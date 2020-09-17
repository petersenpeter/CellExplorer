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

This was inspired by previous papers from our lab (Sirota et al., Neuron 2008; Stark et al., Neuron 2013; Senzai and Buzsaki, Neuron 2017; English et al., Neuron 2017; Senzai et al., Neuron 2019), where the autocorrelogram fits supplement the classical separation approach based on spike waveform features.

Pyramidal cells have a very narrow waveform, are typically bursty with an average firing rate below 2Hz. PV and SST cells have a more narrow waveform, a higher base firing rate and are much less likely to burst during physiological in vivo regime.

The wide waveform interneurons (VIP) are harder to distinquish from pydamidal cells. Here we introduce the autocorrelogram as a dimension for capturing this difference. Autocorrelograms are fitted with a triple-exponential equation:
$$ACG_{fit} = max(c\exp(\frac{-(x-t_{refrac})}{\tau_{decay}})-d\exp(\frac{-(x-t_{refrac})}{\tau_{rise}})+h\exp(\frac{-(x-t_{refrac})}{\tau_{burst}})+rate_{asymptote},0)$$

To support this separation we have included ground truth opto-tagged interneurons into CellExplorer (PV, SST and VIP) and further verified cell types (excitatory vs inhibitory cells) by the monosynaptic connections...
