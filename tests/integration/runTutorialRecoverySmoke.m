function summary=runTutorialRecoverySmoke(source)
%RUNTUTORIALRECOVERYSMOKE Close/reopen the viewer using temporary tutorial copies.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; oldDirectory=pwd; folder=tempname; mkdir(folder);
cleanup=onCleanup(@() finish(oldPath,oldDirectory,folder));
addpath(genpath(root)); copyfile(fullfile(root,'CellExplorer.m'),fullfile(folder,'CellExplorer.m')); clear CellExplorer
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
 'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; value.metricsTable=1; end\n']));
writeStub('inputdlg','function value=inputdlg(varargin); value={''recovered smoke label''}; end');
writeStub('questdlg',sprintf(['function value=questdlg(varargin)\n', ...
 'if strcmp(varargin{2},''Recover unsaved changes'')\n', ...
 'setappdata(0,''ceRecoveryPrompts'',getappdata(0,''ceRecoveryPrompts'')+1); value=getappdata(0,''ceRecoveryAnswer'');\n', ...
 'else, value=getappdata(0,''ceRecoverySaveAnswer''); end\nend\n']));
writeStub('gui_MonoSyn',sprintf(['function mono=gui_MonoSyn(mono,varargin)\n', ...
 'mono.sig_con=[1 3]; mono.sig_con_excitatory=[1 3]; mono.sig_con_inhibitory=zeros(0,2); end\n']));
