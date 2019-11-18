classdef(Sealed) MutableCoefficientCache < sftoolgui.CoefficientCache
    % MutableCoefficientCache Used as a copy of the Java coefficient cache
    % This class is used to contain the cached information received from
    % the Java events which describe the change to a fit type or options.
    %
    
    %   Copyright 2013 The MathWorks, Inc.
    
    properties (Access = private)
        CacheContainer
    end
    
    methods(Access = public)
        function this = MutableCoefficientCache
            % CoefficientCache constructor is called with no arguments.  To
            % add a coefficient to the cache, call the addCoefficient
            % function
            this.CacheContainer = containers.Map();
        end
        
        function addCoefficient(this, name, startpoint, lowerbound, upperbound)
            % addCoefficient is the mechanism by which you can add or update an
            % entry in the CoefficientCache
            this.CacheContainer(name) = [startpoint, lowerbound, upperbound];
        end
        
        function entries = getCoefficient(this, keys)
            keys = iEnsureCellString(keys);
            entries = iGenerateEntryMatrix(this.CacheContainer, keys);
        end
        
        function entries = getStartPoint(this, keys)
            keys = iEnsureCellString(keys);
            entries = iGenerateStartPointVector(this.CacheContainer, keys);
            
        end
        
        function entries = getLowerBound(this, keys)
            keys = iEnsureCellString(keys);
            entries = iGenerateLowerBoundVector(this.CacheContainer, keys);
            
        end
        
        function entries = getUpperBound(this, keys)
            keys = iEnsureCellString(keys);
            entries = iGenerateUpperBoundVector(this.CacheContainer, keys);
        end
        
        function keys = getNames(this)
            keys = this.CacheContainer.keys;
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function cpObj = copyElement(this)
            % Make a shallow copy of all properties
            cpObj = copyElement@matlab.mixin.Copyable(this);
            % Replace coefficient cache with a deep copy of the cache
            % object
            cpObj.CacheContainer = iCloneMap(this.CacheContainer);
        end
    end
end

function clonedMap = iCloneMap(map)
if isempty(map.keys)
    clonedMap = containers.Map;
else
    clonedMap = containers.Map(map.keys, map.values);
end
end

function entries = iGenerateEntryMatrix(container, keys)
entries = zeros(length(keys), 3);
for i = 1:length(keys)
    entries(i,:) = iGetCachedOrNaN(container, keys{i});
end
end

function entries = iGenerateStartPointVector(container, keys)
entries = zeros(length(keys), 1);
for i = 1:length(keys)
    entry = iGetCachedOrNaN(container, keys{i});
    entries(i,:) = entry(1);
end
end

function entries = iGenerateLowerBoundVector(container, keys)
entries = zeros(length(keys), 1);
for i = 1:length(keys)
    entry = iGetCachedOrNaN(container, keys{i});
    entries(i,:) = entry(2);
end
end

function entries = iGenerateUpperBoundVector(container, keys)
entries = zeros(length(keys), 1);
for i = 1:length(keys)
    entry = iGetCachedOrNaN(container, keys{i});
    entries(i,:) = entry(3);
end
end

function entry = iGetCachedOrNaN(container, key)
% iGetCachedOrNan looks for an entry for the corresponding key, and returns
% NaNs if such a key does not exist
if container.isKey(key)
    entry = container(key);
else
    entry = [NaN NaN NaN];
end
end
function keys = iEnsureCellString(keys)
if isa( keys, 'char' )
    % convert to cell-string
    keys = {keys};
end
end
