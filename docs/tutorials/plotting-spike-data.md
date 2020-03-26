---
layout: default
title: Plotting spike data
parent: Tutorials
nav_order: 6
---
# Tutorial on plotting spike raster data in the Cell Explorer
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Show spikes plots in the Cell Explorer
The Cell Explorer can show spike raster data using the `sessionName.spikes.cellinfo.mat` and related structures (`sessionName.*.events.mat` and `sessionName.*.manipulation.mat`). See the [file definitions here]({{"/datastructure/data-structure-and-format/"|absolute_url}}). Any `events` or `manipulation` files located in the basepath will be detected in the pipeline and PSTHs will be generated. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline. 

1. Launch the Cell Explorer
2. Select `Spikes`-> `Spike data menu` from the top menu (keyboard shortcut: `ctrl+a`). 
3. The spike data will be loaded and below dialog will be shown in the Cell Explorer.
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)
4. Now, if the listed spike plotting options are sufficient. Press OK to close the dialog.
5. This will add the spike plot options to the display settings dropdowns 
6. Select the sessions you want to load. You can apply filters, change the sorting for easier selection.
7. Select a spike plot options to display it.
8. If there are no spiking data available for the current session or selected cell the plot will be empty. This is also the case for sesisons without event files for event aligned raster plots. 

### Define spikes plots in the Cell Explorer
1. From the spike data dialog you can add, edit and delete spike plots. To add a new press the add button
2. Below dialog will be shown allowing you to create a spike plot defined by the parameters displayd. Simple raster plots are defined by the upper half of the fields. 
![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/addSpikePlot.png)
3. The dialog can be separated into 5 sections. 1. Plot title, 2. x,y,state data, 3. axis labels, 4. filter, and 5. events.
    1. Start by defining the name of the plot. This must fullfull the requirement of being a variable name.
    2. Next, define the fields to plot from the spikes struct. The X, Y and a state vector can be chosen (state functions as a method for applying color grouping to the data). 
    As an example, lets say you want to plot the spike amplitude across time. In the x-data selection column, select times. For the y-data select amplitudes. 
    3. Provide labels and press OK. This will create a new plot option looking like the third subplot in the figure at the bottom of this page.
    4. You can also define a data field to use as a filter. E.g. amplitude or speed. Select the field you want to use a filter, define the filter type (equal to, less than, greater than) and the threshold-value for the filter.
    5. You can also create PSTH-rasters using separate event data. Define the type of the event (events, manipulations, states files), the name of the events, .e.g. ripples, and the duration of the PSTH window (time before/after alignment). Next, define how to align the events (by onset, offset, center or peak). Each option must be available in the evnets files to be plotable, e.g. peak and offset, or be derivable from other fields, e.g. center (which can be determined from start and stop of intervals). 

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



