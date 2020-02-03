---
layout: default
title: Hippocampal metrics
parent: Tutorials
nav_order: 7
---
# Tutorial on hippocampal and spatial metrics (draft)
{: .no_toc}
This tutorial will guide you through providing the necessary input and understanding the outputs of the hippocampal and spatial calculations and metrics.

## Theta metrics

| Files        | Description |
|:-------------|:-------------|
| `sessionName.lfp` | LFP file|

| Metadata parameter | Description |
|:-------------|:--------------|
| `sessionName.theta.channelInfo.mat` | theta filtered channel | 

## Spatial metrics

| Files        | Description |
|:-------------|:------------|
| `firingRateMaps.firingRateMap.mat` | 1D firing rate map | 

## Deep superficial metrics

| Files        | Description |
|:-------------|:------------|
| `sessionName.ripples.events.mat` | Ripples events | 

| Metadata parameter | Description |
|:-------------|:-----------|
| `session.channelTags.Ripple.channels`|Ripple channel tag (required)|
| `session.analysisTags.probesLayout = 'staggered'`|Ripple channel tag (required;linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5)|
| `session.analysisTags.probesVerticalSpacing = 10; %`| Vertical spacing between sites (Required, [µm])|
| `session.channelTags.Bad.channels = 1;` | Bad channels (optional)|
| `session.channelTags.Cortical.electrodeGroups = 3;`| Cortical spike groups|
| `session.channelTags.Bad.electrodeGroups = 1;`| Bad electrode groups (Optional (broken shanks))|
