classdef Fitdev < curvefit.Handle & curvefit.ListenerTarget
    % Fitdev Surface Fitting Tool Fit Developer
    
    %   Copyright 2008-2014 The MathWorks, Inc.
    
    events
        % FittingDataUpdated   Fired when fitting data is changed.
        FittingDataUpdated
        
        % ValidationDataUpdated   Fired when validation data is changed.
        ValidationDataUpdated
        
        % FittingStarted   Fired when fitting is started.
        %
        % A FittingStarted event is called just before a call to the FIT function.
        FittingStarted
        
        % FitCreated   Fired when a fit has been created.
        %
        % Once a fit has been created, fitting cannot be interrupted. However a fit is
        % not available for access by views until a FitUpdated event has been
        % fired.
        FitCreated
        
        % FitUpdated   Fired when the fit is changed.
        %
        % A FitUpdated event is fired after fitting when the Fit and associated
        % properties are changed. Associated properties include FitState, GoodnessOfFit
        % and ValidationGoodness.
        FitUpdated
        
        % FittingCompleted   Fired when fitting is completed.
        %
        % A FittingCompleted event is fired when all fitting has been completed and after
        % other fitting events such as FitCreated and FitUpdated.
        FittingCompleted
        
        % FitNameUpdated   Fired when the name of the fit is changed
        FitNameUpdated
        
        % CoefficientOptionsUpdated   Fired when start points, lower or upper
        % coefficients bounds change.
        CoefficientOptionsUpdated
        
        % FitTypeFitValuesUpdated   Fired when a value that would require a refit
        % changes. These include:
        %   - data (both new data and new exclusions to current data)
        %   - fit options
        %   - fittype
        FitTypeFitValuesUpdated
        
        % FitdevChanged   Fired whenever Fitdev is changed.
        %
        % This event is designed to assist with tracking session changes. It is expected
        % that not much action takes place in response to the FitdevChanged event as it
        % is sent frequently.
        FitdevChanged
        
        % ExclusionsUpdated   Fired when list of excluded points change
        ExclusionsUpdated
        
        % DimensionChanged   Fired when the Fitdev changes between curve and surface
        DimensionChanged
    end
    
    properties(Access = private)
        % Version - class version number
        Version = 6;
        
        % The specifications are used to create the definitions.  They
        % represent what the user has asked to try and fit.  It may not be
        % possible to generate a definition from a specification.
        PrivateCurveSpecification ;
        PrivateSurfaceSpecification ;
        
        % PrivateFitName   Private storage for public property 'FitName'
        PrivateFitName ;
        
        % ExclusionsStore - storage for exclusions. Empty implies all false.
        ExclusionsStore = [] ;
    end
    
    properties(Access = private, Transient)
        DimensionChangedListener ;
        
        % ExclusionRuleListener   This transient property contains the
        % listener which will fire when the ExclusionRules are changed
        ExclusionRulesListener
    end
    
    properties(SetAccess = private)
        % ExclusionRules   (sftoolgui.exclusion.ExclusionCollection) The
        % exclusion rules which represent the excluded areas of the data
        ExclusionRules ;
    end
    
    properties(SetAccess = private, Dependent)
        % CurrentSpecification   
        CurrentSpecification ;
    
        % ExclusionsByRule   A dependent properties which will return a
        % logical array representing the data points which are currently
        % excluded by the user's set of ExclusionRules
        ExclusionsByRule ;

        % ResultsTxt 
        ResultsTxt ;
        
        % FitTypeString
        FitTypeString;
    
        % HasExclusions   True if the fitdev has any exclusions, either points excluded
        % by rule or enabled exclusion rules
        HasExclusions;
    end
    
    properties
        AutoFitEnabled = true;
        FitID ;
        Fit ;
        Goodness ;
        ValidationGoodness ;
        Output ;
        FittingData ;
        ValidationData ;
        WarningStr ;
        ErrorStr ;
        ConvergenceStr ;
        FitState ;   % SFUtilities enum FitTypeObject: INCOMPLETE GOOD ERROR WARNING
    end
    
    properties(Dependent)
        % Exclusions (logical array)
        Exclusions ;
        
        % FitName   (char array)
        FitName ;

        CurveSpecification ;
        SurfaceSpecification ;
    end
    
    properties(Hidden, Dependent)
        % The following properties are here for compatibility and
        % convenience. They should not be used going forward. Instead, use
        % CurrentSpecification.Fittype and CurrentSpecification.FitOptions
        FitTypeObject ;
        FitOptions ;
    end
    
    properties(Transient)
        % CHECKFITNAMEFCN(NAME, THIS) should return empty if the NAME is a
        % valid fit name. Otherwise, it must return a struct with the
        % following fields: 'identifier', 'message'.
        CheckFitNameFcn ;
    end
    
    methods
        function this = Fitdev(name, id, sftoolguiData)
            % FITDEV Constructor for the Surface Fitting Tool Fit Developer
            %
            %   this = FITDEV(NAME, ID, SFTOOLGUIDATA)
            this.setDefaultValues();

            this.FitName = name;
            this.FitID = id;
            this.setInitialFittingData(sftoolguiData);
            
            this.fit();
        end
        
        function [xLabel, yLabel, zLabel] = getDominantLabels(this)
            % getDominantLabels returns x, y and z labels based on selected
            % data.
            
            %   getDominantLabels uses fitting and validation data names to
            %   determine labels. Default labels are returned if neither
            %   fitting nor validation data is selected. Fitting data
            %   names take precedence over validation data names. If both
            %   are selected, fitting data names will be used. (Validation
            %   data names are used only if validation data is selected and
            %   fitting data is not.)
            
            [fxName, fyName, fzName] = getNames(this.FittingData);
            [vxName, vyName, vzName] = getNames(this.ValidationData);
            
            xLabel = iGetDominantLabel(fxName, vxName, 'X');
            yLabel = iGetDominantLabel(fyName, vyName, 'Y');
            zLabel = iGetDominantLabel(fzName, vzName, 'Z');
        end
        
        function tf = isAnyDataSpecified(this)
            % isAnyDataSpecified returns true if any data (fitting or validation)
            % is specified.
            
            tf = isAnyDataSpecified( this.FittingData ) || ...
                isAnyDataSpecified( this.ValidationData );
        end
        
        function [resids, vResids] = getResiduals(this)
            % getResiduals gets residuals and validation data residuals for
            % either curve or surface data.
            fitObject = this.Fit;
            
            resids = [];
            vResids = [];
            
            if ~isempty(fitObject)
                resids = iResiduals( fitObject, this.FittingData );
                if isValidationDataValid(this)
                    vResids = iResiduals( fitObject, this.ValidationData );
                end
            end
        end
        
        function name = get.FitName(this)
            name = this.PrivateFitName;
        end
        
        function set.FitName(this, name)
            this.checkFitName(name);
            this.PrivateFitName = name;
            this.ExclusionRules.Name = name; 
            notify(this, 'FitNameUpdated', sftoolgui.FitEventData(this));
        end        
        
        function set.FittingData(this, fittingData)
            this.FittingData = fittingData;
            delete(this.DimensionChangedListener); %#ok<MCSUP>
            this.DimensionChangedListener = this.createListener(this.FittingData, 'DimensionChanged', @(src, evt)notify(this, 'DimensionChanged') ); %#ok<MCSUP>
        end
        
        function set.CurveSpecification(this, specification)
            this.PrivateCurveSpecification = specification;
            
            if isCurve(this)
                updateFittype(this, specification);
            end
        end
        
        function specification = get.CurveSpecification(this)
            specification = this.PrivateCurveSpecification;
        end
        
        function set.SurfaceSpecification(this, specification)
            this.PrivateSurfaceSpecification = specification;
            
            if ~isCurve(this)
                updateFittype(this, specification);
            end
            
        end
        
        function specification = get.SurfaceSpecification(this)
            specification = this.PrivateSurfaceSpecification;
        end
        
        function specification = get.CurrentSpecification(this)
            if isCurve(this)
                specification = this.PrivateCurveSpecification;
            else
                specification = this.PrivateSurfaceSpecification;
            end
        end
        
        function tf = isCurve(this)
            % Return true if Curve is the current specification, false
            % otherwise.
            tf = isCurveDataSpecified( this.FittingData );
        end
        
        function fittypeString = get.FitTypeString( this )
            fittypeString = this.CurrentSpecification.FittypeString;
        end
        
        function clearExclusions(this)
            this.Exclusions = iInitializeExclusionArray(this.FittingData);
        end
        
        function toggleExclusion(this, index)
            this.Exclusions(index) = ~this.Exclusions(index);
        end
        
        function setFittingData( this, values, names )
            % setFittingData   Set fitting data for a Fitdev
            %
            % Syntax:
            %   setFittingData( aFitdev, values, names )
            %
            % Inputs:
            %   aFitdev -- the Fitdev that is getting new fitting data.
            %   values -- the values of the fitting data. A cell array with four elements,
            %       one for each of X, Y, Z and W. Elements of the cell array are any numeric
            %       vector. Use an empty, [], to set a variable to 'none'.
            %   names -- the names of the variables. A cell-string with four elements. Empty
            %      names are allowed where the corresponding values are empty.
            %
            % Note that all four elements of values and names must be supplied.
            VARIABLES = 'XYZW';
            for i = 1:length( VARIABLES )
                setVariable( this.FittingData, VARIABLES(i), names{i}, values{i} );
            end
            doFittingDataUpdatedActions( this );
        end
        
        function updateFittingData(this, evt)
            setVariableFromBaseWS(this.FittingData, char(evt.getDataName), char(evt.getFieldName));
            doFittingDataUpdatedActions(this);
        end
        
        function clearFit(this)
            this.Fit = [];
            this.Goodness = [];
            this.ValidationGoodness = [];
            this.Output = [];
            this.WarningStr = [];
            this.ConvergenceStr = [];
            % If FitTypeObject is empty, ErrorStr can indicate a Fittype
            % error (generally due to an invalid custom equation). We want
            % to display this if users attempt a fit. Therefore, clear
            % ErrorStr only if FitTypeObject is not empty.
            if ~isempty(this.CurrentSpecification.Fittype)
                this.ErrorStr = [];
                this.FitState = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
            end
        end
        
        function setValidationData( this, values, names )
            % setValidationData   Set validation data for a Fitdev
            %
            % Syntax:
            %   setValidationData( aFitdev, values, names )
            %
            % Inputs:
            %   aFitdev -- the Fitdev that is getting new validation data.
            %   values -- the values of the validation data. A cell array with three elements,
            %       one for each of X, Y, Z. Elements of the cell array are any numeric
            %       vector. Use an empty, [], to set a variable to 'none'.
            %   names -- the names of the variables. A cell-string with three elements. Empty
            %      names are allowed where the corresponding values are empty.
            %
            % Note that all four elements of values and names must be supplied.
            VARIABLES = 'XYZ';
            for i = 1:length( VARIABLES )
                setVariable( this.ValidationData, VARIABLES(i), names{i}, values{i} );
            end
            doValidationDataUpdatedActions( this );
        end
        
        function updateValidationData(this, evt)
            setVariableFromBaseWS(this.ValidationData, char(evt.getDataName), char(evt.getFieldName));
            doValidationDataUpdatedActions(this);
        end
        
        function this = updateDataFromADifferentFit(this, srcFit)
            % Get the new data
            this.ValidationData = copy(srcFit.ValidationData);
            this.FittingData = copy(srcFit.FittingData);
            
            % doFittingDataUpdatedActions must be called before
            % doValidationDataUpdatedActions because
            % doValidationDataUpdatedActions needs information from the
            % fit.
            doFittingDataUpdatedActions(this);
            doValidationDataUpdatedActions(this);
        end
        
        function updateAutoFit(this, state)
            this.AutoFitEnabled = state;
            if this.AutoFitEnabled
                fit(this);
            end
            notify (this, 'FitdevChanged');
        end
        
        function updateCurveFitOptions(this, specification)
            % Update the curve fit with new options.
            this.PrivateCurveSpecification = specification;
            
            if isCurve(this)
                updateFit(this);
            end
        end
        
        function updateSurfaceFitOptions(this, specification)
            % Update the surface fit with new options.
            this.PrivateSurfaceSpecification = specification;
            
            if ~isCurve(this)
                updateFit(this);
            end
        end
        
        function updateFittype(this, specification)
            % updateFittype sets recommended lower bounds and startpoints
            %
            % This function is called by updateSurfaceFittype and
            % updateCurveFittype.  It is here that we decide whether to
            % overwrite the cached start points and lower bounds based on
            % the default fit options provided by 'fitoptions(fittype)'
            
            % Check to see if this function defines recommended lower
            % bounds.  If this is the case, then we ignore the cached
            % values for the lower bounds
            ft = specification.Fittype;
            fopts = specification.FitOptions;
            
            if isempty(ft)
                ft = fittype;
            end
            defaultOpts = fitoptions(ft);
            if isscalar(defaultOpts) && isprop(defaultOpts, 'Lower') && ~isempty(defaultOpts.lower)
                fopts.lower = defaultOpts.lower;
            end
            
            spfun = startpt(ft);
            startPointFunctionIsDefined = ~isempty(spfun);
            % Populate with the correct start points if a function has
            % been defined for this fit, otherwise use cached values
            if isprop(specification.FitOptions, 'StartPoint') && startPointFunctionIsDefined
                specification.FitOptions.StartPoint = generateStartPointsByFunction(this, specification);
            end
            
            % If there are lower bounds, there will also be upper bounds,
            % so check for just lower.
            if isprop(specification.FitOptions, 'StartPoint') || isprop(specification.FitOptions, 'Lower')
                notify (this, 'CoefficientOptionsUpdated', sftoolgui.FitEventData(this));
            end
            
            % Update the custom equation, error string and then update the
            % fit
            this.ErrorStr = specification.ErrorString;
            updateFit(this);
        end
        
        function saveFitToWorkspace(this)
            checkLabels = {getString(message('curvefit:sftoolgui:SaveFitToMATLABObjectNamed')), ...
                getString(message('curvefit:sftoolgui:SaveGoodnessOfFitToMATLABStructNamed')), ...
                getString(message('curvefit:sftoolgui:SaveFitOutputToMATLABStructNamed'))};
            items = {this.Fit, this.Goodness, this.Output};
            varNames = {'fittedmodel', 'goodness', 'output'};
            export2wsdlg(checkLabels, varNames, items, getString(message('curvefit:sftoolgui:SaveFitToMATLABWorkspace')));
        end
        
        function tf = isFittingDataValid(this)
            % isFittingDataValid returns true if fitting data are specified
            % and data have compatible sizes. Otherwise it returns false.
            tf = iIsDataValid(this.FittingData);
        end
        
        function tf = isValidationDataValid(this)
            % isValidationDataValid   True for valid validation data
            %
            % isValidationDataValid returns true if validation data are
            % specified and have compatible sizes. Otherwise it returns
            % false.
            tf = iIsDataValid( this.ValidationData ) && isFittingValidationDataCompatible( this );
        end
        
        function fit( this )
            % fit   Fit model in Fitdev to data in Fitdev
            
            % Do the fit
            notify( this, 'FittingStarted', sftoolgui.FitEventData( this ) );
            [aFit, aGoodness, anOutput, aWarning, anError, aConvergence] = iCallFit( ...
                this.FittingData, this.CurrentSpecification, this.getAllExclusions );
            notify( this, 'FitCreated' );
            
            % Store fit and related information
            this.Fit = aFit;
            this.Goodness = aGoodness;
            this.Output = anOutput;
            this.WarningStr = aWarning;
            
            this.ErrorStr = this.CurrentSpecification.ErrorString;
            if isempty( this.ErrorStr )
                this.ErrorStr = anError;
            end
            this.ConvergenceStr = aConvergence;
            
            % Compute goodness of validation
            if isempty( aFit )
                this.ValidationGoodness = [];
            else
                [this.ValidationGoodness.sse, this.ValidationGoodness.rmse] = getValidationGoodness( this );
            end
            
            % Assign Fit state
            this.FitState = iPostFittingFitState( aFit, this.ErrorStr, aWarning, this.FittingData );
            
            % The fit has been updated so tell the world
            notify( this, 'FitUpdated', sftoolgui.FitEventData( this ) );
            
            % Fitting is now complete ...
            notify( this, 'FittingCompleted' );
            % ... and the Fitdev has changed.
            notify( this, 'FitdevChanged' );
        end
        
        function results = get.ResultsTxt( this )
            if isempty( this.Fit )
                % Empty results?
                results = '';
            else
                fitResults = genresults( ...
                    this.Fit, this.Goodness, this.Output, '', ...
                    this.ErrorStr, this.ConvergenceStr );
                
                validationString = makeValidationString( this );
                
                results = sprintf( '%s\n', fitResults{:}, validationString );
            end
        end
        
        function duplicatedFit = createADuplicate(this, newName)
            duplicatedFitUUID = javaMethodEDT('randomUUID', 'java.util.UUID');
            duplicatedFit = sftoolgui.Fitdev(newName, duplicatedFitUUID, sftoolgui.Data());
            duplicatedFit.AutoFitEnabled = this.AutoFitEnabled;
            duplicatedFit.Fit = this.Fit;
            duplicatedFit.Goodness = this.Goodness;
            duplicatedFit.ValidationGoodness = this.ValidationGoodness;
            duplicatedFit.Output = this.Output;
            duplicatedFit.FittingData = copy(this.FittingData);
            duplicatedFit.ValidationData = copy(this.ValidationData);
            duplicatedFit.WarningStr = this.WarningStr;
            duplicatedFit.ErrorStr = this.ErrorStr;
            duplicatedFit.ConvergenceStr = this.ConvergenceStr;
            duplicatedFit.FitState = this.FitState;
            duplicatedFit.ExclusionsStore = this.ExclusionsStore;
            duplicatedFit.CheckFitNameFcn = this.CheckFitNameFcn;
            duplicatedFit.PrivateSurfaceSpecification = copy(this.PrivateSurfaceSpecification);
            duplicatedFit.PrivateCurveSpecification = copy(this.PrivateCurveSpecification);
            duplicatedFit.ExclusionRules = copy(this.ExclusionRules);
        end
        
        function generateMCode( this, mcode )
            % generateMCode   Generate Code for a Fitdev
            %
            %    generateMCode( H, CODE ) generates code for the given
            %    Fitdev, H, and adds it to the code object CODE.
            
            [canGenerate, messages] = this.canGenerateCodeForFit();
            if canGenerate
                this.doGenerateCode( mcode );
            else
                for i = 1:length( messages )
                    mcode.addFitComment( getString( messages{i} ) );
                end
            end
        end
        
        function [canGenerate, messages] = canGenerateCodeForFit( this )
            % canGenerateCodeForFit   True if code can be generated for this fit
            %
            % If code cannot be generated then a cell-array of messages explaining why are
            % returned.
            INCOMPLETE = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
            
            if this.FitState == INCOMPLETE
                % Cannot generate code for "incomplete" fits
                canGenerate = false;
                messages{1} = message('curvefit:sftoolgui:CannotGenerateCodeForFitBecauseTheDataSelectionIs', this.FitName );
                
            elseif isempty( this.FitTypeObject )
                % We can't generate code where there is no fittype
                canGenerate = false;
                messages{1} = message( 'curvefit:sftoolgui:CannotGenerateCodeForEmptyFittype', this.FitName );
                % If the fittype is a custom equation, then give the user a hint to the source of
                % the problem.
                if isCustomEquation(this.CurrentSpecification)
                    messages{2} = message( 'curvefit:sftoolgui:CheckCustomEquation' );
                end
                
            else
                % The fit is complete therefore and there is a fittype, therefore we can generate
                % code.
                canGenerate = true;
                messages = {};
            end
        end
        
        function bIsFitted = isFitted(this)
            % isFitted returns true if a fitting operation was attempted and did not error.
            bIsFitted = this.FitState == com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.GOOD || ...
                this.FitState == com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;  % good or warning fit
        end
        
        function fitTypeObject = get.FitTypeObject(this)
            % get fittype
            fitTypeObject = this.CurrentSpecification.Fittype;
        end
        
        function fitOptions = get.FitOptions(this)
            % get fit options
            fitOptions = this.CurrentSpecification.FitOptions;
        end
        
        function set.Version(this, version)
            % set.Version was created so that load would create a struct
            % for objects whose version number is less than the current
            % version.
            currentVersion = 6;
            if version >= currentVersion
                this.Version = version;
            else
                error(message('curvefit:sftoolgui:IncompatibleVersion', currentVersion - 1));
            end
        end
        
        function exclusions = get.Exclusions(this)
            if isempty(this.ExclusionsStore)
                exclusions = iInitializeExclusionArray(this.FittingData);
            else
                exclusions = this.ExclusionsStore;
            end
        end
        
        function set.Exclusions(this, exclusions)
            this.ExclusionsStore = exclusions;
            triggerExclusionsChanged(this);
        end
        
        function set.ExclusionRules( this, rules )
            % set.ExclusionRules   Set method for ExclusionRules
            %
            % Inputs
            %   rules   An ExclusionCollection containing the rules which
            %   represent the excluded areas of the data.
            rules.Name = this.PrivateFitName; %#ok<MCSUP>
            this.ExclusionRules = rules;
            this.setupExclusionRuleListener();
        end
        
        function exclusions = get.ExclusionsByRule(this)
            exclusions = this.ExclusionRules.exclude(this.FittingData);
            
            if numel(exclusions) == numel(this.Exclusions)
                exclusions = reshape(exclusions, size(this.Exclusions));
            else
                exclusions = false(size(this.Exclusions));
            end
        end
        
        function tf = get.HasExclusions( this )
            tf = iAnyExclusions( this.Exclusions, this.ExclusionRules );
        end
        
        function exclusions = getAllExclusions(this)
            exclusions = this.ExclusionsByRule | this.Exclusions;
        end
    end
    
    methods(Static)
        function obj = loadobj(this)
            
            % Get the version number.
            if isstruct(this) && ~isfield(this, 'Version')
                version = 0;
            else
                version = this.Version;
            end
            
            % Update THIS
            if version < 2
                this = iUpdateToV2(this);
            end
            
            if version < 3
                this = iUpdateV2ToV3(this);
            end
            
            if version < 4
                this = iUpdateV3ToV4(this);
            end
            
            if version < 5
                this = iUpdateV4ToV5(this);
            end
            
            if version < 6
                this = iUpdateV5ToV6(this);
            end
            
            % Create a new Fitdev object with THIS values
            try
                obj = iCreateLoadedObject(this);
            catch ignore %#ok<NASGU>
                obj = this;
                warning(message('curvefit:sftoolgui:Fitdev:unexpectedLoadedObject'));
            end
        end
    end
    
    methods(Access = private)
        function setDefaultValues(this)
            % setDefaultValues   Set default values for fields that take
            % handle objects.
            this.ValidationData = sftoolgui.Data();
            this.FitState = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;
            
            this.PrivateCurveSpecification = iCreateDefaultCurveSpecification();
            this.PrivateSurfaceSpecification = iCreateDefaultSurfaceSpecification();
            
            this.ExclusionRules = sftoolgui.exclusion.ExclusionCollection();
        end

        function setInitialFittingData(this, sftoolguiData)
            if isa(sftoolguiData, 'sftoolgui.Data')
                this.FittingData = sftoolguiData;
            elseif isempty(sftoolguiData)
                this.FittingData = sftoolgui.Data();
            else
                error(message('curvefit:sftoolgui:Fitdev:InvalidInput'));
            end
        end

        function checkFitName(this,name)
            if isempty(name)
                error(message('curvefit:sftoolgui:Fitdev:emptyFitName'));
            elseif ~ischar(name)
                error(message('curvefit:sftoolgui:Fitdev:NameNotString'));
            elseif ~isempty(this.CheckFitNameFcn)
                error( this.CheckFitNameFcn( name, this ) );
            end
        end

        function updateFit(this)
            % update Fit information that is relevant for both curves and
            % surface.
            % If there is an error ...
            if ~isempty(this.CurrentSpecification.ErrorString)
                % then update the FitState
                this.FitState = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR;
            end
            % call clearFit() after setting FitTypeObject because in
            % clearFit(), ErrorStr is conditionally cleared depending on
            % FitTypeObject state.
            clearFit(this);
            
            % Make sure FitTypeFitValuesUpdated event gets sent before
            % fitting
            notify (this, 'FitTypeFitValuesUpdated', ...
                sftoolgui.FitEventData(this));
            notify (this, 'FitdevChanged');
            if this.AutoFitEnabled
                fit(this);
            end
        end
        
        function doFittingDataUpdatedActions(this)
            % doFittingDataUpdatedActions does tasks required when fitting
            % data has changed.
            clearFit(this);
            
            % Initialize the ExclusionsStore (Don't set this.Exclusions
            % here as that action does either some actions that we do not
            % want in this case or some actions that are redundant.)
            this.ExclusionsStore = iInitializeExclusionArray(this.FittingData);
            
            reconcileCoefficientOptions(this, this.CurrentSpecification);
            
            notify (this, 'FittingDataUpdated', sftoolgui.FitEventData(this));
            notify (this, 'FitdevChanged');
            updateFit(this);
        end
        
        function doValidationDataUpdatedActions(this)
            % doValidationDataUpdateActions does tasks required when validation data has
            % changed.
            this.ValidationGoodness = [];
            if ~isempty(this.Fit)
                [this.ValidationGoodness.sse, this.ValidationGoodness.rmse] = getValidationGoodness( this );
            end
            notify (this, 'ValidationDataUpdated', sftoolgui.FitEventData(this));
            notify (this, 'FitdevChanged');
        end
        
        function startPoints = calculateStartPoints(this, specification)
            % calculateStartPoints   Calculates startPoints for fittypes
            % that have startpt methods unless fitting data is invalid.
            % Otherwise it will return random startpoints.
            ft = specification.Fittype;
            spfun = startpt(ft);
            if isempty(spfun) || ~isFittingDataValid(this)
                startPoints = iCreateStartPoints(ft);
            else
                startPoints = generateStartPointsByFunction(this, specification);
            end
        end
        
        function startPoints = generateStartPointsByFunction(this,specification)
            ft = specification.Fittype;
            spfun = startpt(ft);
            
            [inputs, output] = iGetInputOutputWeights(this.FittingData);
            % Remove excluded points from the data
            inputs = inputs(~this.Exclusions, :);
            output = output(~this.Exclusions);
            
            if size( inputs, 1 ) < numcoeffs( ft )
                % Insufficient data to fit model or guess start points so just use the default
                % values.
                startPoints = iCreateStartPoints( ft );
            else
                % Center scale data
                inputData = iCenterAndScaleInputs(inputs, specification.FitOptions);
                % Suppress the warning about power x needing to be positive
                warningState = warning('off', 'curvefit:fittype:sethandles:xMustBePositive');
                warningCleanup = onCleanup( @() warning( warningState) );
                % Compute start points
                c = constants(ft);
                startPoints = spfun(inputData, output, c{:});
            end
        end
        
        function reconcileCoefficientOptions(this, specification)
            % reconcileCoefficientOptions will ensure that startpoints,
            % upper bounds and lower bounds are all the same length. If the
            % fittype has a startpt method, it will use that to calculate
            % the startpoints. Otherwise it will just ensure that the
            % startpoints length is compatible with the number of
            % coefficients.
            
            ft = specification.Fittype;
            
            if isprop(specification.FitOptions, 'StartPoint')
                specification.FitOptions.StartPoint = calculateStartPoints(this, specification);
            end
            if isprop(specification.FitOptions, 'Lower')
                [lower, upper] = iCreateBounds(ft);
                specification.FitOptions.Lower = lower;
                % If there are lower bounds, there will also be upper
                % bounds.
                specification.FitOptions.Upper = upper;
            end
            % If there are lower bounds, there will also be upper bounds,
            % so check for just lower.
            if isprop(specification.FitOptions, 'StartPoint') || isprop(specification.FitOptions, 'Lower')
                notify (this, 'CoefficientOptionsUpdated', sftoolgui.FitEventData(this));
            end
        end
        
        function str = makeValidationString(this)
            % makeValidationString returns one of the following:
            % 1) validation statistics and possibly information about number of outside
            %    points (if validation goodness was calculated).
            % 2) an "incompatible data" message (if validation data is valid, but
            %    validation data and fitting data are incompatible).
            % 3) an empty string (if neither of the above cases applies).
            
            % Get the goodness of validation statistics.
            [sse, rmse, numOutside] = getValidationGoodness(this);
            
            % A non-empty sse indicates that validation goodness was calculated, which
            % means all of the following conditions were met:
            % 1) There was a fit object (which implies valid fitting data).
            % 2) Validation data was valid.
            % 3) Validation data and fitting data were compatible. (Data are
            %    incompatible if curve data is selected for fitting and surface data is
            %    selected for validation or surface data is selected for fitting and
            %    curve data is selected for validation).
            if ~isempty(sse)
                % Get message with statistics and possibly information about outside
                % points.
                if numOutside > 0
                    outsideMessage = getString(message ...
                        ('curvefit:sftoolgui:ValidationPointsOutsideDomainOfData', numOutside ));
                else
                    outsideMessage = '';
                end
                
                str = sprintf('SSE: %g\n  RMSE: %g\n%s', sse, rmse, outsideMessage );
                
                % An empty sse indicates validation goodness was not calculated. Are both
                % fitting data and validation data valid but incompatible? If so, get the
                % incompatible message.
            elseif  iIsDataValid(this.ValidationData) ...
                    && isFittingDataValid(this) ...
                    && ~isFittingValidationDataCompatible(this)
                
                str = iGetIncompatibleFittingValidationMessage();
                
                % Otherwise, validation goodness was not calculated for some other reason.
                % Return an empty string.
            else
                str = '';
            end
            % If there is a message, add a header.
            if ~isempty(str)
                str = sprintf('\n%s\n  %s', getString(message('curvefit:sftoolgui:GoodnessOfValidation')), str);
            end
        end
        
        function [sse, rmse, numOutside] = getValidationGoodness( this )
            % getValidationGoodness returns validation entries and the number of
            % outside points.
            
            % Get the fit object.
            fo = this.Fit;
            
            % If the fit object is not empty and the validation data is valid ...
            if ~isempty( fo ) && isValidationDataValid(this)
                % ... then calculate the validation goodness.
                [input, output] = iGetInputOutputWeights(this.ValidationData);
                [sse, rmse, numOutside] = iCalculateValidationGoodness( fo, input, output );
            else
                % ...otherwise, sse and rmse are empty, and the number of outside points is 0.
                sse = [];
                rmse = [];
                numOutside = 0;
            end
        end
        
        function tf = isFittingValidationDataCompatible(this)
            % isFittingValidationDataCompatible returns true if fitting and
            % validation data are either both curve or both surfaces.
            tf = isSurfaceData(this) || isCurveData(this);
        end
        
        function tf = isSurfaceData(this)
            % isSurfaceData returns true if surface data is specified for both Fitting
            % and Validation and false otherwise.
            
            tf = isSurfaceDataSpecified(this.FittingData) && ...
                isSurfaceDataSpecified(this.ValidationData);
        end
        
        function tf = isCurveData(this)
            % isCurveData returns true if curve data is specified for both Fitting
            % and Validation and false otherwise.
            tf = isCurveDataSpecified(this.FittingData) && ...
                isCurveDataSpecified(this.ValidationData);
        end
        
        function doGenerateCode(this,mcode)
            % doGenerateCode   Generate code for a Fitdev that is complete.
            
            % Add code for the fitting data
            addHelpComment( mcode, getString(message('curvefit:sftoolgui:DataForFit', this.FitName ) ));
            iGenerateCodeForFittingData( this.FittingData, mcode );
            
            % Add code for fittype
            iGenerateCodeForFittype( this.CurrentSpecification, mcode );
            
            % Add code for fit options
            factory = sftoolgui.codegen.FitOptionsCodeGeneratorFactory();
            focg = factory.create( this.CurrentSpecification.FitOptions );
            
            % Add code for weights
            if iHaveWeights( this.FittingData );
                focg.addParameterToken( 'Weights', '<weights>' );
            end
            
            % Add code to exclude points
            iGenerateCodeForExclusions( this.Exclusions, this.ExclusionRules, mcode, focg );
            
            focg.generateSetupCode( mcode );
            
            % Add code to do fit
            % ... add a blank line to separate sections of code
            addBlankLine( mcode );
            % ... add a comment for the call to fit
            addFitComment( mcode, getString(message('curvefit:sftoolgui:FitModelToData')) );
            % ... and the code to do the actual fit
            iGenerateCodeForFitting( mcode, isCurve( this ), focg );
            
            % Add code for validation data & validating the fit
            if isAnyDataSpecified( this.ValidationData )
                iGenerateCodeToValidateFit( this, mcode );
            end
        end
        
        function triggerExclusionsChanged(this)
            notify (this, 'ExclusionsUpdated', sftoolgui.FitEventData( this));
            
            % Recalculate startpoints if it is an option and the fittype
            % has a startpt function.
            ft = this.CurrentSpecification.Fittype;
            % Check for empty startpt function here since we want to
            % preserve user's startpoints if there is no startpt function.
            % (calculateStartPoints checks for presence of a startpt function
            % but will create random startpoints if the startpt function is
            % empty.)
            if isprop(this.CurrentSpecification.FitOptions, 'StartPoint') && ~isempty(startpt(ft))
                this.CurrentSpecification.FitOptions.StartPoint =  calculateStartPoints(this, this.CurrentSpecification);
                notify (this, 'CoefficientOptionsUpdated', sftoolgui.FitEventData(this));
            end
            % Update fit
            updateFit(this);
        end
        
        function setupExclusionRuleListener(this)
            delete(this.ExclusionRulesListener);
            this.ExclusionRulesListener = this.createListener(this.ExclusionRules, 'RulesChanged', @(~,~)this.triggerExclusionsChanged());
        end
    end
