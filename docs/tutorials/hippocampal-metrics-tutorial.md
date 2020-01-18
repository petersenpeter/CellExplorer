---
layout: default
title: Hippocampal metrics
parent: Tutorials
nav_order: 7
---
# Tutorial on generating hippocampal and spatial metrics (draft)
{: .no_toc}
This tutorial will guide you through providing the necessary input and understanding the outputs.

## Theta metrics
**Files**
LFP file: `sessionName.lfp`

theta filtered channel: `sessionName.theta.channelInfo.mat`

**Metadata parameters**
`session.channelTags.Theta.Channels`

## Spatial metrics
**Files**
1D firing rate map: 'firingRateMaps.firingRateMap.mat'

## Deep superficial metrics
**Files**
Ripples events: 'sessionName.ripples.events.mat'

**Metadata parameters**
Ripple channel tag: `session.channelTags.Ripple.channels % Required` 

`session.analysisTags. % Required`

`session.channelTags.Cortical.channel % Optional`

`session.channelTags.Bad.channel % Optional`
