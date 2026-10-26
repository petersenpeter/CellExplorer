function values = outputSnapshot(metrics, paths)
%OUTPUTSNAPSHOT Capture only the fields owned by a stage, including absence.
values = struct('path',{},'present',{},'value',{});
for index = 1:numel(paths)
    value = metrics;
    parts = strsplit(paths{index},'.');
    present = true;
    for part = 1:numel(parts)
        if ~isstruct(value) || ~isscalar(value) || ~isfield(value,parts{part})
            present = false; value = []; break
        end
        value = value.(parts{part});
    end
    values(index).path = paths{index};
    values(index).present = present;
    values(index).value = value;
end
end
