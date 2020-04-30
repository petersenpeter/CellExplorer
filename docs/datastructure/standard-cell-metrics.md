---
layout: default
title: Standard cell metrics
parent: Data structure
nav_order: 3
---
# Standard cell metrics
{: .no_toc}
The CellExplorer used a single Matlab struct for handling all cell metrics called `cell_metrics`. The `cell_metrics` struct consists of four types of fields for handling different types of data: double, char cells and structs. Fields must be defined for all cells in the session (1xnCells). Single numeric values are saved to numeric fields with double precision, and character/string fields are saved in char cells. Time series data like waveforms and session parameters are stored in standard struct fields.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


## General metrics
* `general`
  * `basename`
  * `basepath`
  * `clusteringpath`
  * `cellCount`
  * `ccg`
* `processinginfo`. The general fields also contains a list of timestamps for time-series metrics. 
* `brainRegion`: Brain region acronyms from [Allan institute Brain atlas](http://atlas.brain-map.org/atlas?atlas=1).
* `animal`: Unique name of animal.
* `sex`: Sex of the animal [Male, Female, Unknown]
* `species`: Animal species [Rat, Mouse,...]
* `strain`: Animal strain [Long Evans, C57B1/6,...]
* `geneticLine`: Genetic line of the animal
* `spikeGroup`: Spike group: Shank number / spike group. 
* `labels`: Custom labels.

## Spike events based metrics
* `spikeCount`: Spike count of the cell from the entire session.
* `firingRate`: Firing rate in Hz: Spike count normalized by the interval between the first and the last spike.
* `cv2`: [Coefficient of variation](https://www.ncbi.nlm.nih.gov/pubmed/8734581) (CV_2). 
* `burstIndex_Mizuseki2012` Burst index: Fraction of spikes with a neighboring ISI < 6 ms as defined by [Mizuseki et al. Hippocampus 2012](http://www.buzsakilab.com/content/PDFs/Mizuseki2012.pdf).

## ACG & CCG based metrics
* `acg`: autocorrelograms. Three types: 
  * `wide` [-1000 ms : 1 ms: 1000 ms]
  * `narrow` [-50 ms : 0.5 ms : 50 ms] 
  * `log10` [log-intervals spanning 1 ms : 10 s].
* `isi`: interspike intervals
  * `log10` [log-intervals spanning 1 ms : 10 s].
* Autocorrelograms are fitted with a triple-exponential equation:
$$ACG_{fit} = max(c\exp(\frac{-(x-t_{refrac})}{\tau_{decay}})-d\exp(\frac{-(x-t_{refrac})}{\tau_{rise}})+h\exp(\frac{-(x-t_{refrac})}{\tau_{burst}})+rate_{asymptote},0)$$
```m
ACG_fit = 'max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0)'
a = tau_decay, b = tau_rise, c = decay_amplitude, d = rise_amplitude, e = asymptote, f = refrac, g = tau_burst, h = burst_amplitude
 ```
* `acg_tau_rise` ACG tau rise (ms)
* `acg_tau_decay` ACG tau decay (ms)
* `acg_tau_burst` ACG tau bursts (ms)
* `acg_refrac` ACG refractory period (ms)
* `acg_fit_rsquare` ACG fit R-square
* `thetaModulationIndex` is defined by the difference between the theta modulation trough (mean of autocorrelogram bins 50-70 ms) and the theta modulation peak (mean of autocorrelogram bins 100-140ms) over their sum. 
* `synapticEffect`: Synaptic effect
* `burstIndex_Royer2012` Burst index (Royer 2012)
* `burstIndex_Doublets` Burst index doublets.
* `synapticConnectionsIn`:  Synaptic ingoing connections count.
* `synapticConnectionsOut`: Synaptic outgoing connections count.

## Waveform based metrics
* `waveforms`: spike waveform struct with below fields:
  * `filt`: Average filtered spike waveform from channel with max amplitude. High-pass filtered above 500Hz to standardize waveforms.
  * `raw`: Average raw spike waveform from channel with max amplitude. 
  * `time`: Time vector for average raw spike waveform from channel with max amplitude.
* `maxWaveformCh`: Max channel zero-indexed: The channel where the spike has the largest amplitude.
* `maxWaveformCh1`: Max channel one-indexed: The channel where the spike has the largest amplitude.
* `troughToPeak`: Trough-to-peak latency is defined from the trough to the following peak of the waveform. 
* `ab_ratio`: Waveform asymmetry; the ratio between the two positive peaks `(peakB-peakA)/(peakA+peakB)`.
* `peakVoltage`: Peak voltage (µV) Defined from the channel with the maximum waveform (high-pass filtered). `max(waveform)-min(waveform)`.

<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/01/WaveformFeatures.png" width="50%"></p>

## Cell-type classification
* `putativeCellType`: Putative cell types.
  * In the processing pipeline, cells are classified into three putative cell types: **Narrow Interneurons, Wide Interneurons and Pyramidal Cells**.
  * Interneurons are selected by 3 separate criteria:
  1. acg_tau_decay > 30 ms
  2. acg_tau_rise > 3 ms
  3. troughToPeak <= 0.425 ms
  * Next interneurons are separated into two classes
  1. Narrow interneuron assigned if troughToPeak <= 0.425 ms
  2. Wide interneuron assigned if troughToPeak > 0.425 ms
  * Remaining cells are assigned as Pyramidal cells. 

## Monosynaptic connections
* `putativeConnections`: putative connections determined from cross correlograms. Contains two fields: `excitatory` and `inhibitory`, each contains connections pairs. 

## Sorting quality metrics
Isolation distance and L-ratio as defined by [Schmitzer-Torbert et al. Neuroscience. 2005.](https://www.ncbi.nlm.nih.gov/pubmed/15680687)
* `isolationDistance`: Isolation distance.
* `lRatio`: L-ratio.
* `refractoryPeriodViolation`: Refractory period violation (‰): Fraction of ISIs less than 2 ms.

## Sharp wave ripple metrics
* `ripples_modulationIndex`: strength of ripple modulation of the firing rate)
* `ripples_modulationPeakResponseTime`: Ripple peak delay. Calculated from a ripple triggered average. The delay between the ripple peak and the peak response of the ripple triggered average response.
* `deepSuperficial`: Deep-Superficial region assignment [Unknown, Cortical, Superficial, Deep].
* `deepSuperficialDistance`: Deep Superficial depth relative to the reversal of the sharp wave. (in um).

## Theta oscillation metrics
* `thetaPhasePeak`: Theta phase peak
* `thetaPhaseTrough`: Theta phase trough
* `thetaEntrainment`: Theta entrainment
* `thetaModulationIndex`: Theta modulation index. determined from the ACG.

## Firing rate maps
* `firingRateMaps`: (spatial) firing rate maps.

## Spatial metrics
The spatial metrics are all based on average firing rate map.
* `spatialCoverageIndex`: Spatial coverage index. Defined from the inverse cumulative distribution, where bins are sorted by decreasing rate. The 75 percentile point defines the spatial coverage by the fraction of bins below and above the point [(defined by Royer et al., NN 2012)](http://www.buzsakilab.com/content/PDFs/Royer2012.pdf)
* `spatialGiniCoeff`: Spatial Gini coefficient. Defined as the [Gini coefficient](https://en.wikipedia.org/wiki/Gini_coefficient) of the firing rate map.
* `spatialCoherence`: Spatial Coherence. Defined by the degree of correlation between the firing rate map and a hollow convolution with the same map (reference?)
* `spatialPeakRate`: Spatial peak firing rate (Hz). Defined as the peak rate from the firing rate map.
* `placeFieldsCount`: Number of place fields. Defined as the number of intervals along the firing rate map that fulfills a number of spatial criteria: minimum rate of 2Hz and above 10% of the maximum firing rate bin and minimum of 4 connecting bins. The cell further has to have a spatial coherence greater than 0.6 (Mizuseki et al ?).
* `placeCell`: Place cell (binary, determined from the Mizuseki spatial metrics).

## Firing rate stability metrics
* `firingRateGiniCoeff`: The Gini coefficient of the firing rate across time.
* `firingRateStd`: Standard deviation of the "firing rate across time" divided by the mean. 
* `firingRateInstability`: Mean of the absolute differential "firing rate across time" divided by the mean: `abs(diff(firingRateAcrossTime))`.

## Event metrics
* `events`: event time series.

## Manipulation metrics
* `manipulations`: manipulations time series.

## Response curve metrics
* `responseCurves`: response curves.

## Group data
* `groups`: Cell groups. Each cell can be assigned to one or more groups.
* `tags`: Each cell can be assigned to one or more tags.
* `groundTruthClassification`: Opto-tagged/ground truth cell groups. Each cell can be assigned to one or more groups.
