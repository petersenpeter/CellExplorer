function lfpExtension = exist_LFP(session)
% Checks for an existing LFP file
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-11-2019

basepath = session.general.basePath;
basename = session.general.name;
if ~exist(fullfile(basepath, [basename, '.lfp']),'file') && ~exist(fullfile(basepath, [basename, '.eeg']),'file')
    disp('Creating lfp file')
    ce_LFPfromDat(session,'noPrompts',true)
    lfpExtension = '.lfp';
elseif exist(fullfile(basepath, [basename, '.lfp']),'file')
    lfpExtension = '.lfp';
elseif exist(fullfile(basepath, [basename, '.eeg']),'file')
    lfpExtension = '.eeg';
end