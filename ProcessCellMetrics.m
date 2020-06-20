function cell_metrics = ProcessCellMetrics(varargin)
%   This function calculates cell metrics for a given recording/session
%   Most metrics are single value per cell, either numeric or string type, but
%   certain metrics are vectors like the autocorrelograms or cell with double content like waveforms.
%   The metrics are based on a number of features: spikes, waveforms, PCA features,
%   the ACG and CCGs, LFP, theta, ripples and so fourth
%
%   Check the website of the CellExplorer for more details: https://petersenpeter.github.io/CellExplorer/
%
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%   INPUTS
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
%   varargin (Variable-length input argument list; see below)
%
%   - Parameters defining the session to process - 
%   basepath               - 1. Path to session (base directory)
%   sessionName            - 3. Database sessionName
%   sessionID              - 4. Database numeric id
%   session                - 5. Session struct. Must contain a basepath
%
%   - Parameters for the processing - parameters.*
%   showGUI                - Show GUI dialog to adjust settings/parameters
%   metrics                - Metrics that will be calculated. A cell with strings
%                            Examples: 'waveform_metrics','PCA_features','acg_metrics','deepSuperficial',
%                            ,'monoSynaptic_connections','theta_metrics','spatial_metrics',
%                            'event_metrics','manipulation_metrics', 'state_metrics'
%                            ,'psth_metrics'.
%                            Default: 'all'
%   excludeMetrics         - Metrics to exclude. Default: 'none'
%   removeMetrics          - Metrics to remove (supports only deepSuperficial at this point)
%   keepCellClassification - logical. Keep existing cell type classifications
%   includeInhibitoryConnections - logical. Determines if inhibitory connections are included in the detection of synaptic connections
%   manualAdjustMonoSyn    - logical. Manually verify monosynaptic connections in the pipeline (requires user input)
%   restrictToIntervals    - time intervals to restrict the analysis to (in seconds)
%   excludeIntervals       - time intervals to exclude (in seconds)
%   excludeManipulationIntervals - logical. Exclude time intervals around manipulations (loads *.manipulation.mat files and excludes defined manipulation intervals)
%   ignoreEventTypes       - exclude .events files of specific types
%   ignoreManipulationTypes- exclude .manipulations files of specific types
%   ignoreStateTypes       - exclude .states files of specific types
%   showGUI                - logical. Show a GUI that allows you to adjust the input parameters/settings
%   forceReload            - logical. Recalculate existing metrics
%   submitToDatabase       - logical. Submit cell metrics to database
%   saveMat                - logical. Save metrics to cell_metrics.mat
%   saveAs                 - name of .mat file
%   saveBackup             - logical. Whether a backup file should be created
%   summaryFigures         - logical. Plot summary figures
%   debugMode              - logical. Activate a debug mode avoiding try/catch 
%   transferFilesFromClusterpath - logical. Moves previosly generated files from clusteringpath to basepath (new file structure)
%
% - Example calls:
% cell_metrics = ProcessCellMetrics                             % Load from current path, assumed to be a basepath
% cell_metrics = ProcessCellMetrics('session',session)          % Load session from session struct
% cell_metrics = ProcessCellMetrics('basepath',basepath)        % Load from basepath
% cell_metrics = ProcessCellMetrics('sessionName','rec1')       % Load session from database session name
% cell_metrics = ProcessCellMetrics('sessionID',10985)          % Load session from database session id
%
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%   OUTPUT
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
%   Cell_metrics : structure described in details at: https://petersenpeter.github.io/CellExplorer/datastructure/standard-cell-metrics/

%   By Peter Petersen
%   petersen.peter@gmail.com
%   Last edited: 16-03-2020


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Parsing parameters
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

p = inputParser;
addParameter(p,'sessionID',[],@isnumeric);
addParameter(p,'sessionName',[],@isstr);
addParameter(p,'session',[],@isstruct);
addParameter(p,'spikes',[],@isstruct);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'metrics','all',@iscellstr);
addParameter(p,'excludeMetrics',{'none'},@iscellstr);
addParameter(p,'removeMetrics',{'none'},@isstr);
addParameter(p,'restrictToIntervals',[],@isnumeric);
addParameter(p,'excludeIntervals',[],@isnumeric);
addParameter(p,'ignoreEventTypes',{'MergePoints'},@iscell);
addParameter(p,'ignoreManipulationTypes',{'cooling'},@iscell);
addParameter(p,'ignoreStateTypes',{'StateToIgnore'},@iscell);
addParameter(p,'excludeManipulationIntervals',true,@islogical);
addParameter(p,'metricsToExcludeManipulationIntervals',{'waveform_metrics','PCA_features','acg_metrics','monoSynaptic_connections','theta_metrics','spatial_metrics','event_metrics','psth_metrics'},@iscell); % 'other_metrics'

addParameter(p,'keepCellClassification',true,@islogical);
addParameter(p,'manualAdjustMonoSyn',true,@islogical);
addParameter(p,'includeInhibitoryConnections',false,@islogical);
addParameter(p,'showGUI',false,@islogical);
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'submitToDatabase',true,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','cell_metrics',@isstr);
addParameter(p,'saveBackup',true,@islogical);
addParameter(p,'summaryFigures',false,@islogical);
addParameter(p,'debugMode',false,@islogical);
addParameter(p,'transferFilesFromClusterpath',true,@islogical);

parse(p,varargin{:})

sessionID = p.Results.sessionID;
sessionin = p.Results.sessionName;
sessionStruct = p.Results.session;
basepath = p.Results.basepath;
parameters = p.Results;
timerCalcMetrics = tic;


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading session metadata from DB or sessionStruct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ~isempty(sessionID)
    [session, basename, basepath] = db_set_session('sessionId',sessionID);
elseif ~isempty(sessionin)
    [session, basename, basepath] = db_set_session('sessionName',sessionin);
elseif ~isempty(sessionStruct)
    if isfield(sessionStruct.general,'basePath')
        session = sessionStruct;
        basename = session.general.name;
        basepath = session.general.basePath;
    else
        [session, basename, basepath] = db_set_session('session',sessionStruct);
        if isempty(session.general.entryID)
            session.general.entryID = ''; % DB id
        end
        if isempty(session.spikeSorting{1}.entryID)
            session.spikeSorting{1}.entryID = ''; % DB id
        end
    end
end

% If no session struct is provided it will look for a basename.session.mat file in the basepath and otherwise load the sessionTemplate and show the GUI gui_session
if ~exist('session','var')
    [~,basename,~] = fileparts(basepath);
    if exist(fullfile(basepath,[basename,'.session.mat']),'file')
        dispLog(['Loading ',basename,'.session.mat from basepath']);
        load(fullfile(basepath,[basename,'.session.mat']),'session');
        session.general.basePath = basepath;
    elseif exist(fullfile(basepath,'session.mat'),'file')
        dispLog('Loading session.mat from basepath');
        load(fullfile(basepath,'session.mat'),'session');
        session.general.basePath = basepath;
    else
        cd(basepath)
        session = sessionTemplate(basepath);
        parameters.showGUI = true;
    end
end

% If no arguments are given, the GUI is shown
if nargin==0
    parameters.showGUI = true;
end

% Checking format of spike groups and electrode groups (must be of type cell)
if isfield(session.extracellular,'spikeGroups') && isfield(session.extracellular.spikeGroups,'channels') && isnumeric(session.extracellular.spikeGroups.channels)
    session.extracellular.spikeGroups.channels = num2cell(session.extracellular.spikeGroups.channels,2);
end
if isfield(session.extracellular,'electrodeGroups') && isfield(session.extracellular.electrodeGroups,'channels') && isnumeric(session.extracellular.electrodeGroups.channels)
    session.extracellular.electrodeGroups.channels = num2cell(session.extracellular.electrodeGroups.channels,2)';
end
% Non-standard parameters: probeSpacing and probeLayout
if ~isfield(session,'analysisTags') || (~isfield(session.analysisTags,'probesVerticalSpacing') && ~isfield(session.analysisTags,'probesLayout')) && isfield(session.extracellular,'electrodes') && isfield(session.extracellular.electrodes,'siliconProbes')
    session = determineProbeSpacing(session);
    if ~isfield(session.analysisTags,'probesVerticalSpacing')
        session.analysisTags.probesVerticalSpacing = 10;
        disp('  Using default probesVerticalSpacing = 10')
    end
    if ~isfield(session.analysisTags,'probesLayout')
        session.analysisTags.probesLayout = 'poly2';
        disp('  Using default probesLayout = poly2')
    end
end

if ~isfield(session,'extracellular') || ~isfield(session.extracellular,'electrodeGroups')  || ~isfield(session.extracellular.electrodeGroups,'channels') || isempty([session.extracellular.electrodeGroups.channels{:}])
    if isfield(session.extracellular,'spikeGroups')
        warning('No electrode group has been defined. Copied from spike groups')
        session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
        session.extracellular.nElectrodeGroups = session.extracellular.nSpikeGroups;
    end
end
if any([session.extracellular.electrodeGroups.channels{:}]==0)
    error('session.extracellular.electrodeGroups.channels contains 0. Must be 1-indexed')
elseif any([session.extracellular.spikeGroups.channels{:}]==0)
    error('session.extracellular.spikeGroups.channels contains 0. Must be 1-indexed')
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% showGUI
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if parameters.showGUI
    dispLog('Showing GUI for adjusting parameters and session meta data')
    session.general.basePath = basepath;
    [session,parameters,status] = gui_session(session,parameters);
    if status==0
        disp('  Metrics calculations canceled by user')
        return
    end
    basename = session.general.name;
    basepath = session.general.basePath;
    cd(basepath)
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Moving files generated by CellExplorer (basename.*.mat) from relative spike sorting path (clusteringpath) to the basepath
% Previous version of CellExplorer would save cell_metrics and cellinfo derived files in the clusteringpath
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if parameters.transferFilesFromClusterpath && ~isempty(session.spikeSorting{1}.relativePath)
    fileList = dir(fullfile(basepath,session.spikeSorting{1}.relativePath,[basename, '.*.mat']));
    fileListClusterpath = {fileList.name};
    fileList = dir(fullfile(basepath,[basename, '.*.mat']));
    fileListBasepath = {fileList.name};
    [fileListToMove,~] = setdiff(fileListClusterpath,fileListBasepath);
    if numel(fileListToMove)>0
        disp('Moving files from cluster folder to basepath')
        for i = 1:numel(fileListToMove)
            disp([num2str(i) ,'. transfer: ', fileListToMove{i}]);
            movefile(fullfile(basepath,session.spikeSorting{1}.relativePath,fileListToMove{i}),fullfile(basepath,fileListToMove{i}));
        end
        disp(['File transfer complete (', num2str(numel(fileListToMove)),' files)'])
    end
    DuplicatedfileList = fileListClusterpath(ismember(fileListClusterpath,fileListBasepath));
    if ~isempty(DuplicatedfileList)
        warning(['Files existing in both directories are not transferred. Please verify these files should not be transferred: ' DuplicatedfileList{:}])
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Getting spikes  -  excluding user specified- and manipulation intervals
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

