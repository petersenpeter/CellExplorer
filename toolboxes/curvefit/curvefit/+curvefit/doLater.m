function doLater(func)
%doLater Execute a function at a later point in time
%
%  doLater(func) schedules the provided function to be executed at a later
%  point in time and returns immediately, before the function is executed.
%  func may be either a function handle or a cell array that contains a
%  function handle and additional arguments
%
%  Example:
%    curvefit.doLater(@() disp('First')) ; disp('Second');
%  produces the output:
%    Second
%    First

%   Copyright 2012 The MathWorks, Inc.

persistent listenerStore
if isempty(listenerStore)
    listenerStore = handle([]);
else
    % Clear out destroyed listener handles from previous calls
    listenerStore(~ishandle(listenerStore)) = [];
end

cb = com.mathworks.jmi.Callback;
L = addlistener(cb, 'Delayed', ''); 
set(L, 'Callback', {@iDoLaterCallback, L, func});
listenerStore(end+1) = L;

cb.postCallback();
end


function iDoLaterCallback(~, ~, L, func)
% Execute the function
if ~iscell(func)
    feval(func);
else
    feval(func{:});
end

%  Destroy the listener that holds a reference to this function
delete(L);
end

