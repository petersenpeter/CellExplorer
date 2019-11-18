function assertNumOutputsEqualsNumInputs( numInputs, numOutputs )
% assertNumOutputsEqualsNumInputs  Throw an error that "Number of output
% arguments must equal number of input arguments" if the two input arguments are
% not the same
%
%   assertNumOutputsEqualsNumInputs( numInputs, numOutputs )
%
%   See also: prepareFittingData

%   Copyright 2011 The MathWorks, Inc.

if  numInputs ~= numOutputs
    error(message('curvefit:prepareFittingData:numOutputsMustEqualNumInputs'));
end
end
