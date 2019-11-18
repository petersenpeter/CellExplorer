function num = numcoeffs(model)
%NUMCOEFFS Number of coefficients.
%   NUMCOEFFS(FITTYPE) returns the number of coefficients of FITTYPE.
%   
%
%   See also FITTYPE/COEFFNAMES.

%   Copyright 2001-2006 The MathWorks, Inc. 

num = size(model.coeff,1);
