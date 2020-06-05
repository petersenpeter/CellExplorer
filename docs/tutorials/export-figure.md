---
layout: default
title: Export figure
parent: Tutorials
nav_order: 11
---
# Tutorial on exporting CellExplorer figures
{: .no_toc}
Exporting figures in Matlab can be a headache, so CellExplorer have two built-in figure exporting options: exporting the main interface and individual actions plots.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Exporting the CellExplorer interface
The steps below shows how to save a PDF file of the main interface of CellExplorer. Saving a PNG (image file) is more straight forward, but the same steps can be applied. 

1. Launch CellExplorer
2. Select `File`-> `Export figure` from the top menu. This will open a [Export Setup dialog](https://www.mathworks.com/help/matlab/ref/exportsetupdlg.html). Before the dialog is shown the paper size is set to the current figure size and the renderer is set to painter.
3. Use the left side _Properties_ menu to navigate the exporting dialog to apply further optional settings:
  * __Fonts__: We recommend a minimum font size of 14 to minimize further editing.
  *  __Rendering__: Exporting to raster or vector graphics is defined in the ab `Custom renderer` and select `painter` (vector graphics) from the drop-down menu. The rendering has already been set to `painter` and it should not be necessary to change it.
4. If you altered any settings, click the button `Apply to Figure`.
5. Click the button `Export...` to bring up the Save As dialog to specify location, file name and format 

When applying settings to the figure (`Apply to Figure`), the figure sometimes resizes to a smaller size. To fix this, just resize the figure back to the full size before clicking `Export`.

If the export figure dialog is not sufficient for your need, you can bring up the main figure menu by pressing `m`.

By following above tutorial you should end up with an exported figure like shown in below image:
![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-example.png)

## Exporting figures using the action dialog
1. Select a set of cells, using the mouse and open the actions dialog (press `space` or the `Actions` button in the right panel). If no cell selection is done before opening the action dialog, a cell selection dialog will be shown first: 
    <p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-dialog.png" width="70%"></p>
2. Select one of the three `MULTI PLOT OPTIONS` in the actions dialog and press OK.
3. In the multi plot dialog shown below, select the plots to generate, check the `Save figures` toggle, and define file format (.png or .pdf) and file path (Save to the basepaths, to the CellExplorer path or a user defined path):
<p align="center"><img src="https://buzsakilab.com/wp/wp-content/uploads/2019/12/Cell-Explorer-group-action-multiplot-dialog.png" width="70%"></p>

When you select to save your figures to the CellExplorer path or basepath, they will be saved to a subfolder named `summaryFigures`.

Be aware that saving to a pdf file, is substantial slower than saving a .png file, but the figure will be saved with vector graphics.

## Exporting other figures
Any other figures produced by CellExplorer can be saved using the File menu options `Save As` or `Export Setup...`.
