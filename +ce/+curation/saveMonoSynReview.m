function [metrics, mono, result] = saveMonoSynReview(context, reviewed)
%SAVEMONOSYNREVIEW Stage both files, archive both originals, then replace.
% On a caught second-write failure, restore the first file only if no other
% writer changed it. This is not crash recovery or a filesystem transaction.
ce.curation.verifyFileRevision(context.metricsFile,context.metricsHash);
ce.curation.verifyFileRevision(context.monoFile,context.monoHash);
automatic=ce.pipeline.monoSynAutomatic(reviewed);
if ~strcmp(ce.pipeline.fingerprint(automatic),context.automaticHash)
    error('ce:curation:DetectionChanged','Review changed automatic detection data; nothing was saved.');
end
selection=ce.curation.validateMonoSynSelection(reviewed,automatic);
mono=context.mono;
mono.sig_con=selection.excitatory; mono.sig_con_excitatory=selection.excitatory; mono.sig_con_inhibitory=selection.inhibitory;
if isfield(reviewed,'manualEdit'), mono.manualEdit=reviewed.manualEdit; end
mono.processinginfo.review=struct('status','viewer_reviewed','recordedAt',now, ...
    'selectionHash',ce.pipeline.fingerprint(selection));
metrics=ce.curation.projectMonoSynReview(context.metrics,selection);
metrics.general.processinginfo.monosynapticReview=mono.processinginfo.review;
metricTemp=[tempname(fileparts(context.metricsFile)),'.mat'];
monoTemp=[tempname(fileparts(context.monoFile)),'.mat'];
cleanup=onCleanup(@() removeStaged({metricTemp,monoTemp}));
ce.io.writeMat(metricTemp,struct('cell_metrics',metrics));
ce.io.writeMat(monoTemp,struct('mono_res',mono));
monoNewHash=ce.pipeline.fileFingerprint(monoTemp);
result.file=char(java.io.File(context.metricsFile).getCanonicalPath);
result.previousHash=context.metricsHash;
result.hash=ce.pipeline.fileFingerprint(metricTemp);
ce.curation.verifyFileRevision(context.metricsFile,context.metricsHash);
ce.curation.verifyFileRevision(context.monoFile,context.monoHash);
result.metricsBackup=ce.curation.backupMetricFile(context.metricsFile,context.metricsHash,context.metrics);
folder=fullfile(fileparts(context.monoFile),'revisions_mono_res');
if ~isfolder(folder)
    [success,message]=mkdir(folder);
    if ~success, error('ce:curation:BackupFailed','Cannot create monosynaptic backup directory: %s',message); end
end
[~,name]=fileparts(context.monoFile); [~,suffix]=fileparts(tempname(folder));
result.monoBackup=fullfile(folder,[name,'_',suffix,'.mat']);
ce.io.writeAtomic(result.monoBackup,@(temporary) copyfile(context.monoFile,temporary), ...
    @(temporary) ce.curation.verifyFileRevision(temporary,context.monoHash));
ce.curation.verifyFileRevision(context.metricsFile,context.metricsHash);
ce.curation.verifyFileRevision(context.monoFile,context.monoHash);
replace(monoTemp,context.monoFile);
try
    ce.curation.verifyFileRevision(context.metricsFile,context.metricsHash);
    ce.curation.verifyFileRevision(context.monoFile,monoNewHash);
    replace(metricTemp,context.metricsFile);
catch exception
    try
        ce.curation.verifyFileRevision(context.monoFile,monoNewHash);
        ce.io.writeAtomic(context.monoFile,@(temporary) copyfile(result.monoBackup,temporary), ...
            @(temporary) verifyRollback(temporary));
    catch recoveryError
        failure=MException('ce:curation:PartialMonoSynSave', ...
            'Save failed and monosynaptic rollback was unsafe or failed. Original backups: %s and %s.',result.metricsBackup,result.monoBackup);
        failure=addCause(failure,exception); failure=addCause(failure,recoveryError); throw(failure);
    end
    rethrow(exception);
end
result.saved=true;

    function verifyRollback(temporary)
        ce.curation.verifyFileRevision(temporary,context.monoHash);
        ce.curation.verifyFileRevision(context.monoFile,monoNewHash);
    end
end

function replace(source,destination)
[success,message]=movefile(source,destination,'f');
if ~success, error('ce:io:ReplaceFailed','Cannot replace %s: %s',destination,message); end
end

function removeStaged(files)
for item=files, if isfile(item{1}), delete(item{1}); end, end
end
