function values = previewValues(data)
% previewValues returns values for plotting
%
% previewValues(data) returns a (1,3) cell array. DATA is sftoolgui.Data.
% If there is a mismatch in sizes, the cell array has empty values. If all
% specified elements are equal, the cell array contains the actual values
% for those items that are specified and N 0s for those items not
% specified, where N is the number of elements

%   Copyright 2011 The MathWorks, Inc.

values = cell(1,3);
if areNumSpecifiedElementsEqual(data)
    if isCurveDataSpecified(data)
        [x, y] = getCurveValues(data);
        z = [];
    else
        [x, y, z] = getValues(data);
    end
    values = {x, y, z};
    
    % Get indices of empty values
    isEmpty = cellfun('isempty', values);
    
    % If there is at least one non-empty value ...
    if ~all(isEmpty)
        
        % then find the number of elements in a non-empty value ...
        numberOfElements = iNumberOfElements(values, isEmpty);
        
        % and replace the empty values with arrays of zeros.
        values(isEmpty) = {zeros(numberOfElements,1)};
    end
end
end

function numberOfElements = iNumberOfElements(values, isEmpty)
% iNumberOfElements returns the number of elements in non-empty data.

% Find the index of the first non-empty value
nonEmptyIndex = find(~isEmpty, 1);

% Get the number of elements of that value
numberOfElements = numel(values{nonEmptyIndex});
end

