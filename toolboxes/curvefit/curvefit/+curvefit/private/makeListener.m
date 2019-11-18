function listener = makeListener(Factory, Source, Event, Callback)
%makeListener  Construct appropriate listener for source
%
%  makeListener(Factory, Source, Event, Callback) constructs the correct
%  listener for the Source input, using functions provided by the Factory.
%  Source may be an array of handles or a cell array of scalar handles.
%  Factory must be a structure containing three fields, Matlab, Legacy and
%  Java, that each contain a function handle to a function that will create
%  an appropriate listener given the Source, Event and Callback.
%
%  This function ensures that we correctly switch between creating
%  listeners from the correct object system, and also that we pass in the
%  correct Source format.

%   Copyright 2012-2014 The MathWorks, Inc.

% Extract a scalar object handle for testing which system we should be
% using
if iscell(Source)
    scalarObj = Source{1};
else
    scalarObj = Source(1);
end

if isjava(scalarObj)
    % Create a java listener
    Source = iJavaToHandleArray(Source);  
    listener = Factory.Java( Source, Event, Callback );   
    
elseif ~isobject( scalarObj )
    % Create a handle listener
    Source = iSourceToHandleArray(Source);  
    listener = Factory.Legacy( Source, Event, Callback );
    
else
    % Convert cell-array callbacks into a function handle
    if iscell(Callback)
        Callback = curvefit.callbackFunction(Callback{:});
    end
    
    % Create an event listener
    listener = Factory.Matlab( Source, Event, Callback );
end


function Source = iJavaToHandleArray(Source)
% Convert all of the java objects to handles and then put them back into a
% handle array
Source = cell(Source);
Source = cellfun(@(x) handle(x), Source, 'UniformOutput', false);
Source = [Source{:}];


function Source = iSourceToHandleArray(Source)
if iscell(Source)
    % handle listeners require an array.
    Source = [Source{:}];
end

% Convert to handles
Source = handle(Source);
