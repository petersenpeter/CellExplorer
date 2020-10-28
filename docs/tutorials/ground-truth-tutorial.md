---
layout: default
title: Ground truth data
parent: Tutorials
nav_order: 7
---
# Ground truth data tutorial
{: .no_toc}

CellExplorer contains a select set of ground truth data located in `+groundTruthData/`. This tutorial will guide you through using the ground truth data included with CellExplorer.

1. Launch CellExplorer
2. From the top menu `Ground truth`, select `Define ground truth data`. This will display the dialog below with a list of ground truth cells from the `+groundTruthData/` folder. The data is orgazied by sessions, where each session contains at least one tagged cell but can contain more.
![](https://buzsakilab.com/wp/wp-content/uploads/2020/10/GroundTruthCellsDialog_v2.png)
3. Select the cells you would like to load as ground truth data, press OK and the data will be loaded.
4. From the `Ground truth` menu, you can select how to display the ground truth data: as scatter points, as a density map (image), or double histograms.
5. You can select which of the ground truth cell types to display in the Display Settings tab group `GroundTruth` at the bottom of the right panel in CellExplorer.

Once a selection has been made, you can skip step 2 and 3. __If you have data that you are interested in sharing please contact us__. See the [opto-tagging tutorial](/tutorials/optotagging-tutorial/) for how to analyse and add your own data to the ground truth selection. The ground truth cells are labeled in `cell_metrics.groundTruthClassification`.  The video below shows the above steps in CellExplorer:

<video width="100%" height="auto" controls="controls">
  <source src="https://buzsakilab.com/wp/wp-content/uploads/2020/01/GroundTruthTutorial.mp4" type="video/mp4">
</video>
