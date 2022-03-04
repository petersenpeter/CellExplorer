function NeuroScope2(varargin)
% % % % % % % % % % % % % % % % % % % % % % % % %
% NeuroScope2 (BETA) is a visualizer for electrophysiological recordings. It was inspired by the original Neuroscope (http://neurosuite.sourceforge.net/)
% and made to mimic its features, but built upon Matlab and the data structure of CellExplorer, making it much easier to hack/customize, 
% and faster than the original NeuroScope. NeuroScope2 is part of CellExplorer - https://CellExplorer.org/
% Learn more at: https://cellexplorer.org/interface/neuroscope2/
%
% Major features:
% - Multiple plotting styles and colors, electrode groups, channel tags, highlight, filter and hide channels
% - Live trace analysis: filters, spike and event detection, single channel spectrogram, RMS-noise-plot, CSD and spike waveforms
% - Plot multiple data streams together (ephys + analog + digital signals)
% - Plot CellExplorer/Buzcode structures: spikes, cell metrics, events, timeseries, states, behavior, trials
%
% Example calls:
%    NeuroScope2
%    NeuroScope2('basepath',basepath)
%    NeuroScope2('session',session)
%
% By Peter Petersen
% % % % % % % % % % % % % % % % % % % % % % % % %

% Shortcuts
% initUI, initData, initInputs, initTraces, 
% plotData, plot_ephys, plotSpikeData, plotSpectrogram, plotTemporalStates, plotEventData, plotTimeSeriesData, 
% plotAnalog, plotDigital, plotBehavior, plotTrials, plotRMSnoiseInset, plotSpikesPCAspace


% Global variables
UI = []; % Struct with UI elements and settings
UI.t0 = 0; % Timestamp of the start of the current window (in seconds)
data = []; % Contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
ephys = []; % Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
ephys.traces = [];
ephys.sr = [];

spikes_raster = []; % Spike raster (used for highlighting, to minimize computations)
epoch_plotElements.t0 = [];
epoch_plotElements.events = [];
score = [];
raster = [];
if isdeployed % Check for if NeuroScope2 is running as a deployed app (compiled .exe or .app for windows and mac respectively)
    if ~isempty(varargin) % If a file name is provided it will load it.
        [basepath,basename,ext] = fileparts(varargin{1});
        if isequal(basepath,0)
            UI.priority = ext;
            return
        end
    else % Otherwise a file load dialog will be shown
        [file1,basepath] = uigetfile('*.mat;*.dat;*.lfp;*.xml','Please select a file with the basename in it from the basepath');
        if ~isequal(file1,0)
            temp1 = strsplit(file1,'.');
            basename = temp1{1};
            UI.priority = temp1{2};
        else
            return
        end
    end
else
    % Handling inputs if run from Matlab
    p = inputParser;
    addParameter(p,'basepath',pwd,@isstr);
    addParameter(p,'basename',[],@isstr);
    addParameter(p,'session',[],@isstruct);
    addParameter(p,'spikes',[],@isstr);
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

int_gt_0 = @(n,sr) (isempty(n)) || (n <= 0 ) || (n >= sr/2);

% % % % % % % % % % % % % % % % % % % % % %
% Initialization 
% % % % % % % % % % % % % % % % % % % % % %

initUI
initData(basepath,basename);
initInputs
initTraces

% Maximazing figure to full screen
if ~verLessThan('matlab', '9.4')
    set(UI.fig,'WindowState','maximize'), set(UI.fig,'visible','on')
else
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
    set(UI.fig,'visible','on')
    drawnow nocallbacks; frame_h = get(UI.fig,'JavaFrame'); set(frame_h,'Maximized',1); drawnow nocallbacks;
end

% % % % % % % % % % % % % % % % % % % % % %
% Main while loop of the interface
% % % % % % % % % % % % % % % % % % % % % %

while UI.t0 >= 0
    % breaking if figure has been closed
    if ~ishandle(UI.fig)
        break
    else
        
        UI.selectedChannels = [];
        UI.selectedUnits = [];
        
        % Plotting data
        plotData;
        
        % Updating epoch axes
        if ishandle(epoch_plotElements.t0)
            delete(epoch_plotElements.t0)
        end
        epoch_plotElements.t0 = line(UI.epochAxes,[UI.t0,UI.t0],[0,1],'color','k', 'HitTest','off','linewidth',1);
        
        % Update UI text and slider
        UI.elements.lower.time.String = num2str(UI.t0);
        UI.elements.lower.slider.Value = min([UI.t0/(UI.t_total-UI.settings.windowDuration)*100,100]);
        
        if UI.settings.debug
            drawnow
        end
        UI.elements.lower.performance.String = ['  Processing: ' num2str(toc(UI.timerInterface),3) ' seconds (', num2str(numel(ephys.traces)*2/1024/1024,3) ' MB ephys data)'];
        uiwait(UI.fig);
        
        % Tracking viewed timestamps in file (the history can be used by pressing the backspace key)
        UI.settings.stream = false;
        UI.t0 = max([0,min([UI.t0,UI.t_total-UI.settings.windowDuration])]);
        if UI.track && UI.t0_track(end) ~= UI.t0
            UI.t0_track = [UI.t0_track,UI.t0];
        end
        UI.track = true;
    end
    UI.timerInterface = tic;
end

% % % % % % % % % % % % % % % % % % % % % %
% Closing 
% % % % % % % % % % % % % % % % % % % % % %

% Closing all file readers
fclose('all');

% Closing main figure if open
if ishandle(UI.fig)
    close(UI.fig);
end

% Using google analytics for anonymous tracking of usage
trackGoogleAnalytics('NeuroScope2',1); 

% Saving session metadata
if UI.settings.saveMetadata
    session = data.session;
    session.neuroScope2.t0 = UI.t0;
    try
        saveStruct(session,'session','commandDisp',false);
    catch
        warning('Could not save session struct to basepath when closing NeuroScope2')
    end
end

% % % % % % % % % % % % % % % % % % % % % %
% Embedded functions 
% % % % % % % % % % % % % % % % % % % % % %

    function initUI % Initialize the UI (settings, parameters, figure, menu, panels, axis)
        
        % % % % % % % % % % % % % % % % % % % % % %
        % System settings
        % % % % % % % % % % % % % % % % % % % % % %
        
        UI.forceNewData = true; % Reload raw data on display
        UI.timerInterface = tic;
        UI.timers.slider = tic;
        UI.iLine = 1;
        UI.colorLine = lines(256);
        UI.freeText = '';
        UI.selectedChannels = [];  
        UI.legend = {};
        UI.settings.saveMetadata = true; % Save metadata on exit
        UI.settings.fileRead = 'bof';
        UI.settings.channelList = [];
        UI.settings.brainRegionsToHide = [];
        UI.settings.channelTags.hide = [];
        UI.settings.channelTags.filter = [];
        UI.settings.channelTags.highlight = [];
        UI.settings.normalClick = true;
        UI.settings.addEventonClick = false;
        
        % Spikes settings
        UI.settings.showSpikes = false;
        
        UI.settings.showKilosort = false;
        UI.settings.showKlusta = false;
        UI.settings.showSpykingcircus = false;
        
        % Cell metrics
        UI.settings.useMetrics = false;
        
        % Event settings
        UI.settings.showEvents = false;
        UI.settings.eventData = [];
        
        % Timeseries settings
        UI.settings.showTimeSeries = false;
        UI.settings.timeseriesData = [];
        
        % States settings
        UI.settings.showStates = false;
        UI.settings.statesData = [];
        
        % Behavior settings
        UI.settings.showBehavior = false;
        UI.settings.behaviorData = [];
        
        % Intan settings
        UI.settings.intan_showAnalog = false;
        UI.settings.intan_showAux = false;
        UI.settings.intan_showDigital = false;      
        
        % Cell metrics
        UI.params.cellTypes = [];
        UI.params.cell_class_count = [];
        UI.groupData1.groupsList = {'groups','tags','groundTruthClassification'};        
        UI.tableData.Column1 = 'putativeCellType';
        UI.tableData.Column2 = 'firingRate';
        UI.params.subsetTable = [];
        UI.params.subsetFilter = [];
        UI.params.subsetCellType = [];
        UI.params.subsetGroups = [];
        UI.params.sortingMetric = 'putativeCellType';
        UI.params.groupMetric = 'putativeCellType';
        
        % % % % % % % % % % % % % % % % % % % % % %
        % User preferences/settings
        % % % % % % % % % % % % % % % % % % % % % %
        
        UI.settings = preferences_NeuroScope2(UI.settings);
        
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating figure
        % % % % % % % % % % % % % % % % % % % % % %
        
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
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Benchmark NeuroScope2',menuSelectedFcn,@benchmarkStream);
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitNeuroScope2,'Separator','on','Accelerator','W');
        
        % File
        UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
        uimenu(UI.menu.file.topMenu,menuLabel,'Load session from folder',menuSelectedFcn,@loadFromFolder);
        uimenu(UI.menu.file.topMenu,menuLabel,'Load session from file',menuSelectedFcn,@loadFromFile,'Accelerator','O');
        UI.menu.file.recentSessions.main = uimenu(UI.menu.file.topMenu,menuLabel,'Recent sessions...','Separator','on');
        uimenu(UI.menu.file.topMenu,menuLabel,'Export to .png file (image)',menuSelectedFcn,@exportPlotData,'Separator','on');
        uimenu(UI.menu.file.topMenu,menuLabel,'Export to .pdf file (vector graphics)',menuSelectedFcn,@exportPlotData);
        uimenu(UI.menu.file.topMenu,menuLabel,'Export figure via the export setup dialog',menuSelectedFcn,@exportPlotData,'Separator','on');
        
        % Session
        UI.menu.session.topMenu = uimenu(UI.fig,menuLabel,'Session');
        uimenu(UI.menu.session.topMenu,menuLabel,'View metadata',menuSelectedFcn,@viewSessionMetaData);
        uimenu(UI.menu.session.topMenu,menuLabel,'Save metadata',menuSelectedFcn,@saveSessionMetadata);
        uimenu(UI.menu.session.topMenu,menuLabel,'Open basepath',menuSelectedFcn,@openSessionDirectory,'Separator','on');
        
        % Cell metrics 
        UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'Cell metrics');
        UI.menu.cellExplorer.defineGroupData = uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Open group data dialog',menuSelectedFcn,@defineGroupData);
        UI.menu.cellExplorer.saveCellMetrics = uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Save cell_metrics',menuSelectedFcn,@saveCellMetrics);
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Open CellExplorer',menuSelectedFcn,@openCellExplorer);
        
        % BuzLabDB
        UI.menu.BuzLabDB.topMenu = uimenu(UI.fig,menuLabel,'BuzLabDB');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Load session from BuzLabDB',menuSelectedFcn,@DatabaseSessionDialog,'Accelerator','D');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'Edit repository paths',menuSelectedFcn,@editDBrepositories);
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current session on website',menuSelectedFcn,@openSessionInWebDB,'Separator','on');
        uimenu(UI.menu.BuzLabDB.topMenu,menuLabel,'View current animal subject on website',menuSelectedFcn,@showAnimalInWebDB);
        
        % Analysis
        UI.menu.analysis.topMenu = uimenu(UI.fig,menuLabel,'Analysis');
        initAnalysisToolsMenu
        UI.menu.analysis.summaryFigure = uimenu(UI.menu.analysis.topMenu,menuLabel,'Summary figure',menuSelectedFcn,@summaryFigure,'Separator','on');
        
        % Settings
        UI.menu.display.topMenu = uimenu(UI.fig,menuLabel,'Settings');
        UI.menu.display.ShowHideMenu = uimenu(UI.menu.display.topMenu,menuLabel,'Show full menu',menuSelectedFcn,@ShowHideMenu);
        UI.menu.display.removeDC = uimenu(UI.menu.display.topMenu,menuLabel,'Remove DC from signal',menuSelectedFcn,@removeDC,'Separator','on');
        UI.menu.display.medianFilter = uimenu(UI.menu.display.topMenu,menuLabel,'Median filter',menuSelectedFcn,@medianFilter);        
        UI.menu.display.ShowChannelNumbers = uimenu(UI.menu.display.topMenu,menuLabel,'Show channel numbers',menuSelectedFcn,@ShowChannelNumbers);
        UI.menu.display.showScalebar = uimenu(UI.menu.display.topMenu,menuLabel,'Show scale bar',menuSelectedFcn,@showScalebar);
        UI.menu.display.narrowPadding = uimenu(UI.menu.display.topMenu,menuLabel,'Narrow ephys padding',menuSelectedFcn,@narrowPadding);
        UI.menu.display.plotStyleDynamicRange = uimenu(UI.menu.display.topMenu,menuLabel,'Dynamic ephys range plot',menuSelectedFcn,@plotStyleDynamicRange,'Checked','on');
        %UI.menu.display.columnTraces = uimenu(UI.menu.display.topMenu,menuLabel,'Multiple columns',menuSelectedFcn,@columnTraces);
        UI.menu.display.colorByChannels = uimenu(UI.menu.display.topMenu,menuLabel,'Color ephys traces by channel order',menuSelectedFcn,@colorByChannels);
        UI.menu.display.resetZoomOnNavigation = uimenu(UI.menu.display.topMenu,menuLabel,'Reset zoom on navigation',menuSelectedFcn,@resetZoomOnNavigation);
        if UI.settings.resetZoomOnNavigation
            UI.menu.display.resetZoomOnNavigation.Checked = 'on';
        end
        
        UI.menu.display.changeColormap = uimenu(UI.menu.display.topMenu,menuLabel,'Change colormap of ephys traces',menuSelectedFcn,@changeColormap,'Separator','on');
        UI.menu.display.changeSpikesColormap = uimenu(UI.menu.display.topMenu,menuLabel,'Change colormap of spikes',menuSelectedFcn,@changeSpikesColormap);        
        UI.menu.display.changeBackgroundColor = uimenu(UI.menu.display.topMenu,menuLabel,'Change background color & primary color (ticks, text and rasters)',menuSelectedFcn,@changeBackgroundColor);
        UI.menu.display.detectedEventsBelowTrace = uimenu(UI.menu.display.topMenu,menuLabel,'Show detected events below traces',menuSelectedFcn,@detectedEventsBelowTrace,'Separator','on');
        UI.menu.display.detectedSpikesBelowTrace = uimenu(UI.menu.display.topMenu,menuLabel,'Show detected spikes below traces',menuSelectedFcn,@detectedSpikesBelowTrace,'Separator','on');
        UI.menu.display.showDetectedSpikeWaveforms = uimenu(UI.menu.display.topMenu,menuLabel,'Show detected spike waveforms',menuSelectedFcn,@showDetectedSpikeWaveforms);
        UI.menu.display.showDetectedSpikesPCAspace = uimenu(UI.menu.display.topMenu,menuLabel,'Show detected spike PCA space (beta feature)',menuSelectedFcn,@showDetectedSpikesPCAspace);
        UI.menu.display.colorDetectedSpikesByWidth = uimenu(UI.menu.display.topMenu,menuLabel,'Color detected spikes by waveform width',menuSelectedFcn,@toggleColorDetectedSpikesByWidth);
        UI.menu.display.debug = uimenu(UI.menu.display.topMenu,menuLabel,'Debug','Separator','on',menuSelectedFcn,@toggleDebug);
        
        % Help
        UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
        uimenu(UI.menu.help.topMenu,menuLabel,'Mouse and keyboard shortcuts',menuSelectedFcn,@HelpDialog);
        uimenu(UI.menu.help.topMenu,menuLabel,'CellExplorer website',menuSelectedFcn,@openWebsite,'Separator','on');
        uimenu(UI.menu.help.topMenu,menuLabel,'- About NeuroScope2',menuSelectedFcn,@openWebsite);
        uimenu(UI.menu.help.topMenu,menuLabel,'- Tutorial on metadata',menuSelectedFcn,@openWebsite);
        uimenu(UI.menu.help.topMenu,menuLabel,'- Documentation on session metadata',menuSelectedFcn,@openWebsite);
        uimenu(UI.menu.help.topMenu,menuLabel,'Support',menuSelectedFcn,@openWebsite,'Separator','on');
        uimenu(UI.menu.help.topMenu,menuLabel,'- Submit feature request',menuSelectedFcn,@openWebsite);
        uimenu(UI.menu.help.topMenu,menuLabel,'- Report an issue',menuSelectedFcn,@openWebsite);

        % % % % % % % % % % % % % % % % % % % % % %
        % Creating UI/panels 
        
        UI.grid_panels = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0); % Flexib grid box
        UI.panel.left = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Left panel
        
        UI.panel.center = uix.VBox( 'Parent', UI.grid_panels, 'Spacing', 0, 'Padding', 0 ); % Center flex box
        % UI.panel.right = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Right panel
        set(UI.grid_panels, 'Widths', [250 -1],'MinimumWidths',[220 1]); % set grid panel size
        set(UI.grid_panels, 'Widths', [250 -1],'MinimumWidths',[5 1]); % set grid panel size
        % Separation of the center box into three panels: title panel, plot panel and lower info panel
        UI.panel.plots = uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.panel.center,'BackgroundColor','k'); % Main plot panel
        UI.panel.info  = uix.HBox('Parent',UI.panel.center, 'Padding', 1); % Lower info panel
        set(UI.panel.center, 'Heights', [-1 20]); % set center panel size
        
        % Left panel tabs
        UI.uitabgroup = uiextras.TabPanel('Parent', UI.panel.left, 'Padding', 1,'FontSize',UI.settings.fontsize ,'TabSize',60);
        UI.panel.general.main1  = uix.ScrollingPanel('Parent',UI.uitabgroup, 'Padding', 0 );
        UI.panel.general.main  = uix.VBox('Parent',UI.panel.general.main1, 'Padding', 1);
        UI.panel.spikedata.main1  = uix.ScrollingPanel('Parent',UI.uitabgroup, 'Padding', 0 );
        UI.panel.spikedata.main  = uix.VBox('Parent',UI.panel.spikedata.main1, 'Padding', 1);
        UI.panel.other.main1  = uix.ScrollingPanel('Parent',UI.uitabgroup, 'Padding', 0 );
        UI.panel.other.main  = uix.VBox('Parent',UI.panel.other.main1, 'Padding', 1);
        UI.uitabgroup.TabNames = {'General', 'Spikes','Other'};

        % % % % % % % % % % % % % % % % % % % % % %
        % 1. PANEL: General elements
        % Navigation
        UI.panel.general.navigation = uipanel('Parent',UI.panel.general.main,'title','Navigation');
        UI.buttons.play1 = uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.15 0.98],'String',char(9654),'Callback',@(~,~)streamDataButtons,'KeyPressFcn', @keyPress,'tooltip','Stream from current timepoint'); 
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.17 0.01 0.15 0.98],'String',char(8592),'Callback',@(src,evnt)back,'KeyPressFcn', @keyPress,'tooltip','Go back in time');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.33 0.5 0.34 0.49],'String',char(8593),'Callback',@(src,evnt)increaseAmplitude,'KeyPressFcn', @keyPress,'tooltip','Increase amplitude of ephys data');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.33 0.01 0.34 0.49],'String',char(8595),'Callback',@(src,evnt)decreaseAmplitude,'KeyPressFcn', @keyPress,'tooltip','Decrease amplitude of ephys data');
        uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.68 0.01 0.15 0.98],'String',char(8594),'Callback',@(src,evnt)advance,'KeyPressFcn', @keyPress,'tooltip','Forward in time');
        UI.buttons.play2 = uicontrol('Parent',UI.panel.general.navigation,'Style','pushbutton','Units','normalized','Position',[0.84 0.01 0.15 0.98],'String',[char(9655) char(9654)],'Callback',@(~,~)streamDataButtons2,'KeyPressFcn', @keyPress,'tooltip','Stream from end of file');
        
        % Electrophysiology
        UI.panel.general.filter = uipanel('Parent',UI.panel.general.main,'title','Extracellular traces');
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Plot style', 'Units','normalized', 'Position', [0.01 0.87 0.3 0.1],'HorizontalAlignment','left','tooltip','Select plot style');
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Plot colors', 'Units','normalized', 'Position', [0.01 0.74 0.3 0.1],'HorizontalAlignment','left','tooltip','Select plot colors/greyscale');
        UI.panel.general.plotStyle = uicontrol('Parent',UI.panel.general.filter,'Style', 'popup','String',{'Downsampled','Range','Raw','LFP (*.lfp file)','Image','No ephys traces'}, 'value', UI.settings.plotStyle, 'Units','normalized', 'Position', [0.3 0.86 0.69 0.12],'Callback',@changePlotStyle,'HorizontalAlignment','left');
        UI.panel.general.colorScale = uicontrol('Parent',UI.panel.general.filter,'Style', 'popup','String',{'Colors','Colors 75%','Colors 50%','Colors 25%','Grey-scale','Grey-scale 75%','Grey-scale 50%','Grey-scale 25%'}, 'value', 1, 'Units','normalized', 'Position', [0.3 0.73 0.69 0.12],'Callback',@changeColorScale,'HorizontalAlignment','left');
        UI.panel.general.filterToggle = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String','Filter traces', 'value', 0, 'Units','normalized', 'Position', [0. 0.62 0.5 0.11],'Callback',@changeTraceFilter,'HorizontalAlignment','left','tooltip','Filter ephys traces');
        UI.panel.general.extraSpacing = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String','Group spacing', 'value', 0, 'Units','normalized', 'Position', [0.5 0.62 0.5 0.11],'Callback',@extraSpacing,'HorizontalAlignment','left','tooltip','Spacing between channels from different electrode groups');
        if UI.settings.extraSpacing
            UI.panel.general.extraSpacing.Value = 1;
        end
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Lower filter (Hz)', 'Units','normalized', 'Position', [0.0 0.52 0.5 0.09],'HorizontalAlignment','center');
        uicontrol('Parent',UI.panel.general.filter,'Style', 'text', 'String', 'Higher filter (Hz)', 'Units','normalized', 'Position', [0.5 0.52 0.5 0.09],'HorizontalAlignment','center');
        UI.panel.general.lowerBand  = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', '400', 'Units','normalized', 'Position', [0.01 0.39 0.48 0.12],'Callback',@changeTraceFilter,'HorizontalAlignment','center','tooltip','Lower frequency boundary (Hz)');
        UI.panel.general.higherBand = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.5 0.39 0.49 0.12],'Callback',@changeTraceFilter,'HorizontalAlignment','center','tooltip','Higher frequency band (Hz)');
        UI.panel.general.plotEnergy = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String','Absolute smoothing (sec)', 'value', 0, 'Units','normalized', 'Position', [0.01 0.26 0.68 0.12],'Callback',@plotEnergy,'HorizontalAlignment','left');
        UI.panel.general.energyWindow = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.energyWindow), 'Units','normalized', 'Position', [0.7 0.26 0.29 0.12],'Callback',@plotEnergy,'HorizontalAlignment','center','tooltip','Smoothing window (seconds)');
        UI.panel.general.detectEvents = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String',['Detect events (',char(181),'V)'], 'value', 0, 'Units','normalized', 'Position', [0.01 0.135 0.68 0.12],'Callback',@toogleDetectEvents,'HorizontalAlignment','left');
        UI.panel.general.eventThreshold = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.eventThreshold), 'Units','normalized', 'Position', [0.7 0.135 0.29 0.12],'Callback',@toogleDetectEvents,'HorizontalAlignment','center','tooltip',['Event detection threshold (',char(181),'V)']);
        UI.panel.general.detectSpikes = uicontrol('Parent',UI.panel.general.filter,'Style', 'checkbox','String',['Detect spikes (',char(181),'V)'], 'value', 0, 'Units','normalized', 'Position', [0.01 0.01 0.68 0.12],'Callback',@toogleDetectSpikes,'HorizontalAlignment','left');
        UI.panel.general.detectThreshold = uicontrol('Parent',UI.panel.general.filter,'Style', 'Edit', 'String', num2str(UI.settings.spikesDetectionThreshold), 'Units','normalized', 'Position', [0.7 0.01 0.29 0.12],'Callback',@toogleDetectSpikes,'HorizontalAlignment','center','tooltip',['Spike detection threshold (',char(181),'V)']);
        
        % Electrode groups
        UI.uitabgroup_channels = uiextras.TabPanel('Parent', UI.panel.general.main, 'Padding', 1,'FontSize',UI.settings.fontsize ,'TabSize',50);
        UI.panel.electrodeGroups.main  = uix.VBox('Parent',UI.uitabgroup_channels, 'Padding', 1);
        UI.panel.chanelList.main  = uix.VBox('Parent',UI.uitabgroup_channels, 'Padding', 1);
        UI.panel.brainRegions.main  = uix.VBox('Parent',UI.uitabgroup_channels, 'Padding', 1);
        UI.panel.chanCoords.main  = uix.VBox('Parent',UI.uitabgroup_channels, 'Padding', 1);
        UI.uitabgroup_channels.TabNames = {'Groups', 'Channels','Regions','Layout'};
        
        UI.table.electrodeGroups = uitable(UI.panel.electrodeGroups.main,'Data',{false,'','',''},'Units','normalized','Position',[0 0 1 1],'ColumnWidth',{20 20 45 200},'columnname',{'','','Group','Channels        '},'RowName',[],'ColumnEditable',[true false false false],'CellEditCallback',@editElectrodeGroups,'CellSelectionCallback',@ClicktoSelectFromTable);
        UI.panel.electrodeGroupsButtons = uipanel('Parent',UI.panel.general.main);
        
        % Channel list
        UI.listbox.channelList = uicontrol('Parent',UI.panel.chanelList.main,'Style','listbox','Position',[0 0 1 1],'Units','normalized','String',{'1'},'min',0,'Value',1,'fontweight', 'bold','Callback',@buttonChannelList,'KeyPressFcn', {@keyPress});

        % Brain regions
        UI.table.brainRegions = uitable(UI.panel.brainRegions.main,'Data',{false,'','',''},'Units','normalized','Position',[0 0 1 1],'ColumnWidth',{20 45 125 45},'columnname',{'','Region','Channels','Groups'},'RowName',[],'ColumnEditable',[true false false false],'CellEditCallback',@editBrainregionList);
        
        % Channel coordinates
        UI.chanCoordsAxes = axes('Parent',UI.panel.chanCoords.main,'Units','Normalize','Position',[0 0 1 1],'YLim',[0,1],'YTick',[],'XTick',[]); axis tight
        
        % Group buttons
        uicontrol('Parent',UI.panel.electrodeGroupsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.485 0.98],'String','Show all','Callback',@buttonsElectrodeGroups,'KeyPressFcn', @keyPress,'tooltip','Select all');
        uicontrol('Parent',UI.panel.electrodeGroupsButtons,'Style','pushbutton','Units','normalized','Position',[0.505 0.01 0.485 0.98],'String','Show none','Callback',@buttonsElectrodeGroups,'KeyPressFcn', @keyPress,'tooltip','Deselect all');
        
        % Channel tags
        UI.panel.channelTagsList = uipanel('Parent',UI.panel.general.main,'title','Channel tags');
        UI.table.channeltags = uitable(UI.panel.channelTagsList,'Data', {'','',false,false,false,'',''},'Units','normalized','Position',[0 0 1 1],'ColumnWidth',{20 60 20 20 20 55 55},'columnname',{'','Tags',char(8226),'+','-','Channels','Groups'},'RowName',[],'ColumnEditable',[false false true true true true false],'CellEditCallback',@editChannelTags,'CellSelectionCallback',@ClicktoSelectFromTable2);
        UI.panel.channelTagsButtons = uipanel('Parent',UI.panel.general.main);
        uicontrol('Parent',UI.panel.channelTagsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.485 0.98],'String','New tag','Callback',@buttonsChannelTags,'KeyPressFcn', @keyPress,'tooltip','Add channel tag');
        uicontrol('Parent',UI.panel.channelTagsButtons,'Style','pushbutton','Units','normalized','Position',[0.505 0.01 0.485 0.98],'String','Delete tag(s)','Callback',@buttonsChannelTags,'KeyPressFcn', @keyPress,'tooltip','Delete channel tag');
        
        % Notes
        UI.panel.notes.main = uipanel('Parent',UI.panel.general.main,'title','Session notes');
        UI.panel.notes.text = uicontrol('Parent',UI.panel.notes.main,'Style', 'Edit', 'String', '','Units' ,'normalized', 'Position', [0, 0, 1, 1],'HorizontalAlignment','left', 'Min', 0, 'Max', 200,'Callback',@getNotes);
        
        % Epochs
        UI.panel.epochs.main = uipanel('Parent',UI.panel.general.main,'title','Session epochs');
        UI.epochAxes = axes('Parent',UI.panel.epochs.main,'Units','Normalize','Position',[0 0 1 1],'YLim',[0,1],'YTick',[],'ButtonDownFcn',@ClickEpochs,'XTick',[]); axis tight %,'Color',UI.settings.background,'XColor',UI.settings.primaryColor,'TickLength',[0.005, 0.001],'XMinorTick','on',,'Clipping','off');
        
        % Time series data
        UI.panel.timeseriesdata.main = uipanel('Title','Time series data','Position',[0 0.2 1 0.1],'Units','normalized','Parent',UI.panel.general.main);
        UI.table.timeseriesdata = uitable(UI.panel.timeseriesdata.main,'Data',{false,'','',''},'Units','normalized','Position',[0 0.20 1 0.80],'ColumnWidth',{20 35 125 45},'columnname',{'','Tag','File name','nChan'},'RowName',[],'ColumnEditable',[true false false false],'CellEditCallback',@showIntan);
        UI.panel.timeseriesdata.showTimeseriesBelowTrace = uicontrol('Parent',UI.panel.timeseriesdata.main,'Style','checkbox','Units','normalized','Position',[0 0 0.5 0.20], 'value', 0,'String','Below traces','Callback',@showTimeseriesBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show time series data below traces');
        uicontrol('Parent',UI.panel.timeseriesdata.main,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.49 0.19],'String','Metadata','Callback',@editIntanMeta,'KeyPressFcn', @keyPress,'tooltip','Edit session metadata');
            
        % Defining flexible panel heights
        set(UI.panel.general.main, 'Heights', [65 210 -200 35 -100 35 100 40 150],'MinimumHeights',[65 210 160 35 140 35 50 30 150]);
        UI.panel.general.main1.MinimumWidths = 218;
        UI.panel.general.main1.MinimumHeights = 935; 
        
        % % % % % % % % % % % % % % % % % % % % % %
        % 2. PANEL: Spikes related metrics
        % Spikes
        UI.panel.spikes.main = uipanel('Parent',UI.panel.spikedata.main,'title','Spikes  (*.spikes.cellinfo.mat)');
        UI.panel.spikes.showSpikes = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Show spikes', 'value', 0, 'Units','normalized', 'Position', [0.01 0.85 0.48 0.14],'Callback',@toggleSpikes,'HorizontalAlignment','left','tooltip','Load and show spike rasters');
        UI.panel.spikes.showSpikesBelowTrace = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Below traces', 'value', 0, 'Units','normalized', 'Position', [0.51 0.85 0.75 0.14],'Callback',@showSpikesBelowTrace,'HorizontalAlignment','left','tooltip','Show spike rasters below ephys traces');
        uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', ' Colors: ', 'Units','normalized', 'Position', [0 0.68 0.35 0.16],'HorizontalAlignment','left','tooltip','Define color groups');
        UI.panel.spikes.setSpikesGroupColors = uicontrol('Parent',UI.panel.spikes.main,'Style', 'popup', 'String', {'UID','Single color','Electrode groups'}, 'Units','normalized', 'Position', [0.35 0.68 0.64 0.16],'HorizontalAlignment','left','Enable','off','Callback',@setSpikesGroupColors);
        uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', ' Sorting/Ydata: ', 'Units','normalized', 'Position', [0.0 0.51 0.4 0.16],'HorizontalAlignment','left','tooltip','Only applies to rasters shown below ephys traces');
        UI.panel.spikes.setSpikesYData = uicontrol('Parent',UI.panel.spikes.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.35 0.51 0.64 0.16],'HorizontalAlignment','left','Enable','off','Callback',@setSpikesYData);

       	uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', 'Width ', 'Units','normalized', 'Position', [0.37 0.34 0.3 0.13],'HorizontalAlignment','right','tooltip','Relative width of the spike waveforms');        
        UI.panel.spikes.showSpikeWaveforms = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Waveforms', 'value', 0, 'Units','normalized', 'Position', [0.01 0.34 0.43 0.16],'Callback',@showSpikeWaveforms,'HorizontalAlignment','left','tooltip','Show spike waveforms below ephys traces');
        UI.panel.spikes.waveformsRelativeWidth = uicontrol('Parent',UI.panel.spikes.main,'Style', 'Edit', 'String',num2str(UI.settings.waveformsRelativeWidth), 'Units','normalized', 'Position', [0.67 0.34 0.32 0.16],'HorizontalAlignment','center','Callback',@showSpikeWaveforms);
        uicontrol('Parent',UI.panel.spikes.main,'Style', 'text', 'String', 'Electrode group ', 'Units','normalized', 'Position', [0.17 0.17 0.5 0.13],'HorizontalAlignment','right','tooltip','Electrode group that the PCA representation is applied to');
        UI.panel.spikes.showSpikesPCAspace = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','PCAs', 'value', 0, 'Units','normalized', 'Position', [0.01 0.17 0.23 0.16],'Callback',@showSpikesPCAspace,'HorizontalAlignment','left');
        UI.panel.spikes.PCA_electrodeGroup = uicontrol('Parent',UI.panel.spikes.main,'Style', 'Edit', 'String', num2str(UI.settings.PCAspace_electrodeGroup), 'Units','normalized', 'Position', [0.67 0.17 0.32 0.16],'HorizontalAlignment','center','Callback',@showSpikesPCAspace);
        
        UI.panel.spikes.showSpikeMatrix = uicontrol('Parent',UI.panel.spikes.main,'Style', 'checkbox','String','Show matrix', 'value', 0, 'Units','normalized', 'Position', [0.01 0.01 0.45 0.15],'Callback',@showSpikeMatrix,'HorizontalAlignment','left');
        %UI.panel.spikes.setSpikesGroupColors = uicontrol('Parent',UI.panel.spikes.main,'Style', 'popup', 'String', {'UID','Single color','Electrode groups'}, 'Units','normalized', 'Position', [0.35 0.60 0.64 0.16],'HorizontalAlignment','left','Enable','off','Callback',@setSpikesGroupColors);
        
        % Cell metrics
        UI.panel.cell_metrics.main = uipanel('Parent',UI.panel.spikedata.main,'title','Cell metrics (*.cell_metrics.cellinfo.mat)');
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Color groups', 'Units','normalized','Position', [0 0.74 0.5 0.12],'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Sorting','Units','normalized','Position', [0 0.47 1 0.12],'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'text', 'String', '  Filter', 'Units','normalized','Position', [0 0.17 1 0.12], 'HorizontalAlignment','left');
        UI.panel.cell_metrics.useMetrics = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'checkbox','String','Use metrics', 'value', 0, 'Units','normalized','Position', [0 0.85 0.5 0.15], 'Callback',@toggleMetrics,'HorizontalAlignment','left');
        UI.panel.cell_metrics.defineGroupData = uicontrol('Parent',UI.panel.cell_metrics.main,'Style','pushbutton','Units','normalized','Position',[0.5 0.82 0.49 0.18],'String','Group data','Callback',@defineGroupData,'KeyPressFcn', @keyPress,'tooltip','Filter and highlight by groups','Enable','off'); 
        UI.panel.cell_metrics.groupMetric = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'popup', 'String', {''}, 'Units','normalized','Position', [0.01 0.6 0.98 0.15],'HorizontalAlignment','left','Enable','off','Callback',@setGroupMetric);
        UI.panel.cell_metrics.sortingMetric = uicontrol('Parent',UI.panel.cell_metrics.main,'Style', 'popup', 'String', {''}, 'Units','normalized','Position', [0.01 0.32 0.98 0.15],'HorizontalAlignment','left','Enable','off','Callback',@setSortingMetric);
        UI.panel.cell_metrics.textFilter = uicontrol('Style','edit', 'Units','normalized','Position',[0.01 0.01 0.98 0.17],'String','','HorizontalAlignment','left','Parent',UI.panel.cell_metrics.main,'Callback',@filterCellsByText,'Enable','off','tooltip',sprintf('Search across cell metrics\nString fields: "CA1" or "Interneuro"\nNumeric fields: ".firingRate > 10" or ".cv2 < 0.5" (==,>,<,~=) \nCombine with AND // OR operators (&,|) \nEaxmple: ".firingRate > 10 & CA1"\nFilter by parent brain regions as well, fx: ".brainRegion HIP"\nMake sure to include  spaces between fields and operators' ));

        UI.panel.cellTypes.main = uipanel('Parent',UI.panel.spikedata.main,'title','Putative cell types');
        UI.listbox.cellTypes = uicontrol('Parent',UI.panel.cellTypes.main,'Style','listbox', 'Units','normalized','Position',[0 0 1 1],'String',{''},'Enable','off','max',20,'min',0,'Value',[],'Callback',@setCellTypeSelectSubset,'KeyPressFcn', @keyPress,'tooltip','Filter putative cell types. Select to filter');
        
        % Table with list of cells
        UI.panel.cellTable.main = uipanel('Parent',UI.panel.spikedata.main,'title','List of cells');
        UI.table.cells = uitable(UI.panel.cellTable.main,'Data', {false,'','',''},'Units','normalized','Position',[0 0 1 1],'ColumnWidth',{20 25 118 55},'columnname',{'','#','Cell type','Rate (Hz)'},'RowName',[],'ColumnEditable',[true false false false],'ColumnFormat',{'logical','char','char','numeric'},'CellEditCallback',@editCellTable,'Enable','off');
        UI.panel.metricsButtons = uipanel('Parent',UI.panel.spikedata.main);
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.32 0.98],'String','All','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Show all cells');
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.34 0.01 0.32 0.98],'String','None','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Hide all cells');
        uicontrol('Parent',UI.panel.metricsButtons,'Style','pushbutton','Units','normalized','Position',[0.67 0.01 0.32 0.98],'String','Metrics','Callback',@metricsButtons,'KeyPressFcn', @keyPress,'tooltip','Show table with metrics');
        
        % Population analysis
        UI.panel.populationAnalysis.main = uipanel('Parent',UI.panel.spikedata.main,'title','Population dynamics');
        UI.panel.spikes.populationRate = uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'checkbox','String','Show rate', 'value', 0, 'Units','normalized', 'Position', [0.01 0.68 0.485 0.3],'Callback',@tooglePopulationRate,'HorizontalAlignment','left');
        UI.panel.spikes.populationRateBelowTrace = uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'checkbox','String','Below traces', 'value', 0, 'Units','normalized', 'Position', [0.505 0.68 0.485 0.3],'Callback',@tooglePopulationRate,'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'text','String','Binsize (in sec)', 'Units','normalized', 'Position', [0.01 0.33 0.68 0.25],'Callback',@tooglePopulationRate,'HorizontalAlignment','left');
        UI.panel.spikes.populationRateWindow = uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'Edit', 'String', num2str(UI.settings.populationRateWindow), 'Units','normalized', 'Position', [0.7 0.32 0.29 0.3],'Callback',@tooglePopulationRate,'HorizontalAlignment','center','tooltip',['Binsize (seconds)']);
        uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'text','String','Gaussian smoothing (bins)', 'Units','normalized', 'Position', [0.01 0.01 0.68 0.25],'Callback',@tooglePopulationRate,'HorizontalAlignment','left');
        UI.panel.spikes.populationRateSmoothing = uicontrol('Parent',UI.panel.populationAnalysis.main,'Style', 'Edit', 'String', num2str(UI.settings.populationRateSmoothing), 'Units','normalized', 'Position', [0.7 0.01 0.29 0.3],'Callback',@tooglePopulationRate,'HorizontalAlignment','center','tooltip',['Binsize (seconds)']);
        
        % Spike sorting pipelines
        UI.panel.spikesorting.main = uipanel('Title','Other spike sorting formats','Position',[0 0.2 1 0.1],'Units','normalized','Parent',UI.panel.spikedata.main);
        UI.panel.spikesorting.showKilosort = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.01 0.66 0.485 0.32], 'value', 0,'String','Kilosort','Callback',@showKilosort,'KeyPressFcn', @keyPress,'tooltip','Open a KiloSort rez.mat data and show detected spikes');
        UI.panel.spikesorting.kilosortBelowTrace = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.505 0.66 0.485 0.32], 'value', 0,'String','Below traces','Callback',@showKilosort,'KeyPressFcn', @keyPress,'tooltip','Show KiloSort spikes below trace');
        
        UI.panel.spikesorting.showKlusta = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.01 0.33 0.485 0.32], 'value', 0,'String','Klustakwik','Callback',@showKlusta,'KeyPressFcn', @keyPress,'tooltip','Open Klustakwik clustered data files and show detected spikes');
        UI.panel.spikesorting.klustaBelowTrace = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.505 0.33 0.485 0.32], 'value', 0,'String','Below traces','Callback',@showKlusta,'KeyPressFcn', @keyPress,'tooltip','Show Klustakwik spikes below trace');
        
        UI.panel.spikesorting.showSpykingcircus = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.01 0 0.485 0.32], 'value', 0,'String','Spyking Circus','Callback',@showSpykingcircus,'KeyPressFcn', @keyPress,'tooltip','Open SpyKING CIRCUS clustered data and show detected spikes');
        UI.panel.spikesorting.spykingcircusBelowTrace = uicontrol('Parent',UI.panel.spikesorting.main,'Style','checkbox','Units','normalized','Position',[0.505 0 0.485 0.32], 'value', 0,'String','Below traces','Callback',@showSpykingcircus,'KeyPressFcn', @keyPress,'tooltip','Show SpyKING CIRCUS spikes below trace');

        % Defining flexible panel heights
        set(UI.panel.spikedata.main, 'Heights', [160 170 100 -200 35 100 95],'MinimumHeights',[160 170 60 160 35 60 95]);
        UI.panel.spikedata.main1.MinimumWidths = 218;
        UI.panel.spikedata.main1.MinimumHeights = 825;
        
        % % % % % % % % % % % % % % % % % % % % % %
        % 3. PANEL: Other datatypes
        % Events
        UI.panel.events.navigation = uipanel('Parent',UI.panel.other.main,'title','Events (*.events.mat)');
        UI.panel.events.files = uicontrol('Parent',UI.panel.events.navigation,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.85 0.98 0.13],'HorizontalAlignment','left','Callback',@setEventData);
        UI.panel.events.showEvents = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.01 0.75 0.5 0.1], 'value', 0,'String','Show events','Callback',@showEvents,'KeyPressFcn', @keyPress,'tooltip','Show events');
        UI.panel.events.showEventsBelowTrace = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.505 0.75 0.485 0.1], 'value', 0,'String','Below traces','Callback',@showEventsBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show events below traces');
        UI.panel.events.showEventsIntervals = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.01 0.65 0.458 0.1], 'value', 0,'String','Intervals','Callback',@showEventsIntervals,'KeyPressFcn', @keyPress,'tooltip','Show events intervals');
        UI.panel.events.processing_steps = uicontrol('Parent',UI.panel.events.navigation,'Style','checkbox','Units','normalized','Position',[0.505 0.65 0.458 0.1], 'value', 0,'String','Processing','Callback',@processing_steps,'KeyPressFcn', @keyPress,'tooltip','Show processing steps');
        UI.panel.events.eventNumber = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.485 0.485 0.14],'HorizontalAlignment','center','tooltip','Event number','Callback',@gotoEvents);
        UI.panel.events.eventCount = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', 'nEvents', 'Units','normalized', 'Position', [0.505 0.485 0.485 0.14],'HorizontalAlignment','center','Enable','off');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.33 0.32 0.14],'String',char(8592),'Callback',@previousEvent,'KeyPressFcn', @keyPress,'tooltip','Previous event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.34 0.33 0.32 0.14],'String','Random','Callback',@(src,evnt)randomEvent,'KeyPressFcn', @keyPress,'tooltip','Random event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.67 0.33 0.32 0.14],'String',char(8594),'Callback',@nextEvent,'KeyPressFcn', @keyPress,'tooltip','Next event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.17 0.485 0.14],'String','Flag event','Callback',@flagEvent,'KeyPressFcn', @keyPress,'tooltip','Flag selected event');
        UI.panel.events.flagCount = uicontrol('Parent',UI.panel.events.navigation,'Style', 'Edit', 'String', 'nFlags', 'Units','normalized', 'Position', [0.505 0.17 0.485 0.14],'HorizontalAlignment','center','Enable','off');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.01 0.01 0.485 0.14],'String','Manual event','Callback',@addEvent,'KeyPressFcn', @keyPress,'tooltip','Add event');
        uicontrol('Parent',UI.panel.events.navigation,'Style','pushbutton','Units','normalized','Position',[0.505 0.01 0.485 0.14],'String','Save events','Callback',@saveEvent,'KeyPressFcn', @keyPress,'tooltip','Save events');
        
        % Time series
        UI.panel.timeseries.main = uipanel('Parent',UI.panel.other.main,'title','Time series (*.timeseries.mat)');
        UI.panel.timeseries.files = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.72 0.98 0.26],'HorizontalAlignment','left','Callback',@setTimeseriesData);
        UI.panel.timeseries.show = uicontrol('Parent',UI.panel.timeseries.main,'Style','checkbox','Units','normalized','Position',[0.01 0.45 0.485 0.27], 'value', 0,'String','Show','Callback',@showTimeSeries,'KeyPressFcn', @keyPress,'tooltip','Show timeseries data');
        uicontrol('Parent',UI.panel.timeseries.main,'Style','pushbutton','Units','normalized','Position',[0.505 0.45 0.485 0.27],'String','Full trace','Callback',@plotTimeSeries,'KeyPressFcn', @keyPress,'tooltip','Show full trace in separate figure');
        uicontrol('Parent',UI.panel.timeseries.main,'Style', 'text', 'String', 'Lower limit', 'Units','normalized', 'Position', [0.0 0.25 0.5 0.18],'HorizontalAlignment','center');
        uicontrol('Parent',UI.panel.timeseries.main,'Style', 'text', 'String', 'Upper limit', 'Units','normalized', 'Position', [0.5 0.25 0.5 0.18],'HorizontalAlignment','center');
        UI.panel.timeseries.lowerBoundary = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'Edit', 'String', num2str(UI.settings.timeseries.lowerBoundary), 'Units','normalized', 'Position', [0.01 0 0.485 0.26],'HorizontalAlignment','center','tooltip','Lower bound','Callback',@setTimeSeriesBoundary);
        UI.panel.timeseries.upperBoundary = uicontrol('Parent',UI.panel.timeseries.main,'Style', 'Edit', 'String', num2str(UI.settings.timeseries.upperBoundary), 'Units','normalized', 'Position', [0.505 0 0.485 0.26],'HorizontalAlignment','center','tooltip','Higher bound','Callback',@setTimeSeriesBoundary);
        
        % States
        UI.panel.states.main = uipanel('Parent',UI.panel.other.main,'title','States (*.states.mat)');
        UI.panel.states.files = uicontrol('Parent',UI.panel.states.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.67 0.98 0.31],'HorizontalAlignment','left','Callback',@setStatesData);
        UI.panel.states.showStates = uicontrol('Parent',UI.panel.states.main,'Style','checkbox','Units','normalized','Position',[0.01 0.35 1 0.33], 'value', 0,'String','Show states','Callback',@showStates,'KeyPressFcn', @keyPress,'tooltip','Show states data');
        UI.panel.states.previousStates = uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.505 0.35 0.24 0.32],'String',char(8592),'Callback',@previousStates,'KeyPressFcn', @keyPress,'tooltip','Previous state');
        UI.panel.states.nextStates = uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.755 0.35 0.235 0.32],'String',char(8594),'Callback',@nextStates,'KeyPressFcn', @keyPress,'tooltip','Next state');
        UI.panel.states.statesNumber = uicontrol('Parent',UI.panel.states.main,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.01 0.485 0.32],'HorizontalAlignment','center','tooltip','State number','Callback',@gotoState);
        UI.panel.states.statesCount = uicontrol('Parent',UI.panel.states.main,'Style', 'Edit', 'String', 'nStates', 'Units','normalized', 'Position', [0.505 0.01 0.485 0.32],'HorizontalAlignment','center','Enable','off');
        
        % Behavior
        UI.panel.behavior.main = uipanel('Parent',UI.panel.other.main,'title','Behavior (*.behavior.mat)');
        UI.panel.behavior.files = uicontrol('Parent',UI.panel.behavior.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.79 0.98 0.19],'HorizontalAlignment','left','Callback',@setBehaviorData);
        UI.panel.behavior.showBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0 0.60 1 0.19], 'value', 0,'String','Show behavior','Callback',@showBehavior,'KeyPressFcn', @keyPress,'tooltip','Show behavior');
        UI.panel.behavior.previousBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.505 0.60 0.24 0.19],'String',['| ' char(8592)],'Callback',@previousBehavior,'KeyPressFcn', @keyPress,'tooltip','Start of behavior');
        UI.panel.behavior.nextBehavior = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.755 0.60 0.235 0.19],'String',[char(8594) ' |'],'Callback',@nextBehavior,'KeyPressFcn', @keyPress,'tooltip','End of behavior','BusyAction','cancel');
        UI.panel.behavior.showBehaviorBelowTrace = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0.505 0.41 0.485 0.19], 'value', 0,'String','Below traces','Callback',@showBehaviorBelowTrace,'KeyPressFcn', @keyPress,'tooltip','Show behavior data below traces');
        UI.panel.behavior.plotBehaviorLinearized = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0.01 0.41 0.485 0.19], 'value', 0,'String','Linearize','Callback',@plotBehaviorLinearized,'KeyPressFcn', @keyPress,'tooltip','Show linearized behavior');
        UI.panel.behavior.showTrials = uicontrol('Parent',UI.panel.behavior.main,'Style','checkbox','Units','normalized','Position',[0.01 0.22 0.99 0.19], 'value', 0,'String','Trials','Callback',@showTrials,'KeyPressFcn', @keyPress,'tooltip','Show trial data');
        UI.panel.behavior.previousTrial = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.505 0.22 0.24 0.19],'String',char(8592),'Callback',@previousTrial,'KeyPressFcn', @keyPress,'tooltip','Previous trial');
        UI.panel.behavior.nextTrial = uicontrol('Parent',UI.panel.behavior.main,'Style','pushbutton','Units','normalized','Position',[0.755 0.22 0.235 0.19],'String',char(8594),'Callback',@nextTrial,'KeyPressFcn', @keyPress,'tooltip','Next trial');
        UI.panel.behavior.trialNumber = uicontrol('Parent',UI.panel.behavior.main,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.01 0.01 0.485 0.20],'HorizontalAlignment','center','tooltip','Trial number','Callback',@gotoTrial);
        UI.panel.behavior.trialCount = uicontrol('Parent',UI.panel.behavior.main,'Style', 'Edit', 'String', 'nTrials', 'Units','normalized', 'Position', [0.505 0.01 0.485 0.20],'HorizontalAlignment','center','Enable','off');
        
        % Spectrogram
        UI.panel.spectrogram.main = uipanel('Parent',UI.panel.other.main,'title','Spectrogram');
        UI.panel.spectrogram.showSpectrogram = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'checkbox','String','Show spectrogram', 'value', 0, 'Units','normalized', 'Position', [0.01 0.80 0.99 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'text','String','Channel', 'Units','normalized', 'Position', [0.01 0.60 0.49 0.17],'HorizontalAlignment','left');
        UI.panel.spectrogram.spectrogramChannel = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'Edit', 'String', num2str(UI.settings.spectrogram.channel), 'Units','normalized', 'Position', [0.505 0.60 0.485 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','center');
        uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'text','String','Window width (sec)', 'Units','normalized', 'Position', [0.01 0.40 0.49 0.17],'HorizontalAlignment','left');
        UI.panel.spectrogram.spectrogramWindow = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'Edit', 'String', num2str(UI.settings.spectrogram.window), 'Units','normalized', 'Position', [0.505 0.40 0.485 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','center');
        
        uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'text','String','Low freq (Hz)', 'Units','normalized', 'Position', [0.01 0.20 0.32 0.14],'HorizontalAlignment','left');
        UI.panel.spectrogram.freq_low = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'Edit', 'String', num2str(UI.settings.spectrogram.freq_low), 'Units','normalized', 'Position', [0.01 0.01 0.32 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','center');
        
        uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'text','String','Step size (Hz)', 'Units','normalized', 'Position', [0.34 0.20 0.32 0.14],'HorizontalAlignment','center');
        UI.panel.spectrogram.freq_step_size = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'Edit', 'String', num2str(UI.settings.spectrogram.freq_step_size), 'Units','normalized', 'Position', [0.34 0.01 0.32 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','center');
        
        uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'text','String','High freq (Hz)', 'Units','normalized', 'Position', [0.67 0.20 0.32 0.14],'HorizontalAlignment','right');
        UI.panel.spectrogram.freq_high = uicontrol('Parent',UI.panel.spectrogram.main,'Style', 'Edit', 'String', num2str(UI.settings.spectrogram.freq_high), 'Units','normalized', 'Position', [0.67 0.01 0.32 0.19],'Callback',@toggleSpectrogram,'HorizontalAlignment','center');
        
        % Current Source Density
        UI.panel.csd.main = uipanel('Parent',UI.panel.other.main,'title','Current Source Density');
        UI.panel.csd.showCSD = uicontrol('Parent',UI.panel.csd.main,'Style', 'checkbox','String','Show Current Source Density', 'value', 0, 'Units','normalized', 'Position', [0.01 0.01 0.98 0.98],'Callback',@show_CSD,'HorizontalAlignment','left');
        
        % plotRMSnoiseInset
        UI.panel.RMSnoiseInset.main = uipanel('Parent',UI.panel.other.main,'title','RMS noise inset');
        UI.panel.RMSnoiseInset.showRMSnoiseInset = uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'checkbox','String','Show plot inset', 'value', 0, 'Units','normalized', 'Position', [0.01 0.67 0.48 0.30],'Callback',@toggleRMSnoiseInset,'HorizontalAlignment','left');
        UI.panel.RMSnoiseInset.filter = uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'popup','String',{'No filter','Ephys filter','Custom filter'}, 'value', UI.settings.plotRMSnoise_apply_filter, 'Units','normalized', 'Position', [0.50 0.67 0.49 0.30],'Callback',@toggleRMSnoiseInset,'HorizontalAlignment','left');
        uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'text', 'String', 'Lower filter (Hz)', 'Units','normalized', 'Position', [0.0 0.35 0.5 0.26],'HorizontalAlignment','center');
        uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'text', 'String', 'Higher filter (Hz)', 'Units','normalized', 'Position', [0.5 0.35 0.5 0.26],'HorizontalAlignment','center');
        UI.panel.RMSnoiseInset.lowerBand  = uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'Edit', 'String', num2str(UI.settings.plotRMSnoise_lowerBand), 'Units','normalized', 'Position', [0.01 0.01 0.48 0.36],'Callback',@toggleRMSnoiseInset,'HorizontalAlignment','center','tooltip','Lower frequency boundary (Hz)');
        UI.panel.RMSnoiseInset.higherBand = uicontrol('Parent',UI.panel.RMSnoiseInset.main,'Style', 'Edit', 'String', num2str(UI.settings.plotRMSnoise_higherBand), 'Units','normalized', 'Position', [0.5 0.01 0.49 0.36],'Callback',@toggleRMSnoiseInset,'HorizontalAlignment','center','tooltip','Higher frequency band (Hz)');
        
        % Defining flexible panel heights
        set(UI.panel.other.main, 'Heights', [200 110 95 140 95 50 90],'MinimumHeights',[220 120 100 150 150 50 90]);
        UI.panel.other.main1.MinimumWidths = 218;
        UI.panel.other.main1.MinimumHeights = 880;
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Lower info panel elements
        uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', '   Time (s)', 'Units','normalized', 'Position', [0.1 0 0.05 0.8],'HorizontalAlignment','center');
        UI.elements.lower.time = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', '', 'Units','normalized', 'Position', [0.15 0 0.05 1],'HorizontalAlignment','right','tooltip','Current timestamp (seconds)','Callback',@setTime);
        uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', '   Window duration (s)', 'Units','normalized', 'Position', [0.25 0 0.05 0.8],'HorizontalAlignment','center');
        UI.elements.lower.windowsSize = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', UI.settings.windowDuration, 'Units','normalized', 'Position', [0.3 0 0.05 1],'HorizontalAlignment','right','tooltip','Window size (seconds)','Callback',@setWindowsSize);
        UI.elements.lower.scalingText = uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', ' Scaling ', 'Units','normalized', 'Position', [0.0 0 0.05 0.8],'HorizontalAlignment','right');
        UI.elements.lower.scaling = uicontrol('Parent',UI.panel.info,'Style', 'Edit', 'String', num2str(UI.settings.scalingFactor), 'Units','normalized', 'Position', [0.05 0 0.05 1],'HorizontalAlignment','right','tooltip','Ephys scaling','Callback',@setScaling);
        UI.elements.lower.performance = uicontrol('Parent',UI.panel.info,'Style', 'text', 'String', 'Performance', 'Units','normalized', 'Position', [0.25 0 0.05 0.8],'HorizontalAlignment','center','KeyPressFcn', @keyPress);
        UI.elements.lower.slider = uicontrol(UI.panel.info,'Style','slider','Units','normalized','Position',[0.5 0 0.5 1],'Value',0, 'SliderStep', [0.0001, 0.1], 'Min', 0, 'Max', 100,'Callback',@moveSlider);
        addlistener(UI.elements.lower.slider, 'Value', 'PostSet',@movingSlider);
        set(UI.panel.info, 'Widths', [70 80 120 60 120 60 280 -1],'MinimumWidths',[70 80 120 60 60 60 250  1]); % set grid panel size
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating plot axes
        UI.plot_axis1 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0 0 1 1],'ButtonDownFcn',@ClickPlot,'Color',UI.settings.background,'XColor',UI.settings.primaryColor,'TickLength',[0.005, 0.001],'XMinorTick','on','XLim',[0,UI.settings.windowDuration],'YLim',[0,1],'YTickLabel',[],'Clipping','off');
        hold on
        UI.plot_axis1.XAxis.MinorTick = 'on';
        UI.plot_axis1.XAxis.MinorTickValues = 0:0.01:2;
        set(0,'units','pixels');
        ce_dragzoom(UI.plot_axis1,'on');
        UI.Pix_SS = get(0,'screensize');
        UI.Pix_SS = UI.Pix_SS(3)*2;
        
        setScalingText
    end

    function plotData
        % Generates all data plots
        
        % Deletes existing plot data
        delete(UI.plot_axis1.Children)
        set(UI.fig,'CurrentAxes',UI.plot_axis1)
        
        if UI.settings.resetZoomOnNavigation 
            resetZoom
        end
        
        UI.legend = {};
        
        % Ephys traces
        plot_ephys
        
        % KiloSort data
        if UI.settings.showKilosort
            plotKilosortData(UI.t0,UI.t0+UI.settings.windowDuration,'c')
        end
        
        % Klusta data
        if UI.settings.showKlusta
            plotKlustaData(UI.t0,UI.t0+UI.settings.windowDuration,'g')
        end
        
        % Spyking circus data
        if UI.settings.showSpykingcircus
            plotSpykingcircusData(UI.t0,UI.t0+UI.settings.windowDuration,'m')
        end
        
        % Spike data
        if UI.settings.showSpikes
            plotSpikeData(UI.t0,UI.t0+UI.settings.windowDuration,UI.settings.primaryColor,UI.plot_axis1)
        end
        
        % Spectrogram
        if UI.settings.spectrogram.show && ephys.loaded
            plotSpectrogram
        end
        
        % States data
        if UI.settings.showStates
            plotTemporalStates(UI.t0,UI.t0+UI.settings.windowDuration)
        end
        
        % Event data
        if UI.settings.showEvents
            plotEventData(UI.t0,UI.t0+UI.settings.windowDuration,UI.settings.primaryColor,'m')
        end
        
        % Time series
        if UI.settings.showTimeSeries
            plotTimeSeriesData(UI.t0,UI.t0+UI.settings.windowDuration,'m')
        end
        
        % Analog time series
        if UI.settings.intan_showAnalog
            plotAnalog('adc')
        end
        
        % Time series aux (analog)
        if UI.settings.intan_showAux
            plotAnalog('aux')
        end
        
        % Digital time series
        if UI.settings.intan_showDigital
            plotDigital('dig')
        end
        
        % Behavior
        if UI.settings.showBehavior
            plotBehavior(UI.t0,UI.t0+UI.settings.windowDuration,[0.5 0.5 0.5])
        end
        
        % Trials
        if UI.settings.showTrials
            plotTrials(UI.t0,UI.t0+UI.settings.windowDuration,UI.settings.primaryColor)
        end
        
        % Plotting RMS noise inset        
        if UI.settings.plotRMSnoiseInset && ~isempty(UI.channelOrder)
            plotRMSnoiseInset
        end
        
        % Showing detected spikes in a spike-waveform-PCA plot inset
        if UI.settings.detectSpikes && ~isempty(UI.channelOrder) && UI.settings.showDetectedSpikesPCAspace
            plotSpikesPCAspace(raster,UI.settings.primaryColor,true)
        end
        
        if ~isempty(UI.legend)
        	text(1/400,0.005,UI.legend,'FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground,'VerticalAlignment', 'bottom','Units','normalized','HorizontalAlignment','left','HitTest','off','Interpreter','tex')
        end
    end
    
    function text_center(message)
        text(UI.plot_axis1,0.5,0.5,message,'Color',UI.settings.primaryColor,'FontSize',14,'Units','normalized','FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground)
    end
    
    function addLegend(text_string,clr)
        % text_string: text string
        % clr: numeric color
        
        if nargin==1 % Considered a legend header 
            if ischar(UI.settings.primaryColor)
                str2rgb=@(x)get(line('color',x),'color');
                clr = str2rgb(UI.settings.primaryColor);
            else
                clr = UI.settings.primaryColor;
            end
            % Adding empty line above legend header
            if ~isempty(UI.legend)
                UI.legend = [UI.legend;' '];
            end
        end
        text_string = (['\color[rgb]{',num2strCommaSeparated(clr),'} ',text_string]);
        UI.legend = [UI.legend;text_string];
    end
    
    function plot_ephys
        % Loading and plotting ephys data
        % There are five plot styles, for optimized plotting performance
        % 1. Downsampled: Shows every 16th sample of the raw data (no filter or averaging)
        % 2. Range: Shows a sample count optimized for the screen resolution. For each sample the max and the min is plotted of data in the corresponding temporal range
        % 3. Raw: Raw data at full sampling rate
        % 4. LFP: .LFP file, typically the raw data has been downpass filtered and downsampled to 1250Hz before this. All samples are shown.
        % 5. Image: Raw data displayed with the imagesc function
        % Only data thas is not currently displayed will be loaded.
        
        if UI.settings.greyScaleTraces < 5
            colors = UI.colors/UI.settings.greyScaleTraces;
        elseif UI.settings.greyScaleTraces >=5
            colors = ones(size(UI.colors))/(UI.settings.greyScaleTraces-4);
            colors(1:2:end,:) = colors(1:2:end,:)-0.08*(9-UI.settings.greyScaleTraces);
        end
        
        % Setting booleans for validating ephys loading and plotting        
        ephys.loaded = false;
        ephys.plotted = false;
        if UI.settings.plotStyle == 4 % lfp file
            if UI.fid.lfp == -1
                UI.settings.stream = false;
                ephys.loaded = false;
                text_center('Failed to load LFP data')
                return
            end
            sr = data.session.extracellular.srLfp;
            ephys.sr = sr;
            fileID = UI.fid.lfp;
            
        else %  dat file
            if UI.fid.ephys == -1
                UI.settings.stream = false;
                ephys.loaded = false;
                text_center('Failed to load raw data')
                return
            end
            sr = data.session.extracellular.sr;
            ephys.sr = sr;
            fileID = UI.fid.ephys;
        end
        
        if strcmp(UI.settings.fileRead,'bof')
            % Loading data
            if UI.t0>UI.t1 && UI.t0 < UI.t1 + UI.settings.windowDuration && ~UI.forceNewData
                t_offset = UI.t0-UI.t1;
                newSamples = round(UI.samplesToDisplay*t_offset/UI.settings.windowDuration);
                existingSamples = UI.samplesToDisplay-newSamples;
                % Keeping existing samples
                ephys.raw(1:existingSamples,:) = ephys.raw(newSamples+1:UI.samplesToDisplay,:);
                % Loading new samples
                fseek(fileID,round((UI.t0+UI.settings.windowDuration-t_offset)*sr)*data.session.extracellular.nChannels*2,'bof'); % bof: beginning of file
                try
                    ephys.raw(existingSamples+1:UI.samplesToDisplay,:) = double(fread(fileID, [data.session.extracellular.nChannels, newSamples],UI.settings.precision))'*UI.settings.leastSignificantBit;
                    ephys.loaded = true;
                catch 
                    UI.settings.stream = false;
                    text_center('Failed to read file')
                end
            elseif UI.t0 < UI.t1 && UI.t0 > UI.t1 - UI.settings.windowDuration && ~UI.forceNewData
                t_offset = UI.t1-UI.t0;
                newSamples = round(UI.samplesToDisplay*t_offset/UI.settings.windowDuration);
                % Keeping existing samples
                existingSamples = UI.samplesToDisplay-newSamples;
                ephys.raw(newSamples+1:UI.samplesToDisplay,:) = ephys.raw(1:existingSamples,:);
                % Loading new data
                fseek(fileID,round(UI.t0*sr)*data.session.extracellular.nChannels*2,'bof');
                ephys.raw(1:newSamples,:) = double(fread(fileID, [data.session.extracellular.nChannels, newSamples],UI.settings.precision))'*UI.settings.leastSignificantBit;
                ephys.loaded = true;
            elseif UI.t0==UI.t1 && ~UI.forceNewData
                ephys.loaded = true;
            else
                fseek(fileID,round(UI.t0*sr)*data.session.extracellular.nChannels*2,'bof');
                ephys.raw = double(fread(fileID, [data.session.extracellular.nChannels, UI.samplesToDisplay],UI.settings.precision))'*UI.settings.leastSignificantBit;
                ephys.loaded = true;
            end
            UI.forceNewData = false;
        else
            fseek(fileID,ceil(-UI.settings.windowDuration*sr)*data.session.extracellular.nChannels*2,'eof'); % eof: end of file
            ephys.raw = double(fread(fileID, [data.session.extracellular.nChannels, UI.samplesToDisplay],UI.settings.precision))'*UI.settings.leastSignificantBit;
            UI.forceNewData = true;
            ephys.loaded = true;
        end
        
        UI.t1 = UI.t0;
        
        if ~ephys.loaded
            return
        end
        
        % Removing DC (substraction of the mean of each channel)
        if UI.settings.removeDC
            ephys.traces = ephys.raw-mean(ephys.raw);
        else
            ephys.traces = ephys.raw;
        end
        
        % Median filter (substraction of the median at each sample across channels)
        if UI.settings.medianFilter
            ephys.traces = ephys.traces-median(ephys.traces,2);
        end
        
        if UI.settings.filterTraces && UI.settings.plotStyle == 4
            if int_gt_0(UI.settings.filter.lowerBand,sr) && ~int_gt_0(UI.settings.filter.higherBand,sr)
                [b1, a1] = butter(3, UI.settings.filter.higherBand/sr*2, 'low');
            elseif int_gt_0(UI.settings.filter.higherBand,sr) && ~int_gt_0(UI.settings.filter.lowerBand,sr)
                [b1, a1] = butter(3, UI.settings.filter.lowerBand/sr*2, 'high');
            else
                [b1, a1] = butter(3, [UI.settings.filter.lowerBand,UI.settings.filter.higherBand]/sr*2, 'bandpass');
            end
            ephys.traces(:,UI.channelOrder) = filtfilt(b1, a1, ephys.traces(:,UI.channelOrder) * (UI.settings.scalingFactor)/1000000);
        elseif UI.settings.filterTraces
            ephys.traces(:,UI.channelOrder) = filtfilt(UI.settings.filter.b1, UI.settings.filter.a1, ephys.traces(:,UI.channelOrder) * (UI.settings.scalingFactor)/1000000);
        else
            ephys.traces(:,UI.channelOrder) = ephys.traces(:,UI.channelOrder) * (UI.settings.scalingFactor)/1000000;
        end
        
        if UI.settings.plotEnergy
            for i = UI.channelOrder
                ephys.traces(:,i) = 2*smooth(abs(ephys.traces(:,i)),round(UI.settings.energyWindow*sr),'moving');
            end
        end
        
        % CSD Background plot
        if UI.settings.CSD.show & numel(UI.channelOrder)>1
            plotCSD
        end
        
        if UI.settings.colorByChannels
            channelsList2 = [UI.channels{UI.settings.electrodeGroupsToPlot}];
            channelsList = {};
            temp = rem(0:numel(channelsList2)-1,UI.settings.nColorGroups)+1;
            for i = 1:max(temp)
                channelsList{i} = channelsList2(find(temp==i));
            end
            colors = eval([UI.settings.colormap,'(',num2str(numel(channelsList)),')']);
            electrodeGroupsToPlot = 1:max(temp);
            
            if UI.settings.greyScaleTraces < 5
                colors = colors/UI.settings.greyScaleTraces;
            elseif UI.settings.greyScaleTraces >=5
                colors = ones(size(colors))/(UI.settings.greyScaleTraces-4);
                colors(1:2:end,:) = colors(1:2:end,:)-0.08*(9-UI.settings.greyScaleTraces);
            end
            colorsList = colors;
        else
            electrodeGroupsToPlot = UI.settings.electrodeGroupsToPlot;
            channelsList = UI.channels;
            colorsList = colors;
        end
        
        if UI.settings.plotStyle == 1 
            % Low sampled values (Faster plotting)
            for iShanks = electrodeGroupsToPlot
                channels = channelsList{iShanks};
                if ~isempty(channels)
                    [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
                    line(UI.plot_axis1,[1:UI.nDispSamples]/UI.nDispSamples*UI.settings.windowDuration,ephys.traces(UI.dispSamples,channels)-UI.channelOffset(channels),'color',colorsList(iShanks,:), 'HitTest','off');
                end
            end
        elseif UI.settings.plotStyle == 2 && (size(ephys.traces,1) > UI.settings.plotStyleDynamicThreshold || ~UI.settings.plotStyleDynamicRange) % Range values per sample (ala Neuroscope1)
            % Range data (low sampled values with min and max per interval)
            excess_samples = rem(size(ephys.traces,1),ceil(UI.settings.plotStyleRangeSamples*UI.settings.windowDuration));
            ephys_traces3 = ephys.traces(1:end-excess_samples,:);
            ephys_traces2 = reshape(ephys_traces3,ceil(UI.settings.plotStyleRangeSamples*UI.settings.windowDuration),[]);
            ephys.traces_min = reshape(min(ephys_traces2),[],size(ephys.traces,2));
            ephys.traces_max = reshape(max(ephys_traces2),[],size(ephys.traces,2));
            for iShanks = electrodeGroupsToPlot
                tist = [];
                timeLine = [];
                channels = channelsList{iShanks};
                [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
                tist(1,:,:) = ephys.traces_min(:,channels)-UI.channelOffset(channels);
                tist(2,:,:) = ephys.traces_max(:,channels)-UI.channelOffset(channels);
                tist(:,end+1,:) = nan;
                timeLine1 = repmat([1:size(ephys.traces_min,1)]/size(ephys.traces_min,1)*UI.settings.windowDuration,numel(channels),1)';
                timeLine(1,:,:) = timeLine1;
                timeLine(2,:,:) = timeLine1;
                timeLine(:,end+1,:) = timeLine(:,end,:);
                line(UI.plot_axis1,timeLine(:)',tist(:)','color',colorsList(iShanks,:)','LineStyle','-', 'HitTest','off');
            end
        elseif UI.settings.plotStyle == 5
            % Image representation
            UI.dataRange.ephys
            timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
            multiplier = [size(ephys.traces,1)-1:-1:0]/(size(ephys.traces,1)-1)*diff(UI.dataRange.ephys)+UI.dataRange.ephys(1);
            imagesc(UI.plot_axis1,timeLine,multiplier,ephys.traces(:,UI.channelOrder)', 'HitTest','off')
        elseif UI.settings.plotStyle == 6
            % No traces
            
        else % UI.settings.plotStyle == [3,4]
            % Raw data
            timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
            for iShanks = electrodeGroupsToPlot
                channels = channelsList{iShanks};
                if ~isempty(channels)
                    line(UI.plot_axis1,timeLine,ephys.traces(:,channels)-UI.channelOffset(channels),'color',colorsList(iShanks,:),'LineStyle','-', 'HitTest','off');
                end
            end
        end
        
        if ~isempty(UI.settings.channelTags.highlight)
            for i = 1:numel(UI.settings.channelTags.highlight)
                channels = data.session.channelTags.(UI.channelTags{UI.settings.channelTags.highlight(i)}).channels;
                if ~isempty(channels)
                    channels = UI.channelMap(channels); channels(channels==0) = [];
                    if ~isempty(channels) && any(ismember(channels,UI.channelOrder))
                        highlightTraces(channels,UI.colors_tags(UI.settings.channelTags.highlight(i),:));
                    end
                end
            end
        end
        
        % Detecting and plotting spikes
        if UI.settings.detectSpikes && ~isempty(UI.channelOrder)
            [UI.settings.filter.b2, UI.settings.filter.a2] = butter(3, 500/(ephys.sr/2), 'high');
            if UI.settings.removeDC
                ephys.filt = ephys.raw-mean(ephys.raw);
            else
                ephys.filt = ephys.raw;
            end
            ephys.filt(:,UI.channelOrder) = filtfilt(UI.settings.filter.b2, UI.settings.filter.a2, ephys.filt(:,UI.channelOrder));
            
            raster = [];
            raster.idx = [];
            raster.x = [];
            raster.y = [];
            raster.channel = [];
            
            for i = 1:numel(UI.channelOrder)
                idx = find(diff(ephys.filt(:,UI.channelOrder(i)) < UI.settings.spikesDetectionThreshold)==1)+1;
                if ~isempty(idx)
                    raster.idx = [raster.idx;idx];
                    raster.x = [raster.x;idx/ephys.sr];
                    raster.channel = [raster.channel;UI.channelOrder(i)*ones(size(idx))];
                    if UI.settings.detectedSpikesBelowTrace
                        raster_y = diff(UI.dataRange.detectedSpikes)*(-UI.channelScaling(idx,UI.channelOrder(i)))+UI.dataRange.detectedSpikes(1)+0.004;
                        raster.y = [raster.y;raster_y];
                    elseif any(UI.settings.plotStyle == [5,6])
                        raster.y = [raster.y;-UI.channelScaling(idx,UI.channelOrder(i))];    
                    else
                        raster.y = [raster.y;ephys.traces(idx,UI.channelOrder(i))-UI.channelScaling(idx,UI.channelOrder(i))];
                    end
                end
            end
            
            % Removing artifacts (spike events detected on more than a quater the channels within 1 ms bins (min 20 channels))
            [~,idxu,idxc] = unique(raster.idx); % Unique values
            [count, ~, idxcount] = histcounts(raster.x*1000,[0:UI.settings.windowDuration*1000]); % count unique values
            idx2remove = count(idxcount)>max([20,numel(UI.channelOrder)/4]); % Finding timepoints to remove
            raster.idx(idx2remove) = [];
            raster.x(idx2remove) = [];
            raster.y(idx2remove) = []; 
            raster.channel(idx2remove) = [];
            
            % Showing waveforms of detected spikes
            if UI.settings.showDetectedSpikeWaveforms
                if UI.settings.colorDetectedSpikesByWidth
                    raster = plotSpikeWaveforms(raster,UI.settings.primaryColor,5);
                else
                    plotSpikeWaveforms(raster,UI.settings.primaryColor,2);
                end
            end
            
            if UI.settings.showSpikes && ~UI.settings.detectedSpikesBelowTrace
                markerType = 'o';
            else
                markerType = UI.settings.rasterMarker;
            end
            
            % Plotting spike rasters
            if UI.settings.showDetectedSpikeWaveforms && UI.settings.colorDetectedSpikesByWidth
                raster.spike_identity;
                unique_electrodeGroups = unique(raster.spike_identity);
                spike_identity_colormap = [0.2 0.2 1; 1 0.2 0.2];
                for i = 1:numel(unique_electrodeGroups)
                    idx_uids = raster.spike_identity == i;
                    line(UI.plot_axis1,raster.x(idx_uids), raster.y(idx_uids),'Marker',markerType,'LineStyle','none','color',spike_identity_colormap(unique_electrodeGroups(i),:), 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
                end
            else
                line(UI.plot_axis1,raster.x, raster.y,'Marker',markerType,'LineStyle','none','color',UI.settings.primaryColor, 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
            end
            
        end
        
        % Detecting and plotting events
        if UI.settings.detectEvents && ~isempty(UI.channelOrder)
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
                    
                    if UI.settings.detectedEventsBelowTrace
                        raster_y = diff(UI.dataRange.detectedEvents)*(-UI.channelScaling(idx,i))+UI.dataRange.detectedEvents(1)+0.004;
                        raster.y = [raster.y;raster_y];
                    elseif any(UI.settings.plotStyle == [5,6])
                        raster.y = [raster.y;-UI.channelScaling(idx,UI.channelOrder(i))];    
                    else
                        raster.y = [raster.y;ephys.traces(idx,i)-UI.channelScaling(idx,i)];
                    end
                end
            end
            [~,ia] = sort(UI.channelOrder);
            ia = -0.9*((ia-1)/(numel(UI.channelOrder)-1))-0.05+1;
            ia2 = 1:data.session.extracellular.nChannels;
            isx = find(ismember(ia2,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
            ia2(isx) = ia;
            
            line(UI.plot_axis1,raster.x/size(ephys.traces,1)*UI.settings.windowDuration, raster.y,'Marker',UI.settings.rasterMarker,'LineStyle','none','color','m', 'HitTest','off');
        end
        
        % Plotting channel numbers
        if UI.settings.showChannelNumbers
            if UI.settings.plotStyle < 5
                text(UI.plot_axis1,zeros(1,numel(UI.channelOrder)),ephys.traces(1,UI.channelOrder)-UI.channelOffset(UI.channelOrder),strcat(cellstr(num2str(UI.channelOrder')),{' '}),'color',UI.settings.primaryColor,'VerticalAlignment', 'middle','HorizontalAlignment','right','HitTest','off')
            else
                text(UI.plot_axis1,zeros(1,numel(UI.channelOrder)),-UI.channelOffset(UI.channelOrder),strcat(cellstr(num2str(UI.channelOrder')),{' '}),'color',UI.settings.primaryColor,'VerticalAlignment', 'middle','HorizontalAlignment','right','HitTest','off')
            end
        end
        
        % Plotting scale bar
        if UI.settings.showScalebar
            plot(UI.plot_axis1,[0.005,0.005],[0.93,0.98],'-','linewidth',3,'color',UI.settings.primaryColor)
            text(UI.plot_axis1,0.005,0.955,['  ',num2str(0.05/(UI.settings.scalingFactor)*1000,3),' mV'],'FontWeight', 'Bold','VerticalAlignment', 'middle','HorizontalAlignment','left','color',UI.settings.primaryColor)
        end
        ephys.plotted = true;
    end

    function plotAnalog(signal)
        sr = data.session.timeSeries.(signal).sr;
        precision = data.session.timeSeries.(signal).precision;
        nDispSamples = UI.settings.windowDuration*sr;
        % Plotting analog traces
        if strcmp(UI.settings.fileRead,'bof')
            fseek(UI.fid.timeSeries.(signal),round(UI.t0*sr)*data.session.timeSeries.(signal).nChannels*2,'bof'); % eof: end of file
        else 
            fseek(UI.fid.timeSeries.(signal),ceil(-UI.settings.windowDuration*sr)*data.session.timeSeries.(signal).nChannels*2,'eof'); % eof: end of file
        end
        traces_analog = fread(UI.fid.timeSeries.(signal), [data.session.timeSeries.(signal).nChannels, nDispSamples],precision)';
        if UI.settings.showTimeseriesBelowTrace
            line(UI.plot_axis1,(1:nDispSamples)/sr,traces_analog./2^16*diff(UI.dataRange.intan)+UI.dataRange.intan(1), 'HitTest','off','Marker','none','LineStyle','-','linewidth',1);
        else
            line(UI.plot_axis1,(1:nDispSamples)/sr,traces_analog./2^16, 'HitTest','off','Marker','none','LineStyle','-','linewidth',1.5);
        end
        addLegend(['Analog timeseries: ' signal])
        for i = 1:data.session.timeSeries.(signal).nChannels
            addLegend(strrep(UI.settings.traceLabels.(signal){i}, '_', ' '),UI.colorLine(i,:));
        end
    end

    function plotDigital(signal)
        sr = data.session.timeSeries.(signal).sr;
        precision = data.session.timeSeries.(signal).precision;
        nDispSamples = UI.settings.windowDuration*sr;
        
        % Plotting digital traces
        if strcmp(UI.settings.fileRead,'bof')
            fseek(UI.fid.timeSeries.(signal),round(UI.t0*sr)*2,'bof');
        else
            fseek(UI.fid.timeSeries.(signal),ceil(-UI.settings.windowDuration*sr)*2,'eof');
        end
        traces_digital = fread(UI.fid.timeSeries.(signal), nDispSamples,precision)';
        traces_digital2 = [];
        for i = 1:data.session.timeSeries.(signal).nChannels
            traces_digital2(:,i) = bitget(traces_digital,i)+i*0.001;
        end
        if UI.settings.showTimeseriesBelowTrace
            line(UI.plot_axis1,(1:nDispSamples)/sr,0.98*traces_digital2*diff(UI.dataRange.intan)+UI.dataRange.intan(1)+0.004, 'HitTest','off','Marker','none','LineStyle','-');
        else
            line(UI.plot_axis1,(1:nDispSamples)/sr,0.98*traces_digital2+0.005, 'HitTest','off','Marker','none','LineStyle','-');
        end
        addLegend(['Digital timeseries: ' signal])
        for i = 1:data.session.timeSeries.(signal).nChannels
            addLegend(UI.settings.traceLabels.(signal){i},UI.colorLine(i,:)*0.8);
        end
    end

    function highlightTraces(channels,colorIn)
        % Highlight ephys channel(s)
        if ~isempty(colorIn)
            colorLine = colorIn;
        else
            UI.iLine = mod(UI.iLine,7)+1;
            colorLine = UI.colorLine(UI.iLine,:);
        end
        
        if ~isempty(UI.channelOrder)
            if UI.settings.plotStyle == 1
                line(UI.plot_axis1,[1:UI.nDispSamples]/UI.nDispSamples*UI.settings.windowDuration,ephys.traces(UI.dispSamples,channels)-UI.channelOffset(channels), 'HitTest','off','linewidth',1.2,'color',colorLine);
            elseif UI.settings.plotStyle == 2 && (size(ephys.traces,1) > UI.settings.plotStyleDynamicThreshold || ~UI.settings.plotStyleDynamicRange)
                tist = [];
                timeLine = [];
                tist(1,:,:) = ephys.traces_min(:,channels)-UI.channelOffset(channels);
                tist(2,:,:) = ephys.traces_max(:,channels)-UI.channelOffset(channels);
                tist(:,end+1,:) = nan;
                timeLine1 = repmat([1:size(ephys.traces_min,1)]/size(ephys.traces_min,1)*UI.settings.windowDuration,numel(channels),1)';
                timeLine(1,:,:) = timeLine1;
                timeLine(2,:,:) = timeLine1;
                timeLine(:,end+1,:) = timeLine(:,end,:);
                line(UI.plot_axis1,timeLine(:)',tist(:)','LineStyle','-', 'HitTest','off','linewidth',1.2,'color',colorLine);
            else
                timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
                line(UI.plot_axis1,timeLine,ephys.traces(:,channels)-UI.channelOffset(channels),'LineStyle','-', 'HitTest','off','linewidth',1.2,'color',colorLine);
            end
        end
    end

    function plotBehavior(t1,t2,colorIn)
        % Plots behavior
        idx = find((data.behavior.(UI.settings.behaviorData).timestamps > t1 & data.behavior.(UI.settings.behaviorData).timestamps < t2));
        if ~isempty(idx)
            % PLots behavior data on top of the ephys
            if UI.settings.plotBehaviorLinearized
                if UI.settings.showBehaviorBelowTrace
                    line(data.behavior.(UI.settings.behaviorData).timestamps(idx)-t1,data.behavior.(UI.settings.behaviorData).position.linearized(idx)/data.behavior.(UI.settings.behaviorData).limits.linearized(2)*diff(UI.dataRange.behavior)+UI.dataRange.behavior(1), 'Color', colorIn, 'HitTest','off','Marker','.','LineStyle','-','linewidth',2)
                else
                    line(data.behavior.(UI.settings.behaviorData).timestamps(idx)-t1,data.behavior.(UI.settings.behaviorData).position.linearized(idx)/data.behavior.(UI.settings.behaviorData).limits.linearized(2), 'Color', colorIn, 'HitTest','off','Marker','.','LineStyle','-','linewidth',2)
                end
            else
                % Shows behavior data in a small inset plot in the lower right corner
                p1 = patch([5*(t2-t1)/6,(t2-t1),(t2-t1),5*(t2-t1)/6]-0.01,[0 0 0.25 0.25]+0.01+UI.ephys_offset,'k','HitTest','off','EdgeColor',[0.5 0.5 0.5]);
                alpha(p1,0.4);
                line((data.behavior.(UI.settings.behaviorData).position.x(idx)-data.behavior.(UI.settings.behaviorData).limits.x(1))/diff(data.behavior.(UI.settings.behaviorData).limits.x)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).position.y(idx)-data.behavior.(UI.settings.behaviorData).limits.y(1))/diff(data.behavior.(UI.settings.behaviorData).limits.y)*0.25+0.01+UI.ephys_offset, 'Color', colorIn, 'HitTest','off','Marker','none','LineStyle','-','linewidth',2)
                idx2 = [idx(1),idx(round(end/4)),idx(round(end/2)),idx(round(3*end/4))];
                line((data.behavior.(UI.settings.behaviorData).position.x(idx2)-data.behavior.(UI.settings.behaviorData).limits.x(1))/diff(data.behavior.(UI.settings.behaviorData).limits.x)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).position.y(idx2)-data.behavior.(UI.settings.behaviorData).limits.y(1))/diff(data.behavior.(UI.settings.behaviorData).limits.y)*0.25+0.01+UI.ephys_offset, 'Color', [0.9,0.5,0.9], 'HitTest','off','Marker','o','LineStyle','none','linewidth',0.5,'MarkerFaceColor',[0.9,0.5,0.9],'MarkerEdgeColor',[0.9,0.5,0.9]);
                line((data.behavior.(UI.settings.behaviorData).position.x(idx(end))-data.behavior.(UI.settings.behaviorData).limits.x(1))/diff(data.behavior.(UI.settings.behaviorData).limits.x)*(t2-t1)/6+5*(t2-t1)/6-0.01,(data.behavior.(UI.settings.behaviorData).position.y(idx(end))-data.behavior.(UI.settings.behaviorData).limits.y(1))/diff(data.behavior.(UI.settings.behaviorData).limits.y)*0.25+0.01+UI.ephys_offset, 'Color', [1,0.7,1], 'HitTest','off','Marker','s','LineStyle','none','linewidth',0.5,'MarkerFaceColor',[1,0.7,1],'MarkerEdgeColor',[1,0.7,1]);
                
                % Showing spikes in the 2D behavior plot
                if UI.settings.showSpikes && ~isempty(spikes_raster)
                    if UI.settings.spikesGroupColors == 4
                        % UI.params.sortingMetric = 'putativeCellType';
                        putativeCellTypes = unique(data.cell_metrics.(UI.params.groupMetric));
%                         UI.colors_metrics = hsv(numel(putativeCellTypes));
                        UI.colors_metrics = eval([UI.settings.spikesColormap,'(',num2str(numel(putativeCellTypes)),')']);
                        k = 1;
                        for i = 1:numel(putativeCellTypes)
                            idx2 = find(ismember(data.cell_metrics.(UI.params.groupMetric),putativeCellTypes{i}));
                            idx3 = ismember(spikes_raster.UID,idx2);
                            if any(idx3)
                                plotBehaviorEvents(spikes_raster.x(idx3)+t1,UI.colors_metrics(i,:),'o');
                                k = k+1;
                            end
                        end
                    elseif UI.settings.spikesGroupColors == 1
%                         uid = data.spikes.spindices(spikes_raster.spin_idx,2);
                        unique_uids = unique(spikes_raster.UID);
                        uid_colormap = eval([UI.settings.spikesColormap,'(',num2str(numel(unique_uids)),')']);
                        for i = 1:numel(unique_uids)
                            idx_uids = spikes_raster.UID == unique_uids(i);
                            plotBehaviorEvents(spikes_raster.x(idx_uids)+t1,uid_colormap(i,:),'o')
                        end
                    elseif UI.settings.spikesGroupColors == 3
                        unique_electrodeGroups = unique(spikes_raster.electrodeGroup)';
                        electrodeGroup_colormap = UI.colors;
                        for i = unique_electrodeGroups
                            idx_uids = spikes_raster.electrodeGroup' == i;
                            plotBehaviorEvents(spikes_raster.x(idx_uids)+t1,electrodeGroup_colormap(i,:),'o')
                        end
                    else
                        plotBehaviorEvents(spikes_raster.x+t1,UI.settings.primaryColor,'o')
                    end
                end
                
                % Showing events in the 2D behavior plot
                if UI.settings.showEvents
                    idx = find(data.events.(UI.settings.eventData).time >= t1 & data.events.(UI.settings.eventData).time <= t2);
                    % Plotting flagged events in a different color
                    if isfield(data.events.(UI.settings.eventData),'flagged')
                        idx2 = ismember(idx,data.events.(UI.settings.eventData).flagged);
                        if any(idx2)
                            plotBehaviorEvents(data.events.(UI.settings.eventData).time(idx(idx2)),'m','s')
                        end
                        idx(idx2) = [];
                    end
                    % Plotting events
                    if any(idx)
                        plotBehaviorEvents(data.events.(UI.settings.eventData).time(idx),colorIn,'s')
                    end
                    
                    % Plotting added events
                    if isfield(data.events.(UI.settings.eventData),'added') && ~isempty(isfield(data.events.(UI.settings.eventData),'added'))
                        idx3 = find(data.events.(UI.settings.eventData).added >= t1 & data.events.(UI.settings.eventData).added <= t2);
                        if any(idx3)
                            plotBehaviorEvents(data.events.(UI.settings.eventData).added(idx3),'c','s')
                        end
                    end
                end
            end
        end
        
        function plotBehaviorEvents(timestamps,markerColor,markerStyle)
            pos_x = interp1(data.behavior.(UI.settings.behaviorData).timestamps,data.behavior.(UI.settings.behaviorData).position.x,timestamps);
            pos_y = interp1(data.behavior.(UI.settings.behaviorData).timestamps,data.behavior.(UI.settings.behaviorData).position.y,timestamps);
            line((pos_x-data.behavior.(UI.settings.behaviorData).limits.x(1))/diff(data.behavior.(UI.settings.behaviorData).limits.x)*(t2-t1)/6+5*(t2-t1)/6-0.01,(pos_y-data.behavior.(UI.settings.behaviorData).limits.y(1))/diff(data.behavior.(UI.settings.behaviorData).limits.y)*0.25+0.01+UI.ephys_offset, 'Color', [markerColor,0.5],'Marker',markerStyle,'LineStyle','none','linewidth',1,'MarkerFaceColor',markerColor,'MarkerEdgeColor',markerColor, 'HitTest','off');
        end
    end

    function plotSpikeData(t1,t2,colorIn,axesIn)
        % Plots spikes
        
        % Determining which units to plot from various filters
        units2plot = [find(ismember(data.spikes.maxWaveformCh1,[UI.channels{UI.settings.electrodeGroupsToPlot}])),UI.params.subsetTable,UI.params.subsetCellType,UI.params.subsetFilter,UI.params.subsetGroups];
        units2plot = find(histcounts(units2plot,1:data.spikes.numcells+1)==5);
        
        % Finding the spikes in the spindices to plot by index
        spin_idx = find(data.spikes.spindices(:,1) > t1 & data.spikes.spindices(:,1) < t2);
        spin_idx = spin_idx(ismember(data.spikes.spindices(spin_idx,2),units2plot));
        
        spikes_raster = [];
        if any(spin_idx)
            spikes_raster.x = data.spikes.spindices(spin_idx,1)-t1;
            spikes_raster.idx = round(spikes_raster.x*ephys.sr);
            spikes_raster.UID = data.spikes.spindices(spin_idx,2);
            if isfield(data.spikes,'shankID')
                spikes_raster.electrodeGroup = data.spikes.shankID(spikes_raster.UID)';
            end
            spikes_raster.channel = data.spikes.maxWaveformCh1(data.spikes.spindices(spin_idx,2))';
            
            if UI.settings.spikesBelowTrace
                idx2 = round(spikes_raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
                if UI.settings.useSpikesYData
                    spikes_raster.y = (diff(UI.dataRange.spikes))*((data.spikes.spindices(spin_idx,3)-UI.settings.spikes_ylim(1))/diff(UI.settings.spikes_ylim))+UI.dataRange.spikes(1)+0.004;
                else
                    if UI.settings.useMetrics
                        [~,sortIdx] = sort(data.cell_metrics.(UI.params.sortingMetric));
                        [~,sortIdx] = sort(sortIdx);
                    else
                        sortIdx = 1:data.spikes.numcells;
                    end
                    spikes_raster.y = (diff(UI.dataRange.spikes))*(sortIdx(data.spikes.spindices(spin_idx,2))/(data.spikes.numcells))+UI.dataRange.spikes(1)+0.004;
                end
            else
                % Aligning timestamps and determining trace value for each spike
                if UI.settings.plotStyle == 1
                    idx2 = round(spikes_raster.x*UI.nDispSamples/UI.settings.windowDuration);
                    idx2(idx2==0)= 1; % realigning spikes events outside a low sampled trace
                    traces = ephys.traces(UI.dispSamples,:)-UI.channelOffset(:);
                    idx3 = sub2ind(size(traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(spin_idx,2))');
                    spikes_raster.y = traces(idx3);
                
                elseif UI.settings.plotStyle == 2 && (size(ephys.traces,1) > UI.settings.plotStyleDynamicThreshold || ~UI.settings.plotStyleDynamicRange)
                    idx2 = round(spikes_raster.x*size(ephys.traces_min,1)/UI.settings.windowDuration);
                    idx2(idx2==0)= 1; % realigning spikes events outside a low sampled trace
                    traces = ephys.traces_min-UI.channelOffset;
                    idx3 = sub2ind(size(traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(spin_idx,2))');
                    spikes_raster.y = traces(idx3);
                elseif any(UI.settings.plotStyle == [5,6])
                    idx2 = round(spikes_raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
                    idx2(idx2==0)= 1; % realigning spikes events outside a low sampled trace
                    idx3 = sub2ind(size(ephys.traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(spin_idx,2))');
                    spikes_raster.y = -UI.channelScaling(idx3);
                else
                    idx2 = round(spikes_raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
                    idx2(idx2==0)= 1; % realigning spikes events outside a low sampled trace
                    idx3 = sub2ind(size(ephys.traces),idx2,data.spikes.maxWaveformCh1(data.spikes.spindices(spin_idx,2))');
                    spikes_raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
                end
            end
            if UI.settings.spikesGroupColors == 4
                putativeCellTypes = unique(data.cell_metrics.(UI.params.groupMetric));
                UI.colors_metrics = eval([UI.settings.spikesColormap,'(',num2str(numel(putativeCellTypes)),')']);

                addLegend(['Cell metrics: ' UI.params.groupMetric])
                for i = 1:numel(putativeCellTypes)
                    idx2 = find(ismember(data.cell_metrics.(UI.params.groupMetric),putativeCellTypes{i}));
                    idx3 = ismember(data.spikes.spindices(spin_idx,2),idx2);
                    if any(idx3)
                        line(axesIn,spikes_raster.x(idx3), spikes_raster.y(idx3),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',UI.colors_metrics(i,:), 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
                        addLegend(putativeCellTypes{i},UI.colors_metrics(i,:)*0.8);
                    end
                end

            elseif UI.settings.spikesGroupColors == 1
                uid = data.spikes.spindices(spin_idx,2);
                unique_uids = unique(uid);
                uid_colormap = eval([UI.settings.spikesColormap,'(',num2str(numel(unique_uids)),')']);
                for i = 1:numel(unique_uids)
                    idx_uids = uid == unique_uids(i);
                    line(axesIn,spikes_raster.x(idx_uids), spikes_raster.y(idx_uids),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',uid_colormap(i,:), 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
                end
            elseif UI.settings.spikesGroupColors == 3
                unique_electrodeGroups = unique(spikes_raster.electrodeGroup);
                electrodeGroup_colormap = UI.colors;
                for i = 1:numel(unique_electrodeGroups)
                    idx_uids = spikes_raster.electrodeGroup == unique_electrodeGroups(i);
                    line(axesIn,spikes_raster.x(idx_uids), spikes_raster.y(idx_uids),'Marker',UI.settings.rasterMarker,'LineStyle','none','color',electrodeGroup_colormap(unique_electrodeGroups(i),:), 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
                end
            else
                line(axesIn,spikes_raster.x, spikes_raster.y,'Marker',UI.settings.rasterMarker,'LineStyle','none','color',colorIn, 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
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
            
            % Population rate
            if UI.settings.showPopulationRate
                if ~UI.settings.populationRateBelowTrace
                    UI.dataRange.populationRate(2) = 0.5;
                end
                populationBins = 0:UI.settings.populationRateWindow:t2-t1;
                if UI.settings.spikesGroupColors == 4
                    putativeCellTypes = unique(data.cell_metrics.(UI.params.groupMetric));
                    UI.colors_metrics = eval([UI.settings.spikesColormap,'(',num2str(numel(putativeCellTypes)),')']);
                    
                    for i = 1:numel(putativeCellTypes)
                        idx2 = find(ismember(data.cell_metrics.(UI.params.groupMetric),putativeCellTypes{i}));
                        idx3 = ismember(data.spikes.spindices(spin_idx,2),idx2);
                        
                        if any(idx3)
                            populationRate = histcounts(spikes_raster.x(idx3),populationBins)/UI.settings.populationRateWindow/2;
                            if UI.settings.populationRateSmoothing == 1
                                populationRate = [populationRate;populationRate];
                                populationRate = populationRate(:);
                                populationBins = [populationBins(1:end-1);populationBins(2:end)];
                                populationBins = populationBins(:);
                            else
                                populationBins = populationBins(1:end-1)+UI.settings.populationRateWindow/2;
                                % populationRate = smooth(populationRate,UI.settings.populationRateSmoothing);
                                populationRate = conv(populationRate,ce_gausswin(UI.settings.populationRateSmoothing)'/sum(ce_gausswin(UI.settings.populationRateSmoothing)),'same');
                            end
                            populationRate = (populationRate/max(populationRate))*diff(UI.dataRange.populationRate)+UI.dataRange.populationRate(1)+0.001;
                            line(populationBins, populationRate,'Marker','none','LineStyle','-','color',UI.colors_metrics(i,:), 'HitTest','off','linewidth',1.5);
                        end
                    end
                elseif UI.settings.spikesGroupColors == 3
                    unique_electrodeGroups = unique(spikes_raster.electrodeGroup);
                    electrodeGroup_colormap = UI.colors;
                    for i = 1:numel(unique_electrodeGroups)
                        idx3 = spikes_raster.electrodeGroup==unique_electrodeGroups(i);                        
                        if any(idx3)
                            populationRate = histcounts(spikes_raster.x(idx3),populationBins)/UI.settings.populationRateWindow/2;
                            if UI.settings.populationRateSmoothing == 1
                                populationRate = [populationRate;populationRate];
                                populationRate = populationRate(:);
                                populationBins = [populationBins(1:end-1);populationBins(2:end)];
                                populationBins = populationBins(:);
                            else
                                populationBins = populationBins(1:end-1)+UI.settings.populationRateWindow/2;
                                % populationRate = smooth(populationRate,UI.settings.populationRateSmoothing);
                                populationRate = conv(populationRate,ce_gausswin(UI.settings.populationRateSmoothing)'/sum(ce_gausswin(UI.settings.populationRateSmoothing)),'same');
                            end
                            populationRate = (populationRate/max(populationRate))*diff(UI.dataRange.populationRate)+UI.dataRange.populationRate(1)+0.001;
                            line(populationBins, populationRate,'Marker','none','LineStyle','-','color',electrodeGroup_colormap(unique_electrodeGroups(i),:), 'HitTest','off','linewidth',1.5);
                        end
                    end
                    
                else
                    populationRate = histcounts(spikes_raster.x,populationBins)/UI.settings.populationRateWindow;
                    if UI.settings.populationRateSmoothing == 1
                        populationRate = [populationRate;populationRate];
                        populationRate = populationRate(:);
                        populationBins = [populationBins(1:end-1);populationBins(2:end)];
                        populationBins = populationBins(:);
                    else
                        populationBins = populationBins(1:end-1)+UI.settings.populationRateWindow/2;
                        % populationRate = smooth(populationRate,UI.settings.populationRateSmoothing);
                        populationRate = conv(populationRate,gausswin(UI.settings.populationRateSmoothing)'/sum(gausswin(UI.settings.populationRateSmoothing)),'same');
                    end
                    populationRate = (populationRate/max(populationRate))*diff(UI.dataRange.populationRate)+UI.dataRange.populationRate(1)+0.001;
                    line(populationBins, populationRate,'Marker','none','LineStyle','-','color',UI.settings.primaryColor, 'HitTest','off','linewidth',1.5);
                end
            end
            if UI.settings.showSpikeWaveforms
                plotSpikeWaveforms(spikes_raster,UI.settings.primaryColor,UI.settings.spikesGroupColors);
            end
            
            % Showing detected spikes in a spike-waveform-PCA plot inset
            if UI.settings.showSpikesPCAspace
                if ~UI.settings.showDetectedSpikesPCAspace
                    drawBackground = true;
                else
                    drawBackground = false;
                end                    
                plotSpikesPCAspace(spikes_raster,[0.5 0.5 1],drawBackground)
            end
            
            if UI.settings.showSpikeMatrix
                plotSpikeMatrix
            end
        end
    end

    function plotSpikeMatrix
        t1 = UI.t0;
        t2 = UI.t0+UI.settings.windowDuration;
        idx = ismember(data.spikes.spindices(:,2),UI.params.subsetTable ) & ismember(data.spikes.spindices(:,2),UI.params.subsetCellType) & ismember(data.spikes.spindices(:,2),UI.params.subsetFilter) & ismember(data.spikes.spindices(:,2),UI.params.subsetGroups)  & data.spikes.spindices(:,1) > t1 & data.spikes.spindices(:,1) < t2;
        if any(idx)
            abc = histcounts(data.spikes.spindices(idx,2),1:data.spikes.numcells+1);
            plotRows = numSubplots(data.spikes.numcells);
            cell_spikematrix = zeros(1,plotRows(1)*plotRows(2));
            cell_spikematrix(1:data.spikes.numcells) = abc;
            cell_spikematrix = fliplr(reshape(cell_spikematrix,plotRows(2),plotRows(1)))';
            
            p1 = patch(UI.plot_axis1,[(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration,UI.settings.windowDuration,UI.settings.windowDuration,(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration]-0.005,[(1-UI.settings.insetRelativeHeight) (1-UI.settings.insetRelativeHeight) 1 1]-0.015,'k','HitTest','off','EdgeColor',[0.5 0.5 0.5]);
            alpha(p1,0.6);
                
            h = imagesc(UI.plot_axis1,[0.5:plotRows(2)]/plotRows(2)*UI.settings.insetRelativeWidth*UI.settings.windowDuration+(0.995-UI.settings.insetRelativeWidth)*UI.settings.windowDuration,[0.5:plotRows(1)]/plotRows(1)*UI.settings.insetRelativeHeight+(0.985-UI.settings.insetRelativeHeight),cell_spikematrix, 'AlphaData', .8);
            set(h, 'AlphaData', cell_spikematrix) 
            % Drawing PCA values
%             xlim1 = [min(abc(:,1)),max(abc(:,1))];
%             ylim1 = [min(abc(:,2)),max(abc(:,2))];
%             line(UI.plot_axis1,(abc(:,1)-xlim1(1))/diff(xlim1)*UI.settings.insetRelativeWidth*UI.settings.windowDuration+(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration-0.005,(abc(:,2)-ylim1(1))/diff(ylim1)*UI.settings.insetRelativeHeight+(0.985-UI.settings.insetRelativeHeight), 'HitTest','off','Color', lineColor,'Marker','o','LineStyle','none','linewidth',2,'MarkerFaceColor',lineColor,'MarkerEdgeColor',lineColor)
        end
    end

    function raster = plotSpikeWaveforms(raster,lineColor,plotStyle)
        
        wfWin_sec = 0.0008; % Default: 2*0.8ms window size
        wfWin = round(wfWin_sec * ephys.sr); % Windows size in sample
        
        raster.channel(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];
        raster.idx(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];

        channels_with_spikes = unique(raster.channel);
        
        chanCoords_x = data.session.extracellular.chanCoords.x(UI.channelOrder(:));
        chanCoords_x = (chanCoords_x-min(chanCoords_x))/range(chanCoords_x);
        chanCoords_y = data.session.extracellular.chanCoords.y(UI.channelOrder(:));
        chanCoords_y = (chanCoords_y-min(chanCoords_y))/range(chanCoords_y);
        [~,Locb] = ismember(channels_with_spikes,UI.channelOrder(:));
        
        waveforms = zeros(wfWin*2,numel(raster.channel));
        waveforms_xdata = zeros(wfWin*2,numel(raster.channel));
        for j = 1:numel(channels_with_spikes)
            i = channels_with_spikes(j);
            timestamps = raster.idx(raster.channel==i);
            
            if ~isempty(timestamps)
                startIndicies2 = (timestamps - wfWin)+1;
                stopIndicies2 = (timestamps + wfWin);
                X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
                if plotStyle == 5 && ~UI.settings.filterTraces
                    ephys_data = ephys.filt(:,i)';
                else                   
                    ephys_data = (1000000/UI.settings.scalingFactor)*ephys.traces(:,i)';
                end
                
                wf = reshape(double(ephys_data(X2(1:end-1))),1,(wfWin*2),[]);
                wf2 = reshape(permute(wf,[2,1,3]),(wfWin*2),[]);
                
                if UI.settings.showWaveformsBelowTrace
                    x_offset = (0.035+0.93*chanCoords_x(Locb(j)))*UI.settings.windowDuration;
                    y_offset = 0.029+UI.dataRange.spikeWaveforms(1)+(diff(UI.dataRange.spikeWaveforms)-0.05)*chanCoords_y(Locb(j));
                else
                    x_offset = 0.005*UI.settings.windowDuration;
                    y_offset = -UI.channelScaling(1,UI.channelOrder(i));
                end
                if ~isempty(wf2)
                    waveforms_xdata(:,raster.channel==i) = repmat([-wfWin+1:wfWin]/(2*wfWin)*UI.settings.waveformsRelativeWidth*UI.settings.windowDuration,size(wf2,2),1)'+x_offset;
                    waveforms(:,raster.channel==i) = ((wf2-mean(wf2)) * (UI.settings.scalingFactor)/1000000)+y_offset;
                end
            end
        end
        
        % Pulling waveforms
        if ~isempty(waveforms)
            % Drawing background
            if ~UI.settings.showWaveformsBelowTrace
                p1 = patch(UI.plot_axis1,[0.001,0.002+UI.settings.waveformsRelativeWidth*UI.settings.windowDuration,0.002+UI.settings.waveformsRelativeWidth*UI.settings.windowDuration,0.001]+0.005,[0.02 0.02 1 1]-0.01,'k','HitTest','off','EdgeColor',[0.5 0.5 0.5]);
                alpha(p1,0.6);
            end
            
            % Drawing waveforms
            if plotStyle == 1 % UID
                raster.UID(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];
                uid = raster.UID;
                unique_uids = unique(uid);
                uid_colormap = eval([UI.settings.spikesColormap,'(',num2str(numel(unique_uids)),')']);
                for i = 1:numel(unique_uids)
                    idx_uids = uid == unique_uids(i);
                    xdata = [waveforms_xdata(:,idx_uids);nan(1,sum(idx_uids))];
                    ydata = [waveforms(:,idx_uids);nan(1,sum(idx_uids))];
                    line(UI.plot_axis1,xdata(:),ydata(:), 'color', [uid_colormap(i,:),0.4],'HitTest','off')
                end
                
            elseif plotStyle == 3 % Electrode groups
                raster.electrodeGroup(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];
                unique_electrodeGroups = unique(raster.electrodeGroup);
                electrodeGroup_colormap = UI.colors;
                for i = 1:numel(unique_electrodeGroups)
                    idx_uids = raster.electrodeGroup == unique_electrodeGroups(i);
                    xdata = [waveforms_xdata(:,idx_uids);nan(1,sum(idx_uids))];
                    ydata = [waveforms(:,idx_uids);nan(1,sum(idx_uids))];
                    line(UI.plot_axis1,xdata(:),ydata(:), 'color', [electrodeGroup_colormap(unique_electrodeGroups(i),:),0.4],'HitTest','off')
                end
                
            elseif plotStyle == 2 % Single group
                xdata = [waveforms_xdata;nan(1,size(waveforms,2))];
                ydata = [waveforms;nan(1,size(waveforms,2))];
                line(UI.plot_axis1,xdata(:),ydata(:), 'color', [lineColor,0.4],'HitTest','off')
                
            elseif plotStyle == 5 % Colored by spike waveform width
                
                [~,idx_min] = min(waveforms(round(wfWin_sec*ephys.sr):end,:));
                [~,idx_max] = max(waveforms(round(wfWin_sec*ephys.sr):end,:));
                spike_width = idx_max-idx_min;
                spike_identity = double(spike_width>UI.settings.interneuronMaxWidth*ephys.sr/1000)+1;
                raster.spike_identity = spike_identity;
                unique_electrodeGroups = unique(spike_identity);
                spike_identity_colormap = [0.3 0.3 1; 1 0.3 0.3];
                labels_cell_types = {'Narrow waveform','Wide waveform'};
                addLegend('Spike waveforms')
                for i = 1:numel(unique_electrodeGroups)
                    idx_uids = spike_identity == i;
                    xdata = [waveforms_xdata(:,idx_uids);nan(1,sum(idx_uids))];
                    ydata = [waveforms(:,idx_uids);nan(1,sum(idx_uids))];
                    line(UI.plot_axis1,xdata(:),ydata(:), 'color', [spike_identity_colormap(unique_electrodeGroups(i),:),0.5],'HitTest','off')
                    addLegend(labels_cell_types{unique_electrodeGroups(i)},num2strCommaSeparated(spike_identity_colormap(unique_electrodeGroups(i),:)));
                end

            elseif plotStyle == 4
                raster.UID(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];
                putativeCellTypes = unique(data.cell_metrics.(UI.params.groupMetric));
                UI.colors_metrics = eval([UI.settings.spikesColormap,'(',num2str(numel(putativeCellTypes)),')']);
                for i = 1:numel(putativeCellTypes)
                    idx2 = find(ismember(data.cell_metrics.(UI.params.groupMetric),putativeCellTypes{i}));
                    idx3 = ismember(raster.UID,idx2);
                    if any(idx3)
                        xdata = [waveforms_xdata(:,idx3);nan(1,sum(idx3))];
                        ydata = [waveforms(:,idx3);nan(1,sum(idx3))];
                        line(UI.plot_axis1,xdata(:),ydata(:), 'color', [UI.colors_metrics(i,:),0.4],'HitTest','off')
                    end
                end
            end
        end
    end
    
    function plotSpikesPCAspace(raster,lineColor,drawBackground)
        
        wfWin_sec = 0.0008; % Default: 2*0.8ms window size
        wfWin = round(wfWin_sec * ephys.sr); % Windows size in sample
            
        raster.channel(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];
        raster.idx(raster.x<=wfWin_sec | raster.x>=UI.settings.windowDuration-wfWin_sec)=[];        
        raster1 = raster.idx(ismember(raster.channel,UI.channels{UI.settings.PCAspace_electrodeGroup}));
        
        % Pulling waveforms
        if ~isempty(raster1)
            nChannels = numel(UI.channels{UI.settings.PCAspace_electrodeGroup});
            startIndicies2 = (raster1 - wfWin)*nChannels+1;
            stopIndicies2 = (raster1 + wfWin)*nChannels;
            X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
            if isfield(ephys,'filt')
                ephys_data = ephys.filt(:,UI.channels{UI.settings.PCAspace_electrodeGroup})';
            else
                ephys_data = ephys.traces(:,UI.channels{UI.settings.PCAspace_electrodeGroup})';
            end
            wf = reshape(double(ephys_data(X2(1:end-1))),nChannels,(wfWin*2),[]);
            wf2 = reshape(permute(wf,[2,1,3]),nChannels*(wfWin*2),[]);
            abc = pca(wf2,'NumComponents',2);

            % Drawing background
            if drawBackground
                p1 = patch(UI.plot_axis1,[(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration,UI.settings.windowDuration,UI.settings.windowDuration,(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration]-0.005,[(1-UI.settings.insetRelativeHeight) (1-UI.settings.insetRelativeHeight) 1 1]-0.015,'k','HitTest','off','EdgeColor',[0.5 0.5 0.5]);
                alpha(p1,0.6);
            end
            
            % Drawing PCA values
            xlim1 = [min(abc(:,1)),max(abc(:,1))];
            ylim1 = [min(abc(:,2)),max(abc(:,2))];
            line(UI.plot_axis1,(abc(:,1)-xlim1(1))/diff(xlim1)*UI.settings.insetRelativeWidth*UI.settings.windowDuration+(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration-0.005,(abc(:,2)-ylim1(1))/diff(ylim1)*UI.settings.insetRelativeHeight+(0.985-UI.settings.insetRelativeHeight), 'HitTest','off','Color', lineColor,'Marker','o','LineStyle','none','linewidth',2,'MarkerFaceColor',lineColor,'MarkerEdgeColor',lineColor)
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
                    raster.y = (diff(UI.dataRange.spikes))*((data.spikes.spindices(idx,3)-UI.settings.spikes_ylim(1))/diff(UI.settings.spikes_ylim))+UI.dataRange.spikes(1)+0.002;
                else
                    if UI.settings.useMetrics
                        [~,sortIdx] = sort(data.cell_metrics.(UI.params.sortingMetric));
                        [~,sortIdx] = sort(sortIdx);
                    else
                        sortIdx = 1:data.spikes.numcells;
                    end
                    raster.y = (diff(UI.dataRange.spikes))*(sortIdx(data.spikes.spindices(idx,2))/(data.spikes.numcells))+UI.dataRange.spikes(1)+0.002;
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
            idx2 = round(raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.kilosortBelowTrace
                sortIdx = 1:data.spikes_kilosort.numcells;
                raster.y = (diff(UI.dataRange.kilosort))*(sortIdx(data.spikes_kilosort.spindices(idx,2))/(data.spikes_kilosort.numcells))+UI.dataRange.kilosort(1);
                text(1/400,UI.dataRange.kilosort(2),'Kilosort','color',colorIn,'FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground, 'HitTest','off','VerticalAlignment', 'top')
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes_kilosort.maxWaveformCh1(data.spikes_kilosort.spindices(idx,2))');
                raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            line(raster.x, raster.y,'Marker','o','LineStyle','none','color',colorIn, 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
        end
    end
    
    function plotSpykingcircusData(t1,t2,colorIn)
        % Plots spikes
        units2plot = find(ismember(data.spikes_spykingcircus.maxWaveformCh1,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
        idx = data.spikes_spykingcircus.spindices(:,1) > t1 & data.spikes_spykingcircus.spindices(:,1) < t2;
        if any(idx)
            raster = [];
            raster.x = data.spikes_spykingcircus.spindices(idx,1)-t1;
            idx2 = round(raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.spykingcircusBelowTrace
                sortIdx = 1:data.spikes_spykingcircus.numcells;
                raster.y = (diff(UI.dataRange.spykingcircus))*(sortIdx(data.spikes_spykingcircus.spindices(idx,2))/(data.spikes_spykingcircus.numcells))+UI.dataRange.spykingcircus(1);
                text(1/400,UI.dataRange.spykingcircus(2),'SpyKING Circus','color',colorIn,'FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground, 'HitTest','off','VerticalAlignment', 'top')
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes_spykingcircus.maxWaveformCh1(data.spikes_spykingcircus.spindices(idx,2))');
                raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            line(raster.x, raster.y,'Marker','o','LineStyle','none','color',colorIn, 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
        end
    end
    
    function plotKlustaData(t1,t2,colorIn)
        % Plots spikes
        units2plot = find(ismember(data.spikes_klusta.maxWaveformCh1,[UI.channels{UI.settings.electrodeGroupsToPlot}]));
        idx = data.spikes_klusta.spindices(:,1) > t1 & data.spikes_klusta.spindices(:,1) < t2;
        if any(idx)
            raster = [];
            raster.x = data.spikes_klusta.spindices(idx,1)-t1;
            idx2 = round(raster.x*size(ephys.traces,1)/UI.settings.windowDuration);
            if UI.settings.klustaBelowTrace
                sortIdx = 1:data.spikes_klusta.numcells;
                raster.y = (diff(UI.dataRange.klusta))*(sortIdx(data.spikes_klusta.spindices(idx,2))/(data.spikes_klusta.numcells))+UI.dataRange.klusta(1);
                text(1/400,UI.dataRange.klusta(2),'SpyKING Circus','color',colorIn,'FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground, 'HitTest','off','VerticalAlignment', 'top')
            else
                idx3 = sub2ind(size(ephys.traces),idx2,data.spikes_klusta.maxWaveformCh1(data.spikes_klusta.spindices(idx,2))');
                raster.y = ephys.traces(idx3)-UI.channelScaling(idx3);
            end
            line(raster.x, raster.y,'Marker','o','LineStyle','none','color',colorIn, 'HitTest','off','linewidth',UI.settings.spikeRasterLinewidth);
        end
    end

    function plotEventData(t1,t2,colorIn1,colorIn2)
        % Plot events
        ydata = UI.dataRange.events';
        if ~UI.settings.showEventsBelowTrace && UI.settings.processing_steps
            ydata2 = [0;1];
        else
            ydata2 = ydata;
        end  
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
                line([1;1]*data.events.(UI.settings.eventData).time(idx(idx2))'-t1,ydata2*ones(1,sum(idx2)),'Marker','none','LineStyle','-','color','m', 'HitTest','off','linewidth',linewidth);
            end
            idx(idx2) = [];
        end
        
        % Plotting events 
        if any(idx)
            line([1;1]*data.events.(UI.settings.eventData).time(idx)'-t1,ydata2*ones(1,numel(idx)),'Marker','none','LineStyle','-','color',colorIn1, 'HitTest','off','linewidth',linewidth);
        end
        
        % Plotting added events 
        if isfield(data.events.(UI.settings.eventData),'added') && ~isempty(isfield(data.events.(UI.settings.eventData),'added'))
            idx3 = find(data.events.(UI.settings.eventData).added >= t1 & data.events.(UI.settings.eventData).added <= t2);
            if any(idx3)
                line([1;1]*data.events.(UI.settings.eventData).added(idx3)'-t1,ydata2*ones(1,numel(idx3)),'Marker','none','LineStyle','--','color','c', 'HitTest','off','linewidth',linewidth);
            end
        end
        
        % Plotting processing steps
        if UI.settings.processing_steps && isfield(data.events.(UI.settings.eventData),'processing_steps')
            fields2plot = fieldnames(data.events.(UI.settings.eventData).processing_steps);
            UI.colors_processing_steps = hsv(numel(fields2plot));
            ydata1 = [0;0.005]+ydata(1);
            addLegend(['Processing steps: ' UI.settings.eventData])
            for i = 1:numel(fields2plot)
                idx5 = find(data.events.(UI.settings.eventData).processing_steps.(fields2plot{i}) >= t1 & data.events.(UI.settings.eventData).processing_steps.(fields2plot{i}) <= t2);
                if any(idx5)
                    line([1;1]*data.events.(UI.settings.eventData).processing_steps.(fields2plot{i})(idx5)'-t1,0.005*i+ydata1*ones(1,numel(idx5)),'Marker','none','LineStyle','-','color',UI.colors_processing_steps(i,:), 'HitTest','off','linewidth',1.3);
                    addLegend(strrep(fields2plot{i}, '_', ' '),UI.colors_processing_steps(i,:)*0.8);
                else
                    addLegend(fields2plot{i},[0.5, 0.5, 0.5]);
                end
            end

            % Specs
            idx_center = find(data.events.(UI.settings.eventData).time == t1+UI.settings.windowDuration/2);
            if ~isempty(idx_center)
                spec_text = {};
                if isfield(data.events.(UI.settings.eventData),'timestamps')
                    spec_text = [spec_text;['Duration: ', num2str(diff(data.events.(UI.settings.eventData).timestamps(idx_center,:))),' sec']];
                end
                if isfield(data.events.(UI.settings.eventData),'peakNormedPower')
                    spec_text = [spec_text;['Power: ', num2str(data.events.(UI.settings.eventData).peakNormedPower(idx_center))]];
                end
                text(1/400+UI.settings.windowDuration/2,1,spec_text,'color',[1 1 1],'FontWeight', 'Bold','BackgroundColor',UI.settings.textBackground, 'HitTest','off','Units','normalized','verticalalignment','top')
            end
        end
        
        % Plotting event intervals
        if UI.settings.showEventsIntervals
            statesData = data.events.(UI.settings.eventData).timestamps(idx,:)-t1;
            p1 = patch(double([statesData,flip(statesData,2)])',[ydata2(1);ydata2(1);ydata2(2);ydata2(2)]*ones(1,size(statesData,1)),'g','EdgeColor','g','HitTest','off');
            alpha(p1,0.1);
        end
        
        % Highlighting detection channel
        if isfield(data.events.(UI.settings.eventData),'detectorParams')
            detector_channel = data.events.(UI.settings.eventData).detectorParams.channel+1;
        elseif isfield(data.events.(UI.settings.eventData),'detectorinfo') & isfield(data.events.(UI.settings.eventData).detectorinfo,'detectionchannel')
            detector_channel = data.events.(UI.settings.eventData).detectorinfo.detectionchannel+1;
        else
            detector_channel = [];
        end
        if ~isempty(detector_channel) && ismember(detector_channel,UI.channelOrder)
            highlightTraces(detector_channel,UI.settings.primaryColor)
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
        intervals = [data.behavior.trials.start;data.behavior.trials.end]';
        idx = (intervals(:,1)<t2 & intervals(:,2)>t1);
        patch_range = UI.dataRange.trials;
        if any(idx)
            intervals = intervals(idx,:)-t1;
            intervals(intervals<0) = 0; intervals(intervals>t2-t1) = t2-t1;
            p1 = patch(double([intervals,flip(intervals,2)])',[patch_range(1);patch_range(1);patch_range(2);patch_range(2)]*ones(1,size(intervals,1)),'g','EdgeColor','g','HitTest','off');
            alpha(p1,0.3);
            text(intervals(:,1),patch_range(2)*ones(1,size(intervals,1)),strcat({' Trial '}, num2str(find(idx))),'FontWeight', 'Bold','Color',UI.settings.primaryColor,'margin',0.1,'VerticalAlignment', 'top')
        end
    end
    
    function plotSpectrogram
        if ismember(UI.settings.spectrogram.channel,UI.channelOrder)
            sr = ephys.sr;
            spectrogram_range = UI.dataRange.spectrogram;
            window = UI.settings.spectrogram.window;
            freq_range = UI.settings.spectrogram.freq_range;
            y_ticks = UI.settings.spectrogram.y_ticks;
            
            [s, ~, t] = spectrogram(ephys.traces(:,UI.settings.spectrogram.channel)*5, round(sr*UI.settings.spectrogram.window) ,round(sr*UI.settings.spectrogram.window*0.95), UI.settings.spectrogram.freq_range, sr);
            multiplier = [0:size(s,1)-1]/(size(s,1)-1)*diff(spectrogram_range)+spectrogram_range(1);
            
            scaling = 200;
            axis_labels = interp1(freq_range,multiplier,y_ticks);
            image(UI.plot_axis1,'XData',t,'YData',multiplier,'CData',scaling*log10(abs(s)), 'HitTest','off');
            text(UI.plot_axis1,t(1)*ones(size(y_ticks)),axis_labels,num2str(y_ticks(:)),'FontWeight', 'Bold','color',UI.settings.primaryColor,'margin',1, 'HitTest','off','HorizontalAlignment','left','BackgroundColor',[0 0 0 0.5]);
            if ismember(UI.settings.spectrogram.channel,UI.channelOrder)
                highlightTraces(UI.settings.spectrogram.channel,'m')
            end
        end
    end
    
    function plotRMSnoiseInset
        % Shows RMS noise in a small inset plot in the upper right corner
        if UI.settings.plotRMSnoise_apply_filter == 1
            rms1 = rms(ephys.raw/(UI.settings.scalingFactor/1000000));
        elseif UI.settings.plotRMSnoise_apply_filter == 2
            rms1 = rms(ephys.traces/(UI.settings.scalingFactor/1000000));
        else
            if int_gt_0(UI.settings.plotRMSnoise_lowerBand,ephys.sr) && int_gt_0(UI.settings.plotRMSnoise_higherBand,ephys.sr)
                UI.settings.plotRMSnoise_apply_filter = false;
                UI.settings.plotRMSnoise_apply_filter = 1;
                UI.panel.RMSnoiseInset.filter.Value = 1;
                return
            elseif int_gt_0(UI.settings.plotRMSnoise_lowerBand,ephys.sr) && ~int_gt_0(UI.settings.plotRMSnoise_higherBand,ephys.sr)
                [UI.settings.RMSnoise_filter.b1, UI.settings.RMSnoise_filter.a1] = butter(3, UI.settings.plotRMSnoise_higherBand/(ephys.sr/2), 'low');
            elseif int_gt_0(UI.settings.plotRMSnoise_higherBand,ephys.sr) && ~int_gt_0(UI.settings.plotRMSnoise_lowerBand,ephys.sr)
                [UI.settings.RMSnoise_filter.b1, UI.settings.RMSnoise_filter.a1] = butter(3, UI.settings.plotRMSnoise_lowerBand/(ephys.sr/2), 'high');
            else
                [UI.settings.RMSnoise_filter.b1, UI.settings.RMSnoise_filter.a1] = butter(3, [UI.settings.plotRMSnoise_lowerBand,UI.settings.plotRMSnoise_higherBand]/(ephys.sr/2), 'bandpass');
            end
            rms1(UI.channelOrder) = rms(filtfilt(UI.settings.RMSnoise_filter.b1, UI.settings.RMSnoise_filter.a1, ephys.raw(:,UI.channelOrder)));
        end
        k_channels = 0;
        xlim1 = [0,numel([UI.channelOrder])+1];
        ylim1 = [min(rms1(UI.channelOrder)),max(rms1(UI.channelOrder))];
        
        % Drawing background
        p1 = patch(UI.plot_axis1,[(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration,UI.settings.windowDuration,UI.settings.windowDuration,(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration]-0.005,[(1-UI.settings.insetRelativeHeight) (1-UI.settings.insetRelativeHeight) 1 1]-0.015,'k','HitTest','off','EdgeColor',[0.5 0.5 0.5]);
        alpha(p1,0.6);
        
        % Drawing noise curves
        for iShanks = UI.settings.electrodeGroupsToPlot
            channels = UI.channels{iShanks};
            [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
            channels = UI.channelOrder(ia);
            markerColor = UI.colors(iShanks,:);
            x_data = (1:numel(channels))+k_channels;
            y_data = rms1(channels);
            line(UI.plot_axis1,(x_data-xlim1(1))/diff(xlim1)*UI.settings.insetRelativeWidth*UI.settings.windowDuration+(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration-0.005,(y_data-ylim1(1))/diff(ylim1)*UI.settings.insetRelativeHeight+(0.985-UI.settings.insetRelativeHeight), 'HitTest','off','Color', markerColor,'Marker','o','LineStyle','-','linewidth',2,'MarkerFaceColor',markerColor,'MarkerEdgeColor',markerColor)
            k_channels = k_channels + numel(channels);
        end
        text(UI.plot_axis1,(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration-0.005,(0.986-UI.settings.insetRelativeHeight),[' ', num2str(ylim1(1),3),char(181),'V'],'FontWeight', 'Bold','VerticalAlignment', 'bottom','HorizontalAlignment','left','color',UI.settings.primaryColor,'FontSize',12)
        text(UI.plot_axis1,(1-UI.settings.insetRelativeWidth)*UI.settings.windowDuration-0.005,0.984,[' ', num2str(ylim1(2),3),char(181),'V'],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','left','color',UI.settings.primaryColor,'FontSize',12)
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
            addLegend(['States: ' UI.settings.statesData])
            for jj = 1:numel(stateNames)
                if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
                    idx = (states1.(stateNames{jj})(:,1)<t2 & states1.(stateNames{jj})(:,2)>t1);
                    if any(idx)
                        statesData = states1.(stateNames{jj})(idx,:)-t1;
                        statesData(statesData<0) = 0; statesData(statesData>t2-t1) = t2-t1;
                        p1 = patch(double([statesData,flip(statesData,2)])',[UI.dataRange.states(1);UI.dataRange.states(1);UI.dataRange.states(2);UI.dataRange.states(2)]*ones(1,size(statesData,1)),clr_states(jj,:),'EdgeColor',clr_states(jj,:),'HitTest','off');
                        alpha(p1,0.3);
                        addLegend(stateNames{jj},clr_states(jj,:)*0.8);
                    else
                        addLegend(stateNames{jj},[0.5, 0.5, 0.5]);
                    end
                end
            end
        end
    end

    function viewSessionMetaData(~,~)
        % Opens the gui_session for the current session to editing metadata
        [session1,~,statusExit] = gui_session(data.session);
        if statusExit
            data.session = session1;
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
        end
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
        
        AboutWindow.dialog = figure('Position', fig_size,'Name','About NeuroScope2', 'MenuBar', 'None','NumberTitle','off','visible','off', 'resize', 'off'); movegui(AboutWindow.dialog,'center'), set(AboutWindow.dialog,'visible','on')
        if isdeployed
            logog_path = '';
        else
            [logog_path,~,~] = fileparts(which('CellExplorer.m'));
        end
        [img, ~, alphachannel] = imread(fullfile(logog_path,'logo_NeuroScope2.png'));
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

    function keyPress(~, event)
        % Handles keyboard shortcuts
        UI.settings.stream = false;
        if isempty(event.Modifier)
            switch event.Key
                case 'rightarrow'
                    advance(0.25)
                case 'leftarrow'
                    back(0.25)
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
                    UI.t0 = 0;
                    uiresume(UI.fig);
                case 'decimal'
                    UI.t0 = UI.t_total-UI.settings.windowDuration;
                    uiresume(UI.fig);
                case 'backspace'
                    if numel(UI.t0_track)>1
                        UI.t0_track(end) = [];
                    end
                    UI.track = false;
                    UI.t0 = UI.t0_track(end);
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
                    advance(1)
                case 'leftarrow'
                    back(1)
                case 'period'
                    nextPowerEvent
                case 'comma'
                    previousPowerEvent
                case 'slash'
                    maxPowerEvent
                case 'l'
                    minPowerEvent
                case 'f'
                    flagEvent
            end
        elseif strcmp(event.Modifier,'control')
            switch event.Key
                case 'space'
                    streamData2
            end
        elseif strcmp(event.Modifier,'alt')
            switch event.Key
                case 'rightarrow'
                    advance(0.1)
                case 'leftarrow'
                    back(0.1)
            end
        end
    end
    
    function keyRelease(~, event)
        if strcmp(event.Key,'shift')
            UI.settings.normalClick = true;
        end
    end
    
    function ShowChannelNumbers(~,~)
        UI.settings.showChannelNumbers = ~UI.settings.showChannelNumbers;
        if UI.settings.showChannelNumbers
            UI.menu.display.ShowChannelNumbers.Checked = 'on';
        else
            UI.menu.display.ShowChannelNumbers.Checked = 'off';
        end
        resetZoom
        uiresume(UI.fig);
    end
        
    function resetZoomOnNavigation(~,~)
        UI.settings.resetZoomOnNavigation = ~UI.settings.resetZoomOnNavigation;
        if UI.settings.resetZoomOnNavigation
            UI.menu.display.resetZoomOnNavigation.Checked = 'on';
        else
            UI.menu.display.resetZoomOnNavigation.Checked = 'off';
        end
    end
    
    function showScalebar(~,~)
        UI.settings.showScalebar = ~UI.settings.showScalebar;
        if UI.settings.showScalebar
            UI.menu.display.showScalebar.Checked = 'on';
        else
            UI.menu.display.showScalebar.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
    function narrowPadding(~,~)
        UI.settings.narrowPadding = ~UI.settings.narrowPadding;
        if UI.settings.narrowPadding
            UI.settings.ephys_padding = 0.015;
            UI.menu.display.narrowPadding.Checked = 'on';
        else
            UI.settings.ephys_padding = 0.05;
            UI.menu.display.narrowPadding.Checked = 'off';
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function plotStyleDynamicRange(~,~)
        UI.settings.plotStyleDynamicRange = ~UI.settings.plotStyleDynamicRange;
        if UI.settings.plotStyleDynamicRange
            UI.menu.display.plotStyleDynamicRange.Checked = 'on';
        else
            UI.menu.display.plotStyleDynamicRange.Checked = 'off';
        end
        uiresume(UI.fig);
    end
    
    function detectedEventsBelowTrace(~,~)
        UI.settings.detectedEventsBelowTrace = ~UI.settings.detectedEventsBelowTrace;
        if UI.settings.detectedEventsBelowTrace
            UI.menu.display.detectedEventsBelowTrace.Checked = 'on';
        else
            UI.menu.display.detectedEventsBelowTrace.Checked = 'off';
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function detectedSpikesBelowTrace(~,~)
        UI.settings.detectedSpikesBelowTrace = ~UI.settings.detectedSpikesBelowTrace;
        if UI.settings.detectedSpikesBelowTrace
            UI.menu.display.detectedSpikesBelowTrace.Checked = 'on';
        else
            UI.menu.display.detectedSpikesBelowTrace.Checked = 'off';
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function showDetectedSpikeWaveforms(~,~)
        UI.settings.showDetectedSpikeWaveforms = ~UI.settings.showDetectedSpikeWaveforms;
        if UI.settings.showDetectedSpikeWaveforms && isfield(data.session.extracellular,'chanCoords')
            UI.menu.display.showDetectedSpikeWaveforms.Checked = 'on';
        elseif UI.settings.showDetectedSpikeWaveforms
            UI.menu.display.showDetectedSpikeWaveforms.Checked = 'off';
            UI.settings.showDetectedSpikeWaveforms = false;
            warndlg('ChanCoords have not been defined for this session','Error')
        else
            UI.menu.display.showDetectedSpikeWaveforms.Checked = 'off';
        end
        
        initTraces
        uiresume(UI.fig);
    end
    
    function toggleColorDetectedSpikesByWidth(~,~)
        UI.settings.colorDetectedSpikesByWidth = ~UI.settings.colorDetectedSpikesByWidth;

        if UI.settings.colorDetectedSpikesByWidth
            answer = inputdlg('Max trough-to-peak of interneurons (ms)','Waveform width boundary', [1 50],{num2str(UI.settings.interneuronMaxWidth)});
            if ~isempty(answer) && isnumeric(str2double(answer{1})) && str2double(answer{1}) > 0
                UI.settings.interneuronMaxWidth = str2double(answer{1});
                UI.menu.display.colorDetectedSpikesByWidth.Checked = 'on';
                UI.settings.showDetectedSpikeWaveforms = true;
                UI.menu.display.showDetectedSpikeWaveforms.Checked = 'on';
            else
                UI.settings.colorDetectedSpikesByWidth = false;
                UI.menu.display.colorDetectedSpikesByWidth.Checked = 'off';
            end
        else
            UI.menu.display.colorDetectedSpikesByWidth.Checked = 'off';
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function showDetectedSpikesPCAspace(~,~)
        UI.settings.showDetectedSpikesPCAspace = ~UI.settings.showDetectedSpikesPCAspace;
        if UI.settings.showDetectedSpikesPCAspace
            UI.menu.display.showDetectedSpikesPCAspace.Checked = 'on';
        else
            UI.menu.display.showDetectedSpikesPCAspace.Checked = 'off';
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function toggleRMSnoiseInset(~,~)
        if UI.panel.RMSnoiseInset.showRMSnoiseInset.Value == 1
            UI.settings.plotRMSnoiseInset = true;
        else
            UI.settings.plotRMSnoiseInset = false;
        end        
        UI.settings.plotRMSnoise_apply_filter = UI.panel.RMSnoiseInset.filter.Value;
        if UI.panel.RMSnoiseInset.filter.Value == 3
            UI.settings.plotRMSnoise_lowerBand = str2num(UI.panel.RMSnoiseInset.lowerBand.String);
            UI.settings.plotRMSnoise_higherBand = str2num(UI.panel.RMSnoiseInset.higherBand.String);
        end
        
        uiresume(UI.fig);
    end
    
    function show_CSD(~,~)
        if UI.panel.csd.showCSD.Value == 1
            UI.settings.CSD.show = true;
        else
            UI.settings.CSD.show = false;
        end
        uiresume(UI.fig);
    end
    
    function removeDC(~,~)
        UI.settings.removeDC = ~UI.settings.removeDC;
        if UI.settings.removeDC
            UI.menu.display.removeDC.Checked = 'on';
        else
            UI.menu.display.removeDC.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function medianFilter(~,~)
        UI.settings.medianFilter = ~UI.settings.medianFilter;
        if UI.settings.medianFilter
            UI.menu.display.medianFilter.Checked = 'on';
        else
            UI.menu.display.medianFilter.Checked = 'off';
        end
        uiresume(UI.fig);
    end

    function ShowHideMenu(~,~)
        % Hide/show menubar
        if UI.settings.displayMenu == 0
            set(UI.fig, 'MenuBar', 'figure')
            UI.settings.displayMenu = 1;
            UI.menu.display.showHideMenu.Checked = 'On';
            fieldmenus = fieldnames(UI.menu);
            fieldmenus(strcmpi(fieldmenus,'NeuroScope2')) = [];
            for i = 1:numel(fieldmenus)
                UI.menu.(fieldmenus{i}).topMenu.Visible = 'off';
            end
            MsgLog('Regular MATLAB menubar shown. Press M to regain the NeuroScope2 menubar',2);
        else
            set(UI.fig, 'MenuBar', 'None')
            UI.settings.displayMenu = 0;
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
            '> (right arrow)','Forward in time (quarter window length)'; 
            '< (left arrow)','Backward in time (quarter window length)';
            'shift + > (right arrow)','Forward in time (full window length)'; 
            'shift + < (left arrow)','Backward in time (full window length)';
            'alt + > (right arrow)','Forward in time (a tenth window length)'; 
            'alt + < (left arrow)','Backward in time (a tenth window length)';
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
            'H','View mouse and keyboard shortcuts (this page)';
            [scs,'O'],'Open session from file'; 
            [scs,'C'],'Open the file directory of the current session'; 
            [scs,'D'],'Opens session from the Buzsaki lab database';
            [scs,'V'],'Visit the CellExplorer website in your browser';
            '',''; '','<html><b>Visit the CellExplorer website for further help and documentation</html></b>'; };
        if ismac
            dimensions = [450,(size(shortcutList,1)+1)*17.5];
        else
            dimensions = [450,(size(shortcutList,1)+1)*18.5];
        end
        HelpWindow.dialog = figure('Position', [300, 300, dimensions(1), dimensions(2)],'Name','Mouse and keyboard shortcuts', 'MenuBar', 'None','NumberTitle','off','visible','off'); movegui(HelpWindow.dialog,'center'), set(HelpWindow.dialog,'visible','on')
        HelpWindow.sessionList = uitable(HelpWindow.dialog,'Data',shortcutList,'Position',[1, 1, dimensions(1)-1, dimensions(2)-1],'ColumnWidth',{100 345},'columnname',{'Shortcut','Action'},'RowName',[],'ColumnEditable',[false false],'Units','normalized');
    end
    
    
    function streamDataButtons
        if ~UI.settings.stream
            streamData
        else
            UI.settings.stream = false;
        end
    end
    
    function streamDataButtons2
        if ~UI.settings.stream
            streamData2
        else
            UI.settings.stream = false;
        end
    end
    
    function streamData
        % Streams  data from t0, updating traces twice per window duration
        if ~UI.settings.stream
            UI.settings.stream = true;
            UI.settings.fileRead = 'bof';
            UI.buttons.play1.String = [char(9646) char(9646)];
            UI.elements.lower.performance.String = ['  Streaming...'];
            
            while UI.settings.stream
                streamTic = tic;
                UI.t0 = UI.t0+UI.settings.replayRefreshInterval*UI.settings.windowDuration;
                UI.t0 = max([0,min([UI.t0,UI.t_total-UI.settings.windowDuration])]);
                if ~ishandle(UI.fig)
                    return
                end
                plotData
                
                % Updating UI text and slider
                UI.elements.lower.time.String = num2str(UI.t0);
                UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Streaming','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color',UI.settings.primaryColor,'HitTest','off');
                streamToc = toc(streamTic);
                pauseBins = ones(1,10) * 0.05*UI.settings.windowDuration;
                pauseBins(cumsum(pauseBins)-streamToc<0) = [];
                if ~isempty(pauseBins)
                pauseBins(end) = pauseBins(1)-rem(streamToc,pauseBins(end));
                for i = 1:numel(pauseBins)
                    if UI.settings.stream
                        pause(pauseBins(i))
                    end
                end
                end
            end
            UI.elements.lower.performance.String = '';
        end
        UI.settings.fileRead = 'bof';
        if ishandle(UI.streamingText)
            delete(UI.streamingText)
        end
        UI.buttons.play1.String = char(9654);
        UI.buttons.play2.String = [char(9655) char(9654)];
    end
    
    function streamData2
        % Stream from the end of the file, updating twice per window duration
        if ~UI.settings.stream
            UI.settings.stream = true;
            UI.settings.fileRead = 'eof';
            UI.elements.lower.slider.Value = 100;
            while UI.settings.stream
                UI.t0 = UI.t_total-UI.settings.windowDuration;
                if ~ishandle(UI.fig)
                    return
                end
                plotData
                UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Streaming: end of file','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color',UI.settings.primaryColor,'HitTest','off');
                UI.buttons.play2.String = [char(9646) char(9646)];
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
        UI.buttons.play1.String = char(9654);
        UI.buttons.play2.String = [char(9655) char(9654)];
    end
    
    function benchmarkStream(~,~)
        benchmarkChannelCount
        benchmarkDuration
    end
    
    function benchmarkChannelCount(~,~)
        % Stream from the end of the file, updating twice per window duration
        
        UI.settings.plotStyleDynamicRange = false;
        
        UI.settings.stream = true;
        UI.settings.fileRead = 'bof';
        benchmarkValues = zeros;
        
        channelOrder = [data.session.extracellular.electrodeGroups.channels{:}];
        UI.elements.lower.performance.String = 'Benchmarking...';
        
        for j_displays = [1,2,3]
            if ~UI.settings.stream
                return
            end
            i_stream = 1;
            UI.settings.plotStyle = j_displays;
            while UI.settings.stream && i_stream*5<=numel(channelOrder)
                UI.t0 = UI.t0+UI.settings.windowDuration;
                UI.t0 = max([0,min([UI.t0,UI.t_total-UI.settings.windowDuration])]);
                
                UI.settings.channelList = channelOrder(1:i_stream*5);
                initTraces
                
                if ~ishandle(UI.fig)
                    return
                end
                streamTic = tic;
                plotData
                drawnow
                streamToc = toc(streamTic);
                benchmarkValues(j_displays,i_stream) = streamToc;
                i_stream = i_stream+1;
                UI.elements.lower.performance.String = ['Benchmarking ',num2str(i_stream*5),'/', num2str(numel(channelOrder))];
            end
        end        
        fig_benchmark = figure('name','Summary figure','Position',[50 50 1200 900],'visible','off');
        gca1 = gca(fig_benchmark);
        plot(gca1,[1:size(benchmarkValues,2)]*5,benchmarkValues),
        title(gca1,'Benchmark of NeuroScope2'),
        xlabel(gca1,'Channels'),
        ylabel(gca1,'Plotting time (sec)')
        legend({'Downsampled','Range','Raw'})
        
        movegui(fig_benchmark,'center'), set(fig_benchmark,'visible','on')
        UI.buttons.play1.String = char(9654);
        UI.buttons.play2.String = [char(9655) char(9654)];
    end
    
    function benchmarkDuration(~,~)
        
        UI.settings.plotStyleDynamicRange = false;
        UI.settings.stream = true;
        UI.settings.fileRead = 'bof';
        benchmarkValues = zeros;
        % channelOrder = [data.session.extracellular.electrodeGroups.channels{:}];
        UI.elements.lower.performance.String = 'Benchmarking...';
        durations = 0.3:0.1:2;
        
        for j_displays = 1:3
            if ~UI.settings.stream
                return
            end
            i_stream = 1;
            UI.settings.plotStyle = j_displays;
            initTraces
            UI.forceNewData = true;
            uiresume(UI.fig);
            while UI.settings.stream && i_stream<=numel(durations)
                UI.t0 = UI.t0+UI.settings.windowDuration;
                UI.t0 = max([0,min([UI.t0,UI.t_total-UI.settings.windowDuration])]);
                
%                 UI.settings.channelList = channelOrder;
                UI.settings.windowDuration = durations(i_stream);
                UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
                initTraces
                UI.forceNewData = true;
                resetZoom
                
                if ~ishandle(UI.fig)
                    return
                end
                streamTic = tic;
                UI.forceNewData = true;
                plotData
                drawnow
                streamToc = toc(streamTic);
                benchmarkValues(j_displays,i_stream) = streamToc;
                i_stream = i_stream+1;
                UI.elements.lower.performance.String = ['Benchmarking ',num2str(i_stream),'/', num2str(numel(durations))];
            end
        end        
        fig_benchmark = figure('name','Summary figure','Position',[50 50 1200 900],'visible','off');
        gca1 = gca(fig_benchmark);
        plot(gca1,durations,benchmarkValues),
        title(gca1,'Benchmark of windows duration in NeuroScope2'),
        xlabel(gca1,'Window duration (sec)'),
        ylabel(gca1,'Plotting time (sec)')
        legend({'Downsampled','Range','Raw'})
        
        movegui(fig_benchmark,'center'), set(fig_benchmark,'visible','on')
        UI.buttons.play1.String = char(9654);
        UI.buttons.play2.String = [char(9655) char(9654)];
    end
    
    function goToTimestamp(~,~)
        % Go to a specific timestamp via dialog
        UI.settings.stream = false;
        answer = inputdlg('Go go a specific timepoint (sec)','Navigate to timepoint', [1 50]);
        if ~isempty(answer)
            UI.t0 = valid_t0(str2num(answer{1}));
            resetZoom
            uiresume(UI.fig);
        end
    end

    function advance(step_size)
        if nargin==0
            step_size = 0.25;
        end
        % Advance the traces with step_size * window size
        UI.settings.stream = false;
        UI.t0 = UI.t0+step_size*UI.settings.windowDuration;
        uiresume(UI.fig);
    end

    function back(step_size)
        if nargin==0
            step_size = 0.25;
        end
        % Go back step_size * window size
        UI.t0 = max([UI.t0-step_size*UI.settings.windowDuration,0]);
        UI.settings.stream = false;
        uiresume(UI.fig);
    end

    function setTime(~,~)
        % Go to a specific timestamp
        UI.settings.stream = false;
        string1 = str2num(UI.elements.lower.time.String);
        if isnumeric(string1) & string1>=0
            UI.t0 = valid_t0(string1);
            resetZoom
            uiresume(UI.fig);
        end
    end

    function setWindowsSize(~,~)
        % Set the window size
        string1 = str2num(UI.elements.lower.windowsSize.String);
        if isnumeric(string1) 
            if string1 < 0.001
                string1 = 1;
            elseif string1 > 100
                string1 = 100;
            end
            UI.settings.windowDuration = round(string1*1000)/1000;
            UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
            initTraces
            UI.forceNewData = true;
            resetZoom
            uiresume(UI.fig);
        end
    end

    function increaseWindowsSize(~,~)
        % Increase the window size
        windowSize_old = UI.settings.windowDuration;
        UI.settings.windowDuration = min([UI.settings.windowDuration*2,100]);
        UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
        initTraces
        UI.forceNewData = true;
        uiresume(UI.fig);
    end

    function decreaseWindowsSize(~,~)
        % Decrease the window size
        windowSize_old = UI.settings.windowDuration;
        UI.settings.windowDuration = max([UI.settings.windowDuration/2,0.125]);
        UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
        initTraces
        UI.forceNewData = true;
        uiresume(UI.fig);
    end

    function increaseAmplitude(~,~)
        % Decrease amplitude of the traces
        UI.settings.scalingFactor = min([UI.settings.scalingFactor*(sqrt(2)),100000]);
        setScalingText
        initTraces
        uiresume(UI.fig);
    end

    function decreaseAmplitude(~,~)
        % Increase amplitude of the ephys traces
        UI.settings.scalingFactor = max([UI.settings.scalingFactor/sqrt(2),1]);
        setScalingText
        initTraces
        uiresume(UI.fig);
    end

    function setScaling(~,~)
        string1 = str2num(UI.elements.lower.scaling.String);
        if ~isempty(string1) && isnumeric(string1) && string1>=1  && string1<100000
            UI.settings.scalingFactor = string1;
            setScalingText
            initTraces
            uiresume(UI.fig);
        end
    end
    
    function setScalingText
        UI.elements.lower.scalingText.String = ['Scaling (range: ',num2str(round(10000./UI.settings.scalingFactor)/10),char(181),'V) '];
    end

    function buttonsElectrodeGroups(src,~)
        % handles the three buttons under the electrode groups table
        switch src.String
            case 'Show none'
                if UI.uitabgroup_channels.Selection==1
                    UI.table.electrodeGroups.Data(:,1) = {false};
                    editElectrodeGroups
                elseif UI.uitabgroup_channels.Selection == 2
                    UI.listbox.channelList.Value = [];
                    buttonChannelList
                elseif UI.uitabgroup_channels.Selection == 3
                    UI.table.brainRegions.Data(:,1) = {false};
                    brainRegions = fieldnames(data.session.brainRegions);
                    UI.settings.brainRegionsToHide = brainRegions(~UI.table.brainRegions.Data{:,1});
                    initTraces;
                    uiresume(UI.fig);
                end
            case 'Show all'
                if UI.uitabgroup_channels.Selection==1
                    UI.table.electrodeGroups.Data(:,1) = {true};
                    editElectrodeGroups
                elseif UI.uitabgroup_channels.Selection == 2
                    UI.listbox.channelList.Value = 1:numel(UI.listbox.channelList.String);
                    buttonChannelList
                elseif UI.uitabgroup_channels.Selection == 3
                    UI.table.brainRegions.Data(:,1) = {true};
                    brainRegions = fieldnames(data.session.brainRegions);
                    UI.settings.brainRegionsToHide = brainRegions(~UI.table.brainRegions.Data{:,1});
                    initTraces;
                    uiresume(UI.fig);
                end
            otherwise
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
            case 'New tag'
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
            case 'Delete tag(s)'
                if isfield(data.session,'channelTags') && length(fieldnames(data.session.channelTags))>0
                    list = fieldnames(data.session.channelTags);
                    [indx,tf] = listdlg('ListString',list,'name','Delete tag(s)','PromptString','Select tag(s) to delete');
                    if ~isempty(indx)
                        data.session.channelTags = rmfield(data.session.channelTags,list(indx));
                        updateChannelTags
                        initTraces
                        uiresume(UI.fig);
                    end
                end
            otherwise % 'Save'
                saveSessionMetadata
        end
    end

    function saveSessionMetadata(~,~)
        session = data.session;
        session.neuroScope2.t0 = UI.t0;
        saveStruct(session);
        MsgLog('Session metadata saved',2);
    end
    
    function toggleSpikes(~,~)
        % Toggle spikes data
        if ~isfield(data,'spikes') && exist(fullfile(basepath,[basename,'.spikes.cellinfo.mat']),'file')
            data.spikes = loadSpikes('session',data.session);
            data.spikes.spindices = generateSpinDices(data.spikes.times);
            if ~isfield(data.spikes,'maxWaveformCh1')
                data.spikes.maxWaveformCh1 = data.spikes.maxWaveformCh+1;
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
            excluded_fields = {'times','ts','ts_eeg','maxWaveform_all','channels_all','peakVoltage_sorted','timeWaveform','amplitudes','ids'};
            [spikes_fields,ia] = setdiff(spikes_fields,excluded_fields);
            UI.settings.spikesYDataType = UI.settings.spikesYDataType(ia);

            idx_toKeep = [];
            for i = 1:numel(spikes_fields)
                if strcmp(UI.settings.spikesYDataType{i},'cell')
                    if all(all([cellfun(@(X) size(X,1), data.spikes.(spikes_fields{i}));cellfun(@(X) size(X,2), data.spikes.(spikes_fields{i}))] == [data.spikes.total;ones(1,data.spikes.numcells)])) || all(all([cellfun(@(X) size(X,1), data.spikes.(spikes_fields{i}));cellfun(@(X) size(X,2), data.spikes.(spikes_fields{i}))] == [ones(1,data.spikes.numcells);data.spikes.total]))
                        idx_toKeep = [idx_toKeep,i];
                    end
                elseif strcmp(UI.settings.spikesYDataType{i},'double')
                    idx_toKeep = [idx_toKeep,i];
                end
            end
            UI.settings.spikesYDataType = UI.settings.spikesYDataType(idx_toKeep);
            YDataList = spikes_fields(idx_toKeep);
            YDataList(strcmp(YDataList,'UID')) = [];
            if UI.settings.useMetrics
                YDataList = ['Cell metrics';YDataList];
            else
                YDataList = ['UID';YDataList];
            end
            UI.panel.spikes.setSpikesYData.String = YDataList;
            
            if isempty(UI.panel.spikes.setSpikesYData.Value)
                UI.panel.spikes.setSpikesYData.Value = 1;
            end
            UI.params.subsetTable = 1:data.spikes.numcells;
            UI.params.subsetFilter = 1:data.spikes.numcells;
            UI.params.subsetGroups = 1:data.spikes.numcells;
            UI.params.subsetCellType = 1:data.spikes.numcells;
            
            UI.panel.spikes.setSpikesGroupColors.Enable = 'on';
            if UI.panel.spikes.showSpikesBelowTrace.Value == 1
                UI.panel.spikes.setSpikesYData.Enable = 'on';
            else
                UI.panel.spikes.setSpikesYData.Enable = 'off';
            end
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
            
            % Initialize labels
            if ~isfield(data.cell_metrics, 'labels')
                data.cell_metrics.labels = repmat({''},1,data.cell_metrics.general.cellCount);
            end
            % Initialize labels
            if ~isfield(data.cell_metrics, 'synapticEffect')
                data.cell_metrics.synapticEffect = repmat({'Unknown'},1,data.cell_metrics.general.cellCount);
            end
            
            % Initialize groups
            if ~isfield(data.cell_metrics, 'groups')
                data.cell_metrics.groups = struct();
            end

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
            if UI.settings.spikesBelowTrace
                UI.panel.cell_metrics.sortingMetric.Enable = 'on';
            end
            UI.panel.spikes.setSpikesYData.String{1} = 'Cell metrics';
            
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
            
            UI.panel.spikes.setSpikesGroupColors.String = {'UID','Single color','Electrode groups','Cell metrics'};
            UI.panel.spikes.setSpikesGroupColors.Value = 4; 
            UI.settings.spikesGroupColors = 4;
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
            if UI.panel.spikes.setSpikesGroupColors.Value == 4
                UI.panel.spikes.setSpikesGroupColors.Value = 1;
                UI.settings.spikesGroupColors = 1;
            end
            UI.panel.spikes.setSpikesGroupColors.String = {'UID','Single color','Electrode groups'};
            UI.panel.spikes.setSpikesYData.String{1} = 'UID';
        end
        uiresume(UI.fig);
    end
    
    function toggleSpectrogram(~,~)
        numeric_gt_0 = @(n) ~isempty(n) && isnumeric(n) && (n > 0); % numeric and greater than 0
        numeric_gt_oe_0 = @(n) ~isempty(n) && isnumeric(n) && (n >= 0); % Numeric and greater than or equal to 0
        
        if UI.panel.spectrogram.showSpectrogram.Value == 1
            % Channel to use
            channelnumber = str2num(UI.panel.spectrogram.spectrogramChannel.String);
            if isnumeric(channelnumber) && channelnumber>0 && channelnumber<=data.session.extracellular.nChannels
                UI.settings.spectrogram.channel = channelnumber;
                UI.settings.spectrogram.show = true;
            else
                UI.settings.spectrogram.show = false;
                MsgLog('The spectrogram channel is not valid',4);
                return
            end
            
            % Window width
            window1 = str2num(UI.panel.spectrogram.spectrogramWindow.String);
            if numeric_gt_0(window1) && window1<UI.settings.windowDuration
                UI.settings.spectrogram.window = window1;
                UI.settings.spectrogram.show = true;
            else
                UI.settings.spectrogram.show = false;
                MsgLog('The spectrogram window width is not valid',4);
                return
            end
            
            % Frequency range and step size
            freq_low = str2num(UI.panel.spectrogram.freq_low.String);
            freq_step_size = str2num(UI.panel.spectrogram.freq_step_size.String);
            freq_high = str2num(UI.panel.spectrogram.freq_high.String);
            freq_range = [freq_low : freq_step_size : freq_high];
            
            if numeric_gt_oe_0(freq_low) && numeric_gt_0(freq_step_size) && numeric_gt_0(freq_high) && freq_high > freq_low && numel(freq_range)>1
                UI.settings.spectrogram.freq_low = freq_low;
                UI.settings.spectrogram.freq_step_size = freq_step_size;
                UI.settings.spectrogram.freq_high = freq_high;
                UI.settings.spectrogram.freq_range = freq_range;
                UI.settings.spectrogram.show = true;
                
                % Determining the optioal y-ticks
                n_min_ticks = 10;
                y_tick_step_options = [0.1,1,2,5,10,20,50,100,200,500];
                
                axis_ticks_optimal = (freq_range(end)-freq_range(1))/n_min_ticks; 
                y_tick_step = interp1(y_tick_step_options,y_tick_step_options,axis_ticks_optimal,'nearest');
                 
                y_ticks = [y_tick_step*ceil(freq_range(1)/y_tick_step):y_tick_step:y_tick_step*floor(freq_range(end)/y_tick_step)];
                UI.settings.spectrogram.y_ticks = y_ticks;
            else
                UI.settings.spectrogram.show = false;
                UI.panel.spectrogram.showSpectrogram.Value = 0;
                MsgLog('The spectrogram frequency range is not valid',4);
            end
        else
            UI.settings.spectrogram.show = false;
        end
        initTraces
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
            column1 = num2cell(column1);
        end
        if isnumeric(column2)
            column2 = num2cell(column2);
        end
        dataTable(:,2) = cellstr(num2str(UI.params.subsetTable'));
        dataTable(:,3) = column1;
        dataTable(:,4) = column2;
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
                    if ~isempty(UI.selectedUnits)
                        generate_cell_metrics_table(data.cell_metrics, UI.selectedUnits);
                    else
                        generate_cell_metrics_table(data.cell_metrics);
                    end
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
            if UI.settings.showSpikes
                UI.panel.spikes.setSpikesYData.Enable = 'on';
            end
            if UI.settings.useMetrics
                UI.panel.cell_metrics.sortingMetric.Enable = 'on';
            end
        else
            UI.settings.spikesBelowTrace = false;
            UI.panel.spikes.setSpikesYData.Enable = 'off';
            UI.panel.cell_metrics.sortingMetric.Enable = 'off';
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
            try
                UI.settings.useSpikesYData = true;
                if numel(data.spikes.times)>0
                    switch UI.settings.spikesYDataType{UI.panel.spikes.setSpikesYData.Value}
                        case 'double'
                            groups = [];
                            [~,order1] = sort(data.spikes.(UI.settings.spikesYData),'descend');
                            [~,order2] = sort(order1);
                            for i = 1:numel(data.spikes.(UI.settings.spikesYData))
                                groups = [groups,order2(i)*ones(1,data.spikes.total(i))]; % from cell to array
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
            catch
                UI.settings.useSpikesYData = false;
                UI.panel.spikes.setSpikesYData.Value = 1;
                warning('Failed to set sorting')
            end
        else
            UI.settings.useSpikesYData = false;
        end
        initTraces
        uiresume(UI.fig);
    end
        
    function showSpikeWaveforms(~,~)
        numeric_gt_0 = @(n) ~isempty(n) && isnumeric(n) && (n > 0) && (n <= 1); % numeric and greater than 0 and less or equal than 1
        if UI.panel.spikes.showSpikeWaveforms.Value == 1 && isfield(data.session.extracellular,'chanCoords')
            UI.settings.showSpikeWaveforms = true;
        elseif UI.panel.spikes.showSpikeWaveforms.Value == 1
            UI.settings.showSpikeWaveforms = false;
            UI.panel.spikes.showSpikeWaveforms.Value = 0;
            warndlg('ChanCoords have not been defined for this session','Error')
        else
            UI.settings.showSpikeWaveforms = false;
        end
        if numeric_gt_0(str2double(UI.panel.spikes.waveformsRelativeWidth.String))
            UI.settings.waveformsRelativeWidth = str2double(UI.panel.spikes.waveformsRelativeWidth.String);
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function showSpikesPCAspace(~,~)
        numeric_gt_0 = @(n) ~isempty(n) && isnumeric(n) && (n > 0) && (n <= data.session.extracellular.nElectrodeGroups); % numeric and greater than 0 and less or equal than nElectrodes
        if UI.panel.spikes.showSpikesPCAspace.Value == 1
            UI.settings.showSpikesPCAspace = true;
        else
            UI.settings.showSpikesPCAspace = false;
        end
        PCA_electrodeGroup = str2double(UI.panel.spikes.PCA_electrodeGroup.String);
        if numeric_gt_0(PCA_electrodeGroup)
            UI.settings.PCAspace_electrodeGroup = ceil(PCA_electrodeGroup);
            UI.panel.spikes.PCA_electrodeGroup.String = num2str(UI.settings.PCAspace_electrodeGroup);
        else
            UI.settings.showSpikesPCAspace = false;
            UI.panel.spikes.showSpikesPCAspace.Value = 0;
            warndlg('The electrode group for the PCA space is not valid','Error')
        end        
        initTraces
        uiresume(UI.fig);
    end
        
    function showSpikeMatrix(~,~)
        if UI.panel.spikes.showSpikeMatrix.Value == 1
            UI.settings.showSpikeMatrix = true;
        else
            UI.settings.showSpikeMatrix = false;
        end
        uiresume(UI.fig);
    end

    function initTraces
        set(UI.fig,'Renderer','opengl');
        % Determining data offsets
        UI.offsets.intan    = 0.10 * (UI.settings.showTimeseriesBelowTrace & (UI.settings.intan_showAnalog | UI.settings.intan_showAux | UI.settings.intan_showDigital));
        UI.offsets.trials   = 0.02 * (UI.settings.showTrials);
        UI.offsets.behavior = 0.08 * (UI.settings.showBehaviorBelowTrace && UI.settings.plotBehaviorLinearized && UI.settings.showBehavior);
        UI.offsets.states   = 0.04 * (UI.settings.showStates);
        UI.offsets.spectrogram = 0.25 * (UI.settings.spectrogram.show);
        UI.offsets.events   = 0.04 * ((UI.settings.showEventsBelowTrace || UI.settings.processing_steps) && UI.settings.showEvents);
        UI.offsets.kilosort = 0.08 * (UI.settings.showKilosort && UI.settings.kilosortBelowTrace);
        UI.offsets.klusta = 0.08 * (UI.settings.showKlusta && UI.settings.klustaBelowTrace);
        UI.offsets.spykingcircus = 0.08 * (UI.settings.showSpykingcircus && UI.settings.spykingcircusBelowTrace);
        UI.offsets.spikes   = 0.08 * (UI.settings.spikesBelowTrace && UI.settings.showSpikes);
        UI.offsets.populationRate = 0.08 * (UI.settings.showSpikes && UI.settings.showPopulationRate && UI.settings.populationRateBelowTrace);
        UI.offsets.detectedSpikes = 0.08 * (UI.settings.detectSpikes && UI.settings.detectedSpikesBelowTrace);
        UI.offsets.detectedEvents = 0.08 * (UI.settings.detectEvents && UI.settings.detectedEventsBelowTrace);
        UI.offsets.spikeWaveforms = 0.25 * (UI.settings.showWaveformsBelowTrace && ( (UI.settings.showSpikeWaveforms && UI.settings.showSpikes) || (UI.settings.showDetectedSpikeWaveforms && UI.settings.detectSpikes) ) ); 
        
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
        UI.dataRange.ephys = [offset+UI.settings.ephys_padding,1-UI.settings.ephys_padding+offset*UI.settings.ephys_padding];
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
        
        % Filtering channel by channel list
        for j = 1:numel(UI.channels)
            [~,idx] = setdiff(UI.channels{j},UI.settings.channelList);
            UI.channels{j}(idx) = [];
        end
        
        % Filtering channels by brain region list
        for j = 1:numel(UI.channels)
            for k = 1:numel(UI.settings.brainRegionsToHide)
                channels = data.session.brainRegions.(UI.settings.brainRegionsToHide{k}).channels;
                UI.channels{j}(ismember(UI.channels{j},channels)) = [];
            end
        end
        
        % Filtering channels by channel coordinates
        for j = 1:numel(UI.channels)
            [~,idx] = setdiff(UI.channels{j},UI.settings.chanCoordsToPlot);
            UI.channels{j}(idx) = [];
        end
        
        channels = [UI.channels{UI.settings.electrodeGroupsToPlot}];
        if UI.settings.plotSorting == 1
            UI.channelOrder = sort([UI.channels{UI.settings.electrodeGroupsToPlot}]);
        elseif UI.settings.plotSorting == 2
            UI.channelOrder = [UI.channels{UI.settings.electrodeGroupsToPlot}];
%         elseif UI.settings.plotSorting == 3
%             
        end
        
        nChannelsToPlot = numel(UI.channelOrder);
        UI.channelMap = zeros(1,data.session.extracellular.nChannels);
        [idx, idx2]= ismember([data.session.extracellular.electrodeGroups.channels{:}],channels);
        [~,temp] = sort([data.session.extracellular.electrodeGroups.channels{:}]);
        channels_1 = [data.session.extracellular.electrodeGroups.channels{:}];
        UI.channelMap(channels_1(find(idx))) = channels(idx2(idx2~=0));
        padding = UI.settings.ephys_padding + 0.5./numel(UI.channelOrder);
        
        if nChannelsToPlot == 1
        	channelOffset = 0.5;
        elseif nChannelsToPlot == 0
            channelOffset = [];
        elseif UI.settings.extraSpacing && ~isempty(UI.settings.electrodeGroupsToPlot) && UI.settings.plotStyle < 5
            nChannelsInGroups = cellfun(@numel,UI.channels(UI.settings.electrodeGroupsToPlot));
            channelList = [];
%             channelList = (0:nChannelsInGroups(1)-1);
            for i = 1:numel(UI.settings.electrodeGroupsToPlot)
                channelList = [channelList,(0:nChannelsInGroups(i)-1)+numel(channelList)+i*1.5];
            end
            channelOffset = (channelList-1)/(channelList(end)-1)*(1-2*padding)*(1-offset)+padding*(1-offset);
        else
            channelOffset = [0:nChannelsToPlot-1]/(nChannelsToPlot-1)*(1-2*padding)*(1-offset)+padding*(1-offset);
        end
        UI.channelOffset = zeros(1,data.session.extracellular.nChannels);
        UI.channelOffset(UI.channelOrder) = channelOffset-1;
        UI.ephys_offset = offset;
        if UI.settings.plotStyle == 4
            UI.channelScaling = ones(ceil(UI.settings.windowDuration*data.session.extracellular.srLfp),1)*UI.channelOffset;
            UI.samplesToDisplay = UI.settings.windowDuration*data.session.extracellular.srLfp;
        else
            UI.channelScaling = ones(ceil(UI.settings.windowDuration*data.session.extracellular.sr),1)*UI.channelOffset;
            UI.samplesToDisplay = UI.settings.windowDuration*data.session.extracellular.sr;
        end

        UI.dispSamples = floor(linspace(1,UI.samplesToDisplay,UI.Pix_SS));
        UI.nDispSamples = numel(UI.dispSamples);
        UI.elements.lower.windowsSize.String = num2str(UI.settings.windowDuration);
        UI.elements.lower.scaling.String = num2str(UI.settings.scalingFactor);
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
        
        % Init data and UI settings
        UI.settings.stream = false;
        
        UI.track = true;
        UI.t_total = 0; % Length of the recording in seconds
        
        UI.settings.showKilosort = false;
        UI.settings.showKlusta = false;
        UI.settings.showSpykingcircus = false;
        UI.settings.normalClick = true;
        UI.settings.channelTags.hide = [];
        UI.settings.channelTags.filter = [];
        UI.settings.channelTags.highlight = [];
        UI.settings.showSpikes = false;
        UI.settings.useMetrics = false;
        UI.settings.showEvents = false;
        UI.settings.showTimeSeries = false;
        UI.settings.showStates = false;
        UI.settings.showBehavior = false;
        UI.settings.intan_showAnalog = false;
        UI.settings.intan_showAux = false;
        UI.settings.intan_showDigital = false;
        UI.settings.spectrogram.show = false;
        UI.panel.spikes.showSpikes.Value = 0;
        UI.panel.cell_metrics.useMetrics.Value = 0;
        UI.panel.spikes.populationRate.Value = 0;
        UI.panel.spikesorting.showKilosort.Value = 0;
        UI.panel.spikesorting.showKlusta.Value = 0;
        UI.panel.spikesorting.showSpykingcircus.Value = 0;
        UI.panel.events.showEvents.Value = 0;
        UI.panel.timeseries.show.Value = 0;
        UI.panel.states.showStates.Value = 0;
        UI.panel.behavior.showBehavior.Value = 0;
        UI.table.cells.Data = {};
        UI.listbox.cellTypes.String = {''};
        
        % Initialize the data
        UI.data.basepath = basepath;
        UI.data.basename = basename;
        cd(UI.data.basepath)
        
        if ~isfield(data,'session') && exist(fullfile(basepath,[basename,'.session.mat']),'file')
            data.session = loadSession(UI.data.basepath,UI.data.basename);
        elseif ~isfield(data,'session') && exist(fullfile(basepath,[basename,'.xml']),'file')
            data.session = sessionTemplate(UI.data.basepath,'showGUI',false,'basename',basename);
        elseif ~isfield(data,'session')
            data.session = sessionTemplate(UI.data.basepath,'showGUI',true,'basename',basename);
        end
        
        try
            UI.t0 = data.session.neuroScope2.t0;
            if UI.t0<0
                UI.t0=0;
            end
        end
        UI.t1 = UI.t0;
        UI.t0_track = UI.t0;
        
        % UI.settings.colormap
        UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);
        
        UI.settings.leastSignificantBit = data.session.extracellular.leastSignificantBit;
        UI.fig.UserData.leastSignificantBit = UI.settings.leastSignificantBit;
        
        UI.settings.precision = data.session.extracellular.precision;
        
        % Getting notes
        if isfield(data.session.general,'notes')
            UI.panel.notes.text.String = data.session.general.notes;
        end
        
        updateChannelGroupsList
        updateChannelTags
        updateChannelList
        updateBrainRegionList
        
        if data.session.extracellular.nElectrodeGroups<2
            UI.settings.extraSpacing = false;
            UI.panel.general.extraSpacing.Value = 0;
        end
        
        UI.fig.Name = ['NeuroScope2   -   session: ', UI.data.basename, ', basepath: ', UI.data.basepath];
        
        if isfield(data.session.extracellular,'fileName') && ~isempty(data.session.extracellular.fileName)
            UI.data.fileName = fullfile(basepath,data.session.extracellular.fileName);
        else
            UI.data.fileName = fullfile(basepath,[UI.data.basename '.dat']);
        end
        UI.fid.ephys = fopen(UI.data.fileName, 'r');
        s1 = dir(UI.data.fileName);
            
        if isfield(data.session.extracellular,'fileNameLFP') && ~isempty(data.session.extracellular.fileNameLFP)
            UI.data.fileNameLFP = fullfile(basepath,data.session.extracellular.fileNameLFP);
        elseif exist(fullfile(basepath,[UI.data.basename '.lfp']))
            UI.data.fileNameLFP = fullfile(basepath,[UI.data.basename '.lfp']);
        elseif exist(fullfile(basepath,[UI.data.basename '.eeg']))
            UI.data.fileNameLFP = fullfile(basepath,[UI.data.basename '.eeg']);
        else
            UI.data.fileNameLFP = fullfile(basepath,[UI.data.basename '.lfp']);
        end
        UI.fid.lfp = fopen(UI.data.fileNameLFP, 'r');
        s2 = dir(UI.data.fileNameLFP);
            
        if ~isfield(UI,'priority')
            UI.priority = 'dat';
        elseif strcmpi(UI.priority,'dat')
            UI.settings.plotStyle = 2;
            UI.panel.general.plotStyle.Value = UI.settings.plotStyle;
        elseif strcmpi(UI.priority,'lfp')
            UI.settings.plotStyle = 4;
            UI.panel.general.plotStyle.Value = UI.settings.plotStyle;
        end
        
        if ~isempty(s1) && ~strcmp(UI.priority,'lfp')
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
        
        % Timeseries files
        updateTimeSeriesDataList
        
        % Generating epoch interval-visualization
        delete(UI.epochAxes.Children)
        if isfield(data.session,'epochs')
            epochVisualization(data.session.epochs,UI.epochAxes,0,1); 
            if UI.t_total>0
                set(UI.epochAxes,'XLim',[0,UI.t_total])
            end
        end
        
        % Generating Probe layout visualization (Channel coordinates)
        UI.settings.chanCoordsToPlot = 1:data.session.extracellular.nChannels;
        delete(UI.chanCoordsAxes.Children)
        if isfield(data.session.extracellular,'chanCoords') && ~isempty(data.session.extracellular.chanCoords.x) && ~isempty(data.session.extracellular.chanCoords.y)
            chanCoordsVisualization(data.session.extracellular.chanCoords,UI.chanCoordsAxes);
            updateChanCoordsColorHighlight
            
            image_toolbox_installed = isToolboxInstalled('Image Processing Toolbox');
            if ~verLessThan('matlab', '9.4') & image_toolbox_installed
                x_lim_data = [min(data.session.extracellular.chanCoords.x),max(data.session.extracellular.chanCoords.x)];
                y_lim_data = [min(data.session.extracellular.chanCoords.y),max(data.session.extracellular.chanCoords.y)];
                x_padding = 0.03*diff(x_lim_data);
                y_padding = 0.03*diff(y_lim_data);
                UI.plotpoints.roi_ChanCoords = drawrectangle(UI.chanCoordsAxes,'Position',[x_lim_data(1)-x_padding,y_lim_data(1)-y_padding,1.06*diff(x_lim_data),1.06*diff(y_lim_data)],'LineWidth',2,'FaceAlpha',0.1,'Deletable',false,'FixedAspectRatio',false);
                addlistener(UI.plotpoints.roi_ChanCoords,'ROIMoved',@updateChanCoordsPlot);
            end
        end
        
        setRecentSessions
    end
    
    function setRecentSessions
        if isdeployed
            CellExplorer_path = pwd;
        else
            [CellExplorer_path,~,~] = fileparts(which('CellExplorer.m'));
            CellExplorer_path = fullfile(CellExplorer_path,'calc_CellMetrics');
        end
        if exist(fullfile(CellExplorer_path,'data_NeuroScope2.mat'))
            load(fullfile(CellExplorer_path,'data_NeuroScope2.mat'),'recentSessions');
            sameSession = (ismember(recentSessions.basepaths,basepath) & ismember(recentSessions.basenames,basename));
            recentSessions.basepaths(sameSession) = [];
            recentSessions.basenames(sameSession) = [];
            recentSessions.basepaths{end+1} = basepath;
            recentSessions.basenames{end+1} = basename;
        else
            recentSessions.basepaths{1} = basepath;
            recentSessions.basenames{1} = basename;
        end
        if ~verLessThan('matlab', '9.3')
            menuLabel = 'Text';
            menuSelectedFcn = 'MenuSelectedFcn';
        else
            menuLabel = 'Label';
            menuSelectedFcn = 'Callback';
        end
        if isfield(UI.menu.file.recentSessions,'ops')
            delete(UI.menu.file.recentSessions.ops);
            UI.menu.file.recentSessions.ops = [];
        end
        for i = 1:min([numel(recentSessions.basepaths),15])
            UI.menu.file.recentSessions.ops(i) = uimenu(UI.menu.file.recentSessions.main,menuLabel,fullfile(recentSessions.basepaths{end-i+1}, recentSessions.basenames{end-i+1}),menuSelectedFcn,@loadFromRecentFiles);
        end
        try
            save(fullfile(CellExplorer_path,'data_NeuroScope2.mat'),'recentSessions');
        end
    end

    function moveSlider(src,~)
        UI.settings.stream = false;
        s1 = dir(UI.data.fileName);
        s2 = dir(UI.data.fileNameLFP);
        if ~isempty(s1)
            filesize = s1.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.sr*2);
        elseif ~isempty(s2)
            filesize = s2.bytes;
            UI.t_total = filesize/(data.session.extracellular.nChannels*data.session.extracellular.srLfp*2);
        end
    end
    
    function movingSlider(src,evnt)
        if gco == UI.elements.lower.slider
            UI.t0 = valid_t0((UI.t_total-UI.settings.windowDuration)*evnt.AffectedObject.Value/100);
            UI.elements.lower.time.String = num2str(UI.t0);
            
            UI.selectedChannels = [];
            UI.selectedUnits = [];
            
            % Plotting data
            plotData;
            
            % Updating epoch axes
            if ishandle(epoch_plotElements.t0)
                delete(epoch_plotElements.t0)
            end
            epoch_plotElements.t0 = line(UI.epochAxes,[UI.t0,UI.t0],[0,1],'color','k', 'HitTest','off','linewidth',1);
            UI.settings.stream = false;
        end
    end

    function ClickPlot(~,~)
        UI.settings.stream = false;
        % handles clicks on the main axes
        switch get(UI.fig, 'selectiontype')
            case 'normal' % left mouse button
                
                % Adding new event
                if UI.settings.addEventonClick
                    um_axes = get(UI.plot_axis1,'CurrentPoint');
                    t_event = um_axes(1,1)+UI.t0;
                    data.events.(UI.settings.eventData).added = unique([data.events.(UI.settings.eventData).added;t_event]);
                    UI.elements.lower.performance.String = ['Event added: ',num2str(t_event),' sec'];
                    UI.settings.addEventonClick = false;
                    uiresume(UI.fig);
                else % Otherwise show cursor time
                    um_axes = get(UI.plot_axis1,'CurrentPoint');
                    UI.elements.lower.performance.String = ['Cursor: ',num2str(um_axes(1,1)+UI.t0),' sec'];
                end
                
            case 'alt' % right mouse button
                
                % Removing/flagging events
                if UI.settings.addEventonClick && ~isempty(data.events.(UI.settings.eventData).added)
                    idx3 = find(data.events.(UI.settings.eventData).added >= UI.t0 & data.events.(UI.settings.eventData).added <= UI.t0+UI.settings.windowDuration);
                    if any(idx3)
                        um_axes = get(UI.plot_axis1,'CurrentPoint');
                        t_event = um_axes(1,1)+UI.t0;
                        eventsInWindow = data.events.(UI.settings.eventData).added(idx3);
                        [~,idx] = min(abs(eventsInWindow-t_event));
                        t_event = data.events.(UI.settings.eventData).added(idx3(idx));
                        data.events.(UI.settings.eventData).added(idx3(idx)) = [];
                        UI.elements.lower.performance.String = ['Event deleted: ',num2str(t_event),' sec'];
                        UI.settings.addEventonClick = false;
                        uiresume(UI.fig);
                    else
                        UI.settings.addEventonClick = false;
                        uiresume(UI.fig);
                    end
                end
                
            case 'extend' % middle mouse button
                um_axes = get(UI.plot_axis1,'CurrentPoint');
                if UI.settings.normalClick
                    channels = sort([UI.channels{UI.settings.electrodeGroupsToPlot}]);
                    x1 = (ones(size(ephys.traces(:,channels),2),1)*[1:size(ephys.traces(:,channels),1)]/size(ephys.traces(:,channels),1)*UI.settings.windowDuration)';
                    y1 = (ephys.traces(:,channels)-UI.channelOffset(channels));
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
                        highlightUnits(UID,UI.t0,UI.t0+UI.settings.windowDuration);
                        UI.selectedUnits = unique([UID,UI.selectedUnits],'stable');
                        UI.elements.lower.performance.String = ['Unit(s) selected: ',num2str(UI.selectedUnits)];
                    end
                end
                
            case 'open'
                resetZoom
                
            otherwise
                um_axes = get(UI.plot_axis1,'CurrentPoint');
                UI.elements.lower.performance.String = ['Cursor: ',num2str(um_axes(1,1)+UI.t0),' sec'];
        end
    end
    
    function ClickEpochs(~,~)
        UI.settings.stream = false;
        um_axes = get(UI.epochAxes,'CurrentPoint');
        t0_CurrentPoint = um_axes(1,1);
        
        switch get(UI.fig, 'selectiontype')
            case 'normal' % left mouse button
                
                % t0
                UI.t0 = t0_CurrentPoint;
                uiresume(UI.fig);
                
            case 'alt' % right mouse button
                
                % Onset of selected epoch
                t_startTimes = [];
                for i = 1:numel(data.session.epochs)
                    if isfield(data.session.epochs{i},'startTime')
                        t_startTimes(i) = data.session.epochs{i}.startTime;
                    else
                        t_startTimes(i) = 0;
                    end
                end
                t_startTimes = t_startTimes(t_startTimes < t0_CurrentPoint);
                if ~isempty(t_startTimes)
                    UI.t0 = max(t_startTimes);
                    uiresume(UI.fig);
                end
                
            case 'extend' % middle mouse button
                
                % Goes to closest event
                try
                    t_events = data.events.(UI.settings.eventData).time;
                    [~,idx] = min(abs(t_events-t0_CurrentPoint));
                    UI.t0 = t_events(idx)-UI.settings.windowDuration/2;
                    uiresume(UI.fig);
                end
            case 'open' % double click
                
            otherwise
                
        end
    end
    
    function resetZoom
        if UI.settings.showChannelNumbers
            set(UI.plot_axis1,'XLim',[-0.015*UI.settings.windowDuration,UI.settings.windowDuration],'YLim',[0,1])
        else
            set(UI.plot_axis1,'XLim',[0,UI.settings.windowDuration],'YLim',[0,1])
        end
    end
                
    function updateChanCoordsPlot(~,~)

        UI.settings.stream = false;
        pos = UI.plotpoints.roi_ChanCoords.Position;
        x1 = [pos(1),pos(1)+pos(3),pos(1)+pos(3),pos(1)];
        y1 = [pos(2),pos(2),pos(2)+pos(4),pos(2)+pos(4)];
        UI.settings.chanCoordsToPlot = find(inpolygon(data.session.extracellular.chanCoords.x,data.session.extracellular.chanCoords.y, x1 ,y1));
        
        updateChanCoordsColorHighlight
        initTraces
        uiresume(UI.fig);
    end
    
    function updateChanCoordsColorHighlight
        if isfield(data.session.extracellular,'chanCoords')
            try
                delete(UI.plotpoints.chanCoords)
            end
            for fn = 1:data.session.extracellular.nElectrodeGroups
                channels = intersect(data.session.extracellular.electrodeGroups.channels{fn},UI.settings.chanCoordsToPlot,'stable');
                if ~isempty(channels)
                    UI.plotpoints.chanCoords(fn) = line(UI.chanCoordsAxes,data.session.extracellular.chanCoords.x(channels),data.session.extracellular.chanCoords.y(channels),'color',0.8*UI.colors(fn,:),'Marker','.','linestyle','none','HitTest','off','markersize',10);
                end
            end
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
    
    function editBrainregionList(~,~)
        brainRegions = fieldnames(data.session.brainRegions);
        UI.settings.brainRegionsToHide = brainRegions(~[UI.table.brainRegions.Data{:,1}]);
        initTraces
        uiresume(UI.fig);
    end
    
    function buttonChannelList(~,~)
        channelOrder = [data.session.extracellular.electrodeGroups.channels{:}];
        UI.settings.channelList = channelOrder(UI.listbox.channelList.Value);
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
        % Change colors of electrode groups
        if ~isempty(evnt.Indices) && size(evnt.Indices,1) == 1 && evnt.Indices(2) == 2
            colorpick = UI.colors(evnt.Indices(1),:);
            colorpick = userSetColor(colorpick,'Electrode group color');
            UI.colors(evnt.Indices(1),:) = colorpick;
            classColorsHex = rgb2hex(UI.colors);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            colored_string = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            UI.table.electrodeGroups.Data{evnt.Indices(1),2} = colored_string{evnt.Indices(1)};
            initTraces
            updateChannelList
            updateChanCoordsColorHighlight
            uiresume(UI.fig);
        end
    end

    function ClicktoSelectFromTable2(~,evnt)
        if ~isempty(evnt.Indices) && size(evnt.Indices,1) == 1 && evnt.Indices(2) == 1
            colorpick = UI.colors_tags(evnt.Indices(1),:);
            colorpick = userSetColor(colorpick,'Channel tag color');
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
        UI.settings.greyScaleTraces = UI.panel.general.colorScale.Value;
        uiresume(UI.fig);
    end

    function plotEnergy(~,~)
        if  UI.panel.general.plotEnergy.Value==1
            UI.settings.plotEnergy = true;
        else
            UI.settings.plotEnergy = false;
        end
        answer = UI.panel.general.energyWindow.String;
        if  ~isempty(answer) & isnumeric(str2num(answer))
            UI.settings.energyWindow = str2num(answer);
        end
        uiresume(UI.fig);
    end

    function extraSpacing(~,~)
        if UI.panel.general.extraSpacing.Value == 1
            UI.settings.extraSpacing = true;
        else
            UI.settings.extraSpacing = false;
        end
        initTraces
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
            if int_gt_0(UI.settings.filter.lowerBand,data.session.extracellular.sr) && int_gt_0(UI.settings.filter.higherBand,data.session.extracellular.sr) 
                UI.settings.filterTraces = false;
            elseif int_gt_0(UI.settings.filter.lowerBand,data.session.extracellular.sr) && ~int_gt_0(UI.settings.filter.higherBand,data.session.extracellular.sr)
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, UI.settings.filter.higherBand/(data.session.extracellular.sr/2), 'low');
            elseif int_gt_0(UI.settings.filter.higherBand,data.session.extracellular.sr) && ~int_gt_0(UI.settings.filter.lowerBand,data.session.extracellular.sr)
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, UI.settings.filter.lowerBand/(data.session.extracellular.sr/2), 'high');
            else
                [UI.settings.filter.b1, UI.settings.filter.a1] = butter(3, [UI.settings.filter.lowerBand,UI.settings.filter.higherBand]/(data.session.extracellular.sr/2), 'bandpass');
            end
        end
        uiresume(UI.fig);
    end

    function updateChannelGroupsList
        % Updates the list of electrode groups
        
        if isfield(data.session.extracellular,'electrodeGroups')
            tableData = {};
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
    
    function updateChannelList
        if isfield(data.session.extracellular,'electrodeGroups')
            
            UI.settings.channelList = [data.session.extracellular.electrodeGroups.channels{:}];
            colored_string = DefineChannelListColors;
            UI.listbox.channelList.String = colored_string(UI.settings.channelList);
            UI.listbox.channelList.Max = numel(UI.settings.channelList);
            UI.listbox.channelList.Value = 1:numel(UI.settings.channelList);
        else
            UI.settings.channelList = [];
            UI.listbox.channelList.String = {''};
            UI.listbox.channelList.Max = 1;
            UI.listbox.channelList.Value = 1;
        end
        
        function colored_string = DefineChannelListColors
            groupColorsHex = rgb2hex(UI.colors*0.7);
            groupColorsHex = cellstr(groupColorsHex(:,2:end));
            channelColorsHex = repmat({''},numel(UI.settings.channelList),1);
            for fn = 1:size(groupColorsHex,1)
                channelColorsHex(data.session.extracellular.electrodeGroups.channels{fn}) = groupColorsHex(fn);
            end
            
            classNumbers = cellstr(num2str([1:length(UI.settings.channelList)]'));
            classNumbers = regexprep(classNumbers, ' ', '&nbsp;&nbsp;');
            colored_string = strcat('<html><BODY bgcolor="',channelColorsHex,'">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="white">Channel&nbsp;&nbsp;', classNumbers, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</font></BODY>',classNumbers, '.&nbsp;</html>');
        end
    end
    
    function updateBrainRegionList
        if isfield(data.session,'brainRegions') & ~isempty(data.session.brainRegions)
            brainRegions = fieldnames(data.session.brainRegions);
            tableData = {};
            for fn = 1:numel(brainRegions)
                tableData{fn,1} = true;
                tableData{fn,2} = brainRegions{fn};
                tableData{fn,3} = [num2str(data.session.brainRegions.(brainRegions{fn}).channels)];
                tableData{fn,4} = [num2str(data.session.brainRegions.(brainRegions{fn}).electrodeGroups)];
            end
            UI.settings.brainRegionsToHide = [];
        else
            tableData = {false,'','',''};
        end
        UI.table.brainRegions.Data =  tableData;
    end
    
    function updateTimeSeriesDataList
        if isfield(data.session,'timeSeries') & ~isempty(data.session.timeSeries)
            timeSeries = fieldnames(data.session.timeSeries);
            tableData = {};
            for fn = 1:numel(timeSeries)
                tableData{fn,1} = false;
                tableData{fn,2} = timeSeries{fn};
                tableData{fn,3} = (data.session.timeSeries.(timeSeries{fn}).fileName);
                tableData{fn,4} = [num2str(data.session.timeSeries.(timeSeries{fn}).nChannels)];
                
                % Defining channel labels
                UI.settings.traceLabels.(timeSeries{fn}) = strcat(repmat({timeSeries{fn}},data.session.timeSeries.(timeSeries{fn}).nChannels,1),num2str([1:data.session.timeSeries.(timeSeries{fn}).nChannels]'));
                if isfield(data.session,'inputs')
                    inputs = fieldnames(data.session.inputs);
                    for i = 1:numel(inputs)
                        try
                            UI.settings.traceLabels.(timeSeries{fn})(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.(timeSeries{fn}){data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
                        end
                    end
                end
            end
        else
            tableData = {false,'','',''};
        end
        UI.table.timeseriesdata.Data =  tableData;
        
%         if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'adc')
%             % Defining adc channel labels
%             UI.settings.traceLabels.adc = strcat(repmat({'adc'},data.session.timeSeries.adc.nChannels,1),num2str([1:data.session.timeSeries.adc.nChannels]'));
%             if isfield(data.session,'inputs')
%                 inputs = fieldnames(data.session.inputs);
%                 for i = 1:numel(inputs)
%                     if strcmp(data.session.inputs.(inputs{i}).inputType,'adc')
%                         UI.settings.traceLabels.adc(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.adc{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
%                     end
%                 end
%             end
%         else
%             UI.panel.intan.filenameAnalog.String = '';
%         end
%         if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'aux')
%             UI.panel.intan.filenameAux.String = data.session.timeSeries.aux.fileName;
%             % Defining aux channel labels
%             UI.settings.traceLabels.aux = strcat(repmat({'aux'},data.session.timeSeries.aux.nChannels,1),num2str([1:data.session.timeSeries.aux.nChannels]'));
%             if isfield(data.session,'inputs')
%                 inputs = fieldnames(data.session.inputs);
%                 for i = 1:numel(inputs)
%                     if strcmp(data.session.inputs.(inputs{i}).inputType,'aux') && ~isempty(data.session.inputs.(inputs{i}).channels) && data.session.inputs.(inputs{i}).channels <= numel(UI.settings.traceLabels.aux)
%                         UI.settings.traceLabels.aux(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.aux{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
%                     end
%                 end
%             end
%         else
%             UI.panel.intan.filenameAux.String = '';
%         end
%         
%         if isfield(data.session,'timeSeries') && isfield(data.session.timeSeries,'dig')
%             UI.panel.intan.filenameDigital.String = data.session.timeSeries.dig.fileName;
%             % Defining dig channel labels
%             UI.settings.traceLabels.dig = strcat(repmat({'dig'},data.session.timeSeries.dig.nChannels,1),num2str([1:data.session.timeSeries.dig.nChannels]'));
%             if isfield(data.session,'inputs')
%                 inputs = fieldnames(data.session.inputs);
%                 for i = 1:numel(inputs)
%                     if strcmp(data.session.inputs.(inputs{i}).inputType,'dig') && ~isempty(data.session.inputs.(inputs{i}).channels)
%                         UI.settings.traceLabels.dig(data.session.inputs.(inputs{i}).channels) = {[UI.settings.traceLabels.dig{data.session.inputs.(inputs{i}).channels},': ',inputs{i}]};
%                     end
%                 end
%             end
%         else
%             UI.panel.intan.filenameDigital.String = '';
%         end
    end

    function updateChannelTags
        % Updates the list of channelTags
        tableData = {};
        if isfield(data.session,'channelTags') && length(fieldnames(data.session.channelTags))>0
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
            UI.table.channeltags.Data =  {''};
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
        initTraces
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
        initTraces
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
        if ishandle(epoch_plotElements.events)
            delete(epoch_plotElements.events)
        end
        
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
            UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
            UI.panel.events.showEvents.Value = 1;
            UI.panel.events.eventCount.String = ['nEvents: ' num2str(numel(data.events.(UI.settings.eventData).time))];
            if ~isfield(data.events.(UI.settings.eventData),'flagged')
                data.events.(UI.settings.eventData).flagged = [];
            end
            UI.panel.events.flagCount.String = ['nFlags: ', num2str(numel(data.events.(UI.settings.eventData).flagged))];
            t_stamps = data.events.(UI.settings.eventData).time;
            epoch_plotElements.events = line(UI.epochAxes,t_stamps,0.1*ones(size(t_stamps)),'color',UI.settings.primaryColor, 'HitTest','off','Marker',UI.settings.rasterMarker,'LineStyle','none');
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
        initTraces
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
        if UI.settings.showEvents
            idx = 1:numel(data.events.(UI.settings.eventData).time);
            UI.settings.iEvent1 = find(data.events.(UI.settings.eventData).time(idx)>UI.t0+UI.settings.windowDuration/2,1);
            UI.settings.iEvent = idx(UI.settings.iEvent1);
            if ~isempty(UI.settings.iEvent)
                UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
                UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end

    function gotoEvents(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents
            UI.settings.iEvent = str2num(UI.panel.events.eventNumber.String);
            if ~isempty(UI.settings.iEvent) && isnumeric(UI.settings.iEvent) && UI.settings.iEvent <= numel(data.events.(UI.settings.eventData).time) && UI.settings.iEvent > 0
                UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
                UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end
    function previousEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents
            idx = 1:numel(data.events.(UI.settings.eventData).time);
            UI.settings.iEvent1 = find(data.events.(UI.settings.eventData).time(idx)<UI.t0+UI.settings.windowDuration/2,1,'last');
            UI.settings.iEvent = idx(UI.settings.iEvent1);
            if ~isempty(UI.settings.iEvent)
                UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
                UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end

    function randomEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents
            UI.settings.iEvent = ceil(numel(data.events.(UI.settings.eventData).time)*rand(1));
            UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
            UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function nextPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if isfield(data.events.(UI.settings.eventData),'peakNormedPower')
            [~,idx] = sort(data.events.(UI.settings.eventData).peakNormedPower,'descend');
            test = find(idx==UI.settings.iEvent);
            if ~isempty(test) && test < numel(idx) && test >= 1
                UI.settings.iEvent = idx(test+1);
                UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
                UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end

    function previousPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if isfield(data.events.(UI.settings.eventData),'peakNormedPower')
            [~,idx] = sort(data.events.(UI.settings.eventData).peakNormedPower,'descend');
            test = find(idx==UI.settings.iEvent);
            if ~isempty(test) &&  test <= numel(idx) && test > 1
                UI.settings.iEvent = idx(test-1);
                UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
                UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
                uiresume(UI.fig);
            end
        end
    end

    function maxPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents && isfield(data.events.(UI.settings.eventData),'peakNormedPower')
            [~,UI.settings.iEvent] = max(data.events.(UI.settings.eventData).peakNormedPower);
            UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
            UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end

    function minPowerEvent(~,~)
        UI.settings.stream = false;
        if ~UI.settings.showEvents
            showEvents
        end
        if UI.settings.showEvents && isfield(data.events.(UI.settings.eventData),'peakNormedPower')
            [~,UI.settings.iEvent] = min(data.events.(UI.settings.eventData).peakNormedPower);
            UI.panel.events.eventNumber.String = num2str(UI.settings.iEvent);
            UI.t0 = data.events.(UI.settings.eventData).time(UI.settings.iEvent)-UI.settings.windowDuration/2;
            uiresume(UI.fig);
        end
    end
    
    function flagEvent(~,~)
        UI.settings.stream = false;
        if UI.settings.showEvents
            if ~isfield(data.events.(UI.settings.eventData),'flagged')
                data.events.(UI.settings.eventData).flagged = [];
            end
            idx = find(data.events.(UI.settings.eventData).time==UI.t0+UI.settings.windowDuration/2);
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
            UI.streamingText = text(UI.plot_axis1,UI.settings.windowDuration/2,1,'Left click axes to add event - right click event to delete/flag','FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','center','color',UI.settings.primaryColor);
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
    
    function openCellExplorer(~,~)
        if isfield(data,'cell_metrics')
            data.cell_metrics = CellExplorer('metrics',data.cell_metrics);
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
        UI.settings.behaviorData = UI.panel.behavior.files.String{UI.panel.behavior.files.Value};
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
            idx = find(timestamps<UI.t0,1,'last');
            if ~isempty(idx)
                UI.t0 = timestamps(idx);
                UI.panel.states.statesNumber.String = num2str(idx);
                uiresume(UI.fig);
            end
        end
    end

    function nextStates(~,~)
        UI.settings.stream = false;
        if UI.settings.showStates
            timestamps = getTimestampsFromStates;
            idx = find(timestamps>UI.t0,1);
            if ~isempty(idx)
                UI.t0 = timestamps(idx);
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
                UI.t0 = timestamps(idx);
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

    function showBehavior(~,~) % Behavior (CellExplorer/buzcode)
        if UI.settings.showBehavior
            UI.settings.showBehavior = false;
            UI.panel.behavior.showBehavior.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.behaviorData,'.behavior.mat']),'file')
            if ~isfield(data,'behavior') || ~isfield(data.behavior,UI.settings.behaviorData)
                temp = loadStruct(UI.settings.behaviorData,'behavior','session',data.session);
                if ~isfield(temp,'timestamps')
                    MsgLog('Failed to load behavior data',4);
                    UI.panel.behavior.showBehavior.Value = 0;
                    return
                end
                data.behavior.(UI.settings.behaviorData) = temp;
                data.behavior.(UI.settings.behaviorData).limits.x = [min(data.behavior.(UI.settings.behaviorData).position.x),max(data.behavior.(UI.settings.behaviorData).position.x)];
                data.behavior.(UI.settings.behaviorData).limits.y = [min(data.behavior.(UI.settings.behaviorData).position.y),max(data.behavior.(UI.settings.behaviorData).position.y)];
                if ~isfield(data.behavior.(UI.settings.behaviorData).limits,'linearized') && isfield(data.behavior.(UI.settings.behaviorData).position,'linearized')
                    data.behavior.(UI.settings.behaviorData).limits.linearized = [min(data.behavior.(UI.settings.behaviorData).position.linearized),max(data.behavior.(UI.settings.behaviorData).position.linearized)];
                end
                if ~isfield(data.behavior.(UI.settings.behaviorData),'sr')
                    data.behavior.(UI.settings.behaviorData).sr = 1/diff(data.behavior.(UI.settings.behaviorData).timestamps(1:2));
                end
            end
            UI.settings.showBehavior = true;
            UI.panel.behavior.showBehavior.Value = 1;
        end
        initTraces
        uiresume(UI.fig);
    end

    function nextBehavior(~,~)
        UI.settings.stream = false;
        if UI.settings.showBehavior
            UI.t0 = data.behavior.(UI.settings.behaviorData).timestamps(end)-UI.settings.windowDuration;
            uiresume(UI.fig);
        end
    end
    
    function previousBehavior(~,~)
        UI.settings.stream = false;
        if UI.settings.showBehavior
            UI.t0 = data.behavior.(UI.settings.behaviorData).timestamps(1);
            uiresume(UI.fig);
        end
    end
    
    function initAnalysisToolsMenu
        if ~verLessThan('matlab', '9.3')
            menuLabel = 'Text';
            menuSelectedFcn = 'MenuSelectedFcn';
        else
            menuLabel = 'Label';
            menuSelectedFcn = 'Callback';
        end
        
        analysisTools = what('analysis_tools');
        analysisToolsPackages = analysisTools.packages;
        
        for j = 1:length(analysisToolsPackages)
            analysisTools = what(['analysis_tools/',analysisToolsPackages{j}]);
            analysisToolsOptions = cellfun(@(X) X(1:end-2),analysisTools.m,'UniformOutput', false);
            analysisToolsOptions(strcmpi(analysisToolsOptions,'wrapper_example')) = [];
            if ~isempty(analysisToolsOptions)
                UI.menu.analysis.(analysisToolsPackages{j}).topMenu = uimenu(UI.menu.analysis.topMenu,menuLabel,analysisToolsPackages{j});
                for i = 1:length(analysisToolsOptions)
                    UI.menu.analysis.(analysisToolsPackages{j}).(analysisToolsOptions{i}) = uimenu(UI.menu.analysis.(analysisToolsPackages{j}).topMenu,menuLabel,analysisToolsOptions{i},menuSelectedFcn,@analysis_wrapper);
                end
            end
        end
    end

    function summaryFigure(~,~)
        UI.settings.stream = false;
        % Spike data
        summaryfig = figure('name','Summary figure','Position',[50 50 1200 900],'visible','off');
        ax1 = axes(summaryfig,'XLim',[0,UI.t_total],'title','Summary figure','YLim',[0,1],'YTickLabel',[],'Color',UI.settings.background,'Position',[0.05 0.07 0.9 0.88],'XColor','k','TickDir','out'); hold on, 
        xlabel('Time (s)')
        
        if UI.settings.showSpikes
            dataRange_spikes = UI.dataRange.spikes;
            temp = reshape(struct2array(UI.dataRange),2,[]);
            if ~UI.settings.spikesBelowTrace && ~isempty(temp(2,temp(2,:)<1))
                UI.dataRange.spikes(1) = max(temp(2,temp(2,:)<1));
            end
            UI.dataRange.spikes(2) = 0.97;
            spikesBelowTrace = UI.settings.spikesBelowTrace;
            UI.settings.spikesBelowTrace = true;
            
            plotSpikeData(0,UI.t_total,UI.settings.primaryColor,ax1)
            
            UI.dataRange.spikes = dataRange_spikes;
            UI.settings.spikesBelowTrace = spikesBelowTrace;
            
            if UI.settings.useSpikesYData
                spikes_sorting = UI.settings.spikesYData;
            elseif UI.settings.useMetrics
                spikes_sorting = UI.params.sortingMetric;
            else
                spikes_sorting = 'UID';
            end
            ylabel(['Neurons (sorting / ydata: ' spikes_sorting,')'],'interpreter','none'), 
        end
        
        % KiloSort data
        if UI.settings.showKilosort
            plotKilosortData(UI.t0,UI.t0+UI.settings.windowDuration,'c')
        end
        
        % Klusta data
        if UI.settings.showKlusta
            plotKlustaData(UI.t0,UI.t0+UI.settings.windowDuration,'c')
        end
        
        % Spykingcircus data
        if UI.settings.showSpykingcircus
            plotSpykingcircusData(UI.t0,UI.t0+UI.settings.windowDuration,'c')
        end
        
        % Event data
        if UI.settings.showEvents
            plotEventData(0,UI.t_total,UI.settings.primaryColor,'m')
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
            plotTrials(0,UI.t_total,UI.settings.primaryColor)
        end
        
        %Plotting epochs
        if isfield(data.session,'epochs')
            colors = 1-(1-lines(numel(data.session.epochs)))*0.7;
            for i = 1:numel(data.session.epochs)
                if isfield(data.session.epochs{i},'startTime') && isfield(data.session.epochs{i},'stopTime')
                    p1 = patch(ax1,[data.session.epochs{i}.startTime data.session.epochs{i}.stopTime  data.session.epochs{i}.stopTime data.session.epochs{i}.startTime],[0.990 0.990 0.999 0.999],colors(i,:),'EdgeColor',colors(i,:)*0.5,'HitTest','off');
                    alpha(p1,0.8);
                end
                if isfield(data.session.epochs{i},'startTime') && isfield(data.session.epochs{i},'name') && isfield(data.session.epochs{i},'behavioralParadigm')
                    text(data.session.epochs{i}.startTime,1,{data.session.epochs{i}.name;data.session.epochs{i}.behavioralParadigm},'color','k','VerticalAlignment', 'bottom','Margin',1,'interpreter','none','HitTest','off') % 
%                     text(ax1,data.session.epochs{i}.startTime,1,[' ',num2str(i)],'color','k','VerticalAlignment', 'top','Margin',1,'interpreter','none','HitTest','off','fontweight', 'bold')
                elseif isfield(data.session.epochs{i},'startTime') && isfield(data.session.epochs{i},'name')
                    text(ax1,data.session.epochs{i}.startTime,1,[' ',data.session.epochs{i}.name],'color','k','VerticalAlignment', 'bottom','Margin',1,'interpreter','none','HitTest','off','fontweight', 'bold')
                elseif isfield(data.session.epochs{i},'startTime')
                    text(ax1,data.session.epochs{i}.startTime,1,[' ',num2str(i)],'color','k','VerticalAlignment', 'bottom','Margin',1,'interpreter','none','HitTest','off','fontweight', 'bold')
                end
            end
        end
        
        % Plotting current timepoint
        plot([UI.t0;UI.t0],[ax1.YLim(1);ax1.YLim(2)],'--b'); 
        
        movegui(summaryfig,'center'), set(summaryfig,'visible','on')
    end
    
    function analysis_wrapper(src,~)
        out = analysis_tools.(src.Parent.Text).(src.Text)('ephys',ephys,'UI',UI,'data',data);
    end
    
    function plotCSD(~,~)
        % Current source density plot
        % Original code from FMA
        % By Michaël Zugaro
        timeLine = [1:size(ephys.traces,1)]/size(ephys.traces,1)*UI.settings.windowDuration;
        for iShanks = UI.settings.electrodeGroupsToPlot
            channels = UI.channels{iShanks};
            [~,ia,~] = intersect(UI.channelOrder,channels,'stable');
            channels = UI.channelOrder(ia);
            if numel(channels)>3
                y = ephys.traces(:,channels);
                y = y - repmat(mean(y),length(timeLine),1);
                d = -diff(y,2,2);
                d = interp2(d);
                
                d = d(1:2:size(d,1),:);
                %
                markerColor = UI.colors(iShanks,:);
                multiplier = -linspace(max(UI.channelOffset(channels)),min(UI.channelOffset(channels)),size(d,2));
                pcolor(UI.plot_axis1,timeLine,multiplier,flipud(transpose(d)));
            end
        end

        set(UI.plot_axis1,'clim',[-0.05 0.05])
        shading interp;
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
            try
                UI.panel.behavior.trialCount.String = ['nTrials: ' num2str(data.behavior.trials.nTrials)];
            end
        end
        initTraces
        uiresume(UI.fig);
    end

    function nextTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = find(data.behavior.trials.start>UI.t0,1);
            if isempty(idx)
                idx = 1;
            end
            UI.t0 = data.behavior.trials.start(idx);
            UI.panel.behavior.trialNumber.String = num2str(idx);
            uiresume(UI.fig);
        end
    end

    function previousTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = find(data.behavior.trials.start<UI.t0,1,'last');
            if isempty(idx)
                idx = numel(data.behavior.trials.start);
            end
            UI.t0 = data.behavior.trials.start(idx);
            UI.panel.behavior.trialNumber.String = num2str(idx);
            uiresume(UI.fig);
        end
    end

    function gotoTrial(~,~)
        UI.settings.stream = false;
        if UI.settings.showTrials
            idx = str2num(UI.panel.behavior.trialNumber.String);
            if ~isempty(idx) && isnumeric(idx) && idx>0 && idx<=numel(data.behavior.trials.start)
                UI.t0 = data.behavior.trials.start(idx);
                uiresume(UI.fig);
            end
        end
        
    end
    
    function tooglePopulationRate(src,~)
        if UI.panel.spikes.populationRate.Value == 1
            UI.settings.showPopulationRate = true;
            if isnumeric(str2num(UI.panel.spikes.populationRateWindow.String))
                UI.settings.populationRateWindow = str2num(UI.panel.spikes.populationRateWindow.String);
            end
            if isnumeric(str2num(UI.panel.spikes.populationRateSmoothing.String))
                UI.settings.populationRateSmoothing = str2num(UI.panel.spikes.populationRateSmoothing.String);
            end
            if UI.panel.spikes.populationRateBelowTrace.Value == 1
               UI.settings.populationRateBelowTrace = true;
            else
                UI.settings.populationRateBelowTrace = false;
            end
        else
            UI.settings.showPopulationRate = false;
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function showKilosort(~,~)
        if UI.panel.spikesorting.showKilosort.Value == 1 && ~isfield(data,'spikes_kilosort')
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
                    try
                        [~,spikes.maxWaveformCh1(UID)] = max(abs(rez.U(:,rez.iNeigh(1,spike_clusters(i)),1)));
                    end
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
                UI.panel.spikesorting.showKilosort.Value = 0;
            end
        elseif UI.panel.spikesorting.showKilosort.Value == 1  && isfield(data,'spikes_kilosort')
            UI.settings.showKilosort = true;
            uiresume(UI.fig);
        else
            UI.settings.showKilosort = false;
            uiresume(UI.fig);
        end
        if UI.panel.spikesorting.kilosortBelowTrace.Value == 1
            UI.settings.kilosortBelowTrace = true;
        else
            UI.settings.kilosortBelowTrace = false;
        end
        initTraces
    end
    
    function showKlusta(~,~)
        if UI.panel.spikesorting.showKlusta.Value == 1 && ~isfield(data,'spikes_klusta')
            [file,path] = uigetfile('*.xml','Please select the klustakwik xml file for this session');
            if ~isequal(file,0)
                basename1 = file(1:end-4);
                spikes = loadSpikes('basepath',path,'basename',basename1,'format','klustakwik','saveMat',false,'getWaveformsFromDat',false,'getWaveformsFromSource',true);
                spikes.spindices = generateSpinDices(spikes.times);
                data.spikes_klusta = spikes;
                UI.settings.showKlusta = true;
                uiresume(UI.fig);
                MsgLog('Klustakwik data loaded succesful',2)
            else
                UI.settings.showKlusta = false;
                UI.panel.spikesorting.showKlusta.Value = 0;
                MsgLog(['Failed to load KlustaKwik data'],2)
            end
        elseif UI.panel.spikesorting.showKlusta.Value == 1  && isfield(data,'spikes_klusta')
            UI.settings.showKlusta = true;
            uiresume(UI.fig);
        else
            UI.settings.showKlusta = false;
            uiresume(UI.fig);
        end
        if UI.panel.spikesorting.klustaBelowTrace.Value == 1
            UI.settings.klustaBelowTrace = true;
        else
            UI.settings.klustaBelowTrace = false;
        end
        initTraces
    end
    
    function showSpykingcircus(~,~)
        if UI.panel.spikesorting.showSpykingcircus.Value == 1 && ~isfield(data,'spikes_spykingcircus')
            
            [file,path] = uigetfile('*.hdf5','Please select the Spyking Circus file for this session (hdf5 clusters)');
            if ~isequal(file,0)
                % Loading Spyking Circus file
                result_file = fullfile(path,file); % the user should use result.hdf5 which includes spiketimes of all templates (from the last template matching step) 
                info = h5info(result_file);
                templates_file = replace(result_file,'result','templates'); % to read templates.hdf5 file 
                % find max channel and correct for bad channels that are removed
                %preferred_electrodes = double(h5read(templates_file, '/electrodes')); % prefered electrode for every template may not be the maxCh
                bad_channels = data.session.channelTags.Bad.channels;
                bad_channels = sort(bad_channels); % in case they are not stored in Session in ascending order                        
                % extract templates for finding max channel
                temp_shape = double(h5read(templates_file, '/temp_shape'));
                Ne = temp_shape(1);
                Nt = temp_shape(2); 
                N_templates = temp_shape(3)/2; 
                temp_x = double(h5read(templates_file, '/temp_x') + 1);
                temp_y = double(h5read(templates_file, '/temp_y') + 1);
                temp_z = double(h5read(templates_file, '/temp_data'));
                tmp = sparse(temp_x, temp_y, temp_z, Ne*Nt, temp_shape(3));
                templates = reshape(full(tmp(:,1:N_templates)),Nt,Ne,N_templates); %spatiotemporal templates Nt*Ne*N_templates
                for i = 1:N_templates
                    template_i = templates(:,:,i);  
                    [~, maxCh1(i,1)] = min(min(template_i,[],1));
                end
                %correct bad channel removal by Spyking_circus 
                for i = 1:length(bad_channels)
                    ch = bad_channels(i); 
                    mask = maxCh1>= ch;
                    maxCh1(mask) = maxCh1(mask)+1; 
                end                
                
                for i = 1: N_templates % which is equal to length(info.Groups(4).Datasets) = number of templates
                    spikes.times{i} = double(h5read(result_file,['/spiketimes/',info.Groups(4).Datasets(i).Name]))/data.session.extracellular.sr;
                    template_number = str2double(erase(info.Groups(4).Datasets(i).Name,'temp_'));
                    spikes.cluID(i) = template_number+1; %plus one since temps start with temp_0
                    spikes.total(i) = length(spikes.times{i});
                    spikes.maxWaveformCh1(i)=maxCh1(i); %preferred_electrodes(i);
                    spikes.ids{i} = spikes.cluID(i)*ones(size(spikes.times{i})); 
                end
                
                spikes.numcells = numel(spikes.times);
                spikes.UID = 1:spikes.numcells;
                % generateSpinDices
                groups = cat(1,spikes.ids{:}); % from cell to array
                [alltimes,sortidx] = sort(cat(1,spikes.times{:})); % Sorting spikes
                spikes.spindices = [alltimes groups(sortidx)];

                
                % spikes = loadSpikes(data.session,'format','spykingcircus','saveMat',false,'getWaveformsFromDat',false,'getWaveformsFromSource',false);
                data.spikes_spykingcircus = spikes;
                UI.settings.showSpykingcircus = true;
                uiresume(UI.fig);
                MsgLog(['SpyKING circus data loaded succesful: ' basename],2)
            else
                UI.settings.showSpykingcircus = false;
                UI.panel.spikesorting.showSpykingcircus.Value = 0;
            end
            
        elseif UI.panel.spikesorting.showSpykingcircus.Value == 1  && isfield(data,'spikes_spykingcircus')
            UI.settings.showSpykingcircus = true;
            uiresume(UI.fig);
        else
            UI.settings.showSpykingcircus = false;
            uiresume(UI.fig);
        end
        if UI.panel.spikesorting.spykingcircusBelowTrace.Value == 1
            UI.settings.spykingcircusBelowTrace = true;
        else
            UI.settings.spykingcircusBelowTrace = false;
        end
        initTraces
    end

    function showIntan(src,evnt) % Intan data
        
        evnt_indice = evnt.Indices(1);
        value = evnt.EditData;
        tag = src.Data{evnt_indice,2};
        if strcmp(tag,'adc')
            if value && ~isempty(UI.table.timeseriesdata.Data{evnt_indice,3}) && exist(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}),'file')
                UI.settings.intan_showAnalog = true;
                UI.fid.timeSeries.adc = fopen(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}), 'r');
                
            elseif value
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
                MsgLog('Failed to load Analog file',4);
            else
                UI.settings.intan_showAnalog = false;
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
            end
        end
        if strcmp(tag,'aux')
            if value && ~isempty(UI.table.timeseriesdata.Data{evnt_indice,3}) && exist(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}),'file')
                UI.settings.intan_showAux = true;
                UI.fid.timeSeries.aux = fopen(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}), 'r');
            elseif value
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
                UI.settings.intan_showAux = false;
                MsgLog('Failed to load aux file',4);
            else
                UI.settings.intan_showAux = false;
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
            end
        end
        if strcmp(tag,'dig')
            if value && ~isempty(UI.table.timeseriesdata.Data{evnt_indice,3}) && exist(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}),'file')
                UI.settings.intan_showDigital = true;
                UI.fid.timeSeries.dig = fopen(fullfile(basepath,UI.table.timeseriesdata.Data{evnt_indice,3}), 'r');
            elseif value == 1
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
                MsgLog('Failed to load digital file',4);
            else
                UI.settings.intan_showDigital = false;
                UI.table.timeseriesdata.Data{evnt_indice,1} = false;
            end
        end
        initTraces
        uiresume(UI.fig);
    end
    
    function editIntanMeta(~,~)
        [session1,~,statusExit] = gui_session(data.session,[],'inputs');
        if statusExit
            data.session = session1;
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
        end
    end
    
    function showTimeseriesBelowTrace(~,~)
        if UI.panel.timeseriesdata.showTimeseriesBelowTrace.Value == 1
            UI.settings.showTimeseriesBelowTrace = true;
        else
            UI.settings.showTimeseriesBelowTrace = false;
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
            plot([UI.t0;UI.t0],[ax.YLim(1);ax.YLim(2)],'--b');
        end
    end

    function exportPlotData(src,~)
        UI.settings.stream = false;
        timestamp = datestr(now, '_dd-mm-yyyy_HH.MM.SS');
        % Adding text elemenets with timestamps and windows size
        text(UI.plot_axis1,0,1,[' Session: ', UI.data.basename, ', Basepath: ', UI.data.basepath],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','left','color',UI.settings.primaryColor,'Units','normalized')
        text(UI.plot_axis1,1,1,['Start time: ', num2str(UI.t0), ' sec, Duration: ', num2str(UI.settings.windowDuration), ' sec '],'FontWeight', 'Bold','VerticalAlignment', 'top','HorizontalAlignment','right','color',UI.settings.primaryColor,'Units','normalized')
        
        % Adding scalebar
        if ~UI.settings.showScalebar
            plot(UI.plot_axis1,[0.005,0.005],[0.93,0.98],'-','linewidth',3,'color',UI.settings.primaryColor)
            text(UI.plot_axis1,0.005,0.955,['  ',num2str(0.05/(UI.settings.scalingFactor)*1000,3),' mV'],'FontWeight', 'Bold','VerticalAlignment', 'middle','HorizontalAlignment','left','color',UI.settings.primaryColor)
        end
        drawnow
        if strcmp(src.Text,'Export to .png file (image)')
            if ~verLessThan('matlab','9.8') 
                exportgraphics(UI.plot_axis1,fullfile(basepath,[basename,'_NeuroScope',timestamp, '.png']))
            else
                set(UI.fig,'Units','Inches');
                set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
                saveas(UI.fig,fullfile(basepath,[basename,'_NeuroScope',timestamp, '.png']));
            end
            MsgLog(['The .png file was saved to the basepath: ' basename],2);
        elseif strcmp(src.Text,'Export to .pdf file (vector graphics)')
            if ~verLessThan('matlab','9.8') 
                exportgraphics(UI.plot_axis1,fullfile(basepath,[basename,'_NeuroScope',timestamp, '.pdf']),'ContentType','vector')
            else
                % Renderer is set to painter (vector graphics)
                set(UI.fig,'Units','Inches','Renderer','painters');
                set(UI.fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[UI.fig.Position(3), UI.fig.Position(4)],'PaperPosition',UI.fig.Position)
                saveas(UI.fig,fullfile(basepath,[basename,'_NeuroScope',timestamp, '.pdf']));
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
        initial_colormap = UI.settings.colormap;
        color_idx = find(strcmp(UI.settings.colormap,colormapList));
        
        colormap_dialog = dialog('Position', [0, 0, 300, 350],'Name','Change colormap','visible','off'); movegui(colormap_dialog,'center'), set(colormap_dialog,'visible','on')
        colormap_uicontrol = uicontrol('Parent',colormap_dialog,'Style', 'ListBox', 'String', colormapList, 'Position', [10, 50, 280, 270],'Value',color_idx,'Max',1,'Min',1,'Callback',@(src,evnt)previewColormap);
        uicontrol('Parent',colormap_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)close_dialog);
        uicontrol('Parent',colormap_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        uicontrol('Parent',colormap_dialog,'Style', 'text', 'String', 'Colormaps', 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(colormap_uicontrol)
        uiwait(colormap_dialog);

        % [idx,~] = listdlg('PromptString','Select colormap','ListString',colormapList,'ListSize',[250,400],'InitialValue',temp,'SelectionMode','single','Name','Colormap','Callback',@previewColormap);
        function close_dialog
            idx = colormap_uicontrol.Value;
            
            UI.settings.colormap = colormapList{idx};
            
            % Generating colormap
            UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);
            updateChanCoordsColorHighlight
            
            % Updating table colors
            classColorsHex = rgb2hex(UI.colors);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            UI.table.electrodeGroups.Data(:,2) = strcat('<html><BODY bgcolor="',classColorsHex','">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</BODY></html>');
            delete(colormap_dialog);
            uiresume(UI.fig);
            
        end
        function cancel_dialog
            % Closes dialog
            UI.settings.colormap = initial_colormap;
            UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);
            updateChanCoordsColorHighlight
            plotData;
            delete(colormap_dialog);
        end
        
        function previewColormap
            % Previewing colormap
            idx = colormap_uicontrol.Value;
            if ~isempty(idx)
                UI.settings.colormap = colormapList{idx};
                UI.colors = eval([UI.settings.colormap,'(',num2str(data.session.extracellular.nElectrodeGroups),')']);
                updateChanCoordsColorHighlight
                plotData;
            end
        end
    end
    
    function changeSpikesColormap(~,~)
        colormapList = {'lines','hsv','jet','colorcube','prism','parula','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink','white'};
        initial_colormap = UI.settings.spikesColormap;
        color_idx = find(strcmp(UI.settings.spikesColormap,colormapList));
        
        colormap_dialog = dialog('Position', [0, 0, 300, 350],'Name','Change colormap','visible','off'); movegui(colormap_dialog,'center'), set(colormap_dialog,'visible','on')
        colormap_uicontrol = uicontrol('Parent',colormap_dialog,'Style', 'ListBox', 'String', colormapList, 'Position', [10, 50, 280, 270],'Value',color_idx,'Max',1,'Min',1,'Callback',@(src,evnt)previewColormap);
        uicontrol('Parent',colormap_dialog,'Style','pushbutton','Position',[10, 10, 135, 30],'String','OK','Callback',@(src,evnt)close_dialog);
        uicontrol('Parent',colormap_dialog,'Style','pushbutton','Position',[155, 10, 135, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        uicontrol('Parent',colormap_dialog,'Style', 'text', 'String', 'Colormaps', 'Position', [10, 320, 280, 20],'HorizontalAlignment','left');
        uicontrol(colormap_uicontrol)
        uiwait(colormap_dialog);

        function close_dialog
            UI.settings.spikesColormap = colormapList{colormap_uicontrol.Value};
            delete(colormap_dialog);
            uiresume(UI.fig);
            
        end
        function cancel_dialog
            % Closes dialog
            UI.settings.spikesColormap = initial_colormap;
            plotData;
            delete(colormap_dialog);
        end
        
        function previewColormap
            % Previewing colormap
            color_idx = colormap_uicontrol.Value;
            if ~isempty(color_idx)                
                UI.settings.spikesColormap = colormapList{color_idx};
                plotData;
            end
        end
    end
    
    function colorByChannels(~,~)
        UI.settings.colorByChannels = ~UI.settings.colorByChannels;
        if UI.settings.colorByChannels
            prompt = {'Number of color groups (1-50)'};
            dlgtitle = 'Color groups';
            definput = {num2str(UI.settings.nColorGroups)};
            dims = [1 40];
            opts.Interpreter = 'tex';
            answer = inputdlg(prompt,dlgtitle,dims,definput,opts);
            if ~isempty(answer)
                numeric_answer = str2num(answer{1});
                if ~isempty(answer{1}) && rem(numeric_answer,1)==0 && numeric_answer > 0 && numeric_answer <= 50
                    UI.settings.nColorGroups = numeric_answer;
                end
                UI.menu.display.colorByChannels.Checked = 'on';
            else
                UI.settings.colorByChannels = false;
                UI.menu.display.colorByChannels.Checked = 'off';
            end
        else
            UI.menu.display.colorByChannels.Checked = 'off';
        end
        uiresume(UI.fig);
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
            backgroundColor = userSetColor(UI.plot_axis1.Color,'Background color');
            primaryColor = userSetColor(UI.plot_axis1.XColor,'Primary color (ticks, text, and rasters)');
            
            UI.settings.background = backgroundColor;
            UI.settings.textBackground = [backgroundColor,0.7];
            UI.settings.primaryColor = primaryColor;
            UI.plot_axis1.XColor = UI.settings.primaryColor;
            UI.plot_axis1.Color = UI.settings.background;
            uiresume(UI.fig);
    end
    
    function colorpick_out = userSetColor(colorpick1,title1)
        if verLessThan('matlab','9.9') 
            try
                colorpick_out = uisetcolor(colorpick1,title1);
            catch
                MsgLog('Colorpick faield',4)
            end
        else
            colorpick_out = uicolorpicker(colorpick1,title1);
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
            UI.priority = temp{2};
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
        end
    end
    
    function loadFromRecentFiles(src,~)
        UI.settings.stream = false;
        [basepath1,basename1,~] = fileparts(src.Text);
        if exist(basepath1,'dir')
            data = [];
            basepath = basepath1;
            basename = basename1;
            initData(basepath,basename);
            initTraces;
            uiresume(UI.fig);
        else
            MsgLog(['Basepath does not exist: ' basepath1],4)
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
            case '- About NeuroScope2'
                web('https://cellexplorer.org/interface/neuroscope2/','-new','-browser')
            case '- Tutorial on metadata'
                web('https://cellexplorer.org/tutorials/metadata-tutorial/','-new','-browser')
            case '- Documentation on session metadata'
                web('https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata','-new','-browser')
            case 'Support'
                 web('https://cellexplorer.org/#support','-new','-browser')
            case '- Report an issue'
                web('https://github.com/petersenpeter/CellExplorer/issues/new?assignees=&labels=bug&template=bug_report.md&title=','-new','-browser')
            case '- Submit feature request'
                web('https://github.com/petersenpeter/CellExplorer/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=','-new','-browser')
            otherwise
                web('https://cellexplorer.org/','-new','-browser')
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
