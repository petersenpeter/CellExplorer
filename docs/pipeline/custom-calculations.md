---
layout: default
title: Custom calculations
parent: Processing pipeline
nav_order: 5
---
# Custom calculations
{: .no_toc}
The Cell Explorer pipeline has a subfolder for calculations to exist outside the main pipeline, such that updates can be applied without affecting your own additions to the pipeline. Please save your scripts to the folder `+customCalculations/` and follow the template already in that folder to integrate your own calculations into the regular pipeline.

Your metrics has to follow the Cell Explorer [cell_metrics standard]({{"/datastructure/expandability/"|absolute_url}}). Any `events` or `manipulation` files located in the basepath will be detected in the pipeline and PSTHs will be generated automatically. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline. 

```m
function cell_metrics = template(cell_metrics,session,spikes,spikes_all)
    % This is a example template for creating your own calculations
    %
    % INPUTS
    % cell_metrics      cell_metrics struct
    % session           session struct with session-level metadata
    % spikes            spikes struct filtered by manipulation intervals
    % spikes_all        spikes struct with all spikes
    %
    % OUTPUT
    % cell_metrics      updated cell_metrics struct
end
```

Any of the standard file types (e.g. `events` or `manipulation` files) located in the basepath will be detected in the pipeline and an average PSTHs will be generated. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline.
