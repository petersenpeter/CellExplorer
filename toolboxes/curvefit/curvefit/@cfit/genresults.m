function resultstrings = genresults(fitresult,goodness,output,warnstr,errstr,convmsg,confidenceLevel)
%GENRESULTS Generate cell array of strings for results window.
%
%   resultsStrings = GENRESULTS(FITRESULT,GOODNESS,OUTPUT) takes output
%   from FIT command and pretties it up and puts it in a cell array of
%   strings.

%   Copyright 2000-2011 The MathWorks, Inc.

if nargin<7
    confidenceLevel = 0.95; 
end

resultstrings = {};
if ~isempty(errstr)
    fittingComputationCancelled = getString(message('curvefit:curvefit:FittingComputationCancelled'));
    if ~isempty(strfind(fittingComputationCancelled,errstr))
        resultstrings{end+1} = fittingComputationCancelled;
    else
        resultstrings{end+1} = getString(message('curvefit:curvefit:FitCouldNotBeComputedDueToError'));
        resultstrings{end+1} = '';
        resultstrings{end+1} = errstr;
    end
else
    if output.exitflag <= 0 
        resultstrings{end+1} = getString(message('curvefit:curvefit:FitComputationDidNotConverge'));
        resultstrings{end+1} = convmsg;
        resultstrings{end+1} = '';
        resultstrings{end+1} = getString(message('curvefit:curvefit:FitFoundWhenOptimizationTerminated'));
        resultstrings{end+1} = '';
    end

    if ~isempty(warnstr)
        resultstrings{end+1} = getString(message('curvefit:curvefit:WarningsDuringFitting'));
        resultstrings{end+1} = warnstr;
        resultstrings{end+1} = ' ';
    end
    
    [~,line2,line3,line4] = makedisplay(fitresult,'f',output,confidenceLevel);
    resultstrings(end+1:end+3) = {line2,line3,line4};
    
    resultstrings{end+1} = getString(message('curvefit:curvefit:GoodnessOfFit'));
    
    indent = '  ';
    resultstrings{end+1} = [indent, getString(message('curvefit:curvefit:DisplaySSE',             iStringStatistic( goodness.sse        )))];
    resultstrings{end+1} = [indent, getString(message('curvefit:curvefit:DisplayRSquare',         iStringStatistic( goodness.rsquare    )))];
    resultstrings{end+1} = [indent, getString(message('curvefit:curvefit:DisplayAdjustedRsquare', iStringStatistic( goodness.adjrsquare )))];
    resultstrings{end+1} = [indent, getString(message('curvefit:curvefit:DisplayRMSE',            iStringStatistic( goodness.rmse       )))];

    if goodness.rsquare<0
        resultstrings{end+1} = '';
        resultstrings{end+1} = getString(message('curvefit:curvefit:NegativeRSquareWarning'));
    end
end

end

function string = iStringStatistic( statistic )
% iStringStatistic   Convert a statistic from a number to a string.
string = sprintf( '%0.4g', statistic );
end
