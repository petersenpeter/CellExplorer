---
layout: default
title: Monosynaptic connections
parent: Graphical interfaces
nav_order: 9
---
{: .no_toc}
# Graphical interface for inspection and curation of monosynaptic connections

Monosynaptic connections, both excitatory and inhibitory connections, are determined in the processing pipeline. You can visualize the connections and perform manual curation in a graphical interface. 

![](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/MonoSyn3.png)

1. Launch the monoSyn GUI providing the path to your data:
```m
gui_MonoSyn('path_to_data')
```
1. The interface shows you a reference cell together with related connections. CCGs (shown in blue) between all potential connections related to a reference cell (ACG shown in black). The ACG for each potential cell is shown in a small plot inset with each CCG. A image with all CCGs between the reference cell and the rest of the population is also displayed, including the ACG of the reference cell (highlighted with a black dot). Significant connections are also highlighted in the image with white dots. 
2. You can navigate the reference cells using the top two buttons shown in the GUI, or use the left and right arrows. Each connection is displayed twice: where the direction of the connection is shown in context with other connections for that reference cell. This provide insight into the CCG patterns, which is relevant for judging connections of hub-like cells and to detect patterns across CCGs. Press `H` in the GUI to learn all the shortcuts.
2. Following the principles stated above, you can now adjust the connections. 
3. The primary action you can perform in the GUI is rejecting connections. The pipeline determines the connections that fulfills the statistical test, and the manual process consists of confirming and rejecting these connections.
4. Excitatory connections are shown at first, but you can select to show inhibitory connections from the top drop-down menu.
5. To reject a connection you simply click the CCG and it will turn red as shown in the screenshot above. You can also use the keypad to select/reject the CCGs.
5. You can switch between showing all significant connections, and the subset accepted during the manual curation process.
5. when you have completed the curation process, simply close the figure and you will be prompted to save the curation.

## Launch the Monosyn GUI directly from CellExplorer
1. Launch CellExplorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
2. From the top menu select `MonoSyn` -> `Adjust monosynaptic connections`. The monoSyn data will now be loaded and the MonoSyn interface will be displayed.
3. Adjust connections using the mouse or the numeric keypad. 
3. Once done, simply close the MonoSyn figure. 
4. You will be prompted to save the manual curation. If you confirm, it will save the `sessionName.mono_res.cellinfo.mat` to the data folder and update the connections in the `cell_metrics` file as well.