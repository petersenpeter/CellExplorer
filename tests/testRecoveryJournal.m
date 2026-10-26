function tests=testRecoveryJournal
tests=functiontests(localfunctions);
end
function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder;
metrics=struct('UID',[7 9],'cluID',[11 22],'labels',{{'old one','old two'}},'tags',struct('tag',1), ...
 'groups',struct(),'groundTruthClassification',struct(),'firingRate',[1 2],'shankID',[1 1]);
metrics.general=struct('cellCount',2,'basename','synthetic','basepath',folder,'saveAs','cell_metrics','sortingRevision',repmat('a',1,64));
file=fullfile(folder,'synthetic.cell_metrics.cellinfo.mat'); ce.io.saveCellMetrics(metrics,file);
testCase.TestData.metrics=metrics; testCase.TestData.file=file;
end
function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testOpenIsReadOnlyAndCheckpointDoesNotTouchMetrics(testCase)
metrics=testCase.TestData.metrics; hash=ce.pipeline.fileFingerprint(testCase.TestData.file);
state=ce.curation.recovery.open(metrics); verifyFalse(testCase,isfolder(fileparts(state.file)));
[unchanged,errors]=ce.curation.recovery.checkpoint(metrics,[],[],state); verifyEmpty(testCase,errors); verifyEqual(testCase,unchanged,state);
metrics.labels{1}='draft'; [state,errors]=ce.curation.recovery.checkpoint(metrics,1,[],state);
verifyEmpty(testCase,errors); verifyTrue(testCase,isfile(state.file));
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),hash);
loaded=load(state.file,'recovery'); verifyFalse(testCase,isfield(loaded.recovery.annotations,'firingRate'));
before=state.writtenHash; [state,errors]=ce.curation.recovery.checkpoint(metrics,1,[],state);
verifyEmpty(testCase,errors); verifyEqual(testCase,state.writtenHash,before);
end

function testReopenRecoversAnnotationsByUIDWithoutWrites(testCase)
metrics=testCase.TestData.metrics; original=metrics;
first=ce.curation.recovery.open(metrics); metrics.labels{2}='draft'; metrics.tags.tag=[1 2];
[first,errors]=ce.curation.recovery.checkpoint(metrics,2,[],first); verifyEmpty(testCase,errors);
second=ce.curation.recovery.open(original); candidates=ce.curation.recovery.discover(second);
verifyNumElements(testCase,candidates,1);
hash=ce.pipeline.fileFingerprint(testCase.TestData.file);
[restored,dirty,pending]=ce.curation.recovery.prepare(original,second,candidates(1));
verifyEqual(testCase,restored,metrics); verifyEqual(testCase,dirty,2); verifyEmpty(testCase,pending);
verifyTrue(testCase,isfile(first.file)); verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),hash);
reordered=original;
for key={'UID','cluID','labels','firingRate','shankID'}
    reordered.(key{1})=reordered.(key{1})([2 1]);
end
reordered.tags.tag=2;
[restored,dirty]=ce.curation.recovery.prepare(reordered,second,candidates(1));
verifyEqual(testCase,restored.labels,metrics.labels([2 1])); verifyEqual(testCase,dirty,1);
verifyEqual(testCase,sort(restored.tags.tag),[1 2]);
end

function testRecoveryRejectsChangedSourceEvenWithSameIDs(testCase)
[entry,candidate]=draft(testCase);
metrics=testCase.TestData.metrics; metrics.firingRate=[5 6]; ce.io.saveCellMetrics(metrics,testCase.TestData.file);
verifyError(testCase,@() ce.curation.recovery.prepare(metrics,entry,candidate),'ce:curation:FileRevisionChanged');
verifyTrue(testCase,isfile(candidate.file));
end

function testRecoveryRejectsChangedInMemoryBaselineAndSorting(testCase)
[entry,candidate]=draft(testCase); metrics=testCase.TestData.metrics;
metrics.labels{1}='already edited';
verifyError(testCase,@() ce.curation.recovery.prepare(metrics,entry,candidate),'ce:recovery:BaselineChanged');
metrics=testCase.TestData.metrics; metrics.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.recovery.prepare(metrics,entry,candidate),'ce:curation:SortingRevisionMismatch');
verifyTrue(testCase,isfile(candidate.file));
end

