function updated = applyAnnotations(target, source, indices)
%APPLYANNOTATIONS Apply annotations to a complete session by cell identity.
% UID is session-local. Also check cluID when both structures provide it.
% These checks cannot detect re-sorting that reuses both sets of identifiers;
% a future sorting revision contract is required for that case.
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
if isfield(target, 'cluID') && isfield(source, 'cluID')
    if numel(target.cluID) ~= numel(targetIDs) || numel(source.cluID) ~= numel(source.UID) || ...
            ~isequaln(reshape(target.cluID, 1, []), reshape(source.cluID(orderedIndices), 1, []))
        error('ce:curation:IdentityMismatch', 'Cluster identities changed; reload the session before saving.');
    end
end
updated = target;
fields = {'labels','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType'};
for index = 1:numel(fields)
    name = fields{index};
    if isfield(source, name)
        value = source.(name);
        if ~isvector(value) || numel(value) ~= numel(source.UID)
            error('ce:curation:InvalidAnnotations', 'Expected one value per source cell in %s.', name);
        end
        updated.(name) = reshape(value(orderedIndices), 1, []);
    end
end
fields = {'groups','tags','groundTruthClassification'};
for index = 1:numel(fields)
    name = fields{index};
    if isfield(source, name)
        groups = source.(name);
        if ~isstruct(groups) || ~isscalar(groups)
            error('ce:curation:InvalidAnnotations', '%s must be a scalar struct.', name);
        end
        names = fieldnames(groups);
        for groupIndex = 1:numel(names)
            members = groups.(names{groupIndex});
            if ~isnumeric(members) || any(~isfinite(members(:))) || ...
                    any(members(:) < 1 | members(:) > numel(source.UID) | members(:) ~= fix(members(:)))
                error('ce:curation:InvalidAnnotations', 'Invalid cell indices in %s.%s.', name, names{groupIndex});
            end
        end
        updated.(name) = ce.curation.subsetGroups(groups, orderedIndices);
    end
end
end
