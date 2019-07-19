function session = sessionTemplate(pathCurrent)
% Loading parameters if not using DB session struct. 
% Loading settings available from sessionInfo (Buzcode)
% This script must be called from the basepath of your dataset
session = [];
if nargin<1
    pathCurrent = pwd;
end
pathPieces = regexp(pathCurrent, filesep, 'split'); % Assumes file structure: animal/session/
session.general.basePath =  pathCurrent; % Full path
session.general.clusteringPath = pathCurrent; % Full path to the clustered data
session.general.name = pathPieces{end}; % Session name
session.general.animal = pathPieces{end-1}; % Name of animal

session.general.sex = 'Male'; % Male, Female, Unknown
session.general.species = 'Rat'; % Mouse, Rat, ... (http://buzsakilab.com/wp/species/)
session.general.strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
session.general.geneticLine = 'Wild type';

session.extracellular.probesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
session.extracellular.probesVerticalSpacing = 10; % (µm) Vertical spacing between sites.
session.extracellular.leastSignificantBit = 0.195; % (in uV) Intan = 0.195, Amplipex = 0.3815

session.spikeSorting.format{1} = 'Phy'; % Sorting data-format: Phy,Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
session.spikeSorting.method{1} = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus

% session.brainRegions.CA1.channels = 1:128; % Brain region assignment (Allan institute Acronyms: http://atlas.brain-map.org/atlas?atlas=1)

% session.channelTags.Theta.channels = 64; % Theta channel
% session.channelTags.Ripple.channels = 64; % Ripple channel
% session.channelTags.Ripple.spikeGroups = 3; % Ripple spike group
% session.channelTags.RippleNoise.channels = 1; % Ripple Noise reference channel
% session.channelTags.Cortical.spikeGroups = 3; % Cortical spike groups
% session.channelTags.Bad.channels = 1; % Bad channels
% session.channelTags.Bad.spikeGroups = 1; % Bad spike groups (broken shanks)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading parameters from sessionInfo (Buzcode)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);
session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
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
        if isfield(session.channelTags,tagNames{iTag})
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
