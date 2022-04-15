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
    if numel([session.extracellular.electrodeGroups.channels{:}]) < session.extracellular.nChannels
        session.extracellular.electrodeGroups.channels{session.extracellular.nElectrodeGroups+1} = setdiff(1:session.extracellular.nChannels,[session.extracellular.electrodeGroups.channels{:}]);
        session.extracellular.nElectrodeGroups = numel(session.extracellular.electrodeGroups.channels);
        session.channelTags.KiloSort_setdiff.channels = session.extracellular.electrodeGroups.channels{end};
        if isfield(session.channelTags,'Bad') && isfield(session.channelTags.Bad,'channels')
            try
                session.channelTags.Bad.channels = [session.channelTags.Bad.channels,session.extracellular.electrodeGroups.channels{end}];
            end
        else
            session.channelTags.Bad.channels = session.extracellular.electrodeGroups.channels{end};
        end
    end
    session.extracellular.nSpikeGroups = session.extracellular.nElectrodeGroups; % Number of spike groups
    session.extracellular.spikeGroups.channels = session.extracellular.electrodeGroups.channels; % Spike groups
    chanCoords.x = zeros(session.extracellular.nChannels,1);
    chanCoords.y = zeros(session.extracellular.nChannels,1);
    chanCoords.x(rez.ops.chanMap) = rez.xcoords;
    chanCoords.y(rez.ops.chanMap) = rez.ycoords;
    chanCoords.source = 'KiloSort';
    session.extracellular.chanCoords = chanCoords;
else
    disp('rez*.mat file does not exist')
end
