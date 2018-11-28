% % % % % % % % % % % % % % % % % % % % % %
% User preferences for the Cell-inspector
% % % % % % % % % % % % % % % % % % % % % %

% Display settings
ACG_type = 'Narrow'; % Narrow, Wide, Viktor
ACGPlot = 'Single'; % Single, All, tSNE
MonoSynDispIn = 'None'; % All, Selected, None
DisplayMetricsTable = 0; % 0, 1 

% Initial data displayed in the customPlot
plotXdata = 'FiringRate';
plotYdata = 'PeakVoltage';
plotZdata = 'DeepSuperficialDistance';

% Cell type classification definitions
classNames = {'Unknown','Pyramidal Cell 1','Pyramidal Cell 2','Pyramidal Cell 3','Narrow Interneuron','Wide Interneuron'};
deepSuperficialNames = {'Unknown','Cortical','Deep','Superficial'};

% Cell type classification colors
classColors = [[.5,.5,.5];[.2,.2,.8];[.2,.8,.2];[0.2,0.8,0.8];[.8,.2,.2];[0.8,0.2,0.8]];

% tSNE fields
tSNE_fields = {'FiringRate','ThetaModulationIndex','BurstIndex_Mizuseki2012','TroughToPeak','AB_ratio','BurstIndex_Royer2012','ACG_tau_rise','ACG_tau_burst','ACG_h','ACG_tau_decay','CV2','BurstIndex_Doublets','ThetaPhaseTrough','ThetaEntrainment'}; % derivative_TroughtoPeak
