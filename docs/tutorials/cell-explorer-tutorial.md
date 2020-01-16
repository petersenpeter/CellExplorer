---
layout: default
title: Cell Explorer
parent: Tutorials
nav_order: 3
---
# Cell Explorer tutorial (coming)
{: .no_toc}
This tutorial will guide you through the interface and the manual curation process.

1. Visualize the cell metrics in the Cell Explorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
2. Open several session from paths
```m
basenames = {'Rat08-20130708','Rat08-20130709'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130709'};
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
