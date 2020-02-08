---
layout: default
title: Running pipeline
parent: Processing pipeline
nav_order: 1
---
# Running pipeline
{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

### Processing flowcharts
Below three flow charts shows the three main processing steps, 1. Gathering metadata, 2. Running the pipeline and 3. Running Cell Explorer. The boxes are color coded according to external files (blue), database (purple), script (green), Cell Explorer mat files (yellow).

![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/AlgorithmFlowchart-1.png)

### Running pipeline from a data path
The pipeline follows the data standards [described here]({{"/datastructure/data-structure-and-format/"|absolute_url}}). Saving your data in the specified data formats, integrates your data better with the Cell Explorer, allowing you to plot spike rasters and event histograms among other things.

To run the pipeline from a session struct, please see this example
[sessionTemplate.m](https://github.com/petersenpeter/Cell-Explorer/blob/master/calc_CellMetrics/sessionTemplate.m) file for how to format this properly. You can edit the template to fit it to your data.
```m
session = sessionTemplate;
```
You can also view the session struct in a GUI:
```m
session = gui_session(session);
```

To run the pipeline from the Matlab Command Window from the session struct type:
```m
cell_metrics = calc_CellMetrics('session', session);
```
You can also run it directly from a basepath and generate the session struct directly:
```m
cell_metrics = calc_CellMetrics;
```
When calling the pipeline with the sessionTemplate, a GUI will be shown allowing you to edit the metadata both for the input parameters and the session struct. 

Once complete, view the result in the Cell Explorer by typing:
```m
cell_metrics = CellExplorer('metrics',cell_metrics);
```

### Running pipeline using the Buzsaki lab database
The Cell Explorer pipeline uses a single Matlab struct for handling metadata. The struct is automatically loaded from the buzsaki lab database if you are running the pipeline with the database, and is located in the base path once a session has been processed. To run the pipeline on a session named 'PetersSession' using the database type:
```m
cell_metrics = calc_CellMetrics('sessionName','PetersSession');
```
To view the result in the Cell Explorer type:
```m
cell_metrics = CellExplorer('metrics',cell_metrics);
```
### Running Cell Explorer in batch mode
To open multiple sessions together you can run the Cell Explorer in batch mode. Below is an example for running the Cell Explorer on three sessions from the database:

```m
sessionNames = {'sessionName1','sessionName2','sessionName3'};
cell_metrics = LoadCellMetricBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
As you perform classifications in the Cell Explorer, you may save back to the original cell metrics stored with the sessions defined above. You can perform the batch mode from a list of paths as well.
