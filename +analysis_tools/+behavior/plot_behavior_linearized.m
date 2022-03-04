function out = plot_behavior_linearized(varargin)
% This is a wrapper example file for NeuroScope2. 
% Use this wrapper example to make calls from NeuroScope to any other analysis that can be applied to the traces, raw data or any derived data types.
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'ephys',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'UI',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

UI = p.Results.UI;  
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

% This function plots the linearized behavior data

if isfield(data,'behavior') 
    behaviors = fieldnames(data.behavior);
    for i = 1:numel(behaviors)
        if isfield(data.behavior.(behaviors{i}),'position') && isfield(data.behavior.(behaviors{i}).position,'linearized')
            figure, 
            line(data.behavior.(behaviors{i}).timestamps,data.behavior.(behaviors{i}).position.linearized,'Marker','.','LineStyle','none','HitTest','off');
            axis tight, xlabel('Time (sec)'), ylabel('Linearized position'), title(['Behavior: ' behaviors{i}])
        end
    end
else
    msgbox('Load the behavior data before plotting.','NeuroScope2','help')
end
