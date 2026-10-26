function patch = monoSynMetrics(inputs, settings)
%MONOSYNMETRICS Project accepted pairs; retain legacy transmission formulas.
% In/out counts retain the established excitatory-only convention.
count = numel(inputs.UID);
excitatory = inputs.selection.excitatory;
inhibitory = inputs.selection.inhibitory;
patch.putativeConnections.excitatory = excitatory;
patch.putativeConnections.inhibitory = inhibitory;
patch.synapticEffect = repmat({'Unknown'},1,count);
patch.synapticEffect(excitatory(:,1)) = repmat({'Excitatory'},1,size(excitatory,1));
patch.synapticEffect(inhibitory(:,1)) = repmat({'Inhibitory'},1,size(inhibitory,1));
patch.synapticConnectionsOut = zeros(1,count);
patch.synapticConnectionsIn = zeros(1,count);
if ~isempty(excitatory)
    [a,b] = hist(excitatory(:,1),unique(excitatory(:,1)));
    patch.synapticConnectionsOut(b) = a;
    [a,b] = hist(excitatory(:,2),unique(excitatory(:,2)));
    patch.synapticConnectionsIn(b) = a;
end
ccg = inputs.ccgR;
ccg(isnan(ccg)) = 0;
for type = {'excitatory','inhibitory'}
    pairs = inputs.selection.(type{1});
    for index = 1:size(pairs,1)
        reference = pairs(index,1); target = pairs(index,2);
        patch.putativeConnections.([type{1},'TransProb'])(index) = ...
            ce_GetTransProb(ccg(:,reference,target),inputs.total(reference),inputs.binSize,settings.convolutionWindow);
    end
end
end
