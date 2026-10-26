function summary=runTutorialViewerSaveSmoke(source)
%RUNTUTORIALVIEWERSAVESMOKE Real save/restore callbacks using temporary copies.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; oldDirectory=pwd; folder=tempname; mkdir(folder);
cleanup=onCleanup(@() finish(oldPath,oldDirectory,folder));
addpath(genpath(root)); copyfile(fullfile(root,'CellExplorer.m'),fullfile(folder,'CellExplorer.m')); clear CellExplorer
setappdata(0,'ceSaveSmokeWait',@uiwait);
writeStub('uiwait',sprintf(['function uiwait(fig,varargin)\n', ...
 'if strcmp(fig.Name,''Select backup to restore'')\n', ...
 'list=findall(fig,''Style'',''listbox''); list.Value=find(strcmp(list.String,getappdata(0,''ceSaveSmokeBackup'')));\n', ...
 'button=findall(fig,''Style'',''pushbutton'',''String'',''OK''); button.Callback(button,[]);\n', ...
 'else, original=getappdata(0,''ceSaveSmokeWait''); original(fig,varargin{:}); end\nend\n']));
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
 'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; value.metricsTable=1; end\n']));
writeStub('inputdlg','function value=inputdlg(varargin); value={''unsaved smoke label''}; end');
writeStub('questdlg','function value=questdlg(varargin); value=getappdata(0,''ceSaveSmokeAnswer''); end');
writeStub('uiputfile','function [file,folder]=uiputfile(varargin); item=getappdata(0,''ceSaveSmokeFile''); file=item{1}; folder=item{2}; end');
writeStub('uigetfile','function [file,folder]=uigetfile(varargin); item=getappdata(0,''ceSaveSmokeFile''); file=item{1}; folder=item{2}; end');
addpath(folder); cd(folder); rehash;
basename=ce.io.basenameFromBasepath(source);
sourceFile=fullfile(source,[basename,'.cell_metrics.cellinfo.mat']); sourceHash=ce.pipeline.fileFingerprint(sourceFile);
loaded=load(sourceFile,'cell_metrics'); cell_metrics=loaded.cell_metrics;
cell_metrics.general.sortingRevision=repmat('a',1,64);
cell_metrics.labels{1}='first original'; cell_metrics.labels{2}='second original';
file=fullfile(folder,[basename,'.reviewed.cellinfo.mat']); save(file,'cell_metrics');
metrics=ce.ui.readMetricSelection(file); original=metrics;
originalBytes=fullfile(folder,'original.mat'); copyfile(file,originalBytes);
completed=false; failure=[]; phase=0; started=tic;
watch=timer('ExecutionMode','fixedSpacing','Period',1,'StartDelay',1,'TimerFcn',@exercise);
timerCleanup=onCleanup(@() stopTimer(watch)); start(watch);
CellExplorer('metrics',metrics); stopTimer(watch);
assert(completed,'Viewer save smoke did not complete.');
if ~isempty(failure), rethrow(failure); end
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary=struct('sessionCells',151,'batchCells',302,'saveAndRestoreChecked',true,'sourceUnchanged',true,'elapsedSeconds',toc(started));
disp(summary);

    function exercise(~,~)
        if completed, return; end
        figures=findall(0,'Type','figure'); viewer=[];
        for f=figures(:)'
            if startsWith(f.Name,'CellExplorer v'), viewer=f; break; end
        end
        if isempty(viewer) || ~strcmp(viewer.WaitStatus,'waiting')
            if toc(started)>120, failure=MException('test:ViewerTimeout','Viewer did not become ready.'); completed=true; delete(figures); end
            return
        end
        try
            reload=callback(viewer,'Reload cell metrics');
            if phase==0
                assign=callback(viewer,'Assign label'); assign([],[]); before=state(reload);
                assert(~isempty(before.classificationTrackChanges));
                changed=original; changed.general.sortingRevision=repmat('b',1,64); ce.io.saveCellMetrics(changed,file);
                hash=ce.pipeline.fileFingerprint(file);
                saveCallback=callback(viewer,'Save'); saveCallback([],[]);
                assertEdits(before,state(reload)); assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
                assert(~isfolder(fullfile(folder,'revisions_cell_metrics')));
                setappdata(0,'ceSaveSmokeFile',{[basename,'.reviewed.cellinfo.mat'],folder});
                saveAs=callback(viewer,'Save As...'); saveAs([],[]);
                assertEdits(before,state(reload)); assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
                setappdata(0,'ceSaveSmokeFile',{'export.mat',folder}); saveAs([],[]);
                assertEdits(before,state(reload)); exported=load(fullfile(folder,'export.mat'),'cell_metrics');
                assert(strcmp(exported.cell_metrics.labels{1},'unsaved smoke label'));
                copyfile(originalBytes,file,'f');
                fid=fopen(fullfile(folder,'revisions_cell_metrics'),'w'); fclose(fid);
                hash=ce.pipeline.fileFingerprint(file); saveCallback([],[]);
                assertEdits(before,state(reload)); assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
                delete(fullfile(folder,'revisions_cell_metrics'));
                saveCallback([],[]); after=state(reload); assert(isempty(after.classificationTrackChanges));
                stored=load(file,'cell_metrics'); assert(isempty(stored.cell_metrics.general.classificationTrackChanges));
                backups=dir(fullfile(folder,'revisions_cell_metrics','reviewed_*.mat')); assert(numel(backups)==1);
                assert(strcmp(hash,ce.pipeline.fileFingerprint(fullfile(backups(1).folder,backups(1).name))));
                invalid=ce.curation.captureAnnotations(original); invalid.general.sortingRevision=repmat('b',1,64);
                invalidFile=fullfile(folder,'revisions_cell_metrics','reviewed_invalid.mat'); ce.io.writeMat(invalidFile,struct('cell_metrics',invalid));
                setappdata(0,'ceSaveSmokeBackup','reviewed_invalid.mat'); restore=callback(viewer,'Restore from backup');
                before=state(reload); files=dir(fullfile(folder,'revisions_cell_metrics')); restore([],[]);
                assertEdits(before,state(reload)); assert(isequal(files,dir(fullfile(folder,'revisions_cell_metrics'))));
                setappdata(0,'ceSaveSmokeBackup',backups(1).name); restore([],[]);
                after=state(reload); assert(isequal(after.cell_metrics.labels,original.labels));
                assert(~isempty(after.classificationTrackChanges));
                undo=callback(viewer,'Undo classification'); undo([],[]);
                after=state(reload); assert(isequal(after.cell_metrics.labels,before.cell_metrics.labels));
                otherFolder=fullfile(folder,'other'); mkdir(otherFolder);
                one=original; two=original; one.general.classificationTrackChanges=[]; two.general.classificationTrackChanges=[];
                ce.io.saveCellMetrics(one,file); otherFile=fullfile(otherFolder,[basename,'.reviewed.cellinfo.mat']); ce.io.saveCellMetrics(two,otherFile);
                batch=ce.data.assembleMetricBatch({one,two},{folder,otherFolder},{basename,basename},'reviewed');
                batch.general.classificationTrackChanges=[1 152]; batch.labels{1}='first batch edit'; batch.labels{152}='second batch edit';
                ce.io.saveCellMetrics(batch,fullfile(folder,'batch.mat'));
                setappdata(0,'ceSaveSmokeFile',{'batch.mat',folder}); setappdata(0,'ceSaveSmokeAnswer','Discard changes');
                loadCallback=callback(viewer,'Load session from file'); loadCallback([],[]);
                phase=1; return
            end
            before=state(reload); assert(before.UI.BatchMode); assert(isequal(before.classificationTrackChanges,[1 152]));
            otherFile=fullfile(folder,'other',[basename,'.reviewed.cellinfo.mat']);
            changed=original; changed.general.sortingRevision=repmat('b',1,64); ce.io.saveCellMetrics(changed,otherFile);
            hash=ce.pipeline.fileFingerprint(otherFile);
            setappdata(0,'ceSaveSmokeAnswer','Update altered sessions'); saveCallback=callback(viewer,'Save'); saveCallback([],[]);
            after=state(reload); assert(isequal(after.classificationTrackChanges,152));
            assert(strcmp(hash,ce.pipeline.fileFingerprint(otherFile)));
            stored=load(file,'cell_metrics'); assert(strcmp(stored.cell_metrics.labels{1},'first batch edit'));
            completed=true; delete(viewer);
        catch exception
            failure=exception; completed=true; delete(figures(isgraphics(figures)));
        end
    end

    function writeStub(name,text)
        fid=fopen(fullfile(folder,[name,'.m']),'w'); fileCleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',text);
    end
