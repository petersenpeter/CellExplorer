function n = numindep(fun)
%NUMINDEP Number of independent parameter names.
%   NUMINDEP(FUN) returns the number of independent parameters of the FITTYPE
%   object FUN.
%
%   See also INDEPNAMES.

%   Copyright 2008 The MathWorks, Inc.

n = size( fun.indep, 1 );
