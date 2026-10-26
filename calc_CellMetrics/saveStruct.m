function success = saveStruct(data, datatype, varargin)
%SAVESTRUCT Save CellExplorer data using the established naming conventions.
% Retains caller-variable inference, including saveStruct(session).
% New code should call ce.io.saveStruct with an explicit dataName.
callerName = inputname(1);
if strcmp(callerName, 'session')
    datatype = 'session';
    varargin = [varargin, {'session', data}];
elseif nargin < 2
    error('ce:io:MissingDatatype', 'Specify a datatype when the input is not named session.');
end
if ~any(strcmpi(varargin(1:2:end), 'dataName'))
    varargin = [varargin, {'dataName', callerName}];
end
success = ce.io.saveStruct(data, datatype, varargin{:});
end
