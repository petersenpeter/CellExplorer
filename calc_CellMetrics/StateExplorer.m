function dataIn = StateExplorer(dataIn,varargin)
    % % % % % % % % % % % % % % % % % % % % % % % % %
    % StateExplorer (BETA) is a visualizer for state data. StateExplorer is part of CellExplorer - https://CellExplorer.org/
    %
    % INPUTS:
    %   data.timestamps
    %
    %   session: session struct. Defined by CellExplorer: https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata
    %
    % OUTPUT
    % data structure containing state data
    %
    % Example calls:
    %    StateExplorer
    %    StateExplorer('basepath',basepath)
    %    StateExplorer('session',session)
    %
    % By Peter Petersen
    % % % % % % % % % % % % % % % % % % % % % % % % %
    
    % Global variables
    UI = []; % Struct with UI elements and settings
    UI.drag.mouse = false; UI.drag.startX = []; UI.drag.startY = []; UI.drag.axnum = []; UI.drag.pan = []; UI.scroll = true;
    UI.zoom.global = cell(1,1); UI.zoom.globalLog = cell(1,1);  
    data = []; % Contains all external data loaded like data.session, data.events, data.states, data.behavior, data.spikes

    t0 = 0; % Timestamp of the start of the current window (in seconds)
    polygon1.handle = gobjects(0);
    clickAction = 0;
    data_source = 'input';
    epoch_plotElements.t0 = [];
    epoch_plotElements.events = [];

    % % % % % % % % % % % % % % % % % % % % % % % % %
    % Handling inputs
    p = inputParser;
    addParameter(p,'basepath',pwd,@isstr);
    addParameter(p,'basename',[],@isstr);
    addParameter(p,'session',[],@isstruct);
    addParameter(p,'spikes',[],@isstr);
    addParameter(p,'events',[],@isstr);
    addParameter(p,'states',[],@isstr);
    addParameter(p,'behavior',[],@isstr);
    
    parse(p,varargin{:})
    parameters = p.Results;
    
    if ~exist('dataIn')
        answer = questdlg('What data do you want to Explore?', 'StateExplore data', 'From file','From workspace','Cancel','From workspace');
        switch answer
            case 'From file'
                [file,path] = uigetfile('*.mat','Please select a .mat file','.mat');
                if ~isequal(file,0)
                    cd(path)
                    varout = load(file);
                    temo2 = fieldnames(varout);
                    dataIn = varout.(temo2{1});
                    dataIn.inputname = temo2{1};
                    data_source = 'file';
                else
                    return
                end
                
            case 'From workspace'
                [varout,varoutnames] = uigetvariables({'Please select a struct variable from your workspace'},'InputTypes',{'struct'});
                if ~isempty(varout)
                    dataIn = varout{1};
                    dataIn.inputname = varoutnames{1};
                    data_source = 'workspace';
                else
                    return
                end
            case 'Cancel'
                return
        end
    else
        dataIn.inputname = inputname(1);
    end

    basepath = p.Results.basepath;
    basename = p.Results.basename;
    if isempty(basename)
        basename = basenameFromBasepath(basepath);
    end
    if ~isempty(parameters.session)
        basename = parameters.session.general.name;
        basepath = parameters.session.general.basePath;
    end
    if isempty(parameters.session)
        data.session = loadSession(basepath,basename);
    else
        data.session = parameters.session;
    end

    % % % % % % % % % % % % % % % % % % % % % % % % %
    % Initialization
    initUI
    initData(basepath,basename);
    %     initInputs
    %     initTraces
    
    movegui(UI.fig,'center'), 
    set(UI.fig,'visible','on')
