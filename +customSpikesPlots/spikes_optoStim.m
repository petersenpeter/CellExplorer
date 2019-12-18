function spikePlot = spikes_template
    % This is a example template for creating your own custom spike raster plots
    %
    % OUTPUT
    % spikePlot       a struct containing all settings
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated 16-12-2019
    
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Spikes plot definitions 
% Can be loaded by pressing CTRL+A in the Cell Explorer
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

plotName = 'spikes_pos_vs_phase';
spikePlot.x = 'pos_linearized';
spikePlot.y = 'theta_phase';
spikePlot.x_label = 'Position (cm)';
spikePlot.y_label = 'Theta phase';
spikePlot.state = '';
spikePlot.filter = 'speed';
spikePlot.filterType = 'greater than';     % [none, equal to, less than, greater than]
spikePlot.filterValue = 20;
spikePlot.event = '';
spikePlot.eventType = 'event';             % [event,manipulation,state]
spikePlot.eventAlignment = 'peak';         % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 0; 
spikePlot.plotAverage = 0;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_pos_vs_trials';
spikePlot.x = 'pos_linearized';
spikePlot.y = 'trials';
spikePlot.x_label = 'Position (cm)';
spikePlot.y_label = 'Trials';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = '';
spikePlot.eventType = 'event';        % [event,manipulation,state]
spikePlot.eventAlignment = 'peak';         % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 0; 
spikePlot.plotAverage = 0;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_pos_vs_trials_cooling';
spikePlot.x = 'pos_linearized';
spikePlot.y = 'trials';
spikePlot.x_label = 'Position (cm)';
spikePlot.y_label = 'Trials';
spikePlot.state = 'state';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = '';
spikePlot.eventType = 'event';        % [event,manipulation,state]
spikePlot.eventAlignment = 'peak';         % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 0; 
spikePlot.plotAverage = 0;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_time_vs_amplitude';
spikePlot.x = 'times';
spikePlot.y = 'amplitudes';
spikePlot.x_label = 'Time (s)';
spikePlot.y_label = 'Amplitude';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = '';
spikePlot.eventType = 'event';        % [event,manipulation,state]
spikePlot.eventAlignment = 'peak';         % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 0; 
spikePlot.plotAverage = 0;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_ripples_raster';
spikePlot.x = 'times';
spikePlot.y = 'amplitudes';
spikePlot.x_label = 'Time';
spikePlot.y_label = 'Event';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';            % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = 'ripples';
spikePlot.eventType = 'event';        % [event,manipulation,state]
spikePlot.eventAlignment = 'peak';    % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude'; % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;       % in seconds
spikePlot.eventSecAfter = 0.2;        % in seconds
spikePlot.plotRaster = 1; 
spikePlot.plotAverage = 1;
spikePlot.plotAmplitude = 1;
spikePlot.plotDuration = 1;
spikePlot.plotCount = 0;

plotName = 'spikes_optoStim';
spikePlot.x = 'times';
spikePlot.y = 'times';
spikePlot.x_label = 'Time';
spikePlot.y_label = 'Event';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = 'optoStim';
spikePlot.eventType = 'manipulation';      % [event,manipulation,state]
spikePlot.eventAlignment = 'onset';        % [onset, offset, center, peak]
spikePlot.eventSorting = 'time';           % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.1;            % in seconds
spikePlot.eventSecAfter = 0.2;             % in seconds
spikePlot.plotRaster = 1;
spikePlot.plotAverage = 1;
spikePlot.plotAmplitude = 0;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_tesStimulation';
spikePlot.x = 'times';
spikePlot.y = 'times';
spikePlot.x_label = 'Time';
spikePlot.y_label = 'Event';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = 'stimulation';
spikePlot.eventType = 'manipulation';      % [event,manipulation,state]
spikePlot.eventAlignment = 'onset';        % [onset, offset, center, peak]
spikePlot.eventSorting = 'amplitude';      % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 2;              % in seconds
spikePlot.eventSecAfter = 2;               % in seconds
spikePlot.plotRaster = 1;
spikePlot.plotAverage = 1;
spikePlot.plotAmplitude = 1;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;

plotName = 'spikes_pulses';
spikePlot.x = 'times';
spikePlot.y = 'times';
spikePlot.x_label = 'Time';
spikePlot.y_label = 'Event';
spikePlot.state = '';
spikePlot.filter = '';
spikePlot.filterType = '';                 % [none, equal to, less than, greater than]
spikePlot.filterValue = 0;
spikePlot.event = 'pulses';
spikePlot.eventType = 'manipulation';      % [event,manipulation,state]
spikePlot.eventAlignment = 'onset';        % [onset, offset, center, peak]
spikePlot.eventSorting = 'none';           % [none, time, amplitude, duration]
spikePlot.eventSecBefore = 0.2;            % in seconds
spikePlot.eventSecAfter = 0.1;             % in seconds
spikePlot.plotRaster = 1;
spikePlot.plotAverage = 1;
spikePlot.plotAmplitude = 1;
spikePlot.plotDuration = 0;
spikePlot.plotCount = 0;
end