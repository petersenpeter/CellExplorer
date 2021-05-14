function chanMap = generateChannelMap(session)
% Generates a channelmap compatible with KiloSort. 
% Original custom function by Brendon Watson and Sam McKenzie (from the KiloSortWrapper)

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 09-03-2021

% Parameters: 
% layout: channel layout, e.g. linear, poly2, poly3
% verticalSpacing: the vertical spacing between channels (on the same configuration line; in µm)
% shankSpacing (in µm)

electrodeLayouts = {'linear','poly2','poly3','poly4','poly5','twohundred','staggered','neurogrid'};

if isfield(session.animal,'probeImplants')
    source = 'probeImplants';
    layout = session.animal.probeImplants{1}.layout;
    if isfield(session.animal.probeImplants{1},'shankSpacing')
        shankSpacing = session.animal.probeImplants{1}.shankSpacing;
    else
        shankSpacing = 200;
    end
    verticalSpacing = session.animal.probeImplants{1}.verticalSpacing;
    if ~isnumeric(verticalSpacing)
        verticalSpacing = str2num(verticalSpacing);
    end
elseif isfield(session,'analysisTags') && isfield(session.analysisTags,'probesLayout') && any(strcmpi(session.analysisTags.probesLayout,electrodeLayouts))
    source = 'analysisTags';
    layout = session.analysisTags.probesLayout;
    shankSpacing = 200;
    if isfield(session,'analysisTags') && isfield(session.analysisTags,'probesVerticalSpacing')
        verticalSpacing = session.analysisTags.probesVerticalSpacing;
    else
        verticalSpacing = 20;
    end
else
    source = 'defaults';
    layout = 'poly2';
    shankSpacing = 200;
    verticalSpacing = 20;
end
disp(['Generating channel map from ' source ' information. layout: ', layout, ', shank spacing: ' num2str(shankSpacing) 'um, and vertical channel spacing: ' num2str(verticalSpacing),'um'])

%%
xcoords = [];%eventual output arrays
ycoords = [];

ngroups = session.extracellular.nElectrodeGroups;
groups = session.extracellular.electrodeGroups.channels;

switch(layout)
    case {'linear','edge'}
        for a= 1:ngroups
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = 0;
                y(i) = -(i-1);
            end
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:))*verticalSpacing;
        end
    case 'staggered'
        horz_offset = flip([0,8.5,17:4:520]);
        horz_offset(1:2:end) = -horz_offset(1:2:end);
        for a= 1:ngroups % being super lazy and making this map with loops
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = horz_offset(end-length(tchannels)+i);
                y(i) = -(i-1)*verticalSpacing;
            end
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
        
     case {'poly3', 'poly 3'}
        for a= 1:ngroups
            tchannels  = groups{a};
            x = nan(1,length(tchannels));
            y = nan(1,length(tchannels));
            extrachannels = mod(length(tchannels),3);
            polyline = mod([1:length(tchannels)-extrachannels],3);
            x(find(polyline==1)+extrachannels) = -18;
            x(find(polyline==2)+extrachannels) = 0;
            x(find(polyline==0)+extrachannels) = 18;
            x(1:extrachannels) = 0;
            y(find(x == 18))  = [0:length(find(x == 18))-1]*-verticalSpacing;
            y(find(x == 0))   = [0:length(find(x == 0))-1]*-verticalSpacing-verticalSpacing/2+extrachannels*verticalSpacing;
            y(find(x == -18)) = [0:length(find(x == -18))-1]*-verticalSpacing;
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
        
    case {'poly2', 'poly 2'}
        for a= 1:ngroups
            tchannels  = groups{a};
            x = nan(1,length(tchannels));
            y = nan(1,length(tchannels));
            extrachannels = mod(length(tchannels),2);
            polyline = mod([1:length(tchannels)-extrachannels],2);
            x(find(polyline==1)+extrachannels) = 0;
            x(find(polyline==0)+extrachannels) = 20;
            x(1:extrachannels) = 0;
            y(find(x == 0))  = [0:length(find(x == 0))-1]*-verticalSpacing;
            y(find(x == 20)) = [0:length(find(x == 20))-1]*-verticalSpacing-verticalSpacing/2;
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case {'poly5', 'poly 5'}
        for a= 1:ngroups
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
            
            y(find(x == 2*18))  = [0:length(find(x == 2*18))-1]*-verticalSpacing;
            y(find(x == 18))    = [0:length(find(x == 18))-1]*-verticalSpacing-verticalSpacing/2;
            y(find(x == 0))     = [0:length(find(x == 0))-1]*-verticalSpacing;
            y(find(x == -18))   = [0:length(find(x == -18))-1]*-verticalSpacing-verticalSpacing/2;
            y(find(x == 2*-18)) = [0:length(find(x == 2*-18))-1]*-verticalSpacing;
            
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    case 'neurogrid'
        for a= 1:ngroups
            x = [];
            y = [];
            tchannels  = groups{a};
            for i =1:length(tchannels)
                x(i) = length(tchannels)-i;
                y(i) = -(i-1)*verticalSpacing;
            end
            x = x+(a-1)*verticalSpacing;
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
                    y(i) = shankSpacing;%evens
                end
            end
            x = x+(a-1)*shankSpacing;
            xcoords = cat(1,xcoords,x(:));
            ycoords = cat(1,ycoords,y(:));
        end
    otherwise
        warning('layout not detected')
end
[~,I] =  sort(horzcat(groups{:}));
chanMap.xcoords = xcoords(I)';
chanMap.ycoords = ycoords(I)';
chanMap.source = source;
chanMap.layout = layout;
chanMap.shankSpacing = shankSpacing;

