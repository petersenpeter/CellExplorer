---
layout: default
title: Preferences
parent: Processing module
nav_order: 2
---
# Preferences
The processing module allows you to adjust the default preferences or create your own. The preferences are saved in [preferences_ProcessCellMetrics.m](https://github.com/petersenpeter/CellExplorer/blob/master/preferences_ProcessCellMetrics.m). You may edit the default preferences or provide your own preferences in a separate file. To use your own, specify the path to your preferences as an analysis tag in the session struct: 
```m
% load a user_preference.m file from the folder +user_preferences
session.analysisTags.preferences_ProcessCellMetrics = 'user_preferences.user_preferences';
```
__user_preferences exampe file__

You must follow the example file below when generating your own preference file:
```m
function preferences = user_preferences(preferences,session)
% This is an example file for generating your own preferences for ProcessCellMetrics part of CellExplorer
% Please follow the structure of preferences_ProcessCellMetrics.m

% e.g.:
% preferences.waveform.nPull = 600;            % number of spikes to pull out (default: 600)
% preferences.waveform.wfWin_sec = 0.004;      % Larger size of waveform windows for filterning. total width in ms
% preferences.waveform.wfWinKeep = 0.0008;     % half width in ms
% preferences.waveform.showWaveforms = true;

end
```
The example file is located i the `+user_preferences` folder.