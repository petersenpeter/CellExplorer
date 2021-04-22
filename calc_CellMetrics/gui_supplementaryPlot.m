function UI = gui_supplementaryPlot(UI)
if ~exist('UI','var') || ~isfield(UI,'supplementaryFigure')
    % Loading default parameters
    UI.supplementaryFigure.waveformNormalization = 1;
    UI.supplementaryFigure.groupDataNormalization = 1;
    UI.supplementaryFigure.metrics = {'troughToPeak'  'acg_tau_rise'  'firingRate'  'cv2'  'peakVoltage'  'isolationDistance'  'lRatio'  'refractoryPeriodViolation'};
    UI.supplementaryFigure.axisScale = [1 2 2 2 2 2 2 2];
    UI.supplementaryFigure.smoothing = [1 1 1 1 1 1 1 1];
end
listOffsets = 30*[4,3,4,3,4,3,2,1]-20;
listTabs = [1,1,2,2,3,3,3,3];

supplementaryFigure.dialog = dialog('Position',[300 300 500 225],'Name','Select features for supplementary figure','visible','off'); movegui(supplementaryFigure.dialog,'center'), set(supplementaryFigure.dialog,'visible','on')
supplementaryFigure.uitabgroup = uitabgroup('Units','normalized','Position',[0 0.13 1 0.865],'Parent',supplementaryFigure.dialog,'Units','normalized');
supplementaryFigure.tabs.histograms(1) = uitab(supplementaryFigure.uitabgroup,'Title','Scatter plot','tooltip',sprintf('session.general: \nGeneral information about the dataset'));
supplementaryFigure.tabs.histograms(2) = uitab(supplementaryFigure.uitabgroup,'Title','Color groups','tooltip',sprintf('session.general: \nGeneral information about the dataset'));
supplementaryFigure.tabs.histograms(3) = uitab(supplementaryFigure.uitabgroup,'Title','Population','tooltip',sprintf('session.general: \nGeneral information about the dataset'));

% Waveform normalization (z-scored/amplitude)
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style', 'text', 'String', 'Waveform normalization', 'Position', [20, 40, 140, 15],'HorizontalAlignment','left');
supplementaryFigure.waveformNormalization = uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style', 'popupmenu', 'String', {'Z-scored','Absolute (uV)'}, 'Value',UI.supplementaryFigure.waveformNormalization,'Position', [10, 10, 140, 25],'HorizontalAlignment','left');

% Group data normalization
uicontrol('Parent',supplementaryFigure.tabs.histograms(2),'Style', 'text', 'String', 'Group data normalization', 'Position', [20, 40, 140, 15],'HorizontalAlignment','left');
supplementaryFigure.groupDataNormalization = uicontrol('Parent',supplementaryFigure.tabs.histograms(2),'Style', 'popupmenu', 'String', {'Peak','Probability','Count'}, 'Value',UI.supplementaryFigure.groupDataNormalization,'Position', [10, 10, 140, 25],'HorizontalAlignment','left');

% Histograms
for iMetrics = 1:numel(UI.supplementaryFigure.metrics)
    value = find(strcmp(UI.lists.metrics,UI.supplementaryFigure.metrics{iMetrics}));
    if isempty(value)
        value = 1;
    end
    supplementaryFigure.metricsList(iMetrics) = uicontrol('Parent',supplementaryFigure.tabs.histograms(listTabs(iMetrics)),'Style','popupmenu','Position',[10, listOffsets(iMetrics), 280, 25],'String',UI.lists.metrics,'Value',value,'HorizontalAlignment','left');
    supplementaryFigure.axisScale(iMetrics) = uicontrol('Parent',supplementaryFigure.tabs.histograms(listTabs(iMetrics)),'Style', 'popupmenu', 'String', {'Linear','Log'}, 'Value',UI.supplementaryFigure.axisScale(iMetrics),'Position', [310, listOffsets(iMetrics), 80, 25],'HorizontalAlignment','left');
    supplementaryFigure.smoothing(iMetrics) = uicontrol('Parent',supplementaryFigure.tabs.histograms(listTabs(iMetrics)),'Style', 'popupmenu', 'String', {'Yes','No'}, 'Value',UI.supplementaryFigure.smoothing(iMetrics),'Position', [400, listOffsets(iMetrics), 80, 25],'HorizontalAlignment','left');
