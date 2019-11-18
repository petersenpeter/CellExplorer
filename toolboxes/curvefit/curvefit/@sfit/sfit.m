classdef (Sealed = true) sfit < fittype
    % SFIT   Surface Fit Object
    %
    %   An SFIT object encapsulates the result of fitting a surface to data. They
    %   are normally constructed by calling the FIT function.
    %
    %   An SFIT object can be treated as a function to make predictions or
    %   evaluate the surface at values of X and Y, e.g.,
    %
    %       x = 3 - 6 * rand( 49, 1 );
    %       y = 3 - 6 * rand( 49, 1 );
    %       z = peaks( x, y );
    %       sf = fit( [x, y], z, 'poly32' );
    %       zhat = sf( mean( x ), mean( y ) )
    %
    %   sfit methods:
    %       coeffvalues   - Coefficient values.
    %       confint       - Confidence intervals for the coefficients of a fit
    %                       result object.
    %       differentiate - Differentiate a surface fit object.
    %       feval         - FEVAL an SFIT object.
    %       plot          - Plot a surface fit object.
    %       predint       - Prediction intervals for a fit result object or new 
    %                       observations.
    %       probvalues    - Problem parameter values.
    %       quad2d        - Numerically integrate a surface fit object.
    %
    %   See also: FIT, FITTYPE, CFIT.
    
    %   Copyright 2008-2013 The MathWorks, Inc.
    
    properties( SetAccess = 'private', GetAccess = 'private' )
        % version number of class definition
        version = 2.0;
        
        % fCoeffValues -- Cell-array of values for the coefficients
        fCoeffValues = {};
        
        % fProbValues -- Cell-array of values for any parameters designated as
        % "problem specific parameters".
        fProbValues = {};
        
        % sse   sum squared of error
        sse = [];
        
        % dfe   degrees of freedom of error
        dfe = [];
        
        % rinv   inverse of R factor of QR decomposition of Jacobian
        rinv = [];

        % activebounds   Boolean array indicating which coefficients are at an
        % upper or lower bound. This should either be empty or a column vector
        % with one row for each coefficient.
        activebounds = [];
        
        % meanx   mean of the x data used to center the data
        meanx = 0;
        % meany   mean of the y data used to center the data
        meany = 0;
        
        % stdx   standard deviation of the x data used to scale the data
        stdx = 1;
        % stdy   standard deviation of the y data used to scale the data
        stdy = 1;
        
        % xlim   limits of x data used in the fit
        xlim = [-pi, pi];
        % ylim   limits of y data used in the fit
        ylim = [-pi, pi];
    end
    
    methods
        function obj = sfit( model, varargin )
            %SFIT   Construct SFIT object.
            %   SFIT(MODEL,COEFF1,COEFF2,COEFF3,...) constructs an SFIT object
            %   from the MODEL and the coefficient values, COEFFi.
            %
            %   Note: SFIT is called by the FIT function when fitting FITTYPE
            %   objects to data. To create an SFIT object that is the result of
            %   a regression, use FIT.
            %            
            %   You should only call SFIT directly if you want to assign values
            %   to coefficients and problem parameters of a FITTYPE object
            %   without performing a fit.
            %
            %   See also: FIT, FITTYPE, CFIT.
            
            %     SFIT(MODEL,..., PROB1, PROB2, ...) assign values to the
            %     problem parameters.
            %
            %     SFIT(MODEL,..., <Parameter>, <Value>, ...) allows other
            %     information to be passed in as parameter-value pairs.
            switch nargin
                case 0
                    % >> obj = SFIT()
                    % Nothing to do
                case 1
                    obj = constructFromOneArgument( obj, model );
                otherwise
                    obj = constructFromManyArguments( obj, model, varargin{:} );
            end
        end % of constructor
    end
    
    methods(Access = private)
        function obj = constructFromOneArgument( obj, model )
            % Allowed syntax
            % obj = SFIT( sfit )
            % obj = SFIT( fittype ), fittype must be empty
            if isa( model, 'sfit' )
                % >> obj = SFIT( sfit )
                obj = model;
                
            elseif isa( model, 'fittype' )
                % >> obj = SFIT( fittype ), fittype must be empty
                if isempty( model )
                    obj = copyFittypeProperties( obj, model );
                else
                    % If the fittype is not empty then the user should have provided more
                    % input arguments                    
                    error(message('curvefit:sfit:notEnoughInputs'));
                end
            else
                % Anything else must be invalid
                error(message('curvefit:sfit:invalidCall'));
            end
        end
        
        function obj = constructFromManyArguments( obj, model, varargin )
            % Syntax is
            % obj = SFIT( fittype, c1, ..., cn, p1, .., pm, p-v pairs )
            % where
            %   fittype has two independent variables
            %   c1, ..., cn are the coefficients
            %   p1, .., pm are the problem parameters (if any)
            %   p-v pairs are optional parameter value pairs
            if ~isa( model, 'fittype'  )
                % First argument must be a FITTYPE or a subclass
                error(message('curvefit:sfit:invalidCall'))
            elseif numindep( model ) ~= 2
                error(message('curvefit:sfit:invalidFittype'));
            end
            
            % Need to "inherit" the properties from the FITTYPE
            obj = copyFittypeProperties( obj, model );
            
            % Assign coefficients & problem parameters from the variable arguments.
            numCoeffs = size( coeffnames( obj ), 1 );
            numProbs = size( probnames( obj ), 1 );
            numParams = numCoeffs+numProbs;

            iAssertSufficientArgumentsForParameters( numParams, length( varargin ) );
            
            obj.fCoeffValues = varargin(1:numCoeffs);
            obj.fProbValues = varargin(numCoeffs+1:numParams);
            
            % Parse the parameter value pairs
            p = inputParser;
            p.CaseSensitive = false;
            p.addParamValue( 'meanx', obj.meanx, @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'stdx',  obj.stdx,  @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'meany', obj.meany, @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'stdy',  obj.stdy,  @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'xlim',  obj.xlim,  @(v) all( size( v ) == [1, 2] ) );
            p.addParamValue( 'ylim',  obj.ylim,  @(v) all( size( v ) == [1, 2] ) );
            p.addParamValue( 'sse',   obj.sse,   @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'dfe',   obj.dfe,   @(v) isscalar( v ) && isnumeric( v ) );
            p.addParamValue( 'activebounds', obj.activebounds, @(v) isempty( v ) || all( size( v ) == [numCoeffs, 1] ) );
            p.addParamValue( 'jacobian', [] );
            
            p.parse( varargin{numParams+1:end} );
            
            obj.meanx = p.Results.meanx;
            obj.stdx  = p.Results.stdx;
            obj.meany = p.Results.meany;
            obj.stdy  = p.Results.stdy;
            obj.xlim  = p.Results.xlim;
            obj.ylim  = p.Results.ylim;
            obj.sse   = p.Results.sse;
            obj.dfe   = p.Results.dfe;
            
            obj.activebounds = p.Results.activebounds;
            obj.rinv = rinvFromJacobian( p.Results.jacobian, obj.activebounds );
        end
    end
    
    methods(Hidden = true)
        function fn = fieldnames( obj )
            % FIELDNAMES should return a list of those properties that can be
            % set. For an SFIT object that means the coefficients and the
            % problem parameters.
            %
            % See also SUBSASGN
            fn = [
                coeffnames( obj )
                probnames(  obj )
                ];
        end
    end
    
    methods(Access = 'private')
        function prettyPrint( obj, name )
            isLoose = strcmp( get(0, 'FormatSpacing' ), 'loose' );
            
            if isempty( name )
                name = 'ans';
            end
            
            [~, line2, line3, line4] = makedisplay( obj, name );
            
            if (isLoose)
                fprintf('\n');
            end
            fprintf('     %s\n', line2);
            fprintf('     %s\n', line3);
            if ~isempty(line4), fprintf('     %s\n', line4); end
            if (isLoose)
                fprintf('\n');
            end
        end
    end
    
    methods(Static, Hidden)
        obj = loadobj(obj)
    end
    
    methods(Hidden = true)
        disp( obj )
        display( obj )
        resultstrings = genresults( fitresult, goodness, output, warnstr, errstr, convmsg, clev )
        obj = subsasgn(obj, subs, value)
        out = subsref( obj, subs)
    end
    
end

function rinv = rinvFromJacobian( jacobian, activebounds )
% RINVFROMJACOBIAN -- compute inv( R ), aka Rinv, from the Jacobian and the list
% of active bounds.

if isempty( jacobian )
    rinv = [];
    return
end

if ~isempty( activebounds )
    jacobian = jacobian(:,~activebounds);
end
[~, R] = qr( jacobian, 0 );

% We've already warned about conditioning during fit,
% so turn off warnings so "\" doesn't warn.
ws = warning( 'off', 'all' );
warningCleanup = onCleanup( @() warning( ws ) );
rinv = R \ eye( length( R ) );
end

function iAssertSufficientArgumentsForParameters( numParams, numArguments )
if numParams > numArguments
    error( message( 'curvefit:sfit:notEnoughInputs' ) );
end
end
