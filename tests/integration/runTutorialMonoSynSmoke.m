function summary = runTutorialMonoSynSmoke(source)
%RUNTUTORIALMONOSYNSMOKE Native detection/cache checks in a temporary session.
% Uses two tutorial units, then coupled synthetic trains to exercise review edits.
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
spikes.numcells = 2; spikes.total = cellfun(@numel,spikes.times);
spikes.spindices = generateSpinDices(spikes.times);
spikesFile = fullfile(folder,[basename,'.spikes.cellinfo.mat']); save(spikesFile,'spikes');
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics','acg_metrics','monoSynaptic_connections'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
figures = findall(0,'Type','figure');
timer = tic;
first = ProcessCellMetrics(options{:});
assert(strcmp(stage(first,'monosynaptic_detection').status,'completed'));
file = fullfile(folder,[basename,'.mono_res.cellinfo.mat']);
stored = load(file,'mono_res');
expected = ce_MonoSynConvClick(spikes,'sr',sr,'includeInhibitoryConnections',false);
assert(isequaln(ce.pipeline.monoSynAutomatic(stored.mono_res),ce.pipeline.monoSynAutomatic(expected)));
before = ce.pipeline.fileFingerprint(file);
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again,'monosynaptic_detection').status,'reused'));
assert(strcmp(stage(again,'monosynaptic_metrics').status,'reused'));
assert(strcmp(ce.pipeline.fileFingerprint(file),before),'Unchanged mono_res was rewritten.');
changed = ProcessCellMetrics(options{:},'includeInhibitoryConnections',true);
assert(strcmp(stage(changed,'monosynaptic_detection').reason,'changed_parameterHash'));
archives = dir(fullfile(folder,'revisions_mono_res','*.mat'));
assert(any(contains({archives.name},before)),'Previous detection was not archived.');
restricted = ProcessCellMetrics(options{:},'includeInhibitoryConnections',true,'restrictToIntervals',[0 60]);
assert(strcmp(stage(restricted,'monosynaptic_detection').reason,'changed_inputHash'));
before = ce.pipeline.fileFingerprint(file);
ProcessCellMetrics(options{:},'saveMat',false);
assert(strcmp(ce.pipeline.fileFingerprint(file),before),'saveMat=false changed mono_res.');

% Known coupled trains provide a detected pair that can be manually rejected.
spikes.times = {(.1:.05:99.9)',(.102:.05:99.902)'};
for name = {'ts','ids','amplitudes'}
    if isfield(spikes,name{1}), spikes = rmfield(spikes,name{1}); end
end
spikes.total = cellfun(@numel,spikes.times);
spikes.spindices = generateSpinDices(spikes.times);
save(spikesFile,'spikes');
mono_res = ce_MonoSynConvClick(spikes,'sr',sr); % Legacy file without provenance.
assert(~isempty(mono_res.sig_con),'Synthetic coupling did not yield a candidate.');
save(file,'mono_res');
legacyHash = ce.pipeline.fileFingerprint(file);
ProcessCellMetrics(options{:});
archives = dir(fullfile(folder,'revisions_mono_res','*.mat'));
assert(any(contains({archives.name},legacyHash)),'Legacy file was not preserved.');
loaded = load(file,'mono_res'); mono_res = loaded.mono_res;
mono_res.sig_con = []; mono_res.sig_con_excitatory = []; % Simulate the legacy GUI.
save(file,'mono_res');
reviewedHash = ce.pipeline.fileFingerprint(file);
reviewed = ProcessCellMetrics(options{:});
assert(strcmp(stage(reviewed,'monosynaptic_detection').status,'reused'));
assert(strcmp(stage(reviewed,'monosynaptic_metrics').status,'completed'));
assert(isempty(reviewed.putativeConnections.excitatory));
assert(all(strcmp(reviewed.synapticEffect,'Unknown')));
assert(strcmp(reviewed.general.processinginfo.monosynapticReview.status,'external_selection_preserved'));
archives = dir(fullfile(folder,'revisions_mono_res','*.mat'));
assert(any(contains({archives.name},reviewedHash)));
% Even forceReload preserves reviewed selections when the context/output matches.
forced = ProcessCellMetrics(options{:},'forceReload',true);
assert(isempty(forced.putativeConnections.excitatory));
assert(strcmp(stage(forced,'monosynaptic_detection').reason,'forced'));
assert(isequal(findall(0,'Type','figure'),figures),'Headless detection opened a figure.');
summary = struct('tutorialUnits',units,'elapsedSeconds',toc(timer),'legacyNumericsMatch',true, ...
    'intervalAndOptionInvalidation',true,'manualSelectionPreserved',true,'archivesVerified',true);
disp(summary);
end

function result = stage(metrics,name)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},name));
end
