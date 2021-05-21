function verifyCellMetricsStruct(cell_metrics)
    % Defining field types of standard metrics
    cell_metrics_type_struct = {'general','acg','isi','waveforms','putativeConnections','firingRateMaps','responseCurves','events','manipulations','tags','groups','groundTruthClassification','spikes'};
    cell_metrics_type_cell = {'brainRegion','animal','sex','species','strain','geneticLine','labels','putativeCellType','deepSuperficial','synapticEffect'};
    cell_metrics_type_numeric = {'spikeGroup','spikeCount','firingRate','cv2','refractoryPeriodViolation','burstIndex_Mizuseki2012','thetaModulationIndex','acg_tau_rise',...
        'acg_tau_decay','acg_tau_burst','acg_refrac','acg_fit_rsquare','burstIndex_Royer2012','burstIndex_Doublets','synapticConnectionsIn','synapticConnectionsOut','maxWaveformCh',...
        'maxWaveformCh1','troughToPeak','ab_ratio','peakVoltage','isolationDistance','lRatio','ripples_modulationIndex','ripples_modulationPeakResponseTime','deepSuperficialDistance',...
        'thetaPhasePeak','thetaPhaseTrough','thetaEntrainment','thetaModulationIndex','spatialCoverageIndex','spatialGiniCoeff','spatialCoherence','spatialPeakRate', 'placeFieldsCount',...
        'placeCell','firingRateGiniCoeff','firingRateStd','firingRateInstability','peakVoltage_expFitLengthConstant'};
    
    cell_metrics_fieldnames = fieldnames(cell_metrics);
    cell_metrics_types = struct2cell(structfun(@class,cell_metrics,'UniformOutput',false));
    cell_metrics_sizes = cell2mat(struct2cell(structfun(@size, cell_metrics,'UniformOutput',false)));
    cell_metrics_numeric_cell = find(ismember(cell_metrics_types,{'double','cell'}));
    cell_metrics_numeric = find(ismember(cell_metrics_types,{'double'}));
    cell_metrics_cell = find(ismember(cell_metrics_types,{'cell'}));
    fields_struct = find(ismember(cell_metrics_types,'struct'));
    
    % Verifying struct type
    if ~any(ismember(cell_metrics_types((ismember(cell_metrics_fieldnames,cell_metrics_type_struct))),'struct'))
        error('struct field not formatted correctly in cell_metrics')
    end
    % Verifying numeric type
    if ~any(ismember(cell_metrics_types((ismember(cell_metrics_fieldnames,cell_metrics_type_numeric))),'double'))
        error('numeric field not formatted correctly in cell_metrics')
    end
    % Verifying cell type
    if ~any(ismember(cell_metrics_types((ismember(cell_metrics_fieldnames,cell_metrics_type_cell))),'cell'))
        error('cell array field not formatted correctly in cell_metrics')
    end
    % Verifying field sizes
    if any(any(cell_metrics_sizes(cell_metrics_numeric_cell,:) ~= [1,cell_metrics.general.cellCount]))
        cell_metrics
        error('cell_metrics: One or more numeric field/cell not dimensionalized correct')
    end
    % Verifying struct fields
    for i = 1:length(fields_struct)
        if ~strcmp(cell_metrics_fieldnames{fields_struct(i)},{'general','putativeConnections','tags','groups','groundTruthClassification'})
            field_fieldnames = fieldnames(cell_metrics.(cell_metrics_fieldnames{fields_struct(i)}));
            field_types = struct2cell(structfun(@class,cell_metrics.(cell_metrics_fieldnames{fields_struct(i)}),'UniformOutput',false));
            field_sizes = cell2mat(struct2cell(structfun(@size, cell_metrics.(cell_metrics_fieldnames{fields_struct(i)}),'UniformOutput',false)));
            field_numeric_cell = find(ismember(field_types,{'double','cell'}));
            if any(field_sizes(field_numeric_cell,2) ~= cell_metrics.general.cellCount)
                warning(['Incorrect dimensions: cell_metrics.' cell_metrics_fieldnames{fields_struct(i)},'.',field_fieldnames{field_numeric_cell(field_sizes(field_numeric_cell,2) ~= cell_metrics.general.cellCount)}])
            end
        end
    end
end