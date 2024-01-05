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
% Each path must contain:
% 1. timestamps.npy
% 2: channel_states.npy
% 3: channels.npy
% 4: full_words.npy

% TTL_paths = {'TTL_2','TTL_4'};
% TTL_offset = [0,1];

TTL_paths = {};
epochs_startTime = [];
ephys_t0 = [];

for i = 1:numel(session.epochs)
    TTL_paths{i} = fullfile(session.epochs{i}.name,'events','Neuropix-PXI-100.0','TTL_1');
    epochs_startTime(i) = session.epochs{i}.startTime;
    temp = readNPY(fullfile(session.general.basePath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','timestamps.npy'));
    ephys_t0(i) = double(temp(1))/session.extracellular.sr;
end

openephysDig = {};
openephysDig.timestamps = epochs_startTime(1) + double(readNPY(fullfile(session.general.basePath, TTL_paths{1},'timestamps.npy')))/session.extracellular.sr - ephys_t0(1);
openephysDig.channel_states = readNPY(fullfile(session.general.basePath,TTL_paths{1},'channel_states.npy'));
openephysDig.channels = readNPY(fullfile(session.general.basePath, TTL_paths{1},'channels.npy'));
openephysDig.full_words = readNPY(fullfile(session.general.basePath,TTL_paths{1},'full_words.npy'));
openephysDig.on{1} = double(openephysDig.timestamps(openephysDig.channel_states == 1));
openephysDig.off{1} = double(openephysDig.timestamps(openephysDig.channel_states == -1));

if length(TTL_paths) > 1
    openephysDig.nTimestampsPrFile(1) = numel(openephysDig.timestamps);
    openephysDig.nOnPrFile(1) = numel(openephysDig.on{1});
    openephysDig.nOffPrFile(1) = numel(openephysDig.off{1});
    for i = 2:length(TTL_paths)
        timestamps = epochs_startTime(i) + double(readNPY(fullfile(session.general.basePath, TTL_paths{i},'timestamps.npy')))/session.extracellular.sr - ephys_t0(i);
        openephysDig.timestamps = [openephysDig.timestamps; timestamps];
        
        channel_states = readNPY(fullfile(session.general.basePath,TTL_paths{i},'channel_states.npy'));
        openephysDig.channel_states = [openephysDig.channel_states; channel_states];
        
        openephysDig.channels = [openephysDig.channels;readNPY(fullfile(session.general.basePath, TTL_paths{1},'channels.npy'))];
        openephysDig.full_words = [openephysDig.full_words; readNPY(fullfile(session.general.basePath,TTL_paths{1},'full_words.npy'))];
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
