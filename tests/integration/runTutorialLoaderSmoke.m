function summary = runTutorialLoaderSmoke(source, baselineFunction)
%RUNTUTORIALLOADERSMOKE Compare complete batches from read-only tutorial copies.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'));
basename = ce.io.basenameFromBasepath(source);
sourceFile = fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
sourceHash = ce.pipeline.fileFingerprint(sourceFile);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
folders = {fullfile(folder,'first'),fullfile(folder,'second')};
for index = 1:2
    mkdir(folders{index}); copyfile(sourceFile,fullfile(folders{index},[basename,'.cell_metrics.cellinfo.mat']));
end
% Only the frozen legacy loader needs this settings lookup and progress window.
% No credentials or database are needed for a local reference comparison.
if nargin > 1
    fid = fopen(fullfile(folder,'db_load_settings.m'),'w');
    fprintf(fid,'function value = db_load_settings; value = struct(); end\n'); fclose(fid);
    addpath(folder); clear db_load_settings;
    progress = waitbar(0,'Reference loader','Visible','off');
    progressCleanup = onCleanup(@() deleteIfValid(progress));
    before = baselineFunction('basepaths',folders,'basenames',{basename,basename},'waitbar_handle',progress);
    delete(progress); clear progressCleanup;
end
figures = findall(0,'Type','figure'); directory = pwd; timer = tic;
batch = loadCellMetricsBatch('basepaths',folders,'basenames',{basename,basename},'headless',true);
if nargin > 1
    before.general = rmfield(before.general,'batch_benchmark');
    comparison = batch; comparison.general = rmfield(comparison.general,'batch_benchmark');
    names = union(fieldnames(before),fieldnames(comparison));
    for key = names(:)'
        assert(isfield(before,key{1}) && isfield(comparison,key{1}) && ...
            isequaln(before.(key{1}),comparison.(key{1})),['Batch differs from legacy in ',key{1}]);
    end
end
[single,selected] = loadCellMetrics('basepath',folders{1},'basename',basename,'putativeCellType',{'Pyramidal'});
assert(numel(single.UID)==151 && numel(batch.UID)==302);
assert(isequal(selected,find(contains(single.putativeCellType,'Pyramidal'))));
assert(isequal(batch.UID,[single.UID,single.UID]));
assert(isequal(batch.batchIDs,[ones(1,151),2*ones(1,151)]));
assert(isequal(figures,findall(0,'Type','figure')) && strcmp(directory,pwd));
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
for index = 1:2
    assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(fullfile(folders{index},[basename,'.cell_metrics.cellinfo.mat']))));
end
summary = struct('sessionCellCount',151,'batchCellCount',302,'baselineCompared',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function deleteIfValid(handle)
if isgraphics(handle), delete(handle); end
end
