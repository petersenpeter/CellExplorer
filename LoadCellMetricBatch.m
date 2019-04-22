function cell_metrics_batch = LoadCellMetricBatch(varargin)
% Load metrics across sessions
%
% INPUTS:
% varargin: Described below
% 
% OUTPUT:
% cell_metrics_batch. Combibed batch file with metrics from selected sessions

% By Peter Petersen
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'sessionIDs',{},@isnumeric);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);         % 
addParameter(p,'clusteringpaths',{},@iscell);   % Path to the cell_metrics .mat files
addParameter(p,'saveAs','cell_metrics',@isstr); % saveAs - name of .mat file

parse(p,varargin{:})
sessionNames = p.Results.sessions;
sessionIDs = p.Results.sessionIDs;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;
saveAs = p.Results.saveAs;

bz_database = db_credentials;
cell_metrics2 = [];
subfields2 = [];
subfieldstypes = [];
subfieldssizes = [];

disp('Cell-metrics: loading batch')
if ~isempty(sessionNames)
    for iii = 1:length(sessionNames)
        disp(['Loading session info for ', num2str(iii), '/', num2str(length(sessionNames)),': ', sessionNames{iii}])
        [session, basename, basepath, clusteringpath] = db_set_path('session',sessionNames{iii},'changeDir',false);
        basepaths{iii} = basepath;
        clustering_paths{iii} = clusteringpath;
    end
elseif ~isempty(sessionIDs)
    [sessions, basenames, basepaths, clustering_paths] = db_set_path('id',sessionIDs,'changeDir',false);
    
%     for iii = 1:length(sessionIDs)
%         disp(['Loading ', num2str(iii), '/', num2str(length(sessionIDs)),': ', sessionIDs{iii}])
%         [session, basename, basepath, clusteringpath] = db_set_path('id',sessionIDs{iii},'changeDir',false);
%         basepaths{iii} = basepath;
%         clustering_paths{iii} = clusteringpath;
%     end
elseif ~isempty(clusteringpaths)
    clustering_paths = clusteringpaths;
else
    warning('Input not sufficient')
end

for iii = 1:length(clustering_paths)
    if ~isempty(sessionNames)
    disp(['Loading mat files for ', num2str(iii), '/', num2str(length(sessionNames)),': ', sessionNames{iii}])
elseif ~isempty(sessionIDs)
    disp(['Loading mat files for ', num2str(iii), '/', num2str(length(clustering_paths))])
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
for iii = 1:length(cell_metrics2)
    if exist('sessionNames') && ~isempty(sessionNames)
        disp(['Concatenating ', num2str(iii), '/', num2str(length(cell_metrics2)),': ', sessionNames{iii}])
    else
        disp(['Concatenating ', num2str(iii), '/', num2str(length(cell_metrics2)),': ', clustering_paths{iii}])
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
%                 if strcmp(cell_metrics_fieldnames{ii},'FiringRateAcrossTime')
%                    1 
%                 end
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
