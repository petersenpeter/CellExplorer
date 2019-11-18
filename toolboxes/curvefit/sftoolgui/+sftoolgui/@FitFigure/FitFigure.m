classdef FitFigure < sftoolgui.Figure
    %FitFigure Surface Fitting Tool Fit Figure
    
    %   Copyright 2008-2013 The MathWorks, Inc.
    
    events
        SessionChanged
    end
    
    events (NotifyAccess = private)
        %GridStateChanged-- fired when GridState property is changed
        GridStateChanged
        %LegendStateChangedEvent-- fired when LegendOn property is changed
        LegendStateChanged
        %PlotVisibilityStateChanged-- fired when plot panels Visible
        %properties are changed
        PlotVisibilityStateChanged
    end
    
    properties
        HFitdev ;
        FitUUID ;
        HSurfacePanel ;
        HResidualsPanel ;
        HFittingPanel ;
        HResultsPanel ;
        HContourPanel ;
        OtherPredictionBounds = '95';
        HLimitSpinnersDialog ;
        AxesViewModel ;
    end
    
    properties(AbortSet)
        LegendOn = true;
        GridState = 'on';
    end
    
    properties (Dependent = true, SetAccess = private)
        Configuration ;
    end
    
    properties(SetAccess = 'private')
        HNoDataPanel ;
        HPlotPanel ;
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        PlotPanels ;
        UseDataFromMenu ;
        HExclusionRuleDialog ;
    end
    
    methods
        function this = FitFigure(sftool, hFitdev, config)
            %FITFIGURE Constructor for the surface fitting tool fit
            %figure
            %
            %   H = FITFIGURE
            this = this@sftoolgui.Figure(sftool);
            
             % create the AxesViewModel
            this.AxesViewModel = sftoolgui.AxesViewModel();
            
            % Store the Fitdev
            this.HFitdev = hFitdev;
            this.FitUUID = hFitdev.FitID;
            
            % Create listeners to Fitdev
            this.createListener(hFitdev, 'FitTypeFitValuesUpdated', @(s, e) this.updateFitTypeValues());
            this.createListener(hFitdev, 'FittingDataUpdated',      @(s, e) this.updateFittingData());
            this.createListener(hFitdev, 'FittingDataUpdated',      @(s, e) this.setNoDataVisible());
            this.createListener(hFitdev, 'ValidationDataUpdated',   @(s, e) this.updateValidationData());
            this.createListener(hFitdev, 'ValidationDataUpdated',   @(s, e) this.setNoDataVisible());
            this.createListener(hFitdev, 'FitUpdated',              @(s, e) this.fitUpdated());
            this.createListener(hFitdev, 'FitNameUpdated',          @(s, e) this.fitNameUpdated());
            this.createListener(hFitdev, 'ExclusionsUpdated',       @(s, e) this.updateExclusions());
            
            % Create panels
            this = iCreatePanels(this);
            
            iMakeFigureGood(this);
            setNoDataVisible(this);
            
            initialiseDataCursorManager(this);
            
            updateFittingData(this);
            updateValidationData(this);
            if ~isempty(config)
                updateFitFigure(this, config);
            end
            if isFitted(this.HFitdev)
                fitUpdated(this);
            end
            
            this.resize();
            
            % Now that we're ready, set visible on
            set(this.Handle, 'Visible', 'on');
        end

        function config = get.Configuration(this)
            config = sftoolgui.FitFigureConfiguration(this.FitUUID);
            config.LegendOn = this.LegendOn;
            config.Grid = this.GridState;
            
            config.FittingConfig = sftoolgui.FittingConfiguration;
            config.FittingConfig.Visible = this.HFittingPanel.Visible;
            
            config.ResidualsConfig = sftoolgui.ResidualsConfiguration;
            config.ResidualsConfig.Visible = this.HResidualsPanel.Visible;
            
            config.ResultsConfig = sftoolgui.ResultsConfiguration;
            config.ResultsConfig.Visible = this.HResultsPanel.Visible;
            
            config.SurfaceConfig = sftoolgui.SurfaceConfiguration;
            config.SurfaceConfig.Visible = this.HSurfacePanel.Visible;
            config.SurfaceConfig.PredictionLevel = this.HSurfacePanel.PredictionLevel;
            
            config.ContourConfig = sftoolgui.SurfaceConfiguration;
            config.ContourConfig.Visible = this.HContourPanel.Visible;
        end
        
        function set.GridState (this, value)
            if ~(strcmpi(value, 'on') || strcmpi(value, 'off'))
                error(message('curvefit:FitFigure:InvalidGridStateValue'));
            end
            this.GridState = value;
            notify(this, 'GridStateChanged');
            notify(this, 'SessionChanged');
            updateGrids(this);
        end
        
        function set.LegendOn (this, value)
            if ~islogical(value)
                error(message('curvefit:FitFigure:InvalidLegendOnValue'));
            end
            this.LegendOn = value;
            notify(this, 'LegendStateChanged');
            notify(this, 'SessionChanged');
            updateLegends(this);
        end
    end
    
    methods(Access = public)
        generateMCode(this, mcode);
        printToFigure(this, printToFigureTarget);
        updateFitFigure(this, config);
        delete(this);
        resize(this);
    end
    
    methods(Hidden)
        % updateValidationData is public for testing purposes.
        updateValidationData(this);
    end
    
    methods(Access = protected)
        tf = isAssociatedFit(this, fit);
    end
    
    methods(Access = private)
        adjustmenu(this);
        createToolbar(this);
        fitFigureDeleteFcn(this, src, event);
        fitUpdated(this);
        fitNameUpdated(this);
        n = numberOfVisiblePlots(this);
        plotFitAndResids(this);
        plotFittingData(this);
        plotValidationData(this);
        setNoDataVisible(this);
        showAxisLimitsDialog(this, src, event);
        showExclusionRulePanel(this, src, event);
        toggleExcludeMode(this, src, event);
        toggleGridState(this, src, event);
        toggleLegendState(this, src, event);
        toggleProperty(this, property);
        updateFittingData(this);
        updateFitTypeValues (this);
        updateGrids(this);
        updateInformationPanel(this);
        updateLegends(this);
        updatePlotControls(this, controls, selectedProperty);
        updateResultsArea(this);
        initialiseDataCursorManager(this);
    end
