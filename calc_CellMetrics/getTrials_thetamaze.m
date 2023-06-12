function circular_track = getTrials_thetamaze(circular_track, maze, plots)
% Determines trials for position data along a circular_track (2-dimensional path)
%
% circular_track :
%    Required fields in struct:
%    .timestamps : timestamps in seconds
%    .position.x : x position
%    .position.y : y position
%
% maze : maza parameters
%
% plots : show summary plot? 
%
% circular_track - Added fields:
%    .trials.alternation.start
%    .trials.alternation.stop
%    .trials.alternation.trials
%    .trials.alternation.nTrials
%    .trials.alternation.stateName
%
%    .states.left_right
%    .states.error 
%    .stateNames.left_right
%    .stateNames.error

if nargin < 3
    plots = 1;
end
if ~isfield(circular_track,'nSamples')
	circular_track.nSamples = numel(circular_track.timestamps);
end

% Determining polar coordinates
[circular_track.position.polar_theta,circular_track.position.polar_rho] = cart2pol(circular_track.position.y,circular_track.position.x);

% Changing from polar angle to position along circle by multiplying with the radius (inner radius)
% Negative values are along the left arm, positive values along the right arm
circular_track.position.polar_theta = circular_track.position.polar_theta*maze.radius_in;

disp('Defining trials for the behavior')

% Determining spatial limits 

% Onset of central arm
central_arm_onset = find(diff(circular_track.position.y > maze.pos_y_limits(1))==1 ...
    & circular_track.position.x(1:end-1) < maze.pos_x_limits(2)-5 ...
    & circular_track.position.x(1:end-1) > maze.pos_x_limits(1)+5 ...
    & circular_track.position.y(1:end-1) < 0);

% End of central arm
central_arm_end = find(diff(circular_track.position.polar_rho > maze.pos_y_limits(2))==1 ...
    & circular_track.position.x(1:end-1) < maze.pos_x_limits(2)-5 ...
    & circular_track.position.x(1:end-1) > maze.pos_x_limits(1)+5 ...
    & circular_track.position.y(1:end-1) > 0);

% Start of left arm
left_rim_onset = find(diff(circular_track.position.x < maze.pos_x_limits(1)-5)==1 ...
    & circular_track.position.y(1:end-1) > maze.pos_y_limits(2)-10);

% Start of right arm
right_rim_onset = find(diff(circular_track.position.x > maze.pos_x_limits(2)+5)==1 ...
    & circular_track.position.y(1:end-1) > maze.pos_y_limits(2)-10);

% End of left rim
left_rim_end = find(diff(circular_track.position.polar_theta < -maze.polar_theta_limits(2))==1 ...
    & abs(circular_track.position.x(1:end-1)) > 10 ...
    & circular_track.position.polar_rho(1:end-1) > maze.polar_rho_limits(1)-5);

% End of right rim
right_rim_end = find(diff(circular_track.position.polar_theta > maze.polar_theta_limits(2))==1 ...
    & abs(circular_track.position.x(1:end-1)) > 10 ...
    & circular_track.position.polar_rho(1:end-1) > maze.polar_rho_limits(1)-5);

% All 
pos7home = sort([left_rim_end,right_rim_end]);

central_arm_end(find(diff(central_arm_end)<circular_track.sr)+1) = [];

if plots == 1
    disp('Plotting position')
    
    figure
    
    plot(circular_track.position.x,circular_track.position.y,'color',[0.5 0.5 0.5]), hold on
    plot([-10,10],maze.pos_y_limits(1)*[1,1],'k') % Onset of central arm
    plot([-10,10],maze.pos_y_limits(2)*[1,1],'k') % End of central arm
    plot([1,1]*maze.pos_x_limits(1)-5,maze.pos_y_limits(2)+[-10,20],'k') 
    plot([1,1]*maze.pos_x_limits(2)+5,maze.pos_y_limits(2)+[-10,20],'k')
    [y1,x1] = pol2cart(maze.polar_theta_limits(2)/maze.radius_in,maze.polar_rho_limits(1)-5);
    [y2,x2] = pol2cart(maze.polar_theta_limits(2)/maze.radius_in,maze.polar_rho_limits(2));
    plot([x1,x2],[y1,y2],'-k')
    plot(-[x1,x2],[y1,y2],'--k')
    plot(circular_track.position.x(central_arm_onset),circular_track.position.y(central_arm_onset),'or') % Onset of central arm
    plot(circular_track.position.x(central_arm_end),circular_track.position.y(central_arm_end),'om') % End of central arm
    plot(circular_track.position.x(left_rim_onset),circular_track.position.y(left_rim_onset),'ok') % Start of Left arm
    plot(circular_track.position.x(right_rim_onset),circular_track.position.y(right_rim_onset),'og') % Start of right arm
    plot(circular_track.position.x(left_rim_end),circular_track.position.y(left_rim_end),'xc') % Left rim
    plot(circular_track.position.x(right_rim_end),circular_track.position.y(right_rim_end),'xy') % Right rim
    title('Position of the animal'), xlabel('X'), ylabel('Y'), zlabel('Z'),axis tight, % view(2)
    if exist('plot_ThetaMaze.m')
        plot_ThetaMaze(maze)
    end
