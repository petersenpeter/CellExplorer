function metrics = reloadMetricSelection(current, progress)
%RELOADMETRICSELECTION Resolve the actual file(s), including alternate saveAs.
if nargin < 2, progress = @(fraction,message) []; end
if isfield(current.general,'batch')
    names = current.general.basenames; folders = current.general.basepaths;
    saveAs = repmat({'cell_metrics'},1,numel(names));
    if isfield(current.general,'saveAs')
        saveAs = current.general.saveAs;
        if ischar(saveAs), saveAs = repmat({saveAs},1,numel(names)); end
    end
    if ~iscellstr(saveAs) || numel(saveAs) ~= numel(names) || numel(folders) ~= numel(names)
        error('ce:io:InvalidBatchSources','Batch reload requires one source name, path and saveAs per session.');
    end
    sessions = cell(1,numel(names));
    for index = 1:numel(names)
        progress((index-1)/(numel(names)+1),sprintf('%d/%d: %s',index,numel(names),names{index}));
        sessions{index} = ce.io.readCellMetrics(fullfile(folders{index},[names{index},'.',saveAs{index},'.cellinfo.mat']));
    end
    progress(numel(names)/(numel(names)+1),'Assembling cell metrics');
    metrics = ce.data.assembleMetricBatch(sessions,folders,names,'cell_metrics');
    metrics.general.saveAs = saveAs(:)';
    progress(1,'Loading complete');
else
    folder = current.general.basepath;
    if isfield(current.general,'filename') && ~isempty(current.general.filename)
        file = fullfile(folder,current.general.filename);
    else
        saveAs = 'cell_metrics';
        if isfield(current.general,'saveAs'), saveAs = current.general.saveAs; end
        file = fullfile(folder,[current.general.basename,'.',saveAs,'.cellinfo.mat']);
    end
    metrics = ce.ui.readMetricSelection(file);
end
end
