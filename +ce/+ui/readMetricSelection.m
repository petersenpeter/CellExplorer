function metrics = readMetricSelection(file)
%READMETRICSELECTION Load a selected MAT file without importing caller variables.
metrics = ce.io.readCellMetrics(file);
[folder,name,extension] = fileparts(file);
if isempty(folder), folder = pwd; end
if ~isfield(metrics.general,'batch')
    metrics.general.basepath = folder;
    parts = strsplit(name,'.');
    if numel(parts) >= 3 && strcmp(parts{end},'cellinfo')
        metrics.general.saveAs = parts{end-1};
        metrics.general.basename = strjoin(parts(1:end-2),'.');
        if isfield(metrics.general,'filename'), metrics.general = rmfield(metrics.general,'filename'); end
    else
        metrics.general.filename = [name,extension];
    end
end
end
