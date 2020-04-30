---
layout: default
title: Export figure
parent: Tutorials
nav_order: 11
---
# Tutorial on exporting CellExplorer figures
{: .no_toc}
Exporting figures in Matlab can be a headache, so here are two small tutorials to help with this: exporting the main interface and individual actions plots.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Exporting the CellExplorer interface
The steps below shows how to save a PDF file of the main interface of the CellExplorer. Saving a PNG (image file) is more straight forward. 

1. Launch the CellExplorer
2. Select `File`-> `Export figure` from the top menu. This will open a [Export Setup dialog](https://www.mathworks.com/help/matlab/ref/exportsetupdlg.html). Before the dialog is shown the paper size is set to the current figure size and the renderer is set to painter.
3. Use the left side _Properties_ menu to navigate the exporting dialog and apply below settings:
  * __Fonts__: We recommend a minimum font size of 14 to minimize further editing.
  *  __Rendering__: Check `Custom renderer` and select `painter` from the drop-down menu. Rendering has already been set to `painter` and it should not be necessary to change it. 
4. If you altered any settings, click the button `Apply to Figure`.
5. Click the button `Export...` to bring up the Save As dialog to specify location and file name. 

When applying the settings to the figure (`Apply to Figure`), the figure sometimes resizes to a smaller initial size. Just resize the figure back to the full size before clicking `Export`.

If the export figure dialog is not sufficient for your need, you can bring up the main figure menu by pressing `m`.

Following the tutorial should provide you with a .pdf figure, looking like the figure below:
![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2019/11/CellExplorer-example.png)

## Exporting figures using the action dialog
1. Select a set of cells, using the mouse and open the actions dialog (press `space` or the `Actions` button in the right panel). If no cell selection is done beforehand, a cell selection dialog will be shown first: 
    <p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/CellExplorer-group-action-dialog.png" width="70%"></p>
2. Select one of the three `MULTI PLOT OPTIONS` in the actions dialog and press OK.
3. In the multi plot dialog shown below, select the plots to generate, check the `Save figures` toggle, and define file format (.png or .pdf) and file path (Save to the clustering paths, to the CellExplorer path or a user defined path). :
<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/CellExplorer-group-action-multiplot-dialog.png" width="70%"></p>

When you select to save your figures to the CellExplorer path or Clustering path, they will be saved to a subfolder named `summaryFigures`. 

Be aware that saving pdf files, is substantial slower than saving png files, but the figures will be saved with vector graphics.

## Exporting remaining figures
Any other figures produced by the CellExplorer can be saved using the File menu options `Save As` or `Export Setup...`.
