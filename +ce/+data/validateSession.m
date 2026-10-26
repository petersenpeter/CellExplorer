function report = validateSession(session, varargin)
%VALIDATESESSION Check session metadata without dialogs, mutation or file writes.
% report = ce.data.validateSession(session, 'checkFiles', false)
% Every check has code, path, severity (ok/warning/error) and message fields.
% Missing optional files are warnings: cached analyses may not require raw data.
p = inputParser;
addParameter(p,'checkFiles',true,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:});
report = ce.data.validationReport;
checks = report.checks;
if ~isstruct(session) || ~isscalar(session)
    add('InvalidSession','session','error','Provide a scalar session struct.');
    report = ce.data.validationReport(checks);
    return
end
textFields = {'general.name','general.basePath','animal.name'};
for index = 1:numel(textFields)
    name = textFields{index};
    if isText(get(name))
        add('ValidField',name,'ok','Defined.');
    else
        add('RequiredText',name,'error','Define a nonempty character vector or string scalar.');
    end
end
numericFields = {'extracellular.sr','extracellular.nChannels','extracellular.leastSignificantBit', ...
    'extracellular.nElectrodeGroups','extracellular.nSpikeGroups'};
for index = 1:numel(numericFields)
    name = numericFields{index};
    value = get(name);
    valid = positiveScalar(value);
    if contains(name,{'nChannels','nElectrodeGroups','nSpikeGroups'})
        valid = valid && value == fix(value);
    end
    if valid
        add('ValidField',name,'ok','Defined and positive.');
    else
        add('InvalidNumber',name,'error','Define a positive finite scalar; channel/group counts must be integers.');
    end
end
nChannels = get('extracellular.nChannels');
groups = {'electrodeGroups','spikeGroups'};
counts = {'nElectrodeGroups','nSpikeGroups'};
for index = 1:numel(groups)
    name = ['extracellular.',groups{index},'.channels'];
    channels = get(name);
    if isnumeric(channels) && ismatrix(channels) && ~isempty(channels)
        channels = num2cell(channels,2);
        add('LegacyChannelGroups',name,'warning','Numeric channel rows are accepted; the pipeline converts them to cell arrays.');
    end
    if ~iscell(channels) || isempty(channels) || ~isvector(channels)
        add('InvalidChannelGroups',name,'error','Provide a nonempty cell vector of channel lists.');
        continue
    end
    count = get(['extracellular.',counts{index}]);
    if positiveScalar(count) && count ~= numel(channels)
        add('GroupCountMismatch',name,'error','The group count must match the number of channel lists.');
    end
    allChannels = [];
    valid = true;
    for group = 1:numel(channels)
        if ~validIndices(channels{group},nChannels) || isempty(channels{group})
            add('InvalidChannels',sprintf('%s{%d}',name,group),'error', ...
                'Channels must be unique integers between 1 and extracellular.nChannels.');
            valid = false;
        else
            allChannels = [allChannels,reshape(channels{group},1,[])]; %#ok<AGROW>
        end
    end
    if valid
        if numel(unique(allChannels)) ~= numel(allChannels)
            add('DuplicateChannels',name,'error','A channel occurs in more than one group.');
        elseif numel(allChannels) ~= nChannels
            add('PartialChannelCoverage',name,'warning','The groups do not cover every recording channel.');
        else
            add('ValidChannels',name,'ok','Channels are one-indexed, unique and cover the recording.');
        end
    end
end
sorting = get('spikeSorting');
if ~iscell(sorting) || isempty(sorting) || ~isvector(sorting)
    add('MissingSpikeSorting','spikeSorting','error','Provide a nonempty cell vector of spike-sorting metadata.');
else
    for index = 1:numel(sorting)
        name = sprintf('spikeSorting{%d}',index);
        if ~isstruct(sorting{index}) || ~isscalar(sorting{index}) || ...
                ~isfield(sorting{index},'format') || ~isText(sorting{index}.format)
            add('MissingSortingFormat',[name,'.format'],'error','Define the source spike-sorting format.');
        else
            add('ValidField',[name,'.format'],'ok',char(sorting{index}.format));
        end
        if isstruct(sorting{index}) && isscalar(sorting{index}) && isfield(sorting{index},'relativePath') && ...
                ~isempty(sorting{index}.relativePath) && ~isText(sorting{index}.relativePath)
            add('InvalidPath',[name,'.relativePath'],'error','Use text for the sorting directory (or empty for the session directory).');
        end
    end
