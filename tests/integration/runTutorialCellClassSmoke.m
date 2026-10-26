function summary = runTutorialCellClassSmoke(source, baselineFunction)
%RUNTUTORIALCELLCLASSSMOKE Real cell identities with synthetic imported labels.
% Source recordings and original metrics are read-only. Labels in this check are
% test fixtures, not biological classifications of the tutorial cells.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
suffixes = {'.session.mat','.spikes.cellinfo.mat','.cell_metrics.cellinfo.mat'};
hashes = cell(size(suffixes));
for index = 1:numel(suffixes)
    file = [basename,suffixes{index}];
    hashes{index} = ce.pipeline.fileFingerprint(fullfile(source,file));
    copyfile(fullfile(source,file),fullfile(folder,file));
end
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
sessionFile = fullfile(folder,[basename,'.session.mat']);
classFile = fullfile(folder,[basename,'.CellClass.cellinfo.mat']);
loaded = load(metricsFile,'cell_metrics'); original = loaded.cell_metrics;
loaded = load(fullfile(folder,[basename,'.spikes.cellinfo.mat']),'spikes'); spikes = loaded.spikes;
CellClass = struct('UID',spikes.UID,'cluID',spikes.cluID);
CellClass.label = repmat({'pE'},1,numel(spikes.UID));
CellClass.label(2:2:end) = {'pI'}; CellClass.label{1} = [];
save(classFile,'CellClass'); sourceHash = ce.pipeline.fileFingerprint(classFile);
expected = CellClass.label; expected{1} = 'Unknown';
options = {'basepath',folder,'headless',true,'metrics',{'other_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
timer = tic; figures = findall(0,'Type','figure');
if nargin > 1
    before = baselineFunction(options{:});
    cell_metrics = original; save(metricsFile,'cell_metrics');
end
first = ProcessCellMetrics(options{:});
assert(strcmp(stage(first).status,'completed'));
assert(isequal(first.CellClassBuzcode,expected));
if nargin > 1, assert(isequal(first.CellClassBuzcode,before.CellClassBuzcode)); end
assert(isequaln(first.putativeCellType,original.putativeCellType));
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again).status,'reused'));
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(classFile)));
% Reverse all source columns while retaining identities; target labels stay put.
CellClass.UID = fliplr(CellClass.UID); CellClass.cluID = fliplr(CellClass.cluID);
CellClass.label = fliplr(CellClass.label); save(classFile,'CellClass');
reordered = ProcessCellMetrics(options{:});
assert(strcmp(stage(reordered).status,'completed'));
assert(isequal(reordered.CellClassBuzcode,expected));
metricHash = ce.pipeline.fileFingerprint(metricsFile); sessionHash = ce.pipeline.fileFingerprint(sessionFile);
CellClass.label{end} = 'Edited source'; save(classFile,'CellClass');
sourceHash = ce.pipeline.fileFingerprint(classFile);
preview = ProcessCellMetrics(options{:},'saveMat',false,'saveBackup',true);
assert(strcmp(preview.CellClassBuzcode{1},'Edited source'));
assert(strcmp(metricHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(sessionHash,ce.pipeline.fileFingerprint(sessionFile)));
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(classFile)));
assert(~isfolder(fullfile(folder,'revisions_cell_metrics')));
% Equal counts with unverified identity must fail before persistence.
CellClass = rmfield(CellClass,{'UID','cluID'}); save(classFile,'CellClass');
try
    ProcessCellMetrics(options{:},'saveBackup',true);
    error('test:ExpectedFailure','Count-only classifications were accepted.');
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'),exception.message);
end
assert(strcmp(metricHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(sessionHash,ce.pipeline.fileFingerprint(sessionFile)));
assert(~isfolder(fullfile(folder,'revisions_cell_metrics')));
delete(classFile); removed = ProcessCellMetrics(options{:});
assert(~isfield(removed,'CellClassBuzcode'));
assert(isequaln(removed.putativeCellType,original.putativeCellType));
assert(isequal(figures,findall(0,'Type','figure')),'Headless classification import opened figures.');
for index = 1:numel(suffixes)
    assert(strcmp(hashes{index},ce.pipeline.fileFingerprint(fullfile(source,[basename,suffixes{index}]))));
end
summary = struct('cellCount',numel(first.UID),'baselineCompared',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function result = stage(metrics)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},'cell_class_import'));
end
