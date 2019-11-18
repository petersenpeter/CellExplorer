classdef ContourPanel < sftoolgui.Panel
    % ContourPanel   Panel used by SFTOOL for contour-plotting fits
    %
    %   aPanel = sftoolgui.ContourPanel(fitFigure, parent)
    %
    % This panel can be constructed with a user specified
    % ExclusionRulePlotter:
    %
    %   aPanel = sftoolgui.ContourPanel(fitFigure, parent, 'ExclusionRulePlotter', myPlotter)
    
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
        HAxes = [];
        HContours = [];
        HFittingDataLine  = [];
        HValidationDataLine  = [];
        HFittingExclusionLine  = [];
        HFittingExclusionRuleLine  = [];
    end
    methods
        % The "get" methods for the graphics properties are all the same. They first need
        % to ensure that the graphics are created and then return the value of the
        % appropriate property.
        function v = get.HAxes( this )
            createGraphics( this );
            v = this.HAxes;
        end
        function v = get.HContours( this )
            createGraphics( this );
            v = this.HContours;
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
    end
    
    properties(Constant);
        Icon = 'contourSMALL.png';
        % Description is used as the toolbar button tooltip
        Description = getString(message('curvefit:sftoolgui:toolTip_ContourPlot'));
        % Name is used as the menu label
        Name = getString(message('curvefit:sftoolgui:menu_ContourPlot'));
        % NoCurveContoursMessage   Message to use when contour plot cannot be displayed
        NoCurveContoursMessage = message('curvefit:sftoolgui:ContourPanel:NoCurveContour');
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % UIPanel that contains the contour axes
        HImplementationPanel
        
        % MessagePanel object that displays when fit is 2D
        HMessagePanel
        
        % AxesViewModel is the sftoolgui.AxesViewModel
        AxesViewModel;
    end
    
    methods
        function this = ContourPanel( fitFigure, parent, varargin )
            this = this@sftoolgui.Panel(parent);
            
            this.ExclusionRulePlotter = sftoolgui.parsePanelInputs(fitFigure.HFitdev, varargin{:});
            
            set(this.HUIPanel, 'BorderType', 'none');
            
            this.HFitFigure = fitFigure;
            this.HFitdev = fitFigure.HFitdev;
            this.AxesViewModel = fitFigure.AxesViewModel;
            
            this.HImplementationPanel = sftoolgui.util.createEtchedPanel(this.HUIPanel);
            set(this.HImplementationPanel, 'Tag', 'ContourImplementationUIPanel');
            % Save this panel in the uipanel's appdata
            setappdata(this.HUIPanel, 'SurfaceFittingToolPlotPanel', this);
            
            % Create the MessagePanel
            this.HMessagePanel = sftoolgui.MessagePanel(this.HUIPanel, this.NoCurveContoursMessage);
            this.HMessagePanel.Tag = 'ContourMessageUIPanel';
            
            this.Tag = 'ContourUIPanel';
            this.Visible = 'off';
        end
        
        function plotSurface(this)
            clearSurface(this);
            if ~isCurveDataSpecified(this.HFitdev.FittingData)
                this.HContours.FitObject = this.HFitdev.Fit;
            end
            updateDisplayNames(this);
            updateLegend(this, this.HFitFigure.LegendOn);
        end
        
        function clearSurface(this)
            % clearSurface clears the plot when the curve or surface fit changes.
            this.HContours.FitObject = [];
        end
        
        function updateGrid(this)
            if this.Created
                set(this.HAxes, 'XGrid', this.HFitFigure.GridState);
                set(this.HAxes, 'YGrid', this.HFitFigure.GridState);
                set(this.HAxes, 'ZGrid', this.HFitFigure.GridState);
            end
        end
        
        function updateDisplayNames(this)
            this.HContours.DisplayName = this.HFitdev.FitName;
        end
        
        function updateLabels(this)
            % updateLabels updates axes labels
            
            [xLabel, yLabel] = getDominantLabels(this.HFitdev);
            
            set( get( this.HAxes, 'XLabel' ), 'String', xLabel);
            set( get( this.HAxes, 'YLabel' ), 'String', yLabel);
        end
        
        function updateLegend(this, state)
            if this.Created
                sftoolgui.util.refreshLegend(this.HAxes, state);
            end
        end
        
        function plotDataLineWithExclusions(this)
            % plotDataLineWithExclusions   Plot included and excluded data
            
            if this.Created
                values =  sftoolgui.util.previewValues(this.HFitdev.FittingData);
                displayName = this.HFitdev.FittingData.Name;
                
                exclude = this.HFitdev.Exclusions;
                exclusionsByRule = this.HFitdev.ExclusionsByRule;
                
                [blackDots, redDots, redCrosses] = sftoolgui.exclusion.exclusionsToMarkers(exclude, exclusionsByRule);
                
                includedValues{1} = values{1};
                includedValues{1}(~blackDots) = NaN;
                
                includedValues{2} = values{2};
                includedValues{2}(~blackDots) = NaN;
                
                includedValues{3} = values{3};
                includedValues{3}(~blackDots) = NaN;
                
                excludedValues{1} = values{1};
                excludedValues{1}(~redCrosses) = NaN;
                
                excludedValues{2} = values{2};
                excludedValues{2}(~redCrosses) = NaN;
                
                excludedValues{3} = values{3};
                excludedValues{3}(~redCrosses) = NaN;
                
                exclusionRuleValues{1} = values{1};
                exclusionRuleValues{1}(~redDots) = NaN;
                
                exclusionRuleValues{2} = values{2};
                exclusionRuleValues{2}(~redDots) = NaN;
                
                exclusionRuleValues{3} = values{3};
                exclusionRuleValues{3}(~redDots) = NaN;
                
                iPlotDataLine(this.HFittingDataLine, includedValues, displayName );
                iPlotDataLine(this.HFittingExclusionLine, excludedValues, getString(message('curvefit:sftoolgui:DisplayNameExcluded', displayName)));
                iPlotDataLine(this.HFittingExclusionRuleLine, exclusionRuleValues, getString(message('curvefit:sftoolgui:DisplayNameExcludedByRule', displayName)));
            end
        end
        
        function plotValidationLine(this, values, displayName)
            if this.Created
                plotDataLine( this, this.HValidationDataLine, values, displayName);
            end
        end
        
        function clearFittingDataLine(this)
            if this.Created
                iClearDataLine(this.HFittingDataLine);
                iClearDataLine(this.HFittingExclusionLine);
                iClearDataLine(this.HFittingExclusionRuleLine);
            end
        end
        
        function clearValidationDataLine(this)
            if this.Created
                iClearDataLine(this.HValidationDataLine);
            end
        end
        
        function tf = canGenerateCodeForPlot(this)
            % canGenerateCodeForPlot   True if code can be generated
            %
            %    canGenerateCodeForPlot( this ) returns true if code can be
            %    generated for contour plots and false otherwise. Code can
            %    be generated for contour plots if the panel is visible and
            %    curve data is not specified.
            
            tf = strcmpi( this.Visible, 'on' ) && ...
                ~isCurveDataSpecified( this.HFitdev.FittingData );
        end
        
        function generateMCode( this, mcode )
            % GENERATEMCODE   Generate code for a Contour Panel
            %
            %    GENERATEMCODE( H, CODE ) generates code for the given
            %    contour panel, H, and adds it to the code object CODE.
            %
            %    This method should not be called when there is curve data
            %    selected. There is no check for curve data selected in
            %    in this method as this method should be called only if
            %    canGenerateCodeForPlot(this) is true.
            %
            %    See also canGenerateCodeForPlot
            
            cg = sftoolgui.codegen.ContourPlotCodeGenerator();
            cg.FitName            = this.HFitdev.FitName;
            cg.FittingDataName    = this.HFitdev.FittingData.Name;
            cg.ValidationDataName = this.HFitdev.ValidationData.Name;
            cg.HaveLegend         = ~isempty(get(this.HAxes,'Legend'));
            cg.HaveExcludedData   = this.HFitdev.HasExclusions;
            cg.HaveValidation     = isValidationDataValid(this.HFitdev);
            cg.GridState          = this.HFitFigure.GridState;
            generateMCode( cg, mcode );
        end
        
        function printToFigure( this, target )
            % printToFigure   Print a Contour Panel to a figure
            %
            %   printToFigure( aContourPanel, target ) "prints" the contents of a Contour
            %   Panel to the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            if isCurveDataSpecified( this.HFitdev.FittingData )
                printToFigure( this.HMessagePanel, target );
            else
                target.addAxes( this.HAxes );
                printToFigure( this.HContours, target );
                target.add( 'Line', this.HFittingDataLine );
                if isValidationDataValid( this.HFitdev )
                    target.add( 'Line', this.HValidationDataLine );
                end
                if any( this.HFitdev.Exclusions )
                    target.add( 'Line', this.HFittingExclusionLine );
                end
                if any( this.HFitdev.ExclusionsByRule )
                    target.add( 'Line', this.HFittingExclusionRuleLine );
                end
                
                aLegend = get(this.HAxes,'Legend');
                if ~isempty( aLegend );
                    target.addLegend( aLegend );
                end
            end
        end
    end
    
    methods(Access = protected)
        function layoutPanel(this)
            % Update the positions of objects within the panel
            this.layoutPanel@sftoolgui.Panel()
            
            % Set the Message panel and the Contour panel to match the
            % height and width of the Container panel.
            position = this.InnerPosition;
            
            this.HMessagePanel.Position = position;
            set(this.HImplementationPanel, 'Position', ...
                sftoolgui.util.adjustControlPosition(this.HImplementationPanel, position));
        end
        
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
        function requestedLimitsPostSetAction(this, ~, ~)
            % requestedLimitsPostSetAction   Perform actions in response to the requested
            % limits of the axes being changed.
            
            % When the axes limits are requested to change, the limits in the axes need to be
            % changed by setting the limits in the AxesViewModel.
            % requestedLimitsPostSetAction sets AxesViewModel limits
            limits = get( this.HAxes, 'RequestedLimits' );
            xlim = limits{1};
            ylim = limits{2};
            setLimits( this.AxesViewModel, {xlim, ylim}, [],  [] );
        end
        
        function dataUpdatedAction(this, ~, ~)
            % function dataUpdatedAction(this, source, event)
            updateLabels(this);
        end
        
        function createListeners(this)
            % createListeners adds various listeners
            this.createListener( this.HFitdev,       'FittingDataUpdated',    @this.dataUpdatedAction );
            this.createListener( this.HFitdev,       'ValidationDataUpdated', @this.dataUpdatedAction );
            this.createListener( this.AxesViewModel, 'LimitsChanged',         @this.limitsChangedAction );
            this.createListener( this.HFitdev,       'DimensionChanged',      @this.dimensionChangedAction );
            this.createListener( this.HAxes,         'RequestedLimits',       @this.requestedLimitsPostSetAction);
            
        end
        
        function dimensionChangedAction(this, ~, ~)
            % function dimensionChangedAction(this, src, event)
            % dimensionChangedAction sets the panel visibility.
            
            % Set panel visibility
            setVisible(this);
        end
        
        function limitsChangedAction(this, ~, ~)
            % function limitsChangedAction(this, source, event)
            % limitsChangedAction updates the limits
            updateLimits(this);
        end
        
        function updateLimits(this)
            % updateLimits updates the axes limits with axesViewModel
            % values if curve data is not specified.
            avm = this.AxesViewModel;
            if ~isCurveDataSpecified(this.HFitdev.FittingData)
                xlim = avm.XInputLimits;
                ylim = avm.YInputLimits;
                zlim = avm.ResponseLimits ;
                % Contour plots must have 0 in the Z range
                zlim(1) = min(zlim(1), -1);
                zlim(2) = max(zlim(2), 1);
                set(this.HAxes, 'XLim', xlim, 'YLim', ylim, 'ZLim', zlim);
            end
        end
        
        function createGraphics(this)
            % createGraphics   Create graphics (axes and children) for SurfacePanel.
            
            % If the graphics haven't been created ...
            if ~this.Created
                % ... then create them all.
                this.Created = true;
                
                % Create the Axes
                this.HAxes = iCreateAxes( this.HImplementationPanel );
                
                % Create the contour
                this.HContours = curvefit.gui.FunctionContour( this.HAxes );
                
                % Setup the exclusion plotter
                this.ExclusionRulePlotter.VariablesToIgnore = {'z'};
                this.ExclusionRulePlotter.Axes = this.HAxes;
                
                % Create the lines
                createTheLines( this );
                
                % Create listeners
                createListeners( this );
                
                % Update the limits
                updateLimits( this );
                
                % Update the labels
                updateLabels( this );
                
                % Set the visibility
                setVisible( this );
                
                % Plot
                callPlotDataLineWithExclusions( this );
                callPlotValidationLine( this );
                plotSurface( this );
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
        
        function createTheLines(this)
            % createTheLines    Create data, exclusion and validation lines
            this.HFittingDataLine = sftoolgui.util.lineOfPoints( ...
                this.HAxes, 'SurfaceFittingDataLine', 'inclusion' );
            
            this.HFittingExclusionLine = sftoolgui.util.lineOfPoints( ...
                this.HAxes, 'SurfaceFittingExclusionDataLine', 'exclusion' );
            
            this.HValidationDataLine = sftoolgui.util.lineOfPoints( ...
                this.HAxes, 'SurfaceValidationDataLine', 'validation' );
            
            this.HFittingExclusionRuleLine = sftoolgui.util.lineOfPoints( ...
                this.HAxes, 'SurfaceFittingExclusionRuleDataLine', 'exclusionRule' );
        end
        
        function setVisible(this)
            % setVisible sets the Visible property of the Message and
            % Contour panel depending on whether or not curve data is
            % specified.
            tf = isCurveDataSpecified(this.HFitdev.FittingData);
            this.HMessagePanel.Visible = sftoolgui.util.booleanToOnOff( tf );
            set(this.HImplementationPanel, 'Visible', sftoolgui.util.booleanToOnOff( ~tf ));
        end
        
        function plotDataLine(~, dLine, values, displayName)
            %plotDataLine(this, dLine, values, displayName)
            % set z values to zero so that all points will show up on the
            % Contour plot.
            values{3} = zeros(size(values{3}));
            iPlotDataLine(dLine, values, displayName);
        end
    end
end

function iClearDataLine(dLine)
set(dLine, 'XData', [], 'YData', [], 'ZData', []);
end

function iPlotDataLine(dLine, values, displayName)

% Set non-NaN Z-values to zero so that all points will show up on the Contour
% plot.
values{3}(~isnan( values{3} )) = 0;

set(dLine, 'XData', values{1}, 'YData', values{2}, ...
    'ZData', values{3}, 'DisplayName', displayName);
end

function anAxes = iCreateAxes( parent )
% iCreateAxes   Create axes suitable for contour plotting
%
% Axes for contour plotting should be 2d and no support rotation.
anAxes = sftoolgui.util.createAxes( parent, 'sftool contour axes' );

% Display the grid in front of the contours
set( anAxes, 'Layer', 'top' );

% Set the view angle to the 2d view.
view( anAxes, sftoolgui.util.DefaultViewAngle.TwoD );

% Don't allow Rotate3D on the contour plot.
behavior = hggetbehavior( anAxes, 'Rotate3d' );
set( behavior, 'Enable', false );
end
