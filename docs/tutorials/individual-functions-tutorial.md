---
layout: default
title: Individual analysis
parent: Tutorials
nav_order: 7
---
# Run scripts from the processing module separately
{: .no_toc}
The individual analysis steps of the processing module can easily be used separately. Below follows a few examples. All of them requires the session struct and/or the spikes struct. Most functions have a number of optional arguments allowing for customization. 

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

### Create session struct
1. Define the basepath of the dataset to run. An optional Neuroscope compatible `basename.xml` can be used to define the electrode layout.
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
2. Generate session metadata struct using the template function and display the metadata in a GUI
```m
session = sessionTemplate(basepath,'showGUI',true);
```

### Load spikes
Loading and creating the spikes struct is done using the script `loadSpikes`. If the spikes struct has not been created yet, the script will generate it and save it to the basepath. If it already exist in the basepath it will load it into Matlab:
```m
spikes = loadSpikes('session',session);
```

### Extract spike waveforms from dat/binary file
```m
spikes = getWaveformsFromDat(spikes,session);
```

### Calculate waveform metrics
```m
sr = session.extracellular.sr;
waveform_metrics = calc_waveform_metrics(spikes,sr);
```

### ACG and CCG metrics
```m
acg_metrics = calc_ACG_metrics(spikes);
```
### fit ACGs
From the calculated ACGs (previous section) you can calculate the ACG fits:
```m
fit_params = fit_ACG(acg_metrics.acg_narrow);
```

### Calculate log ACGs
The log ACGs are calculated with log-scaled bins from 1ms to 10sec:
```m
acg = calc_logACGs(spikes.times)
```

### Calculate log ISIs
The log ISIs are calculated with log-scaled bins from 1ms to 100sec:
```m
isi = calc_logISIs(spikes.times);
```

### Monosynaptic connections
`ce_MonoSynConvClick.m` is called to detect monosynaptic connections. Once complete, the connections can be manually curated using `gui_MonoSyn.m`. 

```m
mono_res = ce_MonoSynConvClick(spikes);
mono_res = gui_MonoSyn(mono_res);
saveStruct(mono_res,'cellinfo','session',session)
```

### Calculate PSTHs for events
By providing an event struct, interval PSTHs can be created:
```m
PSTH = calc_PSTH(event,spikes);
```
You can provide optional parameters defining the alignment and the windows size.

### Deep-superficial classification of hippocampal recordings
This metric has it own tutorial dedicated to it [here](https://cellexplorer.org/tutorials/deep-superficial-tutorial/), but briefly:
1. Detect ripples
```m
ripples = ce_FindRipples(session);
```
2. Determine the depth
```m
deepSuperficialfromRipple = classification_DeepSuperficial(session);
```
3. This will generate a deep-superficial classification file: `sessionName.deepSuperficialfromRipple.channelinfo.mat`. You can curate it using `gui_DeepSuperficial`:
```m
gui_DeepSuperficial(deepSuperficialfromRipple;
```

### Calculate CCGs across all cells
First calculate the spindices (the input format of the CCG function), if they are missing in the spikes struct:

```m
spikes_restrict.spindices = generateSpinDices(spikes_restrict.times);
```

Next calculate the CCGs between all pairs of cells

```m
binSize = 0.001; % 1ms bin size
duration = 0.1; % -50ms:50ms window
[ccg,t] = CCG(spikes.spindices(:,1),spikes.spindices(:,2),'binSize',binSize,'duration',duration);
```

Finally, to plot the ACGs and CCGs write

```m
figure, 
% Plotting the autocorrelogram (ACG) of the eight cell
subplot(2,1,1)
plot(t,ccg(:,8,8)), title('ASCG'), xlabel('Time (seconds)'), ylabel('Count')

% Plotting the cross correlogram (CCG) between a pair of cells
subplot(2,1,2)
plot(t,ccg(:,1,3)), title('CCG'), xlabel('Time (seconds)'), ylabel('Count')
```

The CCG example is also part of a [CCG tutorial script](https://github.com/petersenpeter/CellExplorer/blob/master/tutorials/CCG_tutorial.m).
