function plan = phyImportPlan(session, varargin)
%PHYIMPORTPLAN Resolve consumed Phy files without dialogs or writes.
p=inputParser;
addParameter(p,'basename','',@ischar);
addParameter(p,'clusteringpath',[],@ischar);
addParameter(p,'labelsToRead',{'good'},@(x) iscell(x) && all(cellfun(@ischar,x)));
addParameter(p,'raw_clusters',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'getWaveformsFromSource',false,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:}); options=p.Results;
if options.raw_clusters
    error('ce:io:UnsupportedPhyMode','Phy raw_clusters has no defined timestamp tolerance; select labelsToRead explicitly.');
end
if options.getWaveformsFromSource
    error('ce:io:UnsupportedPhyMode','Phy template indexing/scaling is not validated. Use raw .dat waveform extraction instead.');
end
if ~isstruct(session) || ~isscalar(session) || ~isfield(session,'general') || ...
        ~isstruct(session.general) || ~isscalar(session.general) || ...
        ~isfield(session.general,'basePath') || ~ischar(session.general.basePath) || ...
        ~isrow(session.general.basePath) || ~isfolder(session.general.basePath) || ...
        ~isfield(session,'extracellular') || ~isstruct(session.extracellular) || ...
        ~isscalar(session.extracellular) || ~isfield(session.extracellular,'sr')
    error('ce:io:InvalidSortingMetadata','Provide an existing session.general.basePath and explicit extracellular.sr.');
end
validateattributes(session.extracellular.sr,{'numeric'},{'real','scalar','finite','positive'});
basename=options.basename;
if isempty(basename) && isfield(session.general,'name'), basename=session.general.name; end
if ~ischar(basename) || ~isrow(basename) || isempty(basename) || any(ismember(basename,'/\'))
    error('ce:io:InvalidSortingMetadata','Provide a recording basename without directory separators.');
end
relativePath=options.clusteringpath;
if ~ischar(relativePath)
    relativePath='';
    if isfield(session,'spikeSorting') && iscell(session.spikeSorting) && ~isempty(session.spikeSorting) && ...
            isstruct(session.spikeSorting{1}) && isscalar(session.spikeSorting{1}) && ...
            isfield(session.spikeSorting{1},'relativePath')
        relativePath=session.spikeSorting{1}.relativePath;
    end
end
if ~ischar(relativePath) || (~isempty(relativePath) && ~isrow(relativePath))
    error('ce:io:InvalidSortingMetadata','The clustering path must be a character row.');
end
folder=fullfile(session.general.basePath,relativePath);
if ~isfolder(folder), error('ce:io:MissingSortingInput','Sorting directory not found: %s.',folder); end
files=struct('file',{},'kind',{});
addFile('spike_clusters.npy','clusters',true);
addFile('spike_times.npy','times',true);
addFile('amplitudes.npy','amplitudes',false);
group=fullfile(folder,'cluster_group.tsv'); delimiter=sprintf('\t');
if isfile(group)
    [ids,labels]=ce.io.readPhyLabels(group,delimiter);
    addFile('cluster_group.tsv','labels',true);
    if isempty(ids)
        group=fullfile(folder,'cluster_KSLabel.tsv');
        addFile('cluster_KSLabel.tsv','labels',true);
        [ids,labels]=ce.io.readPhyLabels(group,delimiter);
    end
elseif isfile(fullfile(folder,'cluster_groups.csv'))
    group=fullfile(folder,'cluster_groups.csv'); delimiter=',';
    addFile('cluster_groups.csv','labels',true);
    [ids,labels]=ce.io.readPhyLabels(group,delimiter);
else
    group=fullfile(folder,'cluster_KSLabel.tsv');
    addFile('cluster_KSLabel.tsv','labels',true);
    [ids,labels]=ce.io.readPhyLabels(group,delimiter);
end
plugins={'cluster_ids.npy','shanks.npy','peak_channel.npy'};
present=cellfun(@(name) isfile(fullfile(folder,name)),plugins);
if any(present) && ~all(present)
    error('ce:io:InvalidPhyMetadata','Phy plugin metadata requires cluster_ids.npy, shanks.npy and peak_channel.npy together.');
end
if all(present)
    for k=1:numel(plugins), addFile(plugins{k},'plugin',true); end
    addFile('rez.mat','channelMap',false);
end
addFile('cluster_info.tsv','info',false);
plan=struct('folder',folder,'basename',basename,'options',options,'files',files, ...
    'clusterIDs',ids,'labels',{labels},'plugins',all(present));

    function addFile(name,kind,required)
        file=fullfile(folder,name);
        if isfile(file), files(end+1)=struct('file',file,'kind',kind);
        elseif required, error('ce:io:MissingSortingInput','Required Phy input not found: %s.',file);
        end
    end
end
