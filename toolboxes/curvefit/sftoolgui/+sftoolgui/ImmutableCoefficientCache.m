classdef ImmutableCoefficientCache < sftoolgui.CoefficientCache
    % ImmutableCoefficientCache A cache that cannot be changed
    % Note that we have not overriden the copyElement method to provide a
    % deep copy of the CoefficientCache property.  This is because the
    % object is effectively immutable
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = private)
        CoefficientCache
    end
    
    methods(Access = public)
        function this = ImmutableCoefficientCache(varargin)
            % ImmutableCoefficientCache constructor can be called with no
            % arguments, or with a CoefficientCache
            if nargin == 0
                constructDefaultImmutableCache(this);
            else
                constructImmutableCacheFromExistingCache(this, varargin{:})
            end
        end
        
        function entries = getCoefficient(this, keys)
            entries = this.CoefficientCache.getCoefficient(keys);
        end
        
        function entries = getStartPoint(this, keys)
            entries = this.CoefficientCache.getStartPoint(keys);
        end
        
        function entries = getLowerBound(this, keys)
            entries = this.CoefficientCache.getLowerBound(keys);
        end
        
        function entries = getUpperBound(this, keys)
            entries = this.CoefficientCache.getUpperBound(keys);
        end
        
        function keys = getNames(this)
            keys = this.CoefficientCache.getNames();
        end
    end
    
    methods(Access = private)
        function constructDefaultImmutableCache(this)
            this.CoefficientCache = sftoolgui.MutableCoefficientCache;
        end
        
        function constructImmutableCacheFromExistingCache(this, varargin)
            aCache = varargin{1};
            
            if isa( aCache, 'sftoolgui.ImmutableCoefficientCache' )
                % Prevent too many levels of indirection
                this.CoefficientCache = copy(aCache.CoefficientCache);
            else
                this.CoefficientCache = copy(aCache);
            end
        end
    end
end
