function obj = saveobj(obj)
%SAVEOBJ Method to pre-process FITTYPE objects before saving

%   Copyright 2001-2013 The MathWorks, Inc.

% Remove function handles that will be useless if loaded later
if ~isequal( category( obj ), 'custom' )
    obj = clearhandles( obj );
end
end
