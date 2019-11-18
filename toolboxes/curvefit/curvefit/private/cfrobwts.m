function w = cfrobwts(robtype,r)
%CFROBWTS Compute bisquare weights for robust curve fitting.
%   W = CFROBWTS(R) computes a weight vector W as a function of a
%   scaled residual vector R.

%   Copyright 2001-2008 The MathWorks, Inc.

if isequal(robtype,'lar')
   w = 1 ./ max(eps,abs(r));
else
   w = (abs(r)<1) .* (1 - r.^2).^2;
   if all(w(:)==0)
      w(:) = 1;
   end
end

