function out = create_empty_events_file(varargin)
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

% This function creates an empty events file

content.title = 'Create new events file'; % dialog title
content.columns = 1; % 1 or 2 columns
content.field_names = {'ripple_channel'}; % name of the variables/fields
content.field_title = {'Name of events'}; % Titles shown above the fields
content.field_style = {'edit'}; % popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
content.field_default = {'new_events'}; % default values
content.format = {'char'}; % char, numeric, logical (boolean)
content.field_options = {'text'}; % options for popupmenus
content.field_required = [true]; % field required?
content.field_tooltip = {'Name of events'};
content = content_dialog(content);

if content.continue
    variable_name = content.output{1};

    if exist(fullfile(data.session.general.basePath,[data.session.general.name,'.',variable_name,'.events.mat']))
        answer = questdlg('Overwrite existing events file?','Events file exists');
        if strcmp(answer,'Yes')
            create_events_file = true;
        else
            create_events_file = false;
        end
    else
        create_events_file = true;
    end

    if create_events_file
        new_events = {};
        new_events.timestamps = nan(1);
        saveStruct(new_events,'events','session',data.session,'dataName',variable_name);
        
        % Refreshing list of events in NeuroScope2
        out.refresh.events = true;
    end
end
