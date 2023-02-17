basepath = 'Z:\Homes\peterp03\IntanData\MS22\Peter_MS22_180626_110916_concat';
cd(basepath)
session = loadSession(basepath); % Loading session info

%% Detect open ephys data
% Coming...
% session = detectOpenEphysData('session',session)

%% Load digital pulses
TTL_paths = {'TTL_2','TTL_4'};
openephysDig = loadOpenEphysDigital(session,TTL_paths);
