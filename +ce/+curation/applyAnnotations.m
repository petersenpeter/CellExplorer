function updated = applyAnnotations(target, source, indices)
%APPLYANNOTATIONS Apply annotations to a complete session by cell identity.
% UID is session-local. Also check cluID when both structures provide it.
% When either dataset has a sorting revision, both session-local revisions must
% match. Legacy pairs without revisions retain UID/cluster checks only.
orderedIndices = ce.curation.annotationOrder(target,source,indices);
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
