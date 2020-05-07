function mono_res = gui_MonoSyn(mono_res_input,UID)
% Manual curating detected CCGs
% Limitation: can only deselect connections at this point. Click the CCG subplot to deselect a connection (turns pink)
%
% INPUT
% mono_res_input : full path to monosyn mat file or a matlab struct
%
% Example call
% mono_res = gui_MonoSyn('Z:\peterp03\IntanData\MS13\Peter_MS13_171130_121758_concat\Kilosort_2017-12-14_170737\Peter_MS13_171130_121758_concat.mono_res.cellinfo.mat')
% mono_res = gui_MonoSyn(mono_res)
% mono_res = gui_MonoSyn  - determines the mono_res file from the pwd

% Original function (bz_PlotMonoSyn) by: Sam, Gabrielle & ?
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 15-03-2019

if ~exist('mono_res_input','var')
    basepath = pwd;
    [~,basename,~] = fileparts(basepath);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        disp(['gui_MonoSyn: Loading ',basename,'.session.mat']);
        load(fullfile(basepath,[basename,'.session.mat']),'session');
        sessionIn = session;
        if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') && ~isempty(session.spikeSorting{1}.relativePath)
            clusteringpath = session.spikeSorting{1}.relativePath;
        else
            clusteringpath = '';
        end
        mono_res_input = fullfile(basepath,clusteringpath,[basename,'.mono_res.cellinfo.mat']);
        if exist(mono_res_input,'file')
            disp(['gui_MonoSyn: Loading mono_res file: ', mono_res_input])
            load(mono_res_input,'mono_res');
        else
            warning('gui_MonoSyn: Could not locage the mono_res file')
            return
        end
    end
elseif ischar(mono_res_input) && exist(mono_res_input,'file')
    disp('gui_MonoSyn: Loading mono_res file')
    load(mono_res_input,'mono_res');
elseif isstruct(mono_res_input)
    mono_res = mono_res_input;
end

disp('gui_MonoSyn: Loading GUI')
ccgR = mono_res.ccgR;
completeIndex = mono_res.completeIndex;
binSize = mono_res.binSize;
xLimit = false;
x_window = [-30 30];
xLimState = 1;

if ~isfield(mono_res,'sig_con_excitatory')
    mono_res.sig_con_excitatory = mono_res.sig_con;
end
if ~isfield(mono_res,'sig_con_excitatory_all')
    mono_res.sig_con_excitatory_all = [];
end
if ~isfield(mono_res,'sig_con_inhibitory')
    mono_res.sig_con_inhibitory = [];
end
if ~isfield(mono_res,'sig_con_inhibitory_all')
    mono_res.sig_con_inhibitory_all = [];
end

if ~isempty(mono_res.sig_con_excitatory) || ~isempty(mono_res.sig_con_excitatory_all)
    connectionsDisplayed = 1;
    sig_con = mono_res.sig_con_excitatory;
elseif ~isempty(mono_res.sig_con_inhibitory) || ~isempty(mono_res.sig_con_inhibitory_all)
    connectionsDisplayed = 2;
    sig_con = mono_res.sig_con_inhibitory;
else
    connectionsDisplayed = 1;
    sig_con = mono_res.sig_con;
end
if isempty(sig_con)
    warning('No connections detected')
    return
end
keep_con = sig_con;
allcel = unique(sig_con(:));
window  =false(size(ccgR,1),1);
window(ceil(length(window)/2) - round(.004/binSize): ceil(length(window)/2) + round(.004/binSize)) = true;
halfBins = round(mono_res.duration/binSize/2);
t = 1000*(-halfBins:halfBins)'*binSize;

