function str = char(obj)
%CHAR Convert FITTYPE object to character array.
%   CHAR(FUN) returns the formula for the FITTYPE object FUN.
%   This is the same as FORMULA(FUN).
%
%   See also FITTYPE, FITTYPE/FORMULA.

%   Copyright 1999-2004 The MathWorks, Inc.

str = obj.defn;