%     DragMouseBegin
    
    % % % % % % % % % % % % % % % % % % % % % % % % %
    % Main loop of the StateExplorer
    
    while t0>=0
        % breaking if figure has been closed
        if ~ishandle(UI.fig)
            break
        else
            % Plotting data
            plotData;
            
            % Enabling axes panning    
            UI.drag.pan.Enable = 'on';
            enableInteractions
            UI.pan.allow = true(1,1);
            
            uiwait(UI.fig);
            
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % % % % %
    % Exit calls
    
    switch data_source
        case 'workspace'
            % Saves back changes to the variable loaded from the workspace
            assignin('base',dataIn.inputname,dataIn)
        case 'file'
            
        otherwise
            
    end
    
    % % % % % % % % % % % % % % % % % % % % % % % % %
    % Embedded functions 
    
    function initData(basepath,basename)
        if numel(dataIn.data)>100000
        samples = 50000;
        idx_lowress = round([1:samples]/samples*numel(dataIn.timestamps));
            dataIn.timestamps_lowress = dataIn.timestamps(idx_lowress);
            dataIn.data_lowress = dataIn.data(idx_lowress);
        else
            dataIn.timestamps_lowress = dataIn.timestamps;
            dataIn.data_lowress = dataIn.data;
        end
        
        updateUIStates
        
        % Detecting CellExplorer/Buzcode files
        UI.data.detectecFiles = detectCellExplorerFiles(basepath,basename);
        % Events
        if isfield(UI.data.detectecFiles,'events') && ~isempty(UI.data.detectecFiles.events)
            UI.panel.events.files.String = UI.data.detectecFiles.events;
            UI.settings.eventData = UI.data.detectecFiles.events{1};
        else
            UI.panel.events.files.String = {''};
        end
        % States
        if isfield(UI.data.detectecFiles,'states') && ~isempty(UI.data.detectecFiles.states)
            UI.panel.statesExtra.files.String = UI.data.detectecFiles.states;
            UI.settings.statesData = UI.data.detectecFiles.states{1};
        else
            UI.panel.statesExtra.files.String = {''};
        end
        
    end
    
    function updateUIStates
        if isfield(dataIn,'states')
            UI.settings.states = fieldnames(dataIn.states)';
            UI.settings.clr_states = eval([UI.settings.colormap,'(',num2str(numel(UI.settings.states)),')']);
        else
            UI.settings.states = [];
            UI.settings.clr_states = [];
        end
        if ~isempty(UI.settings.states)
            classColorsHex = rgb2hex(UI.settings.clr_states*0.7);
            classColorsHex = cellstr(classColorsHex(:,2:end));
            classNumbers = cellstr(num2str([1:length(UI.settings.states)]'))';
            colored_string = strcat('<html>',classNumbers, '.&nbsp;','<BODY bgcolor="white"><font color="', classColorsHex' ,'">&nbsp;', UI.settings.states, '&nbsp;</font></BODY></html>');
            
            UI.listbox.statesOnTrace.String = colored_string;
            UI.listbox.statesIntervals.String = colored_string;
        else
            UI.listbox.statesOnTrace.String = {''};
            UI.listbox.statesIntervals.String = {''};
        end
        
        UI.settings.statesOnTrace = 1:numel(UI.settings.states);
        UI.settings.statesIntervals = 1:numel(UI.settings.states);
        
        UI.listbox.statesOnTrace.Value = UI.settings.statesOnTrace;
        UI.listbox.statesIntervals.Value = UI.settings.statesIntervals;
        
    end
    
    function initUI
        % % % % % % % % % % % % % % % % % % % % % %
        % Init settings
        UI.settings.colormap = 'hsv';
        UI.settings.statesOnTrace = [];
        UI.settings.statesIntervals = [];
        
        % Event settings
        UI.settings.showEvents = false;
        UI.settings.eventData = [];
        
        % States settings
        UI.settings.showStates = false;
        UI.settings.statesData = [];
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating figure
        
        UI.fig = figure('Name',['StateExplorer   -   session: ', basename,', basepath: ' basepath],'NumberTitle','off','renderer','opengl','windowscrollWheelFcn',@ScrolltoZoomInPlot,'KeyPressFcn', @keyPress,'KeyReleaseFcn',@keyRelease,'WindowButtonMotionFcn', @hoverCallback,'DefaultAxesLooseInset',[.01,.01,.01,.01],'visible','off','pos',[0,0,1600,800],'DefaultTextInterpreter', 'none', 'DefaultLegendInterpreter', 'none', 'MenuBar', 'None');
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
        UI.menu.cellExplorer.topMenu = uimenu(UI.fig,menuLabel,'StateExplorer');
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'About StateExplorer',menuSelectedFcn,@AboutDialog);
        uimenu(UI.menu.cellExplorer.topMenu,menuLabel,'Quit',menuSelectedFcn,@exitStateExplorer,'Separator','on','Accelerator','W');
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Creating UI/panels
        
        UI.grid_panels = uix.GridFlex( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 0); % Flexib grid box
        UI.panel.left = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Left panel
        
        UI.panel.center = uix.VBox( 'Parent', UI.grid_panels, 'Spacing', 0, 'Padding', 0 ); % Center flex box
        % UI.panel.right = uix.VBoxFlex('Parent',UI.grid_panels,'position',[0 0.66 0.26 0.31]); % Right panel
        set(UI.grid_panels, 'Widths', [180 -1],'MinimumWidths',[100 1]); % set grid panel size
        
        % Separation of the center box into three panels: title panel, plot panel and lower info panel
        UI.panel.plots = uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.panel.center); % Main plot panel
        UI.panel.info  = uix.HBox('Parent',UI.panel.center, 'Padding', 1); % Lower info panel
        set(UI.panel.center, 'Heights', [-1 20]); % set center panel size
        
        % Left panel tabs
        UI.uitabgroup = uiextras.TabPanel('Parent', UI.panel.left, 'Padding', 1,'FontSize',11 ,'TabSize',60);
        UI.panel.general.main  = uix.VBox('Parent',UI.uitabgroup, 'Padding', 1);
        UI.uitabgroup.TabNames = {'General'};
        UI.panel.states.main  = uix.VBox('Parent',UI.panel.general.main, 'Padding', 1);
        uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.5 0.1],'String','Polygon selection','Callback',@(src,evnt)polygonSelection,'KeyPressFcn', {@keyPress},'tooltip','Draw a polygon around cells to select them');
        uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.5 0.1],'String','Interval addition','Callback',@intervalSelection,'KeyPressFcn', {@keyPress});
        uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0.5 0 0.5 0.1],'String','Interval deletion','Callback',@intervalSelection,'KeyPressFcn', {@keyPress});
        uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0 0 0.5 0.1],'String','Clear a state','Callback',@(src,evnt)clearState,'KeyPressFcn', {@keyPress});
        uicontrol('Parent',UI.panel.states.main,'Style','pushbutton','Units','normalized','Position',[0 0 0.5 0.1],'String','Save states file','Callback',@(src,evnt)saveStates,'KeyPressFcn', {@keyPress});
        set(UI.panel.states.main, 'Heights', [30 30 30 30 30],'MinimumHeights',[30 30 30 30 30]);
        
        UI.panel.statesOnTrace.main = uipanel('Title','States-traces','TitlePosition','centertop','Position',[0 0 1 1],'Units','normalized','Parent',UI.panel.general.main);
        UI.listbox.statesOnTrace = uicontrol('Parent',UI.panel.statesOnTrace.main,'Style','listbox','Position',[0.5 0 0.5 1],'Units','normalized','String',{''},'max',100,'min',0,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)setStatesPlots,'KeyPressFcn', {@keyPress});
        UI.panel.statesIntervals.main = uipanel('Title','States-intervals','TitlePosition','centertop','Position',[0 0 1 1],'Units','normalized','Parent',UI.panel.general.main);
        UI.listbox.statesIntervals = uicontrol('Parent',UI.panel.statesIntervals.main,'Style','listbox','Position',[0.5 0 0.5 1],'Units','normalized','String',{''},'max',100,'min',0,'Value',1,'fontweight', 'bold','Callback',@(src,evnt)setStatesPlots,'KeyPressFcn', {@keyPress});
        
        UI.panel.events.main  = uipanel('Parent',UI.panel.general.main,'title','Event data','TitlePosition','centertop');
