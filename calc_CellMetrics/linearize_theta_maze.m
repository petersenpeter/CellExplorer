function behavior = linearize_theta_maze(behavior,maze)
% Linearize a 2D trajectory on the theta maze to a linear representation.
% 
% Peter Petersen
% petersen.peter@gmail.com

% This is the circular track as used by Peter and Viktor
% The origin has to be the center of the maze


% Defining Arm and rim as states
behavior.states.arm_rim = nan(1,length(behavior.timestamps)); % Numeric: 1, 2 or nan (outside)
behavior.stateNames.arm_rim = {'Arm','Rim'};

idx_arm = behavior.position.polar_rho < maze.polar_rho_limits(1) & behavior.position.y > maze.pos_y_limits(1) & behavior.position.y < maze.pos_y_limits(2);
behavior.states.arm_rim(idx_arm) = 1;

idx_rim = behavior.position.polar_rho > maze.polar_rho_limits(1) & behavior.position.polar_rho < maze.polar_rho_limits(2)+10 & abs(behavior.position.polar_theta) < maze.polar_theta_limits(2);
behavior.states.arm_rim(idx_rim) = 2;

% First the central arm is linearized
pos_linearized = nan(size(behavior.timestamps));
pos_linearized(behavior.states.arm_rim==1) = behavior.position.y(behavior.states.arm_rim==1)-maze.pos_y_limits(1);

% Adding homeport to central arm
idx = find(isnan(behavior.states.arm_rim) & behavior.position.y <=-25);
pos_linearized(idx) = behavior.position.y(idx)-maze.pos_y_limits(1);

% Next the left(?) return side-arm
boundary = diff(maze.pos_y_limits)-5;
pos_linearized(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5) = -behavior.position.polar_theta(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5) + boundary;

% Finally the right return side-arm is linearized.
boundary = boundary + maze.polar_theta_limits(2)-5;
pos_linearized(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5) = behavior.position.polar_theta(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5) + boundary;

behavior.position.linearized = pos_linearized;

behavior.limits.linearized = [0,diff(maze.pos_y_limits) + diff(maze.polar_theta_limits*maze.radius_in)-5];
behavior.boundaries.linearized = [0,diff(maze.pos_y_limits), diff(maze.pos_y_limits)+ diff(maze.polar_theta_limits*maze.radius_in)-5];
behavior.boundaryNames.linearized = {'Central arm','Left side','Right side'};

figure, 
subplot(2,2,1)
plot(behavior.position.x,behavior.position.y,'.k','markersize',2), hold on
plot(behavior.position.x(behavior.states.arm_rim==1),behavior.position.y(behavior.states.arm_rim==1),'.b','markersize',2), 
plot(behavior.position.x(behavior.states.arm_rim==2),behavior.position.y(behavior.states.arm_rim==2),'.r','markersize',2), 
xlabel('X'), ylabel('Y'), axis tight
title('Arm and rim')

subplot(2,2,2)
plot(behavior.position.x,behavior.position.y,'.k','markersize',2), hold on
plot(behavior.position.x(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5),behavior.position.y(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5),'.b','markersize',2), 
plot(behavior.position.x(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5),behavior.position.y(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5),'.r','markersize',2), 
xlabel('X'), ylabel('Y'), axis tight
title('Left and right')

subplot(2,2,4)
plot(behavior.timestamps,behavior.position.linearized,'.k','markersize',2), hold on
plot(behavior.timestamps(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5),behavior.position.linearized(behavior.states.arm_rim==2 & behavior.position.polar_theta < -5),'.b','markersize',2), 
plot(behavior.timestamps(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5),behavior.position.linearized(behavior.states.arm_rim==2 & behavior.position.polar_theta > 5),'.r','markersize',2), 
xlabel('Time (sec)'), ylabel('Linearized position (cm)'), axis tight

subplot(2,2,3)
plot(behavior.timestamps,behavior.position.linearized,'.k','markersize',2), hold on
plot(behavior.timestamps(behavior.states.arm_rim==1),behavior.position.linearized(behavior.states.arm_rim==1),'.b','markersize',2), 
plot(behavior.timestamps(behavior.states.arm_rim==2),behavior.position.linearized(behavior.states.arm_rim==2),'.r','markersize',2), 
xlabel('Time (sec)'), ylabel('Linearized position (cm)'), axis tight
