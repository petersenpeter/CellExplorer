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
%
addParameter(p,'metrics',[],@isstruct);
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);

% Batch input
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'clusteringpaths',{},@iscell);

% Extra inputs
addParameter(p,'SWR',{},@iscell);

% Parsing inputs
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
SWR_in = p.Results.SWR;

% % % % % % % % % % % % % % % % % % % % % %
% Initialization
% % % % % % % % % % % % % % % % % % % % % %

PlotZLog = 0; Plot3axis = 0; db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = [];
classes2plot = []; classes2plotSubset = []; fieldsMenu = []; table_metrics = []; tSNE_plot = []; ii = []; history_classification = [];
BrainRegions_list = []; BrainRegions_acronym = []; cell_class_count = [];  CustomCellPlot = 1; CustomPlotOptions = '';
WaveformsPlot = ''; customPlotHistograms = 0; plotACGfit = 0; basename = ''; clasLegend = 0; Colorval = 1; plotClas = [];
ColorMenu = []; groups2plot = []; groups2plot2 = []; plotClasGroups2 = []; exit = 0; tSNE_fields = ''; MonoSynDispIn = '';
plotXdata = 'FiringRate'; plotYdata = 'PeakVoltage'; plotZdata = 'DeepSuperficialDistance'; DisplayMetricsTable = 0;
Colorstr = []; popup_customplot = []; WaveformsPlotIn = 'Single'; ACGPlotIn = 'Single'; deepSuperficialNames = ''; 
ACG_type = 'Normal'; MonoSynDisp = ''; MonoSynDisp = '';  ACGPlot = '';  tSNE_ACG2 = [];  tSNE_SpikeWaveforms = []; 

fig = figure('KeyReleaseFcn', {@keyPress},'Name','Cell inspector','NumberTitle','off','renderer','opengl');


% % % % % % % % % % % % % % % % % % % % % %
% User preferences for the Cell-inspector
% % % % % % % % % % % % % % % % % % % % % %

CellInspector_Preferences

