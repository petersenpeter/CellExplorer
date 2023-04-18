---
layout: default
title: Behavior pipeline tutorial
parent: Tutorials
nav_order: 8
---
# Behavior pipeline tutorial
{: .no_toc}

This tutorial covers how to generate the behavioral structs, firing rate maps, and show them in CellExplorer. The tutorial is also available as a Matlab script: [behavioral_data_Tutorial](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/behavioral_data_Tutorial.m).

__The steps are:__
1. Get session info and spikes 
2. Import behavior data into CellExplorer/Buzcode data container/format
3. Get TTL pulses/global time
4. Define behavior struct with limits/boundaries/trials. Two examples:
   4. Linear track: Animal runs from one end to the other, and back on a straight line.
   4. Theta maze: a circular maze with arm connecting the two rims, going along the center of the circle. Animal runs along the arm and then back along one of the two side arm (on the rim).
5. Generate the firing rate maps
6. Run CellExplorer Processing pipeline

## 1. Get session info and spikes

Load session info and spikes:

```m
basepath = pwd;
session = loadSession(basepath); % Loading session info
```

Loading spikes struct:
```m
spikes = loadSpikes('session',session);
```

## 2. Importing behavioral tracking from optitrack

First we import the raw behavioral tracking into a Matlab struct:
the optitrack output contains timestamps (from optitrack) and position data 

* `optitrack.timestamps`:      timestamps from optitrack
* `optitrack.position.x`:      x-position
* `optitrack.position.y`:      y-position
* `optitrack.position.z`:      z-position
* `optitrack.speed`:           speed
* `optitrack.sr`:              sampling rate

```m
offset_origin = [5,-5,0]; % Any offset of origin [units: cm]
rotation = []; % Rotation of x,y [units: degrees]
scaling_factor = 1; % An scaling-factor to apply to the x,y,z data
optitrack = loadOptitrack('session',session,'offset_origin',offset_origin,'rotation',rotation,'scaling_factor',scaling_factor);

% After this you can load the generated file:
% optitrack = loadStruct('optitrack','behavior','session',session);
```

Import TTL pulses from Intan used to synchronize the Intan ephys system with optitrack. 

In this case, Intan works as the global clock. This will also save a struct with the digital input: `basename.intanDig.digitalseries.mat`.

The digital timeseries contains timestamps of changes in states:
`intanDig.on`:      cell array with on state-changes channel-wise
`intanDig.off`:     cell array with off state-changes channel-wise

```m
intanDig = loadIntanDigital(session);

% After this you can load the generated file:
% intanDig = loadStruct('intanDig','digitalseries','session',session);
```

## 4. Define behavior struct with limits/boundaries/trials 

### 4.a Linear track

Now, we can realign the temporal states and generate the new behavioral data struct 
```m
OptitrackSync = session.inputs.OptitrackSync.channels; % TTL channel recorded by intan
```
Extending the original behavioral data
```m
lineartrack = optitrack;
```
Defining timestamps via the TTL-pulses from Optitrack recorded with intan
```m
lineartrack.timestamps = intanDig.on{OptitrackSync}(1:numel(lineartrack.timestamps));
```

Plotting the result
```m
figure, 
plot(lineartrack.position.x,lineartrack.position.y)
```

Getting trials via definition of limits. Here we use the x-position as the linearized representation
```m
lineartrack.position.linearized = lineartrack.position.x;
maze.pos_linearized_limits = [10,190];
lineartrack = getTrials_lineartrack(lineartrack,maze.pos_linearized_limits);
```

Now we can save the struct
```m
saveStruct(lineartrack,'behavior','session',session);

% After this you can load the generated file in Matlab:
% lineartrack = loadStruct('lineartrack','behavior','session',session);
```

### 4.b Circular track

Now, we can realign the temporal states and generate the new behavioral data struct 

```m
OptitrackSync = session.inputs.OptitrackSync.channels; % TTL channel recorded by intan
```

Extend the original behavioral data
```m
circular_track = optitrack;
```

Define timestamps via the TTL-pulses from Optitrack recorded with intan:
```m
circular_track.timestamps = intanDig.on{OptitrackSync}(1:numel(circular_track.timestamps));
circular_track.timestamps = circular_track.timestamps(:)';
```

