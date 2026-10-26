function tests=testAnnotationConflicts
tests=functiontests(localfunctions);
end
function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder;
metrics=struct('UID',[7 9 12],'cluID',[11 22 33],'labels',{{'one','two','three'}}, ...
 'brainRegion',{{'CA1','CA1','CA1'}},'tags',struct('A',1),'groups',struct(), ...
 'groundTruthClassification',struct(),'firingRate',[1 2 3]);
metrics.general=struct('cellCount',3,'basepath',folder,'basename','synthetic','saveAs','cell_metrics','sortingRevision',repmat('a',1,64));
file=fullfile(folder,'synthetic.cell_metrics.cellinfo.mat'); ce.io.saveCellMetrics(metrics,file);
testCase.TestData.metrics=metrics; testCase.TestData.file=file;
end
function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end
function testIndependentEditsMergeByUIDAndLeaveScienceOut(testCase)
b=ce.curation.captureAnnotations(testCase.TestData.metrics); l=b; d=b;
l.labels{1}='mine'; d.labels{2}='theirs'; d.brainRegion{1}='CA3';
d=ce.curation.captureAnnotations(d,[3 1 2]);
[m,c]=ce.curation.mergeAnnotations(b,l,d);
verifyEmpty(testCase,c); verifyEqual(testCase,m.UID,[12 7 9]);
verifyEqual(testCase,m.labels,{'three','mine','theirs'}); verifyEqual(testCase,m.brainRegion,{'CA1','CA3','CA1'});
verifyFalse(testCase,isfield(m,'firingRate'));
end
function testDivergentAndIdenticalChanges(testCase)
b=ce.curation.captureAnnotations(testCase.TestData.metrics); l=b; d=b;
l.labels{1}='mine'; d.labels{1}='disk'; l.labels{2}='same'; d.labels{2}='same';
[~,c]=ce.curation.mergeAnnotations(b,l,d); verifyNumElements(testCase,c,1);
verifyEqual(testCase,c.UID,7); verifyEqual(testCase,c.field,'labels');
m=ce.curation.mergeAnnotations(b,l,d,{'mine'}); verifyEqual(testCase,m.labels,{'mine','same','three'});
m=ce.curation.mergeAnnotations(b,l,d,{'disk'}); verifyEqual(testCase,m.labels,{'disk','same','three'});
verifyError(testCase,@() ce.curation.mergeAnnotations(b,l,d,{}),'ce:curation:InvalidResolution');
end
function testGroupMembershipCombinesButDeleteVersusEditConflicts(testCase)
b=ce.curation.captureAnnotations(testCase.TestData.metrics); l=b; d=b;
l.tags.A=[1 2]; d.tags.A=[1 3]; l.tags.New=1; d.tags.New=2;
[m,c]=ce.curation.mergeAnnotations(b,l,d); verifyEmpty(testCase,c);
verifyEqual(testCase,m.tags.A,1:3); verifyEqual(testCase,m.tags.New,[1 2]);
l.tags=rmfield(l.tags,'A'); [~,c]=ce.curation.mergeAnnotations(b,l,d);
verifyNumElements(testCase,c,1); verifyEqual(testCase,c.field,'tags.A');
m=ce.curation.mergeAnnotations(b,l,d,{'mine'}); verifyFalse(testCase,isfield(m.tags,'A'));
m=ce.curation.mergeAnnotations(b,l,d,{'disk'}); verifyEqual(testCase,m.tags.A,[1 3]);
end
function testMissingFieldsAndNaNs(testCase)
b=ce.curation.captureAnnotations(testCase.TestData.metrics); b.deepSuperficialDistance=[nan 2 3]; l=b; d=b;
l.deepSuperficialDistance(2)=4; d=rmfield(d,'deepSuperficialDistance');
[~,c]=ce.curation.mergeAnnotations(b,l,d); verifyNumElements(testCase,c,1);
m=ce.curation.mergeAnnotations(b,l,d,{'disk'}); verifyFalse(testCase,isfield(m,'deepSuperficialDistance'));
d=b; [m,c]=ce.curation.mergeAnnotations(b,l,d); verifyEmpty(testCase,c); verifyEqual(testCase,m.deepSuperficialDistance,[nan 4 3]);
end
function testRevisionChangeCannotBeResolvedByValueChoices(testCase)
b=ce.curation.captureAnnotations(testCase.TestData.metrics); d=b; d.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.mergeAnnotations(b,b,d,{}),'ce:curation:SortingRevisionMismatch');
end
function testOpenToSaveRevisionGuardPreservesConcurrentAnnotations(testCase)
m=testCase.TestData.metrics; state=ce.curation.recovery.open(m);
d=m; d.labels{2}='other viewer'; ce.io.saveCellMetrics(d,testCase.TestData.file);
hash=ce.pipeline.fileFingerprint(testCase.TestData.file); m.labels{1}='mine';
verifyError(testCase,@() ce.curation.saveSessionAnnotations(testCase.TestData.file,m,1:3,state.sourceHash),'ce:curation:FileRevisionChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),hash);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end
function testReconciliationIsReadOnlyAndRetainsLatestScience(testCase)
m=testCase.TestData.metrics; state=ce.curation.recovery.open(m); m.labels{1}='mine';
d=testCase.TestData.metrics; d.labels{2}='disk'; d.firingRate=[10 20 30]; ce.io.saveCellMetrics(d,testCase.TestData.file);
hash=ce.pipeline.fileFingerprint(testCase.TestData.file);
plan=ce.curation.prepareAnnotationReconciliation(m,state);
[disk,merged]=ce.curation.resolveAnnotationReconciliation(plan,{{}});
verifyEqual(testCase,disk.firingRate,[10 20 30]); verifyEqual(testCase,merged{1}.labels,{'mine','disk','three'});
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),hash);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end
function testAnotherChangeDuringChoicesRejectsWholeReconciliation(testCase)
m=testCase.TestData.metrics; state=ce.curation.recovery.open(m); plan=ce.curation.prepareAnnotationReconciliation(m,state);
extra=1; save(testCase.TestData.file,'extra','-append');
verifyError(testCase,@() ce.curation.resolveAnnotationReconciliation(plan,{{}}),'ce:curation:FileRevisionChanged');
end
function testBatchKeepsSessionLocalIDsAndAlternateNames(testCase)
m=testCase.TestData.metrics; other=m; folder=fullfile(testCase.TestData.folder,'other'); mkdir(folder);
other.general.basepath=folder; other.general.saveAs='reviewed'; file=fullfile(folder,'synthetic.reviewed.cellinfo.mat'); ce.io.saveCellMetrics(other,file);
batch=ce.data.assembleMetricBatch({m,other},{m.general.basepath,folder},{'synthetic','synthetic'},'cell_metrics');
batch.general.saveAs={'cell_metrics','reviewed'}; state=ce.curation.recovery.open(batch);
batch.labels{1}='first local'; batch.labels{4}='second local'; other.labels{2}='second disk'; ce.io.saveCellMetrics(other,file);
plan=ce.curation.prepareAnnotationReconciliation(batch,state); [disk,merged]=ce.curation.resolveAnnotationReconciliation(plan,{{},{}});
verifyEqual(testCase,disk.general.saveAs,{'cell_metrics','reviewed'});
verifyEqual(testCase,merged{1}.labels,{'first local','two','three'});
verifyEqual(testCase,merged{2}.labels,{'second local','second disk','three'});
end

function testPostSaveExternalWriteNeverBecomesOurExpectedRevision(testCase)
m=testCase.TestData.metrics; state=ce.curation.recovery.open(m); m.labels{1}='mine';
receipt=ce.curation.saveMetricSnapshot(m,testCase.TestData.file,state.sourceHash);
d=m; d.labels{2}='external after save'; ce.io.saveCellMetrics(d,testCase.TestData.file);
[state,errors]=ce.curation.recovery.refresh(m,1,true,[],[],state,true,receipt);
verifyNotEmpty(testCase,errors); verifyEqual(testCase,state.sourceHash,receipt.hash);
verifyEqual(testCase,state.diskBaseline.labels,m.labels);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(m,testCase.TestData.file,state.sourceHash),'ce:curation:FileRevisionChanged');
plan=ce.curation.prepareAnnotationReconciliation(m,state);
[~,merged]=ce.curation.resolveAnnotationReconciliation(plan,{{}});
verifyEqual(testCase,merged{1}.labels,{'mine','external after save','three'});
end
