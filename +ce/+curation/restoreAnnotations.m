function updated = restoreAnnotations(metrics, backup, indices)
%RESTOREANNOTATIONS Prepare an identity-checked restore without changing inputs.
% Legacy count-only backups cannot prove identity and are rejected.
if nargin<3, indices=1:numel(metrics.UID); end
indices=reshape(indices,1,[]);
target=ce.curation.captureAnnotations(metrics,indices);
if ~isfield(backup,'UID')
    error('ce:curation:MissingIdentity','This backup lacks cell IDs. Reconcile it explicitly; cell counts alone cannot establish identity.');
end
restored=ce.curation.applyAnnotations(target,backup,1:numel(backup.UID));
updated=metrics;
for key={'labels','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType'}
    name=key{1};
    if isfield(backup,name)
        if ~isfield(updated,name) && numel(indices)~=numel(metrics.UID)
            error('ce:curation:InvalidAnnotations','Cannot add %s to only part of a batch.',name);
        end
        updated.(name)(indices)=restored.(name);
    end
end
for key={'groups','tags','groundTruthClassification'}
    name=key{1};
    if ~isfield(backup,name), continue; end
    if ~isfield(updated,name), updated.(name)=struct(); end
    for group=fieldnames(updated.(name))'
        updated.(name).(group{1})=setdiff(updated.(name).(group{1}),indices);
    end
    for group=fieldnames(restored.(name))'
        members=indices(restored.(name).(group{1}));
        if isfield(updated.(name),group{1}), members=[updated.(name).(group{1})(:)',members]; end
        updated.(name).(group{1})=unique(members);
    end
end
end
