---
layout: default
title: Custom analysis
parent: NeuroScope2
grand_parent: Graphical interfaces
nav_order: 4
---

# Perform custom analysis directly from NeuroScope2
You can add your own custom functions that can be run from NeuroScope2 from the menu called Analysis. Basically, you have to create a wrapper for whatever function you want to call outside NeuroScope2. There are a lot of examples included, that you can take inspiration from.

## Organization of analysis tools and included functions 

The analysis menu and underlying `+analysis_tools` folder are organized according to the underlying data types of CellExplorer. Various functions are already included:
### behavior: 
   - 2D and 
   - 3D plot of behavior
   
### cell_metrics
   - run ProcessCellMetrics 
   - open CellExplorer
   - Plot metrics for a subset of cells, including CCGs and other built-in plots from CellExplorer

### events
   - detect ripples. Shows a dialog first, allowing for defining input parameters
### lfp
   - generate the .lfp file from the raw data

### session
   - Plot channel coordinates

### spikes
   - Detect monosynaptic connections
   - plot CCGs
   - plot spike-rasters

### states
   - Detect brain states (`SleepScoreMaster` - requires the Buzcode Matlab toolbox).
   - Edit brain states in (`TheStateEditor` - requires the Buzcode Matlab toolbox).
### timeseries
   - open StateExplorer

### traces
   - Plot correlation between channels
   - Plot RMS noise across channels
   - Show power spectral density across channels on a linear scale
   - Show power spectral density across channels on a log scale
   - Show temporal offsets between channels

The folders' purpose is purely for organization but they are hard-coded in NeuroScope2, so they should not be renamed. 

## Wrapper example provided

The wrapper example is located in the +traces folder ([`wrapper_example.m`](https://github.com/petersenpeter/CellExplorer/blob/master/%2Banalysis_tools/%2Btraces/wrapper_example.m)), use it to built your own analysis functions. 

```m
function out = wrapper_example(varargin)
% This is a wrapper example file for NeuroScope2. 
% Use this wrapper example to make calls from NeuroScope to any other analysis that can be applied to the traces, raw data or any derived data types.
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'ephys',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'UI',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

ephys = p.Results.ephys;
UI = p.Results.UI;  
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

% Your function content should go here

```
