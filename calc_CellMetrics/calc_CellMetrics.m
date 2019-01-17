function cell_metrics = calc_CellMetrics(varargin)
%   This function calculates cell metrics based on buzsaki lab standards.
%   Most metrics are single value per cell, either numeric or string, but
%   certain metrics are vectors like the autocorrelograms, waveforms or theta phase responses.
%   The metrics are based on a number of features: Spikes, Waveforms, PCA features,
%   the ACGs and CCGs, LFP, theta and ripples
%
%   INPUTS
%   id                   - takes a database id as input
%   session              - takes a database session as input
%   basepath             - path to recording (where .dat/.clu/etc files are)
%   clusteringpath       - path to cluster data if different from basepath
%   metrics              - [default = 'all'] which metrics should be calculated. A cell with strings
%   Examples:             'waveform_metrics','PCA_features','ACG_metrics', 'DeepSuperficial',
%                         'ripple_metrics','MonoSynaptic_connections','Celltype_classification','spatial_metrics'
%                         'perturbation_metrics','theta_metrics'
%   excludeMetrics       - [default = 'none'] any metrics to exclude
%   removeMetrics        - [default = 'none'] any metrics to remove
%   TimeRestriction      - [default = 'none'] any time intervals to exclude
%   forceReload          - logical [default = false] Recalculate existing metrics
%   submitToDatabase     - logical [default = false] Submit cell metrics to database
%   saveMat              - save metrics to cell_metrics.mat
%   saveAs               - name of .mat file
%   plots                - logical [default = true] Plot metrics

% By Peter Petersen
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'sessionStruct',[],@isstruct);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'metrics','all',@iscellstr);
addParameter(p,'excludeMetrics','none',@iscellstr);
addParameter(p,'removeMetrics','none',@isstr);
addParameter(p,'TimeRestriction',[],@isnumeric);

addParameter(p,'forceReload',false,@islogical);
addParameter(p,'submitToDatabase',false,@islogical);
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
TimeRestriction = p.Results.TimeRestriction;

forceReload = p.Results.forceReload;
submitToDatabase = p.Results.submitToDatabase;
saveMat = p.Results.saveMat;
saveAs = p.Results.saveAs;
plots = p.Results.plots;

if ~isempty(id) || ~isempty(sessionin) || ~isempty(sessionStruct)
    bz_database = db_credentials;
    if ~isempty(id)
        [session, basename, basepath, clusteringpath] = db_set_path('id',id);
    elseif ~isempty(sessionStruct)
        [session, basename, basepath, clusteringpath] = db_set_path('session',sessionStruct);
        session.General.EntryID = ''; % DB id
        session.SpikeSorting.EntryIDs{1} = ''; % DB id
    else
        [session, basename, basepath, clusteringpath] = db_set_path('session',sessionin);
    end
    
    
    BrainRegions = (fieldnames(session.BrainRegions));
    findBrainRegion = @(Channel,BrainRegions) BrainRegions{find([(struct2array(structfun(@(x) any(Channel==x.Channels)==1, session.BrainRegions,'UniformOutput',false)))])};
end

% Loading parameters from sessionInfo (Buzcode)
sessionInfo = bz_getSessionInfo(session.General.BasePath,'noPrompts',true);
session.Extracellular.nChannels = sessionInfo.nChannels; % Number of channels
session.Extracellular.nGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
session.Extracellular.Groups = sessionInfo.spikeGroups.groups; % Spike groups
session.Extracellular.Sr = sessionInfo.rates.wideband; % Sampling rate of dat file
session.Extracellular.SrLFP = sessionInfo.rates.lfp; % Sampling rate of lfp file
save('session.mat','session')
sr = session.Extracellular.Sr;

spikes = loadClusteringData(basename,session.SpikeSorting.Format{1},clusteringpath);

if ~isempty(TimeRestriction)
    if size(TimeRestriction,2) ~= 2
        error('TimeRestriction has to be a Nx2 matrix')
    else
        for j = 1:size(spikes.times,2)
            indeces2keep = [];
            indeces2keep = find(any(spikes.times{j} >= TimeRestriction(:,1)' & spikes.times{j} <= TimeRestriction(:,2)', 2));
            spikes.ts{j} =  spikes.ts{j}(indeces2keep);
            spikes.times{j} =  spikes.times{j}(indeces2keep);
            spikes.ids{j} =  spikes.ids{j}(indeces2keep);
            spikes.amplitudes{j} =  spikes.amplitudes{j}(indeces2keep);
            spikes.total(j) =  length(indeces2keep);
        end
        indeces2keep = any(spikes.spindices(:,1) >= TimeRestriction(:,1)' & spikes.spindices(:,1) <= TimeRestriction(:,2)', 2);
        spikes.spindices = spikes.spindices(indeces2keep,:);
    end
