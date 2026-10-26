function tests = testWaveformStages
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder);
testCase.TestData.folder = folder;
session.general = struct('name','synthetic','basePath',folder);
session.animal.name = 'synthetic';
session.extracellular = struct('sr',20000,'nChannels',8,'precision','int16', ...
    'leastSignificantBit',.195,'nElectrodeGroups',1,'nSpikeGroups',1, ...
    'electrodeGroups',struct('channels',{{1:8}}),'spikeGroups',struct('channels',{{1:8}}));
session.channelTags = struct(); session.analysisTags = struct();
session.spikeSorting = {struct('format','Phy','relativePath','')};
session.extracellular.chanCoords = struct('x',mod((0:7)',2)*20,'y',-(0:7)'*20);
testCase.TestData.session = session;
spikes = struct('times',{{(.05:.05:.95)'}},'UID',1,'cluID',11,'shankID',1,'maxWaveformCh1',1);
testCase.TestData.spikes = spikes;
samples = 20000;
data = repmat(3*sin((1:samples)*.023),8,1);
window = -40:39;
wave = -800*exp(-(window/3).^2)+300*exp(-((window-9)/5).^2);
for time = spikes.times{1}'
    indices = round(time*20000)+window;
    data(:,indices) = data(:,indices)+(1./(1:8)')*wave;
end
writeRaw(fullfile(folder,'synthetic.dat'),int16(data));
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testExtractionMatchesLegacyAndReuses(testCase)
[session,spikes,parameters,preferences] = fixture(testCase);
before = rng;
[actual,result,cache,file] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
assertEqual(testCase,result.status,'completed',result.error.message);
expected = ce.pipeline.withRandomSeed(parameters.randomSeed,@() getWaveformsFromDat(spikes,session, ...
    'nPull',preferences.waveform.nPull,'showWaveforms',false,'saveMat',false));
for name = ce.pipeline.waveformFields
    verifyEqual(testCase,actual.(name{1}),expected.(name{1}));
end
verifyEqual(testCase,rng,before);
verifyFalse(testCase,isfile(file),'Preparation must not write its cache.');
ce.io.writeMat(file,struct('waveformCache',cache));
[again,result] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.status,'reused');
verifyEqual(testCase,again,actual);
verifyFalse(testCase,isfile(fullfile(session.general.basePath,'synthetic.noiseLevel.channelInfo.mat')));
verifyFalse(testCase,isfile(fullfile(session.general.basePath,'synthetic.spikes.cellinfo.mat')));
end

function testRawContentAndSettingsInvalidate(testCase)
[session,spikes,parameters,preferences] = fixture(testCase);
[~,result,cache,file] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
assertEqual(testCase,result.status,'completed',result.error.message);
ce.io.writeMat(file,struct('waveformCache',cache));
rawFile = fullfile(session.general.basePath,'synthetic.dat');
fid = fopen(rawFile,'r+'); fwrite(fid,int16(123),'int16'); fclose(fid); % Same file size.
[~,result] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,result.reason,'changed_inputHash');
preferences.waveform.nPull = 4;
[~,result,cache] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
ce.io.writeMat(file,struct('waveformCache',cache));
parameters.randomSeed = 9;
[~,result] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.reason,'changed_parameterHash');
end

function testPipelineReusesSidecarWithoutChangingCanonicalSpikes(testCase)
[session,spikes,~,~] = fixture(testCase);
folder = session.general.basePath;
sessionFile = fullfile(folder,'synthetic.session.mat');
spikesFile = fullfile(folder,'synthetic.spikes.cellinfo.mat');
metricsFile = fullfile(folder,'synthetic.cell_metrics.cellinfo.mat');
save(sessionFile,'session'); save(spikesFile,'spikes');
cell_metrics = struct('UID',1,'waveforms',struct(),'putativeCellType',{{'Unknown'}});
cell_metrics.general = struct('cellCount',1,'session',struct(),'animal',struct());
save(metricsFile,'cell_metrics');
before = ce.pipeline.fileFingerprint(spikesFile);
figures = findall(0,'Type','figure');
options = {'basepath',folder,'headless',true,'metrics',{'waveform_metrics'}, ...
    'excludeManipulationIntervals',false,'saveBackup',false};
first = ProcessCellMetrics(options{:});
results = first.general.processinginfo.latestRun.stages;
verifyEqual(testCase,{results(1:3).status},{'completed','completed','completed'});
sidecar = fullfile(folder,'synthetic.cell_metrics.waveformExtraction.cache.mat');
verifyTrue(testCase,isfile(sidecar));
again = ProcessCellMetrics(options{:});
results = again.general.processinginfo.latestRun.stages;
verifyEqual(testCase,{results(1:3).status},{'reused','reused','reused'});
verifyEqual(testCase,again.general.processinginfo.stages,first.general.processinginfo.stages);
verifyEqual(testCase,ce.pipeline.fileFingerprint(spikesFile),before);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
before = {ce.pipeline.fileFingerprint(sidecar),ce.pipeline.fileFingerprint(metricsFile),ce.pipeline.fileFingerprint(sessionFile)};
ProcessCellMetrics(options{:},'saveMat',false,'randomSeed',1);
verifyEqual(testCase,{ce.pipeline.fileFingerprint(sidecar),ce.pipeline.fileFingerprint(metricsFile),ce.pipeline.fileFingerprint(sessionFile)},before);
end

function testRestrictedExtractionUsesSeparateCache(testCase)
[session,spikes,parameters,preferences] = fixture(testCase);
[~,result,cache,file] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
assertEqual(testCase,result.status,'completed',result.error.message);
ce.io.writeMat(file,struct('waveformCache',cache));
before = ce.pipeline.fileFingerprint(file);
spikes.times{1} = spikes.times{1}(1:5);
parameters.restrictToIntervals = [0 .26];
[~,result,newCache] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,result.reason,'changed_inputHash');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
ce.io.writeMat(file,struct('waveformCache',newCache));
[~,result] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.status,'reused');
end

