---
layout: default
title: Generate metadata struct
parent: Tutorials
nav_order: 2
---
# Metadata tutorial
{: .no_toc}
This tutorial shows you how to generate the [session metadata struct](https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata) used by the CellExplorer. 
![Flow chart](https://buzsakilab.com/wp/wp-content/uploads/2020/05/Flowcharts_Metadata.png){: .mt-4}

1. Define the basepath of the dataset to run. A valid dataset consists of a `basename.dat`, a `basename.xml` (not required) and spike sorted data.
```m
basepath = '/your/data/path/basename/';
cd(basepath)
```

2. You can generate the session metadata struct from the template function
```m
session = sessionTemplate(basepath);
```

3. Use the session gui for inspecting the metadata struct and for further manual entry.
```m
session = gui_session(session);
```
Below is a screenshot of the metadata interface and a short video showing the various tabs.
![Metadata interface](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-gui_session-general.png)


<video width="100%" height="auto" controls="controls">
  <source src="https://buzsakilab.com/wp/wp-content/uploads/2020/01/MetadataTutorial.mp4" type="video/mp4">
</video>
