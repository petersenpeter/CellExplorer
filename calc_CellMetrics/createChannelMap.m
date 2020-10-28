function chanMap = createChannelMap(session)
% Creates a channelmap compatible with KiloSort. 
% Original custom function by Brendon Watson and Sam McKenzie

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 27-05-2020

basepath = session.general.basePath;
basename = session.general.name;
electrode_type = session.analysisTags.probesLayout;
inter_shanks_distance = 200;

electrodeTypes = {'linear','poly2','poly3','poly4','poly5','twohundred','staggered','neurogrid'};
if ~any(strcmpi(electrode_type,electrodeTypes))
    disp('Applying default probe layout: poly2')
    electrode_type = 'poly2';
end


%%
xcoords = [];%eventual output arrays
ycoords = [];

ngroups = session.extracellular.nElectrodeGroups;
groups = session.extracellular.electrodeGroups.channels;

switch(electrode_type)
    case 'staggered'
        horz_offset = flip([0,8.5,17:4:520]);
        horz_offset(1:2:end) = -horz_offset(1:2:end);
        for a= 1:ngroups % being super lazy and making this map with loops
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = horz_offset(end-length(tchannels)+i);
                y(i) = -i*20;
            end
            x = x+(a-1)*inter_shanks_distance;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'poly2'
        disp('poly2 probe layout')
        for a= 1:ngroups % being super lazy and making this map with loops
            tchannels  = groups{a};
            x = nan(1,length(tchannels));
            y = nan(1,length(tchannels));
            extrachannels = mod(length(tchannels),3);
            polyline = mod([1:length(tchannels)-extrachannels],3);
            x(find(polyline==1)+extrachannels) = -18;
            x(find(polyline==2)+extrachannels) = 0;
            x(find(polyline==0)+extrachannels) = 18;
            x(1:extrachannels) = 0;
            y(find(x == 18)) = [1:length(find(x == 18))]*-20;
            y(find(x == 0)) = [1:length(find(x == 0))]*-20-10+extrachannels*20;
            y(find(x == -18)) = [1:length(find(x == -18))]*-20;
            x = x+(a-1)*inter_shanks_distance;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'poly5'
        disp('poly5 probe layout')
        for a= 1:ngroups %being super lazy and making this map with loops
            tchannels  = groups{a};
            x = nan(1,length(tchannels));
            y = nan(1,length(tchannels));
            extrachannels = mod(length(tchannels),5);
            polyline = mod([1:length(tchannels)-extrachannels],5);
            x(find(polyline==1)+extrachannels) = -2*18;
            x(find(polyline==2)+extrachannels) = -18;
            x(find(polyline==3)+extrachannels) = 0;
            x(find(polyline==4)+extrachannels) = 18;
            x(find(polyline==0)+extrachannels) = 2*18;
            x(1:extrachannels) = 18*(-1).^[1:extrachannels];
            
            y(find(x == 2*18)) =  [1:length(find(x == 2*18))]*-28;
            y(find(x == 18)) =    [1:length(find(x == 18))]*-28-14;
            y(find(x == 0)) =     [1:length(find(x == 0))]*-28;
            y(find(x == -18)) =   [1:length(find(x == -18))]*-28-14;
            y(find(x == 2*-18)) = [1:length(find(x == 2*-18))]*-28;
            
            x = x+(a-1)*inter_shanks_distance;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'neurogrid'
        for a= 1:ngroups %being super lazy and making this map with loops
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = length(tchannels)-i;
                y(i) = -i*50;
            end
            x = x+(a-1)*50;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'twohundred'
        for a= 1:ngroups 
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = 0;%length(tchannels)-i;
                if mod(i,2)
                    y(i) = 0;%odds
                else
                    y(i) = inter_shanks_distance;%evens
                end
            end
            x = x+(a-1)*inter_shanks_distance;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
end
[~,I] =  sort(horzcat(groups{:}));
chanMap.xcoords = xcoords(I)';
chanMap.ycoords = ycoords(I)';
