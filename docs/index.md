---
layout: default
title: Home
nav_order: 1
has_children: false
---
# Framework for analyzing single cells
{: .no_toc}
{: .fs-9 }

CellExplorer is a graphical user interface (GUI), a standardized processing module and data structure for exploring and classifying single cells acquired using extracellular electrodes.
{: .fs-6 .fw-300}

[Get started now](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2} [View code on GitHub](https://github.com/petersenpeter/CellExplorer){: .btn .fs-5 .mb-4 .mb-md-0}

![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2020/05/CellExplorerInterface-1200x730-1.jpg)

## Introduction
{: .no_toc}
The large diversity of cell-types of the brain, provides the means by which circuits perform complex operations. Understanding such diversity is one of the key challenges of modern neuroscience. Neurons have many unique electrophysiological and behavioral features from which parallel cell-type classification can be inferred.

To address this, we built CellExplorer, a framework for analyzing and characterizing single cells recorded using extracellular electrodes. It can be separated into three components: a standardized yet flexible data structure, a single yet extensive processing module, and a powerful graphical interface. Through the processing module, a high dimensional representation is built from electrophysiological and functional features including the spike waveform, spiking statistics, monosynaptic connections, and behavioral spiking dynamics. The user-friendly interactive graphical interface allows for classification and exploration of those features, through a rich set of built-in plots, interaction modes, cell grouping, and filters. Powerful figures can be created for publications. Opto-tagged cells and public access to reference data have been incorporated to help you characterize your data better. The framework is built entirely in MATLAB making it fast and intuitive to implement and incorporate CellExplorer into your pipelines and analysis scripts. You can expand it with your metrics, plots, and opto-tagged data. The paper is now available on bioRxiv: [https://doi.org/10.1101/2020.05.07.083436](https://doi.org/10.1101/2020.05.07.083436).


[Data structure]({{"/datastructure/data-structure/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Processing module]({{"/pipeline/pipeline/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interface]({{"/interface/interface/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

## Getting started
1. [Clone](x-github-client://openRepo/https://github.com/petersenpeter/CellExplorer), fork, or [download](https://github.com/petersenpeter/CellExplorer/archive/master.zip) the repository (cloning or forking is recommended).
2. Add the local repository to your MATLAB setpath. 
3. The pipeline uses two c-code files that must be compiled `CCGHeart.c` and `FindInInterval.c` (originally part of the FMA toolbox). Compiled versions are included for Windows and Mac. __If you are using Linux__ you have to compile the scripts. In MATLAB, go to `CellExplorer/calc_CellMetrics/mex/` and run these line:
```m
mex -O CCGHeart.c
mex -O FindInInterval.c
```
4. CellExplorer uses additional toolboxes, of which two MATLAB toolboxes must be installed manually.
  * [Curve Fitting Toolbox](https://se.mathworks.com/products/curvefitting.html).
  * [Parallel Computing Toolbox](https://se.mathworks.com/products/parallel-computing.html).

That's it! Now you can explore the software with below example data or try one of the tutorials.

### Try CellExplorer with example data
There is an example dataset included in the repository for trying CellExplorer. Load the mat-file [`cell_metrics_batch.mat`](https://github.com/petersenpeter/CellExplorer/blob/master/loadCellMetricsBatch.m) into MATLAB and type:
```m
CellExplorer('metrics',cell_metrics)
```

### Tutorials for using the framework with your own data 
We have created a few tutorials to get you started, covering the pipeline and the graphical interface. There is also a [tutorial script](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/CellExplorer_Tutorial.m): `CellExplorer_Tutorial.m` included with example code for running the pipeline and the GUI on your data.

[View tutorials]({{ "/tutorials/tutorials/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2}

## Support
Please use the [GitHub issues system](https://github.com/petersenpeter/CellExplorer/issues) for reporting bugs, enhancement requests or general questions. We also have a [google group](https://groups.google.com/g/cellexplorer/) for the same requests.

## Citing CellExplorer in research and publications
Peter C. Petersen, Joshua H. Siegle, Nicholas A. Steinmetz, Sara Mahallati, György Buzsáki. CellExplorer: a graphical user interface and a standardized pipeline for visualizing and characterizing single neurons. bioRxiv 2020.05.07.083436; doi: [https://doi.org/10.1101/2020.05.07.083436](https://doi.org/10.1101/2020.05.07.083436).

## Video demonstrating the user-friendly capabilities of CellExplorer
<video width="100%" height="auto" controls="controls">
  <source src="https://buzsakilab.com/CellExplorer/CellExplorerMovie_WhiteIntro.mp4" type="video/mp4">
</video>

The video can be streamed on [__YouTube in 4K__](https://www.youtube.com/watch?v=GR1glNhcGIY) and is [__available for download (60MB)__](https://buzsakilab.com/CellExplorer/CellExplorerMovie.mp4). For best viewing experience on YouTube, select highest resolution and maximize the video.

## Funding
CellExplorer is funded by the NIH Brain initiative as part of the [Oxytocin U19 BRAIN Initiative Grant](https://med.nyu.edu/departments-institutes/neuroscience/research/shared-research-resources/oxytocin-u19-brain-initiative-grant), [the Lundbeck Foundation](https://www.lundbeckfonden.com/en/), and the [Independent Research Fund Denmark](https://ufm.dk/en/research-and-innovation/councils-and-commissions/independent-research-fund-Denmark).

<p align="center">
	<img src="https://buzsakilab.com/wp/wp-content/uploads/2020/11/brain-logo.png" width="30%">&emsp;&emsp;
	<img src="https://buzsakilab.com/wp/wp-content/uploads/2020/11/LUNDBECK-logo-RGB.jpg" width="30%">&emsp;&emsp;
	<img src="https://buzsakilab.com/wp/wp-content/uploads/2020/11/IndependentResearchFundDenmark.png" width="30%">
</p>
