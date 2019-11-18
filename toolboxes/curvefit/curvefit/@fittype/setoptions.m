function model = setoptions(model, newoptions)
%SETOPTIONS Set Fit Options of model.
%   NEWFITTYPE = SETOPTIONS(FITTYPE,OPTIONS) sets FITTYPE fitoptions field
%   to be OPTIONS.
%
%   See also FITTYPE.

%   Copyright 2001-2011 The MathWorks, Inc.

oldoptions = model.fFitoptions;

if ~isequal( class( newoptions ), class( oldoptions ) )
   warning(message('curvefit:setoptions:mismatchedOptions', newoptions.Method, oldoptions.Method));
end

model.fFitoptions = newoptions;
