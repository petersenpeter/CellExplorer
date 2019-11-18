function span = checkSpan(~, span)
% checkSpan  Check that the span value is between 0 and 1.

% Copyright 2015 The MathWorks, Inc.

if (span < 0) || (span > 1)
    error(message('curvefit:curvfit:lowessoptions:InvalidSpan'));
end
