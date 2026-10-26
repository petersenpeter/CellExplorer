function result = tryMetricLoad(loadCandidate, confirmReplacement, capture, apply, restore)
%TRYMETRICLOAD Stage reads before changing the active session; roll back failures.
% capture/restore own the application model. External effects of custom plotting
% callbacks are outside this boundary. Confirmation happens after loading, so
% edits made while a progress callback yields are included in the decision.
result = struct('status','failed','phase','load','error',[], 'restoreError',[]);
try
    candidate = loadCandidate();
    ce.data.metricCellCount(candidate,true);
    result.phase = 'confirm';
    if ~confirmReplacement()
        result.status = 'cancelled'; return
    end
    result.phase = 'capture';
    previous = capture();
catch exception
    result.error = exception;
    if strcmp(exception.identifier,'ce:io:LoadCancelled'), result.status = 'cancelled'; end
    return
end
result.phase = 'initialize';
try
    apply(candidate);
    result.status = 'loaded'; result.phase = 'complete';
catch exception
    result.error = exception;
    try
        restore(previous);
    catch restoreException
        result.restoreError = restoreException;
    end
end
end
