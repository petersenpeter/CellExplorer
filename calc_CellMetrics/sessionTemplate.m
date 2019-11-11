function session = sessionTemplate(input1,varargin)
% This script can be used to create a session struct (e.g. metadata for the Cell Explorer)
% Load parameters from a Neurosuite xml file and buzcode sessionInfo file and any other parameters specified in this script.
% This script must be called from the basepath of your dataset, or be provided with a basepath as input

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 01-11-2019

p = inputParser;
addParameter(p,'importSkippedChannels',true,@islogical); % Import skipped channels from the xml as bad channels
addParameter(p,'importSyncedChannels',true,@islogical); % Import channel not synchronized between anatomical and spike groups as bad channels
addParameter(p,'noPrompts',true,@islogical); % Show the session gui if requested
addParameter(p,'showGUI',false,@islogical); % Show the session gui if requested

% Parsing inputs
parse(p,varargin{:})
importSkippedChannels = p.Results.importSkippedChannels;
importSyncedChannels = p.Results.importSyncedChannels;
noPrompts = p.Results.noPrompts;
showGUI = p.Results.showGUI;

% Initializing session struct and defining basepath, if not specified as an input
if nargin<1
    basepath = pwd;
elseif ischar(input1)
    basepath = input1;
    cd(basepath)
elseif isstruct(input1)
    session = input1;
    if isfield(session.general,'basePath') && exist(session.general.basePath,'dir')
        basepath = session.general.basePath;
        cd(basepath)
    else
        basepath = pwd;
    end
end

% Loading existing basename.session.mat file if exist
[~,basename,~] = fileparts(basepath);
if ~exist('session','var') && exist(fullfile(basepath,[basename,'.session.mat']),'file')
    load(fullfile(basepath,[basename,'.session.mat']))
elseif ~exist('session','var')
    session = [];
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Standard parameters. Please change accordingly to represent your session
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
pathPieces = regexp(basepath, filesep, 'split'); % Assumes file structure: animal/session/

% % % % % % % % % %
% General metadata
% % % % % % % % % % 
session.general.basePath =  basepath; % Full path
temp = dir('Kilosort_*');
if ~isempty(temp)
    session.general.clusteringPath = temp.name; % clusteringPath assumed from Kilosort
else
    session.general.clusteringPath = ''; % Full path to the clustered data (here assumed to be the basepath)
end
session.general.name = pathPieces{end}; % Session name
session.general.version = 1; % Metadata version

% % % % % % % % % %
% Limited animal metadata (practical information)
% % % % % % % % % %
session.animal.name = pathPieces{end-1}; % Animal name
session.animal.sex = 'Male'; % Male, Female, Unknown
session.animal.species = 'Rat'; % Mouse, Rat, ... (http://buzsakilab.com/wp/species/)
session.animal.strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
session.animal.geneticLine = 'Wild type';

% % % % % % % % % %
% Extracellular
% % % % % % % % % %
session.analysisTags.probesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
session.analysisTags.probesVerticalSpacing = 10; % (µm) Vertical spacing between sites.
session.extracellular.leastSignificantBit = 0.195; % (in µV) Intan = 0.195, Amplipex = 0.3815
session.extracellular.probeDepths = 0;
session.extracellular.precision = 'int16';

% % % % % % % % % %
% Spike sorting
% % % % % % % % % %
session.spikeSorting{1}.format = 'Phy'; % Sorting data-format: Phy, Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
session.spikeSorting{1}.method = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus
session.spikeSorting{1}.relativePath = session.general.clusteringPath;
session.spikeSorting{1}.channels = [];

% % % % % % % % % %
% Brain regions 
% % % % % % % % % %
% Brain regions  must be defined as index-1. Can be specified on a channel or spike group basis (below example for CA1 across all channels)
% session.brainRegions.CA1.channels = 1:128; % Brain region assignment (Allan institute Acronyms: http://atlas.brain-map.org/atlas?atlas=1)

% % % % % % % % % %
% Channel tags
% % % % % % % % % %
% Channel tags must be defined as 1-index. Each tag is a fieldname with the
% channels or spike groups as subfields. Below examples shows 5 tags (Theta, Ripple, RippleNoise, Cortical, Bad)

% session.channelTags.Theta.channels = 64; % Theta channel
% session.channelTags.Ripple.channels = 64; % Ripple channel
% session.channelTags.Ripple.spikeGroups = 3; % Ripple spike group
% session.channelTags.RippleNoise.channels = 1; % Ripple Noise reference channel
% session.channelTags.Cortical.spikeGroups = 3; % Cortical spike groups
% session.channelTags.Bad.channels = 1; % Bad channels
% session.channelTags.Bad.spikeGroups = 1; % Bad spike groups (broken shanks)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading parameters from Buzcode and Neurosuite (including skipped and dead channels)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if exist([session.general.basePath,session.general.name,'.sessionInfo.mat'],'file')
    load([session.general.basePath,session.general.name,'.sessionInfo.mat'])
%     sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);
    if sessionInfo.spikeGroups.nGroups>0
        session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
        session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
    else
        warning('No spike groups exist in the xml. Anatomical groups used instead')
        session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
    end
    session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
elseif exist('LoadXml.m','file')
    sessionInfo = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    if isfield(sessionInfo,'SpkGrps')
        session.extracellular.nSpikeGroups = length(sessionInfo.SpkGrps); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.SpkGrps.Channels}; % Spike groups
    else
        warning('No spike groups exist in the xml. Anatomical groups used instead')
        session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
    end
    session.extracellular.sr = sessionInfo.SampleRate; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.lfpSampleRate; % Sampling rate of lfp file
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
else
    sessionInfo = [];
