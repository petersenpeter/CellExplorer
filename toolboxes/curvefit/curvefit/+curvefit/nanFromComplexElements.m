function x = nanFromComplexElements( x )
% nanFromComplexElements   Replace complex elements with NaN
%
%    nanFromComplexElements( X ) is the same as X except that any complex element
%    (element with non-zero imaginary part) is NaN.

%   Copyright 2011 The MathWorks, Inc.

if ~isreal( x )
    % Determine which elements of the array have non-zero imaginary part.
    tf = imag( x ) ~= 0;
    % Set those elements to NaN
    x(tf) = NaN;
end
end
