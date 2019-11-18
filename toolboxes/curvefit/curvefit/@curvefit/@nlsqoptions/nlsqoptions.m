function h = nlsqoptions
%NLSQOPTIONS Constructor for nlsqoptions object.

% Copyright 2001-2007 The MathWorks, Inc.

h = curvefit.nlsqoptions;

h.Method = 'NonLinearLeastSquares';
h.Robust = 'off';
h.Lower = [];
h.Upper = [];
h.Algorithm = 'Trust-Region';
h.DiffMaxChange = 1e-1;
h.DiffMinChange = 1e-8;
h.Display = 'notify';
h.Jacobian = 'off';
h.MaxFunEvals = 600; % this should be 100*n, but I have no n.
h.MaxIter = 400;
h.TolFun = 1e-6;
h.TolX = 1e-6;
h.StartPoint = [];

h.PLower = [];
h.PUpper = [];
h.PStartPoint = [];






