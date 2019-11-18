function cella = linearterms(model)
%LINEARTERMS Cell array of linear terms to form linear coefficient matrix.
%   LINEARTERMS(FITTYPE) returns the cellarray of linear terms of FITTYPE.
%
%   See also FITTYPE/COEFFNAMES.

%   Copyright 2001-2006 The MathWorks, Inc. 

cella = model.Adefn;
