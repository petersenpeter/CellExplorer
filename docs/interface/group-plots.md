---
layout: default
title: Group plots
parent: Graphical interface
nav_order: 3
---
# Group plots (draft)
{: .no_toc}
The top panel row in the Cell Explorer interface is dedicated to population level representations of the cells, and consists of three main plots shown below.

![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/groupPlots-1.png){: .mt-4}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Custom group plot
The custom group plot has three overall plotting methods.
1. 2D and 3D scatter plot.
2. 2D scatter plot with histograms.
4. Raincloud plot.

![](https://buzsakilab.com/wp/wp-content/uploads/2020/02/groupPlotsOther-1.png){: .mt-4}

## Classical separation plot
One of the most common ways to visualize putative cell types is the trough-to-peak vs the burstiness. putative PV cells (narrow waveform interneurons) separate very nicely from pyramical cells due to their narrow waveforms. The wide waveform interneurons are less clearly captured by these measures and show a continues overlap with both the narrow interneurons and the pyramidal cell population. In the Cell Explorer pipeline, the separation of interneurons from pyramidal cells  determined by the width of the waveforms and the shape of the ACG, which is captured by multiple parameters.

## t-SNE plot
The t-SNE plot takes any number of metrics and projects them to a 2-D t-SNE space. You can define the features to use for the separation from both the settings but also in the Cell Explorer. In the Cell Explorer you can define both single numeric features, as well as waveforms, response curves, ACGs and ISIs and other available single cell features. Further t-SNE settings can be set in the t-SNE dialog as well. Alter the t-SNE metrics from the top menu by going to `View` -> `Change metrics used for t-SNE plot`. This will bring up a dialog allowing you to select features and settings. Besides t-SNE, two other algorithm are also available for dimensionality reduction: PCA and [UMAP](https://umap-learn.readthedocs.io/en/latest/) (Uniform Manifold Approximation and Projection). 
