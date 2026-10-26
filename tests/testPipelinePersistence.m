function tests = testPipelinePersistence
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder); testCase.TestData.folder = folder;
session.general = struct('name','synthetic','basePath',folder);
testCase.TestData.session = session;
parameters = ce.pipeline.parseParameters('headless',true,'basepath',folder);
testCase.TestData.parameters = parameters;
cell_metrics = struct('UID',[7 9],'labels',{{'first','second'}});
cell_metrics.general.cellCount = 2;
testCase.TestData.metrics = cell_metrics;
notes = 'preserve the entire old file'; %#ok<NASGU>
save(fullfile(folder,'synthetic.cell_metrics.cellinfo.mat'),'cell_metrics','notes');
save(fullfile(folder,'synthetic.session.mat'),'session');
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testExactBackupAndVerifiedSessionSave(testCase)
plan = begin(testCase);
metrics = testCase.TestData.metrics; metrics.labels{1} = 'updated';
session = testCase.TestData.session; session.general.sessionName = 'synthetic';
result = ce.pipeline.saveOutputs(metrics,session,plan,struct());
verifyTrue(testCase,result.saved);
verifyEqual(testCase,ce.pipeline.fileFingerprint(result.backup),plan.metricsHash);
saved = load(plan.metricsFile,'cell_metrics'); verifyEqual(testCase,saved.cell_metrics,metrics);
saved = load(plan.sessionFile,'session'); verifyEqual(testCase,saved.session,session);
verifyTrue(testCase,contains(result.backup,[filesep,'cell_metrics_']));
end

function testSaveMatFalseCreatesNoBackupOrOutputs(testCase)
testCase.TestData.parameters.saveMat = false;
plan = begin(testCase); before = dir(testCase.TestData.folder);
outputs.theta = struct('file',fullfile(testCase.TestData.folder,'should_not_exist.mat'),'data',struct(),'expectedHash','');
result = ce.pipeline.saveOutputs(testCase.TestData.metrics,testCase.TestData.session,plan,outputs);
verifyFalse(testCase,result.saved); verifyEqual(testCase,dir(testCase.TestData.folder),before);
end

function testInvalidMetricsPreserveFilesBeforeBackup(testCase)
plan = begin(testCase);
metrics = testCase.TestData.metrics; metrics.UID = [7;9];
verifyError(testCase,@() ce.pipeline.saveOutputs(metrics,testCase.TestData.session,plan,struct()),'');
verifyEqual(testCase,ce.pipeline.fileFingerprint(plan.metricsFile),plan.metricsHash);
verifyEqual(testCase,ce.pipeline.fileFingerprint(plan.sessionFile),plan.sessionHash);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testConcurrentEditAbortsBeforeAnyWrites(testCase)
for target = {'metricsFile','sessionFile'}
    plan = begin(testCase);
    file = plan.(target{1}); changed = 17; save(file,'changed');
    hash = ce.pipeline.fileFingerprint(file);
    verifyError(testCase,@() ce.pipeline.saveOutputs(testCase.TestData.metrics,testCase.TestData.session,plan,struct()),'ce:io:PipelineRevisionChanged');
    verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
    verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end
end

function testBackupFailurePreservesDestinations(testCase)
plan = begin(testCase);
fid = fopen(fullfile(testCase.TestData.folder,'revisions_cell_metrics'),'w'); fclose(fid);
verifyError(testCase,@() ce.pipeline.saveOutputs(testCase.TestData.metrics,testCase.TestData.session,plan,struct()),'ce:io:BackupFailed');
verifyEqual(testCase,ce.pipeline.fileFingerprint(plan.metricsFile),plan.metricsHash);
verifyEqual(testCase,ce.pipeline.fileFingerprint(plan.sessionFile),plan.sessionHash);
end

function testInvalidSessionDestinationFailsBeforeMetricReplacement(testCase)
plan = begin(testCase);
delete(plan.sessionFile); mkdir(plan.sessionFile);
verifyError(testCase,@() ce.pipeline.saveOutputs(testCase.TestData.metrics,testCase.TestData.session,plan,struct()),'ce:io:InvalidDestination');
verifyEqual(testCase,ce.pipeline.fileFingerprint(plan.metricsFile),plan.metricsHash);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function plan = begin(testCase)
plan = ce.pipeline.beginPersistence(testCase.TestData.session,testCase.TestData.parameters);
end
