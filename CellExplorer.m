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
% CellExplorer('sessionIDs',[10985,2845])  % Load batch from database
% CellExplorer('clusteringpaths',{'path1','path1'}) %dr Load batch from a list with paths
% CellExplorer('basepaths',{'path1','[path1'}) % Load batch from a list with paths
%
% OUTPUT
% cell_metrics: struct

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 26-07-2019

% Shortcuts to built-in functions
% initializeSession, LoadDatabaseSession, buttonSave, keyPress, defineSpikesPlots, customPlot, GroupAction, brainRegionDlg

% TODO
% GUI to reverse changes from backup files
% Separate loading of ground truth features
% Submit ground truth cells from new session

p = inputParser;

addParameter(p,'metrics',[],@isstruct);
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'basename','',@isstr);
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
basename = p.Results.basepaths;
clusteringpath = p.Results.clusteringpath;

sessionIDs = p.Results.sessionIDs;
sessionsin = p.Results.sessions;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;
SWR_in = p.Results.SWR;


%% % % % % % % % % % % % % % % % % % % % % %
% Initialization of variables and figure
% % % % % % % % % % % % % % % % % % % % % %

UI = []; UI.settings.plotZLog = 0; UI.settings.plot3axis = 0; UI.settings.plotXdata = 'firingRate'; UI.settings.plotYdata = 'peakVoltage';
UI.settings.plotZdata = 'deepSuperficialDistance'; UI.settings.metricsTableType = 'Metrics'; colorStr = [];
UI.settings.customCellPlotIn1 = 'Single waveform'; UI.settings.customCellPlotIn2 = 'Single ACG'; UI.settings.deepSuperficial = '';
UI.settings.acgType = 'Normal'; UI.settings.cellTypeColors = []; UI.settings.monoSynDispIn = 'None'; UI.settings.layout = 3;
UI.settings.displayMenu = 0; UI.settings.displayInhibitory = false; UI.settings.displayExcitatory = false;
UI.settings.customCellPlotIn3 = 'thetaPhaseResponse'; UI.settings.customCellPlotIn4 = 'firingRateMap';
UI.settings.customCellPlotIn5 = 'firingRateMap'; UI.settings.customCellPlotIn6 = 'firingRateMap'; UI.settings.plotCountIn = 'GUI 3+3';
UI.settings.tSNE_calcNarrowAcg = true; UI.settings.tSNE_calcFiltWaveform = true; UI.settings.tSNE_metrics = '';
UI.settings.tSNE_calcWideAcg = true; UI.settings.dispLegend = 1; UI.settings.tags = {'good','bad','mua','noise','inverseSpike','Other'};
UI.settings.groundTruthMarkers = {'d','o','s','*','+','p'}; UI.settings.groundTruth = {'PV+','NOS1+','GAT1+'};
UI.settings.plotWaveformMetrics = 1; UI.settings.metricsTable = 1; synConnectOptions = {'None', 'Selected', 'Upstream', 'Downstream', 'Up & downstream', 'All'};
tableDataSortBy = 'cellID'; tableDataColumn1 = 'putativeCellType'; tableDataColumn2 = 'brainRegion'; 
tableDataSortingList = sort({'cellID', 'putativeCellType','peakVoltage','firingRate','troughToPeak','synapticConnectionsOut','synapticConnectionsIn','animal','sessionName','cv2','brainRegion','spikeGroup'});
plotOptionsToExlude = {'acg_','waveforms_'}; UI.settings.tSNE_dDistanceMetric = 'euclidean';
menuOptionsToExlude = {'putativeCellType','tags','groundTruthClassification'};
tableOptionsToExlude = {'putativeCellType','tags','groundTruthClassification','brainRegion','labels','deepSuperficial'};
fieldsMenuMetricsToExlude  = {'tags','groundTruthClassification'};
tableDataSortBy = 'cellID'; tableDataColumn1 = 'putativeCellType'; tableDataColumn2 = 'brainRegion'; 
tableDataSortingList = sort({'cellID', 'putativeCellType','peakVoltage','firingRate','troughToPeak','synapticConnectionsOut','synapticConnectionsIn','animal','sessionName','cv2','brainRegion','spikeGroup'});
UI.settings.firingRateMap.showHeatmap = false; UI.settings.firingRateMap.showLegend = false; UI.settings.firingRateMap.showHeatmapColorbar = false;

db_menu_values = []; db_menu_items = []; clusClas = []; plotX = []; plotY = []; plotZ = []; timerVal = tic;
classes2plot = []; classes2plotSubset = []; fieldsMenu = []; table_metrics = []; ii = []; history_classification = [];
brainRegions_list = []; brainRegions_acronym = []; cell_class_count = [];  customCellPlot3 = 1; customCellPlot4 = 1; customPlotOptions = '';
customCellPlot1 = ''; customPlotHistograms = 0; plotAcgFit = 0; clasLegend = 0; Colorval = 1; plotClas = []; plotClas11 = [];
colorMenu = []; groups2plot = []; groups2plot2 = []; plotClasGroups2 = []; monoSynDisp = ''; customCellPlot2 = '';
plotClasGroups = [];  plotClas2 = [];  SWR_batch = []; general = []; plotAverage_nbins = 40; table_fieldsNames = {};
cellsExcitatory = []; cellsInhibitory = []; cellsInhibitory_subset = []; cellsExcitatory_subset = []; ii_history = 1;
subsetPlots1 = []; subsetPlots2 = []; subsetPlots3 = []; subsetPlots4 = []; subsetPlots5 = []; subsetPlots6 = [];
tSNE_metrics = []; BatchMode = false; ClickedCells = []; classificationTrackChanges = []; time_waveforms_zscored = []; spikes = [];
spikesPlots = []; globalZoom = cell(1,9); createStruct.Interpreter = 'tex'; createStruct.WindowStyle = 'modal'; events = [];
fig2_axislimit_x = []; fig2_axislimit_y = []; fig3_axislimit_x = []; fig3_axislimit_y = []; groundTruthSelection = []; subsetGroundTruth = [];
positionsTogglebutton = [[1 29 27 13];[29 29 27 13];[1 15 27 13];[29 15 27 13];[1 1 27 13];[29 1 27 13]]; dispTags = []; dispTags2 = [];
incoming = []; outgoing = []; connections = []; plotName = ''; db = {}; plotConnections = [1 1 1]; tableDataOrder = []; 
set(groot, 'DefaultFigureVisible', 'on'), maxFigureSize = get(groot,'ScreenSize'); UI.settings.figureSize = [50, 50, min(1200,maxFigureSize(3)-50), min(800,maxFigureSize(4)-50)];

if isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

CellExplorerVersion = 1.40;

UI.fig = figure('Name',['Cell Explorer v' num2str(CellExplorerVersion)],'NumberTitle','off','renderer','opengl', 'MenuBar', 'None','PaperOrientation','landscape','windowscrollWheelFcn',@ScrolltoZoomInPlot,'KeyPressFcn', {@keyPress});
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

if exist('db_credentials') == 2
    bz_database = db_credentials;
    if ~strcmp(bz_database.rest_api.username,'user')
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
    try
        cd(basepath)
    catch
        warning('basepath not available')
        close(UI.fig)
        return
    end
    if exist(fullfile(pwd,'session.mat'),'file')
        disp('Cell-Explorer: Loading local session.mat')
        load('session.mat')
        if isempty(session.spikeSorting.relativePath)
            clusteringpath = '';
        else
            clusteringpath = session.spikeSorting.relativePath{1};
        end
        if exist(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']),'file')
            load(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']));
%             load(fullfile(basepath,clusteringpath,'cell_metrics.mat'));
            cell_metrics.general.saveAs = 'cell_metrics';
            initializeSession;
        else
            cell_metrics = [];
            warning('Cell-Explorer: No cell_metrics exist in base folder. Trying to load from the database')
            if enableDatabase
                LoadDatabaseSession;
                if ~exist('cell_metrics') || isempty(cell_metrics)
                    disp('No dataset selected - closing the Cell Explorer')
                    if ishandle(UI.fig)
                        close(UI.fig)
                    end
                    cell_metrics = [];
                    return
                end
            else
                warning('Neither session.mat or cell_metrics.mat exist in base folder')
                if ishandle(UI.fig)
                    close(UI.fig)
                end
                return
            end
        end
        
    elseif exist(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']))
        disp('Loading local cell_metrics')
        load(fullfile(basepath,clusteringpath,[basename,'.cell_metrics.cellinfo.mat']));
%         load('cell_metrics.mat')
        initializeSession
    else
        if enableDatabase
            LoadDatabaseSession;
            if ~exist('cell_metrics') || isempty(cell_metrics)
                disp('No dataset selected - closing the Cell Explorer')
                if ishandle(UI.fig)
                    close(UI.fig)
                end
                cell_metrics = [];
                return
            end
            
        else
            warning('Neither session.mat or cell_metrics.mat exist in base folder')
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

UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
uimenu(UI.menu.file.topMenu,menuLabel,'Load metrics from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
uimenu(UI.menu.file.topMenu,menuLabel,'Edit DB credentials and repositories',menuSelectedFcn,@editDBcredentials);
uimenu(UI.menu.file.topMenu,menuLabel,'Load metrics from database',menuSelectedFcn,@LoadDatabaseSession,'Accelerator','D');
UI.menu.file.save = uimenu(UI.menu.file.topMenu,menuLabel,'Save classification',menuSelectedFcn,@buttonSave,'Separator','on','Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitCellExplorer,'Separator','on','Accelerator','W');

UI.menu.navigation.topMenu = uimenu(UI.fig,menuLabel,'Navigation');
UI.menu.navigation.goToCell = uimenu(UI.menu.navigation.topMenu,menuLabel,'Go to cell',menuSelectedFcn,@goToCell,'Accelerator','G');
UI.menu.navigation.previousSelectedCell = uimenu(UI.menu.navigation.topMenu,menuLabel,'Go to previous select cell [backspace]',menuSelectedFcn,@ii_history_reverse);

UI.menu.edit.topMenu = uimenu(UI.fig,menuLabel,'Classification');
UI.menu.edit.undoClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Undo classification',menuSelectedFcn,@undoClassification,'Accelerator','Z');
UI.menu.edit.buttonBrainRegion = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign brain region',menuSelectedFcn,@buttonBrainRegion,'Accelerator','B');
UI.menu.edit.buttonLabel = uimenu(UI.menu.edit.topMenu,menuLabel,'Assign label',menuSelectedFcn,@buttonLabel,'Accelerator','L');
UI.menu.edit.performClassification = uimenu(UI.menu.edit.topMenu,menuLabel,'Agglomerative hierarchical cluster tree classification',menuSelectedFcn,@performClassification);
UI.menu.edit.reclassify_celltypes = uimenu(UI.menu.edit.topMenu,menuLabel,'Reclassify cells',menuSelectedFcn,@reclassify_celltypes,'Accelerator','R');
UI.menu.edit.adjustDeepSuperficial = uimenu(UI.menu.edit.topMenu,menuLabel,'adjust Deep-Superficial for session',menuSelectedFcn,@adjustDeepSuperficial1);

UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'Display');
UI.menu.display.adjustGUI = uimenu(UI.menu.display.topMenu,menuLabel,'Adjust number of subplots in GUI',menuSelectedFcn,@AdjustGUI,'Accelerator','N');
UI.menu.display.showHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Toggle remainig menubar',menuSelectedFcn,@showHideMenu,'Accelerator','M');
UI.menu.display.significanceMetricsMatrix = uimenu(UI.menu.display.topMenu,menuLabel,'Calculate significance metrics matrix',menuSelectedFcn,@SignificanceMetricsMatrix,'Accelerator','K');
UI.menu.display.redefineMetrics = uimenu(UI.menu.display.topMenu,menuLabel,'Define metrics used in t-SNE',menuSelectedFcn,@tSNE_redefineMetrics,'Accelerator','T');
UI.menu.display.firingRateMapShowLegend = uimenu(UI.menu.display.topMenu,menuLabel,'show legend in firing rate maps',menuSelectedFcn,@toggleFiringRateMapShowLegend);
if UI.settings.firingRateMap.showLegend; UI.menu.display.firingRateMapShowLegend.Checked = 'on'; end
UI.menu.display.showHeatmap = uimenu(UI.menu.display.topMenu,menuLabel,'show heatmap in firing rate maps',menuSelectedFcn,@toggleHeatmapFiringRateMaps);
if UI.settings.firingRateMap.showHeatmap; UI.menu.display.showHeatmap.Checked = 'on'; end
UI.menu.display.firingRateMapShowHeatmapColorbar = uimenu(UI.menu.display.topMenu,menuLabel,'show colorbar in heatmaps in firing rate maps',menuSelectedFcn,@toggleFiringRateMapShowHeatmapColorbar);
if UI.settings.firingRateMap.showHeatmapColorbar; UI.menu.display.firingRateMapShowHeatmapColorbar.Checked = 'on'; end

UI.menu.waveform.topMenu = uimenu(UI.fig,menuLabel,'Waveform');
UI.menu.waveform.showMetrics = uimenu(UI.menu.waveform.topMenu,menuLabel,'Show waveform metrics',menuSelectedFcn,@showWaveformMetrics);

UI.menu.ACG.topMenu = uimenu(UI.fig,menuLabel,'ACG');
UI.menu.ACG.window.ops(1) = uimenu(UI.menu.ACG.topMenu,menuLabel,'30 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(2) = uimenu(UI.menu.ACG.topMenu,menuLabel,'100 msec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.window.ops(3) = uimenu(UI.menu.ACG.topMenu,menuLabel,'1 sec',menuSelectedFcn,@buttonACG);
UI.menu.ACG.showFit = uimenu(UI.menu.ACG.topMenu,menuLabel,'Show fit',menuSelectedFcn,@toggleACGfit,'Separator','on','Accelerator','F');

UI.menu.MonoSyn.topMenu = uimenu(UI.fig,menuLabel,'MonoSyn');
UI.menu.MonoSyn.plotConns.ops(1) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Show in custom plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.MonoSyn.plotConns.ops(2) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Show in Classic plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.MonoSyn.plotConns.ops(3) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Show in tSNE plot','Checked','on',menuSelectedFcn,@updatePlotConnections);
UI.menu.MonoSyn.showConn.ops(1) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'None',menuSelectedFcn,@buttonMonoSyn,'Separator','on');
UI.menu.MonoSyn.showConn.ops(2) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Selected',menuSelectedFcn,@buttonMonoSyn);
UI.menu.MonoSyn.showConn.ops(3) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Upstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.MonoSyn.showConn.ops(4) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.MonoSyn.showConn.ops(5) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Up & downstream',menuSelectedFcn,@buttonMonoSyn);
UI.menu.MonoSyn.showConn.ops(6) = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'All',menuSelectedFcn,@buttonMonoSyn);
UI.menu.MonoSyn.showConn.ops(find(strcmp(synConnectOptions,UI.settings.monoSynDispIn))).Checked = 'on';

UI.menu.MonoSyn.highlightExcitatory = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Highlight excitatory cells','Separator','on',menuSelectedFcn,@highlightExcitatoryCells,'Accelerator','E');
UI.menu.MonoSyn.highlightInhibitory = uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Highlight inhibitory cells',menuSelectedFcn,@highlightInhibitoryCells,'Accelerator','I');
uimenu(UI.menu.MonoSyn.topMenu,menuLabel,'Adjust monosynaptic connections',menuSelectedFcn,@adjustMonoSyn,'Separator','on');

UI.menu.groundTruth.topMenu = uimenu(UI.fig,menuLabel,'Ground truth');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Perform ground truth cell type classification',menuSelectedFcn,@performGroundTruthClassification,'Accelerator','Y');
uimenu(UI.menu.groundTruth.topMenu,menuLabel,'Load ground truth cell types',menuSelectedFcn,@loadGroundTruth,'Accelerator','U');

UI.menu.tableData.topMenu = uimenu(UI.fig,menuLabel,'Table data');
UI.menu.tableData.ops(1) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell metrics',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(2) = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.ops(3) = uimenu(UI.menu.tableData.topMenu,menuLabel,'None',menuSelectedFcn,@buttonShowMetrics);
UI.menu.tableData.column1 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 1','Separator','on');
for i = 1:length(tableDataSortingList)
    UI.menu.tableData.column1_ops(i) = uimenu(UI.menu.tableData.column1,menuLabel,tableDataSortingList{i},menuSelectedFcn,@setColumn1_metric);
end
UI.menu.tableData.column1_ops(find(strcmp(tableDataColumn1,tableDataSortingList))).Checked = 'on';

UI.menu.tableData.column2 = uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list metric 2');
for i = 1:length(tableDataSortingList)
    UI.menu.tableData.column2_ops(i) = uimenu(UI.menu.tableData.column2,menuLabel,tableDataSortingList{i},menuSelectedFcn,@setColumn2_metric);
end
UI.menu.tableData.column2_ops(find(strcmp(tableDataColumn2,tableDataSortingList))).Checked = 'on';

uimenu(UI.menu.tableData.topMenu,menuLabel,'Cell list sorting:','Separator','on');
for i = 1:length(tableDataSortingList)
    UI.menu.tableData.sortingList(i) = uimenu(UI.menu.tableData.topMenu,menuLabel,tableDataSortingList{i},menuSelectedFcn,@setTableDataSorting);
end
UI.menu.tableData.sortingList(find(strcmp(tableDataSortBy,tableDataSortingList))).Checked = 'on';


UI.menu.spikeData.topMenu = uimenu(UI.fig,menuLabel,'Spikes');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Load spike data',menuSelectedFcn,@defineSpikesPlots,'Accelerator','A');
uimenu(UI.menu.spikeData.topMenu,menuLabel,'Edit spike plot',menuSelectedFcn,@editSelectedSpikePlot,'Accelerator','J');

UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
uimenu(UI.menu.session.topMenu,menuLabel,'Open directory of current session',menuSelectedFcn,@openSessionDirectory,'Accelerator','C');
uimenu(UI.menu.session.topMenu,menuLabel,'Open current session in the Buzsaki lab web DB',menuSelectedFcn,@openSessionInWebDB);
uimenu(UI.menu.session.topMenu,menuLabel,'View metadata for current session',menuSelectedFcn,@viewSessionMetaData);

UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
uimenu(UI.menu.help.topMenu,menuLabel,'About the Cell Explorer',menuSelectedFcn,@aboutDialog);
uimenu(UI.menu.help.topMenu,menuLabel,'Show keyboard shortcuts',menuSelectedFcn,@HelpDialog,'Separator','on','Accelerator','H');
uimenu(UI.menu.help.topMenu,menuLabel,'Open preferences',menuSelectedFcn,@LoadPreferences,'Accelerator','P');
uimenu(UI.menu.help.topMenu,menuLabel,'Open the Cell Explorer''s wiki page on Github',menuSelectedFcn,@openWiki,'Separator','on','Accelerator','V');

if UI.settings.plotWaveformMetrics; UI.menu.waveform.showMetrics.Checked = 'on'; end

if strcmp(UI.settings.acgType,'Normal')
    UI.menu.ACG.window.ops(2).Checked = 'On';
elseif strcmp(UI.settings.acgType,'Wide')
    UI.menu.ACG.window.ops(1).Checked = 'On';
else
    UI.menu.ACG.window.ops(3).Checked = 'On';
end


%% % % % % % % % % % % % % % % % % % % % % %
% UI panels
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

%% % % % % % % % % % % % % % % % % % % % % %
% UI content
% % % % % % % % % % % % % % % % % % % % % %
% UI menu panels
UI.panel.navigation = uipanel('Title','Navigation','TitlePosition','centertop','Position',[0.895 0.927 0.1 0.065],'Units','normalized');
UI.panel.cellAssignment = uipanel('Title','Cell assignments','TitlePosition','centertop','Position',[0.895 0.643 0.1 0.275],'Units','normalized');
UI.panel.displaySettings = uipanel('Title','Display Settings','TitlePosition','centertop','Position',[0.895 0.165 0.1 0.323],'Units','normalized');
UI.panel.custom = uipanel('Title','Plot selection','TitlePosition','centertop','Position',[0.005 0.54 0.09 0.435],'Units','normalized');
% UI.panel.loadSave = uipanel('Title','File handling','TitlePosition','centertop','Position',[0.895 0.01 0.1 0.095],'Units','normalized');

% UI cell assignment tabs
UI.panel.tabgroup1 = uitabgroup('Position',[0.895 0.493 0.1 0.142],'Units','normalized');
UI.tabs.tags = uitab(UI.panel.tabgroup1,'Title','Tags');
UI.tabs.deepsuperficial = uitab(UI.panel.tabgroup1,'Title','D/S');

% UI display settings tabs
UI.panel.tabgroup2 = uitabgroup('Position',[0.895 0.005 0.1 0.16],'Units','normalized');
UI.tabs.dispTags = uitab(UI.panel.tabgroup2,'Title','-Tags');
UI.tabs.dispTags2 = uitab(UI.panel.tabgroup2,'Title','+Tags');


% % % % % % % % % % % % % % % % % % % %
% Message log
% % % % % % % % % % % % % % % % % % % %

UI.popupmenu.log = uicontrol('Style','popupmenu','Position',[60 2 300 10],'Units','normalized','String',{},'HorizontalAlignment','left','FontSize',10);
MsgLog('Welcome to the Cell Explorer. Please check the Help menu to learn keyboard shortcuts, adjust preferences, or to visit the wiki')


% % % % % % % % % % % % % % % % % % % %
% Navigation panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Navigation buttons
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[2 2 15 12],'Units','normalized','String','<','Callback',@(src,evnt)back,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[18 2 18 12],'Units','normalized','String','GoTo','Callback',@(src,evnt)goToCell,'KeyPressFcn', {@keyPress});
UI.pushbutton.next = uicontrol('Parent',UI.panel.navigation,'Style','pushbutton','Position',[37 2 15 12],'Units','normalized','String','>','Callback',@(src,evnt)advance,'KeyPressFcn', {@keyPress});


% % % % % % % % % % % % % % % % % % % %
% Cell assignments panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Cell classification
colored_string = DefineCellTypeList;
UI.listbox.cellClassification = uicontrol('Parent',UI.panel.cellAssignment,'Style','listbox','Position',[2 54 50 45],'Units','normalized','String',colored_string,'max',1,'min',1,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)listCellType(),'KeyPressFcn', {@keyPress});

% Poly-select and adding new cell type
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 36 24 15],'Units','normalized','String','O Polygon','Callback',@(src,evnt)GroupSelectFromPlot,'KeyPressFcn', {@keyPress});
uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[27 36 25 15],'Units','normalized','String','+ Cell-type','Callback',@(src,evnt)AddNewCellType,'KeyPressFcn', {@keyPress});