classColorsHex = rgb2hex(classColors*0.7);
classColorsHex = cellstr(classColorsHex(:,2:end));
classNumbers = cellstr(num2str([1:length(classNames)]'))';
plotClasGroups = classNames;

warning('off','MATLAB:deblank:NonStringInput') 
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame') 
% % % % % % % % % % % % % % % % % % % % % % 
% Database initialization
% % % % % % % % % % % % % % % % % % % % % %

if exist('db_credentials') == 2
    bz_database = db_credentials;
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
            try
                [session, basename, basepath, clusteringpath] = db_set_path('id',id,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
        else
            try
                [session, basename, basepath, clusteringpath] = db_set_path('session',sessionin,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
            
        end
        try
            LoadSession
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
        try
            cell_metrics = LoadCellMetricBatch('sessionIDs',sessionIDs);
            initializeSession
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
        try
            cell_metrics = LoadCellMetricBatch('sessions',sessionsin);
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
    try
        cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths);
        initializeSession
    catch
        warning('Failed to load dataset');
        return
    end
elseif ~isempty(basepaths)
    clusteringpaths = basepaths;
    try
        cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths);
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
        if EnableDatabase
            LoadDatabaseSession;
        else
            warning('Neither session.mat or cell_metrics.mat exist in base folder')
            return
        end
    end
    
end

% % % % % % % % % % % % % % % % % % % % % %
% UI initialization
% % % % % % % % % % % % % % % % % % % % % %

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

pannel_Navigation = uipanel('Title','Navigation','TitlePosition','centertop','FontSize',12,'Position',[0.895 0.89 0.1 0.105],'Units','normalized');
pannel_CellAssignment = uipanel('Title','Cell assignments','TitlePosition','centertop','FontSize',12,'Position',[0.895 0.50 0.1 0.385],'Units','normalized');
pannel_DisplaySettings = uipanel('Title','Display Settings','TitlePosition','centertop','FontSize',12,'Position',[0.895 0.125 0.1 0.37],'Units','normalized');
pannel_LoadSave = uipanel('Title','File handling','TitlePosition','centertop','FontSize',12,'Position',[0.895 0.01 0.1 0.105],'Units','normalized');

% Navigation buttons
uicontrol('Parent',pannel_Navigation,'Style','pushbutton','Position',[2 15 24 12],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyReleaseFcn', {@keyPress});
uicontrol('Parent',pannel_Navigation,'Style','pushbutton','Position',[27 15 24 12],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyReleaseFcn', {@keyPress});

% Select cell from spaces & group with polygon buttons
uicontrol('Parent',pannel_Navigation,'Style','pushbutton','Position',[2 2 24 12],'Units','normalized','String','+ Select','Callback',@(src,evnt)buttonSelectFromPlot,'KeyReleaseFcn', {@keyPress});
uicontrol('Parent',pannel_Navigation,'Style','pushbutton','Position',[27 2 24 12],'Units','normalized','String','GoTo','Callback',@(src,evnt)goToCell,'KeyReleaseFcn', {@keyPress});

% Cell classification
% uicontrol('Parent',pannel_CellAssignment,'Style','text','Position',[2 142 50 10],'Units','normalized','String','Cell-type','HorizontalAlignment','center');
colored_string = strcat('<html><font color="', classColorsHex' ,'">' ,classNames,' (', classNumbers, ')</font></html>');
listbox_cell_classification = uicontrol('Parent',pannel_CellAssignment,'Style','listbox','Position',[2 100 50 45],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyReleaseFcn', {@keyPress});
uicontrol('Parent',pannel_CellAssignment,'Style','pushbutton','Position',[2 80 50 15],'Units','normalized','String','Select group from plots','Callback',@(src,evnt)GroupSelectFromPlot,'KeyReleaseFcn', {@keyPress});

% Deep/Superficial
uicontrol('Parent',pannel_CellAssignment,'Style','text','Position',[2 67 50 10],'Units','normalized','String','Deep-Superficial','HorizontalAlignment','center');
listbox_deepsuperficial = uicontrol('Parent',pannel_CellAssignment,'Style','listbox','Position',[2 40 50 30],'Units','normalized','String',deepSuperficialNames,'max',1,'min',1,'Value',cell_metrics.DeepSuperficial_num(ii),'Callback',@(src,evnt)buttonDeepSuperficial,'KeyReleaseFcn', {@keyPress});

% Brain region
button_brainregion = uicontrol('Parent',pannel_CellAssignment,'Style','pushbutton','Position',[2 20 50 15],'Units','normalized','String',['Region: ', cell_metrics.BrainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyReleaseFcn', {@keyPress});

% Custom labels
button_labels = uicontrol('Parent',pannel_CellAssignment,'Style','pushbutton','Position',[2 3 50 15],'Units','normalized','String',['Label: ', cell_metrics.Labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyReleaseFcn', {@keyPress});


% Select subset of cell type
updateCellCount
uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[2 129 50 10],'Units','normalized','String','Cell-types','HorizontalAlignment','center');
listbox_celltypes = uicontrol('Parent',pannel_DisplaySettings,'Style','listbox','Position',[2 82 50 50],'Units','normalized','String',strcat(classNames,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(classNames),'Callback',@(src,evnt)buttonSelectSubset(),'KeyReleaseFcn', {@keyPress});

% Navigate custom plot
uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[2 69 50 10],'Units','normalized','String','Custom plot options','HorizontalAlignment','center');
popup_customplot = uicontrol('Parent',pannel_DisplaySettings,'Style','popupmenu','Position',[2 62 50 10],'Units','normalized','String',CustomPlotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)CustomCellPlotFunc,'KeyReleaseFcn', {@keyPress});

% Changing Waveform and ACG view
uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[2 49 25 10],'Units','normalized','String','Waveforms','HorizontalAlignment','center');
popup_waveforms = uicontrol('Parent',pannel_DisplaySettings,'Style','popupmenu','Position',[2 42 25 10],'Units','normalized','String',{'Single','All','tSNE'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleWaveformsPlot,'KeyReleaseFcn', {@keyPress});
if strcmp(WaveformsPlotIn,'Single'); popup_waveforms.Value = 1; elseif strcmp(WaveformsPlotIn,'All'); popup_waveforms.Value = 2; else; popup_waveforms.Value = 3; end

uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[27 49 25 10],'Units','normalized','String','ACGs','HorizontalAlignment','center');
popup_ACGs = uicontrol('Parent',pannel_DisplaySettings,'Style','popupmenu','Position',[27 42 25 10],'Units','normalized','String',{'Single','All','tSNE'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleACGplot,'KeyReleaseFcn', {@keyPress});
if strcmp(ACGPlotIn,'Single'); popup_ACGs.Value = 1; elseif strcmp(ACGPlotIn,'All'); popup_ACGs.Value = 2; else; popup_ACGs.Value = 3; end

% Show detected synaptic connections
uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[2 29 25 10],'Units','normalized','String','MonoSyn','HorizontalAlignment','center');
popup_SynMono = uicontrol('Parent',pannel_DisplaySettings,'Style','popupmenu','Position',[2 22 25 10],'Units','normalized','String',{'None','Selected','All'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)buttonMonoSyn,'KeyReleaseFcn', {@keyPress});

% ACG window size
uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[27 29 25 10],'Units','normalized','String','ACG window','HorizontalAlignment','center');
popup_ACG = uicontrol('Parent',pannel_DisplaySettings,'Style','popupmenu','Position',[27 22 25 10],'Units','normalized','String',{'30ms','100ms','1s'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)buttonACG,'KeyReleaseFcn', {@keyPress});
if strcmp(ACG_type,'Normal'); popup_ACG.Value = 2; elseif strcmp(ACG_type,'Narrow'); popup_ACG.Value = 1; else; popup_ACG.Value = 3; end

uicontrol('Parent',pannel_DisplaySettings,'Style','text','Position',[2 9 50 10],'Units','normalized','String','Display synaptic connections','HorizontalAlignment','center');
checkbox_SynMono1 = uicontrol('Parent',pannel_DisplaySettings,'Style','checkbox','Position',[3 2 20 10],'Units','normalized','String','Custom','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(fig));
checkbox_SynMono2 = uicontrol('Parent',pannel_DisplaySettings,'Style','checkbox','Position',[21 2 20 10],'Units','normalized','String','Classic','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(fig));
checkbox_SynMono3 = uicontrol('Parent',pannel_DisplaySettings,'Style','checkbox','Position',[38 2 18 10],'Units','normalized','String','tSNE','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(fig));

% Load database session button
button_db = uicontrol('Parent',pannel_LoadSave,'Style','pushbutton','Position',[2 15 50 12],'Units','normalized','String','Load dataset from database','Callback',@(src,evnt)LoadDatabaseSession(),'Visible','off','KeyReleaseFcn', {@keyPress});
if EnableDatabase
    button_db.Visible='On';
end

% Save classification
uicontrol('Parent',pannel_LoadSave,'Style','pushbutton','Position',[2 2 50 12],'Units','normalized','String','Save classification','Callback',@(src,evnt)buttonSave,'KeyReleaseFcn', {@keyPress});



% Custom plotting menues
uicontrol('Style','text','Position',[8 385 45 10],'Units','normalized','String','Select X data','HorizontalAlignment','left');
uicontrol('Style','text','Position',[8 350 45 10],'Units','normalized','String','Select Y data','HorizontalAlignment','left');

popup_x = uicontrol('Style','popupmenu','Position',[5 375 50 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX());
popup_y = uicontrol('Style','popupmenu','Position',[5 340 50 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY());
popup_z = uicontrol('Style','popupmenu','Position',[5 305 50 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ());

checkbox_logx = uicontrol('Style','checkbox','Position',[5 365 45 10],'Units','normalized','String','Log X scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotXLog());
checkbox_logy = uicontrol('Style','checkbox','Position',[5 330 45 10],'Units','normalized','String','Log Y scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotYLog());
checkbox_logz = uicontrol('Style','checkbox','Position',[5 295 45 10],'Units','normalized','String','Log Z scale','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZLog());
checkbox_showz = uicontrol('Style','checkbox','Position',[5 315 45 10],'Units','normalized','String','Show Z axis','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis());

% Custom colors
uicontrol('Style','text','Position',[10 280 45 10],'Units','normalized','String','Select color group','HorizontalAlignment','left');
popup_groups = uicontrol('Style','popupmenu','Position',[5 270 45 10],'Units','normalized','String',ColorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(),'KeyReleaseFcn', {@keyPress});
listbox_groups = uicontrol('Style','listbox','Position',[5 215 45 50],'Units','normalized','String',{'Type 1','Type 2','Type 3'},'max',10,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyReleaseFcn', {@keyPress},'Visible','Off');
checkbox_groups = uicontrol('Style','checkbox','Position',[5 205 45 10],'Units','normalized','String','Group by cell types','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(),'KeyReleaseFcn', {@keyPress},'Visible','Off');

% Table with metrics for selected cell
ui_table = uitable(fig,'Data',[fieldsMenu,num2cell(table_metrics(1,:)')],'Position',[10 30 150 575],'ColumnWidth',{85, 46},'columnname',{'Metrics',''},'RowName',[]);
checkbox_showtable = uicontrol('Style','checkbox','Position',[5 2 50 10],'Units','normalized','String','Show Metrics table','HorizontalAlignment','left','Value',1,'Callback',@(src,evnt)buttonShowMetrics());
if DisplayMetricsTable==0; ui_table.Visible='Off'; checkbox_showtable.Value = 0; end

% Terminal output line
ui_terminal = uicontrol('Style','text','Position',[60 2 320 10],'Units','normalized','String','Welcome to the Cell-Inspector. Press H to learn keyboard shortcuts.','HorizontalAlignment','left','FontSize',10);

% Title line with name of current session
ui_title = uicontrol('Style','text','Position',[5 410 200 10],'Units','normalized','String',['Session: ', cell_metrics.General.basename,' with ', num2str(size(cell_metrics.TroughToPeak,2)), ' cells'],'HorizontalAlignment','left','FontSize',13);
% ui_details = uicontrol('Style','text','Position',[5 400 200 10],'Units','normalized','String',{['Session: ', cell_metrics.General.basename],[num2str(size(cell_metrics_all.TroughToPeak,2)),', shank ']},'HorizontalAlignment','left','FontSize',15);

% Maximazing figure
if ~verLessThan('matlab', '9.4')
    set(fig,'WindowState','maximize')
else 
    drawnow; frame_h = get(fig,'JavaFrame'); set(frame_h,'Maximized',1); % 
end

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
    listbox_cell_classification.Value = clusClas(ii);
    subset = find(ismember(clusClas,classes2plot));
    
    if ~isempty(groups2plot2) & Colorval ~=1
        if checkbox_groups.Value == 0
            subset2 = find(ismember(plotClas,groups2plot2));
        else
            subset2 = find(ismember(plotClas2,groups2plot2));
        end
        subset = intersect(subset,subset2);
    end
    if isfield(cell_metrics,'PutativeConnections')
        putativeSubset = find(sum(ismember(cell_metrics.PutativeConnections,subset)')==2);
    else
        putativeSubset=[];
    end
    if ~isempty(putativeSubset)
        a1 = cell_metrics.PutativeConnections(putativeSubset,1);
        a2 = cell_metrics.PutativeConnections(putativeSubset,2);
        inbound = find(a2 == ii);
        outbound = find(a1 == ii);
    end
    
    % Group display definition
    
    if Colorval == 1
        clr = classColors(intersect(classes2plot,clusClas(subset)),:);
    else
        clr = hsv(length(nanUnique(plotClas(subset))))*0.8;
        %         clr = classColors(1:length(nanUnique(plotClas(subset))),:);
    end
    classes2plotSubset = intersect(plotClas(subset),classes2plot);
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    if customPlotHistograms == 0
        axes(subfig_ax1.Children);
        [az,el] = view;
    end
    delete(subfig_ax1.Children)
    subfig_ax(1) = axes('Parent',subfig_ax1);
    if customPlotHistograms == 0
        hold on
        xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
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
            if ~isempty(clr)
                gscatter(plotX(subset), plotY(subset), plotClas(subset), clr,'',20,'off')
            end
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 2, 'MarkerSize',20)
            
            if  checkbox_SynMono1.Value == 1
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
            end
            
        else
            view([az,el]);
            %             view([40 20]);
            if PlotZLog == 1
                set(gca, 'ZScale', 'log')
            else
                set(gca, 'ZScale', 'linear')
            end
            
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                scatter3(plotX(set1), plotY(set1), plotZ(set1), 'MarkerFaceColor', clr(jj,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
            end
            plot3(plotX(ii), plotY(ii), plotZ(ii),'xk', 'LineWidth', 2, 'MarkerSize',20)
            
            if  checkbox_SynMono1.Value == 1
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
        [az,el] = view;
    elseif customPlotHistograms == 1
        % Double histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',plotClas(subset),'Kernel','on','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',subfig_ax1,'Legend','off','Color',clr); hold on % ,'Style','stairs'
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
    else
        % Double histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',plotClas(subset),'Style','stairs','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',subfig_ax1,'Legend','off','Color',clr); hold on % ,
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent',h_scatter(1))
            if length(unique(plotClas(subset)))==2
                G1 = plotX(subset);
                G = findgroups(plotClas(subset));
                if length(subset(G==1))>0 && length(subset(G==2))>0
                    [h,p] = kstest2(plotX(subset(G==1)),plotX(subset(G==2)));
                    text(1.04,0.01,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90)
                    [h,p] = kstest2(plotY(subset(G==1)),plotY(subset(G==2)));
                    text(0.01,1.04,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized')
                end
            end
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
    if ~isempty(clr)
        legendscatter = gscatter(cell_metrics.TroughToPeak(subset) * 1000, cell_metrics.BurstIndex_Royer2012(subset), plotClas(subset), clr,'',25,'off');
    end

    %     for jj = classes2plot
    %         scatter(cell_metrics.TroughToPeak(subset) * 1000, cell_metrics.BurstIndex_Royer2012(subset), 45,...
    %             'MarkerFaceColor', clr(jj+1,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7,'Parent', subfig_ax(2));
    %     end
    ylabel('BurstIndex Royer2012'); xlabel('Trough-to-Peak (µs)'), title(['Cell ', num2str(ii),'/' num2str(size(cell_metrics.TroughToPeak,2)), '  Class: ', classNames{clusClas(ii)}])
    set(gca, 'YScale', 'log'); axis tight
    
    % cell to check
    plot(cell_metrics.TroughToPeak(ii) * 1000, cell_metrics.BurstIndex_Royer2012(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent', subfig_ax(2));
    
    if ~isempty(putativeSubset) && checkbox_SynMono2.Value == 1
        switch MonoSynDisp
            case 'All'
                plot([cell_metrics.TroughToPeak(a1);cell_metrics.TroughToPeak(a2)] * 1000,[cell_metrics.BurstIndex_Royer2012(a1);cell_metrics.BurstIndex_Royer2012(a2)],'k')
            case 'Selected'
                plot([cell_metrics.TroughToPeak(a1(inbound));cell_metrics.TroughToPeak(a2(inbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(inbound));cell_metrics.BurstIndex_Royer2012(a2(inbound))],'k')
                plot([cell_metrics.TroughToPeak(a1(outbound));cell_metrics.TroughToPeak(a2(outbound))] * 1000,[cell_metrics.BurstIndex_Royer2012(a1(outbound));cell_metrics.BurstIndex_Royer2012(a2(outbound))],'m')
        end
    end
    if ~isempty(subset)
        legend(legendscatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northwest','Box','off','AutoUpdate','off');
    end
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax3.Children)
    subfig_ax(3) = axes('Parent',subfig_ax3);
    cla, hold on
    if ~isempty(clr)
        gscatter(tSNE_plot(subset,1), tSNE_plot(subset,2), plotClas(subset), clr,'',20,'off');
    end
    plot(tSNE_plot(ii,1), tSNE_plot(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20); axis tight
    
    if checkbox_SynMono3.Value == 1
        plotX1 = tSNE_plot(subset,1)';
        plotY1 = tSNE_plot(subset,2)';
        switch MonoSynDisp
            case 'All'
                if ~isempty(putativeSubset)
                    plot([plotX1(a1);plotX1(a2)],[plotY1(a1);plotY1(a2)],'k')
                end
            case 'Selected'
                if ~isempty(putativeSubset)
                    plot([plotX1(a1(inbound));plotX1(a2(inbound))],[plotY1(a1(inbound));plotY1(a2(inbound))],'k')
                    plot([plotX1(a1(outbound));plotX1(a2(outbound))],[plotY1(a1(outbound));plotY1(a2(outbound))],'m')
                end
        end
    end
    
    legend('off'), title('t-SNE Cell class visualization')
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 4
    % % % % % % % % % % % % % % % % % % % % % %
    
    col = classColors(clusClas(ii),:);
    delete(subfig_ax4.Children)
    subfig_ax(4) = axes('Parent',subfig_ax4);
    hold on, cla,
    time_waveforms = [1:size(cell_metrics.SpikeWaveforms,1)]/20-0.8;
    if strcmp(WaveformsPlot,'Single')
        patch([time_waveforms,flip(time_waveforms)]', [cell_metrics.SpikeWaveforms(:,ii)+cell_metrics.SpikeWaveforms_std(:,ii);flip(cell_metrics.SpikeWaveforms(:,ii)-cell_metrics.SpikeWaveforms_std(:,ii))],'black','EdgeColor','none','FaceAlpha',.2)
        plot(time_waveforms, cell_metrics.SpikeWaveforms(:,ii), 'color', col,'linewidth',2), grid on
        xlabel('Time (ms)'),title('Waveform (µV)'), axis tight, hLeg = legend({'Std','Wavefom'},'Location','southwest','Box','off'); set(hLeg,'visible','on');
    elseif strcmp(WaveformsPlot,'All')
        for jj = 1:length(classes2plotSubset)
            set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
            plot(time_waveforms, cell_metrics.SpikeWaveforms_zscored(:,set1), 'color', [clr(jj,:),0.2])
        end
        plot(time_waveforms, cell_metrics.SpikeWaveforms_zscored(:,ii), 'color', 'k','linewidth',2), grid on
        xlabel('Time (ms)'),title('Waveform zscored'), axis tight, hLeg = legend('p'); set(hLeg,'visible','off');
    elseif strcmp(WaveformsPlot,'tSNE')
        gscatter(tSNE_SpikeWaveforms(subset,1), tSNE_SpikeWaveforms(subset,2), plotClas(subset), clr,'',20,'off');
        title('Waveforms - tSNE visualization'), axis tight, xlabel(''),ylabel(''), hold on
        plot(tSNE_SpikeWaveforms(ii,1), tSNE_SpikeWaveforms(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 5
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax5.Children)
    subfig_ax(5) = axes('Parent',subfig_ax5);
    hold on
    if strcmp(ACGPlot,'Single')
        if strcmp(ACG_type,'Normal')
            bar([-100:100]/2,cell_metrics.ACG2(:,ii),1,'FaceColor',col,'EdgeColor',col)
            xticks([-50:10:50]),xlim([-50,50])
        elseif strcmp(ACG_type,'Narrow')
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
            fiteqn = max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0);
            plot([-flip(x),x],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
        end
        
        ax5 = axis; grid on
        plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); plot([ax5(1) ax5(2)],cell_metrics.FiringRate(ii)*[1 1],'--k')
        
        xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.FiringRate(ii),3),'Hz'])
    elseif strcmp(ACGPlot,'All')
        if strcmp(ACG_type,'Normal')
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                plot([-100:100]/2,cell_metrics.ACG2(:,set1), 'color', [clr(jj,:),0.2])
            end
            plot([-100:100]/2,cell_metrics.ACG2(:,ii), 'color', 'k','linewidth',1.5)
            xticks([-50:10:50]),xlim([-50,50])
        elseif strcmp(ACG_type,'Narrow')
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                plot([-30:30]/2,cell_metrics.ACG2(41+30:end-40-30,set1), 'color', [clr(jj,:),0.2])
            end
            plot([-30:30]/2,cell_metrics.ACG2(41+30:end-40-30,ii), 'color', 'k','linewidth',1.5)
            xticks([-15:5:15]),xlim([-15,15])
        else
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                plot([-500:500],cell_metrics.ACG(:,set1), 'color', [clr(jj,:),0.2])
            end
            plot([-500:500],cell_metrics.ACG(:,ii), 'color', 'k','linewidth',1.5)
            xticks([-500:100:500]),xlim([-500,500])
        end
        xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.FiringRate(ii),3),'Hz'])
    elseif strcmp(ACGPlot,'tSNE')
        gscatter(tSNE_ACG2(subset,1), tSNE_ACG2(subset,2), plotClas(subset), clr,'',20,'off');
        title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel(''), hold on
        plot(tSNE_ACG2(ii,1), tSNE_ACG2(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 6
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(subfig_ax6.Children)
    subfig_ax(6) = axes('Parent',subfig_ax6);
    hold on
    if any(strcmp(CustomPlotOptions{CustomCellPlot},{'SWR','RippleCorrelogram'}))
        if length(SWR_batch)>1
            SWR = SWR_batch{cell_metrics.BatchIDs(ii)};
        else
            SWR = SWR_batch;
        end
        SpikeGroup = cell_metrics.SpikeGroup(ii);
        if isfield(SWR,'SWR_diff') && SpikeGroup <= length(SWR.ripple_power)
            ripple_power_temp = SWR.ripple_power{SpikeGroup}/max(SWR.ripple_power{SpikeGroup}); grid on
            
            plot((SWR.SWR_diff{SpikeGroup}*50)+SWR.ripple_time_axis(1)-50,-[0:size(SWR.SWR_diff{SpikeGroup},2)-1]*0.04,'-k','linewidth',2)
            
            for jj = 1:size(SWR.ripple_average{SpikeGroup},2)
                text(SWR.ripple_time_axis(end)+5,SWR.ripple_average{SpikeGroup}(end,jj)-(jj-1)*0.04,[num2str(round(SWR.DeepSuperficial_ChDistance(SWR.ripple_channels{SpikeGroup}(jj))))])
                %         text((ripple_power_temp(jj)*50)+SWR.ripple_time_axis(1)-50+12,-(jj-1)*0.04,num2str(SWR.ripple_channels{SpikeGroup}(jj)))
                if strcmp(SWR.DeepSuperficial_ChClass(SWR.ripple_channels{SpikeGroup}(jj)),'Superficial')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'r','linewidth',1)
                    plot((SWR.SWR_diff{SpikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'or','linewidth',2)
                elseif strcmp(SWR.DeepSuperficial_ChClass(SWR.ripple_channels{SpikeGroup}(jj)),'Deep')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'b','linewidth',1)
                    plot((SWR.SWR_diff{SpikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'ob','linewidth',2)
                elseif strcmp(SWR.DeepSuperficial_ChClass(SWR.ripple_channels{SpikeGroup}(jj)),'Cortical')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'g','linewidth',1)
                    plot((SWR.SWR_diff{SpikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'og','linewidth',2)
                else
                    plot(SWR.ripple_time_axis,SWR.ripple_average{SpikeGroup}(:,jj)-(jj-1)*0.04,'k')
                    plot((SWR.SWR_diff{SpikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'ok')
                end
            end
            
            if any(SWR.ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii))
                jjj = find(SWR.ripple_channels{SpikeGroup} == cell_metrics.MaxChannel(ii));
                plot(SWR.ripple_time_axis,SWR.ripple_average{SpikeGroup}(:,jjj)-(jjj-1)*0.04,':k','linewidth',2)
            end
            axis tight, ax6 = axis; grid on
            plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
            xlim([-220,SWR.ripple_time_axis(end)+50]), xticks([-120:40:120])
            title(['SWR SpikeGroup ', num2str(SpikeGroup)]),xlabel('Time (ms)'), ylabel('Ripple (mV)')
            ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
            ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
            ht3 = text(0.98,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
        end
        
    elseif any(strcmp(CustomPlotOptions{CustomCellPlot},{'Firing rate map'}))
        if isfield(cell_metrics,'firing_rate_map') && ~isempty(cell_metrics.firing_rate_map{ii})
            firing_rate_map = cell_metrics.firing_rate_map{ii};
            plot([1:size(firing_rate_map,1)]*3,firing_rate_map,'color', col,'linewidth',2), xlabel('Position (cm)'),ylabel('Rate (Hz)'), hold on
            hold on
            switch MonoSynDisp
                case {'All'}
                    if ~isempty(outbound)
                        plot([1:length(firing_rate_map)]*3,horzcat(cell_metrics.firing_rate_map{a2(outbound)}),'color', 'm')
                        plot([1:length(firing_rate_map)]*3,mean(horzcat(cell_metrics.firing_rate_map{a2(outbound)}),2),'color', 'm','linewidth',2)
                    end
                    if ~isempty(inbound)
                        plot([1:length(firing_rate_map)]*3,horzcat(cell_metrics.firing_rate_map{a1(inbound)}),'color', 'k')
                        plot([1:length(firing_rate_map)]*3,mean(horzcat( cell_metrics.firing_rate_map{a1(inbound)}),2),'color', 'k','linewidth',2)
                        
                    end
                case 'Selected'
                    if ~isempty(outbound)
                        plot([1:length(firing_rate_map)]*3,horzcat(cell_metrics.firing_rate_map{a2(outbound)}),'color', 'm')
                    end
                    if ~isempty(inbound)
                        plot([1:length(firing_rate_map)]*3,horzcat(cell_metrics.firing_rate_map{a1(inbound)}),'color', 'k')
                    end
            end
            axis tight, ax6 = axis; grid on,
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            plot([45, 45;130,130]', [ax6(3) ax6(4)],'--','color','k');
        else
            text(0.5,0.5,'No firing rate map for this cell','FontWeight','bold','HorizontalAlignment','center')
        end
        title('Firing rate map')
        
    elseif strcmp(CustomPlotOptions{CustomCellPlot},'optoPSTH')
        if isfield(cell_metrics,'optoPSTH') && any(~isnan(cell_metrics.optoPSTH(:,ii)))
            plot([-1:0.1:1],cell_metrics.optoPSTH(:,ii),'color', col,'linewidth',2),
            axis tight, ax6 = axis; grid on, hold on,
            plot([0, 0], [ax6(3) ax6(4)],'color','k');
        else
            text(0.5,0.5,'No PSTH for this cell','FontWeight','bold','HorizontalAlignment','center')
        end
        title('opto PSTH'), xlabel('Time (s)'),ylabel('Rate (Hz)')
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
        
    elseif strcmp(CustomPlotOptions{CustomCellPlot},'SWR Correllogram')
        plot([-200:200],cell_metrics.RippleCorrelogram(:,ii),'color', col,'linewidth',1), title('Ripple Correlogram'), xlabel('time'),ylabel('Voltage')
        axis tight, ax6 = axis; grid on, hold on,
        plot([0, 0], [ax6(3) ax6(4)],'color','k');
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
    else
        plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,ii),'color', col,'linewidth',2), hold on
        switch MonoSynDisp
            case {'All'}
                if ~isempty(outbound)
                    plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a2(outbound)),'color', 'm')
                    plot(mean(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a2(outbound)),2),'color', 'm','linewidth',2)
                end
                if ~isempty(inbound)
                    plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a1(inbound)),'color', 'k')
                    plot(mean(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a1(inbound)),2),'color', 'k','linewidth',2)
                    
                end
            case 'Selected'
                if ~isempty(outbound)
                    plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a2(outbound)),'color', 'm')
                end
                if ~isempty(inbound)
                    plot(cell_metrics.(CustomPlotOptions{CustomCellPlot})(:,a1(inbound)),'color', 'k')
                end
        end
        title(CustomPlotOptions{CustomCellPlot}, 'Interpreter', 'none'), xlabel(''),ylabel('')
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
[C, ~, ic] = unique(clusClas,'sorted');
for i = 1:length(C)
    cell_metrics.PutativeCellType(find(ic==i)) = repmat({classNames{C(i)}},sum(ic==i),1);
end
cell_metrics.General.SWR_batch = SWR_batch;
cell_metrics.General.tSNE_ACG2 = tSNE_ACG2;
cell_metrics.General.tSNE_SpikeWaveforms = tSNE_SpikeWaveforms;
cell_metrics.General.tSNE_plot = tSNE_plot;

% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

    function buttonCellType(selectedClas)
        if any(selectedClas == [1:length(classNames)])
            hist_idx = size(history_classification,2)+1;
            history_classification(hist_idx).CellIDs = ii;
            history_classification(hist_idx).CellTypes = clusClas(ii);
            history_classification(hist_idx).DeepSuperficial = cell_metrics.DeepSuperficial{ii};
            history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
            history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
            
            clusClas(ii) = selectedClas;
            %         cell_metrics.PutativeCellType{ii} = classNames{selectedClas};
            ui_terminal.String = ['Celltype: Cell ', num2str(ii), ' classified as ', classNames{selectedClas}];
            updateCellCount
            updatePlotClas
            advance;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function listCellType
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = cell_metrics.DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        clusClas(ii) = listbox_cell_classification.Value;
        %         cell_metrics.PutativeCellType{ii} = classNames{listbox_cell_classification.Value};
        ui_terminal.String = ['Celltype: Cell ', num2str(ii), ' classified as ', classNames{clusClas(ii)}];
        updateCellCount
        updatePlotClas
        advance;
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonDeepSuperficial
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = cell_metrics.DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        cell_metrics.DeepSuperficial{ii} = deepSuperficialNames{listbox_deepsuperficial.Value};
        cell_metrics.DeepSuperficial_num(ii) = listbox_deepsuperficial.Value;
        
        ui_terminal.String = ['Deep/Superficial: Cell ', num2str(ii), ' classified as ', cell_metrics.DeepSuperficial{ii}];
        if strcmp(plotX_title,'DeepSuperficial_num')
            plotX = cell_metrics.DeepSuperficial_num;
        end
        if strcmp(plotY_title,'DeepSuperficial_num')
            plotY = cell_metrics.DeepSuperficial_num;
        end
        if strcmp(plotZ_title,'DeepSuperficial_num')
            plotZ = cell_metrics.DeepSuperficial_num;
        end
        updatePlotClas
        updateCount
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonLabel
        Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{cell_metrics.Labels{ii}});
        if ~isempty(Label)
            cell_metrics.Labels{ii} = Label{1};
            button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
            ui_terminal.String = ['Label: Cell ', num2str(ii), ' labeled as ', Label{1}];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonBrainRegion
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).CellIDs = ii;
        history_classification(hist_idx).CellTypes = clusClas(ii);
        history_classification(hist_idx).DeepSuperficial = cell_metrics.DeepSuperficial{ii};
        history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion{ii};
        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(ii);
        
        if isempty(BrainRegions_list)
            load('BrainRegions.mat');
            BrainRegions_list = strcat(BrainRegions(:,1),' (',BrainRegions(:,2),')');
            BrainRegions_acronym = BrainRegions(:,2);
            clear BrainRegions;
        end
        choice = BrainRegionDlg(BrainRegions_list,find(strcmp(cell_metrics.BrainRegion{ii},BrainRegions_acronym)));
        if strcmp(choice,'')
            tf = 0;
        else
            indx = find(strcmp(choice,BrainRegions_list));
            tf = 1;
        end
        
        if tf == 1
            SelectedBrainRegion = BrainRegions_acronym{indx};
            cell_metrics.BrainRegion{ii} = SelectedBrainRegion;
            button_brainregion.String = ['Region: ', SelectedBrainRegion];
            [cell_metrics.BrainRegion_num,ID] = findgroups(cell_metrics.BrainRegion);
            groups_ids.BrainRegion_num = ID;
            ui_terminal.String = ['Brain region: Cell ', num2str(ii), ' classified as ', SelectedBrainRegion];
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

    function choice = BrainRegionDlg(BrainRegions,InitBrainRegion)
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
        listbox_deepsuperficial.Value = cell_metrics.DeepSuperficial_num(ii);
        
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
        listbox_deepsuperficial.Value = cell_metrics.DeepSuperficial_num(ii);
        button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
        button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonACG
        if popup_ACG.Value == 1
            ACG_type = 'Narrow';
            button_ACG.String = 'ACG: 30ms';
            ui_terminal.String = 'Autocorrelogram window adjusted to 30 ms';
        elseif popup_ACG.Value == 2
            ACG_type = 'Normal';
            button_ACG.String = 'ACG: 100ms';
            ui_terminal.String = 'Autocorrelogram window adjusted to 100 ms';
        elseif popup_ACG.Value == 3
            ACG_type = 'Wide';
            button_ACG.String = 'ACG: 1s';
            ui_terminal.String = 'Autocorrelogram window adjusted to 1 sec';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonMonoSyn
        if popup_SynMono.Value == 1
            MonoSynDisp = 'None';
            button_SynMono.String = 'MonoSyn: None';
            ui_terminal.String = 'Hiding Synaptic connections';
        elseif popup_SynMono.Value == 2
            MonoSynDisp = 'Selected';
            button_SynMono.String = 'MonoSyn: Selected';
            ui_terminal.String = 'Synaptic connections for selected cell';
        elseif popup_SynMono.Value == 3
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
            ui_terminal.String = ['Select a cell by clicking the top subplots near a point'];
            [u,v] = ginput(1);
            axnum = find(ismember(subfig_ax, gca));
            if axnum == 1
                [~,idx] = min(hypot(plotX(subset)-u,plotY(subset)-v));
                ii = subset(idx);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from custom metrics'];
            elseif axnum == 2
                [~,idx] = min(hypot(cell_metrics.TroughToPeak(subset)-u/1000,log10(cell_metrics.BurstIndex_Royer2012(subset))-log10(v)));
                ii = subset(idx);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from waveform metrics'];
            elseif axnum == 3
                [~,idx] = min(hypot(tSNE_plot(subset,1)-u,tSNE_plot(subset,2)-v));
                ii = subset(idx);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from t-SNE visualization'];
            elseif axnum == 4 && strcmp(WaveformsPlot,'tSNE')
                [~,idx] = min(hypot(tSNE_SpikeWaveforms(subset,1)-u,tSNE_SpikeWaveforms(subset,2)-v));
                ii = subset(idx);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from Waveforms t-SNE visualization'];
            elseif axnum == 4 && strcmp(WaveformsPlot,'All')
                x1 = time_waveforms'*ones(1,length(subset));
                y1 = cell_metrics.SpikeWaveforms_zscored(:,subset);
                [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                In = unique(floor(In/length(time_waveforms)))+1;
                ii = subset(In);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from Waveforms'];
            elseif axnum == 5 && strcmp(ACGPlot,'tSNE')
                [~,idx] = min(hypot(tSNE_ACG2(subset,1)-u,tSNE_ACG2(subset,2)-v));
                ii = subset(idx);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from Autocorrelogram t-SNE visualization'];
            elseif axnum == 5 && strcmp(ACGPlot,'All')
                if strcmp(ACG_type,'Normal')
                    x1 = ([-100:100]/2)'*ones(1,length(subset));
                    y1 = cell_metrics.ACG2(:,subset);
                elseif strcmp(ACG_type,'Narrow')
                    x1 = ([-30:30]/2)'*ones(1,length(subset));
                    y1 = cell_metrics.ACG2(41+30:end-40-30,subset);
                else
                    x1 = ([-500:500])'*ones(1,length(subset));
                    y1 = cell_metrics.ACG(:,subset);
                end
                [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                In = unique(floor(In/size(x1,1)))+1;
                ii = subset(In);
                ui_terminal.String = ['Cell ', num2str(ii), ' selected from Waveforms'];
            end
            listbox_deepsuperficial.Value = cell_metrics.DeepSuperficial_num(ii);
            button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
            button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
            uiresume(fig);
        else
            ui_terminal.String = ['No cells with selected classification'];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupSelectFromPlot
        if ~isempty(subset)
            ui_terminal.String = ['Select cells by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.'];
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
            if ~isempty(polygon_coords)
                plot([polygon_coords(:,1);polygon_coords(1,1)],[polygon_coords(:,2);polygon_coords(1,2)],'.-k');
            end
            hold(ax, 'off')
            clear h2
            if size(polygon_coords,1)>2
                axnum = find(ismember(subfig_ax, gca));
                if axnum == 1
                    In = find(inpolygon(plotX(subset), plotY(subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    ui_terminal.String = [num2str(length(In)), ' cells selected from custom metrics'];
                elseif axnum == 2
                    In = find(inpolygon(cell_metrics.TroughToPeak(subset)*1000, log10(cell_metrics.BurstIndex_Royer2012(subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                    ui_terminal.String = [num2str(length(In)), ' cells selected from waveform metrics'];
                elseif axnum == 3
                    In = find(inpolygon(tSNE_plot(subset,1), tSNE_plot(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    ui_terminal.String = [num2str(length(In)), ' cells selected from t-SNE visualization'];
                elseif axnum == 4 && strcmp(WaveformsPlot,'All')
                    x1 = time_waveforms'*ones(1,length(subset));
                    y1 = cell_metrics.SpikeWaveforms_zscored(:,subset);
                    In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = unique(floor(In/length(time_waveforms)))+1;
                    ui_terminal.String = [num2str(length(In)), ' cells selected from Waveforms'];
                elseif axnum == 4 && strcmp(WaveformsPlot,'tSNE')
                    In = find(inpolygon(tSNE_SpikeWaveforms(subset,1), tSNE_SpikeWaveforms(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    ui_terminal.String = [num2str(length(In)), ' cells selected from t-SNE waveforms visualization'];
                elseif axnum == 5 && strcmp(ACGPlot,'All')
                    if strcmp(ACG_type,'Normal')
                        x1 = ([-100:100]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.ACG2(:,subset);
                    elseif strcmp(ACG_type,'Narrow')
                        x1 = ([-30:30]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.ACG2(41+30:end-40-30,subset);
                    else
                        x1 = ([-500:500])'*ones(1,length(subset));
                        y1 = cell_metrics.ACG(:,subset);
                    end
                    In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = unique(floor(In/size(x1,1)))+1;
                    ui_terminal.String = [num2str(length(In)), ' cells selected from Autocorrelograms'];
                elseif axnum == 5 && strcmp(ACGPlot,'tSNE')
                    In = find(inpolygon(tSNE_ACG2(subset,1), tSNE_ACG2(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    ui_terminal.String = [num2str(length(In)), ' cells selected from t-SNE waveforms visualization'];
                end
                if length(In)>0 && any(axnum == [1,2,3,4,5])
                    [selectedClas,tf] = listdlg('PromptString',['Assign cell-type to ' num2str(length(In)) ' cells'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
                    if ~isempty(selectedClas)
                        hist_idx = size(history_classification,2)+1;
                        history_classification(hist_idx).CellIDs = subset(In);
                        history_classification(hist_idx).CellTypes = clusClas(subset(In));
                        history_classification(hist_idx).DeepSuperficial = {cell_metrics.DeepSuperficial{subset(In)}};
                        history_classification(hist_idx).BrainRegion = {cell_metrics.BrainRegion{subset(In)}};
                        history_classification(hist_idx).BrainRegion_num = cell_metrics.BrainRegion_num(subset(In));
                        history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num(subset(In));
                        
                        clusClas(subset(In)) = selectedClas;
                        %                         cell_metrics.PutativeCellType(subset(In)) = repmat({classNames{selectedClas}},length(In),1);
                        updateCellCount
                        ui_terminal.String = [num2str(length(In)), ' cells assigned to ', classNames{selectedClas}, ' from t-SNE visualization'];
                        updatePlotClas
                        uiresume(fig);
                    end
                else
                    ui_terminal.String = ['0 cells selected'];
                    uiresume(fig);
                end
            else
                ui_terminal.String = ['0 cells selected'];
                uiresume(fig);
            end
        else
            ui_terminal.String = ['No cells with selected classification'];
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

    function updatePlotClas
        if Colorval == 1
            plotClas = clusClas;
        else
            if checkbox_groups.Value == 0
                plotClas = cell_metrics.(Colorstr{Colorval});
                if iscell(plotClas)
                    plotClas = findgroups(plotClas);
                end
            else
                plotClas = clusClas;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonGroups
        Colorval = popup_groups.Value;
        Colorstr = popup_groups.String;
        buttonToggleGroups
        if Colorval == 1
            clasLegend = 0;
            listbox_groups.Visible='Off';
            checkbox_groups.Visible='Off';
            plotClas = clusClas;
            checkbox_groups.Value = 0;
            plotClasGroups = classNames;
        else
            clasLegend = 1;
            listbox_groups.Visible='On';
            checkbox_groups.Visible='On';
            if checkbox_groups.Value == 0
                plotClas = cell_metrics.(Colorstr{Colorval});
                plotClasGroups = groups_ids.([Colorstr{Colorval} '_num']);
                if iscell(plotClas) && ~strcmp(Colorstr{Colorval},'DeepSuperficial')
                    plotClas = findgroups(plotClas);
                elseif strcmp(Colorstr{Colorval},'DeepSuperficial')
                    [~,plotClas] = ismember(plotClas,plotClasGroups);
                end
                color_class_count = histc(plotClas,[1:length(plotClasGroups)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                listbox_groups.String = strcat(plotClasGroups,' (',color_class_count,')'); %  plotClasGroups;
                listbox_groups.Value = 1:length(plotClasGroups);
                groups2plot = 1:length(plotClasGroups);
                groups2plot2 = 1:length(plotClasGroups);
            else
                plotClas = clusClas;
                plotClasGroups = classNames;
                plotClas2 = cell_metrics.(Colorstr{Colorval});
                plotClasGroups2 = groups_ids.([Colorstr{Colorval} '_num']);
                if iscell(plotClas2) && ~strcmp(Colorstr{Colorval},'DeepSuperficial')
                    plotClas2 = findgroups(plotClas2);
                elseif strcmp(Colorstr{Colorval},'DeepSuperficial')
                    [~,plotClas2] = ismember(plotClas2,plotClasGroups2);
                end
 
                color_class_count = histc(plotClas2,[1:length(plotClasGroups2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                listbox_groups.String = strcat(plotClasGroups2,' (',color_class_count,')');
                listbox_groups.Value = 1:length(plotClasGroups2);
                groups2plot = 1:length(plotClasGroups);
                groups2plot2 = 1:length(plotClasGroups2);
            end
            
        end
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
            axes(subfig_ax1.Children);
            view([40 20]);
        else
            Plot3axis = 0;
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectSubset
        classes2plot = listbox_celltypes.Value;
        ui_terminal.String = [''];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectGroups
        groups2plot2 = listbox_groups.Value;
        ui_terminal.String = [''];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonToggleGroups
        ui_terminal.String = ['Changed coloring'];
        %         buttonGroups
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

% % % % % % % % % % % % % % % % % % % % % % %

    function CustomCellPlotFunc
        CustomCellPlot = popup_customplot.Value;
        ui_terminal.String = ['Displaying ', CustomPlotOptions{CustomCellPlot}];
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function togglePlotHistograms
        if customPlotHistograms == 0
            customPlotHistograms = 1;
            ui_terminal.String = ['Displaying smooth histogram'];
        elseif customPlotHistograms == 1
            customPlotHistograms = 2;
            ui_terminal.String = ['Displaying stairs-histogram'];
            
        else
            customPlotHistograms = 0;
            ui_terminal.String = ['Regular plot'];
            delete(h_scatter)
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function toggleWaveformsPlot
        if popup_waveforms.Value == 1
            WaveformsPlot = 'Single';
            ui_terminal.String = 'Displaying single waveform with std';
        elseif popup_waveforms.Value == 2
            WaveformsPlot = 'All';
            ui_terminal.String = 'Displaying all waveforms';
        elseif popup_waveforms.Value == 3
            WaveformsPlot = 'tSNE';
            ui_terminal.String = 'Displaying t-SNE space with waveforms';
        end
        uiresume(fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleACGplot
        if popup_ACGs.Value == 1
            ACGPlot = 'Single';
            ui_terminal.String = 'Displaying single ACG';
        elseif popup_ACGs.Value == 2
             ACGPlot = 'All';
            ui_terminal.String = 'Displaying all ACGs';
        elseif popup_ACGs.Value == 3
            ACGPlot = 'tSNE';
            ui_terminal.String = 'Displaying t-SNE space with ACGs';
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

    function goToCell
        opts.Interpreter = 'tex';
        answer = inputdlg({'Select the cell id to go to'},'Go to cell...',[1 40],{''},opts);
        if ~isempty(answer) && ~isempty(str2num(answer{1}))
            answer = str2num(answer{1});
            if answer > 0 && answer <= size(cell_metrics.TroughToPeak,2)
                ii = answer;
                uiresume(fig);
                ui_terminal.String = ['Cell ' num2str(ii) ' selected.'];
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function keyPress(src, e)
        switch e.Key
            case 'rightarrow'
                advance;
            case 'leftarrow'
                back;
            case {'1','2','3','4','5','6','7','8','9'}
                buttonCellType(str2num(e.Key));
            case 's'
                listbox_deepsuperficial.Value = find(strcmp(deepSuperficialNames,'Superficial'));
                buttonDeepSuperficial;
            case 'd'
                listbox_deepsuperficial.Value = find(strcmp(deepSuperficialNames,'Deep'));
                buttonDeepSuperficial;
            case 'u'
                listbox_deepsuperficial.Value = find(strcmp(deepSuperficialNames,'Unknown'));
                buttonDeepSuperficial;
            case 'c'
                listbox_deepsuperficial.Value = find(strcmp(deepSuperficialNames,'Cortical'));
                buttonDeepSuperficial;
            case 'a'
                toggleACGplot;
            case 'f'
                toggleACGfit;
            case 'z'
                undoClassification;
            case 'l'
                buttonLabel;
            case 'w'
                toggleWaveformsPlot;
            case 'q'
                togglePlotHistograms;
            case 'm'
                SignificanceMetricsMatrix;
            case 'h'
                HelpDialog;
            case 'r'
                reclassify_celltypes;
            case 't'
                buttonACG;
            case 'g'
                goToCell;
            case 'p'
                LoadPreferences;
            case 'b'
                buttonBrainRegion;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadPreferences
        answer = questdlg('Settings are stored in CellInspector_Settings.m. Click Yes to load settings.', ...
            'Settings', ...
            'Yes','Cancel','Yes');
        switch answer
            case 'Yes'
                ui_terminal.String = ['Opening settings file...'];
                edit CellInspector_Preferences.m
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function reclassify_celltypes
        answer = questdlg('Are yo sure you want to reclassify all your cells?', ...
            'Reclassification', ...
            'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                ui_terminal.String = ['Reclassifying cells...'];
                disp('Reclassifying cells...')
                hist_idx = size(history_classification,2)+1;
                history_classification(hist_idx).CellIDs = 1:size(cell_metrics.TroughToPeak,2);
                history_classification(hist_idx).CellTypes = clusClas;
                history_classification(hist_idx).DeepSuperficial = cell_metrics.DeepSuperficial;
                history_classification(hist_idx).BrainRegion = cell_metrics.BrainRegion;
                history_classification(hist_idx).BrainRegion_num = cell_metrics.BrainRegion_num;
                history_classification(hist_idx).DeepSuperficial_num = cell_metrics.DeepSuperficial_num;
                
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
                
                % clusClas initialization
                clusClas = ones(1,length(cell_metrics.PutativeCellType));
                for i = 1:length(classNames)
                    clusClas(strcmp(cell_metrics.PutativeCellType,classNames{i}))=i;
                end
                uiresume(fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function initializeSession
        ii = 1;
        if ~isfield(cell_metrics, 'Labels')
            cell_metrics.Labels = repmat({''},1,size(cell_metrics.CellID,2));
        end
        
        % Cell type initialization
        clusClas = ones(1,length(cell_metrics.PutativeCellType));
        for i = 1:length(classNames)
            clusClas(strcmp(cell_metrics.PutativeCellType,classNames{i}))=i;
        end
        
        % SRW Profile initialization
        if isempty(SWR_in)
            if isfield(cell_metrics.General,'SWR_batch') && ~isempty(cell_metrics.General.SWR_batch)
                disp('Loading existing SWR profiles from cell_metrics structure')
                SWR_batch = cell_metrics.General.SWR_batch;
            elseif length(unique(cell_metrics.SpikeSortingID)) == 1
                if exist('DeepSuperficial_ChClass.mat')
                    SWR_batch = load('DeepSuperficial_ChClass.mat');
                else
                    SWR_batch = [];
                end
            else
                fprintf(['Loading SWR-LFP profiles (', num2str(length(cell_metrics.General.basepaths)),' sessions) \n'])
                SWR_batch = [];
                for i = 1:length(cell_metrics.General.basepaths)
                    if exist(fullfile(cell_metrics.General.basepaths{i},'DeepSuperficial_ChClass.mat'))
                        fprintf([num2str(i), ', '])
                        SWR_batch{i} = load(fullfile(cell_metrics.General.basepaths{i},'DeepSuperficial_ChClass.mat'));
                    end
                    if rem(i,20)==0
                        fprintf('\n')
                    end
                end
                fprintf(' done! \n')
            end
        else
            SWR_batch = SWR_in;
        end
        
        % Plotting menues initialization
        fieldsMenu = sort(fieldnames(cell_metrics));
        groups_ids = [];
        fieldsMenu(find(contains(fieldsMenu,'firing_rate_map_states')))=[];
         fieldsMenu(find(contains(fieldsMenu,'firing_rate_map')))=[];
        fieldsMenu(find(contains(fieldsMenu,'SpatialCoherence')))=[];
        
        for i = 1:length(fieldsMenu)
            if strcmp(fieldsMenu{i},'DeepSuperficial')
                cell_metrics.DeepSuperficial_num = ones(1,length(cell_metrics.DeepSuperficial));
                for j = 1:length(deepSuperficialNames)
                    cell_metrics.DeepSuperficial_num(strcmp(cell_metrics.DeepSuperficial,deepSuperficialNames{j}))=j;
                end
                groups_ids.DeepSuperficial_num = deepSuperficialNames;
            elseif iscell(cell_metrics.(fieldsMenu{i})) && ~any(strcmp(fieldsMenu{i},{'firing_rate_map_states','firing_rate_map'}))
                %                 temp = cellfun(@isempty,cell_metrics.(fieldsMenu{i}));
                [cell_metrics.([fieldsMenu{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenu{i}));
                groups_ids.([fieldsMenu{i},'_num']) = ID;
            end
        end
        
        fieldsMenu = sort(fieldnames(cell_metrics));
        fields_to_keep = [];
        fieldsMenu(find(contains(fieldsMenu,'firing_rate_map_states')))=[];
        fieldsMenu(find(contains(fieldsMenu,'firing_rate_map')))=[];
        fieldsMenu(find(contains(fieldsMenu,'SpatialCoherence')))=[];
        fieldsMenu(find(contains(fieldsMenu,'PutativeConnections')))=[];
        fieldsMenu(find(contains(fieldsMenu,'placecell_stability')))=[];
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
        if isfield(cell_metrics.General,'tSNE_ACG2') && ~isempty(cell_metrics.General.tSNE_ACG2)
            disp('Loading existing tSNE spaces...')
            tSNE_ACG2 = cell_metrics.General.tSNE_ACG2;
            tSNE_SpikeWaveforms = cell_metrics.General.tSNE_SpikeWaveforms;
            tSNE_plot = cell_metrics.General.tSNE_plot;
        else
            disp('Calculating tSNE spaces...')
            tSNE_ACG2 = tsne([cell_metrics.ACG2]');
            tSNE_SpikeWaveforms = tsne(cell_metrics.SpikeWaveforms');
            tSNE_fields = intersect(tSNE_fields,fieldnames(cell_metrics));
            X = cell2mat(cellfun(@(X) cell_metrics.(X),tSNE_fields,'UniformOutput',false));
            X(isnan(X) | isinf(X)) = 0;
            tSNE_plot = tsne(([X',tSNE_ACG2,tSNE_SpikeWaveforms]));
        end
        
        % Setting initial settings for plots, popups and listboxes
        disp('Setting initial settings...')
        popup_x.String = fieldsMenu;
        popup_y.String = fieldsMenu;
        popup_z.String = fieldsMenu;
        plotX = cell_metrics.(plotXdata);
        plotY  = cell_metrics.(plotYdata);
        plotZ  = cell_metrics.(plotZdata);
        
        popup_x.Value = find(strcmp(fieldsMenu,plotXdata));
        popup_y.Value = find(strcmp(fieldsMenu,plotYdata));
        popup_z.Value = find(strcmp(fieldsMenu,plotZdata));
        plotX_title = plotXdata;
        plotY_title = plotYdata;
        plotZ_title = plotZdata;
        
        listbox_celltypes.Value = 1:length(classNames);
        classes2plot = 1:length(classNames);
        
        ui_title.String = ['Session: ', cell_metrics.General.basename,' with ', num2str(size(cell_metrics.TroughToPeak,2)), ' cells'];
        
        
        if isfield(cell_metrics,'PutativeConnections')
            MonoSynDisp = MonoSynDispIn;
            button_SynMono.Visible = 'On';
            button_SynMono.String = ['MonoSyn:' MonoSynDispIn];
        else
            MonoSynDisp = 'None';
            button_SynMono.Visible = 'off';
        end
        
        % History function initialization
        history_classification = [];
        history_classification(1).CellIDs = 1:size(cell_metrics.TroughToPeak,2);
        history_classification(1).CellTypes = clusClas;
        history_classification(1).DeepSuperficial = cell_metrics.DeepSuperficial;
        history_classification(1).BrainRegion = cell_metrics.BrainRegion;
        history_classification(1).BrainRegion_num = cell_metrics.BrainRegion_num;
        history_classification(1).DeepSuperficial_num = cell_metrics.DeepSuperficial_num;
        
        % Cell count for menu
        updateCellCount
        
        % Button Deep-Superficial
        listbox_deepsuperficial.Value = cell_metrics.DeepSuperficial_num(ii);
        
        % Button brain region
        button_brainregion.String = ['Region: ', cell_metrics.BrainRegion{ii}];
        
        % Button label
        button_labels.String = ['Label: ', cell_metrics.Labels{ii}];
        
        cell_metrics.SpikeWaveforms_zscored = zscore(cell_metrics.SpikeWaveforms);
        WaveformsPlot = WaveformsPlotIn;
        
        CustomPlotOptions = fieldnames(cell_metrics);
        temp =  struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        temp1 = cell2mat(struct2cell(structfun(@(X) size(X,1), cell_metrics,'UniformOutput',false)));
        temp2 = cell2mat(struct2cell(structfun(@(X) size(X,2), cell_metrics,'UniformOutput',false)));
        
        CustomPlotOptions = ['SWR'; 'SWR Correllogram'; CustomPlotOptions( find(strcmp(temp,'double') & temp1>1 & temp2==size(cell_metrics.SpikeCount,2)))]; % 'tSNE Waveforms';'tSNE AutoCG';
        CustomPlotOptions(find(contains(CustomPlotOptions,{'PutativeConnections','TruePositive','FalsePositive','ACG','ACG2','SpikeWaveform'})))=[];
        if isfield(cell_metrics,'firing_rate_map')
            CustomPlotOptions = {CustomPlotOptions{:},'Firing rate map'}';
        end
        CustomCellPlot = 1;
        popup_customplot.String = CustomPlotOptions;
        popup_customplot.Value = 1;
        
        % Custom colorgroups
        ColorMenu = sort(fieldnames(cell_metrics));
        fields2keep = [];
        for i = 1:length(ColorMenu)
            if iscell(cell_metrics.(ColorMenu{i})) && ~any(strcmp(ColorMenu{i},{'PutativeCellType','firing_rate_map_states','firing_rate_map'}) )
                fields2keep = [fields2keep,i];
            end
        end
        ColorMenu = ['Celltypes';ColorMenu(fields2keep)];
        popup_groups.String = ColorMenu;
        plotClas = clusClas;
        popup_groups.Value = 1;
        clasLegend = 0;
        listbox_groups.Visible='Off';
        ACGPlot = ACGPlotIn;
        checkbox_groups.Value = 0;
    end


% % % % % % % % % % % % % % % % % % % % % %

    function LoadDatabaseSession
        ui_terminal.String = ['Loading datasets from database...'];
        drawnow
        options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
        options.CertificateFilename=('');
        bz_db = webread([bz_database.rest_api.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
        sessions = loadjson(bz_db.renderedHtml);
        [db_menu_items,index] = sort(cellfun(@(x) x.Name,sessions,'UniformOutput',false));
        db_menu_values = cellfun(@(x) x.Id,sessions,'UniformOutput',false);
        db_menu_values = db_menu_values(index);
        db_menu_items2 = strcat(db_menu_items);
        ui_terminal.String = ['Please select datasets to load.'];
        drawnow
        [indx,tf] = listdlg('PromptString',['Select dataset to load'],'ListString',db_menu_items2,'SelectionMode','multiple','ListSize',[300,350]);
        if ~isempty(indx)
            if length(indx)==1
                try
                    [session, basename, basepath, clusteringpath] = db_set_path('session',db_menu_items{indx},'saveMat',false);
                    %                     sessions = db_load_sessions('session',db_menu_items{indx});
                    %                     session = sessions{1};
                    SWR_in = {};
                    ui_terminal.String = ['Loading single session...'];
                    drawnow
                    LoadSession
                catch
                    warning('Failed to load dataset from database');
                    ui_terminal.String = [db_menu_items{indx},': Error loading dataset from database'];
                end
            else
                try
                    ui_terminal.String = ['Loading batch of sessions...'];
                    drawnow
                    cell_metrics = LoadCellMetricBatch('sessions',db_menu_items(indx));
                    SWR_in = {};
                catch
                    warning('Failed to load all dataset from database');
                    ui_terminal.String = [db_menu_items(indx),': Error loading dataset from database'];
                end
                ui_terminal.String = ['Initializing session(s)...'];
                drawnow
                initializeSession
                ui_terminal.String = ['Session(s) loaded successfully.'];
                drawnow
            end
            %         else
            %             if ~exist('cell_metrics')
            %                 exit = 1;
            %                 return
            %             end
        end
        
        if ishandle(fig)
            uiresume(fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadSession
        
        if exist(basepath)
            
            if exist(fullfile(clusteringpath,'cell_metrics.mat'))
                
                if exist(fullfile(basepath,'DeepSuperficial_ChClass.mat'))
                    cd(basepath);
                    load(fullfile(clusteringpath,'cell_metrics.mat'));
                    
                    initializeSession;
                    
                    ui_terminal.String = [basename ' with ' num2str(size(cell_metrics.TroughToPeak,2))  ' cells loaded from database'];
                else
                    ui_terminal.String = [basename, ': missing DeepSuperficial classification'];
                    warning([basename, ': missing DeepSuperficial classification'])
                end
            else
                ui_terminal.String = [basename, ': missing cell_metrics'];
                warning([basename, ': missing cell_metrics'])
            end
        else
            ui_terminal.String = [basename ': path not available'];
            warning([basename ': path not available'])
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function undoClassification
        if size(history_classification,2) > 1
            clusClas(history_classification(end).CellIDs) = history_classification(end).CellTypes;
            cell_metrics.DeepSuperficial(history_classification(end).CellIDs) = cellstr(history_classification(end).DeepSuperficial);
            cell_metrics.BrainRegion(history_classification(end).CellIDs) = cellstr(history_classification(end).BrainRegion);
            cell_metrics.DeepSuperficial_num(history_classification(end).CellIDs) = history_classification(end).DeepSuperficial_num;
            
            if length(history_classification(end).CellIDs) == 1
                ui_terminal.String = ['Reversed classification for cell ', num2str(history_classification(end).CellIDs)];
            else
                ui_terminal.String = ['Reversed classification for ' num2str(length(history_classification(end).CellIDs)), ' cells'];
            end
            history_classification(end) = [];
            updateCellCount
            updatePlotClas
            updateCount
            
            % Button Deep-Superficial
            listbox_deepsuperficial.Value = cell_metrics.DeepSuperficial_num(ii);
            
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
        cell_class_count = histc(clusClas,[1:length(classNames)]);
        cell_class_count = cellstr(num2str(cell_class_count'))';
        listbox_celltypes.String = strcat(classNames,' (',cell_class_count,')');
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateCount
        if Colorval > 1
            if checkbox_groups.Value == 0
                plotClas = cell_metrics.(Colorstr{Colorval});
                plotClasGroups = groups_ids.([Colorstr{Colorval} '_num']);
                if iscell(plotClas) && ~strcmp(Colorstr{Colorval},'DeepSuperficial')
                    plotClas = findgroups(plotClas);
                elseif strcmp(Colorstr{Colorval},'DeepSuperficial')
                    [~,plotClas] = ismember(plotClas,plotClasGroups);
                end
                color_class_count = histc(plotClas,[1:length(plotClasGroups)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                listbox_groups.String = strcat(plotClasGroups,' (',color_class_count,')'); %  plotClasGroups;
%                 groups2plot = 1:length(plotClasGroups);
%                 groups2plot2 = 1:length(plotClasGroups);
            else
                plotClas = clusClas;
                plotClasGroups = classNames;
                plotClas2 = cell_metrics.(Colorstr{Colorval});
                plotClasGroups2 = groups_ids.([Colorstr{Colorval} '_num']);
                if iscell(plotClas2) && ~strcmp(Colorstr{Colorval},'DeepSuperficial')
                    plotClas2 = findgroups(plotClas2);
                elseif strcmp(Colorstr{Colorval},'DeepSuperficial')
                    [~,plotClas2] = ismember(plotClas2,plotClasGroups2);
                end
                color_class_count = histc(plotClas2,[1:length(plotClasGroups2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                listbox_groups.String = strcat(plotClasGroups2,' (',color_class_count,')');
%                 groups2plot = 1:length(plotClasGroups);
%                 groups2plot2 = 1:length(plotClasGroups2);
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSave
        answer = questdlg('Are you sure you want to save the classification', 'Save classification','Update existing metrics','Create new file', 'Cancel','Cancel');
        % Handle response
        switch answer
            case 'Update existing metrics'
                try
                    saveMetrics(cell_metrics);
                catch
                    exception
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
                    try
                        saveMetrics(cell_metrics,fullfile(SavePath,file));
                    catch
                        exception
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
        
        [C, ~, ic] = unique(clusClas,'sorted');
        for i = 1:length(C)
            cell_metrics.PutativeCellType(find(ic==i)) = repmat({classNames{C(i)}},sum(ic==i),1);
        end
        if nargin > 1
            cell_metrics.General.SWR_batch = SWR_batch;
            cell_metrics.General.tSNE_ACG2 = tSNE_ACG2;
            cell_metrics.General.tSNE_SpikeWaveforms = tSNE_SpikeWaveforms;
            cell_metrics.General.tSNE_plot = tSNE_plot;
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

% % % % % % % % % % % % % % % % % % % % % %

    function SignificanceMetricsMatrix
        if popup_groups.Value~=1 && (length(classes2plot)==2 && checkbox_groups.Value == 1) || (length(groups2plot2)==2 && checkbox_groups.Value == 0)
            % Cell metrics differences
            cell_metrics_effects = [];
            cell_metrics_effects2 = [];
            temp = fieldnames(cell_metrics);
            temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
            subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'TruePositive','FalsePositive','PutativeConnections','ACG','ACG2','SpatialCoherence','_num','optoPSTH','firing_rate_map_states','firing_rate_map','SpikeWaveforms_zscored','SpikeWaveforms','SpikeWaveforms_std','CellID','SpikeSortingID','Promoter'})));
            if checkbox_groups.Value == 0
                testset = plotClasGroups(listbox_groups.Value);
                temp1 = intersect(find(strcmp(cell_metrics.(popup_groups.String{popup_groups.Value}),testset{1})),subset);
                temp2 = intersect(find(strcmp(cell_metrics.(popup_groups.String{popup_groups.Value}),testset{2})),subset);
            else
                testset = plotClasGroups(listbox_celltypes.Value);
                temp1 = intersect(find(strcmp(cell_metrics.PutativeCellType,testset{1})),subset);
                temp2 = intersect(find(strcmp(cell_metrics.PutativeCellType,testset{2})),subset);
            end
            [labels2,I]= sort(temp(subindex));
            for j = 1:length(subindex)
                jj = labels2{j};
                if sum(isnan(cell_metrics.(jj)(temp1))) < length(temp1) && sum(isnan(cell_metrics.(jj)(temp2))) < length(temp2)
                    [h,p] = kstest2(cell_metrics.(jj)(temp1),cell_metrics.(jj)(temp2));
                    cell_metrics_effects(j)= p;
                    cell_metrics_effects2(j)= h;
                else
                    cell_metrics_effects(j)= 0;
                    cell_metrics_effects2(j)= 0;
                end
            end
            
            image2 = log10(cell_metrics_effects);
            image2( intersect(find(~cell_metrics_effects2), find(image2<log10(0.05))) ) = -image2( intersect(find(~cell_metrics_effects2(:)), find(image2<log10(0.05))));
            
            figure('pos',[10 10 300 800])
            imagesc(image2'),colormap(jet),colorbar, hold on
            if sum(cell_metrics_effects<0.003)
                plot(0.55,find(cell_metrics_effects<0.05 & cell_metrics_effects>=0.003),'*w','linewidth',2)
            end
            if sum(cell_metrics_effects<0.003)
                plot([0.55;0.6],[find(cell_metrics_effects<0.003);find(cell_metrics_effects<0.003)],'*w','linewidth',2)
            end
            yticks(1:length(subindex))
            yticklabels(labels2)
            set(gca,'TickLabelInterpreter','none')
            caxis([-3,3]);
            title([testset{1} ' vs ' testset{2}]), xticks(1), xticklabels({'KS-test'})
        else
            ui_terminal.String = ['Please select a group of two'];
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

% % % % % % % % % % % % % % % % % % % % % %

function y = nanUnique(x)
y = unique(x);
y(isnan(y)) = [];
end

% % % % % % % % % % % % % % % % % % % % % %

function HelpDialog
opts.Interpreter = 'tex';
opts.WindowStyle = 'modal';
msgbox({'Navigation','<    : Navigate to next cell', '>    : Navigate to previous cell','G    : Go to a specific cell','   ','Cell assigments:','1-6  : Assign Cell-types','D/S  : Assign Deep, Superficial, Cortical(C) and Unknown (U)','B    : Assign Brain region','L    : Assign Label','Z    : Undo assignment', 'R    : Reclassify cell types','   ','Other shortcuts', 'F    : Display ACG triple-exponential fit','Q    : Display histograms and significance tests', 'M    : Calculate and display significance matrix for all metrics','P    : Open preferences for the Cell-Inspector',''},'Cell-Inspector keyboard shortcuts','help',opts);
end