end

if exist(fullfile(clusteringpath,[saveAs,'.mat']))
    disp(['Loading existing metrics: ' saveAs])
    load(fullfile(clusteringpath,[saveAs,'.mat']))
else
    cell_metrics = [];
end
cell_metrics.General.basepath = basepath;
cell_metrics.General.basename = basename;
cell_metrics.General.clusteringpath = clusteringpath;
cell_metrics.General.CellCount = length(spikes.total);


% Waveform based calculations
if any(contains(metrics,{'waveform_metrics','all'})) && ~any(contains(excludeMetrics,{'waveform_metrics'}))
    if ~exist(fullfile(clusteringpath,[basename,'.waveform_metrics.cellinfo.mat'])) || forceReload == true
        disp('* Calculating waveform classifications: Trough-to-peak latency, Peak toltage');
        [SpikeWaveforms,SpikeWaveforms_std,PeakVoltage_all,ClusterID] = LoadNeurosuiteWaveforms(clusteringpath,basename,sr,TimeRestriction);
        waveform_metrics = calc_waveform_metrics(SpikeWaveforms,sr);
        save(fullfile(clusteringpath,[basename,'.waveform_metrics.cellinfo.mat']),'waveform_metrics','SpikeWaveforms','SpikeWaveforms_std','PeakVoltage_all','ClusterID')
    else
        load(fullfile(clusteringpath,[basename,'.waveform_metrics.cellinfo.mat']))
    end
end


% PCA features based calculations
if any(contains(metrics,{'PCA_features','all'})) && ~any(contains(excludeMetrics,{'PCA_features'}))
    disp('* Calculating PCA classifications: Isolation distance, L-Ratio')
    [IsolationDistance_all,LRatio_all,ClusterID2] = LoadNeurosuiteFeatures(clusteringpath,basename,sr,TimeRestriction);
end


% ACG & CCG based classification
if any(contains(metrics,{'ACG_metrics','all'})) && ~any(contains(excludeMetrics,{'ACG_metrics'}))
    if ~exist(fullfile(clusteringpath,[basename,'.ACG_metrics.cellinfo.mat'])) || forceReload == true
        disp('* Calculating CCG classifications: ThetaModulationIndex, BurstIndex_Royer2012, BurstIndex_Doublets')
        [ACG,ACG2,ThetaModulationIndex,BurstIndex_Royer2012,BurstIndex_Doublets] = calc_ACG_metrics(clusteringpath,sr,TimeRestriction);
        disp('* Fitting double exponential to ACG')
        fit_params = fit_ACG(ACG2);
        save(fullfile(clusteringpath,[basename,'.ACG_metrics.cellinfo.mat']),'ACG','ACG2','ThetaModulationIndex','BurstIndex_Royer2012','fit_params','BurstIndex_Doublets')
    else
        load(fullfile(clusteringpath,[basename,'.ACG_metrics.cellinfo.mat']))
    end
    
    cell_metrics.ACG = ACG; % Wide: 1000ms wide CCG with 1ms bins
    cell_metrics.ACG2 = ACG2; % Narrow: 100ms wide CCG with 0.5ms bins
    cell_metrics.ThetaModulationIndex = ThetaModulationIndex; % cell_tmi
    cell_metrics.BurstIndex_Royer2012 = BurstIndex_Royer2012; % cell_burstRoyer2012
    cell_metrics.BurstIndex_Doublets = BurstIndex_Doublets;
    
    cell_metrics.ACG_tau_decay = fit_params.ACG_tau_decay;
    cell_metrics.ACG_tau_rise = fit_params.ACG_tau_rise;
    cell_metrics.ACG_c = fit_params.ACG_c;
    cell_metrics.ACG_d = fit_params.ACG_d;
    cell_metrics.ACG_asymptote = fit_params.ACG_asymptote;
    cell_metrics.ACG_refrac = fit_params.ACG_refrac;
    cell_metrics.ACG_fit_rsquare = fit_params.ACG_fit_rsquare;
    cell_metrics.ACG_tau_burst = fit_params.ACG_tau_burst;
    cell_metrics.ACG_h = fit_params.ACG_h;
