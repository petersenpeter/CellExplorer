function revision = validateSortingRevision(revision)
%VALIDATESORTINGREVISION Accept only a nonempty SHA-256 revision token.
if isstring(revision) && isscalar(revision), revision = char(revision); end
if ~ischar(revision) || ~isrow(revision) || isempty(regexp(revision,'^[0-9a-f]{64}$','once'))
    error('ce:data:InvalidSortingRevision','A declared sorting revision must be a lowercase SHA-256 token.');
end
end
