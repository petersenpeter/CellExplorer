---
layout: default
title: Using the database
parent: Tutorials
nav_order: 8
---
# Database tutorial (draft)
{: .no_toc}
The public data in the database can be loaded as reference data, and can be accessed without providing credentials, but login credentials are necessary for full functionality of the database. This tutorial will show you the preparatory steps to use the database and various interactions. If you are using the public data, you can skip step 1-3.

1. Add your db credentials
Provide your buzsakilab.com credentials
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
2. Load session from db
```m
sessionName = 'Peter_MS13_171129_105507_concat';
sessions = db_load_sessions('sessionName',sessionName);
session = sessions{1}
```
3. Load and set session parameters
```m
[session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionName);
```
4. Inspecting and editing local session metadata
```m
session = gui_session(session);
```
6. Example as to loading spikes via database/metadata
   1. Loading spikes via the db
```m
spikes = loadSpikes('session',session);
```
   1. Running the Cell Explorer pipeline via the db
```m
cell_metrics = calc_CellMetrics('sessionName',sessionName);
cell_metrics = CellExplorer('metrics',cell_metrics);
```
   1. Running the Cell Explorer directly via the db
```m
cell_metrics = CellExplorer('sessionName',sessionName);
```
