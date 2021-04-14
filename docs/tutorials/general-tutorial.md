---
layout: default
title: General tutorial
parent: Tutorials
nav_order: 1
---
# General tutorial
{: .no_toc}
This tutorial shows you the full processing pipeline, from generating the necessary session metadata from the template, running the processing pipeline, opening multiple sessions for manual curation in CellExplorer, and finally using the cell_metrics for filtering cells, by two different criteria. The tutorial is also available as a Matlab script: (`tutorials/CellExplorer_Tutorial.m`).

1. Define the basepath of the dataset to run. The dataset should ideally consist of the raw data `basename.dat`, and spike sorted data.
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
2. Generate [session metadata struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) using the template function and display the metadata in the [session GUI](https://cellexplorer.org/interface/gui_session/):
```m
session = sessionTemplate(basepath,'showGUI',true);
```

![ProcessCellMetrics_gui](https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_general.png)

You can use the GUI to inspect the metadata. Make sure that the extracellular tab is filled out correctly for your data (see screenshot below). The template script can extracted existing metadata from a Neuroscope compatible `basename.xml`, from Intan's `info.rhd` file, from KiloSort's `rez.mat` file, and from a `basename.sessionInfo.mat` (Buzcode) file.

![ProcessCellMetrics_gui](https://buzsakilab.com/wp/wp-content/uploads/2021/04/gui_session_extracellular.png)

3. Run the cell metrics pipeline `ProcessCellMetrics` using the session struct as input
```m
cell_metrics = ProcessCellMetrics('session', session,'showGUI',true);
```
Setting showGUI to *true* will display the GUI shown below allowing you to verify parameters and settings for `ProcessCellMetrics`. You can click the button __Verify metadata__ to show a table with metadata relevant to the processing. Fields requiring your attention will be highlighted in red; optional fields in blue.

![ProcessCellMetrics_gui](https://buzsakilab.com/wp/wp-content/uploads/2021/04/gui_session_ProcessCellMetrics.png)

4. Visualize the cell metrics in CellExplorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
4. Open multiple session from their basepaths
```m
basenames = {'Rat08-20130708','Rat08-20130709'};
basepaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130709'};
cell_metrics = loadCellMetricsBatch('basepaths',basepaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```

5. Curate your cells in CellExplorer and save the metrics 
6. You may use the script `loadCellMetrics` for further analysis using the metrics as filters
   1. Get cells labeled as Interneuron
```m
cell_metrics_idxs1 = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});
```
   1. Get cells that have the groundTruthClassification tag __Axoaxonic__
```m
cell_metrics_idxs2 = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});
```


The cell metrics follows the definition [here](https://cellexplorer.org/datastructure/standard-cell-metrics/). E. g. the filtered waveforms are stored in the field `cell_metrics.waveforms.filt`, and the firing rates in the field: `cell_metrics.firingRate`.