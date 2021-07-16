function [cell_metrics,cell_metrics_idxs] = loadCellMetrics(varargin)
% This function loads cell metrics for a given session
% Check the wiki of the CellExplorer for more details: https://cellexplorer.org/
%
% INPUTS
%   id                     - takes a database id as input
%   session                - takes a database sessionName as input
%   basepath               - path to session (base directory)
%
%   Filters:
%       brainRegion, synapticEffect, putativeCellType, labels, deepSuperficial, animal, tags, groups, groundTruthClassification
%
% OUTPUT
%   cell_metrics            - Cell_metrics matlab structure
%   cell_metrics_idxs       - indexes of cells fulfilling filters*
% 
% Example calls
%   cell_metrics = loadCellMetrics('basepath',pwd);
%   cell_metrics = loadCellMetrics('session',session);
%   cell_metrics = loadCellMetrics('fileFormat','json')
%   cell_metrics = loadCellMetrics('fileFormat','nwb')
%   [cell_metrics,Pyramidal_indexes] = loadCellMetrics('session',session,'putativeCellType',{'Pyramidal'});
% 

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 06-07-2021

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Parsing parameters
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
p = inputParser;

% Load an existing cell metrics struct 
addParameter(p,'cell_metrics',{},@isstruct);

% Single session input
addParameter(p,'basepath',[],@isstr);
addParameter(p,'basename','',@isstr);
addParameter(p,'session',[],@isstruct);
addParameter(p,'sessionId',[],@isnumeric);
addParameter(p,'sessionName',[],@isstr);

% Batch input (not implemented)
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessionNames',{},@iscell);
addParameter(p,'basepaths',{},@iscell);

% Extra inputs
addParameter(p,'saveAs','cell_metrics',@isstr); % Cell metrics name
addParameter(p,'fileFormat','mat',@isstr); % File format (options: mat,nwb,json)

% Filters
addParameter(p,'brainRegion',[],@iscell);
addParameter(p,'synapticEffect',[],@iscell);
addParameter(p,'putativeCellType',[],@iscell);
addParameter(p,'labels',[],@iscell);
addParameter(p,'deepSuperficial',[],@iscell);
addParameter(p,'animal',[],@iscell);
addParameter(p,'tags',[],@iscell);
addParameter(p,'groups',[],@iscell);
addParameter(p,'groundTruthClassification',[],@iscell);

parse(p,varargin{:})

% Provide existing cell metrics struct
cell_metrics = p.Results.cell_metrics;

% Single session input
sessionId = p.Results.sessionId; 

session = p.Results.session; 
basepath = p.Results.basepath;
basename = p.Results.basename;

% Batch
sessions = p.Results.sessionNames; 

params = p.Results;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Loading metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

if ~isempty(cell_metrics)
    
elseif ~isempty(session)
    basepath = session.general.basePath;
    basename = session.general.name;

elseif ~isempty(sessions)
    cell_metrics = loadCellMetricsBatch('sessions',sessions);
    
elseif ~isempty(sessionId) || ~isempty(params.sessionName)
    bz_database = db_credentials;
    if ~isempty(sessionId)
        [~, basename, basepath] = db_set_session('sessionId',sessionId);
    else
        [~, basename, basepath] = db_set_session('sessionName',params.sessionName);
    end
else
    if isempty(basepath)
        basepath = pwd;
    end
    if isempty(basename)
        s = regexp(basepath, filesep, 'split');
        if isempty(s{end})
            s = s(1:end-1);
        end
        basename = s{end};
    end
end

file = fullfile(basepath,[basename,'.' ,params.saveAs,'.cellinfo.',params.fileFormat]);

% Loading metrics

if exist(file,'file')
    switch lower(params.fileFormat)
        case 'mat'
            load(file,'cell_metrics')
            cell_metrics.general.basepath = basepath;
            cell_metrics.general.fileFormat = params.fileFormat;
            
        case 'nwb'
            cell_metrics = loadNwbCellMetrics(file);
            
        case 'json'
            cell_metrics = loadJsonCellMetrics(file);

        otherwise
            warning(['Unknown cell_metrics file format: ' file])
    end
else
    warning(['Error loading metrics: ' file])
    return
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Filtering metrics
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

filterIndx = ones(length(cell_metrics.UID),9);
if ~isempty(params.brainRegion)
    filterIndx(:,1) = strcmp(cell_metrics.brainRegion,params.brainRegion);
end
if ~isempty(params.synapticEffect)
    filterIndx(:,2) = contains(cell_metrics.synapticEffect,params.synapticEffect);
end
if ~isempty(params.putativeCellType)
    filterIndx(:,3) = contains(cell_metrics.putativeCellType,params.putativeCellType);
end
if ~isempty(params.deepSuperficial)
    filterIndx(:,4) = contains(cell_metrics.deepSuperficial,params.deepSuperficial);
end
if ~isempty(params.animal)
    filterIndx(:,5) = strcmp(cell_metrics.animal,params.animal);
end
if ~isempty(params.labels)
    filterIndx(:,6) = strcmp(cell_metrics.labels,params.labels);
end
if ~isempty(params.tags)
    filterIndx(:,7) = 0;
    for i = 1:numel(params.tags)
         if isfield(cell_metrics.tags,params.tags{i})
             filterIndx(cell_metrics.tags.(params.tags{i}),7) = 1;
         end
    end
end

if ~isempty(params.groups)
    filterIndx(:,8) = 0;
    for i = 1:numel(params.groups)
         if isfield(cell_metrics.groups,params.groups{i})
             filterIndx(cell_metrics.groups.(params.groups{i}),8) = 1;
         end
    end
end

if ~isempty(params.groundTruthClassification)
    filterIndx(:,9) = 0;
    for i = 1:numel(params.groundTruthClassification)
         if isfield(cell_metrics.tags,params.groundTruthClassification{i})
             filterIndx(cell_metrics.groundTruthClassification.(params.groundTruthClassification{i}),9) = 1;
         end
    end
end
cell_metrics_idxs = find(sum(filterIndx')==9);
