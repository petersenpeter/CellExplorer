function fopts = createFitOptions( ft, optionNameValuePairs, coefficientOptions)
% createFitOptions creates options for the given fittype
%
%   Example
%       coefficientOps = sftoolgui.MutableCoefficientCache();
%       opts = sftoolgui.util.createFitOptions(fittype, {}, coefficientOps)

%   Copyright 2011-2012 The MathWorks, Inc.

%   Get the "type" of the fittype.
if isempty(ft) % invalid custom equation. Set up default options and return
    % Set options to the default
    fopts = iDefaultOptions();
    return;
end

theType = type( ft );

startpoint = iGenerateStartPoints(ft, coefficientOptions);
lower = iGenerateLowerBounds(ft, coefficientOptions);
upper = iGenerateUpperBounds(ft, coefficientOptions);

% Interpolant and Smoothing Spline
if ~isempty( strfind( theType, 'interp' ) ) || ...
        strcmpi( theType, 'smoothingspline')
    fopts = iTranslateInputs( ft, optionNameValuePairs{:} );
    
    % Lowess
elseif strcmpi('lowess', theType) || strcmpi('loess', theType)
    fopts = iTranslateLowessInputs(ft, optionNameValuePairs{:} );
    
    % Non-linear parametrics
elseif strcmpi(theType, 'customnonlinear') || ...
        strncmpi( theType, 'exp', 3) || ...
        strncmpi( theType, 'fourier', 7) || ...
        strncmpi( theType, 'gauss', 5) || ...
        strncmpi( theType, 'power', 5) || ...
        strncmpi( theType, 'rat', 3) || ...
        strncmpi( theType, 'sin', 3) || ...
        strcmpi( theType, 'weibull')
    
    fopts = iTranslateInputs(ft, optionNameValuePairs{:});
    fopts.Lower = lower;
    fopts.Upper = upper;
    fopts.StartPoint = startpoint;
    % Turn off display
    fopts.Display = 'off';
    
    % Linear models (polynomials and custom linear)
elseif strncmpi( theType, 'poly', 4 ) || ...
        strcmpi(theType, 'customlinear')
    fopts = iTranslateInputs(ft, optionNameValuePairs{:} );
    fopts.Lower = lower;
    fopts.Upper = upper;
    
    % Else it is an unknown type
else
    warning(message('curvefit:sftoolgui:util:createFitOptions:UnknownFittype', theType));
    % Set options to the default
    fopts = iDefaultOptions();
end
end

function fopts = iTranslateInputs( ft, varargin )
% iTranslateInputs translates option name value pairs.
fopts = fitoptions( ft );
for i = 1:2:length( varargin )
    try
        fopts.(varargin{i}) = varargin{i+1};
    catch ME
        disp( getReport( ME ) );
    end
end
end

function fopts = iTranslateLowessInputs(ft, varargin )
% iTranslateLowessInputs translates lowess name value pairs.
p = inputParser;
p.addParamValue( 'Normalize', 'on' );
p.addParamValue( 'Robust', 'off' );
p.addParamValue( 'Span', 25 );
p.parse( varargin{:} );

fopts = fitoptions( ft );
% in java, span is represented as a percent, so divide by 100 here.
fopts.Span = p.Results.Span/100;
fopts.Robust = p.Results.Robust;
fopts.Normalize = p.Results.Normalize;
end

function fopts = iDefaultOptions()
% iDefaultOptions creates default fit options
fopts = fitoptions( 'Method', 'NonlinearLeastSquares' );

% Turn off display
fopts.Display = 'off';
end

function startPoints = iGenerateStartPoints(ft, coefficientOptions)
coeffs = coeffnames(ft);
startPoints = coefficientOptions.getStartPoint(coeffs);
nBlanks = sum(isnan(startPoints));
startPoints(isnan(startPoints)) = rand(nBlanks, 1);
end

function lower = iGenerateLowerBounds(ft, coefficientOptions)
coeffs = coeffnames(ft);
lower = coefficientOptions.getLowerBound(coeffs);
lower(isnan(lower)) = -inf;
end

function upper = iGenerateUpperBounds(ft, coefficientOptions)
coeffs = coeffnames(ft);
upper = coefficientOptions.getUpperBound(coeffs);
upper(isnan(upper)) = inf;
end
