---
layout: default
title: Capabilities
parent: Graphical interface
nav_order: 2
---
# Capabilities
{: .no_toc}
The CellExplorer is a graphical user interface that allow you to explore your data on a single cell level. Each of the plots are interactive using your mouse and keyboard.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}


## Classification
You can do direct classification in the GUI. The following types of classification can be performed.
* **Putative cell type**: You can create new cell types directly in the GUI.
* **Brain region**: Allen institute atlas.
* **Deep-superficial**: Deep superficial assignment can be done in the CellExplorer cell-wise and in a separate gui channel-wise.
* **Labels**: You can assign your own labels to any cell.
* **Tags**: Tags can be assigned.
* **Groups**: Groups can be created.
* **Ground truth cell types**: Ground truth data can be analysed directly in the GUI.

### Monosynaptic connections
Monosynaptic connections are determined in the pipeline, and you can visualize the connections in the GUI and redo the manual curation directly from the GUI. You can adjust connections from the CellExplorer by launching the monosyn interface. [Please see the tutorial on manual curation of monosynaptic connections]({{"/tutorials/monosynaptic-connections-tutorial/"|absolute_url}}).
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/monosyn.png){: .mt-4}

### Interface for deep-superfial classification curation
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/gui_deepSuperficial.png){: .mt-4}

### Database capabilities
The CellExplorer is capable of loading datasets from and writing to the Buzsaki lab database. Please setup your credentials and local paths as [described here]({{"/database/preparation/"|absolute_url}}).

### Reference data
To help you characterize your own data, you can load reference data provided by our lab.

![Reference data](https://buzsakilab.com/wp/wp-content/uploads/2020/01/referenceData_noRef.png)

### Ground truth data
There are a subset of ground truth cell types provided.

### Raincloud plot
To quantify single dimensional variations in your data you can generate a [raincloud plot](https://github.com/RainCloudPlots/RainCloudPlots). You can generate the plot from the top menu `View` -> `Generate rain cloud metrics plot`.

The comparison line widths signify significance levels, `linewidth=1` signifies p>0.05, `linewidth=2` signifies p<0.05 and `linewidth=3` signifies p<0.001. Significance levels is determined using [Two-sample Kolmogorov-Smirnov test](https://www.mathworks.com/help/stats/kstest2.html) (a nonparametric hypothesis test). You can generate a raincloud plot from any color grouping, e.g. cell types, deep-superficial or animal.

Below plot shows a raincloud a comparison across putative cell types:
![raincloud cell types](https://buzsakilab.com/wp/wp-content/uploads/2020/02/raincloud-cell-types.png)

### Significance matrix
The significance matrix can help quantify the modality of your data, e.g. using the deep-superficial labels or the cell types. You can generate the plot from the top menu `View` -> `Generate significance matrix` or by pressing `K`. Please select a group of size 2 beforehand. This will show a dialog for selecting which metrics to process. 
<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2020/02/SignificanceMatrix.png" width="30%"></p>

The colors in the matrix signify significance level (right color bar in log10), `*` signifies p<0.05 and `**` signifies p<0.001. Selected metrics are shown on the left side of the matrix. Significance levels is determined using [Two-sample Kolmogorov-Smirnov test](https://www.mathworks.com/help/stats/kstest2.html) (a nonparametric hypothesis test).

### Share cell metrics in your publications or with your peers
You can save your combined cell metrics from a study into a single mat file that can be shared together with a publication. This allows peers to verify your classification or use your cell metrics directly. You can save the mat file from the CellExplorer from the menu `File` -> `Save classification`.

### Export figures
Figures can be exported using the GUI, either the main CellExplorer window or through cell selection actions dialog. For more information please see the [figure export tutorial]({{"/tutorials/export-figure/"|absolute_url}}).

### Export summary figure
A summary/supplementary figure can be created for publications as shown below (no further edits required). From the menu select `View` -> `Generate supplementary figure`.
![raincloud cell types](https://buzsakilab.com/wp/wp-content/uploads/2020/05/UnitsSummaryLowRess.png){: .mt-4}

### Work in batch-mode while handling metrics on a single session level
The CellExplorer can handle batches of sessions. It will load metrics into one struct allowing you to visualize and classify your data across recordings and classify cells across sessions, while still maintaining the data handling on a single session level, writing your changes back to the original files. You can save metrics from a batch of sessions, and still load the data back into the CellExplorer.

### Track changes and autosave
The CellExplorer tracks your actions, which includes cell-type classifications, deep-superficial assignment, brain regions, labels, tags, groups and ground truth classifications. Reverse an action by pressing `ctrl+Z`. Further it autosaves your actions to your workspace every 6th action (You can turn the autosave feature off or adjust the autosave-interval in preferences). You still have to save your changes to the original cell_metrics file through the CellExplorer interface.
