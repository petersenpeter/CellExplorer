function obj = loadobj( input )
%LOADOBJ Method to post-process CFIT objects after loading

%   Copyright 2001-2008 The MathWorks, Inc.

if isstruct( input )
    % We've been given a struct: make a new object and assign its fields
    
    % First get the "fittype" field and construct a CFIT object
    if isfield( input, 'fittype' )
        ft = fittype.loadobj( input.fittype );
        obj = copyFittypeProperties( cfit, ft );
    else
        warning(message('curvefit:cfit:loadobj'));
        obj = cfit;
    end
    
    % Copy the data from the struct to the new object
    obj.coeffValues  = input.coeffValues;
    obj.probValues   = input.probValues;
    obj.sse          = input.sse;
    obj.dfe          = input.dfe;
    obj.rinv         = input.rinv;
    obj.meanx        = input.meanx;
    obj.stdx         = input.stdx;
    obj.activebounds = input.activebounds;
    obj.xlim         = input.xlim;
    
else
    % Assume that we have been given a valid cfit object so everything will be
    % good once we have passed through the fittype loadobj 
    obj = fittype.loadobj( input );
end
% We should now have progressed from whatever old version to
% version 2.
obj.version = 2.0;

end
