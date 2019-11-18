function updateExclusions( this )
% updateExclusions  Callback for when exclusions change.
%
%    When exclusions change, we need to plot the fitting data.

%   Copyright 2011-2012 The MathWorks, Inc.

% For the ExclusionsUpdated event, i.e., when exclusions have been updated, we
% want to do the same things as when fitting data has been updated

plotFittingData(this);
end
