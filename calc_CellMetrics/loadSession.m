function session = loadSession(basepath,basename)
% Loads an existing basename.session.mat file from the basepath. If no
% basepath is providede it will try to load from current directory

% By Peter Petersen
% Last edited: 29-06-2020

if ~exist('basepath')
    basepath = pwd;
end
if ~exist('basename')
    test = dir(fullfile(basepath,'*.session.mat'));
    if ~isempty(test)
        load(fullfile(basepath,test.name));
    else
        error(['No *.session.mat file exist in basepath: ' basepath])
    end
else
    load(fullfile(basepath,[basename,'.session.mat']),'session')
end
session.general.basePath = basepath;
