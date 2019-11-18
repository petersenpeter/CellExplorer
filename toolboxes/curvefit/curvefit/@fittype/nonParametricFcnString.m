function line = nonParametricFcnString(obj, variable, arglist, coefficient)
%NONPARAMETRICFCNSTRING Make the string that describes a non-parametric function
%
%   LINE = NONPARAMETRICFCNSTRING(OBJ, VARIABLE, ARGLIST, COEFFICIENT)

%   Copyright 2008-2013 The MathWorks, Inc.

lhs = leftHandSideForFcnString( variable, arglist );
identifier = iIdentifierFromLibname( numindep( obj ), obj.fType );
line = getString( message( identifier, lhs, coefficient ) );
end

function identifier = iIdentifierFromLibname(numindep, libname)
% iIdentifierFromLibname   Get message identifier from library name

switch numindep
    case 1 % curves
        identifier = 'curvefit:curvefit:PiecewisePolynomialComputedFrom';
    case 2 % surfaces
        switch libname
            case 'nearestinterp'
                identifier = 'curvefit:curvefit:PiecewiseConstantSurfaceComputedFrom';
            case 'linearinterp'
                identifier = 'curvefit:curvefit:PiecewiseLinearSurfaceComputedFrom';
            case 'cubicinterp'
                identifier = 'curvefit:curvefit:PiecewiseCubicSurfaceComputedFrom';
            case 'biharmonicinterp'
                identifier = 'curvefit:curvefit:BiharmonicSurfaceComputedFrom';
            case 'thinplateinterp'
                identifier = 'curvefit:curvefit:ThinPlateSplineComputedFrom';
            case 'lowess'
                identifier = 'curvefit:curvefit:LowessLinearSmoothingRegressionComputedFrom';
            case 'loess'
                identifier = 'curvefit:curvefit:LoessQuadraticSmoothingRegressionComputedFrom';
            otherwise
                % We shouldn't hit this case
                error(message('curvefit:fittype:InvalidState', libname));
        end
    otherwise
        % We shouldn't hit this case
        error(message('curvefit:fittype:InvalidState', libname));
end

end
