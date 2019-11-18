function cfSurface = Surface(hAxes, varargin)
% Surface    Factory function for surfaces
%
%   curvefit.gui.Surface( anAxes, ... ) is a surface whose parent is anAxes. 

%   Copyright 2011-2014 The MathWorks, Inc.

cfSurface = primitiveSurface( hAxes, varargin{:} );
