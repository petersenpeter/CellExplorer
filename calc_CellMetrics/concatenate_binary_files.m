function concatenate_binary_files(inputFiles,outputFile)
% Creates a concatenated binary dat file
%
% Inputs:
% inputFiles: full path to input files (cell array)
% outputFile: full path to output file (char)
% 
% By Peter Petersen
% petersen.peter@gmail.com

% Creating the command

if ispc
    command1 = ['copy /b "', strjoin(inputFiles,'"+"'),'" ', outputFile];
    status = system(command1);    
elseif ismac
    command1 = ['! cat "', strjoin(inputFiles,'" "'), '" > ', outputFile];
    status = system(command1);    
elseif isunix    
    command1 = ['! cat "', strjoin(inputFiles,'" "'), '" > ', outputFile];
    status = system(command1);    
end

% % Adding processing info to a MergePoints struct
% MergePoints.timestamps = transitiontimes_sec;
% MergePoints.timestamps_samples = transitiontimes_samp;
% MergePoints.firstlasttimpoints_samples = firstlasttimepoints;
% MergePoints.foldernames = recordingnames;
% MergePoints.filesmerged = datpaths;
% MergePoints.filesizes = datsizes;
% MergePoints.sizecheck = sizecheck;
% MergePoints.processinginfo.detectorname = 'concatenate_binary_files';
% MergePoints.processinginfo.detectiondate = datestr(now,'yyyy-mm-dd');

% %Saving SleepStates
% eventsfilename = fullfile(basepath,[basename,'.MergePoints.events.mat']);
% save(eventsfilename,'MergePoints');

% fprintf('\nConcatenated files successfully!\n');
