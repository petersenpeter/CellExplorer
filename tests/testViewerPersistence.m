function tests=testViewerPersistence
tests=functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder;
metrics=fixture; file=fullfile(folder,'synthetic.reviewed.cellinfo.mat');
cell_metrics=metrics; notes='Preserve extra MAT variables in the backup'; save(file,'cell_metrics','notes');
testCase.TestData.metrics=metrics; testCase.TestData.file=file;
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testSnapshotPreservesExactPreviousFile(testCase)
file=testCase.TestData.file; before=ce.pipeline.fileFingerprint(file);
metrics=testCase.TestData.metrics; metrics.labels={'new first','new second'}; metrics.firingRate=[8 9];
result=ce.curation.saveMetricSnapshot(metrics,file);
verifyTrue(testCase,result.saved); verifyEqual(testCase,ce.pipeline.fileFingerprint(result.backup),before);
verifyTrue(testCase,contains(result.backup,[filesep,'reviewed_']));
loaded=load(file,'cell_metrics'); verifyEqual(testCase,loaded.cell_metrics,metrics);
old=load(result.backup); verifyTrue(testCase,isfield(old,'notes'));
end

function testRevisionAndIdentityMismatchDoNotWrite(testCase)
file=testCase.TestData.file; before=ce.pipeline.fileFingerprint(file);
metrics=testCase.TestData.metrics;
changed=metrics; changed.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:SortingRevisionMismatch');
changed=metrics; changed.general=rmfield(changed.general,'sortingRevision');
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:SortingRevisionMismatch');
changed=metrics; changed.UID=[1 3];
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:IdentityMismatch');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testBatchChecksEverySessionRevisionAndSourceOrder(testCase)
metrics=batchFixture; file=testCase.TestData.file; ce.io.saveCellMetrics(metrics,file);
changed=metrics; changed.general.batch{2}.sortingRevision=repmat('c',1,64);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:SortingRevisionMismatch');
changed=metrics; changed.general.basenames=fliplr(changed.general.basenames);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:IdentityMismatch');
changed=metrics; changed.general.batch=changed.general.batch(1);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(changed,file),'ce:curation:IdentityMismatch');
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
changed=metrics; changed.labels{4}='updated'; ce.curation.saveMetricSnapshot(changed,file);
loaded=load(file,'cell_metrics'); verifyEqual(testCase,loaded.cell_metrics.labels{4},'updated');
end

function testBackupFailureAbortsReplacement(testCase)
file=testCase.TestData.file; before=ce.pipeline.fileFingerprint(file);
fid=fopen(fullfile(testCase.TestData.folder,'revisions_cell_metrics'),'w'); fclose(fid);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(testCase.TestData.metrics,file),'ce:curation:BackupFailed');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
end

function testArbitraryMatFilenameKeepsBackupSaveAsPrefix(testCase)
file=fullfile(testCase.TestData.folder,'export.mat'); metrics=testCase.TestData.metrics;
ce.io.saveCellMetrics(metrics,file);
result=ce.curation.saveMetricSnapshot(metrics,file);
verifyTrue(testCase,contains(result.backup,[filesep,'reviewed_']));
end

function testChangedExpectedRevisionAbortsBeforeBackup(testCase)
file=testCase.TestData.file; expected=ce.pipeline.fileFingerprint(file);
metrics=testCase.TestData.metrics; metrics.labels{1}='concurrent edit'; ce.io.saveCellMetrics(metrics,file);
before=ce.pipeline.fileFingerprint(file);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(testCase.TestData.metrics,file,expected),'ce:curation:FileRevisionChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testNewExportsAndUnverifiableExistingDestinations(testCase)
metrics=testCase.TestData.metrics;
for extension={'mat','json'}
    file=fullfile(testCase.TestData.folder,['export.',extension{1}]);
    result=ce.curation.saveMetricSnapshot(metrics,file); verifyTrue(testCase,result.saved); verifyEmpty(testCase,result.backup);
end
file=fullfile(testCase.TestData.folder,'export.json'); before=ce.pipeline.fileFingerprint(file);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(metrics,file),'ce:curation:UnverifiableDestination');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
file=fullfile(testCase.TestData.folder,'unrelated.mat'); other=17; save(file,'other'); before=ce.pipeline.fileFingerprint(file);
verifyError(testCase,@() ce.curation.saveMetricSnapshot(metrics,file),'ce:io:InvalidMetricsFile');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
end

