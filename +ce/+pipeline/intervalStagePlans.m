function plans = intervalStagePlans(metrics, session, parameters, preferences)
%INTERVALSTAGEPLANS Declare dynamic output ownership and reject ambiguous names.
kinds = {'event_metrics','manipulation_metrics','state_metrics'};
ignoreFields = {'ignoreEventTypes','ignoreManipulationTypes','ignoreStateTypes'};
containers = {'events','manipulations','states'};
plans = struct([]);
for index = 1:numel(kinds)
    kind = kinds{index};
    plan = struct('name',kind,'selected',false,'records',[],'outputs',{{}}, ...
        'retiredOutputs',{ce.pipeline.intervalOwnership(metrics,kind)},'preferences',struct());
    plan.selected = any(contains(parameters.metrics,{kind,'all'})) && ~any(contains(parameters.excludeMetrics,{kind}));
    if plan.selected
        plan.records = ce.pipeline.intervalFiles(session,kind,parameters.(ignoreFields{index}));
        plan.outputs = {['general.',containers{index}]};
        if index < 3, plan.outputs{end+1} = containers{index}; end
        for record = plan.records
            if index == 3
                for state = fieldnames(record.data.ints)'
                    if ~isempty(record.data.ints.(state{1}))
                        addOutputs(strcat({'firingRate_','firingRateISI_','cv2_','burstIndex_'},state{1}));
                    end
                end
            elseif ~isempty(record.data.timestamps)
                addOutputs(strcat(record.name,{'_modulationIndex','_modulationRatio','_modulationPeakResponseTime','_modulationSignificanceLevel'}));
                if isempty(preferences), continue; end % Read-only preflight: no preference callbacks.
                selected = preferences.psth;
                if index == 1 && isfield(selected,record.name) && isstruct(selected.(record.name))
                    selected = selected.(record.name);
                end
                fields = {'binCount','alignment','binDistribution','duration','smoothing','percentile'};
                if index == 1, fields{end+1} = 'intervals'; end
                for name = fields
                    if ~isfield(selected,name{1})
                        error('ce:pipeline:InvalidPsthSettings','Missing PSTH preference %s for %s.',name{1},record.name);
                    end
                    plan.preferences.(record.name).(name{1}) = selected.(name{1});
                end
                if strcmp(selected.alignment,'peaks') && (~isfield(record.data,'peaks') || ...
                        ~isnumeric(record.data.peaks) || ~isreal(record.data.peaks) || ...
                        numel(record.data.peaks) ~= size(record.data.timestamps,1) || any(~isfinite(record.data.peaks(:))))
                    error('ce:pipeline:InvalidEventPeaks','%s requires one finite peak time per event.',record.file);
                end
            end
        end
    else
        plan.outputs = plan.retiredOutputs; % Protect outputs of skipped stages.
    end
    plans = [plans,plan];
end
for left = 1:numel(plans)
    for right = left+1:numel(plans)
        overlap = intersect(plans(left).outputs,plans(right).outputs);
        if ~isempty(overlap) && (plans(left).selected || plans(right).selected)
            error('ce:pipeline:IntervalOutputCollision','%s and %s both own %s. Use distinct input/state names.', ...
                plans(left).name,plans(right).name,overlap{1});
        end
    end
end
% A removed input may have been deliberately moved to another selected stage.
% Do not let the old owner delete fields that the new owner now produces.
for index = 1:numel(plans)
    others = [plans([1:index-1,index+1:end]).outputs];
    plans(index).retiredOutputs = setdiff(plans(index).retiredOutputs,others);
end

    function addOutputs(paths)
        if any(~cellfun(@isvarname,paths)) || any(ismember(paths,plan.outputs))
            error('ce:pipeline:IntervalOutputCollision','Input/state names in %s produce duplicate or invalid metric fields.',kind);
        end
        plan.outputs = [plan.outputs,paths];
    end
end
