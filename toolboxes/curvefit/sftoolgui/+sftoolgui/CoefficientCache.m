classdef CoefficientCache < curvefit.Handle & matlab.mixin.Copyable
    % CoefficientCache Caches lower bounds, upper bounds and start points
    % This abstract class represents the top level interface that should
    % generally be used when querying a CoefficientCache object.
    
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    methods(Abstract, Access = public)
        % getCoefficient returns a matrix whose rows represent the start
        % point, lower bound, and upper bound of the keys parameter
        entries = getCoefficient(this, keys);
        
        % getStartPoint returns a vector of start points which are
        % associated with the keys parameter.  If the object does not
        % have an entry for a key, it will return a NaN value
        entries = getStartPoint(this, keys);
        
        % getLowerBound returns a vector of lower bounds which are
        % associated with the keys parameter.  If the object does not
        % have an entry for a key, it will return a NaN value
        entries = getLowerBound(this, keys);
        
        % getUpperBound returns a vector of upper bounds which are
        % associated with the keys parameter.  If the object does not
        % have an entry for a key, it will return a NaN value
        entries = getUpperBound(this, keys);
        
        % getNames returns all of the coefficient names which have been
        % registered with the cache
        keys = getNames(this);
    end
end
