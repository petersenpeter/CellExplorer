---
layout: default
title: Perform opto-tagging
parent: Tutorials
nav_order: 6
---
# Opto-tagging tutorial
{: .no_toc}
This tutorial will guide you through the process of tagging your cells by assigning groundTruthClassification-tags to your data in the Cell Explorer.

1. Launch the Cell Explorer.
2. Activate the optotagging from the top menu `Ground truth` and select `Perform ground truth cell type classification in current session(s)`. This opens a tab group in the right side Cell Assignment tab menu titled `G/T`. 
3. Assign the ground truth tag label using the available ground truth cell type options. The list can be customized in the preference file `CellExplorer_Preferences.m`. Cells assigned as ground truth will have a classification label in `cell_metrics.groundTruthClassification`. Each cell can have more than one ground truth classification assigned.
4. Once complete, save the session using the top menu `File` -> `Save classification`.
5. To save/update the ground truth cells to the `groundTruthData/` data folder (centralized ground truth data), go to the `Ground truth` top menu and select `Save manual classification to groundTruth folder`. The `groundTruthData/` contains the cells from each session that have been opto-tagged, saved individually per session.
6. Adjust the highlighted cells using the menu option `Ground truth` -> `Show ground truth cell types in current session(s)`. This plot option is different from the plotting option for centralized ground truth data. 

Opto-tagged/ground truth cells have one or more labels in `cell_metrics.groundTruthClassification`. If you have data that you are interested in sharing please contact us. You can push ground truth cells back the the Cell Explorer GitHub repository, or you can send your data by email to us.

![Optotagging interface](https://buzsakilab.com/wp/wp-content/uploads/2020/01/Cell-Explorer-optotagged-cells-2.png)

## Saving ground truth data / optotagged data to the cell_metrics

## Updating the ground truth data
