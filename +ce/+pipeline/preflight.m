function [report, context] = preflight(varargin)
%PREFLIGHT Read-only checks before running ProcessCellMetrics headlessly.
% [report, context] = ce.pipeline.preflight('basepath', path, ...)
% Uses the pipeline's name/value options; headless defaults to true here.
% Supplied/cached spikes or explicit managed Neurosuite/Phy import are supported.
% Managed import computes read-only candidates and verifies source/cache content.
parameters = ce.pipeline.parseParameters('headless',true,varargin{:});
report = ce.data.validationReport;
checks = report.checks;
context = struct('session',[],'spikes',[],'parameters',parameters);
context.spikeImport = [];
context.sortingRevision = '';
requiredToolboxes = {};
if ~isempty(parameters.sessionID) || ~isempty(parameters.sessionName)
    add('LocalSessionRequired','session','error','Preflight requires a local basepath or session struct; resolve database metadata first.');
    finish; return
end
session = parameters.session;
if isempty(session)
    basepath = parameters.basepath;
    if ~isfolder(basepath)
        add('MissingBasepath','basepath','error',['Directory does not exist: ',basepath]);
        finish; return
    end
    basename = ce.io.basenameFromBasepath(basepath);
    file = fullfile(basepath,[basename,'.session.mat']);
    if ~isfile(file), file = fullfile(basepath,'session.mat'); end
    if ~isfile(file)
        add('MissingSession','session','error','Create a basename.session.mat file or provide a session struct; no metadata dialog will be opened.');
        finish; return
    end
    try
        data = load(file,'session');
        if ~isfield(data,'session') || ~isstruct(data.session) || ~isscalar(data.session)
            error('ce:pipeline:InvalidSessionFile','The MAT file must contain a scalar session struct.');
        end
        session = data.session;
        if isfield(session,'general') && isstruct(session.general) && isscalar(session.general)
            % A local copy may legitimately have moved since the metadata was saved.
            session.general.basePath = basepath;
        end
    catch exception
        add('UnreadableSession','session','error',exception.message);
        finish; return
    end
end
metadata = ce.data.validateSession(session);
checks = [checks, metadata.checks];
if ~metadata.valid
    finish; return
end
basepath = char(session.general.basePath);
basename = char(session.general.name);
session.general.basePath = basepath;
session.general.name = basename;
% Empty optional containers let existing stages inspect their fields safely.
for field = {'channelTags','analysisTags'}
    if ~isfield(session,field{1}) || isempty(session.(field{1}))
        session.(field{1}) = struct();
    end
end
context.session = session;
for functionName = {'preferences_ProcessCellMetrics','generateSpinDices','dispLog'}
    requireFunction(functionName{1},false);
end

for field = {'restrictToIntervals','excludeIntervals'}
    value = parameters.(field{1});
    if ~isempty(value) && (~isnumeric(value) || ~isreal(value) || ~ismatrix(value) || size(value,2) ~= 2 || ...
            any(~isfinite(value(:))) || any(value(:,1) < 0 | value(:,2) <= value(:,1)))
        add('InvalidIntervals',field{1},'error','Use finite Nx2 intervals in seconds, with 0 <= start < stop.');
    end
end
if ~strcmpi(parameters.fileFormat,'mat')
    add('UnsupportedPipelineFormat','fileFormat','error','Headless processing currently requires MAT cache files. Export JSON/NWB separately with ce.io.saveCellMetrics.');
end
if parameters.headless && parameters.submitToDatabase
    add('InteractiveIntegration','submitToDatabase','error','Submit to the database separately after the headless computation.');
end
if parameters.forceReloadSpikes && isempty(parameters.spikeImport)
    add('ImportRequired','forceReloadSpikes','error','Import or refresh source spike sorting separately, then supply the resulting spikes or cache.');
end
if ~isstruct(session.analysisTags) || ~isscalar(session.analysisTags)
    add('InvalidAnalysisTags','analysisTags','error','Provide a scalar analysisTags struct.');
elseif parameters.headless && isfield(session.analysisTags,'preferences_ProcessCellMetrics') && ...
        ~isempty(session.analysisTags.preferences_ProcessCellMetrics)
    add('UnverifiedExtension','analysisTags.preferences_ProcessCellMetrics','error', ...
        'Custom preference callbacks are not yet covered by the headless contract; use the interactive pipeline for this session.');
end
knownMetrics = {'all','other_metrics','waveform_metrics','PCA_features','acg_metrics', ...
    'monoSynaptic_connections','deepSuperficial','theta_metrics','spatial_metrics', ...
    'event_metrics','manipulation_metrics','state_metrics','psth_metrics'};
