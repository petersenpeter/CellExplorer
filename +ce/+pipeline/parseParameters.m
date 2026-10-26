function parameters = parseParameters(varargin)
%PARSEPARAMETERS Shared pipeline options. Headless overrides presentation flags.
p = inputParser;
addParameter(p,'sessionID',[],@isnumeric);
addParameter(p,'sessionName',[],@isstr);
addParameter(p,'session',[],@isstruct);
addParameter(p,'spikes',[],@isstruct);
addParameter(p,'spikeImport',[],@(x) isempty(x) || isstruct(x) && isscalar(x));
addParameter(p,'basepath',pwd,@isstr);
addParameter(p,'metrics','all',@(x) ischar(x) || iscellstr(x));
addParameter(p,'excludeMetrics',{'none'},@iscellstr);
addParameter(p,'removeMetrics',{'none'},@isstr);
addParameter(p,'restrictToIntervals',[],@isnumeric);
addParameter(p,'excludeIntervals',[],@isnumeric);
addParameter(p,'ignoreEventTypes',{'MergePoints'},@iscell);
addParameter(p,'ignoreManipulationTypes',{'cooling'},@iscell);
addParameter(p,'ignoreStateTypes',{'StateToIgnore'},@iscell);
addParameter(p,'excludeManipulationIntervals',true,@islogical);
addParameter(p,'metricsToExcludeManipulationIntervals',{'waveform_metrics','PCA_features','acg_metrics','monoSynaptic_connections','theta_metrics','spatial_metrics','event_metrics','psth_metrics'},@iscell);

addParameter(p,'keepCellClassification',true,@islogical);
addParameter(p,'manualAdjustMonoSyn',true,@islogical);
addParameter(p,'getWaveformsFromDat',true,@islogical);
addParameter(p,'includeInhibitoryConnections',false,@islogical);
addParameter(p,'showGUI',false,@islogical);
addParameter(p,'headless',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'randomSeed',0,@(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0 && x <= 2^32-1 && x == fix(x));
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'forceReloadSpikes',false,@islogical);
addParameter(p,'submitToDatabase',false,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','cell_metrics',@isstr);
addParameter(p,'saveBackup',true,@islogical);
addParameter(p,'fileFormat','mat',@isstr);
addParameter(p,'transferFilesFromClusterpath',true,@islogical);

% Plot related parameters
addParameter(p,'showFigures',false,@islogical);
addParameter(p,'showWaveforms',true,@islogical);
addParameter(p,'summaryFigures',false,@islogical);
addParameter(p,'sessionSummaryFigure',true,@islogical);
addParameter(p,'debugMode',false,@islogical);     
 
parse(p,varargin{:})

parameters = p.Results;
if parameters.headless
    fields = {'showGUI','showFigures','showWaveforms','summaryFigures', ...
        'sessionSummaryFigure','manualAdjustMonoSyn','debugMode','transferFilesFromClusterpath'};
    for index = 1:numel(fields)
        parameters.(fields{index}) = false;
    end
end
end
