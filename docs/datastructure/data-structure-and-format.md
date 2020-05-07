---
layout: default
title: Data structure and format
parent: Data structure
nav_order: 2
---
# Data structure and format
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Data paths
For each session there are two main paths that the CellExplorer uses, a basepath and a clusteringpath (relative to basepath). 

The basepath contains the raw data and session level files. The data in the basepath should follow this naming convention: `sessionName.*`, e.g. `sessionName.dat` and `sessionName.lfp` (low-pass filtered and down-sampled. The lfp file is automatically generated in the pipeline if necessary). The clusteringpath contains the spike data, including cell metrics, and can be the same as the basepath (empty clusteringpath field).

## Data structures
Each type of data is saved in its own MATLAB structure, where a subset of the structures are inherited from [buzcode](https://github.com/buzsakilab/buzcode). Please see the list of data containers in the next section. 

### Cell metrics
The cell metrics are kept in a `cell_metrics` struct as [described here]({{"/datastructure/standard-cell-metrics/"|absolute_url}}). The cell metrics are stored in: `sessionName.cell_metrics.cellinfo.mat` in the clustering path.

### Session metadata
A MATLAB struct `session` stored in a .mat file: `sessionName.session.mat`. The session struct contains all session-level metadata. The session struct can be generated using the [sessionTemplate.m](https://github.com/petersenpeter/CellExplorer/blob/master/calc_CellMetrics/sessionTemplate.m) and inspected with [gui_session.m](https://github.com/petersenpeter/CellExplorer/blob/master/calc_CellMetrics/gui_session.m). The `sessionName.session.mat` files should be stored in the basepath. It is structured as defined below:

* `general`
  * `name` : name of session
  * `investigator` : investigator of the session
  * `projects` : projects the session belong to
  * `date` : date the session was recorded
  * `time` : start time of the session
  * `location` : location where the session took place
  * `experimenters` : who performed the experiments
  * `duration` : the total duration of the session (seconds)
  * `sessionType` : type of session (chronic/acute)
  * `notes` : any notes
* `animal`
  * `name` : name of animal
  * `sex` : sex of animal
  * `species` : species of animal
  * `strain` : strain of animal
  * `geneticLine` : genetic line of animal
* `epochs`
  * `name`
  * `behavioralParadigm`
  * `builtMaze`
  * `mazeType`
  * `manipulations`
  * `startTime`
  * `stopTime`
* `extracellular`
  * `equipment` : hardware used to acquire the data
  * `fileFormat` : format of the raw data
  * `sr` : sampling rate
  * `nChannels` : number of channels
  * `nSamples` : number of samples
  * `nElectrodeGroups` : number of electrode groups
  * `electrodeGroups` (struct) : struct with definition of electrode groups (1-indexed)
  * `nSpikeGroups` : number of spike groups
  * `spikeGroups` (struct) : struct with definition of spike groups (1-indexed)
  * `precision` : e.g. signed int16.
  * `leastSignificantBit` : range/precision in µV. Intan system: 0.195µV/bit
  * `srLFP` : sampling rate of the LFP file
  * `electrode` : struct with implanted electrodes
    * `siliconProbes` : name of the probe
    * `company` : company producing the probe
    * `nChannels` : number of channels
    * `nShanks` : number of shanks
    * `AP_coordinates` : Anterior-Posterior coordinates(mm)
    * `ML_coordinates` : Medial-Lateral coordinates (mm)
    * `depth` : implant depth (mm)
    * `brainRegions` : implant brain region acronym (Allen institute Atlas)
* `brainRegions`
  * `regionAcronym` : e.g. CA1 or HIP, Allen institute Atlas
    * `brainRegion` 
    * `channels` : list of channels
    * `electrodeGroups` : list of electrode groups
* `channelTags`
  * `tagName` (e.g. Theta, Cortical, Ripple, Bad)
    * `channels` : list of channels (1-indexed)
    * `electrodeGroups` : list of electrode groups (1-indexed)
* `behavioralTracking`
  * `equipment` : hardware used to acquire the data
  * `filenames` : file names containing the tracking
  * `framerate` : frame rate of the tracking
  * `notes`
* `inputs`
  * `inputTag` : unique name, e.g. temperature, stimPulses, OptitrackTTL
    * `equipment` : hardware used to acquire the data
    * `inputType` : adc, aux, dat, dig ...
    * `channels` : list of channels (1-indexed)
    * `description`
* `analysisTags`
  * `tagName`: the numeric or string values saved in the tag
* `spikeSorting`
  * `method` : e.g. KiloSort
  * `format` : Phy, KiloSort, KlustaViewer, Klustakwik, ...
  * `relativePath` : relative to base/sessionpath
  * `channels` : list of channels selected.
  * `spikeSorter` : Person performed the manual spike sorting
  * `notes`
  * `cellMetrics` : (boolean) if the cell metrics has been run
  * `manuallyCurated` : (boolean) if manual curation has been performed
* `timeseries`
  * `typeTag` : unique type (adc, aux, dat, dig ...)
    * `fileName` : file name
    * `precision` : e.g. int16
    * `nChannels` : number of channels
    * `sr` : sampling rate
    * `nSamples` : number of samples
    * `leastSignificantBit` : range/precision in µV. [Intan system](http://intantech.com/): 0.195µV/bit
    * `equipment` : hardware used to acquire the data

### Spikes
A MATLAB struct `spikes` stored in a .mat file: `sessionName.spikes.cellinfo.mat`. It can be generated with [loadSpikes.m](https://github.com/petersenpeter/CellExplorer/blob/master/calc_CellMetrics/loadSpikes.m). The Cell Inspector's pipeline `ProcessCellMetrics.m` used the script `loadSpikes.m`, to automatically load spike-data from either KiloSort, Phy or Neurosuite and saves it to a spikes struct. `sessionName.spikes.cellinfo.mat` should be located in the clustering path. The struct has the following fields:
* `ts`: a 1xN cell-struct for N units each containing a 1xM vector with M spike events in samples.
* `times`: a 1xN cell-struct for N units each containing a 1xM vector with M spike events in seconds.
* `cluID`: a 1xN vector with inherited IDs from the applied clustering algorithm.
* `UID`: a 1xN vector with values 1:N.
* `shankID`: a 1xN vector containing the corresponding shank/electrode-group each unit (1-indexed).
* `maxWaveformCh`: a 1xN vector with the channel for the maximum waveform for the units (0-indexed) 
* `maxWaveformCh1`: a 1xN vector with the channel for the maximum waveform for the units (1-indexed) 
* `total`: a 1xN vector with the total number of spikes for each unit.
* `peakVoltage`: a 1xN vector with spike waveform amplitude (µV).
* `filtWaveform`: a 1xN cell-struct with spike waveforms from maxWaveformChannel (µV).
* `filtWaveform_std`: a 1xN cell-struct with the std of the spike waveforms (µV).
* `rawWaveform`: a 1xN cell-struct with raw spike waveforms (µV).
* `rawWaveform_std`: a 1xN cell-struct with std of the raw spike waveforms (µV).
* `timeWaveform`: a 1xN cell-struct with spike timestamps for the waveforms (ms).
* `numcells`: number of cells.
* `sessionName`: name of the session (string).
* `spindices`: a Kx2 matrix where the first column contains the K spike times for all units and the second column contains the unit index for each spike. 
* `processinginfo`: a substruct with information about how the spikes was generated including the name of the function, version, date and the parameters.

Any extra field can be added with info about the units, e.g. the theta phase of each spike for the units, or the position/speed of the animal for each spike.

### Firing rate maps
This is a data container for firing rate map data. A MATLAB struct `ratemap` containing 1D or linearized firing rat maps, stored in a .mat file: `sessionName.ratemap.firingRateMap.mat`. The firing rate maps should be stored in the clusteringpath and has the following fields:
* `map`: a 1xN cell-struct for N units each containing a KxL matrix, where K corresponds to the bin count and L to the number of states. States can be trials, manipulation states, left-right states, etc.
* `x_bins`: a 1xK vector with K bin values used to generate the firing rate map.
* `state_labels`: a 1xL vector with char labels describing the states.

### Events
This is a data container for event data. A MATLAB struct `eventName` stored in a .mat file: `sessionName.eventName.events.mat` with the following fields:
* `timestamps`: Px2 matrix with intervals for the P events in seconds.
* `peaks`: Event time for the peak of each events in seconds (Px1).
* `amplitude`: amplitude of each event (Px1).
* `amplitudeUnits`: specify the units of the amplitude vector.
* `eventID`: numeric ID for classifying various event types  (Px1).
* `eventIDlabels`: cell array with labels for classifying various event types defined in stimID (cell array, Px1).
* `eventIDbinary`: boolean specifying if eventID should be read as binary values (default: false).
* `center`: center time-point of event (in seconds; calculated from timestamps; Px1).
* `duration`: duration of event (in seconds; calculated from timestamps; Px1).
* `detectorinfo`: info about how the events were detected.

The `*.events.mat` files should be stored in the basepath. Any `events` files located in the basepath will be detected in the pipeline `ProcessCellMetrics.m` and an average PSTHs will be generated.

### Manipulations
This is a data container for manipulation data. A MATLAB struct `manipulationName` stored in a .mat file: `sessionName.eventName.manipulation.mat` with the following fields:
* `timestamps`: Px2 matrix with intervals for the P events in seconds.
* `peaks`: Event time for the peak of each events in seconds (Px1).
* `amplitude`: amplitude of each event (Px1).
* `amplitudeUnits`: specify the units of the amplitude vector.
* `eventID`: numeric ID for classifying various event types  (Px1).
* `eventIDlabels`: cell array with labels for classifying various event types defined in stimID (cell array, Px1).
* `eventIDbinary`: boolean specifying if eventID should be read as binary values (default: false).
* `center`: center time-point of event (in seconds; calculated from timestamps; Px1).
* `duration`: duration of event (in seconds; calculated from timestamps; Px1).
* `detectorinfo`: info about how the events were detected.

The `*.manipulation.mat` files should be stored in the basepath. `events` and `manipulation` files are similar in content, but only manipulation intervals are excluded in the pipeline. Any `manipulation` files located in the basepath will be detected in the pipeline (ProcessCellMetrics.m) and an average PSTH will be generated. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline.

### Channels
This is a data container for channel-wise data. A MATLAB struct `ChannelName` stored in a .mat file: `sessionName.ChannelName.channelinfo.mat` with the following fields:
* `channel`: a 1xQ vector containing a list of Q channel indexes (0-indexed).
* `channelClass`: a 1xQ cell with classification assigned to each channel (char).
* `processinginfo`: a struct with information about how the mat file was generated including the name of the function, version, date and parameters.
* `detectorinfo`: If the channelinfo struct is based on determined events, detectorinfo contains info about how the event was processed.

The `*.channelinfo.mat` files should be stored in the basepath.

### Time series
This is a data container for other time series data (check other containers for specific formats like intracellular). A MATLAB struct `timeserieName` stored in a .mat file: `sessionName.timeserieName.timeSeries.mat` with the following fields:
* `data` : a [nSamples x nChannels] vector with time series data.
* `timestamps` : a [nSamples x 1] vector with timestamps.
* `precision` : e.g. int16.
* `units` : e.g. mV.
* `nChannels` : number of channels.
* `channelNames` : struct with names of channels.
* `sr` : sampling rate.
* `nSamples` : number of samples.
* `leastSignificantBit` : range/precision in µV. [Intan system](http://intantech.com/): 0.195µV/bit.
* `equipment` : hardware used to acquire the data.
* `notes` : Human-readable notes about this time series data.
* `description` : Description of this time series data.
* `processinginfo` : a struct with information about how the .mat file was generated including the name of the function, version, date, source file, and parameters.
  * `sourceFileName` : file name.

Any other field can be added to the struct containing time series data. The `*.timeseries.mat` files should be stored in the basepath.

### States (being implemented)
This is a data container for brain states data. A MATLAB struct `states` stored in a .mat file: `sessionName.statesName.states.mat`. States can contain multiple temporal states defined by intervals, .e.g sleep/wake-states (awake/nonREM and/REM) and cortical states (Up/Down). It has the following fields:
* `ints`: a struct containing intervals (start and stop times) for each state (required).
  * `.stateName`: start/stop time for each instance of state stateName (required).
* `processinginfo`: a struct with information about how the .mat file was generated including the name of the function, version, date and parameters.
* `detectorinfo`: a struct with information about how the states were detected.

_Optional fields_
* `idx`: a struct containing timestamps for each state.
  * `.states`: a [t x 1] vector giving the state at each point in time (t: number of timestamps).
  * `.timestamps`: a [t x 1] vector with timestamps.
  * `.statenames`: {Nstates} cell array for the name of each state.
Any other field can be added to the struct containing states data. The `*.states.mat` files should be stored in the basepath.

### Behavior (being implemented)
This is a data container for behavioral tracking data. A MATLAB struct `behaviorName` stored in a .mat file: `sessionName.behaviorName.behavior.mat` with the following fields:
* `timestamps`:  array of timestamps that match the data subfields (in seconds).
* `sr`: sampling rate (Hz).
* SpatialSeries: several options as defined below, each with optional subfields:
  * `units`: defines the units of the data.
  * `resolution`: The smallest meaningful difference (in specified unit) between values in data.
  * `referenceFrame`: description defining what the zero-position is.
  * `coordinateSystem`: position: cartesian[default] or polar. orientation: euler or quaternion[default].
* `position`: spatial position defined by: x, x/y or x/y/z axis default units: meters).
* `speed`: a 1D representation of the running speed (cm/s).
* `orientation`: .x, .y, .z, and .w (default units: radians)
* `pupil`: pupil-tracking data: .x, .y, .diameter.
* `linearized`: a projection of spatial parameters into a 1 dimensional representation:
  * `position`: a 1D linearized version of the position data. 
  * `speed`: behavioral speed of the linearized behavior. 
  * `acceleration`: behavioral acceleration of the linearized behavior.
* `events`: behaviorally derived events, .e.g. as an animal passed a specific position or consumes reward. 
* `epochs`: behaviorally derived epochs.
* `trials`: behavioral trials defined as intervals or continuous vector with numeric trial numbers.
* `states`: e.g. spatially defined regions like central arm or waiting area in a maze. Can be binary or numeric.
* `stateNames`: names of the states.
* `timeSeries`: can contain any derived time traces projected into the behavioral timestamps e.g. temperature, oscillation frequency, power etc.
* `notes`: Human-readable notes about this TimeSeries dataset.
* `description`: Description of this TimeSeries dataset.
* `processinginfo`: a struct with information about how the .mat file was generated including.
  * `name` of the function, `version`, `date`, `parameters`.

Any other field can be added to the struct containing behavior data. The `*.behavior.mat` files should be stored in the basepath.

### Trials (being implemented)
A MATLAB struct `trials` stored in a .mat file: `sessionName.trials.behavior.mat`. The trials struct is a special behavior struct centered around behavioral trials. `trials` has the following fields:
* `start`: trial start times in seconds.
* `end`: trial end times in seconds.
* `nTrials`: number of trials.
* `states`: e.g. spatially defined regions like central arm or waiting area in a maze, stimulation trials, error trials. Must be binary or numeric.
* `stateNames`: names of the states.
* `timeSeries`: can contain any derived time traces averaged onto trial e.g. temperature. Use nan values for undefined trials.
* `processinginfo`: a struct with information about how the .mat file was generated including the name of the function, version, date and parameters.

Any other field can be added to the struct containing trial-specified data. The `trials.behavior.mat` files should be stored in the basepath. Trialwise data should live in this container, while trial-intervals can be stored in other behavior structs.

### Intracellular time series (being implemented)
This is a data container for intracellular recordings. Any MATLAB struct `intracellularName` containing intracellular data would be stored in a .mat file: `sessionName.intracellularName.intracellular.mat`. It contains fields inherited from timeSeries with the following fields:
* `data` : a [nSamples x nChannels] vector with time series data.
* `timestamps` : a [nSamples x 1] vector with timestamps.
* `precision` : e.g. int16.
* `units` : e.g. mV.
* `nChannels` : number of channels.
* `channelNames` : struct with names of channels.
* `sr` : sampling rate.
* `nSamples` : number of samples.
* `leastSignificantBit` : range/precision in µV. [Intan system](http://intantech.com/): 0.195µV/bit.
* `equipment` : hardware used to acquire the data.
* `notes` : Human-readable notes about this time series data.
* `description` : Description of this time series data.
* `intracellular` : __Intracellular specific fields__
  * `clamping` : clamping method: `current`,`voltage`.
  * `type` : recording type (`Patch` or `Sharp`).
  * `solution` : Glass pipette solution (string describing the solution).
  * `bridgeBalance` : bridge balance (M ohm).
  * `seriesResistance` : series resistance (M ohm).
  * `inputResistance` : input resistance (M ohm).
  * `membraneCaparitance` : Description of this time series data.
  * `electrodeMaterial` : `glass`,`tungsten`, etc.
  * `groundElectrode` : description of ground electrode.
  * `referenceElectrode` : description of reference electrode.
* `processinginfo` : a struct with information about how the .mat file was generated including:
  * `function` : which function was used to generate the struct.
  * `version` : version of function if any.
  * `date` : date of processing.
  * `parameters` : input parameters when the struct was created.
  * `sourceFileName` : file name of the original source file.
Any other field can be added to the struct containing intracellular time series data. The `*.intracellular.mat` files should be stored in the basepath.

## Data containers
The data is organized into data-type specific containers, a concept introduced by [buzcode](https://github.com/buzsakilab/buzcode):

* `sessionName.session.mat`: session level metadata.
* `sessionName.*.lfp.mat`: derived ephys signals including theta-band filtered lfp.
* `sessionName.*.cellinfo.mat`: Spike derived data including`spikes`, `cell_metrics`, `mono_res`
* `sessionName.*.firingRateMap.mat`: firing rate maps. Derived from behavior and spikes, e.g. `ratemap`.
* `sessionName.*.events.mat`: events data, including `ripples`, `SWR`,
* `sessionName.*.manipulation.mat`: manipulation data: 
* `sessionName.*.channelinfo.mat`: channel-wise data, including impedance
* `sessionName.*.timeseries.mat`: 
* `sessionName.*.behavior.mat`: behavior data, including position tracking.
* `sessionName.*.states.mat`: brain states derived data including SWS/REM/awake and up/down states.
* `sessionName.*.intracellular.mat`: intracellular data.

