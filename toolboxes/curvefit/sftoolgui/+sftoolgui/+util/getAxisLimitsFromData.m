function lim = getAxisLimitsFromData(x, border)
%GETAXISLIMITSFROMDATA Work out axis limits from data values
%
%   LIMITS = GETAXISLIMITSFROMDATA(DATA)
%   LIMITS = GETAXISLIMITSFROMDATA(DATA, BORDER) adds a some space around
%   (border) the data. BORDER is a fraction of the difference to add to the
%   limits (default value is zero).

%   Copyright 2008-2015 The MathWorks, Inc.

if nargin < 2
    border = 0;
end

% Remove any NaNs of Infs
x = x(isfinite( x ));
% Take only the real part
x = real( x );

if isempty( x )
    % Probably we have removed all the terms as being NaN or Inf. We'll just use
    % [-1, 1] as the limits
    lim = [-1, 1];
else
    % Take the min and max points as the limits
    lim = [min( x ), max( x )];
    
    % Add the border
    lim = lim + border * [-1 1] * diff( lim );
    
    % If the min and max are the same, adjust them by a small amount. We need to
    % have a difference between min and max limit for the axes.
    if lim(1) == lim(2)
        lim = lim(1) + [-1 1] * max( 1, eps( lim(1) ) );
    end
end

end
