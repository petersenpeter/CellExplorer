function putativeCellType = standard(cell_metrics,preferences)
    % INPUTS
    % cell_metrics :    cell_metrics struct
    % preferences  :    preferences used by ProcessCellMetrics
    %
    % OUTPUT
    % putativeCellType  a cell array with assigned cell types
    %
    % You may use this as a template for creating your own classification schemas
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated 14-05-2021
    
    dispLog('Performing Cell-type classification using standard parameters');

    % All cells are initially assigned as Pyramidal cells
    putativeCellType = repmat({'Pyramidal Cell'},1,cell_metrics.general.cellCount);

    % Cells are reassigned as interneurons by below criteria 
    % Narrow interneuron assigned if troughToPeak <= 0.425 ms (preferences.putativeCellType.troughToPeak_boundary)
    putativeCellType(cell_metrics.troughToPeak <= preferences.putativeCellType.troughToPeak_boundary) = repmat({'Narrow Interneuron'},sum(cell_metrics.troughToPeak <= preferences.putativeCellType.troughToPeak_boundary),1);

    % acg_tau_rise > 6 ms (preferences.putativeCellType.acg_tau_rise_boundary) and troughToPeak > 0.425 ms
    putativeCellType(cell_metrics.acg_tau_rise > preferences.putativeCellType.acg_tau_rise_boundary & cell_metrics.troughToPeak > preferences.putativeCellType.troughToPeak_boundary) = repmat({'Wide Interneuron'},sum(cell_metrics.acg_tau_rise > preferences.putativeCellType.acg_tau_rise_boundary & cell_metrics.troughToPeak > preferences.putativeCellType.troughToPeak_boundary),1);
end
