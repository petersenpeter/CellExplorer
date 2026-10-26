function summary = runTutorialViewerLoadSmoke(source, tableMode)
%RUNTUTORIALVIEWERLOADSMOKE Exercise real viewer callbacks with isolated dialogs.
% Uses temporary data; stubs only dialogs, preferences persistence and DB/analytics.
if nargin < 2, tableMode = 1; end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath = path; oldDirectory = pwd;
folder = tempname; mkdir(folder);
cleanup = onCleanup(@() cleanupEnvironment(oldDirectory,oldPath,folder));
addpath(genpath(root));
% Run an exact viewer copy so comparison caches remain inside the fixture.
copyfile(fullfile(root,'CellExplorer.m'),fullfile(folder,'CellExplorer.m'));
clear CellExplorer
setappdata(0,'ceViewerSmokeMetricsLabels',@metrics_labels);
setappdata(0,'ceViewerSmokeUiwait',@uiwait);
writeStub('uiwait',sprintf(['function uiwait(varargin)\n', ...
    'fig=varargin{1};\n', ...
    'if isgraphics(fig) && strcmp(fig.Name,''CellExplorer: ground truth data'')\n', ...
    'action=getappdata(0,''ceViewerSmokeGroundDialog'');\n', ...
    'table=findall(fig,''Type'',''uitable''); table.Data(:,1)={true};\n', ...
    'button=findall(fig,''Type'',''uicontrol'',''Style'',''pushbutton'',''String'',action); button.Callback(button,[]);\n', ...
    'if isgraphics(fig), delete(fig); end\n', ...
    'else, original=getappdata(0,''ceViewerSmokeUiwait''); original(varargin{:}); end\nend\n']));
writeStub('metrics_labels',sprintf(['function value=metrics_labels(varargin)\n', ...
    'if isequal(getappdata(0,''ceViewerSmokeReinitFailure''),true), error(''test:ReinitFailure'',''Injected preparation failure''); end\n', ...
    'original=getappdata(0,''ceViewerSmokeMetricsLabels''); value=original(varargin{:}); end\n']));
basename = ce.io.basenameFromBasepath(source);
sourceFile = fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
sourceHash = ce.pipeline.fileFingerprint(sourceFile);
file = fullfile(folder,[basename,'.reviewed.cellinfo.mat']);
copyfile(sourceFile,file);
fixture=load(file,'cell_metrics'); fixture.cell_metrics.tags.ceTableSmoke=[1 2 3];
fixture.cell_metrics.animal{1}=''; fixture.cell_metrics.labels{1}='label without animal';
save(file,'-struct','fixture');
writeStub('db_is_active','function value=db_is_active; value=true; end');
writeStub('db_load_settings','function value=db_load_settings; value=struct(); end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
    'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; value.metricsTable=%d; end\n'],tableMode));
