function orderedIndices = annotationOrder(target, source, indices)
%ANNOTATIONORDER Validate session identity/revision and return source cell order.
if ~isfield(target, 'UID') || ~isfield(source, 'UID')
    error('ce:curation:MissingIdentity', 'Both structures must contain UID.');
end
validateattributes(indices, {'numeric'}, {'vector','integer','positive','finite','<=',numel(source.UID)});
indices = reshape(indices, 1, []);
sourceIDs = source.UID(indices);
targetIDs = target.UID;
if numel(indices) ~= numel(targetIDs) || numel(unique(indices)) ~= numel(indices)
    error('ce:curation:CellCountMismatch', 'The selection must contain every target cell exactly once.');
end
if ~isnumeric(sourceIDs) || ~isnumeric(targetIDs) || ...
        any(~isfinite(sourceIDs(:))) || any(~isfinite(targetIDs(:))) || ...
        numel(unique(sourceIDs)) ~= numel(sourceIDs) || numel(unique(targetIDs)) ~= numel(targetIDs)
    error('ce:curation:InvalidIdentity', 'UIDs must be finite and unique within a session.');
end
[found, order] = ismember(targetIDs, sourceIDs);
if ~all(found(:))
    error('ce:curation:IdentityMismatch', 'The saved session and the edited cells have different UIDs.');
end
orderedIndices = indices(order);
targetRevision = ce.data.metricSortingRevision(target);
sourceRevision = ce.data.metricSortingRevision(source,indices);
if ~strcmp(targetRevision,sourceRevision)
    error('ce:curation:SortingRevisionMismatch','Sorting changed or its revision is missing; reload and reconcile annotations before saving.');
end
if isfield(target, 'cluID') && isfield(source, 'cluID')
    if numel(target.cluID) ~= numel(targetIDs) || numel(source.cluID) ~= numel(source.UID) || ...
            ~isequaln(reshape(target.cluID, 1, []), reshape(source.cluID(orderedIndices), 1, []))
        error('ce:curation:IdentityMismatch', 'Cluster identities changed; reload the session before saving.');
    end
end
end
