function spikePlot = spikes_pos_vs_trials_cooling

spikePlot.x = 'pos_linearized';
spikePlot.y = 'trials';
spikePlot.x_label = 'Position (cm)';
spikePlot.y_label = 'Trials';
spikePlot.state = 'state';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = '';
spikePlot.eventType = '';                  % [events,manipulation,states]
spikePlot.eventAlignment = 'peak';         % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 0; 
spikePlot.plotAverage = 0;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

end