function pp = ppmak(breaks,coefs,d)
%PPMAK Put together a spline in ppform.
%
%   PPMAK(BREAKS,COEFS)  puts together a spline in ppform from the breaks
%   BREAKS and coefficient matrix COEFS. Each column of COEFS is
%   taken to be one coefficient, i.e., the spline is taken to be D-vector
%   valued if COEFS has D rows. Further, with L taken as length(BREAKS)-1,
%   the order K of the spline is computed as (# cols(COEFS))/L, and COEFS is
%   interpreted as a three-dimensional array of size [D,K,L], with
%   COEFS(i,:,j) containing the local polynomial coefficients for the i-th
%   component of the j-th polynomial piece, from highest to lowest.
%
%   PPMAK  will prompt you for BREAKS and COEFS.
%
%   PPMAK(BREAKS,COEFS,D), with D a positive integer, interprets the matrix
%   COEFS to be of size [D,L,K], with COEFS(i,j,:) containing the local
%   polynomial coefficients, from highest to lowest, of the i-th component
%   of the j-th polynomial piece.
%   In particular, the order K is taken to be the last dimension of COEFS,
%   and L is taken to be length(COEFS(:))/(D*K),
%   and BREAKS is expected to be of length L+1.
%   The toolbox uses internally only this second format, reshaping COEFS
%   to be of size [D*L,K].
%
%   For example,  ppmak([1 3 4],[1 2 5 6;3 4 7 8])  and
%                 ppmak([1 3 4],[1 2;3 4;5 6;7 8],2)
%   specify the same function (2-vector-valued, of order 2).
%
%   PPMAK(BREAKS,COEFS,SIZEC), with SIZEC a vector of positive integers,
%   interprets COEFS to be of size SIZEC =: [D,L,K], with COEFS(i,j,:)
%   containing the polynomial coefficient, from highest to lowest, of the i-th
%   component of the j-th polynomial piece. The dimension of the function's
%   target is taken to be SIZEC(1:end-2). Internally, COEFS is reshaped into a
%   matrix, of size [prod(SIZEC(1:end-1)),K].
%
%   For example, to make up the constant function, with basic interval [0..1]
%   say, whose value is the matrix EYE(2), you have to use the command
%      ppmak(0:1, eye(2), [2,2,1,1]);
%
%   PPMAK({BREAKS1,...,BREAKSm},COEFS)  puts together an m-variate
%   tensor-product spline in ppform. In this case, COEFS is expected to be of
%   size [D,lk], with lk := [l1*k1,...,lm*km] and li = length(BREAKS{i})-1,
%   all i, and this defines D and k := [k1,...,km].  If, instead, COEFS is
%   only an m-dimensional array, then D is taken to be 1.
%
%   PPMAK({BREAKS1,...,BREAKSm},COEFS,SIZEC)  uses the optional third argument
%   to specify the size of COEFS. The intended size of COEFS is needed in case
%   one or more of its trailing dimensions is a singleton and thus COEFS by
%   itself appears to be of lower dimension.
%
%   For example, if we intend to construct a 2-vector-valued bivariate
%   polynomial on the rectangle [-1 .. 1] x [0 .. 1], linear in the first
%   variable and constant in the second, say
%      coefs = zeros(2,2,1); coefs(:,:,1) = [1 0; 0 1];
%   then the straightforward
%      pp = ppmak({[-1 1],[0 1]},coefs);
%   will fail, producing a scalar-valued function of order 2 in each variable,
%   as will
%      pp = ppmak({[-1 1],[0 1]},coefs,size(coefs));
%   while the command
%      pp = ppmak({[-1 1],[0 1]},coefs,[2 2 1]);
%   will succeed.
%
%   See also PPBRK, RPMAK, SPMAK, RSMAK, STMAK, FNBRK.

%   Copyright 1987-2013 The MathWorks, Inc.

if nargin==0
    breaks=input('Give the (l+1)-vector of breaks  >');
    coefs=input('Give the (d by (k*l)) matrix of local pol. coefficients  >');
end

sizec = size(coefs);

if iscell(breaks)
    % we are dealing with a tensor-product spline
    if nargin>2
        if prod(sizec)~=prod(d)
            error(message('SPLINES:PPMAK:coefsdontmatchsize'))
        end
        sizec = d;
    end
    [breaks,coefs,sizeval,l,k] = iMultivariateSpline(breaks,coefs,sizec);
else
    if nargin<3
        [coefs,sizeval,l,k] = iUnivariateWithoutD(breaks,coefs,sizec);
    else
        [coefs,sizeval,l,k] = iUnivariateWithD(breaks,coefs,sizec,d);
    end
    breaks = reshape(breaks,1,l+1);
end
pp.form = 'pp';
pp.breaks = breaks;
pp.coefs = coefs;
pp.pieces = l;
pp.order = k;
pp.dim = sizeval;
end

function [breaks,coefs,sizeval,l,k] = iMultivariateSpline(breaks,coefs,sizec)
m = length(breaks);
if length(sizec)<m
    error(message('SPLINES:PPMAK:coefslengthlessthanbreakslength'));
end
if length(sizec)==m,  % coefficients of a scalar-valued function
    sizec = [1 sizec];
end
sizeval = sizec(1:end-m);
sizec = [prod(sizeval), sizec(end-m+(1:m))];
coefs = reshape(coefs, sizec);

for i=m:-1:1
    l(i) = length(breaks{i})-1;
    k(i) = fix(sizec(i+1)/l(i));
    if k(i)<=0||k(i)*l(i)~=sizec(i+1)
        error(message('SPLINES:PPMAK:piecesdontmatchcoefsforvar', sprintf( '%g', l( i ) ), sprintf( '%g', sizec( i + 1 ) ), sprintf( '%g', i )))
    end
    breaks{i} = reshape(breaks{i},1,l(i)+1);
end
end

function [coefs,sizeval,l,k] = iUnivariateWithoutD(breaks,coefs,sizec)
if isempty(coefs)
    error(message('SPLINES:PPMAK:emptycoefs'))
end
sizeval = sizec(1:end-1);
d = prod(sizeval);
kl = sizec(end);
l=length(breaks)-1;
k=fix(kl/l);
if (k<=0)||(k*l~=kl)
    error(message('SPLINES:PPMAK:piecesdontmatchcoefs', sprintf( '%g', l ), sprintf( '%g', kl )));
elseif any(diff(breaks)<0)
    error(message('SPLINES:PPMAK:decreasingbreaks'))
elseif breaks(1)==breaks(l+1)
    error(message('SPLINES:PPMAK:extremebreakssame'))
else
    % the ppformat expects coefs in array  (d*l) by k, while the standard
    % input supplies them in an array d by (k*l) . This requires the
    % following shuffling, from  D+d(-1+K + k(-1+L))=D-d +(K-k)d + dkL
    % to  D+d(-1+L + l(-1+K)=D-d +(L-l)d + dlK .
    % This used to be handled by the following:
    % c=coefs(:); temp = ([1-k:0].'*ones(1,l)+k*ones(k,1)*[1:l]).';
    % coefs=[1-d:0].'*ones(1,kl)+d*ones(d,1)*(temp(:).');
    % coefs(:)=c(coefs);
    % Thanks to multidimensional arrays, we can now simply say
    coefs = reshape(permute(reshape(coefs,[d,k,l]),[1,3,2]),d*l,k);
end
end

function [coefs,sizeval,l,k] = iUnivariateWithD(breaks,coefs,sizec,d)
% in the univariate case, a scalar D only specifies the dimension of
% the target and COEFS must be a matrix (though that is not checked for);
% but if D is a vector, then it is taken to be the intended size of
% COEFS whatever the actual dimensions of COEFS might be.
if length(d)==1
    k = sizec(end);
    l = prod(sizec(1:end-1))/d;
else
    if prod(d)~=prod(sizec)
        error(message('SPLINES:PPMAK:coefssizemismatch', num2str( sizec ), num2str( d )));
    end
    k = d(end);
    l = d(end-1);
    d(end-1:end) = [];
    if isempty(d),
        d = 1;
    end
    % Interpret the coefficients, COEFS, to be of size SIZEC =: [d,l,k]
    coefs = reshape(coefs, prod(d)*l,k);
end
if l+1~=length(breaks)
    error(message ('SPLINES:PPMAK:coefsdontmatchbreaks', ...
        sprintf('%g',l), sprintf('%g',length(breaks)-1)));
end
sizeval = d;
end
