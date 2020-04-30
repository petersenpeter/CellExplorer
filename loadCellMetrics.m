function [cell_metrics_idxs, cell_metrics] = LoadCellMetrics(varargin)
%   This function loads cell metrics for a given session

%
%   Check the wiki of the CellExplorer for more details: https://github.com/petersenpeter/CellExplorer/wiki
%
%   INPUTS
%   id                     - takes a database id as input
%   session                - takes a database sessionName as input
%   basepath               - path to session (base directory)
%   clusteringpath         - path to cluster data if different from basepath
%   Filters:
%       brainRegion, synapticEffect, putativeCellType, labels, deepSuperficial, animal, tags, groups, groundTruthClassification
%
%   OUTPUT
%   cell_metrics_idxs       - indexes of cells fulfilling filters*
%   cell_metrics            - Cell_metrics matlab structure

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 5-04-2020


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Parsing parameters
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
p = inputParser;

% Load an existing cell metrics struct 
addParameter(p,'cell_metrics',{},@isstruct);

% Single session input
addParameter(p,'id',[],@isnumeric);
addParameter(p,'session',[],@isstr);
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'basename','',@isstr);
addParameter(p,'clusteringpath',pwd,@isstr);

% Batch input
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'clusteringpaths',{},@iscell);

% Extra inputs
addParameter(p,'saveAs','cell_metrics',@isstr);

% Filters
addParameter(p,'filter',[],@iscell);
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

% Load an existing cell metrics struct 
cell_metrics = p.Results.cell_metrics;

% Single session input
id = p.Results.id;
sessionin = p.Results.session;
basepath = p.Results.basepath;
basename = p.Results.basename;
clusteringpath = p.Results.clusteringpath;

% Extra inputs
saveAs = p.Results.saveAs;

% Batch input
sessionIDs = p.Results.sessionIDs;
sessions = p.Results.sessions;
basepaths = p.Results.basepaths;
clusteringpaths = p.Results.clusteringpaths;

% Filters
filter = p.Results.filter;
brainRegion = p.Results.brainRegion;
synapticEffect = p.Results.synapticEffect;
putativeCellType = p.Results.putativeCellType;
labels = p.Results.labels;
deepSuperficial = p.Results.deepSuperficial;
animal = p.Results.animal;
tags = p.Results.tags;
groups = p.Results.groups;
groundTruthClassification = p.Results.groundTruthClassification;

if isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

if ~isempty(cell_metrics)
    disp('')
elseif ~isempty(id) || ~isempty(sessionin)
    bz_database = db_credentials;
    if ~isempty(id)
        [session, basename, basepath, clusteringpath] = db_set_session('sessionId',id);
    else
        [session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionin);
    end
    if exist(fullfile(basepath,clusteringpath,[basename,'.' ,saveAs,'.cellinfo.mat']),'file')
        load(fullfile(basepath,clusteringpath,[basename,'.' ,saveAs,'.cellinfo.mat']))
    else
        warning(['Error loading metrics: ' fullfile(basepath,clusteringpath,[basename,'.' ,saveAs,'.cellinfo.mat'])])
    end
elseif ~isempty(sessions)
    cell_metrics = LoadCellMetricsBatch('sessions',sessions);
end

filterIndx = ones(length(cell_metrics.UID),9);
if ~isempty(brainRegion)
    filterIndx(:,1) = strcmp(cell_metrics.brainRegion,brainRegion);
end
if ~isempty(synapticEffect)
    filterIndx(:,2) = contains(cell_metrics.synapticEffect,synapticEffect);
end
if ~isempty(putativeCellType)
    filterIndx(:,3) = contains(cell_metrics.putativeCellType,putativeCellType);
end
if ~isempty(deepSuperficial)
    filterIndx(:,4) = contains(cell_metrics.deepSuperficial,deepSuperficial);
end
if ~isempty(animal)
    filterIndx(:,5) = strcmp(cell_metrics.animal,animal);
end
if ~isempty(labels)
    filterIndx(:,6) = strcmp(cell_metrics.labels,labels);
end
if ~isempty(tags)
    filterIndx(:,7) = 0;
    for i = 1:numel(tags)
         if isfield(cell_metrics.tags,tags{i})
             filterIndx(cell_metrics.tags.(tags{i}),7) = 1;
         end
    end
end
if ~isempty(groups)
    filterIndx(:,8) = 0;
    for i = 1:numel(groups)
         if isfield(cell_metrics.groups,groups{i})
             filterIndx(cell_metrics.groups.(groups{i}),8) = 1;
         end
    end
end
if ~isempty(groundTruthClassification)
    filterIndx(:,9) = 0;
    for i = 1:numel(groundTruthClassification)
         if isfield(cell_metrics.tags,groundTruthClassification{i})
             filterIndx(cell_metrics.groundTruthClassification.(groundTruthClassification{i}),9) = 1;
         end
    end
end
cell_metrics_idxs = find(sum(filterIndx')==9);

