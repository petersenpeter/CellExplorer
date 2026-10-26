function updated = applyMonoSynReview(viewer, metrics, indices)
%APPLYMONOSYNREVIEW Map a saved session projection into the current viewer.
order=ce.curation.annotationOrder(metrics,viewer,indices);
updated=viewer;
for key={'synapticEffect','synapticConnectionsOut','synapticConnectionsIn'}
    updated.(key{1})(order)=metrics.(key{1});
end
for kind={'excitatory','inhibitory'}
    name=kind{1}; previous=zeros(0,2);
    if isfield(updated,'putativeConnections') && isfield(updated.putativeConnections,name)
        previous=updated.putativeConnections.(name);
    end
    keep=~any(ismember(previous,order),2);
    pairs=metrics.putativeConnections.(name);
    mapped=reshape(order(pairs),size(pairs));
    updated.putativeConnections.(name)=[previous(keep,:);mapped];
    probability=[name,'TransProb'];
    if isfield(updated.putativeConnections,probability)
        values=updated.putativeConnections.(probability);
        if numel(values)==size(previous,1) && isfield(metrics.putativeConnections,probability)
            updated.putativeConnections.(probability)=[reshape(values(keep),1,[]),metrics.putativeConnections.(probability)];
        else
            updated.putativeConnections=rmfield(updated.putativeConnections,probability);
        end
    end
end
if isfield(updated.general,'batch')
    session=updated.batchIDs(order(1));
    updated.general.batch{session}.processinginfo.monosynapticReview=metrics.general.processinginfo.monosynapticReview;
else
    updated.general.processinginfo.monosynapticReview=metrics.general.processinginfo.monosynapticReview;
end
end
