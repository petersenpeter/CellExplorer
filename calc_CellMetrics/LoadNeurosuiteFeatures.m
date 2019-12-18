function PCA_features = LoadNeurosuiteFeatures(spikes,session,timeRestriction)%(,basename,sr,timeRestriction)
% Calculates isolation distance and L-ratio from clu and fet files (has to be calculated beforehand)
%
% INPUTS
% spikes
% session
% timeRestriction
%
% OUTPUT
% PCA_features

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-09-2019

% TODO
% Determine both metrics from a subset of dimensions

disp('Loading Neurosuite waveforms')

% Extracts parameters from the session struct
sr = session.extracellular.sr;                   % Sample rate (Hz)
basename = session.general.name;             % basename of the session
clusteringpath = session.general.clusteringPath; % path to clustering data (basename.spikes.cellinfo.mat and basename.clu.* and basename.fet.* files)

spikeGroups = unique(spikes.shankID);
SpikeFeatures = [];
isolationDistance = [];
lRatio = [];
cluID = [];
UID = [];

for i = 1:length(spikeGroups)
    spikeGroup = spikeGroups(i);
    accepted_units = spikes.cluID(spikes.shankID ==spikeGroup);
    accepted_units2 = spikes.UID(spikes.shankID ==spikeGroup);
    disp(['Loading spike group ' num2str(spikeGroup)])
    cluster_index = load(fullfile(clusteringpath, [basename '.clu.' num2str(spikeGroup)]));
    cluster_index = cluster_index(2:end);

   % Load .fet file
    filename = fullfile(clusteringpath,[basename '.fet.' num2str(spikeGroup)]);
    if ~exist(filename)
        error(['File ''' filename ''' not found.']);
    end
    file = fopen(filename,'r');
    if file == -1
        error(['Cannot open file ''' filename '''.']);
    end
    nFeatures = fscanf(file,'%d',1);
    fet = fscanf(file,'%f',[nFeatures,inf])';
    fclose(file);

    if ~isempty(timeRestriction)
        time_stamps = load(fullfile(clusteringpath,[basename '.res.' num2str(spikeGroup)]));
        indeces2keep = find(any(time_stamps./sr >= timeRestriction(:,1)' & time_stamps./sr <= timeRestriction(:,2)', 2));
        cluster_index = cluster_index(indeces2keep);
        fet = fet(indeces2keep,:);
    end
    
    clusters = unique(cluster_index);
    clusters = accepted_units(find(ismember(accepted_units,clusters)));
    clusters2 = accepted_units2(find(ismember(accepted_units,clusters)));
    indexes = find(ismember(cluster_index, clusters));
    SpikeFeatures = fet(indexes,1:end-1); 
    cluster_index = cluster_index(indexes);
    
    [isolation_distance1,isolation_distance_accepted] = calc_IsolationDistance(SpikeFeatures,cluster_index,-1);
    [L_ratio1,L_ratio_accepted] = L_ratio_calc(SpikeFeatures,cluster_index,-1);
    
    isolationDistance = [isolationDistance;isolation_distance1];
    lRatio = [lRatio;L_ratio1];
    cluID = [cluID,clusters];
    UID = [UID,clusters2];
end

PCA_features = [];
PCA_features.isolationDistance = isolationDistance;
PCA_features.lRatio = lRatio;
PCA_features.isolationDistanceSubspace = isolationDistanceSubspace;
PCA_features.lRatioSubspace = lRatioSubspace;
PCA_features.cluID = cluID;
PCA_features.UID = UID;

figure, subplot(2,1,1)
histogram(isolationDistance,[2:2:100]),xlabel('Isolation distance'), ylabel('Count'), hold on, gridxy(25)
subplot(2,1,2)
histogram(lRatio,[0:0.2:5]),xlabel('L ratio'), ylabel('Count'), hold on, gridxy(0.5)
