function tests = testDeepSuperficial
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder);
testCase.TestData.folder = folder;
session.general = struct('name','synthetic','basePath',folder);
session.extracellular.nChannels = 4;
session.extracellular.electrodeGroups.channels = {[1 2],[3 4]};
testCase.TestData.session = session;
testCase.TestData.spikes = struct('UID',[7 9],'cluID',[21 42],'maxWaveformCh1',[1 4]);
testCase.TestData.parameters = ce.pipeline.parseParameters('headless',true,'metrics',{'deepSuperficial'});
testCase.TestData.metrics = struct('UID',[7 9],'cluID',[21 42]);
testCase.TestData.file = fullfile(folder,'synthetic.deepSuperficialfromRipple.channelinfo.mat');
write(testCase,fixture);
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testNamedLoadChannelIdentityAndNormalization(testCase)
data = fixture; order = [4 2 1 3];
data.channel = data.channel(order); data.channelClass = data.channelClass(order); data.channelDistance = data.channelDistance(order);
write(testCase,data);
record = ce.pipeline.deepSuperficialInput(testCase.TestData.session);
verifyEqual(testCase,record.data,fixture);
[metrics,~] = run(testCase,testCase.TestData.metrics);
verifyEqual(testCase,metrics.deepSuperficial,{'Deep','Superficial'});
verifyEqual(testCase,metrics.deepSuperficialDistance,[-30 30]);
verifyEqual(testCase,metrics.general.SWR,fixture);
end

function testInvalidIdentityAndGroupOrderRejected(testCase)
for ids = {[1 2 3 3],[0 1 2 3],[1 2 3],[]}
    data = fixture; data.channel = ids{1}; write(testCase,data);
    verifyError(testCase,@() ce.pipeline.deepSuperficialInput(testCase.TestData.session),'ce:data:DeepSuperficialChannelIdentity');
end
data = fixture; data.ripple_channels{1} = [2 1]; write(testCase,data);
verifyError(testCase,@() ce.pipeline.deepSuperficialInput(testCase.TestData.session),'ce:data:DeepSuperficialGroupIdentity');
data = rmfield(fixture,'channel'); write(testCase,data);
verifyError(testCase,@() ce.pipeline.deepSuperficialInput(testCase.TestData.session),'ce:data:InvalidDeepSuperficial');
end

function testWholeFileFingerprintAndReuseWithoutWrites(testCase)
before = ce.pipeline.fileFingerprint(testCase.TestData.file); figures = findall(0,'Type','figure');
[first,result] = run(testCase,testCase.TestData.metrics);
verifyEqual(testCase,result.status,'completed');
[again,result] = run(testCase,first);
verifyEqual(testCase,result.status,'reused'); verifyEqual(testCase,again,first);
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),before);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
data = fixture; data.note = 'metadata-only edit'; write(testCase,data);
[~,result] = run(testCase,again);
verifyEqual(testCase,result.reason,'changed_inputHash');
end

function testSourceAndPeakChannelChangesRefreshUneditedCells(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
data = fixture; data.channelClass{1} = 'Cortical'; data.channelDistance(4) = 90; write(testCase,data);
[changed,result] = run(testCase,first);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,changed.deepSuperficial,{'Cortical','Superficial'});
verifyEqual(testCase,changed.deepSuperficialDistance,[-30 90]);
testCase.TestData.spikes.maxWaveformCh1 = [2 3];
[changed,result] = run(testCase,changed);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,changed.deepSuperficialDistance,[-10 10]);
end