function testSeparateOwnersNeverOverwriteOrRetireEachOther(testCase)
metrics=testCase.TestData.metrics; one=ce.curation.recovery.open(metrics); two=ce.curation.recovery.open(metrics);
metrics.labels{1}='one'; [one,errors]=ce.curation.recovery.checkpoint(metrics,1,[],one); verifyEmpty(testCase,errors);
metrics.labels{1}='two'; [two,errors]=ce.curation.recovery.checkpoint(metrics,1,[],two); verifyEmpty(testCase,errors);
verifyNotEqual(testCase,one.file,two.file);
ce.curation.recovery.retire(one.file,one.writtenHash); verifyTrue(testCase,isfile(two.file));
verifyEqual(testCase,ce.pipeline.fileFingerprint(two.file),two.writtenHash);
end

function testTamperedJournalIsPreservedOnCheckpointAndRetirement(testCase)
metrics=testCase.TestData.metrics; state=ce.curation.recovery.open(metrics);
[state,errors]=ce.curation.recovery.checkpoint(metrics,1,[],state); verifyEmpty(testCase,errors);
extra=17; save(state.file,'extra','-append'); hash=ce.pipeline.fileFingerprint(state.file);
metrics.labels{1}='edit'; [~,errors]=ce.curation.recovery.checkpoint(metrics,1,[],state); verifyNumElements(testCase,errors,1);
verifyError(testCase,@() ce.curation.recovery.retire(state.file,state.writtenHash),'ce:curation:FileRevisionChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(state.file),hash);
end

function testMalformedJournalIsReportedWithoutDeletion(testCase)
metrics=testCase.TestData.metrics; state=ce.curation.recovery.open(metrics); mkdir(fileparts(state.file));
file=strrep(state.file,'.mat','.bad.mat'); fid=fopen(file,'w'); fprintf(fid,'not a MAT file'); fclose(fid);
candidates=ce.curation.recovery.discover(state); verifyNumElements(testCase,candidates,1);
verifyNotEmpty(testCase,candidates.error); verifyTrue(testCase,isfile(file));
end

function testDiscardRefreshDoesNotAcceptExternallyChangedSource(testCase)
metrics=testCase.TestData.metrics; entry=ce.curation.recovery.open(metrics);
originalHash=entry.sourceHash; metrics.labels{1}='draft';
[entry,errors]=ce.curation.recovery.checkpoint(metrics,1,[],entry); verifyEmpty(testCase,errors);
extra=17; save(testCase.TestData.file,'extra','-append');
[entry,errors]=ce.curation.recovery.refresh(metrics,1,false,1,[],entry,false);
verifyEmpty(testCase,errors); verifyEqual(testCase,entry.sourceHash,originalHash);
next=ce.curation.recovery.open(testCase.TestData.metrics); candidates=ce.curation.recovery.discover(next);
verifyError(testCase,@() ce.curation.recovery.prepare(testCase.TestData.metrics,next,candidates(1)), ...
    'ce:curation:FileRevisionChanged');
end

function testConfirmedSaveRetiresOwnedAndAcceptedDraftsOnly(testCase)
[entry,candidate]=draft(testCase); metrics=testCase.TestData.metrics;
[metrics,dirty]=ce.curation.recovery.prepare(metrics,entry,candidate);
entry.recovered=struct('file',candidate.file,'hash',candidate.hash);
[entry,errors]=ce.curation.recovery.checkpoint(metrics,dirty,[],entry); verifyEmpty(testCase,errors);
ce.io.saveCellMetrics(metrics,testCase.TestData.file);
[entry,errors]=ce.curation.recovery.refresh(metrics,1,true,[],[],entry);
verifyEmpty(testCase,errors); verifyFalse(testCase,isfile(entry.file)); verifyFalse(testCase,isfile(candidate.file));
verifyEqual(testCase,entry.baseline.labels,metrics.labels);
end

function testPartialBatchCheckpointFailureStillReturnsSuccessfulState(testCase)
metrics=testCase.TestData.metrics; other=metrics;
otherFolder=fullfile(testCase.TestData.folder,'other'); mkdir(otherFolder);
other.general.basepath=otherFolder; ce.io.saveCellMetrics(other,fullfile(otherFolder,'synthetic.cell_metrics.cellinfo.mat'));
batch=ce.data.assembleMetricBatch({metrics,other},{metrics.general.basepath,otherFolder},{'synthetic','synthetic'},'cell_metrics');
state=ce.curation.recovery.open(batch);
fid=fopen(fullfile(otherFolder,'.cellexplorer'),'w'); fclose(fid);
[state,errors]=ce.curation.recovery.checkpoint(batch,[1 3],[],state);
verifyNumElements(testCase,errors,1); verifyNotEmpty(testCase,state(1).writtenHash); verifyEmpty(testCase,state(2).writtenHash);
first=state(1).writtenHash;
delete(fullfile(otherFolder,'.cellexplorer'));
[state,errors]=ce.curation.recovery.checkpoint(batch,[1 3],[],state); verifyEmpty(testCase,errors);
verifyEqual(testCase,state(1).writtenHash,first); verifyNotEmpty(testCase,state(2).writtenHash);
[state,errors]=ce.curation.recovery.refresh(batch,1,true,3,[],state);
verifyEmpty(testCase,errors); verifyFalse(testCase,isfile(state(1).file)); verifyTrue(testCase,isfile(state(2).file));
end

function testFailedCheckpointAfterSaveKeepsAcceptedDraft(testCase)
[entry,candidate]=draft(testCase);
[metrics,dirty]=ce.curation.recovery.prepare(testCase.TestData.metrics,entry,candidate);
entry.recovered=struct('file',candidate.file,'hash',candidate.hash);
mkdir(entry.file); % Block replacement of this viewer's journal only.
[~,errors]=ce.curation.recovery.refresh(metrics,1,false,dirty,[],entry);
verifyNotEmpty(testCase,errors); verifyTrue(testCase,isfile(candidate.file));
verifyEqual(testCase,ce.pipeline.fileFingerprint(candidate.file),candidate.hash);
end

function testPendingReviewJournalIsCompactAndRestoredWithoutSaving(testCase)
metrics=testCase.TestData.metrics; count=2;
mono=struct('ccgR',zeros(3,count,count),'n',[20 30],'Pred',[],'Bounds',[], ...
 'completeIndex',[1 11 1;1 22 2],'binSize',.0004,'duration',.120,'conv_w',25, ...
 'Pcausal',nan(count),'sig_con',[1 2],'sig_con_excitatory',[1 2], ...
 'sig_con_inhibitory',zeros(0,2),'sig_con_excitatory_all',[1 2],'sig_con_inhibitory_all',zeros(0,2));
mono.processinginfo.cellIdentity=struct('UID',metrics.UID,'cluID',metrics.cluID,'shankID',metrics.shankID,'sortingRevision',metrics.general.sortingRevision);
monoFile=fullfile(testCase.TestData.folder,'synthetic.mono_res.cellinfo.mat'); ce.io.writeMat(monoFile,struct('mono_res',mono));
context=ce.curation.beginMonoSynReview(testCase.TestData.file,monoFile,metrics,1:2);
review=mono; review.sig_con=[]; review.sig_con_excitatory=[];
pending=struct('context',context,'review',review);
state=ce.curation.recovery.open(metrics); [state,errors]=ce.curation.recovery.checkpoint(metrics,[],pending,state); verifyEmpty(testCase,errors);
loaded=load(state.file,'recovery'); verifyFalse(testCase,isfield(loaded.recovery.pendingReview,'context'));
verifyFalse(testCase,isfield(loaded.recovery.pendingReview,'ccgR'));
next=ce.curation.recovery.open(metrics); candidates=ce.curation.recovery.discover(next);
[restored,dirty,recovered]=ce.curation.recovery.prepare(metrics,next,candidates(1));
verifyEqual(testCase,restored,metrics); verifyEmpty(testCase,dirty); verifyEmpty(testCase,recovered.review.sig_con);
verifyEqual(testCase,ce.pipeline.fileFingerprint(monoFile),context.monoHash);
extra=17; save(monoFile,'extra','-append');
verifyError(testCase,@() ce.curation.recovery.prepare(metrics,next,candidates(1)),'ce:curation:FileRevisionChanged');
end

function [entry,candidate]=draft(testCase)
metrics=testCase.TestData.metrics; state=ce.curation.recovery.open(metrics);
metrics.labels{1}='draft'; [~,errors]=ce.curation.recovery.checkpoint(metrics,1,[],state); assert(isempty(errors));
entry=ce.curation.recovery.open(testCase.TestData.metrics); candidates=ce.curation.recovery.discover(entry); candidate=candidates(1);
end
