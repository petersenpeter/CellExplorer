function h = llsqoptions
%LLSQOPTIONS Constructor for llsqoptions object.

% Copyright 2001-2004 The MathWorks, Inc.

h = curvefit.llsqoptions;
h.method = 'LinearLeastSquares';
h.Robust = 'off';
h.Lower = [];
h.Upper = [];

