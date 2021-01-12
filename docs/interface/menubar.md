---
layout: default
title: Menu Bar
parent: Graphical interface
nav_order: 4
---
# CellExplorer Menu Bar
{: .no_toc}
Here is a detailed description of each of the menu elements of CellExplorer. 

## Menu Bar elements
{: .no_toc .text-delta }

1. TOC
{:toc}


### CellExplorer

| Elements     | Description       | 
|:-------------|:------------------|
| About CellExplorer | Show About window |
| Edit preferences   | Edit [CellExplorer preferences](https://cellexplorer.org/interface/preferences/), which are stored in `preferences_CellExplorer.m` | 
| Run Benchmarks     | Run various benchmarks as showed in Supplementary figure 5 | 
| Quit               | Quit CellExplorer. This will save any manual curation to the output from the call, e.g. `cell_metrics = CellExplorer('metrics',cell_metrics);`. Closing the main window has the same effect. |

### File

| Elements     | Description       | 
|:-------------|:------------------|
| Load session from file             | Opens a file dialog where you can select a cell metrics Matlab file to load | 
| Save classification                | Saves any manual curation to the original cell metrics files. This also works in batch mode, allowing you to save any changes back to the original cell metrics calculated per session. | 
| Restore classification from backup | Shows a dialog with a list of backup steps for the current session. Choose any backup point to restore to that state. Every time the cell metrics are processed again with `ProcessCellMetrics.m` and curation are saved via CellExplorer, a backup is created. Backups are stored in a subfolder with the data | 
| Reload cell metrics                | Reload cell metrics from original files | 
| Export main figure window          | [Exports the CellExplorer interface](https://cellexplorer.org/tutorials/export-figure/) | 
| Generate supplementary figure      | Generates a [supplementary figure](https://cellexplorer.org/interface/capabilities/#export-supplementary-figure) optimized for publication. You can select which metrics to show in C and D (see figure below) | 

![raincloud cell types](https://buzsakilab.com/wp/wp-content/uploads/2020/05/UnitsSummaryLowRess.png){: .mt-4}

### Navigation

| Elements     | Description       | 
|:-------------|:------------------|
| Go to cell | Shows a dialog allowing you to provide a cell id or session to go to | 
| Go to previously selected cell (backspace)| Go to the previously selected cell | 


### Cell Selection

| Elements     | Description       | 
|:-------------|:------------------|
| Polygon selection of cells from plots | Perform cell classification on a group of cells by drawing a polygon circling the points in either of the scatter plots, waveforms, or ACGs | 
| Perform group action | [Perform group action](https://cellexplorer.org/interface/single-cell-plot-options/#group-action-plots) | 
| Sticky cell selection | __boolean__: Cell selection is kept across calls | 
| Reset sticky cell selection | Resets cell selection | 
| Highlight cells by mouse over | __boolean__: a popup is shwon for the nearest cell (relative to the cursor) in the plots with the cell's id and group info (e.g. Cell type or other active grouping) | 

### Classification

| Elements     | Description       | 
|:-------------|:------------------|
| Undo classification | Undos the last manual curation step (any curation of these types are tracked: cell-types,) | 
| Assign brain region | Assign/alter assigned brain region of current cell | 
| Assign label | Assign/alter label of current cell | 
| Add new cell-type | Create new cell-type | 
| Add new tag | Create a new group tag | 
| Reclassify cells | Reclassifies the cells using the [standard classification from the Processing module](https://cellexplorer.org/pipeline/cell-type-classification/) | 
| Agglomerative hierarchical cluster tree classification | Agglomerative hierarchical cluster tree classification. A dialog will be shown allowing you to select which metrics to include in the analysis | 
| Adjust Deep-Superficial assignment for session | open the [Deep-Superficial GUI](https://cellexplorer.org/interface/capabilities/#interface-for-deep-superfial-classification-curation) via `gui_DeepSuperficial.m`. Please see the [Deep-Superficial tutorial](https://cellexplorer.org/tutorials/deep-superficial-tutorial/) for further info| 

### Waveforms

| Elements     | Description       | 
|:-------------|:------------------|
| Z-score waveforms | __boolean__: Waveforms z-scored or shown in absolute units in the waveform| 
| Show waveform metrics | __boolean__: Show waveform metrics in the single waveform plots, including trough-to-peak, AB-ratio, trough-to-peak (derivative) | 
| Channel map inset with waveforms | __No channelmap/Single units/Trilateration of units__:  | 
| Show ACG inset with waveforms | __boolean__ | 
| Waveform alignment | __Probe layout/Electrode groups__ | 
| Waveform count across channels | __All channels/Best channels__ | 
| Trilateration group data | __session/animal/all__ | 

### View

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### ACG

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### MonoSyn

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### Reference data

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### Ground truth

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### Table data

| Elements     | Description       | 
|:-------------|:------------------|
| ok           | good | 
| out of stock | good | 
| ok           | good | 
| ok           | good | 

### Spikes

| Elements     | Description       | 
|:-------------|:------------------|
| Open spike data dialog | Open the [spike data dialog(https://cellexplorer.org/interface/spike-and-event-data/), also described in [this tutorial](https://cellexplorer.org/tutorials/plotting-spike-data/) | 

![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)

### Session

| Elements     | Description       | 
|:-------------|:------------------|
| View metadata for current session | Opens the session metadata window using `gui_session.m` (shown below). [Learn more about the session metadata](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) | 
| Open directory of current session | Show the data directory of the current session in your file browser | 

![Metadata interface](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-gui_session-general.png)

### BuzLabDB

This menu is for lab members that has credentials to the Buzsaki lab databank at [https://buzsakilab.com/wp/database/](https://buzsakilab.com/wp/database/). Please see this [CellExplorer database page](https://cellexplorer.org/publicdata/preparation/) for further info. 

| Elements     | Description       | 
|:-------------|:------------------|
| Load session(s) from BuzLabDB | Shows the database dialog with list of sessions with existing cell metrics. | 
| Edit credentials | Open the database credentials file `db_credentials.m`, where you can define your [Buzsaki lab databank](https://buzsakilab.com/wp/database/) credentials | 
| Edit repository paths | Open the database credentials file `db_local_repositories.m`, where you can define the local paths tho data repositories used by CellExplorer and the database tools | 
| View current session on website | Shows the current session in the web database in your browser | 
| View current animal subject on website | Shows the current animal subject in the web database in your browser | 


### Help

| Elements     | Description       | 
|:-------------|:------------------|
| Keyboard shortcuts   | Shows a window with the list of keyboard shortcuts | 
| CellExplorer website | Open the [CellExplorer website](https://cellexplorer.org/) in your browser | 
| Tutorials            | Open the [tutorials page](https://cellexplorer.org/tutorials/tutorials/) from the CellExplorer website in your browser | 
