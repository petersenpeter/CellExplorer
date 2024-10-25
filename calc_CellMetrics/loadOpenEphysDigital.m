function openephysDig = loadOpenEphysDigital(session)
% function to load digital inputs from Open Ephys and align the data properly
%
% INPUT
% session: session struct
%
% OUTPUTS
% intanDig.on: on-state changes for each channel [in seconds]
% intanDig.off: off-state changes for each channel [in seconds]
%
% By Peter Petersen
% petersen.peter@gmail.com


% Load TTL data
% Each path must contain either:
% Legacy format:
%   1. timestamps.npy
%   2. channel_states.npy
%   3. channels.npy
%   4. full_words.npy
% New format:
%   1. timestamps.npy
%   2. states.npy
%   3. sample_numbers.npy
%   4. full_words.npy

TTL_paths = {};
epochs_startTime = [];
ephys_t0 = [];

% Determine file format and set paths
for i = 1:numel(session.epochs)
    % Try new format path first
    newFormatPath = fullfile(session.epochs{i}.name,'events','Neuropix-PXI-100.ProbeA','TTL');
    legacyFormatPath = fullfile(session.epochs{i}.name,'events','Neuropix-PXI-100.0','TTL_1');
    
    % Check which path exists and set accordingly
    if exist(fullfile(session.general.basePath, newFormatPath), 'dir')
        TTL_paths{i} = newFormatPath;
        timestampPath = fullfile(session.general.basePath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.ProbeA','timestamps.npy');
        isNewFormat = true;  %format flag
    else
        TTL_paths{i} = legacyFormatPath;
        timestampPath = fullfile(session.general.basePath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','timestamps.npy');
        isNewFormat = false;  
    end
    
    epochs_startTime(i) = session.epochs{i}.startTime;
    temp = readNPY(timestampPath);
    if isNewFormat
        ephys_t0(i) = double(temp(1));  % timestamps in second according to new format of open ephys
    else
        ephys_t0(i) = double(temp(1))/session.extracellular.sr;  
    end
end

% Initialize output structure
openephysDig = {};

% Load and process first epoch data
basePath = fullfile(session.general.basePath, TTL_paths{1});
timestamps = readNPY(fullfile(basePath,'timestamps.npy'));
if isNewFormat
    openephysDig.timestamps = epochs_startTime(1) + double(timestamps) - ephys_t0(1);  % timestamps in second
else
    openephysDig.timestamps = epochs_startTime(1) + double(timestamps)/session.extracellular.sr - ephys_t0(1);  % Legacy format
end

% Check which format to use for first epoch
if exist(fullfile(basePath,'states.npy'), 'file')
    openephysDig.channel_states = readNPY(fullfile(basePath,'states.npy'));
    openephysDig.channels = readNPY(fullfile(basePath,'sample_numbers.npy'));
    openephysDig.full_words = readNPY(fullfile(basePath,'full_words.npy'));
else
    openephysDig.channel_states = readNPY(fullfile(basePath,'channel_states.npy'));
    openephysDig.channels = readNPY(fullfile(basePath,'channels.npy'));
    openephysDig.full_words = readNPY(fullfile(basePath,'full_words.npy'));
end

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
            timestamps = epochs_startTime(i) + double(timestamps) - ephys_t0(i);  % timestamps in second
        else
            timestamps = epochs_startTime(i) + double(timestamps)/session.extracellular.sr - ephys_t0(i);  % Legacy format
        end
        openephysDig.timestamps = [openephysDig.timestamps; timestamps];
        
        % Load states and channels based on format
        if exist(fullfile(basePath,'states.npy'), 'file')
            channel_states = readNPY(fullfile(basePath,'states.npy'));
            openephysDig.channel_states = [openephysDig.channel_states; channel_states];
            openephysDig.channels = [openephysDig.channels; readNPY(fullfile(basePath,'sample_numbers.npy'))];
        else
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
