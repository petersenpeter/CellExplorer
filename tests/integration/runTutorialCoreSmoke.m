function summary = runTutorialCoreSmoke(source, baselineFunction)
%RUNTUTORIALCORESMOKE Compare core formulas and saving using isolated real data.
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
loaded = load(metricsFile,'cell_metrics'); original = loaded.cell_metrics;
options = {'basepath',folder,'headless',true,'metrics',{'other_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
timer = tic; figures = findall(0,'Type','figure');
if nargin > 1
    before = baselineFunction(options{:});
    cell_metrics = original; save(metricsFile,'cell_metrics');
end
first = ProcessCellMetrics(options{:});
assert(strcmp(stage(first).status,'completed'));
definition = ce.pipeline.stageDefinition('other_metrics');
if nargin > 1
    assert(isequaln(ce.pipeline.outputSnapshot(first,definition.outputs), ...
        ce.pipeline.outputSnapshot(before,definition.outputs)), ...
        'Core metrics differ from the pre-extraction formulas.');
end
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again).status,'reused'));
assert(isequaln(first.general.processinginfo.stages.other_metrics, ...
    again.general.processinginfo.stages.other_metrics));
loaded = load(sessionFile,'session'); session = loaded.session;
session.general.investigator = 'Core smoke metadata update'; save(sessionFile,'session');
metadata = ProcessCellMetrics(options{:});
assert(strcmp(stage(metadata).status,'reused'));
assert(strcmp(metadata.general.session.investigator,session.general.investigator));
% Full spike subset still uses the legacy excluded-duration denominator.
excludedOptions = [options,{'excludeIntervals',[1,2], ...
    'metricsToExcludeManipulationIntervals',{'none'}}];
if nargin > 1, excludedBefore = baselineFunction(excludedOptions{:},'saveMat',false); end
excluded = ProcessCellMetrics(excludedOptions{:},'saveMat',false,'saveBackup',true);
assert(strcmp(stage(excluded).status,'completed'));
if nargin > 1
    assert(isequaln(ce.pipeline.outputSnapshot(excluded,definition.outputs), ...
        ce.pipeline.outputSnapshot(excludedBefore,definition.outputs)));
end
metricHash = ce.pipeline.fileFingerprint(metricsFile);
sessionHash = ce.pipeline.fileFingerprint(sessionFile);
ProcessCellMetrics(options{:},'saveMat',false,'saveBackup',true);
assert(strcmp(metricHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(sessionHash,ce.pipeline.fileFingerprint(sessionFile)));
backupFolder = fullfile(folder,'revisions_cell_metrics');
assert(~isfolder(backupFolder),'A no-save run created metric backups.');
ProcessCellMetrics(options{:},'saveBackup',true);
backups = dir(fullfile(backupFolder,'*.mat'));
assert(numel(backups) == 1);
assert(strcmp(metricHash,ce.pipeline.fileFingerprint(fullfile(backups(1).folder,backups(1).name))));
metricHash = ce.pipeline.fileFingerprint(metricsFile);
sessionHash = ce.pipeline.fileFingerprint(sessionFile);
spikesFile = fullfile(folder,[basename,'.spikes.cellinfo.mat']);
loaded = load(spikesFile,'spikes'); spikes = loaded.spikes; spikes.total(1) = spikes.total(1)+1;
save(spikesFile,'spikes');
try
    ProcessCellMetrics(options{:},'saveBackup',true);
    error('test:ExpectedFailure','Stale spike totals were accepted.');
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'),exception.message);
end
assert(strcmp(metricHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(sessionHash,ce.pipeline.fileFingerprint(sessionFile)));
assert(numel(dir(fullfile(backupFolder,'*.mat'))) == 1);
assert(isequal(figures,findall(0,'Type','figure')),'Headless core processing opened figures.');
for index = 1:numel(suffixes)
    assert(strcmp(hashes{index},ce.pipeline.fileFingerprint(fullfile(source,[basename,suffixes{index}]))));
end
summary = struct('cellCount',numel(first.UID),'baselineCompared',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function result = stage(metrics)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},'other_metrics'));
end
