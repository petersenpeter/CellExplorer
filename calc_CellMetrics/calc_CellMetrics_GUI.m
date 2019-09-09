function [session,parameters,statusExit] = calc_CellMetrics_GUI(sessionIn,parameters)
% Shows a GUI allowing you to edit parameters and meta data for the input session
%
% INPUTS
% sessionIn
% parameters
%
% OUTPUTS
% session 
% parameters
% statusExit

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 17-06-2019

% TODO
% Toggle button for saving sessionInfo on exit


session = sessionIn;
statusExit = 0;

% Creating figure
UI.fig = dialog('position',[50,50,520,560],'Name','Cell metrics','WindowStyle','modal'); movegui(UI.fig,'center')

% Tabs
UI.uitabgroup = uitabgroup('Units','pixels','Position',[0 40 520 510],'Parent',UI.fig);
if exist('parameters','var')
    UI.tabs.cellMetrics = uitab(UI.uitabgroup,'Title','Parameters');
else
    UI.tabs.cellMetrics = uitab(UI.uitabgroup,'Title','General');
end
UI.tabs.general = uitab(UI.uitabgroup,'Title','Animal');
% UI.tabs.epochs = uitab(UI.uitabgroup,'Title','Epochs');
UI.tabs.extracellular = uitab(UI.uitabgroup,'Title','Extracellular');
UI.tabs.brainRegions = uitab(UI.uitabgroup,'Title','Brain regions');
UI.tabs.channelTags = uitab(UI.uitabgroup,'Title','Tags');

% Buttons
UI.button.ok = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[10, 10, 240, 30],'String','OK','Callback',@(src,evnt)CloseMetricsWindow);
UI.button.cancel = uicontrol('Parent',UI.fig,'Style','pushbutton','Position',[260, 10, 250, 30],'String','Cancel','Callback',@(src,evnt)cancelMetricsWindow);

% Tab: cell metrics
% % % % % % % % % % % % % % % % % % % %

    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Session name (basename)', 'Position', [10, 440, 480, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.session = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', session.general.name, 'Position', [10, 415, 480, 25],'HorizontalAlignment','left');
    
