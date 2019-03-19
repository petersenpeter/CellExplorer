function cell_metrics = CellExplorer(varargin)
% Inspect and perform cell classification
% Check the wiki for more details: https://github.com/petersenpeter/Cell-Explorer/wiki
%
% INPUT
% varargin
%
% Example calls:
% CellExplorer                             % Load from current path, assumed to be a basepath
% CellExplorer('basepath',basepath)        % Load from basepath
% CellExplorer('metrics',cell_metrics)     % Load from cell_metrics, assumes current path to be a basepath
% CellExplorer('session','rec1')           % Load session from database
% CellExplorer('id',10985)                 % Load session from database
% CellExplorer('sessions',{'rec1','rec2'}) % Load batch from database
% CellExplorer('sessionIDs',{10985,2845})  % Load batch from database
% CellExplorer('clusteringpaths',{'path1','[path1'}) % Load batch from a list with paths
% CellExplorer('basepaths',{'path1','[path1'}) % Load batch from a list with paths
%
% OUTPUT
% cell_metrics: structure

% By Peter Petersen
% petersen.peter@gmail.com

% TODO
% PSTH rastermaps
% Adjust deepSuperficial channel/spike groups in the GUI
% Adjust synaptic connections in the GUI or be able to rerun the detection
% Ground truth cell type classifiations
% Faster database interaction when loading multiple sessions

p = inputParser;

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
% Initialization of variables and figure
% % % % % % % % % % % % % % % % % % % % % %

UI = []; UI.settings.plotZLog = 0; UI.settings.plot3axis = 0; UI.settings.plotXdata = 'firingRate'; UI.settings.plotYdata = 'peakVoltage'; 
UI.settings.plotZdata = 'deepSuperficialDistance'; UI.settings.displayMetricsTable = 0; colorStr = []; 
UI.settings.customCellPlotIn1 = 'Single waveform'; UI.settings.customCellPlotIn2 = 'Single ACG'; UI.settings.deepSuperficial = ''; 
UI.settings.acgType = 'Normal'; UI.settings.cellTypeColors = []; UI.settings.monoSynDispIn = ''; UI.settings.layout = 3; 
UI.settings.displayMenu = 0; UI.settings.displayInhibitory = false; UI.settings.displayExcitatory = false; 
UI.settings.customCellPlotIn3 = 'thetaPhaseResponse'; UI.settings.customCellPlotIn4 = 'firingRateMap'; 
UI.settings.customCellPlotIn5 = 'firingRateMap'; UI.settings.customCellPlotIn6 = 'firingRateMap'; UI.settings.plotCountIn = 'GUI 3+3';
UI.settings.tSNE_calcNarrowAcg = true; UI.settings.tSNE_calcFiltWaveform = true; UI.settings.tSNE_metrics = ''; 
UI.settings.tSNE_calcWideAcg = true; UI.settings.dispLegend = 1;

db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = []; timerVal = tic;
classes2plot = []; classes2plotSubset = []; fieldsMenu = []; table_metrics = []; ii = []; history_classification = [];
brainRegions_list = []; brainRegions_acronym = []; cell_class_count = [];  customCellPlot3 = 1; customCellPlot4 = 1; customPlotOptions = '';
customCellPlot1 = ''; customPlotHistograms = 0; plotAcgFit = 0; basename = ''; clasLegend = 0; Colorval = 1; plotClas = [];
colorMenu = []; groups2plot = []; groups2plot2 = []; plotClasGroups2 = []; exit = 0;  monoSynDisp = ''; customCellPlot2 = ''; 
plotClasGroups = [];  plotClas2 = [];  SWR_batch = []; general = []; 
cellsExcitatory = []; cellsInhibitory = []; cellsInhibitory_subset = []; cellsExcitatory_subset = []; ii_history = 1;
subsetPlots1 = []; subsetPlots2 = []; subsetPlots3 = []; subsetPlots4 = []; subsetPlots5 = []; subsetPlots6 = []; 
tSNE_metrics = []; BatchMode = false; ClickedCells = []; classificationTrackChanges = []; time_waveforms_zscored = []; spikes = []; 
spikesPlots = []; globalZoom = cell(1,9); createStruct.Interpreter = 'tex'; createStruct.WindowStyle = 'modal'; 

CellExplorerVersion = '1.0';

UI.fig = figure('KeyPressFcn', {@keyPress},'Name',['Cell Explorer v' CellExplorerVersion],'NumberTitle','off','renderer','opengl', 'MenuBar', 'None','PaperOrientation','landscape','windowscrollWheelFcn',@ScrolltoZoomInPlot);
hManager = uigetmodemanager(UI.fig);

% % % % % % % % % % % % % % % % % % % % % %
% User preferences for the Cell Explorer
% % % % % % % % % % % % % % % % % % % % % %

CellExplorer_Preferences


% % % % % % % % % % % % % % % % % % % % % %
% Checking for Matlab version requirements (Matlab R2017a)
% % % % % % % % % % % % % % % % % % % % % %

if verLessThan('matlab', '9.2')
    warning('The Cell Explorer is only fully compatible and tested with Matlab version 9.2 and forward (Matlab R2017a)')
    return
end


% % % % % % % % % % % % % % % % % % % % % %
% Turning off select warnings
% % % % % % % % % % % % % % % % % % % % % %

warning('off','MATLAB:deblank:NonStringInput')
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')


% % % % % % % % % % % % % % % % % % % % % %
% Database initialization
% % % % % % % % % % % % % % % % % % % % % %

if exist('db_credentials') == 2
    bz_database = db_credentials;
    if ~strcmp(bz_database.rest_api.username,'user')
        enableDatabase = 1;
    else
        enableDatabase = 0;
        disp('Please provide your database credentials in ''db_credentials.m'' ')
    end
else
    enableDatabase = 0;
end


% % % % % % % % % % % % % % % % % % % % % %
% Session initialization
% % % % % % % % % % % % % % % % % % % % % %

if isstruct(metrics)
    cell_metrics = metrics;
    initializeSession
elseif ~isempty(id) || ~isempty(sessionin)
    if enableDatabase
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
            LoadSession;
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
    if enableDatabase
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
    if enableDatabase
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
    if exist(fullfile(pwd,'session.mat'))
        disp('Loading local session.mat')
        load('session.mat')
        if isempty(session.spikeSorting.relativePath)
            clusteringpath = '';
        else
            clusteringpath = session.spikeSorting.relativePath{1};
        end
        load(fullfile(basepath,clusteringpath,'cell_metrics.mat'));
        initializeSession;
        
    elseif exist('cell_metrics.mat')
        disp('Loading local cell_metrics.mat')
        load('cell_metrics.mat')
        
        initializeSession
    else
        if enableDatabase
            LoadDatabaseSession;
            if ~exist('cell_metrics')
                warning('No dataset selected')
                close(UI.fig)
                return
            end
            
        else
            warning('Neither session.mat or cell_metrics.mat exist in base folder')
            return
        end
    end
    
end


% % % % % % % % % % % % % % % % % % % % % %
% UI initialization
% % % % % % % % % % % % % % % % % % % % % %

% UI plot panels
UI.panel.subfig_ax1 = uipanel('position',[0.09 0.5 0.28 0.5],'BorderType','none');
UI.panel.subfig_ax2 = uipanel('position',[0.09+0.28 0.5 0.28 0.5],'BorderType','none');
UI.panel.subfig_ax3 = uipanel('position',[0.09+0.54 0.5 0.28 0.5],'BorderType','none');
UI.panel.subfig_ax4 = uipanel('position',[0.09 0.03 0.28 0.5-0.03],'BorderType','none');
UI.panel.subfig_ax5 = uipanel('position',[0.09+0.28 0.03 0.28 0.5-0.03],'BorderType','none');
UI.panel.subfig_ax6 = uipanel('position',[0.09+0.54 0.0 0.28 0.501],'BorderType','none');
UI.panel.subfig_ax7 = uipanel('position',[0.09+0.54 0.0 0.28 0.25],'BorderType','none');
UI.panel.subfig_ax8 = uipanel('position',[0.09+0.28 0.0 0.28 0.25],'BorderType','none');
UI.panel.subfig_ax9 = uipanel('position',[0.09 0.03 0.28 0.25],'BorderType','none');

subfig_ax(1) = axes('Parent',UI.panel.subfig_ax1);
subfig_ax(2) = axes('Parent',UI.panel.subfig_ax2);
subfig_ax(3) = axes('Parent',UI.panel.subfig_ax3);
subfig_ax(4) = axes('Parent',UI.panel.subfig_ax4);
subfig_ax(5) = axes('Parent',UI.panel.subfig_ax5);
subfig_ax(6) = axes('Parent',UI.panel.subfig_ax6);
subfig_ax(7) = axes('Parent',UI.panel.subfig_ax7);
subfig_ax(8) = axes('Parent',UI.panel.subfig_ax8);
subfig_ax(9) = axes('Parent',UI.panel.subfig_ax9);


% UI menu panels
UI.panel.navigation = uipanel('Title','Navigation','TitlePosition','centertop','Position',[0.895 0.92 0.1 0.065],'Units','normalized');
UI.panel.cellAssignment = uipanel('Title','Cell assignments','TitlePosition','centertop','Position',[0.895 0.548 0.1 0.365],'Units','normalized');
UI.panel.displaySettings = uipanel('Title','Display Settings','TitlePosition','centertop','Position',[0.895 0.115 0.1 0.425],'Units','normalized');
UI.panel.loadSave = uipanel('Title','File handling','TitlePosition','centertop','Position',[0.895 0.01 0.1 0.095],'Units','normalized');
UI.panel.custom = uipanel('Title','Plot selection','TitlePosition','centertop','Position',[0.005 0.55 0.09 0.415],'Units','normalized');

% % % % % % % % % % % % % % % % % % % %
% Message log
% % % % % % % % % % % % % % % % % % % %

UI.popupmenu.log = uicontrol('Style','popupmenu','Position',[60 2 300 10],'Units','normalized','String',{},'HorizontalAlignment','left','FontSize',10);
MsgLog('Welcome to the Cell Explorer. Press H to learn keyboard shortcuts, P to open preferences, or V to visit the wiki')


% % % % % % % % % % % % % % % % % % % %
% Navigation panel
% % % % % % % % % % % % % % % % % % % %

% Navigation buttons
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[2 2 15 12],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[18 2 18 12],'Units','normalized','String','GoTo','Callback',@(src,evnt)goToCell,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[37 2 15 12],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});


% % % % % % % % % % % % % % % % % % % %
% Cell assignments panel
% % % % % % % % % % % % % % % % % % % %

% Cell classification
colored_string = DefineCellTypeList;
UI.listbox.cellClassification = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[2 94 50 45],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyPressFcn', {@keyPress});

% Poly select and adding new cell type
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 76 24 15],'Units','normalized','String','O Polygon','Callback',@(src,evnt)GroupSelectFromPlot,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[27 76 24 15],'Units','normalized','String','+ Cell-type','Callback',@(src,evnt)AddNewCellYype,'KeyPressFcn', {@keyPress});

% Deep/Superficial
uicontrol('Parent',UI.panel.cellAssignment,'Style','text','Position',[2 65 50 10],'Units','normalized','String','Deep-Superficial','HorizontalAlignment','center');
UI.listbox.deepSuperficial = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[2 38 50 30],'Units','normalized','String',UI.settings.deepSuperficial,'max',1,'min',1,'Value',cell_metrics.deepSuperficial_num(ii),'Callback',@(src,evnt)buttonDeepSuperficial,'KeyPressFcn', {@keyPress});

% Brain region
UI.pushbutton.brainRegion = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 20 50 15],'Units','normalized','String',['Region: ', cell_metrics.brainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyPressFcn', {@keyPress});

% Custom labels
UI.pushbutton.labels = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 3 50 15],'Units','normalized','String',['Label: ', cell_metrics.labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyPressFcn', {@keyPress});


% % % % % % % % % % % % % % % % % % % %
% Display settings panel
% % % % % % % % % % % % % % % % % % % %

% Select subset of cell type
updateCellCount

UI.listbox.cellTypes = uicontrol('Parent',UI.panel.displaySettings,'Style','listbox','Position',[2 110 50 50],'Units','normalized','String',strcat(UI.settings.cellTypes,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(UI.settings.cellTypes),'Callback',@(src,evnt)buttonSelectSubset(),'KeyPressFcn', {@keyPress});

% Number of plots
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 96 20 10],'Units','normalized','String','Layout','HorizontalAlignment','left');
UI.popupmenu.plotCount = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[20 97 32 10],'Units','normalized','String',{'GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6'},'max',1,'min',1,'Value',3,'Callback',@(src,evnt)AdjustGUIbutton,'KeyPressFcn', {@keyPress});

% #1 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 86 20 10],'Units','normalized','String','1. View','HorizontalAlignment','left');
UI.popupmenu.customplot1 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 87 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleWaveformsPlot,'KeyPressFcn', {@keyPress});
if any(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); UI.popupmenu.customplot1.Value = find(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); else; UI.popupmenu.customplot1.Value = 1; disp(['The specified customCellPlotIn (', UI.settings.customCellPlotIn1 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot1 = customPlotOptions{UI.popupmenu.customplot1.Value};

% #2 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 76 25 10],'Units','normalized','String','2. View','HorizontalAlignment','left');
UI.popupmenu.customplot2 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 77 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleACGplot,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); UI.popupmenu.customplot2.Value = find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); else; UI.popupmenu.customplot2.Value = 4; disp(['The specified customCellPlotIn (', UI.settings.customCellPlotIn2 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot2 = customPlotOptions{UI.popupmenu.customplot2.Value};

% #3 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 66 35 10],'Units','normalized','String','3. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot3 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 67 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); UI.popupmenu.customplot3.Value = find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); else; UI.popupmenu.customplot3.Value = 7; disp(['The specified UI.settings.customCellPlotIn3 (', UI.settings.customCellPlotIn3 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot3 = customPlotOptions{UI.popupmenu.customplot3.Value};

% #4 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 56 35 10],'Units','normalized','String','4. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot4 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 57 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc2,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); UI.popupmenu.customplot4.Value = find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); else; UI.popupmenu.customplot4.Value = 7; disp(['The specified customCellPlotIn (', UI.settings.customCellPlotIn4 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot4 = customPlotOptions{UI.popupmenu.customplot4.Value};

% #5 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 46 35 10],'Units','normalized','String','5. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot5 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 47 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc3,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); UI.popupmenu.customplot5.Value = find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); else; UI.popupmenu.customplot5.Value = 7; disp(['The specified customCellPlotIn (', UI.settings.customCellPlotIn5 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot5 = customPlotOptions{UI.popupmenu.customplot5.Value};

% #6 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 36 35 10],'Units','normalized','String','6. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot6 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 37 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc4,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); UI.popupmenu.customplot6.Value = find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); else; UI.popupmenu.customplot5.Value = 7; disp(['The specified customCellPlotIn (', UI.settings.customCellPlotIn6 ,') in preferences could not be recogniced as an existing field name']); end
customCellPlot6 = customPlotOptions{UI.popupmenu.customplot6.Value};

if find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); UI.popupmenu.plotCount.Value = find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); else; UI.popupmenu.plotCount.Value = 3; end; AdjustGUIbutton

% Show detected synaptic connections
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 26 25 10],'Units','normalized','String','MonoSyn','HorizontalAlignment','left');
UI.popupmenu.synMono = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[24 27 28 10],'Units','normalized','String',{'None','Selected','All'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)buttonMonoSyn,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.monoSynDispIn,UI.popupmenu.synMono.String)); UI.popupmenu.synMono.Value = find(strcmp(UI.settings.monoSynDispIn,UI.popupmenu.synMono.String)); else; UI.popupmenu.synMono.Value = 1; end

% ACG window size
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 16 25 10],'Units','normalized','String','ACG window','HorizontalAlignment','left');
UI.popupmenu.ACG = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[24 17 28 10],'Units','normalized','String',{'30ms','100ms','1s'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)buttonACG,'KeyPressFcn', {@keyPress});
if strcmp(UI.settings.acgType,'Normal'); UI.popupmenu.ACG.Value = 2; elseif strcmp(UI.settings.acgType,'Narrow'); UI.popupmenu.ACG.Value = 1; else; UI.popupmenu.ACG.Value = 3; end

uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[2 8 50 10],'Units','normalized','String','Synaptic connections','HorizontalAlignment','center');
UI.checkbox.synMono1 = uicontrol('Parent',UI.panel.displaySettings,'Style','checkbox','Position',[3 2 20 10],'Units','normalized','String','Custom','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(UI.fig));
UI.checkbox.synMono2 = uicontrol('Parent',UI.panel.displaySettings,'Style','checkbox','Position',[21 2 20 10],'Units','normalized','String','Classic','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(UI.fig));
UI.checkbox.synMono3 = uicontrol('Parent',UI.panel.displaySettings,'Style','checkbox','Position',[38 2 18 10],'Units','normalized','String','tSNE','Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)uiresume(UI.fig));


% % % % % % % % % % % % % % % % % % % %
% File handling panel
% % % % % % % % % % % % % % % % % % % %

% Load database session button
UI.pushbutton.db = uicontrol('Parent',UI.panel.loadSave,'Style','pushbutton','Position',[2 15 50 12],'Units','normalized','String','Load dataset from database','Callback',@(src,evnt)LoadDatabaseSession,'Visible','on','KeyPressFcn', {@keyPress});

% Save classification
uicontrol('Parent',UI.panel.loadSave,'Style','pushbutton','Position',[2 2 50 12],'Units','normalized','String','Save classification','Callback',@(src,evnt)buttonSave,'KeyPressFcn', {@keyPress});


% % % % % % % % % % % % % % % % % % % %
% Custom plot panel (Left side)
% % % % % % % % % % % % % % % % % % % %

% Custom plotting menues
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 149 20 10],'Units','normalized','String','X data','HorizontalAlignment','left');
UI.checkbox.logx = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 152 18 10],'Units','normalized','String','Log X','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotXLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.xData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 142 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX(),'KeyPressFcn', {@keyPress});

uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 129 20 10],'Units','normalized','String','Y data','HorizontalAlignment','left');
UI.checkbox.logy = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 132 18 10],'Units','normalized','String','Log Y','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotYLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.yData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 122 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY(),'KeyPressFcn', {@keyPress});

UI.checkbox.showz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 112 24 10],'Units','normalized','String','Z data','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis(),'KeyPressFcn', {@keyPress});
UI.checkbox.logz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 112 18 10],'Units','normalized','String','Log Z','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotZLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 102 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData.Enable = 'Off';
UI.checkbox.logz.Enable = 'Off';

% Custom plot
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 90 45 10],'Units','normalized','String','Plot style','HorizontalAlignment','left');
UI.popupmenu.metricsPlot = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 82 44 10],'Units','normalized','String',{'Scatter plot','+ Smooth histograms','+ Stairs histograms'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)togglePlotHistograms,'KeyPressFcn', {@keyPress});

