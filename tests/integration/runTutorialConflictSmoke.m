function summary=runTutorialConflictSmoke(source,batchMode)
%RUNTUTORIALCONFLICTSMOKE Exercise editing-window guards and reconciliation.
if nargin<2, batchMode=false; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; oldDirectory=pwd; folder=tempname; mkdir(folder);
cleanup=onCleanup(@() finish(oldPath,oldDirectory,folder));
addpath(genpath(root)); copyfile(fullfile(root,'CellExplorer.m'),fullfile(folder,'CellExplorer.m')); clear CellExplorer
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
 'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; value.metricsTable=1; end\n']));
writeStub('inputdlg','function value=inputdlg(varargin); value={''local conflict label''}; end');
writeStub('uiputfile','function [file,folder]=uiputfile(varargin); [folder,name,ext]=fileparts(getappdata(0,''ceConflictFile'')); file=[name,ext]; end');
writeStub('questdlg',sprintf(['function value=questdlg(varargin)\n', ...
 'switch varargin{2}\n', ...
 'case ''Reconcile changes from disk'', value=''Review changes'';\n', ...
 'case ''Save classification'', value=''Update altered sessions'';\n', ...
 'case ''Annotation conflict''\n', ...
 'value=getappdata(0,''ceConflictChoice'');\n', ...
 'if getappdata(0,''ceConflictMutate''), extra=17; save(getappdata(0,''ceConflictFile''),''extra'',''-append''); end\n', ...
 'otherwise, value=''Later''; end\nend\n']));
addpath(folder); cd(folder); rehash;
basename=ce.io.basenameFromBasepath(source); sourceFile=fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
sourceHash=ce.pipeline.fileFingerprint(sourceFile); loaded=load(sourceFile,'cell_metrics'); metrics=loaded.cell_metrics;
metrics.general.basepath=folder; metrics.general.saveAs='cell_metrics'; metrics.general.sortingRevision=repmat('a',1,64);
metrics.general.classificationTrackChanges=[]; metrics.labels{1}='original conflict label';
file=fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']); ce.io.saveCellMetrics(metrics,file);
input=ce.ui.readMetricSelection(file); otherFile=''; count=numel(metrics.UID);
if batchMode
    otherFolder=fullfile(folder,'other'); mkdir(otherFolder);
    other=metrics; other.general.basepath=otherFolder;
    otherFile=fullfile(otherFolder,[basename,'.cell_metrics.cellinfo.mat']); ce.io.saveCellMetrics(other,otherFile);
    input=ce.data.assembleMetricBatch({input,other},{folder,otherFolder},{basename,basename},'cell_metrics');
