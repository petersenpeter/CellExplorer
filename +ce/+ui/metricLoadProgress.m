function [progress,cleanup] = metricLoadProgress(enabled, supplied)
%METRICLOADPROGRESS Own only windows created here; closing cancels the load.
cleanup = []; progress = @(fraction,message) [];
if ~enabled, return; end
owned = isempty(supplied);
if owned
    handle = waitbar(0,' ','Name','Cell-metrics: loading batch');
else
    handle = supplied;
    if ~isscalar(handle) || ~isgraphics(handle,'figure')
        error('ce:ui:InvalidProgressHandle','waitbar_handle must be an open progress figure.');
    end
end
if owned, cleanup = onCleanup(@closeOwned); end
progress = @update;
    function update(fraction,message)
        if ~isgraphics(handle,'figure')
            error('ce:io:LoadCancelled','Metric loading was cancelled; no partial batch was returned.');
        end
        waitbar(fraction,handle,message);
        drawnow;
        if ~isgraphics(handle,'figure')
            error('ce:io:LoadCancelled','Metric loading was cancelled; no partial batch was returned.');
        end
    end
    function closeOwned
        if isgraphics(handle,'figure'), delete(handle); end
    end
end
