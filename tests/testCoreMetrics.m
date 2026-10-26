function tests = testCoreMetrics
tests = functiontests(localfunctions);
end

function testReferenceValuesAndLegacyTimeBins(testCase)
[spikes,parameters,preferences] = fixture;
[metrics,result] = ce.pipeline.runCoreMetrics(struct(),spikes,parameters,preferences,1);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,metrics.spikeCount,11);
verifyEqual(testCase,metrics.firingRate,.11,'AbsTol',1e-14);
verifyEqual(testCase,metrics.firingRateISI,.1,'AbsTol',1e-14);
verifyEqual(testCase,metrics.cv2,0);
verifyEqual(testCase,metrics.burstIndex_Mizuseki2012,0);
verifyEqual(testCase,metrics.refractoryPeriodViolation,0);
verifyEqual(testCase,metrics.responseCurves.firingRateAcrossTime{1},[repmat(.1,9,1);.2]);
verifyEqual(testCase,metrics.firingRateGiniCoeff,9/121,'AbsTol',1e-14);
verifyEqual(testCase,metrics.general.responseCurves.firingRateAcrossTime.x_edges,0:10:100);
end

function testCoreReuseAndOutputRepairPreserveAnnotations(testCase)
[spikes,parameters,preferences] = fixture;
initial.labels = {'reviewed'}; initial.brainRegion = {'manual'};
[first,~] = ce.pipeline.runCoreMetrics(initial,spikes,parameters,preferences,1);
[again,result] = ce.pipeline.runCoreMetrics(first,spikes,parameters,preferences,1);
verifyEqual(testCase,result.status,'reused'); verifyEqual(testCase,again,first);
again.firingRate = 999;
[repaired,result] = ce.pipeline.runCoreMetrics(again,spikes,parameters,preferences,1);
verifyEqual(testCase,result.reason,'changed_outputs'); verifyEqual(testCase,repaired.firingRate,first.firingRate);
verifyEqual(testCase,repaired.labels,initial.labels); verifyEqual(testCase,repaired.brainRegion,initial.brainRegion);
end

function testExclusionDenominatorIsTrackedEvenForUnfilteredSpikes(testCase)
[spikes,parameters,preferences] = fixture;
[first,~] = ce.pipeline.runCoreMetrics(struct(),spikes,parameters,preferences,1);
parameters.excludeIntervals = [20 40];
[changed,result] = ce.pipeline.runCoreMetrics(first,spikes,parameters,preferences,1);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,changed.firingRate,11/80);
verifyEqual(testCase,result.provenance.settings.excludeIntervals,[20 40]);
end

function testChangedTimesAndBinsInvalidate(testCase)
[spikes,parameters,preferences] = fixture;
[first,~] = ce.pipeline.runCoreMetrics(struct(),spikes,parameters,preferences,1);
spikes.times{1} = (0:5:100)'; spikes.total = numel(spikes.times{1});
[~,result] = ce.pipeline.runCoreMetrics(first,spikes,parameters,preferences,1);
verifyEqual(testCase,result.reason,'changed_inputHash');
preferences.other.firingRateAcrossTime_binsize = 1;
[changed,result] = ce.pipeline.runCoreMetrics(first,spikes,parameters,preferences,1);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,numel(changed.responseCurves.firingRateAcrossTime{1}),100);
end

function testUndefinedLegacyCasesFailWithoutChangingResults(testCase)
[spikes,parameters,preferences] = fixture;
inputs.spikes = spikes;
settings = ce.pipeline.stageSettings(parameters,preferences.other,1);
definition = ce.pipeline.stageDefinition('other_metrics');
initial.labels = {'keep'};
inputs.spikes.total = 99;
[after,result] = ce.pipeline.runStage(initial,definition,inputs,settings,@() ce.pipeline.stages.coreMetrics(inputs,settings));
verifyEqual(testCase,result.error.identifier,'ce:pipeline:InvalidSpikeTotals'); verifyEqual(testCase,after,initial);
inputs.spikes.times = {0}; inputs.spikes.total = 1;
verifyError(testCase,@() ce.pipeline.stages.coreMetrics(inputs,settings),'ce:pipeline:InvalidCoreTimeSpan');
inputs.spikes.times = {[],[1;2]}; inputs.spikes.total = [0 2]; settings.excludeIntervals = [3 4];
verifyError(testCase,@() ce.pipeline.stages.coreMetrics(inputs,settings),'ce:pipeline:EmptyCoreUnit');
end

function testTrailingPartialBinConventionIsPreserved(testCase)
[spikes,parameters,preferences] = fixture;
spikes.times = {[0;50;105]}; spikes.total = 3;
[metrics,~] = ce.pipeline.runCoreMetrics(struct(),spikes,parameters,preferences,1);
verifyEqual(testCase,metrics.general.responseCurves.firingRateAcrossTime.x_edges,0:10:100);
verifyEqual(testCase,sum(metrics.responseCurves.firingRateAcrossTime{1})*10,2);
verifyEqual(testCase,metrics.spikeCount,3);
end

function testMetadataRefreshDoesNotInvalidateCore(testCase)
[spikes,parameters,preferences] = fixture;
metrics.general.cellCount = 1;
session.general = struct('name','synthetic','entryID','42','investigator','first');
session.animal = struct('name','mouse','sex','Male');
session.extracellular.electrodeGroups.channels = {1};
session.spikeSorting = {struct('method','Phy','entryID',12)};
spikes.shankID = 1; spikes.maxWaveformCh1 = 1;
[metrics,session] = ce.pipeline.updateMetadata(metrics,spikes,session);
[metrics,~] = ce.pipeline.runCoreMetrics(metrics,spikes,parameters,preferences,1);
session.general = rmfield(session.general,{'entryID','investigator'});
session.animal = rmfield(session.animal,'sex'); session.spikeSorting{1} = struct();
[metrics,~] = ce.pipeline.updateMetadata(metrics,spikes,session);
verifyFalse(testCase,isfield(metrics,'sessionID'));
verifyFalse(testCase,isfield(metrics,'spikeSortingID'));
verifyFalse(testCase,isfield(metrics.general.session,'investigator'));
verifyFalse(testCase,isfield(metrics.general.animal,'sex'));
[~,result] = ce.pipeline.runCoreMetrics(metrics,spikes,parameters,preferences,1);
verifyEqual(testCase,result.status,'reused');
session.general.entryID = '1+2';
verifyError(testCase,@() ce.pipeline.updateMetadata(metrics,spikes,session),'ce:pipeline:InvalidMetadataID');
end

function [spikes,parameters,preferences] = fixture
spikes = struct('times',{{(0:10:100)'}},'total',11,'UID',7,'cluID',21);
parameters = ce.pipeline.parseParameters('headless',true,'metrics',{'other_metrics'});
preferences = preferences_ProcessCellMetrics;
end
