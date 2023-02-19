function data_out = loadIntanAnalog(varargin)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Loads analog intan files into CellExplorer data containers
% Part of CellExplorer
%
% Example calls:
% loadIntanAnalog('session',session,'dataName','temperature','data_source_type','adc','container_type','timeseries','processing','thermistor') % Loads temperature data from a thermistor
% wheel = loadIntanAnalog('session',session,'dataName','WheelPosition','data_source_type','adc','container_type','behavior','processing','wheel_position','downsample_samples',200); Loads wheel data

% By Peter Petersen
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Handling inputs
p = inputParser;
addParameter(p,'session',[],@isstruct);
addParameter(p,'dataName',[],@isstr);
addParameter(p,'container_type',[],@isstr);
addParameter(p,'data_source_type',[],@isstr);
addParameter(p,'channels',[],@isnumeric);

addParameter(p,'plot_on',[],@isnumeric);
addParameter(p,'down_sample',true,@islogical);
addParameter(p,'downsample_samples',16,@isnumeric);
addParameter(p,'processing','',@isstr); % Process signal, e.g.: thermistor, thermocouple, wheel_position

parse(p,varargin{:})
parameters = p.Results;

session = p.Results.session;
dataName = p.Results.dataName;
container_type = p.Results.container_type;
data_source_type = p.Results.data_source_type;
channels = p.Results.channels;
plot_on = p.Results.plot_on;
down_sample = p.Results.down_sample;
downsample_samples = p.Results.downsample_samples;
processing = p.Results.processing;

data_out = [];

% Loading metadata from session struct
basepath = session.general.basePath;
basename = session.general.name;
if isempty(data_source_type)
    data_source_type = session.inputs.(dataName).inputType;
end
if isempty(channels)
    channels = session.inputs.(dataName).channels;
end
nChannels = session.timeSeries.(data_source_type).nChannels;
sr = session.timeSeries.(data_source_type).sr;
leastSignificantBit = session.timeSeries.(data_source_type).leastSignificantBit/1000000;

% Determining filename
switch data_source_type
    case 'aux'
        if exist(fullfile(basepath,[basename,'_auxiliary.dat']))
            filename_full = fullfile(basepath,[basename,'_auxiliary.dat']);
        else
            filename_full = fullfile(basepath,'auxiliary.dat');
        end
%         leastSignificantBit = 0.0000374;
        sr = sr*4; % four identical samples is saved per sampling by intan in the aux traces
    case {'analog','adc'}
        if exist(fullfile(basepath,[basename,'_analogin.dat']))
            filename_full = fullfile(basepath,[basename,'_analogin.dat']);
        else
            filename_full = fullfile(basepath,'analogin.dat');
        end
%         leastSignificantBit = 0.000050354;
end

% Reading file
fileinfo = dir(filename_full);
num_samples = fileinfo.bytes/(nChannels * 2); % uint16 = 2 bytes
fid = fopen(filename_full, 'r');
trace = fread(fid, [nChannels, num_samples], 'uint16');
fclose(fid);

% Downsampling
if down_sample
    trace = medfilt1(trace(channels,:),downsample_samples*2);
    trace = mean(reshape(trace(1:end-rem(length(trace),downsample_samples)),downsample_samples,[]));
end

