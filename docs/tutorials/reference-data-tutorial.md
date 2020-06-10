---
layout: default
title: Reference data
parent: Tutorials
nav_order: 8
---
# Tutorial on reference data
{: .no_toc}
The Buzsaki lab is sharing a large set of datasets and a large set of these sessions are also shared with cell metrics that can be downloaded and displayed directly in CellExplorer. Learn more about our public data [here](https://buzsakilab.com/wp/2018/10/29/public-datasets/). This tutorial will guide you through the process of using reference data in the manual curation process and for comparison with your own data.

1. Launch CellExplorer
2. Select `Reference data`-> `Define reference data` from the top menu. Below dialog will be shown in CellExplorer.
![CellExplorer database dialog](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-database-dialog-1.png){: .mt-4}
3. Select the sessions you want to load. You can apply filters, change the sorting for easier selection. All data located at the repository `NYUshare_Datasets` are publicly available and will be downloaded to your computer upon request. For sessions located on private data repositories, you have to specify the local path the the repository in the file `db_local_repositories`
4. Press OK and the sessions will be loaded from the repository paths to the local CellExplorer directory `referenceData/`. Session on **NYUshare_Datasets** will be downloaded automatically to the same directory. 
5. The reference data can be displayed in CellExplorer in three ways (all color coded by cell types):
   1. Image data: 2d colored density map (panel B in figure below. Panel A shows the data regular data representation without reference data).
   2. Scatter data: scatter points `x` (panel C in figure below).
   3. Histogram data: histogram curves along x and y axes (panel D in figure below). 
6. You can define the number of bins, and which of the reference cell types to display. You can select which of the reference cell types to display in the Display Settings tab group `Reference`

Once a selection has been made, you can skip step 2 and 3. The reference data is not displayed in the t-SNE plot. The video below shows the steps in CellExplorer:

<video width="100%" height="auto" controls="controls">
  <source src="https://buzsakilab.com/wp/wp-content/uploads/2020/01/ReferenceDataTutorial.mp4" type="video/mp4">
</video>

Below figure shows the various ways to plot reference data in CellExplorer:
![Reference data](https://buzsakilab.com/wp/wp-content/uploads/2020/01/referenceData_noRef.png){: .mt-4}