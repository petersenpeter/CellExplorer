---
layout: default
title: Preferences
parent: Graphical interface
nav_order: 4
---
<style>
.main-content dd{
    margin: 0 0 0 210px  !important;
    margin-left: 4em  !important;
}
dl {
    padding: 0.1em;
  }
  dt {
    float: left;
    clear: left;
    width: 200px;
    text-align: right;
    color: black;
  }
  dt::after {
    content: " ";
  }
  dd {
    margin: 0 0 0 210px  !important;
    margin-left: 4em  !important;
    padding: 0 0 0.5em 0;
  }
</style>

# Preferences
{: .no_toc}
Preferences are located in `preferences_CellExplorer.m` and is stored as fields in `UI.preferences.*`.

### Display settings
<dl>
  <dt>customCellPlotIn1-6</dt>
  <dd>incomplete list: 'Single waveform','All waveforms','All waveforms (image)','Single raw waveform','All raw waveforms','Single ACG','All ACGs','All ACGs (image)','CCGs (image)','Sharp wave-ripple'</dd>
  <dt>ACG_type</dt>
  <dd>['Normal' (100ms), 'Wide' (1s), 'Narrow' (30ms)]</dd>
  <dt>monoSynDispIn</dt>
  <dd>['None', 'Selected', 'All']</dd>
  <dt>plotCountIn</dt>
  <dd>['GUI 1+3','GUI 2+3','GUI 3+3','GUI 3+4','GUI 3+5','GUI 3+6']</dd>
  <dt>metricsTableType</dt>
  <dd>['Metrics','Cells','None']</dd>
  <dt>plotWaveformMetrics</dt>
  <dd>[0,1]</dd>
  <dt>dispLegend</dt>
  <dd>[0,1]</dd>
</dl>

### Initial data displayed in the customPlot
<dl>
  <dt>plotXdata</dt>
  <dd>'firingRate'</dd>
  <dt>plotYdata</dt>
  <dd>'peakVoltage' </dd>
  <dt>plotZdata</dt>
  <dd>'troughToPeak' </dd>
</dl>

### Autosave settings
<dl>
  <dt>autoSaveFrequency</dt>
  <dd>6</dd>
  <dt>autoSaveVarName</dt>
  <dd>'cell_metrics'</dd>
</dl>

### Cell type classification definitions
<dl>
  <dt>cellTypes</dt>
  <dd>{'Unknown', 'Pyramidal Cell 1', 'Pyramidal Cell 2', 'Pyramidal Cell 3', 'Narrow Interneuron', 'Wide Interneuron'}</dd>
  <dt>deepSuperficial</dt>
  <dd>{'Unknown', 'Cortical', 'Deep', 'Superficial'}</dd>
</dl>

### Cell type classification colors
<dl>
  <dt>cellTypeColors</dt>
  <dd>[ [.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8] ]</dd>
</dl>

### Fields used to define the tSNE space
<dl>
  <dt>tSNE_calcWideAcg</dt>
  <dd>boolean</dd>
  <dt>tSNE_calcNarrowAcg</dt>
  <dd>boolean</dd>
  <dt>tSNE_calcFiltWaveform</dt>
  <dd>boolean</dd>
  <dt>tSNE_calcRawWaveform</dt>
  <dd>boolean</dd>
</dl>

### List of fields to use in the general tSNE representation
<dl>
  <dt>tSNE_metrics</dt>
  <dd>{'FiringRate', 'ThetaModulationIndex', 'BurstIndex_Mizuseki2012', 'TroughToPeak', 'AB_ratio', 'BurstIndex_Royer2012', 'ACG_tau_rise', 'ACG_tau_burst', 'ACG_h', 'ACG_tau_decay', 'CV2', 'BurstIndex_Doublets', 'ThetaPhaseTrough', 'ThetaEntrainment', 'derivative_TroughtoPeak'}</dd>
  <dt>tSNE_dDistanceMetric</dt>
  <dd>default 'seuclidean'</dd>
</dl>

### Highlighting excitatory and inhibitory cells
<dl>
  <dt>displayInhibitory</dt>
  <dd>boolean</dd>
  <dt>displayExcitatory</dt>
  <dd>boolean</dd>
</dl>

### Firing rate map setting
<dl>
  <dt>showHeatmap</dt>
  <dd>boolean</dd>
  <dt>showLegend</dt>
  <dd>boolean</dd>
  <dt>showHeatmapColorbar</dt>
  <dd>boolean</dd>
</dl>
