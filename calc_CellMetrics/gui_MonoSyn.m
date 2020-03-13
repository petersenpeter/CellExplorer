function mono_res = gui_MonoSyn(mono_res_in,UID)
% Manual curating detected CCGs
% Limitation: can only deselect connections at this point. Click the CCG subplot to deselect a connection (turns pink)
% 
% INPUT
% mono_res_in : full path to monosyn mat file or a matlab struct
% 
% Example call
% mono_res = gui_MonoSyn('Z:\peterp03\IntanData\MS13\Peter_MS13_171130_121758_concat\Kilosort_2017-12-14_170737\Peter_MS13_171130_121758_concat.mono_res.cellinfo.mat')
% mono_res = gui_MonoSyn(mono_res)

% Original function (bz_PlotMonoSyn) by: Sam, Gabrielle & ?
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-03-2019

if ischar(mono_res_in) && exist(mono_res_in,'file')
    disp('gui_MonoSyn: Loading mono_res file')
    load(mono_res_in);
elseif isstruct(mono_res_in)
    mono_res = mono_res_in;
else
    warning('gui_MonoSyn: Please provide a valid path or a struct to process')
    return
end

disp('gui_MonoSyn: Loading GUI')
ccgR = mono_res.ccgR;
% sig_con = mono_res.sig_con;
Pred = mono_res.Pred;
completeIndex = mono_res.completeIndex;
binSize = mono_res.binSize;
duration = mono_res.duration;

if isfield(mono_res_in,'sig_con_excitatory') && ~isempty(mono_res_in.sig_con_excitatory)
    sig_con_excitatory = mono_res_in.sig_con_excitatory;
elseif isfield(mono_res_in,'sig_con') && ~isempty(mono_res_in.sig_con)
    sig_con_excitatory = mono_res_in.sig_con;
else
    sig_con_excitatory = [];
end

if isfield(mono_res_in,'sig_con_inhibitory') && ~isempty(mono_res_in.sig_con_inhibitory)
    sig_con_inhibitory = mono_res_in.sig_con_inhibitory;
end

connectionsDisplayed = 1;
sig_con = sig_con_excitatory;
keep_con = sig_con;
allcel = unique(sig_con(:));

window  =false(size(ccgR,1),1);
window(ceil(length(window)/2) - round(.004/binSize): ceil(length(window)/2) + round(.004/binSize)) = true;
halfBins = round(duration/binSize/2);
t = 1000*(-halfBins:halfBins)'*binSize;

%%%%%%%%%%%%%%%%%%%%%%%%%%

h = figure('KeyReleaseFcn', {@keyPress},'Name','MonoSynCon inspector','NumberTitle','off','renderer','opengl');
% p = uipanel(h,'Position',[0 0 1 .1],'BorderType','none')
% p2 = uipanel(h,'Position',[0 0 0.01 0.01],'BorderType','none')
uicontrol('Parent',h,'Style','pushbutton','Position',[5 410 20 10],'Units','normalized','String','<','Callback',@(src,evnt)goBack,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[540 410 20 10],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});
plotTitle = uicontrol('Parent',h,'Style','text','Position',[130 410 350 10],'Units','normalized','String','','HorizontalAlignment','center','FontSize',13);
UI.switchConnectionType = uicontrol('Parent',h,'Style','popupmenu','Position',[30 408 80 10],'Units','normalized','String',{'Excitatory connections','Inhibitory connections'},'Value',1,'Callback',@(src,evnt)switchConnectionType,'KeyPressFcn', {@keyPress});
displayAllConnections = uicontrol('Parent',h,'Style','checkbox','Position',[120 410 100 10],'Units','normalized','String','Show all detected connections','HorizontalAlignment','right','Callback',@(src,evnt)switchConnectionType,'KeyPressFcn', {@keyPress});

if ~verLessThan('matlab', '9.4')
    set(h,'WindowState','maximize','visible','on'), drawnow nocallbacks; 