% Cleaning, translating, and smoothing signal
switch processing
    case 'thermocouple'
        disp('Processing thermocouple')
        trace = trace * leastSignificantBit; % convert to volts
        trace = (trace-1.25)/0.00495;
        trace(find(abs(diff(trace)) > 0.3)) = nan;
        trace(trace > 50 | trace < 0) = nan;
        trace = nanconv(trace,ce_gausswin(200)','edge');
        trace = fillmissing(trace,'linear');
        data_out.data = trace;
        data_out.sr = sr/downsample_samples;
        data_out.timestamps = [1:length(data_out.data)]/data_out.sr;
        figure,
        plot(data_out.timestamps,data_out.data,'-k')
        ylabel('Temperature'), xlabel('Time (s)'), axis tight
        
    case 'thermistor_10000'
        disp('Processing thermistor')
        thermistorT = trace * 0.000050354; % convert to volts
        thermistorT = 10000./(3.3./thermistorT-1); % potentiometer resistance is 10000 Ohm
        thermistorT = 1./(1/310.15 + 1/3454 * log(thermistorT/14015));
        trace = thermistorT - 273.15; % Translating from Kelvin to Celcius
        idx1 = find(diff(trace)<-5);
        idx2 = find(diff(trace)>5);
        idx1 = unique([idx1,idx1+1,idx1-1,idx1-2,idx1+2,idx2,idx2+1,idx2+2,idx2-1,idx2-2]); 
        trace(idx1) = nan;
        trace(trace > 50 | trace < 0) = nan;
        trace = nanconv(trace,ce_gausswin(200)','edge');
        trace = fillmissing(trace,'linear');
        data_out.data = trace;
        data_out.sr = sr/downsample_samples;
        data_out.timestamps = [1:length(data_out.data)]/data_out.sr;
        
        figure,
        plot(data_out.timestamps,data_out.data,'-k')
        ylabel('Temperature'), xlabel('Time (s)'), axis tight
    case 'thermistor_20210'
        disp('Processing thermistor')
        thermistorT = trace * 0.000050354; % convert to volts
%         thermistorT = 18010./(3.3./thermistorT-1); % potentiometer resistance is 20210 Ohm
        thermistorT = 20210./(3.3./thermistorT-1); % potentiometer resistance is 20210 Ohm
        thermistorT = 1./(1/310.15 + 1/3454 * log(thermistorT/14015));
        trace = thermistorT - 273.15; % Translating from Kelvin to Celcius
        idx1 = find(diff(trace)<-5);
        idx2 = find(diff(trace)>5);
        idx1 = unique([idx1,idx1+1,idx1-1,idx1-2,idx1+2,idx2,idx2+1,idx2+2,idx2-1,idx2-2]); 
        trace(idx1) = nan;
        trace(trace > 50 | trace < 0) = nan;
        trace = nanconv(trace,ce_gausswin(200)','edge');
        trace = fillmissing(trace,'linear');
        data_out.data = trace;
        data_out.sr = sr/downsample_samples;
        data_out.timestamps = [1:length(data_out.data)]/data_out.sr;
        
        figure,
        plot(data_out.timestamps,data_out.data,'-k')
        ylabel('Temperature'), xlabel('Time (s)'), axis tight
        
    case 'wheel_position'
        disp('Processing wheel position')
        % Translating into volts
        wheel_pos = trace * 0.000050354;
        
        % Extracting the polar position of the wheel
        data_out.position = 2*pi*(wheel_pos-min(wheel_pos))/(max(wheel_pos)-min(wheel_pos));
        data_out.units.position = 'radians';
        clear wheel_pos trace
        
        data_out.sr = sr/downsample_samples;
        data_out.timestamps = [1:length(data_out.position)]/data_out.sr;
        
        % Determing the volocity of the wheel 
        wheel_radius = 14.86; % Radius of the wheel in cm
        data_out.units.wheel_radius = 'cm';
        data_out.wheel_radius = wheel_radius;
        data_out.velocity = data_out.sr*wheel_radius*diff(unwrap(data_out.position));
        % Smoothing the velocity and adding a sample
        data_out.velocity = [nanconv(data_out.velocity,ce_gausswin(250)'/sum(ce_gausswin(250)),'edge'),0];
        data_out.units.velocity = 'cm/s';
        % Plotting wheel position and speed.
        figure,
        subplot(2,1,1)
        plot(data_out.timestamps,data_out.position,'.k')
        ylabel('Position (rad)'), title('Running wheel'), axis tight
        subplot(2,1,2); 
        plot(data_out.timestamps,data_out.velocity)
        ylabel('Velocity (cm/s)'), xlabel('Time (s)'), axis tight
    otherwise
        data_out.data = trace * leastSignificantBit; % convert to volts
        data_out.sr = sr/downsample_samples;
        data_out.timestamps = [1:length(data_out.data)]/data_out.sr;
end

% Attaching info about the data source and how the data was processed
data_out.processinginfo.function = 'loadIntanAnalog';
data_out.processinginfo.version = 2;
data_out.processinginfo.date = now;
data_out.processinginfo.params.basepath = basepath;
data_out.processinginfo.params.basename = basename;
data_out.processinginfo.params.filename_full = filename_full;
data_out.processinginfo.params.leastSignificantBit = leastSignificantBit;
data_out.processinginfo.params.data_source_type = data_source_type;
data_out.processinginfo.params.processing = processing;
data_out.processinginfo.params.down_sample = down_sample;
data_out.processinginfo.params.downsample_samples = downsample_samples;

try
    data_out.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    data_out.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
end

% Saving data
saveStruct(data_out,container_type,'session',session,'dataName',dataName);

% Plotting
if plot_on
    figure; plot(data_out.timestamps,data_out.data), axis tight, xlabel('Time'),ylabel(dataName)
end
