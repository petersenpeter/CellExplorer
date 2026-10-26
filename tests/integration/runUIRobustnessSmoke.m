function summary=runUIRobustnessSmoke(source,scenarios,captureFile)
%RUNUIROBUSTNESSSMOKE Opt-in GUI callbacks with copied tutorial metadata.
% Recording bytes and all writes are temporary. Does not run in the unit suite.
% A uiwait shim exercises callbacks after construction/plotting, without timers.
if nargin<2, scenarios=1:8; end
if nargin<3, captureFile=''; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath=path; oldDirectory=pwd; folder=tempname; mkdir(folder);
cleanup=onCleanup(@() finish(oldPath,oldDirectory,folder)); %#ok<NASGU>
addpath(genpath(root));
for name={'CellExplorer','NeuroScope2'}, copyfile(fullfile(root,[name{1},'.m']),fullfile(folder,[name{1},'.m'])); end
copyfile(fullfile(root,'calc_CellMetrics','gui_session.m'),fullfile(folder,'gui_session.m'));
writeStub('uiwait','function uiwait(varargin); drawnow; callback=getappdata(0,''ceUIRobustnessCallback''); callback([],[]); end');
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('msgbox','function value=msgbox(varargin); value=[]; end');
writeStub('warndlg','function value=warndlg(varargin); disp(varargin{1}); value=[]; end');
writeStub('uiputfile','function [file,folder]=uiputfile(varargin); file=0; folder=0; end');
addpath(folder); cd(folder); clear gui_session NeuroScope2 uiwait; rehash;
name=ce.io.basenameFromBasepath(source); sourceFile=fullfile(source,[name,'.session.mat']);
sourceHash=ce.pipeline.fileFingerprint(sourceFile); loaded=load(sourceFile,'session'); original=loaded.session;
warmup=figure('Visible','off'); drawnow; delete(warmup);
summary=struct; failure=[]; completed=false; phase=0;
for scenario=scenarios
    fprintf('Starting UI smoke scenario %d.\n',scenario);
    completed=false; phase=0;
    session=original; session.general.basePath=folder;
    if scenario<=3
        file=fullfile(folder,[name,'.session.mat']);
        if scenario==1, file=fullfile(folder,'edited-metadata.mat'); end
        ce.io.writeMat(file,struct('session',session));
        baseline=ce.pipeline.fileFingerprint(file);
    else
        session.general.name='synthetic'; session.general.duration=6;
        session.general.notes='Synthetic recording for UI validation';
        session.extracellular.sr=2000; session.extracellular.srLfp=1000;
        session.extracellular.nChannels=16; session.extracellular.nSamples=12000;
        session.extracellular.nElectrodeGroups=4; session.extracellular.nSpikeGroups=4;
        session.extracellular.electrodeGroups=struct('channels',{{1:4,5:8,9:12,13:16}});
        session.extracellular.spikeGroups=session.extracellular.electrodeGroups;
        session.extracellular.chanCoords=struct('x',repelem(0:3,4)*200,'y',repmat(0:3,1,4)*25);
        session.extracellular.leastSignificantBit=1; session.extracellular.fileName='synthetic.dat';
        session.extracellular.fileNameLFP='synthetic.lfp'; session.extracellular.precision='int32';
        session.brainRegions=struct(); session.channelTags=struct(); session.inputs=struct(); session.timeSeries=struct(); session.neuroScope2=struct();
        session.epochs={struct('name','synthetic','startTime',0,'stopTime',6)};
        if scenario==4, session.extracellular.precision='int16'; end
        n=12000; if scenario==7, n=40; elseif scenario==8, n=0; end
        samples=repmat(1:n,16,1);
        if scenario==9
            time=(1:n)/2000; samples=round(120*sin(2*pi*8*time+(0:15)')+30*cos(2*pi*120*time));
        end
        fid=fopen(fullfile(folder,'synthetic.dat'),'w'); fwrite(fid,samples,session.extracellular.precision); fclose(fid);
        fid=fopen(fullfile(folder,'synthetic.lfp'),'w'); fwrite(fid,samples(:,1:2:end),'int16'); fclose(fid);
        ce.io.writeMat(fullfile(folder,'synthetic.session.mat'),struct('session',session));
        sentinel=fopen(fullfile(folder,'unrelated-reader.txt'),'w');
    end
    setappdata(0,'ceUIRobustnessCallback',@exercise);
    try
        if scenario==1, [returned,~,status]=gui_session('edited-metadata.mat');
        elseif scenario<=3, [returned,~,status]=gui_session(session);
        else, NeuroScope2('basepath',folder,'basename','synthetic'); end
    catch exception
        failure=exception;
    end
    rmappdata(0,'ceUIRobustnessCallback');
    if ~isempty(failure), rethrow(failure); end
    assert(completed,'GUI test did not complete.');
    if scenario==1 || scenario==3
        assert(status==0 && isequaln(returned,session),'Cancel/close must restore input metadata.');
    elseif scenario==2
        assert(status==1 && strcmp(returned.general.notes,'apply without saving'));
        assert(strcmp(baseline,ce.pipeline.fileFingerprint(file)));
    else
        assert(strcmp(fopen(sentinel),fullfile(folder,'unrelated-reader.txt')),'Viewer closed an unrelated file.'); fclose(sentinel);
    end
    summary.(sprintf('scenario%d',scenario))=true;
    fprintf('Passed UI smoke scenario %d.\n',scenario);
end
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
summary.sourceUnchanged=true; disp(summary);

    function exercise(~,~)
        if completed, return; end
        figs=findall(0,'Type','figure'); fig=[];
        for candidate=figs(:)'
            if (scenario<=3 && startsWith(candidate.Name,'Session metadata')) || (scenario>3 && startsWith(candidate.Name,'NeuroScope2'))
                fig=candidate; break
            end
        end
        if isempty(fig), error('test:MissingFigure','The GUI reached its wait boundary without a figure.'); end
        try
            if scenario<=3
                s=state(findCallback(fig,'performStructValidation'));
                if scenario==1
                    s.UI.edit.sr.String='not-a-number'; s.UI.button.save.Callback([],[]);
                    assert(strcmp(baseline,ce.pipeline.fileFingerprint(file)));
                    s.UI.button.ok.Callback([],[]); assert(isgraphics(fig));
                    assert(strcmp(s.UI.edit.sr.String,'not-a-number'));
                    s.UI.edit.sr.String=num2str(session.extracellular.sr);
                    s.UI.edit.notes.String='saved by smoke test'; s.UI.button.save.Callback([],[]);
                    stored=load(file,'session'); assert(strcmp(stored.session.general.notes,'saved by smoke test'));
                    backups=dir(fullfile(folder,'revisions_session','*.mat')); assert(~isempty(backups));
                    assert(any(arrayfun(@(item) strcmp(baseline,ce.pipeline.fileFingerprint(fullfile(item.folder,item.name))),backups)));
                    % A second writer must be rejected, with typed edits retained.
                    changed=stored.session; changed.general.notes='external change'; ce.io.writeMat(file,struct('session',changed));
                    external=ce.pipeline.fileFingerprint(file);
                    s.UI.edit.notes.String='unsaved edit'; s.UI.button.save.Callback([],[]);
                    assert(strcmp(external,ce.pipeline.fileFingerprint(file)) && strcmp(s.UI.edit.notes.String,'unsaved edit'));
                    s.UI.button.cancel.Callback([],[]);
                elseif scenario==2
                    s.UI.edit.notes.String='apply without saving'; s.UI.button.ok.Callback([],[]); assert(~isgraphics(fig));
                else
                    % Cancel a destination picker, then close with the title-bar action.
                    s.UI.edit.basepath.String=fullfile(folder,'missing'); s.UI.button.save.Callback([],[]);
                    assert(strcmp(baseline,ce.pipeline.fileFingerprint(file)) && isgraphics(fig));
                    fig.CloseRequestFcn([],[]);
                end
                completed=true;
            else
                s=state(findCallback(fig,'loadFromFile'));
                if scenario==9
                    if phase==0
                        raw=s.ephys.raw; settings=s.UI.settings;
                        originalHeight=s.UI.panel.general.main1.MinimumHeights;
                        example=s.UI.traceSection.addField('extensionExample','Example setting','edit','String','5'); drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        assert(s.UI.panel.general.main1.MinimumHeights>originalHeight);
                        s.UI.traceSection.setRowVisible('extensionExample',false); drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        assert(strcmp(example.String,'5'));
                        s.UI.traceSection.setRowVisible('extensionExample',true);
                        s.UI.traceSection.setCollapsed(true); drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        assert(s.UI.panel.general.main1.MinimumHeights<originalHeight);
                        s.UI.traceSection.setCollapsed(false);
                        s.UI.traceSection.removeRow('extensionExample');
                        s.UI.grid_panels.Widths=[240 -1]; drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        s.UI.grid_panels.Widths=[330 -1]; drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        s.UI.panel.general.main1.VerticalOffsets=0; drawnow; s.UI.traceSectionListener.flush(); drawnow;
                        nav=getpixelposition(s.UI.panel.general.navigation,true);
                        pane=getpixelposition(s.UI.traceSection.Panel,true);
                        viewport=getpixelposition(s.UI.panel.general.main1,true);
                        assert(nav(2)+nav(4)<=viewport(2)+viewport(4)+2,'Navigation must remain inside the sidebar viewport.');
                        assert(pane(2)+pane(4)<=nav(2)+1,'Trace section must not overlap navigation.');
                        current=state(findCallback(fig,'loadFromFile'));
                        assert(isequaln(current.ephys.raw,raw) && isequaln(current.UI.settings,settings));
                        s.UI.panel.general.lowerBand.String='300';
                        s.UI.panel.general.lowerBand.Callback(s.UI.panel.general.lowerBand,[]);
                        phase=1; return
                    elseif phase==1
                        assert(s.ephys.loaded && s.UI.settings.filterTraces && s.UI.settings.filter.lowerBand==300);
                        s.UI.panel.general.filterToggle.Value=0;
                        s.UI.panel.general.filterToggle.Callback(s.UI.panel.general.filterToggle,[]);
                        s.UI.panel.general.plotStyle.Value=4;
                        s.UI.panel.general.plotStyle.Callback(s.UI.panel.general.plotStyle,[]);
                        phase=2; return
                    else
                        assert(s.ephys.loaded && ~s.UI.settings.filterTraces && s.UI.settings.plotStyle==4 && s.ephys.sr==1000);
                        s.UI.traceSectionListener.flush(); drawnow;
                        if ~isempty(captureFile), frame=getframe(fig); imwrite(frame.cdata,captureFile); end
                    end
                elseif scenario==8
                    assert(s.UI.t_total==0 && ~s.ephys.loaded && isempty(s.ephys.traces));
                elseif scenario==7
                    assert(abs(s.UI.t_total-.02)<eps && size(s.ephys.raw,1)==40 && s.ephys.raw(end,1)==40);
                    assert(isfinite(s.UI.elements.lower.slider.Value));
                elseif scenario==6 && phase==0
                    s.UI.panel.general.plotStyle.Value=4; s.UI.panel.general.plotStyle.Callback([],[]); phase=1; return
                elseif phase==0 || (scenario==6 && phase==1)
                    assert(s.UI.t_total==6,'Duration must use the active stream precision.');
                    forward=findall(fig,'Type','uicontrol','Style','pushbutton','String',char(8594));
                    forward=forward(contains(get(forward,'Tooltip'),'Forward in time'));
                    assert(numel(forward)==1); forward.Callback(forward,[]); phase=2; return
                else
                    expected=round(s.UI.t0*s.ephys.sr)+size(s.ephys.raw,1);
                    if scenario==6, expected=2*expected-1; end
                    assert(s.ephys.raw(end,1)==expected,'Navigation returned the wrong sample.');
                end
                completed=true; delete(fig);
            end
        catch exception
            failure=exception; completed=true; delete(figs(isgraphics(figs)));
        end
    end
    function writeStub(name,value)
        fid=fopen(fullfile(folder,[name,'.m']),'w'); c=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',value);
    end
end
function finish(oldPath,oldDirectory,folder)
cd(oldDirectory); path(oldPath); clear gui_session NeuroScope2 uiwait
delete(findall(0,'Type','figure'));
if isfolder(folder), rmdir(folder,'s'); end
end
function callback=findCallback(fig,name)
for item=findall(fig,'Type','uimenu')'
    fun=item.MenuSelectedFcn;
    if isa(fun,'function_handle')
        details=functions(fun); if contains(details.function,name), callback=fun; return; end
    end
end
error('test:MissingCallback','Missing %s',name);
end
function result=state(fun)
details=functions(fun);
for item=details.workspace(:)'
    if isfield(item{1},'UI'), result=item{1}; return; end
end
error('test:MissingState','Missing UI workspace');
end
