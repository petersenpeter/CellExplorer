function records = intervalFiles(session, kind, ignored)
%INTERVALFILES Read named input variables without importing MAT workspace values.
suffix = struct('event_metrics','events','manipulation_metrics','manipulation','state_metrics','states');
files = dir(fullfile(session.general.basePath,[session.general.name,'.*.',suffix.(kind),'.mat']));
files = files(~contains({files.name},ignored));
[~,order] = sort({files.name}); files = files(order);
records = struct('name',{},'file',{},'sha256',{},'data',{});
for index = 1:numel(files)
    parts = strsplit(files(index).name,'.'); name = parts{end-2};
    if ~isvarname(name) || any(strcmp({records.name},name))
        error('ce:pipeline:AmbiguousIntervalName','Input names must be valid, unique MATLAB field names: %s.',files(index).name);
    end
    file = fullfile(session.general.basePath,files(index).name);
    hash = ce.pipeline.fileFingerprint(file);
    loaded = load(file,name);
    if ~isfield(loaded,name) || ~isstruct(loaded.(name)) || ~isscalar(loaded.(name))
        error('ce:pipeline:InvalidIntervalFile','%s must contain a scalar struct named %s.',file,name);
    end
    source = loaded.(name);
    data = struct();
    if strcmp(kind,'state_metrics')
        if ~isfield(source,'ints') || ~isstruct(source.ints) || ~isscalar(source.ints)
            error('ce:pipeline:InvalidIntervalFile','%s requires a scalar ints struct.',file);
        end
        data.ints = source.ints;
        for state = fieldnames(data.ints)'
            validateIntervals(data.ints.(state{1}),[file,': ',state{1}]);
        end
    else
        if ~isfield(source,'timestamps')
            error('ce:pipeline:InvalidIntervalFile','%s requires timestamps.',file);
        end
        validateIntervals(source.timestamps,file);
        data.timestamps = source.timestamps;
        if isfield(source,'peaks'), data.peaks = source.peaks; end
    end
    after = dir(file);
    if isempty(after) || after.bytes ~= files(index).bytes || after.datenum ~= files(index).datenum
        error('ce:pipeline:IntervalFileChanged','Input changed while being read: %s.',file);
    end
    records(end+1) = struct('name',name,'file',files(index).name,'sha256',hash,'data',data);
end
end

function validateIntervals(value,source)
if isempty(value) && isnumeric(value) && (isequal(size(value),[0 0]) || isequal(size(value),[0 2])), return; end
if ~isnumeric(value) || ~isreal(value) || ~ismatrix(value) || size(value,2) ~= 2 || ...
        any(~isfinite(value(:))) || any(value(:,1) < 0 | value(:,2) <= value(:,1))
    error('ce:pipeline:InvalidIntervalFile','%s requires finite Nx2 intervals with 0 <= start < stop.',source);
end
end
