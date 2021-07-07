function cell_metrics = loadNwbCellMetrics(nwb_file)
% Generate cell_metrics from a nwb file (NeurodataWithoutBorder). Output is compatible with CellExplorer
% The nwb file should be generated from the cell_metrics using saveCellMetrics2nwb.m
%
% The format is described here:https://cellexplorer.org/datastructure/standard-cell-metrics/
%
% Example call:
% cell_metrics = loadNwbCellMetrics('file.nwb');
%
% Now you may run CellExplorer: 
% cell_metrics = CellExplorer('metrics',cell_metrics);

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 05-07-2021

% TODO 
% nwb3.general_experimenter?

% nwb_file = [cell_metrics.general.basename,'.nwb']; 
nwb = nwbRead(nwb_file);

cell_metrics = {};

% General fields
cell_metrics.general.session.investigator = nwb.general_experimenter;
cell_metrics.general.basepath = nwb.session_description;
cell_metrics.general.basename = nwb.identifier;


cell_metrics.general.animal.sex = nwb.general_subject.sex;
cell_metrics.general.animal.species = nwb.general_subject.species;
cell_metrics.general.animal.strain = nwb.general_subject.strain;
cell_metrics.general.animal.geneticLine = nwb.general_subject.genotype;
cell_metrics.general.animal.name = nwb.general_subject.subject_id; % must be a metric

cell_metrics.general.cellCount = nwb.units.id.data.dims;

% Adding basepath to file
try
    [basepath,~,~] = fileparts(nwb_file);
    cell_metrics.general.basepath = basepath;
end

% Adding file format to file
cell_metrics.general.fileFormat = 'nwb';
disp('Processing complete')
    
% General fields
if any(ismember(nwb.general.keys,'cell_explorer_general'))
    cell_explorer_general = nwb.general.get('cell_explorer_general');
    cell_metrics.general.saveAs = cell_explorer_general.saveAs;
    cell_metrics.general.acgs.log10 = cell_explorer_general.acgs_log10.load;
    cell_metrics.general.isis.log10 = cell_explorer_general.isis_log10.load;
    
    cell_metrics.general.session.investigator = cell_explorer_general.session_investigator;
    cell_metrics.general.session.sessionType = cell_explorer_general.session_sessionType;
    cell_metrics.general.session.spikeSortingMethod = cell_explorer_general.session_spikeSortingMethod;
end

% FiringRateMaps
if any(ismember(nwb.general.keys,'firingratemaps'))
    data = nwb.general.get('firingratemaps');
    labels1 = data.firingratemap.keys;
    for i = 1:numel(labels1)
        data_new = data.firingratemap.get(labels1{i});
        fields_new = fields(data_new);
        for j = 1:numel(fields_new)
            temp = data_new.(fields_new{j});
            if ischar(temp) || isnumeric(temp)
                cell_metrics.general.firingRateMaps.(labels1{i}).(fields_new{j}) = temp;
            else
                cell_metrics.general.firingRateMaps.(labels1{i}).(fields_new{j}) = temp.load';
            end
        end
    end
end

% ResponseCurves
if any(ismember(nwb.general.keys,'responseCurves'))
    data = nwb.general.get('responseCurves');
    labels1 = data.responsecurve.keys;
    for i = 1:numel(labels1)
        data_new = data.responsecurve.get(labels1{i});
        fields_new = fields(data_new);
        for j = 1:numel(fields_new)
            temp = data_new.(fields_new{j});
            if ischar(temp) || isnumeric(temp)
                cell_metrics.general.responseCurves.(labels1{i}).(fields_new{j}) = temp;
            else
                cell_metrics.general.responseCurves.(labels1{i}).(fields_new{j}) = temp.load';
            end
        end
    end
end

% Events
if any(ismember(nwb.general.keys,'Events'))
    data = nwb.general.get('Events');
    labels1 = data.eventdata.keys;
    for i = 1:numel(labels1)
        data_new = data.eventdata.get(labels1{i});
        fields_new = fields(data_new);
        for j = 1:numel(fields_new)
            temp = data_new.(fields_new{j});
            if ischar(temp) || isnumeric(temp)
                cell_metrics.general.events.(labels1{i}).(fields_new{j}) = temp;
            else
                cell_metrics.general.events.(labels1{i}).(fields_new{j}) = temp.load';
            end
        end
    end
end

% Manipulations
if any(ismember(nwb.general.keys,'manipulations'))
    data = nwb.general.get('manipulations');
    labels1 = data.manipulationdata.keys;
    for i = 1:numel(labels1)
        data_new = data.manipulationdata.get(labels1{i});
        fields_new = fields(data_new);
        for j = 1:numel(fields_new)
            temp = data_new.(fields_new{j});
            if ischar(temp) || isnumeric(temp)
                cell_metrics.general.manipulations.(labels1{i}).(fields_new{j}) = temp;
            else
                cell_metrics.general.manipulations.(labels1{i}).(fields_new{j}) = temp.load';
            end
        end
    end
end

%% Electrodes
% Electrode groups
electrodeGroups = {};
electrodes = cellstr(nwb.general_extracellular_ephys_electrodes.vectordata.get('label').data.load);
for i = 1:numel(electrodes)
    temp = strsplit(electrodes{i},'__');
    shank_id = strsplit(temp{1},'_');
    channel_id = strsplit(temp{2},'_');
    electrodeGroups{str2num(shank_id{2})}(str2num(channel_id{2})) = i;
