basepath = '/Volumes/DataDrive4/NeuropixelsData/PP01/PP01_2020-06-30_12-27-33';
basepath = '/Volumes/DataDrive4/NeuropixelsData/PP01/PP01_2020-07-09_13-22-13';
% basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-07-01_13-07-16';

basename = basenameFromBasepath(basepath);
cd(basepath)
session = loadSession(basepath,basename,'showGUI',true); % Loading session info

%% Detect open ephys data

session = detectOpenEphysData('session',session);
session = gui_session(session);

%% Load OpenEphys Settings File

session = loadOpenEphysSettingsFile(session);
saveStruct(session);

%% Load digital pulses
TTL_paths = {'TTL_2','TTL_4'};
TTL_offsets = [0,0];
openephysDig = loadOpenEphysDigital(session,TTL_paths,TTL_offsets);


%% Behavior processing
scaling_factor = 1;
offset = [0,0,0];
linear_track = loadOptitrack('session',session,'dataName','linear_track','offset',offset,'scaling_factor',scaling_factor);

openephysDig = loadStruct('openephysDig','digitalseries','session',session);
%% Align optitrack behavior data with TTL pulses


%% Kilosort

