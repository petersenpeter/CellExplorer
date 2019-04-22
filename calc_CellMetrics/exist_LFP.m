function lfpExtension = exist_LFP(basepath,basename)
% Checks for an existing LFP file
if ~exist(fullfile(basepath, [basename, '.lfp']),'file') && ~exist(fullfile(basepath, [basename, '.eeg']),'file')
    disp('Creating lfp file')
    bz_LFPfromDat(basepath,'noPrompts',true)
    lfpExtension = '.lfp';
elseif exist(fullfile(basepath, [basename, '.lfp']),'file')
    lfpExtension = '.lfp';
elseif exist(fullfile(basepath, [basename, '.eeg']),'file')
    lfpExtension = '.eeg';
end