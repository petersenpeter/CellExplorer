function tests = testMetricLoading
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder); testCase.TestData.folder = folder;
testCase.TestData.path = path; testCase.TestData.cwd = pwd;
testCase.TestData.metrics = fixture;
testCase.TestData.file = fullfile(folder,'synthetic.cell_metrics.cellinfo.mat');
cell_metrics = fixture; unrelated = 'named loading only'; %#ok<NASGU>
save(testCase.TestData.file,'cell_metrics','unrelated');
end

function teardown(testCase)
path(testCase.TestData.path); cd(testCase.TestData.cwd);
clear db_set_session db_load_settings;
rmdir(testCase.TestData.folder,'s');
end

function testLocalSingleAndBatchNeedNoDatabaseOrUI(testCase)
writeFunction(testCase,'db_load_settings',"function output = db_load_settings(varargin); error('test:DatabaseCalled','Unexpected database access'); end");
figures = findall(0,'Type','figure'); before = dir(testCase.TestData.folder);
metrics = loadCellMetrics('basepath',testCase.TestData.folder,'basename','synthetic');
verifyEqual(testCase,metrics.UID,[7 9]);
batch = loadCellMetricsBatch('basepaths',{testCase.TestData.folder},'basenames',{'synthetic'},'headless',true);
verifyEqual(testCase,batch.UID,[7 9]); verifyEqual(testCase,batch.batchIDs,[1 1]);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyEqual(testCase,pwd,testCase.TestData.cwd); verifyEqual(testCase,dir(testCase.TestData.folder),before);
end

function testInMemoryAndBatchRoutingAndFilters(testCase)
metrics = testCase.TestData.metrics;
[unchanged,indices] = loadCellMetrics('cell_metrics',metrics,'basepath','/missing', ...
    'brainRegion',{'CA1','CA3'},'putativeCellType',{'Pyramidal'});
verifyEqual(testCase,unchanged,metrics); verifyEqual(testCase,indices,1);
[~,indices] = loadCellMetrics('cell_metrics',metrics,'groundTruthClassification',{'verified'});
verifyEqual(testCase,indices,2);
[~,indices] = loadCellMetrics('cell_metrics',metrics,'tags',{'missing','reviewed'});
verifyEqual(testCase,indices,1);
[~,indices] = loadCellMetrics('cell_metrics',metrics,'animal',{'unknown'});
verifyEmpty(testCase,indices);
[batch,indices] = loadCellMetrics('basepaths',{testCase.TestData.folder,testCase.TestData.folder}, ...
    'basenames',{'synthetic','synthetic'},'headless',true,'labels',{'second'});
verifyEqual(testCase,batch.UID,[7 9 7 9]); verifyEqual(testCase,indices,[2 4]);
end

function testBatchOffsetsAndSessionIdentity(testCase)
first = fixture; second = fixture; second.UID = [9 7]; second.cellID = [9 7];
first.putativeConnections.excitatory = [1 2];
second.putativeConnections.inhibitory = [2 1];
second.putativeConnections.inhibitoryTransProb = .4;
batch = ce.data.assembleMetricBatch({first,second},{'a','b'},{'one','two'},'cell_metrics');
verifyEqual(testCase,batch.UID,[7 9 9 7]); verifyEqual(testCase,batch.batchIDs,[1 1 2 2]);
verifyEqual(testCase,batch.tags.reviewed,[1 3]);
verifyEqual(testCase,batch.groundTruthClassification.verified,[2 4]);
verifyEqual(testCase,batch.putativeConnections.excitatory,[1 2]);
verifyEqual(testCase,batch.putativeConnections.inhibitory,[4 3]);
verifyTrue(testCase,isnan(batch.putativeConnections.excitatoryTransProb));
verifyEqual(testCase,batch.putativeConnections.inhibitoryTransProb,.4);
verifyEqual(testCase,batch.general.batch{2},second.general);
verifyEqual(testCase,batch.session_investigator,{'Test','Test','Test','Test'});
end

function testMissingMetricsPadAllSessionPositions(testCase)
first = fixture; middle = fixture; last = fixture;
middle.acg.narrow = [1 2;3 4]; middle.psth.flash = {[1;2],[3;4]};
middle.extra = [11 12]; middle.logicalMetric = [true false];
last.labels = {'last A','last B'};
batch = ce.data.assembleMetricBatch({first,middle,last},{'a','b','c'},{'one','two','three'},'cell_metrics');
verifyEqual(testCase,batch.acg.narrow,[nan(2,2),[1 2;3 4],nan(2,2)]);
verifyEqual(testCase,batch.extra,[NaN NaN 11 12 NaN NaN]);
verifyEqual(testCase,batch.logicalMetric,[NaN NaN 1 0 NaN NaN]);
verifyEqual(testCase,batch.psth.flash,{[],[],[1;2],[3;4],[],[]});
end

function testBadDimensionsTypesAndIdentityFail(testCase)
first = fixture; bad = first; bad.UID = [7 7];
verifyError(testCase,@() assemble(first,bad),'ce:data:InvalidMetricIdentity');
bad = first; bad.general.cellCount = 3;
verifyError(testCase,@() assemble(first,bad),'ce:data:InvalidMetricIdentity');
bad = first; bad.batchIDs = [1 1]; bad.general.batch = {first.general};
verifyError(testCase,@() assemble(first,bad),'ce:data:InvalidMetricIdentity');
first.acg.narrow = zeros(3,2); bad = fixture; bad.acg.narrow = zeros(4,2);
verifyError(testCase,@() assemble(first,bad),'ce:data:MetricShapeConflict');
bad = fixture; bad.labels = {'too few'};
verifyError(testCase,@() assemble(fixture,bad),'ce:data:MetricShapeConflict');
bad = fixture; bad.firingRate = {'one','two'};
verifyError(testCase,@() assemble(fixture,bad),'ce:data:MetricShapeConflict');
end

