function snapshot = captureAnnotations(metrics, indices)
%CAPTUREANNOTATIONS Capture one complete session with identity and revision.
count=ce.data.metricCellCount(metrics,true);
if nargin<2, indices=1:count; end
validateattributes(indices,{'numeric'},{'vector','integer','positive','finite','<=',count});
indices=reshape(indices,1,[]);
if numel(unique(indices))~=numel(indices)
    error('ce:curation:CellCountMismatch','A backup selection must contain distinct cells.');
end
if isfield(metrics.general,'batch')
    if ~isfield(metrics,'batchIDs') || numel(unique(metrics.batchIDs(indices)))~=1 || ...
            numel(indices)~=sum(metrics.batchIDs==metrics.batchIDs(indices(1)))
        error('ce:curation:CellCountMismatch','Select every cell from exactly one session.');
    end
elseif numel(indices)~=count
    error('ce:curation:CellCountMismatch','Select the complete session when backing up annotations.');
end
snapshot.UID=metrics.UID(indices);
if isfield(metrics,'cluID'), snapshot.cluID=metrics.cluID(indices); end
snapshot.general.cellCount=numel(indices);
revision=ce.data.metricSortingRevision(metrics,indices);
if ~isempty(revision), snapshot.general.sortingRevision=revision; end
for key={'labels','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType'}
    if isfield(metrics,key{1})
        value=metrics.(key{1});
        if ~isvector(value) || numel(value)~=count
            error('ce:curation:InvalidAnnotations','Expected one value per cell in %s.',key{1});
        end
        snapshot.(key{1})=reshape(value(indices),1,[]);
    end
end
for key={'groups','tags','groundTruthClassification'}
    if isfield(metrics,key{1})
        % Validate against the complete source before subsetting group indices.
        source=struct('UID',1:count); source.(key{1})=metrics.(key{1});
        ce.curation.applyAnnotations(struct('UID',1:count),source,1:count);
        snapshot.(key{1})=ce.curation.subsetGroups(metrics.(key{1}),indices);
    end
end
ce.curation.annotationOrder(snapshot,snapshot,1:numel(indices));
end
