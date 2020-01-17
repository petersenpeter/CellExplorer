function cell_metrics = calc_CellMetrics(varargin)
%   This function calculates cell metrics for a given recording/session
%   Most metrics are single value per cell, either numeric or string type, but
%   certain metrics are vectors like the autocorrelograms or cell with double content like waveforms.
%   The metrics are based on a number of features: Spikes, Waveforms, PCA features,
%   the ACG and CCGs, LFP, theta, ripples and so fourth
%
%   Check the wiki of the Cell Explorer for more details: https://github.com/petersenpeter/Cell-Explorer/wiki
%
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%   INPUTS
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
%   varargin (Variable-length input argument list; see below)
%
%   - Parameters defining the session to process - 
%   basepath               - 1. Path to session (base directory)
%   clusteringpath         - 2. Path to cluster data if different from basepath. basepath input required if different
%   session                - 3. Database sessionName
%   id                     - 4. Database numeric id
%   sessionStruct          - 5. Session struct. Must contain a basepath and clusteringpath
%
%   - Settings for the processing - 
%   showGUI                - Show GUI dialog to adjust settings/parameters
%   metrics                - Metrics that will be calculated. A cell with strings
%                            Examples: 'waveform_metrics','PCA_features','acg_metrics','deepSuperficial',
%                            ,'monoSynaptic_connections','theta_metrics','spatial_metrics',
%                            'event_metrics','manipulation_metrics', 'state_metrics'
%                            ,'psth_metrics', 'importCellTypeClassification'.
%                            Default: 'all'
%   excludeMetrics         - Metrics to exclude. Default: 'none'
%   removeMetrics          - Metrics to remove (supports only deepSuperficial at this point)
%   keepCellClassification - logical. Keep existing cell type classifications
%   manualAdjustMonoSyn    - logical. Manually verify monosynaptic connections in the pipeline (requires user input)
%   excludeIntervals       - time intervals to exclude
%   excludeManipulationIntervals - exclude time intervals around manipulations 
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
%
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%   OUTPUT
%   % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%
%   Cell_metrics : structure described on the wiki https://github.com/petersenpeter/Cell-Explorer/wiki/Cell-metrics

%   By Peter Petersen
%   petersen.peter@gmail.com
%   Last edited: 08-01-2020


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Parsing parameters
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'sessionName',[],@isstr);
addParameter(p,'session',[],@isstruct);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'metrics','all',@iscellstr);
addParameter(p,'excludeMetrics',{'none'},@iscellstr);
addParameter(p,'removeMetrics',{'none'},@isstr);
addParameter(p,'excludeIntervals',[],@isnumeric);
addParameter(p,'ignoreEventTypes',{'MergePoints'},@iscell);
addParameter(p,'ignoreManipulationTypes',{'cooling'},@iscell);
addParameter(p,'ignoreStateTypes',{'StateToIgnore'},@iscell);
addParameter(p,'excludeManipulationIntervals',true,@islogical);

addParameter(p,'keepCellClassification',true,@islogical);
addParameter(p,'manualAdjustMonoSyn',true,@islogical);
addParameter(p,'showGUI',false,@islogical);
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'submitToDatabase',true,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','cell_metrics',@isstr);
addParameter(p,'saveBackup',true,@islogical);
addParameter(p,'summaryFigures',true,@islogical);
addParameter(p,'debugMode',false,@islogical);

parse(p,varargin{:})

id = p.Results.id;
sessionin = p.Results.sessionName;
sessionStruct = p.Results.session;
basepath = p.Results.basepath;
clusteringpath = p.Results.clusteringpath;
metrics = p.Results.metrics;
excludeMetrics = p.Results.excludeMetrics;
removeMetrics = p.Results.removeMetrics;
excludeIntervals = p.Results.excludeIntervals;
ignoreEventTypes = p.Results.ignoreEventTypes;
excludeManipulationIntervals = p.Results.excludeManipulationIntervals;
ignoreManipulationTypes = p.Results.ignoreManipulationTypes;
ignoreStateTypes = p.Results.ignoreStateTypes;
keepCellClassification = p.Results.keepCellClassification;
manualAdjustMonoSyn = p.Results.manualAdjustMonoSyn;
showGUI = p.Results.showGUI;

forceReload = p.Results.forceReload;
submitToDatabase = p.Results.submitToDatabase;
saveMat = p.Results.saveMat;
saveAs = p.Results.saveAs;
saveBackup = p.Results.saveBackup;
summaryFigures = p.Results.summaryFigures;
debugMode = p.Results.debugMode;
timerCalcMetrics = tic;


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading session metadata from DB or sessionStruct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ~isempty(id) || ~isempty(sessionin) || ~isempty(sessionStruct)
    if ~isempty(id)
        [session, basename, basepath, clusteringpath] = db_set_session('sessionId',id);
    elseif ~isempty(sessionin)
        [session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionin);
    elseif ~isempty(sessionStruct)
        showGUI = true;
        if isfield(sessionStruct.general,'basePath') && isfield(sessionStruct.general,'clusteringPath')
            session = sessionStruct;
            basename = session.general.name;
            basepath = session.general.basePath;
            clusteringpath = session.general.clusteringPath;
        else
            [session, basename, basepath, clusteringpath] = db_set_session('session',sessionStruct);
            if isempty(session.general.entryID)
                session.general.entryID = ''; % DB id
            end
            if isempty(session.spikeSorting{1}.entryID)
                session.spikeSorting{1}.entryID = ''; % DB id
            end
        end
    else
        warning('Please provide a session struct or a session name/id to load a session from the DB')
    end
end

