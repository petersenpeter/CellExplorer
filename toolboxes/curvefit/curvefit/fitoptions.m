function f = fitoptions(varargin)
%FITOPTIONS  Create/modify a fit options object.
%   F = FITOPTIONS(LIBNAME) creates the fitoptions object F with the option
%   parameters set to the default values for the library model LIBNAME. See "List
%   of Library Models for Curve and Surface Fitting" in documentation for more 
%   information on LIBNAME.
%
%   F = FITOPTIONS(LIBNAME,'PARAM1',VALUE1,'PARAM2',VALUE2,...) creates a 
%   default fitoptions object for the library model LIBNAME with the named 
%   parameters altered with the specified values.
%
%   F = FITOPTIONS('METHOD',VALUE) creates a default fitoptions object 
%   with the method specified by VALUE. Choices for VALUE are:
%
%      NearestInterpolant     - Nearest neighbor interpolation
%      LinearInterpolant      - Linear interpolation
%      PchipInterpolant       - Piecewise Cubic Hermite interpolation.
%      CubicSplineInterpolant - Cubic Spline interpolation
%      BiharmonicInterpolant  - Biharmonic Surface Interpolation
%      SmoothingSpline        - Smoothing Spline 
%      LowessFit              - Lowess Fit
%      LinearLeastSquares     - Linear Least Squares
%      NonlinearLeastSquares  - Nonlinear Least Squares
%
%   It is sufficient to type only the leading characters that uniquely
%   identify the VALUE.  Case is ignored for VALUE names.
%
%   F = FITOPTIONS('METHOD',VALUE1,'PARAM2',VALUE2,...) creates a default
%   fitoptions object for the method specified by VALUE1 with the named 
%   parameters altered with the specified values.
%
%   F = FITOPTIONS(OLDF,NEWF) combines an existing fitoptions object OLDF
%   with a new fitoptions object NEWF. If OLDF and NEWF have the same
%   'Method', any parameters in NEWF with non-empty values override the
%   corresponding old parameters in OLDF. If OLDF and NEWF have different
%   'Method' values, F will have the same Method as OLDF, and only the fields
%   'Normalize', 'Exclude', and 'Weights' of NEWF will override the OLDF
%   fields.
%
%   F = FITOPTIONS(OLDF,'PARAM1',VALUE1,'PARAM2',VALUE2,...) creates a new
%   fitoptions object from fitoptions object OLDF with the named parameters
%   altered with the specified values.
%
%   F = FITOPTIONS creates a fitoptions object F where all the fields are set
%   to default values and the Method parameter has value 'None'.
%
%   All FITOPTIONS objects have the following parameters:
%
%      Normalize - Specifies whether to center and scale the data
%                   [{'off'} | 'on']
%      Exclude   - Exclusion vector with the same length as the data
%                  [{[]} | logical vector with excluded entries set to 1]
%      Weights   - Weight vector with the same length as the data
%                  [{[]} | vector with positive entries] 
%      Method    - method used by FIT
%
%   Depending on the method value, a fitoptions object may have other
%   parameters.
%
%   If Method is NearestInterpolant, LinearInterpolant, PchipInterpolant or
%   CubicSplineInterpolant, BiharmonicInterpolant, then there are no additional
%   parameters. 
%
%   If Method is SmoothingSpline, then the additional parameters are:
%      SmoothingParam - smoothing parameter [{NaN} | scalar in [0,1]]
%                       NaN means it will be computed during FIT
%
%   If Method is LowessFit, then the additional parameters are:
%      Span      - proportion of data points to be used in local regressions
%                  [scalar in [0,1] | {0.25}]
%
%   If Method is LinearLeastSquares, then the additional parameters are:
%
%      Robust    - Specifies the robust linear least squares fitting method
%                  [{'off'} | 'on' | 'LAR' | 'Bisquare']
%      Lower     - A vector of lower bounds on the coefficients to be fitted
%                  [{[]} | vector of length the number of coefficients]
%      Upper     - A vector of upper bounds on the coefficients to be fitted
%                  [{[]} | vector of length the number of coefficients]
%
%  If Method is NonlinearLeastSquares, then the additional parameters are:
%
%     Robust        - Specifies the robust nonlinear least squares fitting
%                     method [{'off'} | 'on' | 'LAR' | 'Bisquare'] 
%     Lower         - Vector of lower bounds on the coefficients to be fitted
%                     [{[]} | vector of length the number of coefficients] 
%     Upper         - Vector of upper bounds on the coefficients to be fitted
%                     [{[]} | vector of length the number of coefficients] 
%     StartPoint    - Vector to be used as the starting point in FIT
%                     [{[]} | vector of length the number of coefficients]
%     Algorithm     - Algorithm to be used in FIT
%                     [{'Levenberg-Marquardt'} | 'Trust-Region']
%                     'Gauss-Newton' has been removed. Use 'Levenberg-Marquardt' instead.
%     DiffMaxChange - Maximum change in coefficients for finite difference  
%                     gradients [positive scalar | {1e-1}]
%     DiffMinChange - Minimum change in coefficients for finite difference
%                     gradients [positive scalar | {1e-8}]
%     Display       - Level of display ['off' | 'iter' | {'notify'} | 'final']
%     MaxFunEvals   - Maximum number of function (model) evaluations allowed
%                     [positive integer]
%     MaxIter       - Maximum number of iterations allowed [positive integer]
%     TolFun        - Termination tolerance on the function (model) value
%                     [positive scalar | {1e-6}]
%     TolX          - Termination tolerance on coefficients
%                     [positive scalar | {1e-6}]
%
%  It is sufficient to type only the leading characters that uniquely
%  identify the parameter.  Case is ignored for parameter names.
%
%  See also FITTYPE.

