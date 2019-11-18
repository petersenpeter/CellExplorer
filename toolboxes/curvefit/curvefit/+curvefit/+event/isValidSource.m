function ret = isValidSource(src)
%isValidSource  Test validity of event source handle
%
%  isValidSource(handle) checks whether an event source handle is valid. A
%  valid source may be a Java object, an object handle or a double HG
%  handle. It must not be a handle to a deleted object.

%   Copyright 2012 The MathWorks, Inc.

if isa(src, 'double')
    src = handle(src);
end

if isobject(src)
    % Some objects
    ret = isscalar(src) && isvalid(src);
elseif all(ishandle(src))
    % Java and other objects.  isscalar does not work for java objects.
    ret = numel(src)==1 ;
else
    % Other datatypes
    ret = false;
end
