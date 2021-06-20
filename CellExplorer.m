function cell_metrics = CellExplorer(varargin)
% CellExplorer is a Matlab GUI and standardized pipeline for exploring and
% classifying spike sorted single units acquired using extracellular electrodes.
%
% Check out the website for extensive documentation and tutorials: https://CellExplorer.org/
%
% Below follows a detailed description of how to call CellExplorer
%
% INPUTS
% varargin (Variable-length input argument list)
%
% - Single session struct with cell_metrics from one or more sessions
% metrics                - cell_metrics struc
%
% - Single session inputs
% basepath               - Path to session (base directory)
% basename               - basename (database session name)
% id                     - BuzLabDB numeric id
% session                - Session struct
%
% - Batch session inputs (when loading multiple session)
% basepaths              - Paths to sessions (base directory)
% sessionIDs             - BuzLabDB numeric ids
% sessions               - session names (basenames)
%
% - Example calls:
% cell_metrics = CellExplorer                             % Load from current path, assumed to be a basepath
% cell_metrics = CellExplorer('basepath',basepath)        % Load from basepath
% cell_metrics = CellExplorer('metrics',cell_metrics)     % Load from cell_metrics
% cell_metrics = CellExplorer('session',session)          % Load session from session struct
% cell_metrics = CellExplorer('sessionName','rec1')       % Load session from database session name
% cell_metrics = CellExplorer('sessionID',10985)          % Load session from BuzLabDB session id
% cell_metrics = CellExplorer('sessions',{'rec1','rec2'})          % Load batch from database
% cell_metrics = CellExplorer('basepaths',{'path1','[path1'})      % Load batch from a list with paths
%
% - Summary figure calls:
% CellExplorer('metrics',cell_metrics,'summaryFigures',true,'plotCellIDs',-1)      % creates Session summary figure from cell_metrics for all cells
% CellExplorer('metrics',cell_metrics,'summaryFigures',true)                       % creates Cell summary figures from cell_metrics for all cells
% CellExplorer('metrics',cell_metrics,'summaryFigures',true,'plotCellIDs',[1,4,5]) % creates Cell summary figures for select cells [1,4,5]
%
% OUTPUT
% cell_metrics: struct

% By Peter Petersen
% petersen.peter@gmail.com

% Shortcuts to built-in functions:
% Data handling: initializeSession, saveDialog, restoreBackup, importGroundTruth, DatabaseSessionDialog, defineReferenceData, initializeReferenceData, defineGroupData
% UI: hoverCallback, updateUI, customPlot, plotGroupData, GroupAction, defineSpikesPlots, keyPress, FromPlot, GroupSelectFromPlot, ScrolltoZoomInPlot, brainRegionDlg, tSNE_redefineMetrics plotSummaryFigures

if isdeployed % Check for if CellExplorer is running as a deployed app (compiled .exe or .app for windows and mac respectively)
    if ~isempty(varargin) % If a file name is provided it will load it.
        filename = varargin{1};
        [basepath1,file1] = fileparts(varargin{1});
    else % Otherwise a file load dialog will be shown
        [file1,basepath1] = uigetfile('*.mat;*.dat;*.lfp;*.xml','Please select a file with the basename in it from the basepath');
    end
    if ~isequal(file1,0)
        basepath = basepath1;
        temp1 = strsplit(file1,'.');
        basename = temp1{1};
    else
        return
    end
    metrics = [];
    id = [];
    sessionName = [];
    session = [];
    sessionIDs = {};
    sessionsin = {};
    summaryFigures = false;
    plotCellIDs = [];
    basepaths = {};
else
    p = inputParser;
    
    addParameter(p,'metrics',[],@isstruct);         % cell_metrics struct
    addParameter(p,'basepath',pwd,@isstr);          % Path to session (base directory)
    addParameter(p,'session',[],@isstruct);
    addParameter(p,'basename','',@isstr);
    addParameter(p,'sessionID',[],@isnumeric);
    addParameter(p,'sessionName',[],@isstr);
    
    % Batch input
    addParameter(p,'sessionIDs',{},@iscell);
    addParameter(p,'sessions',{},@iscell);
    addParameter(p,'basepaths',{},@iscell);
    
    % Extra inputs
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
    
    % Batch inputs
    sessionIDs = p.Results.sessionIDs;
    sessionsin = p.Results.sessions;
    basepaths = p.Results.basepaths;
    
    % Extra inputs
    summaryFigures = p.Results.summaryFigures;
    plotCellIDs = p.Results.plotCellIDs;
end

%% % % % % % % % % % % % % % % % % % % % % %
% Initialization of variables and figure
% % % % % % % % % % % % % % % % % % % % % %

UI = []; UI.BatchMode = false; UI.params.ClickedCells = []; UI.params.inbound = []; 
UI.drag.mouse = false; UI.drag.startX = []; UI.drag.startY = []; UI.drag.axnum = []; UI.drag.pan = []; UI.scroll = true;
UI.params.ii_history = 1; UI.lists.metrics = []; UI.params.hoverStyle = 2;
UI.params.incoming = []; UI.params.outgoing = []; UI.monoSyn.disp = ''; UI.monoSyn.dispHollowGauss = false;
UI.params.ACGLogIntervals = -3:0.04:1; UI.tableData.Column1 = 'putativeCellType'; UI.tableData.Column2 = 'brainRegion'; 
UI.tableData.SortBy = 'cellID'; UI.plot.xTitle = ''; UI.plot.yTitle = ''; UI.plot.zTitle = '';  UI.params.alteredCellMetrics = 1;
UI.cells.excitatory = []; UI.cells.inhibitory = []; UI.cells.inhibitory_subset = []; UI.cells.excitatory_subset = [];
UI.cells.excitatoryPostsynaptic = []; UI.cells.inhibitoryPostsynaptic = []; UI.params.outbound = []; 
UI.zoom.global = cell(1,10); UI.zoom.globalLog = cell(1,10);  
UI.params.chanCoords.x_factor = 40; UI.params.chanCoords.y_factor = 10; UI.colors.toggleButtons = [0. 0.3 0.7];
UI.colorLine = [0, 0.4470, 0.7410;0.8500, 0.3250, 0.0980;0.9290, 0.6940, 0.1250;0.4940, 0.1840, 0.5560;0.4660, 0.6740, 0.1880;0.3010, 0.7450, 0.9330;0.6350, 0.0780, 0.1840];
UI.params.fieldsMenuMetricsToExlude  = {'tags','groundTruthClassification','groups','spikes'};
UI.params.plotOptionsToExlude = {'acg_','waveforms_','isi_','responseCurves_thetaPhase','responseCurves_thetaPhase_zscored','responseCurves_firingRateAcrossTime','groups','tags','groundTruthClassification','spikes'}; 
UI.params.menuOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','groups','spikes'}; 
UI.params.tableOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','brainRegion','labels','deepSuperficial','groups','spikes'};
UI.params.tableDataSortingList = sort({'cellID', 'putativeCellType','peakVoltage','firingRate','troughToPeak','synapticConnectionsOut','synapticConnectionsIn','animal','sessionName','cv2','brainRegion','electrodeGroup'});
UI.classes.plot2 = []; UI.classes.colors = []; UI.classes.colors2 = [];  UI.classes.colors3 = []; UI.classes.plot = []; UI.classes.plot11 = []; 
UI.brainRegions.list = []; UI.brainRegions.acronym = []; UI.brainRegions.relational_tree = []; UI.groupData1.groupsList = {'groups','tags','groundTruthClassification'};

plotConnections = [1 1 1]; plotAverage_nbins = 40; 
synConnectOptions = {'None', 'Selected', 'Upstream', 'Downstream', 'Up & downstream', 'All'}; ccf_ratio = [-35.5,30];
plotX = []; plotY = []; plotY1 = []; plotZ = [];  plotMarkerSize = [];
fig2_axislimit_x = []; fig2_axislimit_y = []; fig3_axislimit_x = []; fig3_axislimit_y = [];
fig2_axislimit_x_reference = []; fig2_axislimit_y_reference = []; fig2_axislimit_x_groundTruth = []; fig2_axislimit_y_groundTruth = [];
ce_waitbar = []; colorStr = []; iLine = 1; h_scatter = []; groups_ids = []; clusClas = [];  meanCCG = [];
hover2highlight = {}; clickPlotRegular = true; 
classes2plot = []; classes2plotSubset = []; ii = []; history_classification = []; batchIDs = []; general = []; classificationTrackChanges = []; 
cell_class_count = [];  plotOptions = ''; colorMenu = []; GroupVal = 1; ColorVal = 1; 
plotAcgFit = 0; plotAcgYLog = 0; plotAcgZscore = 0; clasLegend = 0; groups2plot = []; groups2plot2 = []; connectivityGraph = []; 
tSNE_metrics = [];  spikesPlots = {}; gauss2d = gausswin(10)*gausswin(10)'; gauss2d = 1.*gauss2d/sum(gauss2d(:));
idx_textFilter = []; freeText = {''}; table_metrics = []; table_fieldsNames = {}; tableDataOrder = []; 
groundTruthSelection = []; subsetGroundTruth = []; groundTruthCelltypesList = {''}; db = {}; gt = {}; 
customPlotOptions = {}; timerInterface = tic; timerHover = tic;

spikes = []; events = []; states = [];
referenceData=[]; reference_cell_metrics = []; groundTruth_cell_metrics = []; groundTruthData=[]; 

createStruct.Interpreter = 'tex'; createStruct.WindowStyle = 'modal';
createStruct1.Interpreter = 'none'; createStruct1.WindowStyle = 'modal';
polygon1.handle = gobjects(0); fig = 1;
set(groot, 'DefaultFigureVisible', 'on','DefaultAxesLooseInset',[.01,.01,.01,.01],'DefaultTextInterpreter', 'none'), maxFigureSize = get(groot,'ScreenSize'); UI.preferences.figureSize = [50, 50, min([1500,maxFigureSize(3)-100]), min([1000,maxFigureSize(4)-100])];

if isempty(basename)
    basename = basenameFromBasepath(basepath);
end

CellExplorerVersion = 1.70;

UI.fig = figure('Name',['CellExplorer v' num2str(CellExplorerVersion)],'NumberTitle','off','renderer','opengl', 'MenuBar', 'None','windowscrollWheelFcn',@ScrolltoZoomInPlot,'KeyPressFcn', {@keyPress},'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off','WindowButtonMotionFcn', @hoverCallback,'pos',[0,0,1600,800],'DefaultTextInterpreter', 'none', 'DefaultLegendInterpreter', 'none'); % ,'WindowButtonDownFcn',@mousebuttonPress,'WindowButtonUpFcn',@mousebuttonRelease
hManager = uigetmodemanager(UI.fig);

% % % % % % % % % % % % % % % % % % % % % %
% User preferences
% % % % % % % % % % % % % % % % % % % % % %

preferences_CellExplorer

% % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Checking for Matlab version requirement (Matlab R2017a)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % %

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
                [session, basename, basepath] = db_set_session('sessionId',id,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
        elseif ~isempty(sessionName)
            try
                [session, basename, basepath] = db_set_session('sessionName',sessionName,'saveMat',false);
            catch
                warning('Failed to load dataset');
                return
            end
        else
            try
                [session, basename, basepath] = db_set_session('session',session,'saveMat',false);
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
        warning('BuzLabDB tools not available');
        return
    end
elseif ~isempty(sessionIDs)
    if enableDatabase
        try
            cell_metrics = loadCellMetricsBatch('sessionIDs',sessionIDs);
            initializeSession
        catch
            warning('Failed to load dataset');
            return
        end
    else
        warning('BuzLabDB tools not available');
        return
    end
elseif ~isempty(sessionsin)
    if enableDatabase
        try
            cell_metrics = loadCellMetricsBatch('sessions',sessionsin);
            initializeSession
        catch
            warning('Failed to load dataset');
            return
        end
    else
        warning('BuzLabDB tools not available');
        return
    end
elseif ~isempty(basepaths)
    try
        cell_metrics = loadCellMetricsBatch('basepaths',basepaths);
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
    basename = basenameFromBasepath(basepath);
    if exist(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']),'file')
        disp('Loading local cell_metrics')
        load(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']));
        cell_metrics.general.basepath = basepath;
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
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Run benchmarks',menuSelectedFcn,@runBenchMark,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitCellExplorer,'Separator','on','Accelerator','W');

% File
UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
uimenu(UI.menu.file.topMenu,menuLabel,'Load session from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
UI.menu.file.save = uimenu(UI.menu.file.topMenu,menuLabel,'Save classification',menuSelectedFcn,@saveDialog,'Separator','on','Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Restore classification from backup',menuSelectedFcn,@restoreBackup);
uimenu(UI.menu.file.topMenu,menuLabel,'Reload cell metrics',menuSelectedFcn,@reloadCellMetrics,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Export figure dialog',menuSelectedFcn,@exportFigure,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Generate supplementary figure',menuSelectedFcn,@plotSupplementaryFigure);
uimenu(UI.menu.file.topMenu,menuLabel,'Generate summary figure',menuSelectedFcn,@plotSummaryFigure);

% Cell selection
UI.menu.cellSelection.topMenu = uimenu(UI.fig,menuLabel,'Cell selection');
uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Polygon selection of cells from plot',menuSelectedFcn,@polygonSelection,'Accelerator','P');
uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Perform group action [space]',menuSelectedFcn,@selectCellsForGroupAction);
UI.menu.cellSelection.stickySelection = uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Sticky cell selection',menuSelectedFcn,@toggleStickySelection,'Separator','on');
UI.menu.cellSelection.stickySelectionReset = uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Reset sticky selection',menuSelectedFcn,@toggleStickySelectionReset);
UI.menu.cellSelection.hoverEffect = uimenu(UI.menu.cellSelection.topMenu,menuLabel,'Highlight cells by mouse hover',menuSelectedFcn,@adjustHoverEffect,'Separator','on');
if UI.preferences.hoverEffect; UI.menu.cellSelection.hoverEffect.Checked = 'on'; end

% Classification
UI.menu.edit.topMenu = uimenu(UI.fig,menuLabel,'Classification');
UI.menu.edit.undoClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Undo classification',menuSelectedFcn,@undoClassification,'Accelerator','Z');
UI.menu.edit.buttonBrainRegion = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign brain region',menuSelectedFcn,@buttonBrainRegion,'Accelerator','B');
UI.menu.edit.buttonLabel = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign label',menuSelectedFcn,@buttonLabel,'Accelerator','L');
UI.menu.edit.addCellType = uimenu(UI.menu.edit.topMenu,menuLabel,'Add new cell-type',menuSelectedFcn,@AddNewCellType,'Separator','on');
UI.menu.edit.addTag = uimenu(UI.menu.edit.topMenu,menuLabel,'Add new tag',menuSelectedFcn,@addTag);

UI.menu.edit.reclassify_celltypes = uimenu(UI.menu.edit.topMenu,menuLabel,'Reclassify cells',menuSelectedFcn,@reclassify_celltypes,'Separator','on');
UI.menu.edit.performClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Agglomerative hierarchical cluster tree classification',menuSelectedFcn,@performClassification);
UI.menu.edit.adjustDeepSuperficial = uimenu(UI.menu.edit.topMenu,menuLabel,'Adjust Deep-Superficial assignment for session',menuSelectedFcn,@adjustDeepSuperficial1,'Separator','on');

% Waveforms
UI.menu.waveforms.topMenu = uimenu(UI.fig,menuLabel,'Waveforms');
UI.menu.waveforms.zscoreWaveforms = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Z-score waveforms',menuSelectedFcn,@adjustZscoreWaveforms);
if UI.preferences.zscoreWaveforms; UI.menu.waveforms.zscoreWaveforms.Checked = 'on'; end 
UI.menu.waveforms.showMetrics = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Show waveform metrics',menuSelectedFcn,@showWaveformMetrics);
UI.menu.waveforms.showChannelMapMenu = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Channel map inset','Separator','on');
UI.menu.waveforms.showChannelMap.ops(1) = uimenu(UI.menu.waveforms.showChannelMapMenu,menuLabel,'No channelmap',menuSelectedFcn,@showChannelMap);
UI.menu.waveforms.showChannelMap.ops(2) = uimenu(UI.menu.waveforms.showChannelMapMenu,menuLabel,'By peak channel',menuSelectedFcn,@showChannelMap);
UI.menu.waveforms.showChannelMap.ops(3) = uimenu(UI.menu.waveforms.showChannelMapMenu,menuLabel,'By trilateration',menuSelectedFcn,@showChannelMap);
if UI.preferences.plotInsetChannelMap; UI.menu.waveforms.showChannelMap.ops(UI.preferences.plotInsetChannelMap).Checked = 'on'; end
UI.menu.waveforms.channelMapColoring = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Show group colors in channel map inset',menuSelectedFcn,@showChannelMap);
UI.menu.waveforms.showInsetACG = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Show ACG inset',menuSelectedFcn,@showInsetACG,'Separator','on');
if UI.preferences.plotInsetACG; UI.menu.waveforms.showInsetACG.Checked = 'on'; end
UI.menu.waveforms.waveformsAcrossChannelsAlignmentMenu = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Waveform alignment','Separator','on');
UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(1) = uimenu(UI.menu.waveforms.waveformsAcrossChannelsAlignmentMenu,menuLabel,'Probe layout',menuSelectedFcn,@adjustWaveformsAcrossChannelsAlignment);
UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(2) = uimenu(UI.menu.waveforms.waveformsAcrossChannelsAlignmentMenu,menuLabel,'Electrode groups',menuSelectedFcn,@adjustWaveformsAcrossChannelsAlignment);
initGroupMenu('waveforms','waveformsAcrossChannelsAlignment')
UI.menu.waveforms.plotChannelMapAllChannelsMenu = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Waveform count across channels');
UI.menu.waveforms.plotChannelMapAllChannels.ops(1) = uimenu(UI.menu.waveforms.plotChannelMapAllChannelsMenu,menuLabel,'All channels',menuSelectedFcn,@adjustPlotChannelMapAllChannels);
UI.menu.waveforms.plotChannelMapAllChannels.ops(2) = uimenu(UI.menu.waveforms.plotChannelMapAllChannelsMenu,menuLabel,'Best channels',menuSelectedFcn,@adjustPlotChannelMapAllChannels);
initGroupMenu('waveforms','plotChannelMapAllChannels')
UI.menu.waveforms.trilatGroupDataMenu = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Trilateration group data');
UI.menu.waveforms.trilatGroupData.ops(1) = uimenu(UI.menu.waveforms.trilatGroupDataMenu,menuLabel,'session',menuSelectedFcn,@adjustTrilatGroupData);
UI.menu.waveforms.trilatGroupData.ops(2) = uimenu(UI.menu.waveforms.trilatGroupDataMenu,menuLabel,'animal',menuSelectedFcn,@adjustTrilatGroupData);
UI.menu.waveforms.trilatGroupData.ops(3) = uimenu(UI.menu.waveforms.trilatGroupDataMenu,menuLabel,'all',menuSelectedFcn,@adjustTrilatGroupData);
initGroupMenu('waveforms','trilatGroupData')
UI.menu.waveforms.peakVoltage_session = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Population in Peak voltage plot',menuSelectedFcn,@showSessionPeakVoltage,'Separator','on');
if UI.preferences.peakVoltage_session; UI.menu.waveforms.peakVoltage_session.Checked = 'on'; end
UI.menu.waveforms.peakVoltage_all_sortingMenu = uimenu(UI.menu.waveforms.topMenu,menuLabel,'Peak voltage channel sorting');
UI.menu.waveforms.peakVoltage_all_sorting.ops(1) = uimenu(UI.menu.waveforms.peakVoltage_all_sortingMenu,menuLabel,'Channel order',menuSelectedFcn,@adjustPeakVoltage_all_sorting);
UI.menu.waveforms.peakVoltage_all_sorting.ops(2) = uimenu(UI.menu.waveforms.peakVoltage_all_sortingMenu,menuLabel,'Amplitude',menuSelectedFcn,@adjustPeakVoltage_all_sorting);
UI.menu.waveforms.peakVoltage_all_sorting.ops(3) = uimenu(UI.menu.waveforms.peakVoltage_all_sortingMenu,menuLabel,'None',menuSelectedFcn,@adjustPeakVoltage_all_sorting);
initGroupMenu('waveforms','peakVoltage_all_sorting')
                    
% View / display
UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'View');
UI.menu.display.showHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Show regular Matlab menubar',menuSelectedFcn,@ShowHideMenu,'Accelerator','M');
UI.menu.display.showAllTraces = uimenu(UI.menu.display.topMenu,menuLabel,'Show all traces',menuSelectedFcn,@showAllTraces,'Separator','on');
if UI.preferences.showAllTraces; UI.menu.display.showAllTraces.Checked = 'on'; end 
UI.menu.display.dispLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend in spikes plot',menuSelectedFcn,@showLegends);
if UI.preferences.dispLegend; UI.menu.display.dispLegend.Checked = 'on'; end
UI.menu.display.plotLinearFits = uimenu(UI.menu.display.topMenu,menuLabel,'Show linear fit in group plot',menuSelectedFcn,@togglePlotLinearFits);
if UI.preferences.plotLinearFits; UI.menu.display.plotLinearFits.Checked = 'on'; end
UI.menu.display.firingRateMapShowLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowLegend,'Separator','on');
if UI.preferences.firingRateMap.showLegend; UI.menu.display.firingRateMapShowLegend.Checked = 'on'; end
UI.menu.display.showHeatmap = uimenu(UI.menu.display.topMenu,menuLabel,'Show heatmap in firing rate maps',menuSelectedFcn,@ToggleHeatmapFiringRateMaps);
if UI.preferences.firingRateMap.showHeatmap; UI.menu.display.showHeatmap.Checked = 'on'; end
UI.menu.display.firingRateMapShowHeatmapColorbar = uimenu(UI.menu.display.topMenu,menuLabel,'Show colorbar in heatmaps in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowHeatmapColorbar);
if UI.preferences.firingRateMap.showHeatmapColorbar; UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on'; end
UI.menu.display.isiNormalizationMenu = uimenu(UI.menu.display.topMenu,menuLabel,'ISI normalization','Separator','on');
UI.menu.display.isiNormalization.ops(1) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Rate',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.isiNormalization.ops(2) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Occurrence',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.isiNormalization.ops(3) = uimenu(UI.menu.display.isiNormalizationMenu,menuLabel,'Instantaneous rate',menuSelectedFcn,@buttonACG_normalize);
initGroupMenu('display','isiNormalization')
UI.menu.display.rainCloudNormalizationMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Histogram/raincloud normalization');
UI.menu.display.rainCloudNormalization.ops(1) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Peak',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
UI.menu.display.rainCloudNormalization.ops(2) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Probability',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
UI.menu.display.rainCloudNormalization.ops(3) = uimenu(UI.menu.display.rainCloudNormalizationMenu,menuLabel,'Count',menuSelectedFcn,@adjustRainCloudNormalizationMenu);
initGroupMenu('display','rainCloudNormalization')
UI.menu.display.rasterMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Spike raster y-data');
UI.menu.display.raster.ops(1) = uimenu(UI.menu.display.rasterMenu,menuLabel,'CV2',menuSelectedFcn,@adjustSpikeRasterMenu);
UI.menu.display.raster.ops(2) = uimenu(UI.menu.display.rasterMenu,menuLabel,'ISIs',menuSelectedFcn,@adjustSpikeRasterMenu);
UI.menu.display.raster.ops(3) = uimenu(UI.menu.display.rasterMenu,menuLabel,'Random',menuSelectedFcn,@adjustSpikeRasterMenu);
initGroupMenu('display','raster')
UI.menu.display.significanceMetricsMatrix = uimenu(UI.menu.display.topMenu,menuLabel,'Generate significance matrix',menuSelectedFcn,@SignificanceMetricsMatrix,'Accelerator','K','Separator','on');
UI.menu.display.generateRainCloudsPlot = uimenu(UI.menu.display.topMenu,menuLabel,'Generate rain cloud metrics figure',menuSelectedFcn,@generateRainCloudPlot);
UI.menu.display.markerSizeMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Change marker size for group plots',menuSelectedFcn,@defineMarkerSize,'Separator','on');
UI.menu.display.changeColormap = uimenu(UI.menu.display.topMenu,menuLabel,'Change colormap',menuSelectedFcn,@changeColormap);
UI.menu.display.sortingMetric = uimenu(UI.menu.display.topMenu,menuLabel,'Change metric used for sorting image data',menuSelectedFcn,@editSortingMetric);
UI.menu.display.redefineMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Change metrics used for t-SNE plot',menuSelectedFcn,@tSNE_redefineMetrics,'Accelerator','T');
UI.menu.display.flipXY = uimenu(UI.menu.display.topMenu,menuLabel,'Flip x and y axes in the custom group plot',menuSelectedFcn,@flipXY,'Separator','on');

% ACG
UI.menu.ACG.topMenu = uimenu(UI.fig,menuLabel,'ACG');
UI.menu.ACG.window.ops(1) = uimenu(UI.menu.ACG.topMenu,menuLabel,'30 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(2) = uimenu(UI.menu.ACG.topMenu,menuLabel,'100 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(3) = uimenu(UI.menu.ACG.topMenu,menuLabel,'1 sec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(4) = uimenu(UI.menu.ACG.topMenu,menuLabel,'Log10',menuSelectedFcn,@buttonACG);
UI.menu.ACG.logY = uimenu(UI.menu.ACG.topMenu,menuLabel,'Log y-axis',menuSelectedFcn,@toggleACG_ylog,'Separator','on');
% UI.menu.ACG.z_scored = uimenu(UI.menu.ACG.topMenu,menuLabel,'Z-scored',menuSelectedFcn,@toggleACG_zscored); % Not properly implemented
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
UI.menu.monoSyn.showConn.ops(strcmp(synConnectOptions,UI.preferences.monoSynDispIn)).Checked = 'on';
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
uimenu(UI.menu.referenceData.topMenu,menuLabel,'Explore reference data',menuSelectedFcn,@exploreReferenceData,'Separator','on');

% Ground truth
UI.menu.groundTruth.topMenu = uimenu(UI.fig,menuLabel,'Ground truth');
UI.menu.groundTruth.ops(1) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'No ground truth data',menuSelectedFcn,@showGroundTruthData,'Checked','on');
UI.menu.groundTruth.ops(2) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Image data',menuSelectedFcn,@showGroundTruthData);
UI.menu.groundTruth.ops(3) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Scatter data',menuSelectedFcn,@showGroundTruthData);
UI.menu.groundTruth.ops(4) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Histogram data',menuSelectedFcn,@showGroundTruthData);
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Open ground truth data dialog',menuSelectedFcn,@defineGroundTruthData,'Separator','on');
% uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Compare cell groups to ground truth cell types',menuSelectedFcn,@compareToReference,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Adjust bin count for reference and ground truth plots',menuSelectedFcn,@defineBinSize,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Show ground truth classification tab',menuSelectedFcn,@performGroundTruthClassification,'Accelerator','Y','Separator','on');
% uimenu(UI.menu.groupData.topMenu,menuLabel,'Show ground truth data in current session(s)',menuSelectedFcn,@loadGroundTruth,'Accelerator','U');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Save tagging to groundTruthData folder',menuSelectedFcn,@importGroundTruth);
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Explore groundTruth data',menuSelectedFcn,@exploreGroundTruth,'Separator','on');

% Group data
UI.menu.groupData.topMenu = uimenu(UI.fig,menuLabel,'Group tags');
UI.menu.display.defineGroupData = uimenu(UI.menu.groupData.topMenu,menuLabel,'Open group tags dialog',menuSelectedFcn,@defineGroupData,'Accelerator','G');
UI.menu.display.generateFilterbyGroupData = uimenu(UI.menu.groupData.topMenu,menuLabel,'Generate filter from group data',menuSelectedFcn,@generateFilterbyGroupData,'Separator','on');

% Table menu
UI.menu.tableData.topMenu = uimenu(UI.fig,menuLabel,'Table data');
UI.menu.tableData.ops(1) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell metrics',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(2) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(3) = uimenu(UI.menu.tableData.topMenu,menuLabel,'None',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.column1 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 1','Separator','on');
for m = 1:length(UI.params.tableDataSortingList)
    UI.menu.tableData.column1_ops(m) = uimenu(UI.menu.tableData.column1,menuLabel,UI.params.tableDataSortingList{m},menuSelectedFcn,@setColumn1_metric);
end
UI.menu.tableData.column1_ops(strcmp(UI.tableData.Column1,UI.params.tableDataSortingList)).Checked = 'on';

UI.menu.tableData.column2 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 2');
for m = 1:length(UI.params.tableDataSortingList)
    UI.menu.tableData.column2_ops(m) = uimenu(UI.menu.tableData.column2,menuLabel,UI.params.tableDataSortingList{m},menuSelectedFcn,@setColumn2_metric);
end
UI.menu.tableData.column2_ops(strcmp(UI.tableData.Column2,UI.params.tableDataSortingList)).Checked = 'on';

uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list sorting:','Separator','on');
for m = 1:length(UI.params.tableDataSortingList)
    UI.menu.tableData.sortingList(m) = uimenu(UI.menu.tableData.topMenu,menuLabel,UI.params.tableDataSortingList{m},menuSelectedFcn,@setTableDataSorting);
end
UI.menu.tableData.sortingList(strcmp(UI.tableData.SortBy,UI.params.tableDataSortingList)).Checked = 'on';

% Spikes
UI.menu.spikeData.topMenu = uimenu(UI.fig,menuLabel,'Spikes');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Open spike data dialog',menuSelectedFcn,@defineSpikesPlots,'Accelerator','A');

% Session
UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
uimenu(UI.menu.session.topMenu,menuLabel,'View metadata for current session',menuSelectedFcn,@viewSessionMetaData);
uimenu(UI.menu.session.topMenu,menuLabel,'Open directory of current session',menuSelectedFcn,@openSessionDirectory,'Accelerator','C','Separator','on');

% BuzLabDB
UI.menu.BuzLabDB.topMenu = uimenu(UI.fig,menuLabel,'BuzLabDB');
uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Load session(s) from BuzLabDB',menuSelectedFcn,@DatabaseSessionDialog,'Accelerator','D');
uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit repository paths',menuSelectedFcn,@editDBrepositories);
uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current session on website',menuSelectedFcn,@openSessionInWebDB,'Separator','on');
uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current animal subject on website',menuSelectedFcn,@showAnimalInWebDB);

% Help
UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
uimenu(UI.menu.help.topMenu,menuLabel,'Keyboard shortcuts',menuSelectedFcn,@HelpDialog,'Accelerator','H');
uimenu(UI.menu.help.topMenu,menuLabel,'CellExplorer website',menuSelectedFcn,@openWebsite,'Accelerator','V','Separator','on');
uimenu(UI.menu.help.topMenu,menuLabel,'Tutorials',menuSelectedFcn,@openWebsite,'Separator','on');
uimenu(UI.menu.help.topMenu,menuLabel,'Graphical interface',menuSelectedFcn,@openWebsite);
if UI.preferences.plotWaveformMetrics; UI.menu.display.showMetrics.Checked = 'on'; end

if strcmp(UI.preferences.acgType,'Normal')
    UI.menu.ACG.window.ops(2).Checked = 'On';
elseif strcmp(UI.preferences.acgType,'Wide')
    UI.menu.ACG.window.ops(1).Checked = 'On';
elseif strcmp(UI.preferences.acgType,'Log10')
    UI.menu.ACG.window.ops(4).Checked = 'On';
else
    UI.menu.ACG.window.ops(3).Checked = 'On';
end

% Save classification
if ~isempty(classificationTrackChanges)
    UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
end


%% % % % % % % % % % % % % % % % % % % % % %
% UI panels and basic UI elements
% % % % % % % % % % % % % % % % % % % % % %

% Flexib grid box for adjusting the width of the side panels
UI.HBox = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0);

% Left panel
UI.panel.left = uix.VBoxFlex('Parent',UI.HBox,'position',[0 0.66 0.26 0.31]);

% Elements in left panel
UI.textFilter = uicontrol('Style','edit','Units','normalized','Position',[0 0.973 1 0.024],'String','Filter','HorizontalAlignment','left','Parent',UI.panel.left,'Callback',@filterCellsByText,'tooltip',sprintf('Search across cell metrics\nString fields: "CA1" or "Interneuro"\nNumeric fields: ".firingRate > 10" or ".cv2 < 0.5" (==,>,<,~=) \nCombine with AND // OR operators (&,|) \nEaxmple: ".firingRate > 10 & CA1"\nFilter by parent brain regions as well, fx: ".brainRegion HIP"\nMake sure to include  spaces between fields and operators' ));
UI.panel.custom = uix.VBox('Position',[0 0.717 1 0.255],'Parent',UI.panel.left);
UI.panel.group = uix.VBox('Parent',UI.panel.left);
UI.panel.displaySettings = uix.VBox('Parent',UI.panel.left);
UI.panel.tabgroup2 = uitabgroup('Position',[0 0 1 0.162],'Units','normalized','SelectionChangedFcn',@updateLegends,'Parent',UI.panel.left);
set(UI.panel.left, 'Heights', [25 230 -100 -180 -90], 'Spacing', 8); % ,'MinimumHeights',[25 230 10 10 180]

% Vertical center box with the title at top, grid flex with plots as middle element and message log and bechmark text at bottom
UI.VBox = uix.VBox( 'Parent', UI.HBox, 'Spacing', 0, 'Padding', 0 );

% Title box
% UI.panel.centerTop = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);
% Title with details about the selected cell and current session
UI.title = uicontrol('Style','text','Units','normalized','Position',[0 0 1 1],'String',{'Cell details'},'HorizontalAlignment','center','FontSize',13,'Parent',UI.VBox);

% Grid Flex with plots
UI.panel.GridFlex = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);

% UI plot panels
UI.panel.subfig_ax(1) = uipanel('position',[0 0.67 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(2) = uipanel('position',[0.33 0.67 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(3) = uipanel('position',[0.67 0.67 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(4) = uipanel('position',[0 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(5) = uipanel('position',[0.33 0.33 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(6) = uipanel('position',[0.67 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(7) = uipanel('position',[0 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(8) = uipanel('position',[0.33 0 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax(9) = uipanel('position',[0.67 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);

% Right panel
UI.panel.right = uix.VBoxFlex('Parent',UI.HBox,'position',[0 0.66 0.26 0.31]);

% UI menu panels
UI.panel.navigation = uipanel('Title','Navigation','TitlePosition','centertop','Position',[0 0.927 1 0.065],'Units','normalized','Parent',UI.panel.right);
UI.panel.cellAssignment = uix.VBox('Position',[0 0.643 1 0.275],'Parent',UI.panel.right);
UI.panel.tabgroup1 = uitabgroup('Position',[0 0.493 1 0.142],'Units','normalized','Parent',UI.panel.right);

% Message log and performance
UI.panel.centerBottom = uix.HBox('Parent',UI.VBox);

% set VBox elements sizes
set( UI.HBox, 'Widths', [160 -1 160],'MinimumWidths',[80 1 80]);

% set HBox elements sizes
set( UI.VBox, 'Heights', [25 -1 25]);

subfig_ax(1) = axes('Parent',UI.panel.subfig_ax(1));
subfig_ax(2) = axes('Parent',UI.panel.subfig_ax(2));
subfig_ax(3) = axes('Parent',UI.panel.subfig_ax(3));
subfig_ax(4) = axes('Parent',UI.panel.subfig_ax(4));
subfig_ax(5) = axes('Parent',UI.panel.subfig_ax(5));
subfig_ax(6) = axes('Parent',UI.panel.subfig_ax(6));
subfig_ax(7) = axes('Parent',UI.panel.subfig_ax(7));
subfig_ax(8) = axes('Parent',UI.panel.subfig_ax(8));
subfig_ax(9) = axes('Parent',UI.panel.subfig_ax(9));

% % % % % % % % % % % % % % % % % % %
% Metrics table 
% % % % % % % % % % % % % % % % % % %

if verLessThan('matlab', '9.5')
    tooltip = 'TooltipString';
else
    tooltip = 'Tooltip';
end

% Table with metrics for selected cell
UI.table = uitable('Parent',UI.panel.right,'Data',[table_fieldsNames,table_metrics(:,1)],'Units','normalized','Position',[0 0.003 1 0.485],'ColumnWidth',{100,  100},'columnname',{'Metrics',''},'RowName',[],'CellSelectionCallback',@ClicktoSelectFromTable,'CellEditCallback',@EditSelectFromTable,'KeyPressFcn', {@keyPress},'tooltip',sprintf('Metrics for current cell. \nClick left column to select metric in custom group plot on x axis. \nClick right column to select metric in custom group plot on y axis  \nChange table data in Table data menu'));

set(UI.panel.right, 'Heights', [50 250 180 -1], 'Spacing', 8,'MinimumHeights',[50 20 20 20]);

if strcmp(UI.preferences.metricsTableType,'Metrics')
    UI.preferences.metricsTable=1;
    UI.menu.tableData.ops(1).Checked = 'On';
    UI.table.(tooltip) = sprintf('Metrics for current cell. \nClick left column to select metric in custom group plot on x axis. \nClick right column to select metric in custom group plot on y axis. \nChange table data in Table data menu');
elseif strcmp(UI.preferences.metricsTableType,'Cells')
    UI.preferences.metricsTable=2; UI.table.ColumnName = {'','#',UI.tableData.Column1,UI.tableData.Column2};
    UI.table.ColumnEditable = [true false false false];
    UI.table.(tooltip) = sprintf('List of filtered cells. \nClick any row to go to that cell. \nChange table data in Table data menu. \nYou can customize the order, and data shown in the two columns from the menu.');
    UI.menu.tableData.ops(2).Checked = 'On';
else
    UI.preferences.metricsTable=3; UI.table.Visible='Off';
    UI.menu.tableData.ops(3).Checked = 'On';
end

% % % % % % % % % % % % % % % % % % % %
% Message log and Benchmark            
% % % % % % % % % % % % % % % % % % % %
set( UI.VBox, 'Heights', [25 -1 25]);
UI.popupmenu.log = uicontrol('Style','popupmenu','Units','normalized','String',{'Welcome to CellExplorer. Press H for keyboard shortcuts and visit the website for tutorials and documentation.'},'HorizontalAlignment','left','FontSize',10,'Parent',UI.panel.centerBottom);
% Benchmark with display time in seconds for most recent plot call
UI.benchmark = uicontrol('Style','text','Units','normalized','String','Benchmark','HorizontalAlignment','left','FontSize',13,'ForegroundColor',[0.3 0.3 0.3],'Parent',UI.panel.centerBottom);
set(UI.panel.centerBottom, 'Widths', [-600 -300], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Navigation panel (right side)        
% % % % % % % % % % % % % % % % % % % %

% Navigation buttons
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0 0 0.33 1],'String',char(8592),'Callback',@back,'KeyPressFcn', {@keyPress},'tooltip','Go to previous cell (i-1)');
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0.34 0 0.33 1],'String','GoTo','Callback',@(src,evnt)goToCell,'KeyPressFcn', {@keyPress},'tooltip','Open a dialog to provide specific cell id');
UI.pushbutton.next = uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Units','normalized','Position',[0.67 0 0.33 1],'String',char(8594),'Callback',@advance,'KeyPressFcn', {@keyPress},'tooltip','Go to next cell (i+1)');

% % % % % % % % % % % % % % % % % % % %
% Cell assignments panel (right side)  
% % % % % % % % % % % % % % % % % % % %

% Cell classification
colored_string = DefineCellTypeList;
uicontrol('Parent',UI.panel.cellAssignment,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Cell classification','HorizontalAlignment','center');
UI.listbox.cellClassification = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[0 54 148 48],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType,'KeyPressFcn', {@keyPress},'tooltip','Cell type of current cell. Click to assign');

% Poly-select and action
UI.panel.buttonGroup0 = uix.HBox('Parent',UI.panel.cellAssignment);
uicontrol('Parent',UI.panel.buttonGroup0,'Style','pushbutton','Units','normalized','Position',[0 0 0.5 1],'String','O Polygon','Callback',@(src,evnt)polygonSelection,'KeyPressFcn', {@keyPress},'tooltip','Draw a polygon around cells to select them');
uicontrol('Parent',UI.panel.buttonGroup0,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.5 1],'String','Actions','Callback',@(src,evnt)selectCellsForGroupAction,'KeyPressFcn', {@keyPress},'tooltip','Perform group action on selected cells');

% Brain region
UI.pushbutton.brainRegion = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 20 145 15],'Units','normalized','String',['Region: ', cell_metrics.brainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyPressFcn', {@keyPress},'tooltip','Brain region of current cell. Click to assign');

% Custom labels
UI.pushbutton.labels = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 3 145 15],'Units','normalized','String',['Label: ', cell_metrics.labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyPressFcn', {@keyPress},'tooltip','Label of current cell. Click to assign');

set(UI.panel.cellAssignment, 'Heights', [15 -1 30 30 30], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Tab panel 1 (right side)             
% % % % % % % % % % % % % % % % % % % %

% UI cell assignment tabs
UI.tabs.tags = uitab(UI.panel.tabgroup1,'Title','Tags');
UI.tabs.deepsuperficial = uitab(UI.panel.tabgroup1,'Title','D/S');

% Deep/Superficial
UI.listbox.deepSuperficial = uicontrol('Parent',UI.tabs.deepsuperficial,'Style','listbox','Position',getpixelposition(UI.tabs.deepsuperficial),'Units','normalized','String',UI.preferences.deepSuperficial,'max',1,'min',1,'Value',cell_metrics.deepSuperficial_num(ii),'Callback',@(src,evnt)buttonDeepSuperficial,'KeyPressFcn', {@keyPress},'tooltip','Deep superficial assignment of current cell. Click to assign');

% Tags
buttonPosition = getButtonLayout(UI.tabs.tags,UI.preferences.tags,1);
for m = 1:length(UI.preferences.tags)
    UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String',UI.preferences.tags{m},'Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)buttonTags(m),'KeyPressFcn', {@keyPress});
end
m = length(UI.preferences.tags)+1;
UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String','+ tag','Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)addTag,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Custom plot panel (left side)        
% % % % % % % % % % % % % % % % % % % %

% Custom plot
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 10 45 10],'Units','normalized','String','Custom group plot style','HorizontalAlignment','center');
UI.popupmenu.metricsPlot = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 82 144 10],'Units','normalized','String',{'2D scatter plot','2D + Histograms','3D scatter plot','Raincloud plot'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)customPlotStyle,'KeyPressFcn', {@keyPress},'tooltip','Plot style of custom group plot');

% Custom plotting menues
UI.panel.buttonGroup1 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup1,'Style','text','Units','normalized','Position',[0.25 0 0.5 0.8],'String','  X data','HorizontalAlignment','left');
UI.checkbox.logx = uicontrol('Parent',UI.panel.buttonGroup1,'Style','checkbox','Units','normalized','Position',[0.5 0 0.5 1],'String','Log X','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotXLog(),'KeyPressFcn', {@keyPress},'tooltip','Toggle x axis linear/log');
UI.popupmenu.xData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 62 144 10],'Units','normalized','String',UI.lists.metrics,'Value',find(strcmp(UI.lists.metrics,UI.preferences.plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX(),'KeyPressFcn', {@keyPress},'tooltip','Metric data on x axis');
set(UI.panel.buttonGroup1, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup2 = uix.HBox('Parent',UI.panel.custom);                        
uicontrol('Parent',UI.panel.buttonGroup2,'Style','text','Position',[0.25 0 0.5 1],'Units','normalized','String','  Y data','HorizontalAlignment','left');
UI.checkbox.logy = uicontrol('Parent',UI.panel.buttonGroup2,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log Y','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotYLog(),'KeyPressFcn', {@keyPress},'tooltip','Toggle y axis linear/log');
UI.popupmenu.yData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 42 144 10],'Units','normalized','String',UI.lists.metrics,'Value',find(strcmp(UI.lists.metrics,UI.preferences.plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY(),'KeyPressFcn', {@keyPress},'tooltip','Metric data on y axis');
set(UI.panel.buttonGroup2, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup3 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup3,'Style','text','Position',[0.25 0 0.5 1],'Units','normalized','String','  Z data','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.checkbox.logz = uicontrol('Parent',UI.panel.buttonGroup3,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log Z','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotZLog(),'KeyPressFcn', {@keyPress},'tooltip','Toggle z axis linear/log');
UI.popupmenu.zData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 22 144 10],'Units','normalized','String',UI.lists.metrics,'Value',find(strcmp(UI.lists.metrics,UI.preferences.plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ(),'KeyPressFcn', {@keyPress},'tooltip','Metric data on z axis');
UI.popupmenu.zData.Enable = 'Off'; UI.checkbox.logz.Enable = 'Off';
set(UI.panel.buttonGroup3, 'Widths', [-1 70], 'Spacing', 5);

UI.panel.buttonGroup4 = uix.HBox('Parent',UI.panel.custom);
uicontrol('Parent',UI.panel.buttonGroup4,'Style','text','Position',[0.25 0 0.5 1],'Units','normalized','String','  Marker size','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.checkbox.logMarkerSize = uicontrol('Parent',UI.panel.buttonGroup4,'Style','checkbox','Position',[0.5 0 0.5 1],'Units','normalized','String','Log size','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotMarkerSizeLog(),'KeyPressFcn', {@keyPress},'tooltip','Toggle marker size linear/log');
UI.popupmenu.markerSizeData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 2 144 10],'Units','normalized','String',UI.lists.metrics,'Value',find(strcmp(UI.lists.metrics,UI.preferences.plotMarkerSizedata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotMarkerSize(),'KeyPressFcn', {@keyPress},'tooltip','Metric data for marker size');
UI.popupmenu.markerSizeData.Enable = 'Off'; UI.checkbox.logMarkerSize.Enable = 'Off';
set(UI.panel.buttonGroup4, 'Widths', [-1 70], 'Spacing', 5);
set(UI.panel.custom, 'Heights', [15 20 15 20 15 20 15 20 15 25], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Custom colors
% % % % % % % % % % % % % % % % % % % %'
uicontrol('Parent',UI.panel.group,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Group data & filters','HorizontalAlignment','center');
UI.popupmenu.groups = uicontrol('Parent',UI.panel.group,'Style','popupmenu','Position',[2 73 144 10],'Units','normalized','String',colorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(1),'KeyPressFcn', {@keyPress},'tooltip','Filter and select group data');
updateColorMenuCount
UI.listbox.groups = uicontrol('Parent',UI.panel.group,'Style','listbox','Position',[0 20 148 54],'Units','normalized','String',{},'max',100,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyPressFcn', {@keyPress},'Enable','Off','tooltip','Group data');
uicontrol('Parent',UI.panel.group,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Color groups','HorizontalAlignment','center');
UI.popupmenu.colors = uicontrol('Parent',UI.panel.group,'Style','popupmenu','Position',[2 10 144 10],'Units','normalized','String',{'By group data','By cell types','Single group','Compare to other','By higher brain region'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress},'tooltip','Select color data');
set(UI.panel.group, 'Heights', [15 20 -1 15 25], 'Spacing', 5);

% % % % % % % % % % % % % % % % % % % %
% Display settings panel (left side)
% % % % % % % % % % % % % % % % % % % %
% Select subset of cell type
updateCellCount
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Display settings','HorizontalAlignment','center');
UI.listbox.cellTypes = uicontrol('Parent',UI.panel.displaySettings,'Style','listbox','Position',[0 73 148 48],'Units','normalized','String',strcat(UI.preferences.cellTypes,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(UI.preferences.cellTypes),'Callback',@(src,evnt)buttonSelectSubset(),'KeyPressFcn', {@keyPress},'tooltip','Displayed putative cell types. Select to filter');

% Number of plots
UI.panel.buttonGroup5 = uix.HBox('Parent',UI.panel.displaySettings);
uicontrol('Parent',UI.panel.buttonGroup5,'Style','text','Position',[0 0 0.3 1],'Units','normalized','String','Layout','HorizontalAlignment','center');
UI.popupmenu.plotCount = uicontrol('Parent',UI.panel.buttonGroup5,'Style','popupmenu','Position',[0.3 0 0.7 1],'Units','normalized','String',{'GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6','GUI 1+6'},'max',1,'min',1,'Value',3,'Callback',@(src,evnt)AdjustGUIbutton,'KeyPressFcn', {@keyPress},'tooltip','Select the GUI layout');
set(UI.panel.buttonGroup5, 'Widths', [45 -1], 'Spacing', 5);

for i_disp = 1:6
    UI.panel.buttonGroupView{i_disp} = uix.HBox('Parent',UI.panel.displaySettings);
    uicontrol('Parent',UI.panel.buttonGroupView{i_disp},'Style','text','String',num2str(i_disp),'HorizontalAlignment','center');
    UI.popupmenu.customplot{i_disp} = uicontrol('Parent',UI.panel.buttonGroupView{i_disp},'Style','popupmenu','String',plotOptions,'max',1,'min',1,'Value',1,'Callback',@toggleWaveformsPlot,'KeyPressFcn', {@keyPress},'tooltip','Single cell plot');
    set(UI.panel.buttonGroupView{i_disp}, 'Widths', [15 -1], 'Spacing', 2);
    if any(strcmp(UI.preferences.customCellPlotIn{i_disp},UI.popupmenu.customplot{i_disp}.String)); UI.popupmenu.customplot{i_disp}.Value = find(strcmp(UI.preferences.customCellPlotIn{i_disp},UI.popupmenu.customplot{i_disp}.String)); else; UI.popupmenu.customplot{i_disp}.Value = 1; end
    UI.preferences.customPlot{i_disp} = plotOptions{UI.popupmenu.customplot{i_disp}.Value};
end
set(UI.panel.displaySettings, 'Heights', [15 -1 22 22 22 22 22 22 25], 'Spacing', 3);
if find(strcmp(UI.preferences.plotCountIn,UI.popupmenu.plotCount.String)); UI.popupmenu.plotCount.Value = find(strcmp(UI.preferences.plotCountIn,UI.popupmenu.plotCount.String)); else; UI.popupmenu.plotCount.Value = 3; end; AdjustGUIbutton

% % % % % % % % % % % % % % % % % % % %
% Tab panel 2 (left side)
% % % % % % % % % % % % % % % % % % % %

% UI display settings tabs
UI.tabs.legends =        uitab(UI.panel.tabgroup2,'Title','Legend','tooltip',sprintf('Legend for plots. \nClick to show legends in separate figure'));
UI.tabs.dispTags_minus = uitab(UI.panel.tabgroup2,'Title','-Tags','tooltip',sprintf('Cell tags. \nHide cells with one or more specific tags'));
UI.tabs.dispTags_plus =  uitab(UI.panel.tabgroup2,'Title','+Tags','tooltip',sprintf('Cell tags. \nFilter cells with one or more specific tags'));
UI.axis.legends = axes(UI.tabs.legends,'Position',[0 0 1 1]);
set(UI.axis.legends,'ButtonDownFcn',@createLegend)

% Display settings for tags_minus
buttonPosition = getButtonLayout(UI.tabs.dispTags_minus,UI.preferences.tags,0);
for m = 1:length(UI.preferences.tags)
    UI.togglebutton.dispTags(m) = uicontrol('Parent',UI.tabs.dispTags_minus,'Style','togglebutton','String',UI.preferences.tags{m},'Units','normalized','Position',buttonPosition{m},'Value',0,'Callback',@(src,evnt)buttonTags_minus(m),'KeyPressFcn', {@keyPress});
end

% Display settings for tags_plus
for m = 1:length(UI.preferences.tags)
    UI.togglebutton.dispTags2(m) = uicontrol('Parent',UI.tabs.dispTags_plus,'Style','togglebutton','String',UI.preferences.tags{m},'Units','normalized','Position',buttonPosition{m},'Value',0,'Callback',@(src,evnt)buttonTags_plus(m),'KeyPressFcn', {@keyPress});
end

set(UI.panel.left, 'MinimumHeights',[25 230 10 10 50]);

% Creates summary figures and closes the UI
if summaryFigures
    MsgLog('Generating summary figures',-1)
    UI.params.subset = 1:length(cell_metrics.cellID);
    plotSummaryFigures
%     if ishandle(fig) & plotCellIDs ~= -1
%         close(fig)
%     end
    if ishandle(UI.fig)
        close(UI.fig)
    end
    MsgLog('Summary figure(s) generated. Saved to /summaryFigures',-1)
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
DragMouseBegin
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
trackGoogleAnalytics('CellExplorer',CellExplorerVersion,'metrics',cell_metrics); % Anonymous tracking of usage
cell_metrics = saveCellMetricsStruct(cell_metrics);


%% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

function updateUI
    
    timerInterface = tic;
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
    if ~UI.preferences.stickySelection
        UI.params.ClickedCells = [];
    end
    
    % Resetting polygon selection
    clickPlotRegular = true;
    
    % Resetting zoom levels for subplots
    UI.zoom.global = cell(1,10);
    UI.zoom.globalLog = cell(1,10);
    UI.drag.mouse = false;
    
    % Updating cell specific fields
    UI.listbox.deepSuperficial.Value = cell_metrics.deepSuperficial_num(ii);
    UI.pushbutton.brainRegion.String = ['Region: ', cell_metrics.brainRegion{ii}];
    UI.pushbutton.labels.String = ['Label: ', cell_metrics.labels{ii}];
    
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

    % Rotation of common coordinate framework
    if any(strcmp(UI.preferences.customPlot,'Common Coordinate Framework'))
        idx = find(strcmp(UI.preferences.customPlot,'Common Coordinate Framework'));
        [ccf_ratio1(1),ccf_ratio1(2)] = view(subfig_ax(idx+3));
        if all(ccf_ratio1 ~= [0,90])
            ccf_ratio = ccf_ratio1;
        end
    end
    
    % Group data
    % Filters tagged cells ('tags','groups','groundTruthClassification')
    if ~isempty(UI.groupData1)
        dataTypes = {'tags','groups','groundTruthClassification'};
        filter_pos = [];
        filter_neg = [];
        for jjj = 1:numel(dataTypes)
            if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'plus_filter') && any(struct2array(UI.groupData1.(dataTypes{jjj}).plus_filter))
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'plus_filter')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).plus_filter);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).plus_filter.(fields1{jj}) == 1 && isfield(cell_metrics.(dataTypes{jjj}),fields1{jj})  && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj}))
                            filter_pos = [filter_pos,cell_metrics.(dataTypes{jjj}).(fields1{jj})];
                        end
                    end
                end
            end
            if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'minus_filter') && any(struct2array(UI.groupData1.(dataTypes{jjj}).minus_filter))
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'minus_filter')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).minus_filter);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).minus_filter.(fields1{jj}) == 1 && isfield(cell_metrics.(dataTypes{jjj}),fields1{jj}) && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj}))
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
    
    if ~isempty(groups2plot2) && GroupVal >1
        if ColorVal ~= 2
            subset2 = find(ismember(UI.classes.plot11,groups2plot2));
            UI.classes.plot = UI.classes.plot11;
        else
            subset2 = find(ismember(UI.classes.plot2,groups2plot2));
        end
        UI.params.subset = intersect(UI.params.subset,subset2);
    end
    
    % text filter
    if ~isempty(idx_textFilter)
        UI.params.subset = intersect(UI.params.subset,idx_textFilter);
    end
    [~,UI.preferences.troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
    
    % Regrouping cells if comparison checkbox is checked
    if ColorVal == 5 % major brain regions 
        if ~isfield(UI.params,'brainRegionsLevel') | ~isfield(UI.params,'subset_pre') | numel(UI.params.subset) ~= numel(UI.params.subset_pre) | UI.params.subset ~= UI.params.subset_pre
            if isempty(UI.brainRegions.relational_tree)
                temp = load('brainRegions_relational_tree.mat','relational_tree');
                UI.brainRegions.relational_tree = temp.relational_tree;
            end
            kk = 1;
            idx = find(UI.brainRegions.relational_tree.graph_depth == UI.preferences.graph_depth);
            brainRegionsLevel1 = UI.brainRegions.relational_tree.acronyms(idx);
            UI.params.brainRegionsLevel = {};
            UI.classes.plotBrainRegions = ones(1,length(UI.classes.plot));
            for i = 1:numel(brainRegionsLevel1)
                acronym_out = getBrainRegionChildren(brainRegionsLevel1{i},UI.brainRegions.relational_tree);
                idx2 = ismember(lower(cell_metrics.brainRegion(UI.params.subset)),lower([acronym_out,brainRegionsLevel1{i}]));
                if any(idx2)
                    UI.classes.plotBrainRegions(UI.params.subset(idx2)) = kk;
                    UI.params.brainRegionsLevel{kk} = brainRegionsLevel1{i};
                    kk = kk + 1;
                end
            end
        end
        classes2plotSubset = unique(UI.classes.plot(UI.params.subset));
        UI.classes.plot = UI.classes.plotBrainRegions;
        UI.classes.labels = UI.params.brainRegionsLevel(unique(UI.classes.plot(UI.params.subset)));
        UI.params.subset_pre = UI.params.subset;
    elseif ColorVal == 4 % Compare to rest
        UI.classes.plot = ones(1,length(UI.classes.plot));
        UI.classes.plot(UI.params.subset) = 2;
        UI.params.subset = 1:length(UI.classes.plot);
        classes2plotSubset = unique(UI.classes.plot);
        UI.classes.labels = {'Other cells','Selected cells'};
    elseif ColorVal == 3 % Single group
        UI.classes.plot(1:numel(UI.classes.plot)) = 1;
        classes2plotSubset = unique(UI.classes.plot);
        UI.classes.labels = {'Selected cells'};
    elseif ColorVal == 2 % Cell type color groups
        classes2plotSubset = intersect(UI.classes.plot(UI.params.subset),classes2plot);
    elseif ColorVal == 1  % Regular grouping
        if GroupVal == 1
            groups2plot = classes2plot;
            classes2plotSubset = unique(UI.classes.plot);
        end
        classes2plotSubset = intersect(UI.classes.plot(UI.params.subset),groups2plot);
    end
    
    % Defining synaptic connections
    UI = defineSynapticConnections(UI);
    
    % Defining synaptically identified projecting cell
    if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory)
        UI.cells.excitatory_subset = intersect(UI.params.subset,UI.cells.excitatory);
    else
        UI.cells.excitatory_subset = [];
    end
    if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory)
        UI.cells.inhibitory_subset = intersect(UI.params.subset,UI.cells.inhibitory);
    else
        UI.cells.inhibitory_subset = [];
    end
    if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic)
        UI.cells.excitatoryPostsynaptic_subset = intersect(UI.params.subset,UI.cells.excitatoryPostsynaptic);
    else
        UI.cells.excitatoryPostsynaptic_subset = [];
    end
    if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic)
        UI.cells.inhibitoryPostsynaptic_subset = intersect(UI.params.subset,UI.cells.inhibitoryPostsynaptic);
    else
        UI.cells.inhibitoryPostsynaptic_subset = [];
    end
    
    % Group display definition
    if ColorVal > 2 && ColorVal < 5
        UI.classes.colors = UI.preferences.cellTypeColors(intersect(classes2plotSubset,UI.classes.plot(UI.params.subset)),:);
    elseif  ColorVal == 2 || (GroupVal == 1 && ColorVal < 5)
        UI.classes.colors = UI.preferences.cellTypeColors(intersect(classes2plot,UI.classes.plot(UI.params.subset)),:);
    else
        UI.classes.colors = hsv(length(nanUnique(UI.classes.plot(UI.params.subset))))*0.8;
        if isnan(UI.classes.colors)
            UI.classes.colors = UI.preferences.cellTypeColors(1,:);
        end
    end
    % Ground truth and reference data colors
    if ~strcmp(UI.preferences.referenceData, 'None')
        UI.classes.colors2 = UI.preferences.cellTypeColors(intersect(referenceData.clusClas,referenceData.selection),:);
    end
    if ~strcmp(UI.preferences.groundTruthData, 'None')
        UI.classes.colors3 = UI.preferences.groundTruthColors(intersect(groundTruthData.clusClas,groundTruthData.selection),:);
    end
    
    % Updating table for selected cell
    updateTableColumnWidth
    if UI.preferences.metricsTable==1
        UI.table.Data(:,2) = table_metrics(:,ii);
    elseif UI.preferences.metricsTable==2
        updateCellTableData;
    end
    
    % Updating title
    if isfield(cell_metrics,'sessionName') && isfield(cell_metrics.general,'batch')
        UI.title.String = ['Cell class: ', UI.preferences.cellTypes{clusClas(ii)},', ' , num2str(ii),'/', num2str(cell_metrics.general.cellCount),' (batch ',num2str(batchIDs),'/',num2str(length(cell_metrics.general.batch)),') - UID: ', num2str(cell_metrics.UID(ii)),'/',num2str(general.cellCount),', electrode group: ', num2str(cell_metrics.electrodeGroup(ii)),', session: ', cell_metrics.sessionName{ii},',  animal: ',cell_metrics.animal{ii}];
    else
        UI.title.String = ['Cell Class: ', UI.preferences.cellTypes{clusClas(ii)},', ', num2str(ii),'/', num2str(cell_metrics.general.cellCount),'  - electrode group: ', num2str(cell_metrics.electrodeGroup(ii))];
    end
    
    % Enabling axes panning
    UI.drag.pan.Enable = 'on';
    enableInteractions
    UI.pan.allow = true(1,9);

    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    
    if any(UI.preferences.customPlotHistograms == [1,3,4])
        if size(UI.panel.subfig_ax(1).Children,1) > 1
            set(UI.fig,'CurrentAxes',UI.panel.subfig_ax(1).Children(2))
        else
            set(UI.fig,'CurrentAxes',UI.panel.subfig_ax(1).Children)
        end
        % Saving current view activated for previous cell
        [az,el] = view;
    end

    % Deletes all children from the panel
    delete(UI.panel.subfig_ax(1).Children)
    
    % Creating new chield
    subfig_ax(1) = axes('Parent',UI.panel.subfig_ax(1));
    
    
    % % % % % Regular plot with/without histograms
    
    if any(UI.preferences.customPlotHistograms == [1,2])
        if UI.preferences.customPlotHistograms == 2 || strcmp(UI.preferences.referenceData, 'Histogram') || strcmp(UI.preferences.groundTruthData, 'Histogram')
            % Double kernel-histogram with scatter plot
            clear h_scatter
            set(subfig_ax(1),'Position', [0.30 0.30 0.685 0.675]);
            h_scatter(2) = axes('Parent',UI.panel.subfig_ax(1),'Position', [0.30 0.01 0.685 0.2], 'visible', 'on','Xticklabels',[]);
            h_scatter(3) = axes('Parent',UI.panel.subfig_ax(1),'Position', [0.01 0.30 0.2 0.675], 'visible', 'on','Xticklabels',[]);
            h_scatter(2).YLabel.String = UI.preferences.rainCloudNormalization;
            h_scatter(3).YLabel.String = UI.preferences.rainCloudNormalization;
            hold([subfig_ax(1) h_scatter(2) h_scatter(3)],'on')
            set(UI.fig,'CurrentAxes',subfig_ax(1))
%             h_scatter(2) = subplot(4,4,16); hold on % x axis
%             h_scatter(2).Position = [0.30 0 0.685 0.21];
%             h_scatter(3) = subplot(4,4,1); hold on % y axis
%             h_scatter(3).Position = [0 0.30 0.21 0.675];
%             subfig_ax(1) = subplot(4,4,4); hold on
%             subfig_ax(1).Position = [0.30 0.30 0.685 0.675];
            view(h_scatter(3),[90 -90])
%             set(h_scatter(2), 'visible', 'off');
%             set(h_scatter(3), 'visible', 'off');
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

        if ((strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.preferences.groundTruthData, 'Image')) && ~isempty(groundTruth_cell_metrics)) && UI.checkbox.logy.Value == 1
            yyaxis right, hold on
            subfig_ax(1).YAxis(1).Color = 'k'; 
            subfig_ax(1).YAxis(2).Color = 'k';
        end
        hold on
        subfig_ax(1).YLabel.String = UI.labels.(UI.plot.yTitle); subfig_ax(1).YLabel.Interpreter = 'tex';
        subfig_ax(1).XLabel.String = UI.labels.(UI.plot.xTitle); subfig_ax(1).XLabel.Interpreter = 'tex';
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
        
        % % % % % 2D plot

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
        if strcmp(UI.preferences.referenceData, 'Points') && ~isempty(reference_cell_metrics) && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            ce_gscatter(reference_cell_metrics.(UI.plot.xTitle)(idx), reference_cell_metrics.(UI.plot.yTitle)(idx), referenceData.clusClas(idx), UI.classes.colors2,8,'x');
        elseif strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            if ~exist('referenceData1','var') || ~isfield(referenceData1,'z') || ~strcmp(referenceData1.x_field,UI.plot.xTitle) || ~strcmp(referenceData1.y_field,UI.plot.yTitle) || referenceData1.x_log ~= UI.checkbox.logx.Value || referenceData1.y_log ~= UI.checkbox.logy.Value || ~strcmp(referenceData1.plotType, 'Image')
                if UI.checkbox.logx.Value == 1
                    referenceData1.x = linspace(log10(nanmin([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(1)])),log10(nanmax([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(2)])),UI.preferences.binCount);
                    xdata = log10(reference_cell_metrics.(UI.plot.xTitle));
                else
                    referenceData1.x = linspace(nanmin([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(1)]),nanmax([reference_cell_metrics.(UI.plot.xTitle),fig1_axislimit_x(2)]),UI.preferences.binCount);
                    xdata = reference_cell_metrics.(UI.plot.xTitle);
                end
                if UI.checkbox.logy.Value == 1
                    AA = reference_cell_metrics.(UI.plot.yTitle);
                    AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                    referenceData1.y = linspace(log10(nanmin([AA,fig1_axislimit_y(1)])),log10(nanmax([AA,fig1_axislimit_y(2)])),UI.preferences.binCount);
                    ydata = log10(reference_cell_metrics.(UI.plot.yTitle));
                else
                    AA = reference_cell_metrics.(UI.plot.yTitle);
                    AA = AA( ~isnan(AA) & ~isinf(AA));
                    referenceData1.y = linspace(nanmin([AA,fig1_axislimit_y(1)]),nanmax([AA,fig1_axislimit_y(2)]),UI.preferences.binCount);
                    ydata = reference_cell_metrics.(UI.plot.yTitle);
                end
                referenceData1.x_field = UI.plot.xTitle;
                referenceData1.y_field = UI.plot.yTitle;
                referenceData1.x_log = UI.checkbox.logx.Value;
                referenceData1.y_log = UI.checkbox.logy.Value;
                referenceData1.plotType = 'Image';
                colors = (1-(UI.preferences.cellTypeColors)) * 250;
                referenceData1.z = zeros(length(referenceData1.x)-1,length(referenceData1.y)-1,3,size(colors,1));
                for m = referenceData.selection
                    idx = find(referenceData.clusClas==m);
                    [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),referenceData1.x,referenceData1.y,'norm','probability');
                    referenceData1.z(:,:,:,m) = bsxfun(@times,repmat(conv2(z_referenceData_temp,gauss2d,'same'),1,1,3),reshape(colors(m,:),1,1,[]));
                end
                referenceData1.x = referenceData1.x(1:end-1)+(referenceData1.x(2)-referenceData1.x(1))/2;
                referenceData1.y = referenceData1.y(1:end-1)+(referenceData1.y(2)-referenceData1.y(1))/2;
            end
            if strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logy.Value == 1
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
            if strcmp(UI.preferences.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics) && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
                idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
                ce_gscatter(groundTruth_cell_metrics.(UI.plot.xTitle)(idx), groundTruth_cell_metrics.(UI.plot.yTitle)(idx), groundTruthData.clusClas(idx), UI.classes.colors3,8,UI.preferences.groundTruthMarker);
            elseif strcmp(UI.preferences.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
                if ~exist('groundTruthData1','var') || ~isfield(groundTruthData1,'z') || ~strcmp(groundTruthData1.x_field,UI.plot.xTitle) || ~strcmp(groundTruthData1.y_field,UI.plot.yTitle) || groundTruthData1.x_log ~= UI.checkbox.logx.Value || groundTruthData1.y_log ~= UI.checkbox.logy.Value
                    
                    if UI.checkbox.logx.Value == 1
                        groundTruthData1.x = linspace(log10(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)])),log10(nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)])),UI.preferences.binCount);
                        xdata = log10(groundTruth_cell_metrics.(UI.plot.xTitle));
                    else
                        groundTruthData1.x = linspace(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)]),nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)]),UI.preferences.binCount);
                        xdata = groundTruth_cell_metrics.(UI.plot.xTitle);
                    end
                    if UI.checkbox.logy.Value == 1
                        groundTruthData1.y = linspace(log10(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)])),log10(nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)])),UI.preferences.binCount);
                        ydata = log10(groundTruth_cell_metrics.(UI.plot.yTitle));
                    else
                        groundTruthData1.y = linspace(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)]),nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)]),UI.preferences.binCount);
                        ydata = groundTruth_cell_metrics.(UI.plot.yTitle);
                    end
                    
                    groundTruthData1.x_field = UI.plot.xTitle;
                    groundTruthData1.y_field = UI.plot.yTitle;
                    groundTruthData1.x_log = UI.checkbox.logx.Value;
                    groundTruthData1.y_log = UI.checkbox.logy.Value;
                    
                    colors = (1-(UI.preferences.groundTruthColors)) * 250;
                    groundTruthData1.z = zeros(length(groundTruthData1.x)-1,length(groundTruthData1.y)-1,3,size(colors,1));
                    for m = unique(groundTruthData.clusClas)
                        idx = find(groundTruthData.clusClas==m);
                        [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),groundTruthData1.x,groundTruthData1.y,'norm','probability');
                        groundTruthData1.z(:,:,:,m) = bsxfun(@times,repmat(conv2(z_referenceData_temp,gauss2d,'same'),1,1,3),reshape(colors(m,:),1,1,[]));
                    end
                    groundTruthData1.x = groundTruthData1.x(1:end-1)+(groundTruthData1.x(2)-groundTruthData1.x(1))/2;
                    groundTruthData1.y = groundTruthData1.y(1:end-1)+(groundTruthData1.y(2)-groundTruthData1.y(1))/2;
                end
                if strcmp(UI.preferences.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logy.Value == 1
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
                if strcmp(UI.preferences.referenceData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logy.Value == 1
                    yyaxis right, hold on
                end
            end
            plotGroupData(plotX,plotY,plotConnections(1),1)
            
            if UI.preferences.plotLinearFits
                plotLinearFits(plotX,plotY)
            end
            
            % Axes limits
            if ~strcmp(UI.preferences.groundTruthData, 'None')
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
            
            if ~strcmp(UI.preferences.referenceData, 'None')
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
                xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),
                xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5001]),
%                 subfig_ax(1).XLabel.String = UI.plot.xTitle(1:end-4);
                subfig_ax(1).XLabel.Interpreter = 'none';
            end
            if contains(UI.plot.yTitle,'_num')
                yticks([1:length(groups_ids.(UI.plot.yTitle))]), yticklabels(groups_ids.(UI.plot.yTitle)),ytickangle(65),
                ylim([0.5,length(groups_ids.(UI.plot.yTitle))+0.5001]),
%                 subfig_ax(1).YLabel.String = UI.plot.yTitle(1:end-4); 
                subfig_ax(1).YLabel.Interpreter = 'none';
            end
            if length(unique(UI.classes.plot(UI.params.subset)))==2
%                 G1 = plotX(UI.params.subset);
                G = findgroups(UI.classes.plot(UI.params.subset));
                if ~isempty(UI.params.subset(G==1)) && ~isempty(UI.params.subset(G==2))
                    if ~all(plotX(UI.params.subset(G==1))) && ~all(plotX(UI.params.subset(G==2)))
                        [h,p] = kstest2(plotX(UI.params.subset(G==1)),plotX(UI.params.subset(G==2)));
                        text(0.97,0.02,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90,'Interpreter', 'none','Interpreter', 'none','HitTest','off','BackgroundColor',[1 1 1 0.7],'margin',0.5)
                    end
                    if ~all(plotY(UI.params.subset(G==1))) && ~all(plotY(UI.params.subset(G==2)))
                        [h,p] = kstest2(plotY(UI.params.subset(G==1)),plotY(UI.params.subset(G==2)));
                        text(0.02,0.97,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Interpreter', 'none','Interpreter', 'none','HitTest','off','BackgroundColor',[1 1 1 0.7],'margin',0.5)
                    end
                end
            end
            [az,el] = view;
            if strcmp(UI.preferences.groundTruthData, 'None') && ~strcmp(UI.preferences.referenceData, 'None')
                xlim([min(fig1_axislimit_x(1),fig1_axislimit_x_reference(1)),max(fig1_axislimit_x(2),fig1_axislimit_x_reference(2))])
                ylim([min(fig1_axislimit_y(1),fig1_axislimit_y_reference(1)),max(fig1_axislimit_y(2),fig1_axislimit_y_reference(2))])
            elseif ~strcmp(UI.preferences.groundTruthData, 'None') && strcmp(UI.preferences.referenceData, 'None') && ~isempty(fig1_axislimit_x_groundTruth) && ~isempty(fig1_axislimit_y_groundTruth)
                xlim([min(fig1_axislimit_x(1),fig1_axislimit_x_groundTruth(1)),max(fig1_axislimit_x(2),fig1_axislimit_x_groundTruth(2))])
                ylim([min(fig1_axislimit_y(1),fig1_axislimit_y_groundTruth(1)),max(fig1_axislimit_y(2),fig1_axislimit_y_groundTruth(2))])
            elseif ~strcmp(UI.preferences.groundTruthData, 'None') && ~strcmp(UI.preferences.referenceData, 'None')
                xlim([min([fig1_axislimit_x(1),fig1_axislimit_x_groundTruth(1),fig1_axislimit_x_reference(1)]),max([fig1_axislimit_x(2),fig1_axislimit_x_groundTruth(2),fig1_axislimit_x_reference(2)])])
                ylim([min([fig1_axislimit_y(1),fig1_axislimit_y_groundTruth(1),fig1_axislimit_y_reference(1)]),max([fig1_axislimit_y(2),fig1_axislimit_y_groundTruth(2),fig1_axislimit_y_reference(2)])])
            else
                xlim(fig1_axislimit_x), ylim(fig1_axislimit_y)
            end
            xlim11 = xlim;
            ylim11 = ylim;
            
        if UI.preferences.customPlotHistograms == 2
            plotClas_subset = UI.classes.plot(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            ids_count = histc(plotClas_subset, ids);
            
    
            for m = 1:length(unique(UI.classes.plot(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                if length(temp1)>1
                    densityPlot(plotX(temp1),h_scatter(2),UI.classes.colors(m,:),UI.classes.colors(m,:),UI.checkbox.logx.Value)
                end
            end
            if UI.preferences.plotLinearFits
                plotLinearFits(plotX,plotY)
            end
            xlim(h_scatter(2), xlim11)
            
            for m = 1:length(unique(UI.classes.plot(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                if length(temp1)>1
                    densityPlot(plotY(temp1),h_scatter(3),UI.classes.colors(m,:),UI.classes.colors(m,:),UI.checkbox.logy.Value)
                end
            end
            xlim(h_scatter(3),ylim11)
        end
        if strcmp(UI.preferences.groundTruthData, 'Histogram') && ~isempty(groundTruth_cell_metrics) && isfield(groundTruth_cell_metrics,UI.plot.xTitle) && isfield(groundTruth_cell_metrics,UI.plot.yTitle)
            
            groundTruthData1.x = densityPlotRefData(groundTruth_cell_metrics.(UI.plot.xTitle),h_scatter(2),num2cell(UI.classes.colors3,2),UI.checkbox.logx.Value,xlim11,groundTruthData);
            groundTruthData1.x_field = UI.plot.xTitle;
            groundTruthData1.x_log = UI.checkbox.logx.Value;
                
            groundTruthData1.y = densityPlotRefData(groundTruth_cell_metrics.(UI.plot.yTitle),h_scatter(3),num2cell(UI.classes.colors3,2),UI.checkbox.logy.Value,ylim11,groundTruthData);
            groundTruthData1.y_field = UI.plot.yTitle;
            groundTruthData1.y_log = UI.checkbox.logy.Value;
            
            xlim11 = xlim;
            ylim11 = ylim;
            
%             
%                 if UI.checkbox.logx.Value == 1
%                     groundTruthData1.x = linspace(log10(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)])),log10(nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)])),UI.preferences.binCount);
%                     xdata = log10(groundTruth_cell_metrics.(UI.plot.xTitle));
%                 else
%                     groundTruthData1.x = linspace(nanmin([fig1_axislimit_x(1),groundTruth_cell_metrics.(UI.plot.xTitle)]),nanmax([fig1_axislimit_x(2),groundTruth_cell_metrics.(UI.plot.xTitle)]),UI.preferences.binCount);
%                     xdata = groundTruth_cell_metrics.(UI.plot.xTitle);
%                 end
%                 if UI.checkbox.logy.Value == 1
%                     groundTruthData1.y = linspace(log10(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)])),log10(nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)])),UI.preferences.binCount);
%                     ydata = log10(groundTruth_cell_metrics.(UI.plot.yTitle));
%                 else
%                     groundTruthData1.y = linspace(nanmin([fig1_axislimit_y(1),groundTruth_cell_metrics.(UI.plot.yTitle)]),nanmax([fig1_axislimit_y(2),groundTruth_cell_metrics.(UI.plot.yTitle)]),UI.preferences.binCount);
%                     ydata = groundTruth_cell_metrics.(UI.plot.yTitle);
%                 end
%                 groundTruthData1.x_field = UI.plot.xTitle;
%                 groundTruthData1.y_field = UI.plot.yTitle;
%                 groundTruthData1.x_log = UI.checkbox.logx.Value;
%                 groundTruthData1.y_log = UI.checkbox.logy.Value;

%                 idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
%                 clusClas_list = unique(groundTruthData.clusClas(idx));
%                 line_histograms_X = []; line_histograms_Y = [];
%                 
%                 if ~any(isnan(groundTruthData1.y)) || ~any(isinf(groundTruthData1.y))
%                     for m = 1:length(clusClas_list)
%                         idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
%                         line_histograms_X(:,m) = ksdensity(xdata(idx(idx1)),groundTruthData1.x);
%                     end
%                     if UI.checkbox.logx.Value == 0
%                         legendScatter2 = line(groundTruthData1.x,line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
%                     else
%                         legendScatter2 = line(10.^(groundTruthData1.x),line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
%                     end
%                     set(legendScatter2, {'color'}, num2cell(UI.classes.colors3,2));
%                 end
%                 
%                 if ~any(isnan(groundTruthData1.y)) || ~any(isinf(groundTruthData1.y))
%                     for m = 1:length(clusClas_list)
%                         idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
%                         line_histograms_Y(:,m) = ksdensity(ydata(idx(idx1)),groundTruthData1.y);
%                     end
%                     if UI.checkbox.logy.Value == 0
%                         legendScatter22 = line(groundTruthData1.y,line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
%                     else
%                         legendScatter22 = line(10.^(groundTruthData1.y),line_histograms_Y./max(line_histograms_Y),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(3));
%                     end
%                     set(legendScatter22, {'color'}, num2cell(UI.classes.colors3,2));
%                 end
        end
        
        
    if strcmp(UI.preferences.referenceData, 'Histogram') && ~isempty(reference_cell_metrics) && isfield(reference_cell_metrics,UI.plot.xTitle) && isfield(reference_cell_metrics,UI.plot.yTitle)
            if UI.checkbox.logx.Value == 1
                AA = reference_cell_metrics.(UI.plot.xTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                BB = cell_metrics.(UI.plot.xTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB) & BB>0);
                referenceData1.x = linspace(log10(nanmin([BB,AA])),log10(nanmax([BB,AA])),UI.preferences.binCount);
                xdata = log10(reference_cell_metrics.(UI.plot.xTitle));
            else
                referenceData1.x = linspace(nanmin([cell_metrics.(UI.plot.xTitle),reference_cell_metrics.(UI.plot.xTitle)]),nanmax([cell_metrics.(UI.plot.xTitle),reference_cell_metrics.(UI.plot.xTitle)]),UI.preferences.binCount);
                xdata = reference_cell_metrics.(UI.plot.xTitle);
            end
            if UI.checkbox.logy.Value == 1
                AA = reference_cell_metrics.(UI.plot.yTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA) & AA>0);
                BB = cell_metrics.(UI.plot.yTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB) & BB>0);
                referenceData1.y = linspace(log10(nanmin([BB,AA])),log10(nanmax([BB,AA])),UI.preferences.binCount);
                ydata = log10(reference_cell_metrics.(UI.plot.yTitle));
            else
                AA = reference_cell_metrics.(UI.plot.yTitle);
                AA = AA( ~isnan(AA) & ~isinf(AA));
                BB = cell_metrics.(UI.plot.yTitle);
                BB = BB( ~isnan(BB) & ~isinf(BB));
                referenceData1.y = linspace(nanmin([BB,AA]),nanmax([BB,AA]),UI.preferences.binCount);
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
                set(legendScatter2, {'color'}, num2cell(UI.classes.colors2,2));
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
                set(legendScatter22, {'color'}, num2cell(UI.classes.colors2,2));
            end
            xlim(h_scatter(2), xlim11)
            xlim(h_scatter(3), ylim11)
    end
    
    % % % % % 3D plot
    
    elseif UI.preferences.customPlotHistograms == 3

        hold on
        subfig_ax(1).YLabel.String = UI.labels.(UI.plot.yTitle); subfig_ax(1).YLabel.Interpreter = 'tex';
        subfig_ax(1).XLabel.String = UI.labels.(UI.plot.xTitle); subfig_ax(1).XLabel.Interpreter = 'tex';
        set(subfig_ax(1), 'Clipping','off','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
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
        
        view([az,el]); axis tight
        if UI.preferences.plotZLog == 1
            set(subfig_ax(1), 'ZScale', 'log')
        else
            set(subfig_ax(1), 'ZScale', 'linear')
        end
        
        if UI.preferences.logMarkerSize == 1
            markerSize = 10+ceil(rescale_vector(log10(plotMarkerSize(UI.params.subset)))*80*UI.preferences.markerSize/15);
        else
            markerSize = 10+ceil(rescale_vector(plotMarkerSize(UI.params.subset))*80*UI.preferences.markerSize/15);
        end
        [~, ~,ic] = unique(UI.classes.plot(UI.params.subset));

        markerColor = UI.classes.colors(ic,:);
        legendScatter = scatter3(plotX(UI.params.subset), plotY(UI.params.subset), plotZ(UI.params.subset),markerSize,markerColor,'filled', 'HitTest','off','MarkerFaceAlpha',.7);
        if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX(UI.cells.excitatory_subset), plotY(UI.cells.excitatory_subset), plotZ(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{1}, 'HitTest','off')
        end
        if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX(UI.cells.inhibitory_subset), plotY(UI.cells.inhibitory_subset), plotZ(UI.cells.inhibitory_subset),'Marker','o','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{2}, 'HitTest','off')
        end
        if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX(UI.cells.excitatoryPostsynaptic_subset), plotY(UI.cells.excitatoryPostsynaptic_subset), plotZ(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{3}, 'HitTest','off')
        end
        if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX(UI.cells.inhibitoryPostsynaptic_subset), plotY(UI.cells.inhibitoryPostsynaptic_subset), plotZ(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{4}, 'HitTest','off')
        end
        % Plotting synaptic projections
        if  plotConnections(1) == 1 && ~isempty(UI.params.putativeSubse) && UI.preferences.plotExcitatoryConnections
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
        if plotConnections(1) == 1 && ~isempty(UI.params.putativeSubse_inh) && UI.preferences.plotInhibitoryConnections
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
        
        subfig_ax(1).ZLabel.String = UI.labels.(UI.plot.zTitle); subfig_ax(1).ZLabel.Interpreter = 'tex';
        if contains(UI.plot.zTitle,'_num')
            zticks([1:length(groups_ids.(UI.plot.zTitle))]), zticklabels(groups_ids.(UI.plot.zTitle)),ztickangle(65),zlim([0.5,length(groups_ids.(UI.plot.zTitle))+0.5]),
%             subfig_ax(1).ZLabel.String = UI.plot.zTitle(1:end-4);
            subfig_ax(1).ZLabel.Interpreter = 'none';
        end
        
        % Ground truth cell types
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(UI.groupData1)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData1 = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX(idx_groupData), plotY(idx_groupData), plotZ(idx_groupData),'Marker',UI.preferences.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.preferences.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
        
        % Activating rotation
        rotateFig(subfig_ax(1),1)

        if contains(UI.plot.xTitle,'_num')
            xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5]),
%             subfig_ax(1).XLabel.String(1:end-4) = UI.plot.xTitle;
            subfig_ax(1).XLabel.Interpreter = 'none';
        end
        if contains(UI.plot.yTitle,'_num')
            yticks([1:length(groups_ids.(UI.plot.yTitle))]), yticklabels(groups_ids.(UI.plot.yTitle)),ytickangle(65),ylim([0.5,length(groups_ids.(UI.plot.yTitle))+0.5]),
%             subfig_ax(1).YLabel.String(1:end-4) = UI.plot.yTitle; 
            subfig_ax(1).YLabel.Interpreter = 'none';
        end
        [az,el] = view;
    
    % % % % % Rain cloud plot
        
    elseif UI.preferences.customPlotHistograms == 4
        
        if ~isempty(UI.classes.colors)
            subfig_ax(1).XLabel.String = UI.labels.(UI.plot.xTitle); subfig_ax(1).XLabel.Interpreter = 'tex';
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
            if size(UI.classes.colors,1)>=10
                box_on = 0; % No box plots
            else
                box_on = 1; % No box plots
            end
            counter = 1; % For aligning scatter data
            plotClas_subset = UI.classes.plot(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            ids_count = histc(plotClas_subset, ids);
            drops_y_pos = {};
            drops_idx = {};
            
            if strcmp(UI.preferences.rainCloudNormalization,'Peak')
                ylim1 = [(-length(ids_count)/5),1];
                subfig_ax(1).YLabel.String = 'Normalized by peak';
                subfig_ax(1).YTick = [0:0.1:1];

            elseif strcmp(UI.preferences.rainCloudNormalization,'Count')
                ylim1 = [(-length(ids_count)/5),1]*max(ids_count)*0.3;
                subfig_ax(1).YLabel.String = 'Count';
%                 subfig_ax(1).YTick = [0:0.1:1];
%                 f = f*length(X)/norm_value;
            else % Probability
                ylim1 = [-length(ids_count)/5,1]*0.30;
                subfig_ax(1).YLabel.String = 'Probability';
                subfig_ax(1).YTick = [0:0.05:1];
%                 f = f/100*length(Xi); 
            end
            
            ylim(subfig_ax(1),ylim1);
            
            for m = 1:length(unique(UI.classes.plot(UI.params.subset)))
                temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
                idx = find(plotClas_subset==ids(m));
                if length(temp1)>1
                    if UI.checkbox.logx.Value == 0
                        drops_idx{m} = UI.params.subset(idx((~isnan(plotX(temp1)) & ~isinf(plotX(temp1)))));
                    else
                        drops_idx{m} = UI.params.subset(idx((~isnan(plotX(temp1)) & plotX(temp1) > 0 & ~isinf(plotX(temp1)))));
                    end
                    drops_y_pos{m} = ce_raincloud_plot(plotX(temp1),'randomNumbers',UI.params.randomNumbers(temp1),'box_on',box_on,'box_dodge',1,'line_width',1,'color',UI.classes.colors(m,:),'alpha',0.4,'box_dodge_amount',0.025+(counter-1)*0.21,'dot_dodge_amount',0.13+(counter-1)*0.21,'bxfacecl',UI.classes.colors(m,:),'box_col_match',1,'log_axis',UI.checkbox.logx.Value,'markerSize',UI.preferences.markerSize,'normalization',UI.preferences.rainCloudNormalization,'norm_value',(ids_count(m)),'ylim',ylim1);
                    counter = counter + 1;
                end
            end
            
            axis tight
            if nanmin(plotX(UI.params.subset)) ~= nanmax(plotX(UI.params.subset)) & UI.checkbox.logx.Value == 0
                xlim([nanmin(plotX(UI.params.subset)),nanmax(plotX(UI.params.subset))])
            elseif nanmin(plotX(UI.params.subset)) ~= nanmax(plotX(UI.params.subset)) & UI.checkbox.logx.Value == 1 && any(plotX>0)
                xlim([nanmin(plotX(intersect(UI.params.subset,find(plotX>0)))),nanmax(plotX(intersect(UI.params.subset,find(plotX>0))))])
            end
            plotStatRelationship(plotX,0.015,UI.checkbox.logx.Value,ylim1) % Generates KS group statistics

%             axis tight
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
            
            % Plotting synaptic markers
            if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
                line(plotX(UI.cells.excitatory_subset), plotY1(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{1},'HitTest','off')
            end
            if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
                line(plotX(UI.cells.inhibitory_subset), plotY1(UI.cells.inhibitory_subset),'Marker','s','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{2},'HitTest','off')
            end
            if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
                line(plotX(UI.cells.excitatoryPostsynaptic_subset), plotY1(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{3},'HitTest','off')
            end
            if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
                line(plotX(UI.cells.inhibitoryPostsynaptic_subset), plotY1(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{4},'HitTest','off')
            end
            
            
            if contains(UI.plot.xTitle,'_num')
                xticks([1:length(groups_ids.(UI.plot.xTitle))]), xticklabels(groups_ids.(UI.plot.xTitle)),xtickangle(20),xlim([0.5,length(groups_ids.(UI.plot.xTitle))+0.5]),
%                 subfig_ax(1).XLabel.String = UI.plot.xTitle(1:end-4); 
                subfig_ax(1).XLabel.Interpreter = 'none';
            end
        end
    end
    subfig_ax(1).Title.String = 'Custom group plot';
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 2
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax(2).Visible,'on')

        d = findobj(UI.panel.subfig_ax(2),'Type','line');
        delete(d)
        d = findobj(UI.panel.subfig_ax(2),'Type','image');
        delete(d)
        d = findobj(UI.panel.subfig_ax(2),'Type','text');
        delete(d)
        set(UI.fig,'CurrentAxes',subfig_ax(2))
        set(subfig_ax(2),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
        if (strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.preferences.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics))
            set(subfig_ax(2), 'YScale', 'linear');
            yyaxis right
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
        end
        subfig_ax(2).YLabel.String = ['ACG \tau_{rise} (ms)'];
        subfig_ax(2).YLabel.Interpreter = 'tex';
        subfig_ax(2).XLabel.String = ['Trough-to-Peak (',char(181),'s)'];
        subfig_ax(2).Title.String = 'Cell type separation plot';
        set(subfig_ax(2), 'YScale', 'log');
        
        % Reference data
        if strcmp(UI.preferences.referenceData, 'Points') && ~isempty(reference_cell_metrics)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            ce_gscatter(reference_cell_metrics.troughToPeak(idx) * 1000, reference_cell_metrics.acg_tau_rise(idx), referenceData.clusClas(idx), UI.classes.colors2,8,'x');
        elseif strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics)
            yyaxis left
            set(subfig_ax(2), 'YScale', 'linear');
            referenceData.image = rot90(flip(1-sum(referenceData.z(:,:,:,referenceData.selection),4),2));
            legendScatter2 = image(referenceData.x,log10(referenceData.y),referenceData.image,'HitTest','off', 'PickableParts', 'none');
            set(legendScatter2,'HitTest','off'),set(gca,'YTick',[])
            yyaxis right, hold on
        end
        
        % Ground truth data
        if strcmp(UI.preferences.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics)
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            ce_gscatter(groundTruth_cell_metrics.troughToPeak(idx) * 1000, groundTruth_cell_metrics.acg_tau_rise(idx), groundTruthData.clusClas(idx), UI.classes.colors3,8,UI.preferences.groundTruthMarker);
        elseif strcmp(UI.preferences.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics)
            yyaxis left
            groundTruthData.image = 1-sum(groundTruthData.z(:,:,:,groundTruthData.selection),4);
            groundTruthData.image = flip(groundTruthData.image,2);
            groundTruthData.image = rot90(groundTruthData.image);
            set(subfig_ax(2), 'YScale', 'linear');
            legendScatter3 = image(groundTruthData.x,log10(groundTruthData.y),groundTruthData.image,'HitTest','off', 'PickableParts', 'none');
            set(legendScatter3,'HitTest','off'),set(gca,'YTick',[])
            yyaxis right, hold on
        end
        
        plotGroupData(cell_metrics.troughToPeak * 1000,cell_metrics.acg_tau_rise,plotConnections(2),1)
        
        if strcmp(UI.preferences.groundTruthData, 'None') && ~strcmp(UI.preferences.referenceData, 'None') && ~isempty(fig2_axislimit_x_reference) && ~isempty(fig2_axislimit_y_reference)
            xlim(fig2_axislimit_x_reference), ylim(fig2_axislimit_y_reference)
        elseif ~strcmp(UI.preferences.groundTruthData, 'None') && strcmp(UI.preferences.referenceData, 'None') && ~isempty(fig2_axislimit_x_groundTruth) && ~isempty(fig2_axislimit_y_groundTruth)
            xlim(fig2_axislimit_x_groundTruth), ylim(fig2_axislimit_y_groundTruth)
        elseif ~strcmp(UI.preferences.groundTruthData, 'None') && ~strcmp(UI.preferences.referenceData, 'None')
            xlim([min(fig2_axislimit_x_groundTruth(1),fig2_axislimit_x_reference(1)),max(fig2_axislimit_x_groundTruth(2),fig2_axislimit_x_reference(2))]) 
            ylim([min(fig2_axislimit_y_groundTruth(1),fig2_axislimit_y_reference(1)),max(fig2_axislimit_y_groundTruth(2),fig2_axislimit_y_reference(2))])
        else
            xlim(fig2_axislimit_x), ylim(fig2_axislimit_y)
        end
        xlim21 = xlim;
        ylim21 = ylim;
        
        if strcmp(UI.preferences.groundTruthData, 'Histogram') && ~isempty(groundTruth_cell_metrics)
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            clusClas_list = unique(groundTruthData.clusClas(idx));
            line_histograms_X = []; line_histograms_Y = [];
            for m = 1:length(clusClas_list)
                idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
                line_histograms_X(:,m) = ksdensity(groundTruth_cell_metrics.troughToPeak(idx(idx1)) * 1000,groundTruthData.x);
                line_histograms_Y(:,m) = ksdensity(log10(groundTruth_cell_metrics.acg_tau_rise(idx(idx1))),groundTruthData.y1);
            end
            yyaxis right, hold on
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
%             figure
            legendScatter2 = line(groundTruthData.x,10.^(line_histograms_X./max(line_histograms_X)*diff(log10(ylim21))*0.15+log10(ylim21(1))),'LineStyle','-','linewidth',1,'HitTest','off');
%             legendScatter2 = line(groundTruthData.x,log10(ylim21(1))+diff(log10(ylim21))*0.15*line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter2, {'color'}, num2cell(UI.classes.colors3,2),'Marker','none');
            legendScatter22 = line(xlim21(1)+100*line_histograms_Y./max(line_histograms_Y),10.^(groundTruthData.y1'*ones(1,length(clusClas_list))),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter22, {'color'}, num2cell(UI.classes.colors3,2),'Marker','none');
            xlim(xlim21), ylim((ylim21))
            yyaxis left, hold on
        elseif strcmp(UI.preferences.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics)
            yyaxis left
            xlim(xlim21), ylim(log10(ylim21))
            yyaxis right
        end
        if strcmp(UI.preferences.referenceData, 'Histogram') && ~isempty(reference_cell_metrics)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            clusClas_list = unique(referenceData.clusClas(idx));
            line_histograms_X = []; line_histograms_Y = [];
            for m = 1:length(clusClas_list)
                idx1 = find(referenceData.clusClas(idx)==clusClas_list(m));
                line_histograms_X(:,m) = ksdensity(reference_cell_metrics.troughToPeak(idx(idx1)) * 1000,referenceData.x);
                line_histograms_Y(:,m) = ksdensity(log10(reference_cell_metrics.acg_tau_rise(idx(idx1))),referenceData.y1);
            end
            yyaxis right, hold on
            set(subfig_ax(2),'YScale','log','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto'), hold on
            subfig_ax(2).YAxis(1).Color = 'k'; 
            subfig_ax(2).YAxis(2).Color = 'k';
            legendScatter2 = line(referenceData.x,10.^(line_histograms_X./max(line_histograms_X)*diff(log10(ylim21))*0.15+log10(ylim21(1))),'LineStyle','-','linewidth',1,'HitTest','off'); 
            set(legendScatter2, {'color'}, num2cell(UI.classes.colors2,2));
            legendScatter22 = line(xlim21(1)+100*line_histograms_Y./max(line_histograms_Y),10.^(referenceData.y1'*ones(1,length(clusClas_list))),'LineStyle','-','linewidth',1,'HitTest','off');
            set(legendScatter22, {'color'}, num2cell(UI.classes.colors2,2));
            xlim(xlim21), ylim((ylim21))
            yyaxis left, hold on
        elseif strcmp(UI.preferences.referenceData, 'Image') && ~isempty(reference_cell_metrics)
            yyaxis left
            xlim(xlim21), ylim(log10(ylim21))
            yyaxis right
        end
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax(3).Visible,'on')
        delete(subfig_ax(3).Children)
        set(UI.fig,'CurrentAxes',subfig_ax(3))
        set(subfig_ax(3),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        
        % Scatter plot with t-SNE metrics
        xlim(fig3_axislimit_x); ylim(fig3_axislimit_y);
        subfig_ax(3).YLabel.String = 't-SNE';
        subfig_ax(3).XLabel.String = 't-SNE';
        subfig_ax(3).Title.String = 't-SNE';
        plotGroupData(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',plotConnections(3),1)
    end
    
    %%  % % % % % % % % % % % % % % % % % % % %
    % Subfig 4 - 9
    % % % % % % % % % % % % % % % % % % % % % %
    
    for i_subplot = 4:9
        if strcmp(UI.panel.subfig_ax(i_subplot).Visible,'on')
            delete(subfig_ax(i_subplot).Children)
            set(UI.fig,'CurrentAxes',subfig_ax(i_subplot))
            set(subfig_ax(i_subplot),'ButtonDownFcn',@ClicktoSelectFromPlot,'xscale','linear','yscale','linear','XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto','ZDir','normal'), grid(subfig_ax(i_subplot),'off'), view(subfig_ax(i_subplot),2), daspect(subfig_ax(i_subplot),'auto')
            UI.subsetPlots{i_subplot-3} = customPlot(UI.preferences.customPlot{i_subplot-3},ii,general,batchIDs,subfig_ax(i_subplot),1,1,i_subplot);
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Separate legends in side panel 
    updateLegends
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Response including benchmarking the UI
    UI.benchmark.String = [num2str(length(UI.params.subset)),'/',num2str(cell_metrics.general.cellCount), ' cells displayed. Processing time: ', num2str(toc(timerInterface),3),' sec'];
    
end

    function subsetPlots = customPlot(customPlotSelection,ii,general,batchIDs,plotAxes,UI_fig,highlightCurrentCell,axnum)
        % INPUTS:
        % customPlotSelection = plot type
        % ii = cell to plot
        % general struct for the session of the cell to plot
        % 
        % plotAxes = plot axis
        % UI_fig = if the plot is a UI fig or an external plot
        
        % Creates all cell specific plots
        subsetPlots = [];
        
        % Determinig the plot color
        if ColorVal == 2 || (GroupVal == 1 && ColorVal < 5)
            col = UI.preferences.cellTypeColors(UI.classes.plot(ii),:);
        else
            if isnan(UI.classes.colors)
                col = UI.classes.colors;
            else
                temp = find(nanUnique(UI.classes.plot(UI.params.subset))==UI.classes.plot(ii));
                if temp <= size(UI.classes.colors,1)
                    col = UI.classes.colors(temp,:);
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
%             plotAxes.ContextMenu = cm;
            % Single waveform with std
            if isfield(cell_metrics.waveforms,'filt_std') && ~isempty(cell_metrics.waveforms.filt_std{ii}) && numel(cell_metrics.waveforms.filt{ii}) == numel(cell_metrics.waveforms.filt_std{ii})
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.filt{ii}+cell_metrics.waveforms.filt_std{ii},flip(cell_metrics.waveforms.filt{ii}-cell_metrics.waveforms.filt_std{ii})],'black','EdgeColor','none','FaceAlpha',.2,'HitTest','off')
            end
            line(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.filt{ii}, 'color', col,'linewidth',2,'HitTest','off')    
            
            % Waveform metrics
            if UI.preferences.plotWaveformMetrics
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
            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1,axnum);
            end
            if UI.preferences.plotInsetACG > 1
                plotInsetACG(ii,col,general,1)
            end
        elseif strcmp(customPlotSelection,'Waveforms (all)')
            % All waveforms (z-scored) colored according to cell type
            plotAxes.XLabel.String = 'Time (ms)';
            
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.zscoreWaveforms == 1
               zscoreWaveforms1 = 'filt_zscored';
               plotAxes.YLabel.String = 'Waveforms (z-scored)';
            else
                zscoreWaveforms1 = 'filt_absolute';
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V)'];
            end
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                if ~isempty(set1)
                    xdata = repmat([cell_metrics.waveforms.time_zscored,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.waveforms.(zscoreWaveforms1)(:,set1);nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                end
            end
            
            % selected cell in black
            if highlightCurrentCell
                line(cell_metrics.waveforms.time_zscored, cell_metrics.waveforms.(zscoreWaveforms1)(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            end
            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1,axnum);
            end
            if UI.preferences.plotInsetACG > 1
                plotInsetACG(ii,col,general,1)
            end
            
        elseif strcmp(customPlotSelection,'Waveforms (group averages)')
            % All waveforms (z-scored) colored according to cell type
            plotAxes.XLabel.String = 'Time (ms)';
            
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.zscoreWaveforms == 1
               zscoreWaveforms1 = 'filt_zscored';
               plotAxes.YLabel.String = 'Waveforms (z-scored)';
            else
                zscoreWaveforms1 = 'filt_absolute';
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V)'];
            end
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                if ~isempty(set1)
                    xdata = cell_metrics.waveforms.time_zscored;
                    waveforms_mean = nanmean(cell_metrics.waveforms.(zscoreWaveforms1)(:,set1)');
                    waveforms_std = nanstd(cell_metrics.waveforms.(zscoreWaveforms1)(:,set1)');
                    patch([xdata,flip(xdata)], [waveforms_mean+waveforms_std,flip(waveforms_mean-waveforms_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                    line(xdata,waveforms_mean, 'color', [UI.classes.colors(k,:)],'HitTest','off','linewidth',2)
                end
            end
            
            % selected cell in black
            if highlightCurrentCell
                line(cell_metrics.waveforms.time_zscored, cell_metrics.waveforms.(zscoreWaveforms1)(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            end
            
        elseif strcmp(customPlotSelection,'Waveforms (across channels)')
            % All waveforms across channels with largest ampitude colored according to cell type
            if strcmp(UI.preferences.waveformsAcrossChannelsAlignment,'Probe layout')
                plotAxes.XLabel.String = ['Time (ms) / Position (',char(181),'m*',num2str(UI.params.chanCoords.x_factor),')'];
                plotAxes.YLabel.String = ['Waveforms (',char(181),'V) / Position (',char(181),'m/',num2str(UI.params.chanCoords.y_factor),')'];
                plotAxes.Title.String = 'Waveforms across channels';
                if isfield(general,'chanCoords')  && ~isempty(cell_metrics.waveforms.filt_all{ii}) && ~isempty(cell_metrics.waveforms.time_all{ii})
                    if UI.preferences.plotChannelMapAllChannels
                        channels2plot = cell_metrics.waveforms.channels_all{ii};
                    else
                        channels2plot = cell_metrics.waveforms.bestChannels{ii};
                    end
                    if length(channels2plot) > size(cell_metrics.waveforms.filt_all{ii},1)
                        channels2plot =channels2plot(1:size(cell_metrics.waveforms.filt_all{ii},1));
                    end
                    channels2plot = 1:size(cell_metrics.waveforms.filt_all{ii},1);
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
        elseif strcmp(customPlotSelection,'Waveforms (image across channels)')
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Channels';
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'electrodeGroups') && isfield(general,'electrodeGroups') && ~isempty(cell_metrics.waveforms.filt_all{ii}) && ~isempty(cell_metrics.waveforms.time_all{ii})
                if UI.preferences.plotChannelMapAllChannels
                    channelOrder = flip([general.electrodeGroups{:}]);
                    horzlines = cumsum(flip(cellfun(@length,general.electrodeGroups)));
                    if numel(channelOrder) > size(cell_metrics.waveforms.filt_all{ii},1)
                        channelOrder = 1:size(cell_metrics.waveforms.filt_all{ii},1);
                    end
                    horzlines(horzlines>size(cell_metrics.waveforms.filt_all{ii},1)) = [];
                else
                    channels2plot = cell_metrics.waveforms.bestChannels{ii};
                    channelOrder = flip([general.electrodeGroups{cell_metrics.electrodeGroup(ii)}]);
                    channelOrder = intersect(channelOrder,channels2plot,'stable');
                end
                
                imagesc(cell_metrics.waveforms.time_all{ii}, [1:numel(channelOrder)], cell_metrics.waveforms.filt_all{ii}(channelOrder,:),'HitTest','off'), axis tight
                if UI.preferences.plotChannelMapAllChannels & ~isempty(horzlines)
                    line(cell_metrics.waveforms.time_all{ii}([1,end]),[horzlines;horzlines]+0.5,'color','w','HitTest','off','linewidth',0.8)
                end
                [~,bestChannel] = max(range(cell_metrics.waveforms.filt_all{ii}(channelOrder,:),2));
                if ~isempty(bestChannel)
                    line(cell_metrics.waveforms.time_all{ii}([1,end]),[1;1]*(bestChannel+[-0.5,0.5]),'color','w','HitTest','off','linewidth',0.8)
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
        elseif strcmp(customPlotSelection,'Trilaterated position')
            % All waveforms across channels with largest ampitude colored according to cell type
            plotAxes.XLabel.String = ['Position (',char(181),'m)'];
            plotAxes.YLabel.String = ['Position (',char(181),'m)'];
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'chanCoords')
                line(general.chanCoords.x,general.chanCoords.y,'Marker','s','color',[0.5 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5],'markersize',5,'HitTest','off','LineStyle','none','linewidth',1.2)
            end
            switch UI.preferences.trilatGroupData
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
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), subset1);
                line(cell_metrics.trilat_x(set1),cell_metrics.trilat_y(set1),'Marker','.','LineStyle','none', 'color', [UI.classes.colors(k,:),0.2],'markersize',UI.preferences.markerSize,'HitTest','off'), hold on
            end
            
            % Plots putative connections
            plotPutativeConnections(cell_metrics.trilat_x,cell_metrics.trilat_y,UI.monoSyn.disp,subset1)
            
            % Plots X marker for selected cell
            if highlightCurrentCell
                plotMarker(cell_metrics.trilat_x(ii),cell_metrics.trilat_y(ii))
            end
            
            % Plots tagget ground-truth cell types
            plotGroudhTruthCells(cell_metrics.trilat_x, cell_metrics.trilat_y)

        elseif strcmp(customPlotSelection,'Common Coordinate Framework')
            % All waveforms across channels with largest ampitude colored according to cell type
            plotAxes.XLabel.String = ['Position (',char(181),'m)'];
            plotAxes.YLabel.String = ['Position (',char(181),'m)'];
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'ccf')
                line(general.ccf.x,general.ccf.z,general.ccf.y,'Marker','.','color',[0.3 0.5 0.5],'MarkerFaceColor',[0.5 0.5 0.5],'markersize',5,'HitTest','off','LineStyle','none','linewidth',0.5)
            end
            switch UI.preferences.trilatGroupData
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
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), subset1);
                if ~isempty(set1)
                    line(cell_metrics.ccf_x(set1),cell_metrics.ccf_z(set1),cell_metrics.ccf_y(set1),'Marker','.','LineStyle','none', 'color', [UI.classes.colors(k,:),0.2],'markersize',UI.preferences.markerSize,'HitTest','off')
                end
            end

            if exist('plotAllenBrainGrid.m','file')
                plotAllenBrainGrid
            end
            xlabel('x ( Anterior-Posterior; µm)'), zlabel('y (Superior-Inferior; µm)'), ylabel('z (Left-Right; µm)'), axis equal, set(plotAxes, 'ZDir','reverse','Clipping','off','ButtonDownFcn',[]);
            view(ccf_ratio(1),ccf_ratio(2)); 
            if UI_fig
                rotateFig(plotAxes,getAxisBelowCursor)
            end
            
            % Plots putative connections
            plotPutativeConnections3(cell_metrics.ccf_x,cell_metrics.ccf_z,cell_metrics.ccf_y,UI.monoSyn.disp)
            
            % Plots X marker for selected cell
            if highlightCurrentCell
                plotMarker3(cell_metrics.ccf_x(ii),cell_metrics.ccf_z(ii),cell_metrics.ccf_y(ii))
            end
            % Plots tagget ground-truth cell types
%             plotGroudhTruthCells3(cell_metrics.ccf_x(ii),cell_metrics.ccf_z(ii),cell_metrics.ccf_y(ii))
            
        elseif strcmp(customPlotSelection,'Waveforms (image)')
            % All waveforms, zscored and shown in a imagesc plot
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = ['Cells (Sorting: ', UI.preferences.sortingMetric,')'];
            plotAxes.Title.String = customPlotSelection;
            % Sorted according to trough-to-peak
            [~,UI.preferences.troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(UI.preferences.troughToPeakSorted) == ii);
            
            imagesc(cell_metrics.waveforms.time_zscored, [1:length(UI.params.subset)], cell_metrics.waveforms.filt_zscored(:,UI.params.subset(UI.preferences.troughToPeakSorted))','HitTest','off'),
            colormap(UI.preferences.colormap),
            
            % selected cell highlighted in white
            if ~isempty(idx) && highlightCurrentCell
                line([cell_metrics.waveforms.time_zscored(1),cell_metrics.waveforms.time_zscored(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
            end
            ploConnectionsHighlights(cell_metrics.waveforms.time_zscored,UI.params.subset(UI.preferences.troughToPeakSorted))
            
        elseif strcmp(customPlotSelection,'Waveforms (raw single)')
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
            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1,axnum);
            end
            
        elseif strcmp(customPlotSelection,'Waveforms (raw all)')
            % All raw waveforms (z-scored) colored according to cell type
            plotAxes.XLabel.String = 'Time (ms)';
            
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if UI.preferences.zscoreWaveforms == 1
               zscoreWaveforms1 = 'raw_zscored';
               plotAxes.YLabel.String = 'Raw waveforms (z-scored)';
            else
                zscoreWaveforms1 = 'raw_absolute';
                plotAxes.YLabel.String =  ['Raw waveforms (',char(181),'V)'];
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                xdata = repmat([cell_metrics.waveforms.time_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.(zscoreWaveforms1)(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
            end
            
            % selected cell in black
            if highlightCurrentCell
                line(cell_metrics.waveforms.time_zscored, cell_metrics.waveforms.(zscoreWaveforms1)(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            end
            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                plotInsetChannelMap(ii,col,general,1,axnum);
            end
            
        elseif strcmp(customPlotSelection,'Connectivity graph')
            plotAxes.XLabel.String = ' ';
            plotAxes.YLabel.String = ' ';
            plotAxes.Title.String = customPlotSelection;
            if isfield(cell_metrics,'putativeConnections') && (isfield(cell_metrics.putativeConnections,'excitatory') || isfield(cell_metrics.putativeConnections,'inhibitory'))
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
                    if ~UI.preferences.plotExcitatoryConnections
                        connectivityGraph = rmedge(connectivityGraph,Y(1:size(putativeConnections_subset,1),1),Y(1:size(putativeConnections_subset,1),2));
                    end
                    if ~UI.preferences.plotInhibitoryConnections
                        connectivityGraph = rmedge(connectivityGraph,Y(size(putativeConnections_subset,1)+1:end,1),Y(size(putativeConnections_subset,1)+1:end,2));
                    elseif ~isempty(putativeConnections_subset)
                        connectivityGraph1 = connectivityGraph;
                        connectivityGraph1 = rmedge(connectivityGraph1,Y(1:size(putativeConnections_subset,1),1),Y(1:size(putativeConnections_subset,1),2));
                    end
                    connectivityGraph_plot = plot(connectivityGraph,'Layout','force','Iterations',15,'MarkerSize',3,'NodeCData',UI.classes.plot(putativeSubset1)','EdgeCData',connectivityGraph.Edges.Weight,'HitTest','off','EdgeColor',[0.2 0.2 0.2],'NodeColor','k','NodeLabel',{}); %
                    subsetPlots.xaxis = connectivityGraph_plot.XData;
                    subsetPlots.yaxis = connectivityGraph_plot.YData;
                    subsetPlots.subset = putativeSubset1;
                    subsetPlots.type = 'points';  % points, curves, image
                    
                    for k = 1:length(classes2plotSubset)
                        highlight(connectivityGraph_plot,find(UI.classes.plot(putativeSubset1)==classes2plotSubset(k)),'NodeColor',UI.classes.colors(k,:))
                    end
                    if UI.preferences.plotInhibitoryConnections && ~isempty(putativeConnections_subset)
                        highlight(connectivityGraph_plot,connectivityGraph1,'EdgeColor','b')
                    end
                    axis tight, %title('Connectivity graph')
                    set(plotAxes, 'box','off') % 'XTickLabel',[], 'YTickLabel',[]
                    if UI_fig
                        set(plotAxes,'ButtonDownFcn',@ClicktoSelectFromPlot)
                    end
                    
                    if any(ii == subsetPlots.subset)
                        idx = find(ii == subsetPlots.subset);
                        line(subsetPlots.xaxis(idx), subsetPlots.yaxis(idx),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
                        line(subsetPlots.xaxis(idx), subsetPlots.yaxis(idx),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
                    end
                    
                    % Plots putative connections
                    if ~isempty(UI.params.putativeSubse) && UI.preferences.plotExcitatoryConnections && ismember(UI.monoSyn.disp,{'Selected','Upstream','Downstream','Up & downstream','All'}) && ~isempty(UI.params.connections)
                        C = ismember(subsetPlots.subset,UI.params.connections);
                        line(subsetPlots.xaxis(C),subsetPlots.yaxis(C),'Marker','o','LineStyle','none','color','k','HitTest','off')
                    end
                    
                    % Plots putative inhibitory connections
                    if  ~isempty(UI.params.putativeSubse_inh) && UI.preferences.plotInhibitoryConnections && ismember(UI.monoSyn.disp,{'Selected','Upstream','Downstream','Up & downstream','All'}) && ~isempty(UI.params.connections_inh)
                        C = ismember(subsetPlots.subset,UI.params.connections_inh);
                        line(subsetPlots.xaxis(C),subsetPlots.yaxis(C),'Marker','o','LineStyle','none','color','k','HitTest','off')
                    end
                else
                    text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'Connectivity matrix')
            plotAxes.XLabel.String = ['Inbound cells (sorting: ', UI.preferences.sortingMetric,')'];
            plotAxes.YLabel.String = ['Outbound cells (sorting: ', UI.preferences.sortingMetric,')'];
            plotAxes.Title.String = customPlotSelection;
            subsetPlots.type = 'image';  % points, curves, image
            if UI.BatchMode
                subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                subset222 = UI.params.subset(subset1);
            else
                subset1 = 1:numel(UI.params.subset);
                subset222 = UI.params.subset;
            end
            connectionMatrix = ones(length(subset222),length(subset222),3);
            for j3 = 1:length(subset222)
                connectionMatrix(j3,j3,:) = [0.8,0.8,0.8];
            end
            if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
                putativeSubset22 = find(sum(ismember(cell_metrics.putativeConnections.excitatory,subset222)')==2);
                if ~isempty(putativeSubset22)
                    putativeSubset31 = cell_metrics.putativeConnections.excitatory(putativeSubset22,1)';
                    putativeSubset32 = cell_metrics.putativeConnections.excitatory(putativeSubset22,2)';
                    [~,ia1] = ismember(putativeSubset31,subset222);
                    [~,ia2] = ismember(putativeSubset32,subset222);
                    for j1 = 1:length(putativeSubset22)
                        connectionMatrix(ia1(j1),ia2(j1),[1,2]) = 0;
                    end
                end
            end
            if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory')
                putativeSubset22 = find(sum(ismember(cell_metrics.putativeConnections.inhibitory,subset222)')==2);
                if ~isempty(putativeSubset22)
                    putativeSubset31 = cell_metrics.putativeConnections.inhibitory(putativeSubset22,1)';
                    putativeSubset32 = cell_metrics.putativeConnections.inhibitory(putativeSubset22,2)';
                    [~,ia1] = ismember(putativeSubset31,subset222);
                    [~,ia2] = ismember(putativeSubset32,subset222);
                    for j1 = 1:length(putativeSubset22)
                        connectionMatrix(ia1(j1),ia2(j1),[2,3]) = 0;
                    end
                end
            end
            [~,troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset222));
            imagesc(connectionMatrix(troughToPeakSorted,troughToPeakSorted,:),'HitTest','off'),
            
            idx = find(subset222(troughToPeakSorted) == ii);
            if ~isempty(idx) && highlightCurrentCell
                patch([0,length(subset222),length(subset222),0]+0.5,[idx-0.5,idx-0.5,idx+0.5,idx+0.5],'m','EdgeColor','m','HitTest','off','facealpha',0.1)
                patch([idx-0.5,idx-0.5,idx+0.5,idx+0.5],[0,length(subset222),length(subset222),0]+0.5,'b','EdgeColor','b','HitTest','off','facealpha',0.1)
            end
            
        elseif strcmp(customPlotSelection,'RCs_meanCCG (all)')
            % CCGs for selected cell with other cell pairs from the same session. The ACG for the selected cell is shown first
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Normalized response';
            plotAxes.Title.String = customPlotSelection;
            if isempty(meanCCG)
                idx = find(cellfun(@isempty,cell_metrics.responseCurves.meanCCG));
                if ~isempty(idx)
                    cell_metrics.responseCurves.meanCCG(idx) = repmat({nan(51,1)},1,length(idx));
                end
                meanCCG = cell2mat(cell_metrics.responseCurves.meanCCG);
                if size(meanCCG,1) ~= 51
                    meanCCG = meanCCG';
                end
                meanCCG = meanCCG./mean(meanCCG);
            end
            if isfield(general,'responseCurves') && isfield(general.responseCurves,'meanCCG')
                subsetPlots.xaxis = general.responseCurves.meanCCG.x_bins(:)';
            else
                subsetPlots.xaxis = -250:10:250;
            end
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                xdata = repmat([subsetPlots.xaxis,nan(1,1)],length(set1),1)';
                ydata = [meanCCG(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
            end
            % Selected cell in black
            if highlightCurrentCell
                line(subsetPlots.xaxis, meanCCG(:,ii), 'color', 'k','linewidth',2,'HitTest','off')
            end
            subsetPlots.yaxis = meanCCG(:,UI.params.subset);
            subsetPlots.subset = UI.params.subset;
            subsetPlots.type = 'curves';  % points, curves, image
            
         elseif strcmp(customPlotSelection,'RCs_meanCCG (image)')
            % CCGs for selected cell with other cell pairs from the same session. The ACG for the selected cell is shown first
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            if isfield(general,'responseCurves') && isfield(general.responseCurves,'meanCCG')
                subsetPlots.xaxis = general.responseCurves.meanCCG.x_bins(:)';
            else
                subsetPlots.xaxis = -250:10:250;
            end
            if isempty(meanCCG)
                idx = find(cellfun(@isempty,cell_metrics.responseCurves.meanCCG));
                if ~isempty(idx)
                    cell_metrics.responseCurves.meanCCG(cell_metrics.responseCurves.meanCCG) = repmat({nan(51,1)},1,length(idx));
                end
                meanCCG = cell2mat(cell_metrics.responseCurves.meanCCG);
                if size(meanCCG,1) ~= 51
                    meanCCG = meanCCG';
                end
                meanCCG = meanCCG./mean(meanCCG);
            end
            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            imagesc(subsetPlots.xaxis,1:numel(UI.params.subset),meanCCG(:,UI.params.subset(burstIndexSorted))','HitTest','off')
            if ~isempty(idx) && highlightCurrentCell
                line(subsetPlots.xaxis([1,end]),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
            end
            subsetPlots.subset = UI.params.subset;
            subsetPlots.type = 'image'; % image, raster, curves
                
        elseif strcmp(customPlotSelection,'CCGs (image)')
            % CCGs for selected cell with other cell pairs from the same session. The ACG for the selected cell is shown first
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = 'Cells';
            plotAxes.Title.String = customPlotSelection;
            
            general = generateCCGs(batchIDs,general); % Generates CCGs from spikes
            if isfield(general,'ccg') && ~isempty(UI.params.subset)
                if UI.BatchMode
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset222 = UI.params.subset(subset1);
                    subset1 = cell_metrics.UID(UI.params.subset(subset1));
                else
                    subset1 = UI.params.subset;
                    subset222 = UI.params.subset;
                end
                subset1 = [cell_metrics.UID(ii),subset1(subset1~=cell_metrics.UID(ii))];
                Ydata = [1:length(subset1)];

                if strcmp(UI.preferences.acgType,'Narrow')
                    Xdata = [-30:30]/2;
                    Zdata = general.ccg(41+30:end-40-30,cell_metrics.UID(ii),subset1)./max(general.ccg(41+30:end-40-30,cell_metrics.UID(ii),subset1));
                else
                    Xdata = [-100:100]/2;
                    Zdata = general.ccg(:,cell_metrics.UID(ii),subset1)./max(general.ccg(:,cell_metrics.UID(ii),subset1));
                end
                imagesc(plotAxes,Xdata,Ydata,permute(Zdata,[3,1,2]),'HitTest','off'),
                if highlightCurrentCell
                    line(plotAxes,[0,0,],[0.5,length(subset1)+0.5],'color','k','HitTest','off')
                end
                colormap(UI.preferences.colormap), axis tight
                
                % Synaptic partners are also displayed
%                 subset2 = cell_metrics.UID(subset222);
                ploConnectionsHighlights([Xdata(1),Xdata(end)],subset222)
    
            else
                text(plotAxes,0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ACGs (single)') % ACGs
            % Auto-correlogram for selected cell. Colored according to cell-type. Normalized firing rate. X-axis according to selected option
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = customPlotSelection;
            
            if strcmp(UI.preferences.acgType,'Normal')
                plotXdata = [-100:100]'/2;
                plotYdata = cell_metrics.acg.narrow(:,ii);
                xticks([-50:10:50]),xlim([-50,50])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.preferences.acgType,'Narrow')
                plotXdata = [-30:30]'/2;
                plotYdata = cell_metrics.acg.narrow(41+30:end-40-30,ii);
                xticks([-15:5:15]), xlim([-15,15])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.preferences.acgType,'Log10') && isfield(general,'acgs') && isfield(general.acgs,'log10')
                if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')
                    if plotAcgYLog
                        plotYdata1 = cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii);
                        plotYdata1(plotYdata1 < 0.1)=0.1;
                        line(general.isis.log10, plotYdata1,'linewidth',1,'color',[0.5 0.5 0.5],'HitTest','off')
                    else
                        bar_from_patch(general.isis.log10, cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii),col)
                    end
                end
                
                if UI.preferences.acgYaxisLog == 3
                    plotXdata = general.acgs.log10;
                    plotYdata = cell_metrics.acg.log10(:,ii).*general.acgs.log10;
                    set(plotAxes, 'YScale', 'log')
                else
                    plotXdata = general.acgs.log10;
                    plotYdata = cell_metrics.acg.log10(:,ii);
                end
                set(plotAxes,'xscale','log'),xlim([.001,10])
                plotAxes.XLabel.String = 'Time (sec)';
            else
                plotXdata = [-500:500]';
                plotYdata = cell_metrics.acg.wide(:,ii);
                xticks([-500:100:500]),xlim([-500,500])
                plotAxes.XLabel.String = 'Time (ms)';
            end
            
            if plotAcgYLog
                set(plotAxes,'yscale','log')
                plotYdata(plotYdata < 0.1)=0.1;
                line(plotXdata, plotYdata,'linewidth',1,'color',col,'HitTest','off')
            else
                set(plotAxes,'yscale','linear')
                bar_from_patch_centered_bins(plotXdata, plotYdata,col)
            end
            % ACG fit with a triple-exponential
            if plotAcgFit
                a = cell_metrics.acg_tau_decay(ii); b = cell_metrics.acg_tau_rise(ii); c = cell_metrics.acg_c(ii); d = cell_metrics.acg_d(ii);
                e = cell_metrics.acg_asymptote(ii); f = cell_metrics.acg_refrac(ii); g = cell_metrics.acg_tau_burst(ii); h = cell_metrics.acg_h(ii);
                x_fit = 1:0.2:50;
                fiteqn = max(c*(exp(-(x_fit-f)/a)-d*exp(-(x_fit-f)/b))+h*exp(-(x_fit-f)/g)+e,0);
                if plotAcgYLog
                    fiteqn(fiteqn < 0.1)=0.1;
                end
                if strcmp(UI.preferences.acgType,'Log10')
                    line([-flip(x_fit),x_fit]/1000,[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7],'HitTest','off')
                    % plot(0.05,fiteqn(246),'ok')
                else
                    line([-flip(x_fit),x_fit],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7],'HitTest','off')
                end
            end
            
            ax5 = axis; grid on, set(plotAxes, 'Layer', 'top')
            line([ax5(1) ax5(2)],cell_metrics.firingRate(ii)*[1 1],'LineStyle','--','color','k')          
            
        elseif strcmp(customPlotSelection,'ACGs (group averages)') % ACGs
            % Auto-correlogram for groups. Colored according to cell-type. Normalized firing rate. X-axis according to selected option
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if strcmp(UI.preferences.acgType,'Normal')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = [-100:100]/2;
                    ACGs_mean = nanmean(cell_metrics.acg.narrow(:,set1)./max(cell_metrics.acg.narrow(:,set1)),2)';
                    ACGs_std = nanstd(cell_metrics.acg.narrow(:,set1)./max(cell_metrics.acg.narrow(:,set1)),0,2)';
                    if plotAcgYLog
                        ACGs_mean(ACGs_mean < 0.1)=0.1;
                    end
                    patch([xdata,flip(xdata)], [ACGs_mean+ACGs_std,flip(ACGs_mean-ACGs_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                    line(xdata,ACGs_mean, 'color', UI.classes.colors(k,:),'HitTest','off','linewidth',1.5)
                end
                    
                if highlightCurrentCell
                    ydata = cell_metrics.acg.narrow(:,ii)/max(cell_metrics.acg.narrow(:,ii));
                    line([-100:100]/2,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-50:10:50]),xlim([-50,50])
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.preferences.acgType,'Narrow')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = [-30:30]/2;
                    ACGs_mean = nanmean(cell_metrics.acg.narrow(41+30:end-40-30,set1)./max(cell_metrics.acg.narrow(41+30:end-40-30,set1)),2)';
                    ACGs_std = nanstd(cell_metrics.acg.narrow(41+30:end-40-30,set1)./max(cell_metrics.acg.narrow(41+30:end-40-30,set1)),0,2)';
                    if plotAcgYLog
                        ACGs_mean(ACGs_mean < 0.1)=0.1;
                    end
                    patch([xdata,flip(xdata)], [ACGs_mean+ACGs_std,flip(ACGs_mean-ACGs_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                    line(xdata,ACGs_mean, 'color', UI.classes.colors(k,:),'HitTest','off')
                end
                if highlightCurrentCell
                    ydata = cell_metrics.acg.narrow(41+30:end-40-30,ii)/max(cell_metrics.acg.narrow(41+30:end-40-30,ii));
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line([-30:30]/2,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-15:5:15]),xlim([-15,15])
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.preferences.acgType,'Log10')
                if UI.preferences.acgYaxisLog == 1
                    for k = 1:length(classes2plotSubset)
                        set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                        xdata = general.acgs.log10';
                        ACGs_mean = nanmean(cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1)),2)';
                        ACGs_std = nanstd(cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1)),0,2)';
                        if plotAcgYLog
                            ACGs_mean(ACGs_mean < 0.1)=0.1;
                        end
                        patch([xdata,flip(xdata)], [ACGs_mean+ACGs_std,flip(ACGs_mean-ACGs_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                        line(xdata,ACGs_mean, 'color', UI.classes.colors(k,:),'HitTest','off')
                    end
                    if highlightCurrentCell
                        ydata = cell_metrics.acg.log10(:,ii)/max(cell_metrics.acg.log10(:,ii));
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(general.acgs.log10,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                    end
                else
                    for k = 1:length(classes2plotSubset)
                        set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                        xdata = general.acgs.log10';
                        ACGs_mean = nanmean(cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1)),2)';
                        ACGs_std = nanstd(cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1)),0,2)';
                        if plotAcgYLog
                            ACGs_mean(ACGs_mean < 0.1)=0.1;
                        end
                        patch([xdata,flip(xdata)], [ACGs_mean+ACGs_std,flip(ACGs_mean-ACGs_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                        line(xdata,ACGs_mean, 'color', UI.classes.colors(k,:),'HitTest','off')
                    end
                    if highlightCurrentCell
                        ydata = cell_metrics.acg.log10(:,ii)/max(cell_metrics.acg.log10(:,ii));
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(general.acgs.log10,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                    end
                end
                xlim([0,10]), set(gca,'xscale','log')
                plotAxes.XLabel.String = 'Time (sec)';
            else
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = [-500:500];
                    ACGs_mean = nanmean(cell_metrics.acg.wide(:,set1)./max(cell_metrics.acg.wide(:,set1)),2)';
                    ACGs_std = nanstd(cell_metrics.acg.wide(:,set1)./max(cell_metrics.acg.wide(:,set1)),0,2)';
                    if plotAcgYLog
                        ACGs_mean(ACGs_mean < 0.1)=0.1;
                    end
                    patch([xdata,flip(xdata)], [ACGs_mean+ACGs_std,flip(ACGs_mean-ACGs_std)],UI.classes.colors(k,:),'EdgeColor','none','FaceAlpha',.2,'HitTest','off'), hold on
                    line(xdata,ACGs_mean, 'color', UI.classes.colors(k,:),'HitTest','off')
                end
                if highlightCurrentCell
                    ydata = cell_metrics.acg.wide(:,ii)/max(cell_metrics.acg.wide(:,ii));
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line([-500:500],ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-500:100:500]),xlim([-500,500])
                plotAxes.XLabel.String = 'Time (ms)';
            end
            if plotAcgYLog
                set(plotAxes,'yscale','log')
            else
                set(plotAxes,'yscale','linear'), ylim([0 1.1])
            end
     
        elseif strcmp(customPlotSelection,'ISIs (single)') % ISIs
            plotAxes.YLabel.String = 'Cells';
            plotAxes.XLabel.String = '';
            plotAxes.Title.String = customPlotSelection;
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')
                if strcmp(UI.preferences.isiNormalization,'Rate')
                    bar_from_patch_centered_bins(general.isis.log10, cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii),'k')
                    bar_from_patch_centered_bins(general.isis.log10, cell_metrics.isi.log10(:,ii),col)
                    xlim([0,10])
                    plotAxes.XLabel.String = 'Time (sec)';
                    plotAxes.YLabel.String = 'Rate (Hz)';
                    
                elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                    bar_from_patch_centered_bins(1./general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^UI.params.ACGLogIntervals))',col)
                    xlim([0,1000])
                    plotAxes.XLabel.String = 'Instantaneous rate (Hz)';
                    plotAxes.YLabel.String = 'Occurrence';
                else
                    bar_from_patch_centered_bins(general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^UI.params.ACGLogIntervals))',col)
                    xlim([0,10])
                    plotAxes.XLabel.String = 'Time (sec)';
                    plotAxes.YLabel.String = 'Occurrence';
                end
                set(plotAxes,'xscale','log')
                ax5 = axis; grid on, set(plotAxes, 'Layer', 'top')
%                 title('ISI distribution')
            else
%                 title('ISI distribution')
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ISIs (all)') % ISIs
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10') && ~isempty(classes2plotSubset)
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([general.isis.log10',nan(1,1)],length(set1),1)';
                    if strcmp(UI.preferences.isiNormalization,'Rate')
                        ydata = [cell_metrics.isi.log10(:,set1);nan(1,length(set1))];
                        xlim1 = [0,10];
                        plotAxes.XLabel.String = 'Time (sec)';
                        plotAxes.YLabel.String = 'Rate (Hz)';
                    elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                        xdata = repmat([1./general.isis.log10',nan(1,1)],length(set1),1)';
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^UI.params.ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,1000];
                        plotAxes.XLabel.String = 'Instantaneous rate (Hz)';
                        plotAxes.YLabel.String = 'Occurrence';
                    else
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^UI.params.ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,10];
                        plotAxes.XLabel.String = 'Time (sec)';
                        plotAxes.YLabel.String = 'Occurrence';
                    end
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                end
                if highlightCurrentCell
                    if strcmp(UI.preferences.isiNormalization,'Rate')
                        line(general.isis.log10,cell_metrics.isi.log10(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                    elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                        line(1./general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^UI.params.ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                    else
                        line(general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^UI.params.ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                    end
                end
                xlim(xlim1), set(plotAxes,'xscale','log')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
        elseif strcmp(customPlotSelection,'ACGs (all)')
            % All ACGs. Colored by to cell-type.
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = customPlotSelection;
            if UI.preferences.showAllTraces == 0 && length(UI.params.subset)>2000
                plotSubset = UI.params.subset(randsample(length(UI.params.subset),2000));
            else
                plotSubset = UI.params.subset;
            end
            if strcmp(UI.preferences.acgType,'Normal')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-100:100]/2,nan(1,1)],length(set1),1)';
                    if plotAcgZscore
                        ydata = [cell_metrics.acg.narrow(:,set1)./max(cell_metrics.acg.narrow(:,set1));nan(1,length(set1))];
                    else
                        ydata = [cell_metrics.acg.narrow(:,set1);nan(1,length(set1))];
                    end
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                end
                    
                if highlightCurrentCell && plotAcgZscore
                    ydata = cell_metrics.acg.narrow(:,ii)/max(cell_metrics.acg.narrow(:,ii));
                elseif highlightCurrentCell
                    ydata = cell_metrics.acg.narrow(:,ii);
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                end
                if highlightCurrentCell
                    line([-100:100]/2,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-50:10:50]),xlim([-50,50])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.preferences.acgType,'Narrow')
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-30:30]/2,nan(1,1)],length(set1),1)';
                    if plotAcgZscore
                        ydata = [cell_metrics.acg.narrow(41+30:end-40-30,set1)./max(cell_metrics.acg.narrow(41+30:end-40-30,set1));nan(1,length(set1))];
                    else
                        ydata = [cell_metrics.acg.narrow(41+30:end-40-30,set1);nan(1,length(set1))];
                    end
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                end
                if highlightCurrentCell
                    ydata = cell_metrics.acg.narrow(41+30:end-40-30,ii);
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line([-30:30]/2,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-15:5:15]),xlim([-15,15])
                plotAxes.XLabel.String = 'Time (ms)';
            elseif strcmp(UI.preferences.acgType,'Log10')
                if UI.preferences.acgYaxisLog == 1
                    for k = 1:length(classes2plotSubset)
                        set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                        xdata = repmat([general.acgs.log10',nan(1,1)],length(set1),1)';
                        if plotAcgZscore
                            ydata = [cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1));nan(1,length(set1))]; % .*general.acgs.log10
                        else
                            ydata = [cell_metrics.acg.log10(:,set1);nan(1,length(set1))]; % .*general.acgs.log10
                        end
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                    end
                    if highlightCurrentCell
                        ydata = cell_metrics.acg.log10(:,ii);
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(general.acgs.log10,ydata, 'color', 'k','linewidth',1.5,'HitTest','off') % .*general.acgs.log10
                    end
                else
                    for k = 1:length(classes2plotSubset)
                        set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                        xdata = repmat([general.acgs.log10',nan(1,1)],length(set1),1)';
                        if plotAcgZscore
                            ydata = [cell_metrics.acg.log10(:,set1)./max(cell_metrics.acg.log10(:,set1));nan(1,length(set1))];
                        else
                            ydata = [cell_metrics.acg.log10(:,set1);nan(1,length(set1))];
                        end
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                    end
                    if highlightCurrentCell
                        ydata = cell_metrics.acg.log10(:,ii);
                        if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                        line(general.acgs.log10,ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                    end
                end
                xlim([0,10]), set(gca,'xscale','log')
                plotAxes.XLabel.String = 'Time (sec)';
            else
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), plotSubset);
                    xdata = repmat([[-500:500],nan(1,1)],length(set1),1)';
                    if plotAcgZscore
                        ydata = [cell_metrics.acg.wide(:,set1)./max(cell_metrics.acg.wide(:,set1));nan(1,length(set1))];
                    else
                        ydata = [cell_metrics.acg.wide(:,set1);nan(1,length(set1))];
                    end
                    if plotAcgYLog
                            ydata(ydata < 0.1)=0.1;
                        end
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.2],'HitTest','off')
                end
                if highlightCurrentCell
                    ydata = cell_metrics.acg.wide(:,ii);
                    if plotAcgYLog
                        ydata(ydata < 0.1)=0.1;
                    end
                    line([-500:500],ydata, 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xticks([-500:100:500]),xlim([-500,500])
                plotAxes.XLabel.String = 'Time (ms)';
            end
            if plotAcgYLog
                set(plotAxes,'yscale','log')
            else
                set(plotAxes,'yscale','linear')
            end
            
        elseif strcmp(customPlotSelection,'ISIs (image)')
            plotAxes.YLabel.String = ['Cells (sorting: ', UI.preferences.sortingMetric,')'];
            plotAxes.Title.String = customPlotSelection;
            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            
            if strcmp(UI.preferences.isiNormalization,'Rate')
                imagesc(log10(general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Time (sec; log10)';
            elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                imagesc(log10(1./general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_occurrence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Firing rate (log10)';
            else
                imagesc(log10(general.isis.log10)', 1:length(UI.params.subset), cell_metrics.isi.log10_occurrence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                plotAxes.XLabel.String = 'Time (sec; log10)';
            end
            if ~isempty(idx) && highlightCurrentCell
                if strcmp(UI.preferences.isiNormalization,'Firing rates')
                    line(log10(1./general.isis.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                else
                    line(log10(general.isis.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
            end
            colormap(UI.preferences.colormap), axis tight
            ploConnectionsHighlights(xlim,UI.params.subset(burstIndexSorted))
            
        elseif strcmp(customPlotSelection,'ACGs (image)')
            % All ACGs shown in an image (z-scored). Sorted by the burst-index from Royer 2012
            plotAxes.YLabel.String = ['Cells (sorting: ', UI.preferences.sortingMetric,')'];
            plotAxes.Title.String = customPlotSelection;
            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            if strcmp(UI.preferences.acgType,'Normal')
                imagesc([-100:100]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx) && highlightCurrentCell
                    line([-50,50],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off')
                
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.preferences.acgType,'Narrow')
                imagesc([-30:30]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(41+30:end-40-30,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx) & highlightCurrentCell
                    line([-15,15],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off')
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off','linewidth',1.5)
                
                plotAxes.XLabel.String = 'Time (ms)';
                
            elseif strcmp(UI.preferences.acgType,'Log10')
                imagesc(log10(general.acgs.log10)', [1:length(UI.params.subset)], cell_metrics.acg.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx) 
                    line(log10(general.acgs.log10([1,end])),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                plotAxes.XLabel.String = 'Time (sec, log10)';
            else
                imagesc([-500:500], [1:length(UI.params.subset)], cell_metrics.acg.wide_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx) && highlightCurrentCell
                    line([-500,500],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                line([0,0],[0.5,length(UI.params.subset)+0.5],'color','w','HitTest','off')
                plotAxes.XLabel.String = 'Time (ms)';
            end
            colormap(UI.preferences.colormap), axis tight
            ploConnectionsHighlights(xlim,UI.params.subset(burstIndexSorted))
            
        elseif strcmp(customPlotSelection,'firingRateMaps_firingRateMap')
            firingRateMapName = 'firingRateMap';
            % Precalculated firing rate map for the cell
            plotAxes.XLabel.String = 'Position (cm)';
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = 'Firing Rate Map';
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
                set(plotAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'boundaries')
                    boundaries = general.firingRateMaps.(firingRateMapName).boundaries(:)';
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
                if UI.preferences.firingRateMap.showHeatmap
                    imagesc(x_bins,1:size(firingRateMap,2),firingRateMap','HitTest','off');
                    if UI.preferences.firingRateMap.showHeatmapColorbar
                        colorbar
                    end
                    plotAxes.YLabel.String = '';
                else
                    plt1 = line(x_bins,firingRateMap,'LineStyle','-','linewidth',2, 'HitTest','off');
                    grid on, plotAxes.YLabel.String = 'Rate (Hz)';
                end
                
                axis tight, ax6 = axis;
                set(plotAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName)
                    if UI.preferences.firingRateMap.showLegend
                        if UI.preferences.firingRateMap.showHeatmap
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
                        boundaries = general.firingRateMaps.(firingRateMapName).boundaries(:)';
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
                    boundaries = general.psth.(eventName).boundaries(:)';
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'boundaries')
                    boundaries = general.psth.(eventName).boundaries(:)';
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
                set(plotAxes, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,'Spike raster')
            if isfield(cell_metrics,'spikes') && numel(cell_metrics.spikes.times)>=ii && ~isempty(cell_metrics.spikes.times{ii})
                % ii,general,batchIDs,plotAxes
                plotAxes.XLabel.String = 'Time (s)';
                plotAxes.Title.String = 'Spike raster';
                if strcmp(UI.preferences.raster,'cv2')
                    line(cell_metrics.spikes.times{ii},spikes2cv2(cell_metrics.spikes.times{ii}),'HitTest','off','Marker','.','LineStyle','none','color', [0.5 0.5 0.5 0.5]), axis tight
                    plotAxes.YLabel.String = 'CV_2';
                elseif strcmp(UI.preferences.raster,'ISIs')
                    line(cell_metrics.spikes.times{ii},spikes2isi(cell_metrics.spikes.times{ii}),'HitTest','off','Marker','.','LineStyle','none','color', [0.5 0.5 0.5 0.5]), axis tight
                    plotAxes.YLabel.String = 'ISIs (ms)';
                elseif strcmp(UI.preferences.raster,'random')
                    line(cell_metrics.spikes.times{ii},rand(size(cell_metrics.spikes.times{ii})),'HitTest','off','Marker','.','LineStyle','none','color', [0.5 0.5 0.5 0.5]), axis tight
                    plotAxes.YLabel.String = 'Random';
                end 
                axis tight, ax6 = axis; 
                if isfield(general,'epochs')
                    epochVisualization(general.epochs,plotAxes,-0.1*ax6(4),-0.005*ax6(4),ax6(4));
                    axis tight, ax6 = axis;
                end

                plotTemporalStates
                plotTemporalRestriction
                
                if isfield(general.responseCurves.firingRateAcrossTime,'boundaries') && ~isfield(general,'epochs')
                    boundaries = general.responseCurves.firingRateAcrossTime.boundaries(:)';
                    if isfield(general.responseCurves.firingRateAcrossTime,'boundaries_labels')
                        boundaries_labels = general.responseCurves.firingRateAcrossTime.boundaries_labels;
                        if length(boundaries_labels) == length(boundaries)
                            text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',0.5);
                        end
                    end
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No spike data','FontWeight','bold','HorizontalAlignment','center')
            end
            
        elseif contains(customPlotSelection,'RCs_') && ~contains(customPlotSelection,'Phase') && ~contains(customPlotSelection,'(image)') && ~contains(customPlotSelection,'(all)')
            responseCurvesName = customPlotSelection(5:end);
            plotAxes.XLabel.String = 'Time (s)';
            plotAxes.YLabel.String = 'Rate (Hz)';
            plotAxes.Title.String = responseCurvesName;
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                firingRateAcrossTime = cell_metrics.responseCurves.(responseCurvesName){ii};
                if isfield(general.responseCurves,responseCurvesName) && isfield(general.responseCurves.(responseCurvesName),'x_bins') && length(firingRateAcrossTime) == length(general.responseCurves.(responseCurvesName).x_bins)
                    x_bins = general.responseCurves.(responseCurvesName).x_bins;
                else
                    x_bins = [1:length(firingRateAcrossTime)];
                end
                plt1 = line(x_bins,firingRateAcrossTime,'color', 'k','linewidth',2, 'HitTest','off');
                subsetPlots = plotConnectionsCurves(x_bins,cell_metrics.responseCurves.(responseCurvesName));

                
                axis tight, ax6 = axis; 
                if strcmpi(customPlotSelection,'RCs_firingRateAcrossTime')
                    if isfield(general,'epochs')
                        epochVisualization(general.epochs,plotAxes,-0.1*ax6(4),-0.005*ax6(4),ax6(4));
                        axis tight, ax6 = axis;
                    end
                    plotTemporalStates
                    plotTemporalRestriction
                end
                
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries(:)';
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',0.5);
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
                [~,troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset222));
                
                Zdata = horzcat(cell_metrics.responseCurves.(responseCurvesName){subset222(troughToPeakSorted)});
                
                imagesc(Xdata,Ydata,(Zdata./max(Zdata))','HitTest','off'),
                [~,idx] = find(subset222(troughToPeakSorted) == ii);
                colormap(UI.preferences.colormap), axis tight
                if ~isempty(idx) && highlightCurrentCell
                    line([Xdata(1),Xdata(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
                end
                
                % Synaptic partners are also displayed
                subset1 = cell_metrics.UID(subset222);
                ploConnectionsHighlights(Xdata,subset1(troughToPeakSorted));
                
                axis tight, ax6 = axis; 
                if contains(customPlotSelection,'RCs_firingRateAcrossTime')
                    if isfield(general,'epochs')
                        epochVisualization(general.epochs,plotAxes,-0.1*ax6(4),-0.005*ax6(4),ax6(4));
                        axis tight, ax6 = axis;
                    end
                    plotTemporalStates
                    plotTemporalRestriction
                end
                
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries(:)';
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
                
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), subset222);
                    xdata = repmat([Xdata,nan(1,1)],length(set1),1)';
                    ydata = [horzcat(cell_metrics.responseCurves.(responseCurvesName){set1});nan(1,length(set1))];
                    line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.5],'HitTest','off')
                end
                
                Zdata = horzcat(cell_metrics.responseCurves.(responseCurvesName){subset222});
                idx9 = subset222 == ii;
                if any(idx9) && highlightCurrentCell
                    line(Xdata,Zdata(:,idx9),'color', 'k','linewidth',2, 'HitTest','off'),
                end
                axis tight
                subsetPlots.xaxis = Xdata;
                subsetPlots.yaxis = Zdata;
                subsetPlots.subset = subset222;

                axis tight, ax6 = axis; 
                if contains(customPlotSelection,'RCs_firingRateAcrossTime')
                    if isfield(general,'epochs')
                        epochVisualization(general.epochs,plotAxes,-0.1*ax6(4),-0.005*ax6(4),ax6(4));
                        axis tight, ax6 = axis;
                    end
                    plotTemporalStates
                    plotTemporalRestriction
                end
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries(:)';
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none', 'Color', 'k','BackgroundColor',[1 1 1 0.7],'margin',0.5);
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
            [~,idx] = find(UI.params.subset(UI.preferences.troughToPeakSorted) == ii);
            
            imagesc(UI.x_bins.thetaPhase, [1:length(UI.params.subset)], cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset(UI.preferences.troughToPeakSorted))','HitTest','off'),
            colormap(UI.preferences.colormap),
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            % selected cell highlighted in white
            if ~isempty(idx)
                line([UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','color','w','HitTest','off','linewidth',1.5)
            end
            ploConnectionsHighlights(xlim,UI.params.subset(UI.preferences.troughToPeakSorted))
            
        elseif contains(customPlotSelection,'RCs_') && contains(customPlotSelection,'(all)')
            
            responseCurvesName = customPlotSelection(5:end-6);
            plotAxes.XLabel.String = 'Phase';
            plotAxes.YLabel.String = 'z-scored distribution';
            plotAxes.Title.String = responseCurvesName;
            % All responseCurves colored according to cell type
            for k = 1:length(classes2plotSubset)
                set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), UI.params.subset);
                xdata = repmat([UI.x_bins.thetaPhase,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.responseCurves.thetaPhase_zscored(:,set1);nan(1,length(set1))];
                line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.5],'HitTest','off')
            end
            % selected cell in black
            if highlightCurrentCell
                line(UI.x_bins.thetaPhase, cell_metrics.responseCurves.thetaPhase_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            end
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
                            text(1,0.5,['Duration (' num2str(min(duration)),' => ',num2str(max(duration)),' sec)'],'color','r','HorizontalAlignment','left','VerticalAlignment','bottom','rotation',90,'Interpreter', 'none','HitTest','off','Units','normalized')
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
                        if isfield(spikesPlots.(customPlotSelection),'eventIDlabels') &&  spikesPlots.(customPlotSelection).eventIDlabels && isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'eventIDlabels')
                            text(0.02,0.98,events.(spikesPlots.(customPlotSelection).event){batchIDs}.eventIDlabels,'HorizontalAlignment','left','VerticalAlignment','top', 'Color', 'k','BackgroundColor',[1 1 1 0.8],'margin',0.1,'HitTest','off','Units','normalized')
                        end
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
                    if ~isempty(UI.params.subset) && UI.preferences.dispLegend == 1
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
            
        elseif contains(customPlotSelection,{'Waveforms (peakVoltage_all)'})
            
            plotAxes.XLabel.String = 'Channels';
            plotAxes.YLabel.String = ['Voltage (',char(181),'V)'];
            plotAxes.Title.String = customPlotSelection;
            if isfield(cell_metrics.waveforms,'peakVoltage_all') && ~isempty(cell_metrics.waveforms.peakVoltage_all{ii})
                switch UI.preferences.peakVoltage_all_sorting
                    case 'channelOrder'
                        if isfield(general,'electrodeGroups') && isfield(general,'electrodeGroups') && ~isempty(cell_metrics.waveforms.filt_all{ii}) && ~isempty(cell_metrics.waveforms.time_all{ii})
                            channelOrder = [general.electrodeGroups{:}];
                            if numel(channelOrder) > size(cell_metrics.waveforms.filt_all{ii},1)
                                channelOrder = 1:size(cell_metrics.waveforms.filt_all{ii},1);
                            end
                            plotAxes.XLabel.String = 'Channels (sorted by channel order)';
                        else
                            channelOrder = 1:numel(cell_metrics.waveforms.peakVoltage_all{ii});
                        end
                    case 'amplitude'
                        plotAxes.XLabel.String = 'Channels (sorted by amplitude)';
                        [~, channelOrder]= sort(cell_metrics.waveforms.peakVoltage_all{ii},'descend');
                    case 'none'
                        channelOrder = 1:numel(cell_metrics.waveforms.channels_all{ii});
                end
                if UI.preferences.peakVoltage_session
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                    subset1 = UI.params.subset(subset1);
                    Xdata = [];
                    Ydata = [];
                    subset2 = [];
                    for k = 1:length(classes2plotSubset)
                        set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), subset1);
                        if ~isempty(set1)
                            xdata = repmat([1:numel(cell_metrics.waveforms.peakVoltage_all{ii}),nan(1,1)],length(set1),1)';
                            ydata = vertcat(cell_metrics.waveforms.peakVoltage_all{set1})';
                            if strcmp(UI.preferences.peakVoltage_all_sorting,'amplitude')
                                ydata = [sort(ydata,'descend');nan(1,length(set1))];
                            else
                                ydata = [ydata(channelOrder,:);nan(1,length(set1))];
                            end
                            line(xdata(:),ydata(:), 'color', [UI.classes.colors(k,:),0.5],'HitTest','off')
                            Xdata = [Xdata,xdata];
                            Ydata = [Ydata,ydata];
                            subset2 = [subset2,set1];
                        end
                    end
                    subsetPlots.xaxis = Xdata;
                    subsetPlots.yaxis = Ydata;
                    subsetPlots.subset = subset2;
                end
                line(1:numel(cell_metrics.waveforms.peakVoltage_all{ii}),cell_metrics.waveforms.peakVoltage_all{ii}(channelOrder), 'color', col,'linewidth',2,'HitTest','off','Marker','.')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif contains(customPlotSelection,{'Waveforms ('})
            
            plotAxes.XLabel.String = 'Time (ms)';
            plotAxes.YLabel.String = ['Voltage (',char(181),'V)'];
            plotAxes.Title.String = customPlotSelection;
            field2plot = customPlotSelection(12:end-1);
            if isfield(cell_metrics.waveforms,field2plot) && ~isempty(cell_metrics.waveforms.(field2plot){ii})
                if size(cell_metrics.waveforms.(field2plot){ii},1)>1
                    imagesc(cell_metrics.waveforms.(field2plot){ii},'HitTest','off')
                else
                    line(1:numel(cell_metrics.waveforms.(field2plot){ii}),cell_metrics.waveforms.(field2plot){ii}, 'color', col,'linewidth',2,'HitTest','off')
                end
                if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                    plotInsetChannelMap(ii,col,general,1,axnum);
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
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
                    boundaries = general.(customPlotSelection).boundaries(:)';
                    if isfield(general.(customPlotSelection),'boundaries_labels')
                        boundaries_labels = general.(customPlotSelection).boundaries_labels;
                        text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    line([1;1] * boundaries, [ax6(3) ax6(4)],'LineStyle','--','color','k', 'HitTest','off');
                end
            end
        end
        
        function subsetPlots = plotConnectionsCurves(x_bins,ydata)
            subsetPlots.xaxis = x_bins;
            subsetPlots.yaxis = [];
            subsetPlots.subset = [];
            if ~isempty(UI.params.putativeSubse) && UI.preferences.plotExcitatoryConnections
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
            if ~isempty(UI.params.putativeSubse_inh) &&  UI.preferences.plotInhibitoryConnections
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
            if UI.preferences.plotExcitatoryConnections
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(UI.params.outbound) && any(ismember(subset1,(UI.params.outgoing)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.outgoing));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','m','HitTest','off', 'MarkerSize',12)
                        end
                        if ~isempty(UI.params.inbound) && any(ismember(subset1,(UI.params.incoming)))
                            [~,y_pos,~] = intersect(subset1,(UI.params.incoming));
                            line(x1*ones(size(y_pos)),y_pos,'Marker','.','LineStyle','none','color','b','HitTest','off', 'MarkerSize',12)
                        end
                        xlim([Xdata(1)-x_range*0.025,Xdata(end)])
                end
            end
            if UI.preferences.plotInhibitoryConnections
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
        
        function plotTemporalStates
            if isfield(general,'states')
                stateData = fieldnames(general.states);
                k_offset = ax6(3);
                clr_states = eval([UI.preferences.colormapStates,'(',num2str(1+max(structfun(@(X) numel(fields(X)),general.states))),')']);
                clr_states = 1-(1-clr_states)*0.7;
                for j = 1:numel(stateData)
                    states1  = general.states.(stateData{j});
                    stateNames = fieldnames(states1);
                    for jj = 1:numel(stateNames)
                        if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
                            patch(double([states1.(stateNames{jj}),flip(states1.(stateNames{jj}),2)])',k_offset+ax6(4)*[-0.005;-0.005;-0.1;-0.1]*ones(1,size(states1.(stateNames{jj}),1)),clr_states(jj,:),'EdgeColor',clr_states(jj,:),'HitTest','off')
                        end
                    end
                    k_offset = k_offset - .1*ax6(4);
                    text(ax6(1),k_offset,[stateData{j}, ' (',num2str(numel(stateNames)),')'],'VerticalAlignment', 'bottom','HorizontalAlignment','left', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',0.1)
                    ylim([k_offset,ax6(4)])
                end
                ax6 = axis;
            end
        end
        
        function plotTemporalRestriction
            k_offset = ax6(3);
            if isfield(cell_metrics.general,'restrictToIntervals')
                states1  = cell_metrics.general.restrictToIntervals;
                patch(double([states1,flip(states1,2)])',k_offset+ax6(4)*[-0.005;-0.005;-0.1;-0.1]*ones(1,size(states1,1)),[0.2 0.2 0.8],'EdgeColor',[0.2 0.2 0.8],'HitTest','off')
                k_offset = k_offset - .1*ax6(4);
                text(ax6(1),k_offset*ax6(4),'restrictToIntervals','VerticalAlignment', 'bottom','HorizontalAlignment','left', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',0.1)
%                 ylim([k_states*ax6(4),ax6(4)])
            end
            if isfield(cell_metrics.general,'excludeIntervals')
                states1  = cell_metrics.general.excludeIntervals;
                patch(double([states1,flip(states1,2)])',k_offset+ax6(4)*[-0.005;-0.005;-0.1;-0.1]*ones(1,size(states1,1)),[0.2 0.2 0.8],'EdgeColor',[0.2 0.2 0.8],'HitTest','off')
                k_offset = k_offset - .1*ax6(4);
                text(ax6(1),k_offset*ax6(4),'excludeIntervals','VerticalAlignment', 'bottom','HorizontalAlignment','left', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',0.1)
            end
            ylim([k_offset,ax6(4)])
            ax6 = axis;
        end
        
        function raster = spikes2isi(spikes_times)
            if ~isempty(spikes_times)
                raster = [1./diff(spikes_times);nan];
                raster(raster>800) = nan;
            else
                raster = [];
            end
            
        end
        function raster = spikes2cv2(spikes_times)
            ISIs = diff(spikes_times);
            raster = [nan;2.*abs(ISIs(2:end)-ISIs(1:end-1))./(ISIs(2:end)+ISIs(1:end-1));nan];
        end
    end
    
    function densityPlot(X1,handle23,FaceColor,EdgeColor,logAxis)
        if logAxis
            X1 = X1(X1>0 & ~isinf(X1) & ~isnan(X1));
            X1 = X1(X1>0);
            X1 = log10(X1);
        else
            X1 = X1(~isinf(X1) & ~isnan(X1));
        end
        [f, Xi] = ksdensity(X1, 'bandwidth', [],'Function','pdf');
        if logAxis
            Xi = 10.^Xi;
        end
        if strcmp(UI.preferences.rainCloudNormalization,'Peak')
            f = f/max(f);
        elseif strcmp(UI.preferences.rainCloudNormalization,'Count')
            f = f/sum(f)*numel(X1);
        else % Probability
            f = f/sum(f);
        end
        area(Xi,f, 'FaceColor', FaceColor, 'EdgeColor', EdgeColor, 'LineWidth', 1, 'FaceAlpha', 0.4,'HitTest','off', 'Parent', handle23); hold on
    end
    
    function x_bins = densityPlotRefData(X1,handle23,lineColors,logAxis,xlim1,groundTruthData)
        
%         % % %
%         idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
%         clusClas_list = unique(groundTruthData.clusClas(idx));
%         line_histograms_X = []; line_histograms_Y = [];
%         
%         if ~any(isnan(groundTruthData1.y)) || ~any(isinf(groundTruthData1.y))
%             for m = 1:length(clusClas_list)
%                 idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
%                 line_histograms_X(:,m) = ksdensity(xdata(idx(idx1)),groundTruthData1.x);
%             end
%             if UI.checkbox.logx.Value == 0
%                 legendScatter2 = line(groundTruthData1.x,line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
%             else
%                 legendScatter2 = line(10.^(groundTruthData1.x),line_histograms_X./max(line_histograms_X),'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', h_scatter(2));
%             end
%             set(legendScatter2, {'color'}, num2cell(UI.classes.colors3,2));
%         end
%         % % %
        if logAxis
            X1 = X1(X1>0 & ~isinf(X1) & ~isnan(X1));
            X1 = X1(X1>0);
            x_bins = linspace(log10(nanmin([xlim1(1),X1])),log10(nanmax([xlim1(2),X1])),UI.preferences.binCount);
            X1 = log10(X1);
        else
            X1 = X1(~isinf(X1) & ~isnan(X1));
            x_bins = linspace(nanmin([xlim1(1),X1]),nanmax([xlim1(2),X1]),UI.preferences.binCount);
        end
        
        line_histograms = [];
        idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
        clusClas_list = unique(groundTruthData.clusClas(idx));
        
        for m = 1:length(clusClas_list)
            idx1 = find(groundTruthData.clusClas(idx)==clusClas_list(m));
            X2 = X1(idx(idx1));
            f = ksdensity(X2,x_bins, 'bandwidth', [],'Function','pdf');
            
            if strcmp(UI.preferences.rainCloudNormalization,'Peak')
                f = f/max(f);
            elseif strcmp(UI.preferences.rainCloudNormalization,'Count')
                f = f/sum(f)*numel(X2);
            else % Probability
                f = f/sum(f);
            end
            line_histograms_X(:,m) = f;
        end
        if logAxis
            Xi = 10.^x_bins;
        else
            Xi = x_bins;
        end
        lineData = line(Xi,line_histograms_X,'LineStyle','-','linewidth',1,'HitTest','off', 'Parent', handle23); hold on
        set(lineData, {'color'}, lineColors);
                    
%         area(x_bins,f, 'FaceColor', FaceColor, 'EdgeColor', EdgeColor, 'LineWidth', 1, 'FaceAlpha', 0.4,'HitTest','off', 'Parent', handle23); hold on
    end
    
    function plotGroudhTruthCells(plotX1,plotY1)
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(UI.groupData1)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX1(idx_groupData), plotY1(idx_groupData),'Marker',UI.preferences.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.preferences.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
    end
    
    
    function plotGroupData(plotX1,plotY1,plotConnections1,highlightCurrentCell)
        if ~isempty(UI.classes.colors)
            ce_gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), UI.classes.plot(UI.params.subset), UI.classes.colors,UI.preferences.markerSize,'.');
        end
        if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX1(UI.cells.excitatory_subset), plotY1(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{1},'HitTest','off')
        end
        if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX1(UI.cells.inhibitory_subset), plotY1(UI.cells.inhibitory_subset),'Marker','s','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{2},'HitTest','off')
        end
        if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX1(UI.cells.excitatoryPostsynaptic_subset), plotY1(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{3},'HitTest','off')
        end
        if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX1(UI.cells.inhibitoryPostsynaptic_subset), plotY1(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{4},'HitTest','off')
        end
        
        % Plots putative connections
        if plotConnections1 == 1
            plotPutativeConnections(plotX1,plotY1,UI.monoSyn.disp)
        end
        
        % Plots X marker for selected cell
        if highlightCurrentCell
            line(plotX1(ii), plotY1(ii),'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
            line(plotX1(ii), plotY1(ii),'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
        end
        
        % Plots tagged cells ('tags','groups','groundTruthClassification')
        if ~isempty(UI.groupData1)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                            idx_groupData = intersect(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                            line(plotX1(idx_groupData), plotY1(idx_groupData),'Marker',UI.preferences.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.preferences.groupDataMarkers{jj}(2),'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                        end
                    end
                end
            end
        end
        
        % Plots sticky selection
        if UI.preferences.stickySelection
            line(plotX1(UI.params.ClickedCells),plotY1(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
        end
    end

    function plotGroupScatter(plotX1,plotY1)
        if ~isempty(UI.classes.colors)
            ce_gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), UI.classes.plot(UI.params.subset), UI.classes.colors,UI.preferences.markerSize,'.');
        end
        if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(plotX1(UI.cells.excitatory_subset), plotY1(UI.cells.excitatory_subset),'Marker','^','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{1}, 'HitTest','off')
        end
        if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(plotX1(UI.cells.inhibitory_subset), plotY1(UI.cells.inhibitory_subset),'Marker','o','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{2}, 'HitTest','off')
        end
        if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(plotX1(UI.cells.excitatoryPostsynaptic_subset), plotY1(UI.cells.excitatoryPostsynaptic_subset),'Marker','v','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{3}, 'HitTest','off')
        end
        if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(plotX1(UI.cells.inhibitoryPostsynaptic_subset), plotY1(UI.cells.inhibitoryPostsynaptic_subset),'Marker','*','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{4}, 'HitTest','off')
        end
    end

    function plotMarker(plotX1,plotY1)
        line(plotX1, plotY1,'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        line(plotX1, plotY1,'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
    end

    function plotMarker3(plotX1,plotY1,plotZ1)
        line(plotX1, plotY1, plotZ1,'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        line(plotX1, plotY1, plotZ1,'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
    end
    
    function UI = defineSynapticConnections(UI)
        % Defining putative connections for selected cells
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && ~isempty(cell_metrics.putativeConnections.excitatory)
            UI.params.putativeSubse = find(all(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)'));
        else
            UI.params.putativeSubse=[];
            UI.params.incoming = [];
            UI.params.outgoing = [];
            UI.params.connections = [];
        end
        
        % Excitatory connections
        if ~isempty(UI.params.putativeSubse)
            UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
            UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
            
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
            UI.params.putativeSubse_inh = find(all(ismember(cell_metrics.putativeConnections.inhibitory,UI.params.subset)'));
        else
            UI.params.putativeSubse_inh = [];
        end
        
        % Inhibitory connections
        if ~isempty(UI.params.putativeSubse_inh)
            UI.params.b1 = cell_metrics.putativeConnections.inhibitory(UI.params.putativeSubse_inh,1);
            UI.params.b2 = cell_metrics.putativeConnections.inhibitory(UI.params.putativeSubse_inh,2);
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
    end
    
    function plotLinearFits(plotX,plotY)
        plotClas_subset = UI.classes.plot(UI.params.subset);
        ids = nanUnique(plotClas_subset);
        xlim11 = xlim;
        ylim11 = ylim;
        if UI.checkbox.logx.Value==1
            X1 = log10(plotX);
        else
            X1 = plotX;
        end
        if UI.checkbox.logy.Value==1
            Y1 = log10(plotY);
        else
            Y1 = plotY;
        end
        textconcat = {};
        for m = 1:length(unique(UI.classes.plot(UI.params.subset)))
            temp1 = UI.params.subset(find(plotClas_subset==ids(m)));
            idx = find(plotClas_subset==ids(m));
            fitEnds = [nanmin(X1(temp1)),nanmax(X1(temp1))];
            if length(temp1)>1
                P = polyfit(X1(temp1),Y1(temp1),1);
                yfit = P(1)*fitEnds+P(2);
                if UI.checkbox.logx.Value==1
                    fitEnds = 10.^(fitEnds);
                end
                if UI.checkbox.logy.Value==1
                    yfit = 10.^(yfit);
                end
                [r,p1] = corrcoef(X1(temp1),Y1(temp1),'Rows','complete');
                if p1(2,1)<0.003
                    p1_text = ' **';
                elseif p1(2,1)<0.05
                    p1_text = ' *';
                else
                    p1_text = '';
                end
                line(fitEnds,yfit,'color',UI.classes.colors(m,:), 'LineWidth', 1.5, 'HitTest','off');
                textconcat(m) = {['\bf\color[rgb]{',num2str(UI.classes.colors(m,:)),'} r = ' num2str(r(2,1)), p1_text]};
%                 text(0.02,1.02-0.04*m,['r = ' num2str(r(2,1)), p1_text],'Color',UI.classes.colors(m,:),'BackgroundColor',[1 1 1 0.8],'margin',1,'FontWeight','bold', 'HitTest','off','Units','normalized')
            end
        end
        text(0.02,0.98,textconcat,'BackgroundColor',[1 1 1 0.8],'margin',0.1,'HitTest','off','Units','normalized','interpreter','tex','VerticalAlignment','top')
    end
    
    function plotPutativeConnections(plotX1,plotY1,monoSynDisp,subset1)
        if exist('subset1','var')
            UI1 = UI;
            UI1.params.subset = subset1;
            UI1 = defineSynapticConnections(UI1);
        else
            UI1 = UI;
        end
        % Plots putative excitatory connections
        if ~isempty(UI1.params.putativeSubse) && UI1.preferences.plotExcitatoryConnections
            switch monoSynDisp
                case 'All'
                    xdata = [plotX1(UI1.params.a1);plotX1(UI1.params.a2);nan(1,length(UI1.params.a2))];
                    ydata = [plotY1(UI1.params.a1);plotY1(UI1.params.a2);nan(1,length(UI1.params.a2))];
                    line(xdata(:),ydata(:),'color','k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI1.params.inbound)
                        xdata = [plotX1(UI1.params.incoming);plotX1(UI1.params.a2(UI1.params.inbound));nan(1,length(UI1.params.a2(UI1.params.inbound)))];
                        ydata = [plotY1(UI1.params.incoming);plotY1(UI1.params.a2(UI1.params.inbound));nan(1,length(UI1.params.a2(UI1.params.inbound)))];
                        line(xdata,ydata,'color','b','HitTest','off')
                    end
                    if ~isempty(UI1.params.outbound)
                        xdata = [plotX1(UI1.params.a1(UI1.params.outbound));plotX1(UI1.params.outgoing);nan(1,length(UI1.params.outgoing))];
                        ydata = [plotY1(UI1.params.a1(UI1.params.outbound));plotY1(UI1.params.outgoing);nan(1,length(UI1.params.outgoing))];
                        line(xdata(:),ydata(:),'color','m','HitTest','off')
                    end
            end
        end
        % Plots putative inhibitory connections
        if ~isempty(UI1.params.putativeSubse_inh) && UI1.preferences.plotInhibitoryConnections
            switch monoSynDisp
                case 'All'
                    xdata_inh = [plotX1(UI1.params.b1);plotX1(UI1.params.b2);nan(1,length(UI1.params.b2))];
                    ydata_inh = [plotY1(UI1.params.b1);plotY1(UI1.params.b2);nan(1,length(UI1.params.b2))];
                    line(xdata_inh(:),ydata_inh(:),'LineStyle','--','HitTest','off','color',[0.5 0.5 0.5])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI1.params.inbound_inh)
                        xdata_inh = [plotX1(UI1.params.incoming_inh);plotX1(UI1.params.b2(UI1.params.inbound_inh));nan(1,length(UI1.params.b2(UI1.params.inbound_inh)))];
                        ydata_inh = [plotY1(UI1.params.incoming_inh);plotY1(UI1.params.b2(UI1.params.inbound_inh));nan(1,length(UI1.params.b2(UI1.params.inbound_inh)))];
                        line(xdata_inh,ydata_inh,'LineStyle','--','color','r','HitTest','off')
                    end
                    if ~isempty(UI1.params.outbound_inh)
                        xdata_inh = [plotX1(UI1.params.b1(UI1.params.outbound_inh));plotX1(UI1.params.outgoing_inh);nan(1,length(UI1.params.outgoing_inh))];
                        ydata_inh = [plotY1(UI1.params.b1(UI1.params.outbound_inh));plotY1(UI1.params.outgoing_inh);nan(1,length(UI1.params.outgoing_inh))];
                        line(xdata_inh(:),ydata_inh(:),'LineStyle','--','color','c','HitTest','off')
                    end
            end
        end
    end
    
    function plotPutativeConnections3(plotX1,plotY1,plotZ1,monoSynDisp)
        % Plots putative excitatory connections
        if ~isempty(UI.params.putativeSubse) && UI.preferences.plotExcitatoryConnections
            switch monoSynDisp
                case 'All'
                    xdata = [plotX1(UI.params.a1);plotX1(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY1(UI.params.a1);plotY1(UI.params.a2);nan(1,length(UI.params.a2))];
                    zdata = [plotZ1(UI.params.a1);plotZ1(UI.params.a2);nan(1,length(UI.params.a2))];
                    line(xdata(:),ydata(:),zdata(:),'color','k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX1(UI.params.incoming);plotX1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY1(UI.params.incoming);plotY1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        zdata = [plotZ1(UI.params.incoming);plotZ1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        line(xdata,ydata,zdata,'color','b','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX1(UI.params.a1(UI.params.outbound));plotX1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY1(UI.params.a1(UI.params.outbound));plotY1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        zdata = [plotZ1(UI.params.a1(UI.params.outbound));plotZ1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        line(xdata(:),ydata(:),zdata(:),'color','m','HitTest','off')
                    end
            end
        end
        % Plots putative inhibitory connections
        if ~isempty(UI.params.putativeSubse_inh) && UI.preferences.plotInhibitoryConnections
            switch monoSynDisp
                case 'All'
                    xdata_inh = [plotX1(UI.params.b1);plotX1(UI.params.b2);nan(1,length(UI.params.b2))];
                    ydata_inh = [plotY1(UI.params.b1);plotY1(UI.params.b2);nan(1,length(UI.params.b2))];
                    zdata_inh = [plotZ1(UI.params.b1);plotZ1(UI.params.b2);nan(1,length(UI.params.b2))];
                    line(xdata_inh(:),ydata_inh(:),zdata_inh(:),'LineStyle','--','HitTest','off','color',[0.5 0.5 0.5])
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound_inh)
                        xdata_inh = [plotX1(UI.params.incoming_inh);plotX1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        ydata_inh = [plotY1(UI.params.incoming_inh);plotY1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        zdata_inh = [plotZ1(UI.params.incoming_inh);plotZ1(UI.params.b2(UI.params.inbound_inh));nan(1,length(UI.params.b2(UI.params.inbound_inh)))];
                        line(xdata_inh,ydata_inh,zdata_inh,'LineStyle','--','color','r','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound_inh)
                        xdata_inh = [plotX1(UI.params.b1(UI.params.outbound_inh));plotX1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        ydata_inh = [plotY1(UI.params.b1(UI.params.outbound_inh));plotY1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        zdata_inh = [plotZ1(UI.params.b1(UI.params.outbound_inh));plotZ1(UI.params.outgoing_inh);nan(1,length(UI.params.outgoing_inh))];
                        line(xdata_inh(:),ydata_inh(:),zdata_inh(:),'LineStyle','--','color','c','HitTest','off')
                    end
            end
        end
    end

    function out = plotInsetChannelMap(cellID,col,general,plots,axnum)
        % Displays a map of the channel configuration and highlights current cell
        padding = 0.03;
        if plots
            xlim1 = xlim;
            ylim1 = ylim;
            zlim1 = zlim;
            UI.zoom.global{axnum}(1,:) = xlim1;
            UI.zoom.global{axnum}(2,:) = ylim1;
            UI.zoom.global{axnum}(3,:) = zlim1;
            UI.zoom.globalLog{axnum} = [0,0,0];
        else
%             axnum = getAxisBelowCursor;
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
            if UI.preferences.channelMapColoring
                subset1 = cellIds;
                for k = 1:length(classes2plotSubset)
                    set1 = intersect(find(UI.classes.plot==classes2plotSubset(k)), subset1);
                    line(chanCoords.x1(set1),chanCoords.y1(set1),'Marker','.','LineStyle','none','color',[UI.classes.colors(k,:),0.2],'markersize',10,'HitTest','off')
                end
                plotPutativeConnections(chanCoords.x1,chanCoords.y1,'Selected')
                plotMarker(chanCoords.x1(cellID),chanCoords.y1(cellID))
            else
                line(chanCoords.x1(cellIds),chanCoords.y1(cellIds),'Marker','.','LineStyle','none','color',[0.5 0.5 0.5],'markersize',10,'HitTest','off')
                plotPutativeConnections(chanCoords.x1,chanCoords.y1,'Selected')
                line(chanCoords.x1(cellID),chanCoords.y1(cellID),'Marker','.','LineStyle','none','color',col,'markersize',17,'HitTest','off')
            end
        end
        
        function chanCoords = reallign(chanCoords_x,chanCoords_y)
            chanCoords.x = rescale_vector2(chanCoords_x,chanCoords_x) * xlim2 * chan_width + xlim1(1) + xlim2*(1-chan_width-padding);
            chanCoords.y = rescale_vector2(chanCoords_y,chanCoords_y) * ylim2 * chan_height + ylim1(1) + ylim2*padding;
            if isfield(cell_metrics,'trilat_x') &&  UI.preferences.plotInsetChannelMap > 2
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
        
        if strcmp(UI.preferences.acgType,'Normal')
            chanCoords = reallign([-100:100]', normalize_range(cell_metrics.acg.narrow(:,cellID)));
        elseif strcmp(UI.preferences.acgType,'Narrow')
            chanCoords = reallign([-30:30]', normalize_range(cell_metrics.acg.narrow(71:71+60,cellID)));
        elseif strcmp(UI.preferences.acgType,'Log10') && isfield(general,'acgs') && isfield(general.acgs,'log10')
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
            cell_metrics.general.basepath = path;
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
        UI.preferences.displayExcitatory = ~UI.preferences.displayExcitatory;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.preferences.displayExcitatory
            UI.menu.monoSyn.highlightExcitatory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightExcitatory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightInhibitoryCells(~,~)
        % Highlight inhibitory cells
        UI.preferences.displayInhibitory = ~UI.preferences.displayInhibitory;
        MsgLog(['Toggle highlighting inhibitory cells (circles), Count: ', num2str(length(UI.cells.inhibitory))])
        if UI.preferences.displayInhibitory
            UI.menu.monoSyn.highlightInhibitory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightInhibitory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightExcitatoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.preferences.displayExcitatoryPostsynapticCells = ~UI.preferences.displayExcitatoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.preferences.displayExcitatoryPostsynapticCells
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'on';
        else
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function highlightInhibitoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.preferences.displayInhibitoryPostsynapticCells = ~UI.preferences.displayInhibitoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (diamonds). Count: ', num2str(length(UI.cells.excitatory))])
        if UI.preferences.displayInhibitoryPostsynapticCells
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
                cell_metrics1 = loadCellMetricsBatch('basenames',cell_metrics.general.basenames,'basepaths',cell_metrics.general.basepaths,'waitbar_handle',ce_waitbar);
                if ~isempty(cell_metrics1)
                    cell_metrics = cell_metrics1;
                else
                    return
                end
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
            if isfield(cell_metrics.general,'basepath') && exist(cell_metrics.general.basepath,'dir')
                path1 = cell_metrics.general.basepath;
                file = fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename,'.cell_metrics.cellinfo.mat']);
            end
            if exist(file,'file')
                load(file);
                initializeSession;
                uiresume(UI.fig);
                cell_metrics.general.basepath = path1;
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
            backupList = dir(fullfile(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)},'revisions_cell_metrics','cell_metrics_*'));
        else
            backupList = dir(fullfile(cell_metrics.general.basepath,'revisions_cell_metrics','cell_metrics_*'));
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
                cell_metrics_backup = load(fullfile(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)},'revisions_cell_metrics',backupToRestore));
            else
                cell_metrics_backup = load(fullfile(cell_metrics.general.basepath,'revisions_cell_metrics',backupToRestore));
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
                UI.preferences.tags = unique([UI.preferences.tags fieldnames(cell_metrics.tags)']);
                initTags
                updateTags
                if isfield(UI.preferences,'groundTruthClassification')
                    UI.preferences.groundTruthClassification = unique([UI.preferences.groundTruthClassification fieldnames(cell_metrics.groundTruthClassification)']);
                    delete(UI.togglebutton.groundTruthClassification)
                    createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.preferences.groundTruth,'G/T')
                end
                % clusClas initialization
                clusClas = ones(1,length(cell_metrics.putativeCellType));
                for i = 1:length(UI.preferences.cellTypes)
                    clusClas(strcmp(cell_metrics.putativeCellType,UI.preferences.cellTypes{i}))=i;
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
            path1 = cell_metrics.general.basepaths{batchIDs};
        elseif isfield(cell_metrics.general,'saveAs')
            saveAs = cell_metrics.general.saveAs;
            path1 = cell_metrics.general.basepath;
        else
            saveAs = 'cell_metrics';
            path1 = cell_metrics.general.basepath;
        end
        
        if ~(exist(fullfile(path1,'revisions_cell_metrics'),'dir'))
            mkdir(fullfile(path1,'revisions_cell_metrics'));
        end
        save(fullfile(path1, 'revisions_cell_metrics', [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']),'-struct', 'S');
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
        if UI.preferences.plotWaveformMetrics==0
            UI.menu.waveforms.showMetrics.Checked = 'on';
            UI.preferences.plotWaveformMetrics = 1;
        else
            UI.menu.waveforms.showMetrics.Checked = 'off';
            UI.preferences.plotWaveformMetrics = 0;
        end
        uiresume(UI.fig);
    end
    
    function showAllTraces(~,~)
        if UI.preferences.showAllTraces==0
            UI.menu.display.showAllTraces.Checked = 'on';
            UI.preferences.showAllTraces = 1;
        else
            UI.menu.display.showAllTraces.Checked = 'off';
            UI.preferences.showAllTraces = 0;
        end
        uiresume(UI.fig);
    end
    function adjustHoverEffect(~,~)
        UI.preferences.hoverEffect = 1-UI.preferences.hoverEffect; 
        if UI.preferences.hoverEffect
            UI.menu.cellSelection.hoverEffect.Checked = 'on';
        else
            UI.menu.cellSelection.hoverEffect.Checked = 'off';
        end
    end
    
    function adjustZscoreWaveforms(~,~)
        if UI.preferences.zscoreWaveforms==0
            UI.menu.waveforms.zscoreWaveforms.Checked = 'on';
            UI.preferences.zscoreWaveforms = 1;
        else
            UI.menu.waveforms.zscoreWaveforms.Checked = 'off';
            UI.preferences.zscoreWaveforms = 0;
        end
        uiresume(UI.fig);
    end
    
    function showChannelMap(src,~)
        if src.Position == 1
            UI.menu.waveforms.showChannelMap.ops(1).Checked = 'on';
            UI.menu.waveforms.showChannelMap.ops(2).Checked = 'off';
            UI.menu.waveforms.showChannelMap.ops(3).Checked = 'off';
            UI.preferences.plotInsetChannelMap = 1;
        elseif src.Position == 2
            UI.menu.waveforms.showChannelMap.ops(1).Checked = 'off';
            UI.menu.waveforms.showChannelMap.ops(2).Checked = 'on';
            UI.menu.waveforms.showChannelMap.ops(3).Checked = 'off';
            UI.preferences.plotInsetChannelMap = 2;
        elseif src.Position == 3
            UI.menu.waveforms.showChannelMap.ops(1).Checked = 'off';
            UI.menu.waveforms.showChannelMap.ops(2).Checked = 'off';
            UI.menu.waveforms.showChannelMap.ops(3).Checked = 'on';
            UI.preferences.plotInsetChannelMap = 3;
        end
        if strcmp(UI.menu.waveforms.channelMapColoring.Checked,'off')
            UI.menu.waveforms.channelMapColoring.Checked = 'on';
            UI.preferences.channelMapColoring = true;
        else
            UI.menu.waveforms.channelMapColoring.Checked = 'off';
            UI.preferences.channelMapColoring = false;
        end
        uiresume(UI.fig);
    end
    
    function showInsetACG(src,~)
        if strcmp(UI.menu.waveforms.showInsetACG.Checked,'off')
            UI.menu.waveforms.showInsetACG.Checked = 'on';
            UI.preferences.plotInsetACG = 2;
        else
            UI.menu.waveforms.showInsetACG.Checked = 'off';
            UI.preferences.plotInsetACG = 1;
        end
        uiresume(UI.fig);
    end
    
    function showSessionPeakVoltage(src,~)
        if strcmp(UI.menu.waveforms.peakVoltage_session.Checked,'off')
            UI.menu.waveforms.peakVoltage_session.Checked = 'on';
            UI.preferences.peakVoltage_session = true;
        else
            UI.menu.waveforms.peakVoltage_session.Checked = 'off';
            UI.preferences.peakVoltage_session = false;
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
                web('https://CellExplorer.org/tutorials/tutorials/','-new','-browser')
            case 'Graphical interface'
                web('https://cellexplorer.org/interface/interface/','-new','-browser')
            otherwise
                web('https://CellExplorer.org/','-new','-browser')
        end
    end

    function openSessionDirectory(~,~)
        % Opens the file directory for the selected cell
        if UI.BatchMode
            if exist(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)},'dir')
                cd(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)});
                if ispc
                    winopen(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)});
                elseif ismac
                    syscmd = ['open ', cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)}, ' &'];
                    system(syscmd);
                else
                    filebrowser;
                end
            else
                MsgLog(['File path not available:' cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)}],2)
            end
        else
            if exist(cell_metrics.general.basepath,'dir')
                path_to_open = cell_metrics.general.basepath;
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
            subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','electrodeGroup','spikeSortingID','entryID'};
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
        answer = inputdlg({'Enter marker size [recommended: 6-25]'},'Input',[1 40],{num2str(UI.preferences.markerSize)});
        if ~isempty(answer)
            UI.preferences.markerSize = max(str2double(answer),6);
            uiresume(UI.fig);
        end
    end

    function changeColormap(~,~)
        listing = {'hot','parula','jet','hsv','cool','spring','summer','autumn','winter','gray','bone','copper','pink'};
        [indx,~] = listdlg('PromptString','Select colormap','ListString',listing,'ListSize',[250,400],'InitialValue',1,'SelectionMode','single','Name','Colormap');
        if ~isempty(indx)
            UI.preferences.colormap = listing{indx};
            uiresume(UI.fig);
        end
    end

    function defineBinSize(~,~)
        answer = inputdlg({'Enter bin count'},'Input',[1 40],{num2str(UI.preferences.binCount)});
        if ~isempty(answer)
            UI.preferences.binCount = str2double(answer);
            uiresume(UI.fig);
        end
    end

    function editSortingMetric(~,~)
        sortingMetrics = generateMetricsList('double',UI.preferences.sortingMetric);
        selectMetrics.dialog = dialog('Position', [300, 300, 400, 518],'Name','Select metric for sorting image data','WindowStyle','modal','visible','off'); movegui(selectMetrics.dialog,'center'), set(selectMetrics.dialog,'visible','on')
        selectMetrics.sessionList = uicontrol('Parent',selectMetrics.dialog,'Style','listbox','String',sortingMetrics,'Position',[10, 50, 380, 457],'Value',1,'Max',1,'Min',1);
        uicontrol('Parent',selectMetrics.dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)close_dialog);
        uicontrol('Parent',selectMetrics.dialog,'Style','pushbutton','Position',[200, 10, 190, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        uiwait(selectMetrics.dialog)
        
        function close_dialog
            UI.preferences.sortingMetric = sortingMetrics{selectMetrics.sessionList.Value};
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
            UI.preferences.referenceData = 'None';
            UI.menu.referenceData.ops(1).Checked = 'on';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'off';
            UI.menu.referenceData.ops(4).Checked = 'off';
            if isfield(UI.tabs,'referenceData')
                delete(UI.tabs.referenceData);
                UI.tabs = rmfield(UI.tabs,'referenceData');
            end
        elseif src.Position == 2
            UI.preferences.referenceData = 'Image';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'on';
            UI.menu.referenceData.ops(3).Checked = 'off';
            UI.menu.referenceData.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.preferences.referenceData = 'Points';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'on';
            UI.menu.referenceData.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.preferences.referenceData = 'Histogram';
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
            UI.preferences.groundTruthData = 'None';
            UI.menu.groundTruth.ops(1).Checked = 'on';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            UI.menu.groundTruth.ops(4).Checked = 'off';
            if isfield(UI.tabs,'groundTruthData')
                delete(UI.tabs.groundTruthData);
                UI.tabs = rmfield(UI.tabs,'groundTruthData');
            end
        elseif src.Position == 2
            UI.preferences.groundTruthData = 'Image';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'on';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            UI.menu.groundTruth.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.preferences.groundTruthData = 'Points';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'on';
            UI.menu.groundTruth.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.preferences.groundTruthData = 'Histogram';
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
            if ~isempty(reference_cell_metrics)
                [reference_cell_metrics,referenceData,fig2_axislimit_x_reference,fig2_axislimit_y_reference] = initializeReferenceData(reference_cell_metrics,'reference');
                out = true;
            else
                out = false;
            end
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

    function exploreGroundTruth(~,~)
        if ~isempty(groundTruth_cell_metrics)
            cell_metrics = groundTruth_cell_metrics;
            initializeSession;
            uiresume(UI.fig);
            MsgLog('Ground truth data loaded as primary data',2)
        else
            MsgLog('Ground truth data must be loaded first before exploring',4)
        end
    end

    function exploreReferenceData(~,~)
        if ~isempty(reference_cell_metrics)
            cell_metrics = reference_cell_metrics;
            initializeSession;
            uiresume(UI.fig);
            MsgLog('Reference data loaded as primary data',2)
        else
            MsgLog('Reference data must be loaded first before exploring',4)
        end
    end

    function importGroundTruth(src,evnt)
        [choice,dialog_canceled] = groundTruthDlg(UI.preferences.groundTruth,groundTruthSelection);
        if ~isempty(choice) & ~dialog_canceled
            [~,groundTruthSelection] = ismember(choice',UI.preferences.groundTruth);
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
                cell_list = [cell_list, cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{groundTruthSelection(i)})];
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
                cell_metrics_groundTruthSubset.general.cellCount = length(cell_metrics_groundTruthSubset.UID);
                
                % Saving the ground truth to the subfolder groundTruthData
                if UI.BatchMode
                    file = fullfile(referenceData_path,[cell_metrics.general.basenames{sessionID}, '.cell_metrics.cellinfo.mat']);
                else
                    file = fullfile(referenceData_path,[cell_metrics.general.basename, '.cell_metrics.cellinfo.mat']);
                end
                S.cell_metrics = cell_metrics_groundTruthSubset;
                save(file,'-struct', 'S');
            end
            if ishandle(ce_waitbar)
                close(ce_waitbar)
                MsgLog(['Ground truth data succesfully saved'],[1,2]);
            else
                MsgLog('Ground truth data not succesfully saved for all sessions',4);
            end
        end
    end
    
    function generateFilterbyGroupData(~,~)
        % Generates filter group from group data (tags/groups/groundtruth)
        groups_fields = {'tags','groups','groundTruthClassification'};
        idx = find(ismember(groups_fields,colorMenu));
        if ~isempty(idx)
            colorMenu = rmfield(colorMenu,groups_fields(idx));
        end
        for iGroupFields = 1:numel(groups_fields)
            if ~isempty(cell_metrics.(groups_fields{iGroupFields}))
                newFieldName = ['groups_from_',groups_fields{iGroupFields}];
                temp = fieldnames(cell_metrics.(groups_fields{iGroupFields}));
                cell_metrics.(newFieldName) = repmat({'None'},1,cell_metrics.general.cellCount);
                for i = 1:numel(temp)
                    cell_metrics.(newFieldName)(cell_metrics.(groups_fields{iGroupFields}).(temp{i})) = repmat({temp{i}},1,numel(cell_metrics.(groups_fields{iGroupFields}).(temp{i})));
                end
                colorMenu = [colorMenu;newFieldName];
                if any(strcmp(cell_metrics.(newFieldName),'None'))
                    groups_ids.([newFieldName,'_num']) = sort({temp{:},'None'});
                else
                    groups_ids.([newFieldName,'_num']) = temp';
                end
            end
        end
        updateColorMenuCount
%         UI.popupmenu.groups.String = colorMenu; % buttonGroups(1)
        MsgLog(['Group data filters created. Check the dropdown menu "Group data and filters" in the left side panel.'],[1,2]);
    end
    
    function defineGroupData(~,~)
        [cell_metrics,UI,ClickedCells] = dialog_metrics_groupData(cell_metrics,UI);
        initTags
        updateTags
        if ~isempty(ClickedCells)
            UI.params.ClickedCells = ClickedCells;
            GroupAction(ClickedCells);
        end
    end

    function assignGroup(cellIDsIn,field)
        if strcmp(field,'tags')
            groupList = UI.preferences.tags';
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
                    UI.preferences.tags = [UI.preferences.tags,groupName{1}];
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
        loadDB = {};
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
            gt_cell_metrics = loadCellMetricsBatch('basenames',listing,'basepaths',referenceData_path1); % 'waitbar_handle',ce_waitbar
            gt.refreshTime = datetime('now','Format','HH:mm:ss, d MMMM, yyyy');
            
            % Generating list of sessions
            gt.menu_name = gt_cell_metrics.sessionName;

            fields1 = fieldnames(gt_cell_metrics.groundTruthClassification);
            gt.menu_groundTruth = cell(1,gt_cell_metrics.general.cellCount);
            for i = 1:numel(fields1)
                gt.menu_groundTruth(gt_cell_metrics.groundTruthClassification.(fields1{i})) = strcat(gt.menu_groundTruth(gt_cell_metrics.groundTruthClassification.(fields1{i})),fields1{i});
            end
            gt.menu_animals = gt_cell_metrics.animal; 
            gt.menu_species = gt_cell_metrics.animal_species;
            gt.menu_geneticLine = gt_cell_metrics.animal_geneticLine;
            gt.menu_brainRegion = gt_cell_metrics.brainRegion;
            gt.menu_UID = gt_cell_metrics.UID;
            sessionEnumerator = cellstr(num2str([1:length(gt.menu_name)]'))';
            gt.sessionList = strcat(sessionEnumerator,{' '},gt.menu_name,{' '},gt.menu_groundTruth,{' '},gt.menu_geneticLine,{' '},gt.menu_animals,{' '},gt.menu_species,{' '},gt.menu_brainRegion);
            
            gt.dataTable = {};
            gt.dataTable(:,2:8) = [sessionEnumerator;gt.menu_groundTruth;gt.menu_name;gt.menu_brainRegion;gt.menu_animals;gt.menu_geneticLine;gt.menu_species]';
            gt.dataTable(:,1) = {false};
            gt.listing = listing;
            try
                save(fullfile(referenceData_path,'groundTruth_cell_list.mat'),'gt');
            catch
                warning('failed to save session list with metrics');
            end
            UpdateSummaryText
        end
        
        function UpdateSummaryText
            if ~isempty(loadDB)
                loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' cell(s) from ', num2str(length(unique(loadDB.sessionList.Data(:,4)))),' sessions from ',num2str(length(unique(loadDB.sessionList.Data(:,6)))),' animal(s). Updated at: ', datestr(gt.refreshTime)];
            end
        end
        
        function Button_DB_filterList
%             dataTable1 = gt.dataTable;
            if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
                newStr2 = split(loadDB.popupmenu.filter.String,{' & ',' AND '});
                idx_textFilter2 = zeros(length(newStr2),size(gt.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},{' | ',' OR ',});
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
                groundTruth_cell_metrics = loadCellMetricsBatch('basenames',listSession2,'basepaths',referenceData_path1); % 'waitbar_handle',ce_waitbar
                
                % Saving batch metrics
                save(fullfile(referenceData_path,'groundTruth_cell_metrics.cellinfo.mat'),'groundTruth_cell_metrics');
                
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
            ref_sessionNames = '';
        end
        
        if ~isempty(reference_cell_metrics)
            ref_sessionNames = unique(reference_cell_metrics.sessionName);
        end
        
        [basenames,basepaths,exitMode] = gui_db_sessions(ref_sessionNames);
        
        if ~isempty(basenames)
            % Loading multiple sessions
            if isempty(db) && exist('db_cell_metrics_session_list.mat','file')
                load('db_cell_metrics_session_list.mat','db')
            elseif isempty(db)
                db = db_load_sessionlist;
            end
            i_db_subset_all = find(ismember(db.sessionName,basenames));
            basenames = db.sessionName(i_db_subset_all);
            
            
            % Setting paths from reference data folder/nyu share
            [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
            if ~exist(fullfile(referenceData_path,'+referenceData'), 'dir')
                mkdir(referenceData_path,'+referenceData');
            end
            referenceData_path = fullfile(referenceData_path,'+referenceData');
            nyu_url = 'https://buzsakilab.nyumc.org/datasets/';
            
            ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading reference data');
            
            if isempty(db_settings.repositories)
                db_settings.repositories.random576 = '';
            end
            for i_db = 1:length(i_db_subset_all)
                i_db2 = find(strcmp(basenames{i_db},cellfun(@(X) X.name,db.sessions,'UniformOutput',0)));
                if ~any(strcmp(db.sessions{i_db2}.repositories{1},fieldnames(db_settings.repositories))) && ~strcmp(db.sessions{i_db2}.repositories{1},'NYUshare_Datasets')
                    MsgLog(['The respository ', db.sessions{i_db2}.repositories{1} ,' has not been defined on this computer. Please edit db_local_repositories and provide the path'],4)
                    edit db_local_repositories.m
                    return
                end
                
                db_basepath{i_db} = referenceData_path;
                if ~exist(fullfile(db_basepath{i_db},[basenames{i_db},'.cell_metrics.cellinfo.mat']),'file')
                    waitbar((i_db-1)/length(i_db_subset_all),ce_waitbar,['Downloading missing reference data : ' basenames{i_db}]);
                    Investigator_name = strsplit(db.sessions{i_db2}.investigator,' ');
                    path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                    filename = fullfile(referenceData_path,[basenames{i_db},'.cell_metrics.cellinfo.mat']);
                    
                    if ~any(strcmp(db.sessions{i_db2}.repositories{1},fieldnames(db_settings.repositories))) && strcmp(db.sessions{i_db2}.repositories{1},'NYUshare_Datasets')
                        url = [nyu_url,path_Investigator,'/',db.sessions{i_db2}.animal,'/', basenames{i_db},'/',[basenames{i_db},'.cell_metrics.cellinfo.mat']];
                        options = weboptions('Timeout', 30);
                        outfilename = websave(filename,url,options);
                    else
                        if strcmp(db.sessions{i_db2}.repositories{1},'NYUshare_Datasets')
                            url = fullfile(db_settings.repositories.(db.sessions{i_db2}.repositories{1}), path_Investigator,db.sessions{i_db2}.animal, db.sessions{i_db2}.name);
                        elseif strcmp(db.sessions{i_db2}.repositories{1},'NYUshare_AllenInstitute')
                            url = fullfile(db_settings.repositories.(db.sessions{i_db2}.repositories{1}), db.sessions{i_db2}.name);
                        else
                            url = fullfile(db_settings.repositories.(db.sessions{i_db2}.repositories{1}), db.sessions{i_db2}.animal, db.sessions{i_db2}.name);
                        end
                        url = fullfile(url,[basenames{i_db},'.cell_metrics.cellinfo.mat']);
                        status = copyfile(url,filename);
                        if ~status
                            MsgLog('Copying cell metrics failed',4)
                            return
                        end
                    end
                end
            end
            
            cell_metrics1 = loadCellMetricsBatch('basenames',basenames,'basepaths',db_basepath,'waitbar_handle',ce_waitbar);
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
            save(fullfile(referenceData_path,'reference_cell_metrics.cellinfo.mat'),'reference_cell_metrics');
            
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
                    MsgLog([num2str(length(i_db_subset_all)),' session(s) loaded succesfully'],2);
                else
                    disp([num2str(length(i_db_subset_all)),' session(s) loaded succesfully']);
                end
                
            catch
                if isfield(UI,'panel')
                    MsgLog(['Failed to load dataset from database: ',strjoin(basenames)],4);
                else
                    disp(['Failed to load dataset from database: ',strjoin(basenames)]);
                end
                
            end
        elseif exitMode == 1
            if isfield(UI,'panel')
                MsgLog('No datasets selected.',2);
            else
                disp('No datasets selected');
            end
        end
        
        if ishandle(UI.fig)
            uiresume(UI.fig);
        end
        
    end

    function tSNE_redefineMetrics(~,~)
        [list_tSNE_metrics,ia] = generateMetricsList('all',UI.preferences.tSNE.metrics);
        distanceMetrics = {'euclidean', 'seuclidean', 'cityblock', 'chebychev', 'minkowski', 'mahalanobis', 'cosine', 'correlation', 'spearman', 'hamming', 'jaccard'};
        % [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        
        load_tSNE.dialog = dialog('Position', [300, 300, 500, 518],'Name','Select metrics for the tSNE plot','WindowStyle','modal','visible','off'); movegui(load_tSNE.dialog,'center'), set(load_tSNE.dialog,'visible','on')
        load_tSNE.sessionList = uicontrol('Parent',load_tSNE.dialog,'Style','listbox','String',list_tSNE_metrics,'Position',[10, 135, 480, 372],'Value',1:length(ia),'Max',100,'Min',1);
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 113, 100, 20],'Units','normalized','String','Algorithm','HorizontalAlignment','left');
        load_tSNE.popupmenu.algorithm = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[10, 95, 100, 20],'Units','normalized','String',{'tSNE','UMAP','PCA'},'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 113, 110, 20],'Units','normalized','String','Distance metric','HorizontalAlignment','left');
        load_tSNE.popupmenu.distanceMetric = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[120, 95, 120, 20],'Units','normalized','String',distanceMetrics,'HorizontalAlignment','left');
        if find(strcmp(UI.preferences.tSNE.dDistanceMetric,distanceMetrics)); load_tSNE.popupmenu.distanceMetric.Value = find(strcmp(UI.preferences.tSNE.dDistanceMetric,distanceMetrics)); end
        load_tSNE.checkbox.filter = uicontrol('Parent',load_tSNE.dialog,'Style','checkbox','Position',[250, 95, 300, 20],'Units','normalized','String','Limit population to current filter','HorizontalAlignment','right');
        
        UI.preferences.tSNE.InitialY = 'Random';
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 73, 100, 20],'Units','normalized','String','nPCAComponents','HorizontalAlignment','left');
        load_tSNE.popupmenu.NumPCAComponents = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[10, 55, 100, 20],'Units','normalized','String',UI.preferences.tSNE.NumPCAComponents,'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 73, 90, 20],'Units','normalized','String','LearnRate','HorizontalAlignment','left');
        load_tSNE.popupmenu.LearnRate = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[120, 55, 90, 20],'Units','normalized','String',UI.preferences.tSNE.LearnRate,'HorizontalAlignment','left');
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[220, 73, 70, 20],'Units','normalized','String','Perplexity','HorizontalAlignment','left');
        load_tSNE.popupmenu.Perplexity = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[220, 55, 70, 20],'Units','normalized','String',UI.preferences.tSNE.Perplexity,'HorizontalAlignment','left');
        
        InitialYMetrics = {'Random','PCA space'};
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[380, 73, 110, 20],'Units','normalized','String','InitialY','HorizontalAlignment','left');
        load_tSNE.popupmenu.InitialY = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[380, 55, 110, 20],'Units','normalized','String',InitialYMetrics,'HorizontalAlignment','left','Value',1);
        if find(strcmp(UI.preferences.tSNE.InitialY,InitialYMetrics)); load_tSNE.popupmenu.InitialY.Value = find(strcmp(UI.preferences.tSNE.InitialY,InitialYMetrics)); end
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[300, 73, 70, 20],'Units','normalized','String','Exaggeration','HorizontalAlignment','left');
        load_tSNE.popupmenu.exaggeration = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[300, 55, 70, 20],'Units','normalized','String',num2str(UI.preferences.tSNE.exaggeration),'HorizontalAlignment','left');
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
            
            UI.preferences.tSNE.metrics = list_tSNE_metrics(load_tSNE.sessionList.Value);
            UI.preferences.tSNE.dDistanceMetric = distanceMetrics{load_tSNE.popupmenu.distanceMetric.Value};
            UI.preferences.tSNE.exaggeration = str2double(load_tSNE.popupmenu.exaggeration.String);
            UI.preferences.tSNE.algorithm = load_tSNE.popupmenu.algorithm.String{load_tSNE.popupmenu.algorithm.Value};
            
            UI.preferences.tSNE.NumPCAComponents = str2double(load_tSNE.popupmenu.NumPCAComponents.String);
            UI.preferences.tSNE.LearnRate = str2double(load_tSNE.popupmenu.LearnRate.String);
            UI.preferences.tSNE.Perplexity = str2double(load_tSNE.popupmenu.Perplexity.String);
            UI.preferences.tSNE.InitialY = load_tSNE.popupmenu.InitialY.String{load_tSNE.popupmenu.InitialY.Value};
            UI.preferences.tSNE.filter = load_tSNE.checkbox.filter.Value;
            
            delete(load_tSNE.dialog);
            ce_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
            X(isnan(X) | isinf(X)) = 0;
            if UI.preferences.tSNE.filter == 1
                X1 = nan(cell_metrics.general.cellCount,2);
                X = X(:,UI.params.subset);
            end
            
            switch UI.preferences.tSNE.algorithm
                case 'tSNE'
                    if strcmp(UI.preferences.tSNE.InitialY,'PCA space')
                        waitbar(0.1,ce_waitbar,'Calculating PCA init space...')
                        initPCA = pca(X,'NumComponents',2);
                        waitbar(0.2,ce_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.preferences.tSNE.standardize,'Distance',UI.preferences.tSNE.dDistanceMetric,'Exaggeration',UI.preferences.tSNE.exaggeration,'NumPCAComponents',UI.preferences.tSNE.NumPCAComponents,'Perplexity',UI.preferences.tSNE.Perplexity,'InitialY',initPCA,'LearnRate',UI.preferences.tSNE.LearnRate);
                    else
                        waitbar(0.1,ce_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.preferences.tSNE.standardize,'Distance',UI.preferences.tSNE.dDistanceMetric,'Exaggeration',UI.preferences.tSNE.exaggeration,'NumPCAComponents',min(size(X,1),UI.preferences.tSNE.NumPCAComponents),'Perplexity',min(size(X,2),UI.preferences.tSNE.Perplexity),'LearnRate',UI.preferences.tSNE.LearnRate);
                    end
                case 'UMAP'
                    waitbar(0.1,ce_waitbar,'Calculating UMAP space...')
                    tSNE_metrics.plot = run_umap(X','verbose','none'); % ,'metric',UI.preferences.tSNE.dDistanceMetric
                case 'PCA'
                    waitbar(0.1,ce_waitbar,'Calculating PCA space...')
                    tSNE_metrics.plot = pca(X,'NumComponents',2); % ,'metric',UI.preferences.tSNE.dDistanceMetric
            end
            if UI.preferences.tSNE.filter == 1
                X1(UI.params.subset,:) = tSNE_metrics.plot;
                tSNE_metrics.plot = X1;
            end
            
            if size(tSNE_metrics.plot,2)==1
                tSNE_metrics.plot = [tSNE_metrics.plot,tSNE_metrics.plot];
            end
            
            if ishandle(ce_waitbar)
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
            for j = 1:length(UI.preferences.deepSuperficial)
                cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.preferences.deepSuperficial{j}))=j;
            end
            
            if UI.BatchMode
                cell_metrics.general.SWR_batch{cell_metrics.batchIDs(ii)} = deepSuperficialfromRipple;
            else
                cell_metrics.general.SWR_batch = deepSuperficialfromRipple;
            end
            if UI.BatchMode && isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs{batchIDs};
                matpath = fullfile(cell_metrics.general.basepaths{batchIDs},[cell_metrics.general.basenames{batchIDs}, '.',saveAs,'.cellinfo.mat']);
            elseif isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs;
                matpath = fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat']);
            else
                saveAs = 'cell_metrics';
                matpath = fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat']);
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
        subfieldsExclude = {'UID','batchIDs','cellID','cluID','maxWaveformCh1','maxWaveformCh','sessionID','electrodeGroup','SpikeSortingID'};
        list_tSNE_metrics = setdiff(list_tSNE_metrics,subfieldsExclude);
        if isfield(UI.preferences,'classification_metrics')
            [~,ia,~] = intersect(list_tSNE_metrics,UI.preferences.classification_metrics);
        else
            [~,ia,~] = intersect(list_tSNE_metrics,UI.preferences.tSNE.metrics);
        end
        list_tSNE_metrics = [list_tSNE_metrics(ia);list_tSNE_metrics(setdiff(1:length(list_tSNE_metrics),ia))];
        [indx,~] = listdlg('PromptString',['Select the metrics to use for the classification'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        if ~isempty(indx)
            ce_waitbar = waitbar(0,'Preparing metrics for classification...','WindowStyle','modal');
            X = cell2mat(cellfun(@(X) cell_metrics.(X),list_tSNE_metrics(indx),'UniformOutput',false));
            UI.preferences.classification_metrics = list_tSNE_metrics(indx);
            
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
        if any(selectedClas == [1:length(UI.preferences.cellTypes)])
            saveStateToHistory(ii)
            clusClas(ii) = selectedClas;
            MsgLog(['Cell ', num2str(ii), ' classified as ', UI.preferences.cellTypes{selectedClas}]);
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
        UI.params.alteredCellMetrics = 1;
        if rem(hist_idx,UI.preferences.autoSaveFrequency) == 0
            autoSave_Cell_metrics(cell_metrics)
        end
    end

    function autoSave_Cell_metrics(cell_metrics)
        cell_metrics = saveCellMetricsStruct(cell_metrics);
        assignin('base',UI.preferences.autoSaveVarName,cell_metrics);
        MsgLog(['Autosaved classification changes to workspace (variable: ' UI.preferences.autoSaveVarName ')']);
    end

    function listCellType
        if UI.listbox.cellClassification.Value > length(UI.preferences.cellTypes)
            AddNewCellType
        else
            saveStateToHistory(ii);
            clusClas(ii) = UI.listbox.cellClassification.Value;
            MsgLog(['Cell ', num2str(ii), ' classified as ', UI.preferences.cellTypes{clusClas(ii)}]);
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
        if ~isempty(NewClass) && ~any(strcmp(NewClass,UI.preferences.cellTypes)) && ~isempty(NewClass{1})
            colorpick = rand(1,3);
            try
                colorpick = uisetcolor(colorpick,'Select cell color');
            catch
                MsgLog('Failed to load color palet',3);
            end
            UI.preferences.cellTypes = [UI.preferences.cellTypes,NewClass];
            UI.preferences.cellTypeColors = [UI.preferences.cellTypeColors;colorpick];
            colored_string = DefineCellTypeList;
            UI.listbox.cellClassification.String = colored_string;
            
            if GroupVal == 1 || ColorVal == 2
                UI.classes.labels = UI.preferences.cellTypes;
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
        if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag,UI.preferences.tags))
            if isvarname(NewTag{1})
                UI.preferences.tags = [UI.preferences.tags,NewTag];
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
%         dispTags = ones(size(UI.preferences.tags));
%         dispTags2 = zeros(size(UI.preferences.tags));
        
        % Tags
        buttonPosition = getButtonLayout(UI.tabs.tags,UI.preferences.tags,1);
        delete(UI.togglebutton.tag)
        for m = 1:length(UI.preferences.tags)
            UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String',UI.preferences.tags{m},'Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)buttonTags(m),'KeyPressFcn', {@keyPress});
        end
        m = length(UI.preferences.tags)+1;
        UI.togglebutton.tag(m) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String','+ tag','Position',buttonPosition{m},'Units','normalized','Callback',@(src,evnt)addTag,'KeyPressFcn', {@keyPress});
        
        % Display settings for tags1
        buttonPosition = getButtonLayout(UI.tabs.dispTags_minus,UI.preferences.tags,0);
        delete(UI.togglebutton.dispTags)
        for m = 1:length(UI.preferences.tags)
            UI.togglebutton.dispTags(m) = uicontrol('Parent',UI.tabs.dispTags_minus,'Style','togglebutton','String',UI.preferences.tags{m},'Position',buttonPosition{m},'Value',1,'Units','normalized','Callback',@(src,evnt)buttonTags_minus(m),'KeyPressFcn', {@keyPress});
        end
        
        % Display settings for tags2
        delete(UI.togglebutton.dispTags2)
        for m = 1:length(UI.preferences.tags)
            UI.togglebutton.dispTags2(m) = uicontrol('Parent',UI.tabs.dispTags_plus,'Style','togglebutton','String',UI.preferences.tags{m},'Position',buttonPosition{m},'Value',0,'Units','normalized','Callback',@(src,evnt)buttonTags_plus(m),'KeyPressFcn', {@keyPress});
        end
    end

    function colored_string = DefineCellTypeList
        if size(UI.preferences.cellTypeColors,1) < length(UI.preferences.cellTypes)
            UI.preferences.cellTypeColors = [UI.preferences.cellTypeColors;rand(length(UI.preferences.cellTypes)-size(UI.preferences.cellTypeColors,1),3)];
        elseif size(UI.preferences.cellTypeColors,1) > length(UI.preferences.cellTypes)
            UI.preferences.cellTypeColors = UI.preferences.cellTypeColors(1:length(UI.preferences.cellTypes),:);
        end
        classColorsHex = rgb2hex(UI.preferences.cellTypeColors*0.7);
        classColorsHex = cellstr(classColorsHex(:,2:end));
        classNumbers = cellstr(num2str([1:length(UI.preferences.cellTypes)]'))';
        colored_string = strcat('<html>',classNumbers, '.&nbsp;','<BODY bgcolor="white"><font color="', classColorsHex' ,'">&nbsp;', UI.preferences.cellTypes, '&nbsp;</font></BODY></html>');
        colored_string = [colored_string,'+   New Cell-type'];
    end

    function buttonDeepSuperficial
        saveStateToHistory(ii)
        cell_metrics.deepSuperficial{ii} = UI.preferences.deepSuperficial{UI.listbox.deepSuperficial.Value};
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
            if isfield(cell_metrics.tags,UI.preferences.tags{input})
                cell_metrics.tags.(UI.preferences.tags{input}) = unique([cell_metrics.tags.(UI.preferences.tags{input}),ii]);
            else
                cell_metrics.tags.(UI.preferences.tags{input}) = ii;
            end
            UI.togglebutton.tag(input).FontWeight = 'bold';
            UI.togglebutton.tag(input).ForegroundColor = UI.colors.toggleButtons;
            MsgLog(['Cell ', num2str(ii), ' tag assigned: ', UI.preferences.tags{input}]);
        else
            cell_metrics.tags.(UI.preferences.tags{input}) = setdiff(cell_metrics.tags.(UI.preferences.tags{input}),ii);
            UI.togglebutton.tag(input).FontWeight = 'normal';
            UI.togglebutton.tag(input).ForegroundColor = [0 0 0];
            MsgLog(['Cell ', num2str(ii), ' tag removed: ', UI.preferences.tags{input}]);
            
        end
    end

    function buttonTags_minus(input)
        UI.groupData1.tags.minus_filter.(UI.preferences.tags{input}) = UI.togglebutton.dispTags(input).Value;
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
        UI.groupData1.tags.plus_filter.(UI.preferences.tags{input}) = UI.togglebutton.dispTags2(input).Value;
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
        for i = 1:numel(UI.preferences.tags)
            if ismember(UI.preferences.tags{i},fields1) && any(cell_metrics.tags.(UI.preferences.tags{i})== ii)
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
            cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.preferences.cellTypes{C(i)}},sum(ic==i),1);
        end
    end

    function updateGroundTruth
        % Updates groundTruth tags
        fields1 = fieldnames(cell_metrics.groundTruthClassification);
        for i = 1:numel(UI.preferences.groundTruth)
            if ismember(UI.preferences.groundTruth{i},fields1) && any(cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{i})== ii)
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
        
        if isempty(UI.brainRegions.list)
            brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
            UI.brainRegions.list = strcat(brainRegions(:,1),' (',brainRegions(:,2),')');
            UI.brainRegions.acronym = brainRegions(:,2);
            clear brainRegions;
        end
        choice = brainRegionDlg(UI.brainRegions.list,find(strcmp(cell_metrics.brainRegion{ii},UI.brainRegions.acronym)));
        if strcmp(choice,'')
            tf = 0;
        else
            indx = find(strcmp(choice,UI.brainRegions.list));
            tf = 1;
        end
        
        if tf == 1
            SelectedBrainRegion = UI.brainRegions.acronym{indx};
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
        uicontrol('Parent',brainRegions_dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)CloseBrainRegions_dialog);
        uicontrol('Parent',brainRegions_dialog,'Style','pushbutton','Position',[200, 10, 180, 30],'String','Cancel','Callback',@(src,evnt)CancelBrainRegions_dialog);
        uicontrol('Parent',brainRegions_dialog,'Style','pushbutton','Position',[400, 10, 190, 30],'String','View Allen Atlas','Callback',@(src,evnt)openAtlas);
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
        function openAtlas
            if ~isempty(brainRegionsList.Value)
                brainRegions1 = load('BrainRegions.mat');
                web(brainRegions1.BrainRegions{brainRegionsList.Value,end},'-new','-browser');
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

    function advance(src,evnt)
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
        uiresume(UI.fig);
    end
    
    function advance10
        % Advance 10 cells in the GUI
        if ~isempty(UI.params.subset) && length(UI.params.subset)>1
            if ii >= UI.params.subset(end)
                ii = UI.params.subset(1);
            else
                ii = UI.params.subset(min([9+find(UI.params.subset > ii,1),length(UI.params.subset)]));
            end
        elseif length(UI.params.subset)==1
            ii = UI.params.subset(1);
        end
        uiresume(UI.fig);
    end
    
    function plotLegends
        nLegends = -1;
        line(0,0,'Marker','x','LineStyle','none','color','w', 'LineWidth', 3., 'MarkerSize',18,'HitTest','off'), xlim([-0.15,2]), hold on, yticks([]), xticks([])
        line(0,0,'Marker','x','LineStyle','none','color','k', 'LineWidth', 1.5, 'MarkerSize',16,'HitTest','off');
        text(0.2,0,'Selected cell','HitTest','off')
        if numel(UI.classes.labels) >= numel(nanUnique(UI.classes.plot(UI.params.subset)))
            b12 = nanUnique(UI.classes.plot(UI.params.subset));
            [cnt_unique, temp] = histc(UI.classes.plot(UI.params.subset),b12);
            legendNames = strcat(UI.classes.labels(b12) ,' (',cellstr(num2str(cnt_unique'))',')');
            for i = 1:length(legendNames)
                line(0,nLegends,'Marker','.','LineStyle','none','color',UI.classes.colors(i,:), 'MarkerSize',25,'HitTest','off')
                text(0.2,nLegends,legendNames{i}, 'interpreter', 'none','HitTest','off')
                nLegends = nLegends - 1;
            end
        end
        % Synaptic connections
        switch UI.monoSyn.disp
            case 'All'
                if UI.preferences.plotExcitatoryConnections && ~isempty(UI.params.putativeSubse)
                    line([-0.1,0.1],nLegends*[1,1],'color','k','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'All excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if UI.preferences.plotInhibitoryConnections && ~isempty(UI.params.putativeSubse_inh)
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','k','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'All inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
            case {'Selected','Upstream','Downstream','Up & downstream'}
                if ~isempty(UI.params.inbound) && UI.preferences.plotExcitatoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'color','b','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Inbound excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if ~isempty(UI.params.outbound) && UI.preferences.plotExcitatoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'color','m','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Outbound excitation','HitTest','off')
                    nLegends = nLegends - 1;
                end
                % Inhibitory connections
                if ~isempty(UI.params.inbound_inh) && UI.preferences.plotInhibitoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','r','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Inbound inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
                if ~isempty(UI.params.outbound_inh) && UI.preferences.plotInhibitoryConnections
                    line([-0.1,0.1],nLegends*[1,1],'LineStyle',':','color','c','LineWidth', 2,'HitTest','off')
                    text(0.2,nLegends,'Outbound inhibition','HitTest','off')
                    nLegends = nLegends - 1;
                end
        end
        % Group data
        if ~isempty(UI.groupData1)
            dataTypes = {'tags','groups','groundTruthClassification'};
            for jjj = 1:numel(dataTypes)
                if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'highlight')
                    fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).highlight);
                    for jj = 1:numel(fields1)
                        if UI.groupData1.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(UI.params.subset,cell_metrics.(dataTypes{jjj}).(fields1{jj})))                            
                            line(0, nLegends,'Marker',UI.preferences.groupDataMarkers{jj}(1),'LineStyle','none','color',UI.preferences.groupDataMarkers{jj}(2),'LineWidth', 1.5, 'MarkerSize',8,'HitTest','off');
                            text(0.2,nLegends,[fields1{jj},' (',dataTypes{jjj},')'], 'interpreter', 'none','HitTest','off')
                            nLegends = nLegends - 1;
                        end
                    end
                end
            end
        end
        
        % Reference data
        if ~strcmp(UI.preferences.referenceData, 'None') % 'Points','Image'
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            legends2plot = unique(referenceData.clusClas(idx));
            for jj = 1:length(legends2plot)
                line(0, nLegends,'Marker','x','LineStyle','none','color',UI.classes.colors2(jj,:),'markersize',8);
                text(0.2,nLegends,referenceData.cellTypes{legends2plot(jj)}, 'interpreter', 'none')
                nLegends = nLegends - 1;
            end
        end
        % Ground truth data
        if ~strcmp(UI.preferences.groundTruthData, 'None') % 'Points','Image'
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            legends2plot = unique(groundTruthData.clusClas(idx));
            for jj = 1:length(legends2plot)
                line(0, nLegends,'Marker',UI.preferences.groundTruthMarker,'LineStyle','none','color', UI.classes.colors3(jj,:),'markersize',8);
                text(0.2,nLegends,groundTruthData.groundTruthTypes{legends2plot(jj)}, 'interpreter', 'none')
                nLegends = nLegends - 1;
            end
        end
        % Synaptic cell types
        if UI.preferences.displayExcitatory && ~isempty(UI.cells.excitatory_subset)
            line(0, nLegends,'Marker','^','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{1});
            text(0.2,nLegends,'Excitatory cells')
            nLegends = nLegends - 1;
        end
        if UI.preferences.displayInhibitory && ~isempty(UI.cells.inhibitory_subset)
            line(0, nLegends,'Marker','s','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{2});
            text(0.2,nLegends,'Inhibitory cells', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        if UI.preferences.displayExcitatoryPostsynapticCells && ~isempty(UI.cells.excitatoryPostsynaptic_subset)
            line(0, nLegends,'Marker','v','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{3});
            text(0.2,nLegends,'Cells receiving excitation', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        if UI.preferences.displayInhibitoryPostsynapticCells && ~isempty(UI.cells.inhibitoryPostsynaptic_subset)
            line(0, nLegends,'Marker','*','LineStyle','none','color',UI.preferences.putativeConnectingMarkers{4});
            text(0.2,nLegends,'Cells receiving inhibition', 'interpreter', 'none')
            nLegends = nLegends - 1;
        end
        ylim([min(nLegends,-5)+0.5,0.5])
    end

    function plotCharacteristics(cellID)
        nLegends = 0;
        fieldname = {'cellID','electrodeGroup','cluID','putativeCellType','peakVoltage','firingRate','troughToPeak'};
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
    
    function plotSessionStats
        nLegends = 0;
        xlim([-2,2.5]), hold on, yticks([]), xticks([]),
        % Session name
        text(-2,nLegends,cell_metrics.general.basename,'HorizontalAlignment','left','FontWeight','bold');
        line([-2,2.5],nLegends*[1,1]-0.5,'color','k')
        nLegends = nLegends - 1;
        % Cells
        text(-2,nLegends,['nCells: ',num2str(cell_metrics.general.cellCount)],'HorizontalAlignment','left');
        nLegends = nLegends - 1;
        % Cell-types
        for i = 1:length(UI.preferences.cellTypes)
            putativeCellTypeCount = sum(ismember(cell_metrics.putativeCellType,UI.preferences.cellTypes{i}));
            text(-2,nLegends,[UI.preferences.cellTypes{i},': ',num2str(putativeCellTypeCount)],'HorizontalAlignment','left')
            nLegends = nLegends - 1;
        end
        line([-2,2.5],nLegends*[1,1]+0.5,'color','k')
        % Synaptic connections
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
            text(-2,nLegends,['Excitatory connections: ',num2str(size(cell_metrics.putativeConnections.excitatory,1))],'HorizontalAlignment','left');
            nLegends = nLegends - 1;
        end
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory')
            text(-2,nLegends,['Inhibitory connections: ',num2str(size(cell_metrics.putativeConnections.inhibitory,1))],'HorizontalAlignment','left');
            nLegends = nLegends - 1;
        end
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
            ClasIn = UI.classes.plot(ii);
        end
        temp = find(ClasIn==UI.classes.plot(UI.params.subset));
        temp2 = find(UI.params.subset(temp) > ii,1);
        if ~isempty(temp2)
            ii = UI.params.subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(UI.params.subset(temp) < ii,1))
            ii = UI.params.subset(temp(1));
        else
            MsgLog('No other cells with selected class',2);
        end
        uiresume(UI.fig);
    end

    function backClass
        temp = find(UI.classes.plot(ii)==UI.classes.plot(UI.params.subset));
        temp2 = find(UI.params.subset(temp) < ii,1,'last');
        if ~isempty(temp2)
            ii = UI.params.subset(temp(temp2));
        elseif isempty(temp2) && ~isempty(find(UI.params.subset(temp) > ii,1))
            ii = UI.params.subset(temp(end));
        else
            MsgLog('No other cells with selected class',2);
        end
        uiresume(UI.fig);
    end

    function back(src,evnt)
        if ~isempty(UI.params.subset) && length(UI.params.subset)>1
            if ii <= UI.params.subset(1)
                ii = UI.params.subset(end);
            else
                ii = UI.params.subset(find(UI.params.subset < ii,1,'last'));
            end
        elseif length(UI.params.subset)==1
            ii = UI.params.subset(1);
        end
        uiresume(UI.fig);
    end
    
    function back10
        if ~isempty(UI.params.subset) && length(UI.params.subset)>1
            if ii <= UI.params.subset(1)
                ii = UI.params.subset(end);
            else
                ii = UI.params.subset(max([1,find(UI.params.subset < ii,1,'last')-9]));
            end
        elseif length(UI.params.subset)==1
            ii = UI.params.subset(1);
        end
        uiresume(UI.fig);
    end
    
    function buttonACG(src,~)
        if src.Position == 1
            UI.preferences.acgType = 'Narrow';
            UI.menu.ACG.window.ops(1).Checked = 'on';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.acgType = 'Normal';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(2).Checked = 'on';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 3
            UI.preferences.acgType = 'Wide';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'on';
            UI.menu.ACG.window.ops(4).Checked = 'off';
        elseif src.Position == 4
            UI.preferences.acgType = 'Log10';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'off';
            UI.menu.ACG.window.ops(4).Checked = 'on';
        end
        uiresume(UI.fig);
    end

    function initGroupMenu(groupname,setting)
        if ischar(UI.preferences.(setting))
            idx = find(ismember({UI.menu.(groupname).(setting).ops(:).(menuLabel)},UI.preferences.(setting)));
        if isempty(idx)
            UI.menu.(groupname).(setting).ops(1).Checked = 'on';
        else
            UI.menu.(groupname).(setting).ops(idx).Checked = 'on';
        end
        else
            if UI.preferences.(setting)
                UI.menu.(groupname).(setting).ops(1).Checked = 'on';
            else
                UI.menu.(groupname).(setting).ops(2).Checked = 'on';
            end
        end
    end

    function buttonACG_normalize(src,~)
        if src.Position == 1
            UI.preferences.isiNormalization = 'Rate';
            UI.menu.display.isiNormalization.ops(1).Checked = 'on';
            UI.menu.display.isiNormalization.ops(2).Checked = 'off';
            UI.menu.display.isiNormalization.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.isiNormalization = 'Occurrence';
            UI.menu.display.isiNormalization.ops(1).Checked = 'off';
            UI.menu.display.isiNormalization.ops(2).Checked = 'on';
            UI.menu.display.isiNormalization.ops(3).Checked = 'off';
        elseif src.Position == 3
            UI.preferences.isiNormalization = 'Firing rates';
            UI.menu.display.isiNormalization.ops(1).Checked = 'off';
            UI.menu.display.isiNormalization.ops(2).Checked = 'off';
            UI.menu.display.isiNormalization.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustRainCloudNormalizationMenu(src,~)
        if src.Position == 1
            UI.preferences.rainCloudNormalization = 'Peak';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'on';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.rainCloudNormalization = 'Probability';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'on';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.preferences.rainCloudNormalization = 'Count';
            UI.menu.display.rainCloudNormalization.ops(1).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(2).Checked = 'off';
            UI.menu.display.rainCloudNormalization.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustSpikeRasterMenu(src,~)
        if src.Position == 1
            UI.preferences.raster = 'cv2';
            UI.menu.display.raster.ops(1).Checked = 'on';
            UI.menu.display.raster.ops(2).Checked = 'off';
            UI.menu.display.raster.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.raster = 'ISIs';
            UI.menu.display.raster.ops(1).Checked = 'off';
            UI.menu.display.raster.ops(2).Checked = 'on';
           UI.menu.display.raster.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.preferences.raster = 'random';
            UI.menu.display.raster.ops(1).Checked = 'off';
            UI.menu.display.raster.ops(2).Checked = 'off';
            UI.menu.display.raster.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end

    function adjustTrilatGroupData(src,~)
        if src.Position == 1
            UI.preferences.trilatGroupData = 'session';
            UI.menu.waveforms.trilatGroupData.ops(1).Checked = 'on';
            UI.menu.waveforms.trilatGroupData.ops(2).Checked = 'off';
            UI.menu.waveforms.trilatGroupData.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.trilatGroupData = 'animal';
            UI.menu.waveforms.trilatGroupData.ops(1).Checked = 'off';
            UI.menu.waveforms.trilatGroupData.ops(2).Checked = 'on';
            UI.menu.waveforms.trilatGroupData.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.preferences.trilatGroupData = 'all';
            UI.menu.waveforms.trilatGroupData.ops(1).Checked = 'off';
            UI.menu.waveforms.trilatGroupData.ops(2).Checked = 'off';
            UI.menu.waveforms.trilatGroupData.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustPeakVoltage_all_sorting(src,~)
        if src.Position == 1
            UI.preferences.peakVoltage_all_sorting = 'channelOrder';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(1).Checked = 'on';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(2).Checked = 'off';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.peakVoltage_all_sorting = 'amplitude';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(1).Checked = 'off';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(2).Checked = 'on';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(3).Checked = 'off';
       elseif src.Position == 3
            UI.preferences.peakVoltage_all_sorting = 'none';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(1).Checked = 'off';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(2).Checked = 'off';
            UI.menu.waveforms.peakVoltage_all_sorting.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustWaveformsAcrossChannelsAlignment(src,~)
        if src.Position == 1
            UI.preferences.waveformsAcrossChannelsAlignment = 'Probe layout';
            UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(1).Checked = 'on';
            UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(2).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.waveformsAcrossChannelsAlignment = 'Electrode groups';
            UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(1).Checked = 'off';
            UI.menu.waveforms.waveformsAcrossChannelsAlignment.ops(2).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
    function adjustPlotChannelMapAllChannels(src,~)
        if src.Position == 1
            UI.preferences.plotChannelMapAllChannels = true;
            UI.menu.waveforms.plotChannelMapAllChannels.ops(1).Checked = 'on';
            UI.menu.waveforms.plotChannelMapAllChannels.ops(2).Checked = 'off';
        elseif src.Position == 2
            UI.preferences.plotChannelMapAllChannels = false;
            UI.menu.waveforms.plotChannelMapAllChannels.ops(1).Checked = 'off';
            UI.menu.waveforms.plotChannelMapAllChannels.ops(2).Checked = 'on';
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
            UI.preferences.plotExcitatoryConnections = false;
            UI.menu.monoSyn.plotExcitatoryConnections.Checked = 'Off';
        else
            UI.preferences.plotExcitatoryConnections = true;
            UI.menu.monoSyn.plotExcitatoryConnections.Checked = 'On';
        end
        uiresume(UI.fig);
    end
    
    function togglePlotInhibitoryConnections(src,~)
        if strcmp(src.Checked,'on')
            UI.preferences.plotInhibitoryConnections = false;
            UI.menu.monoSyn.plotInhibitoryConnections.Checked = 'Off';
        else
            UI.preferences.plotInhibitoryConnections = true;
            UI.menu.monoSyn.plotInhibitoryConnections.Checked = 'On';
        end
        uiresume(UI.fig);
    end

    function axnum = getAxisBelowCursor
        axnum = [];
        temp1 = UI.fig.Position([3,4]);
        temp2 = UI.panel.left.Position(3);
        temp3 = UI.panel.right.Position(3);
        temp4 = get(UI.fig, 'CurrentPoint');
        if temp4(1)> temp2 && temp4(1) < (temp1(1)-temp3)
            fractionalPositionX = (temp4(1) - temp2 ) / (temp1(1)-temp3-temp2);
            fractionalPositionY = (temp4(2) - 26 ) / (temp1(2)-20-26);
            switch UI.preferences.layout
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
                    elseif UI.preferences.layout == 2 && fractionalPositionY < 0.4
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
                        if fractionalPositionY < 0.25 && axnum < 5
                            axnum = axnum + 3;
                        end
                    end
                case 5 % GUI: 3+5
                    if fractionalPositionY > 0.5
                        axnum = ceil(fractionalPositionX*3);
                    elseif fractionalPositionY < 0.5
                        axnum = ceil(fractionalPositionX*3)+3;
                        if fractionalPositionY < 0.25 && axnum < 6
                            axnum = axnum + 3;
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
        clickPlotRegular = false;
        if isfield(UI,'panel') && ~isempty(axnum) && UI.scroll
            if axnum == 10
                handle34 = UI.axis.legends;
            else
                handle34 = subfig_ax(axnum);
            end
            um_axes = get(handle34,'CurrentPoint');
            UI.zoom.twoAxes = 0;

            u = um_axes(1,1);
            v = um_axes(1,2);
            w = um_axes(1,2);
%             if UI.preferences.hoverEffect == 0
                set(UI.fig,'CurrentAxes',handle34)
%             end
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
            if axnum == 2 && (strcmp(UI.preferences.referenceData, 'Image') || strcmp(UI.preferences.groundTruthData, 'Image'))
                UI.zoom.twoAxes = 1;
            elseif axnum == 1  && UI.preferences.customPlotHistograms < 3 && UI.checkbox.logy.Value == 1 && UI.checkbox.logx.Value == 0 && (strcmp(UI.preferences.referenceData, 'Image') || strcmp(UI.preferences.groundTruthData, 'Image'))
                UI.zoom.twoAxes = 1;
            end
            zoomInFactor = 0.80;
            zoomOutFactor = 1.3;
            
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
            elseif UI.zoom.twoAxes == 1 && ~(axnum == 1 && (UI.preferences.customPlotHistograms == 2 || strcmp(UI.preferences.referenceData, 'Histogram') || strcmp(UI.preferences.groundTruthData, 'Histogram')))
                applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
                yyaxis left
                globalZoom1(2,:) = globalZoom1(2,:);
                axesLimits(2,:) = axesLimits(2,:);
                applyZoom(globalZoom1,cursorPosition,axesLimits,[0 0 0],direction);
                yyaxis right
            elseif axnum == 1 && (UI.preferences.customPlotHistograms == 2 || strcmp(UI.preferences.referenceData, 'Histogram') || strcmp(UI.preferences.groundTruthData, 'Histogram'))
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
        clickPlotRegular = true;
        
        function applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction)
            
            if isreal(axesLimits)
                u = cursorPosition(1);
                v = cursorPosition(2);
                w = cursorPosition(3);
                b = axesLimits(1,:);
                c = axesLimits(2,:);
                d = axesLimits(3,:);
                if direction == 1
                    % zoom in
                    zoomPct = zoomInFactor;
                else
                    % zoom out
                    zoomPct = zoomOutFactor;
                end
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    axLim = RecalcZoomAxesLimits(c, globalZoom1(2,:), cursorPosition(2), zoomPct,globalZoomLog1(2));
                    ylim(axLim)
                    
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    axLim = RecalcZoomAxesLimits(b, globalZoom1(1,:), cursorPosition(1), zoomPct,globalZoomLog1(1));
                    xlim(axLim)
                    
                else
                    % X zoom
                    axLim = RecalcZoomAxesLimits(b, globalZoom1(1,:), cursorPosition(1), zoomPct,globalZoomLog1(1));
                    xlim(axLim)
                    
                    % Y zoom
                    axLim = RecalcZoomAxesLimits(c, globalZoom1(2,:), cursorPosition(2), zoomPct,globalZoomLog1(2));
                    ylim(axLim)
                    
                    % Z zoom
                    axLim = RecalcZoomAxesLimits(d, globalZoom1(3,:), cursorPosition(3), zoomPct,globalZoomLog1(3));
                    [~,el1] = view;
                    if el1 ~= 90
                        zlim(axLim)
                    end
                end
            end
        end
        
        function axLim = RecalcZoomAxesLimits(axLim, axLimDflt, zcCrd, zoomPct, isLog)
            
            rf = range(axLim);
            ra = range([axLim(1), zcCrd]);
            rb = range([zcCrd, axLim(2)]);
            
            cfa = ra / rf;
            cfb = rb / rf;
            
            newRange = range(axLim) * zoomPct;
            dRange = newRange - rf;
            
            axLim(1) = axLim(1) - dRange * cfa;
            axLim(2) = axLim(2) + dRange * cfb;
            
%             if (axLim(1) < axLimDflt(1)), axLim(1) = axLimDflt(1); end
%             if (axLim(2) > axLimDflt(2)), axLim(2) = axLimDflt(2); end
            
            if diff(axLim)<=0
                axLim = axLimDflt;
            end
            if isLog
                axLim = 10.^axLim;
            end
        end
    end
    
    function enableInteractions
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
    
    function hoverCallback(~,~)
        if clickPlotRegular
            set(UI.fig,'Pointer','arrow')
        else
            set(UI.fig,'Pointer','crosshair')
        end
        if UI.preferences.hoverEffect == 1 && clickPlotRegular && UI.fig == get(groot,'CurrentFigure') && toc(timerHover) > UI.preferences.hoverTimer
            axnum = getAxisBelowCursor;
            if ~isempty(axnum) && axnum < 10 && ~isempty(UI.params.subset)
                if UI.pan.allow(axnum) && any(~UI.pan.allow)
                    UI.drag.pan.Enable = 'on';
                    enableInteractions
                elseif ~UI.pan.allow(axnum)
                    UI.rotate.rotate3d.Enable = 'on';
                    enableInteractions
                end
                handle34 = subfig_ax(axnum);
                set(UI.fig,'CurrentAxes',handle34)
                if ishandle(hover2highlight.handle1)
                    set(hover2highlight.handle1,'Visible','off');
                end
                if ishandle(hover2highlight.handle2)
                    set(hover2highlight.handle2,'Visible','off');
                end
                if ishandle(hover2highlight.handle3)
                    set(hover2highlight.handle3,'Visible','off');
                end
                if ishandle(hover2highlight.handle4)
                    set(hover2highlight.handle4,'Visible','off');
                end
                um_axes = get(handle34,'CurrentPoint');
                u = um_axes(1,1);
                v = um_axes(1,2);
                w = um_axes(1,3);
                try
                    FromPlot(u,v,w,0,1);
                end
                timerHover = tic;
            end
        end
    end

    function [disallowRotation] = ClicktoSelectFromPlot(~,~)
        % Handles mouse clicks on the plots. Determines the selected plot
        % and the coordinates (u,v) within the plot. Finally calls
        % according to which mouse button that was clicked.
        disallowRotation = true;
        axnum = find(ismember(subfig_ax, gca));
        um_axes = get(subfig_ax(axnum),'CurrentPoint');
        cursorPosition = um_axes(1,:);
        u = um_axes(1,1);
        v = um_axes(1,2);
        w = um_axes(1,3);
        selectiontype = get(UI.fig, 'selectiontype');
        if clickPlotRegular
            switch selectiontype
                case {'open','extend'}%'normal'
                    % Select cell from plot
                    if ~isempty(UI.params.subset)
                        SelectFromPlot(u,v,w);
                    else
                        MsgLog(['No cells with selected classification']);
                    end
                case 'alt'
                    % Highlight cell
                    if ~isempty(UI.params.subset)
                        if ishandle(hover2highlight.handle1)
                            set(hover2highlight.handle1,'Visible','off');
                        end
                        if ishandle(hover2highlight.handle3)
                            set(hover2highlight.handle3,'Visible','off');
                        end
                        HighlightFromPlot(u,v,w);
                    end
                case 'normal'%'extend'
                    disallowRotation = false;
%                     h.Enable = 'on';
%                     polygonSelection
                    % Drag axis
%                     DragMouseBegin(axnum,cursorPosition)

%                 case 'open'
                    % Reset zoom
                    % polygonSelection
            end
        else
            c = [u,v];
            
            if strcmpi(selectiontype, 'alt')
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
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter > 0
                polygon1.coords = polygon1.coords(1:end-1,:);
                set(polygon1.handle(polygon1.counter),'Visible','off');
                polygon1.counter = polygon1.counter-1;
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter == 0
                clickPlotRegular = true;
                set(UI.fig,'Pointer','arrow')
                
            elseif strcmpi(selectiontype, 'normal')
                polygon1.coords = [polygon1.coords;c];
                polygon1.counter = polygon1.counter +1;
                polygon1.handle(polygon1.counter) = line(polygon1.coords(:,1),polygon1.coords(:,2),'Marker','.','color','k','HitTest','off');
            end
        end
        
    end

    function mousebuttonRelease(~,~)
         UI.scroll = true;
    end
    
    function mousebuttonPress(~,~)
         UI.scroll = false;
    end
    
    function DragMouseBegin
        UI.drag.pan = pan(UI.fig);
        UI.drag.pan.Enable = 'on';
        UI.drag.pan.ButtonDownFilter = @ClicktoSelectFromPlot;
        UI.drag.pan.ActionPreCallback = @mousebuttonPress;
        UI.drag.pan.ActionPostCallback = @mousebuttonRelease;
        enableInteractions
    end
    
    function rotateFig(axisToRotate,axnum)
        % activates a rotation mode for subfig1 while maintaining the keyboard shortcuts and click functionality for the remaining plots
%         set(UI.fig,'CurrentAxes',UI.panel.subfig_ax(axisTorate).Children)
        UI.pan.allow(axnum) = false;
        rotate3d(axisToRotate,'on');
        UI.rotate.rotate3d = rotate3d(axisToRotate);
        UI.rotate.rotate3d.Enable = 'on';
        setAllowAxesRotate(UI.rotate.rotate3d,subfig_ax(2),false);
        setAllowAxesPan(UI.drag.pan,subfig_ax(2),true);
%         set(UI.rotate.rotate3d,'ButtonDownFilter',@myRotateFilter);
        set(UI.rotate.rotate3d,'ButtonDownFilter',@ClicktoSelectFromPlot);
        set(UI.drag.pan,'ButtonDownFilter',@ClicktoSelectFromPlot);
        enableInteractions
    end
    
    function polygonSelection(~,~)
        clickPlotRegular = false;
        MsgLog('Select cells by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.');
        ax = get(UI.fig,'CurrentAxes');
        hold(ax, 'on');
        polygon1.counter = 0;
        polygon1.cleanExit = 0;
        polygon1.coords = [];
        set(UI.fig,'Pointer','crosshair')
    end

    function toggleStickySelection(~,~)
        if UI.preferences.stickySelection
            UI.preferences.stickySelection = false;
            UI.menu.cellSelection.stickySelection.Checked = 'off';
            uiresume(UI.fig);
        else
            UI.preferences.stickySelection = true;
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
        
        if UI.preferences.metricsTable==1 && ~isempty(event.Indices) && size(event.Indices,1) == 1
            if event.Indices(2) == 1
                UI.popupmenu.xData.Value = find(contains(UI.lists.metrics,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.xData);
                buttonPlotX;
            elseif event.Indices(2) == 2
                UI.popupmenu.yData.Value = find(contains(UI.lists.metrics,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.yData);
                buttonPlotY;
            end
            
        elseif UI.preferences.metricsTable==2 && ~isempty(event.Indices) && event.Indices(2) > 1 && size(event.Indices,1) == 1
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
        if UI.preferences.metricsTable==2
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
        if UI.preferences.customPlotHistograms == 3
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells), plotZ(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.preferences.customPlotHistograms == 1
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.preferences.customPlotHistograms == 4
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY1(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif UI.preferences.customPlotHistograms == 2
            set(UI.fig,'CurrentAxes',subfig_ax(1))
            line(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        end
        set(UI.fig,'CurrentAxes',subfig_ax(2))
        line(cell_metrics.troughToPeak(UI.params.ClickedCells)*1000,cell_metrics.acg_tau_rise(UI.params.ClickedCells),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        
        set(UI.fig,'CurrentAxes',subfig_ax(3))
        line(tSNE_metrics.plot(UI.params.ClickedCells,1),tSNE_metrics.plot(UI.params.ClickedCells,2),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
        
        % Highlighting waveforms
        
        if any(strcmp(UI.preferences.customPlot,'Waveforms (all)'))
            if UI.preferences.zscoreWaveforms == 1
                zscoreWaveforms1 = 'filt_zscored';
            else
                zscoreWaveforms1 = 'filt_absolute';
            end
            idx = find(strcmp(UI.preferences.customPlot,'Waveforms (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(cell_metrics.waveforms.time_zscored,cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting raw waveforms
        if any(strcmp(UI.preferences.customPlot,'Waveforms (raw all)'))
            if UI.preferences.zscoreWaveforms == 1
                zscoreWaveforms1 = 'raw_zscored';
            else
                zscoreWaveforms1 = 'raw_absolute';
            end
            idx = find(strcmp(UI.preferences.customPlot,'Waveforms (raw all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(cell_metrics.waveforms.time_zscored,cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting ACGs
        if any(strcmp(UI.preferences.customPlot,'ACGs (all)'))
            idx = find(strcmp(UI.preferences.customPlot,'ACGs (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                if strcmp(UI.preferences.acgType,'Normal')
                    x1 = [-100:100]/2;
                    y1 = cell_metrics.acg.narrow(:,UI.params.ClickedCells);
%                     line([-100:100]/2,cell_metrics.acg.narrow(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.preferences.acgType,'Narrow')
                    x1 = [-30:30]/2;
                    y1 = cell_metrics.acg.narrow(41+30:end-40-30,UI.params.ClickedCells);
%                     line([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.preferences.acgType,'Log10')
                    x1 = general.acgs.log10;
                    y1 = cell_metrics.acg.log10(:,UI.params.ClickedCells);
%                     line(general.acgs.log10,cell_metrics.acg.log10(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                else
                    x1 = [-500:500];
                    y1 = cell_metrics.acg.wide(:,UI.params.ClickedCells);
%                     line([-500:500],cell_metrics.acg.wide(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                end
                if plotAcgYLog
                    y1(y1 < 0.1) = 0.1;
                end
                line(x1,y1,'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting ISIs
        if any(strcmp(UI.preferences.customPlot,'ISIs (all)'))
            idx = find(strcmp(UI.preferences.customPlot,'ISIs (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                if strcmp(UI.preferences.isiNormalization,'Rate')
                    line(general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
                elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                    line(1./general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells).*(diff(10.^UI.params.ACGLogIntervals))','linewidth',2, 'HitTest','off')
                else
                    line(general.isis.log10,cell_metrics.isi.log10(:,UI.params.ClickedCells).*(diff(10.^UI.params.ACGLogIntervals))','linewidth',2, 'HitTest','off')
                end
            end
        end
        % Highlighting response curves (e.g. theta) 'RCs_thetaPhase (all)'
        if any(strcmp(UI.preferences.customPlot,'RCs_thetaPhase (all)'))
            x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
            y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
            idx = find(strcmp(UI.preferences.customPlot,'RCs_thetaPhase (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(x1(:,UI.params.ClickedCells),y1(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
        % Highlighting firing rate curves 
        if any(strcmp(UI.preferences.customPlot,'RCs_firingRateAcrossTime (all)'))
            idx = find(strcmp(UI.preferences.customPlot,'RCs_firingRateAcrossTime (all)'));
            for i = 1:length(idx)
                set(UI.fig,'CurrentAxes',subfig_ax(3+idx(i)))
                line(UI.subsetPlots{idx}.xaxis,UI.subsetPlots{idx}.yaxis(:,UI.params.ClickedCells),'linewidth',2, 'HitTest','off')
            end
        end
    end

    function iii = FromPlot(u,v,w,highlight,hover)
        hover2highlight.handle1 = [];
        hover2highlight.handle2 = [];
        hover2highlight.handle3 = [];
        hover2highlight.handle4 = [];
        iii = 0;
        if hover
            colorLine = [0.8,0,0.8];
        end
        if highlight
            iLine = mod(iLine,7)+1;
            colorLine = UI.colorLine(iLine,:);
        end
        axnum = find(ismember(subfig_ax, gca));
        if isempty(axnum)
            axnum = 1;
        end

        if axnum == 1 && UI.preferences.customPlotHistograms == 3 % 3D plot
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
                if strcmp(subfig_ax(axnum).YScale,'linear')
                    text_offset = diff(ylim)/80;
                else
                    text_offset = plotY(iii)/20;
                end
                if highlight
                    line(plotX(iii),plotY(iii),plotZ(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                end
                if hover
                    hover2highlight.handle1 = text(plotX(iii),plotY(iii)+text_offset,plotZ(iii),getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    hover2highlight.handle2 = line(plotX(iii),plotY(iii),plotZ(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                end
                if ~(highlight | hover)
                    return
                end
                
        elseif axnum == 1 && UI.preferences.customPlotHistograms < 4 % 2D plot
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
            if strcmp(subfig_ax(axnum).YScale,'linear')
                text_offset = diff(ylim)/80;
            else
                text_offset = plotY(iii)/20;
            end
            if highlight
                line(plotX(iii),plotY(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
            end
            if hover
                hover2highlight.handle1 = text(plotX(iii),plotY(iii)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                hover2highlight.handle2 = line(plotX(iii),plotY(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
            end
            
        elseif axnum == 1 && UI.preferences.customPlotHistograms == 4 % Raincloud plot
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
            if strcmp(subfig_ax(axnum).YScale,'linear')
                text_offset = diff(ylim)/80;
            else
                text_offset = plotY(iii)/20;
            end
            if highlight
                line(plotX(iii),plotY1(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
            end
            if hover
                hover2highlight.handle1 = text(plotX(iii),plotY1(iii)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                hover2highlight.handle2 = line(plotX(iii),plotY1(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
            end
            
        elseif axnum == 2
            x_scale = range(cell_metrics.troughToPeak)*1000;
            y_scale = range(log10(cell_metrics.acg_tau_rise(find(cell_metrics.acg_tau_rise>0 & cell_metrics.acg_tau_rise<Inf))));
            [~,idx] = min(hypot((cell_metrics.troughToPeak(UI.params.subset)*1000-u)/x_scale,(log10(cell_metrics.acg_tau_rise(UI.params.subset))-log10(v))/y_scale));
            iii = UI.params.subset(idx);
            
            if highlight
                line(cell_metrics.troughToPeak(iii)*1000,cell_metrics.acg_tau_rise(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
            end
            if hover
                hover2highlight.handle1 = text(cell_metrics.troughToPeak(iii)*1000,cell_metrics.acg_tau_rise(iii)*1.15,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                hover2highlight.handle2 = line(cell_metrics.troughToPeak(iii)*1000,cell_metrics.acg_tau_rise(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
            end
            
        elseif axnum == 3
            [~,idx] = min(hypot(tSNE_metrics.plot(UI.params.subset,1)-u,tSNE_metrics.plot(UI.params.subset,2)-v));
            iii = UI.params.subset(idx);
            if highlight
                line(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
            end
            if hover
                hover2highlight.handle1 = text(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2)+diff(ylim)/80,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                hover2highlight.handle2 = line(tSNE_metrics.plot(iii,1),tSNE_metrics.plot(iii,2),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
            end
            
        elseif any(axnum == [4,5,6,7,8,9])
            if strcmp(subfig_ax(axnum).YScale,'linear')
                text_offset = diff(ylim)/80;
            else
                text_offset = v/10;
            end
            selectedOption = UI.preferences.customPlot{axnum-3};
            if numel(UI.subsetPlots)>= axnum-3
            subsetPlots = UI.subsetPlots{axnum-3};
            else 
                subsetPlots = [];
            end
            switch selectedOption
                
                case 'Waveforms (single)'
                    if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0,axnum);
                        if ~isempty(out)
                            x_scale = range(out(1,:));
                            y_scale = range(out(2,:));
                            [~,In] = min(hypot((out(1,:)-u)/x_scale,(out(2,:)-v)/y_scale));
                            
                            iii = out(3,In);
                            if hover
                                hover2highlight.handle1 = text(out(1,In),out(2,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                                hover2highlight.handle2 = line(out(1,In),out(2,In),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                            end
                            if highlight
                            	line(out(1,In),out(2,In),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                            end
                        end
                    elseif hover==0
                        showWaveformMetrics;
                    end
                    
                case 'Waveforms (all)'
                    if UI.preferences.zscoreWaveforms == 1
                        zscoreWaveforms1 = 'filt_zscored';
                    else
                        zscoreWaveforms1 = 'filt_absolute';
                    end
                    x1 = cell_metrics.waveforms.time_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                    
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    
                    if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0,axnum);
                        if ~isempty(out)
                            x2 = [x1(:);out(1,:)'];
                            y2 = y1(:);
                            y3 = [y2;out(2,:)'];
                            
                            [~,In] = min(hypot((x2-u)/x_scale,(y3-v)/y_scale));
                            if In > length(y2)
                                iii = out(3,In-length(y2));
                                if hover
                                    hover2highlight.handle3 = text(out(1,In-length(y2)),out(2,In-length(y2))+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                                    hover2highlight.handle4 = line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                                end
                                if highlight
                                    line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                                end
                                In = find(UI.params.subset==iii);
                            else
                                In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                                iii = UI.params.subset(In);
                            end
                            [~,time_index] = min(abs(cell_metrics.waveforms.time_zscored-u));
                        end
                    else
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                        In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                        iii = UI.params.subset(In);
                        [~,time_index] = min(abs(cell_metrics.waveforms.time_zscored-u));
                    end
                    if highlight || hover
                        hover2highlight.handle2 = line(cell_metrics.waveforms.time_zscored,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(cell_metrics.waveforms.time_zscored(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'Waveforms (raw single)'    
                    if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0,axnum);
                        if ~isempty(out)
                            x_scale = range(out(1,:));
                            y_scale = range(out(2,:));
                            [~,In] = min(hypot((out(1,:)-u)/x_scale,(out(2,:)-v)/y_scale));
                            iii = out(3,In);
                            if highlight
                                line(out(1,In),out(2,In),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                            end
                            if highlight || hover
                                hover2highlight.handle1 = text(out(1,In),out(2,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                                hover2highlight.handle2 = line(out(1,In),out(2,In),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                            end
                        end
                    end
                    
                case 'Waveforms (raw all)'
                    if UI.preferences.zscoreWaveforms == 1
                        zscoreWaveforms1 = 'raw_zscored';
                    else
                        zscoreWaveforms1 = 'raw_absolute';
                    end
                    x1 = cell_metrics.waveforms.time_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    
                    if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                        out = plotInsetChannelMap(ii,[],general,0,axnum);
                        if ~isempty(out)
                            x2 = [x1(:);out(1,:)'];
                            y2 = y1(:);
                            y3 = [y2;out(2,:)'];
                            
                            [~,In] = min(hypot((x2-u)/x_scale,(y3-v)/y_scale));
                            if In > length(y2)
                                iii = out(3,In-length(y2));
                                if hover
                                    hover2highlight.handle3 = text(out(1,In-length(y2)),out(2,In-length(y2))+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                                    hover2highlight.handle4 = line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','o','LineStyle','none','color','k', 'HitTest','off');
                                end
                                if highlight
                                    line(out(1,In-length(y2)),out(2,In-length(y2)),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                                end
                                In = find(UI.params.subset==iii);
                            else
                                In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                                iii = UI.params.subset(In);
                            end
                            [~,time_index] = min(abs(cell_metrics.waveforms.time_zscored-u));
                        end
                    else
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                        In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                        iii = UI.params.subset(In);
                        [~,time_index] = min(abs(cell_metrics.waveforms.time_zscored-u));
                    end
                    
                    if highlight || hover
                        hover2highlight.handle2 = line(cell_metrics.waveforms.time_zscored,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(cell_metrics.waveforms.time_zscored(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'Waveforms (image)'
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(UI.preferences.troughToPeakSorted(round(v)));
                        if highlight || hover
                            Xdata = [cell_metrics.waveforms.time_zscored(1),cell_metrics.waveforms.time_zscored(end)];
                            xline = [[Xdata(1),Xdata(end)],[Xdata(end),Xdata(1)]]';
                            yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]'; % [1;1]*[round(v)-0.48,round(v)+0.48]
                            hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                        end
                    end
                    
                case 'Waveforms (across channels)'
                    % All waveforms across channels with largest ampitude colored according to cell type
                    if highlight && ~hover
                        factors = [90,60,40,25,15,10,6,4];
                        idx5 = find(UI.params.chanCoords.y_factor == factors);
                        idx5 = rem(idx5,length(factors))+1;
                        UI.params.chanCoords.y_factor = factors(idx5);
                        MsgLog(['Waveform y-factor altered: ' num2str(UI.params.chanCoords.y_factor)]);
                        uiresume(UI.fig);
                    elseif ~hover
                        factors = [4,6,10,16,25,40,60,90];
                        idx5 = find(UI.params.chanCoords.x_factor==factors);
                        idx5 = rem(idx5,length(factors))+1;
                        UI.params.chanCoords.x_factor = factors(idx5);
                        MsgLog(['Waveform x-factor altered: ' num2str(UI.params.chanCoords.x_factor)]);
                        uiresume(UI.fig);
                    end
                    
                case 'Waveforms (peakVoltage_all)'
                    subset1 = subsetPlots.subset;
                    x1 = subsetPlots.xaxis;
                    y1 = subsetPlots.yaxis;
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/length(subsetPlots.xaxis)))+1;
                    In = min([In,length(subset1)]);
                    iii = subset1(In);
                    [~,time_index] = min(abs(subsetPlots.xaxis-u));
                    if highlight || hover
                        hover2highlight.handle2 = line(subsetPlots.xaxis,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(subsetPlots.xaxis(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'Trilaterated position'
                    switch UI.preferences.trilatGroupData
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
                        line(cell_metrics.trilat_x(iii),cell_metrics.trilat_y(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                    end
                    if highlight || hover
                        hover2highlight.handle1 = text(cell_metrics.trilat_x(iii),cell_metrics.trilat_y(iii)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                        hover2highlight.handle2 = line(cell_metrics.trilat_x(iii),cell_metrics.trilat_y(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                    end
                    
                case 'Common Coordinate Framework'
                    switch UI.preferences.trilatGroupData
                        case 'session'
                            subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                            subset1 = UI.params.subset(subset1);
                        case 'animal'
                            subset1 = ismember(cell_metrics.animal(UI.params.subset),cell_metrics.animal{ii});
                            subset1 = UI.params.subset(subset1);
                        otherwise
                            subset1 = UI.params.subset;
                    end
                    [azimuth,elevation] = view;
                    r  = 100000000;
                    y1 = -r .* cosd(elevation) .* cosd(azimuth);
                    x1 = r .* cosd(elevation) .* sind(azimuth);
                    z1 = r .* sind(elevation);
                    plotX22 = cell_metrics.ccf_x;
                    plotY22 = cell_metrics.ccf_z;
                    plotZ22 = cell_metrics.ccf_y;
                    x_scale = range(xlim);
                    y_scale = range(ylim);
                    z_scale = range(zlim);
                    distance = point_to_line_distance([plotX22(subset1); plotY22(subset1); plotZ22(subset1)]'./[x_scale y_scale z_scale], [u,v,w]./[x_scale y_scale z_scale], ([u,v,w]./[x_scale y_scale z_scale]+[x1,y1,z1]));
                    [~,idx] = min(distance);
                    iii = subset1(idx);
                    [~,idx] = min(distance);
                    iii = subset1(idx);
                    if highlight
                        line(plotX22(iii),plotY22(iii),plotZ22(iii),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                    elseif hover
                        hover2highlight.handle1 = text(plotX22(iii),plotY22(iii)+text_offset,plotZ22(iii),getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                        hover2highlight.handle2 = line(plotX22(iii),plotY22(iii),plotZ22(iii),'Marker','o','LineStyle','none','color','k', 'HitTest','off');
                    else
                        return
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
                        if round(v) > 0 && round(v) <= length(subset2)
                            iii = subset2(round(v));
                            if highlight || hover
                                if strcmp(UI.preferences.acgType,'Narrow')
                                    Xdata = [-30,30]/2;
                                else
                                    Xdata = [-100,100]/2;
                                end
                                xline = [[Xdata(1),Xdata(end)],[Xdata(end),Xdata(1)]]';
                                yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]'; % [1;1]*[round(v)-0.48,round(v)+0.48]
                                hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                                hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                            end
                        end
                    end
                    
                case 'ACGs (single)'
                    if ~hover
                        if highlight
                            toggleACGfit
                        else
                            switch UI.preferences.acgType
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
                    end
                case 'ACGs (image)'
                    [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(burstIndexSorted(round(v)));
                        if highlight || hover
                            if strcmp(UI.preferences.acgType,'Normal')
                                Xdata = [-100,100]/2;
                            elseif strcmp(UI.preferences.acgType,'Narrow')
                                Xdata = [-30,30]/2;
                            elseif strcmp(UI.preferences.acgType,'Log10')
                                Xdata = log10(general.acgs.log10([1,end]));
                            else
                                Xdata = [-500,500];
                            end
                            xline = [[Xdata(1),Xdata(end)],[Xdata(end),Xdata(1)]]';
                            yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]'; % [1;1]*[round(v)-0.48,round(v)+0.48]
                            hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                        end
                    end
                    
                case 'ACGs (all)'
                    if strcmp(UI.preferences.acgType,'Normal')
                        x2 = [-100:100]/2;
                        x1 = ([-100:100]/2)'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.narrow(:,UI.params.subset);
                    elseif strcmp(UI.preferences.acgType,'Narrow')
                        x2 = [-30:30]/2;
                        x1 = ([-30:30]/2)'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.narrow(41+30:end-40-30,UI.params.subset);
                    elseif strcmp(UI.preferences.acgType,'Log10')
                        x2 = general.acgs.log10;
                        x1 = (general.acgs.log10)*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.log10(:,UI.params.subset);
                    else
                        x2 = [-500:500];
                        x1 = ([-500:500])'*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.acg.wide(:,UI.params.subset);
                    end
                    if plotAcgYLog
                        y1(y1 < 0.1) = 0.1;
                    end
                    y_scale = range(y1(:));
                    if strcmp(UI.preferences.acgType,'Log10')
                        x_scale = range(log10(x1(:)));
                        [~,In] = min(hypot((log10(x1(:))-log10(u))/x_scale,(y1(:)-v)/y_scale));
                    else
                        x_scale = range(x1(:));
                        [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    end
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = UI.params.subset(In);
                    if highlight || hover
                        [~,time_index] = min(abs(x2-u));
                        hover2highlight.handle2 = line(x2(:),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(x2(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'ISIs (single)'
                    if ~hover
                        switch UI.preferences.isiNormalization
                            case 'Rate'
                                src.Position = 9;
                            case 'Occurrence'
                                src.Position = 10;
                            otherwise % 'Firing rates'
                                src.Position = 8;
                        end
                        buttonACG_normalize(src)
                    end
                case 'ISIs (all)'
                    x2 = general.isis.log10;
                    x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                    if strcmp(UI.preferences.isiNormalization,'Rate')
                        y1 = cell_metrics.isi.log10(:,UI.params.subset);
                    elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                        x2 = 1./general.isis.log10;
                        x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.params.ACGLogIntervals))';
                    else
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.params.ACGLogIntervals))';
                    end
                    x_scale = range(log10(x1(:)));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((log10(x1(:))-log10(u))/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = UI.params.subset(In);
                    if highlight || hover
                        [~,time_index] = min(abs(x2-u));
                        hover2highlight.handle2 = line(x2(:),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(x2(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'ISIs (image)'
                    [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(burstIndexSorted(round(v)));
                        if highlight || hover
                            if strcmp(UI.preferences.isiNormalization,'Firing rates')
                                Xdata = 1./log10(1./general.isis.log10([1,end]));
                            else
                                Xdata = log10(general.isis.log10([1,end]));
                            end
                            xline = [[Xdata(1),Xdata(end)],[Xdata(end),Xdata(1)]]';
                            yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]';
                            hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
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
                    if highlight || hover
                        hover2highlight.handle2 = line(UI.x_bins.thetaPhase,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(UI.x_bins.thetaPhase(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'RCs_firingRateAcrossTime (all)'
                    subset1 = subsetPlots.subset;
                    x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                    y1 = subsetPlots.yaxis;
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/length(subsetPlots.xaxis)))+1;
                    In = min([In,length(subset1)]);
                    iii = subset1(In);
                    [~,time_index] = min(abs(subsetPlots.xaxis-u));
                    if highlight || hover
                        hover2highlight.handle2 = line(subsetPlots.xaxis,y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                        hover2highlight.handle1 = text(subsetPlots.xaxis(time_index),y1(time_index,In)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                    end
                    
                case 'RCs_thetaPhase (image)'
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(UI.preferences.troughToPeakSorted(round(v)));
                        if highlight || hover
                            xline = [[UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[UI.x_bins.thetaPhase(end),UI.x_bins.thetaPhase(1)]]';
                            yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]';
                            hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                        end
                    end
                case 'Connectivity matrix'
                    if UI.BatchMode
                        subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                        subset222 = UI.params.subset(subset1);
                    else
                        subset1 = 1:numel(UI.params.subset);
                        subset222 = UI.params.subset;
                    end
                    if round(v) > 0 && round(v) <= length(subset222)
                        [~,troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset222));
                        iii = subset222(troughToPeakSorted(round(v)));
                        if highlight || hover
                            xline = [[0,length(subset222),length(subset222),0]+0.5;[round(v)-0.5,round(v)-0.5,round(v)+0.5,round(v)+0.5]]';
                            yline = [[round(v)-0.5,round(v)-0.5,round(v)+0.5,round(v)+0.5];[0,length(subset222),length(subset222),0]+0.5]';
                            hover2highlight.handle2 = patch(xline,yline,'k','EdgeColor','none','HitTest','off','facealpha',0.1);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                        end
                    end
                case 'RCs_firingRateAcrossTime (image)'
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        if UI.BatchMode
                            subset23 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                        else
                            subset23 = 1:general.cellCount;
                        end
                        if round(v) <= length(subset23)
                        [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset23));
                        iii = subset23((burstIndexSorted((round(v)))));
                        
                        if highlight || hover
                            Xdata = general.responseCurves.firingRateAcrossTime.x_edges([1,end]);
                            xline = [[Xdata(1),Xdata(end)],[Xdata(end),Xdata(1)]]';
                            yline = [[round(v)-0.48,round(v)-0.48,round(v)+0.48,round(v)+0.48]]';
                            hover2highlight.handle2 = patch(xline,yline,'w','EdgeColor','w','HitTest','off','facealpha',0.5,'linewidth',2);
                            hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                        end
                        end
                    end
                    
                case 'Connectivity graph'
                    if ~isempty(subsetPlots)
                        [~,idx] = min(hypot(subsetPlots.xaxis-u,subsetPlots.yaxis-v));
                        iii = subsetPlots.subset(idx);
                        if highlight
                            line(subsetPlots.xaxis(idx),subsetPlots.yaxis(idx),'Marker','s','LineStyle','none','color','k','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
                        end
                        if highlight || hover
                            hover2highlight.handle1 = text(subsetPlots.xaxis(idx),subsetPlots.yaxis(idx)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                            hover2highlight.handle2 = line(subsetPlots.xaxis(idx),subsetPlots.yaxis(idx),'Marker','o','LineStyle','none','color','k', 'HitTest','off','LineWidth', 1.5);
                        end
                    end
                otherwise
                    if  ~isempty(subsetPlots) && ~isempty(subsetPlots.subset) && isfield(subsetPlots,'type') && strcmp(subsetPlots.type,'image')
                        if round(v) > 0 && round(v) <= length(subsetPlots.subset)
                            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subsetPlots.subset));
                            iii = subsetPlots.subset((burstIndexSorted(round(v))));
                            if highlight || hover
                                hover2highlight.handle2 = line(subsetPlots.xaxis([1,end]),[1;1]*[round(v)-0.48,round(v)+0.48],'color','w','linewidth',2,'HitTest','off');
                                hover2highlight.handle1 = text(u,round(v)+0.5+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',1);
                            end
                        end
                    elseif any(strcmp(UI.monoSyn.disp,{'All','Selected','Upstream','Downstream','Up & downstream'})) && ~isempty(subsetPlots) && ~isempty(subsetPlots.subset)
                            subset1 = subsetPlots.subset;
                            x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                            y1 = subsetPlots.yaxis;
                            x_scale = range(subsetPlots.xaxis(:));
                            y_scale = range(y1(:));
                            [~,time_index] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
                            In = unique(floor(time_index/length(subsetPlots.xaxis)))+1;
                            if In>0 && In<=numel(subset1)
                                iii = subset1(In);
                                if highlight || hover
                                    hover2highlight.handle2 = line(x1(:,1),y1(:,In),'linewidth',2, 'HitTest','off','color',colorLine);
                                    hover2highlight.handle1 = text(x1(time_index),y1(time_index)+text_offset,getTextLabel(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 12,'BackgroundColor',[1 1 1 0.7],'margin',0.5);
                                end
                            end
                    end
            end
        end
        if ~hover
            hover2highlight.handle1 = [];
            hover2highlight.handle2 = [];
            hover2highlight.handle3 = [];
            hover2highlight.handle4 = [];
        end
        function textLabel = getTextLabel(iii)
            if hover && UI.params.hoverStyle == 1
                textLabel = num2str(iii);
            elseif hover && UI.params.hoverStyle == 2
                textLabel = [num2str(iii),': ',UI.classes.labels{UI.classes.plot(iii)}];
            else
                textLabel = num2str(iii);
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
    
    function bar_from_patch_centered_bins(x_data, y_data,col)
        x_step = (x_data(2)-x_data(1));
        x_data = x_data-x_step/2;
%         x_data(1) = x_data(1)+x_step;
        x_data(end+1) = x_data(end)+x_step;
        y_data(end+1) = y_data(end);
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

    function SelectFromPlot(u,v,w)
        % Called with a plot-click and goes to selected cells and updates
        % the GUI
        if ishandle(hover2highlight.handle1)
            set(hover2highlight.handle1,'Visible','off');
        end
        if ishandle(hover2highlight.handle2)
            set(hover2highlight.handle2,'Visible','off');
        end
        if ishandle(hover2highlight.handle3)
            set(hover2highlight.handle3,'Visible','off');
        end
        if ishandle(hover2highlight.handle4)
            set(hover2highlight.handle4,'Visible','off');
        end
        iii = FromPlot(u,v,w,0,0);
        if iii>0
            ii = iii;
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
            filterCells.cellIDs = uicontrol('Parent',filterCells.dialog,'Style', 'Edit', 'String', '', 'Position', [10, 445, 380, 25],'KeyReleaseFcn',@cellSelection1,'HorizontalAlignment','left');
            filterCells.currentFilter = uicontrol('Parent',filterCells.dialog,'Style','checkbox','Position',[410, 445, 150, 25],'String',['Current filter (', num2str(numel(UI.params.subset)) ,' cells)'],'HorizontalAlignment','right','tooltip','Toggle select cell by current filter');
            
            % Text field
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Metric to filter', 'Position', [10, 420, 180, 15],'HorizontalAlignment','left');
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Logic filter', 'Position', [300, 420, 100, 15],'HorizontalAlignment','left');
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Value', 'Position', [410, 420, 170, 15],'HorizontalAlignment','left');
            filterCells.filterDropdown = uicontrol('Parent',filterCells.dialog,'Style','popupmenu','Position',[10, 395, 280, 25],'Units','normalized','String',['Select';UI.lists.metrics],'Value',1,'HorizontalAlignment','left');
            filterCells.filterType = uicontrol('Parent',filterCells.dialog,'Style', 'popupmenu', 'String', {'>','<','==','~='}, 'Value',1,'Position', [300, 395, 100, 25],'HorizontalAlignment','left');
            filterCells.filterInput = uicontrol('Parent',filterCells.dialog,'Style', 'Edit', 'String', '', 'Position', [410, 395, 170, 25],'HorizontalAlignment','left','KeyReleaseFcn',@cellSelection1);
            
            % Cell type
            uicontrol('Parent',filterCells.dialog,'Style', 'text', 'String', 'Cell types', 'Position', [10, 375, 280, 15],'HorizontalAlignment','left');
            cell_class_count = getCellcount(cell_metrics.putativeCellType,UI.preferences.cellTypes);
            filterCells.cellTypes = uicontrol('Parent',filterCells.dialog,'Style','listbox','Position', [10 295 280 80],'Units','normalized','String',strcat(UI.preferences.cellTypes,' (',cell_class_count,')'),'max',100,'min',0,'Value',[]);
            
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
        
        function cell_class_count = getCellcount(plot11,labels)
            [~,plot11] = ismember(plot11,labels);
            cell_class_count = histc(plot11,[1:length(labels)]);
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
            ClickedCells7 = ones(1,cell_metrics.general.cellCount);
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
            if filterCells.currentFilter.Value == 1
                ClickedCells7 = zeros(1,cell_metrics.general.cellCount);
                ClickedCells7(UI.params.subset) = 1;
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
                ClickedCells1 = ismember(cell_metrics.putativeCellType, UI.preferences.cellTypes(filterCells.cellTypes.Value));
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
                % % ClickedCells6 = ismember(cell_metrics.synapticEffect, groups_ids.synapticEffect_num(filterCells.synEffect.Value));
            end
            
            % Finding cells fullfilling all criteria
            UI.params.ClickedCells = intersect(UI.params.ClickedCells,find(all([ClickedCells0;ClickedCells1;ClickedCells2;ClickedCells3;ClickedCells4;ClickedCells5;ClickedCells6;ClickedCells7])));
            
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
        if ~isempty(UI.params.putativeSubse)
            % Inbound
            a199 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
            % Outbound
            a299 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
            
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
        iii = FromPlot(u,v,w,1,0);
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
                if axnum == 1 && UI.preferences.customPlotHistograms == 4
                    In = find(inpolygon(plotX(UI.params.subset), plotY1(UI.params.subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif axnum == 1
                    In = find(inpolygon(plotX(UI.params.subset), plotY(UI.params.subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif axnum == 2
                    In = find(inpolygon(cell_metrics.troughToPeak(UI.params.subset)*1000, log10(cell_metrics.acg_tau_rise(UI.params.subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                    In = UI.params.subset(In);
                    
                elseif axnum == 3
                    In = find(inpolygon(tSNE_metrics.plot(UI.params.subset,1), tSNE_metrics.plot(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif any(axnum == [4,5,6,7,8,9])
                    selectedOption = UI.preferences.customPlot{axnum-3};
                    subsetPlots = UI.subsetPlots{axnum-3};
                    
                    switch selectedOption
                        case 'Waveforms (single)'
                            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0,axnum);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            
                        case 'Waveforms (raw single)'
                            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0,axnum);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                            end
                            
                        case 'Waveforms (all)'
                            if UI.preferences.zscoreWaveforms == 1
                                zscoreWaveforms1 = 'filt_zscored';
                            else
                                zscoreWaveforms1 = 'filt_absolute';
                            end
                            x1 = cell_metrics.waveforms.time_zscored'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                            In = UI.params.subset(In);
                            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0,axnum);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In2 = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                                In = [In,In2];
                            end
                            
                        case 'Waveforms (raw all)'
                            if UI.preferences.zscoreWaveforms == 1
                                zscoreWaveforms1 = 'raw_zscored';
                            else
                                zscoreWaveforms1 = 'raw_absolute';
                            end
                            x1 = cell_metrics.waveforms.time_zscored'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.waveforms.(zscoreWaveforms1)(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(cell_metrics.waveforms.time_zscored)))+1;
                            In = UI.params.subset(In);    
                            if UI.preferences.plotInsetChannelMap > 1 && isfield(general,'chanCoords')
                                out = plotInsetChannelMap(ii,[],general,0,axnum);                                
                                In1 = find(inpolygon(out(1,:), out(2,:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                In2 = out(3,In1);
                                line(out(1,In1),out(2,In1),'Marker','o','LineStyle','none','color','k', 'HitTest','off')
                                In = [In,In2];
                            end
                            
                        case 'Waveforms (image)'
                            In = UI.params.subset(UI.preferences.troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'Trilaterated position'
                            switch UI.preferences.trilatGroupData
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
                        case 'Connectivity matrix'
                            if UI.BatchMode
                                subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                                subset222 = UI.params.subset(subset1);
                            else
                                subset1 = 1:numel(UI.params.subset);
                                subset222 = UI.params.subset;
                            end
                            [~,troughToPeakSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset222));
%                             In = UI.params.subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            In = subset222(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'ACGs (all)'
                            if strcmp(UI.preferences.acgType,'Normal')
                                x1 = ([-100:100]/2)'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.narrow(:,UI.params.subset);
                            elseif strcmp(UI.preferences.acgType,'Narrow')
                                x1 = ([-30:30]/2)'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.narrow(41+30:end-40-30,UI.params.subset);
                            elseif strcmp(UI.preferences.acgType,'Log10')
                                x1 = (general.acgs.log10)*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.log10(:,UI.params.subset);
                            else
                                x1 = ([-500:500])'*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.acg.wide(:,UI.params.subset);
                            end
                            if plotAcgYLog
                                y1(y1 < 0.1) = 0.1;
                            end
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            if ~isempty(In)
                                line(x1(:,In),y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'ISIs (all)'
                            x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                            if strcmp(UI.preferences.isiNormalization,'Rate')
                                y1 = cell_metrics.isi.log10(:,UI.params.subset);
                            elseif strcmp(UI.preferences.isiNormalization,'Firing rates')
                                x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.params.ACGLogIntervals))';
                            else
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^UI.params.ACGLogIntervals))';
                            end
                            
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            In = UI.params.subset(In);
                            
                        case {'ACGs (image)','ISIs (image)'}
                            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(burstIndexSorted(max(min(floor(polygon_coords(:,2))),1):min(max(ceil(polygon_coords(:,2))),length(UI.params.subset))));
                            
                            
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
                            In = UI.params.subset(UI.preferences.troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'RCs_firingRateAcrossTime (image)'
                            if UI.BatchMode
                                subset23 = UI.params.subset(find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)));
                            else
                                subset23 = 1:general.cellCount;
                            end
                            [~,burstIndexSorted] = sort(cell_metrics.(UI.preferences.sortingMetric)(subset23));
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
                        case 'Waveforms (peakVoltage_all)'
                            subset1 = subsetPlots.subset;
                            x1 = subsetPlots.xaxis;
                            y1 = subsetPlots.yaxis;
                            
                            In2 = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In2 = unique(floor(In2/length(subsetPlots.xaxis)))+1;
                            In = subset1(In2);
                            if ~isempty(In2)
                                line(x1(:,1),y1(:,In2),'linewidth',2, 'HitTest','off')
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
        if UI.preferences.dispLegend
            UI.menu.display.dispLegend.Checked = 'off';
            UI.preferences.dispLegend = 0;
        else
            UI.menu.display.dispLegend.Checked = 'on';
            UI.preferences.dispLegend = 1;
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
        if GroupVal == 1 || ColorVal == 2
            UI.classes.plot = clusClas;
        else
%             if ColorVal == 1
                UI.classes.plot11 = cell_metrics.(colorStr{GroupVal});
                if iscell(UI.classes.plot11)
                    UI.classes.plot11 = findgroups(UI.classes.plot11);
                end
%             else
%                 UI.classes.plot = clusClas;
%             end
        end
    end

    function updateTableColumnWidth
        % Updating table column width
        if UI.preferences.metricsTable==1
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),160);
            UI.table.ColumnWidth = {pos1*6/10-10, pos1*4/10-10};
        elseif UI.preferences.metricsTable==2
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),160);
            UI.table.ColumnWidth = {18,pos1*2/10, pos1*6/10-38, pos1*2/10};
        end
    end

    function buttonGroups(inpt)
        % inpt: describes the call
        % 0 = Color dropdown
        % 1 = Filter dropdown
        GroupVal = UI.popupmenu.groups.Value;
        ColorVal = UI.popupmenu.colors.Value;
        colorStr = colorMenu;
        
        if GroupVal == 1
            clasLegend = 0;
            UI.listbox.groups.Enable = 'Off';
            UI.listbox.groups.String = {};
            UI.classes.plot = clusClas;
            UI.classes.labels = UI.preferences.cellTypes;
        else
            clasLegend = 1;
            UI.listbox.groups.Enable = 'On';
            if ColorVal ~= 2
                UI.classes.plot11 = cell_metrics.(colorStr{GroupVal});
                UI.classes.labels = groups_ids.([colorStr{GroupVal} '_num']);
                if iscell(UI.classes.plot11) && ~strcmp(colorStr{GroupVal},'deepSuperficial')
                    UI.classes.plot11 = findgroups(UI.classes.plot11);
                elseif strcmp(colorStr{GroupVal},'deepSuperficial')
                    [~,UI.classes.plot11] = ismember(UI.classes.plot11,UI.classes.labels);
                end
                color_class_count = histc(UI.classes.plot11,[1:length(UI.classes.labels)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                
                UI.listbox.groups.String = strcat(UI.classes.labels,' (',color_class_count,')'); %  UI.classes.labels;
                if length(UI.listbox.groups.String) < max(UI.listbox.groups.Value) | inpt ==1
                    UI.listbox.groups.Value = 1:length(UI.classes.labels);
                    groups2plot = 1:length(UI.classes.labels);
                    groups2plot2 = 1:length(UI.classes.labels);
                end
            else
                UI.classes.plot = clusClas;
                UI.classes.labels = UI.preferences.cellTypes;
                UI.classes.plot2 = cell_metrics.(colorStr{GroupVal});
                UI.classes.labels2 = groups_ids.([colorStr{GroupVal} '_num']);
                if iscell(UI.classes.plot2) && ~strcmp(colorStr{GroupVal},'deepSuperficial')
                    UI.classes.plot2 = findgroups(UI.classes.plot2);
                elseif strcmp(colorStr{GroupVal},'deepSuperficial')
                    [~,UI.classes.plot2] = ismember(UI.classes.plot2,UI.classes.labels2);
                end
                
                color_class_count = histc(UI.classes.plot2,[1:length(UI.classes.labels2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(UI.classes.labels2,' (',color_class_count,')');
                if length(UI.listbox.groups.String) < max(UI.listbox.groups.Value) || inpt ==1
                    UI.listbox.groups.Value = 1:length(UI.classes.labels2);
                    groups2plot = 1:length(UI.classes.labels);
                    groups2plot2 = 1:length(UI.classes.labels2);
                end
                
            end
            
        end
        uiresume(UI.fig);
    end

    function buttonPlotXLog
        if UI.checkbox.logx.Value==1
            MsgLog('X-axis log. Negative data ignored');
        end
        uiresume(UI.fig);
    end

    function buttonPlotYLog
        if UI.checkbox.logy.Value==1
            MsgLog('Y-axis log. Negative data ignored');
        end
        uiresume(UI.fig);
    end

    function buttonPlotZLog
        if UI.checkbox.logz.Value==1
            UI.preferences.plotZLog = 1;
            MsgLog('Z-axis log. Negative data ignored');
        else
            UI.preferences.plotZLog = 0;
        end
        uiresume(UI.fig);
    end

    function buttonPlotMarkerSizeLog
        if UI.checkbox.logMarkerSize.Value==1
            UI.preferences.logMarkerSize = 1;
            MsgLog('Marker size log. Negative data ignored');
        else
            UI.preferences.logMarkerSize = 0;
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
        for i = 1:length(UI.params.tableDataSortingList)
            UI.menu.tableData.sortingList(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.SortBy,UI.params.tableDataSortingList));
        UI.menu.tableData.sortingList(idx).Checked = 'on';
        if UI.preferences.metricsTable==2
            updateCellTableData
        end
    end
    
    function plotSummaryFigure(~,~)
        plotCellIDs = -1;
        plotSummaryFigures
    end
    
    function plotSupplementaryFigure(~,~)
        axisScale = {'lin','log'};
        UI = gui_supplementaryPlot(UI);
        
        if UI.supplementaryFigure.waveformNormalization==1
            UI.preferences.zscoreWaveforms=1;
        else
            UI.preferences.zscoreWaveforms=0;
        end
        
        if UI.supplementaryFigure.groupDataNormalization== 1
            UI.preferences.rainCloudNormalization = 'Peak';
        elseif UI.supplementaryFigure.groupDataNormalization== 2
            UI.preferences.rainCloudNormalization = 'Probability';
        elseif UI.supplementaryFigure.groupDataNormalization== 3
            UI.preferences.rainCloudNormalization = 'Count';
        end
        
%         adjustZscoreWaveforms;
        UI.preferences.plotInsetChannelMap = 1; % Hiding channel map inset in waveform plots.
        UI.preferences.plotInsetACG = 1; % Hiding ACG inset in waveform plots.
        if ismac
            defaultAxesFontSize = 16;
            fig_pos = [0,0,1100,550];
        else
            defaultAxesFontSize = 12;
            fig_pos = [0,0,1200,600];
        end
        fig = figure('Name','CellExplorer supplementary figure','NumberTitle','off','pos',fig_pos,'defaultAxesFontSize',defaultAxesFontSize,'color','w','visible','on','DefaultTextInterpreter', 'tex');
        % Scatter plot with trough to peak vs burst index
        ax1 = subplot('Position',[0.13 0.22 0.34 .75]); % Trough to peak vs burstiness
        hold on
        uniqueGroups = unique(UI.classes.plot(UI.params.subset));
        for i_groups = 1:numel(uniqueGroups)
            idx = UI.classes.plot(UI.params.subset) == uniqueGroups(i_groups);
            handle_ce_gscatter(i_groups) = scatter(cell_metrics.(UI.supplementaryFigure.metrics{1})(UI.params.subset(idx)), cell_metrics.(UI.supplementaryFigure.metrics{2})(UI.params.subset(idx)),UI.preferences.markerSize+5,UI.classes.colors((i_groups),:), 'filled', 'HitTest','off');
            alpha(handle_ce_gscatter(i_groups),.8)
        end

        xlabel(UI.labels.(UI.supplementaryFigure.metrics{1}),'FontSize',defaultAxesFontSize-1), ylabel(UI.labels.(UI.supplementaryFigure.metrics{2}),'FontSize',defaultAxesFontSize-1); set(gca, 'XScale', axisScale{UI.supplementaryFigure.axisScale(1)}, 'YScale', axisScale{UI.supplementaryFigure.axisScale(2)},'TickLength',[0.02 1]), axis tight, figureLetter('A','right')
        
        % Generating legend
        legendNames = UI.classes.labels(nanUnique(UI.classes.plot(UI.params.subset)));
        for i = 1:length(legendNames)
            legendDots(i) = line(nan,nan,'Marker','.','LineStyle','none','color',UI.classes.colors((i),:), 'MarkerSize',20);
        end
        legend(legendDots,legendNames,'Location','southwest');
        
        % Generating histograms along axis
        subplot('Position',[0.13 0.015 0.34 .1])
        generateGroupRainCloudPlot(UI.supplementaryFigure.metrics{1},UI.supplementaryFigure.axisScale(1)-1,0,0, 0.06,0)
        set(gca,'XColor', 'none','Color','none','box','of','TickLength',[0.01 0.7], 'XScale', axisScale{UI.supplementaryFigure.axisScale(1)},'Xticklabels',[]),title('')
        ylabel(UI.preferences.rainCloudNormalization)
        subplot('Position',[0.01 0.22 0.06 0.75])
        generateGroupRainCloudPlot(UI.supplementaryFigure.metrics{2},UI.supplementaryFigure.axisScale(2)-1,0,0, 0.06,0)
        set(gca,'XColor', 'none','Ydir','reverse','Color','none','box','off','TickLength',[0.01 0.7], 'XScale', axisScale{UI.supplementaryFigure.axisScale(2)},'Xticklabels',[]),title('')
        ylabel(UI.preferences.rainCloudNormalization)
        camroll(90)
        
        % Waveforms
        subplot('Position',[0.5 0.72 0.23 .25])
        customPlot('Waveforms (all)',ii,general,batchIDs,gca,0,0,13); yticks([]), axis tight, ylabel(''), figureLetter('B','right');
        set(gca,'Color','none','box','off','TickLength',[0.03 1]), title('');
        if UI.supplementaryFigure.waveformNormalization==1
            set(gca,'YColor','none')
        end
        
        % % % Histogram plots
        % 1. Group plot: Firing rates
        subplot('Position',[0.5 0.41 0.23 .21])
        generateGroupRainCloudPlot(UI.supplementaryFigure.metrics{3},UI.supplementaryFigure.axisScale(3)-1,0,0, 0.06,1)
        xlabel(UI.labels.(UI.supplementaryFigure.metrics{3})), figureLetter('C','right'),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(3)}), title('')
        
        % 2. Group plot: CV2
        subplot('Position',[0.5 0.1 0.23 .21])
        generateGroupRainCloudPlot(UI.supplementaryFigure.metrics{4},UI.supplementaryFigure.axisScale(4)-1,0,0, 0.06,1), xlabel(UI.labels.(UI.supplementaryFigure.metrics{4})),
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(4)}), title('')
        
        % 1. Population plot: Peak voltage
        subplot('Position',[0.76 0.815 0.23 .155])
        ce_raincloud_plot(cell_metrics.(UI.supplementaryFigure.metrics{5}),'scatter_on',0,'log_axis',UI.supplementaryFigure.axisScale(5)-1,'color', [0.9 0.9 0.9]);
        axis tight, figureLetter('D','right'), xlabel(UI.labels.(UI.supplementaryFigure.metrics{5})), % xticks([10 100 1000])
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(5)});
        
        % 2. Population plot:  Isolation distance
        subplot('Position',[0.76 0.57 0.23 .145])
        ce_raincloud_plot(cell_metrics.(UI.supplementaryFigure.metrics{6}),'scatter_on',0,'log_axis',UI.supplementaryFigure.axisScale(6)-1,'color', [0.9 0.9 0.9]);
        axis tight, xlabel(UI.labels.(UI.supplementaryFigure.metrics{6})), % xticks([10 100]); xlim([10,300]), 
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(6)});
        
        % 3. Population plot:  L_ratio
        subplot('Position',[0.76 0.335 0.23 .142])
        ce_raincloud_plot(cell_metrics.(UI.supplementaryFigure.metrics{7}),'scatter_on',0,'log_axis',UI.supplementaryFigure.axisScale(7)-1,'color', [0.9 0.9 0.9]);
        axis tight, xlabel(UI.labels.(UI.supplementaryFigure.metrics{7})), % xticks(10.^(-5:2:1)); xlim(10.^([-5 2]))
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(7)});
        
        % 4. Population plot:  refractory period
        subplot('Position',[0.76 0.1 0.23 .142])
        ce_raincloud_plot(cell_metrics.(UI.supplementaryFigure.metrics{8}),'scatter_on',0,'log_axis',UI.supplementaryFigure.axisScale(8)-1,'color', [0.9 0.9 0.9]);
        axis tight, xlabel(UI.labels.(UI.supplementaryFigure.metrics{8})), %xticks(10.^(-2:2:2));
        set(gca,'Color','none','YColor','none','box','off','TickLength',[0.03 1], 'XScale', axisScale{UI.supplementaryFigure.axisScale(8)});
        
        % Saving figure
        if isfield(UI.supplementaryFigure,'saveFigure') && UI.supplementaryFigure.saveFigure
            saveFig.save = true;
            saveFig.path = UI.supplementaryFigure.savePath;
            saveFig.fileFormat = UI.supplementaryFigure.fileFormat;
            ce_savefigure(fig,pwd,['Supplementary figure ' datestr(now, 'dd-mm-yyyy HH.MM.SS')],1,saveFig)
        end
        
        movegui(fig,'center'), set(fig,'visible','on')
        
        %         classes2plotSubset = unique(UI.classes.plot);
        %         cell_class_count = histc(UI.classes.plot,1:length(UI.preferences.cellTypes));
        %         figure
        %         h_pie = pie(cell_class_count);
        %         for i = 1:numel(classes2plotSubset)
        %             h_pie((i*2)-1).FaceColor = UI.classes.colors(i,:);
        %         end

        function figureLetter(letter,alignment)
            text(-0.015,1,letter,'FontSize',30,'Units','normalized','verticalalignment','middle','horizontalalignment',alignment);
        end
        
    end

    function plotSummaryFigures
        if isempty(plotCellIDs)
            cellIDs = 1:length(cell_metrics.cellID);
            plotCellIDs = cellIDs;
            highlight = 1;
        elseif plotCellIDs==-1
            cellIDs = 1;
            highlight = 0;
        else
            ids = ismember(plotCellIDs,1:length(cell_metrics.cellID));
            cellIDs = plotCellIDs(ids);
            highlight = 1;
        end
%         UI.params.subset = 1:length(cell_metrics.cellID);
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
            UI.params.putativeSubse = find(sum(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)')==2);
        else
            UI.params.putativeSubse=[];
        end
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory')
            UI.params.putativeSubse_inh = find(sum(ismember(cell_metrics.putativeConnections.inhibitory,UI.params.subset)')==2);
        else
            UI.params.putativeSubse_inh=[];
        end
        UI.preferences.plotInsetChannelMap = 1;
        UI.classes.colors = UI.preferences.cellTypeColors(intersect(classes2plot,UI.classes.plot(UI.params.subset)),:);
        classes2plotSubset = unique(UI.classes.plot(UI.params.subset));
            
        if plotCellIDs==-1
            plotOptions_all = {'Trilaterated position','Waveforms (all)','ACGs (all)','ACGs (image)','ISIs (all)','ISIs (image)','RCs_firingRateAcrossTime (image)','RCs_firingRateAcrossTime (all)'};
            plotOptions = plotOptions(ismember(plotOptions,plotOptions_all));
            if ~UI.BatchMode && isfield(cell_metrics,'putativeConnections') && (isfield(cell_metrics.putativeConnections,'excitatory') || isfield(cell_metrics.putativeConnections,'inhibitory'))
                plotOptions = [plotOptions;'Connectivity graph'; 'Connectivity matrix'];
            end
            plotCount = 3;
        else
            plotCount = 4;
            
        end
        [plotRows,~]= numSubplots(length(plotOptions)+plotCount);
        
        fig = figure('Name','CellExplorer','NumberTitle','off','pos',UI.preferences.figureSize,'visible','off');
        if numel(cellIDs)>1
            ce_waitbar1 = waitbar(0,' ','name','Generating summary figure(s)');
        else
            ce_waitbar1 = [];
        end
        for j = 1:length(cellIDs)
            if ishandle(fig) & ishandle(ce_waitbar1)
                waitbar((j-1)/length(cellIDs),ce_waitbar1,['Cell ' num2str(j),'/',num2str(length(cellIDs))])
            elseif ~ishandle(fig) | (~ishandle(ce_waitbar1) & numel(cellIDs)>1)
                disp('Summary figures canceled by user');
                break
            end
            
            if UI.BatchMode
                batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                general1 = cell_metrics.general.batch{batchIDs1};
                savePath1 = cell_metrics.general.basepaths{batchIDs1};
            else
                general1 = cell_metrics.general;
                batchIDs1 = 1;
                if isfield(cell_metrics.general,'basepath')
                    savePath1 = cell_metrics.general.basepath;
                elseif isfield(cell_metrics.general,'basepath')
                    savePath1 = cell_metrics.general.basepath;
                end
            end
            
            if isfield(cell_metrics.general,'saveAs') && UI.BatchMode
                saveAs = cell_metrics.general.saveAs{batchIDs1};
            elseif isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs;
            else
                saveAs = 'cell_metrics';
            end
            
            clf(fig,'reset')
            if plotCellIDs~=-1
                set(fig,'Name',['CellExplorer cell summary ',saveAs,', cell ID ' num2str(cellIDs(j)),' (', num2str(j),'/', num2str(length(cellIDs)),')']);
            else
                set(fig,'Name',['CellExplorer session summary: ', basename,', ',saveAs]);
            end
            if ~isempty(UI.params.putativeSubse)
                UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                UI.params.incoming = UI.params.a1(UI.params.inbound);
                UI.params.outgoing = UI.params.a2(UI.params.outbound);
                UI.params.connections = [UI.params.incoming;UI.params.outgoing];
            end
            if ~isempty(UI.params.putativeSubse_inh) 
                UI.params.b1 = cell_metrics.putativeConnections.inhibitory(UI.params.putativeSubse_inh,1);
                UI.params.b2 = cell_metrics.putativeConnections.inhibitory(UI.params.putativeSubse_inh,2);
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
            set(0, 'CurrentFigure', fig)
            if ispc
                ha = ce_tight_subplot(plotRows(1),plotRows(2),[.1 .05],[.05 .07],[.05 .05]);
            else
                ha = ce_tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.12 .06],[.06 .05]);
            end
            set(fig,'CurrentAxes',ha(1)), hold on
            ii = cellIDs(j);
            plotGroupData(cell_metrics.troughToPeak * 1000,cell_metrics.acg_tau_rise,plotConnections(2),highlight)
            ha(1).XLabel.String = ['Trough-to-Peak (',char(181),'s)'];
            ha(1).YLabel.String = 'Burst Index (Royer 2012)';
            ha(1).Title.String = 'Population';
            set(ha(1),'YScale', 'log');
            set(fig,'CurrentAxes',ha(2)), hold on
%             axes(ha(2)), hold on
            % Scatter plot with t-SNE metrics
            plotGroupData(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',plotConnections(2),highlight)
            ha(2).XLabel.String = 't-SNE';
            ha(2).YLabel.String = 't-SNE';
            ha(2).Title.String = 't-SNE';
            
            for jj = 1:length(plotOptions)
                set(fig,'CurrentAxes',ha(jj+2)), hold on
                customPlot(plotOptions{jj},cellIDs(j),general1,batchIDs1,ha(jj+2),0,highlight,13);
                if jj == 1
                    ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.electrodeGroup(cellIDs(j)))])
                end
            end
            for jj = length(plotOptions)+3:length(ha)-2
                set(ha(jj),'Visible','off')
            end
            if plotCellIDs~=-1
                set(fig,'CurrentAxes',ha(end-1)), hold on
                set(ha(end-1),'Visible','off'); hold on
                plotCharacteristics(cellIDs(j)), title('Characteristics')
            else
                % Plots session stats
                set(fig,'CurrentAxes',ha(end-1)), hold on
                set(ha(end-1),'Visible','off'); hold on
                plotSessionStats, title('Session stats')
            end
            set(fig,'CurrentAxes',ha(end)), hold on
            set(fig,'Visible','off');  hold on
            plotLegends, title('Characteristics')
            % Saving figure
            if ishandle(fig)
                try
                    if highlight == 0
                        ce_savefigure2(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)}, '.CellExplorer_SessionSummary_', saveAs],0)
                    else
                        ce_savefigure2(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)}, '.CellExplorer_CellSummary_',saveAs,'_cell_', num2str(cell_metrics.UID(cellIDs(j)))],0)
                    end
                catch 
                    disp('figure not saved (action canceled by user or directory not available for writing)')
                    movegui(fig,'center'), set(fig,'visible','on')
                    
                end
            end
        end
        if ishandle(ce_waitbar1)
            close(ce_waitbar1)
        end
        movegui(fig,'center'), set(fig,'visible','on')
        
        function ce_savefigure2(fig,savePathIn,fileNameIn,dispSave)
            savePath = fullfile(savePathIn,'summaryFigures');
            if ~exist(savePath,'dir')
                mkdir(savePathIn,'summaryFigures')
            end
            saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
            if plotCellIDs~=-1
                clf(fig)
            end
            if exist('dispSave','var') && dispSave
                disp(['Figure saved: ', fileNameIn])
            end
        end
        
    end

    function setColumn1_metric(src,~)
        if isfield(src,'Text')
            UI.tableData.Column1 = src.Text;
        else
            UI.tableData.Column1 = src.Label;
        end
        for i = 1:length(UI.params.tableDataSortingList)
            UI.menu.tableData.column1_ops(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.Column1,UI.params.tableDataSortingList));
        UI.menu.tableData.column1_ops(idx).Checked = 'on';
        if UI.preferences.metricsTable==2
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
        for i = 1:length(UI.params.tableDataSortingList)
            UI.menu.tableData.column2_ops(i).Checked = 'off';
        end
        idx = find(strcmp(UI.tableData.Column2,UI.params.tableDataSortingList));
        UI.menu.tableData.column2_ops(idx).Checked = 'on';
        if UI.preferences.metricsTable==2
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
            elseif exist(fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename,'.session.mat']),'file')
                gui_session(fullfile(cell_metrics.general.basepath,[cell_metrics.general.basename,'.session.mat']));
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
                    UI.preferences.metricsTable = 1;
                case 'Cell list'
                    UI.preferences.metricsTable = 2;
                case 'None'
                    UI.preferences.metricsTable = 3;
            end
        end
        if UI.preferences.metricsTable==1
            UI.menu.tableData.ops(1).Checked = 'on';
            UI.menu.tableData.ops(2).Checked = 'off';
            UI.menu.tableData.ops(3).Checked = 'off';
            updateTableColumnWidth
            UI.table.ColumnName = {'Metrics',''};
            UI.table.Data = [table_fieldsNames,table_metrics(:,ii)];
            UI.table.Visible = 'on';
            UI.table.ColumnEditable = [false false];
        elseif UI.preferences.metricsTable==2
            UI.menu.tableData.ops(1).Checked = 'off';
            UI.menu.tableData.ops(2).Checked = 'on';
            UI.menu.tableData.ops(3).Checked = 'off';
            updateTableColumnWidth
            UI.table.ColumnName = {'','#','Cell type','Region'};
            UI.table.ColumnEditable = [true false false false];
            updateCellTableData
            UI.table.Visible = 'on';
            updateTableClickedCells
        elseif UI.preferences.metricsTable==3
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
            UI.preferences.customPlotHistograms = 1;
            UI.checkbox.logz.Enable = 'Off';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'Off';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.preferences.plot3axis = 0;
            
        elseif UI.popupmenu.metricsPlot.Value == 2
            UI.preferences.customPlotHistograms = 2;
            UI.checkbox.logz.Enable = 'Off';
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'Off';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.preferences.plot3axis = 0;
            
        elseif UI.popupmenu.metricsPlot.Value == 3
            UI.preferences.customPlotHistograms = 3;
            UI.popupmenu.yData.Enable = 'On';
            UI.popupmenu.zData.Enable = 'On';
            UI.checkbox.logz.Enable = 'On';
            UI.checkbox.logy.Enable = 'On';
            UI.popupmenu.markerSizeData.Enable = 'On';
            UI.checkbox.logMarkerSize.Enable = 'On';
            UI.preferences.plot3axis = 1;
             set(UI.fig,'CurrentAxes',UI.panel.subfig_ax(1).Children(end)) % Peter
            view([40 20]);

        elseif UI.popupmenu.metricsPlot.Value == 4
            UI.preferences.customPlotHistograms = 4;
            UI.checkbox.logz.Enable = 'Off';
            UI.checkbox.logy.Enable = 'Off';
            UI.popupmenu.yData.Enable = 'Off';
            UI.popupmenu.zData.Enable = 'Off';
            UI.popupmenu.markerSizeData.Enable = 'Off';
            UI.checkbox.logMarkerSize.Enable = 'Off';
            UI.preferences.plot3axis = 0;
        end
        uiresume(UI.fig);
    end

    function toggleWaveformsPlot(src,evnt)
        for i = 1:6
            UI.preferences.customPlot{i} = UI.popupmenu.customplot{i}.String{UI.popupmenu.customplot{i}.Value};
        end
        uiresume(UI.fig);
    end

    function toggleACGfit(~,~)
        % Enable/Disable the ACG fit
        if plotAcgFit == 0
            plotAcgFit = 1;
            UI.menu.ACG.showFit.Checked = 'on';
        elseif plotAcgFit == 1
            plotAcgFit = 0;
            UI.menu.ACG.showFit.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
    function toggleACG_ylog(~,~)
        % Enable/Disable the ACG log y-axis
        if plotAcgYLog == 0
            plotAcgYLog = 1;
            plotAcgZscore = 0;
            UI.menu.ACG.logY.Checked = 'on';
            UI.menu.ACG.z_scored.Checked = 'off';
        elseif plotAcgYLog == 1
            plotAcgYLog = 0;
            plotAcgZscore = 0;
            UI.menu.ACG.logY.Checked = 'off';
            UI.menu.ACG.z_scored.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    function toggleACG_zscored(~,~)
        % Enable/Disable the ACG log y-axis
        if plotAcgZscore == 0
            plotAcgZscore = 1;
            plotAcgYLog = 0;
            UI.menu.ACG.z_scored.Checked = 'on';
            UI.menu.ACG.logY.Checked = 'off';
        elseif plotAcgZscore == 1
            plotAcgZscore = 0;
            plotAcgYLog = 0;
            UI.menu.ACG.z_scored.Checked = 'off';
            UI.menu.ACG.logY.Checked = 'off';
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
        
        actionList = strcat([{'---------------- Assignments -----------------','Assign cell-type','Assign label','Assign deep/superficial','Assign tag','Assign group','-------------------- CCGs ---------------------','CCGs ','CCGs (only with selected cell)','----------- MULTI PLOT OPTIONS ----------','Row-wise plots (5 cells per figure)','Plot-on-top (one figure for all cells)','Dedicated figures (one figure per cell)','--------------- SINGLE PLOTS ---------------'},plotOptions']);
        brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', actionList, 'Position', [10, 50, 280, 270],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', ['Select action to perform on ', num2str(length(cellIDs)) ,' selected cells'], 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(brainRegionsList)
        uiwait(GoTo_dialog);
        
        function  CloseGoTo_dialog(cellIDs)
            choice = brainRegionsList.Value;
            MsgLog(['Action selected: ' actionList{choice} ' for ' num2str(length(cellIDs)) ' cells']);
            if any(choice == [2:6,8:9,11:13,15:length(actionList)])
                delete(GoTo_dialog);
                
                if choice == 2
                    [selectedClas,~] = listdlg('PromptString',['Assign cell-type to ' num2str(length(cellIDs)) ' cells'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
                    if ~isempty(selectedClas) && selectedClas < numel(colored_string)
                        saveStateToHistory(cellIDs)
                        clusClas(cellIDs) = selectedClas;
                        updateCellCount
                        MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.preferences.cellTypes{selectedClas}]);
                        updatePlotClas
                        updatePutativeCellType
                        uiresume(UI.fig);
                    elseif ~isempty(selectedClas) && selectedClas == numel(colored_string)
                        AddNewCellType
                        selectedClas = length(colored_string); % Last entry is the not a a real cell type
                        if ~isempty(selectedClas)
                            saveStateToHistory(cellIDs)
                            clusClas(cellIDs) = selectedClas-1;
                            updateCellCount
                            MsgLog([num2str(length(cellIDs)), ' cells assigned to ', UI.preferences.cellTypes{selectedClas-1}]);
                            updatePlotClas
                            updatePutativeCellType
                            uiresume(UI.fig);
                        end
                    end
                    
                elseif choice == 3
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
                    
                elseif choice == 4
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
                    
                elseif choice == 5
                    % Assign tags
                    assignGroup(cellIDs,'tags')
                    updateTags
                    uiresume(UI.fig);
                    
                elseif choice == 6
                    assignGroup(cellIDs,'groups')
                    
                elseif choice == 8
                    % All CCGs for all combinations of selected cell with highlighted cells
                    UI.params.ClickedCells = cellIDs(:)';
                    updateTableClickedCells
                    general = generateCCGs(cell_metrics.batchIDs(ii),general); % Generates CCGs from spikes
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
                        ccgFigure = figure('Name',['CellExplorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.preferences.figureSize,'visible','off');
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        try 
                        ha = ce_tight_subplot(length(plot_cells),length(plot_cells),[.03 .03],[.06 .05],[.04 .05]);
                        catch
                            MsgLog(['The number of selected cells are too high (', num2str(length(plot_cells)), ')'],4);
                            return
                        end
                        for j = 1:length(plot_cells)
                            for jj = 1:length(plot_cells)
                                set(ccgFigure,'CurrentAxes',ha(k))
                                if jj == j
                                    col1 = UI.preferences.cellTypeColors(clusClas(plot_cells(j)),:);
                                    bar_from_patch_centered_bins(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),col1)
                                    title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.electrodeGroup(plot_cells(j))) ]),
                                    xlabel(cell_metrics.putativeCellType{plot_cells(j)})
                                else
                                    bar_from_patch_centered_bins(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),[0.5,0.5,0.5])
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
                                axis tight, set(ha(k), 'YGrid', 'off', 'XGrid', 'on');
                                if any(cell_metrics.putativeConnections.excitatory(:,1)==plot_cells(j) & cell_metrics.putativeConnections.excitatory(:,2) ==plot_cells(jj))
                                    text(0,1,[' Exc: ', num2str(plot_cells(j)) ' \rightarrow ', num2str(plot_cells(jj))],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top')
                                end
%                                 if any(cell_metrics.putativeConnections.excitatory(:,2)==plot_cells(j) & cell_metrics.putativeConnections.excitatory(:,1) ==plot_cells(jj))
%                                     text(0,1,[' Exc: ', num2str(plot_cells(j)) ' \leftarrow ', num2str(plot_cells(jj))],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top')
%                                 end
                                
                                if any(cell_metrics.putativeConnections.inhibitory(:,1)==plot_cells(j) & cell_metrics.putativeConnections.inhibitory(:,2) ==plot_cells(jj))
                                    text(1,1,[' Inh: ', num2str(plot_cells(j)) ' \rightarrow ', num2str(plot_cells(jj)),' '],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top','HorizontalAlignment','right')
                                end
%                                 if any(cell_metrics.putativeConnections.inhibitory(:,2)==plot_cells(j) & cell_metrics.putativeConnections.inhibitory(:,1) ==plot_cells(jj))
%                                     text(0,1,[' Inh: ', num2str(plot_cells(j)) ' \leftarrow ', num2str(plot_cells(jj)),' '],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top','HorizontalAlignment','right')
%                                 end
                                set(ha(k), 'Layer', 'top')
                                k = k+1;
                            end
                        end
                        movegui(ccgFigure,'center'), set(ccgFigure,'visible','on')
                    else
                        MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (location general.ccg).',2)
                    end
                    
                elseif choice == 9
                    % CCGs with selected cell
                    UI.params.ClickedCells = cellIDs(:)';
                    updateTableClickedCells
                    general = generateCCGs(cell_metrics.batchIDs(ii),general); % Generates CCGs from spikes
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
                        fig = figure('Name',['CellExplorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.preferences.figureSize,'visible','off'); 
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        [plotRows,~]= numSubplots(length(plot_cells));
                        ha = ce_tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                        
                        for j = 2:length(plot_cells)
                            set(fig,'CurrentAxes',ha(k))
                            col1 = UI.preferences.cellTypeColors(clusClas(plot_cells(j)),:);
                            bar_from_patch_centered_bins(general.ccg_time*1000,general.ccg(:,plot_cells2(1),plot_cells2(j)),col1), hold on
                            if UI.monoSyn.dispHollowGauss && j > 1
                                norm_factor = cell_metrics.spikeCount(plot_cells2(1))*0.0005;
                                [ ~,pred] = ce_cch_conv(general.ccg(:,plot_cells2(1),plot_cells2(j))*norm_factor,20); hold on
                                nBonf = round(.004/0.001)*2; % alpha = 0.001;
                                % hiBound=poissinv(1-0.001/nBonf,pred);
                                hiBound=poissinv(1-0.001,pred);
                                line(general.ccg_time*1000,pred/norm_factor,'color','k')
                                line(general.ccg_time*1000,hiBound/norm_factor,'color','r')
                            end
                            
                            title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.electrodeGroup(plot_cells(j))),' (cluID ',num2str(cell_metrics.cluID(plot_cells(j))),')']),
                            xlabel(cell_metrics.putativeCellType{plot_cells(j)}), grid on
                            if j==2; ylabel('Rate (Hz)'); end
                            xticks([-50:10:50])
                            xlim([-50,50])
                            if length(plot_cells) > 2 && j <= plotRows(2)
                                set(ha(k),'XTickLabel',[]);
                            end
                            axis tight, set(ha(k), 'YGrid', 'off', 'XGrid', 'on');
                            if any(cell_metrics.putativeConnections.excitatory(:,1)==plot_cells(1) & cell_metrics.putativeConnections.excitatory(:,2) ==plot_cells(j))
                                text(0,1,[' Exc: ', num2str(plot_cells(1)) ' \rightarrow ', num2str(plot_cells(j))],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top')
                            end
                            if any(cell_metrics.putativeConnections.excitatory(:,2)==plot_cells(1) & cell_metrics.putativeConnections.excitatory(:,1) ==plot_cells(j))
                                text(0,1,[' Exc: ', num2str(plot_cells(1)) ' \leftarrow ', num2str(plot_cells(j))],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top')
                            end
                            if any(cell_metrics.putativeConnections.inhibitory(:,1)==plot_cells(1) & cell_metrics.putativeConnections.inhibitory(:,2) ==plot_cells(j))
                                text(1,1,[' Inh: ', num2str(plot_cells(1)) ' \rightarrow ', num2str(plot_cells(j)),' '],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top','HorizontalAlignment','right')
                            end
                            if any(cell_metrics.putativeConnections.inhibitory(:,2)==plot_cells(1) & cell_metrics.putativeConnections.inhibitory(:,1) ==plot_cells(j))
                                text(1,1,[' Inh: ', num2str(plot_cells(1)) ' \leftarrow ', num2str(plot_cells(j)),' '],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top','HorizontalAlignment','right')
                            end
                            set(ha(k), 'Layer', 'top')
                            k = k+1;
                        end
                        movegui(fig,'center'), set(fig,'visible','on')
                    else
                        MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                    end
                elseif any(choice == [11,12,13])
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
                    exportPlots.popupmenu.savePath = uicontrol('Parent',exportPlots.dialog,'Style','popupmenu','Position',[155, 40, 140, 25],'Units','normalized','String',{'basepath','CellExplorer','Define path'},'HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[5, 5, 140, 30],'String','OK','Callback',@ClosePlot_dialog,'Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[155, 5, 140, 30],'String','Cancel','Callback',@(src,evnt)CancelPlot_dialog,'Units','normalized');

                elseif choice > 14
                    % Plots any custom plot for selected cells in a single new figure with subplots
                    fig = figure('Name',['CellExplorer: ',actionList{choice},' for selected cells: ', num2str(cellIDs)],'NumberTitle','off','pos',UI.preferences.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off');
                    [plotRows,~]= numSubplots(length(cellIDs));
                    if ispc
                        ha = ce_tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
                    else
                        ha = ce_tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.05 .03],[.04 .03]);
                    end
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                        end
                        if ~isempty(UI.params.putativeSubse)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        set(fig,'CurrentAxes',ha(j)), hold on
                        customPlot(actionList{choice},cellIDs(j),general1,batchIDs1,ha(j),0,1,13); title(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.electrodeGroup(cellIDs(j)))])
                        if length(cellIDs)>25
                            plotAxes = ha(j);
                            plotAxes.XLabel.String = [];
                            plotAxes.YLabel.String = [];
                            plotAxes.Title.String = num2str(cellIDs(j));
                        end
                    end
                    movegui(fig,'center'), set(fig,'visible','on')
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
                if choice == 11 && ~isempty(selectedActions)
                    % Displayes a new dialog where a number of plot can be combined and plotted for the highlighted cells
                    plot_columns = min([length(cellIDs),5]);
                    nPlots = 1;
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.basepaths{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(UI.params.putativeSubse)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        
                        for jj = 1:length(selectedActions)
                            if mod(j,5)==1 && jj == 1
                                fig = figure('name',['CellExplorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.preferences.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                                ha = ce_tight_subplot(plot_columns,length(selectedActions),[.06 .03],[.08 .06],[.06 .05]); 
                                subPlotNum = 1;
                            else
                                subPlotNum = subPlotNum+1;
                            end
                            set(fig,'CurrentAxes',ha(subPlotNum))
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1,ha(subPlotNum),0,1,13);
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.electrodeGroup(cellIDs(j)))])
                            end
                            if (mod(j,5)==0 || j == length(cellIDs)) && jj == length(selectedActions)
                                ce_savefigure(gcf,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_MultipleCells_', num2str(nPlots)],saveFig)
                                nPlots = nPlots+1;
                            end
                        end
                    end
                    
                elseif choice == 12 && ~isempty(selectedActions)
                    
                    fig = figure('name',['CellExplorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.preferences.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                    [plotRows,~]= numSubplots(length(selectedActions));
                    ha = ce_tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.basepaths{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(UI.params.putativeSubse)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        for jjj = 1:length(selectedActions)
                            set(fig,'CurrentAxes',ha(jjj)), hold on
%                             subplot(plotRows(1),plotRows(2),jjj), hold on
                            customPlot(plotOptions{selectedActions(jjj)},cellIDs(j),general1,batchIDs1,ha(jjj),0,1,13);
                            title(plotOptions{selectedActions(jjj)},'Interpreter', 'none')
                        end
                    end
                    ce_savefigure(fig,savePath1,['CellExplorer_Cells_', num2str(cell_metrics.UID(cellIDs),'%d_')],0,saveFig)
                    
                elseif choice == 13 && ~isempty(selectedActions)
                    
                    [plotRows,~]= numSubplots(length(selectedActions)+3);
                    for j = 1:length(cellIDs)
                        if UI.BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                            savePath1 = cell_metrics.general.basepaths{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                            savePath1 = '';
                        end
                        if ~isempty(UI.params.putativeSubse)
                            UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                            UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                            UI.params.inbound = find(UI.params.a2 == cellIDs(j));
                            UI.params.outbound = find(UI.params.a1 == cellIDs(j));
                            UI.params.incoming = UI.params.a1(UI.params.inbound);
                            UI.params.outgoing = UI.params.a2(UI.params.outbound);
                            UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                        end
                        fig = figure('Name',['CellExplorer: cell ', num2str(cellIDs(j))],'NumberTitle','off','pos',UI.preferences.figureSize);
                        if ispc
                            ha = ce_tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
                        else
                            ha = ce_tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.05 .03],[.04 .03]);
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
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1,ha(jj+1),0,1,13);
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.electrodeGroup(cellIDs(j)))])
                            end
                        end
                        set(fig,'CurrentAxes',ha(length(selectedActions)+2))
                        plotLegends, title('Legend')
                        
                        set(fig,'CurrentAxes',ha(length(selectedActions)+3))
                        plotCharacteristics(cellIDs(j)), title('Characteristics')
                        
                        % Saving figure
                        ce_savefigure(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_cell_', num2str(cell_metrics.UID(cellIDs(j)))],0,saveFig)
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
        edit preferences_CellExplorer.m
    end

    function reclassify_celltypes(~,~)
        % Reclassify all cells according to the initial algorithm
        answer = questdlg('Are you sure you want to reclassify all your cells?', 'Reclassification', 'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                saveStateToHistory(1:cell_metrics.general.cellCount)
                
                preferences = preferences_ProcessCellMetrics;
                
                % All cells are initially assigned as Pyramidal cells
                cell_metrics.putativeCellType = repmat({'Pyramidal Cell'},1,size(cell_metrics.cellID,2));
                
                % Cells are reassigned as interneurons by below criteria
                % Narrow interneuron assigned if troughToPeak <= 0.425ms (preferences.putativeCellType.troughToPeak_boundary)
                cell_metrics.putativeCellType(cell_metrics.troughToPeak <= preferences.putativeCellType.troughToPeak_boundary) = repmat({'Narrow Interneuron'},sum(cell_metrics.troughToPeak <= preferences.putativeCellType.troughToPeak_boundary),1);
                
                % acg_tau_rise > 6 ms (preferences.putativeCellType.acg_tau_rise_boundary) and troughToPeak > 0.425ms
                cell_metrics.putativeCellType(cell_metrics.acg_tau_rise > preferences.putativeCellType.acg_tau_rise_boundary & cell_metrics.troughToPeak > preferences.putativeCellType.troughToPeak_boundary) = repmat({'Wide Interneuron'},sum(cell_metrics.acg_tau_rise > preferences.putativeCellType.acg_tau_rise_boundary  & cell_metrics.troughToPeak > preferences.putativeCellType.troughToPeak_boundary),1);
                
                % clusClas initialization
                clusClas = ones(1,length(cell_metrics.putativeCellType));
                for i = 1:length(UI.preferences.cellTypes)
                    clusClas(strcmp(cell_metrics.putativeCellType,UI.preferences.cellTypes{i}))=i;
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
            UI.params.alteredCellMetrics = 1;
            
            [cell_metrics.brainRegion_num,ID] = findgroups(cell_metrics.brainRegion);
            groups_ids.brainRegion_num = ID;
        else
            MsgLog('All steps have been undone. No further user actions tracked',2);
        end
        uiresume(UI.fig);
    end

    function updateCellCount
        % Updates the cell count in the cell-type listbox
        cell_class_count = histc(clusClas,1:length(UI.preferences.cellTypes));
        cell_class_count = cellstr(num2str(cell_class_count'))';
        UI.listbox.cellTypes.String = strcat(UI.preferences.cellTypes,' (',cell_class_count,')');
    end

    function updateCount
        % Updates the cell count in the custom groups listbox
        if GroupVal > 1
            if ColorVal ~= 2
                UI.classes.plot11 = cell_metrics.(colorStr{GroupVal});
                UI.classes.labels = groups_ids.([colorStr{GroupVal} '_num']);
                if iscell(UI.classes.plot11) && ~strcmp(colorStr{GroupVal},'deepSuperficial')
                    UI.classes.plot11 = findgroups(UI.classes.plot11);
                elseif strcmp(colorStr{GroupVal},'deepSuperficial')
                    [~,UI.classes.plot11] = ismember(UI.classes.plot11,UI.classes.labels);
                end
                color_class_count = histc(UI.classes.plot11,[1:length(UI.classes.labels)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(UI.classes.labels,' (',color_class_count,')');
            else
                UI.classes.plot = clusClas;
                UI.classes.labels = UI.preferences.cellTypes;
                UI.classes.plot2 = cell_metrics.(colorStr{GroupVal});
                UI.classes.labels2 = groups_ids.([colorStr{GroupVal} '_num']);
                if iscell(UI.classes.plot2) && ~strcmp(colorStr{GroupVal},'deepSuperficial')
                    UI.classes.plot2 = findgroups(UI.classes.plot2);
                elseif strcmp(colorStr{GroupVal},'deepSuperficial')
                    [~,UI.classes.plot2] = ismember(UI.classes.plot2,UI.classes.labels2);
                end
                color_class_count = histc(UI.classes.plot2,[1:length(UI.classes.labels2)]);
                color_class_count = cellstr(num2str(color_class_count'))';
                UI.listbox.groups.String = strcat(UI.classes.labels2,' (',color_class_count,')');
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
            case 'Create new file'
                filter = {'*.mat','MATLAB file (*.mat)';'*.json','JSON-formatted text file (*.json)';'*.nwb','Neurodata Without Borders (NWB) file (*.nwb)';'*.*','Any format (*.*)'};
                if UI.BatchMode
                    file = 'cell_metrics_batch.mat';
                else
                    file = 'cell_metrics.mat';
                end
                [file,SavePath] = uiputfile(filter,'Save metrics',file);
                if SavePath ~= 0
                    saveMetrics(cell_metrics,fullfile(SavePath,file));
                    try
                        
                    catch exception
                        disp(exception.identifier)
                        MsgLog('Failed to save file - see Command Window for details',[3,4]);
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
                saveCellMetrics(cell_metrics,file);
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
                catch
                    MsgLog(['Error saving backup for session: ' cell_metricsTemp.general.basenames{sessionID}],2);
                end
                try 
                    % Saving new metrics to file
                    matpath = fullfile(cell_metricsTemp.general.basepaths{sessionID},[cell_metricsTemp.general.basenames{sessionID}, '.',saveAs,'.cellinfo.mat']);
                    matFileCell_metrics = matfile(matpath,'Writable',true);
                    
                    cell_metrics = matFileCell_metrics.cell_metrics;
                    if length(cellSubset) == size(cell_metrics.putativeCellType,2)
                        % String fields
                        cell_metrics.labels = cell_metricsTemp.labels(cellSubset);
                        cell_metrics.deepSuperficial = cell_metricsTemp.deepSuperficial(cellSubset);
                        cell_metrics.deepSuperficialDistance = cell_metricsTemp.deepSuperficialDistance(cellSubset);
                        cell_metrics.brainRegion = cell_metricsTemp.brainRegion(cellSubset);
                        cell_metrics.putativeCellType = cell_metricsTemp.putativeCellType(cellSubset);
                        % Struct/group fields
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
            if isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs;
            else
                saveAs = 'cell_metrics';
            end
            file = [cell_metrics.general.basename, '.',saveAs,'.cellinfo.mat'];
            if ~(isfield(cell_metrics.general,'basepath') && exist(cell_metrics.general.basepath,'dir'))
                MsgLog(['Basepath does not exist, please save metrics via dialog'],4);
                filter = {'*.mat','MATLAB file (*.mat)';'*.json','JSON-formatted text file (*.json)';'*.nwb','Neurodata Without Borders (NWB) file (*.nwb)';'*.*','Any format (*.*)'};
                [file,SavePath] = uiputfile(filter,'Save metrics',file);
                cell_metrics.general.basename = SavePath;
            end
            try
                createBackup(cell_metrics)
            catch
                MsgLog(['Failed to save backup: ' cell_metrics.general.basepath],4);
            end
            
            try
                file = fullfile(cell_metrics.general.basepath,file);
                save(file,'cell_metrics');
                classificationTrackChanges = [];
                UI.menu.file.save.ForegroundColor = 'k';
                MsgLog(['Classification saved to ', file],[1,2]);
            catch
                MsgLog(['Failed to save the cell metrics. Please choose a different path: ' cell_metrics.general.basepath],4);
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
        
        if length(unique(UI.classes.plot(UI.params.subset)))==2
            % Cell metrics differences
            temp = fieldnames(cell_metrics);
            temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
            subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'batchIDs','placeCell','ripples_modulationSignificanceLevel','electrodeGroup','maxWaveformChannelOrder','maxWaveformCh','maxWaveformCh1','entryID','UID','cluID','truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter','sessionID'})));
            plotClas_subset = UI.classes.plot(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            
            temp1 = UI.params.subset(find(plotClas_subset==ids(1)));
            temp2 = UI.params.subset(find(plotClas_subset==ids(2)));
            testset = UI.classes.labels(nanUnique(plotClas_subset));
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
        subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'batchIDs','placeCell','_modulationSignificanceLevel','electrodeGroup','maxWaveformChannelOrder','maxWaveformCh','maxWaveformCh1','entryID','UID','cluID','truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter','sessionID'})));
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
            fig = figure('Name','CellExplorer: Raincloud plot','NumberTitle','off','pos',UI.preferences.figureSize,'visible','off');
            ha = ce_tight_subplot(plotRows(1),plotRows(2),[.05 .02],[.03 .04],[.03 .03]);
            plotClas_subset = UI.classes.plot(UI.params.subset);
            for j = 1:length(indx)
                fieldName = labels2{j};
                set(fig,'CurrentAxes',ha(j)), hold on
                if UI.checkbox.logx.Value == 1
                    set(ha(j), 'XScale', 'log')
                end
                generateGroupRainCloudPlot(fieldName,UI.checkbox.logx.Value,1,box_on,stats_offset,1)
            end
            
            % Generating legends
            legendNames = UI.classes.labels(nanUnique(UI.classes.plot(UI.params.subset)));
            for i = 1:length(legendNames)
                legendDots(i) = line(nan,nan,'Marker','.','LineStyle','none','color',UI.classes.colors(i,:), 'MarkerSize',20);
            end
            legend(legendDots,legendNames);
            
            % Clearing extra plot axes
            if length(indx)<plotRows(1)*plotRows(2)
                for j = length(indx)+1:plotRows(1)*plotRows(2)
                    set(ha(j),'Visible','off')
                end
            end
            movegui(fig,'center'), set(fig,'visible','on')
        end
    end

    function generateGroupRainCloudPlot(fieldName,log_axis,plotStats,box_on,stats_offset,scatter_on)
        if ~all(isnan(cell_metrics.(fieldName)(UI.params.subset)))
            plotClas_subset = UI.classes.plot(UI.params.subset);
            counter = 1; % For aligning scatter data
            ids = nanUnique(plotClas_subset);
            ids_count = histc(plotClas_subset, ids);
            if strcmp(UI.preferences.rainCloudNormalization,'Peak')
                ylim1 = [(-length(ids_count)/5),1];
                subfig_ax(1).YLabel.String = 'Normalized by peak';
                subfig_ax(1).YTick = [0:0.1:1];

            elseif strcmp(UI.preferences.rainCloudNormalization,'Count')
                ylim1 = [(-length(ids_count)/5),1]*max(ids_count)*0.3;
                subfig_ax(1).YLabel.String = 'Count';
%                 subfig_ax(1).YTick = [0:0.1:1];

            else % Probability
                ylim1 = [-length(ids_count)/5,1]*0.30;
                subfig_ax(1).YLabel.String = 'Probability';
                subfig_ax(1).YTick = [0:0.05:1];
            end
            
            ylim(ylim1);
            for i = 1:length(ids)
                temp1 = UI.params.subset(find(plotClas_subset==ids(i)));
                if length(temp1)>1
                    ce_raincloud_plot(cell_metrics.(fieldName)(temp1),'box_on',box_on,'box_dodge',1,'line_width',1,'color',UI.classes.colors(i,:),'alpha',0.4,'box_dodge_amount',0.025+(counter-1)*0.21,'dot_dodge_amount',0.13+(counter-1)*0.21,'bxfacecl',UI.classes.colors(i,:),'box_col_match',1,'randomNumbers',UI.params.randomNumbers(temp1),'log_axis',log_axis,'normalization',UI.preferences.rainCloudNormalization,'norm_value',(ids_count(i)),'scatter_on',scatter_on,'ylim',ylim1);
                    counter = counter + 1;
                end
            end
            axis tight, title(fieldName, 'interpreter', 'none'), %yticks([]),
            if nanmin(cell_metrics.(fieldName)(UI.params.subset)) ~= nanmax(cell_metrics.(fieldName)(UI.params.subset)) && log_axis == 0
                xlim([nanmin(cell_metrics.(fieldName)(UI.params.subset)),nanmax(cell_metrics.(fieldName)(UI.params.subset))])
            elseif nanmin(cell_metrics.(fieldName)(UI.params.subset)) ~= nanmax(cell_metrics.(fieldName)(UI.params.subset)) && log_axis == 1 && any(cell_metrics.(fieldName)>0)
                xlim([nanmin(cell_metrics.(fieldName)(intersect(UI.params.subset,find(cell_metrics.(fieldName)>0)))),nanmax(cell_metrics.(fieldName)(intersect(UI.params.subset,find(cell_metrics.(fieldName)>0))))])
            end
            if plotStats
                plotStatRelationship(cell_metrics.(fieldName),stats_offset,log_axis,ylim1) % Generates KS group statistics
            end
        else
            text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
        end
    end

    function plotStatRelationship(data1,stats_offset1,log_axis,ylim1) 
        plotClas_subset = UI.classes.plot(UI.params.subset);
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
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21]*ylim1(2),'color','k','linewidth',3,'HitTest','off')
                        elseif p < 0.05
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21]*ylim1(2),'color','k','linewidth',2,'HitTest','off')
                        else
                            line(stats_offset(counter)*[1,1],-[0.13+(j-1)*0.21,0.13+(i-1)*0.21]*ylim1(2),'LineStyle','-','color',[0.5 0.5 0.5],'HitTest','off')
                        end
                        counter = counter + 1;
                    end
                end
            end
            xlim([xlimits(1),stats_offset(counter)])
        end
    end

    

    function initializeSession
        
        ii = 1;
        hover2highlight.handle1 = [];
        hover2highlight.handle2 = [];
        hover2highlight.handle3 = [];
        hover2highlight.handle4 = [];
        UI.params.ii_history = 1;
        if ~isfield(cell_metrics,'electrodeGroup') && isfield(cell_metrics,'spikeGroup')
            cell_metrics.electrodeGroup = cell_metrics.spikeGroup;
        end
        if ~isfield(cell_metrics.general,'cellCount')
            cell_metrics.general.cellCount = size(cell_metrics.UID,2);
        end
        UI.params.randomNumbers = rand(1,cell_metrics.general.cellCount);
        
        if ~isfield(cell_metrics.general,'initialized')
            cell_metrics.general.initialized = 0;
        end
        % Initialize labels
        if ~isfield(cell_metrics, 'labels')
            cell_metrics.labels = repmat({''},1,cell_metrics.general.cellCount);
        end
        % Initialize groups
        if ~isfield(cell_metrics, 'groups')
            cell_metrics.groups = struct();
        end
        meanCCG = [];
        
        % Init group data
        UI.groupData1 = [];
        UI.groupData1.groupsList = {'groups','tags','groundTruthClassification'};
        
        % Updates format of tags if outdated
        cell_metrics = verifyGroupFormat(cell_metrics,'tags');
        if ~isfield(cell_metrics, 'tags')
            cell_metrics.tags = struct();
        end
        tagsInMetrics = fieldnames(cell_metrics.tags)';
        UI.preferences.tags = unique([UI.preferences.tags tagsInMetrics]);
        UI.preferences.tags(cellfun(@isempty, UI.preferences.tags)) = [];
        
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
        UI.preferences.groundTruth = unique([UI.preferences.groundTruth groundTruthInMetrics]);
        UI.preferences.groundTruth(cellfun(@isempty, UI.preferences.groundTruth)) = [];
        
        % Initialize text filter
        freeText = {''};
        idx_textFilter = 1:cell_metrics.general.cellCount;
        
        % Batch initialization
        if isfield(cell_metrics.general,'batch')
            UI.BatchMode = true;
            cell_metrics.general.basename = 'batch of sessions';
        else
            UI.BatchMode = false;
            cell_metrics.batchIDs = ones(1,cell_metrics.general.cellCount);
        end
        
        % Fieldnames
        metrics_fieldsNames = fieldnames(cell_metrics);
        table_fieldsNames = metrics_fieldsNames(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'cell','double'})));
        table_fieldsNames(find(contains(table_fieldsNames,UI.params.tableOptionsToExlude)))=[];
        
        % Cell type initialization
        UI.preferences.cellTypes = unique([UI.preferences.cellTypes,cell_metrics.putativeCellType],'stable');
        clusClas = ones(1,length(cell_metrics.putativeCellType));
        for i = 1:length(UI.preferences.cellTypes)
            clusClas(strcmp(cell_metrics.putativeCellType,UI.preferences.cellTypes{i}))=i;
        end
        colored_string = DefineCellTypeList;
        UI.classes.labels = UI.preferences.cellTypes;
        
        % SWR profile initialization
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
        % Plotting menues initialization
        fieldsMenuCells = metrics_fieldsNames;
        fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fieldsMenuCells(find(contains(fieldsMenuCells,UI.params.fieldsMenuMetricsToExlude)))=[];
        fieldsMenuCells = sort(fieldsMenuCells);
        groups_ids = [];
        
        for i = 1:length(fieldsMenuCells)
            if strcmp(fieldsMenuCells{i},'deepSuperficial')
                cell_metrics.deepSuperficial_num = ones(1,length(cell_metrics.deepSuperficial));
                for j = 1:length(UI.preferences.deepSuperficial)
                    cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.preferences.deepSuperficial{j}))=j;
                end
                groups_ids.deepSuperficial_num = UI.preferences.deepSuperficial;
            elseif iscell(cell_metrics.(fieldsMenuCells{i})) && size(cell_metrics.(fieldsMenuCells{i}),1) == 1 && size(cell_metrics.(fieldsMenuCells{i}),2) == cell_metrics.general.cellCount
                cell_metrics.(fieldsMenuCells{i})(find(cell2mat(cellfun(@(X) isempty(X), cell_metrics.animal,'uni',0)))) = {''};
                [cell_metrics.([fieldsMenuCells{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenuCells{i}));
                groups_ids.([fieldsMenuCells{i},'_num']) = ID;
            end
        end
        clear fieldsMenuCells
        
        UI.lists.metrics = fieldnames(cell_metrics);
        structDouble = strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'double');
        structSize = cell2mat(struct2cell(structfun(@size,cell_metrics,'UniformOutput',0)));
        structNumeric = cell2mat(struct2cell(structfun(@isnumeric,cell_metrics,'UniformOutput',0)));
        UI.lists.metrics = sort(UI.lists.metrics(structDouble & structNumeric & structSize(:,1) == 1 & structSize(:,2) == cell_metrics.general.cellCount));
        
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
        if UI.preferences.metricsTable==1
            UI.table.Data = [table_fieldsNames, table_metrics(:,ii)];
        elseif UI.preferences.metricsTable==2
            updateCellTableData;
        end
        
        step_size = [cellfun(@diff,cell_metrics.waveforms.time,'UniformOutput',false)];
        cell_metrics.waveforms.time_zscored = [max(cellfun(@min, cell_metrics.waveforms.time)):min([step_size{:}]):min(cellfun(@max, cell_metrics.waveforms.time))];
        
        % Response curves
        UI.x_bins.thetaPhase = [-1:0.05:1]*pi;
        UI.x_bins.thetaPhase = UI.x_bins.thetaPhase(1:end-1)+diff(UI.x_bins.thetaPhase([1,2]))/2;
        
        % Generating extra fields if necessary
        if ~cell_metrics.general.initialized | ~isfield(cell_metrics.waveforms,{'filt_zscored','filt_absolute'})
            
            statusUpdate('Initializing session')
            % waveform initialization
            filtWaveform = [];
            for i = 1:length(cell_metrics.waveforms.filt)
                if isempty(cell_metrics.waveforms.filt{i}) || any(isnan(cell_metrics.waveforms.filt{i}))
                    filtWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
                else
                    filtWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.filt{i},cell_metrics.waveforms.time_zscored,'spline',nan);
                end
            end
            cell_metrics.waveforms.filt_absolute = filtWaveform;
            cell_metrics.waveforms.filt_zscored = (filtWaveform-nanmean(filtWaveform))./nanstd(filtWaveform);
            
            % 'All raw waveforms'
            if isfield(cell_metrics.waveforms,'raw')
            rawWaveform = [];
            for i = 1:length(cell_metrics.waveforms.raw)
                if isempty(cell_metrics.waveforms.raw{i}) || any(isnan(cell_metrics.waveforms.raw{i}))
                    rawWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
                else
                    rawWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.raw{i},cell_metrics.waveforms.time_zscored,'spline',nan);
                end
            end
            cell_metrics.waveforms.raw_absolute = rawWaveform;
            cell_metrics.waveforms.raw_zscored = (rawWaveform-nanmean(rawWaveform))./nanstd(rawWaveform);
            clear rawWaveform
            end
            
            % ACGs
            cell_metrics.acg.wide_normalized = normalize_range(cell_metrics.acg.wide);
            cell_metrics.acg.narrow_normalized = normalize_range(cell_metrics.acg.narrow);
            
            if isfield(cell_metrics.acg,'log10')
            cell_metrics.acg.log10_rate = normalize_range(cell_metrics.acg.log10);
            cell_metrics.acg.log10_occurrence = normalize_range(cell_metrics.acg.log10.*diff(10.^UI.params.ACGLogIntervals)');
            end
            
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10);
            cell_metrics.isi.log10_occurrence = normalize_range(cell_metrics.isi.log10.*diff(10.^UI.params.ACGLogIntervals)');
            end
            
            if isfield(cell_metrics.responseCurves,'thetaPhase')
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
        
        if ~isfield(tSNE_metrics,'plot')
            if cell_metrics.general.cellCount>5000
                statusUpdate('Initializing PCA space for the t-SNE plot as cell count is above 5000.')
                UI.preferences.tSNE.metrics = intersect(UI.preferences.tSNE.metrics,fieldnames(cell_metrics));
                if ~isempty(UI.preferences.tSNE.metrics)
                    X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.preferences.tSNE.metrics,'UniformOutput',false));
                    X(isnan(X) | isinf(X)) = 0;
                    tSNE_metrics.plot = pca(X,'NumComponents',2);
                end
            else
                statusUpdate('Initializing t-SNE plot')
                UI.preferences.tSNE.metrics = intersect(UI.preferences.tSNE.metrics,fieldnames(cell_metrics));
                if ~isempty(UI.preferences.tSNE.metrics)
                    X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.preferences.tSNE.metrics,'UniformOutput',false));
                    X(isnan(X) | isinf(X)) = 0;
                    tSNE_metrics.plot = tsne(X','Standardize',true,'Distance',UI.preferences.tSNE.dDistanceMetric,'Exaggeration',UI.preferences.tSNE.exaggeration);
                end
            end
        end
        
        % Loading and defining labels
        UI = metrics_labels(UI);
        % Setting initial settings for plots, popups and listboxes
        UI.popupmenu.xData.String = UI.lists.metrics;
        UI.popupmenu.yData.String = UI.lists.metrics;
        UI.popupmenu.zData.String = UI.lists.metrics;
        plotX = cell_metrics.(UI.preferences.plotXdata);
        plotY  = cell_metrics.(UI.preferences.plotYdata);
        plotZ  = cell_metrics.(UI.preferences.plotZdata);
        plotMarkerSize  = cell_metrics.(UI.preferences.plotMarkerSizedata);
        
        UI.popupmenu.xData.Value = find(strcmp(UI.lists.metrics,UI.preferences.plotXdata));
        UI.popupmenu.yData.Value = find(strcmp(UI.lists.metrics,UI.preferences.plotYdata));
        UI.popupmenu.zData.Value = find(strcmp(UI.lists.metrics,UI.preferences.plotZdata));
        UI.popupmenu.markerSizeData.Value = find(strcmp(UI.lists.metrics,UI.preferences.plotMarkerSizedata));
        
        UI.plot.xTitle = UI.preferences.plotXdata;
        UI.plot.yTitle = UI.preferences.plotYdata;
        UI.plot.zTitle = UI.preferences.plotZdata;
        
        UI.listbox.cellTypes.Value = 1:length(UI.preferences.cellTypes);
        classes2plot = 1:length(UI.preferences.cellTypes);
        
        if isfield(cell_metrics,'putativeConnections')
            UI.monoSyn.disp = UI.preferences.monoSynDispIn;
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
        
        waveformOptions = {'Waveforms (single)';'Waveforms (all)';'Waveforms (group averages)'};
        if isfield(cell_metrics.waveforms,'filt_all') && isfield(cell_metrics.waveforms,'time_all')
            waveformOptions = [waveformOptions;'Waveforms (across channels)';'Waveforms (image across channels)'];
        end
        waveformOptions = [waveformOptions;'Waveforms (image)'];
        
        if isfield(cell_metrics.waveforms,'raw')
            waveformOptions = [waveformOptions;'Waveforms (raw single)';'Waveforms (raw all)'];
        end
        temp = fieldnames(cell_metrics.waveforms);
        temp(ismember(temp,{'filt_std','raw','raw_std','raw_all','filt_all','time_all','channels_all','filt','time','bestChannels'}) | ~structfun(@iscell,cell_metrics.waveforms)) = [];
        for i = 1:length(temp)
            waveformOptions = [waveformOptions;['Waveforms (',temp{i},')']];
        end
        
        if isfield(cell_metrics,'trilat_x') && isfield(cell_metrics,'trilat_y')
            waveformOptions = [waveformOptions;'Trilaterated position'];
        end
        if isfield(cell_metrics,'ccf_x') && isfield(cell_metrics,'ccf_y') && isfield(cell_metrics,'ccf_z')
            waveformOptions = [waveformOptions;'Common Coordinate Framework'];
        end
        
        acgOptions = {'ACGs (single)';'ACGs (all)';'ACGs (group averages)';'ACGs (image)';'CCGs (image)'};
        if isfield(cell_metrics,'isi')
            acgOptions = [acgOptions;'ISIs (single)';'ISIs (all)';'ISIs (image)'];
        end

        if isfield(cell_metrics.responseCurves,'thetaPhase_zscored')
            responseCurvesOptions = {'RCs_thetaPhase';'RCs_thetaPhase (all)';'RCs_thetaPhase (image)'};
        else
            responseCurvesOptions = {};
        end
        if isfield(cell_metrics.responseCurves,'firingRateAcrossTime')
            responseCurvesOptions = [responseCurvesOptions;'RCs_firingRateAcrossTime' ;'RCs_firingRateAcrossTime (image)' ;'RCs_firingRateAcrossTime (all)'];
        end
        
        responseCurvesFields = fieldnames(cell_metrics.responseCurves);
        for i = 1:numel(responseCurvesFields)
            if iscell(cell_metrics.responseCurves.(responseCurvesFields{i})) && all(size(cell_metrics.responseCurves.(responseCurvesFields{i})) == [1,cell_metrics.general.cellCount]) && ~ismember(responseCurvesFields{i},{'firingRateAcrossTime','thetaPhase'})
                responseCurvesOptions = [responseCurvesOptions;['RCs_',responseCurvesFields{i}];['RCs_',responseCurvesFields{i},' (image)'];['RCs_',responseCurvesFields{i},' (all)']];
            end
        end
        
        if isfield(cell_metrics,'spikes')
            rasterOption = {'Spike raster'};
        else
            rasterOption = [];
        end
        
        % Custom plot options
        if isdeployed
            customPlotOptions = {};
        else
            customPlotOptions = what('customPlots');
            customPlotOptions = cellfun(@(X) X(1:end-2),customPlotOptions.m,'UniformOutput', false);
            customPlotOptions(strcmpi(customPlotOptions,'template')) = [];
        end
        
        % cell_metricsFieldnames = fieldnames(cell_metrics,'-full');
        structFieldsType = metrics_fieldsNames(find(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'struct')));
        plotOptions = {};
        for j = 1:length(structFieldsType)
            if ~ismember(structFieldsType{j},{'general','putativeConnections','responseCurves'})
                plotOptions = [plotOptions;strcat(structFieldsType{j},{'_'},fieldnames(cell_metrics.(structFieldsType{j})))];
            end
        end

        if isfield(cell_metrics,'putativeConnections') && (isfield(cell_metrics.putativeConnections,'excitatory') || isfield(cell_metrics.putativeConnections,'inhibitory'))
        	monosynOptions = {'Connectivity graph'; 'Connectivity matrix'};
        else
            monosynOptions = [];
        end
        plotOptions(find(contains(plotOptions,UI.params.plotOptionsToExlude)))=[]; %
        plotOptions = unique([waveformOptions; acgOptions; monosynOptions; rasterOption; customPlotOptions; plotOptions;responseCurvesOptions],'stable');
        
        % Initilizing views
        for i = 1:6
            UI.popupmenu.customplot{i}.String = plotOptions;
            if any(strcmp(UI.preferences.customCellPlotIn{i},UI.popupmenu.customplot{i}.String)); UI.popupmenu.customplot{i}.Value = find(strcmp(UI.preferences.customCellPlotIn{i},UI.popupmenu.customplot{i}.String)); else; UI.popupmenu.customplot{i}.Value = 1; end
            UI.preferences.customPlot{i} = plotOptions{UI.popupmenu.customplot{i}.Value};
        end
        
        % Custom colorgroups
        colorMenu = metrics_fieldsNames;
        colorMenu = colorMenu(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fields2keep = [];
        for i = 1:length(colorMenu)
            if ~any(cell2mat(cellfun(@isnumeric,cell_metrics.(colorMenu{i}),'UniformOutput',false))) && ~contains(colorMenu{i},UI.params.menuOptionsToExlude )
                fields2keep = [fields2keep,i];
            end
        end
        colorMenu = ['cell-type';sort(colorMenu(fields2keep))];
        
        updateColorMenuCount
        
        UI.classes.plot = clusClas;
        UI.popupmenu.groups.Value = 1;
        UI.popupmenu.colors.Value = 1;
        ColorVal = 1;
        GroupVal = 1;
        clasLegend = 0;
        UI.preferences.customPlot{2} = UI.preferences.customCellPlotIn{2};
        
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
        fig2_axislimit_y = [min(cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise>0)),max(cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise<Inf))];
        fig3_axislimit_x = [min(tSNE_metrics.plot(:,1)), max(tSNE_metrics.plot(:,1))];
        fig3_axislimit_y = [min(tSNE_metrics.plot(:,2)), max(tSNE_metrics.plot(:,2))];
        
        % Updating reference and ground truth data if already loaded
        UI.preferences.referenceData = 'None';
        UI.preferences.groundTruthData = 'None';
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
        if isdeployed
            spikesPlots = {};
        else
            customSpikePlotOptions = what('customSpikesPlots');
            customSpikePlotOptions = cellfun(@(X) X(1:end-2),customSpikePlotOptions.m,'UniformOutput', false);
            customSpikePlotOptions(strcmpi(customSpikePlotOptions,'spikes_template')) = [];
            spikesPlots = {};
            for i = 1:length(customSpikePlotOptions)
                spikesPlots.(customSpikePlotOptions{i}) = customSpikesPlots.(customSpikePlotOptions{i});
            end
        end
        cell_metrics.general.initialized = 1;
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
            referenceData.cellTypes = unique([UI.preferences.cellTypes,cell_metrics.putativeCellType],'stable');
            clear referenceData1
            referenceData.clusClas = ones(1,length(cell_metrics.putativeCellType));
            for i = 1:length(referenceData.cellTypes)
                referenceData.clusClas(strcmp(cell_metrics.putativeCellType,referenceData.cellTypes{i}))=i;
            end
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas,[1:length(referenceData.cellTypes)+1])'))';
        else
            % Ground truth initialization
            clear groundTruthData1
%             referenceData.clusClas = ones(1,length(referenceData.clusClas));
            referenceData.groundTruthTypes = fieldnames(cell_metrics.groundTruthClassification)';
            for i = 1:numel(referenceData.groundTruthTypes)
                referenceData.clusClas(cell_metrics.groundTruthClassification.(referenceData.groundTruthTypes{i})) = i;
            end
%             [referenceData.clusClas, referenceData.groundTruthTypes] = findgroups([cell_metrics.groundTruthClassification{:}]);
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas)'))';
        end
        fig2_axislimit_x1 = [min([cell_metrics.troughToPeak * 1000,fig2_axislimit_x(1)]),max([cell_metrics.troughToPeak * 1000, fig2_axislimit_x(2)])];
        fig2_axislimit_y1 = [min([cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise>0),fig2_axislimit_y(1)]),max([cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise<Inf),fig2_axislimit_y(2)])];
        
        % Creating surface of reference points
        referenceData.x = linspace(fig2_axislimit_x1(1),fig2_axislimit_x1(2),UI.preferences.binCount);
        referenceData.y = 10.^(linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),UI.preferences.binCount));
        referenceData.y1 = linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),UI.preferences.binCount);
        
        if strcmp(inputType,'reference')
            colors = (1-(UI.preferences.cellTypeColors)) * 250;
        else
            colors = (1-(UI.preferences.groundTruthColors)) * 250;
        end
        temp = unique(referenceData.clusClas);
        
        referenceData.z = zeros(length(referenceData.x)-1,length(referenceData.y)-1,3,size(colors,1));
        for i = temp
            idx = find(referenceData.clusClas==i);
            [z_referenceData_temp,~,~] = histcounts2(cell_metrics.troughToPeak(idx) * 1000, cell_metrics.acg_tau_rise(idx),referenceData.x,referenceData.y,'norm','probability');
            referenceData.z(:,:,:,i) = bsxfun(@times,repmat(conv2(z_referenceData_temp,gauss2d,'same'),1,1,3),reshape(colors(i,:),1,1,[]));
            
        end
        referenceData.x = referenceData.x(1:end-1)+diff(referenceData.x([1,2]));
        referenceData.y = 10.^(linspace(log10(fig2_axislimit_y(1)),log10(fig2_axislimit_y(2)),UI.preferences.binCount) + (log10(fig2_axislimit_y(2))-log10(fig2_axislimit_y(1)))/UI.preferences.binCount/2);
        referenceData.y = referenceData.y(1:end-1);
        
        referenceData.selection = temp;
        
        % 'All filt waveforms'
        if ~isfield(cell_metrics.waveforms,'time_zscored')
            step_size = [cellfun(@diff,cell_metrics.waveforms.time,'UniformOutput',false)];
            cell_metrics.waveforms.time_zscored = [max(cellfun(@min, cell_metrics.waveforms.time)):min([step_size{:}]):min(cellfun(@max, cell_metrics.waveforms.time))];
        end
        if isfield(cell_metrics.waveforms,'filt')
            filtWaveform = [];
            for i = 1:length(cell_metrics.waveforms.filt)
                if isempty(cell_metrics.waveforms.filt{i})
                    filtWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
                else
                    filtWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.filt{i},cell_metrics.waveforms.time_zscored,'spline',nan);
                end
            end
            if ~isfield(cell_metrics.waveforms,'filt_zscored')  || size(cell_metrics.waveforms.filt,2) ~= size(cell_metrics.waveforms.filt_zscored,2)
                cell_metrics.waveforms.filt_zscored = (filtWaveform-nanmean(filtWaveform))./nanstd(filtWaveform);
            end
            clear filtWaveform
        end
        
        % 'All raw waveforms'
        if isfield(cell_metrics.waveforms,'raw')
            rawWaveform = [];
            for i = 1:length(cell_metrics.waveforms.raw)
                if isempty(cell_metrics.waveforms.raw{i})
                    rawWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
                else
                    rawWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.raw{i},cell_metrics.waveforms.time_zscored,'spline',nan);
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
            cell_metrics.acg.log10_occurrence = normalize_range(cell_metrics.acg.log10.*diff(10.^UI.params.ACGLogIntervals)');
        end
        
        if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10);
            cell_metrics.isi.log10_occurrence = normalize_range(cell_metrics.isi.log10.*diff(10.^UI.params.ACGLogIntervals)');
        end
    end

    function ToggleHeatmapFiringRateMaps(~,~)
        % Enable/Disable the ACG fit
        if ~UI.preferences.firingRateMap.showHeatmap
            UI.preferences.firingRateMap.showHeatmap = true;
            UI.menu.display.showHeatmap.Checked = 'on';
        else
            UI.preferences.firingRateMap.showHeatmap = false;
            UI.menu.display.showHeatmap.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function ToggleFiringRateMapShowLegend(~,~)
        % Enable/Disable the ACG fit
        if ~UI.preferences.firingRateMap.showLegend
            UI.preferences.firingRateMap.showLegend = true;
            UI.menu.display.firingRateMapShowLegend.Checked = 'on';
        else
            UI.preferences.firingRateMap.showLegend = false;
            UI.menu.display.firingRateMapShowLegend.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    function togglePlotLinearFits(~,~)
        % Enable/Disable the ACG fit
        if ~UI.preferences.plotLinearFits
            UI.preferences.plotLinearFits = 1;
            UI.menu.display.plotLinearFits.Checked = 'on';
        else
            UI.preferences.plotLinearFits = 0;
            UI.menu.display.plotLinearFits.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    

    function ToggleFiringRateMapShowHeatmapColorbar(~,~)
        % Enable/Disable the ACG fit
        if ~UI.preferences.firingRateMap.showHeatmapColorbar
            UI.preferences.firingRateMap.showHeatmapColorbar = true;
            UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on';
        else
            UI.preferences.firingRateMap.showHeatmapColorbar = false;
            UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function DatabaseSessionDialog(~,~)
        % Load sessions from the database.
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
        if exist('cell_metrics','var') && isfield(cell_metrics,'sessionName')
            sessionNames = cell_metrics.sessionName;
        else
            sessionNames = '';
        end
        [basenames,basepaths,exitMode] = gui_db_sessions(sessionNames);
        
        if ~isempty(basenames)
            % Setting paths from db struct
            ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading batch');
            cell_metrics1 = loadCellMetricsBatch('basenames',basenames,'basepaths',basepaths,'waitbar_handle',ce_waitbar);
            if ~isempty(cell_metrics1)
                cell_metrics = cell_metrics1;
            else
                if ishandle(ce_waitbar)
                    close(ce_waitbar)
                end
                if isfield(UI,'panel')
                    MsgLog('Failed to load datasets from database. Check the Command Window for further details',4);
                else
                    warning('Failed to load datasets from database.');
                end
                return
            end
            
            statusUpdate('Initializing session(s)')
            initializeSession
            if ishandle(ce_waitbar)
                close(ce_waitbar)
            end
            try
                if isfield(UI,'panel')
                    MsgLog([num2str(numel(basenames)),' session(s) loaded succesfully'],2);
                else
                    disp([num2str(numel(basenames)),' session(s) loaded succesfully']);
                end
                
            catch
                if isfield(UI,'panel')
                    MsgLog(['Failed to load dataset from database: ',strjoin(basenames)],4);
                else
                    disp(['Failed to load dataset from database: ',strjoin(basenames)]);
                end
            end
        elseif exitMode == 1
            if isfield(UI,'panel')
                MsgLog('No datasets selected.',2);
            else
                disp('No datasets selected');
            end
        end
        
        if ishandle(UI.fig)
            uiresume(UI.fig);
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
            if exist(fullfile(basepath,[basename, '.cell_metrics.cellinfo.mat']),'file')
                cd(basepath);
                load(fullfile(basepath,[basename, '.cell_metrics.cellinfo.mat']));
                cell_metrics.general.basepath = basepath;
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
        UI.preferences.layout = UI.popupmenu.plotCount.Value;
        AdjustGUI
    end
    
    function AdjustGUIkey
        UI.preferences.layout = rem(UI.preferences.layout,7)+1;
        AdjustGUI
    end
    
    function general = generateCCGs(batchIDsIn,general)
        if (~isfield(general,'ccg') || size(general.ccg,2) < general.cellCount) && isfield(cell_metrics,'spikes') && isfield(cell_metrics.spikes,'times')
            if UI.BatchMode
                subset1 = find(cell_metrics.batchIDs==cell_metrics.batchIDs(ii));
                if numel(cell_metrics.spikes.times) < max(subset1)
                   return 
                end
            else
                subset1 = 1:numel(cell_metrics.spikes.times);
            end
            if sum(cell_metrics.spikeCount(subset1)) > 10000000
                answer = questdlg(['Do you want to generate CCGs for this session? This can take a while when nSpikes = ', num2str(sum(cell_metrics.spikeCount(subset1)))], 'Generate CCGs', 'Yes','Cancel','Yes');
                if strcmp(answer,'Cancel')
                   return 
                end
            end
            if sum(cell_metrics.spikeCount(subset1)) > 3000000
                ce_waitbar = waitbar(0,'Generating CCGs','Name',['Generating CCGs for ' general.basename],'WindowStyle','modal');
            end
            spindices = generateSpinDices(cell_metrics.spikes.times(subset1));
            spike_times = spindices(:,1); 
            spike_cluster_index = spindices(:,2);
            [~, ~, spike_cluster_index] = unique(spike_cluster_index);
            [ccg2,time2] = CCG(spike_times,spike_cluster_index,'binSize',0.0005,'duration',0.100,'norm','rate');
            if UI.BatchMode
                cell_metrics.general.batch{batchIDsIn}.ccg = ccg2;
                cell_metrics.general.batch{batchIDsIn}.ccg_time = time2;
            else
                cell_metrics.general.ccg = ccg2;
                cell_metrics.general.ccg_time = time2;
            end
            general.ccg = ccg2;
            general.ccg_time = time2;
            if ishandle(ce_waitbar)
            	close(ce_waitbar)
            end
        end
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
                    basename1 = cell_metrics.general.basenames{batchIDsPrivate};
                    basepath1 = cell_metrics.general.basepaths{batchIDsPrivate};
                else
                    basename1 = cell_metrics.general.basename;
                    basepath1 = cell_metrics.general.basepath;
                end
                
                if exist(fullfile(basepath1,[basename1,'.spikes.cellinfo.mat']),'file')
                    if length(batchIDsIn)==1
                        ce_waitbar = waitbar(0,'Loading spike data','Name','Loading spikes data','WindowStyle','modal');
                    end
                    if ~ishandle(ce_waitbar)
                        MsgLog(['Spike loading canceled by the user'],2);
                        return
                    end
                    ce_waitbar = waitbar((batchIDsPrivate-1)/length(batchIDsIn),ce_waitbar,[num2str(batchIDsPrivate) '. Loading ', basename1]);
                    temp = load(fullfile(basepath1,[basename1,'.spikes.cellinfo.mat']));
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
                MsgLog('Spike data loaded',2);
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
        spikePlotList_dialog = dialog('Position', [300, 300, 750, 430],'Name','Spike plot types','WindowStyle','modal','visible','off'); movegui(spikePlotList_dialog,'center'), set(spikePlotList_dialog,'visible','on')
        
        tableData = updateTableData(spikesPlots);
        spikePlot = uitable(spikePlotList_dialog,'Data',tableData,'Position',[10, 50, 730, 335],'ColumnWidth',{20 125 90 90 90 90 70 70 80},'columnname',{'','Plot name','X data','Y data','X label','Y label','State','Events','Event data'},'RowName',[],'ColumnEditable',[true false false false false false false false false]);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add plot','Callback',@(src,evnt)addPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[110, 10, 90, 30],'String','Edit plot','Callback',@(src,evnt)editPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[210, 10, 90, 30],'String','Delete plot','Callback',@(src,evnt)DeletePlot);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[630, 392, 110, 30],'String','Reset spike data','Callback',@(src,evnt)ResetSpikeData);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[510, 392, 110, 30],'String','Load all spike data','Callback',@(src,evnt)LoadAllSpikeData);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[310, 10, 130, 30],'String','Predefined plots','Callback',@(src,evnt)viewPredefinedCustomSpikesPlots);
        OK_button = uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[550, 10, 90, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlotList_dialog);
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
        spikePlotEventLegend = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 15 90 20],'Units','normalized','String','ID labels','HorizontalAlignment','left');
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
            if isfield(spikesPlots.(fieldtoedit),'eventIDlabels')
                spikePlotEventLegend.Value = spikesPlots.(fieldtoedit).eventIDlabels;
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
                spikesPlotsOut.(spikePlotName2).eventIDlabels = spikePlotEventLegend.Value;
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
            
            if axnum>3 && strcmp(UI.preferences.customPlot{axnum-3}(1:7),'spikes_')
                spikesPlotsOut = spikePlotsDlg(UI.preferences.customPlot{axnum-3});
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
        UI.groupData1.groupToList = 'groundTruthClassification';
        performGroundTruthClassification
        defineGroupData
    end

    function compareToReference(src,~)
        if isfield(src,'Text') && strcmp(src.Text,'Compare cell groups to reference data')
            inputReferenceData = 1;
            UI.classes.colors2 = UI.preferences.cellTypeColors(unique(referenceData.clusClas),:);
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
            classesToPlot = unique(UI.classes.plot(UI.params.subset));
            idx = {};
            for j = 1:length(classesToPlot)
                idx{j} = intersect(find(UI.classes.plot==classesToPlot(j)),UI.params.subset);
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
                    line(edges,[N,0],'color',UI.classes.colors(j,:),'linewidth',2)
                end
                subplot(2,n_selectedFields,k+n_selectedFields), hold on
                if inputReferenceData == 1
                    % Reference data
                    title('Reference data')
                    for j = 1:length(listClusClas_referenceData)
                        idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                        [N,edges] = histcounts(reference_cell_metrics.(selectedFields{regularFields(i)})(idx2),20, 'Normalization', 'probability');
                        line(edges,[N,0],'color',UI.classes.colors2(j,:),'linewidth',2)
                    end
                else
                    % Ground truth cells
                    title('Ground truth cells')
                    if ~isempty(subsetGroundTruth)
                        idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                        for jj = 1:length(idGroundTruth)
                            [N,edges] = histcounts(cell_metrics.(selectedFields{regularFields(i)})(subsetGroundTruth{idGroundTruth(jj)}),20, 'Normalization', 'probability');
                            line(edges,[N,0],'color',UI.classes.colors(j,:),'linewidth',2)
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
                        patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],UI.classes.colors(j,:),'EdgeColor','none','FaceAlpha',.2)
                        line(1:length(temp1), temp1, 'color', UI.classes.colors(j,:),'linewidth',2)
                    end
                    subplot(2,n_selectedFields,k+n_selectedFields),hold on
                    if inputReferenceData == 1
                        % Reference data
                        title('Reference data')
                        for j = 1:length(listClusClas_referenceData)
                            idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                            temp1 = mean(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2),2);
                            temp2 = std(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2),0,2);
                            patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],UI.classes.colors2(j,:),'EdgeColor','none','FaceAlpha',.2)
                            line(1:length(temp1), temp1, 'color', UI.classes.colors(j,:),'linewidth',2)
                        end
                    else
                        % Ground truth cells
                        title('Ground truth cells')
                        if ~isempty(subsetGroundTruth)
                            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                            for jj = 1:length(idGroundTruth)
                                temp1 = mean(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)}),2);
                                temp2 = std(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)}),0,2);
                                patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],UI.classes.colors(j,:),'EdgeColor','none','FaceAlpha',.2)
                                line(1:length(temp1), temp1, 'color', UI.classes.colors(j,:),'linewidth',2)
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
            path1 = cell_metrics.general.basepaths{batchIDs};
        else
            if isfield( cell_metrics.general,'basepath')
                basename1 = cell_metrics.general.basename;
                path1 = cell_metrics.general.basepath;
            else
                basename1 = cell_metrics.general.basename;
                path1 = cell_metrics.general.basepath;
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
            answer = questdlg('Do you want to save the manual monosynaptic curation?', 'Save monosynaptic curation', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                ce_waitbar = waitbar(0,' ','name','CellExplorer: Updating MonoSyn');
                if isfield(general,'saveAs')
                    saveAs = general.saveAs;
                else
                    saveAs = 'cell_metrics';
                end
%                 try
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
                    if ~isempty(cell_session.cell_metrics.putativeConnections.inhibitory)
                        cell_session.cell_metrics.synapticEffect(cell_session.cell_metrics.putativeConnections.inhibitory(:,1)) = repmat({'Inhibitory'},1,size(cell_session.cell_metrics.putativeConnections.inhibitory,1));
                    end
                    cell_session.cell_metrics.synapticConnectionsOut = zeros(1,cell_session.cell_metrics.general.cellCount);
                    cell_session.cell_metrics.synapticConnectionsIn = zeros(1,cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,1),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,1)));
                    cell_session.cell_metrics.synapticConnectionsOut(b) = a; cell_session.cell_metrics.synapticConnectionsOut = cell_session.cell_metrics.synapticConnectionsOut(1:cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,2),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,2)));
                    cell_session.cell_metrics.synapticConnectionsIn(b) = a; cell_session.cell_metrics.synapticConnectionsIn = cell_session.cell_metrics.synapticConnectionsIn(1:cell_session.cell_metrics.general.cellCount);
                    
                    save(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), '-struct', 'cell_session')
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
                        if ~isempty(cell_session.cell_metrics.putativeConnections.inhibitory)
                            ia = ismember(cell_metrics.putativeConnections.inhibitory(:,1), idx);
                            cell_metrics.putativeConnections.inhibitory(ia,:) = [];
                            cell_metrics.putativeConnections.inhibitory = [cell_metrics.putativeConnections.inhibitory;idx(mono_res.sig_con_inhibitory)];
                            cell_metrics.synapticEffect(idx(cell_session.cell_metrics.putativeConnections.inhibitory(:,1))) = repmat({'Inhibitory'},1,size(cell_session.cell_metrics.putativeConnections.inhibitory,1));
                        end
                        cell_metrics.synapticEffect(idx) = repmat({'Unknown'},1,cell_session.cell_metrics.general.cellCount);
                        cell_metrics.synapticEffect(idx(cell_session.cell_metrics.putativeConnections.excitatory(:,1))) = repmat({'Excitatory'},1,size(cell_session.cell_metrics.putativeConnections.excitatory,1));
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
%                 catch
%                     MsgLog('Synaptic connections adjustment failed. mono_res struct saved to workspace',4);
%                     assignin('base','mono_res_failed_to_save',mono_res);
%                 end
                
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
            % UI.preferences.groundTruth
            createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.preferences.groundTruth,'G/T')
        end
    end
    
    function createGroundTruthClassificationToggleMenu(childName,parentPanelName,buttonLabels,panelTitle)
        % INPUTS
        % parentPanelName: UI.panel.tabgroup1
        % childName:
        % buttonLabels:    UI.preferences.groundTruth
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
        if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag,UI.preferences.groundTruth)) && isvarname(NewTag{1})
            UI.preferences.groundTruth = [UI.preferences.groundTruth,NewTag];
            delete(UI.togglebutton.groundTruthClassification)
            createGroundTruthClassificationToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.preferences.groundTruth,'G/T')
            
            MsgLog(['New ground truth cell type added: ' NewTag{1}]);
            uiresume(UI.fig);
        end
    end

    function buttonGroundTruthClassification(input)
        saveStateToHistory(ii)
        if UI.togglebutton.groundTruthClassification(input).Value == 1
            if isfield(cell_metrics.groundTruthClassification,UI.preferences.groundTruth{input})
                cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{input}) = unique([cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{input}),ii]);
            else
                cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{input}) = ii;
            end
            UI.togglebutton.groundTruthClassification(input).FontWeight = 'bold';
            UI.togglebutton.groundTruthClassification(input).ForegroundColor = UI.colors.toggleButtons;
            
            MsgLog(['Cell ', num2str(ii), ' ground truth assigned: ', UI.preferences.groundTruth{input}]);
        else
            UI.togglebutton.groundTruthClassification(input).FontWeight = 'normal';
            UI.togglebutton.groundTruthClassification(input).ForegroundColor = [0 0 0];
            cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{input}) = setdiff(cell_metrics.groundTruthClassification.(UI.preferences.groundTruth{input}),ii);
            MsgLog(['Cell ', num2str(ii), ' ground truth removed: ', UI.preferences.groundTruth{input}]);
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
        if isnumeric(str2num(UI.textFilter.String)) && ~isempty(UI.textFilter.String) && ~isempty(str2num(UI.textFilter.String))
                idx_textFilter = str2num(UI.textFilter.String);
        elseif ~isempty(UI.textFilter.String) && ~strcmp(UI.textFilter.String,'Filter')
            if isempty(freeText) || UI.params.alteredCellMetrics == 1
                freeText = {''};
                fieldsMenuCells = fieldnames(cell_metrics);
                fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class, cell_metrics, 'UniformOutput', false)), 'cell'));
                for j = 1:length(fieldsMenuCells)
                    freeText = strcat(freeText, {' '}, cell_metrics.(fieldsMenuCells{j}));
                end
                UI.params.alteredCellMetrics = 0;
            end
            [newStr2,matches] = split(UI.textFilter.String,[" & "," | "," OR "," AND "]);
            idx_textFilter2 = zeros(length(newStr2),cell_metrics.general.cellCount);
            failCheck = 0;
            for i = 1:length(newStr2)
                if numel(newStr2{i})>11 && strcmp(newStr2{i}(1:12),'.brainRegion')
                    newStr = split(newStr2{i}(2:end),' ');
                    if numel(newStr)>1
                        if isempty(UI.brainRegions.relational_tree)
                             temp = load('brainRegions_relational_tree.mat','relational_tree');
                             UI.brainRegions.relational_tree = temp.relational_tree;
                        end
                        acronym_out = getBrainRegionChildren(newStr{2},UI.brainRegions.relational_tree);
                        idx_textFilter2(i,:) = ismember(lower(cell_metrics.brainRegion),lower([acronym_out,newStr{2}]));
                    end
                elseif strcmp(newStr2{i}(1),'.')
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
                    idx_textFilter2(i,:) = contains(freeText,newStr2{i},'IgnoreCase',true);
                end
            end
            if failCheck == 0
                orPairs = find(contains(matches,{' | ',' OR '}));
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
        % -1: Only show message, no logging
        
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        message2 = sprintf('[%s] %s', timestamp, message);
        if ~exist('priority','var') || (exist('priority','var') && any(priority >= 0))
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
                msgbox(message,'CellExplorer',createStruct1);
            end
            if any(priority == 3)
                warning(message)
            end
            if any(priority == 4)
                warndlg(message,'CellExplorer')
            end
        end
    end

    function AdjustGUI(~,~)
        % Adjusts the number of subplots. 1-3 general plots can be displayed, 3-6 cell-specific plots can be
        % displayed. The necessary panels are re-sized and toggled for the requested number of plots.
        UI.popupmenu.plotCount.Value = UI.preferences.layout;
        if UI.preferences.layout == 1
            % GUI: 1+3 figures.
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax(2).Visible = 'off';
            UI.panel.subfig_ax(3).Visible = 'off';
            UI.panel.subfig_ax(7).Visible = 'off';
            UI.panel.subfig_ax(8).Visible = 'off';
            UI.panel.subfig_ax(9).Visible = 'off';
            UI.panel.subfig_ax(1).Position = [0    0    0.7 1];
            UI.panel.subfig_ax(4).Position = [0.70 0.67 0.3 0.33];
            UI.panel.subfig_ax(5).Position = [0.70 0.33 0.3 0.34];
            UI.panel.subfig_ax(6).Position = [0.70 0    0.3 0.33];
         elseif UI.preferences.layout == 2
            % GUI: 2+3 figures
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax(2).Visible = 'off';
            UI.panel.subfig_ax(3).Visible = 'on';
            UI.panel.subfig_ax(7).Visible = 'off';
            UI.panel.subfig_ax(8).Visible = 'off';
            UI.panel.subfig_ax(9).Visible = 'off';
            UI.panel.subfig_ax(1).Position = [0    0.4 0.5  0.6];
            UI.panel.subfig_ax(3).Position = [0.5  0.4 0.5  0.6];
            UI.panel.subfig_ax(4).Position = [0    0   0.33 0.4];
            UI.panel.subfig_ax(5).Position = [0.33 0   0.34 0.4];
            UI.panel.subfig_ax(6).Position = [0.67 0   0.33 0.4];
        elseif UI.preferences.layout == 3
            % GUI: 3+3 figures
            UI.popupmenu.customplot{4}.Enable = 'off';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax(2).Visible = 'on';
            UI.panel.subfig_ax(3).Visible = 'on';
            UI.panel.subfig_ax(7).Visible = 'off';
            UI.panel.subfig_ax(8).Visible = 'off';
            UI.panel.subfig_ax(9).Visible = 'off';
            UI.panel.subfig_ax(1).Position = [0    0.5 0.33 0.5];
            UI.panel.subfig_ax(2).Position = [0.33 0.5 0.34 0.5];
            UI.panel.subfig_ax(3).Position = [0.67 0.5 0.33 0.5];
            UI.panel.subfig_ax(4).Position = [0    0   0.33 0.5];
            UI.panel.subfig_ax(5).Position = [0.33 0   0.34 0.5];
            UI.panel.subfig_ax(6).Position = [0.67 0   0.33 0.5];
        elseif UI.preferences.layout == 4
            % GUI: 3+4 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'off';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax(2).Visible = 'on';
            UI.panel.subfig_ax(3).Visible = 'on';
            UI.panel.subfig_ax(7).Visible = 'on';
            UI.panel.subfig_ax(8).Visible = 'off';
            UI.panel.subfig_ax(9).Visible = 'off';
            UI.panel.subfig_ax(1).Position = [0    0.5  0.33 0.5];
            UI.panel.subfig_ax(2).Position = [0.33 0.5  0.34 0.5];
            UI.panel.subfig_ax(3).Position = [0.67 0.5  0.33 0.5];
            UI.panel.subfig_ax(4).Position = [0    0.25 0.33 0.25];
            UI.panel.subfig_ax(5).Position = [0.33 0    0.34 0.5];
            UI.panel.subfig_ax(6).Position = [0.67 0    0.33 0.5];
            UI.panel.subfig_ax(7).Position = [0    0    0.33 0.25];
        elseif UI.preferences.layout == 5
            % GUI: 3+5 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'off';
            UI.panel.subfig_ax(2).Visible = 'on';
            UI.panel.subfig_ax(3).Visible = 'on';
            UI.panel.subfig_ax(7).Visible = 'on';
            UI.panel.subfig_ax(8).Visible = 'on';
            UI.panel.subfig_ax(9).Visible = 'off';
            UI.panel.subfig_ax(1).Position = [0    0.5  0.33 0.5];
            UI.panel.subfig_ax(2).Position = [0.33 0.5  0.33 0.5];
            UI.panel.subfig_ax(3).Position = [0.67 0.5  0.33 0.5];
            UI.panel.subfig_ax(4).Position = [0    0.25 0.33 0.25];
            UI.panel.subfig_ax(5).Position = [0.33 0.25 0.34 0.25];
            UI.panel.subfig_ax(6).Position = [0.67 0    0.33 0.5];
            UI.panel.subfig_ax(7).Position = [0.0  0    0.34 0.25];
            UI.panel.subfig_ax(8).Position = [0.33 0    0.33 0.25];
        elseif UI.preferences.layout == 6
            % GUI: 3+6 figures
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'on';
            UI.panel.subfig_ax(2).Visible = 'on';
            UI.panel.subfig_ax(3).Visible = 'on';
            UI.panel.subfig_ax(7).Visible = 'on';
            UI.panel.subfig_ax(8).Visible = 'on';
            UI.panel.subfig_ax(9).Visible = 'on';
            UI.panel.subfig_ax(1).Position = [0    0.67  0.33 0.33];
            UI.panel.subfig_ax(2).Position = [0.33 0.67  0.34 0.33];
            UI.panel.subfig_ax(3).Position = [0.67 0.67  0.33 0.33];
            UI.panel.subfig_ax(4).Position = [0    0.33  0.33 0.34];
            UI.panel.subfig_ax(5).Position = [0.33 0.33  0.34 0.34];
            UI.panel.subfig_ax(6).Position = [0.67 0.33  0.33 0.34];
            UI.panel.subfig_ax(7).Position = [0    0     0.33 0.33];
            UI.panel.subfig_ax(8).Position = [0.33 0     0.34 0.33];
            UI.panel.subfig_ax(9).Position = [0.67 0     0.33 0.33];
        elseif UI.preferences.layout == 7
            % GUI: 1+6 figures.
            UI.popupmenu.customplot{4}.Enable = 'on';
            UI.popupmenu.customplot{5}.Enable = 'on';
            UI.popupmenu.customplot{6}.Enable = 'on';
            UI.panel.subfig_ax(2).Visible = 'off';
            UI.panel.subfig_ax(3).Visible = 'off';
            UI.panel.subfig_ax(7).Visible = 'on';
            UI.panel.subfig_ax(8).Visible = 'on';
            UI.panel.subfig_ax(9).Visible = 'on';
            UI.panel.subfig_ax(1).Position = [0    0    0.5  1];
            UI.panel.subfig_ax(4).Position = [0.5  0.67 0.25 0.33];
            UI.panel.subfig_ax(5).Position = [0.5  0.33 0.25 0.34];
            UI.panel.subfig_ax(6).Position = [0.5  0    0.25 0.33];
            UI.panel.subfig_ax(7).Position = [0.75 0.67 0.25 0.33];
            UI.panel.subfig_ax(8).Position = [0.75 0.33 0.25 0.34];
            UI.panel.subfig_ax(9).Position = [0.75 0    0.25 0.33];
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
        nRepetitions = min([100,numel(UI.params.subset)]); 

        [indx,~] = listdlg('PromptString','Which benchmarks do you want to perform?','ListString',{'Cell Exporer UI', 'Single plot figures', 'Cell metrics file loading','Reference data file loading'},'ListSize',[300,200],'InitialValue',1,'SelectionMode','many','Name','Benchmarks');
        if any(indx == 3)
            % Benchmarking file loading
            if isfield(cell_metrics.general,'batch_benchmark')
                x = cell_metrics.general.batch_benchmark.file_cell_count;
                y1 = cell_metrics.general.batch_benchmark.file_load;
                figure,
                plot(x,y1,'.b','markersize',15)
                P = polyfit(x,y1,1);
                yfit = P(1)*x+P(2);
                hold on;
                plot(x,yfit,'r-');
                title(['Benchmark of cell metrics file readings. ', num2str(1/P(1)),' cells per second']), xlabel('Cell count in metrics'), ylabel('Load time (seconds)'), axis tight
            else
                warning('batch_benchmark data does not exist in the cell metrics data')
            end
        end
        if any(indx == 4)
            % Benchmarking reference data file loading
            if isempty(reference_cell_metrics)
                out = loadReferenceData;
                if ~out
                    defineReferenceData;
                end
            end
            if isfield(reference_cell_metrics.general,'batch_benchmark')
            x = reference_cell_metrics.general.batch_benchmark.file_cell_count;
            y1 = reference_cell_metrics.general.batch_benchmark.file_load;
            figure,
            plot(x,y1,'.b','markersize',15)
            P = polyfit(x,y1,1);
            yfit = P(1)*x+P(2);
            hold on;
            plot(x,yfit,'r-');
            title(['Benchmark of reference cell metrics file readings. ', num2str(1/P(1)),' cells per second']), xlabel('Cell count in metrics'), ylabel('Load time (seconds)'), axis tight
            else
                warning('batch_benchmark data does not exist in the reference data')
            end
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
            text(8000*ones(1,size(x_mean,2)),x_mean(numel(testGroups),:),plotOptions1,'HorizontalAlignment','center','VerticalAlignment','bottom')
            figure(UI.fig)
        end
        if any(indx == 1)
            figure(UI.fig)
            % Benchmark of the CellExplorer UI. Runs three different layouts with 25 repetitions.
            t_bench = [];
            % 1. benchmark with minimum features
            UI.preferences.metricsTable = 3; % turning off table data
            buttonShowMetrics
            UI.panel.tabgroup2.SelectedTab = UI.tabs.dispTags_minus; % Deselecting figure legends
            UI.preferences.plotInsetChannelMap = 1; % Hiding channel map inset in waveform plots.
            UI.preferences.plotInsetACG = 1; % Hiding ACG inset in waveform plots.
            UI.preferences.customPlot{1} = 'ACGs (single)';
            UI.preferences.customPlot{2} = 'ACGs (single)';
            UI.preferences.customPlot{3} = 'ACGs (single)';
            UI.preferences.layout = 1; % GUI: 1+3 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % 2. benchmark
            UI.preferences.metricsTable = 1; % turning off table data
            buttonShowMetrics
            UI.panel.tabgroup2.SelectedTab = UI.tabs.legends; % Selecting figure legends
            UI.preferences.plotInsetChannelMap = 3; % Showing channel map inset in waveform plots.
            UI.preferences.plotInsetACG = 2; % Showing ACG inset in waveform plots.
            UI.preferences.customPlot{1} = 'Waveforms (all)';
            UI.preferences.customPlot{2} = 'ACGs (single)';
            UI.preferences.customPlot{3} = 'RCs_firingRateAcrossTime';
            UI.preferences.customPlot{4} = 'Waveforms (single)';
            UI.preferences.customPlot{5} = 'CCGs (image)';
            UI.preferences.customPlot{6} = 'ISIs (all)';
            UI.preferences.layout = 3; % GUI: 3+3 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % 3. benchmark
            UI.preferences.layout = 6; % GUI: 3+6 figures
            AdjustGUI
            t_bench1 = runBenchMarkRound;
            t_bench = [t_bench,t_bench1];
            
            % Plotting benchmark figure
            figure(50),
            subplot(2,1,1)
            plot(1000*diff(t_bench)); title('benchmarking UI'), xlabel('Test number'), ylabel('Processing time (ms)'), ylim([0,500]), set(gca, 'YScale', 'log')
            subplot(2,1,2)
            
            y1 = mean(1000*diff(t_bench));
            y_std = std(1000*diff(t_bench));
            idx = 1:length(testGroupsSizes);
            f1(1) = errorbarPatch(testGroupsSizes,y1(idx),y_std(idx),[0.8 0.2 0.2]);
            f1(2) = errorbarPatch(testGroupsSizes,y1(idx+length(idx)),y_std(idx+length(idx)),[0.2 0.8 0.2]);
            f1(3) = errorbarPatch(testGroupsSizes,y1(idx+length(idx)*2),y_std(idx+length(idx)*2),[0.2 0.2 0.8]);
            xlabel('Number of cells'), ylabel('Processing time (ms)'), ylim([0,800])
            legend(f1,{'Layout: 1+3','Layout: 3+3','Layout: 3+6 simple',}), title('Average processing times'), set(gca, 'YScale', 'log')
            figure(UI.fig)
        end
          
    function t_bench = runBenchMarkRound
        timerVal1 = tic;
        t_bench = [];
        for j = 1:numel(testGroups)
            UI.groupData1.groups.plus_filter.(testGroups{j}) = 1;
            pause(0.5)
            for i = 1:nRepetitions
                ii = cell_metrics.groups.(testGroups{j})(i);
                updateUI
                drawnow nocallbacks;
                t_bench(i,j) = toc(timerVal1);
            end
            UI.groupData1.groups.plus_filter.(testGroups{j}) = 0;
        end
    end
        function t_bench = runBenchMarkSinglePlot(plotOptionsIn)
            % Benchmarking single figures
            testFig1 = figure('pos',UI.preferences.figureSize,'name','Single cell plot benchmarks');
            testFig = gca;
            timerVal1 = tic;
            t_bench = [];
            for j = 1:numel(testGroups)
                UI.groupData1.groups.plus_filter.(testGroups{j}) = 1;
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
                        UI.params.putativeSubse = find(all(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)'));
                    else
                        UI.params.putativeSubse=[];
                        UI.params.incoming = [];
                        UI.params.outgoing = [];
                        UI.params.connections = [];
                    end
                    
                    if ~isempty(UI.params.putativeSubse)
                        UI.params.a1 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,1);
                        UI.params.a2 = cell_metrics.putativeConnections.excitatory(UI.params.putativeSubse,2);
                        UI.params.inbound = find(UI.params.a2 == ii);
                        UI.params.outbound = find(UI.params.a1 == ii);
                        UI.params.incoming = UI.params.a1(UI.params.inbound);
                        UI.params.outgoing = UI.params.a2(UI.params.outbound);
                        UI.params.connections = [UI.params.incoming;UI.params.outgoing];
                    end
                    
                    customPlot(plotOptionsIn,ii,general1,batchIDs1,testFig,0,1,13);
                    drawnow nocallbacks;
                    t_bench(i_rep,j) = toc(timerVal1);
                end
                UI.groupData1.groups.plus_filter.(testGroups{j}) = 0;
            end
            close(testFig1)
        end
    end

    function keyPress(~, event)
        % Keyboard shortcuts
        switch event.Key
            case 'f'
                goToCell
            case 'h'
                HelpDialog;
            case 'm'
                % Hide/show menubar
                ShowHideMenu
            case 'n'
                % Adjusts the number of subplots in the GUI
                AdjustGUIkey;
            case 'r'
                % Hide/show menubar
                resetZoom
            case 'z'
                % undoClassification;
            case 'j'
                editSelectedSpikePlot;
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
                previousSession
            case {'pageup','backquote'}
                % Goes to the first cell from the next session in a batch
                nextSession
            case 'rightarrow'
                if strcmp(event.Modifier,'shift')
                    nextSession
                else
                    advance;
                end
            case 'leftarrow'
                if strcmp(event.Modifier,'shift')
                    previousSession
                else
                    back;
                end
            case 'period'
                if strcmp(event.Modifier,'shift')
                    advanceClass
                else
                    advance10
                end
            case 'comma'
                if strcmp(event.Modifier,'shift')
                    backClass
                else
                    back10
                end
            case {'1','2','3','4','5','6','7','8','9'}
                if strcmp(event.Modifier,'shift')
                    advanceClass(str2double(event.Key))
                else
                    buttonCellType(str2double(event.Key));
                end
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                advanceClass(str2double(event.Key(end)))
            case 'numpad0'
                ii = 1;
                uiresume(UI.fig);
        end
    end
    
    function resetZoom
        axis tight
%         axnum = getAxisBelowCursor;
%         if ~isempty(axnum)
%             set(subfig_ax(axnum),'XLim',[0,UI.settings.windowDuration],'YLim',[0,1]);
%             axis tight
%         end
    end
    
    function nextSession
        if UI.BatchMode
            temp = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii)+1,1);
            if ~isempty(temp)
                ii =  UI.params.subset(temp);
                uiresume(UI.fig);
            end
        end
    end

    function previousSession
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
    end

    function ShowHideMenu(~,~)
        % Hide/show menubar
        if UI.preferences.displayMenu == 0
            set(UI.fig, 'MenuBar', 'figure')
            UI.preferences.displayMenu = 1;
            UI.menu.display.showHideMenu.Checked = 'On';
            fieldmenus = fieldnames(UI.menu);
            fieldmenus(strcmpi(fieldmenus,'CellExplorer')) = [];
            for i = 1:numel(fieldmenus)
                UI.menu.(fieldmenus{i}).topMenu.Visible = 'off';
            end
            MsgLog('Regular MATLAB menubar shown. Press M to regain the CellExplorer menubar',2);
        else
            set(UI.fig, 'MenuBar', 'None')
            UI.preferences.displayMenu = 0;
            UI.menu.display.showHideMenu.Checked = 'Off';
            fieldmenus = fieldnames(UI.menu);
            for i = 1:numel(fieldmenus)
                UI.menu.(fieldmenus{i}).topMenu.Visible = 'on';
            end
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
        [img, ~, alphachannel] = imread(fullfile(logog_path,'logoCellExplorer.png'));
        image(img, 'AlphaData', alphachannel,'ButtonDownFcn',@openWebsite);
        AboutWindow.image = gca;
        set(AboutWindow.image,'Color','none','Units','Pixels') , hold on, axis off
        AboutWindow.image.Position = pos_image;
        text(0,pos_text,{['\bfCellExplorer\rm v', num2str(CellExplorerVersion)],'By Peter Petersen.', 'Developed in the Buzsaki laboratory at NYU, USA.','\bf\color[rgb]{0. 0.2 0.5}https://CellExplorer.org/\rm'},'HorizontalAlignment','left','VerticalAlignment','top','ButtonDownFcn',@openWebsite, 'interpreter','tex')
    end

    function HelpDialog(~,~)
        if ismac; scs  = 'Cmd + '; else; scs  = 'Ctrl + '; end
        shortcutList = { '','<html><b>Navigation</b></html>';
            '> (right arrow)','Next cell'; '< (left arrow)','Previous cell'; '. (dot)','+10 cell (+shift: Next cell with same class)'; ', (comma) ','-10 cell (+shift: Previous cell with same class)';
            ['F '],'Go to a specific cell'; 'Page Up ','Next session in batch (only in batch mode)'; 'Page Down','Previous session in batch (only in batch mode)';
            'Numpad0','First cell'; 'Numpad1-9 ','Next cell with that numeric class'; 'Backspace','Previously selected cell'; 'Numeric + / - / *','Zoom in / zoom out / reset plots'; '   ',''; 
            '','<html><b>Cell assigments</b></html>';
            '1-9 ','Cell-types'; [scs,'B'],'Brain region'; [scs,'L'],'Label'; [scs,'Z'],'Undo assignment'; ' ',' ';
            '','<html><b>Display shortcuts</b></html>';
            'M','Show/Hide menubar'; 'N','Change layout [6; 5 or 4 subplots]'; [scs,'E'],'Highlight excitatory cells (triangles)'; [scs,'I'],'Highlight inhibitory cells (circles)';
            [scs,'F'],'Display ACG fit'; 'K','Calculate and display significance matrix for all metrics (KS-test)'; [scs,'T'],'Calculate tSNE space from a selection of metrics';
            'W','Display waveform metrics'; [scs,'Y'],'Perform ground truth cell type classification'; [scs,'U'],'Load ground truth cell types'; 'Space','Show action dialog'; 'R','Reset zoom'; '  ','';
            '','<html><b>Other shortcuts</b></html>';
            [scs,'P'],'Polygon selection of cells'; [scs,'C'],'Open the file directory of the selected cell'; [scs,'D'],'Opens sessions from BuzLabDB';
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
