function openephysDig = loadOpenEphysDigitalNidaq(session, varargin)
% loadOpenEphysDigitalNidaq - Load and process digital TTL signals from OpenEphys NI-DAQ Board
%
% This function processes TTL signals recorded by the NI-DAQ board in OpenEphys, handling
% multiple recording epochs and aligning timestamps to the probe's timeline.
%
% INPUTS:
%   session        - Session struct containing recording metadata and paths
%
% Optional Name-Value Pairs:
%   'channelNum'   - Integer. Channel number on NI-DAQ board to process
%                    0: Clock signal (1 Hz)
%                    1: Camera trigger (120 Hz)
%                    Default: [] (processes all channels)
%   'probeLetter'  - Character. Specifies which probe's timeline to use for alignment
%                    'A': Use ProbeA timestamps (default)
%                    'B': Use ProbeB timestamps
%
% OUTPUTS:
%   openephysDig   - Structure containing processed TTL data with fields:
%     .timestamps  - [Nx1] Vector of all event timestamps (in seconds)
%     .states      - [Nx1] Vector of binary states (0/1) for each timestamp
%     .epochNum    - [Nx1] Vector indicating the epoch number for each timestamp
%     .on          - {1x1} Cell containing timestamps of rising edges (0→1)
%     .off         - {1x1} Cell containing timestamps of falling edges (1→0)
%     .diagnostics - Structure containing timing analysis and data quality info
%                   including timestamp duplicates and state conflicts
%
% NOTES:
%   - Rising and falling edges are paired based on channel-specific transitions
%   - Timestamps are aligned to probe recording start time
%   - Function warns if rising edges lack corresponding falling edges
%   - Empty epochs or missing files are handled gracefully with warnings
%   - Duplicate timestamps are analyzed with their states for conflicts
%
% EXAMPLE:
%   % Load camera trigger signals from channel 1
%   ttl = loadOpenEphysDigitalNidaq(session, 'channelNum', 1)
%
% See also: readNPY, saveStruct
%
% By Mingze Dou

p = inputParser;
addParameter(p,'channelNum', [], @isnumeric);
addParameter(p,'probeLetter', 'A', @ischar);
parse(p,varargin{:});
parameters = p.Results;

% Check for existing digitalseries file
existingFile = fullfile(session.general.basePath, [session.general.name '.openephysDig.digitalseries.mat']);
if exist(existingFile, 'file')
    load(existingFile, 'openephysDig');
    return
end

% Initialize
ttlPaths = {};
epochsStartTime = [];
ephysT0 = [];
validEpochs = [];
openephysDig.on = {[]};
openephysDig.off = {[]};
openephysDig.timestamps = [];
openephysDig.states = [];
openephysDig.epochNum = [];
openephysDig.diagnostics = struct();

% Find valid epochs
for i = 1:numel(session.epochs)
    ttlPath = fullfile(session.epochs{i}.name, 'events', 'NI-DAQmx-116.PXIe-6341', 'TTL');
    fullWordsPath = fullfile(session.general.basePath, ttlPath, 'full_words.npy');
    
    if exist(fullWordsPath, 'file') && (~isempty(parameters.channelNum) && ...
            any(bitand(readNPY(fullWordsPath), 2^parameters.channelNum)) || isempty(parameters.channelNum))
        validEpochs = [validEpochs i];
        ttlPaths{end+1} = ttlPath;
        
        % Get probe timestamps
        probeStr = parameters.probeLetter;
        if ~isempty(parameters.probeLetter), probeStr = parameters.probeLetter; end
        
        timestampPath = fullfile(session.general.basePath, session.epochs{i}.name, 'continuous', ...
            ['Neuropix-PXI-103.Probe' probeStr], 'timestamps.npy');
        
        if ~exist(timestampPath, 'file')
            error(['Timestamp file not found for Probe' probeStr ' in epoch ' num2str(i)]);
        end
        
        timestampData = readNPY(timestampPath);
        epochsStartTime(end+1) = session.epochs{i}.startTime;
        ephysT0(end+1) = double(timestampData(1));
    end
