---
layout: default
title: Group plots
parent: Graphical interface
nav_order: 3
---
# Group plots (draft)
{: .no_toc}
The top panel row in the Cell Explorer interface is dedicated to population level representations of the cells, and consists of three main plots described below.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Custom group plot
The custom group plot has four overall plotting methods
1. Scatter plot (2D or 3D)
2. Scatter plot with smooth histograms (2-D only)
3. Scatter plot with stairs histograms (2-D only)
4. Raincloud plot

## Classical separation plot
One of the most common ways to visualize putative cell types is the trough-to-peak vs the burstiness. putative PV cells (narrow waveform interneurons) separate very nicely from pyramical cells due to their narrow waveforms. The wide waveform interneurons are less clearly captured by these measures and show a continues overlap with both the narrow interneurons and the pyramidal cell population. In the Cell Explorer pipeline, the separation of interneurons from pyramidal cells  determined by the width of the waveforms and the shape of the ACG, which is captured by multiple parameters.

## t-SNE plot
The t-SNE plot takes any number of metrics and projects them to a 2-D t-SNE space. You can define the features to use for the separation from both the settings but also in the Cell Explorer. In the Cell Explorer you can define both single numeric features, as well as waveforms, response curves, ACGs and ISIs and other available single cell features. Further t-SNE settings can be set in the t-SNE dialog as well. Alter the t-SNE metrics from the top menu by going to `View` -> `Change metrics used for t-SNE plot`. This will bring up a dialog allowing you to select features and settings. Besides t-SNE, two other algorithm are also available for dimensionality reduction: PCA and [UMAP](https://umap-learn.readthedocs.io/en/latest/) (Uniform Manifold Approximation and Projection). 
