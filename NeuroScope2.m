function NeuroScope2(varargin)
% % % % % % % % % % % % % % % % % % % % % % % % %
% NeuroScope2 (BETA) is a visualizer for electrophysiological recordings. It is inspired by the original Neuroscope (http://neurosuite.sourceforge.net/)
% and made to mimic its features, but built upon Matlab and the data structure of CellExplorer making it much easier to hack/customize, fully
% support Matlab mat-files, and faster. NeuroScope2 is part of CellExplorer - https://CellExplorer.org/
%
% Major features:
% - Live trace filter
% - Live spike detection
% - Plot multiple data streams together
% - Plot CellExplorer/Buzcode structures: spikes, cell_metrics, events, timeseries, states, behavior, trials
%
% Example calls:
%    NeuroScope2
%    NeuroScope2('basepath',basepath)
%    NeuroScope2('session',session)
%
% By Peter Petersen
% % % % % % % % % % % % % % % % % % % % % % % % %

% Global variables
UI = []; % Struct with UI elements and settings
data = []; % External data loaded like spikes, events, states, behavior
ephys = []; % Struct with ephys data for current shown time interval
t0 = 0; % Timestamp the current window (in seconds)
spikes_raster = []; % Global spike raster (used for highlighting)
if isdeployed % If NeuroScope2 is run as a deployed app
    if ~isempty(varargin) % If a file name is provided it will load it.
        filename = varargin{1};
        [basepath1,file1] = fileparts(varargin{1});
    else % Else a file dialog will be show
        [file1,basepath1] = uigetfile('*.mat;*.dat;*.lfp;*.xml','Please select a file with the basename in it from the basepath');
    end
    if ~isequal(file1,0)
        basepath = basepath1;
        temp1 = strsplit(file1,'.');
        basename = temp1{1};
    else
        return
    end
else
    % Handling inputs if run from Matlab
    p = inputParser;
    addParameter(p,'basepath',pwd,@isstr);
    addParameter(p,'basename',[],@isstr);
    addParameter(p,'session',[],@isstruct);
    addParameter(p,'events',[],@isstr);
    addParameter(p,'states',[],@isstr);
    addParameter(p,'behavior',[],@isstr);
    addParameter(p,'cellinfo',[],@isstr);
    addParameter(p,'channeltag',[],@isstr);
    parse(p,varargin{:})
    parameters = p.Results;
    basepath = p.Results.basepath;
    basename = p.Results.basename;
    if isempty(basename)
        basename = basenameFromBasepath(basepath);
    end
    if ~isempty(parameters.session)
        basename = parameters.session.general.name;
        basepath = parameters.session.general.basePath;
    end
end

int_gt_0 = @(n) (isempty(n)) || (n <= 0);

% Initialization
initUI
initData(basepath,basename);
initInputs
initTraces

% Main while loop of the interface
while t0>=0
    % breaking if figure has been closed
    if ~ishandle(UI.fig)
        break
    else
        % Plotting data
        UI.selectedChannels = [];
        UI.selectedUnits = [];
        plotData;
        
        % Update UI text and slider
        UI.elements.lower.time.String = num2str(t0);
        UI.elements.lower.slider.Value = min([t0/(UI.t_total-UI.settings.windowDuration)*100,100]);
        if UI.settings.debug
            drawnow
        end
        UI.elements.lower.performance.String = ['  Processing: ' num2str(toc(UI.timerInterface),3) ' s'];
        uiwait(UI.fig);
        
        % Tracking viewed timestamps in file (can be used by pressing the backspace key)
        UI.settings.stream = false;
        t0 = max([0,min([t0,UI.t_total-UI.settings.windowDuration])]);
        if UI.track && UI.t0_track(end) ~= t0
            UI.t0_track = [UI.t0_track,t0];
        end
        UI.track = true;
    end
    UI.timerInterface = tic;
end

% Closing all file readers
fclose('all');
if ishandle(UI.fig)
    % Closing main figure if open
    close(UI.fig);
end

% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions
% % % % % % % % % % % % % % % % % % % % % %

    function initUI % Initialize the UI (settings, parameters, figure, menu, panels, axis)
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Init settings
        UI.t1 = 0;
        UI.forceNewData = true;
        UI.track = true;
        UI.t_total = 0;
        UI.iEvent = 1;
        UI.t0_track = 0;
        UI.timerInterface = tic;
        UI.settings.colormap = 'hsv'; % any Matlab colormap, e.g. 'hsv' or 'lines'
        UI.settings.windowDuration = 1; % in seconds
        UI.settings.scalingFactor = 50;
        UI.settings.plotStyle = 2;
        UI.settings.stream = false;
        UI.settings.fileRead = 'bof';
        UI.settings.greyScaleTraces = 1;
        UI.settings.columnTraces = false;
        UI.preferences.displayMenu = 0;
        UI.settings.channelTags.hide = [];
        UI.settings.channelTags.filter = [];
        UI.settings.channelTags.highlight = [];
        UI.settings.showKilosort = false;
        UI.settings.normalClick = true;
        UI.settings.addEventonClick = false;
        UI.settings.background = 'k';
        UI.settings.xtickColor = 'w';
        % Only Matlab 2020b and forward supports vertical markers unfortunately
        if verLessThan('matlab','9.9') 
            UI.settings.rasterMarker = 'o';
        else
            UI.settings.rasterMarker = '|';
        end
        UI.iLine = 1;
        UI.colorLine = lines(256);
        UI.freeText = '';
        UI.selectedChannels = [];
        UI.settings.debug = false;
        
        % Trace processing
        UI.settings.plotEnergy = 0;
        UI.settings.energyWindow = 0.030; % in seconds
        UI.settings.detectEvents = false;
        UI.settings.eventThreshold = 100; % in µV
        UI.settings.filterTraces = false;
        UI.settings.detectSpikes = false;
        UI.settings.spikesDetectionThreshold = -100; % in µV

        % Performance settings
        UI.settings.plotStyleDynamicRange = true; % If true, all samples will be shown below a temporal threshold in range mode (default: 1.2 sec)
        UI.settings.plotStyleDynamicThreshold = 1.2; % in seconds, threhold for switch between range and raw data presentation
        UI.settings.plotStyleRangeSamples = 4; % resamples per second of data. Default: 4; Higher valie will show less data points
        
        % Spikes settings
        UI.settings.showSpikes = false;
        UI.settings.spikesBelowTrace = false;
        UI.settings.useSpikesYData = false;
        UI.settings.spikesYData = '';
        UI.settings.spikesColormap = 'hsv';
        UI.settings.spikesGroupColors = 1;
        
        % Cell metrics
        UI.settings.useMetrics = false;
        UI.params.cellTypes = [];
        UI.params.cell_class_count = [];
        UI.groupData1.groupsList = {'groups','tags','groundTruthClassification'}; 
        UI.preferences.tags = {'Good','Bad','Noise','InverseSpike'};
        UI.preferences.groundTruth = {'PV','NOS1','GAT1','SST','Axoaxonic','CellType_A'};
        UI.tableData.Column1 = 'putativeCellType';
        UI.tableData.Column2 = 'firingRate';
        UI.params.subsetTable = [];
        UI.params.subsetFilter = [];
        UI.params.subsetCellType = [];
        UI.params.subsetGroups = [];
        UI.params.sortingMetric = 'putativeCellType';
        UI.params.groupMetric = 'putativeCellType';
        
        % Event settings
        UI.settings.showEvents = false;
        UI.settings.eventData = [];
        UI.settings.showEventsBelowTrace = false;
        UI.settings.showEventsIntervals = false;
        UI.settings.processing_steps = false;
        
        % Timeseries settings
        UI.settings.showTimeSeries = false;
        UI.settings.timeseriesData = [];
        UI.settings.timeseries.lowerBoundary = 34;
        UI.settings.timeseries.upperBoundary = 38;
        
        % States settings
        UI.settings.showStates = false;
        UI.settings.statesData = [];
        
        % Behavior settings
        UI.settings.showBehavior = false;
        UI.settings.plotBehaviorLinearized = false;
        UI.settings.showBehaviorBelowTrace = false;
        UI.settings.behaviorData = [];
        UI.settings.showTrials = false;
        
        % Intan settings
        UI.settings.intan_showAnalog = false;
        UI.settings.intan_showAux = false;
        UI.settings.intan_showDigital = false;
        UI.settings.showIntanBelowTrace = false; 
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating figure
        
        UI.fig = figure('Name','NeuroScope2','NumberTitle','off','renderer','opengl','KeyPressFcn', @keyPress,'KeyReleaseFcn',@keyRelease,'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off','pos',[0,0,1600,800],'DefaultTextInterpreter', 'none', 'DefaultLegendInterpreter', 'none', 'MenuBar', 'None');
        if ~verLessThan('matlab', '9.3')
            menuLabel = 'Text';
            menuSelectedFcn = 'MenuSelectedFcn';
        else
            menuLabel = 'Label';
            menuSelectedFcn = 'Callback';
        end
        uix.tracking('off')
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating menu
        
        % NeuroScope2
        UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'NeuroScope2');
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'About NeuroScope2',menuSelectedFcn,@AboutDialog);
        % uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Run benchmarks',menuSelectedFcn,@runBenchMark,'Separator','on');
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitNeuroScope2,'Separator','on','Accelerator','W');
        
        % File
        UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
        uimenu(UI.menu.file.topMenu,menuLabel,'Load session from folder',menuSelectedFcn,@loadFromFolder);
        uimenu(UI.menu.file.topMenu,menuLabel,'Load session from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
        uimenu(UI.menu.file.topMenu,menuLabel,'Export to .png file',menuSelectedFcn,@exportPlotData,'Separator','on');
        uimenu(UI.menu.file.topMenu,menuLabel,'Export to .pdf file',menuSelectedFcn,@exportPlotData);
        uimenu(UI.menu.file.topMenu,menuLabel,'Export figure via the export setup dialog',menuSelectedFcn,@exportPlotData,'Separator','on');
        
        % Session
        UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
        uimenu(UI.menu.session.topMenu,menuLabel,'View metadata',menuSelectedFcn,@viewSessionMetaData);
        uimenu(UI.menu.session.topMenu,menuLabel,'Open basepath',menuSelectedFcn,@openSessionDirectory,'Separator','on');
        
        % Cell metrics 
        UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'Cell metrics');
        UI.menu.cellExplorer.defineGroupData = uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Open group data dialog',menuSelectedFcn,@defineGroupData,'Accelerator','G');
        UI.menu.cellExplorer.saveCellMetrics = uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Save cell_metrics',menuSelectedFcn,@saveCellMetrics);
