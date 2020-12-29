function deepSuperficialfromRipple = gui_DeepSuperficial(basepath,basename)
% Plotting the average ripple with sharp wave one spike groups at the time
% Allows for adjustment of reversal channels and assignment of
% deep-superfical groups ('Cortical', 'Deep', 'Superficial', 'Unknown')

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 21-12-2020

if ~exist('basepath','var')
    basepath = pwd;
end
if ~exist('basename','var')
    [~,basename,~] = fileparts(basepath);
end
spikegroup = 1;
deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
gain = 0.1;
if exist(deepSuperficial_file,'file')
    load(deepSuperficial_file,'deepSuperficialfromRipple');
else
    warndlg([deepSuperficial_file,' does not exist!'],'adjust Deep-Superficial')
    return
end

maxFigureSize = get(groot,'ScreenSize'); figureSize = [50, 50, min(1000,maxFigureSize(3)-50), min(700,maxFigureSize(4)-50)];

h = figure('KeyReleaseFcn', {@keyPress},'Name',['Deep-superficial inspector - session: ', basename],'NumberTitle','off','renderer','opengl','Position',figureSize); movegui(h,'center')
% p = uipanel(h,'Position',[0 0 1 .1],'BorderType','none')
% p2 = uipanel(h,'Position',[0 0 0.01 0.01],'BorderType','none')
uicontrol('Parent',h,'Style','pushbutton','Position',[5 5 85 30],'Units','normalized','String','<','Callback',@(src,evnt)goBack,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[100 5 100 30],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[210 5 100 30],'Units','normalized','String','Assign Unknown','Callback',@(src,evnt)assignUnknown,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[320 5 100 30],'Units','normalized','String','Assign Cortical','Callback',@(src,evnt)assignCortical,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[430 5 100 30],'Units','normalized','String','Assign Deep','Callback',@(src,evnt)assignDeep,'KeyPressFcn', {@keyPress});
uicontrol('Parent',h,'Style','pushbutton','Position',[540 5 100 30],'Units','normalized','String','Assign Superficial','Callback',@(src,evnt)assignSuperficial,'KeyPressFcn', {@keyPress});
DeepSuperficialReversal = uicontrol('Parent',h,'Style','popupmenu','Position',[650 10 200 20],'Units','normalized','String',{},'HorizontalAlignment','left','FontSize',10,'Callback',@(src,evnt)assignReversal);
uicontrol('Parent',h,'Style','pushbutton','Position',[860 5 130 30],'Units','normalized','String','Clear all assignment','Callback',@(src,evnt)clearSessionAssignments,'KeyPressFcn', {@keyPress});

%     plotTitle = uicontrol('Parent',h,'Style','text','Position',[130 410 350 10],'Units','normalized','String','','HorizontalAlignment','center','FontSize',13);

