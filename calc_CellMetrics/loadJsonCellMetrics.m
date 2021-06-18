function cell_metrics = loadJsonCellMetrics(json_file)
    % Loads cell_metrics to a Matlab struct from a cell_metrics JSON file. Output is compatible with CellExplorer
    % The format is described here:https://cellexplorer.org/datastructure/standard-cell-metrics/
    %
    % Learn more about CellExplorer at https://CellExplorer.org/
    %
    % Example call:
    % cell_metrics = loadJsonCellMetrics('cell_metrics.json');
    %
    % Now you can run CellExplorer: 
    % cell_metrics = CellExplorer('metrics',cell_metrics);
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated: 18-06-2021

    % Load and decode json content
    json_file = 'cell_metrics.json';
    text1 = fileread(json_file);
    text1 = strrep(text1,'\','\\'); % Handling backslash from strings
    cell_metrics = jsondecode(text1);
    
    % % % % % % % % % % % % % % % % % %
    % Cleaning metrics in the cell_metrics root (setting correct dimensions)
    % % % % % % % % % % % % % % % % % %
    fields = fieldnames(cell_metrics);
    for i = 1:numel(fields)
        if all(size(cell_metrics.(fields{i})) == [cell_metrics.general.cellCount,1])
            cell_metrics.(fields{i}) = cell_metrics.(fields{i})';
        end
        
    end
    
    % Same action as above, but on the content of struct fields:
    structFields = {'waveforms','tags','acg','firingRateMaps','general','groundTruthClassification','isi','putativeConnections','responseCurves','spikes'};
    for j = 1:numel(structFields)
        fieldsInStruct = fieldnames(cell_metrics.(structFields{j}));
        for i = 1:numel(fieldsInStruct)
            if numel(size(cell_metrics.(structFields{j}).(fieldsInStruct{i})))==2 && all(size(cell_metrics.(structFields{j}).(fieldsInStruct{i})) == [cell_metrics.general.cellCount,1])
                cell_metrics.(structFields{j}).(fieldsInStruct{i}) = cell_metrics.(structFields{j}).(fieldsInStruct{i})';
            end
        end
    end
    
    % % % % % % % % % % % % % % % % % %
    % 2-dimensional fields
    % % % % % % % % % % % % % % % % % %
    cell_fields = {};
    cell_fields.waveforms = {'filt','filt_std','time','raw','raw_std','bestChannels','time_all','peakVoltage_all','channels_all'};
    cell_fields.responseCurves = {'thetaPhase','firingRateAcrossTime','meanCCG'};
    cell_fields.firingRateMaps = {};
    
    fields2process = fieldnames(cell_fields);
    for j = 1:numel(fields2process)
        if isempty(cell_fields.(fields2process{j}))
            cell_fields.(fields2process{j}) = fieldnames(cell_metrics.(fields2process{j}));
        end
        for i = 1:numel(cell_fields.(fields2process{j}))
            if isfield(cell_metrics.(fields2process{j}),cell_fields.(fields2process{j}){i}) && isnumeric(cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i})) && numel(size(cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i})))==2
                disp(['Processing 2-dim ',fields2process{j},'.' cell_fields.(fields2process{j}){i}])
                if strcmp(fields2process{j},'waveforms')
                    cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i}) = num2cell(cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i}),2)';
                else
                    cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i}) = num2cell(cell_metrics.(fields2process{j}).(cell_fields.(fields2process{j}){i})',1);
                end
            end
        end
    end
    
    % % % % % % % % % % % % % % % % % %
    % 3-dimensional fields
    % % % % % % % % % % % % % % % % % %
    cell_fields2.waveforms = {'raw_all','filt_all'};
    cell_fields2.firingRateMaps = {};
    fields2process = fieldnames(cell_fields2);
    for j = 1:numel(fields2process)
        if isempty(cell_fields2.(fields2process{j}))
            cell_fields2.(fields2process{j}) = fieldnames(cell_metrics.(fields2process{j}));
        end
        for i = 1:numel(cell_fields2.(fields2process{j}))
            if isfield(cell_metrics.(fields2process{j}),cell_fields2.(fields2process{j}){i}) && isnumeric(cell_metrics.(fields2process{j}).(cell_fields2.(fields2process{j}){i})) && numel(size(cell_metrics.(fields2process{j}).(cell_fields2.(fields2process{j}){i})))==3
                disp(['Processing 3-dim ',fields2process{j},'.' cell_fields2.(fields2process{j}){i}])
                temp = {};
                for k = 1:size(cell_metrics.(fields2process{j}).(cell_fields2.(fields2process{j}){i}),1)
                    temp{k} = squeeze(cell_metrics.(fields2process{j}).(cell_fields2.(fields2process{j}){i})(k,:,:));
                end
                cell_metrics.(fields2process{j}).(cell_fields2.(fields2process{j}){i}) = temp;
            end
        end
    end
    
    % % % % % % % % % % % % % % % % % %
    % General struct fields
    % % % % % % % % % % % % % % % % % %
    % Electrode groups
    if isfield(cell_metrics.general,'electrodeGroups')
        if size(cell_metrics.general.electrodeGroups,1) > 1
            cell_metrics.general.electrodeGroups = cell_metrics.general.electrodeGroups';
        end
        for i = 1:numel(cell_metrics.general.electrodeGroups)
            cell_metrics.general.electrodeGroups{i} = cell_metrics.general.electrodeGroups{i}(:)';
        end
    end
    
    % Setting proper dimension on numeric fields in general.struct-fields
    for j = 1:numel(structFields)
        if isfield(cell_metrics.general,structFields{j})
            fieldsInStruct = fieldnames(cell_metrics.general.(structFields{j}));
            for i = 1:numel(fieldsInStruct)
                fieldsInStruct2 = fieldnames(cell_metrics.general.(structFields{j}).(fieldsInStruct{i}));
                for k = 1:numel(fieldsInStruct2)
                    disp(['Processing general: ',structFields{j},'.', fieldsInStruct{i},'.' fieldsInStruct2{k}])
                    cell_metrics.general.(structFields{j}).(fieldsInStruct{i}).(fieldsInStruct2{k}) = cell_metrics.general.(structFields{j}).(fieldsInStruct{i}).(fieldsInStruct2{k})(:)';
                end
            end
        end
    end
    disp('Processing complete')
end
    