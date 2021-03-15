% Examples of manually creating a chanCoords structure
% Channel coordinates are the x and y position of the electrodes in one or more probes.
% This script shows how a channel coordinates can be defined manually. To generate the map automatically use the script generateChannelMap
% The manually defined chanCoords are saved to the +ChanCoords folder with CellExplorer. You can push your own designs to the CellExplorer GitHub repository.
% The mat files are saved with the following convention: [chanCoords.probe].probes.chanCoords.channelInfo.mat

% By Peter Petersen

% % % % % % % % % % % % % % % % % % % % % % 
% CambridgeNeurotech P128-5, 128 channel, 4 shank poly 3 layout with a cortical channel on each shank
% % % % % % % % % % % % % % % % % % % % % % 

% % % % % % % % % % % % % % % % % % % % % % 
% Defining probe properties
clear chanCoords
chanCoords.probe = 'P128-5'; % Probe name (must be unique)
chanCoords.source = 'Manually entered';
chanCoords.layout = 'poly 3';
chanCoords.nShanks = 4;
chanCoords.nChannels = 128; 
chanCoords.shankSpacing = 150; % in um
chanCoords.verticalSpacing = 30; % in um
chanCoords.horizontalSpacing = 18.5; % in um


% % % % % % % % % % % % % % % % % % % % % % 
% Generating map
chanCoords.x = nan(1,chanCoords.nChannels);
chanCoords.y = nan(1,chanCoords.nChannels);

shankSpacing = chanCoords.shankSpacing;
verticalSpacing = chanCoords.verticalSpacing;
horizontalSpacing = chanCoords.horizontalSpacing;

% The layput is generated in the same way for each shank
for i = 1:chanCoords.nShanks
    % 1. line of channel (poly3 layout)
    channels = [13 14 15 12 11 10 9 8 7 6]+1  +  32*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:numel(channels)-1);
    
    % 2. line of channel (poly3 layout)
    channels = [31 1 2 3 4 5 30 29 28 27 26]+1 + 32*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+horizontalSpacing+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:10)-verticalSpacing/2;
    
    % 3. line of channel (poly3 layout)
    channels = [18 17 16 19 20 21 22 23 24 25]+1  +  32*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+2*horizontalSpacing+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:numel(channels)-1);
end

% Defining the upper channels separately ("Cortical channels")
channels = [0 32 64 96]+1;
chanCoords.x(channels) = shankSpacing*(0:numel(channels)-1)+verticalSpacing;
chanCoords.y(channels) = [1200 1000 800 600];


%% % % % % % % % % % % % % % % % % % % % % % 
% Plotting and saving channel coordinates
% % % % % % % % % % % % % % % % % % % % % % 
x_range = range(chanCoords.x);
y_range = range(chanCoords.y);
if x_range > y_range
    fig_width = 1600;
    fig_height = ceil(fig_width*y_range/x_range)+200;
else
    fig_height = 1000;
    fig_width = ceil(fig_height*x_range/y_range)+200;
end
fig1 = figure('Name',['Channel map: ' chanCoords.probe ],'position',[5,5,fig_width,fig_height]); movegui(fig1,'center')
plot(chanCoords.x,chanCoords.y,'.k'), hold on
text(chanCoords.x,chanCoords.y,num2str([1:numel(chanCoords.y)]'),'VerticalAlignment', 'bottom','HorizontalAlignment','center');
title({' ','Channel map',' '}), xlabel('X (um)'), ylabel('Y (um)'),


% % % % % % % % % % % % % % % % % % % % % % 
% Adding processing info
chanCoords.processinginfo.function = 'ProcessCellMetrics';
chanCoords.processinginfo.date = now;
try
    chanCoords.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    chanCoords.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end


% % % % % % % % % % % % % % % % % % % % % % 
% Saving chanCoords to probeName.probes.chanCoords.channelInfo.mat
[CellExplorer_path,~,~] = fileparts(which('CellExplorer.m'));
save(fullfile(CellExplorer_path,'+ChanCoords',[chanCoords.probe,'.probes.chanCoords.channelInfo.mat']),'chanCoords');

%% % % % % % % % % % % % % % % % % % % % % % % 
% 2nd example: NeuroNexus Buzsaki A4x16_poly3_6mm20s_200_160 (64 ch, 4 shanks, poly 3  Custom)
% % % % % % % % % % % % % % % % % % % % % % 
clear chanCoords
chanCoords.probe = 'Buzsaki A4x16_poly3_6mm20s_200_160';
chanCoords.source = 'Manually entered';
chanCoords.layout = 'poly 3';
chanCoords.nShanks = 4;
chanCoords.nChannels = 64;
chanCoords.shankSpacing = 200; % in um
chanCoords.verticalSpacing = 20; % in um
chanCoords.horizontalSpacing = 17.32; % in um

% % % % % % % % % % % % % % % % % % % % % % 
% Generating map
chanCoords.x = nan(1,chanCoords.nChannels);
chanCoords.y = nan(1,chanCoords.nChannels);

shankSpacing = chanCoords.shankSpacing;
verticalSpacing = chanCoords.verticalSpacing;
horizontalSpacing = chanCoords.horizontalSpacing;

% The layput is generated in the same way for each shank
for i = 1:chanCoords.nShanks
    % 1. line of channel (poly3 layout)
    channels = [13 14 15 12 11 10 9 8 7 6]  +  16*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:numel(channels)-1);
    
    % 2. line of channel (poly3 layout)
    channels = [31 1 2 3 4 5 30 29 28 27 26] + 16*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+horizontalSpacing+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:10)-verticalSpacing/2;
    
    % 3. line of channel (poly3 layout)
    channels = [18 17 16 19 20 21 22 23 24 25]  +  16*(i-1);
    chanCoords.x(channels) = zeros(numel(channels),1)+2*horizontalSpacing+shankSpacing*(i-1);
    chanCoords.y(channels) = -verticalSpacing*(0:numel(channels)-1);
end