% If no session struct is provided it will look for a basename.session.mat file in the basepath and otherwise load the template and show the GUI gui_session
if ~exist('session','var')
    [~,basename,~] = fileparts(basepath);
    if exist([basename,'.session.mat'],'file')
        disp(['* Loading ',basename,'.session.mat from current folder']);
        load([basename,'.session.mat']);
        session.general.basePath = basepath;
        clusteringpath = session.general.clusteringPath;
    elseif exist(['session.mat'],'file')
        disp(['* Loading session.mat from current folder']);
        load(['session.mat']);
        session.general.basePath = basepath;
        clusteringpath = session.general.clusteringPath;
    else
        cd(basepath)
        session = sessionTemplate;
        showGUI = true;
    end
end

% If no arguments are given, the GUI is shown
if nargin==0
    showGUI = true;
end

% Checking format of spike groups and electrode groups (must be of type cell)
if isfield(session.extracellular,'spikeGroups') && isfield(session.extracellular.spikeGroups,'channels') && isnumeric(session.extracellular.spikeGroups.channels)
    session.extracellular.spikeGroups.channels = num2cell(session.extracellular.spikeGroups.channels,2);
end
if isfield(session.extracellular,'electrodeGroups') && isfield(session.extracellular.electrodeGroups,'channels') && isnumeric(session.extracellular.electrodeGroups.channels)
    session.extracellular.electrodeGroups.channels = num2cell(session.extracellular.electrodeGroups.channels,2)';
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% showGUI
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if showGUI
    disp('* Showing GUI for adjusting parameters and session meta data') 
    parameters = p.Results;
    parameters.excludeIntervals = excludeIntervals;
    parameters.summaryFigures = summaryFigures;
    
    session.general.basePath = basepath;
    session.general.clusteringPath = clusteringpath;
    
    % Non-standard parameters: probeSpacing and probeLayout
    if ~isfield(session.analysisTags,'probesVerticalSpacing') && ~isfield(session.analysisTags,'probesLayout') && isfield(session.extracellular,'electrodes') && isfield(session.extracellular.electrodes,'siliconProbes')
        session = determineProbeSpacing(session);
    end
    [session,parameters,status] = gui_session(session,parameters);
    if status==0
        disp('  Metrics calculations canceled by user')
        return
    end
    basename = session.general.name;
    basepath = session.general.basePath;
    clusteringpath = session.general.clusteringPath;
    
    % Parameters
    metrics = parameters.metrics;
    excludeMetrics = parameters.excludeMetrics;
    removeMetrics = parameters.removeMetrics;
    excludeIntervals = parameters.excludeIntervals;
    excludeManipulationIntervals = parameters.excludeManipulationIntervals;
    keepCellClassification = parameters.keepCellClassification;
    manualAdjustMonoSyn = parameters.manualAdjustMonoSyn;
    forceReload = parameters.forceReload;
    summaryFigures = parameters.summaryFigures;
    submitToDatabase = parameters.submitToDatabase;
    saveMat = parameters.saveMat;
    saveBackup = parameters.saveBackup;
    debugMode = parameters.debugMode;
    cd(basepath)
    
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Getting spikes  -  excluding user specified- and manipulation intervals
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

disp('* Getting spikes')
sr = session.extracellular.sr;
spikes = loadSpikes('clusteringpath',clusteringpath,'clusteringformat',session.spikeSorting{1}.format,'basepath',basepath,'basename',basename,'LSB',session.extracellular.leastSignificantBit);
if ~isfield(spikes,'processinginfo') || ~isfield(spikes.processinginfo.params,'WaveformsSource') || ~strcmp(spikes.processinginfo.params.WaveformsSource,'dat file') || spikes.processinginfo.version<3.5
    spikes = loadSpikes('clusteringpath',clusteringpath,'clusteringformat',session.spikeSorting{1}.format,'basepath',basepath,'basename',basename,'forceReload',true,'spikes',spikes,'LSB',session.extracellular.leastSignificantBit);
end

if excludeManipulationIntervals
    disp('* Excluding manipulation events')
    manipulationFiles = dir(fullfile(basepath,[basename,'.*.manipulation.mat']));
    manipulationFiles = {manipulationFiles.name};
    manipulationFiles(find(contains(manipulationFiles,ignoreManipulationTypes)))=[];
    if ~isempty(manipulationFiles)
        for iEvents = 1:length(manipulationFiles)
            eventName = strsplit(manipulationFiles{iEvents},'.'); 
            eventName = eventName{end-2};
            eventOut = load(manipulationFiles{iEvents});
            if size(eventOut.(eventName).timestamps,2) == 2
                disp(['  Excluding manipulation type: ' eventName])
                excludeIntervals = [excludeIntervals;eventOut.(eventName).timestamps];
            else
                warning('manipulation timestamps has to be a Nx2 matrix')
            end
        end
    else
         disp('  No manipulation events excluded')
    end
end