%         UI.panel.events.navigation = uipanel('Parent',UI.panel.other.main,'title','Events');
        UI.panel.events.files = uicontrol('Parent',UI.panel.events.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.67 0.98 0.31],'HorizontalAlignment','left','Callback',@setEventData);
        UI.panel.events.showEvents = uicontrol('Parent',UI.panel.events.main,'Style','checkbox','Units','normalized','Position',[0.01 0.35 0.98 0.33], 'value', 0,'String','Show events','Callback',@showEvents,'KeyPressFcn', @keyPress,'tooltip','Show events');
        % set(UI.panel.events.main, 'Heights', [30 30],'MinimumHeights',[30 30]);
        
        % Extra states
        UI.panel.statesExtra.main = uipanel('Parent',UI.panel.general.main,'title','Extra states data','TitlePosition','centertop');
        UI.panel.statesExtra.files = uicontrol('Parent',UI.panel.statesExtra.main,'Style', 'popup', 'String', {''}, 'Units','normalized', 'Position', [0.01 0.67 0.98 0.31],'HorizontalAlignment','left','Callback',@setStatesData);
        UI.panel.statesExtra.showStates = uicontrol('Parent',UI.panel.statesExtra.main,'Style','checkbox','Units','normalized','Position',[0.01 0.35 0.98 0.33], 'value', 0,'String','Show states','Callback',@showStates,'KeyPressFcn', @keyPress,'tooltip','Show states data');

        set(UI.panel.general.main, 'Heights', [155 100 100 100 100],'MinimumHeights',[155 100 100 100 100]);
        
        % % % % % % % % % % % % % % % % % % % % % %
        % Lower info panel elements

        % % % % % % % % % % % % % % % % % % % % % %
        % Creating plot axes
        % Main axes
        UI.plot_axis1 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0.015 0.135 0.984 0.865],'ButtonDownFcn',@ClickPlot,'XMinorTick','on');
        % states axis
        UI.plot_axis4 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0.015 0.005 0.984 0.1],'ButtonDownFcn',@ClickPlot,'XMinorTick','on','Visible', 'on','YLim',[0 1],'YTickLabel',[],'XTickLabel',[]); ylabel(UI.plot_axis4,'States')
        % Event axis
        UI.plot_axis3 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0.015 0.005 0.984 0.05],'ButtonDownFcn',@ClickPlot,'XMinorTick','on','Visible', 'off','YLim',[0 1],'YTickLabel',[],'XTickLabel',[]); ylabel(UI.plot_axis3,'Events')
        % Extra states axis
        UI.plot_axis2 = axes('Parent',UI.panel.plots,'Units','Normalize','Position',[0.015 0.005 0.984 0.1],'ButtonDownFcn',@ClickPlot,'XMinorTick','on','Visible', 'off','YLim',[0 1],'YTickLabel',[],'XTickLabel',[]); ylabel(UI.plot_axis2,'Extra states')
        
        hold on, axis tight
        set(0,'units','pixels');
        UI.Pix_SS = get(0,'screensize');
        UI.Pix_SS = UI.Pix_SS(3)*2;
    end
    
    function plotData
        delete(UI.plot_axis1.Children)
        delete(UI.plot_axis4.Children)
        
        set(UI.fig,'CurrentAxes',UI.plot_axis1)
        line(UI.plot_axis1,dataIn.timestamps_lowress,dataIn.data_lowress, 'HitTest','off','color','k'), axis tight;
        xlim1 = UI.plot_axis1.XLim;
        UI.zoom.global{1}(1,:) = xlim1;
        UI.zoom.global{1}(2,:) = UI.plot_axis1.YLim;
        UI.zoom.global{1}(3,:) = UI.plot_axis1.ZLim;
        UI.zoom.globalLog{1} = [0,0,0];
        
        UI.plot_axis4.XLim = xlim1;
        if UI.settings.showEvents
            UI.plot_axis3.XLim = xlim1;
        end
        if UI.settings.showStates
            UI.plot_axis2.XLim = xlim1;
        end
        % States
        if ~isempty(UI.settings.statesOnTrace)
            plotStatesOnTrace(0,inf)
        end
        if UI.settings.statesIntervals
            plotTemporalStates(0,inf)
        end
        
        % Event data
        if UI.settings.showEvents
            delete(UI.plot_axis3.Children)
            plotEventData(0,Inf,'k','m')
        end
        
        % States data
        if UI.settings.showStates
            delete(UI.plot_axis2.Children)
            plotExtraTemporalStates(0,inf,UI.plot_axis2,[0,1])
        end
    end
    
    function keyPress(~,~)
    
    end
    
    
    function keyRelease(~,~)
    
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
        
        AboutWindow.dialog = figure('Position', fig_size,'Name','About StateExplorer', 'MenuBar', 'None','NumberTitle','off','visible','off', 'resize', 'off'); movegui(AboutWindow.dialog,'center'), set(AboutWindow.dialog,'visible','on')
        if isdeployed
            logog_path = '';
        else
            [logog_path,~,~] = fileparts(which('CellExplorer.m'));
        end
        [img, ~, alphachannel] = imread(fullfile(logog_path,'logoCellExplorer.png'));
        image(img, 'AlphaData', alphachannel,'ButtonDownFcn',@openWebsite);
        AboutWindow.image = gca;
        set(AboutWindow.image,'Color','none','Units','Pixels') , hold on, axis off
        AboutWindow.image.Position = pos_image;
        text(0,pos_text,{'\bfStateExplorer\rm - part of CellExplorer','By Peter Petersen.', 'Developed in the Buzsaki laboratory at NYU, USA.','\bf\color[rgb]{0. 0.2 0.5}https://CellExplorer.org/\rm'},'HorizontalAlignment','left','VerticalAlignment','top','ButtonDownFcn',@openWebsite, 'interpreter','tex')
    end
    
    function polygonSelection(~,~)
        clickAction = 1;
        MsgLog('Select points by drawing a polygon with your mouse. Complete with a right click, cancel last point with middle click.');
