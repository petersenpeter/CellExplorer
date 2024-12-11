function openephysDig = loadOpenEphysDigital(session, varargin)
% function to load digital inputs from Open Ephys and align the data properly
%
% INPUT
% session: session struct
% Optional inputs:
%   probeLetter: 'A' or 'B' for specific probe TTL data. If empty, tries ProbeA first, then legacy format
%
% OUTPUTS
% intanDig.on: on-state changes for each channel [in seconds]
% intanDig.off: off-state changes for each channel [in seconds]
%
% By Peter Petersen, Mingze Dou
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'probeLetter','',@ischar);
parse(p,varargin{:});
parameters = p.Results;

TTL_paths = {};
epochs_startTime = [];
ephys_t0 = [];

% Determine file format and set paths
for i = 1:numel(session.epochs)

    if ~isempty(parameters.probeLetter)
        % Specific probe requested
        TTL_path = fullfile(session.epochs{i}.name,'events',['Neuropix-PXI-100.Probe' parameters.probeLetter],'TTL');
        disp(['Checking TTL path for epoch ' num2str(i) ': ' fullfile(session.general.basePath, TTL_path)])
        if exist(fullfile(session.general.basePath, TTL_path), 'dir')
            TTL_paths{i} = TTL_path;
            isNewFormat = true;
            disp('Found TTL directory')
        else
            error(['TTL path not found for Probe' parameters.probeLetter ' in epoch ' num2str(i)]);
        end
    else
        % Try ProbeA format first, then legacy format
        probeA_path = fullfile(session.epochs{i}.name,'events','Neuropix-PXI-100.ProbeA','TTL');
        legacy_path = fullfile(session.epochs{i}.name,'events','Neuropix-PXI-100.0','TTL_1');

        if exist(fullfile(session.general.basePath, probeA_path), 'dir')
            TTL_paths{i} = probeA_path;
            isNewFormat = true;
        elseif exist(fullfile(session.general.basePath, legacy_path), 'dir')
            TTL_paths{i} = legacy_path;
            isNewFormat = false;
        else
            error(['No valid TTL path found for epoch ' num2str(i)]);
        end
    end

    % Set timestamp path based on format
    if isNewFormat
        probeStr = parameters.probeLetter;
        if isempty(probeStr)
            probeStr = 'A';
        end
        timestampPath = fullfile(session.general.basePath, session.epochs{i}.name, 'continuous', ...
            ['Neuropix-PXI-100.Probe' probeStr], 'timestamps.npy');
    else
        timestampPath = fullfile(session.general.basePath, session.epochs{i}.name, 'continuous', ...
            'Neuropix-PXI-100.1', 'timestamps.npy');
    end

    disp(['Checking timestamp path for epoch ' num2str(i) ': ' timestampPath])
    if exist(timestampPath, 'file')
        temp = readNPY(timestampPath);
        disp(['Found ' num2str(length(temp)) ' timestamps, first value: ' num2str(temp(1))])
    else
        disp('Timestamp file not found')
    end

    epochs_startTime(i) = session.epochs{i}.startTime;
    if isNewFormat
        ephys_t0(i) = double(temp(1));
        disp(['ephys_t0 for epoch ' num2str(i) ': ' num2str(ephys_t0(i))])
    else
        ephys_t0(i) = double(temp(1))/session.extracellular.sr;
        disp(['ephys_t0 for epoch ' num2str(i) ': ' num2str(ephys_t0(i))])
    end
end

% Initialize output structure
openephysDig = {};

% Load and process first epoch data
basePath = fullfile(session.general.basePath, TTL_paths{1});
ttlPath = fullfile(basePath,'timestamps.npy');
disp(['Checking TTL timestamps path: ' ttlPath])
if exist(ttlPath, 'file')
    timestamps = readNPY(ttlPath);
    disp(['Found ' num2str(length(timestamps)) ' TTL timestamps'])
else
    disp('TTL timestamp file not found')
end
if isNewFormat
    openephysDig.timestamps = epochs_startTime(1) + double(timestamps) - ephys_t0(1); % timestamps in second
else
    openephysDig.timestamps = epochs_startTime(1) + double(timestamps)/session.extracellular.sr - ephys_t0(1); % legacy format
end

% Check which format to use for first epoch
if exist(fullfile(basePath,'states.npy'), 'file')
    % New format files
    openephysDig.channel_states = readNPY(fullfile(basePath,'states.npy'));
    openephysDig.channels = readNPY(fullfile(basePath,'sample_numbers.npy'));
else
    % Legacy format files
    openephysDig.channel_states = readNPY(fullfile(basePath,'channel_states.npy'));
    openephysDig.channels = readNPY(fullfile(basePath,'channels.npy'));
end
openephysDig.full_words = readNPY(fullfile(basePath,'full_words.npy'));

openephysDig.on{1} = double(openephysDig.timestamps(openephysDig.channel_states == 1));
openephysDig.off{1} = double(openephysDig.timestamps(openephysDig.channel_states == -1));

% Process additional epochs if present
if length(TTL_paths) > 1
    openephysDig.nTimestampsPrFile(1) = numel(openephysDig.timestamps);
    openephysDig.nOnPrFile(1) = numel(openephysDig.on{1});
    openephysDig.nOffPrFile(1) = numel(openephysDig.off{1});
    
    for i = 2:length(TTL_paths)
        basePath = fullfile(session.general.basePath, TTL_paths{i});
        timestamps = readNPY(fullfile(basePath,'timestamps.npy'));
        
        if isNewFormat
            timestamps = epochs_startTime(i) + double(timestamps) - ephys_t0(i); % timestamps in second
        else
            timestamps = epochs_startTime(i) + double(timestamps)/session.extracellular.sr - ephys_t0(i); % legacy format
        end
        openephysDig.timestamps = [openephysDig.timestamps; timestamps];
        
        % Load states and channels based on format
        if exist(fullfile(basePath,'states.npy'), 'file')
            % New format files
            channel_states = readNPY(fullfile(basePath,'states.npy'));
            openephysDig.channel_states = [openephysDig.channel_states; channel_states];
            openephysDig.channels = [openephysDig.channels; readNPY(fullfile(basePath,'sample_numbers.npy'))];
        else
            % Legacy format files
            channel_states = readNPY(fullfile(basePath,'channel_states.npy'));
            openephysDig.channel_states = [openephysDig.channel_states; channel_states];
            openephysDig.channels = [openephysDig.channels; readNPY(fullfile(basePath,'channels.npy'))];
        end
        openephysDig.full_words = [openephysDig.full_words; readNPY(fullfile(basePath,'full_words.npy'))];
        openephysDig.on{1} = [openephysDig.on{1}; double(timestamps(channel_states == 1))];
        openephysDig.off{1} = [openephysDig.off{1}; double(timestamps(channel_states == -1))];
        openephysDig.nTimestampsPrFile(i) = numel(timestamps);
        openephysDig.nOnPrFile(i) = sum(channel_states == 1);
        openephysDig.nOffPrFile(i) = sum(channel_states == -1);
    end
end

% Attaching info about how the data was processed
openephysDig.processinginfo.function = 'loadOpenEphysDigital';
openephysDig.processinginfo.version = 1;
openephysDig.processinginfo.date = datetime('now');
openephysDig.processinginfo.params.basepath = session.general.basePath;
openephysDig.processinginfo.params.basename = session.general.name;
openephysDig.processinginfo.params.TTL_paths = TTL_paths;

try
    openephysDig.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    openephysDig.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end

% Saving data
saveStruct(openephysDig,'digitalseries','session',session);
end