end

function this = iUpdateToV2(this)
% iUpdateToV2 adds or updates the 'CustomEquation' property. The
% 'CustomEquation' field was added for the 9a release (i.e. was not in the
% Prerelease version) but the 'Version' number was not increased. THIS is
% a struct that represents Fitdevs whose 'Version' property is < 2.

% If there isn't a 'CustomEquation' field
if ~isfield(this, 'CustomEquation')
    % ... then we need to add one
    this.CustomEquation = '';
end

% If this Fitdev is for a custom equation, but the 'CustomEquation' field
% is empty
if strcmp( category( this.FitTypeObject ), 'custom' ) && isempty( this.CustomEquation )
    % ... then we need to guess that the formula is close enough to what
    % the user typed for the custom equation (it will be accurate to
    % within some amount of whitespace)
    this.CustomEquation = formula( this.FitTypeObject );
end
end

function aStruct = iUpdateV2ToV3(aStruct)
% iUpdateV2ToV3 handles incompatible exclusions. If the exclusion array is
% longer than the longest data array, it probably means that the Data obj
% is V1 (before we removed NaNs and Infs) so in that case reinitialize
% array and warn the user if there were any exclusions.
[x, y, z] = getValues(aStruct.FittingData);
maxDataLength = max([length(x), length(y), length(z)]);
excludeLength = length(aStruct.Exclusions);
if excludeLength > maxDataLength
    if any(aStruct.Exclusions)
        warning(message('curvefit:sftoolgui:Fitdev:ExclusionsLost', aStruct.FitName));
    end
    aStruct.Exclusions = [];
