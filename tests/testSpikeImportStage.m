function tests = testSpikeImportStage
tests = functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); mkdir(fullfile(folder,'sorting'));
testCase.TestData.folder=folder;
session.general=struct('name','synthetic','basePath',folder);
session.animal.name='synthetic';
session.extracellular=struct('sr',20000,'nChannels',4,'precision','int16','leastSignificantBit',.195, ...
    'nElectrodeGroups',2,'nSpikeGroups',2, ...
    'electrodeGroups',struct('channels',{{[1 2],[3 4]}}),'spikeGroups',struct('channels',{{[1 2],[3 4]}}));
session.spikeSorting={struct('format','Neurosuite','relativePath','sorting')};
testCase.TestData.session=session;
testCase.TestData.options=struct('format','neurosuite','getWaveformsFromSource',true);
writeGroup(testCase,1);
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testReadonlyPreparationAndReuseRetainGenerationProvenance(testCase)
[spikes,result,cache,pending]=prepare(testCase);
verifyEqual(testCase,result.status,'completed');
verifyFalse(testCase,isfile(pending.file));
expected=ce.io.importNeurosuiteSpikes(testCase.TestData.session,'getWaveformsFromSource',true);
verifyEqual(testCase,rmfield(spikes,'processinginfo'),expected);
verifyEqual(testCase,ce.pipeline.spikeSortingRevision(spikes),spikes.processinginfo.sortingRevision);
ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
[again,reused]=prepare(testCase);
verifyEqual(testCase,reused.status,'reused'); verifyEqual(testCase,reused.provenance,result.provenance);
verifyEqual(testCase,again,spikes);
end

function testSameIdsWithEditedSourceChangeRevision(testCase)
[before,~,cache,pending]=prepare(testCase); ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
file=source(testCase,'res',1); timestamp=java.io.File(file).lastModified;
values=load(file,'-ascii'); values(2)=values(2)+1; writematrix(values,file,'FileType','text');
java.io.File(file).setLastModified(timestamp); % Contents change even if mtime is restored.
[after,result]=prepare(testCase);
verifyEqual(testCase,result.status,'completed'); verifyEqual(testCase,result.reason,'changed_inputHash');
verifyEqual(testCase,before.UID,after.UID); verifyEqual(testCase,before.cluID,after.cluID);
verifyNotEqual(testCase,before.processinginfo.sortingRevision,after.processinginfo.sortingRevision);
end

function testWaveformChangesInvalidateCacheWithoutChangingMembership(testCase)
[before,~,cache,pending]=prepare(testCase); ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
file=source(testCase,'spk',1); fid=fopen(file,'r+b'); fwrite(fid,123,'int16'); fclose(fid);
[after,result]=prepare(testCase);
verifyEqual(testCase,result.status,'completed'); verifyEqual(testCase,result.reason,'changed_inputHash');
verifyEqual(testCase,before.processinginfo.sortingRevision,after.processinginfo.sortingRevision);
verifyNotEqual(testCase,before.filtWaveform_all,after.filtWaveform_all);
end

function testScalingAndSampleRateHaveDistinctRevisionEffects(testCase)
[before,~,cache,pending]=prepare(testCase); ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
options=testCase.TestData.options; options.LSB=.3815;
[scaled,result]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,options);
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,before.processinginfo.sortingRevision,scaled.processinginfo.sortingRevision);
session=testCase.TestData.session; session.extracellular.sr=10000;
[resampled,~]=ce.pipeline.prepareSpikeImport(session,testCase.TestData.options);
verifyNotEqual(testCase,before.processinginfo.sortingRevision,resampled.processinginfo.sortingRevision);
end

function testChangedOutputAndImplementationRecompute(testCase)
[~,original,cache,pending]=prepare(testCase);
cache.data.total(1)=999; ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
[spikes,result,cache]=prepare(testCase);
verifyEqual(testCase,result.reason,'changed_outputs'); verifyEqual(testCase,spikes.total,[3 3]);
cache.general.processinginfo.stages.spike_import.implementationHash='outdated';
ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
[~,result]=prepare(testCase); verifyEqual(testCase,result.reason,'changed_implementationHash');
verifyEqual(testCase,result.provenance.inputHash,original.provenance.inputHash);
end

function testPendingCommitDetectsNewGroupsAndConcurrentCacheChanges(testCase)
[~,~,cache,pending]=prepare(testCase);
writeGroup(testCase,2);
verifyError(testCase,@() ce.pipeline.verifySpikeImport(pending),'ce:pipeline:SortingSourceChanged');
[~,~,cache,pending]=prepare(testCase);
ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
verifyError(testCase,@() ce.pipeline.verifySpikeImport(pending),'ce:io:PipelineRevisionChanged');
end

function testEditedSuppliedSpikesCannotRetainOldRevision(testCase)
[spikes,~,~,~]=prepare(testCase); spikes.times{1}(2)=spikes.times{1}(2)+.001;
verifyError(testCase,@() ce.pipeline.spikeSortingRevision(spikes),'ce:pipeline:InvalidSortingRevision');
options=coreOptions(testCase);
report=ce.pipeline.preflight(options{:},'spikeImport',[],'spikes',spikes);
verifyTrue(testCase,ismember('InvalidSortingRevision',{report.errors.code}));
end

