function tests=testSpecialCurationSaves
tests=functiontests(localfunctions);
end
function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder; testCase.TestData.path=path;
root=fileparts(fileparts(mfilename('fullpath')));
copyfile(fullfile(root,'tests','fixtures','groundTruthLegacyReference.m.txt'),fullfile(folder,'groundTruthLegacyReference.m')); addpath(folder);
metrics=struct('UID',[7 9 12],'cluID',[11 12 13],'shankID',[1 1 2], ...
    'firingRate',[1 2 3],'labels',{{'one','two','three'}},'groups',struct(),'tags',struct('tag',[1 2]), ...
    'groundTruthClassification',struct('A',[1 2],'B',[2 3]),'waveforms',struct('filt',{{1:3,2:4,3:5}}));
metrics.general=struct('cellCount',3,'basename','synthetic','basepath',folder,'saveAs','cell_metrics','sortingRevision',repmat('a',1,64));
metrics.putativeConnections=struct('excitatory',[1 2;1 3],'inhibitory',[3 1], ...
    'excitatoryTransProb',[.2 .3],'inhibitoryTransProb',.4);
metrics=ce.curation.projectMonoSynReview(metrics,struct('excitatory',[1 2;1 3],'inhibitory',[3 1]));
mono=struct('ccgR',zeros(301,3,3),'n',[100 120 90],'Pred',[],'Bounds',[], ...
    'completeIndex',[1 11 1;1 12 2;2 13 3],'binSize',.0004,'duration',.120,'conv_w',25, ...
    'Pcausal',nan(3),'sig_con',[1 2;1 3],'sig_con_excitatory',[1 2;1 3], ...
    'sig_con_inhibitory',[3 1],'sig_con_excitatory_all',[1 2;1 3;2 3],'sig_con_inhibitory_all',[3 1]);
mono.processinginfo.cellIdentity=struct('UID',metrics.UID,'cluID',metrics.cluID,'shankID',metrics.shankID,'sortingRevision',metrics.general.sortingRevision);
metricFile=fullfile(folder,'synthetic.cell_metrics.cellinfo.mat'); monoFile=fullfile(folder,'synthetic.mono_res.cellinfo.mat');
ce.io.writeMat(metricFile,struct('cell_metrics',metrics,'notes','preserve metrics extras'));
ce.io.writeMat(monoFile,struct('mono_res',mono,'notes','preserve mono extras'));
testCase.TestData.metrics=metrics; testCase.TestData.mono=mono;
testCase.TestData.metricFile=metricFile; testCase.TestData.monoFile=monoFile;
end
function teardown(testCase)
path(testCase.TestData.path);
if isappdata(0,'ceSpecialMove'), rmappdata(0,'ceSpecialMove'); end
clear movefile
rmdir(testCase.TestData.folder,'s');
end

function testGroundTruthMatchesLegacyAndDeduplicatesTags(testCase)
metrics=testCase.TestData.metrics;
expected=groundTruthLegacyReference(metrics,[3 1]);
actual=ce.curation.groundTruthSubset(metrics,[3 1 3]); verifyEqual(testCase,actual,expected);
verifyEqual(testCase,actual.UID,[12 7]); verifyEqual(testCase,actual.groundTruthClassification.B,1);
metrics.score=int16([4 5 6]); metrics.general.classificationTrackChanges=[1 3];
actual=ce.curation.groundTruthSubset(metrics,[3 1]); verifyEqual(testCase,actual.score,int16([6 4]));
verifyFalse(testCase,isfield(actual.general,'classificationTrackChanges'));
end

function testGroundTruthSelectionCanChangeWithinSameSession(testCase)
metrics=testCase.TestData.metrics; file=fullfile(testCase.TestData.folder,'catalog.cell_metrics.cellinfo.mat');
ce.curation.saveGroundTruth(metrics,[1 2],file); hash=ce.pipeline.fileFingerprint(file);
result=ce.curation.saveGroundTruth(metrics,[2 3],file);
verifyEqual(testCase,ce.pipeline.fileFingerprint(result.backup),hash);
stored=load(file,'cell_metrics'); verifyEqual(testCase,stored.cell_metrics.UID,[9 12]);
end

