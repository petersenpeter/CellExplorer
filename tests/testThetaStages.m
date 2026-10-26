function tests = testThetaStages
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder);
testCase.TestData.folder = folder; testCase.TestData.path = path;
root = fileparts(fileparts(mfilename('fullpath')));
copyfile(fullfile(root,'tests','fixtures','thetaLegacyReference.m.txt'),fullfile(folder,'thetaLegacyReference.m'));
addpath(folder,fullfile(root,'util'),fullfile(root,'calc_CellMetrics','Helpers'));
session.general = struct('name','synthetic','basePath',folder);
session.extracellular = struct('sr',20000,'srLfp',1250,'nChannels',2,'leastSignificantBit',.195);
session.channelTags.Theta.channels = 2;
testCase.TestData.session = session;
t = (0:4999)/1250;
binary = int16([6000*sin(2*pi*8*t);7000*sin(2*pi*7*t+.6)+1000*sin(2*pi*20*t)]);
file = fullfile(folder,'synthetic.lfp');
fid = fopen(file,'w'); fwrite(fid,binary,'int16'); fclose(fid);
animal.time = 0:.1:4; animal.speed = 20*ones(size(animal.time));
save(fullfile(folder,'synthetic.animal.behavior.mat'),'animal');
spikes.times = {(.001:.002:3.999)',(.1:.2:4.1)'};
spikes.ts = cellfun(@(x) round(x*20000),spikes.times,'UniformOutput',false);
spikes.UID = [7 9]; spikes.cluID = [21 42];
testCase.TestData.spikes = spikes;
testCase.TestData.parameters = ce.pipeline.parseParameters('headless',true,'metrics',{'theta_metrics'});
testCase.TestData.preferences = preferences_ProcessCellMetrics;
end

function teardown(testCase)
path(testCase.TestData.path);
rmdir(testCase.TestData.folder,'s');
end

function testSignalAndReaderMatchFrozenLegacy(testCase)
session = testCase.TestData.session;
for channel = [1 2]
    file = fullfile(testCase.TestData.folder,'synthetic.lfp');
    expected = double(LoadBinary(file,'nChannels',2,'channels',channel,'frequency',1250));
    verifyEqual(testCase,ce.io.readLfpChannel(file,2,channel),expected);
end
expected = thetaLegacyReference(session,'forceReload',true,'saveMat',false);
[actual,result] = ce.pipeline.prepareTheta(session,testCase.TestData.parameters);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,rmfield(actual,'processinginfo'),expected);
verifyEqual(testCase,calcInstantaneousTheta2(session,'forceReload',true,'saveMat',false),expected);
verifyEqual(testCase,nargin('calcInstantaneousTheta2'),-2);
end

function testLegacyCacheCannotOverrideOptions(testCase)
session = testCase.TestData.session;
InstantaneousTheta = thetaLegacyReference(session,'forceReload',true,'saveMat',false);
forceReload = true; saveMat = true; %#ok<NASGU>
file = fullfile(testCase.TestData.folder,'synthetic.InstantaneousTheta.lfp.mat');
save(file,'InstantaneousTheta','forceReload','saveMat');
hash = ce.pipeline.fileFingerprint(file);
actual = calcInstantaneousTheta2(session,'saveMat',false);
verifyEqual(testCase,actual,InstantaneousTheta);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
end

function testDeferredPersistenceAndReuse(testCase)
before = dir(testCase.TestData.folder); figures = findall(0,'Type','figure');
[first,results,theta,persistence] = run(testCase,struct());
verifyEqual(testCase,{results.status},{'completed','completed'});
verifyEqual(testCase,dir(testCase.TestData.folder),before);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyTrue(testCase,all(isfinite(first.responseCurves.thetaPhase{1})));
verifyTrue(testCase,all(isnan(first.responseCurves.thetaPhase{2})));
verifyTrue(testCase,ce.io.saveTheta(persistence.file,theta,persistence.expectedHash));
hash = ce.pipeline.fileFingerprint(persistence.file);
[again,results,theta,persistence] = run(testCase,first);
verifyEqual(testCase,{results.status},{'reused','reused'});
verifyEqual(testCase,again,first);
verifyFalse(testCase,ce.io.saveTheta(persistence.file,theta,persistence.expectedHash));
verifyEqual(testCase,ce.pipeline.fileFingerprint(persistence.file),hash);
end

