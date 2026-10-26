function records = importedCellFiles(session, kind, spikes)
%IMPORTEDCELLFILES Validate and align externally calculated per-cell data.
% Identity is explicit: UID or cluID describes the order of the source columns.
% Legacy files without identity must be annotated by their producer; equal
% cell counts alone are not evidence that the columns describe these cells.
switch kind
    case 'spatial_metrics', suffix = 'firingRateMap'; field = 'map';
    case 'psth_metrics', suffix = 'psth'; field = 'unit';
    otherwise, error('ce:pipeline:UnknownStage','Unknown import stage %s.',kind);
end
files = dir(fullfile(session.general.basePath,[session.general.name,'.*.',suffix,'.mat']));
[~,order] = sort({files.name}); files = files(order);
records = struct('name',{},'file',{},'sha256',{},'data',{});
for index = 1:numel(files)
    parts = strsplit(files(index).name,'.'); name = parts{end-2};
    if ~isvarname(name) || any(strcmp({records.name},name))
        error('ce:pipeline:AmbiguousCellImport','Input names must be valid and unique: %s.',files(index).name);
    end
    file = fullfile(session.general.basePath,files(index).name);
    hash = ce.pipeline.fileFingerprint(file);
    loaded = load(file,name);
    if ~isfield(loaded,name) || ~isstruct(loaded.(name)) || ~isscalar(loaded.(name))
        error('ce:pipeline:InvalidCellImport','%s must contain a scalar struct named %s.',file,name);
    end
    source = loaded.(name);
    if ~isfield(source,field) || ~isfield(source,'x_bins') || ...
            ~isnumeric(source.x_bins) || ~isreal(source.x_bins) || ~isvector(source.x_bins) || ...
            isempty(source.x_bins) || any(~isfinite(source.x_bins(:)))
        error('ce:pipeline:InvalidCellImport','%s requires %s and a finite x_bins vector.',file,field);
    end
    order = ce.data.cellIdentityOrder(source,spikes,file);
    values = source.(field);
    if strcmp(kind,'spatial_metrics')
        valid = iscell(values) && isrow(values) && numel(values) == numel(order);
        if valid
            for cellIndex = 1:numel(values)
                value = values{cellIndex};
                valid = valid && validMatrix(value,numel(source.x_bins)) && size(value,2) >= 1;
                if strcmp(name,'ratemap')
                    valid = valid && size(value,2) == 1 && numel(source.x_bins) >= 2;
                end
            end
        end
    else
        valid = validMatrix(values,numel(source.x_bins)) && size(values,2) == numel(order);
    end
    if ~valid
        error('ce:pipeline:InvalidCellImport', ...
            '%s: %s dimensions must match x_bins and cell identity. ratemap requires one column per cell; use another name for state-dependent maps.',file,field);
    end
    data = struct();
    data.(field) = values(:,order);
    if strcmp(kind,'spatial_metrics')
        metadata = {'x_bins','x_label','boundaries','boundaryNames','stateNames'};
    else
        metadata = {'x_bins','x_label','boundaries','labels','boundaries_labels'};
    end
    for key = metadata
        if isfield(source,key{1}), data.(key{1}) = source.(key{1}); end
    end
    % Hash again so consumed data cannot be paired with a hash of an earlier file.
    if ~strcmp(hash,ce.pipeline.fileFingerprint(file))
        error('ce:pipeline:CellImportChanged','Input changed while being read: %s.',file);
    end
    records(end+1) = struct('name',name,'file',files(index).name,'sha256',hash,'data',data);
end
if strcmp(kind,'spatial_metrics') && all(ismember({'ratemap','firingRateMap'},{records.name}))
    error('ce:pipeline:AmbiguousCellImport','ratemap reserves the legacy firingRateMap output alias. Rename the other input.');
end
end

function valid = validMatrix(value,bins)
valid = isnumeric(value) && isreal(value) && ismatrix(value) && ...
    size(value,1) == bins && ~any(isinf(value(:)));
end

