classdef(HandleCompatible) ListenerTarget
    %ListenerTarget Mixin class that provides standard listener creation and storage
    %
    %  The ListenerTarget class should be inherited from when a class
    %  needs the ability to attach listeners to other objects.  This mixin
    %  class provides two capabilities:
    %     * creation of the correct kind of listener for a given source
    %     * storage of listeners within the ListenerTarget
    %
    %  The stored listeners will not be saved: it is the responsibility of
    %  a subclass to recreate and re-store new ones on load.
    %
    %  Curvefit classes should always use this class to create listeners:
    %  there should be no direct calls to event.(prop)listener or
    %  addlistener except in exceptional circumstances.
    %
    %  ListenerTarget properties:  
    %  (Protected, read-only)
    %    Listeners      - Cell array of stored listeners.
    %
    %  ListenerTarget methods:
    %  (Protected)
    %    storeListener  - Add a new listener to the list of stored ones.
    %    createListener - Create a new listener and store it.
    %
    %  Example pseudo-code:  
    %    
    %  classdef CurveFitClass < curvefit.ListenerTarget
    %    ...
    %    methods
    %      function h = CurveFitClass(FitdevObject)
    %         U = uicontrol;
    %         h.createListener(U, 'ActionEvent', {@MyCallback, Arg});
    %         
    %         h.createListener(FitdevObject, 'FitUpdated', @MyFitCallback);
    %      end
    %    end
    %  end    
       
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties(SetAccess=private, GetAccess=protected, Transient)
        %Listeners  List of listeners that are being held by the class.
        %  The listeners are accessible by subclasses and may be deleted if
        %  required.
        Listeners = {}
    end
    
   properties(Access=private, Constant)
        %CheckPeriod Number of listeners to allow to be added between validity checks
        CheckPeriod = 20;
    end
    
    properties(Access=private, Transient)
        %CheckedLength  The length of the listener list when it was last checked for validity.
        CheckedLength = 0;
    end
    
    methods(Access=protected)
        function obj = storeListener(obj, L)
            %storeListener Keep a copy of a listener in a stored list
            %
            %  obj = storeListener(obj, L) places a copy of the listener L
            %  in a stored list in the object in order to prevent it from
            %  going out of scope.  This method should be used if you have
            %  a listener that has been created in an unusual way: for most
            %  purposes use the createListener method.
            %
            %  See also: createListener
            
            obj.Listeners{end+1} = L;
            
            % Check for invalid listener handles if the listener list is
            % getting long.
            if length(obj.Listeners) > (obj.CheckedLength+obj.CheckPeriod)
                obj = cleanupListeners(obj);
            end
        end
        
        function [L, obj] = createListener(obj, src, event, callback)
            %createListener Create a listener and store a copy of it.
            %
            %  [L, obj] = createListener(obj, src, event, callback) creates
            %  a listener on the specified event of the src object, array
            %  of objects or cell array of objects.  The listener is stored
            %  in the target object, obj, as well as being returned.
            %
            %  If event is a property name in src then a listener will be
            %  created on the PostSet event of that property.
            %
            %  The callback may be either a function handle or a cell array
            %  that contains a function handle and additional arguments.
            %
            %  This method will automatically switch between creating
            %  standard event listeners and queued listeners, depending on
            %  the class of the src object.
            %
            %  See also: storeListener, Handle
            
            L = curvefit.createListener(src, event, callback);      
            obj = storeListener(obj, L);
        end
    end
    
    
    methods(Access=private)
        function obj = cleanupListeners(obj)
            % Check for deleted listeners and remove them 
            isValid = cellfun(@iIsValidHandle, obj.Listeners);
            obj.Listeners = obj.Listeners(isValid);
            obj.CheckedLength = length(obj.Listeners);
        end
    end
end


function ok = iIsValidHandle(L)
%iIsValidHandle Check whether a listener handle is valid
if isa(L, 'handle.listener')
    ok = ishandle(L);
else
    ok = isvalid(L);
end
end