end

function this = iCreatePanels(this)
% iCreatePanels creates the plot panels, a panel container for them and a
% "no data" panel.

% Create the "container" for plot panels.
this.HPlotPanel = sftoolgui.PlotLayoutPanel(this.Handle);
this.HPlotPanel.Tag = 'sftoolPlotUIPanel';

% Create the plot panels
this.HSurfacePanel = sftoolgui.SurfacePanel(this, this.HPlotPanel.HUIPanel);
this.HSurfacePanel.Visible = 'off';
this.HResidualsPanel = sftoolgui.ResidualsPanel(this, this.HPlotPanel.HUIPanel);
this.HResidualsPanel.Visible = 'off';
this.HContourPanel = sftoolgui.ContourPanel(this, this.HPlotPanel.HUIPanel);
this.HContourPanel.Visible = 'off';

this.HPlotPanel.setPanels(this.HSurfacePanel, this.HResidualsPanel, this.HContourPanel);

% The order of the panels here determines the order the panels will show up
% in the menu and on the toolbar
this.PlotPanels = {this.HSurfacePanel, this.HResidualsPanel, ...
    this.HContourPanel};

% Create the "No Data" panel
this.HNoDataPanel = sftoolgui.MessagePanel(this.Handle, ...
    message('curvefit:sftoolgui:SelectDataToFitCurvesOrSurfaces'));
this.HNoDataPanel.Visible = 'on';

this.HFittingPanel = sftoolgui.EditFitPanel(this.Handle, ...
    this.HFitdev, this.FitUUID, this);
this.HFittingPanel.Tag = 'FittingUIPanel';

this.HResultsPanel = sftoolgui.InfoAndResultsPanel(this.Handle);
this.HResultsPanel.Tag = 'ResultsUIPanel';

this.HLimitSpinnersDialog = sftoolgui.LimitSpinnersDialog(this);

this.HExclusionRuleDialog = sftoolgui.ExclusionRulesDialog(this.HFitdev.ExclusionRules);
end

function iMakeFigureGood(this)
% iMakeFigureGood
figH = this.Handle;

set(figH, 'Name', this.HFitdev.FitName);

createToolbar(this);
adjustmenu(this);
end
