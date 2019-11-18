function [st,p] = tpaps(x,y,p)
%TPAPS Thin-plate smoothing spline.
%
%   F = TPAPS(X,Y)  is the stform of a thin-plate smoothing spline  f  for
%   the given data sites X(:,j) and corresponding data values Y(:,j).
%   The data values may be scalars, vectors, matrices, or even ND-arrays.
%   The X(:,j) must be distinct points in the plane, and there must be exactly
%   as many data values as there are data sites.
%   The thin-plate smoothing spline  f  is the unique minimizer of the
%   weighted sum
%
%                     P*E(f) + (1-P)*R(f) ,
%
%   with E(f) the error measure
%
%       E(f) :=  sum_j { | Y(:,j) - f(X(:,j)) |^2 : j=1,...,n }
%
%   and R(f) the roughness measure
%
%       R(f) := integral  (D_1 D_1 f)^2 + 2(D_1 D_2 f)^2 + (D_2 D_2 f)^2.
%
%   Here, the integral is taken over the entire 2-space, and
%   D_i denotes differentiation with respect to the i-th argument, hence
%   the integral involves the second derivatives of  f .
%   The smoothing parameter P is chosen in an ad hoc fashion
%   in dependence on the sites X.
%
%   TPAPS(X,Y,P) provides the smoothing parameter P, a number expected to
%   be between  0  and  1 .  As P varies from 0 to 1, the smoothing spline
%   changes, from the least-squares approximation to the data by a linear
%   polynomial when P is 0, to the thin-plate spline interpolant to the data
%   when P is 1.
%
%   [F,P] = TPAPS(...) also returns the smoothing parameter used.
%
%   Warning: The determination of the smoothing spline involves the solution
%   of a linear system with as many unknowns as there are data points.
%   Since the matrix of this linear system is full, the solving can take a long
%   time even if, as is the case here, an iterative scheme is used when there
%   are more than 728 data points. The convergence speed of that iteration is
%   strongly influenced by P, and is slower the larger P is. So, for large
%   problems, use interpolation (P equal to 1) only if you can afford the time.
%
%   Examples:
%
%      nxy = 31;
%      xy = 2*(rand(2,nxy)-.5); vals = sum(xy.^2);
%      noisyvals = vals + (rand(size(vals))-.5)/5;
%      st = tpaps(xy,noisyvals); fnplt(st), hold on
%      avals = fnval(st,xy);
%      plot3(xy(1,:),xy(2,:),vals,'wo','markerfacecolor','k')
%      quiver3(xy(1,:),xy(2,:),avals,zeros(1,nxy),zeros(1,nxy), ...
%               noisyvals-avals,'r'), hold off
%   generates the value of a very smooth function at 31 random sites,
%   adds some noise to it, then constructs the smoothing spline to these
%   noisy data, plots the smoothing spline, the exact values (as black
%   balls) the smoothing is trying to recover, and the arrow leading from
%   the smoothed values to the noisy values.
%
%      n = 64; t = linspace(0,2*pi,n+1); t(end) = [];
%      values = [cos(t); sin(t)];
%      centers = values./repmat(max(abs(values)),2,1);
%      st = tpaps(centers, values, 1);
%      fnplt(st), axis equal
%   constructs a map from the plane to the plane that carries the unit square,
%   {x in R^2: |x(j)|<=1, j=1:2}, pretty much onto the unit disk
%   {x in R^2: norm(x)<=1}, as shown by the picture generated.
%
%   See also CSAPS, SPAPS.

%   Copyright 1987-2011 The MathWorks, Inc.

[m,nx] = size(x);

if m~=2
    if nx==2
        addmess = getString(message('SPLINES:resources:SupplyTranspose','X'));
    else
        addmess = '';
    end
    error( message( 'SPLINES:TPAPS:wrongsizeX', ...
        num2str(m), addmess ) );
end

mp1= m+1;

if nx<mp1
    error( message( 'SPLINES:TPAPS:notenoughsites', ...
        num2str(m), num2str(mp1) ) )
end

% convert the values to vectors, but remember the actual size of the values
% in order to set the dimension parameter of the output correctly.
sizeval = size(y);
ny = sizeval(end); sizeval(end) = []; dy = prod(sizeval);
if length(sizeval)>1
    y = reshape(y,dy,ny);
