function success = db_upload_session(session,varargin)
% Peter Petersen
% petersen.peter@gmail.com
% Last edited: 26-11-2019

% Parsing inputs
p = inputParser;
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'fields',{'all'},@iscell);

parse(p,varargin{:})
forceReload = p.Results.forceReload;
fields = p.Results.fields;

% Setting success toggle
success = false;

% loading and defining db settings
db_settings = db_load_settings;
db_settings.web_address = [db_settings.address, 'entries/' num2str(session.general.entryID)];

% Checking if session already exist
options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
db_session = webread([db_settings.address,'views/15356/'],options,'page_size','5000','Timeout',30,'entryid',session.general.entryID); 
if strcmp(db_session.renderedHtml, '<div class="frm_no_entries">No Entries Found</div>')
   warning('Session does not exist.')
   return 
end
        
% General
if any(contains(fields,{'general','all'}))
    % Updating fields
    jsonStructure = [];
    jsonStructure.form_id = 143;
    jsonStructure.user_id = 3;
    if isfield(session.general,'duration')
        jsonStructure.fiElD_2556 = session.general.duration;
    end
    if isfield(session.general,'location')
        jsonStructure.fiElD_1901 = session.general.location;
    end
    if isfield(session.general,'time')
        jsonStructure.fiElD_2013 = session.general.time;
    end
    jsonStructure.fiElD_1903 = session.general.sessionType;
    jsonStructure.fiElD_1902 = session.general.notes;
    jsonStructure.fiElD_1892 = char(session.general.date);
    if isfield(session.general,'investigator_id')
        jsonStructure.fiElD_2522 = session.general.investigator_id;
    end
    if isfield(session.general,'experimenters_id')
        jsonStructure.fiElD_1895 = session.general.experimenters_id;
    end
    if isfield(session.general,'projects_id')
        jsonStructure.fiElD_2486 = session.general.projects_id;
    end
    if isfield(session.general,'repositories_id')
        jsonStructure.fiElD_2359 = session.general.repositories_id;
    end
    cluIDs = fieldnames(jsonStructure);
    jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
    jsonStructure = jsonencode(jsonStructure);
    jsonStructure = strrep(jsonStructure,'fiElD_','');
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
    RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
    if RESPONSE.success==1
        disp('General metadata successfully submitted to db')
    end
end

% Extracellular
if any(contains(fields,{'extracellular','all'}))
    % Updating fields
    jsonStructure = [];
    jsonStructure.form_id = 143;
    jsonStructure.user_id = 3;
    jsonStructure.fiElD_1908 = session.extracellular.nChannels;
    jsonStructure.fiElD_1909 = session.extracellular.sr;
    if isfield(session.extracellular,'nSamples')
        jsonStructure.fiElD_1911 = session.extracellular.nSamples;
    end
    if isfield(session.extracellular,'precision')
        jsonStructure.fiElD_1910 = session.extracellular.precision;
    end
    if isfield(session.extracellular,'fileFormat')
        jsonStructure.fiElD_2010 = session.extracellular.fileFormat;
    end
    if isfield(session.extracellular,'probeDepths')
        jsonStructure.fiElD_1915 = session.extracellular.probeDepths;
    end
    jsonStructure.fiElD_2930 = session.extracellular.leastSignificantBit;
    if isfield(session.extracellular,'srLfp')
        jsonStructure.fiElD_1971 = session.extracellular.srLfp;
    end
    cluIDs = fieldnames(jsonStructure);
    jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
    jsonStructure = jsonencode(jsonStructure);
    jsonStructure = strrep(jsonStructure,'fiElD_','');
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
    RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
    if RESPONSE.success==1
        disp('extracellular meta data successfully submitted to db')
    end
    % Electrode groups
    db_update_electrodeGroups(session,db_settings)
    % Spike groups
    db_update_spikeGroups(session,db_settings)
end

% Epochs
if any(contains(fields,{'epochs','all'})) && isfield(session,'epochs') && ~isempty(session.epochs)
    db_update_epochs(session,db_settings)
end

% Channel tags
if any(contains(fields,{'channelTags','all'})) && isfield(session,'channelTags') && ~isempty(session.channelTags)
    db_update_channelTags(session,db_settings)
end