function testUnsupportedAndConflictingImportsFailWithoutFallback(testCase)
options=coreOptions(testCase); bad=struct('format','unsupported');
report=ce.pipeline.preflight(options{:},'spikeImport',bad);
verifyTrue(testCase,ismember('SpikeImportFailed',{report.errors.code}));
[spikes,~,~,~]=prepare(testCase);
report=ce.pipeline.preflight(options{:},'spikes',spikes);
verifyTrue(testCase,ismember('InvalidSpikeImport',{report.errors.code}));
verifyError(testCase,@() ProcessCellMetrics(options{:},'headless',false),'ce:pipeline:InvalidSpikeImport');
verifyFalse(testCase,isfile(fullfile(testCase.TestData.folder,'synthetic.spikeImport.cache.mat')));
end

function testPipelineDryRunThenSaveThenReuse(testCase)
file=seedMetrics(testCase); hash=ce.pipeline.fileFingerprint(file);
options=coreOptions(testCase); figures=findall(0,'Type','figure'); directory=pwd;
actual=ProcessCellMetrics(options{:},'saveMat',false);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
cacheFile=fullfile(testCase.TestData.folder,'synthetic.spikeImport.cache.mat');
verifyFalse(testCase,isfile(cacheFile));
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
first=ProcessCellMetrics(options{:}); verifyTrue(testCase,isfile(cacheFile));
verifyEqual(testCase,first.general.sortingRevision,actual.general.sortingRevision);
again=ProcessCellMetrics(options{:});
record=again.general.processinginfo.latestRun.stages;
verifyEqual(testCase,record(strcmp({record.name},'spike_import')).status,'reused');
verifyEqual(testCase,again.general.processinginfo.stages.spike_import,first.general.processinginfo.stages.spike_import);
verifyEqual(testCase,findall(0,'Type','figure'),figures); verifyEqual(testCase,pwd,directory);
end

function testPipelineRefusesReusedIdentifiersAfterResorting(testCase)
file=seedMetrics(testCase); options=coreOptions(testCase);
ProcessCellMetrics(options{:});
hash=ce.pipeline.fileFingerprint(file);
cacheFile=fullfile(testCase.TestData.folder,'synthetic.spikeImport.cache.mat');
cacheHash=ce.pipeline.fileFingerprint(cacheFile);
values=load(source(testCase,'res',1),'-ascii'); values(2)=values(2)+1;
writematrix(values,source(testCase,'res',1),'FileType','text');
report=ce.pipeline.preflight(options{:});
verifyTrue(testCase,ismember('SortingRevisionMismatch',{report.errors.code}));
verifyError(testCase,@() ProcessCellMetrics(options{:}),'ce:pipeline:PreflightFailed');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
verifyEqual(testCase,ce.pipeline.fileFingerprint(cacheFile),cacheHash);
end

function testLegacyMetricsAreNotSilentlyAdopted(testCase)
file=seedMetrics(testCase); loaded=load(file,'cell_metrics');
loaded.cell_metrics.general=rmfield(loaded.cell_metrics.general,'sortingRevision');
save(file,'-struct','loaded');
options=coreOptions(testCase); report=ce.pipeline.preflight(options{:});
verifyTrue(testCase,ismember('SortingRevisionMismatch',{report.errors.code}));
verifyFalse(testCase,isfile(fullfile(testCase.TestData.folder,'synthetic.spikeImport.cache.mat')));
end

function testSourceEditBeforePersistencePreservesDestinations(testCase)
file=seedMetrics(testCase); options=coreOptions(testCase);
metrics=ProcessCellMetrics(options{:},'saveMat',false);
[~,result,cache,pending]=prepare(testCase);
parameters=ce.pipeline.parseParameters(options{:},'saveBackup',true);
plan=ce.pipeline.beginPersistence(testCase.TestData.session,parameters);
outputs.spikeImport=struct('result',result,'cache',cache,'pending',pending);
values=load(source(testCase,'res',1),'-ascii'); values(2)=values(2)+1;
writematrix(values,source(testCase,'res',1),'FileType','text');
verifyError(testCase,@() ce.pipeline.saveOutputs(metrics,testCase.TestData.session,plan,outputs),'ce:pipeline:SortingSourceChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),plan.metricsHash);
verifyFalse(testCase,isfile(plan.sessionFile)); verifyFalse(testCase,isfile(pending.file));
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function file=seedMetrics(testCase)
[spikes,~,~,~]=prepare(testCase);
cell_metrics=struct('UID',spikes.UID,'cluID',spikes.cluID,'waveforms',struct(), ...
    'labels',{{'keep first','keep second'}},'putativeCellType',{{'Unknown','Unknown'}}, ...
    'general',struct('cellCount',2,'session',struct(),'animal',struct(), ...
    'sortingRevision',spikes.processinginfo.sortingRevision));
file=fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat'); save(file,'cell_metrics');
end

function options=coreOptions(testCase)
options={'session',testCase.TestData.session,'headless',true,'spikeImport',testCase.TestData.options, ...
    'metrics',{'other_metrics'},'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveBackup',false};
end

function varargout=prepare(testCase)
[varargout{1:nargout}]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,testCase.TestData.options);
end

function file=source(testCase,kind,group)
file=fullfile(testCase.TestData.folder,'sorting',sprintf('synthetic.%s.%d',kind,group));
end

function writeGroup(testCase,group)
writematrix([4;2;2;2;3;3;3],source(testCase,'clu',group),'FileType','text');
writematrix((1000:1000:6000)',source(testCase,'res',group),'FileType','text');
fid=fopen(source(testCase,'spk',group),'wb'); fwrite(fid,int16(reshape(mod(1:96,17),2,8,6)),'int16'); fclose(fid);
end
