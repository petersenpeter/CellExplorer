function toggleProperty(this, property)
%toggleProperty FitFigure utility
%
%   toggleProperty can toggle both on/off or true/false properties

%   Copyright 2008-2009 The MathWorks, Inc.

value = this.(property);
if islogical(value)
    this.(property) = ~value;
elseif ischar(value)
    if strcmpi(value, 'on')
        this.(property) = 'off';
    else
        this.(property) = 'on';
    end
end
end