end


% Deep-Superficial by ripple polarity reversal
if any(contains(metrics,{'DeepSuperficial','all'})) && ~any(contains(excludeMetrics,{'DeepSuperficial'}))
    disp('* Deep-Superficial by ripple polarity reversal')
    if ~exist(fullfile(basepath,'DeepSuperficial_ChClass.mat')) || forceReload == true
        classification_DeepSuperficial(session)
    end
    temp = load(fullfile(basepath,'DeepSuperficial_ChClass.mat'));
    DeepSuperficial_ChDistance = temp.DeepSuperficial_ChDistance; %
    DeepSuperficial_ChClass = temp.DeepSuperficial_ChClass;% cell_deep_superficial
    cell_metrics.General.DeepSuperficial_file = fullfile(basepath,'DeepSuperficial_ChClass.mat');
end


% Ripple modulation
if any(contains(metrics,{'ripple_metrics','all'})) && ~any(contains(excludeMetrics,{'ripple_metrics'}))
    disp('* Calculating ripple metrics')
    load(fullfile(basepath,[basename,'.ripples.events.mat']));
    [RippleModulationIndex,RipplePeakDelay,RippleCorrelogram] = calc_RippleModulationIndex(ripples,clusteringpath,sr,TimeRestriction);
    cell_metrics.RippleModulationIndex = RippleModulationIndex; % cell_ripple_modulation
    cell_metrics.RipplePeakDelay = RipplePeakDelay; % cell_ripple_peak_delay
    cell_metrics.RippleCorrelogram = RippleCorrelogram;
    cell_metrics.General.ripples_file = fullfile(basepath,[basename,'.ripples.events.mat']);
end