if exist('parameters','var')
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'base path', 'Position', [10, 390, 300, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.basepath = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', parameters.basepath, 'Position', [10, 365, 480, 25],'HorizontalAlignment','left');
    
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'clustering path', 'Position', [10, 340, 480, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.clusteringpath = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', parameters.clusteringpath, 'Position', [10, 315, 480, 25],'HorizontalAlignment','left');
    
    % Include metrics
    UI.list.metrics = {'waveform_metrics','PCA_features','acg_metrics','deepSuperficial','ripple_metrics','monoSynaptic_connections','spatial_metrics','perturbation_metrics','theta_metrics','psth_metrics'};
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Include metrics (default: all)', 'Position', [10, 290, 235, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.listbox.includeMetrics = uicontrol('Parent',UI.tabs.cellMetrics,'Style','listbox','Position',[10 140 235 170],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.metrics));
    
    % Exclude metrics
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Exclude metrics (default: none)', 'Position', [250, 290, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.listbox.excludeMetrics = uicontrol('Parent',UI.tabs.cellMetrics,'Style','listbox','Position',[250 140 240 170],'Units','normalized','String',UI.list.metrics,'max',100,'min',0,'Value',compareStringArray(UI.list.metrics,parameters.excludeMetrics));
    
    % Parameters
    UI.list.params = {'forceReload','submitToDatabase','saveMat','plots','keepCellClassification','useNeurosuiteWaveforms','excludeManipulations'};
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Parameters', 'Position', [10, 100, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    for iParams = 1:length(UI.list.params)
        UI.checkbox.params(iParams) = uicontrol('Parent',UI.tabs.cellMetrics,'Style','checkbox','Position',[10 110-iParams*15 300 15],'Units','normalized','String',UI.list.params{iParams});
        UI.checkbox.params(iParams).Value = parameters.(UI.list.params{iParams});
    end
    
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Probe layout', 'Position', [250, 100, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.probesLayout = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'popup', 'String', {'unknown','linear', 'staggered', 'poly2', 'poly3','poly5'} , 'Position', [250, 75, 240, 25],'HorizontalAlignment','left');
    if iscell(session.extracellular.probesLayout) && size(session.extracellular.probesLayout,2)>1
        probesLayout = session.extracellular.probesLayout{1};
    else
        probesLayout = session.extracellular.probesLayout;
    end
    UIsetValue(UI.edit.probesLayout,probesLayout)
    
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'Probe vertical spacing (µm)', 'Position', [250, 50, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.probesVerticalSpacing = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', session.extracellular.probesVerticalSpacing, 'Position', [250, 25, 240, 25],'HorizontalAlignment','left');
else
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'base path', 'Position', [10, 390, 300, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.basepath = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', session.general.basePath, 'Position', [10, 365, 480, 25],'HorizontalAlignment','left');
    
    uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'text', 'String', 'clustering path', 'Position', [10, 340, 480, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
    UI.edit.clusteringpath = uicontrol('Parent',UI.tabs.cellMetrics,'Style', 'Edit', 'String', session.general.clusteringPath, 'Position', [10, 315, 480, 25],'HorizontalAlignment','left');
end

% Tab: session - general
% % % % % % % % % % % % % % % % % % % % %
uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Name', 'Position', [10, 440, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.session = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.animal, 'Position', [10, 415, 230, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Sex', 'Position', [250, 440, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.sex = uicontrol('Parent',UI.tabs.general,'Style', 'popup', 'String', {'Unknown','Male','Female'}, 'Position', [250, 415, 240, 25],'HorizontalAlignment','left');
UIsetValue(UI.edit.sex,session.general.sex)

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Species', 'Position', [10, 390, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.species = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.species, 'Position', [10, 365, 230, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Strain', 'Position', [250, 390, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.strain = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.strain, 'Position', [250, 365, 240, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.general,'Style', 'text', 'String', 'Genetic line', 'Position', [10, 340, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.geneticLine = uicontrol('Parent',UI.tabs.general,'Style', 'Edit', 'String', session.general.geneticLine, 'Position', [10, 315, 230, 25],'HorizontalAlignment','left');

% Tab: session - extracellular
% % % % % % % % % % % % % % % % % % % % %
uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'nChannels', 'Position', [10, 440, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.nChannels = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', session.extracellular.nChannels, 'Position', [10, 415, 230, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Least significant bit (µV; Intan: 0.195)', 'Position', [250, 440, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.leastSignificantBit = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', session.extracellular.leastSignificantBit, 'Position', [250, 415, 240, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Sampling rate (Hz)', 'Position', [10, 390, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.sr = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', session.extracellular.sr, 'Position', [10, 365, 230, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'LFP sampling rate (Hz)', 'Position', [250, 390, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.srLfp = uicontrol('Parent',UI.tabs.extracellular,'Style', 'Edit', 'String', session.extracellular.srLfp, 'Position', [250, 365, 240, 25],'HorizontalAlignment','left');

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Spike sorting method', 'Position', [10, 340, 230, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.spikeSortingMethod = uicontrol('Parent',UI.tabs.extracellular,'Style', 'popup', 'String', {'KiloSort', 'Klustakwik','MaskedKlustakwik', 'SpikingCircus'} , 'Position', [10, 315, 230, 25],'HorizontalAlignment','left');
UIsetValue(UI.edit.spikeSortingMethod,session.spikeSorting.method{1})

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Spike sorting format', 'Position', [250, 340, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.edit.spikeSortingFormat = uicontrol('Parent',UI.tabs.extracellular,'Style', 'popup', 'String', {'Phy','Klustakwik','KiloSort','KlustaViewer', 'SpikingCircus', 'Neurosuite'} , 'Position', [250, 315, 240, 25],'HorizontalAlignment','left');
UIsetValue(UI.edit.spikeSortingFormat,session.spikeSorting.format{1})

uicontrol('Parent',UI.tabs.extracellular,'Style', 'text', 'String', 'Spike groups', 'Position', [10, 290, 240, 20],'HorizontalAlignment','left', 'fontweight', 'bold');
UI.list.tableData = {false,'','',''};
UI.table.spikeGroups = uitable(UI.tabs.extracellular,'Data',UI.list.tableData,'Position',[10, 50, 480, 240],'ColumnWidth',{20 50 270 120},'columnname',{'','Group','Channels','Labels'},'RowName',[],'ColumnEditable',[true false false false]);
uicontrol('Parent',UI.tabs.extracellular,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add group','Callback',@(src,evnt)addSpikeGroup);
uicontrol('Parent',UI.tabs.extracellular,'Style','pushbutton','Position',[100, 10, 90, 30],'String','Edit group','Callback',@(src,evnt)editSpikeGroup);
uicontrol('Parent',UI.tabs.extracellular,'Style','pushbutton','Position',[190, 10, 90, 30],'String','Delete group(s)','Callback',@(src,evnt)deleteSpikeGroup);
uicontrol('Parent',UI.tabs.extracellular,'Style','pushbutton','Position',[280, 10, 120, 30],'String','Verify spike group(s)','Callback',@(src,evnt)verifySpikeGroup);
% uicontrol('Parent',UI.tabs.extracellular,'Style','pushbutton','Position',[400, 10, 90, 30],'String','Sync buzcode','Callback',@(src,evnt)syncSpikeGroups);
updateSpikeGroupsList

% Tab: session - brain regions
% % % % % % % % % % % % % % % % % % % % %
UI.list.tableData = {false,'','','',''};
UI.table.brainRegion = uitable(UI.tabs.brainRegions,'Data',UI.list.tableData,'Position',[10, 50, 480, 410],'ColumnWidth',{20 100 120 120 115},'columnname',{'','Brain region','Channels','Spike groups','Notes'},'RowName',[],'ColumnEditable',[true false false false false]);
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add region','Callback',@(src,evnt)addRegion);
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[100, 10, 90, 30],'String','Edit region','Callback',@(src,evnt)editRegion);
uicontrol('Parent',UI.tabs.brainRegions,'Style','pushbutton','Position',[190, 10, 90, 30],'String','Delete region(s)','Callback',@(src,evnt)deleteRegion);
updateBrainRegionList

% Tab: session - channel tags
% % % % % % % % % % % % % % % % % % % % %
tableData = {false,'','',''};
UI.table.tags = uitable(UI.tabs.channelTags,'Data',tableData,'Position',[10, 50, 480, 410],'ColumnWidth',{20 110 175 170},'columnname',{'','Tag','Channels','Spike groups'},'RowName',[],'ColumnEditable',[true false false false]);
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[10, 10, 90, 30],'String','Add tag','Callback',@(src,evnt)addTag);
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[100, 10, 90, 30],'String','Edit tag','Callback',@(src,evnt)editTag);
uicontrol('Parent',UI.tabs.channelTags,'Style','pushbutton','Position',[190, 10, 90, 30],'String','Delete tag(s)','Callback',@(src,evnt)deleteTag);
updateTagList

uiwait(UI.fig)

    function X = compareStringArray(A,B)
        if ischar(B)
            B = {B};
        end
        X = zeros(size(A));
        for k = 1:numel(B)
            X(strcmp(A,B{k})) = k;
        end
        X = find(X);
    end

    function CloseMetricsWindow
        % Saving parameters
        if exist('parameters','var')
            for iParams = 1:length(UI.list.params)
                UI.checkbox.params(iParams) = uicontrol('Parent',UI.tabs.cellMetrics,'Style','checkbox','Position',[10 110-iParams*15 300 15],'Units','normalized','String',UI.list.params{iParams});
                parameters.(UI.list.params{iParams}) = UI.checkbox.params(iParams).Value;
            end
            if ~isempty(UI.listbox.includeMetrics.Value)
                parameters.metrics = UI.listbox.includeMetrics.String(UI.listbox.includeMetrics.Value);
            end
            if ~isempty(UI.listbox.excludeMetrics.Value)
                parameters.excludeMetrics = UI.listbox.excludeMetrics.String(UI.listbox.excludeMetrics.Value);
            end
            session.extracellular.probesLayout = UI.edit.probesLayout.String{UI.edit.probesLayout.Value};
            session.extracellular.probesVerticalSpacing = str2double(UI.edit.probesVerticalSpacing.String);
        end
        session.general.sex = UI.edit.sex.String{UI.edit.sex.Value};
        session.general.species = UI.edit.species.String;
        session.general.strain = UI.edit.strain.String;
        session.general.geneticLine = UI.edit.geneticLine.String;
        
        session.extracellular.leastSignificantBit = str2double(UI.edit.leastSignificantBit.String);
        
        session.extracellular.sr = str2double(UI.edit.sr.String);
        session.extracellular.srLfp = str2double(UI.edit.srLfp.String);
        session.extracellular.nChannels = str2double(UI.edit.nChannels.String);
        
        session.spikeSorting.method{1} = UI.edit.spikeSortingMethod.String{UI.edit.spikeSortingMethod.Value};
        session.spikeSorting.format{1} = UI.edit.spikeSortingFormat.String{UI.edit.spikeSortingFormat.Value};
        
        delete(UI.fig)
        statusExit = 1;
    end

    function cancelMetricsWindow
        delete(UI.fig)
    end

    function updateBrainRegionList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        brainRegionFieldnames = fieldnames(session.brainRegions);
        for fn = 1:length(brainRegionFieldnames)
            tableData{fn,1} = false;
            tableData{fn,2} = brainRegionFieldnames{fn};
            if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'channels')
                tableData{fn,3} = num2str(session.brainRegions.(brainRegionFieldnames{fn}).channels);
            else
                tableData{fn,3} = '';
            end
            if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'spikeGroups')
                tableData{fn,4} = num2str(session.brainRegions.(brainRegionFieldnames{fn}).spikeGroups);
            else
                tableData{fn,4} = '';
            end
            if isfield(session.brainRegions.(brainRegionFieldnames{fn}),'notes')
                tableData{fn,5} = session.brainRegions.(brainRegionFieldnames{fn}).notes;
            else
                tableData{fn,5} = '';
            end
        end
        UI.table.brainRegion.Data = tableData;
    end

    function updateTagList
        % Updates the plot table from the spikesPlots structure
        tableData = {};
        if isfield(session,'channelTags') & ~isempty(session.channelTags)
        tagFieldnames = fieldnames(session.channelTags);
        for fn = 1:length(tagFieldnames)
            tableData{fn,1} = false;
            tableData{fn,2} = tagFieldnames{fn};
            if isfield(session.channelTags.(tagFieldnames{fn}),'channels')
                tableData{fn,3} = num2str(session.channelTags.(tagFieldnames{fn}).channels);
            else
                tableData{fn,3} = '';
            end
            if isfield(session.channelTags.(tagFieldnames{fn}),'spikeGroups')
                tableData{fn,4} = num2str(session.channelTags.(tagFieldnames{fn}).spikeGroups);
            else
                tableData{fn,4} = '';
            end
        end
        UI.table.tags.Data = tableData;
        else
            UI.table.tags.Data = {};
        end
    end
    function updateSpikeGroupsList
        % Updates the list of spike groups
        tableData = {};
        if isfield(session.extracellular,'spikeGroups')
            for fn = 1:size(session.extracellular.spikeGroups.channels,2)
                tableData{fn,1} = false;
                tableData{fn,2} = num2str(fn);
                tableData{fn,3} = num2str(session.extracellular.spikeGroups.channels{fn});
                if isfield(session.extracellular.spikeGroups,'label') & size(session.extracellular.spikeGroups.label,2)>=fn
                    tableData{fn,4} = session.extracellular.spikeGroups.label{fn};
                else
                    tableData{fn,4} = '';
                end
            end
            UI.table.spikeGroups.Data = tableData;
        else
            UI.table.spikeGroups.Data = {false,'','',''};
        end
    end

%% % Brain regions
    function deleteRegion
        % Deletes any selected spike plots
        if ~isempty(UI.table.brainRegion.Data) && ~isempty(find([UI.table.brainRegion.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.brainRegions);
            session.brainRegions = rmfield(session.brainRegions,{spikesPlotFieldnames{find([UI.table.brainRegion.Data{:,1}])}});
            updateBrainRegionList
        else
            warndlg(['Please select a region to delete'])
        end
    end

    function addRegion(regionIn)
        % Add new brain region to session struct
        brainRegions = load('BrainRegions.mat'); brainRegions = brainRegions.BrainRegions;
        brainRegions_list = strcat(brainRegions(:,1),' (',brainRegions(:,2),')');
        brainRegions_acronym = brainRegions(:,2);
        if exist('regionIn')
            InitBrainRegion = find(strcmp(regionIn,brainRegions_acronym));
            if isfield(session.brainRegions.(regionIn),'channels')
                initChannels = num2str(session.brainRegions.(regionIn).channels);
            else
                initChannels = '';
            end
            if isfield(session.brainRegions.(regionIn),'spikeGroups')
                initSpikeGroups = num2str(session.brainRegions.(regionIn).spikeGroups);
            else
                initSpikeGroups = '';
            end
        else
            InitBrainRegion = 1;
            initChannels = '';
            initSpikeGroups = '';
        end
        % Opens dialog
        UI.dialog.brainRegion = dialog('Position', [300, 300, 600, 400],'Name','Add brain region','WindowStyle','modal'); movegui(UI.dialog.brainRegion,'center')
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Search term', 'Position', [10, 375, 580, 20],'HorizontalAlignment','left');
        brainRegionsTextfield = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', '', 'Position', [10, 350, 580, 25],'Callback',@(src,evnt)filterBrainRegionsList,'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Selct brain region below', 'Position', [10, 320, 580, 20],'HorizontalAlignment','left');
        brainRegionsList = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'ListBox', 'String', brainRegions_list, 'Position', [10, 100, 580, 220],'Value',InitBrainRegion);
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Channels', 'Position', [10, 75, 280, 20],'HorizontalAlignment','left');
        brainRegionsChannels = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', initChannels, 'Position', [10, 50, 280, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style', 'text', 'String', 'Spike groups', 'Position', [300, 75, 290, 20],'HorizontalAlignment','left');
        brainRegionsSpikeGroups = uicontrol('Parent',UI.dialog.brainRegion,'Style', 'Edit', 'String', initSpikeGroups, 'Position', [300, 50, 290, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.brainRegion,'Style','pushbutton','Position',[10, 10, 280, 30],'String','Save region','Callback',@(src,evnt)CloseBrainRegions_dialog);
        uicontrol('Parent',UI.dialog.brainRegion,'Style','pushbutton','Position',[300, 10, 290, 30],'String','Cancel','Callback',@(src,evnt)CancelBrainRegions_dialog);
        
        uicontrol(brainRegionsTextfield);
        uiwait(UI.dialog.brainRegion);
        
        function filterBrainRegionsList
            temp = contains(brainRegions_list,brainRegionsTextfield.String,'IgnoreCase',true);
            if ~any(temp == brainRegionsList.Value)
                brainRegionsList.Value = 1;
            end
            if ~isempty(temp)
                brainRegionsList.String = brainRegions_list(temp);
            else
                brainRegionsList.String = {''};
            end
        end
        function CloseBrainRegions_dialog
            if length(brainRegionsList.String)>=brainRegionsList.Value
                choice = brainRegionsList.String(brainRegionsList.Value);
                if ~strcmp(choice,'')
                    indx = find(strcmp(choice,brainRegions_list));
                    SelectedBrainRegion = brainRegions_acronym{indx};
                    if ~isempty(brainRegionsChannels.String)
                        try
                            session.brainRegions.(SelectedBrainRegion).channels = eval(['[',brainRegionsChannels.String,']']);
                        catch
                            warndlg(['Channels not not formatted correctly'])
                            uicontrol(brainRegionsChannels);
                        end
                    end
                    if ~isempty(brainRegionsSpikeGroups.String)
                        try
                            session.brainRegions.(SelectedBrainRegion).spikeGroups = eval(['[',brainRegionsSpikeGroups.String,']']);
                        catch
                            warndlg(['Spike groups not formatted correctly'])
                            uicontrol(brainRegionsSpikeGroups);
                        end
                    end
                end
            end
            delete(UI.dialog.brainRegion);
            updateBrainRegionList;
        end
        function CancelBrainRegions_dialog
            session = sessionIn;
            delete(UI.dialog.brainRegion);
        end
    end

    function editRegion
        % Selected region is parsed to the spikePlotsDlg, for edits,
        % saved the output to the spikesPlots structure and updates the
        % table
        if ~isempty(UI.table.brainRegion.Data) && ~isempty(find([UI.table.brainRegion.Data{:,1}])) && sum([UI.table.brainRegion.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.brainRegions);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.brainRegion.Data{:,1}])};
            addRegion(fieldtoedit)
        else
            warndlg(['Please select a region to edit'])
        end
    end

%% % Channel tags

    function deleteTag
        % Deletes any selected tags
        if ~isempty(UI.table.tags.Data) && ~isempty(find([UI.table.tags.Data{:,1}], 1))
            spikesPlotFieldnames = fieldnames(session.channelTags);
            session.channelTags = rmfield(session.channelTags,{spikesPlotFieldnames{find([UI.table.tags.Data{:,1}])}});
            updateTagList
        else
            warndlg(['Please select a tag to delete'])
        end
    end

    function addTag(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            InitTag = regionIn;
            if isfield(session.channelTags.(regionIn),'channels')
                initChannels = num2str(session.channelTags.(regionIn).channels);
            else
                initChannels = '';
            end
            if isfield(session.channelTags.(regionIn),'spikeGroups')
                initSpikeGroups = num2str(session.channelTags.(regionIn).spikeGroups);
            else
                initSpikeGroups = '';
            end
        else
            InitTag = '';
            initChannels = '';
            initSpikeGroups = '';
        end
        
        % Opens dialog
        UI.dialog.tags = dialog('Position', [300, 300, 500, 160],'Name','Add tag','WindowStyle','modal'); movegui(UI.dialog.tags,'center')
        
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', 'Tag name (e.g. Theta, Gamma, Bad, Cortical, Ripple, RippleNoise)', 'Position', [10, 130, 480, 20],'HorizontalAlignment','left');
        tagsTextfield = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', InitTag, 'Position', [10, 105, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', 'Channels', 'Position', [10, 75, 230, 20],'HorizontalAlignment','left');
        tagsChannels = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', initChannels, 'Position', [10, 50, 230, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.tags,'Style', 'text', 'String', 'Spike groups', 'Position', [250, 75, 240, 20],'HorizontalAlignment','left');
        tagsSpikeGroups = uicontrol('Parent',UI.dialog.tags,'Style', 'Edit', 'String', initSpikeGroups, 'Position', [250, 50, 240, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.tags,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save tag','Callback',@(src,evnt)CloseTags_dialog);
        uicontrol('Parent',UI.dialog.tags,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelTags_dialog);
        
        uicontrol(tagsTextfield);
        uiwait(UI.dialog.tags);
        
        function CloseTags_dialog
            if ~strcmp(tagsTextfield.String,'') && isvarname(tagsTextfield.String)
                SelectedTag = tagsTextfield.String;
                if ~isempty(tagsChannels.String)
                    try
                        session.channelTags.(SelectedTag).channels = eval(['[',tagsChannels.String,']']);
                    catch
                        warndlg(['Channels not not formatted correctly'])
                        uicontrol(tagsChannels);
                        return
                    end
                end
                if ~isempty(tagsSpikeGroups.String)
                    try
                        session.channelTags.(SelectedTag).spikeGroups = eval(['[',tagsSpikeGroups.String,']']);
                    catch
                        warndlg(['Spike groups not formatted correctly'])
                        uicontrol(tagsSpikeGroups);
                        return
                    end
                end
                
            end
            delete(UI.dialog.tags);
            updateTagList;
        end
        function CancelTags_dialog
            delete(UI.dialog.tags);
        end
    end

    function editTag
        % Selected tag is parsed to the addTag dialog for edits,
        if ~isempty(UI.table.tags.Data) && ~isempty(find([UI.table.tags.Data{:,1}], 1)) && sum([UI.table.tags.Data{:,1}]) == 1
            spikesPlotFieldnames = fieldnames(session.channelTags);
            fieldtoedit = spikesPlotFieldnames{find([UI.table.tags.Data{:,1}])};
            addTag(fieldtoedit)
        else
            warndlg(['Please select a tag to edit'])
        end
    end

    function UIsetValue(fieldNameIn,valueIn)
        if any(strcmp(valueIn,fieldNameIn.String))
            fieldNameIn.Value = find(strcmp(valueIn,fieldNameIn.String));
        else
            fieldNameIn.Value = 1;
        end
    end

%% % extracellular spike groups

    function deleteSpikeGroup
        % Deletes any selected tags
        if ~isempty(UI.table.spikeGroups.Data) && ~isempty(find([UI.table.spikeGroups.Data{:,1}], 1))
            session.extracellular.spikeGroups.channels([UI.table.spikeGroups.Data{:,1}]) = [];
            session.extracellular.nSpikeGroups = size(session.extracellular.spikeGroups.channels,2);
            updateSpikeGroupsList
        else
            warndlg(['Please select a spike group to delete'])
        end
    end

    function addSpikeGroup(regionIn)
        % Add new tag to session struct
        if exist('regionIn','var')
            initSpikeGroups = num2str(regionIn);
            initChannels = num2str(session.extracellular.spikeGroups.channels{regionIn});
            if isfield(session.extracellular.spikeGroups,'label') & size(session.extracellular.spikeGroups.label,2)>=regionIn & ~isempty(session.extracellular.spikeGroups.label{regionIn})
                initLabel = session.extracellular.spikeGroups.label{regionIn};
            else
                initLabel = '';
            end
        else
            initSpikeGroups = num2str(size(session.extracellular.spikeGroups.channels,2)+1);
            initChannels = '';
            initLabel = '';
        end
        
        % Opens dialog
        UI.dialog.spikeGroups = dialog('Position', [300, 300, 500, 210],'Name','Add spike group','WindowStyle','modal'); movegui(UI.dialog.spikeGroups,'center')

        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', 'Spike group', 'Position', [10, 175, 480, 20],'HorizontalAlignment','left');
        spikeGroupsSpikeGroups = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initSpikeGroups, 'Position', [10, 150, 480, 25],'HorizontalAlignment','left','enable', 'off');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', 'Channels', 'Position', [10, 125, 480, 20],'HorizontalAlignment','left');
        spikeGroupsChannels = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initChannels, 'Position', [10, 100, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'text', 'String', 'Label', 'Position', [10, 75, 480, 20],'HorizontalAlignment','left');
        spikeGroupsLabel = uicontrol('Parent',UI.dialog.spikeGroups,'Style', 'Edit', 'String', initLabel, 'Position', [10, 50, 480, 25],'HorizontalAlignment','left');
        
        uicontrol('Parent',UI.dialog.spikeGroups,'Style','pushbutton','Position',[10, 10, 230, 30],'String','Save spike group','Callback',@(src,evnt)CloseSpikeGroups_dialog);
        uicontrol('Parent',UI.dialog.spikeGroups,'Style','pushbutton','Position',[250, 10, 240, 30],'String','Cancel','Callback',@(src,evnt)CancelSpikeGroups_dialog);
        
        uicontrol(spikeGroupsChannels);
        uiwait(UI.dialog.spikeGroups);
        
        function CloseSpikeGroups_dialog
            spikeGroup = str2double(spikeGroupsSpikeGroups.String);
            if ~isempty(spikeGroupsChannels.String)
                try
                    session.extracellular.spikeGroups.channels{spikeGroup} = eval(['[',spikeGroupsChannels.String,']']);
                catch
                    warndlg(['Channels not not formatted correctly'])
                    uicontrol(spikeGroupsChannels);
                    return
                end
            end
            session.extracellular.spikeGroups.label{spikeGroup} = spikeGroupsLabel.String;
            delete(UI.dialog.spikeGroups);
            session.extracellular.nSpikeGroups = size(session.extracellular.spikeGroups,2);
            updateSpikeGroupsList;
        end
        function CancelSpikeGroups_dialog
            delete(UI.dialog.spikeGroups);
        end
    end

    function editSpikeGroup
        % Selected spike group is parsed to the addSpikeGroup dialog for edits
        if ~isempty(UI.table.spikeGroups.Data) && ~isempty(find([UI.table.spikeGroups.Data{:,1}], 1)) && sum([UI.table.spikeGroups.Data{:,1}]) == 1
            fieldtoedit = find([UI.table.spikeGroups.Data{:,1}]);
            addSpikeGroup(fieldtoedit)
        else
            warndlg(['Please select a spike group to edit'])
        end
    end

    function verifySpikeGroup
        channels = [session.extracellular.spikeGroups.channels{:}];
        uniqueChannels = length(unique(channels));
        nChannels = length(channels);
        if nChannels ~= session.extracellular.nChannels
            warndlg('Channel count in spike groups does not corresponds to nChannels')
        elseif uniqueChannels ~= session.extracellular.nChannels
            warndlg('The unique channel count does not corresponds to nChannels')
        elseif any(sort(channels) ~= [1:session.extracellular.nChannels]-1)
            warndlg('Channels are not ranging from 0 : nChannels-1')
        else
            msgbox('Channels verified succesfully!');
        end
    end
    
    function syncSpikeGroups
        msgbox('spike groups syncing with buzcode sessionInfo and .xml file');
    end

end