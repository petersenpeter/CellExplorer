function subsetPlots = template(cell_metrics,UI,ii,col)
    % This is a example template for creating your own custom single cell plots
    %
    % INPUTS
    % cell_metrics      cell_metrics struct
    % UI                the struct with figure handles, settings and parameters
    % ii                index of the current cell
    % col               color of the current cell
    %
    % OUTPUT
    % subsetPlots       a struct with any extra single cell plots from synaptic partner cells
    %   .xaxis          x axis data (Nx1), where N is the number of samples 
    %   .yaxis          y axis data (NxM), where M is the number of cells
    %   .subset         list of cellIDs (Mx1)
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated 15-12-2019
    
    subsetPlots = [];
    plot(cell_metrics.waveforms.time{ii},cell_metrics.waveforms.filt_zscored(:,ii),'-','Color',col)
end