---
layout: default
title: Menu bar
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

| Elements | Description       | 
|:-------------|:------------------|
| About CellExplorer | Shows dialog with basic info about CellExplorer |
| Edit preferences   | Opens [CellExplorer preferences](https://cellexplorer.org/interface/preferences/), which are stored in `preferences_CellExplorer.m` | 
| Run Benchmarks     | Run various benchmarks as showed in Supplementary figure 5 | 
| Quit               | Quit CellExplorer. This will save any manual curation to the output from the call, e.g. `cell_metrics = CellExplorer('metrics',cell_metrics);`. Closing the main window has the same effect. |

### File

| Elements | Description       | 
|:-------------|:------------------|
| Load session from file             | Opens a file dialog where you can select a cell metrics Matlab file to load | 
| Save classification                | Saves any manual curation to the original cell metrics files. This also works in batch mode, allowing you to save any changes back to the original cell metrics calculated per session. | 
| Restore classification from backup | Shows a dialog with a list of backup steps for the current session. Choose any backup point to restore to that state. Every time the cell metrics are processed again with `ProcessCellMetrics.m` and curation are saved via CellExplorer, a backup is created. Backups are stored in a subfolder with the data | 
| Reload cell metrics                | Reload cell metrics from original files | 
| Export main figure window          | [Exports the CellExplorer interface](https://cellexplorer.org/tutorials/export-figure/) | 
| Generate supplementary figure      | Generates a [supplementary figure](https://cellexplorer.org/interface/capabilities/#export-supplementary-figure) optimized for publication (see figures below with the dialog and supplementary figure). You can select which metrics to show in panels in C and D | 
| Generate summary figure            | Generates a summary figure, which is also generate by the processing module | 


![](https://buzsakilab.com/wp/wp-content/uploads/2021/01/supplementaryFigureDialog.png){: .mt-4}

![](https://buzsakilab.com/wp/wp-content/uploads/2020/05/UnitsSummaryLowRess.png){: .mt-4}



### Navigation

| Elements | Description       | 
|:-------------|:------------------|
| Go to cell | Shows a dialog allowing you to provide a cell id or session to go to | 
| Go to previously selected cell (backspace)| Go to previously selected cell | 


### Cell Selection

| Elements | Description       | 
|:-------------|:------------------|
| Polygon selection of cells from plots | Draw a polygon circling the points/lines in any of the plots to perform an action on the circled cells | 
| Perform group action | [Perform group action](https://cellexplorer.org/interface/single-cell-plot-options/#group-action-plots) on selected cells. If no cells are currently selected, a selection dialog will be shown | 
| Sticky cell selection | __boolean__: Cell the selection is kept: "sticky" | 
| Reset sticky cell selection | Resets cell selection | 
| Highlight cells by mouse over | __boolean__: whenever you move your cursor in any plot, a pop-up is shown for the nearest cell (relative to the cursor) in the plots with the cell's id and group info (e.g. Cell type or other active grouping) | 

### Classification

| Elements     | Description       | 
|:-------------|:------------------|
| Undo classification | Undoes the last manual curation step (any curation of these types are tracked: cell-types, labels, tags, groups, brain regions, ground truth classification, Deep-Superficial) | 
| Assign brain region | Assign/alter brain region of current cell | 
| Assign label | Assign/alter label of current cell | 
| Add new cell-type | Create new cell-type | 
| Add new tag | Create new group tag | 
| Reclassify cells | Reclassifies the cells using the [standard classification from the Processing module](https://cellexplorer.org/pipeline/cell-type-classification/) | 
| Agglomerative hierarchical cluster tree classification | Agglomerative hierarchical cluster tree classification. A dialog will be shown allowing you to select which metrics to include in the analysis | 
| Adjust Deep-Superficial assignment for session | Opens the [Deep-Superficial GUI](https://cellexplorer.org/interface/capabilities/#interface-for-deep-superfial-classification-curation) via `gui_DeepSuperficial.m`. Please see the [Deep-Superficial tutorial](https://cellexplorer.org/tutorials/deep-superficial-tutorial/) for further info | 

### Waveforms

| Elements     | Description       | 
|:-------------|:------------------|
| Z-score waveforms | __boolean__: Waveforms are z-scored or shown in µV in the `Waveforms (all)` plot| 
| Show waveform metrics | __boolean__: Show waveform metrics in the single waveform plots. Metrics include trough-to-peak, AB-ratio, trough-to-peak (derivative) | 
| Channel map inset with waveforms | __No channelmap/Single units/Trilateration of units__: Shows a small channel map inset in the waveform plots | 
| Show group colors in channel map inset | __boolean__: Show group colors in channel map inset | 
| Show ACG inset with waveforms | __boolean__: Shows a small ACG inset in the waveform plot | 
| Waveform alignment | __Probe layout/Electrode groups__ | 
| Waveform count across channels | __All channels/Best channels__ Shows waveforms for all or only for the best channels | 
| Trilateration group data | __session/animal/all__ show trilaterated position of units from current session, from the same animal or from all sessions (only in batchmode). Only affects the `trilateration position` plot and not the Channel map inset in the waveforms plot | 

### View

| Elements     | Description       | 
|:-------------|:------------------|
| Show regular Matlab menu bar | __boolean__ Hides the CellExplorer menu and shows the regular Matlab figure menu bar  | 
| Show all traces | __boolean__ All traces are shown instead of the default maximum of 2000 (on by default to increase performance) | 
| Show legend in spikes plot | __boolean__ Shows legend in  spikes plot (off by default to increase performance) | 
| Show linear fit in group plot | __boolean__ Show a linear fit along thet 2D group data in the custom plot | 
| Show legend in firing rate maps | __boolean__ Show legend in firing rate maps (off by default to increase performance) | 
| Show heatmap in firing rate maps  | __boolean__ Show heatmap of trials in firing rate maps (headmap or lines) | 
| Shown colorbar in heatmaps in firing rate maps | __boolean__ Show colorbar in heatmaps (off by default to increase performance) | 
| ISI normalization | __Rate/Occurrence/Instantaneous rate__ Alter the normalization and x-axis of the ISI plots | 
| Raincloud plot normalization | __Peak/Probability/Count__ Alter the normalization of the raincloud histogram curves | 
| Generate significance matrix | Dialog allowing you to select a list of metrics for which a significance matrix  will be generated as described [here](https://cellexplorer.org/interface/capabilities/#significance-matrix) | 
| Generate raincloud metrics figure | Dialog allowing you to select a list of metrics for which a raincloud plot will be generated for each of them as described [here](https://cellexplorer.org/interface/capabilities/#raincloud-plot) | 
| Change marker size for group plots | Change the marker size in group plots: size 6-25 recommended. | 
| Change colormap | Dialog allowing you to change the colormap | 
| Change metric used for sorting image data | Dialog allowing you to change the metric used to sort cells in image data | 
| Change metrics used for t-SNE plot | Dialog allowing you to change the metrics, parameters and recalculate the t-SNE data | 
| Flip x and y axes in the custom plot | Flips selected x and y metrics for the custom plot | 

### ACG

| Elements     | Description       | 
|:-------------|:------------------|
| ACG time scale | __30ms/100ms/1sec/Log10__: adjusts the timescale of the ACG plots | 
| Log y-axis | __boolean__ Logarithmic y-axis | 
| Show ACG fit | __boolean__ Shows the [ACG fit](https://cellexplorer.org/pipeline/acg-fit/) in the ACG plots | 

### MonoSyn

| Elements     | Description       |
|:-------------|:------------------|
| Show in custom plot  | __boolean__ Show monosynaptic connections in the custom plot |
| Show in classic plot | __boolean__ Show monosynaptic connections in the classic plot |
| Show in t-SNE plot | __boolean__ Show monosynaptic connections in the t-SNE plot |
| Plot excitatory connections | __boolean__ Show excitatory monosynaptic connections |
| Plot inhibitory connections | __boolean__ Show inhibitory monosynaptic connections |
| Synaptic filter | __None/Selected/Upstream/Downstream/Up & Downstream /All__: Which monosynaptic connection types to show. | 
| Highlight excitatory cells | __boolean__ Highlight excitatory cells with triangles | 
| Highlight inhibitory cells | __boolean__ Highlight inhibitory cells with squares | 
| Highlight cells receiving excitatory input | __boolean__ Highlight cells receiving excitation with downward facing triangles | 
| Highlight cells receiving inhibitory input | __boolean__ Highlight cells receiving inhibition with asterisks | 
| Shown hollow gaussian in CCG plots | __boolean__ Show the significance level for the monosynaptic connections in the CCG plots (determined from a hollow gaussian) |
| Adjust monosynaptic connections | adjust monosynaptic connections for the current session using the `gui_MonoSyn.m` as described in the [Monosynaptic connections tutorial](https://cellexplorer.org/tutorials/monosynaptic-connections-tutorial/) |

### Reference data

| Elements     | Description       | 
|:-------------|:------------------|
| Reference data plotting options | __No reference truth data/Image data/Scatter data/Histogram data__ Options described [here](https://cellexplorer.org/publicdata/reference-data/#plotting-options) | 
| Opens reference data dialog | Opens the reference data dialog as described [here](https://cellexplorer.org/publicdata/reference-data/) and in [this tutorial](https://cellexplorer.org/tutorials/reference-data-tutorial/) | 
| Adjust bin count for reference and ground truth plots | Adjust the bin count (default: 100) for image and histogram representations | 
| Explore reference data | Replaces current cell metrics data with the loaded reference data, allowing you to explore these cells natively in CellExplorer | 

### Ground truth

| Elements     | Description       | 
|:-------------|:------------------|
| Ground truth plotting options | __No ground truth data/Image data/Scatter data/Histogram data__ Options described [here](https://cellexplorer.org/publicdata/reference-data/#plotting-options) | 
| Opens ground truth data dialog | Opens the ground truth dialog as described in [this tutorial](https://cellexplorer.org/tutorials/ground-truth-tutorial/) (dialog shown below) | 
| Adjust bin count for reference and ground truth plots | Adjust the bin count (default: 100) for image and histogram representations | 
| Show ground truth classification tab | Shows a tab with a list of ground truth cell-types in the right side-panel for manual curation (tagging). Please see this [Opto-tagging tutorial](https://cellexplorer.org/tutorials/optotagging-tutorial/#tagging-your-cells-in-cellexplorer) to learn more | 
| Save tagging to groundTruthData folder | Please see the [Opto-tagging tutorial](https://cellexplorer.org/tutorials/optotagging-tutorial/#saving-opto-taggedground-truth-cells-to-groundtruth-folder) to learn more |
| Explore groundTruth data | Replaces current cell metrics data with the loaded ground truth data, allowing you to explore these cells natively in CellExplorer | 

![](https://buzsakilab.com/wp/wp-content/uploads/2020/10/GroundTruthCellsDialog_v2.png)

### Group data

| Elements     | Description       | 
|:-------------|:------------------|
| Open group data dialog | Shows the group data window for groups/tags/groundTruthClassification. Group data can be selected, edited, highlighted, used as filters and actions can be performed from them. | 
| Generate filters from group data | Takes group data (groups/tags/groundTruthClassification) and generates filters from them (check the drop-down in the left side panel in Group data and filters). Original group data can be overlapping, where a given cell can belong to many groups. If the filters generated, this is not preserved. Three new filter groups are created: `groups_from_tags`, `groups_from_groups` and `groups_from_groundTruthClassification` | 

### Table data

| Elements     | Description       | 
|:-------------|:------------------|
| Table data type | __Cell metrics/Cell list/None__: Show cell metrics (full list of metrics and values) for current cell or list of cells (list of cells with a check box, id and two metrics for each cell) in table | 
| Cell list metrics #1 and #2 | If cell list is shown in table, you can select what metrics to show in the list | 
| Cell list sorting | __multiple options__ The metric used to sort the cells in the table | 

### Spikes

| Elements     | Description       | 
|:-------------|:------------------|
| Open spike data dialog | Open the [spike data dialog](https://cellexplorer.org/interface/spike-and-event-data/), also described in the [tutorial on plotting spike raster data in CellExplorer](https://cellexplorer.org/tutorials/plotting-spike-data/) | 

![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)

### Session

| Elements     | Description       | 
|:-------------|:------------------|
| View metadata for current session | Opens the session metadata window using `gui_session.m` (shown below). [Learn more about the session metadata](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) | 
| Open directory of current session | Show the data directory of the current session in your file browser | 

![Metadata interface](https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_general.png)

### BuzLabDB

This menu is for lab members that has credentials to the Buzsaki lab databank at [https://buzsakilab.com/wp/database/](https://buzsakilab.com/wp/database/). Please see this [CellExplorer database page](https://cellexplorer.org/publicdata/preparation/) for further info. 

| Elements     | Description       | 
|:-------------|:------------------|
| Load session(s) from BuzLabDB | Shows the database dialog with list of sessions with calculated cell metrics. | 
| Edit credentials | Open the database credentials file `db_credentials.m`, where you can define your [Buzsaki lab databank](https://buzsakilab.com/wp/database/) credentials | 
| Edit repository paths | Open the database credentials file `db_local_repositories.m`, where you can define the local paths to data repositories used by CellExplorer and the database tools | 
| View current session on website | Shows the current session in the Buzsaki lab databank in your browser | 
| View current animal subject on website | Shows the current animal subject in the Buzsaki lab databank in your browser | 

### Help

| Elements     | Description       | 
|:-------------|:------------------|
| Keyboard shortcuts   | Shows a window with the list of keyboard shortcuts | 
| CellExplorer website | Open the [CellExplorer website](https://cellexplorer.org/) in your browser | 
| Tutorials            | Open the [tutorials page](https://cellexplorer.org/tutorials/tutorials/) from the CellExplorer website in your browser | 
