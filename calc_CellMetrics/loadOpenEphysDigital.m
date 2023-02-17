function openephysDig = loadOpenEphysDigital(session,TTL_paths)
% function to load digital inputs from Open Ephys
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
% 1. timestamps.npy and 
% 2: channel_states.npy
% 3: channels.npy
% 4: full_words.npy

% TTL_paths = {'TTL_2','TTL_4'};
% TTL_offset = double(readNPY(fullfile(TTL_path,'experiment2\recording1\continuous\Neuropix-PXI-100.0\timestamps.npy')))/session.extracellular.sr;

openephysDig = {};
openephysDig.timestamps = readNPY(fullfile(session.general.basePath, TTL_paths{1},'timestamps.npy'));
openephysDig.channel_states = readNPY(fullfile(session.general.basePath,TTL_paths{1},'channel_states.npy'));
openephysDig.channels = readNPY(fullfile(session.general.basePath, TTL_paths{1},'channels.npy'));
openephysDig.full_words = readNPY(fullfile(session.general.basePath,TTL_paths{1},'full_words.npy'));
openephysDig.on{1} = double(openephysDig.timestamps(openephysDig.channel_states == 1))/session.extracellular.sr;
openephysDig.off{1} = double(openephysDig.timestamps(openephysDig.channel_states == -1))/session.extracellular.sr;

if length(TTL_paths) > 1
    openephysDig.nTimestampsPrFile(1) = numel(openephysDig.timestamps);
    
    for i = 2:length(TTL_paths)
        openephysDig.timestamps = [openephysDig.timestamps; readNPY(fullfile(session.general.basePath, TTL_paths{i},'timestamps.npy'))];
        openephysDig.channel_states = [openephysDig.channel_states; readNPY(fullfile(session.general.basePath,TTL_paths{i},'channel_states.npy'))];
        openephysDig.channels = [openephysDig.channels;readNPY(fullfile(session.general.basePath, TTL_paths{1},'channels.npy'))];
        openephysDig.full_words = [openephysDig.full_words; readNPY(fullfile(session.general.basePath,TTL_paths{1},'full_words.npy'))];
        openephysDig.on{1} = [openephysDig.on{1}; double(openephysDig.timestamps(openephysDig.channel_states == 1))/session.extracellular.sr];
        openephysDig.off{1} = [openephysDig.off{1}; double(openephysDig.timestamps(openephysDig.channel_states == -1))/session.extracellular.sr];
        openephysDig.nTimestampsPrFile(i) = numel(openephysDig.timestamps)-openephysDig.nTimestampsPrFile(i-1);
    end
end

% Attaching info about how the data was processed
openephysDig.processinginfo.function = 'loadOpenEphysDigital';
openephysDig.processinginfo.version = 1;
openephysDig.processinginfo.date = now;
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