end
cell_metrics.general.electrodeGroups = electrodeGroups;

% Channel coordinates
if any(strcmp(nwb.general_extracellular_ephys_electrodes.colnames,'rel_x'))
    cell_metrics.general.chanCoords.x = nwb.general_extracellular_ephys_electrodes.vectordata.get('rel_x').data.load;
    cell_metrics.general.chanCoords.y = nwb.general_extracellular_ephys_electrodes.vectordata.get('rel_y').data.load;
end
if any(ismember(nwb.general.keys,'chanCoords'))
    chanCoords = nwb.general.get('chanCoords');
    chanCoords_fields = {'shankSpacing','layout','source'};
    for i= 1:numel(chanCoords_fields)
        if ismember(chanCoords_fields{i},fields(chanCoords))
            cell_metrics.general.chanCoords.(chanCoords_fields{i}) = chanCoords.(chanCoords_fields{i});
        end
    end
end

% ccf (common coordinate framework)
if any(strcmp(nwb.general_extracellular_ephys_electrodes.colnames,'x'))
    cell_metrics.general.ccf.x = nwb.general_extracellular_ephys_electrodes.vectordata.get('x').data.load;
    cell_metrics.general.ccf.y = nwb.general_extracellular_ephys_electrodes.vectordata.get('y').data.load;
    cell_metrics.general.ccf.z = nwb.general_extracellular_ephys_electrodes.vectordata.get('z').data.load;
end

%% Loading numeric and string fields
metrics_fields = nwb.units.colnames;
for i = 1:numel(metrics_fields)
    if ~contains(metrics_fields{i},'__')
        data = nwb.units.vectordata.get(metrics_fields{i}).data.load;
        if isnumeric(data)
            disp(['Importing numeric: ' metrics_fields{i}])
            cell_metrics.(metrics_fields{i}) = data';
        else ischar(data)
            disp(['Importing string: ' metrics_fields{i}])
            cell_metrics.(metrics_fields{i}) = cellstr(data)';
        end
    end
end

%% Spikes

spike_data = nwb.units.spike_times.data.load;
spike_data_index = nwb.units.spike_times_index.data.load;
index = [0;spike_data_index];
for j = 1:numel(spike_data_index)
    cell_metrics.spikes.times{j} = spike_data(index(j)+1:index(j+1));
end

%% Waveforms 

cell_metrics.waveforms.filt = num2cell(nwb.units.waveform_mean.data.load,2)';
cell_metrics.waveforms.filt_std = num2cell(nwb.units.waveform_sd.data.load,2)';
cell_metrics.shankID = (nwb.units.electrode_group.data.load')+1;
cell_metrics.maxWaveformCh = double(nwb.units.electrodes.data.load');

%% % Putative connections

try
    cell_metrics.putativeConnections.excitatory = double(nwb.units.vectordata.get('putativeConnections__excitatory').data.load')+1;
catch
    cell_metrics.putativeConnections.excitatory = [];    
end
try
    cell_metrics.putativeConnections.inhibitory = double(nwb.units.vectordata.get('putativeConnections__inhibitory').data.load')+1;
catch
    cell_metrics.putativeConnections.inhibitory = [];
end

%% % Tag fields

tagFields = {'tags', 'groups', 'groundTruthClassification'};
for j = 1:numel(tagFields)
    metrics_fields_tags = nwb.units.colnames(contains(nwb.units.colnames,[tagFields{j},'__']));
    if ~isempty(metrics_fields_tags)
        for i = 1:numel(metrics_fields_tags)
            variable_name = strsplit(metrics_fields_tags{i},'__');
            variable_name = variable_name{end};
        
            disp(['Importing ' ,tagFields{j},'.', variable_name]);
            temp = double(find(nwb.units.vectordata.get(metrics_fields_tags{i}).data.load));
            cell_metrics.(tagFields{j}).(variable_name) = temp(:)';
        end
    else
        cell_metrics.(tagFields{j}) = {};
    end
end

%% % Struct fields

structFields = {'waveforms','firingRateMaps','responseCurves','acg','isi'};

for j = 1:numel(structFields)
    metrics_fields_structs = nwb.units.colnames(contains(nwb.units.colnames,[structFields{j},'__']));

    for i = 1:numel(metrics_fields_structs)
        disp(['Importing ' metrics_fields_structs{i}])
        variable_name = strsplit(metrics_fields_structs{i},'__');
        variable_name = variable_name{end};
        
        data_type = strsplit(nwb.units.vectordata.get(metrics_fields_structs{i}).description,'__');
        data_type = data_type{end};
        
        data = nwb.units.vectordata.get(metrics_fields_structs{i}).data.load;
        
        switch data_type
            case 'cellnumeric'
                data1 = {};
                for k = 1:size(data,1) 
                    data1{k} = permute(data(k,:,:),[2 3 1]);
                end
                cell_metrics.(structFields{j}).(variable_name) = data1;
            case 'numeric'    
                cell_metrics.(structFields{j}).(variable_name) = data';
        end
    end
end