end
epochs = get('epochs');
if ~isempty(epochs)
    if ~iscell(epochs) || ~isvector(epochs)
        add('InvalidEpochs','epochs','error','Provide a cell vector of epoch structs.');
    else
        for index = 1:numel(epochs)
            name = sprintf('epochs{%d}',index);
            epoch = epochs{index};
            if ~isstruct(epoch) || ~isscalar(epoch)
                add('InvalidEpoch',name,'error','Each epoch must be a scalar struct.');
                continue
            end
            if ~isfield(epoch,'name') || ~isText(epoch.name)
                add('MissingEpochName',[name,'.name'],'error','Define an epoch name.');
            end
            if all(isfield(epoch,{'startTime','stopTime'})) && ~isempty(epoch.startTime) && ~isempty(epoch.stopTime)
                start = epoch.startTime;
                stop = epoch.stopTime;
                if ~finiteScalar(start) || ~finiteScalar(stop) || start < 0 || stop <= start
                    add('InvalidEpochInterval',name,'error','Epoch times must be finite seconds with 0 <= startTime < stopTime.');
                end
            else
                add('MissingEpochTimes',name,'warning','Define startTime and stopTime to use epoch-based analysis.');
            end
        end
    end
end
containers = {'channelTags','brainRegions'};
for index = 1:numel(containers)
    value = get(containers{index});
    if isempty(value), continue; end
    if ~isstruct(value) || ~isscalar(value)
        add('InvalidChannelMetadata',containers{index},'error','Provide a scalar struct of named channel groups.');
        continue
    end
    names = fieldnames(value);
    for group = 1:numel(names)
        entry = value.(names{group});
        name = [containers{index},'.',names{group}];
        if ~isstruct(entry) || ~isscalar(entry)
            add('InvalidChannelMetadata',name,'error','Provide a scalar struct with channels or electrodeGroups.');
            continue
        end
        for kind = {'channels','electrodeGroups'}
            field = kind{1};
            limit = nChannels;
            if strcmp(field,'electrodeGroups'), limit = get('extracellular.nElectrodeGroups'); end
            if isfield(entry,field) && ~isempty(entry.(field)) && ~validIndices(entry.(field),limit)
                add('InvalidChannels',[name,'.',field],'error','Use unique, one-indexed channel/group indices within the recording.');
            end
        end
    end
end
if p.Results.checkFiles && isText(get('general.basePath'))
    basepath = char(get('general.basePath'));
    if isfolder(basepath)
        add('BasepathExists','general.basePath','ok',basepath);
    else
        add('MissingBasepath','general.basePath','error',['Directory does not exist: ',basepath]);
    end
    if isText(get('general.name'))
        raw = get('extracellular.fileName');
        if isempty(raw), raw = [char(get('general.name')),'.dat']; end
        if ~isText(raw)
            add('InvalidPath','extracellular.fileName','error','Use a raw filename or leave it empty for basename.dat.');
        else
            fileCheck(fullfile(basepath,char(raw)),'extracellular.fileName','RawData');
        end
    end
    if iscell(sorting) && ~isempty(sorting) && isstruct(sorting{1}) && isscalar(sorting{1})
        relativePath = '';
        if isfield(sorting{1},'relativePath'), relativePath = sorting{1}.relativePath; end
        if isempty(relativePath) || isText(relativePath)
            folder = fullfile(basepath,char(relativePath));
            if ~isfolder(folder)
                add('MissingSortingDirectory','spikeSorting{1}.relativePath','warning', ...
                    ['Sorting directory is unavailable; cached spikes may still be usable: ',folder]);
            end
        end
    end
end
report = ce.data.validationReport(checks);

    function value = get(name)
        value = session;
        parts = strsplit(name,'.');
        for part = 1:numel(parts)
            if ~isstruct(value) || ~isscalar(value) || ~isfield(value,parts{part})
                value = []; return
            end
            value = value.(parts{part});
        end
    end
    function add(code,name,severity,message)
        checks(end+1) = struct('code',code,'path',name,'severity',severity,'message',message);
    end
    function fileCheck(file,name,code)
        if isfile(file)
            add([code,'Exists'],name,'ok',file);
        else
            add(['Missing',code],name,'warning',['File is unavailable; only stages that use it require it: ',file]);
        end
    end
end

function valid = isText(value)
valid = (ischar(value) && isrow(value) || isstring(value) && isscalar(value) && ~ismissing(value)) && ...
    strlength(strtrim(string(value))) > 0;
end

function valid = finiteScalar(value)
valid = isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value);
end

function valid = positiveScalar(value)
valid = finiteScalar(value) && value > 0;
end

function valid = validIndices(value,limit)
valid = positiveScalar(limit) && isnumeric(value) && isreal(value) && (isempty(value) || isvector(value)) && ...
    all(isfinite(value(:)) & value(:) >= 1 & value(:) <= limit & value(:) == fix(value(:))) && ...
    numel(unique(value)) == numel(value);
end
