function out = detect_ripples(varargin)
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

% This function detects/finds ripples

try
    ripple_channel = data.session.channelTags.Ripple.channels;
catch
    ripple_channel = 1;
end

noise_channel = []; % Not implemented

% default passband:
passband_low = 80;
passband_high = 240;

% default durations:
duration_min = 20;
duration_max = 150;

% default thresholds:
threshold_min = 18;
threshold_max = 48;

absoluteThresholds = true;
EMGThresh = 0.8;
variable_name = 'ripples';

content.title = 'Ripple detection parameters'; % dialog title
content.columns = 2; % 1 or 2 columns
content.field_names = {'ripple_channel','noise_channel','passband_low','passband_high','duration_min','duration_max','threshold_min','threshold_max','EMGThresh','variable_name','absoluteThresholds'}; % name of the variables/fields
content.field_title = {'Ripple channel (1-index)','Noise channel (1-index)','Passband low (Hz)','Passband high (Hz)','Min duration (ms)','Max duration max (ms)','Threshold min (defaults: 2*std or 18 µV)','Threshold max (defaults: 5*std or 48µV)','EMG threshold','Variable name','Absolute thresholds'}; % Titles shown above the fields
content.field_style = {'edit','edit','edit','edit','edit','edit','edit','edit','edit','edit','checkbox'}; % popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
content.field_default = {ripple_channel,noise_channel,passband_low,passband_high,duration_min,duration_max,threshold_min,threshold_max,EMGThresh,variable_name,absoluteThresholds}; % default values
content.format = {'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','char','logical'}; % char, numeric, logical (boolean)
content.field_options = {'text','text','text','text','text','text','text','text','text','text','text'}; % options for popupmenus
content.field_required = [true false true true true true true true false true false]; % field required?

content = content_dialog(content);

if content.continue
    data.session.channelTags.Ripple.channels = content.output{1};
    passband = [content.output{3},content.output{4}];
    durations = [content.output{5},content.output{6}];
    thresholds = [content.output{7},content.output{8}]/data.session.extracellular.leastSignificantBit;
    EMGThresh = content.output{9};
    variable_name = content.output{10};
    absoluteThresholds = content.output{11};

    if exist(fullfile(data.session.general.basePath,[data.session.general.name,'.',variable_name,'.events.mat']))
        answer = questdlg('Overwrite existing ripples file?','Ripples already detected');
        if strcmp(answer,'Yes')
            detect_ripples1 = true;
        else
            detect_ripples1 = false;
        end
    else
        detect_ripples1 = true;
    end

    if detect_ripples1
        ripples = ce_FindRipples(data.session,'passband',passband,'durations',durations,'thresholds',thresholds,'saveMat',false,'absoluteThresholds',absoluteThresholds);
        saveStruct(ripples,'events','session',data.session,'dataName',variable_name);
    end
end
