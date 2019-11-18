classdef LimitSpinnersDialog < curvefit.Handle & curvefit.ListenerTarget
    %Surface Fitting Tool Limit Spinners Dialog
    
    %   Copyright 2008-2012 The MathWorks, Inc.
    
    properties (SetAccess = 'private', GetAccess = 'private')
        HFitFigure ;
        JavaDialog ;
        % AxesViewModel is the sftoolgui.AxesViewModel
        AxesViewModel;
        % LimitChangedListener   listener for 'limitChanged' event. Fired when changes are made in the java dialog
        LimitChangedListener;
    end
    
    properties(Dependent = true, SetAccess = 'private')
        XLim ;
        SurfaceYLim ;
        CurveYLim ;
        ResidYLim ;
        MainZLim ;
        ResidZLim ;
    end
 
    properties (Hidden=true, SetAccess = 'private')
        % XLimStep   Step size for x limits
        XLimStep;
        % SurfaceYLimStep   Step size for y limits for surface plots
        SurfaceYLimStep ;
        % CurveYLimStep   Step size for y limits for curve plots
        CurveYLimStep ;
        % ResidYLimStep   Step size for y limits of the residual plots for curves
        ResidYLimStep ;
        % MainZLimStep   Step size for z limits for surface plots
        MainZLimStep ;
        % ResidZLimStep   Step size for s limits for residuals of surface plots
        ResidZLimStep ;
    end

    methods
        function this = LimitSpinnersDialog(hFitFigure)
            this.HFitFigure = hFitFigure;
            this.AxesViewModel = hFitFigure.AxesViewModel;
            
            this.JavaDialog = javaObjectEDT('com.mathworks.toolbox.curvefit.surfacefitting.AxesLimitsDialog');
            
            % UI events, keep hold of the limitsChanged event listener, we
            % need to disable this later
            this.createListener( this.JavaDialog, 'resetLimits', @this.resetDefaultAxisLimits );
            this.LimitChangedListener = this.createListener( this.JavaDialog, 'limitsChanged', @this.axesLimitsDialogAction );
            
            % Fitdev update events
            this.createListener(this.HFitFigure.HFitdev, 'FittingDataUpdated', @this.fittingDataUpdated );
            this.createListener(this.HFitFigure.HFitdev, 'FitNameUpdated', @this.fitNameUpdated );
            this.createListener(this.HFitFigure.HFitdev, 'DimensionChanged', @this.dimensionChangedAction );
            
            % AxesViewModel limit change event
            this.createListener(this.AxesViewModel, 'LimitsChanged', @this.updateAllLimitSpinners );
            
            % Set the title
            fitNameUpdated(this);
            
            % Set variable names
            fittingDataUpdated(this);
            
            % Make sure the correct view is showing
            dimensionChangedAction(this);
            
            % Set spinner values.
            updateAllLimitSpinners(this, [], []);
        end
        
        function show(this)
            % show makes the dialog visible
            javaMethodEDT('showDialog', this.JavaDialog);
        end
        
        function updateAllLimitSpinners(this, ~, ~)
            % function updateAllLimitSpinners(this, source, event)
            % updateAllLimitSpinners updates all the java spinner widgets
            avm = this.AxesViewModel;
            if isCurveDataSpecified(this.HFitFigure.HFitdev.FittingData)
                setValueAndStep(this, 'CurveYLim', avm.ResponseLimits);
            end
            
            setValueAndStep(this, 'XLim', avm.XInputLimits);
            setValueAndStep(this, 'SurfaceYLim', avm.YInputLimits);
            setValueAndStep(this, 'ResidYLim', avm.ResidualLimits);
            setValueAndStep(this, 'MainZLim', avm.ResponseLimits);
            setValueAndStep(this, 'ResidZLim', avm.ResidualLimits);
        end
        
        function delete(this)
            % This is the class's delete method
            javaMethodEDT('dispose', this.JavaDialog);
        end
        
        function lim = get.XLim(this)
            lim = this.AxesViewModel.XInputLimits;
        end
        
        function set.XLim(this, lim)
            this.AxesViewModel.XInputLimits = lim;
        end
        
        function lim = get.SurfaceYLim(this)
            lim = this.AxesViewModel.YInputLimits;
        end
        
        function set.SurfaceYLim(this, lim)
            this.AxesViewModel.YInputLimits = lim;
        end
        
        function lim = get.CurveYLim(this)
            lim = this.AxesViewModel.ResponseLimits;
        end
        
        function set.CurveYLim(this, lim)
            this.AxesViewModel.ResponseLimits = lim;
        end
        
        function lim = get.ResidYLim(this)
            lim = this.AxesViewModel.ResidualLimits;
        end
        
        function set.ResidYLim(this, lim)
            this.AxesViewModel.ResidualLimits = lim;
        end
        
        function lim = get.MainZLim(this)
            lim = this.AxesViewModel.ResponseLimits;
        end
        
        function set.MainZLim(this, lim)
            this.AxesViewModel.ResponseLimits = lim;
        end
        
        function lim = get.ResidZLim(this)
            lim = this.AxesViewModel.ResidualLimits;
        end
        
        function set.ResidZLim(this, lim)
            this.AxesViewModel.ResidualLimits = lim;
        end
    end
    
    methods(Access = 'private')
            
        function fittingDataUpdated(this, ~, ~)
            % function fittingDataUpdated(this, source, event)
            % fittingDataUpdated sets the spinner labels
            [xname, yname, zname] = getNames(this.HFitFigure.HFitdev.FittingData);
            javaMethodEDT('setLabels', this.JavaDialog, xname, yname, zname)
        end
        
        function dimensionChangedAction(this, ~, ~)
            % function dimensionChangedAction(this, source, event)
            % dimensionChangedAction lets the java dialog know that the
            % dimension has changed.
            if isCurveDataSpecified(this.HFitFigure.HFitdev.FittingData)
                javaMethodEDT('showDimensionView', this.JavaDialog, 2);
            else
                javaMethodEDT('showDimensionView', this.JavaDialog, 3);
            end
        end
        
        function fitNameUpdated(this, ~, ~)
            % function fitNameUpdated(this, source, event)
            % fitNameUpdated sets the title of the java dialog to match the
            % new fit name.
            title = getString(message('curvefit:sftoolgui:AxesLimits', this.HFitFigure.HFitdev.FitName));
            javaMethodEDT('setTitle', this.JavaDialog, title);
        end
        
        function resetDefaultAxisLimits(this, ~, ~)
            % function resetDefaultAxisLimits(this, source, event)
            % sets limits to the original view.
            resetToDataLimits(this.HFitFigure);
        end
        
        function axesLimitsDialogAction(this, ~, e)
            % function axesLimitsDialogAction(this, source, event)
            % axesLimitsDialogAction sets the corresponding property of the
            % spinner changed.
            curvefit.setListenerEnabled(this.LimitChangedListener, false);
            
            property = char(e.getLimitProperty());
            this.(property) = [e.getMinValue() e.getMaxValue()];
            
            curvefit.setListenerEnabled(this.LimitChangedListener, true);
        end
        
        function setValueAndStep(this, spinner, limit)
            stepProperty = [spinner, 'Step'];
            stepSize = iCalculateStep(limit);
            this.(stepProperty) = stepSize;
            % setValueAndStep sets the java spinners value and step
            javaMethodEDT('setValueAndStep', this.JavaDialog, spinner, ...
                limit(1), limit(2), stepSize);   
        end
    end
end

function step = iCalculateStep(lim)
% iCalculateStep calculates the step.

% stepAsPortionOfRange is 1% of range rounded to leading non-zero value
dx = (lim(2)-lim(1))/100;
pwr = floor(log10(dx));
stepAsPortionOfRange = 10^pwr * (round(dx/(10^pwr)));

% stepAsPortionOfScale is the smallest step representable by the limits spinner
minimumDifferenceAllowed = 0.0001;
scale = max(abs(lim));
minAllowedRange = scale*minimumDifferenceAllowed;
% Round up to have a 1 as the most significant number and 0's otherwise
pwr = floor(log10(minAllowedRange));
stepAsPortionOfScale = 10^pwr;

step = max(stepAsPortionOfRange, stepAsPortionOfScale);

end
