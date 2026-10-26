function summary = runTutorialAcgSmoke(source)
%RUNTUTORIALACGSMOKE Two real units, temporary metadata/cache, no source writes.
% Requires the native CCGHeart binary and Curve Fitting Toolbox; not part of CI.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
copyfile(fullfile(source,[basename,'.session.mat']),fullfile(folder,[basename,'.session.mat']));
metadata = load(fullfile(folder,[basename,'.session.mat']),'session');
sr = metadata.session.extracellular.sr;
data = load(fullfile(source,[basename,'.spikes.cellinfo.mat']),'spikes');
spikes = data.spikes;
count = numel(spikes.times);
counts = cellfun(@(t) sum(t >= 0 & t <= 120),spikes.times);
[~,order] = sort(counts,'descend'); units = sort(order(1:2));
names = fieldnames(spikes);
for index = 1:numel(names)
    value = spikes.(names{index});
    if (isnumeric(value) || iscell(value)) && isvector(value) && numel(value) == count
        spikes.(names{index}) = value(units);
    end
end
% Preserve waveform data; build coherent short trains for the integration test.
for index = 1:2
    keep = spikes.times{index} >= 0 & spikes.times{index} <= 120;
    for field = {'times','ts','ids','amplitudes'}
        if isfield(spikes,field{1}), spikes.(field{1}){index} = spikes.(field{1}){index}(keep); end
    end
end
spikes.numcells = 2;
spikes.total = cellfun(@numel,spikes.times);
spikes.spindices = generateSpinDices(spikes.times);
save(fullfile(folder,[basename,'.spikes.cellinfo.mat']),'spikes');
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics','acg_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
figures = findall(0,'Type','figure');
timer = tic;
first = ProcessCellMetrics(options{:});
assert(all(strcmp({first.general.processinginfo.latestRun.stages(2:4).status},'completed')));
expected = calc_ACG_metrics(spikes,sr,'showFigures',false);
assert(isequaln(first.acg.narrow,expected.acg_narrow));
assert(isequaln(first.acg.wide,expected.acg_wide));
expectedFits = fit_ACG(expected.acg_narrow,false,false);
names = fieldnames(expectedFits);
for index = 1:numel(names), assert(isequaln(first.(names{index}),expectedFits.(names{index}))); end
expectedLog = calc_logACGs(spikes.times,'showFigures',false,'useParallel',false);
assert(isequaln(first.acg.log10,expectedLog.log10));
again = ProcessCellMetrics(options{:});
assert(all(strcmp({again.general.processinginfo.latestRun.stages(2:4).status},'reused')));
assert(isequaln(first.general.processinginfo.stages,again.general.processinginfo.stages));
changed = ProcessCellMetrics(options{:},'restrictToIntervals',[0 60]);
assert(strcmp(changed.general.processinginfo.latestRun.stages(strcmp({changed.general.processinginfo.latestRun.stages.name},'acg_metrics')).status,'completed'));
assert(strcmp(changed.general.processinginfo.latestRun.stages(strcmp({changed.general.processinginfo.latestRun.stages.name},'acg_metrics')).reason,'changed_inputHash'));
assert(~isequaln(first.acg.narrow,changed.acg.narrow),'Changed interval did not change the ACG.');
repeated = ProcessCellMetrics(options{:},'restrictToIntervals',[0 60]);
assert(all(strcmp({repeated.general.processinginfo.latestRun.stages(2:4).status},'reused')));
% Changing only coordinates must rerun localization, preserving ACG and shape caches.
shiftedSession = metadata.session;
shiftedSession.general.basePath = folder;
shiftedSession.extracellular.chanCoords.x = shiftedSession.extracellular.chanCoords.x + 100;
shifted = ProcessCellMetrics(options{:},'session',shiftedSession,'restrictToIntervals',[0 60]);
results = shifted.general.processinginfo.latestRun.stages;
assert(strcmp(results(strcmp({results.name},'waveform_shape')).status,'reused'));
assert(strcmp(results(strcmp({results.name},'waveform_localization')).status,'completed'));
assert(strcmp(results(strcmp({results.name},'acg_metrics')).status,'reused'));
assert(all(abs(shifted.trilat_x-repeated.trilat_x-100) < 1e-3));
% Skipping ACG must preserve its original provenance, despite new run parameters.
skipped = ProcessCellMetrics(options{:},'metrics',{'waveform_metrics'},'restrictToIntervals',[0 60],'randomSeed',2);
assert(strcmp(skipped.general.processinginfo.latestRun.stages(strcmp({skipped.general.processinginfo.latestRun.stages.name},'acg_metrics')).status,'skipped'));
assert(isequaln(skipped.general.processinginfo.stages.acg_metrics,repeated.general.processinginfo.stages.acg_metrics));
assert(isequal(findall(0,'Type','figure'),figures),'Headless ACG processing created figures.');
stored = load(fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']),'cell_metrics');
assert(isequaln(stored.cell_metrics,skipped));
file = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
beforeFailure = ce.pipeline.fileFingerprint(file);
broken = spikes;
broken.timeWaveform{1} = [0 0]; % Struct passes preflight but calculation cannot interpolate it.
failed = false;
try
    ProcessCellMetrics(options{:},'spikes',broken);
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:StageFailed'));
    assert(contains(exception.message,'waveform_shape'));
    failed = true;
end
assert(failed,'Invalid waveform unexpectedly passed the stage.');
assert(strcmp(ce.pipeline.fileFingerprint(file),beforeFailure),'A failed stage changed the saved metrics.');
summary = struct('cellCount',2,'units',units,'elapsedSeconds',toc(timer), ...
    'cacheReuseVerified',true,'intervalInvalidationVerified',true,'skippedProvenanceVerified',true, ...
    'failurePreservesSavedMetrics',true,'coordinateInvalidationVerified',true);
disp(summary);
end
