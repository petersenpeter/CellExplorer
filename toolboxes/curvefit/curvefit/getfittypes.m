function [fittypes,fitcategories,fitnames,allowedNIndep] = getfittypes()
% GETFITTYPES is a helper function for the Curve Fitting Toolbox

%   Copyright 1999-2013 The MathWorks, Inc.

data = cell( 115, 4 );
%     fittype          category     num indep   name
k = 14;
data(1:k,:) = {
    'custom'           'custom'       [1, 2] 'Model'
    'smoothingspline'  'spline'       1      getString(message('curvefit:curvefit:SmoothingSpline'))
    'cubicspline'      'spline'       1      getString(message('curvefit:curvefit:CubicInterpolatingSpline'))
    'linearinterp'     'interpolant'  [1, 2] getString(message('curvefit:curvefit:LinearInterpolant'))
    'pchipinterp'      'interpolant'  1      getString(message('curvefit:curvefit:ShapePreservingPCHIPInterpolant'))
    'splineinterp'     'interpolant'  1      getString(message('curvefit:curvefit:CubicSplineInterpolant'))
    'nearestinterp'    'interpolant'  [1, 2] getString(message('curvefit:curvefit:NearestNeighborInterpolant'))
    'cubicinterp'      'interpolant'  [1, 2] getString(message('curvefit:curvefit:PiecewiseCubicInterpolant'))
    'thinplateinterp'  'interpolant'  2      getString(message('curvefit:curvefit:ThinPlateSplineInterpolant'))
    'biharmonicinterp' 'interpolant'  2      getString(message('curvefit:curvefit:BiharmonicSplineInterpolant'))
    'lowess'           'lowess'       2      getString(message('curvefit:curvefit:LocallyWeightedSmoothingLinearRegression'))
    'loess'            'lowess'       2      getString(message('curvefit:curvefit:LocallyWeightedSmoothingQuadraticRegression'))
    'exp1'             'library'      1      'Exp1'
    'exp2'             'library'      1      'Exp2'
    };

% Rational curves
for i = 0:5
    for j = 1:5
        k = k + 1;
        data(k,:) = {sprintf('rat%d%d', i, j ), 'library', 1, sprintf('Rat%d%d', i, j )};
    end
end

% Gaussian Curves
for i = 1:8
    k = k + 1;
    data(k,:) = {sprintf('gauss%d', i ), 'library', 1, sprintf('Gauss%d', i )};
end

% Sum of sin curves
for i = 1:9
    k = k + 1;
    data(k,:) = {sprintf('sin%d', i ), 'library', 1, sprintf('Sin%d', i )};
end

% Weibull Curve
k = k + 1;
data(k,:) = {'weibull', 'library', 1, 'Weibull'};

% Power curves
k = k + 1;
data(k,:) = {'power1', 'library', 1, 'Power1'};
k = k + 1;
data(k,:) = {'power2', 'library', 1, 'Power2'};

% Polynomial Curves
for i = 1:9
    k = k + 1;
    data(k,:) = {sprintf('poly%d', i ), 'library', 1, sprintf('Poly%d', i )};
end

% Fourier series Curves
for i = 1:8
    k = k + 1;
    data(k,:) = {sprintf('fourier%d', i ), 'library', 1, sprintf('Fourier%d', i )};
end

% Polynomial surfaces
for i = 0:5
    for j = 0:5
        k = k + 1;
        data(k,:) = {sprintf('poly%d%d', i, j ), 'library', 2, sprintf('Poly%d%d', i, j )};
    end
end

% Sort out outputs
fittypes      = char( data(:,1) );
fitcategories = char( data(:,2) );
allowedNIndep =       data(:,3);
fitnames      = char( data(:,4) );
