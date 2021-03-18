classdef (Abstract) QueryGroup < handle
    %QUERYGROUP Interface for classes that handle query parameter groups
    
    methods (Abstract)
        
        %QUERYPARAMETERS Convert hit to query parameter objects
        qp = queryParameters(obj)
        
    end % abstract methods
    
end % classdef