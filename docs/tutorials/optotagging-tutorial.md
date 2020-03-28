---
layout: default
title: Opto-tagging
parent: Tutorials
nav_order: 6
---
# Opto-tagging tutorial
{: .no_toc}
This tutorial will guide you through the process of tagging your cells by assigning groundTruthClassification-tags to your data in the Cell Explorer. If you have data that you are interested in sharing please contact us. You can push ground truth cells back the the Cell Explorer GitHub repository, or you can send your data by email to us, see instructions below.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

### Add your own tags to your cell_metrics
Opto-tagged/ground truth cells have one or more labels in `cell_metrics.groundTruthClassification`. If you already have determined the identity of your cells you can simply add them to the `groundTruthClassification` field:
```m
cellIDs_optoTagged = [1,5,10]; % IDs (UIDs) of the opto-tagged cells
name_optoTagged = 'PV+';       % Cell line name
cell_metrics.groundTruthClassification(cellIDs_optoTagged) = repmat({{name_optoTagged}},length(cellIDs_optoTagged),1);
```

### Tagging your cells in the Cell Explorer
1. Launch the Cell Explorer.
2. Activate the optotagging from the top menu `Ground truth` and select `Perform ground truth cell type classification in current session(s)`. This opens a tab group in the right side Cell Assignment tab menu titled `G/T`. 
3. Assign the ground truth tag label using the available ground truth cell type options. The list can be customized in the preference file `CellExplorer_Preferences.m`. Cells assigned as ground truth will have a classification label in `cell_metrics.groundTruthClassification`. Each cell can have more than one ground truth classification assigned.
4. Once complete, save the session using the top menu `File` -> `Save classification`.

Opto-tagged/ground truth cells have one or more labels in `cell_metrics.groundTruthClassification`. 

![Optotagging interface](https://buzsakilab.com/wp/wp-content/uploads/2020/01/Cell-Explorer-optotagged-cells-2.png)

### Saving opto-tagged/ground truth cells to groundTruth folder
Following the process described in the previous section on tagging your cells, you can submit your opto-tagged cells to the `groundTruth` folder through the Cell Explorer UI, allowing you to share your cells and use them across sessions without any opto-tagged cells. 

1. To save/update the ground truth cells to the `groundTruthData/` data folder (centralized ground truth data), go to the `Ground truth` top menu and select `Save manual classification to groundTruth folder`. The `groundTruthData/` contains the cells from each session that have been opto-tagged, saved individually per session.
2. Adjust the highlighted cells using the menu option `Ground truth` -> `Show ground truth cell types in current session(s)`. This plot option is different from the plotting option for centralized ground truth data. 

### Submit your cells to the Cell Explorer repository
You can submit your cells to the Cell Explorer repository such that other people can take advantage of your ground truth cells. This allows the community to share their tagged cells such that others can researchers can benefit.

1. __Push metrics back to main branch of the Cell Explorer Github repository__: If you cloned the Cell Explorer repository, you can submit a pull-request to the main Cell Explorer branch. We will verify your files and submit then to the main branch of the Cell Explorer. 
2. __Email metrics to us__: You can email your ground truth cells to us at petersen.peter@gmail.com. Provide at minimum the `cell_metrics` files saved in `groundTruthData/`. Your ground truth cells are saved session-wise, where the files in  `groundTruthData/` only contains cells with an groundTruthClassification. We will verify your files and submit then to the main branch of the Cell Explorer. 