function validateCellMetricsStruct(cell_metrics)
    % Defining field types of standard metrics
    cell_metrics_type_struct = {'general','acg','isi','waveforms','putativeConnections','firingRateMaps','responseCurves','events','manipulations','tags','groups','groundTruthClassification','spikes'};
    cell_metrics_type_cell = {'brainRegion','animal','sex','species','strain','geneticLine','labels','putativeCellType','deepSuperficial','synapticEffect'};
    cell_metrics_type_numeric = {'spikeGroup','spikeCount','firingRate','cv2','refractoryPeriodViolation','burstIndex_Mizuseki2012','thetaModulationIndex','acg_tau_rise',...
        'acg_tau_decay','acg_tau_burst','acg_refrac','acg_fit_rsquare','burstIndex_Royer2012','burstIndex_Doublets','synapticConnectionsIn','synapticConnectionsOut','maxWaveformCh',...
        'maxWaveformCh1','troughToPeak','ab_ratio','peakVoltage','isolationDistance','lRatio','ripples_modulationIndex','ripples_modulationPeakResponseTime','deepSuperficialDistance',...
        'thetaPhasePeak','thetaPhaseTrough','thetaEntrainment','thetaModulationIndex','spatialCoverageIndex','spatialGiniCoeff','spatialCoherence','spatialPeakRate', 'placeFieldsCount',...
        'placeCell','firingRateGiniCoeff','firingRateStd','firingRateInstability','peakVoltage_expFitLengthConstant'};
    
    metrics_fields = fieldnames(cell_metrics);
    
    any_warnings = false;
    
    for i=1:numel(metrics_fields)
        metrics = cell_metrics.(metrics_fields{i});
        % Predefined struct fields
        if isstruct(metrics) && ~ismember(metrics_fields{i},cell_metrics_type_struct)
            disp(['Struct field not formatted correctly: cell_metrics.' metrics_fields{i}])
            any_warnings = true;
        end
        
        % Predefined numeric fields
        if ismember(metrics_fields{i},cell_metrics_type_numeric) && ~isnumeric(metrics)
            disp(['Numeric field not formatted correctly: cell_metrics.' metrics_fields{i}])
            any_warnings = true;
        end
        
        % Cell array
        if ismember(metrics_fields{i},cell_metrics_type_cell) && ~iscell(metrics)
            disp(['Cell array field not formatted correctly: cell_metrics.' metrics_fields{i}])
            any_warnings = true;
        end
        
        % Checking dimensions of all numeric and cell array fields, must be equal to [1,cell_metrics.general.cellCount]
        if ( isnumeric(metrics) || iscell(metrics) ) && any(size(metrics) ~= [1,cell_metrics.general.cellCount])
            disp(['Numeric or cell array field with wrong dimensions: cell_metrics.' metrics_fields{i},', dim: ' num2str(size(metrics))])
            any_warnings = true;
        end     
    end
    if any_warnings
        error('Validation of the cell_metrics failed')
    end
    
    % Validating struct fields
    cell_metrics_types = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
    fields_struct = find(ismember(cell_metrics_types,'struct'));
    for i = 1:length(fields_struct)
        if ~strcmp(metrics_fields{fields_struct(i)},{'general','putativeConnections','tags','groups','groundTruthClassification'})
            field_fieldnames = fieldnames(cell_metrics.(metrics_fields{fields_struct(i)}));
            field_types = struct2cell(structfun(@class,cell_metrics.(metrics_fields{fields_struct(i)}),'UniformOutput',false));
            field_sizes = cell2mat(struct2cell(structfun(@size, cell_metrics.(metrics_fields{fields_struct(i)}),'UniformOutput',false)));
            field_numeric_cell = find(ismember(field_types,{'double','cell'}));
            if any(field_sizes(field_numeric_cell,2) ~= cell_metrics.general.cellCount)
                warning(['Incorrect dimensions: cell_metrics.' metrics_fields{fields_struct(i)},'.',field_fieldnames{field_numeric_cell(field_sizes(field_numeric_cell,2) ~= cell_metrics.general.cellCount)}])
            end
        end
    end
end