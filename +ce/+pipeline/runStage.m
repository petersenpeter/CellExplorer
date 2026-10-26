function [metrics, result] = runStage(metrics, definition, inputs, settings, operation, force, retiredOutputs)
%RUNSTAGE Verify a stage cache or compute/merge a patch and record provenance.
% No files are written. A failed operation returns original metrics and a failed
% result. The caller decides how to surface failure and whether to persist.
if nargin < 6, force = false; end
if nargin < 7, retiredOutputs = {}; end
result = ce.pipeline.stageResult(definition.name,'failed','');
timer = tic;
try
    signature.schemaVersion = 1;
    signature.name = definition.name;
    signature.stageVersion = definition.version;
    signature.definitionHash = ce.pipeline.fingerprint(definition);
    signature.ownedOutputs = definition.outputs;
    signature.inputHash = ce.pipeline.fingerprint(inputs);
    signature.settings = settings;
    signature.parameterHash = ce.pipeline.fingerprint(settings);
    signature.environment = ce.pipeline.environment;
    signature.environmentHash = ce.pipeline.fingerprint(signature.environment);
    dependencies = [definition.dependencies, {'ce.pipeline.runStage','ce.pipeline.fingerprint','ce.pipeline.outputSnapshot','ce.pipeline.withRandomSeed'}];
    implementation = struct();
    for index = 1:numel(dependencies)
        file = which(dependencies{index});
        if isempty(file) || ~isfile(file)
            error('ce:pipeline:MissingImplementation','Cannot fingerprint dependency %s.',dependencies{index});
        end
        implementation(index).name = dependencies{index};
        implementation(index).hash = ce.pipeline.fileFingerprint(file);
    end
    signature.implementation = implementation;
    signature.implementationHash = ce.pipeline.fingerprint(implementation);
    previous = ce.pipeline.outputSnapshot(metrics,{['general.processinginfo.stages.',definition.name]});
    outputs = ce.pipeline.outputSnapshot(metrics,definition.outputs);
    required = ce.pipeline.outputSnapshot(metrics,definition.requiredOutputs);
    reason = 'missing_provenance';
    if force
        reason = 'forced';
    elseif previous.present && isstruct(previous.value) && isscalar(previous.value)
        old = previous.value;
        fields = {'schemaVersion','stageVersion','definitionHash','inputHash','parameterHash','implementationHash','environmentHash'};
        reason = '';
        for index = 1:numel(fields)
            name = fields{index};
            if ~isfield(old,name) || ~isequal(old.(name),signature.(name))
                reason = ['changed_',name]; break
            end
        end
        if isempty(reason) && (~all([required.present]) || ~isfield(old,'outputHash') || ...
                ~strcmp(old.outputHash,ce.pipeline.fingerprint(outputs)))
            reason = 'changed_outputs';
        end
        if isempty(reason)
            result.status = 'reused';
            result.reason = 'matching_fingerprints';
            result.provenance = old; % Keep the original generation date/configuration.
            result.elapsedSeconds = toc(timer);
            return
        end
    end
    result.reason = reason;
    warningState = warning;
    warningCleanup = onCleanup(@() warning(warningState));
    patch = ce.pipeline.withRandomSeed(settings.randomSeed,operation);
    if ~isstruct(patch) || ~isscalar(patch)
        error('ce:pipeline:InvalidStageOutput','Stage %s must return a scalar struct patch.',definition.name);
    end
    candidate = metrics;
    removeOutputs = unique([definition.outputs,retiredOutputs]);
    for index = 1:numel(removeOutputs)
        candidate = removePath(candidate,strsplit(removeOutputs{index},'.'));
    end
    candidate = merge(candidate,patch);
    required = ce.pipeline.outputSnapshot(candidate,definition.requiredOutputs);
    produced = ce.pipeline.outputSnapshot(patch,definition.requiredOutputs);
    if ~all([required.present]) || ~all([produced.present])
        error('ce:pipeline:MissingStageOutput','Stage %s did not produce all required outputs.',definition.name);
    end
    signature.outputHash = ce.pipeline.fingerprint(ce.pipeline.outputSnapshot(candidate,definition.outputs));
    signature.createdAt = now;
    signature.repositoryRevision = ce.pipeline.repositoryRevision;
    candidate.general.processinginfo.stages.(definition.name) = signature;
    metrics = candidate;
    result.status = 'completed';
    result.provenance = signature;
catch exception
    result.error.identifier = exception.identifier;
    result.error.message = exception.message;
    result.error.stack = exception.stack;
end
result.elapsedSeconds = toc(timer);
end

function value = removePath(value,parts)
if ~isstruct(value) || ~isscalar(value) || ~isfield(value,parts{1}), return; end
if numel(parts) == 1
    value = rmfield(value,parts{1});
else
    value.(parts{1}) = removePath(value.(parts{1}),parts(2:end));
end
end

function target = merge(target,patch)
names = fieldnames(patch);
for index = 1:numel(names)
    name = names{index};
    value = patch.(name);
    if isstruct(value) && isscalar(value) && isfield(target,name) && isstruct(target.(name)) && isscalar(target.(name))
        target.(name) = merge(target.(name),value);
    else
        target.(name) = value;
    end
end
end
