function exclusionRulePlotter = parsePanelInputs(fitdev, varargin)
% parsePanelInputs    helper function for creating an exclusion plotter in
% the constructor of the plot panels

%   Copyright 2013 The MathWorks, Inc.

p = inputParser;
p.addOptional('ExclusionRulePlotter', []);
p.parse(varargin{:});

% Only initialise a default if necessary
if ismember(p.UsingDefaults, 'ExclusionRulePlotter')
    exclusionRulePlotter = sftoolgui.exclusion.ExclusionRulePlotter(fitdev.ExclusionRules);
else
    exclusionRulePlotter = p.Results.ExclusionRulePlotter;
end
end