function tests = testCuration
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname;
mkdir(folder);
testCase.TestData.folder = folder;
end

function teardown(testCase)
rmdir(testCase.TestData.folder, 's');
end

function testReorderedUnitsMapAnnotationsAndGroups(testCase)
target = fixture;
source = target;
source.UID = [2 1];
source.cluID = [22 11];
source.labels = {'new second','new first'};
source.tags.selected = 1;
source.firingRate = [999 999];
updated = ce.curation.applyAnnotations(target,source,[1 2]);
verifyEqual(testCase,updated.labels,{'new first','new second'});
verifyEqual(testCase,updated.tags.selected,2);
verifyEqual(testCase,updated.firingRate,target.firingRate);
verifyEqual(testCase,updated.UID,target.UID);
end

function testBatchSessionLocalIDs(testCase)
target = fixture;
source.UID = [1 2 1 2];
source.cluID = [90 91 11 22];
source.labels = {'other','other','selected first','selected second'};
source.groups.selected = [1 4];
updated = ce.curation.applyAnnotations(target,source,[3 4]);
verifyEqual(testCase,updated.labels,{'selected first','selected second'});
verifyEqual(testCase,updated.groups.selected,2);
end

function testCountMismatchRejected(testCase)
target = fixture;
verifyError(testCase,@() ce.curation.applyAnnotations(target,target,1),'ce:curation:CellCountMismatch');
end

function testChangedUIDRejected(testCase)
target = fixture;
source = target;
source.UID = [1 3];
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:IdentityMismatch');
end

function testChangedClusterRejected(testCase)
target = fixture;
source = target;
source.cluID = [11 99];
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:IdentityMismatch');
end

function testDuplicateUIDRejected(testCase)
target = fixture;
source = target;
source.UID = [1 1];
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:InvalidIdentity');
end

function testInvalidGroupRejected(testCase)
target = fixture;
source = target;
source.groups.invalid = 3;
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:InvalidAnnotations');
end

function testSuccessfulSaveBacksUpOriginal(testCase)
target = fixture;
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat');
ce.io.saveCellMetrics(target,file);
source = target;
source.labels = {'new first','new second'};
ce.curation.saveSessionAnnotations(file,source,[1 2]);
stored = load(file);
verifyEqual(testCase,stored.cell_metrics.labels,source.labels);
backups = dir(fullfile(testCase.TestData.folder,'revisions_cell_metrics','cell_metrics_*.mat'));
verifyNumElements(testCase,backups,1);
backup = load(fullfile(backups(1).folder,backups(1).name));
verifyEqual(testCase,backup.cell_metrics.labels,target.labels);
verifyEqual(testCase,backup.cell_metrics.UID,target.UID);
end

function testRejectedSavePreservesOriginal(testCase)
target = fixture;
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat');
ce.io.saveCellMetrics(target,file);
source = target;
source.cluID = [11 99];
verifyError(testCase,@() ce.curation.saveSessionAnnotations(file,source,[1 2]),'ce:curation:IdentityMismatch');
stored = load(file);
verifyEqual(testCase,stored.cell_metrics,target);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
end

function testFailedBackupPreservesOriginal(testCase)
target = fixture;
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat');
ce.io.saveCellMetrics(target,file);
fid = fopen(fullfile(testCase.TestData.folder,'revisions_cell_metrics'),'w');
fclose(fid);
source = target;
source.labels = {'new first','new second'};
verifyError(testCase,@() ce.curation.saveSessionAnnotations(file,source,[1 2]),'ce:curation:BackupFailed');
stored = load(file);
verifyEqual(testCase,stored.cell_metrics,target);
end

function testPartialAndCanceledSavesRetainDirtyCells(testCase)
changed = [1 3 4 3 5];
batchIDs = [1 1 2 2 3];
verifyEqual(testCase,ce.curation.remainingChanges(changed,batchIDs,1),[3 4 3 5]);
verifyEqual(testCase,ce.curation.remainingChanges(changed,batchIDs,[]),changed);
verifyEmpty(testCase,ce.curation.remainingChanges(changed,batchIDs,[1 2 3]));
end

function testSortingRevisionRequiredOnBothSides(testCase)
target = fixture; target.general.sortingRevision = repmat('a',1,64);
source = target; source.general.sortingRevision = repmat('b',1,64);
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:SortingRevisionMismatch');
source.general = rmfield(source.general,'sortingRevision');
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:SortingRevisionMismatch');
verifyError(testCase,@() ce.curation.applyAnnotations(source,target,[1 2]),'ce:curation:SortingRevisionMismatch');
source.general.sortingRevision = 'invalid';
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:data:InvalidSortingRevision');
end

function testBatchUsesSelectedSessionsRevision(testCase)
target = fixture; target.general.sortingRevision = repmat('a',1,64);
source.UID = [1 2 1 2]; source.cluID = [11 22 11 22]; source.batchIDs = [1 1 2 2];
source.labels = {'other','other','selected first','selected second'};
source.general.batch = {struct('sortingRevision',repmat('b',1,64)),target.general};
updated = ce.curation.applyAnnotations(target,source,[3 4]);
verifyEqual(testCase,updated.labels,source.labels(3:4));
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 2]),'ce:curation:SortingRevisionMismatch');
verifyError(testCase,@() ce.curation.applyAnnotations(target,source,[1 4]),'ce:data:InvalidSortingRevision');
end

function testRejectedRevisionPreservesFileAndBackupKeepsRevision(testCase)
target = fixture; target.general.sortingRevision = repmat('a',1,64);
file = fullfile(testCase.TestData.folder,'synthetic.cell_metrics.cellinfo.mat');
ce.io.saveCellMetrics(target,file); before = ce.pipeline.fileFingerprint(file);
source = target; source.labels = {'new first','new second'};
source.general.sortingRevision = repmat('b',1,64);
verifyError(testCase,@() ce.curation.saveSessionAnnotations(file,source,[1 2]),'ce:curation:SortingRevisionMismatch');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
verifyFalse(testCase,isfolder(fullfile(testCase.TestData.folder,'revisions_cell_metrics')));
source.general.sortingRevision = target.general.sortingRevision;
ce.curation.saveSessionAnnotations(file,source,[1 2]);
backups = dir(fullfile(testCase.TestData.folder,'revisions_cell_metrics','*.mat'));
verifyNumElements(testCase,backups,1);
backup = load(fullfile(backups(1).folder,backups(1).name),'cell_metrics');
verifyEqual(testCase,backup.cell_metrics.general.sortingRevision,target.general.sortingRevision);
verifyEqual(testCase,backup.cell_metrics.labels,target.labels);
stored = load(file,'cell_metrics'); verifyEqual(testCase,stored.cell_metrics.labels,source.labels);
end

function metrics = fixture
metrics.general.cellCount = 2;
metrics.general.saveAs = 'cell_metrics';
metrics.UID = [1 2];
metrics.cluID = [11 22];
metrics.firingRate = [1.5 2.5];
metrics.labels = {'old first','old second'};
metrics.groups = struct();
metrics.tags = struct();
end