function testCellEditsSurviveReuseSourceChangesAndForce(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
first.deepSuperficial{1} = 'Reviewed'; first.deepSuperficialDistance(1) = -123;
[reviewed,result] = run(testCase,first);
verifyEqual(testCase,result.status,'reused');
verifyEqual(testCase,reviewed.general.processinginfo.deepSuperficialReview.preservedCellCount,1);
data = fixture; data.channelClass{4} = 'Cortical'; data.channelDistance(4) = 99; write(testCase,data);
testCase.TestData.parameters.forceReload = true;
[changed,~] = run(testCase,reviewed);
verifyEqual(testCase,changed.deepSuperficial,{'Reviewed','Cortical'});
verifyEqual(testCase,changed.deepSuperficialDistance,[-123 99]);
end

function testUnverifiedProjectionCannotEraseCellEdits(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
first.deepSuperficial{1} = 'Reviewed'; first.deepSuperficialDistance(1) = -123;
first.general.processinginfo.deepSuperficialProjection.labels{1} = 'Reviewed';
first.general.processinginfo.deepSuperficialProjection.distances(1) = -123;
[repaired,result] = run(testCase,first);
verifyEqual(testCase,result.reason,'changed_outputs');
verifyEqual(testCase,repaired.deepSuperficial,first.deepSuperficial);
verifyEqual(testCase,repaired.deepSuperficialDistance,first.deepSuperficialDistance);
verifyEqual(testCase,repaired.general.processinginfo.deepSuperficialProjection.labels,{'Deep','Superficial'});
end

function testLegacyAnnotationsAndForcedPipelineRecovery(testCase)
previous = testCase.TestData.metrics;
previous.deepSuperficial = {'Reviewed','Unknown'};
previous.deepSuperficialDistance = [NaN -150];
[first,~] = run(testCase,previous);
verifyEqual(testCase,first.deepSuperficial,previous.deepSuperficial);
verifyEqual(testCase,first.general.processinginfo.deepSuperficialReview.status,'legacy_annotations_preserved');
cell_metrics = first; %#ok<NASGU>
save(fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat'),'cell_metrics');
testCase.TestData.parameters.forceReload = true;
[forced,~] = run(testCase,struct());
verifyEqual(testCase,forced.deepSuperficial,previous.deepSuperficial);
verifyEqual(testCase,forced.deepSuperficialDistance,previous.deepSuperficialDistance);
end

function testDeletedSourceRetiresAutomaticButPreservesAnnotations(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
first.deepSuperficial{1} = ''; first.deepSuperficialDistance(1) = NaN;
[first,~] = run(testCase,first);
delete(testCase.TestData.file);
[removed,~] = run(testCase,first);
verifyFalse(testCase,isfield(removed.general,'SWR'));
verifyFalse(testCase,isfield(removed.general,'deepSuperficial_file'));
verifyFalse(testCase,isfield(removed.general.processinginfo,'deepSuperficialfromRipple'));
verifyEqual(testCase,removed.deepSuperficial,{'',''});
verifyEqual(testCase,removed.deepSuperficialDistance,[NaN NaN]);
[removed,~] = run(testCase,removed); % Empty/NaN annotations must remain tracked.
write(testCase,fixture);
[restored,~] = run(testCase,removed);
verifyEqual(testCase,restored.deepSuperficial,{'','Superficial'});
verifyEqual(testCase,restored.deepSuperficialDistance,[NaN 30]);
end

function testDeletedUneditedSourceRemovesCellFields(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
delete(testCase.TestData.file);
[removed,~] = run(testCase,first);
verifyFalse(testCase,isfield(removed,'deepSuperficial'));
verifyFalse(testCase,isfield(removed,'deepSuperficialDistance'));
end

function testFinalizationDefaultsAreNotManualEdits(testCase)
delete(testCase.TestData.file);
[first,~] = run(testCase,testCase.TestData.metrics);
first.general.cellCount = 2; first.general.basename = 'synthetic';
first.general.session = struct(); first.general.animal = struct(); first.waveforms = struct();
first = ce.pipeline.cleanMetrics(first,testCase.TestData.parameters);
verifyEqual(testCase,first.deepSuperficial,{'Unknown','Unknown'});
[again,~] = run(testCase,first);
verifyEqual(testCase,again.general.processinginfo.deepSuperficialReview.preservedCellCount,0);
write(testCase,fixture);
[restored,~] = run(testCase,again);
verifyEqual(testCase,restored.deepSuperficial,{'Deep','Superficial'});
end

function testMissingPreparationFailsWithoutCreatingFiles(testCase)
delete(testCase.TestData.file);
session = testCase.TestData.session; session.channelTags.Ripple.channels = 1;
before = dir(testCase.TestData.folder);
verifyError(testCase,@() ce.pipeline.deepSuperficialInput(session),'ce:pipeline:DeepSuperficialPreparationRequired');
verifyEqual(testCase,dir(testCase.TestData.folder),before);
end

function testSkippedStageIgnoresMalformedSourceAndRetainsCuration(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
write(testCase,struct());
testCase.TestData.parameters.excludeMetrics = {'deepSuperficial'};
[skipped,result] = run(testCase,first);
verifyEqual(testCase,result.status,'skipped'); verifyEqual(testCase,skipped,first);
end

function testCellIdentityMismatchCannotCarryAnnotations(testCase)
[first,~] = run(testCase,testCase.TestData.metrics);
testCase.TestData.spikes.UID = [9 7];
verifyError(testCase,@() run(testCase,first),'ce:curation:DeepSuperficialIdentity');
testCase.TestData.spikes.UID = [7 9]; testCase.TestData.spikes.maxWaveformCh1(1) = 0;
verifyError(testCase,@() run(testCase,first),'ce:pipeline:InvalidDeepSuperficialSpikes');
end

function data = fixture
data.channel = (1:4)'; data.channelClass = {'Deep';'Deep';'Superficial';'Superficial'};
data.channelDistance = [-30;-10;10;30]; data.ripple_channels = {[1 2],[3 4]};
data.processinginfo = struct('function','reviewed_fixture','date',1);
end

function write(testCase,data)
deepSuperficialfromRipple = data; parameters = 'Unrelated saved workspace value'; %#ok<NASGU>
save(testCase.TestData.file,'deepSuperficialfromRipple','parameters');
end

function [metrics,result] = run(testCase,metrics)
[metrics,result] = ce.pipeline.runDeepSuperficial(metrics,testCase.TestData.spikes, ...
    testCase.TestData.session,testCase.TestData.parameters);
end
