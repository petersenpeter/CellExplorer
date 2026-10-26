function state = open(metrics)
%OPEN Capture recovery baselines without creating directories or writing files.
sources=ce.curation.recovery.sources(metrics);
state=struct('source',{},'indices',{},'baseline',{},'diskBaseline',{},'sourceHash',{},'file',{}, ...
    'writtenHash',{},'contentHash',{},'recovered',{});
owner=char(java.util.UUID.randomUUID);
for index=1:numel(sources)
    source=sources(index).file; [folder,name]=fileparts(source);
    baseline=ce.curation.captureAnnotations(metrics,sources(index).indices);
    hash=''; diskBaseline=[];
    if isfile(source)
        hash=ce.pipeline.fileFingerprint(source);
        diskBaseline=ce.curation.captureAnnotations(ce.io.readCellMetrics(source));
        ce.curation.annotationOrder(diskBaseline,metrics,sources(index).indices);
        ce.curation.verifyFileRevision(source,hash);
    end
    state(index)=struct('source',source,'indices',sources(index).indices,'baseline',baseline, ...
        'diskBaseline',diskBaseline,'sourceHash',hash,'file',fullfile(folder,'.cellexplorer','recovery',[name,'.',owner,'.mat']), ...
        'writtenHash','','contentHash','','recovered',struct('file',{},'hash',{}));
end
end
