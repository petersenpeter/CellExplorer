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

p = inputParser;
addParameter(p,'sessionIDs',{},@isnumeric);     % numeric IDs for the sessions to load
addParameter(p,'sessions',{},@iscell);          % sessionNames for the sessions to load
addParameter(p,'basepaths',{},@iscell);         % basepaths for the sessions to load
addParameter(p,'clusteringpaths',{},@iscell);   % Path to the cell_metrics .mat files
addParameter(p,'saveAs','cell_metrics',@isstr); % saveAs - name of .mat file
addParameter(p,'waitbar_handle',[],@ishandle);  % waitbar handle 

parse(p,varargin{:})
sessionNames = p.Results.sessions;
sessionIDs = p.Results.sessionIDs;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;
saveAs = p.Results.saveAs;
waitbar_handle = p.Results.waitbar_handle;

bz_database = db_credentials;
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
    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'RequestMethod','get','Timeout',50);
    options.CertificateFilename=('');
    % Requesting db list
    bz_db = webread([bz_database.rest_api.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
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
            db_basepath{i_db} = fullfile(bz_database.repositories.(sessions{i_db}.repositories{1}), path_Investigator,sessions{i_db}.animal, sessions{i_db}.name);
        else
            db_basepath{i_db} = fullfile(bz_database.repositories.(sessions{i_db}.repositories{1}), sessions{i_db}.animal, sessions{i_db}.name);
        end
        
        if ~isempty(sessions{i_db}.spikeSorting.relativePath)
            db_clusteringpath{i_db} = fullfile(db_basepath{i_db}, sessions{i_db}.spikeSorting.relativePath{1});
        else
            db_clusteringpath{i_db} = db_basepath{i_db};
        end
    end
    clustering_paths = db_clusteringpath(index);
    basepaths = db_basepath(index);
    
    % % % % % % % % % % % % %
%     count_metricsLoad = length(sessionNames);
%     for iii = 1:length(sessionNames)
%         if ishandle(f_LoadCellMetrics)
%             waitbar(iii/(1+count_metricsLoad+length(sessionNames)),f_LoadCellMetrics,['Loading session info for ', num2str(iii), '/', num2str(length(sessionNames)),': ', sessionNames{iii}]);
%         else
%             break
%         end
%         [session, basename, basepath, clusteringpath] = db_set_path('session',sessionNames{iii},'changeDir',false);
%         basepaths{iii} = basepath;
%         clustering_paths{iii} = clusteringpath;
%     end
    
elseif ~isempty(sessionIDs)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(sessionIDs)),f_LoadCellMetrics,['Loading session info from sessionIDs']);
    [sessions, basenames, basepaths, clustering_paths] = db_set_path('id',sessionIDs,'changeDir',false);
elseif ~isempty(clusteringpaths)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(clusteringpaths)),f_LoadCellMetrics,['Loading session info from clusteringpaths']);
    clustering_paths = clusteringpaths;
else
    warning('Input not sufficient')
end