end
setappdata(0,'ceConflictFile',file); setappdata(0,'ceConflictChoice','Cancel'); setappdata(0,'ceConflictMutate',false);
completed=false; failure=[]; started=tic;
watch=timer('ExecutionMode','fixedSpacing','Period',1,'StartDelay',1,'TimerFcn',@exercise);
timerCleanup=onCleanup(@() stopTimer(watch)); start(watch);
CellExplorer('metrics',input); stopTimer(watch);
assert(completed,'Viewer conflict checks did not complete.');
if ~isempty(failure), rethrow(failure); end
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary=struct('cells',numel(input.UID),'saveConflict',true,'cancelPreservesEdits',true, ...
 'changedDuringChoicesRejected',true,'reconciliationAndUndo',true,'latestSciencePreserved',true, ...
 'sourceUnchanged',true,'elapsedSeconds',toc(started)); disp(summary);

    function exercise(~,~)
        if completed, return; end
        figures=findall(0,'Type','figure'); viewer=[];
        for f=figures(:)', if startsWith(f.Name,'CellExplorer v'), viewer=f; break; end, end
        if isempty(viewer) || ~strcmp(viewer.WaitStatus,'waiting')
            if toc(started)>150, failure=MException('test:ViewerTimeout','Viewer not ready.'); completed=true; delete(figures); end
            return
        end
        try
            reload=callback(viewer,'Reload cell metrics'); assign=callback(viewer,'Assign label'); assign([],[]);
            before=state(reload);
            disk=metrics; disk.labels{1}='external conflict label'; disk.labels{2}='external independent label';
            disk.firingRate=metrics.firingRate+10; ce.io.saveCellMetrics(disk,file);
            if batchMode
                other.labels{2}='other session external label'; other.firingRate=metrics.firingRate+20;
                ce.io.saveCellMetrics(other,otherFile);
            end
            hash=ce.pipeline.fileFingerprint(file); diskCopy=fullfile(folder,'disk-original.mat'); copyfile(file,diskCopy);
            saveCallback=callback(viewer,'Save'); saveCallback([],[]); assertEdits(before,state(reload));
            assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
            saveAs=callback(viewer,'Save As...'); saveAs([],[]); assertEdits(before,state(reload));
            assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
            reconcile=callback(viewer,'Reconcile changes from disk...'); reconcile([],[]);
            assertEdits(before,state(reload)); assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
            setappdata(0,'ceConflictChoice','Keep mine'); setappdata(0,'ceConflictMutate',true);
            reconcile([],[]); assertEdits(before,state(reload));
            copyfile(diskCopy,file,'f'); setappdata(0,'ceConflictMutate',false);
            reconcile([],[]); after=state(reload);
            assert(strcmp(after.cell_metrics.labels{1},'local conflict label'));
            assert(strcmp(after.cell_metrics.labels{2},'external independent label'));
            assert(isequaln(after.cell_metrics.firingRate(1:count),disk.firingRate));
            assert(~isempty(after.classificationTrackChanges));
            assert(strcmp(hash,ce.pipeline.fileFingerprint(file)),'Reconciliation must not save source files.');
            assert(strcmp(after.recoveryState(1).sourceHash,hash));
            undo=callback(viewer,'Undo classification'); undo([],[]); after=state(reload);
            assert(strcmp(after.cell_metrics.labels{1},'external conflict label'));
            assert(strcmp(after.cell_metrics.labels{2},'external independent label'));
            assert(isequaln(after.cell_metrics.firingRate(1:count),disk.firingRate));
            assign([],[]); saveCallback([],[]); after=state(reload);
            assert(isempty(after.classificationTrackChanges));
            if batchMode
                assert(strcmp(after.cell_metrics.labels{count+2},'other session external label'));
                assert(isequaln(after.cell_metrics.firingRate(count+1:end),other.firingRate));
                savedOther=ce.io.readCellMetrics(otherFile);
                assert(strcmp(savedOther.labels{2},'other session external label'));
                assert(isequaln(savedOther.firingRate,other.firingRate));
            end
            stored=ce.io.readCellMetrics(file);
            assert(strcmp(stored.labels{1},'local conflict label')); assert(strcmp(stored.labels{2},'external independent label'));
            assert(isequaln(stored.firingRate,disk.firingRate));
            assert(isempty(dir(fullfile(folder,'.cellexplorer','recovery','*.mat'))));
            completed=true; delete(viewer);
        catch exception
            failure=exception; completed=true; delete(figures(isgraphics(figures)));
        end
    end
    function writeStub(name,value)
        fid=fopen(fullfile(folder,[name,'.m']),'w'); c=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',value);
    end
end
function fun=callback(viewer,label)
menus=findall(viewer,'Type','uimenu'); names=arrayfun(@(x) x.Text,menus,'UniformOutput',false);
item=menus(strcmp(names,label)); assert(numel(item)==1,['Missing menu: ',label]); fun=item.MenuSelectedFcn;
end
function value=state(fun)
details=functions(fun);
for item=details.workspace(:)'
 if isfield(item{1},'cell_metrics'), value=item{1}; return; end
end
error('test:MissingState','Missing viewer state.');
end
function assertEdits(before,after)
for key={'classificationTrackChanges','history_classification','clusClas','ii'}
 assert(isequaln(before.(key{1}),after.(key{1})),['Changed state: ',key{1}]);
end
assert(isequaln(before.cell_metrics,after.cell_metrics));
for key={'sourceHash','baseline','diskBaseline'}
 assert(isequaln({before.recoveryState.(key{1})},{after.recoveryState.(key{1})}),['Changed baseline: ',key{1}]);
end
end
function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end
function finish(oldPath,oldDirectory,folder)
cd(oldDirectory); path(oldPath); clear CellExplorer
for key={'ceConflictFile','ceConflictChoice','ceConflictMutate'}
 if isappdata(0,key{1}), rmappdata(0,key{1}); end
end
if isfolder(folder), rmdir(folder,'s'); end
end
