---
layout: default
title: Compare states
parent: Tutorials
nav_order: 6
---
# Compare states in datasets
{: .no_toc}
CellExplorer can be used to compare states within or across sessions, .e.g. cells activity compared in two states: control and some pharmacological injection.

If this level of customization is not sufficient, you cal also call many of the scripts separately as [described here](https://cellexplorer.org/tutorials/individual-functions-tutorial/). 

## Compare cell metrics calculated for different temporal intervals (e.g. manipulation states) in the same session
Process a session at three different states. e.g. pharmacology injections vs control:

```m
% These three lines defines the intervals to process separately:
intervals_control = [session.epochs{1}.startTime,session.epochs{1}.stopTime];   % Control
intervals_pharmaco1 = [session.epochs{2}.startTime,session.epochs{2}.stopTime]; % Ka
intervals_pharmaco2 = [session.epochs{3}.startTime,session.epochs{3}.stopTime]; % Ca

% Now the metrics can be restricted to the three intervals by using the input: restrictToIntervals
cell_metrics_control  = ProcessCellMetrics('session', session,'saveAs','cell_metrics_control','restrictToIntervals',intervals_control);
cell_metrics_pharmaco1 = ProcessCellMetrics('session', session,'saveAs','cell_metrics_pharmaco1','restrictToIntervals',intervals_pharmaco1);
cell_metrics_pharmaco2 = ProcessCellMetrics('session', session,'saveAs','cell_metrics_pharmaco2','restrictToIntervals',intervals_pharmaco2);
```

Notice how I used the `saveAs` input to create three separate metric struct for the session. Three files have been created in the basepath:
1. `basename.cell_metrics_control.cellinfo.mat`
2. `basename.cell_metrics_pharmaco1.cellinfo.mat`
3. `basename.cell_metrics_pharmaco2.cellinfo.mat`

### Run CellExplorer on individual restricted dataset
```m
cell_metrics_pharmaco1 = CellExplorer('metrics',cell_metrics_pharmaco1); 
cell_metrics_pharmaco2 = CellExplorer('metrics',cell_metrics_pharmaco2); 

% You can easily combine the same cell_metrics, calculated within states, across session by calling:
cell_metrics = loadCellMetricsBatch('basepaths',basepaths,'saveAs','cell_metrics_control');
```

### You can also simply compare the calculated metrics with a simple scatter plot:
```m
figure
plot(cell_metrics_pharmaco2.firingRate,cell_metrics_control.firingRate,'.')
```
