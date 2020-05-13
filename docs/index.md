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
{: .fs-6 .fw-300}

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2} [View code on GitHub](https://github.com/petersenpeter/CellExplorer){: .btn .fs-5 .mb-4 .mb-md-0}

![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2020/05/CellExplorerInterface-1200x730-1.jpg)

## Introduction
{: .no_toc}
The large diversity of cell-types of the brain, provides the means by which circuits perform complex operations. Understanding such diversity is one of the key challenges of modern neuroscience. Neurons have many unique electrophysiological and behavioral features from which parallel cell-type classification can be inferred.

To address this, we built the CellExplorer, a framework for analyzing and characterizing single cells recorded using extracellular electrodes. It can be separated into three components: a standardized yet flexible data structure, a single yet extensive processing module, and a powerful graphical interface. Through the processing module, a high dimensional representation is built from electrophysiological and functional features including the spike waveform, spiking statistics, monosynaptic connections, and behavioral spiking dynamics. The user-friendly interactive graphical interface allows for classification and exploration of those features, through a rich set of built-in plots, interaction modes, cell grouping, and filters. Powerful figures can be created for publications. Opto-tagged cells and public access to reference data have been incorporated to help you characterize your data better. The framework is built entirely in MATLAB making it fast and intuitive to implement and incorporate the CellExplorer into your pipelines and analysis scripts. You can expand it with your metrics, plots, and opto-tagged data. The paper is now available on bioRxiv: [https://doi.org/10.1101/2020.05.07.083436](https://www.biorxiv.org/content/10.1101/2020.05.07.083436v1).


[Data structure]({{"/datastructure/data-structure/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Processing module]({{"/pipeline/pipeline/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interface]({{"/interface/interface/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

## Getting started
1. [Clone](x-github-client://openRepo/https://github.com/petersenpeter/CellExplorer), fork, or [download](https://github.com/petersenpeter/CellExplorer/archive/master.zip) the repository (cloning is recommended).
2. Add the local repository to your MATLAB setpath. 
3. The pipeline uses two c-code files that must be compiled `CCGHeart.c` and `FindInInterval.c` (originally part of the FMA toolbox). Compiled versions are included for Windows and Mac. __If you are using Linux__ you have to compile the scripts. In MATLAB, go to `CellExplorer/calc_CellMetrics/mex/` and run these line:
```m
mex -O CCGHeart.c
mex -O FindInInterval.c
```
4. The CellExplorer GUI and pipeline uses additional toolboxes, of which one MATLAB toolbox must be installed manually.
  * [Curvefit MATLAB toolbox](https://www.mathworks.com/help/curvefit/index.html?s_cid=doc_ftr) (ACG fit in pipeline)

5. That's it! Now you can explore the software with below example data or try one of the tutorials.

### Try the CellExplorer with example data
There is an example dataset included in the repository for trying the CellExplorer. Load the mat-file [`cell_metrics_batch.mat`](https://github.com/petersenpeter/CellExplorer/blob/master/LoadCellMetricsBatch.m) into MATLAB and type:
```m
CellExplorer('metrics',cell_metrics)
```

### Tutorials for using the framework with your own data 
We have created a few tutorials to get you started, covering the pipeline and the graphical interface. There is also a [tutorial script](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/CellExplorer_Tutorial.m): `CellExplorer_Tutorial.m` included with example code for running the pipeline and the GUI on your data.

[View tutorials]({{ "/tutorials/tutorials/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2}

## Reporting bugs, enhancements or questions
Please use the [GitHub issues system](https://github.com/petersenpeter/CellExplorer/issues) for reporting bugs, enhancement requests or general questions.

## Citing the CellExplorer in your research and publications
Peter Christian Petersen, György Buzsáki (2020). CellExplorer: a graphical user interface and standardized pipeline for visualizing and characterizing single neuron features. bioRxiv 2020.05.07.083436; doi: [https://doi.org/10.1101/2020.05.07.083436](https://www.biorxiv.org/content/10.1101/2020.05.07.083436v1). [Download pdf](http://buzsakilab.com/CellExplorer/Petersen_Buzsaki_CellExplorer_bioRxiv_2020.pdf).

## Video demonstrating the user-friendly capabilities of CellExplorer
<video width="100%" height="auto" controls="controls">
  <source src="http://buzsakilab.com/CellExplorer/CellExplorerMovie_WhiteIntro.mp4" type="video/mp4">
</video>

The video is [__available for download (60MB)__](http://buzsakilab.com/CellExplorer/CellExplorerMovie.mp4), and can be streamed on [__YouTube in 4K__](https://www.youtube.com/watch?v=GR1glNhcGIY). For best viewing experience on YouTube, select highest resolution and maximize the video.
