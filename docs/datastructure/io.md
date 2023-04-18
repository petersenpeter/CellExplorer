---
layout: default
title: IO
parent: Data structure
nav_order: 2
---
# Data loaders
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

Below sections describes the various scripts for loading varius data types supported by CellExplorer.

## Raw data
`basename.dat` (CellExplorer also supports other data types, but deviations from this data standard must be defined in the session struct. In general, to read the raw data the following fields must be defined in the session struct (example values filled in):
```m
session.general.name = 'name_of_session; % Name of session
session.extracellular.fileName = 'rawdata.bin'; % Optional if the file name deviates from the standard 
session.extracellular.sr = 30000; % Sampling rate
session.extracellular.nChannels = 384; % Number of channels
session.extracellular.precision = 'int16'; % Numeric data type.
session.extracellular.leastSignificantBit = 0.195; % Least significant bit - precision of the digitization (µV/bit)
```

Please see the [Data structure and format page](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) for further details on the session struct.

```m
data = loadBinaryData('session',session); 
```

__Examples of using loadBinaryData__

```m
session = loadSession; % Loading a predefined session struct

%% Getting an interval from 100sec to 300sec for channel 2
start = 100;
duration = 200; % Duration of traces to;
channels = 2; % channels to load;
data_out = loadBinaryData('session',session,'channels',channels,'start',start,'duration',duration);
traces = session.extracellular.leastSignificantBit * double(data_out);

% Plotting the secod channel of the first interval
figure, plot(traces)

%% Getting an interval from 100 sec to 300 sec using a memmap
data_out = loadBinaryData('session',session,'memmap',true);

start = [100]; % A vector of start intervals
duration = 200; % Duration of traces to
startIndicies2 = start*session.extracellular.sr*session.extracellular.nChannels+1;
stopIndicies2 = (start+duration)*session.extracellular.sr*session.extracellular.nChannels;
X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
traces = session.extracellular.leastSignificantBit * permute(reshape(double(data_out.Data(X2(1:end-1))),session.extracellular.nChannels,duration*session.extracellular.sr,[]),[2,1,3]);
clear data_out

% Plotting the second channel of the first interval
figure, plot(traces(:,2))
```

## LFP data
`basename.lfp`: A low-pass filtered and down-sampled raw data file for lfp analysis (for efficient data analysis and data storage; typically down-sampled to 1250Hz). The lfp file can be generated from the binary data with the script `ce_LFPfromDat`). The sampling rate is specified in the session struct (session.extracellular.srLfp). The LFP file must have the same channel count and scaling as the dat file.

data = LoadBinary
session.extracellular.srLfp= 2500;

## General functions

```m
loadStruct

saveStruct
saveStruct(chanCoords,'channelInfo','session',session);
```

## Session metadata
sessionTemplate
loadSession
gui_session

The session struct can be generated using the script `sessionTemplate.m` and inspected with `gui_session.m`. The `basename.session.mat` files should be stored in the basepath. It is structured as defined below:

## Spikes
A MATLAB struct spikes stored in a .mat file: `basename.spikes.cellinfo.mat`. It can be generated with `loadSpikes.m` to automatically load spike-data from many spike sorting formats including KiloSort, Phy, and Neurosuite and saves it to a spikes struct. `basename.spikes.cellinfo.mat` is saved to the basepath. The struct has the following fields:

```m
loadSpikes.m
spikes = loadSpikes('session',session);
spikes = getWaveformsFromDat(spikes,session);

Load spikes takes spike sorted formats from various algorithms:
```

## Monosynaptic connections
`basename.mono_res.cellinfo.mat`
```m
mono_res = ce_MonoSynConvClick(spikes,'includeInhibitoryConnections',true/false); % detects the monosynaptic connections

gui_MonoSyn(mono_res) % Shows the GUI for manual curation
```

## Cell metrics
loadCellMetrics

```m
basepaths = {'sessionName1','sessionName2','sessionName3'};
cell_metrics = loadCellMetricsBatch('basepaths',bsasepaths);

nwb = saveCellMetrics2nwb(cell_metrics,nwb_file);

saveCellMetrics(cell_metrics,nwb_file)

cell_metrics = ProcessCellMetrics('session', session);
```

## Events
This is a data container for event data. A MATLAB struct eventName stored in a .mat file: `basename.eventName.events.mat` with the following fields:

loadEvents

## Manipulations


## Channels

## Time series

StateExplorer

## States

## Behavior
This is a data container for behavioral tracking data. A MATLAB struct behaviorName stored in a .mat file: `basename.behaviorName.behavior.mat` with the following fields:

__Loading behavior data from an Optitrack csv file:__

```m
scaling_factor = 1;
offset = [0,0,0];
linear_track = loadOptitrack('session',session,'dataName','linear_track','offset',offset,'scaling_factor',scaling_factor);
```

## Firing rate maps
This is a data container for firing rate map data. A MATLAB struct ratemap containing 1D or linearized firing rat maps, stored in a .mat file: `basename.ratemap.firingRateMap.mat`. The firing rate maps have the following fields:

## Intracellular time series
This is a data container for intracellular recordings. Any MATLAB struct intracellularName containing intracellular data would be stored in a .mat file: `basename.intracellularName.intracellular.mat`. It contains fields inherited from timeSeries with the following fields


# Recording systems

## Open Ephys IO

```m
session = detectOpenEphysData('session',session);

session = loadOpenEphysSettingsFile(session);
TTL_paths = {'TTL_2','TTL_4'};
TTL_offsets = [0,0];
openephysDig = loadOpenEphysDigital(session,TTL_paths,TTL_offsets);

openephysDig = loadStruct('openephysDig','digitalseries','session',session);
```

## Intan IO

### Analog traces (timeseries)

loadIntanAnalog

### Digital data (digitalseries)

loadIntanDigital
