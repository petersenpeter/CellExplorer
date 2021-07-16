function firingRateMap = generate_FiringRateMap_1D(varargin)
% 
% 
% INPUTS
% behavior
% spikes
% states
% cells2process
%
% OUTPUTS
% firingRateMap
%
% By Peter Petersen
% petersen.peter@gmail.com

p = inputParser;

addParameter(p,'behavior',[],@isstruct);
addParameter(p,'spikes',[],@isstruct);
addParameter(p,'states',[],@isnumeric);
addParameter(p,'session',[],@isstruct);
addParameter(p,'stateNames',[],@iscellstr);
addParameter(p,'x_label','Position (cm)',@ischar);
addParameter(p,'bin_size',5,@isnumeric);
addParameter(p,'cells2process',[],@isnumeric);
addParameter(p,'dataName','ratemap',@ischar);
addParameter(p,'showPlots',false,@islogical);
addParameter(p,'saveMat',true,@islogical);
parse(p,varargin{:})

behavior = p.Results.behavior;
spikes = p.Results.spikes;
states = p.Results.states;
session = p.Results.session;
stateNames = p.Results.stateNames;
x_label = p.Results.x_label;
bin_size = p.Results.bin_size;
cells2process = p.Results.cells2process;
dataName = p.Results.dataName;
showPlots = p.Results.showPlots;
saveMat = p.Results.saveMat;

% All cells are processed if no input is given
if isempty(cells2process)
    cells2process = 1:spikes.numcells;
end

% Setting simple states vector if none is given
if isempty(states)
    states = ones(1,length(behavior.timestamps));
end

% Plotting
colors = [0.8500, 0.3250, 0.0980; 0, 0.4470, 0.7410; 0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560; 0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330; 0.6350, 0.0780, 0.1840; 0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330; 0.6350, 0.0780, 0.1840];

% Defining histogram bins
x_bins = [behavior.limits.linearized(1):bin_size:behavior.limits.linearized(2)];

firingRateMap = [];
firingRateMap.x_bins = x_bins;
if ~isempty(stateNames)
    firingRateMap.stateNames = stateNames;
end
if ~isempty(stateNames)
    firingRateMap.stateNames = stateNames;
end
if isfield(behavior,'limits') && isfield(behavior.limits,'linearized')
    firingRateMap.limits = behavior.limits.linearized;
end
if isfield(behavior,'boundaries') && isfield(behavior.boundaries,'linearized')
    firingRateMap.boundaries = behavior.boundaries.linearized;
end
if isfield(behavior,'boundaryNames') && isfield(behavior.boundaryNames,'linearized')
    firingRateMap.boundaryNames = behavior.boundaryNames.linearized;
end
firingRateMap.x_label = x_label;

nStates = numel(unique(states(~isnan(states))));

spikes.pos_linearized = cellfun(@(X) interp1(behavior.timestamps,behavior.position.linearized,X),spikes.times,'UniformOutput',false);
spikes.speed = cellfun(@(X) interp1(behavior.timestamps,behavior.speed,X),spikes.times,'UniformOutput',false);
spikes.states = cellfun(@(X) interp1(behavior.timestamps,states,X,'nearest'),spikes.times,'UniformOutput',false);

for k = 1:nStates
    indexes2 = (states == k & behavior.speed > behavior.speed_th);
    behavior_occupancy = histc(behavior.position.linearized(indexes2),x_bins);

    spikes_indices = cellfun(@(X1,X2,X3) (X1 == k & X2 > behavior.speed_th),spikes.states,spikes.speed,'UniformOutput',false);
    map = cellfun(@(X,Y) histc(X(Y),x_bins),spikes.pos_linearized,spikes_indices,'UniformOutput',false);
    for i = cells2process
        firingRateMap.map{i}(:,k) = map{i}(:)./behavior_occupancy(:) * behavior.sr;
    end
end

if saveMat
    saveStruct(firingRateMap,'firingRateMap','session',session,'dataName',dataName);
end

% if showPlots
%     for i = cells2process
%         subplot(5,nStates,1)
%         stairs(x_bins,hist_polar_count(:)./behavior_occupancy(:) * behavior.sr,'color',colors(k,:)), hold on
%         if isfield(behavior,'maze')
%             if isfield(behavior.maze,'reward_points')
%                 plot(behavior.maze.reward_points,0,'sm')
%             end
%         end
%         
%         if isfield(behavior,'maze')
%             if isfield(behavior.maze,'boundaries')
%                 gridxy(behavior.maze.boundaries)
%             end
%         end
%         axis tight, xlim([x_bins(1),x_bins(end)]),
%         if isempty(spikes.times{i})
%             title('No Spikes')
%         else
%             title([num2str(spikes.total(i)/((spikes.times{i}(end)-spikes.times{i}(1))),2) 'Hz']),
%         end
%         if k == 1
%             ylabel(['Unit ' num2str(i) ' (id ' num2str(spikes.cluID(i)) ')']);
%         end
%     end
% end
    
