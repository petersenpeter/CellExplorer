function [inputs, session, importArgs] = spikeImportInputs(session, options)
%SPIKEIMPORTINPUTS Resolve and hash every consumed sorting input.
if ~isstruct(options) || ~isscalar(options)
    error('ce:pipeline:InvalidSpikeImport','spikeImport must be a scalar options struct.');
end
format = '';
if isfield(options,'format')
    format = options.format; options = rmfield(options,'format');
elseif isfield(session,'spikeSorting') && iscell(session.spikeSorting) && ~isempty(session.spikeSorting) && ...
        isstruct(session.spikeSorting{1}) && isfield(session.spikeSorting{1},'format')
    format = session.spikeSorting{1}.format;
end
if ~ischar(format) || ~ismember(lower(format),{'neurosuite','klustakwik','phy'})
    error('ce:pipeline:UnsupportedSpikeImport','Managed spike import supports Neurosuite/Klustakwik and Phy.');
end
allowed={'clusteringpath','raw_clusters','getWaveformsFromSource'};
if strcmpi(format,'phy'), allowed=[allowed,{'labelsToRead'}];
else, allowed=[allowed,{'electrodeGroups','LSB'}]; end
if ~all(ismember(fieldnames(options),allowed))
    error('ce:pipeline:InvalidSpikeImport','Unsupported spikeImport option for this format.');
end
names = fieldnames(options); importArgs = cell(1,2*numel(names));
for index = 1:numel(names)
    importArgs{2*index-1} = names{index}; importArgs{2*index} = options.(names{index});
end
if strcmpi(format,'phy')
    plan=ce.io.phyImportPlan(session,importArgs{:});
    inputs.format='phy'; inputs.basename=plan.basename; inputs.sr=session.extracellular.sr;
    inputs.labelsToRead=plan.options.labelsToRead;
    inputs.files=plan.files;
    for index=1:numel(plan.files)
        inputs.files(index).hash=ce.pipeline.fileFingerprint(plan.files(index).file);
    end
    identitySources=inputs.files(ismember({inputs.files.kind},{'clusters','times','labels'}));
    identitySources=rmfield(identitySources,'file');
    inputs.membershipHash=ce.pipeline.fingerprint(struct('schemaVersion',1,'format','phy', ...
        'sr',inputs.sr,'labelsToRead',{inputs.labelsToRead},'sources',identitySources));
    if plan.plugins
        fields={'nChannels','nElectrodeGroups','electrodeGroups'};
    elseif any(strcmp({inputs.files.kind},'info'))
        fields={'nChannels'};
    else
        fields={};
    end
    for key=fields
        if isfield(session.extracellular,key{1}), inputs.extracellular.(key{1})=session.extracellular.(key{1}); end
    end
    return
end
plan = ce.io.neurosuiteImportPlan(session,importArgs{:});
inputs.format = 'neurosuite'; inputs.basename = plan.basename;
inputs.sr = session.extracellular.sr;
inputs.electrodeGroups = plan.electrodeGroups;
inputs.rawClusters = plan.options.raw_clusters;
inputs.sourceWaveforms = plan.options.getWaveformsFromSource;
inputs.files = plan.files;
for index = 1:numel(plan.files)
    inputs.files(index).hash = ce.pipeline.fileFingerprint(plan.files(index).file);
end
% Sorting membership excludes waveform scaling/bytes and file locations. Those
% still participate in the stage input hash and therefore invalidate its cache.
identitySources = rmfield(inputs.files,'file');
identitySources = identitySources(~strcmp({identitySources.kind},'spk'));
membership = struct('schemaVersion',1,'format',inputs.format,'sr',inputs.sr, ...
    'electrodeGroups',inputs.electrodeGroups,'rawClusters',inputs.rawClusters,'sources',identitySources);
inputs.membershipHash = ce.pipeline.fingerprint(membership);
if inputs.sourceWaveforms
    inputs.scale = plan.scale;
    inputs.channels = session.extracellular.electrodeGroups.channels(plan.electrodeGroups);
    inputs.nChannels = session.extracellular.nChannels;
end
end
