function success = saveStruct(data,datatype,varargin)
% Saves event, manipulation, behavior data to appropiate .mat files
% TODO: Perform validation of the content before saving
%
% Example calls:
% saveStruct(cell_metrics,'cellinfo','session',session); % Saving cell metrics
% saveStruct(ripples,'events','session',session); % Saving ripples
% saveStruct(session); Saving session metadata struct

% By Peter Petersen
% petersen.peter@gmail.com
% Last updated: 03-06-2020

p = inputParser;
addParameter(p,'basepath',pwd,@isstr); 
addParameter(p,'basename','',@isstr);
addParameter(p,'session',{},@isstruct);
addParameter(p,'dataName','',@isstr);
addParameter(p,'commandDisp',true,@islogical);
parse(p,varargin{:});

basepath = p.Results.basepath;
basename = p.Results.basename;
session = p.Results.session;
dataName = p.Results.dataName;
commandDisp = p.Results.commandDisp;
success = false;

if strcmp(inputname(1),'session')
    session = data;
    datatype = 'session';
end
% Importing parameters from session struct
if ~isempty(session)
    basename = session.general.name;
    basepath = session.general.basePath;
elseif isempty(basename)
    basename = basenameFromBasepath(basepath);
end

% Validation
% No validation implemented yet

% Saving data to basepath
supportedDataTypes = {'timeseries','digitalseries','events', 'manipulation', 'behavior', 'cellinfo', 'channelInfo', 'states', 'firingRateMap','lfp','session'};
if any(strcmp(datatype,supportedDataTypes))
    if isempty(dataName)
        dataName = inputname(1);
    end
    S.(dataName) = data;
    switch datatype
        case {'sessionInfo','session'}
            filename = fullfile(basepath,[basename,'.',datatype,'.mat']);
        otherwise
            filename = fullfile(basepath,[basename,'.',dataName,'.',datatype,'.mat']);
    end
    % Saving struct
    % Checks byte size of struct to determine optimal mat format
    structSize = whos('S');
    if structSize.bytes/1000000000 > 2
        save(filename, '-struct', 'S','-v7.3','-nocompression')
        if commandDisp
            disp(['Saved variable ''', dataName, ''' to ', filename,' (v7.3)'])
        end
    else
        save(filename, '-struct', 'S')
        if commandDisp
            disp(['Saved variable ''', dataName, ''' to ', filename])
        end
    end
    success = true;
else
    error(['Not a valid datatype: ', datatype,', basename: ' basename])
end
