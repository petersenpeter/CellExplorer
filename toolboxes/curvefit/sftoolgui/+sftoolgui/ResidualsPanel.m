classdef ResidualsPanel < sftoolgui.Panel
    %ResidualsPanel   A panel used by SFTOOL for residuals
    %
    %   panel = sftoolgui.ResidualsPanel(fitFigure, parent)
    %
    % This panel can be constructed with a user specified
    % ExclusionRulePlotter:
    %
    %   panel = sftoolgui.ResidualsPanel(fitFigure, parent, 'ExclusionRulePlotter', myPlotter)
    
    %   Copyright 2008-2014 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'public')
        HFitFigure ;
    end
    
    properties(Access = 'private')
        % Created   Flag to indicate if the "graphics" have been created.
        Created = false;
        
        % ReferencePlane   A plane showing where z=0 for surface plots
        ReferencePlane
        
        % ReferenceLine   A line showing where y=0 for curve plots
        ReferenceLine
        
        % Plotter for exclusion rules
        ExclusionRulePlotter;
    end
    properties(SetAccess = 'private', GetAccess = 'public')
        HAxes ;
        HFitdev ;
        HResidualsPlot ;
        HResidualsLineForExclude ;
        HValidationDataPlot ;
        HExclusionPlot;
        HExclusionRulePlot;
    end
    methods
        % The "get" methods for the graphics properties are all the same. They first need
        % to ensure that the graphics are created and then return the value of the
        % appropriate property.
        function v = get.HAxes( this )
            createGraphics( this );
            v = this.HAxes;
        end
        function v = get.HResidualsPlot( this )
            createGraphics( this );
            v = this.HResidualsPlot;
        end
        function v = get.HResidualsLineForExclude( this )
            createGraphics( this );
            v = this.HResidualsLineForExclude;
        end
        function v = get.HValidationDataPlot( this )
            createGraphics( this );
            v = this.HValidationDataPlot;
        end
        function v = get.HExclusionPlot( this )
            createGraphics( this );
            v = this.HExclusionPlot;
        end
        function v = get.HExclusionRulePlot( this )
            createGraphics( this );
            v = this.HExclusionRulePlot;
        end
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % AxesViewController is an sftoolgui.AxesViewController
        AxesViewController;
        % AxesViewModel is the sftoolgui.AxesViewModel
        AxesViewModel;
    end
    
    properties (Constant);
        Icon = 'residualSMALL.png';
        % Description is used as the toolbar button tooltip
        Description = getString(message('curvefit:sftoolgui:toolTip_ResidualsPlot'));
        % Name is used as the menu label
        Name = getString(message('curvefit:sftoolgui:menu_ResidualsPlot'));
    end
    
    methods
        function this = ResidualsPanel(fitFigure, parent, varargin)
            this = this@sftoolgui.Panel(parent);
            
            this.ExclusionRulePlotter = sftoolgui.parsePanelInputs(fitFigure.HFitdev, varargin{:});
            
            this.HFitdev = fitFigure.HFitdev;
            this.HFitFigure = fitFigure;
            this.AxesViewModel = fitFigure.AxesViewModel;
            
            this.Tag = 'ResidualUIPanel';
        end
        
        function updateGrid(this)
            set(this.HAxes, 'XGrid', this.HFitFigure.GridState);
            set(this.HAxes, 'YGrid', this.HFitFigure.GridState);
            set(this.HAxes, 'ZGrid', this.HFitFigure.GridState);
        end
        
        function plotDataLineWithExclusions(this)
            updatePlot(this);
        end
        
        function updateLabels(this)
            % updateLabels updates axes labels
            
            [xLabel, yLabel, zLabel] = getDominantLabels(this.HFitFigure.HFitdev);
            
            set( get( this.HAxes, 'XLabel' ), 'String', xLabel);
            set( get( this.HAxes, 'YLabel' ), 'String', yLabel);
            set( get( this.HAxes, 'ZLabel' ), 'String', zLabel);
        end

        function updateLegend(this, state)
            hFitdev = this.HFitFigure.HFitdev;
            fitObject = hFitdev.Fit;
            if state && ~isempty(fitObject)
                curvefit.gui.setLegendable( this.HResidualsPlot, true );
                
                haveValidationData = isValidationDataValid( hFitdev );
                curvefit.gui.setLegendable( this.HValidationDataPlot, haveValidationData );
                
                anyPointsExcluded = ~isempty( hFitdev.Exclusions ) && any( hFitdev.Exclusions );
                anyPointsExcludedByRule = any( hFitdev.ExclusionsByRule );
                
                curvefit.gui.setLegendable( this.HExclusionPlot, anyPointsExcluded );
                curvefit.gui.setLegendable( this.HExclusionRulePlot, anyPointsExcludedByRule );
            end
            if this.Created
                sftoolgui.util.refreshLegend(this.HAxes, state && ~isempty(fitObject));
            end
        end
        
        function plotResiduals(this)
            updatePlot(this);
            updateLegend(this, this.HFitFigure.LegendOn);
        end
        
        function updateDisplayNames(this)
            hFitdev = this.HFitFigure.HFitdev;
            set(this.HResidualsPlot, 'DisplayName', getString(message('curvefit:sftoolgui:displayName_Residuals', hFitdev.FitName)));
            set(this.HExclusionPlot, 'DisplayName', getString(message('curvefit:sftoolgui:DisplayNameExcluded', hFitdev.FittingData.Name)));
            set(this.HValidationDataPlot, 'DisplayName', getString(message('curvefit:sftoolgui:displayName_ValidationResiduals', hFitdev.FitName)));
            set(this.HExclusionRulePlot, 'DisplayName', getString(message('curvefit:sftoolgui:DisplayNameExcludedByRule', hFitdev.FittingData.Name)));
        end
        
        function plotValidationData(this)
            updatePlot(this);
            updateLegend(this, this.HFitFigure.LegendOn);
        end
        
        function dataUpdatedAction(this, ~, ~)
            % function dataUpdatedAction(this, source, event)
            updateLabels(this);
        end
        
        function createListeners(this )
                this.createListener( this.HFitFigure.HFitdev, 'FittingDataUpdated', @this.dataUpdatedAction );
                this.createListener( this.HFitFigure.HFitdev, 'ValidationDataUpdated', @this.dataUpdatedAction );
                this.createListener( this.AxesViewModel, 'LimitsChanged', @this.limitsChangedAction );
                this.createListener( this.HFitFigure.HFitdev, 'DimensionChanged',  @this.dimensionChangedAction );
                this.createListener( this.HAxes, 'RequestedLimits', @this.requestedLimitsPostSetAction );
        end
        
        function dimensionChangedAction(this, ~, ~)
            % function dimensionChangedAction(this, src, event)
            % dimensionChangedAction updates the axesViewController's
            % View2D property.
            this.AxesViewController.View2D = this.isCurveData();
            
            this.updateExclusionRulePlotterDimension();
        end
        
        function tf = canGenerateCodeForPlot(this)
            % canGenerateCodeForPlot   True if code can be generated
            %
            %    canGenerateCodeForPlot( this ) returns true if code can be
            %    generated for residual plots and false otherwise. Code can
            %    be generated for residuals plots if the panel is visible.
            
            tf = strcmpi( this.Visible, 'on' );
        end
        
        function clearSurface(this)
            % clearSurface clears the plot when the curve or surface fit changes.
            
            setResidualData(this, [], [], []);
            setValidationResidualData(this, [], [], []);
            setExclusionData(this, [], [], []);
            setExclusionByRuleData(this, [], [], []);
            setResidualLineForExclude(this, [], [], []);
        end
        
        function generateMCode( this, mcode )
            % GENERATEMCODE   Generate code for a Residuals Panel
            %
            %    GENERATEMCODE( H, CODE ) generates code for the given
            %    residuals panel, H, and adds it the code object CODE.
            
            if this.isCurveData()
                cg = sftoolgui.codegen.CurveResidualPlotCodeGenerator();
                
                xValues = getValues( this.HFitFigure.HFitdev.FittingData );
                cg.HasXData = ~isempty( xValues );
            else
                cg = sftoolgui.codegen.SurfaceResidualPlotCodeGenerator();
                [cg.View(1), cg.View(2)] = view( this.HAxes );
            end
            
            cg.FitName            = this.HFitFigure.HFitdev.FitName;
            cg.FittingDataName    = this.HFitFigure.HFitdev.FittingData.Name;
            cg.ValidationDataName = this.HFitFigure.HFitdev.ValidationData.Name;
            cg.HaveLegend         = ~isempty(get(this.HAxes,'Legend'));
            cg.HaveExcludedData   = this.HFitdev.HasExclusions;
            cg.HaveValidation     = isValidationDataValid(this.HFitFigure.HFitdev);
            cg.GridState          = this.HFitFigure.GridState;
            generateMCode( cg, mcode );
        end
        
        function printToFigure( this, target )
            % printToFigure   Print a Residuals Panel to a figure
            %
            %   printToFigure( aResidualsPanel, target ) "prints" the contents of a Residuals
            %   Panel to the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            target.addAxes( this.HAxes );
            target.add( 'Stem3', this.HResidualsPlot );
            if this.isCurveData()
                target.add( 'Line', this.ReferenceLine, 'Legendable', false );
            else
                target.add( 'Patch', this.ReferencePlane, 'Legendable', false );
            end
            if any( this.HFitFigure.HFitdev.Exclusions );
                target.add( 'Stem3', this.HExclusionPlot );
            end
            if any( this.HFitFigure.HFitdev.ExclusionsByRule );
                target.add( 'Stem3', this.HExclusionRulePlot );
            end
            if isValidationDataValid( this.HFitFigure.HFitdev );
                target.add( 'Stem3', this.HValidationDataPlot );
            end
            
            aLegend = get(this.HAxes,'Legend');
            if ~isempty( aLegend );
                target.addLegend( aLegend );
            end
        end
    end
    
    methods(Access = 'private')
        function createGraphics( this )
            % createGraphics   Create graphics (axes and children) for ResidualsPanel.
            
            % If the graphics haven't been created ...
            if ~this.Created
                % ... then create them all.
                this.Created = true;
                
                this.HAxes = sftoolgui.util.createAxes( this.HUIPanel, 'sftool residuals axes' );
                set( this.HAxes, 'NextPlot', 'add' );
                
                this.HResidualsLineForExclude = sftoolgui.util.lineForExclusion( this.HAxes, 'ResidualsLineForExclude' );
                
                this.HResidualsPlot      = iCreateResidualsPlot(  this.HAxes );
                this.HExclusionPlot      = iCreateExclusionPlot(  this.HAxes );
                this.HExclusionRulePlot  = iCreateExclusionRulePlot( this.HAxes );
                this.HValidationDataPlot = iCreateValidationPlot( this.HAxes );
                
                % Create the exclusion plotter	
                this.ExclusionRulePlotter.Axes = this.HAxes;
                updateExclusionRulePlotterDimension(this);
                
                % Plot the reference line and plane
                this.ReferencePlane = iCreateReferencePlane( this.HAxes );
                this.ReferenceLine = iCreateReferenceLine( this.HAxes );
                
                % Create an AxesViewController
                this.AxesViewController = sftoolgui.AxesViewController( ....
                    this.HAxes, this.AxesViewModel, this.isCurveData() );
                
                % Plot the residuals
                plotResiduals( this );
                
                % Create Listeners
                createListeners(this);
                
                % Update the labels
                updateLabels( this );
                
            end
        end
        
        function tf = isCurveData( this )
            % isCurveData   True if this residuals plot is for a curve fit
            tf = isCurveDataSpecified( this.HFitFigure.HFitdev.FittingData );
        end
        
        function requestedLimitsPostSetAction(this, ~, ~)
            % function requestedLimitsPostSetAction(this, source, event)
            % requestedLimitsPostSetAction sets AxesViewModel limits
            limits = get( this.HAxes, 'RequestedLimits' );
            xlim = limits{1};
            ylim = limits{2};
            zlim = limits{3};
            if this.isCurveData()
                setLimits(this.AxesViewModel, {xlim}, [], ylim);
            else
                setLimits(this.AxesViewModel, {xlim, ylim}, [], zlim);
            end
        end
        
        function updateReferencePlane(this)
            % updateReferencePlane   Update the reference line and reference plane to span
            % the limits of the axes.

            % Make the reference line span the x-limits
            xlim = get( this.HAxes, 'XLim' );
            set( this.ReferenceLine, 'XData', xlim, 'YData', [0, 0] );
            
            % Make the reference plane span the x and y-limits
            ylim = get( this.HAxes, 'YLim' );
            X = xlim([1,1,2,2,1]);
            Y = ylim([1,2,2,1,1]);
            set( this.ReferencePlane, 'XData', X, 'YData', Y, 'ZData', zeros( size( X ) ) );
            
            % For curve fits show the reference line and for surface fits show the reference
            % plane
            curveDataSpecified = this.isCurveData();
            showLine = sftoolgui.util.booleanToOnOff( curveDataSpecified  );
            showPlane = sftoolgui.util.booleanToOnOff( ~curveDataSpecified  );
            set( this.ReferenceLine,  'Visible', showLine );
            set( this.ReferencePlane, 'Visible', showPlane );
        end
        
        function updatePlot(this)
            if strcmpi(this.Visible, 'on')
                clearSurface(this);
                hFitdev = this.HFitFigure.HFitdev;
                fitObject = hFitdev.Fit;
                
                [resids, vResids] = getResiduals(hFitdev);
                % Nothing is plotting unless there is a valid fit.
                if ~isempty(fitObject)
                    if isCurveDataSpecified(hFitdev.FittingData)
                        plotCurveResiduals(this, resids, vResids)
                    else
                        plotSurfaceResiduals(this, resids, vResids)
                    end
                end
                updateDisplayNames(this);
            end
        end

        function plotCurveResiduals(this, resids, vResids)
            % Plot curve residuals
            hFitdev = this.HFitFigure.HFitdev;
            x = getCurveValues(hFitdev.FittingData);
            
            exclude = hFitdev.Exclusions;
            exclusionsByRule = hFitdev.ExclusionsByRule;
            
            [blackDots, redDots, redCrosses] = sftoolgui.exclusion.exclusionsToMarkers(exclude, exclusionsByRule);
            
            xInclude = x;
            xInclude(~blackDots) = NaN;
            yInclude = resids;
            yInclude(~blackDots) = NaN;
            setResidualData(this, xInclude, yInclude, []);
            
            xExclude = x;
            xExclude(~redCrosses) = NaN;
            yExclude = resids;
            yExclude(~redCrosses) = NaN;
            setExclusionData(this, xExclude, yExclude, []);
            
            xExcludeByRule = x;
            xExcludeByRule(~redDots) = NaN;
            yExcludeByRule = resids;
            yExcludeByRule(~redDots) = NaN;
            setExclusionByRuleData(this, xExcludeByRule, yExcludeByRule, []);
            
            setResidualLineForExclude(this, x, resids, []);
            
            if ~isempty(vResids)
                vx = getCurveValues(hFitdev.ValidationData);
                setValidationResidualData(this, vx, vResids, []);
            end
        end
        
        function plotSurfaceResiduals(this, resids, vResids)
            % Plot surface residuals
            
            hFitdev = this.HFitFigure.HFitdev;
            [x, y] = getValues(hFitdev.FittingData);
            
            exclude = hFitdev.Exclusions;
            exclusionsByRule = hFitdev.ExclusionsByRule;
            
            [blackDots, redDots, redCrosses] = sftoolgui.exclusion.exclusionsToMarkers(exclude, exclusionsByRule);
            
            xInclude = x;
            xInclude(~blackDots) = NaN;
            yInclude = y;
            yInclude(~blackDots) = NaN;
            residInclude = resids;
            residInclude(~blackDots) = NaN;
            setResidualData(this, xInclude, yInclude, residInclude);
            
            xExclude = x;
            xExclude(~redCrosses) = NaN;
            yExclude = y;
            yExclude(~redCrosses) = NaN;
            residExclude = resids;
            residExclude(~redCrosses) = NaN;
            setExclusionData(this, xExclude, yExclude, residExclude);
            
            xExcludeByRule = x;
            xExcludeByRule(~redDots) = NaN;
            yExcludeByRule = y;
            yExcludeByRule(~redDots) = NaN;
            residExcludeByRule = resids;	
            residExcludeByRule(~redDots) = NaN;	
            setExclusionByRuleData(this, xExcludeByRule, yExcludeByRule, residExcludeByRule);
            
            setResidualLineForExclude(this, x, y, resids);
                        
            if ~isempty(vResids)
                [vx, vy] = getValues(hFitdev.ValidationData);
                setValidationResidualData(this, vx, vy, vResids);
            end
        end
        
        function setResidualData(this, x, y, z)
            set(this.HResidualsPlot, ...
                'XData', x, ...
                'YData', y, ....
                'ZData', z);
        end
        
        function setExclusionData(this, x, y, z)
            set(this.HExclusionPlot, ...
                'XData', x, ...
                'YData', y, ....
                'ZData', z);
        end
        
        function setExclusionByRuleData(this, x, y, z)
            set(this.HExclusionRulePlot, ...
                'XData', x, ...
                'YData', y, ....	
                'ZData', z);
        end
        
        function setResidualLineForExclude(this, x, y, z)
            set(this.HResidualsLineForExclude, ...
                'XData', x, ...
                'YData', y, ....
                'ZData', z);
        end

        function setValidationResidualData(this, x, y, z)
            set(this.HValidationDataPlot, ...
                'XData', x, ...
                'YData', y, ...
                'ZData', z);
        end
        
        function limitsChangedAction(this, ~, ~)
            % function limitsChangedAction(this, source, event)
            % limitsChangedAction updates axes limits and the reference
            % plane
            updateLimits(this);
            
            % Save the current limit information
            resetplotview(this.HAxes, 'SaveCurrentViewLimitsOnly');
            
            % update the reference plane
            updateReferencePlane(this);
        end
        
        function updateLimits(this)
            % updateLimits updates the limits with AxesViewModel values.
            
            avm = this.AxesViewModel;
            
            xlim = avm.XInputLimits;
            if this.isCurveData()
                ylim = avm.ResidualLimits ;
                zlim = [-1 1];
            else
                ylim = avm.YInputLimits;
                zlim = avm.ResidualLimits ;
            end
            
            set(this.HAxes, 'XLim', xlim, 'YLim', ylim, 'ZLim', zlim);
        end
        
        function updateExclusionRulePlotterDimension(this)
            if this.isCurveData();
                this.ExclusionRulePlotter.VariablesToIgnore = {'y', 'z'};
            else	
                this.ExclusionRulePlotter.VariablesToIgnore = {'z'};
            end
        end
    end
    
    methods(Access = 'protected')
        function postSetVisible( this )
            % postSetVisible   When the ResidualsPanels is made visible we need to ensure that
            % the graphics are created.
            postSetVisible@sftoolgui.Panel( this );
            if isequal( this.Visible, 'on' )
                createGraphics( this );
            end
        end
    end
