function tests = testNeurosuiteImport
tests = functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); mkdir(fullfile(folder,'sorting'));
testCase.TestData.folder=folder; testCase.TestData.path=path;
root=fileparts(fileparts(mfilename('fullpath')));
copyfile(fullfile(root,'tests','fixtures','neurosuiteLegacyReference.m.txt'),fullfile(folder,'neurosuiteLegacyReference.m'));
addpath(folder);
session.general=struct('name','recording.with.dots','basePath',folder);
session.extracellular=struct('sr',20000,'nChannels',4,'leastSignificantBit',.3815, ...
    'electrodeGroups',struct('channels',{{[4 2],[1 3]}}));
session.spikeSorting={struct('format','Neurosuite','relativePath','sorting')};
testCase.TestData.session=session;
writeGroup(testCase,1,[0;1;2;2;2;5;5],[0;5;100;107;120;220;240]);
writeGroup(testCase,2,[2;2;2],[10;30;50]);
end

function teardown(testCase)
path(testCase.TestData.path); rmdir(testCase.TestData.folder,'s');
end

function testTimesIdentityAndUnitsMatchFrozenLegacy(testCase)
actual=compareLegacy(testCase,NaN,false,false);
verifyEqual(testCase,actual.UID,[1 2 3]);
verifyEqual(testCase,actual.cluID,[2 5 2]);
verifyEqual(testCase,actual.shankID,[1 1 2]);
verifyEqual(testCase,actual.ts{1},[100;120]);
verifyEqual(testCase,actual.times{1},[100;120]/20000);
verifyEqual(testCase,actual.total,[2 2 3]);
end

function testSourceWaveformsAndChannelBasesMatchExactly(testCase)
actual=compareLegacy(testCase,NaN,false,true);
verifyEqual(testCase,actual.maxWaveformCh1,[4 4 1]);
verifyEqual(testCase,actual.maxWaveformCh,actual.maxWaveformCh1-1);
% Waveform averaging intentionally includes the 107-sample spike collapsed by
% timestamp uniquetol. This is the unchanged legacy scientific convention.
expected=mean(cat(3,wave(1,3),wave(1,4),wave(1,5)),3)*.3815;
verifyEqual(testCase,actual.filtWaveform_all{1},expected,'AbsTol',1e-12);
end

function testExplicitGroupOrderAndScaleArePreserved(testCase)
actual=compareLegacy(testCase,[2 1],false,true);
verifyEqual(testCase,actual.shankID,[2 1 1]);
session=testCase.TestData.session;
scaled=ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true,'LSB',.195);
defaults=ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true);
verifyEqual(testCase,scaled.peakVoltage,defaults.peakVoltage*(.195/.3815),'AbsTol',1e-12);
end

function testSingleSpikeAndNoiseOnlyGroupMatchLegacy(testCase)
writeGroup(testCase,1,2,100);
writeGroup(testCase,2,[0;1],[0;10]);
actual=compareLegacy(testCase,NaN,false,true);
verifyEqual(testCase,actual.UID,1); verifyEqual(testCase,actual.total,1);
end

function testDiscoverySortsNumericGroupsAndIgnoresBackupSuffixes(testCase)
writeGroup(testCase,10,3,1000);
writeText([sourceFile(testCase,'res',1),'.backup'],'ignored');
[actual,groups]=ce.io.importNeurosuiteSpikes(testCase.TestData.session);
verifyEqual(testCase,groups,[1 2 10]); verifyEqual(testCase,actual.shankID,[1 1 2 10]);
end

function testOriginalClustersAndDiscoveryUseOriginalFolder(testCase)
folder=fullfile(testCase.TestData.folder,'sorting'); mkdir(fullfile(folder,'OriginalClus'));
for group=1:2
    for extension={'clu','res'}
        name=sprintf('%s.%s.%d',testCase.TestData.session.general.name,extension{1},group);
        movefile(fullfile(folder,name),fullfile(folder,'OriginalClus',name));
    end
end
actual=ce.io.importNeurosuiteSpikes(testCase.TestData.session,'raw_clusters',true);
expected=compareLegacy(testCase,[1 2],true,false);
verifyEqual(testCase,actual,expected);
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(testCase.TestData.session, ...
    'raw_clusters',true,'getWaveformsFromSource',true),'ce:io:UnsupportedSourceWaveforms');
