function makeRecursive(listener)
%makeRecursive Set listener properties so that it allows recursion
%
%  makeRecursive(Listener) sets appropriate properties on Listener so that
%  it will allow recursion.  This function works with both normal and
%  legacy listeners.

%   Copyright 2012 The MathWorks, Inc.

if isa(listener, 'handle.listener')
    listener.RecursionLimit = 255;
else
    listener.Recursive = true;
end