end

function aStem = iCreateResidualsPlot(anAxes)
aStem = iCreateStem( anAxes, 'ResidualsPlot', 'inclusion' );
end

function aStem = iCreateExclusionPlot(anAxes)
aStem = iCreateStem( anAxes, 'ResidualsExclusionPlot', 'exclusion' );

aMarker = get( aStem, 'MarkerHandle' );
set( aStem, 'LineWidth', 0.5 );
set( aMarker, 'LineWidth', 1.5 );
end

function aStem = iCreateExclusionRulePlot(anAxes)
aStem = iCreateStem( anAxes, 'ResidualsExclusionRulePlot', 'exclusionRule' );

aMarker = get( aStem, 'MarkerHandle' );
set( aStem, 'LineWidth', 0.5 );
set( aMarker, 'LineWidth', 1.5 );
end

function aStem = iCreateValidationPlot(anAxes)
aStem = iCreateStem( anAxes, 'ResidualsValidationPlot', 'validation' );
end

function aStem = iCreateStem( anAxes, tag, style )
aStem = stem3( [], [], [], 'Parent', anAxes, 'Tag', tag );

sftoolgui.util.MarkerStylist.style( aStem, style );

curvefit.gui.makeAutoLegendable( aStem );
end

function aPlane = iCreateReferencePlane(anAxes)

xlim = get( anAxes, 'XLim' );
ylim = get( anAxes, 'YLim' );

aPlane = patch( xlim([1,1,2,2,1]), ylim([1,2,2,1,1]), zeros( 1, 5 ), ...
    'Parent', anAxes, ...
    'FaceAlpha', 0.2, ...
    'FaceColor', [0.2, 0.2, 0.2], ...
    'HitTest', 'off', ...
    'Tag', 'ResidualsReferencePlane' );

% Don't (ever) show the reference plane in the legend
curvefit.gui.setLegendable( aPlane, false );
end

function aLine = iCreateReferenceLine(anAxes)
xlim = get( anAxes, 'XLim' );

aLine = line( xlim, [0, 0], ...
    'Parent', anAxes, ...
    'Color', 'k', ...
    'HitTest', 'off', ...
    'Tag', 'ResidualsReferenceLine' );

% Don't (ever) show the reference line in the legend
curvefit.gui.setLegendable( aLine, false );
end
