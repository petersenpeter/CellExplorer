---
layout: default
title: NeuroScope2
parent: Graphical interface
nav_order: 9
---
{: .no_toc}
# NeuroScope2 (in beta)
NeuroScope2 is a data viewer for raw and processed extracellular data acquired using multisite silicon probes, tetrodes or single wires. It is written in Matlab, maintaining many of the original functions of [NeuroScope](http://neurosuite.sourceforge.net/), but with many enhancements. It can be used to explore existing data and to stream data being collected and can handle multiple data streams simultaneously - e.g. digital, analog, and aux channels from Intan - together with the raw ephys data. As NeuroScope is written in MATLAB, it is hackable, adaptable and easily expandable. It is much faster than the original NeuroScope, and functions fully within the data types of CellExplorer, using the `session` struct for metadata.

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot.png">![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2021/02/NeuroScope_screenshot_lowress.jpg)</a>

{: .no_toc}
## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Features
The interface is user-friendly, with a single side panel for accessing most functions. You can zoom, navigate, measure, highlight, and select traces directly with your mouse cursor, making manual inspection very intuitive and efficient. NeuroScope2 can also perform basic data processing (that works on a data being collected as well), e.g. bandpass filter traces, perform temporal smoothing, perform spike and events detection directly on the raw or processed traces. Channel tags can be used to highlight and filter (+/-) channels.

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
The interface consist of side panel and a main plot axis. Below the main axis are further navigational elements. The side-panel has three tabs focused on 1. the raw data, plotting styles and settings, and general metadata, 2. spikes data and 3. other data types, including events, time series, states and behavior.

## Metadata
NeuroScope2 uses the [session struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) for session level metadata. Please see [this tutorial](https://cellexplorer.org/tutorials/metadata-tutorial/) on how to generate and fill out the metadata. Metadata can be imported from an existing `basename.xml` file (NeuroSuite), from Intan's `info.rhd` file, from KiloSort's `rez.mat` file and from a `basename.sessionInfo.mat` (Buzcode) file.

## Open a session with NeuroScope2
In Matlab go to the basepath of the session you want to visualize. Now run NeuroScope2:
```m
NeuroScope2
```
NeuroScope2 will detect and load an existing `basename.session.mat` in the folder. If it is missing, it will generate the metadata Matlab struct using the template script `sessionTemplate`. The template script will detect and import metadata from:
* An existing `basename.xml` file (NeuroSuite)
* From Intan's `info.rhd` file
* From KiloSort's `rez.mat` file
* From a `basename.sessionInfo.mat` (Buzcode) file. 

You can also specify a basepath or a session struct when opening NeuroScope2:
```m
% Open NeuroScope2 specifying a basepath
NeuroScope2('basepath',basepath)

% Open NeuroScope2 specifying a session struct
NeuroScope2('session',session)
```
### Open a session from the File menu in NeuroScope2
A new dataset can be loaded from the File menu in NeuroScope2. Select `Load session from file`, to open a file dialog and select any file from the basepath of the session you want to open, that contains the basename, e.g. `basename.session.mat`.

### Display Intan's digital and analog files in NeuroScope2
Intan files are treated as time series and the metadata is stored in the session struct. To load the files you must first specify required metadata e.g. filename, number of channels, sampling rate. The metadata can be imported from Intan's `info.rhd`. In the session GUI `gui_session.m` go to the File menu and select __Import time series from Intan info.rhd__, this will import the metadata as shown in the screenshot below. Save the changes and close the gui.

<a href="https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_inputs.png">![CellExplorer](https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_inputs.png)</a>

## Compiled versions of NeuroScope2
NeuroScope2 can be compiled to a NeuroScope2.exe and a NeuroScope2.app for Windows and Mac respectively. The compiled versions can be used without a Matlab license and without having Matlab installed, but they can also be used independently on a system with Matlab. If Matlab is installed on your system you only need the application (NeuroScope2.exe or NeuroScope2.app), but if you want to use it on a system without Matlab, you have to use the installer (see the MyAppInstaller_web file included with the zip files below).

You can download compiled versions of NeuroScope2 for [Windows](https://buzsakilab.com/CellExplorer/NeuroScope2_Win.zip) and [Mac](https://buzsakilab.com/CellExplorer/NeuroScope2_Mac.zip). The compiled versions are not necessarily the latest version of NeuroScope2.

On Windows you can further make the compiled [NeuroScope2 the default program](https://helpdeskgeek.com/how-to/how-to-change-the-default-program-to-open-a-file-with/) to open .dat files (or another file type), such that you can double click any .dat file to open it directly in NeuroScope2, bypassing Matlab. 

### Compile NeuroScope2 yourself
Follow below direction to compile NeuroScope2 yourself:
* Run `deploytool` In Matlab's Command Window. 
* Select Application Compiler in the shown dialog.
* In the Application compiler window, Add NeuroScope2.m as a main file. 
* Add the GUI Layout Toolbox 2.3.4 in the "Files required by your application" section. The toolbox is included with CellExplorer and is located in the toolboxes folder. Matlab will automatically detect other dependencies and add them to the application.
* Now click __Package__ located in the top panel.
* That's it. A folder with the compiled application will be shown once the compiling completes. You can now run the compiled NeuroScope2 application on a system without a Matlab installation or license.
* If you use these files on a new system, you need to use the installer (MyAppInstaller_web) that is generated when compiling NeuroScope2.

## About the software implementation
NeuroScope2 can be modified and hacked and additional functionality can be implement by using the data structured and main calls described in below sections.

### Data structure in NeuroScope2
NeuroScope2 used global Matlab structures to handle settings and the various data types:
* `data`: Struct with all data loaded from various Matlab files: `data.spikes`, `data.events`, `data.states`, `data.behavior`.
* `ephys`: Struct with the ephys data for current shown time interval (streamed data), e.g. `ephys.raw` (raw unprocessed data), `ephys.traces` (processed data).
* `UI`: Struct with UI elements and settings, e.g.: `UI.fig` (figure handle), `UI.plot_axis1` (main plot axis),`UI.settings` (settings), `UI.menu` (menu elements), `UI.panel` (the various panels), `UI.elements` (UI elements like buttons and text fields).

### The primary function calls in NeuroScope2
Below embedded function are called to initialize various elements and during data visualization:
* `initUI`: Initializes UI elements including the menu, panels, plot axes. 
* `initData`: Initializes data handles and visualization elements derived from the data.
* `initInputs` Initializes any user-specific input (optional)
* `initTraces`: Initilizes trace, including offsets, sorting, applying filters. Called when changing the window size, amplification hiding/showing channels or groups.
* `plotData`: Main call visualizing all data types. `plotData` is further separated in sub-calls for plotting ephys data, spikes, states, events, time series, behavior, trial data and intan digital and analog traces.

Use these calls if you want to customize or add additional functionality. 

## Support
Please use the [GitHub issues system](https://github.com/petersenpeter/CellExplorer/issues) for reporting bugs, enhancement requests or general questions. We also have a [google group](https://groups.google.com/g/cellexplorer/) for the same requests.
