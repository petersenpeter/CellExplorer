function verifySessionStruct(session)
% This function is part of CellExplorer: https://CellExplorer.org
% Verifies that required and optional fields have been defined in the session struct

% By Peter Peterseb
% 26-05-2020

session_fields = {};

% General
session_fields.general.required = {'name';'basePath'};
session_fields.general.optional = {'investigator','sessionType'};

% Epochs
session_fields.epochs.required = {'name'};
session_fields.epochs.optional = {'behavioralParadigm','startTime','stopTime'};

% Animal
session_fields.animal.required = {'name'};
session_fields.animal.optional = {'sex','species','strain','geneticLine'};

% Extracellular
session_fields.extracellular.required = {'sr','nChannels','leastSignificantBit','electrodeGroups','nElectrodeGroups'};
session_fields.extracellular.optional = {'equipment','nSamples','fileName','spikeGroups','nSpikeGroups'};

% Spike sorting
session_fields.spikeSorting.required = {'format'};
session_fields.spikeSorting.optional = {'method','relativePath'};

% channel tags
session_fields.channelTags.optional = {'Theta','Cortical','Ripple'};

% Brain regions
session_fields.brainRegions.optional = {''};

%% Verifying fields
fields_1stLevel = fields(session_fields);
shortcutList = {};
for i = 1:numel(fields_1stLevel)
    shortcutList = [shortcutList;{['<html><b>',fields_1stLevel{i},'</b></html>'], ''}];
    if strcmp(fields_1stLevel{i},'channelTags')
        if isfield(session,'channelTags')
        fields_optional = session_fields.(fields_1stLevel{i}).optional;
        for j = 1:numel(fields_optional)
            if isfield(session.(fields_1stLevel{i}),fields_optional{j}) && ~isempty(session.(fields_1stLevel{i}).(fields_optional{j}))
                shortcutList = [shortcutList;{fields_optional{j},'OK '}];
            else
                shortcutList = [shortcutList;{fields_optional{j},'<html><b><font color="blue">optional</font></b></html>'}];
            end
        end
        end
    elseif strcmp(fields_1stLevel{i},'brainRegions')
        if isfield(session,'brainRegions')
        if ~isempty(session.brainRegions)
            fields_optional = fieldnames(session.brainRegions);
            for j = 1:numel(fields_optional)
                if isfield(session.brainRegions.(fields_optional{j}),'channels') || isfield(session.brainRegions.(fields_optional{j}),'electrodeGroups')
                    shortcutList = [shortcutList;{fields_optional{j},'OK'}];
                else
                    shortcutList = [shortcutList;{fields_optional{j},'<html><b><font color="red">channels or groups not defined</font></b></html>'}];
                end
            end
            shortcutList = [shortcutList;{fields_optional{j},'OK'}];
        else
            shortcutList = [shortcutList;{'no brain regions defined','<html><b><font color="blue">optional</font></b></html>'}];
        end
        end
    elseif strcmp(fields_1stLevel{i},{'spikeSorting'})
        
        fields_required = session_fields.(fields_1stLevel{i}).required;
        for j = 1:numel(fields_required)
            if ~isempty(session.spikeSorting) && isfield(session.(fields_1stLevel{i}){1},fields_required{j}) && ~isempty(session.(fields_1stLevel{i}){1}.(fields_required{j}))
                shortcutList = [shortcutList;{fields_required{j},'OK '}];
            else
                shortcutList = [shortcutList;{fields_required{j},'<html><b><font color="red">Not defined</font></b></html>'}];
            end
            
        end
        
        fields_optional = session_fields.(fields_1stLevel{i}).optional;
        for j = 1:numel(fields_optional)
            if ~isempty(session.spikeSorting) && isfield(session.(fields_1stLevel{i}){1},fields_optional{j}) && ~isempty(session.(fields_1stLevel{i}){1}.(fields_optional{j}))
                shortcutList = [shortcutList;{fields_optional{j},'OK '}];
            else
                shortcutList = [shortcutList;{fields_optional{j},'<html><b><font color="blue">optional</font></b></html>'}];
            end
        end
    elseif strcmp(fields_1stLevel{i},{'epochs'})
        if isfield(session,'epochs')
        for k = 1:numel(session.epochs)
            fields_required = session_fields.(fields_1stLevel{i}).required;
            for j = 1:numel(fields_required)
                if isfield(session.(fields_1stLevel{i}){1},fields_required{j}) && ~isempty(session.(fields_1stLevel{i}){k}.(fields_required{j}))
                    shortcutList = [shortcutList;{['Epochs(',num2str(k),'): ',fields_required{j}],'OK '}];
                else
                    shortcutList = [shortcutList;{fields_required{j},'<html><b><font color="red">Not defined</font></b></html>'}];
                end
            end
            
            fields_optional = session_fields.(fields_1stLevel{i}).optional;
            for j = 1:numel(fields_optional)
                if isfield(session.(fields_1stLevel{i}){1},fields_optional{j}) && ~isempty(session.(fields_1stLevel{i}){k}.(fields_optional{j}))
                    shortcutList = [shortcutList;{fields_optional{j},'OK '}];
                else
                    shortcutList = [shortcutList;{fields_optional{j},'<html><b><font color="blue">optional</font></b></html>'}];
                end
            end
        end
        end
    else
        if isfield(session_fields.(fields_1stLevel{i}),'required')
            fields_required = session_fields.(fields_1stLevel{i}).required;
            for j = 1:numel(fields_required)
                if isfield(session.(fields_1stLevel{i}),fields_required{j}) && ~isempty(session.(fields_1stLevel{i}).(fields_required{j})) 
                    if isnumeric(session.(fields_1stLevel{i}).(fields_required{j})) && session.(fields_1stLevel{i}).(fields_required{j}) == 0
                        shortcutList = [shortcutList;{fields_required{j},'<html><b><font color="red">Zero</font></b></html>'}];
                    else
                        shortcutList = [shortcutList;{fields_required{j},'OK '}];
                    end
                else
                    shortcutList = [shortcutList;{fields_required{j},'<html><b><font color="red">Not defined</font></b></html>'}];
                end
            end
        end
        if isfield(session_fields.(fields_1stLevel{i}),'optional')
            fields_optional = session_fields.(fields_1stLevel{i}).optional;
            for j = 1:numel(fields_optional)
                if isfield(session.(fields_1stLevel{i}),fields_optional{j}) && ~isempty(session.(fields_1stLevel{i}).(fields_optional{j}))
                    shortcutList = [shortcutList;{fields_optional{j},'OK '}];
                else
                    shortcutList = [shortcutList;{fields_optional{j},'<html><b><font color="blue">optional</font></b></html>'}];
                end
            end
        end
        if strcmp(fields_1stLevel{i},{'extracellular'})
            if isfield(session.extracellular,'electrodeGroups') && isfield(session.extracellular.electrodeGroups,'channels') && numel([session.extracellular.electrodeGroups.channels{:}]) == session.extracellular.nChannels
                shortcutList = [shortcutList;{['electrodeGroups channel count: ' numel([session.extracellular.electrodeGroups.channels{:}])],'OK '}];
            elseif isempty(session.extracellular.electrodeGroups.channels)
                shortcutList = [shortcutList;{'electrodeGroups not defined','<html><b><font color="red">electrodeGroups empty</font></b></html>'}];
            else
                shortcutList = [shortcutList;{'electrodeGroups channel count','<html><b><font color="blue">not equal to extracellular.nChannels</font></b></html>'}];
            end
        end
    end
    shortcutList = [shortcutList;{'',''}];
