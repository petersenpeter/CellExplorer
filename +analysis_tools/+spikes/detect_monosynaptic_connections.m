function out = detect_monosynaptic_connections(varargin)
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'ephys',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'UI',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

UI = p.Results.UI;  
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

% This function detects monosynaptic connections

if isfield(data,'spikes') & isfield(data.spikes,'spindices')
    calculate_mono_synaptic_connections = false;
    
    if exist(fullfile(data.session.general.basePath,[data.session.general.name,'.mono_res.cellinfo.mat']))
        answer = questdlg('Overwrite existing monosynaptic connections?','Connections already detected');
        if strcmp(answer,'Yes')
            calculate_mono_synaptic_connections = true;
        end   
    else
        calculate_mono_synaptic_connections = true;
    end
    
    if calculate_mono_synaptic_connections
        mono_res = ce_MonoSynConvClick(data.spikes,'includeInhibitoryConnections',false); % detects the monosynaptic connections
        mono_res = gui_MonoSyn(mono_res); % Shows the GUI for manual curation
        save(fullfile(data.session.general.basePath,[data.session.general.name,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
    end    
else
    msgbox('Load spikes data before detecting monosynaptic connections the raster.','NeuroScope2','help')
end
