function [SpatialCoh,SpatialCohP] = SpatialCoherence(counts)
% Spatial Coherence
neighbour_bins = [1,1,0,1,1]./4;
[temp1 temp2] = corrcoef(counts,nanconv(counts,neighbour_bins,'edge'));
SpatialCoh = temp1(2,1); 
SpatialCohP = temp2(2,1);