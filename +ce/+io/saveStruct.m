function success = saveStruct(data, datatype, varargin)
%SAVESTRUCT Save a named CellExplorer data structure.
% Package callers supply dataName explicitly (except session metadata).
% The legacy wrapper preserves inference from the caller's variable name.
p = inputParser;
addParameter(p, 'basepath', pwd, @(x) ischar(x) || isstring(x));
addParameter(p, 'basename', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'session', [], @isstruct);
addParameter(p, 'dataName', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'fileformat', 'mat', @(x) ischar(x) || isstring(x));
addParameter(p, 'commandDisp', true, @islogical);
parse(p, varargin{:});
options = p.Results;
datatype = char(datatype);
dataName = char(options.dataName);
format = lower(char(options.fileformat));
supported = {'session','sessionInfo','behavior','cellinfo','events','manipulation', ...
    'states','channelInfo','timeseries','digitalseries','firingRateMap','lfp'};
if ~ismember(datatype, supported)
    error('ce:io:UnsupportedDatatype', 'Unsupported datatype: %s', datatype);
end
session = options.session;
if strcmp(datatype, 'session') && isempty(session)
    session = data;
end
if ~isempty(session)
    basepath = session.general.basePath;
    basename = session.general.name;
else
    basepath = char(options.basepath);
    basename = char(options.basename);
    if isempty(basename)
        basename = ce.io.basenameFromBasepath(basepath);
    end
end
if isempty(dataName) && ismember(datatype, {'session','sessionInfo'})
    dataName = datatype;
end
if isempty(dataName)
    error('ce:io:MissingDataName', 'Specify dataName when saving %s data.', datatype);
end
if ismember(datatype, {'session','sessionInfo'})
    filename = fullfile(basepath, [basename, '.', datatype, '.', format]);
else
    filename = fullfile(basepath, [basename, '.', dataName, '.', datatype, '.', format]);
end
isCellMetrics = strcmp(datatype, 'cellinfo') && contains(dataName, 'cell_metrics');
switch format
    case 'mat'
        if contains(dataName, 'cell_metrics')
            variableName = 'cell_metrics';
        else
            variableName = dataName;
        end
        if ~isvarname(variableName)
            error('ce:io:InvalidDataName', 'Invalid MAT variable name: %s', variableName);
        end
        variables.(variableName) = data;
        ce.io.writeMat(filename, variables);
    case 'json'
        ce.io.writeJson(filename, data);
    case 'nwb'
        if ~isCellMetrics
            error('ce:io:UnsupportedDatatype', 'NWB export requires cellinfo with a cell_metrics dataName.');
        end
        ce.io.saveCellMetrics(data, filename);
    otherwise
        error('ce:io:UnsupportedFormat', 'Unsupported file format: %s', format);
end
success = true;
if options.commandDisp
    fprintf('Saved %s to %s\n', dataName, filename);
end
end