end
end

function aStruct = iUpdateV3ToV4(aStruct)
% iUpdateV3ToV4 creates a SurfaceDefinition from Fitdev Version 3
% FitTypeObject and FitOptions, creates the default CurveDefinition and
% sets the Current Definition to be Surface. It also sets the
% ExclusionsStore property from the old Exclusions property.
if isfield(aStruct, 'FitTypeObject') && isfield(aStruct, 'FitOptions')
    aStruct.SurfaceDefinition = sftoolgui.FitDefinition(aStruct.FitTypeObject, aStruct.FitOptions);
else
    aStruct.SurfaceDefinition = iCreateDefaultSurfaceDefinition();
end
aStruct.CurveDefinition =  iCreateDefaultCurveDefinition();
aStruct.CurrentDefinition = aStruct.SurfaceDefinition;

if isfield(aStruct, 'Exclusions')
    aStruct.ExclusionsStore = aStruct.Exclusions;
end
end

function aStruct = iUpdateV4ToV5(aStruct)
% iUpdateV4ToV5 creates a CurveSpecification from a Fitdev Version 4
% CurveDefinition

if isfield(aStruct, 'CurveDefinition')
    aStruct.PrivateCurveSpecification = iCreateCurveSpecificationFromFitDev(aStruct);
else
    aStruct.PrivateCurveSpecification = iCreateDefaultCurveSpecification();
