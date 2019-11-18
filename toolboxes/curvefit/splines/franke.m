function values = franke(x,y)
%FRANKE Franke's bivariate test function.
%
%   FRANKE(X,Y)  returns the values  f(X,Y)  of Franke's test function; cf.
%   Richard Franke, A critical comparison of some methods for
%   interpolation of scattered data, Naval Postgraduate School
%   Tech.Rep.  NPS-53-79-003, March 1979.
%
%   VALUES has the same size as X and Y.

%   Carl de Boor 15 may 91
%   Copyright 1987-2008 The MathWorks, Inc. 

values = .75*exp(-((9*x-2).^2 + (9*y-2).^2)/4) + ...
         .75*exp(-((9*x+1).^2)/49 - (9*y+1)/10) + ...
         .5*exp(-((9*x-7).^2 + (9*y-3).^2)/4) - ...
         .2*exp(-(9*x-4).^2 - (9*y-7).^2);
