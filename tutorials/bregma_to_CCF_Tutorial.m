% Tutorial on using common coordinate framework (CCF) from implant coordinates
basepath = '/Volumes/buzsakilab/peterp03/IntanData/MS22/Peter_MS22_180629_110319_concat';
basepath = 'Z:\peterp03\IntanData\MS22\Peter_MS22_180629_110319_concat';

chanmap = load(fullfile(basepath,'chanMap.mat'));
session = loadSession(basepath);

% Defining implant coordinates
implantCoordinate.ap = -3.5;
implantCoordinate.ml = -2.5;
implantCoordinate.depth = 2.2;
implantCoordinate.ap_angle = 0;
implantCoordinate.ml_angle = 0;
implantCoordinate.rotation = -45;

figure
% Left hippocampal probe
chanCoords.x = chanmap.xcoords(1:64) - mean(chanmap.xcoords(1:64));
chanCoords.y = chanmap.ycoords(1:64) - min(chanmap.ycoords(1:64));
chanCoords.z = zeros(size(chanCoords.y));
chanCoords.x = chanCoords.x(:);
chanCoords.y = chanCoords.y(:);
chanCoords.z = chanCoords.z(:);
ccf1 = bregma_to_CCF(chanCoords,implantCoordinate);

% Right probe
implantCoordinate.rotation = 45;
implantCoordinate.ml = 2.5;
chanCoords.x = chanmap.xcoords(65:128)-mean(chanmap.xcoords(65:128));
chanCoords.y = chanmap.ycoords(65:128) - min(chanmap.ycoords(65:128));
chanCoords.z = zeros(size(chanCoords.y));
chanCoords.x = chanCoords.x(:);
chanCoords.y = chanCoords.y(:);
chanCoords.z = chanCoords.z(:);
ccf2 = bregma_to_CCF(chanCoords,implantCoordinate);

% combining ccfs
clear ccf
ccf.x = [ccf1.x;ccf2.x];
ccf.y = [ccf1.y;ccf2.y];
ccf.x = [ccf1.z;ccf2.z];
ccf.implantVector{1} = ccf1.implantVector;
ccf.implantVector{2} = ccf2.implantVector;

% Saving chanCoords to basename.chanCoords.channelInfo.mat file
saveStruct(chanCoords,'channelInfo','session',session);

% Saving ccf to basename.ccf.channelInfo.mat file
saveStruct(ccf,'channelInfo','session',session);

%% 

% Load all aninals in database with related meta data
projectpath = '/Volumes/buzsakilab/peterp03/IntanData/';
projectpath = 'Z:\peterp03\IntanData';
animals = db_load_table('animals');
animal_subjects = {'MS10','MS12','MS13','MS18','MS21','MS22'};
figure
for i = 1:numel(animal_subjects)
    if isfield(animals.(['animal_' animal_subjects{i}]),'ProbeImplants')
        ProbeImplants = animals.(['animal_' animal_subjects{i}]).ProbeImplants;
        for j = 1:numel(ProbeImplants)
            implantCoordinate = {};
            if isempty(ProbeImplants{j}.APCoordinates)
                implantCoordinate.ap = 0;
            else
                implantCoordinate.ap = str2double(ProbeImplants{j}.APCoordinates);
            end
            % MLCoordinates
            if isempty(ProbeImplants{j}.MLCoordinates)
                implantCoordinate.ml = 0;
            else
                implantCoordinate.ml = str2double(ProbeImplants{j}.MLCoordinates);
            end
            % Depth
            if isempty(ProbeImplants{j}.Depth)
                implantCoordinate.depth = 0;
            else
                implantCoordinate.depth = abs(str2double(ProbeImplants{j}.Depth));
            end
            % APAngle
            if isempty(ProbeImplants{j}.APAngle)
                implantCoordinate.ap_angle = 0;
            else
                implantCoordinate.ap_angle = str2double(ProbeImplants{j}.APAngle);
            end
            % MLAngles
            if isempty(ProbeImplants{j}.MLAngles)
                implantCoordinate.ml_angle = 0;
            else
                implantCoordinate.ml_angle = str2double(ProbeImplants{j}.MLAngles);
            end
            % Rotation
            if isempty(ProbeImplants{j}.Rotation)
                implantCoordinate.rotation = 0;
            else
                implantCoordinate.rotation = str2double(ProbeImplants{j}.Rotation);
            end
            
            chanmap = load(fullfile(projectpath,animal_subjects{i},'chanMap.mat'));
            chanCoords = {};
            chanCoords.x = chanmap.xcoords([1:64]+(j-1)*64) - mean(chanmap.xcoords([1:64]+(j-1)*64));
            chanCoords.y = chanmap.ycoords([1:64]+(j-1)*64) - min(chanmap.ycoords([1:64]+(j-1)*64));
            chanCoords.z = zeros(size(chanCoords.y));
            chanCoords.x = chanCoords.x(:);
            chanCoords.y = chanCoords.y(:);
            chanCoords.z = chanCoords.z(:);
            ccf1 = bregma_to_CCF(chanCoords,implantCoordinate);
        end
    end
end