Next we define maze parameters. These parameters are used for the linearization and to define states on the maze (e.g. left/right arm)
```m
maze.type = 'theta';
maze.radius_in = 96.5/2;
maze.radius_out =  116.5/2;
maze.arm_half_width = 4;
maze.cross_radii = 47.9;
maze.polar_rho_limits = [44,65];
maze.polar_theta_limits = [-2.8,2.8]*maze.radius_in;
maze.pos_x_limits = [-10,10]; % -15
maze.pos_y_limits = [-40,45];

maze.boundary{1} = [0,40]; % Central arm y-position boundaries
maze.boundary{2} = [0,25];
maze.boundary{3} = [-15,40]; 
maze.boundary{4} = [15,40];
maze.boundary{5} = [maze.radius_in-3.25,maze.polar_theta_limits(2)];
```

Getting trials:
```m
circular_track = getTrials_thetamaze(circular_track,maze);

% Circular position
circular_track.states.arm_rim = nan(1,circular_track.nSamples);
circular_track.states.arm_rim(circular_track.position.x > maze.pos_x_limits(1) & circular_track.position.x < maze.pos_x_limits(2) & circular_track.position.y > maze.pos_y_limits(1) & circular_track.position.y < maze.pos_y_limits(2)) = 1;
circular_track.states.arm_rim(circular_track.position.polar_rho > maze.polar_rho_limits(1) & circular_track.position.polar_rho < maze.polar_rho_limits(2) & circular_track.position.polar_theta > maze.polar_theta_limits(1) & circular_track.position.polar_theta < maze.polar_theta_limits(2)) = 2;
circular_track.stateNames.arm_rim = {'arm','rim'};
```

Linearize and defining boundaries
```m
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
```

Save the behavioral data
```m
saveStruct(circular_track,'behavior','session',session);

% After this you can load the generated files:
% circular_track = loadStruct('circular_track','behavior','session',session);
```

## 5. Generate firingratemaps

### 5.a Linear track

Generating the linearized firing rate map
```m
ratemap = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'session',session,'x_label','Linear track position (cm)');
```

Generating trial-wise firing rate map
```m
ratemap_Trials_ab = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.trials.ab.trials,'dataName','ratemap_Trials_ab','session',session,'x_label','Linear track position (cm)');
ratemap_Trials_ba = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.trials.ba.trials,'dataName','ratemap_Trials_ba','session',session,'x_label','Linear track position (cm)');
```

Generating left-right firing rate map
```m
ratemap_ab_ba = generate_FiringRateMap_1D('spikes',spikes,'behavior',lineartrack,'states',lineartrack.states.ab_ba,'stateNames',lineartrack.stateNames.ab_ba,'dataName','ratemap_ab_ba','session',session,'x_label','Linear track position (cm)');
```

### 5.b Circular track

Generate the linearized firing rate map
```m
ratemap = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'session',session,'x_label','Theta maze position (cm)');
```

Generate trial-wise firing rate map
```m
ratemap_Trials = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.trials,'dataName','ratemap_Trials','session',session,'x_label','Theta maze position (cm)');
```

Generate left-right firing rate map
```m
ratemap_LeftRight = generate_FiringRateMap_1D('spikes',spikes,'behavior',circular_track,'states',circular_track.states.left_right,'stateNames',circular_track.stateNames.left_right,'dataName','ratemap_LeftRight','session',session,'x_label','Theta maze position (cm)');
```

## 6. Run CellExplorer's Processing pipeline

The Processing pipeline will detect and import the firing rate maps, detect place fields and calculate spatial information.

The firing rate maps are saved as cell arrays fields, e.g. `cell_metrics.firingRateMaps.ratemap`.

Metadata is saved to the .general field, e.g. 
`cell_metrics.general.firingRateMaps.ratemap.x_bins` and `cell_metrics.general.firingRateMaps.ratemap.boundaries`.

```m
cell_metrics = ProcessCellMetrics('session',session);

cell_metrics = CellExplorer('metrics',cell_metrics);
```
