function metrics = runCustomCalculations(metrics, session, spikes, parameters)
%RUNCUSTOMCALCULATIONS Preserve callback API; reject changes to cell identity.
% Callbacks remain uncached and interactive-only. Their external side effects
% cannot be rolled back by the pipeline.
names = ce.pipeline.customCalculationNames;
for index = 1:numel(names)
    name = names{index};
    if ~any(contains(parameters.metrics,{name,'all'})) || any(contains(parameters.excludeMetrics,{name}))
        continue
    end
    if parameters.headless
        error('ce:pipeline:UnverifiedExtension','Custom calculation %s has no declared headless contract.',name);
    end
    dispLog(['Custom calculation:',name],session.general.name);
    candidate = customCalculations.(name)(metrics,session,spikes,parameters);
    if ~isstruct(candidate) || ~isscalar(candidate) || ~isfield(candidate,'general') || ...
            ~isstruct(candidate.general) || ~isscalar(candidate.general) || ...
            ~isfield(candidate.general,'cellCount') || ~isequal(candidate.general.cellCount,numel(spikes{1}.UID))
        error('ce:pipeline:InvalidExtensionOutput','Custom calculation %s must preserve a scalar metrics struct and its cell count.',name);
    end
    for key = {'UID','cluID'}
        field = key{1};
        if isfield(metrics,field) && ~isfield(candidate,field) || ...
                isfield(candidate,field) && (~isfield(spikes{1},field) || ~isequal(candidate.(field),spikes{1}.(field)))
            error('ce:pipeline:ExtensionIdentityChanged','Custom calculation %s must preserve %s and cell order.',name,field);
        end
    end
    metrics = candidate;
end
end
