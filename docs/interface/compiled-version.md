---
layout: default
title: Compiled version
parent: Graphical interface
nav_order: 8
---
# Compiled versions of CellExplorer
CellExplorer can be compiled to a CellExplorer.exe and a CellExplorer.app for Windows and Mac respectively. The compiled versions can be used without a Matlab license and without having Matlab installed, but they can also be used independently on a system with Matlab. If Matlab is installed on your system you only need the application (CellExplorer.exe or CellExplorer.app), but if you want to use it on a system without Matlab, you have to use the installer (see the CellExplorer_Installer_web file included with the zip files below).

You can download compiled versions of CellExplorer for [Windows](https://buzsakilab.com/CellExplorer/CellExplorer_Win.zip) and [Mac](https://buzsakilab.com/CellExplorer/CellExplorer_Mac.zip). The compiled versions are not necessarily the latest version of CellExplorer.

### Compile CellExplorer yourself
Follow below direction to compile CellExplorer yourself:
* Run `deploytool` In Matlab's Command Window. 
* Select Application Compiler in the shown dialog.
* In the Application compiler window, Add CellExplorer.m as a main file. 
* Add the GUI Layout Toolbox 2.3.4 in the "Files required by your application" section. The toolbox is included with CellExplorer and is located in the toolboxes folder. Matlab will automatically detect other dependencies and add them to the application.
* Now click __Package__ located in the top panel.
* That's it. A folder with the compiled application will be shown once the compiling completes. You can now run the compiled CellExplorer application on a system without a Matlab installation or license.
* If you use these files on a new system, you need to use the installer (MyAppInstaller_web) that is generated when compiling CellExplorer.

### Compiled versions of NeuroScope2 and gui_session
[NeuroScope2](https://cellexplorer.org/interface/neuroscope2/#compiled-versions-of-neuroscope2) and [gui_session](https://cellexplorer.org/interface/gui_session/) are also available as compiled versions. Please see the dedicated pages. 
