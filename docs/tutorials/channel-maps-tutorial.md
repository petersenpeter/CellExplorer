---
layout: default
title: Channel maps tutorial
parent: Tutorials
nav_order: 4
---
# Channel maps tutorial
{: .no_toc}
This tutorial will show you how to generate and use the two channel maps available in CellExplorer: 1. Channel coordinates (2D probe layout) and 2. the Common Coordinate Framework (CCF; by the Allen Institute). The data formats are defined [here](https://cellexplorer.org/datastructure/data-structure-and-format/#channels). The channel maps are useful to see the spatial location of the cells, be it in 2D or in 3D. 

The channel maps can be generated manually or with two CellExplorer functions. When you generate the channel maps manually, make sure to save them according to the data structure of CellExplorer described in above link. 

## Channel maps in CellExplorer
CellExplorer can show both channel maps as separate plots as shown in below figure. The probe layout can also be shows as an embedded plot in the waveform plots. The same session and cell are shown in all three panels. Two probes with 6 shanks, implanted in CA1 in both hemispheres.

![](https://buzsakilab.com/wp/wp-content/uploads/2021/07/Probe_map_and_CCF.png){: .mt-4}

## Channel coordinates (Probe layout)
### Manually generating the channel coordinates
The channel coordinates are based on x and y coordinates in µm. To generate a channel map for a linear probe with 16 channels spaced 20 µm apart, you can do the following:

```m
chanCoords.x = zeros(16,1); % Setting x-position to zero
chanCoords.y = -20*[0:15]'; % Assigning negative depth values, starting at y=0 for channel 1
```

That's it! Now save that struct to the basepath as a channelInfo.mat container:
```m
saveStruct(chanCoords,'channelInfo','session',session);
```

This will save the channel coordinates to a .mat file in the basepath, using the session struct to determine the basepath and basename, e.g. `basepath/basename.chanCoords.channelInfo.mat`. The processing pipeline will automatically detect the file and determine the position of the cells relative to the layout.

### 0. Generating the channel coordinates from session parameters
Channel coordinates can be generated from a session struct with defined electrode groups, and a couple of extra parameters:
between the sites.
There are two ways to provide these parameters

### 1. Using animal probe implants metadata

Open the session gui: 
```m
session = session_gui(session);
```
Select the _Animal Subject_ tab in the left side-menu. 
Activate the _Probe implants_ tab and click _Add_. This will open a probe implants window allowing you to provide probe implants information, including your probe, brain region and implant coordinates (see screenshot below). Now close the session gui and run the script below; 

```m
generateChannelMap(session)
```
This will generate the channel map.

### 2. Using analysis tags
The other option is providing basic parameters about your probe geometry:
* Probe layout: session.analysisTags.probesLayout. Select between the following options: linear, poly2, poly3, poly4, poly5, staggered (default='poly2').
* Vertical spacing: session.analysisTags.probesVerticalSpacing (default=20 µm). The vertical spacing between neighboring channels. 
* The inter-shank distance: 200 µm (not adjustable).

```m
% A session struct with electrode groups:
session.extracellular.electrodeGroups

% And probe layout:

generateChannelMap(session)
```
The channel map can also be generated directly from the session gui, by selecting _Generate channel map_ from the _Extracellular_ menu. This will generate the chanCoords file and below figure showing an example layout with two NeuroNexus Buzsaki 64 channel probes with a staggered configuration with 8 shanks (200 µm apart).

<img src="https://buzsakilab.com/wp/wp-content/uploads/2021/07/Channelmap_session_gui.png" width="80%">

### 3. Generating and using channel coordinates for probe design
CellExplorer also supports true probe geometries, which must be saved as a chanCoords struct in the CellExporer directory: `+chanCoords/probe_name.probes.chanCoords.channelInfo.mat`. If a probe design has been defined, CellExplorer prioritizes this above other methods. 

Priority order for generating the chanCoords file:
1. Probe design
2. Animal probe implants metadata
3. Analysis tags

## Common coordinates (CCF)
### 0. Generate common coordinates manually
The common coordinates are based on x, y and z coordinates in µm. To generate a channel map for a linear probe with 16 channels spaced 20 µm apart, you can do the following:

```m
ccf.x = zeros(16,1); % Setting x-position to zero
ccf.y = zeros(16,1); % Setting y-position to zero
ccf.z = -20*[0:15]'; % Assigning negative depth values, starting at y=0 for channel 1
```

That's it! Now save that struct to the basepath as a channelInfo.mat container:
```m
saveStruct(ccf,'channelInfo','session',session);
```

### 1. Translating the probe layout to CCF coordinates 
Following the one of the first two solutions for generating the channel coordinates, you can now also generate the projected CCF coordinates:
```m
generateCommonCoordinates(session)
```
This action requires the implant metadata, and will generate a ccf file, e.g. `basepath/basename.ccf.channelInfo.mat` and show the figure below

The common coordinates can also be generated directly from the session gui, by selecting _Generate common coordinates_ from the _Extracellular_ menu. This will generate the chanCoords file and below figure showing an example layout with two Buzsaki 64 probes with a staggered configuration with 8 shanks (200 µm apart) implanted in CA1 in both hemispheres. The vectors signifies implant vectors, and the probes has been rotated along the implant axis to follow the curvature of the Longitudinal Axis of the Hippocampus.

<img src="https://buzsakilab.com/wp/wp-content/uploads/2021/07/CCF_sessio_gui.png" width="80%">