function testNumericPaddingDoesNotLoseLargeIntegerValues(testCase)
first = fixture; first.extra = [uint64(2)^53+uint64(1),uint64(7)];
verifyError(testCase,@() assemble(first,fixture),'ce:data:MetricTypeConflict');
batch = assemble(first,first); verifyEqual(testCase,batch.extra,[first.extra first.extra]);
first.extra = [int64(-2)^53-int64(1),int64(7)];
verifyError(testCase,@() assemble(first,fixture),'ce:data:MetricTypeConflict');
end

function testUnsupportedBatchFormatIsExplicit(testCase)
verifyError(testCase,@() loadCellMetrics('basepaths',{testCase.TestData.folder}, ...
    'fileFormat','json','headless',true),'ce:io:UnsupportedBatchFormat');
end

function testLegacyGroupsAndInvalidConnectionIndices(testCase)
first = fixture; first.tags = {{'PV+','shared'},{'shared'}};
batch = assemble(first,fixture);
verifyEqual(testCase,batch.tags.PV_pos,1); verifyEqual(testCase,batch.tags.shared,[1 2]);
bad = fixture; bad.tags.reviewed = 3;
verifyError(testCase,@() assemble(fixture,bad),'ce:data:InvalidMetricGroups');
bad = fixture; bad.putativeConnections.excitatory = [1 3];
verifyError(testCase,@() assemble(fixture,bad),'ce:data:InvalidMetricConnections');
bad.putativeConnections.excitatory = [1 2]; bad.putativeConnections.excitatoryTransProb = [1 2];
verifyError(testCase,@() assemble(fixture,bad),'ce:data:MetricShapeConflict');
end

function testMalformedMissingFilesAndCancellationReturnNoBatch(testCase)
verifyError(testCase,@() ce.io.loadMetricBatch({testCase.TestData.folder},{'missing'}),'ce:io:MissingMetrics');
other = 42; save(testCase.TestData.file,'other');
verifyError(testCase,@() ce.io.readCellMetrics(testCase.TestData.file),'ce:io:InvalidMetricsFile');
cell_metrics = fixture; save(testCase.TestData.file,'cell_metrics');
hash = ce.pipeline.fileFingerprint(testCase.TestData.file);
verifyError(testCase,@() ce.io.loadMetricBatch({testCase.TestData.folder},{'synthetic'},'cell_metrics', ...
    @(fraction,message) error('test:Cancelled','Stop')),'test:Cancelled');
verifyEqual(testCase,ce.pipeline.fileFingerprint(testCase.TestData.file),hash);
end

function testProgressWindowOwnershipAndCancellation(testCase)
existing = findall(0,'Type','figure');
verifyError(testCase,@() loadCellMetricsBatch('basepaths',{testCase.TestData.folder},'basenames',{'missing'}),'ce:io:MissingMetrics');
verifyEqual(testCase,findall(0,'Type','figure'),existing);
handle = waitbar(0,'Test','Visible','off'); cleanup = onCleanup(@() deleteIfValid(handle));
loadCellMetricsBatch('basepaths',{testCase.TestData.folder},'basenames',{'synthetic'},'waitbar_handle',handle);
verifyTrue(testCase,isgraphics(handle));
[progress,ownedCleanup] = ce.ui.metricLoadProgress(true,handle); %#ok<ASGLU>
delete(handle); verifyError(testCase,@() progress(.5,'Loading'),'ce:io:LoadCancelled');
end

function testDatabaseBoundaryPreservesOrderAndDisablesWrites(testCase)
body = ["function [session,name,folder] = db_set_session(varargin)", ...
    "p=inputParser; addParameter(p,'sessionName',''); addParameter(p,'sessionId',[]);", ...
    "addParameter(p,'changeDir',true); addParameter(p,'saveMat',true); parse(p,varargin{:});", ...
    "assert(~p.Results.changeDir && ~p.Results.saveMat); session=struct();", ...
    "name=p.Results.sessionName; if isempty(name), name=num2str(p.Results.sessionId); end", ...
    "folder=fullfile(tempdir,name); end"];
writeFunction(testCase,'db_set_session',strjoin(body,newline));
[~,names] = ce.integrations.resolveMetricSessions({'second','first','second'},[]);
verifyEqual(testCase,names,{'second','first','second'});
[~,names] = ce.integrations.resolveMetricSessions({},[9 7 9]);
verifyEqual(testCase,names,{'9','7','9'});
verifyEqual(testCase,pwd,testCase.TestData.cwd);
end

function metrics = fixture
metrics = struct('UID',[7 9],'cellID',[1 2],'cluID',[21 42], ...
    'firingRate',[1 2],'brainRegion',{{'CA1','CA3'}},'labels',{{'first','second'}}, ...
    'putativeCellType',{{'Pyramidal Cell','Narrow Interneuron'}});
metrics.general = struct('cellCount',2,'basename','synthetic','session',struct('investigator','Test'));
metrics.tags.reviewed = 1; metrics.groundTruthClassification.verified = 2;
end

function batch = assemble(first,second)
batch = ce.data.assembleMetricBatch({first,second},{'a','b'},{'one','two'},'cell_metrics');
end

function writeFunction(testCase,name,body)
fid = fopen(fullfile(testCase.TestData.folder,[name,'.m']),'w');
fprintf(fid,'%s\n',body); fclose(fid); addpath(testCase.TestData.folder); rehash;
end

function deleteIfValid(handle)
if isgraphics(handle), delete(handle); end
end
