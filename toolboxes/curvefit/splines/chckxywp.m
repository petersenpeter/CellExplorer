function [x,y,sizeval,w,origint,p,tolred] = chckxywp(x,y,nmin,w,p,adjtol)
%CHCKXYWP Check and adjust input for *AP*1 commands.
%
%   [X,Y,SIZEVAL] = CHCKXYWP(X,Y) is used in CSAPI1 to check
%   the data sites X and corresponding data values Y,
%   making certain that there are exactly as many sites as values,
%   and at least NMIN = 2 data points, and also reshaping Y, if need be,
%   into a matrix, returning in SIZEVAL the original size of a data value,
%   also removing any data points that involve NaNs or Infs, also
%   dropping the imaginary part, if any, of any data site, also
%   reordering the points if necessary to ensure that X is nondecreasing,
%   and then averaging any data points with the same site, thus making sure
%   that X is strictly increasing.
%   Only if all these tests are passed, are the data, perhaps modified, 
%   returned, with X of size [n,1], and Y of size [n,prod(SIZEVAL)].
%
%   [X,Y,SIZEVAL,VALCONDS] = CHCKXYWP(X,Y,0) is used in CSAPE1.
%   It differs from the preceding call in that it permits the possibility
%   of there being 2 more data values than there are sites and, in that case,
%   strips off the first and last data value, returning it separately in
%   VALCONDS.
%
%   [X,Y,SIZEVAL] = CHCKXYWP(X,Y,NMIN) is used in SPAPI1.
%   It differs from CHCKXYWP(X,Y) in that it makes certain that there are at 
%   least NMIN data points, and does not insist on the data sites all being
%   different.
%
%   [X,Y,SIZEVAL,W] = CHCKXYWP(X,Y,NMIN,W) is used in SPAP21.
%   It differs from the preceding call in the following way.
%   Any data points with the same data site are replaced by their weighted
%   average while the corresponding entries of the weights W are summed.
%   If W is empty, then the composite trapezoidal weights (corresponding
%   to SORT(X)) are returned.
%
%   [X,Y,SIZEVAL,W,ORIGINT,P] = CHCKXYWP(X,Y,NMIN,W,P) is used in CSAPS1.
%   It differs from the preceding call in the following ways.
%   Any data point (X(j),Y(:,j)) whose weight, W(j), is less than some small
%   fraction of norm(W), is removed; if the leftmost and/or rightmost data
%   point is removed in this way, then ORIGINT is the 1-by-2 matrix containing
%   the site of the original leftmost and the original rightmost data point.
%   Further, if length(P)>1, then any data point removal leads to the removal
%   from P of the roughness weight for the interval to the left of that data
%   site, -- except when a reordering of the data points was necessary, in 
%   which case all entries of P but the first are removed, i.e., the default
%   roughness weights will be used.
%
%   [X,Y,SIZEVAL,W,ORIGINT,TOL,TOLRED] = CHCKXYWP(X,Y,NMIN,W,TOL,ADJTOL) is
%   used in SPAPS1. It differs from the preceding call in that it also returns,
%   in TOLRED, the amount by which the error measure is reduced due to the 
%   replacement of any data points with the same site by their average.
%
%   See also CSAPI, SPAPI, SPAP2, CSAPS, SPAPS.

%   Copyright 1984-2012 The MathWorks, Inc.

% make sure X is a vector:
if iscell(x)||length(find(size(x)>1))>1
   error(message('SPLINES:CHCKXYWP:Xnotvec')), end

% make sure X is real:
if ~all(isreal(x))
   x = real(x);
   warning(message('SPLINES:CHCKXYWP:Xnotreal'))
end

% deal with NaN's and Inf's among the sites:
nanx = find(~isfinite(x));
if ~isempty(nanx)
   x(nanx) = [];
   warning(message('SPLINES:CHCKXYWP:NaNs'))
end

n = length(x);
if nargin>2&&nmin>0, minn = nmin; else minn = 2; end
if n<minn
   error(message('SPLINES:CHCKXYWP:toofewpoints', sprintf( '%g', minn ))), end

% re-sort, if needed, to ensure nondecreasing site sequence:
tosort = false;
if any(diff(x)<0), tosort = true; [x,ind] = sort(x); end

nstart = n+length(nanx);
% if Y is ND, reshape it to a matrix by combining all dimensions but the last:
sizeval = size(y);
yn = sizeval(end); sizeval(end) = []; yd = prod(sizeval);
if length(sizeval)>1
   y = reshape(y,yd,yn);
else
   % if Y happens to be a column matrix, of the same length as the original X,
   % then change Y to a row matrix
   if yn==1&&yd==nstart
      yn = yd; y = reshape(y,1,yn); yd = 1; sizeval = yd;
   end
end
y = y.'; x = reshape(x,n,1);

% make sure that sites, values and weights match in number:

