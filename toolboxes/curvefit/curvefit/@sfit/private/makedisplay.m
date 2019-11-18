function [line1,line2,line3,line4] = makedisplay(obj,objectname,out,clev)
% MAKEDISPLAY

%   Copyright 2008-2011 The MathWorks, Inc.

if nargin<4, clev = 0.95; end

line1 = sprintf('%s =', objectname);
line4 = ''; %default

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
            line2b = fcnstring( obj, objectname, 2, indepnames( obj ) );
            line2c = iMakeScalingLine( obj );
            try
                ci = confint(obj,clev);
                line3a = iCoefficientsWithBounds(clev);
                line3b = argstring(char(coeffnames(obj)),obj.fCoeffValues,...
                    ci,obj.activebounds);
            catch ignore %#ok<NASGU>
                line3a = sprintf('%s\n', getString(message('curvefit:curvefit:CoefficientsColon')));
                line3b = argstring(char(coeffnames(obj)),obj.fCoeffValues);
            end
            probnamesarray = char(probnames(obj));
            if ~isempty(probnamesarray)
                line4a = sprintf('%s\n', getString(message('curvefit:curvefit:ProblemParametersColon')));
                line4b = argstring(probnamesarray,obj.fProbValues);
                line4 = sprintf('%s%s',line4a,line4b);
            end
        case {'spline','interpolant', 'lowess'}
            line2a = sprintf('%s:\n     ',prettyname(obj));
            line2b = sprintf( '  %s', nonParametricFcnString( obj, objectname, indepnames( obj ), char(coeffnames(obj)) ) );
            line2c = iMakeScalingLine( obj );
            if nargin>=3 && isfield(out,'p')
                line3a = sprintf('%s\n', getString(message('curvefit:curvefit:SmoothingParameterColon')));
                line3b = sprintf('       p = %0.8g',out.p);
            else
                line3a = sprintf('%s\n', getString(message('curvefit:curvefit:CoefficientsColon')));
                line3b = argstring(char(coeffnames(obj)),{getString(message('curvefit:curvefit:CoefficientStructure'))});
            end
        case 'library'
            if islinear(obj)
                line2a = sprintf('%s %s:\n     ', getString(message('curvefit:curvefit:LinearModel')), prettyname(obj));
            else
                line2a = sprintf('%s %s:\n     ', getString(message('curvefit:curvefit:GeneralModel')), prettyname(obj));
            end
            line2b = fcnstring(obj, objectname, 2, indepnames( obj ) );
            line2c = iMakeScalingLine( obj );
            try
                ci = confint(obj,clev);
                line3a = iCoefficientsWithBounds(clev);
                line3b = argstring(char(coeffnames(obj)),obj.fCoeffValues,...
                    ci,obj.activebounds);
            catch ignore %#ok<NASGU>
                line3a = sprintf('%s\n', getString(message('curvefit:curvefit:CoefficientsColon')));
                line3b = argstring(char(coeffnames(obj)),obj.fCoeffValues);
            end
            probnamesarray = char(probnames(obj));
            if ~isempty(probnamesarray)
                line4a = sprintf('%s\n', getString(message('curvefit:curvefit:ProblemParametersColon')));
                line4b = argstring(probnamesarray,obj.fProbValues);
                line4 = sprintf('%s%s',line4a,line4b);
            end
            
        otherwise
            error(message('curvefit:sfit:makedisplay:unknownFittype'))
    end
    line2 = sprintf('%s%s%s',line2a,line2b,line2c);
    line3 = sprintf('%s%s',line3a,line3b);
end

end

function line = iMakeScalingLine( obj )
indep = indepnames(obj);

xIsScaled = ~isequal( obj.meanx, 0 ) || ~isequal( obj.stdx, 1 );
yIsScaled = ~isequal( obj.meany, 0 ) || ~isequal( obj.stdy, 1 );

if xIsScaled && yIsScaled
    xSentence = getString(message('curvefit:curvefit:WhereXIsNormalizedByMeanAndStd', ...
        indep{1}, num2str( obj.meanx, '%0.4g' ), num2str( obj.stdx, '%0.4g' ) ));
    ySentence = getString(message('curvefit:curvefit:AndWhereYIsNormalizedByMeanAndStd', ...
        indep{2}, num2str( obj.meany, '%0.4g' ), num2str( obj.stdy, '%0.4g' ) )); 
    line = sprintf( '\n       %s\n       %s', xSentence, ySentence );

elseif xIsScaled
    xSentence = getString(message('curvefit:curvefit:WhereXIsNormalizedByMeanAndStd', ...
        indep{1}, num2str( obj.meanx, '%0.4g' ), num2str( obj.stdx, '%0.4g' ) ));
    line = sprintf('\n       %s', xSentence );
    
elseif yIsScaled
    ySentence = getString(message('curvefit:curvefit:WhereXIsNormalizedByMeanAndStd', ...
        indep{2}, num2str( obj.meany, '%0.4g' ), num2str( obj.stdy, '%0.4g' ) ));
    line = sprintf('\n       %s', ySentence );

else 
    line = '';
end

end

function line = iCoefficientsWithBounds(clev)
sentence = getString( message( 'curvefit:curvefit:CoefficientsWithConfidenceBounds', ...
    num2str( 100*clev, '%g' ) ) );
line = sprintf( '%s\n', sentence );
end