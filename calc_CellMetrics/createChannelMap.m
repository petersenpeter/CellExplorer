function chanMap = createChannelMap(basepath,basename,electrode_type)
% Creates a channemap 
% electrode_type: Two options at this point: 'staggered' or 'neurogrid'
% create a channel map file

% Original function by Brendon and Sam

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 08-02-2020


if ~exist('basepath','var')
    basepath = cd;
end
if ~exist('basename','var')
    [~,basename] = fileparts(basepath);
end

[par,rxml] = LoadXml(fullfile(basepath,[basename,'.xml']));
xml_electrode_type = rxml.child(1).child(4).value;
switch(xml_electrode_type)
    case 'staggered'
        electrode_type = 'staggered';
    case 'neurogrid'
        electrode_type = 'neurogrid';
    case 'grid'
        electrode_type = 'neurogrid';
    case 'poly3'
        electrode_type = 'poly3';
    case 'poly5'
        electrode_type = 'poly5';
    case 'poly2'
        electrode_type = 'poly2';
    case 'twohundred'
        electrode_type = 'twohundred';
    otherwise
        electrode_type = 'poly2'; %Default
end


%%
xcoords = [];%eventual output arrays
ycoords = [];

ngroups = length(par.AnatGrps);
for g = 1:ngroups
    groups{g} = par.AnatGrps(g).Channels;
end

switch(electrode_type)
    case 'staggered'
        horz_offset = flip(cumsum([0,-8.5,17,-21,+25,-29,33,-37,41,-45,49,-53,57,-61,65,-69]));
        for a= 1:ngroups %being super lazy and making this map with loops
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = horz_offset(end-length(tchannels)+i);
                y(i) = -i*20;
            end
            x = x+(a-1)*200;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'poly2'
        disp('poly2 probe layout')
        for a= 1:ngroups %being super lazy and making this map with loops
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
            x = x+(a-1)*200;
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
            
            x = x+(a-1)*200;
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
                    y(i) = 200;%evens
                end
            end
            x = x+(a-1)*200;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
end
[~,I] =  sort(horzcat(groups{:}));
chanMap.xcoords = xcoords(I)';
chanMap.ycoords = ycoords(I)';