% Brain regions
if any(contains(fields,{'brainRegions','all'})) && isfield(session,'brainRegions') && ~isempty(session.brainRegions)
    db_update_brainRegions(session,db_settings)
end
% Time series
if any(contains(fields,{'timeSeries','all'})) && isfield(session,'timeSeries') && ~isempty(session.timeSeries)
    db_update_timeSeries(session,db_settings)
end
% Inputs  (formid=147,)
if any(contains(fields,{'inputs','all'})) && isfield(session,'inputs') && ~isempty(session.inputs)
    db_update_inputs(session,db_settings)
end
% analysisTags (formid=198, formd_key 1j1h0)
if any(contains(fields,{'analysisTags','all'})) && isfield(session,'analysisTags') && ~isempty(session.analysisTags)
    db_update_analysisTags(session,db_settings)
end

% spikeSorting (formid=146, formd_key siurq)
if any(contains(fields,{'spikeSorting','all'})) && isfield(session,'spikeSorting') && ~isempty(session.spikeSorting)
    db_update_spikeSorting(session,db_settings)
end

% behavioralTracking (formid=150)
if any(contains(fields,{'behavioralTracking','all'})) && isfield(session,'behavioralTracking') && ~isempty(session.behavioralTracking)
    db_update_behavioralTracking(session,db_settings)
end

% analysisStats (formid=?)
% Not implemented

success = true;

