classdef (Sealed = true) cfit < fittype
    % CFIT   Curve Fit Object
    %
    %   A CFIT object encapsulates the result of fitting a curve to data.
    %   Use the FIT function or CFTOOL to create CFIT objects.
    %
    %   You can treat a CFIT object as a function to make predictions or
    %   evaluation the curve at values of X. For example to predict what
    %   the population was in 1905, then use
    %
    %       load census
    %       cf = fit( cdate, pop, 'poly2' );
    %       yhat = cf( 1905 )
    %
    %   cfit methods:
    %       coeffvalues   - Get values of coefficients.
    %       confint       - Compute prediction intervals for coefficients.
    %       differentiate - Compute values of derivatives.
    %       feval         - Evaluate at new observations.
    %       integrate     - Compute values of integral.
    %       plot          - Plot a curve fit.
    %       predint       - Compute prediction intervals for a curve fit or for 
    %                       new observations.
    %       probvalues    - Get values of problem parameters.
    %
    %   See also: FIT, FITTYPE, SFIT.
    
    %   Copyright 1999-2014 The MathWorks, Inc.
    
    properties(Access = private)
        % coeffValues   cell array of coefficient values
        coeffValues = {};
        
        % probValues   cell array of problem dependent parameter values
        probValues = {};
        
        % sse   sum squared of error
        sse = [];
        
        % dfe   degrees of freedom of error
        dfe = [];
        
        % rinv   inverse of R factor of QR decomposition of Jacobian
        rinv = [];
        % meanx   mean of the xdata used to center the data
        meanx = 0;
        
        % stdx   standard deviation of the xdata used to scale the data
        stdx = 1;
        
        % activebounds   Boolean array indicating which coefficients are at an
        % upper or lower bound
        activebounds = [];
        
        % xlim   limits of x data used in the fit
        xlim = [];
        
        % version number of class definition
        version = 2.0;
    end
    
    methods
        function obj = cfit(model,varargin)
            %CFIT Construct CFIT object.
            %   CFIT(MODEL,COEFF1,COEFF2,COEFF3,...) constructs a CFIT object from the MODEL
            %   and the COEFF values.
            %
            %   Note: CFIT is called by the FIT function when fitting FITTYPE objects to
            %     data. To create a CFIT object that is the result of a regression, use FIT.
            %
            %     You should only call CFIT directly if you want to assign values to
            %     coefficients and problem parameters of a FITTYPE object without performing
            %     a fit.
            %
            %   Example:
            %     load census
            %     ftobj = fittype('a+(x/b)^c');
            %     cfobj = fit(cdate,pop,ftobj,'start',[0,mean(cdate),1])
            %     plot(cdate,pop,'x',cdate,cfobj(cdate),'r-')
            %
            %   See also FIT.
            
            %   Possible parameters:
            %   'sse'         sum squared of error
            %   'dfe'         degrees of freedom of error
            %   'Jacobian'    Jacobian matrix of MODEL
            %   'R'           R factor matrix of QR decomposition of Jacobian
            %   'meanx'       mean of xdata used to normalize data before fitting
            %   'stdx'        std of xdata used to normalize data before fitting
            %   'activebounds' boolean vector indicating which coeffs are at
            %                  their bounds (may be empty if none are active)
            %   'xlim'        min and max of x range of data used in fit
            %
            %   Note: 'Jacobian' and 'R' are redundant parameters in that only one
            %         is needed.
            %
            %   Examples:
            %     m = fittype('a*x+b');
            %     f = cfit(m,1,2);
            %     m = fittype('a*x^2+b*exp(n*x)','prob','n');
            %     f = cfit(m,pi,10.3,3);
            %
            
            % Allowed syntax
            % obj = CFIT()
            % obj = CFIT( cfit )
            % obj = CFIT( fittype ), fittype must be empty
            % obj = CFIT( fittype, <args> ) fittype must have numindep==1
            switch nargin
                case 0
                    % >> obj = CFIT()
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
            % obj = CFIT( cfit )
            % obj = CFIT( fittype ), fittype must be empty
            if isa( model, 'cfit' )
                % >> obj = CFIT( cfit )
                obj = model;
                
            elseif isa( model, 'fittype' )
                % >> obj = CFIT( fittype ), fittype must be empty
                if isempty( model )
                    obj = copyFittypeProperties( obj, model );
                else
                    % If the fittype is not empty then the user should have provided more
                    % input arguments
                    error(message('curvefit:cfit:moreParamsNeeded'));
                end
            else
                % Anything else must be invalid
                error(message('curvefit:cfit:invalidCall'));
            end
        end
        
        function obj = constructFromManyArguments( obj, model, varargin )
            % Syntax is
            % obj = CFIT( fittype, c1, ..., cn, p1, .., pm, p-v pairs )
            % where
            %   fittype has one independent variable
            %   c1, ..., cn are the coefficients
            %   p1, .., pm are the problem parameters (if any)
            %   p-v pairs are optional parameter value pairs
            if ~isa( model, 'fittype'  )
                % First argument must be a FITTYPE or a subclass
                error(message('curvefit:cfit:invalidCall'))
            elseif numindep( model ) ~= 1
                error(message('curvefit:cfit:invalidFittype'));
            end
            
            % Need to "inherit" the properties from the FITTYPE
            obj = copyFittypeProperties( obj, model );
            
            % Parse other arguments for coefficients, etc.
            numCoeffs = size(coeffnames(obj),1);
            numProbs = size(probnames(obj),1);
            if (length( varargin ) < numCoeffs+numProbs)
                error(message('curvefit:cfit:moreParamsNeeded'));
            end
            
            obj.coeffValues = varargin(1:numCoeffs);
            obj.probValues = varargin(numCoeffs+(1:numProbs));
            varargin(1:(numCoeffs+numProbs)) = [];
            
            % There may be additional option name/values pairs
            R = [];
            Jacobian = [];
            activeBounds = [];
            while length(varargin)>1
                switch varargin{1}
                    case 'sse',
                        obj.sse = varargin{2};
                    case 'dfe',
                        obj.dfe = varargin{2};
                    case 'R',
                        R = varargin{2};
                    case 'Jacobian',
                        Jacobian = varargin{2};
                    case 'activebounds',
                        activeBounds = iActiveBoundsFromInputArg(varargin{2});
                    case 'meanx'
                        obj.meanx = varargin{2};
                    case 'stdx'
                        obj.stdx = varargin{2};
                    case 'xlim'
                        obj.xlim = varargin{2};
                    otherwise
                        error(message('curvefit:cfit:invalidArg', varargin{ 1 }));
                end
                varargin(1:2) = [];
            end
            
            % Get inv(R) one way or another
            if isempty(R) && ~isempty(Jacobian)
                if sum(activeBounds)>0
                    Jacobian = Jacobian(:,~activeBounds);
                end
                [~,R] = qr(Jacobian,0);
            end
            if size(R,1)==size(R,2)
                % We've already warned about conditioning during fit,
                % so turn off warnings so "\" doesn't warn.
                ws = warning('off', 'all');
                obj.rinv = R \ eye(length(R));
                warning(ws);
            end
            if isempty(activeBounds)
                activeBounds = zeros(numCoeffs,1);
            end
            obj.activebounds = activeBounds;
            
            if ~isempty(varargin)
                error(message('curvefit:cfit:invalidLastArg'));
            end
        end
    end
    
    methods(Hidden = true)
        function fn = fieldnames( obj )
            % FIELDNAMES should return a list of those properties that can be
            % set. For a CFIT object that means the coefficients and the problem
            % parameters.
            %
            % See also SUBSASGN
            fn = [
                coeffnames( obj )
                probnames(  obj )
                ];
        end
    end
    
    methods(Static = true, Hidden = true)
        obj = loadobj(obj)
    end
    
    methods(Hidden = true)
        disp(obj)
        resultstrings = genresults(fitresult,goodness,output,warnstr,errstr,convmsg,clev)
        c = subsasgn(FITTYPE_OBJ_, varargin)
        FITTYPE_OUT_ = subsref(FITTYPE_OBJ_, FITTYPE_SUBS_)
    end
end

function activeBounds = iActiveBoundsFromInputArg( lambda )
% iActiveBoundsFromInputArg 
%
% Lambda should either be a structure with Lagrangian multipliers or a
% logical vector with true elements for active bounds.
if isstruct(lambda)
    activeBounds = (lambda.lower | lambda.upper);
elseif islogical( lambda );
    activeBounds = lambda;
else
    activeBounds = [];
end
end
