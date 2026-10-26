function result = saveMetricSnapshot(metrics, file, expectedHash)
%SAVEMETRICSNAPSHOT Guard viewer saves; existing MAT files get exact backups.
% This checks sorting identity plus changes during saving, not an edit-session
% lock. New exports are allowed; existing non-MAT exports cannot prove identity.
ce.data.metricCellCount(metrics,true);
file=char(file); [folder,name,extension]=fileparts(file);
if isempty(folder), folder=pwd; end
if ~ismember(lower(extension),{'.mat','.json','.nwb'})
    error('ce:io:UnsupportedFormat','Unsupported cell metrics file format: %s.',file);
end
if ~isfolder(folder) || isfolder(file)
    error('ce:io:InvalidDestination','Destination must be a file in an existing directory: %s.',file);
end
if nargin<3
    expectedHash='';
    if isfile(file), expectedHash=ce.pipeline.fileFingerprint(file); end
end
ce.curation.verifyFileRevision(file,expectedHash);
result=struct('saved',false,'backup','','file',char(java.io.File(file).getCanonicalPath), ...
    'previousHash',expectedHash,'hash','');
if ~isempty(expectedHash)
    if ~strcmpi(extension,'.mat')
        error('ce:curation:UnverifiableDestination','Existing non-MAT exports cannot be identity-checked; choose a new filename.');
    end
    previous=ce.io.readCellMetrics(file);
    ce.curation.assertSnapshotIdentity(previous,metrics);
    ce.curation.verifyFileRevision(file,expectedHash);
    result.backup=ce.curation.backupMetricFile(file,expectedHash,previous);
end
% Inner format writer verifies staged contents; the outer verifier checks the
% original destination after staging and immediately before replacement.
ce.io.writeAtomic(file,@(temporary) ce.io.saveCellMetrics(metrics,temporary), ...
    @verifyReplacement);
result.saved=true;

    function verifyReplacement(temporary)
        ce.curation.verifyFileRevision(file,expectedHash);
        result.hash=ce.pipeline.fileFingerprint(temporary);
    end
end
