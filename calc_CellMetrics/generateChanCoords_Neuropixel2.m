function chanCoords = generateChanCoords_Neuropixel2

% Channels coordinates chanCoords : Channels coordinates struct (probe layout) 
% with x and y position for each recording channel saved to basename.chanCoords.channelinfo.mat 
% with the following fields:

% x : x position of each channel (in µm; [nChannels x 1]).
% y : y position of each channel (in µm; [nChannels x 1]).
% source : how the channel coordinates were generated
% layout : poly2 layout of the probe
% shankSpacing : spacing between each shank: 250µm
% channel : Channel list ([nChannels x 1]; optional), typically 384 or 385
% verticalSpacing : Vertical spacing between channels (in µm) This works as a simple 2D representation of recordings and will help you determine the location of your neurons. It is also used to determine the spike amplitude length constant of the spike waveforms across channels.

chanCoords = {};
chanCoords.source = 'generateChanCoords_Neuropixel2';
chanCoords.layout = 'poly2';
chanCoords.shankSpacing = 250; % µm
chanCoords.verticalSpacing = 15; % µm
chanCoords.horizontalSpacing = 32; % µm

chanCoords.x = [];
chanCoords.y = [];

% Shanks
for i = 1:4
    site_offset = (i-1)*1280;
    chanCoords.x(1+site_offset:2:1280 + site_offset) = 0+(i-1)*250;
    chanCoords.x(2+site_offset:2:1280 + site_offset) = chanCoords.horizontalSpacing+(i-1)*250;
    chanCoords.y(1+site_offset:2:1280 + site_offset) = 0:15:1280/2*15-15;
    chanCoords.y(2+site_offset:2:1280 + site_offset) = 0:15:1280/2*15-15;
    chanCoords.shank(1+site_offset:1280+site_offset) = i;
end
chanCoords.channels = 1:1280*4;