names = ce.pipeline.customCalculationNames;
for index = 1:numel(names)
    name = names{index};
    knownMetrics{end+1} = name; %#ok<AGROW>
    if parameters.headless && selected(name)
        add('UnverifiedExtension',['customCalculations.',name],'error', ...
            'Exclude this custom calculation or run interactively; its headless behavior has not been declared.');
    end
end
requested = parameters.metrics;
if ischar(requested), requested = cellstr(requested); end
unknown = setdiff([requested(:);parameters.excludeMetrics(:)], [knownMetrics,{'none'}]);
for index = 1:numel(unknown)
    add('UnknownMetric','metrics','error',['Unknown metric selection: ',unknown{index},'. Use a supported metric or custom calculation name.']);
end

spikes = parameters.spikes;
if ~isempty(parameters.spikeImport)
    if ~parameters.headless || ~isempty(parameters.spikes)
        add('InvalidSpikeImport','spikeImport','error','Managed import requires headless=true and cannot be combined with supplied spikes.');
    else
        try
            [spikes,result,cache,pending] = ce.pipeline.prepareSpikeImport(session,parameters.spikeImport,parameters.forceReloadSpikes);
            context.spikeImport = struct('result',result,'cache',cache,'pending',pending);
        catch exception
            add('SpikeImportFailed','spikeImport','error',exception.message);
        end
    end
elseif isempty(spikes)
    file = fullfile(basepath,[basename,'.spikes.cellinfo.mat']);
    if ~isfile(file)
        add('MissingSpikes','spikes','error', ...
            ['Supply spikes or import sorting outputs first to create ',file,'. Headless mode does not invoke interactive importers.']);
    else
        try
            data = load(file,'spikes');
            if ~isfield(data,'spikes'), error('ce:pipeline:InvalidSpikesFile','No spikes variable in the cache.'); end
            spikes = data.spikes;
        catch exception
            add('UnreadableSpikes','spikes','error',exception.message);
        end
    end
end
if ~isempty(spikes)
    validateSpikes;
    try
        context.sortingRevision = ce.pipeline.spikeSortingRevision(spikes);
    catch exception
        add('InvalidSortingRevision','spikes','error',exception.message);
    end
end
context.spikes = spikes;

raw = [basename,'.dat'];
if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
    raw = char(session.extracellular.fileName);
end
if parameters.getWaveformsFromDat
    requireFile(fullfile(basepath,raw),'rawData','Raw data is required when getWaveformsFromDat is enabled; disable it to use cached waveforms.');
    if ~isfield(session.extracellular,'precision') || ~ischar(session.extracellular.precision) || isempty(session.extracellular.precision)
        add('MissingPrecision','extracellular.precision','error','Define the raw sample type (for example int16).');
    elseif selected('waveform_metrics') && ~strcmp(session.extracellular.precision,'int16')
        add('UnsupportedRawPrecision','extracellular.precision','error','Managed waveform extraction requires int16; the legacy extractor assumes two bytes per sample.');
    end
    requiredToolboxes = [requiredToolboxes, {'Signal Processing Toolbox','Curve Fitting Toolbox'}];
end
if selected('waveform_metrics') || selected('acg_metrics')
    requiredToolboxes = [requiredToolboxes, {'Curve Fitting Toolbox','Statistics and Machine Learning Toolbox'}];
end
if selected('monoSynaptic_connections')
    requiredToolboxes{end+1} = 'Statistics and Machine Learning Toolbox';
    for dependencyName = {'ce_MonoSynConvClick','ce_cch_conv','ce_InIntervals','ce_GetTransProb','isdmatrix','isdvector','isdscalar'}
        requireFunction(dependencyName{1},false);
    end
end
needsCCG = selected('acg_metrics') || selected('monoSynaptic_connections') || selected('event_metrics') || ...
    selected('manipulation_metrics');
if needsCCG
    requireFunction('CCG',false);
    requireFunction('CCGHeart',true);
end
if selected('event_metrics') || selected('manipulation_metrics')
    requiredToolboxes{end+1} = 'Statistics and Machine Learning Toolbox';
    for dependencyName = {'calc_PSTH','nanconv','ce_gausswin','isdscalar','isdvector'}
        requireFunction(dependencyName{1},false);
    end
end
if selected('state_metrics')
    requireFunction('ce_InIntervals',false);
    requireFunction('isdmatrix',false);
end
if selected('spatial_metrics')
    for dependencyName = {'place_cell_condition','SpatialCoherence','nanconv'}
        requireFunction(dependencyName{1},false);
    end
end
if selected('monoSynaptic_connections') || selected('state_metrics') || ~isempty(parameters.restrictToIntervals) || ~isempty(parameters.excludeIntervals) || parameters.excludeManipulationIntervals
    requireFunction('FindInInterval',true);
