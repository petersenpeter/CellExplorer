function session = loadIntanMetadata(session,basepathIn)
% Loads info about time series from the Intan metadatafile info.rhd
%
% dependencies: read_Intan_RHD2000_file_from_basepath

% Check the website of the CellExplorer for more details: https://petersenpeter.github.io/CellExplorer/

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated 30-01-2020

if exist('basepathIn','var')
    basepath = basepathIn;
elseif isfield(session.general,'basePath')
    basepath = session.general.basePath;
else
    error('loadIntanMetadata: Please provide a basepath either as a secondary input or through the session struct: ''session.general.basePath''')
end
if exist(fullfile(basepath,'info.rhd'),'file')
    if exist('read_Intan_RHD2000_file_from_basepath','file')
        Intan_rec_info = read_Intan_RHD2000_file_from_basepath(basepath);
        if isfield(session,'timeSeries') && iscell(session.timeSeries)
            warning('session.timeSeries not formatted correctly. Overwriting existing structure.')
            session.timeSeries = [];
        end
        if isfield(Intan_rec_info,'board_adc_channels')
            session.timeSeries.adc.fileName  = 'analogin.dat';
            session.timeSeries.adc.precision  = 'uint16';
            session.timeSeries.adc.nChannels  = size(Intan_rec_info.board_adc_channels,2);
            session.timeSeries.adc.sr = Intan_rec_info.frequency_parameters.board_adc_sample_rate;
            fileinfo = dir(fullfile(session.general.basePath,session.timeSeries.adc.fileName));
            if ~isempty(fileinfo)
                session.timeSeries.adc.nSamples = fileinfo.bytes/(session.timeSeries.adc.nChannels * 2); % uint16 = 2 bytes
            else
                session.timeSeries.adc.nSamples = 0;
            end
            session.timeSeries.adc.leastSignificantBit  = 50.354; % uV
            session.timeSeries.adc.equipment = 'Intan Technologies, RHD2000 USB interface board (256ch)';
        end
        if isfield(Intan_rec_info,'aux_input_channels')
            session.timeSeries.aux.fileName  = 'auxiliary.dat';
            session.timeSeries.aux.precision  = 'uint16';
            session.timeSeries.aux.nChannels  = size(Intan_rec_info.aux_input_channels,2);
            session.timeSeries.aux.sr = Intan_rec_info.frequency_parameters.aux_input_sample_rate;
            fileinfo = dir(fullfile(session.general.basePath,session.timeSeries.aux.fileName));
            if ~isempty(fileinfo)
                session.timeSeries.aux.nSamples = fileinfo.bytes/(session.timeSeries.aux.nChannels * 2); % uint16 = 2 bytes
            else
                session.timeSeries.aux.nSamples = 0;
            end
            session.timeSeries.aux.leastSignificantBit  = 37.4; % uV
            session.timeSeries.aux.equipment = 'Intan Technologies, RHD2000 USB interface board (256ch)';
        end
        if isfield(Intan_rec_info,'board_dig_in_channels')
            session.timeSeries.dig.fileName  = 'digitalin.dat';
            session.timeSeries.dig.precision  = 'int16';
            session.timeSeries.dig.nChannels  = size(Intan_rec_info.board_dig_in_channels,2);
            session.timeSeries.dig.sr = Intan_rec_info.frequency_parameters.board_dig_in_sample_rate;
            fileinfo = dir(fullfile(session.general.basePath,session.timeSeries.dig.fileName));
            if ~isempty(fileinfo)
                session.timeSeries.dig.nSamples = fileinfo.bytes/2; % uint16 = 2 bytes
            else
                session.timeSeries.dig.nSamples = 0;
            end
            session.timeSeries.dig.leastSignificantBit  = 0; % Check correct value
            session.timeSeries.dig.equipment = 'Intan Technologies, RHD2000 USB interface board (256ch)';
        end
        if isfield(Intan_rec_info,'amplifier_channels')
            session.timeSeries.dat.fileName  = [session.general.name,'.dat'];
            session.timeSeries.dat.precision  = 'uint16';
            session.timeSeries.dat.nChannels  = size(Intan_rec_info.amplifier_channels,2);
            session.timeSeries.dat.sr = Intan_rec_info.frequency_parameters.amplifier_sample_rate;
            fileinfo = dir(fullfile(session.general.basePath,session.timeSeries.dat.fileName));
            if ~isempty(fileinfo)
                session.timeSeries.dat.nSamples = fileinfo.bytes/2; % uint16 = 2 bytes
            else
                session.timeSeries.dat.nSamples = 0;
            end
            session.timeSeries.dat.leastSignificantBit = 0.195;
            session.timeSeries.dat.equipment = 'Intan Technologies, RHD2000 USB interface board (256ch)';
        end
    else
        warning('read_Intan_RHD2000_file_from_basepath does not exist')
    end
else
    disp('No info.rhd located in basepath')
end
