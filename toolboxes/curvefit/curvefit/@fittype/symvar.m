function vars = symvar(s)
%SYMVAR Determine the symbolic variables for an FITTYPE.
%   SYMVAR returns the variables for the FITTYPE object.
%
%   See also ARGNAMES.

%   Copyright 1999-2004 The MathWorks, Inc.

vars = argnames(s);
