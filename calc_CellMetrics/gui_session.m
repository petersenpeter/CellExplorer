function [session,parameters,statusExit] = gui_session(sessionIn,parameters)
% Displays a GUI allowing you to edit parameters for the CellExplorer and metadata for a session
% Can be run from a basepath as well (if no inputs are provided).
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

% gui_session is part of the CellExplorer: https://petersenpeter.github.io/CellExplorer/

% By Peter Petersen 
% petersen.peter@gmail.com
% Last edited: 16-03-2020

% Lists
sortingMethodList = {'KiloSort', 'SpyKING CIRCUS', 'Klustakwik', 'MaskedKlustakwik'}; % Spike sorting methods
sortingFormatList = {'Phy', 'KiloSort', 'SpyKING CIRCUS', 'Klustakwik', 'KlustaViewa', 'Neurosuite','MountainSort','IronClust'}; % Spike sorting formats
inputsTypeList = {'adc', 'aux','dat', 'dig'}; % input data types
sessionTypesList = {'Chronic', 'Acute'}; % session types

% metrics in cell metrics pipeline
UI.list.metrics = {'waveform_metrics','PCA_features','acg_metrics','deepSuperficial','monoSynaptic_connections','theta_metrics','spatial_metrics','event_metrics','manipulation_metrics','state_metrics','psth_metrics','importCellTypeClassification'};

% Parameters in cell metrics pipeline
UI.list.params = {'forceReload','summaryFigures','saveMat','saveBackup','debugMode','submitToDatabase','keepCellClassification','excludeManipulationIntervals','manualAdjustMonoSyn','includeInhibitoryConnections'};

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
uiLoaded = false;

% % % % % % % % % % % % % % % % % % % %
% Handling inputs
% % % % % % % % % % % % % % % % % % % %

if exist('sessionIn','var') && isstruct(sessionIn)
    session = sessionIn;
    if isfield(session.general,'basePath')
        basepath = session.general.basePath;
    else
        basepath = '';
    end
    if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') & ~isempty(session.spikeSorting{1}.relativePath)
        clusteringpath = session.spikeSorting{1}.relativePath;
    else
        clusteringpath = '';
    end
elseif exist('sessionIn','file') && ischar(sessionIn)
    disp(['Loading ' sessionIn]);
    load(sessionIn,'session');
    [filepath,~,~] = fileparts(sessionIn);
    basepath = filepath;
    sessionIn = session;
    if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') & ~isempty(session.spikeSorting{1}.relativePath)
        clusteringpath = session.spikeSorting{1}.relativePath;
    else
        clusteringpath = '';
    end
else
    basepath = pwd;
    [~,basename,~] = fileparts(pwd);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        disp(['Loading ',basename,'.session.mat from current path']);
        
        load(fullfile(basepath,[basename,'.session.mat']),'session');
        sessionIn = session;
        if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') && ~isempty(session.spikeSorting{1}.relativePath)
            clusteringpath = session.spikeSorting{1}.relativePath;
        else
            clusteringpath = '';
        end
    elseif exist(fullfile(basepath,'session.mat'),'file')
        disp('Loading session.mat from current path');
        load(fullfile(basepath,'session.mat'),'session');
        sessionIn = session;
        if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') && ~isempty(session.spikeSorting{1}.relativePath)
            clusteringpath = session.spikeSorting{1}.relativePath;
        else
            clusteringpath = '';
        end
    else
        answer = questdlg([basename,'.session.mat does not exist. Would you like to create one from a template or locate an existing session file?'],'No basename.session.mat file found','Create from template', 'Load from database','Locate file','Create from template');
        % Handle response
        switch answer
            case 'Create from template'
                session = sessionTemplate(pwd);
                sessionIn = session;
                basepath = session.general.basePath;
                if isfield(session.spikeSorting{1},'relativePath') & ~isempty(session.spikeSorting{1}.relativePath)
                    clusteringpath = session.spikeSorting{1}.relativePath;
                else
                    clusteringpath = '';
                end
            case 'Locate file'
                [file,basepath] = uigetfile('*.mat','Please select a session.mat file','*.session.mat');
                if ~isequal(file,0)
                    cd(basepath)
                    temp = load(file,'session');
                    sessionIn = temp.session;
                    session = sessionIn;
                    if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') & ~isempty(session.spikeSorting{1}.relativePath)
                        clusteringpath = session.spikeSorting{1}.relativePath;
                    else
                        clusteringpath = '';
                    end
                else
                    warning('Please provide a session struct')
                    return
                end
            case 'Load from database'
                [~,nameFolder,~] = fileparts(pwd);
                session.general.name = nameFolder;
                success = updateFromDB;
                if success == 0
                    warning(['Failed to load session metadata from database']);
                    return
                else
                    if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') & ~isempty(session.spikeSorting{1}.relativePath)
                        clusteringpath = session.spikeSorting{1}.relativePath;
                    else
                        clusteringpath = '';
                    end
                end
            otherwise
                return
        end
    end
end

% Importing session metadata from DB if metadata is out of data
if ~isfield(session.general,'version') || session.general.version<4
    if isfield(session.general,'entryID')
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
session.general.basePath = basepath;
if exist('clusteringpath','var')
    session.general.clusteringPath = clusteringpath;
end
statusExit = 0;

%% % % % % % % % % % % % % % % % % % % %
% Initializing GUI
% % % % % % % % % % % % % % % % % % % %

% Creating figure for the GUI
UI.fig = figure('units','pixels','position',[50,50,620,560],'Name','Session metadata','NumberTitle','off','renderer','opengl', 'MenuBar', 'None','PaperOrientation','landscape','visible','off');
movegui(UI.fig,'center')

% Tabs
% tempPosition = UI.fig.InnerPosition;
UI.uitabgroup = uitabgroup('Units','normalized','Position',[0 0.06 1 0.94],'Parent',UI.fig,'Units','normalized');
if exist('parameters','var')
    UI.tabs.parameters = uitab(UI.uitabgroup,'Title','Cell metrics');
end
UI.tabs.general = uitab(UI.uitabgroup,'Title','General');
UI.tabs.epochs = uitab(UI.uitabgroup,'Title','Epochs');
UI.tabs.animal = uitab(UI.uitabgroup,'Title','Animal');
UI.tabs.extracellular = uitab(UI.uitabgroup,'Title','Extracellular');

