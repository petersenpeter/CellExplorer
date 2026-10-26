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

% Batch input (MAT files)
addParameter(p,'sessionIDs',[],@isnumeric);
addParameter(p,'sessionNames',{},@iscell);
addParameter(p,'basepaths',{},@iscell);
addParameter(p,'basenames',{},@iscellstr);
addParameter(p,'headless',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'showProgress',true,@(x) islogical(x) && isscalar(x));

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

params = p.Results;
cell_metrics = params.cell_metrics;
cell_metrics_idxs = [];
if ~isempty(cell_metrics)
    % Supplied data are filtered directly; never attempt an unrelated file load.
elseif ~isempty(params.basepaths) || ~isempty(params.sessionNames) || ~isempty(params.sessionIDs)
    if ~strcmpi(params.fileFormat,'mat')
        error('ce:io:UnsupportedBatchFormat','Batch loading supports MAT files; load JSON/NWB sessions individually.');
    end
    cell_metrics = loadCellMetricsBatch('basepaths',params.basepaths,'basenames',params.basenames, ...
        'sessions',params.sessionNames,'sessionIDs',params.sessionIDs,'saveAs',params.saveAs, ...
        'headless',params.headless,'showProgress',params.showProgress);
else
    basepath = params.basepath; basename = params.basename;
    if ~isempty(params.session)
        basepath = params.session.general.basePath; basename = params.session.general.name;
    elseif ~isempty(params.sessionId) || ~isempty(params.sessionName)
        names = {}; if ~isempty(params.sessionName), names = {params.sessionName}; end
        [folders,names] = ce.integrations.resolveMetricSessions(names,params.sessionId);
        if numel(folders) ~= 1, error('ce:io:AmbiguousMetricSource','Use sessionIDs for multiple sessions.'); end
        basepath = folders{1}; basename = names{1};
    end
    if isempty(basepath), basepath = pwd; end
    if isempty(basename), basename = ce.io.basenameFromBasepath(basepath); end
    file = fullfile(basepath,[basename,'.',params.saveAs,'.cellinfo.',params.fileFormat]);
    switch lower(params.fileFormat)
        case 'mat'
            cell_metrics = ce.io.readCellMetrics(file);
            cell_metrics.general.basepath = basepath;
            cell_metrics.general.fileFormat = params.fileFormat;
            cell_metrics.general.saveAs = params.saveAs;
        case 'json'
            cell_metrics = loadJsonCellMetrics(file); % Legacy format adapter.
        case 'nwb'
            cell_metrics = loadNwbCellMetrics(file); % Legacy MatNWB adapter.
        otherwise
            error('ce:io:UnsupportedFormat','Unsupported metrics format: %s.',params.fileFormat);
    end
end
cell_metrics_idxs = ce.data.filterMetricCells(cell_metrics,params);
end
