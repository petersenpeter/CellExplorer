function [minval, minsite] = fnmin(f,interv)
%FNMIN Minimum of a function (in a given interval).
%
%   FNMIN(F) returns the minimum value of the scalar-valued univariate spline 
%   in F on its basic interval. 
%
%   FNMIN(F,INTERV) returns the minimum value in the interval specified
%   by INTERV (as [a,b]).
%
%   [MINVAL, MINSITE] = FNMIN(F ...) also provides the site MINSITE at
%   which the function in F takes on that minimum value, MINVAL.
%
%   Examples:
%   Since spmak(1:5,-1) provides the negative of the cubic B-spline
%   with knot sequence (1,2,3,4,5), we expect
%
%      [y,x] = fnmin(spmak(1:5,-1))
%   
%   to return y equal to -2/3, and x equal to 3. Further,
% 
%      f = spmak(1:21,rand(1,15)-.5);
%      maxval = -fnmin(fncmb(f,-1))
%
%   provides the maximum value of the spline in f over its basic interval,
%   as the following picture shows:
%      
%      fnplt(f), hold on, plot(fnbrk(f,'in'),[maxval maxval]), hold off
%
%   See also FNZEROS, FNVAL.

%   Copyright 1987-2008 The MathWorks, Inc. 

[v,d] = fnbrk(f,'var','dim');
if v>1
   error(message('SPLINES:FNMIN:onlyuni'))
end
if length(d)>1||d>1
   error(message('SPLINES:FNMIN:onlyscalar'))
end

if nargin>1, f = fnbrk(f,interv); end

form = fnbrk(f,'form');
if form(1)=='r'  % We are dealing with a (univariate) rational function.
   ff = fn2fm(f,'pp');  % Convert to pp function form, and keep in mind
   dff = fnder(ff);     % that now the second component is meant to be the
                        % denominator. Fortunately, we only need the 
                        % numerator of the derivative.
   df = fncmb(  fncmb(fncmb(ff,[1,0]),'*',fncmb(dff,[0,1])),'-', ...
                fncmb(fncmb(ff,[0,1]),'*',fncmb(dff,[1,0]))  );
else
   df = fnder(f);
end

breaks = fnbrk(f,'breaks');
sites = [breaks, mean(fnzeros(df))];
vals = [fnval(f,sites), fnval(f,breaks(2:end-1),'left')];
sites = [sites, breaks(2:end-1)];
   
[minval, imin] = min(vals);
if nargout>1, minsite = sites(imin); end