writeStub('inputdlg','function value=inputdlg(varargin); value={''unsaved smoke label''}; end');
writeStub('questdlg','function value=questdlg(varargin); value=getappdata(0,''ceViewerSmokeAnswer''); end');
writeStub('warndlg','function value=warndlg(varargin); value=[]; end');
writeStub('uigetfile','function [file,folder]=uigetfile(varargin); item=getappdata(0,''ceViewerSmokeFile''); file=item{1}; folder=item{2}; end');
writeStub('gui_db_sessions','function [names,folders,mode]=gui_db_sessions(varargin); item=getappdata(0,''ceViewerSmokeBatch''); names=item{1}; folders=item{2}; mode=1; end');
addpath(folder); cd(folder); rehash;
setappdata(0,'ceViewerSmokeAnswer','Discard changes');
metrics = ce.ui.readMetricSelection(file);
completed = false; failure = []; started = tic; tablePhase = 0; navigationCell = [];
watch = timer('ExecutionMode','fixedSpacing','Period',1,'StartDelay',1,'TimerFcn',@exercise);
timerCleanup = onCleanup(@() stopTimer(watch)); start(watch);
returned = CellExplorer('metrics',metrics);
stopTimer(watch);
cleanupEnvironment(oldDirectory,oldPath,folder);
assert(completed,'Viewer closed before the callback smoke check ran.');
if ~isempty(failure), rethrow(failure); end
assert(numel(returned.UID)==302);
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary = struct('sessionCellCount',151,'batchCellCount',302,'initialTableMode',tableMode,'callbacksChecked',{{'tables','navigation','tag filters','reinitialization','comparisons','reload','file selection','database selection'}},'elapsedSeconds',toc(started));
disp(summary);

    function exercise(~,~)
        if completed, return; end
        figures = findall(0,'Type','figure');
        viewer = figures(startsWith(getNames(figures),'CellExplorer v'));
        if isempty(viewer) || ~strcmp(viewer(1).WaitStatus,'waiting')
            if toc(started)>90
                failure=MException('test:ViewerTimeout','Viewer did not become ready.'); completed=true; delete(figures);
            end
            return
        end
        try
            viewer=viewer(1);
            reload = callback(viewer,'Reload cell metrics');
            state = sessionState(reload);
            if tablePhase == 0
                assert(strcmp(state.cell_metrics.labels{1},'label without animal'));
                assert(isempty(state.UI.tables.grouptags),'Hidden tag table was constructed.');
                assert(numel(findall(viewer,'Type','uitable')) == double(tableMode~=3));
                navigationCell = exerciseTables(reload);
                tablePhase = 1; return
            elseif tablePhase == 1
                assert(state.ii == navigationCell,'Sorted row selected the wrong cell.');
                assert(isequal(state.UI.table.Data,ce.ui.metricTableData(state.cell_metrics,state.table_fieldsNames,state.ii)));
                % Navigate back through the sorted list before the reload tests.
                selectMenu(state.UI.menu.tableData.ops(2)); state=sessionState(reload);
                row=find(state.UI.params.subset(state.tableDataOrder)==1);
                state.UI.table.CellSelectionCallback(state.UI.table,struct('Indices',[row 2]));
                selectMenu(state.UI.menu.tableData.ops(1));
                tablePhase = 2; return
            end
            assert(state.ii == 1);
            if tablePhase == 2
                row=find(strcmp(state.UI.tables.grouptags.Data(:,1),'ceTableSmoke'));
                state.UI.tables.grouptags.CellEditCallback([],struct('Indices',[row 3],'NewData',true));
                tablePhase=3; return
            elseif tablePhase == 3
                assert(isequal(state.UI.params.subset,[1 2 3]));
                selectMenu(state.UI.menu.tableData.ops(2));
                assert(size(state.UI.table.Data,1)==3,'Cell list did not follow the tag filter.');
                row=find(strcmp(state.UI.tables.grouptags.Data(:,1),'ceTableSmoke'));
                state.UI.tables.grouptags.CellEditCallback([],struct('Indices',[row 3],'NewData',false));
                selectMenu(state.UI.menu.tableData.ops(1));
                tablePhase=4; return
            end
            assert(numel(state.UI.params.subset)==151);
            assert(isequal(state.UI.table.Data,ce.ui.metricTableData(state.cell_metrics,state.table_fieldsNames,1)));
            assign = callback(viewer,'Assign label');
            if tablePhase==4
                assign([],[]);
                exerciseComparisonEdits(reload,folder,basename,file);
                tablePhase=5; return % Let the main loop render both comparison overlays.
            end
            assert(strcmp(state.UI.preferences.referenceData,'Points'));
            assert(strcmp(state.UI.preferences.groundTruthData,'Points'));
            before = sessionState(reload);
            previousTitle = viewer.Name;
            previousSaveColor = before.UI.menu.file.save.ForegroundColor;
            previousTagData = before.UI.tables.grouptags.Data;
            previousMetricData = before.UI.table.Data;
            assert(strcmp(before.cell_metrics.labels{1},'unsaved smoke label'));
            assert(~isempty(before.classificationTrackChanges));
            % Missing files do not consume the dirty-state confirmation or edits.
            movefile(file,[file,'.hidden']); reload([],[]); assertUnchanged(before,sessionState(reload));
            movefile([file,'.hidden'],file);
            original = load(file,'cell_metrics'); cell_metrics = original.cell_metrics;
            % Fails late, after history/control updates, when the second plot
            % coordinate is accessed. Valid identity permits initialization.
            cell_metrics.general.tSNE_metrics.plot = zeros(151,1);
            cell_metrics.general.tSNE_metrics.preferences = before.UI.preferences.tSNE;
            cell_metrics.general.classificationTrackChanges = [];
            cell_metrics.labels{1} = 'disk replacement';
            save(file,'cell_metrics'); reload([],[]);
            after = sessionState(reload); assertUnchanged(before,after);
            assert(strcmp(viewer.Name,previousTitle));
            assert(isequal(after.UI.menu.file.save.ForegroundColor,previousSaveColor));
            assert(isequal(after.UI.tables.grouptags.Data,previousTagData));
            assert(isequal(after.UI.table.Data,previousMetricData));
            assert(isequal(after.UI.groupData1,before.UI.groupData1));
            assert(~contains(after.UI.popupmenu.log.String{end},'View restoration also failed'));
            cell_metrics = original.cell_metrics; save(file,'cell_metrics');
            % Declining discard leaves the original undo history intact.
            setappdata(0,'ceViewerSmokeAnswer','Cancel'); reload([],[]); assertUnchanged(before,sessionState(reload));
            % File picker errors and database-selection load errors share the guard.
            openFile = callback(viewer,'Load session from file');
            setappdata(0,'ceViewerSmokeFile',{'missing.mat',folder}); openFile([],[]);
            assertUnchanged(before,sessionState(reload));
            % The database menu name is discovered by its callback, not its text.
            menus = findall(viewer,'Type','uimenu'); dbCallback = [];
            for item = menus(:)'
                fun = item.MenuSelectedFcn;
                if isa(fun,'function_handle') && contains(func2str(fun),'DatabaseSessionDialog'), dbCallback=fun; break; end
            end
            assert(~isempty(dbCallback));
            setappdata(0,'ceViewerSmokeBatch',{{basename},{fullfile(folder,'missing')}});
            dbCallback([],[]); assertUnchanged(before,sessionState(reload));
            % A successful reload commits only after explicit discard.
            setappdata(0,'ceViewerSmokeAnswer','Discard changes'); reload([],[]);
            after = sessionState(reload);
            assert(isempty(after.classificationTrackChanges));
            assert(isequal(after.cell_metrics.labels,original.cell_metrics.labels));
            assert(strcmp(after.cell_metrics.general.saveAs,'reviewed'));
            % Successful file and session selection also use the guarded commit.
            cell_metrics = original.cell_metrics; cell_metrics.labels{1} = 'opened from file';
            alternateName = [basename,'.alternate.cellinfo.mat'];
            save(fullfile(folder,alternateName),'cell_metrics');
            setappdata(0,'ceViewerSmokeFile',{alternateName,folder}); openFile([],[]);
            after = sessionState(reload);
            assert(strcmp(after.cell_metrics.labels{1},'opened from file'));
            assert(strcmp(after.cell_metrics.general.saveAs,'alternate'));
            cell_metrics = original.cell_metrics;
            save(fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']),'cell_metrics');
            setappdata(0,'ceViewerSmokeBatch',{{basename,basename},{folder,folder}});
            dbCallback([],[]); after = sessionState(reload);
            assert(numel(after.cell_metrics.UID)==302 && after.UI.BatchMode);
            assert(isempty(after.classificationTrackChanges));
            assert(isequal(after.UI.table.Data,ce.ui.metricTableData(after.cell_metrics,after.table_fieldsNames,after.ii)));
            assert(~any([after.UI.tables.grouptags.Data{:,2:4}]));
            % Comparison datasets used as primary inputs share discard protection.
            for text={'Explore reference data','Explore groundTruth data'}
                explore=callback(viewer,text{1}); explore([],[]); after=sessionState(reload);
                assert(numel(after.cell_metrics.UID)==151);
                assert(isempty(after.classificationTrackChanges));
                assign([],[]);
            end
            dbCallback([],[]); after=sessionState(reload);
            assert(numel(after.cell_metrics.UID)==302);
            % Closing a real batch progress window must retain edits too.
            assign([],[]); beforeBatch = sessionState(reload);
            % Timer callbacks cannot interrupt another timer reliably. Wrap the
            % real waitbar factory and close its window just after construction.
            setappdata(0,'ceViewerSmokeWaitbar',@waitbar);
            writeStub('waitbar',sprintf(['function varargout=waitbar(varargin)\n', ...
                'original=getappdata(0,''ceViewerSmokeWaitbar'');\n', ...
                'if nargout==0, original(varargin{:}); else\n', ...
                '[varargout{1:nargout}]=original(varargin{:}); delete(varargout{1}); end\nend\n']));
            rehash;
            reload([],[]); assertUnchanged(beforeBatch,sessionState(reload));
            after = sessionState(reload);
            assert(contains(after.UI.popupmenu.log.String{end},'cancelled'));
            % Closed progress windows also cancel comparison selection safely.
            setappdata(0,'ceViewerSmokeBatch',{{basename},{folder}});
            selectReference=callback(viewer,'Open reference data dialog');
            beforeComparison=sessionState(reload); selectReference([],[]);
            assertComparisonUnchanged(beforeComparison,sessionState(reload));
            setappdata(0,'ceViewerSmokeGroundDialog','OK');
            selectGround=callback(viewer,'Open ground truth data dialog'); selectGround([],[]);
            assertComparisonUnchanged(beforeComparison,sessionState(reload));
            assert(strcmp(pwd,folder));
            completed=true; stop(watch); delete(findall(0,'Type','figure'));
        catch exception
            failure=exception; completed=true; stop(watch); delete(findall(0,'Type','figure'));
        end
    end
    function writeStub(name,body)
        fid=fopen(fullfile(folder,[name,'.m']),'w'); fprintf(fid,'%s\n',body); fclose(fid);
    end
end

function exerciseComparisonEdits(reload,folder,basename,metricsFile)
state=sessionState(reload); viewer=state.UI.fig;
reinitialize=callback(viewer,'Initialize cell metrics');
assign=callback(viewer,'Assign label');
state.UI.pushbutton.next.Callback([],[]); state=sessionState(reload);
selected=state.ii; oldLabel=state.cell_metrics.labels{selected}; assign([],[]);
before=sessionState(reload); savedColor=before.UI.menu.file.save.ForegroundColor;
reinitialize([],[]); after=sessionState(reload);
assertCurationUnchanged(before,after);
assert(isequal(after.UI.groupData1,before.UI.groupData1));
assert(isequal(after.UI.menu.file.save.ForegroundColor,savedColor));
assert(contains(after.UI.popupmenu.log.String{end},'complete'));
% Failure after candidate assignment and display preparation restores everything.
before=after; randomState=rng; setappdata(0,'ceViewerSmokeReinitFailure',true);
reinitialize([],[]); after=sessionState(reload);
setappdata(0,'ceViewerSmokeReinitFailure',false);
assertUnchanged(before,after); assert(isequal(rng,randomState));
assert(contains(after.UI.popupmenu.log.String{end},'Injected preparation failure'));
assert(~contains(after.UI.popupmenu.log.String{end},'View restoration also failed'));
undo=callback(viewer,'Undo classification'); undo([],[]); after=sessionState(reload);
assert(strcmp(after.cell_metrics.labels{selected},oldLabel),'Undo history lost during reinitialization.');
selectMenu(after.UI.menu.tableData.ops(2)); after=sessionState(reload);
row=find(after.UI.params.subset(after.tableDataOrder)==1);
after.UI.table.CellSelectionCallback([],struct('Indices',[row 2]));
selectMenu(after.UI.menu.tableData.ops(1));

referencePath=fullfile(folder,'+referenceData'); mkdir(referencePath);
groundPath=fullfile(folder,'+groundTruthData'); mkdir(groundPath);
referenceFile=fullfile(referencePath,'reference_cell_metrics.cellinfo.mat');
groundFile=fullfile(groundPath,'groundTruth_cell_metrics.cellinfo.mat');
stored=load(metricsFile,'cell_metrics'); cell_metrics=stored.cell_metrics;
save(fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']),'cell_metrics');
state=sessionState(reload); before=state;
% Cancelling the first reference selection does not activate an empty overlay.
setappdata(0,'ceViewerSmokeBatch',{{},{}});
selectMenu(state.UI.menu.referenceData.ops(3)); assertUnchanged(before,sessionState(reload));
after=sessionState(reload); assert(strcmp(after.UI.preferences.referenceData,'None'));
% Named-cache loading ignores unrelated MAT variables and rejects the wrong name.
UI='must not enter the viewer workspace'; save(referenceFile,'UI'); %#ok<NASGU>
selectMenu(state.UI.menu.referenceData.ops(3)); after=sessionState(reload);
assertUnchanged(before,after); assert(isempty(after.reference_cell_metrics));
assert(strcmp(after.UI.preferences.referenceData,'None'));
delete(referenceFile);
% Cache failure occurs after creation of a new tab; rollback removes the new tab.
mkdir(referenceFile);
setappdata(0,'ceViewerSmokeBatch',{{basename},{folder}});
selectReference=callback(viewer,'Open reference data dialog');
oldTabs=findall(viewer,'Type','uitab'); selectReference([],[]); after=sessionState(reload);
assertUnchanged(before,after); assert(isempty(after.reference_cell_metrics));
assert(isequal(findall(viewer,'Type','uitab'),oldTabs));
assert(~contains(after.UI.popupmenu.log.String{end},'View restoration also failed'));
rmdir(referenceFile);
selectReference([],[]); after=sessionState(reload);
assertUnchanged(before,after); assert(numel(after.reference_cell_metrics.UID)==151);
assert(isfile(referenceFile));
referenceHash=ce.pipeline.fileFingerprint(referenceFile);
selectMenu(after.UI.menu.referenceData.ops(3)); before=sessionState(reload);
assert(strcmp(before.UI.preferences.referenceData,'Points'));
referenceTab=before.UI.tabs.referenceData; referenceList=before.UI.listbox.referenceData.String;
% A malformed replacement reaches preparation but cannot overwrite the cache.
badName='bad_reference'; cell_metrics.waveforms.filt{1}=1:3;
save(fullfile(folder,[badName,'.cell_metrics.cellinfo.mat']),'cell_metrics');
setappdata(0,'ceViewerSmokeBatch',{{badName},{folder}}); selectReference([],[]);
after=sessionState(reload); assertComparisonUnchanged(before,after);
assert(isequal(after.UI.listbox.referenceData.String,referenceList));
assert(isequal(after.UI.tabs.referenceData,referenceTab));
assert(strcmp(ce.pipeline.fileFingerprint(referenceFile),referenceHash));
% A valid candidate plus an unwritable cache must also preserve the existing view.
movefile(referenceFile,[referenceFile,'.previous']); mkdir(referenceFile);
setappdata(0,'ceViewerSmokeBatch',{{basename},{folder}}); selectReference([],[]);
assertComparisonUnchanged(before,sessionState(reload));
rmdir(referenceFile); movefile([referenceFile,'.previous'],referenceFile);
assert(strcmp(ce.pipeline.fileFingerprint(referenceFile),referenceHash));
% Ground-truth caches use their own named variable and the same commit boundary.
groundTruth_cell_metrics=stored.cell_metrics;
groundTruth_cell_metrics.groundTruthClassification.PV=1:151;
if numel(fieldnames(groundTruth_cell_metrics.groundTruthClassification))>1
    groundTruth_cell_metrics.groundTruthClassification=struct('PV',1:151);
end
badGround=groundTruth_cell_metrics;
groundTruth_cell_metrics.waveforms.filt{1}=1:3; save(groundFile,'groundTruth_cell_metrics');
selectMenu(before.UI.menu.groundTruth.ops(3)); after=sessionState(reload);
assertComparisonUnchanged(before,after);
assert(strcmp(after.UI.preferences.groundTruthData,'None'));
groundTruth_cell_metrics=badGround;
groundTruth_cell_metrics.sessionName=repmat({basename},1,151);
for key={'animal_species','animal_geneticLine'}
    if ~isfield(groundTruth_cell_metrics,key{1}), groundTruth_cell_metrics.(key{1})=repmat({''},1,151); end
end
save(groundFile,'groundTruth_cell_metrics','UI');
selectMenu(after.UI.menu.groundTruth.ops(3)); after=sessionState(reload);
assertUnchanged(before,after); assert(numel(after.groundTruth_cell_metrics.UID)==151);
assert(strcmp(after.UI.preferences.groundTruthData,'Points'));
% Exercise the real ground-truth selection controls, including failed writes.
cell_metrics=groundTruth_cell_metrics;
groundSource=fullfile(groundPath,[basename,'.cell_metrics.cellinfo.mat']);
save(groundSource,'cell_metrics');
selectGround=callback(viewer,'Open ground truth data dialog');
setappdata(0,'ceViewerSmokeGroundDialog','Cancel');
before=after; selectGround([],[]); assertComparisonUnchanged(before,sessionState(reload));
setappdata(0,'ceViewerSmokeGroundDialog','OK');
movefile(groundFile,[groundFile,'.previous']); mkdir(groundFile);
selectGround([],[]); after=sessionState(reload); assertComparisonUnchanged(before,after);
assert(~contains(after.UI.popupmenu.log.String{end},'View restoration also failed'));
rmdir(groundFile); movefile([groundFile,'.previous'],groundFile);
groundHash=ce.pipeline.fileFingerprint(groundFile);
cell_metrics.waveforms.filt{1}=1:3; save(groundSource,'cell_metrics');
selectGround([],[]); assertComparisonUnchanged(before,sessionState(reload));
assert(strcmp(ce.pipeline.fileFingerprint(groundFile),groundHash));
cell_metrics=groundTruth_cell_metrics; save(groundSource,'cell_metrics');
selectGround([],[]); after=sessionState(reload);
assertUnchanged(before,after); assert(contains(after.UI.popupmenu.log.String{end},'complete'));
assert(numel(after.groundTruth_cell_metrics.UID)==151);
% Reinitialization keeps comparison modes/selections and dirty history as well.
before=after; reinitialize([],[]); after=sessionState(reload);
assertCurationUnchanged(before,after);
assert(strcmp(after.UI.preferences.referenceData,before.UI.preferences.referenceData));
assert(strcmp(after.UI.preferences.groundTruthData,before.UI.preferences.groundTruthData));
assert(isequal(after.referenceData.selection,before.referenceData.selection));
assert(isequal(after.groundTruthData.selection,before.groundTruthData.selection));
setappdata(0,'ceViewerSmokeAnswer','Cancel'); before=after;
for text={'Explore reference data','Explore groundTruth data'}
    explore=callback(viewer,text{1}); explore([],[]);
    assertComparisonUnchanged(before,sessionState(reload));
end
setappdata(0,'ceViewerSmokeAnswer','Discard changes');
end

function assertCurationUnchanged(before,after)
for key={'classificationTrackChanges','history_classification','clusClas','ii'}
    assert(isequaln(before.(key{1}),after.(key{1})),['Changed curation state: ',key{1}]);
end
for key={'labels','putativeCellType','brainRegion','deepSuperficial','tags','groups','groundTruthClassification'}
    assert(isequaln(before.cell_metrics.(key{1}),after.cell_metrics.(key{1})),['Changed annotation: ',key{1}]);
end
end

function assertComparisonUnchanged(before,after)
assertUnchanged(before,after);
for key={'reference_cell_metrics','groundTruth_cell_metrics','referenceData','groundTruthData', ...
        'fig2_axislimit_x_reference','fig2_axislimit_y_reference','fig2_axislimit_x_groundTruth','fig2_axislimit_y_groundTruth'}
    assert(isequaln(before.(key{1}),after.(key{1})),['Changed comparison state: ',key{1}]);
end
end

function navigationCell = exerciseTables(reload)
state=sessionState(reload);
selectMenu(state.UI.menu.tableData.ops(1)); state=sessionState(reload);
table=state.UI.table;
assert(isequal(table.Data,ce.ui.metricTableData(state.cell_metrics,state.table_fieldsNames,state.ii)));
selectMenu(state.UI.menu.tableData.ops(3)); assert(strcmp(table.Visible,'off'));
selectMenu(state.UI.menu.tableData.ops(2)); state=sessionState(reload);
assert(state.UI.table==table && size(table.Data,1)==numel(state.UI.params.subset));
% Preserve custom columns across mode changes, including their headings.
index=find(strcmp(state.UI.params.tableDataSortingList,'firingRate'));
selectMenu(state.UI.menu.tableData.column1_ops(index));
selectMenu(state.UI.menu.tableData.sortingList(index));
selectMenu(state.UI.menu.tableData.ops(1)); selectMenu(state.UI.menu.tableData.ops(2));
state=sessionState(reload);
assert(strcmp(table.ColumnName{3},'firingRate'));
[~,order]=sort(state.cell_metrics.firingRate(state.UI.params.subset),'descend');
assert(isequal(state.tableDataOrder,order));
row=find(state.UI.params.subset(order)~=1,1);
navigationCell=state.UI.params.subset(order(row));
table.CellEditCallback(table,struct('Indices',[row 1]));
state=sessionState(reload); assert(ismember(navigationCell,state.UI.params.ClickedCells));
table.CellEditCallback(table,struct('Indices',[row 1]));
% Opening Tags creates exactly one widget; revisiting restores active filters.
state.UI.panel.tabgroup2.SelectedTab=state.UI.tabs.dispTags;
state.UI.panel.tabgroup2.SelectionChangedFcn([],[]); state=sessionState(reload);
tagTable=state.UI.tables.grouptags;
assert(isgraphics(tagTable) && numel(findall(state.UI.fig,'Type','uitable'))==2);
for column=2:4
    tagTable.CellEditCallback(tagTable,struct('Indices',[1 column],'NewData',true));
end
state.UI.panel.tabgroup2.SelectedTab=state.UI.tabs.legends;
state.UI.panel.tabgroup2.SelectionChangedFcn([],[]);
state.UI.panel.tabgroup2.SelectedTab=state.UI.tabs.dispTags;
state.UI.panel.tabgroup2.SelectionChangedFcn([],[]); state=sessionState(reload);
assert(state.UI.tables.grouptags==tagTable && all([tagTable.Data{1,2:4}]));
% Keep highlighting active for the rollback test; clear filtering for navigation.
for column=3:4
    tagTable.CellEditCallback(tagTable,struct('Indices',[1 column],'NewData',false));
end
state.UI.panel.tabgroup2.SelectionChangedFcn([],[]);
table.CellSelectionCallback(table,struct('Indices',[row 2]));
selectMenu(state.UI.menu.tableData.ops(1));
end

function selectMenu(menu)
menu.MenuSelectedFcn(menu,[]);
end

function cleanupEnvironment(oldDirectory,oldPath,folder)
% Explicit cleanup also supports repeated runs in one MATLAB process.
% Callback workspace references can otherwise delay onCleanup destruction.
if ~isfolder(folder), return; end
cd(oldDirectory); path(oldPath);
clear waitbar questdlg warndlg inputdlg uigetfile gui_db_sessions db_is_active db_load_settings trackGoogleAnalytics setLayout_CellExplorer metrics_labels CellExplorer uiwait
for key={'ceViewerSmokeAnswer','ceViewerSmokeFile','ceViewerSmokeBatch','ceViewerSmokeWaitbar','ceViewerSmokeMetricsLabels','ceViewerSmokeReinitFailure','ceViewerSmokeUiwait','ceViewerSmokeGroundDialog'}
    if isappdata(0,key{1}), rmappdata(0,key{1}); end
end
if isfolder(folder), rmdir(folder,'s'); end
end

function names = getNames(figures)
names = arrayfun(@(item) item.Name,figures,'UniformOutput',false);
end

function fun = callback(viewer,text)
menus = findall(viewer,'Type','uimenu');
item = menus(strcmp(arrayfun(@(item) item.Text,menus,'UniformOutput',false),text));
assert(numel(item)==1,['Menu missing: ',text]); fun=item.MenuSelectedFcn;
end

function state = sessionState(callback)
details=functions(callback); state=[];
for item=details.workspace(:)'
    if isfield(item{1},'cell_metrics'), state=item{1}; return; end
end
error('test:MissingViewerState','Cannot inspect the callback workspace.');
end

function assertUnchanged(before,after)
for key={'cell_metrics','classificationTrackChanges','history_classification','clusClas','ii','tSNE_metrics'}
    assert(isequaln(before.(key{1}),after.(key{1})),['Changed viewer state: ',key{1}]);
end
end

function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end

