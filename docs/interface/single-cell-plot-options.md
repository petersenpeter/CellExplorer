---
layout: default
title: Single cell plot options
parent: Graphical interface
nav_order: 3
---
# Single cell plot options
{: .no_toc}
The single cells can be plotted with various plot options. You can further create [your own custom plots]({{"/interface/custom-single-cell-plots/"|absolute_url}}), which can be loaded and displayed in the Cell Explorer, by saving plot function in the customPlots folder.
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

### Waveforms
There are three types of waveform plots: single waveform with noise curves in absolute amplitude, z-scored waveforms across population, and color plot with same z-scored waveforms. Further there are filtered and unfiltered waveform plot options. 
![Waveforms](https://buzsakilab.com/wp/wp-content/uploads/2020/02/waveforms.png){: .mt-4}

### Autocorrelograms
There are three types of autocorrelograms (ACGs) all normalized to firing rates: single ACG, population plot and a color plot with z-scored ACGs. Further there are three ACG types: [-50ms:0.5ms:50ms], [-500ms:1ms:500ms] and a log10 [1ms:10s]. 
![ACGs linear](https://buzsakilab.com/wp/wp-content/uploads/2020/02/ACGlinear.png){: .mt-4}

![ACGs log](https://buzsakilab.com/wp/wp-content/uploads/2020/02/ACGlog.png){: .mt-4}

### ISI distributions
Three types of log10 ISI distributions: single ISI distribution with the addition from ACG shown in the same plot, all the ISIs for the whole population, and a color plot with z-scored ISIs across the population. The normalization can further be set to three different values: occurrence, rate (normalized by bin size), and instantaneous firing rates (1/ISIs).
![ISI rate](https://buzsakilab.com/wp/wp-content/uploads/2020/02/ISI_rate.png){: .mt-4}

![ISI occurence](https://buzsakilab.com/wp/wp-content/uploads/2020/02/ISI_occurance.png){: .mt-4}

### Firing rate maps
![Firing rate maps](https://buzsakilab.com/wp/wp-content/uploads/2020/02/firingRateMaps.png){: .mt-4}

### Response curves
Response curves are generally 
![ResponseCurves](https://buzsakilab.com/wp/wp-content/uploads/2020/02/responseCurve_theta.png){: .mt-4}

### PSTHs
PSTHs can be shown for either sessionName.*.psth.mat files or for sessionName.*.events.mat. They are standard aligned to the onset of the event, but can also be aligned to the peak, center or offset.
![PSTH](https://buzsakilab.com/wp/wp-content/uploads/2019/12/psth_ripples.png)

### Spike rasters
The raw spiking data can also be loaded. [Click here to learn more about how to generate the spike raster plots]({{"/interface/spike-and-event-data/"|absolute_url}}). Below figures show three raster plot examples 1. Phase vs position, 2. trials vs position and 3. spike ampltude vs time.
![Rasters](https://buzsakilab.com/wp/wp-content/uploads/2019/12/spikeRaster.png)
![Rasters in the Cell Explorer](https://buzsakilab.com/wp/wp-content/uploads/2019/12/spikeRasterCellExplorer.png)


## Group action plots
All plots presented on this page are single cell plots that can be selected for the 3-6 single cell subplots in the Cell Explorer but can also be plotted separately using the group action plots menu. Select a few select and press `space`. Below menu will be shown and you can create various plot combinations from above plot options. 

<img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-dialog.png" width="70%">

### Multiplot options and figure exporting
<img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-multiplot-dialog.png" width="70%">
