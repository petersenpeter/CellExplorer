function cell_metrics_batch = loadCellMetricsBatch(varargin)
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
% loadCellMetricsBatch('basepaths',{'path1','[path1'})      % Load batch from a list with paths
% loadCellMetricsBatch('sessions',{'rec1','rec2'})          % Load batch from database
% loadCellMetricsBatch('sessionIDs',[10985,10985])          % Load session from database session id


% % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Handling inputs
% % % % % % % % % % % % % % % % % % % % % % % % % % % % 
p = inputParser;
addParameter(p,'sessionIDs',{},@isnumeric);     % numeric IDs for the sessions to load
addParameter(p,'sessions',{},@iscell);          % sessionNames for the sessions to load
addParameter(p,'basepaths',{},@iscell);         % basepaths for the sessions to load
addParameter(p,'basenames',{},@iscell);         % basenames for the sessions to load
addParameter(p,'saveAs','cell_metrics',@isstr); % saveAs - name of .mat file
addParameter(p,'waitbar_handle',[],@ishandle);  % waitbar handle

parse(p,varargin{:})
sessionNames = p.Results.sessions;
sessionIDs = p.Results.sessionIDs;
basepaths = p.Results.basepaths;
basenames = p.Results.basenames;
saveAs = p.Results.saveAs;
waitbar_handle = p.Results.waitbar_handle;

db_settings = db_load_settings;

cell_metrics2 = [];
subfields2 = [];
subfieldstypes = [];
subfieldssizes = [];
batch_timer = tic;

if ishandle(waitbar_handle)
    ce_waitbar = waitbar_handle;
else
    ce_waitbar = waitbar(0,' ','name','Cell-metrics: loading batch');
end

cell_metrics_type_struct = {'general','putativeConnections','groups','tags','groundTruthClassification','acg','isi','waveforms','firingRateMaps','responseCurves','events','manipulations','spikes'};

% disp('Cell-metrics: $')
if ~isempty(sessionNames)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(sessionNames)),ce_waitbar,['Loading session info from sessionNames']);
   
    % % % % % % % % % % % % %
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50);
    options.CertificateFilename=('');
    
    % Requesting db list
    bz_db = webread([db_settings.address,'views/15356/'],options,'page_size','5000','sorted','1','cellmetrics',1);
    sessions = loadjson(bz_db.renderedHtml);
    
    % Setting paths from db struct
    db_basename = {};
    db_basepath = {};
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
        
    end
    basepaths = db_basepath(index);
    basenames = db_basename(index);
    
elseif ~isempty(sessionIDs)
    count_metricsLoad = 1;
    waitbar(1/(1+count_metricsLoad+length(sessionIDs)),ce_waitbar,['Loading session info from sessionIDs']);
    [sessions, basenames, basepaths] = db_set_session('sessionId',sessionIDs,'changeDir',false);
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
%         if exist(fullfile(basepath,[basename,'.session.mat']),'file')
%             waitbar(1/(1+count_metricsLoad+length(basepaths)),ce_waitbar,['Loading session info from basepaths']);
%             disp(['Loading ',basename,'.session.mat (',]);
%             load(fullfile(basepath,[basename,'.session.mat']));
%             sessionIn = session;
%         else
%             break
%         end
    end
else
    warning('Input not sufficient')
