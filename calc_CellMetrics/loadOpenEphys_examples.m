basepath = '/Volumes/DataDrive4/NeuropixelsData/PP01/PP01_2020-06-30_12-27-33';
basepath = '/Volumes/DataDrive4/NeuropixelsData/PP01/PP01_2020-07-09_13-22-13';
% basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-07-01_13-07-16';
basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-06-30_12-27-33';
basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-07-01_13-07-16';
basepath = 'Z:\SUN-IN-Petersen-lab\EphysData\PeterPetersen\PP01\PP01_2020-07-01_13-07-16';

basename = basenameFromBasepath(basepath);
cd(basepath)
session = loadSession(basepath,basename,'showGUI',true); % Loading session info

%% Detect open ephys data

session = preprocessOpenEphysData('session',session,'showGUI',true);

%% Load OpenEphys Settings File

session = loadOpenEphysSettingsFile(session);
saveStruct(session);

%% Load digital pulses
TTL_paths = {'TTL_2','TTL_4'};
TTL_offsets = [0,0];
openephysDig = loadOpenEphysDigital(session,TTL_paths,TTL_offsets);

%% Behavior processing
scaling_factor = 0.5;
offset_origin = [15,7.5,0];
offset_origin = [5,-5,0];

offset_rigid_body = [5,-5,0]; % Not implemented yet
circular_track = loadOptitrack('session',session,'dataName','circular_track','offset_origin',offset_origin,'scaling_factor',scaling_factor);

% linear_track = loadOptitrack('session',session,'dataName','linear_track','offset',offset,'scaling_factor',scaling_factor);

%% maze parameters
maze = {};
maze.type = 'theta';
maze.radius_in = 96.5/2;
maze.radius_out =  116.5/2;
maze.arm_half_width = 4;
maze.cross_radii = 47.9;
maze.rim_buffer = 10;
maze.polar_rho_limits = [44,75]; % 40,?
maze.polar_theta_limits = [15,2.8*maze.radius_in]; % In units of cm
maze.pos_x_limits = [-10,10]; % 
maze.pos_y_limits = [-40,44]; 

subplot(1,2,1)
plot_ThetaMaze(maze)

%% Align optitrack behavior data with TTL pulses

% Loading pulses
openephysDig = loadStruct('openephysDig','digitalseries','session',session);

%% Get trials from behavior

% Define the trials struct:
[trials,circular_track] = getTrials_thetamaze(circular_track,maze, 1);

%% Linearizing and defining boundaries

circular_track = linearize_theta_maze(circular_track,maze);

% Setting a minimum speed threshold
circular_track.speed_th = 10;

% Generating left_right states data
circular_track.states.left_right = nan(size(circular_track.trials));
for i = 1:trials.nTrials
    circular_track.states.left_right(circular_track.trials==i) = trials.states.left_right(i);
end
circular_track.stateNames.left_right = {'Left','Right'};

saveStruct(circular_track,'behavior','session',session);
saveStruct(trials,'behavior','session',session);

% After this you can load the generated files:
% circular_track = loadStruct('circular_track','behavior','session',session);
% trials = loadStruct('trials','behavior','session',session);

%% Kilosort ? 