UI.fig = figure('KeyReleaseFcn', {@keyPress},'Name','MonoSynCon inspector','NumberTitle','off','renderer','opengl');
% p = uipanel(UI.fig,'Position',[0 0 1 .1],'BorderType','none')
% p2 = uipanel(UI.fig,'Position',[0 0 0.01 0.01],'BorderType','none')
UI.leftbutton = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[5 410 20 10],'Units','normalized','String','<','Callback',@(src,evnt)goBack,'KeyPressFcn', {@keyPress});
UI.rightbutton = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[540 410 20 10],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});
plotTitle = uicontrol('Parent',UI.fig,'Style','text','Position',[130 410 350 10],'Units','normalized','String','','HorizontalAlignment','center','FontSize',13);
UI.switchConnectionType = uicontrol('Parent',UI.fig,'Style','popupmenu','Position',[30 408 80 10],'Units','normalized','String',{'Excitatory connections','Inhibitory connections'},'Value',connectionsDisplayed,'Callback',@(src,evnt)switchConnectionType,'KeyPressFcn', {@keyPress});
displayAllConnections = uicontrol('Parent',UI.fig,'Style','checkbox','Position',[115 410 100 10],'Units','normalized','String','Show all detected connections','HorizontalAlignment','right','Callback',@(src,evnt)switchConnectionType,'KeyPressFcn', {@keyPress});
% align([UI.leftbutton UI.rightbutton UI.switchConnectionType displayAllConnections],'Top','Bottom');
if ~verLessThan('matlab', '9.4')
    set(UI.fig,'WindowState','maximize','visible','on'), drawnow nocallbacks;
else
    set(UI.fig,'visible','on')
    drawnow nocallbacks; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks;
end
if exist('UID','var') && any(UID == allcel)
    i = find(UID == allcel);
else
    i = 1;
end
temp444 = 1;
while temp444 == 1
    if i < 1
        i = 1;
    end
    if i > length(allcel)
        i = length(allcel);
    end
    if ~ishandle(UI.fig)
        saveOnExitDialog
        return
    end
    delete(findobj(UI.fig, 'type', 'axes'));
    
    prs = sig_con(any(sig_con==allcel(i),2),:);
    [plotRows,~]= numSubplots(max(2+size(prs,1),4));
    ha = tight_subplot(plotRows(1),plotRows(2),[.03 .03],[.05 .05],[.02 .015]); %  tight_subplot(Nh, Nw, gap, marg_h, marg_w)
    
    prs2 = [];
    for j=1:length(ha)
        set(UI.fig,'CurrentAxes',ha(j)), hold on
        targ=completeIndex(completeIndex(:,3) == allcel(i),1:2);
        targ_UID=completeIndex(completeIndex(:,3) == allcel(i),3);
        plotTitle.String = ['Reference Cell: ' num2str(targ_UID) ', group: '  num2str(targ(1)),', cluID: ',num2str(targ(2)),' (', num2str(i),'/' num2str(length(allcel)),')'];
        if j<=size(prs,1)
            prs1 = prs(j,:);
            if prs1(1)~=allcel(i)
                dirArrow = [num2str(prs1(1)),' <- ', num2str(prs1(2))];
                prs1 = fliplr(prs1);
            else
                dirArrow = [num2str(prs1(1)),' -> ', num2str(prs1(2))];
            end
            prs2(j,:) = prs1;
            exc=ccgR(:,prs1(1),prs1(2));
            exc(exc<mono_res.Bounds(:,prs1(1),prs1(2),1)|~window)=0;
            exc(ceil(length(exc)/2)) = 0;
            
            inh=ccgR(:,prs1(1),prs1(2));
            inh(inh>mono_res.Bounds(:,prs1(1),prs1(2),2)|~window)=0;
            inh(ceil(length(inh)/2)) = 0;
            
            bar_from_patch(t,ccgR(:,prs1(1),prs1(2)),[0. 0. 0.8],0)
            hold on;
            
            % Plot predicted values
            % plot(t,mono_res.Pred(:,prs1(1),prs1(2)),'g', 'HitTest','off');
            
            %Plot upper and lower boundaries
            plot(t,mono_res.Bounds(:,prs1(1),prs1(2),1),'r--', 'HitTest','off','linewidth',1.5);
            plot(t,mono_res.Bounds(:,prs1(1),prs1(2),2),'r--', 'HitTest','off','linewidth',1.5);
            
            % Plot signif increased bins in red
            if connectionsDisplayed == 1
                bar_from_patch(t,exc,[0.8 0. 0.],0)
            end
            
            % Plot signif lower bins in blue
            if connectionsDisplayed == 2
                bar_from_patch(t,inh,[0. 0.8 0.8],0)
            end
            if xLimit
                xlim(x_window)
                idx = t > x_window(1) & t < x_window(2);
            else
                xlim([min(t) max(t)]);
            end
            
            tcel = setdiff(prs(j,:),allcel(i,:));
            targ=completeIndex(completeIndex(:,3)==tcel,1:2);
            targ_UID=completeIndex(completeIndex(:,3)==tcel,3);
            if connectionsDisplayed == 2
                ylim([0,2*quantile(mono_res.Pred(:,prs1(1),prs1(2)),0.9)])
            end
            temp = ylim;
            
            % the bad ones are shown in pink
            if  ~ismember(prs(j,:),keep_con,'rows')
                set(ha(j),'Color',[1 .75 .75])
            end
            
            set(ha(j),'UserData',j,'ButtonDownFcn',@subplotclick);
            
            % Plot an inset with the ACG
            axhpos = ylim;
            axhpos2 = xlim;
            if xLimit
                thisacg = ccgR(idx,tcel,tcel);
                thisacg = thisacg./max(thisacg)*axhpos(2)*0.2+axhpos(2)*0.78;
                t2 = (16/60)*axhpos2(2)*t(idx)./max(t(idx))+axhpos2(2)*(43/60);
            else
                thisacg = ccgR(:,tcel,tcel);
                thisacg = thisacg./max(thisacg)*axhpos(2)*0.2+axhpos(2)*0.78;
                t2 = (16/60)*axhpos2(2)*t./max(t)+axhpos2(2)*(43/60);
            end
            
            rectangle('Position',[min(t2),min(axhpos(2)*0.8,min(thisacg)),max(t2)-min(t2),axhpos(2)*0.2],'FaceColor','w','EdgeColor','w', 'HitTest','off')
            bar_from_patch(t2,thisacg,[.5 .5 .5],min(axhpos(2)*0.8,min(thisacg)))
            rectangle('Position',[min(t2),min(axhpos(2)*0.8,min(thisacg)),(max(t2)-min(t2))+mean(diff(t2)),axhpos(2)*0.2], 'HitTest','off')
            upL = get(gca,'ylim');
            plot([0 0],[0 upL(2)],'k', 'HitTest','off')
            if xLimit
                text(min(t(idx)) +.03*abs(min(t(idx))),temp(2)*0.97,['Cell: ' num2str(targ_UID) ', group: '  num2str(targ(1)),' | ',dirArrow])
            else
                text(min(t) +.03*abs(min(t)),temp(2)*0.97,['Cell: ' num2str(targ_UID) ', group: '  num2str(targ(1)),' | ',dirArrow])
            end
        elseif j<length(ha)-1
            axis off
        elseif j<length(ha)
            zdata = ccgR(:,:,allcel(i))';
            imagesc(flip(t),1:size(ccgR,3),(zdata'./max(zdata'))'), hold on, axis tight
            if xLimit
                xlim(x_window)
                idx = t > x_window(1) & t < x_window(2);
            else
                xlim([min(t) max(t)]);
            end
            axhpos3 = xlim;
            plot(1.01*axhpos3(1)*ones(size(prs2,1),1),prs2(:,2),'.m', 'HitTest','off', 'MarkerSize',12)
            plot(1.01*axhpos3(1)*ones(size(prs2,1),1),prs2(:,1),'.k', 'HitTest','off', 'MarkerSize',12)
            xlim([1.02*axhpos3(1),axhpos3(2)])
            plot([0;0],[0;1]*size(zdata,1),'m', 'HitTest','off')
