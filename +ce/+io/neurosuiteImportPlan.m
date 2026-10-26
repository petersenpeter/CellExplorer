function plan = neurosuiteImportPlan(session, varargin)
%NEUROSUITEIMPORTPLAN Resolve explicit import inputs without reading sample arrays.
p = inputParser;
addParameter(p,'basename','',@ischar);
addParameter(p,'clusteringpath',[],@ischar);
addParameter(p,'electrodeGroups',NaN,@isnumeric);
addParameter(p,'raw_clusters',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'getWaveformsFromSource',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'LSB',[],@isnumeric);
parse(p,varargin{:}); options = p.Results;
if ~isstruct(session) || ~isscalar(session) || ~isfield(session,'general') || ...
        ~isstruct(session.general) || ~isscalar(session.general) || ...
        ~isfield(session.general,'basePath') || ~ischar(session.general.basePath) || ...
        ~isrow(session.general.basePath) || ~isfolder(session.general.basePath) || ...
        ~isfield(session,'extracellular') || ~isstruct(session.extracellular) || ...
        ~isscalar(session.extracellular) || ~isfield(session.extracellular,'sr') || ...
        ~positiveScalar(session.extracellular.sr)
    error('ce:io:InvalidSortingMetadata','Provide an existing session.general.basePath and a positive extracellular.sr; metadata is never inferred interactively.');
end
basename = options.basename;
if isempty(basename) && isfield(session.general,'name'), basename = session.general.name; end
if ~ischar(basename) || ~isrow(basename) || isempty(basename) || any(ismember(basename,'/\'))
    error('ce:io:InvalidSortingMetadata','Provide a nonempty recording basename without directory separators.');
end
relativePath = options.clusteringpath;
if ~ischar(relativePath)
    relativePath = '';
    if isfield(session,'spikeSorting') && iscell(session.spikeSorting) && ~isempty(session.spikeSorting) && ...
            isstruct(session.spikeSorting{1}) && isscalar(session.spikeSorting{1}) && ...
            isfield(session.spikeSorting{1},'relativePath')
        relativePath = session.spikeSorting{1}.relativePath;
    end
end
if ~ischar(relativePath) || (~isempty(relativePath) && ~isrow(relativePath))
    error('ce:io:InvalidSortingMetadata','The clustering path must be a character row.');
end
folder = fullfile(session.general.basePath,relativePath);
if options.raw_clusters, folder = fullfile(folder,'OriginalClus'); end
if ~isfolder(folder), error('ce:io:MissingSortingInput','Sorting directory not found: %s.',folder); end
if options.raw_clusters && options.getWaveformsFromSource
    error('ce:io:UnsupportedSourceWaveforms','OriginalClus waveform alignment is not declared; import timestamps without source waveforms.');
end

electrodeGroups = options.electrodeGroups;
if isscalar(electrodeGroups) && isnan(electrodeGroups)
    files = dir(fullfile(folder,[basename,'.res.*']));
    expression = ['^',regexptranslate('escape',basename),'\.res\.([1-9][0-9]*)$'];
    tokens = regexp({files.name},expression,'tokens','once');
    tokens = tokens(~cellfun(@isempty,tokens));
    electrodeGroups = sort(cellfun(@(x) str2double(x{1}),tokens));
end
if isempty(electrodeGroups)
    error('ce:io:MissingSortingInput','No numbered .res files found in %s.',folder);
end
if ~isreal(electrodeGroups) || ~isvector(electrodeGroups) || ...
        any(~isfinite(electrodeGroups) | electrodeGroups<1 | electrodeGroups~=fix(electrodeGroups)) || ...
        numel(unique(electrodeGroups))~=numel(electrodeGroups)
    error('ce:io:InvalidElectrodeGroups','Electrode groups must be distinct positive integers, or scalar NaN for discovery.');
end
electrodeGroups = electrodeGroups(:)';
scale = options.LSB;
if options.getWaveformsFromSource
    if isempty(scale) && isfield(session.extracellular,'leastSignificantBit')
        scale = session.extracellular.leastSignificantBit;
    end
    if ~positiveScalar(scale)
        error('ce:io:InvalidSortingMetadata','Source waveforms require a positive leastSignificantBit or explicit LSB in microvolts per bit.');
    end
    validateChannelGroups(session.extracellular,electrodeGroups);
end
% Check every required path before allocating source waveform arrays.
files = struct('file',{},'kind',{},'group',{});
for group = electrodeGroups
    extensions = {'clu','res'};
    if options.getWaveformsFromSource, extensions{end+1} = 'spk'; end
    for extension = extensions
        file = fullfile(folder,sprintf('%s.%s.%d',basename,extension{1},group));
        requireFile(file);
        files(end+1) = struct('file',file,'kind',extension{1},'group',group);
    end
end

plan = struct('folder',folder,'basename',basename,'electrodeGroups',electrodeGroups, ...
    'scale',scale,'options',options,'files',files);
end

function requireFile(file)
if ~isfile(file), error('ce:io:MissingSortingInput','Required sorting input not found: %s.',file); end
end

function value = positiveScalar(value)
value = isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value) && value>0;
end

function validateChannelGroups(extra,groups)
if ~isfield(extra,'nChannels') || ~positiveScalar(extra.nChannels) || extra.nChannels~=fix(extra.nChannels) || ...
        ~isfield(extra,'electrodeGroups') || ~isstruct(extra.electrodeGroups) || ~isscalar(extra.electrodeGroups) || ...
        ~isfield(extra.electrodeGroups,'channels') || ~iscell(extra.electrodeGroups.channels) || ...
        max(groups)>numel(extra.electrodeGroups.channels)
    error('ce:io:InvalidSortingMetadata','Source waveforms need nChannels and one-based electrodeGroups.channels for every requested group.');
end
for group = groups
    channels = extra.electrodeGroups.channels{group};
    if ~isnumeric(channels) || ~isreal(channels) || isempty(channels) || ~isvector(channels) || ...
            any(~isfinite(channels) | channels<1 | channels>extra.nChannels | channels~=fix(channels)) || ...
            numel(unique(channels))~=numel(channels)
        error('ce:io:InvalidSortingMetadata','Invalid one-based channels for electrode group %d.',group);
    end
end
end