function testRestoreMapsUIDsAndLeavesScientificFieldsAlone(testCase)
metrics=testCase.TestData.metrics;
backup=ce.curation.captureAnnotations(metrics,[2 1]); backup.labels={'second restored','first restored'};
backup.tags.selected=1; backup.firingRate=[99 99];
restored=ce.curation.restoreAnnotations(metrics,backup);
verifyEqual(testCase,restored.labels,{'first restored','second restored'});
verifyEqual(testCase,restored.tags.selected,2); verifyEqual(testCase,restored.firingRate,metrics.firingRate);
verifyEqual(testCase,metrics,testCase.TestData.metrics);
end

function testBatchRestoreHandlesNoncontiguousSessionIndices(testCase)
metrics=batchFixture;
backup=ce.curation.captureAnnotations(metrics,[4 2]); backup.labels={'second restored','first restored'};
backup.tags.selected=1;
restored=ce.curation.restoreAnnotations(metrics,backup,[2 4]);
verifyEqual(testCase,restored.labels,{'first','first restored','second','second restored'});
verifyEqual(testCase,restored.tags.selected,[1 4]);
verifyEqual(testCase,restored.general,metrics.general);
verifyError(testCase,@() ce.curation.captureAnnotations(metrics,[1 2]),'ce:curation:CellCountMismatch');
end

function testRestoreRejectsCountOnlyAndChangedRevision(testCase)
metrics=testCase.TestData.metrics; backup=ce.curation.captureAnnotations(metrics);
backup=rmfield(backup,'UID');
verifyError(testCase,@() ce.curation.restoreAnnotations(metrics,backup),'ce:curation:MissingIdentity');
backup=ce.curation.captureAnnotations(metrics); backup.general.sortingRevision=repmat('b',1,64);
verifyError(testCase,@() ce.curation.restoreAnnotations(metrics,backup),'ce:curation:SortingRevisionMismatch');
backup.general=rmfield(backup.general,'sortingRevision');
verifyError(testCase,@() ce.curation.restoreAnnotations(metrics,backup),'ce:curation:SortingRevisionMismatch');
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testAnnotationBackupsRetainIdentityAndRevision(testCase)
metrics=testCase.TestData.metrics;
file=ce.curation.writeAnnotationBackup(metrics,[2 1],testCase.TestData.folder,'reviewed');
backup=load(file,'cell_metrics'); verifyEqual(testCase,backup.cell_metrics.UID,[2 1]);
verifyEqual(testCase,backup.cell_metrics.general.sortingRevision,metrics.general.sortingRevision);
verifyEqual(testCase,ce.curation.restoreAnnotations(metrics,backup.cell_metrics),metrics);
end

function testLegacyIdentityBearingBackupsStillRestore(testCase)
metrics=testCase.TestData.metrics; metrics.general=rmfield(metrics.general,'sortingRevision');
backup=ce.curation.captureAnnotations(metrics); backup.labels{1}='legacy';
restored=ce.curation.restoreAnnotations(metrics,backup); verifyEqual(testCase,restored.labels{1},'legacy');
end

function metrics=fixture
metrics=struct('UID',[1 2],'cluID',[11 22],'labels',{{'first','second'}},'firingRate',[1 2]);
metrics.general=struct('cellCount',2,'saveAs','reviewed','sortingRevision',repmat('a',1,64));
metrics.groups=struct(); metrics.tags=struct('selected',1); metrics.groundTruthClassification=struct();
end

function metrics=batchFixture
one=fixture; two=fixture; two.general.sortingRevision=repmat('b',1,64);
metrics=one; metrics.UID=[1 1 2 2]; metrics.cluID=[11 11 22 22]; metrics.batchIDs=[1 2 1 2];
metrics.labels={'first','first other','second','second other'}; metrics.firingRate=[1 1 2 2];
metrics.tags.selected=[1 4];
metrics.general=struct('cellCount',4,'batch',{{one.general,two.general}}, ...
    'basenames',{{'one','two'}},'basepaths',{{'/one','/two'}});
end
