---
layout: default
title: Menu bar
parent: NeuroScope2
grand_parent: Graphical interfaces
nav_order: 3
---

# NeuroScope2 Menu Bar
{: .no_toc}
Here is a detailed description of each of the menu elements of NeuroScope2. 

## Menu Bar elements
{: .no_toc .text-delta }

1. TOC
{:toc}


### NeuroScope2

| Elements | Description       | 
|:-------------|:------------------|
| About NeuroScope2 | Shows dialog with basic info about NeuroScope2 |
| Quit               | Quit NeuroScope2. This will save automatically save the session metadata. Closing the main window has the same effect. |

### File

| Elements | Description       | 
|:-------------|:------------------|
| Load session from folder              | Opens a file dialog where you can select a folder to load | 
| Load session from file                | Opens a file dialog where you can select a file to load | 
| Recent sessions...                    | Shows a list of recently active sessions. | 
| Export to .png file (image)           | Exports screenshot to .png file as image graphics | 
| Export to .pdf file (vector graphics) | Exports screenshot to .pdf file as vector graphics | 
| Export figure via the export setup dialog | Export figure via the export setup dialog | 


### Session

| Elements      | Description       | 
|:--------------|:------------------|
| View metadata | Shows the session GUI (session metadata) | 
| Save metadata | Save the session metadata | 
| Open basepath | Opens the basepath of the current active session in finder/explorer | 


### Cell metrics 

| Elements     | Description       | 
|:-------------|:------------------|
| Open group data dialog | Opens the group data dialog | 
| Save cell_metrics | Save cell metrics | 

### BuzLabDB

This menu is for lab members that has credentials to the Buzsaki lab databank at [https://buzsakilab.com/wp/database/](https://buzsakilab.com/wp/database/). Please see this [CellExplorer database page](https://cellexplorer.org/publicdata/preparation/) for further info. 

| Elements     | Description       | 
|:-------------|:------------------|
| Load session(s) from BuzLabDB | Shows the database dialog with list of sessions with calculated cell metrics. | 
| Edit credentials | Open the database credentials file `db_credentials.m`, where you can define your [Buzsaki lab databank](https://buzsakilab.com/wp/database/) credentials | 
| Edit repository paths | Open the database credentials file `db_local_repositories.m`, where you can define the local paths to data repositories used by CellExplorer and the database tools | 
| View current session on website | Shows the current session in the Buzsaki lab databank in your browser | 
| View current animal subject on website | Shows the current animal subject in the Buzsaki lab databank in your browser | 

### View

| Elements     | Description       | 
|:-------------|:------------------|
| Summary figure | Generates a summary figure containing the full timeline of external data currently active in NeuroScope2, e.g. spikes, events, states, behavior and trials, time series  | 
| RMS noise across channels | Generates a figure with RMS across electrodes | 
| Power spectral density across channels | Generates a power spectral density plot for all active channels | 
| Power spectral density across channels (log bins; slower) | Generates a power spectral density plot, with log bins, for all active channels. Slower but more informative | 

### Settings

| Elements     | Description       | 
|:-------------|:------------------|
| Show full menu | __boolean__ Hides the NeuroScope2 menu and shows the regular Matlab figure menu bar. Press M to reverse.  | 
| Remove DC from signal | __boolean__ Substracts the mean of each trace (DC-level) | 
| Show channel numbers | __boolean__ Shows channel numbser left of the traces | 
| Show scale bar | __boolean__ Shows a scale bar in the upper left corner of the traces | 
| Narrow ephys padding | __boolean__ Decreases the vertical padding above and below the ephys traces | 
| Dynamic ephys range plot  | __boolean__ Alterns how the "range" plot style acts. In dynamic mode, the range style will only be applied for windows sizes larger 1.2s, otherwise all samples will be plotted. Matlab performs well up to a upper limit of simultaneously plotted samples (~1 second at 20KHz, 128 channels), after which it becomes significantly faster to plot a subset of the points.  | 
| Color ephys traces by channel order | Apply the colormap by channel order instead of by electrode groups. Select the number of color groups (1-50)  | 
| Change colormap of ephys traces | Change the colormap applied to the ephys traces (default to the electrode groups). | 
| Change colormap of spikes | Change the colormap applied to the spike rasters. | 
| Change background color & primary color (ticks, text and rasters) | Changes the color of the trace background (black) and the primary color (white; ticks, text, and rasters) | 
| Show detected events below traces | __boolean__ Shows detected events below traces. | 
| Show detected spikes below traces | __boolean__ Shows detected spike raster below traces. | 
| Debug | Toggle debug mode | 


### Help

| Elements                          | Description        | 
|:----------------------------------|:-------------------|
| Mouse and keyboard shortcuts      | Shows a window with the list of [mouse and keyboard shortcuts](https://cellexplorer.org/interface/neuroscope2-keyboard-shortcuts/) | 
| CellExplorer website              | Open the [CellExplorer website](https://cellexplorer.org/) in your browser | 
| About NeuroScope2                 | Open the [NeuroScope2 page](https://cellexplorer.org/interface/neuroscope2/) from the CellExplorer website in your browser | 
| Tutorial on metadata            | Open the [Session metadata tutorial](https://cellexplorer.org/tutorials/metadata-tutorial/) from the CellExplorer website in your browser | 
| Documentation on session metadata | Open the [session metadata documentation page](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) from the CellExplorer website in your browser | 
| Support | Opens the [CellExplorer website](https://cellexplorer.org/#support) describing support options | 
| Submit feature request | Submit a feature through the [CellExplorer GitHub issue system ](https://github.com/petersenpeter/CellExplorer/issues/new) | 
| Report an issue | Report an issue through the [CellExplorer GitHub issue system](https://github.com/petersenpeter/CellExplorer/issues/new)| 

