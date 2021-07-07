function nwb = saveCellMetrics2nwb(cell_metrics,nwb_file)
% Saves cell_metrics to a nwb file from a cell_metrics JSON file. Output is compatible with CellExplorer
% The format is described here:https://cellexplorer.org/datastructure/standard-cell-metrics/
%
% Learn more about CellExplorer at https://CellExplorer.org/
%
% Example call:
% nwb = saveCellMetrics2nwb(cell_metrics,'filename.nwb');

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 06-07-2021
% Original script by Ben Dichter

% nwb_file = [cell_metrics.general.basename,'.cellmetrics.nwb'];

% Generating a nwb extension from a yaml file for handling a subset of the metadata (located in calc_CellMetrics/nwb_spec)
generateExtension('ndx-cell-explorer.namespace.yaml');


nwb = NwbFile( ...
    'session_description', cell_metrics.general.basepath, ...
    'identifier', cell_metrics.general.basename,  ...
    'session_start_time', datetime, ...
    'general_experimenter', cell_metrics.general.session.investigator, ...
    'general_subject', types.core.Subject( ...
        'sex', cell_metrics.general.animal.sex(1), ...
        'subject_id', cell_metrics.animal{1}, ...
        'species', cell_metrics.general.animal.species, ...
        'strain', cell_metrics.general.animal.strain, ...
        'genotype', cell_metrics.general.animal.geneticLine ...
    ) ...
);

% Questions/To Do: general metadata
print1 = false;
if print1
% cell_metrics.general.session % struct with session fields: .sessionType, .spikeSortingMethod - strings
% cell_metrics.general.saveAs % string
% cell_metrics.general.chanCoords % .source, .layout, .shankSpacing (strings and numeric fields)
% cell_metrics.general.responseCurves.firingRateAcrossTime.x_bins % related to cell_metrics.responseCurves, 
% cell_metrics.general.events.ripples % x_bins, x_label, alignment, event_file
% cell_metrics.general.manipulations.cooling % x_bins, x_label, alignment, event_file. Related to cell_metrics.manipulations, 
% cell_metrics.general.firingRateMaps.LeftRight % x_bins, boundaries, labels
% cell_metrics.general.acgs.log10 % log_bins (used for log ACG)
% cell_metrics.general.isis.log10 % log_bins (used for log ISI)
% cell_metrics.general.epochs % behavioral temporal epochs (optional struct; name, startTime, stopTime, environment, behavioralParadigm) Inherited from sessions
% cell_metrics.general.states.SleepState % struct with states intervals (e.g. WaKEstate, NREMstate, REMstate)

% Open questions 
% units/waveform sampling rate?
end

% General fields saved to extension
cell_explorer_general = types.ndx_cell_explorer.CellExplorerGeneral( ...
    'session_investigator', cell_metrics.general.session.investigator, ...
    'session_sessionType', cell_metrics.general.session.sessionType, ...
    'session_spikeSortingMethod', cell_metrics.general.session.spikeSortingMethod, ...
    'acgs_log10', cell_metrics.general.acgs.log10, ...
    'isis_log10', cell_metrics.general.isis.log10 ...
    );

nwb.general.set('cell_explorer_general', cell_explorer_general);

% chanCoords
if isfield(cell_metrics.general,'chanCoords')
    disp('Adding general.chanCoords')
    chanCoords = types.ndx_cell_explorer.chanCoords();
    variables = fields(cell_metrics.general.chanCoords);
    for i = 1:numel(variables)
        chanCoords.(variables{i}) = cell_metrics.general.chanCoords.(variables{i});
    end
    nwb.general.set('chanCoords', chanCoords);
end

% FiringRateMaps
if isfield(cell_metrics.general,'firingRateMaps')
    disp('Adding general.firingRateMaps')
    firingratemaps = types.ndx_cell_explorer.firingRateMaps();
    list1 = fields(cell_metrics.general.firingRateMaps);
    for i = 1:numel(list1)
        data = types.ndx_cell_explorer.firingRateMap('name', list1(i));
        variables = fields(cell_metrics.general.firingRateMaps.(list1{i}));
        for j = 1:numel(variables)
            data.(variables{j}) = cell_metrics.general.firingRateMaps.(list1{i}).(variables{j});
        end
        firingratemaps.firingratemap.set(list1{i},data);
    end
    nwb.general.set('firingratemaps', firingratemaps);
end