for iii = 1:length(clustering_paths)
    if ~isempty(sessionNames) && ishandle(f_LoadCellMetrics)
            waitbar((iii+count_metricsLoad)/(1+count_metricsLoad+length(clustering_paths)),f_LoadCellMetrics,['Loading ', num2str(iii), '/', num2str(length(sessionNames)),': ', sessionNames{iii}]);
    elseif ~isempty(sessionIDs) && ishandle(f_LoadCellMetrics)
            waitbar((iii+count_metricsLoad)/(1+count_metricsLoad+length(clustering_paths)),f_LoadCellMetrics,['Loading ', num2str(iii), '/', num2str(length(clustering_paths))]);
    elseif ~isempty(clustering_paths) && ishandle(f_LoadCellMetrics)
            waitbar((iii+count_metricsLoad)/(1+count_metricsLoad+length(clustering_paths)),f_LoadCellMetrics,['Loading ', num2str(iii), '/', num2str(length(clustering_paths))]);
    else
        break
    end
    if exist(fullfile(clustering_paths{iii},[saveAs,'.mat']))
        cell_metrics2{iii} = load(fullfile(clustering_paths{iii},[saveAs,'.mat']));
    else
        warning([fullfile(clustering_paths{iii},[saveAs,'.mat']), ' does not exist'])
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
    if ~ishandle(f_LoadCellMetrics)
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
    cell_metrics_batch.general.paths{iii} = clustering_paths{iii};
    cell_metrics_batch.general.basenames{iii} = cell_metrics.general.basename;
    cell_metrics_batch.general.saveAs{iii} = saveAs;
    if ~isempty(basepaths{iii})
        cell_metrics_batch.general.basepaths{iii} = basepaths{iii};
    else
        cell_metrics_batch.general.basepaths{iii} = clustering_paths{iii};
    end
    
    for ii = 1:length(cell_metrics_fieldnames)
        if ~isfield(cell_metrics,cell_metrics_fieldnames{ii}) && ~strcmp(cell_metrics_fieldnames{ii},'putativeConnections')
            if strcmp(subfieldstypes{ii},'double')
                if length(subfieldssizes{ii})==3
                    
                elseif length(subfieldssizes{ii})==2 && subfieldssizes{ii}(1) > 0
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = nan(subfieldssizes{ii}(1:end-1),hh);
                else
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                end
            elseif strcmp(subfieldstypes{ii},'cell') && length(subfieldssizes{ii}) < 3
                cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = repmat({''},1,size(cell_metrics.cellID,2));
                
            elseif strcmp(subfieldstypes{ii},'cell') && length(subfieldssizes{ii}) == 3
                cell_metrics_batch.(cell_metrics_fieldnames{ii}){iii} = {};
            end
        else
            if strcmp(cell_metrics_fieldnames{ii},'putativeConnections')
                if iii > 1 & isfield(cell_metrics,'putativeConnections') & isfield(cell_metrics_batch,'putativeConnections')
                    cell_metrics_batch.(cell_metrics_fieldnames{ii}) = [cell_metrics_batch.(cell_metrics_fieldnames{ii});cell_metrics.(cell_metrics_fieldnames{ii})+h];
                end
                
            elseif strcmp(subfieldstypes{ii},'double')
                if isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(subfieldssizes{ii})==2 && subfieldssizes{ii}(1) > 0%% && ~any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = nan(subfieldssizes{ii}(1:end-1),hh);
                elseif isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(subfieldssizes{ii})==1
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                else
                    if length(subfieldssizes{ii})==3
                        for iiii=1:size(cell_metrics.(cell_metrics_fieldnames{ii}),3)
                            %                             cell_metrics_batch.(cell_metrics_fieldnames{ii}){h+iiii} = cell_metrics.(cell_metrics_fieldnames{ii})(:,:,iiii);
                        end
                    elseif subfieldssizes{ii}(1)>1 %&& ~any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                        cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                        
                    elseif subfieldssizes{ii}(1)>1 %&& any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
                        cell_metrics_batch.(cell_metrics_fieldnames{ii}){iii} = cell_metrics.(cell_metrics_fieldnames{ii});
                    else
                        if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii}))
                            if size(cell_metrics.(cell_metrics_fieldnames{ii}),2) == hh & size(cell_metrics.(cell_metrics_fieldnames{ii}),1) == 1
                                cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                            else
                                cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(hh,1);
                            end
                        end
                    end
                end
            elseif strcmp(subfieldstypes{ii},'cell')
                if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii})) & length(size(cell_metrics.(cell_metrics_fieldnames{ii})))<3 & size(cell_metrics.(cell_metrics_fieldnames{ii}),1)==1 & size(cell_metrics.(cell_metrics_fieldnames{ii}),2)== hh
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                else
                    cell_metrics_batch.(cell_metrics_fieldnames{ii}){iii} = cell_metrics.(cell_metrics_fieldnames{ii}){1};
                end
            end
        end
    end
    h=h+size(cell_metrics.cellID,2);
end
if ishandle(f_LoadCellMetrics)
    waitbar(1,f_LoadCellMetrics,'Loading complete');
    if isempty(waitbar_handle)
        close(f_LoadCellMetrics)
    end
end