function cell_metrics = CellExplorer(varargin)
% The Cell Explorer is a Matlab GUI and standardized pipeline for exploring and 
% classifying spike sorted single units acquired using extracellular electrodes.
% Check out the wiki for extensive documentation: https://github.com/petersenpeter/Cell-Explorer/wiki
%
% Below follows a detailed description of how to call the Cell Explorer
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
% CellExplorer                             % Load from current path, assumed to be a basepath
% CellExplorer('basepath',basepath)        % Load from basepath
% CellExplorer('metrics',cell_metrics)     % Load from cell_metrics
% CellExplorer('session',session)          % Load session from session struct
% CellExplorer('sessionName','rec1')       % Load session from database session name
% CellExplorer('sessionID',10985)          % Load session from database session id
% CellExplorer('sessions',{'rec1','rec2'}) % Load batch from database
% CellExplorer('sessionIDs',[10985,2845])  % Load batch from database
% CellExplorer('clusteringpaths',{'path1','path1'}) % Load batch from a list with paths
% CellExplorer('basepaths',{'path1','[path1'}) % Load batch from a list with paths
%
% OUTPUT
% cell_metrics: struct

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 21-12-2019

% Shortcuts to built-in functions
% initializeSession, DatabaseSessionDialog, saveDialog, restoreBackup, keyPress, defineSpikesPlots, customPlot, importGroundTruth
% GroupAction, brainRegionDlg, FromPlot, GroupSelectFromPlot, tSNE_redefineMetrics, ScrolltoZoomInPlot, defineReferenceData

p = inputParser;

addParameter(p,'metrics',[],@isstruct);
addParameter(p,'basepath',pwd,@isstr);
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
addParameter(p,'summaryFigures',false,@islogical);

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

%% % % % % % % % % % % % % % % % % % % % % %
% Initialization of variables and figure
% % % % % % % % % % % % % % % % % % % % % %

UI = []; UI.settings.plotZLog = 0; UI.settings.plot3axis = 0; UI.settings.plotXdata = 'firingRate'; UI.settings.plotYdata = 'peakVoltage';
UI.settings.plotZdata = 'deepSuperficialDistance'; UI.settings.metricsTableType = 'Metrics'; colorStr = [];
UI.settings.deepSuperficial = ''; UI.settings.acgType = 'Normal'; UI.settings.cellTypeColors = []; UI.settings.monoSynDispIn = 'None';
UI.settings.layout = 3; UI.settings.displayMenu = 0; UI.settings.displayInhibitory = false; UI.settings.displayExcitatory = false;
UI.settings.customCellPlotIn1 = 'Waveforms (single)'; UI.settings.customCellPlotIn2 = 'ACGs (single)';
UI.settings.customCellPlotIn3 = 'thetaPhaseResponse'; UI.settings.customCellPlotIn4 = 'firingRateMap';
UI.settings.customCellPlotIn5 = 'firingRateMap'; UI.settings.customCellPlotIn6 = 'firingRateMap'; UI.settings.plotCountIn = 'GUI 3+3';
UI.settings.tSNE.calcNarrowAcg = true; UI.settings.tSNE.calcFiltWaveform = true; UI.settings.tSNE.metrics = '';
UI.settings.tSNE.calcWideAcg = true; UI.settings.dispLegend = 1; UI.settings.tags = {'good','bad','mua','noise','inverseSpike','Other'};
UI.settings.groundTruthMarkers = {'d','o','s','*','+','p'}; UI.settings.groundTruth = {'PV+','NOS1+','GAT1+'};
UI.settings.plotWaveformMetrics = 1; UI.settings.metricsTable = 1; synConnectOptions = {'None', 'Selected', 'Upstream', 'Downstream', 'Up & downstream', 'All'};
UI.settings.stickySelection = false; UI.settings.fieldsMenuMetricsToExlude  = {'tags','groundTruthClassification'};
UI.settings.plotOptionsToExlude = {'acg_','waveforms_','isi_','responseCurves_thetaPhase_zscored'}; UI.settings.tSNE.dDistanceMetric = 'euclidean';
UI.settings.menuOptionsToExlude = {'putativeCellType','tags','groundTruthClassification'}; UI.params.inbound = [];
UI.settings.tableOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','brainRegion','labels','deepSuperficial'};
UI.settings.tableDataSortingList = sort({'cellID', 'putativeCellType','peakVoltage','firingRate','troughToPeak','synapticConnectionsOut','synapticConnectionsIn','animal','sessionName','cv2','brainRegion','spikeGroup'});
UI.settings.firingRateMap.showHeatmap = false; UI.settings.firingRateMap.showLegend = false; UI.settings.firingRateMap.showHeatmapColorbar = false;
UI.settings.referenceData = 'None'; UI.settings.groundTruthData = 'None'; UI.BatchMode = false; UI.params.ii_history = 1; UI.params.ClickedCells = [];
UI.params.incoming = []; UI.params.outgoing = []; UI.monoSyn.disp = ''; UI.monoSyn.dispHollowGauss = true;
tableDataSortBy = 'cellID'; tableDataColumn1 = 'putativeCellType'; tableDataColumn2 = 'brainRegion';  groups_ids = []; plotX_title = ''; plotY_title = ''; plotZ_title = '';
db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = []; timerVal = tic;
classes2plot = []; classes2plotSubset = []; fieldsMenu = []; table_metrics = []; ii = []; history_classification = [];
brainRegions_list = []; brainRegions_acronym = []; cell_class_count = [];  customCellPlot3 = 1; customCellPlot4 = 1; plotOptions = '';
customCellPlot1 = ''; customPlotHistograms = 0; plotAcgFit = 0; clasLegend = 0; Colorval = 1; plotClas = []; plotClas11 = [];
colorMenu = []; groups2plot = []; groups2plot2 = []; plotClasGroups2 = [];  customCellPlot2 = '';
plotClasGroups = [];  plotClas2 = []; general = []; plotAverage_nbins = 40; table_fieldsNames = {};
cellsExcitatory = []; cellsInhibitory = []; cellsInhibitory_subset = []; cellsExcitatory_subset = []; 
subsetPlots1 = []; subsetPlots2 = []; subsetPlots3 = []; subsetPlots4 = []; subsetPlots5 = []; subsetPlots6 = [];
tSNE_metrics = [];  classificationTrackChanges = []; time_waveforms_zscored = []; spikes = [];
spikesPlots = {}; globalZoom = cell(1,9); globalZoomLog = cell(1,9); createStruct.Interpreter = 'tex'; createStruct.WindowStyle = 'modal'; events = [];
fig2_axislimit_x = []; fig2_axislimit_y = []; fig3_axislimit_x = []; fig3_axislimit_y = []; groundTruthSelection = []; subsetGroundTruth = [];
positionsTogglebutton = [[1 29 27 13];[29 29 27 13];[1 15 27 13];[29 15 27 13];[1 1 27 13];[29 1 27 13]]; dispTags = []; dispTags2 = [];
connections = []; plotName = ''; db = {}; plotConnections = [1 1 1]; tableDataOrder = []; 
groundTruthCelltypesList = {''}; ACGLogIntervals = -3:0.04:1; idx_textFilter = []; clickPlotRegular = true; polygon1.handle = gobjects(0); referenceData=[];
cellsExcitatoryPostsynaptic = []; cellsInhibitoryPostsynaptic = []; reference_cell_metrics = []; UI.params.outbound = [];
groundTruth_cell_metrics = []; groundTruthData=[]; K = gausswin(5)*gausswin(5)'; K = 0.5*K/sum(K(:)); customPlotOptions = {};
set(groot, 'DefaultFigureVisible', 'on'), maxFigureSize = get(groot,'ScreenSize'); UI.settings.figureSize = [50, 50, min(1200,maxFigureSize(3)-50), min(800,maxFigureSize(4)-50)];

if isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

CellExplorerVersion = 1.54;

UI.fig = figure('Name',['Cell Explorer v' num2str(CellExplorerVersion)],'NumberTitle','off','renderer','opengl', 'MenuBar', 'None','PaperOrientation','landscape','windowscrollWheelFcn',@ScrolltoZoomInPlot,'KeyPressFcn', {@keyPress},'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off','WindowButtonMotionFcn', @hoverCallback); 
hManager = uigetmodemanager(UI.fig);

% % % % % % % % % % % % % % % % % % % % % %
% User preferences for the Cell Explorer
% % % % % % % % % % % % % % % % % % % % % %

CellExplorer_Preferences


% % % % % % % % % % % % % % % % % % % % % %
% Checking for Matlab version requirement (Matlab R2017a)
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

if exist('db_load_settings') == 2
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
    try
        cd(basepath)
    catch
        warning('basepath not available')
        close(UI.fig)
        return
    end
    [~,basename,~] = fileparts(basepath);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        disp(['Cell-Explorer: Loading ',basename,'.session.mat'])
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
            disp('Cell-Explorer: No cell_metrics exist in base folder. Loading from database')
            if enableDatabase
                DatabaseSessionDialog;
                if ~exist('cell_metrics') || isempty(cell_metrics)
                    disp('No dataset selected - closing the Cell Explorer')
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
        
    elseif exist(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']))
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
        if ~exist('cell_metrics') || isempty(cell_metrics)
                disp('No dataset selected - closing the Cell Explorer')
                if ishandle(UI.fig)
                    close(UI.fig)
                end
                cell_metrics = [];
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

% Cell explorer
UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'Cell Explorer');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'About the Cell Explorer',menuSelectedFcn,@AboutDialog);
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit preferences',menuSelectedFcn,@LoadPreferences,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit DB credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Edit DB repository paths',menuSelectedFcn,@editDBrepositories);
uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitCellExplorer,'Separator','on','Accelerator','W');

% File
UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
uimenu(UI.menu.file.topMenu,menuLabel,'Load session from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
uimenu(UI.menu.file.topMenu,menuLabel,'Load session(s) from database',menuSelectedFcn,@DatabaseSessionDialog,'Accelerator','D');
UI.menu.file.save = uimenu(UI.menu.file.topMenu,menuLabel,'Save classification',menuSelectedFcn,@saveDialog,'Separator','on','Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Restore classification from backup',menuSelectedFcn,@restoreBackup);
uimenu(UI.menu.file.topMenu,menuLabel,'Reload cell metrics',menuSelectedFcn,@reloadCellMetrics,'Separator','on');

% Navigation
UI.menu.navigation.topMenu = uimenu(UI.fig,menuLabel,'Navigation');
UI.menu.navigation.goToCell = uimenu(UI.menu.navigation.topMenu,menuLabel,'Go to cell',menuSelectedFcn,@goToCell,'Accelerator','G');
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
UI.menu.edit.reclassify_celltypes = uimenu(UI.menu.edit.topMenu,menuLabel,'Reclassify cells',menuSelectedFcn,@reclassify_celltypes,'Accelerator','R','Separator','on');
UI.menu.edit.performClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Agglomerative hierarchical cluster tree classification',menuSelectedFcn,@performClassification);
UI.menu.edit.adjustDeepSuperficial = uimenu(UI.menu.edit.topMenu,menuLabel,'Adjust Deep-Superficial assignment for session',menuSelectedFcn,@adjustDeepSuperficial1,'Separator','on');

% View / display
UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'View');
UI.menu.display.showHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Show remainig menubar',menuSelectedFcn,@ShowHideMenu,'Accelerator','M');
UI.menu.display.showMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Show waveform metrics',menuSelectedFcn,@showWaveformMetrics);
UI.menu.display.dispLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend',menuSelectedFcn,@showLegends);
if UI.settings.dispLegend; UI.menu.display.dispLegend.Checked = 'on'; end
UI.menu.display.firingRateMapShowLegend = uimenu(UI.menu.display.topMenu,menuLabel,'Show legend in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowLegend,'Separator','on');
if UI.settings.firingRateMap.showLegend; UI.menu.display.firingRateMapShowLegend.Checked = 'on'; end
UI.menu.display.showHeatmap = uimenu(UI.menu.display.topMenu,menuLabel,'Show heatmap in firing rate maps',menuSelectedFcn,@ToggleHeatmapFiringRateMaps);
if UI.settings.firingRateMap.showHeatmap; UI.menu.display.showHeatmap.Checked = 'on'; end
UI.menu.display.firingRateMapShowHeatmapColorbar = uimenu(UI.menu.display.topMenu,menuLabel,'Show colorbar in heatmaps in firing rate maps',menuSelectedFcn,@ToggleFiringRateMapShowHeatmapColorbar);
if UI.settings.firingRateMap.showHeatmapColorbar; UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on'; end
UI.menu.display.normalization.ops(1) = uimenu(UI.menu.display.topMenu,menuLabel,'Normalize ISIs by rate',menuSelectedFcn,@buttonACG_normalize,'Separator','on','Checked','on');
UI.menu.display.normalization.ops(2) = uimenu(UI.menu.display.topMenu,menuLabel,'Normalize ISIs by occurence',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.normalization.ops(3) = uimenu(UI.menu.display.topMenu,menuLabel,'Normalize ISIs to instantaneous rate',menuSelectedFcn,@buttonACG_normalize);
UI.menu.display.significanceMetricsMatrix = uimenu(UI.menu.display.topMenu,menuLabel,'Calculate significance metrics matrix',menuSelectedFcn,@SignificanceMetricsMatrix,'Accelerator','K','Separator','on');
UI.menu.display.redefineMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Change metrics used for t-SNE plot',menuSelectedFcn,@tSNE_redefineMetrics,'Accelerator','T');
UI.menu.display.sortingMetric = uimenu(UI.menu.display.topMenu,menuLabel,'Change metric used for sorting image data',menuSelectedFcn,@editSortingMetric);
UI.menu.display.markerSizeMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Adjust marker size for group plots',menuSelectedFcn,@defineMarkerSize,'Separator','on');

% ACG 
UI.menu.ACG.topMenu = uimenu(UI.fig,menuLabel,'ACG');
UI.menu.ACG.window.ops(1) = uimenu(UI.menu.ACG.topMenu,menuLabel,'30 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(2) = uimenu(UI.menu.ACG.topMenu,menuLabel,'100 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(3) = uimenu(UI.menu.ACG.topMenu,menuLabel,'1 sec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(4) = uimenu(UI.menu.ACG.topMenu,menuLabel,'Log10',menuSelectedFcn,@buttonACG);
UI.menu.ACG.showFit = uimenu(UI.menu.ACG.topMenu,menuLabel,'Show ACG fit',menuSelectedFcn,@toggleACGfit,'Separator','on','Accelerator','F');

% MonoSyn
UI.menu.monoSyn.topMenu = uimenu(UI.fig,menuLabel,'MonoSyn');
UI.menu.monoSyn.plotConns.ops(1) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in custom plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.plotConns.ops(2) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in Classic plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.plotConns.ops(3) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Show in tSNE plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.monoSyn.showConn.ops(1) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'None',menuSelectedFcn,@buttonMonoSyn,'Separator','on');
UI.menu.monoSyn.showConn.ops(2) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Selected',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(3) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Upstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(4) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(5) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'Up & downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(6) = uimenu(UI.menu.monoSyn.topMenu,menuLabel,'All',menuSelectedFcn,@buttonMonoSyn);
UI.menu.monoSyn.showConn.ops(find(strcmp(synConnectOptions,UI.settings.monoSynDispIn))).Checked = 'on';
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
uimenu(UI.menu.referenceData.topMenu,menuLabel,'Define reference data',menuSelectedFcn,@defineReferenceData,'Separator','on');
uimenu(UI.menu.referenceData.topMenu,menuLabel,'Compare cell groups to reference data',menuSelectedFcn,@compareToReference,'Separator','on');

% Ground truth
UI.menu.groundTruth.topMenu = uimenu(UI.fig,menuLabel,'Ground truth');
UI.menu.groundTruth.ops(1) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'No ground truth data',menuSelectedFcn,@showGroundTruthData,'Checked','on');
UI.menu.groundTruth.ops(2) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Image data',menuSelectedFcn,@showGroundTruthData);
UI.menu.groundTruth.ops(3) = uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Scatter data',menuSelectedFcn,@showGroundTruthData);
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Define ground truth data',menuSelectedFcn,@defineGroundTruthData,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Compare cell groups to ground truth cell types',menuSelectedFcn,@compareToReference,'Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Perform ground truth cell type classification in current session(s)',menuSelectedFcn,@performGroundTruthClassification,'Accelerator','Y','Separator','on');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Show ground truth cell types in current session(s)',menuSelectedFcn,@loadGroundTruth,'Accelerator','U');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Save manual classification to groundTruth folder',menuSelectedFcn,@importGroundTruth);

% Table menu
UI.menu.tableData.topMenu = uimenu(UI.fig,menuLabel,'Table data');
UI.menu.tableData.ops(1) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell metrics',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(2) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(3) = uimenu(UI.menu.tableData.topMenu,menuLabel,'None',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.column1 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 1','Separator','on');
for i = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.column1_ops(i) = uimenu(UI.menu.tableData.column1,menuLabel,UI.settings.tableDataSortingList{i},menuSelectedFcn,@setColumn1_metric);
end
UI.menu.tableData.column1_ops(find(strcmp(tableDataColumn1,UI.settings.tableDataSortingList))).Checked = 'on';

UI.menu.tableData.column2 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 2');
for i = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.column2_ops(i) = uimenu(UI.menu.tableData.column2,menuLabel,UI.settings.tableDataSortingList{i},menuSelectedFcn,@setColumn2_metric);
end
UI.menu.tableData.column2_ops(find(strcmp(tableDataColumn2,UI.settings.tableDataSortingList))).Checked = 'on';

uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list sorting:','Separator','on');
for i = 1:length(UI.settings.tableDataSortingList)
    UI.menu.tableData.sortingList(i) = uimenu(UI.menu.tableData.topMenu,menuLabel,UI.settings.tableDataSortingList{i},menuSelectedFcn,@setTableDataSorting);
end
UI.menu.tableData.sortingList(find(strcmp(tableDataSortBy,UI.settings.tableDataSortingList))).Checked = 'on';

% Spikes
UI.menu.spikeData.topMenu = uimenu(UI.fig,menuLabel,'Spikes');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Load spike data',menuSelectedFcn,@defineSpikesPlots,'Accelerator','A');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Edit spike plot',menuSelectedFcn,@editSelectedSpikePlot,'Accelerator','J');

% Session
UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
uimenu(UI.menu.session.topMenu,menuLabel,'View metadata for current session',menuSelectedFcn,@viewSessionMetaData);
uimenu(UI.menu.session.topMenu,menuLabel,'Open directory of current session',menuSelectedFcn,@openSessionDirectory,'Accelerator','C','Separator','on');
uimenu(UI.menu.session.topMenu,menuLabel,'Show current session in the Buzsaki lab web DB',menuSelectedFcn,@openSessionInWebDB,'Separator','on');
uimenu(UI.menu.session.topMenu,menuLabel,'Show current animal in the Buzsaki lab web DB',menuSelectedFcn,@showAnimalInWebDB);

% Help 
UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
uimenu(UI.menu.help.topMenu,menuLabel,'Show keyboard shortcuts',menuSelectedFcn,@HelpDialog,'Accelerator','H');
uimenu(UI.menu.help.topMenu,menuLabel,'Open the wiki on Github',menuSelectedFcn,@openWiki,'Accelerator','V');

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

%% % % % % % % % % % % % % % % % % % % % % %
% UI panels
% % % % % % % % % % % % % % % % % % % % % %

% Flexib grid box for adjusting the width of the side panels 
UI.HBox = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0 ); 

% Left panel 
UI.panel.left = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.HBox);

% Vertical center box with the title at top, grid flex with plots as middle element and message log and bechmark text at bottom 
UI.VBox = uix.VBox( 'Parent', UI.HBox, 'Spacing', 0, 'Padding', 0 ); 

% Title box
UI.panel.centerTop = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);

% Grid Flex with plots
UI.panel.GridFlex = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);
% UI.panel.GridFlex = uix.GridFlex( 'Parent', UI.VBox, 'Spacing', 5 , 'Padding', 5); 

% UI plot panels
UI.panel.subfig_ax1 = uipanel('position',[0 0.66 0.33 0.34],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax2 = uipanel('position',[0.33 0.66 0.33 0.34],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax3 = uipanel('position',[0.66 0.66 0.34 0.34],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax4 = uipanel('position',[0 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax5 = uipanel('position',[0.33 0.33 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax6 = uipanel('position',[0.66 0.33 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax7 = uipanel('position',[0 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax8 = uipanel('position',[0.33 0 0.33 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
UI.panel.subfig_ax9 = uipanel('position',[0.66 0 0.34 0.33],'BorderType','none','Parent',UI.panel.GridFlex);
% set(UI.panel.GridFlex, 'Widths', [-1 -1 -1], 'Heights', [-1 -1 -1] );

% Right panel 
UI.panel.right = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.HBox);

% Message log and performance
UI.panel.centerBottom = uipanel('position',[0 0.66 0.26 0.31],'BorderType','none','Parent',UI.VBox);

% set VBox elements sizes
set( UI.HBox, 'Widths', [150 -1 150]);

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

% % % % % % % % % % % % % % % % % % %
% Title and Benchmark
% % % % % % % % % % % % % % % % % % %

% Benchmark with display time in seconds for most recent plot call
UI.benchmark = uicontrol('Style','text','Units','normalized','Position',[0.66 0 0.34 1],'String','Benchmark','HorizontalAlignment','left','FontSize',13,'ForegroundColor',[0.3 0.3 0.3],'Parent',UI.panel.centerBottom);

% Title with details about the selected cell and current session
UI.title = uicontrol('Style','text','Units','normalized','Position',[0 0 1 1],'String',{'Cell details'},'HorizontalAlignment','center','FontSize',13,'Parent',UI.panel.centerTop);

% % % % % % % % % % % % % % % % % % %
% Metrics table
% % % % % % % % % % % % % % % % % % %

% Table with metrics for selected cell
UI.table = uitable('Parent',UI.panel.left,'Data',[table_fieldsNames,table_metrics(1,:)'],'Units','normalized','Position',[0 0.003 1 0.53],'ColumnWidth',{100,  100},'columnname',{'Metrics',''},'RowName',[],'CellSelectionCallback',@ClicktoSelectFromTable,'CellEditCallback',@EditSelectFromTable,'KeyPressFcn', {@keyPress}); % [10 10 150 575] {85, 46} %

if strcmp(UI.settings.metricsTableType,'Metrics')
    UI.settings.metricsTable=1;
    UI.menu.tableData.ops(1).Checked = 'On';
elseif strcmp(UI.settings.metricsTableType,'Cells')
    UI.settings.metricsTable=2; UI.table.ColumnName = {'','#',tableDataColumn1,tableDataColumn2};
    UI.table.ColumnEditable = [true false false false];
    UI.menu.tableData.ops(2).Checked = 'On';
else
    UI.settings.metricsTable=3; UI.table.Visible='Off';
    UI.menu.tableData.ops(3).Checked = 'On';
end

%% % % % % % % % % % % % % % % % % % % % % %
% UI content
% % % % % % % % % % % % % % % % % % % % % %

% Search field
UI.textFilter = uicontrol('Style','edit','Units','normalized','Position',[0 0.973 1 0.024],'String','Filter','HorizontalAlignment','left','Callback',@filterCellsByText,'Parent',UI.panel.left);

% UI menu panels
UI.panel.custom = uipanel('Title','Custom plot','TitlePosition','centertop','Position',[0 0.767 1 0.205],'Units','normalized','Parent',UI.panel.left);
UI.panel.group = uipanel('Title','Color groups','TitlePosition','centertop','Position',[0 0.537 1 0.23],'Units','normalized','Parent',UI.panel.left);

UI.panel.navigation = uipanel('Title','Navigation','TitlePosition','centertop','Position',[0 0.927 1 0.065],'Units','normalized','Parent',UI.panel.right);
UI.panel.cellAssignment = uipanel('Title','Cell assignments','TitlePosition','centertop','Position',[0 0.643 1 0.275],'Units','normalized','Parent',UI.panel.right);
UI.panel.displaySettings = uipanel('Title','Display Settings','TitlePosition','centertop','Position',[0 0.165 1 0.323],'Units','normalized','Parent',UI.panel.right);

% UI cell assignment tabs
UI.panel.tabgroup1 = uitabgroup('Position',[0 0.493 1 0.142],'Units','normalized','Parent',UI.panel.right);
UI.tabs.tags = uitab(UI.panel.tabgroup1,'Title','Tags');
UI.tabs.deepsuperficial = uitab(UI.panel.tabgroup1,'Title','D/S');

% UI display settings tabs
UI.panel.tabgroup2 = uitabgroup('Position',[0 0.002 1 0.16],'Units','normalized','SelectionChangedFcn',@updateLegends,'Parent',UI.panel.right);
UI.tabs.legends = uitab(UI.panel.tabgroup2,'Title','Legends');
UI.tabs.dispTags = uitab(UI.panel.tabgroup2,'Title','-Tags');
UI.tabs.dispTags2 = uitab(UI.panel.tabgroup2,'Title','+Tags');

% % % % % % % % % % % % % % % % % % % %
% Message log
% % % % % % % % % % % % % % % % % % % %

UI.popupmenu.log = uicontrol('Style','popupmenu','Units','normalized','Position',[0 0 0.66 1],'String',{''},'HorizontalAlignment','left','FontSize',10,'Parent',UI.panel.centerBottom);
MsgLog('Welcome to the Cell Explorer. Please check the Help menu to learn keyboard shortcuts or visit the wiki') 

% % % % % % % % % % % % % % % % % % % %
% Navigation panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Navigation buttons
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[2 2 48 12],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[50 2 48 12],'Units','normalized','String','GoTo','Callback',@(src,evnt)goToCell,'KeyPressFcn', {@keyPress});
UI.pushbutton.next = uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[100 2 48 12],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Cell assignments panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Cell classification
colored_string = DefineCellTypeList;
UI.listbox.cellClassification = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[2 54 145 50],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyPressFcn', {@keyPress});

% Poly-select and adding new cell type
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 36 73 15],'Units','normalized','String','O Polygon','Callback',@(src,evnt)polygonSelection,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[75 36 73 15],'Units','normalized','String','+ Cell-type','Callback',@(src,evnt)AddNewCellType,'KeyPressFcn', {@keyPress});

% Brain region
UI.pushbutton.brainRegion = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 20 145 15],'Units','normalized','String',['Region: ', cell_metrics.brainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyPressFcn', {@keyPress});

% Custom labels
UI.pushbutton.labels = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 3 145 15],'Units','normalized','String',['Label: ', cell_metrics.labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Tab panel 1 (right side)
% % % % % % % % % % % % % % % % % % % %

% Deep/Superficial

UI.listbox.deepSuperficial = uicontrol('Parent',UI.tabs.deepsuperficial,'Style','listbox','Position',getpixelposition(UI.tabs.deepsuperficial),'Units','normalized','String',UI.settings.deepSuperficial,'max',1,'min',1,'Value',cell_metrics.deepSuperficial_num(ii),'Callback',@(src,evnt)buttonDeepSuperficial,'KeyPressFcn', {@keyPress});

% Tags    
buttonPosition = getButtonLayout(UI.tabs.tags,UI.settings.tags);
for i = 1:min(length(UI.settings.tags),10)
    UI.togglebutton.tag(i) = uicontrol('Parent',UI.tabs.tags,'Style','togglebutton','String',UI.settings.tags{i},'Position',buttonPosition{i},'Units','normalized','Callback',@(src,evnt)buttonTags(i),'KeyPressFcn', {@keyPress});
end

% % % % % % % % % % % % % % % % % % % %
% Display settings panel (right side)
% % % % % % % % % % % % % % % % % % % %
% Select subset of cell type
updateCellCount
 
UI.listbox.cellTypes = uicontrol('Parent',UI.panel.displaySettings,'Style','listbox','Position',[2 73 145 50],'Units','normalized','String',strcat(UI.settings.cellTypes,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(UI.settings.cellTypes),'Callback',@(src,evnt)buttonSelectSubset(),'KeyPressFcn', {@keyPress});

% Number of plots
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 62 50 10],'Units','normalized','String','Layout','HorizontalAlignment','left');
UI.popupmenu.plotCount = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[50 61 100 10],'Units','normalized','String',{'GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6'},'max',1,'min',1,'Value',3,'Callback',@(src,evnt)AdjustGUIbutton,'KeyPressFcn', {@keyPress});

% #1 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 50 20 10],'Units','normalized','String','1.','HorizontalAlignment','left');
UI.popupmenu.customplot1 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 51 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleWaveformsPlot,'KeyPressFcn', {@keyPress});
if any(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); UI.popupmenu.customplot1.Value = find(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); else; UI.popupmenu.customplot1.Value = 1; end
customCellPlot1 = plotOptions{UI.popupmenu.customplot1.Value};

% #2 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 40 25 10],'Units','normalized','String','2.','HorizontalAlignment','left');
UI.popupmenu.customplot2 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 41 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleACGplot,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); UI.popupmenu.customplot2.Value = find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); else; UI.popupmenu.customplot2.Value = 4; end
customCellPlot2 = plotOptions{UI.popupmenu.customplot2.Value};

% #3 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 30 35 10],'Units','normalized','String','3.','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot3 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 31 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); UI.popupmenu.customplot3.Value = find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); else; UI.popupmenu.customplot3.Value = 1; end
customCellPlot3 = plotOptions{UI.popupmenu.customplot3.Value};

% #4 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 20 35 10],'Units','normalized','String','4.','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot4 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 21 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc2,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); UI.popupmenu.customplot4.Value = find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); else; UI.popupmenu.customplot4.Value = 1; end
customCellPlot4 = plotOptions{UI.popupmenu.customplot4.Value};

% #5 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 10 35 10],'Units','normalized','String','5.','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot5 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 11 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc3,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); UI.popupmenu.customplot5.Value = find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); else; UI.popupmenu.customplot5.Value = 2; end
customCellPlot5 = plotOptions{UI.popupmenu.customplot5.Value};

% #6 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 0 35 10],'Units','normalized','String','6.','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot6 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[23 1 125 10],'Units','normalized','String',plotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc4,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); UI.popupmenu.customplot6.Value = find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); else; UI.popupmenu.customplot5.Value = 3; end
customCellPlot6 = plotOptions{UI.popupmenu.customplot6.Value};

if find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); UI.popupmenu.plotCount.Value = find(strcmp(UI.settings.plotCountIn,UI.popupmenu.plotCount.String)); else; UI.popupmenu.plotCount.Value = 3; end; AdjustGUIbutton

% % % % % % % % % % % % % % % % % % % %
% Tab panel 2 (right side)
% % % % % % % % % % % % % % % % % % % %

% Display settings for tags1
buttonPosition = getButtonLayout(UI.tabs.dispTags,UI.settings.tags);
for i = 1:min(length(UI.settings.tags),6)
    UI.togglebutton.dispTags(i) = uicontrol('Parent',UI.tabs.dispTags,'Style','togglebutton','String',UI.settings.tags{i},'Position',buttonPosition{i},'Value',1,'Units','normalized','Callback',@(src,evnt)buttonTags2(i),'KeyPressFcn', {@keyPress});
end

% Display settings for tags2
for i = 1:min(length(UI.settings.tags),6)
    UI.togglebutton.dispTags2(i) = uicontrol('Parent',UI.tabs.dispTags2,'Style','togglebutton','String',UI.settings.tags{i},'Position',buttonPosition{i},'Value',0,'Units','normalized','Callback',@(src,evnt)buttonTags3(i),'KeyPressFcn', {@keyPress});
end

% Save classification
if ~isempty(classificationTrackChanges)
    UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
end

% % % % % % % % % % % % % % % % % % % %
% Custom plot panel (left side)
% % % % % % % % % % % % % % % % % % % %

% Custom plotting menues
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 59 50 10],'Units','normalized','String','X data','HorizontalAlignment','left');
UI.checkbox.logx = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[75 62 73 10],'Units','normalized','String','Log X','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotXLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.xData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 52 146 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX(),'KeyPressFcn', {@keyPress});

uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 39 50 10],'Units','normalized','String','Y data','HorizontalAlignment','left');
UI.checkbox.logy = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[75 42 73 10],'Units','normalized','String','Log Y','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotYLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.yData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 32 146 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY(),'KeyPressFcn', {@keyPress});

UI.checkbox.showz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 22 72 10],'Units','normalized','String','Z data','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis(),'KeyPressFcn', {@keyPress});
UI.checkbox.logz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[75 22 73 10],'Units','normalized','String','Log Z','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotZLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 12 146 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData.Enable = 'Off';
UI.checkbox.logz.Enable = 'Off';