%             xlabel('CCGs (black marker: reference cell)')
            ha(j).XLabel.String = 'CCGs (black marker: reference cell)';
        else
            bar_from_patch(t,ccgR(:,allcel(i),allcel(i)),'k',0)
            if xLimit
                xlim(x_window)
            else
                xlim([min(t) max(t)]);
            end
%             xlabel('Reference Cell ACG');
            ha(j).XLabel.String = 'Reference Cell ACG';
            uiwait(UI.fig);
        end
    end
end

if ishandle(UI.fig)
    close(UI.fig)
end
saveOnExitDialog

    function saveOnExitDialog
        if connectionsDisplayed == 1
            mono_res.sig_con = keep_con;
            mono_res.sig_con_excitatory = keep_con;
        else
            mono_res.sig_con_inhibitory = keep_con;
        end
        if ischar(mono_res_input)
            disp('Saving mono_res file')
            answer = questdlg('Do you want to save the manual monosynaptic curration?', 'Save monosynaptic curration', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                try
                    save(mono_res_input,'mono_res','-v7.3','-nocompression');
                catch
                    warndlg('Failed to save the mono_res file.')
                end
            end
        end
    end

    function subplotclick(obj,~)
        % when an axes is clicked
        figobj = get(obj,'Parent');
        axdata = get(obj,'UserData');
        switch get(UI.fig, 'selectiontype')
            case 'normal'
                clr2 = get(obj,'Color');
                if sum(clr2 == [1 1 1])==3%if white (ie synapse), set to pink (bad), remember as bad
                    set(obj,'Color',[1 .75 .75])
                    keep_con(ismember(keep_con,prs(axdata,:),'rows'),:)=[];
                elseif sum(clr2 == [1 .75 .75])==3%if pink, set to white, set to good
                    set(obj,'Color',[1 1 1])
                    keep_con = [keep_con;prs(axdata,:)];
                end
            case 'alt'
                %                 set(obj,'Color',[1 0.65 0])
                if prs(axdata,2)==allcel(i)
                    i = find(allcel == prs(axdata,1));
                else
                    i = find(allcel == prs(axdata,2));
                end
                uiresume(UI.fig);
                % case 'extend'
                % polygonSelection
        end
    end

    function numericSelect(subplotNum) %when an axes is clicked
        if subplotNum<length(ha)-1
            obj = ha(subplotNum);
            axdata = get(obj,'UserData');
            clr2 = get(obj,'Color');
            if sum(clr2 == [1 1 1])==3 %if white (ie synapse), set to pink (bad), remember as bad
                set(obj,'Color',[1 .75 .75])
                keep_con(ismember(keep_con,prs(axdata,:),'rows'),:)=[];
            elseif sum(clr2 == [1 .75 .75])==3%if pink, set to white, set to good
                set(obj,'Color',[1 1 1])
                keep_con = [keep_con;prs(axdata,:)];
            end
        end
    end

    function goBack
        ii = i;
        i = max(i-1,1);
        if ii ~= i
            uiresume(UI.fig);
        end
    end

    function advance
        if i==length(allcel)
            answer = questdlg('All cells have been currated. Do you want to quit?', 'Monosyn curration complete', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                if ishandle(UI.fig)
                    close(UI.fig)
                end
            end
        else
            i = i+1;
            uiresume(UI.fig);
        end
    end

    function advance10
        ii = i;
        i = min(i+10,length(allcel));
        if ii ~= i
            uiresume(UI.fig);
        end
    end

    function goBack10
        ii = i;
        i = max(i-10,1);
        if ii ~= i
            uiresume(UI.fig);
        end
    end

    function keyPress(~,event)
        switch event.Key
            case 'space'
                goToCell
            case 'rightarrow'
                advance
            case 'leftarrow'
                goBack
            case {'1','2','3','4','5','6','7','8','9'}
                numericSelect(str2num(event.Key));
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                numericSelect(str2num(event.Key(end)))
            case {'0','numpad0'}
                i=1;
                uiresume(UI.fig);
            case 'uparrow'
                advance10
            case 'downarrow'
                goBack10
            case 'h'
                HelpDialog;
            case 'x'
                changeXlim
            case 'w'
                web('https://petersenpeter.github.io/CellExplorer/tutorials/monosynaptic-connections-tutorial/','-new','-browser')
        end
    end
    function changeXlim
        if xLimState == 1
            xLimState = 2;
            xLimit = true;
            x_window = [-30 30];
        elseif xLimState == 2
            xLimState = 3;
            x_window = [-15 15];
            xLimit = true;
        elseif xLimState == 3
            xLimState = 1;
            xLimit = false;
        end
        uiresume(UI.fig);
    end

    function goToCell
        GoTo_dialog = dialog('Position', [-300, -300, 300, 150],'Name','Go to connection'); movegui(GoTo_dialog,'center')
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the pair number and press enter', 'Position', [10, 125, 280, 20],'HorizontalAlignment','center');
        connectionDialogInput = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 100, 280, 25],'Callback',@(src,evnt)UpdateSelectedCell,'HorizontalAlignment','center');
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the UID and press enter', 'Position', [10, 75, 280, 20],'HorizontalAlignment','center');
        connectionDialogInput2 = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 50, 280, 25],'Callback',@(src,evnt)UpdateSelectedCell2,'HorizontalAlignment','center');
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
        uicontrol(connectionDialogInput)
        uiwait(GoTo_dialog);
        function UpdateSelectedCell
            answer = str2double(connectionDialogInput.String);
            if ~isempty(answer) && answer > 0 && answer <= length(allcel)
                delete(GoTo_dialog);
                i = answer;
                uiresume(UI.fig);
            end
        end
        function UpdateSelectedCell2
            answer = str2double(connectionDialogInput2.String);
            if ~isempty(answer) && any(answer == allcel)
                delete(GoTo_dialog);
                i = find(allcel ==answer);
                uiresume(UI.fig);
            end
        end
        function  CancelGoTo_dialog
            delete(GoTo_dialog);
        end
    end

    function switchConnectionType(~,~)
        currentCell = allcel(i);
        if connectionsDisplayed == 1
            mono_res.sig_con = keep_con;
            mono_res.sig_con_excitatory = keep_con;
        else
            mono_res.sig_con_inhibitory = keep_con;
        end
        connectionsDisplayed = UI.switchConnectionType.Value;
        if connectionsDisplayed == 1 && displayAllConnections.Value == 0
            sig_con = mono_res.sig_con_excitatory;
            keep_con = sig_con;
            allcel = unique(sig_con(:));
            disp('Excitatory connections')
        elseif connectionsDisplayed == 1 && displayAllConnections.Value == 1
            keep_con = mono_res.sig_con_excitatory;
            if ~isempty(mono_res.sig_con_excitatory_all)
                sig_con = mono_res.sig_con_excitatory_all;
                allcel = unique(mono_res.sig_con_excitatory_all(:));
            else
                sig_con = keep_con;
            end
            allcel = unique(sig_con(:));
            disp('Excitatory connections (all)')
        elseif connectionsDisplayed == 2 && displayAllConnections.Value == 0 && ~isempty(mono_res.sig_con_inhibitory)
            
            sig_con = mono_res.sig_con_inhibitory;
            keep_con = sig_con;
            allcel = unique(sig_con(:));
            disp('Inhibitory connections')
        elseif connectionsDisplayed == 2 && displayAllConnections.Value == 1 && ~isempty(mono_res.sig_con_inhibitory)
            keep_con = mono_res.sig_con_inhibitory;
            if ~isempty(mono_res.sig_con_excitatory_all)
                sig_con = mono_res.sig_con_inhibitory_all;
            else
                sig_con = keep_con;
            end
            allcel = unique(sig_con(:));
            disp('Inhibitory connections (all)')
        else
            connectionsDisplayed = 1;
            UI.switchConnectionType.Value = connectionsDisplayed;
            warndlg('No inhibitory connections detected');
            return
        end
        if any(currentCell == allcel)
            i = find(currentCell == allcel);
        end
        uiresume(UI.fig);
    end
