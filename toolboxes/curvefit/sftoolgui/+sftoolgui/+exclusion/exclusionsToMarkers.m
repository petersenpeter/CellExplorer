function [blackDots, redDots, redCrosses] = exclusionsToMarkers(manualExclusions, exclusionsByRule)
% exclusionsToMarkers   This function returns a set of logical vectors
% which describe which marker should be used on a plot panel based on the
% exclusion rules and manual exclusions of a Fitdev.  The options are a
% black dot, a red dot, or a red cross.  The rules are as follows:
% 
%     A black dot is used for a point which is not excluded.  
%
%     A red dot is used for a point which has been excluded by a rule.  
%
%     A red cross is used for a point that has been excluded manually.  
%
%     A red cross supercedes a red dot.

%   Copyright 2013 The MathWorks, Inc.

blackDots = ~manualExclusions & ~exclusionsByRule;
redDots = exclusionsByRule & ~manualExclusions;
redCrosses = manualExclusions;
end

