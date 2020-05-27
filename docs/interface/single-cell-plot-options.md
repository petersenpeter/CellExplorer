---
layout: default
title: Single cell plot options
parent: Graphical interface
nav_order: 3
---
# Single cell plot options
{: .no_toc}
The single cells can be plotted with various plot options. You can further create [your own custom plots]({{"/interface/custom-single-cell-plots/"|absolute_url}}), which can be loaded and displayed in CellExplorer, by saving plot function in the customPlots folder. Most data has three plotting styles: single cell, population and a normalized image.
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
Response curves includes firing rate across time, phase distribution. There are three plotting styles: 
1. Single response curve with monosynaptic cells' response curves. 
2. Population response curves.
3. Image with normalized response curves.
![ResponseCurves](https://buzsakilab.com/wp/wp-content/uploads/2020/02/responseCurve_theta.png){: .mt-4}

### PSTHs
PSTHs can be shown for either sessionName.*.psth.mat files or for sessionName.*.events.mat. They are by default aligned to the onset of the event, but can also be aligned to the peak, center or offset. 
<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/psth_ripples.png" width="60%"></p>{: .mt-4}

### Spike rasters
The spiking data can also be loaded to generate raster plots using spike data. Please see the [tutorial on spike data]({{"/tutorials/plotting-spike-data/"|absolute_url}}) to learn more. The figure below shows two raster plot examples for a pyramidal cell in CA1: 1. Theta phase vs position (the animal runs along a track), 2. Trial vs position, colored according to 3 states.
![Rasters](https://buzsakilab.com/wp/wp-content/uploads/2020/03/rasters_placefield-04.png){: .mt-4}

### Waveforms across channels
Average waveform across all channels.

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/04/waveformsAcrossChannels-01.png" width="70%"></p>{: .mt-4}

## Trilaterated position
A trilaterated estimated position for all cells determined from the amplitudes of their average waveforms across channels. The squares indicate electrode sites.

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/04/trilat-01.png" width="60%"></p>{: .mt-4}

## Connectivity graphs
The connectivity graphs shows all connections detected in a dataset. Selected cell is highlighted together with its synaptic partners. You can select and highlight cells from the plot.

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/04/connectivityGraph-01.png" width="60%"></p>{: .mt-4}

## Custom plots
You can create your own custom plots to display in CellExplorer that also becomes interactive. Image below shows a ripple triggered average across an electrode with the current selected cell highlighted. 

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/04/sharpwave.png" width="60%"></p>{: .mt-4}

## Group action plots
All plots presented on this page are single cell plots that can be selected for the 3-6 single cell subplots in CellExplorer but can also be plotted separately using the group actions menu. Select a few select cells and press `space`. Below menu will be shown and you can create various plot combinations from above plot options. 

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-dialog.png" width="60%"></p>

### Multi plot options and figure exporting
Please see the [tutorial on  exporting figures]({{"/tutorials/export-figure/"|absolute_url}}). 

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-multiplot-dialog.png" width="70%"></p>
