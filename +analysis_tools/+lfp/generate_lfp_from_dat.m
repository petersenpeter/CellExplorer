function out = generate_lfp_from_dat(varargin)
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

% This function generates a lfp file from the raw binary (dat) file

show_waitbar = true;

if exist(fullfile(data.session.general.basePath,[data.session.general.name,'.lfp']))
    answer = questdlg('Overwrite existing .lfp file?','lfp file exists');
    if strcmp(answer,'Yes')
        generate_lfp = true;
    else
        generate_lfp = false;
    end
else
    generate_lfp = true;
end

if generate_lfp
    dat2lfp(data.session,show_waitbar)
end