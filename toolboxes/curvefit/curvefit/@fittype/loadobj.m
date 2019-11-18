function obj = loadobj(obj)
%LOADOBJ Method to post-process FITTYPE objects after loading

%   Copyright 2001-2013 The MathWorks, Inc.

% If the loaded version is a structure then we need to convert it to
% an object
if isstruct( obj )
    if obj.version == 1.0
        obj = versionTwoFromVersionOne( obj );
    end
    obj = copyFittypeProperties( fittype, obj );
end

% Restore function handles that had to be removed during save
if ~isequal(category(obj),'custom')
    libname = obj.fType;
    if ~isempty(libname)
        obj = sethandles(libname,obj);
    end
end

% Attempt to fix the anonymous function if it has been stripped out (R2013a or
% earlier)
obj = iFixAnonymousFunction( obj );

end

function obj = versionTwoFromVersionOne( obj )
% VERSIONTWOFROMVERSIONONE -- Convert the old fieldnames to the new names
obj = changeFieldname( obj, 'category',        'fCategory' );
obj = changeFieldname( obj, 'constants',       'fConstants' );
obj = changeFieldname( obj, 'feval',           'fFeval' );
obj = changeFieldname( obj, 'fitoptions',      'fFitoptions' );
obj = changeFieldname( obj, 'nonlinearcoeffs', 'fNonlinearcoeffs' );
obj = changeFieldname( obj, 'startpt',         'fStartpt' );
obj = changeFieldname( obj, 'type',            'fType' );
obj = changeFieldname( obj, 'typename',        'fTypename' );
obj.version = 2.0;
end

function s = changeFieldname( s, old, new )
s.(new) = s.(old);
s = rmfield( s, old );
end

function obj = iFixAnonymousFunction(obj)
if obj.fFeval && isempty( obj.expr )
    obj.fFeval = false;
    obj.expr = obj.defn;
    % Test that we can evaluate the fittype -- test works for fittype but not for
    % subclasses of fittype.
    ft = fittype( obj );
    try
        testCustomModelEvaluation( ft );
    catch e
        bugReport = '<a href="http://www.mathworks.com/support/bugreports/968079">968079</a>';
        warning( message( 'curvefit:fittype:cannotLoadAnonFunction', ...
            obj.defn, bugReport, e.message ) );
    end
end
end
