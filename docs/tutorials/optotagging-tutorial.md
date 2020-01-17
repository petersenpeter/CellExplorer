---
layout: default
title: Perform opto-tagging
parent: Tutorials
nav_order: 3
---
# Opto-tagging tutorial (draft)
{: .no_toc}
This tutorial will guide you through the process of tagging your cells by assigning cell-type-tags to your data in the Cell Explorer.

1. Launch the Cell Explorer.
2. Activate the optotagging from the top menu `Ground truth` and select `Perform ground truth cell type classification in current session(s)`. This opens a tab group in the right side Cell Assignment tab menu titled `G/T`. 
3. Assign the ground truth tag label using ground truth cell type options. The list can be customized in the preference file `CellExplorer_Preferences.m`. Cells assigned as ground truth with have a classification label in `cell_metrics.groundTruthClassification`. Each cell can have more than one ground truth classification assigned.
4. Once complete, save the session as usual.
5. To save the ground truth cells to the `groundTruthData` data folder (centralized ground truth). Select `Save manual classification to groundTruth folder` from the `Ground truth` top menu.

Adjust the highlighted cells using the menu option `Ground truth` -> `Show ground truth cell types in current session(s)`. This plot option is different from the plotting option for centralized ground truth data.
