function tests = testSessionPreflight
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname;
mkdir(folder);
testCase.TestData.folder = folder;
testCase.TestData.session = fixture(folder);
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testMinimalMetadataValidWithoutFiles(testCase)
report = ce.data.validateSession(testCase.TestData.session,'checkFiles',false);
verifyTrue(testCase,report.valid);
verifyEmpty(testCase,report.errors);
end

function testMissingParentsProduceReport(testCase)
report = ce.data.validateSession(struct(),'checkFiles',false);
verifyFalse(testCase,report.valid);
verifyTrue(testCase,ismember('general.name',{report.errors.path}));
verifyTrue(testCase,ismember('extracellular.nChannels',{report.errors.path}));
report = ce.data.validateSession(42);
verifyEqual(testCase,{report.errors.code},{'InvalidSession'});
end

function testMalformedContainersProduceReport(testCase)
session = testCase.TestData.session;
session.general = [struct('name','a'),struct('name','b')];
session.spikeSorting = {42};
session.epochs = {[],struct('name','bad','startTime',2,'stopTime',1)};
session.channelTags.Bad = 0;
report = ce.data.validateSession(session,'checkFiles',false);
verifyFalse(testCase,report.valid);
verifyTrue(testCase,ismember('InvalidEpochInterval',{report.errors.code}));
end

function testChannelBoundaries(testCase)
for value = {0,3,1.5,NaN,[1 1]}
    session = testCase.TestData.session;
    session.extracellular.electrodeGroups.channels = {value{1}};
    report = ce.data.validateSession(session,'checkFiles',false);
    verifyTrue(testCase,ismember('InvalidChannels',{report.errors.code}));
end
end

function testDuplicateGroupsAndCountMismatch(testCase)
session = testCase.TestData.session;
session.extracellular.electrodeGroups.channels = {[1 2],2};
report = ce.data.validateSession(session,'checkFiles',false);
verifyTrue(testCase,ismember('GroupCountMismatch',{report.errors.code}));
verifyTrue(testCase,ismember('DuplicateChannels',{report.errors.code}));
end

function testChannelTagsValidateOneBasedIndices(testCase)
session = testCase.TestData.session;
session.channelTags.Theta.channels = 0;
report = ce.data.validateSession(session,'checkFiles',false);
verifyTrue(testCase,ismember('channelTags.Theta.channels',{report.errors.path}));
end

function testLegacyNumericChannelRowsAccepted(testCase)
session = testCase.TestData.session;
session.extracellular.electrodeGroups.channels = [1 2];
report = ce.data.validateSession(session,'checkFiles',false);
verifyTrue(testCase,report.valid);
verifyTrue(testCase,ismember('LegacyChannelGroups',{report.warnings.code}));
verifyEqual(testCase,session.extracellular.electrodeGroups.channels,[1 2]);
end

function testMissingOptionalFilesAreWarnings(testCase)
report = ce.data.validateSession(testCase.TestData.session);
verifyTrue(testCase,report.valid);
verifyTrue(testCase,ismember('MissingRawData',{report.warnings.code}));
end

function testMissingBasepathIsError(testCase)
session = testCase.TestData.session;
session.general.basePath = fullfile(testCase.TestData.folder,'missing');
report = ce.data.validateSession(session);
verifyTrue(testCase,ismember('MissingBasepath',{report.errors.code}));
end

function testHeadlessOptionsOverrideDisplayFlags(testCase)
parameters = ce.pipeline.parseParameters('headless',true,'showGUI',true,'manualAdjustMonoSyn',true);
for field = {'showGUI','showFigures','showWaveforms','summaryFigures','sessionSummaryFigure', ...
        'manualAdjustMonoSyn','debugMode','transferFilesFromClusterpath'}
    verifyFalse(testCase,parameters.(field{1}));
end
interactive = ce.pipeline.parseParameters;
verifyTrue(testCase,interactive.manualAdjustMonoSyn);
verifyTrue(testCase,interactive.showWaveforms);
end

