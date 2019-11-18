classdef Data < curvefit.Handle
    %Surface Fitting Tool Data
    
    %   Copyright 2008-2013 The MathWorks, Inc.
    
    events
        DimensionChanged
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % Version  - class version number
        Version = 3;
        % X - sftoolgui.Variable containing X data
        X = sftoolgui.Variable();
        % Y - sftoolgui.Variable containing Y data
        Y = sftoolgui.Variable();
        % Z - sftoolgui.Variable containing Z data
        Z = sftoolgui.Variable();
        % W - sftoolgui.Variable for weights
        W = sftoolgui.Variable();
    end
    
    properties
        % Name - data name
        Name = '';
    end
    
    properties(Dependent, GetAccess = 'private', SetAccess = 'private')
        % Message - an array of Message structures. The structure has two
        % fields: Level and String (Strings are xlated).
        Message;
    end
    
    methods
        function this = Data(dataValues, dataNames)
            % Construct an sftoolgui.Data object using values and names if supplied.
            %
            % DATA()
            % Creates a default Data object
            % DATA(DATAVALUES)
            % Creates a Data object using the values and default names,
            % which will be chosen so as not to clash with the names of any
            % variables currently in the MATLAB base workspace.
            % DATAVALUES is empty or a (1, 3) or (1, 4) cell array of
            % values
            % DATA(DATAVALUES, DATANAMES)
            % Creates a Data object using the values and names
            % DATANAMES is empty or a (1, 3) or (1, 4) cell array of
            % variable names. If empty, default names will be assigned.
            
            if nargin < 1
                dataValues = {};
            end
            if nargin < 2
                dataNames = {};
            end
            
            if ~iIsValidArgInSize(dataValues)
                error(message('curvefit:Data:InvalidDataValues'));
            end
            
            if ~iIsValidArgInSize(dataNames)
                error(message('curvefit:Data:InvalidDataNames'));
            end
            
            if isempty(dataValues)
                createDefaultVariables(this);
            else
                setVariables(this, dataValues, dataNames);
                this.Name = createDataName(this);
            end
        end
        
        function tf = isAnyDataSpecified(this)
            tf = this.X.Specified || this.Y.Specified || ...
                this.Z.Specified || this.W.Specified;
        end
        
        function  [x, y, z, w] = getValues(this)
            % getValues returns all Data values. If x, y and z are all
            % specified and all specified data (including w) have the same
            % number of elements, NaN, Inf and imaginary parts of complex data
            % are removed. Whenever a NaN or Inf is detected, the corresponding
            % indices are removed from all the data.
            
            [x, y, z, w] = getMeshedValues(this);
            
            if isSurfaceDataSpecified(this) && areNumSpecifiedElementsEqual(this)
                
                % Remove imaginary part of complex data
                if ~isreal( x )
                    x = real( x );
                end
                if ~isreal( y )
                    y = real( y );
                end
                if ~isreal( z )
                    z = real( z );
                end
                if ~isreal( w )
                    w = real( w );
                end
                
                % Get finite indices
                xFiniteIndices = isfinite(x);
                yFiniteIndices = isfinite(y);
                zFiniteIndices = isfinite(z);
                
                finiteIndices = xFiniteIndices & yFiniteIndices & zFiniteIndices;
                
                if this.W.Specified
                    wFiniteIndices = isfinite(w);
                    finiteIndices = finiteIndices & wFiniteIndices;
                    if any(finiteIndices)
                        w = w(finiteIndices);
                    end
                end
                
                % Remove NaNs and Inf from data
                if any(~finiteIndices)
                    x = x(finiteIndices);
                    y = y(finiteIndices);
                    z = z(finiteIndices);
                end
            end
        end
        
        function  [x, y, w] = getCurveValues(this)
            % getCurveValues returns all specified Data values. If x and y,
            % but not z is specified, and x, y and w (if specified) all
            % have the same number of elements, NaN, Inf and imaginary
            % parts of complex data are removed. Whenever a NaN or Inf is
            % detected, the corresponding indices are removed from all the
            % data.
            
            [x, y, ~, w] = getRawValues(this);
            
            if isCurveDataSpecified(this) && areNumSpecifiedElementsEqual(this)
                
                % Create x data if it is not specified
                if ~this.X.Specified
                    x = (1:length(y))';
                end
                
                % Remove imaginary part of complex data
                if ~isreal( x )
                    x = real( x );
                end
                if ~isreal( y )
                    y = real( y );
                end
                
                if ~isreal( w )
                    w = real( w );
                end
                
                % Get finite indices
                xFiniteIndices = isfinite(x);
                yFiniteIndices = isfinite(y);
                
                finiteIndices = xFiniteIndices & yFiniteIndices;
                
                if this.W.Specified
                    wFiniteIndices = isfinite(w);
                    finiteIndices = finiteIndices & wFiniteIndices;
                    if any(finiteIndices)
                        w = w(finiteIndices);
                    end
                end
                
                % Remove NaNs and Inf from data
                if any(~finiteIndices)
                    x = x(finiteIndices);
                    y = y(finiteIndices);
                end
            end
        end
        
        function numSpecifiedElementsEqual = areNumSpecifiedElementsEqual(this)
            % areNumSpecifiedElementsEqual returns true if all specified
            % data have the same number of elements initially or if they do
            % after processing them with meshgrid.
            if isMeshable(this)
                numSpecifiedElementsEqual = true;
            else
                values = {this.X.Values, this.Y.Values, ...
                    this.Z.Values, this.W.Values};
                values = values([this.X.Specified, this.Y.Specified, ...
                    this.Z.Specified, this.W.Specified]);
                
                if isempty(values);
                    numSpecifiedElementsEqual = true;
                else
                    n = cellfun('prodofsize', values);
                    numSpecifiedElementsEqual = all(n==max(n));
                end
            end
        end
        
        function XYZSpecified = isSurfaceDataSpecified (this)
            % isSurfaceDataSpecified returns true if surfaces could be fit
            % to the specified data.
            XYZSpecified = this.X.Specified && this.Y.Specified && this.Z.Specified;
        end
        
        function curveSpecified = isCurveDataSpecified (this)
            % isCurveDataSpecified returns true if curves, but not
            % surfaces, could be fit to the specified data.
            % This is true if both X and Y are specified and Z is not
            % specified or if just Y is specified.
            curveSpecified = this.Y.Specified && ~this.Z.Specified;
        end
        
        function setVariable( this, variable, name, values )
            % setVariable   Set a variable in Data
            %
            % Syntax:
            %   setVariable( data, variable, name, values )
            %
            % Inputs:
            %   data -- the instance of sftoolgui.Data to set the variable in.
            %   variable -- the variable to set. One of 'X', 'Y', 'Z' or 'W'.
            %   name -- the name of the variable. A string.
            %   values -- the values of the variable. Any numeric array.
            if isempty( values )
                this.(variable) = sftoolgui.Variable();
            else
                this.(variable) = sftoolgui.Variable( name, values );
            end
            this.Name = createDataName( this );
        end
        
        function setVariableFromBaseWS(this, dataName, fieldName)
            % setVariableFromBaseWS finds the value of dataName in the base
            % workspace and creates a new sftoolgui.Variable and assigns the
            % variable to this.(fieldName). This method also creates a new data
            % name based on the variable dataName.
            value = iValueFromBase( dataName, this.(fieldName).Values );
            setVariable( this, fieldName, dataName, value );
        end
        
        function newData = copy(this)
            % copy creates a new Data object with the values from this
            % object.
            newData = sftoolgui.Data();
            newData.X = this.X;
            newData.Y = this.Y;
            newData.Z = this.Z;
            newData.W = this.W;
            newData.Name = this.Name;
        end
        
        function [xName, yName, zName, wName] = getNames(this)
            % getNames returns the names of x, y, z and w.
            xName = this.X.Name;
            yName = this.Y.Name;
            zName = this.Z.Name;
            wName = this.W.Name;
        end
        
        function theMessage = get.Message(this)
            % get.Message returns a message based on the data attributes.
            
            % First check for incompatible sizes.
            theMessage = incompatibleSizeMessage(this);
            
            % Don't check for other messages if sizes are incompatible.
            if ~isempty(theMessage)
                return;
            end
            
            % Next check for missing data and don't check for other
            % messages if data is missing.
            if ~(isCurveDataSpecified(this) || isSurfaceDataSpecified(this))
                return;
            end
            
            % Check for meshed swapping, NaNs, Inf, Complex, Size Mismatches
            % and non doubles.
            theMessage = [swappingMeshableVariablesMessage(this) ...
                NaNInfMessage(this) ...
                complexMessage(this) ...
                sizeMismatchMessage(this) ...
                nonDoubleMessage(this)];
        end
        
        function msg = getMessageString(this)
            % getMessageString creates a single string from all the
            % String fields of the Message property which is an array of
            % message structures.
            % The String fields are xlated.
            msg = '';
            if ~isempty(this.Message)
                for i = 1 : length(this.Message)
                    msg = sprintf( '%s%s\n', msg, this.Message(i).String);
                end
            end
        end
        
        function level = getMessageLevel(this)
            % getMessageLevel returns the most "important" level found in
            % the level fields of the Message property, which is an array
            % of message structures.
            %
            % The order of levels follows listed with most important one
            % first:
            %
            % ERROR INCOMPLETE WARNING GOOD
            %
            % Note: "INCOMPLETE" is higher than "WARNING" since a fit can
            % be computed if there is a warning, but not when data is
            % incomplete.
            
            if isempty(this.Message)
                level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.GOOD;
                return;
            end
            
            if iHasLevel(com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR, this.Message);
                level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR;
                return;
            end
            if iHasLevel(com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE, this.Message);
                level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
                return;
            end
            if iHasLevel(com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING, this.Message);
                level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
                return;
            end
            % must be good
            level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.GOOD;
        end
        
        function set.Version(this, version)
            % set.Version was created so that load would create a struct
            % for objects whose version number is less than 3.
            currentVersion = 3;
            if (version >= currentVersion)
                this.Version = version;
            else
                error(message('sftoolgui:IncompatibleVersion', currentVersion - 1));
            end
        end
        
        function set.X(this, newValue)
            % set.X was created so that load would create a struct if X is
            % not an sftoolgui.Variable
            iAssertVariable(newValue, 'X');
            
            oldValue = this.X;
            this.X = newValue;
            notifyIfNecessary(this, oldValue, newValue);
        end
        
        function set.Y(this, newValue)
            % set.Y was created so that load would create a struct if Y is
            % not an sftoolgui.Variable
            iAssertVariable(newValue, 'Y');

            oldValue = this.Y;
            this.Y = newValue;
            notifyIfNecessary(this, oldValue, newValue);
        end
        
        function set.Z(this, newValue)
            % set.Z was created so that load would create a struct if Z is
            % not an sftoolgui.Variable
            iAssertVariable(newValue, 'Z');

            oldValue = this.Z;
            this.Z = newValue;
            notifyIfNecessary(this, oldValue, newValue);
        end
        
        function set.W(this, data)
            % set.W was created so that load would create a struct if W is
            % not an sftoolgui.Variable
            iAssertVariable(data, 'W');
            this.W = data;
        end
        
    end
    
    methods(Static)
        function obj = loadobj(data)
            % sftoolgui.Data Version 3 allows all numeric data whose number
            % of elements is greater than 1.
            if isstruct(data) && ~isfield(data, 'Version')
                % Pre-Version 1 objects.  Adding this field makes later
                % by-version checks easier to do
                data.Version = 0;
            end
            
            obj = sftoolgui.Data();
            
            initDataFromOldObject(obj, data, 'X');
            initDataFromOldObject(obj, data, 'Y');
            initDataFromOldObject(obj, data, 'Z');
            initDataFromOldObject(obj, data, 'W');
            
            obj.Name = createDataName(obj);
        end
    end
    
    methods(Access = 'private')
        function notifyIfNecessary(this, oldValue, newValue)
            % This method checks to see whether the data listeners need to
            % be informed of the most recent change to X, Y or Z
            if newValue.Specified ~= oldValue.Specified
                notify(this, 'DimensionChanged');
            end
        end
        
        function meshable = isMeshable(this)
            % isMeshable returns true if X and Y are vectors, Z is a 2D
            % matrix and either of the following 2 cases is true:
            %
            % 1) The number of elements in X is the same as the number of
            % columns in Z and the number of elements in Y is the same as
            % the number of rows in Z.
            %
            % 2) The number of elements in X is the same number of rows in
            % Z and the number of elements in Y is the same as the number
            % of columns in Z.
            %
            % If Weights are specified, they must have the same number of
            % elements as Z.
            
            meshable = (iIsXYZMeshable( this.X, this.Y, this.Z ) || ...
                iIsXYZMeshable( this.Y, this.X, this.Z ));
            if meshable && this.W.Specified
                meshable = iIsZWSameNumel(this);
            end
        end
        
        function hasMeshPotential = isPotentiallyMeshable(this)
            % isPotentiallyMeshable returns true if selected data has the
            % potential to be meshable.
            
            % Assign variables for easier reading.
            x = this.X.Specified;
            y = this.Y.Specified;
            z = this.Z.Specified;
            w = this.W.Specified;
            
            % In comments below, "-" indicates that the variable is not
            % specified, for instance, "x-z-" indicates x and z are
            % specified, y and w are not.
            
            if ~x && ~y && ~z && ~w       % No data specified;
                hasMeshPotential = true;
                
            elseif nnz([x, y, z, w]) == 1 % Only one variable is specified
                hasMeshPotential = true;
                
            elseif x && y && ~z && ~w     % xy--
                hasMeshPotential = iIsVector(this.X) && iIsVector(this.Y);
                
            elseif x && ~y && z && ~w     % x-z-
                hasMeshPotential = iIsVZMeshable(this.X, this.Z);
                
            elseif x && ~y && ~z && w     % x--w
                hasMeshPotential = iIsVWMeshable(this.X, this.W);
                
            elseif ~x && y && z && ~w     % -yz-
                hasMeshPotential = iIsVZMeshable(this.Y, this.Z);
                
            elseif ~x && y && ~z && w     % -y-w
                hasMeshPotential = iIsVWMeshable(this.Y, this.W);
                
            elseif ~x && ~y && z && w     % --zw
                hasMeshPotential = iIsZWSameNumel(this);
                
            elseif x && y && z && ~w      % xyz-
                hasMeshPotential = isMeshable(this);
                
            elseif x && y && ~z && w      % xy-w
                hasMeshPotential = iIsVWMeshable(this.X, this.W) && iIsVWMeshable(this.Y, this.W);
                
            elseif x && ~y && z && w      % x-zw
                hasMeshPotential = iIsVZMeshable(this.X, this.Z) && ...
                    iIsZWSameNumel(this);
                
            elseif ~x && y && z && w      % -yzw
                hasMeshPotential = iIsVZMeshable(this.Y, this.Z) && ...
                    iIsZWSameNumel(this);
                
            else                          % xyzw
                hasMeshPotential = isMeshable(this);
                
            end
        end
        
        function tf = iIsZWSameNumel(this)
            % iIsZWSameNumel return true if the number of elements in the Z
            % variable equals the number of elements in the W variable.
            tf = numel(this.Z.Values) == numel(this.W.Values);
        end
        
        function setVariables(this, dataValues, dataNames)
            % setVariables   Set all variable in Data
            %
            % Syntax:
            %   setVariables( data, values, names )
            %
            % Inputs
            %   data -- the instance of sftoolgui.Data to set the variable in.
            %   names -- the names of the variable. A cell-string. The whole string or
            %       individual elements of the cell-string can be empty
            %   values -- the values of the variable. A cell array of numeric arrays.
            %
            % Valid lengths of 'names' and 'values' are 3 and 4. If the length is 3, then
            % weights are not specified.
            
            FIELDS = {'X', 'Y', 'Z', 'W'};
            DEFAULT_NAMES = {'x', 'y', 'z', 'w'};
            
            for i = 1:length( dataValues )
                if isempty(dataNames) || isempty(dataNames{i})
                    name = iGetUniqueVarName(DEFAULT_NAMES{i});
                else
                    name = dataNames{i};
                end
                this.setVariable( FIELDS{i}, name, dataValues{i} );
            end
            
            % If weights were not specified, create an empty Variable
            if length(dataValues) == 3
                this.W = sftoolgui.Variable();
            end
        end
        
        function createDefaultVariables(this)
            % createDefaultVariables create default sftoolgui.Variables
            this.X = sftoolgui.Variable();
            this.Y = sftoolgui.Variable();
            this.Z = sftoolgui.Variable();
            this.W = sftoolgui.Variable();
        end
        
        function [x, y, z, w] = getRawValues(this)
            % getRawValues returns the Values of x, y, z and w.
            
            % Get values
            x = this.X.Values;
            y = this.Y.Values;
            z = this.Z.Values;
            w = this.W.Values;
        end
        
        function [x, y, z, w] = getMeshedValues(this)
            % getMeshedValues returns either "raw" Variable values or
            % "meshed" values if sizes are "meshgrid" compatible.
            [x, y, z, w] = getRawValues(this);
            
            if iIsXYZMeshable( this.X, this.Y, this.Z )
                [x, y] = meshgrid(x, y);
            elseif iIsXYZMeshable( this.Y, this.X, this.Z )
                [y, x] = meshgrid(y, x);
            end
            % ensure column vectors
            x = x(:);
            y = y(:);
        end
        
        function initDataFromOldObject(obj, data, field)
            % initDataFromOldObject sets obj.(field) data in a version
            % independent way.
            if isstruct(data)
                if data.Version<3
                    % Construct a new variable from the old data as long as
                    % the old name was not '(none)'.
                    if ~strcmp(data.([field 'Name']), ...
                            iGetNoneString())
                        obj.(field) = sftoolgui.Variable(data.([field 'Name']), data.(field));
                    end
                else
                    % Version 3 structs should already have Variable
                    % objects
                    obj.(field) = data.(field);
                end
            else
                obj.(field) = data.(field);
            end
        end
        
        function messageStruct = incompatibleSizeMessage(this)
            % incompatibleSizeMessage returns a messageStruct, which has
            % two fields: "String" and "Level". If data do not have the
            % same number of elements, are not "meshable" or are not
            % "potentially meshable", String will have an "incompatible
            % size" message and Level will be "ERROR". If the data are
            % potentially meshable, messageStruct will be an array of
            % structs. The first String will have information about current
            % data sizes. The second String will have required data sizes
            % for meshable data. The Level for both with be INCOMPLETE.
            
            if areNumSpecifiedElementsEqual( this )
                % then sizes are compatible and we don't need a message
                messageStruct = [];
            elseif isPotentiallyMeshable( this )
                if isCurveDataSpecified( this )
                    % then the data specified is for curves, but is
                    % invalid (since num elements are not equal) but might
                    % be valid for surface data (since it is potentially
                    % meshable).
                    
                    % First get the incompatible message.
                    incompatibleMessage = iIncompatibleCurveDataMessage(this);
                    
                    % Then get the proper "compatible if" message which
                    % depends on whether or not X is specified:
                    if this.X.Specified
                        compatibleIfMessage = iCompatibleZMessage(this);
                    else
                        compatibleIfMessage = iCompatibleXZMessage(this);
                    end
                    messageStruct = [incompatibleMessage, compatibleIfMessage];
                else
                    % surface data that is potentially meshable doesn't
                    % need a message
                    messageStruct = [];
                end
            else
                % sizes are not equal and data is not potentially meshable
                messageStruct.String = getString(message('curvefit:sftoolgui:DataSizesAreIncompatible'));
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR;
            end
        end
        
        function messageStruct = NaNInfMessage(this)
            % NanInfMessage returns a messageStruct, which has two fields:
            % "String" and "Level". If there are NaNs or Inf in the data,
            % String will contain information about ignoring them and Level
            % will be "WARNING".
            [x, y, z, w] = getRawValues(this);
            
            % Check data for NaNs and Inf.
            hasNaN = any(isnan(x)) || any(isnan(y)) || any(isnan(z)) || any(isnan(w));
            hasInf = any(isinf(x)) || any(isinf(y)) || any(isinf(z)) || any(isinf(w));
            str = '';
            if hasNaN && hasInf
                str = getString(message('curvefit:sftoolgui:IgnoringInfAndNaNsInData'));
            elseif hasNaN
                str = getString(message('curvefit:sftoolgui:IgnoringNaNsInData'));
            elseif hasInf
                str = getString(message('curvefit:sftoolgui:IgnoringInfInData'));
            end
            
            messageStruct = [];
            if ~isempty(str)
                messageStruct.String = str;
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
            end
        end
        
        function messageStruct = complexMessage(this)
            % complexMessage returns a messageStruct, which has two fields:
            % "String" and "Level". If data contains complex values, String
            % will contain information about using only the real component of
            % them and Level will be "WARNING".
            [x, y, z, w] = getRawValues(this);
            messageStruct = [];
            if ~isreal( x ) || ~isreal( y ) || ~isreal( z ) || ~isreal( w )
                messageStruct.String = getString(message('curvefit:sftoolgui:UsingOnlyTheRealComponentOfComplexData'));
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
            end
        end
        
        function messageStruct = swappingMeshableVariablesMessage(this)
            % swappingMeshableVariablesMessage returns a messageStruct,
            % which has two fields: "String" and "Level". If X, Y and Z are
            % meshable but the numel(X) ~= number of Z columns, String will
            % contain information about X and Y usage and Level will be
            % "WARNING".
            
            messageStruct = [];
            % Check numel of x and y. If they are equal, iIsXYZMeshable
            % will be true, but we don't want to display the message in
            % that case.
            if iIsXYZMeshable( this.Y, this.X, this.Z )  && ...
                    numel(this.Y.Values) ~= numel(this.X.Values)
                messageStruct.String = ...
                    getString(message('curvefit:sftoolgui:UsingXDataForRowsAndYDataForColumnsToMatchZDataMatri'));
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
            end
        end
        
        function messageStruct = sizeMismatchMessage(this)
            % sizeMismatchMessage returns a messageStruct, which has two
            % fields: "String" and "Level". If data sizes are different
            % String will reflect that fact and Level will be "WARNING".
            % The actual string will vary depending on whether or not the
            % data is meshable.
            %
            % Note: we know that the sizes are compatible at this point.
            %
            % If all Variables are vectors, we will not warn.
            
            if isMeshable(this)
                messageString = getMeshableMismatchMessage(this);
            else
                messageString = getStandardMismatchMessage(this);
            end
            
            messageStruct = [];
            if ~isempty(messageString)
                messageStruct.String = messageString;
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
            end
        end
        
        function messageString = getMeshableMismatchMessage(this)
            % getMeshableMismatchMessage returns information about Weights
            % and Z data mismatched sizes when data is meshable.
            messageString = '';
            if this.W.Specified && ~isequal( this.Z.Size, this.W.Size )
                sizesDoNotMatchMessage = ...
                    getString(message('curvefit:sftoolgui:WeightsAndZSizesDoNotMatch'));
                convertingDataMessage = ...
                    getString(message('curvefit:sftoolgui:ConvertingWeightsAndZToColumnVectors'));
                messageString = sprintf( '%s%s%s\n%s', ...
                    sizesDoNotMatchMessage, ...
                    iSizeMessage(this.Z, getString(message('curvefit:sftoolgui:ZData'))), ...
                    iSizeMessage(this.W, getString(message('curvefit:sftoolgui:Weights'))), ...
                    convertingDataMessage);
            end
        end
        
        function messageString = getStandardMismatchMessage(this)
            % getStandardMismatchMessage returns information about variable
            % sizes if they do not match and they are not meshable.
            messageString = '';
            
            if isCurveDataSpecified(this)
                if this.X.Specified
                    areAllVectors = iIsVector( this.X ) && iIsVector( this.Y );
                    areAllTheSameSize = isequal( this.X.Size, this.Y.Size);
                else % only Y is specified
                    areAllVectors = iIsVector( this.Y );
                    areAllTheSameSize = true;
                end
            elseif isSurfaceDataSpecified(this)
                areAllVectors = iIsVector( this.X ) && iIsVector( this.Y )...
                    && iIsVector( this.Z );
                areAllTheSameSize = isequal( this.X.Size, this.Y.Size, ...
                    this.Z.Size );
            else
                areAllVectors = false;
                areAllTheSameSize = false;
                warning(message('curvefit:Data:getStandardMismatchMessage:InvalidState'));
            end
            
            if this.W.Specified
                areAllVectors = areAllVectors && iIsVector( this.W );
                areAllTheSameSize = areAllTheSameSize && ...
                    isequal( this.X.Size, this.W.Size );
            end
            
            if ~areAllVectors && ~areAllTheSameSize
                sizesDoNotMatchMessage = getString(message('curvefit:sftoolgui:DataSizesDoNotMatch'));
                convertingDataMessage = ...
                    getString(message('curvefit:sftoolgui:ConvertingAllDataToColumnVectors'));
                messageString = sprintf( '%s%s%s%s%s\n%s', ...
                    sizesDoNotMatchMessage, ...
                    iSizeMessage(this.X, getString(message('curvefit:sftoolgui:XData'))), ...
                    iSizeMessage(this.Y, getString(message('curvefit:sftoolgui:YData'))), ...
                    iSizeMessage(this.Z, getString(message('curvefit:sftoolgui:ZData'))), ...
                    iSizeMessage(this.W, getString(message('curvefit:sftoolgui:Weights'))), ...
                    convertingDataMessage);
            end
        end
        
        function messageStruct = nonDoubleMessage(this)
            % nonDoubleMessage returns a messageStruct, which has two fields:
            % "String" and "Level". If data contains non-double, String will
            % contain information about converting them and Level will be
            % "WARNING".
            
            messageStruct = [];
            if ~this.X.IsDouble() ||  ~this.Y.IsDouble() ||  ~this.Z.IsDouble() || ~this.W.IsDouble()
                messageStruct.String = getString(message('curvefit:sftoolgui:ConvertingNondoubleValuesToDoubleValues'));
                messageStruct.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
            end
        end
    end
