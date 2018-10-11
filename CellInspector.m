function CellInspector(basepath)
% Inspect and perform cell classifications
%
% INPUT
% basepath: basepath can be a path, cell_metrics structure, or database ID.
%
% Example calls:
% CellInspector                 % Load from current path, assumed to be a basepath
% CellInspector(basepath)       % Load from basepath
% CellInspector(cell_metrics)   % Load from cell_metrics, assume current path to be a basepath
% CellInspector(10985)          % Load from database
%
%
% By Peter Petersen and Manuel Valero
% petersen.peter@gmail.com

% % % % % % % % % % % % % % % % % % % % % %
% General settings
% % % % % % % % % % % % % % % % % % % % % %

exit = 0;
ACG_type = 'Narrow'; % Narrow, Wide, Viktor
MonoSynDisp = 'None'; % None, Selected, All
classColors = [[.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8]];
% classColorsHex = reshape(sprintf('%02X',(classColors*0.7.')*255),6,[]).';

classColorsHex = rgb2hex(classColors*0.7);
classColorsHex = cellstr(classColorsHex(:,2:end));
classNames = {'Unknown','Pyramidal Cell','Interneuron'};
classNames = {'Unknown','Pyramidal Cell 1','Pyramidal Cell 2','Pyramidal Cell 3','Narrow Interneuron','Wide Interneuron'};
classNumbers = cellstr(num2str([0:length(classNames)-1]'))';
PlotZLog = 0; Plot3axis = 0; db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = []; classes2plot = [];
DeepSuperficial_ChClass = []; DeepSuperficial_ChDistance = []; ripple_amplitude = []; ripple_power = []; ripple_average = [];
fieldsMenu = []; table_metrics = []; tSNE_plot = []; ii = []; ripple_channels = []; session = []; history_classification = [];
cluster_path = ''; DeepSuperficial = []; BrainRegions_list = []; BrainRegions_acronym = []; cell_class_count = [];

% % % % % % % % % % % % % % % % % % % % % %
% Database initialization
% % % % % % % % % % % % % % % % % % % % % %

if exist('bz_database_credentials') == 2
    bz_database = bz_database_credentials;
    EnableDatabase = 1;
else
    EnableDatabase = 0;
end

% % % % % % % % % % % % % % % % % % % % % %
% Session initialization
% % % % % % % % % % % % % % % % % % % % % %

if nargin == 0
    basepath = pwd;
end
if ischar(basepath)
    cd(basepath)
    if exist('session.mat')
        disp('Loading local session.mat')
        load('session.mat')
        try LoadSession
            if ~exist('cell_metrics')
                return
            end
        catch
            warning('Failed to load cell_metrics');
            return
        end
    elseif exist('cell_metrics.mat')
        disp('Loading local cell_metrics.mat')
        load('cell_metrics.mat')
        initializeSession
    else
        warning('Neither session.mat or cell_metrics.mat exist in base folder')
        return
    end
elseif isstruct(basepath)
    cell_metrics = basepath;
    initializeSession
    
elseif isnumeric(basepath)
    if EnableDatabase
        disp('Loading session from database')
        try sessions = bz_load_sessions(basepath,bz_database);
            session = sessions{1};
        catch
            warning('Failed to load dataset');
            return
        end
        try LoadSession
            if ~exist('cell_metrics')
                return
            end
        catch
            warning('Failed to load cell_metrics');
            return
        end
    else
        warning('Database tools not available');
        return
    end
end

% % % % % % % % % % % % % % % % % % % % % %
% UI initialization
% % % % % % % % % % % % % % % % % % % % % %

fig = figure('KeyReleaseFcn', {@keyPress},'Name','Cell inspector','NumberTitle','off','renderer','opengl');

% Navigation buttons
uicontrol('Style','pushbutton','Position',[515 395 40 20],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyReleaseFcn', {@keyPress});
uicontrol('Style','pushbutton','Position',[515 370 40 20],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyReleaseFcn', {@keyPress});

% Cell classification
uicontrol('Style','text','Position',[515 300 40 15],'Units','normalized','String','Cell Classification','HorizontalAlignment','center');
colored_string = strcat('<html><font color="', classColorsHex' ,'">' ,classNames,' (', classNumbers, ')</font></html>');
listbox_cell_classification = uicontrol('Style','listbox','Position',[515 255 40 50],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyReleaseFcn', {@keyPress});

% Deep/Superficial
button_deepsuperficial = uicontrol('Style','pushbutton','Position',[515 165 40 20],'Units','normalized','String',['D/S: ', DeepSuperficial{ii}],'Callback',@(src,evnt)buttonDeepSuperficial,'KeyReleaseFcn', {@keyPress});

% Brain region
button_brainregion = uicontrol('Style','pushbutton','Position',[515 140 40 20],'Units','normalized','String',['Region: ', cell_metrics.BrainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyReleaseFcn', {@keyPress});

% Select unit from t-SNE space
uicontrol('Style','pushbutton','Position',[515 345 40 20],'Units','normalized','String','Select unit','Callback',@(src,evnt)buttonSelectFromPlot(),'KeyReleaseFcn', {@keyPress});

% Select group with polygon buttons
uicontrol('Style','pushbutton','Position',[515 320 40 20],'Units','normalized','String','Polygon','Callback',@(src,evnt)GroupSelectFromPlot,'KeyReleaseFcn', {@keyPress});

% Select subset of cell type
updateCellCount
uicontrol('Style','text','Position',[515 235 40 15],'Units','normalized','String','Display cell-types','HorizontalAlignment','center');
listbox_celltypes = uicontrol('Style','listbox','Position',[515 190 40 50],'Units','normalized','String',strcat(classNames,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(classNames),'Callback',@(src,evnt)buttonSelectSubset());

% ACG window size
button_ACG = uicontrol('Style','pushbutton','Position',[515 115 40 20],'Units','normalized','String','ACG 100ms','Callback',@(src,evnt)buttonACG(),'KeyReleaseFcn', {@keyPress});

% Show detected synaptic connections
button_SynMono = uicontrol('Style','pushbutton','Position',[515 90 40 20],'Units','normalized','String','MonoSyn: All','Callback',@(src,evnt)buttonMonoSyn(),'Visible','on','KeyReleaseFcn', {@keyPress});

% Load database session button
button_db = uicontrol('Style','pushbutton','Position',[515 60 40 20],'Units','normalized','String','Load dataset','Callback',@(src,evnt)LoadDatabaseSession(),'Visible','off','KeyReleaseFcn', {@keyPress});
% popup_db_menu = uicontrol('Style','popupmenu','Position',[515 85 40 10],'Units','normalized','String','test','HorizontalAlignment','left','Visible','off');
if EnableDatabase
    button_db.Visible='On';
end

% Save classification
uicontrol('Style','pushbutton','Position',[515 35 40 20],'Units','normalized','String','Save classification','Callback',@(src,evnt)buttonSave,'KeyReleaseFcn', {@keyPress});

% Exit button
uicontrol('Style','pushbutton','Position',[515 10 40 20],'Units','normalized','String','Exit','Callback',@(src,evnt)buttonExit());

% Custom plotting menues
uicontrol('Style','text','Position',[10 385 45 10],'Units','normalized','String','Select X data','HorizontalAlignment','left');
uicontrol('Style','text','Position',[10 350 45 10],'Units','normalized','String','Select Y data','HorizontalAlignment','left');

popup_x = uicontrol('Style','popupmenu','Position',[5 375 40 10],'Units','normalized','String',fieldsMenu,'Value',6,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX());
popup_y = uicontrol('Style','popupmenu','Position',[5 340 40 10],'Units','normalized','String',fieldsMenu,'Value',5,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY());
popup_z = uicontrol('Style','popupmenu','Position',[5 305 40 10],'Units','normalized','String',fieldsMenu,'Value',12,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ());

checkbox_logx = uicontrol('Style','checkbox','Position',[5 365 40 10],'Units','normalized','String','Log X scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotXLog());
checkbox_logy = uicontrol('Style','checkbox','Position',[5 330 40 10],'Units','normalized','String','Log Y scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotYLog());
checkbox_logz = uicontrol('Style','checkbox','Position',[5 295 40 10],'Units','normalized','String','Log Z scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZLog());
checkbox_showz = uicontrol('Style','checkbox','Position',[5 315 45 10],'Units','normalized','String','Show Z axis','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis());

% Table with metrics for selected cell
ui_table = uitable(fig,'Data',[fieldsMenu,num2cell(table_metrics(1,:)')],'Position',[10 30 140 575],'ColumnWidth',{90, 46},'columnname',{'Metrics',''},'RowName',[]);
checkbox_showtable = uicontrol('Style','checkbox','Position',[5 2 50 10],'Units','normalized','String','Show Metrics table','HorizontalAlignment','left','Value',1,'Callback',@(src,evnt)buttonShowMetrics());

% Terminal output line
ui_terminal = uicontrol('Style','text','Position',[75 2 400 10],'Units','normalized','String','','HorizontalAlignment','left','FontSize',12);

% Title line with name of current session
ui_title = uicontrol('Style','text','Position',[5 410 200 10],'Units','normalized','String',['Session: ', cell_metrics.General.basename,' with ', num2str(size(cell_metrics.TroughToPeak,2)), ' units'],'HorizontalAlignment','left','FontSize',15);
% ui_details = uicontrol('Style','text','Position',[5 400 200 10],'Units','normalized','String',{['Session: ', cell_metrics.General.basename],[num2str(size(cell_metrics_all.TroughToPeak,2)),', shank ']},'HorizontalAlignment','left','FontSize',15);

% % % % % % % % % % % % % % % % % % % % % %
% Main loop of UI
% % % % % % % % % % % % % % % % % % % % % %

while ii <= size(cell_metrics.TroughToPeak,2) & exit == 0
    if strcmp(ui_table.Visible,'on')
        ui_table.Data = [fieldsMenu,num2cell(table_metrics(ii,:)')];
    end
    listbox_cell_classification.Value = clusClas(ii)+1;
    subset = find(ismember(clusClas,classes2plot));
    
    subfig_ax(1) = subplot(2,3,1); cla, hold on
    xlabel(plotX_title, 'Interpreter', 'none'),
    ylabel(plotY_title, 'Interpreter', 'none'),
    title(['Custom metrics, Cluster ID: ' num2str(cell_metrics.CellID(ii))]),
    set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
    xlim auto, ylim auto, zlim auto
    
    if Plot3axis == 0
        for jj = classes2plot
            scatter(plotX(find(clusClas==jj)), plotY(find(clusClas==jj)), 'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
        end
        plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20)
        
        switch MonoSynDisp
            case 'All'
                putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
                a1 = cell_metrics.PutativeConnections(putativeSubset,1);
                a2 = cell_metrics.PutativeConnections(putativeSubset,2);
                plot([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],'k')
            case 'Selected'
                putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
                a1 = cell_metrics.PutativeConnections(putativeSubset,1);
                a2 = cell_metrics.PutativeConnections(putativeSubset,2);
                inbound = find(a2 == ii);
                outbound = find(a1 == ii);
                plot([plotX(a1(inbound));plotX(a2(inbound))],[plotY(a1(inbound));plotY(a2(inbound))],'k')
                plot([plotX(a1(outbound));plotX(a2(outbound))],[plotY(a1(outbound));plotY(a2(outbound))],'m')
        end
    else
        if PlotZLog == 1
            set(gca, 'ZScale', 'log')
        else
            set(gca, 'ZScale', 'linear')
        end
        for jj = classes2plot
            scatter3(plotX(find(clusClas==jj)), plotY(find(clusClas==jj)), plotZ(find(clusClas==jj)), 'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
        end
        plot3(plotX(ii), plotY(ii), plotZ(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20)
        
        switch MonoSynDisp
            case 'All'
                putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
                a1 = cell_metrics.PutativeConnections(putativeSubset,1);
                a2 = cell_metrics.PutativeConnections(putativeSubset,2);
                plot3([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],[plotZ(a1);plotZ(a2)],'k')
            case 'Selected'
                putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
                a1 = cell_metrics.PutativeConnections(putativeSubset,1);
                a2 = cell_metrics.PutativeConnections(putativeSubset,2);
                inbound = find(a2 == ii);
                outbound = find(a1 == ii);
                plot3([plotX(a1(inbound));plotX(a2(inbound))],[plotY(a1(inbound));plotY(a2(inbound))],[plotZ(a1(inbound));plotZ(a2(inbound))],'k')
                plot3([plotX(a1(outbound));plotX(a2(outbound))],[plotY(a1(outbound));plotY(a2(outbound))],[plotZ(a1(outbound));plotZ(a2(outbound))],'m')
        end
        
        zlabel(plotZ_title, 'Interpreter', 'none')
        if contains(plotZ_title,'_num')
            zticks([1:length(groups_ids.(plotZ_title))]), zticklabels(groups_ids.(plotZ_title)),ztickangle(65),zlim([0.5,length(groups_ids.(plotZ_title))+0.5]),zlabel(plotZ_title(1:end-4), 'Interpreter', 'none')
        end
    end
    
    if contains(plotX_title,'_num')
        xticks([1:length(groups_ids.(plotX_title))]), xticklabels(groups_ids.(plotX_title)),xtickangle(20),xlim([0.5,length(groups_ids.(plotX_title))+0.5]),xlabel(plotX_title(1:end-4), 'Interpreter', 'none')
    end
    if contains(plotY_title,'_num')
        yticks([1:length(groups_ids.(plotY_title))]), yticklabels(groups_ids.(plotY_title)),ytickangle(65),ylim([0.5,length(groups_ids.(plotY_title))+0.5]),ylabel(plotY_title(1:end-4), 'Interpreter', 'none')
    end
    
    subfig_ax(2) = subplot(2,3,2);
    cla
    hold on
    for jj = classes2plot
        scatter(cell_metrics.TroughToPeak(find(clusClas==jj)) * 1000, cell_metrics.BurstIndex_Royer2012(find(clusClas==jj)), -7*(log(cell_metrics.BurstIndex_Royer2012(find(clusClas==jj)))-10),...
            'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
    end
    ylabel('BurstIndex Royer2012'); xlabel('Trough-to-Peak (µs)'), title(['Unit ', num2str(ii),'/' num2str(size(cell_metrics.TroughToPeak,2)), '  Class: ', classNames{clusClas(ii)+1}])
    set(gca, 'YScale', 'log')
    % cell to check
    plot(cell_metrics.TroughToPeak(ii) * 1000, cell_metrics.BurstIndex_Royer2012(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20);
    
    switch MonoSynDisp
        case 'All'
            plot([cell_metrics.TroughToPeak(a1);cell_metrics.TroughToPeak(a2)] * 1000,[cell_metrics.BurstIndex_Royer2012(a1);cell_metrics.BurstIndex_Royer2012(a2)],'k')
        case 'Selected'
            plot([cell_metrics.TroughToPeak(a1(inbound));cell_metrics.TroughToPeak(a2(inbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(inbound));cell_metrics.BurstIndex_Royer2012(a2(inbound))],'k')
            plot([cell_metrics.TroughToPeak(a1(outbound));cell_metrics.TroughToPeak(a2(outbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(outbound));cell_metrics.BurstIndex_Royer2012(a2(outbound))],'m')
    end
    
    
    col= classColors(clusClas(ii)+1,:);
    
    subfig_ax(3) = subplot(2,3,3); cla, hold on
    for jj = classes2plot
        scatter(tSNE_plot(find(clusClas==jj),1), tSNE_plot(find(clusClas==jj),2), 'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
    end
    plot(tSNE_plot(find(strcmp(DeepSuperficial,'Superficial') & ismember(clusClas,classes2plot)),1),tSNE_plot(find(strcmp(DeepSuperficial,'Superficial') & ismember(clusClas,classes2plot)),2),'sk')
    plot(tSNE_plot(find(strcmp(DeepSuperficial,'Deep') & ismember(clusClas,classes2plot)),1),tSNE_plot(find(strcmp(DeepSuperficial,'Deep') & ismember(clusClas,classes2plot)),2),'ok')
    plot(tSNE_plot(ii,1), tSNE_plot(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20);
    
    legend('off'), title('t-SNE Cell class visualization')
    
    subplot(2,3,4); hold on, cla
    time_waveforms = [1:size(cell_metrics.SpikeWaveforms,1)]/20-0.8;
    patch([time_waveforms,flip(time_waveforms)]', [cell_metrics.SpikeWaveforms(:,ii)+cell_metrics.SpikeWaveforms_std(:,ii);flip(cell_metrics.SpikeWaveforms(:,ii)-cell_metrics.SpikeWaveforms_std(:,ii))],'black','EdgeColor','none','FaceAlpha',.2)
    plot(time_waveforms, cell_metrics.SpikeWaveforms(:,ii), 'color', col,'linewidth',2), grid on
    xlabel('Time (ms)'),title('Waveform (µV)'), axis tight, legend({'Std','Wavefom'},'Location','southwest','Box','off')
    
    subplot(2,3,5); cla, hold on
    if strcmp(ACG_type,'Narrow')
        bar([-100:100]/2,cell_metrics.ACG2(:,ii),1,'FaceColor',col,'EdgeColor',col)
        xticks([-50:10:50]),xlim([-50,50])
    elseif strcmp(ACG_type,'Viktor')
        bar([-30:30]/2,cell_metrics.ACG2(41+30:end-40-30,ii),1,'FaceColor',col,'EdgeColor',col)
        xticks([-15:5:15]),xlim([-15,15])
    else
        bar([-500:500],cell_metrics.ACG(:,ii),1,'FaceColor',col,'EdgeColor',col)
        xticks([-500:100:500]),xlim([-500,500])
    end
    ax5 = axis; grid on
    plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]);
    plot([ax5(1) ax5(2)],cell_metrics.FiringRate(ii)*[1 1],'--k')
    %     plot([0.006 0.006], [ax5(3) ax5(4)],'color',[.1 .1 .3]);
    
    xlabel('ms'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.FiringRate(ii),3),'Hz'])
    
    subplot(2,3,6); cla, hold on
    SpikeGroup = cell_metrics.SpikeGroup(ii);
    ripple_power_temp = ripple_power{SpikeGroup}/max(ripple_power{SpikeGroup}); grid on
    
    plot((ripple_amplitude{SpikeGroup}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{SpikeGroup},2)-1]*0.04,'-k','linewidth',2)
    
    for jj = 1:size(ripple_average{SpikeGroup},2)
        text(ripple_time_axis(end)+5,ripple_average{SpikeGroup}(1,jj)-(jj-1)*0.04,[num2str(round(DeepSuperficial_ChDistance(ripple_channels{SpikeGroup}(jj))))])
        %         text((ripple_power_temp(jj)*50)+ripple_time_axis(1)-50+12,-(jj-1)*0.04,num2str(ripple_channels{SpikeGroup}(jj)))
        if strcmp(DeepSuperficial_ChClass(ripple_channels{SpikeGroup}(jj)),'Superficial')
            plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'r','linewidth',2)
            plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'or','linewidth',2)
        elseif strcmp(DeepSuperficial_ChClass(ripple_channels{SpikeGroup}(jj)),'Deep')
            plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'b','linewidth',2)
            plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'ob','linewidth',2)
        else
            plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'k')
            plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'ok')
        end
    end
    
    if any(ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii))
        jjj = find(ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii));
        plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jjj)-(jjj-1)*0.04,':k','linewidth',3)
    end
    
    title(['SWR SpikeGroup ', num2str(SpikeGroup)]),xlabel('Time (ms)'), ylabel('Ripple (mV)')
    axis tight, gridxy(-120),gridxy(-170),gridxy(120),xlim([-220,ripple_time_axis(end)+50]), xticks([-120:40:120])
    ht1 = text(0.03,0.01,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
    ht2 = text(0.22,0.01,'Deep','Units','normalized','FontWeight','Bold','Color','b'); set(ht1,'Rotation',90), set(ht2,'Rotation',90)
    ht3 = text(0.97,0.01,'Depth (µm)','Units','normalized','Color','k'); set(ht1,'Rotation',90), set(ht3,'Rotation',90)
    
    uiwait(fig);
end
close(fig);

fprintf('%d pyramidal cells. \n',length(find(clusClas==1)));
fprintf('%d interneurons. \n',length(find(clusClas==2)));
fprintf('%d non-classified cells. \n',length(find(clusClas==0)));

% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

    function buttonCellType(newString)
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        clusClas(ii) = newString;
        ui_terminal.String = ['Celltype: Unit ', num2str(ii), ' classified as ', classNames{newString+1}];
        updateCellCount
        advance;
    end

% % % % % % % % % % % % % % % % % % % % % %

    function listCellType
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        clusClas(ii) = listbox_cell_classification.Value-1;
        ui_terminal.String = ['Celltype: Unit ', num2str(ii), ' classified as ', classNames{clusClas(ii)+1}];
        updateCellCount
        advance;
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonDeepSuperficial
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        if strcmp(DeepSuperficial{ii},'Deep')
            DeepSuperficial{ii} = 'Superficial';
            cell_metrics.DeepSuperficial_num(ii) = find(strcmp(groups_ids.DeepSuperficial_num,'Superficial'));
        else
            DeepSuperficial{ii} = 'Deep';
            cell_metrics.DeepSuperficial_num(ii) = find(strcmp(groups_ids.DeepSuperficial_num,'Deep'));
        end
        button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
        ui_terminal.String = ['Deep/Superficial: Unit ', num2str(ii), ' classified as ', DeepSuperficial{ii}];
        if strcmp(plotX_title,'DeepSuperficial_num')
            plotX = cell_metrics.DeepSuperficial_num;
        end
        if strcmp(plotY_title,'DeepSuperficial_num')
            plotY = cell_metrics.DeepSuperficial_num;
        end
        if strcmp(plotZ_title,'DeepSuperficial_num')
            plotZ = cell_metrics.DeepSuperficial_num;
        end
    end

% % % % % % % % % % % % % % % % % % % % % % 

    function buttonBrainRegion
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        if isempty(BrainRegions_list)
            load('BrainRegions.mat');
            BrainRegions_list = strcat(BrainRegions(:,1),' (',BrainRegions(:,2),')');
            BrainRegions_acronym = BrainRegions(:,2);
            clear BrainRegions;
        end
        [indx,tf] = listdlg('PromptString','Select brain region to assign to cell','Name','Brain region assignment','ListString',BrainRegions_list,'SelectionMode','single','InitialValue',find(strcmp(cell_metrics.BrainRegion{ii},BrainRegions_acronym)), 'ListSize',[550,250]);
        if tf == 1
            SelectedBrainRegion = BrainRegions_acronym{indx};
            cell_metrics.BrainRegion{ii} = SelectedBrainRegion;
            button_brainregion.String = ['Region: ', SelectedBrainRegion];
            [cell_metrics.BrainRegion_num,ID] = findgroups(cell_metrics.BrainRegion);
            groups_ids.BrainRegion_num = ID;
            ui_terminal.String = ['Brain region: Unit ', num2str(ii), ' classified as ', SelectedBrainRegion];
            uiresume(fig);
        end
        if strcmp(plotX_title,'BrainRegion_num')
            plotX = cell_metrics.BrainRegion_num;
        end
        if strcmp(plotY_title,'BrainRegion_num')
            plotY = cell_metrics.BrainRegion_num;
        end
        if strcmp(plotZ_title,'BrainRegion_num')
            plotZ = cell_metrics.BrainRegion_num;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function advance
        if ~isempty(subset) && length(subset)>1
            if ii >= subset(end)
                ii = subset(1);
            else
                ii = subset(find(subset > ii,1));
            end
        elseif length(subset)==1
            ii = subset(1);
        end
        button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
        button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function back
        if ~isempty(subset) && length(subset)>1
            if ii <= subset(1)
                ii = subset(end);
            else
                ii = subset(find(subset < ii,1,'last'));
            end
            ui_terminal.String = '';
        elseif length(subset)==1
            ii = subset(1);
        end
        button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
        button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonACG
        if strcmp(ACG_type,'Viktor')
            ACG_type = 'Narrow';
            button_ACG.String = 'ACG: 100ms';
            ui_terminal.String = 'Autocorrelogram window adjusted to 100 ms';
        elseif strcmp(ACG_type,'Wide')
            ACG_type = 'Viktor';
            button_ACG.String = 'ACG: 30ms';
            ui_terminal.String = 'Autocorrelogram window adjusted to 30 ms';
        else
            ACG_type = 'Wide';
            button_ACG.String = 'ACG: 1s';
            ui_terminal.String = 'Autocorrelogram window adjusted to 1 sec';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonMonoSyn
        if strcmp(MonoSynDisp,'None')
            MonoSynDisp = 'Selected';
            button_SynMono.String = 'MonoSyn: Selected';
            ui_terminal.String = 'Synaptic connections for selected cell';
        elseif strcmp(MonoSynDisp,'All')
            MonoSynDisp = 'None';
            button_SynMono.String = 'MonoSyn: None';
            ui_terminal.String = 'Hiding Synaptic connections';
        elseif strcmp(MonoSynDisp,'Selected')
            MonoSynDisp = 'All';
            button_SynMono.String = 'MonoSyn: All';
            ui_terminal.String = 'Synaptic connections for all cells';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonExit
        exit = 1;
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectFromPlot
        if ~isempty(subset)
            ui_terminal.String = ['Select unit by clicking the top subplots near a point'];
            [u,v] = ginput(1);
            axnum = find(ismember(subfig_ax, gca));
            if axnum == 1
                [~,idx] = min(hypot(plotX(subset)-u,plotY(subset)-v));
                ii = subset(idx);
                ui_terminal.String = ['Unit ', num2str(ii), ' selected from custom metrics'];
            elseif axnum == 2
                [~,idx] = min(hypot(cell_metrics.TroughToPeak(subset)-u/1000,log10(cell_metrics.BurstIndex_Royer2012(subset))-log10(v)));
                ii = subset(idx);
                ui_terminal.String = ['Unit ', num2str(ii), ' selected from waveform metrics'];
            elseif axnum == 3
                [~,idx] = min(hypot(tSNE_plot(subset,1)-u,tSNE_plot(subset,2)-v));
                ii = subset(idx);
                ui_terminal.String = ['Unit ', num2str(ii), ' selected from t-SNE visualization'];
            end
            button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
            button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
            uiresume(fig);
        else
            ui_terminal.String = ['No units with selected classification'];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupSelectFromPlot
        if ~isempty(subset)
            ui_terminal.String = ['Select units by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.'];
            ax = gca;
            polygon_coords = [];
            hold(ax, 'on');
            clear h2
            counter = 0;
            while true
                c = ginput(1);
                sel = get(fig, 'SelectionType');
                
                if strcmpi(sel, 'alt')
                    break;
                end
                if strcmpi(sel, 'extend') & counter > 0
                    polygon_coords=polygon_coords(1:end-1,:);
                    set(h2(counter),'Visible','off');
                    counter = counter-1;
                end
                if strcmpi(sel, 'normal')
                    polygon_coords=[polygon_coords;c];
                    counter = counter +1;
                    h2(counter) = plot(polygon_coords(:,1),polygon_coords(:,2),'.-k');
                end
                
            end
            plot([polygon_coords(:,1);polygon_coords(1,1)],[polygon_coords(:,2);polygon_coords(1,2)],'.-k');
            hold(ax, 'off')
            clear h2
            axnum = find(ismember(subfig_ax, gca));
            if axnum == 1
                In = find(inpolygon(plotX(subset), plotY(subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                ui_terminal.String = [num2str(length(In)), ' units selected from custom metrics'];
            elseif axnum == 2
                In = find(inpolygon(cell_metrics.TroughToPeak(subset)*1000, log10(cell_metrics.BurstIndex_Royer2012(subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                ui_terminal.String = [num2str(length(In)), ' units selected from waveform metrics'];
            elseif axnum == 3
                In = find(inpolygon(tSNE_plot(subset,1), tSNE_plot(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                ui_terminal.String = [num2str(length(In)), ' units selected from t-SNE visualization'];
            end
            if length(In)>0
                [indx,tf] = listdlg('PromptString',['Assign cell-type to ' num2str(length(In)) ' units'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
                if ~isempty(indx)
                    hist_idx = size(history_classification,2)+1;
                    history_classification(hist_idx).CellIDs = subset(In);
                    history_classification(hist_idx).CellTypes = clusClas(subset(In));
                    history_classification(hist_idx).DeepSuperficial = {DeepSuperficial{subset(In)}};
                    history_classification(hist_idx).BrainRegion = {cell_metrics.BrainRegion{subset(In)}};
                    history_classification(hist_idx).BrainRegion_num = cell_metrics.BrainRegion_num(subset(In));
                    history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(subset(In));
                    
                    clusClas(subset(In)) = indx-1;
                    updateCellCount
                    ui_terminal.String = [num2str(length(In)), ' units assigned to ', classNames{indx}, ' from t-SNE visualization'];
                end
            else
                ui_terminal.String = ['0 units selected'];
            end
            uiresume(fig);
        else
            ui_terminal.String = ['No units with selected classification'];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotX
        Xval = popup_x.Value;
        Xstr = popup_x.String;
        plotX = cell_metrics.(Xstr{Xval});
        plotX_title = Xstr{Xval};
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotY
        Yval = popup_y.Value;
        Ystr = popup_y.String;
        plotY = cell_metrics.(Ystr{Yval});
        plotY_title = Ystr{Yval};
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotZ
        Zval = popup_z.Value;
        Zstr = popup_z.String;
        plotZ = cell_metrics.(Zstr{Zval});
        plotZ_title = Zstr{Zval};
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotXLog
        if checkbox_logx.Value==1
            subplot(2,3,1), set(gca, 'XScale', 'log')
            ui_terminal.String = 'X-axis log. Negative data ignored';
        else
            subplot(2,3,1), set(gca, 'XScale', 'linear')
            ui_terminal.String = 'X-axis linear';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotYLog
        if checkbox_logy.Value==1
            subplot(2,3,1), set(gca, 'YScale', 'log')
            ui_terminal.String = 'Y-axis log. Negative data ignored';
        else
            subplot(2,3,1), set(gca, 'YScale', 'linear')
            ui_terminal.String = 'Y-axis linear';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotZLog
        if checkbox_logz.Value==1
            PlotZLog = 1;
            ui_terminal.String = 'Z-axis log. Negative data ignored';
        else
            PlotZLog = 0;
            ui_terminal.String = 'Z-axis linear';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlot3axis
        if checkbox_showz.Value==1
            Plot3axis = 1;
            subplot(2,3,1), view([40 20]);
        else
            Plot3axis = 0;
            subplot(2,3,1), view([0 90]);
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectSubset
        classes2plot = listbox_celltypes.Value-1;
        ui_terminal.String = [''];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonShowMetrics
        if checkbox_showtable.Value==1
            ui_table.Data = [fieldsMenu,num2cell(table_metrics(ii,:)')];
            ui_table.Visible = 'on';
            
        else
            ui_table.Visible = 'off';
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function keyPress(src, e)
        switch e.Key
            
            case 'rightarrow'
                advance
            case 'leftarrow'
                back
            case 's'
                buttonDeepSuperficial
            case 'd'
                buttonDeepSuperficial
            case '5'
                buttonCellType(5);
            case '4'
                buttonCellType(4);
            case '3'
                buttonCellType(3);
            case '2'
                buttonCellType(2);
            case '1'
                buttonCellType(1);
            case '0'
                buttonCellType(0);
            case 'a'
                buttonACG;
            case 'z'
                undoClassification;
        end
        
        %         uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function initializeSession
        ii = 1;
        % cell_classification_PutativeCellType
        cell_metrics.PutativeCellType = repmat({'Pyramidal Cell'},1,size(cell_metrics.CellID,2));
        % Interneuron classification
        cell_metrics.PutativeCellType(cell_metrics.ACG_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_decay>30),1);
        cell_metrics.PutativeCellType(cell_metrics.ACG_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_rise>3),1);
        cell_metrics.PutativeCellType(cell_metrics.TroughToPeak<0.4  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.TroughToPeak<0.4  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
        cell_metrics.PutativeCellType(cell_metrics.TroughToPeak>0.4  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.TroughToPeak>0.4  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
        % Pyramidal cell classification
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak<0.17 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 2'},sum(cell_metrics.derivative_TroughtoPeak<0.17 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak>0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 3'},sum(cell_metrics.derivative_TroughtoPeak>0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak>=0.17 & cell_metrics.derivative_TroughtoPeak<=0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 1'},sum(cell_metrics.derivative_TroughtoPeak>=0.17 & cell_metrics.derivative_TroughtoPeak<=0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        
        % Cell type initialization
        clusClas = zeros(1,length(cell_metrics.PutativeCellType));
        clusClas(strcmp(cell_metrics.PutativeCellType,''))=0;
        
        clusClas(contains(cell_metrics.PutativeCellType,'Pyramidal Cell 1'))=1;
        clusClas(contains(cell_metrics.PutativeCellType,'Pyramidal Cell 2'))=2;
        clusClas(contains(cell_metrics.PutativeCellType,'Pyramidal Cell 3'))=3;
        clusClas(contains(cell_metrics.PutativeCellType,'Narrow Interneuron'))=4;
        clusClas(contains(cell_metrics.PutativeCellType,'Wide Interneuron'))=5;
        
        % Deep-Superficial initialization
        DeepSuperficial = cell_metrics.DeepSuperficial;
        temp = load('DeepSuperficial_ChClass.mat');
        DeepSuperficial_ChClass = temp.DeepSuperficial_ChClass;
        DeepSuperficial_ChDistance = temp.DeepSuperficial_ChDistance;
        
        % Ripple initialization
        ripple_amplitude = temp.ripple_amplitude;
        ripple_power = temp.ripple_power;
        ripple_average = temp.ripple_average;
        ripple_time_axis = temp.ripple_time_axis;
        ripple_channels = temp.ripple_channels;
        
        % Plotting menues initialization
        fieldsMenu = sort(fieldnames(cell_metrics));
        groups_ids = [];
        
        for i = 1:length(fieldsMenu)
            if iscell(cell_metrics.(fieldsMenu{i}))
                [cell_metrics.([fieldsMenu{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenu{i}));
                groups_ids.([fieldsMenu{i},'_num']) = ID;
            end
        end
        
        fieldsMenu = sort(fieldnames(cell_metrics));
        fields_to_keep = [];
        for i = 1:length(fieldsMenu)
            if isnumeric(cell_metrics.(fieldsMenu{i})) && size(cell_metrics.(fieldsMenu{i}),1) == 1
                fields_to_keep(i) = 1;
            else
                fields_to_keep(i) = 0;
            end
        end
        
        fieldsMenu = fieldsMenu(find(fields_to_keep));
        if isfield(fieldsMenu,'General')
            fieldsMenu = rmfield(fieldsMenu,'General');
        end
        
        % Metric table initialization
        table_metrics = [];
        for i = 1:size(fieldsMenu,1)
            table_metrics(:,i) = cell_metrics.(fieldsMenu{i});
        end
        
        % tSNE initialization
        X = [cell_metrics.FiringRate; cell_metrics.ThetaModulationIndex; cell_metrics.BurstIndex_Mizuseki2012; cell_metrics.TroughToPeak; cell_metrics.derivative_TroughtoPeak; cell_metrics.AB_ratio; cell_metrics.BurstIndex_Royer2012; cell_metrics.ACG_tau_rise; cell_metrics.ACG_tau_decay; cell_metrics.CV2]; % cell_metrics.RippleModulationIndex; cell_metrics.RipplePeakDelay
        %         X(isnan(X) | isinf(X)) = 0;
        tSNE_plot = tsne(zscore(X'));
        
        % Setting initial settings for plots, popups and listboxes
        plotX = cell_metrics.ACG_tau_rise;
        plotY  = cell_metrics.ACG_tau_decay;
        plotZ  = cell_metrics.DeepSuperficialDistance;
        plotX_title = 'ACG tau rise';
        plotY_title = 'ACG tau decay';
        plotZ_title = 'Deep Superficial (µm)';
        popup_x.Value = 6;
        popup_y.Value = 5;
        popup_z.Value = 12;
        
        listbox_celltypes.Value = 1:length(classNames);
        classes2plot = 0:length(classNames)-1;
        
        ui_title.String = ['Session: ', cell_metrics.General.basename,' with ', num2str(size(cell_metrics.TroughToPeak,2)), ' units'];
        popup_x.String = fieldsMenu;
        popup_y.String = fieldsMenu;
        popup_z.String = fieldsMenu;
        
        if isfield(cell_metrics,'PutativeConnections')
            MonoSynDisp = 'All';
            button_SynMono.Visible = 'On';
            button_SynMono.String = 'MonoSyn: All';
            
        else
            MonoSynDisp = 'None';
            button_SynMono.Visible = 'off';
        end
        
        % History function initialization
        history_classification = [];
        history_classification(1).CellIDs = 1: size(cell_metrics.TroughToPeak,2);
        history_classification(1).CellTypes = clusClas;
        history_classification(1).DeepSuperficial = DeepSuperficial;
        history_classification(1).BrainRegion = cell_metrics.BrainRegion;
        history_classification(1).BrainRegion_num = cell_metrics.BrainRegion_num;
        history_classification(1).DeepSuperficial_num = cell_metrics.DeepSuperficial_num;
        
        % Cell count for menu
        updateCellCount
        
        % Button Deep-Superficial
        button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
        % Button brain region
        button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadDatabaseSession
        options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
        options.CertificateFilename=('');
        bz_db = webread('https://buzsakilab.com/wp/wp-json/frm/v2/views/15356/',options,'page_size','5000','sorted','1');
        sessions = loadjson(bz_db.renderedHtml);
        [db_menu_items,index] = sort(cellfun(@(x) x.Name,sessions,'UniformOutput',false));
        
        db_menu_values = cellfun(@(x) x.Id,sessions,'UniformOutput',false);
        db_menu_values = db_menu_values(index);
        db_menu_items2 = strcat(db_menu_items, ' (',db_menu_values, ')');
        ui_terminal.String = ['Datasets loaded from database'];
        
        [indx,tf] = listdlg('PromptString',['Select dataset to load'],'ListString',db_menu_items2,'SelectionMode','single','ListSize',[300,350]);
        if ~isempty(indx)
            id = db_menu_values{indx};
            try
                sessions = bz_load_sessions(id,bz_database);
                session = sessions{1};
                LoadSession
            catch
                warning('Failed to load dataset from database');
                ui_terminal.String = [db_menu_items{indx},': Error loading dataset from database'];
            end
        end
        %         end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadSession
        if isempty(session.SpikeSorting.RelativePath)
            cluster_path = '';
        else
            cluster_path = session.SpikeSorting.RelativePath{1};
        end
        
        if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))
            
            if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name,cluster_path,'cell_metrics.mat'))
                
                if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name,'DeepSuperficial_ChClass.mat'))
                    cd(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name));
                    load(fullfile(cluster_path,'cell_metrics.mat'));
                    
                    
                    initializeSession;
                    
                    ui_terminal.String = [session.General.Name ' with ' num2str(size(cell_metrics.TroughToPeak,2))  ' cells loaded from database'];
                else
                    ui_terminal.String = [session.General.Name, ': missing DeepSuperficial classification'];
                    warning([session.General.Name, ': missing DeepSuperficial classification'])
                end
            else
                ui_terminal.String = [session.General.Name, ': missing cell_metrics'];
                warning([session.General.Name, ': missing cell_metrics'])
            end
        else
            ui_terminal.String = [session.General.Name ': path not available'];
            warning([session.General.Name ': path not available'])
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function undoClassification
        if size(history_classification,2) > 1
            clusClas(history_classification(end).CellIDs) = history_classification(end).CellTypes;
            DeepSuperficial(history_classification(end).CellIDs) = cellstr(history_classification(end).DeepSuperficial);
            cell_metrics.BrainRegion(history_classification(end).CellIDs) = cellstr(history_classification(end).BrainRegion);
            cell_metrics.DeepSuperficial_num(history_classification(end).CellIDs) = history_classification(end).DeepSuperficial_num;
            
            if length(history_classification(end).CellIDs) == 1
                ui_terminal.String = ['Reversed classification for unit ', num2str(history_classification(end).CellIDs)];
            else
                ui_terminal.String = ['Reversed classification for ' num2str(length(history_classification(end).CellIDs)), ' cells'];
            end
            history_classification(end) = [];
            updateCellCount
            
            % Button Deep-Superficial
            button_deepsuperficial.String = ['D/S: ', DeepSuperficial{ii}];
            
            % Button brain region
            button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
            
            [cell_metrics.BrainRegion_num,ID] = findgroups(cell_metrics.BrainRegion);
            groups_ids.BrainRegion_num = ID;
            
        else
            ui_terminal.String = ['No history track'];
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateCellCount
        cell_class_count = histc(clusClas,[0:length(classNames)-1]);
        cell_class_count = cellstr(num2str(cell_class_count'))';
        listbox_celltypes.String = strcat(classNames,' (',cell_class_count,')');
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSave
        answer = questdlg('Are you sure you want to save the classification', 'Save classification','Save','Save and exit', 'Cancel','Cancel');
        % Handle response
        switch answer
            case 'Save'
                try
                    saveMetrics(cell_metrics);
                catch exception
                    warning('Failed to save the file');
                    disp(exception.identifier)
                    ui_terminal.String = ['Failed to save file - see Command Window for details'];
                    warndlg('Failed to save file - see Command Window for details','Warning');
                end
            case 'Save and exit'
                try
                    saveMetrics(cell_metrics);
                    exit = 1;
                catch exception
                    warning('Failed to save the file');
                    disp(exception.identifier)
                    ui_terminal.String = ['Failed to save file - see Command Window for details'];
                    warndlg('Failed to save file - see Command Window for details','Warning');
                end
            case 'Cancel'
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function saveMetrics(cell_metrics)
        numeric_fields = fieldnames(cell_metrics);
        cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
        cell_metrics.DeepSuperficial = DeepSuperficial;
        [C, ~, ic] = unique(clusClas+1,'sorted');
        for i = 1:length(C)
            cell_metrics.PutativeCellType(find(ic==i)) = repmat({classNames{C(i)}},sum(ic==i),1);
        end
        if length(unique(cell_metrics.SpikeSortingID)) > 1
            disp('Saving cell metrics from batch')
            save('cell_metrics_batch.mat','cell_metrics');
            ui_terminal.String = ['Classification saved to cell_metrics_batch.mat'];
            disp('Classification saved to cell_metrics_batch.mat');
        else
            save(fullfile(cluster_path,'cell_metrics.mat'),'cell_metrics');
            ui_terminal.String = ['Classification saved to ' fullfile(cluster_path,'cell_metrics.mat')];
            disp(['Classification saved to ' fullfile(cluster_path,'cell_metrics.mat')]);
        end
        
    end

end

function [ hex ] = rgb2hex(rgb)
% rgb2hex converts rgb color values to hex color format. 
% * * * * * * * * * * * * * * * * * * * * 
% Chad A. Greene, April 2014

assert(nargin==1,'This function requires an RGB input.') 
assert(isnumeric(rgb)==1,'Function input must be numeric.') 

sizergb = size(rgb); 
assert(sizergb(2)==3,'rgb value must have three components in the form [r g b].')
assert(max(rgb(:))<=255& min(rgb(:))>=0,'rgb values must be on a scale of 0 to 1 or 0 to 255')

if max(rgb(:))<=1
    rgb = round(rgb*255); 
else
    rgb = round(rgb); 
end

hex(:,2:7) = reshape(sprintf('%02X',rgb.'),6,[]).'; 
hex(:,1) = '#';

end

