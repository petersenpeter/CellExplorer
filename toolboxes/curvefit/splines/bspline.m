function pp=bspline(t,window)
%BSPLINE Plots a B-spline and its polynomial pieces.
%
%   BSPLINE(T)  plots the B-spline with knot sequence T as well as the 
%   polynomial pieces of which it is composed.
%
%   BSPLINE(T,WINDOW) does the plotting in the WINDOW specified.
%
%   PP = BSPLINE(T) plots nothing, but returns the ppform of the specified
%   B-spline, i.e., gives the same result as  pp = fn2fm(spmak(t,1),'pp').
%
%   See also BSPLIGUI, SPMAK

%   Copyright 1987-2009 The MathWorks, Inc.

%  Generate the spline description

k=length(t)-1;
if (k>1)
   adds=ones(1,k-1);
   tt=[adds*t(1) t(:)' adds*t(k+1)];
   a=[adds*0 1 adds*0];

   %  From this, generate the pp description

   inter=find(diff(tt)>0); l=length(inter);
   tx=ones(l,1)*(2-k:k-1)+inter'*ones(1,2*(k-1));tx(:)=tt(tx);
   tx=tx-tt(inter)'*ones(1,2*(k-1));
   b=ones(l,1)*(1-k:0)+inter'*ones(1,k);
   b(:)=a(b);
   c=sprpp(tx,b);x=[tt(inter) tt(2*k)];
else
  l=1;
  x=t;
  c=1;
end

if nargout>0, pp=ppmak(x,c,1); return, end

%  Now generate a mesh ...

step=100;
xx=x(1)+(-10:step+10)*(x(l+1)-x(1))/step;
nstep=length(xx);

%  ... and generate and plot the polynomial pieces

if nargin>1, subplot(2,2,window), end
xxx=[xx(1) xx(nstep)]; yyy=[-1 2];
plot(xxx,yyy,'.b'),axis([xxx yyy]), grid off, hold on
bspl = spval(spmak(t,1),xx); plot(xx,bspl,'k','linew',2)
for j=1:(k+1), plot(t([j j]),yyy), end
temp = find(xx>=x(1));jh=temp(1);
jsmax=5;js=jsmax; co=['r';'g';'k';'m';'b'];
for j=1:l;js=js+1;if (js>jsmax), js=1;end
   jl=jh; temp = find(xx>=x(j+1));jh=temp(1);
   pval=polyval(c(j,:),xx-x(j));
   plot(xx,pval,co(js)); plot(xx(jl:jh),bspl(jl:jh),co(js),'linew',1.3)
end
pause
hold off
