function session = loadPhyMetadata(session,clusteringpath_full)
    % Loads metadata from Phy's npy files into session struct
    % Check the website of CellExplorer for more details: https://cellexplorer.org/
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated 06-09-2021
    
    % Todo
    % params.py (sr, nChannels, precision)
    
    
    if exist(fullfile(clusteringpath_full, 'channel_map.npy'),'file')
        channel_map = readNPY(fullfile(clusteringpath_full, 'channel_map.npy'));
    end
    % Electrode groups
    if exist(fullfile(clusteringpath_full, 'channel_groups.npy'),'file') && exist(fullfile(clusteringpath_full, 'channel_map.npy'),'file')
        channel_groups = readNPY(fullfile(clusteringpath_full, 'channel_groups.npy'));
        
        session.extracellular.nChannels = numel(channel_groups);
        channelGroups = double(unique(channel_groups));
        session.extracellular.nElectrodeGroups = numel(channelGroups);
        for i = 1:numel(channelGroups)
            session.extracellular.electrodeGroups.channels{channelGroups(i)+1} = double(channel_map(channel_groups == channelGroups(i)))'+1;
        end
        session.extracellular.spikeGroups = session.extracellular.electrodeGroups;
        session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups;
    end
    
    % Channel coordinates
    if exist(fullfile(clusteringpath_full, 'channel_positions.npy'),'file')
        channel_positions = readNPY(fullfile(clusteringpath_full, 'channel_positions.npy'));
        session.extracellular.chanCoords.x = nan(1,session.extracellular.nChannels);
        session.extracellular.chanCoords.y = nan(1,session.extracellular.nChannels);
        session.extracellular.chanCoords.x(double(channel_map)+1) = channel_positions(:,1);
        session.extracellular.chanCoords.y(double(channel_map)+1) = channel_positions(:,2);
        session.extracellular.chanCoords.source = 'Phy';
        session.extracellular.chanCoords.layout = 'Unknown';
        session.extracellular.chanCoords.shankSpacing = 0;
    end
end