end
if selected('deepSuperficial')
    try
        ce.pipeline.deepSuperficialInput(session);
    catch exception
        code = 'InvalidDeepSuperficialInput';
        if strcmp(exception.identifier,'ce:pipeline:DeepSuperficialPreparationRequired')
            code = 'InteractivePreparationRequired';
        end
        add(code,'deepSuperficial','error',exception.message);
    end
end
if selected('theta_metrics')
    requireFunction('nanconv',false);
    if isfield(session.channelTags,'Theta') && isfile(fullfile(basepath,[basename,'.animal.behavior.mat']))
        requiredToolboxes = [requiredToolboxes, {'Signal Processing Toolbox','Image Processing Toolbox'}];
        requireFunction('ce_gausswin',false);
        try
            ce.pipeline.thetaRecording(session,false); % Check framing, not the full LFP hash in preflight.
            ce.pipeline.thetaBehavior(session);
        catch exception
            add('InvalidThetaInput','theta_metrics','error',exception.message);
        end
    end
end
installed = ver;
requiredToolboxes = unique(requiredToolboxes,'stable');
for index = 1:numel(requiredToolboxes)
    if ~ismember(requiredToolboxes{index},{installed.Name})
        add('MissingToolbox','dependencies','error',['Install ',requiredToolboxes{index},' or exclude the stage that requires it.']);
    end
end

% Partial metric runs need existing fields used by the legacy finalization and
% classification steps. Check them before expensive computation.
cached = struct();
metricsFile = fullfile(basepath,[basename,'.',parameters.saveAs,'.cellinfo.mat']);
if ~isfile(metricsFile), metricsFile = fullfile(basepath,[parameters.saveAs,'.mat']); end
if isfile(metricsFile) && ~parameters.forceReload
    try
        data = load(metricsFile,'cell_metrics');
        if isfield(data,'cell_metrics'), cached = data.cell_metrics; end
    catch exception
        add('UnreadableMetrics','cell_metrics','error',exception.message);
    end
end
if ~isstruct(cached) || ~isscalar(cached)
    add('InvalidMetrics','cell_metrics','error','The metrics cache must contain a scalar cell_metrics struct.');
else
    if ~isempty(fieldnames(cached)) && isstruct(spikes) && isscalar(spikes) && isfield(spikes,'UID')
        try
            cachedRevision = ce.data.metricSortingRevision(cached);
            if ~strcmp(cachedRevision,context.sortingRevision)
                add('SortingRevisionMismatch','cell_metrics.general.sortingRevision','error', ...
                    'Sorting revisions differ or one is missing. Use a new saveAs or explicitly recompute all required metrics; matching UIDs do not establish unchanged sorting.');
            end
        catch exception
            add('InvalidSortingRevision','cell_metrics.general.sortingRevision','error',exception.message);
        end
        if ~isfield(cached,'UID') || ~isequal(cached.UID,spikes.UID) || ...
                isfield(cached,'cluID') && isfield(spikes,'cluID') && ~isequal(cached.cluID,spikes.cluID)
            add('CacheIdentityMismatch','cell_metrics.UID','error', ...
                'Cached metrics and spikes have different cell identities/order. Recompute all required metrics with forceReload, preserving curation separately.');
        end
    end
    if ~selected('waveform_metrics') && ~isfield(cached,'waveforms')
        add('MissingCachedMetric','waveforms','error','Select waveform_metrics or provide a cache containing waveforms.');
    end
    if ~parameters.keepCellClassification || ~isfield(cached,'putativeCellType')
        if ~selected('acg_metrics') && ~isfield(cached,'acg_tau_rise')
            add('MissingCachedMetric','acg_tau_rise','error','Standard classification requires acg_metrics or cached acg_tau_rise.');
        end
        if ~selected('waveform_metrics') && ~isfield(cached,'troughToPeak')
            add('MissingCachedMetric','troughToPeak','error','Standard classification requires waveform_metrics or cached troughToPeak.');
        end
    end
end
if isstruct(cached) && isscalar(cached)
    try
        ce.pipeline.intervalStagePlans(cached,session,parameters,[]);
        if parameters.excludeManipulationIntervals
            ce.pipeline.intervalFiles(session,'manipulation_metrics',parameters.ignoreManipulationTypes);
        end
    catch exception
        add('InvalidIntervalInput','intervalStages','error',exception.message);
    end
