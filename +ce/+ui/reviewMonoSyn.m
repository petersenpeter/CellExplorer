function mono = reviewMonoSyn(mono)
%REVIEWMONOSYN Keep interactive review separate from detection and persistence.
automatic = ce.pipeline.monoSynAutomatic(mono);
mono = gui_MonoSyn(mono); % Struct input: the GUI cannot write a file itself.
selection = ce.curation.validateMonoSynSelection(mono,automatic);
mono.processinginfo.review.status = 'review_returned';
mono.processinginfo.review.recordedAt = now;
mono.processinginfo.review.selectionHash = ce.pipeline.fingerprint(selection);
end