end

function testMissingAndMalformedInputsDoNotReturnPartialUnits(testCase)
session=testCase.TestData.session;
file=sourceFile(testCase,'clu',2); original=fileread(file); delete(file);
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session),'ce:io:MissingSortingInput');
writeText(file,original);
writeColumn(file,[3;2]);
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session),'ce:io:SortingLengthMismatch');
writeText(file,original);
for data={[10;NaN;50],[10;-1;50],[10;1.5;50],[10;Inf;50],[10 30 50]}
    writeColumn(sourceFile(testCase,'res',2),data{1});
    verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session),'ce:io:InvalidSortingData');
end
end

function testNoSortedCellsAndInvalidGroupSelectionsFailClearly(testCase)
writeGroup(testCase,1,[0;1],[0;20]);
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(testCase.TestData.session, ...
    'electrodeGroups',1),'ce:io:NoSortedUnits');
for groups={[1 1],0,1.5,[1 NaN]}
    verifyError(testCase,@() ce.io.importNeurosuiteSpikes(testCase.TestData.session, ...
        'electrodeGroups',groups{1}),'ce:io:InvalidElectrodeGroups');
end
end

function testWaveformFramingAndMetadataAreChecked(testCase)
session=testCase.TestData.session;
for channels={0,[1 5],[1 1],1.5}
    changed=session; changed.extracellular.electrodeGroups.channels{1}=channels{1};
    verifyError(testCase,@() ce.io.importNeurosuiteSpikes(changed,'getWaveformsFromSource',true),'ce:io:InvalidSortingMetadata');
end
file=sourceFile(testCase,'spk',2); handle=fopen(file,'ab'); fwrite(handle,1,'uint8'); fclose(handle);
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true),'ce:io:InvalidWaveformFile');
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true,'LSB',0),'ce:io:InvalidSortingMetadata');
session.extracellular.sr=0;
verifyError(testCase,@() ce.io.importNeurosuiteSpikes(session),'ce:io:InvalidSortingMetadata');
end

function testReadOnlyAndFileHandlesArePreserved(testCase)
session=testCase.TestData.session; folder=testCase.TestData.folder;
before=dir(fullfile(folder,'sorting')); figures=findall(0,'Type','figure'); randomState=rng; directory=pwd; handles=openedFiles;
for repeat=1:3
    ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true);
end
verifyEqual(testCase,dir(fullfile(folder,'sorting')),before);
verifyEqual(testCase,openedFiles,handles); verifyEqual(testCase,pwd,directory);
verifyEqual(testCase,findall(0,'Type','figure'),figures); verifyEqual(testCase,rng,randomState);
verifyFalse(testCase,isfile(fullfile(folder,[session.general.name,'.spikes.cellinfo.mat'])));
end

function testLegacyEntryPointRoutesAndSavesUnfilteredData(testCase)
session=testCase.TestData.session;
options={'session',session,'getWaveformsFromDat',false,'getWaveformsFromSource',true,'LSB',.3815,'forceReload',true,'showWaveforms',false};
expected=ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true);
actual=loadSpikes(options{:},'saveMat',false);
verifyEqual(testCase,rmfield(actual,'processinginfo'),expected);
alias=loadSpikes(options{:},'format','Klustakwik','saveMat',false);
verifyEqual(testCase,rmfield(alias,'processinginfo'),expected);
selected=loadSpikes(options{:},'saveMat',true,'UID',2);
verifyEqual(testCase,selected.UID,2); verifyEqual(testCase,selected.numcells,1);
file=fullfile(session.general.basePath,[session.general.name,'.spikes.cellinfo.mat']);
stored=load(file,'spikes'); verifyEqual(testCase,stored.spikes.UID,[1 2 3]);
verifyEqual(testCase,rmfield(stored.spikes,'processinginfo'),expected);
end

