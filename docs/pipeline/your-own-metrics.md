---
layout: default
title: Adding your own metrics
parent: Pipeline
nav_order: 5
---
# Adding your own metrics
{: .no_toc}
### Adding your own numeric or string metrics
You can add your own metrics either as numeric values or string arrays. String arrays allow you to group your data by the unique strings set within features, and can be plotted in discrete values. All features in the cell metrics are automatically available in the cell inspector if they contain N values (N: number of cells).

### Adding your own custom plot (e.g. spike triggered average response)
response curves, event histograms, firing rate maps, manipulations and other plots should be saved into predefined subfields. To categorize, a few field names (plot types) are available:
1. responseCurves (e.g. thetaPhase)
2. events (any sessionName.*.events.mat file in the basepath will create an event response curve aligned at event start).
3. manipulations (any sessionName.*.manipulation.mat file in the basepath will create an event response curve per cell aligned at event start).
4. states 
5. firingRateMaps (any sessionName.firingRateMaps.cellinfo.mat file in the basepath will create a firing rate map per cell).
6. psth

This schema allows you to easily add a PSTH or a histogram to better characterize your cells.

The x-axis (the x-bins) can be specified by including a vector with M values in a subfield named after the metric in the structure cell_metrics.general.plotType.plotName.x_bins. State labels (state_label) and axis labels (x_label, y_label) can also be defined in this general field. See the Test dataset for how to format this correctly.

### Spike data
The cell explorer is also capable of loading the raw spike data from a sessionName.spikes.cellInfo.mat file. This is useful for when you want to create a raster psth, see the spike times across trials or time, or plot a phase precession map. [Use the spikes menu in the Cell Explorer](/interface/spike-and-event-data/), and if the current selected cell has spiking data in the data folder, the Cell explorer will load the data and show you plotting options. After this initial step the spikes plotting options will appear with the other cell-specific plotting options in the 6 dropdowns in the Display Settings panel.
