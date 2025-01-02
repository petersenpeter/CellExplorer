function session = preprocessOpenEphysData(varargin)
    % https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html
    
    % Processing steps:
    % 1. Detects epochs (name and duration from experiments and recording folders)
    % 2. Imports extracellular metadata and Channel coordinates from the first structure.oebin file
    % 3. Epoch durations
    % 4. Saving session struct
    % 5. Merge dat/bin files to single binary .dat file in basepath
    % 6. Merge lfp files
    % 7. Merge digital timeseries
    
    p = inputParser;
    addParameter(p,'session', [], @isstruct); % A session struct
    addParameter(p,'basepath',pwd,@isstr);
    addParameter(p,'format',pwd,@isstr); % binary, nwb, or openEphys
    addParameter(p,'saveMat', true, @islogical); % Saves basename.session.mat file
    addParameter(p,'showGUI',false,@islogical);
    addParameter(p,'processData',true,@islogical);
    addParameter(p,'probeLetter','A',@(x) ismember(x,{'A','B','C'}));
    parse(p,varargin{:})

    parameters = p.Results;
    session = parameters.session;
    
    if isfield(session,'general') && isfield(session.general,'basePath')
        basepath = session.general.basePath;
    else
        basepath = parameters.basepath;
    end
    
    % 1. Detects epochs (name and duration from experiments and recording folders)
    k = 1;
    subFolder_RecordNodes = checkfolder(basepath, 'Record Node');
    for m = 1:numel(subFolder_RecordNodes)
        subFolder_Experiments = checkfolder(fullfile(basepath,subFolder_RecordNodes{m}), 'experiment');
        for i = 1:numel(subFolder_Experiments)
            subFolder_Recordings = checkfolder(fullfile(basepath,subFolder_RecordNodes{m},subFolder_Experiments{i}), 'recording');
            for j = 1:numel(subFolder_Recordings)
                session.epochs{k}.name = fullfile(subFolder_RecordNodes{m},subFolder_Experiments{i},subFolder_Recordings{j});
                session.epochs{k}.startTime = 0;
                session.epochs{k}.stopTime = 0;
                session.epochs{k}.notes = fullfile(subFolder_RecordNodes{m},subFolder_Experiments{i},subFolder_Recordings{j});
                k = k + 1;
            end
        end
    end
    saveStruct(session);
    
    % 2. Imports extracellular metadata and Channel coordinates from the first structure.oebin file 
    file1 = fullfile(session.general.basePath,session.epochs{1}.name,'structure.oebin');
    session = loadOpenEphysSettingsFile(file1, session, 'probeLetter', parameters.probeLetter);

    % 3. Epoch durations
    [session,inputFiles] = calculateEpochDurations(session, basepath, parameters.probeLetter);

    % Shows session GUI if requested
    if parameters.showGUI
        session = gui_session(session);
        [session,inputFiles] = calculateEpochDurations(session, basepath, parameters.probeLetter);
    end

    % 4. Saving session struct
    if parameters.saveMat
        saveStruct(session);
    end

    % 5. Merge dat files to single binary .dat file in basepath
    if parameters.processData
        disp('Attempting to concatenate binary files with spiking data.')
        outputFile = fullfile(basepath,[session.general.name, '.dat']);
        binaryMergeWrapper(inputFiles, outputFile)
    end

    % 6. Merge lfp files
    inputFiles_lfp = {};
    for i = 1:numel(session.epochs)
        if exist(fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.bin'),'file')
            inputFiles_lfp{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.bin');
        elseif exist(fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.dat'),'file')
            inputFiles_lfp{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.dat');
        else
            inputFiles_lfp{i} = fullfile(basepath,session.epochs{i}.name,'continuous',['Neuropix-PXI-100.Probe', parameters.probeLetter, '-LFP'],'continuous.dat');
        end
    end
    outputFile_lfp = fullfile(basepath,[session.general.name, '_Probe', parameters.probeLetter, '.lfp']);


    disp('Attempting to concatenate binary LFP files.')
    binaryMergeWrapper(inputFiles_lfp, outputFile_lfp)


    % 7. Merge digital timeseries
    % openephysDig = loadOpenEphysDigital(session);

end

function subFolderNames = checkfolder(dir1, folderstring)
files = dir(dir1);
dirFlags = [files.isdir]; % Get a logical vector that tells which is a directory.
subFolders = files(dirFlags); % Extract only those that are directories.
subFolderNames = {subFolders(3:end).name}; % Get only the folder names into a cell array.  Start at 3 to skip . and ..
subFolderNames = subFolderNames(contains(subFolderNames,folderstring));
end


%% Local functions
function binaryMergeWrapper(inputFiles, outputFile)
% binaryMergeWrapper(inputFiles, outputFile)
%
% Function merges multiple binary files into a single binary file.
%
% Args:
%   inputFiles (cell): a shape-(M, 1) or -(1, M) array of filename strings
%     for concatenation (required).
%   outputFile (char): a shape-(1, N) full path output filename string
%     (required).
% Returns:
%   None.

arguments
  inputFiles cell
  outputFile (1,:) char
end

concatenatedFiles = false;
if ~exist(outputFile,'file')
  % Concatenate files
  disp('Concatenating binary raw files')
  concatenate_binary_files(inputFiles, outputFile)
  concatenatedFiles = true;
else
  % Check if the input files are of the same size as the file that already exists
  inputFileSize = getFileSize(inputFiles);
  outputFileSize = getFileSize(outputFile);
  if inputFileSize == outputFileSize
    disp(['Concatenated binary file already exists: ', outputFile])
    disp('Skipping concatenation.')
  else
    % Concatenate files if an existing concatenated file is of different size than expected.
    if inputFileSize < outputFileSize
      warning(['Concatenated binary file already exists but is larger than all input files taken together. Overwriting file ', outputFile]);
    elseif inputFileSize > outputFileSize
      warning(['Concatenated binary file already exists but is smaller than all input files taken together. Overwriting file ', outputFile]);
    end
    concatenate_binary_files(inputFiles, outputFile)
    concatenatedFiles = true;
  end
end

% Check if the new file has the expected size
inputFileSize = getFileSize(inputFiles);
outputFileSize = getFileSize(outputFile);
if inputFileSize < outputFileSize
  error('Concatenated binary file is larger than all input files taken together.');
elseif inputFileSize > outputFileSize
  error('Concatenated binary file is smaller than all input files taken together.');
elseif concatenatedFiles
  fprintf('\nConcatenated files successfully!\n');
end
end


function [totalSize, individualSizes] = getFileSize(inputFiles)
% [totalSize, individualSizes] = getFileSize(inputFiles)
%
% Function calculates the total size and individual sizes of input files.
%
% Args:
%   inputFiles (cell): a shape-(M, 1) or -(1, M) array of filename strings
%     for file size inference (required).
%
% Returns:
%   totalSize (numeric): a shape-(1,1) scalar showing the total size of all
%     input files in bytes.
%   individualSizes (numeric): a shape-(M, 1) numeric array with individual
%     file sizes in bytes.

arguments
  inputFiles {mustBeA(inputFiles, ["char","cell"])}
end

% Parse input
if ~iscell(inputFiles)
  inputFiles = {inputFiles};
end

% Get file sizes
individualSizes = zeros(numel(inputFiles),1);
for f = 1:numel(inputFiles)
  d = dir(inputFiles{f});
  if isempty(d)
    error([inputFiles{f} ' file not found.']);
  end
  individualSizes(f) = d.bytes;
end
totalSize = sum(individualSizes);
end

function [session,inputFiles] = calculateEpochDurations(session, basepath, probeLetter)
    inputFiles = {};
    startTime = 0;
    stopTime = 0;
    nSamples = 0;
    
    for i = 1:numel(session.epochs)
        session.epochs{i}.startTime = startTime;
        
        % Define possible file paths
        possiblePaths = {
            fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.dat'),
            fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.bin'),
            fullfile(basepath,session.epochs{i}.name,'continuous',['Neuropix-PXI-100.Probe' probeLetter],'continuous.dat'),
            fullfile(basepath,session.epochs{i}.name,'continuous',['Neuropix-PXI-100.Probe' probeLetter '-AP'],'continuous.dat'),
            fullfile(basepath,session.epochs{i}.name,'continuous',['Neuropix-PXI-103.Probe' probeLetter],'continuous.dat'),
            fullfile(basepath,session.epochs{i}.name,'continuous',['Neuropix-PXI-103.Probe' probeLetter '-AP'],'continuous.dat'),
        };
        
        % Check each possible path
        fileFound = false;
        for pathIdx = 1:length(possiblePaths)
            if exist(possiblePaths{pathIdx}, 'file')
                inputFiles{i} = possiblePaths{pathIdx};
                fileFound = true;
                break;
            end
        end
        
        if ~fileFound
            error(['Epoch duration could not be estimated as raw data file does not exist for Probe' probeLetter ' in epoch ' num2str(i)]);
        end
        
        temp = dir(inputFiles{i});
        duration = temp.bytes/session.extracellular.sr/session.extracellular.nChannels/2;
        stopTime = startTime + duration;
        session.epochs{i}.stopTime = stopTime;
        startTime = stopTime;
        nSamples = nSamples + temp.bytes/session.extracellular.nChannels/2;
    end
    session.extracellular.nSamples = nSamples;
    session.general.duration = nSamples/session.extracellular.sr;
end