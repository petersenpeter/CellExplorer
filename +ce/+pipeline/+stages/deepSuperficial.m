function patch = deepSuperficial(inputs)
%DEEPSUPERFICIAL Project reviewed channel assignments onto identified cells.
projection = inputs.cells;
projection.available = inputs.record.available;
projection.labels = repmat({''},1,numel(projection.UID));
projection.distances = nan(1,numel(projection.UID));
if inputs.record.available
    data = inputs.record.data;
    projection.labels = reshape(data.channelClass(projection.maxWaveformCh1),1,[]);
    projection.distances = reshape(data.channelDistance(projection.maxWaveformCh1),1,[]);
    patch.general.SWR = data;
    patch.general.deepSuperficial_file = inputs.record.file;
    if isfield(data,'processinginfo')
        patch.general.processinginfo.deepSuperficialfromRipple = data.processinginfo;
    end
end
patch.general.processinginfo.deepSuperficialProjection = projection;
end