while spikegroup > 0 && spikegroup <= size(deepSuperficialfromRipple.ripple_amplitude,2)
    if ~ishandle(h)
        saveDeepSuperficial
        return
    end
    DeepSuperficialReversal.String = cellstr({'Assign reversal channel';num2str(deepSuperficialfromRipple.ripple_channels{spikegroup}'-1)});
    DeepSuperficialReversal.Value = 1;
    delete(findobj(h, 'type', 'axes'));
    plotDeepSuperficial(spikegroup)
    uiwait(h);
end
saveDeepSuperficial

    function plotDeepSuperficial(spikegroup)
        jj = spikegroup;
        plot((deepSuperficialfromRipple.SWR_diff{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_diff{jj},2)-1]*gain,'-k','linewidth',2), hold on, %grid on
%         plot((deepSuperficialfromRipple.SWR_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_amplitude{jj},2)-1]*gain,'k','linewidth',1)
        % Plotting ripple amplitude along vertical axis
%         plot((deepSuperficialfromRipple.ripple_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.ripple_amplitude{jj},2)-1]*gain,'m','linewidth',1)
        
        for jjj = 1:size(deepSuperficialfromRipple.ripple_average{jj},2)
            % Plotting depth (µm)
            text(deepSuperficialfromRipple.ripple_time_axis(end)+5,deepSuperficialfromRipple.ripple_average{jj}(1,jjj)-(jjj-1)*gain,[num2str(round(deepSuperficialfromRipple.channelDistance(deepSuperficialfromRipple.ripple_channels{jj}(jjj))))])
            % Plotting channel number (0 indexes)
            text((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50-10,-(jjj-1)*gain,num2str(deepSuperficialfromRipple.ripple_channels{jj}(jjj)-1),'HorizontalAlignment','Right')
            
            % Plotting assigned channel labels
            if strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Superficial')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*gain,'or','linewidth',2)
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*gain,'r')
            elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Deep')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*gain,'ob','linewidth',2)
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*gain,'b')
            elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Cortical')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*gain,'og','linewidth',2)
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*gain,'g')
            else
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*gain,'ok')
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*gain,'k')
            end
            % Plotting the channel used for the ripple detection if it is part of current spike group
            if isfield(deepSuperficialfromRipple,'detectorinfo') && deepSuperficialfromRipple.detectorinfo.detectionparms.channel+1==deepSuperficialfromRipple.ripple_channels{jj}(jjj)
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*gain,'k','linewidth',2)
            end
        end
        
        title(['Electrode group ' num2str(jj),'/', num2str(size(deepSuperficialfromRipple.ripple_amplitude,2))]),xlabel('Time (ms)'), %if jj ==1; ylabel(session.general.name, 'Interpreter', 'none'); end
        axis tight, ax6 = axis; % grid on
        plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
        xlim([-220,deepSuperficialfromRipple.ripple_time_axis(end)+45]), xticks([-120:40:120])
        ht1 = text(0.01,0.02,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
        ht2 = text(0.01,0.98,'Deep','Units','normalized','FontWeight','Bold','Color','b');
        ht2 = text(0.01,1.02,'Cortical','Units','normalized','FontWeight','Bold','Color',[0.2,0.8,0.2],'HorizontalAlignment','left');
        ht1 = text(0.01,-0.02,'Unknown','Units','normalized','FontWeight','Bold','Color','k','HorizontalAlignment','left');
        ht1 = text(0.99,1.02,'Depth (µm)','Units','normalized','FontWeight','Bold','Color','k','HorizontalAlignment','Right');
        %         if ceil(session.extracellular.nSpikeGroups/2) == jj || session.extracellular.nSpikeGroups == jj
        %             ht3 = text(1.05,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
        %         end
    end

    function goBack
        spikegroup = max(spikegroup-1,1);
        uiresume(h);
    end

    function advance
        if spikegroup==size(deepSuperficialfromRipple.ripple_amplitude,2)
            answer = questdlg('All spike groups have been currated. Do you want to quit?', 'Deep-superficial curration complete', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                close(h)
            end
        else
            spikegroup = spikegroup+1;
            uiresume(h);
        end
    end

    function keyPress(src, e)
        switch e.Key
            case 'space'
                advance
            case 'rightarrow'
                advance
            case 'leftarrow'
                goBack
            case 'd'
                assignDeep
            case 's'
                assignSuperficial
            case 'c'
                assignCortical
            case 'u'
                assignUnknown
                
        end
    end

    function assignDeep
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}) = repmat({'Deep'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}));
        uiresume(h);
    end

    function assignSuperficial
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}) = repmat({'Superficial'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}));
        uiresume(h);
    end

    function assignCortical
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}) = repmat({'Cortical'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}));
        uiresume(h);
    end

    function assignUnknown
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}) = repmat({'Unknown'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}));
        uiresume(h);
    end

    function assignReversal
        reversal = DeepSuperficialReversal.Value-1;
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}(1:reversal)) = repmat({'Deep'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}(1:reversal)));
        deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{spikegroup}(reversal+1:end)) = repmat({'Superficial'},1,length(deepSuperficialfromRipple.ripple_channels{spikegroup}(reversal+1:end)));
        VerticalSpacing = deepSuperficialfromRipple.processinginfo.params.verticalSpacing;
        deepSuperficialfromRipple.channelDistance(deepSuperficialfromRipple.ripple_channels{spikegroup}) = ([1:length(deepSuperficialfromRipple.ripple_channels{spikegroup})]-reversal)*VerticalSpacing;
        uiresume(h);
    end

    function clearSessionAssignments
        answer = questdlg('Are you sure you want to clear all deep-superficial assignments?', 'clear Deep-superficial', 'Yes','No','Yes');
        if strcmp(answer,'Yes')
            deepSuperficialfromRipple.channelClass = repmat({'Unknown'},1,length(deepSuperficialfromRipple.channelDistance));
            deepSuperficialfromRipple.channelDistance(1:length(deepSuperficialfromRipple.channelDistance)) = NaN;
            uiresume(h);
        end
        
    end

    function saveDeepSuperficial
        answer = questdlg('Do you want to save the manual deep superfical curration?', 'Save Deep-superficial curration', 'Yes','No','Yes');
        if strcmp(answer,'Yes')
            disp('Saving deep superfical classification')
            try
                save(deepSuperficial_file,'deepSuperficialfromRipple','-v7.3','-nocompression');
            catch
                warndlg('Failed to save deep superfical classification','Warning');
                return
            end
        else
            deepSuperficialfromRipple = [];
        end
    end
end
