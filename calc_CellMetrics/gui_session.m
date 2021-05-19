function [session,parameters,statusExit] = gui_session(sessionIn,parameters,activeTab)
% Displays a GUI allowing you to edit parameters for the CellExplorer and metadata for a session
%
% INPUTS
% sessionIn  : session struct to load into the GUI
% parameters : specific to the CellExplorer. Allows you to adjust its parameters from the GUI
%
% - Example calls:
% gui_session             % Tries to load session from current path, assumed to be a basepath. If no session struct exist, it will ask for user input
% gui_session(session)    % Load gui from session struct
% gui_session(basepath)   % Load from basepath
%
% OUTPUTS
% session    : session struct
% parameters : parameters struct
% statusExit : Whether the GUI was closed via the OK button or canceled

% gui_session is part of CellExplorer: https://cellexplorer.org/

% % % % % % % % % % % % % % % % % % % % % %
% Database initialization
if exist('db_load_settings','file') == 2
    db_settings = db_load_settings;
    if ~strcmp(db_settings.credentials.username,'user')
        enableDatabase = 1;
    else
        enableDatabase = 0;
    end
else
    enableDatabase = 0;
end
uiLoaded = false;

% Lists
UI.list.sortingMethod = {'KiloSort','KiloSort2','KiloSort3','SpyKING CIRCUS','Klustakwik','MaskedKlustakwik','MountainSort','IronClust','MClust','Wave_clus'}; % Spike sorting methods
UI.list.sortingFormat = {'Phy','KiloSort','SpyKING CIRCUS','Klustakwik','KlustaViewa','Neurosuite','MountainSort','IronClust','ALF','allensdk','MClust','Wave_clus'}; % Spike sorting formats
UI.list.inputsType = {'adc','aux','dat','dig'}; % input data types
UI.list.sessionTypes = {'Acute','Chronic','Unknown'}; % session types
UI.list.species = {'Unknown','Rat', 'Mouse','Red-eared Turtles'}; % animal species
UI.list.strain = {'Unknown','C57B1/6','B6/FVB Hybrid','BALB/cJ','Red-eared slider','DBA2/J','Brown Norway','Fischer 344','Long Evans','Sprague Dawleys','Wistar'}; % animal strains
UI.list.strain_species = {'Unknown','Mouse','Mouse','Mouse','Red-eared Turtles','Mouse','Rat','Rat','Rat','Rat','Rat'}; % animal strains parent in species

% metrics in cell metrics pipeline
UI.list.metrics = {'waveform_metrics','PCA_features','acg_metrics','deepSuperficial','monoSynaptic_connections','theta_metrics','spatial_metrics','event_metrics','manipulation_metrics','state_metrics','psth_metrics'};

% Parameters in cell metrics pipeline
UI.list.params = {'getWaveformsFromDat','excludeManipulationIntervals','manualAdjustMonoSyn','includeInhibitoryConnections','keepCellClassification','summaryFigures','forceReload','forceReloadSpikes','saveMat','saveBackup','debugMode'};
if enableDatabase
    UI.list.params =  {UI.list.params{:},'submitToDatabase'};
end

layout = {};

% % % % % % % % % % % % % % % % % % % %
% Handling inputs
% % % % % % % % % % % % % % % % % % % %

if isdeployed && ~(exist('sessionIn','var') && isstruct(sessionIn))% Check for if gui_session is running as a deployed app (compiled .exe or .app for windows and mac respectively)
    
    if exist('sessionIn','var') && ~isempty(sessionIn) % If a file name is provided it will load it.
        filename = sessionIn;
        [basepath1,file1] = fileparts(sessionIn);
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
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
         session = loadSession(basepath,basename);
         sessionIn = session;
    end

elseif exist('sessionIn','var') && isstruct(sessionIn)
    session = sessionIn;
    if isfield(session.general,'basePath')
        basepath = session.general.basePath;
    else
        basepath = '';
    end
elseif exist('sessionIn','var') && ischar(sessionIn) && exist(sessionIn,'file') == 2
    disp(['Loading from session file: ' sessionIn]);
    load(fullfile(sessionIn),'session');
    [filepath,~,~] = fileparts(sessionIn);
    basepath = filepath;
    sessionIn = session;
elseif exist('sessionIn','var') && ischar(sessionIn) && exist(sessionIn,'dir') == 7
    disp(['Loading from basepath: ' sessionIn]);
     basepath = sessionIn;
     [~,basename,~] = fileparts(sessionIn);
     if exist(fullfile(basepath,[basename,'.session.mat']),'file')
         session = loadSession(basepath,basename);
     else
         session = sessionTemplate(basepath);
     end
     sessionIn = session;
else
    basepath = pwd;
    [~,basename,~] = fileparts(pwd);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        disp(['Loading ',basename,'.session.mat from current path']);
        session = loadSession(basepath,basename);
        sessionIn = session;
    elseif exist(fullfile(basepath,'session.mat'),'file')
        disp('Loading session.mat from current path');
        load(fullfile(basepath,'session.mat'),'session');
        sessionIn = session;
    else
        answer = questdlg([basename,'.session.mat does not exist. Would you like to create one from a template or locate an existing session file?'],'No basename.session.mat file found','Create from template', 'Load from database','Locate file','Create from template');
        % Handle response
        switch answer
            case 'Create from template'
                session = sessionTemplate(pwd);
                sessionIn = session;
                basepath = session.general.basePath;
            case 'Locate file'
                [file,basepath] = uigetfile('*.mat','Please select a session.mat file','*.session.mat');
                if ~isequal(file,0)
                    cd(basepath)
                    temp = load(file,'session');
                    sessionIn = temp.session;
                    session = sessionIn;
                else
                    warning('Please provide a session struct')
                    return
                end
            case 'Load from database'
                [~,nameFolder,~] = fileparts(pwd);
                session.general.name = nameFolder;
                success = updateFromDB;
                if success == 0
                    warning('Failed to load session metadata from database');
                    return
                end
            otherwise
                return
        end
    end
end

% The session must have a field specifying the version as some changes to the structure has broken compatibility with earlier standard
if ~isfield(session.general,'version') || session.general.version<4
    if isfield(session.general,'entryID')
        % Importing session metadata from DB if metadata is out of data
        disp('Metadata not up to date. Downloading from server')
        success = updateFromDB;
        if success == 0
            return
        end
    else
        answer = questdlg('Metadata not up to date. Would you like to update it using the template?','Metadata not up to date','Update from template','Cancel','Update from template');
        switch answer
            case 'Update from template'
                disp('Updating session using the template')
                session = sessionTemplate(session);
                disp(['Saving ',session.general.name,'.session.mat'])
                try
                    save(fullfile(session.general.name,[basepath,'session.mat']),'session','-v7.3','-nocompression');
                    success = 1;
                catch
                    warning(['Failed to save ',session.general.name,'.session.mat. Location not available']);
                end
            otherwise
                return
        end
    end
end
if isfield(session.animal,'species') && ~ismember(session.animal.species,UI.list.species)
    UI.list.species = [UI.list.species,session.animal.species];
end
if isfield(session.animal,'strain') && isfield(session.animal,'species') && ~ismember(session.animal.strain,UI.list.strain)
    UI.list.strain = [UI.list.strain,session.animal.strain];
    UI.list.strain_species = [UI.list.strain_species,session.animal.species];
end

session.general.basePath = basepath;
statusExit = 0;

%% % % % % % % % % % % % % % % % % % % %
% Initializing GUI
% % % % % % % % % % % % % % % % % % % %

% Creating figure for the GUI
UI.fig = figure('units','pixels','position',[50,50,780,550],'Name','Session metadata','NumberTitle','off','renderer','opengl', 'MenuBar', 'None','PaperOrientation','landscape','visible','off');
movegui(UI.fig,'center')

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

% File
UI.menu.file.topMenu = uimenu(UI.fig,menuLabel,'File');
uimenu(UI.menu.file.topMenu,menuLabel,'Save session file',menuSelectedFcn,@(~,~)saveSessionFile,'Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Import metadata from KiloSort',menuSelectedFcn,@(~,~)importKiloSort,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Import metadata via template script',menuSelectedFcn,@(~,~)importMetadataTemplate);
uimenu(UI.menu.file.topMenu,menuLabel,'Import electrode layout from xml file',menuSelectedFcn,@(~,~)importGroupsFromXML,'Separator','on','Accelerator','I');
uimenu(UI.menu.file.topMenu,menuLabel,'Import bad channels from xml file',menuSelectedFcn,@importBadChannelsFromXML,'Accelerator','S');
uimenu(UI.menu.file.topMenu,menuLabel,'Import time series from Intan info.rhd',menuSelectedFcn,@importMetaFromIntan,'Accelerator','T');
uimenu(UI.menu.file.topMenu,menuLabel,'Import merge points (*.mergePoints.events.mat)',menuSelectedFcn,@importEpochsIntervalsFromMergePoints,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Import epoch info from parent sessions',menuSelectedFcn,@importFromFiles);
uimenu(UI.menu.file.topMenu,menuLabel,'Generate animal metadata template',menuSelectedFcn,@(~,~)generateAnimalMetadataTemplate,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Exit GUI with changes',menuSelectedFcn,@(~,~)CloseMetricsWindow,'Separator','on');
uimenu(UI.menu.file.topMenu,menuLabel,'Exit GUI without changes',menuSelectedFcn,@(~,~)cancelMetricsWindow);

% Extracellular
UI.menu.extracellular.topMenu = uimenu(UI.fig,menuLabel,'Extracellular');
uimenu(UI.menu.extracellular.topMenu,menuLabel,'Verify electrode group(s)',menuSelectedFcn,@verifyElectrodeGroup);
uimenu(UI.menu.extracellular.topMenu,menuLabel,'Sync electrode groups',menuSelectedFcn,@(~,~)syncChannelGroups);
uimenu(UI.menu.extracellular.topMenu,menuLabel,'Generate channel map',menuSelectedFcn,@(~,~)generateChannelMap1,'Separator','on');
uimenu(UI.menu.extracellular.topMenu,menuLabel,'Generate common coordinates',menuSelectedFcn,@(~,~)generateCommonCoordinates1);

% CellExplorer
UI.menu.CellExplorer.topMenu = uimenu(UI.fig,menuLabel,'CellExplorer');
uimenu(UI.menu.CellExplorer.topMenu,menuLabel,'Verfiy metadata',menuSelectedFcn,@performStructVerification,'Accelerator','V');

% Database
if enableDatabase
    UI.menu.buzLabDB.topMenu = uimenu(UI.fig,menuLabel,'BuzLabDB');
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Upload metadata to DB',menuSelectedFcn,@(~,~)buttonUploadToDB,'Accelerator','U');
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Download metadata from DB',menuSelectedFcn,@(~,~)buttonUpdateFromDB,'Accelerator','D');
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Edit credentials',menuSelectedFcn,@editDBcredentials,'Separator','on');
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Edit repository paths',menuSelectedFcn,@editDBrepositories);
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Update metadata model',menuSelectedFcn,@(~,~)db_load_metadata_model,'Separator','on');
    uimenu(UI.menu.buzLabDB.topMenu,menuLabel,'Get animal metadata',menuSelectedFcn,@(~,~)getAnimalMetadata);
end

% Help
UI.menu.help.topMenu = uimenu(UI.fig,menuLabel,'Help');
uimenu(UI.menu.help.topMenu,menuLabel,'Tutorial on session metadata',menuSelectedFcn,@buttonHelp);
uimenu(UI.menu.help.topMenu,menuLabel,'Documentation of session metadata structure',menuSelectedFcn,@buttonHelp,'Accelerator','H');
    
%% % % % % % % % % % % % % % % % % % % %
% Initializing tabs
% % % % % % % % % % % % % % % % % % % %

UI.grid_panels = uix.Grid( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 3); % Flexib grid box
UI.panel.left = uix.VBox('Parent',UI.grid_panels, 'Padding', 0); % Left panel
UI.panel.center = uix.VBox( 'Parent', UI.grid_panels, 'Padding', 0); % Center flex box
set(UI.grid_panels, 'Widths', [150 -1],'MinimumWidths',[100 1]); % set grid panel size

% UI.panel.title = uix.BoxPanel('Parent',UI.panel.center,'title','');
UI.panel.title = uicontrol('Parent',UI.panel.center,'Style', 'text', 'String', '','ForegroundColor','w','HorizontalAlignment','center', 'fontweight', 'bold','Units','normalized','BackgroundColor',[0. 0.3 0.7],'FontSize',11);
UI.panel.main = uipanel('Parent',UI.panel.center); % Main plot panel
% UI.panel.bottom  = uix.HBox('Parent',UI.panel.center, 'Padding', 3); % Lower info panel
set(UI.panel.center, 'Heights', [20 -1]); % set center panel size

tabsList = {'general','epochs','animal','extracellular','spikeSorting','brainRegions','channelTags','inputs','behaviors'};
tabsList2 = {'General','Epochs','Animal subject','Extracellular','Spike sorting','Brain regions','Tags','Time series & inputs','Behavioral tracking'};
if exist('parameters','var') && ~isempty(parameters)
    tabsList = ['parameters',tabsList];
    tabsList2 = ['CellExplorer',tabsList2];
end
UI.panel.title2 = uicontrol('Parent',UI.panel.left,'Style', 'text', 'String', 'Groups','ForegroundColor','w','HorizontalAlignment','center', 'fontweight', 'bold','Units','normalized','BackgroundColor',[0. 0.3 0.7],'FontSize',11);
for iTabs = 1:numel(tabsList)
    UI.buttons.(tabsList{iTabs}) = uicontrol('Parent',UI.panel.left,'Style','togglebutton','Units','normalized','String',tabsList2{iTabs},'Callback',@changeTab);
    UI.tabs.(tabsList{iTabs}) = uipanel('Parent',UI.panel.main,'Visible','off','Units','normalized','Position',[0 0 600 600],'BorderType','none');
end
uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.panel.left);
UI.button.ok = uicontrol('Parent',UI.panel.left,'Style','pushbutton','Position',[10, 5, 100, 30],'String','OK','Callback',@(src,evnt)CloseMetricsWindow,'Units','normalized','Interruptible','off','tooltip',sprintf('Exit GUI whlie keeping changes. \nDoes not save to file'));
UI.button.save = uicontrol('Parent',UI.panel.left,'Style','pushbutton','Position',[120, 5, 100, 30],'String','Save','Callback',@(src,evnt)saveSessionFile,'Units','normalized','Interruptible','off','tooltip',sprintf('Save to session.mat file'));
UI.button.cancel = uicontrol('Parent',UI.panel.left,'Style','pushbutton','Position',[230, 5, 100, 30],'String','Cancel','Callback',@(src,evnt)cancelMetricsWindow,'Units','normalized','Interruptible','off','tooltip',sprintf('Exit GUI without keeping any changes'));

set(UI.panel.left, 'Heights', [20,32*ones(size(tabsList)),-1,30,30,30],'MinimumHeights',[20,32*ones(size(tabsList)),5,30,30,30],'Spacing', 3);

% Buttons
% UI.popupmenu.log = uicontrol('Parent',UI.panel.bottom,'Style','popupmenu','String',{'Message log'},'HorizontalAlignment','left','FontSize',10,'Position',[340, 10, 270, 20],'Units','normalized');
% set(UI.panel.bottom, 'Widths', [-1],'MinimumWidths',[60]);

% % % % % % % % % % % % % % % % % % % %
% CellExplorer: Cell metrics parameters

if exist('parameters','var') && ~isempty(parameters)
    % Include metrics
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Include metrics (default: all)', 'Position', [5, 500, 190, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.listbox.includeMetrics = uicontrol('Parent',UI.tabs.parameters,'Style','listbox','Position',[5 340 190 160],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.metrics),'Units','normalized','tooltip',sprintf('Select metrics to process by type'));
    
    % Exclude metrics
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Exclude metrics (default: none)', 'Position', [210, 500, 190, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.listbox.excludeMetrics = uicontrol('Parent',UI.tabs.parameters,'Style','listbox','Position',[210 340 190 160],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.excludeMetrics),'Units','normalized','tooltip',sprintf('Select metrics not to process by type'));
    
    % Metrics to restrict analysis to for manipulations
    UI.list.metrics = unique([UI.list.metrics,'other_metrics',parameters.metricsToExcludeManipulationIntervals],'stable');
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Exclude manipulation intervals', 'Position', [415, 500, 195, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.listbox.metricsToExcludeManipulationIntervals = uicontrol('Parent',UI.tabs.parameters,'Style','listbox','Position',[415 340 195 160],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.metricsToExcludeManipulationIntervals),'Units','normalized','tooltip',sprintf('Select metrics to exclude manipulation intervals'));

    % Parameters
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Parameters', 'Position', [10, 320, 288, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    for iParams = 1:length(UI.list.params)
        if iParams <=4
            offset = 10;
        elseif iParams >8
            offset = 410;
        else
            offset = 210;
        end
        UI.checkbox.params(iParams) = uicontrol('Parent',UI.tabs.parameters,'Style','checkbox','Position',[offset 305-rem(iParams-1,4)*18 260 15],'Units','normalized','String',UI.list.params{iParams});
    end
    
    
    if isdeployed
        classification_schema_list = {'standard'};
        classification_schema_value = 1;
    else
        classification_schema_list = what('celltype_classification');
        classification_schema_list = cellfun(@(X) X(1:end-2),classification_schema_list.m,'UniformOutput', false);
        
        classification_schema_value = find(strcmp(parameters.preferences.putativeCellType.classification_schema,classification_schema_list));
    end
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Cell-type classification schema', 'Position', [10, 225, 200, 15],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.edit.classification_schema = uicontrol('Parent',UI.tabs.parameters,'Style', 'popup', 'String', classification_schema_list, 'value', classification_schema_value, 'Position', [5, 200, 200, 20],'HorizontalAlignment','left','Units','normalized');

    uicontrol('Parent',UI.tabs.parameters,'Style','pushbutton','Position',[415, 210, 195, 30],'String','Verfiy metadata','Callback',@(src,evnt)performStructVerification,'Units','normalized');
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Preferences', 'Position', [10, 175, 200, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.buttons.preferences = uicontrol('Parent',UI.tabs.parameters,'Style', 'pushbutton', 'String', 'Edit preferences', 'Position', [415, 180, 195, 30],'HorizontalAlignment','right','Units','normalized','Callback',@edit_preferences_ProcessCellMetrics);
    UI.table.preferences = uitable(UI.tabs.parameters,'Data',{},'Position',[5, 5, 605 , 170],'ColumnWidth',{100 160 320},'columnname',{'Category','Name','Value'},'RowName',[],'ColumnEditable',[false false false],'Units','normalized');
end

% % % % % % % % % % % % % % % % % % % %
% General

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Session name (basename)', 'Position', [10, 498, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.session = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.name, 'Position', [10, 475, 600, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('The name of the session (basename)'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Basepath', 'Position', [10, 448, 300, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.basepath = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 425, 600, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('The path to the dataset'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Session type', 'Position', [10, 398, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sessionType = uicontrol('Parent',UI.tabs.general,'Style', 'popup', 'String', UI.list.sessionTypes, 'Position', [10, 375, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Session type'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Duration (sec)', 'Position', [300, 398, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.duration = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 375, 310, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Duration of the session (seconds)'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Date (yyyy-mm-dd)', 'Position', [10, 348, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.date = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 325, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Date of the session (YYYY-MM-DD)'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Time (hh:mm:ss)', 'Position', [300, 348, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.time = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 325, 310, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Time of the session start (24 hour; HH:MM:SS)'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Location', 'Position', [10, 298, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.location = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 275, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Location of the session; e.g. room number'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Experimenters', 'Position', [300, 298, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.experimenters = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 275, 310, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Persons involved in doing the experiments'));

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Investigator', 'Position', [10, 253, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.investigator = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 230, 140, 25],'HorizontalAlignment','left','Units','normalized');
UI.edit.investigatorDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[160, 230, 130, 25],'String','View db investigator','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Projects', 'Position', [300, 253, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.projects = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 230, 160, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Projects'));
UI.edit.projectsDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[470, 230, 140, 25],'String','View db projects','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Repositories', 'Position', [10, 203, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.repositories = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 180, 140, 25],'HorizontalAlignment','left','Units','normalized');
UI.edit.repositoryDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[160, 180, 130, 25],'String','View db repository','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'DB entry ID', 'Position', [300, 203, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sessionID = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 180, 160, 25],'HorizontalAlignment','left','Units','normalized','enable','off','tooltip',sprintf('BuzLabDB specific field'));
UI.edit.sessionDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[470, 180, 140, 25],'String','View db session','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Notes', 'Position', [10, 148, 600, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.notes = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 10, 600, 140],'HorizontalAlignment','left','Units','normalized', 'Min', 0, 'Max', 200);


% % % % % % % % % % % % % % % % % % % % %
% Epochs

tableData = {false,'','',''};
% uicontrol('Parent',UI.tabs.epochs,'Style', 'text', 'String', 'Epochs', 'Position', [10, 200, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.table.epochs = uitable(UI.tabs.epochs,'Data',tableData,'Position',[1, 45, 619, 475],'ColumnWidth',{20 20 160 80 80 100 100 100 60 95},'columnname',{'','','Name','Start time','Stop time','Paradigm','Environment','Manipulations','Stimuli','Notes'},'RowName',[],'ColumnEditable',[true false true true true true true true true true],'ColumnFormat',{'logical','numeric','char','numeric','numeric','char','char','char','char','char'},'Units','normalized','CellEditCallback',@editEpochsTableData);
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add','Callback',@(src,evnt)addEpoch,'Units','normalized','Interruptible','off');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit','Callback',@(src,evnt)editEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[235, 5 110, 32],'String','Delete','Callback',@(src,evnt)deleteEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[350, 5, 110, 32],'String','Duplicate','Callback',@(src,evnt)duplicateEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[500, 5, 50, 32],'String',char(8593),'Callback',@(src,evnt)moveUpEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[555, 5 50, 32],'String',char(8595),'Callback',@(src,evnt)moveDownEpoch,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Animal

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Name', 'Position', [10, 500, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.name = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [10, 475, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Name of animal subject'));

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Sex', 'Position', [300, 500, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sex = uicontrol('Parent',UI.tabs.animal,'Style', 'popup', 'String', {'Unknown','Male','Female'}, 'Position', [300, 475, 310, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Sex of animal subject'));

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Species', 'Position', [10, 450, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.species = uicontrol('Parent',UI.tabs.animal,'Style', 'popup', 'String', UI.list.species, 'Position', [10, 425, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Species of animal subject\nE.g. Rats and Mouse'),'Callback',@(src,evnt)updateStrain);

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Strain', 'Position', [300, 450, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.strain = uicontrol('Parent',UI.tabs.animal,'Style', 'popup', 'String', UI.list.strain, 'Position', [300, 425, 310, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Strain of animal subject'));

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Genetic line', 'Position', [10, 400, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.geneticLine = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [10, 375, 280, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Genetic line of animal subject (e.g. Wild type)'));


