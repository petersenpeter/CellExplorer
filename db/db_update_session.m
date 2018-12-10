function session = db_update_session(session)
bz_database = db_credentials;
web_address = [bz_database.rest_api.address, 'entries/' session.General.EntryID];
cd(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))

if session.General.Duration == 0
    Intan_rec_info = read_Intan_RHD2000_file_Peter(pwd);
    fname = [session.General.Name '.dat'];
    nChannels = size(Intan_rec_info.amplifier_channels,2);
%     Sr = Intan_rec_info.frequency_parameters.amplifier_sample_rate;
    temp_ = dir(fname);

    session.Extracellular.nChannels = nChannels;
    session.Extracellular.FileFormat = 'dat';
    session.Extracellular.Precision = 'int16';
    session.Extracellular.nSamples = temp_.bytes/nChannels/2;
    session.General.Duration = temp_.bytes/Sr/nChannels/2;
    
    sessionInfo = bz_getSessionInfo(session.General.BasePath,'noPrompts',true);
    session.Extracellular.nChannels = sessionInfo.nChannels; % Number of channels
    session.Extracellular.nGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
    session.Extracellular.Groups = sessionInfo.spikeGroups.groups; % Spike groups
    session.Extracellular.Sr = sessionInfo.rates.wideband; % Sampling rate of dat file
    session.Extracellular.SrLFP = sessionInfo.rates.lfp; % Sampling rate of lfp file
    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    options.CertificateFilename=('');
    webwrite(web_address,options,'form_id','143','h1nhs',session.Extracellular.nChannels,'wnvla',session.Extracellular.Sr,'ngvax',session.General.Duration,'s2l9r',session.Extracellular.nSamples,'jr29w',session.Extracellular.Precision);
end

if any(session.SubSessions.Duration == 0)
    Duration = [];
%     Duration_string = '{ "form_id" : 143, "r0g5h": { '
    for i = 1:size(session.SubSessions.Name,2)
        % fname = [session.SubSessions.Name{1} '.dat'];
        fname = 'amplifier.dat';
        if exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.SubSessions.Name{i}, fname))
            temp_ = dir(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.SubSessions.Name{i}, fname));
        elseif exist(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.SubSessions.Name{i}, [session.SubSessions.Name{i},'.dat']))
            temp_ = dir(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.SubSessions.Name{i}, [session.SubSessions.Name{i},'.dat']));
        end
        Duration(i) = temp_.bytes/session.Extracellular.Sr/session.Extracellular.nChannels/2;
%         Duration_string = [Duration_string, ' "', num2str(session.SubSessions.SubSessionIds(i)), '" : { "2309" : 10 },' ];
        web_address1 = [bz_database.rest_api.address,'entries/', num2str(session.SubSessions.EntryIDs(i))];
        options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
        webwrite(web_address1,options,'5ssi4',Duration(i));
    end
%     Duration_string = [Duration_string(1:end-1), '}}']
    
    session.SubSessions.Duration = Duration;
%     options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    %webwrite(web_address,options,Duration_string);
end
