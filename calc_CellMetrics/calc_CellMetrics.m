function cell_metrics = calc_CellMetrics(varargin)
%   This function calculates cell metrics for a given recording/session
%   Most metrics are single value per cell, either numeric or string type, but
%   certain metrics are vectors like the autocorrelograms or cell with double content like waveforms.
%   The metrics are based on a number of features: Spikes, Waveforms, PCA features,
%   the ACG and CCGs, LFP, theta, ripples and so fourth
%
%   Check the wiki of the Cell Explorer for more details: https://github.com/petersenpeter/Cell-Explorer/wiki
%
%   INPUTS
%   id                     - Takes a database id as input
%   session                - Takes a database sessionName as input
%   sessionStruct          - Takes a sessio struct as input
%   basepath               - Path to session (base directory)
%   clusteringpath         - Path to cluster data if different from basepath
%   showGUI                - Show GUI dialog to adjust settings/parameters
%   metrics                - Metrics that will be calculated. A cell with strings
%   Examples:                'waveform_metrics','PCA_features','acg_metrics','c',
%                            'ripple_metrics','monoSynaptic_connections','spatial_metrics'
%                            'perturbation_metrics','theta_metrics','psth_metrics'
%   excludeMetrics         - Metrics to exclude
%   removeMetrics          - Metrics to remove (supports only deepSuperficial at this point)
%   keepCellClassification - Keep existing cell type classifications
%   manuelAdjustMonoSyn    - Manually adjust monosynaptic connections in the pipeline (requires user input)
%   timeRestriction        - Any time intervals to exclude
%   useNeurosuiteWaveforms - Use Neurosuite files to get waveforms and PCAs
%   showGUI                - Show a GUI that allows you to adjust the input parameters/settings
%   forceReload            - logical. Recalculate existing metrics
%   submitToDatabase       - logical. Submit cell metrics to database
%   saveMat                - Save metrics to cell_metrics.mat
%   saveAs                 - name of .mat file
%   plots                  - logical. Plot summary figures
%
%   OUTPUT
%   Cell_metrics matlab structure

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 14-06-2019

% TODO
% Standardize tracking data
% Standardize stimulation/event data


%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Parsing parameters
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'sessionStruct',[],@isstruct);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'metrics','all',@iscellstr);
addParameter(p,'excludeMetrics',{'none'},@iscellstr);
addParameter(p,'removeMetrics',{'none'},@isstr);
addParameter(p,'timeRestriction',[],@isnumeric);
addParameter(p,'useNeurosuiteWaveforms',false,@islogical);
addParameter(p,'keepCellClassification',true,@islogical);
addParameter(p,'manuelAdjustMonoSyn',true,@islogical);
addParameter(p,'showGUI',true,@islogical);

