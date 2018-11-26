function cell_metrics_batch = LoadCellMetricBatch(varargin)
%   saveAs               - name of .mat file

% Load metrics across sessions
p = inputParser;
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'clusteringpaths',{},@iscell);
addParameter(p,'saveAs','cell_metrics',@isstr);

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

if ~isempty(sessionNames)
    for iii = 1:length(sessionNames)
        disp(['Loading ', num2str(iii), ' of ', num2str(length(sessionNames)),': ', sessionNames{iii}])
        sessions = db_load_sessions('session',sessionNames{iii});
        session = sessions{1};
        basepaths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);
        if ~isempty(session.SpikeSorting.RelativePath)
            clustering_paths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name, session.SpikeSorting.RelativePath{1});
        else
            clustering_paths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);
        end
    end
elseif ~isempty(sessionIDs)
    for iii = 1:length(sessionIDs)
        disp(['Loading ', num2str(iii), ' of ', num2str(length(sessionIDs)),': ', sessionIDs{iii}])
        sessions = bz_load_sessions('id',sessionIDs{iii});
        session = sessions{1};
        basepaths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);
        if ~isempty(session.SpikeSorting.RelativePath)
            clustering_paths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name, session.SpikeSorting.RelativePath{1});
        else
            clustering_paths{iii} = fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name);
        end
    end
elseif ~isempty(clusteringpaths)
    clustering_paths = clusteringpaths;
else
    warning('Input not sufficient')
end

for iii = 1:length(clustering_paths)
    cell_metrics2{iii} = load(fullfile(clustering_paths{iii},[saveAs,'.mat']));
    subfields2 = [subfields2(:);fieldnames(cell_metrics2{iii}.cell_metrics)];
    temp = struct2cell(structfun(@class,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldstypes = [subfieldstypes(:);temp(:)];
    temp2 = struct2cell(structfun(@size,cell_metrics2{iii}.cell_metrics,'UniformOutput',false));
    subfieldssizes = [subfieldssizes(:);temp2(:)];
end

[cell_metrics_fieldnames,ia,~] = unique(subfields2);
subfieldstypes = subfieldstypes(ia);
subfieldssizes = subfieldssizes(ia);
subfieldstypes(contains(cell_metrics_fieldnames,{'TruePositive','FalsePositive'})) = [];
subfieldssizes(contains(cell_metrics_fieldnames,{'TruePositive','FalsePositive'})) = [];
cell_metrics_fieldnames(contains(cell_metrics_fieldnames,{'TruePositive','FalsePositive'})) = [];
h = 0;
cell_metrics_batch = [];
for iii = 1:length(cell_metrics2)
    if exist('sessionNames') && ~isempty(sessionNames)
        disp(['Concatenating ', num2str(iii), '/', num2str(length(cell_metrics2)),': ', sessionNames{iii}])
    else
        disp(['Concatenating ', num2str(iii), '/', num2str(length(cell_metrics2)),': ', clustering_paths{iii}])
    end
    cell_metrics = cell_metrics2{iii}.cell_metrics;
    hh = size(cell_metrics.CellID,2);
    if iii == 1
        cell_metrics_batch = cell_metrics;
        cell_metrics_batch.General.basename = 'Batch of sessions';
    end
    cell_metrics_batch.BatchIDs(h+1:hh+h) = iii*ones(1,hh);
    cell_metrics_batch.General.Batch{iii} = cell_metrics.General;
    cell_metrics_batch.General.Paths{iii} = clustering_paths{iii};
    if ~isempty(basepaths{iii})
        cell_metrics_batch.General.basepaths{iii} = basepaths{iii};
    else
        cell_metrics_batch.General.basepaths{iii} = clustering_paths{iii};
    end
    
    for ii = 1:length(cell_metrics_fieldnames)
%         if strcmp(cell_metrics_fieldnames{ii},'DeepSuperficial')
%            1
%         end
        if ~isfield(cell_metrics,cell_metrics_fieldnames{ii}) && ~strcmp(cell_metrics_fieldnames{ii},'PutativeConnections')
            if strcmp(subfieldstypes{ii},'double')
                if length(subfieldssizes{ii})==3

                elseif length(subfieldssizes{ii})==2 && subfieldssizes{ii}(1) > 0
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = nan(subfieldssizes{ii}(1:end-1),hh);
                else
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                end
            elseif strcmp(subfieldstypes{ii},'cell')
                cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = repmat({''},1,size(cell_metrics.CellID,2));
            end
        else
            if strcmp(cell_metrics_fieldnames{ii},'PutativeConnections')
                if iii > 1
                    cell_metrics_batch.(cell_metrics_fieldnames{ii}) = [cell_metrics_batch.(cell_metrics_fieldnames{ii});cell_metrics.(cell_metrics_fieldnames{ii})+h];
                end
            elseif strcmp(subfieldstypes{ii},'double')
                if isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(subfieldssizes{ii})==2 && subfieldssizes{ii}(1) > 0
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = nan(subfieldssizes{ii}(1:end-1),hh);
                elseif isempty(cell_metrics.(cell_metrics_fieldnames{ii})) && length(subfieldssizes{ii})==1
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = nan(1,hh);
                else
                    if length(subfieldssizes{ii})==3
                        for iiii=1:size(cell_metrics.(cell_metrics_fieldnames{ii}),3)
%                             cell_metrics_batch.(cell_metrics_fieldnames{ii}){h+iiii} = cell_metrics.(cell_metrics_fieldnames{ii})(:,:,iiii);
                        end
                    elseif subfieldssizes{ii}(1)>1
                        cell_metrics_batch.(cell_metrics_fieldnames{ii})(:,h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                    else
                        if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii}))
                            cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                        end
                    end
                end
            elseif strcmp(subfieldstypes{ii},'cell')
                if ~isempty(cell_metrics.(cell_metrics_fieldnames{ii}))
                    cell_metrics_batch.(cell_metrics_fieldnames{ii})(h+1:hh+h) = cell_metrics.(cell_metrics_fieldnames{ii});
                end
            end
        end
    end
    h=h+size(cell_metrics.CellID,2);
end