%         ax = get(UI.fig,'CurrentAxes');
        ax = UI.plot_axis1;
        hold(ax, 'on');
        polygon1.counter = 0;
        polygon1.cleanExit = 0;
        polygon1.coords = [];
        set(UI.fig,'Pointer','crosshair')
    end
    
    function intervalSelection(src,~)
        if strcmp(src.String,'Interval addition')
            clickAction = 2;
            MsgLog('Define intervals by drawing temporal boundaries with your mouse. Complete with a right click, cancel last point with middle click.');
        else
            clickAction = 3;
            MsgLog('Remove intervals by drawing temporal boundaries with your mouse. Complete with a right click, cancel last point with middle click.');
        end
        
        ax = UI.plot_axis1;
        hold(ax, 'on');
        polygon1.counter = 0;
        polygon1.cleanExit = 0;
        polygon1.coords = [];
        polygon1.handle2 = [];
        set(UI.fig,'Pointer','left')
    end
    
    function clearState(~,~)
        statesList = fieldnames(dataIn.states);
        [selectedState,~] = listdlg('PromptString','Clear state data','ListString',statesList,'SelectionMode','single','ListSize',[200,150]);
        if ~isempty(selectedState)
            dataIn.states.(statesList{selectedState}) = [];
            dataIn.states = rmfield(dataIn.states,statesList{selectedState});
            UI.settings.states = fieldnames(dataIn.states);
            MsgLog([statesList{selectedState} ' states cleared '],1);
            updateUIStates
            uiresume(UI.fig);
        else
            uiresume(UI.fig);
        end
    end
    
    function saveStates(~,~)
        if isfield(dataIn,'states')
            if isfield(dataIn,'inputname')
            	value = dataIn.inputname;
            else
                value = '';
            end
            answer = inputdlg({'State data name'},'State name', [1 50],{value});
            if ~isempty(answer) && ~strcmp(answer{1},'') && isvarname(answer{1})
                dataName = answer{1};
                data1 = dataIn.states;
                saveStruct(data1,'states','session',data.session,'dataName',dataName);
                MsgLog(['States from ', dataName,' succesfully saved to basepath'],1);
            end
        end
    end
    
    function setStatesPlots(src,evnt)
        UI.settings.statesOnTrace = UI.listbox.statesOnTrace.Value;
        UI.settings.statesIntervals = UI.listbox.statesIntervals.Value;
        uiresume(UI.fig);
    end
    
    function DragMouseBegin
        UI.drag.pan = pan(UI.fig);
        UI.drag.pan.Enable = 'on';
        UI.drag.pan.ButtonDownFilter = @ClicktoSelectFromPlot;
        UI.drag.pan.ActionPreCallback = @mousebuttonPress;
        UI.drag.pan.ActionPostCallback = @mousebuttonRelease;
        enableInteractions
    end
    
    function hoverCallback(~,~)
        if clickAction == 0
            set(UI.fig,'Pointer','arrow')
        elseif clickAction == 1
            set(UI.fig,'Pointer','crosshair')
        else
            set(UI.fig,'Pointer','left')
        end
        if clickAction == 0 && UI.fig == get(groot,'CurrentFigure')
            UI.drag.pan.Enable = 'on';