end

if isfield(aStruct, 'SurfaceDefinition')
    aStruct.PrivateSurfaceSpecification = iCreateSurfaceSpecificationFromFitDev(aStruct);
else
    aStruct.PrivateSurfaceSpecification = iCreateDefaultSurfaceSpecification();
end

end

function aStruct = iUpdateV5ToV6(aStruct)
% iUpdateV5ToV6   Update version 5 to version 6
%
% 1. Creates an ExclusionCollection to store any exclusion rules which may be
% created during the session
%
% 2. Moves the FitName to a private property

if isfield(aStruct, 'FitName')
    aStruct.PrivateFitName = aStruct.FitName;
    aStruct = rmfield( aStruct, 'FitName' );
end

aStruct.ExclusionRules = sftoolgui.exclusion.ExclusionCollection();
end

function curveSpecification = iCreateCurveSpecificationFromFitDev(this)
import sftoolgui.util.DefinitionConverter;

isAnInvalidCustomFit = iIsAnInvalidCustomFit(this.CurveDefinition, this.CustomEquation);

if (isAnInvalidCustomFit)
    curveSpecification = sftoolgui.fittypespec.CustomNonLinearCurveSpecification( ...
        this.CustomEquation, ...
        {}, ...
        sftoolgui.ImmutableCoefficientCache, ...
        '', ...
        '');