end

% Channel tags
if isfield(sessionInfo,'badchannels')
    if isfield(session.channelTags,'Bad')
        session.channelTags.Bad.channels = unique([session.channelTags.Bad.channels,sessionInfo.badchannels+1]);
    else
        session.channelTags.Bad.channels = sessionInfo.badchannels+1;
    end
end

if isfield(sessionInfo,'channelTags')
    tagNames = fieldnames(sessionInfo.channelTags);
    for iTag = 1:length(tagNames)
        if isfield(session,'channelTags') && isfield(session.channelTags,tagNames{iTag})
            session.channelTags.(tagNames{iTag}).channels = unique([session.channelTags.(tagNames{iTag}).channels,sessionInfo.channelTags.(tagNames{iTag})+1]);
        else
            session.channelTags.(tagNames{iTag}).channels = sessionInfo.channelTags.(tagNames{iTag})+1;
        end
    end
end

% Brain regions
if isfield(sessionInfo,'region')
    load BrainRegions.mat
    regionNames = unique(cellfun(@num2str,sessionInfo.region,'uni',0));
    regionNames(cellfun('isempty',regionNames)) = [];
    for iRegion = 1:length(regionNames)
        if any(strcmp(regionNames(iRegion),BrainRegions(:,2)))
            session.brainRegions.(regionNames{iRegion}).channels = find(strcmp(regionNames(iRegion),sessionInfo.region));
        elseif strcmp(regionNames(iRegion),'HPC')
            session.brainRegions.HIP.channels = find(strcmp(regionNames(iRegion),sessionInfo.region));
        else
            warning(['Brain region does not exist in the Allen Brain Atlas: ' regionNames{iRegion}])
        end
    end
end

% Epochs derived from MergePoints
if exist(fullfile(basepath,[session.general.name,'.MergePoints.events.mat']),'file')
    load(fullfile(basepath,[session.general.name,'.MergePoints.events.mat']))
    for i = 1:size(MergePoints.foldernames)
        session.epochs{i}.name =  MergePoints.foldernames{i};
        session.epochs{i}.startTime =  MergePoints.timestamps(i,1);
        session.epochs{i}.stopTime =  MergePoints.timestamps(i,2);
    end
end

% Time series
% Loading info about time series from Intan metadatafile info.rhd
session = loadIntanMetadata(session);


% Skipped and dead channels
if (importSkippedChannels || importSyncedChannels) && exist(fullfile(session.general.basePath,[session.general.name, '.xml']),'file')
    sessionInfo = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    
    % Removing dead channels by the skip parameter in the xml file
    if importSkippedChannels
        order = [sessionInfo.AnatGrps.Channels];
        skip = find([sessionInfo.AnatGrps.Skip]);
        badChannels_skipped = order(skip)+1;
    else
        badChannels_skipped = [];
    end
    % Removing dead channels by comparing AnatGrps to SpkGrps in the xml file
    if importSyncedChannels & isfield(sessionInfo,'SpkGrps')
        skip2 = find(~ismember([sessionInfo.AnatGrps.Channels], [sessionInfo.SpkGrps.Channels])); % finds the indices of the channels that are not part of SpkGrps
        badChannels_synced = order(skip2)+1;
    else
        badChannels_synced = [];
    end
    
    if isfield(session,'channelTags') & isfield(session.channelTags,'Bad')
        session.channelTags.Bad.channels = unique([session.channelTags.Bad.channels,badChannels_skipped,badChannels_synced]);
    else
        session.channelTags.Bad.channels = unique([badChannels_skipped,badChannels_synced]);
    end
end

% Finally show GUI if requested by user
if ~noPrompts || showGUI
    session = gui_session(session);
end