end
batch_benchmark.clock(1) = toc(batch_timer);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Loading cell_metircs file batch
% % % % % % % % % % % % % % % % % % % % % % % % % % % % 
for iii = 1:length(basepaths)
    file_load_timer = tic;
    if ~isempty(basenames) && ishandle(ce_waitbar)
        waitbar((iii+count_metricsLoad)/(1+count_metricsLoad+length(basepaths)),ce_waitbar,[num2str(iii), '/', num2str(length(basenames)),': ', basenames{iii}]);
    else
        break
    end
    if exist(fullfile(basepaths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat']))
        cell_metrics2{iii} = load(fullfile(basepaths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat']));
    else 
        warning(['session not found: ', fullfile(basepaths{iii},[basenames{iii},'.',saveAs,'.cellinfo.mat'])])
        cell_metrics_batch = [];
        return
    end
    
    % Generating session level metrics
    if isfield(cell_metrics2{iii}.cell_metrics.general,'session')
        sessionMetrics = fieldnames(cell_metrics2{iii}.cell_metrics.general.session);
        for i = 1:numel(sessionMetrics)
            cell_metrics2{iii}.cell_metrics.(['session_',sessionMetrics{i}]) = repmat({cell_metrics2{iii}.cell_metrics.general.session.(sessionMetrics{i})},1,cell_metrics2{iii}.cell_metrics.general.cellCount);
        end
    end
    % Generating animal level metrics
    if isfield(cell_metrics2{iii}.cell_metrics.general,'animal')
        sessionMetrics = fieldnames(cell_metrics2{iii}.cell_metrics.general.animal);
        for i = 1:numel(sessionMetrics)
            cell_metrics2{iii}.cell_metrics.(['animal_',sessionMetrics{i}]) = repmat({cell_metrics2{iii}.cell_metrics.general.animal.(sessionMetrics{i})},1,cell_metrics2{iii}.cell_metrics.general.cellCount);
        end
    end
    subfields2 = [subfields2(:);fieldnames(cell_metrics2{iii}.cell_metrics)];
    temp = struct2cell(structfun(@class,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldstypes = [subfieldstypes(:);temp(:)];
    temp2 = struct2cell(structfun(@size,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldssizes = [subfieldssizes(:);temp2(:)];
    batch_benchmark.file_load(iii) = toc(file_load_timer);
    batch_benchmark.file_cell_count(iii) = cell_metrics2{iii}.cell_metrics.general.cellCount;
end

[cell_metrics_fieldnames,ia,~] = unique(subfields2);
subfieldstypes = subfieldstypes(ia);
subfieldssizes = subfieldssizes(ia);
subfieldstypes(contains(cell_metrics_fieldnames,{'truePositive','falsePositive','batchIDs'})) = [];
subfieldssizes(contains(cell_metrics_fieldnames,{'truePositive','falsePositive','batchIDs'})) = [];
cell_metrics_fieldnames(contains(cell_metrics_fieldnames,{'truePositive','falsePositive','batchIDs'})) = [];

subfieldstypes(ismember(cell_metrics_fieldnames,cell_metrics_type_struct)) = {'struct'};
h = 0;
cell_metrics_batch = [];
batch_benchmark.clock(2) = toc(batch_timer);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Creating cell_metrics_batch from individual session cell_metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ishandle(ce_waitbar)
    waitbar((count_metricsLoad+length(cell_metrics2))/(1+count_metricsLoad+length(cell_metrics2)),ce_waitbar,['Initializing cell metrics batch']);
end
cell_metrics_batch.putativeConnections.excitatory = [];
cell_metrics_batch.putativeConnections.inhibitory = [];
for ii = 1:length(cell_metrics_fieldnames)
    if strcmp(subfieldstypes{ii},'cell')
        cell_metrics_batch.(cell_metrics_fieldnames{ii}) = cell(1,sum(batch_benchmark.file_cell_count));
    elseif strcmp(subfieldstypes{ii},'double')
        cell_metrics_batch.(cell_metrics_fieldnames{ii}) = nan(1,sum(batch_benchmark.file_cell_count));
    elseif strcmp(subfieldstypes{ii},'struct')
        
    end
end
if ishandle(ce_waitbar)
    waitbar((count_metricsLoad+length(cell_metrics2))/(1+count_metricsLoad+length(cell_metrics2)),ce_waitbar,['Concatenating files']);
end
for iii = 1:length(cell_metrics2)
    if ishandle(ce_waitbar)
        waitbar((count_metricsLoad+length(cell_metrics2))/(1+count_metricsLoad+length(cell_metrics2)),ce_waitbar,['Concatenating files: ', basenames{iii}  ,' (',num2str(iii),'/' num2str(length(cell_metrics2)),')']);
    else
        break
    end
    cell_metrics = cell_metrics2{iii}.cell_metrics;
    hh = size(cell_metrics.cellID,2);
    cell_metrics = verifyGroupFormat(cell_metrics,'tags');
    cell_metrics = verifyGroupFormat(cell_metrics,'groundTruthClassification');
    if length(cell_metrics2) > 1 && iii == 1
%         cell_metrics_batch = cell_metrics;
%         cell_metrics_batch = rmfield(cell_metrics_batch,'general');
        cell_metrics_batch.general.basename = 'Batch of sessions';
    end
    cell_metrics_batch.batchIDs(h+1:hh+h) = iii*ones(1,hh);
    cell_metrics_batch.general.batch{iii} = cell_metrics.general;
    cell_metrics_batch.general.basepaths{iii} = basepaths{iii};
    cell_metrics_batch.general.basenames{iii} = cell_metrics.general.basename;
    cell_metrics_batch.general.saveAs{iii} = saveAs;
    
    for ii = 1:length(cell_metrics_fieldnames)
        % Struct field
        if  strcmp(subfieldstypes{ii},'struct') && ~strcmp(cell_metrics_fieldnames{ii},'general')
            % If putative connections field (special)
            if strcmp(cell_metrics_fieldnames{ii},'putativeConnections')
                if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'excitatory') && isfield(cell_metrics_batch,'putativeConnections') && isfield(cell_metrics,'putativeConnections')
                    cell_metrics_batch.putativeConnections.excitatory = [cell_metrics_batch.putativeConnections.excitatory; cell_metrics.putativeConnections.excitatory+h];
                end
                if isfield(cell_metrics,'putativeConnections') && isfield(cell_metrics.putativeConnections,'inhibitory') && isfield(cell_metrics_batch,'putativeConnections') && isfield(cell_metrics,'putativeConnections')
                    cell_metrics_batch.putativeConnections.inhibitory = [cell_metrics_batch.putativeConnections.inhibitory; cell_metrics.putativeConnections.inhibitory+h];
                end
            elseif ismember(cell_metrics_fieldnames{ii},{'groups','tags','groundTruthClassification'})
                if isfield(cell_metrics,cell_metrics_fieldnames{ii})
                    fields1 = fieldnames(cell_metrics.(cell_metrics_fieldnames{ii}));
                        for k = 1:numel(fields1)
                            if isfield(cell_metrics_batch,cell_metrics_fieldnames{ii}) && isfield(cell_metrics_batch.(cell_metrics_fieldnames{ii}),fields1{k})
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(fields1{k}) = [cell_metrics_batch.(cell_metrics_fieldnames{ii}).(fields1{k}), cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k})+h];
                            else
                                cell_metrics_batch.(cell_metrics_fieldnames{ii}).(fields1{k}) = cell_metrics.(cell_metrics_fieldnames{ii}).(fields1{k})+h;
                            end
                        end
                end
            else
                if isfield(cell_metrics,cell_metrics_fieldnames{ii})
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
                                    if ~isfield(cell_metrics_batch,cell_metrics_fieldnames{ii}) ||  ~isfield(cell_metrics_batch.(cell_metrics_fieldnames{ii}),structFields{k}) || (isfield(cell_metrics_batch.(cell_metrics_fieldnames{ii}),structFields{k}) && size(cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k}),1) == size(cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k}),1))
                                        cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k})(:,h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
                                    end
%                                 elseif structFieldsSize{k}(1)>1 %&& any(strcmp(cell_metrics_fieldnames{ii}, {'firing_rate_map','firing_rate_map_states'}))
%                                     cell_metrics_batch.(cell_metrics_fieldnames{ii}).(structFields{k}){iii} = cell_metrics.(cell_metrics_fieldnames{ii}).(structFields{k});
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

if ~isempty(cell_metrics_batch)
    cell_metrics_batch.general.cellCount = length(cell_metrics_batch.UID);
    batch_benchmark.clock(3) = toc(batch_timer);
    cell_metrics_batch.general.batch_benchmark = batch_benchmark;
end

% Setting correct size of fields inside structs
cell_metrics_type_struct2 = {'acg','isi','waveforms','firingRateMaps','responseCurves','events','manipulations','spikes'};
for ii = 1:numel(cell_metrics_type_struct2)
    if isfield(cell_metrics_batch,cell_metrics_type_struct2{ii})
        structFields = fieldnames(cell_metrics_batch.(cell_metrics_type_struct2{ii}));
        structFieldsType = struct2cell(structfun(@class,cell_metrics_batch.(cell_metrics_type_struct2{ii}),'UniformOutput',false));
        structFieldsSize = struct2cell(structfun(@size,cell_metrics_batch.(cell_metrics_type_struct2{ii}),'UniformOutput',false));
        for k = 1:length(structFields)
            if strcmp(structFieldsType{k},'cell') & structFieldsSize{k}(2) < cell_metrics_batch.general.cellCount
                cell_metrics_batch.(cell_metrics_type_struct2{ii}).(structFields{k}){cell_metrics_batch.general.cellCount} = [];
            elseif strcmp(structFieldsType{k},'double') & structFieldsSize{k}(2) < cell_metrics_batch.general.cellCount
                cell_metrics_batch.(cell_metrics_type_struct2{ii}).(structFields{k})(:,structFieldsSize{k}(2)+1:cell_metrics_batch.general.cellCount) = nan;
            end
        end
    end
end

if ishandle(ce_waitbar)
    waitbar(1,ce_waitbar,'Loading complete');
    if isempty(waitbar_handle)
        close(ce_waitbar)
    end
end
