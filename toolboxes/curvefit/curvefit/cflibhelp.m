function varargout = cflibhelp( varargin )
%CFLIBHELP   Help on fit type objects in the Curve Fitting Library.
%   CFLIBHELP will be removed in a future release. See the "List of Library
%   Models for Curve and Surface Fitting" in the documentation instead.
%
%   See also FIT, FITTYPE, FITOPTIONS.

%   Copyright 1999-2013 The MathWorks, Inc.

warning( message( 'curvefit:cflibhelp:removed', curvefit.linkToListOfLibraryModels() ) );
if nargout
    varargout{1} = iDoLegacyAction( varargin{:} );
end
end
    
function list = iDoLegacyAction( group )
% iDoLegacyAction   Perform the legacy action for CFLIBHELP
%
%   LIST = CFLIBHELP(GROUP) returns a cell array list of the model names in the
%   given GROUP.
%
%   LIST = CFLIBHELP (with no inputs) returns a cell array list of the libraries.
if (nargin == 1)
    if isequal(group,'polynomial')
        list = {'poly1';'poly2';'poly3';'poly4';'poly5';'poly6';'poly7';'poly8';'poly9';'poly00';'poly01';'poly02';'poly03';'poly04';'poly05';'poly10';'poly11';'poly12';'poly13';'poly14';'poly15';'poly20';'poly21';'poly22';'poly23';'poly24';'poly25';'poly30';'poly31';'poly32';'poly33';'poly34';'poly35';'poly40';'poly41';'poly42';'poly43';'poly44';'poly45';'poly50';'poly51';'poly52';'poly53';'poly54';'poly55'};
    elseif isequal(group,'exponential')
        list = {'exp1';'exp2'};
    elseif isequal(group,'power')
        list = {'power1';'power2'};
    elseif isequal(group,'distribution')
        list = {'weibull'};
    elseif isequal(group,'gaussian')
        list = {'gauss1','gauss2','gauss3','gauss4','gauss5','gauss6','gauss7','gauss8'};
    elseif isequal(group,'fourier')
        list = {'fourier1','fourier2','fourier3','fourier4','fourier5','fourier6','fourier7','fourier8'};
    elseif isequal(group,'sin')
        list = {'sin1','sin2','sin3','sin4','sin5','sin6','sin7','sin8'};
    elseif isequal(group,'rational')
        list = {'rat01','rat02','rat03','rat04','rat05','rat11','rat12','rat13','rat14','rat15','rat21','rat22','rat23','rat24','rat25','rat31','rat32','rat33','rat34','rat35','rat41','rat42','rat43','rat44','rat45','rat51','rat52','rat53','rat54','rat55'};
    elseif isequal(group,'spline')
        list = {'cubicspline';'smoothingspline'};
    elseif isequal(group,'interpolant')
        list = {'linearinterp';'nearestinterp';'splineinterp';'pchipinterp';'cubicinterp';'biharmonicinterp';'thinplateinterp'};
    elseif isequal(group,'lowess')
        list = {'lowess';'loess'};
    else
        throwAsCaller( curvefit.exception( 'curvefit:cflibhelp:unknownLibName', curvefit.linkToListOfLibraryModels() ) );
    end
else 
    % put list in a cellarray
    list = {'polynomial';'exponential';'distribution';'gaussian';'power';'rational';'fourier';'sin';'spline';'interpolant';'lowess'};
end
end
