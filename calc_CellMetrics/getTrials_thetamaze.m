function [trials,circular_track] = getTrials_thetamaze(circular_track,maze, plots)
if nargin < 3
    plots = 1;
end
if ~isfield(circular_track,'nSamples')
	circular_track.nSamples = numel(circular_track.timestamps);
end

% Determining polar coordinates
[circular_track.position.polar_theta,circular_track.position.polar_rho] = cart2pol(circular_track.position.y,circular_track.position.x);

% Changing from polar angle to position along circle by multiplying with the radius
circular_track.position.polar_theta = circular_track.position.polar_theta*maze.radius_in;

disp('Defining trials for the behavior')
boundary = maze.boundary;

% Determining spatial cross points 
pos1test = find(diff(circular_track.position.polar_rho < boundary{1}(2))==1 & circular_track.position.x(1:end-1) < boundary{1}(1)+10 & circular_track.position.x(1:end-1) > boundary{1}(1)-10 & circular_track.position.y(1:end-1) < 0);
pos2test = find(diff(circular_track.position.y > boundary{2}(2))==1 & circular_track.position.x(1:end-1) < boundary{2}(1)+10 & circular_track.position.x(1:end-1) > boundary{2}(1)-10);
pos3test = find(diff(circular_track.position.x < boundary{3}(1))==1 & circular_track.position.x(1:end-1) < boundary{3}(2)+10 & circular_track.position.y(1:end-1) > boundary{3}(2)-10);
pos4test = find(diff(circular_track.position.x > boundary{4}(1))==1 & circular_track.position.x(1:end-1) < boundary{4}(2)+10 & circular_track.position.y(1:end-1) > boundary{4}(2)-10);
pos5test = find(diff(circular_track.position.polar_theta < -boundary{5}(2))==1 & abs(circular_track.position.x(1:end-1)) > 10 & circular_track.position.polar_rho(1:end-1) > boundary{5}(1)-15);
pos6test = find(diff(circular_track.position.polar_theta > boundary{5}(2))==1 & abs(circular_track.position.x(1:end-1)) > 10 & circular_track.position.polar_rho(1:end-1) > boundary{5}(1)-15);
pos7home = sort([pos5test,pos6test]);
pos2test(find(diff(pos2test)<circular_track.sr)+1) = [];

if plots == 1
    disp('Plotting position')
    figure
    plot(circular_track.position.x,circular_track.position.y,'color',[0.5 0.5 0.5]), hold on
    plot([-10,10]+boundary{1}(1),-boundary{1}(2)*[1,1],'red')
    plot([-10,10]+boundary{2}(1),boundary{2}(2)*[1,1],'m')
    plot([1,1]*boundary{3}(1),boundary{3}(2)+[-10,10],'k')
    plot([1,1]*boundary{4}(1),boundary{4}(2)+[-10,10],'y')
    [x1,y1] = pol2cart(boundary{5}(2),boundary{5}(1)-4);
    [x2,y2] = pol2cart(boundary{5}(2),boundary{5}(1)+10);
    plot([x1,x2],-[y1,y2],'c')
    plot(-[x1,x2],-[y1,y2],'g')
    plot(circular_track.position.x(pos1test),circular_track.position.y(pos1test),'or') % Onset of central arm
    plot(circular_track.position.x(pos2test),circular_track.position.y(pos2test),'om') % End of central arm
    plot(circular_track.position.x(pos3test),circular_track.position.y(pos3test),'ok') % Start of Left arm
    plot(circular_track.position.x(pos4test),circular_track.position.y(pos4test),'og') % Start of right arm
    plot(circular_track.position.x(pos5test),circular_track.position.y(pos5test),'xc') % Left rim
    plot(circular_track.position.x(pos6test),circular_track.position.y(pos6test),'xy') % Right rim
    title('3D position of the animal'), xlabel('X'), ylabel('Y'), zlabel('Z'),axis tight,%view(2)
    plot_ThetaMaze(maze)
end

trials = [];
trials.states.error = []; % Boolean, if a trial is considered an error
trials.states.left_right = []; % Numeric: 1 or 2
trials.stateNames.left_right = {'Left','Right'};
trials.start = 0; % Start time of
trials.end = [];

% Preparing trials matric
circular_track.trials = nan(1,circular_track.nSamples);
trials_states = zeros(1,circular_track.nSamples);
i = 0;

% Behavioral scoring
for j = 1:length(pos2test)
    test1 = find(pos1test < pos2test(j));
    test2 = find(pos7home > pos2test(j));
    if ~isempty(test2) & ~isempty(test1)
        if (pos7home(test2(1))- pos1test(test1(end)))/circular_track.sr < 50
            if trials.start(end)-pos1test(test1(end)) ~= 0
                i = i+1;
                trials.start(i) = pos1test(test1(end));
                trials.end(i) = pos7home(test2(1));
                circular_track.trials(trials.start(i):trials.end(i)) = i;
                trials_states(trials.start(i):trials.end(i)) = 1;
                if sum(ismember(pos5test,trials.end(i)))
                    % Left trial
                    trials.states.left_right(i) = 1;
                    if sum(ismember(pos4test,trials.start(i):trials.end(i)))
                        trials.states.error(i) = true;
                        else
                        trials.states.error(i) = false;
                    end
                elseif sum(ismember(pos6test,trials.end(i)))
                    % Right trial
                    trials.states.left_right(i) = 2;
                    if sum(ismember(pos3test,trials.start(i):trials.end(i)))
                        trials.states.error(i) = true;
                    else
                        trials.states.error(i) = false;
                    end
                else
                    trials.states.left_right(i) = 0;
                end
            end
        end
    end
end

% Changning from units of samples to units of time
trials.start = circular_track.timestamps(trials.start);
trials.end = circular_track.timestamps(trials.end);
trials.nTrials = numel(trials.start);

if plots == 1
    figure,
    subplot(1,2,1)
    plot(circular_track.timestamps-circular_track.timestamps(1),circular_track.trials,'.k','linewidth',2), xlabel('Time (sec)'), ylabel('Trials')
    subplot(3,2,2)
    stairs(circular_track.timestamps-circular_track.timestamps(1),trials_states,'.-k','linewidth',1), xlabel('Time (sec)'), ylabel('Trial')
    subplot(3,2,4)
    stairs(trials.states.left_right,'.-b','linewidth',1), xlabel('Trials'), ylabel('Left/Right'), 
    yticks(1:numel(trials.stateNames.left_right)), yticklabels(trials.stateNames.left_right)
    subplot(3,2,6)
    stairs(trials.states.error,'.-k','linewidth',1), xlabel('Trials'), ylabel('Errors')
end
