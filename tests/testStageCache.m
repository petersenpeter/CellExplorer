function tests = testStageCache
tests = functiontests(localfunctions);
end

function testTypedFingerprints(testCase)
a = struct('b',{{[1 NaN],"hello"}},'a',sparse(eye(2)));
b = orderfields(a,{'a','b'});
verifyEqual(testCase,ce.pipeline.fingerprint(a),ce.pipeline.fingerprint(b));
values = {1,single(1),uint8(1),true,[1 2],[1;2],complex(1,2),'1',"1",{1}};
hashes = cellfun(@ce.pipeline.fingerprint,values,'UniformOutput',false);
verifyEqual(testCase,numel(unique(hashes)),numel(values));
verifyError(testCase,@() ce.pipeline.fingerprint(@sin),'ce:pipeline:UnsupportedFingerprintType');
end

function testReuseKeepsOriginalProvenanceAndAnnotations(testCase)
[definition,inputs,settings] = fixture;
[metrics,first] = ce.pipeline.runStage(struct(),definition,inputs,settings,@compute);
verifyEqual(testCase,first.status,'completed');
metrics.labels = {'manually reviewed'};
[again,reused] = ce.pipeline.runStage(metrics,definition,inputs,settings,@fail);
verifyEqual(testCase,reused.status,'reused');
verifyEqual(testCase,again,metrics);
verifyEqual(testCase,reused.provenance,first.provenance);
end

function testInvalidation(testCase)
[definition,inputs,settings] = fixture;
[metrics,first] = ce.pipeline.runStage(struct(),definition,inputs,settings,@compute);
assertEqual(testCase,first.status,'completed');
changed = inputs; changed.times{1}(2) = 3;
[~,result] = ce.pipeline.runStage(metrics,definition,changed,settings,@compute);
verifyEqual(testCase,result.reason,'changed_inputHash');
changedSettings = settings; changedSettings.restrictToIntervals = [1 2];
[~,result] = ce.pipeline.runStage(metrics,definition,inputs,changedSettings,@compute);
verifyEqual(testCase,result.reason,'changed_parameterHash');
changedDefinition = definition; changedDefinition.version = 2;
[~,result] = ce.pipeline.runStage(metrics,changedDefinition,inputs,settings,@compute);
verifyEqual(testCase,result.reason,'changed_stageVersion');
tampered = metrics; tampered.acg.value(1) = 99;
[repaired,result] = ce.pipeline.runStage(tampered,definition,inputs,settings,@compute);
verifyEqual(testCase,result.reason,'changed_outputs');
verifyEqual(testCase,repaired.acg,metrics.acg);
[~,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@compute,true);
verifyEqual(testCase,result.reason,'forced');
end

function testImplementationChangeInvalidates(testCase)
[definition,inputs,settings] = fixture;
folder = tempname; mkdir(folder);
originalPath = path; cleanup = onCleanup(@() removeFixture(folder,originalPath));
file = fullfile(folder,'cacheDependency.m');
writeFile(file,'function cacheDependency; end');
addpath(folder);
definition.dependencies = {'cacheDependency'};
[metrics,result] = ce.pipeline.runStage(struct(),definition,inputs,settings,@compute);
assertEqual(testCase,result.status,'completed');
writeFile(file,'function cacheDependency; disp(1); end');
[~,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@compute);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,result.reason,'changed_implementationHash');
end

function testFailurePreservesMetricsAndRandomState(testCase)
[definition,inputs,settings] = fixture;
before = rng;
[metrics,result] = ce.pipeline.runStage(struct(),definition,inputs,settings,@compute);
assertEqual(testCase,result.status,'completed');
verifyEqual(testCase,rng,before);
[after,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@fail,true);
verifyEqual(testCase,result.status,'failed');
verifyEqual(testCase,result.error.identifier,'test:StageFailure');
verifyEqual(testCase,after,metrics);
verifyEqual(testCase,rng,before);
[after,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@() struct('unrelated',1),true);
verifyEqual(testCase,result.error.identifier,'ce:pipeline:MissingStageOutput');
verifyEqual(testCase,after,metrics);
end

function testOptionalOutputsRemovedWithoutLosingUnrelatedFields(testCase)
[definition,inputs,settings] = fixture;
metrics.acg.unrelated = 42;
metrics.acg.optional = 99;
[metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@compute);
verifyEqual(testCase,result.status,'completed');
verifyFalse(testCase,isfield(metrics.acg,'optional'));
verifyEqual(testCase,metrics.acg.unrelated,42);
end

function [definition,inputs,settings] = fixture
definition = struct('name','example','version',1, ...
    'outputs',{{'acg.value','acg.optional'}},'requiredOutputs',{{'acg.value'}},'dependencies',{{}});
inputs.times = {[1 2]};
settings = struct('randomSeed',0,'restrictToIntervals',[]);
end

function patch = compute
patch.acg.value = rand(1,3);
end

function patch = fail
rand(1,4);
error('test:StageFailure','Deliberate stage failure.');
patch = struct(); %#ok<UNRCH>
end

function removeFixture(folder,originalPath)
path(originalPath);
rmdir(folder,'s');
end

function writeFile(file,content)
fid = fopen(file,'w'); cleanup = onCleanup(@() fclose(fid));
fwrite(fid,content,'char');
end