else
    curveSpecification = DefinitionConverter.convertDefinitionToSpecification(this.CurveDefinition);
end
end

function surfaceSpecification = iCreateSurfaceSpecificationFromFitDev(this)
import sftoolgui.util.DefinitionConverter;

isAnInvalidCustomFit = iIsAnInvalidCustomFit(this.SurfaceDefinition, this.CustomEquation);

if (isAnInvalidCustomFit)
    surfaceSpecification = sftoolgui.fittypespec.CustomNonLinearSurfaceSpecification( ...
        this.CustomEquation, ...
        {}, ...
        sftoolgui.ImmutableCoefficientCache, ...
        {'', ''}, ...
        '');
else
    surfaceSpecification = DefinitionConverter.convertDefinitionToSpecification(this.SurfaceDefinition);
end
end

function isAnInvalidCustomFit = iIsAnInvalidCustomFit(definition, customEquation)
isAnInvalidCustomFit = isempty(definition.Type) && ~isempty(customEquation);
end

function obj = iCreateLoadedObject(this)
% iCreateLoadedObject creates an sftoolgui.Fitdev and assigns values of
% THIS to its properties. THIS is either a struct or an sftoolgui.Fitdev.
obj = sftoolgui.Fitdev(this.PrivateFitName, this.FitID, []);
obj.PrivateCurveSpecification = this.PrivateCurveSpecification;
obj.PrivateSurfaceSpecification = this.PrivateSurfaceSpecification;
obj.ExclusionRules = this.ExclusionRules;
obj.AutoFitEnabled = this.AutoFitEnabled;
obj.Fit = this.Fit;
obj.Goodness = this.Goodness;
obj.ValidationGoodness = this.ValidationGoodness;
obj.Output = this.Output;
obj.FittingData = this.FittingData;
obj.ValidationData = this.ValidationData;
obj.WarningStr = this.WarningStr;
obj.ErrorStr = this.ErrorStr;
obj.ConvergenceStr = this.ConvergenceStr;
obj.FitState = this.FitState;
obj.ExclusionsStore = this.ExclusionsStore;
end

