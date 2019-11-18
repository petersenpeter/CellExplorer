function updateInformationPanel(hFitFigure)
%updateInformationPanel Update the FitFigure's information panel

%   Copyright 2008-2011 The MathWorks, Inc.

% If we need to display the "click fit" message, we will not display any
% other messages. The following pseudo code represents the code logic that
% follows:

% if need "click fit" message  
% 	display "click fit" message
% else
% 	if there are "data" messages 
%       display "data" message
%   end
%   if there are "fit" warnings
% 	    display "fit" warnings
%   end
%   if there are "fit" (or "fittype") errors
%       display "fit" errors
%   end
% end

hFitdev = hFitFigure.HFitdev;

% Clear information panel
updateInfo(hFitFigure.HResultsPanel, '', []);

% Add information about Click requirement if needed.
if iNeedClickFitMessage(hFitdev)
    appendInfo(hFitFigure.HResultsPanel, ...
        getString(message('curvefit:sftoolgui:ClickFitToUpdatePlotAndResults')), ...
        com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE);
else % Display other messages, warnings or errors. 
    
    % Display data related messages if there are any.
    if ~isempty(getMessageString(hFitdev.FittingData))
        appendInfo(hFitFigure.HResultsPanel, ...
            sprintf( '%s', getMessageString(hFitdev.FittingData)), ...
            getMessageLevel(hFitdev.FittingData));
    end
    
    % Add fit warnings or errors if there are any. 
    % Check for warnings first, so that if there are both warnings and
    % errors, the icon will be an error. (Fit warnings take precedence over
    % Data warnings.)
    if ~isempty(hFitdev.WarningStr)
        appendInfo(hFitFigure.HResultsPanel, ...
            sprintf( '%s\n', hFitdev.WarningStr ), ...
            com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING);
    end
    
    if ~isempty(hFitdev.ErrorStr)
        appendInfo(hFitFigure.HResultsPanel, ...
            sprintf( '%s\n', hFitdev.ErrorStr ), ...
            com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR);
    end
end
end

function needClickFitMessage = iNeedClickFitMessage(hFitdev)
% iNeedClickFitMessage returns true if the "Press click to fit" message is
% needed.
%
% The "Press click to fit" message should never be displayed if "AutoFit" 
% is enabled (that is the "Auto Fit" check box is checked).
%
% If "AutoFit" is disabled, the "Press click to fit" message is needed if
% the user has successfully selected data, there is a valid fittype, and no
% fit has occurred. To check if data has been successfully selected, we see
% if curve or surface data have been specified and their sizes are
% compatible (using the isSurfaceDataSpecified or isCurveDataSpecified and
% areNumSpecifiedElementsEqual methods respectively). The only time a
% fittype is invalid is when there is an invalid custom equation. In that
% case, Fitdev's FitState property is set to "Error". So if the FitState is
% not "Error", then we know we have a valid Fittype. When the FitState is
% "Incomplete", we know that a fit has not occurred. 

INCOMPLETE = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;

needClickFitMessage = ~hFitdev.AutoFitEnabled && ...
    (isSurfaceDataSpecified(hFitdev.FittingData) || ...
	isCurveDataSpecified(hFitdev.FittingData)) && ...
    areNumSpecifiedElementsEqual(hFitdev.FittingData) && ...
    hFitdev.FitState == INCOMPLETE;
end
