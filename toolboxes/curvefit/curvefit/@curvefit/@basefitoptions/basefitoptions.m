function h = basefitoptions(varargin)
% Constructor for basefitoptions object.

% Copyright 2001-2004 The MathWorks, Inc.

h = curvefit.basefitoptions;
h.Normalize = 'off';
h.Exclude = [];
h.Weights = [];
h.Method = 'None';
if nargin > 0
  v = varargin;
  if mod(nargin,2) == 1 % will work on fitoption object syntax
    h.Method = v{1};
    v(1) = [];
  end
  if length(v) > 0
    set(h,v{:});
  end
end
