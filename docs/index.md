---
layout: default
title: Home
nav_order: 1
has_children: false
---
# Framework for single cell classification
{: .fs-9 }

The Cell Explorer is a graphical user interface (GUI), standardized pipeline and data structure for exploring and classifying spike sorted single units acquired using extracellular electrodes.
{: .fs-6 .fw-300 }

[Get started now](#installation){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2} [View it on GitHub](https://github.com/petersenpeter/Cell-Explorer){: .btn .fs-5 .mb-4 .mb-md-0 }

![Cell Explorer](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-example.png)

### Installation
Download the repository and add it to your Matlab setpath. The pipeline uses CCGHeart.c. to calculate the CCGs. Compiled versions are included for Windows and Mac. If you are using Linux you have to compile the script. In Matlab, go to Cell-Explorer/calc_CellMetrics/CCG/ and run this line:

`mex -O CCGHeart.c`

The Cell Explorer GUI and pipeline have uses six toolboxes (four required toolboxes are included in the repository in the folder toolboxes, and two Matlab toolboxes must be installed manually).

**Toolbox dependencies**
* [GUI Layout toolbox](https://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox) (Graphical elements in Cell Explorer)
* [JSONLab Matlab toolbox](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab-a-toolbox-to-encode-decode-json-files) (required for db tools)
* [UMAP Matlab toolbox](https://www.mathworks.com/matlabcentral/fileexchange/71902-uniform-manifold-approximation-and-projection-umap) (clustering in Cell Explorer)
* [IoSR Matlab Toolbox](https://github.com/IoSR-Surrey/MatlabToolbox) (lfp filtering in pipeline)
* [Curvefit Matlab toolbox](https://www.mathworks.com/help/curvefit/index.html?s_cid=doc_ftr) (ACG fit in pipeline; install manually)
* [Signal Processing Toolbox ](https://www.mathworks.com/help/signal/index.html?s_tid=CRUX_lftnav) (gausswin; install manually)

### Try the Cell Explorer with example data
There is an example dataset included in the repository. Load the mat-file ['cell_metrics_batch.mat'](https://github.com/petersenpeter/Cell-Explorer/tree/master/exampleData) into Matlab and type:

`CellExplorer('metrics',cell_metrics).`

### Tutorial for running the pipeline on your data
There is a [tutorial script: CellExplorer_Tutorial.m](https://github.com/petersenpeter/Cell-Explorer/blob/master/CellExplorer_Tutorial.m) included for running the pipeline on your data.

### The components of the Cell Explorer
The Cell Explorer can be separated into three components:

[Pipeline](/Cell-Explorer/pipeline/running-pipeline/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interface](/Cell-Explorer/interface/interface/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Database](/Cell-Explorer/database/preparation/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

### Please use below DOI for citing the Cell Explorer in your research and publications:
Petersen, Peter Christian, & Buzsáki, György. (2020, January 10). The Cell Explorer: a graphical user interface and a standardized pipeline for exploring and classifying single cells (Version 1.1). Zenodo. http://doi.org/10.5281/zenodo.3604173

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3604173.svg)](https://doi.org/10.5281/zenodo.3604173)

