function cell_metrics_batch = LoadCellMetricBatch(varargin)
% Load metrics across sessions and concats the metrics into a single struct
% with the appropriate format for each field.
%
% INPUTS:
% varargin: Described below
%
% OUTPUT:
% cell_metrics_batch. Combibed batch file with metrics from selected sessions

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 13-03-2020

% - Example calls:
% LoadCellMetricBatch('basepaths',{'path1','[path1'})      % Load batch from a list with paths
% LoadCellMetricBatch('clusteringpaths',{'path1','path1'}) % Load batch from a list with paths
% LoadCellMetricBatch('sessions',{'rec1','rec2'})          % Load batch from database
% LoadCellMetricBatch('sessionIDs',[10985,10985])          % Load session from database session id

p = inputParser;
addParameter(p,'sessionIDs',{},@isnumeric);     % numeric IDs for the sessions to load
addParameter(p,'sessions',{},@iscell);          % sessionNames for the sessions to load
addParameter(p,'basepaths',{},@iscell);         % basepaths for the sessions to load
addParameter(p,'basenames',{},@iscell);         % basenames for the sessions to load
addParameter(p,'clusteringpaths',{},@iscell);   % Path to the cell_metrics .mat files
addParameter(p,'saveAs','cell_metrics',@isstr); % saveAs - name of .mat file
addParameter(p,'waitbar_handle',[],@ishandle);  % waitbar handle

parse(p,varargin{:})
sessionNames = p.Results.sessions;
sessionIDs = p.Results.sessionIDs;
basepaths = p.Results.basepaths;
basenames = p.Results.basenames;
clusteringpaths = p.Results.clusteringpaths;
saveAs = p.Results.saveAs;
waitbar_handle = p.Results.waitbar_handle;

db_settings = db_load_settings;

cell_metrics2 = [];
subfields2 = [];
subfieldstypes = [];
subfieldssizes = [];

if ishandle(waitbar_handle)
    f_LoadCellMetrics = waitbar_handle;
else
    f_LoadCellMetrics = waitbar(0,' ','name','Cell-metrics: loading batch');
end

% disp('Cell-metrics: loading batch')
if ~isempty(sessionNames)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(sessionNames)),f_LoadCellMetrics,['Loading session info from sessionNames']);
   
    % % % % % % % % % % % % %
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50);
    options.CertificateFilename=('');
    
    % Requesting db list
    bz_db = webread([db_settings.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
    sessions = loadjson(bz_db.renderedHtml);
    
    % Setting paths from db struct
    db_basename = {};
    db_basepath = {};
    db_clusteringpath = {};
    db_basename = cellfun(@(x) x.name,sessions,'UniformOutput',false);
    
    [~,index,~] = intersect(db_basename,sessionNames);
    
    for i_db = 1:length(sessions)
        if strcmp(sessions{i_db}.repositories{1},'NYUshare_Datasets')
            Investigator_name = strsplit(sessions{i_db}.investigator,' ');
            path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
            db_basepath{i_db} = fullfile(db_settings.repositories.(sessions{i_db}.repositories{1}), path_Investigator,sessions{i_db}.animal, sessions{i_db}.name);
        else
            db_basepath{i_db} = fullfile(db_settings.repositories.(sessions{i_db}.repositories{1}), sessions{i_db}.animal, sessions{i_db}.name);
        end
        
        if ~isempty(sessions{i_db}.spikeSorting.relativePath)
            db_clusteringpath{i_db} = fullfile(db_basepath{i_db}, sessions{i_db}.spikeSorting.relativePath{1});
        else
            db_clusteringpath{i_db} = db_basepath{i_db};
        end
    end
    clustering_paths = db_clusteringpath(index);
    basepaths = db_basepath(index);
    basenames = db_basename(index);
    
elseif ~isempty(sessionIDs)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(sessionIDs)),f_LoadCellMetrics,['Loading session info from sessionIDs']);
    [sessions, basenames, basepaths, clustering_paths] = db_set_session('sessionId',sessionIDs,'changeDir',false);
elseif ~isempty(clusteringpaths)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(clusteringpaths)),f_LoadCellMetrics,['Loading session info from clusteringpaths']);
    clustering_paths = clusteringpaths;
