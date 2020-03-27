function spikePlot = spikes_ripples_raster

spikePlot.x = 'times';
spikePlot.y = 'amplitudes';
spikePlot.x_label = 'Time';
spikePlot.y_label = 'Event';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';            % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = 'ripples';
spikePlot.eventType = 'events';        % [events,manipulation,states]
spikePlot.eventAlignment = 'peak';    % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude'; % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;       % in seconds
spikePlot.eventSecAfter = 0.2;        % in seconds
spikePlot.plotRaster = 1; 
spikePlot.plotAverage = 1;
spikePlot.plotAmplitude = 1;
spikePlot.plotDuration = 1;
spikePlot.plotCount = 0;

end