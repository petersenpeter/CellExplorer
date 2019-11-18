function spline = spmak(knots,coefs,sizec)
%SPMAK Put together a spline in B-form.
%
%   SPMAK(KNOTS,COEFS) puts together a spline from the knots and
%   coefficients. Let SIZEC be size(COEFS). Then the spline is taken to be
%   SIZEC(1:end-1)-valued, hence there are altogether n = SIZEC(end)
%   coefficients.
%   The order of the spline is inferred as  k := length(KNOTS) - n .
%   Knot multiplicity is held to <= k , with the coefficients
%   corresponding to a B-spline with trivial support ignored.
%
%   SPMAK  will prompt you for KNOTS and COEFS.
%
%   If KNOTS is a cell array of length  m , then COEFS must be at least
%   m-dimensional, i.e., length(SIZEC) must be at least m. If COEFS is
%   m-dimensional, then the spline is taken to be scalar-valued; otherwise,
%   it is taken to be SIZEC(1:end-m)-valued.
%
%   SPMAK(KNOTS,COEFS,SIZEC) uses SIZEC to specify the intended array
%   dimensions of COEFS, and may be needed for proper interpretation
%   of COEFS in case one or more of its trailing dimensions is a singleton
%   and thus COEFS appears to be of lower dimension.
%
%   Examples:
%
%   To construct a spline function with basic interval [1 .. 6], with 6
%   knots and 3 coefficients.
%      sp = spmak(1:6,0:2);
%      % The order of the spline is 6-3 = 3.
%      fnbrk(sp,'order')
%
%   Specify the third argument, SIZEC, to create a spline that is constant
%   in the last variable. For example, to construct a 3-vector-valued
%   bivariate polynomial on the rectangle [-1 .. 1] x [0 .. 1], linear in
%   the first variable and constant in the second, specify SIZEC. In this
%   case SIZEC = [3 2 1] because the dimension, d, of the target is 3, the
%   polynomial is linear (order = 2) in the first variable and constant
%   (order = 1) in the second variable.
%      knots = {[-1 -1 1 1], [0 1]};
%      coefs = [0.49 0.8; 0.14 0.42; 0.92 0.79];
%      sizec = [3 2 1];
%      sp = spmak(knots,coefs,sizec);
%      [dimension,order] = fnbrk(sp,'dimension','order')
%
%   See also SPBRK, RSMAK, PPMAK, RPMAK, STMAK, FNBRK.

%   Copyright 1987-2014 The MathWorks, Inc.

if nargin==0;
    knots = input('Give the vector of knots  >');
    coefs = input('Give the array of B-spline coefficients  >');
end

if nargin>2
    if numel(coefs)~=prod(sizec)
        error(message('SPLINES:SPMAK:coefsdontmatchsize'))
    end
else
    if isempty(coefs)
        error(message('SPLINES:SPMAK:emptycoefs'))
    end
    sizec = size(coefs);
end

m = 1;
if iscell(knots)
    m = length(knots);
end
if length(sizec)<m
    error(message('SPLINES:SPMAK:coefsdontmatchknots', sprintf( '%g', m ), sprintf( '%g', m )))
end
if length(sizec)==m,  % coefficients of a scalar-valued function
    sizec = [1 sizec];
end

% convert ND-valued coefficients into vector-valued ones, retaining the
% original size in SIZEVAL, to be stored eventually in SP.DIM .
sizeval = sizec(1:end-m);
sizec = [prod(sizeval), sizec(end-m+(1:m))];
coefs = reshape(coefs, sizec);

if iscell(knots), % we are putting together a tensor-product spline
    [knots,coefs,k,sizec] = chckknt(knots,coefs,sizec);
else            % we are putting together a univariate spline
    [knots,coefs,k,sizec] = chckknt({knots},coefs,sizec);
    knots = knots{1};
end

spline.form = 'B-';
spline.knots = knots;
spline.coefs = coefs;
spline.number = sizec(2:end);
spline.order = k;
spline.dim = sizeval;
% spline = [11 d n coefs(:).' k knots(:).'];
end

function [knots,coefs,k,sizec] = chckknt(knots,coefs,sizec)
%CHCKKNT check knots, omit trivial B-splines

for j=1:length(sizec)-1
    n = sizec(j+1);
    k(j) = length(knots{j})-n;
    if k(j)<=0
        error(message('SPLINES:SPMAK:knotsdontmatchcoefs')),
    end
    if any(diff(knots{j})<0)
        error(message('SPLINES:SPMAK:knotdecreasing'))
    end
    if knots{j}(1)==knots{j}(end)
        error(message('SPLINES:SPMAK:extremeknotssame'))
    end
    
    % make sure knot sequence is a row matrix:
    knots{j} = reshape(knots{j},1,n+k(j));
    % throw out trivial B-splines:
    index = find(knots{j}(k(j)+(1:n))-knots{j}(1:n)>0);
    if length(index)<n
        oldn = n;
        n = length(index);
        knots{j} = reshape(knots{j}([index oldn+(1:k(j))]),1,n+k(j));
        coefs = ...
            reshape(coefs, [prod(sizec(1:j)),sizec(j+1),prod(sizec(j+2:end))]);
        sizec(j+1) = n;
        coefs = reshape(coefs(:,index,:),sizec);
    end
end
end
