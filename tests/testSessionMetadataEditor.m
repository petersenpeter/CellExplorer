function tests=testSessionMetadataEditor
tests=functiontests(localfunctions);
end
function setup(t)
folder=tempname; mkdir(folder); t.TestData.folder=folder;
session=struct('general',struct('name','synthetic','basePath',folder),'animal',struct('name','test'));
session.extracellular=struct('sr',2000,'nChannels',4,'leastSignificantBit',.195,'precision','int16', ...
    'nElectrodeGroups',2,'nSpikeGroups',2,'electrodeGroups',struct('channels',{{1:2,3:4}}),'spikeGroups',struct('channels',{{1:2,3:4}}));
session.custom=struct('unknownField',[1 nan 3]);
t.TestData.session=session;
end
function teardown(t)
rmdir(t.TestData.folder,'s');
end
function testNumericListsAndRanges(t)
verifyEqual(t,ce.data.parseNumericText('[1, 3:5; 9:-2:5 1e-3]'),[1 3 4 5;9 7 5 .001]);
verifyEqual(t,ce.data.parseNumericText(' 1 : 2 : 5 '),[1 3 5]);
verifyEqual(t,ce.data.parseNumericText('[1;2;3]'),[1;2;3]);
verifyError(t,@() ce.data.parseNumericText('[1 2;3]'),'ce:data:InvalidNumericText');
verifyEmpty(t,ce.data.parseNumericText('[]','coordinates',true));
verifyEqual(t,ce.data.parseNumericText('[1 NaN 3]','coordinates',true,true),[1 nan 3]);
for value={'nan','Inf','1/2','sin(1)','1:0:5','1:1e9','[1 2','1;error(''unexpected'')'}
    verifyError(t,@() ce.data.parseNumericText(value{1}),'ce:data:InvalidNumericText');
end
end
function testUnsortedMetadataAndUnknownFields(t)
s=t.TestData.session; report=ce.data.validateSessionMetadata(s); verifyTrue(t,report.valid);
s.timeSeries.dig=struct('sr',2000,'nChannels',4,'leastSignificantBit',0);
verifyTrue(t,ce.data.validateSessionMetadata(s).valid);
s.spikeSorting={struct('format','Phy')}; verifyTrue(t,ce.data.validateSessionMetadata(s).valid);
s.spikeSorting=struct('format','Phy'); verifyFalse(t,ce.data.validateSessionMetadata(s).valid);
end
function testInvalidCoreAndOptionalMetadata(t)
s=t.TestData.session;
for field={'sr','nChannels','leastSignificantBit','srLfp','nSamples'}
    changed=s; changed.extracellular.(field{1})=nan; verifyFalse(t,ce.data.validateSessionMetadata(changed).valid);
end
s.extracellular.chanCoords=struct('x',[1 2],'y',[1 2 3 4]);
r=ce.data.validateSessionMetadata(s); verifyTrue(t,ismember('extracellular.chanCoords.x',{r.errors.path}));
s.extracellular.chanCoords=struct('x',[1 nan 3 4],'y',[1 2 3 4]);
verifyTrue(t,ce.data.validateSessionMetadata(s).valid);
s=t.TestData.session; s.epochs={struct('name','bad','startTime',5,'stopTime',2)}; verifyFalse(t,ce.data.validateSessionMetadata(s).valid);
s=t.TestData.session; s.extracellular.electrodeGroups.channels={1:3,3:4}; verifyFalse(t,ce.data.validateSessionMetadata(s).valid);
s=t.TestData.session; s.timeSeries.adc=struct('sr',-1,'nChannels',[1 2]); verifyFalse(t,ce.data.validateSessionMetadata(s).valid);
end
function testGuardedSaveAndExactBackup(t)
session=t.TestData.session; file=fullfile(t.TestData.folder,'synthetic.session.mat');
receipt=ce.curation.saveSessionMetadata(session,file,''); verifyTrue(t,receipt.saved); verifyEmpty(t,receipt.backup);
extra='keep this in the exact backup'; save(file,'extra','-append'); before=ce.pipeline.fileFingerprint(file);
session.general.notes='edited'; receipt=ce.curation.saveSessionMetadata(session,file,before);
verifyEqual(t,ce.pipeline.fileFingerprint(receipt.backup),before);
verifyEqual(t,ce.pipeline.fileFingerprint(file),receipt.hash);
loaded=load(file); verifyEqual(t,loaded.session,session);
loaded=load(receipt.backup); verifyEqual(t,loaded.extra,extra);
end
function testConflictAndInvalidDraftLeaveDiskIntact(t)
session=t.TestData.session; file=fullfile(t.TestData.folder,'synthetic.session.mat');
receipt=ce.curation.saveSessionMetadata(session,file,'');
session.general.notes='external change'; save(file,'session'); before=ce.pipeline.fileFingerprint(file);
verifyError(t,@() ce.curation.saveSessionMetadata(t.TestData.session,file,receipt.hash),'ce:curation:FileRevisionChanged');
verifyError(t,@() ce.curation.saveSessionMetadata(session,file,''),'ce:curation:FileRevisionChanged');
session.extracellular.sr=nan;
verifyError(t,@() ce.curation.saveSessionMetadata(session,file,before),'ce:curation:InvalidSessionMetadata');
verifyEqual(t,ce.pipeline.fileFingerprint(file),before);
verifyFalse(t,isfolder(fullfile(t.TestData.folder,'revisions_session')));
end
function testBackupFailureLeavesDiskIntact(t)
session=t.TestData.session; file=fullfile(t.TestData.folder,'synthetic.session.mat');
receipt=ce.curation.saveSessionMetadata(session,file,'');
fid=fopen(fullfile(t.TestData.folder,'revisions_session'),'w'); fclose(fid);
verifyError(t,@() ce.curation.saveSessionMetadata(session,file,receipt.hash),'ce:curation:BackupFailed');
verifyEqual(t,ce.pipeline.fileFingerprint(file),receipt.hash);
end

function testRelativePathUsesMatlabWorkingDirectory(t)
original=pwd; cleanup=onCleanup(@() cd(original)); %#ok<NASGU>
cd(t.TestData.folder);
verifyEqual(t,ce.io.canonicalPath('relative.mat'),ce.io.canonicalPath(fullfile(t.TestData.folder,'relative.mat')));
receipt=ce.curation.saveSessionMetadata(t.TestData.session,'relative.mat','');
verifyTrue(t,isfile(fullfile(t.TestData.folder,'relative.mat')));
verifyEqual(t,receipt.file,ce.io.canonicalPath(fullfile(t.TestData.folder,'relative.mat')));
end