function testGroundTruthRevisionAndSourceConflictsPreserveFile(testCase)
metrics=testCase.TestData.metrics; file=fullfile(testCase.TestData.folder,'catalog.cell_metrics.cellinfo.mat');
ce.curation.saveGroundTruth(metrics,[1 2],file); hash=ce.pipeline.fileFingerprint(file);
changed=metrics; changed.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.saveGroundTruth(changed,[2 3],file),'ce:curation:SortingRevisionMismatch');
changed=metrics; changed.general.basepath='another source';
verifyError(testCase,@() ce.curation.saveGroundTruth(changed,[2 3],file),'ce:curation:IdentityMismatch');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testGroundTruthBatchUsesSessionLocalRevision(testCase)
metrics=testCase.TestData.metrics; other=metrics; other.general.sortingRevision=repmat('b',1,64);
batch=ce.data.assembleMetricBatch({metrics,other},{'one','two'},{'one','two'},'cell_metrics');
subset=ce.curation.groundTruthSubset(batch,[5 6]);
verifyEqual(testCase,subset.UID,[9 12]); verifyEqual(testCase,subset.general.sortingRevision,other.general.sortingRevision);
verifyFalse(testCase,isfield(subset,'batchIDs'));
verifyError(testCase,@() ce.curation.groundTruthSubset(batch,[1 5]),'ce:data:InvalidSortingRevision');
end

function testMonoReviewReadOnlyAndBindsIdentity(testCase)
context=begin(testCase); verifyEqual(testCase,context.viewerIndices,1:3);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
metrics=testCase.TestData.metrics; metrics.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.beginMonoSynReview(testCase.TestData.metricFile,testCase.TestData.monoFile,metrics,1:3),'ce:curation:SortingRevisionMismatch');
mono=testCase.TestData.mono; mono.processinginfo.cellIdentity.UID=[1 2 3];
ce.io.writeMat(testCase.TestData.monoFile,struct('mono_res',mono));
verifyError(testCase,@() begin(testCase),'ce:curation:MonoSynIdentityMismatch');
mono=rmfield(testCase.TestData.mono,'processinginfo');
ce.io.writeMat(testCase.TestData.monoFile,struct('mono_res',mono));
verifyError(testCase,@() begin(testCase),'ce:curation:MonoSynIdentityMismatch');
end

function testPendingReviewSurvivesOwnAnnotationSaveAndRecovery(testCase)
context=begin(testCase); metrics=testCase.TestData.metrics;
pending=struct('context',context,'review',context.mono);
pending.review.sig_con=[1 3]; pending.review.sig_con_excitatory=[1 3];
entry=ce.curation.recovery.open(metrics);
metrics.labels{1}='saved label';
[old,errors]=ce.curation.recovery.checkpoint(metrics,1,pending,entry); verifyEmpty(testCase,errors);
entry=ce.curation.recovery.open(testCase.TestData.metrics);
entry.recovered=struct('file',old.file,'hash',old.writtenHash);
receipt=ce.curation.saveSessionAnnotations(testCase.TestData.metricFile,metrics,1:3);
updated=ce.curation.refreshMonoSynReview(pending,receipt,metrics);
verifyEqual(testCase,updated.review,pending.review);
verifyEqual(testCase,updated.context.metricsHash,receipt.hash);
verifyEqual(testCase,receipt.previousHash,context.metricsHash);
[entry,errors]=ce.curation.recovery.refresh(metrics,1,true,[],updated,entry);
verifyEmpty(testCase,errors); verifyTrue(testCase,isfile(entry.file));
verifyFalse(testCase,isfile(old.file));
next=ce.curation.recovery.open(metrics); candidates=ce.curation.recovery.discover(next);
[restored,dirty,recovered]=ce.curation.recovery.prepare(metrics,next,candidates(1));
verifyEqual(testCase,restored.labels,metrics.labels); verifyEmpty(testCase,dirty);
verifyEqual(testCase,recovered.review.sig_con,[1 3]);
ce.curation.saveMonoSynReview(recovered.context,recovered.review);
stored=ce.io.readCellMetrics(testCase.TestData.metricFile);
verifyEqual(testCase,stored.labels,metrics.labels);
end

