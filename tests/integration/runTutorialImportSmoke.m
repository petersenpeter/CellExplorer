function summary = runTutorialImportSmoke(source, baselineFunction)
%RUNTUTORIALIMPORTSMOKE Import synthetic maps/PSTHs for every tutorial cell.
% Research inputs are read only; all processing occurs in a temporary folder.
% Optional baselineFunction runs the captured pre-extraction spatial block.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
for suffix = {'.session.mat','.spikes.cellinfo.mat','.cell_metrics.cellinfo.mat'}
    file = [basename,suffix{1}]; copyfile(fullfile(source,file),fullfile(folder,file));
end
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
cached = load(metricsFile,'cell_metrics'); cell_metrics = cached.cell_metrics;
% The tutorial cache contains metadata from absent historical map files. The
% old block leaves it behind. Compare calculations from a clean plot-metadata
% baseline; stale-metadata retirement is intentionally different and tested below.
if isfield(cell_metrics.general,'firingRateMaps')
    cell_metrics.general = rmfield(cell_metrics.general,'firingRateMaps');
end
save(metricsFile,'cell_metrics');
loaded = load(fullfile(folder,[basename,'.spikes.cellinfo.mat']),'spikes');
spikes = loaded.spikes; count = numel(spikes.UID);
ratemap.UID = spikes.UID; ratemap.cluID = spikes.cluID;
ratemap.x_bins = (1:50)'; ratemap.x_label = 'Position (cm)'; ratemap.boundaries = [1 50];
for index = 1:count
    ratemap.map{index} = (10+mod(index,15))*exp(-((ratemap.x_bins-25)/8).^2);
end
ratemap.map{1} = zeros(50,1);
trials = ratemap;
for index = 1:count, trials.map{index} = [trials.map{index},trials.map{index}/2]; end
mapFile = fullfile(folder,[basename,'.ratemap.firingRateMap.mat']);
trialsFile = fullfile(folder,[basename,'.trials.firingRateMap.mat']);
psthFile = fullfile(folder,[basename,'.flash.psth.mat']);
save(mapFile,'ratemap'); save(trialsFile,'trials');
options = {'basepath',folder,'headless',true,'metrics',{'spatial_metrics','psth_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
figures = findall(0,'Type','figure'); timer = tic;
if nargin > 1
    before = baselineFunction(options{:},'metrics',{'spatial_metrics'});
end
cached = load(metricsFile,'cell_metrics'); cell_metrics = cached.cell_metrics;
cell_metrics.general.firingRateMaps.retiredInput.x_bins = [1 2];
save(metricsFile,'cell_metrics');
flash.UID = fliplr(spikes.UID);
flash.cluID = fliplr(spikes.cluID);
flash.unit = repmat(1:count,5,1);
flash.x_bins = (-2:2)'; flash.x_label = 'Time (s)'; flash.boundaries = 0;
save(psthFile,'flash');
first = ProcessCellMetrics(options{:});
assert(~isfield(first.general.firingRateMaps,'retiredInput'));
assert(strcmp(stage(first,'spatial_metrics').status,'completed'));
assert(strcmp(stage(first,'psth_metrics').status,'completed'));
assert(isequal(first.psth.flash,num2cell(fliplr(flash.unit),1)));
assert(strcmp(first.general.psth.flash.x_label,flash.x_label));
definition = ce.pipeline.stageDefinition('spatial_metrics');
if nargin > 1
    assert(isequaln(ce.pipeline.outputSnapshot(first,definition.outputs), ...
        ce.pipeline.outputSnapshot(before,definition.outputs)), ...
        'Spatial outputs differ from the pre-extraction implementation.');
end
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again,'spatial_metrics').status,'reused'));
assert(strcmp(stage(again,'psth_metrics').status,'reused'));
flash.unit(1) = 99; save(psthFile,'flash');
changed = ProcessCellMetrics(options{:});
assert(strcmp(stage(changed,'spatial_metrics').status,'reused'));
assert(strcmp(stage(changed,'psth_metrics').status,'completed'));
hash = ce.pipeline.fileFingerprint(metricsFile);
ProcessCellMetrics(options{:},'saveMat',false);
assert(strcmp(hash,ce.pipeline.fileFingerprint(metricsFile)));
flash = rmfield(flash,{'UID','cluID'}); save(psthFile,'flash');
try
    ProcessCellMetrics(options{:});
    error('test:ExpectedFailure','Missing cell identity was accepted.');
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'),exception.message);
end
assert(strcmp(hash,ce.pipeline.fileFingerprint(metricsFile)));
delete(psthFile); delete(mapFile);
removed = ProcessCellMetrics(options{:});
assert(~isfield(removed.psth,'flash') && ~isfield(removed,'spatialPeakRate'));
assert(~isfield(removed.firingRateMaps,'ratemap') && isfield(removed.firingRateMaps,'trials'));
assert(isequal(figures,findall(0,'Type','figure')),'Headless import opened figures.');
summary = struct('cellCount',count,'comparedBaseline',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function result = stage(metrics,name)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},name));
end
