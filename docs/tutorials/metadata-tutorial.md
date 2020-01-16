---
layout: default
title: Metadata
parent: Tutorials
nav_order: 2
---
# Metadata tutorial (TODO)
{: .no_toc}
This tutorial shows you how to generate the metadata struct used by the Cell Explorer. The tutorial is also available as a matlab script


1. Define the basepath of the dataset to run. The dataset should at minimum consist of a `basename.dat`, a `basename.xml` and spike sorted data.
```m
% basepath = '/your/data/path/basename/';
cd(basepath)
```

2. Generate session metadata struct using the template function and display the meta data in a gui
```m
session = sessionTemplate(pwd,'showGUI',true);
function session = sessionTemplate(input1,varargin)
```