end

function fun=callback(viewer,label)
menus=findall(viewer,'Type','uimenu'); names=arrayfun(@(x) x.Text,menus,'UniformOutput',false);
item=menus(strcmp(names,label)); assert(numel(item)==1,['Missing menu: ',label]); fun=item.MenuSelectedFcn;
end

function value=state(fun)
details=functions(fun); value=[];
for item=details.workspace(:)'
    if isfield(item{1},'cell_metrics')
        value=item{1}; value.saveColor=value.UI.menu.file.save.ForegroundColor; return
    end
end
error('test:MissingViewerState','Cannot inspect viewer workspace.');
end

function assertEdits(before,after)
for key={'classificationTrackChanges','history_classification','clusClas','ii'}
    assert(isequaln(before.(key{1}),after.(key{1})),['Changed state: ',key{1}]);
end
assert(isequal(before.cell_metrics.labels,after.cell_metrics.labels));
assert(isequal(before.saveColor,after.saveColor));
end

function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end

function finish(oldPath,oldDirectory,folder)
cd(oldDirectory); path(oldPath); clear CellExplorer
for key={'ceSaveSmokeWait','ceSaveSmokeBackup','ceSaveSmokeAnswer','ceSaveSmokeFile'}
    if isappdata(0,key{1}), rmappdata(0,key{1}); end
end
if isfolder(folder), rmdir(folder,'s'); end
end