function testPreflightDoesNotWriteOpenFiguresOrChangeDirectory(testCase)
writeCachedSession(testCase);
before = sessionFiles(testCase.TestData.folder);
cwd = pwd;
figures = findall(0,'Type','figure');
options = coreOptions(testCase);
[report,context] = ce.pipeline.preflight(options{:});
verifyTrue(testCase,report.valid,evalc('disp(report.errors)'));
verifyEqual(testCase,pwd,cwd);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyEqual(testCase,sessionFiles(testCase.TestData.folder),before);
verifyEqual(testCase,context.spikes.UID,1);
verifyFalse(testCase,report.parameters.showWaveforms);
end

function testMissingSessionFailsBeforeGui(testCase)
folder = testCase.TestData.folder;
figures = findall(0,'Type','figure');
report = ce.pipeline.preflight('basepath',folder);
verifyEqual(testCase,{report.errors.code},{'MissingSession'});
verifyError(testCase,@() ProcessCellMetrics('basepath',folder,'headless',true),'ce:pipeline:PreflightFailed');
verifyEqual(testCase,findall(0,'Type','figure'),figures);
end

function testMissingSpikesReported(testCase)
options = coreOptions(testCase);
report = ce.pipeline.preflight('session',testCase.TestData.session,options{:});
verifyTrue(testCase,ismember('MissingSpikes',{report.errors.code}));
end

function testRawDataRequiredOnlyWhenRequested(testCase)
writeCachedSession(testCase);
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'getWaveformsFromDat',true);
verifyTrue(testCase,ismember('rawData',{report.errors.path}));
report = ce.pipeline.preflight(options{:});
verifyTrue(testCase,report.valid);
end

function testInvalidIntervalsRejectedBeforeProcessing(testCase)
writeCachedSession(testCase);
options = coreOptions(testCase);
for interval = {[2 1],[-1 2],[0 NaN],[0 1 2]}
    report = ce.pipeline.preflight(options{:},'restrictToIntervals',interval{1});
    verifyTrue(testCase,ismember('InvalidIntervals',{report.errors.code}));
end
end

function testLocalCopyOverridesStoredPathOnlyInMemory(testCase)
writeCachedSession(testCase);
session = testCase.TestData.session;
session.general.basePath = '/missing/original/location';
file = fullfile(testCase.TestData.folder,'synthetic.session.mat');
save(file,'session');
options = coreOptions(testCase);
[report,context] = ce.pipeline.preflight(options{:});
verifyTrue(testCase,report.valid);
verifyEqual(testCase,context.session.general.basePath,testCase.TestData.folder);
stored = load(file,'session');
verifyEqual(testCase,stored.session.general.basePath,session.general.basePath);
end

function testCustomPreferencesRejectedWithoutExecuting(testCase)
writeCachedSession(testCase);
session = testCase.TestData.session;
session.analysisTags.preferences_ProcessCellMetrics = 'nonexistent.callback';
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'session',session);
verifyTrue(testCase,ismember('UnverifiedExtension',{report.errors.code}));
end

function testInteractivePreparationReported(testCase)
writeCachedSession(testCase);
session = testCase.TestData.session;
session.channelTags.Ripple.channels = 1;
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'session',session,'metrics',{'deepSuperficial'});
verifyTrue(testCase,ismember('InteractivePreparationRequired',{report.errors.code}));
end

function testMissingNestedWaveformMetadataDoesNotCrash(testCase)
verifyTrue(testCase,ce.pipeline.needsWaveforms(struct('processinginfo',struct())));
spikes.processinginfo.params.WaveformsSource = 'dat file';
spikes.processinginfo.version = 4;
verifyFalse(testCase,ce.pipeline.needsWaveforms(spikes));
end

function testCacheIdentityMismatchRejected(testCase)
writeCachedSession(testCase);
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat');
data = load(file);
cell_metrics = data.cell_metrics;
cell_metrics.UID = 99;
save(file,'cell_metrics');
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:});
verifyTrue(testCase,ismember('CacheIdentityMismatch',{report.errors.code}));
end

