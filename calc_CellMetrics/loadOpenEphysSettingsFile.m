function session = loadOpenEphysSettingsFile(file1,session)
% Loading structure.oebin -  a json structure created by OpenEphys
% file1 = '/Users/peterpetersen/Databank/OpenEphys/structure_5.oebin';

% https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html

if exist(file1,'file')
    disp(['Loading Open Ephys settings: ', file1])
    text = fileread(file1);
    openEphys_metadata=jsondecode(text);

    if strcmp(openEphys_metadata.GUIVersion, '0.6.7')
        % Importing metadata
        session.extracellular.sr = openEphys_metadata.continuous(1).sample_rate;
        session.extracellular.nChannels = openEphys_metadata.continuous(1).num_channels;
        session.extracellular.equipment = 'OpenEpys Neuropix-PXI';
        session.extracellular.leastSignificantBit = 0.195;
        session.extracellular.fileFormat = 'dat';
        session.extracellular.precision = 'int16';
        session.extracellular.fileName = '';
        
        % Electrode groups and channel mapping
        channelmapping = [];
        for i = 1:session.extracellular.nChannels
            if isstruct(openEphys_metadata.continuous.channels) 
                if isfield(openEphys_metadata.continuous.channels(i),'channel_metadata')
                    channelmapping(i) = openEphys_metadata.continuous(1).channels(i).channel_metadata.value+1;
                end
            elseif isfield(openEphys_metadata.continuous(1).channels{i},'channel_metadata')
                channelmapping(i) = openEphys_metadata.continuous(1).channels{i}.channel_metadata.value+1;
            end
        end
    
        chanCoords = generateChanCoords_Neuropixel2;
    
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
    
        % LFP data stream
        if length(openEphys_metadata.continuous)>1
            session.extracellular.srLfp = openEphys_metadata.continuous(2).sample_rate;
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
else
    warning(['Failed to load Open Ephys settings: ', file1])
end