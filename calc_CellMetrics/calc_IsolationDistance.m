function [isolation_distance,isolation_distance_accepted] = calc_IsolationDistance(features,cluster_index,cluster_ids)
% IsolationDistance_calc
% By Peter Petersen (petersen.peter@gmail.com)
% Calculates the L_ratio

% Inputs: 
% features: feature matrix with dim: (nbspikes,nb features)
% cluster_index: vector with cluster indexes 
% cluster_id: -1=all clusters, otherwise specify cluster for the analysis
% If cluster_id is not specified the L_ratio is calculated for all clusters

% Output: 
% isolation_distance: scores
% IsolationDistance_accepted: acceptance meausure (isolation_distance > 50)

if nargin < 3 || cluster_ids(1) == -1; cluster_ids = unique(cluster_index); end

isolation_distance = zeros(length(cluster_ids),1);
% isolation_distance_mikkel = zeros(length(cluster_ids),1);
for j = 1:length(cluster_ids)
    cluster_id = cluster_ids(j);
    cluster_members = find(cluster_index==cluster_id);
    Nc = length(cluster_members);
    features_cluster_members = zeros(Nc,size(features,2));
    for i = 1:length(cluster_members)
        features_cluster_members(i,:) = features(cluster_members(i),:);
    end

    cluster_noise = find(cluster_index~=cluster_id);
    Nc2 = length(cluster_noise);
    features_cluster_noise = zeros(Nc2,size(features,2));
    for i = 1:length(cluster_noise)
        features_cluster_noise(i,:) = features(cluster_noise(i),:);
    end

%     D_mahal_mikkel = mahal(features(:,1:end-1),features_cluster_members);
%     D_mahal_mikkel_sorted = sort(D_mahal_mikkel);
    if Nc2>Nc && size(features_cluster_members,1) >= size(features_cluster_members,2)
        D_mahal = mahal(features_cluster_noise,features_cluster_members);
        D_mahal_sorted = sort(D_mahal);
        isolation_distance(j) = D_mahal_sorted(Nc);
%         isolation_distance_mikkel(j) = D_mahal_mikkel_sorted(2*Nc);
    else
        isolation_distance(j) = 0;
        disp(['Isolation distance set to zero for cluster ' num2str(j)])
    end
end
isolation_distance_accepted = isolation_distance > 50;