sr = session.extracellular.sr;
if ~isempty(parameters.spikes)
    dispLog('Using spikes provided as input')
    spikes{1} = parameters.spikes;
    parameters.spikes = [];
else
    dispLog('Getting spikes')
    spikes{1} = loadSpikes('session',session);
end
if ~isfield(spikes{1},'processinginfo') || ~isfield(spikes{1}.processinginfo.params,'WaveformsSource') || ~strcmp(spikes{1}.processinginfo.params.WaveformsSource,'dat file') || spikes{1}.processinginfo.version<3.5
    spikes{1} = loadSpikes('forceReload',true,'spikes',spikes{1},'session',session);
end
if ~isfield(spikes{1},'total')
    spikes{1}.total = cellfun(@(X) length(X),spikes{1}.times);
end
if ~isempty(parameters.restrictToIntervals)
    if size(parameters.restrictToIntervals,2) ~= 2
        error('restrictToIntervals has to be a Nx2 matrix')
    else
        dispLog('Restricting analysis to provided intervals')
        
        spikes_indices = cellfun(@(X) ce_InIntervals(X,double(parameters.restrictToIntervals)),spikes{1}.times,'UniformOutput',false);
        spikes{1}.times = cellfun(@(X,Y) X(Y),spikes{1}.times,spikes_indices,'UniformOutput',false);
        if isfield(spikes{1},'ts')
            spikes{1}.ts = cellfun(@(X,Y) X(Y),spikes{1}.ts,spikes_indices,'UniformOutput',false);
        end
        if isfield(spikes{1},'ids')
            spikes{1}.ids = cellfun(@(X,Y) X(Y),spikes{1}.ids,spikes_indices,'UniformOutput',false);
        end
        if isfield(spikes{1},'amplitudes')
            spikes{1}.amplitudes = cellfun(@(X,Y) X(Y),spikes{1}.amplitudes,spikes_indices,'UniformOutput',false);
        end
        
        % Removing empty units from structure
        unitsToRemove = find(cellfun(@isempty,spikes{1}.times));
        fieldsToProcess = fieldnames(spikes{1});
        fieldsToProcess = fieldsToProcess(structfun(@(X) (isnumeric(X) || iscell(X)) && numel(X)==numel(spikes{1}.times),spikes{1}));
        for iField = 1:numel(fieldsToProcess)
            spikes{1}.(fieldsToProcess{iField})(unitsToRemove) = [];
        end
        spikes{1}.total = cell2mat(cellfun(@(X,Y) length(X),spikes{1}.times,'UniformOutput',false));
        spikes{1}.numcells = numel(spikes{1}.times);
        spikes{1}.spindices = generateSpinDices(spikes{1}.times);
    end
end

if parameters.excludeManipulationIntervals
    dispLog('Excluding manipulation events')
    manipulationFiles = dir(fullfile(basepath,[basename,'.*.manipulation.mat']));
    manipulationFiles = {manipulationFiles.name};
    manipulationFiles(find(contains(manipulationFiles,parameters.ignoreManipulationTypes)))=[];
    if ~isempty(manipulationFiles)
        for iEvents = 1:length(manipulationFiles)
            eventName = strsplit(manipulationFiles{iEvents},'.'); 
            eventName = eventName{end-2};
            eventOut = load(manipulationFiles{iEvents});
            if size(eventOut.(eventName).timestamps,2) == 2
                disp(['  Excluding manipulation type: ' eventName])
                parameters.excludeIntervals = [parameters.excludeIntervals;eventOut.(eventName).timestamps];
            else
                warning('manipulation timestamps has to be a Nx2 matrix')
            end
        end
    else
         disp('  No manipulation events excluded')
    end
end

