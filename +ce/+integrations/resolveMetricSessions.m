function [basepaths,basenames] = resolveMetricSessions(names, ids)
%RESOLVEMETRICSESSIONS Explicit DB boundary; preserve request order and duplicates.
if ~isempty(names) && ~isempty(ids)
    error('ce:io:AmbiguousMetricSource','Choose session names or IDs, not both.');
end
if isempty(which('db_set_session'))
    error('ce:io:MissingDatabaseIntegration','Add the database integration to resolve remote session names/IDs, or supply local basepaths.');
end
count = max(numel(names),numel(ids)); basepaths = cell(1,count); basenames = cell(1,count);
for index = 1:count
    if ~isempty(names), selector = {'sessionName',names{index}};
    else, selector = {'sessionId',ids(index)}; end
    % Loading metrics must not rewrite session metadata or change the caller cwd.
    [~,name,folder] = db_set_session(selector{:},'changeDir',false,'saveMat',false);
    if ~ischar(name) || isempty(name) || ~ischar(folder) || isempty(folder)
        error('ce:io:UnresolvedMetricSession','Database session request %d could not be resolved.',index);
    end
    basenames{index} = name; basepaths{index} = folder;
end
end
