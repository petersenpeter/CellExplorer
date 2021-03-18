function optitrack = optitrack2buzcode(session,LengthUnit,arena, apply_head_displacement,apply_pca)
% Loads position tracking data from Optitrack to buzcode data container
%

plot_on = 1;
saveMat = 1;
basepath = session.general.basePath;
basename = session.general.name;
switch nargin
    case 4
        disp('')
        apply_pca = 0;
    case 3
        disp('')
        apply_pca = 0;
        apply_head_displacement = 0;
    case 2
        disp('')
        apply_pca = 0;
%         arena = 'LinearTrack';
        apply_head_displacement = 0;
    case 1
       apply_head_displacement = 0;
       apply_pca = 0;
%        arena = 'LinearTrack';
       LengthUnit = 1;
end
% filename = [datapath recording '/' recordings(id).tracking_file];
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';
header_length = 7;
filename = session.behavioralTracking{1}.filenames;
if iscell(filename)
    fileID = fopen(fullfile(basepath,filename{1}),'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', ',',  'ReturnOnError', false); 
    fclose(fileID);
    FramesPrFile = size(dataArray{1}(header_length:end),1);
    for i = 2:length(filename)
        fileID = fopen(fullfile(basepath,filename{i}),'r');
        dataArray_temp = textscan(fileID, formatSpec, 'Delimiter', ',',  'ReturnOnError', false); 
        fclose(fileID);
        for j = 1:length(dataArray)
            dataArray{j} = [dataArray{j};dataArray_temp{j}(header_length:end)];
        end
        FramesPrFile = [FramesPrFile, size(dataArray_temp{1}(header_length:end),1)];
    end
else
    fileID = fopen(fullfile(basepath,filename),'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', ',',  'ReturnOnError', false);
    fclose(fileID);
end

optitrack_temp = [];
optitrack_temp.Frame = str2double(dataArray{1}(header_length:end));
optitrack_temp.Time = str2double(dataArray{2}(header_length:end));
optitrack_temp.Xr = str2double(dataArray{3}(header_length:end));
optitrack_temp.Yr = str2double(dataArray{4}(header_length:end));
optitrack_temp.Zr = str2double(dataArray{5}(header_length:end));
optitrack_temp.Wr = str2double(dataArray{6}(header_length:end));
optitrack_temp.X = str2double(dataArray{7}(header_length:end));
optitrack_temp.Y = str2double(dataArray{8}(header_length:end));
optitrack_temp.Z = str2double(dataArray{9}(header_length:end));
optitrack_temp.TotalFrames = str2double(dataArray{12}(1));
optitrack_temp.TotalExportedFrames = str2double(dataArray{14}(1));
optitrack_temp.RotationType = dataArray{16}(1);
optitrack_temp.LenghtUnit = dataArray{18}(1);
optitrack_temp.CoorinateSpace = dataArray{20}(1);
optitrack_temp.FrameRate = str2double(dataArray{6}{1});
if exist('FramesPrFile')
    optitrack_temp.FramesPrFile = FramesPrFile;
end
clear dataArray
clearvars filename formatSpec fileID dataArray header_length;

position = 100*[-optitrack_temp.X,optitrack_temp.Z,optitrack_temp.Y]/LengthUnit; % get position out in cm

if apply_head_displacement == 1
    disp('Applying head displacement')
    angles = SpinCalc('QtoEA321',[optitrack_temp.Xr,optitrack_temp.Yr,optitrack_temp.Zr,optitrack_temp.Wr],1e-5,1);
    v = [0;0;-8]; % Displacement vector (xyz, z is the vertical direction)
    y = rot_Peter(angles,v);
    position = position+y;
end

% Rotating the dimensions using PCA
if apply_pca == 1
    disp('Applying PCA')
    [coeff,position3D,latent] = pca(position);
    position1 = position3D(:,1);
    position = nanmedian(position1,10);
else
    position3D = position;
end

