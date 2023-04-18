% % % % % % % % % % % % % % % 
% Behavior pipeline tutorial
% Part of CellExplorer
% % % % % % % % % % % % % % % 

% Below is example code for generating the behavioral structs, firing rate maps and show them in CellExplorer

% The necessary steps are:
% 1. Get session info and spikes 
% 2. Import behavior data into the CellExplorer format
% 3. Get TTL pulses/global time
% 4. Define behavior struct with limits/boundaries/trials. Two examples
%   4.a: Linear track
%   4.b: Theta maze
% 5. Generate the firing rate maps
%   5.a: Linear track
%   5.b: Theta maze
% 6. Run CellExplorer Processing pipeline

%% 1. Load session info and spikes
basepath = pwd;
session = loadSession(basepath); % Loading session info

% Loading spikes struct
spikes = loadSpikes('session',session);

%% 0. Importing behavioral tracking from optitrack
% first we import the raw behavioral tracking into a Matlab struct:
% the optitrack output contains timestamps (from optitrack) and position data 
%    optitrack.timestamps      timestamps from optitrack [s]
%    optitrack.position.x      x-position [cm]
%    optitrack.position.y      y-position [cm]
%    optitrack.position.z      z-position [cm]
%    optitrack.speed           speed [cm/s]
%    optitrack.sr              samplingrate [Hz]

offset_origin = [5,-5,0]; % Any offset of origin [units: cm]
rotation = []; % Rotation of x,y [units: degrees]
scaling_factor = 1; % An scaling-factor to apply to the x,y,z data
optitrack = loadOptitrack('session',session,'offset_origin',offset_origin,'rotation',rotation,'scaling_factor',scaling_factor);

% After this you can load the generated file:
% optitrack = loadStruct('optitrack','behavior','session',session);

% After this you can load the generated mat file:
% optitrack = loadStruct('optitrack','behavior','session',session);

%% 3. Import TTL pulses from Intan used to synchronize the Intan ephys system with optitrack. 
% In this case, Intan works as the global clock.
% This will also save a struct with the digital input: basename.intanDig.digitalseries.mat
% The digital timeseries contains timestamps of changes in states
% intanDig.on      cell array with on state-changes channel-wise [sec]
% intanDig.off     cell array with off state-changes channel-wise [sec]

intanDig = loadIntanDigital(session);

% After this you can load the generated file:
% intanDig = loadStruct('intanDig','digitalseries','session',session);

%% 4. Define behavior struct with limits/boundaries/trials 
% 4.a Linear track

% Now, we can realign the temporal states and generate the new behavioral data struct 
OptitrackSync = session.inputs.OptitrackSync.channels; % TTL channel recorded by intan

% Extending the original behavioral data
lineartrack = optitrack;

% Defining timestamps via the TTL-pulses from Optitrack recorded with intan
lineartrack.timestamps = intanDig.on{OptitrackSync}(1:numel(lineartrack.timestamps));

% Plotting the result
figure, 
plot(lineartrack.position.x,lineartrack.position.y)

% % Getting trials
% Here we use the x-position as the linearized representation
lineartrack.position.linearized = lineartrack.position.x;

maze.pos_linearized_limits = [10,190];

lineartrack = getTrials_lineartrack(lineartrack,maze.pos_linearized_limits);

% Now we can save the struct
saveStruct(lineartrack,'behavior','session',session);

% After this you can load the generated file:
% lineartrack = loadStruct('lineartrack','behavior','session',session);

%% 4.b Circular track

% Now, we can realign the temporal states and generate the new behavioral data struct 
OptitrackSync = session.inputs.OptitrackSync.channels; % TTL channel recorded by intan

% Extending the original behavioral data
circular_track = optitrack;

% Next we define maze parameters:
% These are used for linearization and defining states on the maze (e.g. left/right)

% The circular maze with an arm along the center of the circle
% The animal has to run along the middle arm and return along one of the two side arms 
%     ___________
%    / ___   ___ \   
%   / /   | |   \ \  
%  / /    | |    \ \ 
% ( (     | |     ) )
%  \ \    | |    / / 
%   \ \___| |___/ /  
%    \_____*_____/   
%                    
% * start location   

