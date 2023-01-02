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

![CellExplorer](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/CellExplorerInterface-1200x730-1.jpeg)

## Introduction
{: .no_toc}
The large diversity of cell-types of the brain, provides the means by which circuits perform complex operations. Understanding such diversity is one of the key challenges of modern neuroscience. Neurons have many unique electrophysiological and behavioral features from which parallel cell-type classification can be inferred.

To address this, we built CellExplorer, a framework for analyzing and characterizing single cells recorded using extracellular electrodes. It can be separated into three components: a standardized yet flexible data structure, a single yet extensive processing module, and a powerful graphical interface. Through the processing module, a high dimensional representation is built from electrophysiological and functional features including the spike waveform, spiking statistics, monosynaptic connections, and behavioral spiking dynamics. The user-friendly interactive graphical interface allows for classification and exploration of those features, through a rich set of built-in plots, interaction modes, cell grouping, and filters. Powerful figures can be created for publications. Opto-tagged cells and public access to reference data have been incorporated to help you characterize your data better. The framework is built entirely in MATLAB making it fast and intuitive to implement and incorporate CellExplorer into your pipelines and analysis scripts. You can expand it with your metrics, plots, and opto-tagged data. The paper is published in Neuron: [https://doi.org/10.1016/j.neuron.2021.09.002](https://www.sciencedirect.com/science/article/pii/S0896627321006565).


[Data structure]({{"/data-structure/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Processing module]({{"/pipeline/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interfaces]({{"/interfaces/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}

## Getting started
1. [Clone](x-github-client://openRepo/https://github.com/petersenpeter/CellExplorer), fork, or [download](https://github.com/petersenpeter/CellExplorer/archive/master.zip) the repository (cloning or forking is recommended).
2. Add the local repository to your MATLAB setpath (make sure to select __Add with subfolders...__). 
3. The pipeline uses two c-code files that must be compiled `CCGHeart.c` and `FindInInterval.c` (originally part of the FMA toolbox). Compiled versions are included for Windows 64bit and Intel Mac 64bit, but you still have to compile them if your OS version is different. __If you are using Linux__ you have to compile the scripts. In MATLAB, go to `CellExplorer/calc_CellMetrics/mex/` and run these line:
```m
mex -O CCGHeart.c
mex -O FindInInterval.c
```
4. CellExplorer uses additional MATLAB toolboxes, where three of them are required.
  * [Curve Fitting Toolbox](https://se.mathworks.com/products/curvefitting.html) (required).
  * [Signal Processing Toolbox](https://se.mathworks.com/products/signal.html) (required).
  * [Statistics and Machine Learning Toolbox](https://se.mathworks.com/products/statistics.html) (required).
  * [Parallel Computing Toolbox](https://se.mathworks.com/products/parallel-computing.html) (optional, allows for parallel processing of certain features).
  * [Image Processing Toolbox](https://se.mathworks.com/products/image.html) (optional for NeuroScope2, allows for selection of channels from the probe layout).
  * [DSP System Toolbox](https://se.mathworks.com/products/dsp-system.html) or the [Audio Toolbox](https://www.mathworks.com/products/audio.html) (optional for NeuroScope2 to stream audio of traces).

That's it! Now you can explore the software with below example data or try one of the tutorials with your own data.

### Try CellExplorer with example data
There is an example dataset included in the repository for trying CellExplorer. Load the mat-file [`cell_metrics_batch.mat`](https://github.com/petersenpeter/CellExplorer/blob/master/exampleData/cell_metrics_batch.mat?raw=true) into MATLAB and type:
```m
CellExplorer('metrics',cell_metrics)
```

### Tutorials for using the framework with your own data 
We have created a few tutorials to get you started, covering the pipeline and the graphical interface. There is also a [tutorial script](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/CellExplorer_Tutorial.m): `CellExplorer_Tutorial.m` included with example code for running the pipeline and the GUI on your data.

[View tutorials]({{ "/tutorials/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2}

Please also check out the recorded presentation of [CellExplorer at the Neuropixels course in 2022](https://www.youtube.com/watch?v=ejI5VIz9Yw8). It includes an introduction with slides and a demo in Matlab showing how to use the processing pipeline, CellExplorer, and NeuroScope2 (11 minutes long).

## Support
Please use the [GitHub issues system](https://github.com/petersenpeter/CellExplorer/issues) and [GitHub Discussions](https://github.com/petersenpeter/CellExplorer/discussions) for reporting bugs, enhancement requests or general questions.

## Citing CellExplorer in research and publications
Peter C. Petersen, Joshua H. Siegle, Nicholas A. Steinmetz, Sara Mahallati, György Buzsáki. CellExplorer: A framework for visualizing and characterizing single neurons. Neuron, September 29, 2021; doi: [https://doi.org/10.1016/j.neuron.2021.09.002](https://www.sciencedirect.com/science/article/pii/S0896627321006565).

## Video demonstrating the user-friendly capabilities of CellExplorer
<video width="100%" height="auto" controls="controls">
  <source src="https://raw.githubusercontent.com/petersenpeter/common_resources/main/videos/CellExplorerMovie_WhiteIntro.mp4" type="video/mp4">
</video>

The video can be streamed on [__YouTube in 4K__](https://www.youtube.com/watch?v=GR1glNhcGIY) and is [__available for download (60MB)__](https://raw.githubusercontent.com/petersenpeter/common_resources/main/videos/CellExplorerMovie.mp4). For best viewing experience on YouTube, select highest resolution and maximize the video. 

## Funding
CellExplorer is funded through the [Oxytocin U19 BRAIN Initiative Grant](https://med.nyu.edu/departments-institutes/neuroscience/research/shared-research-resources/oxytocin-u19-brain-initiative-grant), [the Lundbeck Foundation](https://www.lundbeckfonden.com/en/), and the [Independent Research Fund Denmark](https://ufm.dk/en/research-and-innovation/councils-and-commissions/independent-research-fund-Denmark).

<p align="center">
	<img src="https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/brain_initiative.png" width="19%">&emsp;&emsp;&emsp;&emsp;
	<img src="https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/Lundbeck_foundation.png" width="23%">&emsp;&emsp;
	<img src="https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/IndependentResearchFundDenmark.png" width="35%">
</p>
