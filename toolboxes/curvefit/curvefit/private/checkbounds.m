function [lb,ub,theError,theWarning] = checkbounds(lbin,ubin,nvars)
%CHECKBOUNDS checks bounds validity.
%   [LB,UB,errorMessage,WSTR,WARNID] = CHECKBOUNDS(LB,UB,nvars) 
%   checks that the upper and lower bounds are valid (LB <= UB) and the same 
%   length as X (pad with -inf/inf if necessary); warn if too long.  Also make 
%   LB and UB vectors if not already.
%   Finally, inf in LB or -inf in UB throws an error.

%   Copyright 2001-2011 The MathWorks, Inc.

theError = '';
theWarning = '';

% Turn into column vectors
lb = lbin(:); 
ub = ubin(:); 

lenlb = length(lb);
lenub = length(ub);

tooManyLowerBounds = false;
tooManyUpperBounds = false;
% Check maximum length
if lenlb > nvars
   theWarning = message( 'curvefit:checkbounds:tooManyLowerBounds' );
   lb = lb(1:nvars);   
   lenlb = nvars;
   tooManyLowerBounds = true;
elseif lenlb < nvars
   lb = [lb; -inf*ones(nvars-lenlb,1)];
   lenlb = nvars;
end

if lenub > nvars
   theWarning = message( 'curvefit:checkbounds:tooManyUpperBounds' );
   ub = ub(1:nvars);
   lenub = nvars;
   tooManyUpperBounds = true;
elseif lenub < nvars
   ub = [ub; inf*ones(nvars-lenub,1)];
   lenub = nvars;
end

if tooManyLowerBounds && tooManyUpperBounds
   theWarning = message( 'curvefit:checkbounds:tooManyBounds' );
end

% Check feasibility of bounds
len = min(lenlb,lenub);
if any( lb( (1:len)' ) > ub( (1:len)' ) )
   count = full(sum(lb>ub));
   if count == 1
      theError = message( 'curvefit:checkbounds:lowerBoundExceedsUpperBound', count );
      return;
   else
      theError = message( 'curvefit:checkbounds:lowerBoundsExceedsUpperBounds', count );
      return;
   end 
end
% check if -inf in ub or inf in lb   
if any(eq(ub, -inf)) 
   theError = message( 'curvefit:checkbounds:invalidUpperBound' );
   return;
elseif any(eq(lb,inf))
   theError = message( 'curvefit:checkbounds:invalidLowerBound' );
   return;
end