end

function theMessage = iIncompatibleCurveDataMessage(this)
% iDataIncompatibleMessage returns a message struct with two fields:
% String and Level. String contains the message that data are incompatible
% for curves as well the sizes of all specified data. (Z is not included
% for potential size information because if Z is specified, this could not
% be curve data.) Level is INCOMPLETE.
incompatibleMessage = getString(message('curvefit:sftoolgui:DataAreIncompatibleForCurves'));
theMessage.String = sprintf( '%s%s%s%s', ...
    incompatibleMessage, ...
    iSizeMessage(this.X, getString(message('curvefit:sftoolgui:XData'))), ...
    iSizeMessage(this.Y, getString(message('curvefit:sftoolgui:YData'))), ...
    iSizeMessage(this.W, getString(message('curvefit:sftoolgui:Weights'))));
theMessage.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
end

function theMessage = iCompatibleXZMessage(this)
% iCompatibleXZMessage returns a message struct with two fields: String and
% Level. String contains a message stating what sizes X and Z would need to
% be to compatible with the data that has already been specified. Level is
% INCOMPLETE.
theMessage.String = getString(message('curvefit:sftoolgui:DataAreCompatibleForSurfaceFittingIfXIsAndZIs', ...
    iSizeString([ numel(this.W.Values)/numel(this.Y.Values), 1] ), ...
    iSizeString([numel(this.Y.Values), numel(this.W.Values)/numel(this.Y.Values)] )));
