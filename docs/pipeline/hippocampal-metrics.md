---
layout: default
title: Hippocampal metrics
parent: Processing module
nav_order: 8
---
# Hippocampal and spatial metrics
{: .no_toc}
Hippocampal and spatial metrics depends on specific files and metadata to be processed the pipeline.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Theta metrics
A theta-band filtered time series is generated from the lfp file. Continues theta power and phase is then calculated from the generated time series. For each unit the average theta firing profile is calculated together with the theta phase peak/trough and the strength of the theta entrainment. [Learn more about theta oscillation metrics](/datastructure/standard-cell-metrics/#theta-oscillation-metrics). The tracking file is used for filtering by a minimum running speed.

| Files        | Description  |
|:-------------|:-------------|
| `sessionName.lfp` | LFP file |
| `sessionName.InstantaneousTheta.channelInfo.mat` | theta filtered channel |
| `sessionName.animal.behavior.mat` | behavioral tracking file |

| Metadata parameter | Description |
|:-------------|:-----------|
| `session.channelTags.Theta.channels`| Theta channel tag (required) |

## Spatial metrics
All spatial metrics are generated from an existing 1D firing rate map. [Learn more about spatial metrics](/datastructure/standard-cell-metrics/#spatial-metrics) and the [firing rate map Matlab struct](/datastructure/data-structure-and-format/#firing-rate-maps). 

| Files        | Description |
|:-------------|:------------|
| `firingRateMaps.firingRateMap.mat` | 1D firing rate map | 

## Deep-superficial metrics
Deep-superficial metrics are calculated from ripple timestamps and the average ripple is extracted from a channel from the lfp file. A reveral point for the polarity of the sharp wave is derived from a time interval before the average ripple, aligned to their peaks. Deep-superficial distance is estimmated from the reversal point by assigning a numeric value determined from the channel offset to the reversal point.

[Learn more about deep-superficial metrics](/datastructure/standard-cell-metrics/#sharp-wave-ripple-metrics), and see the tutorial [here]({{"/tutorials/deep-superficial-tutorial"|absolute_url}}).

| Files        | Description |
|:-------------|:------------|
| `sessionName.lfp` | LFP file (generated in the processing module) |
| `sessionName.ripples.events.mat` | Ripples events (generated in the processing module) | 
| 'sessionName.deepSuperficialfromRipple.channelinfo.mat' | Ripples events (generated in the processing module) | 


| Metadata parameter | Description |
|:-------------|:-----------|
| `session.channelTags.Ripple.channels`| Ripple channel tag (required) |
| `session.analysisTags.probesLayout`| Ripple channel tag (required; linear,staggered,poly2, edge,poly3,poly5)|
| `session.analysisTags.probesVerticalSpacing`| Vertical spacing between sites (required, [µm]) |
| `session.channelTags.Bad.channels` | Bad channels |
| `session.channelTags.Bad.electrodeGroups`| Bad electrode groups (e.g. broken shanks) |
| `session.channelTags.Cortical.electrodeGroups`| Cortical spike groups |


