function session = import_xml2session(xml_file,session)
% Imports channel groups from .xml file to sesssion struct

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 16-03-2020

if nargin<2
    session = [];
end
if isempty(xml_file)
    xml_file = fullfile(session.general.basePath,[session.general.name,'.xml']);
end
if ~exist(xml_file,'file')
    return
end
sessionInfo = LoadXml(xml_file);

if isfield(sessionInfo,'SpkGrps')
    session.extracellular.nSpikeGroups = length(sessionInfo.SpkGrps); % Number of spike groups
    session.extracellular.spikeGroups.channels = {sessionInfo.SpkGrps.Channels}; % Spike groups
else
    disp('No spike groups exist in the xml. Anatomical groups used instead')
    session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
    session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
end
session.extracellular.nElectrodeGroups = size(sessionInfo.AnatGrps,2); % Number of electrode groups
session.extracellular.electrodeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Electrode groups

% Changing index from 0 to 1:
session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0);
session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0);

% Importing channel counts and sampling rates
session.extracellular.sr = sessionInfo.SampleRate; % Sampling rate of dat file
session.extracellular.srLfp = sessionInfo.lfpSampleRate; % Sampling rate of lfp file
session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels

end
