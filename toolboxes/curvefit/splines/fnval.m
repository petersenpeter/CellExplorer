function v = fnval(f,varargin)
%FNVAL Evaluate a function.
%
%   V = FNVAL(F,X)  or  FNVAL(X,F)  provides the value at the points
%   in  X  of the function described by  F .
%
%   Roughly speaking, V is obtained by replacing each entry of X by the 
%   value of  f  there. This is exactly true in case  f  is scalar-valued
%   and univariate, and is the intent in all other cases, except that, for a 
%   d-valued m-variate function, this means replacing m-vectors by d-vectors.
%   The full details follow.
%
%   For a univariate  f :
%   If f is scalar-valued, then V is of the same size as X. 
%   If f is [d1,...,dr]-valued, and X has size [n1,...,ns], then V has size
%   [d1,...,dr, n1,...,ns], with V(:,...,:, j1,...,js) the value of  f  at 
%   X(j1,...,js), -- except that 
%   (1) n1 is ignored if it is 1 and s is 2, i.e., if X is a row vector; and
%   (2) MATLAB ignores any trailing singleton dimensions of X.
%
%   For an m-variate  f  with  m>1 ,  with  f  [d1,...,dr]-valued, X may be
%   either an array, or else a cell array {X1,...,Xm}.
%   If X is an array, of size [n1,...,ns] say, then n1 must equal m, and V has
%   size [d1,...,dr, n2,...,ns], with V(:,...,:, j2,...,js) the value of  f
%   at X(:,j2,...,js), -- except that
%   (1) d1, ..., dr is ignored in case  f  is scalar-valued, i.e., r==1==d1;
%   (2) MATLAB ignores any trailing singleton dimensions of X.
%   If X is a cell array, then it must be of the form {X1,...,Xm}, with Xj
%   a vector, of length nj, and, in that case, V has size
%   [d1,...,dr, n1,...,nm], with V(:,...,:, j1,...,jm) the value of  f
%   at (X1(j1), ..., Xm(jm)), -- except that
%   d1, ..., dr is ignored in case  f  is scalar-valued, i.e., r==1==d1.
%
%   By agreement, all piecewise polynomial functions in this toolbox are
%   continuous from the right. But FNVAL can be made to treat them as
%   continuous from the left by calling it with an optional third argument,
%   as follows.
%
%   FNVAL(F,X,LEFT)  or  FNVAL(X,F,LEFT)  takes the function to be
%   left-continuous if LEFT is a string that begins with 'l'.
%   If the function is m-variate and LEFT is an m-cell, then continuity
%   from the left is enforced in the i-th  variable if  LEFT{i}(1) is 'l'.
%
%   See also  PPUAL, RSVAL, SPVAL, STVAL, PPVAL.

%   Copyright 1987-2010 The MathWorks, Inc.

if ~isstruct(f)
   if isstruct(varargin{1})
      temp = f; f = varargin{1}; varargin{1} = temp;
   else
      f = fn2fm(f);
   end
end

try
   [m, sizeval] = fnbrk(f,'var','dim');
catch
   error(message('SPLINES:FNVAL:unknownform', f.form))
end
    % record, then adjust, size of site array and of function values.
sizex = size(varargin{1});
if ~iscell(varargin{1})
   if m>1
      if sizex(1)~=m
         error(message('SPLINES:FNVAL:wrongsizex', num2str( m )))
      end
   sizex(1) = [];
   end
   if length(sizex)>2
      varargin{1} = reshape(varargin{1},sizex(1),prod(sizex(2:end)));
   elseif length(sizex)==2&&sizex(1)==1, sizex = sizex(2); end
else
   if sizex(2)~=m
      if sizex(2)==1&&sizex(1)==m, varargin{1}=varargin{1}.';
      else
         error(message('SPLINES:FNVAL:wrongsizecellx', num2str( m )))
      end
   end
   sizex = cellfun('length',varargin{1});
end
if length(sizeval)>1, f = fnchg(f,'dz',prod(sizeval));
else if sizeval==1&&length(sizex)>1; sizeval = []; end
end

switch f.form(1)
case 'B',  ff = @spval;
case 'p',  ff = @ppual;
case 'r',  ff = @rsval;
case 's',  ff = @stval;
otherwise
   error(message('SPLINES:FNVAL:unknownfn'))
end

v = reshape(feval(ff,f,varargin{:}),[sizeval,sizex]);