%             enableInteractions
        end
    end
    
    function enableInteractions
        try
            % this works in R2014b, and maybe beyond:
            [hManager.WindowListenerHandles.Enabled] = deal(false); % HG2
        catch
            set(hManager.WindowListenerHandles, 'Enable', 'off'); % HG1
        end
        set(UI.fig, 'WindowKeyPressFcn', []);
        set(UI.fig, 'KeyPressFcn', {@keyPress});
        set(UI.fig, 'windowscrollWheelFcn',{@ScrolltoZoomInPlot})
    end
    
    function mousebuttonRelease(~,~)
         UI.scroll = true;
         enableInteractions
    end
    
    function mousebuttonPress(~,~)
         UI.scroll = false;
    end
    
    % Events
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
            UI.plot_axis3.Visible = 'off';
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
            UI.panel.events.showEvents.Value = 1;
        else
            UI.settings.showEvents = false;
            UI.panel.events.showEvents.Value = 0;
        end
        setPlotLayout
        uiresume(UI.fig);
    end
    
    % States
    function setStatesData(~,~)
        UI.settings.statesData = UI.panel.statesExtra.files.String{UI.panel.statesExtra.files.Value};
        UI.settings.showStates = false;
        showStates;
    end
    
    function showStates(~,~) % States (buzcode)
        if UI.settings.showStates
            UI.settings.showStates = false;
            UI.panel.statesExtra.showStates.Value = 0;
        elseif exist(fullfile(basepath,[basename,'.',UI.settings.statesData,'.states.mat']),'file')
            if ~isfield(data,'states') || ~isfield(data.states,UI.settings.statesData)
                data.states.(UI.settings.statesData) = loadStruct(UI.settings.statesData,'states','session',data.session);
            end
            UI.settings.showStates = true;
            UI.panel.statesExtra.showStates.Value = 1;
        else
            UI.settings.showStates = false;
            UI.panel.statesExtra.showStates.Value = 0;
        end
        setPlotLayout
        uiresume(UI.fig);
    end
    
    function setPlotLayout
        offset = 0;
        if UI.settings.showStates
            UI.plot_axis2.Visible = 'on';
            offset = offset+0.135;
        else
            UI.plot_axis2.Visible = 'off';
            delete(UI.plot_axis2.Children)
        end
        if UI.settings.showEvents
            UI.plot_axis3.Visible = 'on';
            UI.plot_axis3.Position = [0.015 0.005+offset 0.984 0.05];
            offset = offset+0.08;
        else
            UI.plot_axis3.Visible = 'off';
            delete(UI.plot_axis3.Children)
        end

        UI.plot_axis4.Position = [0.015 0.005+offset 0.984 0.1];
        UI.plot_axis1.Position = [0.015 0.135+offset 0.984 0.865-offset];
    end
    
    function ScrolltoZoomInPlot(h,event,direction)
        % Called when scrolling/zooming
        % Checks first, if a plot is underneath the curser
        if isfield(UI,'panel') && UI.scroll
            axnum = 1;
            handle34 = UI.plot_axis1;
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
                UI.zoom.globalLog{axnum} = [0,0,0];
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
            
            xlim1 = applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction);
            UI.plot_axis4.XLim = xlim1;
            if UI.settings.showEvents
                UI.plot_axis3.XLim = xlim1;
            end
            if UI.settings.showStates
                UI.plot_axis2.XLim = xlim1;
            end
        end
        
        function xlim1 = applyZoom(globalZoom1,cursorPosition,axesLimits,globalZoomLog1,direction)
            
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
                    xlim1 = globalZoom1(1,:);
                elseif v < c(1) || v > c(2)
                    % Horizontal scrolling
                    axLim = RecalcZoomAxesLimits(b, globalZoom1(1,:), cursorPosition(1), zoomPct,globalZoomLog1(1));
                    xlim(axLim)
                    xlim1 = axLim;
                else
                    % X zoom
                    axLim = RecalcZoomAxesLimits(b, globalZoom1(1,:), cursorPosition(1), zoomPct,globalZoomLog1(1));
                    xlim(axLim)
                    xlim1 = axLim;
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
    
    function [disallowRotation] = ClickPlot(~,~)
        % Handles mouse clicks on the plots. Determines the selected plot
        % and the coordinates (u,v) within the plot. Finally calls
        % according to which mouse button that was clicked.
        disallowRotation = true;
        
        if clickAction == 0
            switch get(UI.fig, 'selectiontype')
                case 'open'
                    xlim1 = UI.zoom.global{1}(1,:);
                    set(UI.plot_axis1,'XLim',xlim1,'YLim',UI.zoom.global{1}(2,:))
                    UI.plot_axis4.XLim = xlim1;
                    if UI.settings.showEvents
                        UI.plot_axis3.XLim = xlim1;
                    end
                    if UI.settings.showStates
                        UI.plot_axis2.XLim = xlim1;
                    end
                case 'normal'
                    disallowRotation = false;
            end
        elseif clickAction == 1 % Polygon selection
            um_axes = get(UI.plot_axis1,'CurrentPoint');
            cursorPosition = um_axes(1,:);
            
            selectiontype = get(UI.fig, 'selectiontype');
            
            if strcmpi(selectiontype, 'alt')
                if ~isempty(polygon1.coords)
                    hold on,
                    polygon1.handle(polygon1.counter+1) = line([polygon1.coords(:,1);polygon1.coords(1,1)],[polygon1.coords(:,2);polygon1.coords(1,2)],'Marker','.','color','k', 'HitTest','off');
                end
                if polygon1.counter > 0
                    polygon1.cleanExit = 1;
                end
                clickAction = 0;
                set(UI.fig,'Pointer','arrow')
                finishPolygonSelection
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter > 0
                polygon1.coords = polygon1.coords(1:end-1,:);
                set(polygon1.handle(polygon1.counter),'Visible','off');
                polygon1.counter = polygon1.counter-1;
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter == 0
                clickAction = 0;
                set(UI.fig,'Pointer','arrow')
                
            elseif strcmpi(selectiontype, 'normal')
                polygon1.coords = [polygon1.coords;cursorPosition(1:2)];
                polygon1.counter = polygon1.counter +1;
                polygon1.handle(polygon1.counter) = line(polygon1.coords(:,1),polygon1.coords(:,2),'Marker','.','color','k','HitTest','off');
            elseif strcmpi(selectiontype, 'open')
                set(UI.plot_axis1,'XLim',UI.zoom.global{1}(1,:),'YLim',UI.zoom.global{1}(2,:))
            end
        else % Interval selection
            um_axes = get(UI.plot_axis1,'CurrentPoint');
            cursorPosition = um_axes(1,:);
            
            selectiontype = get(UI.fig, 'selectiontype');
            
            if strcmpi(selectiontype, 'alt')
                if polygon1.counter >= 2
                    polygon1.cleanExit = 1;
                end
                set(UI.fig,'Pointer','arrow')
                finishIntervalSelection(clickAction)
                clickAction = 0;
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter > 1
                
                polygon1.coords = polygon1.coords(1:end-1);
                set(polygon1.handle(polygon1.counter),'Visible','off');
                set(polygon1.handle2(polygon1.counter),'Visible','off');
                polygon1.counter = polygon1.counter-1;
                polygon1.handle2(polygon1.counter) = line(UI.plot_axis1,polygon1.coords(end)*[1,1],UI.zoom.global{1}(2,:),'color',[0.5 0.5 0.5], 'HitTest','off');
                
            elseif strcmpi(selectiontype, 'extend') && polygon1.counter < 2
                clickAction = 0;
                set(UI.fig,'Pointer','arrow')
                uiresume(UI.fig);
                
            elseif strcmpi(selectiontype, 'normal')
                
                polygon1.coords = [polygon1.coords;cursorPosition(1)];
                polygon1.counter = polygon1.counter +1;
                
                n_points = numel(polygon1.coords);
                polygon1.handle2(polygon1.counter) = line(UI.plot_axis1,polygon1.coords(end)*[1,1],UI.zoom.global{1}(2,:),'color',[0.5 0.5 0.5], 'HitTest','off');
                if n_points>1
                    n_even_points = floor(n_points/2)*2;
                    statesData = polygon1.coords(1:n_even_points);
                    statesData = reshape(statesData,2,[])';
                    polygon1.handle(polygon1.counter) = plotStates(statesData(end,:));
                else
                    % polygon1.handle(polygon1.counter) = [];
                end
                
                if polygon1.counter > 1
                    set(polygon1.handle2(polygon1.counter-1),'Visible','off');
                end
            elseif strcmpi(selectiontype, 'open')
                xlim1 = UI.zoom.global{1}(1,:);
                set(UI.plot_axis1,'XLim',xlim1,'YLim',UI.zoom.global{1}(2,:))
                UI.plot_axis4.XLim = xlim1;
                if UI.settings.showEvents
                    UI.plot_axis3.XLim = xlim1;
                end
                if UI.settings.showStates
                    UI.plot_axis2.XLim = xlim1;
                end
            end
        end
        
    end
    
    function finishPolygonSelection
        idx = sort(find(inpolygon(dataIn.timestamps,dataIn.data, polygon1.coords(:,1)',polygon1.coords(:,2)')));
        if ~isempty(idx)
            line(UI.plot_axis1,dataIn.timestamps(idx),dataIn.data(idx),'Marker','.','LineStyle','none','color','k', 'HitTest','off')
            intervals = find(diff(idx)>1);
            intervals = [0,intervals,numel(idx)];
            n_intervals = numel(intervals)-1;
            states = [];
            for i_interval = 1:n_intervals
                idx1 = idx(intervals(i_interval)+1);
                idx2 = idx(intervals(i_interval+1));
                states(i_interval,:) = dataIn.timestamps([idx1,idx2]);
            end
            states = sort(states,2);
            if size(states,1)>1
                states = ConsolidateIntervals(states);
            end
     
            plotStates(states)
            addStateDialog(states)
        else
            uiresume(UI.fig);
        end
    end
    
    function finishIntervalSelection(actionType)
        if polygon1.cleanExit
            n_points = numel(polygon1.coords);
            n_even_points = floor(n_points/2)*2;
            selectedIntervals = reshape(polygon1.coords(1:n_even_points),2,[])';
            states = sort(selectedIntervals,2);
            if size(states,1)>1
                states = ConsolidateIntervals(states);
            end
            plotStates(states);
            if actionType==2
                addStateDialog(states)
            else
                substractStateDialog(states)
            end
        else
            uiresume(UI.fig);
        end
    end
    
    function p1 = plotStates(statesData)
        ydata = [0 1];
