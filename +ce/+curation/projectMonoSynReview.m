function metrics = projectMonoSynReview(metrics, selection)
%PROJECTMONOSYNREVIEW Project reviewed pairs using legacy effect/count rules.
count=ce.data.metricCellCount(metrics);
for kind={'excitatory','inhibitory'}
    name=kind{1}; pairs=selection.(name);
    probability=[name,'TransProb'];
    if isfield(metrics,'putativeConnections') && isfield(metrics.putativeConnections,probability)
        previous=metrics.putativeConnections.(name); values=metrics.putativeConnections.(probability);
        [found,order]=ismember(pairs,previous,'rows');
        if numel(values)==size(previous,1) && all(found)
            metrics.putativeConnections.(probability)=reshape(values(order),1,[]);
        else
            metrics.putativeConnections=rmfield(metrics.putativeConnections,probability);
        end
    end
    metrics.putativeConnections.(name)=pairs;
end
metrics.synapticEffect=repmat({'Unknown'},1,count);
metrics.synapticEffect(selection.excitatory(:,1))={'Excitatory'};
metrics.synapticEffect(selection.inhibitory(:,1))={'Inhibitory'};
metrics.synapticConnectionsOut=zeros(1,count); metrics.synapticConnectionsIn=zeros(1,count);
if ~isempty(selection.excitatory)
    [a,b]=hist(selection.excitatory(:,1),unique(selection.excitatory(:,1))); metrics.synapticConnectionsOut(b)=a;
    [a,b]=hist(selection.excitatory(:,2),unique(selection.excitatory(:,2))); metrics.synapticConnectionsIn(b)=a;
    % Retain the viewer's legacy truncation for hist's scalar-bin convention.
    metrics.synapticConnectionsOut=metrics.synapticConnectionsOut(1:count);
    metrics.synapticConnectionsIn=metrics.synapticConnectionsIn(1:count);
end
end
