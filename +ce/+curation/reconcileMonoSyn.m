function [mono, retained] = reconcileMonoSyn(previous, automatic, provenance)
%RECONCILEMONOSYN Carry manual selections only across an identical detection context.
mono = automatic;
mono.sig_con = automatic.sig_con_excitatory_all;
mono.sig_con_excitatory = mono.sig_con;
if isfield(automatic,'sig_con_inhibitory_all')
    mono.sig_con_inhibitory = automatic.sig_con_inhibitory_all;
end
retained = false;
old = ce.pipeline.outputSnapshot(previous,{'processinginfo.detection'});
keys = {'schemaVersion','stageVersion','definitionHash','inputHash','parameterHash', ...
    'implementationHash','environmentHash','outputHash'};
if old.present && isstruct(old.value) && isscalar(old.value)
    retained = all(isfield(old.value,keys)) && all(isfield(provenance,keys));
    for index = 1:numel(keys)
        if ~retained || ~isequaln(old.value.(keys{index}),provenance.(keys{index}))
            retained = false; break
        end
    end
end
if retained
    ce.curation.validateMonoSynSelection(previous,automatic);
    for name = {'sig_con','sig_con_excitatory','sig_con_inhibitory','manualEdit'}
        if isfield(previous,name{1}), mono.(name{1}) = previous.(name{1}); end
    end
    mono.processinginfo = previous.processinginfo;
else
    mono.processinginfo.review.status = 'automatic';
    if ~isempty(fieldnames(previous))
        mono.processinginfo.review.status = 'new_detection_previous_not_applied';
    end
end
mono.processinginfo.detection = provenance;
selection = ce.curation.validateMonoSynSelection(mono,automatic);
hash = ce.pipeline.fingerprint(selection);
review = ce.pipeline.outputSnapshot(mono,{'processinginfo.review'});
if retained && (~review.present || ~isfield(review.value,'selectionHash') || ~strcmp(review.value.selectionHash,hash))
    mono.processinginfo.review.status = 'external_selection_preserved';
    mono.processinginfo.review.recordedAt = now;
end
mono.processinginfo.review.selectionHash = hash;
end
