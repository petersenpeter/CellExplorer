---
layout: default
title: Manual curation
parent: Tutorials
nav_order: 3
---
# Manual curation tutorial (draft)
{: .no_toc}
This tutorial will guide you through the manual curation process.

1. Launch the Cell Explorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
2. Navigate the cells using the keyboard, the graphical buttons, or by left-clicking the plots. 
3. Assign cell types from the `Cell Assignment` side menu using your mouse or the numeric keys (not the keypad). You can add new cell types by pressing `+ Cell-type`. You can also do group assignment via the group action menu:
   * Select cell(s) and press `space` to open the group actions menu.
   * Click the middle mouse button on any of the Cell Explorer plots to start drawing a polygon using left mouse button circling the cells you want to select. This can be done from any of the plots. Finish the polygon by pressing the right mouse button. This will show the group action menu. 
   * Pressing `space` without any cells selected will show a cell selection filter dialog. Select a filter and press OK to open the group actions menu.
   <img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-dialog.png" width="70%">
4. You can save your progress from the top menu `File` -> `Save classification`. This will save your metrics to the original session-wise cell_metrics files, even when working in batch mode. 
5. A dialog will be shown and you can select to update sessions with tracked changes or all of them.

All your classification actions are tracked, shown in the message log, and can be reversed by pressing `ctrl+z`. The list of cell types are defined in `CellExplorer_Preferences.m`. Putative cell types are stored in `cell_metrics.putativeCellType`. Cell types present in `cell_metrics.putativeCellType` will be added to the predefined list in Cell Explorer. The default cell-type colors are defined in `CellExplorer_Preferences.m`. Learn more about preferences and the interface below.

[Preferences](/Cell-Explorer/interface/preferences/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4} [Graphical interface]({{"/interface/description/"|absolute_url}}){: .btn .fs-5 .mb-4 .mb-md-0 .mr-4}