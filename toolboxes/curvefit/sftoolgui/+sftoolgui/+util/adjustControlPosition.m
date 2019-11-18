function pos = adjustControlPosition(hControl,pos)
%adjustControlPosition Calculate a position that puts a control in the right place
%
%   adjustControlPosition(hControl, pos) adjusts the given position
%   rectangle so that when applied to hControl, hControl will end up in the
%   right place.

%    Copyright 2011-2014 The MathWorks, Inc.

if ~ishghandle(hControl, 'axes')
    % Objects in panels need to be shifted upwards.
    hParent = get(hControl, 'Parent');
    if ishghandle(hParent, 'uipanel')
        W = sftoolgui.util.getPanelBorderWidth(hParent);
        pos(2) = pos(2) + 2*W;
    end
end



function W = iGetAllParentBorderWidths(hControl)

W = 0;
hParent = get(hControl, 'Parent');
while ~isempty(hParent)
    if ishghandle(hParent, 'uipanel')
        W = W + sftoolgui.util.getPanelBorderWidth(hParent);
    end
    hParent = get(hParent, 'Parent');
end
