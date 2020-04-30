function session = sessionTemplate(input1,varargin)
% This script can be used to create a session struct (metadata structure for the CellExplorer)
% Load parameters from a Neurosuite xml file and buzcode sessionInfo file and any other parameters specified in this script.
% This script must be called from the basepath of your dataset, or be provided with a basepath as input
% Check the website of the CellExplorer for more details: https://petersenpeter.github.io/CellExplorer/
%
% - Example calls:
% session = sessionTemplate(session)    % Load session from session struct
% session = sessionTemplate(basepath)   % Load from basepath

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 21-3-2020

p = inputParser;
addRequired(p,'input1',@(X) (ischar(X) && exist(X,'dir')) || isstruct(X)); % specify a valid path or an existing session struct
addParameter(p,'importSkippedChannels',true,@islogical); % Import skipped channels from the xml as bad channels
addParameter(p,'importSyncedChannels',true,@islogical); % Import channel not synchronized between anatomical and spike groups as bad channels
addParameter(p,'noPrompts',true,@islogical); % Show the session gui if requested
addParameter(p,'showGUI',false,@islogical); % Show the session gui if requested

% Parsing inputs
parse(p,input1,varargin{:})
importSkippedChannels = p.Results.importSkippedChannels;
importSyncedChannels = p.Results.importSyncedChannels;
noPrompts = p.Results.noPrompts;
showGUI = p.Results.showGUI;

% Initializing session struct and defining basepath, if not specified as an input
if ischar(input1)
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
    disp('Loading existing basename.session.mat file')
    load(fullfile(basepath,[basename,'.session.mat']))
elseif ~exist('session','var')
    session = [];
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Standard parameters below. Please change accordingly to represent your session
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
pathPieces = regexp(basepath, filesep, 'split'); % Assumes file structure: animal/session/

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% General metadata
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
session.general.basePath =  basepath; % Full path
temp = dir('Kilosort_*');
if ~isempty(temp)
    session.general.clusteringPath = temp.name; % clusteringPath assumed from Kilosort
else
    session.general.clusteringPath = ''; % Full path to the clustered data (here assumed to be the basepath)
end
session.general.name = pathPieces{end}; % Session name
session.general.version = 5; % Metadata version
session.general.sessionType = 'Chronic'; % Type of recording: Chronic, Acute

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Limited animal metadata (practical information)
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if ~isfield(session,'animal')
    session.animal.name = pathPieces{end-1}; % Animal name 
    session.animal.sex = 'Male'; % Male, Female, Unknown
    session.animal.species = 'Rat'; % Mouse, Rat, ... (http://buzsakilab.com/wp/species/)
    session.animal.strain = 'Long Evans'; % (http://buzsakilab.com/wp/strains/)
    session.animal.geneticLine = 'Wild type';
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Extracellular
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if ~isfield(session,'extracellular') || (isfield(session,'extracellular') && (~isfield(session.extracellular,'leastSignificantBit')) || isempty(session.extracellular.leastSignificantBit)) 
    session.extracellular.leastSignificantBit = 0.195; % (in µV) Intan = 0.195, Amplipex = 0.3815
end
if ~isfield(session,'extracellular') || (isfield(session,'extracellular') && (~isfield(session.extracellular,'probeDepths')) || isempty(session.extracellular.probeDepths)) 
    session.extracellular.probeDepths = 0;
end
if ~isfield(session,'extracellular') || (isfield(session,'extracellular') && (~isfield(session.extracellular,'precision')) || isempty(session.extracellular.precision)) 
    session.extracellular.precision = 'int16';
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Spike sorting
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if ~isfield(session,'spikeSorting')
    session.spikeSorting{1}.format = 'Phy'; % Sorting data-format: Phy, Kilosort, Klustakwik, KlustaViewer, SpikingCircus, Neurosuite
    session.spikeSorting{1}.method = 'KiloSort'; % Sorting algorith: KiloSort, Klustakwik, MaskedKlustakwik, SpikingCircus
    session.spikeSorting{1}.relativePath = session.general.clusteringPath;
    session.spikeSorting{1}.channels = [];
    session.spikeSorting{1}.manuallyCurated = 1;
    session.spikeSorting{1}.notes = '';
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Brain regions 
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Brain regions  must be defined as index 1. Can be specified on a channel or spike group basis (below example for CA1 across all channels)
% session.brainRegions.CA1.channels = 1:128; % Brain region acronyms from Allan institute: http://atlas.brain-map.org/atlas?atlas=1)

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Channel tags
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Channel tags must be defined as index 1. Each tag is a fieldname with the channels or spike groups as subfields.
% Below examples shows 5 tags (Theta, Ripple, RippleNoise, Cortical, Bad)
% session.channelTags.Theta.channels = 64; % Theta channel
% session.channelTags.Ripple.channels = 64; % Ripple channel
% session.channelTags.RippleNoise.channels = 1; % Ripple Noise reference channel
% session.channelTags.Cortical.electrodeGroups = 3; % Cortical spike groups
% session.channelTags.Bad.channels = 1; % Bad channels
% session.channelTags.Bad.electrodeGroups = 1; % Bad spike groups (broken shanks)

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Analysis tags
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if ~isfield(session,'analysisTags') || (isfield(session,'analysisTags') && (~isfield(session.analysisTags,'probesLayout')) || isempty(session.analysisTags.probesLayout)) 
    session.analysisTags.probesLayout = 'staggered'; % Probe layout: linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5
    session.analysisTags.probesVerticalSpacing = 10; % (µm) Vertical spacing between sites.
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading parameters from sessionInfo and xml (including skipped and dead channels)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if exist(fullfile(session.general.basePath,[session.general.name,'.sessionInfo.mat']),'file')
    load(fullfile(session.general.basePath,[session.general.name,'.sessionInfo.mat']),'sessionInfo')
    % sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);
    if sessionInfo.spikeGroups.nGroups>0
        session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
        session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
    else
        warning('No spike groups exist in the xml. Anatomical groups used instead')
        session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
    end
    session.extracellular.nElectrodeGroups = size(sessionInfo.AnatGrps,2); % Number of electrode groups
    session.extracellular.electrodeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Electrode groups
    session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
    % Changing index from 0 to 1:
    session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0);
    session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0);
