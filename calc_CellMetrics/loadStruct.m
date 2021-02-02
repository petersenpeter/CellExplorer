function output = loadStruct(dataName,datatype,varargin)
% Load event, manipulation, behavior data to appropiate .mat files
%
% Example calls
% trials = loadStruct('trials','behavior','session',session);
% spikes = loadStruct('spikes','cellinfo','session',session);
% cell_metrics = loadStruct('cell_metrics','cellinfo','session',session);
% ripples = loadStruct('ripples','events','session',session);

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 24-02-2020

p = inputParser;
addParameter(p,'basepath',pwd,@isstr); 
addParameter(p,'basename','',@isstr);
addParameter(p,'session',{},@isstruct);
addParameter(p,'recording',{},@isstruct);
parse(p,varargin{:})

basepath = p.Results.basepath;
basename = p.Results.basename;
session = p.Results.session;
recording = p.Results.recording;

% Supported data types
supportedDataTypes = {'timeseries', 'events', 'manipulation', 'behavior', 'cellinfo', 'channelInfo', 'sessionInfo', 'states', 'firingRateMap', 'lfp', 'session'};

% Importing parameters from session or recording struct
if ~isempty(session)
    basename = session.general.name;
    basepath = session.general.basePath;    
elseif ~isempty(recording)
    basename = recording.name;
    basepath = pwd;
elseif isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

% Validation
% No validation implemented yet


if any(strcmp(datatype,supportedDataTypes))
    switch datatype
        case {'sessionInfo','session'}
            filename = fullfile(basepath,[basename,'.',datatype,'.mat']);
        otherwise
            filename = fullfile(basepath,[basename,'.',dataName,'.',datatype,'.mat']);
    end
    dataStructure = load(filename);
    if isfield(dataStructure,dataName)
        output = dataStructure.(dataName);
    else
        temp = fieldnames(dataStructure);
        output = dataStructure.(temp{1});
        warning(['naming convention not upheld in loaded data: ' dataName,' => ',temp{1}])
    end
%     disp(['Successfully loaded ', filename])
else
    error(['Not a valid datatype: ', datatype,', filename: ' filename])
end
