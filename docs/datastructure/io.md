---
layout: default
title: Data structure and format
parent: Data structure
nav_order: 2
---
# Data loaders
{: .no_toc}

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Raw data
CellExplorer supports raw binary data files (.dat files). This format is also supported by IntanTech, OpenEphys, KiloSort, Phy, NeuroSuite, Spyking Circus, NeuroSuite, Klustakwik, and many other tools.

data = LoadBinary

## LFP data
CellExplorer also uses a basename.lfp file - A low-pass filtered and down-sampled raw data file for lfp analysis (for efficient data analysis and data storage; typically down-sampled to 1250Hz). The lfp file is automatically generated in the pipeline from the raw data file - using the script ce_LFPfromDat). The sampling rate is specified in the session struct (session.extracellular.srLfp). The LFP file has the same channel count and scaling as the dat file.

data = LoadBinary

## General functions
loadStruct

saveStruct
saveStruct(chanCoords,'channelInfo','session',session);


## Analog traces

loadIntanAnalog

## Digital data

loadIntanDigital

loadOpenEphysDigital
## Session metadata
sessionTemplate
loadSession
gui_session


The session struct can be generated using the sessionTemplate.m and inspected with gui_session.m. The basename.session.mat files should be stored in the basepath. It is structured as defined below:


## Spikes
A MATLAB struct spikes stored in a .mat file: basename.spikes.cellinfo.mat. It can be generated with loadSpikes.m. The processing module ProcessCellMetrics.m used the script loadSpikes.m, to automatically load spike-data from either KiloSort, Phy or Neurosuite and saves it to a spikes struct. basename.spikes.cellinfo.mat is saved to the basepath. The struct has the following fields:

loadSpikes.m
spikes = loadSpikes('session',session);
spikes = getWaveformsFromDat(spikes,session);


Load spikes takes spike sorted formats from various algorithms:

## Monosynaptic connections 
mono_res = ce_MonoSynConvClick(spikes,'includeInhibitoryConnections',true/false); % detects the monosynaptic connections
gui_MonoSyn(mono_res) % Shows the GUI for manual curation


## Cell metrics
loadCellMetrics

bsasepaths = {'sessionName1','sessionName2','sessionName3'};
cell_metrics = loadCellMetricsBatch('basepaths',bsasepaths);

nwb = saveCellMetrics2nwb(cell_metrics,nwb_file);

saveCellMetrics(cell_metrics,nwb_file)

cell_metrics = ProcessCellMetrics('session', session);


## Events
This is a data container for event data. A MATLAB struct eventName stored in a .mat file: basename.eventName.events.mat with the following fields:

loadEvents

## Manipulations


## Channels

## Time series

StateExplorer

## States

## Behavior
This is a data container for behavioral tracking data. A MATLAB struct behaviorName stored in a .mat file: basename.behaviorName.behavior.mat with the following fields:

loadOptitrack

## Trials
A MATLAB struct trials stored in a .mat file: basename.trials.behavior.mat. The trials struct is a special behavior struct centered around behavioral trials. trials has the following fields:


## Firing rate maps
This is a data container for firing rate map data. A MATLAB struct ratemap containing 1D or linearized firing rat maps, stored in a .mat file: basename.ratemap.firingRateMap.mat. The firing rate maps have the following fields:

## Intracellular time series
This is a data container for intracellular recordings. Any MATLAB struct intracellularName containing intracellular data would be stored in a .mat file: basename.intracellularName.intracellular.mat. It contains fields inherited from timeSeries with the following fields
