% Helper functions for FMAToolbox.
%
% Parameter testing.
%
%   isstring              - Test if parameter is an (admissible) character string.
%   isdscalar             - Test if parameter is a scalar (double) satisfying an optional list of tests.
%   isdvector             - Test if parameter is a vector of doubles satisfying an optional list of tests.
%   isdmatrix             - Test if parameter is a matrix of doubles (>= 2 columns).
%   issamples             - Test if parameter is a list of samples satisfying an optional list of tests.
%   isiscalar             - Test if parameter is a scalar (integer) satisfying an optional list of tests.
%   isivector             - Test if parameter is a vector of integers satisfying an optional list of tests.
%   isimatrix             - Test if parameter is a matrix of integers (>= 2 columns).
%   islscalar             - Test if parameter is a (pseudo) logical scalar.
%   islvector             - Test if parameter is a (pseudo) logical vector satisfying an optional list of tests.
%   islmatrix             - Test if parameter is a (pseudo) logical matrix (>= 2 columns).
%   isradians             - Test if parameter is in range [0,2pi] or [-pi,pi].
%
%   clinspace             - Linearly spaced vector of circular values (angles).
%   glinspace             - Gamma-corrected linearly spaced vector.
%   int2zstr              - Convert integer to zero-padded string.
%   wrap                  - Set radian angles in range [0,2pi] or [-pi,pi].
%   minmax                - Show min and max values for any number of variables.
%   sz                    - Show sizes for any number of variables.
%