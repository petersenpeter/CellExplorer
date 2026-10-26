function data = metricTableData(metrics, fields, cellIndex, blankNaNs)
%METRICTABLEDATA Format the selected cell without materializing a batch table.
% fields is the viewer's ordered list of scalar-per-cell numeric/text fields.
% Preserve the legacy numeric string conversion, including older MATLAB NaNs.
if nargin < 4, blankNaNs = verLessThan('matlab','9.3'); end
fields = fields(:);
data = cell(numel(fields),2);
data(:,1) = fields;
for index = 1:numel(fields)
    values = metrics.(fields{index});
    value = values(cellIndex);
    if isnumeric(value)
        formatted = string(value);
        if blankNaNs && isnan(value), formatted = ""; end
        data(index,2) = cellstr(formatted);
    else
        data(index,2) = cellstr(value);
    end
end
end
