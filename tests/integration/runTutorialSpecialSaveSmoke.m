function summary=runTutorialSpecialSaveSmoke(source)
%RUNTUTORIALSPECIALSAVESMOKE Exercise specialized viewer callbacks on copies.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; oldDirectory=pwd; folder=tempname; mkdir(folder);
cleanup=onCleanup(@() finish(oldPath,oldDirectory,folder));
addpath(genpath(root)); copyfile(fullfile(root,'CellExplorer.m'),fullfile(folder,'CellExplorer.m')); clear CellExplorer
setappdata(0,'ceSpecialWait',@uiwait);
writeStub('uiwait',sprintf(['function uiwait(fig,varargin)\n', ...
 'if strcmp(fig.Name,''Ground truth cell types'')\n', ...
 'list=findall(fig,''Style'',''listbox''); list.Value=find(startsWith(string(list.String),''Smoke''));\n', ...
 'action=getappdata(0,''ceSpecialDialog''); button=findall(fig,''Style'',''pushbutton'',''String'',action); button.Callback(button,[]);\n', ...
 'else, original=getappdata(0,''ceSpecialWait''); original(fig,varargin{:}); end\nend\n']));
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
 'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; value.metricsTable=1; value.groundTruth={''SmokeA'',''SmokeB''}; end\n']));
writeStub('inputdlg','function value=inputdlg(varargin); value={''unsaved specialized-save label''}; end');
writeStub('questdlg','function value=questdlg(varargin); value=''Yes''; end');
writeStub('warndlg','function value=warndlg(varargin); value=[]; end');
writeStub('gui_MonoSyn',sprintf(['function mono=gui_MonoSyn(mono,position)\n', ...
 'setappdata(0,''ceSpecialPosition'',position);\n', ...
 'mono.sig_con=[1 3]; mono.sig_con_excitatory=[1 3]; mono.sig_con_inhibitory=zeros(0,2);\n', ...
 'file=getappdata(0,''ceSpecialMutate''); if ~isempty(file), extra=17; save(file,''extra'',''-append''); end\nend\n']));
