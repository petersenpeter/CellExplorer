function [Q, ERRBND] = quad2d(fo, A, B, c, d, varargin)
%QUAD2D  Numerically integrate a surface fit object.
%   Q = QUAD2D(FO, A, B, C, D) approximates the integral of the surface fit
%   object FO over the planar region A <= x <= B and C(x) <= y <= D(x). C and D
%   may each be a scalar, a function handle or a curve fit (CFIT) object.
%
%   [Q,ERRBND] = QUAD2D(...) also returns an approximate upper bound on the
%   absolute error, ERRBND.
%
%   [Q,ERRBND] = QUAD2D(FUN,A,B,C,D,PARAM1,VAL1,PARAM2,VAL2,...) performs
%   the integration with specified values of optional parameters. 
%
%   See QUAD2D for details of the upper bound and the optional parameters. 
%     
%   See also: QUAD2D, FIT, SFIT, CFIT.

%   Copyright 2009 The MathWorks, Inc.

fun = @(x, y) feval( fo, x, y );

if isa( c, 'cfit' )
    C = @(x) reshape( feval( c, x(:) ), size( x ) );
else 
    C = c;
end

if isa( d, 'cfit' )
    D = @(x) reshape( feval( d, x(:) ), size( x ) );
else
    D = d;
end

[Q, ERRBND] = quad2d( fun, A, B, C, D, varargin{:} );
end

