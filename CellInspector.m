function cell_metrics = CellInspector(varargin)
% Inspect and perform cell classification
%
% INPUT 
% varargin
%
% Example calls:
% CellInspector                             % Load from current path, assumed to be a basepath
% CellInspector('basepath',basepath)        % Load from basepath
% CellInspector('metrics',cell_metrics)     % Load from cell_metrics, assume current path to be a basepath
% CellInspector('id',10985)                 % Load from database
% CellInspector('session','rec1')           % Load from database
% CellInspector('sessions',{'rec1','rec2'}) % Load batch from database
% CellInspector('sessionIDs',{10985,2845})  % Load batch from database
% CellInspector('clusteringpaths',{'path1','[path1'}) % Load batch from a list with paths
% CellInspector('basepaths',{'path1','[path1'}) % Load batch from a list with paths

% By Peter Petersen and Manuel Valero
% petersen.peter@gmail.com

p = inputParser;
% Loading single session
addParameter(p,'metrics',[],@isstruct);
addParameter(p,'id','',@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);

% Loading multiple sessions
addParameter(p,'sessionIDs',[],@iscell);
addParameter(p,'sessions',[],@iscell);
addParameter(p,'basepaths',[],@iscell);
addParameter(p,'clusteringpaths',[],@iscell);

parse(p,varargin{:})
metrics = p.Results.metrics;
id = p.Results.id;
sessionin = p.Results.session;
basepath = p.Results.basepath;
clusteringpath = p.Results.clusteringpath;
sessionIDs = p.Results.sessionIDs;
sessionsin = p.Results.sessions;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;

% % % % % % % % % % % % % % % % % % % % % %
% General settings
% % % % % % % % % % % % % % % % % % % % % %

exit = 0;
ACG_type = 'Narrow'; % Narrow, Wide, Viktor
MonoSynDisp = 'None'; % None, Selected, All
classColors = [[.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8]];

classColorsHex = rgb2hex(classColors*0.7);
classColorsHex = cellstr(classColorsHex(:,2:end));
classNames = {'Unknown','Pyramidal Cell','Interneuron'};
classNames = {'Unknown','Pyramidal Cell 1','Pyramidal Cell 2','Pyramidal Cell 3','Narrow Interneuron','Wide Interneuron'};
classNumbers = cellstr(num2str([0:length(classNames)-1]'))';
PlotZLog = 0; Plot3axis = 0; db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = []; classes2plot = [];
DeepSuperficial_ChClass = []; DeepSuperficial_ChDistance = []; ripple_amplitude = []; ripple_power = []; ripple_average = [];
fieldsMenu = []; table_metrics = []; tSNE_plot = []; ii = []; ripple_channels = []; history_classification = [];
clusteringpath = ''; DeepSuperficial = []; BrainRegions_list = []; BrainRegions_acronym = []; cell_class_count = [];
CustomCellPlot = 1; CustomPlotOptions = ''; WaveformsPlot = ''; customPlotHistograms = 0; plotACGfit = 0;

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

if isstruct(metrics)
    cell_metrics = metrics;
    initializeSession
elseif ~isempty(id) || ~isempty(sessionin)
    if EnableDatabase
        disp('Loading session from database')
        if ~isempty(id)
            try sessions = bz_load_sessions('id',id);
                session = sessions{1};
            catch
                warning('Failed to load dataset');
                return
            end
            
        else
            try sessions = bz_load_sessions('session',sessionin);
                session = sessions{1};
            catch
                warning('Failed to load dataset');
                return
            end
            
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
elseif ~isempty(sessionIDs)
    if EnableDatabase
        cell_metrics = LoadCellMetricBatch('sessionIDs',sessionIDs);
        initializeSession
        try 
            
        catch
            warning('Failed to load dataset');
            return
        end
    else
        warning('Database tools not available');
        return
    end
elseif ~isempty(sessionsin)
    if EnableDatabase
        try cell_metrics = LoadCellMetricBatch('sessions',sessionsin);
            initializeSession
        catch
            warning('Failed to load dataset');
            return
        end
    else
        warning('Database tools not available');
        return
    end
elseif ~isempty(clusteringpaths)
    try cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths);
        initializeSession
    catch
        warning('Failed to load dataset');
        return
    end
elseif ~isempty(basepaths)
    clusteringpaths = basepaths;
    try cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths);
        initializeSession
    catch
        warning('Failed to load dataset');
        return
    end
else
    cd(basepath)
    if exist('session.mat')
        disp('Loading local session.mat')
        load('session.mat')
        if isempty(session.SpikeSorting.RelativePath)
            clusteringpath = '';
        else
            clusteringpath = session.SpikeSorting.RelativePath{1};
        end
        load(fullfile(clusteringpath,'cell_metrics.mat'));
        initializeSession;
        
    elseif exist('cell_metrics.mat')
        disp('Loading local cell_metrics.mat')
        load('cell_metrics.mat')
        
        initializeSession
    else
        warning('Neither session.mat or cell_metrics.mat exist in base folder')
        return
    end
    
end

% % % % % % % % % % % % % % % % % % % % % %
% UI initialization
% % % % % % % % % % % % % % % % % % % % % %

fig = figure('KeyReleaseFcn', {@keyPress},'Name','Cell inspector','NumberTitle','off','renderer','opengl');

