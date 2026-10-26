function summary = runTutorialThetaSmoke(source, baselineFunction)
%RUNTUTORIALTHETASMOKE Two real tutorial units with synthetic LFP/behavior.
% Optional baselineFunction compares the pre-extraction theta metrics exactly.
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
session = metadata.session;
session.channelTags.Theta.channels = 2;
session.extracellular.srLfp = 1250;
sessionFile = fullfile(folder,[basename,'.session.mat']); save(sessionFile,'session');
srLfp = session.extracellular.srLfp;
t = (0:120*srLfp-1)/srLfp;
lfp = repmat(int16(7000*sin(2*pi*8*t)+1000*sin(2*pi*23*t)),session.extracellular.nChannels,1);
lfpFile = fullfile(folder,[basename,'.lfp']);
fid = fopen(lfpFile,'w'); fwrite(fid,lfp,'int16'); fclose(fid); clear lfp;
animal.time = 0:.1:120; animal.speed = 20*ones(size(animal.time));
behaviorFile = fullfile(folder,[basename,'.animal.behavior.mat']); save(behaviorFile,'animal');
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics','acg_metrics','theta_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
figures = findall(0,'Type','figure'); timer = tic;
if nargin > 1, before = baselineFunction(options{:}); end
first = ProcessCellMetrics(options{:});
assert(strcmp(stage(first,'theta_signal').status,'completed'));
assert(strcmp(stage(first,'theta_metrics').status,'completed'));
if nargin > 1
    definition = ce.pipeline.stageDefinition('theta_metrics');
    assert(isequaln(ce.pipeline.outputSnapshot(first,definition.outputs), ...
        ce.pipeline.outputSnapshot(before,definition.outputs)), ...
        'Theta metrics differ from the pre-extraction implementation.');
end
again = ProcessCellMetrics(options{:});
assert(strcmp(stage(again,'theta_signal').status,'reused'));
assert(strcmp(stage(again,'theta_metrics').status,'reused'));
metricsFile = fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']);
thetaFile = fullfile(folder,[basename,'.InstantaneousTheta.lfp.mat']);
metricsHash = ce.pipeline.fileFingerprint(metricsFile); thetaHash = ce.pipeline.fileFingerprint(thetaFile);
% A different seed forces preparation, so no-write behavior covers fresh output.
ProcessCellMetrics(options{:},'metrics',{'theta_metrics'},'randomSeed',1,'saveMat',false);
assert(strcmp(metricsHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(thetaHash,ce.pipeline.fileFingerprint(thetaFile)));
restricted = ProcessCellMetrics(options{:},'restrictToIntervals',[0 60]);
assert(strcmp(stage(restricted,'theta_signal').status,'reused'));
assert(strcmp(stage(restricted,'theta_metrics').status,'completed'));
animal.speed(:) = 0; save(behaviorFile,'animal');
changed = ProcessCellMetrics(options{:},'restrictToIntervals',[0 60]);
assert(strcmp(stage(changed,'theta_signal').status,'reused'));
assert(strcmp(stage(changed,'theta_metrics').status,'completed'));
assert(all(isnan(changed.thetaEntrainment)));
metricsHash = ce.pipeline.fileFingerprint(metricsFile); thetaHash = ce.pipeline.fileFingerprint(thetaFile);
animal.time(2) = animal.time(1); save(behaviorFile,'animal');
try
    ProcessCellMetrics(options{:});
    error('test:ExpectedFailure','Invalid behavior timestamps were accepted.');
catch exception
    assert(strcmp(exception.identifier,'ce:pipeline:PreflightFailed'),exception.message);
end
assert(strcmp(metricsHash,ce.pipeline.fileFingerprint(metricsFile)));
assert(strcmp(thetaHash,ce.pipeline.fileFingerprint(thetaFile)));
delete(behaviorFile);
removed = ProcessCellMetrics(options{:});
assert(~isfield(removed,'thetaPhasePeak'));
assert(~isfield(removed.responseCurves,'thetaPhase'));
assert(strcmp(stage(removed,'theta_signal').status,'skipped'));
assert(isequal(figures,findall(0,'Type','figure')),'Headless theta opened figures.');
summary = struct('tutorialUnits',units,'baselineCompared',nargin>1,'elapsedSeconds',toc(timer));
disp(summary);
end

function result = stage(metrics,name)
results = metrics.general.processinginfo.latestRun.stages;
result = results(strcmp({results.name},name));
end