function testMissingNativeDependenciesReported(testCase)
writeCachedSession(testCase);
originalPath = path;
cleanup = onCleanup(@() path(originalPath));
root = fileparts(fileparts(mfilename('fullpath')));
restoredefaultpath;
addpath(root,fullfile(root,'calc_CellMetrics'));
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'metrics',{'acg_metrics'});
verifyTrue(testCase,ismember('MissingDependency',{report.errors.code}));
verifyTrue(testCase,any(contains({report.errors.message},'CCGHeart')));
end

function testUnknownMetricRejected(testCase)
writeCachedSession(testCase);
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'metrics',{'waveforms_typo'});
verifyTrue(testCase,ismember('UnknownMetric',{report.errors.code}));
end

function testMonosynapticPreflightRequiresIntervalNative(testCase)
writeCachedSession(testCase);
originalPath = path; cleanup = onCleanup(@() path(originalPath));
root = fileparts(fileparts(mfilename('fullpath')));
restoredefaultpath;
addpath(root,fullfile(root,'calc_CellMetrics'));
options = coreOptions(testCase);
report = ce.pipeline.preflight(options{:},'metrics',{'monoSynaptic_connections'});
verifyTrue(testCase,any(contains({report.errors.message},'FindInInterval')));
end

function testHeadlessCorePipelinePreservesInputsAndCwd(testCase)
writeCachedSession(testCase);
options = coreOptions(testCase);
before = sessionFiles(testCase.TestData.folder);
cwd = pwd;
figures = findall(0,'Type','figure');
metrics = ProcessCellMetrics(options{:},'headless',true,'saveMat',false,'saveBackup',false);
verifyEqual(testCase,metrics.general.cellCount,1);
verifyEqual(testCase,metrics.spikeCount,11);
verifyEqual(testCase,metrics.firingRate,.11,'AbsTol',1e-12);
verifyEqual(testCase,metrics.cv2,0);
verifyTrue(testCase,metrics.general.processinginfo.params.headless);
verifyEqual(testCase,pwd,cwd);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyEqual(testCase,sessionFiles(testCase.TestData.folder),before);
end

function files = sessionFiles(folder)
files = dir(folder);
files = files(~ismember({files.name},{'.','..'}));
end

function options = coreOptions(testCase)
options = {'basepath',testCase.TestData.folder,'metrics',{'other_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false};
end

function writeCachedSession(testCase)
folder = testCase.TestData.folder;
session = testCase.TestData.session;
spikes.times = {(0:10:100)'};
spikes.UID = 1;
spikes.cluID = 11;
spikes.shankID = 1;
spikes.maxWaveformCh1 = 1;
cell_metrics.general.cellCount = 1;
cell_metrics.general.session = struct();
cell_metrics.general.animal = struct();
cell_metrics.UID = 1;
cell_metrics.waveforms = struct();
cell_metrics.putativeCellType = {'Unknown'};
save(fullfile(folder,'synthetic.session.mat'),'session');
save(fullfile(folder,'synthetic.spikes.cellinfo.mat'),'spikes');
save(fullfile(folder,'synthetic.cell_metrics.cellinfo.mat'),'cell_metrics');
end

function session = fixture(folder)
session.general.name = 'synthetic';
session.general.basePath = folder;
session.animal.name = 'synthetic animal';
session.extracellular.sr = 20000;
session.extracellular.nChannels = 2;
session.extracellular.leastSignificantBit = .195;
session.extracellular.precision = 'int16';
session.extracellular.nElectrodeGroups = 1;
session.extracellular.nSpikeGroups = 1;
session.extracellular.electrodeGroups.channels = {[1 2]};
session.extracellular.spikeGroups.channels = {[1 2]};
session.spikeSorting = {struct('format','Phy','relativePath','')};
end
