function verifySpikeImport(pending)
%VERIFYSPIKEIMPORT Detect source edits/new groups and concurrent cache writes.
inputs = ce.pipeline.spikeImportInputs(pending.session,pending.options);
if ~strcmp(pending.inputHash,ce.pipeline.fingerprint(inputs))
    error('ce:pipeline:SortingSourceChanged','Sorting inputs changed during processing; rerun before saving.');
end
actual = '';
if isfile(pending.file), actual = ce.pipeline.fileFingerprint(pending.file); end
if ~strcmp(actual,pending.expectedHash)
    error('ce:io:PipelineRevisionChanged','Spike import cache changed during processing: %s.',pending.file);
end
end
