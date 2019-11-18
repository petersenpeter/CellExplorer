function testCustomModelEvaluation( obj )
% testCustomModelEvaluation   Test that when a custom model is evaluated it does
% not throw an error.

%   Copyright 1999-2013 The MathWorks, Inc.

% Create example values for input arguments
independentValues = iExampleIndependentValues( obj );
problemValues = iExampleProblemValues( obj );
coefficients = iExampleCoefficients( obj );

iAssertCustomEquationIsEvaluable(obj, problemValues, independentValues, coefficients);

dependentValues = iEvaluateCustomEquation(obj, problemValues, independentValues, coefficients);

iAssertCustomEquationIsVectorized(obj, dependentValues, independentValues);
end

function r = iArbitrary( k )
% iArbitrary( K ) is a row vector of K arbitrary values. This can be
% thought of as a substitute for RAND( 1, K ) when the "random" aspect
% is not required.
r = (1:k)/(k+1);
end

function values = iExampleIndependentValues( obj )
% iExampleIndependentValues   A cell array of example independent variables for
% the given fittype object.

ARBITRARY_NUM_VALUES = 7;
if numindep( obj ) == 1
    values = {iArbitrary( ARBITRARY_NUM_VALUES ).'}; 
else % numindep( obj ) == 2
    values = {iArbitrary( ARBITRARY_NUM_VALUES ).', 1-iArbitrary( ARBITRARY_NUM_VALUES ).'}; 
end
end

function probparams = iExampleProblemValues(obj)
% iExampleProblemValues   A cell array of example problem parameters (all
% scalars) for the given fittype object
numProblemParameters = numargs(obj)-obj.numCoeffs-numindep( obj );
probparams = num2cell( iArbitrary( numProblemParameters ) );
end

function coefficients = iExampleCoefficients(obj)
% iExampleCoefficients   A cell array of example coefficients (all scalars) for
% the given fittype object

if iHasValidStartPoint( obj )
    coefficients = num2cell( obj.fFitoptions.StartPoint );
else
    coefficients = num2cell( iArbitrary( obj.numCoeffs ) );
end
end

function tf = iHasValidStartPoint( obj )
% iHasValidStartPoint   True for a fittype with a valid start point, i.e., the
% fit options has a start point field and the number of elements of that field
% matches the number of coefficients
tf = ~isempty(findprop(obj.fFitoptions, 'StartPoint')) && ...
    isequal(length(obj.fFitoptions.StartPoint),obj.numCoeffs);
end

function iAssertCustomEquationIsVectorized(obj, dependentValues, independentValues)
% iAssertCustomEquationIsVectorized   Throws an error if the independent
% values and dependent values of the custom equation indicate that the
% function is not vectorized.
if ~isequal(size(dependentValues), size(independentValues{1}))
    newError = curvefit.exception('curvefit:fittype:nonVectorOutput', obj.formula);
    throwAsCaller( newError );
end
end

function iAssertCustomEquationIsEvaluable(obj, problemValues, independentValues, coefficients)
% iAssertCustomEquationIsEvaluable   Throws an error if the custom equation
% cannot be evaluated
try
    % Try to evaluate the model
    if islinear( obj ) 
        % Also eval to get coefficient matrix
        [~] = getcoeffmatrix( obj, problemValues{:}, independentValues{:} );
    end
    [~] = iEvaluateCustomEquation(obj, problemValues, independentValues, coefficients);
    
catch caughtError
    newError = curvefit.exception( 'curvefit:fittype:invalidExpression', ...
        obj.defn, caughtError.message );
    
    newError = addCause( newError, caughtError ); 
    throwAsCaller( newError );
end
end

function dependentValues = iEvaluateCustomEquation(obj,problemValues,independentValues,coefficients)
% iEvaluateCustomEquation   Calculate the dependent values of a custom
% equation from the coefficients, problem values and independent values
dependentValues = feval( obj, coefficients{:}, problemValues{:}, independentValues{:} );
end
