function c = subsasgn(FITTYPE_OBJ_, varargin)
%SUBSASGN    subsasgn of fittype objects.

%   Copyright 1999-2004 The MathWorks, Inc.

error(message('curvefit:fittype:subsasgn:subsasgnNotAllowed', class( FITTYPE_OBJ_ )));