% Custom plot
% uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 10 45 10],'Units','normalized','String','Plot style','HorizontalAlignment','left');
UI.popupmenu.metricsPlot = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 2 146 10],'Units','normalized','String',{'Scatter plot','+ Smooth histograms','+ Stairs histograms'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)togglePlotHistograms,'KeyPressFcn', {@keyPress});

% % % % % % % % % % % % % % % % % % % %
% Custom colors
% % % % % % % % % % % % % % % % % % % %
UI.popupmenu.groups = uicontrol('Parent',UI.panel.group,'Style','popupmenu','Position',[2 73 146 10],'Units','normalized','String',colorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(1),'KeyPressFcn', {@keyPress});
UI.listbox.groups = uicontrol('Parent',UI.panel.group,'Style','listbox','Position',[3 20 144 54],'Units','normalized','String',{'Type 1','Type 2','Type 3'},'max',10,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.groups = uicontrol('Parent',UI.panel.group,'Style','checkbox','Position',[3 10 146 10],'Units','normalized','String','Group by cell types','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.compare = uicontrol('Parent',UI.panel.group,'Style','checkbox','Position',[3 0 146 10],'Units','normalized','String','Compare to other','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress});

if summaryFigures
    disp('Creating summary figures')
    plotSummaryFigures
    if ishandle(UI.fig)
        close(UI.fig)
    end
    disp('Summary figures created')
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

pause(0.001)
while ii <= size(cell_metrics.troughToPeak,2)
    
    % breaking if figure has been closed
    if ~ishandle(UI.fig)
        break
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
    globalZoom = cell(1,9);
    globalZoomLog = cell(1,9);
    
    % Updating putative cell type listbox
    UI.listbox.cellClassification.Value = clusClas(ii);
    
    % Defining the subset of cells to display
    UI.params.subset = find(ismember(clusClas,classes2plot));
    
    % Updating ground truth tags
    if isfield(UI.tabs,'groundTruthClassification')
        updateGroundTruth
    end
    if any(groundTruthSelection)
        tagFilter2 = find(cellfun(@(X) ~isempty(X), cell_metrics.groundTruthClassification));
        if ~isempty(tagFilter2)
            subsetGroundTruth = [];
            for j = 1:length({UI.settings.groundTruth{groundTruthSelection}})
                subsetGroundTruth{j} = tagFilter2(cell2mat(cellfun(@(X) any(contains(X,UI.settings.groundTruth(groundTruthSelection(j)))), cell_metrics.groundTruthClassification(tagFilter2),'UniformOutput',false)));
            end
        end
      end  
    
    % Updating tags
    updateTags
    tagFilter = [];
    if any(dispTags==0)
        tagFilter = find(cellfun(@(X) ~isempty(X), cell_metrics.tags));
        filter = [];
        for i = 1:length(tagFilter)
            filter(i) = any(strcmp(cell_metrics.tags{tagFilter(i)},{UI.settings.tags{dispTags==0}}));
        end
        tagFilter = tagFilter(find(filter));
        UI.params.subset = setdiff(UI.params.subset,tagFilter);
    end
    if any(dispTags2==1)
        tagFilter2 = find(cellfun(@(X) ~isempty(X), cell_metrics.tags));
        filter = [];
        for i = 1:length(tagFilter2)
            filter(i) = any(strcmp(cell_metrics.tags{tagFilter2(i)},{UI.settings.tags{dispTags2==1}}));
        end
        tagFilter2 = tagFilter2(find(filter));
        UI.params.subset = intersect(UI.params.subset,tagFilter2);
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
    if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
        putativeSubset = find(sum(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)')==2);
    else
        putativeSubset=[];
        UI.params.incoming = [];
        UI.params.outgoing = [];
        UI.params.connections = [];
    end
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
    end
    
    % Defining synaptically identified projecting cell
    if UI.settings.displayExcitatory && ~isempty(cellsExcitatory)
        cellsExcitatory_subset = intersect(UI.params.subset,cellsExcitatory);
    end
    if UI.settings.displayInhibitory && ~isempty(cellsInhibitory)
        cellsInhibitory_subset = intersect(UI.params.subset,cellsInhibitory);
    end
    if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(cellsExcitatoryPostsynaptic)
        cellsExcitatoryPostsynaptic_subset = intersect(UI.params.subset,cellsExcitatoryPostsynaptic);
    else
        cellsExcitatoryPostsynaptic_subset = [];
    end
    if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(cellsInhibitoryPostsynaptic)
        cellsInhibitoryPostsynaptic_subset = intersect(UI.params.subset,cellsInhibitoryPostsynaptic);
    else
        cellsInhibitoryPostsynaptic_subset = [];
    end
    
    % Group display definition
    if UI.checkbox.compare.Value == 1
        clr = UI.settings.cellTypeColors(intersect(classes2plotSubset,plotClas(UI.params.subset)),:);
    elseif Colorval == 1 ||  UI.checkbox.groups.Value == 1
        clr = UI.settings.cellTypeColors(intersect(classes2plot,plotClas(UI.params.subset)),:);
    else
        clr = hsv(length(nanUnique(plotClas(UI.params.subset))))*0.8;
        if isnan(clr)
            clr = UI.settings.cellTypeColors(1,:);
        end
    end
    % Ground truth and reference data colors
    if ~strcmp(UI.settings.referenceData, 'None')
        clr2 = UI.settings.cellTypeColors(intersect(referenceData.clusClas,referenceData.selection),:);
    end
    if ~strcmp(UI.settings.groundTruthData, 'None')
        clr3 = UI.settings.groundTruthColors(intersect(groundTruthData.clusClas,groundTruthData.selection),:);
    end
    
    % Updating table for selected cell
    updateTableColumnWidth
    if UI.settings.metricsTable==1
        UI.table.Data = [table_fieldsNames,table_metrics(ii,:)'];
    elseif UI.settings.metricsTable==2
        updateCellTableData;
    end
    
    % Updating title
    if isfield(cell_metrics,'sessionName') & isfield(cell_metrics.general,'batch')
        UI.title.String = ['Cell class: ', UI.settings.cellTypes{clusClas(ii)},', ' , num2str(ii),'/', num2str(size(cell_metrics.firingRate,2)),' (batch ',num2str(batchIDs),'/',num2str(length(cell_metrics.general.batch)),') - UID: ', num2str(cell_metrics.UID(ii)),'/',num2str(general.cellCount),', spike group: ', num2str(cell_metrics.spikeGroup(ii)),', session: ', cell_metrics.sessionName{ii},',  animal: ',cell_metrics.animal{ii}];
    elseif isfield(cell_metrics,'sessionName')
        UI.title.String = ['Cell: ', num2str(ii),'/', num2str(size(cell_metrics.firingRate,2)),' from ', cell_metrics.sessionName{ii},',  Class: ', UI.settings.cellTypes{clusClas(ii)}];
    else
        UI.title.String = ['Cell: ', num2str(ii),'/', num2str(size(cell_metrics.firingRate,2)),'.  Class: ', UI.settings.cellTypes{clusClas(ii)}];
    end
    
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 1
    % % % % % % % % % % % % % % % % % % % % % %
    
    if customPlotHistograms == 0
        if size(UI.panel.subfig_ax1.Children,1) > 1
            axes(UI.panel.subfig_ax1.Children(2));
        else
            axes(UI.panel.subfig_ax1.Children);
        end
        % Saving current view activated for previous cell
        [az,el] = view;
    end
    % Deletes all children from the panel
    delete(UI.panel.subfig_ax1.Children)
    
    % Creating new chield
    subfig_ax(1) = axes('Parent',UI.panel.subfig_ax1);
    
    % Regular plot without histograms
    if customPlotHistograms == 0
        
        if ((strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.settings.groundTruthData, 'Image')) && ~isempty(groundTruth_cell_metrics)) && UI.checkbox.logy.Value == 1 && UI.settings.plot3axis == 0
        	yyaxis right, hold on
        end
        hold on
        xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
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
        
        if UI.settings.plot3axis == 0
            % 2D plot
            set(subfig_ax(1),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on, axis tight
            view([0 90]);
            
            % Reference data
            if strcmp(UI.settings.referenceData, 'Points') && ~isempty(reference_cell_metrics) && isfield(reference_cell_metrics,plotX_title) && isfield(reference_cell_metrics,plotY_title)
                idx = find(ismember(referenceData.clusClas,referenceData.selection));
                legendScatter2 = gscatter(reference_cell_metrics.(plotX_title)(idx), reference_cell_metrics.(plotY_title)(idx), referenceData.clusClas(idx), clr2,'x',8,'off');
                set(legendScatter2,'HitTest','off')
            elseif strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(reference_cell_metrics,plotX_title) && isfield(reference_cell_metrics,plotY_title)
                if ~exist('referenceData1') || ~strcmp(referenceData1.x_field,plotX_title) || ~strcmp(referenceData1.y_field,plotY_title) || referenceData1.x_log ~= UI.checkbox.logx.Value || referenceData1.y_log ~= UI.checkbox.logy.Value
                    if UI.checkbox.logx.Value == 1
                        referenceData1.x = linspace(log10(min(reference_cell_metrics.(plotX_title))),log10(max(reference_cell_metrics.(plotX_title))),60);
                        xdata = log10(reference_cell_metrics.(plotX_title));
                    else
                        referenceData1.x = linspace(min(reference_cell_metrics.(plotX_title)),max(reference_cell_metrics.(plotX_title)),60);
                        xdata = reference_cell_metrics.(plotX_title);
                    end
                    if UI.checkbox.logy.Value == 1
                        referenceData1.y = linspace(log10(min(reference_cell_metrics.(plotY_title))),log10(max(reference_cell_metrics.(plotY_title))),60);
                        ydata = log10(reference_cell_metrics.(plotY_title));
                    else
                        referenceData1.y = linspace(min(reference_cell_metrics.(plotY_title)),max(reference_cell_metrics.(plotY_title)),60);
                        ydata = reference_cell_metrics.(plotY_title);
                    end
                    
                    referenceData1.x_field = plotX_title;
                    referenceData1.y_field = plotY_title;
                    referenceData1.x_log = UI.checkbox.logx.Value;
                    referenceData1.y_log = UI.checkbox.logy.Value;

                    colors = (1-(UI.settings.cellTypeColors)) * 250;
                    referenceData1.z = zeros(length(referenceData1.x)-1,length(referenceData1.y)-1,3,size(colors,1));
                    for i = referenceData.selection
                        idx = find(referenceData.clusClas==i);
                        [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),referenceData1.x,referenceData1.y,'norm','probability');
                        referenceData1.z(:,:,:,i) = bsxfun(@times,repmat(conv2(z_referenceData_temp,K,'same'),1,1,3),reshape(colors(i,:),1,1,[]));
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
                referenceData1.image = imrotate(referenceData1.image,90);
                legendScatter2 = image(referenceData1.x,referenceData1.y,referenceData1.image,'HitTest','off', 'PickableParts', 'none'); axis tight
                set(legendScatter2,'HitTest','off')
                
                if strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics) && UI.checkbox.logy.Value == 1
                    yyaxis right, hold on
                end
            end
            
            % Ground truth data
            if strcmp(UI.settings.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics) && isfield(groundTruth_cell_metrics,plotX_title) && isfield(groundTruth_cell_metrics,plotY_title)
                idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
                legendScatter2 = gscatter(groundTruth_cell_metrics.(plotX_title)(idx), groundTruth_cell_metrics.(plotY_title)(idx), groundTruthData.clusClas(idx), clr3,'x',8,'off');
                set(legendScatter2,'HitTest','off')
            elseif strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logx.Value == 0 && isfield(groundTruth_cell_metrics,plotX_title) && isfield(groundTruth_cell_metrics,plotY_title)
                if ~exist('groundTruthData1') || ~strcmp(groundTruthData1.x_field,plotX_title) || ~strcmp(groundTruthData1.y_field,plotY_title) || groundTruthData1.x_log ~= UI.checkbox.logx.Value || groundTruthData1.y_log ~= UI.checkbox.logy.Value
                    if UI.checkbox.logx.Value == 1
                        groundTruthData1.x = linspace(log10(min(groundTruth_cell_metrics.(plotX_title))),log10(max(groundTruth_cell_metrics.(plotX_title))),60);
                        xdata = log10(groundTruth_cell_metrics.(plotX_title));
                    else
                        groundTruthData1.x = linspace(min(groundTruth_cell_metrics.(plotX_title)),max(groundTruth_cell_metrics.(plotX_title)),60);
                        xdata = groundTruth_cell_metrics.(plotX_title);
                    end
                    if UI.checkbox.logy.Value == 1
                        groundTruthData1.y = linspace(log10(min(groundTruth_cell_metrics.(plotY_title))),log10(max(groundTruth_cell_metrics.(plotY_title))),60);
                        ydata = log10(groundTruth_cell_metrics.(plotY_title));
                    else
                        groundTruthData1.y = linspace(min(groundTruth_cell_metrics.(plotY_title)),max(groundTruth_cell_metrics.(plotY_title)),60);
                        ydata = groundTruth_cell_metrics.(plotY_title);
                    end
                    
                    groundTruthData1.x_field = plotX_title;
                    groundTruthData1.y_field = plotY_title;
                    groundTruthData1.x_log = UI.checkbox.logx.Value;
                    groundTruthData1.y_log = UI.checkbox.logy.Value;
                    
                    colors = (1-(UI.settings.groundTruthColors)) * 250;
                    groundTruthData1.z = zeros(length(groundTruthData1.x)-1,length(groundTruthData1.y)-1,3,size(colors,1));
                    for i = unique(groundTruthData.clusClas);
                        idx = find(groundTruthData.clusClas==i);
                        [z_referenceData_temp,~,~] = histcounts2(xdata(idx), ydata(idx),groundTruthData1.x,groundTruthData1.y,'norm','probability');
                        groundTruthData1.z(:,:,:,i) = bsxfun(@times,repmat(conv2(z_referenceData_temp,K,'same'),1,1,3),reshape(colors(i,:),1,1,[]));
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
                groundTruthData1.image = imrotate(groundTruthData1.image,90);
                legendScatter2 = image(groundTruthData1.x,groundTruthData1.y,groundTruthData1.image,'HitTest','off', 'PickableParts', 'none'); axis tight
                set(legendScatter2,'HitTest','off'),legendScatter2.AlphaData = 0.9;
                alpha(0.3) 
                if strcmp(UI.settings.referenceData, 'Image') && ~isempty(groundTruth_cell_metrics) && UI.checkbox.logy.Value == 1
                    yyaxis right, hold on
                end
            end
            
            plotGroupData(plotX,plotY,plotConnections(1))