% Pytative MonoSynatic connections
if any(contains(metrics,{'MonoSynaptic_connections','all'})) && ~any(contains(excludeMetrics,{'MonoSynaptic_connections'}))
    disp('* Calculating MonoSynaptic connections')
    if ~exist(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat'])) || forceReload == true
        spikeIDs = [spikes.shankID(spikes.spindices(:,2))' spikes.cluID(spikes.spindices(:,2))' spikes.spindices(:,2)];
        mono_res = bz_MonoSynConvClick(spikeIDs,spikes.spindices(:,1),'plot',true);
        save(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat']),'mono_res');
    else
        disp('  Loading previous detected MonoSynaptic connections')
        load(fullfile(clusteringpath,[basename,'.mono_res.cellinfo.mat']),'mono_res');
    end
    
    if ~isempty(mono_res.sig_con)
        cell_metrics.PutativeConnections = mono_res.sig_con; % Vectors with cell pairs
        cell_metrics.SynapticEffect = repmat({'Unknown'},1,cell_metrics.General.CellCount);
        cell_metrics.SynapticEffect(cell_metrics.PutativeConnections(:,1)) = repmat({'Excitatory'},1,size(cell_metrics.PutativeConnections,1)); % cell_synapticeffect ['Inhibitory','Excitatory','Unknown']
        cell_metrics.SynapticConnectionsOut = zeros(1,cell_metrics.General.CellCount);
        cell_metrics.SynapticConnectionsIn = zeros(1,cell_metrics.General.CellCount);
        [a,b]=hist(cell_metrics.PutativeConnections(:,1),unique(cell_metrics.PutativeConnections(:,1)));
        cell_metrics.SynapticConnectionsOut(b) = a; cell_metrics.SynapticConnectionsOut = cell_metrics.SynapticConnectionsOut(1:cell_metrics.General.CellCount);
        [a,b]=hist(cell_metrics.PutativeConnections(:,2),unique(cell_metrics.PutativeConnections(:,2)));
        cell_metrics.SynapticConnectionsIn(b) = a; cell_metrics.SynapticConnectionsIn = cell_metrics.SynapticConnectionsIn(1:cell_metrics.General.CellCount);
    else
        cell_metrics.PutativeConnections = [];
        cell_metrics.SynapticConnectionsOut = zeros(1,cell_metrics.General.CellCount);
        cell_metrics.SynapticConnectionsIn = zeros(1,cell_metrics.General.CellCount);
    end
    cell_metrics.TruePositive = mono_res.TruePositive; % Matrix
    cell_metrics.FalsePositive = mono_res.FalsePositive; % Matrix
end

% Theta related activity
if any(contains(metrics,{'theta_metrics','all'})) && ~any(contains(excludeMetrics,{'theta_metrics'}))
    disp('* Calculating theta metrics');
    if exist(fullfile(basepath,'animal.mat'))
        recording.name = basename;
        recording.nChannels = session.Extracellular.nChannels;
        recording.ch_theta = session.ChannelTags.Theta.Channels;
        recording.sr = session.Extracellular.Sr;
        recording.sr_lfp = session.Extracellular.SrLFP;
        InstantaneousTheta = calcInstantaneousTheta(recording);
%         theta.sr_freq = 10;
        load(fullfile(basepath,'animal.mat'));
        theta_bins =[-1:0.05:1]*pi;
        cell_metrics.ThetaPhasePeak = nan(1,cell_metrics.General.CellCount);
        cell_metrics.ThetaPhaseTrough = nan(1,cell_metrics.General.CellCount);
        cell_metrics.ThetaPhaseResponse = nan(length(theta_bins)-1,cell_metrics.General.CellCount);
        cell_metrics.ThetaEntrainment = nan(1,cell_metrics.General.CellCount);
        
        for j = 1:size(spikes.times,2)
            spikes.ts{j} = spikes.ts{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase)/recording.sr_lfp);
            spikes.times{j} = spikes.times{j}(spikes.ts{j}/sr < length(InstantaneousTheta.signal_phase)/recording.sr_lfp);
            spikes.ts_eeg{j} = ceil(spikes.ts{j}/16);
            spikes.theta_phase{j} = InstantaneousTheta.signal_phase(spikes.ts_eeg{j});
            spikes.speed{j} = interp1(animal.time,animal.speed,spikes.times{j});
            if sum(spikes.speed{j} > 10)> 500
                [counts,centers] = histcounts(spikes.theta_phase{j}(spikes.speed{j} > 10),theta_bins, 'Normalization', 'probability');
                counts = nanconv(counts,[1,1,1,1,1]/5,'edge');
                [~,tem2] = max(counts);
                [~,tem3] = min(counts);
                cell_metrics.ThetaPhasePeak(j) = centers(tem2)+diff(centers([1,2]))/2;
                cell_metrics.ThetaPhaseTrough(j) = centers(tem3)+diff(centers([1,2]))/2;
                cell_metrics.ThetaPhaseResponse(:,j) = counts;
                cell_metrics.ThetaEntrainment(j) = max(counts)/min(counts);
            end
        end
        cell_metrics.General.timeaxis.ThetaPhaseResponse = centers(1:end-1)+diff(centers([1,2]))/2;
        
        figure, subplot(2,2,1)
        plot(cell_metrics.General.timeaxis.ThetaPhaseResponse,cell_metrics.ThetaPhaseResponse),title('Theta entrainment during locomotion'), xlim([-1,1]*pi)
        subplot(2,2,2)
        plot(cell_metrics.ThetaPhaseTrough,cell_metrics.ThetaPhasePeak,'o'),xlabel('Trough'),ylabel('Peak')
        subplot(2,2,3)
        histogram(cell_metrics.ThetaEntrainment,30),title('Theta entrainment')
        subplot(2,2,4)
        histogram(cell_metrics.ThetaPhaseTrough,[-1:0.2:1]*pi),title('Theta trough and peak'), hold on
        histogram(cell_metrics.ThetaPhasePeak,[-1:0.2:1]*pi), legend({'Trough','Peak'})
    end
end

% Spatial related metrics
if any(contains(metrics,{'spatial_metrics','all'})) && ~any(contains(excludeMetrics,{'spatial_metrics'}))
    disp('* Calculating spatial metrics');
    field2remove = {'firing_rate_map_states','firing_rate_map','placecell_stability','SpatialCoherence','place_cell','placefield_count','placefield_peak_rate'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    if exist(fullfile(basepath,'firing_rate_map.mat'))
        disp('  Loaded firing_rate_map.mat succesfully');
        temp2 = load(fullfile(basepath,'firing_rate_map.mat'));
        if cell_metrics.General.CellCount == size(temp2.firing_rate_map_average.unit,2)
            cell_metrics.FiringRateMap = num2cell(temp2.firing_rate_map_average.unit,1);
            cell_metrics.SpatialPeakRate = max(temp2.firing_rate_map_average.unit);
            cell_metrics.General.timeaxis.FiringRateMap = temp2.firing_rate_map_average.xhist;
            cell_metrics.General.timeaxis.FiringRateMapStates = temp2.firing_rate_map.xhist;
            for j = 1:cell_metrics.General.CellCount
                temp = place_cell_condition(temp2.firing_rate_map_average.unit(:,j));
                cell_metrics.SpatialCoherence(j) = temp.SpatialCoherence;
                cell_metrics.PlaceCell(j) = temp.condition;
                cell_metrics.PlaceFieldsCount(j) = temp.placefield_count;
                temp3 = cumsum(sort(temp2.firing_rate_map_average.unit(:,j),'descend'));
                if ~all(temp3==0)
                    cell_metrics.SpatialCoverageIndex(j) = find(temp3>0.75*temp3(end),1)/(length(temp3)*0.75); % Spatial coverage index (Royer, NN 2012)
                    cum_firing1 = cumsum(sort(temp2.firing_rate_map_average.unit(:,j)));
                    cum_firing1 = cum_firing1/max(cum_firing1);
                    cell_metrics.SpatialGiniCoeff(j) = 1-2*sum(cum_firing1)./length(cum_firing1); 
                else
                    cell_metrics.SpatialCoverageIndex(j) = nan;
                    cell_metrics.SpatialGiniCoeff(j) = nan;
                end
            end
            disp('  Spatial metrics succesfully calculated');
        else
            warning(['Number of cells firing rate maps (', num2str(size(temp2.firing_rate_map_average.unit,2)),  ') does not corresponds to the number of cells in spikes structure (', num2str(size(spikes.UID,2)) ,')' ])
        end
    else
        disp('  No firing_rate_map.mat file found');
    end
end

% Perturbation metrics
if any(contains(metrics,{'perturbation_metrics','all'})) && ~any(contains(excludeMetrics,{'perturbation_metrics'}))
    if exist(fullfile(basepath,'optogenetics.mat'))
        disp('* Calculating perturbation metrics');
        spikes2 = loadClusteringData(basename,session.SpikeSorting.Format{1},clusteringpath,1);
        cell_metrics.OptoPSTH = [];
        temp = load('optogenetics.mat');
        trigger = temp.optogenetics.peak;
        edges = [-1:0.1:1.1];
        for j = 1:cell_metrics.General.CellCount
            psth = zeros(size(edges));
            for jj = 1:length(trigger)
                psth = psth + histc(spikes2.times{j}'-trigger(jj),edges);
            end
            cell_metrics.OptoPSTH(:,j) = (psth(1:end-1)/length(trigger))/0.1;
        end
        figure, plot(edges(1:end-1), cell_metrics.OptoPSTH)
    end
end

% Other metrics
cell_metrics.Animal = repmat({session.General.Animal},1,cell_metrics.General.CellCount);
cell_metrics.Sex = repmat({session.General.Sex},1,cell_metrics.General.CellCount);
cell_metrics.Species = repmat({session.General.Species},1,cell_metrics.General.CellCount);
cell_metrics.Strain = repmat({session.General.Strain},1,cell_metrics.General.CellCount);
cell_metrics.GeneticLine = repmat({session.General.GeneticLine},1,cell_metrics.General.CellCount);
cell_metrics.SessionName = repmat({session.General.Name},1,cell_metrics.General.CellCount);
% cell_metrics.Promoter = {}; % cell_promoter

for j = 1:cell_metrics.General.CellCount
    cell_metrics.SessionID(j) = str2num(session.General.EntryID); % cell_sessionid OK
    cell_metrics.SpikeSortingID(j) = session.SpikeSorting.EntryIDs(1); % cell_spikesortingid OK
    cell_metrics.CellID(j) =  spikes.UID(j); % cell_id OK
    cell_metrics.UID(j) =  spikes.UID(j); % cell_id OK
    cell_metrics.CluID(j) =  spikes.cluID(j); % cell_sortingid OK
    cell_metrics.BrainRegion{j} = findBrainRegion(spikes.maxWaveformCh(j),BrainRegions); % cell_brainregion OK
    cell_metrics.SpikeGroup(j) = spikes.shankID(j); % cell_spikegroup OK
    cell_metrics.MaxChannel(j) = spikes.maxWaveformCh(j); % cell_maxchannel OK
    
    % Spike times based metrics
    cell_metrics.SpikeCount(j) = spikes.total(j); % cell_spikecount OK
    if ~isempty(TimeRestriction)
        TimeRestriction_start = max(find( TimeRestriction(:,1) < spikes.times{j}(1)));
        TimeRestriction_end = min(find( TimeRestriction(:,2) > spikes.times{j}(end)));
        spike_window = sum(diff(TimeRestriction(TimeRestriction_start:TimeRestriction_end,:)'));
        spike_window = spike_window - (spikes.times{j}(1)) - TimeRestriction(TimeRestriction_start,1);
        spike_window = spike_window - (TimeRestriction(TimeRestriction_end,2)-spikes.times{j}(end));
        
        cell_metrics.FiringRate(j) = spikes.total(j)/spike_window; % cell_firingrate OK
    else
        cell_metrics.FiringRate(j) = spikes.total(j)/((spikes.times{j}(end)-spikes.times{j}(1))); % cell_firingrate OK
    end
    
    % CV2
    tau = diff(spikes.times{j});
    cell_metrics.FiringRateISI(j) = 1/mean(tau); % cell_firingrate OK
    CV2_temp = 2*abs(tau(1:end-1) - tau(2:end)) ./ (tau(1:end-1) + tau(2:end));
    cell_metrics.CV2(j) = mean(CV2_temp(CV2_temp<1.9));
    
    % Burstiness_Mizuseki2011
    bursty = [];
    for jj = 2 : length(spikes.times{j}) - 1
        bursty(jj) =  any(diff(spikes.times{j}(jj-1 : jj + 1)) < 0.006);
    end
    cell_metrics.BurstIndex_Mizuseki2012(j) = length(find(bursty > 0))/length(bursty); % Fraction of spikes with a ISI for following or preceding spikes < 0.006
    
    % Waveform metrics
    if any(contains(metrics,{'waveform_metrics','all'})) && ~any(contains(excludeMetrics,{'waveform_metrics'}))
        field2remove = {'derivative_TroughtoPeak'};
        test = isfield(cell_metrics,field2remove);
        cell_metrics = rmfield(cell_metrics,field2remove(test));
        cell_metrics.SpikeWaveforms(:,j) = SpikeWaveforms(find(ClusterID == spikes.cluID(j)),:);
        cell_metrics.SpikeWaveforms_std(:,j) = SpikeWaveforms_std(find(ClusterID == spikes.cluID(j)),:);
        cell_metrics.PeakVoltage(j) = PeakVoltage_all(find(ClusterID == spikes.cluID(j)));
        cell_metrics.TroughToPeak(j) = waveform_metrics.TroughtoPeak(find(ClusterID == spikes.cluID(j)));
        cell_metrics.TroughtoPeakDerivative(j) = waveform_metrics.derivative_TroughtoPeak(find(ClusterID == spikes.cluID(j)));
        cell_metrics.AB_ratio(j) = waveform_metrics.AB_ratio(find(ClusterID == spikes.cluID(j)));
    end
    
    % Isolation metrics
    if any(contains(metrics,{'PCA_features','all'})) && ~any(contains(excludeMetrics,'PCA_features'))
        cell_metrics.IsolationDistance(j) = IsolationDistance_all(find(ClusterID2 == spikes.cluID(j)));
        cell_metrics.LRatio(j) = LRatio_all(find(ClusterID2 == spikes.cluID(j)));
    end
    
    % cell_refractoryperiodviolation
    cell_metrics.RefractoryPeriodViolation(j) = 1000*length(find(diff(spikes.times{j})<0.002))/spikes.total(j);
    
    %  Deep-Superficial
    if any(contains(metrics,{'DeepSuperficial','all'})) && ~any(contains(excludeMetrics,{'DeepSuperficial'}))
        if exist('DeepSuperficial_ChClass')
            cell_metrics.DeepSuperficial(j) = DeepSuperficial_ChClass(cell_metrics.MaxChannel(j)); % cell_deep_superficial OK
            cell_metrics.DeepSuperficialDistance(j) = DeepSuperficial_ChDistance(cell_metrics.MaxChannel(j)); % cell_deep_superficial_distance
        end
    end
end

if ~isfield(cell_metrics,'Labels')
    cell_metrics.Labels = repmat({''},1,cell_metrics.General.CellCount);
end

% cell_classification_PutativeCellType
if any(contains(metrics,{'Celltype_classification','all'})) && ~any(contains(excludeMetrics,{'Celltype_classification'}))
    disp('* Performing cell-type classification');
    cell_metrics.PutativeCellType = repmat({'Pyramidal Cell'},1,cell_metrics.General.CellCount);
    
    % Interneuron classification
    cell_metrics.PutativeCellType(cell_metrics.ACG_tau_decay>30) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_decay>30),1);
    cell_metrics.PutativeCellType(cell_metrics.ACG_tau_rise>3) = repmat({'Interneuron'},sum(cell_metrics.ACG_tau_rise>3),1);
    cell_metrics.PutativeCellType(cell_metrics.TroughToPeak<=0.425  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Narrow Interneuron'},sum(cell_metrics.TroughToPeak<=0.425  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
    cell_metrics.PutativeCellType(cell_metrics.TroughToPeak>0.425  & ismember(cell_metrics.PutativeCellType, 'Interneuron')) = repmat({'Wide Interneuron'},sum(cell_metrics.TroughToPeak>0.425  & (ismember(cell_metrics.PutativeCellType, 'Interneuron'))),1);
    
    % Pyramidal cell classification
    cell_metrics.PutativeCellType(cell_metrics.TroughtoPeakDerivative<0.17 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 2'},sum(cell_metrics.TroughtoPeakDerivative<0.17 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
    cell_metrics.PutativeCellType(cell_metrics.TroughtoPeakDerivative>0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 3'},sum(cell_metrics.TroughtoPeakDerivative>0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
    cell_metrics.PutativeCellType(cell_metrics.TroughtoPeakDerivative>=0.17 & cell_metrics.TroughtoPeakDerivative<=0.3 & ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell')) = repmat({'Pyramidal Cell 1'},sum(cell_metrics.TroughtoPeakDerivative>=0.17 & cell_metrics.TroughtoPeakDerivative<=0.3 & (ismember(cell_metrics.PutativeCellType, 'Pyramidal Cell'))),1);
end

if any(contains(removeMetrics,{'DeepSuperficial'}))
    disp('* Removing DeepSuperficial metrics')
    field2remove = {'DeepSuperficial','DeepSuperficialDistance'};
    test = isfield(cell_metrics,field2remove);
    cell_metrics = rmfield(cell_metrics,field2remove(test));
    cell_metrics.DeepSuperficial = repmat({'Unknown'},1,cell_metrics.General.CellCount);
    cell_metrics.DeepSuperficialDistance = nan(1,cell_metrics.General.CellCount);
end

if ~isfield(cell_metrics,'DeepSuperficial')
    cell_metrics.DeepSuperficial = repmat({'Unknown'},1,cell_metrics.General.CellCount);
    cell_metrics.DeepSuperficialDistance = nan(1,cell_metrics.General.CellCount);
end

% Submitting to database
if submitToDatabase
    disp('* Submitting cells to database');
    cell_metrics = db_submit_cells(cell_metrics,session);
end

% Saving cells
if saveMat
    disp(['* Saving cells to', saveAs,'.mat']);
    save(fullfile(clusteringpath,[saveAs,'.mat']),'cell_metrics','-v7.3','-nocompression')
end

% Plots
if plots
    X = [cell_metrics.FiringRateISI; cell_metrics.ThetaModulationIndex; cell_metrics.BurstIndex_Mizuseki2012;  cell_metrics.TroughToPeak; cell_metrics.TroughtoPeakDerivative; cell_metrics.AB_ratio; cell_metrics.BurstIndex_Royer2012;cell_metrics.ACG_tau_rise;cell_metrics.ACG_tau_decay;cell_metrics.CV2]';
    Y = tsne(X);
    goodrows = not(any(isnan(X),2));
    if isfield(cell_metrics,'DeepSuperficial')
    figure,
    gscatter(Y(:,1),Y(:,2),cell_metrics.PutativeCellType(goodrows)'), title('Cell type classification shown in tSNE space'), hold on
    plot(Y(find(strcmp(cell_metrics.DeepSuperficial(goodrows),'Superficial')),1),Y(find(strcmp(cell_metrics.DeepSuperficial(goodrows),'Superficial')),2),'xk')
    plot(Y(find(strcmp(cell_metrics.DeepSuperficial(goodrows),'Deep')),1),Y(find(strcmp(cell_metrics.DeepSuperficial(goodrows),'Deep')),2),'ok')
    xlabel('o = Deep, x = Superficial')
    end
    
    figure,
    histogram(cell_metrics.SpikeGroup,[0:14]+0.5),xlabel('Spike groups'), ylabel('Count')
    
    figure, subplot(2,2,1)
    histogram(cell_metrics.BurstIndex_Mizuseki2012,40),xlabel('BurstIndex Mizuseki2012'), ylabel('Count')
    subplot(2,2,2)
    histogram(cell_metrics.CV2,40),xlabel('CV2'), ylabel('Count')
    subplot(2,2,3)
    histogram(cell_metrics.RefractoryPeriodViolation,40),xlabel('Refractory period violation (‰)'), ylabel('Count')
    subplot(2,2,4)
    histogram(cell_metrics.ThetaModulationIndex,40),xlabel('Theta modulation index'), ylabel('Count')
    
    figure, subplot(2,2,1)
    histogram(CV2_temp,40),xlabel('CV2_temp'), ylabel('Count')
    subplot(2,2,2)
    histogram(CV2_temp(CV2_temp<1.9),40),xlabel('CV2_temp'), ylabel('Count')
    
    % ACG metrics
    figure
    window_limits = [-50:50];
    order_ACGmetrics = {'BurstIndex_Royer2012','ACG_tau_rise','ACG_tau_decay','BurstIndex_Mizuseki2012'};
    order = {'ascend','descend','descend'};
    for j = 1:3
        [~,index] = sort(cell_metrics.(order_ACGmetrics{j}),order{j});
        temp = cell_metrics.ACG(window_limits+501,index)./(ones(length(window_limits),1)*max(cell_metrics.ACG(window_limits+501,index)));
        
        subplot(2,3,j),
        imagesc(window_limits,[],temp'),title(order_ACGmetrics{j},'interpreter','none')
        subplot(2,3,3+j),
        mpdc10 = [size(temp,2):-1:1;1:size(temp,2);size(temp,2):-1:1]/size(temp,2); hold on
        for j = 1:size(temp,2)
            plot(window_limits,temp(:,j),'color',[mpdc10(:,j);0.5]), axis tight, hold on
        end
    end
    
    figure,
    plot3(cell_metrics.ACG_tau_rise,cell_metrics.ACG_tau_decay,cell_metrics.TroughtoPeakDerivative,'.')
    xlabel('Tau decay'), ylabel('Tau rise'), zlabel('Derivative Trough-to-Peak')
    
    if isfield(cell_metrics,'DeepSuperficial')
    figure, hold on
    CellTypeGroups = unique(cell_metrics.PutativeCellType);
    colorgroups = {'k','g','b','r','c','m'};
    plotX = cell_metrics.TroughtoPeakDerivative;
    plotY = cell_metrics.ACG_tau_decay;
    plotZ = cell_metrics.DeepSuperficialDistance;
    for iii = 1:length(CellTypeGroups)
        indexes = find(strcmp(cell_metrics.PutativeCellType,CellTypeGroups{iii}));
        scatter3(plotX(indexes),plotY(indexes),plotZ(indexes),30,'MarkerFaceColor',colorgroups{iii}, 'MarkerEdgeColor','none','MarkerFaceAlpha',.7)
    end
    if isfield(cell_metrics,'PutativeConnections') && ~isempty(cell_metrics.PutativeConnections)
        a1 = cell_metrics.PutativeConnections(:,1);
        a2 = cell_metrics.PutativeConnections(:,2);
        plot3([plotX(a1);plotX(a2)],[plotY(a1);plotY(a2)],[plotZ(a1);plotZ(a2)],'k')
    end
    xlabel('Tau decay'), ylabel('Tau rise'), zlabel('DeepSuperficialDistance')
    end
end
disp('* Cell metrics calculations complete')
