function sources = sources(metrics)
%SOURCES Resolve complete session selections and canonical metric destinations.
count=ce.data.metricCellCount(metrics,true);
sources=struct('file',{},'indices',{});
if isfield(metrics.general,'batch')
    for index=1:numel(metrics.general.batch)
        saveAs='cell_metrics';
        if isfield(metrics.general,'saveAs'), saveAs=metrics.general.saveAs{index}; end
        file=fullfile(metrics.general.basepaths{index},[metrics.general.basenames{index},'.',saveAs,'.cellinfo.mat']);
        sources(end+1)=item(file,find(metrics.batchIDs==index));
    end
else
    general=metrics.general;
    if ~isfield(general,'basepath') || ~isfolder(general.basepath)
        error('ce:recovery:MissingSource','Recovery needs an existing session basepath.');
    end
    if isfield(general,'filename') && ~isempty(general.filename)
        file=fullfile(general.basepath,general.filename);
    else
        saveAs='cell_metrics'; if isfield(general,'saveAs'), saveAs=general.saveAs; end
        file=fullfile(general.basepath,[general.basename,'.',saveAs,'.cellinfo.mat']);
    end
    sources=item(file,1:count);
end
if numel(unique({sources.file}))~=numel(sources)
    error('ce:recovery:DuplicateSource','A recovery batch must not contain the same destination more than once.');
end
end

function value=item(file,indices)
if isempty(indices), error('ce:recovery:MissingSource','Recovery requires a nonempty session selection.'); end
value=struct('file',char(java.io.File(file).getCanonicalPath),'indices',reshape(indices,1,[]));
end