function exclusions = iInitializeExclusionArray(fittingData)
%iInitializeExclusionArray creates an exclusions array. The length of the
%array is the maximum length of x, y and z.
if isCurveDataSpecified(fittingData)
    [x, y] = getCurveValues(fittingData);
    z = [];
else
    [x, y, z] = getValues(fittingData);
end
excludeLength = max([length(x), length(y), length(z)]);
exclusions = false(1, excludeLength);
end

function tf = iAnyExclusions( manualExclusions, exclusionRules )
% iAnyExclusions   True if there are any exclusions associated with this Fitdev
tf = any( manualExclusions ) || iAnyEnabledExclusionRules( exclusionRules );
end

function tf = iAnyEnabledExclusionRules( exclusionCollection )
% iAnyEnabledExclusionRules   True if any of the rules in an exclusion collection
% are enabled
tf = any( cellfun( @(r) r.Enabled, exclusionCollection.Rules ) );
end

function isValid = iIsDataValid(data)
isValid = (isSurfaceDataSpecified(data) || isCurveDataSpecified(data)) ...
    && areNumSpecifiedElementsEqual(data);
end

function tf = iHaveWeights( hData )
% iHaveWeights -- Determine if a Data object has weights
[~, ~, ~, wName] = getNames( hData );
tf = ~isempty(wName);
end

