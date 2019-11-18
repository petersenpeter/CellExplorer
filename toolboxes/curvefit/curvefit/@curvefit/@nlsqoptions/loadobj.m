function output = loadobj( input )
% loadobj   Post-process curvefit.nlsqoptions objects after loading

% Copyright 2013 The MathWorks, Inc.

if isequal( input.Algorithm, 'Gauss-Newton' )
    warning( message( 'curvefit:fitoptions:GaussNewtonSubstituted' ) );
    input.Algorithm = 'Levenberg-Marquardt';
end

if isa( input, 'curvefit.nlsqoptions' )
    output = input;
    
elseif isstruct( input )
    try
        output = iStructToFitOptions( input );
    catch e
        disp( getReport( e ) );
        output = [];
    end
    
else
    warning( message( 'curvefit:fitoptions:InvalidLoadedObject' ) );
    output = [];
end

end

function output = iStructToFitOptions( input )
% iStructToFitOptions   Convert a structure to a instance of curvefit.nlsqoptions
output = fitoptions( 'Method', input.Method );

names = fieldnames( input );
values = struct2cell( input );

arrayfun( @(n, v) set( output, n, v ), names, values );
end
