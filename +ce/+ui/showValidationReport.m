function fig = showValidationReport(report)
%SHOWVALIDATIONREPORT Display the same checks available to noninteractive callers.
rows = cell(numel(report.checks),3);
for index = 1:numel(report.checks)
    check = report.checks(index);
    rows(index,:) = {check.path,check.severity,check.message};
end
height = min(700,max(180,24*(size(rows,1)+2)));
fig = figure('Position',[300 300 850 height],'Name','CellExplorer: session validation', ...
    'MenuBar','none','NumberTitle','off','Visible','off');
uitable(fig,'Data',rows,'ColumnName',{'Field','Status','Details'}, ...
    'ColumnWidth',{230 70 520},'RowName',[],'ColumnEditable',[false false false], ...
    'Units','normalized','Position',[0 0 1 1]);
movegui(fig,'center');
set(fig,'Visible','on');
end
