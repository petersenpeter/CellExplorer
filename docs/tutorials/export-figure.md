---
layout: default
title: Export figure
parent: Tutorials
nav_order: 11
---
# Tutorial on exporting Cell Explorer figures
{: .no_toc}
Exporting figures in Matlab can be a headache, so here is a small tutorial to help with this. The steps below shows how to save a PDF file of the main interface of the Cell Explorer. Saving a PNG (image file) is more straight forward. 

1. Launch the Cell Explorer
2. Select `File`-> `Export figure` from the top menu. This will open a [Export Setup dialog](https://www.mathworks.com/help/matlab/ref/exportsetupdlg.html). Before the dialog is shown the paper size is set to the current figure size and the renderer is set to painter.
3. Use the left side _Properties_ menu to navigate the exporting dialog and apply below settings:
   __Fonts__: We recommend a minimum font size of 14 to minimize further editing.
   __Rendering__: Check _Custom renderer_ and select _painter_ from the drop-down menu Rendering has already been set to _painter_ and it should not be necessary to change it.
4. Click the button _Apply to Figure_ to apply the changes to the figure.
5. Click the button _Export..._ to bring up the Save As dialog to specify location and file name. 

If the export figure dialog is not sufficient for your need, you can bring up the main figure menu by pressing `m`. 

When applying the settings to the figure (_Apply to Figure_), the figure sometimes resizes to a smaller initial size. Just resize the figure back to the full size before clicking _Export_. 

Any other figures produced by the Cell Explorer can be saved in similar fashion using the File menu options _Save As_ or _Export Setup..._.
https://www.mathworks.com/help/matlab/ref/exportsetupdlg.html