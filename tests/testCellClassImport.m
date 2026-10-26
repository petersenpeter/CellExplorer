function tests = testCellClassImport
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder); testCase.TestData.folder = folder;
testCase.TestData.session.general = struct('name','synthetic','basePath',folder);
testCase.TestData.spikes = struct('UID',[7 9],'cluID',[21 42]);
testCase.TestData.parameters = ce.pipeline.parseParameters('headless',true,'metrics',{'other_metrics'});
end

function teardown(testCase)
rmdir(testCase.TestData.folder,'s');
end

function testNamedLoadReordersLabelsWithoutWritingSource(testCase)
CellClass = struct('UID',[9 7],'cluID',[42 21],'label',{{'pI','pE'}});
write(testCase,CellClass); file = sourceFile(testCase); hash = ce.pipeline.fileFingerprint(file);
input = read(testCase);
verifyEqual(testCase,input.labels,{'pE','pI'});
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
verifyEqual(testCase,input.sha256,hash);
end

function testMissingAndConflictingIdentitiesRejected(testCase)
CellClass.label = {'pE','pI'}; write(testCase,CellClass);
verifyError(testCase,@() read(testCase),'ce:pipeline:CellImportIdentity');
for ids = {[7 7],[7 NaN],[7 11]}
    CellClass.UID = ids{1}; write(testCase,CellClass);
    verifyError(testCase,@() read(testCase),'ce:pipeline:CellImportIdentity');
end
CellClass.UID = [7 9]; CellClass.cluID = [42 21]; write(testCase,CellClass);
verifyError(testCase,@() read(testCase),'ce:pipeline:CellImportIdentity');
CellClass.cluID = [21 42 99]; write(testCase,CellClass);
verifyError(testCase,@() read(testCase),'ce:pipeline:CellImportIdentity');
end

function testClusterOnlyAndSelectedSubset(testCase)
CellClass = struct('cluID',[42 99 21],'label',{{'pI','extra','pE'}});
write(testCase,CellClass); input = read(testCase);
verifyEqual(testCase,input.labels,{'pE','pI'});
CellClass.UID = [9 11 7]; write(testCase,CellClass);
testCase.TestData.spikes = struct('UID',9,'cluID',42);
input = read(testCase); verifyEqual(testCase,input.labels,{'pI'});
end

function testLabelValidationAndUnknownDefaults(testCase)
CellClass = struct('UID',[7 9],'label',{{[],''}}); write(testCase,CellClass);
input = read(testCase); verifyEqual(testCase,input.labels,{'Unknown','Unknown'});
CellClass.label = {'pE';'pI'}; write(testCase,CellClass);
input = read(testCase); verifyEqual(testCase,input.labels,{'pE','pI'});
for labels = {{'one'}, {'pE',17}, {'pE',struct()}, {'pE',['aa';'bb']}}
    CellClass.label = labels{1}; write(testCase,CellClass);
    verifyError(testCase,@() read(testCase),'ce:pipeline:InvalidCellClass');
end
CellClass = 1; write(testCase,CellClass);
verifyError(testCase,@() read(testCase),'ce:pipeline:InvalidCellClass');
unrelated = struct(); save(sourceFile(testCase),'unrelated');
verifyError(testCase,@() read(testCase),'ce:pipeline:InvalidCellClass');
end

function testReuseChangedFileAndOutputRepair(testCase)
CellClass = struct('UID',[7 9],'label',{{'pE','pI'}}); write(testCase,CellClass);
original = struct('labels',{{'manual A','manual B'}},'putativeCellType',{{'Reviewed','Reviewed'}});
[first,result] = run(testCase,original); verifyEqual(testCase,result.status,'completed');
[again,result] = run(testCase,first); verifyEqual(testCase,result.status,'reused');
verifyEqual(testCase,again,first);
again.CellClassBuzcode{1} = 'changed';
[repaired,result] = run(testCase,again); verifyEqual(testCase,result.reason,'changed_outputs');
verifyEqual(testCase,repaired.CellClassBuzcode,CellClass.label);
CellClass.label{1} = 'new source label'; write(testCase,CellClass);
[changed,result] = run(testCase,repaired); verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,changed.CellClassBuzcode,CellClass.label);
verifyEqual(testCase,changed.labels,original.labels);
verifyEqual(testCase,changed.putativeCellType,original.putativeCellType);
testCase.TestData.parameters.forceReload = true;
[~,result] = run(testCase,changed); verifyEqual(testCase,result.reason,'forced');
end

function testFileContentsAndTargetOrderDetermineReuse(testCase)
CellClass = struct('UID',[7 9],'cluID',[21 42],'label',{{'pE','pI'}}); write(testCase,CellClass);
[first,~] = run(testCase,struct());
parameters = 'changed extra variable'; save(sourceFile(testCase),'CellClass','parameters');
[changed,result] = run(testCase,first); verifyEqual(testCase,result.reason,'changed_inputHash');
testCase.TestData.spikes = struct('UID',[9 7],'cluID',[42 21]);
[reordered,result] = run(testCase,changed); verifyEqual(testCase,result.reason,'changed_inputHash');
verifyEqual(testCase,reordered.CellClassBuzcode,{'pI','pE'});
testCase.TestData.parameters.excludeIntervals = [10 20];
testCase.TestData.parameters.restrictToIntervals = [1 30];
[~,result] = run(testCase,reordered); verifyEqual(testCase,result.status,'reused');
end

function testMissingSourcePreservesLegacyAndRetiresManagedLabels(testCase)
legacy.CellClassBuzcode = {'legacy A','legacy B'};
[unchanged,result] = run(testCase,legacy);
verifyEqual(testCase,result.status,'skipped'); verifyEqual(testCase,unchanged,legacy);
CellClass = struct('UID',[7 9],'label',{{'pE','pI'}}); write(testCase,CellClass);
[first,~] = run(testCase,legacy); delete(sourceFile(testCase));
[removed,result] = run(testCase,first);
verifyEqual(testCase,result.status,'completed'); verifyFalse(testCase,isfield(removed,'CellClassBuzcode'));
[~,result] = run(testCase,removed); verifyEqual(testCase,result.status,'reused');
write(testCase,CellClass); [restored,~] = run(testCase,removed);
verifyEqual(testCase,restored.CellClassBuzcode,CellClass.label);
end

function file = sourceFile(testCase)
file = fullfile(testCase.TestData.folder,'synthetic.CellClass.cellinfo.mat');
end

function write(testCase,CellClass)
parameters = 'unrelated variable must not leak into the caller'; %#ok<NASGU>
save(sourceFile(testCase),'CellClass','parameters');
end

function input = read(testCase)
input = ce.pipeline.cellClassInput(testCase.TestData.session,testCase.TestData.spikes);
end

function [metrics,result] = run(testCase,metrics)
[metrics,result] = ce.pipeline.runCellClass(metrics,testCase.TestData.spikes, ...
    testCase.TestData.session,testCase.TestData.parameters);
end
