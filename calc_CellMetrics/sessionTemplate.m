function session = sessionTemplate(basepath)
% This script can be used to create a session struct (e.g. metadata for the Cell Explorer)
% Load parameters from a Neurosuite xml file and buzcode sessionInfo file and any other parameters specified in this script.
% This script must be called from the basepath of your dataset, or be provided with a basepath as input

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 20-09-2019

% Settings:
% Import skipped channels from the xml as bad channels
importSkippedChannels = true;
% Import channel not synchronized between anatomical and spike groups as bad channels
importSyncedChannels = true;

% Initializing session struct and defining basepath, if not specified as an input
session = [];
if nargin<1
    basepath = pwd;
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Standard parameters. Please change accordingly to represent your session
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
pathPieces = regexp(basepath, filesep, 'split'); % Assumes file structure: animal/session/

% - General metadata
session.general.basePath =  basepath; % Full path
session.general.clusteringPath = basepath; % Full path to the clustered data (here assumed to be the basepath)
session.general.name = pathPieces{end}; % Session name
session.general.animal = pathPieces{end-1}; % Animal name

session.general.sex = 'Male'; % Male, Female, Unknown
session.general.species = 'Rat'; % Mouse, Rat, ... (http://buzsakilab.com/wp/species/)
session.general.strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
session.general.geneticLine = 'Wild type';

session.extracellular.probesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
session.extracellular.probesVerticalSpacing = 10; % (µm) Vertical spacing between sites.
session.extracellular.leastSignificantBit = 0.195; % (in µV) Intan = 0.195, Amplipex = 0.3815

session.spikeSorting.format{1} = 'Phy'; % Sorting data-format: Phy, Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
session.spikeSorting.method{1} = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus

% - Brain regions 
% Brain regions  must be defined as index-1. Can be specified on a channel or spike group basis (below example for CA1 across all channels)
% session.brainRegions.CA1.channels = 1:128; % Brain region assignment (Allan institute Acronyms: http://atlas.brain-map.org/atlas?atlas=1)

% - Channel tags
% Channel tags must be defined as index-1. Each tag is a fieldname with the
% channels or spike groups as subfields. Below examples shows 5 tags (Theta, Ripple, RippleNoise, Cortical, Bad)
% session.channelTags.Theta.channels = 64; % Theta channel
% session.channelTags.Ripple.channels = 64; % Ripple channel
% session.channelTags.Ripple.spikeGroups = 3; % Ripple spike group
% session.channelTags.RippleNoise.channels = 1; % Ripple Noise reference channel
% session.channelTags.Cortical.spikeGroups = 3; % Cortical spike groups
% session.channelTags.Bad.channels = 1; % Bad channels
% session.channelTags.Bad.spikeGroups = 1; % Bad spike groups (broken shanks)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading parameters from Buzcode and Neurosuite (skipped and dead channels)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);
session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file

% - Channel tags
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
        if isfield(session.channelTags,tagNames{iTag})
            session.channelTags.(tagNames{iTag}).channels = unique([session.channelTags.(tagNames{iTag}).channels,sessionInfo.channelTags.(tagNames{iTag})+1]);
        else
            session.channelTags.(tagNames{iTag}).channels = sessionInfo.channelTags.(tagNames{iTag})+1;
        end
    end
end


% - Brain regions
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

% - Skipped and dead channels
if importSkippedChannels || importSyncedChannels
    sessionInfo = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    
    % Removing dead channels by the skip parameter in the xml
    if importSkippedChannels
        order = [sessionInfo.AnatGrps.Channels];
        skip = find([sessionInfo.AnatGrps.Skip]);
        badChannels_skipped = order(skip)+1;
    else
        badChannels_skipped = [];
    end
    % Removing dead channels by comparing AnatGrps to SpkGrps in the xml
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
