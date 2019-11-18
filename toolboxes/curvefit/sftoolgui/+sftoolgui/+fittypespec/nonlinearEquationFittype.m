function [aFittype, errorString] = nonlinearEquationFittype( equation, independentVariables, dependentVariable )
% nonlinearEquationFittype   Create a fittype from equation and variable names
%
%   Syntax:
%       [aFittype, errorString] = nonlinearEquationFittype( ...
%           equation, independentVariables, dependentVariable )
%
%   Inputs
%       equation -- char-array which represents the equation.
%       independentVariables -- cell array of strings which represent the
%           independent variables.
%       dependentVariable -- char-array which represents the dependent variable.
%
%   Outputs
%       aFittype -- If the equation and variables are valid, then this is a
%           fittype that represents the equation. If the equation or variables
%           are invalid, then it is an empty fittype.
%
%       errorString -- If the equation and variables are valid, then this is an
%           empty string. If the equation or variables are invalid, then it is a
%           string that contains a message explaining why they are invalid.
%
%   See also: fittype

%   Copyright 2010-2015 The MathWorks, Inc.

errorString = '';
aFittype = fittype();

% Check that inputs are the correct type
if ~ischar( equation )
    errorString = getString(message('curvefit:cftoolgui:EquationMustBeAString'));
    
elseif ~iscellstr( independentVariables )
    errorString = getString(message('curvefit:cftoolgui:IndependentVariablesMustBeACellArrayOfStrings'));
    
elseif ~ischar( dependentVariable )
    errorString = getString(message('curvefit:cftoolgui:DependentVariableMustBeAString'));
    
else
    % Trim any white space from the variable names.
    independentVariables = strtrim( independentVariables );
    dependentVariable = strtrim( dependentVariable );
    
    % Try to create a fittype from the equation and variable names.
    try
        aFittype = fittype( equation, 'independent', independentVariables, 'dependent', dependentVariable );
    catch ME
        errorString = iExceptionToErrorString( ME, equation, independentVariables );
    end
end
end

function errorString = iExceptionToErrorString( ME, equation, independentVariables )
switch ME.identifier
    case 'curvefit:fittype:missingIndVar'
        errorString =  iHandleMissingIndependent(independentVariables, ME.message);
    case 'curvefit:fittype:TooManyInputsForLibraryModel'
        errorString = getString(message('curvefit:cftoolgui:NotAValidEquation', equation));
    case 'curvefit:fittype:emptyExpression'
        errorString = getString(message('curvefit:cftoolgui:CannotCreateAnEquationFromAnEmptyExpression'));
    otherwise
        errorString = ME.message;
end
end

function errorString = iHandleMissingIndependent(independentVariables, theMessage)
% iHandleMissingIndependent   Customizes the "missingIndVar" error message. The
% original "missingIndVar" is appropriate when there is only one independent
% variable as is the case with cftool. We modify the message when there are 2
% independent variables such as the case with sftool equations.

if length(independentVariables) == 2
    errorString =  ...
        getString(message('curvefit:cftoolgui:BothIndependentVariablesMustAppearInTheEquation', ...
        independentVariables{1}, independentVariables{2}));
else
    errorString = theMessage;
end
end
