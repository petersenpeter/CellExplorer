---
layout: default
title: Preferences
parent: Graphical interface
nav_order: 4
---
# Preferences
{: .no_toc}
Allows the user to customize the Cell Explorer. Preferences are located in `CellExplorer_Preferences.m`.

### Display settings
1. customCellPlotIn1-6 : 
incomplete list: 'Single waveform','All waveforms','All waveforms (image)','Single raw waveform','All raw waveforms','Single ACG','All ACGs','All ACGs (image)','CCGs (image)','Sharp wave-ripple'

1. ACG_type : ['Normal' (100ms), 'Wide' (1s), 'Narrow' (30ms)]
1. monoSynDispIn: ['None', 'Selected', 'All']
1. plotCountIn : ['GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6']
1. metricsTableType : ['Metrics','Cells','None']
1. plotWaveformMetrics : [0,1]
1. dispLegend : [0,1]

### Initial data displayed in the customPlot
1. plotXdata : 'firingRate' 
1. plotYdata : 'peakVoltage' 
1. plotZdata : 'troughToPeak' 

### Autosave settings
UI.settings.autoSaveFrequency : 6
UI.settings.autoSaveVarName : 'cell_metrics'

### Cell type classification definitions
1. cellTypes: {'Unknown', 'Pyramidal Cell 1', 'Pyramidal Cell 2', 'Pyramidal Cell 3', 'Narrow Interneuron', 'Wide Interneuron'};
1. deepSuperficial: {'Unknown', 'Cortical', 'Deep', 'Superficial'};

### Cell type classification colors
1. cellTypeColors : [ [.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8] ];

### Fields used to define the tSNE space
1. tSNE_calcWideAcg : boolean
1. tSNE_calcNarrowAcg : boolean
1. tSNE_calcFiltWaveform : boolean
1. tSNE_calcRawWaveform : boolean

### List of fields to use in the general tSNE representation
1. tSNE_metrics : {'FiringRate', 'ThetaModulationIndex', 'BurstIndex_Mizuseki2012', 'TroughToPeak', 'AB_ratio', 'BurstIndex_Royer2012', 'ACG_tau_rise', 'ACG_tau_burst', 'ACG_h', 'ACG_tau_decay', 'CV2', 'BurstIndex_Doublets', 'ThetaPhaseTrough', 'ThetaEntrainment', 'derivative_TroughtoPeak'};
1. tSNE_dDistanceMetric : default 'seuclidean'

### Highlighting excitatory and inhibitory cells
1. displayInhibitory = boolean 
1. displayExcitatory = boolean 

### Firing rate map setting
showHeatmap : boolean
showLegend : boolean
showHeatmapColorbar : boolean 
