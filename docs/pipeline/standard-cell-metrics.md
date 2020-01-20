---
layout: default
title: Standard cell metrics
parent: Processing pipeline
nav_order: 3
---
# Standard cell metrics
{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

The Cell Explorer used a single Matlab struct for handling all cell metrics called `cell_metrics`. The `cell_metrics` struct consists of four types of fields for handling different types of data: double, char cells and structs. Each field should be defined for all cells in the session (1xnCells). Single numeric values are saved to numeric fields with double precision, and character/string fields are saved in char cells. Time series data like waveforms and session parameters are stored in standard struct fields:
* `general`: `basename`, `basepath`, `clusteringpath`, `cellCount`, `ccg`, `processinginfo`. The general fields also contains a list of timestamps for timeseries metrics. 
* `acg`: autocorrelograms. Three types: 
  * `wide` [-1000ms:1ms:1000ms]
  * `narrow` [-50:0.5:50] 
  * `log10` [log-intervals spanning 1ms:10s].
* `isi`: `log10` [log-intervals spanning 1ms:10s].
* `waveforms`: contains the average waveforms of the cells. 
  * `raw`: raw average waveform. 
  * `filt`: filtered waveforms (highpass filtered above 500Hz).
* `putativeConnections`: putative connections determined from cross correlograms. Contains two fields: `excitatory` and `inhibitory`, each contains connections pairs. 
* `events`: event time series.
* `firingRateMaps`: (spatial) firing rate maps.
* `manipulations`: manipulations time series.
* `responseCurves`: response curves.

## Standard metrics
### General metrics
* `putativeCellType`: Putative cell type
* `brainRegion`: Brain region acronyms from [Allan institute Brain atlas](http://atlas.brain-map.org/atlas?atlas=1).
* `animal`: Unique name of animal.
* `sex`: Sex of the animal [Male, Female, Unknown]
* `species`: Animal species [Rat, Mouse,...]
* `strain`: Animal strain [Long Evans, C57B1/6,...]
* `geneticLine`: Genetic line of the animal
* `spikeGroup`: Spike group: Shank number / spike group. 
* `labels`: Custom labels.

### Spike events based metrics
* `spikeCount`: Spike count of the cell from the entire session.
* `firingRate`: Firing rate in Hz: Spike count normalized by the interval between the first and the last spike.
* `cv2`: [Coefficient of variation](https://www.ncbi.nlm.nih.gov/pubmed/8734581) (CV2). 
* `refractoryPeriodViolation`: Refractory period violation (‰): Fraction of ISIs less than 2ms.
* `burstIndex_Mizuseki2012` Burst index: Fraction of spikes with a neighboring ISI < 6ms as defined in [Mizuseki et al. Hippocampus 2012](http://www.buzsakilab.com/content/PDFs/Mizuseki2012.pdf).

### Waveform based metrics
* `waveforms`: Spike waveform struct with below fields:
  * `filt`: Average filtered spike waveform from channel with max amplitude. Highpass filtered above 500Hz to standardize waveforms.
  * `raw`: Average raw spike waveform from channel with max amplitude. 
  * `time`: Time vector for average raw spike waveform from channel with max amplitude.
* `maxWaveformCh`: Max channel zero-indexed: The channel where the spike has the largest amplitude.
* `maxWaveformCh1`: Max channel one-indexed: The channel where the spike has the largest amplitude.
* `troughToPeak`: Trough-to-peak latency is defined from the trough to the following peak of the waveform. 
* `WaveformAsymmetry`: the ratio between the two positive peaks (peakB-peakA)/(peakA+peakB)
* `peakVoltage`: Peak voltage (µV) Defined from the channel with the maximum waveform (highpass filtered). max(waveform)-min(waveform).

### PCA feature based metrics
Isolation distance and L-ratio as defined by [Schmitzer-Torbert et al. Neuroscience. 2005.](https://www.ncbi.nlm.nih.gov/pubmed/15680687)
* `isolationDistance`: Isolation distance.
* `lRatio`: L-ratio.

### ACG & CCG based metrics
* `Theta modulation index` is defined by the difference between the theta modulation trough (mean of autocorrelogram bins 50-70 ms) and the theta modulation peak (mean of autocorrelogram bins 100-140ms) over their sum. Autocorrelogram fits with time constants are fitted with a double-exponential equation ( `fit = c*exp(-x/τ_decay)-d*exp(-x/τ_rise)` )
* `synapticEffect`: Synaptic effect
* ` ` ACG tau rise (ms)
* ` ` ACG tau decay (ms)
* ` ` ACG tau bursts (ms)
* ` ` ACG refractory period (ms)
* ` ` ACG fit R-square
* ` ` Burst index (Royer 2012)
* ` ` Burst index doublets
* `synapticConnectionsIn`:  Synaptic ingoing connections count
* `synapticConnectionsOut`: Synaptic outgoing connections count

### Sharp wave ripple metrics
* `ripples_modulationIndex`: strength of ripple modulation of the firing rate)
* `ripples_modulationPeakResponseTime`: Ripple peak delay. Calculated from a ripple triggered average. The delay between the ripple peak and the peak response of the ripple triggered average response.
* `deepSuperficial`: Deep-Superficial region assignment [Unknown, Cortical, Superficial, Deep].
* `deepSuperficialDistance`: Deep Superficial depth relative to the reversal of the sharp wave. (in um).

### Theta oscillation metrics
* `thetaPhasePeak`: Theta phase peak
* `thetaPhaseTrough`: Theta phase trough
* `thetaEntrainment`: Theta entrainment
* `thetaModulationIndex`: Theta modulation index. determined from the ACG.

### Spatial metrics
The spatial metrics are all based on average firing rate map.
* `spatialCoverageIndex`: Spatial coverage index. Defined from the inverse cumulative distribution, where bins are sorted by decreasing rate. The 75 percentile point defines the spatial coverage by the fraction of bins below and above the point  [(defined by Royer et al., NN 2012)](http://www.buzsakilab.com/content/PDFs/Royer2012.pdf)
* `spatialGiniCoeff`: Spatial Gini coefficient. Defined as the [Gini coefficient](https://en.wikipedia.org/wiki/Gini_coefficient) of the firing rate map.
* `spatialCoherence`: Spatial Coherence. Defined by the degree of correlation between the firing rate map and a hollow convolution with the same map (reference?)
* `spatialPeakRate`: Spatial peak firing rate (Hz). Defined as the peak rate from the firing rate map.
* `placeFieldsCount`: Number of place fields. Defined as the number of intervals along the firing rate map that fulfills a number of spatial criteria: minimum rate of 2Hz and above 10% of the maximum firing rate bin and minimum of 4 connecting bins. The cell further has to have a spatial coherence greater than 0.6 (Mizuseki et al ?).
* `placeCell`: Place cell (binary, determined from the Mizuseki spatial metrics).

### Firing rate stability metrics
* `firingRateGiniCoeff` : The Gini coefficient of the firing rate across time.
* `firingRateStd` : Standard deviation of the "firing rate across time" divided by the mean. 
* `firingRateInstability` : Mean of the absolute differential "firing rate across time" divided by the mean. abs(diff(firingRateAcrossTime))