% Brain region
UI.pushbutton.brainRegion = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 20 50 15],'Units','normalized','String',['Region: ', cell_metrics.brainRegion{ii}],'Callback',@(src,evnt)buttonBrainRegion,'KeyPressFcn', {@keyPress});

% Custom labels
UI.pushbutton.labels = uicontrol('Parent',UI.panel.cellAssignment,'Style','pushbutton','Position',[2 3 50 15],'Units','normalized','String',['Label: ', cell_metrics.labels{ii}],'Callback',@(src,evnt)buttonLabel,'KeyPressFcn', {@keyPress});


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

UI.listbox.cellTypes = uicontrol('Parent',UI.panel.displaySettings,'Style','listbox','Position',[2 73 50 50],'Units','normalized','String',strcat(UI.settings.cellTypes,' (',cell_class_count,')'),'max',10,'min',1,'Value',1:length(UI.settings.cellTypes),'Callback',@(src,evnt)buttonSelectSubset(),'KeyPressFcn', {@keyPress});

% Number of plots
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 62 20 10],'Units','normalized','String','Layout','HorizontalAlignment','left');
UI.popupmenu.plotCount = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[20 61 32 10],'Units','normalized','String',{'GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6'},'max',1,'min',1,'Value',3,'Callback',@(src,evnt)AdjustGUIbutton,'KeyPressFcn', {@keyPress});

% #1 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 52 20 10],'Units','normalized','String','1. View','HorizontalAlignment','left');
UI.popupmenu.customplot1 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 51 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleWaveformsPlot,'KeyPressFcn', {@keyPress});
if any(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); UI.popupmenu.customplot1.Value = find(strcmp(UI.settings.customCellPlotIn1,UI.popupmenu.customplot1.String)); else; UI.popupmenu.customplot1.Value = 1; end
customCellPlot1 = customPlotOptions{UI.popupmenu.customplot1.Value};

% #2 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 42 25 10],'Units','normalized','String','2. View','HorizontalAlignment','left');
UI.popupmenu.customplot2 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 41 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',1,'Callback',@(src,evnt)toggleACGplot,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); UI.popupmenu.customplot2.Value = find(strcmp(UI.settings.customCellPlotIn2,UI.popupmenu.customplot2.String)); else; UI.popupmenu.customplot2.Value = 4; end
customCellPlot2 = customPlotOptions{UI.popupmenu.customplot2.Value};

% #3 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 32 35 10],'Units','normalized','String','3. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot3 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 31 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); UI.popupmenu.customplot3.Value = find(strcmp(UI.settings.customCellPlotIn3,UI.popupmenu.customplot3.String)); else; UI.popupmenu.customplot3.Value = 1; end
customCellPlot3 = customPlotOptions{UI.popupmenu.customplot3.Value};

% #4 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 22 35 10],'Units','normalized','String','4. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot4 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 21 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc2,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); UI.popupmenu.customplot4.Value = find(strcmp(UI.settings.customCellPlotIn4,UI.popupmenu.customplot4.String)); else; UI.popupmenu.customplot4.Value = 1; end
customCellPlot4 = customPlotOptions{UI.popupmenu.customplot4.Value};

% #5 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 12 35 10],'Units','normalized','String','5. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot5 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 11 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc3,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); UI.popupmenu.customplot5.Value = find(strcmp(UI.settings.customCellPlotIn5,UI.popupmenu.customplot5.String)); else; UI.popupmenu.customplot5.Value = 2; end
customCellPlot5 = customPlotOptions{UI.popupmenu.customplot5.Value};

% #6 custom view
uicontrol('Parent',UI.panel.displaySettings,'Style','text','Position',[1 2 35 10],'Units','normalized','String','6. View','HorizontalAlignment','left','KeyPressFcn', {@keyPress});
UI.popupmenu.customplot6 = uicontrol('Parent',UI.panel.displaySettings,'Style','popupmenu','Position',[14 1 38 10],'Units','normalized','String',customPlotOptions,'max',1,'min',1,'Value',7,'Callback',@(src,evnt)customCellPlotFunc4,'KeyPressFcn', {@keyPress});
if find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); UI.popupmenu.customplot6.Value = find(strcmp(UI.settings.customCellPlotIn6,UI.popupmenu.customplot6.String)); else; UI.popupmenu.customplot5.Value = 3; end
customCellPlot6 = customPlotOptions{UI.popupmenu.customplot6.Value};

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

% % % % % % % % % % % % % % % % % % % %
% File handling panel (right side)
% % % % % % % % % % % % % % % % % % % %

% Save classification
% UI.pushbutton.save = uicontrol('Parent',UI.panel.loadSave,'Style','pushbutton','Position',[2 2 50 12],'Units','normalized','String','Save classification','Callback',@(src,evnt)buttonSave,'KeyPressFcn', {@keyPress});
if ~isempty(classificationTrackChanges)
    UI.menu.file.save.ForegroundColor = [0.6350 0.0780 0.1840];
end

% % % % % % % % % % % % % % % % % % % %
% Custom plot panel (left side)
% % % % % % % % % % % % % % % % % % % %

% Custom plotting menues
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 159 20 10],'Units','normalized','String','X data','HorizontalAlignment','left');
UI.checkbox.logx = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 162 18 10],'Units','normalized','String','Log X','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotXLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.xData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 152 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotXdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotX(),'KeyPressFcn', {@keyPress});

uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 139 20 10],'Units','normalized','String','Y data','HorizontalAlignment','left');
UI.checkbox.logy = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 142 18 10],'Units','normalized','String','Log Y','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotYLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.yData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 132 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotYdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotY(),'KeyPressFcn', {@keyPress});

UI.checkbox.showz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 122 24 10],'Units','normalized','String','Z data','HorizontalAlignment','left','Callback',@(src,evnt)buttonPlot3axis(),'KeyPressFcn', {@keyPress});
UI.checkbox.logz = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[28 122 18 10],'Units','normalized','String','Log Z','HorizontalAlignment','right','Callback',@(src,evnt)buttonPlotZLog(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 112 44 10],'Units','normalized','String',fieldsMenu,'Value',find(strcmp(fieldsMenu,UI.settings.plotZdata)),'HorizontalAlignment','left','Callback',@(src,evnt)buttonPlotZ(),'KeyPressFcn', {@keyPress});
UI.popupmenu.zData.Enable = 'Off';
UI.checkbox.logz.Enable = 'Off';

% Custom plot
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 100 45 10],'Units','normalized','String','Plot style','HorizontalAlignment','left');
UI.popupmenu.metricsPlot = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 92 44 10],'Units','normalized','String',{'Scatter plot','+ Smooth histograms','+ Stairs histograms'},'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)togglePlotHistograms,'KeyPressFcn', {@keyPress});

% Custom colors
uicontrol('Parent',UI.panel.custom,'Style','text','Position',[5 80 45 10],'Units','normalized','String','Color group','HorizontalAlignment','left');
UI.popupmenu.groups = uicontrol('Parent',UI.panel.custom,'Style','popupmenu','Position',[2 72 44 10],'Units','normalized','String',colorMenu,'Value',1,'HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(1),'KeyPressFcn', {@keyPress});
UI.checkbox.legend = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[24 82 22 10],'Units','normalized','String','Legend','HorizontalAlignment','right','Callback',@(src,evnt)buttonDispLegend(),'KeyPressFcn', {@keyPress});
UI.listbox.groups = uicontrol('Parent',UI.panel.custom,'Style','listbox','Position',[3 22 42 50],'Units','normalized','String',{'Type 1','Type 2','Type 3'},'max',10,'min',1,'Value',1,'Callback',@(src,evnt)buttonSelectGroups(),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.groups = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 12 44 10],'Units','normalized','String','Group by cell types','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress},'Visible','Off');
UI.checkbox.compare = uicontrol('Parent',UI.panel.custom,'Style','checkbox','Position',[3 2 44 10],'Units','normalized','String','Compare to other','HorizontalAlignment','left','Callback',@(src,evnt)buttonGroups(0),'KeyPressFcn', {@keyPress});
UI.checkbox.legend.Value = UI.settings.dispLegend;

% % % % % % % % % % % % % % % % % % % %
% Metrics table and title
% % % % % % % % % % % % % % % % % % %

