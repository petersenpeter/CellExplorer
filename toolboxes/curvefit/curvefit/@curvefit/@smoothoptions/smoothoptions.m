function h = smoothoptions
% SMOOTHOPTIONS Constructor for smoothoptions object.

% Copyright 2001-2004 The MathWorks, Inc.

h = curvefit.smoothoptions;

h.method = 'SmoothingSpline';
h.SmoothingParam = [];  % default
