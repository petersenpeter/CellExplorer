function session = db_update_session(session)
bz_database = db_credentials;
web_address = [bz_database.rest_api.address, 'entries/' session.General.EntryID];
cd(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.General.Name))


if session.General.Duration == 0
    Intan_rec_info = read_Intan_RHD2000_file_Peter(pwd);
    fname = [session.General.Name '.dat'];
    
    nChannels = size(Intan_rec_info.amplifier_channels,2);
    Sr = Intan_rec_info.frequency_parameters.amplifier_sample_rate;
    SrLFP = Sr/16;
    temp_ = dir(fname); 
    Duration = temp_.bytes/Sr/nChannels/2; 
    nSamples = temp_.bytes/nChannels/2;
    Precision = 'int16';
    FileFormat = 'dat';
    SpikeGroups = 'dat';

    [par,rxml] = LoadXml(fullfile([session.General.Name '.xml']));
    SrLFP = par.lfpSampleRate;
    LFPnChannels
    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    options.CertificateFilename=('');
    webwrite(web_address,options,'form_id','143','h1nhs',nChannels,'wnvla',Sr,'ngvax',Duration,'s2l9r',nSamples,'jr29w',Precision);
    session.General.Duration = Duration;
    session.Extracellular.nChannels = nChannels;
    session.Extracellular.nSamples = nSamples;
    session.Extracellular.Precision = Precision;
    session.Extracellular.Sr = Sr;
    session.Extracellular.SrLFP = SrLFP;
    session.Extracellular.FileFormat = FileFormat;
    session.Extracellular.SpikeGroups = SpikeGroups;
end

if any(session.SubSessions.Duration == 0)
    Duration = [];
%     Duration_string = '{ "form_id" : 143, "r0g5h": { '
    for i = 1:size(session.SubSessions.Name,2)
        % fname = [session.SubSessions.Name{1} '.dat'];
        fname = 'amplifier.dat';
        temp_ = dir(fullfile(bz_database.repositories.(session.General.Repositories{1}), session.General.Animal, session.SubSessions.Name{i}, fname));
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
