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

% General
if any(contains(fields,{'general','all'})) 
    
end

% Extracellular
if any(contains(fields,{'extracellular','all'})) 
    % Updating fields
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
    options.CertificateFilename=('');
    webwrite(db_settings.web_address,options,'form_id','143','h1nhs',session.extracellular.nChannels,'wnvla',session.extracellular.sr,'ngvax',session.general.duration,'s2l9r',session.extracellular.nSamples,'jr29w',session.extracellular.precision);
    
    % Electrode groups
    db_update_electrodeGroups(session,db_settings)
    % Spike groups
    db_update_spikeGroups(session,db_settings)
end

% Epochs
if any(contains(fields,{'epochs','all'})) 
    db_update_epochs(session,db_settings)
end

% Channel tags
if any(contains(fields,{'channelTags','all'})) 
    db_update_channelTags(session,db_settings)
end

% Brain regions
if any(contains(fields,{'brainRegions','all'})) 
    db_update_brainRegions(session,db_settings)
end

% Time series
if any(contains(fields,{'timeSeries','all'})) 
    db_update_TimeSeries(session,db_settings)
end
% inputs
% behavioralTracking
% analysisStats
% analysisTags
% spikeSorting

success = true;

%% % % % % % % % % % % % % % % % % % % %
% Builtin functions
% % % % % % % % % % % % % % % % % % % %

    function db_update_TimeSeries(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.vc5ra.form = 223; % Form id of time series repeatable section
        
        nameTags = fieldnames(session.timeSeries);
        for iTag = 1:length(nameTags)
            shank_label = ['shank' num2str(iTag)];
            jsonStructure.vc5ra.(shank_label).fiElD_2982 = nameTags{iTag};
            jsonStructure.vc5ra.(shank_label).fiElD_2974 = session.timeSeries.(nameTags{iTag}).fileName;
            if isfield(session.timeSeries.(nameTags{iTag}),'precision')
                jsonStructure.vc5ra.(shank_label).fiElD_2975 = session.timeSeries.(nameTags{iTag}).precision;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'nChannels') & ~isempty(session.timeSeries.(nameTags{iTag}).nChannels)
                jsonStructure.vc5ra.(shank_label).fiElD_2976 = session.timeSeries.(nameTags{iTag}).nChannels;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'sr') & ~isempty(session.timeSeries.(nameTags{iTag}).sr)
                jsonStructure.vc5ra.(shank_label).fiElD_2977 = session.timeSeries.(nameTags{iTag}).sr;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'nSamples') & ~isempty(session.timeSeries.(nameTags{iTag}).nSamples)
                jsonStructure.vc5ra.(shank_label).fiElD_2978 = session.timeSeries.(nameTags{iTag}).nSamples;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'leastSignificantBit') & ~isempty(session.timeSeries.(nameTags{iTag}).leastSignificantBit)
                jsonStructure.vc5ra.(shank_label).fiElD_2979 = session.timeSeries.(nameTags{iTag}).leastSignificantBit;
            end
            if isfield(session.timeSeries.(nameTags{iTag}),'equipment')
                jsonStructure.vc5ra.(shank_label).fiElD_2980 = session.timeSeries.(nameTags{iTag}).equipment;
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
    
    function db_update_epochs(session,db_settings)
        for i = 1:length(session.epochs)
            if isfield(session.epochs{i},'startTime')
                startTime = session.epochs{i}.startTime;
            else
                startTime = 0;
            end
            if isfield(session.epochs{i},'stopTime')
                stopTime = session.epochs{i}.stopTime;
            else
                stopTime = 0;
            end
            web_address1 = [db_settings.address,'entries/', num2str(session.epochs{i}.entryID)];
            options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
            webwrite(web_address1,options,'tsr5t',startTime,'5ssi4',stopTime);
        end
        disp('Epochs successfully submitted to db')
    end
    
    
    function db_update_electrodeGroups(session,db_settings)
        jsonStructure = [];
        jsonStructure.form_id = 143; % Form id of sessions
        jsonStructure.vtcx9.form = 219; % Form id of spikeGroups repeatable section
        jsonStructure.fiElD_2983 = session.extracellular.nElectrodeGroups; % nElectrodeGroups
        
        for i = 1:session.extracellular.nElectrodeGroups
            shank_label = ['shank' num2str(i)];
            channels = sprintf('%.0f, ' , session.extracellular.electrodeGroups.channels{i}); channels = channels(1:end-2);
            jsonStructure.vtcx9.(shank_label).fiElD_2933 = i;           % Group
            jsonStructure.vtcx9.(shank_label).fiElD_2934 = channels;    % Channels
            jsonStructure.vtcx9.(shank_label).fiElD_2935 = '';          % Label
            jsonStructure.vtcx9.(shank_label).fiElD_2984 = '1';         % Counter
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
            shank_label = ['shank' num2str(i)];
            channels = sprintf('%.0f, ' , session.extracellular.spikeGroups.channels{i}); channels = channels(1:end-2);
            jsonStructure.ca5yu.(shank_label).fiElD_2460 = i;           % Group
            jsonStructure.ca5yu.(shank_label).fiElD_2461 = channels;    % Channels
            jsonStructure.ca5yu.(shank_label).fiElD_2562 = '';          % Label
            jsonStructure.ca5yu.(shank_label).fiElD_2462 = '1';         % Counter
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
        
        namesChannelTags = fieldnames(session.channelTags);
        for iTag = 1:length(namesChannelTags)
            shank_label = ['shank' num2str(iTag)];
            jsonStructure.uflqe.(shank_label).fiElD_1949 = namesChannelTags{iTag};
            
            if isfield(session.channelTags.(namesChannelTags{iTag}),'channels') & ~isempty(session.channelTags.(namesChannelTags{iTag}).channels)
                channels = sprintf('%.0f, ' , session.channelTags.(namesChannelTags{iTag}).channels); channels = channels(1:end-2);
                jsonStructure.uflqe.(shank_label).fiElD_1950 = channels;
            end
            if isfield(session.channelTags.(namesChannelTags{iTag}),'spikeGroups') & ~isempty(session.channelTags.(namesChannelTags{iTag}).spikeGroups)
                spikeGroups = sprintf('%.0f, ' , session.channelTags.(namesChannelTags{iTag}).spikeGroups); spikeGroups = spikeGroups(1:end-2);
                jsonStructure.uflqe.(shank_label).fiElD_2360 = spikeGroups;
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
        load BrainRegions.mat
        
        brainRegionAcronyms = fieldnames(session.brainRegions);
        for iTag = 1:length(brainRegionAcronyms)
            shank_label = ['shank' num2str(iTag)];
            
            idx = find(strcmp(brainRegionAcronyms{iTag},BrainRegions(:,2)));
            if ~isempty(idx)
                jsonStructure.sessionbrainregions.(shank_label).fiElD_1943 = BrainRegions(idx,6); 
                jsonStructure.sessionbrainregions.(shank_label).fiElD_2518 = brainRegionAcronyms{iTag};
                
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'channels') & ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).channels)
                    channels = sprintf('%.0f, ' , session.brainRegions.(brainRegionAcronyms{iTag}).channels); channels = channels(1:end-2);
                    jsonStructure.sessionbrainregions.(shank_label).fiElD_1944 = channels;
                end
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'spikeGroups') & ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).spikeGroups)
                    spikeGroups = sprintf('%.0f, ' , session.brainRegions.(brainRegionAcronyms{iTag}).spikeGroups); spikeGroups = spikeGroups(1:end-2);
                    jsonStructure.sessionbrainregions.(shank_label).fiElD_1945 = spikeGroups;
                end
                if isfield(session.brainRegions.(brainRegionAcronyms{iTag}),'notes') & ~isempty(session.brainRegions.(brainRegionAcronyms{iTag}).notes)
                    notes = session.brainRegions.(brainRegionAcronyms{iTag}).notes;
                    jsonStructure.sessionbrainregions.(shank_label).fiElD_2746 = notes;
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