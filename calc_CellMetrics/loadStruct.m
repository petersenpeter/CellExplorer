function output = loadStruct(dataName,datatype,varargin)
% Load event, manipulation, behavior data to appropiate .mat files

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 27-08-2019

p = inputParser;
addParameter(p,'basepath',pwd,@isstr); 
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'basename','',@isstr);
addParameter(p,'session',{},@isstruct);
addParameter(p,'recording',{},@isstruct);
parse(p,varargin{:})

basepath = p.Results.basepath;
basename = p.Results.basename;
clusteringpath = p.Results.clusteringpath;
session = p.Results.session;
recording = p.Results.recording;

% Importing parameters from session or recording struct
if ~isempty(session)
    basename = session.general.name;
    basepath = session.general.basePath;
    if isfield(session.general,'clusteringPath')
        clusteringpath = session.general.clusteringPath;
    else
        clusteringpath = basepath;
    end
    
elseif ~isempty(recording)
    basename = recording.name;
    basepath = pwd;
    clusteringpath = recording.SpikeSorting.path;
    
elseif isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
    
end

% Validation
% No validation implemented yet

% Loading data to basepath/clusteringpath
supportedDataTypes = {'timeseries', 'events', 'manipulation', 'behavior', 'cellinfo', 'channelInfo', 'sessionInfo', 'states', 'firingRateMap', 'lfp', 'session'};

if any(strcmp(datatype,supportedDataTypes))
    switch datatype
        case {'sessionInfo','session'}
            filename = fullfile(basepath,[basename,'.',datatype,'.mat']);
        case {'cellinfo','firingRateMap'}
            filename = fullfile(clusteringpath,[basename,'.',dataName,'.',datatype,'.mat']);
        otherwise
            filename = fullfile(basepath,[basename,'.',dataName,'.',datatype,'.mat']);
    end
    temp = load(filename);
    output = temp.(dataName);
%     disp(['Successfully loaded ', filename])
else
    error(['Not a valid datatype: ', datatype,', filename: ' filename])
end
