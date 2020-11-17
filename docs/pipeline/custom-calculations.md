---
layout: default
title: Custom calculations
parent: Processing module
nav_order: 7
---
# Custom calculations
The CellExplorer processing module has a subfolder for user defined calculations to exist outside the main processing module. These scripts will automatically be loaded by the processing module `ProcessCellMetrics`.
This way updates to the software CellExplorer can be applied without affecting your own additions to the pipeline. Please save your scripts to the folder `+customCalculations/` and follow the template already in that folder to integrate your own calculations into the processing module.

Any additional metrics have to follow CellExplorer [cell_metrics standard]({{"/datastructure/expandability/"|absolute_url}}). Any `events` or `manipulation` files located in the basepath will be detected in the pipeline and PSTHs will be generated automatically.

```m
function cell_metrics = template(cell_metrics,session,spikes,spikes_all)
    % This is an example template for creating your own calculations
    %
    % INPUTS
    % cell_metrics      cell_metrics struct
    % session           session struct with session-level metadata
    % spikes            spikes struct filtered by manipulation intervals
    % spikes_all        spikes struct with all spikes
    %
    % OUTPUT
    % cell_metrics      updated cell_metrics struct
end
```