% ResponseCurves
if isfield(cell_metrics.general,'responseCurves')
    disp('Adding general.responseCurves')
    responseCurves = types.ndx_cell_explorer.responseCurves();
    list1 = fields(cell_metrics.general.responseCurves);
    for i = 1:numel(list1)
        data = types.ndx_cell_explorer.responseCurve('name', list1(i));
        variables = fields(cell_metrics.general.responseCurves.(list1{i}));
        for j = 1:numel(variables)
            data.(variables{j}) = cell_metrics.general.responseCurves.(list1{i}).(variables{j});
        end
        responseCurves.responsecurve.set(list1{i},data);
    end
    nwb.general.set('responseCurves', responseCurves);
end

% Events
if isfield(cell_metrics.general,'events')
    disp('Adding general.events')
    Events = types.ndx_cell_explorer.Events();
    list1 = fields(cell_metrics.general.events);
    for i = 1:numel(list1)
        data = types.ndx_cell_explorer.eventdata('name', list1(i));
        variables = fields(cell_metrics.general.events.(list1{i}));
        for j = 1:numel(variables)
            data.(variables{j}) = cell_metrics.general.events.(list1{i}).(variables{j});
        end
        Events.eventdata.set(list1{i},data);
    end
    nwb.general.set('Events', Events);
end

% Manipulations
if isfield(cell_metrics.general,'manipulations')
    disp('Adding general.manipulations')
    manipulations = types.ndx_cell_explorer.manipulations();
    list1 = fields(cell_metrics.general.manipulations);
    for i = 1:numel(list1)
        data = types.ndx_cell_explorer.manipulationdata('name', list1(i));
        variables = fields(cell_metrics.general.manipulations.(list1{i}));
        for j = 1:numel(variables)
            data.(variables{j}) = cell_metrics.general.manipulations.(list1{i}).(variables{j});
        end
        manipulations.manipulationdata.set(list1{i},data);
    end
    nwb.general.set('manipulations', manipulations);
end

%% Electrodes table
% in this example, "label" is a custom column that can be safely removed.
% The rest are required.

nElectrodeGroups = numel(cell_metrics.general.electrodeGroups);
variables = {'x', 'y', 'z', 'imp', 'location', 'filtering', 'group', 'label'};
tbl = cell2table(cell(0, length(variables)), 'VariableNames', variables);
device = types.core.Device(...
    'description', 'the best array', ...
    'manufacturer', 'Probe Company 9000'...
);

device_name = 'array';
nwb.general_devices.set(device_name, device);
device_link = types.untyped.SoftLink(['/general/devices/' device_name]);
channel_shank = [];
channel_shank_order = [];
for iElectrode = 1:nElectrodeGroups
    group_name = ['shank_' num2str(iElectrode)];
    nwb.general_extracellular_ephys.set(group_name, ...
        types.core.ElectrodeGroup( ...
            'description', ['electrode group for shank' num2str(iElectrode)], ...
   	        'location', 'brain area', ...
   	        'device', device_link));
    group_object_view = types.untyped.ObjectView( ...
       	['/general/extracellular_ephys/' group_name]);
    
    channels = cell_metrics.general.electrodeGroups{iElectrode};
    channel_shank(channels) = iElectrode;
    for iChannels = 1:numel(channels)
        channel_shank_order(channels(iChannels)) = iChannels;
    end
end
for i = 1:numel(channel_shank)
    tbl = [tbl; {cell_metrics.general.ccf.x(i), cell_metrics.general.ccf.y(i), cell_metrics.general.ccf.z(i), NaN, 'unknown', 'unknown', ...
            group_object_view, ['shank_', num2str(channel_shank(i)) , '__elec_' num2str(channel_shank_order(i))]}];
end
tbl.rel_x = cell_metrics.general.chanCoords.x;
tbl.rel_y = cell_metrics.general.chanCoords.y;
electrode_table = util.table2nwb(tbl, 'all electrodes');
nwb.general_extracellular_ephys_electrodes = electrode_table;

%% Spikes
% reshape spikes
spikes = {};
for i=1:length(cell_metrics.spikes.times)
    spikes{i} = cell_metrics.spikes.times{i}';
end

% util.create_indexed_column is used for ragged arrays, when the # of cells
% per row changes:
[spike_times_vector, spike_times_index] = util.create_indexed_column( ...
    spikes, '/units/spike_times');
spike_times_index.description = 'Unit index';
% Note that 'spike_times_index' is not in the colnames list.

% If the dimensions of each cell is the same, you can just put it directly in,
% with unit # as the last dimension (see acg_wide)


