function tests = testPersistence
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname;
mkdir(folder);
testCase.TestData.folder = folder;
end

function teardown(testCase)
rmdir(testCase.TestData.folder, 's');
end

function testLegacyMatRoundTrip(testCase)
cell_metrics = fixture;
file = fullfile(testCase.TestData.folder, 'metrics.mat');
verifyWarningFree(testCase, @() saveCellMetrics(cell_metrics, file));
loaded = load(file);
verifyEqual(testCase, fieldnames(loaded), {'cell_metrics'});
verifyEqual(testCase, loaded.cell_metrics, cell_metrics);
cell_metrics.labels = {'changed','second'};
ce.io.saveCellMetrics(cell_metrics, file);
loaded = load(file);
verifyEqual(testCase, loaded.cell_metrics, cell_metrics);
verifyEqual(testCase, numel(dir(fullfile(testCase.TestData.folder,'*.mat'))), 1);
end

function testJsonPreservesLiteralText(testCase)
file = fullfile(testCase.TestData.folder, 'metrics.json');
cell_metrics = fixture;
cell_metrics.labels = {'100% good: %s %d', 'C:\new\trial µV'};
verifyWarningFree(testCase, @() saveCellMetrics(cell_metrics, file));
loaded = jsondecode(fileread(file));
verifyEqual(testCase, loaded.labels(:), cell_metrics.labels(:));
end

function testLegacyVariableInference(testCase)
ripples.timestamps = [1 2; 3 4];
ok = saveStruct(ripples, 'events', 'basepath', testCase.TestData.folder, ...
    'basename', 'synthetic', 'commandDisp', false);
verifyTrue(testCase, ok);
loaded = load(fullfile(testCase.TestData.folder, 'synthetic.ripples.events.mat'));
verifyEqual(testCase, loaded.ripples, ripples);
verifyEqual(testCase, loadStruct('ripples','events','basepath',testCase.TestData.folder, ...
    'basename','synthetic'), ripples);
end

function testLegacySessionInferenceAndJson(testCase)
session.general.name = 'synthetic';
session.general.basePath = testCase.TestData.folder;
verifyTrue(testCase, saveStruct(session));
loaded = load(fullfile(testCase.TestData.folder, 'synthetic.session.mat'));
verifyEqual(testCase, loaded.session, session);
verifyTrue(testCase, saveStruct(session,'session','fileformat','json','commandDisp',false));
loaded = jsondecode(fileread(fullfile(testCase.TestData.folder,'synthetic.session.json')));
verifyEqual(testCase, loaded, session);
end

function testIntervalMetricsKeepMatVariableName(testCase)
cell_metrics = fixture;
ce.io.saveStruct(cell_metrics, 'cellinfo', 'basepath', testCase.TestData.folder, ...
    'basename', 'synthetic', 'dataName', 'cell_metrics.NREM', 'commandDisp', false);
loaded = load(fullfile(testCase.TestData.folder, 'synthetic.cell_metrics.NREM.cellinfo.mat'));
verifyEqual(testCase, fieldnames(loaded), {'cell_metrics'});
verifyEqual(testCase, loaded.cell_metrics, cell_metrics);
end

function testPackageRequiresExplicitDataName(testCase)
verifyError(testCase, @() ce.io.saveStruct(fixture, 'cellinfo', ...
    'basepath',testCase.TestData.folder,'basename','synthetic'), 'ce:io:MissingDataName');
end

function testUnsupportedFormatsFail(testCase)
verifyError(testCase, @() saveCellMetrics(fixture, fullfile(testCase.TestData.folder,'metrics.txt')), ...
    'ce:io:UnsupportedFormat');
verifyError(testCase, @() ce.io.saveStruct(fixture,'cellinfo','dataName','cell_metrics', ...
    'basepath',testCase.TestData.folder,'basename','synthetic','fileformat','txt'), 'ce:io:UnsupportedFormat');
verifyError(testCase, @() ce.io.saveStruct(struct(),'events','dataName','ripples', ...
    'basepath',testCase.TestData.folder,'basename','synthetic','fileformat','nwb'), 'ce:io:UnsupportedDatatype');
verifyError(testCase, @() loadStruct('unknown','unsupported','basepath',testCase.TestData.folder, ...
    'basename','synthetic'), 'ce:io:UnsupportedDatatype');
files = dir(testCase.TestData.folder);
verifyEmpty(testCase, files(~[files.isdir]));
end