function testManagedImportBootstrapsRawWaveformsAndMetrics(testCase)
session = testCase.TestData.session; session.spikeSorting{1}.format = 'Neurosuite';
folder = session.general.basePath;
samples = round(testCase.TestData.spikes.times{1}*session.extracellular.sr);
writematrix([3;2*ones(size(samples))],fullfile(folder,'synthetic.clu.1'),'FileType','text');
writematrix(samples,fullfile(folder,'synthetic.res.1'),'FileType','text');
options = {'session',session,'headless',true,'spikeImport',struct('format','neurosuite'), ...
    'metrics',{'waveform_metrics','acg_metrics','other_metrics'},'saveBackup',false, ...
    'excludeManipulationIntervals',false};
figures = findall(0,'Type','figure');
first = ProcessCellMetrics(options{:});
verifySize(testCase,first.general.sortingRevision,[1 64]);
verifyEqual(testCase,first.UID,1); verifyEqual(testCase,first.cluID,2);
verifyTrue(testCase,isfield(first,'waveforms')); verifyTrue(testCase,isfield(first,'acg_tau_rise'));
verifyFalse(testCase,isfile(fullfile(folder,'synthetic.spikes.cellinfo.mat')));
cache = load(fullfile(folder,'synthetic.spikeImport.cache.mat'),'spikeImportCache');
verifyFalse(testCase,isfield(cache.spikeImportCache.data,'maxWaveformCh1'));
verifyEqual(testCase,first.general.sortingRevision,ce.pipeline.spikeSortingRevision(cache.spikeImportCache.data));
again = ProcessCellMetrics(options{:}); results = again.general.processinginfo.latestRun.stages;
names = {'spike_import','waveform_extraction','waveform_shape','waveform_localization','acg_metrics','other_metrics'};
[found,indices] = ismember(names,{results.name}); verifyTrue(testCase,all(found));
verifyEqual(testCase,{results(indices).status},repmat({'reused'},1,numel(names)));
verifyEqual(testCase,findall(0,'Type','figure'),figures);
end

function testExtractionFailurePreservesCache(testCase)
[session,spikes,parameters,preferences] = fixture(testCase);
[~,result,cache,file] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
assertEqual(testCase,result.status,'completed',result.error.message);
ce.io.writeMat(file,struct('waveformCache',cache));
before = ce.pipeline.fileFingerprint(file);
preferences.waveform.wfWinKeep = .1; % Impossible retained window.
[unchanged,result] = ce.pipeline.prepareWaveforms(spikes,session,parameters,preferences,1);
verifyEqual(testCase,result.status,'failed');
verifyEqual(testCase,unchanged,spikes);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
end

function testPhyTimestampsBootstrapRawWaveformsAndReuse(testCase)
originalPath=path; pathCleanup=onCleanup(@() path(originalPath));
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'toolboxes','npy-matlb'));
session=testCase.TestData.session; folder=session.general.basePath;
samples=round(testCase.TestData.spikes.times{1}*session.extracellular.sr);
writeNPY(uint64(samples),fullfile(folder,'spike_times.npy'));
writeNPY(int32(7*ones(size(samples))),fullfile(folder,'spike_clusters.npy'));
fid=fopen(fullfile(folder,'cluster_group.tsv'),'w'); fprintf(fid,'cluster_id\tgroup\n7\tgood\n'); fclose(fid);
options={'session',session,'headless',true,'spikeImport',struct('format','phy'), ...
    'metrics',{'waveform_metrics','acg_metrics','other_metrics'},'saveBackup',false, ...
    'excludeManipulationIntervals',false};
