function out = plot_CCGs(varargin)
% This function can be called from NeuroScope2 via the menu Analysis

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'UI',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'ephys',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

UI = p.Results.UI;
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % %

% This function generates a spike raster plot

if isfield(data,'spikes')
    plot_cells = UI.selectedUnits;
    unitList = cellstr(num2str([1:data.spikes.numcells]'));
    [plot_cells,tf] = listdlg('ListString',unitList,'Name','Select cells','InitialValue',plot_cells);
    if tf

        if ~isfield(data.spikes,'spindices')
            data.spikes.spindices = generateSpinDices(data.spikes.times(subset1));
        end
        spike_times = data.spikes.spindices(:,1);
        spike_cluster_index = data.spikes.spindices(:,2);
        [~, ~, spike_cluster_index] = unique(spike_cluster_index);
        sr = data.session.extracellular.sr;
        [ccg2,time2] = CCG(spike_times,spike_cluster_index,'binSize',0.0005,'duration',0.100,'norm','rate','Fs',1/sr);
        ccgFigure = figure('Name',['CCGs for cell-pairs ', num2str(plot_cells)],'NumberTitle','off','pos',[50 50 800 600],'visible','off');
        
        k = 1;
        try
            ha = ce_tight_subplot(length(plot_cells),length(plot_cells),[.03 .03],[.06 .05],[.04 .05]);
        catch
            MsgLog(['The number of selected cells are too high (', num2str(length(plot_cells)), ')'],4);
            return
        end
                        
        for j = 1:length(plot_cells)
            for jj = 1:length(plot_cells)
                set(ccgFigure,'CurrentAxes',ha(k))
                if jj == j
%                     col1 = UI.preferences.cellTypeColors(clusClas(plot_cells(j)),:);
                    bar_from_patch_centered_bins(time2*1000,ccg2(:,plot_cells(j),plot_cells(jj)),'k')
                    title(['Cell ', num2str(plot_cells(j))]),
%                     xlabel(cell_metrics.putativeCellType{plot_cells(j)})
                else
                    bar_from_patch_centered_bins(time2*1000,ccg2(:,plot_cells(j),plot_cells(jj)),[0.5,0.5,0.5])
                end
                if j == length(plot_cells) && mod(jj,2) == 1 && j~=jj; xlabel('Time (ms)'); end
                if jj == 1 && mod(j,2) == 0; ylabel('Rate (Hz)'); end
                if length(plot_cells)<7
                    xticks([-50:10:50])
                end
                xlim([-50,50])
                if length(plot_cells) > 2 && j < length(plot_cells)
                    set(ha(k),'XTickLabel',[]);
                end
                axis tight, set(ha(k), 'YGrid', 'off', 'XGrid', 'on');
%                 if any(cell_metrics.putativeConnections.excitatory(:,1)==plot_cells(j) & cell_metrics.putativeConnections.excitatory(:,2) ==plot_cells(jj))
%                     text(0,1,[' Exc: ', num2str(plot_cells(j)) ' \rightarrow ', num2str(plot_cells(jj))],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top')
%                 end

%                 if any(cell_metrics.putativeConnections.inhibitory(:,1)==plot_cells(j) & cell_metrics.putativeConnections.inhibitory(:,2) ==plot_cells(jj))
%                     text(1,1,[' Inh: ', num2str(plot_cells(j)) ' \rightarrow ', num2str(plot_cells(jj)),' '],'Units','normalized','Interpreter','tex','VerticalAlignment', 'top','HorizontalAlignment','right')
%                 end

                set(ha(k), 'Layer', 'top')
                k = k+1;
            end
        end
        movegui(ccgFigure,'center'), set(ccgFigure,'visible','on')
    end
else
    msgbox('Load spikes data before plotting CCGs','NeuroScope2','help')
end

function bar_from_patch_centered_bins(x_data, y_data,col)
        x_step = (x_data(2)-x_data(1));
        x_data = x_data-x_step/2;
%         x_data(1) = x_data(1)+x_step;
        x_data(end+1) = x_data(end)+x_step;
        y_data(end+1) = y_data(end);
        x_data = [x_data(1),reshape([x_data,x_data([2:end,end])]',1,[]),x_data(end)];
        y_data = [0,reshape([y_data,y_data]',1,[]),0];
        patch(x_data, y_data,col,'EdgeColor','none','FaceAlpha',.8,'HitTest','off')
end
    
end
