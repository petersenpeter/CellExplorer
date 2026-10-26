function metrics = reconcileDeepSuperficial(metrics, previous)
%RECONCILEDEEPSUPERFICIAL Keep cell annotations separate from channel projection.
projection = metrics.general.processinginfo.deepSuperficialProjection;
count = numel(projection.UID);
fields = {'deepSuperficial','deepSuperficialDistance'};
values = {projection.labels,projection.distances};
old = ce.pipeline.outputSnapshot(previous,{'general.processinginfo.deepSuperficialProjection'});
review = ce.pipeline.outputSnapshot(previous,{'general.processinginfo.deepSuperficialReview'});
origin = ce.pipeline.outputSnapshot(previous,{'general.processinginfo.stages.deepSuperficial'});
verified = old.present && sameCells(old.value,projection) && origin.present && ...
    isstruct(origin.value) && isscalar(origin.value) && isfield(origin.value,'outputHash');
if verified
    definition = ce.pipeline.stageDefinition('deepSuperficial');
    verified = isequal(origin.value.outputHash,ce.pipeline.fingerprint(ce.pipeline.outputSnapshot(previous,definition.outputs)));
end
knownReview = review.present && sameCells(review.value,projection);
state.UID = projection.UID;
if isfield(projection,'cluID'), state.cluID = projection.cluID; end
state.unverifiedLegacy = false;
for index = 1:2
    field = fields{index}; automatic = values{index};
    retained = false(1,count);
    if isfield(previous,field)
        if ~sameCells(previous,projection)
            error('ce:curation:DeepSuperficialIdentity','Existing deep/superficial annotations must match spike UID/cluster identity and order.');
        end
        current = previous.(field);
        valid = isequal(size(current),[1 count]);
        if index == 1
            valid = valid && iscell(current) && all(cellfun(@(x) ischar(x) && (isrow(x) || isempty(x)),current));
        else
            valid = valid && isnumeric(current) && isreal(current) && ~any(isinf(current));
        end
        if ~valid, error('ce:curation:InvalidDeepSuperficial','Invalid existing %s annotations; reconcile them before recomputing.',field); end
        if verified
            key = 'labels'; if index == 2, key = 'distances'; end
            if ~isfield(old.value,key) || ~isequal(size(old.value.(key)),[1 count])
                error('ce:curation:InvalidDeepSuperficial','Stored automatic projection is incomplete.');
            end
            for cellIndex = 1:count
                retained(cellIndex) = ~isequaln(current(cellIndex),old.value.(key)(cellIndex));
            end
        else
            retained(:) = true; % Unknown legacy values may already be curated.
            state.unverifiedLegacy = true;
        end
        % Keep a known override even if a changed/newly absent source happens
        % to agree with it. A later source change must not silently discard it.
        if knownReview && all(isfield(review.value,{'overrides','values'})) && ...
                isfield(review.value.overrides,field) && isfield(review.value.values,field)
            mask = review.value.overrides.(field); saved = review.value.values.(field);
            if ~islogical(mask) || ~isequal(size(mask),[1 count]) || ~isequal(size(saved),[1 count])
                error('ce:curation:InvalidDeepSuperficial','Stored annotation review has invalid dimensions.');
            end
            for cellIndex = find(mask)
                retained(cellIndex) = retained(cellIndex) || isequaln(current(cellIndex),saved(cellIndex));
            end
            if verified && ~old.value.available
                % Finalization may add Unknown/NaN placeholders for the UI.
                % Recorded non-overrides must not become annotations on rerun.
                for cellIndex = find(~mask)
                    if isequaln(current(cellIndex),saved(cellIndex)), retained(cellIndex) = false; end
                end
            end
        end
        automatic(retained) = current(retained);
    end
    if projection.available || any(retained)
        metrics.(field) = automatic;
    elseif isfield(metrics,field)
        metrics = rmfield(metrics,field);
    end
    state.overrides.(field) = retained;
    state.values.(field) = automatic;
end
state.preservedCellCount = sum(state.overrides.deepSuperficial | state.overrides.deepSuperficialDistance);
state.status = 'projected';
if ~projection.available, state.status = 'source_unavailable'; end
if state.preservedCellCount > 0, state.status = 'cell_annotations_preserved'; end
if state.unverifiedLegacy, state.status = 'legacy_annotations_preserved'; end
metrics.general.processinginfo.deepSuperficialReview = state;
end

function same = sameCells(left,right)
same = isstruct(left) && isscalar(left) && isfield(left,'UID') && isequal(left.UID,right.UID);
if same && (isfield(left,'cluID') || isfield(right,'cluID'))
    same = all(isfield(left,{'cluID'})) && isfield(right,'cluID') && isequal(left.cluID,right.cluID);
end
end
