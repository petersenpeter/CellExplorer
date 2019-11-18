function residualLimits = getResidualLimits(aFitdev)
% getResidualLimits returns residual limits
%
% getResidualLimits(aFitdev) returns (1, 2) limit array. aFitdev is a
% sftoolgui.Fitdev.

%   Copyright 2011-2015 The MathWorks, Inc.

residualLimits = iGetResidualLimits(aFitdev);
end

function residLimits = iGetResidualLimits(aFitdev)
% iGetResidualLimits gets the limits for residuals
[resids, vResids] = getResiduals(aFitdev);
if isempty(resids)
    residLimits = [-1 1];
else
    residLimits = sftoolgui.util.getAxisLimitsFromData( resids, 0.05);
    if ~isempty(vResids)
        vResidLimits = sftoolgui.util.getAxisLimitsFromData( vResids, 0.05);
        residLimits(1) = min(residLimits(1), vResidLimits(1));
        residLimits(2) = max(residLimits(2), vResidLimits(2));
    end
    residLimits = iGetModifiedLimits(aFitdev, residLimits);
end
end

function limits = iGetModifiedLimits(aFitdev, limits)
% iGetModifiedLimits adjusts limits to make effective 0 residuals look like
% 0 residual
fittingData = aFitdev.FittingData;
if isCurveDataSpecified(fittingData) % Curves
    [~, output] = getCurveValues(fittingData);
else % Surface
    [~, ~, output] = getValues(fittingData);
end

if isempty( output )
    range = 1;
else
    range = max( output ) - min( output );
end

minLim = max( 1e-8*range, 1e-5 );

limits(1) = min( limits(1), -minLim );
limits(2) = max( limits(2),  minLim );
end
