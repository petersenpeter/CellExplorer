function tests = testMetricReplacement
tests = functiontests(localfunctions);
end

function testLoadFailureNeverCapturesOrChangesActiveSession(testCase)
state = fixtureState;
original = state;
result = ce.ui.tryMetricLoad(@() failLoad('ce:io:MissingMetrics'), ...
    @() error('test:Unexpected','confirm called'),@() error('test:Unexpected','capture called'), ...
    @apply,@restore);
verifyEqual(testCase,result.status,'failed'); verifyEqual(testCase,result.phase,'load');
verifyEqual(testCase,state,original);
    function apply(candidate), state.metrics = candidate; end
    function restore(previous), state = previous; end
end

function testDecliningReplacementPreservesUnsavedEdits(testCase)
state = fixtureState; original = state;
result = ce.ui.tryMetricLoad(@() state.metrics,@() false,@() state,@apply,@restore);
verifyEqual(testCase,result.status,'cancelled'); verifyEqual(testCase,state,original);
    function apply(candidate), state.metrics = candidate; state.dirty = []; end
    function restore(previous), state = previous; end
end

function testFailedInitializationRestoresEditsHistoryAndSelection(testCase)
state = fixtureState; original = state;
candidate = state.metrics; candidate.labels = {'disk','disk'};
result = ce.ui.tryMetricLoad(@() candidate,@() true,@() state,@apply,@restore);
verifyEqual(testCase,result.status,'failed'); verifyEqual(testCase,result.phase,'initialize');
verifyEqual(testCase,result.error.identifier,'test:InitializeFailed');
verifyEmpty(testCase,result.restoreError); verifyEqual(testCase,state,original);
    function apply(incoming)
        state.metrics = incoming; state.dirty = []; state.undo = []; state.selectedCell = 1;
        error('test:InitializeFailed','Failure after model mutation');
    end
    function restore(previous), state = previous; end
end

function testSuccessfulReplacementOnlyClearsStateDuringApply(testCase)
state = fixtureState; candidate = state.metrics; candidate.labels{1} = 'loaded';
result = ce.ui.tryMetricLoad(@() candidate,@() true,@() state,@apply,@restore);
verifyEqual(testCase,result.status,'loaded'); verifyEqual(testCase,state.metrics,candidate);
verifyEmpty(testCase,state.dirty);
    function apply(incoming), state.metrics = incoming; state.dirty = []; end
    function restore(previous), state = previous; end
end

function testProgressEditsAreCapturedAfterLoading(testCase)
state = fixtureState;
result = ce.ui.tryMetricLoad(@loadWithEdit,@() true,@capture,@apply,@restore);
verifyEqual(testCase,result.status,'failed');
verifyEqual(testCase,state.metrics.labels{2},'edited during loading');
verifyEqual(testCase,state.dirty,[1 2]);
    function candidate = loadWithEdit
        candidate = state.metrics;
        state.metrics.labels{2} = 'edited during loading'; state.dirty = [1 2];
    end
    function apply(incoming), state.metrics = incoming; error('test:InitializeFailed','Failure'); end
    function previous = capture, previous = state; end
    function restore(previous), state = previous; end
end

function testCancellationAndRestoreFailureReportedSeparately(testCase)
state = fixtureState;
result = ce.ui.tryMetricLoad(@() failLoad('ce:io:LoadCancelled'),@() true,@() state,@apply,@restore);
verifyEqual(testCase,result.status,'cancelled');
result = ce.ui.tryMetricLoad(@() state.metrics,@() true,@() state,@apply,@restore);
verifyEqual(testCase,result.error.identifier,'test:InitializeFailed');
verifyEqual(testCase,result.restoreError.identifier,'test:RestoreFailed');
    function apply(candidate), error('test:InitializeFailed','Failure'); end
    function restore(previous), error('test:RestoreFailed','Failure'); end
end

function testReloadUsesActualSingleFilenameAndBatchSaveAs(testCase)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
state = fixtureState; cell_metrics = state.metrics;
cell_metrics.general.basename = 'recording.with.dots';
file = fullfile(folder,'recording.with.dots.reviewed.cellinfo.mat');
UI = 'must not enter the caller workspace'; save(file,'cell_metrics','UI'); %#ok<NASGU>
selected = ce.ui.readMetricSelection(file);
verifyEqual(testCase,selected.general.basename,'recording.with.dots');
verifyEqual(testCase,selected.general.saveAs,'reviewed');
verifyEqual(testCase,ce.ui.reloadMetricSelection(selected),selected);
file2 = fullfile(folder,'arbitrary-name.mat'); save(file2,'cell_metrics');
selected = ce.ui.readMetricSelection(file2);
verifyEqual(testCase,selected.general.filename,'arbitrary-name.mat');
verifyEqual(testCase,ce.ui.reloadMetricSelection(selected),selected);
cell_metrics.labels = {'second','second'};
save(fullfile(folder,'recording.with.dots.other.cellinfo.mat'),'cell_metrics');
batch.general = struct('batch',{{struct(),struct()}},'basepaths',{{folder,folder}}, ...
    'basenames',{{'recording.with.dots','recording.with.dots'}},'saveAs',{{'reviewed','other'}});
reloaded = ce.ui.reloadMetricSelection(batch);
verifyEqual(testCase,reloaded.labels,{'unsaved','original','second','second'});
verifyEqual(testCase,reloaded.general.saveAs,{'reviewed','other'});
end

function testSavedViewerSingleSessionCanJoinBatch(testCase)
state = fixtureState; single = state.metrics; single.batchIDs = [1 1];
batch = ce.data.assembleMetricBatch({single,single},{'a','b'},{'a','b'},'cell_metrics');
verifyEqual(testCase,batch.batchIDs,[1 1 2 2]); verifyEqual(testCase,batch.UID,[7 9 7 9]);
end

function testControlStateRestoredAfterPartialInitialization(testCase)
fig = figure('Visible','off'); cleanup = onCleanup(@() delete(fig));
control = uicontrol(fig,'Style','popupmenu','String',{'old','selected'},'Value',2);
menu = uimenu(fig,'Text','Save','ForegroundColor',[1 0 0]);
mode = uimenu(fig,'Text','Reference','Checked','on');
tabs = uitabgroup(fig); first = uitab(tabs); second = uitab(tabs);
tabs.SelectedTab = first;
table = uitable(fig,'Data',{'unsaved'});
snapshot = ce.ui.captureMetricView(fig);
set(control,'Value',1,'String',{'new'}); menu.ForegroundColor = [0 0 0]; table.Data = {'disk'};
mode.Checked = 'off'; tabs.SelectedTab = second;
ce.ui.restoreMetricView(snapshot);
verifyEqual(testCase,control.String,{'old';'selected'}); verifyEqual(testCase,control.Value,2);
verifyEqual(testCase,menu.ForegroundColor,[1 0 0]); verifyEqual(testCase,table.Data,{'unsaved'});
verifyEqual(testCase,char(mode.Checked),'on'); verifyEqual(testCase,tabs.SelectedTab,first);
end

function state = fixtureState
state.metrics = struct('UID',[7 9],'labels',{{'unsaved','original'}},'general',struct('cellCount',2));
state.dirty = 1; state.undo = struct('cellIDs',1,'labels',{{'before'}}); state.selectedCell = 2;
end

function candidate = failLoad(identifier)
candidate = []; %#ok<NASGU>
error(identifier,'Synthetic read failure');
end
