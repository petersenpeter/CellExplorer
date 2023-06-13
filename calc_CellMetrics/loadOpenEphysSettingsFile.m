function session = loadOpenEphysSettingsFile(session,epoch)

% https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html

% Loading structure.oebin, with a json structure
file1 = fullfile(session.general.basePath,session.epochs{1}.name,'structure.oebin');
if exist(file1,'file')
    disp(['Loading Open Ephys settings: ', file1])
    text = fileread(file1);
    openEphys_metadata=jsondecode(text);

    % Importing metadata
    session.extracellular.sr = openEphys_metadata.continuous(1).sample_rate;
    session.extracellular.nChannels = openEphys_metadata.continuous(1).num_channels;
    session.extracellular.equipment = 'OpenEpys Neuropix-PXI';
    session.extracellular.leastSignificantBit = 0.195;
    session.extracellular.fileFormat = 'dat';
    session.extracellular.precision = 'int16';
    session.extracellular.fileName = '';
    session.extracellular.srLfp = openEphys_metadata.continuous(2).sample_rate;
    session.extracellular.electrodeGroups.channels{1} = 1:384;
    session.extracellular.nElectrodeGroups = 1;
    session.extracellular.spikeGroups.channels{1} = 1:384;
    session.extracellular.nSpikeGroups = 1;

    session.timeSeries.dig.fileName = [openEphys_metadata.events(1).folder_name,'timestamps.npy'];
    session.timeSeries.dig.fileFormat = 'npy';
    session.timeSeries.dig.precision  = openEphys_metadata.events(1).type;
    session.timeSeries.dig.nChannels = openEphys_metadata.events(1).num_channels;
    session.timeSeries.dig.sr = openEphys_metadata.events(1).sample_rate;
    session.timeSeries.dig.equipment = 'OpenEpys Neuropix-PXI';
    session.timeSeries.dig.nSamples = [];
    session.timeSeries.dig.leastSignificantBit = [];
else
    warning(['Failed to load Open Ephys settings: ', file1])
end