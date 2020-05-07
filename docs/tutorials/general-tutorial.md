---
layout: default
title: General tutorial
parent: Tutorials
nav_order: 1
---
# General tutorial
{: .no_toc}
This tutorial shows you the full processing pipeline, from generating the necessary session metadata from the template, running the processing pipeline, opening multiple sessions for manual curation in the CellExplorer, and finally using the cell_metrics for filtering cells, by two different criteria. The tutorial is also available as a Matlab script: (`tutorials/CellExplorer_Tutorial.m`).

1. Define the basepath of the dataset to run. The dataset should at minimum consist of a `basename.dat`, a `basename.xml` and spike sorted data.
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
2. Generate session metadata struct using the template function and display the metadata in a GUI
```m
session = sessionTemplate(basepath,'showGUI',true);
```
3. Run the cell metrics pipeline `ProcessCellMetrics` using the session struct as input
```m
cell_metrics = ProcessCellMetrics('session', session);
```
4. Visualize the cell metrics in the CellExplorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
4. Open several session from paths
```m
basenames = {'Rat08-20130708','Rat08-20130709'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130709'};
cell_metrics = LoadCellMetricsBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```

5. Curate your cells and save the metrics 
6. load a subset of units fulfilling multiple criteria
   1. Get cells that are assigned as Interneuron
```m
cell_metrics_idxs1 = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});
```
   1. Get cells that are has groundTruthClassification as Axoaxonic
```m
cell_metrics_idxs2 = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});
```
