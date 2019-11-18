function varargout = feval(varargin)
%FEVAL  FEVAL an SFIT object.

%   Copyright 2008-2011 The MathWorks, Inc.

obj = varargin{1};
if ~isa(obj,'sfit')
    % If any of the elements in varargin are SFIT objects, then the
    %  overloaded SFIT feval is called even if the first argument
    %  is a string.  In this case, we call the builtin feval.
    [varargout{1:max(1,nargout)}] = builtin('feval',varargin{:});
    return
end

% Parse inputs for data
[xdata, ydata] = iXYDataFromInputs( varargin(2:end) );

% Normalize the data
xdata = (xdata - obj.meanx)/obj.stdx;
ydata = (ydata - obj.meany)/obj.stdy;

try
    [varargout{1:max(1,nargout)}] = evaluate(obj, obj.fCoeffValues{:},...
        obj.fProbValues{:}, xdata, ydata);
catch cause
    exception = curvefit.exception( 'curvefit:sfit:feval:evaluationError' );
    exception = addCause( exception, cause );
    throw( exception );
end
end

function [xdata, ydata] = iXYDataFromInputs( inputs )

ninputs = length( inputs );
if ninputs < 1
    % FO( X ) --> error!
    throwAsCaller( curvefit.exception( 'curvefit:sfit:feval:notEnoughInputs' ) );
      
elseif ninputs == 1
    % FO( XY ) --> X = XY(:,1), Y = XY(:,2)
    if size( inputs{1}, 2 ) == 2
        xdata = inputs{1}(:,1);
        ydata = inputs{1}(:,2);
    else
        throwAsCaller( curvefit.exception( 'curvefit:sfit:subsref:invalidInput' ) );
    end
    
elseif ninputs == 2
    % FO( X, Y )
    xdata = inputs{1};
    ydata = inputs{2};
    
else % ninputs > 2
    % FO( X, Y, ... ) --> error
    throwAsCaller( curvefit.exception( 'curvefit:sfit:feval:tooManyInputs' ) );
end

end




