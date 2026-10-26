function chanCoords = generateChanCoords_Neuropixel1

% Channels coordinates chanCoords : Channels coordinates struct (probe layout) for Neuropixels 1.0
% (staggered, 70 µm wide single shank, 960 electrodes) with x and y position for each electrode,
% indexed by electrode number (1-indexed: electrode index + 1). Same fields as
% generateChanCoords_Neuropixel2.
%
% Geometry (as in SpikeGLX/SGLXMetaToCoords, np1_stag_70um): electrode e (0-indexed) sits in row
% floor(e/2) and column mod(e,2); x = column*32 + 27 µm on even rows and + 11 µm on odd rows;
% y = row*20 µm.

chanCoords = {};
chanCoords.source = 'generateChanCoords_Neuropixel1';
chanCoords.layout = 'staggered';
chanCoords.shankSpacing = 0; % µm, single shank
chanCoords.verticalSpacing = 20; % µm
chanCoords.horizontalSpacing = 32; % µm

electrodes = 0:959;
row = floor(electrodes/2);
col = mod(electrodes,2);
chanCoords.x = col*32 + 27*(mod(row,2)==0) + 11*(mod(row,2)==1);
chanCoords.y = row*20;
chanCoords.shank = ones(1,960);
chanCoords.channels = 1:960;
