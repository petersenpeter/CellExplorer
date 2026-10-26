function summary = runTutorialSessionSmoke(source, referenceFile)
%RUNTUTORIALSESSIONSMOKE Opt-in integration check on an isolated session copy.
% Not part of CI. Copies ONLY session metadata, spikes and cell metrics to temp.
% The source recording is never passed to ProcessCellMetrics for processing.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname;
mkdir(folder);
fileCleanup = onCleanup(@() rmdir(folder,'s'));
suffixes = {'.session.mat','.spikes.cellinfo.mat','.cell_metrics.cellinfo.mat'};
for index = 1:numel(suffixes)
    copyfile(fullfile(source,[basename,suffixes{index}]),fullfile(folder,[basename,suffixes{index}]));
end
% Remove one cached waveform metric in the copy to exercise recalculation.
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
data = load(metricsFile,'cell_metrics');
cell_metrics = data.cell_metrics;
if isfield(cell_metrics,'troughToPeak')
    cell_metrics = rmfield(cell_metrics,'troughToPeak');
end
ce.io.saveCellMetrics(cell_metrics,metricsFile);
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
[report,context] = ce.pipeline.preflight(options{:});
assert(report.valid, 'Preflight failed: %s', strjoin({report.errors.message},newline));
expectedCount = numel(context.spikes.times);
expectedRates = cellfun(@(t) numel(t)/(t(end)-t(1)),context.spikes.times);
expectedWaveforms = ce.metrics.calc_waveform_metrics(context.spikes,context.session.extracellular.sr,'showFigures',false);
cwd = pwd;
figures = findall(0,'Type','figure');
timer = tic;
metrics = ProcessCellMetrics(options{:});
elapsed = toc(timer);
if nargin > 1
    baseline = load(referenceFile,'reference');
    for name = {'trilat_x','trilat_y','peakVoltage_expFit'}
        assert(isequaln(metrics.(name{1}),baseline.reference.(name{1})), ...
            'Localization differs from the pre-extraction reference: %s',name{1});
    end
    assert(isequaln(metrics.general.chanCoords,baseline.reference.chanCoords));
end
assert(metrics.general.cellCount == expectedCount);
assert(isequal(metrics.UID,context.spikes.UID));
assert(all(abs(metrics.firingRate-expectedRates) < 1e-10));
assert(isequaln(metrics.troughToPeak,expectedWaveforms.troughtoPeak),'Pipeline waveform output differs from the standalone metric calculation.');
assert(strcmp(pwd,cwd),'Processing changed the working directory.');
assert(isequal(findall(0,'Type','figure'),figures),'Headless processing created figures.');
stored = load(fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']),'cell_metrics');
assert(isequaln(stored.cell_metrics,metrics),'Saved output differs from returned output.');
assert(strcmp(metrics.general.processinginfo.latestRun.stages(strcmp({metrics.general.processinginfo.latestRun.stages.name},'waveform_shape')).status,'completed'));
originalProvenance = metrics.general.processinginfo.stages.waveform_shape;
again = ProcessCellMetrics(options{:});
assert(strcmp(again.general.processinginfo.latestRun.stages(strcmp({metrics.general.processinginfo.latestRun.stages.name},'waveform_shape')).status,'reused'),'Identical waveform inputs did not reuse the stage.');
assert(isequaln(again.general.processinginfo.stages.waveform_shape,originalProvenance),'Reuse replaced original provenance.');
changed = ProcessCellMetrics(options{:},'randomSeed',1);
assert(strcmp(changed.general.processinginfo.latestRun.stages(strcmp({metrics.general.processinginfo.latestRun.stages.name},'waveform_shape')).status,'completed'));
assert(strcmp(changed.general.processinginfo.latestRun.stages(strcmp({metrics.general.processinginfo.latestRun.stages.name},'waveform_shape')).reason,'changed_parameterHash'));
assert(isequaln(changed.troughToPeak,metrics.troughToPeak),'A seed change altered deterministic shape calculations.');
assert(isequal(findall(0,'Type','figure'),figures),'Headless reruns created figures.');
summary = struct('session',basename,'cellCount',expectedCount,'elapsedSeconds',elapsed, ...
    'preflightWarnings',{report.warnings},'savedOutputVerified',true,'waveformsRecalculated',true, ...
    'cacheReuseVerified',true,'parameterInvalidationVerified',true,'figuresCreated',false);
fprintf('Tutorial smoke passed: %d cells, %.2f seconds; saved output verified; no figures.\n',expectedCount,elapsed);
end
