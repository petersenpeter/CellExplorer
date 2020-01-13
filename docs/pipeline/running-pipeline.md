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

### Running the pipeline from a data path
The pipeline follows the data standards [described here](/pipeline/data-structure-and-format/). Saving your data in the specified data formats, integrates your data better with the Cell Explorer, allowing you to plot spike rasters and event histograms among other things.

To run the pipeline from a session struct, please see this example
[sessionTemplate.m](https://github.com/petersenpeter/Cell-Explorer/blob/master/calc_CellMetrics/sessionTemplate.m) file for how to format this properly. You can edit the template to fit to your data.

`session = sessionTemplate;`

You can also view the session struct in a GUI:

`session = gui_session(session);`

To run the pipeline from the Matlab Command Window from the session struct type:

`cell_metrics = calc_CellMetrics('session', session);`

You can also run it directly from a basepath and generate the session struct directly:

`cell_metrics = calc_CellMetrics;`

When calling the pipeline with the sessionTemplate, a GUI will be shown allowing you to edit the metadata both for the input parameters and the session struct. 

Once complete, view the result in the Cell Explorer by typing:

`cell_metrics = CellExplorer('metrics',cell_metrics);`

### Running the pipeline using the Buzsaki lab database
The Cell Explorer pipeline uses a single Matlab struct for handling metadata. The struct is automatically loaded from the buzsaki lab database if you are running the pipeline with the database, and is located in the base path once a session has been processed. To run the pipeline on a session named 'PetersSession' using the database type:

`cell_metrics = calc_CellMetrics('sessionName','PetersSession');`

To view the result in the Cell Explorer type:

`cell_metrics = CellExplorer('metrics',cell_metrics);`

### Running the Cell Explorer in batch mode
To open multiple sessions together you can run the Cell Explorer in batch mode. Below is an example for running the Cell Explorer on three sessions from the database:

`sessionNames = {'sessionName1','sessionName2','sessionName3'};`

`cell_metrics = LoadCellMetricBatch('sessions',sessionNames);`

`cell_metrics = CellExplorer('metrics',cell_metrics);`

As you perform classifications in the Cell Explorer, you may save back to the original cell metrics stored with the sessions defined above. You can perform the batch mode from a list of paths as well.
