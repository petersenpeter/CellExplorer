---
layout: default
title: Neuropixels
parent: Tutorials
nav_order: 3
---
# Neuropixels tutorial
{: .no_toc}
This tutorial shows how to process a Neuropixels dataset. It is based on the online presentation of CellExplorer at the Neuropixels course in 2022. It includes how to prepare the session metadata, running the cell metrics pipeline, visualizing the cell metrics in CellExplorer, working in batch-mode, and using NeuroScope2 to view the raw data. The tutorial is also available as a Matlab script: (`tutorials/CellExplorer_NeuropixelsTutorial.m`).

### Presentation from the Neuropixels course

Please check out the recorded presentation of [CellExplorer at the Neuropixels course in 2022](https://www.youtube.com/watch?v=ejI5VIz9Yw8). It includes an introduction with slides and a demo in Matlab (11 minutes long).

{% include youtube.html id="ejI5VIz9Yw8" %}

### 1. Generate session metadata struct using the template script and display the metadata in the session gui
For this tutorial, I used a Neuropixels dataset from a pilot study performed on a rat (384 channels, 200GB, ~2.5 hours). 


First we define the basepath of the dataset, and go to that folder in Matlab:
```m
basepath = '/Volumes/Peter_SSD_4/NeuropixelsData/PP02/PP02_2020-07-10';
cd(basepath)
```
The dataset should ideally consist of the raw data `basename.dat`, and spike sorted data. For this session we have a number of files from various sources:

- PP02_2020-07-10.dat       : raw data ([format define here](https://cellexplorer.org/datastructure/data-structure-and-format/#raw-data-file-format))
- rez.mat                   : metadata from KiloSort ([format defined here](https://github.com/MouseLand/Kilosort/wiki/7.-Output-variables))
- PP02_2020-07-10.xml       : metadata from NeuroSuite 
- '*'.npy and '*'.tsv files : Spike data from Phy ([files described here](https://phy.readthedocs.io/en/latest/terminology/))

Using a template script we will generate and import the session-level metadata from these files. It will import metadata from the rez.mat file, from the Neurosuite xml file and the npy files:
```m
session = sessionTemplate(basepath);
```

Next we will use the session-GUI to inspect the generated session struct. You can learn more about the GUI [here](https://cellexplorer.org/interface/gui_session/). The session-GUI is organized in the same way as the underlying session-level metadata struct which is defined [here](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata):
```m
session = gui_session(session);
```

![ProcessCellMetrics_gui](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/gui_session_extracellular.png)

Make sure that the extracellular tab is filled out correctly for your data (see screenshot below). The template script can extracted existing metadata from a Neuroscope compatible `basename.xml`, from Intan's `info.rhd` file, from KiloSort's `rez.mat` file, and from a `basename.sessionInfo.mat` (Buzcode) file.

![ProcessCellMetrics_gui](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/gui_session_general.png)


There is a script you can use to validate required and optional fields for CellExplorer. It will show you a table with the list of parameters and their value in the session-level metadata struct. It cannot validate if the parameters are correctly entered for you specific data, e.g. it cannot validate your channel count or sampling rate, only if the parameters has been set.
```m
validateSessionStruct(session);
```

### 2 Run the cell metrics pipeline 'ProcessCellMetrics' using the session struct as input
Now we can run the processing pipeline. 

```m
cell_metrics = ProcessCellMetrics('session', session,'excludeMetrics',{'monoSynaptic_connections'},'showWaveforms',false,'sessionSummaryFigure',false,'showGUI',true);
```

Setting showGUI to *true* will display the GUI shown below allowing you to validate parameters and settings for `ProcessCellMetrics`. You can click the button __Validate metadata__ to show the validation table with metadata relevant to the processing. Fields requiring your attention will be highlighted in red; optional fields in blue.

![ProcessCellMetrics_gui](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/gui_session_ProcessCellMetrics.png)


Several files are generated here:
- basename.cell_metrics.cellinfo.mat    : cell_metrics
- basename.session.mat                  : session-level metadata
- basename.spikes.cellinfo.mat          : spikes struct

All files and structs are documented here: https://cellexplorer.org/datastructure/data-structure-and-format/

Once created the files can be loaded with dedicated scripts
```m
session = loadSession;           # Loads the session metadata
cell_metrics = loadCellMetrics;  # Loads the cell metrics
spikes = loadSpikes;             # Loads the spikes.
```

The cell metrics follows the definition [here](https://cellexplorer.org/datastructure/standard-cell-metrics/). E. g. the filtered waveforms are stored in the field `cell_metrics.waveforms.filt`, and the firing rates in the field: `cell_metrics.firingRate`.

### 3.1 Visualize the cell metrics in CellExplorer
Finally we can use CellExplorer to visualize the metrics:
```m
cell_metrics = CellExplorer('metrics',cell_metrics);
```

### 3.2 Batch of sessions from Mice and rats (3686 cells from 111 sessions)
The power of CellExplorer really shows when working in a bath mode. Here I am loading a pregenerated batch containing 3686 cells). 

```m
load('/Volumes/Peter_SSD_4/cell_metrics/cell_metrics_peter_viktor.mat');
cell_metrics = CellExplorer('metrics',cell_metrics);
```

### 3.3 Work with several sessions (batch-mode)
To work in batch-mode, you can define the list basepaths and basenames of your sessions, and combine them with a dedicated batch script `loadCellMetricsBatch`, before running CellExplorer
```m
basepaths = {'/your/data/path/basename1/','/your/data/path/basename2/'};
basenames = {'basename1','basename2'};

cell_metrics = loadCellMetricsBatch('basepaths',basepaths,'basenames',basenames);

cell_metrics = CellExplorer('metrics',cell_metrics);
```

### 4.1 NeuroScope2: Two 6-shank silicon probes implanted bilaterally in CA1 (128 channels; 150 cells)
```m
cd('/Volumes/Peter_SSD_4/CellExplorerTutorial/MS22/Peter_MS22_180629_110319_concat');
NeuroScope2
```

### 4.2 NeuroScope2: Inspect a Neuropixels dataset

```m
cd('/Volumes/Peter_SSD_4/NeuropixelsData/PP01/PP01_2020-06-29_13-15-57');
NeuroScope2
```