UI.tabs.spikeSorting = uitab(UI.uitabgroup,'Title','Spike sorting');
UI.tabs.brainRegions = uitab(UI.uitabgroup,'Title','Brain regions');
UI.tabs.channelTags = uitab(UI.uitabgroup,'Title','Tags');
UI.tabs.inputs = uitab(UI.uitabgroup,'Title','Inputs & time series');
UI.tabs.behaviors = uitab(UI.uitabgroup,'Title','Tracking');

% Buttons
UI.button.ok = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[10, 5, 80, 28],'String','OK','Callback',@(src,evnt)CloseMetricsWindow,'Units','normalized','Interruptible','off');
UI.button.save = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[100, 5, 80, 28],'String','Save','Callback',@(src,evnt)saveSessionFile,'Units','normalized','Interruptible','off');
UI.button.cancel = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[190, 5, 80, 28],'String','Cancel','Callback',@(src,evnt)cancelMetricsWindow,'Units','normalized','Interruptible','off');
UI.button.uploadToDB = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[280, 5, 100, 28],'String','Upload to DB','Callback',@(src,evnt)buttonUploadToDB,'Units','normalized','Interruptible','off');
UI.button.updateFromDB = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[390, 5, 110, 28],'String','Download from DB','Callback',@(src,evnt)buttonUpdateFromDB,'Units','normalized','Interruptible','off');
UI.status = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[510, 5, 100, 28],'String','Help','Units','normalized','Callback',@(src,evnt)buttonHelp,'HorizontalAlignment','center', 'fontweight', 'bold','ForegroundColor','k','enable','on','hittest','off');

% % % % % % % % % % % % % % % % % % % %
% Cell metrics parameters

