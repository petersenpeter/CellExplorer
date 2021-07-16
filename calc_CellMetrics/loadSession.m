function session = loadSession(basepath,basename)
% Loads an existing basename.session.mat file from the basepath. If no
% basepath is providede it will try to load from current directory

% By Peter Petersen
% Last edited: 29-06-2021


if ~exist('basepath','var')
    basepath = pwd;
end

if ~exist('basename','var')
    basename = basenameFromBasepath(basepath);
end
file = fullfile(basepath,[basename,'.session.mat']);
if exist(file,'file')
    load(fullfile(basepath,[basename,'.session.mat']),'session')
else
    error('No session file exist')
end
session.general.basePath = basepath;
