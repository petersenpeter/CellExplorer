classdef EventQueue < curvefit.Handle
    %EventQueue Class to capture, queue and execute event callbacks.
    %
    %  The EventQueue class is intended to capture callbacks from multiple
    %  sources that are external to the application software (for example
    %  Java GUI elements and Matlab GUI controls).  The captured callbacks
    %  are placed into a single queue and are then executed in the order in
    %  which they occurred.  This solves the problem of events from one
    %  system interrupting earlier callbacks from other systems and/or
    %  itself.
    %
    %  Example:
    %
    %      theQueue = curvefit.gui.event.EventQueue.getSharedQueue;
    %      cb = theQueue.createCallback(@MyCallback);
    %      uicontrol('Callback', cb);
    %
    %  See also: curvefit.gui.event.callback, curvefit.gui.event.listener,
    %  curvefit.gui.event.proplistener, curvefit.gui.event.interruptListener.
    
    %  Copyright 2011-2012 The MathWorks, Inc.
    
    properties(Dependent, SetAccess=private)
        %Length  
        %  Length contains the number of items that have been queued but
        %  have not yet been executed.
        Length
    end
    
    
    properties(Access=private)
        %QueueData
        %  QueueData contains a structure array of the callbacks that are queued
        %  and not yet executed.
        QueueData = struct('Callback', {}, 'Source', {}, 'EventData',{}, 'HGState', {});
    end
    
    properties(Access=private, Transient)
        %IsFlushing
        %  IsFlushing indicates whether this queue is currently being
        %  flushed.
        IsFlushing = false;
    end
    
    % Basic queue interaction methods
    methods
        function L = get.Length(obj)
            L = size(obj.QueueData, 2);
        end
            
        function add(obj, callback, src, evtData)
            %add Add an event response to the queue
            %
            %  obj.add(callback, src, evtData) adds the specified callback
            %  to the end of the queue along with its associated event
            %  data.  The Callback input must be either a function handle
            %  or a cell array containing a function handle and any
            %  additional trailing arguments to be passed to the function.
            
            if isa(callback, 'function_handle')
                callback = {callback};
            end
            
            iAssertValidCallback(callback);
            
            % Add the callback information along with HG state data if we
            % can find a current figure
            obj.QueueData(end+1) = struct(...
                'Callback', {callback}, ...
                'Source', {src}, ...
                'EventData', {evtData}, ...
                'HGState', iGetHGState(src));
        end
        

        function flush(obj)
            %flush Execute all queued event responses
            %
            %  obj.flush() executes all queued event responses until the
            %  queue is empty.  If items are added during this method they
            %  will be included in the flush.
            %
            %  When a queue has started being flushed, no future flush
            %  calls will be allowed to start; additional calls to this
            %  method will be ignored silently.
            
            if ~obj.IsFlushing
                % Set the lock and start executing events
                obj.IsFlushing = true;
                FlushLockCleaner = onCleanup(iCreateClearFlushingCallback(obj));
                
                obj.pumpQueue();
            end
        end
        
        function flushLater(obj)
            %flushLater Request a flush at a later point in time
            %
            %  obj.flushLater() requests a full flush be done at a later
            %  point in time.  This flushLater call will return immediately
            %  and the flush will be executed as soon afterwards as
            %  possible.
            
            if ~obj.IsFlushing && ~isempty(obj.QueueData)
                obj.IsFlushing = true;
                FlushLockCleaner = onCleanup(iCreateClearFlushingCallback(obj));
                
                curvefit.doLater({@iFlushLaterCallback, obj, FlushLockCleaner});
            end
        end
    end
    
    
    % Higher-level methods for using the queue
    methods
        function cb = createCallback(obj, func, varargin)
            %createCallback  Create a callback that queues itself
            %
            %  obj.createCallback(FUNC) returns a callback function handle
            %  that will queue and execute the callback function FUNC.  The
            %  syntax of FUNC must follow the standard callback form of
            %  FUNC(src, evtData).
            %
            %  obj.createCallback(FUNC, ARG1, ARG2, ...) returns a
            %  self-queuing callback function that will call FUNC(src,
            %  evtData, ARG1, ARG2, ...) when executed.
            
            % Form a correct queue entry
            item = [{func}, varargin];  
 
            % Error now if we are being asked to create a callback for
            % something that the queue will later not recognize as valid.
            iAssertValidCallback(item);
            
            cb = @executeWithQueue;
            
            function executeWithQueue(src, evt)
                % Add item to the queue
                obj.add(item, src, evt);
    
                % Check whether our item is the only one in the queue - if
                % so then we can just execute it now.
                if ~obj.IsFlushing && obj.Length==1
                    obj.flushOne();
                end
                                
                % Always request a full flush at a later time in case
                % something else has been added to the queue.
                obj.flushLater();
            end
        end
    end
    
    
    methods(Access=private)
        function flushOne(obj)
            %flushOne  Execute a single item in the queue
            %
            %  flushOne(obj) executes the top item in the queue.
            
            if ~obj.IsFlushing
                % Set the lock
                obj.IsFlushing = true;
                FlushLockCleaner = onCleanup(iCreateClearFlushingCallback(obj));
                
                % Execute the top item
                if ~isempty(obj.QueueData)
                    obj.pumpOne();
                end
            end
        end
        
        function pumpOne(obj)
            %pumpOne Execute the top item in the queue
            %
            %  pumpOne(obj) executes the top item in the queue.  The queue
            %  must not be empty when this method is called.
            
            queueEntry = obj.QueueData(1);
            obj.QueueData(1) = [];
            
            if curvefit.event.isValidSource(queueEntry.Source)
                % Execute the entry
                iExecute(queueEntry);
            end
        end
        
        function pumpQueue(obj)
            %pumpQueue  Execute all items in the queue
            %
            %  pumpQueue(obj) executes items in the queue one-by-one,
            %  until the queue is empty.
            
            while ~isempty(obj.QueueData)
                obj.pumpOne();
            end
        end
        
        function clearFlushing(obj)
            %clearFlushing Clear the Flushing lock
            %
            %  obj.clearFlushing() sets the IsFlushing flag to false.
            obj.IsFlushing = false;
        end
    end
    
    
    methods(Static)     
        function queue = getSharedQueue()
            %getSharedQueue Get the shared event queue for Curve Fitting Toolbox
            %
            %  getSharedQueue() returns a handle to a singleton EventQueue
            %  that should be used for all Curve Fitting Toolbox GUI event
            %  responses.
            
            queue = curvefit.gui.event.EventQueue.accessSharedQueue();
            if isempty(queue) || ~isvalid(queue)
                % Initialise the shared queue to an instance of this class
                queue = curvefit.gui.event.EventQueue();
                curvefit.gui.event.EventQueue.accessSharedQueue(queue);
            end
        end
        
        function setSharedQueue(queue)
            %setSharedQueue Set the shared event queue
            %
            %  setSharedQueue(queue) sets a new queue to be the shared
            %  Curve Fitting Toolbox GUI event queue.
 
            curvefit.gui.event.EventQueue.accessSharedQueue(queue);
        end
    end
    
    methods(Static, Access=private)
        function queue = accessSharedQueue(queue)
            % Maintain and allow access to a persistent shared queue
            
            persistent theQueue

            if nargin
                % Set the queue
                theQueue = queue;
            else
                % Retrieve current queue
                queue = theQueue;
            end
        end   
    end
