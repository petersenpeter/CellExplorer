function tests = testCustomCalculations
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder); mkdir(fullfile(folder,'+customCalculations'));
testCase.TestData.folder = folder;
testCase.TestData.originalPath = path; testCase.TestData.originalDirectory = pwd;
addpath(fileparts(fileparts(mfilename('fullpath')))); addpath(folder); cd(folder);
testCase.TestData.metrics = struct('UID',[7 9],'cluID',[21 42],'general',struct('cellCount',2));
testCase.TestData.spikes = {struct('UID',[7 9],'cluID',[21 42]),struct('UID',[7 9],'cluID',[21 42])};
testCase.TestData.session.general.name = 'synthetic';
testCase.TestData.parameters = ce.pipeline.parseParameters('metrics',{'ceTestExtension'});
end

function teardown(testCase)
cd(testCase.TestData.originalDirectory); path(testCase.TestData.originalPath);
clear('customCalculations.ceTestExtension');
rmdir(testCase.TestData.folder,'s');
end

function testCallbackSignatureAndSelectionPreserved(testCase)
write(testCase,"assert(numel(spikes)==2); assert(strcmp(session.general.name,'synthetic')); assert(~parameters.headless); metrics.customValue=[1 2];");
metrics = run(testCase); verifyEqual(testCase,metrics.customValue,[1 2]);
testCase.TestData.parameters.metrics = {'all'};
metrics = run(testCase); verifyEqual(testCase,metrics.customValue,[1 2]);
testCase.TestData.parameters.excludeMetrics = {'ceTestExtension'};
verifyEqual(testCase,run(testCase),testCase.TestData.metrics);
end

function testHeadlessGuardDoesNotExecuteCallback(testCase)
write(testCase,"error('test:ShouldNotRun','Callback was executed');");
testCase.TestData.parameters.headless = true;
verifyError(testCase,@() run(testCase),'ce:pipeline:UnverifiedExtension');
testCase.TestData.parameters.metrics = {'other_metrics'};
verifyEqual(testCase,run(testCase),testCase.TestData.metrics);
end

function testIdentityAndCountCannotChange(testCase)
for body = {"metrics.UID=[9 7];", "metrics=rmfield(metrics,'UID');", "metrics.cluID=[42 21];"}
    write(testCase,body{1});
    verifyError(testCase,@() run(testCase),'ce:pipeline:ExtensionIdentityChanged');
end
for body = {"metrics.general.cellCount=1;", "metrics=42;", "metrics=rmfield(metrics,'general');"}
    write(testCase,body{1});
    verifyError(testCase,@() run(testCase),'ce:pipeline:InvalidExtensionOutput');
end
end

function testCallbackFailurePropagates(testCase)
write(testCase,"error('test:ExtensionFailed','Synthetic failure');");
verifyError(testCase,@() run(testCase),'test:ExtensionFailed');
end

function write(testCase,body)
file = fullfile(testCase.TestData.folder,'+customCalculations','ceTestExtension.m');
fid = fopen(file,'w'); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'function metrics = ceTestExtension(metrics,session,spikes,parameters)\n%s\nend\n',body);
clear cleanup;
clear('customCalculations.ceTestExtension'); rehash;
end

function metrics = run(testCase)
metrics = ce.pipeline.runCustomCalculations(testCase.TestData.metrics,testCase.TestData.session, ...
    testCase.TestData.spikes,testCase.TestData.parameters);
end
