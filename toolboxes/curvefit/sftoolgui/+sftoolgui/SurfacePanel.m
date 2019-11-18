classdef SurfacePanel < sftoolgui.Panel
    % SurfacePanel   A panel used by SFTOOL for plotting data and fits
    %
    %   panel = sftoolgui.SurfacePanel(fitFigure, parent)
    %
    % This panel can be constructed with a user specified
    % ExclusionRulePlotter:
    %
    %   panel = sftoolgui.SurfacePanel(fitFigure, parent, 'ExclusionRulePlotter', myPlotter)
    
    %   Copyright 2008-2014 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'public')
        HFitdev;
        HFitFigure;
    end
    
    properties(Access = 'private')
        % Created   Flag to indicate if the "graphics" have been created.
        Created = false;
        
        % Plotter for exclusion rules
        ExclusionRulePlotter;
    end
    
    properties(SetAccess = 'private', GetAccess = 'public')
        HAxes ;
        HSurfacePlot ;
        HCurvePlot ;
        HFittingDataLine ;
        HValidationDataLine ;
        HFittingExclusionLine ;
        HFittingInclusionLine ;
        HFittingExclusionRuleLine ;
    end
    
    methods
        % Get methods
        % The "get" methods for the graphics properties are all the same. They first need
        % to ensure that the graphics are created and then return the value of the
        % appropriate property.
        function v = get.HAxes( this )
            createGraphics( this );
            v = this.HAxes;
        end
        function v = get.HSurfacePlot( this )
            createGraphics( this );
            v = this.HSurfacePlot;
        end
        function v = get.HCurvePlot( this )
            createGraphics( this );
            v = this.HCurvePlot;
        end
        function v = get.HFittingDataLine( this )
            createGraphics( this );
            v = this.HFittingDataLine;
        end
        function v = get.HValidationDataLine( this )
            createGraphics( this );
            v = this.HValidationDataLine;
        end
        function v = get.HFittingExclusionLine( this )
            createGraphics( this );
            v = this.HFittingExclusionLine;
        end
        function v = get.HFittingExclusionRuleLine( this )
            createGraphics( this );
            v = this.HFittingExclusionRuleLine;
        end
        function v = get.HFittingInclusionLine( this )
            createGraphics( this );
            v = this.HFittingInclusionLine;
        end
    end
    
    properties(SetAccess = 'public', GetAccess = 'public', Dependent)
        % PredictionLevel is the level of confidence of the prediction
        % bounds displayed for the curve or surface. To turn off prediction
        % bounds use PredictionLevel = 0.
        PredictionLevel = 0;
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % AxesViewController is an sftoolgui.AxesViewController
        AxesViewController;
        % AxesViewModel is the sftoolgui.AxesViewModel
        AxesViewModel;
        % PrivatePredictionLevel is the private property associated with
        % the public dependent PredictionLevel property.
        PrivatePredictionLevel = 0;
    end
    
    properties(Constant);
        Icon = 'surfaceSMALL.png';
        % Description is used as the toolbar button tooltip
        Description = getString(message('curvefit:sftoolgui:toolTip_MainPlot'));
        % Name is used as the menu label
        Name = getString(message('curvefit:sftoolgui:menu_MainPlot'));
    end
    
    methods
        function this = SurfacePanel( fitFigure, parent, varargin ) 
            this = this@sftoolgui.Panel(parent);
            
            this.ExclusionRulePlotter = sftoolgui.parsePanelInputs(fitFigure.HFitdev, varargin{:});
            
            this.HFitFigure = fitFigure;
            this.HFitdev = fitFigure.HFitdev;
            this.AxesViewModel = fitFigure.AxesViewModel;
            
            this.Tag = 'SurfaceUIPanel';
            this.Visible = 'off';
        end
        
        function level = get.PredictionLevel(this)
            % Return the value of the associated private property
            level = this.PrivatePredictionLevel;
        end
        
        function set.PredictionLevel(this, level)
            % In addition to setting the PrivatePredictionLevel property,
            % this method will set the PredictionBounds and
            % PredictionBoundsOptions.Level properties of HSurfacePlot and
            % HCurvePlot. It will then (re)plot the curve or surface.
            this.PrivatePredictionLevel = level;
            if (level == 0)
                this.HSurfacePlot.PredictionBounds = 'off';
                this.HCurvePlot.PredictionBounds = 'off';
            else
                level = level/100;
                this.HSurfacePlot.PredictionBounds = 'on';
                this.HCurvePlot.PredictionBounds = 'on';
                this.HSurfacePlot.PredictionBoundsOptions.Level = level;
                this.HCurvePlot.PredictionBoundsOptions.Level = level;
            end
            plotSurface(this);
        end
        
        function plotSurface(this)
            clearSurface(this);
            if isCurveDataSpecified(this.HFitdev.FittingData)
                this.HCurvePlot.FitObject = this.HFitdev.Fit;
            else
                this.HSurfacePlot.FitObject = this.HFitdev.Fit;
            end
            updateDisplayNames(this);
            updateLegend(this, this.HFitFigure.LegendOn);
        end
        
        function clearSurface(this)
            % clearSurface    Clear the surface or line that shows the fit
            %
            % This should be called when the curve or surface fit changes.
            
            % The surface (and curve) only need to be cleared if the graphics have been
            % created.
            if this.Created
                this.HSurfacePlot.FitObject = [];
                this.HCurvePlot.FitObject = [];
            end
        end
        
        function updateGrid(this)
            set(this.HAxes, 'XGrid', this.HFitFigure.GridState);
            set(this.HAxes, 'YGrid', this.HFitFigure.GridState);
            set(this.HAxes, 'ZGrid', this.HFitFigure.GridState);
        end
        
        function updateDisplayNames(this)
            this.HSurfacePlot.DisplayName = this.HFitdev.FitName;
            this.HCurvePlot.DisplayName = this.HFitdev.FitName;
        end
        
        function updateLabels(this)
            % updateLabels updates axes labels
            
            [xLabel, yLabel, zLabel] = getDominantLabels(this.HFitdev);
            
            set( get( this.HAxes, 'XLabel' ), 'String', xLabel);
            set( get( this.HAxes, 'YLabel' ), 'String', yLabel);
            set( get( this.HAxes, 'ZLabel' ), 'String', zLabel);
        end
        
        function updateLegend(this, state)
            % updateLegend   Show or hide the legend
            %
            % Syntax:
            %   updateLegend(panel, state)
            %
            % Inputs:
            %   state - Boolean. If state is true then the legend is displayed. If it is
            %      false the legend is hidden.
            
            % The legend only needs be updated if the graphics have been created.
            if this.Created
                sftoolgui.util.refreshLegend(this.HAxes, state);
            end
        end
        
        function plotDataLineWithExclusions(this)
            values =  sftoolgui.util.previewValues(this.HFitdev.FittingData);
            displayName = this.HFitdev.FittingData.Name;
            
            exclusions = this.HFitdev.Exclusions;
            exclusionsByRule = this.HFitdev.ExclusionsByRule;
            
            plotDataLine(this, 'HFittingDataLine', values, '');
            
            [blackDots, redDots, redCrosses] = sftoolgui.exclusion.exclusionsToMarkers(exclusions, exclusionsByRule);
            
            includedValues = values;
            includedValues{1} = values{1}(blackDots);
            includedValues{2} = values{2}(blackDots);
            includedValues{3} = values{3}(blackDots);
            plotDataLine(this, 'HFittingInclusionLine', includedValues, displayName);
            
            excludedValues = values;
            excludedValues{1} = values{1}(redCrosses);
            excludedValues{2} = values{2}(redCrosses);
            excludedValues{3} = values{3}(redCrosses);
            plotDataLine(this, 'HFittingExclusionLine', excludedValues, ...
                getString(message('curvefit:sftoolgui:DisplayNameExcluded',  displayName)));
            
            exclusionRuleValues = values;
            exclusionRuleValues{1} = values{1}(redDots);
            exclusionRuleValues{2} = values{2}(redDots);
            exclusionRuleValues{3} = values{3}(redDots);
            plotDataLine(this, 'HFittingExclusionRuleLine', exclusionRuleValues, ...
                getString(message('curvefit:sftoolgui:DisplayNameExcludedByRule',  displayName)));
            
            if this.Created
                this.HCurvePlot.XData = values{1};
            end
        end
        
        function plotValidationLine(this, values, displayName)
            % plotValidationLine -- Plot validation data
            %
            % Syntax:
            %
            %   plotValidationLine(panel, values, displayName)
            %
            % Inputs:
            %   panel -- the surface panel where the validation data should be plotted.
            %   values -- the values to plot. A cell array with three vectors.
            %  displayName -- the name of the dataset for the validation data.
            plotDataLine( this, 'HValidationDataLine', values, displayName);
        end
        
        function clearFittingDataLine(this)
            clearDataLine( this, 'HFittingDataLine' );
            clearDataLine( this, 'HFittingExclusionLine' );
            clearDataLine( this, 'HFittingExclusionRuleLine' );
            clearDataLine( this, 'HFittingInclusionLine' );
        end
        
        function clearValidationDataLine(this)
            clearDataLine( this, 'HValidationDataLine' );
        end
        
        function tf = canGenerateCodeForPlot(this)
            % canGenerateCodeForPlot   True if code can be generated
            %
            %    canGenerateCodeForPlot( this ) returns true if code can be
            %    generated for surface plots and false otherwise. Code can
            %    be generated for surface plots if the panel is visible.
            
            tf = strcmpi( this.Visible, 'on' );
        end
        
        function generateMCode( this, mcode )
            % generateMCode   Generate code for a Surface Panel
            %
            %    generateMCode( H, CODE ) generates code for the given
            %    surface panel, H, and adds it the code object CODE.
            theFitdev = this.HFitdev;
            if isCurveDataSpecified( theFitdev.FittingData )
                cg = sftoolgui.codegen.CurvePlotCodeGenerator();
                
                xValues = getValues( theFitdev.FittingData );
                cg.HasXData = ~isempty( xValues );
            else
                cg = sftoolgui.codegen.SurfacePlotCodeGenerator();
                [cg.View(1), cg.View(2)] = view( this.HAxes );
            end
            
            cg.DoPredictionBounds = strcmpi( this.HSurfacePlot.PredictionBounds, 'on' );
            cg.PredictionLevel    = this.HSurfacePlot.PredictionBoundsOptions.Level;
            cg.FitName            = theFitdev.FitName;
            cg.FittingDataName    = theFitdev.FittingData.Name;
            cg.ValidationDataName = theFitdev.ValidationData.Name;
            cg.HaveLegend         = ~isempty(get(this.HAxes,'Legend'));
            cg.HaveExcludedData   = theFitdev.HasExclusions;
            cg.HaveValidation     = isValidationDataValid( theFitdev );
            cg.GridState          = this.HFitFigure.GridState;
            
            generateMCode( cg, mcode );
        end
        
        function printToFigure( this, target )
            % printToFigure   Print a Surface Panel to a figure
            %
            %   printToFigure( aSurfacePanel, target ) "prints" the contents of a
            %   Surface Panel to the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            
            target.addAxes( this.HAxes );
            printToFigure( this.HSurfacePlot, target );
            if iHasData( this.HFittingInclusionLine )
                target.addLine( this.HFittingInclusionLine );
            end
            if iHasData( this.HFittingExclusionLine )
                target.addLine( this.HFittingExclusionLine );
            end
            if iHasData( this.HFittingExclusionRuleLine )
                target.addLine( this.HFittingExclusionRuleLine );
            end
            if iHasData( this.HValidationDataLine )
                target.addLine( this.HValidationDataLine );
            end
            printToFigure( this.HCurvePlot, target );
            
            aLegend = get(this.HAxes,'Legend');
            if ~isempty( aLegend )
                target.addLegend( aLegend );
            end
        end
    end
    
    methods(Access = protected)
         function postSetVisible( this )
            % postSetVisible   When the SurfacePanel is made visible we need to ensure that
            % the graphics are created.
            postSetVisible@sftoolgui.Panel( this );
            if isequal( this.Visible, 'on' )
                createGraphics( this );
            end
        end
    end
    
    methods(Access = private)
        function createGraphics( this )
            % createGraphics   Create graphics (axes and children) for SurfacePanel.
            
            % If the graphics haven't been created ...
            if ~this.Created
                % ... then create them all.
                this.Created = true;
                
                % Set up axes
                anAxes = sftoolgui.util.createAxes( this.HUIPanel, 'sftool surface axes' );
                this.HAxes = anAxes;
                
                % Create an AxesViewController
                this.AxesViewController = sftoolgui.AxesViewController( ...
                    anAxes, this.AxesViewModel, ...
                    isCurveDataSpecified( this.HFitdev.FittingData ) );
                
                % Create the exclusion plotter
                this.ExclusionRulePlotter.Axes = this.HAxes;
                this.updateExclusionRulePlotterDimension()
                
                % Create graphics in order: objects at the "back" are created before those at the
                % "front"...
                
                % ... plots of surface fits go at the back
                this.HSurfacePlot = curvefit.gui.FunctionSurface( anAxes );
                this.HSurfacePlot.EdgeAlpha = 0.3;

                % ... line for fitting (included & excluded) data
                this.HFittingDataLine = sftoolgui.util.lineForExclusion( anAxes, 'SurfaceFittingDataLine' );

                % ... lines to show other data: included, excluded, validation
                this.HFittingInclusionLine = sftoolgui.util.lineOfPoints( ...
                    anAxes, 'SurfaceFittingInclusionDataLine', 'inclusion' );
                
                this.HFittingExclusionLine = sftoolgui.util.lineOfPoints( ...
                    anAxes, 'SurfaceFittingExclusionDataLine', 'exclusion' );
                
                this.HFittingExclusionRuleLine = sftoolgui.util.lineOfPoints( ...
                    anAxes, 'SurfaceFittingExclusionRuleDataLine', 'exclusionRule' );
                
                this.HValidationDataLine = sftoolgui.util.lineOfPoints( ...
                    anAxes, 'SurfaceValidationDataLine', 'validation' );

                % ... plots of fitted curves go at the front
                this.HCurvePlot = curvefit.gui.FunctionLine( anAxes );
                this.HCurvePlot.Color = sftoolgui.util.Color.Blue;
                this.HCurvePlot.LineWidth = 1.5;

                % Plot any data from the Fitdev
                callPlotDataLineWithExclusions( this );
                callPlotValidationLine( this );
                plotSurface( this );
                
                % Update the limits
                updateLimits(this);
                
                % Update the labels
                updateLabels(this);
                
                % Create listeners
                createListeners(this);
            end
        end
        
        function callPlotDataLineWithExclusions( this )
            % callPlotDataLineWithExclusions   Get information from Fitdev and call plotDataLineWithExclusions
            aFitdev = this.HFitFigure.HFitdev;

            if areNumSpecifiedElementsEqual( aFitdev.FittingData )
                this.plotDataLineWithExclusions();
            end
        end
        
        function callPlotValidationLine( this )
            % callPlotValidationLine  Get information from Fitdev and call plotValidationLine
            aFitdev = this.HFitFigure.HFitdev;
            
            previewValues =  sftoolgui.util.previewValues( aFitdev.ValidationData );
            
            if areNumSpecifiedElementsEqual( aFitdev.ValidationData )
                this.plotValidationLine( previewValues, aFitdev.ValidationData.Name );
            end
        end
        
        function dimensionChangedAction(this, ~, ~)
            %function dimensionChangedAction(this, src, event)
            % dimensionChangedAction sets the AxesViewController View2D
            % property.
            this.AxesViewController.View2D = isCurveDataSpecified(this.HFitdev.FittingData);
            
            this.updateExclusionRulePlotterDimension();
        end
        
        function limitsChangedAction(this, ~, ~)
            % function limitsChangedAction(this, source, event)
            % limitsChangedAction updates limits
            updateLimits(this);
            
            % Save the current limit information
            resetplotview(this.HAxes, 'SaveCurrentViewLimitsOnly');
        end
        
        function updateLimits(this)
            % updateLimits updates axes limits with AxesViewModel values.
            
            avm = this.AxesViewModel;
            
            xlim = avm.XInputLimits;
            if isCurveDataSpecified(this.HFitdev.FittingData)
                ylim = avm.ResponseLimits ;
                zlim = [-1 1];
            else
                ylim = avm.YInputLimits;
                zlim = avm.ResponseLimits ;
            end
            set(this.HAxes, 'XLim', xlim, 'YLim', ylim, 'ZLim', zlim);
        end
        
        function requestedLimitsPostSetAction(this, ~, ~)
            % function requestedLimitsPostSetAction(this, source, event)
            % requestedLimitsPostSetAction sets AxesViewModel limits
            limits = this.HAxes.RequestedLimits;
            xlim = limits{1};
            ylim = limits{2};
            zlim = limits{3};
            
            if isCurveDataSpecified( this.HFitdev.FittingData )
                setLimits(this.AxesViewModel, {xlim}, ylim, []);
            else
                setLimits(this.AxesViewModel, {xlim, ylim}, zlim, []);
            end
        end
        
        function plotDataLine(this, lineName, values, displayName)
            % plotDataLine   Plot a line in a Surface Panel
            %
            % Syntax:
            %   plotDataLine(panel, theLine, values, displayName)
            %
            % Inputs:
            %   lineName -- name of the line to plot. One of 'HFittingDataLine',
            %       'HValidationDataLine', 'HFittingExclusionLine' or 'HFittingInclusionLine'.
            %   values -- the values to plot. A cell array with three vectors.
            %   displayName -- the display name for the line.
            
            % The line only needs to be plotted if there the graphics have been created.
            if this.Created
                
                % if curve data is specified set z-data to empty.
                if isCurveDataSpecified( this.HFitdev.FittingData )
                    zdata = [];
                else
                    zdata = values{3};
                end
                
                % To plot the line, set the appropriate data values.
                aLine = this.(lineName);
                set(aLine, 'XData', values{1}, 'YData', values{2}, ...
                    'ZData', zdata, 'DisplayName', displayName);
            end
        end
        
        function dataUpdatedAction(this, ~, ~)
            % function dataUpdatedAction(this, source, event)
            updateLabels(this);
        end
        
        function createListeners(this)
            % createListeners adds listeners for the AxesViewModel
            % LimitsChanged event and the Fitdev DimensionChanged event.
            this.createListener( this.HFitdev, 'FittingDataUpdated', @this.dataUpdatedAction );
            this.createListener( this.HFitdev, 'ValidationDataUpdated', @this.dataUpdatedAction );
            this.createListener( this.AxesViewModel, 'LimitsChanged', @this.limitsChangedAction );
            this.createListener( this.HFitdev, 'DimensionChanged',  @this.dimensionChangedAction );
            this.createListener( this.HAxes, 'RequestedLimits', @this.requestedLimitsPostSetAction );
        end
        
        function clearDataLine(this, lineName)
            % clearDataLine   Clear a line in a Surface Panel
            %
            % Syntax:
            %   clearDataLine(panel, lineName)
            %
            % Inputs:
            %   lineName -- name of the line to plot. One of 'HFittingDataLine',
            %       'HValidationDataLine', 'HFittingExclusionLine' or 'HFittingInclusionLine'.
            
            % The lines only need to be cleared if the graphics have been created.
            if this.Created
                aLine = this.(lineName);
                set(aLine, 'XData', [], 'YData', [], 'ZData', []);
            end
        end
        
        function updateExclusionRulePlotterDimension(this)
            if isCurveDataSpecified(this.HFitdev.FittingData)
                this.ExclusionRulePlotter.VariablesToIgnore = {'z'};
            else	
                this.ExclusionRulePlotter.VariablesToIgnore = {};
            end
        end
    end
end

function tf = iHasData( aLine )
% iHasData   True for a line that has data
data = get( aLine, {'XData', 'YData', 'ZData'} );
% A line has data if any of the data fields are not empty
tf = any( not( cellfun( @isempty, data ) ) );
end