end

% Resetting trials field if not formatted correctly
if isfield(circular_track,'trials') && isnumeric(circular_track.trials)
    circular_track.trials = {};
end

trials = [];
circular_track.states.error = []; % Boolean, if a trial is considered an error

circular_track.states.left_right = []; % Numeric: 1 or 2
circular_track.stateNames.left_right = {'Left','Right'};

trials.start = 0; % Start time of
trials.end = [];

% Preparing trials matric
trials.trials = nan(1,circular_track.nSamples);
trials_states = zeros(1,circular_track.nSamples);
i = 0;

% Behavioral scoring
for j = 1:length(central_arm_end)
    test1 = find(central_arm_onset < central_arm_end(j));
    test2 = find(pos7home > central_arm_end(j));
    if ~isempty(test2) & ~isempty(test1)
        if (pos7home(test2(1))- central_arm_onset(test1(end)))/circular_track.sr < 50
            if trials.start(end)-central_arm_onset(test1(end)) ~= 0
                i = i+1;
                trials.start(i) = central_arm_onset(test1(end));
                trials.end(i) = pos7home(test2(1));
                trials.trials(trials.start(i):trials.end(i)) = i;
                trials_states(trials.start(i):trials.end(i)) = 1;
                if sum(ismember(left_rim_end,trials.end(i)))
                    % Left trial
                    circular_track.states.left_right(i) = 1;
                    if sum(ismember(right_rim_onset,trials.start(i):trials.end(i)))
                        circular_track.states.error(i) = true;
                        else
                        circular_track.states.error(i) = false;
                    end
                elseif sum(ismember(right_rim_end,trials.end(i)))
                    % Right trial
                    circular_track.states.left_right(i) = 2;
                    if sum(ismember(left_rim_onset,trials.start(i):trials.end(i)))
                        circular_track.states.error(i) = true;
                    else
                        circular_track.states.error(i) = false;
                    end
                else
                    circular_track.states.left_right(i) = 0;
                end
            end
        end
    end
end

% Changning from units of samples to units of time
trials.start = circular_track.timestamps(trials.start);
trials.end = circular_track.timestamps(trials.end);
trials.nTrials = numel(trials.start);

trials.stateName = 'Alternative running on track';

% Adding trials struct to circular_track struct
circular_track.trials.alternation = trials;

if plots == 1
    figure,
    
    subplot(1,2,1)
    plot(circular_track.timestamps-circular_track.timestamps(1),trials.trials,'.k','linewidth',2), xlabel('Time (sec)'), ylabel('Trials')
    
    subplot(3,2,2)
    stairs(circular_track.timestamps-circular_track.timestamps(1),trials_states,'.-k','linewidth',1), xlabel('Time (sec)'), ylabel('Trial')
    
    subplot(3,2,4)
    stairs(circular_track.states.left_right,'.-b','linewidth',1), xlabel('Trials'), ylabel('Left/Right'), 
    yticks(1:numel(circular_track.stateNames.left_right)), yticklabels(circular_track.stateNames.left_right)
    
    subplot(3,2,6)
    stairs(circular_track.states.error,'.-k','linewidth',1), xlabel('Trials'), ylabel('Errors')
    
    figure
    
    subplot(1,2,1)
    plot(circular_track.position.x,circular_track.position.y,'.k','markersize',2), hold on
    idx_left = ismember(trials.trials, find(circular_track.states.left_right==1));
    plot(circular_track.position.x(idx_left),circular_track.position.y(idx_left),'.b','markersize',6)
    idx_right = ismember(trials.trials, find(circular_track.states.left_right==2));
    plot(circular_track.position.x(idx_right),circular_track.position.y(idx_right),'.r','markersize',6)
    title('Trials'), xlabel('X'), ylabel('Y')

    subplot(1,2,2)
    plot3(circular_track.position.x,circular_track.position.y,circular_track.timestamps,'.k','markersize',2), hold on
    idx_left = ismember(trials.trials, find(circular_track.states.left_right==1));
    plot3(circular_track.position.x(idx_left),circular_track.position.y(idx_left),circular_track.timestamps(idx_left),'.b','markersize',6)
    idx_right = ismember(trials.trials, find(circular_track.states.left_right==2));
    plot3(circular_track.position.x(idx_right),circular_track.position.y(idx_right),circular_track.timestamps(idx_right),'.r','markersize',6)
    title('Trials and time'), xlabel('X'), ylabel('Y'), zlabel('Time (sec)')
end