UI.animalMetadata = uitabgroup('units','pixels','Position',[0, 0, 619, 365],'Parent',UI.tabs.animal,'Units','normalized');

% Implanted probes tab
layout.probeImplants.name = 'probeImplants';
layout.probeImplants.title = 'Probe implants';
layout.probeImplants.field_names = {'probe','brainRegion','ap','ml','depth','ap_angle','ml_angle','rotation'};
layout.probeImplants.field_title = {'Probe','Brain region','AP (mm)','ML (mm)','Depth (mm)','AP angle','ML angle','Rotation'};
layout.probeImplants.field_required = [true true false false false false false false];
layout.probeImplants.field_type = {'probes','brainRegions','text','text','text','text','text','text'};
layout.probeImplants.field_style = {'popup','popup','edit','edit','edit','edit','edit','edit'};
layout.probeImplants.field_relationship = {'probes','brainRegions','text','text','text','text','text','text'};
layout.probeImplants.column_widths = {290 80 60 60 80 60 60 60};
layout.probeImplants.column_format = {'char','char','numeric','numeric','numeric','numeric','numeric','numeric'};
layout.probeImplants.column_editable = [false false true true true true true true];
layout.probeImplants.probes.display = {'supplier','descriptiveName'};
generateTabdata(layout.probeImplants)

% Optic fibers tab
layout.opticFiberImplants.name = 'opticFiberImplants';
layout.opticFiberImplants.title = 'Optic fibers implants';
layout.opticFiberImplants.field_names = {'opticFiber','brainRegion','ap','ml','depth','ap_angle','ml_angle','notes'};
layout.opticFiberImplants.field_title = {'Optic fiber','Target region','AP (mm)','ML (mm)','Depth (mm)','AP angle','ML angle','Notes'};
layout.opticFiberImplants.field_required = [true false false false false false false false];
layout.opticFiberImplants.field_type = {'opticfibers','brainRegions','text','text','text','text','text','text'};
layout.opticFiberImplants.field_style = {'popup','popup','edit','edit','edit','edit','edit','edit'};
layout.opticFiberImplants.field_relationship = {'opticfibers','brainRegions','text','text','text','text','text','text'};
layout.opticFiberImplants.column_format = {'char','char','numeric','numeric','numeric','numeric','numeric','char'};
layout.opticFiberImplants.column_editable = [false false true true true true true true];
layout.opticFiberImplants.column_widths = {180 80 70 70 80 70 70 70};
layout.opticFiberImplants.opticfibers.display = {'supplier','opticFiber'};
layout.opticFiberImplants.opticfibers.save = {'supplier','opticFiber'};
generateTabdata(layout.opticFiberImplants)

% Surgeries tab
layout.surgeries.name = 'surgeries';
layout.surgeries.title = 'Surgeries';
layout.surgeries.field_names = {'date','start_time','end_time','weight','type_of_surgery','room','persons_involved','anesthesia','analgesics','antibiotics','complications','notes'};
layout.surgeries.field_title = {'Date','Start time','End time','Weight (g)','Type of Surgery','Room','Persons involved','Anesthesia','Analgesics','Antibiotics','Complications','Notes'};
layout.surgeries.field_required = [true true true false false false false false false false false false];
layout.surgeries.field_type = {'text','text','text','text',{'Chronic','Acute'},'text','text','text','text','text','text','text'};
layout.surgeries.field_style = {'edit','edit','edit','edit','popup','edit','edit','edit','edit','edit','edit','edit'};
layout.surgeries.field_relationship = {'text','text','text','text','text','text','text','text','text','text','text','text'};
layout.surgeries.column_format = {'char','char','char','numeric',{'Chronic','Acute'},'char','char','char','char','char','char','char'};
layout.surgeries.column_editable = [true true true true true true true true true true true true];
layout.surgeries.column_widths = {80 80 70 60 100 60 100 80 80 80 90 80};
generateTabdata(layout.surgeries)

% Virus injections tab
layout.virusInjections.name = 'virusInjections';
layout.virusInjections.title = 'Virus injections';
layout.virusInjections.field_names = {'virus','brainRegion','injection_schema','notes','injection_volume','injection_rate','ap','ml','depth','ap_angle','ml_angle'};
layout.virusInjections.field_title = {'Virus','Target region','Injection schema','Notes','Injection volume (nL)','Injection rate (nL/s)','AP (mm)','ML (mm)','Depth (mm)','AP angle','ML angle'};
layout.virusInjections.field_required = [true true false false false false false false false false false];
layout.virusInjections.field_type = {'text','brainRegions',{'Unknown','Gradual','Pulses'},'text','text','text','text','text','text','text','text'};
layout.virusInjections.field_style = {'edit','popup','popup','edit','edit','edit','edit','edit','edit','edit','edit'};
layout.virusInjections.field_relationship = {'text','brainRegions','text','text','text','text','text','text','text','text','text'};
layout.virusInjections.column_format = {'char','char',{'Unknown','Gradual','Pulses'},'char','numeric','numeric','numeric','numeric','numeric','numeric','numeric'};
layout.virusInjections.column_editable = [true false true true true true true true true true true];
layout.virusInjections.column_widths = {80 80 100 60 120 120 60 60 80 60 60};
generateTabdata(layout.virusInjections)

% UI.tabs.injections = uitab(UI.animalMetadata,'Title','Injections');

% % % % % % % % % % % % % % % % % % % % %
% Extracellular

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'nChannels', 'Position', [10, 498, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.nChannels = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 475, 180, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Number of channels'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Sampling rate (Hz)', 'Position', [200, 498, 190, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sr = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [200, 475, 190, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Sampling rate (Hz)'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'nSamples', 'Position', [400, 498, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.nSamples = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 475, 210, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Number of samples'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'File name (optional)', 'Position', [10, 448, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.fileName = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 425, 180, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Optional file name of binary file (if different from sessionName.dat)'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Least significant bit (µV; Intan: 0.195)', 'Position', [200, 448, 220, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.leastSignificantBit = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [200, 425, 190, 25],'HorizontalAlignment','left','Units','normalized','tooltip',['Least significant bit (', char(181),'V/bit, Intan=0.195, Amplipex=0.3815']);

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Precision (e.g. int16)', 'Position', [400 448, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.precision = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 425, 210, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('e.g. int16'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Equipment', 'Position', [10, 398, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.equipment = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 375, 380, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Hardware equipment use'));

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'LFP sampling rate (Hz)', 'Position', [400, 398, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.srLfp = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 375, 210, 25],'HorizontalAlignment','left','Units','normalized','tooltip',sprintf('Sampling rate of lfp file'));

% % % % % % % % % % % % % % % % % % % % % %
% Channel groups

UI.channelGroups = uitabgroup('units','pixels','Position',[0, 0, 619, 365],'Parent',UI.tabs.extracellular,'Units','normalized');

% Electrode and spike groups
groups = {'electrodeGroups','spikeGroups'};
titles = {'Electrode groups','Spike groups'};
for iGroups = 1:2
    UI.tabs.(groups{iGroups}) = uitab(UI.channelGroups,'Title',titles{iGroups});
    UI.list.tableData = {false,'','',''};
    UI.table.(groups{iGroups}) = uitable(UI.tabs.(groups{iGroups}),'Data',UI.list.tableData,'Position',[1, 45, 619, 320],'Tag','electrodeGroups','ColumnWidth',{20 45 400 120},'columnname',{'','Group','Channels','Labels'},'RowName',[],'ColumnEditable',[true false true true],'Units','normalized','CellEditCallback',@editElectrodeTableData);
    uicontrol('Parent',UI.tabs.(groups{iGroups}),'Style','pushbutton','Position',[5, 5, 110, 32],'Tag',groups{iGroups},'String','Add','Callback',@addElectrodeGroup,'Units','normalized');
    uicontrol('Parent',UI.tabs.(groups{iGroups}),'Style','pushbutton','Position',[120, 5, 110, 32],'Tag',groups{iGroups},'String','Edit','Callback',@addElectrodeGroup,'Units','normalized');
    uicontrol('Parent',UI.tabs.(groups{iGroups}),'Style','pushbutton','Position',[235, 5, 130, 32],'Tag',groups{iGroups},'String','Delete','Callback',@deleteElectrodeGroup,'Units','normalized');
    uicontrol('Parent',UI.tabs.(groups{iGroups}),'Style','pushbutton','Position',[510, 5, 50, 32],'Tag',groups{iGroups},'String',char(8593),'Callback',@moveElectrodes,'Units','normalized');
    uicontrol('Parent',UI.tabs.(groups{iGroups}),'Style','pushbutton','Position',[565, 5, 50, 32],'Tag',groups{iGroups},'String',char(8595),'Callback',@moveElectrodes,'Units','normalized');
end

% % % % % % % % % % % % % % % % % % % % %
% Spike sorting

tableData = {false,'','',''};
UI.table.spikeSorting = uitable(UI.tabs.spikeSorting,'Data',tableData,'Position',[1, 45, 619, 475],'ColumnWidth',{20 75 75 150 62 75 50 50 60},'columnname',{'','Method','Format','Relative path','Channels','Spike sorter','Notes','Metrics','Currated'},'RowName',[],'ColumnEditable',[true true true true true true true true true],'Units','normalized','ColumnFormat',{'logical',UI.list.sortingMethod,UI.list.sortingFormat,'char','char','char','char','logical','logical'},'CellEditCallback',@editSpikeSortingTableData);
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add sorting','Callback',@(src,evnt)addSpikeSorting,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit sorting','Callback',@(src,evnt)editSpikeSorting,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[235, 5, 130, 32],'String','Delete sorting(s)','Callback',@(src,evnt)deleteSpikeSorting,'Units','normalized');
% uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[330, 10, 160, 30],'String','Import sorting?','Callback',@(src,evnt)importBadChannelsFromXML,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Brain regions

UI.list.tableData = {false,'','','',''};
UI.table.brainRegion = uitable(UI.tabs.brainRegions,'Data',UI.list.tableData,'Position',[1, 45, 619, 475],'ColumnWidth',{20 70 280 95 147},'columnname',{'','Region','Channels','Electrode groups','Notes'},'RowName',[],'ColumnEditable',[true false true true true],'Units','normalized','CellEditCallback',@editBrainregionTableData);
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add region','Callback',@(src,evnt)addRegion,'Units','normalized');
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit region','Callback',@(src,evnt)editRegion,'Units','normalized');
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[235, 5, 120, 32],'String','Delete region(s)','Callback',@(src,evnt)deleteRegion,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Channel tags

tableData = {false,'','',''};
UI.table.tags = uitable(UI.tabs.channelTags,'Data',tableData,'Position',[1, 300, 619, 220],'ColumnWidth',{20 130 315 147},'columnname',{'','Channel tag','Channels','Electrode groups'},'RowName',[],'ColumnEditable',[true false true true],'Units','normalized','CellEditCallback',@editTagsTableData);
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[5, 260, 110, 32],'String','Add tag','Callback',@(src,evnt)addTag,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[120, 260, 110, 32],'String','Edit tag','Callback',@(src,evnt)editTag,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[235, 260, 110, 32],'String','Delete tag(s)','Callback',@(src,evnt)deleteTag,'Units','normalized');
% uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[470, 260, 140, 30],'String','Import bad channels','Callback',@(src,evnt)importBadChannelsFromXML,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Analysis tags

tableData = {false,'','',''};
UI.table.analysis = uitable(UI.tabs.channelTags,'Data',tableData,'Position',[1, 45, 619, 210],'ColumnWidth',{20 250 342},'columnname',{'','Analysis tag','Value'},'RowName',[],'ColumnEditable',[true false true],'Units','normalized','CellEditCallback',@editAnalysisTagsTableData);
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add tag','Callback',@(src,evnt)addAnalysis,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit tag','Callback',@(src,evnt)editAnalysis,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[235, 5, 110, 32],'String','Delete tag(s)','Callback',@(src,evnt)deleteAnalysis,'Units','normalized');
% uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[340, 10, 110, 30],'String','Duplicate tag','Callback',@(src,evnt)duplicateAnalysis,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Time series

tableData = {false,'','',''};
UI.table.timeSeries = uitable(UI.tabs.inputs,'Data',tableData,'Position',[1, 300, 619, 220],'ColumnWidth',{20 90 105 60 70 40 60 90 78},'columnname',{'','Time series tag','File name', 'Precision', 'nChannels', 'sr', 'nSamples', 'least significant bit', 'Equipment'},'RowName',[],'ColumnEditable',[true false true true true true true true true],'Units','normalized','CellEditCallback',@editTimeSeriesTableData);
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[5, 260, 110, 32],'String','Add time serie','Callback',@(src,evnt)addTimeSeries,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[120, 260, 110, 32],'String','Edit time serie','Callback',@(src,evnt)editTimeSeries,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[235, 260, 120, 32],'String','Delete time serie(s)','Callback',@(src,evnt)deleteTimeSeries,'Units','normalized');
% UI.button.importMetaFromIntan = uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[500, 10, 110, 30],'String','Import from Intan','Callback',@(src,evnt)importMetaFromIntan,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Inputs

tableData = {false,'','',''};
UI.table.inputs = uitable(UI.tabs.inputs,'Data',tableData,'Position',[1, 45, 619, 210],'ColumnWidth',{20 120 75 70 140 187},'columnname',{'','Input tag','Channels','Type','Equipment','Description'},'ColumnFormat',{'logical','char','char',UI.list.inputsType,'char','char'},'RowName',[],'ColumnEditable',[true false true true true true true],'Units','normalized','CellEditCallback',@editInputsTableData);
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add input','Callback',@(src,evnt)addInput,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit input','Callback',@(src,evnt)editInput,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[235, 5, 110, 32],'String','Delete input(s)','Callback',@(src,evnt)deleteInput,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% BehavioralTracking

tableData = {false,'','',''};
UI.table.behaviors = uitable(UI.tabs.behaviors,'Data',tableData,'Position',[1, 45, 619, 475],'ColumnWidth',{20 180 100 50 80 75 107},'columnname',{'','Filenames','Equipment','Epoch','Type','Frame rate','Notes'},'RowName',[],'ColumnEditable',[true true true true true true true],'Units','normalized','CellEditCallback',@editBehaviorTableData);
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[5, 5, 110, 32],'String','Add tracking','Callback',@(src,evnt)addBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[120, 5, 110, 32],'String','Edit tracking','Callback',@(src,evnt)editBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[235, 5, 110, 32],'String','Delete tracking(s)','Callback',@(src,evnt)deleteBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[350, 5, 110, 32],'String','Duplicate tracking','Callback',@(src,evnt)duplicateBehavior,'Units','normalized');

