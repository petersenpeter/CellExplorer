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

__Acceptance criteria__
1. The synaptic peak should occur with about 2ms delay.
2. The peak should be asymmetric and shaped as a double exponential function. In the hippocampus the excitatory connections last for about 1.5 ms. Inhibitory connections typically have a slower decay. 

__Rejection criteria__
3. Refractory period maintained. The units should have been merged in the spike sorting process.
2. If peak coincide with ACG peak (typically slower than 2ms), it is likely that the units should have been merged in the spike sorting process, or that they are contaminated with a third unit. This often occurs together with a maintained refractory period, but this will not always be the case for contaminated units
4. A broad centrally aligned CCG peak indicates common drive and the connection should potentially be rejected. Common drive can also be temporally shifted if the cells are far from each other. This is often seen when comparing two cells located at different shanks. Common drive can be difficult to differentiate from monosynaptic input. Common drive can easily occur together with monosynaptic connections and can be difficult to differentiate.

## Using the graphical interface for curating monosynaptic connections
![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/monosyn.png)

1. Launch the monosyn GUI
```m
gui_MonoSyn('path_to_data')
```
1. The interface walks you through the detected connections, displaying the CCGs (shown in blue) between all potential connections related to a reference cell (shown in black). The ACG for each potential cell is shown in a small plot inset for each CCG. A image with all CCGs between the reference cell and the rest of the population is also displayed, including the ACG of the reference cell (highlighted with a black dot). All significant connections are also highlighted in the image with white dots. 
2. You can navigate the reference cells using the top two buttons shown in the GUI, or use the left and right arrows. Each connection is displayed twice: where the direction of the connection is shown in context with other connections for that reference cell. This provide insight into the CCG patterns, which is relevant for judging connections of hub-like cells and to detect patterns across CCGs.
2. Following the principles stated above, you can now adjust the connections. 
3. The primary action you can perform in the GUI is rejecting connections. The pipeline determines the connections that fulfills the statistical test, and the manual process consists of confirming or rejecting these connections.
4. To reject a connection you simply click the CCG and it will turn red as shown in the screenshot above. You can also use the keypad to select/deselect the CCGs.
5. when you have completed the curation process, simply close the figure and you will be prompted to save the curation.

## Launch the Monosyn GUI directly from the Cell Explorer
1. Launch the Cell Explorer
```m
cell_metrics = CellExplorer('metrics',cell_metrics); 
```
2. From the top menu select `MonoSyn` -> `Adjust monosynaptic connections`. The monoSyn data will now be loaded and the MonoSyn interface will be displayed.
3. Adjust connections using the mouse or the numeric keypad. 
3. Once done, simply close the MonoSyn figure. 
4. You will be prompted to save the manual curation. If you confirm, it will save the `sessionName.mono_res.cellinfo.mat` to the data folder and update the connections in the `cell_metrics` file as well.
