function [order,sourceCount] = cellIdentityOrder(source, target, description, allowSubset)
%CELLIDENTITYORDER Map target cells to explicitly identified source columns.
% Both UID and cluID, when supplied, must imply the same mapping. Counts alone
% never establish correspondence. Subsets must be explicitly enabled by callers.
if nargin < 4, allowSubset = false; end
order = []; sourceCount = [];
for key = {'UID','cluID'}
    name = key{1};
    if ~isfield(source,name), continue; end
    if ~isfield(target,name)
        error('ce:pipeline:CellImportIdentity','%s supplies %s but target cells do not.',description,name);
    end
    ids = source.(name); wanted = target.(name);
    if ~validIds(ids) || ~validIds(wanted) || ...
            ~allowSubset && numel(ids) ~= numel(wanted) || ...
            ~isempty(sourceCount) && sourceCount ~= numel(ids)
        error('ce:pipeline:CellImportIdentity','%s requires unique finite, consistently sized %s values for the selected cells.',description,name);
    end
    [found,mapping] = ismember(wanted(:)',ids(:)');
    if ~all(found) || ~isempty(order) && ~isequal(order,mapping)
        error('ce:pipeline:CellImportIdentity','%s: %s does not match the selected cells or disagrees with the other identity field.',description,name);
    end
    order = mapping; sourceCount = numel(ids);
end
if isempty(order)
    error('ce:pipeline:CellImportIdentity', ...
        '%s has no cell identity. Add UID (or cluID) in source-column order using the producer''s verified cell mapping; do not infer identity from matching counts.',description);
end
end

function valid = validIds(value)
valid = isnumeric(value) && isreal(value) && isvector(value) && ~isempty(value) && ...
    all(isfinite(value(:))) && numel(unique(value)) == numel(value);
end