end

function bar_from_patch(x_data, y_data,col,y0)
% Creates a bar graph using the patch plot mode, which is substantial faster than using the regular bar plot.
% By Peter Petersen

x_step = x_data(2)-x_data(1);
x_data = [x_data(1),reshape([x_data,x_data+x_step]',1,[]),x_data(end)+x_step];
y_data = [y0,reshape([y_data,y_data]',1,[]),y0];
patch(x_data, y_data,col,'EdgeColor',col, 'HitTest','off')
end

function [p,n]=numSubplots(n)
% Calculate how many rows and columns of sub-plots are needed to neatly display n subplots.
% Rob Campbell - January 2010

while isprime(n) && n>4
    n=n+1;
end
p=factor(n);
if length(p)==1
    p=[1,p];
    return
end
while length(p)>2
    if length(p)>=4
        p(1)=p(1)*p(end-1);
        p(2)=p(2)*p(end);
        p(end-1:end)=[];
    else
        p(1)=p(1)*p(2);
        p(2)=[];
    end
    p=sort(p);
end

% Reformat if the column/row ratio is too large: we want a roughly square design
while p(2)/p(1)>2.5
    N=n+1;
    [p,n]=numSubplots(N); %Recursive!
end
end

function HelpDialog(~,~)
opts.Interpreter = 'tex'; opts.WindowStyle = 'normal';
msgbox({'\bfMouse interaction\rm','Left click on CCG subplots: accep/reject connection (turns red)','Right click on CCG subplots: switch to select cell','','\bfNavigation\rm','right-arrow : Next cell', 'left arrow : Previous cell','up-arrow : 10 cells forward','down-arrow : 10 cells backward',...
    'space : Go to a specific cell','Numpad0 : Go to first cell','','\bfConnection assigment\rm', '1-9 : Toggle cell with that subplot number', ...
    'Numpad1-9 : Toggle cell with that subplot number','','\bfVisualization\rm','x : change x-limits (60, 30 or 15 ms)','','\bfw: Visit the CellExplorer''s website for further help\rm',''},'Help','help',opts);
end
