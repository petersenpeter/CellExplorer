function restoreMetricView(snapshot)
%RESTOREMETRICVIEW Restore surviving controls; caller rebuilds dynamic tag buttons.
for index = 1:numel(snapshot)
    if isgraphics(snapshot(index).handle)
        set(snapshot(index).handle,snapshot(index).properties);
    end
end
end
