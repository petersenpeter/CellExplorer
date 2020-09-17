---
layout: default
title: Cell-type classification
parent: Processing module
nav_order: 3
---
# Cell-type classification
In the processing pipeline, cells are classified into three putative cell types: **Narrow Interneurons, Wide Interneurons and Pyramidal Cells**.
  * Interneurons are selected by 3 separate criteria:
  1. acg_tau_decay > 30 ms
  2. acg_tau_rise > 3 ms
  3. troughToPeak <= 0.425 ms
  * Next interneurons are separated into two classes
  1. Narrow interneuron assigned if troughToPeak <= 0.425 ms
  2. Wide interneuron assigned if troughToPeak > 0.425 ms
  * Remaining cells are assigned as Pyramidal cells. 

