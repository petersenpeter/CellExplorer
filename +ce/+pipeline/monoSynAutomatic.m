function automatic = monoSynAutomatic(mono)
%MONOSYNAUTOMATIC Project scientific detection outputs, excluding manual choices.
required = {'ccgR','n','Pred','Bounds','completeIndex','binSize','duration','conv_w', ...
    'Pcausal','sig_con_excitatory_all'};
if ~isstruct(mono) || ~isscalar(mono) || ~all(isfield(mono,required))
    error('ce:pipeline:InvalidMonoSynDetection','Monosynaptic detection is missing required automatic outputs.');
end
automatic = struct();
for name = [required, {'sig_con_inhibitory_all','FalsePositive','TruePositive'}]
    if isfield(mono,name{1}), automatic.(name{1}) = mono.(name{1}); end
end
% The review GUI adds empty inhibitory fields even when detection was disabled.
% Canonical empty candidate lists keep that presentation change out of cache keys.
for name = {'sig_con_excitatory_all','sig_con_inhibitory_all'}
    if ~isfield(automatic,name{1}) || isempty(automatic.(name{1}))
        automatic.(name{1}) = zeros(0,2);
    end
end
end
