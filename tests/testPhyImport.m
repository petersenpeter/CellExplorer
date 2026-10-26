function tests=testPhyImport
tests=functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); mkdir(fullfile(folder,'sorting'));
testCase.TestData.folder=folder; testCase.TestData.path=path;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'toolboxes','npy-matlb'),folder);
copyfile(fullfile(root,'tests','fixtures','phyLegacyReference.m.txt'),fullfile(folder,'phyLegacyReference.m'));
session.general=struct('name','synthetic','basePath',folder);
session.extracellular=struct('sr',20000,'nChannels',4,'nElectrodeGroups',2, ...
    'electrodeGroups',struct('channels',{{[1 2],[3 4]}}));
session.spikeSorting={struct('format','Phy','relativePath','sorting')};
testCase.TestData.session=session;
writeNPY(int32([7;7;7;2;2;9]),source(testCase,'spike_clusters.npy'));
writeNPY(uint64([100;107;130;300;330;500]),source(testCase,'spike_times.npy'));
writeNPY(single([1;2;3;4;5;6]),source(testCase,'amplitudes.npy'));
writeText(source(testCase,'cluster_group.tsv'),sprintf('cluster_id\tgroup\n2\tgood\n7\tGOOD\n9\tmua\n99\tgood\n'));
end

function teardown(testCase)
path(testCase.TestData.path); rmdir(testCase.TestData.folder,'s');
end

function testLegacyTimestampAmplitudeAndLabelOrder(testCase)
actual=compareLegacy(testCase,{'good'});
verifyEqual(testCase,actual.cluID,[2 7]); verifyEqual(testCase,actual.UID,[1 2]);
verifyEqual(testCase,actual.ts{2},[100;130]); verifyEqual(testCase,actual.ids{2},[1;3]);
verifyEqual(testCase,actual.amplitudes{2},[1;3]); verifyEqual(testCase,actual.times{2},[100;130]/20000);
verifyFalse(testCase,isfield(actual,'shankID'));
actual=compareLegacy(testCase,{'good','mua'}); verifyEqual(testCase,actual.cluID,[2 7 9]);
end

function testLegacyLabelFilePrecedenceAndFallback(testCase)
writeText(source(testCase,'cluster_KSLabel.tsv'),sprintf('cluster_id\tKSLabel\n7\tgood\n2\tmua\n'));
compareLegacy(testCase,{'good'}); % Nonempty group file wins.
writeText(source(testCase,'cluster_group.tsv'),sprintf('cluster_id\tgroup\n'));
actual=compareLegacy(testCase,{'good'}); verifyEqual(testCase,actual.cluID,7);
delete(source(testCase,'cluster_group.tsv'));
writeText(source(testCase,'cluster_groups.csv'),sprintf('cluster_id,group\n2,good\n7,mua\n'));
actual=compareLegacy(testCase,{'good'}); verifyEqual(testCase,actual.cluID,2);
delete(source(testCase,'cluster_groups.csv'));
actual=compareLegacy(testCase,{'good'}); verifyEqual(testCase,actual.cluID,7);
end

function testZeroClusterAndNpyVectorLayoutsMatchLegacy(testCase)
writeNPY(int32([0 0 0 2 2 9]),source(testCase,'spike_clusters.npy'));
writeNPY(uint64([100 107 130 300 330 500]),source(testCase,'spike_times.npy'));
writeNPY(single([1 2 3 4 5 6]),source(testCase,'amplitudes.npy'));
writeText(source(testCase,'cluster_group.tsv'),sprintf('cluster_id\tgroup\n0\tgood\n2\tgood\n9\tmua\n'));
actual=compareLegacy(testCase,{'good'}); verifyEqual(testCase,actual.cluID,[0 2]);
% Python-style one-dimensional shape and big-endian payload, independent of writeNPY.
header=char("{'descr': '>i8', 'fortran_order': False, 'shape': (6,), }");
header=[header,repmat(' ',1,mod(-(10+numel(header)+1),16)),newline];
fid=fopen(source(testCase,'spike_times.npy'),'wb');
fwrite(fid,[147 78 85 77 80 89 1 0],'uint8'); fwrite(fid,numel(header),'uint16',0,'ieee-le');
fwrite(fid,header,'char'); fwrite(fid,[100 107 130 300 330 500],'int64',0,'ieee-be'); fclose(fid);
actual=compareLegacy(testCase,{'good'}); verifyEqual(testCase,actual.ts{1},[100;130]);
end

