---
layout: default
title: Custom single cell plots
parent: Graphical interface
nav_order: 8
---
# Custom single cell plots
{: .no_toc}
Custom single cell plots can be created and loaded in CellExplorer. Custom plot functions must be located in the subfolder `/+customPlots`. Each plot must be saved individually, for them to be loaded in CellExplorer. There is a template available to get you started:

```m
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
    % subsetPlots       a struct with plotted data. This struct allows the curves to 
                        be selected in the UI with the mouse cursor.
    %   .xaxis          x axis data (Nx1), where N is the number of samples 
    %   .yaxis          y axis data (NxM), where M is the number of cells
    %   .subset         list of cellIDs (Mx1)

    subsetPlots = [];
    plot(cell_metrics.waveforms.time{ii},cell_metrics.waveforms.filt_zscored(:,ii),'-','Color',col)
    
end
```

Your custom plot must accept the same inputs as defined in the template.
