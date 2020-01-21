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
3. Assign cell type from the `Cell Assignment` side menu usng your mouse or the numeric keys (not the keypad).
4. You can save your progress from the top menu `File` -> `Save classification`. This will save your metrics to the original session-wise cell_metrics files, even when working in batch mode. 
5. A dialog will be shown and you can select to update sessions with tracked changes or  all sessions.

All your classification actions are tracked, shown in the message log, and can be reversed by clicking `ctrl+z`.