function testWriterFailurePreservesOriginal(testCase)
file = fullfile(testCase.TestData.folder, 'metrics.mat');
ce.io.saveCellMetrics(fixture, file);
before = readBytes(file);
verifyError(testCase, @() ce.io.writeAtomic(file, @failingWriter, @(unused) []), 'ce:test:InjectedFailure');
verifyEqual(testCase, readBytes(file), before);
verifyEqual(testCase, numel(dir(fullfile(testCase.TestData.folder,'*.mat'))), 1);
end

function testVerifierFailurePreservesOriginal(testCase)
file = fullfile(testCase.TestData.folder, 'metrics.mat');
ce.io.saveCellMetrics(fixture, file);
before = readBytes(file);
verifyError(testCase, @() ce.io.writeAtomic(file, @writePartial, @failingVerifier), 'ce:test:InjectedFailure');
verifyEqual(testCase, readBytes(file), before);
verifyEqual(testCase, numel(dir(fullfile(testCase.TestData.folder,'*.mat'))), 1);
end

function testMissingWriterOutputFails(testCase)
file = fullfile(testCase.TestData.folder, 'missing.mat');
verifyError(testCase, @() ce.io.writeAtomic(file, @(unused) [], @(unused) []), 'ce:io:MissingOutput');
verifyFalse(testCase, isfile(file));
end

function testInvalidDestinationFails(testCase)
verifyError(testCase, @() ce.io.saveCellMetrics(fixture, ...
    fullfile(testCase.TestData.folder,'absent','metrics.mat')), 'ce:io:InvalidDestination');
end

function testNwbAdapterRoutingAndFailurePreservation(testCase)
% Exercise the existing adapter boundary without claiming MatNWB validation.
fixtureSource = fullfile(fileparts(mfilename('fullpath')),'fixtures','nwb_adapter','saveCellMetrics2nwb.m.txt');
fixturePath = fullfile(testCase.TestData.folder,'adapter');
mkdir(fixturePath);
copyfile(fixtureSource,fullfile(fixturePath,'saveCellMetrics2nwb.m'));
originalPath = path;
cleanup = onCleanup(@() path(originalPath));
addpath(fixturePath, '-begin');
metrics = fixture;
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.nwb');
verifyTrue(testCase, saveStruct(metrics,'cellinfo','basepath',testCase.TestData.folder, ...
    'basename','synthetic','dataName','cell_metrics','fileformat','nwb','commandDisp',false));
verifyEqual(testCase,h5read(file,'/UID'),metrics.UID);
before = readBytes(file);
metrics.failExport = true;
verifyError(testCase,@() ce.io.saveCellMetrics(metrics,file),'ce:test:ExportFailed');
verifyEqual(testCase,readBytes(file),before);
verifyEqual(testCase,numel(dir(fullfile(testCase.TestData.folder,'*.nwb'))),1);
end

function testCoreWorksWithoutLegacyPath(testCase)
originalPath = path;
cleanup = onCleanup(@() path(originalPath));
root = fileparts(fileparts(mfilename('fullpath')));
rmpath(fullfile(root,'calc_CellMetrics'));
ce.io.saveStruct(fixture,'cellinfo','basepath',testCase.TestData.folder, ...
    'basename','synthetic','dataName','cell_metrics','commandDisp',false);
loaded = ce.io.loadStruct('cell_metrics','cellinfo','basepath',testCase.TestData.folder,'basename','synthetic');
verifyEqual(testCase,loaded,fixture);
verifyEqual(testCase,ce.metrics.calc_gini(ones(1,4)),0);
ce.data.validateCellMetricsStruct(loaded);
end

function testBasenameDiscoveryCompatibility(testCase)
folder = testCase.TestData.folder;
variables.session = struct();
ce.io.writeMat(fullfile(folder,'recording.session.mat'),variables);
verifyEqual(testCase,ce.io.basenameFromBasepath(folder),'recording');
verifyEqual(testCase,basenameFromBasepath(folder),'recording');
end

function failingWriter(file)
writePartial(file);
error('ce:test:InjectedFailure','Simulated interrupted writer.');
end

function writePartial(file)
fid = fopen(file,'w');
fwrite(fid,'partial output');
fclose(fid);
end

function failingVerifier(~)
error('ce:test:InjectedFailure','Simulated failed verification.');
end

function bytes = readBytes(file)
fid = fopen(file,'r');
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid,Inf,'*uint8');
end

function metrics = fixture
metrics.general.cellCount = 2;
metrics.UID = [1 2];
metrics.firingRate = [1.5 2.5];
metrics.labels = {'first','second'};
end
