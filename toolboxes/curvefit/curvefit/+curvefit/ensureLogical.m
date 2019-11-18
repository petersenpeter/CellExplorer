function [ exclude ] = ensureLogical( exclude, nPoints )
%ensureLogical ensures the exclude vector is represented as a logical
% ensureLogical ensures that the index vector which is passed in, is
% represented with logical values (i.e. true/false or zeros/ones).  If the
% vector contains a list of subscripts, then the function converts the
% values to logicals.  It is for this reason that the total number of data
% points is required as an input.
%
%   Example:
%       data = [1 2 3 4 5 6];
%       indices = [1 5];
%       lIndices = curvefit.ensureLogical(indices, numel(data));
%

%   Copyright 2012 The MathWorks, Inc.

if ~iContainsOnlyLogicalValues(exclude)
    exclude = iConvertSubscriptIndexToLogical(exclude, nPoints);
end
end

function outliers = iConvertSubscriptIndexToLogical(exclude, nPoints)
% This function converts an exclude array which was written with integer
% subscript indices into its logical equivalent
if ~iIsBoundedVectorOfIntegers(exclude, nPoints)
    error(message('curvefit:fit:excludedDataBadSubscript'));
end
outliers=false(nPoints, 1);
outliers(exclude)=true;
end

function state = iIsBoundedVectorOfIntegers(vec, vecMax)
% Returns whether a vector is between vecMin and vecMax inclusive, as well
% as whether the values are all integer
isInteger = all(~mod(vec, 1));
isBounded = all(vec<=vecMax) && all(vec>=1);
state = isBounded && isvector(vec) && isInteger;
end

function contains = iContainsOnlyLogicalValues(exclude)
% This function has been written to check how an exclude array has been
% stored for the fit options.  It checks to see whether the array contains
% only ones and zeros, and can serve as a logical array
contains = all(ismember(exclude, [0, 1]));
end
