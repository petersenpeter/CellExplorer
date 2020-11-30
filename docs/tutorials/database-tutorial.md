---
layout: default
title: Use database from terminal
parent: Tutorials
nav_order: 9
---
# Database tutorial
{: .no_toc}
The public data in the database can be loaded as reference data, and can be accessed without providing credentials, but login credentials are necessary for full functionality of the database. This tutorial will show you the preparatory steps to use the database and various interactions. If you are using the public data, you can skip step 1-3.

1. Provide your [buzsakilab.com](https://buzsakilab.com/wp/database/) credentials
```m
edit db_credentials.m
```
2. In the Matlab file `db_credentials.m`, replace the two lines below with your credentials:
```m
credentials.username = 'user';
credentials.password = 'password';
```
3. Define paths to data repositories
Paths are generated from the repository definition in the database. Here you need to define the root path for each repository in `db_local_repositories.m`. To use the `NYUshare_Datasets` (the NYU share dataset directory), you must define the system path to the repository, e.g.:
```m
repositories.NYUshare_Datasets = '/Volumes/buzsakilab/Buzsakilabspace/Datasets';
```
4. Load session from database
   1. Load single session by filtering by a `sessionName`
```m
sessionName = 'Peter_MS13_171129_105507_concat';
sessions = db_load_sessions('sessionName',sessionName);
session = sessions{1};
```
   1. Load and set session parameters
```m
sessionName = 'Peter_MS13_171129_105507_concat';
[session, basename, basepath] = db_set_session('sessionName',sessionName);
```
5. Inspect and edit the session metadata if necessary
```m
session = gui_session(session);
```
6. Load spikes via database/metadata
```m
spikes = loadSpikes('session',session);
```
7. Loading via database/metadata
   1. Run the processing pipeline and CellExplorer from `sessionName`
```m
cell_metrics = ProcessCellMetrics('sessionName',sessionName);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
   1. Run CellExplorer directly from `sessionName`
```m
cell_metrics = CellExplorer('sessionName',sessionName);
```
   1. Run CellExplorer from list of `sessionNames`
```m
sessionNames = {'ham11_27-29_amp','ham11_34-36_amp'};
cell_metrics = loadCellMetricsBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);
```

Please see the tutorial for [how to interact with the database from CellExplorer]({{"/tutorials/database-sessions-dialog/"|absolute_url}}) as well.