nwb.units = types.core.Units( ...
    'description', 'units table', ...
    'id', types.hdmf_common.ElementIdentifiers( ...
        'data', int64(0:length(spikes) - 1) ...
    ), ...
    'spike_times', spike_times_vector, ...
    'spike_times_index', spike_times_index ...
);

%% % 1. Numeric and string fields
% Fieldnames
list_metrics = fieldnames(cell_metrics);
list_metrics = list_metrics(find(ismember(struct2cell(structfun(@class,cell_metrics,'UniformOutput',false)),{'cell','double'})));
      
labels = metrics_labels(list_metrics); % For description fields

nwb.units.colnames = unique([nwb.units.colnames,list_metrics']);
for i = 1:numel(list_metrics)
    disp(['Adding ', list_metrics{i}])
    nwb.units.vectordata.set(list_metrics{i}, types.hdmf_common.VectorData( 'data', cell_metrics.(list_metrics{i}), 'description', labels.(list_metrics{i}) ));
end


%% % Struct fields
structFields = {'waveforms','firingRateMaps','responseCurves','acg','isi'};
fields_2_skip.waveforms = {'filt','filt_std'};
for j = 1:numel(structFields)
    list_metrics_struct = fieldnames(cell_metrics.(structFields{j}));
    list_metrics_struct2 = strcat(structFields{j},{'__'}, list_metrics_struct);
    for i = 1:numel(list_metrics_struct)
        if strcmp(structFields{j},'waveforms') && ismember(list_metrics_struct{i},fields_2_skip.waveforms)
            disp(['Skipping metric: ', structFields{j},'.',list_metrics_struct{i}])
        else
            nwb.units.colnames = unique([nwb.units.colnames,list_metrics_struct2{i}]);
            disp(['Adding ', list_metrics_struct2{i}])
            data = [];
            if isnumeric(cell_metrics.(structFields{j}).(list_metrics_struct{i}))
                data = cell_metrics.(structFields{j}).(list_metrics_struct{i})';
                label = '__numeric';
            elseif iscellnumeric(cell_metrics.(structFields{j}).(list_metrics_struct{i}))
                label = '__cellnumeric';
                try
                    for k = 1:cell_metrics.general.cellCount
                        data(k,:,:) = cell_metrics.(structFields{j}).(list_metrics_struct{i}){k};
                    end
                end
            else
                warning('Data not imported')
            end
            data(isnan(data)) = 0;
            data(isinf(data)) = 0;
            
            nwb.units.vectordata.set(list_metrics_struct2{i}, types.hdmf_common.VectorData( 'data', data, 'description', [list_metrics_struct2{i},label] ));
        end
    end
end

%% Waveforms
nwb.units.waveform_mean = types.hdmf_common.VectorData('data', vertcat(cell_metrics.waveforms.filt{:}), 'description', 'Spikes');
nwb.units.waveform_sd = types.hdmf_common.VectorData('data', vertcat(cell_metrics.waveforms.filt_std{:}), 'description', 'Spikes');
nwb.units.electrode_group = types.hdmf_common.VectorData('data', cell_metrics.shankID'-1, 'description', 'shankID');
nwb.units.electrodes = types.hdmf_common.DynamicTableRegion('data', cell_metrics.maxWaveformCh', 'description', 'maxWaveformCh','table', types.untyped.ObjectView('/general/extracellular_ephys/electrodes'));
% nwb.units.waveform_rate

%% % Tag fields
tagFields = {'tags', 'groups', 'groundTruthClassification'};
for j = 1:numel(tagFields)
    if isfield(cell_metrics,tagFields{j})
        list_metrics_struct = fieldnames(cell_metrics.(tagFields{j}));
        if ~isempty(list_metrics_struct)
            list_metrics_struct2 = strcat(tagFields{j},{'__'}, list_metrics_struct);
            nwb.units.colnames = unique([nwb.units.colnames,list_metrics_struct2']);
            for i = 1:numel(list_metrics_struct)
                disp(['Adding ', list_metrics_struct2{i}])
                data = zeros(length(spikes),1);
                data(cell_metrics.(tagFields{j}).(list_metrics_struct{i})) = 1;
                nwb.units.vectordata.set(list_metrics_struct2{i}, types.hdmf_common.DynamicTableRegion('data', data, 'description', list_metrics_struct2{i},'table', types.untyped.ObjectView('/units')));
            end
        end
    end
end

%% % Putative connections
if isfield(cell_metrics,'putativeConnections') && ~isempty(cell_metrics.putativeConnections)
    putativeConnectionsFields = {'excitatory', 'inhibitory'};
    list_metrics_struct2 = strcat({'putativeConnections__'}, putativeConnectionsFields);
    nwb.units.colnames = unique([nwb.units.colnames,list_metrics_struct2]);
    for i = 1:numel(putativeConnectionsFields)
        disp(['Adding ', list_metrics_struct2{i}])
        nwb.units.vectordata.set( ...
            list_metrics_struct2{i}, ...
            types.hdmf_common.DynamicTableRegion( ...
                'data', cell_metrics.putativeConnections.(putativeConnectionsFields{i})'-1, ...
                'description', list_metrics_struct2{i}, ...
                'table', types.untyped.ObjectView('/units') ...
            ) ...
        );
    end
end

%% Epochs data
if isfield(cell_metrics.general,'epochs')
    % load epochs data
    epochs = cell_metrics.general.epochs;
    nepochs = length(epochs);
    
    start_time_data = ones(1, nepochs) * NaN;
    stop_time_data = ones(1, nepochs) * NaN;
    name_data = {};
    behavioralParadigm_data = {};
    
    for i = 1:nepochs
        start_time_data(i) = epochs(i).startTime;
        stop_time_data(i) = epochs(i).stopTime;
        name_data{end+1} = epochs(i).name;
        behavioralParadigm_data{end+1} = epochs(i).behavioralParadigm;
    end
    
    % set epochs table
    nwb.intervals_epochs = types.core.TimeIntervals('description','cell_metrics.general.epochs',...
        'id', types.hdmf_common.ElementIdentifiers('data', int64(0:nepochs - 1)), ...
        'colnames', {'start_time', 'stop_time', ...
        'name', 'behavioralParadigm', ...
        'behavioralParadigmID', ...
        'environmentType', ...
        'environment', ...
        'manipulation', ...
        'manipulationID', ...
        'notes', ...
        'entryID', ...
        }, ...
        'start_time', types.hdmf_common.VectorData( ...
        'data', start_time_data, ...
        'description', 'start of epoch in seconds' ...
        ), ...
        'stop_time', types.hdmf_common.VectorData( ...
        'data', stop_time_data, ...
        'description', 'stop of epoch in seconds' ...
        ), ...
        'name', types.hdmf_common.VectorData( ...
        'data', name_data, ...
        'description', 'stop of epoch in seconds' ...
        ), ...
        'behavioralParadigm', types.hdmf_common.VectorData( ...
        'data', behavioralParadigm_data, ...
        'description', 'name of behavioral paradigm' ...
        ) ...
        );
end

%% Sleep state data
if isfield(cell_metrics.general,'states')
    
    states = cell_metrics.general.states;
    statesData = fieldnames(states);
    
    for i = 1:length(statesData)
        disp(['Adding general.states.', statesData{i}])
        % sorting data from all the states so that wake, nrem, and rem can all be in the same table
        start_time_data = [];
        stop_time_data = [];
        label_data = {};
        statesFields = fieldnames(states.(statesData{i}));
        for j = 1:numel(statesFields)
            if size(states.(statesData{i}).(statesFields{j}),2)==2
                start_time_data = [start_time_data;states.(statesData{i}).(statesFields{j})(:,1)];
                stop_time_data = [stop_time_data;states.(statesData{i}).(statesFields{j})(:,2)];
                stateLabel = repmat(statesFields(j),1,size(states.(statesData{i}).(statesFields{j}),1));
                label_data = [label_data,stateLabel];
            end
        end
        
        % Sorting state intervals by start_time
        [start_time_data,idx] = sort(start_time_data);
        stop_time_data = stop_time_data(idx);
        label_data = label_data(idx);
        
        % Set sleep state table
        nwb.intervals.set(statesData{i},types.core.TimeIntervals( 'description',statesData{i},...
            'id', types.hdmf_common.ElementIdentifiers('data', int64(0:length(start_time_data) - 1)), ...
            'colnames', {'start_time', 'stop_time', 'label'}, ...
            'start_time', types.hdmf_common.VectorData( ...
            'data', start_time_data, ...
            'description', 'start of state in seconds' ...
            ), ...
            'stop_time', types.hdmf_common.VectorData( ...
            'data', stop_time_data, ...
            'description', 'stop of state in seconds' ...
            ), ...
            'label', types.hdmf_common.VectorData( ...
            'data', label_data, ...
            'description', 'label of state' ...
            ) ...
            ));
    end
end

%%
nwbExport(nwb, nwb_file);
disp(' ')
disp(['cell_metrics exported to nwb succesfully: ' nwb_file])
end