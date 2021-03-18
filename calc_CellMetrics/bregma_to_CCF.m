function ccf = bregma_to_CCF(chanCoords,implantCoordinate,varargin)
% Translates chanCoords to CCF using implant translation
%
% INPUTS:
% chanCoords
% .x : vector with x-coordinates of each electrode (locations to translate)
% .y : vector with y-coordinates of each electrode (locations to translate)
% .z : vector with z-coordinates of each electrode (locations to translate)
%
% implantCoordinate (origin: bregma)
% .ap : Anteripr-Posterior coordinates (mm)
% .ml  : Medial-lateral coordinates (mm)
% .depth : implantation depth (mm)
% .ap_ration : AP angle (degrees)
% .ml_roation : ML angles (degrees)
% .rotation : Rotation of the probe. 0 degrees when electrode surface is facing AP
%
% OUTPUT:
% ccf
% .x : Anterior->Posterior 
% .y : Superior->Inferior
% .z : Left->Right
% implantVector : implant vector from brain surface to implanted position

% By Peter Petersen
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'plots',true,@islogical)
parse(p,varargin{:})
plots = p.Results.plots;

% Rotating channel coordinates

v_rot1 = rodrigues_rot([chanCoords.x,chanCoords.y,chanCoords.z]',[0;-1;0],implantCoordinate.rotation/360*2*pi);
chanCoords.x = v_rot1(1,:);
chanCoords.y = v_rot1(2,:);
chanCoords.z = v_rot1(3,:);
depth = implantCoordinate.depth*1000;

bregma_in_ccf = [-5000,-5700,0];

mf = which('plotAllenBrainGrid.m');
brainGridData = readNPY(fullfile(fileparts(mf), 'brainGridData.npy'));
brainGridData = 10.*double(brainGridData); 
brainGridData(sum(brainGridData,2)==0,:) = NaN;
brainGridData = brainGridData(:,[1,3,2]);

% Determining surface coordinates
ccf1.x = (-implantCoordinate.ap*1000 - bregma_in_ccf(1));
ccf1.z = (-implantCoordinate.ml*1000 - bregma_in_ccf(2));
[~,In] = min(sqrt(abs(brainGridData(:,1)-ccf1.x).^2 + abs(brainGridData(:,3)-ccf1.z).^2 + abs(brainGridData(:,2)).^2));
surface_coordinates = [ccf1.x,brainGridData(In,2),ccf1.z];
ccf1.y = surface_coordinates(2);

% Translating angles for electrodes
ccf.x = chanCoords.z;
ccf.y = -chanCoords.y + depth;
ccf.z = -chanCoords.x;

v_rot2 = rodrigues_rot([ccf.x;ccf.y;ccf.z],[1,0,0]',implantCoordinate.ml_angle/360*2*pi);
ccf.x = v_rot2(1,:);
ccf.y = v_rot2(2,:);
ccf.z = v_rot2(3,:);
v_rot3 = rodrigues_rot([ccf.x;ccf.y;ccf.z],[0,0,-1]',implantCoordinate.ap_angle/360*2*pi)+surface_coordinates';
ccf.x = v_rot3(1,:)';
ccf.y = v_rot3(2,:)';
ccf.z = v_rot3(3,:)';

% Translating angles for implant vector
ccf1.x = 0;
ccf1.y = depth;
ccf1.z = 0;

v_rot2 = rodrigues_rot([ccf1.x;ccf1.y;ccf1.z],[1,0,0]',implantCoordinate.ml_angle/360*2*pi);
ccf1.x = v_rot2(1,:);
ccf1.y = v_rot2(2,:);
ccf1.z = v_rot2(3,:);
v_rot3 = rodrigues_rot([ccf1.x;ccf1.y;ccf1.z],[0,0,-1]',implantCoordinate.ap_angle/360*2*pi)+surface_coordinates';
ccf1.x = v_rot3(1,:);
ccf1.y = v_rot3(2,:);
ccf1.z = v_rot3(3,:);

implantVector = [surface_coordinates;ccf1.x,ccf1.y,ccf1.z];

ccf.implantVector = implantVector;

if plots
    % Plot
%     figure
    plot3(ccf.x,ccf.z,ccf.y,'.b'), hold on
    plot3(ccf1.x,ccf1.z,ccf1.y,'or')
    plot3(surface_coordinates(1),surface_coordinates(3),surface_coordinates(2),'xr')
    plot3(implantVector(:,1),implantVector(:,3),implantVector(:,2),'k')
    xlabel('x ( Anterior-Posterior; µm)'), zlabel('y (Superior-Inferior; µm)'), ylabel('z (Left-Right; µm)'), axis equal, set(gca, 'ZDir','reverse')
    line(gca, brainGridData(:,1), brainGridData(:,3), brainGridData(:,2), 'Color', [0 0 0 0.3], 'HitTest','off'); title('Mouse brain')
end
