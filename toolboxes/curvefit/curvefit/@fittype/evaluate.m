function varargout = evaluate(varargin)
%EVALUATE Evaluate a FITTYPE object
%
%   F = FEVAL(FITOBJ,A,B,...,X) evaluates the function
%   value F of FITOBJ with coefficients A,B,... and data X.
%
%   [F, J] = FEVAL(FITOBJ,A,B,...,X) evaluates the function
%   value F and Jacobian J, with respect to the coefficients,
%   of FITOBJ with coefficients A,B,... and data X.

%   Some special syntaxes used by the FIT command:
%   [F,...] = FEVAL(FITOBJ,P,X,...,'optim') evaluates the function
%   value F of FITOBJ with the vector of coefficients P by transforming
%   P from a vector into a comma separated list of values matching
%   the syntax of FITOBJ and data X. This is used by optimization routines
%   that expect the coefficients to be gathered together into one vector
%   rather than some number of scalars.
%
%   [F,...] = FEVAL(FITOBJ,P,X,...,W,'optimweight') is the same as 'optim'
%   but multiplies F and J by the weight vector W.
%   This is used by optimization routines.
%
%   [F,...] = FEVAL(FITOBJ,P,X,Y,'separable',...) is for separable equations,
%   for use with the 'optim' or 'optimweight' flags.

%   Copyright 1999-2013 The MathWorks, Inc.

flag = varargin{end};
if iIsFlag(flag,'optimweight')
    weight = varargin{end-1};
    varargin(end-1:end) = []; % leave out 'optimweight' and w arguments
elseif iIsFlag(flag,'optim')
    varargin(end) = []; % leave out 'optim' argument
end

FITTYPE_OBJ_ = varargin{1};

if ~isa(FITTYPE_OBJ_,'fittype')
    % If any of the elements in varargin are fittype objects, then the
    %  overloaded fittype feval is called even if the first argument
    %  is a string.  In this case, we call the builtin feval.
    [varargout{1:max(1,nargout)}] = builtin('feval',varargin{:});
    return
end

if (iIsFlag(flag,'optim') || iIsFlag(flag,'optimweight'))
    % Change a vector of coefficients into individual coefficient inputs
    coeffcells = mat2cell(varargin{2});
    % Reorder so xdata is after probparams: optim code sends it in
    % the wrong order. Also pull it out as separate columns
    xdata = num2cell( varargin{3}, 1 );
    probparams = varargin(4:end);
    FITTYPE_INPUTS_ = [coeffcells, probparams, xdata];
else
    FITTYPE_INPUTS_ = varargin(2:end);
end

if ~iIsFlag( varargin{end}, 'separable' ) && ~iIsFlag( varargin{end-1}, 'separable' )
    if (length(FITTYPE_INPUTS_) < FITTYPE_OBJ_.numArgs)
        error(message('curvefit:fittype:feval:notEnoughInputs'));
    elseif (length(FITTYPE_INPUTS_) > FITTYPE_OBJ_.numArgs)
        error(message('curvefit:fittype:feval:tooManyInputs'));
    end
end

% Add constants. Only affects library functions potentially,
% but not a problem anyway.
% Do this after the .numArgs check as .numArgs doesn't include the
% constants.
% The constants get inserted just before the values of the
% independent variables, which are at the end.
NUM_INDEP_ = size( FITTYPE_OBJ_.indep, 1 );
FITTYPE_INPUTS_ = [...
    FITTYPE_INPUTS_(1:end-NUM_INDEP_), ...
    FITTYPE_OBJ_.fConstants(:)', ...
    FITTYPE_INPUTS_(end-NUM_INDEP_+1:end)
    ];

if FITTYPE_OBJ_.fFeval
    % feval a function
    try
        [varargout{1:max(1,nargout)}] = feval(FITTYPE_OBJ_.expr, FITTYPE_INPUTS_{:});
    catch e
        error(message('curvefit:fittype:feval:evaluationError', inputname( 1 ), e.message));
    end
    
else % eval an expression
    
    if (isempty(FITTYPE_OBJ_.expr))
        if nargout==1
            varargout{1} = [];
        elseif nargout == 2
            varargout{1:2} = [];
        end
    else
        try
            eval( FITTYPE_OBJ_.assignCoeff );
            eval( FITTYPE_OBJ_.assignProb );
            eval( FITTYPE_OBJ_.assignData );
            [~, varargout{1:max(1,nargout)}] = evalc(FITTYPE_OBJ_.expr);
        catch e
            error(message('curvefit:fittype:feval:expressionError', FITTYPE_OBJ_.expr, e.message));
        end
    end
end

if iIsFlag(flag,'optimweight') && ~isempty(weight)
    % Assumes that weight is a column vector
    sqrtwt = sqrt(weight);
    varargout{1} = sqrtwt.*varargout{1};
    if nargout >= 2
        varargout{2} = repmat(sqrtwt,1,size(varargout{2},2)) .* varargout{2};
    end
end

if iIsFlag(flag,'optimweight') || iIsFlag(flag,'optim')
    if any(isnan(varargout{1}))
        error(message('curvefit:fittype:feval:modelComputedNaN'));
    elseif any(isinf(varargout{1}))
        error(message('curvefit:fittype:feval:modelComputedInf'));
    elseif any(~isreal(varargout{1}))
        error(message('curvefit:fittype:feval:modelComputedComplex'));
    elseif nargout==2 && any(isnan(varargout{2}(:)))
        error(message('curvefit:fittype:feval:JacobianComputedNaN'));
    elseif nargout==2  && any(isinf(varargout{2}(:)))
        error(message('curvefit:fittype:feval:JacobianComputedInf'));
    elseif nargout==2 && any(~isreal(varargout{2}(:)))
        error(message('curvefit:fittype:feval:JacobianComputedComplex'));
    end
end

% Convert any complex (non-zero imaginary part) numbers to NaN.
varargout{1} = curvefit.nanFromComplexElements( varargout{1} );
end

%------------------------------------------
function c = mat2cell(a)
% Convert a matrix to a cell array in column order
% (Simpler case than num2cell so much faster)

n = numel( a );
c = cell( 1, n );

for i = 1:n
    c{i} = a(i);
end

end

%------------------------------------------
function tf = iIsFlag( actualFlag, expectedFlag )
% iIsFlag   True if actual flag is a char array and is equal to the expected
% flag.
tf = ischar( actualFlag ) && isequal( actualFlag, expectedFlag );
end
