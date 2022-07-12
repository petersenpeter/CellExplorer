---
layout: default
title: Session metadata struct
parent: Tutorials
nav_order: 2
---
# Session metadata tutorial
{: .no_toc}
This tutorial shows you how to generate the [session metadata struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) used by CellExplorer. 
![Flow chart](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/Flowcharts_Metadata.png){: .mt-4}

1. Define the basepath of the dataset to run. A valid dataset should consist of a binary raw data file and spike sorted data. 
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
CellExplorer operates with one main path for a dataset: the `basepath` which defines the local path to the dataset. The session name, also referred to as `basename`, is assumed to be the same as the directory of the session. These fields are defined in the `session.general` struct. The raw data file should be located in the `basepath`.

2. You can generate the session metadata struct using the session template script
```m
session = sessionTemplate(basepath);
```
`sessionTemplate` will extract metadata from the content of `basepath`. Please go through the `sessionTemplate` script to understand the various components that are extracted. You can create your own template scripts from the original, adding any relevant metadata. 

3. Use the [session gui](https://cellexplorer.org/interface/gui_session/) for inspecting the metadata struct and for further manual entry.
```m
session = gui_session(session);
```
Below is a screenshot of the metadata interface with metadata entered:
![Metadata interface](https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/gui_session_general.png)

4. You can validate the entered metadata by running the verification script:
```m
validateSessionStruct(session);
```
This will show a table, with missing required fields highlighted in red, and unused optional fields in blue. The verification can also be run from the session GUI:

<p align="center"><img src="https://raw.githubusercontent.com/petersenpeter/common_resources/main/images/verification.png" width="75%"></p>{: .mt-4}
