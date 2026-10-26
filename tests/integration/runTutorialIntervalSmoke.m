function summary = runTutorialIntervalSmoke(source, baselineFunction)
%RUNTUTORIALINTERVALSMOKE Isolated native checks with two real tutorial units.
% Optional baselineFunction compares the pre-extraction pipeline numerically.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath = path; pathCleanup = onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'),fullfile(root,'util'), ...
    fullfile(root,'calc_CellMetrics','mex'),fullfile(root,'calc_CellMetrics','Helpers'));
basename = ce.io.basenameFromBasepath(source);
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
copyfile(fullfile(source,[basename,'.session.mat']),fullfile(folder,[basename,'.session.mat']));
metadata = load(fullfile(folder,[basename,'.session.mat']),'session');
sr = metadata.session.extracellular.sr;
loaded = load(fullfile(source,[basename,'.spikes.cellinfo.mat']),'spikes');
spikes = loaded.spikes;
count = numel(spikes.times);
[~,order] = sort(cellfun(@(t) sum(t >= 0 & t <= 120),spikes.times),'descend');
units = sort(order(1:2));
for name = fieldnames(spikes)'
    value = spikes.(name{1});
    if (isnumeric(value) || iscell(value)) && isvector(value) && numel(value) == count
        spikes.(name{1}) = value(units);
    end
end
for index = 1:2
    keep = spikes.times{index} >= 0 & spikes.times{index} <= 120;
    for name = {'times','ts','ids','amplitudes'}
        if isfield(spikes,name{1}), spikes.(name{1}){index} = spikes.(name{1}){index}(keep); end
    end
end
spikes.sr = sr;
spikes.numcells = 2; spikes.total = cellfun(@numel,spikes.times);
spikes.spindices = generateSpinDices(spikes.times);
spikesFile = fullfile(folder,[basename,'.spikes.cellinfo.mat']); save(spikesFile,'spikes');
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics','acg_metrics','event_metrics','manipulation_metrics','state_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
flash.timestamps = [10 10.05;20 20.05;40 40.05;80 80.05];
pulse.timestamps = [15 15.04;30 30.04;70 70.04];
periods.ints.quiet = [5 30;50 70]; periods.ints.active = [80 110];
eventFile = fullfile(folder,[basename,'.flash.events.mat']);
manipFile = fullfile(folder,[basename,'.pulse.manipulation.mat']);
stateFile = fullfile(folder,[basename,'.periods.states.mat']);
save(eventFile,'flash'); save(manipFile,'pulse'); save(stateFile,'periods');
figures = findall(0,'Type','figure'); timer = tic;
if nargin > 1
    before = baselineFunction(options{:});
end
first = ProcessCellMetrics(options{:});
for name = {'event_metrics','manipulation_metrics','state_metrics'}
    assert(strcmp(stage(first,name{1}).status,'completed'));
end
paths = {'events','general.events','manipulations','general.manipulations','general.states'};
for name = {'flash','pulse'}
    paths = [paths,strcat(name{1},{'_modulationIndex','_modulationRatio','_modulationPeakResponseTime','_modulationSignificanceLevel'})];
end
for name = {'quiet','active'}
    paths = [paths,strcat({'firingRate_','firingRateISI_','cv2_','burstIndex_'},name{1})];
end
if nargin > 1
    assert(isequaln(ce.pipeline.outputSnapshot(first,paths),ce.pipeline.outputSnapshot(before,paths)), ...
        'Event/manipulation/state outputs differ from the pre-extraction implementation.');
end
again = ProcessCellMetrics(options{:});
for name = {'event_metrics','manipulation_metrics','state_metrics'}
    assert(strcmp(stage(again,name{1}).status,'reused'));
end
pulse.timestamps = pulse.timestamps + 2; save(manipFile,'pulse');
changed = ProcessCellMetrics(options{:});
assert(strcmp(stage(changed,'event_metrics').status,'reused'));
assert(strcmp(stage(changed,'manipulation_metrics').status,'completed'));
assert(strcmp(stage(changed,'state_metrics').status,'reused'));
ignored = ProcessCellMetrics(options{:},'ignoreEventTypes',{'flash'});
assert(~isfield(ignored,'flash_modulationIndex'));
assert(~isfield(ignored.general.events,'flash'));
periods.ints.rest = periods.ints.quiet; periods.ints = rmfield(periods.ints,'quiet');
save(stateFile,'periods');
renamed = ProcessCellMetrics(options{:},'ignoreEventTypes',{'flash'});
assert(~isfield(renamed,'firingRate_quiet') && isfield(renamed,'firingRate_rest'));
delete(eventFile); delete(stateFile);
removed = ProcessCellMetrics(options{:});
assert(~isfield(removed,'firingRate_rest') && ~isfield(removed,'cv2_active'));
assert(isempty(fieldnames(removed.general.states)));
repeated = ProcessCellMetrics(options{:});
assert(strcmp(stage(repeated,'state_metrics').status,'reused'));
assert(strcmp(stage(repeated,'event_metrics').status,'reused'));
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
beforeFailure = ce.pipeline.fileFingerprint(metricsFile);
pulse.timestamps = [3 2]; save(manipFile,'pulse');
failed = false;
try
    ProcessCellMetrics(options{:});
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'));
    failed = true;
end
assert(failed && strcmp(ce.pipeline.fileFingerprint(metricsFile),beforeFailure));
assert(isequal(findall(0,'Type','figure'),figures));
summary = struct('tutorialUnits',units,'elapsedSeconds',toc(timer),'baselineCompared',nargin>1, ...
    'fileInvalidationVerified',true,'staleOutputsRemoved',true,'failurePreservesSavedMetrics',true);
disp(summary);
end

function result = stage(metrics,name)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},name));
end
