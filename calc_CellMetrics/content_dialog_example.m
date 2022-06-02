% This serves as an example for how to use the content_dialog

% Defining the fields of the dialog
content.title = 'Example parameters'; % dialog title
content.columns = 2; % 1 or 2 columns
content.field_names = {'date','start_time','end_time','weight','type_of_surgery','room','persons_involved','anesthesia'}; % name of the variables/fields
content.field_title = {'Date','Start time','End time','Weight (g)','Type of Surgery','Room','Persons involved','Anesthesia'}; % Titles shown above the fields
content.field_style = {'edit','checkbox','edit','edit','popupmenu','edit','edit','edit'}; % popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
content.field_default = {'test1',true,'text',5,'text','text','text','text'}; % default values
content.format = {'char','logical','char','numeric','char','char','char','char'}; % char, numeric, logical (boolean)
content.field_options = {'text','text','text','text',{'Chronic','Acute'},'text','text','text'}; % options for popupmenus
content.field_required = [true true true false false false false false]; % field required?

% Shows the content dialog
content = content_dialog(content);

% outputs are saved to content.output:
content.output

%% Now we can use the dialog for detecting ripples:

session = loadSession;

try 
    ripple_channel = session.channelTags.Ripple.channels;
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
saveMat = true;
variable_name = 'ripples';
 
content.title = 'Ripple detection parameters'; % dialog title
content.columns = 2; % 1 or 2 columns
content.field_names = {'ripple_channel','noise_channel','passband_low','passband_high','duration_min','duration_max','threshold_min','threshold_max','EMGThresh','variable_name','absoluteThresholds','saveMat'}; % name of the variables/fields
content.field_title = {'Ripple channel (1-index)','Noise channel (1-index)','Passband low (Hz)','Passband high (Hz)','Min duration (ms)','Max duration max (ms)','Threshold min (std/µV)','Threshold max (std/µV)','EMG threshold','Variable name','Absolute thresholds','Save mat file'}; % Titles shown above the fields
content.field_style = {'edit','edit','edit','edit','edit','edit','edit','edit','edit','edit','checkbox','checkbox'}; % popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
content.field_default = {ripple_channel,noise_channel,passband_low,passband_high,duration_min,duration_max,threshold_min,threshold_max,EMGThresh,variable_name,absoluteThresholds,saveMat}; % default values
content.format = {'numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','numeric','char','logical','logical'}; % char, numeric, logical (boolean)
content.field_options = {'text','text','text','text','text','text','text','text','text','text','text','text'}; % options for popupmenus
content.field_required = [true false true true true true true true false true false false]; % field required?

content = content_dialog(content);

if content.continue
    session.channelTags.Ripple.channels = content.output{1};
    passband = [content.output{3},content.output{4}];
    durations = [content.output{5},content.output{6}];
    thresholds = [content.output{7},content.output{8}]/session.extracellular.leastSignificantBit;
    EMGThresh = content.output{9};
    variable_name = content.output{10};
    absoluteThresholds = content.output{11};
    saveMat = content.output{12};
    
    ripples = ce_FindRipples(session,'passband',passband,'durations',durations,'thresholds',thresholds,'saveMat',false,'absoluteThresholds',absoluteThresholds);
    if saveMat
        saveStruct(ripples,'events','session',session,'dataName',variable_name);
    end
end
