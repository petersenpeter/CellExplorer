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
You can add your own metrics either as numeric values or string arrays. String arrays allow you to group your data by the unique strings set within features, and can be plotted in discrete values. All features in the cell metrics are automatically available in the cell inspector if they contain N values (N: number of cells).

### Use the data containers
The cell mentrics processing script `ProcessCellMetrics` will automatically detect container files: `*.events.mat`, `*.manipulation.mat`, `*.cellinfo.mat`

### Custom plot (e.g. spike triggered average response)
Response curves, event histograms, firing rate maps, manipulations and other plots should be saved into predefined subfields. To categorize, a few field names (plot types) are available:
1. responseCurves (e.g. thetaPhase)
2. events (any ´sessionName.*.events.mat´ file in the basepath will create an event response curve aligned at event start).
3. manipulations (any ´sessionName.*.manipulation.mat´ file in the basepath will create an event response curve per cell aligned at event start).
4. states 
5. firingRateMaps (any ´sessionName.firingRateMaps.cellinfo.mat´ file in the basepath will create a firing rate map per cell).
6. psth

This schema allows you to easily add a PSTH or a histogram to better characterize your cells.

The x-axis (the x-bins) can be specified by including a vector with M values in a subfield named after the metric in the structure `cell_metrics.general.plotType.plotName.x_bins`. State labels ´state_label´ and axis labels: ´x_label´ and ´y_label´, can also be defined in the ´general´ field. See the [example dataset](https://github.com/petersenpeter/CellExplorer/tree/master/exampleData) for how to format this properly.

### Spike data
CellExplorer is also capable of loading raw spike data from a ´sessionName.spikes.cellInfo.mat´ file. This is useful for creating a raster PSTH, see the spike times across trials or time, or plot a phase precession map. [Use the spikes menu in the CellExplorer]({{"/interface/spike-and-event-data/"|absolute_url}}), and if the current selected cell has spiking data in the data folder, the CellExplorer will load the data and show you plotting options. After this initial step the spikes plotting options will appear with the other cell-specific plotting options in the 6 drop-downs in the Display Settings panel. Please see the [tutorial on spike raster plots]({{"/tutorials/plotting-spike-data/"|absolute_url}}) for more information.

### Opto-tagging
Incorporate opto-tagged data into the CellExplorer. Please see the [tutorial opto-tagged data]({{"/tutorials/optotagging-tutorial/"|absolute_url}}) for more information.
