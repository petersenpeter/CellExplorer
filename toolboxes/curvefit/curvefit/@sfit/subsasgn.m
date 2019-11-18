function obj = subsasgn(obj, subs, value)
%SUBSASGN    subsasgn of sfit objects

%   Copyright 2008 The MathWorks, Inc.

if (isempty(obj))
   error(message('curvefit:sfit:subsasgn:emptyFit'));
end

% In case nested subsref like f.p.coefs
currsubs = subs(1);

if length(subs) > 1
    subs(1) = [];
    value = subsasgn(subsref(obj,currsubs), subs, value); 
end

switch currsubs.type
case '.'
   argname = currsubs.subs;
   % is it coeff or prob parameter?
   coeff = strmatch(argname,coeffnames(obj),'exact');
   prob = strmatch(argname,probnames(obj),'exact');
   % which index is it?
   if ~isempty(coeff) && isempty(prob)
      k = coeff;
      obj.fCoeffValues{k} = value;
   elseif isempty(coeff) && ~isempty(prob)
      k = prob;
      obj.fProbValues{k} = value;
   else
      % As coefficients and problem parameters must be different, it must be
      % that the name the user gave us is neither coefficient not problem
      % parameter.
      error(message('curvefit:sfit:subsasgn:invalidName'))
   end

   % Uncertainty information is no longer valid
   if ~isempty(obj.sse) && ~isempty(obj.dfe) && ~isempty(obj.rinv)
      obj.sse = [];
      obj.dfe = [];
      obj.rinv = [];
      if ~isempty(coeff)
         warning(message('curvefit:sfit:subsasgn:coeffsClearingConfBounds'));
      else
         warning(message('curvefit:sfit:subsasgn:paramsClearingConfBounds'));
      end
   end
   
otherwise % case '{}', case '()'
   error(message('curvefit:sfit:subsasgn:dotNotationRequired'))
end