%         line(UI.plot_axis1, states,[ydata,flip(ydata)],'Marker','none','LineStyle','-','color','r', 'HitTest','off')
        p1 = patch(UI.plot_axis4,double([statesData,flip(statesData,2)])',[ydata(1);ydata(1);ydata(2);ydata(2)]*ones(1,size(statesData,1)),'k','EdgeColor','k','HitTest','off');
        alpha(p1,0.3);
    end
    
    function addNewStateIntervals(states,stateName)
        if ~isfield(dataIn,'states') || ~isfield(dataIn.states,stateName) || isempty(dataIn.states.(stateName))
            dataIn.states.(stateName) = states;
        else
            dataIn.states.(stateName) = ConsolidateIntervals([dataIn.states.(stateName);states]);
        end
    end
    
    function plotTemporalStates(t1,t2)
        % Plot states
        if isfield(dataIn,'states')
            ydata = [0; 1];
            states1  = dataIn.states;
            stateNames =  UI.settings.states;

            for jj = UI.settings.statesIntervals
                if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
                    idx = (states1.(stateNames{jj})(:,1)<t2 & states1.(stateNames{jj})(:,2)>t1);
                    if any(idx)
                        ydata1(1) = ydata(1)+diff(ydata)/numel(stateNames)*(jj-1);
                        ydata1(2) = ydata(1)+diff(ydata)/numel(stateNames)*(jj);
                        statesData2 = states1.(stateNames{jj})(idx,:);
                        p1 = patch(UI.plot_axis4,double([statesData2,flip(statesData2,2)])',[ydata1(1);ydata1(1);ydata1(2);ydata1(2)]*ones(1,size(statesData2,1)),UI.settings.clr_states(jj,:),'EdgeColor',UI.settings.clr_states(jj,:),'HitTest','off');
                        alpha(p1,0.3);
                        text(UI.plot_axis4,0.005,0.005+(jj-1)*0.15,stateNames{jj},'FontWeight', 'Bold','Color',UI.settings.clr_states(jj,:)*0.8,'margin',1,'BackgroundColor',[1 1 1 0.7], 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized'), axis tight
                    else
                        text(UI.plot_axis4,0.005,0.005+(jj-1)*0.15,stateNames{jj},stateNames{jj},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[1 1 1 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
                    end
                end
            end
        end
    end
    
    function plotExtraTemporalStates(t1,t2,ax1,ylim1)
        % Plot states
        if isfield(data,'states')
            xlim1 = UI.zoom.global{1}(1,:);
            ydata = ylim1;
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
                        ydata1(1) = ydata(1)+diff(ydata)/numel(stateNames)*(jj-1)+diff(ydata)/10;
                        ydata1(2) = ydata(1)+diff(ydata)/numel(stateNames)*(jj);
                        statesData2 = states1.(stateNames{jj})(idx,:);
                        p1 = patch(ax1,double([statesData2,flip(statesData2,2)])',[ydata1(1);ydata1(1);ydata1(2);ydata1(2)]*ones(1,size(statesData2,1)),clr_states(jj,:),'EdgeColor',clr_states(jj,:),'HitTest','off');
                        alpha(p1,0.3);
                        text(ax1,0.005,0.005+(jj-1)*0.15,stateNames{jj},'FontWeight', 'Bold','Color',clr_states(jj,:)*0.8,'margin',1,'BackgroundColor',[1 1 1 0.7], 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized'), axis tight
                    else
                        text(ax1,0.005,0.005+(jj-1)*0.15,stateNames{jj},stateNames{jj},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[1 1 1 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
                    end
                end
            end
        end
    end
    
    function plotStatesOnTrace(t1,t2)
        % Plot states
        if isfield(dataIn,'states')
            xlim1 = UI.zoom.global{1}(1,:);
            ylim1 = UI.zoom.global{1}(2,:);
            ydata = [ylim1(1) diff(ylim1)*0.1+ylim1(1)];
            states1  = dataIn.states;
            stateNames =  UI.settings.states;
            for jj = UI.settings.statesOnTrace
                if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
                    idx = find(states1.(stateNames{jj})(:,1)<t2 & states1.(stateNames{jj})(:,2)>t1);
                    if ~isempty(idx)
                        for i = 1:numel(idx)
                            statesData2 = states1.(stateNames{jj})(idx(i),:);
                            indices = InIntervals(dataIn.timestamps_lowress,statesData2);
                            line(UI.plot_axis1,dataIn.timestamps_lowress(indices),dataIn.data_lowress(indices),'Marker','none','LineStyle','-', 'HitTest','off','Color',UI.settings.clr_states(jj,:),'linewidth',2)
                        end
                        text(0.005,0.005+(jj-1)*0.025,stateNames{jj},'FontWeight', 'Bold','Color',UI.settings.clr_states(jj,:)*0.8,'margin',1,'BackgroundColor',[1 1 1 0.7], 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized'), axis tight
                    else
                        text(0.005,0.005+(jj-1)*0.025,stateNames{jj},stateNames{jj},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[1 1 1 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
                    end
                end
            end
        end
    end
    
    function plotEventData(t1,t2,colorIn1,colorIn2)
        % Plot events
        xlim1 = UI.zoom.global{1}(1,:);
        ylim1 = UI.zoom.global{1}(2,:);
        
        ydata2 = [0; 0.5];
        idx = find(data.events.(UI.settings.eventData).time >= t1 & data.events.(UI.settings.eventData).time <= t2);
        
        % Plotting flagged events in a different color
        if isfield(data.events.(UI.settings.eventData),'flagged')
            idx2 = ismember(idx,data.events.(UI.settings.eventData).flagged);
            if any(idx2)
                raster_line(UI.plot_axis3,data.events.(UI.settings.eventData).time(idx(idx2))',ydata2+0.5,'m')
            end
            idx(idx2) = [];
        end
        
        % Plotting events 
        if any(idx)
            raster_line(UI.plot_axis3,data.events.(UI.settings.eventData).time(idx)',ydata2,colorIn1)
        end
        
        function raster_line(ax1,x1,y_lim,color)
            x_data = [1;1;nan]*x1;
            y_data = [y_lim;nan]*ones(1,numel(x1));
            line(ax1,x_data(:),y_data(:),'Marker','none','LineStyle','-','color',color, 'HitTest','off','linewidth',0.5);
        end
    end
    
    function addStateDialog(states)
        if isempty(UI.settings.states)
            statesList = {'Add to new state'};
        else
            statesList = [UI.settings.states,'Add to new state'];
        end
        [selectedState,~] = listdlg('PromptString',['Assign state to ' num2str(size(states,1)) ' intervals'],'ListString',statesList,'SelectionMode','single','ListSize',[200,150]);
        if ~isempty(selectedState) && selectedState < numel(statesList)
            addNewStateIntervals(states,UI.settings.states{selectedState})
            MsgLog([num2str(size(states,1)), ' intervals assigned to ', UI.settings.states{selectedState}],1);
        elseif ~isempty(selectedState) && selectedState == numel(statesList)
            newState = addNewState;
            if ~isempty(newState)
                addNewStateIntervals(states,newState)
                UI.settings.states = fieldnames(dataIn.states);
                updateUIStates
                MsgLog([num2str(size(states,1)), ' intervals assigned to ', newState]);
            end
            
        end
        uiresume(UI.fig);
    end
    
    function substractStateDialog(states)
        [selectedState,~] = listdlg('PromptString',['Substract states from ' num2str(size(states,1)) ' intervals'],'ListString',UI.settings.states,'SelectionMode','single','ListSize',[200,150]);
        if ~isempty(selectedState)
            stateName = UI.settings.states{selectedState};
            if isfield(dataIn,'states') && isfield(dataIn.states,stateName) && ~isempty(dataIn.states.(stateName))
                dataIn.states.(stateName) = SubtractIntervals(dataIn.states.(stateName),states);
                MsgLog([num2str(size(states,1)), ' intervals removed from ', UI.settings.states{selectedState}],1);
                updateUIStates
            end
            
        end
        uiresume(UI.fig);
    end
    
    function newState = addNewState
        answer = inputdlg({'State name'},'Add new state', [1 50],{''});
        if ~isempty(answer) && ~strcmp(answer{1},'') && isvarname(answer{1}) && (isempty(UI.settings.states) || ~ismember(answer{1},UI.settings.states))
            newState = answer{1};
        else
            newState = '';
        end
    end
    
    function exitStateExplorer(~,~)
        close(UI.fig);
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
                web('https://cellexplorer.org/interface/interface/','-new','-browser')
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
                msgbox(message,'StateExplorer',dialog1);
            end
            if any(priority == 3)
                warning(message)
            end
            if any(priority == 4)
                warndlg(message,'StateExplorer')
            end
        end
    end
    
end