if nargin>2&&~nmin % in this case we accept two more data values than
                   % sites, stripping off the first and last, and returning
		   % them separately, in W, for use in CSAPE1.
   switch yn
   case nstart+2, w = y([1 end],:); y([1 end],:) = [];
      if ~all(isfinite(w)),
         error(message('SPLINES:CHCKXYWP:InfY'))
      end
   case nstart, w = [];
   otherwise
      error(message('SPLINES:CHCKXYWP:XdontmatchY', sprintf( '%g', nstart ), sprintf( '%g', yn )))
   end
else
   if yn~=nstart
      error(message('SPLINES:CHCKXYWP:XdontmatchY', sprintf( '%g', nstart ), sprintf( '%g', yn )))
   end
end

nonemptyw = nargin>3&&~isempty(w);
if nonemptyw
   if length(w)~=nstart
      error(message('SPLINES:CHCKXYWP:weightsdontmatchX', sprintf( '%g', length( w ) ), sprintf( '%g', nstart )))
   else
      w = reshape(w,1,nstart);
   end
end

roughnessw = exist('p','var')&&length(p)>1;
if roughnessw
   if tosort
      warning(message('SPLINES:CHCKXYWP:cantreorderrough'))
      p = p(1);
   else
      if length(p)~=nstart
         error(message('SPLINES:CHCKXYWP:rweightsdontmatchX', sprintf( '%g', nstart )))
      end
   end
end

%%% remove values and error weights corresponding to nonfinite sites:
if ~isempty(nanx), y(nanx,:) = []; if nonemptyw, w(nanx) = []; end
   if roughnessw  % as a first approximation, simply ignore the
                  % specified weight to the left of any ignored point.
      p(max(nanx,2)) = [];
   end
end
if tosort, y = y(ind,:); if nonemptyw, w = w(ind); end, end

% deal with nonfinites among the values:
nany = find(sum(~isfinite(y),2));
if ~isempty(nany)
   y(nany,:) = []; x(nany) = []; if nonemptyw, w(nany) = []; end
   warning(message('SPLINES:CHCKXYWP:NaNs'))
   n = length(x);
   if n<minn
      error(message('SPLINES:CHCKXYWP:toofewX', sprintf( '%g', minn ))), end
   if roughnessw  % as a first approximation, simply ignore the
                  % specified weight to the left of any ignored point.
      p(max(nany,2)) = [];
   end
end

if nargin==3&&nmin, return, end % for SPAPI, skip the averaging

if nargin>3&&isempty(w) %  use the trapezoidal rule weights:
   dx = diff(x);
   if any(dx), w = ([dx;0]+[0;dx]).'/2;
   else,       w = ones(1,n);
   end
   nonemptyw = ~nonemptyw;
end

tolred = 0;
if ~all(diff(x)) % conflate repeat sites, averaging the corresponding values
                 % and summing the corresponding weights
   mults = knt2mlt(x);
   for j=find(diff([mults;0])<0).'
      if nonemptyw
         temp = sum(w(j-mults(j):j));
	 if nargin>5
	    tolred = tolred + w(j-mults(j):j)*sum(y(j-mults(j):j,:).^2,2); 
	 end
         y(j-mults(j),:) = (w(j-mults(j):j)*y(j-mults(j):j,:))/temp;
         w(j-mults(j)) = temp;
         if nargin>5
	    tolred = tolred - temp*sum(y(j-mults(j),:).^2);
	 end
      else
         y(j-mults(j),:) = mean(y(j-mults(j):j,:),1);
      end
   end
      
   repeats = find(mults);
   x(repeats) = []; y(repeats,:) = []; if nonemptyw, w(repeats) = []; end
   if roughnessw  % as a first approximation, simply ignore the
                  % specified weight to the left of any ignored point.
      p(max(repeats,2)) = [];
   end
   n = length(x);
   if n<minn, error(message('SPLINES:CHCKXYWP:toofewX', sprintf( '%g', minn ))), end
end

if nargin<4, return, end


% remove all points corresponding to relatively small weights (since a
% (near-)zero weight in effect asks for the corresponding datum to be dis-
% regarded while, at the same time, leading to bad condition and even
% division by zero).
origint = []; % this will be set to x([1 end]).' in case the weight for an end
             % data point is near zero, hence the approximation is computed
             % without that endpoint.
if nonemptyw
   ignorep = find( w <= (1e-13)*max(abs(w)) );
   if ~isempty(ignorep)
      if ignorep(1)==1||ignorep(end)==n, origint = x([1 end]).'; end
      x(ignorep) = []; y(ignorep,:) = []; w(ignorep) = []; 
      if roughnessw
                     % as a first approximation, simply ignore the
                     % specified weight to the left of any ignored point.
         p(max(ignorep,2)) = [];
      end
      n = length(x);
      if n<minn
        error(message('SPLINES:CHCKXYWP:toofewposW', sprintf( '%g', minn )))
      end
   end
end