%--- Code Generation Sub-Functions
function iGenerateCodeForFittingData( hData, mcode )
% iGenerateCodeForFittingData -- Generate Code for Fitting Data
theGenerator = sftoolgui.codegen.DataCodeGenerator.forFitting();
generateCode( theGenerator, hData, mcode );
end

function iGenerateCodeForFittype( specification, mcode )
% iGenerateCodeForFittype -- Generate code for a fittype
%
% Inputs:
%   specification -- a fittype specification to generate code for
%   mcode -- code object to add generated code to
codeGenVisitor = sftoolgui.codegen.FittypeGenerator( mcode );
specification.accept( codeGenVisitor );
end

function iGenerateCodeForExclusions( manualExclusions, exclusionRules, mcode, focg )
% iGenerateCodeForExclusions -- Generate code to define an exclusion vector
% and assign it as one of the options
%
% Inputs:
%   manualExclusions: logical array where true indicates a point to exclude
%   exclusionRules: collection of exclusion rules
%   mcode: the sftoolgui.codegen.MCode object to add code to
%   focg: fit options code generator 
generator = sftoolgui.codegen.ExclusionsGenerator( );
generator.ManualExclusions = manualExclusions;
exclusionRules.accept( generator );
generator.generateCode( mcode );

if iAnyExclusions( manualExclusions, exclusionRules )
    focg.addParameterToken( 'Exclude', '<ex>' );
end
end

function iGenerateCodeForFitting( mcode, isCurve, focg )

if isCurve
    input = '<x-input>';
    output = '<y-input>';
else
    input = '[<x-input>, <y-input>]';
    output = '<z-output>';
end

mcode.addFunctionCall( '<fo>', '<gof>', '=', 'fit', input, output, '<ft>', ...
    focg.ExtraFitArguments{:} );
end

function iGenerateCodeToValidateFit( this, mcode )
% iGenerateCodeToValidateFit   Generate the code required to validate a fit

% Add a blank line to separate sections of code
addBlankLine( mcode );

if isValidationDataValid( this )
    % If the validation data is valid ...
    % ... add a comment for the validation section
    addFitComment( mcode, getString(message('curvefit:sftoolgui:CompareAgainstValidationData')) );
    % ... add code for the validation data
    iGenerateCodeForValidationData( this.ValidationData, mcode );
    % ... add code for the goodness of validation computation and display
    iGenerateCodeForGoodnessOfValidation( this.FitName, mcode, isCurveDataSpecified( this.ValidationData ) );
    
else
    % If the validation data is invalid ...
    % ... insert a comment telling the user that we couldn't generate code for them.
    addFitComment( mcode, getString(message('curvefit:sftoolgui:CannotGenerateCodeForValidating', this.FitName )) );
end
end

function iGenerateCodeForValidationData( hData, mcode )
% iGenerateCodeForValidationData -- Generate Code for Validation Data
theGenerator = sftoolgui.codegen.DataCodeGenerator.forValidation();
generateCode( theGenerator, hData, mcode );
end

function iGenerateCodeForGoodnessOfValidation( fitName, mcode, isCurve )
% iGenerateCodeForGoodnessOfValidation -- Generate the code that computes
% the goodness of validation and then displays it.

addVariable( mcode, '<residual>', 'residual' );
addVariable( mcode, '<sse>', 'sse' );
addVariable( mcode, '<rmse>', 'rmse' );
addVariable( mcode, '<nNaN>', 'nNaN' );

if isCurve
    codeToComputeResiduals = '<validation-y> - <fo>( <validation-x> )';
else
    codeToComputeResiduals = '<validation-z> - <fo>( <validation-x>, <validation-y> )';
end
mcode.addAssignment( '<residual>', codeToComputeResiduals );

mcode.addMessyFunctionCall( '<nNaN> = nnz( isnan( <residual> ) );', {'nnz', 'isnan'} );
mcode.addMessyFunctionCall( '<residual>(isnan( <residual> )) = [];', {'isnan'} );
mcode.addMessyFunctionCall( '<sse> = norm( <residual> )^2;', {'norm'} );
mcode.addMessyFunctionCall( '<rmse> = sqrt( <sse>/length( <residual> ) );', {'sqrt', 'length'} );

% Need to separate string construction from code
% construction for proper translation.
gofString  = getString(message('curvefit:sftoolgui:GoodnessofvalidationForFit'));
sseString  = getString(message('curvefit:sftoolgui:SSE'));
rmseString = getString(message('curvefit:sftoolgui:RMSE'));
outsideString = getString(message('curvefit:sftoolgui:PointsOutsideDomainOfData'));

gofFormat     = sprintf( '''%s:\\n''', gofString );
sseFormat     = sprintf( '''    %s : %%f\\n''', sseString );
rmseFormat    = sprintf( '''    %s : %%f\\n''', rmseString );
outsideFormat = sprintf( '''    %s\\n''', outsideString );

