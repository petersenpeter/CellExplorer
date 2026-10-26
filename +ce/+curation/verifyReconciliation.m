function verifyReconciliation(plan)
%VERIFYRECONCILIATION Reject input changes during reading, decisions or UI apply.
for k=1:numel(plan.files)
    ce.curation.verifyFileRevision(plan.files{k},plan.hashes{k});
end
end
