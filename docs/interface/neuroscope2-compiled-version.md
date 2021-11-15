---
layout: default
title: Compiled version
parent: NeuroScope2
grand_parent: Graphical interface
nav_order: 9
---

# Compiled versions of NeuroScope2
NeuroScope2 can be compiled to a NeuroScope2.exe and a NeuroScope2.app for Windows and Mac respectively. The compiled versions can be used without a Matlab license and without having Matlab installed, but they can also be used independently on a system with Matlab. If Matlab is installed on your system you only need the application (NeuroScope2.exe or NeuroScope2.app), but if you want to use it on a system without Matlab, you have to use the installer (see the MyAppInstaller_web file included with the zip files below).

You can download compiled versions of NeuroScope2 for [Windows](https://buzsakilab.com/CellExplorer/NeuroScope2_Win.zip) and [Mac](https://buzsakilab.com/CellExplorer/NeuroScope2_Mac.zip). The compiled versions are not necessarily the latest version of NeuroScope2.

On Windows you can further make the compiled [NeuroScope2 the default program](https://helpdeskgeek.com/how-to/how-to-change-the-default-program-to-open-a-file-with/) to open .dat files (or another file type), such that you can double click any .dat file to open it directly in NeuroScope2, bypassing Matlab. 

### Compile NeuroScope2 yourself
Follow below direction to compile NeuroScope2 yourself:
* Run `deploytool` In Matlab's Command Window. 
* Select Application Compiler in the shown dialog.
* In the Application compiler window, Add NeuroScope2.m as a main file. 
* Add the GUI Layout Toolbox 2.3.4 in the "Files required by your application" section. The toolbox is included with CellExplorer and is located in the toolboxes folder. Matlab will automatically detect other dependencies and add them to the application.
* Now click __Package__ located in the top panel.
* That's it. A folder with the compiled application will be shown once the compiling completes. You can now run the compiled NeuroScope2 application on a system without a Matlab installation or license.
* If you use these files on a new system, you need to use the installer (MyAppInstaller_web) that is generated when compiling NeuroScope2.
