function summary = runTutorialDeepSuperficialSmoke(source, baselineFunction)
%RUNTUTORIALDEEPSUPERFICIALSMOKE Actual channel classifications, isolated copies.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
suffixes = {'.session.mat','.spikes.cellinfo.mat','.cell_metrics.cellinfo.mat', ...
    '.deepSuperficialfromRipple.channelinfo.mat','.ripples.events.mat'};
hashes = cell(size(suffixes));
for index = 1:numel(suffixes)
    file = [basename,suffixes{index}];
    hashes{index} = ce.pipeline.fileFingerprint(fullfile(source,file));
    copyfile(fullfile(source,file),fullfile(folder,file));
end
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
channelFile = fullfile(folder,[basename,'.deepSuperficialfromRipple.channelinfo.mat']);
cached = load(metricsFile,'cell_metrics'); original = cached.cell_metrics;
options = {'basepath',folder,'headless',true,'metrics',{'deepSuperficial'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
timer = tic; figures = findall(0,'Type','figure');
legacy = ProcessCellMetrics(options{:});
for name = {'deepSuperficial','deepSuperficialDistance'}
    if isfield(original,name{1}), assert(isequaln(legacy.(name{1}),original.(name{1}))); end
end
% Compare automatic projection from a clean copy without existing annotations.
cell_metrics = original;
for name = {'deepSuperficial','deepSuperficialDistance'}
    if isfield(cell_metrics,name{1}), cell_metrics = rmfield(cell_metrics,name{1}); end
end
save(metricsFile,'cell_metrics');
if nargin > 1
    before = baselineFunction(options{:});
    save(metricsFile,'cell_metrics');
end
first = ProcessCellMetrics(options{:});
assert(strcmp(stage(first).status,'completed'));
if nargin > 1
    paths = {'deepSuperficial','deepSuperficialDistance','general.SWR','general.deepSuperficial_file', ...
        'general.processinginfo.deepSuperficialfromRipple'};
    assert(isequaln(ce.pipeline.outputSnapshot(first,paths),ce.pipeline.outputSnapshot(before,paths)), ...
        'Deep/superficial outputs differ from the legacy projection.');
end
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again).status,'reused'));
cell_metrics = again;
cell_metrics.deepSuperficial{1} = 'Reviewed'; cell_metrics.deepSuperficialDistance(1) = -999;
save(metricsFile,'cell_metrics');
loaded = load(channelFile,'deepSuperficialfromRipple');
deepSuperficialfromRipple = loaded.deepSuperficialfromRipple;
deepSuperficialfromRipple.channelClass(:) = {'Cortical'};
deepSuperficialfromRipple.channelDistance(:) = 77;
save(channelFile,'deepSuperficialfromRipple'); channelHash = ce.pipeline.fileFingerprint(channelFile);
changed = ProcessCellMetrics(options{:});
assert(strcmp(stage(changed).status,'completed'));
assert(strcmp(changed.deepSuperficial{1},'Reviewed') && changed.deepSuperficialDistance(1) == -999);
assert(all(strcmp(changed.deepSuperficial(2:end),'Cortical')));
assert(all(changed.deepSuperficialDistance(2:end) == 77));
assert(strcmp(channelHash,ce.pipeline.fileFingerprint(channelFile)),'Pipeline rewrote reviewed channel data.');
metricsHash = ce.pipeline.fileFingerprint(metricsFile);
deepSuperficialfromRipple.channelDistance(:) = 88; save(channelFile,'deepSuperficialfromRipple');
channelHash = ce.pipeline.fileFingerprint(channelFile);
ProcessCellMetrics(options{:},'saveMat',false);
assert(strcmp(metricsHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(channelHash,ce.pipeline.fileFingerprint(channelFile)));
delete(channelFile);
try
    ProcessCellMetrics(options{:});
    error('test:ExpectedFailure','Missing classification preparation was accepted.');
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'),exception.message);
end
assert(strcmp(metricsHash,ce.pipeline.fileFingerprint(metricsFile)));
delete(fullfile(folder,[basename,'.ripples.events.mat']));
sessionFile = fullfile(folder,[basename,'.session.mat']); loaded = load(sessionFile,'session'); session = loaded.session;
if isfield(session.channelTags,'Ripple'), session.channelTags = rmfield(session.channelTags,'Ripple'); end
save(sessionFile,'session');
removed = ProcessCellMetrics(options{:});
assert(~isfield(removed.general,'SWR'));
assert(strcmp(removed.deepSuperficial{1},'Reviewed') && removed.deepSuperficialDistance(1) == -999);
assert(all(cellfun(@isempty,removed.deepSuperficial(2:end))) && all(isnan(removed.deepSuperficialDistance(2:end))));
assert(isequal(figures,findall(0,'Type','figure')),'Headless projection opened figures.');
for index = 1:numel(suffixes)
    assert(strcmp(hashes{index},ce.pipeline.fileFingerprint(fullfile(source,[basename,suffixes{index}]))));
end
summary = struct('cellCount',numel(first.UID),'baselineCompared',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function result = stage(metrics)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},'deepSuperficial'));
end