end

%% Verifying if data that is pointed to exists
shortcutList = [shortcutList;{['<html><b>','Verification of paths and fields','</b></html>'], ''}];
if exist(session.general.basePath,'dir')
    shortcutList = [shortcutList;{'session.general.basePath','basepath exists'}];
else
    shortcutList = [shortcutList;{'session.general.basePath','<html><b><font color="red">path does not exist</font></b></html>'}];
end
if isfield(session,'spikeSorting') && ~isempty(session.spikeSorting{1}) && isfield(session.spikeSorting{1},'relativePath')
    clusteringpath = session.spikeSorting{1}.relativePath;
else
    clusteringpath = '';
end 
if exist(fullfile(session.general.basePath,clusteringpath),'dir')
    shortcutList = [shortcutList;{'session.spikeSorting{1}.relativePath','clustering data path exist'}];
else
    shortcutList = [shortcutList;{'session.spikeSorting{1}.relativePath','<html><b><font color="red">clustering data path does not exist</font></b></html>'}];
end
% Verifying raw data file exist
if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
    fileNameRaw = session.extracellular.fileName;
else
    fileNameRaw = [session.general.name '.dat'];
end

if exist(fullfile(session.general.basePath,fileNameRaw),'file')
    shortcutList = [shortcutList;{['Raw data file: ', fileNameRaw],'raw data exists'}];
else
    shortcutList = [shortcutList;{['Raw data file: ', fileNameRaw],'<html><b><font color="red">raw data does not exist</font></b></html>'}];
end

%% Plotting figure with outcome-table
if ismac
    dimensions = [420,(size(shortcutList,1)+1)*17.5];
else
    dimensions = [420,(size(shortcutList,1)+1)*18.5];
end
dimensions(2) = min(dimensions(2),700);
fig.verifySessionStruct = figure('Position', [300, 300, dimensions(1), dimensions(2)],'Name','CellExplorer: verification of session struct content', 'MenuBar', 'None','NumberTitle','off','visible','off'); movegui(fig.verifySessionStruct,'center'), set(fig.verifySessionStruct,'visible','on')
fig.sessionList = uitable(fig.verifySessionStruct,'Data',shortcutList,'Position',[1, 1, dimensions(1)-1, dimensions(2)-1],'ColumnWidth',{200 200},'columnname',{'Field','Outcome'},'RowName',[],'ColumnEditable',[false false],'Units','normalized');
