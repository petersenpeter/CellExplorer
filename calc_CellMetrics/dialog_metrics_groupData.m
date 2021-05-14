function [cell_metrics,UI,ClickedCells] = dialog_metrics_groupData(cell_metrics,UI)
        if ~isfield(UI.groupData1,'groupToList')
            UI.groupData1.groupToList = 'tags';
            groupDataSelect = 2;
        else
            groupDataSelect = find(ismember(UI.groupData1.groupsList,UI.groupData1.groupToList));
        end
        ClickedCells = [];
        updateGroupList
        drawnow nocallbacks;
        UI.groupData1.dialog = dialog('Position', [300, 300, 840, 465],'Name','Cell metrics group tags','WindowStyle','modal', 'resize', 'on','visible','off'); movegui(UI.groupData1.dialog,'center'), set(UI.groupData1.dialog,'visible','on') % 'MenuBar', 'None','NumberTitle','off'
        UI.groupData1.VBox = uix.VBox( 'Parent', UI.groupData1.dialog, 'Spacing', 5, 'Padding', 0 );
        UI.groupData1.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.groupData1.VBox);
        UI.groupData1.sessionList = uitable(UI.groupData1.VBox,'Data',UI.groupData.dataTable,'Position',[10, 50, 740, 457],'ColumnWidth',{65,45,45,100,460 75,45},'columnname',{'Highlight','+filter','-filter','Group name','List of cells','Cell count','Select'},'RowName',[],'ColumnEditable',[true true true true true false true],'Units','normalized','CellEditCallback',@editTable);
        UI.groupData1.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.groupData1.VBox);
        set(UI.groupData1.VBox, 'Heights', [50 -1 35]);
        uicontrol('Parent',UI.groupData1.panel.top,'Style','text','Position',[13, 25, 170, 20],'Units','normalized','String','Group tags','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.top,'Style','text','Position',[203, 25, 120, 20],'Units','normalized','String','Sort by','HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.top,'Style','text','Position',[333, 25, 170, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');

        UI.groupData1.popupmenu.groupData = uicontrol('Parent',UI.groupData1.panel.top,'Style','popupmenu','Position',[10, 5, 180, 22],'Units','normalized','String',UI.groupData1.groupsList,'HorizontalAlignment','left','Callback',@(src,evnt)ChangeGroupToList,'Units','normalized','Value',groupDataSelect);
        UI.groupData1.popupmenu.sorting = uicontrol('Parent',UI.groupData1.panel.top,'Style','popupmenu','Position',[200, 5, 120, 22],'Units','normalized','String',{'Group name','Count'},'HorizontalAlignment','left','Callback',@(src,evnt)filterGroupData,'Units','normalized');
        UI.groupData1.popupmenu.filter = uicontrol('Parent',UI.groupData1.panel.top,'Style', 'Edit', 'String', '', 'Position', [330, 5, 170, 25],'Callback',@(src,evnt)filterGroupData,'HorizontalAlignment','left','Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[10, 5, 120, 30],'String','Highlight all','Callback',@(src,evnt)button_groupData_selectAll,'Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[140, 5, 120, 30],'String','Clear all','Callback',@(src,evnt)button_groupData_deselectAll,'Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.top,'Style','pushbutton','Position',[620, 5, 100, 30],'String','+ New','Callback',@(src,evnt)newGroup,'Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.top,'Style','pushbutton','Position',[730, 5, 100, 30],'String','Delete','Callback',@(src,evnt)deleteGroup,'Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[620, 5, 100, 30],'String','Actions','Callback',@(src,evnt)CreateGroupAction,'Units','normalized');
        uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[730, 5, 100, 30],'String','OK','Callback',@(src,evnt)CloseDialog,'Units','normalized');
        UI.groupData1.popupmenu.performGroundTruthClassification = uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[270, 5, 110, 30],'String','Show G/T tab','Callback',@(src,evnt)performGroundTruthClassification,'Units','normalized','visible','Off');
%         UI.groupData1.popupmenu.importGroundTruth = uicontrol('Parent',UI.groupData1.panel.bottom,'Style','pushbutton','Position',[390, 5, 110, 30],'String','Export GT','Callback',@(src,evnt)importGroundTruth,'Units','normalized','visible','Off');

        toggleGroundTruthButtons
        updateGroupDataCount
        filterGroupData
        uicontrol(UI.groupData1.popupmenu.filter)
        uiwait(UI.groupData1.dialog)
        
        function CreateGroupAction
            oldField = find([UI.groupData1.sessionList.Data{:,end}]);
            if ~isempty(oldField)
                field = UI.groupData1.sessionList.Data(oldField,4);
                affectedCells = [];
                for i = 1:numel(oldField)
                    affectedCells = [affectedCells,cell_metrics.(UI.groupData1.groupToList).(field{i})];
                end
                ClickedCells = affectedCells;
                delete(UI.groupData1.dialog);
                updateUI2
            end
        end
        
        function ChangeGroupToList
            UI.groupData1.groupToList = UI.groupData1.groupsList{UI.groupData1.popupmenu.groupData.Value};
            toggleGroundTruthButtons
            updateGroupList
            filterGroupData
        end
        function updateUI2
            for i = 1:numel(UI.preferences.tags)
                if isfield(UI,'togglebutton')
                    if  isfield(UI.groupData1,'tags') && isfield(UI.groupData1.tags,'minus_filter') && isfield(UI.groupData1.tags.minus_filter,UI.preferences.tags{i})
                        UI.togglebutton.dispTags(i).Value = UI.groupData1.tags.minus_filter.(UI.preferences.tags{i});
                        UI.togglebutton.dispTags(i).FontWeight = 'bold';
                        UI.togglebutton.dispTags(i).ForegroundColor = UI.colors.toggleButtons;
                    else
                        UI.togglebutton.dispTags(i).Value = 0;
                        UI.togglebutton.dispTags(i).FontWeight = 'normal';
                        UI.togglebutton.dispTags(i).ForegroundColor = [0 0 0];
                    end
                    if isfield(UI.groupData1,'tags') && isfield(UI.groupData1.tags,'plus_filter') && isfield(UI.groupData1.tags.plus_filter,UI.preferences.tags{i})
                        UI.togglebutton.dispTags2(i).Value = UI.groupData1.tags.plus_filter.(UI.preferences.tags{i});
                        UI.togglebutton.dispTags2(i).FontWeight = 'bold';
                        UI.togglebutton.dispTags2(i).ForegroundColor = UI.colors.toggleButtons;
                    else
                        UI.togglebutton.dispTags2(i).Value = 0;
                        UI.togglebutton.dispTags2(i).FontWeight = 'normal';
                        UI.togglebutton.dispTags2(i).ForegroundColor = [0 0 0];
                    end
                end
            end
        end
        function toggleGroundTruthButtons
            if strcmp(UI.groupData1.groupToList,'groundTruthClassification')
                UI.groupData1.popupmenu.performGroundTruthClassification.Visible = 'On';
                UI.groupData1.popupmenu.importGroundTruth.Visible = 'On';
            else
                UI.groupData1.popupmenu.performGroundTruthClassification.Visible = 'Off';
                UI.groupData1.popupmenu.importGroundTruth.Visible = 'Off';
            end
        end
        
        function newGroup
            opts.Interpreter = 'tex';
            NewTag = inputdlg({'Name of new group','Cells in group'},'Add group',[1 40],{'',''},opts);
            if ~isempty(NewTag) && ~isempty(NewTag{1}) && ~any(strcmp(NewTag{1},UI.groupData.(UI.groupData1.groupToList)))
                if isvarname(NewTag{1})
                    if ~isempty(NewTag{2})
                        try
                            temp = eval(['[',NewTag{2},']']);
                            if isnumeric(eval(['[',NewTag{2},']']))
                                cell_metrics.(UI.groupData1.groupToList).(NewTag{1}) = eval(['[',NewTag{2},']']);
                                idx_ids = cell_metrics.(UI.groupData1.groupToList).(NewTag{1}) < 1 | cell_metrics.(UI.groupData1.groupToList).(NewTag{1}) > cell_metrics.general.cellCount;
                                cell_metrics.(UI.groupData1.groupToList).(NewTag{1})(idx_ids) = [];
                                saveStateToHistory(cell_metrics.(UI.groupData1.groupToList).(NewTag{1}));
                            end
                        end
                    else
                        cell_metrics.(UI.groupData1.groupToList).(NewTag{1}) = [];
                    end
                    updateGroupList
                    filterGroupData
                    if strcmp(UI.groupData1.groupToList,'tags')
                        UI.preferences.tags = [UI.preferences.tags,NewTag{1}];
%                         initTags
%                         updateTags
                    end
                else
                    warndlg(['Tag not added. Must be a valid variable name : ' NewTag{1}]);
                end
            end
        end
        
        function deleteGroup
            oldField = find([UI.groupData1.sessionList.Data{:,end}]);
            if ~isempty(oldField)
                field = UI.groupData1.sessionList.Data(oldField,4);
                affectedCells = [];
                for i = 1:numel(oldField)
                    affectedCells = [affectedCells,cell_metrics.(UI.groupData1.groupToList).(field{i})];
                end
                if ~isempty(affectedCells)
                    saveStateToHistory(affectedCells)
                end
                cell_metrics.(UI.groupData1.groupToList) = rmfield(cell_metrics.(UI.groupData1.groupToList),field);
                updateGroupList
                filterGroupData
                if strcmp(UI.groupData1.groupToList,'tags')
                    UI.preferences.tags(ismember(UI.preferences.tags,field)) = [];
%                     initTags
%                     updateTags
                end
            end
        end
        
        function editTable(hObject,callbackdata)
            row = callbackdata.Indices(1);
            column = callbackdata.Indices(2);
            if any(column == [1,2,3,7])
                UI.groupData1.sessionList.Data{row,column} = callbackdata.EditData;
                if column == 1
                    UI.groupData1.(UI.groupData1.groupToList).highlight.(UI.groupData1.sessionList.Data{row,4}) = callbackdata.EditData;
                elseif column == 2
                    UI.groupData1.(UI.groupData1.groupToList).plus_filter.(UI.groupData1.sessionList.Data{row,4}) = callbackdata.EditData;
                elseif column == 3
                    UI.groupData1.(UI.groupData1.groupToList).minus_filter.(UI.groupData1.sessionList.Data{row,4}) = callbackdata.EditData;
                end
            elseif column == 4 && isvarname(UI.groupData1.sessionList.Data{row,column}) && ~ismember(UI.groupData1.sessionList.Data{row,column},UI.groupData.(UI.groupData1.groupToList))
                
                newField = callbackdata.EditData;
                oldField = callbackdata.PreviousData;
                cells_altered = cell_metrics.(UI.groupData1.groupToList).(oldField);
                if ~isempty(cells_altered)
                    saveStateToHistory(cells_altered)
                end
                [cell_metrics.(UI.groupData1.groupToList).(newField)] = cell_metrics.(UI.groupData1.groupToList).(oldField);
                cell_metrics.(UI.groupData1.groupToList) = rmfield(cell_metrics.(UI.groupData1.groupToList),oldField);
                updateGroupList;
                filterGroupData;
                
                if strcmp(UI.groupData1.groupToList,'tags')
                    UI.preferences.tags(ismember(UI.preferences.tags,oldField)) = [];
                    UI.preferences.tags = [UI.preferences.tags,newField];
%                     initTags
%                     updateTags
                end
            elseif column == 5

                numericValue = UI.groupData1.sessionList.Data{row,column};
                preValue = cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4});
                try
                    temp = eval(['[',numericValue,']']);
                    if ~isempty(numericValue) && isnumeric(eval(['[',numericValue,']']))
                        cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4}) = eval(['[',numericValue,']']);
                        idx_ids = cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4}) < 1 | cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4}) > cell_metrics.general.cellCount;
                        cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4})(idx_ids) = [];
                    end
                end
                cells_altered = unique([preValue,cell_metrics.(UI.groupData1.groupToList).(UI.groupData1.sessionList.Data{row,4})]);
                if ~isempty(cells_altered)
                    saveStateToHistory(cells_altered)
                end
                updateGroupList
                filterGroupData
                if strcmp(UI.groupData1.groupToList,'tags')
                    updateTags
                end
            else
                updateGroupList
                filterGroupData
            end
        end
        
        function updateGroupList
            % Loading group data
            UI.groupData = [];
            if isfield(cell_metrics,UI.groupData1.groupToList)
                cell_metrics.(UI.groupData1.groupToList) = orderfields(cell_metrics.(UI.groupData1.groupToList));
                UI.groupData.(UI.groupData1.groupToList) = fieldnames(cell_metrics.(UI.groupData1.groupToList));
                % Generating table data
                UI.groupData.Counts = struct2cell(structfun(@(X) num2str(length(X)),cell_metrics.(UI.groupData1.groupToList),'UniformOutput',false));
                UI.groupData.sessionEnumerator = cellstr(num2str([1:length(UI.groupData.(UI.groupData1.groupToList))]'));
                UI.groupData.cellList = cellfun(@num2str,struct2cell(cell_metrics.(UI.groupData1.groupToList)),'UniformOutput',false);
                UI.groupData.dataTable = {};
                UI.groupData.dataTable(:,[4,5,6]) = [UI.groupData.(UI.groupData1.groupToList),UI.groupData.cellList,UI.groupData.Counts];
                UI.groupData.dataTable(:,1) = {false};
                UI.groupData.dataTable(:,2) = {false};
                UI.groupData.dataTable(:,3) = {false};
                UI.groupData.dataTable(:,7) = {false};
                UI.groupData.sessionList = strcat(UI.groupData.(UI.groupData1.groupToList),{' '},UI.groupData.cellList);
                if isfield(UI.groupData1,UI.groupData1.groupToList)  && isfield(UI.groupData1.(UI.groupData1.groupToList),'highlight')
                    fields1 = fieldnames(UI.groupData1.(UI.groupData1.groupToList).highlight);
                    for i = 1:numel(fields1)
                        if UI.groupData1.(UI.groupData1.groupToList).highlight.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),1) = {true};
                        end
                    end
                end
                if isfield(UI.groupData1,UI.groupData1.groupToList)  && isfield(UI.groupData1.(UI.groupData1.groupToList),'plus_filter')
                    fields1 = fieldnames(UI.groupData1.(UI.groupData1.groupToList).plus_filter);
                    for i = 1:numel(fields1)
                        if UI.groupData1.(UI.groupData1.groupToList).plus_filter.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),2) = {true};
                        end
                    end
                end
                if isfield(UI.groupData1,UI.groupData1.groupToList)  && isfield(UI.groupData1.(UI.groupData1.groupToList),'minus_filter')
                    fields1 = fieldnames(UI.groupData1.(UI.groupData1.groupToList).minus_filter);
                    for i = 1:numel(fields1)
                        if UI.groupData1.(UI.groupData1.groupToList).minus_filter.(fields1{i}) == 1
                            UI.groupData.dataTable(ismember(UI.groupData.dataTable(:,4),fields1{i}),3) = {true};
                        end
                    end
                end
            else
                UI.groupData.sessionList = {};
                UI.groupData.dataTable = {false,'',false,false,false,'',''};
                UI.groupData.(UI.groupData1.groupToList) = '';
            end
            
        end
        
        function updateGroupDataCount
            groupDataCount = [numel(fieldnames(cell_metrics.(UI.groupData1.groupsList{1}))),numel(fieldnames(cell_metrics.(UI.groupData1.groupsList{2}))),numel(fieldnames(cell_metrics.(UI.groupData1.groupsList{3})))];
            UI.groupData1.popupmenu.groupData.String = strcat(UI.groupData1.groupsList,' (',cellstr(num2str(groupDataCount'))',')');
        end
        function filterGroupData
            if ~isempty(UI.groupData1.popupmenu.filter.String) && ~strcmp(UI.groupData1.popupmenu.filter.String,'Filter')
                newStr2 = split(UI.groupData1.popupmenu.filter.String,{' & ',' AND '});
                idx_textFilter2 = zeros(length(newStr2),size(UI.groupData.dataTable,1));
                for i = 1:length(newStr2)
                    newStr3 = split(newStr2{i},{' | ',' OR ',});
                    idx_textFilter2(i,:) = contains(UI.groupData.sessionList,newStr3,'IgnoreCase',true);
                end
                idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
            else
                idx1 = 1:size(UI.groupData.dataTable,1);
            end
            if UI.groupData1.popupmenu.sorting.Value == 2
                [~,idx2] = sort(str2double([UI.groupData.dataTable(:,end-1)]),'descend');
            else
                [~,idx2] = sort(UI.groupData.dataTable(:,4));
            end
            idx2 = intersect(idx2,idx1,'stable');
            UI.groupData1.sessionList.Data = UI.groupData.dataTable(idx2,:);
%             UpdateSummaryText;
            updateGroupDataCount
        end
        
        function button_groupData_selectAll
            UI.groupData1.sessionList.Data(:,1) = {true};
            for i = 1:size(UI.groupData1.sessionList.Data,1)
                UI.groupData1.(UI.groupData1.groupToList).highlight.(UI.groupData1.sessionList.Data{i,4}) = 1;
            end
        end
        
        function button_groupData_deselectAll
            UI.groupData1.sessionList.Data(:,1) = {false};
            UI.groupData1.sessionList.Data(:,2) = {false};
            UI.groupData1.sessionList.Data(:,3) = {false};
            for i = 1:size(UI.groupData1.sessionList.Data,1)
                UI.groupData1.(UI.groupData1.groupToList).highlight.(UI.groupData1.sessionList.Data{i,4}) = 0;
                UI.groupData1.(UI.groupData1.groupToList).minus_filter.(UI.groupData1.sessionList.Data{i,4}) = 0;
                UI.groupData1.(UI.groupData1.groupToList).plus_filter.(UI.groupData1.sessionList.Data{i,4}) = 0;
            end
        end
        
        function CloseDialog
            % Closes the dialog
            delete(UI.groupData1.dialog);
            updateUI2
            uiresume(UI.fig);
        end
    end