else
    set(h,'visible','on')
    drawnow nocallbacks; frame_h = get(h,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks; 
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
    if ~ishandle(h)
        if connectionsDisplayed == 1
            mono_res.sig_con = keep_con;
            mono_res.sig_con_excitatory = keep_con;
        else
            mono_res.sig_con_inhibitory = keep_con;
        end
        if ischar(mono_res_in)
            disp('Saving mono_res file')
            save(mono_res_in,'mono_res','-v7.3','-nocompression');
        end
        return
    end
    delete(findobj(h, 'type', 'axes'));
    
    prs = sig_con(any(sig_con==allcel(i),2),:);
    [plotRows,~]= numSubplots(max(2+size(prs,1),4));
    ha = tight_subplot(plotRows(1),plotRows(2),[.03 .03],[.05 .05],[.03 .03]);
    
    prs2 = [];
    for j=1:length(ha)
        axes(ha(j))
        if j<=size(prs,1)
            prs1 = prs(j,:);
            if prs1(1)~=allcel(i)
                prs1 = fliplr(prs1);
            end
            prs2(j,:) = prs1;
            exc=ccgR(:,prs1(1),prs1(2));
            exc(exc<mono_res.Bounds(:,prs1(1),prs1(2),1)|~window)=0;
            exc(ceil(length(exc)/2)) = 0;
            
            inh=ccgR(:,prs1(1),prs1(2));
            inh(inh>mono_res.Bounds(:,prs1(1),prs1(2),2)|~window)=0;
            inh(ceil(length(inh)/2)) = 0;
            bar_from_patch(t,ccgR(:,prs1(1),prs1(2)),'b',0)
            hold on;
            
            % Plot predicted values
            plot(t,Pred(:,prs1(1),prs1(2)),'g', 'HitTest','off');
            
            %Plot upper and lower boundaries
            plot(t,mono_res.Bounds(:,prs1(1),prs1(2),1),'r--', 'HitTest','off');
            plot(t,mono_res.Bounds(:,prs1(1),prs1(2),2),'r--', 'HitTest','off');
            
            % Plot signif increased bins in red
            if connectionsDisplayed == 1
                bar_from_patch(t,exc,'r',0)
            end
            
            % Plot signif lower bins in blue
            if connectionsDisplayed == 2
                bar_from_patch(t,inh,'c',0)
            end
            xlim([min(t) max(t)]);

            tcel = setdiff(prs(j,:),allcel(i,:));
            targ=completeIndex(completeIndex(:,3)==tcel,1:2);

            if connectionsDisplayed == 2
                ylim([0,2*quantile(Pred(:,prs1(1),prs1(2)),0.9)])
            end
            temp = ylim;
            text(min(t) +.03*abs(min(t)),temp(2)*0.97,['Cell: ' num2str(targ(2)) ', spike group '  num2str(targ(1))])
            
            %the bad ones are in pink
            if  ~ismember(prs(j,:),keep_con,'rows')
                set(ha(j),'Color',[1 .75 .75])
            end
            
            set(gca,'UserData',j,'ButtonDownFcn',@subplotclick);
            
            % Plot an inset with the ACG
            axhpos = ylim;
            
            thisacg = ccgR(:,tcel,tcel);
            thisacg = thisacg./max(thisacg)*axhpos(2)*0.2+axhpos(2)*0.78;
            t2 = 16*t./max(t)+43; 
            rectangle('Position',[min(t2),min(axhpos(2)*0.8,min(thisacg)),max(t2)-min(t2),axhpos(2)*0.2],'FaceColor','w','EdgeColor','w', 'HitTest','off')
            bar_from_patch(t2,thisacg,[.5 .5 .5],min(axhpos(2)*0.8,min(thisacg)))
            rectangle('Position',[min(t2),min(axhpos(2)*0.8,min(thisacg)),(max(t2)-min(t2))*1.0035,axhpos(2)*0.2], 'HitTest','off')
            upL = get(gca,'ylim');
            plot([0 0],[0 upL(2)],'k', 'HitTest','off')
        elseif j<length(ha)-1
            axis off
        elseif j<length(ha)
            zdata = ccgR(:,:,allcel(i))';
            imagesc(flip(t),1:size(ccgR,3),(zdata'./max(zdata'))'), hold on
            plot(-58*ones(size(prs2,1),1),prs2(:,2),'.w', 'HitTest','off', 'MarkerSize',12)
            plot(-58*ones(size(prs2,1),1),prs2(:,1),'.k', 'HitTest','off', 'MarkerSize',12)
            plot(-58*ones(size(prs2,1),1),[prs2(:,2),prs2(:,1)],'ok', 'HitTest','off')
            plot([0;0],[0;1]*size(zdata,1),'m', 'HitTest','off')
            xlabel('CCGs (black marker: reference cell)')
        else
            bar_from_patch(t,ccgR(:,allcel(i),allcel(i)),'k',0)
            xlim([min(t) max(t)]);
            xlabel('Reference Cell ACG');
%             connection_matrix = ones(size(mono_res_in.TruePositive));
%             connection_matrix(allcel(i),:) = 0.8;
%             for iii = 1:size(prs,1)
%                 connection_matrix(prs(iii,1),prs(iii,2)) = 0.5;
%             end
%             for iii = 1:size(keep_con,1)
%                 connection_matrix(keep_con(iii,1),keep_con(iii,2)) = 0;
%             end
%             axh = AxesInsetBars2(gca,.2,connection_matrix);
%             axhpos = get(axh,'Position');
%             set(axh,'Position',[axhpos(1) axhpos(2)-axhpos(4)*.2 axhpos(3) axhpos(4)],'XTickLabel',[],'YTickLabel',[]);
            
            targ=completeIndex(completeIndex(:,3) == allcel(i),1:2);
            plotTitle.String = ['Reference Cell: cell ' num2str(targ(2)) ', spike group '  num2str(targ(1)),' (', num2str(i),'/' num2str(length(allcel)),')'];
            uiwait(h);
        end
    end
    
end

if ishandle(h)
    close(h)
end

if connectionsDisplayed == 1
    mono_res.sig_con = keep_con;
    mono_res.sig_con_excitatory = keep_con;
else
    mono_res.sig_con_inhibitory = keep_con;
end

if ischar(mono_res_in)
    disp('Saving mono_res file')
    save(mono_res_in,'mono_res','-v7.3','-nocompression');
end

    function subplotclick(obj,ev) %when an axes is clicked
        figobj = get(obj,'Parent');
        axdata = get(obj,'UserData');
        clr2 = get(obj,'Color');
        if sum(clr2 == [1 1 1])==3%if white (ie synapse), set to pink (bad), remember as bad
            set(obj,'Color',[1 .75 .75])
            keep_con(ismember(keep_con,prs(axdata,:),'rows'),:)=[];
        elseif sum(clr2 == [1 .75 .75])==3%if pink, set to white, set to good
            set(obj,'Color',[1 1 1])
            keep_con = [keep_con;prs(axdata,:)];
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
        i = max(i-1,1);
        uiresume(h);
    end

    function advance
        if i==length(allcel)
            answer = questdlg('All cells have been currated. Do you want to quit?', 'Monosyn curration complete', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                close(h)
            end
        else
            i = i+1;
            uiresume(h);
        end
    end

    function advance10
        i = min(i+10,length(allcel));
        uiresume(h);
    end

    function goBack10
        i = max(i-10,1);
        uiresume(h);
    end

    function keyPress(src,event)
        switch event.Key
            case 'space'
                advance
            case 'rightarrow'
                advance
            case 'leftarrow'
                goBack
            case 'leftarrow'
                goBack
            case {'1','2','3','4','5','6','7','8','9'}
                numericSelect(str2num(event.Key));
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                numericSelect(str2num(event.Key(end)))
            case {'0','numpad0'}
                i=1;
                uiresume(h);
            case 'uparrow'
                advance10
            case 'downarrow'
                goBack10
        end
    end

    function switchConnectionType(~,~)
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
            if isfield(mono_res,'sig_con_excitatory_all')
                sig_con = mono_res.sig_con_excitatory_all;
                allcel = unique(mono_res.sig_con_excitatory_all(:));
            else
                sig_con = keep_con;
            end
            allcel = unique(sig_con(:));
            disp('Excitatory connections (all)')
        elseif connectionsDisplayed == 2 && displayAllConnections.Value == 0
            sig_con = mono_res.sig_con_inhibitory;
            keep_con = sig_con;
            allcel = unique(sig_con(:));
            disp('Inhibitory connections')
        elseif connectionsDisplayed == 2 && displayAllConnections.Value == 1
            keep_con = mono_res.sig_con_inhibitory;
            if isfield(mono_res,'sig_con_excitatory_all')
                sig_con = mono_res.sig_con_inhibitory_all;
            else
                sig_con = keep_con;
            end
            allcel = unique(sig_con(:));
            disp('Inhibitory connections (all)')
        end
        uiresume(h);
    end
end

function bar_from_patch(x_data, y_data,col,y0)
% Creates a bar graph using the patch plot mode, which is substantial
% faster than using the regular bar plot.
% By Peter Petersen

x_step = x_data(2)-x_data(1);
x_data = [x_data(1),reshape([x_data,x_data+x_step]',1,[]),x_data(end)+x_step];
y_data = [y0,reshape([y_data,y_data]',1,[]),y0];
patch(x_data, y_data,col,'EdgeColor',col, 'HitTest','off')
end

function [p,n]=numSubplots(n)
% Calculate how many rows and columns of sub-plots are needed to
% neatly display n subplots.
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

% Reformat if the column/row ratio is too large: we want a roughly
% square design
while p(2)/p(1)>2.5
    N=n+1;
    [p,n]=numSubplots(N); %Recursive!
end
end