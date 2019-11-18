function h = cfSplineLeverage(W, M, Qt)
%CFSPLINELEVERAGE Compute Leverage for Smoothing Splines
%
%   H = CFSPLINELEVERAGE(W, M, QT)
%
%   Computes the leverage: h = diag(W * Q * (M \ Qt)).
%   The leverage h may be used to compute the degrees of freedom df for
%   a spline on n points with smoothing parameter p using: 
%
%        df = n - 6*(1-p)*sum(h)

%   Copyright 2000-2006 The MathWorks, Inc.

% Put M into packed storage format.
% Mpacked1 is the packed storage for Banded Cholesky factorization.
% Mpacked2 is the packed storage for Banded LU factorization.
% Mpacked2 is used by splinelev only if M is not positive definite
% due to floating point arithmetics.
m = length( M );
if isequal( diag( M, 2 ), zeros( m-2, 1 ) ) %tridiagonal
    Mpacked2 = [zeros( 1, m ); full( spdiags( M, 1:-1:-1 ) )'];
    Mpacked1 = Mpacked2(2:3,:);
else %pentadiagonal, otherwise.
    Mpacked2 = [zeros( 2, m ); full( spdiags( M, 2:-1:-2 ) )'];
    Mpacked1 = Mpacked2(3:5,:);
end

% Call the MEX file that actually does the computation
h = splinelev( W , Qt, Mpacked1, Mpacked2 );
