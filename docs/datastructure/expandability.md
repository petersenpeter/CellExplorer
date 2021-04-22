---
layout: default
title: Expandability
parent: Data structure
nav_order: 6
---

# Expandability
Add your own metrics, groups, plots and opto-tagging
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

### Your own numeric or string metrics
You can add your own metrics either as numeric values or string arrays. String arrays allow you to group your data by the unique strings set within features, and can be plotted in discrete values. All features in the cell metrics are automatically available in CellExplorer if they contain N values (N: number of cells). Make sure to not use a [fieldname already in use](https://cellexplorer.org/datastructure/standard-cell-metrics/).

__Add a string metrics to your cell_metrics.__
Let's say you want to add a cell metric describing cortical layers for each cell, using predefined labels (Layer 1 to Layer 6). This can be stored as a char cell array, e.g.:
```m
cell_metrics.corticalLayer = {'layer 5','layer 4','layer 2','layer 2/3','layer 1'}; % For nCells = 5
```

__Add numeric values to your cell metrics.__
Let's say you want to add the preferred orientation of [a drifting grating presented to cells in the visual cortex](https://allensdk.readthedocs.io/en/latest/visual_coding_neuropixels.html#precomputed-stimulus-metrics). This will be stored as numeric values, e.g.:
```m
cell_metrics.pref_ori_dg = [90,25,45,80,30]; % For nCells = 5
```

If you open multiple sessions in CellExplorer, the custom metrics will automatically be imported. Cells without numeric values will have NaN values assigned and empty strings for missing char fields. The fields will appear in the drop-down menus in the custom group plot.

You can incorporate calculations/import of metrics into the `ProcessCellMetrics` script by using the [custom calculation implementation](https://cellexplorer.org/pipeline/custom-calculations/).

### Custom plot (e.g. spike triggered average response)
Response curves, event histograms, firing rate maps, manipulations, and other plots should be saved into predefined subfields. To categorize, a few field names (plot types) are available:
1. responseCurves (e.g. thetaPhase)  
2. events (any ´sessionName.*.events.mat´ file in the basepath will create an event response curve aligned at event start).
3. manipulations (any ´sessionName.*.manipulation.mat´ file in the basepath will create an event response curve per cell aligned at event start).
4. states 
5. firingRateMaps (any ´sessionName.firingRateMaps.cellinfo.mat´ file in the basepath will create a firing rate map per cell).
6. psth

This schema allows you to easily add a PSTH or a histogram to better characterize your cells.

The x-axis (the x-bins) can be specified by including a vector with M values in a subfield named after the metric in the structure `cell_metrics.general.plotType.plotName.x_bins`. State labels ´state_label´ and axis labels: ´x_label´ and ´y_label´, can also be defined in the ´general´ field. See the [example dataset](https://github.com/petersenpeter/CellExplorer/tree/master/exampleData) for how to format this properly.

### Spike data
CellExplorer is also capable of loading raw spike data from a ´sessionName.spikes.cellInfo.mat´ file. This is useful for creating a raster PSTH, see the spike times across trials or time, or plot a phase precession map. [Use the spikes menu in CellExplorer]({{"/interface/spike-and-event-data/"|absolute_url}}), and if the current selected cell has spiking data in the data folder, CellExplorer will load the data and show you plotting options. After this initial step the spikes plotting options will appear with the other cell-specific plotting options in the 6 drop-downs in the Display Settings panel. Please see the [tutorial on spike raster plots]({{"/tutorials/plotting-spike-data/"|absolute_url}}) for more information.

### Opto-tagging
Incorporate opto-tagged data into CellExplorer. Please see the [tutorial opto-tagged data]({{"/tutorials/optotagging-tutorial/"|absolute_url}}) for more information.
