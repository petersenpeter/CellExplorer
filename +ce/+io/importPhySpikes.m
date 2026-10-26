function spikes = importPhySpikes(session, varargin)
%IMPORTPHYSPIKES Read Phy timestamps/metadata with no UI, cache or file writes.
% Label-table order determines UIDs. Retain the legacy 0.5 ms deduplication,
% amplitude selection, plugin channel mapping and cluster_info precedence.
plan=ce.io.phyImportPlan(session,varargin{:}); folder=plan.folder;
clusters=ce.io.readSortingNpy(fullfile(folder,'spike_clusters.npy'));
times=ce.io.readSortingNpy(fullfile(folder,'spike_times.npy'));
integerVector(clusters,'spike_clusters'); integerVector(times,'spike_times');
if numel(clusters)~=numel(times), error('ce:io:InvalidSortingData','Phy assignments and timestamps must have equal lengths.'); end
hasAmplitudes=any(strcmp({plan.files.kind},'amplitudes'));
if hasAmplitudes
    amplitudes=ce.io.readSortingNpy(fullfile(folder,'amplitudes.npy'));
    numericVector(amplitudes,'amplitudes');
    if numel(amplitudes)~=numel(times), error('ce:io:InvalidSortingData','Expected one amplitude per source spike.'); end
end
if plan.plugins
    ids=ce.io.readSortingNpy(fullfile(folder,'cluster_ids.npy'));
    shanks=ce.io.readSortingNpy(fullfile(folder,'shanks.npy')); % Legacy reads but does not use these assignments.
    peak=ce.io.readSortingNpy(fullfile(folder,'peak_channel.npy'));
    integerVector(ids,'cluster_ids'); integerVector(shanks,'shanks'); integerVector(peak,'peak_channel');
    if numel(unique(ids))~=numel(ids) || numel(peak)~=numel(ids) || numel(shanks)~=numel(ids)
        error('ce:io:InvalidPhyMetadata','Plugin arrays need one unique cluster ID and matching channel/shank entries.');
    end
    peak=double(peak)+1;
    if any(strcmp({plan.files.kind},'channelMap'))
        stored=load(fullfile(folder,'rez.mat'),'rez');
        if ~isfield(stored,'rez') || ~isstruct(stored.rez) || ~isscalar(stored.rez) || ~isfield(stored.rez,'connected')
            error('ce:io:InvalidPhyMetadata','rez.mat must contain rez.connected for channel mapping.');
        end
        connected=stored.rez.connected;
        if ~(isnumeric(connected) || islogical(connected)) || ~isvector(connected) || any(~ismember(connected,[0 1]))
            error('ce:io:InvalidPhyMetadata','rez.connected must be a binary channel vector.');
        end
        channels=find(connected);
        if any(peak>numel(channels)), error('ce:io:InvalidPhyMetadata','Plugin peak channel exceeds rez.connected mapping.'); end
        peak=channels(peak);
    end
    validateChannels(peak,session);
    extra=session.extracellular;
    if ~isfield(extra,'nElectrodeGroups') || ~isfield(extra,'electrodeGroups') || ...
            ~isstruct(extra.electrodeGroups) || ~isscalar(extra.electrodeGroups) || ...
            ~isfield(extra.electrodeGroups,'channels') || ~iscell(extra.electrodeGroups.channels) || ...
            ~isequal(extra.nElectrodeGroups,numel(extra.electrodeGroups.channels))
        error('ce:io:InvalidPhyMetadata','Plugin channels require explicit electrodeGroups.channels and nElectrodeGroups.');
    end
