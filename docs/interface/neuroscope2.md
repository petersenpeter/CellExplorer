---
layout: default
title: NeuroScope2
parent: Graphical interface
nav_order: 9
---
{: .no_toc}
# NeuroScope2 (beta)
NeuroScope2 is a data viewer for raw and processed extracellular data acquired using multisite silicon probes, tetrodes or single wires. It is written in Matlab, maintaining many of the original functions of [NeuroScope](http://neurosuite.sourceforge.net/), but with many enhancements. It can be used to explore existing data and to live stream data being collected and can handle multiple data streams simultaneously - e.g. digital, analog, and aux channels from Intan - together with the raw ephys data. As NeuroScope is written in MATLAB, it is hackable, adaptable and easily expandable. It is much faster than the original NeuroScope, and functions fully within the data types of CellExplorer, using the `session` struct for metadata.

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot.png">![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot_lowress.jpg)</a>

{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Features
The interface is user-friendly, with a single side panel for accessing most functions. You can zoom, navigate, measure, highlight, and select traces directly with your mouse cursor, making manual inspection very intuitive and efficient. NeuroScope2 can also perform basic data processing (that works on a live data stream as well), e.g. bandpass filter traces, perform temporal smoothing, perform spike and events detection directly on the raw or processed traces. Channel tags can be used to highlight and filter (+/-) channels.

You can view CellExplorer, Buzcode, and other .mat structures:
* [Session metadata](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata)
* [spikes](https://cellexplorer.org/datastructure/data-structure-and-format/#spikes): plot spike rasters on the ephys traces or separately below the traces.
* [cell metrics](https://cellexplorer.org/datastructure/standard-cell-metrics/): use cell metrics to filter, group or sort cells (see example screenshot below).
* [events](https://cellexplorer.org/datastructure/data-structure-and-format/#events) and [manipulations](https://cellexplorer.org/datastructure/data-structure-and-format/#manipulations): You can inspect detected events, flag individual events (again see the example below).
* [states](https://cellexplorer.org/datastructure/data-structure-and-format/#states): show and navigate states.
* [behavior](https://cellexplorer.org/datastructure/data-structure-and-format/#behavior) and [trials](https://cellexplorer.org/datastructure/data-structure-and-format/#trials): Show 2D behavior (not standardized yet), linearized positions, and trial data.
* [timeseries](https://cellexplorer.org/datastructure/data-structure-and-format/#time-series): Show time series data.

You can also view KiloSort spike data from a `rez.mat` file.

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot_ripples.png">![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot_ripples_lowress.jpg)</a>

The screenshot above shows a 128 channels recording with two ripple events highlighted, the spike raster below is color coded and sorted by putative cell types.

### Interface elements

## Metadata
NeuroScope2 uses the [session struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) for session level metadata. Please see [this tutorial](https://cellexplorer.org/tutorials/metadata-tutorial/) on how to generate and fill out the metadata. Metadata can be imported from an existing `basename.xml` file (NeuroSuite), from Intan's `info.rhd` file, from KiloSort's `rez.mat` file and from a `basename.sessionInfo.mat` (Buzcode) file.

### Intan files
Intan files are treated as time series. To load the files you must specify the metadata in the session metadata struct. This can be imported from Intan's `info.rhd`. In the session GUI (gui_session.m) go to the File menu and select __Import time series from Intan info.rhd__, this will import the metadata as shown in the screenshot below. Save the changes and close the gui.

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/02/timeseries_intan.png">![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2021/02/timeseries_intan.png)</a>

### Loading a new dataset
A new dataset can be loaded from the File menu. Select any file from the basepath of the session that contains the basename, `basename.*`. 

### Compiled versions of NeuroScope2
NeuroScope2 can be compiled to a NeuroScope2.exe and NeuroScope2.app for Windows and Mac respectively. These can be run without having Matlab installed, or just be used independently on a system with Matlab. If Matlab is installed on your system you only need the app (NeuroScope2.exe or NeuroScope2.app), but if you are using the it on a system without Matlab, you have to install dependencies first.

In Windows you can further make the compiled NeuroScope2 the default program to open e.g. .dat files, such that you can double click any .dat file to open it directly in NeuroScope2.

You can download compiled versions of NeuroScope2 for [Windows](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope2_Windows.zip) and [Mac](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope2_Mac.zip).

