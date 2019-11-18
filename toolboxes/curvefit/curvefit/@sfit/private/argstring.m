function line = argstring(names,values,ci,activebounds)
%  Args are coefficient names, coefficient values, and optional
%  coefficient confidence intervals.

%   Copyright 1999-2011 The MathWorks, Inc.

numnames = size(names,1);

if nargin<4 || length(activebounds)~=numnames
   activebounds = zeros(numnames,1);
end

line = '';
for k = 1:numnames
    value = values{k};
    name = deblank(names(k,:));
    if isa(value,'double') && length(value)==1
        nameValue = sprintf( '%s = %11.4g', name, value );
        if nargin<3
            line = sprintf('%s       %s\n', line, nameValue );
        elseif activebounds(k)
            line = sprintf('%s       %s  (%s)\n',line, nameValue, iFixedAtBound );
        elseif isnan(ci(2,k))
            line = sprintf('%s       %s\n', line, nameValue );
        else
            line = sprintf('%s       %s  (%.4g, %.4g)\n', line, nameValue, ci(1,k), ci(2,k) );
        end
    elseif ischar(value)
        line = sprintf('%s       %s = %s\n', line, name,value);
    else
        [m,n]=size(value);
        value = sprintf('%sx%s %s', num2str(m), num2str(n) ,class(value));
        line = sprintf('%s       %s = %s\n', line, name,value);
    end
    
end

% Remove trailing newline
lf = sprintf('\n');
idx = (length(line)-length(lf)+1):length(line);
if length(line)>length(lf) && isequal(lf,line(idx))
   line(idx) = [];
end
end

function fixedAtBound = iFixedAtBound()
fixedAtBound = getString(message('curvefit:curvefit:FixedAtBound'));
end
