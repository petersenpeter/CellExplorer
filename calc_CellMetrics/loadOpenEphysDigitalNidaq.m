function openephysDig = loadOpenEphysDigitalNidaq(session, varargin)
% function to load digital inputs from OpenEphys NI-DAQ Board using bitwise operations
%
% INPUT
% session: session struct
% Optional inputs:
%   channelNum: Channel number for NI-DAQ board (0 for clock, 1 for camera)
%   probeLetter: 'A' or 'B' for specific probe timestamps. If empty, uses ProbeA
%
% OUTPUTS
% openephysDig.timestamps: timestamps for all events [in seconds]
% openephysDig.states: corresponding states for each timestamp
% openephysDig.epochNum: corresponding epoch number for each timestamp
% openephysDig.on: cell array containing on-state timestamps for the channel
% openephysDig.off: cell array containing off-state timestamps for the channel
%
% By Mingze Dou (modified version)

p = inputParser;
addParameter(p,'channelNum', [], @isnumeric);
addParameter(p,'probeLetter', '', @ischar);
parse(p,varargin{:});
parameters = p.Results;

% Initialize paths and timestamp arrays
ttlPaths = {};
epochsStartTime = [];
ephysT0 = [];
validEpochs = [];

% Initialize output structure
openephysDig.on = {[]};  % Initialize for single channel
openephysDig.off = {[]};
openephysDig.timestamps = [];
openephysDig.states = [];
openephysDig.epochNum = [];

% First pass: identify valid epochs and collect paths
for i = 1:numel(session.epochs)
    ttlPath = fullfile(session.epochs{i}.name, 'events', 'NI-DAQmx-116.PXIe-6341', 'TTL');
    fullWordsPath = fullfile(session.general.basePath, ttlPath, 'full_words.npy');
    
    if exist(fullWordsPath, 'file')
        fullWordsTemp = readNPY(fullWordsPath);
        
        if ~isempty(parameters.channelNum)
            targetChannel = 2^parameters.channelNum;
            if any(bitand(fullWordsTemp, targetChannel))
                validEpochs = [validEpochs i];
                ttlPaths{end+1} = ttlPath;
                fprintf('Epoch %d has signal from channel %d\n', i, parameters.channelNum);
            else
                fprintf('Epoch %d has no signal from channel %d - skipping\n', i, parameters.channelNum);
                continue;
            end
        else
            validEpochs = [validEpochs i];
            ttlPaths{end+1} = ttlPath;
        end
    else
        fprintf('No TTL data found for epoch %d - skipping\n', i);
        continue;
    end
    
    % Get probe timestamps
    if isempty(parameters.probeLetter)
        probeStr = 'A';
    else
        probeStr = parameters.probeLetter;
    end
    
    timestampPath = fullfile(session.general.basePath, session.epochs{i}.name, 'continuous', ...
        ['Neuropix-PXI-103.Probe' probeStr], 'timestamps.npy');
    
    if ~exist(timestampPath, 'file')
        error(['Timestamp file not found for Probe' probeStr ' in epoch ' num2str(i)]);
    end
    
    timestampData = readNPY(timestampPath);
    epochsStartTime(end+1) = session.epochs{i}.startTime;
    ephysT0(end+1) = double(timestampData(1));
end

openephysDig.validEpochs = validEpochs;

if isempty(validEpochs)
    error('No valid epochs found with the specified channel');
end

% Process valid epochs
for i = 1:length(validEpochs)
    currentEpoch = validEpochs(i);
    basePath = fullfile(session.general.basePath, ttlPaths{i});
    timestamps = readNPY(fullfile(basePath,'timestamps.npy'));
    fullWords = readNPY(fullfile(basePath,'full_words.npy'));
    
    % Align timestamps
    alignedTimestamps = epochsStartTime(i) + double(timestamps) - ephysT0(i);
    
    % Get channel states using bitget
    channelStates = bitget(fullWords, parameters.channelNum + 1);
    
    % Find state transitions
    stateChanges = diff([0; channelStates]);
    risingEdges = find(stateChanges == 1);
    fallingEdges = find(stateChanges == 0);
    
    % Remove duplicate timestamps from rising edges
    [uniqueRisingTimestamps, uniqueRisingIdx] = unique(alignedTimestamps(risingEdges));
    risingEdges = risingEdges(uniqueRisingIdx);
    
    % Remove duplicate timestamps from falling edges
    [uniqueFallingTimestamps, uniqueFallingIdx] = unique(alignedTimestamps(fallingEdges));
    fallingEdges = fallingEdges(uniqueFallingIdx);
    
    % Store timestamps for the specific channel
    openephysDig.on{1} = [openephysDig.on{1}; uniqueRisingTimestamps];
    openephysDig.off{1} = [openephysDig.off{1}; uniqueFallingTimestamps];
    
    % Store only unique state changes
    changeIndices = sort([risingEdges; fallingEdges]);
    [uniqueChangeTimestamps, uniqueIdx] = unique(alignedTimestamps(changeIndices));
    
    openephysDig.timestamps = [openephysDig.timestamps; uniqueChangeTimestamps];
    openephysDig.states = [openephysDig.states; channelStates(changeIndices(uniqueIdx))];
    openephysDig.epochNum = [openephysDig.epochNum; repmat(currentEpoch, length(uniqueChangeTimestamps), 1)];
end

% Store processing information
openephysDig.processinginfo.function = 'loadOpenEphysDigitalNidaq';
openephysDig.processinginfo.version = 9;
openephysDig.processinginfo.date = datetime('now');
openephysDig.processinginfo.params = struct('basePath', session.general.basePath, ...
    'basename', session.general.name, ...
    'ttlPaths', {ttlPaths}, ...
    'channelNum', parameters.channelNum);

% Save the processed data
saveStruct(openephysDig,'digitalseries','session',session);
end