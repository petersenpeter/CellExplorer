function result = saveOutputs(metrics, session, plan, outputs)
%SAVEOUTPUTS Persist validated results; source classification files stay read-only.
% Individual files use verified replacement. This is not a multi-file transaction.
result = struct('saved',false,'backup','');
if ~plan.enabled, return; end
if isfield(outputs,'spikeImport'), ce.pipeline.verifySpikeImport(outputs.spikeImport.pending); end
ce.data.validateCellMetricsStruct(metrics);
validateattributes(session,{'struct'},{'scalar'});
for file = {plan.metricsFile,plan.sessionFile}
    if isfolder(file{1}) || ~isfolder(fileparts(file{1}))
        error('ce:io:InvalidDestination','Destination must be a file in an existing directory: %s.',file{1});
    end
end
verifyRevision(plan.metricsFile,plan.metricsHash);
verifyRevision(plan.sessionFile,plan.sessionHash);
if plan.saveBackup && ~isempty(plan.metricsHash)
    folder = fullfile(fileparts(plan.metricsFile),'revisions_cell_metrics');
    if ~isfolder(folder)
        [success,message] = mkdir(folder);
        if ~success, error('ce:io:BackupFailed','Cannot create metric backup directory: %s',message); end
    end
    [~,~,extension] = fileparts(plan.metricsFile);
    result.backup = fullfile(folder,[plan.saveAs,'_',datestr(now,'yyyy-mm-dd_HHMMSS'),'_',plan.metricsHash,extension]);
    if isfile(result.backup)
        verifyRevision(result.backup,plan.metricsHash);
    else
        ce.io.writeAtomic(result.backup,@(temporary) copyfile(plan.metricsFile,temporary), ...
            @(temporary) verifyRevision(temporary,plan.metricsHash));
    end
end
% Recheck after backup creation, before any result files are changed.
verifyRevision(plan.metricsFile,plan.metricsHash);
verifyRevision(plan.sessionFile,plan.sessionHash);
if isfield(outputs,'theta')
    item = outputs.theta;
    ce.io.saveTheta(item.file,item.data,item.expectedHash);
end
if isfield(outputs,'mono')
    item = outputs.mono;
    ce.io.saveMonoSyn(item.file,item.data,item.expectedHash);
end
if isfield(outputs,'waveforms')
    item = outputs.waveforms;
    ce.io.writeMat(item.file,struct('waveformCache',item.data));
end
if isfield(outputs,'spikeImport')
    item = outputs.spikeImport;
    ce.pipeline.verifySpikeImport(item.pending);
    ce.io.writeMat(item.pending.file,struct('spikeImportCache',item.cache));
end
verifyRevision(plan.metricsFile,plan.metricsHash);
ce.io.saveCellMetrics(metrics,plan.metricsFile);
verifyRevision(plan.sessionFile,plan.sessionHash);
ce.io.writeMat(plan.sessionFile,struct('session',session));
result.saved = true;
end

function verifyRevision(file,expected)
actual = '';
if isfile(file), actual = ce.pipeline.fileFingerprint(file); end
if ~strcmp(actual,expected)
    error('ce:io:PipelineRevisionChanged','File changed during processing: %s. Reload before saving.',file);
end
end