function testPendingReviewCannotAcceptExternalChangesAroundOwnSave(testCase)
context=begin(testCase); pending=struct('context',context,'review',context.mono);
metrics=testCase.TestData.metrics; metrics.labels{1}='own save';
receipt=ce.curation.saveMetricSnapshot(metrics,testCase.TestData.metricFile);
extra=17; save(testCase.TestData.metricFile,'extra','-append');
verifyError(testCase,@() ce.curation.refreshMonoSynReview(pending,receipt,metrics),'ce:curation:FileRevisionChanged');
% A later successful save must not bless an already-stale review either.
receipt=ce.curation.saveMetricSnapshot(metrics,testCase.TestData.metricFile);
verifyError(testCase,@() ce.curation.refreshMonoSynReview(pending,receipt,metrics),'ce:curation:FileRevisionChanged');
end

function testLegacyMonoRequiresCompleteMatchingIndices(testCase)
metrics=testCase.TestData.metrics; metrics.general=rmfield(metrics.general,'sortingRevision');
mono=testCase.TestData.mono; mono=rmfield(mono,'processinginfo');
ce.io.writeMat(testCase.TestData.metricFile,struct('cell_metrics',metrics)); ce.io.writeMat(testCase.TestData.monoFile,struct('mono_res',mono));
testCase.TestData.metrics=metrics; begin(testCase);
mono.completeIndex(2,2)=99; ce.io.writeMat(testCase.TestData.monoFile,struct('mono_res',mono));
verifyError(testCase,@() begin(testCase),'ce:curation:MonoSynIdentityMismatch');
end

function testMonoRevisionChangesDuringReviewPreserveBothFiles(testCase)
for field={'metricFile','monoFile'}
    context=begin(testCase);
    file=testCase.TestData.(field{1}); extra=17; save(file,'extra','-append');
    hashes=hashBoth(testCase);
    verifyError(testCase,@() ce.curation.saveMonoSynReview(context,context.mono),'ce:curation:FileRevisionChanged');
    verifyEqual(testCase,hashBoth(testCase),hashes);
end
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testMonoInvalidReviewDoesNotWrite(testCase)
context=begin(testCase); reviewed=context.mono; reviewed.ccgR(1)=1; hashes=hashBoth(testCase);
verifyError(testCase,@() ce.curation.saveMonoSynReview(context,reviewed),'ce:curation:DetectionChanged');
reviewed=context.mono; reviewed.sig_con=[2 1]; reviewed.sig_con_excitatory=[2 1];
verifyError(testCase,@() ce.curation.saveMonoSynReview(context,reviewed),'ce:curation:InvalidMonoSynSelection');
verifyEqual(testCase,hashBoth(testCase),hashes);
end

function testMonoSaveArchivesBothFilesAndProjectsSelectedPairs(testCase)
context=begin(testCase); reviewed=context.mono; reviewed.sig_con=[1 3]; reviewed.sig_con_excitatory=[1 3]; reviewed.sig_con_inhibitory=zeros(0,2);
[metrics,mono,result]=ce.curation.saveMonoSynReview(context,reviewed);
verifyEqual(testCase,ce.pipeline.fileFingerprint(result.metricsBackup),context.metricsHash);
verifyEqual(testCase,ce.pipeline.fileFingerprint(result.monoBackup),context.monoHash);
verifyEqual(testCase,metrics.synapticEffect,{'Excitatory','Unknown','Unknown'});
verifyEqual(testCase,metrics.synapticConnectionsOut,[1 0 0]); verifyEqual(testCase,metrics.synapticConnectionsIn,[0 0 1]);
verifyEqual(testCase,metrics.putativeConnections.excitatoryTransProb,.3);
verifyEmpty(testCase,metrics.putativeConnections.inhibitoryTransProb);
stored=load(testCase.TestData.metricFile,'cell_metrics'); verifyEqual(testCase,stored.cell_metrics,metrics);
stored=load(testCase.TestData.monoFile,'mono_res'); verifyEqual(testCase,stored.mono_res,mono);
end

