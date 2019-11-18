function line = fcnstring(obj, variable, numargs, arglist)
%FCNSTRING Create string representation of fittype function
%   FCNSTRING( OBJ, NAME, NARGS )
%   FCNSTRING( OBJ, NAME, NARGS, ARGLIST )

%   Copyright 1999-2010 The MathWorks, Inc.


if nargin < 3
    numargs = obj.numArgs;
end
if nargin < 4
    arglist = obj.args;
end
arglist = cellstr( arglist );

line = leftHandSideForFcnString( variable, arglist(1:numargs) );
line = sprintf('%s = %s', line, obj.defn );

% Fold line over multiple lines if it is too long and not yet broken
nl = sprintf('\n');
if length(line)>80 && ~ismember(nl(1),line)
    line = strtrim(line);
    breakpt = 72;
    breakchars = '+-,)= ';   % willing to break after these
    blanks = repmat(' ',1,20);
    while(breakpt <= length(line)-5)
        % Break as close as possible to current point, not too close to end
        j = find(ismember(line(breakpt:end-5),breakchars)) - 1;
        if isempty(j)
            break;
        end
        breakpt = breakpt+j(1);
        line = sprintf('%s\n%s%s',line(1:breakpt),blanks,line(breakpt+1:end));
        breakpt = breakpt + 72;
    end
end

end
