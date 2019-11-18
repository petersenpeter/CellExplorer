function pos = clipPosition(clipRect,pos)
%clipPosition Ensure a position rectangle is within given bounds
%
%   clipPosition(clipRect, pos) adjusts the given position
%   rectangle so that it has a size and width greater than zero and
%   whenever possible lies within the clipping position rectangle clipRect.

%    Copyright 2011 The MathWorks, Inc.

xMax = clipRect(1) + clipRect(3);
yMax = clipRect(2) + clipRect(4);

if pos(1) < clipRect(1)
    pos(3) = pos(3) - (clipRect(1) - pos(1));
    pos(1) = clipRect(1);
elseif pos(1) >= xMax
    pos(1) = xMax - 1;
end

if pos(2) < clipRect(2)
    pos(4) = pos(4) - (clipRect(2) - pos(2));
    pos(2) = clipRect(2);
elseif pos(2) >= yMax
    pos(2) = yMax - 1;
end

if pos(3) < 1
    pos(3) = 1;
elseif (pos(1) + pos(3)) > xMax
    pos(3) = xMax - pos(1);
end

if pos(4) < 1
    pos(4) = 1;
elseif (pos(2) + pos(4)) > yMax
    pos(4) = yMax - pos(2);
end