if exist('parameters','var')
    % Include metrics
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Include metrics (default: all)', 'Position', [10, 500, 285, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.listbox.includeMetrics = uicontrol('Parent',UI.tabs.parameters,'Style','listbox','Position',[10 330 275 170],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.metrics),'Units','normalized');
    
    % Exclude metrics
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Exclude metrics (default: none)', 'Position', [300, 500, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    UI.listbox.excludeMetrics = uicontrol('Parent',UI.tabs.parameters,'Style','listbox','Position',[300 330 310 170],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.excludeMetrics),'Units','normalized');
    
    % Parameters
    uicontrol('Parent',UI.tabs.parameters,'Style', 'text', 'String', 'Parameters', 'Position', [10, 305, 288, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
    for iParams = 1:length(UI.list.params)
        if iParams <=6
            offset = 0;
        else
            offset = 140;
        end
        UI.checkbox.params(iParams) = uicontrol('Parent',UI.tabs.parameters,'Style','checkbox','Position',[10+offset 285-rem(iParams-1,6)*18 260 15],'Units','normalized','String',UI.list.params{iParams});
    end
end

% % % % % % % % % % % % % % % % % % % %
% General

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Base path', 'Position', [10, 498, 300, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.basepath = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 475, 600, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Session name (base name)', 'Position', [10, 448, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.session = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.name, 'Position', [10, 425, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Session type', 'Position', [300, 448, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sessionType = uicontrol('Parent',UI.tabs.general,'Style', 'popup', 'String', sessionTypesList, 'Position', [300, 425, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Clustering path (relative)', 'Position', [10, 398, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.clusteringpath = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 375, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Duration', 'Position', [300, 398, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.duration = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 375, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Date', 'Position', [10, 348, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.date = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 325, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Time', 'Position', [300, 348, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.time = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 325, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Location', 'Position', [10, 298, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.location = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 275, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Experimenters', 'Position', [300, 298, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.experimenters = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 275, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Investigator', 'Position', [10, 253, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.investigator = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 230, 140, 25],'HorizontalAlignment','left','Units','normalized');
UI.edit.investigatorDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[160, 230, 130, 25],'String','View db investigator','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Projects', 'Position', [300, 253, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.projects = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 230, 160, 25],'HorizontalAlignment','left','Units','normalized');
UI.edit.projectsDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[470, 230, 140, 25],'String','View db projects','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Repositories', 'Position', [10, 203, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.repositories = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 180, 140, 25],'HorizontalAlignment','left','Units','normalized');
UI.edit.repositoryDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[160, 180, 130, 25],'String','View db repository','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'DB entry ID', 'Position', [300, 203, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sessionID = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [300, 180, 160, 25],'HorizontalAlignment','left','Units','normalized','enable','off');
UI.edit.sessionDBbutton = uicontrol('Parent',UI.tabs.general,'Style','pushbutton','Position',[470, 180, 140, 25],'String','View db session','Callback',@openInWebDB,'Units','normalized','Interruptible','off');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Notes', 'Position', [10, 148, 600, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.notes = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', '', 'Position', [10, 10, 600, 140],'HorizontalAlignment','left','Units','normalized', 'Min', 0, 'Max', 100);


% % % % % % % % % % % % % % % % % % % % %
% Epochs

tableData = {false,'','',''};
% uicontrol('Parent',UI.tabs.epochs,'Style', 'text', 'String', 'Epochs', 'Position', [10, 200, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.table.epochs = uitable(UI.tabs.epochs,'Data',tableData,'Position',[1, 90, 619, 435],'ColumnWidth',{20 20 160 80 80 100 100 100 60 95},'columnname',{'','','Name','Start time','Stop time','Paradigm','Environment','Manipulations','Stimuli','Notes'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add epoch','Callback',@(src,evnt)addEpoch,'Units','normalized','Interruptible','off');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[10, 50, 100, 30],'String','Edit epoch','Callback',@(src,evnt)editEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[120, 10 100, 30],'String','Delete epoch(s)','Callback',@(src,evnt)deleteEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[120, 50, 100, 30],'String','Duplicate','Callback',@(src,evnt)duplicateEpoch,'Units','normalized');
UI.button.importEpochsIntervalsFromMergePoints = uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[360, 50, 130, 30],'String','Import merge points','Callback',@importEpochsIntervalsFromMergePoints,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[360, 10 130, 30],'String','Import children','Callback',@importFromFiles,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[500, 50, 110, 30],'String','Move up','Callback',@(src,evnt)moveUpEpoch,'Units','normalized');
uicontrol('Parent',UI.tabs.epochs,'Style','pushbutton','Position',[500, 10 110, 30],'String','Move down','Callback',@(src,evnt)moveDownEpoch,'Units','normalized');


% % % % % % % % % % % % % % % % % % % % %
% Animal

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Name', 'Position', [10, 500, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.name = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [10, 475, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Sex', 'Position', [300, 500, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sex = uicontrol('Parent',UI.tabs.animal,'Style', 'popup', 'String', {'Unknown','Male','Female'}, 'Position', [300, 475, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Species', 'Position', [10, 450, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.species = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [10, 425, 280, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Strain', 'Position', [300, 450, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.strain = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [300, 425, 310, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.animal,'Style', 'text', 'String', 'Genetic line', 'Position', [10, 400, 280, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.geneticLine = uicontrol('Parent',UI.tabs.animal,'Style', 'Edit', 'String', '', 'Position', [10, 375, 280, 25],'HorizontalAlignment','left','Units','normalized');


% % % % % % % % % % % % % % % % % % % % %
% Extracellular

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'nChannels', 'Position', [10, 498, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.nChannels = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 475, 180, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Sampling rate (Hz)', 'Position', [200, 498, 190, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.sr = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [200, 475, 190, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'nSamples', 'Position', [400, 498, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.nSamples = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 475, 210, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Precision (e.g. int16)', 'Position', [10, 448, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.precision = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 425, 180, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Least significant bit (µV; Intan: 0.195)', 'Position', [200, 448, 220, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.leastSignificantBit = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [200, 425, 190, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Depth (µm)', 'Position', [400, 448, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.probeDepths = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 425, 210, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Equipment', 'Position', [10, 398, 310, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.equipment = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [10, 375, 380, 25],'HorizontalAlignment','left','Units','normalized');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'LFP sampling rate (Hz)', 'Position', [400, 398, 180, 20],'HorizontalAlignment','left', 'fontweight', 'bold','Units','normalized');
UI.edit.srLfp = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', '', 'Position', [400, 375, 210, 25],'HorizontalAlignment','left','Units','normalized');


% % % % % % % % % % % % % % % % % % % % % %
% Channel groups

UI.channelGroups = uitabgroup('units','pixels','Position',[0, 0, 619, 365],'Parent',UI.tabs.extracellular,'Units','normalized');

% Electrode groups
UI.tabs.electrodeGroups = uitab(UI.channelGroups,'Title','Electrode groups');
UI.list.tableData = {false,'','',''};
UI.table.electrodeGroups = uitable(UI.tabs.electrodeGroups,'Data',UI.list.tableData,'Position',[0, 50, 620, 315],'ColumnWidth',{20 50 370 115},'columnname',{'','Group','Channels','Labels'},'RowName',[],'ColumnEditable',[true false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[10, 10, 75, 30],'String','Add group','Callback',@(src,evnt)addSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[95, 10, 75, 30],'String','Edit group','Callback',@(src,evnt)editSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[180, 10, 100, 30],'String','Delete group(s)','Callback',@(src,evnt)deleteSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[290, 10, 95, 30],'String','Verify group(s)','Callback',@(src,evnt)verifySpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[395, 10, 90, 30],'String','Sync groups','Callback',@(src,evnt)syncChannelGroups,'Units','normalized');
UI.button.importGroupsFromXML1 = uicontrol('Parent',UI.tabs.electrodeGroups,'Style','pushbutton','Position',[495, 10, 115, 30],'String','Import from xml','Callback',@(src,evnt)importGroupsFromXML,'Units','normalized');

% Spike groups
UI.tabs.spikeGroups = uitab(UI.channelGroups,'Title','Spike groups');
UI.list.tableData = {false,'','',''};
UI.table.spikeGroups = uitable(UI.tabs.spikeGroups,'Data',UI.list.tableData,'Position',[1, 50, 619, 315],'ColumnWidth',{20 50 370 115},'columnname',{'','Group','Channels','Labels'},'RowName',[],'ColumnEditable',[true false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[10, 10, 75, 30],'String','Add group','Callback',@(src,evnt)addSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[95, 10, 75, 30],'String','Edit group','Callback',@(src,evnt)editSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[180, 10, 100, 30],'String','Delete group(s)','Callback',@(src,evnt)deleteSpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[290, 10, 95, 30],'String','Verify group(s)','Callback',@(src,evnt)verifySpikeGroup,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[395, 10, 90, 30],'String','Sync groups','Callback',@(src,evnt)syncChannelGroups,'Units','normalized');
UI.button.importGroupsFromXML2 = uicontrol('Parent',UI.tabs.spikeGroups,'Style','pushbutton','Position',[495, 10, 115, 30],'String','Import from xml','Callback',@(src,evnt)importGroupsFromXML,'Units','normalized');

% Silicon probes from db
if isfield(session.extracellular,'electrodes')
    UI.tabs.spikeGroups = uitab(UI.channelGroups,'Title','Electrodes');
    UI.list.tableData = {false,'','','','','','',''};
    UI.table.electrodes = uitable(UI.tabs.spikeGroups,'Data',UI.list.tableData,'Position',[1, 1, 619, 364],'ColumnWidth',{20 200 120 70 60 80 60 60 80},'columnname',{'','Probes','Company','nChannels','nShanks','Brain region','AP (mm)','ML (mm)','Depth (mm)'},'RowName',[],'ColumnEditable',[true false false false false false false false],'Units','normalized');
end


% % % % % % % % % % % % % % % % % % % % %
% Spike sorting

tableData = {false,'','',''};
UI.table.spikeSorting = uitable(UI.tabs.spikeSorting,'Data',tableData,'Position',[1, 50, 619, 475],'ColumnWidth',{20 58 58 140 75 80 50 50 60},'columnname',{'','Method','Format','Relative path','Channels','Spike sorter','Notes','Metrics','Currated'},'RowName',[],'ColumnEditable',[true false false false false false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add sorting','Callback',@(src,evnt)addSpikeSorting,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[120, 10, 100, 30],'String','Edit sorting','Callback',@(src,evnt)editSpikeSorting,'Units','normalized');
uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[230, 10, 100, 30],'String','Delete sorting(s)','Callback',@(src,evnt)deleteSpikeSorting,'Units','normalized');
% uicontrol('Parent',UI.tabs.spikeSorting,'Style','pushbutton','Position',[330, 10, 160, 30],'String','Import sorting?','Callback',@(src,evnt)importBadChannelsFromXML,'Units','normalized');


% % % % % % % % % % % % % % % % % % % % %
% Brain regions

UI.list.tableData = {false,'','','',''};
UI.table.brainRegion = uitable(UI.tabs.brainRegions,'Data',UI.list.tableData,'Position',[1, 50, 619, 475],'ColumnWidth',{20 70 280 95 127},'columnname',{'','Region','Channels','Electrode groups','Notes'},'RowName',[],'ColumnEditable',[true false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add region','Callback',@(src,evnt)addRegion,'Units','normalized');
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[120, 10, 100, 30],'String','Edit region','Callback',@(src,evnt)editRegion,'Units','normalized');
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[230, 10, 110, 30],'String','Delete region(s)','Callback',@(src,evnt)deleteRegion,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Channel tags

tableData = {false,'','',''};
UI.table.tags = uitable(UI.tabs.channelTags,'Data',tableData,'Position',[1, 300, 619, 225],'ColumnWidth',{20 130 315 127},'columnname',{'','Channel tag','Channels','Electrode groups'},'RowName',[],'ColumnEditable',[true false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[10, 260, 100, 30],'String','Add channel tag','Callback',@(src,evnt)addTag,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[120, 260, 100, 30],'String','Edit channel tag','Callback',@(src,evnt)editTag,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[230, 260, 100, 30],'String','Delete tag(s)','Callback',@(src,evnt)deleteTag,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[470, 260, 140, 30],'String','Import bad channels','Callback',@(src,evnt)importBadChannelsFromXML,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Inputs

tableData = {false,'','',''};
UI.table.inputs = uitable(UI.tabs.inputs,'Data',tableData,'Position',[1, 300, 619, 225],'ColumnWidth',{20 120 75 70 120 187},'columnname',{'','Input tag','Channels','Type','Equipment','Description'},'RowName',[],'ColumnEditable',[true false false false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[10, 260, 100, 30],'String','Add input','Callback',@(src,evnt)addInput,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[120, 260, 100, 30],'String','Edit input','Callback',@(src,evnt)editInput,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[230, 260, 100, 30],'String','Delete input(s)','Callback',@(src,evnt)deleteInput,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% Time series

tableData = {false,'','',''};
UI.table.timeSeries = uitable(UI.tabs.inputs,'Data',tableData,'Position',[1, 50, 619, 200],'ColumnWidth',{20 90 85 60 70 40 60 90 78},'columnname',{'','Time series tag','File name', 'Precision', 'nChannels', 'sr', 'nSamples', 'summaryFiguresificant bit', 'Equipment'},'RowName',[],'ColumnEditable',[true false false false false false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add time serie','Callback',@(src,evnt)addTimeSeries,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[120, 10, 100, 30],'String','Edit time serie','Callback',@(src,evnt)editTimeSeries,'Units','normalized');
uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[230, 10, 110, 30],'String','Delete time serie(s)','Callback',@(src,evnt)deleteTimeSeries,'Units','normalized');
UI.button.importMetaFromIntan = uicontrol('Parent',UI.tabs.inputs,'Style','pushbutton','Position',[500, 10, 110, 30],'String','Import from Intan','Callback',@(src,evnt)importMetaFromIntan,'Units','normalized');

% % % % % % % % % % % % % % % % % % % % %
% BehavioralTracking

tableData = {false,'','',''};
UI.table.behaviors = uitable(UI.tabs.behaviors,'Data',tableData,'Position',[1, 50, 619, 475],'ColumnWidth',{20 160 100 50 80 75 107},'columnname',{'','Filenames','Equipment','Epoch','Type','Frame rate','Notes'},'RowName',[],'ColumnEditable',[true false false false false false false],'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add tracking','Callback',@(src,evnt)addBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[120, 10, 100, 30],'String','Edit tracking','Callback',@(src,evnt)editBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[230, 10, 100, 30],'String','Delete tracking(s)','Callback',@(src,evnt)deleteBehavior,'Units','normalized');
uicontrol('Parent',UI.tabs.behaviors,'Style','pushbutton','Position',[340, 10, 100, 30],'String','Duplicate tracking','Callback',@(src,evnt)duplicateBehavior,'Units','normalized');


% % % % % % % % % % % % % % % % % % % % %
% Analysis tags

tableData = {false,'','',''};
UI.table.analysis = uitable(UI.tabs.channelTags,'Data',tableData,'Position',[1, 50, 619, 200],'ColumnWidth',{20 250 322},'columnname',{'','Analysis tag','Value'},'RowName',[],'ColumnEditable',[true false false],'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[10, 10, 100, 30],'String','Add analysis tag','Callback',@(src,evnt)addAnalysis,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[120, 10, 100, 30],'String','Edit analysis tag','Callback',@(src,evnt)editAnalysis,'Units','normalized');
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[230, 10, 100, 30],'String','Delete tag(s)','Callback',@(src,evnt)deleteAnalysis,'Units','normalized');
% uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[340, 10, 110, 30],'String','Duplicate tag','Callback',@(src,evnt)duplicateAnalysis,'Units','normalized');

% Loading session struct into gui
loadSessionStruct
UI.fig.Visible = 'on';
uiLoaded = true;
uiwait(UI.fig)

%% % % % % % % % % % % % % % % % % % % % %
% Embedded functions 
% % % % % % % % % % % % % % % % % % % % %
    
    function importEpochsIntervalsFromMergePoints(~,~)
        % Epochs derived from MergePoints
        if exist(fullfile(UI.edit.basepath.String,[UI.edit.session.String,'.MergePoints.events.mat']),'file')
            UI.status.BackgroundColor = [1,0.6,0.0];
            UI.status.String = 'Uploading...';
            
            temp = load(fullfile(UI.edit.basepath.String,[UI.edit.session.String,'.MergePoints.events.mat']));
            for i = 1:size(temp.MergePoints.foldernames,2)
                session.epochs{i}.name = temp.MergePoints.foldernames{i};
                session.epochs{i}.startTime = temp.MergePoints.timestamps(i,1);
                session.epochs{i}.stopTime = temp.MergePoints.timestamps(i,2);
            end
            updateEpochsList
            UI.status.BackgroundColor = [0.3,0.7,0.3];
            UI.status.String = 'Epochs updated';
        else
            msgbox(['No ', UI.edit.session.String,'.MergePoints.events.mat',' exist in basepath'],'Error');
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
                    if exist(filepath1) || exist(filepath2)
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

    function openInWebDB(src,evnt)
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
        UI.status.BackgroundColor = [1,0.6,0.0];
        UI.status.String = 'Loading...';
        
        session = loadIntanMetadata(session);
        updateTimeSeriesList
        UI.status.BackgroundColor = [0.3,0.7,0.3];
        UI.status.String = 'Updated from intan';
    end
    
    function loadSessionStruct
        if exist('parameters','var')
            for iParams = 1:length(UI.list.params)
                UI.checkbox.params(iParams).Value = parameters.(UI.list.params{iParams});
            end
        end
        
        UI.edit.basepath.String = session.general.basePath;
        UI.edit.clusteringpath.String = session.general.clusteringPath;
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
            UI.edit.sessionType.Value = find(strcmp(session.general.sessionType,sessionTypesList));
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
        UIsetString(session.animal,'species');
        UIsetString(session.animal,'strain');
        UIsetString(session.animal,'geneticLine');
        UIsetString(session.extracellular,'nChannels');
        UIsetString(session.extracellular,'sr');
        UIsetString(session.extracellular,'nSamples');
        UIsetString(session.extracellular,'precision');
        UIsetString(session.extracellular,'leastSignificantBit');
        UIsetString(session.extracellular,'probeDepths');
        UIsetString(session.extracellular,'equipment');
        UIsetString(session.extracellular,'srLfp');
        updateChannelGroupsList
        if isfield(session.extracellular,'electrodes')
            updateElectrodeList
        end
        updateSpikeSortingList
        updateBrainRegionList
        updateTagList
        updateInputsList
        updateBehaviorsList
        updateAnalysisList
        updateTimeSeriesList
    end
    
    function buttonUpdateFromDB
        answer = questdlg('Are you sure you want to update the session struct from the database?', 'Update session from DB', 'Yes','Cancel','Cancel');
        % Handle response
        if strcmp(answer,'Yes')
            UI.status.BackgroundColor = [1,0.6,0.0];
            UI.status.String = 'Updating...';
            
            success = updateFromDB;
            if success
                UI.status.BackgroundColor = [0.3,0.7,0.3];
                UI.status.String = 'Updated from db';
            else
                errordlg('Database tools not available');
                UI.status.String = 'Update failed';
                UI.status.BackgroundColor = [1,0.6,0.0];
            end
        end
    end
    
    function buttonHelp
        web('https://petersenpeter.github.io/CellExplorer/tutorials/metadata-tutorial/','-new','-browser')
    end
    
    function buttonUploadToDB
        listing = fieldnames(session);
        [indx,tf] = listdlg('PromptString',['Select the data types to upload to the database'],'ListString',listing,'SelectionMode','multiple','ListSize',[300,220],'InitialValue',1,'Name','Upload session changes to DB');
        if ~isempty(indx)
            UI.status.BackgroundColor = [1,0.6,0.0];
            UI.status.String = 'Uploading...';
            
            readBackFields;
            try
                success = db_upload_session(session,'fields',listing(indx));
                if success
                    UI.status.BackgroundColor = [0.3,0.7,0.3];
                    UI.status.String = 'Upload complete';
                else
                    errordlg('Database tools not available');
                end
            catch
                UI.status.String = 'Failed upload';
                errordlg('Database tools not working properly');
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
                    loadSessionStruct
                end
                success = 1;
            end
            catch 
                errordlg('Database tools not working');
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
        BackgroundColor = UI.status.BackgroundColor;
        if ~strcmp(pwd,UI.edit.basepath.String)
            answer = questdlg('Base path is different from current path. Where would you like to save the session struct to','Location','basepath','current path','Select location','basepath');
        else
            answer = 'basepath';
        end
        switch answer
            case 'basepath'
                filepath1 = UI.edit.basepath.String;
                filename1 = [UI.edit.session.String,'.session.mat'];
            case 'current folder'
                filepath1 = pwd;
                filename1 = [UI.edit.session.String,'.session.mat'];
            case 'Select'
                [filename1,filepath1] = uiputfile([UI.edit.session.String,'.session.mat']);
            otherwise
                return
        end
        
        readBackFields;
        try
            save(fullfile(filepath1, filename1),'session','-v7.3','-nocompression');
            UI.status.BackgroundColor = [0.3,0.7,0.3];
            UI.status.String = 'File saved';
        catch
            msgbox(['Failed to save ',filename1,'. Location not available'],'Error','error');
            UI.status.String = 'Save failed';
        end
        
    end

    function UIsetString(StructName,StringName,StringName2)
        if isfield(StructName,StringName) & exist('StringName2')
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
    end
    
    function readBackFields
        % Saving parameters
        if exist('parameters','var')
            for iParams = 1:length(UI.list.params)
                parameters.(UI.list.params{iParams}) = UI.checkbox.params(iParams).Value;
            end
            if ~isempty(UI.listbox.includeMetrics.Value)
                parameters.metrics = UI.listbox.includeMetrics.String(UI.listbox.includeMetrics.Value);
            end
            if ~isempty(UI.listbox.excludeMetrics.Value)
                parameters.excludeMetrics = UI.listbox.excludeMetrics.String(UI.listbox.excludeMetrics.Value);
            end
        end
        session.general.date = UI.edit.date.String;
        session.general.time = UI.edit.time.String;
        session.general.name = UI.edit.session.String;
        session.general.basePath = UI.edit.basepath.String;
        session.general.clusteringPath = UI.edit.clusteringpath.String;
        session.general.duration = UI.edit.duration.String;
        session.general.location = UI.edit.location.String;
        session.general.experimenters = UI.edit.experimenters.String;
        session.general.notes = UI.edit.notes.String;
        session.general.sessionType = sessionTypesList{UI.edit.sessionType.Value};
        if ~isfield(session.general,'entryID') || isempty(session.general.entryID)
            session.general.investigator = UI.edit.investigator.String;
            session.general.repositories = UI.edit.repositories.String;
            session.general.projects = UI.edit.projects.String;
        end
        session.animal.name = UI.edit.name.String;
        session.animal.sex = UI.edit.sex.String{UI.edit.sex.Value};
        session.animal.species = UI.edit.species.String;
        session.animal.strain = UI.edit.strain.String;
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
        if ~strcmp(UI.edit.probeDepths.String,'') 
            session.extracellular.probeDepths = str2double(UI.edit.probeDepths.String);
        else
            session.extracellular.probeDepths = 0;
        end
        session.extracellular.precision = UI.edit.precision.String;
        session.extracellular.equipment = UI.edit.equipment.String;
    end
    
    function cancelMetricsWindow
        session = sessionIn;
        delete(UI.fig)
    end

    function updateBrainRegionList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'brainRegions') & ~isempty(session.brainRegions)
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
        if isfield(session,'channelTags') & ~isempty(session.channelTags)
            tagFieldnames = fieldnames(session.channelTags);
            for fn = 1:length(tagFieldnames)
                tableData{fn,1} = false;
                tableData{fn,2} = tagFieldnames{fn};
                if isfield(session.channelTags.(tagFieldnames{fn}),'channels')
                    tableData{fn,3} = num2str(session.channelTags.(tagFieldnames{fn}).channels);
                else
                    tableData{fn,3} = '';
                end
                if isfield(session.channelTags.(tagFieldnames{fn}),'electrodeGroups')
                    tableData{fn,4} = num2str(session.channelTags.(tagFieldnames{fn}).electrodeGroups);
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.tags.Data = tableData;
        else
            UI.table.tags.Data = {};
        end
    end

    function updateChannelGroupsList
        % Updates the list of electrode groups
        tableData = {};
        if isfield(session.extracellular,'electrodeGroups')
            if isnumeric(session.extracellular.electrodeGroups.channels)
                nTotal = size(session.extracellular.electrodeGroups.channels,1);
            elseif ~isempty(session.extracellular.electrodeGroups.channels) && ~isempty(session.extracellular.electrodeGroups.channels{1})
                nTotal = length(session.extracellular.electrodeGroups.channels);
            else
                nTotal = 0;
            end
            for fn = 1:nTotal
                tableData{fn,1} = false;
                tableData{fn,2} = [num2str(fn),' (',num2str(length(session.extracellular.electrodeGroups.channels{fn})),')'];
                tableData{fn,3} = num2str(session.extracellular.electrodeGroups.channels{fn});
                if isfield(session.extracellular.electrodeGroups,'label') & size(session.extracellular.electrodeGroups.label,2)>=fn
                    tableData{fn,4} = session.extracellular.electrodeGroups.label{fn};
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.electrodeGroups.Data = tableData;
        else
            UI.table.electrodeGroups.Data = {false,'','',''};
        end
        
        % Updates the list of spike groups
        tableData = {};
        if isfield(session.extracellular,'spikeGroups')
            if isnumeric(session.extracellular.spikeGroups.channels)
            	nTotal = size(session.extracellular.spikeGroups.channels,1);
            else
                nTotal = length(session.extracellular.spikeGroups.channels);
            end
            for fn = 1:nTotal
                tableData{fn,1} = false;
                tableData{fn,2} = [num2str(fn),' (',num2str(length(session.extracellular.spikeGroups.channels{fn})),')'];
                if isnumeric(session.extracellular.spikeGroups.channels)
                    tableData{fn,3} = num2str(session.extracellular.spikeGroups.channels(fn,:));
                else
                    tableData{fn,3} = num2str(session.extracellular.spikeGroups.channels{fn});
                end
                if isfield(session.extracellular.spikeGroups,'label') & size(session.extracellular.spikeGroups.label,2)>=fn
                    tableData{fn,4} = session.extracellular.spikeGroups.label{fn};
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.spikeGroups.Data = tableData;
        else
            UI.table.spikeGroups.Data = {false,'','',''};
        end
    end
    
    function updateElectrodeList
        % Updates the list of electrodes
        if isfield(session.extracellular,'electrodes')
            tableData = {};
            nTotal = length(session.extracellular.electrodes.nChannels);
            for fn = 1:nTotal
                tableData{fn,1} = false;
                tableData{fn,2} = session.extracellular.electrodes.siliconProbes{fn};
                tableData{fn,3} = session.extracellular.electrodes.company{fn};
                tableData{fn,4} = session.extracellular.electrodes.nChannels(fn);
                tableData{fn,5} = session.extracellular.electrodes.nShanks(fn);
                tableData{fn,6} = session.extracellular.electrodes.brainRegions{fn};
                if isfield(session.extracellular.electrodes,'AP_coordinates') && ~isempty(session.extracellular.electrodes.AP_coordinates)
                    tableData{fn,7} = session.extracellular.electrodes.AP_coordinates(fn);
                end
                if isfield(session.extracellular.electrodes,'ML_coordinates') && ~isempty(session.extracellular.electrodes.ML_coordinates)
                    tableData{fn,8} = session.extracellular.electrodes.ML_coordinates(fn);
                end
                if isfield(session.extracellular.electrodes,'depth') && ~isempty(session.extracellular.electrodes.depth)
                    tableData{fn,9} = session.extracellular.electrodes.depth(fn);
                end
            end
            UI.table.electrodes.Data = tableData;
        else
            UI.table.electrodes.Data = {false,'','','','','','','',''};
        end
        
    end
    function updateEpochsList
        % Updates the plot table from the spikesPlots structure
        if isfield(session,'epochs') & ~isempty(session.epochs)
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
        if isfield(session,'inputs') & ~isempty(session.inputs)
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
        if isfield(session,'behavioralTracking') & ~isempty(session.behavioralTracking)
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
        if isfield(session,'spikeSorting') & ~isempty(session.spikeSorting)
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
                    tableData{fn,8} = session.spikeSorting{fn}.cellMetrics;
                end
                if isfield(session.spikeSorting{fn},'manuallyCurated') && ~isempty(session.spikeSorting{fn}.manuallyCurated)
                    tableData{fn,9} = session.spikeSorting{fn}.manuallyCurated;
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
        if isfield(session,'analysisTags') & ~isempty(session.analysisTags)
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
        if isfield(session,'timeSeries') & ~isempty(session.timeSeries) & isstruct(session.timeSeries)
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
            errordlg(['Please select the region(s) to delete'],'Error')
        end
    end

    function addRegion(regionIn)
        % Add new brain region to session struct
        brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
        brainRegions_list = strcat(brainRegions(:,1),' (',brainRegions(:,2),')');
        brainRegions_acronym = brainRegions(:,2);
        if exist('regionIn')
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
        brainRegionsTextfield = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', '', 'Position', [10, 350, 600, 25],'Callback',@(src,evnt)filterBrainRegionsList,'HorizontalAlignment','left');
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
                            errordlg(['Channels not not formatted correctly'],'Error')
                            uicontrol(brainRegionsChannels);
                        end
                    end
                    if ~isempty(brainRegionsElectrodeGroups.String)
                        try
                            session.brainRegions.(SelectedBrainRegion).electrodeGroups = eval(['[',brainRegionsElectrodeGroups.String,']']);
                        catch
                            errordlg(['Spike groups not formatted correctly'],'Error')
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
        % Selected region is parsed to the spikePlotsDlg, for edits,
        % saved the output to the spikesPlots structure and updates the
        % table
        if ~isempty(UI.table.brainRegion.Data) && ~isempty(find([UI.table.brainRegion.Data{:,1}])) && sum([UI.table.brainRegion.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.brainRegions);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.brainRegion.Data{:,1}])};
            addRegion(fieldtoedit)
        else
            errordlg(['Please select the region to edit'],'Error')
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
            errordlg(['Please select the channel tag(s) to delete'],'Error')
        end
    end

    function addTag(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            InitTag = regionIn;
            if isfield(session.channelTags.(regionIn),'channels')
                initChannels = num2str(session.channelTags.(regionIn).channels);
            else
                initChannels = '';
            end
            if isfield(session.channelTags.(regionIn),'electrodeGroups')
                initElectrodeGroups = num2str(session.channelTags.(regionIn).electrodeGroups);
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
                       errordlg(['Channels not not formatted correctly'],'Error')
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
                        errordlg(['Spike groups not formatted correctly'],'Error')
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
            errordlg(['Please select the channel tag to edit'],'Error')
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
            errordlg(['Please select the input(s) to delete'],'Error')
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
        inputsType = uicontrol('Parent',UI.dialog.inputs,'Style', 'popup', 'String', inputsTypeList , 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
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
                        errordlg(['Channels not not formatted correctly'],'Error')
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
            errordlg(['Please select the input to edit'],'Error')
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
            errordlg(['Please select the epoch(s) to move'],'Error')
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
            errordlg(['Please select the epoch(s) to move'],'Error')
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
            errordlg(['Please select the epoch(s) to delete'],'Error')
        end
    end

    function addEpoch(epochIn)
        % Add new epoch to session struct
        if exist('epochIn','var')
            InitEpoch = epochIn;
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
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Start time', 'Position', [10, 123, 230, 20],'HorizontalAlignment','left');
        epochsStartTime = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initStartTime, 'Position', [10, 100, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Stop time', 'Position', [250, 123, 240, 20],'HorizontalAlignment','left');
        epochsStopTime = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initStopTime, 'Position', [250, 100, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style', 'text', 'String', 'Notes', 'Position', [10, 73, 440, 20],'HorizontalAlignment','left');
        epochsNotes = uicontrol('Parent',UI.dialog.epochs,'Style', 'Edit', 'String', initNotes, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.epochs,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save epoch','Callback',@(src,evnt)CloseEpochs_dialog);
        uicontrol('Parent',UI.dialog.epochs,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelEpochs_dialog);
        
        uicontrol(epochsName);
        uiwait(UI.dialog.epochs);
        
        function CloseEpochs_dialog
            if ~strcmp(epochsName.String,'') isvarname(epochsName.String)
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
            errordlg(['Please select the epoch to edit'],'Error')
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
            errordlg(['Please select the epoch to duplicate'],'Error')
        end
    end

%% % Behavior

    function deleteBehavior
        % Deletes any selected Behaviors
        if ~isempty(UI.table.behaviors.Data) && ~isempty(find([UI.table.behaviors.Data{:,1}], 1))
            session.behavioralTracking(find([UI.table.behaviors.Data{:,1}])) = [];
            updateBehaviorsList
        else
            errordlg(['Please select the behavior(s) to delete'],'Error')
        end
    end

    function addBehavior(behaviorIn)
        % Add new behavior to session struct
        if exist('behaviorIn','var')
            InitBehavior = behaviorIn;
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
            if ~strcmp(behaviorsFileNames.String,'') isvarname(behaviorsFileNames.String)
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
            errordlg(['Please select the behavior to edit'],'Error')
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
            errordlg(['Please select the tracking to duplicate'],'Error')
        end
    end

%% % Spike sorting

    function deleteSpikeSorting
        % Deletes any selected SpikeSorting
        if ~isempty(UI.table.spikeSorting.Data) && ~isempty(find([UI.table.spikeSorting.Data{:,1}], 1))
            session.spikeSorting(find([UI.table.spikeSorting.Data{:,1}])) = [];
            updateSpikeSortingList
        else
            errordlg(['Please select the sorting(s) to delete'],'Error')
        end
    end

    function addSpikeSorting(behaviorIn)
        % Add new behavior to session struct
        if exist('behaviorIn','var')
            InitBehavior = behaviorIn;
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
        spikeSortingMethod = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'popup', 'String', sortingMethodList, 'Position', [10, 175, 230, 25],'HorizontalAlignment','left');
        UIsetValue(spikeSortingMethod,InitMethod)
        
        uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'text', 'String', 'Sorting format', 'Position', [250, 198, 240, 20],'HorizontalAlignment','left');
        spikeSortinFormat = uicontrol('Parent',UI.dialog.spikeSorting,'Style', 'popup', 'String', sortingFormatList, 'Position', [250, 175, 240, 25],'HorizontalAlignment','left');
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
                errordlg(['Please format the relative path correctly'],'Error')
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
            errordlg(['Please select the sorting to edit'],'Error')
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
            errordlg(['Please select the analysis tag(s) to delete'],'Error')
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
                       errordlg(['Values not not formatted correctly'],'Error')
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
            errordlg(['Please select the analysis tag to edit'],'Error')
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
            errordlg(['Please select the time series(s) to delete'],'Error')
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
        timeSeriesType = uicontrol('Parent',UI.dialog.timeSeries,'Style', 'popup', 'String', inputsTypeList, 'Position', [250, 200, 240, 25],'HorizontalAlignment','left');
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
                errordlg(['Please provide a filename'],'Error')
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
            errordlg(['Please select the time series to edit'],'Error')
        end
    end

%% Extracellular spike groups

    function deleteSpikeGroup
        % Deletes any selected tags
        if ~isempty(UI.table.spikeGroups.Data) && ~isempty(find([UI.table.spikeGroups.Data{:,1}], 1))
            session.extracellular.spikeGroups.channels([UI.table.spikeGroups.Data{:,1}]) = [];
            session.extracellular.nSpikeGroups = size(session.extracellular.spikeGroups.channels,2);
            updateChannelGroupsList
        else
            errordlg(['Please select the spike group(s) to delete'],'Error')
        end
    end
    
    function addSpikeGroup(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            initSpikeGroups = num2str(regionIn);
            if isnumeric(session.extracellular.spikeGroups.channels)
                initChannels = num2str(session.extracellular.spikeGroups.channels(regionIn,:));
            else
                initChannels = num2str(session.extracellular.spikeGroups.channels{regionIn});
            end
            if isfield(session.extracellular.spikeGroups,'label') & size(session.extracellular.spikeGroups.label,2)>=regionIn & ~isempty(session.extracellular.spikeGroups.label{regionIn})
                initLabel = session.extracellular.spikeGroups.label{regionIn};
            else
                initLabel = '';
            end
        else
            initSpikeGroups = num2str(size(session.extracellular.spikeGroups.channels,2)+1);
            initChannels = '';
            initLabel = '';
        end
        
        % Opens dialog
        UI.dialog.spikeGroups = dialog('Position', [300, 300, 500, 200],'Name','Spike group','WindowStyle','modal'); movegui(UI.dialog.spikeGroups,'center')
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', ['Spike group (nSpikeGroups = ',num2str(session.extracellular.nSpikeGroups),')'], 'Position', [10, 173, 480, 20],'HorizontalAlignment','left');
        spikeGroupsSpikeGroups = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initSpikeGroups, 'Position', [10, 150, 480, 25],'HorizontalAlignment','left','enable', 'off');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', ['Channels (nChannels = ',num2str(session.extracellular.nChannels),')'], 'Position', [10, 123, 480, 20],'HorizontalAlignment','left');
        spikeGroupsChannels = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initChannels, 'Position', [10, 100, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', 'Label', 'Position', [10, 73, 480, 20],'HorizontalAlignment','left');
        spikeGroupsLabel = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initLabel, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save spike group','Callback',@(src,evnt)CloseSpikeGroups_dialog);
        uicontrol('Parent',UI.dialog.spikeGroups,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikeGroups_dialog);
        
        uicontrol(spikeGroupsChannels);
        uiwait(UI.dialog.spikeGroups);
        
        function CloseSpikeGroups_dialog
            spikeGroup = str2double(spikeGroupsSpikeGroups.String);
            if ~isempty(spikeGroupsChannels.String)
                try
                    session.extracellular.spikeGroups.channels{spikeGroup} = eval(['[',spikeGroupsChannels.String,']']);
                catch
                    errordlg(['Channels not not formatted correctly'],'Error')
                    uicontrol(spikeGroupsChannels);
                    return
                end
            end
            session.extracellular.spikeGroups.label{spikeGroup} = spikeGroupsLabel.String;
            delete(UI.dialog.spikeGroups);
            session.extracellular.nSpikeGroups = size(session.extracellular.spikeGroups,2);
            updateChannelGroupsList;
        end
        function CancelSpikeGroups_dialog
            delete(UI.dialog.spikeGroups);
        end
    end

    function editSpikeGroup
        % Selected spike group is parsed to the addSpikeGroup dialog for edits
        if ~isempty(UI.table.spikeGroups.Data) && ~isempty(find([UI.table.spikeGroups.Data{:,1}], 1)) && sum([UI.table.spikeGroups.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.spikeGroups.Data{:,1}]);
            addSpikeGroup(fieldtoedit)
        else
            errordlg(['Please select the spike group to edit'],'Error')
        end
    end

    function verifySpikeGroup(~,~)
        if isfield(session.extracellular,'electrodeGroups')
            if isnumeric(session.extracellular.electrodeGroups.channels)
                channels = session.extracellular.electrodeGroups.channels(:);
            else
                channels = [session.extracellular.electrodeGroups.channels{:}];
            end
            uniqueChannels = length(unique(channels));
            nChannels = length(channels);
            if nChannels ~= session.extracellular.nChannels
                errordlg(['Channel count in electrode groups (', num2str(nChannels), ') does not corresponds to nChannels (',num2str(session.extracellular.nChannels),')'],'Error')
            elseif uniqueChannels ~= session.extracellular.nChannels
                errordlg('The unique channel count does not corresponds to nChannels','Error')
            elseif any(sort(channels) ~= [1:session.extracellular.nChannels])
                errordlg('Channels are not ranging from 1 : nChannels','Error')
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
            UI.status.BackgroundColor = [1,0.6,0.0];
            UI.status.String = 'Importing...';
            
            session = import_xml2session(xml_filepath,session);
            updateChannelGroupsList
            UIsetString(session.extracellular,'sr'); % Sampling rate of dat file
            UIsetString(session.extracellular,'srLfp'); % Sampling rate of lfp file
            UIsetString(session.extracellular,'nChannels'); % Number of channels
            UI.status.BackgroundColor = [0.3,0.7,0.3];
            UI.status.String = 'XML imported';
        else
            errordlg(['xml file not accessible: ' xml_filepath],'Error')
        end
    end
    
    function syncChannelGroups
        answer = questdlg('How do you want to sync the channel groups?','Sync channel groups','electrode groups -> spike groups', 'spike groups -> electrode groups','Cancel','electrode groups -> spike groups');
        if strcmp(answer,'electrode groups -> spike groups') && isfield(session.extracellular,'electrodeGroups')
            session.extracellular.spikeGroups = session.extracellular.electrodeGroups;
        elseif strcmp(answer,'spike groups -> electrode groups') && isfield(session.extracellular,'spikeGroups')
            session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
        end
        updateChannelGroupsList
    end

    function importBadChannelsFromXML
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
            errordlg(['xml file not accessible: ' xml_filepath],'Error')
        end
    end

end