function out = open_gui_MonoSyn(varargin)
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

% This function opens the GUI for monosynaptic connections
% If the data does not exist the user is asked to process the connections

calculate_mono_synaptic_connections = false;

mono_res_file = fullfile(data.session.general.basePath,[data.session.general.name,'.mono_res.cellinfo.mat']);

if exist(mono_res_file)
    gui_MonoSyn(mono_res_file); % Shows the GUI for manual curation
else
    answer = questdlg('No monosynaptic connections detected. Do you want to detect them?','File does not exist');
    if strcmp(answer,'Yes')
        calculate_mono_synaptic_connections = true;
    end
end

if calculate_mono_synaptic_connections
    if isfield(data,'spikes')
        mono_res = ce_MonoSynConvClick(data.spikes,'includeInhibitoryConnections',false); % detects the monosynaptic connections
        mono_res = gui_MonoSyn(mono_res); % Shows the GUI for manual curation
        save(fullfile(data.session.general.basePath,[data.session.general.name,'.mono_res.cellinfo.mat']),'mono_res','-v7.3','-nocompression');
    else
        msgbox('Please load the spikes data first.','NeuroScope2','help')
    end
end
