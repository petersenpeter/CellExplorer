function snapshot = captureMetricView(figureHandle)
%CAPTUREMETRICVIEW Capture properties changed by legacy session initialization.
snapshot = struct('handle',{},'properties',{});
handles = findall(figureHandle);
properties = {'String','Data','Min','Max','Value','ForegroundColor','Visible','Enable','Name','Checked','SelectedTab'};
for index = 1:numel(handles)
    handle = handles(index); type = get(handle,'Type');
    if ~ismember(type,{'uicontrol','uitable','uimenu','figure','uitabgroup'}), continue; end
    saved = struct();
    for key = properties
        if isprop(handle,key{1}), saved.(key{1}) = get(handle,key{1}); end
    end
    snapshot(end+1) = struct('handle',handle,'properties',saved);
end
end