mcode.addFunctionCall( 'fprintf', gofFormat, ['''', fitName, ''''] );
mcode.addFunctionCall( 'fprintf', sseFormat, '<sse>' );
mcode.addFunctionCall( 'fprintf', rmseFormat, '<rmse>' );
mcode.addFunctionCall( 'fprintf', outsideFormat, '<nNaN>' );
end
%--- End of Code Generation Sub-Functions

function [sse, rmse, numOutside] = iCalculateValidationGoodness( fo, input, output )
% iCalculateValidationGoodness returns validation entries and number of
% outside points. It assumes that fo, input and output are all valid.
outputHat = fo(input);
% For some model types, esp. GRIDDATA, outputHat will be NaN for some
% points because they are outside the region of definition of the
% surface. We remove those points from the stats and warn the user.
outputHatIsNan = isnan( outputHat );
numOutside = nnz( outputHatIsNan );
if numOutside > 0
    output = output(~outputHatIsNan);
    outputHat = outputHat(~outputHatIsNan);
end
residual = output(:) - outputHat;
sse = norm( residual )^2;
rmse = sqrt( sse/length( outputHat ) );
end

function theMessage = iGetIncompatibleFittingValidationMessage()
% iGetIncompatibleFittingValidationMessage returns an "incompatible fitting
% and validation data" message.
theMessage = getString(message('curvefit:sftoolgui:NotCalculatedIncompatibleFittingAndValidationData'));
end

function fitDefinition = iCreateDefaultCurveDefinition()
% iCreateDefaultCurveDefinition creates the default sftoolgui.FitDefinition
% for curves
defaultFittype = fittype('poly1');
defaultFitOptions = fitoptions(defaultFittype);
fitDefinition = sftoolgui.FitDefinition(defaultFittype, defaultFitOptions);
end

function fitSpecification = iCreateDefaultCurveSpecification()
% iCreateDefaultCurveSpecification creates the default
% sftoolgui.fittypespec.* for curves
fitSpecification = sftoolgui.fittypespec.LibraryCurveSpecification( ...
    'poly', '1', {}, sftoolgui.MutableCoefficientCache ...
    );
end

function fitSpecification = iCreateDefaultSurfaceSpecification()
% iCreateDefaultSurfaceSpecification creates the default
% sftoolgui.fittypespec.* for curves
fitSpecification = sftoolgui.fittypespec.InterpolantSurfaceSpecification( ...
    'linear', {'Normalize', 'on'} ...
    );
end

function fitDefinition = iCreateDefaultSurfaceDefinition()
% iCreateDefaultSurfaceDefinition creates the default
% sftoolgui.FitDefinition for surfaces and sets the 'Normalize'
% option to be 'on'.
defaultFittype = fittype( 'linearinterp', 'numindep', 2 );
defaultFitOptions = fitoptions(defaultFittype);
defaultFitOptions.Normalize = 'on';
fitDefinition = sftoolgui.FitDefinition(defaultFittype, defaultFitOptions);
end

function [lower, upper] = iCreateBounds(fitType)
% iCreateBounds creates arrays of lower and upper bounds. The length of the
% arrays is the same as the number of coefficients.
numcoeff = numcoeffs(fitType);
% If the fittype has specific lower bounds, use those.
fo = fitoptions(fitType);
if isscalar(fo) && isprop(fo, 'Lower') && ~isempty(fo.Lower)
    lower = fo.Lower;
else
    lower = -Inf(1, numcoeff);
end
if isscalar(fo) && isprop(fo, 'Upper') && ~isempty(fo.Upper)
    upper = fo.Upper;
else
    upper = Inf(1, numcoeff);
end
end

function startPoints = iCreateStartPoints(fitType)
% iCreateStartPoints creates an array of (random) startpoints that is the
% same length as the number of coefficients.
numcoeff = numcoeffs(fitType);
startPoints = rand(1, numcoeff);
end

function inputs = iCenterAndScaleInputs(inputs, fopts)
% iCenterAndScaleInputs will center and scale inputs if "Normalize" option
% is on.
if isprop(fopts, 'Normalize') && strcmpi(fopts.Normalize, 'on')
    inputs = curvefit.normalize(inputs);
end
end

function [input, output, weights] = iGetInputOutputWeights(data)
% getInputOutputWeights returns input, output and weights
% for both curve and non-curve data, which is assumed to have been tested
% for validity before this function is called.

if isCurveDataSpecified(data)
    [input, output, weights] = getCurveValues(data);
else
    [x, y, output, weights] = getValues(data);
    % concatenate x and y
    input = [x, y];
end
end

function [aFit, aGoodness, anOutput, aWarning, anError, aConvergence] = iCallFit( ...
    fittingData, specification, exclusions )
% iCallFit   Call the Fit Function
%
% Syntax:
%   iCallFit( fittingData, specification, exclusions )
%
% Inputs:
%   fittingData -- sftoolgui.Data
%   specification -- sftoolgui.fittypespec.*
%   exclusions -- logical column vector
aFittype = specification.Fittype;

if iIsDataValid( fittingData ) && ~isempty( aFittype )
    % We have valid fitting and a valid fit specification. Therefore we can fit.
    [input, output, weights] = iGetInputOutputWeights( fittingData );
    
    % Assign weights and Exclusions into the fit options
    fitOptions = specification.FitOptions;
    fitOptions.Weights = weights;
    fitOptions.Exclude = exclusions;
    
    % Fit!
    [aFit, aGoodness, anOutput, aWarning, anError, aConvergence] = ...
        fit( input, output, aFittype, fitOptions );
    
else
    % Without a valid fitting data and a valid fittype, we need to return empty for
    % all arguments.
    aFit = [];
    aGoodness = [];
    anOutput = [];
    aWarning = '';
    anError = '';
    aConvergence = '';
end
end

function fitState = iPostFittingFitState( aFit, anError, aWarning, fittingData )
% iPostFittingFitState   The "fit state" after a fit has been performed.
ERROR      = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.ERROR;
WARNING    = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING;
GOOD       = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.GOOD;
INCOMPLETE = com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.INCOMPLETE;

if ~isempty( anError )
    fitState = ERROR;
    
elseif isempty( aFit )
    fitState = INCOMPLETE;
    
elseif ~isempty( aWarning ) || ~isempty( getMessageString( fittingData ) )
    fitState = WARNING;
    
else
    fitState = GOOD;
end
end

function residuals = iResiduals (fitObject, data)
% iResiduals calculates residuals. This method assumes that fitObject is
% not empty.
[input, output] = iGetInputOutputWeights( data );
residuals = output - fitObject( input );
end

function label = iGetDominantLabel(fittingName, validationName, defaultLabel)
% iGetDominantLabel returns a label based on data names. Names are empty if
% a value has not been specified. If there is a fitting name, use it. If
% there is no fitting name, but a validation name, use the validation name.
% If both fitting and validation names are empty, use the default.

if ~isempty( fittingName )
    label = fittingName;
    
elseif ~isempty( validationName )
    label = validationName;
    
else % assume the default is not empty
    label = defaultLabel;
end
end

function tf = isCustomEquation(currentSpecification)
tf = isa(currentSpecification, 'sftoolgui.fittypespec.CustomLinearCurveSpecification') ...
    || isa(currentSpecification, 'sftoolgui.fittypespec.CustomNonLinearCurveSpecification') ...
    || isa(currentSpecification, 'sftoolgui.fittypespec.CustomNonLinearSurfaceSpecification');
end


