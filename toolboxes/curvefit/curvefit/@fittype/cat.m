function c = cat(varargin)
%CAT    N-D concatenation of FITTYPE objects (disallowed)

%   Copyright 1999-2004 The MathWorks, Inc.

error(message('curvefit:fittype:cat:catNotPermitted', class( varargin{ 1 } )))
