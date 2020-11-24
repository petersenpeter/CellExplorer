function UI = defineSupplementaryPlot(UI)

supplementaryFigure.dialog = dialog('Position',[300 300 500 225],'Name','Select features for supplementary figure','visible','off'); movegui(supplementaryFigure.dialog,'center'), set(supplementaryFigure.dialog,'visible','on')
UI.uitabgroup = uitabgroup('Units','normalized','Position',[0 0.12 1 0.88],'Parent',supplementaryFigure.dialog,'Units','normalized');
UI.tabs.histograms(1) = uitab(UI.uitabgroup,'Title','Scatter plot','tooltip',sprintf('session.general: \nGeneral information about the dataset'));
UI.tabs.histograms(2) = uitab(UI.uitabgroup,'Title','Color groups','tooltip',sprintf('session.general: \nGeneral information about the dataset'));
UI.tabs.histograms(3) = uitab(UI.uitabgroup,'Title','Population','tooltip',sprintf('session.general: \nGeneral information about the dataset'));

% Waveform normalization (z-scored/amplitude)
uicontrol('Parent',UI.tabs.histograms(1),'Style', 'text', 'String', 'Waveform normalization', 'Position', [20, 40, 140, 15],'HorizontalAlignment','left');
supplementaryFigure.waveformNormalization = uicontrol('Parent',UI.tabs.histograms(1),'Style', 'popupmenu', 'String', {'Z-scored','Absolute (uV)'}, 'Value',1,'Position', [10, 10, 140, 25],'HorizontalAlignment','left');

% Waveform normalization (z-scored/amplitude)
uicontrol('Parent',UI.tabs.histograms(2),'Style', 'text', 'String', 'Group data normalization', 'Position', [20, 40, 140, 15],'HorizontalAlignment','left');
supplementaryFigure.groupDataNormalization = uicontrol('Parent',UI.tabs.histograms(2),'Style', 'popupmenu', 'String', {'By peak','By probability'}, 'Value',1,'Position', [10, 10, 140, 25],'HorizontalAlignment','left');

% Histograms
predefinedMetrics = {'troughToPeak','acg_tau_rise','firingRate','cv2','peakVoltage','isolationDistance','lRatio','refractoryPeriodViolation'};
fieldsMenu = fieldsMenu;
listOffsets = 30*[4,3,4,3,4,3,2,1]-20;
listTabs = [1,1,2,2,3,3,3,3];
for iMetrics = 1:numel(predefinedMetrics)
    supplementaryFigure.metricsList(iMetrics) = uicontrol('Parent',UI.tabs.histograms(listTabs(iMetrics)),'Style','popupmenu','Position',[10, listOffsets(iMetrics), 280, 25],'String',fieldsMenu,'Value',find(strcmp(fieldsMenu,predefinedMetrics{iMetrics})),'HorizontalAlignment','left');    
    supplementaryFigure.axisScale(iMetrics) = uicontrol('Parent',UI.tabs.histograms(listTabs(iMetrics)),'Style', 'popupmenu', 'String', {'Lin','Log'}, 'Value',2,'Position', [310, listOffsets(iMetrics), 80, 25],'HorizontalAlignment','left');
    supplementaryFigure.smoothing(iMetrics) = uicontrol('Parent',UI.tabs.histograms(listTabs(iMetrics)),'Style', 'popupmenu', 'String', {'Yes','No'}, 'Value',1,'Position', [400, listOffsets(iMetrics), 80, 25],'HorizontalAlignment','left');
end
uicontrol('Parent',UI.tabs.histograms(1),'Style', 'text', 'String', 'Scatter plot (x and y data)', 'Position', [20, listOffsets(1)+30, 180, 15],'HorizontalAlignment','left');
uicontrol('Parent',UI.tabs.histograms(2),'Style', 'text', 'String', 'Group data histograms (2 plots)', 'Position', [20, listOffsets(3)+30, 180, 15],'HorizontalAlignment','left');
uicontrol('Parent',UI.tabs.histograms(3),'Style', 'text', 'String', 'Population histograms (4 plots)', 'Position', [20, listOffsets(5)+30, 180, 15],'HorizontalAlignment','left');
uicontrol('Parent',UI.tabs.histograms(2),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(3)+30, 80, 15],'HorizontalAlignment','center');
uicontrol('Parent',UI.tabs.histograms(2),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(3)+30, 80, 15],'HorizontalAlignment','center');
uicontrol('Parent',UI.tabs.histograms(3),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(5)+30, 80, 15],'HorizontalAlignment','center');
uicontrol('Parent',UI.tabs.histograms(3),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(5)+30, 80, 15],'HorizontalAlignment','center');
uicontrol('Parent',UI.tabs.histograms(1),'Style', 'text', 'String', 'Axis scale', 'Position', [310, listOffsets(1)+30, 80, 15],'HorizontalAlignment','center');
uicontrol('Parent',UI.tabs.histograms(1),'Style', 'text', 'String', 'Smoothing', 'Position', [400, listOffsets(1)+30, 80, 15],'HorizontalAlignment','center');

% Buttons
supplementaryFigure.button.ok = uicontrol('Parent',supplementaryFigure.dialog,'Style','pushbutton','Position',[10, 10, 235, 30],'String','OK','Callback',@(src,evnt)close_with_ok);
supplementaryFigure.button.cancel = uicontrol('Parent',supplementaryFigure.dialog,'Style','pushbutton','Position',[260, 10, 235, 30],'String','Cancel','Callback',@(src,evnt)close_with_cancel);

% uicontrol(supplementaryFigure.cellIDs)
uiwait(supplementaryFigure.dialog);

function close_with_ok
    delete(supplementaryFigure.dialog);
%     UI.supplementaryFigure.
end

function close_with_cancel
    delete(supplementaryFigure.dialog);
end
end