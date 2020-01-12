---
layout: default
title: Capabilities
parent: Graphical interface
nav_order: 2
---
# Capabilities
{: .no_toc}
The Cell Explorer is a graphical user interface that allow you to explore your data on a single cell level. Each of the plots are interactive using your mouse and keyboard.

### Classification
You can do direct classification in the GUI. The following types of classification can be performed.
* **Putative cell type**: You can create new cell types directly in the GUI.
* **Brain region**: Allen institute atlas.
* **Deep-superficial**: Deep superficial assignment can be done in the Cell Explorer cell-wise and in a separate gui channel-wise.
* **Labels**: You can assign your own labels to any cell.
* **Tags**: A selection of predetermined tags can also be assigned. 
* **Ground truth cell types**: Ground truth data can be analysed directly in the GUI.

## Interface for deep-superfial classification**
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-gui_deep-superfial.png)

### Monosynaptic connections
Monosynaptic connections are determined in the pipeline, and you can visualize the connections in the GUI and redo the manual curation directly from the GUI. You can adjust connections from the Cell Explorer by launching the monosyn interface.

##Interface for adjustment of monosynaptic connections**
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-gui_monosyn.png)

### Reference data
To help you characterize your own data, you can load reference data provided by our lab.

### Ground truth data
There are a subset of ground truth cell types provided.

### Share cell metrics in your publications or with your peers
You can save your combined cell metrics from a study into a single mat file that can be shared together with a publication. This allows peers to verify your classification or use your cell metrics directly. You can save the mat file from the Cell Explorer from the menu File -> Save classification.

### Export figures


### Work in batch-mode while handle metrics on a single session level

Using the Cell Explorer on a batch of sessions, will load metrics into one struct allowing you to visualize and classify your data across recordings and classify cells across sessions, while still maintaining the data handling on a single session level, writing your changes back to the original files. You can save metrics from a batch of sessions, and still load the data back into the Cell Explorer.

### Autosave

The Cell Explorer automatically saves your manual curation every 6 classification action (actions include changes to cell-type, deep-superficial assignment and brain region). You can turn this feature off or adjust the autosave-interval in preferences. The autosave only saves your progress to the workspace and you have to save your changes to the original cell_metrics file through the Cell Explorer interface.

### Database capabilities

The Cell Explorer is capable of loading datasets from and writing to the Buzsaki lab database. Please setup your credentials and local paths as [described here](https://github.com/petersenpeter/Cell-Explorer/wiki/Using-the-buzsaki-lab-database).

