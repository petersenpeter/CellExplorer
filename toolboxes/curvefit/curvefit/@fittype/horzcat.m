function c = horzcat(varargin)
%HORZCAT Horizontal concatenation of FITTYPE objects (disallowed)

%   Copyright 1999-2004 The MathWorks, Inc.

error(message('curvefit:fittype:horzcat:catNotPermitted', class( varargin{ 1 } )));