end
hasInfo=any(strcmp({plan.files.kind},'info'));
if hasInfo
    info=tdfread(fullfile(folder,'cluster_info.tsv'));
    if isfield(info,'id'), infoIDs=info.id;
    elseif isfield(info,'cluster_id'), infoIDs=info.cluster_id;
    else, error('ce:io:InvalidPhyMetadata','cluster_info.tsv requires id or cluster_id.'); end
    integerVector(infoIDs,'cluster_info IDs');
    if ~all(isfield(info,{'ch','amp'})) || numel(unique(infoIDs))~=numel(infoIDs)
        error('ce:io:InvalidPhyMetadata','cluster_info.tsv requires unique IDs, ch and amp.');
    end
    integerVector(info.ch,'cluster_info channels'); numericVector(info.amp,'cluster_info amplitudes');
    if numel(info.ch)~=numel(infoIDs) || numel(info.amp)~=numel(infoIDs)
        error('ce:io:InvalidPhyMetadata','cluster_info columns must have equal lengths.');
    end
    validateChannels(info.ch+1,session);
end
spikes=struct(); UID=0; tolerance=session.extracellular.sr*5e-4;
for index=1:numel(plan.clusterIDs)
    cluster=plan.clusterIDs(index);
    if ~any(strcmpi(plan.labels{index},plan.options.labelsToRead)) || ~any(clusters==cluster), continue; end
    UID=UID+1;
    spikes.ids{UID}=find(clusters==cluster);
    [spikes.ts{UID},selected]=uniquetol(double(times(spikes.ids{UID})),tolerance,'DataScale',1);
    spikes.ids{UID}=spikes.ids{UID}(selected);
    spikes.times{UID}=spikes.ts{UID}/session.extracellular.sr;
    spikes.cluID(UID)=cluster;
    spikes.total(UID)=length(spikes.ts{UID});
    if hasAmplitudes, spikes.amplitudes{UID}=double(amplitudes(spikes.ids{UID})); end
    if plan.plugins
        row=find(ids==cluster);
        if numel(row)~=1, error('ce:io:InvalidPhyMetadata','Missing plugin mapping for selected cluster %g.',cluster); end
        spikes.maxWaveformCh1(UID)=double(peak(row));
        spikes.maxWaveformCh(UID)=double(peak(row))-1;
        groups=find(cellfun(@(channels) any(channels==peak(row)),extra.electrodeGroups.channels));
        if numel(groups)~=1, error('ce:io:InvalidPhyMetadata','Selected plugin channel must belong to exactly one electrode group.'); end
        spikes.shankID(UID)=groups;
    end
    if hasInfo
        row=find(infoIDs==cluster);
        if numel(row)~=1, error('ce:io:InvalidPhyMetadata','Missing cluster_info mapping for selected cluster %g.',cluster); end
        spikes.maxWaveformCh(UID)=info.ch(row);
        spikes.maxWaveformCh1(UID)=info.ch(row)+1;
        spikes.phy_maxWaveformCh1(UID)=info.ch(row)+1;
        spikes.phy_amp(UID)=info.amp(row)+1; % Preserve legacy offset; scientific review is separate.
    end
end
if UID==0, error('ce:io:NoSortedUnits','No spikes match the requested Phy labels.'); end
spikes.basename=plan.basename; spikes.numcells=UID; spikes.UID=1:UID; spikes.sr=session.extracellular.sr;
end

function numericVector(data,name)
if ~isnumeric(data) || ~isreal(data) || (~isempty(data) && ~isvector(data)) || any(~isfinite(data(:)))
    error('ce:io:InvalidSortingData','%s must be a finite numeric vector.',name);
end
end

function integerVector(data,name)
numericVector(data,name);
if any(data(:)<0 | data(:)~=fix(data(:)) | data(:)>flintmax)
    error('ce:io:InvalidSortingData','%s must contain nonnegative exactly representable integers.',name);
end
end

function validateChannels(channels,session)
if ~isfield(session.extracellular,'nChannels') || ~isnumeric(session.extracellular.nChannels) || ...
        ~isscalar(session.extracellular.nChannels) || ~isfinite(session.extracellular.nChannels) || ...
        session.extracellular.nChannels<1 || session.extracellular.nChannels~=fix(session.extracellular.nChannels) || ...
        any(channels<1 | channels>session.extracellular.nChannels)
    error('ce:io:InvalidPhyMetadata','Peak channels must be within the recording channel count.');
end
end
