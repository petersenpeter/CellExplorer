---
layout: default
title: Compare states
parent: Tutorials
nav_order: 6
---
# Compare states in datasets
{: .no_toc}
CellExplorer can be used to compare states within or across sessions, .e.g. cells activity compares in two states: control and some pharmacological injection. Another example is comparing a group of sessions to compare experimental conditions and subject differences. 

## Compare states within the same dataset

```m
%% Process same session at three different states. e.g. pharmacology injection vs control

% These three lines defines the intervals to process separately:
intervals_control = [session.epochs{1}.startTime,session.epochs{1}.stopTime];   % Control
intervals_pharmaco1 = [session.epochs{2}.startTime,session.epochs{2}.stopTime]; % Ka
intervals_pharmaco2 = [session.epochs{3}.startTime,session.epochs{3}.stopTime]; % Ca
% Processing cell metrics
% Now the metrics can be restricted to the three intervals by usint the input: restrictToIntervals
cell_metrics_control  = ProcessCellMetrics('session', session,'saveAs','cell_metrics_control','restrictToIntervals',intervals_control);
cell_metrics_pharmaco1 = ProcessCellMetrics('session', session,'saveAs','cell_metrics_pharmaco1','restrictToIntervals',intervals_pharmaco1);
cell_metrics_pharmaco2 = ProcessCellMetrics('session', session,'saveAs','cell_metrics_pharmaco2','restrictToIntervals',intervals_pharmaco2);
% Notice how I used the saveAs input to create three separate metric struct for the session (three files have also been created in the basepath)

% Running CellExplorer on individual restricted dataset
cell_metrics_pharmaco1 = CellExplorer('metrics',cell_metrics_pharmaco1); 
cell_metrics_pharmaco2 = CellExplorer('metrics',cell_metrics_pharmaco2); 
% There is not way yet to combine the same sessions in CellExplorer with different names (restrictToIntervals). 
% You can easily combine the same cell_metrics files within states by calling:
cell_metrics = LoadCellMetricsBatch('basepaths',basepaths,'saveAs','cell_metrics_control');

% What you can  do the comparison of various metrics yourself, e.g.:
figure, plot(cell_metrics_pharmaco2.firingRate,cell_metrics_control.firingRate,'.')
```

## Compare states across datasets
CellExplorer can easily be used to compare sets of datasets
