function session = db_update_session(session,varargin)
% Peter Petersen
% petersen.peter@gmail.com
% Last edited: 27-06-2019

p = inputParser;
addParameter(p,'forceReload',false,@islogical);

parse(p,varargin{:})

forceReload = p.Results.forceReload;

db_settings = db_load_settings;
web_address = [db_settings.address, 'entries/' session.general.entryID];
cd(session.general.basePath)
sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);

%% % % % % % % % % % % % % % % % % % % %
% Extracellular
% % % % % % % % % % % % % % % % % % % %
if ~isfield(session.general,'duration') | session.general.duration == 0 | forceReload
    sr = sessionInfo.rates.wideband;
    if exist(fullfile(session.general.basePath,'info.rhd'))
        Intan_rec_info = read_Intan_RHD2000_file_Peter(pwd);
        nChannels = size(Intan_rec_info.amplifier_channels,2);
        sr = Intan_rec_info.frequency_parameters.amplifier_sample_rate;
    elseif exist(fullfile(session.general.clusteringPath,[session.general.baseName, '.xml']))
        xml = LoadXml(fullfile(session.general.clusteringPath,[session.general.baseName, '.xml']));
        nChannels = xml.nChannels;
        sr = xml.SampleRate;
    end
    fname = [session.general.name '.dat'];
    
    temp_ = dir(fname);
    
    session.extracellular.nChannels = nChannels;
    session.extracellular.fileFormat = 'dat';
    session.extracellular.precision = 'int16';
    session.extracellular.nSamples = temp_.bytes/nChannels/2;
    session.general.duration = temp_.bytes/sr/nChannels/2;
    
    session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
    session.extracellular.nGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
    session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
    session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
    session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
    options.CertificateFilename=('');
    webwrite(web_address,options,'form_id','143','h1nhs',session.extracellular.nChannels,'wnvla',session.extracellular.sr,'ngvax',session.general.duration,'s2l9r',session.extracellular.nSamples,'jr29w',session.extracellular.precision);
end

%% % % % % % % % % % % % % % % % % % % %
% Epochs
% % % % % % % % % % % % % % % % % % % %
if isempty(session.epochs.duration) | any(session.epochs.duration == 0) | forceReload
    duration = [];
    for i = 1:size(session.epochs.name,2)
        fname = 'amplifier.dat';
        if exist(fullfile(db_settings.repositories.(session.general.repositories{1}), session.general.animal, session.epochs.name{i}, fname))
            temp_ = dir(fullfile(db_settings.repositories.(session.general.repositories{1}), session.general.animal, session.epochs.name{i}, fname));
        elseif exist(fullfile(db_settings.repositories.(session.general.repositories{1}), session.general.animal, session.epochs.name{i}, [session.epochs.name{i},'.dat']))
            temp_ = dir(fullfile(db_settings.repositories.(session.general.repositories{1}), session.general.animal, session.epochs.name{i}, [session.epochs.name{i},'.dat']));
        end
        duration(i) = temp_.bytes/session.extracellular.sr/session.extracellular.nChannels/2;
        web_address1 = [db_settings.address,'entries/', num2str(session.epochs.entryIDs(i))];
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
        webwrite(web_address1,options,'5ssi4',duration(i));
    end
    
    session.epochs.duration = duration;
end

%% % % % % % % % % % % % % % % % % % % %
% SpikeGroups
% % % % % % % % % % % % % % % % % % % %
jsonStructure = [];
jsonStructure.form_id = 143; % Form id of sessions
jsonStructure.ca5yu.form = 191; % Form id of spikeGroups repeatable section
jsonStructure.fiElD_2463 = length(sessionInfo.spikeGroups.groups); % nSpikeGroups

for i = 1:length(sessionInfo.spikeGroups.groups)
    shank_label = ['shank' num2str(i)];
    channels = sprintf('%.0f, ' , sessionInfo.spikeGroups.groups{i}); channels = channels(1:end-2);
    jsonStructure.ca5yu.(shank_label).fiElD_2460 = i; % Group
    jsonStructure.ca5yu.(shank_label).fiElD_2461 = channels; % Channels
    jsonStructure.ca5yu.(shank_label).fiElD_2562 = ''; % Label
    jsonStructure.ca5yu.(shank_label).fiElD_2462 = '1'; % Counter
end
jsonStructure = jsonencode(jsonStructure);
jsonStructure = strrep(jsonStructure,'fiElD_','');
options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
RESPONSE = webwrite(web_address,jsonStructure,options);
if RESPONSE.success==1
    disp('Spike groups successfully submitted to db')
end

% % % % % % % % % % % % % % % % % % % %
% Channel tags
% % % % % % % % % % % % % % % % % % % %
if isfield(sessionInfo,'badchannels')
    if isfield(session.channelTags,'Bad')
        session.channelTags.Bad.channels = unique([session.channelTags.Bad.channels,sessionInfo.badchannels+1]);
    else
        session.channelTags.Bad.channels = sessionInfo.badchannels+1;
    end
end
if isfield(sessionInfo,'channelTags')
    tagNames = fieldnames(sessionInfo.channelTags);
    for iTag = 1:length(tagNames)
        if isfield(session.channelTags,tagNames{iTag})
            session.channelTags.(tagNames{iTag}).channels = unique([session.channelTags.(tagNames{iTag}).channels,sessionInfo.channelTags.(tagNames{iTag})+1]);
        else
            session.channelTags.(tagNames{iTag}).channels = sessionInfo.channelTags.(tagNames{iTag})+1;
        end
    end
end
db_update_channelTags(session,db_settings)

%% % % % % % % % % % % % % % % % % % % %
% Brain regions
% % % % % % % % % % % % % % % % % % % %
if isfield(sessionInfo,'region')
    load BrainRegions.mat
    regionNames = unique(cellfun(@num2str,sessionInfo.region,'uni',0));
    regionNames(cellfun('isempty',regionNames)) = [];
    for iRegion = 1:length(regionNames)
        if any(strcmp(regionNames(iRegion),BrainRegions(:,2)))
            session.brainRegions.(regionNames{iRegion}).channels = find(strcmp(regionNames(iRegion),sessionInfo.region));
        elseif strcmp(regionNames(iRegion),'HPC')
            session.brainRegions.HIP.channels = find(strcmp(regionNames(iRegion),sessionInfo.region));
        else
            warning(['Select brain region does not exist in the Allen Brain Atlas: ' regionNames{iRegion}])
        end
    end
end
db_update_brainRegions(session,db_settings)

%% % % % % % % % % % % % % % % % % % % %
% Builtin functions
% % % % % % % % % % % % % % % % % % % %
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
        options = weboptions('Username',db_settings.username,'Password',db_settings.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(web_address,jsonStructure,options);
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
        options = weboptions('Username',db_settings.username,'Password',db_settings.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        RESPONSE = webwrite(web_address,jsonStructure,options);
        if RESPONSE.success==1
            disp('Brain regions successfully submitted to db')
        end
    end

end