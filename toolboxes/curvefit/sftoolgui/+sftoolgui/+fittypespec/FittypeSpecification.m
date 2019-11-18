classdef FittypeSpecification < curvefit.Handle & matlab.mixin.Copyable
    % FittypeSpecification An abstract builder for fit type data 
    %
    % Note that this superclass uses the Copyable mixin.  This means that
    % all subclasses are responsible for ensuring that the copyElement
    % method is implemented if a deep copy is required.  However, If all
    % the properties are value classes or effectively immutable this is not
    % necessary
    
    %   Copyright 2012-2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        Fittype
        FitOptions
        ErrorString
    end
    
    properties(Dependent, GetAccess = public, SetAccess = private)
        FittypeString
    end
    
    methods(Abstract)        
        % A specification must implement the accept method, by passing
        % itself to the appropriatefittypeSpecificationVisitor's visit() 
        % method.
        accept(this, fittypeSpecificationVisitor);
    end
    
    methods
        function fittypeString = get.FittypeString(this)
            fittypeString = this.getFittypeString();
        end
    end
    
    methods(Access = protected)
        % A specification must define a way in which it wishes to be
        % displayed to the user, this default behaviour may be overriden in
        % the subclass
        function fittypeString = getFittypeString(this)
            fittypeString = type(this.Fittype);
        end
    end
    
    methods(Hidden, Access = ?sftoolgui.util.DefinitionConverter)
        % This function has been created so that when a FitDefinition is
        % deserialised, it is possible to overwrite the fittype and
        % fitoptions so that the originals are preserved
        function overwriteFittypeAndOptions( this, aFittype, options )
            this.Fittype = aFittype;
            this.FitOptions = options;
        end
    end
    
    methods(Access = protected)
        function aCopy = copyElement(this)
            aCopy = copyElement@matlab.mixin.Copyable(this);
            % FitOptions is stored as a handle, therefore we require a deep
            % copy
            aCopy.FitOptions = fitoptions(this.FitOptions);
        end
    end
end

