function subset = groundTruthSubset(metrics, indices)
%GROUNDTRUTHSUBSET Prepare one session's selected cells without writes or UI.
count=ce.data.metricCellCount(metrics,true);
validateattributes(indices,{'numeric'},{'vector','integer','positive','finite','<=',count,'nonempty'});
indices=unique(reshape(indices,1,[]),'stable'); % Overlapping tags export each cell once.
if isfield(metrics.general,'batch')
    ce.data.metricSortingRevision(metrics,indices); % Exactly one session.
    general=metrics.general.batch{metrics.batchIDs(indices(1))};
else
    general=metrics.general;
end
subset=struct('general',general);
for key=fieldnames(metrics)'
    name=key{1}; value=metrics.(name);
    if ismember(name,{'general','putativeConnections','batchIDs','groups','tags','groundTruthClassification'}) || contains(name,'_num'), continue; end
    if (isnumeric(value) || islogical(value) || iscell(value)) && isvector(value) && numel(value)==count
        subset.(name)=reshape(value(indices),1,[]);
    elseif isstruct(value) && isscalar(value)
        subset.(name)=select(value);
    end
end
for key={'groups','tags','groundTruthClassification'}
    if isfield(metrics,key{1})
        groups=ce.data.metricGroups(metrics.(key{1}),count,key{1});
        subset.(key{1})=ce.curation.subsetGroups(groups,indices);
    end
end
subset.general.cellCount=numel(indices);
if isfield(subset.general,'classificationTrackChanges'), subset.general=rmfield(subset.general,'classificationTrackChanges'); end
ce.data.metricCellCount(subset);

    function output=select(input)
        output=struct();
        for field=fieldnames(input)'
            value=input.(field{1});
            if contains(field{1},'_zscored'), continue; end
            if (isnumeric(value) || islogical(value) || iscell(value)) && ismatrix(value) && size(value,2)==count
                output.(field{1})=value(:,indices);
            elseif isstruct(value) && isscalar(value)
                output.(field{1})=select(value);
            end
        end
    end
end
