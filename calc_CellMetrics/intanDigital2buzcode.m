function intanDig = intanDigital2buzcode(session)
% function gives out the digital inputs as raw datapoints.
% Documentation for Intantech data file formats: http://intantech.com/files/Intan_RHD2000_data_file_formats.pdf
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

if exist(fullfile(session.general.basePath,session.timeSeries.dig.fileName))
    filename_full = fullfile(session.general.basePath,session.timeSeries.dig.fileName);
elseif exist(fullfile(session.general.basePath,[session.general.baseName,'_digitalin.dat']))
    filename_full = fullfile(session.general.basePath,[session.general.baseName,'_digitalin.dat']);
elseif exist(fullfile(session.general.basePath,'digitalin.dat'))
    filename_full = fullfile(session.general.basePath,'digitalin.dat');
else
    error(['Intan Digital file was not found'])
end
if isfield(session.timeSeries.dig,'sr')
    sr = session.timeSeries.dig.sr;
elseif isfield(session.timeSeries.dig,'sr')
    sr = session.extracellular.sr;
end

disp(['Loading digital channels: ' filename_full])
m = memmapfile(filename_full,'Format','uint16','writable',false);
% digital_word2 = double(m.Data);
% digital_data = m.Data;
% clear m

if isfield(session.timeSeries.dig,'nChannels')
    nChannels = session.timeSeries.dig.nChannels;
else
    nChannels = 16; % Default max channel for the format
end
nChannels2 = nChannels+1;
disp(['Reading out digital channels (nChannels=', num2str(nChannels),')'])

% digital_output_ch = (bitand(digital_word, 2^ch) > 0); % ch has a value of 0-15 here
binaryData = [];
for k = 1:nChannels
    binaryData = bitget(m.Data,k);
    bitChange = diff(int16(binaryData));
    intanDig.on{k} = find(bitChange == 1)/sr;
    intanDig.off{k} = find(bitChange == -1)/sr;
end

% Attaching info about how the data was processed
intanDig.processinginfo.function = 'intanDigital2buzcode';
intanDig.processinginfo.version = 1;
intanDig.processinginfo.date = now;
intanDig.processinginfo.params.basepath = session.general.basePath;
intanDig.processinginfo.params.basename = session.general.baseName;
intanDig.processinginfo.params.filename_full = filename_full;

try
    intanDig.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    intanDig.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end

% Saving data
disp('Saving digital channels')
saveStruct(intanDig,'digitalseries','session',session);
