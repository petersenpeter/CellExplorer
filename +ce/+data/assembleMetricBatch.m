function batch = assembleMetricBatch(sessions, basepaths, basenames, saveAs)
%ASSEMBLEMETRICBATCH Pure assembly; identity remains local to each batchID.
if isempty(sessions) || ~iscell(sessions) || ~iscellstr(basepaths) || ~iscellstr(basenames) || ...
        numel(sessions) ~= numel(basepaths) || numel(sessions) ~= numel(basenames)
    error('ce:data:InvalidMetricBatch','Provide one metrics struct and source path/name per session.');
end
sessions = sessions(:)';
count = zeros(1,numel(sessions)); names = {};
for index = 1:numel(sessions)
    metrics = sessions{index}; count(index) = ce.data.metricCellCount(metrics);
    if ~isfield(metrics,'cellID'), metrics.cellID = metrics.UID; end
    for container = {'session','animal'}
        parent = container{1};
        if isfield(metrics.general,parent)
            metadata = metrics.general.(parent);
            if ~isstruct(metadata) || ~isscalar(metadata)
                error('ce:data:InvalidMetricBatch','general.%s must be a scalar struct.',parent);
            end
            for key = fieldnames(metadata)'
                metrics.([parent,'_',key{1}]) = repmat({metadata.(key{1})},1,count(index));
            end
        end
    end
    sessions{index} = metrics; names = union(names,fieldnames(metrics));
end
offsets = [0 cumsum(count)]; total = sum(count);
batch = struct(); batch.general.basename = 'Batch of sessions';
batch.batchIDs = repelem(1:numel(sessions),count);
batch.general.cellCount = total;
batch.general.basepaths = basepaths(:)'; batch.general.basenames = basenames(:)';
batch.general.saveAs = repmat({saveAs},1,numel(sessions));
for index = 1:numel(sessions)
    batch.general.batch{index} = sessions{index}.general;
end
batch.putativeConnections = connections(sessions, count, offsets);
names = setdiff(names,{'general','putativeConnections','truePositive','falsePositive','batchIDs'});
for item = names(:)'
    name = item{1};
    if ismember(name,{'tags','groups','groundTruthClassification'})
        batch.(name) = struct();
        for index = 1:numel(sessions)
            if ~isfield(sessions{index},name), continue; end
            groups = ce.data.metricGroups(sessions{index}.(name),count(index),name);
            for key = fieldnames(groups)'
                field = key{1};
                if ~isfield(batch.(name),field), batch.(name).(field) = []; end
                batch.(name).(field) = [batch.(name).(field),groups.(field)+offsets(index)];
            end
        end
    else
        values = cell(size(sessions)); present = false(size(sessions));
        for index = 1:numel(sessions)
            present(index) = isfield(sessions{index},name);
            if present(index), values{index} = sessions{index}.(name); end
        end
        batch.(name) = combine(values,present,count,name,true);
    end
end
end

function output = combine(values, present, count, description, topLevel)
first = values{find(present,1)};
if isstruct(first)
    names = {};
    for index = find(present)
        if ~isstruct(values{index}) || ~isscalar(values{index}), mismatch(description); end
        names = union(names,fieldnames(values{index}));
    end
    output = struct();
    for key = names(:)'
        children = cell(size(values)); found = false(size(present));
        for index = find(present)
            found(index) = isfield(values{index},key{1});
            if found(index), children{index} = values{index}.(key{1}); end
        end
        output.(key{1}) = combine(children,found,count,[description,'.',key{1}],false);
    end
elseif iscell(first)
    output = cell(1,sum(count));
    if topLevel, output(:) = {''}; end
    offsets = [0 cumsum(count)];
    for index = find(present)
        value = values{index};
        if ~iscell(value) || ~isvector(value) || numel(value) ~= count(index), mismatch(description); end
        output(offsets(index)+1:offsets(index+1)) = value(:)';
    end
elseif isnumeric(first) || islogical(first)
    rows = [];
    for index = find(present)
        value = values{index};
        if ~(isnumeric(value) || islogical(value)) || ~isreal(value) || ~ismatrix(value), mismatch(description); end
        if topLevel && isvector(value) && numel(value) == count(index), value = value(:)'; end
        if isempty(value), present(index) = false; continue; end
        if size(value,2) ~= count(index) || topLevel && size(value,1) ~= 1, mismatch(description); end
        if isempty(rows), rows = size(value,1); end
        if rows ~= size(value,1), mismatch(description); end
        values{index} = value;
    end
    if isempty(rows), rows = max(1,size(first,1)); end
    % Floating padding is explicit; never insert implicit zeros into missing data.
    if any(~present)
        for index = find(present)
            value = values{index};
            if isinteger(value) && (any(value(:) > cast(flintmax,'like',value)) || ...
                    any(value(:) < cast(-flintmax,'like',value)))
                error('ce:data:MetricTypeConflict','Cannot pad %s without losing integer precision.',description);
            end
            values{index} = double(value);
        end
        for index = find(~present), values{index} = nan(rows,count(index)); end
    else
        classes = cellfun(@class,values,'UniformOutput',false);
        if numel(unique(classes)) > 1, mismatch(description); end
    end
    output = cat(2,values{:});
else
    error('ce:data:UnsupportedMetricType','%s must contain per-cell arrays or structs; put session metadata in general.',description);
end
end

function output = connections(sessions, count, offsets)
output = struct('excitatory',[],'inhibitory',[],'excitatoryTransProb',[],'inhibitoryTransProb',[]);
for index = 1:numel(sessions)
    if ~isfield(sessions{index},'putativeConnections'), continue; end
    source = sessions{index}.putativeConnections;
    if ~isstruct(source) || ~isscalar(source), mismatch('putativeConnections'); end
    for kind = {'excitatory','inhibitory'}
        name = kind{1}; probability = [name,'TransProb']; pairs = [];
        if isfield(source,name), pairs = source.(name); end
        if ~isnumeric(pairs) || ~isreal(pairs) || ~isempty(pairs) && (~ismatrix(pairs) || size(pairs,2) ~= 2) || ...
                any(~isfinite(pairs(:)) | pairs(:) < 1 | pairs(:) > count(index) | pairs(:) ~= fix(pairs(:)))
            error('ce:data:InvalidMetricConnections','%s must contain pairs of local one-based cell indices.',name);
        end
        n = size(pairs,1); if isempty(pairs), n = 0; end
        probabilities = nan(1,n);
        if isfield(source,probability)
            probabilities = source.(probability);
            if ~isnumeric(probabilities) || ~isreal(probabilities) || numel(probabilities) ~= n, mismatch(probability); end
        end
        output.(name) = [output.(name); pairs+offsets(index)];
        output.(probability) = [output.(probability),probabilities(:)'];
    end
end
end

function mismatch(description)
error('ce:data:MetricShapeConflict','Incompatible types or per-cell dimensions in %s; align these data before batching.',description);
end
