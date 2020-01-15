---
layout: default
title: UI elements
parent: Graphical interface
nav_order: 1
---
# Details on the graphical interface
{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-Interface-description-1.png)
### Graphical elements
The interface consists of 4-9 main plots, where the top row is dedicated to population level representations of the cells and the other plots are [selectable and customizable plots for individual cells]({{"/interface/single-cell-plot-options/"|absolute_url}}) (including variations of waveforms, ACGs, ISIs, CCGs, PSTHs, response curves and firing rate maps). The surrounding interface consists of 7 panels placed on either side of the graphs: On the right side there is a navigation panel, cell assignment panel, display settings panel, and on the left side a plot selection panel, color group panel and a table with cell metrics. The panels are described in details below. Further there is a text field for custom text filter, a message log and figure legends. There are [keyboard shortcuts]({{"/interface/keyboard-shortcuts/"|absolute_url}}) that allow you to quickly navigate your data. Press H in the cell Explorer to learn Keyboard shortcuts.

### Navigation and cell selection
The Navigation panel allows you can navigate and select which cell to display.
+ Right arrow: navigate to the next cell (n+1).

+ Left arrow: navigate to the previous cell (n-1).

+ GoTo: Opens a dialog box that allows you go to a specific cell number or to a specific session, when visualizing a batch of sessions.

*Mouse actions in plots*
+ *Left mouse click*: go to nearest cell. 
+ *Right mouse click*: select nearest cell. Cell point/trace is highlighted and Cell ID is displayed for selected cell(s).
+ *Middle mouse click*: activate a group selection function allowing you to draw a polygon (with left mouse clicks) to select multiple cells (finish with a right mouse click; delete points with middle mouse click).
+ *Mouse scroll wheel*: zoom in or out at the location of the mouse cursor. When zooming on one of the axis, only that dimension is zoomed. 

### Cell Assignment
The Cell Assignment panel allows you to perform relevant types of cell-assignments such as cell-type, Deep/Superficial, assign Brain region or Labels.

+ Cell-type list: You can assign/alter cell-type of the current cell by clicking a cell-type on the list. 

+ O Polygon: Perform cell classification on a group of cells by drawing a polygon circling the points in either of the scatter plots, waveforms, or ACGs. 

+ + Cell-type: Allows you to add a new cell type.

+ Region: Brain region assignment of the selected cell according to the Allan Institute Brain Atlas.

+ Label: Assign a label to the selected cell. Labels are saved to the cell_metrics structure.

### Display Settings
The Display Settings panel allows you to customize the plots in the Cell Explorer. 
Cell-type list: Defines the displayed cell-types. 
Layout: Adjust the layout and number of cell specific plots to display: 1+3 -> 3+6
1.-6. view: A dropdown for each of the cell plots containing available options like the Firing rate map, tSNE plots, Sharp wave-ripple, Autocorrelogram, waveform,  all plots associated with the selected cell.

ACGs: display selected, all or a t-SNE scatter plot of ACGs.

MonoSyn: [None/Selected/All] Display monosynaptic connections for selected cell or for all cells. All: all connections are highlighted in black in the top row scatter plots. Selected: for the selected cell, the ingoing connections are shown with black lines, the outgoing in magenta. The synaptic connected partners' curves are also displayed in the custom plot.

Display synaptic connections: You can select in which of the plots you want the mono-synaptic connections displayed, using the toggles for the three main scatter plots.

### Plot selection
The plot selection panel allows you to customize the first scatter plot, select what data to display, change the axis type, adjust the plotting style and the color groups.

Select X,Y and Z data: Allows you to select what metrics that are displayed on the X,Y and Z axes respectively.

Log X, Y and Z: Define if a linear or log scale will be used for the X, Y and Z axes respectively.

Show Z: Whether to display the third axis.

Select plot style: Allows you to display a double histogram along the X and Y axes. A smooth or a stairs histogram can be selected. Only the X and Y axes are displayed here.

Select color group: A dropdown menu with cell-array metrics, which allows you to group the cells according to these metrics including, Deep-Superficial, Brain regions and Labels. When selecting another option than cell-types, two new menu items appears below the dropdown that allows you to select a subset of groups in the scatter plots, and further combine this selection with a potential subset selection in Cell types.

Group by cell-type: Allows you to define a subset of cells that fulfills both the selection in cell-types and the selection in color group, but group the data according to cell types.

### Filter by free text
A filter field is located in the top left corner of the interface. You can filter by text strings or by specific criteria from numeric fields. You can further combine criteria by and/or logic e.g.:

Filter by text string "MS" and firing rate > 5Hz: 
#+BEGIN_EXAMPLE
MS & .firingRate > 5
#+END_EXAMPLE

Filter by MS or HIP:
#+BEGIN_EXAMPLE
MS | HIP
#+END_EXAMPLE

Filter by ab_ratio > 1 and troughToPeak > 0.6ms
#+BEGIN_EXAMPLE
.ab_ratio > 1 & .troughToPeak > 0.6
#+END_EXAMPLE

### Metrics table
The table contains all numeric values for the selected cell and is updated as you navigate the interface. The table can show two types of data: A list of cell metrics and associated values for the selected cell or a list of all cells with selection marker, and two other metrics. Use the menu Table data to customize what is displayed in the table.

### Message log
At the bottom of the interface, there is a message log showing details about the actions performed. You can click it to see the full list of commands with timestamps. 