function testPluginChannelMappingAndClusterInfoPrecedence(testCase)
writePlugins(testCase);
rez.connected=logical([0 1 1 1]); unrelated='must not overwrite local variables';
save(source(testCase,'rez.mat'),'rez','unrelated');
actual=compareLegacy(testCase,{'good'});
verifyEqual(testCase,actual.maxWaveformCh1,[4 2]); verifyEqual(testCase,actual.shankID,[2 1]);
for id={'id','cluster_id'}
    writeText(source(testCase,'cluster_info.tsv'),sprintf('%s\tch\tamp\n7\t2\t20\n2\t0\t40\n',id{1}));
    actual=compareLegacy(testCase,{'good'});
    verifyEqual(testCase,actual.maxWaveformCh1,[1 3]);
    verifyEqual(testCase,actual.shankID,[2 1]); % Legacy plugin groups survive cluster_info channel overrides.
    verifyEqual(testCase,actual.phy_amp,[41 21]); % Preserve the legacy +1 offset.
end
end

function testClusterInfoWithoutPluginsDoesNotInventShanks(testCase)
writeText(source(testCase,'cluster_info.tsv'),sprintf('cluster_id\tch\tamp\n7\t2\t20\n2\t0\t40\n'));
actual=compareLegacy(testCase,{'good'}); verifyFalse(testCase,isfield(actual,'shankID'));
delete(source(testCase,'amplitudes.npy')); compareLegacy(testCase,{'good'});
end

