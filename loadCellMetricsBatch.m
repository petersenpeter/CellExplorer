function cell_metrics_batch = loadCellMetricsBatch(varargin)
% Load metrics across sessions and concats the metrics into a single struct
% with the appropriate format for each field.
%
% INPUTS:
% varargin: Described below
%
% OUTPUT:
% cell_metrics_batch. Combined cell metrics batch file from selected sessions that can be opened with CellExplorer

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 18-07-2021

% - Example calls:
% cell_metrics = loadCellMetricsBatch('basepaths',{'basepath1','basepath2'},'basenames',{'basename1','basename2'});
% cell_metrics = loadCellMetricsBatch('sessions',{'rec1','rec2'}) % Load batch from database
% cell_metrics = loadCellMetricsBatch('sessionIDs',[10985,10985]) % Load session from database session id

% Local loading never reads database settings. headless suppresses progress UI.
p = inputParser;
addParameter(p,'sessionIDs',[],@isnumeric);
addParameter(p,'sessions',{},@iscellstr);
addParameter(p,'basepaths',{},@iscellstr);
addParameter(p,'basenames',{},@iscellstr);
addParameter(p,'saveAs','cell_metrics',@ischar);
addParameter(p,'waitbar_handle',[],@(x) isempty(x) || isscalar(x));
addParameter(p,'headless',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'showProgress',true,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:}); options = p.Results;
if ~isempty(options.basepaths) && (~isempty(options.sessions) || ~isempty(options.sessionIDs))
    error('ce:io:AmbiguousMetricSource','Choose local basepaths or database session selectors.');
end
[progress,cleanup] = ce.ui.metricLoadProgress(~options.headless && options.showProgress,options.waitbar_handle); %#ok<ASGLU>
basepaths = options.basepaths; basenames = options.basenames;
if ~isempty(options.sessions) || ~isempty(options.sessionIDs)
    [basepaths,basenames] = ce.integrations.resolveMetricSessions(options.sessions,options.sessionIDs);
end
cell_metrics_batch = ce.io.loadMetricBatch(basepaths,basenames,options.saveAs,progress);
end
