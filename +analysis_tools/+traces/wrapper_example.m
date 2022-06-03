function out = wrapper_example(varargin)
% This is a wrapper example file for NeuroScope2. 
% Use this wrapper example to make calls from NeuroScope to any other analysis that can be applied to the traces, raw data or any derived data types.
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'UI',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'ephys',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

ephys = p.Results.ephys;
UI = p.Results.UI;  
data = p.Results.data;
% session = data.session;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

msgbox('This is a wrapper example function for NeuroScope2.','NeuroScope2 Analysis','help')
