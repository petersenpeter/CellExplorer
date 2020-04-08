---
layout: default
title: Running pipeline
parent: Processing pipeline
nav_order: 1
---
# Running pipeline
The pipeline has three main processing steps: 
1. Gathering metadata
2. Processing cell_metrics
3. Running Cell Explorer

{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Flowcharts
The flowcharts below show the processes in details. The boxes are color coded according to external files (blue), database (purple), script (green), Cell Explorer structs and .mat files (yellow).

### Gathering metadata
First step is creating the session struct. This struct contains all metadata necessary for calculating the cell metrics. You can use the `sessionTemplate` to extract and define the parameters and visualize them with the graphical interface `gui_session`. The templates will scan the basepath for specific files to minimize the manual entry. You can customize the template script to fit and extract information relevant to your data. [The session struct is defined here]({{"/datastructure/data-structure-and-format/#session-metadata"|absolute_url}}). The session struct follows the database structure of the Buzsaki Lab and all metadata can be loaded directly from the database for database sessions. See the example code below on how perform the actions in Matlab.

![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/FlowChart_sessionStruct.png)

### Processing cell_metrics
Following the definition of metadata, the cell metrics calculation process can be performed. A single script processes all default cell_metrics (which can be customized and expanded). The process is fully automatic, except for the detection of monosynaptic connections, in which a graphical interface is shown for further manual curation (the manual step can be turned off). See the [full list of default cell_metrics here]({{"/datastructure/standard-cell-metrics/"|absolute_url}}). Below follows two flowcharts: a simple with the minimal inputs and an advanced flowchart. The advanced chart shows all relevant files that is loaded by the cell_metrics calculation process. 

![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/FlowChart_pipeline.png)

### Running Cell Explorer
The Cell Explorer can be used to display single cell_metrics files as well as batches. Batch loading is performed with the script LoadCellMetricsBatch. The advanced flowchart below further details the capabilities of loading various GUIs from the Cell Explorer (`gui_session`, `gui_MonoSyn` and `gui_DeelSuperficial`) as well as do spike raster plots, that requires access to the local spikes struct and potentially also manipulation and events files when plotting PSTHs.
![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/FlowChart_CellExplorer.png)

## Running pipeline from a data path
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

To run the processing script from the Matlab Command Window from the session struct type:
```m
cell_metrics = ProcessCellMetrics('session', session);
```
You can also run it directly from a basepath and generate the session struct directly:
```m
cell_metrics = ProcessCellMetrics;
```
When calling the processing script with the sessionTemplate, a GUI will be shown allowing you to edit  metadata, both input parameters and the session struct. 

Once complete, view the result in the Cell Explorer by typing:
```m
cell_metrics = CellExplorer('metrics',cell_metrics);
```
### Running Cell Explorer in batch mode from list of data paths
To open multiple sessions together you can run the Cell Explorer in batch mode. Below is an example for running the Cell Explorer on three sessions from the database:

```m
bsasepaths = {'sessionName1','sessionName2','sessionName3'};
cell_metrics = LoadCellMetricsBatch('basepaths',bsasepaths);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
As you perform classifications in the Cell Explorer, you may save back to the original cell metrics stored with the sessions defined above. You can perform the batch mode from a list of paths as well.

## Running pipeline using the Buzsaki lab database
The Cell Explorer pipeline uses a single Matlab struct for handling metadata. The struct is automatically loaded from the buzsaki lab database if you are running the pipeline with the database, and is located in the base path once a session has been processed. To run the pipeline on a session named 'PetersSession' using the database type:
```m
cell_metrics = ProcessCellMetrics('sessionName','PetersSession');
```
To view the result in the Cell Explorer type:
```m
cell_metrics = CellExplorer('metrics',cell_metrics);
```
### Running Cell Explorer in batch mode from database
To open multiple sessions together you can run the Cell Explorer in batch mode. Below is an example for running the Cell Explorer on three sessions from the database:

```m
sessionNames = {'sessionName1','sessionName2','sessionName3'};
cell_metrics = LoadCellMetricsBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
As you perform classifications in the Cell Explorer in batch mode, you can save your progress to the original sessions. You can work in batch mode from a list of paths as well.