% Custom colors
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 70 45 10],'Units','normalized','String','Color group','HorizontalAlignment','left');
UI.popupmenu.groups = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 62 44 10],'Units','normalized','String',colorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(1),'KeyPressFcn', {@keyPress});
UI.listbox.groups = uicontrol('Parent',UI.panel.custom,'Style','listbox','Position',[3 12 42 50],'Units','normalized','String',{'Type 1','Type 2','Type 3'},'max',10,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.groups = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 2 44 10],'Units','normalized','String','Group by cell types','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.legend = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[24 72 22 10],'Units','normalized','String','Legend','HorizontalAlignment','right','Callback',@(src,evnt)buttonDispLegend(),'KeyPressFcn', {@keyPress});
UI.checkbox.legend.Value = UI.settings.dispLegend;

% % % % % % % % % % % % % % % % % % % %
% Metrics table, terminal and title
% % % % % % % % % % % % % % % % % % % %

% Table with metrics for selected cell
UI.table = uitable(UI.fig,'Data',[fieldsMenu,num2cell(table_metrics(1,:)')],'Units','normalized','Position',[0.005 0.028 0.09 0.51],'ColumnWidth',{85, 46},'columnname',{'Metrics',''},'RowName',[],'CellSelectionCallback',@ClicktoSelectFromTable); % [10 10 150 575] {85, 46} %
UI.checkbox.showtable = uicontrol('Style','checkbox','Position',[5 2 50 10],'Units','normalized','String','Show Metrics table','HorizontalAlignment','left','Value',1,'Callback',@(src,evnt)buttonShowMetrics(),'KeyPressFcn', {@keyPress});
if ~UI.settings.displayMetricsTable; UI.table.Visible='Off'; UI.checkbox.showtable.Value = 0; end

% Title with name of current session and details about the selected cell
UI.title = uicontrol('Style','text','Position',[185 410 200 10],'Units','normalized','String',{'Cell details'},'HorizontalAlignment','center','FontSize',13);
UI.benchmark = uicontrol('Style','text','Position',[3 410 100 10],'Units','normalized','String','Benchmark','HorizontalAlignment','left','FontSize',13,'ForegroundColor',[0.3 0.3 0.3]);

% Maximazing figure to full screen
if ~verLessThan('matlab', '9.4')
    set(UI.fig,'WindowState','maximize')
else
    drawnow; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); %
end

% % % % % % % % % % % % % % % % % % % % % %
% Main loop of UI
% % % % % % % % % % % % % % % % % % % % % %

while ii <= size(cell_metrics.troughToPeak,2) & exit == 0
    
    if ~ishandle(UI.fig)
        break
    end
    
    if ii_history(end) ~= ii
        ii_history = [ii_history,ii];
    end
    
    % Instantiates batch metrics
    if BatchMode
        batchIDs = cell_metrics.batchIDs(ii);
        general = cell_metrics.general.batch{batchIDs};
    else
        general = cell_metrics.general;
        batchIDs = 1;
    end
    
    ClickedCells = [];
    globalZoom = cell(1,9);
    
    if strcmp(UI.table.Visible,'on')
        pos1 = getpixelposition(UI.table,true);
        pos1 = max(pos1(3),150);
        UI.table.ColumnWidth = {pos1*2/3-10, pos1*1/3-10};
        UI.table.Data = [fieldsMenu,num2cell(table_metrics(ii,:)')];
    end
    
    UI.listbox.cellClassification.Value = clusClas(ii);
    subset = find(ismember(clusClas,classes2plot));
    
    if ~isempty(groups2plot2) && Colorval ~=1
        if UI.checkbox.groups.Value == 0
            subset2 = find(ismember(plotClas,groups2plot2));
        else
            subset2 = find(ismember(plotClas2,groups2plot2));
        end
        subset = intersect(subset,subset2);
    end
    
    if isfield(cell_metrics,'putativeConnections')
        putativeSubset = find(sum(ismember(cell_metrics.putativeConnections,subset)')==2);
    else
        putativeSubset=[];
    end
    
    if ~isempty(putativeSubset)
        a1 = cell_metrics.putativeConnections(putativeSubset,1);
        a2 = cell_metrics.putativeConnections(putativeSubset,2);
        inbound = find(a2 == ii);
        outbound = find(a1 == ii);
    end
    
    % Synaptic cell types
    if UI.settings.displayExcitatory && ~isempty(cellsExcitatory)
        cellsExcitatory_subset = intersect(subset,cellsExcitatory);
    end
    if UI.settings.displayInhibitory && ~isempty(cellsInhibitory)
        cellsInhibitory_subset = intersect(subset,cellsInhibitory);
    end
    
    % Group display definition
    if Colorval == 1 ||  UI.checkbox.groups.Value == 1
        clr = UI.settings.cellTypeColors(intersect(classes2plot,clusClas(subset)),:);
    else
        clr = hsv(length(nanUnique(plotClas(subset))))*0.8;
        if isnan(clr)
            clr = UI.settings.cellTypeColors(1,:);
        end
    end
    
    classes2plotSubset = intersect(plotClas(subset),classes2plot);
    if isfield(cell_metrics,'sessionName')
        UI.title.String = ['Cell: ', num2str(ii),'/', num2str(size(cell_metrics.firingRate,2)),' from ', cell_metrics.sessionName{ii}, '.  Class: ', UI.settings.cellTypes{clusClas(ii)}];
    else
        UI.title.String = ['Cell: ', num2str(ii),'/', num2str(size(cell_metrics.firingRate,2)),'.  Class: ', UI.settings.cellTypes{clusClas(ii)}];
    end

    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    
    if customPlotHistograms == 0
        if size(UI.panel.subfig_ax1.Children,1) > 1
            axes(UI.panel.subfig_ax1.Children(2));
        else
            axes(UI.panel.subfig_ax1.Children);
        end
        [az,el] = view;
    end
    delete(UI.panel.subfig_ax1.Children)
    subfig_ax(1) = axes('Parent',UI.panel.subfig_ax1);
    if customPlotHistograms == 0
        if UI.settings.layout == 1
            set(subfig_ax(1),'LooseInset',get(gca,'TightInset'))
        end
        hold on
        xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
        xlim auto, ylim auto, zlim auto
        if UI.checkbox.logx.Value==1
            set(subfig_ax(1), 'XScale', 'log')
        else
            set(subfig_ax(1), 'XScale', 'linear')
        end
        if UI.checkbox.logy.Value==1
            set(subfig_ax(1), 'YScale', 'log')
        else
            set(subfig_ax(1), 'YScale', 'linear')
        end
        
        if UI.settings.plot3axis == 0
            set(subfig_ax(1),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
            view([0 90]);
            if ~isempty(clr)
                legendScatter = gscatter(plotX(subset), plotY(subset), plotClas(subset), clr,'',20,'off');
                set(legendScatter,'HitTest','off')
            end
            
            if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
                plot(plotX(cellsExcitatory_subset), plotY(cellsExcitatory_subset),'^k', 'HitTest','off')
            end
            if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
                plot(plotX(cellsInhibitory_subset), plotY(cellsInhibitory_subset),'ok', 'HitTest','off')
            end
            
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 2, 'MarkerSize',20, 'HitTest','off')
            
            if  UI.checkbox.synMono1.Value == 1
                switch monoSynDisp
                    case 'All'
                        if ~isempty(putativeSubset)
                            plot([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],'-ok','HitTest','off')
                        end
                    case 'Selected'
                        if ~isempty(putativeSubset)
                            plot([plotX(a1(inbound));plotX(a2(inbound))],[plotY(a1(inbound));plotY(a2(inbound))],'-ok','HitTest','off')
                            plot([plotX(a1(outbound));plotX(a2(outbound))],[plotY(a1(outbound));plotY(a2(outbound))],'-om','HitTest','off')
                        end
                end
            end
            axis tight
        else
            view([az,el]);
            %             view([40 20]);
            if UI.settings.plotZLog == 1
                set(gca, 'ZScale', 'log')
            else
                set(gca, 'ZScale', 'linear')
            end
            
            legendScatter = [];
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                legendScatter(jj) = scatter3(plotX(set1), plotY(set1), plotZ(set1), 'MarkerFaceColor', clr(jj,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
            end
            
            if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
                plot3(plotX(cellsExcitatory_subset), plotY(cellsExcitatory_subset), plotZ(cellsExcitatory_subset),'^k', 'HitTest','off')
            end
            if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
                plot3(plotX(cellsInhibitory_subset), plotY(cellsInhibitory_subset), plotZ(cellsInhibitory_subset),'ok', 'HitTest','off')
            end
            
            plot3(plotX(ii), plotY(ii), plotZ(ii),'xk', 'LineWidth', 2, 'MarkerSize',20)
            
            if  UI.checkbox.synMono1.Value == 1
                switch monoSynDisp
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
            rotateFig1
        end
        
        if contains(plotX_title,'_num')
            xticks([1:length(groups_ids.(plotX_title))]), xticklabels(groups_ids.(plotX_title)),xtickangle(20),xlim([0.5,length(groups_ids.(plotX_title))+0.5]),xlabel(plotX_title(1:end-4), 'Interpreter', 'none')
        end
        if contains(plotY_title,'_num')
            yticks([1:length(groups_ids.(plotY_title))]), yticklabels(groups_ids.(plotY_title)),ytickangle(65),ylim([0.5,length(groups_ids.(plotY_title))+0.5]),ylabel(plotY_title(1:end-4), 'Interpreter', 'none')
        end
        axis tight
        [az,el] = view;
        if ~isempty(subset) && UI.settings.layout == 1 && UI.settings.dispLegend == 1
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northeast','Box','off','AutoUpdate','off');
        end
        
    elseif customPlotHistograms == 1
        % Double kernel-histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',plotClas(subset),'Kernel','on','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',UI.panel.subfig_ax1,'Legend','off','Color',clr); hold on % ,'Style','stairs'
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent',h_scatter(1))
            axis(h_scatter(1),'tight');
            if UI.checkbox.logx.Value==1
                set(h_scatter(1), 'XScale', 'log')
                set(h_scatter(2), 'XScale', 'log')
            else
                set(h_scatter(1), 'XScale', 'linear')
                set(h_scatter(2), 'XScale', 'linear')
            end
            if UI.checkbox.logy.Value==1
                set(h_scatter(1), 'YScale', 'log')
                set(h_scatter(3), 'XScale', 'log')
            else
                set(h_scatter(1), 'YScale', 'linear')
                set(h_scatter(3), 'XScale', 'linear')
            end
        end
        if ~isempty(subset) && UI.settings.layout == 1  && UI.settings.dispLegend == 1
            legendScatter = h_scatter(1).Children;
            legendScatter = legendScatter(end-length(nanUnique(plotClas(subset)))+1:end);
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northeast','Box','off','AutoUpdate','off');
        end
    else
        % Double stairs-histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',plotClas(subset),'Style','stairs','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',UI.panel.subfig_ax1,'Legend','off','Color',clr); hold on % ,
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent',h_scatter(1))
            if length(unique(plotClas(subset)))==2
                G1 = plotX(subset);
                G = findgroups(plotClas(subset));
                if ~isempty(subset(G==1)) && length(subset(G==2))>0
                    [h,p] = kstest2(plotX(subset(G==1)),plotX(subset(G==2)));
                    text(1.04,0.01,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90)
                    [h,p] = kstest2(plotY(subset(G==1)),plotY(subset(G==2)));
                    text(0.01,1.04,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized')
                end
            end
            axis(h_scatter(1),'tight');
            if UI.checkbox.logx.Value==1
                set(h_scatter(1), 'XScale', 'log')
                set(h_scatter(2), 'XScale', 'log')
            else
                set(h_scatter(1), 'XScale', 'linear')
                set(h_scatter(2), 'XScale', 'linear')
            end
            if UI.checkbox.logy.Value==1
                set(h_scatter(1), 'YScale', 'log')
                set(h_scatter(3), 'XScale', 'log')
            else
                set(h_scatter(1), 'YScale', 'linear')
                set(h_scatter(3), 'XScale', 'linear')
            end
        end
        
        if ~isempty(subset) && UI.settings.layout == 1  && UI.settings.dispLegend == 1
            legendScatter = h_scatter(1).Children;
            legendScatter = legendScatter(end-length(nanUnique(plotClas(subset)))+1:end);
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northeast','Box','off','AutoUpdate','off');
        end
        
    end
    
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 2
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax2.Visible,'on')
        delete(UI.panel.subfig_ax2.Children)
        subfig_ax(2) = axes('Parent',UI.panel.subfig_ax2);
        set(subfig_ax(2),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        
        if ~isempty(clr)
            legendScatter = gscatter(cell_metrics.troughToPeak(subset) * 1000, cell_metrics.burstIndex_Royer2012(subset), plotClas(subset), clr,'',25,'off');
            set(legendScatter,'HitTest','off')
        end
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(cell_metrics.troughToPeak(cellsExcitatory_subset) * 1000, cell_metrics.burstIndex_Royer2012(cellsExcitatory_subset),'^k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(cell_metrics.troughToPeak(cellsInhibitory_subset) * 1000, cell_metrics.burstIndex_Royer2012(cellsInhibitory_subset),'ok', 'HitTest','off')
        end
        
        ylabel('Burst Index (Royer 2012)'); xlabel('Trough-to-Peak (µs)'),
        set(gca, 'YScale', 'log'); axis tight
        
        % cell to check
        plot(cell_metrics.troughToPeak(ii) * 1000, cell_metrics.burstIndex_Royer2012(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent', subfig_ax(2),'HitTest','off');
        
        if ~isempty(putativeSubset) && UI.checkbox.synMono2.Value == 1
            switch monoSynDisp
                case 'All'
                    plot([cell_metrics.troughToPeak(a1);cell_metrics.troughToPeak(a2)] * 1000,[cell_metrics.burstIndex_Royer2012(a1);cell_metrics.burstIndex_Royer2012(a2)],'-ok','HitTest','off')
                case 'Selected'
                    plot([cell_metrics.troughToPeak(a1(inbound));cell_metrics.troughToPeak(a2(inbound))] * 1000,[cell_metrics.burstIndex_Royer2012(a1(inbound));cell_metrics.burstIndex_Royer2012(a2(inbound))],'-ok','HitTest','off')
                    plot([cell_metrics.troughToPeak(a1(outbound));cell_metrics.troughToPeak(a2(outbound))] * 1000,[cell_metrics.burstIndex_Royer2012(a1(outbound));cell_metrics.burstIndex_Royer2012(a2(outbound))],'-om','HitTest','off')
            end
        end
        if ~isempty(subset) && UI.settings.layout >2 && UI.settings.dispLegend == 1
            legend111 = legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northwest','Box','off','AutoUpdate','off');
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax3.Visible,'on')
        delete(UI.panel.subfig_ax3.Children)
        subfig_ax(3) = axes('Parent',UI.panel.subfig_ax3);
        set(subfig_ax(3),'ButtonDownFcn',@ClicktoSelectFromPlot)
        cla, hold on
        if ~isempty(clr)
            legendScatter = gscatter(tSNE_metrics.plot(subset,1), tSNE_metrics.plot(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter,'HitTest','off')
        end
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(tSNE_metrics.plot(cellsExcitatory_subset,1), tSNE_metrics.plot(cellsExcitatory_subset,2),'^k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(tSNE_metrics.plot(cellsInhibitory_subset,1), tSNE_metrics.plot(cellsInhibitory_subset,2),'ok', 'HitTest','off')
        end
        
        plot(tSNE_metrics.plot(ii,1), tSNE_metrics.plot(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off'); axis tight
        
        if ~isempty(putativeSubset) && UI.checkbox.synMono3.Value == 1
            plotX1 = tSNE_metrics.plot(:,1)';
            plotY1 = tSNE_metrics.plot(:,2)';
            switch monoSynDisp
                case 'All'
                    if ~isempty(putativeSubset)
                        plot([plotX1(a1);plotX1(a2)],[plotY1(a1);plotY1(a2)],'-ok','HitTest','off')
                    end
                case 'Selected'
                    if ~isempty(putativeSubset)
                        plot([plotX1(a1(inbound));plotX1(a2(inbound))],[plotY1(a1(inbound));plotY1(a2(inbound))],'-ok','HitTest','off')
                        plot([plotX1(a1(outbound));plotX1(a2(outbound))],[plotY1(a1(outbound));plotY1(a2(outbound))],'-om','HitTest','off')
                    end
            end
        end
        
        xlabel('t-SNE')
        if ~isempty(subset) && UI.settings.layout == 2  && UI.settings.dispLegend == 1
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northeast','Box','off','AutoUpdate','off');
        end
    end
    
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 4
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(UI.panel.subfig_ax4.Children)
    subfig_ax(4) = axes('Parent',UI.panel.subfig_ax4);
    set(subfig_ax(4),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
    subsetPlots1 = customPlot(customCellPlot1,ii,general,batchIDs);
    
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 5
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(UI.panel.subfig_ax5.Children)
    subfig_ax(5) = axes('Parent',UI.panel.subfig_ax5);
    set(subfig_ax(5),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
    subsetPlots2 = customPlot(customCellPlot2,ii,general,batchIDs);
    
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 6
    % % % % % % % % % % % % % % % % % % % % % %
    
    delete(UI.panel.subfig_ax6.Children)
    subfig_ax(6) = axes('Parent',UI.panel.subfig_ax6);
    set(subfig_ax(6),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
    subsetPlots3 = customPlot(customCellPlot3,ii,general,batchIDs);
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 7
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax7.Visible,'on')
        delete(UI.panel.subfig_ax7.Children)
        subfig_ax(7) = axes('Parent',UI.panel.subfig_ax7);
        set(subfig_ax(7),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        subsetPlots4 = customPlot(customCellPlot4,ii,general,batchIDs);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 8
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax8.Visible,'on')
        delete(UI.panel.subfig_ax8.Children)
        subfig_ax(8) = axes('Parent',UI.panel.subfig_ax8);
        set(subfig_ax(8),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        subsetPlots5 = customPlot(customCellPlot5,ii,general,batchIDs);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 9
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax9.Visible,'on')
        delete(UI.panel.subfig_ax9.Children)
        subfig_ax(9) = axes('Parent',UI.panel.subfig_ax9);
        set(subfig_ax(9),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        subsetPlots6 = customPlot(customCellPlot6,ii,general,batchIDs);
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Bechmarking the UI
    % % % % % % % % % % % % % % % % % % % % % %
    UI.benchmark.String = toc(timerVal);
    
    % % % % % % % % % % % % % % % % % % % % % %
    uiwait(UI.fig);
    timerVal = tic;
end


% % % % % % % % % % % % % % % % % % % % % %
% Calls when closing
% % % % % % % % % % % % % % % % % % % % % %

if ishandle(UI.fig)
    close(UI.fig);
end
numeric_fields = fieldnames(cell_metrics);
cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
[C, ~, ic] = unique(clusClas,'sorted');
for i = 1:length(C)
    cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.settings.cellTypes{C(i)}},sum(ic==i),1);
end
cell_metrics.general.SWR_batch = SWR_batch;
cell_metrics.general.tSNE_metrics = tSNE_metrics;
cell_metrics.general.classificationTrackChanges = classificationTrackChanges;


% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

    function subsetPlots = customPlot(customPlotSelection,ii,general,batchIDs)
        
        subsetPlots = [];
        col = UI.settings.cellTypeColors(clusClas(ii),:);
        
        % Waveforms
        if strcmp(customPlotSelection,'Single waveform')
            if isfield(cell_metrics,'filtWaveform_std')
                patch([cell_metrics.timeWaveform{ii},flip(cell_metrics.timeWaveform{ii})]', [cell_metrics.filtWaveform{ii}+cell_metrics.filtWaveform_std{ii},flip(cell_metrics.filtWaveform{ii}-cell_metrics.filtWaveform_std{ii})],'black','EdgeColor','none','FaceAlpha',.2)
                plot(cell_metrics.timeWaveform{ii}, cell_metrics.filtWaveform{ii}, 'color', col,'linewidth',2), grid on
                hLeg = legend({'Std','Wavefom'},'Location','southwest','Box','off'); set(hLeg,'visible','on');
            else
                plot(cell_metrics.timeWaveform{ii}, cell_metrics.filtWaveform{ii}, 'color', col,'linewidth',2), grid on
            end
            xlabel('Time (ms)'), title('Waveform (µV)'), axis tight, 

        elseif strcmp(customPlotSelection,'All waveforms')
            
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                plot(time_waveforms_zscored, cell_metrics.filtWaveform_zscored(:,set1), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            plot(time_waveforms_zscored, cell_metrics.filtWaveform_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Time (ms)'),title('Waveform zscored'), axis tight, hLeg = legend('p'); set(hLeg,'visible','off');
            
        elseif strcmp(customPlotSelection,'tSNE of waveforms')
            
            legendScatter4 = gscatter(tSNE_metrics.filtWaveform(subset,1), tSNE_metrics.filtWaveform(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter4,'HitTest','off')
            title('Waveforms - tSNE visualization'), axis tight, xlabel(''),ylabel(''), hold on
            plot(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
            
        elseif strcmp(customPlotSelection,'Single ACG') % ACGs
            
            if strcmp(UI.settings.acgType,'Normal')
                bar([-100:100]/2,cell_metrics.acg2(:,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-50:10:50]),xlim([-50,50])
            elseif strcmp(UI.settings.acgType,'Narrow')
                bar([-30:30]/2,cell_metrics.acg2(41+30:end-40-30,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-15:5:15]),xlim([-15,15])
            else
                bar([-500:500],cell_metrics.acg(:,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-500:100:500]),xlim([-500,500])
            end
            
            if plotAcgFit
                a = cell_metrics.acg_tau_decay(ii); b = cell_metrics.acg_tau_rise(ii); c = cell_metrics.acg_c(ii); d = cell_metrics.acg_d(ii);
                e = cell_metrics.acg_asymptote(ii); f = cell_metrics.acg_refrac(ii); g = cell_metrics.acg_tau_burst(ii); h = cell_metrics.acg_h(ii);
                x = 1:0.2:50;
                fiteqn = max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0);
                plot([-flip(x),x],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
            end
            
            ax5 = axis; grid on
            plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); plot([ax5(1) ax5(2)],cell_metrics.firingRate(ii)*[1 1],'--k')
            xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.firingRate(ii),3),'Hz'])
            
        elseif strcmp(customPlotSelection,'All ACGs')
            
            if strcmp(UI.settings.acgType,'Normal')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    plot([-100:100]/2,cell_metrics.acg2(:,set1), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-100:100]/2,cell_metrics.acg2(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-50:10:50]),xlim([-50,50])
            elseif strcmp(UI.settings.acgType,'Narrow')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    plot([-30:30]/2,cell_metrics.acg2(41+30:end-40-30,set1), 'color', [clr(jj,:),0.2])
                end
                plot([-30:30]/2,cell_metrics.acg2(41+30:end-40-30,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-15:5:15]),xlim([-15,15])
            else
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    plot([-500:500],cell_metrics.acg(:,set1), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-500:500],cell_metrics.acg(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-500:100:500]),xlim([-500,500])
            end
            xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.firingRate(ii),3),'Hz'])
            
        elseif strcmp(customPlotSelection,'tSNE of narrow ACGs')
            
            legendScatter5 = gscatter(tSNE_metrics.acg2(subset,1), tSNE_metrics.acg2(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter5,'HitTest','off')
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel(''), hold on
            plot(tSNE_metrics.acg2(ii,1), tSNE_metrics.acg2(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of wide ACGs')
            
            if ~isempty(clr)
                legendScatter5 = gscatter(tSNE_metrics.acg1(subset,1), tSNE_metrics.acg1(subset,2), plotClas(subset), clr,'',20,'off');
                set(legendScatter5,'HitTest','off')
            end
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel(''), hold on
            plot(tSNE_metrics.acg1(ii,1), tSNE_metrics.acg1(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'Sharp wave-ripple')
            
            if BatchMode
                SWR = SWR_batch{cell_metrics.batchIDs(ii)};
            else
                SWR = SWR_batch;
            end
            
            spikeGroup = cell_metrics.spikeGroup(ii);
            if ~isempty(SWR) & isfield(SWR,'SWR_diff') & spikeGroup <= length(SWR.ripple_power)
                ripple_power_temp = SWR.ripple_power{spikeGroup}/max(SWR.ripple_power{spikeGroup}); grid on
                
                plot((SWR.SWR_diff{spikeGroup}*50)+SWR.ripple_time_axis(1)-50,-[0:size(SWR.SWR_diff{spikeGroup},2)-1]*0.04,'-k','linewidth',2, 'HitTest','off')
                
                for jj = 1:size(SWR.ripple_average{spikeGroup},2)
                    text(SWR.ripple_time_axis(end)+5,SWR.ripple_average{spikeGroup}(end,jj)-(jj-1)*0.04,[num2str(round(SWR.channelDistance(SWR.ripple_channels{spikeGroup}(jj))))])
                    %         text((ripple_power_temp(jj)*50)+SWR.ripple_time_axis(1)-50+12,-(jj-1)*0.04,num2str(SWR.ripple_channels{spikeGroup}(jj)))
                    if strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Superficial')
                        plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*0.04,'r','linewidth',1, 'HitTest','off')
                        plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'or','linewidth',2, 'HitTest','off')
                    elseif strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Deep')
                        plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*0.04,'b','linewidth',1, 'HitTest','off')
                        plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'ob','linewidth',2, 'HitTest','off')
                    elseif strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Cortical')
                        plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*0.04,'g','linewidth',1, 'HitTest','off')
                        plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'og','linewidth',2, 'HitTest','off')
                    else
                        plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*0.04,'k', 'HitTest','off')
                        plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*0.04,'ok', 'HitTest','off')
                    end
                end
                
                if any(SWR.ripple_channels{spikeGroup} == cell_metrics.maxWaveformCh(ii)+1)
                    jjj = find(SWR.ripple_channels{spikeGroup} == cell_metrics.maxWaveformCh(ii)+1);
                    plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jjj)-(jjj-1)*0.04,':k','linewidth',2, 'HitTest','off')
                end
                axis tight, ax6 = axis; grid on
                plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                xlim([-220,SWR.ripple_time_axis(end)+50]), xticks([-120:40:120])
                title(['SWR spikeGroup ', num2str(spikeGroup)]),xlabel('Time (ms)'), ylabel('Ripple (mV)')
                ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
                ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
                ht3 = text(0.98,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
            else
                text(0.5,0.5,'No sharp wave-ripple defined for this session','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif strcmp(customPlotSelection,'firingRateMap')
            
            if isfield(cell_metrics,'firingRateMap') && ~isempty(cell_metrics.firingRateMap{ii})
                firingRateMap = cell_metrics.firingRateMap{ii};
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'x_bins')
                    x_bins = general.(customPlotSelection).x_bins;
                else
                    x_bins = [1:length(firingRateMap)];
                end
                plot(x_bins,firingRateMap,'-','color', 'k','linewidth',2, 'HitTest','off'), xlabel('Position (cm)'),ylabel('Rate (Hz)')
                
                switch monoSynDisp
                    case {'Selected','All'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.firingRateMap{[a2(outbound);a1(inbound)]});
                        subsetPlots.subset = [a2(outbound);a1(inbound)];
                        if ~isempty(outbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMap{a2(outbound)}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(inbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMap{a1(inbound)}),'color', 'k', 'HitTest','off')
                        end
                end
                axis tight, ax6 = axis; grid on,
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No firing rate map for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title('Firing rate map')
            
        elseif contains(customPlotSelection,{'firingRateMap','FiringRateMap'})
            
            if isfield(cell_metrics,customPlotSelection) && ~isempty(cell_metrics.(customPlotSelection){batchIDs})
                firingRateMap = permute(cell_metrics.(customPlotSelection){batchIDs},[1,3,2]);
                
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'x_bins')
                    x_bins = general.(customPlotSelection).x_bins;
                else
                    x_bins = [1:size(firingRateMap,1)];
                end
                plt1 = plot(x_bins,firingRateMap(:,:,cell_metrics.UID(ii)),'-','linewidth',2, 'HitTest','off'); hold on
                
                xlabel('Position (cm)'),ylabel('Rate (Hz)')
                axis tight, ax6 = axis; grid on,
                
                if isfield(general,customPlotSelection)
                    if isfield(general.(customPlotSelection),'labels')
                        legend(general.(customPlotSelection).labels,'Location','northeast','Box','off','AutoUpdate','off')
                    else
                        lgend212 = legend(plt1);
                        set(lgend212,'Location','northeast','Box','off','AutoUpdate','off')
                    end
                    if isfield(general.(customPlotSelection),'boundaries')
                        boundaries = general.(customPlotSelection).boundaries;
                        plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                    end
                end
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No firing rate map for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title(customPlotSelection, 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,{'psth'})
            
            if isfield(cell_metrics,customPlotSelection) && ~isempty(cell_metrics.(customPlotSelection){ii})
                psth_response = cell_metrics.(customPlotSelection){ii};
                
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'x_bins')
                    x_bins = general.(customPlotSelection).x_bins;
                else
                    x_bins = [1:size(psth_response,1)];
                end
                plot(x_bins,psth_response,'color', 'k','linewidth',2, 'HitTest','off')
                
                switch monoSynDisp
                    case {'Selected','All'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.(customPlotSelection){[a2(outbound);a1(inbound)]});
                        subsetPlots.subset = [a2(outbound);a1(inbound)];
                        if ~isempty(outbound)
                            plot(x_bins,horzcat(cell_metrics.(customPlotSelection){a2(outbound)}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(inbound)
                            plot(x_bins,horzcat(cell_metrics.(customPlotSelection){a1(inbound)}),'color', 'k', 'HitTest','off')
                        end
                end
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
                if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No PSTH for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            
            title(customPlotSelection, 'Interpreter', 'none'), xlabel('Time (s)'),ylabel('Rate (Hz)')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            
        elseif strcmp(customPlotSelection,'rippleCorrelogram')
            
            if isfield(cell_metrics,'rippleCorrelogram') && ~isempty(cell_metrics.rippleCorrelogram{ii})
                rippleCorrelogram = cell_metrics.rippleCorrelogram{ii};
                
                if isfield(general,customPlotSelection) & isfield(general.rippleCorrelogram,'x_bins')
                    x_bins = general.rippleCorrelogram.x_bins;
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                if ~isempty(putativeSubset)
                    switch monoSynDisp
                        case {'Selected','All'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.rippleCorrelogram{[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.rippleCorrelogram{a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.rippleCorrelogram{a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                plot(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'), xlabel('time'),ylabel('Voltage')
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No ripple correlogram for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title('Ripple Correlogram', 'Interpreter', 'none')
            
        elseif strcmp(customPlotSelection,'firingRateAcrossTime')
            
            if isfield(cell_metrics,customPlotSelection) && ~isempty(cell_metrics.firingRateAcrossTime{ii})
                firingRateAcrossTime = cell_metrics.firingRateAcrossTime{ii};
                
                if isfield(general,customPlotSelection) & isfield(general.firingRateAcrossTime,'x_bins')
                    x_bins = general.firingRateAcrossTime.x_bins;
                else
                    x_bins = [1:length(firingRateAcrossTime)];
                end
                plt1 = plot(x_bins,firingRateAcrossTime,'color', 'k','linewidth',2, 'HitTest','off'); hold on
                
                if ~isempty(putativeSubset)
                    switch monoSynDisp
                        case {'Selected','All'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.firingRateAcrossTime{[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.firingRateAcrossTime{a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.firingRateAcrossTime{a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                xlabel('Time (minutes)'), ylabel('Rate (Hz)')
                axis tight, ax6 = axis; grid on,
                
                if isfield(general,customPlotSelection)
                    if isfield(general.firingRateAcrossTime,'boundaries')
                        boundaries = general.firingRateAcrossTime.boundaries;
                        plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                        if isfield(general.firingRateAcrossTime,'boundaries_labels')
                            boundaries_labels = general.firingRateAcrossTime.boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90);
                            end
                        end
                    end
                end
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No firing rate map for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title(customPlotSelection, 'Interpreter', 'none')
            
        elseif strcmp(customPlotSelection,'thetaPhaseResponse')
            
            if isfield(cell_metrics,customPlotSelection) && ~isempty(cell_metrics.thetaPhaseResponse{ii})
                thetaPhaseResponse = cell_metrics.thetaPhaseResponse{ii};
                if isfield(general,customPlotSelection) & isfield(general.thetaPhaseResponse,'x_bins')
                    x_bins = general.thetaPhaseResponse.x_bins;
                else
                    x_bins = [1:length(thetaPhaseResponse)];
                end
                plt1 = plot(x_bins,thetaPhaseResponse,'color', 'k','linewidth',2, 'HitTest','off'); hold on
                
                if ~isempty(putativeSubset)
                    switch monoSynDisp
                        case {'Selected','All'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.thetaPhaseResponse{[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.thetaPhaseResponse{a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.thetaPhaseResponse{a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                axis tight, ax6 = axis; grid on,
            else
                text(0.5,0.5,'No Theta Phase Response for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title('Theta Phase Response'), xlabel('Phase'), ylabel('Probability')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            
        elseif contains(customPlotSelection,{'spikes_'})
            
            out = CheckSpikes(batchIDs);
            if out && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).x) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).y)
                if ~isempty(spikesPlots.(customPlotSelection).state) & isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state) & ~isempty(nanUnique(spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)}))
                    if isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state)
                        plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)},'.k'), hold on
                        if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                            plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi,'.k')
                        end
                        legendScatter = gscatter(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}, spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)},[],'',8,'off'); %,
                        hold on
                        if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                            gscatter(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi, spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)},[],'',8,'off'); %,
                            yticks([-pi,0,pi,2*pi,3*pi]),yticklabels({'-\pi','0','\pi','2\pi','3\pi'}),ylim([-pi,3*pi])
                        
                        end
                        if ~isempty(subset) && UI.settings.dispLegend == 1
                            legend(legendScatter, {},'Location','northeast','Box','off','AutoUpdate','off');
                        end
                    else
                        text(0.5,0.5,'No data for this cell','FontWeight','bold','HorizontalAlignment','center')
                    end
                else
                    plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)},'.','color', col), hold on
                    if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                        plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi,'.','color', col)
                        yticks([-pi,0,pi,2*pi,3*pi]),yticklabels({'-\pi','0','\pi','2\pi','3\pi'}),ylim([-pi,3*pi])
                    end
                    
                end
                axis tight
            else
                text(0.5,0.5,'No data for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            xlabel(spikesPlots.(customPlotSelection).x_label), ylabel(spikesPlots.(customPlotSelection).y_label), title(customPlotSelection,'Interpreter', 'none')

        else
            
            customCellPlotNum = find(strcmp(customPlotSelection, customPlotOptions));
            if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'x_bins')
                x_bins = general.(customPlotSelection).x_bins;
            else
                x_bins = [1:length(cell_metrics.(customPlotOptions{customCellPlotNum})(:,ii))];
            end
            plot(x_bins,cell_metrics.(customPlotOptions{customCellPlotNum})(:,ii),'color', 'k','linewidth',2, 'HitTest','off')
            
            switch monoSynDisp
                case {'All'}
                    subsetPlots.xaxis = x_bins;
                    subsetPlots.yaxis = cell_metrics.(customPlotOptions{customCellPlotNum})(:,a2(outbound));
                    subsetPlots.subset = a2(outbound);
                    plot(x_bins,cell_metrics.(customPlotOptions{customCellPlotNum})(:,a2(outbound)),'color', [0,0,0,.5])
                case 'Selected'
                    subsetPlots.xaxis = x_bins;
                    subsetPlots.yaxis = cell_metrics.(customPlotOptions{customCellPlotNum})(:,[a2(outbound);a1(inbound)]);
                    subsetPlots.subset = [a2(outbound);a1(inbound)];
                    if ~isempty(outbound)
                        plot(x_bins,cell_metrics.(customPlotOptions{customCellPlotNum})(:,a2(outbound)),'color', 'm', 'HitTest','off')
                    end
                    if ~isempty(inbound)
                        plot(x_bins,cell_metrics.(customPlotOptions{customCellPlotNum})(:,a1(inbound)),'color', 'k', 'HitTest','off')
                    end
            end
            title(customPlotOptions{customCellPlotNum}, 'Interpreter', 'none'), xlabel(''),ylabel('')
            axis tight, ax6 = axis; grid on
            plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
            if isfield(general,customPlotSelection)
                if isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                    if isfield(general.(customPlotSelection),'boundaries_labels')
                        boundaries_labels = general.(customPlotSelection).boundaries_labels;
                        text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90);
                    end
                end
                
            end
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function tSNE_redefineMetrics
        disp('')
        subfieldsnames =  fieldnames(cell_metrics);
        subfieldstypes = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        subfieldssizes = struct2cell(structfun(@size,cell_metrics,'UniformOutput',false));
        subfieldssizes = cell2mat(subfieldssizes);
        temp = find(strcmp(subfieldstypes,'double') & subfieldssizes(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames,'_num'));
        list_tSNE_metrics = sort(subfieldsnames(temp));
        subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','SpikeGroup','SpikeSortingID'};
        list_tSNE_metrics = setdiff(list_tSNE_metrics,subfieldsExclude);
        [~,ia,~] = intersect(list_tSNE_metrics,UI.settings.tSNE_metrics);
        list_tSNE_metrics = [list_tSNE_metrics(ia);list_tSNE_metrics(setdiff(1:length(list_tSNE_metrics),ia))];
        [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[250,400],'InitialValue',1:length(ia));
        if ~isempty(indx)
            f_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
            X = cell2mat(cellfun(@(X) cell_metrics.(X),list_tSNE_metrics(indx),'UniformOutput',false));
            UI.settings.tSNE_metrics = list_tSNE_metrics(indx);
            X(isnan(X) | isinf(X)) = 0;
            waitbar(0.1,f_waitbar,'Calculating tSNE space...')
            
            tSNE_metrics.plot = tsne(X','Standardize',true);
            waitbar(1,f_waitbar,'tSNE space calculations complete.')
            uiresume(UI.fig);
            if ishandle(f_waitbar)
                close(f_waitbar)
            end
            MsgLog('tSNE space calculations complete.');
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ii_history_reverse
        if length(ii_history)>1
            ii_history(end) = [];
            ii = ii_history(end);
            MsgLog(['Previous cell selected: ', num2str(ii)])
            uiresume(UI.fig);
        else
            MsgLog('No further cell selection history available')
            
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonCellType(selectedClas)
        if any(selectedClas == [1:length(UI.settings.cellTypes)])
            saveStateToHistory(ii)
            clusClas(ii) = selectedClas;
            MsgLog(['Cell ', num2str(ii), ' classified as ', UI.settings.cellTypes{selectedClas}]);
            updateCellCount
            updatePlotClas
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function saveStateToHistory(cellIDs)
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).cellIDs = cellIDs;
        history_classification(hist_idx).cellTypes = clusClas(cellIDs);
        history_classification(hist_idx).deepSuperficial = cell_metrics.deepSuperficial{cellIDs};
        history_classification(hist_idx).brainRegion = cell_metrics.brainRegion{cellIDs};
        history_classification(hist_idx).deepSuperficial_num = cell_metrics.deepSuperficial_num(cellIDs);
        classificationTrackChanges = [classificationTrackChanges,cellIDs];
    end

% % % % % % % % % % % % % % % % % % % % % %

    function listCellType
        saveStateToHistory(ii);
        clusClas(ii) = UI.listbox.cellClassification.Value;
        MsgLog(['Cell ', num2str(ii), ' classified as ', UI.settings.cellTypes{clusClas(ii)}]);
        updateCellCount
        updatePlotClas
        
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function AddNewCellYype
        opts.Interpreter = 'tex';
        NewClass = inputdlg({'Name of new cell-type'},'Add cell type',[1 40],{''},opts);
        if ~isempty(NewClass) && ~any(strcmp(NewClass,UI.settings.cellTypes))
            colorpick = rand(1,3);
            try
                colorpick = uisetcolor(colorpick,'Select cell color');
            catch
                MsgLog('Failed to load color palet',3);
            end
            UI.settings.cellTypes = [UI.settings.cellTypes,NewClass];
            UI.settings.cellTypeColors = [UI.settings.cellTypeColors;colorpick];
            colored_string = DefineCellTypeList;
            UI.listbox.cellClassification.String = colored_string;
            
            if Colorval == 1 || ( Colorval > 1 && UI.checkbox.groups.Value == 1 )
                plotClasGroups = UI.settings.cellTypes;
            end
            
            updateCellCount;
            UI.listbox.cellTypes.Value = [UI.listbox.cellTypes.Value,size(UI.listbox.cellTypes.String,1)];
            updatePlotClas;
            classes2plot = UI.listbox.cellTypes.Value;
            MsgLog(['New cell type added: ' NewClass{1}]);
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function colored_string = DefineCellTypeList
        if size(UI.settings.cellTypeColors,1) < length(UI.settings.cellTypes)
            UI.settings.cellTypeColors = [UI.settings.cellTypeColors;rand(length(UI.settings.cellTypes)-size(UI.settings.cellTypeColors,1),3)];
        end
        classColorsHex = rgb2hex(UI.settings.cellTypeColors*0.7);
        classColorsHex = cellstr(classColorsHex(:,2:end));
        classNumbers = cellstr(num2str([1:length(UI.settings.cellTypes)]'))';
        colored_string = strcat('<html><font color="', classColorsHex' ,'">', classNumbers, '.&nbsp;' ,UI.settings.cellTypes, '</font></html>');
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonDeepSuperficial
        saveStateToHistory(ii)
        cell_metrics.deepSuperficial{ii} = UI.settings.deepSuperficial{UI.listbox.deepSuperficial.Value};
        cell_metrics.deepSuperficial_num(ii) = UI.listbox.deepSuperficial.Value;
        
        MsgLog(['Cell ', num2str(ii), ' classified as ', cell_metrics.deepSuperficial{ii}]);
        if strcmp(plotX_title,'deepSuperficial_num')
            plotX = cell_metrics.deepSuperficial_num;
        end
        if strcmp(plotY_title,'deepSuperficial_num')
            plotY = cell_metrics.deepSuperficial_num;
        end
        if strcmp(plotZ_title,'deepSuperficial_num')
            plotZ = cell_metrics.deepSuperficial_num;
        end
        updatePlotClas
        updateCount
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonLabel
        Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{cell_metrics.labels{ii}});
        if ~isempty(Label)
            cell_metrics.labels{ii} = Label{1};
            UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
            MsgLog(['Cell ', num2str(ii), ' labeled as ', Label{1}]);
            [~,ID] = findgroups(cell_metrics.labels);
            groups_ids.labels_num = ID;
            classificationTrackChanges = [classificationTrackChanges,ii];
            updatePlotClas
            updateCount
            buttonGroups(1);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonBrainRegion
        saveStateToHistory(ii)
        
        if isempty(brainRegions_list)
            brainRegions = load('brainRegions.mat'); brainRegions = brainRegions.BrainRegions;
            brainRegions_list = strcat(brainRegions(:,1),' (',brainRegions(:,2),')');
            brainRegions_acronym = brainRegions(:,2);
            clear brainRegions;
        end
        choice = brainRegionDlg(brainRegions_list,find(strcmp(cell_metrics.brainRegion{ii},brainRegions_acronym)));
        if strcmp(choice,'')
            tf = 0;
        else
            indx = find(strcmp(choice,brainRegions_list));
            tf = 1;
        end
        
        if tf == 1
            SelectedBrainRegion = brainRegions_acronym{indx};
            cell_metrics.brainRegion{ii} = SelectedBrainRegion;
            UI.pushbutton.brainRegion.String = ['Region: ', SelectedBrainRegion];
            [cell_metrics.brainRegion_num,ID] = findgroups(cell_metrics.brainRegion);
            groups_ids.brainRegion_num = ID;
            MsgLog(['Brain region: Cell ', num2str(ii), ' classified as ', SelectedBrainRegion]);
            uiresume(UI.fig);
        end
        if strcmp(plotX_title,'brainRegion_num')
            plotX = cell_metrics.brainRegion_num;
        end
        if strcmp(plotY_title,'brainRegion_num')
            plotY = cell_metrics.brainRegion_num;
        end
        if strcmp(plotZ_title,'brainRegion_num')
            plotZ = cell_metrics.brainRegion_num;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function choice = brainRegionDlg(brainRegions,InitBrainRegion)
        choice = '';
        brainRegions_dialog = dialog('Position', [300, 300, 600, 350],'Name','Brain region assignment'); movegui(brainRegions_dialog,'center')
        brainRegionsList = uicontrol('Parent',brainRegions_dialog,'Style', 'ListBox', 'String', brainRegions, 'Position', [10, 50, 580, 220],'Value',InitBrainRegion);
        brainRegionsTextfield = uicontrol('Parent',brainRegions_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 580, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','left');
        uicontrol('Parent',brainRegions_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','OK','Callback',@(src,evnt)CloseBrainRegions_dialog);
        uicontrol('Parent',brainRegions_dialog,'Style','pushbutton','Position',[300, 10, 290, 30],'String','Cancel','Callback',@(src,evnt)CancelBrainRegions_dialog);
        uicontrol('Parent',brainRegions_dialog,'Style', 'text', 'String', 'Search term', 'Position', [10, 325, 580, 20],'HorizontalAlignment','left');
        uicontrol('Parent',brainRegions_dialog,'Style', 'text', 'String', 'Selct brain region below', 'Position', [10, 270, 580, 20],'HorizontalAlignment','left');
        uicontrol(brainRegionsTextfield)
        uiwait(brainRegions_dialog);
        function UpdateBrainRegionsList
            temp = contains(brainRegions,brainRegionsTextfield.String,'IgnoreCase',true);
            if ~any(temp == brainRegionsList.Value)
                brainRegionsList.Value = 1;
            end
            if ~isempty(temp)
                brainRegionsList.String = brainRegions(temp);
            else
                brainRegionsList.String = {''};
            end
        end
        function  CloseBrainRegions_dialog
            if length(brainRegionsList.String)>=brainRegionsList.Value
                choice = brainRegionsList.String(brainRegionsList.Value);
            end
            delete(brainRegions_dialog);
        end
        function  CancelBrainRegions_dialog
            choice = '';
            delete(brainRegions_dialog);
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
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function advanceClass(ClasIn)
        if ~exist('ClasIn')
            ClasIn = plotClas(ii);
        end
        temp = find(ClasIn==plotClas(subset));
        temp2 = find(subset(temp) > ii,1);
        if ~isempty(temp2)
            ii = subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(subset(temp) < ii,1))
            ii = subset(temp(1));
        else
            MsgLog('No other cells with selected class');
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function backClass
        temp = find(plotClas(ii)==plotClas(subset));
        temp2 = max(find(subset(temp) < ii));
        if ~isempty(temp2)
            ii = subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(subset(temp) > ii,1))
            ii = subset(temp(end));
        else
            MsgLog('No other cells with selected class');
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function back
        if ~isempty(subset) && length(subset)>1
            if ii <= subset(1)
                ii = subset(end);
            else
                ii = subset(find(subset < ii,1,'last'));
            end
        elseif length(subset)==1
            ii = subset(1);
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonACG
        if UI.popupmenu.ACG.Value == 1
            UI.settings.acgType = 'Narrow';
            button_ACG.String = 'ACG: 30ms';
        elseif UI.popupmenu.ACG.Value == 2
            UI.settings.acgType = 'Normal';
            button_ACG.String = 'ACG: 100ms';
        elseif UI.popupmenu.ACG.Value == 3
            UI.settings.acgType = 'Wide';
            button_ACG.String = 'ACG: 1s';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonMonoSyn
        if UI.popupmenu.synMono.Value == 1
            monoSynDisp = 'None';
            button_SynMono.String = 'MonoSyn: None';
        elseif UI.popupmenu.synMono.Value == 2
            monoSynDisp = 'Selected';
            button_SynMono.String = 'MonoSyn: Selected';
        elseif UI.popupmenu.synMono.Value == 3
            monoSynDisp = 'All';
            button_SynMono.String = 'MonoSyn: All';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonExit
        exit = 1;
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ScrolltoZoomInPlot(h,event)
        h2 = overobj2('flat','visible','on');
        
        if ~isempty(h2) && strcmp(h2.Type,'uipanel') && strcmp(h2.Title,'') && ~isempty(h2.Children) && any(find(ismember(subfig_ax, h2.Children)) == [1:9])
            axnum = find(ismember(subfig_ax, h2.Children));
            um_axes = get(h2.Children(end),'CurrentPoint');
            u = um_axes(1,1);
            v = um_axes(1,2);
            axes(h2.Children(end));
            b = get(gca,'Xlim');
            c = get(gca,'Ylim');
            if isempty(globalZoom{axnum})
                globalZoom{axnum} = [b;c];
            end
            
            if event.VerticalScrollCount<0
                if u < b(1) || u > b(2)
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*0.7);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*0.7);
                    ylim([y1,y2]);
                elseif v < c(1) || v > c(2)
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*0.7);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*0.7);
                    xlim([x1,x2]);
                else
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*0.7);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*0.7);
                    xlim([x1,x2]);
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*0.7);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*0.7);
                    ylim([y1,y2]);
                end
            else
                if u < b(1) || u > b(2)
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*1.8);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*1.8);
                    if y1 == globalZoom{axnum}(2,1)
                        y2 = min([globalZoom{axnum}(2,2),y1 + diff(c)*2]);
                    end
                    if y2 == globalZoom{axnum}(2,2)
                        y1 = max([globalZoom{axnum}(2,1),y2 - diff(c)*2]);
                    end
                    ylim([y1,y2]);
                elseif v < c(1) || v > c(2)
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*1.8);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*1.8);
                    if x1 == globalZoom{axnum}(1,1)
                        x2 = min([globalZoom{axnum}(1,2),x1 + diff(b)*2]);
                    end
                    if x2 == globalZoom{axnum}(1,2)
                        x1 = max([globalZoom{axnum}(1,1),x2 - diff(b)*2]);
                    end
                    xlim([x1,x2]);
                else
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*1.8);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*1.8);
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*1.8);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*1.8);
                    if x1 == globalZoom{axnum}(1,1)
                        x2 = min([globalZoom{axnum}(1,2),x1 + diff(b)*2]);
                    end
                    if x2 == globalZoom{axnum}(1,2)
                        x1 = max([globalZoom{axnum}(1,1),x2 - diff(b)*2]);
                    end
                    if y1 == globalZoom{axnum}(2,1)
                        y2 = min([globalZoom{axnum}(2,2),y1 + diff(c)*2]);
                    end
                    if y2 == globalZoom{axnum}(2,2)
                        y1 = max([globalZoom{axnum}(2,1),y2 - diff(c)*2]);
                    end
                    xlim([x1,x2]);
                    ylim([y1,y2]);
                end
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ClicktoSelectFromPlot(h,~)
        switch get(UI.fig, 'selectiontype')
            case 'normal'
                if ~isempty(subset)
                    axnum = find(ismember(subfig_ax, gca));
                    um_axes = get(gca,'CurrentPoint');
                    u = um_axes(1,1);
                    v = um_axes(1,2);
                    SelectFromPlot(u,v);
                else
                    MsgLog(['No cells with selected classification']);
                end
            case 'alt'
                if ~isempty(subset)
                    axnum = find(ismember(subfig_ax, gca));
                    um_axes = get(gca,'CurrentPoint');
                    u = um_axes(1,1);
                    v = um_axes(1,2);
                    HighlightFromPlot(u,v);
                end
            case 'extend'
                if ~isempty(subset)
                    axnum = find(ismember(subfig_ax, gca));
                    um_axes = get(gca,'CurrentPoint');
                    u = um_axes(1,1);
                    v = um_axes(1,2);
                    ccgFromPlot(u,v);
                end
        end
    end


