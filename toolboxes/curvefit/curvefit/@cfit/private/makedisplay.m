function [line1,line2,line3,line4] = makedisplay(obj,objectname,out,clev)
% MAKEDISPLAY

%   Copyright 1999-2011 The MathWorks, Inc.

% If no object name is given then use the dependname.
if isempty( objectname )
    objectname = dependnames( obj );
    objectname = objectname {1};
end

if nargin<4, clev = 0.95; end

line1 = sprintf('%s =', objectname);
line4 = ''; %default
line2c = '';

if (isempty(obj))
    line2 = getString(message('curvefit:curvefit:ModelEmpty'));
    line3 = getString(message('curvefit:curvefit:CoefficientsEmpty'));
else
    switch category(obj)
        case 'custom'
            if islinear(obj)
                line2a = sprintf('%s:\n     ', getString(message('curvefit:curvefit:LinearModel')));
            else
                line2a = sprintf('%s:\n     ', getString(message('curvefit:curvefit:GeneralModel')));
            end
            line2b = fcnstring( obj, objectname, 1, indepnames( obj ) );
            line2c = iNormalizedLine( obj );
            try
                ci = confint(obj,clev);
                line3a = iCoefficientsWithBounds(clev);
                line3b = argstring(char(coeffnames(obj)),obj.coeffValues,...
                    ci,obj.activebounds);
            catch ignore %#ok<NASGU>
                line3a = sprintf( '%s\n', getString(message('curvefit:curvefit:CoefficientsColon')) );
                line3b = argstring(char(coeffnames(obj)),obj.coeffValues);
            end
            probnamesarray = char(probnames(obj));
            if ~isempty(probnamesarray)
                line4a = sprintf('%s\n', getString(message('curvefit:curvefit:ProblemParametersColon')) );
                line4b = argstring(probnamesarray,obj.probValues);
                line4 = sprintf('%s%s',line4a,line4b);
            end
        case {'spline','interpolant'}
            line2a = sprintf('%s:\n     ',prettyname(obj));
            line2b = sprintf( '  %s', nonParametricFcnString( obj, objectname, indepnames( obj ), char(coeffnames(obj)) ) );
            line2c = iNormalizedLine( obj );
            if nargin>=3 && isfield(out,'p')
                line3a = sprintf( '%s\n', getString(message('curvefit:curvefit:SmoothingParameterColon')) );
                line3b = sprintf('       p = %0.8g',out.p);
            else
                line3a = sprintf( '%s\n', getString(message('curvefit:curvefit:CoefficientsColon')) );
                line3b = argstring(char(coeffnames(obj)),{getString(message('curvefit:curvefit:CoefficientStructure'))});
            end
        case 'library'
            if islinear(obj)
                line2a = sprintf('%s %s:\n     ', getString(message('curvefit:curvefit:LinearModel')), prettyname(obj));
            else
                line2a = sprintf('%s %s:\n     ', getString(message('curvefit:curvefit:GeneralModel')), prettyname(obj));
            end
            line2b = fcnstring( obj, objectname, 1, indepnames( obj ) );
            line2c = iNormalizedLine( obj );
            try
                ci = confint(obj,clev);
                line3a = iCoefficientsWithBounds(clev);
                line3b = argstring(char(coeffnames(obj)),obj.coeffValues,...
                    ci,obj.activebounds);
            catch ignore %#ok<NASGU>
                line3a = sprintf( '%s\n', getString(message('curvefit:curvefit:CoefficientsColon')) );
                line3b = argstring(char(coeffnames(obj)),obj.coeffValues);
            end
            probnamesarray = char(probnames(obj));
            if ~isempty(probnamesarray)
                line4a = sprintf('%s\n', getString(message('curvefit:curvefit:ProblemParametersColon')) );
                line4b = argstring(probnamesarray,obj.probValues);
                line4 = sprintf('%s%s',line4a,line4b);
            end
            
        otherwise
            error(message('curvefit:cfit:makedisplay:unknownFittype'))
    end
    line2 = sprintf('%s%s%s',line2a,line2b,line2c);
    line3 = sprintf('%s%s',line3a,line3b);
end

end

function line = iNormalizedLine(obj)
if isequal( obj.meanx, 0 ) && isequal( obj.stdx, 1 )
    line = '';
else
    indep = indepnames(obj);
    sentence = getString(message('curvefit:curvefit:WhereXIsNormalizedByMeanAndStd', ...
        indep{1}, num2str( obj.meanx, '%0.4g' ), num2str( obj.stdx, '%0.4g' ) ) );
    line = sprintf('\n       %s', sentence );
end
end

function line = iCoefficientsWithBounds(clev)
sentence = getString( message( 'curvefit:curvefit:CoefficientsWithConfidenceBounds', ...
    num2str( 100*clev, '%g' ) ) );
line = sprintf( '%s\n', sentence );
end