% Loading session struct into gui
importSessionStruct
UI.fig.Visible = 'on';
UI.activeTab = 1;
if exist('activeTab','var')
    idx1 = find(strcmp(tabsList,activeTab));
    if ~isempty(UI.activeTab)
        UI.activeTab = idx1;
    end
end
UI.tabs.(tabsList{UI.activeTab}).Visible = 'on';
UI.buttons.(tabsList{UI.activeTab}).Value = 1;
UI.buttons.(tabsList{UI.activeTab}).FontWeight = 'bold';
UI.buttons.(tabsList{UI.activeTab}).ForegroundColor = [0. 0.3 0.7];
UI.panel.title.String = tabsList2{UI.activeTab};
UI.fig.Name = ['Session metadata: ',session.general.name];
uiLoaded = true;
uiwait(UI.fig)

%% % % % % % % % % % % % % % % % % % % % %
% Embedded functions 
% % % % % % % % % % % % % % % % % % % % %

    function generateAnimalMetadataTemplate(~,~)
        readBackFields;
        pathparts = strsplit(session.general.basePath,filesep);
        filepath1 = session.general.basePath(1:end-numel(pathparts{end}));
        filename1 = [session.animal.name,'.session.mat'];
        session.general.name = session.animal.name;
        try
            save(fullfile(filepath1, filename1),'session','-v7.3','-nocompression');
            MsgLog(['Animal metadata template saved to: ' fullfile(filepath1, filename1)],2)
        catch
            MsgLog(['Failed to save ',filename1,'. Location not available'],4)
        end
    end
    
    function generateTabdata(metadataStruct)
        UI.list.tableData = {};
        UI.tabs.(metadataStruct.name) = uitab(UI.animalMetadata,'Title',metadataStruct.title);
        UI.tabs.panels.(metadataStruct.name).main = uix.VBox( 'Parent', UI.tabs.(metadataStruct.name), 'Padding', 0); % Center flex box
        UI.tabs.panels.(metadataStruct.name).table = uix.HBox('Parent',UI.tabs.panels.(metadataStruct.name).main, 'Padding', 0); % Main plot panel
        UI.tabs.panels.(metadataStruct.name).buttons  = uix.HBox('Parent',UI.tabs.panels.(metadataStruct.name).main, 'Padding', 3); % Lower info panel
        set(UI.tabs.panels.(metadataStruct.name).main, 'Heights', [-1 39]); % set center panel size
        UI.table.(metadataStruct.name) = uitable(UI.tabs.panels.(metadataStruct.name).table,'Data',UI.list.tableData,'Tag',metadataStruct.name,'Units','normalized','Position',[0, 0, 1, 1],'ColumnWidth',[20, metadataStruct.column_widths],'columnname',{'',metadataStruct.field_title{:}},'ColumnFormat',{'logical',metadataStruct.column_format{:}},'RowName',[],'ColumnEditable',[true metadataStruct.column_editable],'Units','normalized','CellEditCallback',@editTableData);
        updateAnimalMeta(metadataStruct.name)
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'Position',[10, 0, 110, 32],'String','Add','Callback',@animalMeta,'Units','normalized');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'Position',[130, 0, 110, 32],'String','Edit','Callback',@animalMeta,'Units','normalized');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'Position',[130, 0, 110, 32],'String','Duplicate','Callback',@animalMeta,'Units','normalized');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'Position',[250, 0, 130, 32],'String','Delete','Callback',@animalMeta,'Units','normalized');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','text','String','');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'String',char(8593),'Callback',@moveIt,'Units','normalized');
        uicontrol('Parent',UI.tabs.panels.(metadataStruct.name).buttons,'Style','pushbutton','Tag',metadataStruct.name,'String',char(8595),'Callback',@moveIt,'Units','normalized');
        set(UI.tabs.panels.(metadataStruct.name).buttons, 'Widths', [110 110 110 110 -1 50 50],'MinimumWidths',[110 110 110 110 10 50 50],'Spacing', 3);
    end
    
    function editTableData(src,evnt)
        if evnt.Indices(1,2)>1
            session.animal.(src.Tag){evnt.Indices(1,1)}.(layout.(src.Tag).field_names{evnt.Indices(1,2)-1}) = evnt.NewData;
        end
    end
    
    function moveIt(src,~)
        if~isempty(UI.table.(src.Tag).Data) && ~isempty(find([UI.table.(src.Tag).Data{:,1}], 1)) && sum([UI.table.(src.Tag).Data{:,1}])>0
            cell2move = [UI.table.(src.Tag).Data{:,1}];
            newOrder = 1:length(session.animal.(src.Tag));
            if strcmp(src.String,char(8595))
                offset = cumsumWithReset2(cell2move);
                newOrder1 = newOrder+offset;
            else
                offset = cumsumWithReset(cell2move);
                newOrder1 = newOrder-offset;
            end
            [~,newOrder] = sort(newOrder1);
            session.animal.(src.Tag) = session.animal.(src.Tag)(newOrder);
            updateAnimalMeta(src.Tag)
            UI.table.(src.Tag).Data(find(ismember(newOrder,find(cell2move))),1) = {true};
        else
            helpdlg('Please select the entry/entries to move','Error')
        end
    end
    
    function animalMeta(src,~)
        animalMetaType = layout.(src.Tag);
        if isfield(session.animal,(src.Tag))
            entry = numel(session.animal.(src.Tag))+1;
        else
            entry = 1;
        end
        
        switch src.String
            case {'Add','Edit'}
                % Add a new entry
                if strcmp(src.String,'Edit')
                    if ~isempty(UI.table.(src.Tag).Data) && ~isempty(find([UI.table.(src.Tag).Data{:,1}], 1)) && sum([UI.table.(src.Tag).Data{:,1}])==1
                        entry = find([UI.table.(src.Tag).Data{:,1}]);
                    else
                        helpdlg(['Please select an entry to edit'],'Error')
                        return
                    end
                end
                % Opens dialog
                UI.dialog.animal = dialog('Position', [300, 330, 330, numel(animalMetaType.field_names)*50+50],'Name',animalMetaType.title,'WindowStyle','modal'); movegui(UI.dialog.animal,'center')

                % Filling in dialog
                for i = 1:numel(animalMetaType.field_names)
                    if animalMetaType.field_required(i)
                        string_title = [animalMetaType.field_title{i},' *'];
                    else
                        string_title = animalMetaType.field_title{i};
                    end
                    titles1.(animalMetaType.field_names{i}) = uicontrol('Parent',UI.dialog.animal,'Style', 'text', 'String', string_title, 'Position', [10, numel(animalMetaType.field_names)*50+50-i*50+25, 300, 20],'HorizontalAlignment','left');
                    
                    if strcmp(animalMetaType.field_style{i},'edit')
                        if strcmp(src.String,'Edit') & isfield(session.animal.(src.Tag){entry},animalMetaType.field_names{i})
                            string1 = session.animal.(src.Tag){entry}.(animalMetaType.field_names{i});
                        else 
                            string1 = '';
                        end
                        fields1.(animalMetaType.field_names{i}) = uicontrol('Parent',UI.dialog.animal,'Style', 'Edit','Tag',animalMetaType.field_names{i}, 'String', string1, 'Position', [10, numel(animalMetaType.field_names)*50+50-i*50, 300, 25],'HorizontalAlignment','left');
                    
                    elseif strcmp(animalMetaType.field_style{i},'popup')
                        
                    if ~strcmp(animalMetaType.field_relationship{i},'text') && strcmp(animalMetaType.field_type{i},'brainRegions')
                        % Add new brain region to session struct
                        brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
                        brainRegions_list = strcat(brainRegions(:,2),' (',brainRegions(:,1),')');
                        
                        if strcmp(src.String,'Edit')
                            value1 = find(strcmp(brainRegions(:,2),session.animal.(src.Tag){entry}.(animalMetaType.field_names{i})));
                            if isempty(value1)
                                value1 = 1;
                            end
                        else
                            value1 = 1;
                        end
                        
                        fields1.(animalMetaType.field_names{i}) = uicontrol('Parent',UI.dialog.animal,'Style', 'popupmenu','Tag',animalMetaType.field_names{i}, 'String', brainRegions_list, 'Position', [10, numel(animalMetaType.field_names)*50+50-i*50, 300, 25],'HorizontalAlignment','left','value',value1);
                        
                    elseif ~strcmp(animalMetaType.field_relationship{i},'text')
                        if ~exist('db_metadata_model','var')
                            load('db_metadata_model.mat','db_metadata_model');
                        end
                        display = animalMetaType.(animalMetaType.field_relationship{i}).display;
                        list1 = cellfun(@(X) X.(display{1}), db_metadata_model.(animalMetaType.field_relationship{i}),'UniformOutput', false);
                        for j = 2:numel(display)
                            list1 = strcat(list1," - ",cellfun(@(X) X.(display{j}), db_metadata_model.(animalMetaType.field_relationship{i}),'UniformOutput', false));
                        end
                        
                        [list1,list_sorting] = sort(list1);
                        list_sorting1.(animalMetaType.field_names{i}) = list_sorting;
                        if strcmp(src.String,'Edit')
                            list2 = cellfun(@(X) X.(animalMetaType.field_names{i}), db_metadata_model.(animalMetaType.field_relationship{i}),'UniformOutput', false);
                            value1 = find(strcmp(list2(list_sorting),session.animal.(src.Tag){entry}.(animalMetaType.field_names{i})));
                            if isempty(value1)
                                value1 = 1;
                            end
                        else
                            value1 = 1;
                        end
                        fields1.(animalMetaType.field_names{i}) = uicontrol('Parent',UI.dialog.animal,'Style', 'popupmenu','Tag',animalMetaType.field_names{i}, 'String', list1, 'Position', [10, numel(animalMetaType.field_names)*50+50-i*50, 300, 25],'HorizontalAlignment','left','value',value1);
                        
                        
                    else
                        if strcmp(src.String,'Edit')
                            value1 = find(strcmp(animalMetaType.field_type{i},session.animal.(src.Tag){entry}.(animalMetaType.field_names{i})));
                            if isempty(value1)
                                value1 = 1;
                            end
                        else
                            value1 = 1;
                        end
                        fields1.(animalMetaType.field_names{i}) = uicontrol('Parent',UI.dialog.animal,'Style', 'popupmenu','Tag',animalMetaType.field_names{i}, 'String', animalMetaType.field_type{i}, 'Position', [10, numel(animalMetaType.field_names)*50+50-i*50, 300, 25],'HorizontalAlignment','left','value',value1);
                        
                    end
                    
                    end
                end
                uicontrol('Parent',UI.dialog.animal,'Style','pushbutton','Position',[10, 10, 150, 30],'String','Save','Callback',@(src,evnt)close_dialog);
                uicontrol('Parent',UI.dialog.animal,'Style','pushbutton','Position',[170, 10, 150, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
                
            case 'Duplicate'
                % Duplicate an existing
                if ~isempty(UI.table.(src.Tag).Data) && ~isempty(find([UI.table.(src.Tag).Data{:,1}], 1)) && sum([UI.table.(src.Tag).Data{:,1}])==1
                    entry_old = find([UI.table.(src.Tag).Data{:,1}]);
                    entry_new = numel(session.animal.(src.Tag))+1;
                    session.animal.(src.Tag){entry_new} = session.animal.(src.Tag){entry_old};
                    updateAnimalMeta(src.Tag)
                else
                    helpdlg('Please select entry to duplicate','Error')
                end
            case 'Delete'
                % Deletes selected entries
                if ~isempty(UI.table.(src.Tag).Data) && ~isempty(find([UI.table.(src.Tag).Data{:,1}], 1))
                    entry = find([UI.table.(src.Tag).Data{:,1}]);
                    session.animal.(src.Tag)(entry) = [];
                    updateAnimalMeta(src.Tag)
                else
                    helpdlg('Please select entry/entries to delete','Error')
                end
        end
        
        function close_dialog
            for i = 1:numel(animalMetaType.field_names)
                if animalMetaType.field_required(i) && isempty(fields1.(animalMetaType.field_names{i}).String)
                    titles1.(animalMetaType.field_names{i}).ForegroundColor = [1 0 0];
                    titles1.(animalMetaType.field_names{i}).FontWeight = 'bold';
                    helpdlg(['Please fill out required field: ' animalMetaType.field_title{i}],'Error');
                    return
                end
                if strcmp(animalMetaType.field_style{i},'edit')
                    if strcmp(animalMetaType.column_format{i},'numeric')
                        session.animal.(src.Tag){entry}.(animalMetaType.field_names{i}) = str2num(fields1.(animalMetaType.field_names{i}).String);
                    else
                        session.animal.(src.Tag){entry}.(animalMetaType.field_names{i}) = fields1.(animalMetaType.field_names{i}).String;
                    end
                    
                elseif strcmp(animalMetaType.field_style{i},'popup')
                    if strcmp(fields1.(animalMetaType.field_names{i}).Tag,'brainRegion')
                        session.animal.(src.Tag){entry}.(animalMetaType.field_names{i}) = brainRegions{fields1.(animalMetaType.field_names{i}).Value,2};
                    elseif ~strcmp(animalMetaType.field_relationship{i},'text')
                        if ~exist('db_metadata_model','var')
                            load('db_metadata_model.mat','db_metadata_model');
                        end
                        fields2copy = db_metadata_model.(animalMetaType.field_relationship{i}){list_sorting1.(animalMetaType.field_names{i})(fields1.(animalMetaType.field_names{i}).Value)};
                        fields = fieldnames(fields2copy);
                        fields(strcmp(fields,'id')) = [];
                        for j = 1:numel(fields)
                            session.animal.(src.Tag){entry}.(fields{j}) = fields2copy.(fields{j});
                        end
                    else
                        session.animal.(src.Tag){entry}.(animalMetaType.field_names{i}) = fields1.(animalMetaType.field_names{i}).String{fields1.(animalMetaType.field_names{i}).Value};
                    end
                end
            end
            updateAnimalMeta(src.Tag)
            delete(UI.dialog.animal)
        end
        
        function cancel_dialog
            delete(UI.dialog.animal)
        end
    end
    
    function updateAnimalMeta(datatype)
       % Updates table data
        if isfield(session.animal,datatype) && ~isempty(session.animal.(datatype))
            animalMetaType = layout.(datatype);
            tableData = {};
            nEntries = numel(session.animal.(datatype));
            for fn = 1:nEntries
                tableData{fn,1} = false;
                for i = 1:numel(animalMetaType.field_names)
                    if iscell(animalMetaType.field_type{i}) || strcmp(animalMetaType.field_type{i},'text') || strcmp(animalMetaType.field_type{i},'brainRegions')
                        if isfield(session.animal.(datatype){fn},animalMetaType.field_names{i})
                            tableData{fn,i+1} = session.animal.(datatype){fn}.(animalMetaType.field_names{i});
                        else
                            tableData{fn,i+1} = '';
                        end
                    else
                        display = animalMetaType.(animalMetaType.field_relationship{i}).display;
                        text1 = session.animal.(datatype){fn}.(display{1});
                        for j = 2:numel(display)
                            text1 = [text1,' - ',session.animal.(datatype){fn}.(display{j})];
                        end
                        tableData{fn,i+1} = text1;
                    end
                end
            end
            UI.table.(datatype).Data = tableData;
        else
            UI.table.(datatype).Data = {};
        end
    end
    
    function changeTab(src,~)
        UI.tabs.(tabsList{UI.activeTab}).Visible = 'off';
        UI.buttons.(tabsList{UI.activeTab}).Value = 0;
        UI.buttons.(tabsList{UI.activeTab}).FontWeight = 'normal';
        UI.buttons.(tabsList{UI.activeTab}).ForegroundColor = [0 0 0];
        
        UI.activeTab = find(strcmp(tabsList2,src.String));
        
        UI.tabs.(tabsList{UI.activeTab}).Visible = 'on';
        UI.buttons.(tabsList{UI.activeTab}).Value = 1;
        UI.buttons.(tabsList{UI.activeTab}).FontWeight = 'bold';
        UI.buttons.(tabsList{UI.activeTab}).ForegroundColor = [0. 0.3 0.7];
        UI.panel.title.String = tabsList2{UI.activeTab};
    end
    
    function importEpochsIntervalsFromMergePoints(~,~)
        % Epochs derived from MergePoints
        if exist(fullfile(UI.edit.basepath.String,[UI.edit.session.String,'.MergePoints.events.mat']),'file')
            temp = load(fullfile(UI.edit.basepath.String,[UI.edit.session.String,'.MergePoints.events.mat']));
            for i = 1:size(temp.MergePoints.foldernames,2)
                session.epochs{i}.name = temp.MergePoints.foldernames{i};
                session.epochs{i}.startTime = temp.MergePoints.timestamps(i,1);
                session.epochs{i}.stopTime = temp.MergePoints.timestamps(i,2);
            end
            updateEpochsList
            MsgLog('Epochs updated',2)
        else
            MsgLog(['No ', UI.edit.session.String,'.MergePoints.events.mat',' exist in basepath'],2)
        end
    end

    function importFromFiles(~,~)
        if ~isempty(session.epochs)
            answer = questdlg('Where is your epochs located?','Import epoch data','outside session level','inside session folder','outside session level');
            if ~isempty(answer)
                [filepath,~,~] = fileparts(UI.edit.basepath.String);
                fname = 'amplifier.dat';
                k = 0;
                for i = 1:size(session.epochs,2)
                    temp_ = [];
                    if strcmp(answer,'outside session level')
                        filepath1 = fullfile(filepath,session.epochs{i}.name,[session.epochs{i}.name,'.dat']);
                        filepath2 = fullfile(filepath,session.epochs{i}.name,fname);
                    else
                        filepath1 = fullfile(UI.edit.basepath.String,session.epochs{i}.name,[session.epochs{i}.name,'.dat']);
                        filepath2 = fullfile(UI.edit.basepath.String,session.epochs{i}.name,fname);
                    end
                    if exist(filepath1,'file')
                        temp_ = dir(filepath1);
                    elseif exist(filepath2,'file')
                        temp_ = dir(filepath2);
                    end
                    if exist(filepath1,'file') || exist(filepath2,'file')
                        session.epochs{i}.stopTime = temp_.bytes/session.extracellular.sr/session.extracellular.nChannels/2;
                        if i == 1
                            session.epochs{i}.startTime = 0;
                        else
                            session.epochs{i}.startTime = session.epochs{i-1}.stopTime;
                            session.epochs{i}.stopTime = session.epochs{i}.stopTime+session.epochs{i-1}.stopTime;
                        end
                        disp(['Epoch #' num2str(i),': ' num2str(session.epochs{i}.startTime),'-', num2str(session.epochs{i}.stopTime)])
                        k = k +1;
                    end
                end
                updateEpochsList
                msgbox([num2str(k), ' epoch intervals imported.']);
            end
        end
    end

    function openInWebDB(src,~)
        switch src.String
            case 'View db session'
                % Opens session in the Buzsaki lab web database
                web(['https://buzsakilab.com/wp/sessions/?frm_search=', session.general.name],'-new','-browser')
            case 'View db projects'
                % Opens project in the Buzsaki lab web database
                web(['https://buzsakilab.com/wp/projects/?frm_search=', session.general.projects],'-new','-browser')
            case 'View db investigator'
                % Opens session in the Buzsaki lab web database
                web(['https://buzsakilab.com/wp/persons/?frm_search=', session.general.investigator],'-new','-browser')
            case 'View db repository'
                % Opens session in the Buzsaki lab web database
                web(['https://buzsakilab.com/wp/repositories/?frm_search=', session.general.repositories{1}],'-new','-browser')
        end
    end
    
    function importMetaFromIntan(~,~)
        session = loadIntanMetadata(session);
        updateTimeSeriesList
        MsgLog('Updated from intan',2)
    end
    
    function importSessionStruct
        if exist('parameters','var') && ~isempty(parameters)
            for iParams = 1:length(UI.list.params)
                UI.checkbox.params(iParams).Value = parameters.(UI.list.params{iParams});
            end
            updatePreferencesTable
        end
        
        UI.edit.basepath.String = session.general.basePath;
%         UI.edit.clusteringpath.String = session.general.clusteringPath;
        UI.edit.session.String = session.general.name;
        UIsetString(session.general,'date');
        UIsetString(session.general,'time');
        UIsetString(session.general,'duration');
        if isfield(session.general,'experimenters') && ~isempty(session.general.experimenters)
            if iscell(session.general.experimenters)
                UI.edit.experimenters.String = strjoin(session.general.experimenters,', ');
            else
                UI.edit.experimenters.String = session.general.experimenters;
            end
        end
        if isfield(session.general,'location') && ~isempty(session.general.location)
            UI.edit.location.String = session.general.location;
        end
        if isfield(session.general,'notes') && ~isempty(session.general.notes)
%             session.general.notes = regexprep(session.general.notes, '<.*?>', '');
            UI.edit.notes.String = session.general.notes;
        end
        
        UIsetString(session.general,'investigator');
        if isfield(session.general,'entryID')
            UI.edit.sessionID.String = session.general.entryID;
            UI.edit.sessionDBbutton.Enable = 'on';
            UI.edit.projectsDBbutton.Enable = 'on';
            UI.edit.investigatorDBbutton.Enable = 'on';
            UI.edit.repositoryDBbutton.Enable = 'on';
        else
            UI.edit.sessionDBbutton.Enable = 'off';
            UI.edit.projectsDBbutton.Enable = 'off';
            UI.edit.investigatorDBbutton.Enable = 'off';
            UI.edit.repositoryDBbutton.Enable = 'off';
        end
        
        if isfield(session.general,'sessionType') && ~isempty(session.general.sessionType)
            UI.edit.sessionType.Value = find(strcmp(session.general.sessionType,UI.list.sessionTypes));
        end
        if isfield(session.general,'repositories') && ~isempty(session.general.repositories)
            if iscell(session.general.repositories)
                UI.edit.repositories.String = strjoin(session.general.repositories,', ');
            else
                UI.edit.repositories.String = session.general.repositories;
            end
        else
            UI.edit.repositories.String = '';
        end
        if isfield(session.general,'projects') && ~isempty(session.general.projects)
            if iscell(session.general.projects)
                UI.edit.projects.String = strjoin(session.general.projects,', ');
            else
                UI.edit.projects.String = session.general.projects;
            end
        end
        updateEpochsList
        UIsetString(session.animal,'name');
        UIsetValue(UI.edit.sex,session.animal.sex)
        UIsetValue(UI.edit.species,session.animal.species)
        updateStrain
        UIsetString(session.animal,'geneticLine');
        UIsetString(session.extracellular,'nChannels');
        UIsetString(session.extracellular,'sr');
        UIsetString(session.extracellular,'nSamples');
        UIsetString(session.extracellular,'precision');
        UIsetString(session.extracellular,'leastSignificantBit');
        UIsetString(session.extracellular,'fileName');
        UIsetString(session.extracellular,'equipment');
        UIsetString(session.extracellular,'srLfp');
        updateChannelGroupsList('electrodeGroups')
        updateChannelGroupsList('spikeGroups')
        updateSpikeSortingList
        updateBrainRegionList
        updateTagList
        updateInputsList
        updateBehaviorsList
        updateAnalysisList
        updateTimeSeriesList
    end
    
    function updateStrain
       UI.edit.strain.String = UI.list.strain(strcmp(UI.list.strain_species,UI.edit.species.String{UI.edit.species.Value})); 
       UIsetValue(UI.edit.strain,session.animal.strain);
    end
    
    function getAnimalMetadata
        db_animal_metadata = db_load_animal_metadata(session.animal.name);
        db_animal_metadata_fields = fieldnames(db_animal_metadata);
        for i = 1:numel(db_animal_metadata_fields)
            session.animal.(db_animal_metadata_fields{i}) = db_animal_metadata.(db_animal_metadata_fields{i});
            updateAnimalMeta(db_animal_metadata_fields{i})
            MsgLog('Animal metadata updated from database',2)
        end
    end
    
    function buttonUpdateFromDB
        answer = questdlg('Are you sure you want to update the session struct from the database?', 'Update session from DB', 'Yes','Cancel','Cancel');
        % Handle response
        if strcmp(answer,'Yes')
            MsgLog('Updating...',0)
            success = updateFromDB;
            if success
                MsgLog('Updated from db',2)
            else
                MsgLog('Database tools not available',4)
            end
        end
    end
    
    function editDBcredentials(~,~)
        edit db_credentials.m
    end

    function editDBrepositories(~,~)
        edit db_local_repositories.m
    end
    function buttonHelp(src,~)
        if strcmp(src.(menuLabel),'Tutorial on session metadata')
            web('https://cellexplorer.org/tutorials/metadata-tutorial/','-new','-browser')
        else
            web('https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata','-new','-browser')
        end
    end
    
    function performStructVerification(~,~)
        readBackFields;
        verifySessionStruct(session);
    end
    
    function edit_preferences_ProcessCellMetrics(~,~)
        edit preferences_ProcessCellMetrics
        MsgLog('Prerences are located in preferences_ProcessCellMetrics.m. If you do any changes you have to rerun ProcessCellMetrics.',2)
    end
    function buttonUploadToDB
        listing = fieldnames(session);
        [indx,~] = listdlg('PromptString','Select the data types to upload to the database','ListString',listing,'SelectionMode','multiple','ListSize',[300,220],'InitialValue',1,'Name','Upload session changes to DB');
        if ~isempty(indx)
            MsgLog('Uploading to db',0)
            readBackFields;
            try
                success = db_upload_session(session,'fields',listing(indx));
                if success
                    MsgLog('Upload complete',2)
                else
                    MsgLog('Database tools not available',4)
                end
            catch
                MsgLog('Database tools not working properly',0)
            end
            
        end
    end
    
    function success = updateFromDB
        success = 0;
        if enableDatabase 
            try
            if isfield(session.general,'entryID') && isnumeric(session.general.entryID)
                session = db_set_session('sessionId',session.general.entryID,'changeDir',false,'saveMat',true);
            else
                session = db_set_session('sessionName',session.general.name,'changeDir',false,'saveMat',true);
            end
            if ~isempty(session)
                if uiLoaded
                    importSessionStruct
                end
                success = 1;
            end
            catch 
                warning('Database tools not working');

            end
        else
            warning('Database tools not available');
        end
    end
    
    function UIsetValue(fieldNameIn,valueIn)
        if any(strcmp(valueIn,fieldNameIn.String))
            fieldNameIn.Value = find(strcmp(valueIn,fieldNameIn.String));
        else
            fieldNameIn.Value = 1;
        end
    end

    function saveSessionFile
        if ~strcmp(pwd,UI.edit.basepath.String)
            answer = questdlg('Base path is different from current path. Where would you like to save the session struct to','Location','basepath','Current path','Select location','basepath');
        else
            answer = 'basepath';
        end
        switch answer
            case 'basepath'
                filepath1 = UI.edit.basepath.String;
                filename1 = [UI.edit.session.String,'.session.mat'];
            case 'Current path'
                filepath1 = pwd;
                filename1 = [UI.edit.session.String,'.session.mat'];
            case 'Select location'
                [filename1,filepath1] = uiputfile([UI.edit.session.String,'.session.mat']);
            otherwise
                return
        end
        
        readBackFields;
        try
            save(fullfile(filepath1, filename1),'session','-v7.3','-nocompression');
            MsgLog(['Session struct saved: ' fullfile(filepath1, filename1)],2)
        catch
            MsgLog(['Failed to save ',filename1,'. Location not available'],4)
        end
        
    end

    function UIsetString(StructName,StringName,StringName2)
        if isfield(StructName,StringName) && exist('StringName2','var')
            UI.edit.(StringName).String = StructName.(StringName2);
        elseif isfield(StructName,StringName)
            UI.edit.(StringName).String = StructName.(StringName);
        end
    end
    
    function X = compareStringArray(A,B)
        if ischar(B)
            B = {B};
        end
        X = zeros(size(A));
        for k = 1:numel(B)
            X(strcmp(A,B{k})) = k;
        end
        X = find(X);
    end

    function CloseMetricsWindow
        readBackFields;
        delete(UI.fig);
        statusExit = 1;
        trackGoogleAnalytics('gui_session',1,'session',session); % Anonymous tracking of usage
    end
    
    function readBackFields
        % Saving parameters
        if exist('parameters','var') && ~isempty(parameters)
            for iParams = 1:length(UI.list.params)
                parameters.(UI.list.params{iParams}) = logical(UI.checkbox.params(iParams).Value);
            end
            if ~isempty(UI.listbox.includeMetrics.Value)
                parameters.metrics = UI.listbox.includeMetrics.String(UI.listbox.includeMetrics.Value);
            end
            if ~isempty(UI.listbox.excludeMetrics.Value)
                parameters.excludeMetrics = UI.listbox.excludeMetrics.String(UI.listbox.excludeMetrics.Value);
            end
            if ~isempty(UI.listbox.metricsToExcludeManipulationIntervals.Value)
                parameters.metricsToExcludeManipulationIntervals = UI.listbox.metricsToExcludeManipulationIntervals.String(UI.listbox.metricsToExcludeManipulationIntervals.Value);
            end
            try
                parameters.preferences.putativeCellType.classification_schema = UI.edit.classification_schema.String{UI.edit.classification_schema.Value};
            end
        end
        session.general.date = UI.edit.date.String;
        session.general.time = UI.edit.time.String;
        session.general.name = UI.edit.session.String;
        session.general.basePath = UI.edit.basepath.String;
        session.general.duration = UI.edit.duration.String;
        session.general.location = UI.edit.location.String;
        session.general.experimenters = UI.edit.experimenters.String;
        session.general.notes = UI.edit.notes.String;
        session.general.sessionType = UI.list.sessionTypes{UI.edit.sessionType.Value};
        if ~isfield(session.general,'entryID') || isempty(session.general.entryID)
            session.general.investigator = UI.edit.investigator.String;
            session.general.repositories = UI.edit.repositories.String;
            session.general.projects = UI.edit.projects.String;
        end
        session.animal.name = UI.edit.name.String;
        session.animal.sex = UI.edit.sex.String{UI.edit.sex.Value};
        session.animal.species = UI.edit.species.String{UI.edit.species.Value};
        session.animal.strain = UI.edit.strain.String{UI.edit.strain.Value};
        session.animal.geneticLine = UI.edit.geneticLine.String;
        
        % Extracellular
        if ~strcmp(UI.edit.leastSignificantBit.String,'')
            session.extracellular.leastSignificantBit = str2double(UI.edit.leastSignificantBit.String);
        end
        if ~strcmp(UI.edit.sr.String,'')
            session.extracellular.sr = str2double(UI.edit.sr.String);
        end
        if ~strcmp(UI.edit.srLfp.String,'')
            session.extracellular.srLfp = str2double(UI.edit.srLfp.String);
        end
        if ~strcmp(UI.edit.nSamples.String,'')
            session.extracellular.nSamples = str2double(UI.edit.nSamples.String);
        end
        if ~strcmp(UI.edit.nChannels.String,'')
            session.extracellular.nChannels = str2double(UI.edit.nChannels.String);
        end
        session.extracellular.nElectrodeGroups = numel(session.extracellular.electrodeGroups.channels);
        session.extracellular.nSpikeGroups = numel(session.extracellular.spikeGroups.channels);
        
        session.extracellular.fileName = UI.edit.fileName.String;
        session.extracellular.precision = UI.edit.precision.String;
        session.extracellular.equipment = UI.edit.equipment.String;
    end
    
    function cancelMetricsWindow
        session = sessionIn;
        delete(UI.fig)
        trackGoogleAnalytics('gui_session',1); % Anonymous tracking of usage
    end

    function updateBrainRegionList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'brainRegions') && ~isempty(session.brainRegions)
            brainRegionFieldnames = fieldnames(session.brainRegions);
            for fn = 1:length(brainRegionFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = brainRegionFieldnames{fn};
                if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'channels')
                    tableData{fn,3} = num2str(session.brainRegions.(brainRegionFieldnames{fn}).channels);
                else
                    tableData{fn,3} = '';
                end
                if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'electrodeGroups')
                    tableData{fn,4} = num2str(session.brainRegions.(brainRegionFieldnames{fn}).electrodeGroups);
                else
                    tableData{fn,4} = '';
                end
                if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'notes')
                    tableData{fn,5} = session.brainRegions.(brainRegionFieldnames{fn}).notes;
                else
                    tableData{fn,5} = '';
                end
            end
            UI.table.brainRegion.Data = tableData;
        else
            UI.table.brainRegion.Data = {};
        end
    end

    function updateTagList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'channelTags') && ~isempty(session.channelTags)
            tagFieldnames = fieldnames(session.channelTags);
            for fn = 1:length(tagFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = tagFieldnames{fn};
                if isfield(session.channelTags.(tagFieldnames{fn}),'channels')
                    tableData{fn,3} = num2str(session.channelTags.(tagFieldnames{fn}).channels(:)');
                else
                    tableData{fn,3} = '';
                end
                if isfield(session.channelTags.(tagFieldnames{fn}),'electrodeGroups')
                    tableData{fn,4} = num2str(session.channelTags.(tagFieldnames{fn}).electrodeGroups(:)');
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.tags.Data = tableData;
        else
            UI.table.tags.Data = {};
        end
    end

    function updateChannelGroupsList(group)
        % Updates the list of electrode/spike groups
        tableData = {};
        if isfield(session.extracellular,group)
            if isfield(session.extracellular,group) && isfield(session.extracellular.(group),'channels') && isnumeric(session.extracellular.(group).channels)
                session.extracellular.(group).channels = num2cell(session.extracellular.(group).channels,2)';
            end
            
           if ~isempty(session.extracellular.(group).channels) && ~isempty(session.extracellular.(group).channels{1})
                nTotal = numel(session.extracellular.(group).channels);
            else
                nTotal = 0;
            end
            for fn = 1:nTotal
                tableData{fn,1} = false;
                tableData{fn,2} = [num2str(fn),' (',num2str(length(session.extracellular.(group).channels{fn})),')'];
                tableData{fn,3} = num2str(session.extracellular.(group).channels{fn});
                if isfield(session.extracellular.(group),'label') && size(session.extracellular.(group).label,2)>=fn
                    tableData{fn,4} = session.extracellular.(group).label{fn};
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.(group).Data = tableData;
        else
            UI.table.(group).Data = {false,'','',''};
        end
    end
    
    function updatePreferencesTable
        k = 1;
        tableData = {};
        fields_preferences = fieldnames(parameters.preferences);
        for i = 1:numel(fields_preferences)
            fields_preferences2 = fieldnames(parameters.preferences.(fields_preferences{i}));
            for j = 1:numel(fields_preferences2)
%                 tableData{k,1} = false;
                tableData{k,1} = fields_preferences{i};
                tableData{k,2} = fields_preferences2{j};
                fieldvalue = parameters.preferences.(fields_preferences{i}).(fields_preferences2{j});
                if isnumeric(fieldvalue)
                    tableData{k,3} = num2str(fieldvalue);
                elseif iscell(fieldvalue)
                    tableData{k,3} = fieldvalue{:};
                else
                    tableData{k,3} = fieldvalue;
                end
                k = k + 1;
            end
        end
        try
            UI.table.preferences.Data = tableData;
        end
    end
    
    function updateEpochsList
        % Updates the plot table from the spikesPlots structure
        if isfield(session,'epochs') && ~isempty(session.epochs)
            nEntries = length(session.epochs);
            tableData = cell(nEntries,10);
            tableData(:,1) = {false};
            for fn = 1:nEntries
                tableData{fn,2} = fn;
                tableData{fn,3} = session.epochs{fn}.name;
                if isfield(session.epochs{fn},'startTime') && ~isempty(session.epochs{fn}.startTime)
                    tableData{fn,4} = session.epochs{fn}.startTime;
                end
                if isfield(session.epochs{fn},'stopTime') && ~isempty(session.epochs{fn}.stopTime)
                    tableData{fn,5} = session.epochs{fn}.stopTime;
                end
                if isfield(session.epochs{fn},'behavioralParadigm') && ~isempty(session.epochs{fn}.behavioralParadigm)
                    tableData{fn,6} = session.epochs{fn}.behavioralParadigm;
                end
                if isfield(session.epochs{fn},'environment') && ~isempty(session.epochs{fn}.environment)
                    tableData{fn,7} = session.epochs{fn}.environment;
                end
                if isfield(session.epochs{fn},'manipulation') && ~isempty(session.epochs{fn}.manipulation)
                    tableData{fn,8} = session.epochs{fn}.manipulation;
                end
                if isfield(session.epochs{fn},'stimuli') && ~isempty(session.epochs{fn}.stimuli)
                    tableData{fn,9} = session.epochs{fn}.stimuli;
                end

                if isfield(session.epochs{fn},'notes') && ~isempty(session.epochs{fn}.notes)
                    tableData{fn,10} = session.epochs{fn}.notes;
                end
            end
            UI.table.epochs.Data = tableData;
        else
            UI.table.epochs.Data = {};
        end
    end
    
    function updateInputsList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'inputs') && ~isempty(session.inputs)
            tagFieldnames = fieldnames(session.inputs);
            for fn = 1:length(tagFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = tagFieldnames{fn};
                if isfield(session.inputs.(tagFieldnames{fn}),'channels')
                    tableData{fn,3} = num2str(session.inputs.(tagFieldnames{fn}).channels);
                else
                    tableData{fn,3} = '';
                end
                if isfield(session.inputs.(tagFieldnames{fn}),'inputType')
                    tableData{fn,4} = session.inputs.(tagFieldnames{fn}).inputType;
                else
                    tableData{fn,4} = '';
                end
                if isfield(session.inputs.(tagFieldnames{fn}),'equipment')
                    tableData{fn,5} = session.inputs.(tagFieldnames{fn}).equipment;
                else
                    tableData{fn,5} = '';
                end
                if isfield(session.inputs.(tagFieldnames{fn}),'description')
                    tableData{fn,6} = session.inputs.(tagFieldnames{fn}).description;
                else
                    tableData{fn,6} = '';
                end
            end
            UI.table.inputs.Data = tableData;
        else
            UI.table.inputs.Data = {};
        end
    end
    
    function updateBehaviorsList
        % Updates the plot table from the spikesPlots structure
        if isfield(session,'behavioralTracking') && ~isempty(session.behavioralTracking)
            nEntries = length(session.behavioralTracking);
            tableData = cell(nEntries,7);
            tableData(:,1) = {false};
            for fn = 1:nEntries
                tableData{fn,2} = session.behavioralTracking{fn}.filenames;
                if isfield(session.behavioralTracking{fn},'equipment') && ~isempty(session.behavioralTracking{fn}.equipment)
                    tableData{fn,3} = session.behavioralTracking{fn}.equipment;
                end
                if isfield(session.behavioralTracking{fn},'epoch') && ~isempty(session.behavioralTracking{fn}.epoch)
                    tableData{fn,4} = session.behavioralTracking{fn}.epoch;
                end
                if isfield(session.behavioralTracking{fn},'type') && ~isempty(session.behavioralTracking{fn}.type)
                    tableData{fn,5} = session.behavioralTracking{fn}.type;
                end
                if isfield(session.behavioralTracking{fn},'framerate') && ~isempty(session.behavioralTracking{fn}.framerate)
                    tableData{fn,6} = session.behavioralTracking{fn}.framerate;
                end
                if isfield(session.behavioralTracking{fn},'notes') && ~isempty(session.behavioralTracking{fn}.notes)
                    tableData{fn,7} = session.behavioralTracking{fn}.notes;
                end
            end
            UI.table.behaviors.Data = tableData;
        else
            UI.table.behaviors.Data = {};
        end
    end
    
    function updateSpikeSortingList
        % Updates the plot table from the spikesPlots structure
        % '','Method','Format','relative path','channels','spike sorter','Notes','cell metrics','Manual currated'
        if isfield(session,'spikeSorting') && ~isempty(session.spikeSorting)
            nEntries = length(session.spikeSorting);
            tableData = cell(nEntries,9);
            tableData(:,1) = {false};
            for fn = 1:nEntries
                tableData{fn,2} = session.spikeSorting{fn}.method;
                if isfield(session.spikeSorting{fn},'format') && ~isempty(session.spikeSorting{fn}.format)
                    tableData{fn,3} = session.spikeSorting{fn}.format;
                end
                if isfield(session.spikeSorting{fn},'relativePath') && ~isempty(session.spikeSorting{fn}.relativePath)
                    tableData{fn,4} = session.spikeSorting{fn}.relativePath;
                end
                if isfield(session.spikeSorting{fn},'channels') && ~isempty(session.spikeSorting{fn}.channels)
                    tableData{fn,5} = num2str(session.spikeSorting{fn}.channels);
                end
                if isfield(session.spikeSorting{fn},'spikeSorter') && ~isempty(session.spikeSorting{fn}.spikeSorter)
                    tableData{fn,6} = session.spikeSorting{fn}.spikeSorter;
                end
                if isfield(session.spikeSorting{fn},'notes') && ~isempty(session.spikeSorting{fn}.notes)
                    tableData{fn,7} = session.spikeSorting{fn}.notes;
                end
                if isfield(session.spikeSorting{fn},'cellMetrics') && ~isempty(session.spikeSorting{fn}.cellMetrics)
                    if session.spikeSorting{fn}.cellMetrics==1
                        tableData{fn,8} = true;
                    else
                        tableData{fn,8} = false;
                    end
                end
                if isfield(session.spikeSorting{fn},'manuallyCurated') && ~isempty(session.spikeSorting{fn}.manuallyCurated)
                    if session.spikeSorting{fn}.manuallyCurated==1
                        tableData{fn,9} = true;
                    else
                        tableData{fn,9} = false;
                    end
                end
            end
            UI.table.spikeSorting.Data = tableData;
        else
            UI.table.spikeSorting.Data = {};
        end
    end

    function updateAnalysisList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'analysisTags') && ~isempty(session.analysisTags)
            tagFieldnames = fieldnames(session.analysisTags);
            for fn = 1:length(tagFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = tagFieldnames{fn};
                if ~isempty(session.analysisTags.(tagFieldnames{fn}))
                    tableData{fn,3} = num2str(session.analysisTags.(tagFieldnames{fn}));
                else
                    tableData{fn,3} = '';
                end
            end
            UI.table.analysis.Data = tableData;
        else
            UI.table.analysis.Data = {};
        end 
    end
    
    function updateTimeSeriesList
        if isfield(session,'timeSeries') && ~isempty(session.timeSeries) && isstruct(session.timeSeries)
            Fieldnames = fieldnames(session.timeSeries);
            nEntries = length(Fieldnames);
            tableData = cell(nEntries,9);
            tableData(:,1) = {false};
            for fn = 1:nEntries
                tableData{fn,2} = Fieldnames{fn};
                tableData{fn,3} = session.timeSeries.(Fieldnames{fn}).fileName;
                if isfield(session.timeSeries.(Fieldnames{fn}),'precision') && ~isempty(session.timeSeries.(Fieldnames{fn}).precision)
                    tableData{fn,4} = session.timeSeries.(Fieldnames{fn}).precision;
                end
                if isfield(session.timeSeries.(Fieldnames{fn}),'nChannels') && ~isempty(session.timeSeries.(Fieldnames{fn}).nChannels)
                    tableData{fn,5} = session.timeSeries.(Fieldnames{fn}).nChannels;
                end
                if isfield(session.timeSeries.(Fieldnames{fn}),'sr') && ~isempty(session.timeSeries.(Fieldnames{fn}).sr)
                    tableData{fn,6} = session.timeSeries.(Fieldnames{fn}).sr;
                end
                if isfield(session.timeSeries.(Fieldnames{fn}),'nSamples') && ~isempty(session.timeSeries.(Fieldnames{fn}).nSamples)
                    tableData{fn,7} = session.timeSeries.(Fieldnames{fn}).nSamples;
                end
                if isfield(session.timeSeries.(Fieldnames{fn}),'leastSignificantBit') && ~isempty(session.timeSeries.(Fieldnames{fn}).leastSignificantBit)
                    tableData{fn,8} = session.timeSeries.(Fieldnames{fn}).leastSignificantBit;
                end
                if isfield(session.timeSeries.(Fieldnames{fn}),'equipment') && ~isempty(session.timeSeries.(Fieldnames{fn}).equipment)
                    tableData{fn,9} = session.timeSeries.(Fieldnames{fn}).equipment;
                end
            end
            UI.table.timeSeries.Data = tableData;
        else
            UI.table.timeSeries.Data = {};
        end
    end

%% % Brain regions

    function deleteRegion
        % Deletes any selected spike plots
        if ~isempty(UI.table.brainRegion.Data) && ~isempty(find([UI.table.brainRegion.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.brainRegions);
            session.brainRegions = rmfield(session.brainRegions,{spikesPlotFieldnames{find([UI.table.brainRegion.Data{:,1}])}});
            updateBrainRegionList
        else
            helpdlg('Please select the region(s) to delete','Error')
        end
    end

    function addRegion(regionIn)
        % Add new brain region to session struct
        brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
        brainRegions_list = strcat(brainRegions(:,1),' (',brainRegions(:,2),')');
        brainRegions_acronym = brainRegions(:,2);
        if exist('regionIn','var')
            InitBrainRegion = find(strcmp(regionIn,brainRegions_acronym));
            if isfield(session.brainRegions.(regionIn),'channels')
                initChannels = num2str(session.brainRegions.(regionIn).channels);
            else
                initChannels = '';
            end
            if isfield(session.brainRegions.(regionIn),'electrodeGroups')
                initElectrodeGroups = num2str(session.brainRegions.(regionIn).electrodeGroups);
            else
                initElectrodeGroups = '';
            end
        else
            InitBrainRegion = 1;
            initChannels = '';
            initElectrodeGroups = '';
        end
        % Opens dialog
        UI.dialog.brainRegion = dialog('Position', [300, 300, 600, 400],'Name','Brain region','WindowStyle','modal'); movegui(UI.dialog.brainRegion,'center')
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Search term', 'Position', [10, 373, 600, 20],'HorizontalAlignment','left');
        brainRegionsTextfield = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', '', 'Position', [10, 330, 600, 25],'Callback',@(src,evnt)filterBrainRegionsList,'HorizontalAlignment','left');
        if exist('regionIn','var')
            brainRegionsTextfield.Enable = 'off';
        end
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Selct brain region below', 'Position', [10, 320, 600, 20],'HorizontalAlignment','left');
        brainRegionsList = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'ListBox', 'String', brainRegions_list, 'Position', [10, 100, 600, 220],'Value',InitBrainRegion);
        if exist('regionIn','var')
            brainRegionsList.Enable = 'off';
        end
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', ['Channels (nChannels = ',num2str(session.extracellular.nChannels),')'], 'Position', [10, 73, 280, 20],'HorizontalAlignment','left');
        brainRegionsChannels = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', initChannels, 'Position', [10, 50, 280, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', ['Spike group (nElectrodeGroups = ',num2str(session.extracellular.nElectrodeGroups),')'], 'Position', [300, 73, 310, 20],'HorizontalAlignment','left');
        brainRegionsElectrodeGroups = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', initElectrodeGroups, 'Position', [300, 50, 310, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Save region','Callback',@(src,evnt)CloseBrainRegions_dialog);
        uicontrol('Parent',UI.dialog.brainRegion,'Style','pushbutton','Position',[300, 10, 310, 30],'String','Cancel','Callback',@(src,evnt)CancelBrainRegions_dialog);
        
        uicontrol(brainRegionsTextfield);
        uiwait(UI.dialog.brainRegion);
        
        function filterBrainRegionsList
            temp = contains(brainRegions_list,brainRegionsTextfield.String,'IgnoreCase',true);
            if ~any(temp == brainRegionsList.Value)
                brainRegionsList.Value = 1;
            end
            if ~isempty(temp)
                brainRegionsList.String = brainRegions_list(temp);
            else
                brainRegionsList.String = {''};
            end
        end
        function CloseBrainRegions_dialog
            if length(brainRegionsList.String)>=brainRegionsList.Value
                choice = brainRegionsList.String(brainRegionsList.Value);
                if ~strcmp(choice,'')
                    indx = find(strcmp(choice,brainRegions_list));
                    SelectedBrainRegion = brainRegions_acronym{indx};
                    if ~isempty(brainRegionsChannels.String)
                        try
                            session.brainRegions.(SelectedBrainRegion).channels = eval(['[',brainRegionsChannels.String,']']);
                        catch
                            helpdlg('Channels not formatted correctly','Error')
                            uicontrol(brainRegionsChannels);
                        end
                    end
                    if ~isempty(brainRegionsElectrodeGroups.String)
                        try
                            session.brainRegions.(SelectedBrainRegion).electrodeGroups = eval(['[',brainRegionsElectrodeGroups.String,']']);
                        catch
                            helpdlg('Spike groups not formatted correctly','Error')
                            uicontrol(brainRegionsElectrodeGroups);
                        end
                    end
                end
            end
            delete(UI.dialog.brainRegion);
            updateBrainRegionList;
        end
        function CancelBrainRegions_dialog
            session = sessionIn;
            delete(UI.dialog.brainRegion);
        end
    end

    function editRegion 
        % Selected region is parsed to the spikePlotsDlg, for edits, saved the output to the spikesPlots structure and updates the table
        if ~isempty(UI.table.brainRegion.Data) && ~isempty(find([UI.table.brainRegion.Data{:,1}])) && sum([UI.table.brainRegion.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.brainRegions);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.brainRegion.Data{:,1}])};
            addRegion(fieldtoedit)
        else
            helpdlg('Please select the region to edit','Error')
        end
    end

