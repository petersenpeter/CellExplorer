---
layout: default
title: Generate metadata struct
parent: Tutorials
nav_order: 2
---
# Metadata tutorial (draft)
{: .no_toc}
This tutorial shows you how to generate the [metadata struct](https://petersenpeter.github.io/Cell-Explorer/pipeline/data-structure-and-format/#session-metadata) used by the Cell Explorer.

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
Below is a screenshot of the metadata interface and a short video.
![Metadata interface](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-gui_session-general.png)

<video max-width="100%" height="auto" controls="controls">
  <source src="https://buzsakilab.com/wp/wp-content/uploads/2020/01/MetadataTutorial.mp4" type="video/mp4">
</video>
