function placecell = place_cell_condition(firing_rate_map,varargin)
% INPUTS
% firing_rate_map 
%
% OUTPUTS
% placecell structure
%
% By Peter Petersen
% petersen.peter@gmail.com

p = inputParser;
addParameter(p,'firing_rate_threshold',0.1,@isnumeric); % percentage of peak firing rate to define boundaries of the fields
addParameter(p,'place_field_min_size',4,@isnumeric); % min number of bins for a region to be considered a placefield
addParameter(p,'firing_rate_peak_min',8,@isnumeric); % min peak firing rate in Hz in the place field
addParameter(p,'spatial_coherence_min',0.6,@isnumeric); % Initial requirement to be considered for further analysis

parse(p,varargin{:})

firing_rate_threshold = p.Results.firing_rate_threshold;
place_field_min_size = p.Results.place_field_min_size;
firing_rate_peak_min = p.Results.firing_rate_peak_min;
spatial_coherence_min = p.Results.spatial_coherence_min;

firing_rate_map = firing_rate_map(:)';
test1 = firing_rate_map > firing_rate_threshold.*max(firing_rate_map); % Finding bins with firing rate greater than min requirement (firing_rate_threshold)
test2 = conv(test1,ones(1,place_field_min_size),'same'); % Finding connected intervals where the above requirement is fulfilled
test3 = conv(firing_rate_map > firing_rate_peak_min,ones(1,place_field_min_size+2),'same'); % Defines fields with firing_rate_peak_min

placecell = [];
placecell.SpatialCoherence = [];
placecell.condition = [];
placecell.placefield_count = 0;
placecell.placefield_interval = [];
placecell.placefield_state = [];

placecell.SpatialCoherence = SpatialCoherence(firing_rate_map);
if any(test2 == place_field_min_size & firing_rate_map > firing_rate_peak_min & placecell.SpatialCoherence > spatial_coherence_min)
    placecell.condition = 1;
    placefield_start = find(diff(test2 == place_field_min_size & test3>0)==1)-1; 
    placefield_end = find(diff(test2 == place_field_min_size & test3>0)==-1)+2;
    placefield_start(placefield_start==0) = 1; 
    placefield_end(placefield_end==length(test2)) = length(test2); 
    
    placecell.placefield_count = min(length(placefield_start),length(placefield_end));
    placecell.placefield_interval = [placefield_start;placefield_end+1]';
    placecell.placefield_state = zeros(size(firing_rate_map));
    X = cumsum(accumarray(cumsum([1;placefield_end(:)-placefield_start(:)+1]),[placefield_start(:);0]-[0;placefield_end(:)]-1)+1);
    X = X(1:end-1);
    placecell.placefield_state(X) = 1;
else
     placecell.condition = 0;
     placecell.placefield_state = zeros(size(firing_rate_map));
end
