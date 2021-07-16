function pos_linearized = linearize_pos_v2(animal,maze)
% Linearize a 2D trajectory into one 1D.
% 
% Peter Petersen
% petersen.peter@gmail.com

if any(strcmp(maze.type, {'theta','CircularTrack','circular track'}))
    % This is a circular track as used by Peter and Viktor
    % The origin has to be the center of the maze
    % First the central arm is linearized
    pos_linearized = nan(size(animal.timestamps));
    pos_linearized(animal.states.arm_rim==1) = animal.position.y(animal.states.arm_rim==1)-maze.pos_y_limits(1);
    
    % Adding homeport to central arm
    idx = find(isnan(animal.states.arm_rim) & animal.position.y <=-25);
    pos_linearized(idx) = animal.position.y(idx)-maze.pos_y_limits(1);
    
    % Next the left(?) return side-arm
    boundary = diff(maze.pos_y_limits)-5;
    pos_linearized(animal.states.arm_rim==2 & animal.position.polar_theta < -5) = -animal.position.polar_theta(animal.states.arm_rim==2 & animal.position.polar_theta < -5) + boundary;
    
    % Finally the right return side-arm is linearized.
    boundary = boundary + abs(maze.polar_theta_limits(1))-5;
    pos_linearized(animal.states.arm_rim==2 & animal.position.polar_theta > 5) = animal.position.polar_theta(animal.states.arm_rim==2 & animal.position.polar_theta > 5) + boundary;
    
    figure, plot(animal.timestamps,pos_linearized,'.'), xlabel('Time (sec)'), ylabel('Linearized position (cm)'), axis tight
end