function testMalformedArraysAndLabelsFailWithClosedHandles(testCase)
handles=fopen('all');
writeNPY(uint64([100;107]),source(testCase,'spike_times.npy'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidSortingData');
writeNPY(uint64([100;107;130;300;330;500]),source(testCase,'spike_times.npy'));
writeNPY(single([1;2]),source(testCase,'amplitudes.npy'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidSortingData');
delete(source(testCase,'amplitudes.npy'));
writeText(source(testCase,'cluster_group.tsv'),sprintf('cluster_id\tgroup\n2\tgood\n2\tmua\n'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyLabels');
writeText(source(testCase,'cluster_group.tsv'),sprintf('cluster_id\tgroup\n2\t\n'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyLabels');
verifyEqual(testCase,fopen('all'),handles);
end

function testTruncatedNpyAndUnsafeShapeRejected(testCase)
file=source(testCase,'spike_times.npy');
fid=fopen(file,'rb'); data=fread(fid,Inf,'*uint8'); fclose(fid);
fid=fopen(file,'wb'); fwrite(fid,data(1:end-1),'uint8'); fclose(fid);
verifyError(testCase,@() import(testCase),'ce:io:InvalidSortingData');
header=uint8(char("{'descr': '<i8', 'fortran_order': False, 'shape': (1+1,), }"));
fid=fopen(file,'wb'); fwrite(fid,[147 78 85 77 80 89 1 0],'uint8');
fwrite(fid,numel(header),'uint16',0,'ieee-le'); fwrite(fid,header,'uint8'); fwrite(fid,[100 200],'int64'); fclose(fid);
verifyError(testCase,@() import(testCase),'ce:io:InvalidSortingData');
end

function testPluginAndInfoMappingFailures(testCase)
writeNPY(int32([7;2]),source(testCase,'cluster_ids.npy'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyMetadata');
writePlugins(testCase);
writeNPY(int32([7;7]),source(testCase,'cluster_ids.npy'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyMetadata');
writePlugins(testCase);
writeNPY(int32([0;10]),source(testCase,'peak_channel.npy'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyMetadata');
writePlugins(testCase);
writeText(source(testCase,'cluster_info.tsv'),sprintf('cluster_id\tch\tamp\n7\t2\t20\n'));
verifyError(testCase,@() import(testCase),'ce:io:InvalidPhyMetadata');
end

function testUnsupportedModesAndNoSelectedUnits(testCase)
verifyError(testCase,@() ce.io.importPhySpikes(testCase.TestData.session,'raw_clusters',true),'ce:io:UnsupportedPhyMode');
verifyError(testCase,@() ce.io.importPhySpikes(testCase.TestData.session,'getWaveformsFromSource',true),'ce:io:UnsupportedPhyMode');
verifyError(testCase,@() ce.io.importPhySpikes(testCase.TestData.session,'labelsToRead',{'absent'}),'ce:io:NoSortedUnits');
end

function testManagedReuseAndContentRevision(testCase)
[spikes,result,cache,pending]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy'));
verifyEqual(testCase,result.status,'completed'); verifyFalse(testCase,isfile(pending.file));
verifyEqual(testCase,rmfield(spikes,'processinginfo'),import(testCase));
ce.io.writeMat(pending.file,struct('spikeImportCache',cache));
[again,result]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy'));
verifyEqual(testCase,result.status,'reused'); verifyEqual(testCase,again,spikes);
writeNPY(single([11;12;13;14;15;16]),source(testCase,'amplitudes.npy'));
[amplitudes,result]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy'));
verifyEqual(testCase,result.reason,'changed_inputHash');
verifyEqual(testCase,amplitudes.processinginfo.sortingRevision,spikes.processinginfo.sortingRevision);
writeNPY(uint64([101;108;131;301;331;501]),source(testCase,'spike_times.npy'));
[changed,~]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy'));
verifyEqual(testCase,changed.UID,spikes.UID); verifyEqual(testCase,changed.cluID,spikes.cluID);
verifyNotEqual(testCase,changed.processinginfo.sortingRevision,spikes.processinginfo.sortingRevision);
end

function testSourceRediscoveryAndLabelSelectionAffectManagedImport(testCase)
[spikes,~,~,pending]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy'));
writeText(source(testCase,'cluster_info.tsv'),sprintf('cluster_id\tch\tamp\n7\t2\t20\n2\t0\t40\n9\t1\t10\n'));
verifyError(testCase,@() ce.pipeline.verifySpikeImport(pending),'ce:pipeline:SortingSourceChanged');
[changed,~]=ce.pipeline.prepareSpikeImport(testCase.TestData.session,struct('format','phy','labelsToRead',{{'good','mua'}}));
verifyEqual(testCase,changed.cluID,[2 7 9]);
verifyNotEqual(testCase,changed.processinginfo.sortingRevision,spikes.processinginfo.sortingRevision);
end

function testPublicLoaderSaveFilterAndFailurePreservation(testCase)
options={'session',testCase.TestData.session,'getWaveformsFromDat',false,'saveMat',true,'forceReload',true};
actual=loadSpikes(options{:},'cluID',7); verifyEqual(testCase,actual.cluID,7);
file=fullfile(testCase.TestData.folder,'synthetic.spikes.cellinfo.mat');
stored=load(file,'spikes'); verifyEqual(testCase,stored.spikes.cluID,[2 7]);
before=ce.pipeline.fileFingerprint(file);
verifyError(testCase,@() loadSpikes(options{:},'getWaveformsFromSource',true),'ce:io:UnsupportedPhyMode');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
end

function spikes=compareLegacy(testCase,labels)
state=rng; directory=pwd; figures=findall(0,'Type','figure');
spikes=ce.io.importPhySpikes(testCase.TestData.session,'labelsToRead',labels);
expected=phyLegacyReference(testCase.TestData.session,labels);
verifyEqual(testCase,spikes,expected); verifyEqual(testCase,rng,state); verifyEqual(testCase,pwd,directory);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
end

function spikes=import(testCase)
spikes=ce.io.importPhySpikes(testCase.TestData.session);
end

function file=source(testCase,name)
file=fullfile(testCase.TestData.folder,'sorting',name);
end

function writePlugins(testCase)
writeNPY(int32([7;2]),source(testCase,'cluster_ids.npy'));
writeNPY(int32([99;99]),source(testCase,'shanks.npy')); % Deliberately ignored by legacy mapping.
writeNPY(int32([0;2]),source(testCase,'peak_channel.npy'));
end

function writeText(file,value)
fid=fopen(file,'w'); cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s',value);
end