end
if isstruct(spikes) && isscalar(spikes) && isfield(spikes,'UID')
    % CellClass import is unconditional in the legacy pipeline, including partial
    % metric runs. Validate it before any expensive calculations or saving.
    try
        ce.pipeline.cellClassInput(session,spikes);
    catch exception
        add('InvalidCellClassInput','CellClass','error',exception.message);
    end
    for kind = {'spatial_metrics','psth_metrics'}
        if ~selected(kind{1}), continue; end
        try
            ce.pipeline.importedCellFiles(session,kind{1},spikes);
        catch exception
            add('InvalidCellImport',kind{1},'error',exception.message);
        end
    end
end
finish;

    function enabled = selected(name)
        enabled = any(contains(parameters.metrics,{name,'all'})) && ~any(contains(parameters.excludeMetrics,{name}));
    end
    function add(code,name,severity,message)
        checks(end+1) = struct('code',code,'path',name,'severity',severity,'message',message);
    end
    function requireFile(file,name,message)
        if ~isfile(file), add('MissingInput',name,'error',[message,' Missing: ',file]); end
    end
    function requireFunction(name,native)
        resolved = which(name);
        [~,~,extension] = fileparts(resolved);
        if isempty(resolved) || native && ~strcmp(extension,['.',mexext])
            message = ['Add the directory containing ',name,' to the MATLAB path.'];
            if native
                message = ['Build or install ',name,' for this MATLAB platform (',mexext,') and add its directory to the MATLAB path.'];
            end
            add('MissingDependency','dependencies','error',message);
        end
    end
    function finish
        report = ce.data.validationReport(checks);
        report.parameters = rmfield(parameters,{'session','spikes'});
        report.requiredToolboxes = requiredToolboxes;
    end
    function validateSpikes
        if ~isstruct(spikes) || ~isscalar(spikes) || ~isfield(spikes,'times') || ...
                ~iscell(spikes.times) || isempty(spikes.times) || ~isrow(spikes.times)
            add('InvalidSpikes','spikes.times','error','Supply a scalar spikes struct with a nonempty row cell array of spike times.');
            return
        end
        count = numel(spikes.times);
        fields = {'UID','cluID','shankID','maxWaveformCh1'};
        for item = 1:numel(fields)
            name = fields{item};
            if ismember(name,{'maxWaveformCh1','shankID'}) && ~isfield(spikes,name) && ~isempty(context.spikeImport) && ...
                    parameters.getWaveformsFromDat && selected('waveform_metrics')
                continue % Managed raw waveform extraction supplies peak channels/groups.
            end
            if ~isfield(spikes,name) || ~isnumeric(spikes.(name)) || ~isreal(spikes.(name)) || ...
                    ~isequal(size(spikes.(name)),[1 count]) || any(~isfinite(spikes.(name)))
                add('InvalidSpikeMetadata',['spikes.',name],'error','Provide one finite numeric value per cell as a row vector.');
            elseif strcmp(name,'UID') && (numel(unique(spikes.UID)) ~= count || any(spikes.UID < 1 | spikes.UID ~= fix(spikes.UID)))
                add('InvalidSpikeIdentity','spikes.UID','error','UIDs must be unique positive integers.');
            elseif strcmp(name,'maxWaveformCh1') && any(spikes.(name) < 1 | spikes.(name) > session.extracellular.nChannels | spikes.(name) ~= fix(spikes.(name)))
                add('InvalidSpikeChannel',['spikes.',name],'error','Peak channels must be one-indexed integers within nChannels.');
            elseif strcmp(name,'shankID') && any(spikes.(name) < 1 | spikes.(name) > session.extracellular.nSpikeGroups | spikes.(name) ~= fix(spikes.(name)))
                add('InvalidSpikeGroup',['spikes.',name],'error','Shank IDs must be valid one-indexed spike-group integers.');
            end
        end
        for cellIndex = 1:count
            times = spikes.times{cellIndex};
            if ~isnumeric(times) || ~isreal(times) || ~iscolumn(times) || isempty(times) || ...
                    any(~isfinite(times) | times < 0) || any(diff(times) < 0)
                add('InvalidSpikeTimes',sprintf('spikes.times{%d}',cellIndex),'error', ...
                    'Use a nonempty sorted column of finite spike times in seconds; remove empty units before processing.');
            end
        end
        if isfield(spikes,'total') && ~isequal(spikes.total,cellfun(@numel,spikes.times))
            add('InvalidSpikeTotals','spikes.total','error','Spike totals must match the number of times for each cell; refresh the spike cache.');
        end
        if selected('waveform_metrics') && ~parameters.getWaveformsFromDat
            names = {'filtWaveform','timeWaveform','peakVoltage'};
            for item = 1:numel(names)
                if ~isfield(spikes,names{item}) || numel(spikes.(names{item})) ~= count
                    add('MissingWaveforms',['spikes.',names{item}],'error','Cached waveform metrics need per-cell waveforms, time axes and peak voltage.');
                end
            end
        end
    end
end
