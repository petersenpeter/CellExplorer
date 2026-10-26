function patch = stateMetrics(inputs)
%STATEMETRICS Retain the legacy ISI/CV2/state indexing and duration conventions.
% Alignment/formula changes require a separate scientific validation milestone.
spikes = inputs.spikes;
patch.general.states = struct();
allspikes.ISIs = cellfun(@diff,spikes.times,'UniformOutput',false);
allspikes.meanISI = cellfun(@(X) (X(1:end-1)+X(2:end))./2,allspikes.ISIs,'UniformOutput',false);
allspikes.CV2 = cellfun(@(X) 2.*abs(X(2:end)-X(1:end-1))./(X(2:end)+X(1:end-1)),allspikes.ISIs,'UniformOutput',false);
allspikes.times = cellfun(@(X) X(2:end-1),spikes.times,'UniformOutput',false);
allspikes.ISIs_bursts = cellfun(@(X) any([X(1:end-1),X(2:end)] < 0.006,2),allspikes.ISIs,'UniformOutput',false);
allspikes.ISIs = cellfun(@(X) X(1:end-1),allspikes.ISIs,'UniformOutput',false);
for record = inputs.records
    states = record.data.ints;
    patch.general.states.(record.name) = states;
    for name = fieldnames(states)'
        intervals = states.(name{1});
        if isempty(intervals), continue; end
        statespikes = cellfun(@(X) ce_InIntervals(X,double(intervals)),allspikes.times,'UniformOutput',false);
        patch.(['firingRate_',name{1}]) = cellfun(@(X) sum(X),statespikes) / sum(diff(intervals'));
        ISIs = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.ISIs,statespikes,'UniformOutput',false);
        patch.(['firingRateISI_',name{1}]) = 1./cellfun(@median,ISIs);
        CV2 = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.CV2,statespikes,'UniformOutput',false);
        patch.(['cv2_',name{1}]) = cellfun(@(X) mean(X(X<1.95)),CV2);
        bursts = cellfun(@(X,Y) X(Y(2:end-1)),allspikes.ISIs_bursts,statespikes,'UniformOutput',false);
        patch.(['burstIndex_',name{1}]) = cellfun(@(X) sum(X)/length(X),bursts);
    end
end
end
