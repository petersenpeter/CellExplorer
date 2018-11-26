function [L_ratio,L_ratio_accepted] = L_ratio_calc(features,cluster_index,cluster_ids)
% L_ratio_calc
% By Peter Petersen (petersen.peter@gmail.com)
% Calculates the L_ratio for specified cluster

% Inputs: 
% features: feature matrix with dim: (nbspikes,nb features)
% cluster_index: vector with cluster indexes 
% cluster_id: -1=all clusters, otherwise specify cluster for the analysis
% If cluster_id is not specified the L_ratio is calculated for all clusters

% Output: 
% L_ratio: scores
% L_ratio_accepted: acceptance meausure (L_ratio < 0.05)

if nargin < 3 || cluster_ids(1) == -1; cluster_ids = unique(cluster_index); end

L_ratio = zeros(length(cluster_ids),1);
for j = 1:length(cluster_ids)
    cluster_id = cluster_ids(j);
    cluster_members = find(cluster_index==cluster_id);
    Nc = length(cluster_members);

    cluster_members_features = zeros(Nc,size(features,2));
    for i = 1:length(cluster_members)
        cluster_members_features(i,:) = features(cluster_members(i),:);
    end

    cluster_noise = find(cluster_index~=cluster_id);
    Nc2 = length(cluster_noise);
    cluster_noise_features = zeros(Nc2,size(features,2));
    for i = 1:length(cluster_noise)
        cluster_noise_features(i,:) = features(cluster_noise(i),:);
    end
    if size(cluster_members_features,1) >= size(cluster_members_features,2)
        D_mahal = mahal(cluster_noise_features,cluster_members_features);
        v = size(cluster_noise_features,2); % degree of freedom
        CDF = cdf('chi2',D_mahal,v);
        L_ratio(j) = 1/Nc * sum(1-CDF);
    else
        L_ratio(j) = 0;
        disp(['L_ratio = 0 for cluster ' num2str(j) '. Too few spikes (' num2str(size(cluster_members_features,1)) ' spikes)'])
    end
end
L_ratio_accepted = L_ratio < 0.05;
