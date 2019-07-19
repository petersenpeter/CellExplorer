function success = saveStruct(data,varargin)
% Saves event, manipulation, behavior data to appropiate .mat files
% Performs validation of the content before saving (not yet implemented)

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 12-07-2019

p = inputParser;
addParameter(p,'data',[],@isstruct); % struct with data to save
addParameter(p,'basepath',pwd,@isstr); 
addParameter(p,'clusteringpath',pwd,@isstr);
addParameter(p,'basename','',@isstr);
addParameter(p,'datatype','events',@isstr); % 
addParameter(p,'session',{},@isstruct);
parse(p,varargin{:})

basepath = p.Results.basepath;
basename = p.Results.basename;
clusteringpath = p.Results.clusteringpath;
datatype = p.Results.datatype;
session = p.Results.session;

success = false;

% Importing parameters from session struct
if ~isempty(session)
    basename = session.general.name;
    basepath = session.general.basePath;
    if isfield(session.general,'clusteringPath')
        clusteringpath = session.general.clusteringPath;
    else
        clusteringpath = basepath;
    end
elseif isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

% Validation


% Saving data to basepath/clusteringpath
supportedDataTypes = {'timeseries','events', 'manipulation', 'behavior', 'cellinfo', 'channelInfo', 'sessionInfo', 'states', 'firingRateMap'};
if any(strcmp(datatype,supportedDataTypes))
    dataName = inputname(1);
    S.(dataName) = data;
    switch datatype
        case {'cellinfo','firingRateMap'}
            filename = fullfile(clusteringpath,[basename,'.',dataName,'.',datatype,'.mat']);
        otherwise
            filename = fullfile(basepath,[basename,'.',dataName,'.',datatype,'.mat']);
    end
    save(filename, '-struct', 'S')
    disp(['Successfully saved ', filename])
    success = true;
else
    error(['Datatype not formatted correctly saved ', filename])
end
