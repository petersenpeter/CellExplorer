---
layout: default
title: Individual analysis
parent: Tutorials
nav_order: 7
---
# Run scripts from the processing module separately
{: .no_toc}
The individual analysis steps of the processing module can easily be used separately. Below follows a few examples. All of them requires the session struct and/or the spikes struct. Most functions have a number of optional arguments allowing for customization. 

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
