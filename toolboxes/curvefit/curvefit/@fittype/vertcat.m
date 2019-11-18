function c = vertcat(varargin)
%VERTCAT Vertical concatenation of FITTYPE objects (disallowed)

%   Copyright 1999-2004 The MathWorks, Inc.

error(message('curvefit:fittype:vertcat:catNotAllowed', class( varargin{ 1 } )));