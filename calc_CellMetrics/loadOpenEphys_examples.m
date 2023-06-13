basepath = '/Path/To/Your/Data/basename';

basename = basenameFromBasepath(basepath);
cd(basepath)
session = loadSession(basepath,basename,'showGUI',true); % Loading session info

%% Detect open ephys data

session = preprocessOpenEphysData('session',session,'showGUI',true);

%% Load OpenEphys Settings File

session = loadOpenEphysSettingsFile(session);
saveStruct(session);

%% Load digital pulses

openephysDig = loadOpenEphysDigital(session);

%% Behavior processing
scaling_factor = 0.5;
offset_origin = [15,7.5,0];
offset_origin = [5,-5,0];

offset_rigid_body = [5,-5,0]; % Not implemented yet
circular_track = loadOptitrack('session',session,'dataName','circular_track','offset_origin',offset_origin,'scaling_factor',scaling_factor);

% linear_track = loadOptitrack('session',session,'dataName','linear_track','offset',offset,'scaling_factor',scaling_factor);
% circular_track = loadStruct('circular_track','behavior','session',session);

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
if exist('plot_ThetaMaze.m','file')
	plot_ThetaMaze(maze)
end

%% Align optitrack behavior data with TTL pulses

% Loading pulses
openephysDig = loadStruct('openephysDig','digitalseries','session',session);

if session.behavioralTracking{1}.epoch==1
    TTL_offset = 0;
else
    TTL_offset = sum(openephysDig.nOnPrFile(1:session.behavioralTracking{1}.epoch-1));    
end
circular_track.timestamps = openephysDig.on{1}([1:circular_track.nSamples]+TTL_offset);
circular_track.timestamps_reference = 'ephys';
saveStruct(circular_track,'behavior','session',session);

%% Get trials from behavior

% Define the trials struct:
circular_track = getTrials_thetamaze(circular_track,maze, 1);

%% Linearizing and defining boundaries

circular_track = linearize_theta_maze(circular_track,maze);

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

% After this you can load the generated files:
% circular_track = loadStruct('circular_track','behavior','session',session);

%% Plot spikes
spikes = loadSpikes('session',session);

% A figure for each unit showing the X,Y position of the spikes
for unit1 = 1:spikes.numcells
    spikes.position_x{unit1} = interp1(circular_track.timestamps,circular_track.position.x,spikes.times{unit1},'linear');
    spikes.position_y{unit1} = interp1(circular_track.timestamps,circular_track.position.y,spikes.times{unit1},'linear');
    
    figure
    plot(circular_track.position.x,circular_track.position.y,'-k'), hold on
    plot(spikes.position_x{unit1},spikes.position_y{unit1},'.r'), hold on
    plot_ThetaMaze(maze), title(['Unit ' num2str(unit1)]), xlabel('X'), ylabel('Y')
end

for unit1 = 1:spikes.numcells
    spikes.position_linearized{unit1} = interp1(circular_track.timestamps,circular_track.position.linearized,spikes.times{unit1},'linear');
    spikes.position_trials{unit1} = interp1(circular_track.timestamps,circular_track.trials.alternation.trials,spikes.times{unit1},'linear');
    
    figure
    plot(circular_track.position.linearized,circular_track.trials.alternation.trials,'.b'), hold on
    plot(spikes.position_linearized{unit1},spikes.position_trials{unit1},'.r','markersize',15), hold on
    title(['Unit ' num2str(unit1)]), xlabel('Linearized postion'), ylabel('Trials')
end

spikes.spindices = generateSpinDices(spikes.times);
figure, plot(spikes.spindices(:,1),spikes.spindices(:,2),'.')

for i = 1:circular_track.trials.alternation.nTrials
    trial1 = i;
    figure
    idx = circular_track.trials.alternation.trials == trial1;
    plot(circular_track.position.x(idx),circular_track.position.y(idx),'-k'), hold on
    for unit1 = 1:spikes.numcells
        idx2 = spikes.position_trials{unit1} == trial1;
        plot(spikes.position_x{unit1}(idx2),spikes.position_y{unit1}(idx2),'.'), hold on
    end
    title(['Trial ' num2str(trial1)]), xlabel('Linearized postion'), ylabel('Trials')
end

%% 4. Generate firingratemaps

% Generating the linearized firing rate map
ratemap = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'session',session,'x_label','Theta maze position (cm)','showPlots',true);

% Generating trial-wise firing rate map
ratemap_Trials = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.trials.alternation.trials,'dataName','ratemap_Trials','session',session,'x_label','Theta maze position (cm)','showPlots',true);

% Generating left-right firing rate map
ratemap_LeftRight = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.states.left_right,'stateNames',circular_track.stateNames.left_right,'dataName','ratemap_LeftRight','session',session,'x_label','Theta maze position (cm)','showPlots',true);
