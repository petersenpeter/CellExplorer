function success = saveStruct(data,datatype,varargin)
% Saves event, manipulation, behavior data to appropiate .mat files
% Performs validation of the content before saving (not yet implemented)
%
% Example calls:
% 

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 03-06-2020

p = inputParser;
addParameter(p,'basepath',pwd,@isstr); 
addParameter(p,'basename','',@isstr);
addParameter(p,'session',{},@isstruct);
parse(p,varargin{:});

basepath = p.Results.basepath;
basename = p.Results.basename;
session = p.Results.session;

success = false;

if strcmp(inputname(1),'session')
    session = data;
end
% Importing parameters from session struct
if ~isempty(session)
    basename = session.general.name;
    basepath = session.general.basePath;
elseif isempty(basename)
    s = regexp(basepath, filesep, 'split');
    basename = s{end};
end

% Validation
% No validation implemented yet

% Saving data to basepath
supportedDataTypes = {'timeseries','events', 'manipulation', 'behavior', 'cellinfo', 'channelInfo', 'sessionInfo', 'states', 'firingRateMap','lfp','session'};
if any(strcmp(datatype,supportedDataTypes))
    dataName = inputname(1);
    S.(dataName) = data;
    switch datatype
        case {'sessionInfo','session'}
            filename = fullfile(basepath,[basename,'.',datatype,'.mat']);
        otherwise
            filename = fullfile(basepath,[basename,'.',dataName,'.',datatype,'.mat']);
    end
    % Saving struct. 
    % Checks byte size of struct to determine optimal mat format
    structSize = whos('S');
    if structSize.bytes/1000000000 > 2
        save(filename, '-struct', 'S','-v7.3')
        disp(['Saved variable ''',dataName, ''' to ', filename,' (v7.3)'])
    else
        save(filename, '-struct', 'S')
        disp(['Saved variable ''',dataName, ''' to ', filename])
    end
    success = true;
else
    error(['Not a valid datatype: ', datatype,', basename: ' basename])
end
