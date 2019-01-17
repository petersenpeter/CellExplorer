% Loading parameters if not using DB session struct. 
% Loading settings available from sessionInfo (Buzcode)
session = [];

pathCurrent = pwd;
pathPieces = regexp(pathCurrent, filesep, 'split'); % Assumes file structure: animal/session/
session.General.BasePath =  pathCurrent; % Full path
session.General.ClusteringPath = pathCurrent; % Full path to the clustered data
session.General.Name = pathPieces{end}; % Session name
session.General.Animal = pathPieces{end-1}; % Name of animal

session.General.Sex = 'Male'; % Male, Female, Unknown
session.General.Species = 'Rat'; % Mouse, Rats, ... (http://buzsakilab.com/wp/species/)
session.General.Strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
session.General.GeneticLine = 'Wild type';

session.Extracellular.ProbesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
session.Extracellular.ProbesVerticalSpacing = 10; % (µm) Vertical spacing between sites

session.SpikeSorting.Format{1} = 'Phy'; % Sorting data-format: Phy,Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
session.SpikeSorting.Method{1} = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus

session.BrainRegions.CA1.Channels = 1:128; % Brain region assignment (Allan institute Acronyms: http://atlas.brain-map.org/atlas?atlas=1)

session.ChannelTags.Theta.Channels = 64; % Theta channel
session.ChannelTags.Ripple.Channels = 64; % Ripple channel
session.ChannelTags.Ripple.SpikeGroups = 3; % Ripple spike group
session.ChannelTags.RippleNoise.Channels = 1; % Ripple Noise reference channel
session.ChannelTags.Cortical.SpikeGroups = 3; % Cortical spike groups
session.ChannelTags.Bad.Channels = 3; % Bad channels (floating channels)
session.ChannelTags.Bad.SpikeGroups = 3; % Bad spike groups (broken shanks)

% Buzcode available parameters:
% session.Extracellular.nChannels = sessionInfo.nChannels; % Number of channels
% session.Extracellular.nGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
% session.Extracellular.Groups = sessionInfo.spikeGroups.Groups; % Number of spike groups
% session.Extracellular.Sr = sessionInfo.rates.wideband; % Sampling rate of dat file
% session.Extracellular.SrLFP = sessionInfo.rates.lfp; % Sampling rate of lfp file
