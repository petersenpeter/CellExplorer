---
layout: default
title: Use public data as reference data
parent: Database
nav_order: 3
---
# Public data
{: .fs-9 }
We are sharing a large set of cells that is available to explore or use as reference data for classifying your own data. Any sessions located in the repository **NYUshare_Datasets** is publicly available and can be downloaded and loaded automatically in the Cell Explorer, without providing any database credentials. Upon request the data will be downloaded from our [public web share](https://buzsakilab.nyumc.org/datasets/) and saved to the local Cell Explorer directory `referenceData/` for future access.

1. Launch the Cell Explorer
2. Select `Reference data`-> `Define reference data` from the top menu. Below dialog will be shown in the Cell Explorer.
![Cell Explorer database dialog](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-database-dialog-1.png)
4. Select the sessions you want to load. You can apply filters, change the sorting for easier selection.
5. Press OK and the sessions will be loaded from the repository paths to the local Cell Explorer directory `referenceData/`. Session on **NYUshare_Datasets** will be downloaded automatically to the same directory. 
6. The reference data can be displayed in the Cell Explorer in three ways (all color coded by cell types):
   1. Image data: 2d colored density map (panel A in the figure below).
   2. Scatter data: scatter points `x` (panel B in the figure below).
   3. Histogram data: histogram curves along x and y axes (panel C in the figure below). 
![referenceDataPlotExamples](https://buzsakilab.com/wp/wp-content/uploads/2020/01/referenceDataPlotExamples.png)

The reference data is not displayed in the t-SNE plot. 
