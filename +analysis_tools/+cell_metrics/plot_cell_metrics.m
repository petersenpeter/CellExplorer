function out = plot_cell_metrics(varargin)
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

% This function generates a summary plot with metrics from CellExplorer

if isfield(data,'cell_metrics')
    unitList = cellstr(num2str([1:data.cell_metrics.general.cellCount]'));
    [indx,tf] = listdlg('ListString',unitList,'Name','Select cells','InitialValue',UI.selectedUnits);
    if tf
        if numel(indx)>0 && numel(indx) ~= data.cell_metrics.general.cellCount
            CellExplorer('metrics',data.cell_metrics,'summaryFigures',true,'plotCellIDs',indx,'selectSummaryPlotSubset',true,'keepSummaryFigures',true);
        else
            CellExplorer('metrics',data.cell_metrics,'summaryFigures',true,'plotCellIDs',-1,'selectSummaryPlotSubset',true,'keepSummaryFigures',true);
        end
    end
else
    msgbox('Load cell metrics data before plotting','NeuroScope2','help')
end
