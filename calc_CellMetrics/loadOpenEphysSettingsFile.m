function session = loadOpenEphysSettingsFile(file1,session,varargin)
% Loading structure.oebin -  a json structure created by OpenEphys
% file1 = '/Users/peterpetersen/Databank/OpenEphys/structure_5.oebin';

% https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html
%
% Neuropixels channel coordinates: the probe type is read from the probe part number in the Record
% Node's settings.xml when available, otherwise inferred from the streams (Neuropixels 1.0 records a
% separate LFP stream); Neuropixels 2.0 geometry is used, with a warning, when neither tells.
% GUI versions other than 0.6.7 and 1.0.1: only sampling rate, channel count and bit_volts are
% imported (with a warning); set channel coordinates and electrode groups in gui_session.

p = inputParser;
addParameter(p,'probeLetter','A',@ischar);

% Parsing inputs
parse(p,varargin{:})
parameters = p.Results;

switch parameters.probeLetter
    case 'A'
        stream_id = 1;
    case 'B'
        stream_id = 2;
    case 'C'
        stream_id = 3;
    otherwise
        stream_id = 1;
end

if exist(file1,'file')
    disp(['Loading Open Ephys settings: ', file1])
    text = fileread(file1);
    openEphys_metadata=jsondecode(text);

    if strcmp(openEphys_metadata.GUIVersion, '0.6.7')
        % Importing metadata
        session.extracellular.sr = openEphys_metadata.continuous(stream_id).sample_rate;
        session.extracellular.nChannels = openEphys_metadata.continuous(stream_id).num_channels;
        session.extracellular.equipment = 'OpenEpys Neuropix-PXI';
        session.extracellular.leastSignificantBit = 0.195;
        session.extracellular.fileFormat = 'dat';
        session.extracellular.precision = 'int16';
        session.extracellular.fileName = '';
        
        % Electrode groups and channel mapping
        channelmapping = [];
        for i = 1:session.extracellular.nChannels
            if isstruct(openEphys_metadata.continuous(stream_id).channels) 
                if isfield(openEphys_metadata.continuous(stream_id).channels(i),'channel_metadata')
                    channelmapping(i) = openEphys_metadata.continuous(stream_id).channels(i).channel_metadata.value+1;
                end
            elseif isfield(openEphys_metadata.continuous(stream_id).channels{i},'channel_metadata')
                channelmapping(i) = openEphys_metadata.continuous(stream_id).channels{i}.channel_metadata.value+1;
            end
        end
    
        chanCoords = neuropixelsChanCoords(file1,openEphys_metadata,parameters.probeLetter);
    
        session.extracellular.chanCoords = chanCoords;
        session.extracellular.chanCoords.x = chanCoords.x(channelmapping);
        session.extracellular.chanCoords.y = chanCoords.y(channelmapping);
        session.extracellular.chanCoords.shank = chanCoords.shank(channelmapping);
        session.extracellular.chanCoords.channels = chanCoords.channels(channelmapping);
    
        session.extracellular.electrodeGroups.channels = {};
        
        shanks = unique(session.extracellular.chanCoords.shank);
        for j = 1:length(shanks)
            session.extracellular.electrodeGroups.channels{j} = find(session.extracellular.chanCoords.shank == shanks(j));
            [~,idx] = sortrows([...
                session.extracellular.chanCoords.x(session.extracellular.electrodeGroups.channels{j});...
                session.extracellular.chanCoords.y(session.extracellular.electrodeGroups.channels{j})...
                ]',[2,1],{'descend','ascend'});
            session.extracellular.electrodeGroups.channels{j} = session.extracellular.electrodeGroups.channels{j}(idx);
            session.extracellular.electrodeGroups.label{j} = ['shanks',num2str(shanks(j))];
        end
        session.extracellular.nElectrodeGroups = length(shanks);
    
        figure
        plot(chanCoords.x,chanCoords.y,'.k'), hold on
        site_cmap = hot(session.extracellular.nElectrodeGroups);
        for j = 1:session.extracellular.nElectrodeGroups
            x = session.extracellular.chanCoords.x(session.extracellular.electrodeGroups.channels{j});
            y = session.extracellular.chanCoords.y(session.extracellular.electrodeGroups.channels{j});
            plot(x,y,'s',MarkerFaceColor=site_cmap(j,:))
        end
        xlabel('X position (µm)'), ylabel('Y position (µm)'), title('Neuropixel site selection', file1)
        axis equal
    
        session.extracellular.spikeGroups.channels = session.extracellular.electrodeGroups.channels;
        session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups;
    
        % LFP data stream (only when the second stream is a lower-rate LFP stream; a second probe's AP stream is not)
        if length(openEphys_metadata.continuous)>1
            if openEphys_metadata.continuous(2).sample_rate < session.extracellular.sr
                session.extracellular.srLfp = openEphys_metadata.continuous(2).sample_rate;
            else
                warning('loadOpenEphysSettingsFile: no LFP stream found (second stream is %g Hz); session.extracellular.srLfp was not set',openEphys_metadata.continuous(2).sample_rate)
            end
        end
    
        % Loading events from timestamps
        session.timeSeries.dig.fileName = [openEphys_metadata.events{1}.folder_name,'timestamps.npy'];
        session.timeSeries.dig.fileFormat = 'npy';
        session.timeSeries.dig.precision  = openEphys_metadata.events{1}.type;
        %session.timeSeries.dig.nChannels = openEphys_metadata.events{1}.num_channels;
        session.timeSeries.dig.nChannels = 1;
        session.timeSeries.dig.sr = openEphys_metadata.events{1}.sample_rate;
        session.timeSeries.dig.equipment = 'OpenEpys Neuropix-PXI';
        session.timeSeries.dig.nSamples = [];
        session.timeSeries.dig.leastSignificantBit = [];
    end


    if strcmp(openEphys_metadata.GUIVersion, '1.0.1')
        % Importing metadata
        session.extracellular.sr = openEphys_metadata.continuous(stream_id).sample_rate;
        session.extracellular.nChannels = openEphys_metadata.continuous(stream_id).num_channels;
        session.extracellular.equipment = 'Open Ephys Neuropix-PXI'; % Fixed typo: "Epys" -> "Ephys"
        session.extracellular.leastSignificantBit = 0.195;
        session.extracellular.fileFormat = 'dat';
        session.extracellular.precision = 'int16';
        session.extracellular.fileName = '';
        
        % Electrode groups and channel mapping
        channelmapping = zeros(1, session.extracellular.nChannels); % Pre-allocate for efficiency
        for i = 1:session.extracellular.nChannels
            if isstruct(openEphys_metadata.continuous(stream_id).channels) 
                if isfield(openEphys_metadata.continuous(stream_id).channels(i),'channel_metadata')
                    % REMOVED +1: The metadata value is now correctly 0-indexed and matches CH0, CH1, etc.
                    channelmapping(i) = openEphys_metadata.continuous(stream_id).channels(i).channel_metadata.value;
                end
            elseif isfield(openEphys_metadata.continuous(stream_id).channels{i},'channel_metadata')
                % REMOVED +1: The metadata value is now correctly 0-indexed and matches CH0, CH1, etc.
                channelmapping(i) = openEphys_metadata.continuous(stream_id).channels{i}.channel_metadata.value;
            end
        end
    
        chanCoords = neuropixelsChanCoords(file1,openEphys_metadata,parameters.probeLetter);
    
        session.extracellular.chanCoords = chanCoords;
        session.extracellular.chanCoords.x = chanCoords.x(channelmapping + 1); % Add 1 here if generateChanCoords_Neuropixel2 is 1-indexed
        session.extracellular.chanCoords.y = chanCoords.y(channelmapping + 1);
        session.extracellular.chanCoords.shank = chanCoords.shank(channelmapping + 1);
        session.extracellular.chanCoords.channels = chanCoords.channels(channelmapping + 1);
    
        session.extracellular.electrodeGroups.channels = {};
        
        shanks = unique(session.extracellular.chanCoords.shank);
        for j = 1:length(shanks)
            session.extracellular.electrodeGroups.channels{j} = find(session.extracellular.chanCoords.shank == shanks(j));
            [~,idx] = sortrows([...
                session.extracellular.chanCoords.x(session.extracellular.electrodeGroups.channels{j});...
                session.extracellular.chanCoords.y(session.extracellular.electrodeGroups.channels{j})...
                ]',[2,1],{'descend','ascend'});
            session.extracellular.electrodeGroups.channels{j} = session.extracellular.electrodeGroups.channels{j}(idx);
            session.extracellular.electrodeGroups.label{j} = ['shanks',num2str(shanks(j))]; 
        end
        session.extracellular.nElectrodeGroups = length(shanks);
    
        figure
        plot(chanCoords.x,chanCoords.y,'.k'), hold on
        site_cmap = hot(session.extracellular.nElectrodeGroups);
        for j = 1:session.extracellular.nElectrodeGroups
            x = session.extracellular.chanCoords.x(session.extracellular.electrodeGroups.channels{j});
            y = session.extracellular.chanCoords.y(session.extracellular.electrodeGroups.channels{j});
            plot(x,y,'s',MarkerFaceColor=site_cmap(j,:))
        end
        xlabel('X position (µm)'), ylabel('Y position (µm)'), title(['Neuropixel site selection: ', file1]) % Fixed title to show filename
        axis equal
    
        session.extracellular.spikeGroups.channels = session.extracellular.electrodeGroups.channels;
        session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups;
    
        % LFP data stream (only when the second stream is a lower-rate LFP stream; a second probe's AP stream is not)
        if length(openEphys_metadata.continuous)>1
            if openEphys_metadata.continuous(2).sample_rate < session.extracellular.sr
                session.extracellular.srLfp = openEphys_metadata.continuous(2).sample_rate;
            else
                warning('loadOpenEphysSettingsFile: no LFP stream found (second stream is %g Hz); session.extracellular.srLfp was not set',openEphys_metadata.continuous(2).sample_rate)
            end
        end
    
        % Loading events from timestamps
        % Check if events array is not empty
        if ~isempty(openEphys_metadata.events)
            session.timeSeries.dig.fileName = [openEphys_metadata.events{1}.folder_name,'timestamps.npy'];
            session.timeSeries.dig.fileFormat = 'npy';
            session.timeSeries.dig.precision  = openEphys_metadata.events{1}.type;
            session.timeSeries.dig.nChannels = 1;
            session.timeSeries.dig.sr = openEphys_metadata.events{1}.sample_rate;
            session.timeSeries.dig.equipment = 'Open Ephys Neuropix-PXI'; % Fixed typo
            session.timeSeries.dig.nSamples = [];
            session.timeSeries.dig.leastSignificantBit = [];
        else
            warning('No events found in the structure.oebin file.');
        end
    end

    if ~any(strcmp(openEphys_metadata.GUIVersion, {'0.6.7','1.0.1'}))
        % Unsupported GUI version: import what the oebin format reliably holds and say what is missing
        % (previously the session struct silently kept its template defaults)
        if ~isfield(openEphys_metadata,'continuous') || numel(openEphys_metadata.continuous) < stream_id
            error('loadOpenEphysSettingsFile: Open Ephys GUI version %s is not supported and %s has no continuous stream %d to import from.',openEphys_metadata.GUIVersion,file1,stream_id)
        end
        stream = openEphys_metadata.continuous(stream_id);
        if iscell(stream), stream = stream{1}; end
        session.extracellular.sr = stream.sample_rate;
        session.extracellular.nChannels = stream.num_channels;
        session.extracellular.fileFormat = 'dat';
        session.extracellular.precision = 'int16';
        session.extracellular.fileName = '';
        lsbNote = '';
        if isfield(stream,'channels') && ~isempty(stream.channels)
            ch1 = stream.channels(1); if iscell(ch1), ch1 = ch1{1}; end
            if isfield(ch1,'bit_volts'), session.extracellular.leastSignificantBit = ch1.bit_volts; else, lsbNote = ', leastSignificantBit'; end
        else
            lsbNote = ', leastSignificantBit';
        end
        warning(['loadOpenEphysSettingsFile: Open Ephys GUI version %s is not supported. Imported sr (%g Hz) and nChannels (%d) from %s. ', ...
            'Not imported: channel coordinates, electrode groups, srLfp%s. Set them in gui_session before processing.'], ...
            openEphys_metadata.GUIVersion,session.extracellular.sr,session.extracellular.nChannels,file1,lsbNote)
    end
else
    warning(['Failed to load Open Ephys settings: ', file1])
end
end

function chanCoords = neuropixelsChanCoords(file1,openEphys_metadata,probeLetter)
% Neuropixels 1.0 or 2.0 electrode coordinates, chosen from the recording's metadata
probeType = '';
source = '';
% 1. Probe part numbers in the Record Node's settings.xml (oebin: <Record Node>/experimentN/recordingM/structure.oebin)
recordNode = fileparts(fileparts(fileparts(file1)));
settingsFiles = [dir(fullfile(recordNode,'settings.xml')); dir(fullfile(recordNode,'settings_*.xml'))];
settingsFiles = settingsFiles(1:min(1,end)); % one settings file: later experiments repeat the same probes
partNumbers = {};
for i = 1:numel(settingsFiles)
    txt = fileread(fullfile(settingsFiles(i).folder,settingsFiles(i).name));
    tokens = regexp(txt,'probe_part_number="([^"]+)"','tokens');
    partNumbers = [partNumbers, cellfun(@(t) t{1},tokens,'UniformOutput',false)]; %#ok<AGROW>
end
if ~isempty(partNumbers)
    idx = double(upper(probeLetter(1)))-64; % probe A -> first probe listed
    if idx < 1 || idx > numel(partNumbers), idx = 1; end
    pn = partNumbers{idx};
    if any(strcmp(pn,{'PRB_1_4_0480_1','PRB_1_4_0480_1_C','PRB_1_2_0480_2','NP1010','NP1011','NP1012','NP1013'}))
        probeType = 'NP1';
    elseif startsWith(pn,'PRB2_') || any(strcmp(pn,{'NP2000','NP2003','NP2004','NP2010','NP2013','NP2014'}))
        probeType = 'NP2';
    else
        warning('loadOpenEphysSettingsFile: probe part number %s has no supported geometry here; check the channel coordinates',pn)
    end
    source = ['probe part number ',pn];
end
% 2. Only AP/LFP streams belonging to the requested probe identify its geometry.
% A different probe's LFP stream (or an unrelated 2500 Hz stream) is not evidence.
% Unnamed/custom streams remain ambiguous and use the warning/default below.
if isempty(probeType) && isfield(openEphys_metadata,'continuous')
    probeName = regexptranslate('escape',['Probe',upper(probeLetter)]);
    streamPattern = ['(^|[. /\\])',probeName,'-(AP|LFP)($|[/\\ ])'];
    for k = 1:numel(openEphys_metadata.continuous)
        st = openEphys_metadata.continuous(k); if iscell(st), st = st{1}; end
        names = {};
        if isfield(st,'stream_name'), names{end+1} = st.stream_name; end
        if isfield(st,'folder_name'), names{end+1} = st.folder_name; end
        if any(~cellfun(@isempty,regexp(names,streamPattern,'once')))
            probeType = 'NP1';
            source = ['AP/LFP stream for Probe',upper(probeLetter)];
            break
        end
    end
end
if isempty(probeType)
    warning('loadOpenEphysSettingsFile: the Neuropixels probe type is not stated in the metadata; using Neuropixels 2.0 geometry. Check the channel coordinates.')
    probeType = 'NP2';
    source = 'default';
end
switch probeType
    case 'NP1'
        chanCoords = generateChanCoords_Neuropixel1;
    otherwise
        chanCoords = generateChanCoords_Neuropixel2;
end
chanCoords.probeTypeSource = source;
disp(['Neuropixels geometry: ',chanCoords.source,' (',source,')'])
end
