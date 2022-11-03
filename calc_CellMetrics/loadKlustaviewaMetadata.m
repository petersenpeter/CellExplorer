function session = loadKlustaviewaMetadata(session,kwik_file)
% Loads metadata from Klustaviewa's kwik file into the session struct
% Check the website of CellExplorer for more details: https://cellexplorer.org/

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated 20-03-2022
    
kwik_hdf5info = hdf5info(kwik_file);
channel_groups = length(kwik_hdf5info.GroupHierarchy.Groups(2).Groups);
session.extracellular.sr = double(hdf5read(kwik_file, ['/application_data/spikedetekt/sample_rate']));
session.extracellular.nChannels = double(hdf5read(kwik_file, ['/application_data/spikedetekt/nchannels']));

for i = 1:channel_groups
    temp = {kwik_hdf5info.GroupHierarchy.Groups(2).Groups(i).Groups(2).Groups.Name};
    channels = [];
    for j = 1:length(temp)
        newStr = split(temp{j},'/');
        electrodeGroup = str2double(newStr{3})+1;
        channels(j) = str2double(newStr{5})+1;
        
    end
    disp([num2str(i),': group ' num2str(electrodeGroup),' channels: ' num2str(channels)])
    session.extracellular.electrodeGroups.channels{electrodeGroup} = channels;
end
session.extracellular.nElectrodeGroups = channel_groups;
session.extracellular.spikeGroups = session.extracellular.electrodeGroups;
session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups;
