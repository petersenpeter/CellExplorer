---
layout: default
title: Manipulations
parent: Tutorials
nav_order: 6
---

If you are doing optogenetic stimulation, applying pharmacology or performing other types of manipulations that could have an effect on the calculated cell metrics, you might want to handle the manipulation time-points with special care. CellExplorer can exclude these affected timestamps and does this on a "metric type" level, defined by the default cell metrics categories:

* waveform_metrics
* PCA_features
* acg_metrics
* monoSynaptic_connections
* theta_metrics
* spatial_metrics
* event_metrics
* psth_metrics
* other_metrics

 Please use [`basename.*.manipulation.mat`]((https://cellexplorer.org/datastructure/data-structure-and-format/#manipulations)) files with timestamps, or provided intervals, are excluded in certain metrics. Manipulation files will automatically be detected and their intervals excluded.

 You can change the [default list of excluded metrics](https://github.com/petersenpeter/CellExplorer/blob/master/ProcessCellMetrics.m#L86) in `ProcessCellMetrics` using the input parameter `metricsToExcludeManipulationIntervals`:

```m
cell_metrics = ProcessCellMetrics('session', session, 'metricsToExcludeManipulationIntervals', {'waveform_metrics','PCA_features','acg_metrics','monoSynaptic_connections','theta_metrics','spatial_metrics','event_metrics','psth_metrics'});
```

You can also use the GUI, as shown in below screenshot - the third list box on the right:
```m
cell_metrics = ProcessCellMetrics('session', session,'showGUI',true)
% Or simply running the script without inputs will show the GUI
cell_metrics = ProcessCellMetrics
```

![ProcessCellMetrics_gui](https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_ProcessCellMetrics.png)

One important thing to clarify is that in `ProcessCellMetrics` the regular spikes struct is split into two structures: [spikes{1}](https://github.com/petersenpeter/CellExplorer/blob/master/ProcessCellMetrics.m#L251) that contains all spikes, and [spikes{2}](https://github.com/petersenpeter/CellExplorer/blob/master/ProcessCellMetrics.m#L326) that excludes timestamps during manipulations. This allows for greater flexibility when handling various types of manipulations that can have very different effects on the calculated metrics.

## Example #1: Excluding manipulations in "other metrics"
As an example, lets say you want to exclude manipulations for the metric `burstIndex_Mizuseki2012`. This is calculated in "other metrics", meaning this is not by default excluded, so you want to add it to the list 'metricsToExcludeManipulationIntervals'. Make sure to save your manipulation timestamps as a [manipulation file](https://cellexplorer.org/datastructure/data-structure-and-format/#manipulations) in the basepath.
 
You can adjust the metrics list using the input parameter `metricsToExcludeManipulationIntervals`:

```m
cell_metrics = ProcessCellMetrics('session', session, 'metricsToExcludeManipulationIntervals', {'other_metrics',...});
```

Or run ProcessCellMetrics from the basepath without inputs, which will show the GUI, and you can add "other_metrics" to the selected list (see the screenshot of the GUI above):

```m
cell_metrics = ProcessCellMetrics
```

## Example #2: excluding manipulations for waveform metrics by supplying interval(s)
As a second example, lets say you want to exclude a specific time interval but only for the waveform metrics. Here you can use the input parameter `excludeIntervals`:

```m
excludeIntervals = [0,2000]; % in seconds, can be pairs of intervals
% Now compute the metrics while using the input parameter: excludeIntervals
cell_metrics_control  = ProcessCellMetrics('session', session,'saveAs','cell_metrics_control','excludeIntervals',excludeIntervals,'metricsToExcludeManipulationIntervals','waveform_metrics');
```
