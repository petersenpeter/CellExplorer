---
layout: default
title: General tutorial
parent: Tutorials
nav_order: 1
---
# General tutorial
{: .no_toc}
This tutorial shows you the full processing pipeline, from generating the necessary session metadata from the template, running the processing pipeline, openinh multiple sessions for manual curation in the Cell Explorer, and finally using the cell_metrics for filtering the cells, by two different criteria. The tutorial is also available as a Matlab script.


1. Define the basepath of the dataset to run. The dataset should at minimum consist of a `basename.dat`, a `basename.xml` and spike sorted data.
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
2. Generate session metadata struct using the template function and display the meta data in a gui
```m
session = sessionTemplate(basepath,'showGUI',true);
```
3. Run the cell metrics pipeline 'calc_CellMetrics' using the session struct as input
```m
cell_metrics = calc_CellMetrics('session', session);
```
4. Visualize the cell metrics in the Cell Explorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
4. Open several session from paths
```m
basenames = {'Rat08-20130708','Rat08-20130709'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130709'};
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```

6. load a subset of units fullfilling multiple of criterium
```m
% Get cells that are assigned as 'Interneuron'
cell_metrics_idxs1 = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});

% Get cells that are has groundTruthClassification as 'Axoaxonic'
cell_metrics_idxs2 = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});
```