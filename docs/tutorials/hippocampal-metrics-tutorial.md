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
**Files**
LFP file: `sessionName.lfp`

theta filtered channel: `sessionName.theta.channelInfo.mat`

**Metadata parameters**
Theta channel: `session.channelTags.Theta.Channels`

## Spatial metrics
**Files**
1D firing rate map: 'firingRateMaps.firingRateMap.mat'

## Deep superficial metrics
**Files**
Ripples events: 'sessionName.ripples.events.mat'

**Metadata parameters**
Ripple channel tag: `session.channelTags.Ripple.channels % Required` 

Probe layout: `session.analysisTags.probesLayout = 'staggered'; % Required (linear,staggered,poly2,poly 2,edge,poly3,poly 3,poly5,poly 5)`

Vertical spacing between sites: `session.analysisTags.probesVerticalSpacing = 10; % Required, [µm]`

Cortical spike groups: `session.channelTags.Cortical.electrodeGroups = 3;`

Bad channels: `session.channelTags.Bad.channels = 1; % Optional`

Bad electrode groups: `session.channelTags.Bad.electrodeGroups = 1; % Optional (broken shanks)`
