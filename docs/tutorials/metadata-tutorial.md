---
layout: default
title: Generate metadata struct
parent: Tutorials
nav_order: 2
---
# Metadata tutorial
{: .no_toc}
This tutorial shows you how to generate the [session metadata struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) used by CellExplorer. 
![Flow chart](https://buzsakilab.com/wp/wp-content/uploads/2020/05/Flowcharts_Metadata.png){: .mt-4}

1. Define the basepath of the dataset to run. A valid dataset should consist of a binary raw file, and spike sorted data. 
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```
CellExplorer operates with one main path for a dataset: the `basepath`. The `basepath` defines the local path to the dataset. The session name, also referred to as `basename`, is assumed to be the same as the directory of the session. Each of these fields are defined in the `session.general` struct. The raw data file should be located in the `basepath`. 
2. You can generate the session metadata struct from the template function
```m
session = sessionTemplate(basepath);
```
`sessionTemplate` will extract metadata from the content of `basepath`. Please go through the `sessionTemplate` script to understand the various components that are extracted. You can create your own template scripts from the original, adding any other relevant metadata. 

3. Use the session gui for inspecting the metadata struct and for further manual entry.
```m
session = gui_session(session);
```
4. You can verify the fields by running the verification script:
```m
verifySessionStruct(session);
```
This will show a small figure, with missing required fields highlighted in red, and unused optional fields in blue.

Below is a screenshot of the metadata interface with metadata entered.
![Metadata interface](https://buzsakilab.com/wp/wp-content/uploads/2021/03/gui_session_general.png)