theMessage.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
end

function theMessage = iCompatibleZMessage(this)
% iCompatibleZMessage returns a message struct with two fields: String and
% Level. String contains a message stating what size Z would need to be to
% compatible with the data that has already been specified. Level is
% INCOMPLETE.
theMessage.String = getString(message('curvefit:sftoolgui:DataAreCompatibleForSurfacesIfZIs', ...
    iSizeString([numel(this.Y.Values), numel(this.X.Values)])));
theMessage.Level = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
end

function v = iValueFromBase( name, oldValue )
% iValueFromBase   Returns a value from the base workspace for the given
% name.
if isempty(name)
    v = [];
else
    % names might not correspond to matlab variables if user entered
    % data, so return original value.
    try
        v = evalin('base', name);
    catch me %#ok<NASGU>
        v = oldValue;
    end
end
end

% function  isDouble = iIsDouble(variable)
% % iIsDouble returns true if the variable is a double.
% isDouble = strcmp(variable.Class, 'double');
% end

function isValid = iIsValidArgInSize(arg)
% iIsValidArgInSize returns true arg is empty, or a cell array of size:
% (1,3), (1,4), (3,1), or (4,1).
isValid = false;
if isempty(arg)
    isValid = true;
elseif iscell(arg) && isvector(arg) && ...
        (length(arg) == 3 || length(arg) == 4)
    isValid = true;
