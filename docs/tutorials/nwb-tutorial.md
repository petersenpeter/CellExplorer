---
layout: default
title: NWB tutorial
parent: Tutorials
nav_order: 3
---
# NWB tutorial
{: .no_toc}
This tutorial will show you how to export cell metrics to a NWB file and import them back from the file. CellExplorer still works with its regular Matlab structs in memory, but you can save (export) and load (import) the cell metrics from a nwb file.

1. Load cell_metrics struct from a session into Matlab, e.g.:

```m
cell_metrics = loadCellMetrics('basepath',pwd);
```

2. Export the cell_metrics to NWB
The nwb naming should ideally follow the CellExplorer filename convention:
```m
nwb_file = [cell_metrics.general.basename,'.cell_metrics.cellinfo.nwb'];

% Generate the nwb file
nwb = saveCellMetrics2nwb(cell_metrics,nwb_file);
```

3. Import cell_metrics from NWB

```m
cell_metrics = loadNwbCellMetrics(nwb_file);

% Now you may run CellExplorer: 
cell_metrics = CellExplorer('metrics',cell_metrics);
```

### Saving metrics to nwb via saveCellMetrics
To save metrics to nwb with saveCellMetrics, all you have to do is specify the filename extension to be nwb:

```m
nwb_file = [cell_metrics.general.basename,'.cellmetrics.cellinfo.nwb'];
saveCellMetrics(cell_metrics,nwb_file)
```

### Loading metrics from nwb via loadCellMetrics
Cell metrics saved to a nwb file can also directly be loaded with loadCellMetrics, as long as you specify nwb as the file format:

```m
cell_metrics = loadCellMetrics('fileFormat','nwb')
```
The script will determine the nwb filename from the basename and basepath, e.g.: `basepath/basename.cell_metrics.cellinfo.nwb`

## Saving metrics to nwb in ProcessCellMetrics
To save the cell metrics directly to an nwb file in the processing module, you must provide the file format as an input to the call. The file format can also be set in the graphical interface by setting `showGUI=true`
```m
cell_metrics = ProcessCellMetrics('session', session,'showGUI',true,'fileFormat','nwb');
```

### Saving metrics to nwb in CellExplorer
You may also save directly to an nwb file in CellExplorer. From the _File_ menu in CellExplorer, select _Save As..._, a save-dialog will appear, in which you may select _.nwb_ as the file format. 
