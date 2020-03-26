---
layout: default
title: Plotting spike data
parent: Tutorials
nav_order: 9
---
# Tutorial on plotting spike raster data in the Cell Explorer
{: .no_toc}


## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Defining spikes plots in the Cell Explorer
The Cell Explorer can show spike raster data using the `sessionName.spikes.cellinfo.mat` and related structures (`sessionName.*.events.mat` and `sessionName.*.manipulation.mat`). See the [file definitions here]({{"/datastructure/data-structure-and-format/"|absolute_url}}). Any `events` or `manipulation` files located in the basepath will be detected in the pipeline and PSTHs will be generated. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline. 

1. Launch the Cell Explorer
2. Select `Spikes`-> `Spike data menu` from the top menu (keyboard shortcut: `ctrl+a`). 
3. The spike data will be loaded and below dialog will be shown in the Cell Explorer.
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)
4. 
4. Select the sessions you want to load. You can apply filters, change the sorting for easier selection.
5. Press OK and the sessions will be loaded.

![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)


## Predefine spikes plots
You can define spike raster plots directly in the Cell Explorer using above dialog, or you can save custom plots that are loaded automatically in the Cell Explorer every time. Custom spikes plots are located at `+customSpikesPlots/`. There is a spikes_template available to get you started: 
```m
function spikePlot = spikes_template
% This is a example template for creating your own custom spike raster plots
%
% OUTPUT
% spikePlot: a struct containing all settings

% Spikes struct parameter
spikePlot.x = 'pos_linearized';             % x data
spikePlot.y = 'theta_phase';                % y data
spikePlot.x_label = 'Position (cm)';        % x label
spikePlot.y_label = 'Theta phase';          % y label
spikePlot.state = '';                       % state data [ideally integer]
spikePlot.filter = 'speed';                 % any data used as filter
spikePlot.filterType = 'greater than';      % [none, equal to, less than, greater than]
spikePlot.filterValue = 20;                 % filter value

% Event related parameters (if applicable)
spikePlot.event = '';
spikePlot.eventType = 'events';              % [events,manipulation,states]
spikePlot.eventAlignment = 'peak';          % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';       % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;             % in seconds
spikePlot.eventSecAfter = 0.2;              % in seconds
spikePlot.plotRaster = 0;                   % [binary] show raster
spikePlot.plotAverage = 0;                  % [binary] show average response
spikePlot.plotAmplitude = 0;                % [binary] show amplitude for each event on a separate y-axis plot
spikePlot.plotDuration = 0;                 % [binary] show event duration for each event on a separate y-axis plot
spikePlot.plotCount = 0;                    % [binary] show spike count for each event on a separate y-axis plot
end
```

## Examples of spikes plots
Below figure shows three raster plot examples 1. Phase vs position, 2. trials vs position and 3. spike amplitude vs time. 
![Rasters](https://buzsakilab.com/wp/wp-content/uploads/2019/12/spikeRaster.png)