% % % % % % % % % % % % % % % % % % % % % %

    function ClicktoSelectFromTable(src, event)
        if ~isempty(event.Indices) & size(event.Indices,1) == 1
            if event.Indices(2) == 1
                UI.popupmenu.xData.Value = event.Indices(1);
                uicontrol(UI.popupmenu.xData);
                buttonPlotX;
            elseif event.Indices(2) == 2
                UI.popupmenu.yData.Value = event.Indices(1);
                uicontrol(UI.popupmenu.yData);
                buttonPlotY;
            end
        end
    end


% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectFromPlot
        if ~isempty(subset)
            MsgLog(['Select a cell by clicking a scatter point or line']);
            if UI.settings.plot3axis
                rotate3d(subfig_ax(1),'off')
            end
            [u,v] = ginput(1);
            SelectFromPlot(u,v);
        else
            MsgLog(['No cells with selected classification']);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function iii = FromPlot(u,v,highlight)
        iii = 0;
        if ~exist('highlight')
            highlight = 0;
        end
        axnum = find(ismember(subfig_ax, gca));
        
        if axnum == 1
            
            [~,idx] = min(hypot(plotX(subset)-u,plotY(subset)-v));
            iii = subset(idx);
            if highlight
                text(plotX(iii),plotY(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
            end
            
        elseif axnum == 2
            
            [~,idx] = min(hypot(cell_metrics.troughToPeak(subset)-u/1000,log10(cell_metrics.burstIndex_Royer2012(subset))-log10(v)));
            iii = subset(idx);
            
            if highlight
                text(cell_metrics.troughToPeak(iii)*1000,cell_metrics.burstIndex_Royer2012(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
            end
            
        elseif axnum == 3
            
            [~,idx] = min(hypot(tSNE_metrics.plot(subset,1)-u,tSNE_metrics.plot(subset,2)-v));
            iii = subset(idx);
            if highlight
                text(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
            end
            
        elseif any(axnum == [4,5,6,7,8,9])
            
            if axnum == 4
                selectedOption = customCellPlot1;
                subsetPlots = subsetPlots1;
            elseif axnum == 5
                selectedOption = customCellPlot2;
                subsetPlots = subsetPlots2;
            elseif axnum == 6
                selectedOption = customCellPlot3;
                subsetPlots = subsetPlots3;
            elseif axnum == 7
                selectedOption = customCellPlot4;
                subsetPlots = subsetPlots4;
            elseif axnum == 8
                selectedOption = customCellPlot5;
                subsetPlots = subsetPlots5;
            elseif axnum == 9
                selectedOption = customCellPlot6;
                subsetPlots = subsetPlots6;
            end
            
            switch selectedOption
                case 'tSNE of waveforms'
                    
                    [~,idx] = min(hypot(tSNE_metrics.filtWaveform(subset,1)-u,tSNE_metrics.filtWaveform(subset,2)-v));
                    iii = subset(idx);
                    if highlight
                        text(tSNE_metrics.filtWaveform(iii,1),tSNE_metrics.filtWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'All waveforms'
                    
                    x1 = time_waveforms_zscored'*ones(1,length(subset));
                    y1 = cell_metrics.filtWaveform_zscored(:,subset);
                    [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(time_waveforms_zscored)))+1;
                    iii = subset(In);
                    [~,time_index] = min(abs(time_waveforms_zscored-u));
                    if highlight
                        plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'tSNE of narrow ACGs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.acg2(subset,1)-u,tSNE_metrics.acg2(subset,2)-v));
                    iii = subset(idx);
                    if highlight
                        text(tSNE_metrics.acg2(iii,1),tSNE_metrics.acg2(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'tSNE of wide ACGs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.acg1(subset,1)-u,tSNE_metrics.acg1(subset,2)-v));
                    iii = subset(idx);
                    if highlight
                        text(tSNE_metrics.acg1(iii,1),tSNE_metrics.acg1(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'All ACGs'
                    
                    if strcmp(UI.settings.acgType,'Normal')
                        x2 = [-100:100]/2;
                        x1 = ([-100:100]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.acg2(:,subset);
                    elseif strcmp(UI.settings.acgType,'Narrow')
                        x2 = [-30:30]/2;
                        x1 = ([-30:30]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.acg2(41+30:end-40-30,subset);
                    else
                        x2 = [-500:500];
                        x1 = ([-500:500])'*ones(1,length(subset));
                        y1 = cell_metrics.acg(:,subset);
                    end
                    
                    [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = subset(In);
                    if highlight
                        [~,time_index] = min(abs(x2-u));
                        plot(x2(:),y1(:,In),'linewidth',2, 'HitTest','off')
                        text(x2(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                otherwise
                    if any(strcmp(monoSynDisp,{'Selected','All'})) & ~isempty(subsetPlots)
                        if ~isempty(outbound) || ~isempty(inbound)
                            subset1 = subsetPlots.subset;
                            x1 = subsetPlots.xaxis'*ones(1,length(subset1));
                            y1 = subsetPlots.yaxis;
                            
                            [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                            In = unique(floor(In/size(x1,1)))+1;
                            if In>0
                                iii = subset1(In);
                                if highlight
                                    [~,time_index] = min(abs(x1-u));
                                    plot(x1(:,1),y1(:,In),'linewidth',2, 'HitTest','off')
                                    text(x1(time_index,1),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                                end
                            end
                        end
                    end
            end
        end
    end


% % % % % % % % % % % % % % % % % % % % % %

    function SelectFromPlot(u,v)
        iii = FromPlot(u,v,0);
        if iii>0
            ii = iii;
            UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
            UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
            UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ccgFromPlot(u,v)
        iii = FromPlot(u,v,1);
        if iii > 0
            ClickedCells = [ClickedCells,iii];
        end
        if ~isempty(ClickedCells)
            GroupAction(ClickedCells)
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function HighlightFromPlot(u,v)
        iii = FromPlot(u,v,1);
        if iii > 0
            ClickedCells = [ClickedCells,iii];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupSelectFromPlot
        if ~isempty(subset)
            MsgLog(['Select cells by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.']);
            if UI.settings.plot3axis
                rotate3d(subfig_ax(1),'off')
            end
            ax = get(UI.fig,'CurrentAxes');
            polygon_coords = [];
            hold(ax, 'on');
            clear h2
            counter = 0;
            while true
                c = ginput(1);
                sel = get(UI.fig, 'SelectionType');
                
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
                    In = subset(In);
                    plot(plotX(In),plotY(In),'ok', 'HitTest','off')
                    
                elseif axnum == 2
                    
                    In = find(inpolygon(cell_metrics.troughToPeak(subset)*1000, log10(cell_metrics.burstIndex_Royer2012(subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                    In = subset(In);
                    plot(cell_metrics.troughToPeak(In)*1000,cell_metrics.burstIndex_Royer2012(In),'ok', 'HitTest','off')
                    
                elseif axnum == 3
                    
                    In = find(inpolygon(tSNE_metrics.plot(subset,1), tSNE_metrics.plot(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = subset(In);
                    plot(tSNE_metrics.plot(In,1),tSNE_metrics.plot(In,2),'ok', 'HitTest','off')
                    
                elseif any(axnum == [4,5,6,7,8,9])
                    
                    if axnum == 4
                        selectedOption = customCellPlot1;
                        subsetPlots = subsetPlots1;
                    elseif axnum == 5
                        selectedOption = customCellPlot2;
                        subsetPlots = subsetPlots2;
                    elseif axnum == 6
                        selectedOption = customCellPlot3;
                        subsetPlots = subsetPlots3;
                    elseif axnum == 7
                        selectedOption = customCellPlot4;
                        subsetPlots = subsetPlots4;
                    elseif axnum == 8
                        selectedOption = customCellPlot5;
                        subsetPlots = subsetPlots5;
                    elseif axnum == 9
                        selectedOption = customCellPlot6;
                        subsetPlots = subsetPlots6;
                    end
                    
                    switch selectedOption
                        
                        case 'All waveforms'
                            
                            x1 = time_waveforms_zscored'*ones(1,length(subset));
                            y1 = cell_metrics.filtWaveform_zscored(:,subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            In = subset(In);
                            plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                            
                        case 'tSNE of waveforms'
                            
                            In = find(inpolygon(tSNE_metrics.filtWaveform(subset,1), tSNE_metrics.filtWaveform(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        case 'All ACGs'
                            
                            if strcmp(UI.settings.acgType,'Normal')
                                x1 = ([-100:100]/2)'*ones(1,length(subset));
                                y1 = cell_metrics.acg2(:,subset);
                            elseif strcmp(UI.settings.acgType,'Narrow')
                                x1 = ([-30:30]/2)'*ones(1,length(subset));
                                y1 = cell_metrics.acg2(41+30:end-40-30,subset);
                            else
                                x1 = ([-500:500])'*ones(1,length(subset));
                                y1 = cell_metrics.acg(:,subset);
                            end
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            In = subset(In);
                            
                        case 'tSNE of narrow ACGs'
                            
                            In = find(inpolygon(tSNE_metrics.acg2(subset,1), tSNE_metrics.acg2(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        case 'tSNE of wide ACGs'
                            
                            In = find(inpolygon(tSNE_metrics.acg1(subset,1), tSNE_metrics.acg1(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        otherwise
                            if any(strcmp(monoSynDisp,{'Selected','All'}))
                                if ~isempty(outbound) || ~isempty(inbound) || ~isempty(subsetPlots)
                                    subset1 = subsetPlots.subset;
                                    x1 = subsetPlots.xaxis'*ones(1,length(subset1));
                                    y1 = subsetPlots.yaxis;
                                    
                                    In2 = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                    In2 = unique(floor(In2/length(subsetPlots.xaxis)))+1;
                                    In = subset1(In2);
                                    hold on, plot(x1(:,1),y1(:,In2),'linewidth',2, 'HitTest','off')
                                end
                            end
                    end
                end
                
                
                if length(In)>0 && any(axnum == [1,2,3,4,5,6,7,8,9])
                    GroupAction(In)
                else
                    MsgLog(['0 cells selected']);
                end
            else
                MsgLog(['0 cells selected']);
            end
        else
            MsgLog(['No cells with selected classification']);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function  buttonDispLegend
        UI.settings.dispLegend = UI.checkbox.legend.Value;
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotX
        Xval = UI.popupmenu.xData.Value;
        Xstr = UI.popupmenu.xData.String;
        plotX = cell_metrics.(Xstr{Xval});
        plotX_title = Xstr{Xval};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotY
        Yval = UI.popupmenu.yData.Value;
        Ystr = UI.popupmenu.yData.String;
        plotY = cell_metrics.(Ystr{Yval});
        plotY_title = Ystr{Yval};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotZ
        Zval = UI.popupmenu.zData.Value;
        Zstr = UI.popupmenu.zData.String;
        plotZ = cell_metrics.(Zstr{Zval});
        plotZ_title = Zstr{Zval};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updatePlotClas
        if Colorval == 1
            plotClas = clusClas;
        else
            if UI.checkbox.groups.Value == 0
                plotClas = cell_metrics.(colorStr{Colorval});
                if iscell(plotClas)
                    plotClas = findgroups(plotClas);
                end
            else
                plotClas = clusClas;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonGroups(inpt)
        Colorval = UI.popupmenu.groups.Value;
        colorStr = UI.popupmenu.groups.String;
        if Colorval == 1
            clasLegend = 0;
            UI.listbox.groups.Visible='Off';
            UI.checkbox.groups.Visible='Off';
            plotClas = clusClas;
            UI.checkbox.groups.Value = 0;
            plotClasGroups = UI.settings.cellTypes;
        else
            clasLegend = 1;
            UI.listbox.groups.Visible='On';
            UI.checkbox.groups.Visible='On';
            if UI.checkbox.groups.Value == 0
                plotClas = cell_metrics.(colorStr{Colorval});
                plotClasGroups = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas = findgroups(plotClas);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas] = ismember(plotClas,plotClasGroups);
                end
                color_class_count = histc(plotClas,[1:length(plotClasGroups)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                
                UI.listbox.groups.String = strcat(plotClasGroups,' (',color_class_count,')'); %  plotClasGroups;
                if length(UI.listbox.groups.String) < max(UI.listbox.groups.Value) | inpt ==1
                    UI.listbox.groups.Value = 1:length(plotClasGroups);
                    groups2plot = 1:length(plotClasGroups);
                    groups2plot2 = 1:length(plotClasGroups);
                end
            else
                plotClas = clusClas;
                plotClasGroups = UI.settings.cellTypes;
                plotClas2 = cell_metrics.(colorStr{Colorval});
                plotClasGroups2 = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas2) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas2 = findgroups(plotClas2);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas2] = ismember(plotClas2,plotClasGroups2);
                end
                
                color_class_count = histc(plotClas2,[1:length(plotClasGroups2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(plotClasGroups2,' (',color_class_count,')');
                if length(UI.listbox.groups.String) < max(UI.listbox.groups.Value) || inpt ==1
                    UI.listbox.groups.Value = 1:length(plotClasGroups2);
                    groups2plot = 1:length(plotClasGroups);
                    groups2plot2 = 1:length(plotClasGroups2);
                end
                
            end
            
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotXLog
        if UI.checkbox.logx.Value==1
            MsgLog('X-axis log. Negative data ignored');
        else
            MsgLog('X-axis linear');
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotYLog
        if UI.checkbox.logy.Value==1
            MsgLog('Y-axis log. Negative data ignored');
        else
            MsgLog('Y-axis linear');
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlotZLog
        if UI.checkbox.logz.Value==1
            UI.settings.plotZLog = 1;
            MsgLog('Z-axis log. Negative data ignored');
        else
            UI.settings.plotZLog = 0;
            MsgLog('Z-axis linear');
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPlot3axis
        if UI.checkbox.showz.Value==1
            UI.popupmenu.zData.Enable = 'On';
            UI.checkbox.logz.Enable = 'On';
            UI.settings.plot3axis = 1;
            axes(UI.panel.subfig_ax1.Children(end));
            view([40 20]);
            %             rotateFig1
        else
            UI.popupmenu.zData.Enable = 'Off';
            UI.checkbox.logz.Enable = 'Off';
            UI.settings.plot3axis = 0;
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectSubset
        classes2plot = UI.listbox.cellTypes.Value;
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSelectGroups
        groups2plot2 = UI.listbox.groups.Value;
        uiresume(UI.fig);
    end


% % % % % % % % % % % % % % % % % % % % % %

    function buttonShowMetrics
        if UI.checkbox.showtable.Value==1
            UI.table.Data = [fieldsMenu,num2cell(table_metrics(ii,:)')];
            UI.table.Visible = 'on';
        else
            UI.table.Visible = 'off';
        end
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc
        customCellPlot3 = customPlotOptions{UI.popupmenu.customplot3.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc2
        customCellPlot4 = customPlotOptions{UI.popupmenu.customplot4.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc3
        customCellPlot5 = customPlotOptions{UI.popupmenu.customplot5.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc4
        customCellPlot6 = customPlotOptions{UI.popupmenu.customplot6.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function togglePlotHistograms
        if UI.popupmenu.metricsPlot.Value == 1
            customPlotHistograms = 0;
            delete(h_scatter)
        elseif UI.popupmenu.metricsPlot.Value == 2
            customPlotHistograms = 1;
        elseif UI.popupmenu.metricsPlot.Value == 3
            customPlotHistograms = 2;
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function toggleWaveformsPlot
        customCellPlot1 = UI.popupmenu.customplot1.String{UI.popupmenu.customplot1.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleACGplot
        customCellPlot2 = UI.popupmenu.customplot2.String{UI.popupmenu.customplot2.Value};
        uiresume(UI.fig);
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleACGfit
        if plotAcgFit == 0
            plotAcgFit = 1;
            MsgLog('Plotting ACG fit');
        elseif plotAcgFit == 1
            plotAcgFit = 0;
            MsgLog('Hiding ACG fit');
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function goToCell
        if BatchMode
            choice = '';
            GoTo_dialog = dialog('Position', [300, 300, 300, 350],'Name','Go to cell'); movegui(GoTo_dialog,'center')
            
            sessionCount = histc(cell_metrics.batchIDs,[1:length(cell_metrics.general.basenames)]);
            sessionCount = cellstr(num2str(sessionCount'))';
            sessionEnumerator = cellstr(num2str([1:length(cell_metrics.general.basenames)]'))';
            sessionList = strcat(sessionEnumerator,{'.  '},cell_metrics.general.basenames,' (',sessionCount,')');
            
            brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', sessionList, 'Position', [10, 50, 280, 220],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog);
            brainRegionsTextfield = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 280, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','left');
            %             uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Go to session','Callback',@(src,evnt)CloseGoTo_dialog);
            uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the cell id to go to and press enter', 'Position', [10, 325, 280, 20],'HorizontalAlignment','left');
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Click the session to go to', 'Position', [10, 270, 280, 20],'HorizontalAlignment','left');
            uicontrol(brainRegionsTextfield)
            uiwait(GoTo_dialog);
        else
            choice = '';
            GoTo_dialog = dialog('Position', [300, 300, 300, 100],'Name','Go to cell'); movegui(GoTo_dialog,'center')
            brainRegionsTextfield = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 50, 280, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','center');
            uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the cell id to go to and press enter', 'Position', [10, 75, 280, 20],'HorizontalAlignment','center');
            uicontrol(brainRegionsTextfield)
            uiwait(GoTo_dialog);
            
        end
        
        function UpdateBrainRegionsList
            answer = str2num(brainRegionsTextfield.String);
            if ~isempty(answer) && answer > 0 && answer <= size(cell_metrics.troughToPeak,2)
                delete(GoTo_dialog);
                ii = answer;
                uiresume(UI.fig);
                MsgLog(['Cell ' num2str(ii) ' selected.']);
            end
        end
        
        function  CloseGoTo_dialog
            if ismember(brainRegionsList.Value,cell_metrics.batchIDs)
                ii = find(cell_metrics.batchIDs==brainRegionsList.Value,1);
                MsgLog(['Session ' cell_metrics.general.basenames{brainRegionsList.Value} ' selected.']);
                delete(GoTo_dialog);
                uiresume(UI.fig);
            end
        end
        
        function  CancelGoTo_dialog
            choice = '';
            delete(GoTo_dialog);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupAction(cellIDs)
        cellIDs = unique(cellIDs);
        choice = '';
        GoTo_dialog = dialog('Position', [0, 0, 300, 350],'Name','Select action'); movegui(GoTo_dialog,'center')
        
        actionList = strcat([{'Assign existing cell-type','Assign new cell-type','Assign label','Assign deep/superficial','Plot CCGs','Multiple plot actions'},customPlotOptions']);
        brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', actionList, 'Position', [10, 50, 280, 270],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', ['Select the action to perform on the ', num2str(length(cellIDs)) ,' selected cells'], 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(brainRegionsList)
        uiwait(GoTo_dialog);
        
        function  CloseGoTo_dialog(cellIDs)
            choice = brainRegionsList.Value;
            MsgLog(['Action selected: ' actionList{choice} ' for ' num2str(length(cellIDs)) ' cells']);
            delete(GoTo_dialog);
            if choice == 1
                [selectedClas,tf] = listdlg('PromptString',['Assign cell-type to ' num2str(length(cellIDs)) ' cells'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
                if ~isempty(selectedClas)
                    saveStateToHistory(cellIDs)
                    
                    clusClas(cellIDs) = selectedClas;
                    updateCellCount
                    MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.settings.cellTypes{selectedClas}, ' from t-SNE visualization']);
                    updatePlotClas
                    uiresume(UI.fig);
                end
            elseif choice == 2
                AddNewCellYype
                selectedClas = length(colored_string);
                if ~isempty(selectedClas)
                    saveStateToHistory(cellIDs)
                    clusClas(cellIDs) = selectedClas;
                    updateCellCount
                    MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.settings.cellTypes{selectedClas}, ' from t-SNE visualization']);
                    updatePlotClas
                    uiresume(UI.fig);
                end
                
                
            elseif choice == 3
                Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{''});
                if ~isempty(Label)
                    cell_metrics.labels(cellIDs) = repmat(Label(1),length(cellIDs),1);
                    [~,ID] = findgroups(cell_metrics.labels);
                    groups_ids.labels_num = ID;
                    classificationTrackChanges = [classificationTrackChanges,ii];
                    updatePlotClas
                    updateCount
                    buttonGroups(1);
                    uiresume(UI.fig);
                end
                
            elseif choice == 4
                
                [selectedClas,tf] = listdlg('PromptString',['Assign Deep-Superficial to ' num2str(length(cellIDs)) ' cells'],'ListString',UI.listbox.deepSuperficial.String,'SelectionMode','single','ListSize',[200,150]);
                if ~isempty(selectedClas)
                    saveStateToHistory(cellIDs)
                    cell_metrics.deepSuperficial(cellIDs) =  repmat(UI.listbox.deepSuperficial.String(selectedClas),1,length(cellIDs));
                    cell_metrics.deepSuperficial_num(cellIDs) = selectedClas;
                    
                    if strcmp(plotX_title,'deepSuperficial_num')
                        plotX = cell_metrics.deepSuperficial_num;
                    end
                    if strcmp(plotY_title,'deepSuperficial_num')
                        plotY = cell_metrics.deepSuperficial_num;
                    end
                    if strcmp(plotZ_title,'deepSuperficial_num')
                        plotZ = cell_metrics.deepSuperficial_num;
                    end
                    updatePlotClas
                    updateCount
                    uiresume(UI.fig);
                end
                
            elseif choice == 5
                
                ClickedCells = cellIDs(:)';
                if isfield(general,'ccg') && ~isempty(ClickedCells)
                    %                     ClickedCells = unique(ClickedCells);
                    if BatchMode
                        ClickedCells_inBatch = find(cell_metrics.batchIDs(ii) == cell_metrics.batchIDs(ClickedCells));
                        if length(ClickedCells_inBatch) < length(ClickedCells)
                            MsgLog([ num2str(length(ClickedCells)-length(ClickedCells_inBatch)), ' cell(s) from a different batch are not displayed in the CCG window.'],0);
                        end
                        plot_cells = [ii,ClickedCells(ClickedCells_inBatch)];
                    else
                        plot_cells = [ii,ClickedCells];
                    end
                    plot_cells = unique(plot_cells,'stable');
                    figure('Name',['Cell Explorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off')
                    
                    %                     plot_cells = [ii,ClickedCells];
                    plot_cells2 = cell_metrics.UID(plot_cells);
                    k = 1;
                    for j = 1:length(plot_cells)
                        for jj = 1:length(plot_cells)
                            subplot(length(plot_cells),length(plot_cells),k)
                            if jj == j
                                col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                                bar(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),1,'FaceColor',col1,'EdgeColor',col1),
                                title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j)))]),
                                grid on, ylabel(cell_metrics.putativeCellType{plot_cells(j)})
                            else
                                bar(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),1,'FaceColor',[0.5,0.5,0.5],'EdgeColor',[0.5,0.5,0.5]),
                                grid on
                            end
                            if j == length(plot_cells); xlabel('Time (ms)'); end
                            if jj == 1 && j > 1; ylabel('Rate (Hz)'); end
                            xticks([-50:10:50]),xlim([-50,50])
                            if length(plot_cells) > 2 & j < length(plot_cells)
                                set(gca,'XTickLabel',[]);
                            end
                            ax = gca; ax.TickLength = [0.03, 0.02];
                            k = k+1;
                        end
                    end
                else
                    MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                end
                
            elseif choice == 6
                [selectedActions,tf] = listdlg('PromptString',['Plot actions to perform on ' num2str(length(cellIDs)) ' cells'],'ListString',customPlotOptions','SelectionMode','Multiple','ListSize',[200,250]);
                if ~isempty(selectedActions)
                    plot_columns = min([length(cellIDs),5]);
                    for j = 1:length(cellIDs)
                        if BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                        end
                        if ~isempty(putativeSubset)
                            a1 = cell_metrics.putativeConnections(putativeSubset,1);
                            a2 = cell_metrics.putativeConnections(putativeSubset,2);
                            inbound = find(a2 == cellIDs(j));
                            outbound = find(a1 == cellIDs(j));
                        end
                        for jj = 1:length(selectedActions)
                            subplot_advanced(plot_columns,length(selectedActions),j,jj,mod(j ,5),['Cell Explorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells']), hold on
                            customPlot(customPlotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1); 
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                            end
                        end
                        
                    end
                end
                
            elseif choice > 6
                figure('Name',['Cell Explorer: ',actionList{choice},' for selected cells: ', num2str(cellIDs)],'NumberTitle','off')
                for j = 1:length(cellIDs)
                    if BatchMode
                        batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                        general1 = cell_metrics.general.batch{batchIDs1};
                    else
                        general1 = cell_metrics.general;
                        batchIDs1 = 1;
                    end
                    if ~isempty(putativeSubset)
                        a1 = cell_metrics.putativeConnections(putativeSubset,1);
                        a2 = cell_metrics.putativeConnections(putativeSubset,2);
                        inbound = find(a2 == cellIDs(j));
                        outbound = find(a1 == cellIDs(j));
                    end
                    subplot(min(2,length(cellIDs)),ceil(length(cellIDs)/2),j), hold on
                    customPlot(actionList{choice},cellIDs(j),general1,batchIDs1); title(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                end
                
            else
                uiresume(UI.fig);
            end
            
        end
        
        function  CancelGoTo_dialog
            choice = '';
            delete(GoTo_dialog);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function LoadPreferences
        answer = questdlg('Settings are stored in CellExplorer_Settings.m. Click Yes to load settings.', 'Settings', 'Yes','Cancel','Yes');
        switch answer
            case 'Yes'
                MsgLog(['Opening settings file']);
                edit CellExplorer_Preferences.m
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function reclassify_celltypes
        answer = questdlg('Are yo sure you want to reclassify all your cells?', 'Reclassification', 'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                saveStateToHistory(1:size(cell_metrics.troughToPeak,2))
                
                % cell_classification_putativeCellType
                cell_metrics.putativeCellType = repmat({'Pyramidal Cell'},1,size(cell_metrics.cellID,2));
                
                % Interneuron classification
                cell_metrics.putativeCellType(cell_metrics.acg_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_decay>30),1);
                cell_metrics.putativeCellType(cell_metrics.acg_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_rise>3),1);
                cell_metrics.putativeCellType(cell_metrics.troughToPeak<=0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.troughToPeak<=0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
                cell_metrics.putativeCellType(cell_metrics.troughToPeak>0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.troughToPeak>0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
                
                % Pyramidal cell classification
                cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative<0.17 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 2'},sum(cell_metrics.troughtoPeakDerivative<0.17 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
                cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative>0.3 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 3'},sum(cell_metrics.troughtoPeakDerivative>0.3 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
                cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative>=0.17 & cell_metrics.troughtoPeakDerivative<=0.3 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 1'},sum(cell_metrics.troughtoPeakDerivative>=0.17 & cell_metrics.troughtoPeakDerivative<=0.3 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
                
                % clusClas initialization
                clusClas = ones(1,length(cell_metrics.putativeCellType));
                for i = 1:length(UI.settings.cellTypes)
                    clusClas(strcmp(cell_metrics.putativeCellType,UI.settings.cellTypes{i}))=i;
                end
                updateCellCount
                updatePlotClas
                uiresume(UI.fig);
                MsgLog(['Succesfully reclassified cells'],2);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function undoClassification
        if size(history_classification,2) > 1
            clusClas(history_classification(end).cellIDs) = history_classification(end).cellTypes;
            cell_metrics.deepSuperficial(history_classification(end).cellIDs) = cellstr(history_classification(end).deepSuperficial);
            cell_metrics.brainRegion(history_classification(end).cellIDs) = cellstr(history_classification(end).brainRegion);
            cell_metrics.deepSuperficial_num(history_classification(end).cellIDs) = history_classification(end).deepSuperficial_num;
            classificationTrackChanges = [classificationTrackChanges,history_classification(end).cellIDs];
            
            if length(history_classification(end).cellIDs) == 1
                MsgLog(['Reversed classification for cell ', num2str(history_classification(end).cellIDs)]);
                ii = history_classification(end).cellIDs;
            else
                MsgLog(['Reversed classification for ' num2str(length(history_classification(end).cellIDs)), ' cells']);
            end
            history_classification(end) = [];
            updateCellCount
            updatePlotClas
            updateCount
            
            % Button Deep-Superficial
            UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
            
            % Button brain region
            UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
            
            [cell_metrics.brainRegion_num,ID] = findgroups(cell_metrics.brainRegion);
            groups_ids.brainRegion_num = ID;
            
        else
            MsgLog(['No further history track available']);
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateCellCount
        cell_class_count = histc(clusClas,[1:length(UI.settings.cellTypes)]);
        cell_class_count = cellstr(num2str(cell_class_count'))';
        UI.listbox.cellTypes.String = strcat(UI.settings.cellTypes,' (',cell_class_count,')');
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateCount
        if Colorval > 1
            if UI.checkbox.groups.Value == 0
                plotClas = cell_metrics.(colorStr{Colorval});
                plotClasGroups = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas = findgroups(plotClas);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas] = ismember(plotClas,plotClasGroups);
                end
                color_class_count = histc(plotClas,[1:length(plotClasGroups)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(plotClasGroups,' (',color_class_count,')'); %  plotClasGroups;
                %                 groups2plot = 1:length(plotClasGroups);
                %                 groups2plot2 = 1:length(plotClasGroups);
            else
                plotClas = clusClas;
                plotClasGroups = UI.settings.cellTypes;
                plotClas2 = cell_metrics.(colorStr{Colorval});
                plotClasGroups2 = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas2) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas2 = findgroups(plotClas2);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas2] = ismember(plotClas2,plotClasGroups2);
                end
                color_class_count = histc(plotClas2,[1:length(plotClasGroups2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(plotClasGroups2,' (',color_class_count,')');
                %                 groups2plot = 1:length(plotClasGroups);
                %                 groups2plot2 = 1:length(plotClasGroups2);
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonSave
        answer = questdlg('How would you like to save the classification?', 'Save classification','Update existing metrics','Create new file', 'Cancel','Cancel');
        % Handle response
        switch answer
            case 'Update existing metrics'
                try
                    saveMetrics(cell_metrics);
                catch
                    exception
                    disp(exception.identifier)
                    MsgLog(['Failed to save file - see Command Window for details'],[3,4]);
                end
            case 'Create new file'
                if length(unique(cell_metrics.spikeSortingID)) > 1
                    [file,SavePath] = uiputfile('cell_metrics_batch.mat','Save metrics');
                else
                    [file,SavePath] = uiputfile('cell_metrics.mat','Save metrics');
                end
                if SavePath ~= 0
                    try
                        saveMetrics(cell_metrics,fullfile(SavePath,file));
                    catch
                        exception
                        disp(exception.identifier)
                        MsgLog(['Failed to save file - see Command Window for details'],[3,4]);
                    end
                end
            case 'Cancel'
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function saveMetrics(cell_metrics,file)
        MsgLog(['Saving metrics']);
        drawnow
        numeric_fields = fieldnames(cell_metrics);
        cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
        [C, ~, ic] = unique(clusClas,'sorted');
        for i = 1:length(C)
            cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.settings.cellTypes{C(i)}},sum(ic==i),1);
        end
        cell_metrics.general.SWR_batch = SWR_batch;
        cell_metrics.general.tSNE_metrics = tSNE_metrics;
        
        if nargin > 1
            save(file,'cell_metrics');
            MsgLog(['Classification saved to ', file],[1,2]);
        elseif length(unique(cell_metrics.spikeSortingID)) > 1
            MsgLog('Saving cell metrics from batch',1);
            sessionWithChanges = unique(cell_metrics.batchIDs(classificationTrackChanges));
            cellsWithChanges = length(unique(classificationTrackChanges));
            countSessionWithChanges = length(sessionWithChanges);
            answer = questdlg([num2str(cellsWithChanges), ' cell(s) from ', num2str(countSessionWithChanges),' session(s) altered. Which sessions to you want to update?'], 'Save classification','Update altered sessions','Update all sessions', 'Update altered sessions');
            switch answer
                case 'Update all sessions'
                    sessionWithChanges = 1:length(cell_metrics.general.basenames);
                case 'Update altered sessions'
                    sessionWithChanges = unique(cell_metrics.batchIDs(classificationTrackChanges));
                otherwise
                    return
            end
            cell_metricsTemp = cell_metrics; clear cell_metrics
            f_waitbar = waitbar(0,'Saving cell metrics from batch (',num2str(sessionWithChanges),' sessions with changes)','WindowStyle','modal');
            
            for j = 1:length(sessionWithChanges)
                if ~ishandle(f_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                waitbar(j/length(sessionWithChanges),f_waitbar,['Saving cell metrics from batch. Session ' num2str(j),'/',num2str(length(sessionWithChanges))])
                cellSubset = find(cell_metricsTemp.batchIDs==sessionID);
                matpath = fullfile(cell_metricsTemp.general.paths{sessionID},'cell_metrics.mat');
                matFileCell_metrics = matfile(matpath,'Writable',true);
                cell_metrics = matFileCell_metrics.cell_metrics;
                if length(cellSubset) == size(cell_metrics.putativeCellType,2)
                    cell_metrics.labels = cell_metricsTemp.labels(cellSubset);
                    cell_metrics.deepSuperficial = cell_metricsTemp.deepSuperficial(cellSubset);
                    cell_metrics.brainRegion = cell_metricsTemp.brainRegion(cellSubset);
                    cell_metrics.putativeCellType = cell_metricsTemp.putativeCellType(cellSubset);
                    matFileCell_metrics.cell_metrics = cell_metrics;
                end
            end
            if ishandle(f_waitbar)
                close(f_waitbar)
                classificationTrackChanges = [];
                MsgLog(['Classifications succesfully saved to existing cell_metrics files'],[1,2]);
            else
                MsgLog('Metrics was not succesfully saved for all session in batch',4);
            end
        else
            file = fullfile(clusteringpath,'cell_metrics.mat');
            save(file,'cell_metrics');
            classificationTrackChanges = [];
            MsgLog(['Classification saved to ', file],[1,2]);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function SignificanceMetricsMatrix
        if UI.popupmenu.groups.Value~=1 && (length(classes2plot)==2 && UI.checkbox.groups.Value == 1) || (length(groups2plot2)==2 && UI.checkbox.groups.Value == 0)
            % Cell metrics differences
            cell_metrics_effects = [];
            cell_metrics_effects2 = [];
            temp = fieldnames(cell_metrics);
            temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
            subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter'})));
            if UI.checkbox.groups.Value == 0
                testset = plotClasGroups(UI.listbox.groups.Value);
                temp1 = intersect(find(strcmp(cell_metrics.(UI.popupmenu.groups.String{UI.popupmenu.groups.Value}),testset{1})),subset);
                temp2 = intersect(find(strcmp(cell_metrics.(UI.popupmenu.groups.String{UI.popupmenu.groups.Value}),testset{2})),subset);
            else
                testset = plotClasGroups(UI.listbox.cellTypes.Value);
                temp1 = intersect(find(strcmp(cell_metrics.putativeCellType,testset{1})),subset);
                temp2 = intersect(find(strcmp(cell_metrics.putativeCellType,testset{2})),subset);
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
            MsgLog(['KS-test: please select a group of size two']);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function rotateFig1
        axes(UI.panel.subfig_ax1.Children);
        rotate3d(subfig_ax(1),'on');
        h = rotate3d(subfig_ax(1));
        h.Enable = 'on';
        
        setAllowAxesRotate(h,subfig_ax(2),false);
        %         set(fig,'ButtonDownFCN','disp(''clicked'')');
        set(h,'ButtonDownFilter',@myRotateFilter);
        
        try
            % this works in R2014b, and maybe beyond:
            [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
        catch
            set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
        end
        set(UI.fig, 'WindowKeyPressFcn', []);
        set(UI.fig, 'KeyPressFcn', {@keyPress});
        set(UI.fig, 'windowscrollWheelFcn',{@ScrolltoZoomInPlot})
    end

    function [disallowRotation] = myRotateFilter(obj,eventdata)
        disallowRotation = false;
        % if a ButtonDownFcn has been defined for the object, then use that
        if isfield(get(obj),'ButtonDownFcn')
            disallowRotation = ~isempty(get(obj,'ButtonDownFcn'));
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function initializeSession
        ii = 1;
        ii_history = 1;
        
        if ~isfield(cell_metrics, 'labels')
            cell_metrics.labels = repmat({''},1,size(cell_metrics.cellID,2));
        end
        
        % Instantiates batch metrics
        if isfield(cell_metrics.general,'batch')
            BatchMode = true;
        end
        
        % Fieldnames
        metrics_fieldsNames = fieldnames(cell_metrics);
        
        % Cell type initialization
        UI.settings.cellTypes = unique([UI.settings.cellTypes,cell_metrics.putativeCellType],'stable');
        clusClas = ones(1,length(cell_metrics.putativeCellType));
        for i = 1:length(UI.settings.cellTypes)
            clusClas(strcmp(cell_metrics.putativeCellType,UI.settings.cellTypes{i}))=i;
        end
        colored_string = DefineCellTypeList;
        plotClasGroups = UI.settings.cellTypes;
        
        % SRW Profile initialization
        if isempty(SWR_in)
            if isfield(cell_metrics.general,'SWR_batch') && ~isempty(cell_metrics.general.SWR_batch)
                disp('Loading existing SWR profiles from cell_metrics structure')
                SWR_batch = cell_metrics.general.SWR_batch;
            elseif ~BatchMode
                if isfield(cell_metrics.general,'SWR')
                    SWR_batch = cell_metrics.general.SWR;
                else
                    SWR_batch = [];
                end
            else
                disp(['Loading Sharp wave ripple profiles'])
                SWR_batch = [];
                for i = 1:length(cell_metrics.general.basepaths)
                    if isfield(cell_metrics.general.batch{i},'SWR')
                        SWR_batch{i} = cell_metrics.general.batch{i}.SWR;
                    else
                        SWR_batch{i} = [];
                    end
                end
            end
        else
            SWR_batch = SWR_in;
        end
        
        % Plotting menues initialization
        fieldsMenu = sort(metrics_fieldsNames);
        groups_ids = [];
        fieldsMenu(find(contains(fieldsMenu,{'thetaPhaseResponse','rippleCorrelogram','firingRateMap','FiringRateMap','firing_rate_map','spatialCoherence','firingRateAcrossTime','FiringRateAcrossTime','filtWaveform','timeWaveform','psth'})))=[];
        
        for i = 1:length(fieldsMenu)
            if strcmp(fieldsMenu{i},'deepSuperficial')
                cell_metrics.deepSuperficial_num = ones(1,length(cell_metrics.deepSuperficial));
                for j = 1:length(UI.settings.deepSuperficial)
                    cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.settings.deepSuperficial{j}))=j;
                end
                groups_ids.deepSuperficial_num = UI.settings.deepSuperficial;
            elseif iscell(cell_metrics.(fieldsMenu{i})) && size(cell_metrics.(fieldsMenu{i}),1) == 1 && size(cell_metrics.(fieldsMenu{i}),2) == size(cell_metrics.cellID,2)
                [cell_metrics.([fieldsMenu{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenu{i}));
                groups_ids.([fieldsMenu{i},'_num']) = ID;
            end
        end
        
        fieldsMenu = sort(fieldnames(cell_metrics));
        fields_to_keep = [];
        for i = 1:length(fieldsMenu)
            if isnumeric(cell_metrics.(fieldsMenu{i})) && size(cell_metrics.(fieldsMenu{i}),1) == 1 && size(cell_metrics.(fieldsMenu{i}),2) == size(cell_metrics.cellID,2)
                fields_to_keep(i) = 1;
            else
                fields_to_keep(i) = 0;
            end
        end
        
        fieldsMenu = fieldsMenu(find(fields_to_keep));
        fieldsMenu(find(contains(fieldsMenu,'general')))=[];
        
        % Metric table initialization
        table_metrics = [];
        for i = 1:size(fieldsMenu,1)
            table_metrics(:,i) = cell_metrics.(fieldsMenu{i});
        end
        
        % tSNE initialization
        filtWaveform = [];
        step_size = [cellfun(@diff,cell_metrics.timeWaveform,'UniformOutput',false)];
        time_waveforms_zscored = [min([cell_metrics.timeWaveform{:}]):min([step_size{:}]):max([cell_metrics.timeWaveform{:}])];
        for i = 1:length(cell_metrics.filtWaveform)
            filtWaveform(:,i) = interp1(cell_metrics.timeWaveform{i},cell_metrics.filtWaveform{i},time_waveforms_zscored,'spline');
        end
        
        cell_metrics.filtWaveform_zscored = zscore(filtWaveform);
        cell_metrics.acg_zscored = zscore(cell_metrics.acg); cell_metrics.acg_zscored = cell_metrics.acg_zscored - min(cell_metrics.acg_zscored(490:510,:));
        cell_metrics.acg2_zscored = zscore(cell_metrics.acg2); cell_metrics.acg2_zscored = cell_metrics.acg2_zscored - min(cell_metrics.acg2_zscored(90:110,:));
        
        % filtWaveform, acg2, acg1, plot
        if isfield(cell_metrics.general,'tSNE_metrics')
            disp('Loading existing tSNE spaces from cell_metrics structure')
            tSNE_metrics = cell_metrics.general.tSNE_metrics;
            tSNE_fieldnames = fieldnames(cell_metrics.general.tSNE_metrics);
            for i = 1:length(tSNE_fieldnames)
                if ~isempty(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i})) && size(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i}),1) == length(cell_metrics.cellID)
                    tSNE_metrics.(tSNE_fieldnames{i}) = cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i});
                end
            end
        else
            tSNE_metrics = [];
        end
        
        if UI.settings.tSNE_calcWideAcg && ~isfield(tSNE_metrics,'acg1')
            disp('Calculating tSNE space for wide ACGs')
            tSNE_metrics.acg1 = tsne([cell_metrics.acg_zscored(ceil(size(cell_metrics.acg_zscored,1)/2):end,:)]');
        end
        if UI.settings.tSNE_calcNarrowAcg && ~isfield(tSNE_metrics,'acg2')
            disp('Calculating tSNE space for narrow ACGs')
            tSNE_metrics.acg2 = tsne([cell_metrics.acg2_zscored(ceil(size(cell_metrics.acg2_zscored,1)/2):end,:)]');
        end
        if UI.settings.tSNE_calcFiltWaveform && ~isfield(tSNE_metrics,'filtWaveform')
            disp('Calculating tSNE space for waveforms')
            tSNE_metrics.filtWaveform = tsne(cell_metrics.filtWaveform_zscored','Standardize',true);
        end
        if ~isfield(tSNE_metrics,'plot')
            disp('Calculating tSNE space for combined metrics')
            UI.settings.tSNE_metrics = intersect(UI.settings.tSNE_metrics,fieldnames(cell_metrics));
            X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.settings.tSNE_metrics,'UniformOutput',false));
            X(isnan(X) | isinf(X)) = 0;
            tSNE_metrics.plot = tsne((X'),'Standardize',true);
        end
        
        % Setting initial settings for plots, popups and listboxes
        disp('Initializing and applying preferences')
        UI.popupmenu.xData.String = fieldsMenu;
        UI.popupmenu.yData.String = fieldsMenu;
        UI.popupmenu.zData.String = fieldsMenu;
        plotX = cell_metrics.(UI.settings.plotXdata);
        plotY  = cell_metrics.(UI.settings.plotYdata);
        plotZ  = cell_metrics.(UI.settings.plotZdata);
        
        UI.popupmenu.xData.Value = find(strcmp(fieldsMenu,UI.settings.plotXdata));
        UI.popupmenu.yData.Value = find(strcmp(fieldsMenu,UI.settings.plotYdata));
        UI.popupmenu.zData.Value = find(strcmp(fieldsMenu,UI.settings.plotZdata));
        plotX_title = UI.settings.plotXdata;
        plotY_title = UI.settings.plotYdata;
        plotZ_title = UI.settings.plotZdata;
        
        UI.listbox.cellTypes.Value = 1:length(UI.settings.cellTypes);
        classes2plot = 1:length(UI.settings.cellTypes);
        
        if isfield(cell_metrics,'putativeConnections')
            monoSynDisp = UI.settings.monoSynDispIn;
            button_SynMono.Visible = 'On';
            button_SynMono.String = ['MonoSyn:' UI.settings.monoSynDispIn];
        else
            monoSynDisp = 'None';
            button_SynMono.Visible = 'off';
        end
        
        % History function initialization
        if isfield(cell_metrics.general,'classificationTrackChanges')
            classificationTrackChanges = cell_metrics.general.classificationTrackChanges;
        else
            classificationTrackChanges = [];
        end
        history_classification = [];
        history_classification(1).cellIDs = 1:size(cell_metrics.troughToPeak,2);
        history_classification(1).cellTypes = clusClas;
        history_classification(1).deepSuperficial = cell_metrics.deepSuperficial;
        history_classification(1).brainRegion = cell_metrics.brainRegion;
        history_classification(1).brainRegion_num = cell_metrics.brainRegion_num;
        history_classification(1).deepSuperficial_num = cell_metrics.deepSuperficial_num;
        
        % Cell count for menu
        updateCellCount
        
        % Button Deep-Superficial
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        
        % Button brain region
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        
        % Button label
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        
        customPlotOptions = fieldnames(cell_metrics);
        temp =  struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        temp1 = cell2mat(struct2cell(structfun(@(X) size(X,1), cell_metrics,'UniformOutput',false)));
        temp2 = cell2mat(struct2cell(structfun(@(X) size(X,2), cell_metrics,'UniformOutput',false)));
        
        fields2keep = [];
        customPlotOptions2 = customPlotOptions(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        
        for i = 1:length(customPlotOptions2)
            if any(cell2mat(cellfun(@isnumeric,cell_metrics.(customPlotOptions2{i}),'UniformOutput',false)))
                fields2keep = [fields2keep,i];
                % && ~contains(colorMenu{i},{'putativeCellType','firingRateMap','firingRateAcrossTime','FiringRateMap','FiringRateAcrossTime','psth'} )
            end
        end
        customPlotOptions2 = sort(customPlotOptions2(fields2keep));
        
        waveformOptions = {'Single waveform';'All waveforms'};
        if isfield(tSNE_metrics,'filtWaveform')
            waveformOptions = [waveformOptions;'tSNE of waveforms'];
        end
        acgOptions = {'Single ACG';'All ACGs'};
        if isfield(tSNE_metrics,'acg2')
            acgOptions = [acgOptions;'tSNE of narrow ACGs'];
        end
        if isfield(tSNE_metrics,'acg1')
            acgOptions = [acgOptions;'tSNE of wide ACGs'];
        end
        otherOptions = {};
        if ~isempty(SWR_batch)
            otherOptions = [otherOptions;'Sharp wave-ripple'];
        end
        
        customPlotOptions = customPlotOptions(  find( (strcmp(temp,'double') & temp1>1 & temp2==size(cell_metrics.spikeCount,2) ) )  );
        customPlotOptions = [customPlotOptions;customPlotOptions2];
        customPlotOptions(find(contains(customPlotOptions,{'putativeConnections','acg','acg2','filtWaveform','timeWaveform'})))=[];
        customPlotOptions = unique([waveformOptions; acgOptions; otherOptions; customPlotOptions],'stable');
        
        %         if any(contains(metrics_fieldsNames,'firingRateAcrossTime'))
        %             customPlotOptions = {customPlotOptions{:},metrics_fieldsNames{find(contains(metrics_fieldsNames,'firingRateAcrossTime'))}};
        %         end
        %
        %         % Firing rate maps
        %         if any(contains(metrics_fieldsNames,'firingRateMap'))
        %             customPlotOptions = {customPlotOptions{:},metrics_fieldsNames{find(contains(metrics_fieldsNames,'firingRateMap'))}};
        %         end
        %
        %         % PSTHs
        %         if any(contains(metrics_fieldsNames,'psth'))
        %             customPlotOptions = {customPlotOptions{:},metrics_fieldsNames{find(contains(metrics_fieldsNames,'psth'))}};
        %         end
        
        % Initilizing view #1
        UI.popupmenu.customplot1.String = customPlotOptions;
        if any(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); UI.popupmenu.customplot1.Value = find(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); else; UI.popupmenu.customplot1.Value = 1; end
        customCellPlot1 = customPlotOptions{UI.popupmenu.customplot1.Value};
        
        % Initilizing view #2
        UI.popupmenu.customplot2.String = customPlotOptions;
        if find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); UI.popupmenu.customplot2.Value = find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); else; UI.popupmenu.customplot2.Value = 4; end
        customCellPlot2 = customPlotOptions{UI.popupmenu.customplot2.Value};
        
        % Initilizing view #3
        UI.popupmenu.customplot3.String = customPlotOptions;
        if find(strcmp(UI.settings.customCellPlotIn3,customPlotOptions)); UI.popupmenu.customplot3.Value = find(strcmp(UI.settings.customCellPlotIn3,customPlotOptions)); else; UI.popupmenu.customplot3.Value = 7; end
        customCellPlot3 = customPlotOptions{UI.popupmenu.customplot3.Value};
        
        % Initilizing view #4
        UI.popupmenu.customplot4.String = customPlotOptions;
        if find(strcmp(UI.settings.customCellPlotIn4,customPlotOptions)); UI.popupmenu.customplot4.Value = find(strcmp(UI.settings.customCellPlotIn4,customPlotOptions)); else; UI.popupmenu.customplot4.Value = 7; end
        customCellPlot4 = customPlotOptions{UI.popupmenu.customplot4.Value};
        
        % Initilizing view #5
        UI.popupmenu.customplot5.String = customPlotOptions;
        if find(strcmp(UI.settings.customCellPlotIn5,customPlotOptions)); UI.popupmenu.customplot5.Value = find(strcmp(UI.settings.customCellPlotIn5,customPlotOptions)); else; UI.popupmenu.customplot5.Value = 7; end
        customCellPlot5 = customPlotOptions{UI.popupmenu.customplot5.Value};
        
        % Initilizing view #6
        UI.popupmenu.customplot6.String = customPlotOptions;
        if find(strcmp(UI.settings.customCellPlotIn6,customPlotOptions)); UI.popupmenu.customplot6.Value = find(strcmp(UI.settings.customCellPlotIn6,customPlotOptions)); else; UI.popupmenu.customplot6.Value = 7; end
        customCellPlot6 = customPlotOptions{UI.popupmenu.customplot6.Value};
        
        % Custom colorgroups
        colorMenu = metrics_fieldsNames;
        colorMenu = colorMenu(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fields2keep = [];
        for i = 1:length(colorMenu)
            if ~any(cell2mat(cellfun(@isnumeric,cell_metrics.(colorMenu{i}),'UniformOutput',false))) && ~contains(colorMenu{i},{'putativeCellType','firingRateMap','firingRateAcrossTime','FiringRateMap','FiringRateAcrossTime','psth'} )
                fields2keep = [fields2keep,i];
            end
        end
        colorMenu = ['cell-type';sort(colorMenu(fields2keep))];
        UI.popupmenu.groups.String = colorMenu;
        
        plotClas = clusClas;
        UI.popupmenu.groups.Value = 1;
        clasLegend = 0;
        UI.listbox.groups.Visible='Off';
        customCellPlot2 = UI.settings.customCellPlotIn2;
        UI.checkbox.groups.Value = 0;
        
        if isfield(cell_metrics,'synapticEffect')
            cellsExcitatory = find(strcmp(cell_metrics.synapticEffect,'Excitatory'));
            cellsInhibitory = find(strcmp(cell_metrics.synapticEffect,'Inhibitory'));
        end
        
        spikes = []; 
    end


% % % % % % % % % % % % % % % % % % % % % %

    function LoadDatabaseSession
        if exist('db_credentials') == 2
            bz_database = db_credentials;
            if ~strcmp(bz_database.rest_api.username,'user')
                disp(['Loading datasets from database']);
                drawnow
                options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
                options.CertificateFilename=('');
                bz_db = webread([bz_database.rest_api.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
                sessions = loadjson(bz_db.renderedHtml);
                [db_menu_items,index] = sort(cellfun(@(x) x.name,sessions,'UniformOutput',false));
                db_menu_ids = cellfun(@(x) x.id,sessions,'UniformOutput',false);
                db_menu_animals = cellfun(@(x) x.animal,sessions,'UniformOutput',false);
                db_menu_investigator = cellfun(@(x) x.investigator,sessions,'UniformOutput',false);
                db_menu_values = cellfun(@(x) x.id,sessions,'UniformOutput',false);
                db_menu_values = db_menu_values(index);
                db_menu_items2 = strcat(db_menu_items);
                sessionEnumerator = cellstr(num2str([1:length(db_menu_items2)]'))';
                sessionList = strcat(sessionEnumerator,{'.  '},db_menu_items2,{' ('},db_menu_animals(index),')');
                drawnow
                [indx,tf] = listdlg('PromptString',['Select dataset to load'],'ListString',sessionList,'SelectionMode','multiple','ListSize',[400,350]);
                if ~isempty(indx)
                    if length(indx)==1
                        try
                            drawnow
                            [session, basename, basepath, clusteringpath] = db_set_path('id',str2double(db_menu_ids(indx)),'saveMat',false);
                            SWR_in = {};
                            successMessage = LoadSession;
                            MsgLog(successMessage,2);
                        catch
                            MsgLog(['Failed to load dataset from database: ', db_menu_items{indx}],3);
                        end
                    else
%                         try
                            drawnow
                            cell_metrics = LoadCellMetricBatch('sessionIDs', str2double(db_menu_ids(indx)));
                            SWR_in = {};
                            
                            disp(['Initializing session(s)']);
                            initializeSession
                            disp('Session(s) loaded succesfully');
                        try
                        catch
                            disp(['Failed to load dataset from database: ',strjoin(db_menu_items(indx))]);
                        end
                        drawnow
                    end
                end
                
                if ishandle(UI.fig)
                    uiresume(UI.fig);
                end
            else
                MsgLog(['Please provide your database credentials in ''db\_credentials.m'' '],2);
                edit db_credentials
                
            end
        else
            MsgLog('Database tools not installed');
            msgbox({'Database tools not installed. To install, follow the steps below: ','1. Go to the Cell Explorer Github webpage','2. Download the database tools', '3. Add the db directory to your Matlab path', '4. Provide your credentials in db\_credentials.m and try again.'},createStruct);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function successMessage = LoadSession
        successMessage = '';
        if exist(basepath)
            if exist(fullfile(clusteringpath,'cell_metrics.mat'))
                cd(basepath);
                load(fullfile(clusteringpath,'cell_metrics.mat'));
                
                initializeSession;
                
                successMessage = [basename ' with ' num2str(size(cell_metrics.troughToPeak,2))  ' cells loaded from database'];
                MsgLog(successMessage);
            else
                successMessage = ['Error: ', basename, ' has no missing cell metrics'];
                MsgLog(successMessage,3);
            end
        else
            successMessage = ['Error: ',basename ' path not available'];
            MsgLog(successMessage,3);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function AdjustGUIbutton
        switch UI.popupmenu.plotCount.Value
            case 6
                UI.settings.layout = 1;
            case 5
                UI.settings.layout = 6;
            case 4
                UI.settings.layout = 5;
            case 3
                UI.settings.layout = 4;
            case 2
                UI.settings.layout = 3;
            case 1
                UI.settings.layout = 2;
        end
        AdjustGUI
    end


% % % % % % % % % % % % % % % % % % % % % %

    function out = CheckSpikes(batchIDs)
        if isempty(spikes) || length(spikes) < batchIDs || isempty(spikes{batchIDs})
            if BatchMode
                clusteringpath1 = cell_metrics.general.paths{batchIDs};
            else
                clusteringpath1 = clusteringpath;
            end

            if exist(fullfile(clusteringpath1,[general.basename,'.spikes.cellinfo.mat']),'file')
                spikesfilesize=dir(fullfile(clusteringpath1,[general.basename,'.spikes.cellinfo.mat']));
                waitbar_spikes = waitbar(0,['Loading spikes from ', general.basename , ' (', num2str(ceil(spikesfilesize.bytes/1000000)), 'MB)'],'Name','Loading spikes','WindowStyle','modal');
                temp = load(fullfile(clusteringpath1,[general.basename,'.spikes.cellinfo.mat']));
                spikes{batchIDs} = temp.spikes;
                out = true;
                if ishandle(waitbar_spikes)
                    waitbar(1,waitbar_spikes,'Complete');
                    close(waitbar_spikes)
                end
                MsgLog(['Spikes loaded succesfully for ' general.basename]);
            else
                out = false;
            end
        else
            out = true;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function defineSpikesPlots
        out = CheckSpikes(batchIDs);
        if out
            spikePlotListDlg;
        else
            MsgLog('No spike data found in the data folder',2)
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function spikePlotListDlg
        spikePlotList_dialog = dialog('Position', [300, 300, 670, 400],'Name','Spike plot types','WindowStyle','modal'); movegui(spikePlotList_dialog,'center')
        
        tableData = updateTableData(spikesPlots);
        spikePlot = uitable(spikePlotList_dialog,'Data',tableData,'Position',[10, 50, 650, 340],'ColumnWidth',{20 125 90 90 90 90 70 70},'columnname',{'','Plot name','X data','Y data','X label','Y label','State','Event'},'RowName',[],'ColumnEditable',[true false false false false false false false]);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[10, 10, 120, 30],'String','Add plot','Callback',@(src,evnt)addPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[140, 10, 120, 30],'String','Edit plot','Callback',@(src,evnt)editPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[270, 10, 120, 30],'String','Delete plot','Callback',@(src,evnt)DeletePlot);
        OK_button = uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[410, 10, 120, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlotList_dialog);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[540, 10, 120, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikePlotList_dialog);
        
        uicontrol(OK_button)
        uiwait(spikePlotList_dialog);
        
        function tableData = updateTableData(spikesPlots)
            tableData = {};
            spikesPlotFieldnames = fieldnames(spikesPlots);
            for fn = 1:length(spikesPlotFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = spikesPlotFieldnames{fn}(8:end);
                tableData{fn,3} = spikesPlots.(spikesPlotFieldnames{fn}).x;
                tableData{fn,4} = spikesPlots.(spikesPlotFieldnames{fn}).y;
                tableData{fn,5} = spikesPlots.(spikesPlotFieldnames{fn}).x_label;
                tableData{fn,6} = spikesPlots.(spikesPlotFieldnames{fn}).y_label;
                tableData{fn,7} = spikesPlots.(spikesPlotFieldnames{fn}).state;
                tableData{fn,8} = spikesPlots.(spikesPlotFieldnames{fn}).event;
            end
        end
        
        function  CloseSpikePlotList_dialog
            customPlotOptions(contains(customPlotOptions,'spikes_')) = [];
            customPlotOptions = [customPlotOptions;fieldnames(spikesPlots)];
            customPlotOptions = unique(customPlotOptions,'stable');
            UI.popupmenu.customplot1.String = customPlotOptions; if UI.popupmenu.customplot1.Value>length(customPlotOptions), UI.popupmenu.customplot1.Value=1; end
            UI.popupmenu.customplot2.String = customPlotOptions; if UI.popupmenu.customplot2.Value>length(customPlotOptions), UI.popupmenu.customplot2.Value=1; end
            UI.popupmenu.customplot3.String = customPlotOptions; if UI.popupmenu.customplot3.Value>length(customPlotOptions), UI.popupmenu.customplot3.Value=1; end
            UI.popupmenu.customplot4.String = customPlotOptions; if UI.popupmenu.customplot4.Value>length(customPlotOptions), UI.popupmenu.customplot4.Value=1; end
            UI.popupmenu.customplot5.String = customPlotOptions; if UI.popupmenu.customplot5.Value>length(customPlotOptions), UI.popupmenu.customplot5.Value=1; end
            UI.popupmenu.customplot6.String = customPlotOptions; if UI.popupmenu.customplot6.Value>length(customPlotOptions), UI.popupmenu.customplot6.Value=1; end
            MsgLog('Spike plots defined')
            delete(spikePlotList_dialog);
        end
        
        function  CancelSpikePlotList_dialog
            delete(spikePlotList_dialog);
        end
        
        function DeletePlot
            if ~isempty(find([spikePlot.Data{:,1}]))
                spikesPlotFieldnames = fieldnames(spikesPlots);
                spikesPlots = rmfield(spikesPlots,{spikesPlotFieldnames{find([spikePlot.Data{:,1}])}});
                tableData = updateTableData(spikesPlots);
                spikePlot.Data = tableData;
            end
        end
        
        function addPlotToTable
            spikesPlotsOut = spikePlotsDlg([]);
            if ~isempty(spikesPlotsOut) 
                for fn = fieldnames(spikesPlotsOut)'
                    spikesPlots.(fn{1}) = spikesPlotsOut.(fn{1});
                end
                tableData = updateTableData(spikesPlots);
                spikePlot.Data = tableData;
            end
        end
        
        function editPlotToTable
            if ~isempty(find([spikePlot.Data{:,1}])) && sum([spikePlot.Data{:,1}]) == 1
                spikesPlotFieldnames = fieldnames(spikesPlots);
%                 fieldtoedit = convertStringsToChars(tableData{find([spikePlot.Data{:,1}]),2});
%                 fieldtoedit = ['spikes_',fieldtoedit];
                fieldtoedit = spikesPlotFieldnames{find([spikePlot.Data{:,1}])};
                spikesPlotsOut = spikePlotsDlg(fieldtoedit);
                if ~isempty(spikesPlotsOut)
                    for fn = fieldnames(spikesPlotsOut)'
                        spikesPlots.(fn{1}) = spikesPlotsOut.(fn{1});
                    end
                    tableData = updateTableData(spikesPlots);
                    spikePlot.Data = tableData;
                end
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

function spikesPlotsOut = spikePlotsDlg(fieldtoedit)
    
        spikesPlotsOut = '';
        spikePlots_dialog = dialog('Position', [300, 300, 600, 400],'Name','Add new plot type','WindowStyle','modal'); movegui(spikePlots_dialog,'center')
        
        spikesField = cellfun(@fieldnames,{spikes{find(~cellfun(@isempty,spikes))}},'UniformOutput',false);
        spikesField = spikesField{:};
        temp1 = struct2cell(structfun(@class,spikes{batchIDs},'UniformOutput',false));
        spikesField = sort(spikesField(find(strcmp(temp1,'cell'))));
        
        if BatchMode
            basepath1 = cell_metrics.general.basepaths{batchIDs};
        else
            basepath1 = basepath;
        end
        eventField = dir(fullfile(basepath1,[general.basename, '.*.events.mat']));
        eventField = {eventField.name};
        eventField = ['Select event file below';eventField];
        
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Plot name', 'Position', [10, 375, 580, 20],'HorizontalAlignment','left');
        spikePlotName = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 350, 580, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'X data', 'Position', [10, 325, 280, 20],'HorizontalAlignment','left');
        spikePlotXData = uicontrol('Parent',spikePlots_dialog,'Style', 'ListBox', 'String', spikesField, 'Position', [10, 130, 280, 195],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'X label', 'Position', [10, 105, 280, 20],'HorizontalAlignment','left');
        spikePlotXLabel = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 80, 280, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Y data', 'Position', [310, 325, 280, 20],'HorizontalAlignment','left');
        spikePlotYData = uicontrol('Parent',spikePlots_dialog,'Style', 'ListBox', 'String', spikesField, 'Position', [310, 130, 280, 195],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Y label', 'Position', [310, 105, 280, 20],'HorizontalAlignment','left');
        spikePlotYLabel = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [310, 80, 280, 25],'HorizontalAlignment','left');
        
        spikePlotState = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', ['Select state field below';spikesField], 'Position', [10, 60, 280, 10],'HorizontalAlignment','left');
        spikePlotEvent = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', eventField, 'Position', [310, 60, 280, 10],'HorizontalAlignment','left');
        
        uicontrol('Parent',spikePlots_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlots_dialog);
        uicontrol('Parent',spikePlots_dialog,'Style','pushbutton','Position',[300, 10, 290, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikePlots_dialog);
        
        if ~isempty(fieldtoedit)
            spikePlotName.String = fieldtoedit(8:end);
            spikePlotXLabel.String = spikesPlots.(fieldtoedit).x_label;
            spikePlotYLabel.String = spikesPlots.(fieldtoedit).y_label;
            
            if find(strcmp(spikesPlots.(fieldtoedit).x,spikePlotXData.String))
                spikePlotXData.Value = find(strcmp(spikesPlots.(fieldtoedit).x,spikePlotXData.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).y,spikePlotYData.String))
                spikePlotYData.Value = find(strcmp(spikesPlots.(fieldtoedit).y,spikePlotYData.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).state,spikePlotState.String))
                spikePlotState.Value = find(strcmp(spikesPlots.(fieldtoedit).state,spikePlotState.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).event,spikePlotEvent.String))
                spikePlotEvent.Value = find(strcmp(spikesPlots.(fieldtoedit).event,spikePlotEvent.String));
            end
        end
        
        uicontrol(spikePlotName);
        uiwait(spikePlots_dialog);

        function CloseSpikePlots_dialog
            if ~isempty(spikePlotName.String)
                spikePlotName2 = ['spikes_',spikePlotName.String];
                spikesPlotsOut.(spikePlotName2).x = spikesField{spikePlotXData.Value};
                spikesPlotsOut.(spikePlotName2).y = spikesField{spikePlotYData.Value};
                spikesPlotsOut.(spikePlotName2).x_label = spikePlotXLabel.String;
                spikesPlotsOut.(spikePlotName2).y_label = spikePlotYLabel.String;
                if spikePlotState.Value > 1
                    spikesPlotsOut.(spikePlotName2).state = spikesField{spikePlotState.Value-1};
                else
                    spikesPlotsOut.(spikePlotName2).state = '';
                end
                if spikePlotEvent > 1
                    spikesPlotsOut.(spikePlotName2).event = eventField{spikePlotEvent.Value-1};
                else
                    spikesPlotsOut.(spikePlotName2).event = '';
                end
                delete(spikePlots_dialog);
            else
                uicontrol(spikePlotName);
                message = sprintf('Warning: Plot name must be filled out!');
                uiwait(warndlg(message));
            end
        end
        
    function  CancelSpikePlots_dialog
            spikesPlotsOut = '';
            delete(spikePlots_dialog);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function MsgLog(message,priority)
        % priority:
        % 1: Show message in Command Window
        % 2: Show msg dialog
        % 3: Show warning in Command Window
        % 4: Show warning dialog
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        message2 = sprintf('[%s] %s', timestamp, message);
        UI.popupmenu.log.String = {UI.popupmenu.log.String{:},message2};
        UI.popupmenu.log.Value = length(UI.popupmenu.log.String);
        % priority==1
        if exist('priority')
            if any(priority == 1) 
                disp(message)
            end
            if any(priority == 2) 
                msgbox(message,createStruct);
            end
            if any(priority == 3) 
                warning(message)
            end
            if any(priority == 4) 
                warndlg(message)
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function AdjustGUI
        % UI plot panels
        if UI.settings.layout == 1
            % GUI: 3+6 figures
            UI.popupmenu.customplot4.Enable = 'on';
            UI.popupmenu.customplot5.Enable = 'on';
            UI.popupmenu.customplot6.Enable = 'on';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'on';
            UI.panel.subfig_ax1.Position = [0.09 0.5 0.28 0.5];
            UI.panel.subfig_ax2.Position = [0.09+0.28 0.5 0.28 0.5];
            UI.panel.subfig_ax3.Position = [0.09+0.54 0.5 0.28 0.5];
            UI.panel.subfig_ax4.Position = [0.09 0.25 0.28 0.25];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.25 0.28 0.25];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.25 0.28 0.251];
            UI.panel.subfig_ax7.Position = [0.09 0.03 0.28 0.25-0.03];
            UI.panel.subfig_ax8.Position = [0.09+0.28 0.03 0.28 0.250-0.03];
            UI.panel.subfig_ax9.Position = [0.09+0.54 0.03 0.28 0.250-0.03];
            UI.popupmenu.plotCount.Value = 6;
            UI.settings.layout = 6;
        elseif UI.settings.layout == 6
            % GUI: 3+5 figures
            UI.panel.UI.popupmenu.customplot4.Enable = 'on';
            UI.panel.UI.popupmenu.customplot5.Enable = 'on';
            UI.panel.UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.09 0.5 0.28 0.5];
            UI.panel.subfig_ax2.Position = [0.09+0.28 0.5 0.28 0.5];
            UI.panel.subfig_ax3.Position = [0.09+0.54 0.5 0.28 0.5];
            UI.panel.subfig_ax4.Position = [0.09 0.03 0.28 0.5-0.03];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.25 0.28 0.25];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.25 0.28 0.251];
            UI.panel.subfig_ax7.Position = [0.09+0.28 0.03 0.28 0.250-0.03];
            UI.panel.subfig_ax8.Position = [0.09+0.54 0.03 0.28 0.250-0.03];
            UI.popupmenu.plotCount.Value = 5;
            UI.settings.layout = 5;
        elseif UI.settings.layout == 5
            % GUI: 3+4 figures
            UI.popupmenu.customplot4.Enable = 'on';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.09 0.5 0.28 0.5];
            UI.panel.subfig_ax2.Position = [0.09+0.28 0.5 0.28 0.5];
            UI.panel.subfig_ax3.Position = [0.09+0.54 0.5 0.28 0.5];
            UI.panel.subfig_ax4.Position = [0.09 0.03 0.28 0.5-0.03];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.03 0.28 0.5-0.03];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.25 0.28 0.251];
            UI.panel.subfig_ax7.Position = [0.09+0.54 0.0 0.28 0.250];
            UI.popupmenu.plotCount.Value = 4;
            UI.settings.layout = 4;
        elseif UI.settings.layout == 4
            % GUI: 3+3 figures
            UI.popupmenu.customplot4.Enable = 'off';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.09 0.5 0.28 0.5];
            UI.panel.subfig_ax2.Position = [0.09+0.28 0.5 0.28 0.5];
            UI.panel.subfig_ax3.Position = [0.09+0.54 0.5 0.28 0.5];
            UI.panel.subfig_ax4.Position = [0.09 0.03 0.28 0.5-0.03];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.03 0.28 0.5-0.03];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.0 0.28 0.501];
            UI.popupmenu.plotCount.Value = 3;
            UI.settings.layout = 3;
        elseif UI.settings.layout == 3
            % GUI: 2+3 figures
            UI.popupmenu.customplot4.Enable = 'off';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.09 0.4 0.42 0.6];
            UI.panel.subfig_ax3.Position = [0.09+0.40 0.4 0.42 0.6];
            UI.panel.subfig_ax4.Position = [0.09 0.03 0.28 0.4-0.03];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.03 0.28 0.4-0.03];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.0 0.28 0.401];
            UI.popupmenu.plotCount.Value = 2;
            UI.settings.layout = 2;
        elseif UI.settings.layout == 2
            % GUI: 1+3 figures
            UI.popupmenu.customplot4.Enable = 'off';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'off';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.10 0.024 0.53 0.945];
            UI.panel.subfig_ax4.Position = [0.09+0.54 0.66 0.28 0.33];
            UI.panel.subfig_ax5.Position = [0.09+0.54 0.33 0.28 0.33];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.0 0.28 0.33];
            UI.popupmenu.plotCount.Value = 1;
            UI.settings.layout = 1;
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function keyPress(src, event)
        switch event.Key
            case 'b'
                buttonBrainRegion;
            case 'c'
                UI.listbox.deepSuperficial.Value = find(strcmp(UI.settings.deepSuperficial,'Cortical'));
                buttonDeepSuperficial;
            case 'd'
                UI.listbox.deepSuperficial.Value = find(strcmp(UI.settings.deepSuperficial,'Deep'));
                buttonDeepSuperficial;
            case 'e'
                UI.settings.displayExcitatory = ~UI.settings.displayExcitatory;
                MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(cellsExcitatory))])
                uiresume(UI.fig);
            case 'f'
                toggleACGfit;
            case 'g'
                goToCell;
            case 'h'
                HelpDialog;
            case 'i'
                UI.settings.displayInhibitory = ~UI.settings.displayInhibitory;
                MsgLog(['Toggle highlighting inhibitory cells (circles), Count: ', num2str(length(cellsInhibitory))])
                uiresume(UI.fig);
            case 'k'
                SignificanceMetricsMatrix;
            case 'l'
                buttonLabel;
            case 'm'
                if UI.settings.displayMenu == 0
                    set(UI.fig, 'MenuBar', 'figure')
                    UI.settings.displayMenu = 1;
                else
                    set(UI.fig, 'MenuBar', 'None')
                    UI.settings.displayMenu = 0;
                end
            case 'n'
                AdjustGUI;
            case 'o'
                if BatchMode
                    if exist(cell_metrics.general.paths{cell_metrics.batchIDs(ii)})==7
                        cd(cell_metrics.general.paths{cell_metrics.batchIDs(ii)});
                        if ispc
                            winopen(cell_metrics.general.paths{cell_metrics.batchIDs(ii)});
                        elseif ismac
                            syscmd = ['open ', cell_metrics.general.paths{cell_metrics.batchIDs(ii)}, ' &'];
                            system(syscmd);
                        else
                            filebrowser;
                        end
                    else
                        MsgLog(['File path not available'],2)
                    end
                else
                    if ispc
                        winopen(pwd);
                    else
                        filebrowser;
                    end
                end
            case 'p'
                LoadPreferences;
            case 'r'
                reclassify_celltypes;
            case 's'
                defineSpikesPlots;
            case 't'
                tSNE_redefineMetrics;
            case 'u'
                UI.listbox.deepSuperficial.Value = find(strcmp(UI.settings.deepSuperficial,'Unknown'));
                buttonDeepSuperficial;
            case 'v'
                web('https://github.com/petersenpeter/Cell-Explorer/wiki','-new','-browser')
            case 'x'
                buttonSelectFromPlot;
            case 'z'
                undoClassification;
            case 'space'
                if isempty(ClickedCells)
                    answer = inputdlg({'Cells to process. E.g. 1:32 or 7,8,9,10'},'Select cells',[1 40],{''});
                    if ~isempty(answer)
                        try
                            ClickedCells = eval(['[',answer{1},']']);
                            ClickedCells = ClickedCells(ismember(ClickedCells,1:size(cell_metrics.troughToPeak,2)));
                        catch
                            MsgLog(['List of cell not formatted correctly'],2)
                        end
                    end
                end
                if ~isempty(ClickedCells)
                    GroupAction(ClickedCells)
                end
            case 'backspace'
                ii_history_reverse;
            case {'hyphen','add'}
                AddNewCellYype;
            case 'pagedown'
                if BatchMode
                    if ii ~= 1 && cell_metrics.batchIDs(ii) == cell_metrics.batchIDs(ii-1)
                        temp = find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii),1);
                    else
                        temp = find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii)-1,1);
                    end
                    if ~isempty(temp)
                        ii =  subset(temp);
                        uiresume(UI.fig);
                    end
                end
            case 'pageup'
                if BatchMode
                    temp = find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii)+1,1);
                    if ~isempty(temp)
                        ii =  subset(temp);
                        uiresume(UI.fig);
                    end
                end
            case 'rightarrow'
                advance;
            case 'leftarrow'
                back;
            case 'period'
                advanceClass
            case 'comma'
                backClass
            case {'1','2','3','4','5','6','7','8','9'}
                buttonCellType(str2num(event.Key));
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                advanceClass(str2num(event.Key(end)))
            case 'numpad0'
                ii = 1;
                uiresume(UI.fig);
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
msgbox({'\bfNavigation\rm','<    : Next cell', '>    : Previous cell','.     : Next cell with same class',',     : Previous cell with same class','G   : Go to a specific cell','X    : Select cell from plot','Page Up      : Next session in batch (only in batch mode)','Page Down  : Previous session in batch (only in batch mode)','Numpad0     : First cell', 'Numpad1-9 : Next cell with that numeric class','Backspace   : Previously selected cell','   ','\bfCell assigments\rm','1-9 : Cell-types','D   : Deep','C   : Cortical','U   : Unknown','B    : Brain region','L    : Label','+    : Add Cell-type','Z    : Undo assignment', 'R    : Reclassify cell types','   ','\bfDisplay shortcuts\rm','M    : Show/Hide menubar','N    : Change layout [6, 5 or 4 subplots]','E     : Highlight excitatory cells (triangles)','I      : Highlight inhibitory cells (circles)','F     : Display ACG fit', 'K    : Calculate and display significance matrix for all metrics (KS-test)','T     : Calculate tSNE space from a selection of metrics','Space  : Show action dialog for selected cells','     ','\bfOther shortcuts\rm', 'P    : Open preferences for the Cell Explorer','O    : Open the file directory of the selected cell','S    : Load spike data','V    : Visit the Github wiki in your browser','','\bfVisit the Cell Explorer''s wiki for further help\rm',''},'Keyboard shortcuts','help',opts);
end

% % % % % % % % % % % % % % % % % % % % % %

function subplot_advanced(x,y,z,w,new,titleIn)
if isempty('new')
    new = 1;
end
if y == 1
    if mod(z,x) == 1 & new
        figure('Name',titleIn,'pos',[100 100 900 800])
    end
    subplot(x,y,mod(z-1,x)+1)
else
    if mod(z,x) == 1 & w == 1
        figure('Name',titleIn,'pos',[100 100 900 800])
    end
    subplot(x,y,y*mod(z-1,x)+w)
end
end

% % % % % % % % % % % % % % % % % % % % % %

function h = overobj2(varargin)
%OVEROBJ2 Get handle of object that the pointer is over.
%   H = OVEROBJ2 searches all objects in the PointerWindow
%   looking for one that is under the pointer. Returns first
%   object handle it finds under the pointer, or empty matrix.
%
%   H = OVEROBJ2(FINDOBJ_PROPS) searches all objects which are
%   descendants of the figure beneath the pointer and that are
%   returned by FINDOBJ with the specified arguments.
%
%   Example:
%       h = overobj2('type','axes');
%       h = overobj2('flat','visible','on');
%
%   See also OVEROBJ, FINDOBJ

% By Yair Altman
% https://undocumentedmatlab.com/blog/undocumented-mouse-pointer-functions

% Ensure root units are pixels
oldUnits = get(0,'units');
set(0,'units','pixels');
 
% Get the figure beneath the mouse pointer & mouse pointer pos
try
   fig = get(0,'PointerWindow');  % HG1: R2014a or older
catch
   fig = matlab.ui.internal.getPointerWindow;  % HG2: R2014b or newer
end
p = get(0,'PointerLocation');
set(0,'units',oldUnits);
 
% Look for quick exit (if mouse pointer is not over any figure)
if fig==0,  h=[]; return;  end
 
% Compute figure offset of mouse pointer in pixels
figPos = getpixelposition(fig);
x = (p(1)-figPos(1));
y = (p(2)-figPos(2));
 
% Loop over all figure descendants
c = findobj(get(fig,'Children'),varargin{:});
for h = c'
   % If descendant contains the mouse pointer position, exit
   r = getpixelposition(h);  % Note: cache this for improved performance
   if (x>r(1)) && (x<r(1)+r(3)) && (y>r(2)) && (y<r(2)+r(4))
      return
   end
end
h = [];
end
