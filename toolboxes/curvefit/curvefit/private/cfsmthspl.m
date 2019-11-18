function [pp,p,df] = cfsmthspl(x,y,p,w)
%CFSMTHSPL Curve Fitting's cubic smoothing spline.
%   PP = CFSMTHSPL(X,Y) returns the ppform of the cubic smoothing spline for
%   the data (X,Y) with a smoothing parameter P chosen between 0 and 1.
%   The range of values for which P returns a reasonable smoothing spline
%   depends on the data (X,Y) and is actually much smaller than the whole
%   range [0 1].
%   CFSMTHSPL uses a value of P that is somewhere in the reasonable range.
%
%   PP = CFSMTHSPL(X,Y,P) specifies the smoothing parameter P, a scalar
%   between 0 and 1.  If P=[], CFSMTHSPL chooses the smoothing parameter P
%   from the reasonable range.
%
%   PP = CFSMTHSPL(X,Y,P,W) specifies the weights W on the data X.  The
%   default is the vector of all ones, which weights all the data evenly.
%   If W=[], the default is used.
%
%   [PP,P] = CFSMTHSPL(X,Y,...) also returns the smoothing parameter P
%   used to construct the spline. If P was specified as a nonempty input,
%   it is returned unchanged.
%
%   [PP,P,DF] = CFSMTHSPL(X,Y,...) also returns an approximate degrees of
%   freedom DF for the fit.
%
%   Note: The smoothing spline f returned in PP minimizes
%      P * (sum(W.*(Y - f(X)).^2))  +  (1-P) * integral (D^2 f)^2
%   where D^2 is the second derivative of f with respect to X.
%
%   Note: P=0 gives the least squares straight line fit to the data and 
%   has DF=2.  P=1 gives the cubic spline interpolant of the data and
%   has DF equal to the number of distinct X values.
%
%   CFSMTHSPL is based on the function CSAPS.
%
%   See also CSAPS.

%   Copyright 2000-2012 The MathWorks, Inc.

if nargin < 3
	p = [];
end
if nargin < 4
	w = [];
end

% Pre-process to remove duplicate x values
[xi,yi,w] = preprocess(x,y,w);

n = length(xi);
if n < 2
	error(message('curvefit:fit:InsufficientData', 2))
end

[yd,yn] = size(yi);
if n ~= yn
	error(message('curvefit:cfsmthspl:NumSitesValuesDoNotMatch'))
end
yi = yi.';
dd = ones(1,yd);

% remove all points corresponding to relatively small weights since a
% (near-)zero weight in effect asks for the corresponding datum to be dis-
% regarded while, at the same time, leading to bad condition and even
% division by zero.
if isempty(w)
	w = ones(n,1);
else
	maxw = max(abs(w));
	ignorep = find( w <= (1e-13)*maxw );
	if ~isempty(ignorep)
		w(ignorep) = [];
		xi(ignorep) = [];
		yi(ignorep,:) = [];
		n = length(xi);
		if n < 2
			error(message('curvefit:cfsmthspl:notEnoughPositiveWeights'))
		end
	end
end

dx = diff(xi);
divdif = diff(yi)./dx(:,dd);
if n == 2 % the smoothing spline is the straight line interpolant
   pp = mkpp(xi.',[divdif.' yi(1,:).'],yd);
   if nargout > 1
      if (nargin == 2) || isempty(p)
         p = 1;
      end
      if nargout > 2
         df = n;
      end
   end
else
   % set up the linear system for solving for the 2nd derivatives at  xi .
   % this is taken from (XIV.6)ff of the `Practical Guide to Splines'
   % with the diagonal matrix  D^2 there equal to diag(1/w) here.
   % Make use of sparsity of the system.
   dxol = dx;
   R = spdiags([dxol(2:n-1),2*(dxol(2:n-1)+dxol(1:n-2)),dxol(1:n-2)],...
       -1:1,n-2,n-2);
   odx = ones(n-1,1)./dx;
   Qt = spdiags([odx(1:n-2),-(odx(2:n-1)+odx(1:n-2)),odx(2:n-1)], ...
       0:2,n-2,n);
   % solve for the 2nd derivatives
   if isempty(w)
       w = ones(n,1);
   end
   W = spdiags(ones(n,1)./w(:),0,n,n);
   QtWQ = Qt*W*Qt.';
   if isempty(p)
      % we are to determine an appropriate P
      p = 1 / (1+trace(R)/(6*trace(QtWQ)));
   elseif (p < 0) || (p > 1)
      error(message('curvefit:cfsmthspl:invalidParam'));
   end
   M = 6*(1-p)*QtWQ+p*R;
   u = M \ diff(divdif);
   
   % Get degrees of freedom if required
   if (nargout >= 3)
       h = cfSplineLeverage( W, M, Qt );
       df = n - 6*(1-p)*sum(h);
   end
   clear M QtWQ

   % ... and convert to pp form
   % Qt.'*u=diff([0;diff([0;u;0])./dx;0])
   yi = yi - ...
        (6*(1-p))*W*diff([zeros(1,yd);
        diff([zeros(1,yd); u; zeros(1,yd)])./dx(:,dd);
        zeros(1,yd)]);
   c3 = [zeros(1,yd); p*u; zeros(1,yd)];
   c2 = diff(yi)./dx(:,dd)-dxol(:,dd).*(2*c3(1:n-1,:)+c3(2:n,:));
   pp = mkpp(xi.',...
        reshape([(diff(c3)./dx(:,dd)).',3*c3(1:n-1,:).',c2.',yi(1:n-1,:).'],...
        (n-1)*yd,4),yd);
end


% ---------- helper function to pre-process the data
function [x,y,w] = preprocess(x,y,w)
%PREPROCESS Pre-process data for smoothing spline calculation
%
%   Given input vectors (x,y,w) with possible repeated x values,
%   this function produces (X,Y,W) satisfying the following:
%       1.  X = sort(unique(x))
%       2.  Y(j) = weighted mean(y(:,(x==X(j))),2)
%       3.  W(j) = sum(w(x==X(j)))
%       4.  The smoothing spline for (X,Y,W) is the same as the
%           smoothing spline for (x,y,w) for a given p value

% Make y have one row per dimension
[yd,yn] = size(y);
if yn==1 
    yn=yd; 
    y=reshape(y,1,yn); 
end
x = x(:);

% Get default weights if required
if isempty(w), w = ones(size(x)); end

% Sort x
if any(diff(x)<0)
   [x,ind] = sort(x);
   y = y(:,ind);
   w = w(ind);
end

% Watch for simplest case
dx = diff(x);
if (~any(dx==0)), return; end

% Find first index, count of each distinct x value
x2 = [1; 1+find(dx>0)];
nx = [x2(2:end); length(x)+1] - x2;

% Compute the weighted average of y and the sum of w at each distinct x
ybar = y(:,x2);   % Get ybar of proper size, to fill in values later
sumw = w(x2);
w = w(:);

for j=1:length(x2)
   if nx(j)>1
      ind = (x2(j)-1) + (1:nx(j));
      wvec = w(ind);
      sumw(j) = sum(wvec);
      ybar(:,j) = (y(:,ind)*wvec) / sumw(j);
   end
end

% Returned reduced variables
x = x(x2);
y = ybar;
w = sumw;
