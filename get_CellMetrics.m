function [cell_metrics_idxs, cell_metrics] = get_CellMetrics(varargin)
%   This function calculates cell metrics for a given recording/session
%   Most metrics are single value per cell, either numeric or string type, but
%   certain metrics are vectors like the autocorrelograms or cell with double content like waveforms.
%   The metrics are based on a number of features: Spikes, Waveforms, PCA features,
%   the ACG and CCGs, LFP, theta, ripples and so fourth
%
%   Check the wiki of the Cell Explorer for more details: https://github.com/petersenpeter/Cell-Explorer/wiki
%
%   INPUTS
%   id                     - takes a database id as input
%   session                - takes a database sessionName as input
%   basepath               - path to session (base directory)
%   clusteringpath         - path to cluster data if different from basepath
%   metrics                - which metrics should be calculated. A cell with strings
%   Examples:                'waveform_metrics','PCA_features','acg_metrics','deepSuperficial',
%                            'ripple_metrics','monoSynaptic_connections','spatial_metrics'
%                            'perturbation_metrics','theta_metrics','psth_metrics'
%   excludeMetrics         - Any metrics to exclude
%   removeMetrics          - Any metrics to remove (supports only deepSuperficial at this point)
%   useNeurosuiteWaveforms - Use Neurosuite files to get waveforms and PCAs
%   forceReload            - logical. Recalculate existing metrics
%   saveMat                - save metrics to cell_metrics.mat
%
%   OUTPUT
%   cell_metrics_idxs       - indexes of cells fulfilling filters*
%   cell_metrics            - Cell_metrics matlab structure

% By Peter Petersen
% petersen.peter@gmail.com
% 24-05-2019


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
addParameter(p,'clusteringpath',pwd,@isstr);

% Batch input
addParameter(p,'sessionIDs',{},@iscell);
addParameter(p,'sessions',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'clusteringpaths',{},@iscell);

% Extra inputs
addParameter(p,'metrics','all',@iscellstr);
addParameter(p,'excludeMetrics','none',@iscellstr);
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

parse(p,varargin{:})

% Load an existing cell metrics struct 
cell_metrics = p.Results.cell_metrics;

% Single session input
id = p.Results.id;
sessionin = p.Results.session;
basepath = p.Results.basepath;
clusteringpath = p.Results.clusteringpath;

% Extra inputs
metrics = p.Results.metrics;
excludeMetrics = p.Results.excludeMetrics;
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

if ~isempty(cell_metrics)
    disp('')
elseif ~isempty(id) || ~isempty(sessionin)
    bz_database = db_credentials;
    if ~isempty(id)
        [session, basename, basepath, clusteringpath] = db_set_path('id',id);
    else
        [session, basename, basepath, clusteringpath] = db_set_path('session',sessionin);
    end
    if exist(fullfile(clusteringpath,[saveAs,'.mat']),'file')
        disp(['Loading existing metrics: ' saveAs])
        load(fullfile(clusteringpath,[saveAs,'.mat']))
    else
        warning(['Error loading metrics: ' fullfile(clusteringpath,[saveAs,'.mat'])])
    end
elseif ~isempty(sessions)
    cell_metrics = LoadCellMetricBatch('sessions',sessions);
end

filterIndx = ones(length(cell_metrics.UID),6);
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
if ~isempty(tags)
    for i = 1:length(cell_metrics.UID)
        if ~isempty(cell_metrics.tags{i})
            filterIndx(i,6) = any(strcmp(cell_metrics.tags{i},tags));
        else
            filterIndx(i,6) = 0;
        end
    end
end

cell_metrics_idxs = find(sum(filterIndx')==6);