end
end

function name = iGetUniqueVarName(baseName)
% iGetUniqueVarName determines whether or not baseName already exists in
% the base workspace. If so, it finds a suffix to add to make the name
% unique.
if ~varExistsInBase(baseName)
    name = baseName;
else
    i = 1;
    taken = 1;
    while taken
        name = sprintf('%s%i', baseName, i);
        if varExistsInBase(name)
            i = i+1;
        else
            taken = 0;
        end
    end
end
end

function varExists = varExistsInBase(varName)
% varExistsInBase returns true if varName is in the base workspace.
varExists = evalin('base', ['exist(''', varName, ''', ''var'')']);
end

function dataName = createDataName(this)
% createDataName returns a data name based on selected variable names.
[xName, yName, zName, wName] = getNames(this);

if isempty(zName)
    dataName = iMakeName({xName}, yName);
else
    dataName = iMakeName({xName, yName}, zName);
end

if ~isempty(wName)
    % Append "with w" to the name
    if ~isempty(dataName)
        dataName = [dataName ' with ' wName];
    else
        dataName = wName;
    end
end

end

function name = iMakeName(inNames, outName)
% iMakeName constructs a name based on input and output variables
% Make comma separated list of all inputNames
inNames = inNames(~cellfun('isempty', inNames));
inStr = sprintf('%s, ', inNames{:});
% Strip off last ', '
inStr = inStr(1:end-2);

if isempty( outName )
    name = inStr;
elseif isempty( inStr );
    name = outName;
else % both inStr and outStr are not empty
    % so make then name from both of them
    name = [outName ' vs. ' inStr];
end
end

function level = iHasLevel(level, messages)
% hasLevel returns true if the LEVEL is in any of the MESSAGES Level fields.
% Otherwise, the return value is false.
level = any(cellfun(@(x) x == level, cell([messages.Level])));
end

function iAssertVariable(data, field)
% iAssertVariable    Throw an error if |data| is not an sftoolgui.Variable.

if ~isa(data, 'sftoolgui.Variable')
    error(message('curvefit:Data:InvalidData', field));
end
end

function dataIsVector = iIsVector(variable)
% iIsVector returns true if the variable is a vector.
sz = variable.Size;
dataIsVector = (length(sz) == 2) && (sz(1) == 1 || sz(2) == 1);
end

function theMessage = iSizeMessage(variable, identifier)
% iSizeMessage returns a message indicating the size of the variable. If
% the variable is not specified, the message is empty.
theMessage = '';
if variable.Specified
    sz = variable.Size;
    name = variable.Name;
    if length(name) > 24
        name = [name(1:21) '...'];
    end
    indent = '    ';
    theMessage = sprintf('\n%s%s: %s is %s', indent, identifier, name, iSizeString(sz));
end
end

function sizeString = iSizeString(sz)
% iSizeString returns a string representation of the size.
sizeString = sprintf('%d', sz(1));
nDimensions = length(sz);
for i = 2:nDimensions
    sizeString = sprintf('%sx%d', sizeString, sz(i));
end
end

function tf = iIsXYZMeshable( x, y, z )
% iIsXYZMeshable returns true if sizes of x, y and z are such that they can
% be used with the meshgrid function.
tf = iIsVector( x ) && iIsVector( y ) && length(z.Size) == 2 && ...
    (numel(x.Values) == z.Size(2) && ...
    numel(y.Values) == z.Size(1));
end

function tf = iIsVZMeshable(v, z)
% iIsVZMeshable returns true if v is a Vector, z is a 2D matrix and the
% length of v equals the number or columns or the number of rows as z
tf = iIsVector( v ) && length(z.Size) == 2 && ...
    (numel(v.Values) == z.Size(1) ||  numel(v.Values) == z.Size(2));
end

function tf = iIsVWMeshable(v, w)
% iIsVWMeshable returns true if v is a Vector and the number of elements of
% w is a multiple of the number of elements of v.
tf = iIsVector( v ) && rem(numel(w.Values), numel(v.Values)) == 0;
end

function s = iGetNoneString
% iGetNoneString Returns the string "none" subject to translation
s = '(none)';
end
