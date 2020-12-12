---
layout: default
title: Public data
has_children: true
nav_order: 5
---
<style type="text/css">
    ol { list-style-type: upper-alpha; }
</style>
# Data access
{: .no_toc}
We are sharing a variety of data from behaving rats and mice. Combined more than 70.000 cells are available to explore or use as reference data for classifying your own data. The cells are primarily from the Hippocampus and visual cortex but also from many other brain regions. CellExplorer achieves this by communicating with the [Buzsaki lab databank](https://buzsakilab.com/wp/database/). The public data in the databank can be downloaded and loaded as reference data without login credentials. Credentials are necessary for having full access and writing capabilities. We are also sharing "ground truth data", which are hundreds of opto-tagged cell types from several mouse lines. 
* [Learn more about the Buzsaki lab databank](https://buzsakilab.com/wp/database/). 
* [Tutorial on using reference data in CellExplorer](/tutorials/reference-data-tutorial/).
* [Learn more about our ground truth data](/database/ground-truth-data/).
* [Setup access to the databank](/database/preparation/).

# Download and use data in CellExplorer
Any sessions located in the repository **NYUshare_Datasets** is publicly available and can be downloaded and loaded automatically in CellExplorer, without database credentials. Upon request the data will be downloaded from our [public web share](https://buzsakilab.nyumc.org/datasets/) and saved to the local CellExplorer directory `referenceData/` for future access. Be patient when downloading the data as some sessions are very large (spanning a few to hundreds of MB). Once data has been loaded as reference data, you can directly explore the reference data by selecting __Explore reference data__ from the Reference data menu in CellExplorer.

![Reference data dialog](https://buzsakilab.com/wp/wp-content/uploads/2020/12/referenceDataDialog.png)

## Plotting options
The various plotting options for the reference data. A. A representation of a session without reference data. B. Image data: 2-D colored density map. C. Scatter data: scatter points `x`. D. Histogram data: histogram curves along x and y axes.

![Reference data representations](https://buzsakilab.com/wp/wp-content/uploads/2020/01/referenceData_noRef.png)

 


