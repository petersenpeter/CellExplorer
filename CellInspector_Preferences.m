% % % % % % % % % % % % % % % % % % % % % %
% Cell-inspector User Preferences  
% % % % % % % % % % % % % % % % % % % % % %

% Display settings
ACG_type = 'Normal'; % Normal (100ms), Wide (1s), Narrow (30ms)
ACGPlotIn = 'Single'; % Single, All, tSNE
WaveformsPlotIn = 'Single'; % Single, All, tSNE
MonoSynDispIn = 'None'; % All, Selected, None
DisplayMetricsTable = 0; % 0, 1 

% Initial data displayed in the customPlot
plotXdata = 'FiringRate';
plotYdata = 'PeakVoltage';
plotZdata = 'TroughToPeak';

% Cell type classification definitions
classNames = {'Unknown','Pyramidal Cell 1','Pyramidal Cell 2','Pyramidal Cell 3','Narrow Interneuron','Wide Interneuron'};
deepSuperficialNames = {'Unknown','Cortical','Deep','Superficial'};

% Cell type classification colors
classColors = [[.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8]];

% Fields used to define the tSNE represetation
tSNE_fields = {'FiringRate','ThetaModulationIndex','BurstIndex_Mizuseki2012','TroughToPeak','AB_ratio','BurstIndex_Royer2012','ACG_tau_rise','ACG_tau_burst','ACG_h','ACG_tau_decay','CV2','BurstIndex_Doublets','ThetaPhaseTrough','ThetaEntrainment','derivative_TroughtoPeak'}; % derivative_TroughtoPeak

% Highlighting excitatory and inhibitory cells
displayInhibitory = false; % boolean 
displayExcitatory = false; % boolean 
