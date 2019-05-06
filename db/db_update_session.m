function session = db_update_session(session,varargin)
% Peter Petersen
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'forceReload',false,@islogical);

parse(p,varargin{:})

forceReload = p.Results.forceReload;

bz_database = db_credentials;
web_address = [bz_database.rest_api.address, 'entries/' session.general.entryID];
cd(session.general.basePath)
sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);

% % % % % % % % % % % % % % % % % % % % 
% Extracellular
% % % % % % % % % % % % % % % % % % % % 
if session.general.duration == 0 | forceReload
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
    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    options.CertificateFilename=('');
    webwrite(web_address,options,'form_id','143','h1nhs',session.extracellular.nChannels,'wnvla',session.extracellular.sr,'ngvax',session.general.duration,'s2l9r',session.extracellular.nSamples,'jr29w',session.extracellular.precision);
end

% % % % % % % % % % % % % % % % % % % % 
% Subsessions
% % % % % % % % % % % % % % % % % % % % 
if any(session.subSessions.duration == 0) | forceReload
    duration = [];
    for i = 1:size(session.subSessions.name,2)
        fname = 'amplifier.dat';
        if exist(fullfile(bz_database.repositories.(session.general.repositories{1}), session.general.animal, session.subSessions.name{i}, fname))
            temp_ = dir(fullfile(bz_database.repositories.(session.general.repositories{1}), session.general.animal, session.subSessions.name{i}, fname));
        elseif exist(fullfile(bz_database.repositories.(session.general.repositories{1}), session.general.animal, session.subSessions.name{i}, [session.subSessions.name{i},'.dat']))
            temp_ = dir(fullfile(bz_database.repositories.(session.general.repositories{1}), session.general.animal, session.subSessions.name{i}, [session.subSessions.name{i},'.dat']));
        end
        duration(i) = temp_.bytes/session.extracellular.sr/session.extracellular.nChannels/2;
        web_address1 = [bz_database.rest_api.address,'entries/', num2str(session.subSessions.entryIDs(i))];
        options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
        webwrite(web_address1,options,'5ssi4',duration(i));
    end
    
    session.subSessions.duration = duration;
end

% % % % % % % % % % % % % % % % % % % % 
% SpikeGroups
% % % % % % % % % % % % % % % % % % % %  
jsonStructure = [];
jsonStructure.form_id = 143; % Form id of sessions
jsonStructure.ca5yu.form = 191; % Form id of spikeGroups repeatable section
jsonStructure.fiElD_2463 = length(sessionInfo.spikeGroups.groups); % nSpikeGroups

for i = 1:length(sessionInfo.spikeGroups.groups)
    shank_label = ['shank' num2str(i)];
    channels = sprintf('%.0f,' , sessionInfo.spikeGroups.groups{i}); channels = channels(1:end-1);
    jsonStructure.ca5yu.(shank_label).fiElD_2460 = i; % Group
    jsonStructure.ca5yu.(shank_label).fiElD_2461 = channels; % Channels
    jsonStructure.ca5yu.(shank_label).fiElD_2562 = ''; % Label
    jsonStructure.ca5yu.(shank_label).fiElD_2462 = '1'; % Counter
end
jsonStructure = jsonencode(jsonStructure);
jsonStructure = strrep(jsonStructure,'fiElD_','');
options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
% options.CertificateFilename=('');
webwrite(web_address,jsonStructure,options);


% SpikeGroups with form-type submission
% for i = 1:length(sessionInfo.spikeGroups.groups)
%     i
%     if i <= length(session.extracellular.spikeGroups.entryIDs)
%         options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
%         web_address1 = [bz_database.rest_api.address,'entries/', num2str(session.extracellular.spikeGroups.entryIDs(i))];
%         Channels = sprintf('%.0f,' , sessionInfo.spikeGroups.groups{i}); channels = channels(1:end-1);
%         webwrite(web_address1,options,'i08ch',num2str(i),'ji7jw',channels,'wv8l3','1');
%     else
%         warning(['SpikeGroup ' num2str(i), ' has not been updated.'])
%     end
% end