%             % Scatter plot
%             plotGroupScatter(plotX, plotY)
% 
%             % Plot putative connections
%             if plotConnections(1) == 1
%                 plotPutativeConnections(plotX,plotY)
%             end
%             % Plots X marker for selected cell
%             plotMarker(plotX(ii),plotY(ii))
%         
%             % Plots tagget ground-truth cell types
%             plotGroudhTruthCells(plotX, plotY)
%             
%             if UI.settings.stickySelection
%                 plot(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
%             end
            axis tight
            
        else
            % 3D plot
            view([az,el]); axis tight
            if UI.settings.plotZLog == 1
                set(subfig_ax(1), 'ZScale', 'log')
            else
                set(subfig_ax(1), 'ZScale', 'linear')
            end
            
            legendScatter = [];
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                legendScatter(jj) = scatter3(plotX(set1), plotY(set1), plotZ(set1), 'MarkerFaceColor', clr(jj,:), 'MarkerEdgeColor','none','MarkerFaceAlpha',.7);
            end
            
            if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
                plot3(plotX(cellsExcitatory_subset), plotY(cellsExcitatory_subset), plotZ(cellsExcitatory_subset),'^k', 'HitTest','off')
            end
            if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
                plot3(plotX(cellsInhibitory_subset), plotY(cellsInhibitory_subset), plotZ(cellsInhibitory_subset),'ok', 'HitTest','off')
            end
            if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(cellsExcitatoryPostsynaptic_subset)
                plot3(plotX(cellsExcitatoryPostsynaptic_subset), plotY(cellsExcitatoryPostsynaptic_subset), plotZ(cellsExcitatoryPostsynaptic_subset),'vk', 'HitTest','off')
            end
            if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(cellsInhibitoryPostsynaptic_subset)
                plot3(plotX(cellsInhibitoryPostsynaptic_subset), plotY(cellsInhibitoryPostsynaptic_subset), plotZ(cellsInhibitoryPostsynaptic_subset),'*k', 'HitTest','off')
            end
            % Plotting synaptic projections
            if  plotConnections(1) == 1 && ~isempty(putativeSubset)
                switch UI.monoSyn.disp
                    case 'All'
                        xdata = [plotX(UI.params.a1);plotX(UI.params.a2);nan(1,length(UI.params.a2))];
                        ydata = [plotY(UI.params.a1);plotY(UI.params.a2);nan(1,length(UI.params.a2))];
                        zdata = [plotZ(UI.params.a1);plotZ(UI.params.a2);nan(1,length(UI.params.a2))];
                        plot3(xdata(:),ydata(:),zdata(:),'k','HitTest','off')
                    case {'Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(UI.params.inbound)
                            xdata = [plotX(UI.params.incoming);plotX(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                            ydata = [plotY(UI.params.incoming);plotY(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                            zdata = [plotZ(UI.params.incoming);plotZ(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                            plot3(xdata(:),ydata(:),zdata(:),'b','HitTest','off')
                        end
                        if ~isempty(UI.params.outbound)
                            xdata = [plotX(UI.params.a1(UI.params.outbound));plotX(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                            ydata = [plotY(UI.params.a1(UI.params.outbound));plotY(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                            zdata = [plotZ(UI.params.a1(UI.params.outbound));plotZ(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                            plot3(xdata(:),ydata(:),zdata(:),'m','HitTest','off')
                        end
                end
            end
            
            plot3(plotX(ii), plotY(ii), plotZ(ii),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off')
            plot3(plotX(ii), plotY(ii), plotZ(ii),'xk', 'LineWidth', 2, 'MarkerSize',20, 'HitTest','off')
            
            zlabel(plotZ_title, 'Interpreter', 'none')
            if contains(plotZ_title,'_num')
                zticks([1:length(groups_ids.(plotZ_title))]), zticklabels(groups_ids.(plotZ_title)),ztickangle(65),zlim([0.5,length(groups_ids.(plotZ_title))+0.5]),zlabel(plotZ_title(1:end-4), 'Interpreter', 'none')
            end

            % Ground truth cell types
            if groundTruthSelection
                idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                for jj = 1:length(idGroundTruth)
                    plot3(plotX(subsetGroundTruth{idGroundTruth(jj)}), plotY(subsetGroundTruth{idGroundTruth(jj)}), plotZ(subsetGroundTruth{idGroundTruth(jj)}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                end
            end
            
            % Activating rotation
            rotateFig1
        end
        
        if contains(plotX_title,'_num')
            xticks([1:length(groups_ids.(plotX_title))]), xticklabels(groups_ids.(plotX_title)),xtickangle(20),xlim([0.5,length(groups_ids.(plotX_title))+0.5]),xlabel(plotX_title(1:end-4), 'Interpreter', 'none')
        end
        if contains(plotY_title,'_num')
            yticks([1:length(groups_ids.(plotY_title))]), yticklabels(groups_ids.(plotY_title)),ytickangle(65),ylim([0.5,length(groups_ids.(plotY_title))+0.5]),ylabel(plotY_title(1:end-4), 'Interpreter', 'none')
        end
        [az,el] = view;
        
    elseif customPlotHistograms == 1
        % Double kernel-histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(UI.params.subset),plotY(UI.params.subset),'Group',plotClas(UI.params.subset),'Kernel','on','Marker','.','MarkerSize',UI.settings.markerSize,'LineStyle',{'-'},'Parent',UI.panel.subfig_ax1,'Legend','off','Color',clr); hold on % ,'Style','stairs'
            axis(h_scatter(1),'tight');
            set(h_scatter(1).Children,'HitTest','off')
            set(h_scatter(1),'ButtonDownFcn',@ClicktoSelectFromPlot)
            
            xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
            
            % Setting linear/log scale
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
            
%             axes(h_scatter(1))
            % Plot putative connections
            if plotConnections(1) == 1
                plotPutativeConnections(plotX,plotY)
            end
            % Plots X marker for selected cell
            plotMarker(plotX(ii),plotY(ii))
        
            % Plots tagget ground-truth cell types
            plotGroudhTruthCells(plotX, plotY)
            
        end
    else
        % Double stairs-histogram with scatter plot
        hold off
        
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(UI.params.subset),plotY(UI.params.subset),'Group',plotClas(UI.params.subset),'Style','stairs','Marker','.','MarkerSize',UI.settings.markerSize,'LineStyle',{'-'},'Parent',UI.panel.subfig_ax1,'Legend','off','Color',clr); hold on % ,
            set(h_scatter(1).Children,'HitTest','off')
            set(h_scatter(1),'ButtonDownFcn',@ClicktoSelectFromPlot)
            axis(h_scatter(1),'tight');
            
            xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
            if length(unique(plotClas(UI.params.subset)))==2
                G1 = plotX(UI.params.subset);
                G = findgroups(plotClas(UI.params.subset));
                if ~isempty(UI.params.subset(G==1)) && length(UI.params.subset(G==2))>0
                    [h,p] = kstest2(plotX(UI.params.subset(G==1)),plotX(UI.params.subset(G==2)));
                    text(1.04,0.01,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90,'Interpreter', 'none','Interpreter', 'none')
                    [h,p] = kstest2(plotY(UI.params.subset(G==1)),plotY(UI.params.subset(G==2)));
                    text(0.01,1.04,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Interpreter', 'none','Interpreter', 'none')
                end
            end
            
            % Setting linear/log scale
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
            
            axes(h_scatter(1))
            % Plot putative connections
            if plotConnections(1) == 1
                plotPutativeConnections(plotX,plotY)
            end
            
            % Plots X marker for selected cell
            plotMarker(plotX(ii),plotY(ii))
        
            % Plots tagget ground-truth cell types
            plotGroudhTruthCells(plotX, plotY)
        end
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 2
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax2.Visible,'on')
        delete(UI.panel.subfig_ax2.Children)
        subfig_ax(2) = axes('Parent',UI.panel.subfig_ax2);
        set(subfig_ax(2),'ButtonDownFcn',@ClicktoSelectFromPlot), hold on
        if (strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)) || (strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics))
            yyaxis right
        end
        
        xlim(fig2_axislimit_x), ylim(fig2_axislimit_y), ylabel('Burst Index (Royer 2012)'); xlabel('Trough-to-Peak (µs)')
        set(subfig_ax(2), 'YScale', 'log');
        
        % Reference data
        if strcmp(UI.settings.referenceData, 'Points') && ~isempty(reference_cell_metrics)
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            legendScatter2 = gscatter(reference_cell_metrics.troughToPeak(idx) * 1000, reference_cell_metrics.burstIndex_Royer2012(idx), referenceData.clusClas(idx), clr2,'x',8,'off');
            set(legendScatter2,'HitTest','off')
        elseif strcmp(UI.settings.referenceData, 'Image') && ~isempty(reference_cell_metrics)
            yyaxis left
            referenceData.image = 1-sum(referenceData.z(:,:,:,referenceData.selection),4);
            referenceData.image = flip(referenceData.image,2);
            referenceData.image = imrotate(referenceData.image,90);
            legendScatter2 = image(referenceData.x,referenceData.y,referenceData.image,'HitTest','off', 'PickableParts', 'none'); axis tight
            set(gca,'YTick',[])
            set(legendScatter2,'HitTest','off')
            yyaxis right, hold on
        end
        
        % Ground truth data
        if strcmp(UI.settings.groundTruthData, 'Points') && ~isempty(groundTruth_cell_metrics)
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            legendScatter3 = gscatter(groundTruth_cell_metrics.troughToPeak(idx) * 1000, groundTruth_cell_metrics.burstIndex_Royer2012(idx), groundTruthData.clusClas(idx), clr3,'x',8,'off');
            set(legendScatter3,'HitTest','off')
        elseif strcmp(UI.settings.groundTruthData, 'Image') && ~isempty(groundTruth_cell_metrics)
            yyaxis left
            groundTruthData.image = 1-sum(groundTruthData.z(:,:,:,groundTruthData.selection),4);
            groundTruthData.image = flip(groundTruthData.image,2);
            groundTruthData.image = imrotate(groundTruthData.image,90);
            legendScatter3 = image(groundTruthData.x,groundTruthData.y,groundTruthData.image,'HitTest','off', 'PickableParts', 'none'); axis tight
            set(gca,'YTick',[])
            set(legendScatter3,'HitTest','off')
            yyaxis right, hold on
        end
        
        plotGroupData(cell_metrics.troughToPeak * 1000,cell_metrics.burstIndex_Royer2012,plotConnections(2))
        
%         % Scatter plot
%         plotGroupScatter(cell_metrics.troughToPeak * 1000, cell_metrics.burstIndex_Royer2012)
% 
%         % Plot putative connections
%         if plotConnections(2) == 1
%             plotPutativeConnections(cell_metrics.troughToPeak * 1000,cell_metrics.burstIndex_Royer2012)
%         end
%         % Plot X marker for selected cell
%         plotMarker(cell_metrics.troughToPeak(ii) * 1000,cell_metrics.burstIndex_Royer2012(ii))
%         
%         % Plot tagget ground-truth cell types
%         plotGroudhTruthCells(cell_metrics.troughToPeak * 1000, cell_metrics.burstIndex_Royer2012)
% 
%         % Sticky selection
%         if UI.settings.stickySelection
%         	plot(cell_metrics.troughToPeak(UI.params.ClickedCells)*1000,cell_metrics.burstIndex_Royer2012(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
%         end        
        
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
    % Subfig 3
    % % % % % % % % % % % % % % % % % % % % % %
    
    if strcmp(UI.panel.subfig_ax3.Visible,'on')
        delete(UI.panel.subfig_ax3.Children)
        subfig_ax(3) = axes('Parent',UI.panel.subfig_ax3);
        set(subfig_ax(3),'ButtonDownFcn',@ClicktoSelectFromPlot)
        cla, hold on
        
        % Scatter plot with t-SNE metrics
        xlim(fig3_axislimit_x), ylim(fig3_axislimit_y), xlabel('t-SNE'), ylabel('t-SNE')
        
        plotGroupData(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)',plotConnections(3))
        
        
%         plotGroupScatter(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2))
        
        
%         % Plots putative connections
%         if plotConnections(3) == 1
%             plotPutativeConnections(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)')
%         end
%         
%         % Plots X marker for selected cell
%         plotMarker(tSNE_metrics.plot(ii,1),tSNE_metrics.plot(ii,2))
%         
%         % Plots tagget ground-truth cell types
%         plotGroudhTruthCells(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2))
%         
%         if UI.settings.stickySelection
%             plot(tSNE_metrics.plot(UI.params.ClickedCells,1),tSNE_metrics.plot(UI.params.ClickedCells,2),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
%         end
    end
    
    %% % % % % % % % % % % % % % % % % % % % % %
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
    % Separate legends in side panel
    updateLegends
    
    % % % % % % % % % % % % % % % % % % % % % %
    % Response including benchmarking the UI
    
    UI.benchmark.String = [num2str(length(UI.params.subset)),'/',num2str(size(cell_metrics.troughToPeak,2)), ' cells displayed. Processing time: ', num2str(toc(timerVal),3),' sec'];
    
    % Waiting for uiresume call
    uiwait(UI.fig);
    timerVal = tic;
    if ishandle(UI.fig)
        UI.benchmark.String = '';
    end
end


%% % % % % % % % % % % % % % % % % % % % % %
% Calls when closing
% % % % % % % % % % % % % % % % % % % % % %

if ishandle(UI.fig)
    % Closing cell explorer figure if still open
    close(UI.fig);
end
cell_metrics = saveCellMetricsStruct(cell_metrics);


%% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

    function subsetPlots = customPlot(customPlotSelection,ii,general,batchIDs)
        % Creates all cell specific plots
        subsetPlots = [];
        
        % Determinig the plot color
        if UI.checkbox.compare.Value == 1
            col = UI.settings.cellTypeColors(plotClas(ii),:);
        elseif Colorval == 1 ||  UI.checkbox.groups.Value == 1
            col = UI.settings.cellTypeColors(plotClas(ii),:);
        else
            if isnan(clr)
                col = clr;
            else
                temp = find(nanUnique(plotClas(UI.params.subset))==plotClas(ii));
                if temp <= size(clr,1)
                    col = clr(temp,:);
                else
                    col = [0.3,0.3,0.3];
                end
                if isempty(col)
                    col = [0.3,0.3,0.3];
                end
            end
        end
        
        axis tight
        if any(strcmp(customPlotSelection,customPlotOptions))
            
            subsetPlots = customPlots.(customPlotSelection)(cell_metrics,UI,ii,col);
            
        elseif strcmp(customPlotSelection,'Waveforms (single)')
            
            % Single waveform with std
            if isfield(cell_metrics.waveforms,'filt_std')
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.filt{ii}+cell_metrics.waveforms.filt_std{ii},flip(cell_metrics.waveforms.filt{ii}-cell_metrics.waveforms.filt_std{ii})],'black','EdgeColor','none','FaceAlpha',.2)
            end
            plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.filt{ii}, 'color', col,'linewidth',2), grid on
            xlabel('Time (ms)'), ylabel('Voltage (µV)'), title('Filtered waveform')
            
            % Waveform metrics
            if UI.settings.plotWaveformMetrics
                if isfield(cell_metrics,'polarity') && cell_metrics.polarity(ii) > 0
                    filtWaveform = -cell_metrics.waveforms.filt{ii};
                    [temp1,temp2] = max(-filtWaveform);   % Trough to peak. Red
                    [~,temp3] = max(diff(-filtWaveform)); % Derivative. Green
                    [temp4,temp5] = max(filtWaveform);   % AB-ratio. Blue
                    temp6= min(cell_metrics.waveforms.filt{ii});
                else
                    filtWaveform = cell_metrics.waveforms.filt{ii};
                    [temp1,temp2] = min(filtWaveform);   % Trough to peak
                    [~,temp3] = min(diff(filtWaveform)); % Derivative
                    [temp4,temp5] = max(filtWaveform);   % AB-ratio
                    temp6 = max(cell_metrics.waveforms.filt{ii});
                end
                
                plt1(1) = plot([cell_metrics.waveforms.time{ii}(temp2),cell_metrics.waveforms.time{ii}(temp2)+cell_metrics.troughToPeak(ii)],[temp1,temp1],'v-','linewidth',2,'color',[1,0.5,0.5,0.5],'HitTest','off');
                plt1(2) = plot([cell_metrics.waveforms.time{ii}(temp3),cell_metrics.waveforms.time{ii}(temp3)+cell_metrics.troughtoPeakDerivative(ii)],[cell_metrics.waveforms.filt{ii}(temp3),cell_metrics.waveforms.filt{ii}(temp3)],'s-','linewidth',2,'color',[0.5,1,0.5,0.5],'HitTest','off');
                plt1(3) = plot([cell_metrics.waveforms.time{ii}(temp5),cell_metrics.waveforms.time{ii}(temp5)],[temp6,temp6+cell_metrics.ab_ratio(ii)*temp6],'^-','linewidth',2,'color',[0.5,0.5,1,0.5],'HitTest','off');
                
                % Setting legend
                if UI.settings.dispLegend == 1
                    legend(plt1, {'Trough-to-peak','Trough-to-peak (derivative)','AB-ratio'},'Location','southwest','Box','off','AutoUpdate','off');
                end
            end
            
        elseif strcmp(customPlotSelection,'Waveforms (all)')
            % All waveforms (z-scored) colored according to cell type
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.filt_zscored(:,set1);nan(1,length(set1))];
                plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            % selected cell in black
            plot(time_waveforms_zscored, cell_metrics.waveforms.filt_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Time (ms)'), ylabel('Waveforms (z-scored)'), title('Waveforms')
            
        elseif strcmp(customPlotSelection,'Waveforms (image)')
            
            % All waveforms, zscored and shown in a imagesc plot
            % Sorted according to trough-to-peak
            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(troughToPeakSorted) == ii);
            
            imagesc(time_waveforms_zscored, [1:length(UI.params.subset)], cell_metrics.waveforms.filt_zscored(:,UI.params.subset(troughToPeakSorted))','HitTest','off'),
            colormap hot(512), xlabel('Time (ms)'), title('Waveform zscored (image)')
            
            % selected cell highlighted in white
            if ~isempty(idx)
                plot([time_waveforms_zscored(1),time_waveforms_zscored(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
            end
            
        elseif strcmp(customPlotSelection,'Raw waveforms (single)')
            % Single waveform with std
            
            if isfield(cell_metrics.waveforms,'raw_std') & ~isempty(cell_metrics.waveforms.raw{ii})
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.raw{ii}+cell_metrics.waveforms.raw_std{ii},flip(cell_metrics.waveforms.raw{ii}-cell_metrics.waveforms.raw_std{ii})],'black','EdgeColor','none','FaceAlpha',.2)
                plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2), grid on
            elseif ~isempty(cell_metrics.waveforms.raw{ii})
                plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2), grid on
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
            xlabel('Time (ms)'), ylabel('Voltage (µV)'), title('Raw waveform')
            
        elseif strcmp(customPlotSelection,'Raw waveforms (all)')
            % All raw waveforms (z-scored) colored according to cell type
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.raw_zscored(:,set1);nan(1,length(set1))];
                plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            % selected cell in black
            plot(time_waveforms_zscored, cell_metrics.waveforms.raw_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Time (ms)'), title('Raw waveforms zscored')
            
        elseif strcmp(customPlotSelection,'Waveforms (tSNE)')
            
            % t-SNE scatter-plot with all waveforms calculated from the z-scored
            % waveforms
            legendScatter4 = gscatter(tSNE_metrics.filtWaveform(UI.params.subset,1), tSNE_metrics.filtWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
            set(legendScatter4,'HitTest','off')
            title('Waveforms - tSNE visualization'), axis tight, xlabel(''), ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            plot(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'Raw waveforms (tSNE)')
            
            % t-SNE scatter-plot with all raw waveforms calculated from the z-scored
            % waveforms
            legendScatter4 = gscatter(tSNE_metrics.rawWaveform(UI.params.subset,1), tSNE_metrics.rawWaveform(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
            set(legendScatter4,'HitTest','off')
            title('Raw waveforms - tSNE visualization'), axis tight, xlabel(''), ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            plot(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'CCGs (image)')
            
            % CCGs for selected cell with other cell pairs from the same
            % session. The ACG for the selected cell is shown first
            if isfield(general,'ccg') & ~isempty(UI.params.subset)
                if UI.BatchMode
                    subset1 = find(cell_metrics.batchIDs(UI.params.subset)==cell_metrics.batchIDs(ii));
                else
                    subset1 = 1:general.cellCount;
                end
                subset1 = cell_metrics.UID(UI.params.subset(subset1));
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
                plot([0,0,],[0.5,length(subset1)+0.5],'k','HitTest','off')
                colormap hot(512), xlabel('Time (ms)'), title(['CCGs']), axis tight
                
                % Synaptic partners are also displayed
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(UI.params.outbound)
                            [~,y_pos,~] = intersect(subset1,cell_metrics.UID(UI.params.outgoing));
                            plot(1.045*Xdata(3)*ones(size(UI.params.outbound)),y_pos,'.m', 'HitTest','off', 'MarkerSize',12)
                        end
                        if ~isempty(UI.params.inbound)
                            [~,y_pos,~] = intersect(subset1,cell_metrics.UID(UI.params.incoming));
                            plot(1.045*Xdata(3)*ones(size(UI.params.inbound)),y_pos,'.b', 'HitTest','off', 'MarkerSize',12)
                        end
                        xlim([Xdata(1)*1.05,Xdata(end)])
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ACGs (single)') % ACGs
            
            % Auto-correlogram for selected cell. Colored according to
            % cell-type. Normalized firing rate. X-axis according to
            % selected
            % option___________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
            if strcmp(UI.settings.acgType,'Normal')
                bar_from_patch([-100:100]'/2, cell_metrics.acg.narrow(:,ii),col)
                xticks([-50:10:50]),xlim([-50,50])
            elseif strcmp(UI.settings.acgType,'Narrow')
                bar_from_patch([-30:30]'/2, cell_metrics.acg.narrow(41+30:end-40-30,ii),col)
                xticks([-15:5:15]),xlim([-15,15])
            elseif strcmp(UI.settings.acgType,'Log10') && isfield(general,'acgs') && isfield(general.acgs,'log10')
                bar_from_patch(general.acgs.log10, cell_metrics.acg.log10(:,ii),col)
                set(gca,'xscale','log'),xlim([0,10])
            else
                bar_from_patch([-500:500]', cell_metrics.acg.wide(:,ii),col)
                xticks([-500:100:500]),xlim([-500,500])
            end
            
            % ACG fit with a triple-exponential
            if plotAcgFit
                a = cell_metrics.acg_tau_decay(ii); b = cell_metrics.acg_tau_rise(ii); c = cell_metrics.acg_c(ii); d = cell_metrics.acg_d(ii);
                e = cell_metrics.acg_asymptote(ii); f = cell_metrics.acg_refrac(ii); g = cell_metrics.acg_tau_burst(ii); h = cell_metrics.acg_h(ii);
                x = 1:0.2:50;
                fiteqn = max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0);
                if strcmp(UI.settings.acgType,'Log10')
                    plot([-flip(x),x]/1000,[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
%                     plot(0.05,fiteqn(246),'ok')
                else
                    plot([-flip(x),x],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
                end
            end
            
            ax5 = axis; grid on, set(gca, 'Layer', 'top')
            plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); plot([ax5(1) ax5(2)],cell_metrics.firingRate(ii)*[1 1],'--k')
            xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.firingRate(ii),3),'Hz'])
        
        elseif strcmp(customPlotSelection,'ISIs (single)') % ISIs
            
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')
                if strcmp(UI.settings.isiNormalization,'Rate')
                    bar_from_patch(general.isis.log10, cell_metrics.acg.log10(:,ii)-cell_metrics.isi.log10(:,ii),'k')
                    bar_from_patch(general.isis.log10, cell_metrics.isi.log10(:,ii),col)
                    xlim([0,10]), xlabel('Time (sec)'), ylabel('Rate (Hz)'),
                    
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    bar_from_patch(1./general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^ACGLogIntervals))',col)
                    xlim([0,1000]), xlabel('Instantaneous rate (Hz)'), ylabel('Occurence'),
                else
                    bar_from_patch(general.isis.log10, cell_metrics.isi.log10(:,ii).*(diff(10.^ACGLogIntervals))',col)  
                    xlim([0,10]), xlabel('Time (sec)'), ylabel('Occurence'),
                end
                set(gca,'xscale','log')
                ax5 = axis; grid on, set(gca, 'Layer', 'top')
                title(['ISI distribution - firing rate: ', num2str(cell_metrics.firingRate(ii),3),'Hz'])
                if UI.settings.dispLegend == 1
                    legend({'ACG-ISI','ISI distribution'})
                end
            else
                title('ISI distribution')
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'ISIs (all)') % ISIs
            
            if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10') && length(classes2plotSubset) > 0
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                    xdata = repmat([general.isis.log10',nan(1,1)],length(set1),1)';
                    if strcmp(UI.settings.isiNormalization,'Rate')
                        ydata = [cell_metrics.isi.log10(:,set1);nan(1,length(set1))];
                        xlim1 = [0,10];
                        xlabel('Time (sec)'), ylabel('Rate (Hz)')
                    elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                        xdata = repmat([1./general.isis.log10',nan(1,1)],length(set1),1)';
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,1000];
                        xlabel('Instantaneous rate (Hz)'), ylabel('Occurence')
                    else
                        ydata = [cell_metrics.isi.log10(:,set1).*(diff(10.^ACGLogIntervals))';nan(1,length(set1))];
                        xlim1 = [0,10];
                        xlabel('Time (sec)'), ylabel('Occurence')
                    end
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                if strcmp(UI.settings.isiNormalization,'Rate')
                    plot(general.isis.log10,cell_metrics.isi.log10(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    plot(1./general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                else
                    plot(general.isis.log10,cell_metrics.isi.log10(:,ii).*(diff(10.^ACGLogIntervals))', 'color', 'k','linewidth',1.5,'HitTest','off')
                end
                xlim(xlim1), set(gca,'xscale','log')
                title(['All ISIs'])
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
        elseif strcmp(customPlotSelection,'ACGs (all)')
            
            % All ACGs. Colored by to cell-type.
            if strcmp(UI.settings.acgType,'Normal')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                    xdata = repmat([[-100:100]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(:,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-100:100]/2,cell_metrics.acg.narrow(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-50:10:50]),xlim([-50,50])
                
            elseif strcmp(UI.settings.acgType,'Narrow')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                    xdata = repmat([[-30:30]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(41+30:end-40-30,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-15:5:15]),xlim([-15,15])
            elseif strcmp(UI.settings.acgType,'Log10')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                    xdata = repmat([general.acgs.log10',nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.log10(:,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot(general.acgs.log10,cell_metrics.acg.log10(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xlim([0,10]), set(gca,'xscale','log')
                
            else
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                    xdata = repmat([[-500:500],nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.wide(:,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-500:500],cell_metrics.acg.wide(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-500:100:500]),xlim([-500,500])
            end
            xlabel('Time (ms)'), ylabel('Rate (Hz)'), title(['All ACGs'])
        
        elseif strcmp(customPlotSelection,'ISIs (image)')
                
                [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
                
                if strcmp(UI.settings.isiNormalization,'Rate')
                    imagesc(general.isis.log10', [1:length(UI.params.subset)], cell_metrics.isi.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                    xlabel('Time')
                elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                    imagesc(1./general.isis.log10', [1:length(UI.params.subset)], cell_metrics.isi.log10_occurence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                    xlabel('Firing rate')
                else
                    imagesc(general.isis.log10', [1:length(UI.params.subset)], cell_metrics.isi.log10_occurence(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                    xlabel('Time')
                end
                if ~isempty(idx)
                    if strcmp(UI.settings.isiNormalization,'Firing rates')
                        plot(1./general.isis.log10([1,end]),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                    else
                        plot(general.isis.log10([1,end]),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                    end
                end
                colormap hot(512), title(['All ISIs (image)']), axis tight
                
        elseif strcmp(customPlotSelection,'ACGs (image)')
            
            % All ACGs shown in an image (z-scored). Sorted by the burst-index from Royer 2012
            [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(burstIndexSorted) == ii);
            if strcmp(UI.settings.acgType,'Normal')
                imagesc([-100:100]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-50,50],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
                plot([0,0],[0.5,length(UI.params.subset)+0.5],'w','HitTest','off')
                
            elseif strcmp(UI.settings.acgType,'Narrow')
                imagesc([-30:30]/2, [1:length(UI.params.subset)], cell_metrics.acg.narrow_normalized(41+30:end-40-30,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-15,15],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
                plot([0,0],[0.5,length(UI.params.subset)+0.5],'w','HitTest','off')
                
            elseif strcmp(UI.settings.acgType,'Log10')
                imagesc(general.acgs.log10', [1:length(UI.params.subset)], cell_metrics.acg.log10_rate(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot(general.acgs.log10([1,end]),[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
                %xlim([0,10]), xticks([1]),xticklabels({'0.001','0.01','0.1','1','10'})
            else
                imagesc([-500:500], [1:length(UI.params.subset)], cell_metrics.acg.wide_normalized(:,UI.params.subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-500,500],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
                plot([0,0],[0.5,length(UI.params.subset)+0.5],'w','HitTest','off')
            end
            colormap hot(512), xlabel('Time'), title(['All ACGs (image)']), axis tight
            
        elseif strcmp(customPlotSelection,'tSNE of narrow ACGs')
            
            % t-SNE scatter-plot with all ACGs. Calculated from the narrow
            % ACG (-50ms:0.5ms:50ms). Colored by cell-type.
            legendScatter5 = gscatter(tSNE_metrics.acg_narrow(UI.params.subset,1), tSNE_metrics.acg_narrow(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
            set(legendScatter5,'HitTest','off')
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.acg_narrow(ii,1), tSNE_metrics.acg_narrow(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.acg_narrow(ii,1), tSNE_metrics.acg_narrow(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of wide ACGs')
            
            % t-SNE scatter-plot with all ACGs. Calculated from the wide
            % ACG (-500ms:1ms:500ms). Colored by cell-type.
            if ~isempty(clr)
                legendScatter5 = gscatter(tSNE_metrics.acg_wide(UI.params.subset,1), tSNE_metrics.acg_wide(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
                set(legendScatter5,'HitTest','off')
            end
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            plot(tSNE_metrics.acg_wide(ii,1), tSNE_metrics.acg_wide(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.acg_wide(ii,1), tSNE_metrics.acg_wide(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
          
         elseif strcmp(customPlotSelection,'tSNE of log ACGs')
            
            % t-SNE scatter-plot with all ACGs. Calculated from the log10
            % ACG (-500ms:1ms:500ms). Colored by cell-type.
            if ~isempty(clr)
                legendScatter5 = gscatter(tSNE_metrics.acg_log10(UI.params.subset,1), tSNE_metrics.acg_log10(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
                set(legendScatter5,'HitTest','off')
            end
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            plot(tSNE_metrics.acg_log10(ii,1), tSNE_metrics.acg_log10(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.acg_log10(ii,1), tSNE_metrics.acg_log10(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of log ISIs')
            
            % t-SNE scatter-plot with all ISIs. Calculated from the log10
            if ~isempty(clr)
                legendScatter5 = gscatter(tSNE_metrics.isi_log10(UI.params.subset,1), tSNE_metrics.isi_log10(UI.params.subset,2), plotClas(UI.params.subset), clr,'',20,'off');
                set(legendScatter5,'HitTest','off')
            end
            title('Interspike intervals - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            plot(tSNE_metrics.isi_log10(ii,1), tSNE_metrics.isi_log10(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.isi_log10(ii,1), tSNE_metrics.isi_log10(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'firingRateMaps_firingRateMap')
            firingRateMapName = 'firingRateMap';
            % Precalculated firing rate map for the cell
            if isfield(cell_metrics.firingRateMaps,firingRateMapName) && size(cell_metrics.firingRateMaps.(firingRateMapName),2)>=ii && ~isempty(cell_metrics.firingRateMaps.(firingRateMapName){ii})
                firingRateMap = cell_metrics.firingRateMaps.(firingRateMapName){ii};
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'x_bins')
                    x_bins = general.firingRateMaps.(firingRateMapName).x_bins(:);
                else
                    x_bins = [1:length(firingRateMap)];
                end
                plot(x_bins,firingRateMap,'-','color', 'k','linewidth',2, 'HitTest','off'), xlabel('Position (cm)'), ylabel('Rate (Hz)')
                
                % Synaptic partners are also displayed
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.firingRateMaps.(firingRateMapName){[UI.params.outgoing;UI.params.incoming]});
                        subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                        if ~isempty(UI.params.outbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMaps.(firingRateMapName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(UI.params.inbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMaps.(firingRateMapName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                        end
                end
                axis tight, ax6 = axis; grid on,
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'boundaries')
                    boundaries = general.firingRateMaps.(firingRateMapName).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            title('Firing rate map')
            
        elseif contains(customPlotSelection,{'firingRateMaps_'})
            firingRateMapName = customPlotSelection(16:end);
            % A state dependent firing rate map
            if isfield(cell_metrics.firingRateMaps,firingRateMapName)  && size(cell_metrics.firingRateMaps.(firingRateMapName),2)>=ii && ~isempty(cell_metrics.firingRateMaps.(firingRateMapName){ii})
                firingRateMap = cell_metrics.firingRateMaps.(firingRateMapName){ii};
                
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'x_bins')
                    x_bins = general.firingRateMaps.(firingRateMapName).x_bins;
                else
                    x_bins = [1:size(firingRateMap,1)];
                end
                if UI.settings.firingRateMap.showHeatmap
                    imagesc(x_bins,1:size(firingRateMap,2),firingRateMap','HitTest','off');
                    xlabel('Position (cm)'),
                    if UI.settings.firingRateMap.showHeatmapColorbar
                        colorbar
                    end
                else
                    plt1 = plot(x_bins,firingRateMap,'-','linewidth',2, 'HitTest','off');
                    xlabel('Position (cm)'),ylabel('Rate (Hz)'); grid on,
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
                        plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                    end
                end
%                 set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,['No data'],'FontWeight','bold','HorizontalAlignment','center')
            end
            title(customPlotSelection, 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,{'psth_'}) & ~contains(customPlotSelection,{'spikes_'})
            eventName = customPlotSelection(6:end);
            if isfield(cell_metrics.psth,eventName) && length(cell_metrics.psth.(eventName))>=ii && ~isempty(cell_metrics.psth.(eventName){ii})
                psth_response = cell_metrics.psth.(eventName){ii};
                
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'x_bins')
                    x_bins = general.psth.(eventName).x_bins(:);
                else
                    x_bins = [1:size(psth_response,1)];
                end
                plot(x_bins,psth_response,'color', 'k','linewidth',2, 'HitTest','off')
                
                switch UI.monoSyn.disp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.psth.(eventName){[UI.params.outgoing;UI.params.incoming]});
                        subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                        if ~isempty(UI.params.outbound)
                            plot(x_bins,horzcat(cell_metrics.psth.(eventName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(UI.params.inbound)
                            plot(x_bins,horzcat(cell_metrics.psth.(eventName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                        end
                end
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'boundaries')
                    boundaries = general.psth.(eventName).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'boundaries')
                    boundaries = general.psth.(eventName).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            
            title(eventName, 'Interpreter', 'none'), xlabel('Time (s)'),ylabel('Rate (Hz)')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            
        elseif contains(customPlotSelection,'events_')
            eventName = customPlotSelection(8:end);
            if isfield(cell_metrics.events,eventName) && length(cell_metrics.events.(eventName))>=ii && ~isempty(cell_metrics.events.(eventName){ii})
                rippleCorrelogram = cell_metrics.events.(eventName){ii};
                
                if isfield(general.events,eventName) & isfield(general.events.(eventName),'x_bins')
                    x_bins = general.events.(eventName).x_bins(:);
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                if ~isempty(putativeSubset)
                    switch UI.monoSyn.disp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.events.(eventName){[UI.params.outgoing;UI.params.incoming]});
                            subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                            if ~isempty(UI.params.outbound)
                                plot(x_bins,horzcat(cell_metrics.events.(eventName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(UI.params.inbound)
                                plot(x_bins,horzcat(cell_metrics.events.(eventName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                            end
                    end
                end
                plot(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'), xlabel('time'),ylabel('')
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            title([eventName ' event histogram'], 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,'manipulations_')
            eventName = customPlotSelection(15:end);
            if isfield(cell_metrics.manipulations,eventName) && ~isempty(cell_metrics.manipulations.(eventName){ii})
                rippleCorrelogram = cell_metrics.manipulations.(eventName){ii};
                
                if isfield(general.manipulations,eventName) & isfield(general.manipulations.(eventName),'x_bins')
                    x_bins = general.manipulations.(eventName).x_bins(:);
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                if ~isempty(putativeSubset)
                    switch UI.monoSyn.disp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.manipulations.(eventName){[UI.params.outgoing;UI.params.incoming]});
                            subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                            if ~isempty(UI.params.outbound)
                                plot(x_bins,horzcat(cell_metrics.manipulations.(eventName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(UI.params.inbound)
                                plot(x_bins,horzcat(cell_metrics.manipulations.(eventName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                            end
                    end
                end
                plot(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'), xlabel('time'),ylabel('')
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            title([eventName ' manipulation histogram'], 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,'responseCurves_') & ~contains(customPlotSelection,'Phase')
            responseCurvesName = customPlotSelection(16:end);
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                firingRateAcrossTime = cell_metrics.responseCurves.(responseCurvesName){ii};
                if isfield(general.responseCurves,responseCurvesName) & isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    x_bins = general.responseCurves.(responseCurvesName).x_bins;
                else
                    x_bins = [1:length(firingRateAcrossTime)];
                end
                plt1 = plot(x_bins,firingRateAcrossTime,'color', 'k','linewidth',2, 'HitTest','off');
                
                if ~isempty(putativeSubset)
                    switch UI.monoSyn.disp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.responseCurves.(responseCurvesName){[UI.params.outgoing;UI.params.incoming]});
                            subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                            if ~isempty(UI.params.outbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(UI.params.inbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                            end
                    end
                end
                xlabel('Time (minutes)'), ylabel('Rate (Hz)')
                axis tight, ax6 = axis; grid on,
                
                if isfield(general.responseCurves,responseCurvesName)
                    if isfield(general.responseCurves.(responseCurvesName),'boundaries')
                        boundaries = general.responseCurves.(responseCurvesName).boundaries;
                        plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                        if isfield(general.responseCurves.(responseCurvesName),'boundaries_labels')
                            boundaries_labels = general.responseCurves.(responseCurvesName).boundaries_labels;
                            if length(boundaries_labels) == length(boundaries)
                                text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none');
                            end
                        end
                    end
                end
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            title([responseCurvesName ' response'], 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,'responseCurves_') && contains(customPlotSelection,'Phase') && ~contains(customPlotSelection,'(image)') && ~contains(customPlotSelection,'(all)')
            responseCurvesName = customPlotSelection(16:end);
            if isfield(cell_metrics.responseCurves,responseCurvesName) && ~isempty(cell_metrics.responseCurves.(responseCurvesName){ii})
                thetaPhaseResponse = cell_metrics.responseCurves.(responseCurvesName){ii};
                if isfield(general.responseCurves,responseCurvesName) & isfield(general.responseCurves.(responseCurvesName),'x_bins')
                    x_bins = general.responseCurves.(responseCurvesName).x_bins;
                else
                    x_bins = [1:length(thetaPhaseResponse)];
                end
                plt1 = plot(x_bins,thetaPhaseResponse,'color', 'k','linewidth',2, 'HitTest','off');
                
                if ~isempty(putativeSubset)
                    switch UI.monoSyn.disp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.responseCurves.(responseCurvesName){[UI.params.outgoing;UI.params.incoming]});
                            subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                            if ~isempty(UI.params.outbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){UI.params.outgoing}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(UI.params.inbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){UI.params.incoming}),'color', 'b', 'HitTest','off')
                            end
                    end
                end
                axis tight, ax6 = axis; grid on,
            else
                text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
            end
            title([responseCurvesName, ' response'],'Interpreter', 'none'), xlabel('Phase'), ylabel('Probability')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            
        elseif contains(customPlotSelection,'responseCurves_') && contains(customPlotSelection,'(image)')
            responseCurvesName = customPlotSelection(16:end-8);
            
            % All responseCurves shown in an imagesc plot
            % Sorted according to user input
            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
            [~,idx] = find(UI.params.subset(troughToPeakSorted) == ii);
            
            imagesc(UI.x_bins.thetaPhase, [1:length(UI.params.subset)], cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset(troughToPeakSorted))','HitTest','off'),
            colormap hot(512), xlabel('Phase '), title('Theta phase (image)')
            
            % selected cell highlighted in white
            if ~isempty(idx)
                plot([UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
            end
            
        elseif contains(customPlotSelection,'responseCurves_') && contains(customPlotSelection,'(all)')
            
            responseCurvesName = customPlotSelection(16:end-6);
            % All responseCurves colored according to cell type
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), UI.params.subset);
                xdata = repmat([UI.x_bins.thetaPhase,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.responseCurves.thetaPhase_zscored(:,set1);nan(1,length(set1))];
                plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            % selected cell in black
            plot(UI.x_bins.thetaPhase, cell_metrics.responseCurves.thetaPhase_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Phase'), ylabel('z-scored distribution'), title('Theta phase')
            
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
                            plot(vertcat(adjustedSpikes{:}),vertcat(spikeEvent{:}),'.','color', [0.5 0.5 0.5])
                            if isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).state)
                                data_x = vertcat(adjustedSpikes{:});
                                data_y = vertcat(spikeEvent{:});
                                data_g = vertcat(adjustedSpikesStates{:});
                                gscatter(data_x(~isnan(data_g)),data_y(~isnan(data_g)), data_g(~isnan(data_g)),[],'',8,'off');
                            end
                        else
                            plot(vertcat(adjustedSpikes{:}),vertcat(spikeEvent{:}),'.','color', col)
                        end
                    end
                    grid on, plot([0, 0], [0 length(ts_onset)],'color','k', 'HitTest','off');
                    if spikesPlots.(customPlotSelection).plotAverage
                        % Average plot (histogram) for events
                        bin_duration = (secbefore + secafter)/plotAverage_nbins;
                        bin_times = -secbefore:bin_duration:secafter;
                        bin_times2 = bin_times(1:end-1) + mean(diff(bin_times))/2;
                        spkhist = histcounts(vertcat(adjustedSpikes{:}),bin_times);
                        plotData = spkhist/(bin_duration*length(ts_onset));
                        if spikesPlots.(customPlotSelection).plotRaster
                            scalingFactor = (0.2*length(ts_onset)/max(plotData));
                            plot([-secbefore,secafter],[0,0],'-k'), text(secafter,0,[num2str(max(plotData),3),'Hz'],'HorizontalAlignment','right','VerticalAlignment','top','Interpreter', 'none')
                            plot(bin_times2,plotData*scalingFactor-(max(plotData)*scalingFactor),'color', col,'linewidth',2);
                        else
                            plot(bin_times2,plotData,'color', col,'linewidth',2);
                        end
                        if spikesPlots.(customPlotSelection).plotAmplitude && isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'amplitude')
                            temp = events.(spikesPlots.(customPlotSelection).event){batchIDs}.amplitude(idxOrder);
                            temp2 = find(temp>0);
                            plot(secafter+temp(temp2)/max(temp(temp2))*(secbefore+secafter)/6,temp2,'.k')
                            text(secafter+(secbefore+secafter)/6,0,'Amplitude','color','k','HorizontalAlignment','left','VerticalAlignment','bottom','rotation',90,'Interpreter', 'none')
                            plot([0, secafter+(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                            plot([secafter, secafter], [0 length(ts_onset)],'color','k', 'HitTest','off');
                        end
                        if spikesPlots.(customPlotSelection).plotDuration && isfield(events.(spikesPlots.(customPlotSelection).event){batchIDs},'duration')
                            temp = events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration(idxOrder);
                            temp2 = find(temp>0);
                            plot(secafter+temp(temp2)/max(temp(temp2))*(secbefore+secafter)/6,temp2,'.r')
                            duration = events.(spikesPlots.(customPlotSelection).event){batchIDs}.duration;
                            text(secafter+(secbefore+secafter)/6,0,['Duration (' num2str(min(duration)),' => ',num2str(max(duration)),' sec)'],'color','r','HorizontalAlignment','left','VerticalAlignment','top','rotation',90,'Interpreter', 'none')
                            plot([0, secafter+(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                            plot([secafter, secafter], [0 length(ts_onset)],'color','k', 'HitTest','off');
                        end
                        if spikesPlots.(customPlotSelection).plotCount && isfield(spikesPlots.(customPlotSelection),'plotCount')
                            count = histcounts(vertcat(spikeEvent{:}),[0:length(spikeEvent)]+0.5);
                            plot(-secbefore-count/max(count)*(secbefore+secafter)/6,[1:length(spikeEvent)],'.b')
                            text(-secbefore-(secbefore+secafter)/6,0,['Count (' num2str(min(count)),' => ',num2str(max(count)),' count)'],'color','b','HorizontalAlignment','left','VerticalAlignment','top','rotation',90,'Interpreter', 'none')
                            plot([0, -secbefore-(secbefore+secafter)/6], [0 0],'color','k', 'HitTest','off');
                        end
                        plot([0, 0], [0 -0.2*length(ts_onset)],'color','k', 'HitTest','off');
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
                    plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)},'.','color', [0.5 0.5 0.5]),
                    if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                        plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)},spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}+2*pi,'.','color', [0.5 0.5 0.5])
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
                plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)}(idx_filter),spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}(idx_filter),'.','color', col)
                
                if strcmp(spikesPlots.(customPlotSelection).y,'theta_phase')
                    plot(spikes{batchIDs}.(spikesPlots.(customPlotSelection).x){cell_metrics.UID(ii)}(idx_filter),spikes{batchIDs}.(spikesPlots.(customPlotSelection).y){cell_metrics.UID(ii)}(idx_filter)+2*pi,'.','color', col)
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
            if isnumeric(plotData)
                plotData = plotData(:,ii);
            else
                plotData = plotData{ii};
            end
            if isfield(general,customPlotSelection) & isfield(general.(customPlotSelection),'x_bins')
                x_bins = general.(customPlotSelection).x_bins;
            else
                x_bins = [1:length(plotData)];
            end
            plot(x_bins,plotData,'color', 'k','linewidth',2, 'HitTest','off')
            
            if isnumeric(cell_metrics.(plotOptions{customCellPlotNum}))
                switch UI.monoSyn.disp
                    case {'All'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = cell_metrics.(plotOptions{customCellPlotNum})(:,UI.params.outgoing);
                        subsetPlots.subset = UI.params.outgoing;
                        plot(x_bins,cell_metrics.(plotOptions{customCellPlotNum})(:,UI.params.outgoing),'color', [0,0,0,.5])
                    case {'Selected','Upstream','Downstream','Up & downstream'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = cell_metrics.(plotOptions{customCellPlotNum})(:,[UI.params.outgoing;UI.params.incoming]);
                        subsetPlots.subset = [UI.params.outgoing;UI.params.incoming];
                        if ~isempty(UI.params.outbound)
                            plot(x_bins,cell_metrics.(plotOptions{customCellPlotNum})(:,UI.params.outgoing),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(UI.params.inbound)
                            plot(x_bins,cell_metrics.(plotOptions{customCellPlotNum})(:,UI.params.incoming),'color', 'b', 'HitTest','off')
                        end
                end
            end
            title(plotOptions{customCellPlotNum}, 'Interpreter', 'none'), xlabel(''),ylabel('')
            axis tight, ax6 = axis; grid on
            plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
            if isfield(general,customPlotSelection)
                if isfield(general.(customPlotSelection),'boundaries')
                    boundaries = general.(customPlotSelection).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                    if isfield(general.(customPlotSelection),'boundaries_labels')
                        boundaries_labels = general.(customPlotSelection).boundaries_labels;
                        text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none');
                    end
                end
                
            end
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function plotGroudhTruthCells(plotX1,plotY1)
        if groundTruthSelection
            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
            for jj = 1:length(idGroundTruth)
                plot(plotX1(subsetGroundTruth{idGroundTruth(jj)}), plotY1(subsetGroundTruth{idGroundTruth(jj)}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function plotGroupData(plotX1,plotY1,plotConnections1)
        if ~isempty(clr)
            legendScatter = gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), plotClas(UI.params.subset), clr,'',UI.settings.markerSize,'off');
            set(legendScatter,'HitTest','off')
        end
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(plotX1(cellsExcitatory_subset), plotY1(cellsExcitatory_subset),'^k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(plotX1(cellsInhibitory_subset), plotY1(cellsInhibitory_subset),'ok', 'HitTest','off')
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(cellsExcitatoryPostsynaptic_subset)
            plot(plotX1(cellsExcitatoryPostsynaptic_subset), plotY1(cellsExcitatoryPostsynaptic_subset),'vk', 'HitTest','off')
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(cellsInhibitoryPostsynaptic_subset)
            plot(plotX1(cellsInhibitoryPostsynaptic_subset), plotY1(cellsInhibitoryPostsynaptic_subset),'*k', 'HitTest','off')
        end
        
        % Plots putative connections
        if plotConnections1 == 1 && ~isempty(putativeSubset)
            switch UI.monoSyn.disp
                case 'All'
                    xdata = [plotX1(UI.params.a1);plotX1(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY1(UI.params.a1);plotY1(UI.params.a2);nan(1,length(UI.params.a2))];
                    plot(xdata(:),ydata(:),'-k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX1(UI.params.incoming);plotX1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY1(UI.params.incoming);plotY1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        plot(xdata,ydata,'-ob','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX1(UI.params.a1(UI.params.outbound));plotX1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY1(UI.params.a1(UI.params.outbound));plotY1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        plot(xdata(:),ydata(:),'-om','HitTest','off')
                    end
            end
        end
        
        % Plots X marker for selected cell
%         plotMarker(tSNE_metrics.plot(ii,1),tSNE_metrics.plot(ii,2))
        plot(plotX1(ii), plotY1(ii),'xw', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        plot(plotX1(ii), plotY1(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
        
        % Plots tagget ground-truth cell types
        if groundTruthSelection
            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
            for jj = 1:length(idGroundTruth)
                plot(plotX1(subsetGroundTruth{idGroundTruth(jj)}), plotY1(subsetGroundTruth{idGroundTruth(jj)}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
            end
        end
        
        if UI.settings.stickySelection
            plot(plotX1(UI.params.ClickedCells),plotY1(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function plotGroupScatter(plotX1,plotY1)
        if ~isempty(clr)
            legendScatter = gscatter(plotX1(UI.params.subset), plotY1(UI.params.subset), plotClas(UI.params.subset), clr,'',UI.settings.markerSize,'off');
            set(legendScatter,'HitTest','off')
        end
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(plotX1(cellsExcitatory_subset), plotY1(cellsExcitatory_subset),'^k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(plotX1(cellsInhibitory_subset), plotY1(cellsInhibitory_subset),'ok', 'HitTest','off')
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(cellsExcitatoryPostsynaptic_subset)
            plot(plotX1(cellsExcitatoryPostsynaptic_subset), plotY1(cellsExcitatoryPostsynaptic_subset),'vk', 'HitTest','off')
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(cellsInhibitoryPostsynaptic_subset)
            plot(plotX1(cellsInhibitoryPostsynaptic_subset), plotY1(cellsInhibitoryPostsynaptic_subset),'*k', 'HitTest','off')
        end
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function plotMarker(plotX1,plotY1)
        plot(plotX1, plotY1,'xw', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        plot(plotX1, plotY1,'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function plotPutativeConnections(plotX1,plotY1)
        if ~isempty(putativeSubset)
            switch UI.monoSyn.disp
                case 'All'
                    xdata = [plotX1(UI.params.a1);plotX1(UI.params.a2);nan(1,length(UI.params.a2))];
                    ydata = [plotY1(UI.params.a1);plotY1(UI.params.a2);nan(1,length(UI.params.a2))];
                    plot(xdata(:),ydata(:),'-k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(UI.params.inbound)
                        xdata = [plotX1(UI.params.incoming);plotX1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        ydata = [plotY1(UI.params.incoming);plotY1(UI.params.a2(UI.params.inbound));nan(1,length(UI.params.a2(UI.params.inbound)))];
                        plot(xdata,ydata,'-ob','HitTest','off')
                    end
                    if ~isempty(UI.params.outbound)
                        xdata = [plotX1(UI.params.a1(UI.params.outbound));plotX1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        ydata = [plotY1(UI.params.a1(UI.params.outbound));plotY1(UI.params.outgoing);nan(1,length(UI.params.outgoing))];
                        plot(xdata(:),ydata(:),'-om','HitTest','off')
                    end
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function highlightExcitatoryCells(~,~)
        % Highlight excitatory cells
        UI.settings.displayExcitatory = ~UI.settings.displayExcitatory;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(cellsExcitatory))])
        if UI.settings.displayExcitatory
            UI.menu.monoSyn.highlightExcitatory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightExcitatory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function highlightInhibitoryCells(~,~)
        % Highlight inhibitory cells
        UI.settings.displayInhibitory = ~UI.settings.displayInhibitory;
        MsgLog(['Toggle highlighting inhibitory cells (circles), Count: ', num2str(length(cellsInhibitory))])
        if UI.settings.displayInhibitory
            UI.menu.monoSyn.highlightInhibitory.Checked = 'on';
        else
            UI.menu.monoSyn.highlightInhibitory.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function highlightExcitatoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.settings.displayExcitatoryPostsynapticCells = ~UI.settings.displayExcitatoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(cellsExcitatory))])
        if UI.settings.displayExcitatoryPostsynapticCells
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'on';
        else
            UI.menu.monoSyn.excitatoryPostsynapticCells.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function highlightInhibitoryPostsynapticCells(~,~)
        % Highlight excitatory post-synaptic cells
        UI.settings.displayInhibitoryPostsynapticCells = ~UI.settings.displayInhibitoryPostsynapticCells;
        MsgLog(['Toggle highlighting excitatory cells (diamonds). Count: ', num2str(length(cellsExcitatory))])
        if UI.settings.displayInhibitoryPostsynapticCells
            UI.menu.monoSyn.inhibitoryPostsynapticCells.Checked = 'on';
        else
            UI.menu.monoSyn.inhibitoryPostsynapticCells.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function reloadCellMetrics(~,~)
        answer = questdlg('Are you sure you want to reload the cell metrics?', 'Reload cell metrics', 'Yes','Cancel','Cancel');
        if strcmp(answer,'Yes') && UI.BatchMode
            f_LoadCellMetrics = waitbar(0,' ','name','Cell-metrics: loading batch');
            try
                cell_metrics1 = LoadCellMetricBatch('clusteringpaths', cell_metrics.general.path,'basenames',cell_metrics.general.basenames,'basepaths',cell_metrics.general.basepaths,'waitbar_handle',f_LoadCellMetrics);
                if ~isempty(cell_metrics1)
                    cell_metrics = cell_metrics1;
                else
                    return
                end
                SWR_in = {};
                
                if ishandle(f_LoadCellMetrics)
                    waitbar(1,f_LoadCellMetrics,'Initializing session(s)');
                else
                    disp(['Initializing session(s)']);
                end
                
                initializeSession
                if ishandle(f_LoadCellMetrics)
                    close(f_LoadCellMetrics)
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
    
% % % % % % % % % % % % % % % % % % % % % %

    function restoreBackup(~,~)
        try 
            dir(pwd);
        catch
            MsgLog(['Unable to access current folder.'],4)
            selpath = uigetdir(matlabroot,'Please select current folder');
            cd(selpath)
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
            restoreBackup.dialog = dialog('Position', [300, 300, 300, 518],'Name','Select backup to restore','WindowStyle','modal'); movegui(restoreBackup.dialog,'center')
            restoreBackup.backupList = uicontrol('Parent',restoreBackup.dialog,'Style','listbox','String',backupList,'Position',[10, 60, 280, 447],'Value',1,'Max',1,'Min',1);
            uicontrol('Parent',restoreBackup.dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)closeDialog);
            uicontrol('Parent',restoreBackup.dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)cancelDialog);
            uiwait(restoreBackup.dialog)
        end
        function closeDialog
            backupToRestore = backupList{restoreBackup.backupList.Value};
            delete(restoreBackup.dialog);
            
            % Creating backup of existing metrics
            createBackup(cell_metrics,cell_metrics.batchIDs(ii))
            
            % Restoring backup to metrics
            if UI.BatchMode
                backup_subset = find(cell_metrics.batchIDs == cell_metrics.batchIDs(ii));
                cell_metrics_backup = load(fullfile(cell_metrics.general.path{cell_metrics.batchIDs(ii)},'revisions_cell_metrics',backupToRestore));
            else
                backup_subset = 1:cell_metrics.general.cellCount;
                cell_metrics_backup = load(fullfile(cell_metrics.general.path,'revisions_cell_metrics',backupToRestore));
            end
            if size(cell_metrics_backup.cell_metrics.putativeCellType,2) == length(backup_subset)
                saveStateToHistory(backup_subset);
                cell_metrics.labels(backup_subset) = cell_metrics_backup.cell_metrics.labels;
                if isfield(cell_metrics_backup.cell_metrics,'tags')
                    cell_metrics.tags(backup_subset) = cell_metrics_backup.cell_metrics.tags;
                end
                if isfield(cell_metrics_backup.cell_metrics,'deepSuperficial')
                    cell_metrics.deepSuperficial(backup_subset) = cell_metrics_backup.cell_metrics.deepSuperficial;
                    cell_metrics.deepSuperficialDistance(backup_subset) = cell_metrics_backup.cell_metrics.deepSuperficialDistance;
                end
                cell_metrics.brainRegion(backup_subset) = cell_metrics_backup.cell_metrics.brainRegion;
                cell_metrics.putativeCellType(backup_subset) = cell_metrics_backup.cell_metrics.putativeCellType;
                if isfield(cell_metrics_backup.cell_metrics,'groundTruthClassification')
                    cell_metrics.groundTruthClassification(backup_subset) = cell_metrics_backup.cell_metrics.groundTruthClassification;
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
    
    % % % % % % % % % % % % % % % % % % % % % %
    
    function createBackup(cell_metrics,backup_subset)
        % Creating backup of metrics 
        if ~exist('backup_subset')
            backup_subset = 1:length(cell_metrics.UID);
        end
        
        cell_metrics_backup = {};
        cell_metrics_backup.labels = cell_metrics.labels(backup_subset);
        if isfield(cell_metrics,'tags')
            cell_metrics_backup.tags = cell_metrics.tags(backup_subset);
        end
        if isfield(cell_metrics,'deepSuperficial')
            cell_metrics_backup.deepSuperficial = cell_metrics.deepSuperficial(backup_subset);
            cell_metrics_backup.deepSuperficialDistance = cell_metrics.deepSuperficialDistance(backup_subset);
        end
        cell_metrics_backup.brainRegion = cell_metrics.brainRegion(backup_subset);
        cell_metrics_backup.putativeCellType = cell_metrics.putativeCellType(backup_subset);
        if isfield(cell_metrics,'groundTruthClassification')
            cell_metrics_backup.groundTruthClassification = cell_metrics.groundTruthClassification(backup_subset);
        end
        
        S.cell_metrics = cell_metrics_backup;
        if UI.BatchMode && isfield(cell_metrics.general,'saveAs')
            saveAs = cell_metrics.general.saveAs{cell_metrics.batchIDs(ii)};
        elseif isfield(cell_metrics.general,'saveAs')
            saveAs = cell_metrics.general.saveAs;
        else
            saveAs = 'cell_metrics';
        end
        
        if UI.BatchMode
            path1 = cell_metrics.general.path{batchIDs};
        else
            path1 = cell_metrics.general.path;
        end
        if ~(exist(fullfile(path1,'revisions_cell_metrics'),'dir'))
            mkdir(fullfile(path1,'revisions_cell_metrics'));
        end
        save(fullfile(path1, 'revisions_cell_metrics', [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']),'-struct', 'S','-v7.3','-nocompression');
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleHollowGauss(~,~)
        if UI.monoSyn.dispHollowGauss
            UI.monoSyn.dispHollowGauss = false;
            UI.menu.monoSyn.toggleHollowGauss.Checked = 'off';
        else
            UI.monoSyn.dispHollowGauss = true;
            UI.menu.monoSyn.toggleHollowGauss.Checked = 'on';
        end
    end

% % % % % % % % % % % % % % % % % % % % % %
    
    function updatePlotConnections(src,event)
        if strcmp(src.Checked,'on')
            plotConnections(src.Position) = 0;
            UI.menu.monoSyn.plotConns.ops(src.Position).Checked = 'off';
        else
            plotConnections(src.Position) = 1;
            UI.menu.monoSyn.plotConns.ops(src.Position).Checked = 'on';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function openWiki(~,~)
        % Opens the Cell Explorer wiki in your browser
        web('https://github.com/petersenpeter/Cell-Explorer/wiki','-new','-browser')
    end

% % % % % % % % % % % % % % % % % % % % % %

    function openSessionDirectory(~,~)
        % Opens the file directory for the selected cell
        if UI.BatchMode
            if exist(cell_metrics.general.path{cell_metrics.batchIDs(ii)})==7
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
            if ispc
                winopen(pwd);
            else
                filebrowser;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function openSessionInWebDB(~,~)
        % Opens the current session in the Buzsaki lab web database
        web(['https://buzsakilab.com/wp/sessions/?frm_search=', general.basename],'-new','-browser')
    end

% % % % % % % % % % % % % % % % % % % % % %

    function showAnimalInWebDB(~,~)
        % Opens the current animal in the Buzsaki lab web database
        if isfield(cell_metrics,'animal')
            web(['https://buzsakilab.com/wp/animals/?frm_search=', cell_metrics.animal{ii}],'-new','-browser')
        else
            web(['https://buzsakilab.com/wp/animals/'],'-new','-browser')
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
            temp2 = find(strcmp(subfieldstypes,'struct') & ~strcmp(subfieldsnames,'general'));
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
        if exist('preselectedList')
            [~,ia,~] = intersect(list_metrics,preselectedList);
            list_metrics = [list_metrics(ia);list_metrics(setdiff(1:length(list_metrics),ia))];
        else 
            ia = [];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function defineMarkerSize(~,~)
        answer = inputdlg({'Enter marker size [recommended: 5-25]'},'Input',[1 40],{num2str(UI.settings.markerSize)});
        if ~isempty(answer)
            UI.settings.markerSize = str2double(answer);
            uiresume(UI.fig);
        end
    end
% % % % % % % % % % % % % % % % % % % % % %

        function editSortingMetric(~,~)
        sortingMetrics = generateMetricsList('double',UI.settings.sortingMetric);
        selectMetrics.dialog = dialog('Position', [300, 300, 400, 518],'Name','Select metric for sorting image data','WindowStyle','modal'); movegui(selectMetrics.dialog,'center')
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
    
% % % % % % % % % % % % % % % % % % % % % %
    
    function showReferenceData(src,evnt)
        if src.Position == 1
            UI.settings.referenceData = 'None';
            UI.menu.referenceData.ops(1).Checked = 'on';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'off';
            if isfield(UI.tabs,'referenceData')
                delete(UI.tabs.referenceData);
                UI.tabs = rmfield(UI.tabs,'referenceData');
            end
        elseif src.Position == 2
            UI.settings.referenceData = 'Image';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'on';
            UI.menu.referenceData.ops(3).Checked = 'off';
        elseif src.Position == 3
            UI.settings.referenceData = 'Points';
            UI.menu.referenceData.ops(1).Checked = 'off';
            UI.menu.referenceData.ops(2).Checked = 'off';
            UI.menu.referenceData.ops(3).Checked = 'on';
        end
        if ~isfield(UI.tabs,'referenceData') && src.Position > 1
            if isempty(reference_cell_metrics)
                out = loadReferenceData;
                if ~out
                    defineReferenceData;
                end
            end
            % UI.settings.referenceData
            UI.tabs.referenceData = uitab(UI.panel.tabgroup2,'Title','Reference');
            UI.listbox.referenceData = uicontrol('Parent',UI.tabs.referenceData,'Style','listbox','Position',getpixelposition(UI.tabs.referenceData),'Units','normalized','String',referenceData.cellTypes,'max',99,'min',1,'Value',1,'Callback',@(src,evnt)referenceDataSelection,'KeyPressFcn', {@keyPress});
            UI.panel.tabgroup2.SelectedTab = UI.tabs.referenceData;
            initReferenceDataTab
        end
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

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
    
    % % % % % % % % % % % % % % % % % % % % % %
    
    function referenceDataSelection(src,evnt)
        referenceData.selection = UI.listbox.referenceData.Value;
        uiresume(UI.fig);
    end
% % % % % % % % % % % % % % % % % % % % % %
    
    function showGroundTruthData(src,evnt)
        if src.Position == 1
            UI.settings.groundTruthData = 'None';
            UI.menu.groundTruth.ops(1).Checked = 'on';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'off';
            if isfield(UI.tabs,'groundTruthData')
                delete(UI.tabs.groundTruthData);
                UI.tabs = rmfield(UI.tabs,'groundTruthData');
            end
        elseif src.Position == 2
            UI.settings.groundTruthData = 'Image';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'on';
            UI.menu.groundTruth.ops(3).Checked = 'off';
        elseif src.Position == 3
            UI.settings.groundTruthData = 'Points';
            UI.menu.groundTruth.ops(1).Checked = 'off';
            UI.menu.groundTruth.ops(2).Checked = 'off';
            UI.menu.groundTruth.ops(3).Checked = 'on';
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

% % % % % % % % % % % % % % % % % % % % % %

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
    
    % % % % % % % % % % % % % % % % % % % % % %
    
    function groundTruthDataSelection(src,evnt)
        groundTruthData.selection = UI.listbox.groundTruthData.Value;
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function out = loadReferenceData
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'referenceData','reference_cell_metrics.cellinfo.mat');
        if exist(referenceData_path,'file')
            load(referenceData_path);
            [reference_cell_metrics,referenceData] = initializeReferenceData(reference_cell_metrics,'reference');
            out = true;
        else
            out = false;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function out = loadGroundTruthData
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'groundTruthData','groundTruth_cell_metrics.cellinfo.mat');
        if exist(referenceData_path,'file')
            load(referenceData_path);
            [groundTruth_cell_metrics,groundTruthData] = initializeReferenceData(groundTruth_cell_metrics,'groundTruth');
            out = true;
        else
            out = false;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
            tagFilter2 = find(cellfun(@(X) ~isempty(X), cell_metrics.groundTruthClassification));
            if ~isempty(tagFilter2)
                filter = [];
                for i = 1:length(tagFilter2)
                    filter(i,:) = strcmp(cell_metrics.groundTruthClassification{tagFilter2(i)},{UI.settings.groundTruth{groundTruthSelection}});
                end
                subsetGroundTruth = [];
                for j = 1:length({UI.settings.groundTruth{groundTruthSelection}})
                    subsetGroundTruth{j} = tagFilter2(find(filter(:,j)));
                end
            end
            [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
            referenceData_path = fullfile(referenceData_path,'groundTruthData');
            
            cell_list = [subsetGroundTruth{:}];
            sessionWithChanges = unique(cell_metrics.batchIDs(cell_list));
            f_waitbar = waitbar(0,[num2str(length(sessionWithChanges)),' sessions with changes'],'name','Saving ground truth cell metrics','WindowStyle','modal');
            for j = 1:length(sessionWithChanges)
                if ~ishandle(f_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                waitbar(j/length(sessionWithChanges),f_waitbar,['Session ' num2str(j),'/',num2str(length(sessionWithChanges)),': ', cell_metrics.general.basenames{sessionID}])
                cell_subset = cell_list(find(cell_metrics.batchIDs(cell_list)==sessionID));
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
                metrics_fieldNames2(find(contains(metrics_fieldNames2,{'putativeConnections','general'})))=[];
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
                
                % Saving the ground truth to the subfolder groundTruthData
                if UI.BatchMode
                    file = fullfile(referenceData_path,[cell_metrics.general.basenames{sessionID}, '.cell_metrics.cellinfo.mat']);
                else
                    file = fullfile(referenceData_path,[cell_metrics.general.basename, '.cell_metrics.cellinfo.mat']);
                end
                S.cell_metrics = cell_metrics_groundTruthSubset;
                save(file,'-struct', 'S','-v7.3','-nocompression');
            end
            if ishandle(f_waitbar)
                close(f_waitbar)
                MsgLog(['Ground truth data succesfully saved'],[1,2]);
            else
                MsgLog('Ground truth data not succesfully saved for all sessions',4);
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function defineGroundTruthData(src,evnt)
        [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
        referenceData_path = fullfile(referenceData_path,'groundTruthData');
        % 'groundTruth_cell_metrics.cellinfo.mat'
        listing = dir(fullfile(referenceData_path,'*.cell_metrics.cellinfo.mat'));
        listing = {listing.name};
        listing = cellfun(@(x) x(1:end-26), listing(:),'uni',0);
        if ~isempty(groundTruth_cell_metrics)
            initValue = find(ismember(listing',groundTruth_cell_metrics.sessionName));
        else
            initValue = 1;
        end
        [indx,tf] = listdlg('PromptString',['Select the metrics to load for ground truth classification'],'ListString',listing,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',initValue);
        
        if ~isempty(indx)
            listSession = listing(indx);
            referenceData_path1 = cell(1,length(listSession));
            referenceData_path1(:) = {referenceData_path};
            % Loading metrics
            groundTruth_cell_metrics = LoadCellMetricBatch('clusteringpaths', referenceData_path1,'basenames',listSession,'basepaths',referenceData_path1); % 'waitbar_handle',f_LoadCellMetrics
            
            % Saving batch metrics
            save(fullfile(referenceData_path,'groundTruth_cell_metrics.cellinfo.mat'),'groundTruth_cell_metrics','-v7.3','-nocompression');
            
            % Initializing
            [groundTruth_cell_metrics,groundTruthData] = initializeReferenceData(groundTruth_cell_metrics,'groundTruth');
            initGroundTruthTab
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function defineReferenceData(src,evnt)
        % Load reference data from NYU, through either local or internet connection
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
        if isempty(reference_cell_metrics)
            out = loadReferenceData;
        end
        
        drawnow nocallbacks;
        if isempty(db) && exist('db_cell_metrics_session_list.mat')
            load('db_cell_metrics_session_list.mat')
        elseif isempty(db)
            LoadDB_sessionlist
        end
        
        loadDB.dialog = dialog('Position', [300, 300, 900, 565],'Name','Cell Explorer: Load reference data','WindowStyle','modal', 'resize', 'on' ); movegui(loadDB.dialog,'center')
        loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 );
        loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        loadDB.sessionList = uitable(loadDB.VBox,'Data',db.dataTable,'Position',[10, 50, 880, 457],'ColumnWidth',{20 30 210 50 120 70 160 110 110 110},'columnname',{'','#','Session','Cells','Animal','Species','Behaviors','Investigator','Repository','Brain regions'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized'); % ,'CellSelectionCallback',@ClicktoSelectFromTable
        loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
        set(loadDB.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[480, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[640, 25, 150, 20],'Units','normalized','String','Repositories','HorizontalAlignment','center','Units','normalized');
        loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 460, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
        loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[480, 5, 150, 22],'Units','normalized','String',{'Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[640, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
        uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[800, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
        loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 480, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[700, 5, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog,'Units','normalized');
        uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[800, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog,'Units','normalized');
        
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
            
            if loadDB.popupmenu.repositories.Value == 1
                idx3 = find(ismember(db.menu_repository(db.index),[fieldnames(db_settings.repositories);'NYUshare_Datasets']));
            else
                idx3 = 1:size(db.dataTable,1);
            end
            
            idx2 = intersect(idx2,idx1,'stable');
            idx2 = intersect(idx2,idx3,'stable');
            loadDB.sessionList.Data = db.dataTable(idx2,:);
            UpdateSummaryText
        end
        
        function ClicktoSelectFromTable(src, event)
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
                    db_basename = {};
                    db_basepath = {};
                    db_clusteringpath = {};
                    db_basename = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
                    i_db_subset_all = db.index(indx);
                    [referenceData_path,~,~] = fileparts(which('CellExplorer.m'));
                    if ~exist(fullfile(referenceData_path,'referenceData'), 'dir')
                        mkdir(referenceData_path,'referenceData');
                    end
                    referenceData_path = fullfile(referenceData_path,'referenceData');
                    nyu_url = 'https://buzsakilab.nyumc.org/datasets/';
                    
                    f_LoadCellMetrics = waitbar(0,' ','name','Cell-metrics: loading reference data');
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
                            waitbar(i_db/length(i_db_subset_all),f_LoadCellMetrics,['Downloading missing reference data : ' db_basename{indx2}]);
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
                    
                    cell_metrics1 = LoadCellMetricBatch('clusteringpaths', db_clusteringpath,'basenames',db_basename(indx),'basepaths',db_basepath,'waitbar_handle',f_LoadCellMetrics);
                    if ~isempty(cell_metrics1)
                        reference_cell_metrics = cell_metrics1;
                    else
                        return
                    end
                    
                    if ishandle(f_LoadCellMetrics)
                        waitbar(1,f_LoadCellMetrics,'Initializing session(s)');
                    else
                        disp(['Initializing session(s)']);
                    end
                    save(fullfile(referenceData_path,'reference_cell_metrics.cellinfo.mat'),'reference_cell_metrics','-v7.3','-nocompression');
                    
                    [reference_cell_metrics,referenceData] = initializeReferenceData(reference_cell_metrics,'reference');
                    initReferenceDataTab
                    
                    if ishandle(f_LoadCellMetrics)
                        close(f_LoadCellMetrics)
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
    
% % % % % % % % % % % % % % % % % % % % % %

    function tSNE_redefineMetrics(~,~)
        [list_tSNE_metrics,ia] = generateMetricsList('all',UI.settings.tSNE.metrics);
        distanceMetrics = {'euclidean', 'seuclidean', 'cityblock', 'chebychev', 'minkowski', 'mahalanobis', 'cosine', 'correlation', 'spearman', 'hamming', 'jaccard'};
        %         [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        
        load_tSNE.dialog = dialog('Position', [300, 300, 500, 518],'Name','Select metrics for the tSNE plot','WindowStyle','modal'); movegui(load_tSNE.dialog,'center')
        load_tSNE.sessionList = uicontrol('Parent',load_tSNE.dialog,'Style','listbox','String',list_tSNE_metrics,'Position',[10, 95, 480, 402],'Value',1:length(ia),'Max',100,'Min',1);
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 73, 100, 20],'Units','normalized','String','nPCAComponents','HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 73, 90, 20],'Units','normalized','String','LearnRate','HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[220, 735, 70, 20],'Units','normalized','String','Perplexity','HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[380, 73, 110, 20],'Units','normalized','String','InitialY','HorizontalAlignment','left');

        UI.settings.tSNE.InitialY = 'Random';
        load_tSNE.popupmenu.NumPCAComponents = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[10, 55, 100, 20],'Units','normalized','String',UI.settings.tSNE.NumPCAComponents,'HorizontalAlignment','left');
        load_tSNE.popupmenu.LearnRate = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[120, 55, 90, 20],'Units','normalized','String',UI.settings.tSNE.LearnRate,'HorizontalAlignment','left');
        load_tSNE.popupmenu.Perplexity = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[220, 55, 70, 20],'Units','normalized','String',UI.settings.tSNE.Perplexity,'HorizontalAlignment','left');
        InitialYMetrics = {'Random','PCA space'};
        load_tSNE.popupmenu.InitialY = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[380, 55, 110, 20],'Units','normalized','String',InitialYMetrics,'HorizontalAlignment','left','Value',1);
        if find(strcmp(UI.settings.tSNE.InitialY,InitialYMetrics)); load_tSNE.popupmenu.InitialY.Value = find(strcmp(UI.settings.tSNE.InitialY,InitialYMetrics)); end
        
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 35, 90, 20],'Units','normalized','String','Algorithm','HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[100, 35, 110, 20],'Units','normalized','String','Distance metric','HorizontalAlignment','left');
        uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[220, 35, 70, 20],'Units','normalized','String','Exaggeration','HorizontalAlignment','left');
        load_tSNE.popupmenu.algorithm = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[10, 15, 90, 20],'Units','normalized','String',{'tSNE','UMAP','PCA'},'HorizontalAlignment','left');
        load_tSNE.popupmenu.distanceMetric = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[100, 15, 110, 20],'Units','normalized','String',distanceMetrics,'HorizontalAlignment','left');
        if find(strcmp(UI.settings.tSNE.dDistanceMetric,distanceMetrics)); load_tSNE.popupmenu.distanceMetric.Value = find(strcmp(UI.settings.tSNE.dDistanceMetric,distanceMetrics)); end
        load_tSNE.popupmenu.exaggeration = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[220, 15, 70, 20],'Units','normalized','String',num2str(UI.settings.tSNE.exaggeration),'HorizontalAlignment','left');
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
            
            delete(load_tSNE.dialog);
            f_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
            X(isnan(X) | isinf(X)) = 0;
            switch UI.settings.tSNE.algorithm
                case 'tSNE'
                    if strcmp(UI.settings.tSNE.InitialY,'PCA space')
                        waitbar(0.1,f_waitbar,'Calculating PCA init space space...')
                        initPCA = pca(X,'NumComponents',2);
                        waitbar(0.2,f_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.settings.tSNE.standardize,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration,'NumPCAComponents',UI.settings.tSNE.NumPCAComponents,'Perplexity',UI.settings.tSNE.Perplexity,'InitialY',initPCA,'LearnRate',UI.settings.tSNE.LearnRate);
                    else
                        waitbar(0.1,f_waitbar,'Calculating tSNE space...')
                        tSNE_metrics.plot = tsne(X','Standardize',UI.settings.tSNE.standardize,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration,'NumPCAComponents',UI.settings.tSNE.NumPCAComponents,'Perplexity',UI.settings.tSNE.Perplexity,'LearnRate',UI.settings.tSNE.LearnRate);
                    end
                case 'UMAP'
                    waitbar(0.1,f_waitbar,'Calculating UMAP space...')
                    tSNE_metrics.plot = run_umap(X','verbose','none'); % ,'metric',UI.settings.tSNE.dDistanceMetric
                case 'PCA'
                    waitbar(0.1,f_waitbar,'Calculating PCA space...')
                    tSNE_metrics.plot = pca(X,'NumComponents',2); % ,'metric',UI.settings.tSNE.dDistanceMetric
            end
            
            if size(tSNE_metrics.plot,2)==1
                tSNE_metrics.plot = [tSNE_metrics.plot,tSNE_metrics.plot];
            end
            
            if ishandle(f_waitbar)
                waitbar(1,f_waitbar,'feature space calculations complete.')
                close(f_waitbar)
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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

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
        [indx,tf] = listdlg('PromptString',['Select the metrics to use for the classification'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        if ~isempty(indx)
            f_waitbar = waitbar(0,'Preparing metrics for classification...','WindowStyle','modal');
            X = cell2mat(cellfun(@(X) cell_metrics.(X),list_tSNE_metrics(indx),'UniformOutput',false));
            UI.settings.classification_metrics = list_tSNE_metrics(indx);
            
            X(isnan(X) | isinf(X)) = 0;
            waitbar(0.1,f_waitbar,'Calculating tSNE space...')
            
            % Hierarchical Clustering
            eucD = pdist(X','euclidean');
            clustTreeEuc = linkage(X','average');
            cophenet(clustTreeEuc,eucD);
                        
            % K nearest neighbor clustering
            % Mdl = fitcknn(X',cell_metrics.putativeCellType,'NumNeighbors',5,'Standardize',1);

            % UMAP visualization
            % tSNE_metrics.plot = run_umap(X');
            
            waitbar(1,f_waitbar,'Classification calculations complete.')
            if ishandle(f_waitbar)
                close(f_waitbar)
            end
            figure,
            [h,nodes] = dendrogram(clustTreeEuc,0); title('Hierarchical Clustering')
            h_gca = gca;
            h_gca.TickDir = 'out';
            h_gca.TickLength = [.002 0];
            h_gca.XTickLabel = [];
            
            MsgLog('Classification space calculations complete.');
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function buttonPosition = getButtonLayout(parentPanelName,buttonLabels)
        rows = max(ceil(length(buttonLabels)/2),3);
        positionToogleButtons = getpixelposition(parentPanelName);
        positionToogleButtons = [positionToogleButtons(3)/2,(positionToogleButtons(4)-0.03)/rows];
        for i = 1:max(length(buttonLabels),6)
            buttonPosition{i} = [(1.04-mod(i,2))*positionToogleButtons(1),0.05+(rows-ceil(i/2))*positionToogleButtons(2),positionToogleButtons(1),positionToogleButtons(2)];
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function saveStateToHistory(cellIDs)
        UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
        hist_idx = size(history_classification,2)+1;
        history_classification(hist_idx).cellIDs = cellIDs;
        history_classification(hist_idx).cellTypes = clusClas(cellIDs);
        history_classification(hist_idx).deepSuperficial = cell_metrics.deepSuperficial{cellIDs};
        history_classification(hist_idx).brainRegion = cell_metrics.brainRegion{cellIDs};
        history_classification(hist_idx).labels = cell_metrics.labels{cellIDs};
        history_classification(hist_idx).tags = cell_metrics.tags{cellIDs};
        history_classification(hist_idx).deepSuperficial_num = cell_metrics.deepSuperficial_num(cellIDs);
        history_classification(hist_idx).deepSuperficialDistance = cell_metrics.deepSuperficialDistance(cellIDs);
        history_classification(hist_idx).groundTruthClassification = cell_metrics.groundTruthClassification{cellIDs};
        classificationTrackChanges = [classificationTrackChanges,cellIDs];
        if rem(hist_idx,UI.settings.autoSaveFrequency) == 0
            autoSave_Cell_metrics(cell_metrics)
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function autoSave_Cell_metrics(cell_metrics)
        cell_metrics = saveCellMetricsStruct(cell_metrics);
        assignin('base',UI.settings.autoSaveVarName,cell_metrics);
        MsgLog(['Autosaved classification changes to workspace (variable: ' UI.settings.autoSaveVarName ')']);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function listCellType
        saveStateToHistory(ii);
        clusClas(ii) = UI.listbox.cellClassification.Value;
        MsgLog(['Cell ', num2str(ii), ' classified as ', UI.settings.cellTypes{clusClas(ii)}]);
        updateCellCount
        updatePlotClas
        updatePutativeCellType
        uicontrol(UI.pushbutton.next)
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function AddNewCellType
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

% % % % % % % % % % % % % % % % % % % % % %

    function colored_string = DefineCellTypeList
        if size(UI.settings.cellTypeColors,1) < length(UI.settings.cellTypes)
            UI.settings.cellTypeColors = [UI.settings.cellTypeColors;rand(length(UI.settings.cellTypes)-size(UI.settings.cellTypeColors,1),3)];
        elseif size(UI.settings.cellTypeColors,1) > length(UI.settings.cellTypes)
            UI.settings.cellTypeColors = UI.settings.cellTypeColors(1:length(UI.settings.cellTypes),:);
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

    function buttonTags(input)
        saveStateToHistory(ii);
        if UI.togglebutton.tag(input).Value == 1
            if isempty(cell_metrics.tags{ii})
                cell_metrics.tags{ii} = {UI.settings.tags{input}};
            else
                cell_metrics.tags{ii} = [cell_metrics.tags{ii},UI.settings.tags{input}];
                %                 [cell_metrics.tags(ii),UI.settings.tags{input}];
            end
            MsgLog(['Cell ', num2str(ii), ' tag assigned: ', UI.settings.tags{input}]);
        else
            cell_metrics.tags{ii}(find(strcmp(cell_metrics.tags{ii},UI.settings.tags{input}))) = [];
            MsgLog(['Cell ', num2str(ii), ' tag removed: ', UI.settings.tags{input}]);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonTags2(input)
        dispTags(input) = UI.togglebutton.dispTags(input).Value;
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonTags3(input)
        dispTags2(input) = UI.togglebutton.dispTags2(input).Value;
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateTags
        % Updates tags
        [~,~,tagsIdxs] = intersect(cell_metrics.tags{ii},UI.settings.tags);
        for i = 1:length(UI.togglebutton.tag)
            if any(tagsIdxs==i)
                UI.togglebutton.tag(i).Value = 1;
            else
                UI.togglebutton.tag(i).Value = 0;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updatePutativeCellType
        % Updates putativeCellType field
        [C, ~, ic] = unique(clusClas,'sorted');
        for i = 1:length(C)
            cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.settings.cellTypes{C(i)}},sum(ic==i),1);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateGroundTruth
        % Updates groundTruth tags
        [~,~,tagsIdxs] = intersect(cell_metrics.groundTruthClassification{ii},UI.settings.groundTruth);
        for i = 1:length(UI.togglebutton.groundTruthClassification)
            if any(tagsIdxs==i)
                UI.togglebutton.groundTruthClassification(i).Value = 1;
            else
                UI.togglebutton.groundTruthClassification(i).Value = 0;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
            buttonGroups(1);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
        brainRegions_dialog = dialog('Position', [300, 300, 600, 350],'Name','Brain region assignment for current cell'); movegui(brainRegions_dialog,'center')
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

% % % % % % % % % % % % % % % % % % % % % %

    function plotLegends
        nLegends = -1;
        plot(0,0,'xw', 'LineWidth', 3., 'MarkerSize',18,'HitTest','off'), xlim([-0.3,2]), hold on, yticks([]), xticks([])
        plot(0,0,'xk', 'LineWidth', 1.5, 'MarkerSize',16,'HitTest','off');
        text(0.2,0,'Selected cell')
        legendNames = plotClasGroups(nanUnique(plotClas(UI.params.subset)));
        for i = 1:length(legendNames)
            plot(0,nLegends,'.','color',clr(i,:), 'MarkerSize',25)
            text(0.2,nLegends,legendNames{i})
            nLegends = nLegends - 1;
        end
        
        % Synaptic connections
        switch UI.monoSyn.disp
            case 'All'
                plot([-0.1,0.1],nLegends*[1,1],'-k','LineWidth', 2)
                text(0.2,nLegends,'All connections')
                nLegends = nLegends - 1;
            case {'Selected','Upstream','Downstream','Up & downstream'}
                if ~isempty(UI.params.inbound)
                    plot([-0.1,0.1],nLegends*[1,1],'-b','LineWidth', 2)
                    text(0.2,nLegends,'Inbound connection')
                    nLegends = nLegends - 1;
                end
                if ~isempty(UI.params.outbound)
                    plot([-0.1,0.1],nLegends*[1,1],'-m','LineWidth', 2)
                    text(0.2,nLegends,'Outbound connection')
                    nLegends = nLegends - 1;
                end
        end
        % Ground truth cell types within session
        if groundTruthSelection
            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
            for jj = 1:length(idGroundTruth)
                plot(0, nLegends,UI.settings.groundTruthMarkers{jj},'LineWidth', 1.5, 'MarkerSize',8);
                text(0.2,nLegends,UI.settings.groundTruth{idGroundTruth(jj)})
                nLegends = nLegends - 1;
            end
        end
        % Reference data
        if ~strcmp(UI.settings.referenceData, 'None') % 'Points','Image'
            idx = find(ismember(referenceData.clusClas,referenceData.selection));
            legends2plot = unique(referenceData.clusClas(idx));
            for jj = 1:length(legends2plot)
                plot(0, nLegends,'x','color',clr2(jj,:),'markersize',8);
                text(0.2,nLegends,referenceData.cellTypes{legends2plot(jj)})
                nLegends = nLegends - 1;
            end
        end
        % Ground truth data
        if ~strcmp(UI.settings.groundTruthData, 'None') % 'Points','Image'
            idx = find(ismember(groundTruthData.clusClas,groundTruthData.selection));
            legends2plot = unique(groundTruthData.clusClas(idx));
            for jj = 1:length(legends2plot)
                plot(0, nLegends,'x','color', clr3(jj,:),'markersize',8);
                text(0.2,nLegends,groundTruthData.groundTruthTypes{legends2plot(jj)})
                nLegends = nLegends - 1;
            end
        end
        % Synaptic cell types
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(0, nLegends,'^k');
            text(0.2,nLegends,'Excitatory cells')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(0, nLegends,'ok');
            text(0.2,nLegends,'Inhibitory cells')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayExcitatoryPostsynapticCells && ~isempty(cellsExcitatoryPostsynaptic_subset)
            plot(0, nLegends,'vk');
            text(0.2,nLegends,'Cells receiving excitation')
            nLegends = nLegends - 1;
        end
        if UI.settings.displayInhibitoryPostsynapticCells && ~isempty(cellsInhibitoryPostsynaptic_subset)
            plot(0, nLegends,'*k');
            text(0.2,nLegends,'Cells receiving inhibition')
            nLegends = nLegends - 1;
        end
        ylim([min(nLegends,-5),1])
    end

% % % % % % % % % % % % % % % % % % % % % %

    function plotCharacteristics(cellID)
        nLegends = 0;
        fieldname = {'cellID','UID','spikeGroup','cluID','putativeCellType','cv2','peakVoltage','animal','firingRate','troughToPeak'};
        xlim([-2,2]), hold on, yticks([]), xticks([]), 
        for i = 1:10
            text(-0.2,nLegends,fieldname{i},'HorizontalAlignment','right')
            if isnumeric(cell_metrics.(fieldname{i}))
                text(0.2,nLegends,num2str(cell_metrics.(fieldname{i})(cellID)))
            else
                text(0.2,nLegends,cell_metrics.(fieldname{i}){cellID})
            end
            nLegends = nLegends - 1;
        end
        plot([0,0],[min(nLegends,-5),0]+0.5,'k')
        ylim([min(nLegends,-5),1])
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateLegends(src,evnt)
        % Updates the legends in the Legends tab with active plot types
        if strcmp(UI.panel.tabgroup2.SelectedTab.Title,'Legends')
            axes(UI.tabs.legends,'Position',[0 0 1 1])
            plotLegends
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function advanceClass(ClasIn)
        if ~exist('ClasIn')
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

% % % % % % % % % % % % % % % % % % % % % %

    function backClass
        temp = find(plotClas(ii)==plotClas(UI.params.subset));
        temp2 = max(find(UI.params.subset(temp) < ii));
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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function buttonACG(src,event)
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

% % % % % % % % % % % % % % % % % % % % % %
    
    function buttonACG_normalize(src,event)
        if src.Position == 7
            UI.settings.isiNormalization = 'Rate';
            UI.menu.display.normalization.ops(1).Checked = 'on';
            UI.menu.display.normalization.ops(2).Checked = 'off';
            UI.menu.display.normalization.ops(3).Checked = 'off';
        elseif src.Position == 8
            UI.settings.isiNormalization = 'occurence';
            UI.menu.display.normalization.ops(1).Checked = 'off';
            UI.menu.display.normalization.ops(2).Checked = 'on';
            UI.menu.display.normalization.ops(3).Checked = 'off';
            elseif src.Position == 9
            UI.settings.isiNormalization = 'Firing rates';
            UI.menu.display.normalization.ops(1).Checked = 'off';
            UI.menu.display.normalization.ops(2).Checked = 'off';
            UI.menu.display.normalization.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function buttonMonoSyn(src,event)
        UI.menu.monoSyn.showConn.ops(1).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(2).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(3).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(4).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(5).Checked = 'off';
        UI.menu.monoSyn.showConn.ops(6).Checked = 'off';
        if src.Position == 4
            UI.monoSyn.disp = 'None';
        elseif src.Position == 5
            UI.monoSyn.disp = 'Selected';
        elseif src.Position == 6
            UI.monoSyn.disp = 'Upstream';
        elseif src.Position == 7
            UI.monoSyn.disp = 'Downstream';
        elseif src.Position == 8
            UI.monoSyn.disp = 'Up & downstream';
        elseif src.Position == 9
            UI.monoSyn.disp = 'All';
        end
        UI.menu.monoSyn.showConn.ops(src.Position-3).Checked = 'on';
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function axnum = getAxisBelowCursor
        temp1 = UI.fig.Position([3,4]);
        temp2 = UI.panel.left.Position(3);
        temp3 = UI.panel.right.Position(3);
        temp4 = get(UI.fig, 'CurrentPoint');
        if temp4(1)> temp2 & temp4(1) < (temp1(1)-temp3)
            fractionalPositionX = (temp4(1) - temp2 ) / (temp1(1)-temp3-temp2);
            fractionalPositionY = (temp4(2) - 26 ) / (temp1(2)-20-26);
            if UI.settings.layout == 1 && fractionalPositionX < 0.7
                axnum = 1;
            elseif UI.settings.layout == 1 && fractionalPositionX > 0.7
                axnum = 6-floor(fractionalPositionY*3);
            elseif UI.settings.layout == 2 && fractionalPositionY > 0.4
                axnum = ceil(fractionalPositionX*2);
            elseif UI.settings.layout == 2 && fractionalPositionY < 0.4
                axnum = ceil(fractionalPositionX*3)+3;
            elseif UI.settings.layout == 3 && fractionalPositionY > 0.5
                axnum = ceil(fractionalPositionX*3);
            elseif UI.settings.layout == 3 && fractionalPositionY < 0.5
                axnum = ceil(fractionalPositionX*3)+3;
            elseif UI.settings.layout == 4 && fractionalPositionY > 0.5
                axnum = ceil(fractionalPositionX*3);
            elseif UI.settings.layout == 4 && fractionalPositionY < 0.5
                axnum = ceil(fractionalPositionX*3)+3;
                if fractionalPositionY < 0.25 & axnum == 6
                    axnum = axnum + 1;
                end
            elseif UI.settings.layout == 5 && fractionalPositionY > 0.5
                axnum = ceil(fractionalPositionX*3);
            elseif UI.settings.layout == 5 && fractionalPositionY < 0.5
                axnum = ceil(fractionalPositionX*3)+3;
                if fractionalPositionY < 0.25 & axnum >= 5
                    axnum = axnum + 2;
                end
            elseif UI.settings.layout == 6 && fractionalPositionY > 0.66
                axnum = ceil(fractionalPositionX*3);
            elseif UI.settings.layout == 6 && fractionalPositionY > 0.33
                axnum = ceil(fractionalPositionX*3)+3;
            elseif UI.settings.layout == 6 && fractionalPositionY < 0.33
                axnum = ceil(fractionalPositionX*3)+6;
            else
                axnum = 1;
            end
        else
            axnum = [];
        end
    end

    % % % % % % % % % % % % % % % % % % % % % %

    function ScrolltoZoomInPlot(h,event,direction)
        % Called when scrolling/zooming in the cell inspector.
        % Checks first, if a plot is underneath the curser
        axnum = getAxisBelowCursor;
        if isfield(UI,'panel') & ~isempty(axnum)
            handle34 = subfig_ax(axnum);

             um_axes = get(handle34,'CurrentPoint');

            
            % If ScrolltoZoomInPlot is called by a keypress, the underlying
            % mouse position must be determined by the WindowButtonMotionFcn
            if exist('direction')
                set(gcf,'WindowButtonMotionFcn', @hoverCallback);
            end
            u = um_axes(1,1);
            v = um_axes(1,2);
            w = um_axes(1,2);
            
            axes(handle34);
            b = get(handle34,'Xlim');
            c = get(handle34,'Ylim');
            d = get(handle34,'Zlim');
            
            % Saves the initial axis limits and linear/log axis settings
            if isempty(globalZoom{axnum})
                globalZoom{axnum} = [b;c;d];
                if axnum == 1
                    globalZoomLog{axnum} = [UI.checkbox.logx.Value,UI.checkbox.logy.Value,UI.checkbox.logz.Value];
                elseif axnum == 2
                    globalZoomLog{axnum} = [0,1,0];
                else
                    globalZoomLog{axnum} = [0,0,0];
                end
            end
            zoomInFactor = 0.7;
            zoomOutFactor = 1.8;
            
            globalZoom1 = globalZoom{axnum};
            globalZoomLog1 = globalZoomLog{axnum};
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
            if ~exist('direction')
                if event.VerticalScrollCount<0
                    direction = 1;% positive scroll direction (zoom out)
                else
                    direction = -1; % Negative scroll direction (zoom in)
                end
            end
            
            applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
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
                    if y2>y1 & globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 & globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1 & globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 & globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1 & globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 & globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1 & globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 & globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                    z1 = max(globalZoom1(3,1),w-diff(d)/2*zoomInFactor);
                    z2 = min(globalZoom1(3,2),w+diff(d)/2*zoomInFactor);
                    if z2>z1 & globalZoomLog1(3)==0
%                         zlim([z1,z2]);
                    elseif z2>z1 & globalZoomLog1(3)==1
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
                    if y2>y1 & globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 & globalZoomLog1(2)==1
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
                    if x2>x1 & globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 & globalZoomLog1(1)==1
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
                    
                    if x2>x1 & globalZoomLog1(1)==0
                        xlim([x1,x2]);
                    elseif x2>x1 & globalZoomLog1(1)==1
                        xlim(10.^[x1,x2]);
                    end
                    if y2>y1 & globalZoomLog1(2)==0
                        ylim([y1,y2]);
                    elseif y2>y1 & globalZoomLog1(2)==1
                        ylim(10.^[y1,y2]);
                    end
                    if z2>z1 & globalZoomLog1(3)==0
%                         zlim([z1,z2]);
                    elseif z2>z1 & globalZoomLog1(3)==1
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

    function hoverCallback(src,evt)
            
    end

% % % % % % % % % % % % % % % % % % % % % %

    function [u,v] = ClicktoSelectFromPlot(h,~)
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
                        HighlightFromPlot(u,v);
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
                    polygon1.handle(polygon1.counter+1) = plot([polygon1.coords(:,1);polygon1.coords(1,1)],[polygon1.coords(:,2);polygon1.coords(1,2)],'.-k', 'HitTest','off');
                end
                if polygon1.counter > 0
                    polygon1.cleanExit = 1;
                end
                clickPlotRegular = true;
                set(UI.fig,'Pointer','arrow')
                GroupSelectFromPlot
                set(polygon1.handle(find(ishandle(polygon1.handle))),'Visible','off');
                
            elseif strcmpi(sel, 'extend') & polygon1.counter > 0
                polygon1.coords = polygon1.coords(1:end-1,:);
                set(polygon1.handle(polygon1.counter),'Visible','off');
                polygon1.counter = polygon1.counter-1;
                
            elseif strcmpi(sel, 'extend') & polygon1.counter == 0
                clickPlotRegular = true;
                set(UI.fig,'Pointer','arrow')
                
            elseif strcmpi(sel, 'normal')
                polygon1.coords = [polygon1.coords;c];
                polygon1.counter = polygon1.counter +1;
                polygon1.handle(polygon1.counter) = plot(polygon1.coords(:,1),polygon1.coords(:,2),'.-k', 'HitTest','off');
            end
            
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function polygonSelection(~,~)
        clickPlotRegular = false;
        MsgLog(['Select cells by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.']);
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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %
    
    function toggleStickySelectionReset(~,~)
        UI.params.ClickedCells = [];
        uiresume(UI.fig);
    end
        
% % % % % % % % % % % % % % % % % % % % % %

    function ClicktoSelectFromTable(src, event)
        % Called when a table-cell is clicked in the table. Changes to
        % custom display according what metric is clicked. First column
        % updates x-axis and second column updates the y-axis
        
        if UI.settings.metricsTable==1 & ~isempty(event.Indices) & size(event.Indices,1) == 1
            if event.Indices(2) == 1
                UI.popupmenu.xData.Value = find(contains(fieldsMenu,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.xData);
                buttonPlotX;
            elseif event.Indices(2) == 2
                UI.popupmenu.yData.Value = find(contains(fieldsMenu,table_fieldsNames(event.Indices(1))),1);
                uicontrol(UI.popupmenu.yData);
                buttonPlotY;
            end
            
        elseif UI.settings.metricsTable==2 & ~isempty(event.Indices) & event.Indices(2) > 1 & size(event.Indices,1) == 1
            % Goes to selected cell
            ii = UI.params.subset(tableDataOrder(event.Indices(1)));
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function EditSelectFromTable(src, event)
        if any(UI.params.ClickedCells == UI.params.subset(tableDataOrder(event.Indices(1))))
            UI.params.ClickedCells = UI.params.ClickedCells(~(UI.params.ClickedCells == UI.params.subset(tableDataOrder(event.Indices(1)))));
        else
            UI.params.ClickedCells = [UI.params.ClickedCells,UI.params.subset(tableDataOrder(event.Indices(1)))];
        end
        if length(UI.params.ClickedCells)<11
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(UI.params.ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(UI.params.ClickedCells(1:10)),'\s+',', ')), ' ...'];
        end
    end
%

% % % % % % % % % % % % % % % % % % % % % %

    function updateTableClickedCells
        if UI.settings.metricsTable==2
            %             UI.table.Data(:,1) = {false};
            [~,ia,~] = intersect(UI.params.subset(tableDataOrder),UI.params.ClickedCells);
            UI.table.Data(ia,1) = {true};
        end
        if length(UI.params.ClickedCells)<11
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(UI.params.ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(UI.params.ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(UI.params.ClickedCells(1:10)),'\s+',', ')), ' ...'];
        end
    end


% % % % % % % % % % % % % % % % % % % % % %

    function highlightSelectedCells
        if customPlotHistograms == 0 && UI.settings.plot3axis == 1
            axes(subfig_ax(1))
            plot3(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells), plotZ(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif customPlotHistograms == 0 && UI.settings.plot3axis == 0
            axes(subfig_ax(1))
            plot(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        elseif customPlotHistograms > 0
            axes(h_scatter(1));
            plot(plotX(UI.params.ClickedCells),plotY(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        end

        axes(subfig_ax(2))
        plot(cell_metrics.troughToPeak(UI.params.ClickedCells)*1000,cell_metrics.burstIndex_Royer2012(UI.params.ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        
        axes(subfig_ax(3))
        plot(tSNE_metrics.plot(UI.params.ClickedCells,1),tSNE_metrics.plot(UI.params.ClickedCells,2),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
    end

% % % % % % % % % % % % % % % % % % % % % %

    function iii = FromPlot(u,v,highlight)
        iii = 0;
        if ~exist('highlight')
            highlight = 0;
        end
        axnum = find(ismember(subfig_ax, gca));
        if isempty(axnum)
            axnum = 1;
        end

        if axnum == 1
            if UI.checkbox.logx.Value == 1 && UI.checkbox.logy.Value == 1
                x_scale = range(log10(plotX(find(plotX>0))));
                y_scale = range(log10(plotY(plotY>0)));
                [~,idx] = min(hypot((log10(plotX(UI.params.subset))-log10(u))/x_scale,(log10(plotY(UI.params.subset))-log10(v))/y_scale));
            elseif UI.checkbox.logx.Value == 1 && UI.checkbox.logy.Value == 0
                x_scale = range(log10(plotX(find(plotX>0))));
                y_scale = range(plotY);
                [~,idx] = min(hypot((log10(plotX(UI.params.subset))-log10(u))/x_scale,(plotY(UI.params.subset)-v)/y_scale));
            elseif UI.checkbox.logx.Value == 0 && UI.checkbox.logy.Value == 1
                x_scale = range(plotX);
                y_scale = range(log10(plotY(find(plotY>0))));
                [~,idx] = min(hypot((plotX(UI.params.subset)-u)/x_scale,(log10(plotY(UI.params.subset))-log10(v))/y_scale));
            else
                x_scale = range(plotX);
                y_scale = range(plotY);
                [~,idx] = min(hypot((plotX(UI.params.subset)-u)/x_scale,(plotY(UI.params.subset)-v)/y_scale));
            end
            iii = UI.params.subset(idx);
            if highlight
                text(plotX(iii),plotY(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
            end
            
        elseif axnum == 2
            
            x_scale = range(cell_metrics.troughToPeak)*1000;
            y_scale = range(log10(cell_metrics.burstIndex_Royer2012(find(cell_metrics.burstIndex_Royer2012>0 & cell_metrics.burstIndex_Royer2012<Inf))));
            [~,idx] = min(hypot((cell_metrics.troughToPeak(UI.params.subset)*1000-u)/x_scale,(log10(cell_metrics.burstIndex_Royer2012(UI.params.subset))-log10(v))/y_scale));
            iii = UI.params.subset(idx);
            
            if highlight
                text(cell_metrics.troughToPeak(iii)*1000,cell_metrics.burstIndex_Royer2012(iii),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
            end
            
        elseif axnum == 3
            
            [~,idx] = min(hypot(tSNE_metrics.plot(UI.params.subset,1)-u,tSNE_metrics.plot(UI.params.subset,2)-v));
            iii = UI.params.subset(idx);
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
                case 'Waveforms (tSNE)'
                    
                    [~,idx] = min(hypot(tSNE_metrics.filtWaveform(UI.params.subset,1)-u,tSNE_metrics.filtWaveform(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.filtWaveform(iii,1),tSNE_metrics.filtWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'Raw waveforms (tSNE)'
                    
                    [~,idx] = min(hypot(tSNE_metrics.rawWaveform(UI.params.subset,1)-u,tSNE_metrics.rawWaveform(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.rawWaveform(iii,1),tSNE_metrics.rawWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'Waveforms (all)'
                    
                    x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.filt_zscored(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
%                     [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(time_waveforms_zscored)))+1;
                    iii = UI.params.subset(In);
                    [~,time_index] = min(abs(time_waveforms_zscored-u));
                    if highlight
                        plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'Raw waveforms (all)'
                    
                    x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.waveforms.raw_zscored(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
%                     [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(time_waveforms_zscored)))+1;
                    iii = UI.params.subset(In);
                    [~,time_index] = min(abs(time_waveforms_zscored-u));
                    if highlight
                        plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'Waveforms (image)'
                    
                    [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(troughToPeakSorted(round(v)));
                        if highlight
                            plot([time_waveforms_zscored(1),time_waveforms_zscored(end)],[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                        end
                    end
                    
                case 'tSNE of narrow ACGs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.acg_narrow(UI.params.subset,1)-u,tSNE_metrics.acg_narrow(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_narrow(iii,1),tSNE_metrics.acg_narrow(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'tSNE of wide ACGs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.acg_wide(UI.params.subset,1)-u,tSNE_metrics.acg_wide(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_wide(iii,1),tSNE_metrics.acg_wide(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'tSNE of log ACGs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.acg_log10(UI.params.subset,1)-u,tSNE_metrics.acg_log10(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.acg_log10(iii,1),tSNE_metrics.acg_log10(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                
                case 'tSNE of log ISIs'
                    
                    [~,idx] = min(hypot(tSNE_metrics.isi_log10(UI.params.subset,1)-u,tSNE_metrics.isi_log10(UI.params.subset,2)-v));
                    iii = UI.params.subset(idx);
                    if highlight
                        text(tSNE_metrics.isi_log10(iii,1),tSNE_metrics.isi_log10(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
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
                                plot(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                                text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                            end
                        end
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
                                Xdata = general.acgs.log10([1,end]);
                            else
                                Xdata = [-500,500];
                            end
                            plot(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
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
                        plot(x2(:),y1(:,In),'linewidth',2, 'HitTest','off')
                        text(x2(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                
                case 'ISIs (all)'
                    
                    x2 = general.isis.log10;
                    x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                    if strcmp(UI.settings.isiNormalization,'Rate')
                        y1 = cell_metrics.isi.log10(:,UI.params.subset);
                    elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                        x2 = 1./general.isis.log10;
                        x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^ACGLogIntervals))';
                    else
                        y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^ACGLogIntervals))';
                    end
                    x_scale = range(log10(x1(:)));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((log10(x1(:))-log10(u))/x_scale,(y1(:)-v)/y_scale));
                    In = unique(floor(In/size(x1,1)))+1;
                    iii = UI.params.subset(In);
                    if highlight
                        [~,time_index] = min(abs(x2-u));
                        plot(x2(:),y1(:,In),'linewidth',2, 'HitTest','off')
                        text(x2(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                
                case 'ISIs (image)'
                    
                    [~,burstIndexSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(burstIndexSorted(round(v)));
                        if highlight
                            Xdata = general.isis.log10([1,end]);
                            plot(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                        end
                    end
                
                case 'responseCurves_thetaPhase (all)'
                    
                    x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
                    y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
                    x_scale = range(x1(:));
                    y_scale = range(y1(:));
                    [~,In] = min(hypot((x1(:)-u)/x_scale,(y1(:)-v)/y_scale));
%                     [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(UI.x_bins.thetaPhase)))+1;
                    iii = UI.params.subset(In);
                    [~,time_index] = min(abs(UI.x_bins.thetaPhase-u));
                    if highlight
                        plot(UI.x_bins.thetaPhase,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(UI.x_bins.thetaPhase(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'responseCurves_thetaPhase (image)'
                    
                    [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                    if round(v) > 0 && round(v) <= length(UI.params.subset)
                        iii = UI.params.subset(troughToPeakSorted(round(v)));
                        if highlight
                            plot([UI.x_bins.thetaPhase(1),UI.x_bins.thetaPhase(end)],[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                        end
                    end
                    
                otherwise
                    
                    if any(strcmp(UI.monoSyn.disp,{'All','Selected','Upstream','Downstream','Up & downstream'})) & ~isempty(subsetPlots)
                        if ~isempty(UI.params.outbound) || ~isempty(UI.params.inbound)
                            subset1 = subsetPlots.subset;
                            x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
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
    
    function exitCellExplorer(~,~)
        close(UI.fig);
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function bar_from_patch(x_data, y_data,col)
        x_data = [x_data(1),reshape([x_data,x_data([2:end,end])]',1,[]),x_data(end)];
        y_data = [0,reshape([y_data,y_data]',1,[]),0];
        patch(x_data, y_data,col,'EdgeColor','none','FaceAlpha',.8,'HitTest','off')
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function selectCellsForGroupAction(~,~)
        % Checkes if any cells have been highlighted, if not asks the user
        % to provide list of cell.
        if isempty(UI.params.ClickedCells)
            filterCells.dialog = dialog('Position',[300 300 600 495],'Name','Select cells'); movegui(filterCells.dialog,'center')
            
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
        
        function cellSelection1(src,evnt)
            if strcmpi(evnt.Key,'return')
                cellSelection
            end
            
        end
        function cellSelection
            % Filters the selected cells based on user input
            ClickedCells0 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells1 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells2 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells3 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells4 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells5 = ones(1,size(cell_metrics.troughToPeak,2));
            ClickedCells6 = ones(1,size(cell_metrics.troughToPeak,2));
            % Input field
            answer = filterCells.cellIDs.String;
            if ~isempty(answer)
                try
                    UI.params.ClickedCells = eval(['[',answer,']']);
                    UI.params.ClickedCells = UI.params.ClickedCells(ismember(UI.params.ClickedCells,1:size(cell_metrics.troughToPeak,2)));
                catch
                    MsgLog(['List of cells not formatted correctly'],2)
                end
            else
                UI.params.ClickedCells = 1:size(cell_metrics.troughToPeak,2);
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
            if ~isempty(filterCells.synConnectFilter.Value) & length(filterCells.synConnectFilter.Value) == 1
                ClickedCells6_out = findSynapticConnections(filterCells.synConnectFilter.String{filterCells.synConnectFilter.Value});
                ClickedCells6 = zeros(1,size(cell_metrics.troughToPeak,2));
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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function HighlightFromPlot(u,v)
        iii = FromPlot(u,v,1);
        if iii > 0
            UI.params.ClickedCells = unique([UI.params.ClickedCells,iii]);
            updateTableClickedCells
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
                if axnum == 1
                    
                    In = find(inpolygon(plotX(UI.params.subset), plotY(UI.params.subset), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
                elseif axnum == 2
                    
                    In = find(inpolygon(cell_metrics.troughToPeak(UI.params.subset)*1000, log10(cell_metrics.burstIndex_Royer2012(UI.params.subset)), polygon_coords(:,1), log10(polygon_coords(:,2))));
                    In = UI.params.subset(In);
                    
                elseif axnum == 3
                    
                    In = find(inpolygon(tSNE_metrics.plot(UI.params.subset,1), tSNE_metrics.plot(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                    In = UI.params.subset(In);
                    
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
                        
                        case 'Waveforms (all)'
                            x1 = time_waveforms_zscored'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.waveforms.filt_zscored(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            if ~isempty(In)
                                plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'Waveforms (image)'
                            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'Waveforms (tSNE)'
                            In = find(inpolygon(tSNE_metrics.filtWaveform(UI.params.subset,1), tSNE_metrics.filtWaveform(UI.params.subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = UI.params.subset(In);
                            
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
                                plot(x1(:,In),y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'ISIs (all)'
                            x1 = (general.isis.log10)*ones(1,length(UI.params.subset));
                            if strcmp(UI.settings.isiNormalization,'Rate')
                                y1 = cell_metrics.isi.log10(:,UI.params.subset);
                            elseif strcmp(UI.settings.isiNormalization,'Firing rates')
                                x1 = (1./general.isis.log10)*ones(1,length(UI.params.subset));
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^ACGLogIntervals))';
                            else
                                y1 = cell_metrics.isi.log10(:,UI.params.subset).*(diff(10.^ACGLogIntervals))';
                            end
                            
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            if ~isempty(In)
                                plot(x1(:,In),y1(:,In),'linewidth',2, 'HitTest','off')
                            end
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
                                                
                        case 'responseCurves_thetaPhase (all)'
                            x1 = UI.x_bins.thetaPhase'*ones(1,length(UI.params.subset));
                            y1 = cell_metrics.responseCurves.thetaPhase_zscored(:,UI.params.subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(UI.x_bins.thetaPhase)))+1;
                            if ~isempty(In)
                                plot(UI.x_bins.thetaPhase,y1(:,In),'linewidth',2, 'HitTest','off')
                            end
                            In = UI.params.subset(In);
                            
                        case 'responseCurves_thetaPhase (image)'
                            [~,troughToPeakSorted] = sort(cell_metrics.(UI.settings.sortingMetric)(UI.params.subset));
                            In = UI.params.subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        otherwise
                            if any(strcmp(UI.monoSyn.disp,{'All','Selected','Upstream','Downstream','Up & downstream'}))
                                if (~isempty(UI.params.outbound) || ~isempty(UI.params.inbound)) & ~isempty(subsetPlots)
                                    subset1 = subsetPlots.subset;
                                    x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                                    y1 = subsetPlots.yaxis;
                                    
                                    In2 = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                    In2 = unique(floor(In2/length(subsetPlots.xaxis)))+1;
                                    In = subset1(In2);
                                    if ~isempty(In2)
                                        plot(x1(:,1),y1(:,In2),'linewidth',2, 'HitTest','off')
                                    end
                                end
                            end
                    end
                end
                
                if length(In)>0 && any(axnum == [1,2,3,4,5,6,7,8,9])
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

% % % % % % % % % % % % % % % % % % % % % %

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
                plotClas11 = cell_metrics.(colorStr{Colorval});
                if iscell(plotClas11)
                    plotClas11 = findgroups(plotClas11);
                end
            else
                plotClas = clusClas;
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateTableColumnWidth
        % Updating table column width
        if UI.settings.metricsTable==1
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),150);
            UI.table.ColumnWidth = {pos1*6/10-10, pos1*4/10-10};
        elseif UI.settings.metricsTable==2
            pos1 = getpixelposition(UI.table,true);
            pos1 = max(pos1(3),150);
            UI.table.ColumnWidth = {18,pos1*2/10, pos1*6/10-38, pos1*2/10};
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonGroups(inpt)
        Colorval = UI.popupmenu.groups.Value;
        colorStr = UI.popupmenu.groups.String;
        if Colorval == 1
            clasLegend = 0;
            UI.listbox.groups.Visible = 'Off';
            UI.checkbox.groups.Visible = 'Off';
            plotClas = clusClas;
            UI.checkbox.groups.Value = 0;
            plotClasGroups = UI.settings.cellTypes;
        else
            clasLegend = 1;
            UI.listbox.groups.Visible = 'On';
            UI.checkbox.groups.Visible = 'On';
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
    
    function setTableDataSorting(src,event)
        if isfield(src,'Text')
            tableDataSortBy = src.Text;
        else
            tableDataSortBy = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.sortingList(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataSortBy,UI.settings.tableDataSortingList));
        UI.menu.tableData.sortingList(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            updateCellTableData
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function plotSummaryFigures
        UI.params.subset = 1:length(cell_metrics.cellID);
        if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
            putativeSubset = find(sum(ismember(cell_metrics.putativeConnections.excitatory,UI.params.subset)')==2);
        else
            putativeSubset=[];
        end
        clr = UI.settings.cellTypeColors(intersect(classes2plot,plotClas(UI.params.subset)),:);
        classes2plotSubset = unique(plotClas);
        [plotRows,~]= numSubplots(length(plotOptions)+3);
        cellIDs = 1:length(cell_metrics.cellID);
        for j = 1:length(cellIDs)
            if UI.BatchMode
                batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                general1 = cell_metrics.general.batch{batchIDs1};
                savePath1 = cell_metrics.general.path{batchIDs1};
            else
                general1 = cell_metrics.general;
                batchIDs1 = 1;
                savePath1 = cell_metrics.general.path;
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
            fig = figure('Name',['Cell Explorer: cell ', num2str(cellIDs(j))],'NumberTitle','off','pos',UI.settings.figureSize);
            if ispc
                ha = tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
            else
                ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.12 .06],[.06 .05]);
            end
            axes(ha(1)), hold on
            
            % Scatter plot with t-SNE metrics
            plotGroupScatter(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2)), axis tight
            xlabel('t-SNE'), ylabel('t-SNE')
            
            % Plots: putative connections
            if plotConnections(3) == 1
                plotPutativeConnections(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)')
            end
            % Plots: X marker for selected cell
            plotMarker(tSNE_metrics.plot(cellIDs(j),1),tSNE_metrics.plot(cellIDs(j),2))
            
            % Plots: tagget ground-truth cell types
            plotGroudhTruthCells(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2))
            
            for jj = 1:length(plotOptions)
                axes(ha(jj+1)); hold on
                customPlot(plotOptions{jj},cellIDs(j),general1,batchIDs1);
                if jj == 1
                    ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                end
            end
            axes(ha(length(plotOptions)+2));  hold on
            plotLegends, title('Legends')
            
            axes(ha(length(plotOptions)+3)); hold on
            plotCharacteristics(cellIDs(j)), title('Characteristics')
            
            % Saving figure
            savefigure(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_cell_', num2str(cell_metrics.UID(cellIDs(j)))])
        end
        
        function savefigure(fig,savePathIn,fileNameIn)
            
            savePath = fullfile(savePathIn,'summaryFigures');
            if ~exist(savePath,'dir')
                mkdir(savePathIn,'summaryFigures')
            end
%             if exportPlots.popupmenu.fileFormat.Value == 1
                saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
%             else
%                 set(fig,'Units','Inches');
%                 pos = get(fig,'Position');
%                 set(fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
%                 print(fig, fullfile(savePath,[fileNameIn,'.pdf']),'-dpdf');
%             end
            
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function setColumn1_metric(src,event)
        if isfield(src,'Text')
            tableDataColumn1 = src.Text;
        else
            tableDataColumn1 = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.column1_ops(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataColumn1,UI.settings.tableDataSortingList));
        UI.menu.tableData.column1_ops(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            UI.table.ColumnName = {'','#',tableDataColumn1,tableDataColumn2};
            updateCellTableData
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function setColumn2_metric(src,event)
        if isfield(src,'Text')
            tableDataColumn2 = src.Text;
        else
            tableDataColumn2 = src.Label;
        end
        for i = 1:length(UI.settings.tableDataSortingList)
            UI.menu.tableData.column2_ops(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataColumn2,UI.settings.tableDataSortingList));
        UI.menu.tableData.column2_ops(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            UI.table.ColumnName = {'','#',tableDataColumn1,tableDataColumn2};
            updateCellTableData
        end
    end

% % % % % % % % % % % % % % % % % % % % % %
    
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

% % % % % % % % % % % % % % % % % % % % % %

    function buttonShowMetrics(src,event)
        
        if exist('src')
            if isfield(src,'Text')
                text1 = src.Text;
            else
                text1 = src.Label;
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
            UI.table.Data = [table_fieldsNames,table_metrics(ii,:)'];
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

% % % % % % % % % % % % % % % % % % % % % % %

    function updateCellTableData
        dataTable = {};
        column1 = cell_metrics.(tableDataColumn1)(UI.params.subset)';
        column2 = cell_metrics.(tableDataColumn2)(UI.params.subset)';
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
        if ~strcmp(tableDataSortBy,'cellID')
            [~,tableDataOrder] = sort(cell_metrics.(tableDataSortBy)(UI.params.subset));
            UI.table.Data = dataTable(tableDataOrder,:);
        else
            tableDataOrder = 1:length(UI.params.subset);
            UI.table.Data = dataTable;
        end
        else
            UI.table.Data = {};
        end
    end
    
% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc
        customCellPlot3 = plotOptions{UI.popupmenu.customplot3.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc2
        customCellPlot4 = plotOptions{UI.popupmenu.customplot4.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc3
        customCellPlot5 = plotOptions{UI.popupmenu.customplot5.Value};
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % % %

    function customCellPlotFunc4
        customCellPlot6 = plotOptions{UI.popupmenu.customplot6.Value};
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

% % % % % % % % % % % % % % % % % % % % % %

    function goToCell(~,~)
        if UI.BatchMode
            choice = '';
            GoTo_dialog = dialog('Position', [300, 300, 300, 350],'Name','Go to cell'); movegui(GoTo_dialog,'center')
            
            sessionCount = histc(cell_metrics.batchIDs,[1:length(cell_metrics.general.basenames)]);
            sessionCount = cellstr(num2str(sessionCount'))';
            sessionEnumerator = cellstr(num2str([1:length(cell_metrics.general.basenames)]'))';
            sessionList = strcat(sessionEnumerator,{'.  '},cell_metrics.general.basenames,' (',sessionCount,')');
            
            brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', sessionList, 'Position', [10, 50, 280, 220],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog);
            if cell_metrics.batchIDs(ii)>0 & cell_metrics.batchIDs(ii)<=length(sessionList)
                brainRegionsList.Value = cell_metrics.batchIDs(ii);
            end
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
        % dialog menu for creating group actions, including classification
        % and plots summaries.
        cellIDs = unique(cellIDs);
        highlightSelectedCells
        choice = '';
        GoTo_dialog = dialog('Position', [0, 0, 300, 350],'Name','Select action'); movegui(GoTo_dialog,'center')
        
        actionList = strcat([{'---------------- Assignments -----------------','Assign existing cell-type','Assign new cell-type','Assign label','Assign deep/superficial','Assign tag','-------------------- CCGs ---------------------','CCGs ','CCGs (only with selected cell)','----------- MULTI PLOT OPTIONS ----------','Row-wise plots (5 cells per figure)','Plot-on-top (one figure for all cells)','Dedicated figures (one figure per cell)','--------------- SINGLE PLOTS ---------------'},plotOptions']);
        brainRegionsList = uicontrol('Parent',GoTo_dialog,'Style', 'ListBox', 'String', actionList, 'Position', [10, 50, 280, 270],'Value',1,'Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)CloseGoTo_dialog(cellIDs));
        uicontrol('Parent',GoTo_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)CancelGoTo_dialog);
        uicontrol('Parent',GoTo_dialog,'Style', 'text', 'String', ['Select the action to perform on the ', num2str(length(cellIDs)) ,' selected cells'], 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(brainRegionsList)
        uiwait(GoTo_dialog);
        
        function  CloseGoTo_dialog(cellIDs)
            choice = brainRegionsList.Value;
            MsgLog(['Action selected: ' actionList{choice} ' for ' num2str(length(cellIDs)) ' cells']);
            if any(choice == [2:6,8:9,11:13,15:length(actionList)])
                delete(GoTo_dialog);
                
                if choice == 2
                    [selectedClas,tf] = listdlg('PromptString',['Assign cell-type to ' num2str(length(cellIDs)) ' cells'],'ListString',colored_string,'SelectionMode','single','ListSize',[200,150]);
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
                        %                     classificationTrackChanges = [classificationTrackChanges,ii];
                        updatePlotClas
                        updateCount
                        buttonGroups(1);
                        uiresume(UI.fig);
                    end
                    
                elseif choice == 5
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
                    
                elseif choice == 6
                    % Assign tags
                    [selectedTag,tf] = listdlg('PromptString',['Assign tag to ' num2str(length(cellIDs)) ' cells'],'ListString', UI.settings.tags,'SelectionMode','single','ListSize',[200,150]);
                    if ~isempty(selectedTag)
                        saveStateToHistory(cellIDs)
                        for j = 1:length(cellIDs)
                            if isempty(cell_metrics.tags{j})
                                cell_metrics.tags{j} = {UI.settings.tags{selectedTag}};
                            elseif any(strcmp(cell_metrics.tags{j}, UI.settings.tags{selectedTag}))
                                disp(['Tag already assigned to cell ' num2str(j)]);
                            else
                                cell_metrics.tags{j} = [cell_metrics.tags{j},UI.settings.tags{selectedTag}];
                            end
                        end
                        updateTags
                        MsgLog([num2str(length(cellIDs)), ' cells assigned tag: ', UI.settings.tags{selectedTag}]);
                    end
                    
                elseif choice == 8
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
                        ccgFigure = figure('Name',['Cell Explorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize,'visible','off');
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        ha = tight_subplot(length(plot_cells),length(plot_cells),[.03 .03],[.12 .05],[.06 .05]);
                        for j = 1:length(plot_cells)
                            for jj = 1:length(plot_cells)
                                axes(ha(k));
                                if jj == j
                                    col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                                    bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),col1)
                                    %                                 bar(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),1,'FaceColor',col1,'EdgeColor',col1),
                                    title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j))) ]),
                                    xlabel(cell_metrics.putativeCellType{plot_cells(j)})
                                else
                                    bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),[0.5,0.5,0.5])
                                    %                                 bar(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),1,'FaceColor',[0.5,0.5,0.5],'EdgeColor',[0.5,0.5,0.5]),
                                end
                                if j == length(plot_cells) & mod(jj,2) == 1 & j~=jj; xlabel('Time (ms)'); end
                                if jj == 1 && mod(j,2) == 0; ylabel('Rate (Hz)'); end
                                if length(plot_cells)<7
                                    xticks([-50:10:50])
                                end
                                xlim([-50,50])
                                if length(plot_cells) > 2 & j < length(plot_cells)
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
                    
                elseif choice == 9
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
                        figure('Name',['Cell Explorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize)
                        
                        plot_cells2 = cell_metrics.UID(plot_cells);
                        k = 1;
                        [plotRows,~]= numSubplots(length(plot_cells));
                        ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                        for j = 2:length(plot_cells)
                            axes(ha(k));
                            col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                            bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(1)),col1)
                            if UI.monoSyn.dispHollowGauss && j > 1
                                [ ~,pred] = ce_cch_conv(general.ccg(:,plot_cells2(j),plot_cells2(1)),20); hold on
                                nBonf = round(.004/0.0005)*2;
                                hiBound=poissinv(1-0.001/nBonf,pred);
                                plot(general.ccg_time*1000,pred,'-k',general.ccg_time*1000,hiBound,'-r')
                                %                             plot()
                            end
                            
                            title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j))),' (cluID ',num2str(cell_metrics.cluID(plot_cells(j))),')']),
                            xlabel(cell_metrics.putativeCellType{plot_cells(j)}), grid on
                            if mod(j,plotRows(2))==1; ylabel('Rate (Hz)'); end
                            xticks([-50:10:50])
                            xlim([-50,50])
                            if length(plot_cells) > 2 & j <= plotRows(2)
                                set(ha(k),'XTickLabel',[]);
                            end
                            axis tight, grid on
                            set(ha(k), 'Layer', 'top')
                            k = k+1;
                        end
                    else
                        MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                    end
                elseif any(choice == [11,12,13])
                    % Multiple plots
                    % Creates summary figures and saves them to
                    % '/summaryFigures' or a custom path
                    exportPlots.dialog = dialog('Position', [300, 300, 300, 370],'Name','Multiple plots','WindowStyle','modal', 'resize', 'on' ); movegui(exportPlots.dialog,'center')
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[5, 350, 290, 20],'Units','normalized','String','Select plots to export','HorizontalAlignment','center','Units','normalized');
                    %                     [selectedActions,tf] = listdlg('PromptString',['Plot actions to perform on ' num2str(length(cellIDs)) ' cells'],'ListString',plotOptions','SelectionMode','Multiple','ListSize',[300,350]);
                    exportPlots.popupmenu.plotList = uicontrol('Parent',exportPlots.dialog,'Style','listbox','Position',[5, 110, 290, 245],'Units','normalized','String',plotOptions,'HorizontalAlignment','left','Units','normalized','min',1,'max',100);
                    exportPlots.popupmenu.saveFigures = uicontrol('Parent',exportPlots.dialog,'Style','checkbox','Position',[5, 80, 240, 25],'Units','normalized','String','Save figures','HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[5, 62, 140, 20],'Units','normalized','String','File format','HorizontalAlignment','center','Units','normalized');
                    exportPlots.popupmenu.fileFormat = uicontrol('Parent',exportPlots.dialog,'Style','popupmenu','Position',[5, 40, 140, 25],'Units','normalized','String',{'png','pdf'},'HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','text','Position',[155, 62, 140, 20],'Units','normalized','String','File path','HorizontalAlignment','center','Units','normalized');
                    exportPlots.popupmenu.savePath = uicontrol('Parent',exportPlots.dialog,'Style','popupmenu','Position',[155, 40, 140, 25],'Units','normalized','String',{'Clustering path','Cell Explorer','Define path'},'HorizontalAlignment','left','Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[5, 5, 140, 30],'String','OK','Callback',@ClosePlot_dialog,'Units','normalized');
                    uicontrol('Parent',exportPlots.dialog,'Style','pushbutton','Position',[155, 5, 140, 30],'String','Cancel','Callback',@(src,evnt)CancelPlot_dialog,'Units','normalized');
                    
                elseif choice > 14
                    % Plots any custom plot for selected cells in a single new figure with subplots
                    figure('Name',['Cell Explorer: ',actionList{choice},' for selected cells: ', num2str(cellIDs)],'NumberTitle','off','pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01])
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
                        [plotRows,~]= numSubplots(length(cellIDs));
                        subplot(plotRows(1),plotRows(2),j), hold on
                        customPlot(actionList{choice},cellIDs(j),general1,batchIDs1); title(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                    end
                else
                    uiresume(UI.fig);
                end
            end
            function CancelPlot_dialog
                % Closes the dialog
                delete(exportPlots.dialog);
            end
            
            function ClosePlot_dialog(src,evnt)
                selectedActions = exportPlots.popupmenu.plotList.Value;
                if choice == 11 && ~isempty(selectedActions)
                    % Displayes a new dialog where a number of plot can be
                    % combined and plotted for the highlighted cells
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
                            subplot_advanced(plot_columns,length(selectedActions),j,jj,mod(j ,5),['Cell Explorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells']); hold on
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1);
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                            end
                            if (mod(j,5)==0 || j == length(cellIDs)) && jj == length(selectedActions)
                                savefigure(gcf,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_MultipleCells_', num2str(nPlots)])
                                nPlots = nPlots+1;
                            end
                        end
                    end
                    
                elseif choice == 12 && ~isempty(selectedActions)
                    
                    plot_columns = min([length(cellIDs),5]);
                    fig = figure('name',['Cell Explorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01]);
                    [plotRows,~]= numSubplots(length(selectedActions));
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
                            subplot(plotRows(1),plotRows(2),jjj), hold on
                            customPlot(plotOptions{selectedActions(jjj)},cellIDs(j),general1,batchIDs1);
                            title(plotOptions{selectedActions(jjj)},'Interpreter', 'none')
                        end
                    end
                    savefigure(fig,savePath1,['CellExplorer_Cells_', num2str(cell_metrics.UID(cellIDs),'%d_')])
                    
                elseif choice == 13 && ~isempty(selectedActions)
                    
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
                        fig = figure('Name',['Cell Explorer: cell ', num2str(cellIDs(j))],'NumberTitle','off','pos',UI.settings.figureSize);
                        if ispc
                            ha = tight_subplot(plotRows(1),plotRows(2),[.08 .04],[.05 .05],[.05 .05]);
                        else
                            ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.05 .03],[.04 .03]);
                        end
                                                
                        axes(ha(1)); hold on
                        % Scatter plot with t-SNE metrics
                        plotGroupScatter(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2)), axis tight
                        xlabel('t-SNE'), ylabel('t-SNE')
                        
                        % Plots: putative connections
                        if plotConnections(3) == 1
                            plotPutativeConnections(tSNE_metrics.plot(:,1)',tSNE_metrics.plot(:,2)')
                        end
                        % Plots: X marker for selected cell
                        plotMarker(tSNE_metrics.plot(cellIDs(j),1),tSNE_metrics.plot(cellIDs(j),2))
                        % Plots: tagget ground-truth cell types
                        plotGroudhTruthCells(tSNE_metrics.plot(:,1),tSNE_metrics.plot(:,2))
                        
                        for jj = 1:length(selectedActions)
                            axes(ha(jj+1)); hold on
                            customPlot(plotOptions{selectedActions(jj)},cellIDs(j),general1,batchIDs1);
                            if jj == 1
                                ylabel(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                            end
                        end
                        axes(ha(length(selectedActions)+2))
                        plotLegends, title('Legends')
                        
                        axes(ha(length(selectedActions)+3))
                        plotCharacteristics(cellIDs(j)), title('Characteristics')
                        
                        % Saving figure
                        savefigure(fig,savePath1,[cell_metrics.sessionName{cellIDs(j)},'.CellExplorer_cell_', num2str(cell_metrics.UID(cellIDs(j)))])
                        
                    end
                end
                
                delete(exportPlots.dialog);
                
                function savefigure(fig,savePathIn,fileNameIn)
                    if exportPlots.popupmenu.saveFigures.Value == 1
                        if exportPlots.popupmenu.savePath.Value == 1
                            savePath = fullfile(savePathIn,'summaryFigures');
                            if ~exist(savePath,'dir')
                                mkdir(dirName,'summaryFigures')
                            end
                        elseif exportPlots.popupmenu.savePath.Value == 2
                            [dirName,~,~] = fileparts(which('CellExplorer.m'));
                            savePath = fullfile(dirName,'summaryFigures');
                            if ~exist(savePath,'dir')
                                mkdir(dirName,'summaryFigures')
                            end
                        elseif exportPlots.popupmenu.savePath.Value == 3
                            if ~exist('dirName','var')
                                dirName = uigetdir;
                            end
                            savePath = dirName;
                        end
                        if exportPlots.popupmenu.fileFormat.Value == 1
                            saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
                        else
                            set(fig,'Units','Inches');
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

% % % % % % % % % % % % % % % % % % % % % %

    function LoadPreferences(~,~)
        % Opens the preference .m file in matlab.
        answer = questdlg('Settings are stored in CellExplorer_Preferences.m. Click Yes to load preferences.', 'Preferences', 'Yes','Cancel','Yes');
        if strcmp(answer,'Yes')
            MsgLog(['Opening settings file']);
            edit CellExplorer_Preferences.m
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function reclassify_celltypes(~,~)
        % Reclassify all cells according to the initial algorithm
        answer = questdlg('Are you sure you want to reclassify all your cells?', 'Reclassification', 'Yes','Cancel','Cancel');
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
                updatePutativeCellType
                uiresume(UI.fig);
                MsgLog(['Succesfully reclassified cells'],2);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function undoClassification(~,~)
        % Undoes the most recent classification within 3 categories: cell-type
        % deep/superficial and brain region. Labels are left untouched.
        % Updates GUI to reflect the changes
        if size(history_classification,2) > 1
            clusClas(history_classification(end).cellIDs) = history_classification(end).cellTypes;
            cell_metrics.deepSuperficial(history_classification(end).cellIDs) = cellstr(history_classification(end).deepSuperficial);
            cell_metrics.labels(history_classification(end).cellIDs) = cellstr(history_classification(end).labels);
            cell_metrics.tags{history_classification(end).cellIDs} = cellstr(history_classification(end).tags);
            cell_metrics.brainRegion(history_classification(end).cellIDs) = cellstr(history_classification(end).brainRegion);
            cell_metrics.deepSuperficial_num(history_classification(end).cellIDs) = history_classification(end).deepSuperficial_num;
            cell_metrics.deepSuperficialDistance(history_classification(end).cellIDs) = history_classification(end).deepSuperficialDistance;
            cell_metrics.groundTruthClassification{history_classification(end).cellIDs} = cellstr(history_classification(end).groundTruthClassification);
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
            MsgLog(['All steps has been undone. No further history track available'],2);
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateCellCount
        % Updates the cell count in the cell-type listbox
        cell_class_count = histc(clusClas,[1:length(UI.settings.cellTypes)]);
        cell_class_count = cellstr(num2str(cell_class_count'))';
        UI.listbox.cellTypes.String = strcat(UI.settings.cellTypes,' (',cell_class_count,')');
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

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
                if length(unique(cell_metrics.spikeSortingID)) > 1
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

% % % % % % % % % % % % % % % % % % % % % %

    function cell_metrics = saveCellMetricsStruct(cell_metrics)
        % Prepares the cell_metrics structure for saving generated info,
        % including putative cell-type, tSNE and classificationTrackChanges
        numeric_fields = fieldnames(cell_metrics);
        cell_metrics = rmfield(cell_metrics,{numeric_fields{find(contains(numeric_fields,'_num'))}});
        updatePutativeCellType
        
%         cell_metrics.general.SWR_batch = SWR_batch;
        cell_metrics.general.tSNE_metrics = tSNE_metrics;
        cell_metrics.general.classificationTrackChanges = classificationTrackChanges;
    end

% % % % % % % % % % % % % % % % % % % % % %

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
            cell_metricsTemp = cell_metrics; %clear cell_metrics
            f_waitbar = waitbar(0,[num2str(sessionWithChanges),' sessions with changes'],'name','Saving cell metrics from batch','WindowStyle','modal');
            errorSaving = [];
            for j = 1:length(sessionWithChanges)
                if ~ishandle(f_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                waitbar(j/length(sessionWithChanges),f_waitbar,['Session ' num2str(j),'/',num2str(length(sessionWithChanges)),': ', cell_metricsTemp.general.basenames{sessionID}])
                
                
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
                        cell_metrics.tags = cell_metricsTemp.tags(cellSubset);
                        cell_metrics.deepSuperficial = cell_metricsTemp.deepSuperficial(cellSubset);
                        cell_metrics.deepSuperficialDistance = cell_metricsTemp.deepSuperficialDistance(cellSubset);
                        cell_metrics.brainRegion = cell_metricsTemp.brainRegion(cellSubset);
                        cell_metrics.putativeCellType = cell_metricsTemp.putativeCellType(cellSubset);
                        cell_metrics.groundTruthClassification = cell_metricsTemp.groundTruthClassification(cellSubset);
                        matFileCell_metrics.cell_metrics = cell_metrics;
                    end
                    errorSaving(j) = 0;
                catch
                    MsgLog(['Error saving metrics for session: ' cell_metricsTemp.general.basenames{sessionID}],4);
                    errorSaving(j) = 1;
                end
            end
            if ishandle(f_waitbar) && all(errorSaving==0)
                close(f_waitbar)
                classificationTrackChanges = [];
                UI.menu.file.save.ForegroundColor = 'k';
                MsgLog(['Classifications succesfully saved to existing cell metrics files'],[1,2]);
            else
                MsgLog('Metrics were not succesfully saved for all sessions in batch',4);
            end
        else
            if exist(cell_metrics.general.path,'dir')
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
    
    % % % % % % % % % % % % % % % % % % % % % %

    function SignificanceMetricsMatrix(~,~)
        % Performs a KS-test for selected two groups and displays a colored
        % matrix with significance levels for relevant metrics
        
        if length(unique(plotClas(UI.params.subset)))==2
            % Cell metrics differences
            cell_metrics_effects = [];
            cell_metrics_effects2 = [];
            temp = fieldnames(cell_metrics);
            temp3 = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
            subindex = intersect(find(~contains(temp3',{'cell','struct'})), find(~contains(temp,{'truePositive','falsePositive','putativeConnections','acg','acg2','spatialCoherence','_num','optoPSTH','FiringRateMap','firingRateMapStates','firingRateMap','filtWaveform_zscored','filtWaveform','filtWaveform_std','cellID','spikeSortingID','Promoter'})));
            plotClas_subset = plotClas(UI.params.subset);
            ids = nanUnique(plotClas_subset);
            
            temp1 = UI.params.subset(find(plotClas_subset==ids(1)));
            temp2 = UI.params.subset(find(plotClas_subset==ids(2)));
            testset = plotClasGroups(nanUnique(plotClas_subset));
%             if UI.checkbox.groups.Value == 0
%                 testset = plotClasGroups(UI.listbox.groups.Value);
%                 temp1 = intersect(find(strcmp(cell_metrics.(UI.popupmenu.groups.String{UI.popupmenu.groups.Value}),testset{1})),UI.params.subset);
%                 temp2 = intersect(find(strcmp(cell_metrics.(UI.popupmenu.groups.String{UI.popupmenu.groups.Value}),testset{2})),UI.params.subset);
%             else
%                 testset = plotClasGroups(UI.listbox.cellTypes.Value);
%                 temp1 = intersect(find(strcmp(cell_metrics.putativeCellType,testset{1})),UI.params.subset);
%                 temp2 = intersect(find(strcmp(cell_metrics.putativeCellType,testset{2})),UI.params.subset);
%             end
            [labels2,I]= sort(temp(subindex));
            for j = 1:length(subindex)
                fieldName = labels2{j};
                if sum(isnan(cell_metrics.(fieldName)(temp1))) < length(temp1) && sum(isnan(cell_metrics.(fieldName)(temp2))) < length(temp2)
                    [h,p] = kstest2(cell_metrics.(fieldName)(temp1),cell_metrics.(fieldName)(temp2));
                    cell_metrics_effects(j)= p;
                    cell_metrics_effects2(j)= h;
                else
                    cell_metrics_effects(j)= 1;
                    cell_metrics_effects2(j)= 0;
                end
            end
            
            image2 = log10(cell_metrics_effects);
            image2( intersect(find(~cell_metrics_effects2), find(image2<log10(0.05))) ) = -image2( intersect(find(~cell_metrics_effects2(:)), find(image2<log10(0.05))));
            
            figure('pos',[10 10 300 800],'DefaultAxesLooseInset',[.01,.01,.01,.01])
            imagesc(image2'),colormap(jet),colorbar, hold on
            if any(cell_metrics_effects<0.05 & cell_metrics_effects>=0.003)
                plot(1,find(cell_metrics_effects<0.05 & cell_metrics_effects>=0.003),'*w','linewidth',1)
            end
            if sum(cell_metrics_effects<0.003)
                plot([0.9;1.1],[find(cell_metrics_effects<0.003);find(cell_metrics_effects<0.003)],'*w','linewidth',1)
            end
            yticks(1:length(subindex))
            yticklabels(labels2)
            set(gca,'TickLabelInterpreter','none')
            caxis([-3,3]);
            title([testset{1} ' vs ' testset{2}],'Interpreter', 'none'), xticks(1), xticklabels({'KS-test'})
        else
            MsgLog(['KS-test: please select a group of size two']);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function rotateFig1
        % activates a rotation mode for subfig1 while maintaining the
        % keyboard shortcuts and click functionality for the remaining
        % plots
        axes(UI.panel.subfig_ax1.Children);
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
        UI.params.ii_history = 1;
        % Initialize labels
        if ~isfield(cell_metrics, 'labels')
            cell_metrics.labels = repmat({''},1,size(cell_metrics.UID,2));
        end
        % Initialize tags
        if ~isfield(cell_metrics, 'tags')
            cell_metrics.tags = repmat({''},1,size(cell_metrics.UID,2));
        end
        dispTags = ones(size(UI.settings.tags));
        dispTags2 = zeros(size(UI.settings.tags));
        
        % Initialize ground truth classification
        if ~isfield(cell_metrics, 'groundTruthClassification')
            cell_metrics.groundTruthClassification = repmat({''},1,size(cell_metrics.UID,2));
        end
        
        % Initialize text filter
        idx_textFilter = 1:size(cell_metrics.UID,2);
        
        % Batch initialization
        if isfield(cell_metrics.general,'batch')
            UI.BatchMode = true;
        else
            UI.BatchMode = false;
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
            elseif iscell(cell_metrics.(fieldsMenuCells{i})) && size(cell_metrics.(fieldsMenuCells{i}),1) == 1 && size(cell_metrics.(fieldsMenuCells{i}),2) == size(cell_metrics.UID,2)
                cell_metrics.(fieldsMenuCells{i})(find(cell2mat(cellfun(@(X) isempty(X), cell_metrics.animal,'uni',0)))) = {''};
                [cell_metrics.([fieldsMenuCells{i},'_num']),ID] = findgroups(cell_metrics.(fieldsMenuCells{i}));
                groups_ids.([fieldsMenuCells{i},'_num']) = ID;
            end
        end
        clear fieldsMenuCells
        
        fieldsMenu = fieldnames(cell_metrics);
        fieldsMenu = fieldsMenu(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'double'));
        fieldsMenu = sort(fieldsMenu);
        fields_to_keep = [];
        for i = 1:length(fieldsMenu)
            if isnumeric(cell_metrics.(fieldsMenu{i})) && size(cell_metrics.(fieldsMenu{i}),1) == 1 && size(cell_metrics.(fieldsMenu{i}),2) == size(cell_metrics.UID,2)
                fields_to_keep(i) = 1;
            else
                fields_to_keep(i) = 0;
            end
        end
        fieldsMenu = fieldsMenu(find(fields_to_keep));
        
        % Metric table initialization
        table_metrics = {};
        
        for i = 1:size(table_fieldsNames,1)
            if isnumeric(cell_metrics.(table_fieldsNames{i})')
                table_metrics(:,i) = cellstr(num2str(cell_metrics.(table_fieldsNames{i})',5));
            else
                table_metrics(:,i) = cellstr(cell_metrics.(table_fieldsNames{i}));
            end
        end
        
        % tSNE initialization
        filtWaveform = [];
        step_size = [cellfun(@diff,cell_metrics.waveforms.time,'UniformOutput',false)];
        time_waveforms_zscored = [max(cellfun(@min, cell_metrics.waveforms.time)):min([step_size{:}]):min(cellfun(@max, cell_metrics.waveforms.time))];
        
        for i = 1:length(cell_metrics.waveforms.filt)
            filtWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.filt{i},time_waveforms_zscored,'spline',nan);
        end
        cell_metrics.waveforms.filt_zscored = (filtWaveform-nanmean(filtWaveform))./nanstd(filtWaveform);
        
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
            cell_metrics.acg.log10_occurence = normalize_range(cell_metrics.acg.log10.*diff(10.^ACGLogIntervals)');
        end

        if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10); 
            cell_metrics.isi.log10_occurence = normalize_range(cell_metrics.isi.log10.*diff(10.^ACGLogIntervals)'); 
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
            disp('Calculating tSNE space for wide ACGs')
            tSNE_metrics.acg_wide = tsne([cell_metrics.acg.wide_normalized(ceil(size(cell_metrics.acg.wide_normalized,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcNarrowAcg && ~isfield(tSNE_metrics,'acg_narrow')
            disp('Calculating tSNE space for narrow ACGs')
            tSNE_metrics.acg_narrow = tsne([cell_metrics.acg.narrow_normalized(ceil(size(cell_metrics.acg.narrow_normalized,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcLogAcg && ~isfield(tSNE_metrics,'acg_log10') && isfield(cell_metrics.acg,'log10_normalized')
            disp('Calculating tSNE space for log ACGs')
            tSNE_metrics.acg_log10 = tsne([cell_metrics.acg.log10(ceil(size(cell_metrics.acg.log10_rate,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcLogIsi && ~isfield(tSNE_metrics,'isi_log10') && isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10_normalized')
            disp('Calculating tSNE space for log ISIs')
            tSNE_metrics.isi_log10 = tsne([cell_metrics.isi.log10(ceil(size(cell_metrics.isi.log10_rate,1)/2):end,:)]','Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        
        if UI.settings.tSNE.calcFiltWaveform && ~isfield(tSNE_metrics,'filtWaveform')
            disp('Calculating tSNE space for filtered waveforms')
            X = cell_metrics.waveforms.filt_zscored';
            tSNE_metrics.filtWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
        end
        if UI.settings.tSNE.calcRawWaveform && ~isfield(tSNE_metrics,'rawWaveform') && isfield(cell_metrics.waveforms,'raw')
            disp('Calculating tSNE space for raw waveforms')
            X = cell_metrics.waveforms.raw_zscored';
            if ~isempty(find(~any(isnan(X))))
                tSNE_metrics.rawWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
            end
        end
        
        if ~isfield(tSNE_metrics,'plot')
            % disp('Calculating tSNE space for combined metrics')
            UI.settings.tSNE.metrics = intersect(UI.settings.tSNE.metrics,fieldnames(cell_metrics));
            if ~isempty(UI.settings.tSNE.metrics)
                X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.settings.tSNE.metrics,'UniformOutput',false));
                X(isnan(X) | isinf(X)) = 0;
                tSNE_metrics.plot = tsne(X','Standardize',true,'Distance',UI.settings.tSNE.dDistanceMetric,'Exaggeration',UI.settings.tSNE.exaggeration);
            end
        end
        
        % Response curves
        tempNames = fieldnames(cell_metrics.responseCurves);
        UI.x_bins.thetaPhase = [-1:0.05:1]*pi;
        UI.x_bins.thetaPhase = UI.x_bins.thetaPhase(1:end-1)+diff(UI.x_bins.thetaPhase([1,2]))/2;
        if isfield(cell_metrics.responseCurves,'thetaPhase') && (~isfield(cell_metrics.responseCurves,'thetaPhase_zscored')  || size(cell_metrics.responseCurves.thetaPhase_zscored,2) ~= length(cell_metrics.troughToPeak))
            thetaPhaseCurves = nan(length(UI.x_bins.thetaPhase),size(cell_metrics.troughToPeak,2));
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
%             cell_metrics.responseCurves.thetaPhase_zscored = thetaPhaseCurves;
            clear thetaPhaseCurves
        end
        
        % Setting initial settings for plots, popups and listboxes
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
            UI.monoSyn.disp = UI.settings.monoSynDispIn;
        else
            UI.monoSyn.disp = 'None';
        end
        
        % History function initialization
        if isfield(cell_metrics.general,'classificationTrackChanges') & ~isempty(cell_metrics.general.classificationTrackChanges)
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
        history_classification(1).cellIDs = 1:size(cell_metrics.troughToPeak,2);
        history_classification(1).cellTypes = clusClas;
        history_classification(1).deepSuperficial = cell_metrics.deepSuperficial;
        history_classification(1).labels = cell_metrics.labels;
        history_classification(1).tags = cell_metrics.tags;
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
        
        waveformOptions = {'Waveforms (single)';'Waveforms (all)';'Waveforms (image)'};
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
            responseCurvesOptions = {'responseCurves_thetaPhase (all)';'responseCurves_thetaPhase (image)'};
        else
            responseCurvesOptions = {};
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
        plotOptions = unique([waveformOptions; waveformOptions2; acgOptions; customPlotOptions; plotOptions;responseCurvesOptions],'stable');
        
        % Initilizing view #1
        UI.popupmenu.customplot1.String = plotOptions;
        if any(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); UI.popupmenu.customplot1.Value = find(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); else; UI.popupmenu.customplot1.Value = 1; end
        customCellPlot1 = plotOptions{UI.popupmenu.customplot1.Value};
        
        % Initilizing view #2
        UI.popupmenu.customplot2.String = plotOptions;
        if find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); UI.popupmenu.customplot2.Value = find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); else; UI.popupmenu.customplot2.Value = 4; end
        customCellPlot2 = plotOptions{UI.popupmenu.customplot2.Value};
        
        % Initilizing view #3
        UI.popupmenu.customplot3.String = plotOptions;
        if find(strcmp(UI.settings.customCellPlotIn3,plotOptions)); UI.popupmenu.customplot3.Value = find(strcmp(UI.settings.customCellPlotIn3,plotOptions)); else; UI.popupmenu.customplot3.Value = 7; end
        customCellPlot3 = plotOptions{UI.popupmenu.customplot3.Value};
        
        % Initilizing view #4
        UI.popupmenu.customplot4.String = plotOptions;
        if find(strcmp(UI.settings.customCellPlotIn4,plotOptions)); UI.popupmenu.customplot4.Value = find(strcmp(UI.settings.customCellPlotIn4,plotOptions)); else; UI.popupmenu.customplot4.Value = 7; end
        customCellPlot4 = plotOptions{UI.popupmenu.customplot4.Value};
        
        % Initilizing view #5
        UI.popupmenu.customplot5.String = plotOptions;
        if find(strcmp(UI.settings.customCellPlotIn5,plotOptions)); UI.popupmenu.customplot5.Value = find(strcmp(UI.settings.customCellPlotIn5,plotOptions)); else; UI.popupmenu.customplot5.Value = 7; end
        customCellPlot5 = plotOptions{UI.popupmenu.customplot5.Value};
        
        % Initilizing view #6
        UI.popupmenu.customplot6.String = plotOptions;
        if find(strcmp(UI.settings.customCellPlotIn6,plotOptions)); UI.popupmenu.customplot6.Value = find(strcmp(UI.settings.customCellPlotIn6,plotOptions)); else; UI.popupmenu.customplot6.Value = 7; end
        customCellPlot6 = plotOptions{UI.popupmenu.customplot6.Value};
        
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
        UI.popupmenu.groups.String = colorMenu;
        
        plotClas = clusClas;
        UI.popupmenu.groups.Value = 1;
        clasLegend = 0;
        UI.listbox.groups.Visible='Off';
        customCellPlot2 = UI.settings.customCellPlotIn2;
        UI.checkbox.groups.Value = 0;
        
        % Init synaptic connections
        if isfield(cell_metrics,'synapticEffect')
            cellsExcitatory = find(strcmp(cell_metrics.synapticEffect,'Excitatory'));
            cellsInhibitory = find(strcmp(cell_metrics.synapticEffect,'Inhibitory'));
        end
        if isfield(cell_metrics,'putativeConnections') & isfield(cell_metrics.putativeConnections,'excitatory') & ~isempty(cell_metrics.putativeConnections.excitatory)
            cellsExcitatoryPostsynaptic = unique(cell_metrics.putativeConnections.excitatory(:,2));
        else
            cellsExcitatoryPostsynaptic = [];
        end
        if isfield(cell_metrics,'putativeConnections') & isfield(cell_metrics.putativeConnections,'inhibitory') & ~isempty(cell_metrics.putativeConnections.inhibitory)
            cellsInhibitoryPostsynaptic = unique(cell_metrics.putativeConnections.inhibitory(:,2));
        else
            cellsInhibitoryPostsynaptic = [];
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
        UI.fig.Name = ['Cell Explorer v' num2str(CellExplorerVersion), ': ',cell_metrics.general.basename];
        
        
        % Initialize spike plot options
        customSpikePlotOptions = what('customSpikesPlots');
        customSpikePlotOptions = cellfun(@(X) X(1:end-2),customSpikePlotOptions.m,'UniformOutput', false);
        customSpikePlotOptions(strcmpi(customSpikePlotOptions,'spikes_template')) = [];
        spikesPlots = {};
        for i = 1:length(customSpikePlotOptions)
            spikesPlots.(customSpikePlotOptions{i}) = customSpikesPlots.(customSpikePlotOptions{i});
        end
    end
    
    function [cell_metrics,referenceData] = initializeReferenceData(cell_metrics,inputType)
        
        if strcmp(inputType,'reference')
            % Cell type initialization
            referenceData.cellTypes = unique([UI.settings.cellTypes,cell_metrics.putativeCellType],'stable');
            clear referenceData1
            referenceData.clusClas = ones(1,length(cell_metrics.putativeCellType));
            for i = 1:length(referenceData.cellTypes)
                referenceData.clusClas(strcmp(cell_metrics.putativeCellType,referenceData.cellTypes{i}))=i;
            end
%             [referenceData.clusClas, referenceData.cellTypes] = findgroups(cell_metrics.putativeCellType);
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas,[1:length(referenceData.cellTypes)+1])'))';
        else
            % Ground truth initialization
            clear groundTruthData1 
%             referenceData.groundTruthTypes = unique([UI.settings.groundTruth,cell_metrics.groundTruthClassification],'stable');
            [referenceData.clusClas, referenceData.groundTruthTypes] = findgroups([cell_metrics.groundTruthClassification{:}]);
            referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas)'))';
        end
        
        
        % Creating surface of reference points
        referenceData.x = fig2_axislimit_x(1):10:fig2_axislimit_x(2);
        referenceData.y = 10.^(log10(fig2_axislimit_y(1)):0.05:log10(fig2_axislimit_y(2)));
        
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
        referenceData.x = referenceData.x(1:end-1)+5;
        referenceData.y = 10.^(log10(fig2_axislimit_y(1))+0.025:0.05:log10(fig2_axislimit_y(2))-0.05);
        
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
            cell_metrics.acg.log10_occurence = normalize_range(cell_metrics.acg.log10.*diff(10.^ACGLogIntervals)');
        end

        if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
            cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10); 
            cell_metrics.isi.log10_occurence = normalize_range(cell_metrics.isi.log10.*diff(10.^ACGLogIntervals)'); 
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

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

% % % % % % % % % % % % % % % % % % % % % %

    function DatabaseSessionDialog(~,~)
        % Load sessions from the database.
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
                drawnow nocallbacks;
                if isempty(db) && exist('db_cell_metrics_session_list.mat')
                    load('db_cell_metrics_session_list.mat')
                elseif isempty(db)
                    LoadDB_sessionlist
                end
                
                loadDB.dialog = dialog('Position', [300, 300, 900, 565],'Name','Cell Explorer: Load sessions from DB','WindowStyle','modal', 'resize', 'on' ); movegui(loadDB.dialog,'center')
                loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 ); 
                loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
                loadDB.sessionList = uitable(loadDB.VBox,'Data',db.dataTable,'Position',[10, 50, 880, 457],'ColumnWidth',{20 30 210 50 120 70 160 110 110 110},'columnname',{'','#','Session','Cells','Animal','Species','Behaviors','Investigator','Repository','Brain regions'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized'); % ,'CellSelectionCallback',@ClicktoSelectFromTable
                loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
                set(loadDB.VBox, 'Heights', [50 -1 35]);
                uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
                uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[480, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
                uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[640, 25, 150, 20],'Units','normalized','String','Repositories','HorizontalAlignment','center','Units','normalized');
                loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 460, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
                loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[480, 5, 150, 22],'Units','normalized','String',{'Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
                loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[640, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
                uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[800, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
                uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
                uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
                loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 480, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
                uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[700, 5, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog,'Units','normalized');
                uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[800, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog,'Units','normalized');
                
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
        
        function ClicktoSelectFromTable(src, event)
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
                    
                    f_LoadCellMetrics = waitbar(0,' ','name','Cell-metrics: loading batch');
                    cell_metrics1 = LoadCellMetricBatch('clusteringpaths', db_clusteringpath,'basenames',db_basename(indx),'basepaths',db_basepath,'waitbar_handle',f_LoadCellMetrics);
                    if ~isempty(cell_metrics1)
                        cell_metrics = cell_metrics1;
                    else
                        return
                    end
                    %                             cell_metrics = LoadCellMetricBatch('sessionIDs', str2double(db_menu_ids(indx)));
                    SWR_in = {};
                    
                    if ishandle(f_LoadCellMetrics)
                        waitbar(1,f_LoadCellMetrics,'Initializing session(s)');
                    else
                        disp(['Initializing session(s)']);
                    end
                    
                    initializeSession
                    if ishandle(f_LoadCellMetrics)
                        close(f_LoadCellMetrics)
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
        if exist('db_load_settings') == 2
            db_settings = db_load_settings;
            db = {};
            if ~strcmp(db_settings.credentials.username,'user')
                waitbar_message = 'Downloading session list. Hold on for a few seconds...';
                % DB settings for authorized users
                options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50,'CertificateFilename','');
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
                loadBD_waitbar = waitbar(0,waitbar_message,'name','Loading metadata from DB','WindowStyle', 'modal');
            else
                loadBD_waitbar = [];
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
                if ishandle(loadBD_waitbar)
                    close(loadBD_waitbar)
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
                MsgLog(['Failed to load sessions from database'],4);
            end
        else
            MsgLog('Database tools not installed');
            msgbox({'Database tools not installed. To install, follow the steps below: ','1. Go to the Cell Explorer Github webpage','2. Download the database tools', '3. Add the db directory to your Matlab path', '4. Optionally provide your credentials in db\_credentials.m and try again.'},createStruct);
        end
    end
    
    
% % % % % % % % % % % % % % % % % % % % % %
    
    function editDBcredentials(~,~)
        edit db_credentials.m
    end
    
% % % % % % % % % % % % % % % % % % % % % %
    
    function editDBrepositories(~,~)
        edit db_local_repositories.m
    end
    
% % % % % % % % % % % % % % % % % % % % % %

    function successMessage = LoadSession
        % Loads cell_metrics from a single session and initializes it.
        % Returns sucess/error message
        successMessage = '';
        messagePriority = 1;
        if exist(basepath)
            if exist(fullfile(clusteringpath,[basename, '.cell_metrics.cellinfo.mat']))
                cd(basepath);
                load(fullfile(clusteringpath,[basename, '.cell_metrics.cellinfo.mat']));
                cell_metrics.general.path = clusteringpath;
                initializeSession;
                
                successMessage = [basename ' with ' num2str(size(cell_metrics.troughToPeak,2))  ' cells loaded from database'];
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

% % % % % % % % % % % % % % % % % % % % % %

    function AdjustGUIbutton
        % Shuffles through the layout options and calls AdjustGUI
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

    function out = CheckSpikes(batchIDsIn)
        % Checks if spikes data is available for the selected session (batchIDs)
        % If it is, the file is loaded into memory (spikes structure)
        if length(batchIDsIn)>1
            waitbar_spikes = waitbar(0,['Loading spike data'],'Name',['Loading spikes from ', num2str(length(batchIDsIn)),' sessions'],'WindowStyle','modal');
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
                        waitbar_spikes = waitbar(0,['Loading spike data'],'Name',['Loading spikes data'],'WindowStyle','modal');
                    end
                    if ~ishandle(waitbar_spikes)
                        MsgLog(['Spike loading canceled by the user'],2);
                        return
                    end
                    waitbar_spikes = waitbar((batchIDsPrivate-1)/length(batchIDsIn),waitbar_spikes,[num2str(batchIDsPrivate) '. Loading ', basename1]);
                    temp = load(fullfile(clusteringpath1,[basename1,'.spikes.cellinfo.mat']));
                    spikes{batchIDsPrivate} = temp.spikes;
                    out = true;
                    MsgLog(['Spikes loaded succesfully for ' basename1]);
                    if ishandle(waitbar_spikes) && length(batchIDsIn) == 1
                        close(waitbar_spikes)
                    end
                else
                    out = false;
                end
            else
                out = true;
            end
        end
        if i_batch == length(batchIDsIn) && length(batchIDsIn) > 1 && ishandle(waitbar_spikes)
            close(waitbar_spikes)
            if length(batchIDsIn)>1
                MsgLog(['Spike data loading complete'],2);
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

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
                eventsfilesize = dir(eventfile);
                if eventsfilesize.bytes/1000000>10 % Show waitbar if filesize exceeds 10MB
                    waitbar_events = waitbar(0,['Loading events from ', basename1 , ' (', num2str(ceil(eventsfilesize.bytes/1000000)), 'MB)'],'Name','Loading events','WindowStyle','modal');
                end
                temp = load(eventfile);
                if isfield(temp.(eventName),'timestamps')
                    events.(eventName){batchIDs} = temp.(eventName);
                    if isfield(temp.(eventName),'peakNormedPower') & ~isfield(temp.(eventName),'amplitude')
                        events.(eventName){batchIDs}.amplitude = temp.(eventName).peakNormedPower;
                    end
                    if isfield(temp.(eventName),'timestamps') & ~isfield(temp.(eventName),'duration')
                        events.(eventName){batchIDs}.duration = diff(temp.(eventName).timestamps')';
                    end
                    out = true;
                    MsgLog([eventName ' events loaded succesfully for ' basename1]);
                else
                    out = false;
                    MsgLog([eventName ' events loading failed due to missing fieldname timestamps for ' basename1]);
                end
                if exist('waitbar_events') & ishandle(waitbar_events)
                    close(waitbar_events)
                end
            else
                out = false;
            end
        else
            out = true;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function defineSpikesPlots(~,~)
        % check for local spikes structure before the spikePlotListDlg dialog is called
        out = CheckSpikes(batchIDs);
        if out
            spikePlotListDlg;
        else
            MsgLog(['No spike data found or the spike data is not accessible: ',general.basename],2)
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function spikePlotListDlg
        % Displays a dialog with the spike plots as defined in the
        % spikesPlots structure
        spikePlotList_dialog = dialog('Position', [300, 300, 670, 400],'Name','Spike plot types','WindowStyle','modal'); movegui(spikePlotList_dialog,'center')
        
        tableData = updateTableData(spikesPlots);
        spikePlot = uitable(spikePlotList_dialog,'Data',tableData,'Position',[10, 50, 650, 340],'ColumnWidth',{20 125 90 90 90 90 70 70},'columnname',{'','Plot name','X data','Y data','X label','Y label','State','Event'},'RowName',[],'ColumnEditable',[true false false false false false false false]);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add plot','Callback',@(src,evnt)addPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[100, 10, 90, 30],'String','Edit plot','Callback',@(src,evnt)editPlotToTable);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[190, 10, 90, 30],'String','Delete plot','Callback',@(src,evnt)DeletePlot);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[280, 10, 90, 30],'String','Reset spike data','Callback',@(src,evnt)ResetSpikeData);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[370, 10, 100, 30],'String','Load all spike data','Callback',@(src,evnt)LoadAllSpikeData);
        OK_button = uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[480, 10, 90, 30],'String','OK','Callback',@(src,evnt)CloseSpikePlotList_dialog);
        uicontrol('Parent',spikePlotList_dialog,'Style','pushbutton','Position',[570, 10, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikePlotList_dialog);
        
        uicontrol(OK_button)
        uiwait(spikePlotList_dialog);
        
        function  ResetSpikeData
            % Resets spikes and event data and closes the dialog
            spikes = [];
            events = [];
            delete(spikePlotList_dialog);
            MsgLog('Spike and event data have been reset',2)
        end
        
        function LoadAllSpikeData
            % Loads all spikes data
            out = CheckSpikes([1:length(cell_metrics.general.batch)]);
        end
        
        function tableData = updateTableData(spikesPlots)
            % Updates the plot table from the spikesPlots structure
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
            % Closes the dialog and resets the plot options
            plotOptions(contains(plotOptions,'spikes_')) = [];
            plotOptions = [plotOptions;fieldnames(spikesPlots)];
            plotOptions = unique(plotOptions,'stable');
            UI.popupmenu.customplot1.String = plotOptions; if UI.popupmenu.customplot1.Value>length(plotOptions), UI.popupmenu.customplot1.Value=1; end
            UI.popupmenu.customplot2.String = plotOptions; if UI.popupmenu.customplot2.Value>length(plotOptions), UI.popupmenu.customplot2.Value=1; end
            UI.popupmenu.customplot3.String = plotOptions; if UI.popupmenu.customplot3.Value>length(plotOptions), UI.popupmenu.customplot3.Value=1; end
            UI.popupmenu.customplot4.String = plotOptions; if UI.popupmenu.customplot4.Value>length(plotOptions), UI.popupmenu.customplot4.Value=1; end
            UI.popupmenu.customplot5.String = plotOptions; if UI.popupmenu.customplot5.Value>length(plotOptions), UI.popupmenu.customplot5.Value=1; end
            UI.popupmenu.customplot6.String = plotOptions; if UI.popupmenu.customplot6.Value>length(plotOptions), UI.popupmenu.customplot6.Value=1; end
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

% % % % % % % % % % % % % % % % % % % % % %

    function spikesPlotsOut = spikePlotsDlg(fieldtoedit)
        % Displayes a dialog window for defining a new spike plot.
        
        spikesPlotsOut = '';
        spikePlots_dialog = dialog('Position', [300, 300, 670, 450],'Name','Plot type','WindowStyle','modal'); movegui(spikePlots_dialog,'center')
        
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
%         
%         if UI.BatchMode
%             basepath1 = cell_metrics.general.basepaths{batchIDs};
%         else
%             basepath1 = basepath;
%         end
        
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
        spikePlotFilterData = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', ['Select field';spikesField], 'Value',1,'Position', [10, 155, 210, 20],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Type', 'Position', [230, 169, 210, 20],'HorizontalAlignment','left');
        spikePlotFilterType = uicontrol('Parent',spikePlots_dialog,'Style', 'popupmenu', 'String', {'none','equal to','less than','greater than'}, 'Value',1,'Position', [230, 155, 130, 20],'HorizontalAlignment','left');
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Value', 'Position', [370, 169, 70, 20],'HorizontalAlignment','left');
        spikePlotFilterValue = uicontrol('Parent',spikePlots_dialog,'Style', 'Edit', 'String', '', 'Position', [370, 155, 70, 20],'HorizontalAlignment','left');
        
        % Event data
        uicontrol('Parent', spikePlots_dialog, 'Style', 'text', 'String', 'Event', 'Position', [10, 121, 210, 20],'HorizontalAlignment','left');
        spikePlotEventType = uicontrol('Parent', spikePlots_dialog, 'Style', 'popupmenu', 'String', {'none','event', 'manipulation','state'}, 'Value',1,'Position', [10, 105, 210, 20],'HorizontalAlignment','left');
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
        uicontrol('Parent',spikePlots_dialog,'Style', 'text', 'String', 'Event settings', 'Position', [450, 71, 120, 20],'HorizontalAlignment','left');
        spikePlotEventPlotRaster = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 55 70 20],'Units','normalized','String','Raster','HorizontalAlignment','left');
        spikePlotEventPlotAverage = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 35 70 20],'Units','normalized','String','Histogram','HorizontalAlignment','left');
        spikePlotEventPlotAmplitude = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[450 15 70 20],'Units','normalized','String','Amplitude','HorizontalAlignment','left');
        spikePlotEventPlotDuration = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[530 55 70 20],'Units','normalized','String','Duration','HorizontalAlignment','left');
        spikePlotEventPlotCount = uicontrol('Parent',spikePlots_dialog,'Style','checkbox','Position',[530 35 70 20],'Units','normalized','String','Count','HorizontalAlignment','left');
        
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
        
        uicontrol(spikePlotName);
        uiwait(spikePlots_dialog);
        
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
                spikesPlotsOut.(spikePlotName2).filterValue = str2num(spikePlotFilterValue.String);
                % Event data
                spikesPlotsOut.(spikePlotName2).eventSecBefore = str2num(spikePlotEventSecBefore.String);
                spikesPlotsOut.(spikePlotName2).eventSecAfter = str2num(spikePlotEventSecAfter.String);
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
                        if isempty(fieldString.String) | ~all(ismember(fieldString.String, '.1234567890'))
                            uiwait(warndlg('Field must be numeric'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'alphanumeric'
                        if isempty(fieldString.String) | ~regexp(fieldString.String, '^[A-Za-z0-9_]+$') | ~regexp(fieldString.String(1), '^[A-Z]+$')
                            uiwait(warndlg('Field must be alpha numeric'))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'required'
                        if isempty(fieldString.String)
                            uiwait(warndlg(['Required field missing']))
                            uicontrol(fieldString);
                            out = 0;
                        end
                    case 'varname'
                        if ~isvarname(fieldString.String)
                            uiwait(warndlg(['Field must be a valid variable name']))
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

% % % % % % % % % % % % % % % % % % % % % %

    function editSelectedSpikePlot(~,~)
        % Called when scrolling/zooming in the cell inspector.
        % Checks first, if a plot is underneath the curser
        
        axnum = getAxisBelowCursor;
        if isfield(UI,'panel') & ~isempty(axnum)
            handle34 = subfig_ax(axnum);
            handle34 = h2.Children(end);
            um_axes = get(handle34,'CurrentPoint');
            if any(ismember(subfig_ax, h2.Children))>0 && any(find(ismember(subfig_ax, h2.Children)) == [4:9])
                axnum = find(ismember(subfig_ax, h2.Children));
            else
                axnum = 1;
            end
            customCellPlotList = {customCellPlot1,customCellPlot2,customCellPlot3,customCellPlot4,customCellPlot5,customCellPlot6};
            if strcmp(customCellPlotList{axnum-3}(1:7),'spikes_')
                spikesPlotsOut = spikePlotsDlg(customCellPlotList{axnum-3});
                if ~isempty(spikesPlotsOut)
                    for fn = fieldnames(spikesPlotsOut)'
                        spikesPlots.(fn{1}) = spikesPlotsOut.(fn{1});
                    end
                    uiresume(UI.fig);
                end
            end
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function loadGroundTruth(~,~)
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
        performGroundTruthClassification
    end

% % % % % % % % % % % % % % % % % % % % % %

    function compareToReference(src,evnt)
        if isfield(src,'Text') && strcmp(src.Text,'Compare cell groups to reference data')
            inputReferenceData = 1;
            clr2 = UI.settings.cellTypeColors(unique(referenceData.clusClas),:);
            listClusClas_referenceData = unique(referenceData.clusClas);
        else
            inputReferenceData = 0;
        end
        list_metrics = generateMetricsList('all');
        compareToGroundTruth.dialog = dialog('Position', [300, 300, 400, 518],'Name','Select the metrics to compare','WindowStyle','modal'); movegui(compareToGroundTruth.dialog,'center')
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
%             [plotRows,~]= numSubplots(length(selectedFields));
            regularFields = find(~contains(selectedFields,'.'));
            figure
            for i = 1:length(regularFields)
                if k > 4
                    k = 1;
                    figure
                end
                %                 subplot(plotRows(1),plotRows(2),k)
                subplot(2,n_selectedFields,k)
                hold on, title(selectedFields(regularFields(i)))
                for j = 1:length(classesToPlot)
                    
                    [N,edges] = histcounts(cell_metrics.(selectedFields{regularFields(i)})(idx{j}),20, 'Normalization', 'probability');
                    plot(edges,[N,0],'color',clr(j,:),'linewidth',2)
                end
                subplot(2,n_selectedFields,k+n_selectedFields), hold on
                if inputReferenceData == 1
                    % Reference data
                    title('Reference data')
                    for j = 1:length(listClusClas_referenceData)
                        idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                        [N,edges] = histcounts(reference_cell_metrics.(selectedFields{regularFields(i)})(idx2),20, 'Normalization', 'probability');
                        plot(edges,[N,0],'color',clr2(j,:),'linewidth',2)
                    end
                else
                    % Ground truth cells
                    title('Ground truth cells')
                    if ~isempty(subsetGroundTruth)
                        idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                        for jj = 1:length(idGroundTruth)
                            [N,edges] = histcounts(cell_metrics.(selectedFields{regularFields(i)})(subsetGroundTruth{idGroundTruth(jj)}),20, 'Normalization', 'probability');
                            plot(edges,[N,0],'color',clr(j,:),'linewidth',2)
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
                    %                     subplot(plotRows(1),plotRows(2),k),
                    subplot(2,n_selectedFields,k)
                    hold on, title(selectedFields(structFields(i)))
                    for j = 1:length(classesToPlot)
                        temp1 = mean(cell_metrics.(newStr{1}).(newStr{2})(:,idx{j})');
                        temp2 = std(cell_metrics.(newStr{1}).(newStr{2})(:,idx{j})');
                        patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr(j,:),'EdgeColor','none','FaceAlpha',.2)
                        plot(1:length(temp1), temp1, 'color', clr(j,:),'linewidth',2)
                    end
                    subplot(2,n_selectedFields,k+n_selectedFields),hold on
                    if inputReferenceData == 1
                        % Reference data
                        title('Reference data')
                        for j = 1:length(listClusClas_referenceData)
                            idx2 = find(referenceData.clusClas==listClusClas_referenceData(j));
                            temp1 = mean(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2)');
                            temp2 = std(reference_cell_metrics.(newStr{1}).(newStr{2})(:,idx2)');
                            patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr2(j,:),'EdgeColor','none','FaceAlpha',.2)
                            plot(1:length(temp1), temp1, 'color', clr(j,:),'linewidth',2)
                        end
                    else
                        % Ground truth cells
                        title('Ground truth cells')
                        if ~isempty(subsetGroundTruth)
                            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                            for jj = 1:length(idGroundTruth)
                                temp1 = mean(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)})');
                                temp2 = std(cell_metrics.(newStr{1}).(newStr{2})(:,subsetGroundTruth{idGroundTruth(jj)})');
                                patch([1:length(temp1),flip(1:length(temp1))], [temp1+temp2,flip(temp1-temp2)],clr(j,:),'EdgeColor','none','FaceAlpha',.2)
                                plot(1:length(temp1), temp1, 'color', clr(j,:),'linewidth',2)
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
    
% % % % % % % % % % % % % % % % % % % % % %
    
    function data = normalize_range(data)
        % Normalizes a input matrix or vector to the interval [0,1]
        data = data./range(data);
    end
        
% % % % % % % % % % % % % % % % % % % % % %

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
            f_LoadMonoSyn = waitbar(0,' ','name','Cell Explorer: loading MonoSyn file');
            mono_res1 = load(MonoSynFile);
            if ishandle(f_LoadMonoSyn)
                waitbar(1,f_LoadMonoSyn,'Complete');
                close(f_LoadMonoSyn)
            end
            mono_res = gui_MonoSyn(mono_res1.mono_res,cell_metrics.UID(ii));
            % Saves output to the cell_metrics from the select session
            answer = questdlg('Do you want to save the manual monosynaptic curration?', 'Save monosynaptic curration', 'Yes','No','Yes');
            if strcmp(answer,'Yes')
                f_LoadMonoSyn = waitbar(0,' ','name','Cell Explorer: Updating MonoSyn');
                if isfield(general,'saveAs')
                    saveAs = general.saveAs;
                else
                    saveAs = 'cell_metrics';
                end
                try
                    % Saving MonoSynFile fule
                    if ishandle(f_LoadMonoSyn)
                        waitbar(0.05,f_LoadMonoSyn,'Saving MonoSyn file');
                    end
                    save(MonoSynFile,'mono_res','-v7.3','-nocompression');
                    
                    % Creating backup of existing metrics
                    if ishandle(f_LoadMonoSyn)
                        waitbar(0.4,f_LoadMonoSyn,'Creating backup of existing metrics');
                    end
                    dirname = 'revisions_cell_metrics';
                    if ~(exist(fullfile(path1,dirname),'dir'))
                        mkdir(fullfile(path1,dirname));
                    end
                    if exist(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']),'file')
                        copyfile(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), fullfile(path1, dirname, [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']));
                    end
                    
                    % Saving new metrics
                    if ishandle(f_LoadMonoSyn)
                        waitbar(0.7,f_LoadMonoSyn,['Saving cells to cell_metrics file']);
                    end
                    cell_session = load(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']));
                    cell_session.cell_metrics.putativeConnections.excitatory = mono_res.sig_con; % Vectors with cell pairs
                    cell_session.cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_session.cell_metrics.general.cellCount);
                    cell_session.cell_metrics.synapticEffect(cell_session.cell_metrics.putativeConnections.excitatory(:,1)) = repmat({'Excitatory'},1,size(cell_session.cell_metrics.putativeConnections.excitatory,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
                    cell_session.cell_metrics.synapticConnectionsOut = zeros(1,cell_session.cell_metrics.general.cellCount);
                    cell_session.cell_metrics.synapticConnectionsIn = zeros(1,cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,1),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,1)));
                    cell_session.cell_metrics.synapticConnectionsOut(b) = a; cell_session.cell_metrics.synapticConnectionsOut = cell_session.cell_metrics.synapticConnectionsOut(1:cell_session.cell_metrics.general.cellCount);
                    [a,b]=hist(cell_session.cell_metrics.putativeConnections.excitatory(:,2),unique(cell_session.cell_metrics.putativeConnections.excitatory(:,2)));
                    cell_session.cell_metrics.synapticConnectionsIn(b) = a; cell_session.cell_metrics.synapticConnectionsIn = cell_session.cell_metrics.synapticConnectionsIn(1:cell_session.cell_metrics.general.cellCount);
                    
                    save(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), '-struct', 'cell_session','-v7.3','-nocompression')
%                     MsgLog(['Synaptic connections adjusted for: ', basename1,'. Reload session to see the changes'],2);
                    
                    if ishandle(f_LoadMonoSyn)
                        waitbar(0.9,f_LoadMonoSyn,'Updating session');
                    end
                    if UI.BatchMode
                        idx = find(cell_metrics.batchIDs == batchIDs);
                    else
                        idx = 1:cell_metrics.general.cellCount;
                    end
                    if length(idx) == cell_session.cell_metrics.general.cellCount
                        [~,ia,~] = intersect(cell_metrics.putativeConnections.excitatory(:,1), idx);
                        cell_metrics.putativeConnections.excitatory(ia,:) = [];
                        cell_metrics.putativeConnections.excitatory = [cell_metrics.putativeConnections.excitatory;idx(mono_res.sig_con)];
                        cell_metrics.synapticEffect(idx) = repmat({'Unknown'},1,cell_session.cell_metrics.general.cellCount);
                        cell_metrics.synapticEffect(idx(cell_session.cell_metrics.putativeConnections.excitatory(:,1))) = repmat({'Excitatory'},1,size(cell_session.cell_metrics.putativeConnections.excitatory,1));
                        
                        cell_metrics.synapticConnectionsOut(idx) = cell_session.cell_metrics.synapticConnectionsOut;
                        cell_metrics.synapticConnectionsIn(idx) = cell_session.cell_metrics.synapticConnectionsIn;
                        
                        if isfield(cell_metrics,'synapticEffect')
                            cellsExcitatory = find(strcmp(cell_metrics.synapticEffect,'Excitatory'));
                            cellsInhibitory = find(strcmp(cell_metrics.synapticEffect,'Inhibitory'));
                        end
                        if isfield(cell_metrics,'putativeConnections') & isfield(cell_metrics.putativeConnections,'excitatory') & ~isempty(cell_metrics.putativeConnections.excitatory)
                            cellsExcitatoryPostsynaptic = unique(cell_metrics.putativeConnections.excitatory(:,2));
                        else
                            cellsExcitatoryPostsynaptic = [];
                        end
                        if isfield(cell_metrics,'putativeConnections') & isfield(cell_metrics.putativeConnections,'inhibitory') & ~isempty(cell_metrics.putativeConnections.inhibitory)
                            cellsInhibitoryPostsynaptic = unique(cell_metrics.putativeConnections.inhibitory(:,2));
                        else
                            cellsInhibitoryPostsynaptic = [];
                        end
                    else
                        MsgLog(['Error updating current session. Reload session to see the changes'],4);
                    end
                    
                    if ishandle(f_LoadMonoSyn)
                        waitbar(1,f_LoadMonoSyn,'Complete');
                    end
                    MsgLog(['Synaptic connections adjusted for: ', basename1]);
                    uiresume(UI.fig);
                catch
                    MsgLog(['Synaptic connections adjustment failed.'],4);
                end
                
                if ishandle(f_LoadMonoSyn)
                    close(f_LoadMonoSyn)
                end
            else
                MsgLog(['Synaptic connections not updated.']);
            end
        elseif ~exist(MonoSynFile,'file')
            MsgLog(['Mono_syn file does not exist: ' MonoSynFile],4);
            return
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % %
    
    function performGroundTruthClassification(~,~)
        if ~isfield(UI.tabs,'groundTruthClassification')
            % UI.settings.groundTruth
            createToggleMenu('groundTruthClassification',UI.panel.tabgroup1,UI.settings.groundTruth,'G/T')
        end
        
        function createToggleMenu(childName,parentPanelName,buttonLabels,panelTitle)
            % INPUTS
            % parentPanelName: UI.panel.tabgroup1
            % childName:
            % buttonLabels:    UI.settings.groundTruth
            % panelTitle:      'G/T'
            
            UI.tabs.(childName) =uitab(parentPanelName,'Title',panelTitle);
            buttonPosition = getButtonLayout(parentPanelName,buttonLabels);

            % Display settings for tags1
            for i = 1:min(length(buttonLabels),10)
%                 innerPosition = [(1-mod(i,2))*positionToogleButtons(1),(rows-ceil(i/2))*positionToogleButtons(2),positionToogleButtons(1)*0.95,positionToogleButtons(2)*0.95];
                UI.togglebutton.(childName)(i) = uicontrol('Parent',UI.tabs.(childName),'Style','togglebutton','String',buttonLabels{i},'Position',buttonPosition{i},'Value',0,'Units','normalized','Callback',@(src,evnt)buttonGroundTruthClassification(i),'KeyPressFcn', {@keyPress});
            end
            parentPanelName.SelectedTab = UI.tabs.(childName);
            updateGroundTruth
        end
    end


    
    function buttonGroundTruthClassification(input)
        saveStateToHistory(ii)
        if UI.togglebutton.groundTruthClassification(input).Value == 1
            if isempty(cell_metrics.groundTruthClassification{ii})
                cell_metrics.groundTruthClassification{ii} = {UI.settings.groundTruth{input}};
            else
                cell_metrics.groundTruthClassification{ii} = [cell_metrics.groundTruthClassification{ii},UI.settings.groundTruth{input}];
                %                 [cell_metrics.groundTruthClassification(ii),UI.settings.groundTruth{input}];
            end
            MsgLog(['Cell ', num2str(ii), ' ground truth assigned: ', UI.settings.groundTruth{input}]);
        else
            cell_metrics.groundTruthClassification{ii}(find(strcmp(cell_metrics.groundTruthClassification{ii},UI.settings.groundTruth{input}))) = [];
            MsgLog(['Cell ', num2str(ii), ' ground truth removed: ', UI.settings.groundTruth{input}]);
        end
        %         classificationTrackChanges = [classificationTrackChanges,ii];
        if groundTruthSelection
            uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function [choice,dialog_canceled] = groundTruthDlg(groundTruthCelltypes,groundTruthSelectionIn)
        choice = '';
        dialog_canceled = 1;
        updateGroundTruthCount;
        
        groundTruth_dialog = dialog('Position', [300, 300, 600, 350],'Name','Ground truth cell types'); movegui(groundTruth_dialog,'center')
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
            tagFilter2 = find(cellfun(@(X) ~isempty(X), cell_metrics.groundTruthClassification));
            if ~isempty(tagFilter2)
                cellCount = [];
                for j = 1:length(groundTruthCelltypes)
                    cellCount(j) = sum(cell2mat(cellfun(@(X) any(contains(X,groundTruthCelltypes{j})), cell_metrics.groundTruthClassification(tagFilter2),'UniformOutput',false)));
                end
            else
                cellCount = zeros(1,length(groundTruthCelltypes));
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

% % % % % % % % % % % % % % % % % % % % % %

    function filterCellsByText(src,event)
        if ~isempty(UI.textFilter.String) && ~strcmp(UI.textFilter.String,'Filter')
            freeText = {''};
            [newStr2,matches] = split(UI.textFilter.String,[" & "," | "]);
            idx_textFilter2 = zeros(length(newStr2),size(cell_metrics.troughToPeak,2));
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
                            if ~contains(fieldsMenuCells{j},{'groundTruthClassification','tags'})
                                freeText = strcat(freeText,{' '},cell_metrics.(fieldsMenuCells{j}));
                            end
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
                MsgLog([num2str(length(idx_textFilter)),'/',num2str(size(cell_metrics.troughToPeak,2)),' cells selected with ',num2str(length(newStr2)),' filter: ' ,UI.textFilter.String]);
            elseif failCheck == 2
                MsgLog('Filter not formatted correctly. Field does not exist',2);
            else
                MsgLog('Filter not formatted correctly',2);
                idx_textFilter = 1:size(cell_metrics.troughToPeak,2);
            end
        else
            idx_textFilter = 1:size(cell_metrics.troughToPeak,2);
            MsgLog('Filter reset');
        end
        if isempty(idx_textFilter)
           idx_textFilter = -1; 
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function MsgLog(message,priority)
        % Writes the input message to the message log with a timestamp. The second parameter
        % defines the priority i.e. if any  message or warning should be given as well.
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

    function AdjustGUI(~,~)
        % Adjusts the number of subplots. 1-3 general plots can be displayed, 3-6 cell-specific plots can be
        % displayed. The necessary panels are re-sized and toggled for the requested number of plots.
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
            UI.panel.subfig_ax1.Position = [0 0.66 0.33 0.34];
            UI.panel.subfig_ax2.Position = [0.33 0.66 0.33 0.34];
            UI.panel.subfig_ax3.Position = [0.66 0.66 0.34 0.34];
            UI.panel.subfig_ax4.Position = [0 0.33 0.33 0.33];
            UI.panel.subfig_ax5.Position = [0.33 0.33 0.33 0.33];
            UI.panel.subfig_ax6.Position = [0.66 0.33 0.34 0.33];
            UI.panel.subfig_ax7.Position = [0 0 0.33 0.33];
            UI.panel.subfig_ax8.Position = [0.33 0 0.33 0.33];
            UI.panel.subfig_ax9.Position = [0.66 0 0.34 0.33];
            UI.popupmenu.plotCount.Value = 6;
            UI.settings.layout = 6;
        elseif UI.settings.layout == 6
            % GUI: 3+5 figures
            UI.popupmenu.customplot4.Enable = 'on';
            UI.popupmenu.customplot5.Enable = 'on';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'on';
            UI.panel.subfig_ax3.Visible = 'on';
            UI.panel.subfig_ax7.Visible = 'on';
            UI.panel.subfig_ax8.Visible = 'on';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.33 0.5];
            UI.panel.subfig_ax3.Position = [0.66 0.5 0.34 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0.25 0.33 0.25];
            UI.panel.subfig_ax6.Position = [0.66 0.25 0.34 0.25];
            UI.panel.subfig_ax7.Position = [0.33 0 0.33 0.25];
            UI.panel.subfig_ax8.Position = [0.66 0 0.34 0.25];
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
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.33 0.5];
            UI.panel.subfig_ax3.Position = [0.66 0.5 0.34 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0 0.33 0.5];
            UI.panel.subfig_ax6.Position = [0.66 0.25 0.34 0.25];
            UI.panel.subfig_ax7.Position = [0.66 0 0.34 0.25];
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
            UI.panel.subfig_ax1.Position = [0 0.5 0.33 0.5];
            UI.panel.subfig_ax2.Position = [0.33 0.5 0.33 0.5];
            UI.panel.subfig_ax3.Position = [0.66 0.5 0.34 0.5];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.5];
            UI.panel.subfig_ax5.Position = [0.33 0 0.33 0.5];
            UI.panel.subfig_ax6.Position = [0.66 0 0.34 0.5];
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
            UI.panel.subfig_ax1.Position = [0 0.4 0.5 0.6];
            UI.panel.subfig_ax3.Position = [0.5 0.4 0.5 0.6];
            UI.panel.subfig_ax4.Position = [0 0 0.33 0.4];
            UI.panel.subfig_ax5.Position = [0.33 0 0.33 0.4];
            UI.panel.subfig_ax6.Position = [0.66 0 0.34 0.4];
            UI.popupmenu.plotCount.Value = 2;
            UI.settings.layout = 2;
        elseif UI.settings.layout == 2
            % GUI: 1+3 figures.
            UI.popupmenu.customplot4.Enable = 'off';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'off';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0 0 0.7 1];
            UI.panel.subfig_ax4.Position = [0.70 0.66 0.3 0.34];
            UI.panel.subfig_ax5.Position = [0.70 0.33 0.3 0.33];
            UI.panel.subfig_ax6.Position = [0.70 0 0.3 0.33];
            UI.popupmenu.plotCount.Value = 1;
            UI.settings.layout = 1;
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function keyPress(src, event)
        % Keyboard shortcuts. Sorted alphabetically
        switch event.Key
            case 'h'
                HelpDialog;
            case 'm'
                % Hide/show menubar
                ShowHideMenu
            case 'n'
                % Adjusts the number of subplots in the GUI
                AdjustGUI;
            case 'z'
%                 undoClassification;
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
                buttonCellType(str2num(event.Key));
            case {'numpad1','numpad2','numpad3','numpad4','numpad5','numpad6','numpad7','numpad8','numpad9'}
                advanceClass(str2num(event.Key(end)))
            case 'numpad0'
                ii = 1;
                uiresume(UI.fig);
        end
    end

% % % % % % % % % % % % % % % % % % % % % % 

    function ShowHideMenu(~,~)
        % Hide/show menubar
        if UI.settings.displayMenu == 0
            set(UI.fig, 'MenuBar', 'figure')
            UI.settings.displayMenu = 1;
        else
            set(UI.fig, 'MenuBar', 'None')
            UI.settings.displayMenu = 0;
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function AboutDialog(~,~)
        opts.Interpreter = 'tex';
        opts.WindowStyle = 'normal';
        msgbox({['\bfCell Explorer\rm v', num2str(CellExplorerVersion)],'By Peter Petersen.', 'Developed in the Buzsaki laboratory at NYU, USA.','\itgithub.com/petersenpeter/Cell-Explorer\rm'},'About the Cell Explorer','help',opts);
    end
    
% % % % % % % % % % % % % % % % % % % % % % 

    function HelpDialog(~,~)
        opts.Interpreter = 'tex';
        opts.WindowStyle = 'normal';
        msgbox({'\bfNavigation\rm','<    : Next cell', '>    : Previous cell','.     : Next cell with same class',',     : Previous cell with same class','+G   : Go to a specific cell','Page Up      : Next session in batch (only in batch mode)','Page Down  : Previous session in batch (only in batch mode)','Numpad0     : First cell', 'Numpad1-9 : Next cell with that numeric class','Backspace   : Previously selected cell','Numeric + / - / *          : Zoom in / out / reset plots','   ',...
            '\bfCell assigments\rm','1-9 : Cell-types','+B    : Brain region','+L    : Label','Plus   : Add Cell-type','+Z    : Undo assignment', '+R    : Reclassify cell types','   ',...
            '\bfDisplay shortcuts\rm','M    : Show/Hide menubar','N    : Change layout [6, 5 or 4 subplots]','+E     : Highlight excitatory cells (triangles)','+I      : Highlight inhibitory cells (circles)','+F     : Display ACG fit', 'K    : Calculate and display significance matrix for all metrics (KS-test)','+T     : Calculate tSNE space from a selection of metrics','W    : Display waveform metrics','+Y    : Perform ground truth cell type classification','+U    : Load ground truth cell types','Space  : Show action dialog for selected cells','     ',...
            '\bfOther shortcuts\rm', '+P    : Open preferences for the Cell Explorer','+C    : Open the file directory of the selected cell','+D    : Opens sessions from the Buzsaki lab database','+A    : Load spike data','+J     : Adjust monosynaptic connections','+V    : Visit the Github wiki in your browser','',...
            '+ sign indicatea that the key must be combined with command/control (Mac/Windows)','','\bfVisit the Cell Explorer''s wiki for further help\rm',''},'Keyboard shortcuts','help',opts);
    end
    
% % % % % % % % % % % % % % % % % % % % % % 

    function subplot_advanced(x,y,z,w,new,titleIn)
        if isempty('new')
            new = 1;
        end
        if y == 1
            if mod(z,x) == 1 & new
                figure('Name',titleIn,'pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01])
            end
            subplot(x,y,mod(z-1,x)+1)
            
        else
            if (mod(z,x) == 1 || (z==x & z==1)) & w == 1
                figure('Name',titleIn,'pos',UI.settings.figureSize,'DefaultAxesLooseInset',[.01,.01,.01,.01])
            end
            subplot(x,y,y*mod(z-1,x)+w)
        end
    end
    
end