elseif ~isempty(basepaths)
    count_metricsLoad = 1;
    for i = 1:length(basepaths)
        basepath = basepaths{i};
        if isempty(basenames) || length(basenames) < i
            [~,basename,~] = fileparts(basepath);
            basenames{i} = basename;
        else
            basename = basenames{i};
        end
        if exist(fullfile(basepath,[basename,'.session.mat']),'file')
            waitbar(1/(1+count_metricsLoad+length(basepaths)),f_LoadCellMetrics,['Loading session info from basepaths']);
            disp(['Loading ',basename,'.session.mat']);
            load(fullfile(basepath,[basename,'.session.mat']));
            sessionIn = session;
            if iscell(session.spikeSorting) && isfield(session.spikeSorting{1},'relativePath') && ~isempty(session.spikeSorting{1}.relativePath)
                clusteringpath = session.spikeSorting{1}.relativePath;
            else
                clusteringpath = '';
            end
            clustering_paths{i} = fullfile(basepath,clusteringpath);
        else
            break
        end
    end
    
else
    warning('Input not sufficient')
end

for iii = 1:length(clustering_paths)
    if ~isempty(basenames) && ishandle(f_LoadCellMetrics)
        waitbar((iii+count_metricsLoad)/(1+count_metricsLoad+length(clustering_paths)),f_LoadCellMetrics,[num2str(iii), '/', num2str(length(basenames)),': ', basenames{iii}]);
    else
        break
    end
    if exist(fullfile(clustering_paths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat']))
        cell_metrics2{iii} = load(fullfile(clustering_paths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat']));
    else 
        warning(['session not found: ', fullfile(clustering_paths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat'])])
        cell_metrics_batch = [];
        return
    end
    subfields2 = [subfields2(:);fieldnames(cell_metrics2{iii}.cell_metrics)];
    temp = struct2cell(structfun(@class,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldstypes = [subfieldstypes(:);temp(:)];
    temp2 = struct2cell(structfun(@size,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldssizes = [subfieldssizes(:);temp2(:)];
end

[cell_metrics_fieldnames,ia,~] = unique(subfields2);
subfieldstypes = subfieldstypes(ia);
subfieldssizes = subfieldssizes(ia);
subfieldstypes(contains(cell_metrics_fieldnames,{'truePositive','falsePositive'})) = [];
subfieldssizes(contains(cell_metrics_fieldnames,{'truePositive','falsePositive'})) = [];
cell_metrics_fieldnames(contains(cell_metrics_fieldnames,{'truePositive','falsePositive'})) = [];

h = 0;
cell_metrics_batch = [];

if ishandle(f_LoadCellMetrics)
    waitbar((count_metricsLoad+length(cell_metrics2))/(1+count_metricsLoad+length(cell_metrics2)),f_LoadCellMetrics,['Concatenating files']);
end
for iii = 1:length(cell_metrics2)
    if ishandle(f_LoadCellMetrics)
        waitbar((count_metricsLoad+length(cell_metrics2))/(1+count_metricsLoad+length(cell_metrics2)),f_LoadCellMetrics,['Concatenating files: ', basenames{iii}  ,' (',num2str(iii),'/' num2str(length(cell_metrics2)),')']);
    else
        break
    end
    cell_metrics = cell_metrics2{iii}.cell_metrics;
    hh = size(cell_metrics.cellID,2);
    if iii == 1
        cell_metrics_batch = cell_metrics;
        cell_metrics_batch = rmfield(cell_metrics_batch,'general');
        cell_metrics_batch.general.basename = 'Batch of sessions';
    end
    cell_metrics_batch.batchIDs(h+1:hh+h) = iii*ones(1,hh);
    cell_metrics_batch.general.batch{iii} = cell_metrics.general;
    cell_metrics_batch.general.path{iii} = clustering_paths{iii};
    cell_metrics_batch.general.basenames{iii} = cell_metrics.general.basename;
    cell_metrics_batch.general.saveAs{iii} = saveAs;
    if ~isempty(basepaths)
        cell_metrics_batch.general.basepaths{iii} = basepaths{iii};
    else
        cell_metrics_batch.general.basepaths{iii} = clustering_paths{iii};
    end
    
    for ii = 1:length(cell_metrics_fieldnames)
        % Struct field
        if  strcmp(subfieldstypes{ii},'struct') && ~strcmp(cell_metrics_fieldnames{ii},'general')
            % If putative connections field (special)
            if strcmp(cell_metrics_fieldnames{ii},'putativeConnections')
                if isfield(cell_metrics.putativeConnections,'excitatory') && iii > 1 && isfield(cell_metrics_batch,'putativeConnections') && isfield(cell_metrics,'putativeConnections')
                    cell_metrics_batch.putativeConnections.excitatory = [cell_metrics_batch.putativeConnections.excitatory; cell_metrics.putativeConnections.excitatory+h];
                end
                if isfield(cell_metrics.putativeConnections,'inhibitory') && iii > 1 && isfield(cell_metrics_batch,'putativeConnections') && isfield(cell_metrics,'putativeConnections')
                    cell_metrics_batch.putativeConnections.inhibitory = [cell_metrics_batch.putativeConnections.inhibitory; cell_metrics.putativeConnections.inhibitory+h];
                end
            else
                if ~isfield(cell_metrics,cell_metrics_fieldnames{ii})
                    
                else
                structFields = fieldnames(cell_metrics.(cell_metrics_fieldnames{ii}));
                structFieldsType = struct2cell(structfun(@class,cell_metrics.(cell_metrics_fieldnames{ii}),'UniformOutput',false));
                structFieldsSize = struct2cell(structfun(@size,cell_metrics.(cell_metrics_fieldnames{ii}),'UniformOutput',false));
                for k = 1:length(structFields)
                    if  strcmp(structFieldsType{k},'cell')
                        if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k})) && length(size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k})))<3 & size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),1)==1 & size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),2)== hh
                            cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
                        else
                            cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k}){iii} = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}){1};
                        end
                    elseif strcmp(structFieldsType{k},'double')
                        % % % % % % % % % % % % % % % % % % % % % % % % 
                        % If field does not exist
                        if ~isfield(cell_metrics.(cell_metrics_fieldnames{ii}),structFields{k})
                            if length(structFieldsSize{k})==2 && structFieldsSize{k}(1) > 0
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(:,h+1:hh+h) = nan(structFieldsSize{k}(1:end-1),hh);
                            else
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(h+1:hh+h) = nan(1,hh);
                            end
                            
                        % If field exist
                        else
                            if isempty(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k})) && length(structFieldsSize{k})==2 && structFieldsSize{k}(1) > 0%% && ~any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(:,h+1:hh+h) = nan(structFieldsSize{k}(1:end-1),hh);
                            elseif isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(structFieldsSize{k})==1
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(h+1:hh+h) = nan(1,hh);
                            else
                                if length(structFieldsSize{k})==3
                                    for iiii=1:size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),3)
                                        
                                    end
                                elseif structFieldsSize{k}(1)>1 %&& ~any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                                    cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(:,h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
                                    
                                elseif structFieldsSize{k}(1)>1 %&& any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                                    cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k}){iii} = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
                                else
                                    if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}))
                                        if size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),2) == hh && size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),1) == 1
                                            cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
                                        else
                                            cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(h+1:hh+h) = nan(1,hh);
                                        end
                                    end
                                end
                            end
                        end
                        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
                    end
                end
                end
            end
            
        % Cell field
        elseif strcmp(subfieldstypes{ii},'cell')
            % If field does not exist
            if ~isfield(cell_metrics,cell_metrics_fieldnames{ii})
                if strcmp(subfieldstypes{ii},'cell') && length(subfieldssizes{ii}) < 3
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = repmat({''},1,size(cell_metrics.cellID,2));
                elseif strcmp(subfieldstypes{ii},'cell') && length(subfieldssizes{ii}) == 3
                    cell_metrics_batch.(cell_metrics_fieldnames{ii}){iii} = {};
                end
                
            % If field exist
            else
                if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(size(cell_metrics.(cell_metrics_fieldnames{ii})))<3 & size(cell_metrics.(cell_metrics_fieldnames{ii}),1)==1 && size(cell_metrics.(cell_metrics_fieldnames{ii}),2)== hh
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                else
                    cell_metrics_batch.(cell_metrics_fieldnames{ii}){iii} = cell_metrics.(cell_metrics_fieldnames{ii}){1};
                end
            end
            
            % Double field
        elseif strcmp(subfieldstypes{ii},'double')
            % If field does not exist
            if ~isfield(cell_metrics,cell_metrics_fieldnames{ii})
                cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                
            % If field exist
            else
                if size(cell_metrics.(cell_metrics_fieldnames{ii}),2) == hh && size(cell_metrics.(cell_metrics_fieldnames{ii}),1) == 1
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                elseif size(cell_metrics.(cell_metrics_fieldnames{ii}),1) == hh && size(cell_metrics.(cell_metrics_fieldnames{ii}),2) == 1
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii})';
                else
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                end
                
            end
        end
    end
    h=h+size(cell_metrics.cellID,2);
end
cell_metrics_batch.general.cellCount = length(cell_metrics_batch.UID);

if ishandle(f_LoadCellMetrics)
    waitbar(1,f_LoadCellMetrics,'Loading complete');
    if isempty(waitbar_handle)
        close(f_LoadCellMetrics)
    end
end
