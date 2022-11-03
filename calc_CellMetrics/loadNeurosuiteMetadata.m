function session = loadNeurosuiteMetadata(session)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading channel group parameters from xml
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if exist(fullfile(session.general.basePath,[session.general.name, '.xml']),'file')
    if ~exist('LoadXml.m','file')
        error('''LoadXml.m'' and ''xmltools.m'' is not in your path and is required to load the xml file.')
    end
    sessionInfo = LoadXml(fullfile(session.general.basePath,[session.general.name, '.xml']));
    if isfield(sessionInfo,'AnatGrps')
        session.extracellular.nElectrodeGroups = size(sessionInfo.AnatGrps,2); % Number of electrode groups
        session.extracellular.electrodeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Electrode groups
        session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0); % Changing index from 0 to 1
    end
    
    if isfield(sessionInfo,'SpkGrps')
        session.extracellular.nSpikeGroups = length(sessionInfo.SpkGrps); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.SpkGrps.Channels}; % Spike groups
        session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0); % Changing index from 0 to 1
    elseif isfield(sessionInfo,'AnatGrps')
        warning('No spike groups exist in the xml. Anatomical groups used instead for spike groups')
        session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
        session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
        session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0); % Changing index from 0 to 1
    end
    
    session.extracellular.sr = sessionInfo.SampleRate; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.lfpSampleRate; % Sampling rate of lfp file
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
    disp(['Channel groups updated from ', session.general.name, '.xml'])
else
    disp('No xml file found in basepath.')
end