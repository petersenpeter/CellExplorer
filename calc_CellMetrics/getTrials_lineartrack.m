function trials = getTrials_lineartrack(position)
trials = [];
a2b_equ = @(a,b,c)(find(diff(a(1,:) > b)==1 & a(2,1:end-1) > c(1) & a(2,1:end-1) < c(2)));
a2b.start = a2b_equ(position,boundary1(1),boundary2);
a2b.end = a2b_equ(position,boundary1(2),boundary2)+1;
j = 0;
trials.trials{1} = nan(1,size(position,2));
trials.state = zeros(1,size(position,2));
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
            trials.trials{1}(trials.ab.start(j):trials.ab.end(j)) = j;
            trials.state(trials.ab.start(j):trials.ab.end(j)) = 1;
    end
end

b2a_equ = @(a,b,c)(find(diff(a(1,:) < b)==1 & a(2,1:end-1) > c(1) & a(2,1:end-1) < c(2)));
b2a.start = b2a_equ(position,boundary1(2),boundary2);
b2a.end = b2a_equ(position,boundary1(1),boundary2)+1;
j = 0;
trials.trials{2} = nan(1,size(position,2));
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
            trials.trials{2}(trials.ba.start(j):trials.ba.end(j)) = j;
            trials.state(trials.ba.start(j):trials.ba.end(j)) = 2;
    end
end
