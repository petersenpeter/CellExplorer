function [X, residual, output] = cflsqlin( C, d, lb, ub, fitopt)
%CFLSQLIN Constrained linear least squares.
%
%   X=CFLSQLIN(C,d,lb,ub) solves the least-squares problem
%
%           min  0.5*(NORM(C*x-d)).^2       subject to    lb <= x <= ub
%            x
%
%   where C is m-by-n.
%
%   Use empty matrices for lb and ub if no bounds exist. Set lb(i) = -Inf if
%   X(i) is unbounded below; set ub(i) = Inf if  X(i) is unbounded above.
%
%   X=CFLSQLIN(C,d,lb,ub,OPTIONS) minimizes with the default optimization
%   parameters replaced by values in the fitoptions object OPTIONS. 
%
%   See also FIT, LSQLIN

%   Copyright 1990-2014 The MathWorks, Inc.

if isempty(C) || isempty(d)
   error(message('curvefit:cflsqlin:invalidArgs'))
end

% convert FITOPTIONS to OPTIMOPTIONS
options = optimset(get(fitopt));

% Make sure that OPTIM doesn't display stuff
options.Display = 'none';

% Call CFALSLNSH
[X,~,residual,~,output] = cfalslnsh(C,d,[],[],[],[],lb,ub,[],options);
end