%% % Channel tags

    function deleteTag
        % Deletes any selected tags
        if ~isempty(UI.table.tags.Data) && ~isempty(find([UI.table.tags.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.channelTags);
            if ~isempty({spikesPlotFieldnames{find([UI.table.tags.Data{:,1}])}})
                session.channelTags = rmfield(session.channelTags,{spikesPlotFieldnames{find([UI.table.tags.Data{:,1}])}});
            end
            updateTagList
        else
            helpdlg('Please select the channel tag(s) to delete','Error')
        end
    end

    function addTag(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            InitTag = regionIn;
            if isfield(session.channelTags.(regionIn),'channels')
                initChannels = num2str(session.channelTags.(regionIn).channels(:)');
            else
                initChannels = '';
            end
            if isfield(session.channelTags.(regionIn),'electrodeGroups')
                initElectrodeGroups = num2str(session.channelTags.(regionIn).electrodeGroups(:)');
            else
                initElectrodeGroups = '';
            end
        else
            InitTag = '';
            initChannels = '';
            initElectrodeGroups = '';
        end
        
        % Opens dialog
        UI.dialog.tags = dialog('Position', [300, 300, 500, 150],'Name','Channel tag','WindowStyle','modal'); movegui(UI.dialog.tags,'center')
        
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', 'Channel tag name (e.g. Theta, Gamma, Bad, Cortical, Ripple, RippleNoise)', 'Position', [10, 123, 480, 20],'HorizontalAlignment','left');
        tagsTextfield = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', InitTag, 'Position', [10, 100, 480, 25],'HorizontalAlignment','left');
        if exist('regionIn','var')
            tagsTextfield.Enable = 'off';
        end
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', ['Channels (nChannels = ',num2str(session.extracellular.nChannels),')'], 'Position', [10, 73, 230, 20],'HorizontalAlignment','left');
        tagsChannels = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', initChannels, 'Position', [10, 50, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', ['Spike group (nElectrodeGroups = ',num2str(session.extracellular.nElectrodeGroups),')'], 'Position', [250, 73, 240, 20],'HorizontalAlignment','left');
        tagsElectrodeGroups = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', initElectrodeGroups, 'Position', [250, 50, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.tags,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save tag','Callback',@(src,evnt)CloseTags_dialog);
        uicontrol('Parent',UI.dialog.tags,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelTags_dialog);
        
        uicontrol(tagsTextfield);
        uiwait(UI.dialog.tags);
        
        function CloseTags_dialog
            if ~strcmp(tagsTextfield.String,'') && isvarname(tagsTextfield.String)
                SelectedTag = tagsTextfield.String;
                if ~isempty(tagsChannels.String)
                    try
                        session.channelTags.(SelectedTag).channels = eval(['[',tagsChannels.String,']']);
                    catch
                       helpdlg('Channels not formatted correctly','Error')
                        uicontrol(tagsChannels);
                        return
                    end
                else
                    session.channelTags.(SelectedTag).channels = [];
                end
                if ~isempty(tagsElectrodeGroups.String)
                    try
                        session.channelTags.(SelectedTag).electrodeGroups = eval(['[',tagsElectrodeGroups.String,']']);
                    catch
                        helpdlg('Spike groups not formatted correctly','Error')
                        uicontrol(tagsElectrodeGroups);
                        return
                    end
                else
                    session.channelTags.(SelectedTag).electrodeGroups = [];
                end
            end
            delete(UI.dialog.tags);
            updateTagList;
        end
        
        function CancelTags_dialog
            delete(UI.dialog.tags);
        end
    end

    function editTag
        % Selected tag is parsed to the addTag dialog for edits,
        if ~isempty(UI.table.tags.Data) && ~isempty(find([UI.table.tags.Data{:,1}], 1)) && sum([UI.table.tags.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.channelTags);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.tags.Data{:,1}])};
            addTag(fieldtoedit)
        else
            helpdlg('Please select the channel tag to edit','Error')
        end
    end


%% % Inputs

    function deleteInput
        % Deletes any selected Inputs
        if ~isempty(UI.table.inputs.Data) && ~isempty(find([UI.table.inputs.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.inputs);
            session.inputs = rmfield(session.inputs,{spikesPlotFieldnames{find([UI.table.inputs.Data{:,1}])}});
            updateInputsList
        else
            helpdlg('Please select the input(s) to delete','Error')
        end
    end

    function addInput(regionIn)
        % Add new input to session struct
        if exist('regionIn','var')
            InitInput = regionIn;
            if isfield(session.inputs.(regionIn),'channels')
                initChannels = num2str(session.inputs.(regionIn).channels);
            else
                initChannels = '';
            end
            if isfield(session.inputs.(regionIn),'equipment')
                InitEquipment = session.inputs.(regionIn).equipment;
            else
                InitEquipment = '';
            end
            if isfield(session.inputs.(regionIn),'inputType')
                initInputType = session.inputs.(regionIn).inputType;
            else
                initInputType = '';
            end
            if isfield(session.inputs.(regionIn),'description')
                initDescription = session.inputs.(regionIn).description;
            else
                initDescription = '';
            end
        else
            InitInput = '';
            InitEquipment = '';
            initInputType = '';
            initChannels = '';
            initDescription = '';
        end
        
        % Opens dialog
        UI.dialog.inputs = dialog('Position', [300, 300, 500, 200],'Name','Input','WindowStyle','modal'); movegui(UI.dialog.inputs,'center')
        
        uicontrol('Parent',UI.dialog.inputs,'Style', 'text', 'String', 'input name', 'Position', [10, 173, 230, 20],'HorizontalAlignment','left');
        inputsTextfield = uicontrol('Parent',UI.dialog.inputs,'Style', 'Edit', 'String', InitInput, 'Position', [10, 150, 230, 25],'HorizontalAlignment','left');
        if exist('regionIn','var')
            inputsTextfield.Enable = 'off';
        end
        uicontrol('Parent',UI.dialog.inputs,'Style', 'text', 'String', 'Equipment', 'Position', [250, 173, 240, 20],'HorizontalAlignment','left');
        inputsEquipment = uicontrol('Parent',UI.dialog.inputs,'Style', 'Edit', 'String', InitEquipment, 'Position', [250, 150, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.inputs,'Style', 'text', 'String', 'Channels', 'Position', [10, 123, 230, 20],'HorizontalAlignment','left');
        inputsChannels = uicontrol('Parent',UI.dialog.inputs,'Style', 'Edit', 'String', initChannels, 'Position', [10, 100, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.inputs,'Style', 'text', 'String', 'Input type', 'Position', [250, 123, 240, 20],'HorizontalAlignment','left');
        inputsType = uicontrol('Parent',UI.dialog.inputs,'Style', 'popup', 'String', UI.list.inputsType , 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
        UIsetValue(inputsType,initInputType)
        
        uicontrol('Parent',UI.dialog.inputs,'Style', 'text', 'String', 'Description', 'Position', [10, 73, 230, 20],'HorizontalAlignment','left');
        inputsDescription = uicontrol('Parent',UI.dialog.inputs,'Style', 'Edit', 'String', initDescription, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.inputs,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save input','Callback',@(src,evnt)CloseInputs_dialog);
        uicontrol('Parent',UI.dialog.inputs,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelInputs_dialog);
        
        uicontrol(inputsTextfield);
        uiwait(UI.dialog.inputs);
        
        function CloseInputs_dialog
            if ~strcmp(inputsTextfield.String,'') && isvarname(inputsTextfield.String)
                Selectedinput = inputsTextfield.String;
                if ~isempty(inputsChannels.String)
                    try
                        session.inputs.(Selectedinput).channels = eval(['[',inputsChannels.String,']']);
                    catch
                        helpdlg('Channels not formatted correctly','Error')
                        uicontrol(inputsChannels);
                        return
                    end
                end
                if ~isempty(inputsEquipment.String)
                    session.inputs.(Selectedinput).equipment = inputsEquipment.String;
                end
                if ~isempty(inputsType.String)
                    session.inputs.(Selectedinput).inputType = inputsType.String{inputsType.Value};
                end
                if ~isempty(inputsDescription.String)
                    session.inputs.(Selectedinput).description = inputsDescription.String;
                end
            end
            delete(UI.dialog.inputs);
            updateInputsList;
        end
        
        function CancelInputs_dialog
            delete(UI.dialog.inputs);
        end
    end

    function editInput
        % Selected input is parsed to the addInput dialog for edits,
        if ~isempty(UI.table.inputs.Data) && ~isempty(find([UI.table.inputs.Data{:,1}], 1)) && sum([UI.table.inputs.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.inputs);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.inputs.Data{:,1}])};
            addInput(fieldtoedit)
        else
            helpdlg('Please select the input to edit','Error')
        end
    end

%% % Epochs
    
    function moveDownEpoch
        if ~isempty(UI.table.epochs.Data) && ~isempty(find([UI.table.epochs.Data{:,1}], 1))
            cell2move = [UI.table.epochs.Data{:,1}];
            offset = cumsumWithReset2(cell2move);
            newOrder = 1:length(session.epochs);
            newOrder1 = newOrder+offset;
            [~,newOrder] = sort(newOrder1);
            session.epochs = session.epochs(newOrder);
            updateEpochsList
            UI.table.epochs.Data(find(ismember(newOrder,find(cell2move))),1) = {true};
        else
            helpdlg('Please select the epoch(s) to move','Error')
        end
    end
    
    function moveUpEpoch
        if ~isempty(UI.table.epochs.Data) && ~isempty(find([UI.table.epochs.Data{:,1}], 1))
            cell2move = [UI.table.epochs.Data{:,1}];
            offset = cumsumWithReset(cell2move);
            newOrder = 1:length(session.epochs);
            newOrder1 = newOrder-offset;
            [~,newOrder] = sort(newOrder1);
            session.epochs = session.epochs(newOrder);
            updateEpochsList
            UI.table.epochs.Data(find(ismember(newOrder,find(cell2move))),1) = {true};
        else
            helpdlg('Please select the epoch(s) to move','Error')
        end
    end
    
    function H = cumsumWithReset(G)
        H = zeros(size(G));
        count = 0;
        for idx = 1:numel(G)
            if G(idx)
                count = count + 1;
            else
                count = 0;
            end
            if count > 0
                H(idx) = count+0.01;
            end
        end
    end
    function H = cumsumWithReset2(G)
        H = zeros(size(G));
        count = 0;
        for idx = numel(G):-1:1
            if G(idx)
                count = count + 1;
            else
                count = 0;
            end
            if count > 0
                H(idx) = count+0.01;
            end
        end
        
    end
    function deleteEpoch
        % Deletes any selected Epochs
        if ~isempty(UI.table.epochs.Data) && ~isempty(find([UI.table.epochs.Data{:,1}], 1))
            session.epochs(find([UI.table.epochs.Data{:,1}])) = [];
            updateEpochsList
        else
            helpdlg('Please select the epoch(s) to delete','Error')
        end
    end

    function addEpoch(epochIn)
        % Add new epoch to session struct
        if exist('epochIn','var')
            % name
            if isfield(session.epochs{epochIn},'name')
                InitName = session.epochs{epochIn}.name;
            else
                InitName = '';
            end
            % behavioralParadigm
            if isfield(session.epochs{epochIn},'behavioralParadigm')
                initParadigm = session.epochs{epochIn}.behavioralParadigm;
            else
                initParadigm = '';
            end
            % environment
            if isfield(session.epochs{epochIn},'environment')
                initEnvironment = session.epochs{epochIn}.environment;
            else
                initEnvironment = '';
            end
            % manipulation
            if isfield(session.epochs{epochIn},'manipulation')
                initManipulation = session.epochs{epochIn}.manipulation;
            else
                initManipulation = '';
            end
            % start time
            if isfield(session.epochs{epochIn},'startTime')
                initStartTime = num2str(session.epochs{epochIn}.startTime);
            else
                initStartTime = '';
            end
            % stop time
            if isfield(session.epochs{epochIn},'stopTime')
                initStopTime = num2str(session.epochs{epochIn}.stopTime);
            else
                initStopTime = '';
            end
            % notes
            if isfield(session.epochs{epochIn},'notes')
                initNotes = session.epochs{epochIn}.notes;
            else
                initNotes = '';
            end
        else
            InitName = '';
            initParadigm = '';
            initEnvironment = '';
            initManipulation = '';
            initStartTime = '';
            initStopTime = '';
            initNotes = '';
            if isfield(session,'epochs')
                epochIn = length(session.epochs)+1;
            else
                epochIn = 1;
            end
        end
        
        % Opens dialog
        UI.dialog.epochs = dialog('Position', [300, 300, 500, 250],'Name','Epoch','WindowStyle','modal'); movegui(UI.dialog.epochs,'center')
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Name', 'Position', [10, 223, 230, 20],'HorizontalAlignment','left');
        epochsName = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', InitName, 'Position', [10, 200, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Paradigm', 'Position', [250, 223, 240, 20],'HorizontalAlignment','left');
        epochsParadigm = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initParadigm, 'Position', [250, 200, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Environment', 'Position', [10, 173, 230, 20],'HorizontalAlignment','left');
        epochsEnvironment = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initEnvironment, 'Position', [10, 150, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Manipulation', 'Position', [250, 173, 240, 20],'HorizontalAlignment','left');
        epochsManipulation = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initManipulation, 'Position', [250, 150, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Start time (sec)', 'Position', [10, 123, 230, 20],'HorizontalAlignment','left');
        epochsStartTime = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initStartTime, 'Position', [10, 100, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Stop time (sec)', 'Position', [250, 123, 240, 20],'HorizontalAlignment','left');
        epochsStopTime = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initStopTime, 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Notes', 'Position', [10, 73, 440, 20],'HorizontalAlignment','left');
        epochsNotes = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initNotes, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save epoch','Callback',@(src,evnt)CloseEpochs_dialog);
        uicontrol('Parent',UI.dialog.epochs,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelEpochs_dialog);
        
        uicontrol(epochsName);
        uiwait(UI.dialog.epochs);
        
        function CloseEpochs_dialog
            if ~strcmp(epochsName.String,'') && isvarname(epochsName.String)
                SelectedEpoch = epochIn;
                if ~isempty(epochsName.String)
                    session.epochs{SelectedEpoch}.name = epochsName.String;
                end
                if ~isempty(epochsParadigm.String)
                    session.epochs{SelectedEpoch}.behavioralParadigm = epochsParadigm.String;
                end                
                if ~isempty(epochsEnvironment.String)
                    session.epochs{SelectedEpoch}.environment = epochsEnvironment.String;
                end
                if ~isempty(epochsManipulation.String)
                    session.epochs{SelectedEpoch}.manipulation = epochsManipulation.String;
                end
                if ~isempty(epochsStartTime.String)
                    session.epochs{SelectedEpoch}.startTime = str2double(epochsStartTime.String);
                end
                if ~isempty(epochsStopTime.String)
                    session.epochs{SelectedEpoch}.stopTime = str2double(epochsStopTime.String);
                end
                if ~isempty(epochsNotes.String)
                    session.epochs{SelectedEpoch}.notes = epochsNotes.String;
                end
            end
            delete(UI.dialog.epochs);
            updateEpochsList;
        end
        
        function CancelEpochs_dialog
            delete(UI.dialog.epochs);
        end
    end

    function editEpoch
        % Selected epoch is parsed to the addEpoch dialog for edits,
        if ~isempty(UI.table.epochs.Data) && ~isempty(find([UI.table.epochs.Data{:,1}], 1)) && sum([UI.table.epochs.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.epochs.Data{:,1}]);
            addEpoch(fieldtoedit)
        else
            helpdlg('Please select the epoch to edit','Error')
        end
    end

    function duplicateEpoch
        % Selected epoch is parsed to the addEpoch dialog for edits,
        if ~isempty(UI.table.epochs.Data) && ~isempty(find([UI.table.epochs.Data{:,1}], 1)) && sum([UI.table.epochs.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.epochs.Data{:,1}]);
            session.epochs{end+1} = session.epochs{fieldtoedit};
            session.epochs{end}.name = [session.epochs{fieldtoedit}.name,'_duplicated'];
            updateEpochsList
            addEpoch(length(session.epochs));
        else
            helpdlg('Please select the epoch to duplicate','Error')
        end
    end

%% % Behavior

    function deleteBehavior
        % Deletes any selected Behaviors
        if ~isempty(UI.table.behaviors.Data) && ~isempty(find([UI.table.behaviors.Data{:,1}], 1))
            session.behavioralTracking(find([UI.table.behaviors.Data{:,1}])) = [];
            updateBehaviorsList
        else
            helpdlg('Please select the behavior(s) to delete','Error')
        end
    end

    function addBehavior(behaviorIn)
        % Add new behavior to session struct
        if exist('behaviorIn','var')
            % filenames
            if isfield(session.behavioralTracking{behaviorIn},'filenames')
                InitFilenames = session.behavioralTracking{behaviorIn}.filenames;
            else
                InitFilenames = '';
            end
            % equipment
            if isfield(session.behavioralTracking{behaviorIn},'equipment')
                initEquipment = session.behavioralTracking{behaviorIn}.equipment;
            else
                initEquipment = '';
            end
            % epoch
            if isfield(session.behavioralTracking{behaviorIn},'epoch')
                initEpoch = session.behavioralTracking{behaviorIn}.epoch;
            else
                initEpoch = 1;
            end
            % type
            if isfield(session.behavioralTracking{behaviorIn},'type')
                initType = session.behavioralTracking{behaviorIn}.type;
            else
                initType = '';
            end
            % framerate
            if isfield(session.behavioralTracking{behaviorIn},'framerate')
                initFramerate = num2str(session.behavioralTracking{behaviorIn}.framerate);
            else
                initFramerate = '';
            end
            % notes
            if isfield(session.behavioralTracking{behaviorIn},'notes')
                initNotes = session.behavioralTracking{behaviorIn}.notes;
            else
                initNotes = '';
            end
        else
            InitFilenames = '';
            initEquipment = '';
            initEpoch = 1;
            initType = '';
            initFramerate = '';
            initNotes = '';
            if isfield(session,'behavioralTracking')
                behaviorIn = length(session.behavioralTracking)+1;
            else
                behaviorIn = 1;
            end
        end
        
        % Opens dialog
        UI.dialog.behaviors = dialog('Position', [300, 300, 500, 200],'Name','Behavior','WindowStyle','modal'); movegui(UI.dialog.behaviors,'center')
        
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'File names', 'Position', [10, 173, 230, 20],'HorizontalAlignment','left');
        behaviorsFileNames = uicontrol('Parent',UI.dialog.behaviors,'Style', 'Edit', 'String', InitFilenames, 'Position', [10, 150, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'Equipment', 'Position', [250, 173, 240, 20],'HorizontalAlignment','left');
        behaviorsEquipment = uicontrol('Parent',UI.dialog.behaviors,'Style', 'Edit', 'String', initEquipment, 'Position', [250, 150, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'Epoch', 'Position', [10, 123, 230, 20],'HorizontalAlignment','left');
        epochList = strcat(cellfun(@num2str,num2cell(1:length(session.epochs)),'un',0),{': '}, cellfun(@(x) x.name,session.epochs,'UniformOutput',false));
        
        behaviorsEpoch = uicontrol('Parent',UI.dialog.behaviors,'Style', 'popup', 'String', epochList, 'Position', [10, 100, 230, 25],'HorizontalAlignment','left');
        behaviorsEpoch.Value = initEpoch;
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'Type', 'Position', [250, 123, 240, 20],'HorizontalAlignment','left');
        behaviorsType = uicontrol('Parent',UI.dialog.behaviors,'Style', 'Edit', 'String', initType, 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'Frame rate', 'Position', [10, 73, 230, 20],'HorizontalAlignment','left');
        behaviorsFramerate = uicontrol('Parent',UI.dialog.behaviors,'Style', 'Edit', 'String', initFramerate, 'Position', [10, 50, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.behaviors,'Style', 'text', 'String', 'Notes', 'Position', [250, 73, 240, 20],'HorizontalAlignment','left');
        behaviorsNotes = uicontrol('Parent',UI.dialog.behaviors,'Style', 'Edit', 'String', initNotes, 'Position', [250, 50, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.behaviors,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save behavior','Callback',@(src,evnt)CloseBehaviors_dialog);
        uicontrol('Parent',UI.dialog.behaviors,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelBehaviors_dialog);
        
        uicontrol(behaviorsFileNames);
        uiwait(UI.dialog.behaviors);
        
        function CloseBehaviors_dialog
            if ~strcmp(behaviorsFileNames.String,'') && isvarname(behaviorsFileNames.String)
                SelectedBehavior = behaviorIn;
                if ~isempty(behaviorsFileNames.String)
                    session.behavioralTracking{SelectedBehavior}.filenames = behaviorsFileNames.String;
                end
                if ~isempty(behaviorsEquipment.String)
                    session.behavioralTracking{SelectedBehavior}.equipment = behaviorsEquipment.String;
                end                
                if ~isempty(behaviorsEpoch.String)
                    session.behavioralTracking{SelectedBehavior}.epoch = behaviorsEpoch.Value;
                end
                if ~isempty(behaviorsType.String)
                    session.behavioralTracking{SelectedBehavior}.type = behaviorsType.String;
                end
                if ~isempty(behaviorsFramerate.String)
                    session.behavioralTracking{SelectedBehavior}.framerate = str2double(behaviorsFramerate.String);
                end
                if ~isempty(behaviorsNotes.String)
                    session.behavioralTracking{SelectedBehavior}.notes = behaviorsNotes.String;
                end
            end
            delete(UI.dialog.behaviors);
            updateBehaviorsList;
        end
        
        function CancelBehaviors_dialog
            delete(UI.dialog.behaviors);
        end
    end

    function editBehavior
        % Selected behavior is parsed to the addBehavior dialog for edits,
        if ~isempty(UI.table.behaviors.Data) && ~isempty(find([UI.table.behaviors.Data{:,1}], 1)) && sum([UI.table.behaviors.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.behaviors.Data{:,1}]);
            addBehavior(fieldtoedit)
        else
            helpdlg('Please select the behavior to edit','Error')
        end
    end

    function duplicateBehavior
        % Selected behavior is parsed to the addBehavior dialog for edits,
        if ~isempty(UI.table.behaviors.Data) && ~isempty(find([UI.table.behaviors.Data{:,1}], 1)) && sum([UI.table.behaviors.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.behaviors.Data{:,1}]);
            session.behavioralTracking{end+1} = session.behavioralTracking{fieldtoedit};
            session.behavioralTracking{end}.filenames = [session.behavioralTracking{fieldtoedit}.filenames,'_duplicated'];
            updateBehaviorsList;
            addBehavior(length(session.behavioralTracking));
        else
            helpdlg('Please select the tracking to duplicate','Error')
        end
    end

%% % Spike sorting

    function deleteSpikeSorting
        % Deletes any selected SpikeSorting
        if ~isempty(UI.table.spikeSorting.Data) && ~isempty(find([UI.table.spikeSorting.Data{:,1}], 1))
            session.spikeSorting(find([UI.table.spikeSorting.Data{:,1}])) = [];
            updateSpikeSortingList
        else
            helpdlg('Please select the sorting(s) to delete','Error')
        end
    end

    function addSpikeSorting(behaviorIn)
        % Add new behavior to session struct
        if exist('behaviorIn','var')
            % method
            if isfield(session.spikeSorting{behaviorIn},'method')
                InitMethod = session.spikeSorting{behaviorIn}.method;
            else
                InitMethod = 'KiloSort';
            end
            % format
            if isfield(session.spikeSorting{behaviorIn},'format')
                initFormat = session.spikeSorting{behaviorIn}.format;
            else
                initFormat = 'Phy';
            end
            % relativePath
            if isfield(session.spikeSorting{behaviorIn},'relativePath')
                initRelativePath = session.spikeSorting{behaviorIn}.relativePath;
            else
                initRelativePath = '';
            end
            % channels
            if isfield(session.spikeSorting{behaviorIn},'channels')
                initChannels = num2str(session.spikeSorting{behaviorIn}.channels);
            else
                initChannels = '';
            end
            % spikeSorter
            if isfield(session.spikeSorting{behaviorIn},'spikeSorter')
                initSpikeSorter = session.spikeSorting{behaviorIn}.spikeSorter;
            else
                initSpikeSorter = '';
            end
            % notes
            if isfield(session.spikeSorting{behaviorIn},'notes')
                initNotes = session.spikeSorting{behaviorIn}.notes;
            else
                initNotes = '';
            end
            % manuallyCurated
            if isfield(session.spikeSorting{behaviorIn},'manuallyCurated')
                initManuallyCurated = session.spikeSorting{behaviorIn}.manuallyCurated;
            else
                initManuallyCurated = 0;
            end
            
            % cellMetrics
            if isfield(session.spikeSorting{behaviorIn},'cellMetrics')
                initCellMetrics = session.spikeSorting{behaviorIn}.cellMetrics;
            else
                initCellMetrics = 0;
            end
        else
            InitMethod = 'KiloSort';
            initFormat = 'Phy';
            initRelativePath = '';
            initChannels = '';
            initSpikeSorter = '';
            initNotes = '';
            initManuallyCurated = 0;
            initCellMetrics = 0;
            
            if isfield(session,'spikeSorting')
                behaviorIn = length(session.spikeSorting)+1;
            else
                behaviorIn = 1;
            end
        end
        
        % Opens dialog
        UI.dialog.spikeSorting = dialog('Position', [300, 300, 500, 225],'Name','Spike sorting','WindowStyle','modal'); movegui(UI.dialog.spikeSorting,'center')
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Sorting method', 'Position', [10, 198, 230, 20],'HorizontalAlignment','left');
        spikeSortingMethod = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'popup', 'String', UI.list.sortingMethod, 'Position', [10, 175, 230, 25],'HorizontalAlignment','left');
        UIsetValue(spikeSortingMethod,InitMethod)
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Sorting format', 'Position', [250, 198, 240, 20],'HorizontalAlignment','left');
        spikeSortinFormat = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'popup', 'String', UI.list.sortingFormat, 'Position', [250, 175, 240, 25],'HorizontalAlignment','left');
        UIsetValue(spikeSortinFormat,initFormat) 
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Relative path', 'Position', [10, 148, 230, 20],'HorizontalAlignment','left');
        spikeSortingRelativePath = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'Edit', 'String', initRelativePath, 'Position', [10, 125, 230, 25],'HorizontalAlignment','left');

        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Channels', 'Position', [250, 148, 240, 20],'HorizontalAlignment','left');
        spikeSortingChannels = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'Edit', 'String', initChannels, 'Position', [250, 125, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Spike sorter', 'Position', [10, 98, 230, 20],'HorizontalAlignment','left');
        spikeSortingSpikeSorter = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'Edit', 'String', initSpikeSorter, 'Position', [10, 75, 230, 25],'HorizontalAlignment','left');
                
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Notes', 'Position', [250, 98, 240, 20],'HorizontalAlignment','left');
        spikeSortingNotes = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'Edit', 'String', initNotes, 'Position', [250, 75, 240, 25],'HorizontalAlignment','left');
        
%         uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Manually curated', 'Position', [10, 75, 230, 20],'HorizontalAlignment','left');
        spikeSortingManuallyCurated = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'checkbox','String','Manually curated', 'value', initManuallyCurated, 'Position', [10, 50, 230, 25],'HorizontalAlignment','left');
        
%         uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Cell metrics', 'Position', [250, 75, 240, 20],'HorizontalAlignment','left');
        spikeSortingCellMetrics = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'checkbox','String','Cell metrics', 'value', initCellMetrics, 'Position', [250, 50, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save sorting','Callback',@(src,evnt)CloseSorting_dialog);
        uicontrol('Parent',UI.dialog.spikeSorting,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelSorting_dialog);
        
        uicontrol(spikeSortingRelativePath);
        uiwait(UI.dialog.spikeSorting);
        
        function CloseSorting_dialog
            if strcmp(spikeSortingRelativePath.String,'') || isempty(regexp(spikeSortingRelativePath.String, '[/\*:?"<>|]', 'once'))
                % isvarname(spikeSortingRelativePath.String)
                SelectedBehavior = behaviorIn;
                session.spikeSorting{SelectedBehavior}.method = spikeSortingMethod.String{spikeSortingMethod.Value};               
                session.spikeSorting{SelectedBehavior}.format = spikeSortinFormat.String{spikeSortinFormat.Value};               
                session.spikeSorting{SelectedBehavior}.relativePath = spikeSortingRelativePath.String;
                
                if ~isempty(spikeSortingChannels.String)
                    session.spikeSorting{SelectedBehavior}.channels = str2double(spikeSortingChannels.String);
                else
                    session.spikeSorting{SelectedBehavior}.channels = [];
                end
                session.spikeSorting{SelectedBehavior}.spikeSorter = spikeSortingSpikeSorter.String;
                session.spikeSorting{SelectedBehavior}.notes = spikeSortingNotes.String;
                session.spikeSorting{SelectedBehavior}.cellMetrics = spikeSortingCellMetrics.Value;
                session.spikeSorting{SelectedBehavior}.manuallyCurated = spikeSortingManuallyCurated.Value;
                delete(UI.dialog.spikeSorting);
                updateSpikeSortingList;
            else
                helpdlg('Please format the relative path correctly','Error')
            end
        end
        
        function CancelSorting_dialog
            delete(UI.dialog.spikeSorting);
        end
    end

    function editSpikeSorting
        % Selected behavior is parsed to the addBehavior dialog for edits,
        if ~isempty(UI.table.spikeSorting.Data) && ~isempty(find([UI.table.spikeSorting.Data{:,1}], 1)) && sum([UI.table.spikeSorting.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.spikeSorting.Data{:,1}]);
            addSpikeSorting(fieldtoedit)
        else
            helpdlg('Please select the sorting to edit','Error')
        end
    end


%% % analysis tags

    function deleteAnalysis
        % Deletes any selected analysis tag
        if ~isempty(UI.table.analysis.Data) && ~isempty(find([UI.table.analysis.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.analysisTags);
            session.analysisTags = rmfield(session.analysisTags,{spikesPlotFieldnames{find([UI.table.analysis.Data{:,1}])}});
            updateAnalysisList
        else
            helpdlg(['Please select the analysis tag(s) to delete'],'Error')
        end
    end

    function addAnalysis(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            InitAnalysis = regionIn;
            if ~isempty(session.analysisTags.(regionIn))
                initValue = num2str(session.analysisTags.(regionIn));
            else
                initValue = '';
            end
        else
            InitAnalysis = '';
            initValue = '';
        end
        
        % Opens dialog
        UI.dialog.analysis = dialog('Position', [300, 300, 500, 150],'Name','Analysis tag','WindowStyle','modal'); movegui(UI.dialog.analysis,'center')
        
        uicontrol('Parent',UI.dialog.analysis,'Style', 'text', 'String', 'Analysis tag name', 'Position', [10, 123, 480, 20],'HorizontalAlignment','left');
        analysisName = uicontrol('Parent',UI.dialog.analysis,'Style', 'Edit', 'String', InitAnalysis, 'Position', [10, 100, 480, 25],'HorizontalAlignment','left');
        if exist('regionIn','var')
            analysisName.Enable = 'off';
        end
        uicontrol('Parent',UI.dialog.analysis,'Style', 'text', 'String', 'Value', 'Position', [10, 73, 480, 20],'HorizontalAlignment','left');
        analysisValue = uicontrol('Parent',UI.dialog.analysis,'Style', 'Edit', 'String', initValue, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.analysis,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save tag','Callback',@(src,evnt)CloseAnalysis_dialog);
        uicontrol('Parent',UI.dialog.analysis,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelAnalysis_dialog);
        
        uicontrol(analysisName);
        uiwait(UI.dialog.analysis);
        
        function CloseAnalysis_dialog
            if ~strcmp(analysisName.String,'') && isvarname(analysisName.String)
                SelectedTag = analysisName.String;
                if ~isempty(analysisValue.String)
                    try
                        if any(isletter(analysisValue.String))
                            session.analysisTags.(SelectedTag) = analysisValue.String;
                        else
                            session.analysisTags.(SelectedTag) = eval(['[',analysisValue.String,']']);
                        end
                    catch
                       helpdlg('Values not formatted correctly','Error')
                        uicontrol(analysisValue);
                        return
                    end
                end
            end
            delete(UI.dialog.analysis);
            updateAnalysisList;
        end
        
        function CancelAnalysis_dialog
            delete(UI.dialog.analysis);
        end
    end

    function editAnalysis
        % Selected tag is parsed to the addTag dialog for edits,
        if ~isempty(UI.table.analysis.Data) && ~isempty(find([UI.table.analysis.Data{:,1}], 1)) && sum([UI.table.analysis.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.analysisTags);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.analysis.Data{:,1}])};
            addAnalysis(fieldtoedit)
        else
            helpdlg('Please select the analysis tag to edit','Error')
        end
    end
    
%% % Time series

    function deleteTimeSeries
        % Deletes any selected TimeSeries
        if ~isempty(UI.table.timeSeries.Data) && ~isempty(find([UI.table.timeSeries.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.timeSeries);
            session.timeSeries = rmfield(session.timeSeries,{spikesPlotFieldnames{find([UI.table.timeSeries.Data{:,1}])}});
            updateTimeSeriesList
        else
            helpdlg(['Please select the time series(s) to delete'],'Error')
        end
    end

    function addTimeSeries(behaviorIn)
        % Add new behavior to session struct
        if exist('behaviorIn','var')
            % method
            if isfield(session.timeSeries.(behaviorIn),'fileName')
                InitFileName = session.timeSeries.(behaviorIn).fileName;
            else
                InitFileName = '';
            end
            % type
            initType = behaviorIn;
            % precision
            if isfield(session.timeSeries.(behaviorIn),'precision')
                initPrecision = session.timeSeries.(behaviorIn).precision;
            else
                initPrecision = '';
            end
            % nChannels
            if isfield(session.timeSeries.(behaviorIn),'nChannels')
                initnChannels = num2str(session.timeSeries.(behaviorIn).nChannels);
            else
                initnChannels = '';
            end
            % sr
            if isfield(session.timeSeries.(behaviorIn),'sr')
                initSr = session.timeSeries.(behaviorIn).sr;
            else
                initSr = '';
            end
            % initnSamples
            if isfield(session.timeSeries.(behaviorIn),'nSamples')
                initnSamples = session.timeSeries.(behaviorIn).nSamples;
            else
                initnSamples = '';
            end
            % initLeastSignificantBit
            if isfield(session.timeSeries.(behaviorIn),'leastSignificantBit')
                initLeastSignificantBit = session.timeSeries.(behaviorIn).leastSignificantBit;
            else
                initLeastSignificantBit = 0;
            end
            % equipment
            if isfield(session.timeSeries.(behaviorIn),'equipment')
                initEquipment = session.timeSeries.(behaviorIn).equipment;
            else
                initEquipment = '';
            end
        else 
            InitFileName = '';
            initType = 'adc';
            initPrecision = 'int16';
            initnChannels = '';
            initSr = '';
            initnSamples = '';
            initLeastSignificantBit = '';
            initEquipment = '';
        end
        
        % Opens dialog
        UI.dialog.timeSeries = dialog('Position', [300, 300, 500, 255],'Name','Time serie','WindowStyle','modal'); movegui(UI.dialog.timeSeries,'center')
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'File name', 'Position', [10, 225, 230, 20],'HorizontalAlignment','left');
        timeSeriesFileName = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'edit', 'String', InitFileName, 'Position', [10, 200, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'Type (tag name)', 'Position', [250, 225, 240, 20],'HorizontalAlignment','left');
        timeSeriesType = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'popup', 'String', UI.list.inputsType, 'Position', [250, 200, 240, 25],'HorizontalAlignment','left');
        UIsetValue(timeSeriesType,initType) 
        if exist('behaviorIn','var')
            timeSeriesType.Enable = 'off';
        end
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'Precision', 'Position', [10, 173, 230, 20],'HorizontalAlignment','left');
        timeSeriesPrecision = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'Edit', 'String', initPrecision, 'Position', [10, 150, 230, 25],'HorizontalAlignment','left');

        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'nChannels', 'Position', [250, 173, 240, 20],'HorizontalAlignment','left');
        timeSeriesnChannels = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'Edit', 'String', initnChannels, 'Position', [250, 150, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'Sample rate', 'Position', [10, 123, 230, 20],'HorizontalAlignment','left');
        timeSeriesSr = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'Edit', 'String', initSr, 'Position', [10, 100, 230, 25],'HorizontalAlignment','left');
                
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'nSamples', 'Position', [250, 123, 240, 20],'HorizontalAlignment','left');
        timeSeriesnSamples = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'Edit', 'String', initnSamples, 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'Least significant bit', 'Position', [10, 73, 230, 20],'HorizontalAlignment','left');
        timeSeriesLeastSignificantBit = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'Edit','String',initLeastSignificantBit, 'Position', [10, 50, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style', 'text', 'String', 'Equipment', 'Position', [250, 73, 240, 20],'HorizontalAlignment','left');
        timeSerieEquipment = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'edit','String',initEquipment, 'Position', [250, 50, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.timeSeries,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save time serie','Callback',@(src,evnt)CloseTimeSeries_dialog);
        uicontrol('Parent',UI.dialog.timeSeries,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelTimeSeries_dialog);
        
        uicontrol(timeSeriesFileName);
        uiwait(UI.dialog.timeSeries);
        
        function CloseTimeSeries_dialog
            if isvarname(timeSeriesType.String{timeSeriesType.Value})
                SelectedBehavior = timeSeriesType.String{timeSeriesType.Value};
                session.timeSeries.(SelectedBehavior).fileName = timeSeriesFileName.String;             
                session.timeSeries.(SelectedBehavior).precision = timeSeriesPrecision.String;
                if ~isempty(timeSeriesnChannels.String)
                    session.timeSeries.(SelectedBehavior).nChannels = str2double(timeSeriesnChannels.String);
                else
                    session.timeSeries.(SelectedBehavior).nChannels = [];
                end
                if ~isempty(timeSeriesSr.String)
                    session.timeSeries.(SelectedBehavior).sr = str2double(timeSeriesSr.String);
                else
                    session.timeSeries.(SelectedBehavior).sr = [];
                end
                if ~isempty(timeSeriesnSamples.String)
                    session.timeSeries.(SelectedBehavior).nSamples = str2double(timeSeriesnSamples.String);
                else
                    session.timeSeries.(SelectedBehavior).nSamples = [];
                end
                if ~isempty(timeSeriesLeastSignificantBit.String)
                    session.timeSeries.(SelectedBehavior).leastSignificantBit = str2double(timeSeriesLeastSignificantBit.String);
                else
                    session.timeSeries.(SelectedBehavior).leastSignificantBit = [];
                end
                session.timeSeries.(SelectedBehavior).equipment = timeSerieEquipment.String;
                delete(UI.dialog.timeSeries);
                updateTimeSeriesList;
            else
                helpdlg('Please provide a filename','Error')
            end
        end

        function CancelTimeSeries_dialog
            delete(UI.dialog.timeSeries);
        end
    end

    function editTimeSeries
        % Selected behavior is parsed to the addBehavior dialog for edits,
                % Selected tag is parsed to the addTag dialog for edits,
        if ~isempty(UI.table.timeSeries.Data) && ~isempty(find([UI.table.timeSeries.Data{:,1}], 1)) && sum([UI.table.timeSeries.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.timeSeries);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.timeSeries.Data{:,1}])};
            addTimeSeries(fieldtoedit)
        else
            helpdlg('Please select the time series to edit','Error')
        end
    end

%% Extracellular spike groups
    
    function deleteElectrodeGroup(src,~)
        group = src.Tag;
        % Deletes group(s)
        if ~isempty(UI.table.(group).Data) && ~isempty(find([UI.table.(group).Data{:,1}], 1))
            session.extracellular.(group).channels([UI.table.(group).Data{:,1}]) = [];
            if strcmp(group,'electrodeGroups')
                session.extracellular.nElectrodeGroups = size(session.extracellular.(group).channels,2);
            else
                session.extracellular.nSpikeGroups = size(session.extracellular.(group).channels,2);
            end
            updateChannelGroupsList(group)
        else
            helpdlg('Please select the group(s) to delete','Error')
        end
    end

    function addElectrodeGroup(src,~)
        group = src.Tag;
        button = src.String;
         % Select electrode group for edit
        if strcmp(button,'Edit') && ~isempty(UI.table.(group).Data) && ~isempty(find([UI.table.(group).Data{:,1}], 1)) && sum([UI.table.(group).Data{:,1}]) == 1
            fieldtoedit = find([UI.table.(group).Data{:,1}]);
            regionIn = fieldtoedit;
        elseif strcmp(button,'Edit')
            helpdlg('Please select one group to edit','Error')
            return
        end
        
        % Add new electrode group
        if exist('regionIn','var')
            initElectrodeGroups = num2str(regionIn);
            if isnumeric(session.extracellular.(group).channels)
                initChannels = num2str(session.extracellular.(group).channels(regionIn,:));
            else
                initChannels = num2str(session.extracellular.(group).channels{regionIn});
            end
            if isfield(session.extracellular.(group),'label') && size(session.extracellular.(group).label,2)>=regionIn && ~isempty(session.extracellular.(group).label{regionIn})
                initLabel = session.extracellular.(group).label{regionIn};
            else
                initLabel = '';
            end
        else
            if isfield(session.extracellular,'electrodeGroups') && isfield(session.extracellular.(group),'channels') 
                initElectrodeGroups = num2str(size(session.extracellular.(group).channels,2)+1);
            else
                initElectrodeGroups = 1;
                session.extracellular.nElectrodeGroups = 0;
            end
            initChannels = '';
            initLabel = '';
        end
        
        % Opens dialog
        UI.dialog.electrodes = dialog('Position', [300, 300, 500, 200],'Name','Electrode group','WindowStyle','modal'); movegui(UI.dialog.electrodes,'center')
        
        uicontrol('Parent',UI.dialog.electrodes,'Style', 'text', 'String', ['Group (nGroups = ',num2str(session.extracellular.nElectrodeGroups),')'], 'Position', [10, 173, 480, 20],'HorizontalAlignment','left');
        spikeGroupsSpikeGroups = uicontrol('Parent',UI.dialog.electrodes,'Style', 'Edit', 'String', initElectrodeGroups, 'Position', [10, 150, 480, 25],'HorizontalAlignment','left','enable', 'off');
        
        uicontrol('Parent',UI.dialog.electrodes,'Style', 'text', 'String', ['Channels (nChannels = ',num2str(session.extracellular.nChannels),')'], 'Position', [10, 123, 480, 20],'HorizontalAlignment','left');
        spikeGroupsChannels = uicontrol('Parent',UI.dialog.electrodes,'Style', 'Edit', 'String', initChannels, 'Position', [10, 100, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.electrodes,'Style', 'text', 'String', 'Label', 'Position', [10, 73, 480, 20],'HorizontalAlignment','left');
        spikeGroupsLabel = uicontrol('Parent',UI.dialog.electrodes,'Style', 'Edit', 'String', initLabel, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.electrodes,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save','Callback',@(src,evnt)save_and_close_dialog);
        uicontrol('Parent',UI.dialog.electrodes,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
        
        uicontrol(spikeGroupsChannels);
        uiwait(UI.dialog.electrodes);
        
        function save_and_close_dialog
            spikeGroup = str2double(spikeGroupsSpikeGroups.String);
            if ~isempty(spikeGroupsChannels.String)
                try
                    session.extracellular.(group).channels{spikeGroup} = eval(['[',spikeGroupsChannels.String,']']);
                catch
                    helpdlg(['Channels not formatted correctly'],'Error')
                    uicontrol(spikeGroupsChannels);
                    return
                end
            end
            session.extracellular.(group).label{spikeGroup} = spikeGroupsLabel.String;
            delete(UI.dialog.electrodes);
            if strcmp(group,'electrodeGroups')
                session.extracellular.nElectrodeGroups = size(session.extracellular.(group),2);
            else
                session.extracellular.nSpikeGroups = size(session.extracellular.(group),2);
            end
            updateChannelGroupsList(group)
        end
        
        function cancel_dialog
            delete(UI.dialog.electrodes);
        end
    end

    function moveElectrodes(src,~)
        if~isempty(UI.table.(src.Tag).Data) && ~isempty(find([UI.table.(src.Tag).Data{:,1}], 1)) && sum([UI.table.(src.Tag).Data{:,1}])>0
            cell2move = [UI.table.(src.Tag).Data{:,1}];
            newOrder = 1:length(session.extracellular.(src.Tag).channels);
            if strcmp(src.String,char(8595))
                offset = cumsumWithReset2(cell2move);
                newOrder1 = newOrder+offset;
            else
                offset = cumsumWithReset(cell2move);
                newOrder1 = newOrder-offset;
            end
            [~,newOrder] = sort(newOrder1);
            session.extracellular.(src.Tag).channels = session.extracellular.(src.Tag).channels(newOrder);
            updateChannelGroupsList(src.Tag)
            UI.table.(src.Tag).Data(find(ismember(newOrder,find(cell2move))),1) = {true};
        else
            helpdlg('Please select the group(s) to move','Error')
        end
    end
    
    function editEpochsTableData(src,evnt)
        % {'','','Name','Start time','Stop time','Paradigm','Environment','Manipulations','Stimuli','Notes'}
        edit_group = evnt.Indices(1,1);
        if evnt.Indices(1,2)==3
            session.epochs{edit_group}.name = evnt.NewData;
        elseif evnt.Indices(1,2)==4
            try
                newNumber = eval(['[',evnt.EditData,']']);
                if isnumeric(newNumber) && numel(newNumber)==1
                    session.epochs{edit_group}.startTime = newNumber;
                end
            catch
                helpdlg('Start time not formatted correctly','Error')
            end
            updateEpochsList
        elseif evnt.Indices(1,2)==5
            try
                newNumber = eval(['[',evnt.EditData,']']);
                if isnumeric(newNumber) && numel(newNumber)==1
                    session.epochs{edit_group}.stopTime = newNumber;
                end
            catch
                helpdlg('Stop time not formatted correctly','Error')
            end
            updateEpochsList
        elseif evnt.Indices(1,2)==6
            session.epochs{edit_group}.behavioralParadigm = evnt.NewData;
        elseif evnt.Indices(1,2)==7
            session.epochs{edit_group}.environment = evnt.NewData;
        elseif evnt.Indices(1,2)==8
            session.epochs{edit_group}.manipulation = evnt.NewData;
        elseif evnt.Indices(1,2)==9
            session.epochs{edit_group}.stimulus = evnt.NewData;
        elseif evnt.Indices(1,2)==10
            session.epochs{edit_group}.notes = evnt.NewData;
        end
    end    
        
    function editElectrodeTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        if evnt.Indices(1,2)==3
            try
                session.extracellular.(src.Tag).channels{edit_group} = eval(['[',evnt.NewData,']']);
            catch
                helpdlg('Channels not formatted correctly','Error')
            end
            updateChannelGroupsList(src.Tag)
        elseif evnt.Indices(1,2)==4
            session.extracellular.(src.Tag).label{edit_group} = evnt.NewData;
        end
    end    
    
    function editSpikeSortingTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        if evnt.Indices(1,2)==2
            session.spikeSorting{edit_group}.method = evnt.NewData;
        elseif evnt.Indices(1,2)==3
            session.spikeSorting{edit_group}.format = evnt.NewData;
        elseif evnt.Indices(1,2)==4
            session.spikeSorting{edit_group}.relativePath = evnt.NewData;
        elseif evnt.Indices(1,2)==5
            try
                session.spikeSorting{edit_group}.channels = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Channels not formatted correctly','Error')
            end
            updateSpikeSortingList
        elseif evnt.Indices(1,2)==6
            session.spikeSorting{edit_group}.relativePath = evnt.NewData;
        elseif evnt.Indices(1,2)==7   
            session.spikeSorting{edit_group}.notes = evnt.NewData;
        elseif evnt.Indices(1,2)==8  
            session.spikeSorting{edit_group}.cellMetrics = evnt.NewData;
        elseif evnt.Indices(1,2)==9
            session.spikeSorting{edit_group}.manuallyCurated = evnt.NewData;    
        end
    end
    
    function editBrainregionTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        region = src.Data{edit_group,2};
        if evnt.Indices(1,2)==3
            try
                session.brainRegions.(region).channels = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Channels not formatted correctly','Error')
            end
            updateBrainRegionList
        elseif evnt.Indices(1,2)==4
            try
                session.brainRegions.(region).electrodeGroups = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Electrode groups not formatted correctly','Error')
            end
            updateBrainRegionList
        elseif evnt.Indices(1,2)==5
            session.brainRegions.(region).notes = evnt.NewData;
        end
    end
    
    function editTagsTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        tag = src.Data{edit_group,2};
        if evnt.Indices(1,2)==3
            try
                session.channelTags.(tag).channels = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Channels not formatted correctly','Error')
            end
            updateTagList
        elseif evnt.Indices(1,2)==4
            try
                session.channelTags.(tag).electrodeGroups = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Electrode groups not formatted correctly','Error')
            end
            updateTagList
        end
    end
    
    function editAnalysisTagsTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        tag = src.Data{edit_group,2};
        if evnt.Indices(1,2)==3
            if isnumeric(session.analysisTags.(tag))
                try
                    session.analysisTags.(tag) = eval(['[',evnt.EditData,']']);
                catch
                    helpdlg('analysis tag not formatted correctly. Must be numeric','Error')
                end
            else
                session.analysisTags.(tag) = evnt.EditData;
            end
            updateAnalysisList
        end
    end
    
    function editInputsTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        input = src.Data{edit_group,2};
        if evnt.Indices(1,2)==3
            try
                session.inputs.(input).channels = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Channels not formatted correctly. Must be numeric','Error')
            end
            updateInputsList
        elseif evnt.Indices(1,2)==4
            session.inputs.(input).inputType = evnt.EditData;
        elseif evnt.Indices(1,2)==5
            session.inputs.(input).equipment = evnt.EditData;
        elseif evnt.Indices(1,2)==6
            session.inputs.(input).description = evnt.EditData;
        end
    end
    
    function editTimeSeriesTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        timeSeries = src.Data{edit_group,2};
        if evnt.Indices(1,2)==3
            session.timeSeries.(timeSeries).fileName = evnt.EditData;
        elseif evnt.Indices(1,2)==4
            session.timeSeries.(timeSeries).precision = evnt.EditData;
        elseif evnt.Indices(1,2)==5
            try
                session.timeSeries.(timeSeries).nChannels = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('nChannels not formatted correctly. Must be numeric','Error')
            end
            updateTimeSeriesList
        elseif evnt.Indices(1,2)==6
            try
                session.timeSeries.(timeSeries).sr = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Sampling rate not formatted correctly. Must be numeric','Error')
            end
            updateTimeSeriesList
        elseif evnt.Indices(1,2)==7
            try
                session.timeSeries.(timeSeries).nSamples = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('nSamples not formatted correctly. Must be numeric','Error')
            end
            updateTimeSeriesList
        elseif evnt.Indices(1,2)==8
            try
                session.timeSeries.(timeSeries).leastSignificantBit = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Least significant bit not formatted correctly. Must be numeric','Error')
            end
            updateTimeSeriesList
        elseif evnt.Indices(1,2)==9
            session.timeSeries.(timeSeries).equipment = evnt.EditData;
        end
    end
    
    function editBehaviorTableData(src,evnt)
        edit_group = evnt.Indices(1,1);
        if evnt.Indices(1,2)==2
            session.behavioralTracking{edit_group}.filenames = evnt.EditData;
        elseif evnt.Indices(1,2)==3
            session.behavioralTracking{edit_group}.equipment = evnt.EditData;
        elseif evnt.Indices(1,2)==4
            try
                epoch = eval(['[',evnt.EditData,']']);
                if epoch>0 & epoch<=numel(session.epochs)
                    session.behavioralTracking{edit_group}.epoch = epoch;
                else
                    helpdlg('Epoch not formatted correctly. Must be numeric and exist','Error')
                end
            catch
                helpdlg('Epoch not formatted correctly. Must be numeric and exist','Error')
            end
            updateBehaviorsList
        elseif evnt.Indices(1,2)==5
            session.behavioralTracking{edit_group}.type = evnt.EditData;
        elseif evnt.Indices(1,2)==6
            try
                session.behavioralTracking{edit_group}.framerate = eval(['[',evnt.EditData,']']);
            catch
                helpdlg('Framerate not formatted correctly. Must be numeric','Error')
            end
            updateBehaviorsList
        elseif evnt.Indices(1,2)==7
            session.behavioralTracking{edit_group}.notes = evnt.EditData;
        end
    end
    
    function verifyElectrodeGroup(~,~)
        if isfield(session.extracellular,'electrodeGroups')
            if isnumeric(session.extracellular.electrodeGroups.channels)
                channels = session.extracellular.electrodeGroups.channels(:);
            else
                channels = [session.extracellular.electrodeGroups.channels{:}];
            end
            uniqueChannels = length(unique(channels));
            nChannels = length(channels);
            if nChannels ~= session.extracellular.nChannels
                helpdlg(['Channel count in electrode groups (', num2str(nChannels), ') does not corresponds to nChannels (',num2str(session.extracellular.nChannels),')'],'Error')
            elseif uniqueChannels ~= session.extracellular.nChannels
                helpdlg('The unique channel count does not corresponds to nChannels','Error')
            elseif any(sort(channels) ~= [1:session.extracellular.nChannels])
                helpdlg('Channels are not ranging from 1 : nChannels','Error')
            else
                msgbox('Channels verified succesfully!');
            end
        else
            msgbox('Error: No electrode groups found.');
        end
    end

    function importGroupsFromXML
        xml_filepath = fullfile(UI.edit.basepath.String,[UI.edit.session.String, '.xml']);
        if exist(xml_filepath,'file')
            MsgLog('Importing groups from XML...',0)
            
            session = import_xml2session(xml_filepath,session);
            updateChannelGroupsList('electrodeGroups')
            updateChannelGroupsList('spikeGroups')
            UIsetString(session.extracellular,'sr'); % Sampling rate of dat file
            UIsetString(session.extracellular,'srLfp'); % Sampling rate of lfp file
            UIsetString(session.extracellular,'nChannels'); % Number of channels
            MsgLog('XML imported',2)
        else
            MsgLog(['xml file not accessible: ' xml_filepath],4)
        end
    end
    
    function importKiloSort
        if isfield(session,'spikeSorting') && isfield(session.spikeSorting{1},'relativePath')
            relativePath = session.spikeSorting{1}.relativePath;
        else
            relativePath = ''; % Relative path to the clustered data (here assumed to be the basepath)
        end
        rezFile = dir(fullfile(basepath,relativePath,'rez*.mat'));
        
        if ~isempty(rezFile)
            rezFile = fullfile(rezFile.folder,rezFile.name);
            MsgLog('Importing KiloSort metadata...',0)
            session = loadKiloSortMetadata(session,rezFile);
            updateChannelGroupsList
            UIsetString(session.extracellular,'sr'); % Sampling rate of dat file
            UIsetString(session.extracellular,'srLfp'); % Sampling rate of lfp file
            UIsetString(session.extracellular,'nChannels'); % Number of channels
            MsgLog('KiloSort metadata imported via rez file',2)
        else
            MsgLog('rez file does not exist',4)
        end
    end
    
    function importMetadataTemplate
        MsgLog('Importing metadata using template',0)
        session = sessionTemplate(session);
        updateChannelGroupsList
        UIsetString(session.extracellular,'sr'); % Sampling rate of dat file
        UIsetString(session.extracellular,'srLfp'); % Sampling rate of lfp file
        UIsetString(session.extracellular,'nChannels'); % Number of channels
        MsgLog('Metadata imported using template',2)
    end
    
    function syncChannelGroups
        answer = questdlg('How do you want to sync the channel groups?','Sync channel groups','electrode groups -> spike groups', 'spike groups -> electrode groups','Cancel','electrode groups -> spike groups');
        if strcmp(answer,'electrode groups -> spike groups') && isfield(session.extracellular,'electrodeGroups')
            session.extracellular.spikeGroups = session.extracellular.electrodeGroups;
        elseif strcmp(answer,'spike groups -> electrode groups') && isfield(session.extracellular,'spikeGroups')
            session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
        elseif strcmp(answer,'Cancel')
            return
        end
        updateChannelGroupsList
    end
    
    function generateCommonCoordinates1
        generateCommonCoordinates(session)
    end
    
    function generateChannelMap1
        [CellExplorer_path,~,~] = fileparts(which('CellExplorer.m'));
        if isfield(session.animal,'probes') && exist(fullfile(CellExplorer_path,'+ChanCoords',[session.animal.probeImplants{1}.probe,'.probes.chanCoords.channelInfo.mat']),'file')
            disp('Loading predefined chanCoords')
            load(fullfile(CellExplorer_path,'+ChanCoords',[session.animal.probeImplants{1}.probe,'.probes.chanCoords.channelInfo.mat']),'chanCoords');
        else
            chanMap = generateChannelMap(session);
            chanCoords.x = chanMap.xcoords(:);
            chanCoords.y = chanMap.ycoords(:);
            chanCoords.source = chanMap.source;
            chanCoords.layout = chanMap.layout;
            chanCoords.shankSpacing = chanMap.shankSpacing;
        end
        x_range = range(chanCoords.x);
        y_range = range(chanCoords.y);
        if x_range > y_range
            fig_width = 1600;
            fig_height = ceil(fig_width*y_range/x_range)+200;
        else
            fig_height = 1000;
            fig_width = ceil(fig_height*x_range/y_range)+200;
        end
        fig1 = figure('Name','Channel map','position',[5,5,fig_width,fig_height]); movegui(fig1,'center')
        plot(chanCoords.x,chanCoords.y,'.k'), hold on
        text(chanCoords.x,chanCoords.y,num2str([1:numel(chanCoords.x)]'),'VerticalAlignment', 'bottom','HorizontalAlignment','center');
        title({' ','Channel map',' '}), xlabel('X (um)'), ylabel('Y (um)'), 
        % Saving chanCoords to basename.chanCoords.channelInfo.mat file
        saveStruct(chanCoords,'channelInfo','session',session);
    end

    function importBadChannelsFromXML(~,~)
        xml_filepath = fullfile(UI.edit.basepath.String,[UI.edit.session.String, '.xml']);
        if exist(xml_filepath,'file')
            sessionInfo = LoadXml(xml_filepath);
            
            % Removing dead channels by the skip parameter in the xml
            order = [sessionInfo.AnatGrps.Channels];
            skip = find([sessionInfo.AnatGrps.Skip]);
            badChannels_skipped = order(skip)+1;
            
            % Removing dead channels by comparing AnatGrps to SpkGrps in the xml
            if isfield(sessionInfo,'SpkGrps')
                skip2 = find(~ismember([sessionInfo.AnatGrps.Channels], [sessionInfo.SpkGrps.Channels])); % finds the indices of the channels that are not part of SpkGrps
                badChannels_synced = order(skip2)+1;
            else
                badChannels_synced = [];
            end
            
            if isfield(session,'channelTags') & isfield(session.channelTags,'Bad')
                session.channelTags.Bad.channels = unique([session.channelTags.Bad.channels,badChannels_skipped,badChannels_synced]);
            else
                session.channelTags.Bad.channels = unique([badChannels_skipped,badChannels_synced]);
            end
            if isempty(session.channelTags.Bad.channels)
                session.channelTags.Bad = rmfield(session.channelTags.Bad,'channels');
            end
            if isfield(session.channelTags,'Bad') && isfield(session.channelTags.Bad,'channels') && ~isempty(session.channelTags.Bad.channels)
                msgbox([num2str(length(session.channelTags.Bad.channels)),' bad channels detected (' num2str(session.channelTags.Bad.channels),')'])
            else
                msgbox('No bad channels detected')
                if isfield(session.channelTags,'Bad')
                    session.channelTags = rmfield(session.channelTags,'Bad');
                end
            end
            updateTagList
        else
            MsgLog(['xml file not accessible: ' xml_filepath],4)
        end
    end

    function MsgLog(message,priority)
        % Writes the input message to the message log with a timestamp. The second parameter
        % defines the priority i.e. if any  message or warning should be given as well.
        % priority:
        % 0: Shows message inly in message log popup
        % 1: Show message in Command Window
        % 2: Show msg dialog
        % 3: Show warning in Command Window
        % 4: Show warning dialog
        % -1: disp only
        
        timestamp = datestr(now, 'HH:MM:SS');
        message2 = sprintf('[%s] %s', timestamp, message);
        %         if ~exist('priority','var') || (exist('priority','var') && any(priority >= 0))
        %             UI.popupmenu.log.String = [UI.popupmenu.log.String;message2];
        %             UI.popupmenu.log.Value = length(UI.popupmenu.log.String);
        %         end
        dialog1.Interpreter = 'none';
        dialog1.WindowStyle = 'modal';
        if exist('priority','var')
            if any(priority < 0)
                disp(message2)
            end
            if any(priority == 1)
                disp(message)
            end
            if any(priority == 2)
                msgbox(message,'Message',dialog1);
            end
            if any(priority == 3)
                warning(message)
            end
            if any(priority == 4)
                warndlg(message,'Warning')
            end
        end
    end
end