if ~isempty(parameters.excludeIntervals)
    % Checks if intervals are formatted correctly
    if size(parameters.excludeIntervals,2) ~= 2
        error('excludeIntervals has to be a Nx2 matrix')
    else
        disp(['  Excluding ',num2str(size(parameters.excludeIntervals,1)),' intervals in spikes (' num2str(sum(diff(parameters.excludeIntervals'))),' seconds)'])
        spikes{2} = spikes{1};
        spikes_indices = cellfun(@(X) ~ce_InIntervals(X,double(parameters.excludeIntervals)),spikes{1}.times,'UniformOutput',false);
        spikes{2}.times = cellfun(@(X,Y) X(Y),spikes{1}.times,spikes_indices,'UniformOutput',false);
        if isfield(spikes{1},'ts')
            spikes{2}.ts = cellfun(@(X,Y) X(Y),spikes{1}.ts,spikes_indices,'UniformOutput',false);
        end
        if isfield(spikes{1},'ids')
            spikes{2}.ids = cellfun(@(X,Y) X(Y),spikes{1}.ids,spikes_indices,'UniformOutput',false);
        end
        if isfield(spikes{1},'amplitudes')
            spikes{2}.amplitudes = cellfun(@(X,Y) X(Y),spikes{1}.amplitudes,spikes_indices,'UniformOutput',false);
        end
        spikes{2}.total = cell2mat(cellfun(@(X,Y) length(X),spikes{2}.times,'UniformOutput',false));
        spikes{2}.spindices = generateSpinDices(spikes{2}.times);
    end
else
    disp('  No intervals excluded')
    parameters.metricsToExcludeManipulationIntervals = {'none'};
    
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Initializing cell_metrics struct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

saveAsFullfile = fullfile(basepath,[basename,'.',parameters.saveAs,'.cellinfo.mat']);

if exist(saveAsFullfile,'file')
    dispLog(['Loading existing metrics: ' saveAsFullfile])
    load(saveAsFullfile)
elseif exist(fullfile(basepath,[parameters.saveAs,'.mat']),'file')
    % For legacy naming convention
    warning(['Loading existing legacy metrics: ' parameters.saveAs])
    load(fullfile(basepath,[parameters.saveAs,'.mat']))
else
    cell_metrics = [];
end

if parameters.saveBackup && ~isempty(cell_metrics)
    % Creating backup of existing user adjustable metrics
    backupDirectory = 'revisions_cell_metrics';
    dispLog(['Creating backup of existing user adjustable metrics ''',backupDirectory,'''']);
    
    backupFields = {'labels','tags','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType','groundTruthClassification','groups'};
    temp = {};
    for i = 1:length(backupFields)
        if isfield(cell_metrics,backupFields{i})
            temp.cell_metrics.(backupFields{i}) = cell_metrics.(backupFields{i});
        end
    end
    try
        if ~(exist(fullfile(basepath,backupDirectory),'dir'))
            mkdir(fullfile(basepath,backupDirectory));
        end
        save(fullfile(basepath, backupDirectory, [parameters.saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat',]),'cell_metrics','-v7.3','-nocompression', '-struct', 'temp')
    catch
        warning('Failed to save backup data in the CellExplorer pipeline')
    end
end

cell_metrics.general.basepath = basepath;
cell_metrics.general.basename = basename;
cell_metrics.general.cellCount = numel(spikes{1}.times);

% Saving spike times to metrics
cell_metrics.spikes.times = spikes{1}.times;

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Waveform based calculations
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'waveform_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'waveform_metrics'}))
    spkExclu = setSpkExclu('waveform_metrics',parameters);
    if ~all(isfield(cell_metrics,{'waveforms','peakVoltage','troughToPeak','troughtoPeakDerivative','ab_ratio'})) || ~all(isfield(cell_metrics.waveforms,{'raw','filt','filt_all','raw_all'})) || parameters.forceReload == true
        dispLog('Getting waveforms');
        field2copy = {'filtWaveform_std','rawWaveform','rawWaveform_std','rawWaveform_all','filtWaveform_all','timeWaveform_all','peakVoltage_all','channels_all','filtWaveform','timeWaveform'};
        field2copyNewNames = {'filt_std','raw','raw_std','raw_all','filt_all','time_all','peakVoltage_all','channels_all','filt','time'};
        if spkExclu==2 || any(~isfield(spikes{spkExclu},field2copy)) || ~isempty(parameters.restrictToIntervals) || parameters.forceReload == true
            spikes{spkExclu} = getAllWaveformsFromDat(spikes{spkExclu},session);
        end
        cell_metrics.peakVoltage = spikes{spkExclu}.peakVoltage;
        cell_metrics.peakVoltage_expFitLengthConstant = spikes{spkExclu}.peakVoltage_expFitLengthConstant;
        for j = 1:numel(field2copy)
            if isfield(spikes{spkExclu},field2copy{j})
                cell_metrics.waveforms.(field2copyNewNames{j}) =  spikes{spkExclu}.(field2copy{j});
            end
        end

        for j = 1:cell_metrics.general.cellCount
            if numel(spikes{spkExclu}.maxWaveform_all)>=j && ~isempty(spikes{spkExclu}.maxWaveform_all{j})
                nChannelFit = min([16,length(spikes{spkExclu}.maxWaveform_all{j}),length(session.extracellular.electrodeGroups.channels{spikes{spkExclu}.shankID(j)})]);
                cell_metrics.waveforms.bestChannels{j} = spikes{spkExclu}.maxWaveform_all{j}(1:nChannelFit);
            else
                cell_metrics.waveforms.bestChannels{j} = [];
            end
            
        end
        
        dispLog('Calculating waveform metrics');
        waveform_metrics = calc_waveform_metrics(spikes{spkExclu},sr);
        cell_metrics.troughToPeak = waveform_metrics.troughtoPeak;
        cell_metrics.troughtoPeakDerivative = waveform_metrics.derivative_TroughtoPeak;
        cell_metrics.ab_ratio = waveform_metrics.ab_ratio;
        cell_metrics.polarity = waveform_metrics.polarity;
        
        % Removing outdated fields
        field2remove = {'derivative_TroughtoPeak','filtWaveform','filtWaveform_std','rawWaveform','rawWaveform_std','timeWaveform'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
    end
    
    % Channel coordinates map, trilateration and length constant determined from waveforms across channels
    if ~all(isfield(cell_metrics,{'trilat_x','trilat_y','peakVoltage_expFit'})) || parameters.forceReload == true
        if ~isfield(session.extracellular,'chanCoords')
            if exist(fullfile(basepath,'chanMap.mat'),'file') % Will look for a chanMap file with default name (compatible with KiloSort)
                chanMap = load(fullfile(basepath,'chanMap.mat'));
            elseif isfield(session,'analysisTags') && isfield(session.analysisTags,'chanMapFile')
                % You can use a different filename that must be specified in: session.analysisTags.chanMapFile
                chanMap = load(fullfile(basepath,session.analysisTags.chanMapFile));
            else
                if ~isfield(session,'analysisTags') || ~isfield(session.analysisTags,'probesLayout')
                    disp('  Using default probesLayout: poly2')
                    session.analysisTags.probesLayout = 'poly2';
                end
                disp('  Creating channelmap')
                chanMap = createChannelMap(session);
            end
            session.extracellular.chanCoords.x = chanMap.xcoords(:);
            session.extracellular.chanCoords.y = chanMap.ycoords(:);
        end
        cell_metrics.general.chanCoords = session.extracellular.chanCoords;
       
        % Fit exponential
        fit_eqn = fittype('a*exp(-x/b)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c'});
        
        expential_x = {};
        expential_y = {};
        for j = 1:cell_metrics.general.cellCount
            if ~isnan(cell_metrics.peakVoltage(j))
                % Trilateration
                [~,idx] = sort(cell_metrics.waveforms.peakVoltage_all{j},'descend');
                bestChannels = cell_metrics.waveforms.channels_all{j}(idx(1:16));
                beta0 = [cell_metrics.general.chanCoords.x(bestChannels(1)),cell_metrics.general.chanCoords.y(bestChannels(1))]; % initial position
                trilat_pos = trilat([cell_metrics.general.chanCoords.x(bestChannels),cell_metrics.general.chanCoords.y(bestChannels)],cell_metrics.waveforms.peakVoltage_all{j}(idx(1:16)),beta0,0); % ,1,cell_metrics.waveforms.filt_all{j}(bestChannels,:)
                cell_metrics.trilat_x(j) = trilat_pos(1);
                cell_metrics.trilat_y(j) = trilat_pos(2);
                
                % Length constant
                x1 = cell_metrics.general.chanCoords.x;
                y1 = cell_metrics.general.chanCoords.y;
                u = cell_metrics.trilat_x(j);
                v = cell_metrics.trilat_y(j);
                [channel_distance,idx2] = sort(hypot((x1(:)-u),(y1(:)-v)));
                
                nChannelFit = min([16,length(session.extracellular.electrodeGroups.channels{spikes{spkExclu}.shankID(j)})]);
                x = 1:nChannelFit;
                y = cell_metrics.waveforms.peakVoltage_all{j}(idx(x));
                x2 = channel_distance(1:nChannelFit)';
                expential_x{j} = x2;
                expential_y{j} = y;
                f0 = fit(x2',y',fit_eqn,'StartPoint',[cell_metrics.peakVoltage(j), 30, 5],'Lower',[1, 0.001, 0],'Upper',[5000, 200, 1000]);
                fitCoeffValues = coeffvalues(f0);
                cell_metrics.peakVoltage_expFit(j) = fitCoeffValues(2);
            else
                cell_metrics.trilat_x(j) = nan;
                cell_metrics.trilat_y(j) = nan;
                cell_metrics.peakVoltage_expFit(j) = nan;
                expential_x{j} = [];
                expential_y{j} = [];
            end
        end
        fig1 = figure('Name', 'Length constant and Trilateration','NumberTitle', 'off','position',[100,100,1000,800]);
        subplot(2,2,1), hold on
        for j = 1:cell_metrics.general.cellCount
            plot(expential_x{j},expential_y{j})
        end
        title('Spike amplitude (all)'), xlabel('Distance (µm)'), ylabel('µV')
        subplot(2,2,2), hold off,
        histogram(cell_metrics.peakVoltage_expFit,20), xlabel('Length constant (µm)')
        subplot(2,2,3), hold on
        plot(cell_metrics.peakVoltage,cell_metrics.peakVoltage_expFit,'ok')
        ylabel('Length constant (µm)'), xlabel('Peak voltage (µV)')
        subplot(2,2,4), hold on
        plot(cell_metrics.general.chanCoords.x,cell_metrics.general.chanCoords.y,'.k'), hold on
        plot(cell_metrics.trilat_x,cell_metrics.trilat_y,'ob'), xlabel('x position (µm)'), ylabel('y position (µm)')
        
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% PCA features based calculations: Isolation distance and L-ratio
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% if any(contains(parameters.metrics,{'PCA_features','all'})) && ~any(contains(parameters.excludeMetrics,{'PCA_features'}))
%     spkExclu = setSpkExclu('PCA_features',parameters);
%     dispLog('PCA classifications: Isolation distance, L-Ratio')
%     if ~all(isfield(cell_metrics,{'isolationDistance66','lRatio'})) || parameters.forceReload == true
%         if strcmp(session.spikeSorting{1}.method,{'Neurosuite','KlustaKwik'})
%             disp('Getting PCA features for KlustaKwik')
%             PCA_features = LoadNeurosuiteFeatures(spikes,session,parameters.excludeIntervals); %(session.spikeSorting{1}.relativePath,basename,sr,parameters.excludeIntervals);
%             for j = 1:cell_metrics.general.cellCount
%                 cell_metrics.isolationDistance(j) = PCA_features.isolationDistance(find(PCA_features.UID == spikes{spkExclu}.UID(j)));
%                 cell_metrics.lRatio(j) = PCA_features.lRatio(find(PCA_features.UID == spikes{spkExclu}.UID(j)));
%             end
%         elseif strcmp(session.spikeSorting{1}.method,{'KiloSort'})
%             disp('Getting masked PCA features for KiloSort')
%             [clusterIDs, unitQuality, contaminationRate] = sqKilosort.maskedClusterQuality(basepath);
%             cell_metrics.unitQuality = nan(1,spikes{spkExclu}.numcells);
%             cell_metrics.contaminationRate = nan(1,spikes{spkExclu}.numcells);
%             for i = 1:spikes{spkExclu}.numcells
%                 if any(cell_metrics.cluID(i) == clusterIDs)
%                     idx = find(cell_metrics.cluID(i) == clusterIDs)
%                     cell_metrics.unitQuality(i) = unitQuality(idx);
%                     cell_metrics.contaminationRate(i) = contaminationRate(idx);
%                 end
%             end
%             keyboard
%         elseif strcmp(session.spikeSorting{1}.method,{'MaskedKlustakwik','klusta'})
%             disp('Getting masked PCA features for MaskedKlustakwik')
%             [clusterIDs, unitQuality, contaminationRate] = sqKwik.maskedClusterQuality(basepath);
%             keyboard
% %             getPCAfeatures(session)
% %             disp('  No PCAs available')
%         end
%     end
% end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% ACG & CCG based classification
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'acg_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'acg_metrics'}))
    spkExclu = setSpkExclu('acg_metrics',parameters);
    if isfield(cell_metrics, 'acg') && isnumeric(cell_metrics.acg)
        field2remove = {'acg','acg2'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
    end
    if ~all(isfield(cell_metrics,{'acg','thetaModulationIndex','burstIndex_Royer2012','burstIndex_Doublets','acg_tau_decay','acg_tau_rise'})) || parameters.forceReload == true
        dispLog('ACG classifications: ThetaModulationIndex, BurstIndex_Royer2012, BurstIndex_Doublets')
        acg_metrics = calc_ACG_metrics(spikes{spkExclu});
        
        cell_metrics.acg.wide = acg_metrics.acg_wide; % Wide: 1000ms wide CCG with 1ms bins
        cell_metrics.acg.narrow = acg_metrics.acg_narrow; % Narrow: 100ms wide CCG with 0.5ms bins
        cell_metrics.thetaModulationIndex = acg_metrics.thetaModulationIndex; % cell_tmi
        cell_metrics.burstIndex_Royer2012 = acg_metrics.burstIndex_Royer2012; % cell_burstRoyer2012
        cell_metrics.burstIndex_Doublets = acg_metrics.burstIndex_Doublets;
        
        dispLog('Fitting triple exponential to ACG')
        fit_params = fit_ACG(acg_metrics.acg_narrow);
        cell_metrics.acg_tau_decay = fit_params.acg_tau_decay;
        cell_metrics.acg_tau_rise = fit_params.acg_tau_rise;
        cell_metrics.acg_c = fit_params.acg_c;
        cell_metrics.acg_d = fit_params.acg_d;
        cell_metrics.acg_asymptote = fit_params.acg_asymptote;
        cell_metrics.acg_refrac = fit_params.acg_refrac;
        cell_metrics.acg_fit_rsquare = fit_params.acg_fit_rsquare;
        cell_metrics.acg_tau_burst = fit_params.acg_tau_burst;
        cell_metrics.acg_h = fit_params.acg_h;
    end
    if ~all(isfield(cell_metrics,{'acg'}))  || ~isfield(cell_metrics.acg,{'log10'})  || parameters.forceReload == true
        dispLog('Calculating log10 ACGs')
         acg = calc_logACGs(spikes{spkExclu});
         cell_metrics.acg.log10 = acg.log10;
         cell_metrics.general.acgs.log10 = acg.log10_bins;
    end
    if ~all(isfield(cell_metrics,{'isi'}))  || ~isfield(cell_metrics.isi,{'log10'})  || parameters.forceReload == true
        dispLog('Calculating log10 ISIs')
        isi = calc_logISIs(spikes{spkExclu});
        cell_metrics.isi.log10 = isi.log10;
        cell_metrics.general.isis.log10 = isi.log10_bins;
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Deep-Superficial by ripple polarity reversal
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'deepSuperficial','all'})) && ~any(contains(parameters.excludeMetrics,{'deepSuperficial'}))
    spkExclu = setSpkExclu('deepSuperficial',parameters);
    if (~exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file')) && isfield(session,'channelTags') && isfield(session.channelTags,'Ripple') && isnumeric(session.channelTags.Ripple.channels)
        dispLog('Finding ripples')
        if ~exist(fullfile(session.general.basePath,[session.general.name, '.lfp']),'file')
            disp('Creating lfp file')
            ce_LFPfromDat(session)
        end
        if isfield(session.channelTags,'RippleNoise')
            disp('  Using RippleNoise reference channel')
            RippleNoiseChannel = double(LoadBinary([basename, '.lfp'],'nChannels',session.extracellular.nChannels,'channels',session.channelTags.RippleNoise.channels,'precision','int16','frequency',session.extracellular.srLfp)); % 0.000050354 *
            ripples = bz_FindRipples(basepath,session.channelTags.Ripple.channels-1,'durations',[50 150],'passband',[120 180],'noise',RippleNoiseChannel);
        else
            ripples = bz_FindRipples(basepath,session.channelTags.Ripple.channels-1,'durations',[50 150]);
        end
    end

    deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
    if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file') && (~all(isfield(cell_metrics,{'deepSuperficial','deepSuperficialDistance'})) || parameters.forceReload == true)
        dispLog('Deep-Superficial by ripple polarity reversal')
        if ~exist(deepSuperficial_file,'file')
            if ~isfield(session.analysisTags,'probesVerticalSpacing') && ~isfield(session.analysisTags,'probesLayout')
                session = determineProbeSpacing(session);
            end
            classification_DeepSuperficial(session);
        end
        load(deepSuperficial_file)
        cell_metrics.general.SWR = deepSuperficialfromRipple;
        deepSuperficial_ChDistance = deepSuperficialfromRipple.channelDistance; %
        deepSuperficial_ChClass = deepSuperficialfromRipple.channelClass;% cell_deep_superficial
        cell_metrics.general.deepSuperficial_file = deepSuperficial_file;
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.deepSuperficial(j) = deepSuperficial_ChClass(spikes{spkExclu}.maxWaveformCh1(j)); % cell_deep_superficial OK
            cell_metrics.deepSuperficialDistance(j) = deepSuperficial_ChDistance(spikes{spkExclu}.maxWaveformCh1(j)); % cell_deep_superficial_distance
        end
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Pytative MonoSynaptic connections
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'monoSynaptic_connections','all'})) && ~any(contains(parameters.excludeMetrics,{'monoSynaptic_connections'}))
    spkExclu = setSpkExclu('monoSynaptic_connections',parameters);
    dispLog('MonoSynaptic connections')
    if ~exist(fullfile(basepath,[basename,'.mono_res.cellinfo.mat']),'file')
        mono_res = ce_MonoSynConvClick(spikes{spkExclu},'includeInhibitoryConnections',parameters.includeInhibitoryConnections);
        if parameters.manualAdjustMonoSyn
            dispLog('Loading MonoSynaptic GUI for manual adjustment')
            mono_res = gui_MonoSyn(mono_res);
        end
        save(fullfile(basepath,[basename,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
    else
        disp('  Loading previous detected MonoSynaptic connections')
        load(fullfile(basepath,[basename,'.mono_res.cellinfo.mat']),'mono_res');
        if parameters.forceReload == true && parameters.manualAdjustMonoSyn
            mono_res = gui_MonoSyn(mono_res);
            save(fullfile(basepath,[basename,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
        end
    end
    
    field2remove = {'putativeConnections'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    if ~isempty(mono_res.sig_con)
        if isfield(mono_res,'sig_con_excitatory')
            cell_metrics.putativeConnections.excitatory = mono_res.sig_con_excitatory; % Vectors with cell pairs
        else
            cell_metrics.putativeConnections.excitatory = mono_res.sig_con; % Vectors with cell pairs
        end
        if isfield(mono_res,'sig_con_inhibitory')
            cell_metrics.putativeConnections.inhibitory = mono_res.sig_con_inhibitory;
        else
            cell_metrics.putativeConnections.inhibitory = [];
        end 
        cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_metrics.general.cellCount);
        cell_metrics.synapticEffect(cell_metrics.putativeConnections.excitatory(:,1)) = repmat({'Excitatory'},1,size(cell_metrics.putativeConnections.excitatory,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
        if ~isempty(cell_metrics.putativeConnections.inhibitory)
            cell_metrics.synapticEffect(cell_metrics.putativeConnections.inhibitory(:,1)) = repmat({'Inhibitory'},1,size(cell_metrics.putativeConnections.inhibitory,1));
        end
        cell_metrics.synapticConnectionsOut = zeros(1,cell_metrics.general.cellCount);
        cell_metrics.synapticConnectionsIn = zeros(1,cell_metrics.general.cellCount);

        [a,b]=hist(cell_metrics.putativeConnections.excitatory(:,1),unique(cell_metrics.putativeConnections.excitatory(:,1)));
        cell_metrics.synapticConnectionsOut(b) = a; 
        cell_metrics.synapticConnectionsOut = cell_metrics.synapticConnectionsOut(1:cell_metrics.general.cellCount);
        [a,b]=hist(cell_metrics.putativeConnections.excitatory(:,2),unique(cell_metrics.putativeConnections.excitatory(:,2)));
        cell_metrics.synapticConnectionsIn(b) = a; 
        cell_metrics.synapticConnectionsIn = cell_metrics.synapticConnectionsIn(1:cell_metrics.general.cellCount);
        
        % Connection strength
        disp('  Determining MonoSynaptic connection strengths (transmission probabilities)')
        ccg2 = mono_res.ccgR;
        ccg2(isnan(ccg2)) =  0;
        % Excitatory connections
        for i = 1:size(cell_metrics.putativeConnections.excitatory,1)
            [trans,prob,prob_uncor,pred] = ce_GetTransProb(ccg2(:,cell_metrics.putativeConnections.excitatory(i,1),cell_metrics.putativeConnections.excitatory(i,2)),  spikes{spkExclu}.total(cell_metrics.putativeConnections.excitatory(i,1)),  mono_res.binSize,  0.020);
            cell_metrics.putativeConnections.excitatoryTransProb(i) = trans;
        end
        % Inhibitory connections
        for i = 1:size(cell_metrics.putativeConnections.inhibitory,1)
            [trans,prob,prob_uncor,pred] = ce_GetTransProb(ccg2(:,cell_metrics.putativeConnections.inhibitory(i,1),cell_metrics.putativeConnections.inhibitory(i,2)),  spikes{spkExclu}.total(cell_metrics.putativeConnections.inhibitory(i,1)),  mono_res.binSize,  0.020);
            cell_metrics.putativeConnections.inhibitoryTransProb(i) = trans;
        end
    else
        cell_metrics.putativeConnections.excitatory = [];
        cell_metrics.putativeConnections.inhibitory = [];
        cell_metrics.synapticConnectionsOut = zeros(1,cell_metrics.general.cellCount);
        cell_metrics.synapticConnectionsIn = zeros(1,cell_metrics.general.cellCount);
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Theta related activity
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'theta_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'theta_metrics'})) && exist(fullfile(basepath,[basename,'.animal.behavior.mat']),'file') && isfield(session.channelTags,'Theta') %&& (~isfield(cell_metrics,'thetaEntrainment') || parameters.forceReload == true)
    spkExclu = setSpkExclu('theta_metrics',parameters);
    dispLog('Theta metrics');
    InstantaneousTheta = calcInstantaneousTheta2(session);
    load(fullfile(basepath,[basename,'.animal.behavior.mat']));
    theta_bins =[-1:0.05:1]*pi;
    cell_metrics.thetaPhasePeak = nan(1,cell_metrics.general.cellCount);
    cell_metrics.thetaPhaseTrough = nan(1,cell_metrics.general.cellCount);
    % cell_metrics.responseCurves.thetaPhase = nan(length(theta_bins)-1,cell_metrics.general.cellCount);
    cell_metrics.thetaEntrainment = nan(1,cell_metrics.general.cellCount);
    
    spikes2 = spikes{spkExclu};
    
    if isfield(cell_metrics,'thetaPhaseResponse')
        cell_metrics = rmfield(cell_metrics,'thetaPhaseResponse');
    end
    
    for j = 1:size(spikes{spkExclu}.times,2)
        spikes2.ts{j} = spikes2.ts{j}(spikes{spkExclu}.times{j} < length(InstantaneousTheta.signal_phase{session.channelTags.Theta.channels})/session.extracellular.srLfp);
        spikes2.times{j} = spikes2.times{j}(spikes{spkExclu}.times{j} < length(InstantaneousTheta.signal_phase{session.channelTags.Theta.channels})/session.extracellular.srLfp);
        spikes2.ts_eeg{j} = ceil(spikes2.ts{j}/16);
        spikes2.theta_phase{j} = InstantaneousTheta.signal_phase{session.channelTags.Theta.channels}(spikes2.ts_eeg{j});
        spikes2.speed{j} = interp1(animal.time,animal.speed,spikes2.times{j});
        if sum(spikes2.speed{j} > 10)> 500
            
            [counts,centers] = histcounts(spikes2.theta_phase{j}(spikes2.speed{j} > 10),theta_bins, 'Normalization', 'probability');
            counts = nanconv(counts,[1,1,1,1,1]/5,'edge');
            [~,tem2] = max(counts);
            [~,tem3] = min(counts);
            cell_metrics.responseCurves.thetaPhase{j} = counts(:);
            cell_metrics.thetaPhasePeak(j) = centers(tem2)+diff(centers([1,2]))/2;
            cell_metrics.thetaPhaseTrough(j) = centers(tem3)+diff(centers([1,2]))/2;
            cell_metrics.thetaEntrainment(j) = max(counts)/min(counts);
        else
            cell_metrics.responseCurves.thetaPhase{j} = nan(length(theta_bins)-1,1);
        end
    end
    cell_metrics.general.responseCurves.thetaPhase.x_bins = theta_bins(1:end-1)+diff(theta_bins([1,2]))/2;
    
    figure, subplot(2,2,1)
    plot(cell_metrics.general.responseCurves.thetaPhase.x_bins,horzcat(cell_metrics.responseCurves.thetaPhase{:})),title('Theta entrainment during locomotion'), xlim([-1,1]*pi)
    subplot(2,2,2)
    plot(cell_metrics.thetaPhaseTrough,cell_metrics.thetaPhasePeak,'o'),xlabel('Trough'),ylabel('Peak')
    subplot(2,2,3)
    histogram(cell_metrics.thetaEntrainment,30),title('Theta entrainment')
    subplot(2,2,4)
    histogram(cell_metrics.thetaPhaseTrough,[-1:0.2:1]*pi),title('Theta trough and peak'), hold on
    histogram(cell_metrics.thetaPhasePeak,[-1:0.2:1]*pi), legend({'Trough','Peak'})
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Spatial related metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'spatial_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'spatial_metrics'}))
    spkExclu = setSpkExclu('spatial_metrics',parameters);
    dispLog('Spatial metrics');
    field2remove = {'firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMaps','firingRateMap','firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap','FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));

    % General firing rate map
    if exist(fullfile(basepath,[basename,'.firingRateMap.firingRateMap.mat']),'file')
        
        temp2 = load(fullfile(basepath,[basename,'.firingRateMap.firingRateMap.mat']));
        disp('  Loaded firingRateMap.mat succesfully');
        if isfield(temp2,'firingRateMap')
            firingRateMap = temp2.firingRateMap;
            if cell_metrics.general.cellCount == length(firingRateMap.total)
                cell_metrics.firingRateMaps.firingRateMap = firingRateMap.map;
                
                if isfield(firingRateMap,'x_bins')
                    cell_metrics.general.firingRateMaps.firingRateMap.x_bins = firingRateMap.x_bins;
                end
                if isfield(firingRateMap,'boundaries')
                    cell_metrics.general.firingRateMaps.firingRateMap.boundaries = firingRateMap.boundaries;
                end
                
                cell_metrics.general.firingRateMaps.firingRateMap.x_bins = firingRateMap.x_bins;
                cell_metrics.general.firingRateMaps.firingRateMap.boundaries = firingRateMap.boundaries;
                
                for j = 1:cell_metrics.general.cellCount
                    cell_metrics.spatialPeakRate(j) = max(firingRateMap.map{j});
                    temp = place_cell_condition(firingRateMap.map{j});
                    cell_metrics.spatialCoherence(j) = temp.SpatialCoherence;
                    cell_metrics.placeCell(j) = temp.condition;
                    cell_metrics.placeFieldsCount(j) = temp.placefield_count;
                    temp3 = cumsum(sort(firingRateMap.map{j},'descend'));
                    if ~all(temp3==0)
                        cell_metrics.spatialCoverageIndex(j) = find(temp3>0.75*temp3(end),1)/(length(temp3)*0.75); % Spatial coverage index (Royer, NN 2012)
                        cum_firing1 = cumsum(sort(firingRateMap.map{j}));
                        cum_firing1 = cum_firing1/max(cum_firing1);
                        cell_metrics.spatialGiniCoeff(j) = 1-2*sum(cum_firing1)./length(cum_firing1);
                    else
                        cell_metrics.spatialCoverageIndex(j) = nan;
                        cell_metrics.spatialGiniCoeff(j) = nan;
                    end
                end
                disp('  Spatial metrics succesfully calculated');
            else
                warning(['Number of cells firing rate maps (', num2str(size(firingRateMap.map,2)),  ') does not corresponds to the number of cells in spikes structure (', num2str(numel(spikes{spkExclu}.times)) ,')' ])
            end
        end
        
    else
        disp('  No *.firingRateMap.firingRateMap.mat file found');
    end
    
    % State dependent firing rate maps
    % e.g. basename.LeftRightRateMap.firingRateMap.mat
    firingRateMap_filelist = dir(fullfile(basepath,[basename,'.*.firingRateMap.mat'])); 
    firingRateMap_filelist = {firingRateMap_filelist.name};
    
    for i = 1:length(firingRateMap_filelist)
        
        temp2 = load(fullfile(basepath,firingRateMap_filelist{i}));
        firingRateMapName = strsplit(firingRateMap_filelist{i},'.'); 
        firingRateMapName = firingRateMapName{end-2};
%         firingRateMapName = firingRateMap_filelist{i}(1:end-4);
        firingRateMap = temp2.(firingRateMapName);
        if cell_metrics.general.cellCount == size(firingRateMap.map,2) && length(firingRateMap.x_bins) == size(firingRateMap.map{1},1)
            disp(['  Loaded ' firingRateMapName ' succesfully']);
            cell_metrics.firingRateMaps.(firingRateMapName) = firingRateMap.map;
            if isfield(firingRateMap,'x_bins')
                cell_metrics.general.firingRateMaps.(firingRateMapName).x_bins = firingRateMap.x_bins;
            end
            if isfield(firingRateMap,'x_label')
                cell_metrics.general.firingRateMaps.(firingRateMapName).x_label = firingRateMap.x_label;
            end
            if isfield(firingRateMap,'boundaries')
                cell_metrics.general.firingRateMaps.(firingRateMapName).boundaries = firingRateMap.boundaries;
            end
            if isfield(firingRateMap,'labels')
                cell_metrics.general.firingRateMaps.(firingRateMapName).labels = firingRateMap.labels;
            end
            if isfield(firingRateMap,'boundaries_labels')
                cell_metrics.general.firingRateMaps.(firingRateMapName).boundaries_labels = firingRateMap.boundaries_labels;
            end
        end
    end
    
    if isfield(cell_metrics,'firingRateMaps') && isfield(cell_metrics.firingRateMaps,'LeftRightRateMap')
        if isfield(firingRateMap,'splitter_bins')
            splitter_bins = firingRateMap.splitter_bins;
            cell_metrics.general.firingRateMaps.(firingRateMapName).splitter_bins = firingRateMap.splitter_bins;
        else
            splitter_bins = find( cell_metrics.general.firingRateMaps.(firingRateMapName).x_bins < cell_metrics.general.firingRateMaps.(firingRateMapName).boundaries(1) );
            cell_metrics.general.firingRateMaps.(firingRateMapName).splitter_bins = splitter_bins;
        end
        splitter_bins = find( cell_metrics.general.firingRateMaps.(firingRateMapName).x_bins < cell_metrics.general.firingRateMaps.(firingRateMapName).boundaries(1) );
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.spatialSplitterDegree(j) = sum(abs(cell_metrics.firingRateMaps.(firingRateMapName){1}(splitter_bins,j,1) - cell_metrics.firingRateMaps.(firingRateMapName){1}(splitter_bins,j,2)))/sum(cell_metrics.firingRateMaps.(firingRateMapName){1}(splitter_bins,j,1) + cell_metrics.firingRateMaps.(firingRateMapName){1}(splitter_bins,j,2) + length(splitter_bins));
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Event metrics
% 
% eventName.timestamps
% eventName.data
%
% E.g. ripple events
% 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'event_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'event_metrics'}))
    spkExclu = setSpkExclu('event_metrics',parameters);
    field2remove = {'rippleCorrelogram','events','rippleModulationIndex','ripplePeakDelay'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    dispLog('Event metrics')
    eventFiles = dir(fullfile(basepath,[basename,'.*.events.mat']));
    eventFiles = {eventFiles.name};
    eventFiles(find(contains(eventFiles,parameters.ignoreEventTypes)))=[];
    
    if ~isempty(eventFiles)
        for i = 1:length(eventFiles)
            eventName = strsplit(eventFiles{i},'.');
            eventName = eventName{end-2};
            eventOut = load(eventFiles{i});
            disp(['  Importing ' eventName]);
            if strcmp(fieldnames(eventOut),eventName)
                if strcmp(eventName,'ripples') && isfield(eventOut.(eventName),'timestamps') && isnumeric(eventOut.(eventName).peaks) && length(eventOut.(eventName).peaks)>0
                    PSTH = calc_PSTH(eventOut.ripples,spikes{spkExclu},'alignment','peaks','duration',0.150,'binCount',150,'smoothing',5,'eventName',eventName);
                    if size(PSTH.responsecurve,2) == cell_metrics.general.cellCount
                        cell_metrics.events.ripples = num2cell(PSTH.responsecurve,1);
                        cell_metrics.general.events.(eventName).event_file = eventFiles{i};
                        cell_metrics.general.events.(eventName).x_bins = PSTH.time*1000;
                        cell_metrics.general.events.(eventName).x_label = 'Time (ms)';
                        cell_metrics.general.events.(eventName).alignment = PSTH.alignment;
                        
                        cell_metrics.([eventName,'_modulationIndex']) = PSTH.modulationIndex;
                        cell_metrics.([eventName,'_modulationPeakResponseTime']) = PSTH.modulationPeakResponseTime;
                        cell_metrics.([eventName,'_modulationSignificanceLevel']) = PSTH.modulationSignificanceLevel;
                    end
                elseif isfield(eventOut.(eventName),'timestamps') && isnumeric(eventOut.(eventName).timestamps) && length(eventOut.(eventName).timestamps)>0
                    PSTH = calc_PSTH(eventOut.(eventName),spikes{spkExclu},'alignment','onset','smoothing',5,'eventName',eventName);
                    if size(PSTH.responsecurve,2) == cell_metrics.general.cellCount
                        cell_metrics.events.(eventName) = num2cell(PSTH.responsecurve,1);
                        cell_metrics.general.events.(eventName).event_file = eventFiles{i};
                        cell_metrics.general.events.(eventName).x_bins = PSTH.time*1000;
                        cell_metrics.general.events.(eventName).x_label = 'Time (ms)';
                        cell_metrics.general.events.(eventName).alignment = PSTH.alignment;
                        
                        cell_metrics.([eventName,'_modulationIndex']) = PSTH.modulationIndex;
                        cell_metrics.([eventName,'_modulationPeakResponseTime']) = PSTH.modulationPeakResponseTime;
                        cell_metrics.([eventName,'_modulationSignificanceLevel']) = PSTH.modulationSignificanceLevel;
                    end
                end
            end
        end
    else

    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Manipulation metrics
% 
% manipulationName.timestamps
% manipulationName.data
% manipulationName.processingInfo
%
% E.g. optogenetical stimulation events
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'manipulation_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'manipulation_metrics'}))
    spkExclu = setSpkExclu('manipulation_metrics',parameters);
    dispLog('Manipulation metrics');
    field2remove = {'manipulations'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    manipulationFiles = dir(fullfile(basepath,[basename,'.*.manipulation.mat']));
    manipulationFiles = {manipulationFiles.name};
    manipulationFiles(find(contains(manipulationFiles,parameters.ignoreManipulationTypes)))=[];
    if ~isempty(manipulationFiles)
        for iEvents = 1:length(manipulationFiles)
            eventName = strsplit(manipulationFiles{iEvents},'.'); eventName = eventName{end-2};
            eventOut = load(manipulationFiles{iEvents});
            disp(['  Importing ' eventName]);
            PSTH = calc_PSTH(eventOut.(eventName),spikes{spkExclu},'alignment','onset','smoothing',5,'eventName',eventName);
            cell_metrics.manipulations.(eventName) = num2cell(PSTH.responsecurve,1);
            cell_metrics.general.manipulations.(eventName).event_file = manipulationFiles{iEvents};
            cell_metrics.general.manipulations.(eventName).x_bins = PSTH.time*1000;
            cell_metrics.general.manipulations.(eventName).x_label = 'Time (ms)';
            cell_metrics.general.manipulations.(eventName).alignment = PSTH.alignment;
            
            cell_metrics.([eventName,'_modulationIndex']) = PSTH.modulationIndex;
            cell_metrics.([eventName,'_modulationPeakResponseTime']) = PSTH.modulationPeakResponseTime;
            cell_metrics.([eventName,'_modulationSignificanceLevel']) = PSTH.modulationSignificanceLevel;

%             [PSTH,PSTH_time] = calc_PSTH(eventOut.(eventName),spikes{spkExclu},'smoothing',10);
%             eventFieldName = ['manipulation_',eventName];
%             cell_metrics.manipulations.(eventName) = num2cell(PSTH,1);
%             cell_metrics.general.manipulations.(eventName).event_file = manipulationFiles{iEvents};
%             cell_metrics.general.manipulations.(eventName).x_bins = PSTH_time*1000;
%             cell_metrics.general.manipulations.(eventName).x_label = 'Time (ms)';
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% States metrics
% 
% stateName.timestamps
% stateName.data
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'state_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'state_metrics'}))
    spkExclu = setSpkExclu('state_metrics',parameters);
    dispLog('State metrics');
    statesFiles = dir(fullfile(basepath,[basename,'.*.states.mat']));
    statesFiles = {statesFiles.name};
    statesFiles(find(contains(statesFiles,parameters.ignoreStateTypes)))=[];
    
    if ~isempty(statesFiles)
    %Calculate ISI and CV2 for allspikes
    allspikes.ISIs = cellfun(@diff,spikes{spkExclu}.times,'UniformOutput',false);
    allspikes.meanISI = cellfun(@(X) (X(1:end-1)+X(2:end))./2,allspikes.ISIs,'UniformOutput',false);
    allspikes.CV2 = cellfun(@(X) 2.*abs(X(2:end)-X(1:end-1))./(X(2:end)+X(1:end-1)),allspikes.ISIs ,'UniformOutput',false);
    %Make sure times line up
    allspikes.times = cellfun(@(X) X(2:end-1),spikes{spkExclu}.times,'UniformOutput',false);
    allspikes.ISIs_bursts = cellfun(@(X) any([X(1:end-1), X(2:end)] < 0.006,2),allspikes.ISIs,'UniformOutput',false);
    allspikes.ISIs = cellfun(@(X) X(1:end-1),allspikes.ISIs,'UniformOutput',false);
    
        for iEvents = 1:length(statesFiles)
            statesName = strsplit(statesFiles{iEvents},'.'); statesName = statesName{end-2};
            eventOut = load(statesFiles{iEvents});
            disp(['  Importing ' statesName]);
            eventOut = load(statesFiles{iEvents});
            if isfield(eventOut.(statesName),'ints')
                states = eventOut.(statesName).ints;
                cell_metrics.general.states.(statesName) = states;
                statenames =  fieldnames(states);
                for iStates = 1:numel(statenames)
                    %Find which spikes are during state of interest
                    statespikes = cellfun(@(X) ce_InIntervals(X,double(states.(statenames{iStates}))),allspikes.times,'UniformOutput',false);
                    
                    % firing rate in state (nSpikes/duration)
                    cell_metrics.(['firingRate_' statenames{iStates}]) = cellfun(@(X) sum(X),statespikes) / sum(diff(states.(statenames{iStates})'));
                    
                    % firing rate in state derived from ISIs (1/median(ISIs))
                    ISIs = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.ISIs,statespikes,'Uniformoutput',false);
                    cell_metrics.(['firingRateISI_' statenames{iStates}]) = 1./cellfun(@(X) median(X),ISIs);
                    
                    % CV2 during state
                    CV2 = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.CV2,statespikes,'Uniformoutput',false);
                    cell_metrics.(['cv2_' statenames{iStates}]) = cellfun(@(X) mean(X(X<1.95)),CV2);
                    
                    % Burstiness_Mizuseki2011
                    ISIs_bursts = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.ISIs_bursts,statespikes,'Uniformoutput',false);
                    cell_metrics.(['burstIndex_' statenames{iStates}]) = cellfun(@(X) sum(X)/length(X),ISIs_bursts);
                end
            end
            % States specific calculations
            % isi distribution?
        end
    end
end

% Cleaning state specific metrics misnamed:
metricsNames = fieldnames(cell_metrics);
cell_metrics = rmfield(cell_metrics,metricsNames(contains(metricsNames,{'firingRatesISI_','firingRates_'})));


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% PSTH metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(parameters.metrics,{'psth_metrics','all'})) && ~any(contains(parameters.excludeMetrics,{'psth_metrics'}))
    spkExclu = setSpkExclu('psth_metrics',parameters);
    dispLog('Perturbation metrics');
    % PSTH response
    psth_filelist = dir(fullfile(basepath,[basename,'.*.psth.mat']));
    psth_filelist = {psth_filelist.name};
    
    for i = 1:length(psth_filelist)
        temp2 = load(fullfile(basepath,psth_filelist{i}));
        psth_type = psth_filelist{i}(1:end-4);
        disp(['  Loaded ' psth_filelist{i} ' succesfully']);
        psth_response = temp2.(psth_type);
        if cell_metrics.general.cellCount == size(psth_response.unit,2) && length(psth_response.x_bins) == size(psth_response.unit,1)
            cell_metrics.(psth_type){1} = psth_response.unit;
            if isfield(psth_response,'x_label')
                cell_metrics.general.(psth_type).x_label = psth_response.x_bins;
            end
            if isfield(psth_response,'x_bins')
                cell_metrics.general.(psth_type).x_bins = psth_response.x_bins;
            end
            if isfield(psth_response,'boundaries')
                cell_metrics.general.(psth_type).boundaries = psth_response.boundaries;
            end
            if isfield(psth_response,'labels')
                cell_metrics.general.(psth_type).labels = psth_response.labels;
            end
            if isfield(psth_response,'boundaries_labels')
                cell_metrics.general.(psth_type).boundaries_labels = psth_response.boundaries_labels;
            end
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Behavior metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Custom metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

customCalculationsOptions = what('customCalculations');
customCalculationsOptions = cellfun(@(X) X(1:end-2),customCalculationsOptions.m,'UniformOutput', false);
customCalculationsOptions(strcmpi(customCalculationsOptions,'template')) = [];
for i = 1:length(customCalculationsOptions)
    if any(contains(parameters.metrics,{customCalculationsOptions{i},'all'})) && ~any(contains(parameters.excludeMetrics,{customCalculationsOptions{i}}))
        dispLog(['Custom calculation:' customCalculationsOptions{i}]);
        cell_metrics = customCalculations.(customCalculationsOptions{i})(cell_metrics,session,spikes,parameters);
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Import pE and pI classifications from Buzcode (basename.CellClass.cellinfo.mat)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

filename = fullfile(basepath,[basename,'.CellClass.cellinfo.mat']);
if exist(filename,'file')
    dispLog('Importing classified cell types from buzcode');
    temp = load(filename);
    disp(['  Loaded ' filename ' succesfully']);
    if isfield(temp.CellClass,'label') && size(temp.CellClass.label,2) == cell_metrics.general.cellCount
        cell_metrics.CellClassBuzcode = repmat({'Unknown'},1,cell_metrics.general.cellCount);
        for i = 1:cell_metrics.general.cellCount
            if ~isempty(temp.CellClass.label{i})
                cell_metrics.CellClassBuzcode{i} = temp.CellClass.label{i};
            end
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Other metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

spkExclu = setSpkExclu('other_metrics',parameters);

% Session specific metrics
session.general.sessionName = session.general.name;
cell_metrics.sessionName = repmat({session.general.name},1,cell_metrics.general.cellCount);
listMetrics = {'investigator','sessionType'};
for i = find(isfield(session.general,listMetrics))
    cell_metrics.general.session.(listMetrics{i}) = session.general.(listMetrics{i});
end

% Spike sorting algorithm
if isfield(session.spikeSorting{1},'method')
    cell_metrics.general.session.spikeSortingMethod = session.spikeSorting{1}.method;
end

% Animal specific metrics
cell_metrics.animal = repmat({session.animal.name},1,cell_metrics.general.cellCount);
listMetrics = {'sex','species','strain','geneticLine'};
for i = find(isfield(session.animal,listMetrics))
    cell_metrics.general.animal.(listMetrics{i}) = session.animal.(listMetrics{i});
end

% Firing rate across time
firingRateAcrossTime_binsize = 3*60;
if max(vertcat(spikes{spkExclu}.times{:}))/firingRateAcrossTime_binsize<40
    firingRateAcrossTime_binsize = ceil(max(vertcat(spikes{spkExclu}.times{:}))/40/10)*10;
end

% Cleaning out firingRateAcrossTime
field2remove = {'firingRateAcrossTime'};
test = isfield(cell_metrics,field2remove);
cell_metrics = rmfield(cell_metrics,field2remove(test));
if isfield(cell_metrics.general,'responseCurves')
    test = isfield(cell_metrics.general.responseCurves,field2remove);
    cell_metrics.general.responseCurves = rmfield(cell_metrics.general.responseCurves,field2remove(test));
end
cell_metrics.general.responseCurves.firingRateAcrossTime.x_edges = [0:firingRateAcrossTime_binsize:max(vertcat(spikes{spkExclu}.times{:}))];
cell_metrics.general.responseCurves.firingRateAcrossTime.x_bins = cell_metrics.general.responseCurves.firingRateAcrossTime.x_edges(1:end-1)+firingRateAcrossTime_binsize/2;

if isfield(session,'epochs')
    for j = 1:length(session.epochs)
        if isfield(session.epochs{j},'behavioralParadigm') && isfield(session.epochs{j},'stopTime')
            cell_metrics.general.responseCurves.firingRateAcrossTime.boundaries(j) = session.epochs{j}.stopTime;
            cell_metrics.general.responseCurves.firingRateAcrossTime.boundaries_labels{j} = session.epochs{j}.behavioralParadigm;
        elseif isfield(session.epochs{j},'stopTime')
            cell_metrics.general.responseCurves.firingRateAcrossTime.boundaries(j) = session.epochs{j}.stopTime;
        end
    end

end

if isfield(session,'brainRegions') && ~isempty(session.brainRegions)
    chListBrainRegions = findBrainRegion(session);
end

% Spikes metrics
cell_metrics.cellID =  spikes{spkExclu}.UID;
cell_metrics.UID =  spikes{spkExclu}.UID;
cell_metrics.cluID =  spikes{spkExclu}.cluID;
% cell_metrics.spikeGroup = spikes{spkExclu}.shankID; % cell_spikegroup OK
cell_metrics.electrodeGroup = spikes{spkExclu}.shankID; % cell_spikegroup OK
cell_metrics.maxWaveformCh = spikes{spkExclu}.maxWaveformCh1-1; % cell_maxchannel OK
cell_metrics.maxWaveformCh1 = spikes{spkExclu}.maxWaveformCh1; % cell_maxchannel OK
cell_metrics.spikeCount = spikes{spkExclu}.total; % cell_spikecount OK

cell_metrics.general.electrodeGroups = session.extracellular.electrodeGroups.channels;

for j = 1:cell_metrics.general.cellCount
    % Session metrics
    if isfield(session.general,'entryID') && isnumeric(session.general.entryID)
        cell_metrics.sessionID(j) = session.general.entryID; % cell_sessionid OK
    elseif isfield(session.general,'entryID') && ischar(session.general.entryID)
        cell_metrics.sessionID(j) = str2num(session.general.entryID); % cell_sessionid OK
    end 
    if isfield(session.spikeSorting{1},'entryID')
        cell_metrics.spikeSortingID(j) = session.spikeSorting{1}.entryID; % cell_spikesortingid OK
    end

    % Spikes metrics
    if isfield(session,'brainRegions') && ~isempty(session.brainRegions)
        cell_metrics.brainRegion{j} = chListBrainRegions{spikes{spkExclu}.maxWaveformCh1(j)}; % cell_brainregion OK
    end
    try
        cell_metrics.maxWaveformChannelOrder(j) = find([session.extracellular.electrodeGroups.channels{:}] == spikes{spkExclu}.maxWaveformCh1(j)); %
    catch
        warning('peak channel not determined')
        cell_metrics.maxWaveformChannelOrder(j) = nan;
    end
    
    % Spike times based metrics
    if ~isempty(parameters.excludeIntervals)
        idx = find(any(parameters.excludeIntervals' > spikes{spkExclu}.times{j}(1)) & any(parameters.excludeIntervals' < spikes{spkExclu}.times{j}(end)));
        if isempty(idx)
            spike_window = ((spikes{spkExclu}.times{j}(end)-spikes{spkExclu}.times{j}(1)));
        else
            spike_window = ((spikes{spkExclu}.times{j}(end)-spikes{spkExclu}.times{j}(1))) - sum(diff(parameters.excludeIntervals(idx,:)'));
        end
        cell_metrics.firingRate(j) = spikes{spkExclu}.total(j)/spike_window; % cell_firingrate OK
    elseif isempty(spikes{spkExclu}.times{j})
        cell_metrics.firingRate(j) = 0;
    else
        cell_metrics.firingRate(j) = spikes{spkExclu}.total(j)/((spikes{spkExclu}.times{j}(end)-spikes{spkExclu}.times{j}(1))); % cell_firingrate OK
    end
    
    % Firing rate across time
    temp = histcounts(spikes{spkExclu}.times{j},cell_metrics.general.responseCurves.firingRateAcrossTime.x_edges)/firingRateAcrossTime_binsize;
    cell_metrics.responseCurves.firingRateAcrossTime{j} = temp(:);
    
    cum_firing1 = cumsum(sort(temp(:)));
    cum_firing1 = cum_firing1/max(cum_firing1);
    cell_metrics.firingRateGiniCoeff(j) = 1-2*sum(cum_firing1)./length(cum_firing1);
    cell_metrics.firingRateStd(j) = std(temp(:))./mean(temp(:));
    cell_metrics.firingRateInstability(j) = median(abs(diff(temp(:))))./mean(temp(:));
    
    % CV2
    tau = diff(spikes{spkExclu}.times{j});
    cell_metrics.firingRateISI(j) = 1/median(tau);
    CV2_temp = 2*abs(tau(1:end-1) - tau(2:end)) ./ (tau(1:end-1) + tau(2:end));
    cell_metrics.cv2(j) = mean(CV2_temp(CV2_temp<1.95));
    
    % Burstiness_Mizuseki2011
    bursty = [];
    for jj = 2 : length(spikes{spkExclu}.times{j}) - 1
        bursty(jj) =  any(diff(spikes{spkExclu}.times{j}(jj-1 : jj + 1)) < 0.006);
    end
    cell_metrics.burstIndex_Mizuseki2012(j) = length(find(bursty > 0))/length(bursty); % Fraction of spikes with a ISI for following or preceding spikes < 0.006
    
    % Refractory period violation
    cell_metrics.refractoryPeriodViolation(j) = 1000*length(find(diff(spikes{spkExclu}.times{j})<0.002))/spikes{spkExclu}.total(j);
end

if ~isfield(cell_metrics,'labels')
    cell_metrics.labels = repmat({''},1,cell_metrics.general.cellCount);
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% cell_classification_putativeCellType
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ~isfield(cell_metrics,'putativeCellType') || ~ parameters.keepCellClassification
    dispLog('Performing Cell-type classification');
    % All cells assigned as Pyramidal cells at first
    cell_metrics.putativeCellType = repmat({'Pyramidal Cell'},1,cell_metrics.general.cellCount);
    
    % Interneuron classification
    % Cells are reassigned as interneurons by below criteria 
    % acg_tau_decay > 30ms
    cell_metrics.putativeCellType(cell_metrics.acg_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_decay>30),1);
    % acg_tau_rise > 3ms
    cell_metrics.putativeCellType(cell_metrics.acg_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_rise>3),1);
    % troughToPeak <= 0.425ms
    cell_metrics.putativeCellType(cell_metrics.troughToPeak<=0.425) = repmat({'Interneuron'},sum(cell_metrics.troughToPeak<=0.425),1);
    % Narrow interneuron assigned if troughToPeak <= 0.425ms
    cell_metrics.putativeCellType(cell_metrics.troughToPeak<=0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.troughToPeak<=0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
    % Wide interneuron assigned if troughToPeak > 0.425ms
    cell_metrics.putativeCellType(cell_metrics.troughToPeak>0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.troughToPeak>0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Cleaning metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Removing CCGs
field2remove = {'ccg','ccg_time'};
test = isfield(cell_metrics.general,field2remove);
cell_metrics.general = rmfield(cell_metrics.general,field2remove(test));

% Order fields alphabetically
cell_metrics = orderfields(cell_metrics);

% Defines unknown brain region if not defined
if ~isfield(cell_metrics,'brainRegion')
    cell_metrics.brainRegion = repmat({'Unknown'},1,cell_metrics.general.cellCount);
end

dispLog('Cleaning metrics')
if any(contains(parameters.removeMetrics,{'deepSuperficial'}))
    dispLog('Removing deepSuperficial metrics')
    field2remove = {'deepSuperficial','deepSuperficialDistance'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    cell_metrics.deepSuperficial = repmat({'Unknown'},1,cell_metrics.general.cellCount);
    cell_metrics.deepSuperficialDistance = nan(1,cell_metrics.general.cellCount);
end

if ~isfield(cell_metrics,'deepSuperficial')
    cell_metrics.deepSuperficial = repmat({'Unknown'},1,cell_metrics.general.cellCount);
    cell_metrics.deepSuperficialDistance = nan(1,cell_metrics.general.cellCount);
end

dispLog('Cleaning legacy fields')
field2remove = {'firingRateMap_StimStates','rawWaveform_zscored','firingRateMap_StimStates','acg2_zscored','acg_zscored','filtWaveform_zscored',...
    'firingRateAcrossTime','thetaPhaseResponse','firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMap','firing_rate_map_states',...
    'firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap',...
    'FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'...
    'sex','species','strain','geneticLine','sessionType','geneticLine','session_name','spikeSortingMethod'};
% cleaning cell_metrics
test2 = isfield(cell_metrics,field2remove);
cell_metrics = rmfield(cell_metrics,field2remove(test2));
% cleaning cell_metrics.general
test = isfield(cell_metrics.general,field2remove);
cell_metrics.general = rmfield(cell_metrics.general,field2remove(test));

% cleaning cell_metrics.general.session & cell_metrics.general.animal
field2remove = {'name'};
test2 = isfield(cell_metrics.general.session,field2remove);
cell_metrics.general.session = rmfield(cell_metrics.general.session,field2remove(test2));
field2remove = {'name'};
test2 = isfield(cell_metrics.general.animal,field2remove);
cell_metrics.general.animal = rmfield(cell_metrics.general.animal,field2remove(test2));

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Submitting to database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Checks if db credentials have been set
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

if parameters.submitToDatabase && enableDatabase
    dispLog('Submitting cells to database');
    if parameters.debugMode
        cell_metrics = db_submit_cells(cell_metrics,session);
%         session = db_update_session(session,'forceReload',true);
    else
        try
            cell_metrics = db_submit_cells(cell_metrics,session);
%             session = db_update_session(session,'forceReload',true);
        catch exception
            disp(exception.identifier)
            warning('Failed to submit to database');
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Adding processing info
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
cell_metrics.general.processinginfo.params = parameters;
cell_metrics.general.processinginfo.function = 'ProcessCellMetrics';
cell_metrics.general.processinginfo.date = now;
cell_metrics.general.processinginfo.version = 2.1;
try
    cell_metrics.general.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    cell_metrics.general.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end
if isfield(spikes{spkExclu},'processinginfo')
    cell_metrics.general.processinginfo.spikes = spikes{spkExclu}.processinginfo;
end
if exist('deepSuperficialfromRipple','var') && isfield(deepSuperficialfromRipple,'processinginfo')
    cell_metrics.general.processinginfo.deepSuperficialfromRipple = deepSuperficialfromRipple.processinginfo;
end
% Restricted intervals
if ~isempty(parameters.restrictToIntervals) && size(parameters.restrictToIntervals,2) == 2
    cell_metrics.general.restrictToIntervals = parameters.restrictToIntervals;
end
if ~isempty(parameters.excludeIntervals) && size(parameters.excludeIntervals,2) == 2
    cell_metrics.general.excludeIntervals = parameters.excludeIntervals;
end
%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Verifying metrics struct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
dispLog('Verifying metrics struct');
verifyCellMetricsStruct(cell_metrics);

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Saving cells
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if parameters.saveMat
    dispLog(['Saving cells to: ',saveAsFullfile]);
    try
        structSize = whos('cell_metrics');
        if structSize.bytes/1000000000 > 2
            save(saveAsFullfile,'cell_metrics','-v7.3')
        else
            save(saveAsFullfile,'cell_metrics')
        end
        dispLog(['Saving session struct: ' fullfile(basepath,[basename,'.session.mat'])]);
        save(fullfile(basepath,[basename,'.session.mat']),'session')
    catch
        warning('Failed to save data in the CellExplorer pipeline')
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %%
% Summary figures
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

CellExplorer('metrics',cell_metrics,'summaryFigures',true,'plotCellIDs',-1); % Creates group plots only

if parameters.summaryFigures
    cell_metrics.general.path = basepath;
    CellExplorer('metrics',cell_metrics,'summaryFigures',true);
    
    X = [cell_metrics.firingRateISI; cell_metrics.thetaModulationIndex; cell_metrics.burstIndex_Mizuseki2012;  cell_metrics.troughToPeak; cell_metrics.troughtoPeakDerivative; cell_metrics.ab_ratio; cell_metrics.burstIndex_Royer2012; cell_metrics.acg_tau_rise; cell_metrics.acg_tau_decay; cell_metrics.cv2]';
    Y = tsne(X);
    goodrows = not(any(isnan(X),2));
    if isfield(cell_metrics,'deepSuperficial')
        figure,
        gscatter(Y(:,1),Y(:,2),cell_metrics.putativeCellType(goodrows)'), title('Cell type classification shown in tSNE space'), hold on
        plot(Y(find(strcmp(cell_metrics.deepSuperficial(goodrows),'Superficial')),1),Y(find(strcmp(cell_metrics.deepSuperficial(goodrows),'Superficial')),2),'xk')
        plot(Y(find(strcmp(cell_metrics.deepSuperficial(goodrows),'Deep')),1),Y(find(strcmp(cell_metrics.deepSuperficial(goodrows),'Deep')),2),'ok')
        xlabel('o = Deep, x = Superficial')
    end
    
    figure,
    histogram(cell_metrics.electrodeGroup,[0:14]+0.5),xlabel('Spike groups'), ylabel('Count')
    
    figure, subplot(2,2,1)
    histogram(cell_metrics.burstIndex_Mizuseki2012,40),xlabel('BurstIndex Mizuseki2012'), ylabel('Count')
    subplot(2,2,2)
    histogram(cell_metrics.cv2,40),xlabel('CV2'), ylabel('Count')
    subplot(2,2,3)
    histogram(cell_metrics.refractoryPeriodViolation,40),xlabel('Refractory period violation (‰)'), ylabel('Count')
    subplot(2,2,4)
    histogram(cell_metrics.thetaModulationIndex,40),xlabel('Theta modulation index'), ylabel('Count')
    
    figure, subplot(2,2,1)
    histogram(CV2_temp,40),xlabel('CV2_temp'), ylabel('Count')
    subplot(2,2,2)
    histogram(CV2_temp(CV2_temp<1.9),40),xlabel('CV2_temp'), ylabel('Count')
    
    % Plotting ACG metrics
    figure
    window_limits = [-50:50];
    order_acgmetrics = {'burstIndex_Royer2012','acg_tau_rise','acg_tau_decay','burstIndex_Mizuseki2012'};
    order = {'ascend','descend','descend'};
    for j = 1:3
        [~,index] = sort(cell_metrics.(order_acgmetrics{j}),order{j});
        temp = cell_metrics.acg.wide(window_limits+501,index)./(ones(length(window_limits),1)*max(cell_metrics.acg.wide(window_limits+501,index)));
        
        subplot(2,3,j),
        imagesc(window_limits,[],temp'),title(order_acgmetrics{j},'interpreter','none')
        subplot(2,3,3+j),
        mpdc10 = [size(temp,2):-1:1;1:size(temp,2);size(temp,2):-1:1]/size(temp,2); hold on
        for j = 1:size(temp,2)
            plot(window_limits,temp(:,j),'color',[mpdc10(:,j);0.5]), axis tight, hold on
        end
    end
    figure,
    plot3(cell_metrics.acg_tau_rise,cell_metrics.acg_tau_decay,cell_metrics.troughtoPeakDerivative,'.')
    xlabel('Tau decay'), ylabel('Tau rise'), zlabel('Derivative Trough-to-Peak')
    
    % Plotting summary figure with acg-taus and deepSuperficialDistance
    if isfield(cell_metrics,'deepSuperficial')
        figure, hold on
        CellTypeGroups = unique(cell_metrics.putativeCellType);
        colorgroups = {'k','g','b','r','c','m'};
        plotX = cell_metrics.troughtoPeakDerivative;
        plotY = cell_metrics.acg_tau_decay;
        plotZ = cell_metrics.deepSuperficialDistance;
        for iii = 1:length(CellTypeGroups)
            indexes = find(strcmp(cell_metrics.putativeCellType,CellTypeGroups{iii}));
            scatter3(plotX(indexes),plotY(indexes),plotZ(indexes),30,'MarkerFaceColor',colorgroups{iii}, 'MarkerEdgeColor','none','MarkerFaceAlpha',.7)
        end
        if isfield(cell_metrics,'putativeConnections') && ~isempty(cell_metrics.putativeConnections.excitatory)
            a1 = cell_metrics.putativeConnections.excitatory(:,1);
            a2 = cell_metrics.putativeConnections.excitatory(:,2);
            plot3([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],[plotZ(a1);plotZ(a2)],'k')
        end
        xlabel('Tau decay'), ylabel('Tau rise'), zlabel('deepSuperficialDistance')
    end
    
    % Plotting the average ripple with sharp wave across all spike groups
    deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
    if exist(deepSuperficial_file,'file')
        load(deepSuperficial_file)
        fig = figure('Name','Deep-Superficial assignment','pos',[50,50,1000,800]);
        ripple_scaling = 0.2;
        for jj = 1:session.extracellular.nSpikeGroups
            subplot(2,ceil(session.extracellular.nSpikeGroups/2),jj)
            plot((deepSuperficialfromRipple.SWR_diff{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_diff{jj},2)-1]*ripple_scaling,'-k','linewidth',2), hold on, grid on
            plot((deepSuperficialfromRipple.SWR_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_amplitude{jj},2)-1]*ripple_scaling,'k','linewidth',1)
            % Plotting ripple amplitude along vertical axis
            plot((deepSuperficialfromRipple.ripple_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.ripple_amplitude{jj},2)-1]*ripple_scaling,'m','linewidth',1)
            
            for jjj = 1:size(deepSuperficialfromRipple.ripple_average{jj},2)
                % Plotting depth (µm)
                text(deepSuperficialfromRipple.ripple_time_axis(end)+5,deepSuperficialfromRipple.ripple_average{jj}(1,jjj)-(jjj-1)*ripple_scaling,[num2str(round(deepSuperficialfromRipple.channelDistance(deepSuperficialfromRipple.ripple_channels{jj}(jjj))))])
                % Plotting channel number (0 indexes)
                text((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50-10,-(jjj-1)*ripple_scaling,num2str(deepSuperficialfromRipple.ripple_channels{jj}(jjj)-1),'HorizontalAlignment','Right')
                plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*ripple_scaling)
                % Plotting assigned channel labels
                if strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Superficial')
                    plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*ripple_scaling,'or','linewidth',2)
                elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Deep')
                    plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*ripple_scaling,'ob','linewidth',2)
                elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Cortical')
                    plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*ripple_scaling,'og','linewidth',2)
                else
                    plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*ripple_scaling,'ok')
                end
                % Plotting the channel used for the ripple detection if it is part of current spike group
                %             if ripple_channel_detector==deepSuperficialfromRipple.ripple_channels{jj}(jjj)
                %                 plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*ripple_scaling,'k','linewidth',2)
                %             end
            end
            
            title(['Spike group ' num2str(jj)]),xlabel('Time (ms)'),if jj ==1; ylabel(session.general.name, 'Interpreter', 'none'); end
            axis tight, ax6 = axis; grid on
            plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
            xlim([-220,deepSuperficialfromRipple.ripple_time_axis(end)+45]), xticks([-120:40:120])
            ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
            ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
            if ceil(session.extracellular.nSpikeGroups/2) == jj || session.extracellular.nSpikeGroups == jj
                ht3 = text(1.05,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
            end
        end
        saveas(fig,fullfile(basepath,[basename,'.deepSuperficialfromRipple.png']))
    end
end

dispLog(['Cell metrics calculations complete. Elapsed time is ', num2str(toc(timerCalcMetrics),5),' seconds.'])

end

function dispLog(message)
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    message2 = sprintf('[%s] %s', timestamp, message);
    disp(message2);
end

function spkExclu = setSpkExclu(metrics,parameters)
    if ismember(metrics,parameters.metricsToExcludeManipulationIntervals)
        spkExclu = 2; % Spikes excluding times within exclusion intervals
    else
        spkExclu = 1; % All spikes (can be restricted)
    end
end
