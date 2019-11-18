function varargout = feval(varargin)
%FEVAL  FEVAL a CFIT object.

%   Copyright 1999-2008 The MathWorks, Inc.


obj = varargin{1};
if ~isa(obj,'cfit')
    % If any of the elements in varargin are CFIT objects, then the
    %  overloaded CFIT feval is called even if the first argument
    %  is a string.  In this case, we call the builtin feval.
    [varargout{1:max(1,nargout)}] = builtin('feval',varargin{:});
    return
end

inputs = varargin(2:end);
if (length(inputs) < 1)
    error(message('curvefit:cfit:feval:notEnoughInputs'));
elseif (length(inputs) > 1)
    error(message('curvefit:cfit:feval:tooManyInputs'));
end
xdata = varargin{2};

% quad passes row vectors, so need to make sure xdata is column
xdata = (xdata(:)-obj.meanx)/obj.stdx;  % In case it was normalized
try
    [varargout{1:max(1,nargout)}] = evaluate(obj, obj.coeffValues{:},...
        obj.probValues{:}, xdata);
catch e
    error(message('curvefit:cfit:feval:evaluationError', inputname( 1 ), e.message));
end










