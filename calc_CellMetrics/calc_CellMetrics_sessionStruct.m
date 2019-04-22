% Loading parameters if not using DB session struct. 
% Loading settings available from sessionInfo (Buzcode)
session = [];

pathCurrent = pwd;
pathPieces = regexp(pathCurrent, filesep, 'split'); % Assumes file structure: animal/session/
session.general.basePath =  pathCurrent; % Full path
session.general.clusteringPath = pathCurrent; % Full path to the clustered data
session.general.name = pathPieces{end}; % Session name
session.general.animal = pathPieces{end-1}; % Name of animal

session.general.sex = 'Male'; % Male, Female, Unknown
session.general.species = 'Rat'; % Mouse, Rats, ... (http://buzsakilab.com/wp/species/)
session.general.strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
session.general.geneticLine = 'Wild type';

session.extracellular.probesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
session.extracellular.probesVerticalSpacing = 10; % (µm) Vertical spacing between sites

session.spikeSorting.format{1} = 'Phy'; % Sorting data-format: Phy,Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
session.spikeSorting.method{1} = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus

session.brainRegions.CA1.channels = 1:128; % Brain region assignment (Allan institute Acronyms: http://atlas.brain-map.org/atlas?atlas=1)

session.channelTags.Theta.channels = 64; % Theta channel
session.channelTags.Ripple.channels = 64; % Ripple channel
session.channelTags.Ripple.spikeGroups = 3; % Ripple spike group 
session.channelTags.RippleNoise.channels = 1; % Ripple Noise reference channel
session.channelTags.Cortical.spikeGroups = 3; % Cortical spike groups
session.channelTags.Bad.channels = 3; % Bad channels
session.channelTags.Bad.spikeGroups = 3; % Bad spike groups (broken shanks)

% Buzcode available parameters:
% session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
% session.extracellular.nGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
% session.extracellular.groups = sessionInfo.spikeGroups.Groups; % Number of spike groups
% session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
% session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