% Estimating the speed of the rat
% animal_speed = 100*Optitrack.FrameRate*(diff(Optitrack.X).^2+diff(Optitrack.Y).^2+diff(Optitrack.Z).^2).^0.5;
animal_speed3 = [optitrack_temp.FrameRate*sqrt(sum(diff(position)'.^2)),0];
% animal_speed3(animal_speed3>150) = 0;

animal_speed1 = [];
animal_speed = nanconv(animal_speed3,ones(1,10)/10,'edge');
animal_acceleration = [0,diff(animal_speed)];

animal_speed2 = optitrack_temp.FrameRate*sqrt(sum((diff(position3D).^2),2))';
animal_speed2(animal_speed2>150) = 0;
animal_speed3D = [];
for i = 1:length(animal_speed2)-10
    animal_speed3D(i) = median(animal_speed2(i:i+10));
end
animal_speed3D =[zeros(1,5),animal_speed3D, zeros(1,6)];

% Adding  output struct
optitrack_temp.position1D = position(:,1)';
optitrack_temp.position3D = position3D';
optitrack_temp.animal_speed = animal_speed;
optitrack_temp.animal_acceleration = animal_acceleration;

% Generating buzcode fields and output struct
optitrack.timestamps = optitrack_temp.Time;
optitrack.timestamps_reference = 'optitrack';
optitrack.sr = optitrack_temp.FrameRate;
optitrack.position.x = optitrack_temp.position3D(1,:);
optitrack.position.y = optitrack_temp.position3D(2,:);
optitrack.position.z = optitrack_temp.position3D(3,:);
optitrack.position.speed = animal_speed;
optitrack.position.acceleration = animal_acceleration;
optitrack.position.units = 'centimeters';
optitrack.position.referenceFrame = 'global';
optitrack.position.coordinateSystem = 'cartesian';
optitrack.orientation.x = optitrack_temp.Xr;
optitrack.orientation.y = optitrack_temp.Yr;
optitrack.orientation.z = optitrack_temp.Zr;
optitrack.orientation.rotationType = optitrack_temp.RotationType;
% optitrack.position.resolution
% optitrack.linearized.position
% optitrack.linearized.speed
% optitrack.linearized.acceleration

% Attaching info about how the data was processed
optitrack.processinginfo.function = 'optitrack2buzcode';
optitrack.processinginfo.version = 1;
optitrack.processinginfo.date = now;
optitrack.processinginfo.params.basepath = basepath;
optitrack.processinginfo.params.basename = basename;
try
    optitrack.processinginfo.username = char(java.lang.System.getProperty('user.name'));
    optitrack.processinginfo.hostname = char(java.net.InetAddress.getLocalHost.getHostName);
catch
    disp('Failed to retrieve system info.')
end
% Saving data
if saveMat
    saveStruct(optitrack,'behavior','session',session);
end

% Plotting
if plot_on
    figure
    subplot(1,2,1)
    plot3(position3D(:,1),position3D(:,2),position3D(:,3)), title('3D position'), xlabel('X'), ylabel('Y'), zlabel('Z'),axis tight,view(2), hold on,
    % switch arena{1}
    %     case {'CircularTrack', 'Circular track'}
    %         position = position + [5,-5,0]; % get position out in cm
    %         position3D = position3D + [5,-5,0];
    %         maze_dia_out = 116.5;
    %         maze_dia_in = 96.5;
    %         pos1 = [-maze_dia_out/2, -maze_dia_out/2, maze_dia_out, maze_dia_out];
    %         pos2 = [-maze_dia_in/2, -maze_dia_in/2, maze_dia_in, maze_dia_in];
    %         rectangle('Position',pos1,'Curvature',[1 1]), hold on
    %         rectangle('Position',pos2,'Curvature',[1 1])
    %         cross_radii = 47.9;
    %         plot([-cross_radii -5 -5],[-5 -5 -cross_radii],'k'), hold on
    %         plot([cross_radii 5 5],[5 5 cross_radii],'k')
    %         plot([cross_radii 5 5],[-5 -5 -cross_radii],'k')
    %         plot([-cross_radii -5 -5],[5 5 cross_radii],'k')
    %         axis equal
    %         xlim([-65,65]),ylim([-65,65]),
    % 	case {'LinearTrack', 'Linear track'}
    %         disp('Linear Track detected')
    % end
    
    subplot(1,2,2)
    plot3(position3D(:,1),position3D(:,2),animal_speed), hold on
    xlabel('X'), ylabel('Y'),zlabel('Speed'), axis tight
end