%   Copyright 2001-2013 The MathWorks, Inc.

% F = FITOPTIONS
if nargin == 0 % create the default fitoptions object.
    f = curvefit.basefitoptions;
    return
end

% F = FITOPTIONS(OLDF,NEWF)
if nargin == 2 && isa(varargin{1},'curvefit.basefitoptions') && ...
        isa(varargin{2},'curvefit.basefitoptions') 
    f = merge(varargin{1},varargin{2});
    return;
end

% F = FITOPTIONS(OLDF,'PARAM1',VALUE1,'PARAM2',VALUE2,...)
nonmethod = 0;
if isa(varargin{1},'curvefit.basefitoptions') 
    f = copy(varargin{1});
    varargin(1) = [];
    nonmethod = 1; % 'Method' does not need to be present
else % check to see if it is LIBNAME syntax
    fittypes = cellstr( getfittypes() ); 
    ind = strcmpi( varargin{1}, fittypes );
    if ~any( ind )
        ind = strncmpi( varargin{1}, fittypes, length( varargin{1} ) );
    end
    if nnz( ind ) > 1
        error(message('curvefit:fitoptions:libnameNotUnique', varargin{ 1 }));
    end
    if (any(ind) && ~ind(1)) || ~isidentifier(varargin{1}) % libname syntax
        obj = fittype(varargin{1});
        f = fitoptions(obj);  % using the fitoptions method for the fittype.
        varargin(1) = [];
        nonmethod = 1; % 'Method' does not need to be present
    end
end

% only param-value pairs left in varargin.

if ~isempty(varargin) % param value pairs
    if mod(length(varargin),2) ~= 0
        error(message('curvefit:fitoptions:invalidArgs'));
    end
    for i=1:2:length(varargin)
        if ~ischar(varargin{i})
            error(message('curvefit:fitoptions:paramNameMustBeString'));
        end
    end
    
    if nonmethod == 1
        set(f,varargin{:}); % should not allow method to be set.
        return
    end
    
    % method syntax starts from here
    methodindex = strncmpi( 'me', varargin(1:2:end), 2 );
    if any( methodindex )
        if nnz( methodindex ) > 1
            warning(message('curvefit:fitoptions:ignoringParamValues'));
        end
        methodvalue = varargin{2*find( methodindex, 1, 'first' )}; % in case more than one method param
        token = findmethod(methodvalue);
        % Remove all method param-value pairs from varargin
        methodindex = find( methodindex );
        varargin(vertcat(2*methodindex-1,2*methodindex)) = [];
    else
        token = '';
    end
    
    f = optionsFromToken( token );
    
    if ~isempty(varargin)
        set(f,varargin{:});
    end
end

%-------------------------------------------
function tf = isidentifier(str)

tf = false;
if ~ischar(str)
    return;
end

if ~isempty(str)
    first = str(1);
    if (isletter(first))
        letters = isletter(str);
        numerals = (48 <= str) & (str <= 57);
        underscore = (95 == str);
        if (all(letters | numerals | underscore))
            tf = true;
        end
    end
end

%-------------------------------------------
function method = findmethod(str)
% find the method name for str

if ~ischar( str )
    error( message( 'curvefit:fitoptions:methodNameMustBeString' ) );
end

methods = {'none', 'smoothingspline',...
        'nearestinterpolant','linearinterpolant', ...
        'pchipinterpolant','cubicsplineinterpolant', ...
        'linearleastsquares','nonlinearleastsquares', ...
        'biharmonicinterpolant', 'thinplateinterpolant', ...
        'lowessfit'};
idx = strncmpi( str, methods, length( str ) );
if nnz(idx) > 1
    error(message('curvefit:fitoptions:methodNameAmbiguous', str))
elseif ~any(idx)
    error(message('curvefit:fitoptions:invalidMethodName', str));
end

ReturnToken = ['no';'sm';'ne';'li';'pc';'cu';'ll';'nl';'bh';'th';'lo'];
method = ReturnToken(idx,:);

%-------------------------------------------
function f = optionsFromToken(token)
switch token
case 'cu'
    f = curvefit.interpoptions('CubicSplineInterpolant');
case 'li'
    f = curvefit.interpoptions('LinearInterpolant');
case 'll'
    f = curvefit.llsqoptions;
case 'ne'
    f = curvefit.interpoptions('NearestInterpolant');
case 'nl'
    f = curvefit.nlsqoptions;
case 'no' % method none, means use basefitoptions.
    f = curvefit.basefitoptions;
case 'pc'
    f = curvefit.interpoptions('PchipInterpolant');
case 'sm'
    f = curvefit.smoothoptions;
case 'bh'
    f = curvefit.interpoptions('BiharmonicInterpolant');
case 'th'
    f = curvefit.interpoptions('ThinPlateInterpolant');
case 'lo'
    f = curvefit.lowessoptions;
otherwise
    f = curvefit.basefitoptions;
end
