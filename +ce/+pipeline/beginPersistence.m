function plan = beginPersistence(session, parameters)
%BEGINPERSISTENCE Capture destination revisions before calculation/curation.
plan.enabled = parameters.saveMat;
plan.saveBackup = parameters.saveBackup;
plan.saveAs = parameters.saveAs;
plan.metricsFile = fullfile(session.general.basePath,[session.general.name,'.',parameters.saveAs,'.cellinfo.',parameters.fileFormat]);
plan.sessionFile = fullfile(session.general.basePath,[session.general.name,'.session.mat']);
plan.metricsHash = ''; plan.sessionHash = '';
if plan.enabled
    if isfile(plan.metricsFile), plan.metricsHash = ce.pipeline.fileFingerprint(plan.metricsFile); end
    if isfile(plan.sessionFile), plan.sessionHash = ce.pipeline.fileFingerprint(plan.sessionFile); end
end
end