%         uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'View cell metrics in CellExplorer',menuSelectedFcn,@openCellExplorer);
        
        % BuzLabDB
        UI.menu.BuzLabDB.topMenu = uimenu(UI.fig,menuLabel,'BuzLabDB');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Load session from BuzLabDB',menuSelectedFcn,@DatabaseSessionDialog,'Accelerator','D');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit repository paths',menuSelectedFcn,@editDBrepositories);
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current session on website',menuSelectedFcn,@openSessionInWebDB,'Separator','on');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current animal subject on website',menuSelectedFcn,@showAnimalInWebDB);
        
        % View
        UI.menu.view.topMenu = uimenu(UI.fig,menuLabel,'View');
        UI.menu.view.summaryFigure = uimenu(UI.menu.view.topMenu,menuLabel,'Summary figure',menuSelectedFcn,@summaryFigure);
         
        % Settings
        UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'Settings');
        UI.menu.display.columnTraces = uimenu(UI.menu.display.topMenu,menuLabel,'Multiple columns',menuSelectedFcn,@columnTraces);
        UI.menu.display.changeColormap = uimenu(UI.menu.display.topMenu,menuLabel,'Change colormap of ephys traces',menuSelectedFcn,@changeColormap,'Separator','on');
        UI.menu.display.changeBackgroundColor = uimenu(UI.menu.display.topMenu,menuLabel,'Change background/xtick color',menuSelectedFcn,@changeBackgroundColor);
        UI.menu.display.ShowHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Show full menu','Separator','on',menuSelectedFcn,@ShowHideMenu);
        UI.menu.display.debug = uimenu(UI.menu.display.topMenu,menuLabel,'Debug','Separator','on',menuSelectedFcn,@toggleDebug);
        
        % Help
        UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
        uimenu(UI.menu.help.topMenu,menuLabel,'Mouse and keyboard shortcuts',menuSelectedFcn,@HelpDialog);
        uimenu(UI.menu.help.topMenu,menuLabel,'CellExplorer website',menuSelectedFcn,@openWebsite,'Accelerator','V','Separator','on');
        uimenu(UI.menu.help.topMenu,menuLabel,'Tutorial on metadata',menuSelectedFcn,@openWebsite,'Separator','on');
        uimenu(UI.menu.help.topMenu,menuLabel,'Documentation on session metadata',menuSelectedFcn,@openWebsite);

        % % % % % % % % % % % % % % % % % % % % % %
        % Creating UI/panels
        
        UI.grid_panels = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0); % Flexib grid box
        UI.panel.left = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Left panel
        
        UI.panel.center = uix.VBox( 'Parent', UI.grid_panels, 'Spacing', 0, 'Padding', 0 ); % Center flex box
        % UI.panel.right = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Right panel
        set(UI.grid_panels, 'Widths', [200 -1],'MinimumWidths',[80 1]); % set grid panel size
        
        % Separation of the center box into three panels: title panel, plot panel and lower info panel
        UI.panel.plots = uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.panel.center,'BackgroundColor','k'); % Main plot panel
        UI.panel.info  = uix.HBox('Parent',UI.panel.center, 'Padding', 1); % Lower info panel
        set(UI.panel.center, 'Heights', [-1 20]); % set center panel size
        
        % Left panel tabs
        UI.uitabgroup = uiextras.TabPanel('Parent', UI.panel.left, 'Padding', 1,'FontSize',11 ,'TabSize',60);
        UI.panel.general.main  = uix.VBox('Parent',UI.uitabgroup, 'Padding', 1);
        UI.panel.spikedata.main  = uix.VBox('Parent',UI.uitabgroup, 'Padding', 1);
        UI.panel.other.main  = uix.VBox('Parent',UI.uitabgroup, 'Padding', 1);
        UI.uitabgroup.TabNames = {'General', 'Spikes','Other'};

        % % General tab elements
        % Navigation
        UI.panel.general.navigation = uipanel('Parent',UI.panel.general.main);
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.15 0.98],'String','<<','Callback',@back_fast,'KeyPressFcn', @keyPress,'tooltip','Fast backward in time'); 
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.17 0.01 0.15 0.98],'String','<','Callback',@back,'KeyPressFcn', @keyPress,'tooltip','Go back in time');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.33 0.5 0.34 0.49],'String',char(94),'Callback',@(src,evnt)increaseAmplitude,'KeyPressFcn', @keyPress,'tooltip','Increase amplitude of ephys data');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.33 0.01 0.34 0.49],'String','v','Callback',@(src,evnt)decreaseAmplitude,'KeyPressFcn', @keyPress,'tooltip','Decrease amplitude of ephys data');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.68 0.01 0.15 0.98],'String','>','Callback',@advance,'KeyPressFcn', @keyPress,'tooltip','Forward in time');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.84 0.01 0.15 0.98],'String','>>','Callback',@advance_fast,'KeyPressFcn', @keyPress,'tooltip','Fast forward in time');
        
        % Electrophysiology
        UI.panel.general.filter = uipanel('Parent',UI.panel.general.main,'title','Electrophysiology');
        UI.panel.general.plotStyle = uicontrol('Parent',UI.panel.general.filter,'Style', 'popup','String',{'Downsampled','Range','Raw','LFP'}, 'value', UI.settings.plotStyle, 'Units','normalized', 'Position', [0.01 0.85 0.98 0.15],'Callback',@changePlotStyle,'HorizontalAlignment','left');
        UI.panel.general.detectSpikes = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String',['Detect spikes (',char(181),'V)'], 'value', 0, 'Units','normalized', 'Position', [0.0 0.70 0.7 0.15],'Callback',@toogleDetectSpikes,'HorizontalAlignment','left');
        UI.panel.general.detectThreshold = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.spikesDetectionThreshold), 'Units','normalized', 'Position', [0.71 0.70 0.28 0.15],'Callback',@toogleDetectSpikes,'HorizontalAlignment','center','tooltip',['Spike detection threshold (',char(181),'V)']);
        UI.panel.general.filterToggle = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String','Filter traces', 'value', 0, 'Units','normalized', 'Position', [0. 0.55 0.5 0.145],'Callback',@changeTraceFilter,'HorizontalAlignment','left');
        UI.panel.general.greyScaleTraces = uicontrol('Parent',UI.panel.general.filter,'Style', 'popup','String',{'Colors','Colors 75%','Colors 50%','Colors 25%','Grey-scale','Grey-scale 75%','Grey-scale 50%','Grey-scale 25%'}, 'value', 1, 'Units','normalized', 'Position', [0.50 0.55 0.49 0.15],'Callback',@changeColorScale,'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Lower filter (Hz)', 'Units','normalized', 'Position', [0.0 0.45 0.5 0.1],'HorizontalAlignment','center');
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Higher filter (Hz)', 'Units','normalized', 'Position', [0.5 0.45 0.5 0.1],'HorizontalAlignment','center');
        UI.panel.general.lowerBand  = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', '400', 'Units','normalized', 'Position', [0.01 0.3 0.48 0.145],'Callback',@changeTraceFilter,'HorizontalAlignment','center','tooltip','Lower frequency boundary (Hz)');
        UI.panel.general.higherBand = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.5 0.3 0.49 0.145],'Callback',@changeTraceFilter,'HorizontalAlignment','center','tooltip','Higher frequency band (Hz)');
        UI.panel.general.plotEnergy = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String','Smooth traces; sec)', 'value', 0, 'Units','normalized', 'Position', [0. 0.15 0.7 0.145],'Callback',@plotEnergy,'HorizontalAlignment','left');
        UI.panel.general.energyWindow = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.energyWindow), 'Units','normalized', 'Position', [0.7 0.15 0.29 0.145],'Callback',@plotEnergy,'HorizontalAlignment','center','tooltip','Smoothing window (seconds)');
        UI.panel.general.detectEvents = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String',['Detect events (',char(181),'V)'], 'value', 0, 'Units','normalized', 'Position', [0.0 0 0.7 0.145],'Callback',@toogleDetectEvents,'HorizontalAlignment','left');
        UI.panel.general.eventThreshold = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.eventThreshold), 'Units','normalized', 'Position', [0.7 0 0.29 0.145],'Callback',@toogleDetectEvents,'HorizontalAlignment','center','tooltip',['Event detection threshold (',char(181),'V)']);
        
        % Electrode groups
        UI.table.electrodeGroups = uitable(UI.panel.general.main,'Data',{false,'','',''},'Units','normalized','Position',[0 0.55 1 0.25],'ColumnWidth',{20 20 45 220},'columnname',{'','','Group','Channels        '},'RowName',[],'ColumnEditable',[true false false false],'CellEditCallback',@editElectrodeGroups,'CellSelectionCallback',@ClicktoSelectFromTable);
        UI.panel.electrodeGroupsButtons = uipanel('Parent',UI.panel.general.main,'title','Electrode groups');
        uicontrol('Parent',UI.panel.electrodeGroupsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.323 0.98],'String','All','Callback',@buttonsElectrodeGroups,'KeyPressFcn', @keyPress,'tooltip','Select all groups');
        uicontrol('Parent',UI.panel.electrodeGroupsButtons,'Style','pushbutton','Units','normalized','Position',[0.34 0.01 0.32 0.98],'String','None','Callback',@buttonsElectrodeGroups,'KeyPressFcn', @keyPress,'tooltip','Deselect all groups');
        uicontrol('Parent',UI.panel.electrodeGroupsButtons,'Style','pushbutton','Units','normalized','Position',[0.67 0.01 0.32 0.98],'String','Edit','Callback',@buttonsElectrodeGroups,'KeyPressFcn', @keyPress,'tooltip','Edit groups');
        
        % Channel tags
        UI.table.channeltags = uitable(UI.panel.general.main,'Data', {'','',false,false,false,'',''},'Units','normalized','Position',[0 0.45 1 0.1],'ColumnWidth',{20 60 20 20 20 55 55},'columnname',{'','Tags','o','+','÷','Channels','Groups'},'RowName',[],'ColumnEditable',[false false true true true true false],'CellEditCallback',@editChannelTags,'CellSelectionCallback',@ClicktoSelectFromTable2);
        UI.panel.channelTagsButtons = uipanel('Parent',UI.panel.general.main,'title','Channel tags');
        uicontrol('Parent',UI.panel.channelTagsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.32 0.98],'String','Add','Callback',@buttonsChannelTags,'KeyPressFcn', @keyPress,'tooltip','Add channel tag');
        uicontrol('Parent',UI.panel.channelTagsButtons,'Style','pushbutton','Units','normalized','Position',[0.34 0.01 0.32 0.98],'String','Save','Callback',@buttonsChannelTags,'KeyPressFcn', @keyPress,'tooltip','Save channel tags to session metadata');
        uicontrol('Parent',UI.panel.channelTagsButtons,'Style','pushbutton','Units','normalized','Position',[0.67 0.01 0.32 0.98],'String','Delete','Callback',@buttonsChannelTags,'KeyPressFcn', @keyPress,'tooltip','Delete channel tag in session gui');
        
        % Notes
        UI.panel.notes.main = uipanel('Parent',UI.panel.general.main,'title','Session notes');
        UI.panel.notes.text = uicontrol('Parent',UI.panel.notes.main,'Style', 'Edit', 'String', '','Units' ,'normalized', 'Position', [0, 0, 1, 1],'HorizontalAlignment','left', 'Min', 0, 'Max', 100,'Callback',@getNotes);
        
        % Intan
        UI.panel.intan.main = uipanel('Title','Intan data','TitlePosition','centertop','Position',[0 0.2 1 0.1],'Units','normalized','Parent',UI.panel.general.main);
        UI.panel.intan.showAnalog = uicontrol('Parent',UI.panel.intan.main,'Style','checkbox','Units','normalized','Position',[0 0.75 1 0.25], 'value', 0,'String','Show analog','Callback',@showIntan,'KeyPressFcn', @keyPress,'tooltip','Show analog data');
        UI.panel.intan.filenameAnalog = uicontrol('Parent',UI.panel.intan.main,'Style', 'Edit', 'String', 'analogin.dat', 'Units','normalized', 'Position', [0.5 0.75 0.49 0.24],'Callback',@showIntan,'HorizontalAlignment','left','tooltip','Filename of analog file','Enable','off');
        UI.panel.intan.showAux = uicontrol('Parent',UI.panel.intan.main,'Style','checkbox','Units','normalized','Position',[0 0.5 1 0.25], 'value', 0,'String','Show aux','Callback',@showIntan,'KeyPressFcn', @keyPress,'tooltip','Show aux data');
        UI.panel.intan.filenameAux = uicontrol('Parent',UI.panel.intan.main,'Style', 'Edit', 'String', 'auxiliary.dat', 'Units','normalized', 'Position', [0.5 0.5 0.49 0.24],'Callback',@showIntan,'HorizontalAlignment','left','tooltip','Filename of analog file','Enable','off');
        UI.panel.intan.showDigital = uicontrol('Parent',UI.panel.intan.main,'Style','checkbox','Units','normalized','Position',[0 0.25 1 0.25], 'value', 0,'String','Show digital','Callback',@showIntan,'KeyPressFcn', @keyPress,'tooltip','Show digital data');
        UI.panel.intan.filenameDigital = uicontrol('Parent',UI.panel.intan.main,'Style', 'Edit', 'String', 'digitalin.dat', 'Units','normalized', 'Position', [0.5 0.25 0.49 0.24],'Callback',@showIntan,'HorizontalAlignment','left','tooltip','Filename of analog file','Enable','off');
        UI.panel.intan.showIntanBelowTrace = uicontrol('Parent',UI.panel.intan.main,'Style','checkbox','Units','normalized','Position',[0 0 0.5 0.25], 'value', 0,'String','Below traces','Callback',@showIntanBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show intan data below traces');
        uicontrol('Parent',UI.panel.intan.main,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.49 0.24],'String','Metadata','Callback',@editIntanMeta,'KeyPressFcn', @keyPress,'tooltip','Edit input channels');
            
        % Defining flexible panel heights
        set(UI.panel.general.main, 'Heights', [55 180 -200 50 -100 50 100 110],'MinimumHeights',[55 180 100 50 100 50 50 110]);
        
        % 2. PANEL: Spikes related metrics
        % Spikes
        UI.panel.spikes.main = uipanel('Parent',UI.panel.spikedata.main,'title','Spikes');
        UI.panel.spikes.showSpikes = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Show spikes', 'value', 0, 'Units','normalized', 'Position', [0.01 0.67 0.48 0.32],'Callback',@toggleSpikes,'HorizontalAlignment','left');
        UI.panel.spikes.showSpikesBelowTrace = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Below traces', 'value', 0, 'Units','normalized', 'Position', [0.51 0.67 0.48 0.32],'Callback',@showSpikesBelowTrace,'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', ' Colors: ', 'Units','normalized', 'Position', [0 0.34 0.3 0.3],'HorizontalAlignment','left');
        UI.panel.spikes.setSpikesGroupColors = uicontrol('Parent',UI.panel.spikes.main,'Style', 'popup', 'String', {'UID','White'}, 'Units','normalized', 'Position', [0.3 0.34 0.69 0.32],'HorizontalAlignment','left','Enable','off','Callback',@setSpikesGroupColors);
        uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', ' Y-data: ', 'Units','normalized', 'Position', [0.0 0.01 0.3 0.3],'HorizontalAlignment','left');
        UI.panel.spikes.setSpikesYData = uicontrol('Parent',UI.panel.spikes.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.3 0.01 0.69 0.32],'HorizontalAlignment','left','Enable','off','Callback',@setSpikesYData);
        
        % Cell metrics
        UI.panel.cell_metrics.main = uipanel('Parent',UI.panel.spikedata.main,'title','Cell metrics');
        UI.panel.cell_metrics.useMetrics = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'checkbox','String','Use metrics', 'value', 0, 'Units','normalized','Position', [0 0.85 0.5 0.15], 'Callback',@toggleMetrics,'HorizontalAlignment','left');
        UI.panel.cell_metrics.defineGroupData = uicontrol('Parent',UI.panel.cell_metrics.main,'Style','pushbutton','Units','normalized','Position',[0.5 0.82 0.49 0.18],'String','Groups','Callback',@defineGroupData,'KeyPressFcn', @keyPress,'tooltip','Fast backward in time','Enable','off'); 
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Grouping', 'Units','normalized','Position', [0 0.74 0.5 0.13],'HorizontalAlignment','left');
        UI.panel.cell_metrics.groupMetric = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'popup', 'String', {''}, 'Units','normalized','Position', [0.01 0.6 0.98 0.15],'HorizontalAlignment','left','Enable','off','Callback',@setGroupMetric);
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Sorting','Units','normalized','Position', [0 0.47 1 0.13],'HorizontalAlignment','left');
        UI.panel.cell_metrics.sortingMetric = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'popup', 'String', {''}, 'Units','normalized','Position', [0.01 0.32 0.98 0.15],'HorizontalAlignment','left','Enable','off','Callback',@setSortingMetric);
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Filter', 'Units','normalized','Position', [0 0.17 1 0.13], 'HorizontalAlignment','left');
        UI.panel.cell_metrics.textFilter = uicontrol('Style','edit', 'Units','normalized','Position',[0.01 0.01 0.98 0.17],'String','','HorizontalAlignment','left','Parent',UI.panel.cell_metrics.main,'Callback',@filterCellsByText,'Enable','off','tooltip',sprintf('Search across cell metrics\nString fields: "CA1" or "Interneuro"\nNumeric fields: ".firingRate > 10" or ".cv2 < 0.5" (==,>,<,~=) \nCombine with AND // OR operators (&,|) \nEaxmple: ".firingRate > 10 & CA1"\nFilter by parent brain regions as well, fx: ".brainRegion HIP"\nMake sure to include  spaces between fields and operators' ));
        
        UI.panel.cellTypes.main = uipanel('Parent',UI.panel.spikedata.main,'title','Putative cell types');
        UI.listbox.cellTypes = uicontrol('Parent',UI.panel.cellTypes.main,'Style','listbox', 'Units','normalized','Position',[0 0 1 1],'String',{''},'Enable','off','max',20,'min',0,'Value',[],'Callback',@setCellTypeSelectSubset,'KeyPressFcn', @keyPress,'tooltip','Filter putative cell types. Select to filter');
        
        % Table with list of cells
        UI.table.cells = uitable(UI.panel.spikedata.main,'Data', {false,'','',''},'Units','normalized','Position',[0 0.34 1 0.45],'ColumnWidth',{20 30 80 80},'columnname',{'','#',UI.tableData.Column1,UI.tableData.Column2},'RowName',[],'ColumnEditable',[true false false false],'CellEditCallback',@editCellTable,'Enable','off');
        UI.panel.metricsButtons = uipanel('Parent',UI.panel.spikedata.main,'title','Electrode groups','title','Cells and metrics','Position',[0 0.3 1 0.04]);
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.32 0.98],'String','All','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Show all cells');
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.34 0.01 0.32 0.98],'String','None','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Hide all cells');
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.67 0.01 0.32 0.98],'String','Metrics','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Show table with metrics');
        
        % KiloSort
        UI.panel.kilosort.main = uipanel('Title','Processed data','TitlePosition','centertop','Position',[0 0.2 1 0.1],'Units','normalized','Parent',UI.panel.spikedata.main);
        UI.panel.kilosort.showKilosort = uicontrol('Parent',UI.panel.kilosort.main,'Style','checkbox','Units','normalized','Position',[0 0 1 1], 'value', 0,'String','Show spikes from KiloSort','Callback',@showKilosort,'KeyPressFcn', @keyPress,'tooltip','Open a KiloSort rez.mat data and show detected spikes');

        % Defining flexible panel heights
        set(UI.panel.spikedata.main, 'Heights', [95 170 100 -200 45 45],'MinimumHeights',[95 170 60 60 45 45]);
        
        % 3. PANEL: Other datatypes
        % Events
        UI.panel.events.navigation = uipanel('Parent',UI.panel.other.main,'title','Events and manipulations');
        UI.panel.events.files = uicontrol('Parent',UI.panel.events.navigation,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.85 0.98 0.13],'HorizontalAlignment','left','Callback',@setEventData);
        UI.panel.events.showEvents = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0 0.75 0.5 0.1], 'value', 0,'String','Show','Callback',@showEvents,'KeyPressFcn', @keyPress,'tooltip','Show events');
        UI.panel.events.processing_steps = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.5 0.75 0.5 0.1], 'value', 0,'String','Processing','Callback',@processing_steps,'KeyPressFcn', @keyPress,'tooltip','Show processing steps');
        UI.panel.events.showEventsBelowTrace = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0 0.65 0.5 0.1], 'value', 0,'String','Below traces','Callback',@showEventsBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show events below traces');
        UI.panel.events.showEventsIntervals = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.5 0.65 0.5 0.1], 'value', 0,'String','Intervals','Callback',@showEventsIntervals,'KeyPressFcn', @keyPress,'tooltip','Show events intervals');
        UI.panel.events.eventNumber = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.485 0.485 0.14],'HorizontalAlignment','center','tooltip','Event number','Callback',@gotoEvents);
        UI.panel.events.eventCount = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', 'nEvents', 'Units','normalized', 'Position', [0.505 0.485 0.48 0.14],'HorizontalAlignment','center','Enable','off');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.33 0.32 0.14],'String','<','Callback',@previousEvent,'KeyPressFcn', @keyPress,'tooltip','Previous event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.34 0.33 0.32 0.14],'String','?','Callback',@(src,evnt)randomEvent,'KeyPressFcn', @keyPress,'tooltip','Random event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.67 0.33 0.32 0.14],'String','>','Callback',@nextEvent,'KeyPressFcn', @keyPress,'tooltip','Next event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.17 0.48 0.14],'String','Flag event','Callback',@flagEvent,'KeyPressFcn', @keyPress,'tooltip','Flag selected event');
        UI.panel.events.flagCount = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', 'nFlags', 'Units','normalized', 'Position', [0.51 0.17 0.48 0.14],'HorizontalAlignment','center','Enable','off');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.485 0.14],'String','Manual events','Callback',@addEvent,'KeyPressFcn', @keyPress,'tooltip','Add event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.505 0.01 0.485 0.14],'String','Save events','Callback',@saveEvent,'KeyPressFcn', @keyPress,'tooltip','Save events');
        
        % Time series
        UI.panel.timeseries.main = uipanel('Parent',UI.panel.other.main,'title','Time series');
        UI.panel.timeseries.files = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.67 0.98 0.31],'HorizontalAlignment','left','Callback',@setTimeseriesData);
        UI.panel.timeseries.show = uicontrol('Parent',UI.panel.timeseries.main,'Style','checkbox','Units','normalized','Position',[0 0.34 0.5 0.33], 'value', 0,'String','Show','Callback',@showTimeSeries,'KeyPressFcn', @keyPress,'tooltip','Show timeseries data');
        uicontrol('Parent',UI.panel.timeseries.main,'Style','pushbutton','Units','normalized','Position',[0.5 0.34 0.49 0.33],'String','Full trace','Callback',@plotTimeSeries,'KeyPressFcn', @keyPress,'tooltip','Show full trace in separate figure');
        UI.panel.timeseries.lowerBoundary = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'Edit', 'String', num2str(UI.settings.timeseries.lowerBoundary), 'Units','normalized', 'Position', [0.01 0 0.49 0.33],'HorizontalAlignment','center','tooltip','Lower bound','Callback',@setTimeSeriesBoundary);
        UI.panel.timeseries.upperBoundary = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'Edit', 'String', num2str(UI.settings.timeseries.upperBoundary), 'Units','normalized', 'Position', [0.51 0 0.48 0.33],'HorizontalAlignment','center','tooltip','Higher bound','Callback',@setTimeSeriesBoundary);
        
        % States
        UI.panel.states.main = uipanel('Parent',UI.panel.other.main,'title','States');
        UI.panel.states.files = uicontrol('Parent',UI.panel.states.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.67 0.98 0.31],'HorizontalAlignment','left','Callback',@setStatesData);
        UI.panel.states.showStates = uicontrol('Parent',UI.panel.states.main,'Style','checkbox','Units','normalized','Position',[0 0.35 1 0.33], 'value', 0,'String','Show states','Callback',@showStates,'KeyPressFcn', @keyPress,'tooltip','Show states data');
        UI.panel.states.previousStates = uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.5 0.35 0.235 0.32],'String','<','Callback',@previousStates,'KeyPressFcn', @keyPress,'tooltip','Previous state');
        UI.panel.states.nextStates = uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.755 0.35 0.235 0.32],'String','>','Callback',@nextStates,'KeyPressFcn', @keyPress,'tooltip','Next state');
        UI.panel.states.statesNumber = uicontrol('Parent',UI.panel.states.main,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.01 0.48 0.32],'HorizontalAlignment','center','tooltip','State number','Callback',@gotoState);
        UI.panel.states.statesCount = uicontrol('Parent',UI.panel.states.main,'Style', 'Edit', 'String', 'nStates', 'Units','normalized', 'Position', [0.51 0.01 0.48 0.32],'HorizontalAlignment','center','Enable','off');
        
        % Behavior
        UI.panel.behavior.main = uipanel('Parent',UI.panel.other.main,'title','Behavior');
        UI.panel.behavior.files = uicontrol('Parent',UI.panel.behavior.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.79 0.98 0.19],'HorizontalAlignment','left','Callback',@setBehaviorData);
        UI.panel.behavior.showBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0 0.60 1 0.19], 'value', 0,'String','Behavior','Callback',@showBehavior,'KeyPressFcn', @keyPress,'tooltip','Show behavior');
        UI.panel.behavior.previousBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.49 0.60 0.24 0.19],'String','<','Callback',@previousBehavior,'KeyPressFcn', @keyPress,'tooltip','Start');
        UI.panel.behavior.nextBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.75 0.60 0.24 0.19],'String','>','Callback',@nextBehavior,'KeyPressFcn', @keyPress,'tooltip','End','BusyAction','cancel');
        UI.panel.behavior.plotBehaviorLinearized = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0 0.41 0.5 0.19], 'value', 0,'String','Linearize','Callback',@plotBehaviorLinearized,'KeyPressFcn', @keyPress,'tooltip','Show linearized behavior');
        UI.panel.behavior.showBehaviorBelowTrace = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[00.5 0.41 0.5 0.19], 'value', 0,'String','Below traces','Callback',@showBehaviorBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show behavior data below traces');
        UI.panel.behavior.showTrials = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0 0.22 1 0.19], 'value', 0,'String','Trials','Callback',@showTrials,'KeyPressFcn', @keyPress,'tooltip','Show trial data');
        UI.panel.behavior.previousTrial = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.49 0.22 0.24 0.19],'String','<','Callback',@previousTrial,'KeyPressFcn', @keyPress,'tooltip','Previous trial');
        UI.panel.behavior.nextTrial = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.75 0.22 0.24 0.19],'String','>','Callback',@nextTrial,'KeyPressFcn', @keyPress,'tooltip','Next trial');
        UI.panel.behavior.trialNumber = uicontrol('Parent',UI.panel.behavior.main,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.01 0.48 0.20],'HorizontalAlignment','center','tooltip','Trial number','Callback',@gotoTrial);
        UI.panel.behavior.trialCount = uicontrol('Parent',UI.panel.behavior.main,'Style', 'Edit', 'String', 'nTrials', 'Units','normalized', 'Position', [0.51 0.01 0.48 0.20],'HorizontalAlignment','center','Enable','off');
        
        % Defining flexible panel heights
        set(UI.panel.other.main, 'Heights', [200 95 95 140],'MinimumHeights',[220 100 100 150]);
        
        % Lower info panel elements
        uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', '   Time (s)', 'Units','normalized', 'Position', [0.1 0 0.05 0.8],'HorizontalAlignment','left');
        UI.elements.lower.time = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.15 0 0.05 1],'HorizontalAlignment','left','tooltip','Current timestamp (seconds)','Callback',@setTime);
        uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', '   Window duration (s)', 'Units','normalized', 'Position', [0.25 0 0.05 0.8],'HorizontalAlignment','left');
        UI.elements.lower.windowsSize = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', UI.settings.windowDuration, 'Units','normalized', 'Position', [0.3 0 0.05 1],'HorizontalAlignment','left','tooltip','Window size (seconds)','Callback',@setWindowsSize);
        uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', '   Scaling', 'Units','normalized', 'Position', [0.0 0 0.05 0.8],'HorizontalAlignment','left');
        UI.elements.lower.scaling = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', num2str(UI.settings.scalingFactor), 'Units','normalized', 'Position', [0.05 0 0.05 1],'HorizontalAlignment','left','tooltip','Ephys scaling','Callback',@setScaling);
        UI.elements.lower.performance = uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', 'Performance', 'Units','normalized', 'Position', [0.25 0 0.05 0.8],'HorizontalAlignment','left','KeyPressFcn', @keyPress);
        UI.elements.lower.slider = uicontrol(UI.panel.info,'Style','slider','Units','normalized','Position',[0.5 0 0.5 1],'Value',0, 'SliderStep', [0.0001, 0.1], 'Min', 0, 'Max', 100,'Callback',@moveSlider,'KeyPressFcn', @keyPress);
        set(UI.panel.info, 'Widths', [70 60 120 60 60 60 200 -1],'MinimumWidths',[70 60 120 60 60 60 180  1]); % set grid panel size
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating plot axes
        UI.plot_axis1 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0 0 1 1],'ButtonDownFcn',@ClickPlot,'Color',UI.settings.background,'XColor',UI.settings.xtickColor,'TickLength',[0.005, 0.001],'XMinorTick','on','XLim',[0,UI.settings.windowDuration],'YLim',[0,1],'YTickLabel',[],'Clipping','off');
        hold on
        UI.plot_axis1.XAxis.MinorTick = 'on';
        UI.plot_axis1.XAxis.MinorTickValues = 0:0.01:2;
        set(0,'units','pixels');
        ce_dragzoom(UI.plot_axis1,'on');
        UI.Pix_SS = get(0,'screensize');
        UI.Pix_SS = UI.Pix_SS(3)*2;
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Maximazing figure to full screen
        if ~verLessThan('matlab', '9.4')
            set(UI.fig,'WindowState','maximize','visible','on'), drawnow nocallbacks;
        else
            set(UI.fig,'visible','on')
            drawnow nocallbacks; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks;
        end
    end

    function plotData
        % Generates all data plots
        
        % Deletes existing plot data
        delete(UI.plot_axis1.Children)
        UI.settings.textOffset = 0;
        set(UI.plot_axis1,'XLim',[0,UI.settings.windowDuration],'YLim',[0,1])
        
        % Ephys traces
        plot_ephys
        
        % KiloSort data
        if UI.settings.showKilosort
            plotKilosortData(t0,t0+UI.settings.windowDuration,'c')
        end
        
        % Spike data
        if UI.settings.showSpikes
            plotSpikeData(t0,t0+UI.settings.windowDuration,'w')
        end
        
        % States data
        if UI.settings.showStates
            plotTemporalStates(t0,t0+UI.settings.windowDuration)
        end
        
        % Event data
        if UI.settings.showEvents
            plotEventData(t0,t0+UI.settings.windowDuration,'w','m')
        end
        
        % Time series
        if UI.settings.showTimeSeries
            plotTimeSeriesData(t0,t0+UI.settings.windowDuration,'m')
        end
        
        % Intan analog
        if UI.settings.intan_showAnalog
            plotAnalog('adc',data.session.extracellular.sr)
        end
        
        % Intan aux
        if UI.settings.intan_showAux
            plotAnalog('aux',data.session.extracellular.sr)
        end
        
        % Intan digital
        if UI.settings.intan_showDigital
            plotDigital('dig',data.session.extracellular.sr)
        end
        
        % Behavior
        if UI.settings.showBehavior
            plotBehavior(t0,t0+UI.settings.windowDuration,'m')
        end
        
        % Trials
        if UI.settings.showTrials
            plotTrials(t0,t0+UI.settings.windowDuration,'w')
        end
    end

    function plot_ephys
        % Loading and plotting ephys data
        % There are four plot styles, for optimized plotting performance
        % 1. Downsampled: Shows every 16th sample of the raw data (no filter or averaging)
        % 2. Range: Shows a sample count optimized to the screen resolution. For each sample the max and the min is plotted of data in that temporal range
        % 3. Raw: Raw data at full sampling rate
        % 4. LFP: .LFP file, typically the raw data has been downpass filtered and downsampled to 1250Hz before this. All samples are shown.
        %
        % Only data thas is not currently displayed will be loaded.
        
        if UI.settings.greyScaleTraces < 5
            colors = UI.colors/UI.settings.greyScaleTraces;
        elseif UI.settings.greyScaleTraces >=5
            colors = ones(size(UI.colors))/(UI.settings.greyScaleTraces-4);
            colors(1:2:end,:) = colors(1:2:end,:)-0.08*(9-UI.settings.greyScaleTraces);
        end
        
        if UI.settings.plotStyle == 4 % lfp file
            if UI.fid.lfp == -1
                UI.settings.stream = false;
                MsgLog('Failed to load LFP data',4);
                return
            end
            sr = data.session.extracellular.srLfp;
            fileID = UI.fid.lfp;
        else %  dat file
            if UI.fid.ephys == -1
                UI.settings.stream = false;
                MsgLog('Failed to load raw data',4);
                return
            end
            sr = data.session.extracellular.sr;
            fileID = UI.fid.ephys;
        end
        
        if strcmp(UI.settings.fileRead,'bof')
            % Loading data
            if t0>UI.t1 && t0 < UI.t1 + UI.settings.windowDuration && ~UI.forceNewData
                t_offset = t0-UI.t1;
                newSamples = round(UI.samplesToDisplay*t_offset/UI.settings.windowDuration);
                existingSamples = UI.samplesToDisplay-newSamples;
                % Keeping existing samples
                ephys.raw(1:existingSamples,:) = ephys.raw(newSamples+1:UI.samplesToDisplay,:);
                % Loading new samples
                fseek(fileID,round((t0+UI.settings.windowDuration-t_offset)*sr)*data.session.extracellular.nChannels*2,'bof'); % bof: beginning of file
                ephys.raw(existingSamples+1:UI.samplesToDisplay,:) = double(fread(fileID, [data.session.extracellular.nChannels, newSamples],'int16'))'*UI.settings.leastSignificantBit;
            elseif t0 < UI.t1 && t0 > UI.t1 - UI.settings.windowDuration && ~UI.forceNewData
                t_offset = UI.t1-t0;
                newSamples = round(UI.samplesToDisplay*t_offset/UI.settings.windowDuration);
                % Keeping existing samples
                existingSamples = UI.samplesToDisplay-newSamples;
                ephys.raw(newSamples+1:UI.samplesToDisplay,:) = ephys.raw(1:existingSamples,:);
                % Loading new data
                fseek(fileID,round(t0*sr)*data.session.extracellular.nChannels*2,'bof');
                ephys.raw(1:newSamples,:) = double(fread(fileID, [data.session.extracellular.nChannels, newSamples],'int16'))'*UI.settings.leastSignificantBit;
            elseif t0==UI.t1 && ~UI.forceNewData
            else
                fseek(fileID,round(t0*sr)*data.session.extracellular.nChannels*2,'bof');
                ephys.raw = double(fread(fileID, [data.session.extracellular.nChannels, UI.samplesToDisplay],'int16'))'*UI.settings.leastSignificantBit;
            end
            UI.forceNewData = false;
            
        else
            fseek(fileID,ceil(-UI.settings.windowDuration*sr)*data.session.extracellular.nChannels*2,'eof'); % eof: end of file
            ephys.raw = double(fread(fileID, [data.session.extracellular.nChannels, UI.samplesToDisplay],'int16'))'*UI.settings.leastSignificantBit;
            UI.forceNewData = true;
        end
        
        UI.t1 = t0;
        if isempty(ephys.raw)
            return
        end
        
        if UI.settings.filterTraces && UI.settings.plotStyle == 4
            if int_gt_0(UI.settings.filter.lowerBand) && ~int_gt_0(UI.settings.filter.higherBand)
                [b1, a1] = butter(3, UI.settings.filter.higherBand/sr*2, 'low');
            elseif int_gt_0(UI.settings.filter.higherBand) && ~int_gt_0(UI.settings.filter.lowerBand)
                [b1, a1] = butter(3, UI.settings.filter.lowerBand/sr*2, 'high');
            else
                [b1, a1] = butter(3, [UI.settings.filter.lowerBand,UI.settings.filter.higherBand]/sr*2, 'bandpass');
            end
            ephys.traces = filtfilt(b1, a1, ephys.raw * (UI.settings.scalingFactor)/1000000);
        elseif UI.settings.filterTraces
            ephys.traces = filtfilt(UI.settings.filter.b1, UI.settings.filter.a1, ephys.raw * (UI.settings.scalingFactor)/1000000);
        else
            ephys.traces = ephys.raw * (UI.settings.scalingFactor)/1000000;
        end
        
        if UI.settings.plotEnergy == 1
            if UI.settings.plotStyle == 4
                sr = data.session.extracellular.srLfp;
            else
                sr = data.session.extracellular.sr;
            end
            for i = 1:size(ephys.traces,2)
                ephys.traces(:,i) = 2*smooth(abs(ephys.traces(:,i)),round(UI.settings.energyWindow*sr),'moving');
            end
        end
        
        if UI.settings.plotStyle == 1 % Low sampled values (Faster plotting)
            for iShanks = UI.settings.electrodeGroupsToPlot
                channels = UI.channels{iShanks};
                [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
                line(UI.plot_axis1,[1:UI.nDispSamples]/UI.nDispSamples*UI.settings.windowDuration,ephys.traces(UI.dispSamples,channels)-UI.channelScaling(UI.dispSamples,channels),'color',colors(iShanks,:), 'HitTest','off');
            end
        elseif UI.settings.plotStyle == 2 && (UI.settings.windowDuration>=UI.settings.plotStyleDynamicThreshold || ~UI.settings.plotStyleDynamicRange) % Range values per sample (ala Neuroscope1)
            ephys_traces2 = reshape(ephys.traces,UI.settings.plotStyleRangeSamples*UI.settings.windowDuration,[]);
            ephys.traces_min = reshape(min(ephys_traces2),[],size(ephys.traces,2));
            ephys.traces_max = reshape(max(ephys_traces2),[],size(ephys.traces,2));
            for iShanks = UI.settings.electrodeGroupsToPlot
                tist = [];
                timeLine = [];
                channels = UI.channels{iShanks};
                [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
                tist(1,:,:) = ephys.traces_min(:,channels)-UI.channelScaling([1:size(ephys.traces_min,1)],channels);
                tist(2,:,:) = ephys.traces_max(:,channels)-UI.channelScaling([1:size(ephys.traces_min,1)],channels);
                tist(:,end+1,:) = nan;
                timeLine1 = repmat([1:size(ephys.traces_min,1)]/size(ephys.traces_min,1)*UI.settings.windowDuration,numel(channels),1)';
                timeLine(1,:,:) = timeLine1;
                timeLine(2,:,:) = timeLine1;
                timeLine(:,end+1,:) = timeLine(:,end,:);
                line(UI.plot_axis1,timeLine(:)',tist(:)','color',colors(iShanks,:)','LineStyle','-', 'HitTest','off');
            end
        else
            timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
            for iShanks = UI.settings.electrodeGroupsToPlot
                channels = UI.channels{iShanks};
                if ~isempty(channels)
                    [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
                    line(UI.plot_axis1,timeLine,ephys.traces(:,channels)-UI.channelScaling(:,channels),'color',colors(iShanks,:),'LineStyle','-', 'HitTest','off');
                end
            end
        end
        if ~isempty(UI.settings.channelTags.highlight)
            for i = 1:numel(UI.settings.channelTags.highlight)
                channels = data.session.channelTags.(UI.channelTags{UI.settings.channelTags.highlight(i)}).channels;
                if ~isempty(channels)
                    channels = UI.channelMap(channels); channels(channels==0) = [];
                    if ~isempty(channels)
                        highlightTraces(channels,UI.colors_tags(UI.settings.channelTags.highlight(i),:));
                    end
                end
            end
        end
        
        % Detecting and plotting spikes
        if UI.settings.detectSpikes
            if UI.settings.plotStyle == 4
                [UI.settings.filter.b2, UI.settings.filter.a2] = butter(3, 500/(data.session.extracellular.srLfp/2), 'high');
            else
                [UI.settings.filter.b2, UI.settings.filter.a2] = butter(3, 500/(data.session.extracellular.sr/2), 'high');
            end
            ephys.filt = filtfilt(UI.settings.filter.b2, UI.settings.filter.a2, ephys.raw);
            
            raster = [];
            raster.x = [];
            raster.y = [];
            for i = 1:size(ephys.filt,2)
                idx = find(diff(ephys.filt(:,i) < UI.settings.spikesDetectionThreshold)==1)+1;
                if ~isempty(idx)
                    raster.x = [raster.x;idx];
                    %                     raster.y = [raster.y;i*ones(numel(idx),1)];
                    raster.y = [raster.y;ephys.traces(idx,i)-UI.channelScaling(idx,i)];
                end
            end
            [~,ia] = sort(UI.channelOrder);
            ia = -0.9*((ia-1)/(numel(UI.channelOrder)-1))-0.05+1;
            ia2 = 1:data.session.extracellular.nChannels;
            isx = find(ismember(ia2,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
            ia2(isx) = ia;
            if UI.settings.showSpikes
                markerType = 'o';
            else
                markerType = UI.settings.rasterMarker;
            end
            line(raster.x/size(ephys.traces,1)*UI.settings.windowDuration, raster.y,'Marker',markerType,'LineStyle','none','color','w', 'HitTest','off');
        end
        
        % Detecting and plotting events
        if UI.settings.detectEvents
            raster = [];
            raster.x = [];
            raster.y = [];
            for i = 1:size(ephys.traces,2)
                if UI.settings.eventThreshold>0
                    idx = find(diff(ephys.traces(:,i)/(UI.settings.scalingFactor/1000000) > UI.settings.eventThreshold)==1);
                else
                    idx = find(diff(ephys.traces(:,i)/(UI.settings.scalingFactor/1000000) < UI.settings.eventThreshold)==1);
                end
                if ~isempty(idx)
                    raster.x = [raster.x;idx];
                    raster.y = [raster.y;ephys.traces(idx,i)-UI.channelScaling(idx,i)];
                end
            end
            [~,ia] = sort(UI.channelOrder);
            ia = -0.9*((ia-1)/(numel(UI.channelOrder)-1))-0.05+1;
            ia2 = 1:data.session.extracellular.nChannels;
            isx = find(ismember(ia2,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
            ia2(isx) = ia;
            
            line(raster.x/size(ephys.traces,1)*UI.settings.windowDuration, raster.y,'Marker',UI.settings.rasterMarker,'LineStyle','none','color','m', 'HitTest','off');
        end
    end


    function plotAnalog(signal,sr)
        % Plotting analog traces
        if strcmp(UI.settings.fileRead,'bof')
            fseek(UI.fid.timeSeries.(signal),round(t0*sr)*data.session.timeSeries.(signal).nChannels*2,'bof'); % eof: end of file
        else
            fseek(UI.fid.timeSeries.(signal),ceil(-UI.settings.windowDuration*sr)*data.session.timeSeries.(signal).nChannels*2,'eof'); % eof: end of file
        end
        traces_analog = fread(UI.fid.timeSeries.(signal), [data.session.timeSeries.(signal).nChannels, UI.samplesToDisplay],'uint16')';
        if UI.settings.showIntanBelowTrace
            line((1:UI.nDispSamples)/UI.nDispSamples*UI.settings.windowDuration,traces_analog(UI.dispSamples,:)./2^16*diff(UI.dataRange.intan)+UI.dataRange.intan(1), 'HitTest','off','Marker','none','LineStyle','-','linewidth',1);
        else
            line((1:UI.nDispSamples)/UI.nDispSamples*UI.settings.windowDuration,traces_analog(UI.dispSamples,:)./2^16, 'HitTest','off','Marker','none','LineStyle','-','linewidth',1.5);
        end
        for i = 1:data.session.timeSeries.(signal).nChannels
            text(UI.settings.windowDuration-1/400,0.005+(UI.settings.textOffset+i-1)*0.012+UI.dataRange.intan(1),UI.settings.traceLabels.(signal){i},'color',UI.colorLine(i,:),'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7],'VerticalAlignment', 'bottom','Units','normalized','HorizontalAlignment','right')
        end
        UI.settings.textOffset = UI.settings.textOffset + data.session.timeSeries.(signal).nChannels;
    end

    function plotDigital(signal,sr)
        % Plotting digital traces
        if strcmp(UI.settings.fileRead,'bof')
            fseek(UI.fid.timeSeries.(signal),round(t0*sr)*2,'bof');
        else
            fseek(UI.fid.timeSeries.(signal),ceil(-UI.settings.windowDuration*sr)*2,'eof');
        end
        traces_digital = fread(UI.fid.timeSeries.(signal), [UI.samplesToDisplay],'uint16')';
        traces_digital2 = [];
        for i = 1:data.session.timeSeries.dig.nChannels
            traces_digital2(:,i) = bitget(traces_digital,i)+i*0.001;
        end
        if UI.settings.showIntanBelowTrace
            line((1:UI.nDispSamples)/UI.nDispSamples*UI.settings.windowDuration,0.98*traces_digital2(UI.dispSamples,:)*diff(UI.dataRange.intan)+UI.dataRange.intan(1)+0.004, 'HitTest','off','Marker','none','LineStyle','-');
        else
            line((1:UI.nDispSamples)/UI.nDispSamples*UI.settings.windowDuration,0.98*traces_digital2(UI.dispSamples,:)+0.005, 'HitTest','off','Marker','none','LineStyle','-');
        end
        for i = 1:data.session.timeSeries.(signal).nChannels
            text(UI.settings.windowDuration-1/400,0.005+(UI.settings.textOffset+i-1)*0.012+UI.dataRange.intan(1),UI.settings.traceLabels.(signal){i},'color',UI.colorLine(i,:),'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7],'VerticalAlignment', 'bottom','Units','normalized','HorizontalAlignment','right')
        end
        UI.settings.textOffset = UI.settings.textOffset + data.session.timeSeries.(signal).nChannels;
    end

    function highlightTraces(channels,colorIn)
        % Highlight ephys channel(s)
        if ~isempty(colorIn)
            colorLine = colorIn;
        else
            UI.iLine = mod(UI.iLine,7)+1;
            colorLine = UI.colorLine(UI.iLine,:);
        end
        
        if size(UI.channelScaling,2)>0
            if UI.settings.plotStyle == 1
                line(UI.plot_axis1,[1:UI.nDispSamples]/UI.nDispSamples*UI.settings.windowDuration,ephys.traces(UI.dispSamples,channels)-UI.channelScaling(UI.dispSamples,channels), 'HitTest','off','linewidth',1.2,'color',colorLine);
            elseif UI.settings.plotStyle == 2 && (UI.settings.windowDuration>=UI.settings.plotStyleDynamicThreshold || ~UI.settings.plotStyleDynamicRange)
                tist = [];
                timeLine = [];
                tist(1,:,:) = ephys.traces_min(:,channels)-UI.channelScaling([1:size(ephys.traces_min,1)],channels);
                tist(2,:,:) = ephys.traces_max(:,channels)-UI.channelScaling([1:size(ephys.traces_min,1)],channels);
                tist(:,end+1,:) = nan;
                timeLine1 = repmat([1:size(ephys.traces_min,1)]/size(ephys.traces_min,1)*UI.settings.windowDuration,numel(channels),1)';
                timeLine(1,:,:) = timeLine1;
                timeLine(2,:,:) = timeLine1;
                timeLine(:,end+1,:) = timeLine(:,end,:);
                line(UI.plot_axis1,timeLine(:)',tist(:)','LineStyle','-', 'HitTest','off','linewidth',1.2,'color',colorLine);
            else
                timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
                line(UI.plot_axis1,timeLine,ephys.traces(:,channels)-UI.channelScaling(:,channels),'LineStyle','-', 'HitTest','off','linewidth',1.2,'color',colorLine);
            end
        end
    end

    function plotBehavior(t1,t2,colorIn)
        % Plots behavior
        idx = find((data.behavior.(UI.settings.behaviorData).time > t1 & data.behavior.(UI.settings.behaviorData).time < t2));
        if ~isempty(idx)
            if UI.settings.plotBehaviorLinearized
                if UI.settings.showBehaviorBelowTrace
                    line(data.behavior.(UI.settings.behaviorData).time(idx)-t1,data.behavior.(UI.settings.behaviorData).pos_linearized(idx)/data.behavior.(UI.settings.behaviorData).pos_linearized_limits(2)*diff(UI.dataRange.behavior)+UI.dataRange.behavior(1), 'Color', colorIn, 'HitTest','off','Marker','none','LineStyle','-','linewidth',2)
                else
                    line(data.behavior.(UI.settings.behaviorData).time(idx)-t1,data.behavior.(UI.settings.behaviorData).pos_linearized(idx)/data.behavior.(UI.settings.behaviorData).pos_linearized_limits(2), 'Color', colorIn, 'HitTest','off','Marker','none','LineStyle','-','linewidth',2)
                end
            else
                p1 = patch([5*(t2-t1)/6,(t2-t1),(t2-t1),5*(t2-t1)/6]-0.01,[0 0 0.25 0.25]+0.01,'k','HitTest','off','EdgeColor','none');
                alpha(p1,0.4);
                line((data.behavior.(UI.settings.behaviorData).pos(1,idx)-data.behavior.xlim(1))/diff(data.behavior.xlim)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).pos(2,idx)-data.behavior.ylim(1))/diff(data.behavior.ylim)*0.25+0.01, 'Color', colorIn, 'HitTest','off','Marker','none','LineStyle','-','linewidth',2)
                idx2 = [idx(1),idx(round(end/4)),idx(round(end/2)),idx(round(3*end/4))];
                line((data.behavior.(UI.settings.behaviorData).pos(1,idx2)-data.behavior.xlim(1))/diff(data.behavior.xlim)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).pos(2,idx2)-data.behavior.ylim(1))/diff(data.behavior.ylim)*0.25+0.01, 'Color', [0.9,0.5,0.9], 'HitTest','off','Marker','o','LineStyle','none','linewidth',0.5,'MarkerFaceColor',[0.9,0.5,0.9],'MarkerEdgeColor',[0.9,0.5,0.9]);
                line((data.behavior.(UI.settings.behaviorData).pos(1,idx(end))-data.behavior.xlim(1))/diff(data.behavior.xlim)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).pos(2,idx(end))-data.behavior.ylim(1))/diff(data.behavior.ylim)*0.25+0.01, 'Color', [1,0.7,1], 'HitTest','off','Marker','s','LineStyle','none','linewidth',0.5,'MarkerFaceColor',[1,0.7,1],'MarkerEdgeColor',[1,0.7,1]);
            end
        end
    end

    function plotSpikeData(t1,t2,colorIn)
        % Plots spikes
        
        % Determining which units to plot from various filters
        units2plot = [find(ismember(data.spikes.maxWaveformCh1,[UI.channels{UI.settings.electrodeGroupsToPlot}])),UI.params.subsetTable,UI.params.subsetCellType,UI.params.subsetFilter,UI.params.subsetGroups];
        units2plot = find(histcounts(units2plot,1:data.spikes.numcells+1)==5);
        
        % Finding the spikes in the spindices to plot by index
        idx = find(data.spikes.spindices(:,1) > t1 & data.spikes.spindices(:,1) < t2);
        idx = idx(ismember(data.spikes.spindices(idx,2),units2plot));
        
        spikes_raster = [];
        if any(idx)
            spikes_raster.x = data.spikes.spindices(idx,1)-t1;
            spikes_raster.UID = data.spikes.spindices(idx,2);
            idx2 = ceil(spikes_raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.spikesBelowTrace
                if UI.settings.useSpikesYData
                    spikes_raster.y = (diff(UI.dataRange.spikes))*((data.spikes.spindices(idx,3)-UI.settings.spikes_ylim(1))/diff(UI.settings.spikes_ylim))+UI.dataRange.spikes(1);
                else
                    if UI.settings.useMetrics
                        [~,sortIdx] = sort(data.cell_metrics.(UI.params.sortingMetric));
                        [~,sortIdx] = sort(sortIdx);
                    else
                        sortIdx = 1:data.spikes.numcells;
                    end
                    spikes_raster.y = (diff(UI.dataRange.spikes))*(sortIdx(data.spikes.spindices(idx,2))/(data.spikes.numcells))+UI.dataRange.spikes(1);
                end
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(idx,2))');
                spikes_raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            if UI.settings.spikesGroupColors == 3
                % UI.params.sortingMetric = 'putativeCellType';
                putativeCellTypes = unique(data.cell_metrics.(UI.params.groupMetric));
                UI.colors_metrics = hsv(numel(putativeCellTypes));
                k = 1;
                for i = 1:numel(putativeCellTypes)
                    idx2 = find(ismember(data.cell_metrics.(UI.params.groupMetric),putativeCellTypes{i}));
                    idx3 = ismember(data.spikes.spindices(idx,2),idx2);
                    if any(idx3)
                        line(spikes_raster.x(idx3), spikes_raster.y(idx3),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',UI.colors_metrics(i,:), 'HitTest','off');
                        text(1/400,0.005+(k-1)*0.012+UI.dataRange.spikes(1),putativeCellTypes{i},'color',UI.colors_metrics(i,:)*0.8,'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7],'VerticalAlignment', 'bottom','Units','normalized')
                        k = k+1;
                    end
                end
            elseif UI.settings.spikesGroupColors == 1
                uid = data.spikes.spindices(idx,2);
                unique_uids = unique(uid);
                uid_colormap = eval([UI.settings.spikesColormap,'(',num2str(numel(unique_uids)),')']);
                for i = 1:numel(unique_uids)
                    idx_uids = uid == unique_uids(i);
                    line(spikes_raster.x(idx_uids), spikes_raster.y(idx_uids),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',uid_colormap(i,:), 'HitTest','off');
                end
            else
                line(spikes_raster.x, spikes_raster.y,'Marker',UI.settings.rasterMarker,'LineStyle','none','color',colorIn, 'HitTest','off');
            end
            
            
            % Highlights cells ('tags','groups','groundTruthClassification')
            if ~isempty(UI.groupData1)
                uids_toHighlight = [];
                dataTypes = {'tags','groups','groundTruthClassification'};
                for jjj = 1:numel(dataTypes)
                    if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'highlight')
                        fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).highlight);
                        for jj = 1:numel(fields1)
                            if UI.groupData1.(dataTypes{jjj}).highlight.(fields1{jj}) == 1 && ~isempty(data.cell_metrics.(dataTypes{jjj}).(fields1{jj})) && any(ismember(units2plot,data.cell_metrics.(dataTypes{jjj}).(fields1{jj})))
                                idx_groupData1 = intersect(units2plot,data.cell_metrics.(dataTypes{jjj}).(fields1{jj}));
                                uids_toHighlight = [uids_toHighlight,idx_groupData1];
                            end
                        end
                    end
                end
                if ~isempty(uids_toHighlight)
                    highlightUnits(unique(uids_toHighlight),t1,t2);
                end
            end
        end
    end
    
    function highlightUnits(units2plot,t1,t2)
        
        % Plots spikes
        idx = ismember(data.spikes.spindices(:,2),units2plot) & ismember(data.spikes.spindices(:,2),UI.params.subsetTable ) & ismember(data.spikes.spindices(:,2),UI.params.subsetCellType) & ismember(data.spikes.spindices(:,2),UI.params.subsetFilter) & ismember(data.spikes.spindices(:,2),UI.params.subsetGroups)  & data.spikes.spindices(:,1) > t1 & data.spikes.spindices(:,1) < t2;
        if any(idx)
            raster = [];
            raster.x = data.spikes.spindices(idx,1)-t1;
            idx2 = ceil(raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.spikesBelowTrace
                if UI.settings.useSpikesYData
                    raster.y = (diff(UI.dataRange.spikes))*((data.spikes.spindices(idx,3)-UI.settings.spikes_ylim(1))/diff(UI.settings.spikes_ylim))+UI.dataRange.spikes(1);
                else
                    if UI.settings.useMetrics
                        [~,sortIdx] = sort(data.cell_metrics.(UI.params.sortingMetric));
                        [~,sortIdx] = sort(sortIdx);
                    else
                        sortIdx = 1:data.spikes.numcells;
                    end
                    raster.y = (diff(UI.dataRange.spikes))*(sortIdx(data.spikes.spindices(idx,2))/(data.spikes.numcells))+UI.dataRange.spikes(1);
                end
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(idx,2))');
                raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            
            uid = data.spikes.spindices(idx,2);
            unique_uids = unique(uid);
            uid_colormap = eval([UI.settings.spikesColormap,'(',num2str(numel(unique_uids)),')']);
            if numel(unique_uids) == 1
                UI.iLine = mod(UI.iLine,7)+1;
                colorLine = UI.colorLine(UI.iLine,:);
                line(raster.x, raster.y,'Marker',UI.settings.rasterMarker,'LineStyle','none','color',colorLine, 'HitTest','off','linewidth',3);
            else
            for i = 1:numel(unique_uids)
                idx_uids = uid == unique_uids(i);
                line(raster.x(idx_uids), raster.y(idx_uids),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',uid_colormap(i,:), 'HitTest','off','linewidth',3);
            end
            end
        end
    end

    function plotKilosortData(t1,t2,colorIn)
        % Plots spikes
        units2plot = find(ismember(data.spikes_kilosort.maxWaveformCh1,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
        idx = data.spikes_kilosort.spindices(:,1) > t1 & data.spikes_kilosort.spindices(:,1) < t2;
        if any(idx)
            raster = [];
            raster.x = data.spikes_kilosort.spindices(idx,1)-t1;
            idx2 = ceil(raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.spikesBelowTrace
                sortIdx = 1:data.spikes_kilosort.numcells;
                raster.y = (diff(UI.dataRange.spikes))*(sortIdx(data.spikes_kilosort.spindices(idx,2))/(data.spikes_kilosort.numcells))+UI.dataRange.spikes(1);
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes_kilosort.maxWaveformCh1(data.spikes_kilosort.spindices(idx,2))');
                raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            line(raster.x, raster.y,'Marker','o','LineStyle','none','color',colorIn, 'HitTest','off');
        end
    end

    function plotEventData(t1,t2,colorIn1,colorIn2)
        % Plot events
        ydata = UI.dataRange.events';
        if UI.settings.showEventsBelowTrace && UI.settings.showEvents
            linewidth = 1.5;
        else
            linewidth = 0.8;
        end
        idx = find(data.events.(UI.settings.eventData).time >= t1 & data.events.(UI.settings.eventData).time <= t2);
        % Plotting flagged events in a different color
        if isfield(data.events.(UI.settings.eventData),'flagged')
            idx2 = ismember(idx,data.events.(UI.settings.eventData).flagged);
            if any(idx2)
                line([1;1]*data.events.(UI.settings.eventData).time(idx(idx2))'-t1,ydata*ones(1,sum(idx2)),'Marker','none','LineStyle','-','color','m', 'HitTest','off','linewidth',linewidth);
            end
            idx(idx2) = [];
        end
        % Plotting events 
        if any(idx)
            line([1;1]*data.events.(UI.settings.eventData).time(idx)'-t1,ydata*ones(1,numel(idx)),'Marker','none','LineStyle','-','color',colorIn1, 'HitTest','off','linewidth',linewidth);
        end
        
        % Plotting added events 
        if isfield(data.events.(UI.settings.eventData),'added') && ~isempty(isfield(data.events.(UI.settings.eventData),'added'))
            idx3 = find(data.events.(UI.settings.eventData).added >= t1 & data.events.(UI.settings.eventData).added <= t2);
            if any(idx3)
                line([1;1]*data.events.(UI.settings.eventData).added(idx3)'-t1,ydata*ones(1,numel(idx3)),'Marker','none','LineStyle','--','color','c', 'HitTest','off','linewidth',linewidth);
            end
        end
            
        if UI.settings.processing_steps && isfield(data.events.(UI.settings.eventData),'processing_steps')
            fields2plot = fieldnames(data.events.(UI.settings.eventData).processing_steps);
            UI.colors_processing_steps = hsv(numel(fields2plot));
            ydata1 = [0;0.005]+0.04*UI.settings.showStates;
            for i = 1:numel(fields2plot)
                idx = find(data.events.(UI.settings.eventData).processing_steps.(fields2plot{i}) >= t1 & data.events.(UI.settings.eventData).processing_steps.(fields2plot{i}) <= t2);
                if any(idx)
                    line([1;1]*data.events.(UI.settings.eventData).processing_steps.(fields2plot{i})(idx)'-t1,0.005*i+ydata1*ones(1,numel(idx)),'Marker','none','LineStyle','-','color',UI.colors_processing_steps(i,:), 'HitTest','off','linewidth',1.3);
                    text(1/400,0.005+i*0.012+ydata(1),fields2plot{i},'color',UI.colors_processing_steps(i,:)*0.8,'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7], 'HitTest','off','Units','normalized')
                else
                    text(1/400,0.005+i*0.012+ydata(1),fields2plot{i},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7], 'HitTest','off','Units','normalized')
                end
            end
        end
        if UI.settings.showEventsIntervals
            statesData = data.events.(UI.settings.eventData).timestamps(idx,:)-t1;
            p1 = patch(double([statesData,flip(statesData,2)])',[ydata(1);ydata(1);ydata(2);ydata(2)]*ones(1,size(statesData,1)),'r','EdgeColor','r','HitTest','off');
            alpha(p1,0.1);
        end
        if isfield(data.events.(UI.settings.eventData),'detectorParams')
            detector_channel = data.events.(UI.settings.eventData).detectorParams.channel;
        elseif isfield(data.events.(UI.settings.eventData),'detectorinfo') & isfield(data.events.(UI.settings.eventData).detectorinfo,'detectionchannel')
            detector_channel = data.events.(UI.settings.eventData).detectorinfo.detectionchannel;
        else
            detector_channel = [];
        end
        if ~isempty(detector_channel)
            highlightTraces(detector_channel+1,'w')
        end
    end

    function plotTimeSeriesData(t1,t2,colorIn)
        % Plot time series
        idx = data.timeseries.(UI.settings.timeseriesData).timestamps>t1 & data.timeseries.(UI.settings.timeseriesData).timestamps<t2;
        if any(idx)
            line((data.timeseries.(UI.settings.timeseriesData).timestamps(idx)-t1),(data.timeseries.(UI.settings.timeseriesData).data(idx) - UI.settings.timeseries.lowerBoundary)/(UI.settings.timeseries.upperBoundary-UI.settings.timeseries.lowerBoundary),'Marker','.','LineStyle','-','color',colorIn, 'HitTest','off');
        end
    end

    function plotTrials(t1,t2,colorIn)
        % Plot trials
        intervals = data.behavior.(UI.settings.behaviorData).time([data.behavior.trials.start;data.behavior.trials.end])';
        idx = (intervals(:,1)<t2 & intervals(:,2)>t1);
        patch_range = UI.dataRange.trials;
        if any(idx)
            intervals = intervals(idx,:)-t1;
            p1 = patch(double([intervals,flip(intervals,2)])',[patch_range(1);patch_range(1);patch_range(2);patch_range(2)]*ones(1,size(intervals,1)),'g','EdgeColor','g','HitTest','off');
            alpha(p1,0.3);
            text(intervals(:,1),patch_range(2)*ones(1,size(intervals,1)),strcat({' Trial '}, num2str(find(idx))),'FontWeight', 'Bold','Color','w','margin',0.1,'VerticalAlignment', 'top')
        end
    end

    function plotTemporalStates(t1,t2)
        % Plot states
        if isfield(data,'states')
            if isfield(data.states.(UI.settings.statesData),'ints')
                states1  = data.states.(UI.settings.statesData).ints;
            else
                states1  = data.states.(UI.settings.statesData);
            end
            stateNames = fieldnames(states1);
            clr_states = eval([UI.settings.colormap,'(',num2str(numel(stateNames)),')']);
            for jj = 1:numel(stateNames)
                if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
                    idx = (states1.(stateNames{jj})(:,1)<t2 & states1.(stateNames{jj})(:,2)>t1);
                    if any(idx)
                        statesData = states1.(stateNames{jj})(idx,:)-t1;
                        p1 = patch(double([statesData,flip(statesData,2)])',[UI.dataRange.states(1);UI.dataRange.states(1);UI.dataRange.states(2);UI.dataRange.states(2)]*ones(1,size(statesData,1)),clr_states(jj,:),'EdgeColor',clr_states(jj,:),'HitTest','off');
                        alpha(p1,0.3);
                        text(1/400,0.005+(jj-1)*0.012+UI.dataRange.states(1),stateNames{jj},'color',clr_states(jj,:)*0.8,'FontWeight', 'Bold','Color', clr_states(jj,:),'BackgroundColor',[0 0 0 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
                    else
                        text(1/400,0.005+(jj-1)*0.012+UI.dataRange.states(1),stateNames{jj},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[0 0 0 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
                    end
                end
            end
        end
    end

    function viewSessionMetaData(~,~)
        % Opens the gui_session for the current session to editing metadata
        data.session = gui_session(data.session);
        initData(basepath,basename);
        initTraces;
        uiresume(UI.fig);
    end

    function openSessionDirectory(~,~)
        % opens the basepath in the file browser
        if ispc
            winopen(basepath);
        elseif ismac
            syscmd = ['open ', basepath, ' &'];
            system(syscmd);
        else
            filebrowser;
        end
    end
    
    function defineGroupData(~,~)
        if isfield(data,'cell_metrics')
            [data.cell_metrics,UI] = dialog_metrics_groupData(data.cell_metrics,UI);
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
                                if UI.groupData1.(dataTypes{jjj}).plus_filter.(fields1{jj}) == 1 && isfield(data.cell_metrics.(dataTypes{jjj}),fields1{jj})  && ~isempty(data.cell_metrics.(dataTypes{jjj}).(fields1{jj}))
                                    filter_pos = [filter_pos,data.cell_metrics.(dataTypes{jjj}).(fields1{jj})];
                                end
                            end
                        end
                    end
                    if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'minus_filter') && any(struct2array(UI.groupData1.(dataTypes{jjj}).minus_filter))
                        if isfield(UI.groupData1,dataTypes{jjj}) && isfield(UI.groupData1.(dataTypes{jjj}),'minus_filter')
                            fields1 = fieldnames(UI.groupData1.(dataTypes{jjj}).minus_filter);
                            for jj = 1:numel(fields1)
                                if UI.groupData1.(dataTypes{jjj}).minus_filter.(fields1{jj}) == 1 && isfield(data.cell_metrics.(dataTypes{jjj}),fields1{jj}) && ~isempty(data.cell_metrics.(dataTypes{jjj}).(fields1{jj}))
                                    filter_neg = [filter_neg,data.cell_metrics.(dataTypes{jjj}).(fields1{jj})];
                                end
                            end
                        end
                    end
                end
                if ~isempty(filter_neg)
                    UI.params.subsetGroups = setdiff(UI.params.subsetGroups,filter_neg);
                end
                if ~isempty(filter_pos)
                    UI.params.subsetGroups = intersect(UI.params.subsetGroups,filter_pos);
                end
            else
                UI.params.subsetGroups = 1:data.spikes.numcells;
            end
        end
    end
    
%     function openCellExplorer(~,~)
%         % Opens CellExplorer for the current session
%         if ~isfield(data,'cell_metrics') && exist(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']),'file')
%             data.cell_metrics = loadCellMetrics('session',data.session);
%         elseif ~exist(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']),'file')
%             UI.panel.cell_metrics.useMetrics.Value = 0;
%             MsgLog('Cell_metrics does not exist',4);
%             return
%         end
%         data.cell_metrics = CellExplorer('metrics',data.cell_metrics);
%         toggleMetrics
%         uiresume(UI.fig);
%     end
    
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
        AboutWindow.dialog = figure('Position', fig_size,'Name','About NeuroScope2', 'MenuBar', 'None','NumberTitle','off','visible','off', 'resize', 'off'); movegui(AboutWindow.dialog,'center'), set(AboutWindow.dialog,'visible','on')
        [img, ~, alphachannel] = imread(fullfile(logog_path,'logoCellExplorer.png'));
        image(img, 'AlphaData', alphachannel,'ButtonDownFcn',@openWebsite);
        AboutWindow.image = gca;
        set(AboutWindow.image,'Color','none','Units','Pixels') , hold on, axis off
        AboutWindow.image.Position = pos_image;
        text(0,pos_text,{'\bfNeuroScope2\rm - part of CellExplorer','By Peter Petersen.', 'Developed in the Buzsaki laboratory at NYU, USA.','\bf\color[rgb]{0. 0.2 0.5}https://CellExplorer.org/\rm'},'HorizontalAlignment','left','VerticalAlignment','top','ButtonDownFcn',@openWebsite, 'interpreter','tex')
    end
    
    function exitNeuroScope2(~,~)
    	close(UI.fig);
    end
        
    function DatabaseSessionDialog(~,~)
        % Load sessions from the database.
        % Dialog is shown with sessions from the database with calculated cell metrics.
        % Then selected session is loaded from the database
        
        [basenames,basepaths] = gui_db_sessions(basename);
        try
            if ~isempty(basenames)
                data = [];
                basepath = basepaths{1};
                basename = basenames{1};
                initData(basepath,basename);
                initTraces;
                uiresume(UI.fig);
                MsgLog(['Session loaded succesful: ' basename],2)
            end
        catch
            MsgLog(['Failed to loaded session: ' basename],4)
        end
    end
    
    function editDBcredentials(~,~)
        edit db_credentials.m
    end
    
    function editDBrepositories(~,~)
        edit db_local_repositories.m
    end
    
    function openSessionInWebDB(~,~)
        % Opens the current session in the Buzsaki lab web database
        web(['https://buzsakilab.com/wp/sessions/?frm_search=', basename],'-new','-browser')
    end

    function showAnimalInWebDB(~,~)
        % Opens the current animal in the Buzsaki lab web database
        if isfield(data.session.animal,'name')
            web(['https://buzsakilab.com/wp/animals/?frm_search=', data.session.animal.name],'-new','-browser')
        else
            web('https://buzsakilab.com/wp/animals/','-new','-browser')
        end
    end
    
    function ScrolltoZoomInPlot(~,evnt)
        handle34 = UI.plot_axis1;
        um_axes = get(handle34,'CurrentPoint');
        u = um_axes(1,1);
        v = um_axes(1,2);
        cursorPosition = [u;v];
        b = get(handle34,'Xlim');
        c = get(handle34,'Ylim');
        axesLimits = [b;c];
        globalZoom1 = [[0,UI.settings.windowDuration];[0,1]];
        if evnt.VerticalScrollCount<0
            direction = 1;% positive scroll direction (zoom out)
        else
            direction = -1; % Negative scroll direction (zoom in)
        end
        applyZoom(globalZoom1,cursorPosition,axesLimits,direction);
        
        function applyZoom(globalZoom1,cursorPosition,axesLimits,direction)
            zoomInFactor = 0.85;
            zoomOutFactor = 1.6;
            u = cursorPosition(1);
            v = cursorPosition(2);
            b = axesLimits(1,:);
            c = axesLimits(2,:);
            
            if direction == 1 % zoom in
                
                if u < b(1) || u > b(2)
                    % Vertical scrolling
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1
                        ylim([y1,y2]);
                    end
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1
                        xlim([x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomInFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomInFactor);
                    if x2>x1
                        xlim([x1,x2]);
                    end
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomInFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomInFactor);
                    if y2>y1
                        ylim([y1,y2]);
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
                    if y2>y1
                        ylim([y1,y2]);
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
                    if x2>x1
                        xlim([x1,x2]);
                    end
                else
                    % Global scrolling
                    x1 = max(globalZoom1(1,1),u-diff(b)/2*zoomOutFactor);
                    x2 = min(globalZoom1(1,2),u+diff(b)/2*zoomOutFactor);
                    y1 = max(globalZoom1(2,1),v-diff(c)/2*zoomOutFactor);
                    y2 = min(globalZoom1(2,2),v+diff(c)/2*zoomOutFactor);
                    
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
                    
                    if x2>x1
                        xlim([x1,x2]);
                    end
                    if y2>y1
                        ylim([y1,y2]);
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

    function keyPress(~, event)
        % Handles keyboard shortcuts
        UI.settings.stream = false;
        if isempty(event.Modifier)
            switch event.Key
                case 'rightarrow'
                    advance
                case 'leftarrow'
                    back
                case 'm'
                    % Hide/show menubar
                    ShowHideMenu
                case 'q'
                    increaseWindowsSize
                case 'a'
                    decreaseWindowsSize
                case 'g'
                    goToTimestamp
                case 's'
                    toggleSpikes
                case 'e'
                    showEvents
                case 't'
                    showTimeSeries
                case 'numpad0'
                    t0 = 0;
                    uiresume(UI.fig);
                case 'decimal'
                    t0 = UI.t_total-UI.settings.windowDuration;
                    uiresume(UI.fig);
                case 'backspace'
                    if numel(UI.t0_track)>1
                        UI.t0_track(end) = [];
                    end
                    UI.track = false;
                    t0 = UI.t0_track(end);
                    uiresume(UI.fig);
                case 'uparrow'
                    increaseAmplitude
                case 'downarrow'
                    decreaseAmplitude
                case 'c'
                    answer = inputdlg('Provide channels to highlight','Highlighting');
                    if ~isempty(answer) & isnumeric(str2num(answer{1})) & all(str2num(answer{1})>0)
                        highlightTraces(str2num(answer{1}),[]);
                    end
                case 'h'
                    HelpDialog
                case 'period'
                    nextEvent
                case 'comma'
                    previousEvent
                case 'f'
                    flagEvent
                case 'l'
                    addEvent
                case 'slash'
                    randomEvent
                case 'shift'
                    UI.settings.normalClick = false;
            end
        elseif strcmp(event.Modifier,'shift')
            UI.settings.normalClick = false;
            switch event.Key
                case 'space'
                    streamData
                case 'rightarrow'
                    advance_fast
                case 'leftarrow'
                    back_fast
                case 'period'
                    nextPowerEvent
                case 'comma'
                    previousPowerEvent
                case 'slash'
                    maxPowerEvent
            end
        elseif strcmp(event.Modifier,'control')
            switch event.Key
                case 'space'
                    streamData2
            end
        end
    end
    
    function keyRelease(~, event)
        if strcmp(event.Key,'shift')
            UI.settings.normalClick = true;
        end
    end
    
    function ShowHideMenu(~,~)
        % Hide/show menubar
        if UI.preferences.displayMenu == 0
            set(UI.fig, 'MenuBar', 'figure')
            UI.preferences.displayMenu = 1;
            UI.menu.display.showHideMenu.Checked = 'On';
            fieldmenus = fieldnames(UI.menu);
            fieldmenus(strcmpi(fieldmenus,'NeuroScope2')) = [];
            for i = 1:numel(fieldmenus)
                UI.menu.(fieldmenus{i}).topMenu.Visible = 'off';
            end
            MsgLog('Regular MATLAB menubar shown. Press M to regain the NeuroScope2 menubar',2);
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
    
    function HelpDialog(~,~)
        if ismac; scs  = 'Cmd + '; else; scs  = 'Ctrl + '; end
        shortcutList = { 
            '','<html><b>Mouse actions</b></html>';
            'Left mouse button','Pan traces'; 
            'Right mouse button','Rubber band tool for zooming and measurements';
            'Middle button','Highlight ephys trace';
            'Middle button+shift','Highlight unit spike raster';
            'Double click','Reset zoom';
            'Scroll in','Zoom in';
            'Scroll out','Zoom out';
            
            '   ',''; 
            '','<html><b>Navigation</b></html>';
            '> (right arrow)','Forward in time'; 
            '< (left arrow)','Backward in time';
            'shift + > (right arrow)','Fast forward in time'; 
            'shift + < (left arrow)','Fast backward in time';
            'G','Go to timestamp';
            'Numpad0','Go to t = 0s'; 
            'Backspace','Go to previous time point'; 
            
            '   ',''; 
            '','<html><b>Display settings</b></html>';
            [char(94) ' (up arrow)'],'increase ephys amplitude'; 
            'v (down arrow)','Decrease ephys amplitude';
            'Q','Increase window duration'; 
            'A','Decrease window duration';
            'C','Highlight ephys channel(s)';
            'H','View mouse and keyboard shortcuts (this page)';
            
            '   ',''; 
            '','<html><b>Data streaming</b></html>';
            'shift + space','Stream data from current time'; 
            'ctrl + space','Stream data from end of file'; 
            
            '   ',''; 
            '','<html><b>Mat files</b></html>';
            'S','Toggle spikes';
            'E','Toggle events';
            'T','Toggle timeseries';
            '. (dot)','Go to next event';
            ', (comma)','Go to previous event';
            '/ (slash/period)','Go to random event';
            'F','Flag event';
            'L','Add/delete events';
            
            '   ',''; 
            '','<html><b>Other shortcuts</b></html>';
            [scs,'O'],'Open session from file'; 
            [scs,'C'],'Open the file directory of the selected cell'; 
            [scs,'D'],'Opens session from BuzLabDB';
            [scs,'V'],'Visit the CellExplorer website in your browser';
            '',''; '','<html><b>Visit the CellExplorer website for further help and documentation</html></b>'; };
        if ismac
            dimensions = [450,(size(shortcutList,1)+1)*17.5];
        else
            dimensions = [450,(size(shortcutList,1)+1)*18.5];
        end
        HelpWindow.dialog = figure('Position', [300, 300, dimensions(1), dimensions(2)],'Name','NeuroScope2: mouse and keyboard shortcuts', 'MenuBar', 'None','NumberTitle','off','visible','off'); movegui(HelpWindow.dialog,'center'), set(HelpWindow.dialog,'visible','on')
        HelpWindow.sessionList = uitable(HelpWindow.dialog,'Data',shortcutList,'Position',[1, 1, dimensions(1)-1, dimensions(2)-1],'ColumnWidth',{100 345},'columnname',{'Shortcut','Action'},'RowName',[],'ColumnEditable',[false false],'Units','normalized');
    end

    function streamData
        % Streams  data from t0, updating traces twice per window duration
        if ~UI.settings.stream
            UI.settings.stream = true;
            UI.settings.fileRead = 'bof';
            while UI.settings.stream
                t0 = t0+0.5*UI.settings.windowDuration;
                t0 = max([0,min([t0,UI.t_total-UI.settings.windowDuration])]);
                if ~ishandle(UI.fig)
                    return
                end
                plotData
                % Update UI text and slider
                UI.elements.lower.time.String = num2str(t0);
                UI.elements.lower.performance.String = ['  Streaming...'];
                UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Streaming','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color','w');
                for i = 1:10
                    if UI.settings.stream
                        pause(0.05*UI.settings.windowDuration)
                    end
                end
            end
            UI.elements.lower.performance.String = '';
        end
        UI.settings.fileRead = 'bof';
        if ishandle(UI.streamingText)
            delete(UI.streamingText)
        end
    end
    function streamData2
        % Stream from the end of the file, updating twice per window duration
        if ~UI.settings.stream
            UI.settings.stream = true;
            UI.settings.fileRead = 'eof';
            while UI.settings.stream
                t0 = UI.t_total-UI.settings.windowDuration;
                if ~ishandle(UI.fig)
                    return
                end
                plotData
                UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Streaming: end of file','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color','w');
                for i = 1:10
                    if UI.settings.stream
                        pause(0.05*UI.settings.windowDuration)
                    end
                end
            end
        end
        UI.settings.fileRead = 'bof';
        if ishandle(UI.streamingText)
            delete(UI.streamingText)
        end
    end
    function goToTimestamp(~,~)
        % Go to a specific timestamp via dialog
        UI.settings.stream = false;
        answer = inputdlg('Go go timepoint:','Sample', [1 50]);
        if ~isempty(answer)
            t0 = valid_t0(str2num(answer{1}));
            uiresume(UI.fig);
        end
    end

    function advance(~,~)
        % Advance the traces with 1/4 window size
        UI.settings.stream = false;
        t0 = t0+0.25*UI.settings.windowDuration;
        uiresume(UI.fig);
    end

    function back(~,~)
        % Go back 1/4 window size in time
        t0 = max([t0-0.25*UI.settings.windowDuration,0]);
        UI.settings.stream = false;
        uiresume(UI.fig);
    end

    function advance_fast(~,~)
        % Advance the traces with 1/4 window size
        UI.settings.stream = false;
        t0 = t0+UI.settings.windowDuration;
        uiresume(UI.fig);
    end

    function back_fast(~,~)
        % Go back 1/4 window size in time
        UI.settings.stream = false;
        t0 = max([t0-UI.settings.windowDuration,0]);
        uiresume(UI.fig);
    end

    function setTime(~,~)
        % Go to a specific timestamp
        UI.settings.stream = false;
        string1 = str2num(UI.elements.lower.time.String);
        if isnumeric(string1) & string1>=0
            t0 = valid_t0(string1);
            uiresume(UI.fig);
        end
    end

    function setWindowsSize(~,~)
        % Set the window size
        string1 = str2num(UI.elements.lower.windowsSize.String);
        if isnumeric(string1) & string1>0
            UI.settings.windowDuration = string1;
            initTraces
            UI.forceNewData = true;
            uiresume(UI.fig);
        end
    end

    function increaseWindowsSize(~,~)
        % Increase the window size
        windowSize_old = UI.settings.windowDuration;
        UI.settings.windowDuration = min([UI.settings.windowDuration*2,20]);
        xlim(UI.plot_axis1,[0,UI.settings.windowDuration])
        initTraces
        UI.forceNewData = true;
        uiresume(UI.fig);
    end

    function decreaseWindowsSize(~,~)
        % Decrease the window size
        windowSize_old = UI.settings.windowDuration;
        UI.settings.windowDuration = max([UI.settings.windowDuration/2,0.125]);
        xlim(UI.plot_axis1,[0,UI.settings.windowDuration])
        initTraces
        UI.forceNewData = true;
        uiresume(UI.fig);
    end

    function increaseAmplitude(~,~)
        % Decrease amplitude of the traces
        UI.settings.scalingFactor = UI.settings.scalingFactor*(sqrt(2));
        initTraces
        uiresume(UI.fig);
    end

    function decreaseAmplitude(~,~)
        % Increase amplitude of the ephys traces
        UI.settings.scalingFactor = UI.settings.scalingFactor/sqrt(2);
        initTraces
        uiresume(UI.fig);
    end

    function setScaling(~,~)
        % Decrease amplitude of the ephys traces
        string1 = str2num(UI.elements.lower.scaling.String);
        if isnumeric(string1) && string1>=0
            UI.settings.scalingFactor = string1;
            initTraces
            uiresume(UI.fig);
        end
    end

    function buttonsElectrodeGroups(src,~)
        % handles the three buttons under the electrode groups table
        switch src.String
            case 'None'
                UI.table.electrodeGroups.Data(:,1) = {false};
                editElectrodeGroups
            case 'All'
                UI.table.electrodeGroups.Data(:,1) = {true};
                editElectrodeGroups
            case 'Edit'
                data.session = gui_session(data.session,[],'extracellular');
                initData(basepath,basename);
                initTraces;
                uiresume(UI.fig);
        end
    end

    function getNotes(~,~)
        data.session.general.notes = UI.panel.notes.text.String;
    end
    
    function buttonsChannelTags(src,~)
        % handles the three buttons under the channel tags table
        switch src.String
            case 'Add'
                if isempty(UI.selectedChannels)
                    selectedChannels = '';
                else
                    selectedChannels = num2str(UI.selectedChannels);
                end
                answer = inputdlg({'Tag name (e.g. Bad, Ripple, Theta)','Channels','Groups'},'Add channel tag', [1 50; 1 50; 1 50],{'',selectedChannels,''});
                if ~isempty(answer) && ~strcmp(answer{1},'') && isvarname(answer{1}) && ~ismember(answer{1},fieldnames(data.session.channelTags))
                    if ~isempty(answer{2}) && isnumeric(str2num(answer{2})) && all(str2num(answer{2})>0)
                        data.session.channelTags.(answer{1}).channels = str2num(answer{2});
                    end
                    if ~isempty(answer{3}) && isnumeric(str2num(answer{3})) && all(str2num(answer{3})>0)
                        data.session.channelTags.(answer{1}).electrodeGroups = str2num(answer{3});
                    end
                    updateChannelTags
                    uiresume(UI.fig);
                end
            case 'Save'
                session = data.session;
                saveStruct(session);
                MsgLog('Channel tags saved with session metadata',2);
            case 'Delete'
                data.session = gui_session(data.session,[],'channelTags');
                initData(basepath,basename);
                initTraces;
                uiresume(UI.fig);
        end
    end

    function toggleSpikes(~,~)
        % Toggle spikes data
        if ~isfield(data,'spikes') && exist(fullfile(basepath,[basename,'.spikes.cellinfo.mat']),'file')
            data.spikes = loadSpikes('session',data.session);
            if ~isfield(data.spikes,'spindices')
                data.spikes.spindices = generateSpinDices(data.spikes.times);
            end
        elseif ~exist(fullfile(basepath,[basename,'.spikes.cellinfo.mat']),'file')
            UI.panel.spikes.showSpikes.Value = 0;
            MsgLog('Spikes does not exist',4);
            return
        end
        UI.settings.showSpikes = ~UI.settings.showSpikes;
        if UI.settings.showSpikes
            UI.panel.spikes.showSpikes.Value = 1;
            
            spikes_fields = fieldnames(data.spikes);
            subfieldstypes = struct2cell(structfun(@class,data.spikes,'UniformOutput',false));
            subfieldssizes = struct2cell(structfun(@size,data.spikes,'UniformOutput',false));
            subfieldssizes = cell2mat(subfieldssizes);
            idx = ismember(subfieldstypes,{'double','cell'}) & all(subfieldssizes == [1,data.spikes.numcells],2);
            spikes_fields = spikes_fields(idx);
            UI.settings.spikesYDataType = subfieldstypes(idx);
            excluded_fields = {'times','ts','ts_eeg','maxWaveform_all','channels_all','peakVoltage_sorted','timeWaveform'};
            [spikes_fields,ia] = setdiff(spikes_fields,excluded_fields);
            UI.settings.spikesYDataType = UI.settings.spikesYDataType(ia);

            idx_toKeep = [];
            for i = 1:numel(spikes_fields)
                if strcmp(UI.settings.spikesYDataType{i},'cell')
                    if all(all([cellfun(@(X) size(X,1), data.spikes.(spikes_fields{i}));cellfun(@(X) size(X,2), data.spikes.(spikes_fields{i}))] == [data.spikes.total;ones(1,data.spikes.numcells)])) || all(all([cellfun(@(X) size(X,1), data.spikes.(spikes_fields{i}));cellfun(@(X) size(X,2), data.spikes.(spikes_fields{i}))] == [ones(1,data.spikes.numcells);data.spikes.total]))
                        idx_toKeep = [idx_toKeep,i];
                    end
                end
            end
            UI.settings.spikesYDataType = UI.settings.spikesYDataType(idx_toKeep);
            UI.panel.spikes.setSpikesYData.String = ['None';spikes_fields(idx_toKeep)];
            UI.panel.spikes.setSpikesYData.Value = 1;
            
            if isempty(UI.panel.spikes.setSpikesYData.Value)
                UI.panel.spikes.setSpikesYData.Value = 1;
            end
            UI.params.subsetTable = 1:data.spikes.numcells;
            UI.params.subsetFilter = 1:data.spikes.numcells;
            UI.params.subsetGroups = 1:data.spikes.numcells;
            UI.params.subsetCellType = 1:data.spikes.numcells;
            UI.panel.spikes.setSpikesYData.Enable = 'on';
            UI.panel.spikes.setSpikesGroupColors.Enable = 'on';
        else
            UI.panel.spikes.showSpikes.Value = 0;
            UI.panel.spikes.setSpikesYData.Enable = 'off';
            UI.panel.spikes.setSpikesGroupColors.Enable = 'off';
            spikes_fields = {''};
        end
        initTraces
        uiresume(UI.fig);
    end

    function toggleMetrics(~,~)
        % Toggle cell metrics data
        if ~isfield(data,'cell_metrics') && exist(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']),'file')
            data.cell_metrics = loadCellMetrics('session',data.session);
        elseif ~exist(fullfile(basepath,[basename,'.cell_metrics.cellinfo.mat']),'file')
            UI.panel.cell_metrics.useMetrics.Value = 0;
            MsgLog('Cell_metrics does not exist',4);
            return
        end
        UI.settings.useMetrics = ~UI.settings.useMetrics;
        if UI.settings.useMetrics
            UI.panel.cell_metrics.useMetrics.Value = 1;
            spikes_fields = fieldnames(data.cell_metrics);
            subfieldstypes = struct2cell(structfun(@class,data.cell_metrics,'UniformOutput',false));
            subfieldssizes = struct2cell(structfun(@size,data.cell_metrics,'UniformOutput',false));
            subfieldssizes = cell2mat(subfieldssizes);
            
            % Sorting
            idx = ismember(subfieldstypes,{'double','cell'}) & all(subfieldssizes == [1,data.cell_metrics.general.cellCount],2);
            spikes_fields1 = spikes_fields(idx);
            UI.panel.cell_metrics.sortingMetric.String = spikes_fields1;
            UI.panel.cell_metrics.sortingMetric.Value = find(strcmp(spikes_fields1,UI.params.sortingMetric));
            if isempty(UI.panel.cell_metrics.sortingMetric.Value)
                UI.panel.cell_metrics.sortingMetric.Value = 1;
            end
            UI.panel.cell_metrics.sortingMetric.Enable = 'on';
            
            % Grouping
            idx = ismember(subfieldstypes,{'cell'}) & all(subfieldssizes == [1,data.cell_metrics.general.cellCount],2);
            spikes_fields2 = spikes_fields(idx);
            UI.panel.cell_metrics.groupMetric.String = spikes_fields2;
            UI.panel.cell_metrics.groupMetric.Value = find(strcmp(spikes_fields2,UI.params.groupMetric));
            if isempty(UI.panel.cell_metrics.groupMetric.Value)
                UI.panel.cell_metrics.groupMetric.Value = 1;
            end
            UI.panel.cell_metrics.groupMetric.Enable = 'on';
            UI.panel.cell_metrics.textFilter.Enable = 'on';
            UI.panel.cell_metrics.defineGroupData.Enable = 'on';
            UI.params.subsetTable = 1:data.cell_metrics.general.cellCount;
            initCellsTable
            
            % Cell type list
            UI.listbox.cellTypes.Enable = 'on';
            [UI.params.cellTypes,~,clusClas] = unique(data.cell_metrics.putativeCellType);
            UI.params.cell_class_count = histc(clusClas,1:length(UI.params.cellTypes));
            UI.params.cell_class_count = cellstr(num2str(UI.params.cell_class_count))';
            UI.listbox.cellTypes.String = strcat(UI.params.cellTypes,' (',UI.params.cell_class_count,')');
            UI.listbox.cellTypes.Value = 1:length(UI.params.cellTypes);
            UI.params.subsetCellType = 1:data.cell_metrics.general.cellCount;
            
            UI.panel.spikes.setSpikesGroupColors.String = {'UID','White','Cell metrics'};
            UI.panel.spikes.setSpikesGroupColors.Value = 3; 
            UI.settings.spikesGroupColors = 3;
        else
            UI.panel.cell_metrics.useMetrics.Value = 0;
            UI.panel.cell_metrics.sortingMetric.Enable = 'off';
            UI.panel.cell_metrics.groupMetric.Enable = 'off';
            UI.panel.cell_metrics.textFilter.Enable = 'off';
            UI.panel.cell_metrics.defineGroupData.Enable = 'off';
            UI.listbox.cellTypes.Enable = 'off';
            spikes_fields = {''};
            UI.table.cells.Data = {''};
            UI.table.cells.Enable = 'off';
            if UI.panel.spikes.setSpikesGroupColors.Value == 3
                UI.panel.spikes.setSpikesGroupColors.Value = 1;
                UI.settings.spikesGroupColors = 1;
            end
            UI.panel.spikes.setSpikesGroupColors.String = {'UID','White'};
        end
        uiresume(UI.fig);
    end

    function setSortingMetric(~,~)
        UI.params.sortingMetric = UI.panel.cell_metrics.sortingMetric.String{UI.panel.cell_metrics.sortingMetric.Value};
        uiresume(UI.fig);
    end

    function setCellTypeSelectSubset(~,~)
        UI.params.subsetCellType = find(ismember(data.cell_metrics.putativeCellType,UI.params.cellTypes(UI.listbox.cellTypes.Value)));
        uiresume(UI.fig);
    end

    function setGroupMetric(~,~)
        UI.params.groupMetric = UI.panel.cell_metrics.groupMetric.String{UI.panel.cell_metrics.groupMetric.Value};
        uiresume(UI.fig);
    end

    function initCellsTable(~,~)
        dataTable = {};
        column1 = data.cell_metrics.(UI.tableData.Column1)';
        column2 = data.cell_metrics.(UI.tableData.Column2)';
        if isnumeric(column1)
            column1 = cellstr(num2str(column1,3));
        end
        if isnumeric(column2)
            column2 = cellstr(num2str(column2,3));
        end
        dataTable(:,2:4) = [cellstr(num2str(UI.params.subsetTable')),column1,column2];
        dataTable(:,1) = {false};
        dataTable(UI.params.subsetTable,1) = {true};
        UI.table.cells.Data = dataTable;
        UI.table.cells.Enable = 'on';
    end

    function editCellTable(~,~)
        UI.params.subsetTable = find([UI.table.cells.Data{:,1}]);
    end

    function metricsButtons(src,~)
        switch src.String
            case 'None'
                UI.table.cells.Data(:,1) = {false};
                UI.params.subsetTable = find([UI.table.cells.Data{:,1}]);
                uiresume(UI.fig);
            case 'All'
                UI.table.cells.Data(:,1) = {true};
                UI.params.subsetTable = find([UI.table.cells.Data{:,1}]);
                uiresume(UI.fig);
            case 'Metrics'
                if isfield(data,'cell_metrics')
                    generate_cell_metrics_table(data.cell_metrics);
                end
        end
    end

    function filterCellsByText(~,~)
        if isnumeric(str2num(UI.panel.cell_metrics.textFilter.String)) && ~isempty(UI.panel.cell_metrics.textFilter.String) && ~isempty(str2num(UI.panel.cell_metrics.textFilter.String))
                UI.params.subsetFilter = str2num(UI.panel.cell_metrics.textFilter.String);
        elseif ~isempty(UI.panel.cell_metrics.textFilter.String) && ~strcmp(UI.panel.cell_metrics.textFilter.String,'Filter')
            if isempty(UI.freeText)
                UI.freeText = {''};
                fieldsMenuCells = fieldnames(data.cell_metrics);
                fieldsMenuCells = fieldsMenuCells(strcmp(struct2cell(structfun(@class, data.cell_metrics, 'UniformOutput', false)), 'cell'));
                for j = 1:length(fieldsMenuCells)
                    UI.freeText = strcat(UI.freeText, {' '}, data.cell_metrics.(fieldsMenuCells{j}));
                end
                UI.params.alteredCellMetrics = 0;
            end
            str2num(UI.panel.cell_metrics.textFilter.String)
            
            [newStr2,matches] = split(UI.panel.cell_metrics.textFilter.String,[" & "," | "," OR "," AND "]);
            idx_textFilter2 = zeros(length(newStr2),data.cell_metrics.general.cellCount);
            failCheck = 0;
            for i = 1:length(newStr2)
                if numel(newStr2{i})>11 && strcmp(newStr2{i}(1:12),'.brainRegion')
                    newStr = split(newStr2{i}(2:end),' ');
                    if numel(newStr)>1
                        if isempty(UI.brainRegions.relational_tree)
                            load('brainRegions_relational_tree.mat','relational_tree');
                        end
                        acronym_out = getBrainRegionChildren(newStr{2},UI.brainRegions.relational_tree);
                        idx_textFilter2(i,:) = ismember(lower(data.cell_metrics.brainRegion),lower([acronym_out,newStr{2}]));
                    end
                elseif strcmp(newStr2{i}(1),'.')
                    newStr = split(newStr2{i}(2:end),' ');
                    if length(newStr)==3 && isfield(data.cell_metrics,newStr{1}) && isnumeric(data.cell_metrics.(newStr{1})) && contains(newStr{2},{'==','>','<','~='})
                        switch newStr{2}
                            case '>'
                                idx_textFilter2(i,:) = data.cell_metrics.(newStr{1}) > str2double(newStr{3});
                            case '<'
                                idx_textFilter2(i,:) = data.cell_metrics.(newStr{1}) < str2double(newStr{3});
                            case '=='
                                idx_textFilter2(i,:) = data.cell_metrics.(newStr{1}) == str2double(newStr{3});
                            case '~='
                                idx_textFilter2(i,:) = data.cell_metrics.(newStr{1}) ~= str2double(newStr{3});
                            otherwise
                                failCheck = 1;
                        end
                    elseif length(newStr)==3 && ~isfield(data.cell_metrics,newStr{1}) && contains(newStr{2},{'==','>','<','~='})
                        failCheck = 2;
                    else
                        failCheck = 1;
                    end
                else
                    idx_textFilter2(i,:) = contains(UI.freeText,newStr2{i},'IgnoreCase',true);
                end
            end
            if failCheck == 0
                orPairs = find(contains(matches,{' | ',' OR '}));
                if ~isempty(orPairs)
                    for i = 1:length(orPairs)
                        idx_textFilter2([orPairs(i),orPairs(i)+1],:) = any(idx_textFilter2([orPairs(i),orPairs(i)+1],:)).*[1;1];
                    end
                end
                UI.params.subsetFilter = find(all(idx_textFilter2,1));
                MsgLog([num2str(length(UI.params.subsetFilter)),'/',num2str(data.cell_metrics.general.cellCount),' cells selected with ',num2str(length(newStr2)),' filter: ' ,UI.panel.cell_metrics.textFilter.String]);
            elseif failCheck == 2
                MsgLog('Filter not formatted correctly. Field does not exist',2);
            else
                MsgLog('Filter not formatted correctly',2);
                UI.params.subsetFilter = 1:data.cell_metrics.general.cellCount;
            end
        else
            UI.params.subsetFilter = 1:data.cell_metrics.general.cellCount;
            MsgLog('Filter reset');
        end
        if isempty(UI.params.subsetFilter)
            UI.params.subsetFilter = 1:data.cell_metrics.general.cellCount;
        end
        uiresume(UI.fig);
    end

    function showSpikesBelowTrace(~,~)
        if UI.panel.spikes.showSpikesBelowTrace.Value == 1
            UI.settings.spikesBelowTrace = true;
        else
            UI.settings.spikesBelowTrace = false;
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function setSpikesGroupColors(~,~)
        UI.settings.spikesGroupColors = UI.panel.spikes.setSpikesGroupColors.Value;
        uiresume(UI.fig);
    end
    function setSpikesYData(~,~)
        UI.settings.spikesYData = UI.panel.spikes.setSpikesYData.String{UI.panel.spikes.setSpikesYData.Value};
        if UI.panel.spikes.setSpikesYData.Value > 1
            UI.settings.useSpikesYData = true;
            if numel(data.spikes.times)>0
                switch UI.settings.spikesYDataType{UI.panel.spikes.setSpikesYData.Value-1}
                    case 'double'
                        groups = [];
                            for i = 1:numel(data.spikes.(UI.settings.spikesYData))
                                groups = [groups,ones(1,data.spikes.total(i))*data.spikes.(UI.settings.spikesYData)(i)]; % from cell to array
                            end
                        [~,sortidx] = sort(cat(1,data.spikes.times{:})); % Sorting spikes
                        data.spikes.spindices(:,3) = groups(sortidx); % Combining spikes and sorted group ids
                    case 'cell'
                        if size(data.spikes.(UI.settings.spikesYData){1},2)==1
                            groups = [];
                            for i = 1:numel(data.spikes.(UI.settings.spikesYData))
                                groups = [groups,data.spikes.(UI.settings.spikesYData){i}']; % from cell to array
                            end
                        elseif size(data.spikes.(UI.settings.spikesYData){1},1)==1
                            groups = [];
                            for i = 1:numel(data.spikes.(UI.settings.spikesYData))
                                groups = [groups,data.spikes.(UI.settings.spikesYData){i}]; % from cell to array
                            end
                        end
                        [~,sortidx] = sort(cat(1,data.spikes.times{:})); % Sorting spikes
                        data.spikes.spindices(:,3) = groups(sortidx); % Combining spikes and sorted group ids
                        if contains(UI.settings.spikesYData,'phase')
                            idx = (data.spikes.spindices(:,3) < 0);
                            data.spikes.spindices(idx,3) = data.spikes.spindices(idx,3)+2*pi;
                        end
                end
            end
            
            % Getting limits
            UI.settings.spikes_ylim = [min(data.spikes.spindices(:,3)),max(data.spikes.spindices(:,3))];
        else
            UI.settings.useSpikesYData = false;
        end
        initTraces
        uiresume(UI.fig);
    end

    function initTraces
        set(UI.fig,'Renderer','opengl');
        % Determining data offsets
        UI.offsets.intan    = 0.10 * (UI.settings.showIntanBelowTrace & (UI.settings.intan_showAnalog | UI.settings.intan_showAux | UI.settings.intan_showDigital));
        UI.offsets.trials   = 0.02 * (UI.settings.showTrials);
        UI.offsets.behavior = 0.08 * (UI.settings.showBehaviorBelowTrace && UI.settings.plotBehaviorLinearized && UI.settings.showBehavior);
        UI.offsets.states   = 0.04 * (UI.settings.showStates);
        UI.offsets.events   = 0.04 * (UI.settings.showEventsBelowTrace && UI.settings.showEvents);
        UI.offsets.spikes   = 0.08 * (UI.settings.spikesBelowTrace && UI.settings.showSpikes);
        
        offset = 0;
        padding = 0.005;
        list = fieldnames(UI.offsets);
        for i = 1:numel(list)
            if UI.offsets.(list{i}) == 0
                UI.dataRange.(list{i}) = [0,1];
            else
                UI.dataRange.(list{i}) = [0,UI.offsets.(list{i})] + offset;
                offset = offset + UI.offsets.(list{i}) + padding;
            end
        end

        % Initialize the trace data with current metadata and configuration
        UI.channels = data.session.extracellular.electrodeGroups.channels;
        if isfield(data.session,'channelTags')
            UI.channelTags = fieldnames(data.session.channelTags);
        end
        if ~isempty(UI.settings.channelTags.hide)
            for j = 1:numel(UI.channels)
                for i = 1:numel(UI.settings.channelTags.hide)
                    if isfield(data.session.channelTags.(UI.channelTags{UI.settings.channelTags.hide(i)}),'channels') && ~isempty(data.session.channelTags.(UI.channelTags{UI.settings.channelTags.hide(i)}).channels)
                        UI.channels{j}(ismember(UI.channels{j},data.session.channelTags.(UI.channelTags{UI.settings.channelTags.hide(i)}).channels)) = [];
                    end
                end
            end
        end
        if ~isempty(UI.settings.channelTags.filter)
            for j = 1:numel(UI.channels)
                for i = 1:numel(UI.settings.channelTags.filter)
                    if isfield(data.session.channelTags.(UI.channelTags{UI.settings.channelTags.filter(i)}),'channels') && ~isempty(data.session.channelTags.(UI.channelTags{UI.settings.channelTags.filter(i)}).channels)
                        [~,idx] = setdiff(UI.channels{j},data.session.channelTags.(UI.channelTags{UI.settings.channelTags.filter(i)}).channels);
                        UI.channels{j}(idx) = [];
                    end
                end
            end
        end
        channels = [UI.channels{UI.settings.electrodeGroupsToPlot}];
        UI.channelOrder = [UI.channels{UI.settings.electrodeGroupsToPlot}];
        nChannelsToPlot = numel(UI.channelOrder);
        UI.channelMap = zeros(1,data.session.extracellular.nChannels);
        [idx, idx2]= ismember([data.session.extracellular.electrodeGroups.channels{:}],channels);
        [~,temp] = sort([data.session.extracellular.electrodeGroups.channels{:}]);
        channels_1 = [data.session.extracellular.electrodeGroups.channels{:}];
        UI.channelMap(channels_1(find(idx))) = channels(idx2(idx2~=0));
        if nChannelsToPlot == 1
            multiplier = 0.5*ones(1,UI.channelOrder);
        else
            multiplier = [0:nChannelsToPlot-1]/(nChannelsToPlot-1)*(0.9-0.9*offset)+0.05*(1-offset);
        end
        if UI.settings.plotStyle == 4
            UI.channelScaling = ones(UI.settings.windowDuration*data.session.extracellular.srLfp,1)*multiplier;
            UI.samplesToDisplay = UI.settings.windowDuration*data.session.extracellular.srLfp;
        else
            UI.channelScaling = ones(UI.settings.windowDuration*data.session.extracellular.sr,1)*multiplier;
            UI.samplesToDisplay = UI.settings.windowDuration*data.session.extracellular.sr;
        end

        if nChannelsToPlot == 1
            UI.channelScaling(:,1:UI.channelOrder) = UI.channelScaling-1;
        else
            UI.channelScaling(:,UI.channelOrder) = UI.channelScaling-1;
        end
        UI.dispSamples = floor(linspace(1,UI.samplesToDisplay,UI.Pix_SS));
        UI.nDispSamples = numel(UI.dispSamples);
        UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
        UI.elements.lower.scaling.String = num2str(UI.settings.scalingFactor);
        xlim(UI.plot_axis1,[0,UI.settings.windowDuration]);
        UI.plot_axis1.XAxis.TickValues = [0:0.5:UI.settings.windowDuration];
        UI.plot_axis1.XAxis.MinorTickValues = [0:0.01:UI.settings.windowDuration];
        UI.fig.UserData.scalingFactor = UI.settings.scalingFactor;
        if UI.settings.plotStyle == 3
            UI.fig.UserData.rangeData = true;
        else
            UI.fig.UserData.rangeData = false;
        end
    end

    function initInputs
        % Handling channeltags
        if exist('parameters','var') && ~isempty(parameters.channeltag)
            idx = find(strcmp(parameters.channeltag,{UI.table.channeltags.Data{:,2}}));
            if ~isempty(idx)
                UI.table.channeltags.Data(idx,3) = {true};
                UI.settings.channelTags.highlight = find([UI.table.channeltags.Data{:,3}]);
                initTraces
            end
        end
        if exist('parameters','var') &&~isempty(parameters.events)
            idx = find(strcmp(parameters.events,UI.panel.events.files.String));
            if ~isempty(idx)
                UI.panel.events.files.Value = idx;
                UI.settings.eventData = UI.panel.events.files.String{UI.panel.events.files.Value};
                UI.settings.showEvents = false;
                showEvents
            end
        end
    end
    
    function initData(basepath,basename)
        % Initialize the data
        UI.data.basepath = basepath;
        UI.data.basename = basename;
        cd(UI.data.basepath)
        UI.file.dat = dir([UI.data.basename,'.dat']);
        if ~isfield(data,'session') & exist(fullfile(basepath,[basename,'.session.mat']))
            data.session = loadSession(UI.data.basepath,UI.data.basename);
        elseif ~isfield(data,'session')
            data.session = sessionTemplate(UI.data.basepath,'showGUI',false,'basename',basename);
        end
        % UI.settings.colormap
        UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);
        
        UI.settings.leastSignificantBit = data.session.extracellular.leastSignificantBit;
        UI.fig.UserData.leastSignificantBit = UI.settings.leastSignificantBit;
        
        % Getting notes
        if isfield(data.session.general,'notes')
            UI.panel.notes.text.String = data.session.general.notes;
        end
        
        updateChannelGroupsList
        updateChannelTags
        UI.fig.Name = ['NeuroScope2   -   session: ', UI.data.basename, ', basepath: ', UI.data.basepath];
        UI.fid.ephys = fopen(fullfile(basepath,[UI.data.basename '.dat']), 'r');
        UI.fid.lfp = fopen(fullfile(basepath,[UI.data.basename '.lfp']), 'r');
        s1 = dir(fullfile(basepath,[UI.data.basename '.dat']));
        s2 = dir(fullfile(basepath,[UI.data.basename '.lfp']));
        if ~isempty(s1)
            filesize = s1.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.sr*2);
        elseif ~isempty(s2)
            filesize = s2.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.srLfp*2);
            UI.settings.plotStyle = 4;
            UI.panel.general.plotStyle.Value = UI.settings.plotStyle;
        else
            warning('NeuroScope2: Binary data does not exist')
            outcome = true;
        end
        UI.forceNewData = true;
        
        % Detecting CellExplorer/Buzcode files
        UI.data.detectecFiles = detectCellExplorerFiles(UI.data.basepath,UI.data.basename);
        if isfield(UI.data.detectecFiles,'events') && ~isempty(UI.data.detectecFiles.events)
            UI.panel.events.files.String = UI.data.detectecFiles.events;
            UI.settings.eventData = UI.data.detectecFiles.events{1};
        else
            UI.panel.events.files.String = {''};
        end
        if isfield(UI.data.detectecFiles,'timeseries') && ~isempty(UI.data.detectecFiles.timeseries)
            UI.panel.timeseries.files.String = UI.data.detectecFiles.timeseries;
            UI.settings.timeseriesData = UI.data.detectecFiles.timeseries{1};
        else
            UI.panel.timeseries.files.String = {''};
        end
        if isfield(UI.data.detectecFiles,'states') && ~isempty(UI.data.detectecFiles.states)
            UI.panel.states.files.String = UI.data.detectecFiles.states;
            UI.settings.statesData = UI.data.detectecFiles.states{1};
        else
            UI.panel.states.files.String = {''};
        end
        if isfield(UI.data.detectecFiles,'behavior') && ~isempty(UI.data.detectecFiles.behavior)
            UI.panel.behavior.files.String = UI.data.detectecFiles.behavior;
            UI.settings.behaviorData = UI.data.detectecFiles.behavior{1};
        else
            UI.panel.behavior.files.String = {''};
        end
        
        % Intan files
        if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'adc')
            UI.panel.intan.filenameAnalog.String = data.session.timeSeries.adc.fileName;
            % Defining adc channel labels
            UI.settings.traceLabels.adc = strcat(repmat({'adc'},data.session.timeSeries.adc.nChannels,1),num2str([1:data.session.timeSeries.adc.nChannels]'));
            if isfield(data.session,'inputs')
                inputs = fieldnames(data.session.inputs);
                for i = 1:numel(inputs)
                    if strcmp(data.session.inputs.(inputs{i}).inputType,'adc')
                        UI.settings.traceLabels.adc(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.adc{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
                    end
                end
            end
        else
            UI.panel.intan.filenameAnalog.String = '';
        end
        if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'aux')
            UI.panel.intan.filenameAux.String = data.session.timeSeries.aux.fileName;
            % Defining aux channel labels
            UI.settings.traceLabels.aux = strcat(repmat({'aux'},data.session.timeSeries.aux.nChannels,1),num2str([1:data.session.timeSeries.aux.nChannels]'));
            if isfield(data.session,'inputs')
                inputs = fieldnames(data.session.inputs);
                for i = 1:numel(inputs)
                    if strcmp(data.session.inputs.(inputs{i}).inputType,'aux')
                        UI.settings.traceLabels.aux(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.aux{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
                    end
                end
            end
        else
            UI.panel.intan.filenameAux.String = '';
        end
        if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'dig')
            UI.panel.intan.filenameDigital.String = data.session.timeSeries.dig.fileName;
            % Defining dig channel labels
            UI.settings.traceLabels.dig = strcat(repmat({'dig'},data.session.timeSeries.dig.nChannels,1),num2str([1:data.session.timeSeries.dig.nChannels]'));
            if isfield(data.session,'inputs')
                inputs = fieldnames(data.session.inputs);
                for i = 1:numel(inputs)
                    if strcmp(data.session.inputs.(inputs{i}).inputType,'dig')
                        UI.settings.traceLabels.dig(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.dig{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
                    end
                end
            end
        else
            UI.panel.intan.filenameDigital.String = '';
        end
    end

    function moveSlider(src,~)
        UI.settings.stream = false;
        s1 = dir(fullfile(basepath,[UI.data.basename '.dat']));
        s2 = dir(fullfile(basepath,[UI.data.basename '.lfp']));
        if ~isempty(s1)
            filesize = s1.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.sr*2);
        elseif ~isempty(s2)
            filesize = s2.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.srLfp*2);
        end
        t0 = valid_t0((UI.t_total-UI.settings.windowDuration)*src.Value/100);
        uiresume(UI.fig);
    end

    function ClickPlot(~,~)
        UI.settings.stream = false;
        % handles clicks on the main axes
        switch get(UI.fig, 'selectiontype')
            case 'normal' % left mouse button
                
                % Adding new event
                if UI.settings.addEventonClick
                    um_axes = get(UI.plot_axis1,'CurrentPoint');
                    t_event = um_axes(1,1)+t0;
                    data.events.(UI.settings.eventData).added = unique([data.events.(UI.settings.eventData).added;t_event]);
                    UI.elements.lower.performance.String = ['Event added: ',num2str(t_event),' sec'];
                    UI.settings.addEventonClick = false;
                    uiresume(UI.fig);
                end
                
            case 'alt' % right mouse button
                
                % Removing/flagging events
                if UI.settings.addEventonClick && ~isempty(data.events.(UI.settings.eventData).added)
                    idx3 = find(data.events.(UI.settings.eventData).added >= t0 & data.events.(UI.settings.eventData).added <= t0+UI.settings.windowDuration);
                    if any(idx3)
                        um_axes = get(UI.plot_axis1,'CurrentPoint');
                        t_event = um_axes(1,1)+t0;
                        eventsInWindow = data.events.(UI.settings.eventData).added(idx3);
                        [~,idx] = min(abs(eventsInWindow-t_event));
                        t_event = data.events.(UI.settings.eventData).added(idx3(idx));
                        data.events.(UI.settings.eventData).added(idx3(idx)) = [];
                        UI.elements.lower.performance.String = ['Event deleted: ',num2str(t_event),' sec'];
                        UI.settings.addEventonClick = false;
                        uiresume(UI.fig);
                    end
                end
                
            case 'extend' % middle mouse button
                um_axes = get(UI.plot_axis1,'CurrentPoint');
                if UI.settings.normalClick
                    channels = sort([UI.channels{UI.settings.electrodeGroupsToPlot}]);
                    x1 = (ones(size(ephys.traces(:,channels),2),1)*[1:size(ephys.traces(:,channels),1)]/size(ephys.traces(:,channels),1)*UI.settings.windowDuration)';
                    y1 = (ephys.traces(:,channels)-UI.channelScaling(:,channels));
                    [~,In] = min(hypot((x1(:)-um_axes(1,1)),(y1(:)-um_axes(1,2))));
                    In = unique(floor(In/size(x1,1)))+1;
                    In = channels(In);
                    highlightTraces(In,[])
                    UI.selectedChannels = unique([In,UI.selectedChannels],'stable');
                    UI.elements.lower.performance.String = ['Channel(s): ',num2str(UI.selectedChannels)];
                elseif UI.settings.showSpikes && ~UI.settings.normalClick
                    [~,In] = min(hypot((spikes_raster.x(:)-um_axes(1,1)),(spikes_raster.y(:)-um_axes(1,2))));
                    UID = spikes_raster.UID(In);
                    if ~isempty(UID)
                        highlightUnits(UID,t0,t0+UI.settings.windowDuration);
                        UI.selectedUnits = unique([UID,UI.selectedUnits],'stable');
                        UI.elements.lower.performance.String = ['Unit(s) selected: ',num2str(UI.selectedUnits)];
                    end
                end
            case 'open'
                set(UI.plot_axis1,'XLim',[0,UI.settings.windowDuration],'YLim',[0,1]);
            otherwise
                um_axes = get(UI.plot_axis1,'CurrentPoint');
                UI.elements.lower.performance.String = ['Cursor: ',num2str(um_axes(1,1)+t0),' sec'];
        end
    end

    function t0 = valid_t0(t0)
        t0 = min([max([0,floor(t0*data.session.extracellular.sr)/data.session.extracellular.sr]),UI.t_total-UI.settings.windowDuration]);
    end

    function editElectrodeGroups(~,~)
        UI.settings.electrodeGroupsToPlot = find([UI.table.electrodeGroups.Data{:,1}]);
        initTraces
        uiresume(UI.fig);
    end

    function editChannelTags(~,evnt)
        if evnt.Indices(1,2) == 6 & isnumeric(str2num(evnt.NewData))
            data.session.channelTags.(UI.table.channeltags.Data{evnt.Indices(1,1),2}).channels = str2num(evnt.NewData);
            initTraces
            uiresume(UI.fig);
        else
            UI.settings.channelTags.highlight = find([UI.table.channeltags.Data{:,3}]);
            UI.settings.channelTags.filter = find([UI.table.channeltags.Data{:,4}]);
            UI.settings.channelTags.hide = find([UI.table.channeltags.Data{:,5}]);
            initTraces
            uiresume(UI.fig);
        end
    end

    function ClicktoSelectFromTable(~,evnt)
        if ~isempty(evnt.Indices) && size(evnt.Indices,1) == 1 && evnt.Indices(2) == 2
            colorpick = UI.colors(evnt.Indices(1),:);
            try
                colorpick = uisetcolor(colorpick,'Electrode group color');
                UI.colors(evnt.Indices(1),:) = colorpick;
            catch
                MsgLog('Failed to load color palet',3);
            end
            classColorsHex = rgb2hex(UI.colors);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            colored_string = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            UI.table.electrodeGroups.Data{evnt.Indices(1),2} = colored_string{evnt.Indices(1)};
            initTraces
            uiresume(UI.fig);
        end
    end

    function ClicktoSelectFromTable2(~,evnt)
        if ~isempty(evnt.Indices) && size(evnt.Indices,1) == 1 && evnt.Indices(2) == 1
            colorpick = UI.colors_tags(evnt.Indices(1),:);
            try
                colorpick = uisetcolor(colorpick,'Channel tag color');
            catch
                MsgLog('Failed to load color palet',3);
            end
            UI.colors_tags(evnt.Indices(1),:) = colorpick;
            classColorsHex = rgb2hex(UI.colors_tags);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            colored_string = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            UI.table.channeltags.Data{evnt.Indices(1),1} = colored_string{evnt.Indices(1)};
            uiresume(UI.fig);
        end
    end

    function changePlotStyle(~,~)
        UI.settings.plotStyle = UI.panel.general.plotStyle.Value;
        initTraces
        UI.forceNewData = true;
        uiresume(UI.fig);
    end

    function changeColorScale(~,~)
        UI.settings.greyScaleTraces = UI.panel.general.greyScaleTraces.Value;
        uiresume(UI.fig);
    end

    function plotEnergy(~,~)
        UI.settings.plotEnergy = UI.panel.general.plotEnergy.Value;
        answer = UI.panel.general.energyWindow.String;
        if  ~isempty(answer) & isnumeric(str2num(answer))
            UI.settings.energyWindow = str2num(answer);
        end
        uiresume(UI.fig);
    end

    function changeTraceFilter(src,~)
        if strcmp(src.Style,'edit')
            UI.panel.general.filterToggle.Value = 1;
        end
        if UI.panel.general.filterToggle.Value == 0
            UI.settings.filterTraces = false;
        else
            UI.settings.filterTraces = true;
            UI.settings.filter.lowerBand = str2num(UI.panel.general.lowerBand.String);
            UI.settings.filter.higherBand = str2num(UI.panel.general.higherBand.String);
            if int_gt_0(UI.settings.filter.lowerBand) && int_gt_0(UI.settings.filter.higherBand)
                UI.settings.filterTraces = false;
            elseif int_gt_0(UI.settings.filter.lowerBand) && ~int_gt_0(UI.settings.filter.higherBand)
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, UI.settings.filter.higherBand/(data.session.extracellular.sr/2), 'low');
            elseif int_gt_0(UI.settings.filter.higherBand) && ~int_gt_0(UI.settings.filter.lowerBand)
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, UI.settings.filter.lowerBand/(data.session.extracellular.sr/2), 'high');
            else
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, [UI.settings.filter.lowerBand,UI.settings.filter.higherBand]/(data.session.extracellular.sr/2), 'bandpass');
            end
        end
        uiresume(UI.fig);
    end

    function updateChannelGroupsList
        % Updates the list of electrode groups
        tableData = {};
        if isfield(data.session.extracellular,'electrodeGroups')
            if isfield(data.session.extracellular,'electrodeGroups') && isfield(data.session.extracellular.electrodeGroups,'channels') && isnumeric(data.session.extracellular.electrodeGroups.channels)
                data.session.extracellular.electrodeGroups.channels = num2cell(data.session.extracellular.electrodeGroups.channels,2)';
            end
            
            if ~isempty(data.session.extracellular.electrodeGroups.channels) && ~isempty(data.session.extracellular.electrodeGroups.channels{1})
                nTotal = numel(data.session.extracellular.electrodeGroups.channels);
            else
                nTotal = 0;
            end
            classColorsHex = rgb2hex(UI.colors);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            colored_string = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            
            for fn = 1:nTotal
                tableData{fn,1} = true;
                tableData{fn,2} = colored_string{fn};
                tableData{fn,3} = [num2str(fn),' (',num2str(length(data.session.extracellular.electrodeGroups.channels{fn})),')'];
                tableData{fn,4} = ['<HTML>' num2str(data.session.extracellular.electrodeGroups.channels{fn})];
            end
            UI.table.electrodeGroups.Data = tableData;
        else
            UI.table.electrodeGroups.Data = {false,'','',''};
        end
        UI.settings.electrodeGroupsToPlot = 1:data.session.extracellular.nElectrodeGroups;
    end

    function updateChannelTags
        % Updates the list of channelTags
        tableData = {};
        if isfield(data.session,'channelTags')
            UI.colors_tags = jet(numel(fieldnames(data.session.channelTags)))*0.8;
            classColorsHex = rgb2hex(UI.colors_tags);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            colored_string = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            UI.channelTags = fieldnames(data.session.channelTags);
            nTags = numel(UI.channelTags);
            for i = 1:nTags
                tableData{i,1} = colored_string{i};
                tableData{i,2} = UI.channelTags{i};
                tableData{i,3} = false;
                tableData{i,4} = false;
                tableData{i,5} = false;
                if isfield(data.session.channelTags.(UI.channelTags{i}),'channels')
                    tableData{i,6} = num2str(data.session.channelTags.(UI.channelTags{i}).channels);
                else
                    tableData{i,6} = '';
                end
                if isfield(data.session.channelTags.(UI.channelTags{i}),'groups')
                    tableData{i,7} = num2str(data.session.channelTags.(UI.channelTags{i}).groups);
                else
                    tableData{i,7} = '';
                end
                
            end
            UI.table.channeltags.Data = tableData;
        else
            UI.table.channeltags.Data =  {'','',false,false,false,'',''};
        end
    end

% % Spikes functions
    function toogleDetectSpikes(~,~)
        if UI.panel.general.detectSpikes.Value == 1
            UI.settings.detectSpikes = true;
            if isnumeric(str2num(UI.panel.general.detectThreshold.String))
                UI.settings.spikesDetectionThreshold = str2num(UI.panel.general.detectThreshold.String);
            end
        else
            UI.settings.detectSpikes = false;
        end
        uiresume(UI.fig);
    end

    function toogleDetectEvents(~,~)
        if UI.panel.general.detectEvents.Value == 1
            UI.settings.detectEvents = true;
            if isnumeric(str2num(UI.panel.general.eventThreshold.String))
                UI.settings.eventThreshold = str2num(UI.panel.general.eventThreshold.String);
            end
        else
            UI.settings.detectEvents = false;
        end
        uiresume(UI.fig);
    end

% % Event functions
    function setEventData(~,~)
        UI.settings.eventData = UI.panel.events.files.String{UI.panel.events.files.Value};
        UI.settings.showEvents = false;
        showEvents
    end

    function showEvents(~,~)
        % Loading event data
        if UI.settings.showEvents
            UI.settings.showEvents = false;
            UI.panel.events.eventNumber.String = '';
            UI.panel.events.showEvents.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.eventData,'.events.mat']),'file')
            if ~isfield(data,'events') || ~isfield(data.events,UI.settings.eventData)
                data.events.(UI.settings.eventData) = loadStruct(UI.settings.eventData,'events','session',data.session);
                if ~isfield(data.events.(UI.settings.eventData),'time')
                    if isfield(data.events.(UI.settings.eventData),'peaks')
                        data.events.(UI.settings.eventData).time = data.events.(UI.settings.eventData).peaks;
                    elseif isfield(data.events.(UI.settings.eventData),'timestamps')
                        data.events.(UI.settings.eventData).time = data.events.(UI.settings.eventData).timestamps(:,1);
                    end
                end
            end
            UI.settings.showEvents = true;
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            UI.panel.events.showEvents.Value = 1;
            UI.panel.events.eventCount.String = ['nEvents: ' num2str(numel(data.events.(UI.settings.eventData).time))];
            if ~isfield(data.events.(UI.settings.eventData),'flagged')
                data.events.(UI.settings.eventData).flagged = [];
            end
            UI.panel.events.flagCount.String = ['nFlags: ', num2str(numel(data.events.(UI.settings.eventData).flagged))];
        else
            UI.settings.showEvents = false;
            UI.panel.events.eventNumber.String = '';
            UI.panel.events.showEvents.Value = 0;
        end
        initTraces
        uiresume(UI.fig);
    end

    function processing_steps(~,~)
        % Determines if processing steps should be plotted
        if UI.panel.events.processing_steps.Value == 1
            UI.settings.processing_steps = true;
        else
            UI.settings.processing_steps = false;
        end
        uiresume(UI.fig);
    end

    function showEventsBelowTrace(~,~)
        if UI.settings.showEventsBelowTrace
            UI.settings.showEventsBelowTrace = false;
            UI.panel.events.showEventsBelowTrace.Value = 0;
        else
            UI.settings.showEventsBelowTrace = true;
            UI.panel.events.showEventsBelowTrace.Value = 1;
        end
        initTraces
        uiresume(UI.fig);
    end

    function showBehaviorBelowTrace(~,~)
        if UI.settings.showBehaviorBelowTrace
            UI.settings.showBehaviorBelowTrace = false;
            UI.panel.behavior.showBehaviorBelowTrace.Value = 0;
        else
            UI.settings.showBehaviorBelowTrace = true;
            UI.panel.behavior.showBehaviorBelowTrace.Value = 1;
        end
        initTraces
        uiresume(UI.fig);
    end

    function plotBehaviorLinearized(~,~)
        if UI.settings.plotBehaviorLinearized
            UI.settings.plotBehaviorLinearized = false;
            UI.panel.behavior.plotBehaviorLinearized.Value = 0;
        else
            UI.settings.plotBehaviorLinearized = true;
            UI.panel.behavior.plotBehaviorLinearized.Value = 1;
        end
        initTraces
        uiresume(UI.fig);
    end

    function showEventsIntervals(~,~)
        if UI.panel.events.showEventsIntervals.Value == 1
            UI.settings.showEventsIntervals = true;
        else
            UI.settings.showEventsIntervals = false;
        end
        initTraces
        uiresume(UI.fig);
    end
    function nextEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if isfield(data.events.(UI.settings.eventData),'flagged') && ~isempty(data.events.(UI.settings.eventData).flagged)
            idx = setdiff(1:numel(data.events.(UI.settings.eventData).time),data.events.(UI.settings.eventData).flagged);
        else
            idx = 1:numel(data.events.(UI.settings.eventData).time);
        end
        UI.iEvent1 = find(data.events.(UI.settings.eventData).time(idx)>t0+UI.settings.windowDuration/2,1);
        UI.iEvent = idx(UI.iEvent1);
        if ~isempty(UI.iEvent)
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function gotoEvents(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        UI.iEvent = str2num(UI.panel.events.eventNumber.String);
        if ~isempty(UI.iEvent) && isnumeric(UI.iEvent) && UI.iEvent <= numel(data.events.(UI.settings.eventData).time) && UI.iEvent > 0
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end
    function previousEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if isfield(data.events.(UI.settings.eventData),'flagged') && ~isempty(data.events.(UI.settings.eventData).flagged)
            idx = setdiff(1:numel(data.events.(UI.settings.eventData).time),data.events.(UI.settings.eventData).flagged);
        else
            idx = 1:numel(data.events.(UI.settings.eventData).time);
        end
        UI.iEvent1 = find(data.events.(UI.settings.eventData).time(idx)<t0+UI.settings.windowDuration/2,1,'last');
        UI.iEvent = idx(UI.iEvent1);
        if ~isempty(UI.iEvent)
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function randomEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        UI.iEvent = ceil(numel(data.events.(UI.settings.eventData).time)*rand(1));
        UI.panel.events.eventNumber.String = num2str(UI.iEvent);
        t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
        uiresume(UI.fig);
    end

    function nextPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        [~,idx] = sort(data.events.(UI.settings.eventData).peakNormedPower,'descend');
        test = find(idx==UI.iEvent);
        if ~isempty(test) && test < numel(idx) && test >= 1
            UI.iEvent = idx(test+1);
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function previousPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        [~,idx] = sort(data.events.(UI.settings.eventData).peakNormedPower,'descend');
        test = find(idx==UI.iEvent);
        if ~isempty(test) &&  test <= numel(idx) && test > 1
            UI.iEvent = idx(test-1);
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function maxPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents
            [~,UI.iEvent] = max(data.events.(UI.settings.eventData).peakNormedPower);
            UI.panel.events.eventNumber.String = num2str(UI.iEvent);
            t0 = data.events.(UI.settings.eventData).time(UI.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function flagEvent(~,~)
        UI.settings.stream = false;
        if UI.settings.showEvents
            if ~isfield(data.events.(UI.settings.eventData),'flagged')
                data.events.(UI.settings.eventData).flagged = [];
            end
            idx = find(data.events.(UI.settings.eventData).time==t0+UI.settings.windowDuration/2);
            if ~isempty(idx)
                if any(data.events.(UI.settings.eventData).flagged == idx)
                    idx2 = find(data.events.(UI.settings.eventData).flagged == idx);
                    data.events.(UI.settings.eventData).flagged(idx2) = [];
                else
                    data.events.(UI.settings.eventData).flagged = unique([data.events.(UI.settings.eventData).flagged;idx]);
                end
            end
            UI.panel.events.flagCount.String = ['nFlags: ', num2str(numel(data.events.(UI.settings.eventData).flagged))];
            uiresume(UI.fig);
        end
    end
    
    function addEvent(~,~)
        UI.settings.stream = false;
        if UI.settings.showEvents
            if ~isfield(data.events.(UI.settings.eventData),'added')
                data.events.(UI.settings.eventData).added = [];
            end
            UI.settings.addEventonClick = true;
            UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Left click axes to add event - right click event to delete/flag','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color','w');
        else
            MsgLog('Before adding events you must open an event file',2);
        end
    end
    
    function saveEvent(~,~) % Saving event file
        if isfield(data,'events') && isfield(data.events,UI.settings.eventData)
            data1 = data.events.(UI.settings.eventData);
            saveStruct(data1,'events','session',data.session,'dataName',UI.settings.eventData);
            MsgLog(['Events from ', UI.settings.eventData,' succesfully saved to basepath'],2);
        end
    end
    
    function saveCellMetrics(~,~) % Saving cell_metrics
        if isfield(data,'cell_metrics')
        data1 = data.cell_metrics;
        saveStruct(data1,'cellinfo','session',data.session,'dataName','cell_metrics');
        MsgLog('Cell metrics succesfully saved to basepath',2);
        end
    end

% Time series
    function setTimeseriesData(~,~)
        UI.settings.timeseriesData = UI.panel.timeseries.files.String{UI.panel.timeseries.files.Value};
        UI.settings.showTimeSeries = false;
        showTimeSeries;
    end

% States
    function setStatesData(~,~)
        UI.settings.statesData = UI.panel.states.files.String{UI.panel.states.files.Value};
        UI.settings.showStates = false;
        showStates;
    end

% Behavior
    function setBehaviorData(~,~)
        UI.settings.behavior = UI.panel.behavior.files.String{UI.panel.behavior.files.Value};
        UI.settings.showBehavior = false;
        showBehavior;
    end

    function showTimeSeries(~,~) % Time series (buzcode)
        if UI.settings.showTimeSeries
            UI.settings.showTimeSeries = false;
            UI.panel.timeseries.show.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.timeseriesData,'.timeseries.mat']),'file')
            data.timeseries.(UI.settings.timeseriesData) = loadStruct(UI.settings.timeseriesData,'timeseries','session',data.session);
            if ~isfield(data.timeseries.(UI.settings.timeseriesData),'data')
                data.timeseries.(UI.settings.timeseriesData).data = data.timeseries.(UI.settings.timeseriesData).temp;
            end
            if ~isfield(data.timeseries.(UI.settings.timeseriesData),'timestamps')
                data.timeseries.(UI.settings.timeseriesData).timestamps = data.timeseries.(UI.settings.timeseriesData).time;
            end
            UI.settings.showTimeSeries = true;
            UI.panel.timeseries.show.Value = 1;
        else
            UI.settings.showTimeSeries = false;
            UI.panel.timeseries.show.Value = 0;
        end
        uiresume(UI.fig);
    end

    function showStates(~,~) % States (buzcode)
        if UI.settings.showStates
            UI.settings.showStates = false;
            UI.panel.states.showStates.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.statesData,'.states.mat']),'file')
            if ~isfield(data,'states') || ~isfield(data.states,UI.settings.statesData)
                data.states.(UI.settings.statesData) = loadStruct(UI.settings.statesData,'states','session',data.session);
            end
            UI.settings.showStates = true;
            UI.panel.states.showStates.Value = 1;
            UI.panel.states.statesNumber.String = '1';
            UI.panel.states.statesCount.String = ['nStates: ' num2str(numel(data.states.(UI.settings.statesData).idx.timestamps))];
        else
            UI.settings.showStates = false;
            UI.panel.states.showStates.Value = 0;
        end
        initTraces
        uiresume(UI.fig);
    end

    function previousStates(~,~)
        UI.settings.stream = false;
        if UI.settings.showStates
            timestamps = getTimestampsFromStates;
            idx = find(timestamps<t0,1,'last');
            if ~isempty(idx)
                t0 = timestamps(idx);
                UI.panel.states.statesNumber.String = num2str(idx);
                uiresume(UI.fig);
            end
        end
    end

    function nextStates(~,~)
        UI.settings.stream = false;
        if UI.settings.showStates
            timestamps = getTimestampsFromStates;
            idx = find(timestamps>t0,1);
            if ~isempty(idx)
                t0 = timestamps(idx);
                UI.panel.states.statesNumber.String = num2str(idx);
                uiresume(UI.fig);
            end
        end
    end

    function gotoState(~,~)
        UI.settings.stream = false;
        if UI.settings.showStates
            timestamps = getTimestampsFromStates;
            idx =  str2num(UI.panel.states.statesNumber.String);
            if ~isempty(idx) && isnumeric(idx) && idx>0 && idx<=numel(timestamps)
                t0 = timestamps(idx)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end
    
    function timestamps = getTimestampsFromStates
        timestamps = [];
        if isfield(data.states.(UI.settings.statesData),'ints')
            states1  = data.states.(UI.settings.statesData).ints;
        else
            states1  = data.states.(UI.settings.statesData);
        end
        timestamps1 = cellfun(@(fn) states1.(fn), fieldnames(states1), 'UniformOutput', false);
        timestamps1 = vertcat(timestamps1{:});
        timestamps = [timestamps,timestamps1(:,1)];
        timestamps = sort(timestamps);
    end

    function showBehavior(~,~) % Behavior (buzcode)
        if UI.settings.showBehavior
            UI.settings.showBehavior = false;
            UI.panel.behavior.showBehavior.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.behaviorData,'.behavior.mat']),'file')
            if ~isfield(data,'behavior') || ~isfield(data.behavior,UI.settings.behaviorData)
                data.behavior.(UI.settings.behaviorData) = loadStruct(UI.settings.behaviorData,'behavior','session',data.session);
            end
            data.behavior.xlim = [min(data.behavior.(UI.settings.behaviorData).pos(1,:)),max(data.behavior.(UI.settings.behaviorData).pos(1,:))];
            data.behavior.ylim = [min(data.behavior.(UI.settings.behaviorData).pos(2,:)),max(data.behavior.(UI.settings.behaviorData).pos(2,:))];
            UI.settings.showBehavior = true;
            UI.panel.behavior.showBehavior.Value = 1;
        end
        initTraces
        uiresume(UI.fig);
    end

    function nextBehavior(~,~)
        UI.settings.stream = false;
        if UI.settings.showBehavior
            t0 = data.behavior.(UI.settings.behaviorData).time(end)-UI.settings.windowDuration;
            uiresume(UI.fig);
        end
    end
    
    function previousBehavior(~,~)
        UI.settings.stream = false;
        if UI.settings.showBehavior
            t0 = data.behavior.(UI.settings.behaviorData).time(1);
            uiresume(UI.fig);
        end
    end

    function summaryFigure(~,~)
        UI.settings.stream = false;
        % Spike data
        summaryfig = figure('name','Summary figure','Position',[50 50 1200 900],'visible','off');
        ax1 = axes(summaryfig,'XLim',[0,UI.t_total],'title','Summary figure','YLim',[0,1],'YTickLabel',[],'Color','k','Position',[0.05 0.05 0.9 0.9],'XColor','k','TickDir','out'); hold on, title('Summary figure'), xlabel('Time (s)'), % ce_dragzoom(ax1)
        
        if UI.settings.showSpikes
            dataRange_spikes = UI.dataRange.spikes;
            temp = reshape(struct2array(UI.dataRange),2,[]);
            if ~UI.settings.spikesBelowTrace && ~isempty(temp(2,temp(2,:)<1))
                UI.dataRange.spikes(1) = max(temp(2,temp(2,:)<1));
            end
            UI.dataRange.spikes(2) = 0.97;
            spikesBelowTrace = UI.settings.spikesBelowTrace;
            UI.settings.spikesBelowTrace = true;
            
            plotSpikeData(0,UI.t_total,'w')
            
            UI.dataRange.spikes = dataRange_spikes;
            UI.settings.spikesBelowTrace = spikesBelowTrace;
            
        end
        
        % KiloSort data
        if UI.settings.showKilosort
            plotKilosortData(t0,t0+UI.settings.windowDuration,'c')
        end
        
        % Event data
        if UI.settings.showEvents
            plotEventData(0,UI.t_total,'w','m')
        end
        
        % Time series
        if UI.settings.showTimeSeries
            plotTimeSeriesData(0,UI.t_total,'m')
        end
        
        % States data
        if UI.settings.showStates
            plotTemporalStates(0,UI.t_total)
        end
        
        % Behavior
        if UI.settings.showBehavior
            plotBehavior(0,UI.t_total,'m')
        end
        
        % Trials
        if UI.settings.showTrials
            plotTrials(0,UI.t_total,'w')
        end
        
        % Plotting epochs
        if isfield(data.session,'epochs')
            for i = 1:numel(data.session.epochs)
                if isfield(data.session.epochs{i},'startTime') && isfield(data.session.epochs{i},'stopTime')
                    p1 = patch([data.session.epochs{i}.startTime data.session.epochs{i}.stopTime  data.session.epochs{i}.stopTime data.session.epochs{i}.startTime],[0.97 0.97 0.999 0.999],'w','EdgeColor','w','HitTest','off');
                    alpha(p1,0.7);
                end
                if isfield(data.session.epochs{i},'startTime') && isfield(data.session.epochs{i},'behavioralParadigm')
                    text(data.session.epochs{i}.startTime,0.999,{data.session.epochs{i}.name;data.session.epochs{i}.behavioralParadigm},'color','k','FontWeight', 'Bold','VerticalAlignment', 'top','Margin',0.1,'interpreter','none') % ,'BackgroundColor',[0 0 0 0.7]
                end
            end
        end
        % Plotting current timepoint
        plot([t0;t0],[ax1.YLim(1);ax1.YLim(2)],'--b');
        
        movegui(summaryfig,'center'), set(summaryfig,'visible','on')
    end

    function showTrials(~,~)
        if UI.settings.showTrials
            UI.settings.showTrials = false;
            UI.panel.behavior.showTrials.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.trials.behavior.mat']),'file')
            if ~UI.settings.showBehavior
                showBehavior
            end
            if ~isfield(data,'behavior') || ~isfield(data.behavior,'trials')
                data.behavior.trials = loadStruct('trials','behavior','session',data.session);
            end
            UI.settings.showTrials = true;
            UI.panel.behavior.showTrials.Value = 1;
            UI.panel.behavior.trialNumber.String = '1';
            UI.panel.behavior.trialCount.String = ['nTrials: ' num2str(data.behavior.trials.total)];
        end
        initTraces
        uiresume(UI.fig);
    end

    function nextTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = find(data.behavior.(UI.settings.behaviorData).time(data.behavior.trials.start)>t0,1);
            if isempty(idx)
                idx = 1;
            end
            t0 = data.behavior.(UI.settings.behaviorData).time(data.behavior.trials.start(idx));
            UI.panel.behavior.trialNumber.String = num2str(idx);
            uiresume(UI.fig);
        end
    end

    function previousTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = find(data.behavior.(UI.settings.behaviorData).time(data.behavior.trials.start)<t0,1,'last');
            if isempty(idx)
                idx = numel(data.behavior.trials.start);
            end
            t0 = data.behavior.(UI.settings.behaviorData).time(data.behavior.trials.start(idx));
            UI.panel.behavior.trialNumber.String = num2str(idx);
            uiresume(UI.fig);
        end
    end

    function gotoTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = str2num(UI.panel.behavior.trialNumber.String);
            if ~isempty(idx) && isnumeric(idx) && idx>0 && idx<=numel(data.behavior.trials.start)
                t0 = data.behavior.(UI.settings.behaviorData).time(data.behavior.trials.start(idx))-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
        
    end

    function showKilosort(src,~)
        if UI.panel.kilosort.showKilosort.Value == 1 && ~isfield(data,'spikes_kilosort')
            [file,path] = uigetfile('*.mat','Please select a KiloSort rez file for this session');
            if ~isequal(file,0)
                % Loading rez file
                load(fullfile(path,file),'rez');
                
                % Importing Kilosort data into spikes struct
                if size(rez.st3,2)>4
                    spikeClusters = uint32(rez.st3(:,5));
                    spike_cluster_index = uint32(spikeClusters); % -1 for zero indexing
                else
                    spikeTemplates = uint32(rez.st3(:,2));
                    spike_cluster_index = uint32(spikeTemplates); % -1 for zero indexing
                end
                
                spike_times = uint64(rez.st3(:,1));
                spike_amplitudes = rez.st3(:,3);
                spike_clusters = unique(spike_cluster_index);
                
                UID = 1;
                tol_ms = data.session.extracellular.sr/1100; % 1 ms tolerance in timestamp units
                for i = 1:length(spike_clusters)
                    spikes.ids{UID} = find(spike_cluster_index == spike_clusters(i));
                    tol = tol_ms/max(double(spike_times(spikes.ids{UID}))); % unique values within tol (=within 1 ms)
                    [spikes.ts{UID},ind_unique] = uniquetol(double(spike_times(spikes.ids{UID})),tol);
                    spikes.ids{UID} = spikes.ids{UID}(ind_unique);
                    spikes.times{UID} = spikes.ts{UID}/data.session.extracellular.sr;
                    spikes.cluID(UID) = spike_clusters(i);
                    spikes.total(UID) = length(spikes.ts{UID});
                    spikes.amplitudes{UID} = double(spike_amplitudes(spikes.ids{UID}));
                    [~,spikes.maxWaveformCh1(UID)] = max(abs(rez.U(:,rez.iNeigh(1,spike_clusters(i)),1)));
                    UID = UID+1;
                end
                spikes.numcells = numel(spikes.times);
                spikes.spindices = generateSpinDices(spikes.times);
                data.spikes_kilosort = spikes;
                UI.settings.showKilosort = true;
                uiresume(UI.fig);
                MsgLog(['KiloSort data loaded succesful: ' basename],2)
            else
                UI.settings.showKilosort = false;
                UI.panel.kilosort.showKilosort.Value = 0;
            end
        elseif UI.panel.kilosort.showKilosort.Value == 1  && isfield(data,'spikes_kilosort')
            UI.settings.showKilosort = true;
            uiresume(UI.fig);
        else
            UI.settings.showKilosort = false;
            uiresume(UI.fig);
        end
    end

    function showIntan(src,~) % Intan data
        if strcmp(src.String,'Show analog')
            if UI.panel.intan.showAnalog.Value == 1 && ~isempty(UI.panel.intan.filenameAnalog.String) && exist(fullfile(basepath,UI.panel.intan.filenameAnalog.String),'file')
                UI.settings.intan_showAnalog = true;
                UI.fid.timeSeries.adc = fopen(fullfile(basepath,UI.panel.intan.filenameAnalog.String), 'r');
                
            elseif UI.panel.intan.showAnalog.Value == 1
                UI.panel.intan.showAnalog.Value = 0;
                MsgLog('Failed to load Analog file',4);
            else
                UI.settings.intan_showAnalog = false;
                UI.panel.intan.showAnalog.Value = 0;
            end
        end
        if strcmp(src.String,'Show aux')
            if UI.panel.intan.showAux.Value == 1 && ~isempty(UI.panel.intan.filenameAux.String) && exist(fullfile(basepath,UI.panel.intan.filenameAux.String),'file')
                UI.settings.intan_showAux = true;
                UI.fid.timeSeries.aux = fopen(fullfile(basepath,UI.panel.intan.filenameAux.String), 'r');
            elseif UI.panel.intan.showAux.Value == 1
                UI.panel.intan.showAux.Value = 0;
                UI.settings.intan_showAux = false;
                MsgLog('Failed to load aux file',4);
            else
                UI.settings.intan_showAux = false;
                UI.panel.intan.showAux.Value = 0;                
            end
        end
        if strcmp(src.String,'Show digital')
            if UI.panel.intan.showDigital.Value == 1 && ~isempty(UI.panel.intan.filenameDigital.String) && exist(fullfile(basepath,UI.panel.intan.filenameDigital.String),'file')
                UI.settings.intan_showDigital = true;
                UI.fid.timeSeries.dig = fopen(fullfile(basepath,UI.panel.intan.filenameDigital.String), 'r');
            elseif UI.panel.intan.showDigital.Value == 1
                UI.panel.intan.showDigital.Value = 0;
                MsgLog('Failed to load digital file',4);
            else
                UI.settings.intan_showDigital = false;
                UI.panel.intan.showDigital.Value = 0;
            end
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function editIntanMeta(~,~)
        data.session = gui_session(data.session,[],'inputs');
        initData(basepath,basename);
        initTraces;
        uiresume(UI.fig);
    end
    
    function showIntanBelowTrace(~,~)
        if UI.panel.intan.showIntanBelowTrace.Value == 1
            UI.settings.showIntanBelowTrace = true;
        else
            UI.settings.showIntanBelowTrace = false;
        end
        initTraces
        uiresume(UI.fig);
    end

    function plotTimeSeries(~,~)
        if ~UI.settings.showTimeSeries
            showTimeSeries
        end
        if isfield(data,'timeseries') && isfield(data.timeseries,UI.settings.timeseriesData)
            figure,
            plot(data.timeseries.(UI.settings.timeseriesData).timestamps,data.timeseries.(UI.settings.timeseriesData).data), axis tight, hold on
            ax = gca;
            plot([t0;t0],[ax.YLim(1);ax.YLim(2)],'--b');
        end
    end

    function exportPlotData(src,~)
        UI.settings.stream = false;
        timestamp = datestr(now, '_dd-mm-yyyy_HH.MM.SS');
        % Adding text elemenets with timestamps and windows size
        text(UI.plot_axis1,0,1,[' t  = ', num2str(t0), ' s'],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','left','color','w','Units','normalized')
        text(UI.plot_axis1,1,1,['Window duration = ', num2str(UI.settings.windowDuration), ' sec '],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','right','color','w','Units','normalized')
        % Adding scalebar
        plot([0.005,0.005],[0.93,0.98],'-w','linewidth',3)
        text(UI.plot_axis1,0.005,0.955,['  ',num2str(0.05/(UI.settings.scalingFactor)*1000,3),' mV'],'FontWeight', 'Bold','VerticalAlignment', 'middle','HorizontalAlignment','left','color','w')
        drawnow
        if strcmp(src.Text,'Export to .png file')
            if ~verLessThan('matlab','9.8') 
                exportgraphics(UI.plot_axis1,fullfile(basepath,[basename,'_NeuroScope_',timestamp, '.png']))
            else
                set(UI.fig,'Units','Inches');
                set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
                saveas(UI.fig,fullfile(basepath,[basename,'_NeuroScope_',timestamp, '.png']));
            end
            MsgLog(['The .png file was saved to the basepath: ' basename],2);
        elseif strcmp(src.Text,'Export to .pdf file')
            if ~verLessThan('matlab','9.8') 
                exportgraphics(UI.plot_axis1,fullfile(basepath,[basename,'_NeuroScope_',timestamp, '.pdf']),'ContentType','vector')
            else
                % Renderer is set to painter (vector graphics)
                set(UI.fig,'Units','Inches','Renderer','painters');
                set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
                saveas(UI.fig,fullfile(basepath,[basename,'_NeuroScope_',timestamp, '.pdf']));
                set(UI.fig,'Renderer','opengl');
            end
            MsgLog(['The .pdf file was saved to the basepath: ' basename],2);
        else
            % renderer is set to painter (vector graphics)
            set(UI.fig,'Units','Inches','Renderer','painters');
            set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
            exportsetupdlg(UI.fig)
        end
    end
    
    function setTimeSeriesBoundary(~,~)
        UI.settings.timeseries.lowerBoundary = str2num(UI.panel.timeseries.lowerBoundary.String);
        UI.settings.timeseries.upperBoundary = str2num(UI.panel.timeseries.upperBoundary.String);
        if isempty(UI.settings.timeseries.lowerBoundary)
            UI.settings.timeseries.lowerBoundary = 0;
        end
        if isempty(UI.settings.timeseries.upperBoundary)
            UI.settings.timeseries.upperBoundary = 40;
        end
        UI.panel.timeseries.upperBoundary.String = num2str(UI.settings.timeseries.upperBoundary);
        UI.panel.timeseries.lowerBoundary.String = num2str(UI.settings.timeseries.lowerBoundary);
        uiresume(UI.fig);
    end
    
    function changeColormap(~,~)
        colormapList = {'lines','hsv','jet','colorcube','prism','parula','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink','white'};
        temp = find(strcmp(UI.settings.colormap,colormapList));
        [idx,~] = listdlg('PromptString','Select colormap','ListString',colormapList,'ListSize',[250,400],'InitialValue',temp,'SelectionMode','single','Name','Colormap');
        if ~isempty(idx)
            UI.settings.colormap = colormapList{idx};
            % Generating colormap
            UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);

            % Updating table colors
            classColorsHex = rgb2hex(UI.colors);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            UI.table.electrodeGroups.Data(:,2) = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            
            uiresume(UI.fig);
        end
    end
    
    function columnTraces(~,~)
        UI.settings.columnTraces = ~UI.settings.columnTraces;
        if UI.settings.columnTraces
            UI.menu.display.columnTraces.Checked = 'on';
        else
            UI.menu.display.columnTraces.Checked = 'off';
        end
        initTraces;
    end

    function changeBackgroundColor(~,~)
        try
            colorpick = uisetcolor(UI.plot_axis1.Color,'Background color');
            UI.settings.background = colorpick;
            UI.plot_axis1.Color = UI.settings.background;
            
            colorpick = uisetcolor(UI.plot_axis1.XColor,'X-tick color');
            UI.settings.xtickColor = colorpick;
            UI.plot_axis1.XColor = UI.settings.xtickColor;
        end
    end
        
    function toggleDebug(~,~)
        UI.settings.debug = ~UI.settings.debug;
        if UI.settings.debug
            UI.menu.display.debug.Checked = 'on';
        else
            UI.menu.display.debug.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
    function loadFromFolder(~,~)
        % Shows a file dialog allowing you to select session via a .dat/.mat/.xml to load
        UI.settings.stream = false;
        path1 = uigetdir(pwd,'Please select the data folder');
        if ~isequal(path1,0)
            basename = basenameFromBasepath(path1);
            data = [];
            basepath = path1;
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
            MsgLog(['Session loaded succesful: ' basename],2)
        end
    end
    
    function loadFromFile(~,~)
        UI.settings.stream = false;
        % Shows a file dialog allowing you to select session via a .dat/.mat/.xml to load
        [file,path] = uigetfile('*.mat;*.dat;*.lfp;*.xml','Please select any file with the basename in it');
        if ~isequal(file,0)
            temp = strsplit(file,'.');
            data = [];
            basepath = path;
            basename = temp{1};
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
            MsgLog(['Session loaded succesful: ' basename],2)
        end
    end
    
    function openWebsite(src,~)
        % Opens the CellExplorer website in your browser
        if isprop(src,'Text')
            source = src.Text;
        else
            source = '';
        end
        switch source
            case 'Tutorial on metadata'
                web('https://cellexplorer.org/tutorials/metadata-tutorial/','-new','-browser')
            case 'Documentation on session metadata'
                web('https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata','-new','-browser')
            otherwise
                web('https://CellExplorer.org/','-new','-browser')
        end
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
        UI.settings.stream = false;
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        message2 = sprintf('[%s] %s', timestamp, message);
        %         if ~exist('priority','var') || (exist('priority','var') && any(priority >= 0))
        %             UI.popupmenu.log.String = [UI.popupmenu.log.String;message2];
        %             UI.popupmenu.log.Value = length(UI.popupmenu.log.String);
        %         end
        if exist('priority','var')
            dialog1.Interpreter = 'none';
            dialog1.WindowStyle = 'modal';
            if any(priority < 0)
                disp(message2)
            end
            if any(priority == 1)
                disp(message)
            end
            if any(priority == 2)
                msgbox(message,'NeuroScope2',dialog1);
            end
            if any(priority == 3)
                warning(message)
            end
            if any(priority == 4)
                warndlg(message,'NeuroScope2')
            end
        end
    end
end
