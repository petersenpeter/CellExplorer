function selection = validateMonoSynSelection(mono, automatic)
%VALIDATEMONOSYNSELECTION Reviewed pairs must belong to the detected candidates.
selection.excitatory = mono.sig_con_excitatory;
if ~isequal(mono.sig_con,selection.excitatory)
    error('ce:curation:InconsistentMonoSynAliases','sig_con and sig_con_excitatory must agree.');
end
selection.inhibitory = zeros(0,2);
if isfield(mono,'sig_con_inhibitory'), selection.inhibitory = mono.sig_con_inhibitory; end
for type = {'excitatory','inhibitory'}
    value = selection.(type{1});
    candidates = zeros(0,2);
    name = ['sig_con_',type{1},'_all'];
    if isfield(automatic,name), candidates = automatic.(name); end
    if isempty(value), value = zeros(0,2); end
    if isempty(candidates), candidates = zeros(0,2); end
    if ~isnumeric(value) || ~isreal(value) || size(value,2) ~= 2 || ...
            any(~isfinite(value(:)) | value(:) < 1 | value(:) ~= fix(value(:))) || ...
            size(unique(value,'rows'),1) ~= size(value,1) || ~all(ismember(value,candidates,'rows'))
        error('ce:curation:InvalidMonoSynSelection','Reviewed %s pairs must be unique detected candidates.',type{1});
    end
    selection.(type{1}) = value;
end
end
