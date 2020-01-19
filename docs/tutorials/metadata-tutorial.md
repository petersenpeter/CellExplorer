---
layout: default
title: Generate metadata struct
parent: Tutorials
nav_order: 2
---
# Metadata tutorial (draft)
{: .no_toc}
This tutorial shows you how to generate the metadata struct used by the Cell Explorer [defined here](https://petersenpeter.github.io/Cell-Explorer/pipeline/data-structure-and-format/#session-metadata). .

1. Define the basepath of the dataset to run. The dataset should at minimum consist of a `basename.dat`, a `basename.xml` and spike sorted data.
```m
% basepath = '/your/data/path/basename/';
cd(basepath)
```

2. You can generate the session metadata struct from the template function
```m
session = sessionTemplate(basepath);
```

3. Use an interface for inspecting the metadata and for further manual entry.
```m
session = gui_session(session);
```
