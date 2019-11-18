function h = interpoptions(varargin)
% INTERPOPTIONS Constructor for interpoptions object.
% h = interpoptions(methodname)

% Copyright 2001-2004 The MathWorks, Inc.

h = curvefit.interpoptions;

if nargin > 0
  if mod(nargin,2) == 1 
    h.Method = varargin{1};
    varargin(1) = [];
  end
end
