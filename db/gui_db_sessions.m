function [basenames,basepaths,exitMode] = gui_db_sessions(basenames_in,textfilter)
    % Shows a list of sessions from the Buzsaki lab databank
    % This function is part of CellExplorer
    %
    % Example call
    % [basenames,basepaths,exitMode] = gui_db_sessions
    
    % By Peter Petersen
    exitMode = 0;
    db = [];
    basenames = {};
    basepaths = {};
    if exist('db_load_settings','file')
        db_settings = db_load_settings;
    end
    % Load sessions from the database.
    % Dialog is shown with sessions from the database with calculated cell metrics.
    % Then selected sessions are loaded from the database
    drawnow nocallbacks;
    if isempty(db) && exist('db_cell_metrics_session_list.mat','file')
        load('db_cell_metrics_session_list.mat')
    elseif isempty(db)
        db = db_load_sessionlist;
    end
    
    loadDB.dialog = dialog('Position', [300, 300, 1000, 565],'Name','BuzLabDB: Spike sorted sessions','WindowStyle','modal', 'resize', 'on','visible','off'); 
    loadDB.VBox = uix.VBox( 'Parent', loadDB.dialog, 'Spacing', 5, 'Padding', 0 );
    loadDB.panel.top = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
    loadDB.sessionList = uitable(loadDB.VBox,'Data',db.dataTable,'Position',[10, 50, 880, 457],'ColumnWidth',{20 30 210 50 120 70 160 110 110 100},'columnname',{'','#','Session','Cells','Animal','Species','Behaviors','Investigator','Repository','Brain regions'},'RowName',[],'ColumnEditable',[true false false false false false false false false false],'Units','normalized'); % ,'CellSelectionCallback',@ClicktoSelectFromTable
    loadDB.panel.bottom = uipanel('position',[0 0 1 1],'BorderType','none','Parent',loadDB.VBox);
    set(loadDB.VBox, 'Heights', [50 -1 35]);
    uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[10, 25, 150, 20],'Units','normalized','String','Filter','HorizontalAlignment','left','Units','normalized');
    uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[580, 25, 150, 20],'Units','normalized','String','Sort by','HorizontalAlignment','center','Units','normalized');
    uicontrol('Parent',loadDB.panel.top,'Style','text','Position',[740, 25, 150, 20],'Units','normalized','String','Repositories','HorizontalAlignment','center','Units','normalized');
    loadDB.popupmenu.filter = uicontrol('Parent',loadDB.panel.top,'Style', 'Edit', 'String', '', 'Position', [10, 5, 560, 25],'Callback',@(src,evnt)Button_DB_filterList,'HorizontalAlignment','left','Units','normalized');
    loadDB.popupmenu.sorting = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[580, 5, 150, 22],'Units','normalized','String',{'Session','Cell count','Animal','Species','Behavioral paradigm','Investigator','Data repository'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
    loadDB.popupmenu.repositories = uicontrol('Parent',loadDB.panel.top,'Style','popupmenu','Position',[740, 5, 150, 22],'Units','normalized','String',{'All repositories','Your repositories'},'HorizontalAlignment','left','Callback',@(src,evnt)Button_DB_filterList,'Units','normalized');
    uicontrol('Parent',loadDB.panel.top,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Update list','Callback',@(src,evnt)ReloadSessionlist,'Units','normalized');
    uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[10, 5, 90, 30],'String','Select all','Callback',@(src,evnt)button_DB_selectAll,'Units','normalized');
    uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[110, 5, 90, 30],'String','Select none','Callback',@(src,evnt)button_DB_deselectAll,'Units','normalized');
    loadDB.summaryText = uicontrol('Parent',loadDB.panel.bottom,'Style','text','Position',[210, 5, 580, 25],'Units','normalized','String','','HorizontalAlignment','center','Units','normalized');
    uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[800, 5, 90, 30],'String','OK','Callback',@(src,evnt)exit_dialog,'Units','normalized');
    uicontrol('Parent',loadDB.panel.bottom,'Style','pushbutton','Position',[900, 5, 90, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog,'Units','normalized');

    UpdateSummaryText
    if exist('basenames_in','var') && ~isempty(basenames_in)
        loadDB.sessionList.Data(ismember(loadDB.sessionList.Data(:,3),basenames_in),1) = {true};
    end
    if exist('textfilter','var') && ~isempty(textfilter)
        loadDB.popupmenu.filter.String = textfilter;
        Button_DB_filterList
    end
        
    movegui(loadDB.dialog,'center')
%         set(loadDB.dialog,'visible','on')
    uicontrol(loadDB.popupmenu.filter)
    uiwait(loadDB.dialog)

    function ReloadSessionlist
        db = db_load_sessionlist;
        Button_DB_filterList
    end

    function UpdateSummaryText
        cellCount = nansum(cell2mat( cellfun(@(x) str2double(x),loadDB.sessionList.Data(:,4),'UniformOutput',false)));
        loadDB.summaryText.String = [num2str(size(loadDB.sessionList.Data,1)),' session(s) with ', num2str(cellCount),' cells from ',num2str(length(unique(loadDB.sessionList.Data(:,5)))),' animal(s). Updated at: ', datestr(db.refreshTime)];
    end

    function Button_DB_filterList
        if ~isempty(loadDB.popupmenu.filter.String) && ~strcmp(loadDB.popupmenu.filter.String,'Filter')
            newStr2 = split(loadDB.popupmenu.filter.String,{' & ',' AND '});
            idx_textFilter2 = zeros(length(newStr2),size(db.dataTable,1));
            for i = 1:length(newStr2)
                newStr3 = split(newStr2{i},{' | ',' OR ',});
                idx_textFilter2(i,:) = contains(db.sessionList,newStr3,'IgnoreCase',true);
            end
            idx1 = find(sum(idx_textFilter2,1)==length(newStr2));
        else
            idx1 = 1:size(db.dataTable,1);
        end

        if loadDB.popupmenu.sorting.Value == 2 % Cell count
            cellCount = [];
            for i = 1:numel(db.sessions)
                if ~isempty(db.sessions{i}.spikeSorting.cellCount)
                cellCount(i) = db.sessions{i}.spikeSorting.cellCount;
                else
                    cellCount(i) = 0;
                end
            end
%             cellCount = cell2mat( cellfun(@(x) x.spikeSorting.cellCount,db.sessions,'UniformOutput',false));
            [~,idx2] = sort(cellCount(db.index),'descend');
        elseif loadDB.popupmenu.sorting.Value == 3 % Animal
            [~,idx2] = sort(db.animals(db.index));
        elseif loadDB.popupmenu.sorting.Value == 4 % Species
            [~,idx2] = sort(db.species(db.index));
        elseif loadDB.popupmenu.sorting.Value == 5 % Behavioral paradigm
            [~,idx2] = sort(db.behavioralParadigm(db.index));
        elseif loadDB.popupmenu.sorting.Value == 6 % Investigator
            [~,idx2] = sort(db.investigator(db.index));
        elseif loadDB.popupmenu.sorting.Value == 7 % Data repository
            [~,idx2] = sort(db.repository(db.index));
        else
            idx2 = 1:size(db.dataTable,1);
        end

        if loadDB.popupmenu.repositories.Value == 2 && ~isempty(db_settings.repositories)
            idx3 = find(ismember(db.repository(db.index),fieldnames(db_settings.repositories)));
        else
            idx3 = 1:size(db.dataTable,1);
        end

        idx2 = intersect(idx2,idx1,'stable');
        idx2 = intersect(idx2,idx3,'stable');
        loadDB.sessionList.Data = db.dataTable(idx2,:);
        UpdateSummaryText
    end

    function button_DB_selectAll
        loadDB.sessionList.Data(:,1) = {true};
    end

    function button_DB_deselectAll
        loadDB.sessionList.Data(:,1) = {false};
    end

    function exit_dialog
        % Exit dialog with current selection
        indx = cell2mat(cellfun(@str2double,loadDB.sessionList.Data(find([loadDB.sessionList.Data{:,1}])',2),'un',0));
        delete(loadDB.dialog);
        if ~isempty(indx)
            exitMode = 1;
            % Setting paths from db struct
            db_basename = {};
            db_basepath = {};
            db_basename = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
            basenames = db_basename(indx);
            i_db_subset_all = db.index(indx);
            
            if isempty(db_settings.repositories)
                disp(['Local respositories have not been defined on this computer. Edit db_local_repositories']);
                return
            end
            for i_db = 1:length(i_db_subset_all)
                i_db_subset = i_db_subset_all(i_db);
                if ~any(strcmp(db.sessions{i_db_subset}.repositories{1},fieldnames(db_settings.repositories)))
                    disp(['The respository ', db.sessions{i_db_subset}.repositories{1} ,' has not been defined on this computer. Please edit db_local_repositories and provide the path'])
                    edit db_local_repositories.m
                    return
                end
                if strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_Datasets')
                    Investigator_name = strsplit(db.sessions{i_db_subset}.investigator,' ');
                    path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
                    db_basepath{i_db} = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), path_Investigator,db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                elseif strcmp(db.sessions{i_db_subset}.repositories{1},'NYUshare_AllenInstitute')
                    db_basepath{i_db} = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), db.sessions{i_db_subset}.name);
                else
                    db_basepath{i_db} = fullfile(db_settings.repositories.(db.sessions{i_db_subset}.repositories{1}), db.sessions{i_db_subset}.animal, db.sessions{i_db_subset}.name);
                end
            end
            basepaths = db_basepath;
        else
            disp('No datasets selected');
            exitMode = 0;
        end
    end

    function cancel_dialog
        % Cancel and close the dialog 
        basenames = {};
        basepaths = {};
        delete(loadDB.dialog);
        exitMode = 0;
    end
end