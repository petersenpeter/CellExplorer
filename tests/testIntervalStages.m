function tests = testIntervalStages
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder);
testCase.TestData.folder = folder;
testCase.TestData.session.general = struct('name','synthetic','basePath',folder);
testCase.TestData.preferences = preferences_ProcessCellMetrics;
testCase.TestData.parameters = ce.pipeline.parseParameters('headless',true, ...
    'metrics',{'event_metrics','manipulation_metrics','state_metrics'});
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testNamedLoadAndContentFingerprint(testCase)
file = fullfile(testCase.TestData.folder,'synthetic.flash.events.mat');
flash.timestamps = [1 2;3 4];
parameters = 'unrelated MAT variable'; %#ok<NASGU>
save(file,'flash','parameters');
first = ce.pipeline.intervalFiles(testCase.TestData.session,'event_metrics',{});
verifyEqual(testCase,first.data,flash);
parameters = 'changed metadata'; %#ok<NASGU>
save(file,'flash','parameters');
second = ce.pipeline.intervalFiles(testCase.TestData.session,'event_metrics',{});
verifyNotEqual(testCase,first.sha256,second.sha256);
verifyEqual(testCase,first.data,second.data);
end

function testMalformedIntervalsRejected(testCase)
file = fullfile(testCase.TestData.folder,'synthetic.flash.events.mat');
flash.timestamps = [2 1]; save(file,'flash');
verifyError(testCase,@() ce.pipeline.intervalFiles(testCase.TestData.session,'event_metrics',{}),'ce:pipeline:InvalidIntervalFile');
flash = 7; save(file,'flash');
verifyError(testCase,@() ce.pipeline.intervalFiles(testCase.TestData.session,'event_metrics',{}),'ce:pipeline:InvalidIntervalFile');
end

function testCrossStageNamesCannotOverwriteEachOther(testCase)
flash.timestamps = [1 2];
save(fullfile(testCase.TestData.folder,'synthetic.flash.events.mat'),'flash');
save(fullfile(testCase.TestData.folder,'synthetic.flash.manipulation.mat'),'flash');
verifyError(testCase,@() plans(testCase,struct()),'ce:pipeline:IntervalOutputCollision');
end

function testDuplicateStateNamesRejected(testCase)
one.ints.quiet = [1 2]; two.ints.quiet = [3 4];
save(fullfile(testCase.TestData.folder,'synthetic.one.states.mat'),'one');
save(fullfile(testCase.TestData.folder,'synthetic.two.states.mat'),'two');
verifyError(testCase,@() plans(testCase,struct()),'ce:pipeline:IntervalOutputCollision');
end

function testSkippedStageProtectsExistingOutputs(testCase)
flash.timestamps = [1 2];
save(fullfile(testCase.TestData.folder,'synthetic.flash.events.mat'),'flash');
metrics.general.manipulations.flash.event_file = 'synthetic.flash.manipulation.mat';
testCase.TestData.parameters.excludeMetrics = {'manipulation_metrics'};
verifyError(testCase,@() plans(testCase,metrics),'ce:pipeline:IntervalOutputCollision');
end

function testLegacyOwnershipAndIgnoredInputs(testCase)
flash.timestamps = [1 2]; save(fullfile(testCase.TestData.folder,'synthetic.flash.events.mat'),'flash');
metrics.general.events.flash.event_file = 'synthetic.flash.events.mat';
metrics.general.states.sleep.quiet = [1 2];
metrics.labels = {'keep me'};
testCase.TestData.parameters.ignoreEventTypes = {'flash'};
result = plans(testCase,metrics);
verifyEmpty(testCase,result(1).records);
verifyTrue(testCase,ismember('flash_modulationIndex',result(1).retiredOutputs));
verifyTrue(testCase,ismember('firingRate_quiet',result(3).retiredOutputs));
verifyFalse(testCase,ismember('labels',[result.retiredOutputs]));
verifyEqual(testCase,result(1).outputs,{'general.events','events'});
end

function testEmptyInputsDoNotDeclareUndefinedMetrics(testCase)
flash.timestamps = zeros(0,2); sleep.ints.quiet = zeros(0,2);
save(fullfile(testCase.TestData.folder,'synthetic.flash.events.mat'),'flash');
save(fullfile(testCase.TestData.folder,'synthetic.sleep.states.mat'),'sleep');
result = plans(testCase,struct());
verifyFalse(testCase,ismember('flash_modulationIndex',result(1).outputs));
verifyFalse(testCase,ismember('firingRate_quiet',result(3).outputs));
end

function testRetiredOutputsClearedOnlyAfterSuccess(testCase)
metrics.events.old = {1}; metrics.old_modulationIndex = 7;
metrics.labels = {'keep me'};
definition = struct('name','dynamic_example','version',1,'dependencies',{{}}, ...
    'outputs',{{'events'}},'requiredOutputs',{{'events'}});
settings = struct('randomSeed',0);
[after,result] = ce.pipeline.runStage(metrics,definition,struct(),settings, ...
    @() error('test:FailedStage','Deliberate failure.'),false,{'old_modulationIndex'});
verifyEqual(testCase,result.status,'failed'); verifyEqual(testCase,after,metrics);
[after,result] = ce.pipeline.runStage(metrics,definition,struct(),settings, ...
    @() struct('events',struct()),false,{'old_modulationIndex'});
verifyEqual(testCase,result.status,'completed');
verifyFalse(testCase,isfield(after,'old_modulationIndex'));
verifyEmpty(testCase,fieldnames(after.events));
verifyEqual(testCase,after.labels,metrics.labels);
[again,result] = ce.pipeline.runStage(after,definition,struct(),settings, ...
    @() error('test:UnexpectedCalculation','Expected reuse.'),false,{});
verifyEqual(testCase,result.status,'reused'); verifyEqual(testCase,again,after);
end

function result = plans(testCase,metrics)
result = ce.pipeline.intervalStagePlans(metrics,testCase.TestData.session, ...
    testCase.TestData.parameters,testCase.TestData.preferences);
end
