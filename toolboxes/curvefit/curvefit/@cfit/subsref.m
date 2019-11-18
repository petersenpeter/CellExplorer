function out = subsref(obj, subs)
%SUBSREF Evaluate CFIT object.

%   Copyright 1999-2013 The MathWorks, Inc.

if (isempty(obj))
    error(message('curvefit:cfit:subsref:emptyFit'));
end

% In case nested subsref like f.p.coefs
currsubs = subs(1);

switch currsubs.type
    case '()'
        out = iParenthesesReference( obj, currsubs );
        
    case '.'
        out = iDotReference( obj, currsubs );
        
    otherwise % case '{}'
        error(message('curvefit:cfit:subsref:cellarrayBracketsNotAllowed'))
end

if length(subs) > 1
    subs(1) = [];
    out = subsref(out, subs);
end

end

function out = iParenthesesReference( obj, subs )
inputs = subs.subs;
if (length(inputs) < 1)
    error(message('curvefit:cfit:subsref:notEnoughInputs'));
elseif (length(inputs) > 1)
    error(message('curvefit:cfit:subsref:tooManyInputs'));
end

if (isempty(fevalexpr(obj)))
    out = [];
else
    try
        out= feval(obj,inputs{:});
    catch ignore
        error(message('curvefit:cfit:subsref:cannotEvaluateModel'))
    end
end
end

function out = iDotReference( obj, subs )

argname = subs.subs;
% is it coeff or prob parameter?
coeff = strcmp( argname, coeffnames(obj) );
prob = strcmp( argname, probnames(obj) );
% which index is it?
if any( coeff )
    out = obj.coeffValues{coeff};
elseif any( prob )
    out = obj.probValues{prob};
else
    % As coefficients and problem parameters must be different, it must be
    % that the name the user gave us is neither coefficient not problem
    % parameter.
    
    coefficients = coeffnames(obj);
    exampleParameter = iGetExampleParameterForFit(coefficients);
    
    ME = curvefit.exception( 'curvefit:cfit:subsref:invalidName',  subs.subs, exampleParameter, strjoin(coefficients', ', ') );
    throwAsCaller( ME );
end
end

function exampleParameter = iGetExampleParameterForFit(coefficients)
exampleParameter = 'p1';
if ~isempty(coefficients)
    exampleParameter = coefficients{1};
end
end
