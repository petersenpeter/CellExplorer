function lineartrack = getTrials_lineartrack(lineartrack, pos_limits,plots)
% Determines trials for position data along a linear track (1-dimensional path)
%
% lineartrack :
%    Required fields in struct:
%    .timestamps : timestamps in seconds
%    .position.linearized : linearized position
%
% pos_limits : two limits in 1D, e.g. [10,90]
%
% lineartrack - Added fields:
%    .trials.ab.start
%    .trials.ab.stop
%    .trials.ab.trials
%    .trials.ab.nTrials
%    .trials.ab.stateName
%    .trials.ba.*
%
%    .states.ab_ba
%    .stateNames.ab_ba

if nargin < 3
    plots = 1;
end

position = lineartrack.position.linearized;

trials = [];

% % % % % % % % % %
% Processing a to b
lineartrack.states.ab_ba = zeros(1,length(position));
a2b.start = find(diff(position > pos_limits(1)) == 1);
a2b.end = find(diff(position > pos_limits(2)) == -1)-1;
trials.ab.trials = nan(1,length(position));

j = 0;
for i = 1:length(a2b.start)
    test2 = find(a2b.end > a2b.start(i));
    if ~isempty(test2)
        if j > 0
            if trials.ab.end(end) ~= a2b.end(test2(1))
                j = j + 1;
            else
                trials.trials{1}(trials.ab.start(j):trials.ab.end(j)) = nan;
            end
        else
            j = 1;
        end
        trials.ab.start(j) = a2b.start(i);
        trials.ab.end(j) = a2b.end(test2(1));
        trials.ab.trials(trials.ab.start(j):trials.ab.end(j)) = j;
        lineartrack.states.ab_ba(trials.ab.start(j):trials.ab.end(j)) = 1;
    end
end

% Changning from units of samples to units of time
trials.ab.start = lineartrack.timestamps(trials.ab.start);
trials.ab.end = lineartrack.timestamps(trials.ab.end);
trials.ab.nTrials = numel(trials.ab.start);

% % % % % % % % % %
% Processing b to a
b2a.start = find(diff(position < pos_limits(2)) == 1);
b2a.end = find(diff(position < pos_limits(1)) == 1)-1;

trials.ba.trials = nan(1,length(position));
j = 0;
for i = 1:length(b2a.start)
    test2 = find(b2a.end > b2a.start(i));
    if ~isempty(test2)
        if j > 0
            if trials.ba.end(end) ~= b2a.end(test2(1))
                j = j + 1;
            else
                trials.trials{2}(trials.ba.start(j):trials.ba.end(j)) = nan;
            end
        else
            j = 1;
        end
        trials.ba.start(j) = b2a.start(i);
        trials.ba.end(j) = b2a.end(test2(1));
        trials.ba.trials(trials.ba.start(j):trials.ba.end(j)) = j;
        lineartrack.states.ab_ba(trials.ba.start(j):trials.ba.end(j)) = 2;
    end
end


% Changning from units of samples to units of time
trials.ba.start = lineartrack.timestamps(trials.ba.start);
trials.ba.end = lineartrack.timestamps(trials.ba.end);
trials.ba.nTrials = numel(trials.ba.start);


% % % % % % % % % %
% Adding stateNames
trials.ab.stateName = 'From a to b';
trials.ba.stateName = 'From b to a';
lineartrack.stateNames.ab_ba = {'From a to b','From b to a'};


% Adding trials struct to lineartrack struct
lineartrack.trials = trials;

xlim1 = [0,max(lineartrack.timestamps-lineartrack.timestamps(1))];
if plots == 1
    
    figure,
    
    subplot(3,1,1)
    plot(lineartrack.timestamps-lineartrack.timestamps(1),lineartrack.position.linearized,'.k','linewidth',2), xlabel('Time (sec)'), ylabel('Position'), hold on
    idx1 = lineartrack.states.ab_ba == 1;
    plot(lineartrack.timestamps(idx1)-lineartrack.timestamps(1),lineartrack.position.linearized(idx1),'.r','linewidth',2)
    idx2 = lineartrack.states.ab_ba == 2;
    plot(lineartrack.timestamps(idx2)-lineartrack.timestamps(1),lineartrack.position.linearized(idx2),'.b','linewidth',2)
    xlim(xlim1), title('Behavior (from a2b and b2a)'), legend({'All positions','a2b','b2a'})
    
    subplot(3,1,2)
    plot(lineartrack.timestamps-lineartrack.timestamps(1),lineartrack.trials.ab.trials,'.r','linewidth',2), xlabel('Time (sec)'), ylabel('Trials'), hold on
    plot(lineartrack.timestamps-lineartrack.timestamps(1),lineartrack.trials.ba.trials,'.b','linewidth',2)
    xlim(xlim1)
    
    subplot(3,1,3)
    stairs(lineartrack.timestamps-lineartrack.timestamps(1),lineartrack.states.ab_ba,'.-k','linewidth',1), xlabel('Time (sec)'), ylabel('States')
    xlim(xlim1)

end