% Table with metrics for selected cell
UI.table = uitable(UI.fig,'Data',[table_fieldsNames,table_metrics(1,:)'],'Units','normalized','Position',[0.005 0.008 0.09 0.53],'ColumnWidth',{100,  100},'columnname',{'Metrics',''},'RowName',[],'CellSelectionCallback',@ClicktoSelectFromTable,'CellEditCallback',@EditSelectFromTable,'KeyPressFcn', {@keyPress}); % [10 10 150 575] {85, 46} %
% UI.popupmenu.tableType = uicontrol('Style','popupmenu','Position',[3 2 50 10],'Units','normalized','String',{'Table: Cell metrics','Table: Cell types','Table: None'},'max',1,'min',1,'Value',1,'Callback',@(src,evnt)buttonShowMetrics(),'KeyPressFcn', {@keyPress});

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

% Benchmark with display time in seconds for most recent plot call
UI.benchmark = uicontrol('Style','text','Position',[3 410 150 10],'Units','normalized','String','Benchmark','HorizontalAlignment','left','FontSize',13,'ForegroundColor',[0.3 0.3 0.3]);

% Title with details about the selected cell and current session
UI.title = uicontrol('Style','text','Position',[130 410 350 10],'Units','normalized','String',{'Cell details'},'HorizontalAlignment','center','FontSize',13);

% Maximazing figure to full screen
if ~verLessThan('matlab', '9.4')
    set(UI.fig,'WindowState','maximize'), drawnow nocallbacks; 
else
    drawnow nocallbacks; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks; 
end

%% % % % % % % % % % % % % % % % % % % % % %
% Main loop of UI
% % % % % % % % % % % % % % % % % % % % % %
pause(0.01)
while ii <= size(cell_metrics.troughToPeak,2)
    
    % breaking if figure has been closed
    if ~ishandle(UI.fig)
        break
    end
    
    % Keeping track of selected cells
    if ii_history(end) ~= ii
        ii_history = [ii_history,ii];
    end
    
    % Instantiates batch metrics
    if BatchMode
        batchIDs = cell_metrics.batchIDs(ii);
        general = cell_metrics.general.batch{batchIDs};
    else
        batchIDs = 1;
        general = cell_metrics.general;
    end
    
    % Resetting list of highlighted cells
    ClickedCells = [];
    
    % Resetting zoom levels for subplots
    globalZoom = cell(1,9);
    
    % Updating putative cell type listbox
    UI.listbox.cellClassification.Value = clusClas(ii);
    
    % Defining the subset of cells to display
    subset = find(ismember(clusClas,classes2plot));
    
    % Updating ground truth tags
    if isfield(UI.tabs,'groundTruthClassification')
        updateGroundTruth
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
        subset = setdiff(subset,tagFilter);
    end
    if any(dispTags2==1)
        tagFilter2 = find(cellfun(@(X) ~isempty(X), cell_metrics.tags));
        filter = [];
        for i = 1:length(tagFilter2)
            filter(i) = any(strcmp(cell_metrics.tags{tagFilter2(i)},{UI.settings.tags{dispTags2==1}}));
        end
        tagFilter2 = tagFilter2(find(filter));
        subset = intersect(subset,tagFilter2);
    end
    if ~isempty(groups2plot2) && Colorval ~=1
        if UI.checkbox.groups.Value == 0
            subset2 = find(ismember(plotClas11,groups2plot2));
            plotClas = plotClas11;
        else
            subset2 = find(ismember(plotClas2,groups2plot2));
        end
        subset = intersect(subset,subset2);
    end
    
    % Regrouping cells if comparison checkbox is checked
    if UI.checkbox.compare.Value == 1
        plotClas = ones(1,length(plotClas));
        plotClas(subset) = 2;
        subset = 1:length(plotClas);
        classes2plotSubset = unique(plotClas);
        plotClasGroups = {'Other cells','Selected cells'};
    else
        classes2plotSubset = intersect(plotClas(subset),classes2plot);
    end
    
    % Defining putative connections for selected cells
    if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory')
        putativeSubset = find(sum(ismember(cell_metrics.putativeConnections.excitatory,subset)')==2);
    else
        putativeSubset=[];
        incoming = [];
        outgoing = [];
        connections = [];
    end
    if ~isempty(putativeSubset)
        % Inbound
        a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
        % Outbound
        a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
        
        if any(strcmp(monoSynDisp, {'Selected','All'}))
            inbound = find(a2 == ii);
            outbound = find(a1 == ii);
        else
            inbound = [];
            outbound = [];
        end
        
        if any(strcmp(monoSynDisp, {'Upstream','Up & downstream'}))
            kkk = 1;
            inbound = find(a2 == ii);
            while ~isempty(inbound) && any(ismember(a2, a1(inbound))) && kkk < 10
                inbound = [inbound;find(ismember(a2, a1(inbound)))];
                kkk = kkk + 1;
            end
        end
        if any(strcmp(monoSynDisp, {'Downstream','Up & downstream'}))
            kkk = 1;
            outbound = find(a1 == ii);
            while ~isempty(outbound) && any(ismember(a1, a2(outbound))) && kkk < 10
                outbound = [outbound;find(ismember(a1, a2(outbound)))];
                kkk = kkk + 1;
            end
        end
        incoming = a1(inbound);
        outgoing = a2(outbound);
        connections = [incoming;outgoing];
    end
    
    % Defining synaptically identified projecting cell
    if UI.settings.displayExcitatory && ~isempty(cellsExcitatory)
        cellsExcitatory_subset = intersect(subset,cellsExcitatory);
    end
    if UI.settings.displayInhibitory && ~isempty(cellsInhibitory)
        cellsInhibitory_subset = intersect(subset,cellsInhibitory);
    end
    
    % Group display definition
    if UI.checkbox.compare.Value == 1
        clr = UI.settings.cellTypeColors(intersect(classes2plotSubset,plotClas(subset)),:);
    elseif Colorval == 1 ||  UI.checkbox.groups.Value == 1
        clr = UI.settings.cellTypeColors(intersect(classes2plot,plotClas(subset)),:);
    else
        clr = hsv(length(nanUnique(plotClas(subset))))*0.8;
        if isnan(clr)
            clr = UI.settings.cellTypeColors(1,:);
        end
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
    
    
    % % % % % % % % % % % % % % % % % % % % % %
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
        
        if UI.settings.layout == 1
            set(subfig_ax(1),'LooseInset',get(subfig_ax(1),'TightInset'))
        end
        hold on
        xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
        set(subfig_ax(1), 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'),
        xlim auto, ylim auto, zlim auto
        % Setting linear/log scale
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
            % 2D plot
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
            
            if  plotConnections(1) == 1 & ~isempty(putativeSubset)
                switch monoSynDisp
                    case 'All'
                        xdata = [plotX(a1);plotX(a2);nan(1,length(a2))];
                        ydata = [plotY(a1);plotY(a2);nan(1,length(a2))];
                        plot(xdata(:),ydata(:),'-k','HitTest','off')
                    case {'Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(inbound)
                            xdata = [plotX(a1(inbound));plotX(a2(inbound));nan(1,length(a2(inbound)))];
                            ydata = [plotY(a1(inbound));plotY(a2(inbound));nan(1,length(a2(inbound)))];
                            plot(xdata(:),ydata(:),'-ob','HitTest','off')
                        end
                        if ~isempty(outbound)
                            xdata = [plotX(a1(outbound));plotX(a2(outbound));nan(1,length(a2(outbound)))];
                            ydata = [plotY(a1(outbound));plotY(a2(outbound));nan(1,length(a2(outbound)))];
                            plot(xdata(:),ydata(:),'-m','HitTest','off')
                        end
                end
            end
            plot(plotX(ii), plotY(ii),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off')
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off')
            axis tight
            
            % Ground truth cell types
            if groundTruthSelection
                idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
                for jj = 1:length(idGroundTruth)
                    plot(plotX(subsetGroundTruth{idGroundTruth(jj)}), plotY(subsetGroundTruth{idGroundTruth(jj)}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                end
            end
            
        else
            % 3D plot
            view([az,el]);
            if UI.settings.plotZLog == 1
                set(subfig_ax(1), 'ZScale', 'log')
            else
                set(subfig_ax(1), 'ZScale', 'linear')
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
            
            % Plotting synaptic projections
            if  plotConnections(1) == 1 & ~isempty(putativeSubset)
                switch monoSynDisp
                    case 'All'
                        xdata = [plotX(a1);plotX(a2);nan(1,length(a2))];
                        ydata = [plotY(a1);plotY(a2);nan(1,length(a2))];
                        zdata = [plotZ(a1);plotZ(a2);nan(1,length(a2))];
                        plot3(xdata(:),ydata(:),zdata(:),'k','HitTest','off')
                    case {'Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(inbound)
                            xdata = [plotX(a1(inbound));plotX(a2(inbound));nan(1,length(a2(inbound)))];
                            ydata = [plotY(a1(inbound));plotY(a2(inbound));nan(1,length(a2(inbound)))];
                            zdata = [plotZ(a1(inbound));plotZ(a2(inbound));nan(1,length(a2(inbound)))];
                            plot3(xdata(:),ydata(:),zdata(:),'b','HitTest','off')
                        end
                        if ~isempty(outbound)
                            xdata = [plotX(a1(outbound));plotX(a2(outbound));nan(1,length(a2(outbound)))];
                            ydata = [plotY(a1(outbound));plotY(a2(outbound));nan(1,length(a2(outbound)))];
                            zdata = [plotZ(a1(outbound));plotZ(a2(outbound));nan(1,length(a2(outbound)))];
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
                for jj = 1:length(subsetGroundTruth)
                    plot(plotX(subsetGroundTruth{jj}), plotY(subsetGroundTruth{jj}), plotZ(subsetGroundTruth{jj}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
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
        axis tight
        [az,el] = view;
        
        % Setting legend
        if ~isempty(subset) && UI.settings.layout == 1 && UI.settings.dispLegend == 1
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northeast','Box','off','AutoUpdate','off');
        end
        
    elseif customPlotHistograms == 1
        % Double kernel-histogram with scatter plot
        hold off
        if ~isempty(clr)
            h_scatter = scatterhist(plotX(subset),plotY(subset),'Group',plotClas(subset),'Kernel','on','Marker','.','MarkerSize',[12],'LineStyle',{'-'},'Parent',UI.panel.subfig_ax1,'Legend','off','Color',clr); hold on % ,'Style','stairs'
            set(h_scatter(1).Children,'HitTest','off')
            set(h_scatter(1),'ButtonDownFcn',@ClicktoSelectFromPlot)
            axis(h_scatter(1),'tight');
            plot(plotX(ii), plotY(ii),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off')
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off') % 'Parent',h_scatter(1),
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
            
            % Ground truth cell types
            if groundTruthSelection
                for jj = 1:length(subsetGroundTruth)
                    plot(plotX(subsetGroundTruth{jj}), plotY(subsetGroundTruth{jj}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                end
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
            set(h_scatter(1).Children,'HitTest','off')
            axis(h_scatter(1),'tight');
            set(h_scatter(1),'ButtonDownFcn',@ClicktoSelectFromPlot)
            plot(plotX(ii), plotY(ii),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off')
            plot(plotX(ii), plotY(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off') % ,'Parent',h_scatter(1)
            xlabel(plotX_title, 'Interpreter', 'none'), ylabel(plotY_title, 'Interpreter', 'none'),
            if length(unique(plotClas(subset)))==2
                G1 = plotX(subset);
                G = findgroups(plotClas(subset));
                if ~isempty(subset(G==1)) && length(subset(G==2))>0
                    [h,p] = kstest2(plotX(subset(G==1)),plotX(subset(G==2)));
                    text(1.04,0.01,['h=', num2str(h), ', p=',num2str(p,3)],'Units','normalized','Rotation',90,'Interpreter', 'none','Interpreter', 'none')
                    [h,p] = kstest2(plotY(subset(G==1)),plotY(subset(G==2)));
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
            
            % Ground truth cell types
            if groundTruthSelection
                for jj = 1:length(subsetGroundTruth)
                    plot(plotX(subsetGroundTruth{jj}), plotY(subsetGroundTruth{jj}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
                end
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
        
        xlim(fig2_axislimit_x), ylim(fig2_axislimit_y)
        set(subfig_ax(2), 'YScale', 'log');
        if ~isempty(clr)
            legendScatter = gscatter(cell_metrics.troughToPeak(subset) * 1000, cell_metrics.burstIndex_Royer2012(subset), plotClas(subset), clr,'',20,'off');
            set(legendScatter,'HitTest','off')
        end
        if UI.settings.displayExcitatory && ~isempty(cellsExcitatory_subset)
            plot(cell_metrics.troughToPeak(cellsExcitatory_subset) * 1000, cell_metrics.burstIndex_Royer2012(cellsExcitatory_subset),'^k', 'HitTest','off')
        end
        if UI.settings.displayInhibitory && ~isempty(cellsInhibitory_subset)
            plot(cell_metrics.troughToPeak(cellsInhibitory_subset) * 1000, cell_metrics.burstIndex_Royer2012(cellsInhibitory_subset),'ok', 'HitTest','off')
        end
        
        % Plotting synaptic connections
        if ~isempty(putativeSubset) && plotConnections(2) == 1
            switch monoSynDisp
                case 'All'
                    xdata = [cell_metrics.troughToPeak(a1) * 1000;cell_metrics.troughToPeak(a2) * 1000;nan(1,length(a2))];
                    ydata = [cell_metrics.burstIndex_Royer2012(a1);cell_metrics.burstIndex_Royer2012(a2);nan(1,length(a2))];
                    plot(xdata(:),ydata(:),'-k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(inbound)
                        xdata = [cell_metrics.troughToPeak(a1(inbound))* 1000;cell_metrics.troughToPeak(a2(inbound))* 1000;nan(1,length(a2(inbound)))];
                        ydata = [cell_metrics.burstIndex_Royer2012(a1(inbound));cell_metrics.burstIndex_Royer2012(a2(inbound));nan(1,length(a2(inbound)))];
                        plot(xdata,ydata,'-ob','HitTest','off')
                    end
                    if ~isempty(outbound)
                        xdata = [cell_metrics.troughToPeak(a1(outbound))* 1000;cell_metrics.troughToPeak(a2(outbound))* 1000;nan(1,length(a2(outbound)))];
                        ydata = [cell_metrics.burstIndex_Royer2012(a1(outbound));cell_metrics.burstIndex_Royer2012(a2(outbound));nan(1,length(a2(outbound)))];
                        plot(xdata(:),ydata(:),'-om','HitTest','off')
                    end
            end
        end
        plot(cell_metrics.troughToPeak(ii) * 1000, cell_metrics.burstIndex_Royer2012(ii),'xw', 'LineWidth', 3., 'MarkerSize',22,'Parent', subfig_ax(2),'HitTest','off');
        plot(cell_metrics.troughToPeak(ii) * 1000, cell_metrics.burstIndex_Royer2012(ii),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'Parent', subfig_ax(2),'HitTest','off');
        
        % Ground truth cell types
        if groundTruthSelection
            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
            for jj = 1:length(idGroundTruth)
                plot(cell_metrics.troughToPeak(subsetGroundTruth{idGroundTruth(jj)}) * 1000, cell_metrics.burstIndex_Royer2012(subsetGroundTruth{idGroundTruth(jj)}),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
            end
        end
        % Setting legend
        if ~isempty(subset) && UI.settings.layout >2 && UI.settings.dispLegend == 1
            legend(legendScatter, {plotClasGroups{nanUnique(plotClas(subset))}},'Location','northwest','Box','off','AutoUpdate','off');
        end
        
        ylabel('Burst Index (Royer 2012)'); xlabel('Trough-to-Peak (µs)'),
        
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
        
        xlim(fig3_axislimit_x), ylim(fig3_axislimit_y), xlabel('t-SNE')
        
        if ~isempty(putativeSubset) && plotConnections(3) == 1
            plotX1 = tSNE_metrics.plot(:,1)';
            plotY1 = tSNE_metrics.plot(:,2)';
            
            switch monoSynDisp
                case 'All'
                    xdata = [plotX1(a1);plotX1(a2);nan(1,length(a2))];
                    ydata = [plotY1(a1);plotY1(a2);nan(1,length(a2))];
                    plot(xdata(:),ydata(:),'-k','HitTest','off')
                case {'Selected','Upstream','Downstream','Up & downstream'}
                    if ~isempty(inbound)
                        xdata = [plotX1(a1(inbound));plotX1(a2(inbound));nan(1,length(a2(inbound)))];
                        ydata = [plotY1(a1(inbound));plotY1(a2(inbound));nan(1,length(a2(inbound)))];
                        plot(xdata,ydata,'-ob','HitTest','off')
                    end
                    if ~isempty(outbound)
                        xdata = [plotX1(a1(outbound));plotX1(a2(outbound));nan(1,length(a2(outbound)))];
                        ydata = [plotY1(a1(outbound));plotY1(a2(outbound));nan(1,length(a2(outbound)))];
                        plot(xdata(:),ydata(:),'-om','HitTest','off')
                    end
            end
        end
        plot(tSNE_metrics.plot(ii,1), tSNE_metrics.plot(ii,2),'xw', 'LineWidth', 3., 'MarkerSize',22,'HitTest','off');
        plot(tSNE_metrics.plot(ii,1), tSNE_metrics.plot(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
        
        % Ground truth cell types
        if groundTruthSelection
            idGroundTruth = find(~cellfun(@isempty,subsetGroundTruth));
            for jj = 1:length(idGroundTruth)
                plot(tSNE_metrics.plot(subsetGroundTruth{idGroundTruth(jj)},1), tSNE_metrics.plot(subsetGroundTruth{idGroundTruth(jj)},2),UI.settings.groundTruthMarkers{jj},'HitTest','off','LineWidth', 1.5, 'MarkerSize',8);
            end
        end
        
        % Setting legend
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
    
    % Bechmarking the UI
    UI.benchmark.String = [num2str(toc(timerVal),3),' sec'];
   
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
        col = UI.settings.cellTypeColors(clusClas(ii),:);

        if strcmp(customPlotSelection,'Single waveform')
            
            % Single waveform with std
            if isfield(cell_metrics.waveforms,'filt_std')
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.filt{ii}+cell_metrics.waveforms.filt_std{ii},flip(cell_metrics.waveforms.filt{ii}-cell_metrics.waveforms.filt_std{ii})],'black','EdgeColor','none','FaceAlpha',.2)
            end
            plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.filt{ii}, 'color', col,'linewidth',2), grid on
            xlabel('Time (ms)'), ylabel('Voltage (µV)'), title('Filtered waveform'), axis tight,
            
            % Show waveform metrics
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
            
        elseif strcmp(customPlotSelection,'All waveforms')
            % All waveforms (z-scored) colored according to cell type
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.filt_zscored(:,set1);nan(1,length(set1))];
                plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            % selected cell in black
            plot(time_waveforms_zscored, cell_metrics.waveforms.filt_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Time (ms)'), title('Waveform zscored'), axis tight,
            
        elseif strcmp(customPlotSelection,'All waveforms (image)')
            
            % All waveforms, zscored and shown in a imagesc plot
            % Sorted according to trough-to-peak
            [~,troughToPeakSorted] = sort(cell_metrics.troughToPeak(subset));
            imagesc(time_waveforms_zscored, [1:length(subset)], cell_metrics.waveforms.filt_zscored(:,subset(troughToPeakSorted))','HitTest','off'),
            colormap hot(512), xlabel('Time (ms)'), title('Waveform zscored (image)'), axis tight,
            [~,idx] = find(subset(troughToPeakSorted) == ii);
            % selected cell highlighted in white
            if ~isempty(idx)
                plot([time_waveforms_zscored(1),time_waveforms_zscored(end)],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
            end
            
        elseif strcmp(customPlotSelection,'Single raw waveform')
            % Single waveform with std
            
            if isfield(cell_metrics.waveforms,'raw_std') & ~isempty(cell_metrics.waveforms.raw{ii})
                patch([cell_metrics.waveforms.time{ii},flip(cell_metrics.waveforms.time{ii})], [cell_metrics.waveforms.raw{ii}+cell_metrics.waveforms.raw_std{ii},flip(cell_metrics.waveforms.raw{ii}-cell_metrics.waveforms.raw_std{ii})],'black','EdgeColor','none','FaceAlpha',.2)
                plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2), grid on
            elseif ~isempty(cell_metrics.waveforms.raw{ii})
                plot(cell_metrics.waveforms.time{ii}, cell_metrics.waveforms.raw{ii}, 'color', col,'linewidth',2), grid on
            else
                text(0.5,0.5,'No raw waveform for this cell','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
            xlabel('Time (ms)'), ylabel('Voltage (µV)'), title('Raw waveform'), axis tight,
            
        elseif strcmp(customPlotSelection,'All raw waveforms')
            % All raw waveforms (z-scored) colored according to cell type
            for jj = 1:length(classes2plotSubset)
                set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                xdata = repmat([time_waveforms_zscored,nan(1,1)],length(set1),1)';
                ydata = [cell_metrics.waveforms.raw_zscored(:,set1);nan(1,length(set1))];
                plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
            end
            % selected cell in black
            plot(time_waveforms_zscored, cell_metrics.waveforms.raw_zscored(:,ii), 'color', 'k','linewidth',2,'HitTest','off'), grid on
            xlabel('Time (ms)'), title('Raw waveforms zscored'), axis tight,
            
        elseif strcmp(customPlotSelection,'tSNE of waveforms')
            
            % t-SNE scatter-plot with all waveforms calculated from the z-scored
            % waveforms
            legendScatter4 = gscatter(tSNE_metrics.filtWaveform(subset,1), tSNE_metrics.filtWaveform(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter4,'HitTest','off')
            title('Waveforms - tSNE visualization'), axis tight, xlabel(''), ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            plot(tSNE_metrics.filtWaveform(ii,1), tSNE_metrics.filtWaveform(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of raw waveforms')
            
            % t-SNE scatter-plot with all raw waveforms calculated from the z-scored
            % waveforms
            legendScatter4 = gscatter(tSNE_metrics.rawWaveform(subset,1), tSNE_metrics.rawWaveform(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter4,'HitTest','off')
            title('Raw waveforms - tSNE visualization'), axis tight, xlabel(''), ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22,'HitTest','off');
            plot(tSNE_metrics.rawWaveform(ii,1), tSNE_metrics.rawWaveform(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20,'HitTest','off');
            
        elseif strcmp(customPlotSelection,'CCGs (image)')
            
            % CCGs for selected cell with other cell pairs from the same
            % session. The ACG for the selected cell is shown first
            if isfield(general,'ccg') & ~isempty(subset)
                if BatchMode
                    subset1 = find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii));
                else
                    subset1 = 1:general.cellCount;
                end
                subset1 = cell_metrics.UID(subset(subset1));
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
                switch monoSynDisp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        if ~isempty(outbound)
                            [~,y_pos,~] = intersect(subset1,cell_metrics.UID(a2(outbound)));
                            plot(1.045*Xdata(3)*ones(size(outbound)),y_pos,'.m', 'HitTest','off', 'MarkerSize',12)
                        end
                        if ~isempty(inbound)
                            [~,y_pos,~] = intersect(subset1,cell_metrics.UID(a1(inbound)));
                            plot(1.045*Xdata(3)*ones(size(inbound)),y_pos,'.b', 'HitTest','off', 'MarkerSize',12)
                        end
                        xlim([Xdata(1)*1.05,Xdata(end)])
                end
            else
                text(0.5,0.5,'No cross-correlogram for this cell with selected filter','FontWeight','bold','HorizontalAlignment','center','Interpreter', 'none')
            end
            
        elseif strcmp(customPlotSelection,'Single ACG') % ACGs
            
            % Auto-correlogram for selected cell. Colored according to
            % cell-type. Normalized firing rate. X-axis according to
            % selected option
            if strcmp(UI.settings.acgType,'Normal')
                bar_from_patch([-100:100]'/2, cell_metrics.acg.narrow(:,ii),col)
                %                 bar([-100:100]/2,cell_metrics.acg.narrow(:,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-50:10:50]),xlim([-50,50])
            elseif strcmp(UI.settings.acgType,'Narrow')
                bar_from_patch([-30:30]'/2, cell_metrics.acg.narrow(41+30:end-40-30,ii),col)
                %                 bar([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-15:5:15]),xlim([-15,15])
            else
                bar_from_patch([-500:500]', cell_metrics.acg.wide(:,ii),col)
                %                 bar([-500:500],cell_metrics.acg.wide(:,ii),1,'FaceColor',col,'EdgeColor',col)
                xticks([-500:100:500]),xlim([-500,500])
            end
            % ACG fit with a triple-exponential
            if plotAcgFit
                a = cell_metrics.acg_tau_decay(ii); b = cell_metrics.acg_tau_rise(ii); c = cell_metrics.acg_c(ii); d = cell_metrics.acg_d(ii);
                e = cell_metrics.acg_asymptote(ii); f = cell_metrics.acg_refrac(ii); g = cell_metrics.acg_tau_burst(ii); h = cell_metrics.acg_h(ii);
                x = 1:0.2:50;
                fiteqn = max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0);
                plot([-flip(x),x],[flip(fiteqn),fiteqn],'linewidth',2,'color',[0,0,0,0.7])
            end
            
            ax5 = axis; grid on, set(gca, 'Layer', 'top')
            plot([0 0], [ax5(3) ax5(4)],'color',[.1 .1 .3]); plot([ax5(1) ax5(2)],cell_metrics.firingRate(ii)*[1 1],'--k')
            xlabel('Time (ms)'), ylabel('Rate (Hz)'),title(['Autocorrelogram - firing rate: ', num2str(cell_metrics.firingRate(ii),3),'Hz'])
            
        elseif strcmp(customPlotSelection,'All ACGs')
            
            % All ACGs. Colored by to cell-type.
            if strcmp(UI.settings.acgType,'Normal')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    xdata = repmat([[-100:100]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(:,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-100:100]/2,cell_metrics.acg.narrow(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-50:10:50]),xlim([-50,50])
                
            elseif strcmp(UI.settings.acgType,'Narrow')
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    xdata = repmat([[-30:30]/2,nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.narrow(41+30:end-40-30,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-30:30]/2,cell_metrics.acg.narrow(41+30:end-40-30,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-15:5:15]),xlim([-15,15])
                
            else
                for jj = 1:length(classes2plotSubset)
                    set1 = intersect(find(plotClas==classes2plotSubset(jj)), subset);
                    xdata = repmat([[-500:500],nan(1,1)],length(set1),1)';
                    ydata = [cell_metrics.acg.wide(:,set1);nan(1,length(set1))];
                    plot(xdata(:),ydata(:), 'color', [clr(jj,:),0.2],'HitTest','off')
                end
                plot([-500:500],cell_metrics.acg.wide(:,ii), 'color', 'k','linewidth',1.5,'HitTest','off')
                xticks([-500:100:500]),xlim([-500,500])
            end
            xlabel('Time (ms)'), ylabel('Rate (Hz)'), title(['All ACGs'])
            
        elseif strcmp(customPlotSelection,'All ACGs (image)')
            
            % All ACGs shown in an image (z-scored). Sorted by the burst-index from Royer 2012
            [~,burstIndexSorted] = sort(cell_metrics.burstIndex_Royer2012(subset));
            [~,idx] = find(subset(burstIndexSorted) == ii);
            if strcmp(UI.settings.acgType,'Normal')
                imagesc([-100:100]/2, [1:length(subset)], cell_metrics.acg.narrow_zscored(:,subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-50,50],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
            elseif strcmp(UI.settings.acgType,'Narrow')
                imagesc([-30:30]/2, [1:length(subset)], cell_metrics.acg.narrow_zscored(41+30:end-40-30,subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-15,15],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
            else
                imagesc([-500:500], [1:length(subset)], cell_metrics.acg.wide_zscored(:,subset(burstIndexSorted))','HitTest','off')
                if ~isempty(idx)
                    plot([-500,500],[idx-0.5,idx-0.5;idx+0.5,idx+0.5]','w','HitTest','off')
                end
            end
            plot([0,0],[0.5,length(subset)+0.5],'w','HitTest','off')
            colormap hot(512), xlabel('Time (ms)'), title(['All ACGs (image)']), axis tight
            
        elseif strcmp(customPlotSelection,'tSNE of narrow ACGs')
            
            % t-SNE scatter-plot with all ACGs. Calculated from the narrow
            % ACG (-50ms:0.5ms:50ms). Colored by cell-type.
            legendScatter5 = gscatter(tSNE_metrics.acg2(subset,1), tSNE_metrics.acg2(subset,2), plotClas(subset), clr,'',20,'off');
            set(legendScatter5,'HitTest','off')
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            % selected cell highlighted with black cross
            plot(tSNE_metrics.acg2(ii,1), tSNE_metrics.acg2(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.acg2(ii,1), tSNE_metrics.acg2(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'tSNE of wide ACGs')
            
            % t-SNE scatter-plot with all ACGs. Calculated from the wide
            % ACG (-500ms:1ms:500ms). Colored by cell-type.
            if ~isempty(clr)
                legendScatter5 = gscatter(tSNE_metrics.acg1(subset,1), tSNE_metrics.acg1(subset,2), plotClas(subset), clr,'',20,'off');
                set(legendScatter5,'HitTest','off')
            end
            title('Autocorrelogram - tSNE visualization'), axis tight, xlabel(''),ylabel('')
            plot(tSNE_metrics.acg1(ii,1), tSNE_metrics.acg1(ii,2),'xw', 'LineWidth', 3, 'MarkerSize',22, 'HitTest','off');
            plot(tSNE_metrics.acg1(ii,1), tSNE_metrics.acg1(ii,2),'xk', 'LineWidth', 1.5, 'MarkerSize',20, 'HitTest','off');
            
        elseif strcmp(customPlotSelection,'Sharp wave-ripple')
            
            % Displays the average sharp wave-ripple for the spike group of the
            % selected cell. The peak channel of the cell is highlighted
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
                ht3 = text(0.98,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90,'Interpreter', 'none')
            else
                text(0.5,0.5,'No sharp wave-ripple defined for this session','FontWeight','bold','HorizontalAlignment','center')
            end
            
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
                switch monoSynDisp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.firingRateMaps.(firingRateMapName){[a2(outbound);a1(inbound)]});
                        subsetPlots.subset = [a2(outbound);a1(inbound)];
                        if ~isempty(outbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMaps.(firingRateMapName){a2(outbound)}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(inbound)
                            plot(x_bins,horzcat(cell_metrics.firingRateMaps.(firingRateMapName){a1(inbound)}),'color', 'k', 'HitTest','off')
                        end
                end
                axis tight, ax6 = axis; grid on,
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
                if isfield(general.firingRateMaps,firingRateMapName) & isfield(general.firingRateMaps.(firingRateMapName),'boundaries')
                    boundaries = general.firingRateMaps.(firingRateMapName).boundaries;
                    plot([1;1] * boundaries, [ax6(3) ax6(4)],'--','color','k', 'HitTest','off');
                end
            else
                text(0.5,0.5,'No firing rate map for this cell','FontWeight','bold','HorizontalAlignment','center')
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
                text(0.5,0.5,['No ',firingRateMapName,' firing rate map for this cell'],'FontWeight','bold','HorizontalAlignment','center')
            end
            title(customPlotSelection, 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,{'psth_'}) & ~contains(customPlotSelection,{'spikes_'})
            eventName = customPlotSelection(6:end);
            if isfield(cell_metrics.psth,eventName) && ~isempty(cell_metrics.psth.(eventName){ii})
                psth_response = cell_metrics.psth.(eventName){ii};
                
                if isfield(general.psth,eventName) & isfield(general.psth.(eventName),'x_bins')
                    x_bins = general.psth.(eventName).x_bins(:);
                else
                    x_bins = [1:size(psth_response,1)];
                end
                plot(x_bins,psth_response,'color', 'k','linewidth',2, 'HitTest','off')
                
                switch monoSynDisp
                    case {'All','Selected','Upstream','Downstream','Up & downstream'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = horzcat(cell_metrics.psth.(eventName){[a2(outbound);a1(inbound)]});
                        subsetPlots.subset = [a2(outbound);a1(inbound)];
                        if ~isempty(outbound)
                            plot(x_bins,horzcat(cell_metrics.psth.(eventName){a2(outbound)}),'color', 'm', 'HitTest','off')
                        end
                        if ~isempty(inbound)
                            plot(x_bins,horzcat(cell_metrics.psth.(customPlotSelection){a1(inbound)}),'color', 'k', 'HitTest','off')
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
                text(0.5,0.5,'No PSTH for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            
            title(eventName, 'Interpreter', 'none'), xlabel('Time (s)'),ylabel('Rate (Hz)')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            
        elseif contains(customPlotSelection,'events_')
            eventName = customPlotSelection(8:end);
            if isfield(cell_metrics.events,eventName) && ~isempty(cell_metrics.events.(eventName){ii})
                rippleCorrelogram = cell_metrics.events.(eventName){ii};
                
                if isfield(general.events,eventName) & isfield(general.events.(eventName),'x_bins')
                    x_bins = general.events.(eventName).x_bins(:);
                else
                    x_bins = [1:length(rippleCorrelogram)];
                end
                if ~isempty(putativeSubset)
                    switch monoSynDisp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.events.(eventName){[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.events.(eventName){a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.events.(eventName){a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                plot(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'), xlabel('time'),ylabel('Voltage')
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No event histogram for this cell','FontWeight','bold','HorizontalAlignment','center')
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
                    switch monoSynDisp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.manipulations.(eventName){[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.manipulations.(eventName){a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.manipulations.(eventName){a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                plot(x_bins,rippleCorrelogram,'color', col,'linewidth',2, 'HitTest','off'), xlabel('time'),ylabel('Voltage')
                axis tight, ax6 = axis; grid on
                plot([0, 0], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
                set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            else
                text(0.5,0.5,'No manipulation histogram for this cell','FontWeight','bold','HorizontalAlignment','center')
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
                    switch monoSynDisp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.responseCurves.(responseCurvesName){[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){a1(inbound)}),'color', 'k', 'HitTest','off')
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
                text(0.5,0.5,'No reponse curve for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title([responseCurvesName ' response'], 'Interpreter', 'none')
            
        elseif contains(customPlotSelection,'responseCurves_') & contains(customPlotSelection,'Phase')
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
                    switch monoSynDisp
                        case {'All','Selected','Upstream','Downstream','Up & downstream'}
                            subsetPlots.xaxis = x_bins;
                            subsetPlots.yaxis = horzcat(cell_metrics.responseCurves.(responseCurvesName){[a2(outbound);a1(inbound)]});
                            subsetPlots.subset = [a2(outbound);a1(inbound)];
                            if ~isempty(outbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){a2(outbound)}),'color', 'm', 'HitTest','off')
                            end
                            if ~isempty(inbound)
                                plot(x_bins,horzcat(cell_metrics.responseCurves.(responseCurvesName){a1(inbound)}),'color', 'k', 'HitTest','off')
                            end
                    end
                end
                axis tight, ax6 = axis; grid on,
            else
                text(0.5,0.5,'No Phase Response for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            title([responseCurvesName, ' response'],'Interpreter', 'none'), xlabel('Phase'), ylabel('Probability')
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
            xticks([-pi,-pi/2,0,pi/2,pi]),xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'}),xlim([-pi,pi])
            
        elseif contains(customPlotSelection,{'spikes_'}) && ~isempty(spikesPlots.(customPlotSelection).event)
            
            % Spike raster plots from the raw spike data with event data
            out = CheckSpikes(batchIDs);
            
            if out && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).x) && isfield(spikes{batchIDs},spikesPlots.(customPlotSelection).y)
                out = CheckEvents(batchIDs,spikesPlots.(customPlotSelection).event);
                
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
                    text(0.5,0.5,'No event data for this cell','FontWeight','bold','HorizontalAlignment','center')
                end
            else
                text(0.5,0.5,'No data for this cell','FontWeight','bold','HorizontalAlignment','center')
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
                    if ~isempty(subset) && UI.settings.dispLegend == 1
                        legend(legendScatter, {},'Location','northeast','Box','off','AutoUpdate','off');
                    end
                    axis tight
                else
                    text(0.5,0.5,'No state data for this cell','FontWeight','bold','HorizontalAlignment','center')
                end
            else
                text(0.5,0.5,'No data for this cell','FontWeight','bold','HorizontalAlignment','center')
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
                text(0.5,0.5,'No data for this cell','FontWeight','bold','HorizontalAlignment','center')
            end
            xlabel(spikesPlots.(customPlotSelection).x_label), ylabel(spikesPlots.(customPlotSelection).y_label), title(customPlotSelection,'Interpreter', 'none')
            
        else
            
            customCellPlotNum = find(strcmp(customPlotSelection, customPlotOptions));
            plotData = cell_metrics.(customPlotOptions{customCellPlotNum});
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
            
            if isnumeric(cell_metrics.(customPlotOptions{customCellPlotNum}))
                switch monoSynDisp
                    case {'All'}
                        subsetPlots.xaxis = x_bins;
                        subsetPlots.yaxis = cell_metrics.(customPlotOptions{customCellPlotNum})(:,a2(outbound));
                        subsetPlots.subset = a2(outbound);
                        plot(x_bins,cell_metrics.(customPlotOptions{customCellPlotNum})(:,a2(outbound)),'color', [0,0,0,.5])
                    case {'Selected','Upstream','Downstream','Up & downstream'}
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
                        text(boundaries, ax6(4)*ones(1,length(boundaries_labels)),boundaries_labels, 'HitTest','off','HorizontalAlignment','left','VerticalAlignment','top','Rotation',-90,'Interpreter', 'none');
                    end
                end
                
            end
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto', 'YTickMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickMode', 'auto', 'ZTickLabelMode', 'auto')
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function loadFromFile(~,~)
        [file,path] = uigetfile('*.mat','Please select a cell_metrics.mat file','cell_metrics.mat');
        if ~isequal(file,0)
            cd(path)
            load(file);
            initializeSession;
            try
                
            catch
                MsgLog(['Error loading cell metrics:' path, file],2)
                return
            end
            uiresume(UI.fig);
            cell_metrics.general.saveAs = file(1:end-4);
            MsgLog('Session loaded succesful',2)
            
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function highlightExcitatoryCells(~,~)
        % Highlight excitatory cells
        UI.settings.displayExcitatory = ~UI.settings.displayExcitatory;
        MsgLog(['Toggle highlighting excitatory cells (triangles). Count: ', num2str(length(cellsExcitatory))])
        if UI.settings.displayExcitatory
            UI.menu.MonoSyn.highlightExcitatory.Checked = 'on';
        else
            UI.menu.MonoSyn.highlightExcitatory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function highlightInhibitoryCells(~,~)
        % Highlight inhibitory cells
        UI.settings.displayInhibitory = ~UI.settings.displayInhibitory;
        MsgLog(['Toggle highlighting inhibitory cells (circles), Count: ', num2str(length(cellsInhibitory))])
        if UI.settings.displayInhibitory
            UI.menu.MonoSyn.highlightInhibitory.Checked = 'on';
        else
            UI.menu.MonoSyn.highlightInhibitory.Checked = 'off';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function adjustMonoSyn(~,~)
        adjustMonoSyn_UpdateMetrics(cell_metrics)
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updatePlotConnections(src,event)
        if strcmp(src.Checked,'on')
            plotConnections(src.Position) = 0;
            UI.menu.MonoSyn.plotConns.ops(src.Position).Checked = 'off';
        else
            plotConnections(src.Position) = 1;
            UI.menu.MonoSyn.plotConns.ops(src.Position).Checked = 'on';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function showWaveformMetrics(~,~)
        if UI.settings.plotWaveformMetrics==0
            UI.menu.waveform.showMetrics.Checked = 'on';
            UI.settings.plotWaveformMetrics = 1;
        else
            UI.menu.waveform.showMetrics.Checked = 'off';
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

    function tSNE_redefineMetrics(~,~)
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
        [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
        if ~isempty(indx)
            f_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
            X = cell2mat(cellfun(@(X) cell_metrics.(X),list_tSNE_metrics(indx),'UniformOutput',false));
            UI.settings.tSNE_metrics = list_tSNE_metrics(indx);
            
            X(isnan(X) | isinf(X)) = 0;
            waitbar(0.1,f_waitbar,'Calculating tSNE space...')
            
            tSNE_metrics.plot = tsne(X','Standardize',true,'Distance',UI.settings.tSNE_dDistanceMetric,'Exaggeration',10);            
            
            if size(tSNE_metrics.plot,2)==1
                tSNE_metrics.plot = [tSNE_metrics.plot,tSNE_metrics.plot];
            end
            waitbar(1,f_waitbar,'tSNE space calculations complete.')
            uiresume(UI.fig);
            if ishandle(f_waitbar)
                close(f_waitbar)
            end
            MsgLog('tSNE space calculations complete.');
        end
        fig3_axislimit_x = [min(tSNE_metrics.plot(:,1)), max(tSNE_metrics.plot(:,1))];
        fig3_axislimit_y = [min(tSNE_metrics.plot(:,2)), max(tSNE_metrics.plot(:,2))];
    end

% % % % % % % % % % % % % % % % % % % % % %

    function adjustDeepSuperficial1(~,~)
        % Adjust Deep-Superfical assignment for session and update cell_metrics
        deepSuperficialfromRipple = adjustDeepSuperficial(cell_metrics.general.basepaths{batchIDs},general.basename);
        if ~isempty(deepSuperficialfromRipple)
            subset = find(cell_metrics.batchIDs == batchIDs);
            saveStateToHistory(subset)
            for j = subset
                cell_metrics.deepSuperficial(j) = deepSuperficialfromRipple.channelClass(cell_metrics.maxWaveformCh1(j));
                cell_metrics.deepSuperficialDistance(j) = deepSuperficialfromRipple.channelDistance(cell_metrics.maxWaveformCh1(j));
            end
            for j = 1:length(UI.settings.deepSuperficial)
                cell_metrics.deepSuperficial_num(strcmp(cell_metrics.deepSuperficial,UI.settings.deepSuperficial{j}))=j;
            end
            
            if BatchMode
                SWR_batch{cell_metrics.batchIDs(ii)} = deepSuperficialfromRipple;
            else
                SWR_batch = deepSuperficialfromRipple;
            end
            if BatchMode && isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs{batchIDs};
            else
                saveAs = 'cell_metrics';
            end
            matpath = fullfile(cell_metrics.general.paths{batchIDs},[cell_metrics.general.basenames{batchIDs}, '.',saveAs,'.cellinfo.mat'])
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
            [~,ia,~] = intersect(list_tSNE_metrics,UI.settings.tSNE_metrics);
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
        % Updating tags
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
        % Updating putativeCellType field
        [C, ~, ic] = unique(clusClas,'sorted');
        for i = 1:length(C)
            cell_metrics.putativeCellType(find(ic==i)) = repmat({UI.settings.cellTypes{C(i)}},sum(ic==i),1);
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function updateGroundTruth
        % Updating groundTruth tags
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
            MsgLog('No other cells with selected class',2);
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
            MsgLog('No other cells with selected class',2);
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

    function buttonACG(src,event)
        if src.Position == 1
            UI.settings.acgType = 'Narrow';
            UI.menu.ACG.window.ops(1).Checked = 'on';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'off';
        elseif src.Position == 2
            UI.settings.acgType = 'Normal';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(2).Checked = 'on';
            UI.menu.ACG.window.ops(3).Checked = 'off';
        elseif src.Position == 3
            UI.settings.acgType = 'Wide';
            UI.menu.ACG.window.ops(2).Checked = 'off';
            UI.menu.ACG.window.ops(1).Checked = 'off';
            UI.menu.ACG.window.ops(3).Checked = 'on';
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function buttonMonoSyn(src,event)
        UI.menu.MonoSyn.showConn.ops(1).Checked = 'off';
        UI.menu.MonoSyn.showConn.ops(2).Checked = 'off';
        UI.menu.MonoSyn.showConn.ops(3).Checked = 'off';
        UI.menu.MonoSyn.showConn.ops(4).Checked = 'off';
        UI.menu.MonoSyn.showConn.ops(5).Checked = 'off';
        UI.menu.MonoSyn.showConn.ops(6).Checked = 'off';
        if src.Position == 4
            monoSynDisp = 'None';
        elseif src.Position == 5
            monoSynDisp = 'Selected';
        elseif src.Position == 6
            monoSynDisp = 'Upstream';
        elseif src.Position == 7
            monoSynDisp = 'Downstream';
        elseif src.Position == 8
            monoSynDisp = 'Up & downstream';
        elseif src.Position == 9
            monoSynDisp = 'All';
        end
        UI.menu.MonoSyn.showConn.ops(src.Position-3).Checked = 'on';
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ScrolltoZoomInPlot(h,event,direction)
        % Called when scrolling/zooming in the cell inspector.
        % Checks first, if a plot is underneath the curser
        h2 = overobj2('flat','visible','on');
        
        %v if ~isempty(h2) && strcmp(h2.Type,'uipanel') && strcmp(h2.Title,'') && ~isempty(h2.Children) && any(ismember(subfig_ax, h2.Children))>0 && any(find(ismember(subfig_ax, h2.Children)) == [1:9])
        if isfield(UI,'panel') & any(ismember([UI.panel.subfig_ax1,UI.panel.subfig_ax2,UI.panel.subfig_ax3,UI.panel.subfig_ax4,UI.panel.subfig_ax5,UI.panel.subfig_ax6,UI.panel.subfig_ax7,UI.panel.subfig_ax8,UI.panel.subfig_ax9], h2))
            handle34 = h2.Children(end);
            um_axes = get(handle34,'CurrentPoint');
            if any(ismember(subfig_ax, h2.Children))>0 && any(find(ismember(subfig_ax, h2.Children)) == [1:9])
                axnum = find(ismember(subfig_ax, h2.Children));
            else
                axnum = 1;
            end
            
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
            
            % Saves the initial x/y limits
            if isempty(globalZoom{axnum})
                globalZoom{axnum} = [b;c;d];
            end
            zoomInFactor = 0.7;
            zoomOutFactor = 1.8;
            
            % Applies global/horizontal/vertical zoom according to the mouse position.
            % Further applies zoom direction according to scroll-wheel direction
            % Zooming out have global boundaries set by the initial x/y limits
            if ~exist('direction')
                if event.VerticalScrollCount<0
                    direction = 1;
                else
                    direction = -1;
                end
            else
                %                 [x,y]=gpos(h2.Children(end));
            end
            %             if event.VerticalScrollCount<0
            if direction == 1
                % Negative scroll direction (zoom in)
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1
                        ylim([y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1
                        xlim([x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1
                        xlim([x1,x2]);
                    end
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1
                        ylim([y1,y2]);
                    end
                    z1 = max(globalZoom{axnum}(3,1),w-diff(d)/2*zoomInFactor);
                    z2 = min(globalZoom{axnum}(3,2),w+diff(d)/2*zoomInFactor);
                    if z2>z1
                        zlim([z1,z2]);
                    end
                end
            elseif direction == -1
                % Positive scrolling direction (zoom out)
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*zoomOutFactor);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*zoomOutFactor);
                    if y1 == globalZoom{axnum}(2,1)
                        y2 = min([globalZoom{axnum}(2,2),y1 + diff(c)*2]);
                    end
                    if y2 == globalZoom{axnum}(2,2)
                        y1 = max([globalZoom{axnum}(2,1),y2 - diff(c)*2]);
                    end
                    if y2>y1
                        ylim([y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*zoomOutFactor);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*zoomOutFactor);
                    if x1 == globalZoom{axnum}(1,1)
                        x2 = min([globalZoom{axnum}(1,2),x1 + diff(b)*2]);
                    end
                    if x2 == globalZoom{axnum}(1,2)
                        x1 = max([globalZoom{axnum}(1,1),x2 - diff(b)*2]);
                    end
                    if x2>x1
                        xlim([x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom{axnum}(1,1),u-diff(b)/2*zoomOutFactor);
                    x2 = min(globalZoom{axnum}(1,2),u+diff(b)/2*zoomOutFactor);
                    y1 = max(globalZoom{axnum}(2,1),v-diff(c)/2*zoomOutFactor);
                    y2 = min(globalZoom{axnum}(2,2),v+diff(c)/2*zoomOutFactor);
                    z1 = max(globalZoom{axnum}(3,1),w-diff(d)/2*zoomOutFactor);
                    z2 = min(globalZoom{axnum}(3,2),w+diff(d)/2*zoomOutFactor);
                    
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
                    
                    if z1 == globalZoom{axnum}(3,1)
                        z2 = min([globalZoom{axnum}(3,2),z1 + diff(d)*2]);
                    end
                    if z2 == globalZoom{axnum}(3,2)
                        z1 = max([globalZoom{axnum}(3,1),z2 - diff(d)*2]);
                    end
                    
                    if x2>x1
                        xlim([x1,x2]);
                    end
                    if y2>y1
                        ylim([y1,y2]);
                    end
                    if z2>z1
                        zlim([z1,z2]);
                    end
                end
            else
                % Reset zoom
                xlim(globalZoom{axnum}(1,:));
                ylim(globalZoom{axnum}(2,:));
                zlim(globalZoom{axnum}(3,:));
            end
        end
        
        function hoverCallback(src,evt)
            
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function ClicktoSelectFromPlot(h,~)
        % Handles mouse clicks on the plots. Determines the selected plot
        % and the coordinates (u,v) within the plot. Finally calls
        % according to which mouse button that was clicked.
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
                selectCellsForGroupAction
        end
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
            ii = subset(tableDataOrder(event.Indices(1)));
            uiresume(UI.fig);
        end
    end

    function EditSelectFromTable(src, event)
        if any(ClickedCells == subset(tableDataOrder(event.Indices(1))))
            ClickedCells = ClickedCells(~(ClickedCells == subset(tableDataOrder(event.Indices(1)))));
        else
            ClickedCells = [ClickedCells,subset(tableDataOrder(event.Indices(1)))];
        end
        if length(ClickedCells)<11
            UI.benchmark.String = [num2str(length(ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(ClickedCells(1:10)),'\s+',', ')), ' ...'];
        end
    end
%

% % % % % % % % % % % % % % % % % % % % % %

    function updateTableClickedCells
        if UI.settings.metricsTable==2
            %             UI.table.Data(:,1) = {false};
            [~,ia,~] = intersect(subset(tableDataOrder),ClickedCells);
            UI.table.Data(ia,1) = {true};
        end
        if length(ClickedCells)<11
            UI.benchmark.String = [num2str(length(ClickedCells)), ' cells selected: ' num2str(regexprep(num2str(ClickedCells),'\s+',', ')) ''];
        else
            UI.benchmark.String = [num2str(length(ClickedCells)), ' cells selected: ', num2str(regexprep(num2str(ClickedCells(1:10)),'\s+',', ')), ' ...'];
        end
    end


% % % % % % % % % % % % % % % % % % % % % %

    function highlightSelectedCells
        %         axes(UI.panel.subfig_ax1);
        %         UI.panel.subfig_ax1
        axes(subfig_ax(1))
        plot(plotX(ClickedCells),plotY(ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        
        axes(subfig_ax(2))
        plot(cell_metrics.troughToPeak(ClickedCells)*1000,cell_metrics.burstIndex_Royer2012(ClickedCells),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',8)
        
        axes(subfig_ax(3))
        plot(tSNE_metrics.plot(ClickedCells,1),tSNE_metrics.plot(ClickedCells,2),'sk','MarkerFaceColor',[1,0,1],'HitTest','off','LineWidth', 1.5,'markersize',9)
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
                    
                case 'tSNE of raw waveforms'
                    
                    [~,idx] = min(hypot(tSNE_metrics.rawWaveform(subset,1)-u,tSNE_metrics.rawWaveform(subset,2)-v));
                    iii = subset(idx);
                    if highlight
                        text(tSNE_metrics.rawWaveform(iii,1),tSNE_metrics.rawWaveform(iii,2),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'All waveforms'
                    
                    x1 = time_waveforms_zscored'*ones(1,length(subset));
                    y1 = cell_metrics.waveforms.filt_zscored(:,subset);
                    [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(time_waveforms_zscored)))+1;
                    iii = subset(In);
                    [~,time_index] = min(abs(time_waveforms_zscored-u));
                    if highlight
                        plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'All raw waveforms'
                    
                    x1 = time_waveforms_zscored'*ones(1,length(subset));
                    y1 = cell_metrics.waveforms.raw_zscored(:,subset);
                    [~,In] = min(hypot(x1(:)-u,y1(:)-v));
                    In = unique(floor(In/length(time_waveforms_zscored)))+1;
                    iii = subset(In);
                    [~,time_index] = min(abs(time_waveforms_zscored-u));
                    if highlight
                        plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                        text(time_waveforms_zscored(time_index),y1(time_index,In),num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14)
                    end
                    
                case 'All waveforms (image)'
                    [~,troughToPeakSorted] = sort(cell_metrics.troughToPeak(subset));
                    if round(v) > 0 && round(v) <= length(subset)
                        iii = subset(troughToPeakSorted(round(v)));
                        if highlight
                            plot([time_waveforms_zscored(1),time_waveforms_zscored(end)],[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                        end
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
                    
                case 'CCGs (image)'
                    
                    if isfield(general,'ccg')
                        if BatchMode
                            subset2 = subset(find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii)));
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
                    
                case 'All ACGs (image)'
                    
                    [~,burstIndexSorted] = sort(cell_metrics.burstIndex_Royer2012(subset));
                    if round(v) > 0 && round(v) <= length(subset)
                        iii = subset(burstIndexSorted(round(v)));
                        if highlight
                            if strcmp(UI.settings.acgType,'Normal')
                                Xdata = [-100,100]/2;
                            elseif strcmp(UI.settings.acgType,'Narrow')
                                Xdata = [-30:30]/2;
                            else
                                Xdata = [-500:500];
                            end
                            plot(Xdata,[1;1]*[round(v)-0.48,round(v)+0.48],'w','linewidth',2,'HitTest','off')
                            text(u,round(v)+0.5,num2str(iii),'VerticalAlignment', 'bottom','HorizontalAlignment','center', 'HitTest','off', 'FontSize', 14, 'Color', 'w')
                        end
                    end
                    
                case 'All ACGs'
                    
                    if strcmp(UI.settings.acgType,'Normal')
                        x2 = [-100:100]/2;
                        x1 = ([-100:100]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.acg.narrow(:,subset);
                    elseif strcmp(UI.settings.acgType,'Narrow')
                        x2 = [-30:30]/2;
                        x1 = ([-30:30]/2)'*ones(1,length(subset));
                        y1 = cell_metrics.acg.narrow(41+30:end-40-30,subset);
                    else
                        x2 = [-500:500];
                        x1 = ([-500:500])'*ones(1,length(subset));
                        y1 = cell_metrics.acg.wide(:,subset);
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
                    
                    if any(strcmp(monoSynDisp,{'All','Selected','Upstream','Downstream','Up & downstream'})) & ~isempty(subsetPlots)
                        if ~isempty(outbound) || ~isempty(inbound)
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
        x_step = x_data(2)-x_data(1);
        x_data = [x_data(1),reshape([x_data,x_data+x_step]',1,[]),x_data(end)];
        y_data = [0,reshape([y_data,y_data]',1,[]),0];
        patch(x_data, y_data,col,'EdgeColor',col)
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

    function selectCellsForGroupAction
        % Checkes if any cells have been highlighted, if not asks the user
        % to provide list of cell.
        if isempty(ClickedCells)
            filterCells.dialog = dialog('Position',[300 300 600 495],'Name','Select & filter cells'); movegui(filterCells.dialog,'center')
            
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
            if ~isempty(ClickedCells)
                GroupAction(ClickedCells)
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
                    ClickedCells = eval(['[',answer,']']);
                    ClickedCells = ClickedCells(ismember(ClickedCells,1:size(cell_metrics.troughToPeak,2)));
                catch
                    MsgLog(['List of cells not formatted correctly'],2)
                end
            else
                ClickedCells = 1:size(cell_metrics.troughToPeak,2);
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
            ClickedCells = intersect(ClickedCells,find(all([ClickedCells0;ClickedCells1;ClickedCells2;ClickedCells3;ClickedCells4;ClickedCells5;ClickedCells6])));
            
            close(filterCells.dialog)
            updateTableClickedCells
            % Calls the group action for highlighted cells
            if ~isempty(ClickedCells)
                highlightSelectedCells
                GroupAction(ClickedCells)
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
            ClickedCells = unique([ClickedCells,iii]);
            updateTableClickedCells
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function GroupSelectFromPlot
        % Allows the user to draw a polygon to select multiple cells from
        % either of the plots.
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
                    h2(counter) = plot(polygon_coords(:,1),polygon_coords(:,2),'.-k', 'HitTest','off');
                end
                
            end
            if ~isempty(polygon_coords)
                hold on, plot([polygon_coords(:,1);polygon_coords(1,1)],[polygon_coords(:,2);polygon_coords(1,2)],'.-k', 'HitTest','off');
            end
            %             hold(ax, 'off')
            clear h2
            if size(polygon_coords,1)>2
                axnum = find(ismember(subfig_ax, gca));
                if isempty(axnum)
                    axnum = 1;
                end
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
                            y1 = cell_metrics.waveforms.filt_zscored(:,subset);
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/length(time_waveforms_zscored)))+1;
                            plot(time_waveforms_zscored,y1(:,In),'linewidth',2, 'HitTest','off')
                            In = subset(In);
                            
                        case 'All waveforms (image)'
                            [~,troughToPeakSorted] = sort(cell_metrics.troughToPeak(subset));
                            In = subset(troughToPeakSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'tSNE of waveforms'
                            
                            In = find(inpolygon(tSNE_metrics.filtWaveform(subset,1), tSNE_metrics.filtWaveform(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        case 'CCGs (image)'
                            if isfield(general,'ccg')
                                subset2 = subset(find(cell_metrics.batchIDs(subset)==cell_metrics.batchIDs(ii)));
                                subset1 = cell_metrics.UID(subset2);
                                subset1 = [cell_metrics.UID(ii),subset1(subset1~=cell_metrics.UID(ii))];
                                subset2 = [ii,subset2(subset2~=ii)];
                                In = subset2(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2))));
                            end
                        case 'All ACGs'
                            
                            if strcmp(UI.settings.acgType,'Normal')
                                x1 = ([-100:100]/2)'*ones(1,length(subset));
                                y1 = cell_metrics.acg.narrow(:,subset);
                            elseif strcmp(UI.settings.acgType,'Narrow')
                                x1 = ([-30:30]/2)'*ones(1,length(subset));
                                y1 = cell_metrics.acg.narrow(41+30:end-40-30,subset);
                            else
                                x1 = ([-500:500])'*ones(1,length(subset));
                                y1 = cell_metrics.acg.wide(:,subset);
                            end
                            In = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = unique(floor(In/size(x1,1)))+1;
                            In = subset(In);
                            
                            
                        case 'All ACGs (image)'
                            [~,burstIndexSorted] = sort(cell_metrics.burstIndex_Royer2012(subset));
                            In = subset(burstIndexSorted(min(floor(polygon_coords(:,2))):max(ceil(polygon_coords(:,2)))));
                            
                        case 'tSNE of narrow ACGs'
                            
                            In = find(inpolygon(tSNE_metrics.acg2(subset,1), tSNE_metrics.acg2(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        case 'tSNE of wide ACGs'
                            
                            In = find(inpolygon(tSNE_metrics.acg1(subset,1), tSNE_metrics.acg1(subset,2), polygon_coords(:,1)',polygon_coords(:,2)'));
                            In = subset(In);
                            
                        otherwise
                            if any(strcmp(monoSynDisp,{'All','Selected','Upstream','Downstream','Up & downstream'}))
                                if ~isempty(outbound) || ~isempty(inbound) || ~isempty(subsetPlots)
                                    subset1 = subsetPlots.subset;
                                    x1 = subsetPlots.xaxis(:)*ones(1,length(subset1));
                                    y1 = subsetPlots.yaxis;
                                    
                                    In2 = find(inpolygon(x1(:),y1(:), polygon_coords(:,1)',polygon_coords(:,2)'));
                                    In2 = unique(floor(In2/length(subsetPlots.xaxis)))+1;
                                    In = subset1(In2);
                                    plot(x1(:,1),y1(:,In2),'linewidth',2, 'HitTest','off')
                                end
                            end
                    end
                end
                
                
                if length(In)>0 && any(axnum == [1,2,3,4,5,6,7,8,9])
                    ClickedCells = unique([ClickedCells,In]);
                    updateTableClickedCells
                    GroupAction(ClickedCells)
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
        for i = 1:length(tableDataSortingList)
            UI.menu.tableData.sortingList(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataSortBy,tableDataSortingList));
        UI.menu.tableData.sortingList(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            updateCellTableData
        end
    end

% % % % % % % % % % % % % % % % % % % % % %

    function setColumn1_metric(src,event)
        if isfield(src,'Text')
            tableDataColumn1 = src.Text;
        else
            tableDataColumn1 = src.Label;
        end
        for i = 1:length(tableDataSortingList)
            UI.menu.tableData.column1_ops(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataColumn1,tableDataSortingList));
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
        for i = 1:length(tableDataSortingList)
            UI.menu.tableData.column2_ops(i).Checked = 'off';
        end
        idx = find(strcmp(tableDataColumn2,tableDataSortingList));
        UI.menu.tableData.column2_ops(idx).Checked = 'on';
        if UI.settings.metricsTable==2
            UI.table.ColumnName = {'','#',tableDataColumn1,tableDataColumn2};
            updateCellTableData
        end
    end

% % % % % % % % % % % % % % % % % % % % % %
    
    function viewSessionMetaData(~,~)
        if BatchMode
            sessionMetaFilename = fullfile(cell_metrics.general.basepaths{cell_metrics.batchIDs(ii)},'session.mat');
            if exist(sessionMetaFilename,'file')
                sessionIn = load(sessionMetaFilename);
                calc_CellMetrics_GUI(sessionIn.session);
            else
                MsgLog(['Session metadat file not available:' sessionMetaFilename],2)
            end
        else
            sessionIn = load('session.mat');
            calc_CellMetrics_GUI(sessionIn.session);
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
        column1 = cell_metrics.(tableDataColumn1)(subset)';
        column2 = cell_metrics.(tableDataColumn2)(subset)';
        if isnumeric(column1)
            column1 = cellstr(num2str(column1,3));
        end
        if isnumeric(column2)
            column2 = cellstr(num2str(column2,3));
        end
        if ~isempty(subset)
        dataTable(:,2:4) = [cellstr(num2str(subset')),column1,column2];
        dataTable(:,1) = {false};
        if find(subset==ii)
            idx = find(subset==ii);
            dataTable{idx,2} = ['<html><b>&nbsp;',dataTable{idx,2},'</b></html>'];
            dataTable{idx,3} = ['<html><b>',dataTable{idx,3},'</b></html>'];
            dataTable{idx,4} = ['<html><b>',dataTable{idx,4},'</b></html>'];
        end
        if ~strcmp(tableDataSortBy,'cellID')
            [~,tableDataOrder] = sort(cell_metrics.(tableDataSortBy)(subset));
            UI.table.Data = dataTable(tableDataOrder,:);
        else
            tableDataOrder = 1:length(subset);
            UI.table.Data = dataTable;
        end
        else
            UI.table.Data = {};
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
        if BatchMode
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
        choice = '';
        GoTo_dialog = dialog('Position', [0, 0, 300, 350],'Name','Select action'); movegui(GoTo_dialog,'center')
        
        actionList = strcat([{'Assign existing cell-type','Assign new cell-type','Assign label','Assign deep/superficial','Assign tag','CCGs ','CCGs (only with selected cell)','Multiple plot actions','Multiple plot actions (overlapping cells)'},customPlotOptions']);
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
                    updatePutativeCellType
                    uiresume(UI.fig);
                end
                
            elseif choice == 2
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
                
            elseif choice == 3
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
                
            elseif choice == 6
                % All CCGs for all combinations of selected cell with highlighted cells
                ClickedCells = cellIDs(:)';
                updateTableClickedCells
                if isfield(general,'ccg') && ~isempty(ClickedCells)
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
                    figure('Name',['Cell Explorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize)
                    
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
                else
                    MsgLog('There is no cross- and auto-correlograms matrix structure found for this dataset (Location general.ccg).',2)
                end
                
            elseif choice == 7
                % CCGs with selected cell
                ClickedCells = cellIDs(:)';
                updateTableClickedCells
                if isfield(general,'ccg') && ~isempty(ClickedCells)
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
                    figure('Name',['Cell Explorer: CCGs for cell ', num2str(ii), ' with cell-pairs ', num2str(plot_cells(2:end))],'NumberTitle','off','pos',UI.settings.figureSize)
                    
                    plot_cells2 = cell_metrics.UID(plot_cells);
                    k = 1;
                    [plotRows,~]= numSubplots(length(plot_cells));
                    ha = tight_subplot(plotRows(1),plotRows(2),[.06 .03],[.08 .06],[.06 .05]);
                    for j = 1:length(plot_cells)
                        axes(ha(k));
                        col1 = UI.settings.cellTypeColors(clusClas(plot_cells(j)),:);
                        bar_from_patch(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(1)),col1)
                        %                             bar(general.ccg_time*1000,general.ccg(:,plot_cells2(j),plot_cells2(jj)),1,'FaceColor',col1,'EdgeColor',col1),
                        title(['Cell ', num2str(plot_cells(j)),', Group ', num2str(cell_metrics.spikeGroup(plot_cells(j))) ]),
                        xlabel(cell_metrics.putativeCellType{plot_cells(j)}), grid on
                        if mod(j,plotRows(1)); ylabel('Rate (Hz)'); end
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
                
            elseif choice == 8
                % Displayes a new dialog where a number of plot can be
                % combined and plotted for the highlighted cells
                [selectedActions,tf] = listdlg('PromptString',['Plot actions to perform on ' num2str(length(cellIDs)) ' cells'],'ListString',customPlotOptions','SelectionMode','Multiple','ListSize',[300,350]);
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
                            a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
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
                
            elseif choice == 9
                % Displayes a new dialog where a number of plot can be
                % combined and plotted for the highlighted cells. Similar
                % to choice 8 but the cells are plotted on the same
                % subplots
                [selectedActions,tf] = listdlg('PromptString',['Plot actions to perform on ' num2str(length(cellIDs)) ' cells'],'ListString',customPlotOptions','SelectionMode','Multiple','ListSize',[300,350]);
                if ~isempty(selectedActions)
                    plot_columns = min([length(cellIDs),5]);
                    figure('name',['Cell Explorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'],'pos',UI.settings.figureSize)
                    [plotRows,~]= numSubplots(length(selectedActions));
                    for j = 1:length(cellIDs)
                        if BatchMode
                            batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                            general1 = cell_metrics.general.batch{batchIDs1};
                        else
                            general1 = cell_metrics.general;
                            batchIDs1 = 1;
                        end
                        if ~isempty(putativeSubset)
                            a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                            a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                            inbound = find(a2 == cellIDs(j));
                            outbound = find(a1 == cellIDs(j));
                        end
                        for jjj = 1:length(selectedActions)
                            subplot(plotRows(1),plotRows(2),jjj), hold on
                            %                             subplot(plot_columns,length(selectedActions),j,jj,mod(j ,5),['Cell Explorer: Multiple plots for ', num2str(length(cellIDs)), ' selected cells'])
                            customPlot(customPlotOptions{selectedActions(jjj)},cellIDs(j),general1,batchIDs1);
                            title(customPlotOptions{selectedActions(jjj)},'Interpreter', 'none')
                        end
                    end
                end
                
            elseif choice > 9
                % Plots any custom plot for selected cells in a single new figure with subplots
                figure('Name',['Cell Explorer: ',actionList{choice},' for selected cells: ', num2str(cellIDs)],'NumberTitle','off','pos',UI.settings.figureSize)
                for j = 1:length(cellIDs)
                    if BatchMode
                        batchIDs1 = cell_metrics.batchIDs(cellIDs(j));
                        general1 = cell_metrics.general.batch{batchIDs1};
                    else
                        general1 = cell_metrics.general;
                        batchIDs1 = 1;
                    end
                    if ~isempty(putativeSubset)
                        a1 = cell_metrics.putativeConnections.excitatory(putativeSubset,1);
                        a2 = cell_metrics.putativeConnections.excitatory(putativeSubset,2);
                        inbound = find(a2 == cellIDs(j));
                        outbound = find(a1 == cellIDs(j));
                    end
                    [plotRows,~]= numSubplots(length(cellIDs));
                    subplot(plotRows(1),plotRows(2),j), hold on
                    customPlot(actionList{choice},cellIDs(j),general1,batchIDs1); title(['Cell ', num2str(cellIDs(j)), ', Group ', num2str(cell_metrics.spikeGroup(cellIDs(j)))])
                end
            else
                uiresume(UI.fig);
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
        answer = questdlg('Settings are stored in CellExplorer_Settings.m. Click Yes to load settings.', 'Settings', 'Yes','Cancel','Yes');
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

    function buttonSave(~,~)
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
        
        cell_metrics.general.SWR_batch = SWR_batch;
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
            f_waitbar = waitbar(0,[num2str(sessionWithChanges),' sessions with changes'],'name','Saving cell metrics from batch','WindowStyle','modal');
            
            for j = 1:length(sessionWithChanges)
                if ~ishandle(f_waitbar)
                    MsgLog(['Saving canceled']);
                    break
                end
                sessionID = sessionWithChanges(j);
                waitbar(j/length(sessionWithChanges),f_waitbar,['Session ' num2str(j),'/',num2str(length(sessionWithChanges)),': ', cell_metricsTemp.general.basenames{sessionID}])
                cellSubset = find(cell_metricsTemp.batchIDs==sessionID);
                if BatchMode && isfield(cell_metricsTemp.general,'saveAs')
                    saveAs = cell_metricsTemp.general.saveAs{sessionID};
                else
                    saveAs = 'cell_metrics';
                end
                matpath = fullfile(cell_metricsTemp.general.paths{sessionID},[cell_metricsTemp.general.basenames{sessionID}, '.',saveAs,'.cellinfo.mat']);
                matFileCell_metrics = matfile(matpath,'Writable',true);
                
                % Creating backup of existing metrics
                cell_metrics = {};
                cell_metrics_temp = matFileCell_metrics.cell_metrics;
                cell_metrics.labels = cell_metrics_temp.labels;
                if isfield(cell_metrics_temp,'tags')
                    cell_metrics.tags = cell_metrics_temp.tags;
                end
                cell_metrics.deepSuperficial = cell_metrics_temp.deepSuperficial;
                cell_metrics.brainRegion = cell_metrics_temp.brainRegion;
                cell_metrics.putativeCellType = cell_metrics_temp.putativeCellType;
                if isfield(cell_metrics_temp,'groundTruthClassification')
                cell_metrics.groundTruthClassification = cell_metrics_temp.groundTruthClassification;
                end
                save(fullfile(cell_metricsTemp.general.paths{sessionID}, 'revisions_cell_metrics', [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']),'cell_metrics','-v7.3','-nocompression')
                
                % Saving new metrics to file
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
            end
            if ishandle(f_waitbar)
                close(f_waitbar)
                classificationTrackChanges = [];
                UI.menu.file.save.ForegroundColor = 'k';
                MsgLog(['Classifications succesfully saved to existing cell-metrics files'],[1,2]);
            else
                MsgLog('Metrics were not succesfully saved for all session in batch',4);
            end
        else
            if isfield(cell_metrics.general,'saveAs')
                saveAs = cell_metrics.general.saveAs;
                %             elseif isfield(cell_metrics.general.processingInfo,'saveAs')
            else
                saveAs = 'cell_metrics';
            end
            file = fullfile(clusteringpath,[saveAs,'.mat']);
            save(file,'cell_metrics');
            classificationTrackChanges = [];
            UI.menu.file.save.ForegroundColor = 'k';
            MsgLog(['Classification saved to ', file],[1,2]);
        end
        
    end

% % % % % % % % % % % % % % % % % % % % % %

    function SignificanceMetricsMatrix(~,~)
        % Performs a KS-test for selected two groups and displays a colored
        % matrix with significance levels for relevant metrics
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
        ii_history = 1;
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
        
        % Batch initialization
        if isfield(cell_metrics.general,'batch')
            BatchMode = true;
        else
            BatchMode = false;
        end
        
        % Fieldnames
        metrics_fieldsNames = fieldnames(cell_metrics);
        table_fieldsNames = metrics_fieldsNames(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'cell','double'})));
        table_fieldsNames(find(contains(table_fieldsNames,tableOptionsToExlude)))=[];
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
                SWR_batch = cell_metrics.general.SWR_batch;
            elseif ~BatchMode
                if isfield(cell_metrics.general,'SWR')
                    SWR_batch = cell_metrics.general.SWR;
                else
                    SWR_batch = [];
                end
            else
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
        fieldsMenuCells = metrics_fieldsNames;
        fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
        fieldsMenuCells(find(contains(fieldsMenuCells,fieldsMenuMetricsToExlude)))=[];
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
            cell_metrics.waveforms.raw_zscored = (rawWaveform-nanmean(rawWaveform))./nanstd(rawWaveform);
            clear rawWaveform
        end
        cell_metrics.acg.wide_zscored = zscore(cell_metrics.acg.wide); cell_metrics.acg.wide_zscored = cell_metrics.acg.wide_zscored - min(cell_metrics.acg.wide_zscored(490:510,:));
        cell_metrics.acg.narrow_zscored = zscore(cell_metrics.acg.narrow); cell_metrics.acg.narrow_zscored = cell_metrics.acg.narrow_zscored - min(cell_metrics.acg.narrow_zscored(90:110,:));
        
        % filtWaveform, acg2, acg1, plot
        if isfield(cell_metrics.general,'tSNE_metrics')
            tSNE_metrics = cell_metrics.general.tSNE_metrics;
            tSNE_fieldnames = fieldnames(cell_metrics.general.tSNE_metrics);
            for i = 1:length(tSNE_fieldnames)
                if ~isempty(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i})) && size(cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i}),1) == length(cell_metrics.UID)
                    tSNE_metrics.(tSNE_fieldnames{i}) = cell_metrics.general.tSNE_metrics.(tSNE_fieldnames{i});
                end
            end
        else
            tSNE_metrics = [];
        end
        
        if UI.settings.tSNE_calcWideAcg && ~isfield(tSNE_metrics,'acg1')
            disp('Calculating tSNE space for wide ACGs')
            tSNE_metrics.acg_wide = tsne([cell_metrics.acg.wide_zscored(ceil(size(cell_metrics.acg.wide_zscored,1)/2):end,:)]','Distance',UI.settings.tSNE_dDistanceMetric);
        end
        if UI.settings.tSNE_calcNarrowAcg && ~isfield(tSNE_metrics,'acg2')
            disp('Calculating tSNE space for narrow ACGs')
            tSNE_metrics.acg_narrow = tsne([cell_metrics.acg.narrow_zscored(ceil(size(cell_metrics.acg.narrow_zscored,1)/2):end,:)]','Distance',UI.settings.tSNE_dDistanceMetric);
        end
        if UI.settings.tSNE_calcFiltWaveform && ~isfield(tSNE_metrics,'filtWaveform')
            disp('Calculating tSNE space for filtered waveforms')
            X = cell_metrics.waveforms.filt_zscored';
            tSNE_metrics.filtWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE_dDistanceMetric);
        end
        if UI.settings.tSNE_calcRawWaveform && ~isfield(tSNE_metrics,'rawWaveform') && isfield(cell_metrics.waveforms,'raw')
            disp('Calculating tSNE space for raw waveforms')
            X = cell_metrics.waveforms.raw_zscored';
            if ~isempty(find(~any(isnan(X))))
                tSNE_metrics.rawWaveform = tsne(X(:,find(~any(isnan(X)))),'Standardize',true,'Distance',UI.settings.tSNE_dDistanceMetric);
            end
        end
        if ~isfield(tSNE_metrics,'plot')
            %             disp('Calculating tSNE space for combined metrics')
            UI.settings.tSNE_metrics = intersect(UI.settings.tSNE_metrics,fieldnames(cell_metrics));
            X = cell2mat(cellfun(@(X) cell_metrics.(X),UI.settings.tSNE_metrics,'UniformOutput',false));
            X(isnan(X) | isinf(X)) = 0;
            tSNE_metrics.plot = tsne(X','Standardize',true,'Distance',UI.settings.tSNE_dDistanceMetric);
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
            monoSynDisp = UI.settings.monoSynDispIn;
        else
            monoSynDisp = 'None';
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
        
%         customPlotOptions = fieldnames(cell_metrics);
%         temp =  struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
%         temp1 = cell2mat(struct2cell(structfun(@(X) size(X,1), cell_metrics,'UniformOutput',false)));
%         temp2 = cell2mat(struct2cell(structfun(@(X) size(X,2), cell_metrics,'UniformOutput',false)));
%         
%         fields2keep = [];
%         customPlotOptions2 = customPlotOptions(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'cell'));
%         
%         for i = 1:length(customPlotOptions2)
%             if any(cell2mat(cellfun(@isnumeric,cell_metrics.(customPlotOptions2{i}),'UniformOutput',false)))
%                 fields2keep = [fields2keep,i];
%             end
%         end
%         customPlotOptions2 = sort(customPlotOptions2(fields2keep));
        
        waveformOptions = {'Single waveform';'All waveforms';'All waveforms (image)'};
        if isfield(tSNE_metrics,'filtWaveform')
            waveformOptions = [waveformOptions;'tSNE of waveforms'];
        end
        if isfield(cell_metrics.waveforms,'raw')
            waveformOptions2 = {'Single raw waveform';'All raw waveforms'};
            if isfield(tSNE_metrics,'rawWaveform')
                waveformOptions2 = [waveformOptions2;'tSNE of raw waveforms'];
            end
        else
            waveformOptions2 = {};
        end
        acgOptions = {'Single ACG';'All ACGs';'All ACGs (image)';'CCGs (image)'};
        if isfield(tSNE_metrics,'acg_narrow')
            acgOptions = [acgOptions;'tSNE of narrow ACGs'];
        end
        if isfield(tSNE_metrics,'acg_wide')
            acgOptions = [acgOptions;'tSNE of wide ACGs'];
        end
        otherOptions = {};
        if ~isempty(SWR_batch)
            otherOptions = [otherOptions;'Sharp wave-ripple'];
        end
%         cell_metricsFieldnames = fieldnames(cell_metrics,'-full');
        structFieldsType = metrics_fieldsNames(find(strcmp(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),'struct')));
        customPlotOptions = {};
        for j = 1:length(structFieldsType)
            if ~any(strcmp(structFieldsType{j},{'general','putativeConnections'}))
                customPlotOptions = [customPlotOptions;strcat(structFieldsType{j},{'_'},fieldnames(cell_metrics.(structFieldsType{j})))];
            end
        end
%         customPlotOptions = customPlotOptions(   (strcmp(temp,'double') & temp1>1 & temp2==size(cell_metrics.spikeCount,2) )   );
%         customPlotOptions = [customPlotOptions;customPlotOptions2];
        customPlotOptions(find(contains(customPlotOptions,plotOptionsToExlude)))=[]; %
        customPlotOptions = unique([waveformOptions; waveformOptions2; acgOptions; otherOptions; customPlotOptions],'stable');
        
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
            if ~any(cell2mat(cellfun(@isnumeric,cell_metrics.(colorMenu{i}),'UniformOutput',false))) && ~contains(colorMenu{i},menuOptionsToExlude )
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
        
        % Spikes and event initialization
        spikes = [];
        events = [];
        
        % fixed axes limits for subfig2 and subfig3 to increase performance
        fig2_axislimit_x = [min(cell_metrics.troughToPeak * 1000),max(cell_metrics.troughToPeak * 1000)];
        fig2_axislimit_y = [min(cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012>0)),max(cell_metrics.burstIndex_Royer2012(cell_metrics.burstIndex_Royer2012<Inf))];
        fig3_axislimit_x = [min(tSNE_metrics.plot(:,1)), max(tSNE_metrics.plot(:,1))];
        fig3_axislimit_y = [min(tSNE_metrics.plot(:,2)), max(tSNE_metrics.plot(:,2))];
        
        subsetGroundTruth = [];
    end

% % % % % % % % % % % % % % % % % % % % % %

    function toggleHeatmapFiringRateMaps(~,~)
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

    function toggleFiringRateMapShowLegend(~,~)
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

    function toggleFiringRateMapShowHeatmapColorbar(~,~)
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

    function LoadDatabaseSession(~,~)
        % Load sessions from the database.
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected sessions are loaded from the database
                drawnow nocallbacks;
                if isempty(db) && exist('db_cell_metrics_session_list.mat')
                    load('db_cell_metrics_session_list.mat')
                elseif isempty(db)
                    loadDB_sessionlist
                end
                
                loadDB.dialog = dialog('Position', [300, 300, 900, 518],'Name','Load sessions from DB','WindowStyle','modal'); movegui(loadDB.dialog,'center')
                loadDB.sessionList = uitable(loadDB.dialog,'Data',db.dataTable,'Position',[10, 60, 880, 447],'ColumnWidth',{20 30 210 50 120 70 140 110 110},'columnname',{'','#','Session name','Cells','Animal','Species','Behaviors','Investigator','Repository'},'RowName',[],'ColumnEditable',[true false false false false false false false false]); % ,'CellSelectionCallback',@ClicktoSelectFromTable
                loadDB.summaryText = uicontrol('Parent',loadDB.dialog,'Style','text','Position',[10, 44, 880, 15],'Units','normalized','String','','HorizontalAlignment','center');
                
                uicontrol('Parent',loadDB.dialog,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll);
                uicontrol('Parent',loadDB.dialog,'Style','pushbutton','Position',[110, 10, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll);
                uicontrol('Parent',loadDB.dialog,'Style','pushbutton','Position',[210, 10, 90, 30],'String','Update list','Callback',@(src,evnt)reloadSessionlist);
                loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.dialog,'Style','popupmenu','Position',[310, 15, 150, 20],'Units','normalized','String',{'Sort by','Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)button_DB_filterList);
                loadDB.popupmenu.filter = uicontrol('Parent',loadDB.dialog,'Style', 'Edit', 'String', 'Filter', 'Position', [470, 12, 100, 25],'Callback',@(src,evnt)button_DB_filterList,'HorizontalAlignment','left');
                loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.dialog,'Style','popupmenu','Position',[570, 15, 120, 20],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)button_DB_filterList);
                uicontrol('Parent',loadDB.dialog,'Style','pushbutton','Position',[700, 10, 90, 30],'String','OK','Callback',@(src,evnt)CloseDB_dialog);
                uicontrol('Parent',loadDB.dialog,'Style','pushbutton','Position',[800, 10, 90, 30],'String','Cancel','Callback',@(src,evnt)CancelDB_dialog);
                updateSummaryText
                uiwait(loadDB.dialog)
            
        function reloadSessionlist
            loadDB_sessionlist
            button_DB_filterList
        end
        
        function loadDB_sessionlist
            if exist('db_credentials') == 2
                bz_database = db_credentials;
                if ~strcmp(bz_database.rest_api.username,'user')
                    %                 disp(['Loading datasets from database']);
                    db = {};
                    % DB settings
                    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
                    options.CertificateFilename=('');
                    
                    % Show waitbar while loading DB
                    if isfield(UI,'panel')
                        loadBD_waitbar = waitbar(0,'Downloading session list. Hold on for a few seconds...','name','Loading metadata from DB','WindowStyle', 'modal');
                    else
                        loadBD_waitbar = [];
                    end
                    
                    % Requesting db list
                    bz_db = webread([bz_database.rest_api.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
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
                    end
                    %             db.menu_behavioralParadigm = cellfun(@(x) x.behavioralParadigm{1},db.sessions,'UniformOutput',false);
                    %             db.menu_behavioralParadigm = cellfun(@(x) strjoin(x{:}),db.menu_behavioralParadigm,'UniformOutput',false);
                    db.menu_investigator = cellfun(@(x) x.investigator,db.sessions,'UniformOutput',false);
                    db.menu_repository = cellfun(@(x) x.repositories{1},db.sessions,'UniformOutput',false);
                    db.menu_cells = cellfun(@(x) num2str(x.spikeSorting.cellCount),db.sessions,'UniformOutput',false);
                    
                    db.menu_values = cellfun(@(x) x.id,db.sessions,'UniformOutput',false);
                    db.menu_values = db.menu_values(db.index);
                    db.menu_items2 = strcat(db.menu_items);
                    sessionEnumerator = cellstr(num2str([1:length(db.menu_items2)]'))';
                    db.sessionList = strcat(sessionEnumerator,{' '},db.menu_items2,{' '},db.menu_cells(db.index),{' '},db.menu_animals(db.index),{' '},db.menu_behavioralParadigm(db.index),{' '},db.menu_species(db.index),{' '},db.menu_investigator(db.index),{' '},db.menu_repository(db.index));
                    
                    % Promt user with a tabel with sessions
                    if ishandle(loadBD_waitbar)
                        close(loadBD_waitbar)
                    end
                    db.dataTable = {};
                    db.dataTable(:,2:9) = [sessionEnumerator;db.menu_items2;db.menu_cells(db.index);db.menu_animals(db.index);db.menu_species(db.index);db.menu_behavioralParadigm(db.index);db.menu_investigator(db.index);db.menu_repository(db.index)]';
                    db.dataTable(:,1) = {false};
                    [db_path,~,~] = fileparts(which('db_load_sessions.m'));
                    try
                        save(fullfile(db_path,'db_cell_metrics_session_list.mat'),'db');
                    catch
                        warning('failed to save session list with metrics');
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
        
        function updateSummaryText
            cellCount = sum(cell2mat( cellfun(@(x) str2double(x),loadDB.sessionList.Data(:,4),'UniformOutput',false)));
            loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' session(s) with ', num2str(cellCount),' cells from ',num2str(length(unique(loadDB.sessionList.Data(:,5)))),' animal(s). Updated at: ', datestr(db.refreshTime)];
        end
        
        function button_DB_filterList
            dataTable1 = db.dataTable;
            if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
                idx1 = find(contains(db.sessionList,loadDB.popupmenu.filter.String,'IgnoreCase',true));
            else
                idx1 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.sorting.Value == 3 % Cell count
                cellCount = cell2mat( cellfun(@(x) x.spikeSorting.cellCount,db.sessions,'UniformOutput',false));
                [~,idx2] = sort(cellCount(db.index),'descend');
            elseif loadDB.popupmenu.sorting.Value == 4 % Animal
                [~,idx2] = sort(db.menu_animals(db.index));
            elseif loadDB.popupmenu.sorting.Value == 5 % Species
                [~,idx2] = sort(db.menu_species(db.index));
            elseif loadDB.popupmenu.sorting.Value == 6 % Behavioral paradigm
                [~,idx2] = sort(db.menu_behavioralParadigm(db.index));
            elseif loadDB.popupmenu.sorting.Value == 7 % Investigator
                [~,idx2] = sort(db.menu_investigator(db.index));
            elseif loadDB.popupmenu.sorting.Value == 8 % Data repository
                [~,idx2] = sort(db.menu_repository(db.index));
            else
                idx2 = 1:size(db.dataTable,1);
            end
            
            if loadDB.popupmenu.repositories.Value == 2 
                idx3 = find(ismember(db.menu_repository(db.index),fieldnames(bz_database.repositories)));
            else
                idx3 = 1:size(db.dataTable,1);
            end
            
            idx2 = intersect(idx2,idx1,'stable');
            idx2 = intersect(idx2,idx3,'stable');
            loadDB.sessionList.Data = db.dataTable(idx2,:);
            updateSummaryText
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
                        if ~any(strcmp(session.repositories{1},fieldnames(bz_database.repositories)))
                            MsgLog(['The respository ', session.repositories{1} ,' has not been defined on this computer. Please edit db_credentials and provide the path'],4)
                            edit db_credentials
                            return
                        end
                        if strcmp(session.repositories{1},'NYUshare_Datasets')
                            Investigator_name = strsplit(session.investigator,' ');
                            path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                            basepath = fullfile(bz_database.repositories.(session.repositories{1}), path_Investigator,session.animal, session.name);
                        else
                            basepath = fullfile(bz_database.repositories.(session.repositories{1}), session.animal, session.name);
                        end
                        
                        if ~isempty(session.spikeSorting.relativePath)
                            clusteringpath = fullfile(basepath, session.spikeSorting.relativePath{1});
                        else
                            clusteringpath = basepath;
                        end
                        %                             [session, basename, basepath, clusteringpath] = db_set_path('id',str2double(db_menu_ids(indx)),'saveMat',false);
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
                        if ~any(strcmp(db.sessions{i_db_subset}.repositories{1},fieldnames(bz_database.repositories)))
                            MsgLog(['The respository ', db.sessions{i_db_subset}.repositories{1} ,' has not been defined on this computer. Please edit db_credentials and provide the path'],4)
                            edit db_credentials.m
                            return
                        end
                        if strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_Datasets')
                            Investigator_name = strsplit(db.sessions{i_db_subset}.investigator,' ');
                            path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                            db_basepath{i_db} = fullfile(bz_database.repositories.(db.sessions{i_db_subset}.repositories{1}), path_Investigator,db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                        else
                            db_basepath{i_db} = fullfile(bz_database.repositories.(db.sessions{i_db_subset}.repositories{1}), db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                        end
                        
                        if ~isempty(db.sessions{i_db_subset}.spikeSorting.relativePath)
                            db_clusteringpath{i_db} = fullfile(db_basepath{i_db}, db.sessions{i_db_subset}.spikeSorting.relativePath{1});
                        else
                            db_clusteringpath{i_db} = db_basepath{i_db};
                        end
                        
                    end
                    
                    
                    f_LoadCellMetrics = waitbar(0,' ','name','Cell-metrics: loading batch');
                    try
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
    
% % % % % % % % % % % % % % % % % % % % % %
    
    function editDBcredentials(~,~)
        edit db_credentials.m
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
                if BatchMode
                    clusteringpath1 = cell_metrics.general.paths{batchIDsPrivate};
                    basename1 = cell_metrics.general.basenames{batchIDsPrivate};
                else
                    clusteringpath1 = clusteringpath;
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
                    spikesfilesize=dir(fullfile(clusteringpath1,[basename1,'.spikes.cellinfo.mat']));
                    waitbar_spikes = waitbar((batchIDsPrivate-1)/length(batchIDsIn),waitbar_spikes,[num2str(batchIDsPrivate) '. Loading ', basename1 , ' (', num2str(ceil(spikesfilesize.bytes/1000000)), 'MB)']);
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

    function out = CheckEvents(batchIDs,eventType)
        % Checks if the event type is available for the selected session (batchIDs)
        % If it is the file is loaded into memory (events structure)
        if isempty(events) || ~isfield(events,eventType) || length(events.(eventType)) < batchIDs || isempty(events.(eventType){batchIDs})
            if BatchMode
                basepath1 = cell_metrics.general.basepaths{batchIDs};
                basename1 = cell_metrics.general.basenames{batchIDs};
            else
                basepath1 = basepath;
                basename1 = cell_metrics.general.basename;
            end
            
            if exist(fullfile(basepath1,[basename1,'.' (eventType) '.events.mat']),'file')
                eventsfilesize = dir(fullfile(basepath1,[basename1,'.' (eventType) '.events.mat']));
                if eventsfilesize.bytes/1000000>10 % Show waitbar if filesize exceeds 10MB
                    waitbar_events = waitbar(0,['Loading events from ', basename1 , ' (', num2str(ceil(eventsfilesize.bytes/1000000)), 'MB)'],'Name','Loading events','WindowStyle','modal');
                end
                temp = load(fullfile(basepath1,[basename1,'.' (eventType) '.events.mat']));
                if isfield(temp.(eventType),'timestamps')
                    events.(eventType){batchIDs} = temp.(eventType);
                    if isfield(temp.(eventType),'peakNormedPower') & ~isfield(temp.(eventType),'amplitude')
                        events.(eventType){batchIDs}.amplitude = temp.(eventType).peakNormedPower;
                    end
                    if isfield(temp.(eventType),'timestamps') & ~isfield(temp.(eventType),'duration')
                        events.(eventType){batchIDs}.duration = diff(temp.(eventType).timestamps')';
                    end
                    out = true;
                    MsgLog([eventType ' events loaded succesfully for ' basename1]);
                else
                    out = false;
                    MsgLog([eventType ' events loading failed due to missing fieldname timestamps for ' basename1]);
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
            MsgLog(['No spike data found or the spike data is not accessible: ',general.basepath],2)
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
        
        if BatchMode
            basepath1 = cell_metrics.general.basepaths{batchIDs};
        else
            basepath1 = basepath;
        end
        
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
        eventType = uicontrol('Parent', spikePlots_dialog, 'Style', 'popupmenu', 'String', {'none','event', 'manipulation','state'}, 'Value',1,'Position', [10, 105, 210, 20],'HorizontalAlignment','left');
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


    function editSelectedSpikePlot(~,~)
        % Called when scrolling/zooming in the cell inspector.
        % Checks first, if a plot is underneath the curser
        h2 = overobj2('flat','visible','on');
        
        %v if ~isempty(h2) && strcmp(h2.Type,'uipanel') && strcmp(h2.Title,'') && ~isempty(h2.Children) && any(ismember(subfig_ax, h2.Children))>0 && any(find(ismember(subfig_ax, h2.Children)) == [1:9])
        if isfield(UI,'panel') & any(ismember([UI.panel.subfig_ax4,UI.panel.subfig_ax5,UI.panel.subfig_ax6,UI.panel.subfig_ax7,UI.panel.subfig_ax8,UI.panel.subfig_ax9], h2))
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
    end

% % % % % % % % % % % % % % % % % % % % % %

    function adjustMonoSyn_UpdateMetrics(cell_metricsIn,cell_metrics)
        answer = questdlg('Are you sure you want to adjust monosyn connections for this session?', 'Adjust monosynaptic connections', 'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                % Manually select connections
                if BatchMode
                    basepath1 = cell_metricsIn.general.basepaths{batchIDs};
                    basename1 = cell_metricsIn.general.basenames{batchIDs};
                    path1 = cell_metricsIn.general.paths{batchIDs};
                else
                    basepath1 = basepath;
                    basename1 = cell_metricsIn.general.basename;
                    path1 = cell_metricsIn.general.clusteringpath;
                end
                MonoSynFile = fullfile(path1,[basename1,'.mono_res.cellinfo.mat']);
                if exist('bz_PlotMonoSyn.m','file') && exist(MonoSynFile,'file')
                    mono_res = adjustMonoSyn(MonoSynFile);
                elseif ~exist(MonoSynFile,'file')
                    MsgLog(['Mono syn file does not exist: ' MonoSynFile],4);
                    return
                elseif ~exist('bz_PlotMonoSyn.m','file')
                    MsgLog(['Synaptic connections can only be adjusted with bz_PlotMonoSyn.m in your Matlab path (from buzcode)'],4);
                    return
                end
                
                % Saves output to the cell_metrics from the select session
                if isfield(general,'saveAs')
                    saveAs = general.saveAs;
                else
                    saveAs = 'cell_metrics';
                end
                disp(['Saving cells to ', saveAs,'.mat']);
                
                % Creating backup of existing metrics
                dirname = 'revisions_cell_metrics';
                if ~(exist(fullfile(path1,dirname),'dir'))
                    mkdir(fullfile(path1,dirname));
                end
                if exist(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']),'file')
                    copyfile(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']), fullfile(path1, dirname, [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']));
                end
                
                % Saving new metrics
                load(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']));
%                 load(fullfile(path1,[saveAs,'.mat']));
                cell_metrics.putativeConnections.excitatory = mono_res.sig_con; % Vectors with cell pairs
                cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_metrics.general.cellCount);
                cell_metrics.synapticEffect(cell_metrics.putativeConnections.excitatory(:,1)) = repmat({'Excitatory'},1,size(cell_metrics.putativeConnections.excitatory,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
                cell_metrics.synapticConnectionsOut = zeros(1,cell_metrics.general.cellCount);
                cell_metrics.synapticConnectionsIn = zeros(1,cell_metrics.general.cellCount);
                [a,b]=hist(cell_metrics.putativeConnections.excitatory(:,1),unique(cell_metrics.putativeConnections.excitatory(:,1)));
                cell_metrics.synapticConnectionsOut(b) = a; cell_metrics.synapticConnectionsOut = cell_metrics.synapticConnectionsOut(1:cell_metrics.general.cellCount);
                [a,b]=hist(cell_metrics.putativeConnections.excitatory(:,2),unique(cell_metrics.putativeConnections.excitatory(:,2)));
                cell_metrics.synapticConnectionsIn(b) = a; cell_metrics.synapticConnectionsIn = cell_metrics.synapticConnectionsIn(1:cell_metrics.general.cellCount);
                save(fullfile(path1,[basename1,'.',saveAs,'.cellinfo.mat']),'cell_metrics','-v7.3','-nocompression')
                MsgLog(['Synaptic connections adjusted for: ', basename1,'. Reload session to see the changes'],2);
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
            
%             rows = max(ceil(length(buttonLabels)/2),3);
%             positionToogleButtons = getpixelposition(parentPanelName);
%             positionToogleButtons = [positionToogleButtons(3)/2,positionToogleButtons(4)/rows];
            
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
        groundTruth_dialog = dialog('Position', [300, 300, 600, 350],'Name','Ground truth cell types'); movegui(groundTruth_dialog,'center')
        groundTruthList = uicontrol('Parent',groundTruth_dialog,'Style', 'ListBox', 'String', groundTruthCelltypes, 'Position', [10, 50, 580, 220],'Min', 0, 'Max', 100,'Value',groundTruthSelectionIn);
        groundTruthTextfield = uicontrol('Parent',groundTruth_dialog,'Style', 'Edit', 'String', '', 'Position', [10, 300, 580, 25],'Callback',@(src,evnt)UpdateGroundTruthList,'HorizontalAlignment','left');
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[10, 10, 180, 30],'String','OK','Callback',@(src,evnt)CloseGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[200, 10, 190, 30],'String','Cancel','Callback',@(src,evnt)CancelGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style','pushbutton','Position',[400, 10, 190, 30],'String','Reset','Callback',@(src,evnt)ResetGroundTruth_dialog);
        uicontrol('Parent',groundTruth_dialog,'Style', 'text', 'String', 'Search term', 'Position', [10, 325, 580, 20],'HorizontalAlignment','left');
        uicontrol('Parent',groundTruth_dialog,'Style', 'text', 'String', 'Selct the cell types below', 'Position', [10, 270, 580, 20],'HorizontalAlignment','left');
        uicontrol(groundTruthTextfield)
        uiwait(groundTruth_dialog);
        function UpdateGroundTruthList
            temp = contains(groundTruthCelltypes,groundTruthTextfield.String,'IgnoreCase',true);
            if ~isempty(groundTruthList.Value) && ~any(temp == groundTruthList.Value)
                groundTruthList.Value = 1;
            end
            if ~isempty(temp)
                groundTruthList.String = groundTruthCelltypes(temp);
            else
                groundTruthList.String = {''};
            end
        end
        function  CloseGroundTruth_dialog
            if length(groundTruthList.String)>=groundTruthList.Value
                choice = groundTruthList.String(groundTruthList.Value);
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
            UI.panel.subfig_ax1.Position = [0.09 0.66 0.28 0.33];
            UI.panel.subfig_ax2.Position = [0.09+0.28 0.66 0.28 0.33];
            UI.panel.subfig_ax3.Position = [0.09+0.54 0.66 0.28 0.33];
            UI.panel.subfig_ax4.Position = [0.09 0.33 0.28 0.33];
            UI.panel.subfig_ax5.Position = [0.09+0.28 0.33 0.28 0.33];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.33 0.28 0.331];
            UI.panel.subfig_ax7.Position = [0.09 0.03 0.28 0.33-0.03];
            UI.panel.subfig_ax8.Position = [0.09+0.28 0.03 0.28 0.33-0.03];
            UI.panel.subfig_ax9.Position = [0.09+0.54 0.03 0.28 0.33-0.03];
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
            % GUI: 1+3 figures.
            UI.popupmenu.customplot4.Enable = 'off';
            UI.popupmenu.customplot5.Enable = 'off';
            UI.popupmenu.customplot6.Enable = 'off';
            UI.panel.subfig_ax2.Visible = 'off';
            UI.panel.subfig_ax3.Visible = 'off';
            UI.panel.subfig_ax7.Visible = 'off';
            UI.panel.subfig_ax8.Visible = 'off';
            UI.panel.subfig_ax9.Visible = 'off';
            UI.panel.subfig_ax1.Position = [0.10 0.024 0.53 0.945];
            UI.panel.subfig_ax4.Position = [0.09+0.54 0.66 0.28 0.315];
            UI.panel.subfig_ax5.Position = [0.09+0.54 0.33 0.28 0.33];
            UI.panel.subfig_ax6.Position = [0.09+0.54 0.0 0.28 0.33];
            UI.popupmenu.plotCount.Value = 1;
            UI.settings.layout = 1;
        end
        uiresume(UI.fig);
    end

% % % % % % % % % % % % % % % % % % % % % %

    function keyPress(src, event)
        % Keyboard shortcuts. Sorted alphabetically
        switch event.Key
            case 'a'
                % Load spike plot options
%                 defineSpikesPlots;
            case 'b'
%                 buttonBrainRegion;
            case 'c'
                % Opens the file directory for the selected cell
%                 openSessionDirectory
            case 'd'
                % Opens the current session in the Buzsaki lab web database
%                 openSessionInWebDB
            case 'e'
                % Highlight excitatory cells
%                 highlightExcitatoryCells
            case 'f'
%                 toggleACGfit;
            case 'g'
%                 goToCell;
            case 'h'
                HelpDialog;
            case 'i'
                % Highlight inhibitory cells
%                 highlightInhibitoryCells
            case 'j'
%                 adjustMonoSyn_UpdateMetrics(cell_metrics);
            case 'k'
% %                 SignificanceMetricsMatrix;
            case 'l'
%                 buttonLabel;
            case 'm'
                % Hide/show menubar
                showHideMenu
            case 'n'
                % Adjusts the number of subplots in the GUI
                AdjustGUI;
            case 'o'
                % Loads list of sessions from database 
%                 LoadDatabaseSession
            case 'p'
                LoadPreferences;
            case 'r'
%                 reclassify_celltypes;
            case 't'
                % Redefine the space of the t-SNE representation
%                 tSNE_redefineMetrics;
            case 'u'
                % Load ground truth datasets
%                 loadGroundTruth
            case 'v'
                % Opens the Cell Explorer wiki in your browser
%                 openWiki
            case 'w'
%                 showWaveformMetrics
            case 'x'

            case 'y'
                % Load ground truth datasets
%                 performGroundTruthClassification
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
            case {'pageup','backquote'}
                % Goes to the first cell from the next session in a batch
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

    function showHideMenu(~,~)
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

    function aboutDialog(~,~)
        opts.Interpreter = 'tex';
        opts.WindowStyle = 'normal';
        msgbox({['\bfCell Explorer\rm v', num2str(CellExplorerVersion)],'Developed by Peter Petersen in the Buzsaki lab at NYU.','\itgithub.com/petersenpeter/Cell-Explorer\rm'},'About the Cell Explorer','help',opts);
    end
end

%% % % % % % % % % % % % % % % % % % % % % %
% External functions
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
% Unique values exluding nans
y = unique(x);
y(isnan(y)) = [];
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
        figure('Name',titleIn,'pos',UI.settings.figureSize)
    end
    subplot(x,y,mod(z-1,x)+1)
else
    if (mod(z,x) == 1 || (z==x & z==1)) & w == 1
        figure('Name',titleIn,'pos',UI.settings.figureSize)
    end
    subplot(x,y,y*mod(z-1,x)+w)
end
end

% % % % % % % % % % % % % % % % % % % % % %

function h = overobj2(varargin)
% OVEROBJ2 Get handle of object that the pointer is over.
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

% % % % % % % % % % % % % % % % % % % % % %

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

%Reformat if the column/row ratio is too large: we want a roughly
%square design
while p(2)/p(1)>2.5
    N=n+1;
    [p,n]=numSubplots(N); %Recursive!
end
end

% % % % % % % % % % % % % % % % % % % % % %

function ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
% tight_subplot creates "subplot" axes with adjustable gaps and margins
% Pekka Kumpulainen 21.5.2012
% https://www.mathworks.com/matlabcentral/fileexchange/27991-tight_subplot-nh-nw-gap-marg_h-marg_w
if nargin<3; gap = .02; end
if nargin<4 || isempty(marg_h); marg_h = .05; end
if nargin<5; marg_w = .05; end
if numel(gap)==1
    gap = [gap gap];
end
if numel(marg_w)==1
    marg_w = [marg_w marg_w];
end
if numel(marg_h)==1
    marg_h = [marg_h marg_h];
end
axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh;
axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;
py = 1-marg_h(2)-axh;

ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    for ix = 1:Nw
        ii = ii+1;
        ha(ii) = axes('Units','normalized','Position',[px py axw axh]); % 'XTickLabel','','YTickLabel',''
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end
ha = ha(:);
end