function testMonoBackupFailurePreservesBothFiles(testCase)
context=begin(testCase); hashes=hashBoth(testCase);
fid=fopen(fullfile(testCase.TestData.folder,'revisions_mono_res'),'w'); fclose(fid);
verifyError(testCase,@() ce.curation.saveMonoSynReview(context,context.mono),'ce:curation:BackupFailed');
verifyEqual(testCase,hashBoth(testCase),hashes);
end

function testSecondReplacementFailureRestoresMonoBytes(testCase)
context=begin(testCase); hashes=hashBoth(testCase);
installMoveFailure(testCase);
verifyError(testCase,@() ce.curation.saveMonoSynReview(context,context.mono),'ce:io:ReplaceFailed');
verifyEqual(testCase,hashBoth(testCase),hashes);
end

function testRollbackDoesNotOverwriteConcurrentMonoEdit(testCase)
context=begin(testCase); installMoveFailure(testCase);
item=getappdata(0,'ceSpecialMove'); item.concurrentFile=testCase.TestData.monoFile; setappdata(0,'ceSpecialMove',item);
verifyError(testCase,@() ce.curation.saveMonoSynReview(context,context.mono),'ce:curation:PartialMonoSynSave');
stored=load(testCase.TestData.monoFile,'external'); verifyEqual(testCase,stored.external,17);
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.metricFile),context.metricsHash);
backups=dir(fullfile(testCase.TestData.folder,'revisions_mono_res','*.mat'));
verifyNumElements(testCase,backups,1);
verifyEqual(testCase,ce.pipeline.fileFingerprint(fullfile(backups(1).folder,backups(1).name)),context.monoHash);
end

function testProjectionClearsInhibitionAndMapsBatchIndices(testCase)
metrics=testCase.TestData.metrics;
selection=struct('excitatory',[2 3],'inhibitory',zeros(0,2));
projected=ce.curation.projectMonoSynReview(metrics,selection);
verifyFalse(testCase,isfield(projected.putativeConnections,'excitatoryTransProb'));
verifyEqual(testCase,projected.synapticEffect,{'Unknown','Excitatory','Unknown'});
projected.general.processinginfo.monosynapticReview=struct('status','test');
batch=ce.data.assembleMetricBatch({metrics,metrics},{'one','two'},{'one','two'},'cell_metrics');
batch.labels{4}='unsaved'; updated=ce.curation.applyMonoSynReview(batch,projected,4:6);
verifyEqual(testCase,updated.labels,batch.labels);
verifyEqual(testCase,updated.putativeConnections.excitatory,[1 2;1 3;5 6]);
verifyEqual(testCase,updated.putativeConnections.inhibitory,[3 1]);
verifyEqual(testCase,updated.synapticEffect(4:6),projected.synapticEffect);
end

function context=begin(testCase)
context=ce.curation.beginMonoSynReview(testCase.TestData.metricFile,testCase.TestData.monoFile,testCase.TestData.metrics,1:3);
end
function hashes=hashBoth(testCase)
hashes={ce.pipeline.fileFingerprint(testCase.TestData.metricFile),ce.pipeline.fileFingerprint(testCase.TestData.monoFile)};
end
function installMoveFailure(testCase)
realMove=@movefile; setappdata(0,'ceSpecialMove',struct('original',realMove,'destination',testCase.TestData.metricFile));
file=fullfile(testCase.TestData.folder,'movefile.m'); fid=fopen(file,'w'); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,['function [ok,msg]=movefile(source,destination,varargin)\n', ...
 'item=getappdata(0,''ceSpecialMove'');\n', ...
 'if strcmp(destination,item.destination)\n', ...
 'if isfield(item,''concurrentFile''), external=17; save(item.concurrentFile,''external'',''-append''); end\n', ...
 'ok=false; msg=''injected second replacement failure'';\n', ...
 'else, [ok,msg]=item.original(source,destination,varargin{:}); end\nend\n']);
rehash;
end