function testCacheReadsOnlySpikesAndWriteErrorsPropagate(testCase)
session=testCase.TestData.session;
options={'session',session,'getWaveformsFromDat',false,'getWaveformsFromSource',true,'forceReload',true,'showWaveforms',false};
spikes=loadSpikes(options{:},'saveMat',false);
file=fullfile(session.general.basePath,[session.general.name,'.spikes.cellinfo.mat']);
parameters='must not overwrite parsed options'; save(file,'spikes','parameters'); %#ok<NASGU>
actual=loadSpikes('session',session,'getWaveformsFromDat',false);
verifyEqual(testCase,actual,spikes);
before=ce.pipeline.fileFingerprint(file);
delete(sourceFile(testCase,'clu',2));
verifyError(testCase,@() loadSpikes(options{:}),'ce:io:MissingSortingInput');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
writeGroup(testCase,2,[2;2;2],[10;30;50]);
delete(file); mkdir(file);
verifyError(testCase,@() loadSpikes(options{:}),'ce:io:InvalidDestination');
end

function testImportedSpikesFeedHeadlessPipelineWithoutAnImporterCallback(testCase)
session=testCase.TestData.session;
session.animal.name='synthetic animal';
session.extracellular.nElectrodeGroups=2; session.extracellular.nSpikeGroups=2;
session.extracellular.spikeGroups=session.extracellular.electrodeGroups;
session.extracellular.precision='int16';
spikes=ce.io.importNeurosuiteSpikes(session,'getWaveformsFromSource',true);
cell_metrics=struct('UID',spikes.UID,'cluID',spikes.cluID,'waveforms',struct(), ...
    'putativeCellType',{{'Unknown','Unknown','Unknown'}}, ...
    'general',struct('cellCount',3,'session',struct(),'animal',struct()));
file=fullfile(session.general.basePath,[session.general.name,'.cell_metrics.cellinfo.mat']);
save(file,'cell_metrics'); before=ce.pipeline.fileFingerprint(file);
options={'session',session,'spikes',spikes,'headless',true,'metrics',{'other_metrics'}, ...
    'getWaveformsFromDat',false,'excludeManipulationIntervals',false,'saveMat',false};
report=ce.pipeline.preflight(options{:}); assertTrue(testCase,report.valid,evalc('disp(report.errors)'));
figures=findall(0,'Type','figure'); directory=pwd;
actual=ProcessCellMetrics(options{:});
verifyEqual(testCase,actual.UID,spikes.UID); verifyEqual(testCase,actual.cluID,spikes.cluID);
verifyEqual(testCase,actual.spikeCount,spikes.total);
verifyEqual(testCase,actual.maxWaveformCh1,spikes.maxWaveformCh1);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
verifyFalse(testCase,isfile(fullfile(session.general.basePath,[session.general.name,'.spikes.cellinfo.mat'])));
verifyEqual(testCase,findall(0,'Type','figure'),figures); verifyEqual(testCase,pwd,directory);
end

function actual=compareLegacy(testCase,groups,raw,sourceWaveforms)
session=testCase.TestData.session;
parameters=struct('getWaveformsFromDat',false,'getWaveformsFromSource',sourceWaveforms);
[expected,expectedGroups]=neurosuiteLegacyReference(session,fullfile(session.general.basePath,'sorting'), ...
    session.general.name,groups,raw,parameters,.3815);
[actual,actualGroups]=ce.io.importNeurosuiteSpikes(session,'electrodeGroups',groups, ...
    'raw_clusters',raw,'getWaveformsFromSource',sourceWaveforms,'LSB',.3815);
verifyEqual(testCase,actual,expected); verifyEqual(testCase,actualGroups,expectedGroups);
end

function writeGroup(testCase,group,clusters,times)
writeColumn(sourceFile(testCase,'clu',group),[max(clusters)+1;clusters]);
writeColumn(sourceFile(testCase,'res',group),times);
data=zeros(2,4,numel(times),'int16');
for index=1:numel(times), data(:,:,index)=wave(group,index); end
handle=fopen(sourceFile(testCase,'spk',group),'wb'); fwrite(handle,data,'int16'); fclose(handle);
end

function values=wave(group,index)
values=int16([-5 10 -2 -3;1 -1 0 2]*index+10*group);
end

function file=sourceFile(testCase,extension,group)
file=fullfile(testCase.TestData.folder,'sorting',sprintf('%s.%s.%d',testCase.TestData.session.general.name,extension,group));
end

function writeColumn(file,values)
% Preserve rows as malformed input for the column-shape checks.
writematrix(values,file,'FileType','text','Delimiter','tab');
end

function writeText(file,value)
handle=fopen(file,'w'); fprintf(handle,'%s',value); fclose(handle);
end
