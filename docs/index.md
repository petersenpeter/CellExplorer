---
layout: default
title: Home
nav_order: 1
has_children: false
---
# Framework for analyzing and characterizing single cells
{: .no_toc}
{: .fs-9 }

CellExplorer is a graphical user interface (GUI), a standardized processing module and data structure for exploring and classifying single cells acquired using extracellular electrodes.
{: .fs-6 .fw-300 }

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2} [View code on GitHub](https://github.com/petersenpeter/CellExplorer){: .btn .fs-5 .mb-4 .mb-md-0 }

![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2020/04/CellExplorerInterface-1024x623.png)

## Introduction
{: .no_toc}
The large diversity of cell-types of the brain, provides the means by which circuits perform complex operations. Understanding such diversity is one of the key challenges of modern neuroscience. Neurons have many unique electrophysiological and behavioral features from which parallel cell-type classification can be inferred.

To address this, we built the CellExplorer, a framework for analyzing and characterizing single cells recorded using extracellular electrodes. It can be separated into three components: a standardized yet flexible data structure, a single yet extensive processing module, and a powerful graphical interface. Through the processing module, a high dimensional representation is built from electrophysiological and functional features including the spike waveform, spiking statistics, monosynaptic connections, and behavioral spiking dynamics. The user-friendly interactive graphical interface allows for classification and exploration of those features, through a rich set of built-in plots, interaction modes, cell grouping, and filters. Powerful figures can be created for publications. Opto-tagged cells and public access to reference data have been incorporated to help you characterize your data better. The framework is built entirely in MATLAB making it fast and intuitive to implement and incorporate the CellExplorer into your pipelines and analysis scripts. You can expand it with your metrics, plots, and opto-tagged data.

[Data structure]({{"/datastructure/data-structure/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Processing module]({{"/pipeline/pipeline/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interface]({{"/interface/interface/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Getting started
1. [Clone](x-github-client://openRepo/https://github.com/petersenpeter/CellExplorer), fork, or [download](https://github.com/petersenpeter/CellExplorer/archive/master.zip) the repository (cloning is recommended).
2. Add the local repository to your Matlab setpath. 
3. The pipeline uses `CCGHeart.c`. to calculate the CCGs. Compiled versions are included for Windows and Mac. __If you are using Linux__ you have to compile the script. In Matlab, go to `CellExplorer/calc_CellMetrics/CCG/` and run this line:
```m
mex -O CCGHeart.c
```
4. The CellExplorer GUI and pipeline uses additional toolboxes, of which one Matlab toolbox must be installed manually.
  * [Curvefit Matlab toolbox](https://www.mathworks.com/help/curvefit/index.html?s_cid=doc_ftr) (ACG fit in pipeline)

5. That's it! Now you can explore the software with below example data or try one of the tutorials.

### Try the CellExplorer with example data
There is an example dataset included in the repository for trying the CellExplorer. Load the mat-file [`cell_metrics_batch.mat`](https://github.com/petersenpeter/CellExplorer/blob/master/LoadCellMetricsBatch.m) into Matlab and type:
```m
CellExplorer('metrics',cell_metrics)
```

### Tutorials for using the framework with your own data 
We have created a few tutorials to get you started, covering the pipeline and the graphical interface. There is also a [tutorial script](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/CellExplorer_Tutorial.m): `CellExplorer_Tutorial.m` included with example code for running the pipeline and the GUI on your data.

[View tutorials]({{ "/tutorials/tutorials/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2}

## Reporting bugs, enhancements or questions
Please use the [GitHub issues system](https://github.com/petersenpeter/CellExplorer/issues) for reporting bugs, enhancement requests or general questions.

## Citing the CellExplorer in your research and publications
Petersen, Peter C, & Buzsáki, György. (2020, April 8). The CellExplorer: a graphical user interface and a standardized pipeline for exploring and classifying single cells (Version 1.2). Zenodo. [http://doi.org/10.5281/zenodo.3604172](http://doi.org/10.5281/zenodo.3604172)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3604172.svg)](https://doi.org/10.5281/zenodo.3604172)