function testBehaviorChangeKeepsSignalAndChangesMetrics(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
animal.time = 0:.1:4; animal.speed = zeros(size(animal.time));
save(fullfile(testCase.TestData.folder,'synthetic.animal.behavior.mat'),'animal');
[changed,results] = run(testCase,first);
verifyEqual(testCase,{results.status},{'reused','completed'});
verifyTrue(testCase,all(isnan(changed.thetaEntrainment)));
verifyEqual(testCase,changed.general.processinginfo.stages.theta_signal,first.general.processinginfo.stages.theta_signal);
end

function testIntervalsAndPreferencesOnlyInvalidateMetrics(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
testCase.TestData.parameters.excludeIntervals = [1 3];
testCase.TestData.parameters.metricsToExcludeManipulationIntervals = {'theta_metrics'};
selected = testCase.TestData.spikes;
for k = 1:2
    keep = selected.times{k} < 1 | selected.times{k} > 3;
    selected.times{k} = selected.times{k}(keep); selected.ts{k} = selected.ts{k}(keep);
end
[changed,results] = ce.pipeline.runThetaStages(first,{testCase.TestData.spikes,selected}, ...
    testCase.TestData.session,testCase.TestData.parameters,testCase.TestData.preferences);
verifyEqual(testCase,{results.status},{'reused','completed'});
verifyEqual(testCase,changed.general.processinginfo.stages.theta_metrics.settings.spikeSubset,2);
testCase.TestData.preferences.theta.min_spikes = 5000;
[changed,results] = run(testCase,first);
verifyEqual(testCase,{results.status},{'reused','completed'});
verifyTrue(testCase,all(isnan(changed.thetaEntrainment)));
end

function testLfpContentAndChannelInvalidateSignal(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
fid = fopen(fullfile(testCase.TestData.folder,'synthetic.lfp'),'r+');
fseek(fid,1002,'bof'); fwrite(fid,int16(12345),'int16'); fclose(fid);
[~,results,theta,persistence] = run(testCase,first);
verifyEqual(testCase,{results.status},{'completed','completed'});
verifyEqual(testCase,results(1).reason,'changed_inputHash'); persist(theta,persistence);
testCase.TestData.session.channelTags.Theta.channels = 1;
[~,results] = run(testCase,first);
verifyEqual(testCase,results(1).status,'completed');
verifyEqual(testCase,results(1).reason,'changed_inputHash');
end

function testEditedCacheRecomputedAndConflictPreservesEdit(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
loaded = load(persistence.file); InstantaneousTheta = loaded.InstantaneousTheta;
InstantaneousTheta.signal_phase{2}(10) = 100;
save(persistence.file,'InstantaneousTheta');
[~,results,repaired,persistence] = run(testCase,first);
verifyEqual(testCase,results(1).reason,'changed_outputs');
verifyEqual(testCase,repaired.signal_phase,theta.signal_phase);
InstantaneousTheta.timestamps = 99; save(persistence.file,'InstantaneousTheta');
hash = ce.pipeline.fileFingerprint(persistence.file);
verifyError(testCase,@() persist(repaired,persistence),'ce:io:ThetaRevisionChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(persistence.file),hash);
end

function testFailureDoesNotPersistSignal(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
hash = ce.pipeline.fileFingerprint(persistence.file);
testCase.TestData.preferences.theta.bins = [0 1 0];
verifyError(testCase,@() run(testCase,first),'ce:pipeline:StageFailed');
verifyEqual(testCase,ce.pipeline.fileFingerprint(persistence.file),hash);
end

function testMissingPrerequisitesRetireOnlyThetaMetrics(testCase)
[first,~,theta,persistence] = run(testCase,struct()); persist(theta,persistence);
first.responseCurves.custom = {1,2}; first.thetaPhaseResponse = {1,2};
delete(fullfile(testCase.TestData.folder,'synthetic.animal.behavior.mat'));
[removed,results,~,persistence] = run(testCase,first);
verifyEqual(testCase,{results.status},{'skipped','completed'});
verifyFalse(testCase,isfield(removed,'thetaPhasePeak'));
verifyFalse(testCase,isfield(removed,'thetaPhaseResponse'));
verifyFalse(testCase,isfield(removed.responseCurves,'thetaPhase'));
verifyFalse(testCase,isfield(removed.general.responseCurves,'thetaPhase'));
verifyEqual(testCase,removed.responseCurves.custom,{1,2}); verifyEmpty(testCase,persistence);
testCase.TestData.parameters.excludeMetrics = {'theta_metrics'};
[skipped,results] = run(testCase,first);
verifyEqual(testCase,{results.status},{'skipped','skipped'}); verifyEqual(testCase,skipped,first);
end

function testInvalidBehaviorAndLfpRejected(testCase)
animal.time = [0 1 1]; animal.speed = [1 2 3];
save(fullfile(testCase.TestData.folder,'synthetic.animal.behavior.mat'),'animal');
verifyError(testCase,@() ce.pipeline.thetaBehavior(testCase.TestData.session),'ce:pipeline:InvalidThetaBehavior');
file = fullfile(testCase.TestData.folder,'synthetic.lfp');
fid = fopen(file,'a'); fwrite(fid,uint8(0),'uint8'); fclose(fid);
verifyError(testCase,@() ce.pipeline.thetaRecording(testCase.TestData.session),'ce:pipeline:InvalidThetaLfp');
delete(file);
verifyError(testCase,@() ce.pipeline.thetaRecording(testCase.TestData.session),'ce:pipeline:MissingThetaLfp');
verifyFalse(testCase,isfile(file));
end

function testTimestampOriginAndUnitsAreExplicit(testCase)
recording = ce.pipeline.thetaRecording(testCase.TestData.session,false);
spikes = testCase.TestData.spikes;
spikes.ts{1}(1) = 0; spikes.times{1}(1) = 0;
verifyError(testCase,@() ce.pipeline.thetaSpikes(spikes,recording),'ce:pipeline:InvalidThetaSpikeSamples');
spikes = testCase.TestData.spikes; spikes.ts{1} = spikes.times{1};
verifyError(testCase,@() ce.pipeline.thetaSpikes(spikes,recording),'ce:pipeline:InvalidThetaSpikes');
spikes = rmfield(spikes,'ts');
verifyError(testCase,@() ce.pipeline.thetaSpikes(spikes,recording),'ce:pipeline:InvalidThetaSpikes');
end

function [metrics,results,theta,persistence] = run(testCase,metrics)
[metrics,results,theta,persistence] = ce.pipeline.runThetaStages(metrics, ...
    {testCase.TestData.spikes,testCase.TestData.spikes},testCase.TestData.session, ...
    testCase.TestData.parameters,testCase.TestData.preferences);
end

function persist(theta,persistence)
ce.io.saveTheta(persistence.file,theta,persistence.expectedHash);
end
