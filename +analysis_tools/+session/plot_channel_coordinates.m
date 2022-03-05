function out = plot_channel_coordinates(varargin)
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

% This function plots channel coordinates

if isfield(data,'session')  && isfield(data.session,'extracellular') && isfield(data.session.extracellular,'chanCoords')
    chanCoords = data.session.extracellular.chanCoords;
    x_range = range(chanCoords.x);
    y_range = range(chanCoords.y);
    if x_range > y_range
        fig_width = 1600;
        fig_height = ceil(fig_width*y_range/x_range)+200;
    else
        fig_height = 1000;
        fig_width = ceil(fig_height*x_range/y_range)+200;
    end
    fig1 = figure('Name','Channel coordinates','position',[5,5,fig_width,fig_height],'visible','off'); movegui(fig1,'center')
    ax1 = axes(fig1);
    plot(ax1,chanCoords.x,chanCoords.y,'.k'), hold on
    text(ax1,chanCoords.x,chanCoords.y,num2str([1:numel(chanCoords.x)]'),'VerticalAlignment', 'bottom','HorizontalAlignment','center');
    title(ax1,{' ','Channel coordinates',' '}), xlabel(ax1,'X (um)'), ylabel(ax1,'Y (um)')
    set(fig1,'visible','on')
else
    MsgLog('No channel coords data available',4)
end