addpath(folder); cd(folder); rehash;
basename=ce.io.basenameFromBasepath(source); sourceFile=fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
sourceHash=ce.pipeline.fileFingerprint(sourceFile);
loaded=load(sourceFile,'cell_metrics'); metrics=loaded.cell_metrics; count=numel(metrics.UID);
metrics.general.sortingRevision=repmat('a',1,64); metrics.general.basepath=folder;
metrics.general.saveAs='cell_metrics'; metrics.general.classificationTrackChanges=[];
metrics.labels{1}='original recovery label';
metrics=ce.curation.projectMonoSynReview(metrics,struct('excitatory',[1 2;1 3],'inhibitory',[3 1]));
file=fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']); ce.io.saveCellMetrics(metrics,file);
mono=struct('ccgR',zeros(3,count,count),'n',ones(1,count),'Pred',[],'Bounds',[], ...
 'completeIndex',[metrics.shankID(:),metrics.cluID(:),(1:count)'],'binSize',.0004, ...
 'duration',.120,'conv_w',25,'Pcausal',nan(count),'sig_con',[1 2;1 3], ...
 'sig_con_excitatory',[1 2;1 3],'sig_con_inhibitory',[3 1], ...
 'sig_con_excitatory_all',[1 2;1 3],'sig_con_inhibitory_all',[3 1]);
mono.processinginfo.cellIdentity=struct('UID',metrics.UID,'cluID',metrics.cluID,'shankID',metrics.shankID,'sortingRevision',metrics.general.sortingRevision);
monoFile=fullfile(folder,[basename,'.mono_res.cellinfo.mat']); ce.io.writeMat(monoFile,struct('mono_res',mono));
originalMetricsHash=ce.pipeline.fileFingerprint(file); originalMonoHash=ce.pipeline.fileFingerprint(monoFile);
completed=false; failure=[]; step=0; started=tic; journalFile=''; journalHash='';
for phase=1:5
    completed=false; step=0;
    setappdata(0,'ceRecoveryPrompts',0); setappdata(0,'ceRecoverySaveAnswer','No');
    if ismember(phase,[3 4]), setappdata(0,'ceRecoveryAnswer','Recover'); else, setappdata(0,'ceRecoveryAnswer','Later'); end
    watch=timer('ExecutionMode','fixedSpacing','Period',1,'StartDelay',1,'TimerFcn',@exercise);
    timerCleanup=onCleanup(@() stopTimer(watch)); start(watch);
    CellExplorer('metrics',ce.ui.readMetricSelection(file)); stopTimer(watch);
    assert(completed,'Recovery viewer checks did not complete.');
    if ~isempty(failure), rethrow(failure); end
    if phase<=2
        assert(strcmp(originalMetricsHash,ce.pipeline.fileFingerprint(file)));
        assert(strcmp(originalMonoHash,ce.pipeline.fileFingerprint(monoFile)));
        drafts=dir(fullfile(folder,'.cellexplorer','recovery','*.mat')); assert(numel(drafts)==1);
        if phase==1
            journalFile=fullfile(drafts(1).folder,drafts(1).name); journalHash=ce.pipeline.fileFingerprint(journalFile);
        else
            assert(strcmp(journalHash,ce.pipeline.fileFingerprint(journalFile)),'Later must leave the draft unchanged.');
        end
    elseif phase==3
        assert(numel(dir(fullfile(folder,'.cellexplorer','recovery','*.mat')))==1);
    else
        assert(isempty(dir(fullfile(folder,'.cellexplorer','recovery','*.mat'))));
    end
end
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary=struct('cells',count,'closeReopenRecovery',true,'laterPreservesDraft',true, ...
 'undo',true,'pendingReviewRetry',true,'annotationSaveBeforeReview',true, ...
 'saveRetiresDrafts',true,'sourceUnchanged',true,'elapsedSeconds',toc(started)); disp(summary);

    function exercise(~,~)
        if completed, return; end
        figures=findall(0,'Type','figure'); viewer=[];
        for f=figures(:)', if startsWith(f.Name,'CellExplorer v'), viewer=f; break; end, end
        if isempty(viewer) || ~strcmp(viewer.WaitStatus,'waiting')
            if toc(started)>180, failure=MException('test:ViewerTimeout','Viewer not ready.'); completed=true; delete(figures); end
            return
        end
        try
            reload=callback(viewer,'Reload cell metrics'); current=state(reload);
            switch phase
                case 1
                    if step==0
                        assign=callback(viewer,'Assign label'); assign([],[]);
                        step=1; return
                    elseif step==1
                        assert(isfile(current.recoveryState.file),'Completed annotation callbacks must be journaled before closing.');
                        stored=load(current.recoveryState.file,'recovery');
                        assert(strcmp(stored.recovery.annotations.labels{1},'recovered smoke label'));
                        adjust=callback(viewer,'Adjust monosynaptic connections'); adjust([],[]);
                        current=state(reload); assert(isfield(current.UI.monoSyn,'pendingReview'));
                        assert(isfile(current.recoveryState.file),'A returned review must immediately be journaled.');
                        discard=callback(viewer,'Discard pending connection review');
                        setappdata(0,'ceRecoverySaveAnswer','Keep review'); discard([],[]);
                        current=state(reload); assert(isfield(current.UI.monoSyn,'pendingReview'));
                        setappdata(0,'ceRecoverySaveAnswer','Discard review'); discard([],[]);
                        current=state(reload); assert(~isfield(current.UI.monoSyn,'pendingReview'));
                        assert(strcmp(current.cell_metrics.labels{1},'recovered smoke label'));
                        assert(strcmp(current.recoveryState.sourceHash,originalMetricsHash));
                        setappdata(0,'ceRecoverySaveAnswer','No'); adjust([],[]);
                        step=2; return
                    end
                    stored=load(current.recoveryState.file,'recovery');
                    assert(strcmp(stored.recovery.annotations.labels{1},'recovered smoke label'));
                    assert(isequal(stored.recovery.dirtyUIDs,metrics.UID(1)));
                case 2
                    assert(getappdata(0,'ceRecoveryPrompts')==1);
                    assert(strcmp(current.cell_metrics.labels{1},metrics.labels{1}));
                    assert(isempty(current.classificationTrackChanges));
                    assert(~isfield(current.UI.monoSyn,'pendingReview'));
                case 3
                    assert(getappdata(0,'ceRecoveryPrompts')==1);
                    assert(strcmp(current.cell_metrics.labels{1},'recovered smoke label'));
                    assert(isequal(current.classificationTrackChanges,1));
                    assert(isfield(current.UI.monoSyn,'pendingReview'));
                    assert(isequal(current.UI.monoSyn.pendingReview.review.sig_con,[1 3]));
                    assert(strcmp(originalMetricsHash,ce.pipeline.fileFingerprint(file)));
                    assert(strcmp(originalMonoHash,ce.pipeline.fileFingerprint(monoFile)));
                    undo=callback(viewer,'Undo classification'); undo([],[]); current=state(reload);
                    assert(strcmp(current.cell_metrics.labels{1},metrics.labels{1}));
                    assign=callback(viewer,'Assign label'); assign([],[]);
                    saveCallback=callback(viewer,'Save'); saveCallback([],[]); current=state(reload);
                    assert(isempty(current.classificationTrackChanges));
                    assert(isfield(current.UI.monoSyn,'pendingReview'));
                    assert(~isfile(journalFile));
                case 4
                    assert(getappdata(0,'ceRecoveryPrompts')==1);
                    assert(strcmp(current.cell_metrics.labels{1},'recovered smoke label'));
                    assert(isempty(current.classificationTrackChanges));
                    assert(isfield(current.UI.monoSyn,'pendingReview'));
                    assert(isequal(current.UI.monoSyn.pendingReview.review.sig_con,[1 3]));
                    setappdata(0,'ceRecoverySaveAnswer','Yes');
                    adjust=callback(viewer,'Adjust monosynaptic connections'); adjust([],[]); current=state(reload);
                    assert(~isfield(current.UI.monoSyn,'pendingReview'));
                    assert(strcmp(current.cell_metrics.labels{1},'recovered smoke label'));
                    assert(isempty(current.classificationTrackChanges));
                    assert(~isfile(journalFile));
                case 5
                    assert(getappdata(0,'ceRecoveryPrompts')==0);
                    assert(strcmp(current.cell_metrics.labels{1},'recovered smoke label'));
                    assert(isequal(current.cell_metrics.putativeConnections.excitatory,[1 3]));
                    assert(isempty(current.cell_metrics.putativeConnections.inhibitory));
                    assert(isempty(current.classificationTrackChanges));
            end
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
function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end
function finish(oldPath,oldDirectory,folder)
cd(oldDirectory); path(oldPath); clear CellExplorer
for key={'ceRecoveryPrompts','ceRecoveryAnswer','ceRecoverySaveAnswer'}
 if isappdata(0,key{1}), rmappdata(0,key{1}); end
end
if isfolder(folder), rmdir(folder,'s'); end
end
