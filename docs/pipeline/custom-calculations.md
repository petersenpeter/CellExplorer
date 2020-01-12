---
layout: default
title: Custom calculations
parent: Running pipeline
nav_order: 4
---
The Cell Explorer pipeline has a subfolder for calculations to exist outside the main pipeline, such that updates can be applied without affecting your own additions to the pipeline. Please save your scripts to the folder calc_CellMetrics/+customCalculations/ and follow the template already in that folder to integrate your own calculations into the regular pipeline.

Your metrics has to follow the Cell Explorer "cell_metrics standard":https://github.com/petersenpeter/Cell-Explorer/wiki/Adding-your-own-metrics.

<pre><code>function cell_metrics = template(cell_metrics,session,spikes,spikes_all)
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
    
   
end</code></pre>