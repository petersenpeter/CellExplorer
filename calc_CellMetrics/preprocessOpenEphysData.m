function session = preprocessOpenEphysData(varargin)
    % https://open-ephys.github.io/gui-docs/User-Manual/Recording-data/Binary-format.html
    
    % Processing steps:
    % 1. Detects epochs (name and duration from experiments and recording folders)
    % 2. Imports extracellular metadata from the first structure.oebin file
    % 3. Channel coordinates (NOT IMPLEMENTED YET)
    % 4. Epoch durations
    % 5. Saving session struct
    % 6. Merge dat/bin files to single binary .dat file in basepath
    % 7. Merge lfp files
    % 8. Merge and import digital timeseries
    
    p = inputParser;
    addParameter(p,'session', [], @isstruct); % A session struct
    addParameter(p,'basepath',pwd,@isstr);
    addParameter(p,'format',pwd,@isstr); % binary, nwb, or openEphys
    addParameter(p,'saveMat', true, @islogical); % Saves basename.session.mat file
    addParameter(p,'showGUI',false,@islogical);
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
    subFolder_Experiments = checkfolder(basepath, 'experiment');
    for i = 1:numel(subFolder_Experiments)
        subFolder_Recordings = checkfolder(subFolder_Experiments{i}, 'recording');
        for j = 1:numel(subFolder_Recordings)            
            session.epochs{k}.name = fullfile(subFolder_Experiments{i},subFolder_Recordings{j});
            session.epochs{k}.startTime = 0;
            session.epochs{k}.stopTime = 0;
            session.epochs{k}.notes = fullfile(subFolder_Experiments{i},subFolder_Recordings{j});
            k = k + 1;            
        end
    end
    
    % 2. Imports extracellular metadata from the first structure.oebin file 
    session = loadOpenEphysSettingsFile(session);
    
    % 3. Channel coordinates (NOT IMPLEMENTED YET)
    
    
    % 4. Epoch durations
    inputFiles = {};
    startTime = 0;
    stopTime = 0;
    nSamples = 0;
    for i = 1:numel(session.epochs)
        session.epochs{i}.startTime = startTime;
        if exist(fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.bin'),'file')
            inputFiles{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.bin');
        elseif exist(fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.dat'),'file')
            inputFiles{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.0','continuous.dat');
        else
            error(['Epoch duration could not be estimated as raw data file does not exist: ', inputFiles{i}]);
        end
        temp = dir(inputFiles{i});
        duration = temp.bytes/session.extracellular.sr/session.extracellular.nChannels/2;
        stopTime = startTime+duration;
        session.epochs{i}.stopTime = stopTime;
        startTime = stopTime;
        nSamples = nSamples + temp.bytes/session.extracellular.nChannels/2;
    end
    session.extracellular.nSamples = nSamples;
    session.general.duration = nSamples/session.extracellular.sr;
       
    % Shows session GUI if requested by user
    if parameters.showGUI
        session = gui_session(session);
    end
    
    % 5. Saving session struct
    saveStruct(session);
    
    
    % 6. Merge dat/bin files to a single binary .dat file in basepath
    outputFile = fullfile(basepath,[session.general.name,'.dat']);
    if ~exist(outputFile,'file')
        disp('Concatenating binary raw files')
        concatenate_binary_files(inputFiles,outputFile)
    else
        disp(['Binary file already exist: ',outputFile])
    end
    
    
    % 7. Merge lfp files
    inputFiles_lfp = {};
    for i = 1:numel(session.epochs)
        if exist(fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.bin'),'file')
            inputFiles_lfp{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.bin');
        else
            inputFiles_lfp{i} = fullfile(basepath,session.epochs{i}.name,'continuous','Neuropix-PXI-100.1','continuous.dat');
        end
    end    
    outputFile_lfp = fullfile(basepath,[session.general.name,'.lfp']);
    
    if ~exist(outputFile_lfp,'file')
        disp('Concatenating lfp files')
        concatenate_binary_files(inputFiles_lfp,outputFile_lfp)
    else
        disp(['LFP file already exist: ',outputFile_lfp])
    end    
    
    % 8. Merge and import digital timeseries
    openephysDig = loadOpenEphysDigital(session);

    function subFolderNames = checkfolder(dir1, folderstring)
        files = dir(dir1);
        dirFlags = [files.isdir]; % Get a logical vector that tells which is a directory.
        subFolders = files(dirFlags); % Extract only those that are directories.
        subFolderNames = {subFolders(3:end).name}; % Get only the folder names into a cell array.  Start at 3 to skip . and ..
        subFolderNames = subFolderNames(contains(subFolderNames,folderstring));
    end    
end