end
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style', 'text', 'String', 'Scatter plot (x and y data)', 'Position', [20, listOffsets(1)+30, 180, 15], 'HorizontalAlignment','left');
uicontrol('Parent',supplementaryFigure.tabs.histograms(2),'Style', 'text', 'String', 'Group data histograms (2 plots)', 'Position', [20, listOffsets(3)+30, 180, 15], 'HorizontalAlignment','left');
uicontrol('Parent',supplementaryFigure.tabs.histograms(3),'Style', 'text', 'String', 'Population histograms (4 plots)', 'Position', [20, listOffsets(5)+30, 180, 15], 'HorizontalAlignment','left');
uicontrol('Parent',supplementaryFigure.tabs.histograms(2),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(3)+30, 80, 15], 'HorizontalAlignment','center');
uicontrol('Parent',supplementaryFigure.tabs.histograms(2),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(3)+30, 80, 15], 'HorizontalAlignment','center');
uicontrol('Parent',supplementaryFigure.tabs.histograms(3),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(5)+30, 80, 15], 'HorizontalAlignment','center');
uicontrol('Parent',supplementaryFigure.tabs.histograms(3),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(5)+30, 80, 15], 'HorizontalAlignment','center');
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(1)+30, 80, 15], 'HorizontalAlignment','center');
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(1)+30, 80, 15], 'HorizontalAlignment','center');

uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','text','Position',[165, 42, 120, 15],'String','Export options','HorizontalAlignment','left');
supplementaryFigure.popupmenu.saveFigure = uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','checkbox','Position',[160, 12, 120, 25],'String','Save figures','HorizontalAlignment','left');
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','text','Position',[260, 42, 140, 15],'String','File format','HorizontalAlignment','left');
supplementaryFigure.popupmenu.fileFormat = uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','popupmenu','Position',[250, 10, 100, 25],'String',{'png','pdf'},'HorizontalAlignment','left');
uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','text','Position',[370, 42, 140, 15],'String','File path','HorizontalAlignment','left');
supplementaryFigure.popupmenu.savePath = uicontrol('Parent',supplementaryFigure.tabs.histograms(1),'Style','popupmenu','Position',[360, 10, 120, 25],'String',{'basepath','CellExplorer','Define path'},'HorizontalAlignment','left');

% Buttons
supplementaryFigure.button.ok = uicontrol('Parent',supplementaryFigure.dialog,'Style','pushbutton','Position',[10, 10, 240, 30],'String','OK','Callback',@(src,evnt)close_with_ok);
supplementaryFigure.button.cancel = uicontrol('Parent',supplementaryFigure.dialog,'Style','pushbutton','Position',[260, 10, 230, 30],'String','Cancel','Callback',@(src,evnt)close_with_cancel);

% uicontrol(supplementaryFigure.cellIDs)
uiwait(supplementaryFigure.dialog);

function close_with_ok
    UI.supplementaryFigure.waveformNormalization = supplementaryFigure.waveformNormalization.Value;
    UI.supplementaryFigure.groupDataNormalization = supplementaryFigure.groupDataNormalization.Value;
    for iMetrics = 1:numel(UI.supplementaryFigure.metrics)
    	UI.supplementaryFigure.metrics{iMetrics} = UI.lists.metrics{supplementaryFigure.metricsList(iMetrics).Value};
        UI.supplementaryFigure.axisScale(iMetrics) = supplementaryFigure.axisScale(iMetrics).Value;
        UI.supplementaryFigure.smoothing(iMetrics) = supplementaryFigure.smoothing(iMetrics).Value;
    end
    UI.supplementaryFigure.saveFigure = supplementaryFigure.popupmenu.saveFigure.Value;
    UI.supplementaryFigure.fileFormat = supplementaryFigure.popupmenu.fileFormat.Value;
    UI.supplementaryFigure.savePath = supplementaryFigure.popupmenu.savePath.Value;
    delete(supplementaryFigure.dialog);
end

function close_with_cancel
    delete(supplementaryFigure.dialog);
end
end