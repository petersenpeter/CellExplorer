---
layout: default
title: Monosynaptic connections
parent: Tutorials
nav_order: 4
---
# Monosynaptic connections tutorial (draft)
{: .no_toc}
This tutorial will guide you through the manual curation process of the monosynaptic connections. Monosynaptic connections are determined in the pipeline. You can visualize the connections and perform manual curation directly in the graphical interface well. 

There are a few principles you have to follow when doing the manual curation:
1. The synaptic peak should occur with about 2ms delay.
2. If peak coincide with ACG peak (typically slower than 2ms), it is likely that the units should have been merged in the spike sorting process, or that they are contaminated with a third unit and the connection should be rejected.
3. If refractory period is maintained and the CCG is asymmetric: the units should have been merged in the spike sorting process, and the connection should be rejected.
4. Central CCG peak indicates common drive and connections should potentially be rejected. Common drive can also be temporally shifted if the cells are far from each other. This is often seen when comparing two cells located at different shanks. Common drive can be difficult to differentiate from monosynaptic input.

## Using the graphical interface for curating monosynaptic connections
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/monosyn.png)

1. Launch the monosyn GUI
```m
gui_MonoSyn('path_to_data')
```
1. The interface is built from...
2. You can navigate the determined connections using the top two buttons shown in the GUI, or use the left and right arrows.
2. Following the principles stated above, you can now adjust the connections. 
3. The primary action you can perform in the GUI is rejecting connections. The pipeline determines the connections that fulfills the statistical test, and the manual process consists of confirming or rejecting these connections.
4. To reject a connection you simply click the CCG and it will turn red as shown in the screenshot above. You can also use the keypad to select/deselect the CCGs.
5. when you have completed the curation process, simply close the figure and you will be prompted to save the curation.

## You can launch the Monosyn GUI directly from the Cell Explorer
1. Launch the Cell Explorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
2. From the top menu select `MonoSyn` -> `Adjust monosynaptic connections`. The monoSyn data will now be loaded and the MonoSyn interface will be displayed.
3. Adjust connections using the mouse or the numeric keypad. 
3. Once done, simply close the MonoSyn figure. 
4. You will be prompted to save the curation. If you confirm, it will save the `sessionName.mono_res.cellinfo.mat` to the data folder and update the connections in the `cell_metrics` file as well.