addpath(folder); cd(folder); rehash;
basename=ce.io.basenameFromBasepath(source); sourceFile=fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
sourceHash=ce.pipeline.fileFingerprint(sourceFile);
loaded=load(sourceFile,'cell_metrics'); metrics=loaded.cell_metrics; count=numel(metrics.UID);
metrics.UID=1000+(1:count); metrics.general.sortingRevision=repmat('a',1,64);
metrics.general.basepath=folder; metrics.general.saveAs='cell_metrics';
metrics.groundTruthClassification=struct('SmokeA',[1 2],'SmokeB',[2 3]);
metrics.putativeConnections=struct('excitatory',[1 2;1 3],'inhibitory',[3 1]);
metrics=ce.curation.projectMonoSynReview(metrics,struct('excitatory',[1 2;1 3],'inhibitory',[3 1]));
file=fullfile(folder,[basename,'.cell_metrics.cellinfo.mat']); ce.io.saveCellMetrics(metrics,file);
originalCopy=fullfile(folder,'original.mat'); copyfile(file,originalCopy);
mono=struct('ccgR',zeros(3,count,count),'n',ones(1,count),'Pred',[],'Bounds',[], ...
 'completeIndex',[metrics.shankID(:),metrics.cluID(:),(1:count)'],'binSize',.0004, ...
 'duration',.120,'conv_w',25,'Pcausal',nan(count),'sig_con',[1 2;1 3], ...
 'sig_con_excitatory',[1 2;1 3],'sig_con_inhibitory',[3 1], ...
 'sig_con_excitatory_all',[1 2;1 3],'sig_con_inhibitory_all',[3 1]);
mono.processinginfo.cellIdentity=struct('UID',metrics.UID,'cluID',metrics.cluID,'shankID',metrics.shankID,'sortingRevision',metrics.general.sortingRevision);
monoFile=fullfile(folder,[basename,'.mono_res.cellinfo.mat']); ce.io.writeMat(monoFile,struct('mono_res',mono));
completed=false; failure=[]; started=tic;
watch=timer('ExecutionMode','fixedSpacing','Period',1,'StartDelay',1,'TimerFcn',@exercise);
timerCleanup=onCleanup(@() stopTimer(watch)); start(watch);
CellExplorer('metrics',metrics); stopTimer(watch);
assert(completed,'Viewer did not complete specialized save checks.');
if ~isempty(failure), rethrow(failure); end
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary=struct('cells',count,'groundTruthExport',true,'monosynapticSave',true,'pendingReviewPreserved',true,'sourceUnchanged',true,'elapsedSeconds',toc(started)); disp(summary);

    function exercise(~,~)
        if completed, return; end
        figures=findall(0,'Type','figure'); viewer=[];
        for f=figures(:)', if startsWith(f.Name,'CellExplorer v'), viewer=f; break; end, end
        if isempty(viewer) || ~strcmp(viewer.WaitStatus,'waiting')
            if toc(started)>120, failure=MException('test:ViewerTimeout','Viewer not ready.'); completed=true; delete(figures); end
            return
        end
        try
            reload=callback(viewer,'Reload cell metrics'); assign=callback(viewer,'Assign label'); assign([],[]);
            before=state(reload);
            export=callback(viewer,'Save tagging to groundTruthData folder');
            setappdata(0,'ceSpecialDialog','OK'); export([],[]);
            target=fullfile(folder,'+groundTruthData',[basename,'.cell_metrics.cellinfo.mat']);
            stored=load(target,'cell_metrics'); assert(isequal(stored.cell_metrics.UID,metrics.UID(1:3)));
            assert(isequal(stored.cell_metrics.groundTruthClassification.SmokeB,[2 3]));
            hash=ce.pipeline.fileFingerprint(target);
            setappdata(0,'ceSpecialDialog','Cancel'); export([],[]); assert(strcmp(hash,ce.pipeline.fileFingerprint(target)));
            stored.cell_metrics.general.sortingRevision=repmat('b',1,64); ce.io.writeMat(target,stored); hash=ce.pipeline.fileFingerprint(target);
            setappdata(0,'ceSpecialDialog','OK'); export([],[]); assert(strcmp(hash,ce.pipeline.fileFingerprint(target)));
            assertEdits(before,state(reload));
            adjust=callback(viewer,'Adjust monosynaptic connections'); oldMono=ce.pipeline.fileFingerprint(monoFile);
            % Simulate another writer while the review window is open.
            setappdata(0,'ceSpecialMutate',file); adjust([],[]); after=state(reload);
            assert(isfield(after.UI.monoSyn,'pendingReview')); assertEdits(before,after);
            assert(strcmp(oldMono,ce.pipeline.fileFingerprint(monoFile)));
            assert(getappdata(0,'ceSpecialPosition')==1,'GUI must receive local position, not UID 1001.');
            % The Yes stub is not Discard review: stale retry keeps the draft.
            externalHash=ce.pipeline.fileFingerprint(file); adjust([],[]);
            assert(strcmp(externalHash,ce.pipeline.fileFingerprint(file)));
            after=state(reload); assert(isfield(after.UI.monoSyn,'pendingReview'));
            copyfile(originalCopy,file,'f'); setappdata(0,'ceSpecialMutate','');
            fid=fopen(fullfile(folder,'revisions_mono_res'),'w'); fclose(fid);
            adjust([],[]); after=state(reload); assert(isfield(after.UI.monoSyn,'pendingReview')); assertEdits(before,after);
            assert(strcmp(oldMono,ce.pipeline.fileFingerprint(monoFile)));
            delete(fullfile(folder,'revisions_mono_res')); adjust([],[]); after=state(reload);
            assert(~isfield(after.UI.monoSyn,'pendingReview')); assertEdits(before,after);
            assert(isequal(after.cell_metrics.putativeConnections.excitatory,[1 3]));
            assert(isempty(after.cell_metrics.putativeConnections.inhibitory)); assert(isempty(after.UI.cells.inhibitory));
            stored=load(file,'cell_metrics'); assert(isequal(stored.cell_metrics.synapticEffect,after.cell_metrics.synapticEffect));
            assert(isequal(stored.cell_metrics.labels,metrics.labels),'Pending labels must not be persisted by a connection save.');
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
 if isfield(item{1},'cell_metrics'), value=item{1}; value.saveColor=value.UI.menu.file.save.ForegroundColor; return; end
end
error('test:MissingState','Missing viewer state.');
end
function assertEdits(before,after)
for key={'classificationTrackChanges','history_classification','clusClas','ii','saveColor'}
 assert(isequaln(before.(key{1}),after.(key{1})),['Changed state: ',key{1}]);
end
assert(isequal(before.cell_metrics.labels,after.cell_metrics.labels));
end
function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end
function finish(oldPath,oldDirectory,folder)
cd(oldDirectory); path(oldPath); clear CellExplorer
for key={'ceSpecialWait','ceSpecialDialog','ceSpecialPosition','ceSpecialMutate'}
 if isappdata(0,key{1}), rmappdata(0,key{1}); end
end
if isfolder(folder), rmdir(folder,'s'); end
end
