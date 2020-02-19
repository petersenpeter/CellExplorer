---
layout: default
title: Capabilities
parent: Graphical interface
nav_order: 2
---
# Capabilities
{: .no_toc}
The Cell Explorer is a graphical user interface that allow you to explore your data on a single cell level. Each of the plots are interactive using your mouse and keyboard.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Classification
You can do direct classification in the GUI. The following types of classification can be performed.
* **Putative cell type**: You can create new cell types directly in the GUI.
* **Brain region**: Allen institute atlas.
* **Deep-superficial**: Deep superficial assignment can be done in the Cell Explorer cell-wise and in a separate gui channel-wise.
* **Labels**: You can assign your own labels to any cell.
* **Tags**: A selection of predetermined tags can also be assigned. 
* **Ground truth cell types**: Ground truth data can be analysed directly in the GUI.

### Interface for deep-superfial classification curation
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/gui_deepSuperficial.png){: .mt-4}

## Monosynaptic connections
Monosynaptic connections are determined in the pipeline, and you can visualize the connections in the GUI and redo the manual curation directly from the GUI. You can adjust connections from the Cell Explorer by launching the monosyn interface.

### Interface for monosynaptic connections curation
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/monosyn.png)

## Database capabilities
The Cell Explorer is capable of loading datasets from and writing to the Buzsaki lab database. Please setup your credentials and local paths as [described here]({{"/database/preparation/"|absolute_url}}).

### Reference data
To help you characterize your own data, you can load reference data provided by our lab.

![Reference data](https://buzsakilab.com/wp/wp-content/uploads/2020/01/referenceData_noRef.png)

### Ground truth data
There are a subset of ground truth cell types provided.

### Raincloud plot
To estimate single dimensional variations in your data you can generate a [raincloud plot](https://github.com/RainCloudPlots/RainCloudPlots). You can generate the plot from the top menu `View` -> `Generate rain cloud metrics plot`.

The comparison line widths signify significance levels, `linewidth=1` signifies p>0.05, `linewidth=2` signifies p<0.05 and `linewidth=3` signifies p<0.001. Significance levels is determined using [Two-sample Kolmogorov-Smirnov test](https://www.mathworks.com/help/stats/kstest2.html) (a nonparametric hypothesis test).

Below plot shows a raincloud a comparison across putative cell types:
![raincloud cell types](https://buzsakilab.com/wp/wp-content/uploads/2020/02/raincloud-cell-types.png)

Below plot shows a comparing of cells labeled either deep or superficial:
![raincloud deep superficial](https://buzsakilab.com/wp/wp-content/uploads/2020/02/raincloud-deep-superficial.png)

### Significance matrix
The significance matrix can help find metrics that your data into groups, e.g. deep-superfical labels. You can generate the plot from the top menu `View` -> `Generate significance matrix` or by pressing `K`. Please select a group of size 2 beforehand. This will show a dialog for selecting which metrics to use. 

![Significance matrix](https://buzsakilab.com/wp/wp-content/uploads/2020/02/SignificanceMatrix.png)
The colors in the matrix signify significance level (right color bar in log10), `*` signifies p<0.05 and `**` signifies p<0.001. Selected metrics are shown on the left side of the matrix. Significance levels is determined using [Two-sample Kolmogorov-Smirnov test](https://www.mathworks.com/help/stats/kstest2.html) (a nonparametric hypothesis test).

### Share cell metrics in your publications or with your peers
You can save your combined cell metrics from a study into a single mat file that can be shared together with a publication. This allows peers to verify your classification or use your cell metrics directly. You can save the mat file from the Cell Explorer from the menu `File` -> `Save classification`.

### Export figures
There are two ways to export figures. 
1. You can export the whole interface from the top menu from the top menu `File` -> `Export figure`. This will open the Matlab Figure Export Setup dialog box (`exportsetupdlg`). 
2. Single cell figures
   1. Select a number of cells, using the mouse and press `space`, this opens the action dialog. If no selection is done before pressing `space` a selection dialog will be shown.
   <p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-dialog.png" width="70%"></p>
   2. Select either of the three `MULTI PLOT OPTIONS`
   3. In the new dialog, toogle `Save figures`, and define format and file path.
   <p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-multiplot-dialog.png" width="70%"></p>

### Work in batch-mode while handling metrics on a single session level
Using the Cell Explorer on a batch of sessions, will load metrics into one struct allowing you to visualize and classify your data across recordings and classify cells across sessions, while still maintaining the data handling on a single session level, writing your changes back to the original files. You can save metrics from a batch of sessions, and still load the data back into the Cell Explorer.

### Autosave
The Cell Explorer automatically saves your manual curation every 6 classification action (actions include changes to cell-type, deep-superficial assignment and brain region). You can turn this feature off or adjust the autosave-interval in preferences. The autosave only saves your progress to the workspace and you have to save your changes to the original cell_metrics file through the Cell Explorer interface.
