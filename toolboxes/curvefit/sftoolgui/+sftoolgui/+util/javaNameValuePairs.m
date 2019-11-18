function [ ja ] = javaNameValuePairs( fittype, options )
% javaNameValuePairs creates name/value pairs for the java panels.

%   Copyright 2010-2013 The MathWorks, Inc.

% First form cell-string of args, then form java string.

% The first few arguments are determined by the "type" of the
% fittype.
theType = type( fittype );
 
if strcmpi( theType, 'lowess' )
    % Lowess Linear
    args = {'''Polynomial''', '''Linear'''};
    
elseif strcmpi( theType, 'loess' )
    % Lowess Quadratic
    args = {'''Polynomial''', '''Quadratic'''};
       
elseif ~isempty( strfind( theType, 'interp') )
    % Interpolant
    % -- This is handled below by the "Method" from the fit options
    args = {};
    
else
    % Custom Equation
    args = {};
end

% The rest of the arguments come from the fit options
fn = fieldnames( options );
for i = 1:length( fn )
    optionValue = options.(fn{i});
    switch fn{i}
        case 'Normalize'
            args{end+1} = '''Normalize''';    %#ok<AGROW>
            args{end+1} = mat2str( optionValue ); %#ok<AGROW>
        case 'Span'
            args{end+1} = '''Span'''; %#ok<AGROW>
            % java wants to display this as a percent, so
            % multiply by 100;
            args{end+1} = mat2str( optionValue*100 ); %#ok<AGROW>
        case 'Method'
            args{end+1} = '''Method'''; %#ok<AGROW>
            args{end+1} = iTranslateMethodForJava( optionValue ); %#ok<AGROW>
        otherwise
            args{end+1} = sprintf( '''%s''', fn{i} ); %#ok<AGROW>
            args{end+1} = mat2str( optionValue );     %#ok<AGROW>
    end
end

% Now convert to a java array
n = length( args );
ja = javaArray( 'java.lang.String', n );
for i = 1:n
    ja(i) = javaObjectEDT( 'java.lang.String', args{i} );
end
end

function arg = iTranslateMethodForJava( method )
% iTranslateMethodForJava -- Translate the name of fitting method as used
% by FIT and translate to a name as used by the Java code.
%
% The returned name is an "evaluatable" string, i.e., if you evaluate the
% string you get another string. This means there are quote inside the
% string.
switch method
    case 'CubicSplineInterpolant'
        arg = '''cubic''';
    case 'NearestInterpolant'
        arg = '''nearest''';
    case 'LinearInterpolant'
        arg = '''linear''';
    case 'BiharmonicInterpolant'
        arg = '''v4''';
    case 'PchipInterpolant'
        arg = '''PCHIP''';
    case 'ThinPlateInterpolant'
        arg = '''thinplate''';
    otherwise 
        % Use the same Name in both FIT and Java.
        arg = sprintf( '''%s''', method );
end
end