first=ProcessCellMetrics(options{:});
verifyEqual(testCase,first.cluID,7); verifySize(testCase,first.general.sortingRevision,[1 64]);
cache=load(fullfile(folder,'synthetic.spikeImport.cache.mat'),'spikeImportCache');
verifyFalse(testCase,isfield(cache.spikeImportCache.data,'shankID'));
verifyEqual(testCase,first.general.sortingRevision,ce.pipeline.spikeSortingRevision(cache.spikeImportCache.data));
again=ProcessCellMetrics(options{:}); results=again.general.processinginfo.latestRun.stages;
names={'spike_import','waveform_extraction','waveform_shape','waveform_localization','acg_metrics','other_metrics'};
[found,indices]=ismember(names,{results.name}); verifyTrue(testCase,all(found));
verifyEqual(testCase,{results(indices).status},repmat({'reused'},1,numel(names)));
verifyFalse(testCase,isfile(fullfile(folder,'synthetic.spikes.cellinfo.mat')));
end

function testCoordinateSourcesRefreshAndValidate(testCase)
session = testCase.TestData.session;
explicit = ce.pipeline.resolveGeometry(session);
chanCoords = struct('x',(101:108)','y',(1:8)');
file = fullfile(session.general.basePath,'synthetic.chanCoords.channelInfo.mat');
save(file,'chanCoords');
verifyEqual(testCase,ce.pipeline.resolveGeometry(session),explicit); % Explicit metadata wins.
session.extracellular = rmfield(session.extracellular,'chanCoords');
first = ce.pipeline.resolveGeometry(session);
verifyEqual(testCase,first.chanCoords,chanCoords);
chanCoords.x = chanCoords.x + 1; save(file,'chanCoords');
second = ce.pipeline.resolveGeometry(session);
verifyNotEqual(testCase,ce.pipeline.fingerprint(first),ce.pipeline.fingerprint(second));
verifyFalse(testCase,isfield(session.extracellular,'chanCoords'));
chanCoords.x = [1 2]; save(file,'chanCoords');
verifyError(testCase,@() ce.pipeline.resolveGeometry(session),'ce:pipeline:InvalidCoordinates');
end

function testMissingCcfRemovesOwnedOutputs(testCase)
[session,spikes,~,~] = fixture(testCase);
ccf = struct('x',nan(8,1),'y',nan(8,1),'z',nan(8,1));
file = fullfile(session.general.basePath,'synthetic.ccf.channelInfo.mat'); save(file,'ccf');
metrics = struct('peakVoltage',NaN,'maxWaveformCh1',1,'waveforms',struct());
settings = struct('randomSeed',0,'preferences',struct('trilat_nChannels',8));
options = struct('debugMode',false,'showFigures',false);
definition = ce.pipeline.stageDefinition('waveform_localization');
inputs = ce.pipeline.localizationInputs(metrics,spikes,session,ce.pipeline.resolveGeometry(session));
[metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@() ce.pipeline.stages.localizeWaveforms(inputs,settings,options));
assertEqual(testCase,result.status,'completed',result.error.message);
verifyTrue(testCase,isfield(metrics,'ccf_x'));
delete(file);
inputs = ce.pipeline.localizationInputs(metrics,spikes,session,ce.pipeline.resolveGeometry(session));
[metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@() ce.pipeline.stages.localizeWaveforms(inputs,settings,options));
verifyEqual(testCase,result.status,'completed');
verifyFalse(testCase,isfield(metrics,'ccf_x'));
verifyFalse(testCase,isfield(metrics.general,'ccf'));
end

function testRawSizeAndPrecisionRejected(testCase)
session = testCase.TestData.session;
session.extracellular.precision = 'single';
verifyError(testCase,@() ce.pipeline.rawRecording(session),'ce:pipeline:UnsupportedRawPrecision');
session.extracellular.precision = 'int16';
writeRaw(fullfile(session.general.basePath,'synthetic.dat'),int16([1 2 3]));
verifyError(testCase,@() ce.pipeline.rawRecording(session),'ce:pipeline:InvalidRawSize');
end

function [session,spikes,parameters,preferences] = fixture(testCase)
session = testCase.TestData.session;
spikes = testCase.TestData.spikes;
parameters = ce.pipeline.parseParameters('headless',true,'basepath',session.general.basePath);
preferences = preferences_ProcessCellMetrics(session);
preferences.waveform.nPull = 5;
end

function writeRaw(file,data)
fid = fopen(file,'w'); cleanup = onCleanup(@() fclose(fid));
fwrite(fid,data,'int16');
end