% Scattergroup uipanel
subfig_ax1 = uipanel('position',[0.09 0.5 0.28 0.5],'BorderType','none');
subfig_ax2 = uipanel('position',[0.09+0.28 0.5 0.28 0.5],'BorderType','none');
subfig_ax3 = uipanel('position',[0.09+0.54 0.5 0.28 0.5],'BorderType','none');
subfig_ax4 = uipanel('position',[0.09 0.03 0.28 0.5-0.03],'BorderType','none');
subfig_ax5 = uipanel('position',[0.09+0.28 0.03 0.28 0.5-0.03],'BorderType','none');
subfig_ax6 = uipanel('position',[0.09+0.54 0.0 0.28 0.5],'BorderType','none');
subfig_ax(1) = axes('Parent',subfig_ax1);
subfig_ax(2) = axes('Parent',subfig_ax2);
subfig_ax(3) = axes('Parent',subfig_ax3);
subfig_ax(4) = axes('Parent',subfig_ax4);
subfig_ax(5) = axes('Parent',subfig_ax5);
subfig_ax(6) = axes('Parent',subfig_ax6);

% Navigation buttons
uicontrol('Style','pushbutton','Position',[515 395 40 20],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyReleaseFcn', {@keyPress});
uicontrol('Style','pushbutton','Position',[515 370 40 20],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyReleaseFcn', {@keyPress});

% Cell classification
uicontrol('Style','text','Position',[515 300 40 15],'Units','normalized','String','Cell Classification','HorizontalAlignment','center');
colored_string = strcat('<html><font color="', classColorsHex' ,'">' ,classNames,' (', classNumbers, ')</font></html>');
listbox_cell_classification = uicontrol('Style','listbox','Position',[515 255 40 50],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyReleaseFcn', {@keyPress});

% Deep/Superficial
button_deepsuperficial = uicontrol('Style','pushbutton','Position',[515 160 40 20],'Units','normalized','String',['D/S: ', DeepSuperficial{ii}],'Callback',@(src,evnt)buttonDeepSuperficial,'KeyReleaseFcn', {@keyPress});

% Custom labels
button_labels = uicontrol('Style','pushbutton','Position',[515 110 40 20],'Units','normalized','String',['Label: ', cell_metrics.Labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyReleaseFcn', {@keyPress});

% Brain region
button_brainregion = uicontrol('Style','pushbutton','Position',[515 135 40 20],'Units','normalized','String',['Region: ', cell_metrics.BrainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyReleaseFcn', {@keyPress});

% Select unit from t-SNE space
uicontrol('Style','pushbutton','Position',[515 345 40 20],'Units','normalized','String','Select unit','Callback',@(src,evnt)buttonSelectFromPlot(),'KeyReleaseFcn', {@keyPress});

% Select group with polygon buttons
uicontrol('Style','pushbutton','Position',[515 320 40 20],'Units','normalized','String','Polygon','Callback',@(src,evnt)GroupSelectFromPlot,'KeyReleaseFcn', {@keyPress});

% Select subset of cell type
updateCellCount
uicontrol('Style','text','Position',[515 235 40 15],'Units','normalized','String','Display cell-types','HorizontalAlignment','center');
listbox_celltypes = uicontrol('Style','listbox','Position',[515 190 40 50],'Units','normalized','String',strcat(classNames,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(classNames),'Callback',@(src,evnt)buttonSelectSubset(),'KeyReleaseFcn', {@keyPress});

% ACG window size
button_ACG = uicontrol('Style','pushbutton','Position',[515 85 40 20],'Units','normalized','String','ACG 100ms','Callback',@(src,evnt)buttonACG(),'KeyReleaseFcn', {@keyPress});

% Show detected synaptic connections
button_SynMono = uicontrol('Style','pushbutton','Position',[515 60 40 20],'Units','normalized','String','MonoSyn: All','Callback',@(src,evnt)buttonMonoSyn(),'Visible','on','KeyReleaseFcn', {@keyPress});

% Load database session button
button_db = uicontrol('Style','pushbutton','Position',[515 35 40 20],'Units','normalized','String','Load dataset','Callback',@(src,evnt)LoadDatabaseSession(),'Visible','off','KeyReleaseFcn', {@keyPress});
if EnableDatabase
    button_db.Visible='On';
end

% Save classification
uicontrol('Style','pushbutton','Position',[515 10 40 20],'Units','normalized','String','Save classification','Callback',@(src,evnt)buttonSave,'KeyReleaseFcn', {@keyPress});

% Custom plotting menues
uicontrol('Style','text','Position',[10 385 45 10],'Units','normalized','String','Select X data','HorizontalAlignment','left');
uicontrol('Style','text','Position',[10 350 45 10],'Units','normalized','String','Select Y data','HorizontalAlignment','left');

popup_x = uicontrol('Style','popupmenu','Position',[5 375 40 10],'Units','normalized','String',fieldsMenu,'Value',20,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX());
popup_y = uicontrol('Style','popupmenu','Position',[5 340 40 10],'Units','normalized','String',fieldsMenu,'Value',25,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY());
popup_z = uicontrol('Style','popupmenu','Position',[5 305 40 10],'Units','normalized','String',fieldsMenu,'Value',18,'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ());

checkbox_logx = uicontrol('Style','checkbox','Position',[5 365 40 10],'Units','normalized','String','Log X scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotXLog());
checkbox_logy = uicontrol('Style','checkbox','Position',[5 330 40 10],'Units','normalized','String','Log Y scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotYLog());
checkbox_logz = uicontrol('Style','checkbox','Position',[5 295 40 10],'Units','normalized','String','Log Z scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZLog());
checkbox_showz = uicontrol('Style','checkbox','Position',[5 315 45 10],'Units','normalized','String','Show Z axis','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis());

% Table with metrics for selected cell
ui_table = uitable(fig,'Data',[fieldsMenu,num2cell(table_metrics(1,:)')],'Position',[10 30 150 575],'ColumnWidth',{85, 46},'columnname',{'Metrics',''},'RowName',[]);
checkbox_showtable = uicontrol('Style','checkbox','Position',[5 2 50 10],'Units','normalized','String','Show Metrics table','HorizontalAlignment','left','Value',1,'Callback',@(src,evnt)buttonShowMetrics());

% Terminal output line
ui_terminal = uicontrol('Style','text','Position',[60 2 320 10],'Units','normalized','String','','HorizontalAlignment','left','FontSize',10);

% Title line with name of current session
ui_title = uicontrol('Style','text','Position',[5 410 200 10],'Units','normalized','String',['Session: ', cell_metrics.General.basename,' with ', num2str(size(cell_metrics.TroughToPeak,2)), ' units'],'HorizontalAlignment','left','FontSize',13);
% ui_details = uicontrol('Style','text','Position',[5 400 200 10],'Units','normalized','String',{['Session: ', cell_metrics.General.basename],[num2str(size(cell_metrics_all.TroughToPeak,2)),', shank ']},'HorizontalAlignment','left','FontSize',15);


% % % % % % % % % % % % % % % % % % % % % %
% Main loop of UI
% % % % % % % % % % % % % % % % % % % % % %

while ii <= size(cell_metrics.TroughToPeak,2) & exit == 0
    if ~ishandle(fig)
        break
    end
    if strcmp(ui_table.Visible,'on')
        ui_table.Data = [fieldsMenu,num2cell(table_metrics(ii,:)')];
    end
    listbox_cell_classification.Value = clusClas(ii)+1;
    subset = find(ismember(clusClas,classes2plot));
    putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
    if ~isempty(putativeSubset)
        a1 = cell_metrics.PutativeConnections(putativeSubset,1);
        a2 = cell_metrics.PutativeConnections(putativeSubset,2);
        inbound = find(a2 == ii);
        outbound = find(a1 == ii);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax1.Children)
    subfig_ax(1) = axes('Parent',subfig_ax1);
    if customPlotHistograms == 0
        hold on
        xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
        %     title(['Custom metrics, Cluster ID: ' num2str(cell_metrics.CellID(ii))]),
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
        xlim auto, ylim auto, zlim auto
        if checkbox_logx.Value==1
            set(subfig_ax(1), 'XScale', 'log')
        else
            set(subfig_ax(1), 'XScale', 'linear')
        end
        if checkbox_logy.Value==1
            set(subfig_ax(1), 'YScale', 'log')
        else
            set(subfig_ax(1), 'YScale', 'linear')
        end
        
        if Plot3axis == 0
            view([0 90]);
            for jj = classes2plot
                scatter(plotX(find(clusClas==jj)), plotY(find(clusClas==jj)), 'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7)
            end
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20)
            
            
            switch MonoSynDisp
                case 'All'
                    if ~isempty(putativeSubset)
                        plot([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],'k')
                    end
                case 'Selected'
                    if ~isempty(putativeSubset)
                        plot([plotX(a1(inbound));plotX(a2(inbound))],[plotY(a1(inbound));plotY(a2(inbound))],'k')
                        plot([plotX(a1(outbound));plotX(a2(outbound))],[plotY(a1(outbound));plotY(a2(outbound))],'m')
                    end
            end
            
        else
            view([40 20]);
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
                    if ~isempty(putativeSubset)
                        plot3([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],[plotZ(a1);plotZ(a2)],'k')
                    end
                case 'Selected'
                    if ~isempty(putativeSubset)
                        plot3([plotX(a1(inbound));plotX(a2(inbound))],[plotY(a1(inbound));plotY(a2(inbound))],[plotZ(a1(inbound));plotZ(a2(inbound))],'k')
                        plot3([plotX(a1(outbound));plotX(a2(outbound))],[plotY(a1(outbound));plotY(a2(outbound))],[plotZ(a1(outbound));plotZ(a2(outbound))],'m')
                    end
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
        
    else
        % Double histogram with scatter plot
        hold off
        clr = classColors(intersect(classes2plot,clusClas(subset))+1,:);
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',clusClas(subset),'Kernel','on','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',subfig_ax1,'Legend','off','Color',clr); hold on % ,'Style','stairs'
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent',h_scatter(1))
            axis(h_scatter(1),'tight');
            if checkbox_logx.Value==1
                set(h_scatter(1), 'XScale', 'log')
                set(h_scatter(2), 'XScale', 'log')
            else
                set(h_scatter(1), 'XScale', 'linear')
                set(h_scatter(2), 'XScale', 'linear')
            end
            if checkbox_logy.Value==1
                set(h_scatter(1), 'YScale', 'log')
                set(h_scatter(3), 'XScale', 'log')
            else
                set(h_scatter(1), 'YScale', 'linear')
                set(h_scatter(3), 'XScale', 'linear')
            end
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 2
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax2.Children)
    subfig_ax(2) = axes('Parent',subfig_ax2);

    hold on,
    for jj = classes2plot
        scatter(cell_metrics.TroughToPeak(find(clusClas==jj)) * 1000, cell_metrics.BurstIndex_Royer2012(find(clusClas==jj)), -7*(log(cell_metrics.BurstIndex_Royer2012(find(clusClas==jj)))-10),...
            'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7,'Parent', subfig_ax(2));
    end
    ylabel('BurstIndex Royer2012'); xlabel('Trough-to-Peak (µs)'), title(['Unit ', num2str(ii),'/' num2str(size(cell_metrics.TroughToPeak,2)), '  Class: ', classNames{clusClas(ii)+1}])
    set(gca, 'YScale', 'log')
    
    % cell to check
    plot(cell_metrics.TroughToPeak(ii) * 1000, cell_metrics.BurstIndex_Royer2012(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent', subfig_ax(2));
    
    if ~isempty(putativeSubset)
        switch MonoSynDisp
            case 'All'
                plot([cell_metrics.TroughToPeak(a1);cell_metrics.TroughToPeak(a2)] * 1000,[cell_metrics.BurstIndex_Royer2012(a1);cell_metrics.BurstIndex_Royer2012(a2)],'k')
            case 'Selected'
                plot([cell_metrics.TroughToPeak(a1(inbound));cell_metrics.TroughToPeak(a2(inbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(inbound));cell_metrics.BurstIndex_Royer2012(a2(inbound))],'k')
                plot([cell_metrics.TroughToPeak(a1(outbound));cell_metrics.TroughToPeak(a2(outbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(outbound));cell_metrics.BurstIndex_Royer2012(a2(outbound))],'m')
        end
    end
    
    col= classColors(clusClas(ii)+1,:);
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax3.Children)
    subfig_ax(3) = axes('Parent',subfig_ax3);
    cla, hold on
    for jj = classes2plot
        scatter(tSNE_plot(find(clusClas==jj),1), tSNE_plot(find(clusClas==jj),2), 'MarkerFaceColor', classColors(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
    end
    
    %     plot(tSNE_plot(find(strcmp(DeepSuperficial,'Superficial') & ismember(clusClas,classes2plot)),1),tSNE_plot(find(strcmp(DeepSuperficial,'Superficial') & ismember(clusClas,classes2plot)),2),'sk')
    %     plot(tSNE_plot(find(strcmp(DeepSuperficial,'Deep') & ismember(clusClas,classes2plot)),1),tSNE_plot(find(strcmp(DeepSuperficial,'Deep') & ismember(clusClas,classes2plot)),2),'ok')
    plot(tSNE_plot(ii,1), tSNE_plot(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20);
    
    legend('off'), title('t-SNE Cell class visualization')
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 4
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax4.Children)
    subfig_ax(4) = axes('Parent',subfig_ax4);
    hold on, cla,
    time_waveforms = [1:size(cell_metrics.SpikeWaveforms,1)]/20-0.8;
    if strcmp(WaveformsPlot,'Single')
        patch([time_waveforms,flip(time_waveforms)]', [cell_metrics.SpikeWaveforms(:,ii)+cell_metrics.SpikeWaveforms_std(:,ii);flip(cell_metrics.SpikeWaveforms(:,ii)-cell_metrics.SpikeWaveforms_std(:,ii))],'black','EdgeColor','none','FaceAlpha',.2)
        plot(time_waveforms, cell_metrics.SpikeWaveforms(:,ii), 'color', col,'linewidth',2), grid on
        xlabel('Time (ms)'),title('Waveform (µV)'), axis tight, hLeg = legend({'Std','Wavefom'},'Location','southwest','Box','off'); set(hLeg,'visible','on');
    else
        for jj = intersect(clusClas,classes2plot)
            plot(time_waveforms, cell_metrics.SpikeWaveforms_zscored(:,find(clusClas==jj)), 'color', [classColors(jj+1,1:3),0.2])
        end
        plot(time_waveforms, cell_metrics.SpikeWaveforms_zscored(:,ii), 'color', 'k','linewidth',2), grid on
        xlabel('Time (ms)'),title('Waveform zscored'), axis tight, hLeg = legend('p'); set(hLeg,'visible','off');
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 5
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax5.Children)
    subfig_ax(5) = axes('Parent',subfig_ax5);
    hold on
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
    
    if plotACGfit
        a = cell_metrics.ACG_tau_decay(ii); b = cell_metrics.ACG_tau_rise(ii); c = cell_metrics.ACG_c(ii); d = cell_metrics.ACG_d(ii);
        e = cell_metrics.ACG_asymptote(ii); f = cell_metrics.ACG_refrac(ii); g = cell_metrics.ACG_tau_burst(ii); h = cell_metrics.ACG_h(ii);
        x = 1:0.2:50;
        fiteqn = max(c*exp(-(x-f)/a)-d*exp(-(x-f)/b)+e+h*exp(-(x-f)/g),0)*max(cell_metrics.ACG2(:,ii));
        plot([-flip(x),x],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
    end
    
    ax5 = axis; grid on
    plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); plot([ax5(1) ax5(2)],cell_metrics.FiringRate(ii)*[1 1],'--k')
    
    xlabel('ms'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.FiringRate(ii),3),'Hz'])
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 6
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax6.Children)
    subfig_ax(6) = axes('Parent',subfig_ax6);
    hold on
    if any(strcmp(CustomPlotOptions{CustomCellPlot},{'SWR','RippleCorrelogram'}))
        SpikeGroup = cell_metrics.SpikeGroup(ii);
        if SpikeGroup <= length(ripple_power)
            ripple_power_temp = ripple_power{SpikeGroup}/max(ripple_power{SpikeGroup}); grid on
            
            plot((ripple_amplitude{SpikeGroup}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{SpikeGroup},2)-1]*0.04,'-k','linewidth',2)
            
            for jj = 1:size(ripple_average{SpikeGroup},2)
                text(ripple_time_axis(end)+5,ripple_average{SpikeGroup}(1,jj)-(jj-1)*0.04,[num2str(round(DeepSuperficial_ChDistance(ripple_channels{SpikeGroup}(jj))))])
                %         text((ripple_power_temp(jj)*50)+ripple_time_axis(1)-50+12,-(jj-1)*0.04,num2str(ripple_channels{SpikeGroup}(jj)))
                if strcmp(DeepSuperficial_ChClass(ripple_channels{SpikeGroup}(jj)),'Superficial')
                    plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'r','linewidth',1)
                    plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'or','linewidth',2)
                elseif strcmp(DeepSuperficial_ChClass(ripple_channels{SpikeGroup}(jj)),'Deep')
                    plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'b','linewidth',1)
                    plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'ob','linewidth',2)
                else
                    plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'k')
                    plot((ripple_amplitude{SpikeGroup}(jj)*50)+ripple_time_axis(1)-50,-(jj-1)*0.04,'ok')
                end
            end
            
            if any(ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii))
                jjj = find(ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii));
                plot(ripple_time_axis,ripple_average{SpikeGroup}(:,jjj)-(jjj-1)*0.04,':k','linewidth',2)
            end
        end
        title(['SWR SpikeGroup ', num2str(SpikeGroup)]),xlabel('Time (ms)'), ylabel('Ripple (mV)')
        axis tight, ax6 = axis; grid on
        plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
        xlim([-220,ripple_time_axis(end)+50]), xticks([-120:40:120])
        ht1 = text(0.03,0.01,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
        ht2 = text(0.22,0.01,'Deep','Units','normalized','FontWeight','Bold','Color','b'); set(ht1,'Rotation',90), set(ht2,'Rotation',90)
        ht3 = text(0.97,0.01,'Depth (µm)','Units','normalized','Color','k'); set(ht1,'Rotation',90), set(ht3,'Rotation',90)
    elseif any(strcmp(CustomPlotOptions{CustomCellPlot},{'firing_rate_map'}))
        if isfield(cell_metrics,'firing_rate_map')
            plot(cell_metrics.firing_rate_map(:,ii),'color', col,'linewidth',2), title('Firing rate map'), xlabel('Position'),ylabel('Rate (Hz)'), hold on
            axis tight, ax6 = axis; grid on, hold on,
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            switch MonoSynDisp
                case {'All'}
                    plot(cell_metrics.firing_rate_map(:,a2(outbound)),'color', 'm')
                    plot(cell_metrics.firing_rate_map(:,a1(inbound)),'color', 'k')
                    plot(mean(cell_metrics.firing_rate_map(:,a1(inbound)),2),'color', 'k','linewidth',2)
                    plot(mean(cell_metrics.firing_rate_map(:,a2(outbound)),2),'color', 'm','linewidth',2)
                    
                case 'Selected'
                    plot(cell_metrics.firing_rate_map(:,a2(outbound)),'color', 'm')
                    plot(cell_metrics.firing_rate_map(:,a1(inbound)),'color', 'k')
            end
        end
        
        %     elseif strcmp(CustomCellPlot,'firing_rate_map2')
        %         if length(cell_metrics.firing_rate_map_states)>=ii && ~isempty(cell_metrics.firing_rate_map_states{ii})
        %             plot(cell_metrics.firing_rate_map_states{ii})
        %         end
        %         xlabel('Position'),ylabel('Rate (Hz)'), title('Firing rate map states'),
        %         axis tight, ax6 = axis; grid on, hold on,
        %         set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
    elseif strcmp(CustomPlotOptions{CustomCellPlot},'optoPSTH')
        if isfield(cell_metrics,'optoPSTH')
            plot([-1:0.1:1],cell_metrics.optoPSTH(:,ii),'color', col,'linewidth',2),
        end
        title('opto PSTH'), xlabel('Time (s)'),ylabel('Rate (Hz)')
        axis tight, ax6 = axis; grid on, hold on,
        plot([0, 0], [ax6(3) ax6(4)],'color','k');
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
        
    elseif strcmp(CustomPlotOptions{CustomCellPlot},'SWR Correllogram')
        plot([-200:200],cell_metrics.RippleCorrelogram(:,ii),'color', col,'linewidth',1), title('Ripple Correlogram'), xlabel('time'),ylabel('Voltage')
        axis tight, ax6 = axis; grid on, hold on,
        plot([0, 0], [ax6(3) ax6(4)],'color','k');
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
    else
        plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,ii),'color', col), title(CustomPlotOptions{CustomCellPlot}, 'Interpreter', 'none'), xlabel(''),ylabel('')
        axis tight, ax6 = axis; grid on, hold on,
        plot([0, 0], [ax6(3) ax6(4)],'color','k');
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
    end
    
    uiwait(fig);
    
end

% % % % % % % % % % % % % % % % % % % % % %
% Calls when closing
% % % % % % % % % % % % % % % % % % % % % %
if ishandle(fig)
    close(fig);
end
numeric_fields = fieldnames(cell_metrics);
cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
cell_metrics.DeepSuperficial = DeepSuperficial;
[C, ~, ic] = unique(clusClas+1,'sorted');
for i = 1:length(C)
    cell_metrics.PutativeCellType(find(ic==i)) = repmat({classNames{C(i)}},sum(ic==i),1);
end

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

    function buttonLabel
        Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{cell_metrics.Labels{ii}});
        if ~isempty(Label)
            cell_metrics.Labels{ii} = Label{1};
            button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
            ui_terminal.String = ['Label: Unit ', num2str(ii), ' labeled as ', Label{1}];
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
        choice = yourDlg(BrainRegions_list,find(strcmp(cell_metrics.BrainRegion{ii},BrainRegions_acronym)));
        if strcmp(choice,'')
            tf = 0;
        else
            indx = find(strcmp(choice,BrainRegions_list));
            tf = 1;
        end

%         [indx,tf] = listdlg('PromptString','Select brain region to assign to cell','Name','Brain region assignment','ListString',BrainRegions_list,'SelectionMode','single','InitialValue',find(strcmp(cell_metrics.BrainRegion{ii},BrainRegions_acronym)), 'ListSize',[550,250]);
        
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

    function choice = yourDlg(BrainRegions,InitBrainRegion)
        choice = '';
        BrainRegions_dialog = dialog('Position', [300, 300, 600, 350],'Name','Brain region assignment'); movegui(BrainRegions_dialog,'center')
        BrainRegionsList = uicontrol('Parent',BrainRegions_dialog,'Style', 'ListBox', 'String', BrainRegions, 'Position', [10, 50, 580, 220],'Value',InitBrainRegion);
        BrainRegionsTextfield = uicontrol('Parent',BrainRegions_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 580, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','left');
        uicontrol('Parent',BrainRegions_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','OK','Callback',@(src,evnt)CloseBrainRegions_dialog);
        uicontrol('Parent',BrainRegions_dialog,'Style','pushbutton','Position',[300, 10, 290, 30],'String','Cancel','Callback',@(src,evnt)CancelBrainRegions_dialog);
        uicontrol('Parent',BrainRegions_dialog,'Style', 'text', 'String', 'Search term', 'Position', [10, 325, 580, 20],'HorizontalAlignment','left');
        uicontrol('Parent',BrainRegions_dialog,'Style', 'text', 'String', 'Selct brain region below', 'Position', [10, 270, 580, 20],'HorizontalAlignment','left');
        uiwait(BrainRegions_dialog);
        function UpdateBrainRegionsList
            temp = contains(BrainRegions,BrainRegionsTextfield.String,'IgnoreCase',true);
            if ~any(temp == BrainRegionsList.Value)
                BrainRegionsList.Value = 1;
            end
            if ~isempty(temp)
                BrainRegionsList.String = BrainRegions(temp);
            else
                BrainRegionsList.String = {''};
            end
        end
        function  CloseBrainRegions_dialog
            if length(BrainRegionsList.String)>=BrainRegionsList.Value
                choice = BrainRegionsList.String(BrainRegionsList.Value);
            end
            delete(BrainRegions_dialog);
        end
        function  CancelBrainRegions_dialog
            choice = '';
            delete(BrainRegions_dialog);
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
        button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
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
        button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
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
            axnum = find(ismember(subfig_ax, gca))
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
            button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
            uiresume(fig);
        else
            ui_terminal.String = ['No units with selected classification'];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupSelectFromPlot
        if ~isempty(subset)
            ui_terminal.String = ['Select units by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.'];
            %             ax = gca;
            ax = get(fig,'CurrentAxes');
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
            ui_terminal.String = 'X-axis log. Negative data ignored';
        else
            ui_terminal.String = 'X-axis linear';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotYLog
        if checkbox_logy.Value==1
            ui_terminal.String = 'Y-axis log. Negative data ignored';
        else
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
        else
            Plot3axis = 0;
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

    function toggleCellPlotAdvance
        if CustomCellPlot ==size(CustomPlotOptions,1)
            CustomCellPlot = 1;
        else
            CustomCellPlot = CustomCellPlot+1;
        end
        plotstring = strcat(CustomPlotOptions,', ');
        ui_terminal.String = ['Displaying ', CustomPlotOptions{CustomCellPlot}, '. Available options: ', plotstring{:}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function togglePlotHistograms
        if customPlotHistograms ==0
            customPlotHistograms = 1;
            ui_terminal.String = ['Displaying histogram'];
        else
            customPlotHistograms = 0;
            ui_terminal.String = ['Regular plot'];
            delete(h_scatter)
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleCellPlotBack
        if CustomCellPlot == 1
            CustomCellPlot = size(CustomPlotOptions,1);
        else
            CustomCellPlot = CustomCellPlot-1;
        end
        ui_terminal.String = ['Displaying ' CustomPlotOptions{CustomCellPlot}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleWaveformPlot
        if strcmp(WaveformsPlot,'Single')
            WaveformsPlot = '';
            ui_terminal.String = 'Displaying all waveforms';
        else
            WaveformsPlot = 'Single';
            ui_terminal.String = 'Displaying single waveform with std';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleACGfit
        if plotACGfit == 1
            plotACGfit = 0;
            ui_terminal.String = 'Removing ACG fit';
        else
            plotACGfit = 1;
            ui_terminal.String = 'Plotting ACG fit';
        end
        uiresume(fig);
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
            case '9'
                buttonCellType(0);
            case 'a'
                buttonACG;
            case 'z'
                undoClassification;
            case 'uparrow'
                toggleCellPlotAdvance;
            case 'downarrow'
                toggleCellPlotBack;
            case 'l'
                buttonLabel;
            case 'w'
                toggleWaveformPlot;
            case 'h'
                togglePlotHistograms;
            case 'f'
                toggleACGfit;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function reclassify_celltypes
        % cell_classification_PutativeCellType
        cell_metrics.PutativeCellType = repmat({'Pyramidal Cell'},1,size(cell_metrics.CellID,2));
        
        % Interneuron classification
        cell_metrics.PutativeCellType(cell_metrics.ACG_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_decay>30),1);
        cell_metrics.PutativeCellType(cell_metrics.ACG_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_rise>3),1);
        cell_metrics.PutativeCellType(cell_metrics.TroughToPeak<=0.425  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.TroughToPeak<=0.425  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
        cell_metrics.PutativeCellType(cell_metrics.TroughToPeak>0.425  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.TroughToPeak>0.425  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
        
        % Pyramidal cell classification
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak<0.17 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 2'},sum(cell_metrics.derivative_TroughtoPeak<0.17 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak>0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 3'},sum(cell_metrics.derivative_TroughtoPeak>0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        cell_metrics.PutativeCellType(cell_metrics.derivative_TroughtoPeak>=0.17 & cell_metrics.derivative_TroughtoPeak<=0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 1'},sum(cell_metrics.derivative_TroughtoPeak>=0.17 & cell_metrics.derivative_TroughtoPeak<=0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function initializeSession
        ii = 1;
        if ~isfield(cell_metrics, 'Labels')
            cell_metrics.Labels = repmat({''},1,size(cell_metrics.CellID,2));
        end
        
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
        fieldsMenu(find(contains(fieldsMenu,'Labels')))=[];
        fieldsMenu(find(contains(fieldsMenu,'firing_rate_map_states')))=[];
        fieldsMenu(find(contains(fieldsMenu,'SpatialCoherence')))=[];
        
        for i = 1:length(fieldsMenu)
            if iscell(cell_metrics.(fieldsMenu{i})) && ~strcmp(fieldsMenu{i},'firing_rate_map_states')
                [cell_metrics.([fieldsMenu{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenu{i}));
                groups_ids.([fieldsMenu{i},'_num']) = ID;
            end
        end
        
        fieldsMenu = sort(fieldnames(cell_metrics));
        fields_to_keep = [];
        fieldsMenu(find(contains(fieldsMenu,'firing_rate_map_states')))=[];
        fieldsMenu(find(contains(fieldsMenu,'SpatialCoherence')))=[];
        fieldsMenu(find(contains(fieldsMenu,'PutativeConnections')))=[];
        for i = 1:length(fieldsMenu)
            if isnumeric(cell_metrics.(fieldsMenu{i})) && size(cell_metrics.(fieldsMenu{i}),1) == 1
                fields_to_keep(i) = 1;
            else
                fields_to_keep(i) = 0;
            end
        end
        
        fieldsMenu = fieldsMenu(find(fields_to_keep));
        fieldsMenu(find(contains(fieldsMenu,'General')))=[];
        
        % Metric table initialization
        table_metrics = [];
        for i = 1:size(fieldsMenu,1)
            table_metrics(:,i) = cell_metrics.(fieldsMenu{i});
        end
        
        % tSNE initialization
        X = [cell_metrics.FiringRate; cell_metrics.ThetaModulationIndex; cell_metrics.BurstIndex_Mizuseki2012; cell_metrics.TroughToPeak; cell_metrics.derivative_TroughtoPeak; cell_metrics.AB_ratio; cell_metrics.BurstIndex_Royer2012; cell_metrics.ACG_tau_rise; cell_metrics.ACG_tau_burst; cell_metrics.ACG_h; cell_metrics.ACG_tau_decay; cell_metrics.CV2; cell_metrics.BurstIndex_Doublets]; % cell_metrics.RippleModulationIndex; cell_metrics.RipplePeakDelay
        X(isnan(X) | isinf(X)) = 0;
        tSNE_plot = tsne(zscore(X'));
        
        % Setting initial settings for plots, popups and listboxes
        plotX = cell_metrics.FiringRate;
        plotY  = cell_metrics.PeakVoltage;
        plotZ  = cell_metrics.DeepSuperficialDistance;
        plotX_title = 'Firing rate (Hz)';
        plotY_title = 'Peak voltage (uV)';
        plotZ_title = 'Deep-Superficial depth (µm)';
        popup_x.Value = 20;
        popup_y.Value = 25;
        popup_z.Value = 18;
        
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
        % Button label
        button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
        
        cell_metrics.SpikeWaveforms_zscored = zscore(cell_metrics.SpikeWaveforms);
        WaveformsPlot = 'Single';
        
        CustomPlotOptions = fieldnames(cell_metrics);
        temp =  struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        temp1 = cell2mat(struct2cell(structfun(@(X) size(X,1), cell_metrics,'UniformOutput',false)));
        temp2 = cell2mat(struct2cell(structfun(@(X) size(X,2), cell_metrics,'UniformOutput',false)));
        
        CustomPlotOptions = ['SWR'; 'SWR Correllogram'; CustomPlotOptions( find(strcmp(temp,'double') & temp1>1 & temp2==size(cell_metrics.SpikeCount,2)))];
        CustomPlotOptions(find(contains(CustomPlotOptions,{'PutativeConnections','TruePositive','FalsePositive','ACG','ACG2','SpikeWaveform'})))=[];
        CustomCellPlot = 1;
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadDatabaseSession
        ui_terminal.String = ['Loading datasets from database...'];
        drawnow
        options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
        options.CertificateFilename=('');
        bz_db = webread('https://buzsakilab.com/wp/wp-json/frm/v2/views/15356/',options,'page_size','5000','sorted','1');
        sessions = loadjson(bz_db.renderedHtml);
        [db_menu_items,index] = sort(cellfun(@(x) x.Name,sessions,'UniformOutput',false));
        
        db_menu_values = cellfun(@(x) x.Id,sessions,'UniformOutput',false);
        db_menu_values = db_menu_values(index);
        db_menu_items2 = strcat(db_menu_items, ' (',db_menu_values, ')');
        ui_terminal.String = ['Datasets loaded from database'];
        
        [indx,tf] = listdlg('PromptString',['Select dataset to load'],'ListString',db_menu_items2,'SelectionMode','multiple','ListSize',[300,350]);
        if ~isempty(indx)
            if length(indx)==1
                %             id = db_menu_values{indx};
                try sessions = bz_load_sessions('session',db_menu_items{indx});
                    session = sessions{1};
                    LoadSession
                catch
                    warning('Failed to load dataset from database');
                    ui_terminal.String = [db_menu_items{indx},': Error loading dataset from database'];
                end
            else
                try cell_metrics = LoadCellMetricBatch('sessions',db_menu_items(indx));
                catch
                    warning('Failed to load all dataset from database');
                    ui_terminal.String = [db_menu_items(indx),': Error loading dataset from database'];
                end
                initializeSession
            end
        end
        %         end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadSession
        if isempty(session.SpikeSorting.RelativePath)
            clusteringpath = '';
        else
            clusteringpath = session.SpikeSorting.RelativePath{1};
        end
        
        if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))
            
            if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name,clusteringpath,'cell_metrics.mat'))
                
                if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name,'DeepSuperficial_ChClass.mat'))
                    cd(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name));
                    load(fullfile(clusteringpath,'cell_metrics.mat'));
                    
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
        answer = questdlg('Are you sure you want to save the classification', 'Save classification','Update existing metrics','Create new file', 'Cancel','Cancel');
        % Handle response
        switch answer
            case 'Update existing metrics'
                try saveMetrics(cell_metrics);
                catch exception
                    warning('Failed to save metrics');
                    disp(exception.identifier)
                    ui_terminal.String = ['Failed to save file - see Command Window for details'];
                    warndlg('Failed to save file - see Command Window for details','Warning');
                end
            case 'Create new file'
                if length(unique(cell_metrics.SpikeSortingID)) > 1
                    [file,SavePath] = uiputfile('cell_metrics_batch.mat','Save metrics');
                else
                    [file,SavePath] = uiputfile('cell_metrics.mat','Save metrics');
                end
                if SavePath ~= 0
                    try saveMetrics(cell_metrics,fullfile(SavePath,file));
                    catch exception
                        warning('Failed to save the file');
                        disp(exception.identifier)
                        ui_terminal.String = ['Failed to save file - see Command Window for details'];
                        warndlg('Failed to save file - see Command Window for details','Warning');
                    end
                end
            case 'Cancel'
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function saveMetrics(cell_metrics,file)
        ui_terminal.String = ['Saving metrics...'];
        drawnow
        numeric_fields = fieldnames(cell_metrics);
        cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
        cell_metrics.DeepSuperficial = DeepSuperficial;
        [C, ~, ic] = unique(clusClas+1,'sorted');
        for i = 1:length(C)
            cell_metrics.PutativeCellType(find(ic==i)) = repmat({classNames{C(i)}},sum(ic==i),1);
        end
        if nargin > 1
            save(file,'cell_metrics');
            ui_terminal.String = ['Classification saved to ', file];
            disp(['Classification saved to ', fullfile(pwd,file)]);
        elseif length(unique(cell_metrics.SpikeSortingID)) > 1
            disp('Saving cell metrics from batch')
            cell_metricsTemp = cell_metrics; clear cell_metrics
            for j = 1:length(cell_metricsTemp.General.Paths)
                cellSubset = find(cell_metricsTemp.BatchIDs==j);
                load(fullfile(cell_metricsTemp.General.Paths{j},'cell_metrics.mat'));
                if length(cellSubset) == size(cell_metrics.PutativeCellType,2)
                    cell_metrics.Labels = cell_metricsTemp.Labels(cellSubset);
                    cell_metrics.DeepSuperficial = cell_metricsTemp.DeepSuperficial(cellSubset);
                    cell_metrics.BrainRegion = cell_metricsTemp.BrainRegion(cellSubset);
                    cell_metrics.PutativeCellType = cell_metricsTemp.PutativeCellType(cellSubset);
                    save(fullfile(cell_metricsTemp.General.Paths{j},'cell_metrics.mat'),'cell_metrics')
                end
            end
            
            ui_terminal.String = ['Classifications succesfully saved to existing cell_metrics files'];
            disp('Classifications succesfully saved to existing cell_metrics files');
        else
            file = fullfile(clusteringpath,'cell_metrics.mat');
            save(file,'cell_metrics');
            ui_terminal.String = ['Classification saved to ', file];
            disp(['Classification saved to ', fullfile(pwd,file)]);
        end
        
    end

end

% % % % % % % % % % % % % % % % % % % % % %

function [ hex ] = rgb2hex(rgb)
% rgb2hex converts rgb color values to hex color format.
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