maze = {};
maze.type = 'theta';            
maze.radius_in = 48.25;          % Inner radius of the ring (cm)
maze.radius_out =  58.25;        % Outer radius of the ring (cm)
maze.arm_half_width = 4;         % Half width of the arm going along the center of the circle (cm)
maze.cross_radii = 47.9;         % Radius along the vertical midline (cm)
maze.rim_buffer = 10;            % Extra buffer applied when assigning position along the maze (cm)
maze.polar_rho_limits = [44,75]; % Polar coordinate limits when assigning the animal subject to the ring (cm)
maze.polar_theta_limits = [15,2.8*maze.radius_in]; %  (cm)
maze.pos_x_limits = [-10,10];    % x-limits when assigning animal the the middle arm (cm)
maze.pos_y_limits = [-40,44];    % The y-limits when assigning animal the the middle arm (cm)

% Defining trials:
circular_track = getTrials_thetamaze(circular_track,maze);

% Linearizing and defining boundaries
circular_track = linearize_theta_maze(circular_track,maze);
circular_track.limits.linearized = [0,diff(maze.pos_y_limits) + diff(maze.polar_theta_limits)-5];
circular_track.boundaries.linearized = [0,diff(maze.pos_y_limits), diff(maze.pos_y_limits)+ abs(maze.polar_theta_limits(1))-5];
circular_track.boundaryNames.linearized = {'Central arm','Left side','Right side'};

% Setting a minimum speed threshold
circular_track.speed_th = 10;

% Generating left_right states data
circular_track.states.left_right = nan(size(circular_track.timestamps));
for i = 1:circular_track.trials.alternation.nTrials
    circular_track.states.left_right(circular_track.trials.alternation.trials==i) = circular_track.states.left_right(i);
end
circular_track.stateNames.left_right = {'Left','Right'};

% Saving behavioral data
saveStruct(circular_track,'behavior','session',session);

% After this you can load the generated file:
% circular_track = loadStruct('circular_track','behavior','session',session);


%% 5. Generate firingratemaps

% % % % % % % % % % % % % % % % % % % %
% 5.a Linear track
% Generating the linearized firing rate map
ratemap = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'session',session,'x_label','Linear track position (cm)');

% Generating trial-wise firing rate map
ratemap_Trials_ab = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.trials.ab.trials,'dataName','ratemap_Trials_ab','session',session,'x_label','Linear track position (cm)');
ratemap_Trials_ba = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.trials.ba.trials,'dataName','ratemap_Trials_ba','session',session,'x_label','Linear track position (cm)');

% Generating left-right firing rate map
ratemap_ab_ba = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.states.ab_ba,'stateNames',lineartrack.stateNames.ab_ba,'dataName','ratemap_ab_ba','session',session,'x_label','Linear track position (cm)');

% % % % % % % % % % % % % % % % % % % %
% 5.b Theta maze

% Generating the linearized firing rate map
ratemap = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'session',session,'x_label','Theta maze position (cm)');

% Generating trial-wise firing rate map
ratemap_Trials = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.trials.alternation.trials,'dataName','ratemap_Trials','session',session,'x_label','Theta maze position (cm)');

% Generating left-right firing rate map
ratemap_LeftRight = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.states.left_right,'stateNames',circular_track.stateNames.left_right,'dataName','ratemap_LeftRight','session',session,'x_label','Theta maze position (cm)');

%% 6. Run CellExplorer's Processing pipeline
% The Processing pipeline will detect and import the firing rate maps, detect place fields and calculate spatial information
%
% The firing rate maps are saved as cell arrays fields, e.g.
% cell_metrics.firingRateMaps.ratemap
%
% Metadata is saved to the .general field, e.g.
% cell_metrics.general.firingRateMaps.ratemap.x_bins
% cell_metrics.general.firingRateMaps.ratemap.boundaries

cell_metrics = ProcessCellMetrics('session',session);

cell_metrics = CellExplorer('metrics',cell_metrics);
