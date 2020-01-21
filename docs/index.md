---
layout: default
title: Home
nav_order: 1
has_children: false
---
# Framework for single cell classification
{: .no_toc}
{: .fs-9 }

The Cell Explorer is a graphical user interface (GUI), standardized pipeline and data structure for exploring and classifying spike sorted single units acquired using extracellular electrodes.
{: .fs-6 .fw-300 }

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2} [View code on GitHub](https://github.com/petersenpeter/Cell-Explorer){: .btn .fs-5 .mb-4 .mb-md-0 }

![Cell Explorer](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-example.png)

## Introduction
{: .no_toc}
The large diversity of cell types of the brain provides the means by which circuits perform complex operations. Understanding such diversity is one of the key challenges of modern neuroscience. These cells have many unique electrophysiological and behavioral features from which parallel cell types classification can be inferred. The Cell Explorer is a framework for analyzing and characterizing single cells recorded using extracellular electrodes. A high dimensional representation is built from electrophysiological and functional features including the spike waveform, spiking statistics, behavioral spiking dynamics, spatial firing maps and various brain rhythms. Moreover, we are incorporating opto-tagget cells in this pipeline (ground-truth cell types). The user friendly graphical interface allows for verification, classification and exploration of those same features. The framework is built entirely in Matlab making it fast and intuitive to implement your own code and incorporate the Cell Explorer in your overall pipeline and analysis scripts.

### The components of the Cell Explorer
{: .no_toc}
The Cell Explorer can be separated into three main components:

[1. Processing pipeline](/Cell-Explorer/pipeline/running-pipeline/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [2. Graphical interface]({{"/interface/interface/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [3. Database]({{ "/database/preparation/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Getting started
[Clone](x-github-client://openRepo/https://github.com/petersenpeter/Cell-Explorer) or [download](https://github.com/petersenpeter/Cell-Explorer/archive/master.zip) the repository and add it to your Matlab setpath (Cloning is strongly recommended). 

The pipeline uses `CCGHeart.c`. to calculate the CCGs. Compiled versions are included for Windows and Mac. __If you are using Linux__ you have to compile the script. In Matlab, go to `Cell-Explorer/calc_CellMetrics/CCG/` and run this line:

```m
mex -O CCGHeart.c
```
The Cell Explorer GUI and pipeline uses a few toolboxes (four required toolboxes are included in the repository in the folder toolboxes, and three Matlab toolboxes must be installed manually).

**Toolbox dependencies**
* [GUI Layout toolbox](https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (Graphical elements in Cell Explorer)
* [JSONLab Matlab toolbox](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab-a-toolbox-to-encode-decode-json-files) (required for db tools)
* [UMAP Matlab toolbox](https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap) (clustering in Cell Explorer)
* [IoSR Matlab Toolbox](https://github.com/IoSR-Surrey/MatlabToolbox) (lfp filtering in pipeline)
* [Curvefit Matlab toolbox](https://www.mathworks.com/help/curvefit/index.html?s_cid=doc_ftr) (ACG fit in pipeline; install manually)
* [Signal Processing Toolbox](https://www.mathworks.com/help/signal/index.html?s_tid=CRUX_lftnav) (gausswin; install manually)
* [Image Processing Toolbox ](https://www.mathworks.com/products/image.html) (imrotate; install manually)

### Try the Cell Explorer with example data
There is an example dataset included in the repository. Load the mat-file [`cell_metrics_batch.mat`](https://github.com/petersenpeter/Cell-Explorer/blob/master/LoadCellMetricBatch.m) into Matlab and type:
```m
CellExplorer('metrics',cell_metrics)
```

### Tutorials for using the framework with your own data 
We have created a few tutorials, please check them out. There is a [tutorial script](https://github.com/petersenpeter/Cell-Explorer/blob/master/tutorials/CellExplorer_Tutorial.m): `CellExplorer_Tutorial.m` included for running the pipeline on your data.

[View tutorials]({{ "/tutorials/tutorials/"|absolute_url}}){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2}

### Reporting bugs, enhancements or questions
Please use the [GitHub issues system](https://github.com/petersenpeter/Cell-Explorer/issues) for reporting bugs, enhancement requests or geneal questions.

## Citing the Cell Explorer in your research and publications

Petersen, Peter Christian, & Buzsáki, György. (2020, January 10). The Cell Explorer: a graphical user interface and a standardized pipeline for exploring and classifying single cells (Version 1.1). Zenodo. http://doi.org/10.5281/zenodo.3604173

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3604173.svg)](https://doi.org/10.5281/zenodo.3604173)

