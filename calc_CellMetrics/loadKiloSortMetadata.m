function session = loadKiloSortMetadata(session,rezFile)
% Loads metadata from KiloSort's rez structure into session struct
%
% Check the website of CellExplorer for more details: https://cellexplorer.org/

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated 19-10-2020

if ~exist('rezFile','var')
    basepath = session.general.basePath;
    relativePath = session.spikeSorting{1}.relativePath;
    rezFile = dir(fullfile(basepath,relativePath,'rez*.mat'));
    rezFile = rezFile.name;
end

if exist(rezFile,'file')
    disp('Loading KiloSort metadata from rez structure')
    load(rezFile,'rez');
    session.extracellular.sr = rez.ops.fs;
    session.extracellular.nChannels = rez.ops.NchanTOT;
    kcoords_ids = unique(rez.ops.kcoords);
    session.extracellular.nElectrodeGroups = numel(kcoords_ids);
    for i = 1:numel(kcoords_ids)
        session.extracellular.electrodeGroups.channels{i} = rez.ops.chanMap(find(rez.ops.kcoords == kcoords_ids(i)));
        if size(session.extracellular.electrodeGroups.channels{i},1)>1
            session.extracellular.electrodeGroups.channels{i} = session.extracellular.electrodeGroups.channels{i}';
        end
    end
    session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups; % Number of spike groups
    session.extracellular.spikeGroups.channels = session.extracellular.electrodeGroups.channels; % Spike groups
    chanCoords.x = rez.xcoords;
    chanCoords.y = rez.ycoords;
    chanCoordsFile = fullfile(session.general.basePath,[session.general.name,'.chanCoords.channelInfo.mat']);
    if ~exist(chanCoordsFile,'file')
        disp(['Generating chanCoords file from KiloSort rez structure : ' chanCoordsFile])
        save(chanCoordsFile,'chanCoords');
    end
else
    disp('rez*.mat file does not exist')
end