elseif exist('LoadXml.m','file') && exist(fullfile(session.general.basePath,[session.general.name, '.xml']),'file')
    sessionInfo = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    if isfield(sessionInfo,'SpkGrps')
        session.extracellular.nSpikeGroups = length(sessionInfo.SpkGrps); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.SpkGrps.Channels}; % Spike groups
    else
        warning('No spike groups exist in the xml. Anatomical groups used instead')
        session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
    end
    session.extracellular.nElectrodeGroups = size(sessionInfo.AnatGrps,2); % Number of electrode groups
    session.extracellular.electrodeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Electrode groups
    session.extracellular.sr = sessionInfo.SampleRate; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.lfpSampleRate; % Sampling rate of lfp file
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
    % Changing index from 0 to 1:
    session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0);
    session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0);
else
    warning('No sessionInfo.mat or xml file loaded')
    sessionInfo = [];
end

if (~isfield(session.general,'date') || isempty(session.general.date)) && isfield(sessionInfo,'Date')
    session.general.date = sessionInfo.Date;
end
if isfield(session,'extracellular') && isfield(session.extracellular,'nChannels')
    fullpath = fullfile(session.general.basePath,[session.general.name,'.dat']);
    if exist(fullpath,'file')
        temp2_ = dir(fullpath);
        session.extracellular.nSamples = temp2_.bytes/session.extracellular.nChannels/2;
        session.general.duration = session.extracellular.nSamples/session.extracellular.sr;
    end
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Importing channel tags
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
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

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Importing brain regions
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if isfield(sessionInfo,'region')
    load BrainRegions.mat
    regionNames = unique(cellfun(@num2str,sessionInfo.region,'uni',0));
    regionNames(cellfun('isempty',regionNames)) = [];
    for iRegion = 1:length(regionNames)
        if any(strcmp(regionNames{iRegion},BrainRegions(:,2)))
            session.brainRegions.(regionNames{iRegion}).channels = find(strcmp(regionNames{iRegion},sessionInfo.region));
        elseif strcmp(lower(regionNames{iRegion}),'hpc')
            session.brainRegions.HIP.channels = find(strcmp(regionNames{iRegion},sessionInfo.region));
        else
            disp(['Brain region does not exist in the Allen Brain Atlas: ' regionNames{iRegion}])
            regionName = regexprep(regionNames{iRegion}, {'[%() ]+', '_+$'}, {'_', ''});
            tagName = ['brainRegion_', regionName];
            if ~isfield(session,'channelTags') || all(~strcmp(tagName,fieldnames(session.channelTags)))
                disp(['Creating a channeltag with assigned channels: ' tagName])
                session.channelTags.(tagName).channels = find(strcmp(regionNames{iRegion},sessionInfo.region));
            end
        end
    end
end

% Epochs derived from MergePoints
if exist(fullfile(basepath,[session.general.name,'.MergePoints.events.mat']),'file')
    load(fullfile(basepath,[session.general.name,'.MergePoints.events.mat']),'MergePoints')
    for i = 1:size(MergePoints.foldernames,2)
        session.epochs{i}.name =  MergePoints.foldernames{i};
        session.epochs{i}.startTime =  MergePoints.timestamps(i,1);
        session.epochs{i}.stopTime =  MergePoints.timestamps(i,2);
    end
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Importing time series
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading info about time series from Intan metadatafile info.rhd
session = loadIntanMetadata(session);

% % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Importing skipped and dead channels
% % % % % % % % % % % % % % % % % % % % % % % % % % % %
if (importSkippedChannels || importSyncedChannels) && exist(fullfile(session.general.basePath,[session.general.name, '.xml']),'file')
    [sessionInfo, rxml] = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    
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
    % Importing notes
    try
    	if isfield(session.general,'notes')
            session.general.notes = [session.general.notes,'   Notes from xml: ',rxml.child(1).child(3).value,'   Description: ' rxml.child(1).child(4).value];
        else
            session.general.notes = ['Notes: ',rxml.child(1).child(3).value,'   Description from xml: ' rxml.child(1).child(4).value];
        end
    end
    % Importing experimenters
    try
    	if ~isfield(session.general,'experimenters') || isempty(session.general.experimenters)
            session.general.experimenters = rxml.child(1).child(2).value;
        end
    end
end

% Finally show GUI if requested by user
if ~noPrompts || showGUI
    session = gui_session(session);
end