if ~isempty(excludeIntervals)
    % Checks if intervals are formatted correctly
    if size(excludeIntervals,2) ~= 2
        error('excludeIntervals has to be a Nx2 matrix')
    else
        disp(['  Excluding ',num2str(size(excludeIntervals,1)),' intervals in spikes (' num2str(sum(diff(excludeIntervals'))),' seconds)'])
        spikes_all = spikes;
        for j = 1:size(spikes.times,2)
            indeces2keep = 1:length(spikes.times{j});
            indeces2delete = find(any(spikes.times{j} >= excludeIntervals(:,1)' & spikes.times{j} <= excludeIntervals(:,2)', 2));
            indeces2keep(indeces2delete) = [];
            spikes.times{j} =  spikes.times{j}(indeces2keep);
            spikes.total(j) =  length(indeces2keep);
            if isfield(spikes,'ts')
                spikes.ts{j} =  spikes.ts{j}(indeces2keep);
            end
            if isfield(spikes,'ids')
                spikes.ids{j} =  spikes.ids{j}(indeces2keep);
            end
            if isfield(spikes,'amplitudes')
                spikes.amplitudes{j} =  spikes.amplitudes{j}(indeces2keep);
            end
        end
        indeces2keep = 1:size(spikes.spindices,1);
        indeces2delete = find(any(spikes.spindices(:,1) >= excludeIntervals(:,1)' & spikes.spindices(:,1) <= excludeIntervals(:,2)', 2));
        indeces2keep(indeces2delete) = [];
        spikes.spindices = spikes.spindices(indeces2keep,:);
    end
else
    spikes_all = spikes;
    disp('  No intervals excluded')
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Initializing cell_metrics struct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

clusteringpath_full = fullfile(basepath,clusteringpath);
saveAsFullfile = fullfile(clusteringpath_full,[basename,'.',saveAs,'.cellinfo.mat']);

if exist(saveAsFullfile,'file')
    disp(['* Loading existing metrics: ' saveAsFullfile])
    load(saveAsFullfile)
elseif exist(fullfile(clusteringpath_full,[saveAs,'.mat']),'file')
    % For compatibility
    warning(['Loading existing legacy metrics: ' saveAs])
    load(fullfile(clusteringpath_full,[saveAs,'.mat']))
else
    cell_metrics = [];
end

if saveBackup && ~isempty(cell_metrics)
    % Creating backup of existing user adjustable metrics
    backupDirectory = 'revisions_cell_metrics';
    disp(['* Creating backup of existing user adjustable metrics ''',backupDirectory,'''']);
    
    if ~(exist(fullfile(clusteringpath_full,backupDirectory),'dir'))
        mkdir(fullfile(clusteringpath_full,backupDirectory));
    end
    backupFields = {'labels','tags','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType','groundTruthClassification'};
    temp = {};
    for i = 1:length(backupFields)
        if isfield(cell_metrics,backupFields{i})
            temp.cell_metrics.(backupFields{i}) = cell_metrics.(backupFields{i});
        end
    end
%     if isfield(cell_metrics,'labels')
%         temp.cell_metrics.labels = cell_metrics.labels;
%     end
%     if isfield(cell_metrics,'tags')
%         temp.cell_metrics.tags = cell_metrics.tags;
%     end
%     if isfield(cell_metrics,'deepSuperficial')
%         temp.cell_metrics.deepSuperficial = cell_metrics.deepSuperficial;
%     end
%     if isfield(cell_metrics,'deepSuperficialDistance')
%         temp.cell_metrics.deepSuperficialDistance = cell_metrics.deepSuperficialDistance;
%     end
%     if isfield(cell_metrics,'brainRegion')
%         temp.cell_metrics.brainRegion = cell_metrics.brainRegion;
%     end
%     if isfield(cell_metrics,'putativeCellType')
%         temp.cell_metrics.putativeCellType = cell_metrics.putativeCellType;
%     end
%     if isfield(cell_metrics,'groundTruthClassification')
%         temp.cell_metrics.groundTruthClassification = cell_metrics.groundTruthClassification;
%     end
    save(fullfile(clusteringpath_full, backupDirectory, [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat',]),'cell_metrics','-v7.3','-nocompression', '-struct', 'temp')
end

cell_metrics.general.basepath = basepath;
cell_metrics.general.basename = basename;
cell_metrics.general.clusteringpath = clusteringpath;
cell_metrics.general.cellCount = length(spikes.total);


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Waveform based calculations
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'waveform_metrics','all'})) && ~any(contains(excludeMetrics,{'waveform_metrics'}))
    if ~all(isfield(cell_metrics,{'waveforms23','peakVoltage','troughToPeak','troughtoPeakDerivative','ab_ratio'})) || forceReload == true
        disp('* Getting waveforms');
        if all(isfield(spikes,{'filtWaveform','peakVoltage','cluID'})) % 'filtWaveform_std'
            waveforms.filtWaveform = spikes.filtWaveform;
            if isfield(spikes,'timeWaveform')
                waveforms.timeWaveform = spikes.timeWaveform;
            else
                waveforms.timeWaveform = repmat({(([1:length(waveforms.filtWaveform{1})]-floor(length(waveforms.filtWaveform{1})/2))/sr)*1000},1,cell_metrics.general.cellCount);
            end
            if isfield(spikes,'filtWaveform_std')
                waveforms.filtWaveform_std = spikes.filtWaveform_std;
            end
            waveforms.peakVoltage = spikes.peakVoltage;
            waveforms.UID = spikes.UID;
        elseif any(~isfield(spikes,{'filtWaveform','peakVoltage','cluID'})) % ,'filtWaveform_std'
            spikes = loadSpikes('basename',basename,'clusteringformat',session.spikeSorting{1}.format,'clusteringpath',clusteringpath,'forceReload',true,'spikes',spikes_all,'basepath',basepath);
            %             spikes = GetWaveformsFromDat(spikes,sessionInfo);
            waveforms.filtWaveform = spikes.filtWaveform;
            if ~isfield(spikes,'timeWaveform')
                waveforms.timeWaveform = spikes.timeWaveform;
            else
                waveforms.timeWaveform = repmat({(([1:length(waveforms.filtWaveform{1})]-floor(length(waveforms.filtWaveform{1})/2))/sr)*1000},1,cell_metrics.general.cellCount);
            end
            if isfield(spikes,'filtWaveform_std')
                waveforms.filtWaveform_std = spikes.filtWaveform_std;
            end
            waveforms.peakVoltage = spikes.peakVoltage;
            waveforms.UID = spikes.UID;
        end
        disp('* Calculating waveform classifications: Trough-to-peak latency');
        waveform_metrics = calc_waveform_metrics(waveforms,sr);
        field2remove = {'derivative_TroughtoPeak','filtWaveform','filtWaveform_std','rawWaveform','rawWaveform_std','timeWaveform'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
        
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.waveforms.filt{j} = waveforms.filtWaveform{j};
            if isfield(waveforms,'filtWaveform_std')
                cell_metrics.waveforms.filt_std{j} =  waveforms.filtWaveform_std{j};
            end
            cell_metrics.waveforms.time{j} = waveforms.timeWaveform{j};
            if isfield(spikes,'rawWaveform')
                cell_metrics.waveforms.raw{j} =  spikes.rawWaveform{j};
            end
            if isfield(spikes,'rawWaveform_std')
                cell_metrics.waveforms.raw_std{j} =  spikes.rawWaveform_std{j};
            end
            cell_metrics.peakVoltage(j) = waveforms.peakVoltage(j);
            cell_metrics.troughToPeak(j) = waveform_metrics.troughtoPeak(j);
            cell_metrics.troughtoPeakDerivative(j) = waveform_metrics.derivative_TroughtoPeak(j);
            cell_metrics.ab_ratio(j) = waveform_metrics.ab_ratio(j);
            cell_metrics.polarity(j) = waveform_metrics.polarity(j);
        end
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% PCA features based calculations: Isolation distance and L-ratio
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% if any(contains(metrics,{'PCA_features','all'})) && ~any(contains(excludeMetrics,{'PCA_features'}))
%     disp('* PCA classifications: Isolation distance, L-Ratio')
%     if ~all(isfield(cell_metrics,{'isolationDistance','lRatio'})) || forceReload == true
%         if strcmp(session.spikeSorting{1}.method,{'Neurosuite','KlustaKwik'})
%             PCA_features = LoadNeurosuiteFeatures(spikes,session,excludeIntervals); %(clusteringpath,basename,sr,excludeIntervals);
%             for j = 1:cell_metrics.general.cellCount
%                 cell_metrics.isolationDistance(j) = PCA_features.isolationDistance(find(PCA_features.UID == spikes.UID(j)));
%                 cell_metrics.lRatio(j) = PCA_features.lRatio(find(PCA_features.UID == spikes.UID(j)));
%             end
%         else
%             keyboard
%             getPCAfeatures(session)
%             disp('  No PCAs available')
%         end
%     end
% end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% ACG & CCG based classification
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'acg_metrics','all'})) && ~any(contains(excludeMetrics,{'acg_metrics'}))
    if isfield(cell_metrics, 'acg') && isnumeric(cell_metrics.acg)
        field2remove = {'acg','acg2'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
    end
    if ~all(isfield(cell_metrics,{'acg','thetaModulationIndex','burstIndex_Royer2012','burstIndex_Doublets','acg_tau_decay','acg_tau_rise'})) || forceReload == true
        disp('* CCG classifications: ThetaModulationIndex, BurstIndex_Royer2012, BurstIndex_Doublets')
        acg_metrics = calc_ACG_metrics(spikes);
        
        disp('* Fitting triple exponential to ACG')
        fit_params = fit_ACG(acg_metrics.acg2);
        
        cell_metrics.acg.wide = acg_metrics.acg; % Wide: 1000ms wide CCG with 1ms bins
        cell_metrics.acg.narrow = acg_metrics.acg2; % Narrow: 100ms wide CCG with 0.5ms bins
        cell_metrics.thetaModulationIndex = acg_metrics.thetaModulationIndex; % cell_tmi
        cell_metrics.burstIndex_Royer2012 = acg_metrics.burstIndex_Royer2012; % cell_burstRoyer2012
        cell_metrics.burstIndex_Doublets = acg_metrics.burstIndex_Doublets;
        
        cell_metrics.acg_tau_decay = fit_params.acg_tau_decay;
        cell_metrics.acg_tau_rise = fit_params.acg_tau_rise;
        cell_metrics.acg_c = fit_params.acg_c;
        cell_metrics.acg_d = fit_params.acg_d;
        cell_metrics.acg_asymptote = fit_params.acg_asymptote;
        cell_metrics.acg_refrac = fit_params.acg_refrac;
        cell_metrics.acg_fit_rsquare = fit_params.acg_fit_rsquare;
        cell_metrics.acg_tau_burst = fit_params.acg_tau_burst;
        cell_metrics.acg_h = fit_params.acg_h;
        
        cell_metrics.general.ccg = acg_metrics.ccg;
        cell_metrics.general.ccg_time = acg_metrics.ccg_time;
    end
    if ~all(isfield(cell_metrics,{'acg'}))  || ~isfield(cell_metrics.acg,{'log10'})  || forceReload == true
        disp('* Calculating log10 ACGs')
         acg = calc_logACGs(spikes);
         cell_metrics.acg.log10 = acg.log10;
         cell_metrics.general.acgs.log10 = acg.log10_bins;
    end
    if ~all(isfield(cell_metrics,{'isi'}))  || ~isfield(cell_metrics.isi,{'log10'})  || forceReload == true
        disp('* Calculating log10 ISIs')
        isi = calc_logISIs(spikes);
        cell_metrics.isi.log10 = isi.log10;
        cell_metrics.general.isis.log10 = isi.log10_bins;
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Deep-Superficial by ripple polarity reversal
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'deepSuperficial','all'})) && ~any(contains(excludeMetrics,{'deepSuperficial'}))
    if (~exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file')) && isfield(session.channelTags,'Ripple') && isnumeric(session.channelTags.Ripple.channels)
        disp('* Finding ripples')
        if isfield(session.channelTags,'RippleNoise')
            disp('  Using RippleNoise reference channel')
            RippleNoiseChannel = double(LoadBinary([basename, '.lfp'],'nChannels',session.extracellular.nChannels,'channels',session.channelTags.RippleNoise.channels,'precision','int16','frequency',session.extracellular.srLfp)); % 0.000050354 *
            ripples = bz_FindRipples(basepath,session.channelTags.Ripple.channels-1,'durations',[50 150],'passband',[120 180],'noise',RippleNoiseChannel);
        else
            ripples = bz_FindRipples(basepath,session.channelTags.Ripple.channels-1,'durations',[50 150]);
        end
    end

    deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
    if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file') && (~all(isfield(cell_metrics,{'deepSuperficial','deepSuperficialDistance'})) || forceReload == true)
        disp('* Deep-Superficial by ripple polarity reversal')
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
            cell_metrics.deepSuperficial(j) = deepSuperficial_ChClass(spikes_all.maxWaveformCh1(j)); % cell_deep_superficial OK
            cell_metrics.deepSuperficialDistance(j) = deepSuperficial_ChDistance(spikes_all.maxWaveformCh1(j)); % cell_deep_superficial_distance
        end
    end
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Pytative MonoSynaptic connections
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'monoSynaptic_connections','all'})) && ~any(contains(excludeMetrics,{'monoSynaptic_connections'}))
    disp('* MonoSynaptic connections')
    if ~exist(fullfile(clusteringpath_full,[basename,'.mono_res.cellinfo.mat']),'file')
        spikeIDs = double([spikes.shankID(spikes.spindices(:,2))' spikes.cluID(spikes.spindices(:,2))' spikes.spindices(:,2)]);
        mono_res = ce_MonoSynConvClick(spikeIDs,spikes.spindices(:,1));
        if manualAdjustMonoSyn
            mono_res = gui_MonoSyn(mono_res);
        end
        save(fullfile(clusteringpath_full,[basename,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
    else
        disp('  Loading previous detected MonoSynaptic connections')
        load(fullfile(clusteringpath_full,[basename,'.mono_res.cellinfo.mat']),'mono_res');
        if forceReload == true && manualAdjustMonoSyn
            mono_res = gui_MonoSyn(mono_res);
            save(fullfile(clusteringpath_full,[basename,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
        end
    end
    
    field2remove = {'putativeConnections'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    if ~isempty(mono_res.sig_con)
        cell_metrics.putativeConnections.excitatory = mono_res.sig_con; % Vectors with cell pairs
        cell_metrics.putativeConnections.inhibitory = [];
        cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_metrics.general.cellCount);
        cell_metrics.synapticEffect(cell_metrics.putativeConnections.excitatory(:,1)) = repmat({'Excitatory'},1,size(cell_metrics.putativeConnections.excitatory,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
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
        for i = 1:size(mono_res.sig_con,1)
            rawCCG = round(cell_metrics.general.ccg(:,mono_res.sig_con(i,1),mono_res.sig_con(i,2))*spikes.total(mono_res.sig_con(i,1))*0.001);
            [trans,prob,prob_uncor,pred] = ce_GetTransProb(rawCCG,spikes.total(mono_res.sig_con(i,1)),0.001,0.020);
            cell_metrics.putativeConnections.excitatoryTransProb(i) = trans;
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

if any(contains(metrics,{'theta_metrics','all'})) && ~any(contains(excludeMetrics,{'theta_metrics'})) && exist(fullfile(basepath,[basename,'.animal.behavior.mat']),'file') && isfield(session.channelTags,'Theta') %&& (~isfield(cell_metrics,'thetaEntrainment') || forceReload == true)
    disp('* Theta metrics');
    InstantaneousTheta = calcInstantaneousTheta2(session);
    load(fullfile(basepath,[basename,'.animal.behavior.mat']));
    theta_bins =[-1:0.05:1]*pi;
    cell_metrics.thetaPhasePeak = nan(1,cell_metrics.general.cellCount);
    cell_metrics.thetaPhaseTrough = nan(1,cell_metrics.general.cellCount);
    % cell_metrics.responseCurves.thetaPhase = nan(length(theta_bins)-1,cell_metrics.general.cellCount);
    cell_metrics.thetaEntrainment = nan(1,cell_metrics.general.cellCount);
    
    spikes2 = spikes;
    
    if isfield(cell_metrics,'thetaPhaseResponse')
        cell_metrics = rmfield(cell_metrics,'thetaPhaseResponse');
    end
    
    for j = 1:size(spikes.times,2)
        spikes2.ts{j} = spikes2.ts{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase{session.channelTags.Theta.channels})/session.extracellular.srLfp);
        spikes2.times{j} = spikes2.times{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase{session.channelTags.Theta.channels})/session.extracellular.srLfp);
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

if any(contains(metrics,{'spatial_metrics','all'})) && ~any(contains(excludeMetrics,{'spatial_metrics'}))
    disp('* Spatial metrics');
    field2remove = {'firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMaps','firingRateMap','firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap','FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));

    % General firing rate map
    if exist(fullfile(clusteringpath_full,[basename,'.firingRateMap.firingRateMap.mat']),'file')
        
        temp2 = load(fullfile(clusteringpath_full,[basename,'.firingRateMap.firingRateMap.mat']));
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
                warning(['Number of cells firing rate maps (', num2str(size(firingRateMap.map,2)),  ') does not corresponds to the number of cells in spikes structure (', num2str(size(spikes.UID,2)) ,')' ])
            end
        end
        
    else
        disp('  No *.firingRateMap.firingRateMap.mat file found');
    end
    
    % State dependent firing rate maps
    % e.g. basename.LeftRightRateMap.firingRateMap.mat
    firingRateMap_filelist = dir(fullfile(clusteringpath_full,[basename,'.*.firingRateMap.mat'])); 
    firingRateMap_filelist = {firingRateMap_filelist.name};
    
    for i = 1:length(firingRateMap_filelist)
        
        temp2 = load(fullfile(clusteringpath_full,firingRateMap_filelist{i}));
        firingRateMapName = strsplit(firingRateMap_filelist{i},'.'); 
        firingRateMapName = firingRateMapName{end-2};
%         firingRateMapName = firingRateMap_filelist{i}(1:end-4);
        firingRateMap = temp2.(firingRateMapName);
        if cell_metrics.general.cellCount == size(firingRateMap.map,2) & length(firingRateMap.x_bins) == size(firingRateMap.map{1},1)
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

if any(contains(metrics,{'event_metrics','all'})) && ~any(contains(excludeMetrics,{'event_metrics'}))
    field2remove = {'rippleCorrelogram','events','rippleModulationIndex','ripplePeakDelay'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    disp('* Event metrics')
    eventFiles = dir(fullfile(basepath,[basename,'.*.events.mat']));
    eventFiles = {eventFiles.name};
    eventFiles(find(contains(eventFiles,ignoreEventTypes)))=[];
    
    if ~isempty(eventFiles)
        for i = 1:length(eventFiles)
            eventName = strsplit(eventFiles{i},'.');
            eventName = eventName{end-2};
            eventOut = load(eventFiles{i});
            disp(['  Importing ' eventName]);
            if strcmp(fieldnames(eventOut),eventName)
                if strcmp(eventName,'ripples') && isfield(eventOut.(eventName),'timestamps') && isnumeric(eventOut.(eventName).peaks) && length(eventOut.(eventName).peaks)>0
                    PSTH = calc_PSTH(eventOut.ripples,spikes,'alignment','peaks','duration',0.150,'binCount',150,'smoothing',5,'eventName',eventName);
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
                    PSTH = calc_PSTH(eventOut.(eventName),spikes,'alignment','onset','smoothing',5,'eventName',eventName);
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

if any(contains(metrics,{'manipulation_metrics','all'})) && ~any(contains(excludeMetrics,{'manipulation_metrics'}))
    disp('* Manipulation metrics');
    field2remove = {'manipulations'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    manipulationFiles = dir(fullfile(basepath,[basename,'.*.manipulation.mat']));
    manipulationFiles = {manipulationFiles.name};
    manipulationFiles(find(contains(manipulationFiles,ignoreManipulationTypes)))=[];
    if ~isempty(manipulationFiles)
        for iEvents = 1:length(manipulationFiles)
            eventName = strsplit(manipulationFiles{iEvents},'.'); eventName = eventName{end-2};
            eventOut = load(manipulationFiles{iEvents});
            disp(['  Importing ' eventName]);
            PSTH = calc_PSTH(eventOut.(eventName),spikes_all,'alignment','onset','smoothing',5,'eventName',eventName);
            cell_metrics.manipulations.(eventName) = num2cell(PSTH.responsecurve,1);
            cell_metrics.general.manipulations.(eventName).event_file = manipulationFiles{iEvents};
            cell_metrics.general.manipulations.(eventName).x_bins = PSTH.time*1000;
            cell_metrics.general.manipulations.(eventName).x_label = 'Time (ms)';
            cell_metrics.general.manipulations.(eventName).alignment = PSTH.alignment;
            
            cell_metrics.([eventName,'_modulationIndex']) = PSTH.modulationIndex;
            cell_metrics.([eventName,'_modulationPeakResponseTime']) = PSTH.modulationPeakResponseTime;
            cell_metrics.([eventName,'_modulationSignificanceLevel']) = PSTH.modulationSignificanceLevel;

%             [PSTH,PSTH_time] = calc_PSTH(eventOut.(eventName),spikes,'smoothing',10);
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

if any(contains(metrics,{'state_metrics','all'})) && ~any(contains(excludeMetrics,{'state_metrics'}))
    
    disp('* State metrics');
    statesFiles = dir(fullfile(basepath,[basename,'.*.states.mat']));
    statesFiles = {statesFiles.name};
    statesFiles(find(contains(statesFiles,ignoreStateTypes)))=[];
    if ~isempty(statesFiles)
        for iEvents = 1:length(statesFiles)
            statesName = strsplit(statesFiles{iEvents},'.'); statesName = statesName{end-2};
            eventOut = load(statesFiles{iEvents});
            disp(['  Importing ' statesName]);
            
%             PSTH = calc_PSTH(eventOut.(statesName),spikes,'alignment','onset','smoothing',5,'eventName',statesName);
%             cell_metrics.manipulations.(statesName) = num2cell(PSTH.responsecurve,1);
%             cell_metrics.general.manipulations.(statesName).event_file = statesFiles{iEvents};
%             cell_metrics.general.manipulations.(statesName).x_bins = PSTH.time*1000;
%             cell_metrics.general.manipulations.(statesName).x_label = 'Time (ms)';
%             cell_metrics.general.manipulations.(statesName).alignment = PSTH.alignment;
%             
%             cell_metrics.([statesName,'_modulationIndex']) = PSTH.modulationIndex;
%             cell_metrics.([statesName,'_modulationPeakResponseTime']) = PSTH.modulationPeakResponseTime;
%             cell_metrics.([statesName,'_modulationSignificanceLevel']) = PSTH.modulationSignificanceLevel;
            
            % States specific calculations
            % firing rate
            % CV2
            % burst index
            % isi distribution
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% PSTH metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'psth_metrics','all'})) && ~any(contains(excludeMetrics,{'psth_metrics'}))
    disp('* Perturbation metrics');
    
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
% Custom metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

customCalculationsOptions = what('customCalculations');
customCalculationsOptions = cellfun(@(X) X(1:end-2),customCalculationsOptions.m,'UniformOutput', false);
customCalculationsOptions(strcmpi(customCalculationsOptions,'template')) = [];
for i = 1:length(customCalculationsOptions)
    if any(contains(metrics,{customCalculationsOptions{i},'all'})) && ~any(contains(excludeMetrics,{customCalculationsOptions{i}}))
        disp(['* Custom calculation:' customCalculationsOptions{i}]);
        cell_metrics = customCalculations.(customCalculationsOptions{i})(cell_metrics,session,spikes,spikes_all);
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Import pE and pI classifications from Buzcode (basename.CellClass.cellinfo.mat)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if any(contains(metrics,{'importCellTypeClassification','all'})) && ~any(contains(excludeMetrics,{'importCellTypeClassification'}))
    filename = fullfile(basepath,[basename,'.CellClass.cellinfo.mat']);
    if exist(filename,'file')
        disp('* Importing classified cell types from buzcode');
        temp = load(filename);
        disp(['  Loaded ' filename ' succesfully']);
        if isfield(temp.CellClass,'label') & size(temp.CellClass.label,2) == cell_metrics.general.cellCount
            cell_metrics.CellClassBuzcode = repmat({'Unknown'},1,cell_metrics.general.cellCount);
            for i = 1:cell_metrics.general.cellCount
                if ~isempty(temp.CellClass.label{i})
                    cell_metrics.CellClassBuzcode{i} = temp.CellClass.label{i};
                end
            end
        end
    end
end   

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Other metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

session.general.sessionName = session.general.name;
cell_metrics.sessionName = repmat({session.general.name},1,cell_metrics.general.cellCount);
cell_metrics.sessionType = repmat({session.general.sessionType},1,cell_metrics.general.cellCount);
cell_metrics.animal = repmat({session.animal.name},1,cell_metrics.general.cellCount);

listMetrics = {'sex','species','strain','geneticLine'};
for i = find(isfield(session.animal,listMetrics))
    cell_metrics.(listMetrics{i}) = repmat({session.animal.(listMetrics{i})},1,cell_metrics.general.cellCount);
end
% cell_metrics.promoter = {}; % cell_promoter

% Firing rate across time
firingRateAcrossTime_binsize = 3*60;
if max(cellfun(@max,spikes.times))/firingRateAcrossTime_binsize<40
    firingRateAcrossTime_binsize = ceil((max(cellfun(@max,spikes.times))/40)/10)*10;
end

% Clarning out firingRateAcrossTime
field2remove = {'firingRateAcrossTime'};
test = isfield(cell_metrics,field2remove);
cell_metrics = rmfield(cell_metrics,field2remove(test));
if isfield(cell_metrics.general,'responseCurves')
    test = isfield(cell_metrics.general.responseCurves,field2remove);
    cell_metrics.general.responseCurves = rmfield(cell_metrics.general.responseCurves,field2remove(test));
end
cell_metrics.general.responseCurves.firingRateAcrossTime.x_edges = [0:firingRateAcrossTime_binsize:max(cellfun(@max,spikes.times))];
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
%     if isfield(cell_metrics.general.responseCurves.firingRateAcrossTime,'boundaries')
%         cell_metrics.general.responseCurves.firingRateAcrossTime.boundaries = cumsum(cell_metrics.general.responseCurves.firingRateAcrossTime.boundaries);
%     end
end
% cell_metrics.firingRateAcrossTime = mat2cell(zeros(length(cell_metrics.general.firingRateAcrossTime.x_bins),cell_metrics.general.cellCount));

if isfield(session,'brainRegions') && ~isempty(session.brainRegions)
    chListBrainRegions = findBrainRegion(session);
end

% Spikes metrics
cell_metrics.cellID =  spikes.UID;
cell_metrics.UID =  spikes.UID;
cell_metrics.cluID =  spikes.cluID;
cell_metrics.spikeGroup = spikes.shankID; % cell_spikegroup OK
cell_metrics.maxWaveformCh = spikes.maxWaveformCh1-1; % cell_maxchannel OK
cell_metrics.maxWaveformCh1 = spikes.maxWaveformCh1; % cell_maxchannel OK
cell_metrics.spikeCount = spikes.total; % cell_spikecount OK

% Spike sorting algorithm
if isfield(session.spikeSorting{1},'method')
    cell_metrics.spikeSortingMethod = repmat({session.spikeSorting{1}.method},1,cell_metrics.general.cellCount);
end

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
    if isfield(session,'brainRegions') & ~isempty(session.brainRegions)
        cell_metrics.brainRegion{j} = chListBrainRegions{spikes.maxWaveformCh1(j)}; % cell_brainregion OK
    end
    cell_metrics.maxWaveformChannelOrder(j) = find([session.extracellular.electrodeGroups.channels{:}] == spikes.maxWaveformCh1(j)); %

    % Spike times based metrics
    if ~isempty(excludeIntervals)
        idx = find(any(excludeIntervals' > spikes.times{j}(1)) & any(excludeIntervals' < spikes.times{j}(end)));
        if isempty(idx)
            spike_window = ((spikes.times{j}(end)-spikes.times{j}(1)));
        else
            spike_window = ((spikes.times{j}(end)-spikes.times{j}(1))) - sum(diff(excludeIntervals(idx,:)'));
        end
        cell_metrics.firingRate(j) = spikes.total(j)/spike_window; % cell_firingrate OK
    else
        cell_metrics.firingRate(j) = spikes.total(j)/((spikes.times{j}(end)-spikes.times{j}(1))); % cell_firingrate OK
    end
    
    % Firing rate across time
    temp = histcounts(spikes.times{j},cell_metrics.general.responseCurves.firingRateAcrossTime.x_edges)/firingRateAcrossTime_binsize;
    cell_metrics.responseCurves.firingRateAcrossTime{j} = temp(:);
    cell_metrics.firingRateGiniCoeff(j) = 1-2*sum(temp(:))./length(temp(:));
    cell_metrics.firingRateStd(j) = std(temp(:))./mean(temp(:));
    cell_metrics.firingRateInstability(j) = median(abs(diff(temp(:))))./mean(temp(:));
    
    % CV2
    tau = diff(spikes.times{j});
    cell_metrics.firingRateISI(j) = 1/median(tau);
    CV2_temp = 2*abs(tau(1:end-1) - tau(2:end)) ./ (tau(1:end-1) + tau(2:end));
    cell_metrics.cv2(j) = mean(CV2_temp(CV2_temp<1.95));
    
    % Burstiness_Mizuseki2011
    bursty = [];
    for jj = 2 : length(spikes.times{j}) - 1
        bursty(jj) =  any(diff(spikes.times{j}(jj-1 : jj + 1)) < 0.006);
    end
    cell_metrics.burstIndex_Mizuseki2012(j) = length(find(bursty > 0))/length(bursty); % Fraction of spikes with a ISI for following or preceding spikes < 0.006
    
    % cell_refractoryperiodviolation
    cell_metrics.refractoryPeriodViolation(j) = 1000*length(find(diff(spikes.times{j})<0.002))/spikes.total(j);
end

if ~isfield(cell_metrics,'labels')
    cell_metrics.labels = repmat({''},1,cell_metrics.general.cellCount);
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% cell_classification_putativeCellType
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ~isfield(cell_metrics,'putativeCellType') || ~keepCellClassification
    disp('* Performing Cell-type classification');
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

% Order fields alphabetically
cell_metrics = orderfields(cell_metrics);

% Defines unknown brain region if not defined
if ~isfield(cell_metrics,'brainRegion')
    cell_metrics.brainRegion = repmat({'Unknown'},1,cell_metrics.general.cellCount);
end

disp('* Cleaning metrics')
if any(contains(removeMetrics,{'deepSuperficial'}))
    disp('* Removing deepSuperficial metrics')
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

disp('* Cleaning legacy fields')
field2remove = {'firingRateMap_StimStates','rawWaveform_zscored','firingRateMap_StimStates','acg2_zscored','acg_zscored','filtWaveform_zscored','firingRateAcrossTime','thetaPhaseResponse','firingRateMap_CoolingStates','firingRateMap_LeftRight','firingRateMap','firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap','FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'};
% cleaning cell_metrics
test2 = isfield(cell_metrics,field2remove);
cell_metrics = rmfield(cell_metrics,field2remove(test2));
% cleaning cell_metrics.general
test = isfield(cell_metrics.general,field2remove);
cell_metrics.general = rmfield(cell_metrics.general,field2remove(test));


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Submitting to database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Checks weather db credentials exist
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

if submitToDatabase && enableDatabase
    disp('* Submitting cells to database');
    if debugMode
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
cell_metrics.general.processinginfo.params.metrics = metrics;
cell_metrics.general.processinginfo.params.excludeMetrics = excludeMetrics;
cell_metrics.general.processinginfo.params.removeMetrics = removeMetrics;
cell_metrics.general.processinginfo.params.excludeIntervals = excludeIntervals;
cell_metrics.general.processinginfo.params.ignoreEventTypes = ignoreEventTypes;
cell_metrics.general.processinginfo.params.ignoreManipulationTypes = ignoreManipulationTypes;
cell_metrics.general.processinginfo.params.excludeManipulationIntervals = excludeManipulationIntervals;
cell_metrics.general.processinginfo.params.keepCellClassification = keepCellClassification;
cell_metrics.general.processinginfo.params.forceReload = forceReload;
cell_metrics.general.processinginfo.params.submitToDatabase = submitToDatabase;
cell_metrics.general.processinginfo.params.saveAs = saveAs;
cell_metrics.general.processinginfo.function = 'calc_CellMetrics';
cell_metrics.general.processinginfo.date = now;
cell_metrics.general.processinginfo.version = 2.1;
try
    cell_metrics.general.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    cell_metrics.general.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end
if isfield(spikes,'processinginfo')
    cell_metrics.general.processinginfo.spikes = spikes.processinginfo;
end
if exist('deepSuperficialfromRipple','var') && isfield(deepSuperficialfromRipple,'processinginfo')
    cell_metrics.general.processinginfo.deepSuperficialfromRipple = deepSuperficialfromRipple.processinginfo;
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Saving cells
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if saveMat
    disp(['* Saving cells to: ',saveAsFullfile]);
    save(saveAsFullfile,'cell_metrics','-v7.3','-nocompression')
    disp(['* Saving session struct: ' fullfile(basepath,[basename,'.session.mat'])]);
    save(fullfile(basepath,[basename,'.session.mat']),'session','-v7.3','-nocompression')
end


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Summary figures
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if summaryFigures
    cell_metrics.general.path = clusteringpath_full;
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
    histogram(cell_metrics.spikeGroup,[0:14]+0.5),xlabel('Spike groups'), ylabel('Count')
    
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
        fig = figure('Name',['Deep-Superficial assignment'],'pos',[50,50,1000,800]);
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

disp(['* Cell metrics calculations complete. Elapsed time is ', num2str(toc(timerCalcMetrics),5),' seconds.'])
