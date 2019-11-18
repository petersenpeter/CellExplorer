function W = getPanelBorderWidth(hPanel)
%getPanelBorderWidth Calculate the width of the panel's border decoration
%
%   W = getPanelBorderWidth(PANEL) returns the visual width of the panel's
%   current border settings for a single edge.

%   Copyright 2011-2014 The MathWorks, Inc.

W = get(hPanel, 'BorderWidth');

Type = get(hPanel, 'BorderType');
if strcmp(Type, 'none')
    % Width ignored for none border type
    W = 0;
else
    % All other borders use the border width
end
