classdef (Sealed) Variable
    %Surface Fitting Tool Variable
    %
    %   VARIABLE stores a Surface Fitting variable. It allows access to the
    %   original size and class of the variable and to a value that
    %   represents the data as a double column vector.
    
    %   Copyright 2009-2012 The MathWorks, Inc.
    
    properties (SetAccess = 'private')
        % Name - data name
        Name = '';
    end
    
    properties(Dependent, SetAccess = 'private')
        % Values - original data converted to a double column vector
        Values;
        % Size - size of the original data
        Size;
        % Class - class of the original data
        Class;
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % Version - class version number
        Version = 1;
        % OriginalData - value in its original size and shape
        OriginalData;
    end
    
    properties(SetAccess = 'private')
        % Specified is true if the object has been constructed with both
        % name and value.
        Specified = false;
    end
    
    methods
        function this = Variable(name, data)
            % Construct an sftoolgui.Variable object with name and data if supplied.
            %
            % VARIABLE()
            % Creates a default Variable object
            % VARIABLE(NAME)
            % Creates a Variable object using NAME
            % VARIABLE(NAME, DATA)
            % Creates a Variable object using NAME and DATA
            
            if nargin > 0
                this.Name = name;
            end
            
            if nargin > 1
                this.OriginalData = data;
                this.Specified = true;
            end
        end
        
        function this = set.OriginalData(this, data)
            % DATA is valid if it is non-scalar numeric.
            if isscalar(data) || ~isnumeric(data)
                error(message('curvefit:sftoolgui:Variable:InvalidDataValue'));
            else
                this.OriginalData = data;
            end
        end
        
        function this = set.Name(this, name)
            % Name is valid if it is a string.
            if ~ischar(name)
                error(message('curvefit:sftoolgui:Variable:InvalidName'));
            else
                this.Name = name;
            end
        end
        
        function values = get.Values(this)
            % The returned value is the original data converted to a double
            % column vector.
            values = full( double( this.OriginalData(:) ) );
        end
        
        function originalDataSize = get.Size(this)
            % The returned value is the size of the original data.
            originalDataSize = size(this.OriginalData);
        end
        
        function isDbl = IsDouble(this)
            % check if this is a double or sub-class of double
            isDbl = isa(this.OriginalData, 'double');
        end
    end
end

