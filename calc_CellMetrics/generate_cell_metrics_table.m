function generate_cell_metrics_table(cell_metrics)
    % Generates a table with the full list of metrics. Function is part of CellExplorer (https://cellexplorer.org/)
    
    % Written by Peter Petersen
    
    UI.lists.metrics = fieldnames(cell_metrics);
    [indx,tf] = listdlg('ListString',UI.lists.metrics);
    UI.lists.metrics = UI.lists.metrics(indx);
    
    UI = metrics_labels(UI);
    
    columnname = {};
    tableData = {};
    k = 1;
    for i = 1:numel(UI.lists.metrics)
        if isnumeric(cell_metrics.(UI.lists.metrics{i})) && ~all(isnan(cell_metrics.(UI.lists.metrics{i})))
            tableData.(UI.lists.metrics{i}) = cell_metrics.(UI.lists.metrics{i})';
            columnname{k} = UI.labels.(UI.lists.metrics{i});
            k = k + 1;
        elseif  iscell(cell_metrics.(UI.lists.metrics{i}))
            tableData.(UI.lists.metrics{i}) = cell_metrics.(UI.lists.metrics{i})';
            columnname{k} = UI.labels.(UI.lists.metrics{i});
            k = k + 1;
        end
    end
    tableData = struct2table(tableData);
    fig = uifigure('Name','Cell metrics','pos',[0,0,min([1200,numel(UI.lists.metrics)*150]),800],'visible','off');
    uitable(fig,'Data', tableData,'Units','normalized','Position',[0 0 1 1],'columnname',columnname,'RowName',[],'ColumnEditable',false,'ColumnSortable',true);
    movegui(fig,'center'), set(fig,'visible','on')