end

if isempty(validEpochs)
    error('No valid epochs found with the specified channel');
end

% Process epochs
for i = 1:length(validEpochs)
    currentEpoch = validEpochs(i);
    basePath = fullfile(session.general.basePath, ttlPaths{i});
    timestamps = readNPY(fullfile(basePath,'timestamps.npy'));
    fullWords = readNPY(fullfile(basePath,'full_words.npy'));
    if isempty(timestamps) || isempty(fullWords)
        warning('Empty data found in epoch %d', currentEpoch);
        continue;
    end

    % Align timestamps and get states
    alignedTimestamps = epochsStartTime(i) + double(timestamps) - ephysT0(i);
    channel_states = bitget(fullWords, parameters.channelNum + 1);

    % Find unique timestamps and duplicates
    [uniqueTimestamps, uniqueIdx] = unique(alignedTimestamps);
    uniqueStates = channel_states(uniqueIdx);

    % Analyze duplicates and their states
    [~, ~, dupGroups] = unique(alignedTimestamps);  % Get grouping for all timestamps
    duplicateInfo = struct('timestamps', [], 'states', [], 'hasConflict', []);
    
    % Find timestamps that appear more than once
    [dupCounts, dupValues] = hist(alignedTimestamps, unique(alignedTimestamps));
    duplicateTimestamps = dupValues(dupCounts > 1);
    
    if ~isempty(duplicateTimestamps)
        for j = 1:length(duplicateTimestamps)
            dupTime = duplicateTimestamps(j);
            dupIndices = find(alignedTimestamps == dupTime);
            dupStates = channel_states(dupIndices);
            
            % Store duplicate information
            duplicateInfo.timestamps(j) = dupTime;
            duplicateInfo.states{j} = dupStates;
            duplicateInfo.hasConflict(j) = length(unique(dupStates)) > 1;
        end
        
        % Store in diagnostics
        openephysDig.diagnostics.epoch(i).duplicates = duplicateInfo;
    end

    % Initialize arrays for this epoch
    rising_edges = [];
    falling_edges = [];

    % Process the state sequence
    state_idx = 1;
    while state_idx < length(uniqueStates)
        % Find next rising edge
        while state_idx < length(uniqueStates) && uniqueStates(state_idx) == 0
            state_idx = state_idx + 1;
        end

        if state_idx < length(uniqueStates)
            % Found a rising edge
            rising_edge_idx = state_idx;

            % Look for the next falling edge for this specific channel
            state_idx = state_idx + 1;
            while state_idx < length(uniqueStates) && uniqueStates(state_idx) == 1
                state_idx = state_idx + 1;
            end

            if state_idx < length(uniqueStates)
                % Found the corresponding falling edge
                falling_edge_idx = state_idx;

                % Store the edges
                rising_edges = [rising_edges; rising_edge_idx];
                falling_edges = [falling_edges; falling_edge_idx];
            else
                warning('Found rising edge without corresponding falling edge at timestamp %f in epoch %d', ...
                    uniqueTimestamps(rising_edge_idx), currentEpoch);
            end
        end
    end

    % Store results using the correct timestamps
    openephysDig.on{1} = [openephysDig.on{1}; uniqueTimestamps(rising_edges)];
    openephysDig.off{1} = [openephysDig.off{1}; uniqueTimestamps(falling_edges)];
    openephysDig.timestamps = [openephysDig.timestamps; uniqueTimestamps];
    openephysDig.states = [openephysDig.states; uniqueStates];
    openephysDig.epochNum = [openephysDig.epochNum; repmat(currentEpoch, length(uniqueTimestamps), 1)];
end

% Save
saveStruct(openephysDig,'digitalseries','session',session);
end