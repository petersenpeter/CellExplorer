function cell_metrics = CellExplorer(varargin)
% CellExplorer is a Matlab GUI and standardized pipeline for exploring and
% classifying spike sorted single units acquired using extracellular electrodes.
%
% Check out the website for extensive documentation and tutorials: https://petersenpeter.github.io/CellExplorer/
%
% Below follows a detailed description of how to call CellExplorer
%
% INPUTS
% varargin (Variable-length input argument list)
%
% - Single session struct with cell_metrics from one or more sessions
% metrics                - cell_metrics struct
%
% - Single session inputs
% basepath               - Path to session (base directory)
% clusteringpath         - Path to cluster data
% basename               - basename (database session name)
% id                     - Database numeric id
% session                - Session struct
%
% - Batch session inputs (when loading multiple session)
% basepaths              - Paths to sessions (base directory)
% clusteringpaths        - Paths to cluster data
% sessionIDs             - Database numeric id
% sessions               - basenames (database session names)
%
% - Example calls:
% cell_metrics = CellExplorer                             % Load from current path, assumed to be a basepath
% cell_metrics = CellExplorer('basepath',basepath)        % Load from basepath
% cell_metrics = CellExplorer('metrics',cell_metrics)     % Load from cell_metrics
% cell_metrics = CellExplorer('session',session)          % Load session from session struct
% cell_metrics = CellExplorer('sessionName','rec1')       % Load session from database session name
% cell_metrics = CellExplorer('sessionID',10985)          % Load session from database session id
% cell_metrics = CellExplorer('sessions',{'rec1','rec2'})          % Load batch from database
% cell_metrics = CellExplorer('clusteringpaths',{'path1','path1'}) % Load batch from a list with paths
% cell_metrics = CellExplorer('basepaths',{'path1','[path1'})      % Load batch from a list with paths
%
% - Summary figure calls:
% CellExplorer('summaryFigures',true)                       % creates summary figures from current path
% CellExplorer('summaryFigures',true,'plotCellIDs',[1,4,5]) % creates summary figures for select cells [1,4,5]
%
% OUTPUT
% cell_metrics: struct

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 22-03-2020

% Shortcuts to built-in functions:
% Data handling: initializeSession, saveDialog, restoreBackup, importGroundTruth, DatabaseSessionDialog, defineReferenceData, initializeReferenceData, defineGroupData
% UI: updateUI, customPlot, plotGroupData, GroupAction, defineSpikesPlots, keyPress, FromPlot, GroupSelectFromPlot, ScrolltoZoomInPlot, brainRegionDlg, tSNE_redefineMetrics plotSummaryFigures

p = inputParser;

addParameter(p,'metrics',[],@isstruct);         % cell_metrics struct
addParameter(p,'basepath',pwd,@isstr);          % Path to session (base directory)
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'session',[],@isstruct);
addParameter(p,'basename','',@isstr);
addParameter(p,'sessionID',[],@isnumeric);
addParameter(p,'sessionName',[],@isstr);

% Batch input
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'clusteringpaths',{},@iscell);

% Extra inputs
addParameter(p,'SWR',{},@iscell);
addParameter(p,'summaryFigures',false,@islogical); % Creates summary figures
addParameter(p,'plotCellIDs',[],@isnumeric); % Defines which cell ids to plot in the summary figures

% Parsing inputs
parse(p,varargin{:})
metrics = p.Results.metrics;
id = p.Results.sessionID;
sessionName = p.Results.sessionName;
session = p.Results.session;
basepath = p.Results.basepath;
basename = p.Results.basepaths;
clusteringpath = p.Results.clusteringpath;

% Batch inputs
sessionIDs = p.Results.sessionIDs;
sessionsin = p.Results.sessions;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;

% Extra inputs
SWR_in = p.Results.SWR;
summaryFigures = p.Results.summaryFigures;
plotCellIDs = p.Results.plotCellIDs;

%% % % % % % % % % % % % % % % % % % % % % %
% Initialization of variables and figure
% % % % % % % % % % % % % % % % % % % % % %

UI = []; UI.settings.plotZLog = 0; UI.settings.plot3axis = 0; UI.settings.plotXdata = 'firingRate'; UI.settings.plotYdata = 'peakVoltage';
UI.settings.plotZdata = 'deepSuperficialDistance'; UI.settings.metricsTableType = 'Metrics'; colorStr = [];
UI.settings.deepSuperficial = ''; UI.settings.acgType = 'Normal'; UI.settings.cellTypeColors = []; UI.settings.monoSynDispIn = 'None';
UI.settings.layout = 3; UI.settings.displayMenu = 0; UI.settings.displayInhibitory = false; UI.settings.displayExcitatory = false;
UI.settings.customCellPlotIn{1} = 'Waveforms (single)'; UI.settings.customCellPlotIn{2} = 'ACGs (single)';
UI.settings.customCellPlotIn{3} = 'thetaPhaseResponse'; UI.settings.customCellPlotIn{4} = 'firingRateMap';
UI.settings.customCellPlotIn{5} = 'firingRateMap'; UI.settings.customCellPlotIn{6} = 'firingRateMap'; UI.settings.plotCountIn = 'GUI 3+3';
UI.settings.tSNE.calcNarrowAcg = true; UI.settings.tSNE.calcFiltWaveform = true; UI.settings.tSNE.metrics = '';
UI.settings.tSNE.calcWideAcg = true; UI.settings.dispLegend = 1; UI.settings.tags = {'good','bad','mua','noise','inverseSpike','Other'};
UI.settings.groundTruthMarkers = {'d','o','s','*','+','p'}; UI.settings.groundTruth = {'PV+','NOS1+','GAT1+'};
UI.settings.plotWaveformMetrics = 1; UI.settings.metricsTable = 1; synConnectOptions = {'None', 'Selected', 'Upstream', 'Downstream', 'Up & downstream', 'All'};
UI.settings.stickySelection = false; UI.settings.fieldsMenuMetricsToExlude  = {'tags','groundTruthClassification','groups'};
UI.settings.plotOptionsToExlude = {'acg_','waveforms_','isi_','responseCurves_thetaPhase','responseCurves_thetaPhase_zscored','responseCurves_firingRateAcrossTime','groups','tags','groundTruthClassification'}; UI.settings.tSNE.dDistanceMetric = 'euclidean';
UI.settings.menuOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','groups'}; UI.params.inbound = [];
UI.settings.tableOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','brainRegion','labels','deepSuperficial','groups'};
UI.settings.tableDataSortingList = sort({'cellID', 'putativeCellType','peakVoltage','firingRate','troughToPeak','synapticConnectionsOut','synapticConnectionsIn','animal','sessionName','cv2','brainRegion','spikeGroup'});
UI.settings.firingRateMap.showHeatmap = false; UI.settings.firingRateMap.showLegend = false; UI.settings.firingRateMap.showHeatmapColorbar = false;
UI.settings.referenceData = 'None'; UI.settings.groundTruthData = 'None'; UI.BatchMode = false; UI.params.ii_history = 1; UI.params.ClickedCells = [];
UI.params.incoming = []; UI.params.outgoing = []; UI.monoSyn.disp = ''; UI.monoSyn.dispHollowGauss = false; UI.settings.binCount = 100;
UI.settings.customPlotHistograms = 1; UI.tableData.Column1 = 'putativeCellType'; UI.tableData.Column2 = 'brainRegion'; UI.settings.ACGLogIntervals = -3:0.04:1;
UI.tableData.SortBy = 'cellID'; UI.plot.xTitle = ''; UI.plot.yTitle = ''; UI.plot.zTitle = ''; ce_waitbar = [];
UI.cells.excitatory = []; UI.cells.inhibitory = []; UI.cells.inhibitory_subset = []; UI.cells.excitatory_subset = [];
UI.cells.excitatoryPostsynaptic = []; UI.cells.inhibitoryPostsynaptic = []; UI.params.outbound = []; h_scatter = [];
UI.zoom.global = cell(1,10); UI.zoom.globalLog = cell(1,10); UI.settings.logMarkerSize = 0; clr_groups = []; clr_groups2 = [];  clr_groups3 = []; putativeSubset = []; putativeSubset_inh = [];
UI.params.chanCoords.x_factor = 40; UI.params.chanCoords.y_factor = 10; UI.colors.toggleButtons = [0. 0.3 0.7];
UI.settings.plotExcitatoryConnections = true; UI.settings.plotInhibitoryConnections = true; iLine = 1; batchIDs = [];
UI.colorLine = [0, 0.4470, 0.7410;0.8500, 0.3250, 0.0980;0.9290, 0.6940, 0.1250;0.4940, 0.1840, 0.5560;0.4660, 0.6740, 0.1880;0.3010, 0.7450, 0.9330;0.6350, 0.0780, 0.1840];

groups_ids = []; clusClas = []; plotX = []; plotY = []; plotY1 = []; plotZ = [];  plotMarkerSize = [];
classes2plot = []; classes2plotSubset = []; fieldsMenu = []; table_metrics = []; ii = []; history_classification = [];
brainRegions_list = []; brainRegions_acronym = []; cell_class_count = [];  plotOptions = '';
plotAcgFit = 0; clasLegend = 0; Colorval = 1; plotClas = []; plotClas11 = []; groupData.groupsList = {'groups','tags','groundTruthClassification'};
colorMenu = []; groups2plot = []; groups2plot2 = []; plotClasGroups2 = []; connectivityGraph = [];
plotClasGroups = [];  plotClas2 = []; general = []; plotAverage_nbins = 40; table_fieldsNames = {};
tSNE_metrics = [];  classificationTrackChanges = []; time_waveforms_zscored = []; spikesPlots = {}; K = gausswin(10)*gausswin(10)'; K = 1.*K/sum(K(:));
tableDataOrder = []; groundTruthSelection = []; subsetGroundTruth = [];
idx_textFilter = []; groundTruthCelltypesList = {''}; db = {}; gt = {}; plotConnections = [1 1 1];
clickPlotRegular = true; fig2_axislimit_x = []; fig2_axislimit_y = []; fig3_axislimit_x = []; fig3_axislimit_y = [];
fig2_axislimit_x_reference = []; fig2_axislimit_y_reference = []; fig2_axislimit_x_groundTruth = []; fig2_axislimit_y_groundTruth = [];
referenceData=[]; reference_cell_metrics = []; groundTruth_cell_metrics = []; groundTruthData=[]; customPlotOptions = {};

timerVal = tic;
spikes = []; events = []; states = [];
createStruct.Interpreter = 'tex'; createStruct.WindowStyle = 'modal';
polygon1.handle = gobjects(0); fig = 1;
set(groot, 'DefaultFigureVisible', 'on','DefaultAxesLooseInset',[.01,.01,.01,.01]), maxFigureSize = get(groot,'ScreenSize'); UI.settings.figureSize = [50, 50, min(1500,maxFigureSize(3)-50), min(1000,maxFigureSize(4)-50)];

if isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

CellExplorerVersion = 1.64;

UI.fig = figure('Name',['CellExplorer v' num2str(CellExplorerVersion)],'NumberTitle','off','renderer','opengl', 'MenuBar', 'None','windowscrollWheelFcn',@ScrolltoZoomInPlot,'KeyPressFcn', {@keyPress},'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off','WindowButtonMotionFcn', @hoverCallback,'pos',[0,0,1600,800]);
hManager = uigetmodemanager(UI.fig);

% % % % % % % % % % % % % % % % % % % % % %
% User preferences
% % % % % % % % % % % % % % % % % % % % % %

CellExplorer_Preferences

% % % % % % % % % % % % % % % % % % % % % %
% Checking for Matlab version requirement (Matlab R2017a)
% % % % % % % % % % % % % % % % % % % % % %

if verLessThan('matlab', '9.2')
    warning('CellExplorer is only fully compatible and tested with Matlab version 9.2 and forward (Matlab R2017a)')
    return
end

% % % % % % % % % % % % % % % % % % % % % %
% Turning off select warnings
% % % % % % % % % % % % % % % % % % % % % %

warning('off','MATLAB:deblank:NonStringInput')
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
warning('off','MATLAB:Axes:NegativeDataInLogAxis')

% % % % % % % % % % % % % % % % % % % % % %
% Database initialization
% % % % % % % % % % % % % % % % % % % % % %

if exist('db_load_settings','file')
    db_settings = db_load_settings;
    if ~strcmp(db_settings.credentials.username,'user')
        enableDatabase = 1;
    else
        enableDatabase = 0;
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
elseif ~isempty(id) || ~isempty(sessionName) || ~isempty(session)
    if enableDatabase
        disp('Loading session from database')
        if ~isempty(id)
            try
                [session, basename, basepath, clusteringpath] = db_set_session('sessionId',id,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
        elseif ~isempty(sessionName)
            try
                [session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionName,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
        else
            try
                [session, basename, basepath, clusteringpath] = db_set_session('session',session,'saveMat',false);
            catch
                warning('Failed to load session');
                return
            end
        end
        try
            LoadSession;
            if ~exist('cell_metrics','var')
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
            cell_metrics = LoadCellMetricsBatch('sessionIDs',sessionIDs);
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
            cell_metrics = LoadCellMetricsBatch('sessions',sessionsin);
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
        cell_metrics = LoadCellMetricsBatch('clusteringpaths',clusteringpaths);
        initializeSession
    catch
        warning('Failed to load dataset from clustering paths');
        return
    end
elseif ~isempty(basepaths)
    try
        cell_metrics = LoadCellMetricsBatch('basepaths',basepaths);
        initializeSession
    catch
        warning('Failed to load dataset from basepaths');
        return
    end
else
    try
        cd(basepath)
    catch
        warning('basepath not available')
        close(UI.fig)
        return
    end
    [~,basename,~] = fileparts(basepath);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        disp(['CellExplorer: Loading ',basename,'.session.mat'])
        load(fullfile(basepath,[basename,'.session.mat']))
        if isempty(session.spikeSorting{1}.relativePath)
            clusteringpath = '';
        else
            clusteringpath = session.spikeSorting{1}.relativePath;
        end
        if exist(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']),'file')
            load(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']));
            cell_metrics.general.path = fullfile(basepath,clusteringpath);
            cell_metrics.general.saveAs = 'cell_metrics';
            initializeSession;
        else
            cell_metrics = [];
            disp('CellExplorer: No cell_metrics exist in base folder. Loading from database')
            if enableDatabase
                DatabaseSessionDialog;
                if ~exist('cell_metrics','var') || isempty(cell_metrics)
                    disp('No dataset selected - closing CellExplorer')
                    if ishandle(UI.fig)
                        close(UI.fig)
                    end
                    cell_metrics = [];
                    return
                end
            else
                warning('Neither basename.session.mat or basename.cell_metrics.mat exist in base folder')
                if ishandle(UI.fig)
                    close(UI.fig)
                end
                return
            end
        end
        
    elseif exist(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']),'file')
        disp('Loading local cell_metrics')
        load(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']));
        cell_metrics.general.path = fullfile(basepath,clusteringpath);
        initializeSession
    else
        if enableDatabase
            DatabaseSessionDialog;
        else
            loadFromFile
        end
        if ~exist('cell_metrics','var') || isempty(cell_metrics)
            disp('No dataset selected - closing CellExplorer')
            if ishandle(UI.fig)
                close(UI.fig)
            end
            return
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % %
% Menu
% % % % % % % % % % % % % % % % % % % % % %

if ~verLessThan('matlab', '9.3')
    menuLabel = 'Text';
    menuSelectedFcn = 'MenuSelectedFcn';
else
    menuLabel = 'Label';
    menuSelectedFcn = 'Callback';
end

% CellExplorer
UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'CellExplorer');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'About CellExplorer',menuSelectedFcn,@AboutDialog);
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit preferences',menuSelectedFcn,@LoadPreferences,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit DB credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit DB repository paths',menuSelectedFcn,@editDBrepositories);
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Benchmarking',menuSelectedFcn,@runBenchMark,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitCellExplorer,'Separator','on','Accelerator','W');

% File
UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
uimenu(UI.menu.file.topMenu,menuLabel,'Load session from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
uimenu(UI.menu.file.topMenu,menuLabel,'Load session(s) from database',menuSelectedFcn,@DatabaseSessionDialog,'Accelerator','D');
UI.menu.file.save = uimenu(UI.menu.file.topMenu,menuLabel,'Save classification',menuSelectedFcn,@saveDialog,'Separator','on','Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Restore classification from backup',menuSelectedFcn,@restoreBackup);
uimenu(UI.menu.file.topMenu,menuLabel,'Reload cell metrics',menuSelectedFcn,@reloadCellMetrics,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Export figure',menuSelectedFcn,@exportFigure,'Separator','on');

% Navigation
UI.menu.navigation.topMenu = uimenu(UI.fig,menuLabel,'Navigation');
UI.menu.navigation.goToCell = uimenu(UI.menu.navigation.topMenu,menuLabel,'Go to cell',menuSelectedFcn,@goToCell,'Accelerator','F');
UI.menu.navigation.previousSelectedCell = uimenu(UI.menu.navigation.topMenu,menuLabel,'Go to previous select cell [backspace]',menuSelectedFcn,@ii_history_reverse);

UI.menu.cellSelection.topMenu = uimenu(UI.fig,menuLabel,'Cell selection');
uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Polygon selection of cells from plot',menuSelectedFcn,@polygonSelection,'Accelerator','P');
uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Perform group action [space]',menuSelectedFcn,@selectCellsForGroupAction);
UI.menu.cellSelection.stickySelection = uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Sticky cell selection',menuSelectedFcn,@toggleStickySelection,'Separator','on');
UI.menu.cellSelection.stickySelectionReset = uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Reset sticky selection',menuSelectedFcn,@toggleStickySelectionReset);

% Classification
UI.menu.edit.topMenu = uimenu(UI.fig,menuLabel,'Classification');
UI.menu.edit.undoClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Undo classification',menuSelectedFcn,@undoClassification,'Accelerator','Z');
UI.menu.edit.buttonBrainRegion = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign brain region',menuSelectedFcn,@buttonBrainRegion,'Accelerator','B');
UI.menu.edit.buttonLabel = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign label',menuSelectedFcn,@buttonLabel,'Accelerator','L');
UI.menu.edit.addCellType = uimenu(UI.menu.edit.topMenu,menuLabel,'Add new cell-type',menuSelectedFcn,@AddNewCellType,'Separator','on');
UI.menu.edit.addTag = uimenu(UI.menu.edit.topMenu,menuLabel,'Add new tag',menuSelectedFcn,@addTag);


UI.menu.edit.reclassify_celltypes = uimenu(UI.menu.edit.topMenu,menuLabel,'Reclassify cells',menuSelectedFcn,@reclassify_celltypes,'Accelerator','R','Separator','on');
UI.menu.edit.performClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Agglomerative hierarchical cluster tree classification',menuSelectedFcn,@performClassification);
UI.menu.edit.adjustDeepSuperficial = uimenu(UI.menu.edit.topMenu,menuLabel,'Adjust Deep-Superficial assignment for session',menuSelectedFcn,@adjustDeepSuperficial1,'Separator','on');

% View / display
UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'View');
UI.menu.display.showHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Show full menubar',menuSelectedFcn,@ShowHideMenu,'Accelerator','M');
UI.menu.display.showAllWaveforms = uimenu(UI.menu.display.topMenu,menuLabel,'Show all traces',menuSelectedFcn,@showAllWaveforms,'Separator','on');
if UI.settings.showAllWaveforms; UI.menu.display.showAllWaveforms.Checked = 'on'; end 
UI.menu.display.zscoreWaveforms = uimenu(UI.menu.display.topMenu,menuLabel,'Z-score waveforms',menuSelectedFcn,@adjustZscoreWaveforms);
if UI.settings.zscoreWaveforms; UI.menu.display.zscoreWaveforms.Checked = 'on'; end 

UI.menu.display.showMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Show waveform metrics',menuSelectedFcn,@showWaveformMetrics);
UI.menu.display.showChannelMapMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Channel map inset with waveforms');
UI.menu.display.showChannelMap.ops(1) = uimenu(UI.menu.display.showChannelMapMenu,menuLabel,'No channelmap',menuSelectedFcn,@showChannelMap);
UI.menu.display.showChannelMap.ops(2) = uimenu(UI.menu.display.showChannelMapMenu,menuLabel,'Single units',menuSelectedFcn,@showChannelMap);
UI.menu.display.showChannelMap.ops(3) = uimenu(UI.menu.display.showChannelMapMenu,menuLabel,'Trilateration of units',menuSelectedFcn,@showChannelMap);
if UI.settings.plotInsetChannelMap; UI.menu.display.showChannelMap.ops(UI.settings.plotInsetChannelMap).Checked = 'on'; end
UI.menu.display.showInsetACG = uimenu(UI.menu.display.topMenu,menuLabel,'Show ACG inset with waveforms',menuSelectedFcn,@showInsetACG);
if UI.settings.plotInsetACG; UI.menu.display.showInsetACG.Checked = 'on'; end
UI.menu.display.dispLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend in spikes plot',menuSelectedFcn,@showLegends);
if UI.settings.dispLegend; UI.menu.display.dispLegend.Checked = 'on'; end
UI.menu.display.firingRateMapShowLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowLegend,'Separator','on');
if UI.settings.firingRateMap.showLegend; UI.menu.display.firingRateMapShowLegend.Checked = 'on'; end
UI.menu.display.showHeatmap = uimenu(UI.menu.display.topMenu,menuLabel,'Show heatmap in firing rate maps',menuSelectedFcn,@ToggleHeatmapFiringRateMaps);
if UI.settings.firingRateMap.showHeatmap; UI.menu.display.showHeatmap.Checked = 'on'; end
UI.menu.display.firingRateMapShowHeatmapColorbar = uimenu(UI.menu.display.topMenu,menuLabel,'Show colorbar in heatmaps in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowHeatmapColorbar);
if UI.settings.firingRateMap.showHeatmapColorbar; UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on'; end
UI.menu.display.isiNormalizationMenu = uimenu(UI.menu.display.topMenu,menuLabel,'ISI normalization','Separator','on');
UI.menu.display.isiNormalization.ops(1) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Rate',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.isiNormalization.ops(2) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Occurrence',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.isiNormalization.ops(3) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Instantaneous rate',menuSelectedFcn,@buttonACG_normalize);
initGroupMenu('isiNormalization')
UI.menu.display.rainCloudNormalizationMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Raincloud plot normalization');
UI.menu.display.rainCloudNormalization.ops(1) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Peak',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
UI.menu.display.rainCloudNormalization.ops(2) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Probability',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
UI.menu.display.rainCloudNormalization.ops(3) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Count',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
initGroupMenu('rainCloudNormalization')
UI.menu.display.waveformsAcrossChannelsAlignmentMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Waveform alignment');
UI.menu.display.waveformsAcrossChannelsAlignment.ops(1) = uimenu(UI.menu.display.waveformsAcrossChannelsAlignmentMenu,menuLabel,'Probe layout',menuSelectedFcn,@adjustWaveformsAcrossChannelsAlignment);
UI.menu.display.waveformsAcrossChannelsAlignment.ops(2) = uimenu(UI.menu.display.waveformsAcrossChannelsAlignmentMenu,menuLabel,'Electrode groups',menuSelectedFcn,@adjustWaveformsAcrossChannelsAlignment);
initGroupMenu('waveformsAcrossChannelsAlignment')
UI.menu.display.plotChannelMapAllChannelsMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Waveform count across channels');
UI.menu.display.plotChannelMapAllChannels.ops(1) = uimenu(UI.menu.display.plotChannelMapAllChannelsMenu,menuLabel,'All channels',menuSelectedFcn,@adjustPlotChannelMapAllChannels);
UI.menu.display.plotChannelMapAllChannels.ops(2) = uimenu(UI.menu.display.plotChannelMapAllChannelsMenu,menuLabel,'Subset',menuSelectedFcn,@adjustPlotChannelMapAllChannels);
initGroupMenu('plotChannelMapAllChannels')
UI.menu.display.trilatGroupDataMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Trilateration group data');
UI.menu.display.trilatGroupData.ops(1) = uimenu(UI.menu.display.trilatGroupDataMenu,menuLabel,'session',menuSelectedFcn,@adjustTrilatGroupData);
UI.menu.display.trilatGroupData.ops(2) = uimenu(UI.menu.display.trilatGroupDataMenu,menuLabel,'animal',menuSelectedFcn,@adjustTrilatGroupData);
UI.menu.display.trilatGroupData.ops(3) = uimenu(UI.menu.display.trilatGroupDataMenu,menuLabel,'all',menuSelectedFcn,@adjustTrilatGroupData);
initGroupMenu('trilatGroupData')
UI.menu.display.significanceMetricsMatrix = uimenu(UI.menu.display.topMenu,menuLabel,'Generate significance matrix',menuSelectedFcn,@SignificanceMetricsMatrix,'Accelerator','K','Separator','on');
UI.menu.display.generateRainCloudsPlot = uimenu(UI.menu.display.topMenu,menuLabel,'Generate rain cloud metrics figure',menuSelectedFcn,@generateRainCloudPlot);
UI.menu.display.plotSupplementaryFigure = uimenu(UI.menu.display.topMenu,menuLabel,'Generate supplementary figure',menuSelectedFcn,@plotSupplementaryFigure);
UI.menu.display.markerSizeMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Change marker size for group plots',menuSelectedFcn,@defineMarkerSize,'Separator','on');
UI.menu.display.changeColormap = uimenu(UI.menu.display.topMenu,menuLabel,'Change colormap',menuSelectedFcn,@changeColormap);
UI.menu.display.sortingMetric = uimenu(UI.menu.display.topMenu,menuLabel,'Change metric used for sorting image data',menuSelectedFcn,@editSortingMetric);
UI.menu.display.redefineMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Change metrics used for t-SNE plot',menuSelectedFcn,@tSNE_redefineMetrics,'Accelerator','T');
UI.menu.display.flipXY = uimenu(UI.menu.display.topMenu,menuLabel,'Flip x and y axes in the custom plot',menuSelectedFcn,@flipXY,'Separator','on');

% ACG
UI.menu.ACG.topMenu = uimenu(UI.fig,menuLabel,'ACG');
UI.menu.ACG.window.ops(1) = uimenu(UI.menu.ACG.topMenu,menuLabel,'30 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(2) = uimenu(UI.menu.ACG.topMenu,menuLabel,'100 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(3) = uimenu(UI.menu.ACG.topMenu,menuLabel,'1 sec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(4) = uimenu(UI.menu.ACG.topMenu,menuLabel,'Log10',menuSelectedFcn,@buttonACG);
UI.menu.ACG.showFit = uimenu(UI.menu.ACG.topMenu,menuLabel,'Show ACG fit',menuSelectedFcn,@toggleACGfit,'Separator','on');

% MonoSyn
UI.menu.monoSyn.topMenu = uimenu(UI.fig,menuLabel,'MonoSyn');
UI.menu.monoSyn.plotConns.ops(1) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in custom plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.plotConns.ops(2) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in Classic plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.plotConns.ops(3) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in tSNE plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.plotExcitatoryConnections = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Plot excitatiry connections','Checked','on',menuSelectedFcn,@togglePlotExcitatoryConnections,'Separator','on');
UI.menu.monoSyn.plotInhibitoryConnections = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Plot inhibitory connections','Checked','on',menuSelectedFcn,@togglePlotInhibitoryConnections);

UI.menu.monoSyn.showConn.ops(1) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'None',menuSelectedFcn,@buttonMonoSyn,'Separator','on');
UI.menu.monoSyn.showConn.ops(2) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Selected',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(3) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Upstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(4) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(5) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Up & downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(6) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'All',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(strcmp(synConnectOptions,UI.settings.monoSynDispIn)).Checked = 'on';
UI.menu.monoSyn.highlightExcitatory = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Highlight excitatory cells','Separator','on',menuSelectedFcn,@highlightExcitatoryCells,'Accelerator','E');
UI.menu.monoSyn.highlightInhibitory = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Highlight inhibitory cells',menuSelectedFcn,@highlightInhibitoryCells,'Accelerator','I');
UI.menu.monoSyn.excitatoryPostsynapticCells = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Highlight cells receiving excitatory input',menuSelectedFcn,@highlightExcitatoryPostsynapticCells);
UI.menu.monoSyn.inhibitoryPostsynapticCells = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Highlight cells receiving inhibitory input',menuSelectedFcn,@highlightInhibitoryPostsynapticCells);
UI.menu.monoSyn.toggleHollowGauss = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show hollow gaussian in CCG plots',menuSelectedFcn,@toggleHollowGauss,'Separator','on','Accelerator','F','Checked','on');
uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Adjust monosynaptic connections',menuSelectedFcn,@adjustMonoSyn_UpdateMetrics,'Separator','on');

% Reference data
UI.menu.referenceData.topMenu = uimenu(UI.fig,menuLabel,'Reference data');
UI.menu.referenceData.ops(1) = uimenu(UI.menu.referenceData.topMenu,menuLabel,'No reference data',menuSelectedFcn,@showReferenceData,'Checked','on');
UI.menu.referenceData.ops(2) = uimenu(UI.menu.referenceData.topMenu,menuLabel,'Image data',menuSelectedFcn,@showReferenceData);
UI.menu.referenceData.ops(3) = uimenu(UI.menu.referenceData.topMenu,menuLabel,'Scatter data',menuSelectedFcn,@showReferenceData);
UI.menu.referenceData.ops(4) = uimenu(UI.menu.referenceData.topMenu,menuLabel,'Histogram data',menuSelectedFcn,@showReferenceData);
uimenu(UI.menu.referenceData.topMenu,menuLabel,'Open reference data dialog',menuSelectedFcn,@defineReferenceData,'Separator','on');
% uimenu(UI.menu.referenceData.topMenu,menuLabel,'Compare cell groups to reference data',menuSelectedFcn,@compareToReference,'Separator','on');
uimenu(UI.menu.referenceData.topMenu,menuLabel,'Adjust bin count for reference and ground truth plots',menuSelectedFcn,@defineBinSize,'Separator','on');

% Ground truth
UI.menu.groundTruth.topMenu = uimenu(UI.fig,menuLabel,'Ground truth');
UI.menu.groundTruth.ops(1) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'No ground truth data',menuSelectedFcn,@showGroundTruthData,'Checked','on');
UI.menu.groundTruth.ops(2) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Image data',menuSelectedFcn,@showGroundTruthData);
UI.menu.groundTruth.ops(3) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Scatter data',menuSelectedFcn,@showGroundTruthData);
UI.menu.groundTruth.ops(4) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Histogram data',menuSelectedFcn,@showGroundTruthData);
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Open ground truth data dialog',menuSelectedFcn,@defineGroundTruthData,'Separator','on');
% uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Compare cell groups to ground truth cell types',menuSelectedFcn,@compareToReference,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Adjust bin count for reference and ground truth plots',menuSelectedFcn,@defineBinSize,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Show ground truth classification panel',menuSelectedFcn,@performGroundTruthClassification,'Accelerator','Y','Separator','on');
% uimenu(UI.menu.groupData.topMenu,menuLabel,'Show ground truth data in current session(s)',menuSelectedFcn,@loadGroundTruth,'Accelerator','U');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Save tagging to groundTruthData folder',menuSelectedFcn,@importGroundTruth);

% Group data
UI.menu.groupData.topMenu = uimenu(UI.fig,menuLabel,'Group data');
UI.menu.display.defineGroupData = uimenu(UI.menu.groupData.topMenu,menuLabel,'Open group data dialog',menuSelectedFcn,@defineGroupData,'Accelerator','G');

% Table menu
UI.menu.tableData.topMenu = uimenu(UI.fig,menuLabel,'Table data');
UI.menu.tableData.ops(1) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell metrics',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(2) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(3) = uimenu(UI.menu.tableData.topMenu,menuLabel,'None',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.column1 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 1','Separator','on');
for m = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.column1_ops(m) = uimenu(UI.menu.tableData.column1,menuLabel,UI.settings.tableDataSortingList{m},menuSelectedFcn,@setColumn1_metric);
end
UI.menu.tableData.column1_ops(strcmp(UI.tableData.Column1,UI.settings.tableDataSortingList)).Checked = 'on';

UI.menu.tableData.column2 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 2');
for m = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.column2_ops(m) = uimenu(UI.menu.tableData.column2,menuLabel,UI.settings.tableDataSortingList{m},menuSelectedFcn,@setColumn2_metric);
end
UI.menu.tableData.column2_ops(strcmp(UI.tableData.Column2,UI.settings.tableDataSortingList)).Checked = 'on';

uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list sorting:','Separator','on');
for m = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.sortingList(m) = uimenu(UI.menu.tableData.topMenu,menuLabel,UI.settings.tableDataSortingList{m},menuSelectedFcn,@setTableDataSorting);
end
UI.menu.tableData.sortingList(strcmp(UI.tableData.SortBy,UI.settings.tableDataSortingList)).Checked = 'on';

% Spikes
UI.menu.spikeData.topMenu = uimenu(UI.fig,menuLabel,'Spikes');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Open spike data dialog',menuSelectedFcn,@defineSpikesPlots,'Accelerator','A');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Hover to edit spike plot',menuSelectedFcn,@editSelectedSpikePlot,'Accelerator','J');

% Session
UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
uimenu(UI.menu.session.topMenu,menuLabel,'View metadata for current session',menuSelectedFcn,@viewSessionMetaData);
uimenu(UI.menu.session.topMenu,menuLabel,'Open directory of current session',menuSelectedFcn,@openSessionDirectory,'Accelerator','C','Separator','on');
uimenu(UI.menu.session.topMenu,menuLabel,'Show current session in the Buzsaki lab web DB',menuSelectedFcn,@openSessionInWebDB,'Separator','on');
uimenu(UI.menu.session.topMenu,menuLabel,'Show current animal in the Buzsaki lab web DB',menuSelectedFcn,@showAnimalInWebDB);

% Help
UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
uimenu(UI.menu.help.topMenu,menuLabel,'Keyboard shortcuts',menuSelectedFcn,@HelpDialog,'Accelerator','H');
uimenu(UI.menu.help.topMenu,menuLabel,'CellExplorer website',menuSelectedFcn,@openWebsite,'Accelerator','V');
uimenu(UI.menu.help.topMenu,menuLabel,'Tutorials',menuSelectedFcn,@openWebsite);

if UI.settings.plotWaveformMetrics; UI.menu.display.showMetrics.Checked = 'on'; end

if strcmp(UI.settings.acgType,'Normal')
    UI.menu.ACG.window.ops(2).Checked = 'On';
elseif strcmp(UI.settings.acgType,'Wide')
    UI.menu.ACG.window.ops(1).Checked = 'On';
elseif strcmp(UI.settings.acgType,'Log10')
    UI.menu.ACG.window.ops(4).Checked = 'On';
else
    UI.menu.ACG.window.ops(3).Checked = 'On';
end

% Save classification
if ~isempty(classificationTrackChanges)
    UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
end

%% % % % % % % % % % % % % % % % % % % % % %
% UI panels
% % % % % % % % % % % % % % % % % % % % % %

% Flexib grid box for adjusting the width of the side panels
UI.HBox = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0);

% Left panel
UI.panel.left = uix.VBoxFlex('Parent',UI.HBox,'position',[0 0.66 0.26 0.31]);

% Elements in left panel
UI.textFilter = uicontrol('Style','edit','Units','normalized','Position',[0 0.973 1 0.024],'String','Filter','HorizontalAlignment','left','Parent',UI.panel.left,'Callback',@filterCellsByText);
UI.panel.custom = uix.VBox('Position',[0 0.717 1 0.255],'Parent',UI.panel.left);
UI.panel.group = uix.VBox('Parent',UI.panel.left);
UI.panel.displaySettings = uix.VBox('Parent',UI.panel.left);
UI.panel.tabgroup2 = uitabgroup('Position',[0 0 1 0.162],'Units','normalized','SelectionChangedFcn',@updateLegends,'Parent',UI.panel.left);
set(UI.panel.left, 'Heights', [25 230 -100 -180 -90], 'Spacing', 8);

% Vertical center box with the title at top, grid flex with plots as middle element and message log and bechmark text at bottom
UI.VBox = uix.VBox( 'Parent', UI.HBox, 'Spacing', 0, 'Padding', 0 );

% Title box
UI.panel.centerTop = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);

% Grid Flex with plots
UI.panel.GridFlex = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);

% UI plot panels
UI.panel.subfig_ax1 = uipanel('position',[0 0.67 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax2 = uipanel('position',[0.33 0.67 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax3 = uipanel('position',[0.67 0.67 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax4 = uipanel('position',[0 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax5 = uipanel('position',[0.33 0.33 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax6 = uipanel('position',[0.67 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax7 = uipanel('position',[0 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax8 = uipanel('position',[0.33 0 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax9 = uipanel('position',[0.67 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);

% Right panel
UI.panel.right = uix.VBoxFlex('Parent',UI.HBox,'position',[0 0.66 0.26 0.31]);

% UI menu panels
UI.panel.navigation = uipanel('Title','Navigation','TitlePosition','centertop','Position',[0 0.927 1 0.065],'Units','normalized','Parent',UI.panel.right);
UI.panel.cellAssignment = uix.VBox('Position',[0 0.643 1 0.275],'Parent',UI.panel.right);
UI.panel.tabgroup1 = uitabgroup('Position',[0 0.493 1 0.142],'Units','normalized','Parent',UI.panel.right);

% Message log and performance
UI.panel.centerBottom = uix.HBox('Parent',UI.VBox);

% set VBox elements sizes
set( UI.HBox, 'Widths', [160 -1 160]);

% set HBox elements sizes
set( UI.VBox, 'Heights', [25 -1 25]);

subfig_ax(1) = axes('Parent',UI.panel.subfig_ax1);
subfig_ax(2) = axes('Parent',UI.panel.subfig_ax2);
subfig_ax(3) = axes('Parent',UI.panel.subfig_ax3);
subfig_ax(4) = axes('Parent',UI.panel.subfig_ax4);
subfig_ax(5) = axes('Parent',UI.panel.subfig_ax5);
subfig_ax(6) = axes('Parent',UI.panel.subfig_ax6);
subfig_ax(7) = axes('Parent',UI.panel.subfig_ax7);
subfig_ax(8) = axes('Parent',UI.panel.subfig_ax8);
subfig_ax(9) = axes('Parent',UI.panel.subfig_ax9);


% Title with details about the selected cell and current session
UI.title = uicontrol('Style','text','Units','normalized','Position',[0 0 1 1],'String',{'Cell details'},'HorizontalAlignment','center','FontSize',13,'Parent',UI.panel.centerTop);

% % % % % % % % % % % % % % % % % % %
% Metrics table
% % % % % % % % % % % % % % % % % % %

% Table with metrics for selected cell
UI.table = uitable('Parent',UI.panel.right,'Data',[table_fieldsNames,table_metrics(:,1)],'Units','normalized','Position',[0 0.003 1 0.485],'ColumnWidth',{100,  100},'columnname',{'Metrics',''},'RowName',[],'CellSelectionCallback',@ClicktoSelectFromTable,'CellEditCallback',@EditSelectFromTable,'KeyPressFcn', {@keyPress});

set(UI.panel.right, 'Heights', [50 250 180 -1], 'Spacing', 8);

if strcmp(UI.settings.metricsTableType,'Metrics')
    UI.settings.metricsTable=1;
    UI.menu.tableData.ops(1).Checked = 'On';
elseif strcmp(UI.settings.metricsTableType,'Cells')
    UI.settings.metricsTable=2; UI.table.ColumnName = {'','#',UI.tableData.Column1,UI.tableData.Column2};
    UI.table.ColumnEditable = [true false false false];
    UI.menu.tableData.ops(2).Checked = 'On';
else
    UI.settings.metricsTable=3; UI.table.Visible='Off';
    UI.menu.tableData.ops(3).Checked = 'On';
end

%% % % % % % % % % % % % % % % % % % % % % %
% UI content
% % % % % % % % % % % % % % % % % % % % % %

% % % % % % % % % % % % % % % % % % % %
% Message log and Benchmark
% % % % % % % % % % % % % % % % % % % %
set( UI.VBox, 'Heights', [25 -1 25]);
UI.popupmenu.log = uicontrol('Style','popupmenu','Units','normalized','String',{'Welcome to CellExplorer. Please check the Help menu to learn keyboard shortcuts or visit the website'},'HorizontalAlignment','left','FontSize',10,'Parent',UI.panel.centerBottom);
% Benchmark with display time in seconds for most recent plot call
UI.benchmark = uicontrol('Style','text','Units','normalized','String','Benchmark','HorizontalAlignment','left','FontSize',13,'ForegroundColor',[0.3 0.3 0.3],'Parent',UI.panel.centerBottom);
set(UI.panel.centerBottom, 'Widths', [-600 -300], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Navigation panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Navigation buttons
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0 0 0.33 1],'String','<','Callback',@(src,evnt)back,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0.34 0 0.33 1],'String','GoTo','Callback',@(src,evnt)goToCell,'KeyPressFcn', {@keyPress});
UI.pushbutton.next = uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0.67 0 0.33 1],'String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Cell assignments panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Cell classification
colored_string = DefineCellTypeList;
uicontrol('Parent',UI.panel.cellAssignment,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Cell classification','HorizontalAlignment','center');
UI.listbox.cellClassification = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[0 54 148 48],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType,'KeyPressFcn', {@keyPress});

% Poly-select and adding new cell type
UI.panel.buttonGroup0 = uix.HBox('Parent',UI.panel.cellAssignment);
uicontrol('Parent',UI.panel.buttonGroup0,'Style','pushbutton','Units','normalized','Position',[0 0 0.5 1],'String','O Polygon','Callback',@(src,evnt)polygonSelection,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.buttonGroup0,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.5 1],'String','Actions','Callback',@(src,evnt)selectCellsForGroupAction,'KeyPressFcn', {@keyPress}); % AddNewCellType

% Brain region
UI.pushbutton.brainRegion = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 20 145 15],'Units','normalized','String',['Region: ', cell_metrics.brainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyPressFcn', {@keyPress});

% Custom labels
UI.pushbutton.labels = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 3 145 15],'Units','normalized','String',['Label: ', cell_metrics.labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyPressFcn', {@keyPress});

set(UI.panel.cellAssignment, 'Heights', [15 -1 30 30 30], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Tab panel 1 (right side)
% % % % % % % % % % % % % % % % % % % %

% UI cell assignment tabs
UI.tabs.tags = uitab(UI.panel.tabgroup1,'Title','Tags');
UI.tabs.deepsuperficial = uitab(UI.panel.tabgroup1,'Title','D/S');

% Deep/Superficial
UI.listbox.deepSuperficial = uicontrol('Parent',UI.tabs.deepsuperficial,'Style','listbox','Position',getpixelposition(UI.tabs.deepsuperficial),'Units','normalized','String',UI.settings.deepSuperficial,'max',1,'min',1,'Value',cell_metrics.deepSuperficial_num(ii),'Callback',@(src,evnt)buttonDeepSuperficial,'KeyPressFcn', {@keyPress});

% Tags
buttonPosition = getButtonLayout(UI.tabs.tags,UI.settings.tags,1);
for m = 1:length(UI.settings.tags)
    UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String',UI.settings.tags{m},'Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)buttonTags(m),'KeyPressFcn', {@keyPress});
end
m = length(UI.settings.tags)+1;
UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String','+ tag','Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)addTag,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Custom plot panel (left side)
% % % % % % % % % % % % % % % % % % % %

% Custom plot
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 10 45 10],'Units','normalized','String','Custom plot style','HorizontalAlignment','center');
UI.popupmenu.metricsPlot = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 82 144 10],'Units','normalized','String',{'2D scatter plot','+ Histograms','3D scatter plot','Raincloud plot'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)customPlotStyle,'KeyPressFcn', {@keyPress});

% Custom plotting menues
UI.panel.buttonGroup1 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup1,'Style','text','Units','normalized','Position',[0.2 0 0.5 1],'String','  X data','HorizontalAlignment','left');
UI.checkbox.logx = uicontrol('Parent',UI.panel.buttonGroup1,'Style','checkbox','Units','normalized','Position',[0.5 0 0.5 1],'String','Log X','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotXLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.xData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 62 144 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX(),'KeyPressFcn', {@keyPress});
set(UI.panel.buttonGroup1, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup2 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup2,'Style','text','Position',[0.2 0 0.5 1],'Units','normalized','String','  Y data','HorizontalAlignment','left');
UI.checkbox.logy = uicontrol('Parent',UI.panel.buttonGroup2,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log Y','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotYLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.yData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 42 144 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY(),'KeyPressFcn', {@keyPress});
set(UI.panel.buttonGroup2, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup3 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup3,'Style','text','Position',[0.2 0 0.5 1],'Units','normalized','String','  Z data','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.checkbox.logz = uicontrol('Parent',UI.panel.buttonGroup3,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log Z','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotZLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 22 144 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData.Enable = 'Off'; UI.checkbox.logz.Enable = 'Off';
set(UI.panel.buttonGroup3, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup4 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup4,'Style','text','Position',[0.2 0 0.5 1],'Units','normalized','String','  Marker size','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.checkbox.logMarkerSize = uicontrol('Parent',UI.panel.buttonGroup4,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log size','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotMarkerSizeLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.markerSizeData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 2 144 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotMarkerSizedata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotMarkerSize(),'KeyPressFcn', {@keyPress});
UI.popupmenu.markerSizeData.Enable = 'Off'; UI.checkbox.logMarkerSize.Enable = 'Off';
set(UI.panel.buttonGroup4, 'Widths', [-1 70], 'Spacing', 5);
set(UI.panel.custom, 'Heights', [15 20 15 20 15 20 15 20 15 25], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Custom colors
% % % % % % % % % % % % % % % % % % % %'
uicontrol('Parent',UI.panel.group,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Color groups & filter','HorizontalAlignment','center');
UI.popupmenu.groups = uicontrol('Parent',UI.panel.group,'Style','popupmenu','Position',[2 73 144 10],'Units','normalized','String',colorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(1),'KeyPressFcn', {@keyPress});
updateColorMenuCount
UI.listbox.groups = uicontrol('Parent',UI.panel.group,'Style','listbox','Position',[0 20 148 54],'Units','normalized','String',{},'max',10,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyPressFcn', {@keyPress},'Enable','Off');
UI.checkbox.groups = uicontrol('Parent',UI.panel.group,'Style','checkbox','Position',[3 10 144 10],'Units','normalized','String','Group by cell types','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress},'Enable','Off','Value',1);
UI.checkbox.compare = uicontrol('Parent',UI.panel.group,'Style','checkbox','Position',[3 0 144 10],'Units','normalized','String','Compare to other','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress});

set(UI.panel.group, 'Heights', [15 20 -1 20 20], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Display settings panel (left side)
% % % % % % % % % % % % % % % % % % % %
% Select subset of cell type
updateCellCount
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Display settings','HorizontalAlignment','center');
UI.listbox.cellTypes = uicontrol('Parent',UI.panel.displaySettings,'Style','listbox','Position',[0 73 148 48],'Units','normalized','String',strcat(UI.settings.cellTypes,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(UI.settings.cellTypes),'Callback',@(src,evnt)buttonSelectSubset(),'KeyPressFcn', {@keyPress});

% Number of plots
UI.panel.buttonGroup5 = uix.HBox('Parent',UI.panel.displaySettings);
uicontrol('Parent',UI.panel.buttonGroup5,'Style','text','Position',[0 0 0.3 1],'Units','normalized','String','Layout','HorizontalAlignment','center');
UI.popupmenu.plotCount = uicontrol('Parent',UI.panel.buttonGroup5,'Style','popupmenu','Position',[0.3 0 0.7 1],'Units','normalized','String',{'GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6','GUI 1+6'},'max',1,'min',1,'Value',3,'Callback',@(src,evnt)AdjustGUIbutton,'KeyPressFcn', {@keyPress});
set(UI.panel.buttonGroup5, 'Widths', [45 -1], 'Spacing', 5);

for i_disp = 1:6
    UI.panel.buttonGroupView{i_disp} = uix.HBox('Parent',UI.panel.displaySettings);
    uicontrol('Parent',UI.panel.buttonGroupView{i_disp},'Style','text','String',num2str(i_disp),'HorizontalAlignment','center');
    UI.popupmenu.customplot{i_disp} = uicontrol('Parent',UI.panel.buttonGroupView{i_disp},'Style','popupmenu','String',plotOptions,'max',1,'min',1,'Value',1,'Callback',@toggleWaveformsPlot,'KeyPressFcn', {@keyPress});
    set(UI.panel.buttonGroupView{i_disp}, 'Widths', [15 -1], 'Spacing', 2);
    if any(strcmp(UI.settings.customCellPlotIn{i_disp},UI.popupmenu.customplot{i_disp}.String)); UI.popupmenu.customplot{i_disp}.Value = find(strcmp(UI.settings.customCellPlotIn{i_disp},UI.popupmenu.customplot{i_disp}.String)); else; UI.popupmenu.customplot{i_disp}.Value = 1; end
    UI.settings.customPlot{i_disp} = plotOptions{UI.popupmenu.customplot{i_disp}.Value};
end
set(UI.panel.displaySettings, 'Heights', [15 -1 22 22 22 22 22 22 25], 'Spacing', 3);
if find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); UI.popupmenu.plotCount.Value = find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); else; UI.popupmenu.plotCount.Value = 3; end; AdjustGUIbutton

% % % % % % % % % % % % % % % % % % % %
% Tab panel 2 (left side)
% % % % % % % % % % % % % % % % % % % %

% UI display settings tabs
UI.tabs.legends = uitab(UI.panel.tabgroup2,'Title','Legend');
UI.tabs.dispTags_minus = uitab(UI.panel.tabgroup2,'Title','-Tags');
UI.tabs.dispTags_plus = uitab(UI.panel.tabgroup2,'Title','+Tags');
UI.axis.legends = axes(UI.tabs.legends,'Position',[0 0 1 1]);
set(UI.axis.legends,'ButtonDownFcn',@createLegend)


% Display settings for tags_minus
buttonPosition = getButtonLayout(UI.tabs.dispTags_minus,UI.settings.tags,0);
for m = 1:length(UI.settings.tags)
    UI.togglebutton.dispTags(m) = uicontrol('Parent',UI.tabs.dispTags_minus,'Style','togglebutton','String',UI.settings.tags{m},'Units','normalized','Position',buttonPosition{m},'Value',0,'Callback',@(src,evnt)buttonTags_minus(m),'KeyPressFcn', {@keyPress});
end

% Display settings for tags_plus
for m = 1:length(UI.settings.tags)
    UI.togglebutton.dispTags2(m) = uicontrol('Parent',UI.tabs.dispTags_plus,'Style','togglebutton','String',UI.settings.tags{m},'Units','normalized','Position',buttonPosition{m},'Value',0,'Callback',@(src,evnt)buttonTags_plus(m),'KeyPressFcn', {@keyPress});
end


% Creates summary figures and closes the UI
if summaryFigures
    MsgLog('Creating summary figures',-1)
    plotSummaryFigures
    if ishandle(fig) && plotCellIDs ~= -1
        close(fig)
    end
    if ishandle(UI.fig)
        close(UI.fig)
    end
    MsgLog('Summary figures created. Saved to /summaryFigures',-1)
    return
end

% % % % % % % % % % % % % % % % % % %
% Maximazing figure to full screen
% % % % % % % % % % % % % % % % % % %

if ~verLessThan('matlab', '9.4')
    set(UI.fig,'WindowState','maximize','visible','on'), drawnow nocallbacks;
else
    set(UI.fig,'visible','on')
    drawnow nocallbacks; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks;
end

%% % % % % % % % % % % % % % % % % % % % % %
% Main loop of UI
% % % % % % % % % % % % % % % % % % % % % %

while ii <= cell_metrics.general.cellCount
    % breaking if figure has been closed
    if ~ishandle(UI.fig)
        break
    end
    updateUI
    % Waiting for uiresume call
    uiwait(UI.fig);
    
end

%% % % % % % % % % % % % % % % % % % % % % %
% Calls when closing
% % % % % % % % % % % % % % % % % % % % % %

if ishandle(UI.fig)
    % Closing CellExplorer figure if still open
    close(UI.fig);
end
cell_metrics = saveCellMetricsStruct(cell_metrics);


%% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

function updateUI
    
    timerVal = tic;
    if ishandle(UI.fig)
        UI.benchmark.String = '';
    end
    
    % Keeping track of selected cells
    if UI.params.ii_history(end) ~= ii
        UI.params.ii_history = [UI.params.ii_history,ii];
    end
    
    % Instantiates batch metrics
    if UI.BatchMode
        batchIDs = cell_metrics.batchIDs(ii);
        general = cell_metrics.general.batch{batchIDs};
    else
        batchIDs = 1;
        general = cell_metrics.general;
    end
    
    % Resetting list of highlighted cells
    if ~UI.settings.stickySelection
        UI.params.ClickedCells = [];
    end
    
    % Resetting polygon selection
    clickPlotRegular = true;
    
    % Resetting zoom levels for subplots
    UI.zoom.global = cell(1,10);
    UI.zoom.globalLog = cell(1,10);
    
    % Updating putative cell type listbox
    UI.listbox.cellClassification.Value = clusClas(ii);
    
    % Defining the subset of cells to display
    UI.params.subset = find(ismember(clusClas,classes2plot));
    
    % Updating ground truth tags
    if isfield(UI.tabs,'groundTruthClassification')
        updateGroundTruth
    end

    % Updating tags
    updateTags

    % Group data
    % Filters tagged cells ('tags','groups','groundTruthClassification')
    if ~isempty(groupData)
        dataTypes = {'tags','groups','groundTruthClassification'};
        filter_pos = [];
        filter_neg = [];
        for jjj = 1:numel(dataTypes)
            if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'plus_filter') && any(struct2array(groupData.(dataTypes{jjj}).plus_filter))
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'plus_filter')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).plus_filter);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).plus_filter.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj}))
                            filter_pos = [filter_pos,cell_metrics.(dataTypes{jjj}).(fields1{jj})];
                        end
                    end
                end
            end
            if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'minus_filter') && any(struct2array(groupData.(dataTypes{jjj}).minus_filter))
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'minus_filter')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).minus_filter);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).minus_filter.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj}))
                            filter_neg = [filter_neg,cell_metrics.(dataTypes{jjj}).(fields1{jj})];
                        end
                    end
                end
            end
        end
        if ~isempty(filter_neg)
            UI.params.subset = setdiff(UI.params.subset,filter_neg);
        end
        if ~isempty(filter_pos)
            UI.params.subset = intersect(UI.params.subset,filter_pos);
        end
    end
    
    if ~isempty(groups2plot2) && Colorval ~=1
        if UI.checkbox.groups.Value == 0
            subset2 = find(ismember(plotClas11,groups2plot2));
            plotClas = plotClas11;
        else
            subset2 = find(ismember(plotClas2,groups2plot2));
        end
        UI.params.subset = intersect(UI.params.subset,subset2);
    end
    
    % text filter
    if ~isempty(idx_textFilter)
        UI.params.subset = intersect(UI.params.subset,idx_textFilter);
    end
    
    % Regrouping cells if comparison checkbox is checked
    if UI.checkbox.compare.Value == 1
        plotClas = ones(1,length(plotClas));
        plotClas(UI.params.subset) = 2;
        UI.params.subset = 1:length(plotClas);
        classes2plotSubset = unique(plotClas);
        plotClasGroups = {'Other cells','Selected cells'};
    elseif UI.popupmenu.groups.Value == 1
        classes2plotSubset = intersect(plotClas(UI.params.subset),classes2plot);
    else
        classes2plotSubset = intersect(plotClas(UI.params.subset),groups2plot);
    end
    
    % Defining putative connections for selected cells
    if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && ~isempty(cell_metrics.putativeConnections.excitatory)
        putativeSubset = find(all(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)'));
    else
        putativeSubset=[];
        UI.params.incoming = [];
        UI.params.outgoing = [];
        UI.params.connections = [];
    end
    
    % Excitatory connections
    if ~isempty(putativeSubset)
        UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
        UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
        
        if any(strcmp(UI.monoSyn.disp, {'Selected','All'}))
            UI.params.inbound = find(UI.params.a2 == ii);
            UI.params.outbound = find(UI.params.a1 == ii);
        else
            UI.params.inbound = [];
            UI.params.outbound = [];
        end
        
        if any(strcmp(UI.monoSyn.disp, {'Upstream','Up & downstream'}))
            kkk = 1;
            UI.params.inbound = find(UI.params.a2 == ii);
            while ~isempty(UI.params.inbound) && any(ismember(UI.params.a2, UI.params.incoming)) && kkk < 10
                UI.params.inbound = [UI.params.inbound;find(ismember(UI.params.a2, UI.params.incoming))];
                kkk = kkk + 1;
            end
        end
        if any(strcmp(UI.monoSyn.disp, {'Downstream','Up & downstream'}))
            kkk = 1;
            UI.params.outbound = find(UI.params.a1 == ii);
            while ~isempty(UI.params.outbound) && any(ismember(UI.params.a1, UI.params.outgoing)) && kkk < 10
                UI.params.outbound = [UI.params.outbound;find(ismember(UI.params.a1, UI.params.outgoing))];
                kkk = kkk + 1;
            end
        end
        UI.params.incoming = UI.params.a1(UI.params.inbound);
        UI.params.outgoing = UI.params.a2(UI.params.outbound);
        UI.params.connections = [UI.params.incoming;UI.params.outgoing];
    else
        UI.params.incoming = [];
        UI.params.outgoing = [];
        UI.params.inbound = [];
        UI.params.outbound = [];
        UI.params.connections = [];
    end
    
    % Inhibitory connections
    if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory') && ~isempty(cell_metrics.putativeConnections.inhibitory)
        putativeSubset_inh = find(all(ismember(cell_metrics.putativeConnections.inhibitory,UI.params.subset)'));
    else
        putativeSubset_inh = [];
    end
    
    % Inhibitory connections
    if ~isempty(putativeSubset_inh)
        UI.params.b1 = cell_metrics.putativeConnections.inhibitory(putativeSubset_inh,1);
        UI.params.b2 = cell_metrics.putativeConnections.inhibitory(putativeSubset_inh,2);
        if any(strcmp(UI.monoSyn.disp, {'Selected','All'}))
            UI.params.inbound_inh = find(UI.params.b2 == ii);
            UI.params.outbound_inh = find(UI.params.b1 == ii);
        else
            UI.params.inbound_inh = [];
            UI.params.outbound_inh = [];
        end
        if any(strcmp(UI.monoSyn.disp, {'Upstream','Up & downstream'}))
            kkk = 1;
            UI.params.inbound_inh = find(UI.params.b2 == ii);
            while ~isempty(UI.params.inbound_inh) && any(ismember(UI.params.b2, UI.params.incoming_inh)) && kkk < 10
                UI.params.inbound_inh = [UI.params.inbound_inh;find(ismember(UI.params.b2, UI.params.incoming_inh))];
                kkk = kkk + 1;
            end
        end
        if any(strcmp(UI.monoSyn.disp, {'Downstream','Up & downstream'}))
            kkk = 1;
            UI.params.outbound_inh = find(UI.params.b1 == ii);
            while ~isempty(UI.params.outbound_inh) && any(ismember(UI.params.b1, UI.params.outgoing_inh)) && kkk < 10
                UI.params.outbound_inh = [UI.params.outbound_inh;find(ismember(UI.params.b1, UI.params.outgoing_inh))];
                kkk = kkk + 1;
            end
        end
        UI.params.incoming_inh = UI.params.b1(UI.params.inbound_inh);
        UI.params.outgoing_inh = UI.params.b2(UI.params.outbound_inh);
        UI.params.connections_inh = [UI.params.incoming_inh;UI.params.outgoing_inh];
    else
        UI.params.incoming_inh = [];
        UI.params.outgoing_inh = [];
        UI.params.inbound_inh = [];
        UI.params.outbound_inh = [];
        UI.params.connections_inh = [];
    end
    
    % Defining synaptically identified projecting cell
    if UI.settings.displayExcitatory && ~isempty(UI.cells.excitatory)
        UI.cells.excitatory_subset = intersect(UI.params.subset,UI.cells.excitatory);
    end
    if UI.settings.displayInhibitory && ~isempty(UI.cells.inhibitory)
        UI.cells.inhibitory_subset = intersect(UI.params.subset,UI.cells.inhibitory);
    end
    if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic)
        UI.cells.excitatoryPostsynaptic_subset = intersect(UI.params.subset,UI.cells.excitatoryPostsynaptic);
    else
        UI.cells.excitatoryPostsynaptic_subset = [];
    end
    if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic)
        UI.cells.inhibitoryPostsynaptic_subset = intersect(UI.params.subset,UI.cells.inhibitoryPostsynaptic);
    else
        UI.cells.inhibitoryPostsynaptic_subset = [];
    end
    
    % Group display definition
    if UI.checkbox.compare.Value == 1
        clr_groups = UI.settings.cellTypeColors(intersect(classes2plotSubset,plotClas(UI.params.subset)),:);
    elseif Colorval == 1 ||  UI.checkbox.groups.Value == 1
        clr_groups = UI.settings.cellTypeColors(intersect(classes2plot,plotClas(UI.params.subset)),:);
    else
        clr_groups = hsv(length(nanUnique(plotClas(UI.params.subset))))*0.8;
        if isnan(clr_groups)
            clr_groups = UI.settings.cellTypeColors(1,:);
        end
    end
    % Ground truth and reference data colors
    if ~strcmp(UI.settings.referenceData, 'None')
        clr_groups2 = UI.settings.cellTypeColors(intersect(referenceData.clusClas,referenceData.selection),:);
    end
    if ~strcmp(UI.settings.groundTruthData, 'None')
        clr_groups3 = UI.settings.groundTruthColors(intersect(groundTruthData.clusClas,groundTruthData.selection),:);
    end
    
    % Updating table for selected cell
    updateTableColumnWidth
    if UI.settings.metricsTable==1
        UI.table.Data(:,2) = table_metrics(:,ii);
    elseif UI.settings.metricsTable==2
        updateCellTableData;
    end
    
    % Updating title
     if isfield(cell_metrics,'sessionName') && isfield(cell_metrics.general,'batch')
        UI.title.String = ['Cell class: ', UI.settings.cellTypes{clusClas(ii)},', ' , num2str(ii),'/', num2str(cell_metrics.general.cellCount),' (batch ',num2str(batchIDs),'/',num2str(length(cell_metrics.general.batch)),') - UID: ', num2str(cell_metrics.UID(ii)),'/',num2str(general.cellCount),', spike group: ', num2str(cell_metrics.spikeGroup(ii)),', session: ', cell_metrics.sessionName{ii},',  animal: ',cell_metrics.animal{ii}];
    else
        UI.title.String = ['Cell Class: ', UI.settings.cellTypes{clusClas(ii)},', ', num2str(ii),'/', num2str(cell_metrics.general.cellCount),'  - spike group: ', num2str(cell_metrics.spikeGroup(ii))];
     end

    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    
    if any(UI.settings.customPlotHistograms == [1,3,4])
        if size(UI.panel.subfig_ax1.Children,1) > 1
            set(UI.fig,'CurrentAxes',UI.panel.subfig_ax1.Children(2))
        else
            set(UI.fig,'CurrentAxes',UI.panel.subfig_ax1.Children)
        end
        % Saving current view activated for previous cell
        [az,el] = view;
    end
    
%     delete(subfig_ax(1).Children)
%     set(UI.fig,'CurrentAxes',subfig_ax(1))

    % Deletes all children from the panel
    delete(UI.panel.subfig_ax1.Children)
    % Creating new chield
    subfig_ax(1) = axes('Parent',UI.panel.subfig_ax1);
    
    % Regular plot without histograms
    if any(UI.settings.customPlotHistograms == [1,2])
        if UI.settings.customPlotHistograms == 2 || strcmp(UI.settings.referenceData, 'Histogram') || strcmp(UI.settings.groundTruthData, 'Histogram')
            % Double kernel-histogram with scatter plot
            clear h_scatter
            h_scatter(2) = subplot(4,4,16); hold on % x axis
            h_scatter(2).Position = [0.30 0 0.685 0.21];
            h_scatter(3) = subplot(4,4,1); hold on % y axis
            h_scatter(3).Position = [0 0.30 0.21 0.685];
            subfig_ax(1) = subplot(4,4,4); hold on
            subfig_ax(1).Position = [0.30 0.30 0.685 0.685];
            view(h_scatter(3),[90 -90])
            set(h_scatter(2), 'visible', 'off');
            set(h_scatter(3), 'visible', 'off');
            if UI.checkbox.logx.Value == 1
                set(h_scatter(2), 'XScale', 'log')
            else
                set(h_scatter(2), 'XScale', 'linear')
            end
            if UI.checkbox.logy.Value == 1
                set(h_scatter(3), 'XScale', 'log')
            else
                set(h_scatter(3), 'XScale', 'linear')
            end
        end

        if ((strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.settings.groundTruthData, 'Image')) && ~isempty(groundTruth_cell_metrics)) && UI.checkbox.logy.Value == 1
            yyaxis right, hold on
            subfig_ax(1).YAxis(1).Color = 'k'; 
            subfig_ax(1).YAxis(2).Color = 'k';
        end
        hold on
        subfig_ax(1).YLabel.String = UI.plot.yTitle; subfig_ax(1).YLabel.Interpreter = 'none';
        subfig_ax(1).XLabel.String = UI.plot.xTitle;subfig_ax(1).XLabel.Interpreter = 'none';
        set(subfig_ax(1), 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
        xlim auto, ylim auto, zlim auto, axis tight
        
        % Setting linear/log scale
        if UI.checkbox.logx.Value == 1
            set(subfig_ax(1), 'XScale', 'log')
        else
            set(subfig_ax(1), 'XScale', 'linear')
        end
        if UI.checkbox.logy.Value == 1
            set(subfig_ax(1), 'YScale', 'log')
        else
            set(subfig_ax(1), 'YScale', 'linear')
        end
        
        % 2D plot
        set(subfig_ax(1),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on, axis tight
        view([0 90]);
        if UI.checkbox.logx.Value == 1
            AA = cell_metrics.(UI.plot.xTitle)(UI.params.subset);
            AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
            fig1_axislimit_x = [nanmin(AA),max(AA)];
        else
            AA = cell_metrics.(UI.plot.xTitle)(UI.params.subset);
            AA = AA( ~isnan(AA) & ~isinf(AA));
            fig1_axislimit_x = [nanmin(AA),max(AA)];
        end
        if isempty(fig1_axislimit_x)
            fig1_axislimit_x = [0 1];
        elseif diff(fig1_axislimit_x) == 0
            fig1_axislimit_x = fig1_axislimit_x + [-1 1];
        end
        if UI.checkbox.logy.Value == 1
            AA = cell_metrics.(UI.plot.yTitle)(UI.params.subset);
            AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
            fig1_axislimit_y = [nanmin(AA),max(AA)];
        else
            AA = cell_metrics.(UI.plot.yTitle)(UI.params.subset);
            AA = AA( ~isnan(AA) & ~isinf(AA));
            fig1_axislimit_y = [nanmin(AA),max(AA)];
        end
        if isempty(fig1_axislimit_y)
            fig1_axislimit_y = [0 1];
        elseif diff(fig1_axislimit_y) == 0
            fig1_axislimit_y = fig1_axislimit_y + [-1 1];
        end
        
        % Reference data
        if strcmp(UI.settings.referenceData, 'Points') && ~isempty(reference_cell_metrics) && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            ce_gscatter(reference_cell_metrics.(UI.plot.xTitle)(idx), reference_cell_metrics.(UI.plot.yTitle)(idx), referenceData.clusClas(idx), clr_groups2,8,'x');
%             legendScatter2 = gscatter(reference_cell_metrics.(UI.plot.xTitle)(idx), reference_cell_metrics.(UI.plot.yTitle)(idx), referenceData.clusClas(idx), clr_groups2,'x',8,'off');
%             set(legendScatter2,'HitTest','off')
        elseif strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            if ~exist('referenceData1','var') || ~isfield(referenceData1,'z') || ~strcmp(referenceData1.x_field,UI.plot.xTitle) || ~strcmp(referenceData1.y_field,UI.plot.yTitle) || referenceData1.x_log ~= UI.checkbox.logx.Value || referenceData1.y_log ~= UI.checkbox.logy.Value || ~strcmp(referenceData1.plotType, 'Image')
                if UI.checkbox.logx.Value == 1
                    referenceData1.x = linspace(log10(nanmin([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(1)])),log10(nanmax([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(2)])),UI.settings.binCount);
                    xdata = log10(reference_cell_metrics.(UI.plot.xTitle));
                else
                    referenceData1.x = linspace(nanmin([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(1)]),nanmax([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(2)]),UI.settings.binCount);
                    xdata = reference_cell_metrics.(UI.plot.xTitle);
                end
                if UI.checkbox.logy.Value == 1
                    AA = reference_cell_metrics.(UI.plot.yTitle);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    referenceData1.y = linspace(log10(nanmin([AA,fig1_axislimit_y(1)])),log10(nanmax([AA,fig1_axislimit_y(2)])),UI.settings.binCount);
                    ydata = log10(reference_cell_metrics.(UI.plot.yTitle));
                else
                    AA = reference_cell_metrics.(UI.plot.yTitle);
                    AA = AA( ~isnan(AA) & ~isinf(AA));
                    referenceData1.y = linspace(nanmin([AA,fig1_axislimit_y(1)]),nanmax([AA,fig1_axislimit_y(2)]),UI.settings.binCount);
                    ydata = reference_cell_metrics.(UI.plot.yTitle);
                end
                referenceData1.x_field = UI.plot.xTitle;
                referenceData1.y_field = UI.plot.yTitle;
                referenceData1.x_log = UI.checkbox.logx.Value;
                referenceData1.y_log = UI.checkbox.logy.Value;
                referenceData1.plotType = 'Image';
                colors = (1-(UI.settings.cellTypeColors)) * 250;
                referenceData1.z = zeros(length(referenceData1.x)-1,length(referenceData1.y)-1,3,size(colors,1));
                for m = referenceData.selection
                    idx = find(referenceData.clusClas==m);
                    [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),referenceData1.x,referenceData1.y,'norm','probability');
                    referenceData1.z(:,:,:,m) = bsxfun(@times,repmat(conv2(z_referenceData_temp,K,'same'),1,1,3),reshape(colors(m,:),1,1,[]));
                end
                referenceData1.x = referenceData1.x(1:end-1)+(referenceData1.x(2)-referenceData1.x(1))/2;
                referenceData1.y = referenceData1.y(1:end-1)+(referenceData1.y(2)-referenceData1.y(1))/2;
            end
            if strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logy.Value == 1
                yyaxis left, hold on
                set(gca,'YTick',[])
            end
            % Image plot
            referenceData1.image = 1-sum(referenceData1.z(:,:,:,referenceData.selection),4);
            referenceData1.image = flip(referenceData1.image,2);
            referenceData1.image = rot90(referenceData1.image);
            legendScatter2 = image(referenceData1.x,referenceData1.y,referenceData1.image,'HitTest','off', 'PickableParts', 'none'); axis tight
            set(legendScatter2,'HitTest','off')
            
            if ~isempty(reference_cell_metrics) && UI.checkbox.logy.Value == 1
                yyaxis right, hold on
            end
        end
            
            % Ground truth data
            if strcmp(UI.settings.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics) && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
                idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
                ce_gscatter(groundTruth_cell_metrics.(UI.plot.xTitle)(idx), groundTruth_cell_metrics.(UI.plot.yTitle)(idx), groundTruthData.clusClas(idx), clr_groups3,8,'x');
%                 legendScatter2 = gscatter(groundTruth_cell_metrics.(UI.plot.xTitle)(idx), groundTruth_cell_metrics.(UI.plot.yTitle)(idx), groundTruthData.clusClas(idx), clr_groups3,'x',8,'off');
%                 set(legendScatter2,'HitTest','off')
            elseif strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
                if ~exist('groundTruthData1','var') || ~isfield(groundTruthData1,'z') || ~strcmp(groundTruthData1.x_field,UI.plot.xTitle) || ~strcmp(groundTruthData1.y_field,UI.plot.yTitle) || groundTruthData1.x_log ~= UI.checkbox.logx.Value || groundTruthData1.y_log ~= UI.checkbox.logy.Value
                    
                    if UI.checkbox.logx.Value == 1
                        groundTruthData1.x = linspace(log10(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)])),log10(nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)])),UI.settings.binCount);
                        xdata = log10(groundTruth_cell_metrics.(UI.plot.xTitle));
                    else
                        groundTruthData1.x = linspace(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)]),nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)]),UI.settings.binCount);
                        xdata = groundTruth_cell_metrics.(UI.plot.xTitle);
                    end
                    if UI.checkbox.logy.Value == 1
                        groundTruthData1.y = linspace(log10(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)])),log10(nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)])),UI.settings.binCount);
                        ydata = log10(groundTruth_cell_metrics.(UI.plot.yTitle));
                    else
                        groundTruthData1.y = linspace(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)]),nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)]),UI.settings.binCount);
                        ydata = groundTruth_cell_metrics.(UI.plot.yTitle);
                    end
                    
                    groundTruthData1.x_field = UI.plot.xTitle;
                    groundTruthData1.y_field = UI.plot.yTitle;
                    groundTruthData1.x_log = UI.checkbox.logx.Value;
                    groundTruthData1.y_log = UI.checkbox.logy.Value;
                    
                    colors = (1-(UI.settings.groundTruthColors)) * 250;
                    groundTruthData1.z = zeros(length(groundTruthData1.x)-1,length(groundTruthData1.y)-1,3,size(colors,1));
                    for m = unique(groundTruthData.clusClas)
                        idx = find(groundTruthData.clusClas==m);
                        [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),groundTruthData1.x,groundTruthData1.y,'norm','probability');
                        groundTruthData1.z(:,:,:,m) = bsxfun(@times,repmat(conv2(z_referenceData_temp,K,'same'),1,1,3),reshape(colors(m,:),1,1,[]));
                    end
                    groundTruthData1.x = groundTruthData1.x(1:end-1)+(groundTruthData1.x(2)-groundTruthData1.x(1))/2;
                    groundTruthData1.y = groundTruthData1.y(1:end-1)+(groundTruthData1.y(2)-groundTruthData1.y(1))/2;
                end
                if strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logy.Value == 1
                    yyaxis left, hold on
                    set(gca,'YTick',[])
                end
                
                % Image plot
                groundTruthData1.image = 1-sum(groundTruthData1.z(:,:,:,groundTruthData.selection),4);
                groundTruthData1.image = flip(groundTruthData1.image,2);
                groundTruthData1.image = rot90(groundTruthData1.image);
                legendScatter2 = image(groundTruthData1.x,groundTruthData1.y,groundTruthData1.image,'HitTest','off', 'PickableParts', 'none'); axis tight
                set(legendScatter2,'HitTest','off'),legendScatter2.AlphaData = 0.9;
                alpha(0.3)
                if strcmp(UI.settings.referenceData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logy.Value == 1
                    yyaxis right, hold on
                end
            end
            plotGroupData(plotX,plotY,plotConnections(1))
            
            % Axes limits
            if ~strcmp(UI.settings.groundTruthData, 'None')
                idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
                if UI.checkbox.logx.Value == 1
                    AA = groundTruth_cell_metrics.(UI.plot.xTitle)(idx);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    fig1_axislimit_x_groundTruth = [nanmin(AA),max(AA)];
                else
                    fig1_axislimit_x_groundTruth = [min(groundTruth_cell_metrics.(UI.plot.xTitle)(idx)),max(groundTruth_cell_metrics.(UI.plot.xTitle)(idx))];
                end
                if isempty(fig1_axislimit_x_groundTruth)
                    fig1_axislimit_x_groundTruth = [0 1];
                elseif diff(fig1_axislimit_x_groundTruth) == 0
                    fig1_axislimit_x_groundTruth = fig1_axislimit_x_groundTruth + [-1 1];
                end
                if UI.checkbox.logy.Value == 1
                    AA = groundTruth_cell_metrics.(UI.plot.yTitle)(idx);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    fig1_axislimit_y_groundTruth = [nanmin(AA),max(AA)];
                else
                    fig1_axislimit_y_groundTruth = [min(groundTruth_cell_metrics.(UI.plot.yTitle)(idx)),max(groundTruth_cell_metrics.(UI.plot.yTitle)(idx))];
                end
                if isempty(fig1_axislimit_y_groundTruth)
                    fig1_axislimit_y_groundTruth = [0 1];
                elseif diff(fig1_axislimit_y_groundTruth) == 0
                    fig1_axislimit_y_groundTruth = fig1_axislimit_y_groundTruth + [-1 1];
                end
            end
            
            if ~strcmp(UI.settings.referenceData, 'None')
                idx = find(ismember(referenceData.clusClas,referenceData.selection));
                if UI.checkbox.logx.Value == 1
                    AA = reference_cell_metrics.(UI.plot.xTitle)(idx);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    fig1_axislimit_x_reference = [nanmin(AA),max(AA)];
                else
                    fig1_axislimit_x_reference = [min(reference_cell_metrics.(UI.plot.xTitle)(idx)),max(reference_cell_metrics.(UI.plot.xTitle)(idx))];
                end
                if isempty(fig1_axislimit_x_reference)
                    fig1_axislimit_x_reference = [0 1];
                elseif diff(fig1_axislimit_x_reference) == 0
                    fig1_axislimit_x_reference = fig1_axislimit_x_reference + [-1 1];
                end
                if UI.checkbox.logy.Value == 1
                    AA = reference_cell_metrics.(UI.plot.yTitle)(idx);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    fig1_axislimit_y_reference = [nanmin(AA),max(AA)];
                else
                    fig1_axislimit_y_reference = [min(reference_cell_metrics.(UI.plot.yTitle)(idx)),max(reference_cell_metrics.(UI.plot.yTitle)(idx))];
                end
                if isempty(fig1_axislimit_y_reference)
                    fig1_axislimit_y_reference = [0 1];
                elseif diff(fig1_axislimit_y_reference) == 0
                    fig1_axislimit_y_reference = fig1_axislimit_y_reference + [-1 1];
                end
            end
            
            if contains(UI.plot.xTitle,'_num')
                xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5]),
                subfig_ax(1).XLabel.String = UI.plot.xTitle(1:end-4);subfig_ax(1).XLabel.Interpreter = 'none';
            end
            if contains(UI.plot.yTitle,'_num')
                yticks([1:length(groups_ids.(UI.plot.yTitle))]), yticklabels(groups_ids.(UI.plot.yTitle)),ytickangle(65),ylim([0.5,length(groups_ids.(UI.plot.yTitle))+0.5]),
                subfig_ax(1).YLabel.String = UI.plot.yTitle(1:end-4); subfig_ax(1).YLabel.Interpreter = 'none';
            end
            if length(unique(plotClas(UI.params.subset)))==2
%                 G1 = plotX(UI.params.subset);
                G = findgroups(plotClas(UI.params.subset));
                if ~isempty(UI.params.subset(G==1)) && ~isempty(UI.params.subset(G==2))
                    if ~all(plotX(UI.params.subset(G==1))) && ~all(plotX(UI.params.subset(G==2)))
                        [h,p] = kstest2(plotX(UI.params.subset(G==1)),plotX(UI.params.subset(G==2)));
                        text(0.97,0.02,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90,'Interpreter', 'none','Interpreter', 'none','HitTest','off','BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    if ~all(plotY(UI.params.subset(G==1))) && ~all(plotY(UI.params.subset(G==2)))
                        [h,p] = kstest2(plotY(UI.params.subset(G==1)),plotY(UI.params.subset(G==2)));
                        text(0.02,0.97,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Interpreter', 'none','Interpreter', 'none','HitTest','off','BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                end
            end
            [az,el] = view;
            if strcmp(UI.settings.groundTruthData, 'None') && ~strcmp(UI.settings.referenceData, 'None')
                xlim([min(fig1_axislimit_x(1),fig1_axislimit_x_reference(1)),max(fig1_axislimit_x(2),fig1_axislimit_x_reference(2))])
                ylim([min(fig1_axislimit_y(1),fig1_axislimit_y_reference(1)),max(fig1_axislimit_y(2),fig1_axislimit_y_reference(2))])
            elseif ~strcmp(UI.settings.groundTruthData, 'None') && strcmp(UI.settings.referenceData, 'None') && ~isempty(fig1_axislimit_x_groundTruth) && ~isempty(fig1_axislimit_y_groundTruth)
                xlim([min(fig1_axislimit_x(1),fig1_axislimit_x_groundTruth(1)),max(fig1_axislimit_x(2),fig1_axislimit_x_groundTruth(2))])
                ylim([min(fig1_axislimit_y(1),fig1_axislimit_y_groundTruth(1)),max(fig1_axislimit_y(2),fig1_axislimit_y_groundTruth(2))])
            elseif ~strcmp(UI.settings.groundTruthData, 'None') && ~strcmp(UI.settings.referenceData, 'None')
                xlim([min([fig1_axislimit_x(1),fig1_axislimit_x_groundTruth(1),fig1_axislimit_x_reference(1)]),max([fig1_axislimit_x(2),fig1_axislimit_x_groundTruth(2),fig1_axislimit_x_reference(2)])])
                ylim([min([fig1_axislimit_y(1),fig1_axislimit_y_groundTruth(1),fig1_axislimit_y_reference(1)]),max([fig1_axislimit_y(2),fig1_axislimit_y_groundTruth(2),fig1_axislimit_y_reference(2)])])
            else
                xlim(fig1_axislimit_x), ylim(fig1_axislimit_y)
            end
            xlim11 = xlim;
            xlim12 = ylim;
            
        if UI.settings.customPlotHistograms == 2
            plotClas_subset = plotClas(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            
            for m = 1:length(unique(plotClas(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                idx = find(plotClas_subset==ids(m));
                if length(temp1)>1
                    X1 = plotX(temp1);
                    if UI.checkbox.logx.Value
                        X1 = X1(X1>0 & ~isinf(X1) & ~isnan(X1));
                        if all(isnan(X1))
                            return
                        end
                        [f, Xi, u] = ksdensity(log10(X1), 'bandwidth', []);
                        Xi = 10.^Xi;
                    else
                        X1 = X1(~isinf(X1) & ~isnan(X1));
                        [f, Xi, u] = ksdensity(X1, 'bandwidth', []);
                    end
                    area(Xi, f/max(f), 'FaceColor', clr_groups(m,:), 'EdgeColor', clr_groups(m,:), 'LineWidth', 1, 'FaceAlpha', 0.4,'HitTest','off', 'Parent', h_scatter(2)); hold on
                end
            end
            xlim(h_scatter(2), xlim11)
            
            for m = 1:length(unique(plotClas(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                idx = find(plotClas_subset==ids(m));
                if length(temp1)>1
                    X1 = plotY(temp1);
                    if UI.checkbox.logy.Value
                        X1 = X1(X1>0 & ~isinf(X1) & ~isnan(X1));
                        X1 = X1(X1>0);
                        if all(isnan(X1))
                            return
                        end
                        [f, Xi, u] = ksdensity(log10(X1), 'bandwidth', []);
                        Xi = 10.^Xi;
                    else
                        X1 = X1(~isinf(X1) & ~isnan(X1));
                        [f, Xi, u] = ksdensity(X1, 'bandwidth', []);
                    end
                    area(Xi,f/max(f), 'FaceColor', clr_groups(m,:), 'EdgeColor', clr_groups(m,:), 'LineWidth', 1, 'FaceAlpha', 0.4,'HitTest','off', 'Parent', h_scatter(3)); hold on
                end
            end
            xlim(h_scatter(3),xlim12)
        end
        if strcmp(UI.settings.groundTruthData, 'Histogram') && ~isempty(groundTruth_cell_metrics) && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
                if UI.checkbox.logx.Value == 1
                    groundTruthData1.x = linspace(log10(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)])),log10(nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)])),UI.settings.binCount);
                    xdata = log10(groundTruth_cell_metrics.(UI.plot.xTitle));
                else
                    groundTruthData1.x = linspace(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)]),nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)]),UI.settings.binCount);
                    xdata = groundTruth_cell_metrics.(UI.plot.xTitle);
                end
                if UI.checkbox.logy.Value == 1
                    groundTruthData1.y = linspace(log10(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)])),log10(nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)])),UI.settings.binCount);
                    ydata = log10(groundTruth_cell_metrics.(UI.plot.yTitle));
                else
                    groundTruthData1.y = linspace(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)]),nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)]),UI.settings.binCount);
                    ydata = groundTruth_cell_metrics.(UI.plot.yTitle);
                end
                groundTruthData1.x_field = UI.plot.xTitle;
                groundTruthData1.y_field = UI.plot.yTitle;
                groundTruthData1.x_log = UI.checkbox.logx.Value;
                groundTruthData1.y_log = UI.checkbox.logy.Value;
                idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
                clusClas_list = unique(groundTruthData.clusClas(idx));
                line_histograms_X = []; line_histograms_Y = [];
                
                if ~any(isnan(groundTruthData1.y)) || ~any(isinf(groundTruthData1.y))
                    for m = 1:length(clusClas_list)
                        idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
                        line_histograms_X(:,m) = ksdensity(xdata(idx(idx1)),groundTruthData1.x);
                    end
                    if UI.checkbox.logx.Value == 0
                        legendScatter2 = line(groundTruthData1.x,line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
                    else
                        legendScatter2 = line(10.^(groundTruthData1.x),line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
                    end
                    set(legendScatter2, {'color'}, num2cell(clr_groups3,2));
                end
                
                if ~any(isnan(groundTruthData1.y)) || ~any(isinf(groundTruthData1.y))
                    for m = 1:length(clusClas_list)
                        idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
                        line_histograms_Y(:,m) = ksdensity(ydata(idx(idx1)),groundTruthData1.y);
                    end
                    if UI.checkbox.logy.Value == 0
                        legendScatter22 = line(groundTruthData1.y,line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
                    else
                        legendScatter22 = line(10.^(groundTruthData1.y),line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
                    end
                    set(legendScatter22, {'color'}, num2cell(clr_groups3,2));
                end
        end
    if strcmp(UI.settings.referenceData, 'Histogram') && ~isempty(reference_cell_metrics) && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            if UI.checkbox.logx.Value == 1
                AA = reference_cell_metrics.(UI.plot.xTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                BB = cell_metrics.(UI.plot.xTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB) & BB>0);
                referenceData1.x = linspace(log10(nanmin([BB,AA])),log10(nanmax([BB,AA])),UI.settings.binCount);
                xdata = log10(reference_cell_metrics.(UI.plot.xTitle));
            else
                referenceData1.x = linspace(nanmin([cell_metrics.(UI.plot.xTitle),reference_cell_metrics.(UI.plot.xTitle)]),nanmax([cell_metrics.(UI.plot.xTitle),reference_cell_metrics.(UI.plot.xTitle)]),UI.settings.binCount);
                xdata = reference_cell_metrics.(UI.plot.xTitle);
            end
            if UI.checkbox.logy.Value == 1
                AA = reference_cell_metrics.(UI.plot.yTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                BB = cell_metrics.(UI.plot.yTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB) & BB>0);
                referenceData1.y = linspace(log10(nanmin([BB,AA])),log10(nanmax([BB,AA])),UI.settings.binCount);
                ydata = log10(reference_cell_metrics.(UI.plot.yTitle));
            else
                AA = reference_cell_metrics.(UI.plot.yTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA));
                BB = cell_metrics.(UI.plot.yTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB));
                referenceData1.y = linspace(nanmin([BB,AA]),nanmax([BB,AA]),UI.settings.binCount);
                ydata = reference_cell_metrics.(UI.plot.yTitle);
            end
            referenceData1.x_field = UI.plot.xTitle;
            referenceData1.y_field = UI.plot.yTitle;
            referenceData1.x_log = UI.checkbox.logx.Value;
            referenceData1.y_log = UI.checkbox.logy.Value;
            referenceData1.plotType = 'Histogram';
            
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            clusClas_list = unique(referenceData.clusClas(idx));
            line_histograms_X = []; line_histograms_Y = [];
            
            if ~any(isnan(referenceData1.x)) && ~any(isinf(referenceData1.x))
                for m = 1:length(clusClas_list)
                    idx1 = find(referenceData.clusClas(idx)==clusClas_list(m));
                    line_histograms_X(:,m) = ksdensity(xdata(idx(idx1)),referenceData1.x);
                end
                if UI.checkbox.logx.Value == 0
                    legendScatter2 = line(referenceData1.x,line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
                else
                    legendScatter2 = line(10.^(referenceData1.x),line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
                end
                set(legendScatter2, {'color'}, num2cell(clr_groups2,2));
            end
            
            if ~any(isnan(referenceData1.y)) || ~any(isinf(referenceData1.y))
                for m = 1:length(clusClas_list)
                    idx1 = find(referenceData.clusClas(idx)==clusClas_list(m));
                    line_histograms_Y(:,m) = ksdensity(ydata(idx(idx1)),referenceData1.y);
                end
                if UI.checkbox.logy.Value == 0
                    legendScatter22 = line(referenceData1.y,line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
                else
                    legendScatter22 = line(10.^(referenceData1.y),line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
                end
                set(legendScatter22, {'color'}, num2cell(clr_groups2,2));
            end
            xlim(h_scatter(2), xlim11)
            xlim(h_scatter(3), xlim12)
    end
    
    elseif UI.settings.customPlotHistograms == 3
        % 3D plot
        hold on
        subfig_ax(1).YLabel.String = UI.plot.yTitle; subfig_ax(1).YLabel.Interpreter = 'none';
        subfig_ax(1).XLabel.String = UI.plot.xTitle;subfig_ax(1).XLabel.Interpreter = 'none';
        set(subfig_ax(1), 'Clipping','off','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
        xlim auto, ylim auto, zlim auto, axis tight
        % set(subfig_ax(1),'ButtonDownFcn',@ClicktoSelectFromPlot)
%         hZoom = zoom;
%         zoom('off') % cannot change context if zoom on !
%         set(hZoom,'RightClickAction',@ClicktoSelectFromPlot);
%         zoom('on')
        
        % Setting linear/log scale
        if UI.checkbox.logx.Value == 1
            set(subfig_ax(1), 'XScale', 'log')
        else
            set(subfig_ax(1), 'XScale', 'linear')
        end
        if UI.checkbox.logy.Value == 1
            set(subfig_ax(1), 'YScale', 'log')
        else
            set(subfig_ax(1), 'YScale', 'linear')
        end
        
        view([az,el]); axis tight
        if UI.settings.plotZLog == 1
            set(subfig_ax(1), 'ZScale', 'log')
        else
            set(subfig_ax(1), 'ZScale', 'linear')
        end
        
        if UI.settings.logMarkerSize == 1
            markerSize = 10+ceil(rescale_vector(log10(plotMarkerSize(UI.params.subset)))*80*UI.settings.markerSize/15);
        else
            markerSize = 10+ceil(rescale_vector(plotMarkerSize(UI.params.subset))*80*UI.settings.markerSize/15);
        end
        [~, ~,ic] = unique(plotClas(UI.params.subset));

        markerColor = clr_groups(ic,:);
        legendScatter = scatter3(plotX(UI.params.subset), plotY(UI.params.subset), plotZ(UI.params.subset),markerSize,markerColor,'filled', 'HitTest','off','MarkerFaceAlpha',.7);
        if UI.settings.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX(UI.cells.excitatory_subset), plotY(UI.cells.excitatory_subset), plotZ(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX(UI.cells.inhibitory_subset), plotY(UI.cells.inhibitory_subset), plotZ(UI.cells.inhibitory_subset),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX(UI.cells.excitatoryPostsynaptic_subset), plotY(UI.cells.excitatoryPostsynaptic_subset), plotZ(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX(UI.cells.inhibitoryPostsynaptic_subset), plotY(UI.cells.inhibitoryPostsynaptic_subset), plotZ(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color','k','*k', 'HitTest','off')
        end
        % Plotting synaptic projections
        if  plotConnections(1) == 1 && ~isempty(putativeSubset) && UI.settings.plotExcitatoryConnections
            switch UI.monoSyn.disp
                case 'All'
                    xdata = [plotX(UI.params.a1);plotX(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY(UI.params.a1);plotY(UI.params.a2);nan(1,length(UI.params.a2))];
                    zdata = [plotZ(UI.params.a1);plotZ(UI.params.a2);nan(1,length(UI.params.a2))];
                    line(xdata(:),ydata(:),zdata(:),'color','k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX(UI.params.incoming);plotX(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY(UI.params.incoming);plotY(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        zdata = [plotZ(UI.params.incoming);plotZ(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        line(xdata(:),ydata(:),zdata(:),'color','b','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX(UI.params.a1(UI.params.outbound));plotX(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY(UI.params.a1(UI.params.outbound));plotY(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        zdata = [plotZ(UI.params.a1(UI.params.outbound));plotZ(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        line(xdata(:),ydata(:),zdata(:),'color','m','HitTest','off')
                    end
            end
        end
        % Plots putative inhibitory connections
        if plotConnections(1) == 1 && ~isempty(putativeSubset_inh) && UI.settings.plotInhibitoryConnections
            switch UI.monoSyn.disp
                case 'All'
                    xdata = [plotX(UI.params.b1);plotX(UI.params.b2);nan(1,length(UI.params.b2))];
                    ydata = [plotY(UI.params.b1);plotY(UI.params.b2);nan(1,length(UI.params.b2))];
                    zdata = [plotZ(UI.params.b1);plotZ(UI.params.b2);nan(1,length(UI.params.b2))];
                    line(xdata(:),ydata(:),zdata(:),'LineStyle','--','HitTest','off','color',[0.5 0.5 0.5])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound_inh)
                        xdata = [plotX(UI.params.incoming_inh);plotX(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        ydata = [plotY(UI.params.incoming_inh);plotY(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        zdata = [plotZ(UI.params.incoming_inh);plotZ(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        line(xdata(:),ydata(:),zdata(:),'LineStyle','--','color','r','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound_inh)
                        xdata = [plotX(UI.params.b1(UI.params.outbound_inh));plotX(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        ydata = [plotY(UI.params.b1(UI.params.outbound_inh));plotY(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        zdata = [plotZ(UI.params.b1(UI.params.outbound_inh));plotZ(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        line(xdata(:),ydata(:),zdata(:),'LineStyle','--','color','c','HitTest','off')
                    end
            end
        end
        line(plotX(ii), plotY(ii), plotZ(ii),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off')
        line(plotX(ii), plotY(ii), plotZ(ii),'Marker','x','LineStyle','none','color','k', 'LineWidth', 2, 'MarkerSize',20, 'HitTest','off')
        
        subfig_ax(1).ZLabel.String = UI.plot.zTitle;subfig_ax(1).ZLabel.Interpreter = 'none';
        if contains(UI.plot.zTitle,'_num')
            zticks([1:length(groups_ids.(UI.plot.zTitle))]), zticklabels(groups_ids.(UI.plot.zTitle)),ztickangle(65),zlim([0.5,length(groups_ids.(UI.plot.zTitle))+0.5]),
            subfig_ax(1).ZLabel.String = UI.plot.zTitle(1:end-4);subfig_ax(1).ZLabel.Interpreter = 'none';
        end
        
        % Ground truth cell types
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(groupData)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX(idx_groupData), plotY(idx_groupData), plotZ(idx_groupData),'Marker',UI.settings.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.settings.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
        

        % Activating rotation
        rotateFig1

        if contains(UI.plot.xTitle,'_num')
            xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5]),
            subfig_ax(1).XLabel.String(1:end-4) = UI.plot.xTitle;subfig_ax(1).XLabel.Interpreter = 'none';
        end
        if contains(UI.plot.yTitle,'_num')
            yticks([1:length(groups_ids.(UI.plot.yTitle))]), yticklabels(groups_ids.(UI.plot.yTitle)),ytickangle(65),ylim([0.5,length(groups_ids.(UI.plot.yTitle))+0.5]),
            subfig_ax(1).YLabel.String(1:end-4) = UI.plot.yTitle; subfig_ax(1).YLabel.Interpreter = 'none';
            
        end
        [az,el] = view;
        
    elseif UI.settings.customPlotHistograms == 4
        % Rain cloud plot
        
        if ~isempty(clr_groups)
            subfig_ax(1).XLabel.String = UI.plot.xTitle;subfig_ax(1).XLabel.Interpreter = 'none';
            set(subfig_ax(1), 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
            xlim auto, ylim manual, zlim auto
            set(subfig_ax(1),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on, axis tight
            view([0 90]);
            % Setting linear/log scale
            if UI.checkbox.logx.Value == 1
                set(subfig_ax(1), 'XScale', 'log')
            else
                set(subfig_ax(1), 'XScale', 'linear')
            end
            if size(clr_groups,1)>=10
                box_on = 0; % No box plots
            else
                box_on = 1; % No box plots
            end
            counter = 1; % For aligning scatter data
            plotClas_subset = plotClas(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            ids_count = histc(plotClas_subset, ids);
            drops_y_pos = {};
            drops_idx = {};
            ylim([-length(ids_count)/5,1])
            for m = 1:length(unique(plotClas(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                idx = find(plotClas_subset==ids(m));
                if length(temp1)>1
                    if UI.checkbox.logx.Value == 0
                        drops_idx{m} = UI.params.subset(idx((~isnan(plotX(temp1)) & ~isinf(plotX(temp1)))));
                    else
                        drops_idx{m} = UI.params.subset(idx((~isnan(plotX(temp1)) & plotX(temp1) > 0 & ~isinf(plotX(temp1)))));
                    end
                    drops_y_pos{m} = ce_raincloud_plot(plotX(temp1),'randomNumbers',UI.params.randomNumbers(temp1),'box_on',box_on,'box_dodge',1,'line_width',1,'color',clr_groups(m,:),'alpha',0.4,'box_dodge_amount',0.025+(counter-1)*0.21,'dot_dodge_amount',0.13+(counter-1)*0.21,'bxfacecl',clr_groups(m,:),'box_col_match',1,'log_axis',UI.checkbox.logx.Value,'markerSize',UI.settings.markerSize,'normalization',UI.settings.rainCloudNormalization,'norm_value',max(ids_count));
                    counter = counter + 1;
                end
            end
            axis tight
            yticks([]),
            if nanmin(plotX(UI.params.subset)) ~= nanmax(plotX(UI.params.subset)) & UI.checkbox.logx.Value == 0
                xlim([nanmin(plotX(UI.params.subset)),nanmax(plotX(UI.params.subset))])
            elseif nanmin(plotX(UI.params.subset)) ~= nanmax(plotX(UI.params.subset)) & UI.checkbox.logx.Value == 1 && any(plotX>0)
                xlim([nanmin(plotX(intersect(UI.params.subset,find(plotX>0)))),nanmax(plotX(intersect(UI.params.subset,find(plotX>0))))])
            end
            plotStatRelationship(plotX,0.015,UI.checkbox.logx.Value) % Generates KS group statistics
            
            plotY1 = nan(size(plotX));
            if ~isempty([drops_y_pos{:}])
                plotY1([drops_idx{:}]) = [drops_y_pos{:}];
            end
            
            % Plot putative connections
            if plotConnections(1) == 1
                plotPutativeConnections(plotX,plotY1,UI.monoSyn.disp)
            end
            % Plots X marker for selected cell
            plotMarker(plotX(ii),plotY1(ii))
            
            % Plots tagget ground-truth cell types
            plotGroudhTruthCells(plotX, plotY1)
            
            if contains(UI.plot.xTitle,'_num')
                xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5]),
                subfig_ax(1).XLabel.String = UI.plot.xTitle(1:end-4);subfig_ax(1).XLabel.Interpreter = 'none';
            end
        end
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 2
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax2.Visible,'on')

        d = findobj(UI.panel.subfig_ax2,'Type','line');
        delete(d)
        d = findobj(UI.panel.subfig_ax2,'Type','image');
        delete(d)
        d = findobj(UI.panel.subfig_ax2,'Type','text');
        delete(d)
        set(UI.fig,'CurrentAxes',subfig_ax(2))
        set(subfig_ax(2),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
%         delete(UI.panel.subfig_ax2.Children)
%         % Creating new chield
%         subfig_ax(2) = axes('Parent',UI.panel.subfig_ax2);
        
%         set(subfig_ax(2),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        if (strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics))
            set(subfig_ax(2), 'YScale', 'linear');
            yyaxis right
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
        end
        subfig_ax(2).YLabel.String = 'Burst Index (Royer 2012)';
        subfig_ax(2).XLabel.String = ['Trough-to-Peak (',char(181),'s)'];
        set(subfig_ax(2), 'YScale', 'log');
        
        % Reference data
        if strcmp(UI.settings.referenceData, 'Points') && ~isempty(reference_cell_metrics)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            ce_gscatter(reference_cell_metrics.troughToPeak(idx) * 1000, reference_cell_metrics.burstIndex_Royer2012(idx), referenceData.clusClas(idx), clr_groups2,8,'x');
%             legendScatter2 = gscatter(reference_cell_metrics.troughToPeak(idx) * 1000, reference_cell_metrics.burstIndex_Royer2012(idx), referenceData.clusClas(idx), clr_groups2,'x',8,'off');
%             set(legendScatter2,'HitTest','off')
        elseif strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)
            yyaxis left
            set(subfig_ax(2), 'YScale', 'linear');
            referenceData.image = rot90(flip(1-sum(referenceData.z(:,:,:,referenceData.selection),4),2));
            legendScatter2 = image(referenceData.x,log10(referenceData.y),referenceData.image,'HitTest','off', 'PickableParts', 'none');
            set(legendScatter2,'HitTest','off'),set(gca,'YTick',[])
            yyaxis right, hold on
        end
        
        % Ground truth data
        if strcmp(UI.settings.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics)
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            ce_gscatter(groundTruth_cell_metrics.troughToPeak(idx) * 1000, groundTruth_cell_metrics.burstIndex_Royer2012(idx), groundTruthData.clusClas(idx), clr_groups3,8,'x');
%             legendScatter3 = gscatter(groundTruth_cell_metrics.troughToPeak(idx) * 1000, groundTruth_cell_metrics.burstIndex_Royer2012(idx), groundTruthData.clusClas(idx), clr_groups3,'x',8,'off');
%             set(legendScatter3,'HitTest','off')
        elseif strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics)
            yyaxis left
            groundTruthData.image = 1-sum(groundTruthData.z(:,:,:,groundTruthData.selection),4);
            groundTruthData.image = flip(groundTruthData.image,2);
            groundTruthData.image = rot90(groundTruthData.image);
            set(subfig_ax(2), 'YScale', 'linear');
            legendScatter3 = image(groundTruthData.x,log10(groundTruthData.y),groundTruthData.image,'HitTest','off', 'PickableParts', 'none');
            set(legendScatter3,'HitTest','off'),set(gca,'YTick',[])
            yyaxis right, hold on
        end
        
        plotGroupData(cell_metrics.troughToPeak * 1000,cell_metrics.burstIndex_Royer2012,plotConnections(2))
        
        if strcmp(UI.settings.groundTruthData, 'None') && ~strcmp(UI.settings.referenceData, 'None')
            xlim(fig2_axislimit_x_reference), ylim(fig2_axislimit_y_reference)
        elseif ~strcmp(UI.settings.groundTruthData, 'None') && strcmp(UI.settings.referenceData, 'None') && ~isempty(fig2_axislimit_x_groundTruth) && ~isempty(fig2_axislimit_y_groundTruth)
            xlim(fig2_axislimit_x_groundTruth), ylim(fig2_axislimit_y_groundTruth)
        elseif ~strcmp(UI.settings.groundTruthData, 'None') && ~strcmp(UI.settings.referenceData, 'None')
            xlim([min(fig2_axislimit_x_groundTruth(1),fig2_axislimit_x_reference(1)),max(fig2_axislimit_x_groundTruth(2),fig2_axislimit_x_reference(2))]) 
            ylim([min(fig2_axislimit_y_groundTruth(1),fig2_axislimit_y_reference(1)),max(fig2_axislimit_y_groundTruth(2),fig2_axislimit_y_reference(2))])
        else
            xlim(fig2_axislimit_x), ylim(fig2_axislimit_y)
        end
        xlim21 = xlim;
        ylim21 = ylim;
        
        if strcmp(UI.settings.groundTruthData, 'Histogram') && ~isempty(groundTruth_cell_metrics)
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            clusClas_list = unique(groundTruthData.clusClas(idx));
            line_histograms_X = []; line_histograms_Y = [];
            for m = 1:length(clusClas_list)
                idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
                line_histograms_X(:,m) = ksdensity(groundTruth_cell_metrics.troughToPeak(idx(idx1)) * 1000,groundTruthData.x);
                line_histograms_Y(:,m) = ksdensity(log10(groundTruth_cell_metrics.burstIndex_Royer2012(idx(idx1))),groundTruthData.y1);
            end
            yyaxis right, hold on
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
            legendScatter2 = line(groundTruthData.x,10.^(line_histograms_X./max(line_histograms_X)*diff(log10(ylim21))*0.15+log10(ylim21(1))),'LineStyle','-','linewidth',1,'HitTest','off');
%             legendScatter2 = line(groundTruthData.x,log10(ylim21(1))+diff(log10(ylim21))*0.15*line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter2, {'color'}, num2cell(clr_groups3,2));
            legendScatter22 = line(xlim21(1)+100*line_histograms_Y./max(line_histograms_Y),10.^(groundTruthData.y1'*ones(1,length(clusClas_list))),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter22, {'color'}, num2cell(clr_groups3,2));
            xlim(xlim21), ylim((ylim21))
            yyaxis left, hold on
        elseif strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics)
            yyaxis left
            xlim(xlim21), ylim(log10(ylim21))
            yyaxis right
        end
        if strcmp(UI.settings.referenceData, 'Histogram') && ~isempty(reference_cell_metrics)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            clusClas_list = unique(referenceData.clusClas(idx));
            line_histograms_X = []; line_histograms_Y = [];
            for m = 1:length(clusClas_list)
                idx1 = find(referenceData.clusClas(idx)==clusClas_list(m));
                line_histograms_X(:,m) = ksdensity(reference_cell_metrics.troughToPeak(idx(idx1)) * 1000,referenceData.x);
                line_histograms_Y(:,m) = ksdensity(log10(reference_cell_metrics.burstIndex_Royer2012(idx(idx1))),referenceData.y1);
            end
            yyaxis right, hold on
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
            legendScatter2 = line(referenceData.x,10.^(line_histograms_X./max(line_histograms_X)*diff(log10(ylim21))*0.15+log10(ylim21(1))),'LineStyle','-','linewidth',1,'HitTest','off'); 
            set(legendScatter2, {'color'}, num2cell(clr_groups2,2));
            legendScatter22 = line(xlim21(1)+100*line_histograms_Y./max(line_histograms_Y),10.^(referenceData.y1'*ones(1,length(clusClas_list))),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter22, {'color'}, num2cell(clr_groups2,2));
            xlim(xlim21), ylim((ylim21))
            yyaxis left, hold on
        elseif strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)
            yyaxis left
            xlim(xlim21), ylim(log10(ylim21))
            yyaxis right
        end
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax3.Visible,'on')
        delete(subfig_ax(3).Children)
        set(UI.fig,'CurrentAxes',subfig_ax(3))
        set(subfig_ax(3),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        
        % Scatter plot with t-SNE metrics
        xlim(fig3_axislimit_x); ylim(fig3_axislimit_y);
        subfig_ax(3).YLabel.String = 't-SNE';
        subfig_ax(3).XLabel.String = 't-SNE';
        plotGroupData(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',plotConnections(3))
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 4
    % % % % % % % % % % % % % % % % % % % % % %
    delete(subfig_ax(4).Children)
    set(UI.fig,'CurrentAxes',subfig_ax(4))
    set(subfig_ax(4),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(4),'off')
    UI.subsetPlots{1} = customPlot(UI.settings.customPlot{1},ii,general,batchIDs,subfig_ax(4)); 
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 5
    % % % % % % % % % % % % % % % % % % % % % %
    delete(subfig_ax(5).Children)
    set(UI.fig,'CurrentAxes',subfig_ax(5))
    set(subfig_ax(5),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(5),'off')
    UI.subsetPlots{2} = customPlot(UI.settings.customPlot{2},ii,general,batchIDs,subfig_ax(5));
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 6
    % % % % % % % % % % % % % % % % % % % % % %
    delete(subfig_ax(6).Children)
    set(UI.fig,'CurrentAxes',subfig_ax(6))
    set(subfig_ax(6),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(6),'off')
    UI.subsetPlots{3} = customPlot(UI.settings.customPlot{3},ii,general,batchIDs,subfig_ax(6));
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 7
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax7.Visible,'on')
        delete(subfig_ax(7).Children)
        set(UI.fig,'CurrentAxes',subfig_ax(7))
        set(subfig_ax(7),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(7),'off')
        UI.subsetPlots{4} = customPlot(UI.settings.customPlot{4},ii,general,batchIDs,subfig_ax(7));
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 8
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax8.Visible,'on')
        delete(subfig_ax(8).Children)
        set(UI.fig,'CurrentAxes',subfig_ax(8))
        set(subfig_ax(8),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(8),'off')
        UI.subsetPlots{5} = customPlot(UI.settings.customPlot{5},ii,general,batchIDs,subfig_ax(8));
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Subfig 9 
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax9.Visible,'on')
        delete(subfig_ax(9).Children)
        set(UI.fig,'CurrentAxes',subfig_ax(9))
        set(subfig_ax(9),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(subfig_ax(9),'off')
        UI.subsetPlots{6} = customPlot(UI.settings.customPlot{6},ii,general,batchIDs,subfig_ax(9));
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Separate legends in side panel 
    updateLegends
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Response including benchmarking the UI
%     drawnow nocallbacks
    UI.benchmark.String = [num2str(length(UI.params.subset)),'/',num2str(cell_metrics.general.cellCount), ' cells displayed. Processing time: ', num2str(toc(timerVal),3),' sec'];
    
end

    function subsetPlots = customPlot(customPlotSelection,ii,general,batchIDs,plotAxes)
        % Creates all cell specific plots
        subsetPlots = [];
        
        % Determinig the plot color
        if UI.checkbox.compare.Value == 1 || Colorval == 1 ||  UI.checkbox.groups.Value == 1
            col = UI.settings.cellTypeColors(plotClas(ii),:);
        else
            if isnan(clr_groups)
                col = clr_groups;
            else
                temp = find(nanUnique(plotClas(UI.params.subset))==plotClas(ii));
                if temp <= size(clr_groups,1)
                    col = clr_groups(temp,:);
                else
                    col = [0.3,0.3,0.3];
                end
                if isempty(col)
                    col = [0.3,0.3,0.3];
                end
            end
        end
        
        axis tight, hold on
        if any(strcmp(customPlotSelection,customPlotOptions))
            
            subsetPlots = customPlots.(customPlotSelection)(cell_metrics,UI,ii,col);
            
        elseif strcmp(customPlotSelection,'Waveforms (single)')
            
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = ['Voltage (',char(181),'V)'];
            plotAxes.Title.String = customPlotSelection;
            % Single waveform with std
            if isfield(cell_metrics.waveforms,'filt_std')
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.filt{ii}+cell_metrics.waveforms.filt_std{ii},flip(cell_metrics.waveforms.filt{ii}-cell_metrics.waveforms.filt_std{ii})],'black','EdgeColor','none','FaceAlpha',.2,'HitTest','off')
            end
            line(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.filt{ii}, 'color', col,'linewidth',2,'HitTest','off')            
            % Waveform metrics
            if UI.settings.plotWaveformMetrics
                if isfield(cell_metrics,'polarity') && cell_metrics.polarity(ii) > 0
                    filtWaveform = -cell_metrics.waveforms.filt{ii};
                    [temp1,temp2] = max(-filtWaveform);     % Trough to peak. Red
                    [~,temp3] = max(diff(-filtWaveform));   % Derivative. Green
                    [~,temp5] = max(filtWaveform);          % AB-ratio. Blue
                    temp6= min(cell_metrics.waveforms.filt{ii});
                else
                    filtWaveform = cell_metrics.waveforms.filt{ii};
                    temp1 = max(filtWaveform(round(end/2):end)); % Trough to peak
                    [~,temp2] = min(filtWaveform);          % Trough to peak
                    [~,temp3] = min(diff(filtWaveform));    % Derivative
                    [~,temp5] = max(filtWaveform);          % AB-ratio
                    temp6 = max(cell_metrics.waveforms.filt{ii});
                end
                
                plt1(1) = line([cell_metrics.waveforms.time{ii}(temp2),cell_metrics.waveforms.time{ii}(temp2)+cell_metrics.troughToPeak(ii)],[temp1,temp1],'Marker','.','linewidth',2,'color',[1,0.5,0.5,0.5],'HitTest','off');
                plt1(2) = line([cell_metrics.waveforms.time{ii}(temp3),cell_metrics.waveforms.time{ii}(temp3)+cell_metrics.troughtoPeakDerivative(ii)],[cell_metrics.waveforms.filt{ii}(temp3),cell_metrics.waveforms.filt{ii}(temp3)],'Marker','s','linewidth',2,'color',[0.5,1,0.5,0.5],'HitTest','off');
                if cell_metrics.waveforms.time{ii}(temp5)<0
                    plt1(3) = line([cell_metrics.waveforms.time{ii}(temp5),cell_metrics.waveforms.time{ii}(temp5)],[temp6,temp6+cell_metrics.ab_ratio(ii)*temp6],'Marker','.','linewidth',2,'color',[0.5,0.5,1,0.5],'HitTest','off');
                else
                    plt1(3) = line([cell_metrics.waveforms.time{ii}(temp5),cell_metrics.waveforms.time{ii}(temp5)],[temp6,temp6-cell_metrics.ab_ratio(ii)*temp6],'Marker','.','linewidth',2,'color',[0.5,0.5,1,0.5],'HitTest','off');
                end
                text(cell_metrics.waveforms.time{ii}(temp2),temp1,'Trough-to-peak','HorizontalAlignment','left','VerticalAlignment','bottom')
                text(cell_metrics.waveforms.time{ii}(temp3),cell_metrics.waveforms.filt{ii}(temp3),'Trough-to-peak (derivative)','HorizontalAlignment','left','VerticalAlignment','bottom')
                text(cell_metrics.waveforms.time{ii}(temp5),temp6,'AB-ratio','HorizontalAlignment','left','VerticalAlignment','bottom')
            end
            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1);
            end
            if UI.settings.plotInsetACG > 1
                plotInsetACG(ii,col,general,1)
            end
        elseif strcmp(customPlotSelection,'Waveforms (all)')
            % All waveforms (z-scored) colored according to cell type
            plotAxes.XLabel.String = 'Time (ms)';
            
            plotAxes.Title.String = customPlotSelection;
            if UI.settings.zscoreWaveforms == 1
               zscoreWaveforms1 = 'filt_zscored';
               plotAxes.YLabel.String = 'Waveforms (z-scored)';
            else
                zscoreWaveforms1 = 'filt_absolute';
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V)'];
            end
            if UI.settings.showAllWaveforms == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.(zscoreWaveforms1)(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
            end
            
            % selected cell in black
            line(time_waveforms_zscored, cell_metrics.waveforms.(zscoreWaveforms1)(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1);
            end
            if UI.settings.plotInsetACG > 1
                plotInsetACG(ii,col,general,1)
            end
        elseif strcmp(customPlotSelection,'Waveforms (across channels)')
            % All waveforms across channels with largest ampitude colored according to cell type
            if strcmp(UI.settings.waveformsAcrossChannelsAlignment,'Probe layout')
                plotAxes.XLabel.String = ['Time (ms) / Position (',char(181),'m*',num2str(UI.params.chanCoords.x_factor),')'];
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V) / Position (',char(181),'m/',num2str(UI.params.chanCoords.y_factor),')'];
                plotAxes.Title.String = 'Waveforms across channels';
                if isfield(general,'chanCoords')
                    if UI.settings.plotChannelMapAllChannels
                        channels2plot = cell_metrics.waveforms.channels_all{ii};
                    else
                        channels2plot = cell_metrics.waveforms.bestChannels{ii};
                    end
                    xdata = repmat([cell_metrics.waveforms.time_all{ii},nan(1,1)],length(channels2plot),1)' + general.chanCoords.x(channels2plot)'/UI.params.chanCoords.x_factor;
                    ydata = [cell_metrics.waveforms.filt_all{ii}(channels2plot,:),nan(length(channels2plot),1)]' + general.chanCoords.y(channels2plot)'*UI.params.chanCoords.y_factor;
                    line(xdata(:),ydata(:), 'color', col,'linewidth',1,'HitTest','off')
                else
                    text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
                end
            else
                plotAxes.XLabel.String = ['Time (ms)'];
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V)'];
                plotAxes.Title.String = 'Waveforms across channels';
                if isfield(general,'chanCoords')
                    channels2plot = cell_metrics.waveforms.bestChannels{ii};
                    xdata = repmat([cell_metrics.waveforms.time_all{ii},nan(1,1)],length(channels2plot),1)';
                    ydata = [cell_metrics.waveforms.filt_all{ii}(channels2plot,:),nan(length(channels2plot),1)]' - 10*[1:length(channels2plot)]*UI.params.chanCoords.y_factor;
                    line(xdata(:),ydata(:), 'color', col,'linewidth',1,'HitTest','off')
                else
                    text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
                end
            end
            
        elseif strcmp(customPlotSelection,'Trilaterated position')
            % All waveforms across channels with largest ampitude colored according to cell type
            plotAxes.XLabel.String = ['Position (',char(181),'m)'];
            plotAxes.YLabel.String = ['Position (',char(181),'m)'];
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'chanCoords')
                line(general.chanCoords.x,general.chanCoords.y,'Marker','s','color',[0.5 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5],'markersize',5,'HitTest','off','LineStyle','none','linewidth',1.2)
            end
            switch UI.settings.trilatGroupData
                case 'session'
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset1 = UI.params.subset(subset1);
                case 'animal'
                    subset1 = ismember(cell_metrics.animal(UI.params.subset),cell_metrics.animal{ii});
                    subset1 = UI.params.subset(subset1);
                otherwise
                    subset1 = UI.params.subset;
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(k)), subset1);
                line(cell_metrics.trilat_x(set1),cell_metrics.trilat_y(set1),'Marker','.','LineStyle','none', 'color', [clr_groups(k,:),0.2],'markersize',UI.settings.markerSize,'HitTest','off')
            end
%             plot(cell_metrics.trilat_x(ii),cell_metrics.trilat_y(ii),'.', 'color', 'k','markersize',14,'HitTest','off')
            
            % Plots putative connections
            plotPutativeConnections(cell_metrics.trilat_x,cell_metrics.trilat_y,UI.monoSyn.disp)
            
            % Plots X marker for selected cell
            plotMarker(cell_metrics.trilat_x(ii),cell_metrics.trilat_y(ii))
            
            % Plots tagget ground-truth cell types
            plotGroudhTruthCells(cell_metrics.trilat_x, cell_metrics.trilat_y)
            
        elseif strcmp(customPlotSelection,'Waveforms (image)')
            % All waveforms, zscored and shown in a imagesc plot
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            % Sorted according to trough-to-peak
            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(troughToPeakSorted) == ii);
            
            imagesc(time_waveforms_zscored, [1:length(UI.params.subset)], cell_metrics.waveforms.filt_zscored(:,UI.params.subset(troughToPeakSorted))','HitTest','off'),
            colormap(UI.settings.colormap),
            
            % selected cell highlighted in white
            if ~isempty(idx)
                line([time_waveforms_zscored(1),time_waveforms_zscored(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
            end
            ploConnectionsHighlights(time_waveforms_zscored,UI.params.subset(troughToPeakSorted))
            
        elseif strcmp(customPlotSelection,'Raw waveforms (single)')
            % Single waveform with std
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = ['Voltage (',char(181),'V)'];
            plotAxes.Title.String = customPlotSelection;
            if isfield(cell_metrics.waveforms,'raw_std') && ~isempty(cell_metrics.waveforms.raw{ii})
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.raw{ii}+cell_metrics.waveforms.raw_std{ii},flip(cell_metrics.waveforms.raw{ii}-cell_metrics.waveforms.raw_std{ii})],'black','EdgeColor','none','FaceAlpha',.2,'HitTest','off')
                line(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2,'HitTest','off'), grid on
            elseif ~isempty(cell_metrics.waveforms.raw{ii})
                line(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2,'HitTest','off'), grid on
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1);
            end
            
        elseif strcmp(customPlotSelection,'Raw waveforms (all)')
            % All raw waveforms (z-scored) colored according to cell type
            plotAxes.XLabel.String = 'Time (ms)';
            
            plotAxes.Title.String = customPlotSelection;
            if UI.settings.showAllWaveforms == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if UI.settings.zscoreWaveforms == 1
               zscoreWaveforms1 = 'raw_zscored';
               plotAxes.YLabel.String = 'Raw waveforms (z-scored)';
            else
                zscoreWaveforms1 = 'raw_absolute';
                plotAxes.YLabel.String =  ['Raw waveforms (',char(181),'V)'];
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.(zscoreWaveforms1)(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
            end
            % selected cell in black
            line(time_waveforms_zscored, cell_metrics.waveforms.(zscoreWaveforms1)(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1);
            end
            
        elseif strcmp(customPlotSelection,'Waveforms (tSNE)')
            % t-SNE scatter-plot with all waveforms calculated from the z-scored waveforms
            plotAxes.XLabel.String = '';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            ce_gscatter(tSNE_metrics.filtWaveform(UI.params.subset,1), tSNE_metrics.filtWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%             legendScatter4 = gscatter(tSNE_metrics.filtWaveform(UI.params.subset,1), tSNE_metrics.filtWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%             set(legendScatter4,'HitTest','off')
            % selected cell highlighted with black cross
            line(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            line(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'Raw waveforms (tSNE)')
            % t-SNE scatter-plot with all raw waveforms calculated from the z-scored waveforms
            plotAxes.XLabel.String = '';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            ce_gscatter(tSNE_metrics.rawWaveform(UI.params.subset,1), tSNE_metrics.rawWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%             legendScatter4 = gscatter(tSNE_metrics.rawWaveform(UI.params.subset,1), tSNE_metrics.rawWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%             set(legendScatter4,'HitTest','off')
            % selected cell highlighted with black cross
            line(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            line(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'Connectivity graph')
            plotAxes.XLabel.String = '';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = customPlotSelection;

            putativeConnections_subset = all(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset),2);
            putativeConnections_subset = cell_metrics.putativeConnections.excitatory(putativeConnections_subset,:);
            
            putativeConnections_subset_inh = all(ismember(cell_metrics.putativeConnections.inhibitory,UI.params.subset),2);
            putativeConnections_subset_inh = cell_metrics.putativeConnections.inhibitory(putativeConnections_subset_inh,:);
            
            if ~isempty(putativeConnections_subset) || ~isempty(putativeConnections_subset_inh)
            [putativeSubset1,~,Y] = unique([putativeConnections_subset;putativeConnections_subset_inh]);
            
            Y = reshape(Y,size([putativeConnections_subset;putativeConnections_subset_inh]));
            nNodes = length(putativeSubset1);
            A = zeros(nNodes,nNodes);
            for i = 1:size(putativeConnections_subset,1)
                A(Y(i,1),Y(i,2)) = 1;
            end
            for i = size(putativeConnections_subset,1)+1:size(Y,1)
                A(Y(i,1),Y(i,2)) = 2;
            end
            
            connectivityGraph = digraph(A);
            if ~UI.settings.plotExcitatoryConnections
                connectivityGraph = rmedge(connectivityGraph,Y(1:size(putativeConnections_subset,1),1),Y(1:size(putativeConnections_subset,1),2));
            end
            if ~UI.settings.plotInhibitoryConnections
                connectivityGraph = rmedge(connectivityGraph,Y(size(putativeConnections_subset,1)+1:end,1),Y(size(putativeConnections_subset,1)+1:end,2));
            elseif ~isempty(putativeConnections_subset)
                connectivityGraph1 = connectivityGraph;
                connectivityGraph1 = rmedge(connectivityGraph1,Y(1:size(putativeConnections_subset,1),1),Y(1:size(putativeConnections_subset,1),2));
            end
            connectivityGraph_plot = plot(connectivityGraph,'Layout','force','Iterations',15,'MarkerSize',3,'NodeCData',plotClas(putativeSubset1)','EdgeCData',connectivityGraph.Edges.Weight,'HitTest','off','EdgeColor',[0.2 0.2 0.2],'NodeColor','k','NodeLabel',{}); %
            subsetPlots.xaxis = connectivityGraph_plot.XData;
            subsetPlots.yaxis = connectivityGraph_plot.YData;
            subsetPlots.subset = putativeSubset1;
            for k = 1:length(classes2plotSubset)
                highlight(connectivityGraph_plot,find(plotClas(putativeSubset1)==classes2plotSubset(k)),'NodeColor',clr_groups(k,:))
            end
            if UI.settings.plotInhibitoryConnections && ~isempty(putativeConnections_subset)
                highlight(connectivityGraph_plot,connectivityGraph1,'EdgeColor','b')
            end
            axis tight, %title('Connectivity graph')
            set(gca, 'box','off','XTick',[],'YTick',[]) % 'XTickLabel',[], 'YTickLabel',[]
            set(gca,'ButtonDownFcn',@ClicktoSelectFromPlot)
            
            if any(ii == subsetPlots.subset)
                idx = find(ii == subsetPlots.subset);
                line(subsetPlots.xaxis(idx), subsetPlots.yaxis(idx),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
                line(subsetPlots.xaxis(idx), subsetPlots.yaxis(idx),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            end
            
            % Plots putative connections
            if ~isempty(putativeSubset) && UI.settings.plotExcitatoryConnections && ismember(UI.monoSyn.disp,{'Selected','Upstream','Downstream','Up & downstream','All'}) && ~isempty(UI.params.connections)
                C = ismember(subsetPlots.subset,UI.params.connections);
                line(subsetPlots.xaxis(C),subsetPlots.yaxis(C),'Marker','o','LineStyle','none','color','k','HitTest','off')
            end
            
            % Plots putative inhibitory connections
            if  ~isempty(putativeSubset_inh) && UI.settings.plotInhibitoryConnections && ismember(UI.monoSyn.disp,{'Selected','Upstream','Downstream','Up & downstream','All'}) && ~isempty(UI.params.connections_inh)
                C = ismember(subsetPlots.subset,UI.params.connections_inh);
                line(subsetPlots.xaxis(C),subsetPlots.yaxis(C),'Marker','o','LineStyle','none','color','k','HitTest','off')
            end
            else
%                 title('ISI distribution')
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
        elseif strcmp(customPlotSelection,'CCGs (image)')
            % CCGs for selected cell with other cell pairs from the same session. The ACG for the selected cell is shown first
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'ccg') && ~isempty(UI.params.subset)
                if UI.BatchMode
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset1 = cell_metrics.UID(UI.params.subset(subset1));
                else
                    subset1 = UI.params.subset;
                end
                subset1 = [cell_metrics.UID(ii),subset1(subset1~=cell_metrics.UID(ii))];
                Ydata = [1:length(subset1)];
                if strcmp(UI.settings.acgType,'Narrow')
                    Xdata = [-30:30]/2;
                    Zdata = general.ccg(41+30:end-40-30,cell_metrics.UID(ii),subset1)./max(general.ccg(41+30:end-40-30,cell_metrics.UID(ii),subset1));
                else
                    Xdata = [-100:100]/2;
                    Zdata = general.ccg(:,cell_metrics.UID(ii),subset1)./max(general.ccg(:,cell_metrics.UID(ii),subset1));
                end
                imagesc(Xdata,Ydata,permute(Zdata,[3,1,2]),'HitTest','off'),
                line([0,0,],[0.5,length(subset1)+0.5],'color','k','HitTest','off')
                colormap(UI.settings.colormap), axis tight
                
                % Synaptic partners are also displayed
                ploConnectionsHighlights(Xdata,subset1)
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ACGs (single)') % ACGs
            % Auto-correlogram for selected cell. Colored according to cell-type. Normalized firing rate. X-axis according to selected option
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = customPlotSelection;
            if strcmp(UI.settings.acgType,'Normal')
                bar_from_patch([-100:100]'/2, cell_metrics.acg.narrow(:,ii),col)
                xticks([-50:10:50]),xlim([-50,50])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.settings.acgType,'Narrow')
                bar_from_patch([-30:30]'/2, cell_metrics.acg.narrow(41+30:end-40-30,ii),col)
                xticks([-15:5:15]), xlim([-15,15])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.settings.acgType,'Log10') && isfield(general,'acgs') && isfield(general.acgs,'log10')
                if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10') 
                    bar_from_patch(general.isis.log10, cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii),'k')
                end
                bar_from_patch(general.acgs.log10, cell_metrics.acg.log10(:,ii),col)
                set(gca,'xscale','log'),xlim([.001,10])
                plotAxes.XLabel.String = 'Time (sec)';
            else
                bar_from_patch([-500:500]', cell_metrics.acg.wide(:,ii),col)
                xticks([-500:100:500]),xlim([-500,500])
                plotAxes.XLabel.String = 'Time (ms)';
            end
            
            % ACG fit with a triple-exponential
            if plotAcgFit
                a = cell_metrics.acg_tau_decay(ii); b = cell_metrics.acg_tau_rise(ii); c = cell_metrics.acg_c(ii); d = cell_metrics.acg_d(ii);
                e = cell_metrics.acg_asymptote(ii); f = cell_metrics.acg_refrac(ii); g = cell_metrics.acg_tau_burst(ii); h = cell_metrics.acg_h(ii);
                x_fit = 1:0.2:50;
                fiteqn = max(c*(exp(-(x_fit-f)/a)-d*exp(-(x_fit-f)/b))+h*exp(-(x_fit-f)/g)+e,0);
                if strcmp(UI.settings.acgType,'Log10')
                    line([-flip(x_fit),x_fit]/1000,[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7],'HitTest','off')
                    % plot(0.05,fiteqn(246),'ok')
                else
                    line([-flip(x_fit),x_fit],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7],'HitTest','off')
                end
            end
            
            ax5 = axis; grid on, set(gca, 'Layer', 'top')
%             line([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); 
            line([ax5(1) ax5(2)],cell_metrics.firingRate(ii)*[1 1],'LineStyle','--','color','k')
%             ylabel('Rate (Hz)'), title('Autocorrelogram')
            
        elseif strcmp(customPlotSelection,'ISIs (single)') % ISIs
            plotAxes.YLabel.String = 'Cells';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')
                if strcmp(UI.settings.isiNormalization,'Rate')
                    bar_from_patch(general.isis.log10, cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii),'k')
                    bar_from_patch(general.isis.log10, cell_metrics.isi.log10(:,ii),col)
                    xlim([0,10])
                    plotAxes.XLabel.String = 'Time (sec)';
                    plotAxes.YLabel.String = 'Rate (Hz)';
                    
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    bar_from_patch(1./general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^UI.settings.ACGLogIntervals))',col)
                    xlim([0,1000])
                    plotAxes.XLabel.String = 'Instantaneous rate (Hz)';
                    plotAxes.YLabel.String = 'Occurrence';
                else
                    bar_from_patch(general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^UI.settings.ACGLogIntervals))',col)
                    xlim([0,10])
                    plotAxes.XLabel.String = 'Time (sec)';
                    plotAxes.YLabel.String = 'Occurrence';
                end
                set(gca,'xscale','log')
                ax5 = axis; grid on, set(gca, 'Layer', 'top')
%                 title('ISI distribution')
            else
%                 title('ISI distribution')
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ISIs (all)') % ISIs
            plotAxes.Title.String = customPlotSelection;
            if UI.settings.showAllWaveforms == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10') && ~isempty(classes2plotSubset)
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([general.isis.log10',nan(1,1)],length(set1),1)';
                    if strcmp(UI.settings.isiNormalization,'Rate')
                        ydata = [cell_metrics.isi.log10(:,set1);nan(1,length(set1))];
                        xlim1 = [0,10];
                        plotAxes.XLabel.String = 'Time (sec)';
                        plotAxes.YLabel.String = 'Rate (Hz)';
                    elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                        xdata = repmat([1./general.isis.log10',nan(1,1)],length(set1),1)';
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^UI.settings.ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,1000];
                        plotAxes.XLabel.String = 'Instantaneous rate (Hz)';
                    plotAxes.YLabel.String = 'Occurrence';
                    else
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^UI.settings.ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,10];
                        plotAxes.XLabel.String = 'Time (sec)';
                        plotAxes.YLabel.String = 'Occurrence';
                    end
                    line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
                end
                if strcmp(UI.settings.isiNormalization,'Rate')
                    line(general.isis.log10,cell_metrics.isi.log10(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    line(1./general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^UI.settings.ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                else
                    line(general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^UI.settings.ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xlim(xlim1), set(gca,'xscale','log')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
        elseif strcmp(customPlotSelection,'ACGs (all)')
            % All ACGs. Colored by to cell-type.
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = customPlotSelection;
            if UI.settings.showAllWaveforms == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if strcmp(UI.settings.acgType,'Normal')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-100:100]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(:,set1);nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
                end
                line([-100:100]/2,cell_metrics.acg.narrow(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-50:10:50]),xlim([-50,50])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.settings.acgType,'Narrow')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-30:30]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(41+30:end-40-30,set1);nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
                end
                line([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-15:5:15]),xlim([-15,15])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.settings.acgType,'Log10')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([general.acgs.log10',nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.log10(:,set1);nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
                end
                line(general.acgs.log10,cell_metrics.acg.log10(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xlim([0,10]), set(gca,'xscale','log')
                plotAxes.XLabel.String = 'Time (sec)';
            else
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-500:500],nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.wide(:,set1);nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.2],'HitTest','off')
                end
                line([-500:500],cell_metrics.acg.wide(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-500:100:500]),xlim([-500,500])
                plotAxes.XLabel.String = 'Time (ms)';
            end
            
        elseif strcmp(customPlotSelection,'ISIs (image)')
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            
            if strcmp(UI.settings.isiNormalization,'Rate')
                imagesc(log10(general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Time (sec; log10)';
            elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                imagesc(log10(1./general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_occurrence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Firing rate (log10)';
            else
                imagesc(log10(general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_occurrence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Time (sec; log10)';
            end
            if ~isempty(idx)
                if strcmp(UI.settings.isiNormalization,'Firing rates')
                    line(log10(1./general.isis.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                else
                    line(log10(general.isis.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
            end
            colormap(UI.settings.colormap), axis tight
            ploConnectionsHighlights(xlim,UI.params.subset(burstIndexSorted))
            
        elseif strcmp(customPlotSelection,'ACGs (image)')
            % All ACGs shown in an image (z-scored). Sorted by the burst-index from Royer 2012
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            if strcmp(UI.settings.acgType,'Normal')
                imagesc([-100:100]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    line([-50,50],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off')
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.settings.acgType,'Narrow')
                imagesc([-30:30]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(41+30:end-40-30,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    line([-15,15],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off')
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off','linewidth',1.5),
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.settings.acgType,'Log10')
                imagesc(log10(general.acgs.log10)', [1:length(UI.params.subset)], cell_metrics.acg.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    line(log10(general.acgs.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                plotAxes.XLabel.String = 'Time (sec, log10)';
            else
                imagesc([-500:500], [1:length(UI.params.subset)], cell_metrics.acg.wide_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    line([-500,500],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off')
                plotAxes.XLabel.String = 'Time (ms)';
            end
            colormap(UI.settings.colormap), axis tight
            ploConnectionsHighlights(xlim,UI.params.subset(burstIndexSorted))
            
        elseif strcmp(customPlotSelection,'tSNE of narrow ACGs')
            % t-SNE scatter-plot with all ACGs. Calculated from the narrow ACG (-50ms:0.5ms:50ms). Colored by cell-type.
            plotAxes.YLabel.String = '';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            ce_gscatter(tSNE_metrics.acg_narrow(UI.params.subset,1), tSNE_metrics.acg_narrow(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%             legendScatter5 = gscatter(tSNE_metrics.acg_narrow(UI.params.subset,1), tSNE_metrics.acg_narrow(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%             set(legendScatter5,'HitTest','off'), axis tight
            % selected cell highlighted with black cross
            line(tSNE_metrics.acg_narrow(ii,1), tSNE_metrics.acg_narrow(ii,2),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            line(tSNE_metrics.acg_narrow(ii,1), tSNE_metrics.acg_narrow(ii,2),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of wide ACGs')
            % t-SNE scatter-plot with all ACGs. Calculated from the wide ACG (-500ms:1ms:500ms). Colored by cell-type.
            plotAxes.YLabel.String = '';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            if ~isempty(clr_groups)
                ce_gscatter(tSNE_metrics.acg_wide(UI.params.subset,1), tSNE_metrics.acg_wide(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%                 legendScatter5 = gscatter(tSNE_metrics.acg_wide(UI.params.subset,1), tSNE_metrics.acg_wide(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%                 set(legendScatter5,'HitTest','off')
            end
            axis tight
            line(tSNE_metrics.acg_wide(ii,1), tSNE_metrics.acg_wide(ii,2),'Marker','x','LineStyle','none','color','w','LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            line(tSNE_metrics.acg_wide(ii,1), tSNE_metrics.acg_wide(ii,2),'Marker','x','LineStyle','none','color','k','LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of log ACGs')
            % t-SNE scatter-plot with all ACGs. Calculated from the log10 ACG (-500ms:1ms:500ms). Colored by cell-type.
            plotAxes.YLabel.String = '';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            if ~isempty(clr_groups)
                ce_gscatter(tSNE_metrics.acg_log10(UI.params.subset,1), tSNE_metrics.acg_log10(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%                 legendScatter5 = gscatter(tSNE_metrics.acg_log10(UI.params.subset,1), tSNE_metrics.acg_log10(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%                 set(legendScatter5,'HitTest','off')
            end
            axis tight
            line(tSNE_metrics.acg_log10(ii,1), tSNE_metrics.acg_log10(ii,2),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            line(tSNE_metrics.acg_log10(ii,1), tSNE_metrics.acg_log10(ii,2),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of log ISIs')
            % t-SNE scatter-plot with all ISIs. Calculated from the log10
            plotAxes.YLabel.String = '';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            if ~isempty(clr_groups)
                ce_gscatter(tSNE_metrics.isi_log10(UI.params.subset,1), tSNE_metrics.isi_log10(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,20,'.');
%                 legendScatter5 = gscatter(tSNE_metrics.isi_log10(UI.params.subset,1), tSNE_metrics.isi_log10(UI.params.subset,2), plotClas(UI.params.subset), clr_groups,'',20,'off');
%                 set(legendScatter5,'HitTest','off')
            end
            axis tight
            line(tSNE_metrics.isi_log10(ii,1), tSNE_metrics.isi_log10(ii,2),'Marker','x','LineStyle','none','color','w','LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            line(tSNE_metrics.isi_log10(ii,1), tSNE_metrics.isi_log10(ii,2),'Marker','x','LineStyle','none','color','k','LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'firingRateMaps_firingRateMap')
            firingRateMapName = 'firingRateMap';
            % Precalculated firing rate map for the cell
            plotAxes.XLabel.String = 'Position (cm)';
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = firingRateMapName;
            if isfield(cell_metrics.firingRateMaps,firingRateMapName) && size(cell_metrics.firingRateMaps.(firingRateMapName),2)>=ii && ~isempty(cell_metrics.firingRateMaps.(firingRateMapName){ii})
                firingRateMap = cell_metrics.firingRateMaps.(firingRateMapName){ii};
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'x_bins')
                    x_bins = general.firingRateMaps.(firingRateMapName).x_bins(:);
                else
                    x_bins = [1:length(firingRateMap)];
                end
                line(x_bins,firingRateMap,'LineStyle','-','color', 'k','linewidth',2, 'HitTest','off'),
                % Synaptic partners are also displayed
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.firingRateMaps.(firingRateMapName));
                axis tight, ax6 = axis; grid on,
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'boundaries')
                    boundaries = general.firingRateMaps.(firingRateMapName).boundaries;
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,{'firingRateMaps_'})
            firingRateMapName = customPlotSelection(16:end);
            % A state dependent firing rate map
            plotAxes.XLabel.String = 'Position (cm)';
            plotAxes.Title.String = firingRateMapName;
            if isfield(cell_metrics.firingRateMaps,firingRateMapName)  && size(cell_metrics.firingRateMaps.(firingRateMapName),2)>=ii && ~isempty(cell_metrics.firingRateMaps.(firingRateMapName){ii})
                firingRateMap = cell_metrics.firingRateMaps.(firingRateMapName){ii};
                
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'x_bins')
                    x_bins = general.firingRateMaps.(firingRateMapName).x_bins;
                else
                    x_bins = [1:size(firingRateMap,1)];
                end
                if UI.settings.firingRateMap.showHeatmap
                    imagesc(x_bins,1:size(firingRateMap,2),firingRateMap','HitTest','off');
                    if UI.settings.firingRateMap.showHeatmapColorbar
                        colorbar
                    end
                    plotAxes.YLabel.String = '';
                else
                    plt1 = line(x_bins,firingRateMap,'LineStyle','-','linewidth',2, 'HitTest','off');
                    grid on, plotAxes.YLabel.String = 'Rate (Hz)';
                end
                
                axis tight, ax6 = axis;
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName)
                    if UI.settings.firingRateMap.showLegend
                        if UI.settings.firingRateMap.showHeatmap
                            if isfield(general.firingRateMaps.(firingRateMapName),'labels')
                                yticks([1:length(general.firingRateMaps.(firingRateMapName).labels)])
                                yticklabels(general.firingRateMaps.(firingRateMapName).labels)
                            end
                        else
                            if isfield(general.firingRateMaps.(firingRateMapName),'labels')
                                legend(general.firingRateMaps.(firingRateMapName).labels,'Location','northeast','Box','off','AutoUpdate','off')
                            else
                                lgend212 = legend(plt1);
                                set(lgend212,'Location','northeast','Box','off','AutoUpdate','off')
                            end
                        end
                    end
                    if isfield(general.firingRateMaps.(firingRateMapName),'boundaries')
                        boundaries = general.firingRateMaps.(firingRateMapName).boundaries;
                        line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                    end
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,{'psth_'}) && ~contains(customPlotSelection,{'spikes_'})
            eventName = customPlotSelection(6:end);
            plotAxes.XLabel.String = 'Time (s)';
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = eventName;
            if isfield(cell_metrics.psth,eventName) && length(cell_metrics.psth.(eventName))>=ii && ~isempty(cell_metrics.psth.(eventName){ii})
                psth_response = cell_metrics.psth.(eventName){ii};
                
                if isfield(general.psth,eventName) && isfield(general.psth.(eventName),'x_bins')
                    x_bins = general.psth.(eventName).x_bins(:);
                else
                    x_bins = [1:size(psth_response,1)];
                end
                line(x_bins,psth_response,'color', 'k','linewidth',2, 'HitTest','off')
                
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.psth.(eventName));
                
                axis tight, ax6 = axis; grid on
                line([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'boundaries')
                    boundaries = general.psth.(eventName).boundaries;
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'boundaries')
                    boundaries = general.psth.(eventName).boundaries;
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,'events_')
            eventName = customPlotSelection(8:end);
            plotAxes.XLabel.String = 'Time';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = eventName;
            if isfield(cell_metrics.events,eventName) && length(cell_metrics.events.(eventName))>=ii && ~isempty(cell_metrics.events.(eventName){ii})
                rippleCorrelogram = cell_metrics.events.(eventName){ii};
                
                if isfield(general.events,eventName) && isfield(general.events.(eventName),'x_bins')
                    x_bins = general.events.(eventName).x_bins(:);
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.events.(eventName));
                line(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'),
                axis tight, ax6 = axis; grid on
                line([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,'manipulations_')
            eventName = customPlotSelection(15:end);
            plotAxes.XLabel.String = 'Time';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = eventName;
            if isfield(cell_metrics.manipulations,eventName) && numel(cell_metrics.manipulations.(eventName)) >= ii && ~isempty(cell_metrics.manipulations.(eventName){ii})
                rippleCorrelogram = cell_metrics.manipulations.(eventName){ii};
                
                if isfield(general.manipulations,eventName) && isfield(general.manipulations.(eventName),'x_bins')
                    x_bins = general.manipulations.(eventName).x_bins(:);
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.manipulations.(eventName));
                
                line(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off')
                axis tight, ax6 = axis; grid on
                line([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,'RCs_') && ~contains(customPlotSelection,'Phase') && ~contains(customPlotSelection,'(image)') && ~contains(customPlotSelection,'(all)')
            responseCurvesName = customPlotSelection(5:end);
            plotAxes.XLabel.String = 'Time (s)';
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = responseCurvesName;
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                firingRateAcrossTime = cell_metrics.responseCurves.(responseCurvesName){ii};
                if isfield(general.responseCurves,responseCurvesName) && isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    x_bins = general.responseCurves.(responseCurvesName).x_bins;
                else
                    x_bins = [1:length(firingRateAcrossTime)];
                end
                plt1 = line(x_bins,firingRateAcrossTime,'color', 'k','linewidth',2, 'HitTest','off');
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.responseCurves.(responseCurvesName));

                axis tight, ax6 = axis; 
                
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries;
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',1);
                            end
                        end
                        line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                    end
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
        
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'(image)') && ~contains(customPlotSelection,'Phase')
            
            % Firing rates across time for the population
            responseCurvesName = customPlotSelection(5:end-8);
            plotAxes.XLabel.String = 'Time (s)';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = responseCurvesName;
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                if UI.BatchMode
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset222 = UI.params.subset(subset1);
                else
                    subset1 = UI.params.subset;
                    subset222 = UI.params.subset;
                end
                Ydata = [1:length(subset1)];
                if isfield(general.responseCurves,responseCurvesName) && isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    Xdata = general.responseCurves.(responseCurvesName).x_bins;
                else
                    Xdata = [1:length(cell_metrics.responseCurves.(responseCurvesName))];
                end
                [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(subset222));
                Zdata = horzcat(cell_metrics.responseCurves.(responseCurvesName){subset222(troughToPeakSorted)});
                
                imagesc(Xdata,Ydata,(Zdata./max(Zdata))','HitTest','off'),
                [~,idx] = find(subset222(troughToPeakSorted) == ii);
                colormap(UI.settings.colormap), axis tight
                if ~isempty(idx)
                    line([Xdata(1),Xdata(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                
                % Synaptic partners are also displayed
                subset1 = cell_metrics.UID(subset222);
                ploConnectionsHighlights(Xdata,subset1(troughToPeakSorted));
                
                ax6 = axis; 
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries;
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none', 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                            end
                        end
                        line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','w', 'HitTest','off','linewidth',1.5);
                    end
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'(all)') && ~contains(customPlotSelection,'Phase')
            
            % Firing rates across time for the population
            responseCurvesName = customPlotSelection(5:end-6);
            plotAxes.XLabel.String = 'Time (s)';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = responseCurvesName;
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                if UI.BatchMode
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset222 = UI.params.subset(subset1);
                else
                    subset1 = UI.params.subset;
                    subset222 = UI.params.subset;
                end
                if isfield(general.responseCurves,responseCurvesName) && isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    Xdata = general.responseCurves.(responseCurvesName).x_bins;
                else
                    Xdata = [1:length(cell_metrics.responseCurves.(responseCurvesName))];
                end
                Zdata = horzcat(cell_metrics.responseCurves.(responseCurvesName){subset222});
                idx9 = subset222 == ii;
                line(Xdata,Zdata,'HitTest','off'),
                line(Xdata,Zdata(:,idx9),'color', 'k','linewidth',2, 'HitTest','off'),
                axis tight
                subsetPlots.xaxis = Xdata;
                subsetPlots.yaxis = Zdata;
                subsetPlots.subset = subset222;

                ax6 = axis; 
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries;
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none', 'Color', 'k','BackgroundColor',[1 1 1 0.7],'margin',1);
                            end
                        end
                        line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off','linewidth',1.5);
                    end
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'Phase') && ~contains(customPlotSelection,'(image)') && ~contains(customPlotSelection,'(all)')
            responseCurvesName = customPlotSelection(5:end);
            plotAxes.XLabel.String = 'Phase';
            plotAxes.YLabel.String = 'Probability';
            plotAxes.Title.String = responseCurvesName;
            if isfield(cell_metrics.responseCurves,responseCurvesName) && numel(cell_metrics.responseCurves.(responseCurvesName)) >= ii && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                thetaPhaseResponse = cell_metrics.responseCurves.(responseCurvesName){ii};
                if isfield(general.responseCurves,responseCurvesName) & isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    x_bins = general.responseCurves.(responseCurvesName).x_bins;
                else
                    x_bins = [1:length(thetaPhaseResponse)];
                end
                plt1 = line(x_bins,thetaPhaseResponse,'color', 'k','linewidth',2, 'HitTest','off');
                
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.responseCurves.(responseCurvesName));
                axis tight, ax6 = axis; grid on,
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'(image)')
            responseCurvesName = customPlotSelection(5:end-8);
            plotAxes.XLabel.String = 'Phase';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = responseCurvesName;
            % All responseCurves shown in an imagesc plot
            % Sorted according to user input
            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(troughToPeakSorted) == ii);
            
            imagesc(UI.x_bins.thetaPhase, [1:length(UI.params.subset)], cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset(troughToPeakSorted))','HitTest','off'),
            colormap(UI.settings.colormap),
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            % selected cell highlighted in white
            if ~isempty(idx)
                line([UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
            end
            ploConnectionsHighlights(xlim,UI.params.subset(troughToPeakSorted))
            
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'(all)')
            
            responseCurvesName = customPlotSelection(5:end-6);
            plotAxes.XLabel.String = 'Phase';
            plotAxes.YLabel.String = 'z-scored distribution';
            plotAxes.Title.String = responseCurvesName;
            % All responseCurves colored according to cell type
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(k)), UI.params.subset);
                xdata = repmat([UI.x_bins.thetaPhase,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.responseCurves.thetaPhase_zscored(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [clr_groups(k,:),0.5],'HitTest','off')
            end
            % selected cell in black
            line(UI.x_bins.thetaPhase, cell_metrics.responseCurves.thetaPhase_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
        elseif contains(customPlotSelection,{'spikes_'}) && ~isempty(spikesPlots.(customPlotSelection).event)
            
            % Spike raster plots from the raw spike data with event data
            out = CheckSpikes(batchIDs);
            
            if out && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).x) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).y)
                out = CheckEvents(batchIDs,spikesPlots.(customPlotSelection).event,spikesPlots.(customPlotSelection).eventType);
                
                if out && ~isempty(spikesPlots.(customPlotSelection).event) && isfield(spikes{batchIDs},'times')% && ~isempty(nanUnique(spikes{batchIDs}.(spikesPlots.(customPlotSelection).event){cell_metrics.UID(ii)}))
                    % Event data
                    secbefore = spikesPlots.(customPlotSelection).eventSecBefore;
                    secafter = spikesPlots.(customPlotSelection).eventSecAfter;
                    switch spikesPlots.(customPlotSelection).eventAlignment
                        case 'onset'
                            ts_onset = events.(spikesPlots.(customPlotSelection).event){batchIDs}.timestamps(:,1);
                        case 'offset'
                            ts_onset = events.(spikesPlots.(customPlotSelection).event){batchIDs}.timestamps(:,2);
                        case 'center'
                            ts_onset = mean(events.(spikesPlots.(customPlotSelection).event){batchIDs}.timestamps,2);
                        case 'peak'
                            ts_onset = events.(spikesPlots.(customPlotSelection).event){batchIDs}.peaks;
                    end
                    switch spikesPlots.(customPlotSelection).eventSorting
                        case 'none'
                            idxOrder = 1:length(ts_onset);
                        case 'time'
                            [ts_onset,idxOrder] = sort(ts_onset);
                        case 'amplitude'
                            if isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'amplitude')
                                [~,idxOrder] = sort(events.(spikesPlots.(customPlotSelection).event){batchIDs}.amplitude);
                                ts_onset = ts_onset(idxOrder);
                            end
                        case 'eventID'
                            if isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'eventID')
                                [~,idxOrder] = sort(events.(spikesPlots.(customPlotSelection).event){batchIDs}.eventID);
                                ts_onset = ts_onset(idxOrder);
                            end
                        case 'duration'
                            if isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'duration')
                                [~,idxOrder] = sort(events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration);
                                ts_onset = ts_onset(idxOrder);
                            elseif isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'timestamps')
                                events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration = diff(events.(spikesPlots.(customPlotSelection).event){batchIDs}.timestamps')';
                                [~,idxOrder] = sort(events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration);
                                ts_onset = ts_onset(idxOrder);
                            end
                    end
                    ep = [ts_onset-secbefore, ts_onset+secafter];
                    spks = spikes{batchIDs}.times{cell_metrics.UID(ii)};
                    adjustedSpikes = cellfun(@(x,y) spks(spks>x(1) & spks<x(2))-y,num2cell(ep,2),num2cell(ts_onset), 'uni',0);
                    if ~isempty(spikesPlots.(customPlotSelection).state) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state)
                        spksStates = spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)};
                        adjustedSpikesStates = cellfun(@(x) spksStates(spks>x(1) & spks<x(2)),num2cell(ep,2), 'uni',0);
                    end
                    if spikesPlots.(customPlotSelection).plotRaster
                        % Raster plot with events on y-axis
                        spikeEvent = cellfun(@(x,y) ones(length(x),1).*y, adjustedSpikes, num2cell(1:length(adjustedSpikes))', 'uni',0);
                        if ~isempty(spikesPlots.(customPlotSelection).state)
                            line(vertcat(adjustedSpikes{:}),vertcat(spikeEvent{:}),'Marker','.','LineStyle','none','color', [0.5 0.5 0.5])
                            if isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state)
                                data_x = vertcat(adjustedSpikes{:});
                                data_y = vertcat(spikeEvent{:});
                                data_g = vertcat(adjustedSpikesStates{:});
                                gscatter(data_x(~isnan(data_g)),data_y(~isnan(data_g)), data_g(~isnan(data_g)),[],'',8,'off');
                            end
                        else
                            line(vertcat(adjustedSpikes{:}),vertcat(spikeEvent{:}),'Marker','.','LineStyle','none','color', col)
                        end
                    end
                    grid on, line([0, 0], [0 length(ts_onset)],'color','k', 'HitTest','off');
                    if spikesPlots.(customPlotSelection).plotAverage
                        % Average plot (histogram) for events
                        bin_duration = (secbefore + secafter)/plotAverage_nbins;
                        bin_times = -secbefore:bin_duration:secafter;
                        bin_times2 = bin_times(1:end-1) + mean(diff(bin_times))/2;
                        spkhist = histcounts(vertcat(adjustedSpikes{:}),bin_times);
                        plotData = spkhist/(bin_duration*length(ts_onset));
                        if spikesPlots.(customPlotSelection).plotRaster
                            scalingFactor = (0.2*length(ts_onset)/max(plotData));
                            line([-secbefore,secafter],[0,0],'color','k'), text(secafter,0,[num2str(max(plotData),3),'Hz'],'HorizontalAlignment','right','VerticalAlignment','top','Interpreter', 'none')
                            line(bin_times2,plotData*scalingFactor-(max(plotData)*scalingFactor),'color', col,'linewidth',2);
                        else
                            line(bin_times2,plotData,'color', col,'linewidth',2);
                        end
                        if spikesPlots.(customPlotSelection).plotAmplitude && isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'amplitude')
                            temp = events.(spikesPlots.(customPlotSelection).event){batchIDs}.amplitude(idxOrder);
                            temp2 = find(temp>0);
                            line(secafter+temp(temp2)/max(temp(temp2))*(secbefore+secafter)/6,temp2,'Marker','.','LineStyle','none','color','k')
                            text(secafter+(secbefore+secafter)/6,0,'Amplitude','color','k','HorizontalAlignment','left','VerticalAlignment','bottom','rotation',90,'Interpreter', 'none')
                            line([0, secafter+(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                            line([secafter, secafter], [0 length(ts_onset)],'color','k', 'HitTest','off');
                        end
                        if spikesPlots.(customPlotSelection).plotDuration && isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'duration')
                            temp = events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration(idxOrder);
                            temp2 = find(temp>0);
                            line(secafter+temp(temp2)/max(temp(temp2))*(secbefore+secafter)/6,temp2,'Marker','.','LineStyle','none','color','r')
                            duration = events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration;
                            text(secafter+(secbefore+secafter)/6,0,['Duration (' num2str(min(duration)),' => ',num2str(max(duration)),' sec)'],'color','r','HorizontalAlignment','left','VerticalAlignment','top','rotation',90,'Interpreter', 'none')
                            line([0, secafter+(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                            line([secafter, secafter], [0 length(ts_onset)],'color','k', 'HitTest','off');
                        end
                        if spikesPlots.(customPlotSelection).plotCount && isfield(spikesPlots.(customPlotSelection),'plotCount')
                            count = histcounts(vertcat(spikeEvent{:}),[0:length(spikeEvent)]+0.5);
                            line(-secbefore-count/max(count)*(secbefore+secafter)/6,[1:length(spikeEvent)],'Marker','.','LineStyle','none','color','b')
                            text(-secbefore-(secbefore+secafter)/6,0,['Count (' num2str(min(count)),' => ',num2str(max(count)),' count)'],'color','b','HorizontalAlignment','left','VerticalAlignment','top','rotation',90,'Interpreter', 'none')
                            line([0, -secbefore-(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                        end
                        line([0, 0], [0 -0.2*length(ts_onset)],'color','k', 'HitTest','off');
                    end
                    axis tight
                else
                    text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            xlabel([spikesPlots.(customPlotSelection).x_label, ' (by ',spikesPlots.(customPlotSelection).eventAlignment,')']), ylabel([spikesPlots.(customPlotSelection).y_label,' (by ' spikesPlots.(customPlotSelection).eventSorting,')']), title(customPlotSelection,'Interpreter', 'none')
            
        elseif contains(customPlotSelection,{'spikes_'}) && ~isempty(spikesPlots.(customPlotSelection).state) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state) && ~isempty(nanUnique(spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)}))
            
            % Spike raster plots from the raw spike data with states
            out = CheckSpikes(batchIDs);
            
            if out && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).x) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).y)
                % State dependent raster
                if isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state)
                    line(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)},'Marker','.','LineStyle','none','color', [0.5 0.5 0.5]),
                    if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                        line(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi,'Marker','.','LineStyle','none','color', [0.5 0.5 0.5])
                    end
                    legendScatter = gscatter(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}, spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)},[],'',8,'off'); %,
                    
                    if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                        gscatter(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi, spikes{batchIDs}.(spikesPlots.(customPlotSelection).state){cell_metrics.UID(ii)},[],'',8,'off'); %,
                        yticks([-pi,0,pi,2*pi,3*pi]),yticklabels({'-\pi','0','\pi','2\pi','3\pi'}),ylim([-pi,3*pi])
                    end
                    if ~isempty(UI.params.subset) && UI.settings.dispLegend == 1
                        legend(legendScatter, {},'Location','northeast','Box','off','AutoUpdate','off');
                    end
                    axis tight
                else
                    text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            xlabel(spikesPlots.(customPlotSelection).x_label), ylabel(spikesPlots.(customPlotSelection).y_label), title(customPlotSelection,'Interpreter', 'none')
            
        elseif contains(customPlotSelection,{'spikes_'})
            
            % Spike raster plots from the raw spike data
            out = CheckSpikes(batchIDs);
            
            if out && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).x) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).y)
                if ~isempty(spikesPlots.(customPlotSelection).filter) && ~strcmp(spikesPlots.(customPlotSelection).filterType,'none') && ~isempty(spikesPlots.(customPlotSelection).filterValue)
                    switch spikesPlots.(customPlotSelection).filterType
                        case 'equal to'
                            idx_filter = find(spikes{batchIDs}.(spikesPlots.(customPlotSelection).filter){cell_metrics.UID(ii)} == spikesPlots.(customPlotSelection).filterValue);
                        case 'less than'
                            idx_filter = find(spikes{batchIDs}.(spikesPlots.(customPlotSelection).filter){cell_metrics.UID(ii)} < spikesPlots.(customPlotSelection).filterValue);
                        case 'greater than'
                            idx_filter = find(spikes{batchIDs}.(spikesPlots.(customPlotSelection).filter){cell_metrics.UID(ii)} > spikesPlots.(customPlotSelection).filterValue);
                    end
                else
                    idx_filter = 1:length(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)});
                end
                line(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)}(idx_filter),spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}(idx_filter),'Marker','.','LineStyle','none','color', col)
                
                if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                    line(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)}(idx_filter),spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}(idx_filter)+2*pi,'Marker','.','LineStyle','none','color', col)
                    yticks([-pi,0,pi,2*pi,3*pi]),yticklabels({'-\pi','0','\pi','2\pi','3\pi'}),ylim([-pi,3*pi]), grid on
                end
                axis tight
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            xlabel(spikesPlots.(customPlotSelection).x_label), ylabel(spikesPlots.(customPlotSelection).y_label), title(customPlotSelection,'Interpreter', 'none')
            
        else
            customCellPlotNum = find(strcmp(customPlotSelection, plotOptions));
            plotData = cell_metrics.(plotOptions{customCellPlotNum});
            plotAxes.XLabel.String = '';
            plotAxes.YLabel.String = '';
            plotAxes.Title.String = plotOptions{customCellPlotNum};
            if isnumeric(plotData)
                plotData = plotData(:,ii);
            else
                plotData = plotData{ii};
            end
            if isfield(general,customPlotSelection) && isfield(general.(customPlotSelection),'x_bins')
                x_bins = general.(customPlotSelection).x_bins;
            else
                x_bins = [1:length(plotData)];
            end
            line(x_bins,plotData,'color', 'k','linewidth',2, 'HitTest','off')
            subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.(plotOptions{customCellPlotNum}));
            axis tight, ax6 = axis; grid on
            line([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
            if isfield(general,customPlotSelection)
                if isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    if isfield(general.(customPlotSelection),'boundaries_labels')
                        boundaries_labels = general.(customPlotSelection).boundaries_labels;
                        text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',1);
                    end
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
            end
        end
        
        function subsetPlots = plotConnectionsCurves(x_bins,ydata)
            subsetPlots.xaxis = x_bins;
            subsetPlots.yaxis = [];
            subsetPlots.subset = [];
            if ~isempty(putativeSubset) && UI.settings.plotExcitatoryConnections
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        % subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = [subsetPlots.yaxis,horzcat(ydata{[UI.params.outgoing;UI.params.incoming]})];
                        subsetPlots.subset = [subsetPlots.subset;[UI.params.outgoing;UI.params.incoming]];
                        if ~isempty(UI.params.outbound) && ~isempty(UI.params.outgoing)
                            line(x_bins,horzcat(ydata{UI.params.outgoing}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(UI.params.inbound) && ~isempty(UI.params.incoming)
                            line(x_bins,horzcat(ydata{UI.params.incoming}),'color', 'b', 'HitTest','off')
                        end
                end
            end
            if ~isempty(putativeSubset_inh) &&  UI.settings.plotInhibitoryConnections
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        % subsetPlots.xaxis_inh = x_bins;
                        subsetPlots.yaxis = [subsetPlots.yaxis,horzcat(ydata{[UI.params.outgoing_inh;UI.params.incoming_inh]})];
                        subsetPlots.subset = [subsetPlots.subset;[UI.params.outgoing_inh;UI.params.incoming_inh]];
                        if ~isempty(UI.params.outbound_inh) && ~isempty(UI.params.outgoing_inh)
                            line(x_bins,horzcat(ydata{UI.params.outgoing_inh}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(UI.params.inbound_inh) && ~isempty(UI.params.incoming_inh)
                            line(x_bins,horzcat(ydata{UI.params.incoming_inh}),'color', 'b', 'HitTest','off')
                        end
                end
            end
        end
        
        function ploConnectionsHighlights(Xdata,subset1)
            x_range = Xdata(end)-Xdata(1);
            x1 = (Xdata(1)-0.015*x_range);
            if UI.settings.plotExcitatoryConnections
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(UI.params.outbound) && any(ismember(subset1,(UI.params.outgoing)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.outgoing));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','m','HitTest','off', 'MarkerSize',12)
                        end
                        if ~isempty(UI.params.inbound) && any(ismember(subset1,(UI.params.inbound)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.incoming));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','b','HitTest','off', 'MarkerSize',12)
                        end
                        xlim([Xdata(1)-x_range*0.025,Xdata(end)])
                end
            end
            if UI.settings.plotInhibitoryConnections
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(UI.params.outbound_inh) && any(ismember(subset1,(UI.params.outbound_inh)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.outgoing_inh));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','c','HitTest','off', 'MarkerSize',12)
                        end
                        if ~isempty(UI.params.inbound_inh) && any(ismember(subset1,(UI.params.inbound_inh)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.incoming_inh));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','r','HitTest','off', 'MarkerSize',12)
                        end
                        xlim([Xdata(1)-x_range*0.025,Xdata(end)])
                end
            end
        end
    end

    function plotGroudhTruthCells(plotX1,plotY1)
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(groupData)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX1(idx_groupData), plotY1(idx_groupData),'Marker',UI.settings.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.settings.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
    end
    function handle_ce_gscatter = ce_gscatter(plotX,plotY1,plotClas,clr_groups,markerSize,markerType)
        uniqueGroups = unique(plotClas);
        for i_groups = 1:size(clr_groups,1)
            idx = plotClas == uniqueGroups(i_groups);
            handle_ce_gscatter(i_groups) = line(plotX(idx), plotY1(idx),'Marker',markerType,'LineStyle','none','color',clr_groups(i_groups,:), 'MarkerSize',markerSize,'HitTest','off');
        end
    end
    
    function plotGroupData(plotX1,plotY1,plotConnections1)
        if ~isempty(clr_groups)
            ce_gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), plotClas(UI.params.subset), clr_groups,UI.settings.markerSize,'.');
        end
        if UI.settings.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX1(UI.cells.excitatory_subset), plotY1(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color','k','HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX1(UI.cells.inhibitory_subset), plotY1(UI.cells.inhibitory_subset),'Marker','s','LineStyle','none','color','k','HitTest','off')
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX1(UI.cells.excitatoryPostsynaptic_subset), plotY1(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color','k','HitTest','off')
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX1(UI.cells.inhibitoryPostsynaptic_subset), plotY1(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color','k','HitTest','off')
        end
        
        % Plots putative connections
        if plotConnections1 == 1 && ~isempty(putativeSubset) && UI.settings.plotExcitatoryConnections
            switch UI.monoSyn.disp
                case 'All'
                    xdata = [plotX1(UI.params.a1);plotX1(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY1(UI.params.a1);plotY1(UI.params.a2);nan(1,length(UI.params.a2))];
                    line(xdata(:),ydata(:),'LineStyle','-','HitTest','off','color',[0 0 0 0.3])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX1(UI.params.incoming);plotX1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY1(UI.params.incoming);plotY1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        line(xdata,ydata,'LineStyle','-','HitTest','off','color','b')
%                         scatter(xdata(:),ydata(:),UI.settings.markerSize,'b','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX1(UI.params.a1(UI.params.outbound));plotX1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY1(UI.params.a1(UI.params.outbound));plotY1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        line(xdata(:),ydata(:),'LineStyle','-','HitTest','off','color','m')
%                         scatter(xdata(:),ydata(:),UI.settings.markerSize,'m','HitTest','off')
                    end
            end
        end
        
        % Plots putative inhibitory connections
        if plotConnections1 == 1 && ~isempty(putativeSubset_inh) && UI.settings.plotInhibitoryConnections
            switch UI.monoSyn.disp
                case 'All'
                    xdata_inh = [plotX1(UI.params.b1);plotX1(UI.params.b2);nan(1,length(UI.params.b2))];
                    ydata_inh = [plotY1(UI.params.b1);plotY1(UI.params.b2);nan(1,length(UI.params.b2))];
                    line(xdata_inh(:),ydata_inh(:),'LineStyle','--','HitTest','off','color',[0.5 0.5 1 0.3])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound_inh)
                        xdata_inh = [plotX1(UI.params.incoming_inh);plotX1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        ydata_inh = [plotY1(UI.params.incoming_inh);plotY1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        line(xdata_inh,ydata_inh,'LineStyle','--','color','r','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound_inh)
                        xdata_inh = [plotX1(UI.params.b1(UI.params.outbound_inh));plotX1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        ydata_inh = [plotY1(UI.params.b1(UI.params.outbound_inh));plotY1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        line(xdata_inh(:),ydata_inh(:),'LineStyle','--','color','c','HitTest','off')
                    end
            end
        end
        
        % Plots X marker for selected cell
        line(plotX1(ii), plotY1(ii),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        line(plotX1(ii), plotY1(ii),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
        
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(groupData)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX1(idx_groupData), plotY1(idx_groupData),'Marker',UI.settings.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.settings.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
        
        % Plots sticky selection
        if UI.settings.stickySelection
            line(plotX1(UI.params.ClickedCells),plotY1(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
        end
    end

    function plotGroupScatter(plotX1,plotY1)
        if ~isempty(clr_groups)
            ce_gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), plotClas(UI.params.subset), clr_groups,UI.settings.markerSize,'.');
        end
        if UI.settings.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX1(UI.cells.excitatory_subset), plotY1(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX1(UI.cells.inhibitory_subset), plotY1(UI.cells.inhibitory_subset),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX1(UI.cells.excitatoryPostsynaptic_subset), plotY1(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color','k', 'HitTest','off')
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX1(UI.cells.inhibitoryPostsynaptic_subset), plotY1(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color','k', 'HitTest','off')
        end
    end

    function plotMarker(plotX1,plotY1)
        line(plotX1, plotY1,'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        line(plotX1, plotY1,'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
    end

    function plotPutativeConnections(plotX1,plotY1,monoSynDisp)
        % Plots putative excitatory connections
        if ~isempty(putativeSubset) && UI.settings.plotExcitatoryConnections
            switch monoSynDisp
                case 'All'
                    xdata = [plotX1(UI.params.a1);plotX1(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY1(UI.params.a1);plotY1(UI.params.a2);nan(1,length(UI.params.a2))];
                    line(xdata(:),ydata(:),'color','k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX1(UI.params.incoming);plotX1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY1(UI.params.incoming);plotY1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        line(xdata,ydata,'color','b','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX1(UI.params.a1(UI.params.outbound));plotX1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY1(UI.params.a1(UI.params.outbound));plotY1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        line(xdata(:),ydata(:),'color','m','HitTest','off')
                    end
            end
        end
        % Plots putative inhibitory connections
        if ~isempty(putativeSubset_inh) && UI.settings.plotInhibitoryConnections
            switch monoSynDisp
                case 'All'
                    xdata_inh = [plotX1(UI.params.b1);plotX1(UI.params.b2);nan(1,length(UI.params.b2))];
                    ydata_inh = [plotY1(UI.params.b1);plotY1(UI.params.b2);nan(1,length(UI.params.b2))];
                    line(xdata_inh(:),ydata_inh(:),'LineStyle','--','HitTest','off','color',[0.5 0.5 0.5])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound_inh)
                        xdata_inh = [plotX1(UI.params.incoming_inh);plotX1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        ydata_inh = [plotY1(UI.params.incoming_inh);plotY1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        line(xdata_inh,ydata_inh,'LineStyle','--','color','r','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound_inh)
                        xdata_inh = [plotX1(UI.params.b1(UI.params.outbound_inh));plotX1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        ydata_inh = [plotY1(UI.params.b1(UI.params.outbound_inh));plotY1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        line(xdata_inh(:),ydata_inh(:),'LineStyle','--','color','c','HitTest','off')
                    end
            end
        end
    end

    function out = plotInsetChannelMap(cellID,col,general,plots)
        % Displays a map of the channel configuration and highlights current cell
        padding = 0.03;
        if plots
            xlim1 = xlim;
            ylim1 = ylim;
        else
            axnum = getAxisBelowCursor;
            if isempty(axnum) || isempty(UI.zoom.global{axnum})
                xlim1 = xlim;
                ylim1 = ylim;
            else
                globalZoom = UI.zoom.global{axnum};
                xlim1 = globalZoom(1,:);
                ylim1 = globalZoom(2,:);
            end
        end
        xlim2 = diff(xlim1);
        ylim2 = diff(ylim1);

        chanCoords_ratio = range(general.chanCoords.y)/range(general.chanCoords.x);
        if chanCoords_ratio<1
            chan_width = 0.30;
            chan_height = 0.15;
        else
            chan_height = 0.35;
            chan_width = 0.20;
        end
        if UI.BatchMode
            cellIds = intersect(find(cell_metrics.batchIDs == cell_metrics.batchIDs(cellID)),UI.params.subset);
        else
            cellIds = UI.params.subset;
        end
        chanCoords = reallign(general.chanCoords.x,general.chanCoords.y);
        out = [chanCoords.x1(cellIds);chanCoords.y1(cellIds);cellIds];
        if plots
            line(chanCoords.x,chanCoords.y,'Marker','.','LineStyle','none','color','k','markersize',4,'HitTest','off')
            line(chanCoords.x1(cellIds),chanCoords.y1(cellIds),'Marker','.','LineStyle','none','color',[0.5 0.5 0.5],'markersize',10,'HitTest','off')
            plotPutativeConnections(chanCoords.x1,chanCoords.y1,'Selected')
            line(chanCoords.x1(cellID),chanCoords.y1(cellID),'Marker','.','LineStyle','none','color',col,'markersize',17,'HitTest','off')
        end
        
        function chanCoords = reallign(chanCoords_x,chanCoords_y)
            chanCoords.x = rescale_vector2(chanCoords_x,chanCoords_x) * xlim2 * chan_width + xlim1(1) + xlim2*(1-chan_width-padding);
            chanCoords.y = rescale_vector2(chanCoords_y,chanCoords_y) * ylim2 * chan_height + ylim1(1) + ylim2*padding;
            if isfield(cell_metrics,'trilat_x') &&  UI.settings.plotInsetChannelMap > 2
                chanCoords.x1 = rescale_vector2(cell_metrics.trilat_x,chanCoords_x) * xlim2 * chan_width + xlim1(1) + xlim2*(1-chan_width-padding);
                chanCoords.y1 = rescale_vector2(cell_metrics.trilat_y,chanCoords_y) * ylim2 * chan_height + ylim1(1) + ylim2*padding;
            else
                chanCoords.x1 = nan(size(cell_metrics.maxWaveformCh1));
                chanCoords.y1 = nan(size(cell_metrics.maxWaveformCh1));
                chanCoords.x1(cellIds) = chanCoords.x(cell_metrics.maxWaveformCh1(cellIds))';
                chanCoords.y1(cellIds) = chanCoords.y(cell_metrics.maxWaveformCh1(cellIds))';
            end
        end
    end

    function out = plotInsetACG(cellID,col,general,plots)
        % Displays a map of the channel configuration and highlights current cell
        padding = 0.03;
        
        if plots
            xlim1 = xlim;
            ylim1 = ylim;
        else
            axnum = getAxisBelowCursor;
            if isempty(axnum) || isempty(UI.zoom.global{axnum})
                xlim1 = xlim;
                ylim1 = ylim;
            else
                globalZoom = UI.zoom.global{axnum};
                xlim1 = globalZoom(1,:);
                ylim1 = globalZoom(2,:);
            end
        end
        xlim2 = diff(xlim1);
        ylim2 = diff(ylim1);

        chan_width = 0.30;
        chan_height = 0.15;
        
        if strcmp(UI.settings.acgType,'Normal')
            chanCoords = reallign([-100:100]', normalize_range(cell_metrics.acg.narrow(:,cellID)));
        elseif strcmp(UI.settings.acgType,'Narrow')
            chanCoords = reallign([-30:30]', normalize_range(cell_metrics.acg.narrow(71:71+60,cellID)));
        elseif strcmp(UI.settings.acgType,'Log10') && isfield(general,'acgs') && isfield(general.acgs,'log10')
            chanCoords = reallign(log10(general.acgs.log10), normalize_range(cell_metrics.acg.log10(:,cellID)));
        else
            chanCoords = reallign([-500:500]', normalize_range(cell_metrics.acg.wide(:,cellID)));
        end
        bar_from_patch2(chanCoords.x, chanCoords.y,col,ylim1(1) + ylim2*padding)
        function chanCoords = reallign(chanCoords_x,chanCoords_y)
            chanCoords.x = rescale_vector2(chanCoords_x,chanCoords_x) * xlim2 * chan_width + xlim1(1) + xlim2*padding;
            chanCoords.y = rescale_vector2(chanCoords_y,chanCoords_y) * ylim2 * chan_height + ylim1(1) + ylim2*padding;
        end
    end

    function norm_data = rescale_vector(bla)
        norm_data = (bla - min(bla)) / ( max(bla) - min(bla) );
    end

    function norm_data = rescale_vector2(bla,blb)
        norm_data = (bla - min(blb)) / ( max(blb) - min(blb) );
    end

    function loadFromFile(~,~)
        [file,path] = uigetfile('*.mat','Please select a cell_metrics.mat file','.cell_metrics.cellinfo.mat');
        if ~isequal(file,0)
            cd(path)
            load(file);
            cell_metrics.general.path = path;
            temp = strsplit(file,'.');
            if length(temp)==4
                cell_metrics.general.saveAs = temp{end-2};
            else
                cell_metrics.general.filename = file;
            end
            try
                initializeSession;
            catch
                if isfield(UI,'panel')
                    MsgLog(['Error loading cell metrics:' path, file],2)
                else
                    disp(['Error loading cell metrics:' path, file]);
                end
                return
            end
            uiresume(UI.fig);
            if isfield(UI,'panel')
                MsgLog('Session loaded succesful',2)
            else
                disp(['Session loaded succesful']);
            end
        end
    end

    function highlightExcitatoryCells(~,~)
        % Highlight excitatory cells
        UI.settings.displayExcitatory = ~UI.settings.displayExcitatory;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.settings.displayExcitatory
            UI.menu.monoSyn.highlightExcitatory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightExcitatory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightInhibitoryCells(~,~)
        % Highlight inhibitory cells
        UI.settings.displayInhibitory = ~UI.settings.displayInhibitory;
        MsgLog(['Toggle highlighting inhibitory cells (circles), Count: ', num2str(length(UI.cells.inhibitory))])
        if UI.settings.displayInhibitory
            UI.menu.monoSyn.highlightInhibitory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightInhibitory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightExcitatoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.settings.displayExcitatoryPostsynapticCells = ~UI.settings.displayExcitatoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.settings.displayExcitatoryPostsynapticCells
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'on';
        else
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightInhibitoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.settings.displayInhibitoryPostsynapticCells = ~UI.settings.displayInhibitoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (diamonds). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.settings.displayInhibitoryPostsynapticCells
            UI.menu.monoSyn.inhibitoryPostsynapticCells.Checked = 'on';
        else
            UI.menu.monoSyn.inhibitoryPostsynapticCells.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function reloadCellMetrics(~,~)
        answer = questdlg('Are you sure you want to reload the cell metrics?', 'Reload cell metrics', 'Yes','Cancel','Cancel');
        if strcmp(answer,'Yes') && UI.BatchMode
            ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading batch');
            try
                cell_metrics1 = LoadCellMetricsBatch('clusteringpaths', cell_metrics.general.path,'basenames',cell_metrics.general.basenames,'basepaths',cell_metrics.general.basepaths,'waitbar_handle',ce_waitbar);
                if ~isempty(cell_metrics1)
                    cell_metrics = cell_metrics1;
                else
                    return
                end
                SWR_in = {};
                statusUpdate('Initializing session(s)')
                initializeSession
                if ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
                uiresume(UI.fig);
                MsgLog([num2str(length(cell_metrics.general.basenames)),' session(s) reloaded succesfully'],2);
            catch
                MsgLog(['Failed to reload dataset from database: ',strjoin(cell_metrics.general.basenames)],4);
            end
        elseif strcmp(answer,'Yes')
            if isfield(cell_metrics.general,'path') && exist(cell_metrics.general.path,'dir')
                path1 = cell_metrics.general.path;
                file = fullfile(cell_metrics.general.path,[cell_metrics.general.basename,'.cell_metrics.cellinfo.mat']);
            else isfield(cell_metrics.general,'basepath') && exist(cell_metrics.general.basepath,'dir')
                path1 = fullfile(cell_metrics.general.basepath,cell_metrics.general.clusteringpath);
                file = fullfile(path1,[cell_metrics.general.basename,'.cell_metrics.cellinfo.mat']);
            end
            if exist(file,'file')
                load(file);
                initializeSession;
                uiresume(UI.fig);
                cell_metrics.general.path = path1;
                temp = strsplit(file,'.');
                if length(temp)==4
                    cell_metrics.general.saveAs = temp{end-2};
                else
                    cell_metrics.general.filename = file;
                end
                MsgLog('Session loaded succesful',2)
            else
                MsgLog('Could not reload cell_metrics. cell_metrics file not found.',2)
            end
        end
    end

    function restoreBackup(~,~)
        try
            dir(pwd);
        catch
            MsgLog(['Unable to access current folder.'],4);
            selpath = uigetdir(matlabroot,'Please select current folder');
            cd(selpath);
        end
        if UI.BatchMode
            backupList = dir(fullfile(cell_metrics.general.path{cell_metrics.batchIDs(ii)},'revisions_cell_metrics','cell_metrics_*'));
        else
            backupList = dir(fullfile(cell_metrics.general.path,'revisions_cell_metrics','cell_metrics_*'));
        end
        if ~isempty(backupList)
            backupList = {backupList.name};
        end
        if ~isempty(backupList)
            restoreBackup.dialog = dialog('Position', [300, 300, 300, 518],'Name','Select backup to restore','WindowStyle','modal','visible','off'); movegui(restoreBackup.dialog,'center'), set(restoreBackup.dialog,'visible','on')
            restoreBackup.backupList = uicontrol('Parent',restoreBackup.dialog,'Style','listbox','String',backupList,'Position',[10, 60, 280, 447],'Value',1,'Max',1,'Min',1);
            uicontrol('Parent',restoreBackup.dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)closeDialog);
            uicontrol('Parent',restoreBackup.dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)cancelDialog);
            uiwait(restoreBackup.dialog)
        end
        function closeDialog
            backupToRestore = backupList{restoreBackup.backupList.Value};
            delete(restoreBackup.dialog);
            
            % Creating backup of existing metrics
            if UI.BatchMode
                backup_subset = find(cell_metrics.batchIDs == cell_metrics.batchIDs(ii));
            else
                backup_subset = 1:cell_metrics.general.cellCount;
            end
            createBackup(cell_metrics,backup_subset);
            
            % Restoring backup to metrics
            if UI.BatchMode
                cell_metrics_backup = load(fullfile(cell_metrics.general.path{cell_metrics.batchIDs(ii)},'revisions_cell_metrics',backupToRestore));
            else
                cell_metrics_backup = load(fullfile(cell_metrics.general.path,'revisions_cell_metrics',backupToRestore));
            end
            cell_metrics_backup.cell_metrics = verifyGroupFormat(cell_metrics_backup.cell_metrics,'tags');
            cell_metrics_backup.cell_metrics = verifyGroupFormat(cell_metrics_backup.cell_metrics,'groundTruthClassification');
            if size(cell_metrics_backup.cell_metrics.putativeCellType,2) == length(backup_subset)
                saveStateToHistory(backup_subset);
                cell_metrics.labels(backup_subset) = cell_metrics_backup.cell_metrics.labels;
                if isfield(cell_metrics_backup.cell_metrics,'deepSuperficial')
                    cell_metrics.deepSuperficial(backup_subset) = cell_metrics_backup.cell_metrics.deepSuperficial;
                    cell_metrics.deepSuperficialDistance(backup_subset) = cell_metrics_backup.cell_metrics.deepSuperficialDistance;
                end
                cell_metrics.brainRegion(backup_subset) = cell_metrics_backup.cell_metrics.brainRegion;
                cell_metrics.putativeCellType(backup_subset) = cell_metrics_backup.cell_metrics.putativeCellType;
                
                % TODO: Implement backup of group data
                cell_metrics_fieldnames = {'groundTruthClassification','tags','groups'};
                h = min(backup_subset)-1;
                for ii = 1:numel(cell_metrics_fieldnames)
                    if isfield(cell_metrics,cell_metrics_fieldnames{ii})
                        fields1 = fieldnames(cell_metrics.(cell_metrics_fieldnames{ii}));
                        for k = 1:numel(fields1)
                            cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k}) = setdiff(cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k}),backup_subset);
                        end
                    end
                    if isfield(cell_metrics_backup.cell_metrics,cell_metrics_fieldnames{ii})
                        fields1 = fieldnames(cell_metrics_backup.cell_metrics.(cell_metrics_fieldnames{ii}));
                        for k = 1:numel(fields1)
                            if isfield(cell_metrics,cell_metrics_fieldnames{ii}) && isfield(cell_metrics.(cell_metrics_fieldnames{ii}),fields1{k})
                                cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k}) = unique([cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k}), cell_metrics_backup.cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k})+h]);
                            else
                                cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k}) = cell_metrics_backup.cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k})+h;
                            end
                        end
                    end
                end
                UI.settings.tags = unique([UI.settings.tags fieldnames(cell_metrics.tags)']);
                initTags
                updateTags
                if isfield(UI.settings,'groundTruthClassification')
                    UI.settings.groundTruthClassification = unique([UI.settings.groundTruthClassification fieldnames(cell_metrics.groundTruthClassification)']);
                    delete(UI.togglebutton.groundTruthClassification)
                    createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.settings.groundTruth,'G/T')
                end
                % clusClas initialization
                clusClas = ones(1,length(cell_metrics.putativeCellType));
                for i = 1:length(UI.settings.cellTypes)
                    clusClas(strcmp(cell_metrics.putativeCellType,UI.settings.cellTypes{i}))=i;
                end
                updateCellCount
                updatePlotClas
                updatePutativeCellType
                
                MsgLog(['Session succesfully restored from backup: ' backupToRestore],2)
                uiresume(UI.fig);
            else
                MsgLog(['Session could not be restored from backup: ' backupToRestore ],4)
            end
        end
        
        function cancelDialog
            % Closes the dialog
            delete(restoreBackup.dialog);
        end
    end

    function createBackup(cell_metrics,backup_subset)
        % Creating backup of metrics
        if ~exist('backup_subset','var')
            backup_subset = 1:length(cell_metrics.UID);
        end
        cell_metrics_backup = {};
        cell_metrics_backup.labels = cell_metrics.labels(backup_subset);
        
        if isfield(cell_metrics,'deepSuperficial')
            cell_metrics_backup.deepSuperficial = cell_metrics.deepSuperficial(backup_subset);
            cell_metrics_backup.deepSuperficialDistance = cell_metrics.deepSuperficialDistance(backup_subset);
        end
        cell_metrics_backup.brainRegion = cell_metrics.brainRegion(backup_subset);
        cell_metrics_backup.putativeCellType = cell_metrics.putativeCellType(backup_subset);
        
        cell_metrics_backup.groups = getSubsetCellMetrics(cell_metrics.groups,backup_subset);
        cell_metrics_backup.tags = getSubsetCellMetrics(cell_metrics.tags,backup_subset);
        cell_metrics_backup.groundTruthClassification = getSubsetCellMetrics(cell_metrics.groundTruthClassification,backup_subset);

        S.cell_metrics = cell_metrics_backup;
        if UI.BatchMode && isfield(cell_metrics.general,'saveAs')
            saveAs = cell_metrics.general.saveAs{cell_metrics.batchIDs(ii)};
            path1 = cell_metrics.general.path{batchIDs};
        elseif isfield(cell_metrics.general,'saveAs')
            saveAs = cell_metrics.general.saveAs;
            path1 = cell_metrics.general.path;
        else
            saveAs = 'cell_metrics';
            path1 = cell_metrics.general.path;
        end
        
        if ~(exist(fullfile(path1,'revisions_cell_metrics'),'dir'))
            mkdir(fullfile(path1,'revisions_cell_metrics'));
        end
        save(fullfile(path1, 'revisions_cell_metrics', [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']),'-struct', 'S','-v7.3','-nocompression');
    end

    function toggleHollowGauss(~,~)
        if UI.monoSyn.dispHollowGauss
            UI.monoSyn.dispHollowGauss = false;
            UI.menu.monoSyn.toggleHollowGauss.Checked = 'off';
        else
            UI.monoSyn.dispHollowGauss = true;
            UI.menu.monoSyn.toggleHollowGauss.Checked = 'on';
        end
    end

    function updatePlotConnections(src,~)
        if strcmp(src.Checked,'on')
            plotConnections(src.Position) = 0;
            UI.menu.monoSyn.plotConns.ops(src.Position).Checked = 'off';
        else
            plotConnections(src.Position) = 1;
            UI.menu.monoSyn.plotConns.ops(src.Position).Checked = 'on';
        end
        uiresume(UI.fig);
    end

    function showWaveformMetrics(~,~)
        if UI.settings.plotWaveformMetrics==0
            UI.menu.display.showMetrics.Checked = 'on';
            UI.settings.plotWaveformMetrics = 1;
        else
            UI.menu.display.showMetrics.Checked = 'off';
            UI.settings.plotWaveformMetrics = 0;
        end
        uiresume(UI.fig);
    end
    
    function showAllWaveforms(~,~)
        if UI.settings.showAllWaveforms==0
            UI.menu.display.showAllWaveforms.Checked = 'on';
            UI.settings.showAllWaveforms = 1;
        else
            UI.menu.display.showAllWaveforms.Checked = 'off';
            UI.settings.showAllWaveforms = 0;
        end
        uiresume(UI.fig);
    end
    
    function adjustZscoreWaveforms(~,~)
        if UI.settings.zscoreWaveforms==0
            UI.menu.display.zscoreWaveforms.Checked = 'on';
            UI.settings.zscoreWaveforms = 1;
        else
            UI.menu.display.zscoreWaveforms.Checked = 'off';
            UI.settings.zscoreWaveforms = 0;
        end
        uiresume(UI.fig);
    end
    
    function showChannelMap(src,~)
        if src.Position == 1
            UI.menu.display.showChannelMap.ops(1).Checked = 'on';
            UI.menu.display.showChannelMap.ops(2).Checked = 'off';
            UI.menu.display.showChannelMap.ops(3).Checked = 'off';
            UI.settings.plotInsetChannelMap = 1;
        elseif src.Position == 2
            UI.menu.display.showChannelMap.ops(1).Checked = 'off';
            UI.menu.display.showChannelMap.ops(2).Checked = 'on';
            UI.menu.display.showChannelMap.ops(3).Checked = 'off';
            UI.settings.plotInsetChannelMap = 2;
        elseif src.Position == 3
            UI.menu.display.showChannelMap.ops(1).Checked = 'off';
            UI.menu.display.showChannelMap.ops(2).Checked = 'off';
            UI.menu.display.showChannelMap.ops(3).Checked = 'on';
            UI.settings.plotInsetChannelMap = 3;
        end
        uiresume(UI.fig);
    end

    function showInsetACG(src,~)
        if strcmp(UI.menu.display.showInsetACG.Checked,'off')
            UI.menu.display.showInsetACG.Checked = 'on';
            UI.settings.plotInsetACG = 2;
        else
            UI.menu.display.showInsetACG.Checked = 'off';
            UI.settings.plotInsetACG = 1;
        end
        uiresume(UI.fig);
    end

    function openWebsite(src,~)
        % Opens the CellExplorer website in your browser
        if isprop(src,'Text')
            source = src.Text;
        else
            source = '';
        end
        switch source
            case 'Tutorials'
                web('https://petersenpeter.github.io/CellExplorer/tutorials/tutorials/','-new','-browser')
            otherwise
                web('https://petersenpeter.github.io/CellExplorer/','-new','-browser')
        end
    end

    function openSessionDirectory(~,~)
        % Opens the file directory for the selected cell
        if UI.BatchMode
            if exist(cell_metrics.general.path{cell_metrics.batchIDs(ii)},'dir')
                cd(cell_metrics.general.path{cell_metrics.batchIDs(ii)});
                if ispc
                    winopen(cell_metrics.general.path{cell_metrics.batchIDs(ii)});
                elseif ismac
                    syscmd = ['open ', cell_metrics.general.path{cell_metrics.batchIDs(ii)}, ' &'];
                    system(syscmd);
                else
                    filebrowser;
                end
            else
                MsgLog(['File path not available:' general.basepath],2)
            end
        else
            if exist(cell_metrics.general.path,'dir')
                path_to_open = cell_metrics.general.path;
            else
                path_to_open = pwd;
            end
            if ispc
                winopen(path_to_open);
            elseif ismac
                    syscmd = ['open ', path_to_open, ' &'];
                    system(syscmd);
            else
                filebrowser;
            end
        end
    end

    function openSessionInWebDB(~,~)
        % Opens the current session in the Buzsaki lab web database
        web(['https://buzsakilab.com/wp/sessions/?frm_search=', general.basename],'-new','-browser')
    end

    function showAnimalInWebDB(~,~)
        % Opens the current animal in the Buzsaki lab web database
        if isfield(cell_metrics,'animal')
            web(['https://buzsakilab.com/wp/animals/?frm_search=', cell_metrics.animal{ii}],'-new','-browser')
        else
            web(['https://buzsakilab.com/wp/animals/'],'-new','-browser')
        end
    end

    function [list_metrics,ia] = generateMetricsList(fieldType,preselectedList)
        subfieldsnames = fieldnames(cell_metrics);
        subfieldstypes = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        subfieldssizes = struct2cell(structfun(@size,cell_metrics,'UniformOutput',false));
        subfieldssizes = cell2mat(subfieldssizes);
        list_metrics = {};
        if any(strcmp(fieldType,{'double','all'}))
            temp = find(strcmp(subfieldstypes,'double') & subfieldssizes(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames,'_num'));
            list_metrics = sort(subfieldsnames(temp));
        end
        if any(strcmp(fieldType,{'struct','all'}))
            temp2 = find(strcmp(subfieldstypes,'struct') & ~ismember(subfieldsnames,{'general','groups','tags','groundTruthClassification'}));
            for i = 1:length(temp2)
                fieldname = subfieldsnames{temp2(i)};
                subfieldsnames1 = fieldnames(cell_metrics.(fieldname));
                subfieldstypes1 = struct2cell(structfun(@class,cell_metrics.(fieldname),'UniformOutput',false));
                subfieldssizes1 = struct2cell(structfun(@size,cell_metrics.(fieldname),'UniformOutput',false));
                subfieldssizes1 = cell2mat(subfieldssizes1);
                temp1 = find(strcmp(subfieldstypes1,'double') & subfieldssizes1(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames1,'_num'));
                list_metrics = [list_metrics;strcat({fieldname},{'.'},subfieldsnames1(temp1))];
            end
            subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','spikeGroup','spikeSortingID','entryID'};
            list_metrics = setdiff(list_metrics,subfieldsExclude);
        end
        if exist('preselectedList','var')
            [~,ia,~] = intersect(list_metrics,preselectedList);
            list_metrics = [list_metrics(ia);list_metrics(setdiff(1:length(list_metrics),ia))];
        else
            ia = [];
        end
    end

    function defineMarkerSize(~,~)
        answer = inputdlg({'Enter marker size [recommended: 5-25]'},'Input',[1 40],{num2str(UI.settings.markerSize)});
        if ~isempty(answer)
            UI.settings.markerSize = str2double(answer);
            uiresume(UI.fig);
        end
    end

    function changeColormap(~,~)
        listing = {'hot','parula','jet','hsv','cool','spring','summer','autumn','winter','gray','bone','copper','pink'};
        [indx,~] = listdlg('PromptString','Select colormap','ListString',listing,'ListSize',[250,400],'InitialValue',1,'SelectionMode','single','Name','Colormap');
        if ~isempty(indx)
            UI.settings.colormap = listing{indx};
            uiresume(UI.fig);
        end
    end

    function defineBinSize(~,~)
        answer = inputdlg({'Enter bin count'},'Input',[1 40],{num2str(UI.settings.binCount)});
        if ~isempty(answer)
            UI.settings.binCount = str2double(answer);
            uiresume(UI.fig);
        end
    end

    function editSortingMetric(~,~)
        sortingMetrics = generateMetricsList('double',UI.settings.sortingMetric);
        selectMetrics.dialog = dialog('Position', [300, 300, 400, 518],'Name','Select metric for sorting image data','WindowStyle','modal','visible','off'); movegui(selectMetrics.dialog,'center'), set(selectMetrics.dialog,'visible','on')
        selectMetrics.sessionList = uicontrol('Parent',selectMetrics.dialog,'Style','listbox','String',sortingMetrics,'Position',[10, 50, 380, 457],'Value',1,'Max',1,'Min',1);
        uicontrol('Parent',selectMetrics.dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)close_dialog);
        uicontrol('Parent',selectMetrics.dialog,'Style','pushbutton','Position',[200, 10, 190, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        uiwait(selectMetrics.dialog)
        
        function close_dialog
            UI.settings.sortingMetric = sortingMetrics{selectMetrics.sessionList.Value};
            delete(selectMetrics.dialog);
            uiresume(UI.fig);
        end
        
        function cancel_dialog
            % Closes the dialog
            delete(selectMetrics.dialog);
        end
    end

    function showReferenceData(src,~)
        if src.Position == 1
            UI.settings.referenceData = 'None';
            UI.menu.referenceData.ops(1).Checked = 'on';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'off';
            UI.menu.referenceData.ops(4).Checked = 'off';
            if isfield(UI.tabs,'referenceData')
                delete(UI.tabs.referenceData);
                UI.tabs = rmfield(UI.tabs,'referenceData');
            end
        elseif src.Position == 2
            UI.settings.referenceData = 'Image';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'on';
            UI.menu.referenceData.ops(3).Checked = 'off';
            UI.menu.referenceData.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.settings.referenceData = 'Points';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'on';
            UI.menu.referenceData.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.settings.referenceData = 'Histogram';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'off';
            UI.menu.referenceData.ops(4).Checked = 'on';
        end
        if ~isfield(UI.tabs,'referenceData') && src.Position > 1
            if isempty(reference_cell_metrics)
                out = loadReferenceData;
                if ~out
                    defineReferenceData;
                end
            end
            UI.tabs.referenceData = uitab(UI.panel.tabgroup2,'Title','Reference');
            UI.listbox.referenceData = uicontrol('Parent',UI.tabs.referenceData,'Style','listbox','Position',getpixelposition(UI.tabs.referenceData),'Units','normalized','String',referenceData.cellTypes,'max',99,'min',1,'Value',1,'Callback',@(src,evnt)referenceDataSelection,'KeyPressFcn', {@keyPress});
            UI.panel.tabgroup2.SelectedTab = UI.tabs.referenceData;
            initReferenceDataTab
        end
        uiresume(UI.fig);
    end

    function initReferenceDataTab
        % Defining Cell count for listbox
        if isfield(UI.listbox,'referenceData') && ishandle(UI.listbox.referenceData)
            UI.listbox.referenceData.String = strcat(referenceData.cellTypes,' (',referenceData.counts,')');
            if ~isfield(referenceData,'selection')
                referenceData.selection = 1:length(referenceData.cellTypes);
            end
            UI.listbox.referenceData.Value = referenceData.selection;
        end
    end

    function referenceDataSelection(~,~)
        referenceData.selection = UI.listbox.referenceData.Value;
        uiresume(UI.fig);
    end

    function showGroundTruthData(src,~)
        if src.Position == 1
            UI.settings.groundTruthData = 'None';
            UI.menu.groundTruth.ops(1).Checked = 'on';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            UI.menu.groundTruth.ops(4).Checked = 'off';
            if isfield(UI.tabs,'groundTruthData')
                delete(UI.tabs.groundTruthData);
                UI.tabs = rmfield(UI.tabs,'groundTruthData');
            end
        elseif src.Position == 2
            UI.settings.groundTruthData = 'Image';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'on';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            UI.menu.groundTruth.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.settings.groundTruthData = 'Points';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'on';
            UI.menu.groundTruth.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.settings.groundTruthData = 'Histogram';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            UI.menu.groundTruth.ops(4).Checked = 'on';
        end
        
        if ~isfield(UI.tabs,'groundTruthData') && src.Position > 1
            if isempty(groundTruth_cell_metrics)
                out = loadGroundTruthData;
                if ~out
                    defineGroundTruthData;
                end
            end
            UI.tabs.groundTruthData = uitab(UI.panel.tabgroup2,'Title','GroundTruth');
            UI.listbox.groundTruthData = uicontrol('Parent',UI.tabs.groundTruthData,'Style','listbox','Position',getpixelposition(UI.tabs.groundTruthData),'Units','normalized','String',groundTruthData.groundTruthTypes,'max',99,'min',1,'Value',1,'Callback',@(src,evnt)groundTruthDataSelection,'KeyPressFcn', {@keyPress});
            UI.panel.tabgroup2.SelectedTab = UI.tabs.groundTruthData;
            initGroundTruthTab
        end
        uiresume(UI.fig);
    end

    function initGroundTruthTab
        % Defining Cell count for listbox
        if isfield(UI.listbox,'groundTruthData')
            UI.listbox.groundTruthData.String = strcat(groundTruthData.groundTruthTypes,' (',groundTruthData.counts,')');
            if ~isfield(groundTruthData,'selection')
                groundTruthData.selection = 1:length(groundTruthData.groundTruthTypes);
            end
            UI.listbox.groundTruthData.Value = groundTruthData.selection;
        end
    end

    function groundTruthDataSelection(src,evnt)
        groundTruthData.selection = UI.listbox.groundTruthData.Value;
        uiresume(UI.fig);
    end

    function out = loadReferenceData
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'+referenceData','reference_cell_metrics.cellinfo.mat');
        if exist(referenceData_path,'file')
            load(referenceData_path);
            [reference_cell_metrics,referenceData,fig2_axislimit_x_reference,fig2_axislimit_y_reference] = initializeReferenceData(reference_cell_metrics,'reference');
            out = true;
        else
            out = false;
        end
    end

    function out = loadGroundTruthData
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'+groundTruthData','groundTruth_cell_metrics.cellinfo.mat');
        if exist(referenceData_path,'file')
            load(referenceData_path);
            [groundTruth_cell_metrics,groundTruthData,fig2_axislimit_x_groundTruth,fig2_axislimit_y_groundTruth] = initializeReferenceData(groundTruth_cell_metrics,'groundTruth');
            out = true;
        else
            out = false;
        end
    end

    function importGroundTruth(src,evnt)
        [choice,dialog_canceled] = groundTruthDlg(UI.settings.groundTruth,groundTruthSelection);
        if ~isempty(choice) & ~dialog_canceled
            [~,groundTruthSelection] = ismember(choice',UI.settings.groundTruth);
            MsgLog(['Ground truth cell-types selected: ', strjoin(choice,', ')]);
            uiresume(UI.fig);
        elseif isempty(choice) & ~dialog_canceled
            groundTruthSelection = [];
            MsgLog('No ground truth cell-types selected');
            uiresume(UI.fig);
        end
        
        if any(groundTruthSelection)
            [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
            referenceData_path = fullfile(referenceData_path,'+groundTruthData');
            cell_list = [];
            for i = 1:length(groundTruthSelection)
                cell_list = [cell_list, cell_metrics.groundTruthClassification.(UI.settings.groundTruth{groundTruthSelection(i)})];
            end
            if UI.BatchMode
                sessionWithChanges = unique(cell_metrics.batchIDs(cell_list));
            else
                sessionWithChanges = 1;
            end
            ce_waitbar = waitbar(0,[num2str(length(sessionWithChanges)),' sessions with changes'],'name','Saving ground truth cell metrics','WindowStyle','modal');
            for j = 1:length(sessionWithChanges)
                if ~ishandle(ce_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                if UI.BatchMode
                    waitbar(j/length(sessionWithChanges),ce_waitbar,['Session ' num2str(j),'/',num2str(length(sessionWithChanges)),': ', cell_metrics.general.basenames{sessionID}])
                    cell_subset = cell_list(find(cell_metrics.batchIDs(cell_list)==sessionID));
                else
                    cell_subset = cell_list;
                end
                
                cell_metrics_groundTruthSubset = {};
                if UI.BatchMode
                    cell_metrics_groundTruthSubset.general = cell_metrics.general.batch{sessionID};
                else
                    cell_metrics_groundTruthSubset.general = cell_metrics.general;
                end
                metrics_fieldNames = fieldnames(cell_metrics);
                metrics_fieldNames1 = metrics_fieldNames(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'cell','double'})));
                metrics_fieldNames1(find(contains(metrics_fieldNames1,'_num')))=[];
                for i = 1:length(metrics_fieldNames1)
                    cell_metrics_groundTruthSubset.(metrics_fieldNames1{i}) = cell_metrics.(metrics_fieldNames1{i})(cell_subset);
                end
                metrics_fieldNames2 = metrics_fieldNames(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'struct'})));
                metrics_fieldNames2(find(contains(metrics_fieldNames2,{'putativeConnections','general','groups','tags','groundTruthClassification'})))=[];
                for i = 1:length(metrics_fieldNames2)
                    metrics_fieldNames3 = fieldnames(cell_metrics.(metrics_fieldNames2{i}));
                    metrics_fieldNames3(find(contains(metrics_fieldNames3,'_zscored')))=[];
                    for k = 1:length(metrics_fieldNames3)
                        
                        if iscell(cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k})) && size(cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k}),2) == size(cell_metrics.firingRate,2)
                            cell_metrics_groundTruthSubset.(metrics_fieldNames2{i}).(metrics_fieldNames3{k}) = cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k})(cell_subset);
                        elseif isnumeric(cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k})) && size(cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k}),2) == size(cell_metrics.firingRate,2)
                            cell_metrics_groundTruthSubset.(metrics_fieldNames2{i}).(metrics_fieldNames3{k}) = cell_metrics.(metrics_fieldNames2{i}).(metrics_fieldNames3{k})(:,cell_subset);
                        end
                    end
                end
                cell_metrics_groundTruthSubset.groups = getSubsetCellMetrics(cell_metrics.groups,cell_subset);
                cell_metrics_groundTruthSubset.tags = getSubsetCellMetrics(cell_metrics.tags,cell_subset);
                cell_metrics_groundTruthSubset.groundTruthClassification = getSubsetCellMetrics(cell_metrics.groundTruthClassification,cell_subset);
                
                % Saving the ground truth to the subfolder groundTruthData
                if UI.BatchMode
                    file = fullfile(referenceData_path,[cell_metrics.general.basenames{sessionID}, '.cell_metrics.cellinfo.mat']);
                else
                    file = fullfile(referenceData_path,[cell_metrics.general.basename, '.cell_metrics.cellinfo.mat']);
                end
                S.cell_metrics = cell_metrics_groundTruthSubset;
                save(file,'-struct', 'S','-v7.3','-nocompression');
            end
            if ishandle(ce_waitbar)
                close(ce_waitbar)
                MsgLog(['Ground truth data succesfully saved'],[1,2]);
            else
                MsgLog('Ground truth data not succesfully saved for all sessions',4);
            end
        end
    end
    
    function defineGroupData(~,~)
        if ~isfield(groupData,'groupToList')
            groupData.groupToList = 'tags';
            groupDataSelect = 2;
        else
            groupDataSelect = find(ismember(groupData.groupsList,groupData.groupToList));
        end
        
        updateGroupList
        drawnow nocallbacks;
        groupData.dialog = dialog('Position', [300, 300, 840, 465],'Name','CellExplorer: group data','WindowStyle','modal', 'resize', 'on','visible','off'); movegui(groupData.dialog,'center'), set(groupData.dialog,'visible','on') % 'MenuBar', 'None','NumberTitle','off'
        groupData.VBox = uix.VBox( 'Parent', groupData.dialog, 'Spacing', 5, 'Padding', 0 );
        groupData.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',groupData.VBox);
        groupData.sessionList = uitable(groupData.VBox,'Data',UI.groupData.dataTable,'Position',[10, 50, 740, 457],'ColumnWidth',{65,45,45,100,460 75,45},'columnname',{'Highlight','+filter','-filter','Group name','List of cells','Cell count','Select'},'RowName',[],'ColumnEditable',[true true true true true false true],'Units','normalized','CellEditCallback',@editTable);
        groupData.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',groupData.VBox);
        set(groupData.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',groupData.panel.top,'Style','text','Position',[13, 25, 170, 20],'Units','normalized','String','Group data','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',groupData.panel.top,'Style','text','Position',[203, 25, 120, 20],'Units','normalized','String','Sort by','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',groupData.panel.top,'Style','text','Position',[333, 25, 170, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');

        groupData.popupmenu.groupData = uicontrol('Parent',groupData.panel.top,'Style','popupmenu','Position',[10, 5, 180, 22],'Units','normalized','String',groupData.groupsList,'HorizontalAlignment','left','Callback',@(src,evnt)ChangeGroupToList,'Units','normalized','Value',groupDataSelect);
        groupData.popupmenu.sorting = uicontrol('Parent',groupData.panel.top,'Style','popupmenu','Position',[200, 5, 120, 22],'Units','normalized','String',{'Group name','Count'},'HorizontalAlignment','left','Callback',@(src,evnt)filterGroupData,'Units','normalized');
        groupData.popupmenu.filter = uicontrol('Parent',groupData.panel.top,'Style', 'Edit', 'String', '', 'Position', [330, 5, 170, 25],'Callback',@(src,evnt)filterGroupData,'HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[10, 5, 120, 30],'String','Highlight all','Callback',@(src,evnt)button_groupData_selectAll,'Units','normalized');
        uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[140, 5, 120, 30],'String','Clear all','Callback',@(src,evnt)button_groupData_deselectAll,'Units','normalized');
%         groupData.summaryText = uicontrol('Parent',groupData.panel.bottom,'Style','text','Position',[270, 5, 300, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',groupData.panel.top,'Style','pushbutton','Position',[620, 5, 100, 30],'String','+ New','Callback',@(src,evnt)newGroup,'Units','normalized');
        uicontrol('Parent',groupData.panel.top,'Style','pushbutton','Position',[730, 5, 100, 30],'String','Delete','Callback',@(src,evnt)deleteGroup,'Units','normalized');
        uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[620, 5, 100, 30],'String','Action','Callback',@(src,evnt)CreateGroupAction,'Units','normalized');
        uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[730, 5, 100, 30],'String','Close','Callback',@(src,evnt)CloseDialog,'Units','normalized');
        groupData.popupmenu.performGroundTruthClassification = uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[270, 5, 110, 30],'String','Show GT panel','Callback',@(src,evnt)performGroundTruthClassification,'Units','normalized','visible','Off');
        groupData.popupmenu.importGroundTruth = uicontrol('Parent',groupData.panel.bottom,'Style','pushbutton','Position',[390, 5, 110, 30],'String','Export GT','Callback',@(src,evnt)importGroundTruth,'Units','normalized','visible','Off');

        toggleGroundTruthButtons
        updateGroupDataCount
        filterGroupData
        uicontrol(groupData.popupmenu.filter)
        uiwait(groupData.dialog)
        
        function CreateGroupAction
            oldField = find([groupData.sessionList.Data{:,end}]);
            if ~isempty(oldField)
                field = groupData.sessionList.Data(oldField,4);
                affectedCells = [];
                for i = 1:numel(oldField)
                    affectedCells = [affectedCells,cell_metrics.(groupData.groupToList).(field{i})];
                end
                UI.params.ClickedCells = affectedCells;
                delete(groupData.dialog);
                updateUI2
                GroupAction(UI.params.ClickedCells);
            end
        end
        function ChangeGroupToList
            groupData.groupToList = groupData.groupsList{groupData.popupmenu.groupData.Value};
            toggleGroundTruthButtons
            updateGroupList
            filterGroupData
        end
        function updateUI2
            for i = 1:numel(UI.settings.tags)
                if  isfield(groupData,'tags') && isfield(groupData.tags,'minus_filter') && isfield(groupData.tags.minus_filter,UI.settings.tags{i})
                    UI.togglebutton.dispTags(i).Value = groupData.tags.minus_filter.(UI.settings.tags{i});
                    UI.togglebutton.dispTags(i).FontWeight = 'bold';
                    UI.togglebutton.dispTags(i).ForegroundColor = UI.colors.toggleButtons;
                else 
                    UI.togglebutton.dispTags(i).Value = 0;
                    UI.togglebutton.dispTags(i).FontWeight = 'normal';
                    UI.togglebutton.dispTags(i).ForegroundColor = [0 0 0];
                end
                if isfield(groupData,'tags') && isfield(groupData.tags,'plus_filter') && isfield(groupData.tags.plus_filter,UI.settings.tags{i})
                    UI.togglebutton.dispTags2(i).Value = groupData.tags.plus_filter.(UI.settings.tags{i});
                    UI.togglebutton.dispTags2(i).FontWeight = 'bold';
                    UI.togglebutton.dispTags2(i).ForegroundColor = UI.colors.toggleButtons;
                else
                    UI.togglebutton.dispTags2(i).Value = 0;
                    UI.togglebutton.dispTags2(i).FontWeight = 'normal';
                    UI.togglebutton.dispTags2(i).ForegroundColor = [0 0 0];
                end

            end
        end
        function toggleGroundTruthButtons
            if strcmp(groupData.groupToList,'groundTruthClassification')
                groupData.popupmenu.performGroundTruthClassification.Visible = 'On';
                groupData.popupmenu.importGroundTruth.Visible = 'On';
            else
                groupData.popupmenu.performGroundTruthClassification.Visible = 'Off';
                groupData.popupmenu.importGroundTruth.Visible = 'Off';
            end
        end
        
        function newGroup
            opts.Interpreter = 'tex';
            NewTag = inputdlg({'Name of new group','Cells in group'},'Add group',[1 40],{'',''},opts);
            if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag{1},UI.groupData.(groupData.groupToList)))
                if isvarname(NewTag{1})
                    if ~isempty(NewTag{2})
                        try
                            temp = eval(['[',NewTag{2},']']);
                            if isnumeric(eval(['[',NewTag{2},']']))
                                cell_metrics.(groupData.groupToList).(NewTag{1}) = eval(['[',NewTag{2},']']);
                                idx_ids = cell_metrics.(groupData.groupToList).(NewTag{1}) < 1 | cell_metrics.(groupData.groupToList).(NewTag{1}) > cell_metrics.general.cellCount;
                                cell_metrics.(groupData.groupToList).(NewTag{1})(idx_ids) = [];
                                saveStateToHistory(cell_metrics.(groupData.groupToList).(NewTag{1}));
                            end
                        end
                    else
                        cell_metrics.(groupData.groupToList).(NewTag{1}) = [];
                    end
                    updateGroupList
                    filterGroupData
                    MsgLog(['New group added: ' NewTag{1}]);
                    if strcmp(groupData.groupToList,'tags')
                        UI.settings.tags = [UI.settings.tags,NewTag{1}];
                        initTags
                        updateTags
                    end
                else
                    MsgLog(['Tag not added. Must be a valid variable name : ' NewTag{1}],4);
                end
            end
        end
        
        function deleteGroup
            oldField = find([groupData.sessionList.Data{:,end}]);
            if ~isempty(oldField)
                field = groupData.sessionList.Data(oldField,4);
                affectedCells = [];
                for i = 1:numel(oldField)
                    affectedCells = [affectedCells,cell_metrics.(groupData.groupToList).(field{i})];
                end
                if ~isempty(affectedCells)
                    saveStateToHistory(affectedCells)
                end
                cell_metrics.(groupData.groupToList) = rmfield(cell_metrics.(groupData.groupToList),field);
                updateGroupList
                filterGroupData
                if strcmp(groupData.groupToList,'tags')
                    UI.settings.tags(ismember(UI.settings.tags,field)) = [];
                    initTags
                    updateTags
                end
            end
        end
        
        function editTable(hObject,callbackdata)
            row = callbackdata.Indices(1);
            column = callbackdata.Indices(2);
            if any(column == [1,2,3,7])
                groupData.sessionList.Data{row,column} = callbackdata.EditData;
                if column == 1
                    groupData.(groupData.groupToList).highlight.(groupData.sessionList.Data{row,4}) = callbackdata.EditData;
                elseif column == 2
                    groupData.(groupData.groupToList).plus_filter.(groupData.sessionList.Data{row,4}) = callbackdata.EditData;
                elseif column == 3
                    groupData.(groupData.groupToList).minus_filter.(groupData.sessionList.Data{row,4}) = callbackdata.EditData;
                end
            elseif column == 4 && isvarname(groupData.sessionList.Data{row,column}) && ~ismember(groupData.sessionList.Data{row,column},UI.groupData.(groupData.groupToList))
                
                newField = callbackdata.EditData;
                oldField = callbackdata.PreviousData;
                cells_altered = cell_metrics.(groupData.groupToList).(oldField);
                if ~isempty(cells_altered)
                    saveStateToHistory(cells_altered)
                end
                [cell_metrics.(groupData.groupToList).(newField)] = cell_metrics.(groupData.groupToList).(oldField);
                cell_metrics.(groupData.groupToList) = rmfield(cell_metrics.(groupData.groupToList),oldField);
                updateGroupList;
                filterGroupData;
                
                if strcmp(groupData.groupToList,'tags')
                    UI.settings.tags(ismember(UI.settings.tags,oldField)) = [];
                    UI.settings.tags = [UI.settings.tags,newField];
                    initTags
                    updateTags
                end
            elseif column == 5

                numericValue = groupData.sessionList.Data{row,column};
                preValue = cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4});
                try
                    temp = eval(['[',numericValue,']']);
                    if ~isempty(numericValue) && isnumeric(eval(['[',numericValue,']']))
                        cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4}) = eval(['[',numericValue,']']);
                        idx_ids = cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4}) < 1 | cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4}) > cell_metrics.general.cellCount;
                        cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4})(idx_ids) = [];
                    end
                end
                cells_altered = unique([preValue,cell_metrics.(groupData.groupToList).(groupData.sessionList.Data{row,4})]);
                if ~isempty(cells_altered)
                    saveStateToHistory(cells_altered)
                end
                updateGroupList
                filterGroupData
                if strcmp(groupData.groupToList,'tags')
                    updateTags
                end
            else
                updateGroupList
                filterGroupData
            end
        end
        
        function updateGroupList
            % Loading group data
            UI.groupData = [];
            if isfield(cell_metrics,groupData.groupToList)
                cell_metrics.(groupData.groupToList) = orderfields(cell_metrics.(groupData.groupToList));
                UI.groupData.(groupData.groupToList) = fieldnames(cell_metrics.(groupData.groupToList));
                % Generating table data
                UI.groupData.Counts = struct2cell(structfun(@(X) num2str(length(X)),cell_metrics.(groupData.groupToList),'UniformOutput',false));
                UI.groupData.sessionEnumerator = cellstr(num2str([1:length(UI.groupData.(groupData.groupToList))]'));
                UI.groupData.cellList = cellfun(@num2str,struct2cell(cell_metrics.(groupData.groupToList)),'UniformOutput',false);
                UI.groupData.dataTable = {};
                UI.groupData.dataTable(:,[4,5,6]) = [UI.groupData.(groupData.groupToList),UI.groupData.cellList,UI.groupData.Counts];
                UI.groupData.dataTable(:,1) = {false};
                UI.groupData.dataTable(:,2) = {false};
                UI.groupData.dataTable(:,3) = {false};
                UI.groupData.dataTable(:,7) = {false};
                UI.groupData.sessionList = strcat(UI.groupData.(groupData.groupToList),{' '},UI.groupData.cellList);
                if isfield(groupData,groupData.groupToList)  && isfield(groupData.(groupData.groupToList),'highlight')
                    fields1 = fieldnames(groupData.(groupData.groupToList).highlight);
                    for i = 1:numel(fields1)
                        if groupData.(groupData.groupToList).highlight.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),1) = {true};
                        end
                    end
                end
                if isfield(groupData,groupData.groupToList)  && isfield(groupData.(groupData.groupToList),'plus_filter')
                    fields1 = fieldnames(groupData.(groupData.groupToList).plus_filter);
                    for i = 1:numel(fields1)
                        if groupData.(groupData.groupToList).plus_filter.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),2) = {true};
                        end
                    end
                end
                if isfield(groupData,groupData.groupToList)  && isfield(groupData.(groupData.groupToList),'minus_filter')
                    fields1 = fieldnames(groupData.(groupData.groupToList).minus_filter);
                    for i = 1:numel(fields1)
                        if groupData.(groupData.groupToList).minus_filter.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),3) = {true};
                        end
                    end
                end
            else
                UI.groupData.sessionList = {};
                UI.groupData.dataTable = {false,'',false,false,false,'',''};
                UI.groupData.(groupData.groupToList) = '';
            end
            
        end
        
%         function UpdateSummaryText
%             groupData.summaryText.String = [num2str(size(groupData.sessionList.Data,1)),' group(s)'];
%         end
        function updateGroupDataCount
            groupDataCount = [numel(fieldnames(cell_metrics.(groupData.groupsList{1}))),numel(fieldnames(cell_metrics.(groupData.groupsList{2}))),numel(fieldnames(cell_metrics.(groupData.groupsList{3})))];
            groupData.popupmenu.groupData.String = strcat(groupData.groupsList,' (',cellstr(num2str(groupDataCount'))',')');
        end
        function filterGroupData
            if ~isempty(groupData.popupmenu.filter.String) && ~strcmp(groupData.popupmenu.filter.String,'Filter')
                newStr2 = split(groupData.popupmenu.filter.String,' & ');
                idx_textFilter2 = zeros(length(newStr2),size(UI.groupData.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},' | ');
                    idx_textFilter2(i,:) = contains(UI.groupData.sessionList,newStr3,'IgnoreCase',true);
                end
                idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
            else
                idx1 = 1:size(UI.groupData.dataTable,1);
            end
            if groupData.popupmenu.sorting.Value == 2
                [~,idx2] = sort(str2double([UI.groupData.dataTable(:,end-1)]),'descend');
            else
                [~,idx2] = sort(UI.groupData.dataTable(:,4));
            end
            idx2 = intersect(idx2,idx1,'stable');
            groupData.sessionList.Data = UI.groupData.dataTable(idx2,:);
%             UpdateSummaryText;
            updateGroupDataCount
        end
        
        function button_groupData_selectAll
            groupData.sessionList.Data(:,1) = {true};
            for i = 1:size(groupData.sessionList.Data,1)
                groupData.(groupData.groupToList).highlight.(groupData.sessionList.Data{i,4}) = 1;
            end
        end
        
        function button_groupData_deselectAll
            groupData.sessionList.Data(:,1) = {false};
            groupData.sessionList.Data(:,2) = {false};
            groupData.sessionList.Data(:,3) = {false};
            for i = 1:size(groupData.sessionList.Data,1)
                groupData.(groupData.groupToList).highlight.(groupData.sessionList.Data{i,4}) = 0;
                groupData.(groupData.groupToList).minus_filter.(groupData.sessionList.Data{i,4}) = 0;
                groupData.(groupData.groupToList).plus_filter.(groupData.sessionList.Data{i,4}) = 0;
            end
        end
        
        function CloseDialog
            % Closes the dialog
            delete(groupData.dialog);
            updateUI2
            uiresume(UI.fig);
        end
    end

    function assignGroup(cellIDsIn,field)
        if strcmp(field,'tags')
            groupList = UI.settings.tags';
        else
            groupList = fieldnames(cell_metrics.(field));
        end
        [selectedTag,~] = listdlg('PromptString',['Assign a ',field(1:end-1),' to ' num2str(length(cellIDsIn)) ' selected cells'],'ListString', [groupList;'+ New group'],'SelectionMode','single','ListSize',[200,150],'Name',['Assign ' field(1:end-1)]);
        if ~isempty(selectedTag) && selectedTag > length(groupList)
            opts.Interpreter = 'tex';
            groupName = inputdlg({['Name of new ' field(1:end-1)]},['Add ' field(1:end-1)] ,[1 40],{''},opts);
            if ~isempty(groupName) && ~isempty(groupName{1}) && ~any(strcmp(groupName,fieldnames(cell_metrics.(field))))
                saveStateToHistory(cellIDsIn)
                cell_metrics.(field).(groupName{1}) = cellIDsIn;
                MsgLog(['New ', field(1:end-1),' added: ' groupName{1}]);
                if strcmp(field,'tags')
                    UI.settings.tags = [UI.settings.tags,groupName{1}];
                    initTags
                end 
            end
        elseif ~isempty(selectedTag)
            saveStateToHistory(cellIDsIn)
            if isfield(cell_metrics.(field),groupList{selectedTag})
                cell_metrics.(field).(groupList{selectedTag}) = unique([cellIDsIn,cell_metrics.(field).(groupList{selectedTag})]);
            else
                cell_metrics.(field).(groupList{selectedTag}) = cellIDsIn;
            end
        end
    end

    function defineGroundTruthData(~,~)
        if isempty(groundTruth_cell_metrics)
            out = loadGroundTruthData;
        end
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'+groundTruthData');
        listing = dir(fullfile(referenceData_path,'*.cell_metrics.cellinfo.mat'));
        listing = {listing.name};
        listing = cellfun(@(x) x(1:end-26), listing(:),'uni',0);
        if isempty(groundTruth_cell_metrics) || any(ismember(listing',groundTruth_cell_metrics.sessionName)==0)
            ReloadSessionlist;
        elseif isempty(gt) && exist(fullfile(referenceData_path,'groundTruth_cell_list.mat'),'file')
            load(fullfile(referenceData_path,'groundTruth_cell_list.mat'),'gt');
        elseif isempty(gt)
            ReloadSessionlist;
        end
        drawnow nocallbacks;
        loadDB.dialog = dialog('Position', [300, 300, 840, 565],'Name','CellExplorer: ground truth data','WindowStyle','modal', 'resize', 'on','visible','off'); movegui(loadDB.dialog,'center'), set(loadDB.dialog,'visible','on')
        loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 );
        loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        loadDB.sessionList = uitable(loadDB.VBox,'Data',gt.dataTable,'Position',[10, 50, 740, 457],'ColumnWidth',{20 30 120 120 120 120 120 170},'columnname',{'','#','Ground truth','Session','Brain region','Animal','Genetic line','Species'},'RowName',[],'ColumnEditable',[true false false false false false false false],'Units','normalized');
        loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        set(loadDB.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[580, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
        loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 560, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
        loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[580, 5, 150, 22],'Units','normalized','String',{'Ground truth','Session','Brain region','Animal','Genetic line','Species'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
%         loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[740, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[740, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
        loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 420, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[640, 5, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[740, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog,'Units','normalized');
        
        UpdateSummaryText
        Button_DB_filterList
        if ~isempty(groundTruth_cell_metrics)
            loadDB.sessionList.Data(find(ismember(loadDB.sessionList.Data(:,4),unique(groundTruth_cell_metrics.sessionName))),1) = {true};
        end
        uicontrol(loadDB.popupmenu.filter)
        uiwait(loadDB.dialog)
        
        function ReloadSessionlist
            [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
            referenceData_path = fullfile(referenceData_path,'+groundTruthData');
            listing = dir(fullfile(referenceData_path,'*.cell_metrics.cellinfo.mat'));
            listing = {listing.name};
            listing = cellfun(@(x) x(1:end-26), listing(:),'uni',0);
            referenceData_path1 = cell(1,length(listing));
            referenceData_path1(:) = {referenceData_path};
            % Loading metrics
            gt_cell_metrics = LoadCellMetricsBatch('clusteringpaths', referenceData_path1,'basenames',listing,'basepaths',referenceData_path1); % 'waitbar_handle',ce_waitbar
            gt.refreshTime = datetime('now','Format','HH:mm:ss, d MMMM, yyyy');
            
            % Generating list of sessions
            gt.menu_name = gt_cell_metrics.sessionName;
            gt.menu_geneticLine = gt_cell_metrics.geneticLine;
            fields1 = fieldnames(gt_cell_metrics.groundTruthClassification);
            gt.menu_groundTruth = cell(1,gt_cell_metrics.general.cellCount);
            for i = 1:numel(fields1)
                gt.menu_groundTruth(gt_cell_metrics.groundTruthClassification.(fields1{i})) = strcat(gt.menu_groundTruth(gt_cell_metrics.groundTruthClassification.(fields1{i})),fields1{i});
            end
            gt.menu_animals = gt_cell_metrics.animal;
            gt.menu_species = gt_cell_metrics.species;
            gt.menu_brainRegion = gt_cell_metrics.brainRegion;
            gt.menu_UID = gt_cell_metrics.UID;
            sessionEnumerator = cellstr(num2str([1:length(gt.menu_name)]'))';
            gt.sessionList = strcat(sessionEnumerator,{' '},gt.menu_name,{' '},gt.menu_groundTruth,{' '},gt.menu_geneticLine,{' '},gt.menu_animals,{' '},gt.menu_species,{' '},gt.menu_brainRegion);
            
            gt.dataTable = {};
            gt.dataTable(:,2:8) = [sessionEnumerator;gt.menu_groundTruth;gt.menu_name;gt.menu_brainRegion;gt.menu_animals;gt.menu_geneticLine;gt.menu_species]';
            gt.dataTable(:,1) = {false};
            gt.listing = listing;
            try
                save(fullfile(referenceData_path,'groundTruth_cell_list.mat'),'gt','-v7.3','-nocompression');
            catch
                warning('failed to save session list with metrics');
            end
            UpdateSummaryText
        end
        
        function UpdateSummaryText
            if exist('loadDB','var')
                loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' cell(s) from ', num2str(length(unique(loadDB.sessionList.Data(:,4)))),' sessions from ',num2str(length(unique(loadDB.sessionList.Data(:,6)))),' animal(s). Updated at: ', datestr(gt.refreshTime)];
            end
        end
        
        function Button_DB_filterList
%             dataTable1 = gt.dataTable;
            if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
                newStr2 = split(loadDB.popupmenu.filter.String,' & ');
                idx_textFilter2 = zeros(length(newStr2),size(gt.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},' | ');
                    idx_textFilter2(i,:) = contains(gt.sessionList,newStr3,'IgnoreCase',true);
                end
                idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
            else
                idx1 = 1:size(gt.dataTable,1);
            end
            
            [~,idx2] = sort(gt.dataTable(:,loadDB.popupmenu.sorting.Value+1));
            idx2 = intersect(idx2,idx1,'stable');
            loadDB.sessionList.Data = gt.dataTable(idx2,:);
            UpdateSummaryText
        end
        
        function button_DB_selectAll
            loadDB.sessionList.Data(:,1) = {true};
        end
        
        function button_DB_deselectAll
            loadDB.sessionList.Data(:,1) = {false};
        end
        
        function CloseDB_dialog
            indx = cell2mat(cellfun(@str2double,loadDB.sessionList.Data(find([loadDB.sessionList.Data{:,1}])',2),'un',0));
            if ~isempty(indx)
                list_Session = gt.menu_name(indx);
                list_UID = gt.menu_UID(indx);
                delete(loadDB.dialog);
                listSession2 = unique(list_Session);
                referenceData_path1 = cell(1,length(listSession2));
                referenceData_path1(:) = {referenceData_path};
                % Loading metrics
                groundTruth_cell_metrics = LoadCellMetricsBatch('clusteringpaths', referenceData_path1,'basenames',listSession2,'basepaths',referenceData_path1); % 'waitbar_handle',ce_waitbar
                
                % Saving batch metrics
                save(fullfile(referenceData_path,'groundTruth_cell_metrics.cellinfo.mat'),'groundTruth_cell_metrics','-v7.3','-nocompression');
                
                % Initializing
                [groundTruth_cell_metrics,groundTruthData] = initializeReferenceData(groundTruth_cell_metrics,'groundTruth');
                if isfield(UI.tabs,'groundTruthData')
                    delete(UI.tabs.groundTruthData);
                    UI.tabs = rmfield(UI.tabs,'groundTruthData');
                end
                if isfield(UI.listbox,'groundTruthData')
                    delete(UI.listbox.groundTruthData);
                    UI.listbox = rmfield(UI.listbox,'groundTruthData');
                end
                UI.tabs.groundTruthData = uitab(UI.panel.tabgroup2,'Title','GroundTruth');
                UI.listbox.groundTruthData = uicontrol('Parent',UI.tabs.groundTruthData,'Style','listbox','Position',getpixelposition(UI.tabs.groundTruthData),'Units','normalized','String',groundTruthData.groundTruthTypes,'max',99,'min',1,'Value',1,'Callback',@(src,evnt)groundTruthDataSelection,'KeyPressFcn', {@keyPress});
                UI.panel.tabgroup2.SelectedTab = UI.tabs.groundTruthData;
                initGroundTruthTab
                uiresume(UI.fig);
            else
                delete(loadDB.dialog);
            end
            if ishandle(UI.fig)
                uiresume(UI.fig);
            end
        end
        
        function  CancelDB_dialog
            % Closes the dialog
            delete(loadDB.dialog);
        end
    end

    function defineReferenceData(~,~)
        % Load reference data from NYU, through either local or internet connection
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
        if isempty(reference_cell_metrics)
            out = loadReferenceData;
        end
        
        drawnow nocallbacks;
        if isempty(db) && exist('db_cell_metrics_session_list.mat','file')
            load('db_cell_metrics_session_list.mat')
        elseif isempty(db)
            LoadDB_sessionlist
        end
        
        loadDB.dialog = dialog('Position', [300, 300, 1000, 565],'Name','CellExplorer: reference data','WindowStyle','modal', 'resize', 'on','visible','off'); movegui(loadDB.dialog,'center'), set(loadDB.dialog,'visible','on')
        loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 );
        loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        loadDB.sessionList = uitable(loadDB.VBox,'Data',db.dataTable,'Position',[10, 50, 880, 457],'ColumnWidth',{20 30 210 50 120 70 160 110 110 100},'columnname',{'','#','Session','Cells','Animal','Species','Behaviors','Investigator','Repository','Brain regions'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized'); % ,'CellSelectionCallback',@ClicktoSelectFromTable
        loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        set(loadDB.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[580, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[740, 25, 150, 20],'Units','normalized','String','Repositories','HorizontalAlignment','center','Units','normalized');
        loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 560, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
        loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[580, 5, 150, 22],'Units','normalized','String',{'Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[740, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
        loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 580, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[800, 5, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog,'Units','normalized');
        
        UpdateSummaryText
        Button_DB_filterList
        if ~isempty(reference_cell_metrics)
            loadDB.sessionList.Data(find(ismember(loadDB.sessionList.Data(:,3),unique(reference_cell_metrics.sessionName))),1) = {true};
        end
        uicontrol(loadDB.popupmenu.filter)
        uiwait(loadDB.dialog)
        
        function ReloadSessionlist
            LoadDB_sessionlist
            Button_DB_filterList
        end
        
        function UpdateSummaryText
            cellCount = sum(cell2mat( cellfun(@(x) str2double(x),loadDB.sessionList.Data(:,4),'UniformOutput',false)));
            loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' session(s) with ', num2str(cellCount),' cells from ',num2str(length(unique(loadDB.sessionList.Data(:,5)))),' animal(s). Updated at: ', datestr(db.refreshTime)];
        end
        
        function Button_DB_filterList
            dataTable1 = db.dataTable;
            if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
                newStr2 = split(loadDB.popupmenu.filter.String,' & ');
                idx_textFilter2 = zeros(length(newStr2),size(db.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},' | ');
                    idx_textFilter2(i,:) = contains(db.sessionList,newStr3,'IgnoreCase',true);
                end
                idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
            else
                idx1 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.sorting.Value == 2 % Cell count
                cellCount = cell2mat( cellfun(@(x) x.spikeSorting.cellCount,db.sessions,'UniformOutput',false));
                [~,idx2] = sort(cellCount(db.index),'descend');
            elseif loadDB.popupmenu.sorting.Value == 3 % Animal
                [~,idx2] = sort(db.menu_animals(db.index));
            elseif loadDB.popupmenu.sorting.Value == 4 % Species
                [~,idx2] = sort(db.menu_species(db.index));
            elseif loadDB.popupmenu.sorting.Value == 5 % Behavioral paradigm
                [~,idx2] = sort(db.menu_behavioralParadigm(db.index));
            elseif loadDB.popupmenu.sorting.Value == 6 % Investigator
                [~,idx2] = sort(db.menu_investigator(db.index));
            elseif loadDB.popupmenu.sorting.Value == 7 % Data repository
                [~,idx2] = sort(db.menu_repository(db.index));
            else
                idx2 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.repositories.Value == 1 && ~isempty(db_settings.repositories)
                idx3 = find(ismember(db.menu_repository(db.index),[fieldnames(db_settings.repositories);'NYUshare_Datasets']));
            else
                idx3 = 1:size(db.dataTable,1);
            end
            
            idx2 = intersect(idx2,idx1,'stable');
            idx2 = intersect(idx2,idx3,'stable');
            loadDB.sessionList.Data = db.dataTable(idx2,:);
            UpdateSummaryText
        end
        
        function ClicktoSelectFromTable(~, event)
            % Called when a table-cell is clicked in the table. Changes to
            % custom display according what metric is clicked. First column
            % updates x-axis and second column updates the y-axis
            
            if ~isempty(event.Indices) & all(event.Indices(:,2) > 1)
                loadDB.sessionList.Data(event.Indices(:,1),1) = {true};
            end
        end
        
        function button_DB_selectAll
            loadDB.sessionList.Data(:,1) = {true};
        end
        
        function button_DB_deselectAll
            loadDB.sessionList.Data(:,1) = {false};
        end
        
        function CloseDB_dialog
            indx = cell2mat(cellfun(@str2double,loadDB.sessionList.Data(find([loadDB.sessionList.Data{:,1}])',2),'un',0));
            delete(loadDB.dialog);
            if ~isempty(indx)
                % Loading multiple sessions
                % Setting paths from reference data folder/nyu share
                db_basepath = {};
                db_clusteringpath = {};
                db_basename = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
                i_db_subset_all = db.index(indx);
                [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
                if ~exist(fullfile(referenceData_path,'+referenceData'), 'dir')
                    mkdir(referenceData_path,'+referenceData');
                end
                referenceData_path = fullfile(referenceData_path,'+referenceData');
                nyu_url = 'https://buzsakilab.nyumc.org/datasets/';
                
                ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading reference data');
                for i_db = 1:length(i_db_subset_all)
                    i_db_subset = i_db_subset_all(i_db);
                    indx2 = indx(i_db);
                    if ~any(strcmp(db.sessions{i_db_subset}.repositories{1},fieldnames(db_settings.repositories)))
                        MsgLog(['The respository ', db.sessions{i_db_subset}.repositories{1} ,' has not been defined on this computer. Please edit db_local_repositories and provide the path'],4)
                        edit db_local_repositories.m
                        return
                    end
                    
                    db_clusteringpath{i_db} = referenceData_path;
                    db_basepath{i_db} = referenceData_path;
                    if ~exist(fullfile(db_clusteringpath{i_db},[db_basename{indx2},'.cell_metrics.cellinfo.mat']),'file')
                        waitbar(i_db/length(i_db_subset_all),ce_waitbar,['Downloading missing reference data : ' db_basename{indx2}]);
                        Investigator_name = strsplit(db.sessions{i_db_subset}.investigator,' ');
                        path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                        filename = fullfile(referenceData_path,[db_basename{indx2},'.cell_metrics.cellinfo.mat']);
                        
                        if ~any(strcmp(db.sessions{i_db_subset}.repositories{1},fieldnames(db_settings.repositories))) && strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_Datasets')
                            url = [nyu_url,path_Investigator,'/',db.sessions{i_db_subset}.animal,'/', db_basename{indx2},'/',[db_basename{indx2},'.cell_metrics.cellinfo.mat']];
                            outfilename = websave(filename,url);
                        else
                            if strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_Datasets')
                                url = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), path_Investigator,db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                            else
                                url = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                            end
                            if ~isempty(db.sessions{i_db_subset}.spikeSorting.relativePath)
                                url = fullfile(url, db.sessions{i_db_subset}.spikeSorting.relativePath{1},[db_basename{indx2},'.cell_metrics.cellinfo.mat']);
                            else
                                url = fullfile(url,[db_basename{indx2},'.cell_metrics.cellinfo.mat']);
                            end
                            status = copyfile(url,filename);
                            if ~status
                                MsgLog(['Copying cell metrics failed'],4)
                                return
                            end
                        end
                    end
                    %                         cell_metrics2{i_db} = load(fullfile(db_clusteringpath{i_db},[db_basename{i_db_subset},'.',saveAs,'.cellinfo.mat']));
                end
                
                cell_metrics1 = LoadCellMetricsBatch('clusteringpaths', db_clusteringpath,'basenames',db_basename(indx),'basepaths',db_basepath,'waitbar_handle',ce_waitbar);
                if ~isempty(cell_metrics1)
                    reference_cell_metrics = cell_metrics1;
                else
                    return
                end
                
                if ishandle(ce_waitbar)
                    waitbar(1,ce_waitbar,'Initializing session(s)');
                else
                    disp(['Initializing session(s)']);
                end
                save(fullfile(referenceData_path,'reference_cell_metrics.cellinfo.mat'),'reference_cell_metrics','-v7.3','-nocompression');
                
                [reference_cell_metrics,referenceData] = initializeReferenceData(reference_cell_metrics,'reference');
                if isfield(UI.tabs,'referenceData')
                    delete(UI.tabs.referenceData);
                    UI.tabs = rmfield(UI.tabs,'referenceData');
                end
                if isfield(UI.listbox,'referenceData')
                    delete(UI.listbox.referenceData);
                    UI.listbox = rmfield(UI.listbox,'referenceData');
                end
                UI.tabs.referenceData = uitab(UI.panel.tabgroup2,'Title','Reference');
                UI.listbox.referenceData = uicontrol('Parent',UI.tabs.referenceData,'Style','listbox','Position',getpixelposition(UI.tabs.referenceData),'Units','normalized','String',referenceData.cellTypes,'max',99,'min',1,'Value',1,'Callback',@(src,evnt)referenceDataSelection,'KeyPressFcn', {@keyPress});
                UI.panel.tabgroup2.SelectedTab = UI.tabs.referenceData;
                initReferenceDataTab
                
                if ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
                try
                    if isfield(UI,'panel')
                        MsgLog([num2str(length(indx)),' session(s) loaded succesfully'],2);
                    else
                        disp([num2str(length(indx)),' session(s) loaded succesfully']);
                    end
                    
                catch
                    if isfield(UI,'panel')
                        MsgLog(['Failed to load dataset from database: ',strjoin(db.menu_items(indx))],4);
                    else
                        disp(['Failed to load dataset from database: ',strjoin(db.menu_items(indx))]);
                    end
                    
                end
            end
            
            if ishandle(UI.fig)
                uiresume(UI.fig);
            end
            
        end
        
        function  CancelDB_dialog
            % Closes the dialog
            delete(loadDB.dialog);
        end
    end

    function tSNE_redefineMetrics(~,~)
        [list_tSNE_metrics,ia] = generateMetricsList('all',UI.settings.tSNE.metrics);
        distanceMetrics = {'euclidean', 'seuclidean', 'cityblock', 'chebychev', 'minkowski', 'mahalanobis', 'cosine', 'correlation', 'spearman', 'hamming', 'jaccard'};
        % [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        
        load_tSNE.dialog = dialog('Position', [300, 300, 500, 518],'Name','Select metrics for the tSNE plot','WindowStyle','modal','visible','off'); movegui(load_tSNE.dialog,'center'), set(load_tSNE.dialog,'visible','on')
        load_tSNE.sessionList = uicontrol('Parent',load_tSNE.dialog,'Style','listbox','String',list_tSNE_metrics,'Position',[10, 135, 480, 372],'Value',1:length(ia),'Max',100,'Min',1);
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 113, 100, 20],'Units','normalized','String','Algorithm','HorizontalAlignment','left');
        load_tSNE.popupmenu.algorithm = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[10, 95, 100, 20],'Units','normalized','String',{'tSNE','UMAP','PCA'},'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 113, 110, 20],'Units','normalized','String','Distance metric','HorizontalAlignment','left');
        load_tSNE.popupmenu.distanceMetric = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[120, 95, 120, 20],'Units','normalized','String',distanceMetrics,'HorizontalAlignment','left');
        if find(strcmp(UI.settings.tSNE.dDistanceMetric,distanceMetrics)); load_tSNE.popupmenu.distanceMetric.Value = find(strcmp(UI.settings.tSNE.dDistanceMetric,distanceMetrics)); end
        load_tSNE.checkbox.filter = uicontrol('Parent',load_tSNE.dialog,'Style','checkbox','Position',[250, 95, 300, 20],'Units','normalized','String','Limit population to current filter','HorizontalAlignment','right');
        
        UI.settings.tSNE.InitialY = 'Random';
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 73, 100, 20],'Units','normalized','String','nPCAComponents','HorizontalAlignment','left');
        load_tSNE.popupmenu.NumPCAComponents = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[10, 55, 100, 20],'Units','normalized','String',UI.settings.tSNE.NumPCAComponents,'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 73, 90, 20],'Units','normalized','String','LearnRate','HorizontalAlignment','left');
        load_tSNE.popupmenu.LearnRate = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[120, 55, 90, 20],'Units','normalized','String',UI.settings.tSNE.LearnRate,'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[220, 73, 70, 20],'Units','normalized','String','Perplexity','HorizontalAlignment','left');
        load_tSNE.popupmenu.Perplexity = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[220, 55, 70, 20],'Units','normalized','String',UI.settings.tSNE.Perplexity,'HorizontalAlignment','left');
        
        InitialYMetrics = {'Random','PCA space'};
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[380, 73, 110, 20],'Units','normalized','String','InitialY','HorizontalAlignment','left');
        load_tSNE.popupmenu.InitialY = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[380, 55, 110, 20],'Units','normalized','String',InitialYMetrics,'HorizontalAlignment','left','Value',1);
        if find(strcmp(UI.settings.tSNE.InitialY,InitialYMetrics)); load_tSNE.popupmenu.InitialY.Value = find(strcmp(UI.settings.tSNE.InitialY,InitialYMetrics)); end
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[300, 73, 70, 20],'Units','normalized','String','Exaggeration','HorizontalAlignment','left');
        load_tSNE.popupmenu.exaggeration = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[300, 55, 70, 20],'Units','normalized','String',num2str(UI.settings.tSNE.exaggeration),'HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','pushbutton','Position',[300, 10, 90, 30],'String','OK','Callback',@(src,evnt)close_tSNE_dialog);
        uicontrol('Parent',load_tSNE.dialog,'Style','pushbutton','Position',[400, 10, 90, 30],'String','Cancel','Callback',@(src,evnt)cancel_tSNE_dialog);
        uiwait(load_tSNE.dialog)
        
        function close_tSNE_dialog
            selectedFields = list_tSNE_metrics(load_tSNE.sessionList.Value);
            regularFields = find(~contains(selectedFields,'.'));
            X = cell2mat(cellfun(@(X) cell_metrics.(X),selectedFields(regularFields),'UniformOutput',false));
            
            structFields = find(contains(selectedFields,'.'));
            if ~isempty(structFields)
                for i = 1:length(structFields)
                    newStr = split(selectedFields{structFields(i)},'.');
                    X = [X;cell_metrics.(newStr{1}).(newStr{2})];
                end
            end
            
            UI.settings.tSNE.metrics = list_tSNE_metrics(load_tSNE.sessionList.Value);
            UI.settings.tSNE.dDistanceMetric = distanceMetrics{load_tSNE.popupmenu.distanceMetric.Value};
            UI.settings.tSNE.exaggeration = str2double(load_tSNE.popupmenu.exaggeration.String);
            UI.settings.tSNE.algorithm = load_tSNE.popupmenu.algorithm.String{load_tSNE.popupmenu.algorithm.Value};
            
            UI.settings.tSNE.NumPCAComponents = str2double(load_tSNE.popupmenu.NumPCAComponents.String);
            UI.settings.tSNE.LearnRate = str2double(load_tSNE.popupmenu.LearnRate.String);
            UI.settings.tSNE.Perplexity = str2double(load_tSNE.popupmenu.Perplexity.String);
            UI.settings.tSNE.InitialY = load_tSNE.popupmenu.InitialY.String{load_tSNE.popupmenu.InitialY.Value};
            UI.settings.tSNE.filter = load_tSNE.checkbox.filter.Value;
            
            delete(load_tSNE.dialog);
            ce_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
            X(isnan(X) | isinf(X)) = 0;
            if UI.settings.tSNE.filter == 1
                X1 = nan(cell_metrics.general.cellCount,2);
                X = X(:,UI.params.subset);
            end
            switch UI.settings.tSNE.algorithm
                case 'tSNE'
                    if strcmp(UI.settings.tSNE.InitialY,'PCA space')
                        waitbar(0.1,ce_waitbar,'Calculating PCA init space space...')
                        initPCA = pca(X,'NumComponents',2);
                        waitbar(0.2,ce_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.settings.tSNE.standardize,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration,'NumPCAComponents',UI.settings.tSNE.NumPCAComponents,'Perplexity',UI.settings.tSNE.Perplexity,'InitialY',initPCA,'LearnRate',UI.settings.tSNE.LearnRate);
                    else
                        waitbar(0.1,ce_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.settings.tSNE.standardize,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration,'NumPCAComponents',UI.settings.tSNE.NumPCAComponents,'Perplexity',min(size(X,2),UI.settings.tSNE.Perplexity),'LearnRate',UI.settings.tSNE.LearnRate);
                    end
                case 'UMAP'
                    waitbar(0.1,ce_waitbar,'Calculating UMAP space...')
                    tSNE_metrics.plot = run_umap(X','verbose','none'); % ,'metric',UI.settings.tSNE.dDistanceMetric
                case 'PCA'
                    waitbar(0.1,ce_waitbar,'Calculating PCA space...')
                    tSNE_metrics.plot = pca(X,'NumComponents',2); % ,'metric',UI.settings.tSNE.dDistanceMetric
            end
            if UI.settings.tSNE.filter == 1
                X1(UI.params.subset,:) = tSNE_metrics.plot;
                tSNE_metrics.plot = X1;
            end
            
            if size(tSNE_metrics.plot,2)==1
                tSNE_metrics.plot = [tSNE_metrics.plot,tSNE_metrics.plot];
            end
            
            if ishandle(ce_waitbar)
                waitbar(1,ce_waitbar,'feature space calculations complete.')
                close(ce_waitbar)
            end
            uiresume(UI.fig);
            MsgLog('tSNE space calculations complete.');
            fig3_axislimit_x = [min(tSNE_metrics.plot(:,1)), max(tSNE_metrics.plot(:,1))];
            fig3_axislimit_y = [min(tSNE_metrics.plot(:,2)), max(tSNE_metrics.plot(:,2))];
        end
        
        function  cancel_tSNE_dialog
            % Closes the dialog
            delete(load_tSNE.dialog);
        end
        
    end

    function adjustDeepSuperficial1(~,~)
        % Adjust Deep-Superfical assignment for session and update cell_metrics
        if UI.BatchMode
            deepSuperficialfromRipple = gui_DeepSuperficial(cell_metrics.general.basepaths{batchIDs},general.basename);
        elseif exist(cell_metrics.general.basepath,'dir')
            deepSuperficialfromRipple = gui_DeepSuperficial(cell_metrics.general.basepath,general.basename);
        else
            uiwait(msgbox('Please select the basepath for this session','Basepath missing','modal'));
            tempDir = uigetdir(pwd,'Please select the basepath for this session');
            if ~isnumeric(tempDir)
                cell_metrics.general.basepath = tempDir;
                deepSuperficialfromRipple = gui_DeepSuperficial(cell_metrics.general.basepath,general.basename);
            end
        end
        if ~isempty(deepSuperficialfromRipple)
            if UI.BatchMode
                subset = find(cell_metrics.batchIDs == batchIDs);
            else
                subset = 1:cell_metrics.general.cellCount;
            end
            saveStateToHistory(subset)
            for j = subset
                cell_metrics.deepSuperficial(j) = deepSuperficialfromRipple.channelClass(cell_metrics.maxWaveformCh1(j));
                cell_metrics.deepSuperficialDistance(j) = deepSuperficialfromRipple.channelDistance(cell_metrics.maxWaveformCh1(j));
            end
            for j = 1:length(UI.settings.deepSuperficial)
                cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.settings.deepSuperficial{j}))=j;
            end
            
            if UI.BatchMode
                cell_metrics.general.SWR_batch{cell_metrics.batchIDs(ii)} = deepSuperficialfromRipple;
            else
                cell_metrics.general.SWR_batch = deepSuperficialfromRipple;
            end
            if UI.BatchMode && isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs{batchIDs};
                matpath = fullfile(cell_metrics.general.path{batchIDs},[cell_metrics.general.basenames{batchIDs}, '.',saveAs,'.cellinfo.mat']);
            elseif isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs;
                matpath = fullfile(cell_metrics.general.path,[cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat']);
            else
                saveAs = 'cell_metrics';
                matpath = fullfile(cell_metrics.general.path,[cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat']);
            end
            matFileCell_metrics = matfile(matpath,'Writable',true);
            temp = matFileCell_metrics.cell_metrics;
            temp.general.SWR = deepSuperficialfromRipple;
            matFileCell_metrics.cell_metrics = temp;
            MsgLog('Deep-Superficial succesfully updated',2);
            uiresume(UI.fig);
        end
    end

    function performClassification(~,~)
        subfieldsnames =  fieldnames(cell_metrics);
        subfieldstypes = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        subfieldssizes = struct2cell(structfun(@size,cell_metrics,'UniformOutput',false));
        subfieldssizes = cell2mat(subfieldssizes);
        temp = find(strcmp(subfieldstypes,'double') & subfieldssizes(:,2) == length(cell_metrics.cellID) & ~contains(subfieldsnames,'_num'));
        list_tSNE_metrics = sort(subfieldsnames(temp));
        subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','SpikeGroup','SpikeSortingID'};
        list_tSNE_metrics = setdiff(list_tSNE_metrics,subfieldsExclude);
        if isfield(UI.settings,'classification_metrics')
            [~,ia,~] = intersect(list_tSNE_metrics,UI.settings.classification_metrics);
        else
            [~,ia,~] = intersect(list_tSNE_metrics,UI.settings.tSNE.metrics);
        end
        list_tSNE_metrics = [list_tSNE_metrics(ia);list_tSNE_metrics(setdiff(1:length(list_tSNE_metrics),ia))];
        [indx,~] = listdlg('PromptString',['Select the metrics to use for the classification'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        if ~isempty(indx)
            ce_waitbar = waitbar(0,'Preparing metrics for classification...','WindowStyle','modal');
            X = cell2mat(cellfun(@(X) cell_metrics.(X),list_tSNE_metrics(indx),'UniformOutput',false));
            UI.settings.classification_metrics = list_tSNE_metrics(indx);
            
            X(isnan(X) | isinf(X)) = 0;
            waitbar(0.1,ce_waitbar,'Calculating tSNE space...')
            
            % Hierarchical Clustering
            eucD = pdist(X','euclidean');
            clustTreeEuc = linkage(X','average');
            cophenet(clustTreeEuc,eucD);
            
            % K nearest neighbor clustering
            % Mdl = fitcknn(X',cell_metrics.putativeCellType,'NumNeighbors',5,'Standardize',1);
            
            % UMAP visualization
            % tSNE_metrics.plot = run_umap(X');
            
            waitbar(1,ce_waitbar,'Classification calculations complete.')
            if ishandle(ce_waitbar)
                close(ce_waitbar)
            end
            figure,
            [h,~] = dendrogram(clustTreeEuc,0); title('Hierarchical Clustering')
            h_gca = gca;
            h_gca.TickDir = 'out';
            h_gca.TickLength = [.002 0];
            h_gca.XTickLabel = [];
            
            MsgLog('Classification space calculations complete.');
        end
    end

    function ii_history_reverse(~,~)
        if length(UI.params.ii_history)>1
            UI.params.ii_history(end) = [];
            ii = UI.params.ii_history(end);
            MsgLog(['Previous cell selected: ', num2str(ii)])
            uiresume(UI.fig);
        else
            MsgLog('No further cell selection history available')
            
        end
    end

    function buttonCellType(selectedClas)
        if any(selectedClas == [1:length(UI.settings.cellTypes)])
            saveStateToHistory(ii)
            clusClas(ii) = selectedClas;
            MsgLog(['Cell ', num2str(ii), ' classified as ', UI.settings.cellTypes{selectedClas}]);
            updateCellCount
            updatePlotClas
            updatePutativeCellType
            uiresume(UI.fig);
        end
    end

    function buttonPosition = getButtonLayout(parentPanelName,buttonLabels,extraButton)
        if extraButton==1
            nButtons = length(buttonLabels)+1;
        else
            nButtons = length(buttonLabels);
        end
        rows = max(ceil(nButtons/2),3);
        positionToogleButtons = getpixelposition(parentPanelName);
        positionToogleButtons = [positionToogleButtons(3)/2,(positionToogleButtons(4)-0.03)/rows];
        for i = 1:nButtons
            buttonPosition{i} = [(1.04-mod(i,2))*positionToogleButtons(1),0.05+(rows-ceil(i/2))*positionToogleButtons(2),positionToogleButtons(1),positionToogleButtons(2)];
        end
    end

    function saveStateToHistory(cellIDs)
        UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).cellIDs = cellIDs;
        history_classification(hist_idx).cellTypes = clusClas(cellIDs);
        history_classification(hist_idx).deepSuperficial = cell_metrics.deepSuperficial{cellIDs};
        history_classification(hist_idx).brainRegion = cell_metrics.brainRegion{cellIDs};
        history_classification(hist_idx).labels = cell_metrics.labels{cellIDs};
        history_classification(hist_idx).tags = cell_metrics.tags;
        history_classification(hist_idx).groups = cell_metrics.groups;
        history_classification(hist_idx).groundTruthClassification = cell_metrics.groundTruthClassification;
        history_classification(hist_idx).deepSuperficial_num = cell_metrics.deepSuperficial_num(cellIDs);
        history_classification(hist_idx).deepSuperficialDistance = cell_metrics.deepSuperficialDistance(cellIDs);
        classificationTrackChanges = [classificationTrackChanges,cellIDs];
        if rem(hist_idx,UI.settings.autoSaveFrequency) == 0
            autoSave_Cell_metrics(cell_metrics)
        end
    end

    function autoSave_Cell_metrics(cell_metrics)
        cell_metrics = saveCellMetricsStruct(cell_metrics);
        assignin('base',UI.settings.autoSaveVarName,cell_metrics);
        MsgLog(['Autosaved classification changes to workspace (variable: ' UI.settings.autoSaveVarName ')']);
    end

    function listCellType
        if UI.listbox.cellClassification.Value > length(UI.settings.cellTypes)
            AddNewCellType
        else
            saveStateToHistory(ii);
            clusClas(ii) = UI.listbox.cellClassification.Value;
            MsgLog(['Cell ', num2str(ii), ' classified as ', UI.settings.cellTypes{clusClas(ii)}]);
            updateCellCount
            updatePlotClas
            updatePutativeCellType
            uicontrol(UI.pushbutton.next)
            uiresume(UI.fig);
        end
    end

    function AddNewCellType(~,~)
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
            updatePutativeCellType
            classes2plot = UI.listbox.cellTypes.Value;
            MsgLog(['New cell type added: ' NewClass{1}]);
            uiresume(UI.fig);
        end
    end

    function addTag(~,~)
        opts.Interpreter = 'tex';
        NewTag = inputdlg({'Name of new tag'},'Add tag',[1 40],{''},opts);
        if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag,UI.settings.tags))
            if isvarname(NewTag{1})
                UI.settings.tags = [UI.settings.tags,NewTag];
                initTags
                MsgLog(['New tag added: ' NewTag{1}]);
                uiresume(UI.fig);
            else
                MsgLog(['Tag not added. Must be a valid variable name : ' NewTag{1}],4);
            end
        end
    end

    function initTags
        % Initialize tags
%         dispTags = ones(size(UI.settings.tags));
%         dispTags2 = zeros(size(UI.settings.tags));
        
        % Tags
        buttonPosition = getButtonLayout(UI.tabs.tags,UI.settings.tags,1);
        delete(UI.togglebutton.tag)
        for m = 1:length(UI.settings.tags)
            UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String',UI.settings.tags{m},'Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)buttonTags(m),'KeyPressFcn', {@keyPress});
        end
        m = length(UI.settings.tags)+1;
        UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String','+ tag','Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)addTag,'KeyPressFcn', {@keyPress});
        
        % Display settings for tags1
        buttonPosition = getButtonLayout(UI.tabs.dispTags_minus,UI.settings.tags,0);
        delete(UI.togglebutton.dispTags)
        for m = 1:length(UI.settings.tags)
            UI.togglebutton.dispTags(m) = uicontrol('Parent',UI.tabs.dispTags_minus,'Style','togglebutton','String',UI.settings.tags{m},'Position',buttonPosition{m},'Value',1,'Units','normalized','Callback',@(src,evnt)buttonTags_minus(m),'KeyPressFcn', {@keyPress});
        end
        
        % Display settings for tags2
        delete(UI.togglebutton.dispTags2)
        for m = 1:length(UI.settings.tags)
            UI.togglebutton.dispTags2(m) = uicontrol('Parent',UI.tabs.dispTags_plus,'Style','togglebutton','String',UI.settings.tags{m},'Position',buttonPosition{m},'Value',0,'Units','normalized','Callback',@(src,evnt)buttonTags_plus(m),'KeyPressFcn', {@keyPress});
        end
    end

    function colored_string = DefineCellTypeList
        if size(UI.settings.cellTypeColors,1) < length(UI.settings.cellTypes)
            UI.settings.cellTypeColors = [UI.settings.cellTypeColors;rand(length(UI.settings.cellTypes)-size(UI.settings.cellTypeColors,1),3)];
        elseif size(UI.settings.cellTypeColors,1) > length(UI.settings.cellTypes)
            UI.settings.cellTypeColors = UI.settings.cellTypeColors(1:length(UI.settings.cellTypes),:);
        end
        classColorsHex = rgb2hex(UI.settings.cellTypeColors*0.7);
        classColorsHex = cellstr(classColorsHex(:,2:end));
        classNumbers = cellstr(num2str([1:length(UI.settings.cellTypes)]'))';
        colored_string = strcat('<html>',classNumbers, '.&nbsp;','<BODY bgcolor="white"><font color="', classColorsHex' ,'">&nbsp;', UI.settings.cellTypes, '&nbsp;</font></BODY></html>');
        colored_string = [colored_string,'+   New Cell-type'];
    end

    function buttonDeepSuperficial
        saveStateToHistory(ii)
        cell_metrics.deepSuperficial{ii} = UI.settings.deepSuperficial{UI.listbox.deepSuperficial.Value};
        cell_metrics.deepSuperficial_num(ii) = UI.listbox.deepSuperficial.Value;
        
        MsgLog(['Cell ', num2str(ii), ' classified as ', cell_metrics.deepSuperficial{ii}]);
        if strcmp(UI.plot.xTitle,'deepSuperficial_num')
            plotX = cell_metrics.deepSuperficial_num;
        end
        if strcmp(UI.plot.yTitle,'deepSuperficial_num')
            plotY = cell_metrics.deepSuperficial_num;
        end
        if strcmp(UI.plot.zTitle,'deepSuperficial_num')
            plotZ = cell_metrics.deepSuperficial_num;
        end
        updatePlotClas
        updateCount
        uiresume(UI.fig);
    end

    function buttonTags(input)
        saveStateToHistory(ii);
        if UI.togglebutton.tag(input).Value == 1
            if isfield(cell_metrics.tags,UI.settings.tags{input})
                cell_metrics.tags.(UI.settings.tags{input}) = unique([cell_metrics.tags.(UI.settings.tags{input}),ii]);
            else
                cell_metrics.tags.(UI.settings.tags{input}) = ii;
            end
            UI.togglebutton.tag(input).FontWeight = 'bold';
            UI.togglebutton.tag(input).ForegroundColor = UI.colors.toggleButtons;
            MsgLog(['Cell ', num2str(ii), ' tag assigned: ', UI.settings.tags{input}]);
        else
            cell_metrics.tags.(UI.settings.tags{input}) = setdiff(cell_metrics.tags.(UI.settings.tags{input}),ii);
            UI.togglebutton.tag(input).FontWeight = 'normal';
            UI.togglebutton.tag(input).ForegroundColor = [0 0 0];
            MsgLog(['Cell ', num2str(ii), ' tag removed: ', UI.settings.tags{input}]);
            
        end
    end

    function buttonTags_minus(input)
        groupData.tags.minus_filter.(UI.settings.tags{input}) = UI.togglebutton.dispTags(input).Value;
        if UI.togglebutton.dispTags(input).Value == 1
            UI.togglebutton.dispTags(input).FontWeight = 'bold';
            UI.togglebutton.dispTags(input).ForegroundColor = UI.colors.toggleButtons;
        else
            UI.togglebutton.dispTags(input).FontWeight = 'normal';
            UI.togglebutton.dispTags(input).ForegroundColor = [0 0 0];
        end
        uiresume(UI.fig);
    end

    function buttonTags_plus(input)
        groupData.tags.plus_filter.(UI.settings.tags{input}) = UI.togglebutton.dispTags2(input).Value;
        if UI.togglebutton.dispTags2(input).Value == 1
            UI.togglebutton.dispTags2(input).FontWeight = 'bold';
            UI.togglebutton.dispTags2(input).ForegroundColor = UI.colors.toggleButtons;
        else
            UI.togglebutton.dispTags2(input).FontWeight = 'normal';
            UI.togglebutton.dispTags2(input).ForegroundColor = [0 0 0];
        end
        uiresume(UI.fig);
    end

    function updateTags
        % Updates tags
        fields1 = fieldnames(cell_metrics.tags);
        for i = 1:numel(UI.settings.tags)
            if ismember(UI.settings.tags{i},fields1) && any(cell_metrics.tags.(UI.settings.tags{i})== ii)
                UI.togglebutton.tag(i).Value = 1;
                UI.togglebutton.tag(i).FontWeight = 'bold';
                UI.togglebutton.tag(i).ForegroundColor = UI.colors.toggleButtons;
            else
                UI.togglebutton.tag(i).Value = 0;
                UI.togglebutton.tag(i).FontWeight = 'normal';
                UI.togglebutton.tag(i).ForegroundColor = [0 0 0];
            end
        end
    end

    function updatePutativeCellType
        % Updates putativeCellType field
        [C, ~, ic] = unique(clusClas,'sorted');
        for i = 1:length(C)
            cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.settings.cellTypes{C(i)}},sum(ic==i),1);
        end
    end

    function updateGroundTruth
        % Updates groundTruth tags
        fields1 = fieldnames(cell_metrics.groundTruthClassification);
        for i = 1:numel(UI.settings.groundTruth)
            if ismember(UI.settings.groundTruth{i},fields1) && any(cell_metrics.groundTruthClassification.(UI.settings.groundTruth{i})== ii)
                UI.togglebutton.groundTruthClassification(i).Value = 1;
                UI.togglebutton.groundTruthClassification(i).FontWeight = 'bold';
                UI.togglebutton.groundTruthClassification(i).ForegroundColor = UI.colors.toggleButtons;
            else
                UI.togglebutton.groundTruthClassification(i).Value = 0;
                UI.togglebutton.groundTruthClassification(i).FontWeight = 'normal';
                UI.togglebutton.groundTruthClassification(i).ForegroundColor = [0 0 0];
            
            end
        end
    end

    function buttonLabel(~,~)
        Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{cell_metrics.labels{ii}});
        if ~isempty(Label)
            saveStateToHistory(ii);
            cell_metrics.labels{ii} = Label{1};
            UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
            MsgLog(['Cell ', num2str(ii), ' labeled as ', Label{1}]);
            [~,ID] = findgroups(cell_metrics.labels);
            groups_ids.labels_num = ID;
            updatePlotClas
            updateCount
            updateColorMenuCount
            buttonGroups(1);
        end
    end

    function buttonBrainRegion(~,~)
        saveStateToHistory(ii)
        
        if isempty(brainRegions_list)
            brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
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
        if strcmp(UI.plot.xTitle,'brainRegion_num')
            plotX = cell_metrics.brainRegion_num;
        end
        if strcmp(UI.plot.yTitle,'brainRegion_num')
            plotY = cell_metrics.brainRegion_num;
        end
        if strcmp(UI.plot.zTitle,'brainRegion_num')
            plotZ = cell_metrics.brainRegion_num;
        end
    end

    function choice = brainRegionDlg(brainRegions,InitBrainRegion)
        choice = '';
        brainRegions_dialog = dialog('Position', [300, 300, 600, 350],'Name','Brain region assignment for current cell','visible','off'); movegui(brainRegions_dialog,'center'), set(brainRegions_dialog,'visible','on')
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

    function advance
        % Advance to next cell in the GUI
        if ~isempty(UI.params.subset) && length(UI.params.subset)>1
            if ii >= UI.params.subset(end)
                ii = UI.params.subset(1);
            else
                ii = UI.params.subset(find(UI.params.subset > ii,1));
            end
        elseif length(UI.params.subset)==1
            ii = UI.params.subset(1);
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

    function plotLegends
        nLegends = -1;
        line(0,0,'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',18,'HitTest','off'), xlim([-0.3,2]), hold on, yticks([]), xticks([])
        line(0,0,'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',16,'HitTest','off');
        text(0.2,0,'Selected cell','HitTest','off')
        if numel(plotClasGroups) >= numel(nanUnique(plotClas(UI.params.subset)))
        legendNames = plotClasGroups(nanUnique(plotClas(UI.params.subset)));
        for i = 1:length(legendNames)
            line(0,nLegends,'Marker','.','LineStyle','none','color',clr_groups(i,:), 'MarkerSize',25,'HitTest','off')
            text(0.2,nLegends,legendNames{i}, 'interpreter', 'none','HitTest','off')
            nLegends = nLegends - 1;
        end
        end
        % Synaptic connections
        switch UI.monoSyn.disp
            case 'All'
                if UI.settings.plotExcitatoryConnections && ~isempty(putativeSubset)
                    line([-0.1,0.1],nLegends*[1,1],'color','k','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'All excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if UI.settings.plotInhibitoryConnections && ~isempty(putativeSubset_inh)
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','k','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'All inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
            case {'Selected','Upstream','Downstream','Up & downstream'}
                if ~isempty(UI.params.inbound) && UI.settings.plotExcitatoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'color','b','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Inbound excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if ~isempty(UI.params.outbound) && UI.settings.plotExcitatoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'color','m','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Outbound excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                % Inhibitory connections
                if ~isempty(UI.params.inbound_inh) && UI.settings.plotInhibitoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','r','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Inbound inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if ~isempty(UI.params.outbound_inh) && UI.settings.plotInhibitoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','c','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Outbound inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
        end
        % Group data
        if ~isempty(groupData)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(groupData,dataTypes{jjj}) && isfield(groupData.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(groupData.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if groupData.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))                            
                            line(0, nLegends,'Marker',UI.settings.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.settings.groupDataMarkers{jj}(2),'LineWidth', 1.5, 'MarkerSize',8,'HitTest','off');
                            text(0.2,nLegends,[fields1{jj},' (',dataTypes{jjj},')'], 'interpreter', 'none','HitTest','off')
                            nLegends = nLegends - 1;
                        end
                    end
                end
            end
        end
        
        % Reference data
        if ~strcmp(UI.settings.referenceData, 'None') % 'Points','Image'
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            legends2plot = unique(referenceData.clusClas(idx));
            for jj = 1:length(legends2plot)
                line(0, nLegends,'Marker','x','LineStyle','none','color',clr_groups2(jj,:),'markersize',8);
                text(0.2,nLegends,referenceData.cellTypes{legends2plot(jj)}, 'interpreter', 'none')
                nLegends = nLegends - 1;
            end
        end
        % Ground truth data
        if ~strcmp(UI.settings.groundTruthData, 'None') % 'Points','Image'
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            legends2plot = unique(groundTruthData.clusClas(idx));
            for jj = 1:length(legends2plot)
                line(0, nLegends,'Marker','x','LineStyle','none','color', clr_groups3(jj,:),'markersize',8);
                text(0.2,nLegends,groundTruthData.groundTruthTypes{legends2plot(jj)}, 'interpreter', 'none')
                nLegends = nLegends - 1;
            end
        end
        % Synaptic cell types
        if UI.settings.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(0, nLegends,'Marker','^','LineStyle','none','color','k');
            text(0.2,nLegends,'Excitatory cells')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(0, nLegends,'Marker','s','LineStyle','none','color','k');
            text(0.2,nLegends,'Inhibitory cells', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(0, nLegends,'Marker','v','LineStyle','none','color','k');
            text(0.2,nLegends,'Cells receiving excitation', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(0, nLegends,'Marker','*','LineStyle','none','color','k');
            text(0.2,nLegends,'Cells receiving inhibition', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        ylim([min(nLegends,-5)+0.5,0.5])
    end

    function plotCharacteristics(cellID)
        nLegends = 0;
        fieldname = {'cellID','spikeGroup','cluID','putativeCellType','peakVoltage','firingRate','troughToPeak'};
        xlim([-2,2]), hold on, yticks([]), xticks([]),
        %         text(0,1.2,'Characteristics','HorizontalAlignment','center','FontWeight', 'Bold')
        for i = 1:length(fieldname)
            text(-0.2,nLegends,fieldname{i},'HorizontalAlignment','right')
            if isnumeric(cell_metrics.(fieldname{i}))
                text(0.2,nLegends,num2str(cell_metrics.(fieldname{i})(cellID)))
            else
                text(0.2,nLegends,cell_metrics.(fieldname{i}){cellID})
            end
            nLegends = nLegends - 1;
        end
        line([0,0],[min(nLegends,-5),0]+0.5,'color','k')
        ylim([min(nLegends,-5)+0.5,0.5])
    end

    function updateLegends(~,~)
        % Updates the legends in the Legends tab with active plot types
        if strcmp(UI.panel.tabgroup2.SelectedTab.Title,'Legend')
            set(UI.fig,'CurrentAxes',UI.axis.legends)
            delete(UI.axis.legends.Children)
            plotLegends
        end
    end

    function createLegend(~,~)
        figure
        plotLegends, title('Legend')
    end

    function advanceClass(ClasIn)
        if ~exist('ClasIn','var')
            ClasIn = plotClas(ii);
        end
        temp = find(ClasIn==plotClas(UI.params.subset));
        temp2 = find(UI.params.subset(temp) > ii,1);
        if ~isempty(temp2)
            ii = UI.params.subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(UI.params.subset(temp) < ii,1))
            ii = UI.params.subset(temp(1));
        else
            MsgLog('No other cells with selected class',2);
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);    
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

    function backClass
        temp = find(plotClas(ii)==plotClas(UI.params.subset));
        temp2 = find(UI.params.subset(temp) < ii,1,'last');
        if ~isempty(temp2)
            ii = UI.params.subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(UI.params.subset(temp) > ii,1))
            ii = UI.params.subset(temp(end));
        else
            MsgLog('No other cells with selected class',2);
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

    function back
        if ~isempty(UI.params.subset) && length(UI.params.subset)>1
            if ii <= UI.params.subset(1)
                ii = UI.params.subset(end);
            else
                ii = UI.params.subset(find(UI.params.subset < ii,1,'last'));
            end
        elseif length(UI.params.subset)==1
            ii = UI.params.subset(1);
        end
        UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
        UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
        UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
        uiresume(UI.fig);
    end

    function buttonACG(src,~)
        if src.Position == 1
            UI.settings.acgType = 'Narrow';
            UI.menu.ACG.window.ops(1).Checked = 'on';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 2
            UI.settings.acgType = 'Normal';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(2).Checked = 'on';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.settings.acgType = 'Wide';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'on';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.settings.acgType = 'Log10';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'on';
        end
        uiresume(UI.fig);
    end

    function initGroupMenu(setting)
        if ischar(UI.settings.(setting))
            idx = find(ismember({UI.menu.display.(setting).ops(:).(menuLabel)},UI.settings.(setting)));
        if isempty(idx)
            UI.menu.display.(setting).ops(1).Checked = 'on';
        else
            UI.menu.display.(setting).ops(idx).Checked = 'on';
        end
        else
            if UI.settings.(setting)
                UI.menu.display.(setting).ops(1).Checked = 'on';
            else
                UI.menu.display.(setting).ops(2).Checked = 'on';
            end
        end
    end

    function buttonACG_normalize(src,~)
        if src.Position == 1
            UI.settings.isiNormalization = 'Rate';
            UI.menu.display.isiNormalization.ops(1).Checked = 'on';
            UI.menu.display.isiNormalization.ops(2).Checked = 'off';
            UI.menu.display.isiNormalization.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.settings.isiNormalization = 'Occurrence';
            UI.menu.display.isiNormalization.ops(1).Checked = 'off';
            UI.menu.display.isiNormalization.ops(2).Checked = 'on';
            UI.menu.display.isiNormalization.ops(3).Checked = 'off';
        elseif src.Position == 3
            UI.settings.isiNormalization = 'Firing rates';
            UI.menu.display.isiNormalization.ops(1).Checked = 'off';
            UI.menu.display.isiNormalization.ops(2).Checked = 'off';
            UI.menu.display.isiNormalization.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustRainCloudNormalizationMenu(src,~)
        if src.Position == 1
            UI.settings.rainCloudNormalization = 'Peak';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'on';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.settings.rainCloudNormalization = 'Probability';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'on';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.settings.rainCloudNormalization = 'Count';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustTrilatGroupData(src,~)
        if src.Position == 1
            UI.settings.trilatGroupData = 'session';
            UI.menu.display.trilatGroupData.ops(1).Checked = 'on';
            UI.menu.display.trilatGroupData.ops(2).Checked = 'off';
            UI.menu.display.trilatGroupData.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.settings.trilatGroupData = 'animal';
            UI.menu.display.trilatGroupData.ops(1).Checked = 'off';
            UI.menu.display.trilatGroupData.ops(2).Checked = 'on';
            UI.menu.display.trilatGroupData.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.settings.trilatGroupData = 'all';
            UI.menu.display.trilatGroupData.ops(1).Checked = 'off';
            UI.menu.display.trilatGroupData.ops(2).Checked = 'off';
            UI.menu.display.trilatGroupData.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end

    function adjustWaveformsAcrossChannelsAlignment(src,~)
        if src.Position == 1
            UI.settings.waveformsAcrossChannelsAlignment = 'Probe layout';
            UI.menu.display.waveformsAcrossChannelsAlignment.ops(1).Checked = 'on';
            UI.menu.display.waveformsAcrossChannelsAlignment.ops(2).Checked = 'off';
        elseif src.Position == 2
            UI.settings.waveformsAcrossChannelsAlignment = 'Electrode groups';
            UI.menu.display.waveformsAcrossChannelsAlignment.ops(1).Checked = 'off';
            UI.menu.display.waveformsAcrossChannelsAlignment.ops(2).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustPlotChannelMapAllChannels(src,~)
        if src.Position == 1
            UI.settings.plotChannelMapAllChannels = true;
            UI.menu.display.plotChannelMapAllChannels.ops(1).Checked = 'on';
            UI.menu.display.plotChannelMapAllChannels.ops(2).Checked = 'off';
        elseif src.Position == 2
            UI.settings.plotChannelMapAllChannels = false;
            UI.menu.display.plotChannelMapAllChannels.ops(1).Checked = 'off';
            UI.menu.display.plotChannelMapAllChannels.ops(2).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function buttonMonoSyn(src,~)
        UI.menu.monoSyn.showConn.ops(1).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(2).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(3).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(4).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(5).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(6).Checked = 'off';
        if src.Position == 6
            UI.monoSyn.disp = 'None';
        elseif src.Position == 7
            UI.monoSyn.disp = 'Selected';
        elseif src.Position == 8
            UI.monoSyn.disp = 'Upstream';
        elseif src.Position == 9
            UI.monoSyn.disp = 'Downstream';
        elseif src.Position == 10
            UI.monoSyn.disp = 'Up & downstream';
        elseif src.Position == 11
            UI.monoSyn.disp = 'All';
        end
        UI.menu.monoSyn.showConn.ops(src.Position-5).Checked = 'on';
        uiresume(UI.fig);
    end
    
    function togglePlotExcitatoryConnections(src,~)
        if strcmp(src.Checked,'on')
            UI.settings.plotExcitatoryConnections = false;
            UI.menu.monoSyn.plotExcitatoryConnections.Checked = 'Off';
        else
            UI.settings.plotExcitatoryConnections = true;
            UI.menu.monoSyn.plotExcitatoryConnections.Checked = 'On';
        end
        uiresume(UI.fig);
    end
    
    function togglePlotInhibitoryConnections(src,~)
        if strcmp(src.Checked,'on')
            UI.settings.plotInhibitoryConnections = false;
            UI.menu.monoSyn.plotInhibitoryConnections.Checked = 'Off';
        else
            UI.settings.plotInhibitoryConnections = true;
            UI.menu.monoSyn.plotInhibitoryConnections.Checked = 'On';
        end
        uiresume(UI.fig);
    end

    function axnum = getAxisBelowCursor
        temp1 = UI.fig.Position([3,4]);
        temp2 = UI.panel.left.Position(3);
        temp3 = UI.panel.right.Position(3);
        temp4 = get(UI.fig, 'CurrentPoint');
        if temp4(1)> temp2 && temp4(1) < (temp1(1)-temp3)
            fractionalPositionX = (temp4(1) - temp2 ) / (temp1(1)-temp3-temp2);
            fractionalPositionY = (temp4(2) - 26 ) / (temp1(2)-20-26);
            switch UI.settings.layout
                case 1 % GUI: 1+3
                    if fractionalPositionX < 0.7
                        axnum = 1;
                    elseif fractionalPositionX > 0.7
                        axnum = 6-floor(fractionalPositionY*3);
                    end
                case 2 % GUI: 2+3
                    if fractionalPositionY > 0.4
                        if fractionalPositionX<0.5
                            axnum = 1;
                        else
                            axnum = 3;
                        end
                    elseif UI.settings.layout == 2 && fractionalPositionY < 0.4
                        axnum = ceil(fractionalPositionX*3)+3;
                    end
                case 3 % GUI: 3+3
                    if fractionalPositionY > 0.5
                        axnum = ceil(fractionalPositionX*3);
                    elseif fractionalPositionY < 0.5
                        axnum = ceil(fractionalPositionX*3)+3;
                    end
                case 4 % GUI: 3+4
                    if fractionalPositionY > 0.5
                        axnum = ceil(fractionalPositionX*3);
                    elseif fractionalPositionY < 0.5
                        axnum = ceil(fractionalPositionX*3)+3;
                        if fractionalPositionY < 0.25
                            axnum = axnum + 1;
                        end
                    end
                case 5 % GUI: 3+5
                    if fractionalPositionY > 0.5
                        axnum = ceil(fractionalPositionX*3);
                    elseif fractionalPositionY < 0.5
                        axnum = ceil(fractionalPositionX*3)+3;
                        if fractionalPositionY < 0.25 && axnum >= 5
                            axnum = axnum + 2;
                        end
                    end
                case 6 % GUI: 3+6
                    if fractionalPositionY > 0.66
                        axnum = ceil(fractionalPositionX*3);
                    elseif fractionalPositionY > 0.33
                        axnum = ceil(fractionalPositionX*3)+3;
                    elseif fractionalPositionY < 0.33
                        axnum = ceil(fractionalPositionX*3)+6;
                    end
                case 7 % GUI: 1+6
                    if fractionalPositionX < 0.5
                        axnum = 1;
                    elseif fractionalPositionX > 0.5 && fractionalPositionX < 0.75
                        axnum = 6-floor(fractionalPositionY*3);
                    else
                        axnum = 9-floor(fractionalPositionY*3);
                    end
                otherwise
                    axnum = 1;
            end
        elseif temp4(1) < temp2
            if temp4(2) < UI.panel.tabgroup2.Position(4)*temp1(2)
                axnum = 10;
            else
                axnum = [];
            end
        else
            axnum = [];
        end
    end

    function ScrolltoZoomInPlot(h,event,direction)
        % Called when scrolling/zooming
        % Checks first, if a plot is underneath the curser
        axnum = getAxisBelowCursor;
        
        if isfield(UI,'panel') && ~isempty(axnum)
            if axnum == 10
                handle34 = UI.axis.legends;
            else
                handle34 = subfig_ax(axnum);
            end
            um_axes = get(handle34,'CurrentPoint');
            UI.zoom.twoAxes = 0;
            
            % If ScrolltoZoomInPlot is called by a keypress, the underlying
            % mouse position must be determined by the WindowButtonMotionFcn
            if exist('direction','var')
                set(gcf,'WindowButtonMotionFcn', @hoverCallback);
            end
            u = um_axes(1,1);
            v = um_axes(1,2);
            w = um_axes(1,2);
            
            set(UI.fig,'CurrentAxes',handle34)
            b = get(handle34,'Xlim');
            c = get(handle34,'Ylim');
            d = get(handle34,'Zlim');
            
            % Saves the initial axis limits and linear/log axis settings
            if isempty(UI.zoom.global{axnum})
                UI.zoom.global{axnum} = [b;c;d];
                if axnum == 1
                    UI.zoom.globalLog{axnum} = [UI.checkbox.logx.Value,UI.checkbox.logy.Value,UI.checkbox.logz.Value];
                elseif axnum == 2
                    UI.zoom.globalLog{axnum} = [0,1,0];
                else
                    UI.zoom.globalLog{axnum} = [0,0,0];
                end
            end
            if axnum == 2 && (strcmp(UI.settings.referenceData, 'Image') || strcmp(UI.settings.groundTruthData, 'Image'))
                UI.zoom.twoAxes = 1;
            elseif axnum == 1  && UI.settings.customPlotHistograms < 3 && UI.checkbox.logy.Value == 1 && UI.checkbox.logx.Value == 0 && (strcmp(UI.settings.referenceData, 'Image') || strcmp(UI.settings.groundTruthData, 'Image'))
                UI.zoom.twoAxes = 1;
            end
            zoomInFactor = 0.85;
            zoomOutFactor = 1.6;
            
            globalZoom1 = UI.zoom.global{axnum};
            globalZoomLog1 = UI.zoom.globalLog{axnum};
            cursorPosition = [u;v;w];
            axesLimits = [b;c;d];
            if any(globalZoomLog1 == 1)
                idx = find(globalZoomLog1==1);
                cursorPosition(idx) = log10(cursorPosition(idx));
                globalZoom1(idx,:) = log10(globalZoom1(idx,:));
                axesLimits(idx,:) = log10(axesLimits(idx,:));
            end
            
            % Applies global/horizontal/vertical zoom according to the mouse position.
            % Further applies zoom direction according to scroll-wheel direction
            % Zooming out have global boundaries set by the initial x/y limits
            if ~exist('direction','var')
                if event.VerticalScrollCount<0
                    direction = 1;% positive scroll direction (zoom out)
                else
                    direction = -1; % Negative scroll direction (zoom in)
                end
            end
            if axnum == 10
                applyZoom(globalZoom1,[-100,cursorPosition(2),0],axesLimits,globalZoomLog1,direction);
            elseif UI.zoom.twoAxes == 1 && ~(axnum == 1 && (UI.settings.customPlotHistograms == 2 || strcmp(UI.settings.referenceData, 'Histogram') || strcmp(UI.settings.groundTruthData, 'Histogram')))
                applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
                yyaxis left
                globalZoom1(2,:) = globalZoom1(2,:);
                axesLimits(2,:) = axesLimits(2,:);
                applyZoom(globalZoom1,cursorPosition,axesLimits,[0 0 0],direction);
                yyaxis right
            elseif axnum == 1 && (UI.settings.customPlotHistograms == 2 || strcmp(UI.settings.referenceData, 'Histogram') || strcmp(UI.settings.groundTruthData, 'Histogram'))
                if UI.zoom.twoAxes == 1
                    applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
                    yyaxis left
                    globalZoom1(2,:) = globalZoom1(2,:);
                    axesLimits(2,:) = axesLimits(2,:);
                    applyZoom(globalZoom1,cursorPosition,axesLimits,[0 0 0],direction);
                    yyaxis right
                else
                    applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
                end
                % Double kernel-histograms
                set(UI.fig,'CurrentAxes',h_scatter(2))
                applyZoom([globalZoom1(1,:);0,1;0,1],[cursorPosition(1),inf,0],[axesLimits(1,:);0,1;0,1],[globalZoomLog1(1),0,0],direction);
                set(UI.fig,'CurrentAxes',h_scatter(3))
                applyZoom([globalZoom1(2,:);0,1;0,1],[cursorPosition(2),inf,0],[axesLimits(2,:);0,1;0,1],[globalZoomLog1(2),0,0],direction);
            else
                applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
            end
        end
        
        function applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction)
            u = cursorPosition(1);
            v = cursorPosition(2);
            w = cursorPosition(3);
            b = axesLimits(1,:);
            c = axesLimits(2,:);
            d = axesLimits(3,:);
            
            if direction == 1 % zoom in
                
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1 && globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 && globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1 && globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 && globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1 && globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 && globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1 && globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 && globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                    z1 = max(globalZoom1(3,1),w-diff(d)/2*zoomInFactor);
                    z2 = min(globalZoom1(3,2),w+diff(d)/2*zoomInFactor);
                    if z2>z1 && globalZoomLog1(3)==0
                    elseif z2>z1 && globalZoomLog1(3)==1
                        zlim(10.^[z1,z2]);
                    end
                end
            elseif direction == -1
                % Positive scrolling direction (zoom out)
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomOutFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomOutFactor);
                    if y1 == globalZoom1(2,1)
                        y2 = min([globalZoom1(2,2),y1 + diff(c)*2]);
                    end
                    if y2 == globalZoom1(2,2)
                        y1 = max([globalZoom1(2,1),y2 - diff(c)*2]);
                    end
                    if y2>y1 && globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 && globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomOutFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomOutFactor);
                    if x1 == globalZoom1(1,1)
                        x2 = min([globalZoom1(1,2),x1 + diff(b)*2]);
                    end
                    if x2 == globalZoom1(1,2)
                        x1 = max([globalZoom1(1,1),x2 - diff(b)*2]);
                    end
                    if x2>x1 && globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 && globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomOutFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomOutFactor);
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomOutFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomOutFactor);
                    z1 = max(globalZoom1(3,1),w-diff(d)/2*zoomOutFactor);
                    z2 = min(globalZoom1(3,2),w+diff(d)/2*zoomOutFactor);
                    
                    if x1 == globalZoom1(1,1)
                        x2 = min([globalZoom1(1,2),x1 + diff(b)*2]);
                    end
                    if x2 == globalZoom1(1,2)
                        x1 = max([globalZoom1(1,1),x2 - diff(b)*2]);
                    end
                    if y1 == globalZoom1(2,1)
                        y2 = min([globalZoom1(2,2),y1 + diff(c)*2]);
                    end
                    if y2 == globalZoom1(2,2)
                        y1 = max([globalZoom1(2,1),y2 - diff(c)*2]);
                    end
                    
                    if z1 == globalZoom1(3,1)
                        z2 = min([globalZoom1(3,2),z1 + diff(d)*2]);
                    end
                    if z2 == globalZoom1(3,2)
                        z1 = max([globalZoom1(3,1),z2 - diff(d)*2]);
                    end
                    
                    if x2>x1 && globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 && globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                    if y2>y1 && globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 && globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                    if z2>z1 && globalZoomLog1(3)==0
                    elseif z2>z1 && globalZoomLog1(3)==1
                        zlim(10.^[z1,z2]);
                    end
                end
            else
                % Reset zoom
                xlim(globalZoom1(1,:));
                ylim(globalZoom1(2,:));
                zlim(globalZoom1(3,:));
            end
        end
    end

    function hoverCallback(~,~)
        
    end

    function [u,v] = ClicktoSelectFromPlot(~,~)
        % Handles mouse clicks on the plots. Determines the selected plot
        % and the coordinates (u,v) within the plot. Finally calls
        % according to which mouse button that was clicked.
        axnum = find(ismember(subfig_ax, gca));
        um_axes = get(gca,'CurrentPoint');
        u = um_axes(1,1);
        v = um_axes(1,2);
        if clickPlotRegular
            
            switch get(UI.fig, 'selectiontype')
                case 'normal'
                    if ~isempty(UI.params.subset)
                        SelectFromPlot(u,v);
                    else
                        MsgLog(['No cells with selected classification']);
                    end
                case 'alt'
                    if ~isempty(UI.params.subset)
                        HighlightFromPlot(u,v,0);
                    end
                case 'extend'
                    polygonSelection
            end
        else
            c = [u,v];
            sel = get(UI.fig, 'SelectionType');
            
            if strcmpi(sel, 'alt')
                if ~isempty(polygon1.coords)
                    hold on,
                    polygon1.handle(polygon1.counter+1) = line([polygon1.coords(:,1);polygon1.coords(1,1)],[polygon1.coords(:,2);polygon1.coords(1,2)],'Marker','.','color','k', 'HitTest','off');
                end
                if polygon1.counter > 0
                    polygon1.cleanExit = 1;
                end
                clickPlotRegular = true;
                set(UI.fig,'Pointer','arrow')
                GroupSelectFromPlot
                set(polygon1.handle(find(ishandle(polygon1.handle))),'Visible','off');
                
            elseif strcmpi(sel, 'extend') && polygon1.counter > 0
                polygon1.coords = polygon1.coords(1:end-1,:);
                set(polygon1.handle(polygon1.counter),'Visible','off');
                polygon1.counter = polygon1.counter-1;
                
            elseif strcmpi(sel, 'extend') && polygon1.counter == 0
                clickPlotRegular = true;
                set(UI.fig,'Pointer','arrow')
                
            elseif strcmpi(sel, 'normal')
                polygon1.coords = [polygon1.coords;c];
                polygon1.counter = polygon1.counter +1;
                polygon1.handle(polygon1.counter) = line(polygon1.coords(:,1),polygon1.coords(:,2),'Marker','.','color','k','HitTest','off');
            end
        end
    end

    function polygonSelection(~,~)
        clickPlotRegular = false;
        MsgLog('Select cells by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.');
        %         if UI.settings.plot3axis
        %             rotate3d(subfig_ax(1),'off')
        %         end
        ax = get(UI.fig,'CurrentAxes');
        hold(ax, 'on');
        polygon1.counter = 0;
        polygon1.cleanExit = 0;
        polygon1.coords = [];
        set(UI.fig,'Pointer','crosshair')
    end

    function toggleStickySelection(~,~)
        if UI.settings.stickySelection
            UI.settings.stickySelection = false;
            UI.menu.cellSelection.stickySelection.Checked = 'off';
            uiresume(UI.fig);
        else
            UI.settings.stickySelection = true;
            UI.menu.cellSelection.stickySelection.Checked = 'on';
        end
    end

    function toggleStickySelectionReset(~,~)
        UI.params.ClickedCells = [];
        uiresume(UI.fig);
    end

    function ClicktoSelectFromTable(~,event)
        % Called when a table-cell is clicked in the table. Changes to
        % custom display according what metric is clicked. First column
        % updates x-axis and second column updates the y-axis
        
        if UI.settings.metricsTable==1 && ~isempty(event.Indices) && size(event.Indices,1) == 1
            if event.Indices(2) == 1
                UI.popupmenu.xData.Value = find(contains(fieldsMenu,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.xData);
                buttonPlotX;
            elseif event.Indices(2) == 2
                UI.popupmenu.yData.Value = find(contains(fieldsMenu,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.yData);
                buttonPlotY;
            end
            
        elseif UI.settings.metricsTable==2 && ~isempty(event.Indices) && event.Indices(2) > 1 && size(event.Indices,1) == 1
            % Goes to selected cell
            ii = UI.params.subset(tableDataOrder(event.Indices(1)));
            uiresume(UI.fig);
        end
    end

    function EditSelectFromTable(~, event)
        if any(UI.params.ClickedCells == UI.params.subset(tableDataOrder(event.Indices(1))))
            UI.params.ClickedCells = UI.params.ClickedCells(~(UI.params.ClickedCells == UI.params.subset(tableDataOrder(event.Indices(1)))));
        else
            UI.params.ClickedCells = [UI.params.ClickedCells,UI.params.subset(tableDataOrder(event.Indices(1)))];
        end
        if length(UI.params.ClickedCells)<21
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(UI.params.ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(UI.params.ClickedCells(1:20)),'\s+',', ')), ' ...'];
        end
    end

    function updateTableClickedCells
        if UI.settings.metricsTable==2
            % UI.table.Data(:,1) = {false};
            [~,ia,~] = intersect(UI.params.subset(tableDataOrder),UI.params.ClickedCells);
            UI.table.Data(ia,1) = {true};
        end
        if length(UI.params.ClickedCells)<21
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(UI.params.ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(UI.params.ClickedCells(1:20)),'\s+',', ')), ' ...'];
        end
    end

    function highlightSelectedCells
        if UI.settings.customPlotHistograms == 3
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells), plotZ(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.settings.customPlotHistograms == 1
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.settings.customPlotHistograms == 4
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY1(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.settings.customPlotHistograms == 2
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        end
        set(UI.fig,'CurrentAxes',subfig_ax(2))
        line(cell_metrics.troughToPeak(UI.params.ClickedCells)*1000,cell_metrics.burstIndex_Royer2012(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        
        set(UI.fig,'CurrentAxes',subfig_ax(3))
        line(tSNE_metrics.plot(UI.params.ClickedCells,1),tSNE_metrics.plot(UI.params.ClickedCells,2),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
        
        % Highlighting waveforms
        
        if any(strcmp(UI.settings.customPlot,'Waveforms (all)'))
            if UI.settings.zscoreWaveforms == 1
                zscoreWaveforms1 = 'filt_zscored';
            else
                zscoreWaveforms1 = 'filt_absolute';
            end
            idx = find(strcmp(UI.settings.customPlot,'Waveforms (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(time_waveforms_zscored,cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting raw waveforms
        if any(strcmp(UI.settings.customPlot,'Raw waveforms (all)'))
            if UI.settings.zscoreWaveforms == 1
                zscoreWaveforms1 = 'raw_zscored';
            else
                zscoreWaveforms1 = 'raw_absolute';
            end
            idx = find(strcmp(UI.settings.customPlot,'Raw waveforms (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(time_waveforms_zscored,cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting ACGs
        if any(strcmp(UI.settings.customPlot,'ACGs (all)'))
            idx = find(strcmp(UI.settings.customPlot,'ACGs (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                if strcmp(UI.settings.acgType,'Normal')
                    line([-100:100]/2,cell_metrics.acg.narrow(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.settings.acgType,'Narrow')
                    line([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.settings.acgType,'Log10')
                    line(general.acgs.log10,cell_metrics.acg.log10(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                else
                    line([-500:500],cell_metrics.acg.wide(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                end
            end
        end
        % Highlighting ISIs
        if any(strcmp(UI.settings.customPlot,'ISIs (all)'))
            idx = find(strcmp(UI.settings.customPlot,'ISIs (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                if strcmp(UI.settings.isiNormalization,'Rate')
                    line(general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    line(1./general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells).*(diff(10.^UI.settings.ACGLogIntervals))','linewidth',2, 'HitTest','off')
                else
                    line(general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells).*(diff(10.^UI.settings.ACGLogIntervals))','linewidth',2, 'HitTest','off')
                end
            end
        end
        % Highlighting response curves (e.g. theta) 'RCs_thetaPhase (all)'
        if any(strcmp(UI.settings.customPlot,'RCs_thetaPhase (all)'))
            x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
            y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
            idx = find(strcmp(UI.settings.customPlot,'RCs_thetaPhase (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(x1(:,UI.params.ClickedCells),y1(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting firing rate curves 
        if any(strcmp(UI.settings.customPlot,'RCs_firingRateAcrossTime (all)'))
            idx = find(strcmp(UI.settings.customPlot,'RCs_firingRateAcrossTime (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(UI.subsetPlots{idx}.xaxis,UI.subsetPlots{idx}.yaxis(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
    end

    function iii = FromPlot(u,v,highlight,w)
        iii = 0;
        if ~exist('highlight','var')
            highlight = 0;
        end
        if highlight
            iLine = mod(iLine,7)+1;
            colorLine = UI.colorLine(iLine,:);
        end
        axnum = find(ismember(subfig_ax, gca));
        if isempty(axnum)
            axnum = 1;
        end
        if axnum == 1 && UI.settings.customPlotHistograms == 3
            [azimuth,elevation] = view;
                r  = 10000;
                y1 = -r .* cosd(elevation) .* cosd(azimuth);
                x1 = r .* cosd(elevation) .* sind(azimuth);
                z1 = r .* sind(elevation);
                if UI.checkbox.logx.Value == 1
                    x_scale = range(log10(plotX(plotX>0 & ~isinf(plotX))));
                    u = log10(u);
                    plotX11 = log10(plotX(UI.params.subset));
                else
                    x_scale = range(plotX(~isinf(plotX)));
                    plotX11 = plotX(UI.params.subset);
                end
                if UI.checkbox.logy.Value == 1
                    y_scale = range(log10(plotY(plotY>0 & ~isinf(plotY))));
                    v = log10(v);
                    plotY11 = log10(plotY(UI.params.subset));
                else
                    y_scale = range(plotY(~isinf(plotY)));
                    plotY11 = plotY(UI.params.subset);
                end
                if UI.checkbox.logz.Value == 1
                    z_scale = range(log10(plotZ(plotZ>0 & ~isinf(plotZ))));
                    w = log10(w);
                    plotZ11 = log10(plotZ(UI.params.subset));
                else
                    z_scale = range(plotZ( ~isinf(plotZ)));
                    plotZ11 = plotZ(UI.params.subset);
                end
                distance = point_to_line_distance([plotX11; plotY11; plotZ11]'./[x_scale y_scale z_scale], [u,v,w]./[x_scale y_scale z_scale], ([u,v,w]./[x_scale y_scale z_scale]+[x1,y1,z1]));
                [~,idx] = min(distance);
                iii = UI.params.subset(idx);
                if highlight == 1
                    text(plotX(iii),plotY(iii),plotZ(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    line(plotX(iii),plotY(iii),plotZ(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                else
                    return
                end
        elseif axnum == 1 && UI.settings.customPlotHistograms < 4
            if UI.checkbox.logx.Value == 1 && UI.checkbox.logy.Value == 1
                x_scale = range(log10(plotX(plotX>0 & ~isinf(plotX))));
                y_scale = range(log10(plotY(plotY>0 & ~isinf(plotY))));
                [~,idx] = min(hypot((log10(plotX(UI.params.subset))-log10(u))/x_scale,(log10(plotY(UI.params.subset))-log10(v))/y_scale));
            elseif UI.checkbox.logx.Value == 1 && UI.checkbox.logy.Value == 0
                x_scale = range(log10(plotX(plotX>0 & ~isinf(plotX))));
                y_scale = range(plotY(~isinf(plotY)));
                [~,idx] = min(hypot((log10(plotX(UI.params.subset))-log10(u))/x_scale,(plotY(UI.params.subset)-v)/y_scale));
            elseif UI.checkbox.logx.Value == 0 && UI.checkbox.logy.Value == 1
                x_scale = range(plotX(~isinf(plotX)));
                y_scale = range(log10(plotY(plotY>0 & ~isinf(plotY))));
                [~,idx] = min(hypot((plotX(UI.params.subset)-u)/x_scale,(log10(plotY(UI.params.subset))-log10(v))/y_scale));
            else
                x_scale = range(plotX(~isinf(plotX)));
                y_scale = range(plotY(~isinf(plotY)));
                [~,idx] = min(hypot((plotX(UI.params.subset)-u)/x_scale,(plotY(UI.params.subset)-v)/y_scale));
            end
            iii = UI.params.subset(idx);
            if highlight
                text(plotX(iii),plotY(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                line(plotX(iii),plotY(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
            end
            
        elseif axnum == 1 && UI.settings.customPlotHistograms == 4
            if UI.checkbox.logx.Value == 1
                x_scale = range(log10(plotX(plotX>0 & ~isinf(plotX))));
                y_scale = range(plotY1(~isinf(plotY1)));
                [~,idx] = min(hypot((log10(plotX(UI.params.subset))-log10(u))/x_scale,(plotY1(UI.params.subset)-v)/y_scale));
            else
                x_scale = range(plotX(~isinf(plotX)));
                y_scale = range(plotY1(~isinf(plotY1)));
                [~,idx] = min(hypot((plotX(UI.params.subset)-u)/x_scale,(plotY1(UI.params.subset)-v)/y_scale));
            end
            iii = UI.params.subset(idx);
            if highlight
                text(plotX(iii),plotY1(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                line(plotX(iii),plotY1(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
            end
            
        elseif axnum == 2
            x_scale = range(cell_metrics.troughToPeak)*1000;
            y_scale = range(log10(cell_metrics.burstIndex_Royer2012(find(cell_metrics.burstIndex_Royer2012>0 & cell_metrics.burstIndex_Royer2012<Inf))));
            [~,idx] = min(hypot((cell_metrics.troughToPeak(UI.params.subset)*1000-u)/x_scale,(log10(cell_metrics.burstIndex_Royer2012(UI.params.subset))-log10(v))/y_scale));
            iii = UI.params.subset(idx);
            
            if highlight
                text(cell_metrics.troughToPeak(iii)*1000,cell_metrics.burstIndex_Royer2012(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                line(cell_metrics.troughToPeak(iii)*1000,cell_metrics.burstIndex_Royer2012(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
            end
            
        elseif axnum == 3
            [~,idx] = min(hypot(tSNE_metrics.plot(UI.params.subset,1)-u,tSNE_metrics.plot(UI.params.subset,2)-v));
            iii = UI.params.subset(idx);
            if highlight
                text(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                line(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
            end
            
        elseif any(axnum == [4,5,6,7,8,9])
            
            selectedOption = UI.settings.customPlot{axnum-3};
            subsetPlots = UI.subsetPlots{axnum-3};
            
            switch selectedOption
                case 'Waveforms (tSNE)'
                    [~,idx] = min(hypot(tSNE_metrics.filtWaveform(UI.params.subset,1)-u,tSNE_metrics.filtWaveform(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.filtWaveform(iii,1),tSNE_metrics.filtWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'Raw waveforms (tSNE)'
                    [~,idx] = min(hypot(tSNE_metrics.rawWaveform(UI.params.subset,1)-u,tSNE_metrics.rawWaveform(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.rawWaveform(iii,1),tSNE_metrics.rawWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'Waveforms (single)'
                    if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0);
                        x_scale = range(out(1,:));
                        y_scale = range(out(2,:));
                        [~,In] = min(hypot((out(1,:)-u)/x_scale,(out(2,:)-v)/y_scale));
                        iii = out(3,In);
                        if highlight
                            text(out(1,In),out(2,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                            line(out(1,In),out(2,In),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                        end
                    else
                        showWaveformMetrics;
                    end
                    
                case 'Waveforms (all)'
                    if UI.settings.zscoreWaveforms == 1
                        zscoreWaveforms1 = 'filt_zscored';
                    else
                        zscoreWaveforms1 = 'filt_absolute';
                    end
                    x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                    
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    
                    if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0);
                        x2 = [x1(:);out(1,:)'];
                        y2 = y1(:);
                        y3 = [y2;out(2,:)'];
                        
                        [~,In] = min(hypot((x2-u)/x_scale,(y3-v)/y_scale));
                        if In > length(y2)
                            iii = out(3,In-length(y2));
                            if highlight
                            text(out(1,In-length(y2)),out(2,In-length(y2)),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                            line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            In = find(UI.params.subset==iii);
                        else
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            iii = UI.params.subset(In);
                        end
                        [~,time_index] = min(abs(time_waveforms_zscored-u));
                    else
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                        In = unique(floor(In/length(time_waveforms_zscored)))+1;
                        iii = UI.params.subset(In);
                        [~,time_index] = min(abs(time_waveforms_zscored-u));
                    end
                    if highlight
                        line(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                case 'Raw waveforms (single)'    
                    if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0);
                        x_scale = range(out(1,:));
                        y_scale = range(out(2,:));
                        [~,In] = min(hypot((out(1,:)-u)/x_scale,(out(2,:)-v)/y_scale));
                        iii = out(3,In);
                        if highlight
                            text(out(1,In),out(2,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                            line(out(1,In),out(2,In),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                        end
                    end
                case 'Raw waveforms (all)'
                    if UI.settings.zscoreWaveforms == 1
                        zscoreWaveforms1 = 'raw_zscored';
                    else
                        zscoreWaveforms1 = 'raw_absolute';
                    end
                    x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    
                    if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0);
                        x2 = [x1(:);out(1,:)'];
                        y2 = y1(:);
                        y3 = [y2;out(2,:)'];
                        
                        [~,In] = min(hypot((x2-u)/x_scale,(y3-v)/y_scale));
                        if In > length(y2)
                            iii = out(3,In-length(y2));
                            if highlight
                            text(out(1,In-length(y2)),out(2,In-length(y2)),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                            line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            In = find(UI.params.subset==iii);
                        else
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            iii = UI.params.subset(In);
                        end
                        [~,time_index] = min(abs(time_waveforms_zscored-u));
                    else
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                        In = unique(floor(In/length(time_waveforms_zscored)))+1;
                        iii = UI.params.subset(In);
                        [~,time_index] = min(abs(time_waveforms_zscored-u));
                    end
                    
                    if highlight
                        line(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'Waveforms (image)'
                    [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(troughToPeakSorted(round(v)));
                        if highlight
                            line([time_waveforms_zscored(1),time_waveforms_zscored(end)],[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                        end
                    end
                    
                case 'Waveforms (across channels)'
                    % All waveforms across channels with largest ampitude colored according to cell type
                    if highlight
                        factors = [90,60,40,25,15,10,6,4];
                        idx5 = find(UI.params.chanCoords.y_factor == factors);
                        idx5 = rem(idx5,length(factors))+1;
                        UI.params.chanCoords.y_factor = factors(idx5);
                        MsgLog(['Waveform y-factor altered: ' num2str(UI.params.chanCoords.y_factor)]);
                    else
                        factors = [4,6,10,16,25,40,60,90];
                        idx5 = find(UI.params.chanCoords.x_factor==factors);
                        idx5 = rem(idx5,length(factors))+1;
                        UI.params.chanCoords.x_factor = factors(idx5);
                        MsgLog(['Waveform x-factor altered: ' num2str(UI.params.chanCoords.x_factor)]);
                    end
                    uiresume(UI.fig);
                    
                case 'Trilaterated position'
                    switch UI.settings.trilatGroupData
                        case 'session'
                            subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                            subset1 = UI.params.subset(subset1);
                        case 'animal'
                            subset1 = ismember(cell_metrics.animal(UI.params.subset),cell_metrics.animal{ii});
                            subset1 = UI.params.subset(subset1);
                        otherwise
                            subset1 = UI.params.subset;
                    end
                    x1 = cell_metrics.trilat_x(subset1);
                    y1 = cell_metrics.trilat_y(subset1);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,idx] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    iii = subset1(idx);
                    if highlight
                        text(cell_metrics.trilat_x(iii),cell_metrics.trilat_y(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'tSNE of narrow ACGs'
                    [~,idx] = min(hypot(tSNE_metrics.acg_narrow(UI.params.subset,1)-u,tSNE_metrics.acg_narrow(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_narrow(iii,1),tSNE_metrics.acg_narrow(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'tSNE of wide ACGs'
                    [~,idx] = min(hypot(tSNE_metrics.acg_wide(UI.params.subset,1)-u,tSNE_metrics.acg_wide(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_wide(iii,1),tSNE_metrics.acg_wide(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'tSNE of log ACGs'
                    [~,idx] = min(hypot(tSNE_metrics.acg_log10(UI.params.subset,1)-u,tSNE_metrics.acg_log10(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_log10(iii,1),tSNE_metrics.acg_log10(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'tSNE of log ISIs'
                    [~,idx] = min(hypot(tSNE_metrics.isi_log10(UI.params.subset,1)-u,tSNE_metrics.isi_log10(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.isi_log10(iii,1),tSNE_metrics.isi_log10(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'CCGs (image)'
                    if isfield(general,'ccg')
                        if UI.BatchMode
                            subset2 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                        else
                            subset2 = 1:general.cellCount;
                        end
                        subset1 = cell_metrics.UID(subset2);
                        subset1 = [cell_metrics.UID(ii),subset1(subset1~=cell_metrics.UID(ii))];
                        subset2 = [ii,subset2(subset2~=ii)];
                        if round(v) > 0 && round(v) <= max(subset2)
                            iii = subset2(round(v));
                            if highlight
                                if strcmp(UI.settings.acgType,'Narrow')
                                    Xdata = [-30,30]/2;
                                else
                                    Xdata = [-100,100]/2;
                                end
                                line(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                                text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                            end
                        end
                    end
                    
                case 'ACGs (single)'
                    if highlight
                        toggleACGfit
                    else
                        switch UI.settings.acgType
                            case 'Normal'
                                src.Position = 3;
                            case 'Narrow'
                                src.Position = 2;
                            case 'Wide'
                                src.Position = 4;
                            case 'Log10'
                                src.Position = 1;
                        end
                        buttonACG(src);
                    end
        
                case 'ACGs (image)'
                    [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(burstIndexSorted(round(v)));
                        if highlight
                            if strcmp(UI.settings.acgType,'Normal')
                                Xdata = [-100,100]/2;
                            elseif strcmp(UI.settings.acgType,'Narrow')
                                Xdata = [-30,30]/2;
                            elseif strcmp(UI.settings.acgType,'Log10')
                                Xdata = log10(general.acgs.log10([1,end]));
                            else
                                Xdata = [-500,500];
                            end
                            line(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                        end
                    end
                    
                case 'ACGs (all)'
                    if strcmp(UI.settings.acgType,'Normal')
                        x2 = [-100:100]/2;
                        x1 = ([-100:100]/2)'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.narrow(:,UI.params.subset);
                    elseif strcmp(UI.settings.acgType,'Narrow')
                        x2 = [-30:30]/2;
                        x1 = ([-30:30]/2)'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.narrow(41+30:end-40-30,UI.params.subset);
                    elseif strcmp(UI.settings.acgType,'Log10')
                        x2 = general.acgs.log10;
                        x1 = (general.acgs.log10)*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.log10(:,UI.params.subset);
                    else
                        x2 = [-500:500];
                        x1 = ([-500:500])'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.wide(:,UI.params.subset);
                    end
                    y_scale = range(y1(:));
                    if strcmp(UI.settings.acgType,'Log10')
                        x_scale = range(log10(x1(:)));
                        [~,In] = min(hypot((log10(x1(:))-log10(u))/x_scale,(y1(:)-v)/y_scale));
                    else
                        x_scale = range(x1(:));
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    end
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = UI.params.subset(In);
                    if highlight
                        [~,time_index] = min(abs(x2-u));
                        line(x2(:),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(x2(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'ISIs (single)'
                        switch UI.settings.isiNormalization
                            case 'Rate'
                                src.Position = 9;
                            case 'Occurrence'
                                src.Position = 10;
                            otherwise % 'Firing rates'
                                src.Position = 8;
                        end
                        buttonACG_normalize(src)
                    
                case 'ISIs (all)'
                    x2 = general.isis.log10;
                    x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                    if strcmp(UI.settings.isiNormalization,'Rate')
                        y1 = cell_metrics.isi.log10(:,UI.params.subset);
                    elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                        x2 = 1./general.isis.log10;
                        x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.settings.ACGLogIntervals))';
                    else
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.settings.ACGLogIntervals))';
                    end
                    x_scale = range(log10(x1(:)));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((log10(x1(:))-log10(u))/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = UI.params.subset(In);
                    if highlight
                        [~,time_index] = min(abs(x2-u));
                        line(x2(:),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(x2(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'ISIs (image)'
                    [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(burstIndexSorted(round(v)));
                        if highlight
                            if strcmp(UI.settings.isiNormalization,'Firing rates')
                                line(1./log10(1./general.isis.log10([1,end])),[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','HitTest','off','linewidth',2)
                            else
                                line(log10(general.isis.log10([1,end])),[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','HitTest','off','linewidth',2)
                            end
%                             line(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                        end
                    end
                    
                case 'RCs_thetaPhase (all)'
                    x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/length(UI.x_bins.thetaPhase)))+1;
                    iii = UI.params.subset(In);
                    [~,time_index] = min(abs(UI.x_bins.thetaPhase-u));
                    if highlight
                        line(UI.x_bins.thetaPhase,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(UI.x_bins.thetaPhase(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'RCs_firingRateAcrossTime (all)'
                    subset1 = subsetPlots.subset;
                    x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                    y1 = subsetPlots.yaxis;
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/length(subsetPlots.xaxis)))+1;
                    iii = subset1(In);
                    [~,time_index] = min(abs(subsetPlots.xaxis-u));
                    if highlight
                        line(subsetPlots.xaxis,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                        text(subsetPlots.xaxis(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                    end
                    
                case 'RCs_thetaPhase (image)'
                    [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(troughToPeakSorted(round(v)));
                        if highlight
                            line([UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                        end
                    end
                    
                case 'RCs_firingRateAcrossTime (image)'
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        if UI.BatchMode
                            subset23 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                        else
                            subset23 = 1:general.cellCount;
                        end
                        [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(subset23));
                        iii = subset23((burstIndexSorted((round(v)))));
                        
                        if highlight
                            Xdata = general.responseCurves.firingRateAcrossTime.x_edges([1,end]);
                            line(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1)
                        end
                    end
                    
                case 'Connectivity graph'
                    if ~isempty(subsetPlots)
                        [~,idx] = min(hypot(subsetPlots.xaxis-u,subsetPlots.yaxis-v));
                        iii = subsetPlots.subset(idx);
                        if highlight
                            text(subsetPlots.xaxis(idx),subsetPlots.yaxis(idx),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                        end
                    end
                otherwise
                    if any(strcmp(UI.monoSyn.disp,{'All','Selected','Upstream','Downstream','Up & downstream'})) && ~isempty(subsetPlots) && ~isempty(subsetPlots.subset)
                            subset1 = subsetPlots.subset;
                            x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                            y1 = subsetPlots.yaxis;
                            x_scale = range(subsetPlots.xaxis(:));
                            y_scale = range(y1(:));
                            [~,time_index] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                            In = unique(floor(time_index/length(subsetPlots.xaxis)))+1;
                            if In>0
                                iii = subset1(In);
                                if highlight
                                    line(x1(:,1),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine)
                                    text(x1(time_index),y1(time_index),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14,'BackgroundColor',[1 1 1 0.7],'margin',1)
                                end
                            end
                    end
            end
        end
    end

    function exitCellExplorer(~,~)
        close(UI.fig);
    end

    function bar_from_patch(x_data, y_data,col)
        x_data = [x_data(1),reshape([x_data,x_data([2:end,end])]',1,[]),x_data(end)];
        y_data = [0,reshape([y_data,y_data]',1,[]),0];
        patch(x_data, y_data,col,'EdgeColor','none','FaceAlpha',.8,'HitTest','off')
    end
    
    function bar_from_patch2(x_data, y_data,col,y0)
        % Creates a bar graph using the patch plot mode, which is substantial faster than using the regular bar plot.
        % By Peter Petersen
        
        x_step = x_data(2)-x_data(1);
        x_data = [x_data(1),reshape([x_data,x_data+x_step]',1,[]),x_data(end)+x_step];
        y_data = [y0,reshape([y_data,y_data]',1,[]),y0];
        patch(x_data, y_data,col,'EdgeColor',col, 'HitTest','off')
    end

    function SelectFromPlot(u,v)
        % Called with a plot-click and goes to selected cells and updates
        % the GUI
        iii = FromPlot(u,v,0);
        if iii>0
            ii = iii;
            UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
            UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
            UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
            uiresume(UI.fig);
        end
    end

    function selectCellsForGroupAction(~,~)
        % Checkes if any cells have been highlighted, if not asks the user
        % to provide list of cell.
        if isempty(UI.params.ClickedCells)
            filterCells.dialog = dialog('Position',[300 300 600 495],'Name','Select cells','visible','off'); movegui(filterCells.dialog,'center'), set(filterCells.dialog,'visible','on')
            
            % Text field
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Cell IDs to process. E.g. 1:32 or 7,8,9,10 (leave empty to select all cells)', 'Position', [10, 470, 580, 15],'HorizontalAlignment','left');
            filterCells.cellIDs = uicontrol('Parent',filterCells.dialog,'Style', 'Edit', 'String', '', 'Position', [10, 445, 570, 25],'KeyReleaseFcn',@cellSelection1,'HorizontalAlignment','left');
            
            % Text field
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Metric to filter', 'Position', [10, 420, 180, 15],'HorizontalAlignment','left');
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Logic filter', 'Position', [300, 420, 100, 15],'HorizontalAlignment','left');
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Value', 'Position', [410, 420, 170, 15],'HorizontalAlignment','left');
            filterCells.filterDropdown = uicontrol('Parent',filterCells.dialog,'Style','popupmenu','Position',[10, 395, 280, 25],'Units','normalized','String',['Select';fieldsMenu],'Value',1,'HorizontalAlignment','left');
            filterCells.filterType = uicontrol('Parent',filterCells.dialog,'Style', 'popupmenu', 'String', {'>','<','==','~='}, 'Value',1,'Position', [300, 395, 100, 25],'HorizontalAlignment','left');
            filterCells.filterInput = uicontrol('Parent',filterCells.dialog,'Style', 'Edit', 'String', '', 'Position', [410, 395, 170, 25],'HorizontalAlignment','left','KeyReleaseFcn',@cellSelection1);
            
            % Cell type
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Cell types', 'Position', [10, 375, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.putativeCellType,UI.settings.cellTypes);
            filterCells.cellTypes = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position', [10 295 280 80],'Units','normalized','String',strcat(UI.settings.cellTypes,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
            % Brain region
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Brain regions', 'Position', [300, 375, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.brainRegion,groups_ids.brainRegion_num);
            filterCells.brainRegions = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position', [300 295 280 80],'Units','normalized','String',strcat(groups_ids.brainRegion_num,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
            % Session
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Sessions', 'Position', [10, 270, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.sessionName,groups_ids.sessionName_num);
            filterCells.sessions = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position', [10 150 280 120],'Units','normalized','String',strcat(groups_ids.sessionName_num,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
            % Animal
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Animals', 'Position', [300, 270, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.animal,groups_ids.animal_num);
            filterCells.animals = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position', [300 150 280 120],'Units','normalized','String',strcat(groups_ids.animal_num,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
            % Synaptic effect
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Synaptic effect', 'Position', [10, 130, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.synapticEffect,groups_ids.synapticEffect_num);
            filterCells.synEffect = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position',  [10 50 280 80],'Units','normalized','String',strcat(groups_ids.synapticEffect_num,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
            % Connections
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Synaptic connections', 'Position', [300, 130, 280, 15],'HorizontalAlignment','left');
            filterCells.synConnectFilter = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position',  [300 50 280 80],'Units','normalized','String',synConnectOptions(2:end),'max',100,'min',0,'Value',[]);
            
            % Buttons
            uicontrol('Parent',filterCells.dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','OK','Callback',@(src,evnt)cellSelection);
            uicontrol('Parent',filterCells.dialog,'Style','pushbutton','Position',[300, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)cancelCellSelection);
            %         uicontrol('Parent',filterCells.dialog,'Style','pushbutton','Position',[200, 10, 90, 30],'String','Reset filter','Callback',@(src,evnt)cancelCellSelection);
            
            uicontrol(filterCells.cellIDs)
            uiwait(filterCells.dialog);
            
        else
            % Calls the group action for highlighted cells
            if ~isempty(UI.params.ClickedCells)
                GroupAction(UI.params.ClickedCells)
            end
        end
        
        function cell_class_count = getCellcount(plotClas11,plotClasGroups)
            [~,plotClas11] = ismember(plotClas11,plotClasGroups);
            cell_class_count = histc(plotClas11,[1:length(plotClasGroups)]);
            cell_class_count = cellstr(num2str(cell_class_count'))';
        end
        
        function cellSelection1(~,evnt)
            if strcmpi(evnt.Key,'return')
                cellSelection
            end
            
        end
        function cellSelection
            % Filters the selected cells based on user input
            ClickedCells0 = ones(1,cell_metrics.general.cellCount);
            ClickedCells1 = ones(1,cell_metrics.general.cellCount);
            ClickedCells2 = ones(1,cell_metrics.general.cellCount);
            ClickedCells3 = ones(1,cell_metrics.general.cellCount);
            ClickedCells4 = ones(1,cell_metrics.general.cellCount);
            ClickedCells5 = ones(1,cell_metrics.general.cellCount);
            ClickedCells6 = ones(1,cell_metrics.general.cellCount);
            % Input field
            answer = filterCells.cellIDs.String;
            if ~isempty(answer)
                try
                    UI.params.ClickedCells = eval(['[',answer,']']);
                    UI.params.ClickedCells = UI.params.ClickedCells(ismember(UI.params.ClickedCells,1:cell_metrics.general.cellCount));
                catch
                    MsgLog(['List of cells not formatted correctly'],2)
                end
            else
                UI.params.ClickedCells = 1:cell_metrics.general.cellCount;
            end
            
            % Filter field % {'Select','>','<','==','~='}
            if filterCells.filterDropdown.Value > 1 && ~isempty(filterCells.filterInput.String) && isnumeric(str2double(filterCells.filterInput.String))
                if filterCells.filterType.Value==1 % greater than
                    ClickedCells0 = cell_metrics.(filterCells.filterDropdown.String{filterCells.filterDropdown.Value}) > str2double(filterCells.filterInput.String);
                elseif filterCells.filterType.Value==2 % less than
                    ClickedCells0 = cell_metrics.(filterCells.filterDropdown.String{filterCells.filterDropdown.Value}) < str2double(filterCells.filterInput.String);
                elseif filterCells.filterType.Value==3 % equal to
                    ClickedCells0 = cell_metrics.(filterCells.filterDropdown.String{filterCells.filterDropdown.Value}) == str2double(filterCells.filterInput.String);
                elseif filterCells.filterType.Value==4 % different from
                    ClickedCells0 = cell_metrics.(filterCells.filterDropdown.String{filterCells.filterDropdown.Value}) ~= str2double(filterCells.filterInput.String);
                end
            end
            
            % Cell type
            if ~isempty(filterCells.cellTypes.Value)
                ClickedCells1 = ismember(cell_metrics.putativeCellType, UI.settings.cellTypes(filterCells.cellTypes.Value));
            end
            % Session name
            if ~isempty(filterCells.sessions.Value)
                ClickedCells2 = ismember(cell_metrics.sessionName, groups_ids.sessionName_num(filterCells.sessions.Value));
            end
            % Brain region
            if ~isempty(filterCells.brainRegions.Value)
                ClickedCells3 = ismember(cell_metrics.brainRegion, groups_ids.brainRegion_num(filterCells.brainRegions.Value));
            end
            % Synaptic effect
            if ~isempty(filterCells.synEffect.Value)
                ClickedCells4 = ismember(cell_metrics.synapticEffect, groups_ids.synapticEffect_num(filterCells.synEffect.Value));
            end
            % Animals
            if ~isempty(filterCells.animals.Value)
                ClickedCells5 = ismember(cell_metrics.animal, groups_ids.animal_num(filterCells.animals.Value));
            end
            
            % Synaptic connections
            if ~isempty(filterCells.synConnectFilter.Value) && length(filterCells.synConnectFilter.Value) == 1
                ClickedCells6_out = findSynapticConnections(filterCells.synConnectFilter.String{filterCells.synConnectFilter.Value});
                ClickedCells6 = zeros(1,cell_metrics.general.cellCount);
                ClickedCells6(ClickedCells6_out) = 1;
                % %                 ClickedCells6 = ismember(cell_metrics.synapticEffect, groups_ids.synapticEffect_num(filterCells.synEffect.Value));
            end
            
            % Finding cells fullfilling all criteria
            UI.params.ClickedCells = intersect(UI.params.ClickedCells,find(all([ClickedCells0;ClickedCells1;ClickedCells2;ClickedCells3;ClickedCells4;ClickedCells5;ClickedCells6])));
            
            close(filterCells.dialog)
            updateTableClickedCells
            % Calls the group action for highlighted cells
            if ~isempty(UI.params.ClickedCells)
                %                 highlightSelectedCells
                GroupAction(UI.params.ClickedCells)
            end
        end
        
        function cancelCellSelection
            close(filterCells.dialog)
        end
    end

    function connections1 = findSynapticConnections(synType)
        if ~isempty(putativeSubset)
            % Inbound
            a199 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
            % Outbound
            a299 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
            
            if strcmp(synType, 'Selected')
                inbound99 = find(a299 == ii);
                outbound99 = find(a199 == ii);
            elseif strcmp(synType, 'All')
                inbound99 = 1:length(a299);
                outbound99 = 1:length(a199);
            else
                inbound99 = [];
                outbound99 = [];
            end
            
            if any(strcmp(synType, {'Upstream','Up & downstream'}))
                kkk = 1;
                inbound99 = find(a299 == ii);
                while ~isempty(inbound99) && any(ismember(a299, a199(inbound99))) && kkk < 10
                    inbound99 = [inbound99;find(ismember(a299, a199(inbound99)))];
                    kkk = kkk + 1;
                end
            end
            if any(strcmp(synType, {'Downstream','Up & downstream'}))
                kkk = 1;
                outbound99 = find(a199 == ii);
                while ~isempty(outbound99) && any(ismember(a199, a299(outbound99))) && kkk < 10
                    outbound99 = [outbound99;find(ismember(a199, a299(outbound99)))];
                    kkk = kkk + 1;
                end
            end
            incoming1 = a199(inbound99);
            outgoing1 = a299(outbound99);
            connections1 = [incoming1;outgoing1];
        end
    end

    function HighlightFromPlot(u,v,w)
        iii = FromPlot(u,v,1,w);
        if iii > 0
            UI.params.ClickedCells = unique([UI.params.ClickedCells,iii]);
            updateTableClickedCells
        end
    end

    function exportFigure(~,~)
        % Opens the export figure dialog
        % First the size of the printed figure is resized to the current size of the figure and renderer is set to painter (vector graphics)
        set(UI.fig,'Units','Inches','Renderer','painters');
        set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
        exportsetupdlg(UI.fig)
    end

    function GroupSelectFromPlot(~,~)
        % Allows the user to select multiple cells from any plot.
        if ~isempty(UI.params.subset)
            polygon_coords = polygon1.coords;
            In = [];
            
            if size(polygon_coords,1)>2
                axnum = find(ismember(subfig_ax, gca));
                if isempty(axnum)
                    axnum = 1;
                end
                if axnum == 1 && UI.settings.customPlotHistograms == 4
                    In = find(inpolygon(plotX(UI.params.subset), plotY1(UI.params.subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif axnum == 1
                    In = find(inpolygon(plotX(UI.params.subset), plotY(UI.params.subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif axnum == 2
                    In = find(inpolygon(cell_metrics.troughToPeak(UI.params.subset)*1000, log10(cell_metrics.burstIndex_Royer2012(UI.params.subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                    In = UI.params.subset(In);
                    
                elseif axnum == 3
                    In = find(inpolygon(tSNE_metrics.plot(UI.params.subset,1), tSNE_metrics.plot(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif any(axnum == [4,5,6,7,8,9])
                    selectedOption = UI.settings.customPlot{axnum-3};
                    subsetPlots = UI.subsetPlots{axnum-3};
                    
                    switch selectedOption
                        case 'Waveforms (single)'
                            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            
                        case 'Raw waveforms (single)'
                            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            
                        case 'Waveforms (all)'
                            if UI.settings.zscoreWaveforms == 1
                                zscoreWaveforms1 = 'filt_zscored';
                            else
                                zscoreWaveforms1 = 'filt_absolute';
                            end
                            x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            In = UI.params.subset(In);
                            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In2 = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                                In = [In,In2];
                            end
                            
                        case 'Raw waveforms (all)'
                            if UI.settings.zscoreWaveforms == 1
                                zscoreWaveforms1 = 'raw_zscored';
                            else
                                zscoreWaveforms1 = 'raw_absolute';
                            end
                            x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            In = UI.params.subset(In);    
                            if UI.settings.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In2 = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                                In = [In,In2];
                            end
                            
                        case 'Waveforms (image)'
                            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'Waveforms (tSNE)'
                            In = find(inpolygon(tSNE_metrics.filtWaveform(UI.params.subset,1), tSNE_metrics.filtWaveform(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = UI.params.subset(In);
                            
                        case 'Trilaterated position'
                            switch UI.settings.trilatGroupData
                                case 'session'
                                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                                    subset1 = UI.params.subset(subset1);
                                case 'animal'
                                    subset1 = ismember(cell_metrics.animal(UI.params.subset),cell_metrics.animal{ii});
                                    subset1 = UI.params.subset(subset1);
                                otherwise
                                    subset1 = UI.params.subset;
                            end
                            In = find(inpolygon(cell_metrics.trilat_x(subset1), cell_metrics.trilat_y(subset1), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset1(In);
                            if ~isempty(In)
                                line(cell_metrics.trilat_x(In),cell_metrics.trilat_y(In),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
                            end
                            
                        case 'CCGs (image)'
                            if isfield(general,'ccg')
                                if UI.BatchMode
                                    subset2 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                                else
                                    subset2 = UI.params.subset;
                                end
                                subset1 = cell_metrics.UID(subset2);
                                subset1 = [cell_metrics.UID(ii),subset1(subset1~=cell_metrics.UID(ii))];
                                subset2 = [ii,subset2(subset2~=ii)];
                                In = subset2(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2))));
                            end
                            
                        case 'ACGs (all)'
                            if strcmp(UI.settings.acgType,'Normal')
                                x1 = ([-100:100]/2)'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.narrow(:,UI.params.subset);
                            elseif strcmp(UI.settings.acgType,'Narrow')
                                x1 = ([-30:30]/2)'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.narrow(41+30:end-40-30,UI.params.subset);
                            elseif strcmp(UI.settings.acgType,'Log10')
                                x1 = (general.acgs.log10)*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.log10(:,UI.params.subset);
                            else
                                x1 = ([-500:500])'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.wide(:,UI.params.subset);
                            end
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            if ~isempty(In)
                                line(x1(:,In),y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'ISIs (all)'
                            x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                            if strcmp(UI.settings.isiNormalization,'Rate')
                                y1 = cell_metrics.isi.log10(:,UI.params.subset);
                            elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                                x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.settings.ACGLogIntervals))';
                            else
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.settings.ACGLogIntervals))';
                            end
                            
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            In = UI.params.subset(In);
                            
                        case {'ACGs (image)','ISIs (image)'}
                            [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(burstIndexSorted(max(min(floor(polygon_coords(:,2))),1):min(max(ceil(polygon_coords(:,2))),length(UI.params.subset))));
                            
                        case 'tSNE of narrow ACGs'
                            In = find(inpolygon(tSNE_metrics.acg_narrow(UI.params.subset,1), tSNE_metrics.acg_narrow(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = UI.params.subset(In);
                            
                        case 'tSNE of wide ACGs'
                            In = find(inpolygon(tSNE_metrics.acg_wide(UI.params.subset,1), tSNE_metrics.acg_wide(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = UI.params.subset(In);
                            
                        case 'RCs_thetaPhase (all)'
                            x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(UI.x_bins.thetaPhase)))+1;
                            if ~isempty(In)
                                line(UI.x_bins.thetaPhase,y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'RCs_thetaPhase (image)'
                            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'RCs_firingRateAcrossTime (image)'
                            if UI.BatchMode
                                subset23 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                            else
                                subset23 = 1:general.cellCount;
                            end
                            [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(subset23));
                            subset2 = subset23(burstIndexSorted);
                            In = subset2(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2))));
                        case 'Connectivity graph'
                            if ~isempty(subsetPlots)
                                In1 = find(inpolygon(subsetPlots.xaxis, subsetPlots.yaxis, polygon_coords(:,1)',polygon_coords(:,2)'));
                                In = subsetPlots.subset(In1);
                                if ~isempty(In)
                                    line(subsetPlots.xaxis(In1),subsetPlots.yaxis(In1),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9,'HitTest','off')
                                end
                            end
                        otherwise
                            if any(strcmp(UI.monoSyn.disp,{'All','Selected','Upstream','Downstream','Up & downstream'}))
                                if (~isempty(UI.params.outbound) || ~isempty(UI.params.inbound)) && ~isempty(subsetPlots)
                                    subset1 = subsetPlots.subset;
                                    x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                                    y1 = subsetPlots.yaxis;
                                    
                                    In2 = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                    In2 = unique(floor(In2/length(subsetPlots.xaxis)))+1;
                                    In = subset1(In2);
                                    if ~isempty(In2)
                                        line(x1(:,1),y1(:,In2),'linewidth',2, 'HitTest','off')
                                    end
                                end
                            end
                    end
                end
                
                if ~isempty(In) && any(axnum == [1,2,3,4,5,6,7,8,9])
                    if iscolumn(In)
                        UI.params.ClickedCells = unique([UI.params.ClickedCells,In']);
                    else
                        UI.params.ClickedCells = unique([UI.params.ClickedCells,In]);
                    end
                    updateTableClickedCells
                    GroupAction(UI.params.ClickedCells)
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

    function showLegends(~,~)
        if UI.settings.dispLegend
            UI.menu.display.dispLegend.Checked = 'off';
            UI.settings.dispLegend = 0;
        else
            UI.menu.display.dispLegend.Checked = 'on';
            UI.settings.dispLegend = 1;
            UI.panel.tabgroup2.SelectedTab = UI.tabs.legends;
        end
        uiresume(UI.fig);
    end

    function flipXY(~,~)
        Xval = UI.popupmenu.yData.Value;
        Xstr = UI.popupmenu.yData.String;
        plotX = cell_metrics.(Xstr{Xval});
        UI.plot.xTitle = Xstr{Xval};

        Yval = UI.popupmenu.xData.Value;
        Ystr = UI.popupmenu.xData.String;
        plotY = cell_metrics.(Ystr{Yval});
        UI.plot.yTitle = Ystr{Yval};
        
        UI.popupmenu.xData.Value = Xval;
        UI.popupmenu.yData.Value = Yval;
        Xlog = UI.checkbox.logx.Value;
        Ylog = UI.checkbox.logy.Value;
        UI.checkbox.logx.Value = Ylog;
        UI.checkbox.logy.Value = Xlog;
        uiresume(UI.fig);
    end
    
    function buttonPlotX
        Xval = UI.popupmenu.xData.Value;
        Xstr = UI.popupmenu.xData.String;
        plotX = cell_metrics.(Xstr{Xval});
        UI.plot.xTitle = Xstr{Xval};
        uiresume(UI.fig);
    end

    function buttonPlotY
        Yval = UI.popupmenu.yData.Value;
        Ystr = UI.popupmenu.yData.String;
        plotY = cell_metrics.(Ystr{Yval});
        UI.plot.yTitle = Ystr{Yval};
        uiresume(UI.fig);
    end

    function buttonPlotZ
        Zval = UI.popupmenu.zData.Value;
        Zstr = UI.popupmenu.zData.String;
        plotZ = cell_metrics.(Zstr{Zval});
        UI.plot.zTitle = Zstr{Zval};
        uiresume(UI.fig);
    end

    function buttonPlotMarkerSize
        Zval = UI.popupmenu.markerSizeData.Value;
        Zstr = UI.popupmenu.markerSizeData.String;
        plotMarkerSize = cell_metrics.(Zstr{Zval});
        uiresume(UI.fig);
    end

    function updatePlotClas
        if Colorval == 1
            plotClas = clusClas;
        else
            if UI.checkbox.groups.Value == 0
                plotClas11 = cell_metrics.(colorStr{Colorval});
                if iscell(plotClas11)
                    plotClas11 = findgroups(plotClas11);
                end
            else
                plotClas = clusClas;
            end
        end
    end

    function updateTableColumnWidth
        % Updating table column width
        if UI.settings.metricsTable==1
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),160);
            UI.table.ColumnWidth = {pos1*6/10-10, pos1*4/10-10};
        elseif UI.settings.metricsTable==2
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),160);
            UI.table.ColumnWidth = {18,pos1*2/10, pos1*6/10-38, pos1*2/10};
        end
    end

    function buttonGroups(inpt)
        Colorval = UI.popupmenu.groups.Value;
        colorStr = colorMenu;
        
        if Colorval == 1
            clasLegend = 0;
            UI.listbox.groups.Enable = 'Off';
            UI.listbox.groups.String = {};
            UI.checkbox.groups.Enable = 'Off';
            plotClas = clusClas;
            UI.checkbox.groups.Value = 1;
            plotClasGroups = UI.settings.cellTypes;
        else
            clasLegend = 1;
            UI.listbox.groups.Enable = 'On';
            UI.checkbox.groups.Enable = 'On';
            if inpt == 1
                UI.checkbox.groups.Value = 0;
            end
            if UI.checkbox.groups.Value == 0
                plotClas11 = cell_metrics.(colorStr{Colorval});
                plotClasGroups = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas11) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas11 = findgroups(plotClas11);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas11] = ismember(plotClas11,plotClasGroups);
                end
                color_class_count = histc(plotClas11,[1:length(plotClasGroups)]);
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

    function buttonPlotXLog
        if UI.checkbox.logx.Value==1
            MsgLog('X-axis log. Negative data ignored');
        else
            MsgLog('X-axis linear');
        end
        uiresume(UI.fig);
    end

    function buttonPlotYLog
        if UI.checkbox.logy.Value==1
            MsgLog('Y-axis log. Negative data ignored');
        else
            MsgLog('Y-axis linear');
        end
        uiresume(UI.fig);
    end

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

    function buttonPlotMarkerSizeLog
        if UI.checkbox.logMarkerSize.Value==1
            UI.settings.logMarkerSize = 1;
            MsgLog('Marker size log. Negative data ignored');
        else
            UI.settings.logMarkerSize = 0;
            MsgLog('Marker size linear');
        end
        uiresume(UI.fig);
    end

    function buttonSelectSubset
        classes2plot = UI.listbox.cellTypes.Value;
        uiresume(UI.fig);
    end

    function buttonSelectGroups
        groups2plot2 = UI.listbox.groups.Value;
        uiresume(UI.fig);
    end

    function setTableDataSorting(src,~)
        if isfield(src,'Text')
            UI.tableData.SortBy = src.Text;
        else
            UI.tableData.SortBy = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.sortingList(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.SortBy,UI.settings.tableDataSortingList));
        UI.menu.tableData.sortingList(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            updateCellTableData
        end
    end

    function plotSupplementaryFigure(~,~)
        UI.settings.plotInsetChannelMap = 1; % Hiding channel map inset in waveform plots.
        UI.settings.plotInsetACG = 1; % Hiding ACG inset in waveform plots.
        if ismac
            defaultAxesFontSize = 16;
            fig_pos = [0,0,1100,550];
        else
            defaultAxesFontSize = 12;
            fig_pos = [0,0,1200,600];
        end
        fig = figure('Name','CellExplorer supplementary figure','NumberTitle','off','pos',fig_pos,'defaultAxesFontSize',defaultAxesFontSize,'color','w','visible','off'); movegui(fig,'center'), set(fig,'visible','on')
        % Scatter plot with trough to peak vs burst index
        ax1 = subplot('Position',[0.06 0.1 0.41 .87]); % Trough to peak vs burstiness
        ce_gscatter(cell_metrics.troughToPeak(UI.params.subset), cell_metrics.burstIndex_Royer2012(UI.params.subset), plotClas(UI.params.subset), clr_groups,UI.settings.markerSize,'.'); axis tight
        xlabel('Trough to peak (ms)'), ylabel('Burst index'); set(gca, 'YScale', 'log','TickLength',[0.02 1]), axis tight, figureLetter('A','right')
        % Generating legend
        legendNames = plotClasGroups(nanUnique(plotClas(UI.params.subset)));
        for i = 1:length(legendNames)
            legendDots(i) = line(nan,nan,'Marker','.','LineStyle','none','color',clr_groups(i,:), 'MarkerSize',20);
        end
        legend(legendDots,legendNames,'Location','southwest');
        % Waveforms
        subplot('Position',[0.5 0.72 0.23 .25]) 
        customPlot('Waveforms (all)',ii,general,batchIDs,gca); yticks([]), axis tight, ylabel(''), figureLetter('B','center');
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1]), title('');
        % Firing rates
        subplot('Position',[0.5 0.41 0.23 .21]) 
        generateGroupRainCloudPlot('firingRate',1,0,0, 0.06)
        xlabel('Firing rate (Hz)'), figureLetter('C','center'),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', 'log'), title('')
        % CV2
        subplot('Position',[0.5 0.1 0.23 .21]) 
        generateGroupRainCloudPlot('cv2',0,0,0, 0.06), xlabel('CV_2'),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1]), title('')
        % Peak voltage
        subplot('Position',[0.76 0.815 0.23 .155]) 
        ce_raincloud_plot(cell_metrics.peakVoltage,'scatter_on',0,'log_axis',1,'color', [0.9 0.9 0.9]); 
        axis tight, figureLetter('D','center'), xticks([10 100 1000]), xlabel(['Peak voltage (',char(181),'V)']),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', 'log');
        % Isolation distance
        subplot('Position',[0.76 0.57 0.23 .145]) 
        ce_raincloud_plot(cell_metrics.isolationDistance,'scatter_on',0,'log_axis',1,'color', [0.9 0.9 0.9]); 
        axis tight, xticks([10 100]); xlim([10,300]), xlabel('Isolation distance'),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', 'log');
        % L_ratio
        subplot('Position',[0.76 0.335 0.23 .142]) 
        ce_raincloud_plot(cell_metrics.lRatio,'scatter_on',0,'log_axis',1,'color', [0.9 0.9 0.9]); 
        axis tight, xticks(10.^(-5:2:1)); xlim(10.^([-5 2])), xlabel('L-ratio'), 
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', 'log');
        % refractory period
        subplot('Position',[0.76 0.1 0.23 .142]) 
        ce_raincloud_plot(cell_metrics.refractoryPeriodViolation,'scatter_on',0,'log_axis',1,'color', [0.9 0.9 0.9]); 
        axis tight, xticks(10.^(-2:2:2)); xlabel(['Refractory period violation (',char(8240),')']),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', 'log');
%         classes2plotSubset = unique(plotClas);
%         cell_class_count = histc(plotClas,1:length(UI.settings.cellTypes));
%         figure
%         h_pie = pie(cell_class_count);
%         for i = 1:numel(classes2plotSubset)
%             h_pie((i*2)-1).FaceColor = clr_groups(i,:);
%         end
        function figureLetter(letter,alignment)
            text(-0.015,1,letter,'FontSize',30,'Units','normalized','verticalalignment','middle','horizontalalignment',alignment);
        end
    end

    function plotSummaryFigures
        if isempty(plotCellIDs)
            cellIDs = 1:length(cell_metrics.cellID);
        elseif plotCellIDs==-1
            cellIDs = 1;
        else
            ids = ismember(plotCellIDs,1:length(cell_metrics.cellID));
            cellIDs = plotCellIDs(ids);
        end
        UI.params.subset = 1:length(cell_metrics.cellID);
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
            putativeSubset = find(sum(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)')==2);
        else
            putativeSubset=[];
        end
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory')
            putativeSubset_inh = find(sum(ismember(cell_metrics.putativeConnections.inhibitory,UI.params.subset)')==2);
        else
            putativeSubset_inh=[];
        end
        clr_groups = UI.settings.cellTypeColors(intersect(classes2plot,plotClas(UI.params.subset)),:);
        classes2plotSubset = unique(plotClas);
        if plotCellIDs==-1
            plotOptions_all = {'Trilaterated position','Waveforms (all)','Waveforms (image)','Raw waveforms (all)','ACGs (all)','ACGs (image)','ISIs (all)','ISIs (image)','RCs_firingRateAcrossTime (image)','RCs_firingRateAcrossTime (all)','Connectivity graph'};
            plotOptions = plotOptions(ismember(plotOptions,plotOptions_all));
            plotCount = 3;
        else
            plotCount = 4;
        end
        
        [plotRows,~]= numSubplots(length(plotOptions)+plotCount);
        
        fig = figure('Name','CellExplorer','NumberTitle','off','pos',UI.settings.figureSize);
        for j = 1:length(cellIDs)
            if ~ishandle(fig)
                warning(['Summary figures canceled by user']);
                break
            end
            if plotCellIDs~=-1
                set(fig,'Name',['CellExplorer summary figures ',num2str(j),'/',num2str(length(cellIDs))]);
            else
                set(fig,'Name',['CellExplorer summary figure']);
            end
            if UI.BatchMode
                batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                general1 = cell_metrics.general.batch{batchIDs1};
                savePath1 = cell_metrics.general.path{batchIDs1};
            else
                general1 = cell_metrics.general;
                batchIDs1 = 1;
                if isfield(cell_metrics.general,'path')
                    savePath1 = cell_metrics.general.path;
                elseif isfield(cell_metrics.general,'basepath')
                    savePath1 = cell_metrics.general.basepath;
                end
            end
            if ~isempty(putativeSubset)
                UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                UI.params.incoming = UI.params.a1(UI.params.inbound);
                UI.params.outgoing = UI.params.a2(UI.params.outbound);
                UI.params.connections = [UI.params.incoming;UI.params.outgoing];
            end
            if ~isempty(putativeSubset_inh) 
                UI.params.b1 = cell_metrics.putativeConnections.inhibitory(putativeSubset_inh,1);
                UI.params.b2 = cell_metrics.putativeConnections.inhibitory(putativeSubset_inh,2);
                UI.params.inbound_inh = find(UI.params.b2 == cellIDs(j));
                UI.params.outbound_inh = find(UI.params.b1 == cellIDs(j));
                UI.params.incoming_inh = UI.params.b1(UI.params.inbound_inh);
                UI.params.outgoing_inh = UI.params.b2(UI.params.outbound_inh);
                UI.params.connections_inh = [UI.params.incoming_inh;UI.params.outgoing_inh];
            else
                UI.params.inbound_inh = [];
                UI.params.outbound_inh = [];
                UI.params.incoming_inh = [];
                UI.params.outgoing_inh = [];
                UI.params.connections_inh = [];
            end
            if ispc
                ha = tight_subplot(plotRows(1),plotRows(2),[.1 .05],[.05 .07],[.05 .05]);
            else
                ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.12 .06],[.06 .05]);
            end
            set(fig,'CurrentAxes',ha(1)), hold on
            plotGroupData(cell_metrics.troughToPeak * 1000,cell_metrics.burstIndex_Royer2012,plotConnections(2))
            ha(1).XLabel.String = ['Trough-to-Peak (',char(181),'s)'];
            ha(1).YLabel.String = 'Burst Index (Royer 2012)';
            ha(1).Title.String = 'Population';
            set(ha(1),'YScale', 'log');
            set(fig,'CurrentAxes',ha(2)), hold on
%             axes(ha(2)), hold on
            % Scatter plot with t-SNE metrics
            plotGroupData(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',plotConnections(2))
            ha(2).XLabel.String = 't-SNE';
            ha(2).YLabel.String = 't-SNE';
            ha(2).Title.String = 't-SNE';
            
            for jj = 1:length(plotOptions)
                set(fig,'CurrentAxes',ha(jj+2)), hold on
                customPlot(plotOptions{jj},cellIDs(j),general1,batchIDs1,ha(jj+2));
                if jj == 1
                    ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                end
            end
            if plotCellIDs~=-1
                set(fig,'CurrentAxes',ha(end-1)), hold on
                set(gca,'Visible','off'); hold on
                plotCharacteristics(cellIDs(j)), title('Characteristics')
            end
             set(fig,'CurrentAxes',ha(end)), hold on
            set(gca,'Visible','off');  hold on
            plotLegends, title('Characteristics')
            % Saving figure
            if ishandle(fig)
                try 
                    savefigure(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_cell_', num2str(cell_metrics.UID(cellIDs(j)))])
                catch 
                    disp('figure not saved (action canceled by user or directory not available for writing)')
                end
            end
        end
        
        function savefigure(fig,savePathIn,fileNameIn)
            savePath = fullfile(savePathIn,'summaryFigures');
            if ~exist(savePath,'dir')
                mkdir(savePathIn,'summaryFigures')
            end
            saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
            if plotCellIDs~=-1
                clf(fig)
            end
        end
    end

    function setColumn1_metric(src,~)
        if isfield(src,'Text')
            UI.tableData.Column1 = src.Text;
        else
            UI.tableData.Column1 = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.column1_ops(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.Column1,UI.settings.tableDataSortingList));
        UI.menu.tableData.column1_ops(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            UI.table.ColumnName = {'','#',UI.tableData.Column1,UI.tableData.Column2};
            updateCellTableData
        end
    end

    function setColumn2_metric(src,~)
        if isfield(src,'Text')
            UI.tableData.Column2 = src.Text;
        else
            UI.tableData.Column2 = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.column2_ops(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.Column2,UI.settings.tableDataSortingList));
        UI.menu.tableData.column2_ops(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            UI.table.ColumnName = {'','#',UI.tableData.Column1,UI.tableData.Column2};
            updateCellTableData
        end
    end

    function viewSessionMetaData(~,~)
        if UI.BatchMode
            sessionMetaFilename = fullfile(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)},[cell_metrics.general.basenames{cell_metrics.batchIDs(ii)},'.session.mat']);
            if exist(sessionMetaFilename,'file')
                gui_session(sessionMetaFilename);
            else
                MsgLog(['Session metadata file not available:' sessionMetaFilename],2)
            end
        else
            [~,basename,~] = fileparts(pwd);
            sessionMetaFilename = fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename,'.session.mat']);
            if exist(sessionMetaFilename,'file')
                gui_session(sessionMetaFilename);
            elseif exist(fullfile(cell_metrics.general.path,[cell_metrics.general.basename,'.session.mat']),'file')
                gui_session(fullfile(cell_metrics.general.path,[cell_metrics.general.basename,'.session.mat']));
            elseif exist([basename,'.session.mat'],'file')
                gui_session;
            else
                MsgLog(['Session metadata file not available:' sessionMetaFilename],2)
            end
        end
    end

    function buttonShowMetrics(src23,~)
        
        if exist('src23','var')
            if isfield(src23,'Text')
                text1 = src23.Text;
            else
                text1 = src23.Label;
            end
            switch text1
                case 'Cell metrics'
                    UI.settings.metricsTable = 1;
                case 'Cell list'
                    UI.settings.metricsTable = 2;
                case 'None'
                    UI.settings.metricsTable = 3;
            end
        end
        if UI.settings.metricsTable==1
            UI.menu.tableData.ops(1).Checked = 'on';
            UI.menu.tableData.ops(2).Checked = 'off';
            UI.menu.tableData.ops(3).Checked = 'off';
            updateTableColumnWidth
            UI.table.ColumnName = {'Metrics',''};
            UI.table.Data = [table_fieldsNames,table_metrics(:,ii)];
            UI.table.Visible = 'on';
            UI.table.ColumnEditable = [false false];
            
        elseif UI.settings.metricsTable==2
            UI.menu.tableData.ops(1).Checked = 'off';
            UI.menu.tableData.ops(2).Checked = 'on';
            UI.menu.tableData.ops(3).Checked = 'off';
            updateTableColumnWidth
            UI.table.ColumnName = {'','#','Cell type','Region'};
            UI.table.ColumnEditable = [true false false false];
            updateCellTableData
            UI.table.Visible = 'on';
            %             updateCellTableData
            updateTableClickedCells
        elseif UI.settings.metricsTable==3
            UI.table.Visible = 'off';
            UI.menu.tableData.ops(1).Checked = 'off';
            UI.menu.tableData.ops(2).Checked = 'off';
            UI.menu.tableData.ops(3).Checked = 'on';
        end
    end

    function updateCellTableData
        dataTable = {};
        column1 = cell_metrics.(UI.tableData.Column1)(UI.params.subset)';
        column2 = cell_metrics.(UI.tableData.Column2)(UI.params.subset)';
        if isnumeric(column1)
            column1 = cellstr(num2str(column1,3));
        end
        if isnumeric(column2)
            column2 = cellstr(num2str(column2,3));
        end
        if ~isempty(UI.params.subset)
            dataTable(:,2:4) = [cellstr(num2str(UI.params.subset')),column1,column2];
            dataTable(:,1) = {false};
            if find(UI.params.subset==ii)
                idx = find(UI.params.subset==ii);
                dataTable{idx,2} = ['<html><b>&nbsp;',dataTable{idx,2},'</b></html>'];
                dataTable{idx,3} = ['<html><b>',dataTable{idx,3},'</b></html>'];
                dataTable{idx,4} = ['<html><b>',dataTable{idx,4},'</b></html>'];
            end
            if ~strcmp(UI.tableData.SortBy,'cellID')
                if ismember(UI.tableData.SortBy,{'peakVoltage','firingRate','synapticConnectionsOut','synapticConnectionsIn'})
                    [~,tableDataOrder] = sort(cell_metrics.(UI.tableData.SortBy)(UI.params.subset),'descend');
                else
                    [~,tableDataOrder] = sort(cell_metrics.(UI.tableData.SortBy)(UI.params.subset));
                end
                UI.table.Data = dataTable(tableDataOrder,:);
            else
                
                tableDataOrder = 1:length(UI.params.subset);
                UI.table.Data = dataTable;
            end
        else
            UI.table.Data = {};
        end
    end

    function customPlotStyle
        if exist('h_scatter','var') && any(ishandle(h_scatter))
        	delete(h_scatter)
        end
        if UI.popupmenu.metricsPlot.Value == 1
            UI.settings.customPlotHistograms = 1;
            UI.checkbox.logz.Enable = 'Off';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'Off';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.settings.plot3axis = 0;
            
        elseif UI.popupmenu.metricsPlot.Value == 2
            UI.settings.customPlotHistograms = 2;
            UI.checkbox.logz.Enable = 'Off';
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'Off';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.settings.plot3axis = 0;
            
        elseif UI.popupmenu.metricsPlot.Value == 3
            UI.settings.customPlotHistograms = 3;
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'On';
            UI.checkbox.logz.Enable = 'On';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.markerSizeData.Enable = 'On';
            UI.checkbox.logMarkerSize.Enable = 'On';
            UI.settings.plot3axis = 1;
             set(UI.fig,'CurrentAxes',UI.panel.subfig_ax1.Children(end))
            view([40 20]);

        elseif UI.popupmenu.metricsPlot.Value == 4
            UI.settings.customPlotHistograms = 4;
            UI.checkbox.logz.Enable = 'Off';
            UI.checkbox.logy.Enable = 'Off';
            UI.popupmenu.yData.Enable = 'Off';
            UI.popupmenu.zData.Enable = 'Off';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.settings.plot3axis = 0;
        end
        uiresume(UI.fig);
    end

    function toggleWaveformsPlot(src,evnt)
        for i = 1:6
            UI.settings.customPlot{i} = UI.popupmenu.customplot{i}.String{UI.popupmenu.customplot{i}.Value};
        end
        uiresume(UI.fig);
    end

    function toggleACGfit(~,~)
        % Enable/Disable the ACG fit
        if plotAcgFit == 0
            plotAcgFit = 1;
            UI.menu.ACG.showFit.Checked = 'on';
            UI.checkbox.ACGfit.Value = 1;
            MsgLog('Plotting ACG fit');
        elseif plotAcgFit == 1
            plotAcgFit = 0;
            UI.checkbox.ACGfit.Value = 0;
            UI.menu.ACG.showFit.Checked = 'off';
            MsgLog('Hiding ACG fit');
        end
        uiresume(UI.fig);
    end

    function goToCell(~,~)
        if UI.BatchMode
            GoTo_dialog = dialog('Position', [300, 300, 300, 350],'Name','Go to cell','visible','off'); movegui(GoTo_dialog,'center'), set(GoTo_dialog,'visible','on')
            
            sessionCount = histc(cell_metrics.batchIDs,[1:length(cell_metrics.general.basenames)]);
            sessionCount = cellstr(num2str(sessionCount'))';
            sessionEnumerator = cellstr(num2str([1:length(cell_metrics.general.basenames)]'))';
            sessionList = strcat(sessionEnumerator,{'.  '},cell_metrics.general.basenames,' (',sessionCount,')');
            
            brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', sessionList, 'Position', [10, 50, 280, 220],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog);
            if cell_metrics.batchIDs(ii)>0 && cell_metrics.batchIDs(ii)<=length(sessionList)
                brainRegionsList.Value = cell_metrics.batchIDs(ii);
            end
            brainRegionsTextfield = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 280, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','left');
            uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the cell id to go to and press enter', 'Position', [10, 325, 280, 20],'HorizontalAlignment','left');
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Click the session to go to', 'Position', [10, 270, 280, 20],'HorizontalAlignment','left');
            uicontrol(brainRegionsTextfield)
            uiwait(GoTo_dialog);
        else
            GoTo_dialog = dialog('Position', [300, 300, 300, 100],'Name','Go to cell','visible','off'); movegui(GoTo_dialog,'center'), set(GoTo_dialog,'visible','on')
            brainRegionsTextfield = uicontrol('Parent',GoTo_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 50, 280, 25],'Callback',@(src,evnt)UpdateBrainRegionsList,'HorizontalAlignment','center');
            uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
            uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', 'Provide the cell id to go to and press enter', 'Position', [10, 75, 280, 20],'HorizontalAlignment','center');
            uicontrol(brainRegionsTextfield)
            uiwait(GoTo_dialog);
        end
        
        function UpdateBrainRegionsList
            answer = str2double(brainRegionsTextfield.String);
            if ~isempty(answer) && answer > 0 && answer <= cell_metrics.general.cellCount
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
            delete(GoTo_dialog);
        end
    end

    function GroupAction(cellIDs)
        % dialog menu for creating group actions, including classification
        % and plots summaries.
        cellIDs = unique(cellIDs);
        highlightSelectedCells
        choice = '';
        GoTo_dialog = dialog('Position', [0, 0, 300, 350],'Name','Group actions','visible','off'); movegui(GoTo_dialog,'center'), set(GoTo_dialog,'visible','on')
        
        actionList = strcat([{'---------------- Assignments -----------------','Assign existing cell-type','Assign new cell-type','Assign label','Assign deep/superficial','Assign tag','Assign group','-------------------- CCGs ---------------------','CCGs ','CCGs (only with selected cell)','----------- MULTI PLOT OPTIONS ----------','Row-wise plots (5 cells per figure)','Plot-on-top (one figure for all cells)','Dedicated figures (one figure per cell)','--------------- SINGLE PLOTS ---------------'},plotOptions']);
        brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', actionList, 'Position', [10, 50, 280, 270],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', ['Select action to perform on ', num2str(length(cellIDs)) ,' selected cells'], 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(brainRegionsList)
        uiwait(GoTo_dialog);
        
        function  CloseGoTo_dialog(cellIDs)
            choice = brainRegionsList.Value;
            MsgLog(['Action selected: ' actionList{choice} ' for ' num2str(length(cellIDs)) ' cells']);
            if any(choice == [2:7,9:10,12:14,16:length(actionList)])
                delete(GoTo_dialog);
                
                if choice == 2
                    [selectedClas,~] = listdlg('PromptString',['Assign cell-type to ' num2str(length(cellIDs)) ' cells'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
                    if ~isempty(selectedClas)
                        saveStateToHistory(cellIDs)
                        clusClas(cellIDs) = selectedClas;
                        updateCellCount
                        MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.settings.cellTypes{selectedClas}, ' from t-SNE visualization']);
                        updatePlotClas
                        updatePutativeCellType
                        uiresume(UI.fig);
                    end
                    
                elseif choice == 3
                    AddNewCellType
                    selectedClas = length(colored_string);
                    if ~isempty(selectedClas)
                        saveStateToHistory(cellIDs)
                        clusClas(cellIDs) = selectedClas;
                        updateCellCount
                        MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.settings.cellTypes{selectedClas}, ' from t-SNE visualization']);
                        updatePlotClas
                        updatePutativeCellType
                        uiresume(UI.fig);
                    end
                    
                elseif choice == 4
                    Label = inputdlg({'Assign label to cell'},'Custom label',[1 40],{''});
                    if ~isempty(Label)
                        saveStateToHistory(cellIDs)
                        cell_metrics.labels(cellIDs) = repmat(Label(1),length(cellIDs),1);
                        [~,ID] = findgroups(cell_metrics.labels);
                        groups_ids.labels_num = ID;
                        % classificationTrackChanges = [classificationTrackChanges,ii];
                        updatePlotClas
                        updateCount
                        buttonGroups(1);
                        uiresume(UI.fig);
                    end
                    
                elseif choice == 5
                    [selectedClas,~] = listdlg('PromptString',['Assign Deep-Superficial to ' num2str(length(cellIDs)) ' cells'],'ListString',UI.listbox.deepSuperficial.String,'SelectionMode','single','ListSize',[200,150]);
                    if ~isempty(selectedClas)
                        saveStateToHistory(cellIDs)
                        cell_metrics.deepSuperficial(cellIDs) =  repmat(UI.listbox.deepSuperficial.String(selectedClas),1,length(cellIDs));
                        cell_metrics.deepSuperficial_num(cellIDs) = selectedClas;
                        
                        if strcmp(UI.plot.xTitle,'deepSuperficial_num')
                            plotX = cell_metrics.deepSuperficial_num;
                        end
                        if strcmp(UI.plot.yTitle,'deepSuperficial_num')
                            plotY = cell_metrics.deepSuperficial_num;
                        end
                        if strcmp(UI.plot.zTitle,'deepSuperficial_num')
                            plotZ = cell_metrics.deepSuperficial_num;
                        end
                        updatePlotClas
                        updateCount
                        uiresume(UI.fig);
                    end
                    
                elseif choice == 6
                    % Assign tags
                    assignGroup(cellIDs,'tags')
                    updateTags
                    uiresume(UI.fig);
                    
                elseif choice == 7
                    assignGroup(cellIDs,'groups')
                    
                elseif choice == 9
                    % All CCGs for all combinations of selected cell with highlighted cells
                    UI.params.ClickedCells = cellIDs(:)';
                    updateTableClickedCells
                    if isfield(general,'ccg') && ~isempty(UI.params.ClickedCells)
                        if UI.BatchMode
                            ClickedCells_inBatch = find(cell_metrics.batchIDs(ii) == cell_metrics.batchIDs(UI.params.ClickedCells));
                            if length(ClickedCells_inBatch) < length(UI.params.ClickedCells)
                                MsgLog([ num2str(length(UI.params.ClickedCells)-length(ClickedCells_inBatch)), ' cell(s) from a different batch are not displayed in the CCG window.'],0);
                            end
                            plot_cells = [ii,UI.params.ClickedCells(ClickedCells_inBatch)];
                        else
                            plot_cells = [ii,UI.params.ClickedCells];
                        end
                        plot_cells = unique(plot_cells,'stable');
                        ccgFigure = figure('Name',['CellExplorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize,'visible','off');
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        ha = tight_subplot(length(plot_cells),length(plot_cells),[.03 .03],[.06 .05],[.04 .05]);
                        for j = 1:length(plot_cells)
                            for jj = 1:length(plot_cells)
                                set(ccgFigure,'CurrentAxes',ha(k))
                                if jj == j
                                    col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                                    bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),col1)
                                    title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j))) ]),
                                    xlabel(cell_metrics.putativeCellType{plot_cells(j)})
                                else
                                    bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),[0.5,0.5,0.5])
                                end
                                if j == length(plot_cells) && mod(jj,2) == 1 && j~=jj; xlabel('Time (ms)'); end
                                if jj == 1 && mod(j,2) == 0; ylabel('Rate (Hz)'); end
                                if length(plot_cells)<7
                                    xticks([-50:10:50])
                                end
                                xlim([-50,50])
                                if length(plot_cells) > 2 && j < length(plot_cells)
                                    set(ha(k),'XTickLabel',[]);
                                end
                                axis tight, grid on
                                set(ha(k), 'Layer', 'top')
                                k = k+1;
                            end
                        end
                        set(ccgFigure,'visible','on')
                    else
                        MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                    end
                    
                elseif choice == 10
                    % CCGs with selected cell
                    UI.params.ClickedCells = cellIDs(:)';
                    updateTableClickedCells
                    if isfield(general,'ccg') && ~isempty(UI.params.ClickedCells)
                        if UI.BatchMode
                            ClickedCells_inBatch = find(cell_metrics.batchIDs(ii) == cell_metrics.batchIDs(UI.params.ClickedCells));
                            if length(ClickedCells_inBatch) < length(UI.params.ClickedCells)
                                MsgLog([ num2str(length(UI.params.ClickedCells)-length(ClickedCells_inBatch)), ' cell(s) from a different batch are not displayed in the CCG window.'],0);
                            end
                            plot_cells = [ii,UI.params.ClickedCells(ClickedCells_inBatch)];
                        else
                            plot_cells = [ii,UI.params.ClickedCells];
                        end
                        plot_cells = unique(plot_cells,'stable');
                        fig = figure('Name',['CellExplorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize);
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        [plotRows,~]= numSubplots(length(plot_cells));
                        ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                        
                        for j = 2:length(plot_cells)
                            set(fig,'CurrentAxes',ha(k))
                            col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                            bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(1),plot_cells2(j)),col1), hold on
                            if UI.monoSyn.dispHollowGauss && j > 1
                                norm_factor = cell_metrics.spikeCount(plot_cells2(1))*0.0005;
                                [ ~,pred] = ce_cch_conv(general.ccg(:,plot_cells2(1),plot_cells2(j))*norm_factor,20); hold on
                                nBonf = round(.004/0.001)*2; % alpha = 0.001;
                                % hiBound=poissinv(1-0.001/nBonf,pred);
                                hiBound=poissinv(1-0.001,pred);
                                line(general.ccg_time*1000,pred/norm_factor,'color','k')
                                line(general.ccg_time*1000,hiBound/norm_factor,'color','r')
                            end
                            
                            title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j))),' (cluID ',num2str(cell_metrics.cluID(plot_cells(j))),')']),
                            xlabel(cell_metrics.putativeCellType{plot_cells(j)}), grid on
                            if j==2; ylabel('Rate (Hz)'); end
                            xticks([-50:10:50])
                            xlim([-50,50])
                            if length(plot_cells) > 2 && j <= plotRows(2)
                                set(ha(k),'XTickLabel',[]);
                            end
                            axis tight, grid on
                            set(ha(k), 'Layer', 'top')
                            k = k+1;
                        end
                    else
                        MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                    end
                elseif any(choice == [12,13,14])
                    % Multiple plots
                    % Creates summary figures and saves them to '/summaryFigures' or a custom path
                    exportPlots.dialog = dialog('Position', [300, 300, 300, 370],'Name','Multi plot','WindowStyle','modal', 'resize', 'on', 'visible','off'); movegui(exportPlots.dialog,'center'), set(exportPlots.dialog,'visible','on')
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[5, 350, 290, 20],'Units','normalized','String','Select plots','HorizontalAlignment','center','Units','normalized');
                    % [selectedActions,tf] = listdlg('PromptString',['Plot actions to perform on ' num2str(length(cellIDs)) ' cells'],'ListString',plotOptions','SelectionMode','Multiple','ListSize',[300,350]);
                    exportPlots.popupmenu.plotList = uicontrol('Parent',exportPlots.dialog,'Style','listbox','Position',[5, 110, 290, 245],'Units','normalized','String',plotOptions,'HorizontalAlignment','left','Units','normalized','min',1,'max',100);
                    exportPlots.popupmenu.saveFigures = uicontrol('Parent',exportPlots.dialog,'Style','checkbox','Position',[5, 80, 240, 25],'Units','normalized','String','Save figures','HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[5, 62, 140, 20],'Units','normalized','String','File format','HorizontalAlignment','center','Units','normalized');
                    exportPlots.popupmenu.fileFormat = uicontrol('Parent',exportPlots.dialog,'Style','popupmenu','Position',[5, 40, 140, 25],'Units','normalized','String',{'png','pdf (slower but vector graphics)'},'HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[155, 62, 140, 20],'Units','normalized','String','File path','HorizontalAlignment','center','Units','normalized');
                    exportPlots.popupmenu.savePath = uicontrol('Parent',exportPlots.dialog,'Style','popupmenu','Position',[155, 40, 140, 25],'Units','normalized','String',{'Clustering path','CellExplorer','Define path'},'HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[5, 5, 140, 30],'String','OK','Callback',@ClosePlot_dialog,'Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[155, 5, 140, 30],'String','Cancel','Callback',@(src,evnt)CancelPlot_dialog,'Units','normalized');
                    
                elseif choice > 15
                    % Plots any custom plot for selected cells in a single new figure with subplots
                    fig = figure('Name',['CellExplorer: ',actionList{choice},' for selected cells: ', num2str(cellIDs)],'NumberTitle','off','pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                    [plotRows,~]= numSubplots(length(cellIDs));
                    if ispc
                        ha = tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
                    else
                        ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.05 .03],[.04 .03]);
                    end
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                        end
                        if ~isempty(putativeSubset)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        set(fig,'CurrentAxes',ha(j)), hold on
                        customPlot(actionList{choice},cellIDs(j),general1,batchIDs1,ha(j)); title(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                    end
                else
                    uiresume(UI.fig);
                end
            end
            function CancelPlot_dialog
                % Closes the dialog
                delete(exportPlots.dialog);
            end
            
            function ClosePlot_dialog(~,~)
                selectedActions = exportPlots.popupmenu.plotList.Value;
                
                if exportPlots.popupmenu.saveFigures.Value == 0
                    saveFig.save = false;
                else
                    saveFig.save = true;
                    saveFig.path = exportPlots.popupmenu.savePath.Value;
                    saveFig.fileFormat = exportPlots.popupmenu.fileFormat.Value;
                    if saveFig.path == 3 &&  ~exist('dirNameCustom','var')
                    	dirNameCustom = uigetdir;
                    end
                end
                delete(exportPlots.dialog);
                if choice == 12 && ~isempty(selectedActions)
                    % Displayes a new dialog where a number of plot can be combined and plotted for the highlighted cells
                    plot_columns = min([length(cellIDs),5]);
                    nPlots = 1;
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.path{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(putativeSubset)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        
                        for jj = 1:length(selectedActions)
                            if mod(j,5)==1 && jj == 1
                                fig = figure('name',['CellExplorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                                ha = tight_subplot(plot_columns,length(selectedActions),[.06 .03],[.08 .06],[.06 .05]); 
                                subPlotNum = 1;
                            else
                                subPlotNum = subPlotNum+1;
                            end
                            set(fig,'CurrentAxes',ha(subPlotNum))
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1,ha(subPlotNum));
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                            end
                            if (mod(j,5)==0 || j == length(cellIDs)) && jj == length(selectedActions)
                                savefigure(gcf,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_MultipleCells_', num2str(nPlots)])
                                nPlots = nPlots+1;
                            end
                        end
                    end
                    
                elseif choice == 13 && ~isempty(selectedActions)
                    
                    fig = figure('name',['CellExplorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                    [plotRows,~]= numSubplots(length(selectedActions));
                    ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.path{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(putativeSubset)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        for jjj = 1:length(selectedActions)
                            set(fig,'CurrentAxes',ha(jjj)), hold on
%                             subplot(plotRows(1),plotRows(2),jjj), hold on
                            customPlot(plotOptions{selectedActions(jjj)},cellIDs(j),general1,batchIDs1,ha(jjj));
                            title(plotOptions{selectedActions(jjj)},'Interpreter', 'none')
                        end
                    end
                    savefigure(fig,savePath1,['CellExplorer_Cells_', num2str(cell_metrics.UID(cellIDs),'%d_')])
                    
                elseif choice == 14 && ~isempty(selectedActions)
                    
                    [plotRows,~]= numSubplots(length(selectedActions)+3);
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.path{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(putativeSubset)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        fig = figure('Name',['CellExplorer: cell ', num2str(cellIDs(j))],'NumberTitle','off','pos',UI.settings.figureSize);
                        if ispc
                            ha = tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
                        else
                            ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.05 .03],[.04 .03]);
                        end
                        set(fig,'CurrentAxes',ha(1)), hold on
                        % Scatter plot with t-SNE metrics
                        plotGroupScatter(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2)), axis tight
                        ha(1).XLabel.String = 't-SNE';
                        ha(1).YLabel.String = 't-SNE';
                        ha(1).Title.String = 't-SNE';
                        
                        % Plots: putative connections
                        if plotConnections(3) == 1
                            plotPutativeConnections(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',UI.monoSyn.disp)
                        end
                        
                        % Plots: X marker for selected cell
                        plotMarker(tSNE_metrics.plot(cellIDs(j),1),tSNE_metrics.plot(cellIDs(j),2))
                        
                        % Plots: tagget ground-truth cell types
                        plotGroudhTruthCells(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2))
                        
                        for jj = 1:length(selectedActions)
                            
                            set(fig,'CurrentAxes',ha(jj+1))
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1,ha(jj+1));
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                            end
                        end
                        set(fig,'CurrentAxes',ha(length(selectedActions)+2))
                        plotLegends, title('Legend')
                        
                        set(fig,'CurrentAxes',ha(length(selectedActions)+3))
                        plotCharacteristics(cellIDs(j)), title('Characteristics')
                        
                        % Saving figure
                        savefigure(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_cell_', num2str(cell_metrics.UID(cellIDs(j)))])
                    end
                end

                function savefigure(fig,savePathIn,fileNameIn)
                    if saveFig.save
                        if saveFig.path == 1
                            savePath = fullfile(savePathIn,'summaryFigures');
                            if ~exist(savePath,'dir')
                                mkdir(savePathIn,'summaryFigures')
                            end
                        elseif saveFig.path == 2
                            [dirName,~,~] = fileparts(which('CellExplorer.m'));
                            savePath = fullfile(dirName,'summaryFigures');
                            if ~exist(savePath,'dir')
                                mkdir(dirName,'summaryFigures')
                            end
                        elseif saveFig.path == 3
                            if ~exist('dirNameCustom','var')
                                dirNameCustom = uigetdir;
                            end
                            savePath = dirNameCustom;
                        end
                        if saveFig.fileFormat == 1
                            saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
                        else
                            set(fig,'Units','Inches','Renderer','painters');
                            pos = get(fig,'Position');
                            set(fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]) 
                            print(fig, fullfile(savePath,[fileNameIn,'.pdf']),'-dpdf');
                        end
                    end
                end
            end
        end
        
        function  CancelGoTo_dialog
            % Closes dialog
            choice = '';
            delete(GoTo_dialog);
        end
    end

    function LoadPreferences(~,~)
        % Opens the preference .m file in matlab.
        MsgLog(['Opening settings file']);
        edit CellExplorer_Preferences.m
    end

    function reclassify_celltypes(~,~)
        % Reclassify all cells according to the initial algorithm
        answer = questdlg('Are you sure you want to reclassify all your cells?', 'Reclassification', 'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                saveStateToHistory(1:cell_metrics.general.cellCount)
                
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
                updatePutativeCellType
                uiresume(UI.fig);
                MsgLog('Succesfully reclassified cells',2);
        end
    end

    function undoClassification(~,~)
        % Undoes the most recent classification within 3 categories: cell-type
        % deep/superficial and brain region. Labels are left untouched.
        % Updates GUI to reflect the changes
        if size(history_classification,2) > 1
            clusClas(history_classification(end).cellIDs) = history_classification(end).cellTypes;
            cell_metrics.deepSuperficial(history_classification(end).cellIDs) = cellstr(history_classification(end).deepSuperficial);
            cell_metrics.labels(history_classification(end).cellIDs) = cellstr(history_classification(end).labels);
            cell_metrics.tags = history_classification(end).tags;
            cell_metrics.groups = history_classification(end).groups;
            cell_metrics.groundTruthClassification = history_classification(end).groundTruthClassification;
            cell_metrics.brainRegion(history_classification(end).cellIDs) = cellstr(history_classification(end).brainRegion);
            cell_metrics.deepSuperficial_num(history_classification(end).cellIDs) = history_classification(end).deepSuperficial_num;
            cell_metrics.deepSuperficialDistance(history_classification(end).cellIDs) = history_classification(end).deepSuperficialDistance;
            
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
            updateTags
            updatePutativeCellType
            
            % Button Deep-Superficial
            UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
            
            % Button brain region
            UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
            
            [cell_metrics.brainRegion_num,ID] = findgroups(cell_metrics.brainRegion);
            groups_ids.brainRegion_num = ID;
        else
            MsgLog('All steps have been undone. No further user actions tracked',2);
        end
        uiresume(UI.fig);
    end

    function updateCellCount
        % Updates the cell count in the cell-type listbox
        cell_class_count = histc(clusClas,1:length(UI.settings.cellTypes));
        cell_class_count = cellstr(num2str(cell_class_count'))';
        UI.listbox.cellTypes.String = strcat(UI.settings.cellTypes,' (',cell_class_count,')');
    end

    function updateCount
        % Updates the cell count in the custom groups listbox
        if Colorval > 1
            if UI.checkbox.groups.Value == 0
                plotClas11 = cell_metrics.(colorStr{Colorval});
                plotClasGroups = groups_ids.([colorStr{Colorval} '_num']);
                if iscell(plotClas11) && ~strcmp(colorStr{Colorval},'deepSuperficial')
                    plotClas11 = findgroups(plotClas11);
                elseif strcmp(colorStr{Colorval},'deepSuperficial')
                    [~,plotClas11] = ismember(plotClas11,plotClasGroups);
                end
                color_class_count = histc(plotClas11,[1:length(plotClasGroups)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(plotClasGroups,' (',color_class_count,')');
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
            end
        end
    end

    function saveDialog(~,~)
        % Called with the save button.
        % Two options are available
        % 1. Updates existing metrics
        % 2. Create new .mat-file
        
        answer = questdlg('How would you like to save the classification?', 'Save classification','Update existing metrics','Create new file','Update existing metrics'); % 'Update workspace metrics',
        % Handle response
        switch answer
            case 'Update existing metrics'
                assignin('base','cell_metrics',cell_metrics)
                saveMetrics(cell_metrics);
                try
                    
                catch exception
                    disp(exception.identifier)
                    MsgLog(['Failed to save file - see Command Window for details'],[3,4]);
                end
            case 'Create new file'
                if UI.BatchMode
                    [file,SavePath] = uiputfile('cell_metrics_batch.mat','Save metrics');
                else
                    [file,SavePath] = uiputfile('cell_metrics.mat','Save metrics');
                end
                if SavePath ~= 0
                    try
                        saveMetrics(cell_metrics,fullfile(SavePath,file));
                    catch exception
                        disp(exception.identifier)
                        MsgLog(['Failed to save file - see Command Window for details'],[3,4]);
                    end
                end
            case 'Cancel'
        end
    end

    function cell_metrics = saveCellMetricsStruct(cell_metrics)
        % Prepares the cell_metrics structure for saving generated info,
        % including putative cell-type, tSNE and classificationTrackChanges
        numeric_fields = fieldnames(cell_metrics);
        cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
        updatePutativeCellType
        
        % cell_metrics.general.SWR_batch = SWR_batch;
        cell_metrics.general.tSNE_metrics = tSNE_metrics;
        cell_metrics.general.classificationTrackChanges = classificationTrackChanges;
    end

    function saveMetrics(cell_metrics,file)
        % Save dialog
        % Saves adjustable metrics to either all sessions or the sessions
        % with registered changes
        MsgLog(['Saving metrics']);
        drawnow nocallbacks;
        cell_metrics = saveCellMetricsStruct(cell_metrics);
        
        if nargin > 1
            try
                save(file,'cell_metrics','-v7.3','-nocompression');
                MsgLog(['Classification saved to ', file],[1,2]);
            catch
                MsgLog(['Error saving metrics: ' file],4);
            end
        elseif UI.BatchMode
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
            cell_metricsTemp = cell_metrics; % clear cell_metrics
            ce_waitbar = waitbar(0,[num2str(sessionWithChanges),' sessions with changes'],'name','Saving cell metrics from batch','WindowStyle','modal');
            errorSaving = zeros(1,length(sessionWithChanges));
            for j = 1:length(sessionWithChanges)
                if ~ishandle(ce_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                waitbar(j/length(sessionWithChanges),ce_waitbar,['Session ' num2str(j),'/',num2str(length(sessionWithChanges)),': ', cell_metricsTemp.general.basenames{sessionID}])
                cellSubset = find(cell_metricsTemp.batchIDs==sessionID);
                if isfield(cell_metricsTemp.general,'saveAs')
                    saveAs = cell_metricsTemp.general.saveAs{sessionID};
                else
                    saveAs = 'cell_metrics';
                end
                try
                    % Creating backup metrics
                    createBackup(cell_metricsTemp,cellSubset)
                    
                    % Saving new metrics to file
                    matpath = fullfile(cell_metricsTemp.general.path{sessionID},[cell_metricsTemp.general.basenames{sessionID}, '.',saveAs,'.cellinfo.mat']);
                    matFileCell_metrics = matfile(matpath,'Writable',true);
                    
                    cell_metrics = matFileCell_metrics.cell_metrics;
                    if length(cellSubset) == size(cell_metrics.putativeCellType,2)
                        cell_metrics.labels = cell_metricsTemp.labels(cellSubset);
                        cell_metrics.deepSuperficial = cell_metricsTemp.deepSuperficial(cellSubset);
                        cell_metrics.deepSuperficialDistance = cell_metricsTemp.deepSuperficialDistance(cellSubset);
                        cell_metrics.brainRegion = cell_metricsTemp.brainRegion(cellSubset);
                        cell_metrics.putativeCellType = cell_metricsTemp.putativeCellType(cellSubset);
                        
                        cell_metrics.groups = getSubsetCellMetrics(cell_metricsTemp.groups,cellSubset);
                        cell_metrics.tags = getSubsetCellMetrics(cell_metricsTemp.tags,cellSubset);
                        cell_metrics.groundTruthClassification = getSubsetCellMetrics(cell_metricsTemp.groundTruthClassification,cellSubset);
                        matFileCell_metrics.cell_metrics = cell_metrics;
                        
                    end
                catch
                    MsgLog(['Error saving metrics for session: ' cell_metricsTemp.general.basenames{sessionID}],4);
                    errorSaving(j) = 1;
                end
            end
            if ishandle(ce_waitbar) && all(errorSaving==0)
                close(ce_waitbar)
                classificationTrackChanges = [];
                UI.menu.file.save.ForegroundColor = 'k';
                MsgLog(['Classifications succesfully saved to existing cell metrics files'],[1,2]);
            else
                MsgLog('Metrics were not succesfully saved for all sessions in batch',4);
            end
        else
            if isfield(cell_metrics.general,'path') && exist(cell_metrics.general.path,'dir')
                if isfield(cell_metrics.general,'saveAs')
                    saveAs = cell_metrics.general.saveAs;
                else
                    saveAs = 'cell_metrics';
                end
                try
                    createBackup(cell_metrics)
                    file = fullfile(cell_metrics.general.path,[cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat']);
                    save(file,'cell_metrics','-v7.3','-nocompression');
                    classificationTrackChanges = [];
                    UI.menu.file.save.ForegroundColor = 'k';
                    MsgLog(['Classification saved to ', file],[1,2]);
                catch
                    MsgLog(['Failed to save the cell metrics. Please choose a different path: ' cell_metrics.general.path],4);
                end
            else
                MsgLog(['The path does not exist. Please choose another path to save the metrics'],4);
            end
        end
    end
    
    function subsetOut = getSubsetCellMetrics(subsetIn,cellSubset)
        subsetOut = struct();
    	fields1 = fieldnames(subsetIn);
        for i = 1:numel(fields1)
            temp = intersect(subsetIn.(fields1{i}),cellSubset);
            if ~isempty(temp)
                subsetOut.(fields1{i}) = find(ismember(cellSubset,temp));
            end
        end
    end

    function SignificanceMetricsMatrix(~,~)
        % Performs a KS-test for selected two groups and displays a colored matrix with significance levels for relevant metrics
        
        if length(unique(plotClas(UI.params.subset)))==2
            % Cell metrics differences
            temp = fieldnames(cell_metrics);
            temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
            subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'batchIDs','placeCell','ripples_modulationSignificanceLevel','spikeGroup','maxWaveformChannelOrder','maxWaveformCh','maxWaveformCh1','entryID','UID','cluID','truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter','sessionID'})));
            plotClas_subset = plotClas(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            
            temp1 = UI.params.subset(find(plotClas_subset==ids(1)));
            temp2 = UI.params.subset(find(plotClas_subset==ids(2)));
            testset = plotClasGroups(nanUnique(plotClas_subset));
            [labels2,~]= sort(temp(subindex));
            [indx,~] = listdlg('PromptString',['Select the metrics to show in a rain cloud plot'],'ListString',labels2,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(labels2));
            % keyboard
            if ~isempty(indx)
                labels2 = labels2(indx);
                cell_metrics_effects = ones(1,length(indx));
                cell_metrics_effects2 = zeros(1,length(indx));
                for j = 1:length(indx)
                    fieldName = labels2{j};
                    if sum(isnan(cell_metrics.(fieldName)(temp1))) < length(temp1) && sum(isnan(cell_metrics.(fieldName)(temp2))) < length(temp2)
                        [h,p] = kstest2(cell_metrics.(fieldName)(temp1),cell_metrics.(fieldName)(temp2));
                        cell_metrics_effects(j)= p;
                        cell_metrics_effects2(j)= h;
                    end
                end
                image2 = log10(cell_metrics_effects);
                image2( intersect(find(~cell_metrics_effects2), find(image2<log10(0.05))) ) = -image2( intersect(find(~cell_metrics_effects2(:)), find(image2<log10(0.05))));
                
                figure('pos',[10 10 400 800],'DefaultAxesLooseInset',[.01,.01,.01,.01])
                imagesc(image2'),colormap(jet),colorbar, hold on
                if any(cell_metrics_effects<0.05 & cell_metrics_effects>=0.003)
                    line(1,find(cell_metrics_effects<0.05 & cell_metrics_effects>=0.003),'Marker','*','LineStyle','none','color','w','linewidth',1)
                end
                if sum(cell_metrics_effects<0.003)
                    line([0.9;1.1],[find(cell_metrics_effects<0.003);find(cell_metrics_effects<0.003)],'Marker','*','LineStyle','none','color','w','linewidth',1)
                end
                yticks(1:length(subindex))
                yticklabels(labels2)
                set(gca,'TickLabelInterpreter','none')
                caxis([-3,3]);
                title([testset{1} ' vs ' testset{2}],'Interpreter', 'none'), xticks(1), xticklabels({'KS-test'})
            end
        else
            MsgLog(['KS-test: please select a group of size two'],2);
        end
    end

    function generateRainCloudPlot(~,~)
        % Generates a rain cloud plot with KS statistics 
        % See https://github.com/RainCloudPlots/RainCloudPlots
        % Shows a dialog with metrics to plot and plots selected metrics in a new window. 
        temp = fieldnames(cell_metrics);
        temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
        subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'batchIDs','placeCell','_modulationSignificanceLevel','spikeGroup','maxWaveformChannelOrder','maxWaveformCh','maxWaveformCh1','entryID','UID','cluID','truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter','sessionID'})));
        [labels2,~]= sort(temp(subindex));
        [indx,~] = listdlg('PromptString','Select the metrics to show in the rain cloud plot','ListString',labels2,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(labels2));
        if ~isempty(indx)
            labels2 = labels2(indx);
            if length(indx)>12
                box_on = 0; % No box plots
                stats_offset = 0.06;
            else
                box_on = 1; % Shows box plots
                stats_offset = 0.03;
            end
            [plotRows,~]= numSubplots(length(indx)); % Determining optimal number of subplots
            fig = figure('Name','CellExplorer: Raincloud plot','NumberTitle','off','pos',UI.settings.figureSize);
            ha = tight_subplot(plotRows(1),plotRows(2),[.05 .02],[.03 .04],[.03 .03]);
            plotClas_subset = plotClas(UI.params.subset);
            for j = 1:length(indx)
                fieldName = labels2{j};
                set(fig,'CurrentAxes',ha(j)), hold on
                if UI.checkbox.logx.Value == 1
                    set(ha(j), 'XScale', 'log')
                end
                generateGroupRainCloudPlot(fieldName,UI.checkbox.logx.Value,1,box_on,stats_offset)
            end
            
            % Generating legends
            legendNames = plotClasGroups(nanUnique(plotClas(UI.params.subset)));
            for i = 1:length(legendNames)
                legendDots(i) = line(nan,nan,'Marker','.','LineStyle','none','color',clr_groups(i,:), 'MarkerSize',20);
            end
            legend(legendDots,legendNames);
            
            % Clearing extra plot axes
            if length(indx)<plotRows(1)*plotRows(2)
                for j = length(indx)+1:plotRows(1)*plotRows(2)
                    set(ha(j),'Visible','off')
                end
            end
        end
    end

    function generateGroupRainCloudPlot(fieldName,log_axis,plotStats,box_on,stats_offset)
        if ~all(isnan(cell_metrics.(fieldName)(UI.params.subset)))
            plotClas_subset = plotClas(UI.params.subset);
            counter = 1; % For aligning scatter data
            ids = nanUnique(plotClas_subset);
            for i = 1:length(ids)
                temp1 = UI.params.subset(find(plotClas_subset==ids(i)));
                if length(temp1)>1
                    ce_raincloud_plot(cell_metrics.(fieldName)(temp1),'box_on',box_on,'box_dodge',1,'line_width',1,'color',clr_groups(i,:),'alpha',0.4,'box_dodge_amount',0.025+(counter-1)*0.21,'dot_dodge_amount',0.13+(counter-1)*0.21,'bxfacecl',clr_groups(i,:),'box_col_match',1,'randomNumbers',UI.params.randomNumbers(temp1),'log_axis',log_axis,'normalization',UI.settings.rainCloudNormalization);
                    counter = counter + 1;
                end
            end
            axis tight, title(fieldName, 'interpreter', 'none'), yticks([]),
            if nanmin(cell_metrics.(fieldName)(UI.params.subset)) ~= nanmax(cell_metrics.(fieldName)(UI.params.subset)) && log_axis == 0
                xlim([nanmin(cell_metrics.(fieldName)(UI.params.subset)),nanmax(cell_metrics.(fieldName)(UI.params.subset))])
            elseif nanmin(cell_metrics.(fieldName)(UI.params.subset)) ~= nanmax(cell_metrics.(fieldName)(UI.params.subset)) && log_axis == 1 && any(cell_metrics.(fieldName)>0)
                xlim([nanmin(cell_metrics.(fieldName)(intersect(UI.params.subset,find(cell_metrics.(fieldName)>0)))),nanmax(cell_metrics.(fieldName)(intersect(UI.params.subset,find(cell_metrics.(fieldName)>0))))])
            end
            if plotStats
                plotStatRelationship(cell_metrics.(fieldName),stats_offset,log_axis) % Generates KS group statistics
            end
        else
            text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
        end
    end

    function plotStatRelationship(data1,stats_offset1,log_axis) 
        plotClas_subset = plotClas(UI.params.subset);
        groups = nanUnique(plotClas_subset);
        if length(groups)<10
            counter = 1;
            xlimits = xlim;
            x_width = xlimits(2)-xlimits(1);
            data11 = data1;
            if exist('log_axis','var') && log_axis==1
                stats_offset = 10.^(stats_offset1*(log10(xlimits(2))-log10(xlimits(1)))*(1:factorial(length(groups)))+log10(xlimits(2)));
                data11(data11<=0) = nan;
                data11 = log10(data11);
            else
                stats_offset = stats_offset1*x_width*[1:factorial(length(groups))]+xlimits(2);
            end
            for i = 1:length(groups)-1
                temp11 = UI.params.subset(find(plotClas_subset==groups(i)));
                for j = i+1:length(groups)
                    temp2 = UI.params.subset(find(plotClas_subset==groups(j)));
                    if ~all(isnan(data11(temp11))) && ~all(isnan(data11(temp2)))
                        [h,p] = kstest2(data11(temp11),data11(temp2));
                        if p <0.001
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21],'color','k','linewidth',3,'HitTest','off')
                        elseif p < 0.05
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21],'color','k','linewidth',2,'HitTest','off')
                        else
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21],'LineStyle','-','color',[0.5 0.5 0.5],'HitTest','off')
                        end
                        counter = counter + 1;
                    end
                end
            end
            xlim([xlimits(1),stats_offset(counter)])
        end
    end

    function rotateFig1
        % activates a rotation mode for subfig1 while maintaining the keyboard shortcuts and click functionality for the remaining plots
        set(UI.fig,'CurrentAxes',UI.panel.subfig_ax1.Children)
        rotate3d(subfig_ax(1),'on');
        h = rotate3d(subfig_ax(1));
        h.Enable = 'on';
        setAllowAxesRotate(h,subfig_ax(2),false);
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
    
    function [disallowRotation] = myRotateFilter(obj,~)
        disallowRotation = true;
        axnum = find(ismember(subfig_ax, gca));
        if UI.settings.customPlotHistograms == 3 && axnum == 1 && strcmp(get(UI.fig, 'selectiontype'),'extend') &&  ~isempty(UI.params.subset)
            um_axes = get(gca,'CurrentPoint');
            u = um_axes(1,1);
            v = um_axes(1,2);
            w = um_axes(1,3);
            HighlightFromPlot(u,v,w);
        elseif UI.settings.customPlotHistograms == 3 && axnum == 1 && strcmp(get(UI.fig, 'selectiontype'),'alt') &&  ~isempty(UI.params.subset)
            um_axes = get(gca,'CurrentPoint');
            u = um_axes(1,1);
            v = um_axes(1,2);
            w = um_axes(1,3);
            iii = FromPlot(u,v,0,w);
            if iii>0
                ii = iii;
                UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
                UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
                UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
                uiresume(UI.fig);
            end
        elseif isfield(get(obj),'ButtonDownFcn')
            % if a ButtonDownFcn has been defined for the object, then use that
            disallowRotation = ~isempty(get(obj,'ButtonDownFcn'));
        end
    end

    function initializeSession
        ii = 1;
        UI.params.ii_history = 1;
        if ~isfield(cell_metrics.general,'cellCount')
            cell_metrics.general.cellCount = size(cell_metrics.UID,2);
        end
        UI.params.randomNumbers = rand(1,cell_metrics.general.cellCount);
        
        % Initialize labels
        if ~isfield(cell_metrics, 'labels')
            cell_metrics.labels = repmat({''},1,cell_metrics.general.cellCount);
        end
        % Initialize groups
        if ~isfield(cell_metrics, 'groups')
            cell_metrics.groups = struct();
        end
        
        % Updates format of tags if outdated
        cell_metrics = verifyGroupFormat(cell_metrics,'tags');
        if ~isfield(cell_metrics, 'tags')
            cell_metrics.tags = struct();
        end
        tagsInMetrics = fieldnames(cell_metrics.tags)';
        UI.settings.tags = unique([UI.settings.tags tagsInMetrics]);
        UI.settings.tags(cellfun(@isempty, UI.settings.tags)) = [];
        
        % Initialize tags
        if isfield(UI,'tabs')
            initTags
        end

        % Initialize ground truth classification
        cell_metrics = verifyGroupFormat(cell_metrics,'groundTruthClassification');
        if ~isfield(cell_metrics, 'groundTruthClassification')
            % cell_metrics.groundTruthClassification = repmat({''},1,cell_metrics.general.cellCount);
            cell_metrics.groundTruthClassification = struct();
        end
        
        % Init ground truth cell list
        % groundTruthInMetrics = unique([cell_metrics.groundTruthClassification{:}]);
        groundTruthInMetrics = fieldnames(cell_metrics.groundTruthClassification)';
        UI.settings.groundTruth = unique([UI.settings.groundTruth groundTruthInMetrics]);
        UI.settings.groundTruth(cellfun(@isempty, UI.settings.groundTruth)) = [];
        
        % Initialize text filter
        idx_textFilter = 1:cell_metrics.general.cellCount;
        
        % Batch initialization
        if isfield(cell_metrics.general,'batch')
            UI.BatchMode = true;
        else
            UI.BatchMode = false;
            cell_metrics.batchIDs = ones(1,cell_metrics.general.cellCount);
        end
        
        % Fieldnames
        metrics_fieldsNames = fieldnames(cell_metrics);
        table_fieldsNames = metrics_fieldsNames(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'cell','double'})));
        table_fieldsNames(find(contains(table_fieldsNames,UI.settings.tableOptionsToExlude)))=[];
        
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
                
            elseif ~UI.BatchMode
                if isfield(cell_metrics.general,'SWR')
                    cell_metrics.general.SWR_batch = cell_metrics.general.SWR;
                else
                    cell_metrics.general.SWR_batch = [];
                end
            else
                cell_metrics.general.SWR_batch = [];
                for i = 1:length(cell_metrics.general.basepaths)
                    if isfield(cell_metrics.general.batch{i},'SWR')
                        cell_metrics.general.SWR_batch{i} = cell_metrics.general.batch{i}.SWR;
                    else
                        cell_metrics.general.SWR_batch{i} = [];
                    end
                end
            end
        else
            cell_metrics.general.SWR_batch = SWR_in;
        end
        
        % Plotting menues initialization
        fieldsMenuCells = metrics_fieldsNames;
        fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fieldsMenuCells(find(contains(fieldsMenuCells,UI.settings.fieldsMenuMetricsToExlude)))=[];
        fieldsMenuCells = sort(fieldsMenuCells);
        groups_ids = [];
        
        for i = 1:length(fieldsMenuCells)
            if strcmp(fieldsMenuCells{i},'deepSuperficial')
                cell_metrics.deepSuperficial_num = ones(1,length(cell_metrics.deepSuperficial));
                for j = 1:length(UI.settings.deepSuperficial)
                    cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.settings.deepSuperficial{j}))=j;
                end
                groups_ids.deepSuperficial_num = UI.settings.deepSuperficial;
            elseif iscell(cell_metrics.(fieldsMenuCells{i})) && size(cell_metrics.(fieldsMenuCells{i}),1) == 1 && size(cell_metrics.(fieldsMenuCells{i}),2) == cell_metrics.general.cellCount
                cell_metrics.(fieldsMenuCells{i})(find(cell2mat(cellfun(@(X) isempty(X), cell_metrics.animal,'uni',0)))) = {''};
                [cell_metrics.([fieldsMenuCells{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenuCells{i}));
                groups_ids.([fieldsMenuCells{i},'_num']) = ID;
            end
        end
        clear fieldsMenuCells
        
        fieldsMenu = fieldnames(cell_metrics);
        structDouble = strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'double');
        structSize = cell2mat(struct2cell(structfun(@size,cell_metrics,'UniformOutput',0)));
        structNumeric = cell2mat(struct2cell(structfun(@isnumeric,cell_metrics,'UniformOutput',0)));
        fieldsMenu = sort(fieldsMenu(structDouble & structNumeric & structSize(:,1) == 1 & structSize(:,2) == cell_metrics.general.cellCount));
        
        % Metric table initialization
        table_metrics = cell(size(table_fieldsNames,1),cell_metrics.general.cellCount);
        for i = 1:size(table_fieldsNames,1)
            if isnumeric(cell_metrics.(table_fieldsNames{i})') && verLessThan('matlab', '9.3')
                table_string = string(cell_metrics.(table_fieldsNames{i}));
                table_string(isnan(cell_metrics.(table_fieldsNames{i}))) = "";
                table_metrics(i,:) = cellstr(table_string);
            elseif isnumeric(cell_metrics.(table_fieldsNames{i})')
                table_metrics(i,:) = cellstr(string(cell_metrics.(table_fieldsNames{i})));
            else
                table_metrics(i,:) = cellstr(cell_metrics.(table_fieldsNames{i}));
            end
        end
        if UI.settings.metricsTable==1
            UI.table.Data = [table_fieldsNames, table_metrics(:,ii)];
        elseif UI.settings.metricsTable==2
            updateCellTableData;
        end
        
        % waveform initialization
        filtWaveform = [];
        step_size = [cellfun(@diff,cell_metrics.waveforms.time,'UniformOutput',false)];
        time_waveforms_zscored = [max(cellfun(@min, cell_metrics.waveforms.time)):min([step_size{:}]):min(cellfun(@max, cell_metrics.waveforms.time))];
        if ~isfield(cell_metrics.waveforms,'filt_zscored') || ~isfield(cell_metrics.waveforms,'filt_absolute') || size(cell_metrics.waveforms.filt_zscored,2) ~= cell_metrics.general.cellCount
            statusUpdate('Initializing filtered waveforms')
            for i = 1:length(cell_metrics.waveforms.filt)
                filtWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.filt{i},time_waveforms_zscored,'spline',nan);
            end
            cell_metrics.waveforms.filt_absolute = filtWaveform;
            cell_metrics.waveforms.filt_zscored = (filtWaveform-nanmean(filtWaveform))./nanstd(filtWaveform);
        end
        
        % 'All raw waveforms'
        if isfield(cell_metrics.waveforms,'raw') && (~isfield(cell_metrics.waveforms,'raw_zscored') || ~isfield(cell_metrics.waveforms,'raw_absolute') || size(cell_metrics.waveforms.raw_zscored,2) ~= cell_metrics.general.cellCount)
            statusUpdate('Initializing raw waveforms')
            rawWaveform = [];
            for i = 1:length(cell_metrics.waveforms.raw)
                if isempty(cell_metrics.waveforms.raw{i})
                    rawWaveform(:,i) = zeros(size(time_waveforms_zscored));
                else
                    rawWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.raw{i},time_waveforms_zscored,'spline',nan);
                end
            end
                cell_metrics.waveforms.raw_absolute = rawWaveform;
                cell_metrics.waveforms.raw_zscored = (rawWaveform-nanmean(rawWaveform))./nanstd(rawWaveform);
            clear rawWaveform
        end
        
        if ~isfield(cell_metrics.acg,'wide_normalized') || size(cell_metrics.acg.wide_normalized,2) ~= size(cell_metrics.acg.wide,2)
            statusUpdate('Initializing wide ACGs')
            cell_metrics.acg.wide_normalized = normalize_range(cell_metrics.acg.wide);
        end
        if ~isfield(cell_metrics.acg,'narrow_normalized') || size(cell_metrics.acg.narrow_normalized,2) ~= size(cell_metrics.acg.narrow,2)
            statusUpdate('Initializing narrow ACGs')
            cell_metrics.acg.narrow_normalized = normalize_range(cell_metrics.acg.narrow);
        end
        
        if isfield(cell_metrics.acg,'log10') && (~isfield(cell_metrics.acg,'log10_occurrence') || ~isfield(cell_metrics.acg,'log10_rate') || size(cell_metrics.acg.log10_rate,2) ~= size(cell_metrics.acg.log10,2))
            statusUpdate('Initializing log10 ACGs')
            cell_metrics.acg.log10_rate = normalize_range(cell_metrics.acg.log10);
            cell_metrics.acg.log10_occurrence = normalize_range(cell_metrics.acg.log10.*diff(10.^UI.settings.ACGLogIntervals)');
        end
        
        if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_occurrence') || ~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
            statusUpdate('Initializing log10 ACGs')
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10);
            cell_metrics.isi.log10_occurrence = normalize_range(cell_metrics.isi.log10.*diff(10.^UI.settings.ACGLogIntervals)');
        end
        
        % filtWaveform, acg2, acg1, plot
        if isfield(cell_metrics.general,'tSNE_metrics')
            tSNE_fieldnames = fieldnames(cell_metrics.general.tSNE_metrics);
            for i = 1:length(tSNE_fieldnames)
                if ~isempty(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i})) && size(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i}),1) == length(cell_metrics.UID)
                    tSNE_metrics.(tSNE_fieldnames{i}) = cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i});
                end
            end
        else
            tSNE_metrics = [];
        end
        
        if UI.settings.tSNE.calcWideAcg && ~isfield(tSNE_metrics,'acg_wide')
            statusUpdate('Calculating tSNE space for wide ACGs')
            tSNE_metrics.acg_wide = tsne([cell_metrics.acg.wide_normalized(ceil(size(cell_metrics.acg.wide_normalized,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcNarrowAcg && ~isfield(tSNE_metrics,'acg_narrow')
            statusUpdate('Calculating tSNE space for narrow ACGs')
            tSNE_metrics.acg_narrow = tsne([cell_metrics.acg.narrow_normalized(ceil(size(cell_metrics.acg.narrow_normalized,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcLogAcg && ~isfield(tSNE_metrics,'acg_log10') && isfield(cell_metrics.acg,'log10_normalized')
            statusUpdate('Calculating tSNE space for log ACGs')
            tSNE_metrics.acg_log10 = tsne([cell_metrics.acg.log10(ceil(size(cell_metrics.acg.log10_rate,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcLogIsi && ~isfield(tSNE_metrics,'isi_log10') && isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10_normalized')
            statusUpdate('Calculating tSNE space for log ISIs')
            tSNE_metrics.isi_log10 = tsne([cell_metrics.isi.log10(ceil(size(cell_metrics.isi.log10_rate,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        
        if UI.settings.tSNE.calcFiltWaveform && ~isfield(tSNE_metrics,'filtWaveform')
            statusUpdate('Calculating tSNE space for filtered waveforms')
            X = cell_metrics.waveforms.filt_zscored';
            tSNE_metrics.filtWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcRawWaveform && ~isfield(tSNE_metrics,'rawWaveform') && isfield(cell_metrics.waveforms,'raw')
            statusUpdate('Calculating tSNE space for raw waveforms')
            X = cell_metrics.waveforms.raw_zscored';
            if ~isempty(find(~any(isnan(X))))
                tSNE_metrics.rawWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
            end
        end
        
        if ~isfield(tSNE_metrics,'plot')
            statusUpdate('Initializing t-SNE plot')
            UI.settings.tSNE.metrics = intersect(UI.settings.tSNE.metrics,fieldnames(cell_metrics));
            if ~isempty(UI.settings.tSNE.metrics)
                X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.settings.tSNE.metrics,'UniformOutput',false));
                X(isnan(X) | isinf(X)) = 0;
                tSNE_metrics.plot = tsne(X','Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
            end
        end
        
        % Response curves
        UI.x_bins.thetaPhase = [-1:0.05:1]*pi;
        UI.x_bins.thetaPhase = UI.x_bins.thetaPhase(1:end-1)+diff(UI.x_bins.thetaPhase([1,2]))/2;
        if isfield(cell_metrics.responseCurves,'thetaPhase') && (~isfield(cell_metrics.responseCurves,'thetaPhase_zscored')  || size(cell_metrics.responseCurves.thetaPhase_zscored,2) ~= length(cell_metrics.troughToPeak))
            statusUpdate('Initializing response curves')
            thetaPhaseCurves = nan(length(UI.x_bins.thetaPhase),cell_metrics.general.cellCount);
            for i = 1:length(cell_metrics.responseCurves.thetaPhase)
                if isempty(cell_metrics.responseCurves.thetaPhase{i}) || any(isnan(cell_metrics.responseCurves.thetaPhase{i}))
                    thetaPhaseCurves(:,i) = nan(size(UI.x_bins.thetaPhase));
                elseif UI.BatchMode
                    thetaPhaseCurves(:,i) = interp1(cell_metrics.general.batch{cell_metrics.batchIDs(i)}.responseCurves.thetaPhase.x_bins,cell_metrics.responseCurves.thetaPhase{i}',UI.x_bins.thetaPhase,'spline',nan);
                else
                    thetaPhaseCurves(:,i) = interp1(cell_metrics.general.responseCurves.thetaPhase.x_bins,cell_metrics.responseCurves.thetaPhase{i},UI.x_bins.thetaPhase,'spline',nan);
                end
            end
            cell_metrics.responseCurves.thetaPhase_zscored = (thetaPhaseCurves-nanmean(thetaPhaseCurves))./nanstd(thetaPhaseCurves);
            clear thetaPhaseCurves
        end
        
        % Setting initial settings for plots, popups and listboxes
        UI.popupmenu.xData.String = fieldsMenu;
        UI.popupmenu.yData.String = fieldsMenu;
        UI.popupmenu.zData.String = fieldsMenu;
        plotX = cell_metrics.(UI.settings.plotXdata);
        plotY  = cell_metrics.(UI.settings.plotYdata);
        plotZ  = cell_metrics.(UI.settings.plotZdata);
        plotMarkerSize  = cell_metrics.(UI.settings.plotMarkerSizedata);
        
        UI.popupmenu.xData.Value = find(strcmp(fieldsMenu,UI.settings.plotXdata));
        UI.popupmenu.yData.Value = find(strcmp(fieldsMenu,UI.settings.plotYdata));
        UI.popupmenu.zData.Value = find(strcmp(fieldsMenu,UI.settings.plotZdata));
        UI.popupmenu.markerSizeData.Value = find(strcmp(fieldsMenu,UI.settings.plotMarkerSizedata));
        
        UI.plot.xTitle = UI.settings.plotXdata;
        UI.plot.yTitle = UI.settings.plotYdata;
        UI.plot.zTitle = UI.settings.plotZdata;
        
        UI.listbox.cellTypes.Value = 1:length(UI.settings.cellTypes);
        classes2plot = 1:length(UI.settings.cellTypes);
        
        if isfield(cell_metrics,'putativeConnections')
            UI.monoSyn.disp = UI.settings.monoSynDispIn;
        else
            UI.monoSyn.disp = 'None';
        end
        
        % History function initialization
        if isfield(cell_metrics.general,'classificationTrackChanges') && ~isempty(cell_metrics.general.classificationTrackChanges)
            classificationTrackChanges = cell_metrics.general.classificationTrackChanges;
            if isfield(UI,'pushbutton')
                UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
            end
        else
            classificationTrackChanges = [];
            if isfield(UI,'pushbutton')
                UI.menu.file.save.ForegroundColor = 'k';
            end
        end
        history_classification = [];
        history_classification(1).cellIDs = 1:cell_metrics.general.cellCount;
        history_classification(1).cellTypes = clusClas;
        history_classification(1).deepSuperficial = cell_metrics.deepSuperficial;
        history_classification(1).labels = cell_metrics.labels;
        history_classification(1).tags = cell_metrics.tags;
        history_classification(1).groups = cell_metrics.groups;
        history_classification(1).groundTruthClassification = cell_metrics.groundTruthClassification;
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
        
        waveformOptions = {'Waveforms (single)';'Waveforms (all)'};
        if isfield(cell_metrics.waveforms,'filt_all')
            waveformOptions = [waveformOptions;'Waveforms (across channels)'];
        end
        waveformOptions = [waveformOptions;'Waveforms (image)'];
        
        if isfield(cell_metrics,'trilat_x') && isfield(cell_metrics,'trilat_y')
            waveformOptions = [waveformOptions;'Trilaterated position'];
        end
        
        if isfield(tSNE_metrics,'filtWaveform')
            waveformOptions = [waveformOptions;'Waveforms (tSNE)'];
        end
        if isfield(cell_metrics.waveforms,'raw')
            waveformOptions2 = {'Raw waveforms (single)';'Raw waveforms (all)'};
            if isfield(tSNE_metrics,'rawWaveform')
                waveformOptions2 = [waveformOptions2;'Raw waveforms (tSNE)'];
            end
        else
            waveformOptions2 = {};
        end
        acgOptions = {'ACGs (single)';'ACGs (all)';'ACGs (image)';'CCGs (image)'};
        if isfield(cell_metrics,'isi')
            acgOptions = [acgOptions;'ISIs (single)';'ISIs (all)';'ISIs (image)'];
        end
        tSNE_list = {'acg_narrow','acg_wide','acg_log10','isi_log10'};
        tSNE_listLabels = {'tSNE of narrow ACGs','tSNE of wide ACGs','tSNE of log ACGs','tSNE of log ISIs'};
        for i = 1:length(tSNE_list)
            if isfield(tSNE_metrics,tSNE_list{i})
                acgOptions = [acgOptions;tSNE_listLabels{i}];
            end
        end
        if isfield(cell_metrics.responseCurves,'thetaPhase_zscored')
            responseCurvesOptions = {'RCs_thetaPhase';'RCs_thetaPhase (all)';'RCs_thetaPhase (image)'};
        else
            responseCurvesOptions = {};
        end
        if isfield(cell_metrics.responseCurves,'firingRateAcrossTime')
            responseCurvesOptions = [responseCurvesOptions;'RCs_firingRateAcrossTime' ;'RCs_firingRateAcrossTime (image)' ;'RCs_firingRateAcrossTime (all)'];
        end
        % Custom plot options
        customPlotOptions = what('customPlots');
        customPlotOptions = cellfun(@(X) X(1:end-2),customPlotOptions.m,'UniformOutput', false);
        customPlotOptions(strcmpi(customPlotOptions,'template')) = [];
        
        %         cell_metricsFieldnames = fieldnames(cell_metrics,'-full');
        structFieldsType = metrics_fieldsNames(find(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'struct')));
        plotOptions = {};
        for j = 1:length(structFieldsType)
            if ~any(strcmp(structFieldsType{j},{'general','putativeConnections'}))
                plotOptions = [plotOptions;strcat(structFieldsType{j},{'_'},fieldnames(cell_metrics.(structFieldsType{j})))];
            end
        end
        %         customPlotOptions = customPlotOptions(   (strcmp(temp,'double') & temp1>1 & temp2==size(cell_metrics.spikeCount,2) )   );
        %         customPlotOptions = [customPlotOptions;customPlotOptions2];
        plotOptions(find(contains(plotOptions,UI.settings.plotOptionsToExlude)))=[]; %
        plotOptions = unique([waveformOptions; waveformOptions2; acgOptions; 'Connectivity graph'; customPlotOptions; plotOptions;responseCurvesOptions],'stable');
        
        % Initilizing views
        for i = 1:6
            UI.popupmenu.customplot{i}.String = plotOptions;
            if any(strcmp(UI.settings.customCellPlotIn{i},UI.popupmenu.customplot{i}.String)); UI.popupmenu.customplot{i}.Value = find(strcmp(UI.settings.customCellPlotIn{i},UI.popupmenu.customplot{i}.String)); else; UI.popupmenu.customplot{i}.Value = 1; end
            UI.settings.customPlot{i} = plotOptions{UI.popupmenu.customplot{i}.Value};
        end
        
        % Custom colorgroups
        colorMenu = metrics_fieldsNames;
        colorMenu = colorMenu(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fields2keep = [];
        for i = 1:length(colorMenu)
            if ~any(cell2mat(cellfun(@isnumeric,cell_metrics.(colorMenu{i}),'UniformOutput',false))) && ~contains(colorMenu{i},UI.settings.menuOptionsToExlude )
                fields2keep = [fields2keep,i];
            end
        end
        colorMenu = ['cell-type';sort(colorMenu(fields2keep))];
        
        updateColorMenuCount
        
        plotClas = clusClas;
        UI.popupmenu.groups.Value = 1;
        clasLegend = 0;
        UI.settings.customPlot{2} = UI.settings.customCellPlotIn{2};
        UI.checkbox.groups.Value = 0;
        
        % Init synaptic connections
        if isfield(cell_metrics,'synapticEffect')
            UI.cells.excitatory = find(strcmp(cell_metrics.synapticEffect,'Excitatory'));
            UI.cells.inhibitory = find(strcmp(cell_metrics.synapticEffect,'Inhibitory'));
        end
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && ~isempty(cell_metrics.putativeConnections.excitatory)
            UI.cells.excitatoryPostsynaptic = unique(cell_metrics.putativeConnections.excitatory(:,2));
        else
            UI.cells.excitatoryPostsynaptic = [];
        end
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory') && ~isempty(cell_metrics.putativeConnections.inhibitory)
            UI.cells.inhibitoryPostsynaptic = unique(cell_metrics.putativeConnections.inhibitory(:,2));
        else
            UI.cells.inhibitoryPostsynaptic = [];
        end
        
        % Spikes and event initialization
        spikes = [];
        events = [];
        
        % fixed axes limits for subfig2 and subfig3 to increase performance
        fig2_axislimit_x = [min(cell_metrics.troughToPeak * 1000),max(cell_metrics.troughToPeak * 1000)];
        fig2_axislimit_y = [min(cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012>0)),max(cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012<Inf))];
        fig3_axislimit_x = [min(tSNE_metrics.plot(:,1)), max(tSNE_metrics.plot(:,1))];
        fig3_axislimit_y = [min(tSNE_metrics.plot(:,2)), max(tSNE_metrics.plot(:,2))];
        
        % Updating reference and ground truth data if already loaded
        UI.settings.referenceData = 'None';
        UI.settings.groundTruthData = 'None';
        if ~isempty(reference_cell_metrics)
            [reference_cell_metrics,referenceData] = initializeReferenceData(reference_cell_metrics,'reference');
            initReferenceDataTab
        end
        if ~isempty(groundTruth_cell_metrics)
            [groundTruth_cell_metrics,groundTruthData] = initializeReferenceData(groundTruth_cell_metrics,'groundTruth');
            initGroundTruthTab
        end
        
        subsetGroundTruth = [];
        % Updating figure name
        UI.fig.Name = ['CellExplorer v' num2str(CellExplorerVersion), ': ',cell_metrics.general.basename];
        
        % Initialize spike plot options
        customSpikePlotOptions = what('customSpikesPlots');
        customSpikePlotOptions = cellfun(@(X) X(1:end-2),customSpikePlotOptions.m,'UniformOutput', false);
        customSpikePlotOptions(strcmpi(customSpikePlotOptions,'spikes_template')) = [];
        spikesPlots = {};
        for i = 1:length(customSpikePlotOptions)
            spikesPlots.(customSpikePlotOptions{i}) = customSpikesPlots.(customSpikePlotOptions{i});
        end
    end

    function updateColorMenuCount
        colorMenu2 = colorMenu;
        for i = 2:numel(colorMenu2)
            color_class_count = unique(cell_metrics.(colorMenu2{i}));
            color_class_count = sum(~ismember(color_class_count,''));
            colorMenu2{i} = strcat(colorMenu2{i},' (',num2str(color_class_count),')');
        end
        UI.popupmenu.groups.String = colorMenu2;
    end

    function statusUpdate(message)
        if ishandle(ce_waitbar)
            waitbar(1,ce_waitbar,message);
        else
            timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
            message2 = sprintf('[%s] %s', timestamp, message);
            disp(message2);
        end
    end

    function [cell_metrics,referenceData,fig2_axislimit_x1,fig2_axislimit_y1] = initializeReferenceData(cell_metrics,inputType)
        
        if strcmp(inputType,'reference')
            % Cell type initialization
            referenceData.cellTypes = unique([UI.settings.cellTypes,cell_metrics.putativeCellType],'stable');
            clear referenceData1
            referenceData.clusClas = ones(1,length(cell_metrics.putativeCellType));
            for i = 1:length(referenceData.cellTypes)
                referenceData.clusClas(strcmp(cell_metrics.putativeCellType,referenceData.cellTypes{i}))=i;
            end
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas,[1:length(referenceData.cellTypes)+1])'))';
        else
            % Ground truth initialization
            clear groundTruthData1
            referenceData.groundTruthTypes = fieldnames(cell_metrics.groundTruthClassification)';
            for i = 1:numel(referenceData.groundTruthTypes)
                referenceData.clusClas(cell_metrics.groundTruthClassification.(referenceData.groundTruthTypes{i})) = i;
            end
%             [referenceData.clusClas, referenceData.groundTruthTypes] = findgroups([cell_metrics.groundTruthClassification{:}]);
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas)'))';
        end
        fig2_axislimit_x1 = [min([cell_metrics.troughToPeak * 1000,fig2_axislimit_x(1)]),max([cell_metrics.troughToPeak * 1000, fig2_axislimit_x(2)])];
        fig2_axislimit_y1 = [min([cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012>0),fig2_axislimit_y(1)]),max([cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012<Inf),fig2_axislimit_y(2)])];
        
        % Creating surface of reference points
        referenceData.x = linspace(fig2_axislimit_x1(1),fig2_axislimit_x1(2),UI.settings.binCount);
        referenceData.y = 10.^(linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),UI.settings.binCount));
        referenceData.y1 = linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),UI.settings.binCount);
        
        if strcmp(inputType,'reference')
            colors = (1-(UI.settings.cellTypeColors)) * 250;
        else
            colors = (1-(UI.settings.groundTruthColors)) * 250;
        end
        temp = unique(referenceData.clusClas);
        
        referenceData.z = zeros(length(referenceData.x)-1,length(referenceData.y)-1,3,size(colors,1));
        for i = temp
            idx = find(referenceData.clusClas==i);
            [z_referenceData_temp,~,~] = histcounts2(cell_metrics.troughToPeak(idx) * 1000, cell_metrics.burstIndex_Royer2012(idx),referenceData.x,referenceData.y,'norm','probability');
            referenceData.z(:,:,:,i) = bsxfun(@times,repmat(conv2(z_referenceData_temp,K,'same'),1,1,3),reshape(colors(i,:),1,1,[]));
            
        end
        referenceData.x = referenceData.x(1:end-1)+diff(referenceData.x([1,2]));
        referenceData.y = 10.^(linspace(log10(fig2_axislimit_y(1)),log10(fig2_axislimit_y(2)),UI.settings.binCount) + (log10(fig2_axislimit_y(2))-log10(fig2_axislimit_y(1)))/UI.settings.binCount/2);
        referenceData.y = referenceData.y(1:end-1);
        
        referenceData.selection = temp;
        
        % 'All raw waveforms'
        if isfield(cell_metrics.waveforms,'raw')
            rawWaveform = [];
            for i = 1:length(cell_metrics.waveforms.raw)
                if isempty(cell_metrics.waveforms.raw{i})
                    rawWaveform(:,i) = zeros(size(time_waveforms_zscored));
                else
                    rawWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.raw{i},time_waveforms_zscored,'spline',nan);
                end
            end
            if ~isfield(cell_metrics.waveforms,'raw_zscored')  || size(cell_metrics.waveforms.raw,2) ~= size(cell_metrics.waveforms.raw_zscored,2)
                cell_metrics.waveforms.raw_zscored = (rawWaveform-nanmean(rawWaveform))./nanstd(rawWaveform);
            end
            clear rawWaveform
        end
        
        if ~isfield(cell_metrics.acg,'wide_normalized')
            cell_metrics.acg.wide_normalized = normalize_range(cell_metrics.acg.wide);
        end
        if ~isfield(cell_metrics.acg,'narrow_normalized')
            cell_metrics.acg.narrow_normalized = normalize_range(cell_metrics.acg.narrow);
        end
        
        if isfield(cell_metrics.acg,'log10') && (~isfield(cell_metrics.acg,'log10_rate') || size(cell_metrics.acg.log10_rate,2) ~= size(cell_metrics.acg.log10,2))
            cell_metrics.acg.log10_rate = normalize_range(cell_metrics.acg.log10);
            cell_metrics.acg.log10_occurrence = normalize_range(cell_metrics.acg.log10.*diff(10.^UI.settings.ACGLogIntervals)');
        end
        
        if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10);
            cell_metrics.isi.log10_occurrence = normalize_range(cell_metrics.isi.log10.*diff(10.^UI.settings.ACGLogIntervals)');
        end
    end

    function ToggleHeatmapFiringRateMaps(~,~)
        % Enable/Disable the ACG fit
        if ~UI.settings.firingRateMap.showHeatmap
            UI.settings.firingRateMap.showHeatmap = true;
            UI.menu.display.showHeatmap.Checked = 'on';
        else
            UI.settings.firingRateMap.showHeatmap = false;
            UI.menu.display.showHeatmap.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function ToggleFiringRateMapShowLegend(~,~)
        % Enable/Disable the ACG fit
        if ~UI.settings.firingRateMap.showLegend
            UI.settings.firingRateMap.showLegend = true;
            UI.menu.display.firingRateMapShowLegend.Checked = 'on';
        else
            UI.settings.firingRateMap.showLegend = false;
            UI.menu.display.firingRateMapShowLegend.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function ToggleFiringRateMapShowHeatmapColorbar(~,~)
        % Enable/Disable the ACG fit
        if ~UI.settings.firingRateMap.showHeatmapColorbar
            UI.settings.firingRateMap.showHeatmapColorbar = true;
            UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on';
        else
            UI.settings.firingRateMap.showHeatmapColorbar = false;
            UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function DatabaseSessionDialog(~,~)
        % Load sessions from the database.
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
        drawnow nocallbacks;
        if isempty(db) && exist('db_cell_metrics_session_list.mat','file')
            load('db_cell_metrics_session_list.mat')
        elseif isempty(db)
            LoadDB_sessionlist
        end   
        
        loadDB.dialog = dialog('Position', [300, 300, 1000, 565],'Name','CellExplorer: database sessions','WindowStyle','modal', 'resize', 'on','visible','off'); movegui(loadDB.dialog,'center'), set(loadDB.dialog,'visible','on')
        loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 );
        loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        loadDB.sessionList = uitable(loadDB.VBox,'Data',db.dataTable,'Position',[10, 50, 880, 457],'ColumnWidth',{20 30 210 50 120 70 160 110 110 100},'columnname',{'','#','Session','Cells','Animal','Species','Behaviors','Investigator','Repository','Brain regions'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized'); % ,'CellSelectionCallback',@ClicktoSelectFromTable
        loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        set(loadDB.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[580, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[740, 25, 150, 20],'Units','normalized','String','Repositories','HorizontalAlignment','center','Units','normalized');
        loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 560, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
        loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[580, 5, 150, 22],'Units','normalized','String',{'Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[740, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
        loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 580, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[800, 5, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog,'Units','normalized');
        
        UpdateSummaryText
        if exist('cell_metrics','var') && ~isempty(cell_metrics)
            loadDB.sessionList.Data(find(ismember(loadDB.sessionList.Data(:,3),unique(cell_metrics.sessionName))),1) = {true};
        end
        uicontrol(loadDB.popupmenu.filter)
        
        uiwait(loadDB.dialog)
        
        function ReloadSessionlist
            LoadDB_sessionlist
            Button_DB_filterList
        end
        
        function UpdateSummaryText
            cellCount = sum(cell2mat( cellfun(@(x) str2double(x),loadDB.sessionList.Data(:,4),'UniformOutput',false)));
            loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' session(s) with ', num2str(cellCount),' cells from ',num2str(length(unique(loadDB.sessionList.Data(:,5)))),' animal(s). Updated at: ', datestr(db.refreshTime)];
        end
        
        function Button_DB_filterList
            if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
                newStr2 = split(loadDB.popupmenu.filter.String,' & ');
                idx_textFilter2 = zeros(length(newStr2),size(db.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},' | ');
                    idx_textFilter2(i,:) = contains(db.sessionList,newStr3,'IgnoreCase',true);
                end
                idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
            else
                idx1 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.sorting.Value == 2 % Cell count
                cellCount = cell2mat( cellfun(@(x) x.spikeSorting.cellCount,db.sessions,'UniformOutput',false));
                [~,idx2] = sort(cellCount(db.index),'descend');
            elseif loadDB.popupmenu.sorting.Value == 3 % Animal
                [~,idx2] = sort(db.menu_animals(db.index));
            elseif loadDB.popupmenu.sorting.Value == 4 % Species
                [~,idx2] = sort(db.menu_species(db.index));
            elseif loadDB.popupmenu.sorting.Value == 5 % Behavioral paradigm
                [~,idx2] = sort(db.menu_behavioralParadigm(db.index));
            elseif loadDB.popupmenu.sorting.Value == 6 % Investigator
                [~,idx2] = sort(db.menu_investigator(db.index));
            elseif loadDB.popupmenu.sorting.Value == 7 % Data repository
                [~,idx2] = sort(db.menu_repository(db.index));
            else
                idx2 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.repositories.Value == 2
                idx3 = find(ismember(db.menu_repository(db.index),fieldnames(db_settings.repositories)));
            else
                idx3 = 1:size(db.dataTable,1);
            end
            
            idx2 = intersect(idx2,idx1,'stable');
            idx2 = intersect(idx2,idx3,'stable');
            loadDB.sessionList.Data = db.dataTable(idx2,:);
            UpdateSummaryText
        end
        
        function button_DB_selectAll
            loadDB.sessionList.Data(:,1) = {true};
        end
        
        function button_DB_deselectAll
            loadDB.sessionList.Data(:,1) = {false};
        end
        
        function CloseDB_dialog
            indx = cell2mat(cellfun(@str2double,loadDB.sessionList.Data(find([loadDB.sessionList.Data{:,1}])',2),'un',0));
            delete(loadDB.dialog);
            if ~isempty(indx)
                if length(indx)==1 % Loading single session
                    try
                        session = db.sessions{db.index(indx)};
                        basename = session.name;
                        if ~any(strcmp(session.repositories{1},fieldnames(db_settings.repositories)))
                            MsgLog(['The respository ', session.repositories{1} ,' has not been defined on this computer. Please edit db_local_repositories and provide the path'],4)
                            edit db_local_repositories.m
                            return
                        end
                        if strcmp(session.repositories{1},'NYUshare_Datasets')
                            Investigator_name = strsplit(session.investigator,' ');
                            path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                            basepath = fullfile(db_settings.repositories.(session.repositories{1}), path_Investigator,session.animal, session.name);
                        else
                            basepath = fullfile(db_settings.repositories.(session.repositories{1}), session.animal, session.name);
                        end
                        
                        if ~isempty(session.spikeSorting.relativePath)
                            clusteringpath = fullfile(basepath, session.spikeSorting.relativePath{1});
                        else
                            clusteringpath = basepath;
                        end
                        SWR_in = {};
                        successMessage = LoadSession;
                    end
                    
                else % Loading multiple sessions
                    % Setting paths from db struct
                    db_basename = {};
                    db_basepath = {};
                    db_clusteringpath = {};
                    db_basename = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
                    i_db_subset_all = db.index(indx);
                    for i_db = 1:length(i_db_subset_all)
                        i_db_subset = i_db_subset_all(i_db);
                        if ~any(strcmp(db.sessions{i_db_subset}.repositories{1},fieldnames(db_settings.repositories)))
                            MsgLog(['The respository ', db.sessions{i_db_subset}.repositories{1} ,' has not been defined on this computer. Please edit db_local_repositories and provide the path'],4)
                            edit db_local_repositories.m.m
                            return
                        end
                        if strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_Datasets')
                            Investigator_name = strsplit(db.sessions{i_db_subset}.investigator,' ');
                            path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                            db_basepath{i_db} = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), path_Investigator,db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                        else
                            db_basepath{i_db} = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                        end
                        
                        if ~isempty(db.sessions{i_db_subset}.spikeSorting.relativePath)
                            db_clusteringpath{i_db} = fullfile(db_basepath{i_db}, db.sessions{i_db_subset}.spikeSorting.relativePath{1});
                        else
                            db_clusteringpath{i_db} = db_basepath{i_db};
                        end
                        
                    end
                    
                    ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading batch');
                    cell_metrics1 = LoadCellMetricsBatch('clusteringpaths', db_clusteringpath,'basenames',db_basename(indx),'basepaths',db_basepath,'waitbar_handle',ce_waitbar);
                    if ~isempty(cell_metrics1)
                        cell_metrics = cell_metrics1;
                    else
                        return
                    end
                    % cell_metrics = LoadCellMetricsBatch('sessionIDs', str2double(db_menu_ids(indx)));
                    SWR_in = {};
                    
                    statusUpdate('Initializing session(s)')
                    initializeSession
                    if ishandle(ce_waitbar)
                        close(ce_waitbar)
                    end
                    try
                        if isfield(UI,'panel')
                            MsgLog([num2str(length(indx)),' session(s) loaded succesfully'],2);
                        else
                            disp([num2str(length(indx)),' session(s) loaded succesfully']);
                        end
                        
                    catch
                        if isfield(UI,'panel')
                            MsgLog(['Failed to load dataset from database: ',strjoin(db.menu_items(indx))],4);
                        else
                            disp(['Failed to load dataset from database: ',strjoin(db.menu_items(indx))]);
                        end
                    end
                    
                end
            end
            
            if ishandle(UI.fig)
                uiresume(UI.fig);
            end
        end
        
        function  CancelDB_dialog
            % Closes the dialog
            delete(loadDB.dialog);
        end
    end

    function LoadDB_sessionlist
        if exist('db_load_settings','file')
            db_settings = db_load_settings;
            db = {};
            if ~strcmp(db_settings.credentials.username,'user')
                waitbar_message = 'Downloading session list. Hold on for a few seconds...';
                % DB settings for authorized users
                options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50,'CertificateFilename',''); % ,'ArrayFormat','json','ContentType','json'
                db_settings.address_full = [db_settings.address,'views/15356/'];
            else
                waitbar_message = 'Downloading public session list. Hold on for a few seconds...';
                % DB settings for public access
                options = weboptions('RequestMethod','get','Timeout',50,'CertificateFilename','');
                db_settings.address_full = [db_settings.address,'views/16777/'];
                MsgLog(['Loading public list. Please provide your database credentials in ''db\_credentials.m'' ']);
            end
            
            % Show waitbar while loading DB
            if isfield(UI,'panel')
                ce_waitbar = waitbar(0,waitbar_message,'name','Loading metadata from DB','WindowStyle', 'modal');
            else
                ce_waitbar = [];
            end
            
            % Requesting db list
            bz_db = webread(db_settings.address_full,options,'page_size','5000','sorted','1','cellmetrics',1);
            if ~isempty(bz_db.renderedHtml)
                db.sessions = loadjson(bz_db.renderedHtml);
                db.refreshTime = datetime('now','Format','HH:mm:ss, d MMMM, yyyy');
                
                % Generating list of sessions
                [db.menu_items,db.index] = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
                db.menu_ids = cellfun(@(x) x.id,db.sessions,'UniformOutput',false);
                db.menu_ids = db.menu_ids(db.index);
                db.menu_animals = cellfun(@(x) x.animal,db.sessions,'UniformOutput',false);
                db.menu_species = cellfun(@(x) x.species,db.sessions,'UniformOutput',false);
                for i = 1:size(db.sessions,2)
                    if ~isempty(db.sessions{i}.behavioralParadigm)
                        db.menu_behavioralParadigm{i} = strjoin(db.sessions{i}.behavioralParadigm,', ');
                    else
                        db.menu_behavioralParadigm{i} = '';
                    end
                    if ~isempty(db.sessions{i}.brainRegion)
                        db.menu_brainRegion{i} = strjoin(db.sessions{i}.brainRegion,', ');
                    else
                        db.menu_brainRegion{i} = '';
                    end
                end
                db.menu_investigator = cellfun(@(x) x.investigator,db.sessions,'UniformOutput',false);
                db.menu_repository = cellfun(@(x) x.repositories{1},db.sessions,'UniformOutput',false);
                db.menu_cells = cellfun(@(x) num2str(x.spikeSorting.cellCount),db.sessions,'UniformOutput',false);
                
                db.menu_values = cellfun(@(x) x.id,db.sessions,'UniformOutput',false);
                db.menu_values = db.menu_values(db.index);
                db.menu_items2 = strcat(db.menu_items);
                sessionEnumerator = cellstr(num2str([1:length(db.menu_items2)]'))';
                db.sessionList = strcat(sessionEnumerator,{' '},db.menu_items2,{' '},db.menu_cells(db.index),{' '},db.menu_animals(db.index),{' '},db.menu_behavioralParadigm(db.index),{' '},db.menu_species(db.index),{' '},db.menu_investigator(db.index),{' '},db.menu_repository(db.index),{' '},db.menu_brainRegion(db.index));
                
                % Promt user with a tabel with sessions
                if ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
                db.dataTable = {};
                db.dataTable(:,2:10) = [sessionEnumerator;db.menu_items2;db.menu_cells(db.index);db.menu_animals(db.index);db.menu_species(db.index);db.menu_behavioralParadigm(db.index);db.menu_investigator(db.index);db.menu_repository(db.index);db.menu_brainRegion(db.index)]';
                db.dataTable(:,1) = {false};
                [db_path,~,~] = fileparts(which('db_load_sessions.m'));
                try
                    save(fullfile(db_path,'db_cell_metrics_session_list.mat'),'db','-v7.3','-nocompression');
                catch
                    warning('failed to save session list with metrics');
                end
            else
                MsgLog('Failed to load sessions from database',4);
            end
        else
            MsgLog('Database tools not installed');
            msgbox({'Database tools not installed. To install, follow the steps below: ','1. Go to the CellExplorer GitHub webpage','2. Download the database tools', '3. Add the db directory to your Matlab path', '4. Optionally provide your credentials in db\_credentials.m and try again.'},createStruct);
        end
    end

    function editDBcredentials(~,~)
        edit db_credentials.m
    end

    function editDBrepositories(~,~)
        edit db_local_repositories.m
    end

    function successMessage = LoadSession
        % Loads cell_metrics from a single session and initializes it.
        % Returns sucess/error message
        successMessage = '';
        messagePriority = 1;
        if exist(basepath,'dir')
            if exist(fullfile(clusteringpath,[basename, '.cell_metrics.cellinfo.mat']),'file')
                cd(basepath);
                load(fullfile(clusteringpath,[basename, '.cell_metrics.cellinfo.mat']));
                cell_metrics.general.path = clusteringpath;
                initializeSession;
                
                successMessage = [basename ' with ' num2str(cell_metrics.general.cellCount)  ' cells loaded from database'];
                messagePriority = 2;
            else
                successMessage = ['Error: ', basename, ' has no cell metrics'];
                messagePriority = 3;
            end
        else
            successMessage = ['Error: ',basename ' path not available'];
            messagePriority = 3;
        end
        
        if isfield(UI,'panel')
            MsgLog(successMessage,messagePriority);
        else
            disp(successMessage);
        end
    end

    function AdjustGUIbutton
        % Shuffles through the layout options and calls AdjustGUI
        UI.settings.layout = UI.popupmenu.plotCount.Value;
        AdjustGUI
    end
    
    function AdjustGUIkey
        UI.settings.layout = rem(UI.settings.layout,7)+1;
        AdjustGUI
    end

    function out = CheckSpikes(batchIDsIn)
        % Checks if spikes data is available for the selected session (batchIDs)
        % If it is, the file is loaded into memory (spikes structure)
        if length(batchIDsIn)>1
            ce_waitbar = waitbar(0,'Loading spike data','Name',['Loading spikes from ', num2str(length(batchIDsIn)),' sessions'],'WindowStyle','modal');
        end
        for i_batch = 1:length(batchIDsIn)
            batchIDsPrivate = batchIDsIn(i_batch);
            
            if isempty(spikes) || length(spikes) < batchIDsPrivate || isempty(spikes{batchIDsPrivate})
                if UI.BatchMode
                    clusteringpath1 = cell_metrics.general.path{batchIDsPrivate};
                    basename1 = cell_metrics.general.basenames{batchIDsPrivate};
                else
                    clusteringpath1 = cell_metrics.general.clusteringpath;
                    basename1 = cell_metrics.general.basename;
                end
                
                if exist(fullfile(clusteringpath1,[basename1,'.spikes.cellinfo.mat']),'file')
                    if length(batchIDsIn)==1
                        ce_waitbar = waitbar(0,'Loading spike data','Name','Loading spikes data','WindowStyle','modal');
                    end
                    if ~ishandle(ce_waitbar)
                        MsgLog(['Spike loading canceled by the user'],2);
                        return
                    end
                    ce_waitbar = waitbar((batchIDsPrivate-1)/length(batchIDsIn),ce_waitbar,[num2str(batchIDsPrivate) '. Loading ', basename1]);
                    temp = load(fullfile(clusteringpath1,[basename1,'.spikes.cellinfo.mat']));
                    spikes{batchIDsPrivate} = temp.spikes;
                    out = true;
                    MsgLog(['Spikes loaded succesfully for ' basename1]);
                    if ishandle(ce_waitbar) && length(batchIDsIn) == 1
                        close(ce_waitbar)
                    end
                else
                    out = false;
                end
            else
                out = true;
            end
        end
        if i_batch == length(batchIDsIn) && length(batchIDsIn) > 1 && ishandle(ce_waitbar)
            close(ce_waitbar)
            if length(batchIDsIn)>1
                MsgLog(['Spike data loading complete'],2);
            end
        end
    end

    function out = CheckEvents(batchIDs,eventName,eventType)
        % Checks if the event type is available for the selected session (batchIDs)
        % If it is the file is loaded into memory (events structure)
        if isempty(events) || ~isfield(events,eventName) || length(events.(eventName)) < batchIDs || isempty(events.(eventName){batchIDs})
            if UI.BatchMode
                basepath1 = cell_metrics.general.basepaths{batchIDs};
                basename1 = cell_metrics.general.basenames{batchIDs};
            else
                basepath1 = basepath;
                basename1 = cell_metrics.general.basename;
            end
            eventfile = fullfile(basepath1,[basename1,'.' (eventName) '.',eventType,'.mat']);
            if exist(eventfile,'file')
                temp = load(eventfile);
                if isfield(temp.(eventName),'timestamps')
                    events.(eventName){batchIDs} = temp.(eventName);
                    if isfield(temp.(eventName),'peakNormedPower') && ~isfield(temp.(eventName),'amplitude')
                        events.(eventName){batchIDs}.amplitude = temp.(eventName).peakNormedPower;
                    end
                    if isfield(temp.(eventName),'timestamps') && ~isfield(temp.(eventName),'duration')
                        events.(eventName){batchIDs}.duration = diff(temp.(eventName).timestamps')';
                    end
                    out = true;
                    MsgLog([eventName ' events loaded succesfully for ' basename1]);
                else
                    out = false;
                    MsgLog([eventName ' events loading failed due to missing fieldname timestamps for ' basename1]);
                end
                if exist('ce_waitbar') && ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
            else
                out = false;
            end
        else
            out = true;
        end
    end
    
    function out = CheckStates(batchIDs,stateName)
        % Checks if the states type is available for the selected session (batchIDs)
        % If it is the file is loaded into memory (states structure)
        if isempty(states) || ~isfield(states,stateName) || length(states.(stateName)) < batchIDs || isempty(states.(stateName){batchIDs})
            if UI.BatchMode
                basepath1 = cell_metrics.general.basepaths{batchIDs};
                basename1 = cell_metrics.general.basenames{batchIDs};
            else
                basepath1 = basepath;
                basename1 = cell_metrics.general.basename;
            end
            statesfile = fullfile(basepath1,[basename1,'.' (stateName) '.states.mat']);
            if exist(statesfile,'file')
                temp = load(statesfile);
                if isfield(temp.(stateName),'ints')
                    states.(stateName){batchIDs} = temp.(stateName);
                    out = true;
                    MsgLog([stateName ' states loaded succesfully for ' basename1]);
                else
                    out = false;
                    MsgLog([stateName ' states loading failed due to missing ints timestamps for ' basename1]);
                end
                if exist('ce_waitbar') && ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
            else
                out = false;
            end
        else
            out = true;
        end
    end
    
    function defineSpikesPlots(~,~)
        % check for local spikes structure before the spikePlotListDlg dialog is called
        out = CheckSpikes(batchIDs);
        if out
            spikePlotListDlg;
        else
            MsgLog(['No spike data found or the spike data is not accessible: ',general.basename],2)
        end
    end

    function spikePlotListDlg
        % Displays a dialog with the spike plots as defined in the
        % spikesPlots structure
        spikePlotList_dialog = dialog('Position', [300, 300, 750, 400],'Name','Spike plot types','WindowStyle','modal','visible','off'); movegui(spikePlotList_dialog,'center'), set(spikePlotList_dialog,'visible','on')
        
        tableData = updateTableData(spikesPlots);
        spikePlot = uitable(spikePlotList_dialog,'Data',tableData,'Position',[10, 50, 730, 340],'ColumnWidth',{20 125 90 90 90 90 70 70 80},'columnname',{'','Plot name','X data','Y data','X label','Y label','State','Events','Event data'},'RowName',[],'ColumnEditable',[true false false false false false false false false]);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add plot','Callback',@(src,evnt)addPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[100, 10, 90, 30],'String','Edit plot','Callback',@(src,evnt)editPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[190, 10, 90, 30],'String','Delete plot','Callback',@(src,evnt)DeletePlot);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[280, 10, 90, 30],'String','Reset spike data','Callback',@(src,evnt)ResetSpikeData);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[370, 10, 100, 30],'String','Load all spike data','Callback',@(src,evnt)LoadAllSpikeData);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[470, 10, 90, 30],'String','Predefine','Callback',@(src,evnt)viewPredefinedCustomSpikesPlots);
        OK_button = uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[560, 10, 90, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlotList_dialog);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[650, 10, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikePlotList_dialog);
        
        uicontrol(OK_button)
        uiwait(spikePlotList_dialog);
        function viewPredefinedCustomSpikesPlots
            temp = what('customSpikesPlots');
            if ispc
                winopen(temp.path);
            elseif ismac
                syscmd = ['open "', temp.path, '" &'];
                system(syscmd);
            else
                filebrowser;
            end
        end
        function  ResetSpikeData
            % Resets spikes and event data and closes the dialog
            spikes = [];
            events = [];
            states = [];
            delete(spikePlotList_dialog);
            MsgLog('Spike and event data have been reset',2)
        end
        
        function LoadAllSpikeData
            % Loads all spikes data
            if UI.BatchMode
                out = CheckSpikes([1:length(cell_metrics.general.batch)]);
            else
                out = CheckSpikes(1);
                MsgLog('Spike data loaded',2);
            end
        end
        
        function tableData = updateTableData(spikesPlots)
            % Updates the plot table from the spikesPlots structure
            spikesPlotFieldnames = fieldnames(spikesPlots);
            tableData = cell(length(spikesPlotFieldnames),8);
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
            % Closes the dialog and resets the plot options
            plotOptions(contains(plotOptions,'spikes_')) = [];
            plotOptions = [plotOptions;fieldnames(spikesPlots)];
            plotOptions = unique(plotOptions,'stable');
            for i = 1:6
                UI.popupmenu.customplot{i}.String = plotOptions; if UI.popupmenu.customplot{i}.Value>length(plotOptions), UI.popupmenu.customplot{i}.Value=1; end
            end
            MsgLog('Spike plots defined')
            delete(spikePlotList_dialog);
        end
        
        function  CancelSpikePlotList_dialog
            % Closes the dialog
            delete(spikePlotList_dialog);
        end
        
        function DeletePlot
            % Deletes any selected spike plots
            if ~isempty(find([spikePlot.Data{:,1}]))
                spikesPlotFieldnames = fieldnames(spikesPlots);
                spikesPlots = rmfield(spikesPlots,{spikesPlotFieldnames{find([spikePlot.Data{:,1}])}});
                tableData = updateTableData(spikesPlots);
                spikePlot.Data = tableData;
            end
        end
        
        function addPlotToTable
            % Calls spikePlotsDlg and saved the generated plot in the spikesPlots structure and
            % updates the table
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
            % Selected plot is parsed to the spikePlotsDlg, for edits,
            % saved the output to the spikesPlots structure and updates the
            % table
            if ~isempty(find([spikePlot.Data{:,1}])) && sum([spikePlot.Data{:,1}]) == 1
                spikesPlotFieldnames = fieldnames(spikesPlots);
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

    function spikesPlotsOut = spikePlotsDlg(fieldtoedit)
        % Displayes a dialog window for defining a new spike plot.
        
        spikesPlotsOut = '';
        spikePlots_dialog = dialog('Position', [300, 300, 670, 450],'Name','Plot type','WindowStyle','modal','visible','off'); movegui(spikePlots_dialog,'center'), set(spikePlots_dialog,'visible','on')
        
        % Generates a list of fieldnames that exist in either of the
        % spikes-structures in memory and sorts them  alphabetically and adds any preselected field names
        spikesField = cellfun(@fieldnames,{spikes{find(~cellfun(@isempty,spikes))}},'UniformOutput',false);
        spikesField = sort(unique(vertcat(spikesField{:})));
        
        spikes_fieldnames = fieldnames(spikesPlots);
        data_types = {'x','y','state','filter'};
        for i_types = 1:length(data_types)
            fields_new = cellfun(@(x1) spikesPlots.(x1).(data_types{i_types}),spikes_fieldnames,'UniformOutput',false);
            spikesField = [spikesField;fields_new(~cellfun('isempty',fields_new))];
        end
        spikesField = unique(spikesField);
        
        % Defines the uicontrols
        % Plot name
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Plot name', 'Position', [10, 421, 650, 20],'HorizontalAlignment','left');
        spikePlotName = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 405, 650, 20],'HorizontalAlignment','left');
        % X data
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'X data', 'Position', [10, 371, 210, 20],'HorizontalAlignment','left');
        spikePlotXData = uicontrol('Parent',spikePlots_dialog,'Style', 'ListBox', 'String', spikesField, 'Position', [10, 240, 210, 135],'HorizontalAlignment','left');
        % X label
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'X label', 'Position', [10, 216, 210, 20],'HorizontalAlignment','left');
        spikePlotXLabel = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 200, 210, 20],'HorizontalAlignment','left');
        % Y data
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Y data', 'Position', [230, 371, 210, 20],'HorizontalAlignment','left');
        spikePlotYData = uicontrol('Parent',spikePlots_dialog,'Style', 'ListBox', 'String', spikesField, 'Position', [230, 240, 210, 135],'HorizontalAlignment','left');
        % Y label
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Y label', 'Position', [230, 216, 210, 20],'HorizontalAlignment','left');
        spikePlotYLabel = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [230, 200, 210, 20],'HorizontalAlignment','left');
        % State
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'State', 'Position', [450, 371, 210, 20],'HorizontalAlignment','left');
        spikePlotState = uicontrol('Parent',spikePlots_dialog,'Style', 'ListBox', 'String', ['Select field';spikesField], 'Position', [450, 240, 210, 135],'HorizontalAlignment','left');
        
        % Filter/Threshold
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Filter', 'Position', [10, 169, 210, 20],'HorizontalAlignment','left');
        spikePlotFilterData = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', ['none';spikesField], 'Value',1,'Position', [10, 155, 210, 20],'HorizontalAlignment','left','Callback',@(src,evnt)toggleFilterFields);
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Type', 'Position', [230, 169, 210, 20],'HorizontalAlignment','left');
        spikePlotFilterType = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', {'none','equal to','less than','greater than'}, 'Value',1,'Position', [230, 155, 130, 20],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Value', 'Position', [370, 169, 70, 20],'HorizontalAlignment','left');
        spikePlotFilterValue = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [370, 155, 70, 20],'HorizontalAlignment','left');
        
        % Event data
        uicontrol('Parent', spikePlots_dialog, 'Style', 'text', 'String', 'Event type', 'Position', [10, 121, 210, 20],'HorizontalAlignment','left');
        spikePlotEventType = uicontrol('Parent', spikePlots_dialog, 'Style', 'popupmenu', 'String', {'none','events', 'manipulation','states'}, 'Value',1,'Position', [10, 105, 210, 20],'HorizontalAlignment','left','Callback',@(src,evnt)toggleEventFields);
        uicontrol('Parent', spikePlots_dialog, 'Style', 'text', 'String', 'Event name', 'Position', [230, 121, 210, 20],'HorizontalAlignment','left');
        spikePlotEvent = uicontrol('Parent', spikePlots_dialog, 'Style', 'Edit', 'String', '', 'Position', [230, 105, 210, 20],'HorizontalAlignment','left');
        uicontrol('Parent', spikePlots_dialog,'Style', 'text', 'String', 'sec before', 'Position', [450, 121, 100, 20],'HorizontalAlignment','left');
        spikePlotEventSecBefore = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [450, 105, 100, 20],'HorizontalAlignment','left');
        uicontrol('Parent', spikePlots_dialog,'Style', 'text', 'String', 'sec after', 'Position', [560, 121, 100, 20],'HorizontalAlignment','left');
        spikePlotEventSecAfter = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [560, 105, 100, 20],'HorizontalAlignment','left');
        uicontrol('Parent', spikePlots_dialog,'Style', 'text', 'String', 'Event alignment', 'Position', [10, 71, 210, 20],'HorizontalAlignment','left');
        spikePlotEventAlignment = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', {'onset', 'offset', 'center', 'peak'}, 'Value',1,'Position', [10, 55, 210, 20],'HorizontalAlignment','center');
        uicontrol('Parent', spikePlots_dialog, 'Style', 'text', 'String', 'Event sorting', 'Position', [230, 71, 210, 20],'HorizontalAlignment','left');
        spikePlotEventSorting = uicontrol('Parent', spikePlots_dialog, 'Style', 'popupmenu', 'String', {'none','time', 'amplitude', 'duration','eventID'}, 'Value',1,'Position', [230, 55, 210, 20],'HorizontalAlignment','center');
        
        % Check boxes
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Event plots', 'Position', [450, 71, 120, 20],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Event trialwise curves', 'Position', [550, 71, 120, 20],'HorizontalAlignment','left');
        spikePlotEventPlotRaster = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 55 70 20],'Units','normalized','String','Raster','HorizontalAlignment','left');
        spikePlotEventPlotAverage = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 35 90 20],'Units','normalized','String','Average PSTH','HorizontalAlignment','left');
        spikePlotEventPlotAmplitude = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[550 15 70 20],'Units','normalized','String','Amplitude','HorizontalAlignment','left');
        spikePlotEventPlotDuration = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[550 55 70 20],'Units','normalized','String','Duration','HorizontalAlignment','left');
        spikePlotEventPlotCount = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[550 35 70 20],'Units','normalized','String','Count','HorizontalAlignment','left');
        
        uicontrol('Parent',spikePlots_dialog,'Style','pushbutton','Position',[10, 10, 210, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlots_dialog);
        uicontrol('Parent',spikePlots_dialog,'Style','pushbutton','Position',[230, 10, 210, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikePlots_dialog);
        
        if ~isempty(fieldtoedit)
            spikePlotName.String = fieldtoedit(8:end);
            spikePlotXLabel.String = spikesPlots.(fieldtoedit).x_label;
            spikePlotYLabel.String = spikesPlots.(fieldtoedit).y_label;
            spikePlotEvent.String = spikesPlots.(fieldtoedit).event;
            spikePlotEventSecBefore.String = spikesPlots.(fieldtoedit).eventSecBefore;
            spikePlotEventSecAfter.String = spikesPlots.(fieldtoedit).eventSecAfter;
            if isfield(spikesPlots.(fieldtoedit),'plotRaster')
                spikePlotEventPlotRaster.Value = spikesPlots.(fieldtoedit).plotRaster;
            end
            if isfield(spikesPlots.(fieldtoedit),'plotAverage')
                spikePlotEventPlotAverage.Value = spikesPlots.(fieldtoedit).plotAverage;
            end
            if isfield(spikesPlots.(fieldtoedit),'plotAmplitude')
                spikePlotEventPlotAmplitude.Value = spikesPlots.(fieldtoedit).plotAmplitude;
            end
            if isfield(spikesPlots.(fieldtoedit),'plotDuration')
                spikePlotEventPlotDuration.Value = spikesPlots.(fieldtoedit).plotDuration;
            end
            if isfield(spikesPlots.(fieldtoedit),'plotCount')
                spikePlotEventPlotCount.Value = spikesPlots.(fieldtoedit).plotCount;
            end
            
            if find(strcmp(spikesPlots.(fieldtoedit).x,spikePlotXData.String))
                spikePlotXData.Value = find(strcmp(spikesPlots.(fieldtoedit).x,spikePlotXData.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).y,spikePlotYData.String))
                spikePlotYData.Value = find(strcmp(spikesPlots.(fieldtoedit).y,spikePlotYData.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).state,spikePlotState.String))
                spikePlotState.Value = find(strcmp(spikesPlots.(fieldtoedit).state,spikePlotState.String));
            end
            
            % Filter
            if find(strcmp(spikesPlots.(fieldtoedit).filter,spikePlotFilterData.String))
                spikePlotFilterData.Value = find(strcmp(spikesPlots.(fieldtoedit).filter,spikePlotFilterData.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).filterType,spikePlotFilterType.String))
                spikePlotFilterType.Value = find(strcmp(spikesPlots.(fieldtoedit).filterType,spikePlotFilterType.String));
            end
            spikePlotFilterValue.String = spikesPlots.(fieldtoedit).filterValue;
            
            
            % Event
            if find(strcmp(spikesPlots.(fieldtoedit).event,spikePlotEvent.String))
                spikePlotEvent.Value = find(strcmp(spikesPlots.(fieldtoedit).event,spikePlotEvent.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).eventType,spikePlotEventType.String))
                spikePlotEventType.Value = find(strcmp(spikesPlots.(fieldtoedit).eventType,spikePlotEventType.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).eventAlignment,spikePlotEventAlignment.String))
                spikePlotEventAlignment.Value = find(strcmp(spikesPlots.(fieldtoedit).eventAlignment,spikePlotEventAlignment.String));
            end
            if find(strcmp(spikesPlots.(fieldtoedit).eventSorting,spikePlotEventSorting.String))
                spikePlotEventSorting.Value = find(strcmp(spikesPlots.(fieldtoedit).eventSorting,spikePlotEventSorting.String));
            end
        end
        toggleEventFields
        toggleFilterFields

        
        uicontrol(spikePlotName);
        uiwait(spikePlots_dialog);
        
        function toggleFilterFields
            if spikePlotFilterData.Value == 1
                spikePlotFilterType.Enable = 'off';
                spikePlotFilterValue.Enable = 'off';
            else
                spikePlotFilterType.Enable = 'on';
                spikePlotFilterValue.Enable = 'on';
            end
        end
        function toggleEventFields
            if spikePlotEventType.Value == 1
                spikePlotEvent.Enable = 'off';
                spikePlotEventAlignment.Enable = 'off';
                spikePlotEventSorting.Enable = 'off';
                spikePlotEventPlotRaster.Enable = 'off';
                spikePlotEventPlotAverage.Enable = 'off';
                spikePlotEventPlotAmplitude.Enable = 'off';
                spikePlotEventPlotDuration.Enable = 'off';
                spikePlotEventPlotCount.Enable = 'off';
                spikePlotEventSecBefore.Enable = 'off';
                spikePlotEventSecAfter.Enable = 'off';
            else
                spikePlotEvent.Enable = 'on';
                spikePlotEventAlignment.Enable = 'on';
                spikePlotEventSorting.Enable = 'on';
                spikePlotEventPlotRaster.Enable = 'on';
                spikePlotEventPlotAverage.Enable = 'on';
                spikePlotEventPlotAmplitude.Enable = 'on';
                spikePlotEventPlotDuration.Enable = 'on';
                spikePlotEventPlotCount.Enable = 'on';
                spikePlotEventSecBefore.Enable = 'on';
                spikePlotEventSecAfter.Enable = 'on';
            end
        end
        
        function CloseSpikePlots_dialog
            % Checks the inputs for correct format then closes the dialog and parses the inputs to spikesPlotsOut structure
            if ~myFieldCheck(spikePlotName,'varname') || ...
                    ( ~isempty(spikePlotEvent.String) && ~myFieldCheck(spikePlotEvent,'varname')) || ...
                    ( ~isempty(spikePlotEvent.String) && ~myFieldCheck(spikePlotEventSecBefore,'numeric')) || ...
                    ( ~isempty(spikePlotEvent.String) && ~myFieldCheck(spikePlotEventSecAfter,'numeric'))
            else
                spikePlotName2 = ['spikes_',regexprep(spikePlotName.String,{'/.*',' ','-'},'')];
                spikesPlotsOut.(spikePlotName2).x = spikesField{spikePlotXData.Value};
                spikesPlotsOut.(spikePlotName2).y = spikesField{spikePlotYData.Value};
                spikesPlotsOut.(spikePlotName2).x_label = spikePlotXLabel.String;
                spikesPlotsOut.(spikePlotName2).y_label = spikePlotYLabel.String;
                spikesPlotsOut.(spikePlotName2).event = spikePlotEvent.String;
                % State data
                if spikePlotState.Value > 1
                    spikesPlotsOut.(spikePlotName2).state = spikesField{spikePlotState.Value-1};
                else
                    spikesPlotsOut.(spikePlotName2).state = '';
                end
                % Filter data
                if spikePlotFilterData.Value > 1
                    spikesPlotsOut.(spikePlotName2).filter = spikesField{spikePlotFilterData.Value-1};
                else
                    spikesPlotsOut.(spikePlotName2).filter = '';
                end
                spikesPlotsOut.(spikePlotName2).filterType = spikePlotFilterType.String{spikePlotFilterType.Value};
                spikesPlotsOut.(spikePlotName2).filterValue = str2double(spikePlotFilterValue.String);
                % Event data
                spikesPlotsOut.(spikePlotName2).eventSecBefore = str2double(spikePlotEventSecBefore.String);
                spikesPlotsOut.(spikePlotName2).eventSecAfter = str2double(spikePlotEventSecAfter.String);
                spikesPlotsOut.(spikePlotName2).plotRaster = spikePlotEventPlotRaster.Value;
                spikesPlotsOut.(spikePlotName2).plotAverage = spikePlotEventPlotAverage.Value;
                spikesPlotsOut.(spikePlotName2).plotAmplitude = spikePlotEventPlotAmplitude.Value;
                spikesPlotsOut.(spikePlotName2).plotDuration = spikePlotEventPlotDuration.Value;
                spikesPlotsOut.(spikePlotName2).plotCount = spikePlotEventPlotCount.Value;
                spikesPlotsOut.(spikePlotName2).eventAlignment = spikePlotEventAlignment.String{spikePlotEventAlignment.Value};
                spikesPlotsOut.(spikePlotName2).eventSorting = spikePlotEventSorting.String{spikePlotEventSorting.Value};
                spikesPlotsOut.(spikePlotName2).eventType = spikePlotEventType.String{spikePlotEventType.Value};
                
                delete(spikePlots_dialog);
            end
            
            function out = myFieldCheck(fieldString,type)
                % Checks the input field for specific type, i.e. numeric,
                % alphanumeric, required or varname. If the requirement is
                % not fulfilled focus is set to the selected field.
                out = 1;
                switch type
                    case 'numeric'
                        if isempty(fieldString.String) || ~all(ismember(fieldString.String, '.1234567890'))
                            uiwait(warndlg('Field must be numeric'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'alphanumeric'
                        if isempty(fieldString.String) || ~regexp(fieldString.String, '^[A-Za-z0-9_]+$') || ~regexp(fieldString.String(1), '^[A-Z]+$')
                            uiwait(warndlg('Field must be alpha numeric'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'required'
                        if isempty(fieldString.String)
                            uiwait(warndlg('Required field missing'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'varname'
                        if ~isvarname(fieldString.String)
                            uiwait(warndlg('Field must be a valid variable name'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                end
            end
        end
        
        function  CancelSpikePlots_dialog
            % Closes the dialog without returning the field inputs
            spikesPlotsOut = '';
            delete(spikePlots_dialog);
        end
    end

    function editSelectedSpikePlot(~,~)
        axnum = getAxisBelowCursor;
        if isfield(UI,'panel') && ~isempty(axnum)
            handle34 = subfig_ax(axnum);
            um_axes = get(handle34,'CurrentPoint');
            
            if axnum>3 && strcmp(UI.settings.customPlot{axnum-3}(1:7),'spikes_')
                spikesPlotsOut = spikePlotsDlg(UI.settings.customPlot{axnum-3});
                if ~isempty(spikesPlotsOut)
                    for fn = fieldnames(spikesPlotsOut)'
                        spikesPlots.(fn{1}) = spikesPlotsOut.(fn{1});
                    end
                    uiresume(UI.fig);
                end
            else
                MsgLog('Hover over a spike plot and press the shortcut to edit the plot parameters',2);
            end
        end
    end

    function loadGroundTruth(~,~)
        groupData.groupToList = 'groundTruthClassification';
        performGroundTruthClassification
        defineGroupData
    end

    function compareToReference(src,~)
        if isfield(src,'Text') && strcmp(src.Text,'Compare cell groups to reference data')
            inputReferenceData = 1;
            clr_groups2 = UI.settings.cellTypeColors(unique(referenceData.clusClas),:);
            listClusClas_referenceData = unique(referenceData.clusClas);
        else
            inputReferenceData = 0;
        end
        list_metrics = generateMetricsList('all');
        compareToGroundTruth.dialog = dialog('Position', [300, 300, 400, 518],'Name','Select the metrics to compare','WindowStyle','modal','visible','off'); movegui(compareToGroundTruth.dialog,'center'), set(compareToGroundTruth.dialog,'visible','on')
        compareToGroundTruth.sessionList = uicontrol('Parent',compareToGroundTruth.dialog,'Style','listbox','String',list_metrics,'Position',[10, 50, 380, 457],'Value',1,'Max',100,'Min',1);
        uicontrol('Parent',compareToGroundTruth.dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)close_dialog);
        uicontrol('Parent',compareToGroundTruth.dialog,'Style','pushbutton','Position',[200, 10, 190, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        uiwait(compareToGroundTruth.dialog)
        
        function close_dialog
            classesToPlot = unique(plotClas(UI.params.subset));
            idx = {};
            for j = 1:length(classesToPlot)
                idx{j} = intersect(find(plotClas==classesToPlot(j)),UI.params.subset);
            end
            selectedFields = list_metrics(compareToGroundTruth.sessionList.Value);
            n_selectedFields = min(length(selectedFields),4);
            k = 1;
            regularFields = find(~contains(selectedFields,'.'));
            figure
            for i = 1:length(regularFields)
                if k > 4
                    k = 1;
                    figure
                end
                subplot(2,n_selectedFields,k)
                hold on, title(selectedFields(regularFields(i)))
                for j = 1:length(classesToPlot)
                    
                    [N,edges] = histcounts(cell_metrics.(selectedFields{regularFields(i)})(idx{j}),20, 'Normalization', 'probability');
                    line(edges,[N,0],'color',clr_groups(j,:),'linewidth',2)
                end
                subplot(2,n_selectedFields,k+n_selectedFields), hold on
                if inputReferenceData == 1
                    % Reference data
                    title('Reference data')
                    for j = 1:length(listClusClas_referenceData)
                        idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                        [N,edges] = histcounts(reference_cell_metrics.(selectedFields{regularFields(i)})(idx2),20, 'Normalization', 'probability');
                        line(edges,[N,0],'color',clr_groups2(j,:),'linewidth',2)
                    end
                else
                    % Ground truth cells
                    title('Ground truth cells')
                    if ~isempty(subsetGroundTruth)
                        idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                        for jj = 1:length(idGroundTruth)
                            [N,edges] = histcounts(cell_metrics.(selectedFields{regularFields(i)})(subsetGroundTruth{idGroundTruth(jj)}),20, 'Normalization', 'probability');
                            line(edges,[N,0],'color',clr_groups(j,:),'linewidth',2)
                        end
                    end
                end
                k = k + 1;
            end
            
            structFields = find(contains(selectedFields,'.'));
            if ~isempty(structFields)
                for i = 1:length(structFields)
                    if k > 4
                        k = 1;
                        figure
                    end
                    newStr = split(selectedFields{structFields(i)},'.');
                    subplot(2,n_selectedFields,k)
                    hold on, title(selectedFields(structFields(i)))
                    for j = 1:length(classesToPlot)
                        temp1 = mean(cell_metrics.(newStr{1}).(newStr{2})(:,idx{j}),2);
                        temp2 = std(cell_metrics.(newStr{1}).(newStr{2})(:,idx{j}),0,2);
                        patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr_groups(j,:),'EdgeColor','none','FaceAlpha',.2)
                        line(1:length(temp1), temp1, 'color', clr_groups(j,:),'linewidth',2)
                    end
                    subplot(2,n_selectedFields,k+n_selectedFields),hold on
                    if inputReferenceData == 1
                        % Reference data
                        title('Reference data')
                        for j = 1:length(listClusClas_referenceData)
                            idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                            temp1 = mean(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2),2);
                            temp2 = std(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2),0,2);
                            patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr_groups2(j,:),'EdgeColor','none','FaceAlpha',.2)
                            line(1:length(temp1), temp1, 'color', clr_groups(j,:),'linewidth',2)
                        end
                    else g
                        % Ground truth cells
                        title('Ground truth cells')
                        if ~isempty(subsetGroundTruth)
                            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                            for jj = 1:length(idGroundTruth)
                                temp1 = mean(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)}),2);
                                temp2 = std(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)}),0,2);
                                patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr_groups(j,:),'EdgeColor','none','FaceAlpha',.2)
                                line(1:length(temp1), temp1, 'color', clr_groups(j,:),'linewidth',2)
                            end
                        end
                    end
                    k = k + 1;
                end
            end
            delete(compareToGroundTruth.dialog);
        end
        
        function cancel_dialog
            % Closes the dialog
            delete(compareToGroundTruth.dialog);
        end
    end

    function data = normalize_range(data)
        % Normalizes a input matrix or vector to the interval [0,1]
        data = data./range(data);
    end

    function adjustMonoSyn_UpdateMetrics(~,~)
        % Manually select connections
        if UI.BatchMode
            basename1 = cell_metrics.general.basenames{batchIDs};
            path1 = cell_metrics.general.path{batchIDs};
        else
            if isfield( cell_metrics.general,'path')
                basename1 = cell_metrics.general.basename;
                path1 = cell_metrics.general.path;
            else
                basename1 = cell_metrics.general.basename;
                path1 = fullfile(cell_metrics.general.basepath,cell_metrics.general.clusteringpath);
            end
        end
        
        MonoSynFile = fullfile(path1,[basename1,'.mono_res.cellinfo.mat']);
        if exist(MonoSynFile,'file')
            ce_waitbar = waitbar(0,'Loading MonoSyn file','name','CellExplorer');
            load(MonoSynFile,'mono_res');
            if ishandle(ce_waitbar)
                waitbar(1,ce_waitbar,'Complete');
                close(ce_waitbar)
            end
            mono_res = gui_MonoSyn(mono_res,cell_metrics.UID(ii));
            % Saves output to the cell_metrics from the select session
            answer = questdlg('Do you want to save the manual monosynaptic curration?', 'Save monosynaptic curration', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                ce_waitbar = waitbar(0,' ','name','CellExplorer: Updating MonoSyn');
                if isfield(general,'saveAs')
                    saveAs = general.saveAs;
                else
                    saveAs = 'cell_metrics';
                end
                try
                    % Saving MonoSynFile fule
                    if ishandle(ce_waitbar)
                        waitbar(0.05,ce_waitbar,'Saving MonoSyn file');
                    end
                    save(MonoSynFile,'mono_res','-v7.3','-nocompression');
                    
                    % Creating backup of existing metrics
                    if ishandle(ce_waitbar)
                        waitbar(0.4,ce_waitbar,'Creating backup of existing metrics');
                    end
                    dirname = 'revisions_cell_metrics';
                    if ~(exist(fullfile(path1,dirname),'dir'))
                        mkdir(fullfile(path1,dirname));
                    end
                    if exist(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']),'file')
                        copyfile(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), fullfile(path1, dirname, [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']));
                    end
                    
                    % Saving new metrics
                    if ishandle(ce_waitbar)
                        waitbar(0.7,ce_waitbar,'Saving cells to cell_metrics file');
                    end
                    cell_session = load(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']));
                    cell_session.cell_metrics.putativeConnections.excitatory = mono_res.sig_con_excitatory; % Vectors with cell pairs
                    cell_session.cell_metrics.putativeConnections.inhibitory = mono_res.sig_con_inhibitory; % Vectors with cell pairs
                    cell_session.cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_session.cell_metrics.general.cellCount);
                    cell_session.cell_metrics.synapticEffect(cell_session.cell_metrics.putativeConnections.excitatory(:,1)) = repmat({'Excitatory'},1,size(cell_session.cell_metrics.putativeConnections.excitatory,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
                    cell_session.cell_metrics.synapticEffect(cell_session.cell_metrics.putativeConnections.inhibitory(:,1)) = repmat({'Inhibitory'},1,size(cell_session.cell_metrics.putativeConnections.inhibitory,1));
                    cell_session.cell_metrics.synapticConnectionsOut = zeros(1,cell_session.cell_metrics.general.cellCount);
                    cell_session.cell_metrics.synapticConnectionsIn = zeros(1,cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,1),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,1)));
                    cell_session.cell_metrics.synapticConnectionsOut(b) = a; cell_session.cell_metrics.synapticConnectionsOut = cell_session.cell_metrics.synapticConnectionsOut(1:cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,2),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,2)));
                    cell_session.cell_metrics.synapticConnectionsIn(b) = a; cell_session.cell_metrics.synapticConnectionsIn = cell_session.cell_metrics.synapticConnectionsIn(1:cell_session.cell_metrics.general.cellCount);
                    
                    save(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), '-struct', 'cell_session','-v7.3','-nocompression')
                    % MsgLog(['Synaptic connections adjusted for: ', basename1,'. Reload session to see the changes'],2);
                    
                    if ishandle(ce_waitbar)
                        waitbar(0.9,ce_waitbar,'Updating session');
                    end
                    if UI.BatchMode
                        idx = find(cell_metrics.batchIDs == batchIDs);
                    else
                        idx = 1:cell_metrics.general.cellCount;
                    end
                    if length(idx) == cell_session.cell_metrics.general.cellCount
                        ia = ismember(cell_metrics.putativeConnections.excitatory(:,1), idx);
                        cell_metrics.putativeConnections.excitatory(ia,:) = [];
                        cell_metrics.putativeConnections.excitatory = [cell_metrics.putativeConnections.excitatory;idx(mono_res.sig_con_excitatory)];
                        ia = ismember(cell_metrics.putativeConnections.inhibitory(:,1), idx);
                        cell_metrics.putativeConnections.inhibitory(ia,:) = [];
                        cell_metrics.putativeConnections.inhibitory = [cell_metrics.putativeConnections.inhibitory;idx(mono_res.sig_con_inhibitory)];
                        cell_metrics.synapticEffect(idx) = repmat({'Unknown'},1,cell_session.cell_metrics.general.cellCount);
                        cell_metrics.synapticEffect(idx(cell_session.cell_metrics.putativeConnections.excitatory(:,1))) = repmat({'Excitatory'},1,size(cell_session.cell_metrics.putativeConnections.excitatory,1));
                        cell_metrics.synapticEffect(idx(cell_session.cell_metrics.putativeConnections.inhibitory(:,1))) = repmat({'Inhibitory'},1,size(cell_session.cell_metrics.putativeConnections.inhibitory,1));
                        
                        cell_metrics.synapticConnectionsOut(idx) = cell_session.cell_metrics.synapticConnectionsOut;
                        cell_metrics.synapticConnectionsIn(idx) = cell_session.cell_metrics.synapticConnectionsIn;
                        
                        if isfield(cell_metrics,'synapticEffect')
                            UI.cells.excitatory = find(strcmp(cell_metrics.synapticEffect,'Excitatory'));
                            UI.cells.inhibitory = find(strcmp(cell_metrics.synapticEffect,'Inhibitory'));
                        end
                        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && ~isempty(cell_metrics.putativeConnections.excitatory)
                            UI.cells.excitatoryPostsynaptic = unique(cell_metrics.putativeConnections.excitatory(:,2));
                        else
                            UI.cells.excitatoryPostsynaptic = [];
                        end
                        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory') && ~isempty(cell_metrics.putativeConnections.inhibitory)
                            UI.cells.inhibitoryPostsynaptic = unique(cell_metrics.putativeConnections.inhibitory(:,2));
                        else
                            UI.cells.inhibitoryPostsynaptic = [];
                        end
                    else
                        MsgLog('Error updating current session. Reload session to see the changes',4);
                    end
                    
                    if ishandle(ce_waitbar)
                        waitbar(1,ce_waitbar,'Complete');
                    end
                    MsgLog(['Synaptic connections adjusted for: ', basename1]);
                    uiresume(UI.fig);
                catch
                    MsgLog('Synaptic connections adjustment failed. mono_res struct saved to workspace',4);
                    assignin('base','mono_res_failed_to_save',mono_res);
                end
                
                if ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
            else
                MsgLog('Synaptic connections not updated.');
            end
        elseif ~exist(MonoSynFile,'file')
            MsgLog(['Mono_syn file does not exist: ' MonoSynFile],4);
            return
        end
    end
    
    function performGroundTruthClassification(~,~)
        if ~isfield(UI.tabs,'groundTruthClassification')
            % UI.settings.groundTruth
            createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.settings.groundTruth,'G/T')
        end
    end
    
    function createGroundTruthClassificationToggleMenu(childName,parentPanelName,buttonLabels,panelTitle)
        % INPUTS
        % parentPanelName: UI.panel.tabgroup1
        % childName:
        % buttonLabels:    UI.settings.groundTruth
        % panelTitle:      'G/T'
        
        UI.tabs.(childName) =uitab(parentPanelName,'Title',panelTitle);
        buttonPosition = getButtonLayout(parentPanelName,buttonLabels,1);
        
        % Display settings for tags1
        for i = 1:length(buttonLabels)
            UI.togglebutton.groundTruthClassification(i) = uicontrol('Parent',UI.tabs.groundTruthClassification,'Style','togglebutton','String',buttonLabels{i},'Position',buttonPosition{i},'Value',0,'Units','normalized','Callback',@(src,evnt)buttonGroundTruthClassification(i),'KeyPressFcn', {@keyPress});
        end
        UI.togglebutton.groundTruthClassification(i+1) = uicontrol('Parent',UI.tabs.groundTruthClassification,'Style','togglebutton','String','+ Cell type','Position',buttonPosition{i+1},'Units','normalized','Callback',@(src,evnt)addgroundTruthCellType,'KeyPressFcn', {@keyPress});
        
        parentPanelName.SelectedTab = UI.tabs.(childName);
        updateGroundTruth
    end
    
    function addgroundTruthCellType(~,~)
        opts.Interpreter = 'tex';
        NewTag = inputdlg({'Name of new cell type'},'Add cell type',[1 40],{''},opts);
        if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag,UI.settings.groundTruth)) && isvarname(NewTag{1})
            UI.settings.groundTruth = [UI.settings.groundTruth,NewTag];
            delete(UI.togglebutton.groundTruthClassification)
            createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.settings.groundTruth,'G/T')
            
            MsgLog(['New ground truth cell type added: ' NewTag{1}]);
            uiresume(UI.fig);
        end
    end

    function buttonGroundTruthClassification(input)
        saveStateToHistory(ii)
        if UI.togglebutton.groundTruthClassification(input).Value == 1
            if isfield(cell_metrics.groundTruthClassification,UI.settings.groundTruth{input})
                cell_metrics.groundTruthClassification.(UI.settings.groundTruth{input}) = unique([cell_metrics.groundTruthClassification.(UI.settings.groundTruth{input}),ii]);
            else
                cell_metrics.groundTruthClassification.(UI.settings.groundTruth{input}) = ii;
            end
            UI.togglebutton.groundTruthClassification(input).FontWeight = 'bold';
            UI.togglebutton.groundTruthClassification(input).ForegroundColor = UI.colors.toggleButtons;
            
            MsgLog(['Cell ', num2str(ii), ' ground truth assigned: ', UI.settings.groundTruth{input}]);
        else
            UI.togglebutton.groundTruthClassification(input).FontWeight = 'normal';
            UI.togglebutton.groundTruthClassification(input).ForegroundColor = [0 0 0];
            cell_metrics.groundTruthClassification.(UI.settings.groundTruth{input}) = setdiff(cell_metrics.groundTruthClassification.(UI.settings.groundTruth{input}),ii);
            MsgLog(['Cell ', num2str(ii), ' ground truth removed: ', UI.settings.groundTruth{input}]);
        end
    end

    function [choice,dialog_canceled] = groundTruthDlg(groundTruthCelltypes,groundTruthSelectionIn)
        choice = '';
        dialog_canceled = 1;
        updateGroundTruthCount;
        
        groundTruth_dialog = dialog('Position', [300, 300, 600, 350],'Name','Ground truth cell types','visible','off'); movegui(groundTruth_dialog,'center'), set(groundTruth_dialog,'visible','on')
        groundTruthList = uicontrol('Parent',groundTruth_dialog,'Style', 'ListBox', 'String', groundTruthCelltypesList, 'Position', [10, 50, 580, 220],'Min', 0, 'Max', 100,'Value',groundTruthSelectionIn);
        groundTruthTextfield = uicontrol('Parent',groundTruth_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 580, 25],'Callback',@(src,evnt)UpdateGroundTruthList,'HorizontalAlignment','left');
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)CloseGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[200, 10, 190, 30],'String','Cancel','Callback',@(src,evnt)CancelGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[400, 10, 190, 30],'String','Reset','Callback',@(src,evnt)ResetGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style', 'text', 'String', 'Search term', 'Position', [10, 325, 580, 20],'HorizontalAlignment','left');
        uicontrol('Parent',groundTruth_dialog,'Style', 'text', 'String', 'Selct the cell types below', 'Position', [10, 270, 580, 20],'HorizontalAlignment','left');
        uicontrol(groundTruthTextfield)
        uiwait(groundTruth_dialog);
        
        function updateGroundTruthCount
            cellCount = zeros(1,length(groundTruthCelltypes));
            for i = 1:numel(groundTruthCelltypes)
                if isfield(cell_metrics.groundTruthClassification,groundTruthCelltypes{i})
                    cellCount(i) = length(cell_metrics.groundTruthClassification.(groundTruthCelltypes{i}));
                end
            end
            cellCount = cellstr(num2str(cellCount'))';
            groundTruthCelltypesList = strcat(groundTruthCelltypes,' (',cellCount,')');
        end
        
        function UpdateGroundTruthList
            temp = find(contains(groundTruthCelltypes,groundTruthTextfield.String,'IgnoreCase',true));
            
            if ~isempty(groundTruthList.Value) && ~any(temp == groundTruthList.Value)
                groundTruthList.Value = 1;
            end
            if ~isempty(temp)
                groundTruthList.String = groundTruthCelltypesList(temp);
            else
                groundTruthList.String = {''};
            end
        end
        function  CloseGroundTruth_dialog
            if length(groundTruthList.String)>=groundTruthList.Value
                choice = groundTruthCelltypes(groundTruthList.Value);
            end
            dialog_canceled = 0;
            delete(groundTruth_dialog);
        end
        function  CancelGroundTruth_dialog
            dialog_canceled = 1;
            choice = [];
            delete(groundTruth_dialog);
        end
        function  ResetGroundTruth_dialog
            dialog_canceled = 0;
            choice = [];
            delete(groundTruth_dialog);
        end
    end

    function filterCellsByText(~,~)
        if ~isempty(UI.textFilter.String) && ~strcmp(UI.textFilter.String,'Filter')
            freeText = {''};
            [newStr2,matches] = split(UI.textFilter.String,[" & "," | "]);
            idx_textFilter2 = zeros(length(newStr2),cell_metrics.general.cellCount);
            failCheck = 0;
            for i = 1:length(newStr2)
                if strcmp(newStr2{i}(1),'.')
                    newStr = split(newStr2{i}(2:end),' ');
                    if length(newStr)==3 && isfield(cell_metrics,newStr{1}) && isnumeric(cell_metrics.(newStr{1})) && contains(newStr{2},{'==','>','<','~='})
                        switch newStr{2}
                            case '>'
                                idx_textFilter2(i,:) = cell_metrics.(newStr{1}) > str2double(newStr{3});
                            case '<'
                                idx_textFilter2(i,:) = cell_metrics.(newStr{1}) < str2double(newStr{3});
                            case '=='
                                idx_textFilter2(i,:) = cell_metrics.(newStr{1}) == str2double(newStr{3});
                            case '~='
                                idx_textFilter2(i,:) = cell_metrics.(newStr{1}) ~= str2double(newStr{3});
                            otherwise
                                failCheck = 1;
                        end
                    elseif length(newStr)==3 && ~isfield(cell_metrics,newStr{1}) && contains(newStr{2},{'==','>','<','~='})
                        failCheck = 2;
                    else
                        failCheck = 1;
                    end
                else
                    if ~isempty(freeText)
                        fieldsMenuCells = fieldnames(cell_metrics);
                        fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
                        for j = 1:length(fieldsMenuCells)
%                             if ~contains(fieldsMenuCells{j},{'groundTruthClassification','tags','groups'})
                                freeText = strcat(freeText,{' '},cell_metrics.(fieldsMenuCells{j}));
%                             end
                        end
                    end
                    idx_textFilter2(i,:) = contains(freeText,newStr2{i},'IgnoreCase',true);
                end
            end
            if failCheck == 0
                orPairs = find(contains(matches,' | '));
                if ~isempty(orPairs)
                    for i = 1:length(orPairs)
                        idx_textFilter2([orPairs(i),orPairs(i)+1],:) = any(idx_textFilter2([orPairs(i),orPairs(i)+1],:)).*[1;1];
                    end
                end
                idx_textFilter = find(all(idx_textFilter2,1));
                MsgLog([num2str(length(idx_textFilter)),'/',num2str(cell_metrics.general.cellCount),' cells selected with ',num2str(length(newStr2)),' filter: ' ,UI.textFilter.String]);
            elseif failCheck == 2
                MsgLog('Filter not formatted correctly. Field does not exist',2);
            else
                MsgLog('Filter not formatted correctly',2);
                idx_textFilter = 1:cell_metrics.general.cellCount;
            end
        else
            idx_textFilter = 1:cell_metrics.general.cellCount;
            MsgLog('Filter reset');
        end
        if isempty(idx_textFilter)
            idx_textFilter = -1;
        end
        uiresume(UI.fig);
    end

    function MsgLog(message,priority)
        % Writes the input message to the message log with a timestamp. The second parameter
        % defines the priority i.e. if any  message or warning should be given as well.
        % priority:
        % 1: Show message in Command Window
        % 2: Show msg dialog
        % 3: Show warning in Command Window
        % 4: Show warning dialog
        % -1: disp only
        
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        message2 = sprintf('[%s] %s', timestamp, message);
        if ~exist('priority','var') || (exist('priority','var') && any(priority > 0))
            UI.popupmenu.log.String = [UI.popupmenu.log.String;message2];
            UI.popupmenu.log.Value = length(UI.popupmenu.log.String);
        end
        if exist('priority','var')
            if any(priority < 0)
                disp(message2)
            end
            if any(priority == 1)
                disp(message)
            end
            if any(priority == 2)
                msgbox(message,'CellExplorer message',createStruct);
            end
            if any(priority == 3)
                warning(message)
            end
            if any(priority == 4)
                warndlg(message,'CellExplorer warning')
            end
        end
    end

    function AdjustGUI(~,~)
        % Adjusts the number of subplots. 1-3 general plots can be displayed, 3-6 cell-specific plots can be
        % displayed. The necessary panels are re-sized and toggled for the requested number of plots.
        UI.popupmenu.plotCount.Value = UI.settings.layout;
        if UI.settings.layout == 1
            % GUI: 1+3 figures.
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'off';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0 0.7 1];
            UI.panel.subfig_ax4.Position = [0.70 0.67 0.3 0.33];
            UI.panel.subfig_ax5.Position = [0.70 0.33 0.3 0.34];
            UI.panel.subfig_ax6.Position = [0.70 0 0.3 0.33];
         elseif UI.settings.layout == 2
            % GUI: 2+3 figures
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0.4 0.5 0.6];
            UI.panel.subfig_ax3.Position = [0.5 0.4 0.5 0.6];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.4];
            UI.panel.subfig_ax5.Position = [0.33 0 0.34 0.4];
            UI.panel.subfig_ax6.Position = [0.67 0 0.33 0.4];
        elseif UI.settings.layout == 3
            % GUI: 3+3 figures
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.34 0.5];
            UI.panel.subfig_ax3.Position = [0.67 0.5 0.33 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0 0.34 0.5];
            UI.panel.subfig_ax6.Position = [0.67 0 0.33 0.5];
        elseif UI.settings.layout == 4
            % GUI: 3+4 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.34 0.5];
            UI.panel.subfig_ax3.Position = [0.67 0.5 0.33 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0 0.34 0.5];
            UI.panel.subfig_ax6.Position = [0.67 0.25 0.33 0.25];
            UI.panel.subfig_ax7.Position = [0.67 0 0.33 0.25];
        elseif UI.settings.layout == 5
            % GUI: 3+5 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.33 0.5];
            UI.panel.subfig_ax3.Position = [0.67 0.5 0.33 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0.25 0.34 0.25];
            UI.panel.subfig_ax6.Position = [0.67 0.25 0.33 0.25];
            UI.panel.subfig_ax7.Position = [0.33 0 0.34 0.25];
            UI.panel.subfig_ax8.Position = [0.67 0 0.33 0.25];
        elseif UI.settings.layout == 6
            % GUI: 3+6 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'on';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'on';
            UI.panel.subfig_ax1.Position = [0 0.67 0.33 0.33];
            UI.panel.subfig_ax2.Position = [0.33 0.67 0.34 0.33];
            UI.panel.subfig_ax3.Position = [0.67 0.67 0.33 0.33];
            UI.panel.subfig_ax4.Position = [0 0.33 0.33 0.34];
            UI.panel.subfig_ax5.Position = [0.33 0.33 0.34 0.34];
            UI.panel.subfig_ax6.Position = [0.67 0.33 0.33 0.34];
            UI.panel.subfig_ax7.Position = [0 0 0.33 0.33];
            UI.panel.subfig_ax8.Position = [0.33 0 0.34 0.33];
            UI.panel.subfig_ax9.Position = [0.67 0 0.33 0.33];
        elseif UI.settings.layout == 7
            % GUI: 1+6 figures.
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'on';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'off';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'on';
            UI.panel.subfig_ax1.Position = [0 0 0.5 1];
            UI.panel.subfig_ax4.Position = [0.5 0.67 0.25 0.33];
            UI.panel.subfig_ax5.Position = [0.5 0.33 0.25 0.34];
            UI.panel.subfig_ax6.Position = [0.5 0    0.25 0.33];
            UI.panel.subfig_ax7.Position = [0.75 0.67 0.25 0.33];
            UI.panel.subfig_ax8.Position = [0.75 0.33 0.25 0.34];
            UI.panel.subfig_ax9.Position = [0.75 0    0.25 0.33];
        end
        uiresume(UI.fig);
    end

    function runBenchMark(~,~)
        % Benchmark of the CellExporer UI, single cell plots and file readings
        % 1. UI: Runs three different layouts with 50 repetitions and various group sizes
        % 2. Single cell plots: runs through all plots with 50 repetitions
        % 3. File reading benchmarks using loading times saved with cell metrics
        % 4. Reference data file reading using loading times saved with reference data
        
        testGroups = {'testGroup1','testGroup2','testGroup3','testGroup4','testGroup5','testGroup6','testGroup7'};
        testGroupsSizes = [100,500,2000,4000,6000,8000,10000];
        
        for i = 1:numel(testGroups)-1
            if cell_metrics.general.cellCount >= testGroupsSizes(i)
                cell_metrics.groups.(testGroups{i}) = UI.params.subset(randsample(length(UI.params.subset),testGroupsSizes(i)));
            else
                testGroupsSizes(i) = 0;
            end
        end
        testGroupsSizes(end) = cell_metrics.general.cellCount;
        cell_metrics.groups.(testGroups{end}) = UI.params.subset(randsample(length(UI.params.subset),testGroupsSizes(end)));
        idx = testGroupsSizes==0;
        testGroups(idx) = [];
        testGroupsSizes(idx) = [];
        nRepetitions = 100; 

        [indx,~] = listdlg('PromptString','What benchmark do you want to perform?','ListString',{'Cell Exporer UI', 'Single plot figures', 'Cell metrics file loading','Reference data file loading'},'ListSize',[300,200],'InitialValue',1,'SelectionMode','many','Name','Benchmarks');
        if any(indx == 3)
            % Benchmarking file loading
            x = cell_metrics.general.batch_benchmark.file_cell_count;
            y1 = cell_metrics.general.batch_benchmark.file_load;
            figure,
            plot(x,y1,'.b','markersize',15)
            P = polyfit(x,y1,1);
            yfit = P(1)*x+P(2);
            hold on;
            plot(x,yfit,'r-');
            title(['Benchmark of cell metrics file readings. ', num2str(1/P(1)),' cells per second']), xlabel('Cell count in metrics'), ylabel('Load time (seconds)'), axis tight
        end
        if any(indx == 4)
            % Benchmarking reference data file loading
            if isempty(reference_cell_metrics)
                out = loadReferenceData;
                if ~out
                    defineReferenceData;
                end
            end
            x = reference_cell_metrics.general.batch_benchmark.file_cell_count;
            y1 = reference_cell_metrics.general.batch_benchmark.file_load;
            figure,
            plot(x,y1,'.b','markersize',15)
            P = polyfit(x,y1,1);
            yfit = P(1)*x+P(2);
            hold on;
            plot(x,yfit,'r-');
            title(['Benchmark of reference cell metrics file readings. ', num2str(1/P(1)),' cells per second']), xlabel('Cell count in metrics'), ylabel('Load time (seconds)'), axis tight
        end
        if any(indx == 2)
            figure(UI.fig)
            % Benchmarking single figures
            t_bench_single = [];
            plotOptions1 = {'Waveforms (single)','Waveforms (all)','Waveforms (across channels)','Waveforms (image)','Trilaterated position','ACGs (single)','ACGs (all)','ACGs (image)','CCGs (image)','ISIs (single)','ISIs (all)','ISIs (image)','Connectivity graph'};
            plotOptions1 = plotOptions;
            disp(['Benchmarking single cell plots (n = ',num2str(numel(plotOptions1)),')'])
            for k = 1:numel(plotOptions1)
                disp([plotOptions1{k},' ',num2str(k),'/',num2str(numel(plotOptions1))])
                t_bench1 = runBenchMarkSinglePlot(plotOptions1{k});
                t_bench_single = [t_bench_single,t_bench1];
            end
            figure,
            subplot(2,1,1)
            plot(1000*diff(t_bench_single)); title('benchmarking single plots'), xlabel('Test number'), ylabel('Processing time (ms)'), ylim([0,500])
            subplot(2,1,2)
            
            x_mean = median(reshape(1000*diff(t_bench_single)',[numel(testGroups),size(t_bench_single,2)/numel(testGroups),size(t_bench_single,1)-1]),3);
            plot(testGroupsSizes,x_mean,'o-'), xlabel('Process'), ylabel('Processing time (ms)'), ylim([0,1200])
            text(8000*ones(1,size(x_mean,2)),x_mean(6,:),plotOptions1,'HorizontalAlignment','center','VerticalAlignment','bottom')
            figure(UI.fig)
        end
        if any(indx == 1)
            figure(UI.fig)
            % Benchmark of the CellExplorer UI. Runs three different layouts with 25 repetitions.
            t_bench = [];
            % 1. benchmark with minimum features
            UI.settings.metricsTable = 3; % turning off table data
            buttonShowMetrics
            UI.panel.tabgroup2.SelectedTab = UI.tabs.dispTags_minus; % Deselecting figure legends
            UI.settings.plotInsetChannelMap = 1; % Hiding channel map inset in waveform plots.
            UI.settings.plotInsetACG = 1; % Hiding ACG inset in waveform plots.
            UI.settings.customPlot{1} = 'ACGs (single)';
            UI.settings.customPlot{2} = 'ACGs (single)';
            UI.settings.customPlot{3} = 'ACGs (single)';
            UI.settings.layout = 1; % GUI: 1+3 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % 2. benchmark
            UI.settings.metricsTable = 1; % turning off table data
            buttonShowMetrics
            UI.panel.tabgroup2.SelectedTab = UI.tabs.legends; % Selecting figure legends
            UI.settings.plotInsetChannelMap = 3; % Showing channel map inset in waveform plots.
            UI.settings.plotInsetACG = 2; % Showing ACG inset in waveform plots.
            UI.settings.customPlot{1} = 'Waveforms (all)';
            UI.settings.customPlot{2} = 'ACGs (single)';
            UI.settings.customPlot{3} = 'RCs_firingRateAcrossTime';
            UI.settings.customPlot{4} = 'Waveforms (single)';
            UI.settings.customPlot{5} = 'CCGs (image)';
            UI.settings.customPlot{6} = 'ISIs (all)';
            UI.settings.layout = 3; % GUI: 3+3 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % 3. benchmark
            UI.settings.layout = 6; % GUI: 3+6 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % Plotting benchmark figure
            figure(50),
            subplot(2,1,1)
            plot(1000*diff(t_bench)); title('benchmarking UI'), xlabel('Test number'), ylabel('Processing time (ms)'), ylim([0,500])
            subplot(2,1,2)
            
            y1 = mean(1000*diff(t_bench));
            y_std = std(1000*diff(t_bench));
            idx = 1:length(testGroupsSizes);
            f1(1) = errorbarPatch(testGroupsSizes,y1(idx),y_std(idx),[0.8 0.2 0.2]);
            f1(2) = errorbarPatch(testGroupsSizes,y1(idx+length(idx)),y_std(idx+length(idx)),[0.2 0.8 0.2]);
            f1(3) = errorbarPatch(testGroupsSizes,y1(idx+length(idx)*2),y_std(idx+length(idx)*2),[0.2 0.2 0.8]);
            xlabel('Number of cells'), ylabel('Processing time (ms)'), ylim([0,800])
            legend(f1,{'Layout: 1+3','Layout: 3+3','Layout: 3+6 simple',}), title('Average processing times')
            figure(UI.fig)
        end
          
    function t_bench = runBenchMarkRound
        timerVal1 = tic;
        t_bench = [];
        for j = 1:numel(testGroups)
            groupData.groups.plus_filter.(testGroups{j}) = 1;
            pause(0.5)
            for i = 1:nRepetitions
                ii = cell_metrics.groups.(testGroups{j})(i);
                updateUI
                drawnow nocallbacks;
                t_bench(i,j) = toc(timerVal1);
            end
            groupData.groups.plus_filter.(testGroups{j}) = 0;
        end
    end
        function t_bench = runBenchMarkSinglePlot(plotOptionsIn)
            % Benchmarking single figures
            testFig1 = figure('pos',UI.settings.figureSize,'name','Single cell plot benchmarks');
            testFig = gca;
            timerVal1 = tic;
            t_bench = [];
            for j = 1:numel(testGroups)
                groupData.groups.plus_filter.(testGroups{j}) = 1;
%                 ii = 1;
                figure(UI.fig)
                updateUI
                figure(testFig1), set(testFig1,'name',['Single cell plot benchmarks: group: ',num2str(j),'/',num2str(numel(testGroups))])
                pause(0.5)
                for i_rep = 1:nRepetitions
                    ii = cell_metrics.groups.(testGroups{j})(i_rep);
                    delete(testFig.Children)
%                     set(testFig1,'CurrentAxes',testFig)
                    set(testFig,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), grid(testFig,'off')
                    
                    if UI.BatchMode
                        batchIDs1 = cell_metrics.batchIDs(ii);
                        general1 = cell_metrics.general.batch{batchIDs1};
                    else
                        general1 = cell_metrics.general;
                        batchIDs1 = 1;
                    end
                    
                    % Defining putative connections for selected cells
                    if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && ~isempty(cell_metrics.putativeConnections.excitatory)
                        putativeSubset = find(all(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)'));
                    else
                        putativeSubset=[];
                        UI.params.incoming = [];
                        UI.params.outgoing = [];
                        UI.params.connections = [];
                    end
                    
                    if ~isempty(putativeSubset)
                        UI.params.a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                        UI.params.a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                        UI.params.inbound = find(UI.params.a2 == ii);
                        UI.params.outbound = find(UI.params.a1 == ii);
                        UI.params.incoming = UI.params.a1(UI.params.inbound);
                        UI.params.outgoing = UI.params.a2(UI.params.outbound);
                        UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                    end
                    
                    customPlot(plotOptionsIn,ii,general1,batchIDs1,testFig);
                    drawnow nocallbacks;
                    t_bench(i_rep,j) = toc(timerVal1);
                end
                groupData.groups.plus_filter.(testGroups{j}) = 0;
            end
            close(testFig1)
        end
    end

    function keyPress(~, event)
        % Keyboard shortcuts. Sorted alphabetically
        switch event.Key
            case 'h'
                HelpDialog;
            case 'm'
                % Hide/show menubar
                ShowHideMenu
            case 'n'
                % Adjusts the number of subplots in the GUI
                AdjustGUIkey;
            case 'z'
                % undoClassification;
            case 'space'
                selectCellsForGroupAction
            case 'backspace'
                ii_history_reverse;
            case {'add','hyphen'}
                ScrolltoZoomInPlot([],[],1)
            case {'slash','subtract'}
                ScrolltoZoomInPlot([],[],-1)
            case {'multiply'}
                ScrolltoZoomInPlot([],[],0)
            case 'pagedown'
                % Goes to the first cell from the previous session in a batch
                if UI.BatchMode
                    if ii ~= 1 && cell_metrics.batchIDs(ii) == cell_metrics.batchIDs(ii-1)
                        temp = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii),1);
                    else
                        temp = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)-1,1);
                    end
                    if ~isempty(temp)
                        ii =  UI.params.subset(temp);
                        uiresume(UI.fig);
                    end
                end
            case {'pageup','backquote'}
                % Goes to the first cell from the next session in a batch
                if UI.BatchMode
                    temp = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)+1,1);
                    if ~isempty(temp)
                        ii =  UI.params.subset(temp);
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
                buttonCellType(str2double(event.Key));
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                advanceClass(str2double(event.Key(end)))
            case 'numpad0'
                ii = 1;
                uiresume(UI.fig);
        end
    end

    function ShowHideMenu(~,~)
        % Hide/show menubar
        if UI.settings.displayMenu == 0
            set(UI.fig, 'MenuBar', 'figure')
            UI.settings.displayMenu = 1;
            UI.menu.display.showHideMenu.Checked = 'On';
        else
            set(UI.fig, 'MenuBar', 'None')
            UI.settings.displayMenu = 0;
            UI.menu.display.showHideMenu.Checked = 'Off';
        end
    end

    function AboutDialog(~,~)
        if ismac
            fig_size = [50, 50, 300, 130];
            pos_image = [20 72 268 46];
            pos_text = 110;
        else
            fig_size = [50, 50, 320, 150];
            pos_image = [20 88 268 46];
            pos_text = 110;
        end
        
        [logog_path,~,~] = fileparts(which('CellExplorer.m'));
        logo = imread(fullfile(logog_path,'logoCellExplorer.png'));
        AboutWindow.dialog = figure('Position', fig_size,'Name','About CellExplorer', 'MenuBar', 'None','NumberTitle','off','visible','off', 'resize', 'off'); movegui(AboutWindow.dialog,'center'), set(AboutWindow.dialog,'visible','on')
        [img, map, alphachannel] = imread(fullfile(logog_path,'logoCellExplorer.png'));
        image(img, 'AlphaData', alphachannel,'ButtonDownFcn',@openWebsite);
        AboutWindow.image = gca;
        set(AboutWindow.image,'Color','none','Units','Pixels') , hold on, axis off
        AboutWindow.image.Position = pos_image;
        
        text(0,pos_text,{['\bfCellExplorer\rm v', num2str(CellExplorerVersion)],'By Peter Petersen.', 'Developed in the Buzsaki laboratory at NYU, USA.','\it\color[rgb]{0. 0.2 0.5}https://petersenpeter.github.io/CellExplorer/\rm'},'HorizontalAlignment','left','VerticalAlignment','top','ButtonDownFcn',@openWebsite)
    end

    function HelpDialog(~,~)
        if ismac; scs  = 'Cmd + '; else; scs  = 'Ctrl + '; end
        shortcutList = { '','<html><b>Navigation</b></html>';
            '> (right arrow)','Next cell'; '< (left arrow)','Previous cell'; '. (dot)','Next cell with same class'; ', (comma) ','Previous cell with same class';
            [scs,'F '],'Go to a specific cell'; 'Page Up ','Next session in batch (only in batch mode)'; 'Page Down','Previous session in batch (only in batch mode)';
            'Numpad0','First cell'; 'Numpad1-9 ','Next cell with that numeric class'; 'Backspace','Previously selected cell'; 'Numeric + / - / *','Zoom in / zoom out / reset plots'; '   ',''; 
            '','<html><b>Cell assigments</b></html>';
            '1-9 ','Cell-types'; [scs,'B'],'Brain region'; [scs,'L'],'Label'; [scs,'Z'],'Undo assignment'; [scs,'R'],'Reclassify cell types'; ' ',' ';
            '','<html><b>Display shortcuts</b></html>';
            'M','Show/Hide menubar'; 'N','Change layout [6; 5 or 4 subplots]'; [scs,'E'],'Highlight excitatory cells (triangles)'; [scs,'I'],'Highlight inhibitory cells (circles)';
            [scs,'F'],'Display ACG fit'; 'K','Calculate and display significance matrix for all metrics (KS-test)'; [scs,'T'],'Calculate tSNE space from a selection of metrics';
            'W','Display waveform metrics'; [scs,'Y'],'Perform ground truth cell type classification'; [scs,'U'],'Load ground truth cell types'; 'Space','Show action dialog for selected cells'; '  ','';
            '','<html><b>Other shortcuts</b></html>';
            [scs,'P'],'Open preferences for CellExplorer'; [scs,'C'],'Open the file directory of the selected cell'; [scs,'D'],'Opens sessions from the Buzsaki lab database';
            [scs,'A'],'Open spike data menu'; [scs,'J'],'Modify parameters for a spike plot'; [scs,'V'],'Visit the CellExplorer website in your browser';
            '',''; '','<html><b>Visit the CellExplorer website for further help and documentation</html></b>'; };
        if ismac
            dimensions = [450,(size(shortcutList,1)+1)*17.5];
        else
            dimensions = [450,(size(shortcutList,1)+1)*18.5];
        end
        HelpWindow.dialog = figure('Position', [300, 300, dimensions(1), dimensions(2)],'Name','CellExplorer: keyboard shortcuts', 'MenuBar', 'None','NumberTitle','off','visible','off'); movegui(HelpWindow.dialog,'center'), set(HelpWindow.dialog,'visible','on')
        HelpWindow.sessionList = uitable(HelpWindow.dialog,'Data',shortcutList,'Position',[1, 1, dimensions(1)-1, dimensions(2)-1],'ColumnWidth',{100 345},'columnname',{'Shortcut','Action'},'RowName',[],'ColumnEditable',[false false],'Units','normalized');
    end
end