end

if ny~=nx
    if dy==nx
        addmess = getString(message('SPLINES:resources:SupplyTranspose','Y'));
    else
        addmess = '';
    end
    error( message( 'SPLINES:TPAPS:wrongsizeY', ...
        num2str(ny), num2str(nx), addmess ) );
end

% ignore all nonfinites
nonfinites = find(sum(~isfinite([x;y])));
if ~isempty(nonfinites)
    x(:,nonfinites) = []; y(:,nonfinites) = []; nx = size(x,2);
    warning(message('SPLINES:TPAPS:NaNs'))
end

if nx<mp1
    error( message( 'SPLINES:TPAPS:notenoughsites', ...
        num2str(m), num2str(mp1) ) )
end

[Q,R] = qr([ x.' ones(nx,1)]);
radiags = sort(abs(diag(R)));
if radiags(1)<1.e-14*radiags(end)
    error(message('SPLINES:TPAPS:collinearsites'))
end

if nx==3 % simply return the interpolating plane
    st = stmak(x,[zeros(dy,3), y/(R(1:mp1,1:mp1).')],'tp00');
    p = 1;
    
else
    
    Q1 = Q(:,1:mp1); Q(:,1:mp1) = [];
    if nargin==3&&~isempty(p)&&p==0 % get the linear least squares polynomial:
        st = stmak(x, [zeros(dy,nx), (y*Q1)/(R(1:mp1,1:mp1).')],'tp00');
    elseif nx<729 % we solve the linear system directly:
        
        colmat = stcol(x,x,'tr');
        
        if nargin<3||isempty(p) % we must supply the smoothing parameter
            p = 1/(1+mean(diag(Q'*colmat*Q)));
        end
        
        if p~=1, colmat(1:nx+1:nx^2) = colmat(1:nx+1:nx^2)+(1-p)/p; end
        coefs1 = (y*Q/(Q'*colmat*Q))*Q';
        coefs2 = ((y - coefs1*colmat)*Q1)/(R(1:mp1,1:mp1).');
        
        st = stmak(x,[coefs1,coefs2],'tp00');
        
    else      % we use an iterative scheme, to avoid use of out-of-core memory
        % and, for very large problems, perhaps to save execution time
        
        warning(message('SPLINES:TPAPS:longjob'))
        
        if nargin<3||isempty(p) % we must supply the smoothing parameter
            ns = 100; % (this estimate seems insensitive to (reasonable) ns)
            xx = x(:,fix(linspace(1,nx,ns)));
            [q,~] = qr([ones(ns,1),xx.']);
            q(:,1:mp1) = [];
            p = 1/(1+mean(diag(q'*stcol(xx,xx,'tr')*q)));
        end
        
        st0.form = 'st-tp'; st0.centers = x; st0.coefs = []; st0.interv = {[],[]};
        for i=dy:-1:1
            % GMRES(AFUN,B,RESTART,TOL,MAXIT,M1FUN,M2FUN,X0,P1,P2,...)
            % [coefs1(:,i),flag,relres,iter,resvec] = ...
            % ask for the flag output to prevent GMRES from printing a message
            [coefs1(:,i),flag] = gmres(@tppval,(y(i,:)*Q).',10, ...
                1.e-6*max(abs(y(:))),[],[],[],zeros(nx-3,1), st0,Q,p);
            if flag, warning(message('SPLINES:TPAPS:nonconvergence'));
            end
        end
        coefs1 = Q*coefs1;
        coefs2 = ((y - tppval(coefs1,st0,[],p).')*Q1)/(R(1:mp1,1:mp1).');
        st = stmak(x,[coefs1.',coefs2],'tp00');
    end
end
if length(sizeval)>1, st = fnchg(st,'dz',sizeval); end

function vals = tppval(x,st,Q2,p)
%TPPVAL evaluation for iterative solution of thin-plate spline smoothing system

if isempty(Q2)
    st.coefs = x.';
    vals = stval(st,st.centers).';
else
    st.coefs = (Q2*x).';
    vals = (stval(st,st.centers)*Q2).';
end
if p~=1 % TPPVAL is never called when p==0
    vals = vals + x*((1-p)/p);
end