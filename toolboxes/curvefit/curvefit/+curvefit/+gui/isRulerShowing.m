function tf = isRulerShowing( ruler )
% isRulerShowing   True for rulera that are showing

%   Copyright 2015 The MathWorks, Inc.

tf = arrayfun( @iIsShowing, ruler );
end

function tf = iIsShowing( ruler )
% iIsShowing  True for a scalar ruler that is showing
%
% Is there a way to tell if a ruler is showing? 
%
% For the time being you can get the ruler Axle property. If it is empty
% then the ruler is not showing. If it does exist you can check the Visible
% property on that.
axle = ruler.Axle;
if isempty( axle )
    tf = false;
else
    tf = strcmp( axle.Visible, 'on' );
end
end
