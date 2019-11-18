function updatePlotControls(fitFigure, controls, selectedProperty)
% updatePlotControls FitFigure utility to set controls enable and "selected" states.
%
% updatePlotControls(FITFIGURE, CONTROLS, SELECTEDPROPERTY) CONTROLS is a
% cell array of toolbar buttons or uimenus that correspond to the
% FITFIGURE's PlotPanels. If CONTROLS is an array of menu items,
% SELECTEDPROPERTY should be 'Checked'. If CONTROLS is an array of toolbar
% buttons, SELECTEDPROPERTY should be 'State'.
%
% If no data is specified, all controls should be disabled and not
% selected. If data is specified, there should always be at least one plot
% visible. If there is only one plot visible, its corresponding control
% should be disabled. If data is specified, the "selected" state should
% match the visible state.

%   Copyright 2011 The MathWorks, Inc.

isDataSpecified = isAnyDataSpecified(fitFigure.HFitdev);
numVisiblePlots = numberOfVisiblePlots(fitFigure);

for i=1:length(controls)
    if isDataSpecified
        % The control's "selected" state has to match the visible state
        state = fitFigure.PlotPanels{i}.Visible;
        % If this is the one and only visible plot, ...
        if (numVisiblePlots == 1) ...
                && strcmpi(state, 'on')
            % ... then the control should be disabled
            enable = 'off';
        else
            % ... otherwise the control should be enabled
            enable = 'on';
        end
    else % no data has been specified
        enable = 'off';
        state = 'off';
    end
    set(controls{i}, 'Enable', enable, selectedProperty, state);
end