end

function iFlushLaterCallback(obj, FlushLockCleaner)
%iFlushLaterCallback Callback function that starts a flush

if isvalid(obj)
    % Empty the queue
    obj.pumpQueue();
end

% Destroy the flush lock holder,  unlocking the queue for future pumping.
delete(FlushLockCleaner);
end

function Fcn = iCreateClearFlushingCallback(obj)
%iCreateClearFlushingCallback Create a safe function handle for onCleanup
%
%   iCreateClearFlushingCallback(obj) creates a function handle that calls
%   the clearFlushing method on obj.  The function handle will not have
%   additional references within it.

Fcn = @obj.clearFlushing;
end

function iExecute(queueEntry)
%execute Evaluate a single queue entry callback function.
%
%  execute(queueEntry) takes the data for a single queued event
%  and evaluates the callback function.

% Extract callback and event data
callback = queueEntry.Callback;
src = queueEntry.Source;
evtData = queueEntry.EventData;

% Restore key HG values to those that we took a copy of at the time of the
% event
CurrentHGState = iGetHGState(src);
iRestoreHGState(src, queueEntry.HGState);

if iscell(callback)
    % Execute {@func, arg1, arg2, ...} callback style
    func = callback{1};
    args = callback(2:end);
else
    % The data isn't in the recognized callback format.  These
    % should not get through the input checks in add().  By
    % dumping the callback into func we will generate an error
    % in the feval below which will give the user a useful
    % notification.
    func = callback;
    args = {};
end

try
    func(src, evtData, args{:});
catch E
    % The callback errored.  We want to show this but we don't
    % want to stop the processing of succeeding callbacks.
    warning(message('curvefit:curvefit:gui:event:EventQueue:CallbackError', E.getReport()));
end

% Restore HG state back to what it was
iRestoreHGState(src, CurrentHGState);

end


function iAssertValidCallback(callback)
% Throw an error if the input is not a callback that we can execute
if ~(iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle'))
    error(message('curvefit:curvefit:gui:event:EventQueue:InvalidCallback'));
end
end


function state = iGetHGState(src)
% Take a copy of the state of some key HG variables that callbacks may be
% relying on.  Currently this includes mouse position and mouse click type
% if we can find a related figure.
state = [];
fig = iGetFigure(src);
if ~isempty(fig)
    state.CurrentPoint = get(fig, 'CurrentPoint');
    state.SelectionType = get(fig, 'SelectionType');
end
end

function iRestoreHGState(src, state)
% Restore the HG state that was saved when the event occurred.
if ~isempty(state)
    fig = iGetFigure(src);
    if ~isempty(fig)
        set(fig, state);
    end
end
end

function fig = iGetFigure(src)
% Ancestor returns an empty if the source is not recognized as HG
fig = ancestor(src, 'figure');
end