addParameter(p,'forceReload',false,@islogical);
addParameter(p,'submitToDatabase',true,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','cell_metrics',@isstr);
addParameter(p,'plots',true,@islogical);

parse(p,varargin{:})

id = p.Results.id;
sessionin = p.Results.session;
sessionStruct = p.Results.sessionStruct;
basepath = p.Results.basepath;
clusteringpath = p.Results.clusteringpath;
metrics = p.Results.metrics;
excludeMetrics = p.Results.excludeMetrics;
removeMetrics = p.Results.removeMetrics;
timeRestriction = p.Results.timeRestriction;
useNeurosuiteWaveforms = p.Results.useNeurosuiteWaveforms;
keepCellClassification = p.Results.keepCellClassification;
manuelAdjustMonoSyn = p.Results.manuelAdjustMonoSyn;
showGUI = p.Results.showGUI;

forceReload = p.Results.forceReload;
submitToDatabase = p.Results.submitToDatabase;
saveMat = p.Results.saveMat;
saveAs = p.Results.saveAs;
plots = p.Results.plots;
timerCalcMetrics = tic;

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading session metadata from DB or sessionStruct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if ~isempty(id) || ~isempty(sessionin) || ~isempty(sessionStruct)
    bz_database = db_credentials;
    if ~isempty(id)
        [session, basename, basepath, clusteringpath] = db_set_path('id',id);
    elseif ~isempty(sessionin)
        [session, basename, basepath, clusteringpath] = db_set_path('session',sessionin);
    elseif ~isempty(sessionStruct)
        showGUI = true;
        if isfield(sessionStruct.general,'basePath') && isfield(sessionStruct.general,'clusteringPath')
            session = sessionStruct;
            basename = session.general.name;
            basepath = session.general.basePath;
            clusteringpath = session.general.clusteringPath;
        else
            [session, basename, basepath, clusteringpath] = db_set_path('sessionstruct',sessionStruct);
            if isempty(session.general.entryID)
                session.general.entryID = ''; % DB id
            end
            if isempty(session.spikeSorting.entryIDs)
                session.spikeSorting.entryIDs(1) = ''; % DB id
            end
        end
    else
        warning('Please provide a session struct or a session name/id to load a session from the DB')
    end
end
% If no session struct is provided the template is loaded and the GUI is displayed
if ~exist('session','var')
    session = sessionTemplate;
    showGUI = true;
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% showGUI
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if showGUI
    parameters = p.Results;
    parameters.basepath = basepath;
    parameters.clusteringpath = clusteringpath;
    
    % Non-standard parameters: probeSpacing and probeLayout
    if ~isfield(session.extracellular,'probesVerticalSpacing') & ~isfield(session.extracellular,'probesLayout')
        session = determineProbeSpacing(session);
    end
    [session,parameters,status] = calc_CellMetrics_GUI(session,parameters);
    if status==0
        disp('Metrics calculations canceled by user')
        return
    end
    basename = session.general.name;
    basepath = session.general.basePath;
    clusteringpath = session.general.clusteringPath;
    cd(basepath)
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Getting spikes
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

sr = session.extracellular.sr;
srLfp = session.extracellular.srLfp;

spikes = loadClusteringData(clusteringpath,session.spikeSorting.format{1},'basepath',basepath,'basename',basename,'LSB',session.extracellular.leastSignificantBit);

if ~isfield(spikes,'processinginfo') || ~isfield(spikes.processinginfo.params,'WaveformsSource') || ~strcmp(spikes.processinginfo.params.WaveformsSource,'dat file') || spikes.processinginfo.version<3.4
    spikes = loadClusteringData(clusteringpath,session.spikeSorting.format{1},'basepath',basepath,'basename',basename,'forceReload',true,'spikes',spikes,'LSB',session.extracellular.leastSignificantBit);
end

if ~isempty(timeRestriction)
    if size(timeRestriction,2) ~= 2
        error('timeRestriction has to be a Nx2 matrix')
    else
        for j = 1:size(spikes.times,2)
            indeces2keep = [];
            indeces2keep = find(any(spikes.times{j} >= timeRestriction(:,1)' & spikes.times{j} <= timeRestriction(:,2)', 2));
            spikes.ts{j} =  spikes.ts{j}(indeces2keep);
            spikes.times{j} =  spikes.times{j}(indeces2keep);
            spikes.ids{j} =  spikes.ids{j}(indeces2keep);
            spikes.amplitudes{j} =  spikes.amplitudes{j}(indeces2keep);
            spikes.total(j) =  length(indeces2keep);
        end
        indeces2keep = any(spikes.spindices(:,1) >= timeRestriction(:,1)' & spikes.spindices(:,1) <= timeRestriction(:,2)', 2);
        spikes.spindices = spikes.spindices(indeces2keep,:);
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Initializing cell_metrics struct
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if exist(fullfile(clusteringpath,[saveAs,'.mat']),'file')
    disp(['Loading existing metrics: ' saveAs])
    load(fullfile(clusteringpath,[saveAs,'.mat']))
else
    cell_metrics = [];
end

cell_metrics.general.basepath = basepath;
cell_metrics.general.basename = basename;
cell_metrics.general.clusteringpath = clusteringpath;
cell_metrics.general.cellCount = length(spikes.total);

% if isfield(cell_metrics,'PutativeCellType')
%     cell_metrics.putativeCellType = cell_metrics.PutativeCellType;
% end
% listSubfields = fieldnames(cell_metrics);
% for i = 1:length(listSubfields)
%     isUpperCase = isstrprop(listSubfields{i},'upper');
%     if isUpperCase(1)==1
%         cell_metrics = rmfield(cell_metrics,listSubfields{i});
%     end
% end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Waveform based calculations
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'waveform_metrics','all'})) && ~any(contains(excludeMetrics,{'waveform_metrics'}))
    if ~all(isfield(cell_metrics,{'filtWaveform','timeWaveform','filtWaveform_std','peakVoltage','troughToPeak','troughtoPeakDerivative','ab_ratio'})) || forceReload == true
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
        elseif useNeurosuiteWaveforms
            waveforms = LoadNeurosuiteWaveforms(spikes,session,timeRestriction);
        elseif any(~isfield(spikes,{'filtWaveform','peakVoltage','cluID'})) % ,'filtWaveform_std'
            spikes = loadClusteringData(basename,session.spikeSorting.format{1},clusteringpath,'forceReload',true,'spikes',spikes,'basepath',basepath);
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
        field2remove = {'derivative_TroughtoPeak','filtWaveform','filtWaveform_std'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.filtWaveform{j} = waveforms.filtWaveform{j};
            if isfield(waveforms,'filtWaveform_std')
                cell_metrics.filtWaveform_std{j} =  waveforms.filtWaveform_std{j};
            end
            cell_metrics.timeWaveform{j} = waveforms.timeWaveform{j};
            if isfield(spikes,'rawWaveform')
                cell_metrics.rawWaveform{j} =  spikes.rawWaveform{j};
            end
            if isfield(spikes,'rawWaveform_std')
                cell_metrics.rawWaveform_std{j} =  spikes.rawWaveform_std{j};
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
% PCA features based calculations
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'PCA_features','all'})) && ~any(contains(excludeMetrics,{'PCA_features'}))
    disp('* Calculating PCA classifications: Isolation distance, L-Ratio')
    if ~all(isfield(cell_metrics,{'isolationDistance','lRatio'})) || forceReload == true
        if useNeurosuiteWaveforms
            PCA_features = LoadNeurosuiteFeatures(spikes,session,timeRestriction); %(clusteringpath,basename,sr,timeRestriction);
            for j = 1:cell_metrics.general.cellCount
                cell_metrics.isolationDistance(j) = PCA_features.isolationDistance(find(PCA_features.UID == spikes.UID(j)));
                cell_metrics.lRatio(j) = PCA_features.lRatio(find(PCA_features.UID == spikes.UID(j)));
            end
        else
            disp('  No PCAs available')
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% ACG & CCG based classification
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'acg_metrics','all'})) && ~any(contains(excludeMetrics,{'acg_metrics'}))
    if ~all(isfield(cell_metrics,{'acg','acg2','thetaModulationIndex','burstIndex_Royer2012','burstIndex_Doublets','acg_tau_decay','acg_tau_rise'})) || forceReload == true
        disp('* Calculating CCG classifications: ThetaModulationIndex, BurstIndex_Royer2012, BurstIndex_Doublets')
        acg_metrics = calc_ACG_metrics(spikes);%(clusteringpath,sr,timeRestriction);
        
        disp('* Fitting double exponential to ACG')
        fit_params = fit_ACG(acg_metrics.acg2);
        
        cell_metrics.acg = acg_metrics.acg; % Wide: 1000ms wide CCG with 1ms bins
        cell_metrics.acg2 = acg_metrics.acg2; % Narrow: 100ms wide CCG with 0.5ms bins
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
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Deep-Superficial by ripple polarity reversal
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'deepSuperficial','all'})) && ~any(contains(excludeMetrics,{'deepSuperficial'}))
    disp('* Deep-Superficial by ripple polarity reversal')
    %     lfpExtension = exist_LFP(basepath,basename);
    
    if (~exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file') || forceReload == true)
        lfpExtension = exist_LFP(basepath,basename);
        if isfield(session.channelTags,'RippleNoise') & isfield(session.channelTags,'Ripple')
            disp('  Using RippleNoise reference channel')
            RippleNoiseChannel = double(LoadBinary([basename, lfpExtension],'nChannels',session.extracellular.nChannels,'channels',session.channelTags.RippleNoise.channels,'precision','int16','frequency',session.extracellular.srLfp)); % 0.000050354 *
            ripples = bz_FindRipples('basepath',basepath,'channel',session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.9,'noise',RippleNoiseChannel);
        elseif isfield(session.channelTags,'Ripple')
            ripples = bz_FindRipples('basepath',basepath,'channel',session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.5);
        else
            warning('Ripple')
        end
    end
    
    deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
    if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file') & (~all(isfield(cell_metrics,{'deepSuperficial','deepSuperficialDistance'})) || forceReload == true)
        lfpExtension = exist_LFP(basepath,basename);
        if ~exist(deepSuperficial_file,'file')
            if ~isfield(session.extracellular,'probesVerticalSpacing') & ~isfield(session.extracellular,'probesLayout')
                session = determineProbeSpacing(session);
            end
            classification_DeepSuperficial(session)
        end
        load(deepSuperficial_file)
        cell_metrics.general.SWR = deepSuperficialfromRipple;
        deepSuperficial_ChDistance = deepSuperficialfromRipple.channelDistance; %
        deepSuperficial_ChClass = deepSuperficialfromRipple.channelClass;% cell_deep_superficial
        cell_metrics.general.deepSuperficial_file = deepSuperficial_file;
        
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.deepSuperficial(j) = deepSuperficial_ChClass(spikes.maxWaveformCh1(j)); % cell_deep_superficial OK
            cell_metrics.deepSuperficialDistance(j) = deepSuperficial_ChDistance(spikes.maxWaveformCh(j)+1); % cell_deep_superficial_distance
        end
    end
    
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Ripple modulation
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'ripple_metrics','all'})) && ~any(contains(excludeMetrics,{'ripple_metrics'}))
    disp('* Calculating ripple metrics')
    if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file')
        lfpExtension = exist_LFP(basepath,basename);
        load(fullfile(basepath,[basename,'.ripples.events.mat']));
        [PSTH,PSTH_time] = calc_PSTH(ripples.peaks,spikes);
        [rippleModulationIndex,ripplePeakDelay,rippleCorrelogram] = calc_RippleModulationIndex(PSTH,PSTH_time);
        cell_metrics.rippleModulationIndex = rippleModulationIndex; % cell_ripple_modulation
        cell_metrics.ripplePeakDelay = ripplePeakDelay; % cell_ripple_peak_delay
        cell_metrics.rippleCorrelogram = num2cell(rippleCorrelogram,1);
        cell_metrics.general.rippleCorrelogram.event_file = fullfile(basepath,[basename,'.ripples.events.mat']);
        cell_metrics.general.rippleCorrelogram.x_bins = PSTH_time*1000;
        cell_metrics.general.rippleCorrelogram.x_label = 'Time (ms)';
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Pytative MonoSynaptic connections
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'monoSynaptic_connections','all'})) && ~any(contains(excludeMetrics,{'monoSynaptic_connections'}))
    disp('* Calculating MonoSynaptic connections')
    if ~exist(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat']),'file') || forceReload == true
        spikeIDs = [spikes.shankID(spikes.spindices(:,2))' spikes.cluID(spikes.spindices(:,2))' spikes.spindices(:,2)];
        mono_res = bz_MonoSynConvClick(spikeIDs,spikes.spindices(:,1),'plot',manuelAdjustMonoSyn);
        save(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
    else
        disp('  Loading previous detected MonoSynaptic connections')
        load(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat']),'mono_res');
    end
    
    if ~isempty(mono_res.sig_con)
        cell_metrics.putativeConnections = mono_res.sig_con; % Vectors with cell pairs
        cell_metrics.synapticEffect = repmat({'Unknown'},1,cell_metrics.general.cellCount);
        cell_metrics.synapticEffect(cell_metrics.putativeConnections(:,1)) = repmat({'Excitatory'},1,size(cell_metrics.putativeConnections,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
        cell_metrics.synapticConnectionsOut = zeros(1,cell_metrics.general.cellCount);
        cell_metrics.synapticConnectionsIn = zeros(1,cell_metrics.general.cellCount);
        [a,b]=hist(cell_metrics.putativeConnections(:,1),unique(cell_metrics.putativeConnections(:,1)));
        cell_metrics.synapticConnectionsOut(b) = a; cell_metrics.synapticConnectionsOut = cell_metrics.synapticConnectionsOut(1:cell_metrics.general.cellCount);
        [a,b]=hist(cell_metrics.putativeConnections(:,2),unique(cell_metrics.putativeConnections(:,2)));
        cell_metrics.synapticConnectionsIn(b) = a; cell_metrics.synapticConnectionsIn = cell_metrics.synapticConnectionsIn(1:cell_metrics.general.cellCount);
        %         cell_metrics.truePositive = mono_res.truePositive; % Matrix
        %         cell_metrics.falsePositive = mono_res.falsePositive; % Matrix
    else
        cell_metrics.putativeConnections = [];
        cell_metrics.synapticConnectionsOut = zeros(1,cell_metrics.general.cellCount);
        cell_metrics.synapticConnectionsIn = zeros(1,cell_metrics.general.cellCount);
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Theta related activity
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'theta_metrics','all'})) && ~any(contains(excludeMetrics,{'theta_metrics'}))
    disp('* Calculating theta metrics');
    if exist(fullfile(basepath,'animal.mat'),'file')
        lfpExtension = exist_LFP(basepath,basename);
        InstantaneousTheta = calcInstantaneousTheta2(session);
        load(fullfile(basepath,'animal.mat'));
        theta_bins =[-1:0.05:1]*pi;
        cell_metrics.thetaPhasePeak = nan(1,cell_metrics.general.cellCount);
        cell_metrics.thetaPhaseTrough = nan(1,cell_metrics.general.cellCount);
        %         cell_metrics.thetaPhaseResponse = nan(length(theta_bins)-1,cell_metrics.general.cellCount);
        cell_metrics.thetaEntrainment = nan(1,cell_metrics.general.cellCount);
        
        spikes2 = spikes;
        
        if isfield(cell_metrics,'thetaPhaseResponse')
            cell_metrics = rmfield(cell_metrics,'thetaPhaseResponse');
        end
        
        for j = 1:size(spikes.times,2)
            spikes2.ts{j} = spikes2.ts{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase)/srLfp);
            spikes2.times{j} = spikes2.times{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase)/srLfp);
            spikes2.ts_eeg{j} = ceil(spikes2.ts{j}/16);
            spikes2.theta_phase{j} = InstantaneousTheta.signal_phase(spikes2.ts_eeg{j});
            spikes2.speed{j} = interp1(animal.time,animal.speed,spikes2.times{j});
            if sum(spikes2.speed{j} > 10)> 500
                
                [counts,centers] = histcounts(spikes2.theta_phase{j}(spikes2.speed{j} > 10),theta_bins, 'Normalization', 'probability');
                counts = nanconv(counts,[1,1,1,1,1]/5,'edge');
                [~,tem2] = max(counts);
                [~,tem3] = min(counts);
                cell_metrics.thetaPhaseResponse{j} = counts';
                cell_metrics.thetaPhasePeak(j) = centers(tem2)+diff(centers([1,2]))/2;
                cell_metrics.thetaPhaseTrough(j) = centers(tem3)+diff(centers([1,2]))/2;
                cell_metrics.thetaEntrainment(j) = max(counts)/min(counts);
            else
                cell_metrics.thetaPhaseResponse{j} = nan(length(theta_bins)-1,1);
            end
        end
        cell_metrics.general.thetaPhaseResponse.x_bins = theta_bins(1:end-1)+diff(theta_bins([1,2]))/2;
        
        figure, subplot(2,2,1)
        plot(cell_metrics.general.thetaPhaseResponse.x_bins,horzcat(cell_metrics.thetaPhaseResponse{:})),title('Theta entrainment during locomotion'), xlim([-1,1]*pi)
        subplot(2,2,2)
        plot(cell_metrics.thetaPhaseTrough,cell_metrics.thetaPhasePeak,'o'),xlabel('Trough'),ylabel('Peak')
        subplot(2,2,3)
        histogram(cell_metrics.thetaEntrainment,30),title('Theta entrainment')
        subplot(2,2,4)
        histogram(cell_metrics.thetaPhaseTrough,[-1:0.2:1]*pi),title('Theta trough and peak'), hold on
        histogram(cell_metrics.thetaPhasePeak,[-1:0.2:1]*pi), legend({'Trough','Peak'})
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Spatial related metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'spatial_metrics','all'})) && ~any(contains(excludeMetrics,{'spatial_metrics'}))
    disp('* Calculating spatial metrics');
    field2remove = {'firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate','FiringRateMap','FiringRateMap_CoolingStates','FiringRateMap_StimStates','FiringRateMap_LeftRight'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    
    % General firing rate map
    if exist(fullfile(basepath,'firingRateMap.mat'),'file')
        temp2 = load(fullfile(basepath,'firingRateMap.mat'));
        disp('  Loaded firingRateMap.mat succesfully');
        if isfield(temp2,'firingRateMap')
            firingRateMap = temp2.firingRateMap;
            
            if cell_metrics.general.cellCount == length(firingRateMap.total)
                cell_metrics.firingRateMap = num2cell(firingRateMap.unit,1);
                cell_metrics.spatialPeakRate = max(firingRateMap.unit);
                if isfield(firingRateMap,'x_bins')
                    cell_metrics.general.firingRateMap.x_bins = firingRateMap.x_bins;
                end
                if isfield(firingRateMap,'boundaries')
                    cell_metrics.general.firingRateMap.boundaries = firingRateMap.boundaries;
                end
                
                cell_metrics.general.firingRateMap.x_bins = firingRateMap.x_bins;
                cell_metrics.general.firingRateMap.boundaries = firingRateMap.boundaries;
                
                for j = 1:cell_metrics.general.cellCount
                    temp = place_cell_condition(firingRateMap.unit(:,j)');
                    cell_metrics.spatialCoherence(j) = temp.SpatialCoherence;
                    cell_metrics.placeCell(j) = temp.condition;
                    cell_metrics.placeFieldsCount(j) = temp.placefield_count;
                    temp3 = cumsum(sort(firingRateMap.unit(:,j),'descend'));
                    if ~all(temp3==0)
                        cell_metrics.spatialCoverageIndex(j) = find(temp3>0.75*temp3(end),1)/(length(temp3)*0.75); % Spatial coverage index (Royer, NN 2012)
                        cum_firing1 = cumsum(sort(firingRateMap.unit(:,j)));
                        cum_firing1 = cum_firing1/max(cum_firing1);
                        cell_metrics.spatialGiniCoeff(j) = 1-2*sum(cum_firing1)./length(cum_firing1);
                    else
                        cell_metrics.spatialCoverageIndex(j) = nan;
                        cell_metrics.spatialGiniCoeff(j) = nan;
                    end
                end
                disp('  Spatial metrics succesfully calculated');
            else
                warning(['Number of cells firing rate maps (', num2str(size(firingRateMap.unit,2)),  ') does not corresponds to the number of cells in spikes structure (', num2str(size(spikes.UID,2)) ,')' ])
            end
        end
        
    else
        disp('  No firingRateMap.mat file found');
    end
    
    % State dependent firing rate maps
    firingRateMap_filelist = dir(fullfile(basepath,'firingRateMap_*.mat')); firingRateMap_filelist = {firingRateMap_filelist.name};
    
    for i = 1:length(firingRateMap_filelist)
        temp2 = load(fullfile(basepath,firingRateMap_filelist{i}));
        firingRateMapName = firingRateMap_filelist{i}(1:end-4);
        disp(['  Loaded ' firingRateMap_filelist{i} ' succesfully']);
        firingRateMap = temp2.(firingRateMapName);
        if cell_metrics.general.cellCount == size(firingRateMap.unit,2) & length(firingRateMap.x_bins) == size(firingRateMap.unit,1)
            cell_metrics.(firingRateMapName){1} = firingRateMap.unit;
            if isfield(firingRateMap,'x_bins')
                cell_metrics.general.(firingRateMapName).x_bins = firingRateMap.x_bins;
            end
            if isfield(firingRateMap,'x_label')
                cell_metrics.general.(firingRateMapName).x_label = firingRateMap.x_label;
            end
            if isfield(firingRateMap,'boundaries')
                cell_metrics.general.(firingRateMapName).boundaries = firingRateMap.boundaries;
            end
            if isfield(firingRateMap,'labels')
                cell_metrics.general.(firingRateMapName).labels = firingRateMap.labels;
            end
            if isfield(firingRateMap,'boundaries_labels')
                cell_metrics.general.(firingRateMapName).boundaries_labels = firingRateMap.boundaries_labels;
            end
        end
    end
    
    if isfield(cell_metrics,'firingRateMap_LeftRight')
        if isfield(firingRateMap,'splitter_bins')
            splitter_bins = firingRateMap.splitter_bins;
            cell_metrics.general.(firingRateMapName).splitter_bins = firingRateMap.splitter_bins;
        else
            splitter_bins = find( cell_metrics.general.firingRateMap_LeftRight.x_bins < cell_metrics.general.firingRateMap_LeftRight.boundaries(1) );
            cell_metrics.general.(firingRateMapName).splitter_bins = splitter_bins;
        end
        splitter_bins = find( cell_metrics.general.firingRateMap_LeftRight.x_bins < cell_metrics.general.firingRateMap_LeftRight.boundaries(1) );
        for j = 1:cell_metrics.general.cellCount
            cell_metrics.spatialSplitterDegree(j) = sum(abs(cell_metrics.firingRateMap_LeftRight{1}(splitter_bins,j,1) - cell_metrics.firingRateMap_LeftRight{1}(splitter_bins,j,2)))/sum(cell_metrics.firingRateMap_LeftRight{1}(splitter_bins,j,1) + cell_metrics.firingRateMap_LeftRight{1}(splitter_bins,j,2) + length(splitter_bins));
        end
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Perturbation metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'perturbation_metrics','all'})) && ~any(contains(excludeMetrics,{'perturbation_metrics'}))
    if exist(fullfile(basepath,'optogenetics.mat'),'file')
        disp('* Calculating perturbation metrics');
        spikes2 = loadClusteringData(basename,session.spikeSorting.format{1},clusteringpath,1,'basepath',basepath);
        if isfield(cell_metrics,'optoPSTH')
            cell_metrics = rmfield(cell_metrics,'optoPSTH');
        end
        cell_metrics.psth_optostim = [];
        temp = load('optogenetics.mat');
        trigger = temp.optogenetics.peak;
        edges = [-1:0.1:1];
        for j = 1:cell_metrics.general.cellCount
            psth = zeros(size(edges));
            for jj = 1:length(trigger)
                psth = psth + histc(spikes2.times{j}'-trigger(jj),edges);
            end
            cell_metrics.psth_optostim{j} = (psth(1:end-1)/length(trigger))/0.1;
            cell_metrics.psth_optostim{j} = cell_metrics.psth_optostim{j}(:);
        end
        
        cell_metrics.general.psth_optostim.x_label = 'Time (s)';
        cell_metrics.general.psth_optostim.x_bins = edges(1:end-1)+(edges(2)-edges(1))/2;
        figure, plot(cell_metrics.general.psth_optostim.x_bins, horzcat(cell_metrics.psth_optostim{:}))
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% PSTH metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if any(contains(metrics,{'psth_metrics','all'})) && ~any(contains(excludeMetrics,{'psth_metrics'}))
    disp('* Calculating perturbation metrics');
    
    % PSTH response
    psth_filelist = dir(fullfile(basepath,'psth_*.mat')); psth_filelist = {psth_filelist.name};
    
    for i = 1:length(psth_filelist)
        temp2 = load(fullfile(basepath,psth_filelist{i}));
        psth_type = psth_filelist{i}(1:end-4);
        disp(['  Loaded ' psth_filelist{i} ' succesfully']);
        psth_response = temp2.(psth_type);
        if cell_metrics.general.cellCount == size(psth_response.unit,2) & length(psth_response.x_bins) == size(psth_response.unit,1)
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
% Other metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
session.general.sessionName = session.general.name;
listMetrics = {'animal','sex','species','strain','geneticLine','sessionName'};
for i = find(isfield(session.general,listMetrics))
    cell_metrics.(listMetrics{i}) = repmat({session.general.(listMetrics{i})},1,cell_metrics.general.cellCount);
end
% cell_metrics.promoter = {}; % cell_promoter

% Firing rate across time
firingRateAcrossTime_binsize = 3*60;
if max(cellfun(@max,spikes.times))/firingRateAcrossTime_binsize<40
    firingRateAcrossTime_binsize = ceil((max(cellfun(@max,spikes.times))/40)/10)*10;
end
cell_metrics.general.firingRateAcrossTime.x_edges = [0:firingRateAcrossTime_binsize:max(cellfun(@max,spikes.times))];
cell_metrics.general.firingRateAcrossTime.x_bins = cell_metrics.general.firingRateAcrossTime.x_edges(1:end-1)+firingRateAcrossTime_binsize/2;
cell_metrics.general.firingRateAcrossTime.boundaries = cumsum(session.epochs.duration);
cell_metrics.general.firingRateAcrossTime.boundaries_labels = session.epochs.behavioralParadigm;
% cell_metrics.firingRateAcrossTime = mat2cell(zeros(length(cell_metrics.general.firingRateAcrossTime.x_bins),cell_metrics.general.cellCount));

chListBrainRegions = findBrainRegion(session);

for j = 1:cell_metrics.general.cellCount
    cell_metrics.sessionID(j) = str2num(session.general.entryID); % cell_sessionid OK
    cell_metrics.spikeSortingID(j) = session.spikeSorting.entryIDs(1); % cell_spikesortingid OK
    cell_metrics.cellID(j) =  spikes.UID(j); % cell_id OK
    cell_metrics.UID(j) =  spikes.UID(j); % cell_id OK
    cell_metrics.cluID(j) =  spikes.cluID(j); % cell_sortingid OK
    cell_metrics.brainRegion{j} = chListBrainRegions{spikes.maxWaveformCh1(j)}; % cell_brainregion OK
    cell_metrics.spikeGroup(j) = spikes.shankID(j); % cell_spikegroup OK
    cell_metrics.maxWaveformCh(j) = spikes.maxWaveformCh1(j)-1; % cell_maxchannel OK
    cell_metrics.maxWaveformCh1(j) = spikes.maxWaveformCh1(j); % cell_maxchannel OK
    
    % Spike times based metrics
    cell_metrics.spikeCount(j) = spikes.total(j); % cell_spikecount OK
    if ~isempty(timeRestriction)
        timeRestriction_start = max(find( timeRestriction(:,1) < spikes.times{j}(1)));
        timeRestriction_end = min(find( timeRestriction(:,2) > spikes.times{j}(end)));
        spike_window = sum(diff(timeRestriction(timeRestriction_start:timeRestriction_end,:)'));
        spike_window = spike_window - (spikes.times{j}(1)) - timeRestriction(timeRestriction_start,1);
        spike_window = spike_window - (timeRestriction(timeRestriction_end,2)-spikes.times{j}(end));
        
        cell_metrics.firingRate(j) = spikes.total(j)/spike_window; % cell_firingrate OK
    else
        cell_metrics.firingRate(j) = spikes.total(j)/((spikes.times{j}(end)-spikes.times{j}(1))); % cell_firingrate OK
    end
    
    % Firing rate across time
    temp = histcounts(spikes.times{j},cell_metrics.general.firingRateAcrossTime.x_edges)/firingRateAcrossTime_binsize;
    cell_metrics.firingRateAcrossTime{j} = temp(:);
    
    % CV2
    tau = diff(spikes.times{j});
    cell_metrics.firingRateISI(j) = 1/median(tau);
    CV2_temp = 2*abs(tau(1:end-1) - tau(2:end)) ./ (tau(1:end-1) + tau(2:end));
    cell_metrics.cv2(j) = mean(CV2_temp(CV2_temp<1.9));
    
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
    cell_metrics.putativeCellType = repmat({'Pyramidal Cell'},1,cell_metrics.general.cellCount);
    
    % Interneuron classification
    cell_metrics.putativeCellType(cell_metrics.acg_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_decay>30),1);
    cell_metrics.putativeCellType(cell_metrics.acg_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.acg_tau_rise>3),1);
    cell_metrics.putativeCellType(cell_metrics.troughToPeak<=0.425) = repmat({'Interneuron'},sum(cell_metrics.troughToPeak<=0.425),1);
    cell_metrics.putativeCellType(cell_metrics.troughToPeak<=0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.troughToPeak<=0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
    cell_metrics.putativeCellType(cell_metrics.troughToPeak>0.425  & ismember(cell_metrics.putativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.troughToPeak>0.425  & (ismember(cell_metrics.putativeCellType, 'Interneuron'))),1);
    
    % Pyramidal cell classification
    %     cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative<0.17 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 2'},sum(cell_metrics.troughtoPeakDerivative<0.17 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
    %     cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative>0.3 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 3'},sum(cell_metrics.troughtoPeakDerivative>0.3 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
    %     cell_metrics.putativeCellType(cell_metrics.troughtoPeakDerivative>=0.17 & cell_metrics.troughtoPeakDerivative<=0.3 & ismember(cell_metrics.putativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 1'},sum(cell_metrics.troughtoPeakDerivative>=0.17 & cell_metrics.troughtoPeakDerivative<=0.3 & (ismember(cell_metrics.putativeCellType, 'Pyramidal Cell'))),1);
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Cleaning metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
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

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Submitting to database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if submitToDatabase
    disp('* Submitting cells to database');
    try
        session = db_update_session(session,'forceReload',true);
        cell_metrics = db_submit_cells(cell_metrics,session);
    catch exception
        disp(exception.identifier)
        warning('Failed to submit to database');
    end
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Adding processing info
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
cell_metrics.general.processinginfo.params.metrics = metrics;
cell_metrics.general.processinginfo.params.excludeMetrics = excludeMetrics;
cell_metrics.general.processinginfo.params.removeMetrics = removeMetrics;
cell_metrics.general.processinginfo.params.timeRestriction = timeRestriction;
cell_metrics.general.processinginfo.params.keepCellClassification = keepCellClassification;
cell_metrics.general.processinginfo.params.useNeurosuiteWaveforms = useNeurosuiteWaveforms;
cell_metrics.general.processinginfo.params.forceReload = forceReload;
cell_metrics.general.processinginfo.params.submitToDatabase = submitToDatabase;
cell_metrics.general.processinginfo.params.saveAs = saveAs;
cell_metrics.general.processinginfo.function = 'calc_CellMetrics';
cell_metrics.general.processinginfo.date = now;
cell_metrics.general.processinginfo.version = 1.0;
if isfield(spikes,'processinginfo')
    cell_metrics.general.processinginfo.spikes = spikes.processinginfo;
end
if exist('deepSuperficialfromRipple') && isfield(deepSuperficialfromRipple,'processinginfo')
    cell_metrics.general.processinginfo.deepSuperficialfromRipple = deepSuperficialfromRipple.processinginfo;
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Saving cells
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if saveMat
    disp(['* Saving cells to ''', saveAs,'''.mat']);
    dirname = 'revisions_cell_metrics';
    if ~(exist(fullfile(clusteringpath,dirname),'dir'))
        mkdir(fullfile(clusteringpath,dirname));
    end
    if exist(fullfile(clusteringpath,[saveAs,'.mat']),'file')
        copyfile(fullfile(clusteringpath,[saveAs,'.mat']), fullfile(clusteringpath, dirname, [saveAs, '_',datestr(clock,'yyyy-mm-dd_HHMMSS'), '.mat']));
    end
    save(fullfile(clusteringpath,[saveAs,'.mat']),'cell_metrics','-v7.3','-nocompression')
end

%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Summary plots
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if plots
    
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
        temp = cell_metrics.acg(window_limits+501,index)./(ones(length(window_limits),1)*max(cell_metrics.acg(window_limits+501,index)));
        
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
        if isfield(cell_metrics,'putativeConnections') && ~isempty(cell_metrics.putativeConnections)
            a1 = cell_metrics.putativeConnections(:,1);
            a2 = cell_metrics.putativeConnections(:,2);
            plot3([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],[plotZ(a1);plotZ(a2)],'k')
        end
        xlabel('Tau decay'), ylabel('Tau rise'), zlabel('deepSuperficialDistance')
    end
    
    % Plotting the average ripple with sharp wave across all spike groups
    deepSuperficial_file = fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']);
    if exist(deepSuperficial_file,'file')
        load(deepSuperficial_file)
    figure
    for jj = 1:session.extracellular.nSpikeGroups
        subplot(2,ceil(session.extracellular.nSpikeGroups/2),jj)
        plot((deepSuperficialfromRipple.SWR_diff{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_diff{jj},2)-1]*0.04,'-k','linewidth',2), hold on, grid on
        plot((deepSuperficialfromRipple.SWR_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.SWR_amplitude{jj},2)-1]*0.04,'k','linewidth',1)
        % Plotting ripple amplitude along vertical axis
        plot((deepSuperficialfromRipple.ripple_amplitude{jj}*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-[0:size(deepSuperficialfromRipple.ripple_amplitude{jj},2)-1]*0.04,'m','linewidth',1)
        
        for jjj = 1:size(deepSuperficialfromRipple.ripple_average{jj},2)
            % Plotting depth (µm)
            text(deepSuperficialfromRipple.ripple_time_axis(end)+5,deepSuperficialfromRipple.ripple_average{jj}(1,jjj)-(jjj-1)*0.04,[num2str(round(deepSuperficialfromRipple.channelDistance(deepSuperficialfromRipple.ripple_channels{jj}(jjj))))])
            % Plotting channel number (0 indexes)
            text((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50-10,-(jjj-1)*0.04,num2str(deepSuperficialfromRipple.ripple_channels{jj}(jjj)-1),'HorizontalAlignment','Right')
            plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*0.04)
            % Plotting assigned channel labels
            if strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Superficial')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*0.04,'or','linewidth',2)
            elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Deep')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*0.04,'ob','linewidth',2)
            elseif strcmp(deepSuperficialfromRipple.channelClass(deepSuperficialfromRipple.ripple_channels{jj}(jjj)),'Cortical')
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*0.04,'og','linewidth',2)
            else
                plot((deepSuperficialfromRipple.SWR_diff{jj}(jjj)*50)+deepSuperficialfromRipple.ripple_time_axis(1)-50,-(jjj-1)*0.04,'ok')
            end
            % Plotting the channel used for the ripple detection if it is part of current spike group
%             if ripple_channel_detector==deepSuperficialfromRipple.ripple_channels{jj}(jjj)
%                 plot(deepSuperficialfromRipple.ripple_time_axis,deepSuperficialfromRipple.ripple_average{jj}(:,jjj)-(jjj-1)*0.04,'k','linewidth',2)
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
    end
end

toc(timerCalcMetrics)
disp(['* Cell metrics calculations complete.'])
