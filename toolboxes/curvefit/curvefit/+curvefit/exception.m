function theException = exception( id, varargin )
%EXCEPTION Create an MException
%
%   theException = exception(id, varargin) creates an MException using ID
%   and optional VARARGIN message arguments
%
%   Examples:
%
%   theException = curvefit.exception('curvefit:sfit:invalidCall');
%
%   theException = curvefit.exception ...
%   ('curvefit:managecustom:NewEquationNameExists', 'myfit');

%   Copyright 2011-2013 The MathWorks, Inc.

theMessage = message( id, varargin{:} );
theException = MException( id, '%s', getString( theMessage ) );
end