%% % % % % % % % % % % % % % % % % % % %
% Builtin functions
% % % % % % % % % % % % % % % % % % % %

    function db_update_behavioralTracking(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.w0uy7.form = 150; % Form id of spikeSorting repeatable section
        for i = 1:length(session.behavioralTracking)
            if isfield(session.behavioralTracking{i},'entryID') && session.behavioralTracking{i}.entryID>0
                idx = ['fiElD_', num2str(session.behavioralTracking{i}.entryID)];
                if isfield(session.behavioralTracking{i},'equipmentID') & ~isempty(session.behavioralTracking{i}.equipmentID)
                    jsonStructure.w0uy7.(idx).fiElD_2597 = session.behavioralTracking{i}.equipmentID;  % dynamic field
                end
            else
                idx = ['shank' num2str(i)];
            end
            jsonStructure.w0uy7.(idx).fiElD_1957 = session.behavioralTracking{i}.filenames;
            jsonStructure.w0uy7.(idx).fiElD_2554 = session.behavioralTracking{i}.epoch;
            if isfield(session.behavioralTracking{i},'type')
                jsonStructure.w0uy7.(idx).fiElD_1956 = session.behavioralTracking{i}.type;
            end
            if isfield(session.behavioralTracking{i},'framerate')
                jsonStructure.w0uy7.(idx).fiElD_1965 = session.behavioralTracking{i}.framerate;
            end
            if isfield(session.behavioralTracking{i},'notes')
                jsonStructure.w0uy7.(idx).fiElD_1959 = session.behavioralTracking{i}.notes;
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Behavioral tracking successfully submitted to db')
        end
    end

    function db_update_spikeSorting(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.wu0al.form = 146; % Form id of spikeSorting repeatable section
        for i = 1:length(session.spikeSorting)
            if isfield(session.spikeSorting{i},'entryID') && session.spikeSorting{i}.entryID>0
                idx = ['fiElD_', num2str(session.spikeSorting{i}.entryID)];
                if isfield(session.spikeSorting{i},'spikeSorterID') & ~isempty(session.spikeSorting{i}.spikeSorterID)
                    jsonStructure.wu0al.(idx).fiElD_2392 = session.spikeSorting{i}.spikeSorterID;  % dynamic field
                end
            else
                idx = ['shank' num2str(i)];
            end
            jsonStructure.wu0al.(idx).fiElD_1933 = session.spikeSorting{i}.method;
            jsonStructure.wu0al.(idx).fiElD_1934 = session.spikeSorting{i}.format;
            jsonStructure.wu0al.(idx).fiElD_1935 = session.spikeSorting{i}.relativePath;
            if isfield(session.spikeSorting{i},'channels')
                jsonStructure.wu0al.(idx).fiElD_1937 = session.spikeSorting{i}.channels;
            end
                if isfield(session.spikeSorting{i},'notes')
            jsonStructure.wu0al.(idx).fiElD_1938 = session.spikeSorting{i}.notes;
            end
            if isfield(session.spikeSorting{i},'cellMetrics')
                jsonStructure.wu0al.(idx).fiElD_2944 = session.spikeSorting{i}.cellMetrics;
            end
            if isfield(session.spikeSorting{i},'manuallyCurated')
                jsonStructure.wu0al.(idx).fiElD_1936 = session.spikeSorting{i}.manuallyCurated;
            end
            if isfield(session.spikeSorting{i},'cellCount')
                jsonStructure.wu0al.(idx).fiElD_2938 = session.spikeSorting{i}.cellCount;
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Spike sorting successfully submitted to db')
        end
        
    end
    
    function db_update_analysisTags(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.iznbr.form = 198; % Form id of inputs repeatable section
        if ~isempty(session.analysisTags)
            nameTags = fieldnames(session.analysisTags);
            for iTag = 1:length(nameTags)
                if isfield(session.analysisTags.(nameTags{iTag}),'entryID') && session.analysisTags.(nameTags{iTag}).entryID>0
                    idx = ['fiElD_', num2str(session.analysisTags.(nameTags{iTag}).entryID)];
                else
                    idx = ['shank' num2str(iTag)];
                end
                jsonStructure.iznbr.(idx).fiElD_2549 = nameTags{iTag};
                jsonStructure.iznbr.(idx).fiElD_2551 = session.analysisTags.(nameTags{iTag});
            end
            jsonStructure = jsonencode(jsonStructure);
            jsonStructure = strrep(jsonStructure,'fiElD_','');
            options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
            RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
            if RESPONSE.success==1
                disp('inputs successfully submitted to db')
            end
        end
    end
    
    function db_update_inputs(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.fiElD_6f4rk.form = 147; % Form id of inputs repeatable section
        
        nameTags = fieldnames(session.inputs);
        for iTag = 1:length(nameTags)
            if isfield(session.inputs.(nameTags{iTag}),'entryID') && session.inputs.(nameTags{iTag}).entryID>0
                idx = ['fiElD_', num2str(session.inputs.(nameTags{iTag}).entryID)];
                if isfield(session.inputs.(nameTags{iTag}),'equipmentID') & ~isempty(session.inputs.(nameTags{iTag}).equipmentID)
                    jsonStructure.fiElD_6f4rk.(idx).fiElD_2596 = session.inputs.(nameTags{iTag}).equipmentID; % dynamic field
                end
            else
                idx = ['shank' num2str(iTag)];
            end
            jsonStructure.fiElD_6f4rk.(idx).fiElD_1931 = nameTags{iTag};
            if isfield(session.inputs.(nameTags{iTag}),'description')
                jsonStructure.fiElD_6f4rk.(idx).fiElD_1932 = session.inputs.(nameTags{iTag}).description;
            end
            if isfield(session.inputs.(nameTags{iTag}),'inputType')
                jsonStructure.fiElD_6f4rk.(idx).fiElD_1930 = session.inputs.(nameTags{iTag}).inputType;
            end
            if isfield(session.inputs.(nameTags{iTag}),'channels') & ~isempty(session.inputs.(nameTags{iTag}).channels)
                jsonStructure.fiElD_6f4rk.(idx).fiElD_1929 = session.inputs.(nameTags{iTag}).channels;
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('inputs successfully submitted to db')
        end
    end
    
    function db_update_timeSeries(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.vc5ra.form = 223; % Form id of time series repeatable section
        
        if isfield(session,'timeSeries') && ~isempty(session.timeSeries)
        nameTags = fieldnames(session.timeSeries);
        for iTag = 1:length(nameTags)
            if isfield(session.timeSeries.(nameTags{iTag}),'entryID') && session.timeSeries.(nameTags{iTag}).entryID>0
                idx = ['fiElD_', num2str(session.timeSeries.(nameTags{iTag}).entryID)];
                if isfield(session.timeSeries.(nameTags{iTag}),'equipmentID') & ~isempty(session.timeSeries.(nameTags{iTag}).equipmentID)
                    jsonStructure.vc5ra.(idx).fiElD_2980 = session.timeSeries.(nameTags{iTag}).equipmentID; % Dynamic field
                end
            else
                idx = ['shank' num2str(iTag)];
            end
            jsonStructure.vc5ra.(idx).fiElD_2982 = nameTags{iTag};
            jsonStructure.vc5ra.(idx).fiElD_2974 = session.timeSeries.(nameTags{iTag}).fileName;
            if isfield(session.timeSeries.(nameTags{iTag}),'precision')
                jsonStructure.vc5ra.(idx).fiElD_2975 = session.timeSeries.(nameTags{iTag}).precision;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'nChannels') & ~isempty(session.timeSeries.(nameTags{iTag}).nChannels)
                jsonStructure.vc5ra.(idx).fiElD_2976 = session.timeSeries.(nameTags{iTag}).nChannels;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'sr') & ~isempty(session.timeSeries.(nameTags{iTag}).sr)
                jsonStructure.vc5ra.(idx).fiElD_2977 = session.timeSeries.(nameTags{iTag}).sr;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'nSamples') & ~isempty(session.timeSeries.(nameTags{iTag}).nSamples)
                jsonStructure.vc5ra.(idx).fiElD_2978 = session.timeSeries.(nameTags{iTag}).nSamples;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'leastSignificantBit') & ~isempty(session.timeSeries.(nameTags{iTag}).leastSignificantBit)
                jsonStructure.vc5ra.(idx).fiElD_2979 = session.timeSeries.(nameTags{iTag}).leastSignificantBit;
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Time series successfully submitted to db')
        end
        end
    end
    
    function db_update_epochs(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.r0g5h.form = 193; % Form id of epochs repeatable section
        if isfield(session,'epochs')
            for i = 1:length(session.epochs)
                if isfield(session.epochs{i},'entryID') && session.epochs{i}.entryID>0
                    idx = ['fiElD_', num2str(session.epochs{i}.entryID)];
                else
                    idx = ['shank' num2str(i)];
                end
                jsonStructure.r0g5h.(idx).fiElD_2311 = session.epochs{i}.name;
                if isfield(session.epochs{i},'entryID') && session.epochs{i}.entryID>0
                    if isfield(session.epochs{i},'behavioralParadigmID') && ~isempty(session.epochs{i}.behavioralParadigmID)
                        jsonStructure.r0g5h.(idx).fiElD_2598 = session.epochs{i}.behavioralParadigmID;
                    end
                    if isfield(session.epochs{i},'environmentID') && ~isempty(session.epochs{i}.environmentID)
                        jsonStructure.r0g5h.(idx).fiElD_2495 = session.epochs{i}.environmentID;
                    end
                    if isfield(session.epochs{i},'manipulationID') && ~isempty(session.epochs{i}.manipulationID)
                        jsonStructure.r0g5h.(idx).fiElD_2506 = session.epochs{i}.manipulationID;
                    end
                    if isfield(session.epochs{i},'startTime') && ~isempty(session.epochs{i}.startTime)
                        jsonStructure.r0g5h.(idx).fiElD_2971 = session.epochs{i}.startTime;
                    end
                    if isfield(session.epochs{i},'stopTime') && ~isempty(session.epochs{i}.stopTime)
                        jsonStructure.r0g5h.(idx).fiElD_2309 = session.epochs{i}.stopTime;
                    end
                    if isfield(session.epochs{i},'notes') && ~isempty(session.epochs{i}.notes)
                        jsonStructure.r0g5h.(idx).fiElD_2314 = session.epochs{i}.notes;
                    end
%                     keyboard
                end
            end
            jsonStructure = jsonencode(jsonStructure);
            jsonStructure = strrep(jsonStructure,'fiElD_','');
            options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
            RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
            if RESPONSE.success==1
                disp('Epochs successfully submitted to db')
            end
        end
    end
    
    
    
    function db_update_electrodeGroups(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.vtcx9.form = 219; % Form id of spikeGroups repeatable section
        jsonStructure.fiElD_2983 = session.extracellular.nElectrodeGroups; % nElectrodeGroups
        
        for i = 1:session.extracellular.nElectrodeGroups
            idx = ['shank' num2str(i)];
            channels = sprintf('%.0f, ' , session.extracellular.electrodeGroups.channels{i}); channels = channels(1:end-2);
            jsonStructure.vtcx9.(idx).fiElD_2933 = i;           % Group
            jsonStructure.vtcx9.(idx).fiElD_2934 = channels;    % Channels
            jsonStructure.vtcx9.(idx).fiElD_2935 = '';          % Label
            jsonStructure.vtcx9.(idx).fiElD_2984 = '1';         % Counter
        end
        
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Electrode groups successfully submitted to db')
        end
    end

    function db_update_spikeGroups(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.ca5yu.form = 191; % Form id of spikeGroups repeatable section
        jsonStructure.fiElD_2463 = session.extracellular.nSpikeGroups;  % nSpikeGroups
        
        for i = 1:session.extracellular.nSpikeGroups
            idx = ['shank' num2str(i)];
            channels = sprintf('%.0f, ' , session.extracellular.spikeGroups.channels{i}); channels = channels(1:end-2);
            jsonStructure.ca5yu.(idx).fiElD_2460 = i;           % Group
            jsonStructure.ca5yu.(idx).fiElD_2461 = channels;    % Channels
            jsonStructure.ca5yu.(idx).fiElD_2562 = '';          % Label
            jsonStructure.ca5yu.(idx).fiElD_2462 = '1';         % Counter
        end
        
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Spike groups successfully submitted to db')
        end
    end
    
    function db_update_channelTags(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.uflqe.form = 149; % Form id of channelTags repeatable section
        
        nameTags = fieldnames(session.channelTags);
        for iTag = 1:length(nameTags)
            if isfield(session.channelTags.(nameTags{iTag}),'entryID') && session.channelTags.(nameTags{iTag}).entryID>0
                idx = ['fiElD_', num2str(session.channelTags.(nameTags{iTag}).entryID)];
            else
                idx = ['shank' num2str(iTag)];
            end
            jsonStructure.uflqe.(idx).fiElD_1949 = nameTags{iTag};
            
            if isfield(session.channelTags.(nameTags{iTag}),'channels') & ~isempty(session.channelTags.(nameTags{iTag}).channels)
                channels = sprintf('%.0f, ' , session.channelTags.(nameTags{iTag}).channels); channels = channels(1:end-2);
                jsonStructure.uflqe.(idx).fiElD_1950 = channels;
            end
            if isfield(session.channelTags.(nameTags{iTag}),'spikeGroups') & ~isempty(session.channelTags.(nameTags{iTag}).spikeGroups)
                spikeGroups = sprintf('%.0f, ' , session.channelTags.(nameTags{iTag}).spikeGroups); spikeGroups = spikeGroups(1:end-2);
                jsonStructure.uflqe.(idx).fiElD_2360 = spikeGroups;
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Channel tags successfully submitted to db')
        end
    end

    function db_update_brainRegions(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.sessionbrainregions.form = 148; % Form id of brainRegions repeatable section
        load('BrainRegions.mat','BrainRegions')
        
        brainRegionAcronyms = fieldnames(session.brainRegions);
        for iTag = 1:length(brainRegionAcronyms)
            if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'entryID') && session.brainRegions.(brainRegionAcronyms{iTag}).entryID>0
                idx = ['fiElD_', num2str(session.brainRegions.(brainRegionAcronyms{iTag}).entryID)];
            else
                idx = ['shank' num2str(iTag)];
            end
            
            idx2 = find(strcmp(brainRegionAcronyms{iTag},BrainRegions(:,2)));
            if ~isempty(idx2)
                jsonStructure.sessionbrainregions.(idx).fiElD_1943 = BrainRegions(idx2,6); 
                jsonStructure.sessionbrainregions.(idx).fiElD_2518 = brainRegionAcronyms{iTag};
                
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'channels') && ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).channels)
                    channels = sprintf('%.0f, ' , session.brainRegions.(brainRegionAcronyms{iTag}).channels); channels = channels(1:end-2);
                    jsonStructure.sessionbrainregions.(idx).fiElD_1944 = channels;
                end
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'spikeGroups') && ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).spikeGroups)
                    spikeGroups = sprintf('%.0f, ' , session.brainRegions.(brainRegionAcronyms{iTag}).spikeGroups); spikeGroups = spikeGroups(1:end-2);
                    jsonStructure.sessionbrainregions.(idx).fiElD_1945 = spikeGroups;
                end
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'notes') && ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).notes)
                    notes = session.brainRegions.(brainRegionAcronyms{iTag}).notes;
                    jsonStructure.sessionbrainregions.(idx).fiElD_2746 = notes;
                end
            end
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Brain regions successfully submitted to db')
        end
    end

end