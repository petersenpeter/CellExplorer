function obj = subsasgn(obj, subs, value)
%SUBSASGN    subsasgn of cfit objects

%   Copyright 1999-2008 The MathWorks, Inc.

if (isempty(obj))
   error(message('curvefit:cfit:subsasgn:emptyFit'));
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
      obj.coeffValues{k} = value;
   elseif isempty(coeff) && ~isempty(prob)
      k = prob;
      obj.probValues{k} = value;
   else
      % As coefficients and problem parameters must be different, it must be
      % that the name the user gave us is neither coefficient not problem
      % parameter.
      error(message('curvefit:cfit:subsasgn:invalidName'))
   end

   % Uncertainty information is no longer valid
   if ~isempty(obj.sse) && ~isempty(obj.dfe) && ~isempty(obj.rinv)
      obj.sse = [];
      obj.dfe = [];
      obj.rinv = [];
      if ~isempty(coeff)
         warning(message('curvefit:cfit:subsasgn:coeffsClearingConfBounds'));
      else
         warning(message('curvefit:cfit:subsasgn:paramsClearingConfBounds'));
      end
   end
   
otherwise % case '{}', case '()'
   error(message('curvefit:cfit:subsasgn:dotNotationRequired'))
end




