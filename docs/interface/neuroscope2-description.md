---
layout: default
title: UI elements
parent: NeuroScope2
grand_parent: Graphical interface
nav_order: 1
---

# UI elements
{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/11/NeuroScope2.png">![NeuroScope2](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot_lowress.jpg)</a>

### NeuroScope2 interface elements
The interface consists of a side panel and a main plot axis. Below the main axis are further navigational elements. The side-panel has three tabs: 
1. General (ephys raw traces, plotting styles and settings)
2. Spikes (spikes, cell metrics, and derived data), and 
3. Other (other data types and data analysis, including events, time series, states, behavior, spectrogram, RMS noise plot, and a Current Source density visualization). There are [keyboard shortcuts]({{"/interface/neuroscope2-keyboard-shortcuts/"|absolute_url}}) that allow you to quickly navigate your data. Press `H` in NeuroScope2 to see the keyboard shortcuts.

## General tab
### Navigation
The Navigation panel allows you can navigate and select which cell to display.
+ `Left arrow`: navigate to the next cell.
+ `Right arrow`: navigate to the previous cell.
+ `GoTo`: Opens a dialog box that allows you go to a specific cell, or session when visualizing a batch of sessions.
*Mouse actions in plots*
+ `Left mouse click`: Pan the plot around the location of the mouse cursor. In the 3D group plot a `Left mouse click` allows you to rotate the 3D plot.
+ `Mouse scroll wheel`: zoom in or out at the location of the mouse cursor.
+ `Middle mouse click`: go to nearest cell. 
+ `Right mouse click`: select nearest cell. Cell point/trace is highlighted and Cell ID is displayed for selected cell(s).


### Extracellular traces
% Loading and plotting ephys data
        % There are five plot styles, for optimized plotting performance
        % 1. Downsampled: Shows every 16th sample of the raw data (no filter or averaging)
        % 2. Range: Shows a sample count optimized for the screen resolution. For each sample the max and the min is plotted of data in the corresponding temporal range
        % 3. Raw: Raw data at full sampling rate
        % 4. LFP: .LFP file, typically the raw data has been downpass filtered and downsampled to 1250Hz before this. All samples are shown.
        % 5. Image: Raw data displayed with the imagesc function
        % Only data thas is not currently displayed will be loaded.
        
### Channel tags

### Session notes

### Session epochs

### Time series data
 
+ `Cell-type list`: You can assign/alter cell-type of the current cell by clicking a cell-type on the list. 
+ `O Polygon`: Perform cell classification on a group of cells by drawing a polygon circling the points in either of the scatter plots, waveforms, or ACGs. 
+ `+ Cell-type`: Allows you to add a new cell-type.
+ `Region`: Brain region assignment of the selected cell according to the Allan Institute Brain Atlas.
+ `Label`: Assign a label to the selected cell.

## Spikes tab

### Spikes

### Cell metrics

### Putative cell types

### List of cells

### Population dynamics

### Other spike sorting formats



## Other tab

### Events

### Time seris

### State


### States


### Behavior

### Spectrogram


### Current Source Density


### RMS noise inset


### Display Settings
The Display Settings panel allows you to customize the plots in CellExplorer. 
Cell-type list: Defines the displayed cell-types. 
Layout: Adjust the layout and number of cell specific plots to display: `1+3` -> `3+6`
1.-6. view: A drop-down menu for each of the cell plots containing available options like the *Firing rate map*, *tSNE plots*, *Sharp wave-ripple*, *Autocorrelograms*, *waveforms*,  all plots associated with the selected cell.

### Plot selection
The plot selection panel allows you to customize the first scatter plot, select what data to display, change the axis type, adjust the plotting style and the color groups.

`Plot style`: Allows you to alter the [custom plot]({{"/interface/group-plots/"|absolute_url}}): 1. 2D and 3D scatter plot. 2. 2D scatter plot with histograms. 3. Raincloud plot.

`Select X`,`Select Y` and `Select Z` data: Allows you to select what metrics that are displayed on the X,Y and Z axes respectively.

`Log X`, `Log Y` and `Log Z`: Define if a linear or log scale will be used for the X, Y and Z axes respectively.

`Show Z`: Whether to display the third axis.

`Select color group`: A drop-down menu with cell-array metrics, which allows you to group the cells according to these metrics including, Deep-Superficial, Brain regions and Labels. When selecting another option than cell-types, two new menu items appears below the drop-down that allows you to select a subset of groups in the scatter plots, and further combine this selection with a potential subset selection in Cell types.

`Group by cell-type`: Allows you to define a subset of cells that fulfills both the selection in cell-types and the selection in color group, but group the data according to cell types.

### Filter by free text
A filter field is located in the top left corner of the interface. You can filter by text strings or by specific criteria from numeric fields. You can further combine criteria by and/or logic e.g.:

Filter by text string "MS" and firing rate > 5 Hz: `MS & .firingRate > 5`.

Filter by MS or HIP: `MS | HIP`.

Filter by ab_ratio > 1 and troughToPeak > 0.6 ms: `.ab_ratio > 1 & .troughToPeak > 0.6`.

### Metrics table
The table contains all numeric values for the selected cell and is updated as you navigate the interface. The table can show two types of data: A list of cell metrics and associated values for the selected cell or a list of all cells with selection marker, and two other metrics. Use the menu Table data to customize what is displayed in the table.

### Message log
At the bottom of the interface, there is a message log showing details about the actions performed. You can click it to see the full list of commands with timestamps. 
