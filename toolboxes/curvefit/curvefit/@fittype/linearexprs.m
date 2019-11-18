function cella = linearexprs(model)
%LINEAREXPRS Vectorized expressions for linear coefficient matrix.
%   LINEAREXPRS(FITTYPE) returns the cell array of linear terms of FITTYPE after
%   they have been "vectorized".
%
%   See also FITTYPE/COEFFNAMES.

%   Copyright 2001-2006 The MathWorks, Inc. 

cella = model.Aexpr;
