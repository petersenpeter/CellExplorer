classdef FunctionLine < curvefit.Handle & curvefit.ListenerTarget
    % FunctionLine   An HG representation of a curve fit object
    %
    %   A FunctionLine is wrapper around an HG line. This HG line is a plot of a
    %   curve fit object and will respond to changes in that fit object or to changes
    %   in the axes limits.
    %
    %   Example:
    %       % Fit a curve to data
    %       load hahn1
    %       plot( temp, thermex, '.' );
    %       fo = fit( temp, thermex, 'rat32', 'normalize', 'on', 'start', ones( 6, 1 ) );
    %       
    %       % Create a function line attached to the current axes (GCA)
    %       h = curvefit.gui.FunctionLine( gca );
    %       
    %       % Setting the FitObject property produces a plot
    %       h.FitObject = fo;
    %       
    %       % View prediction bounds
    %       h.PredictionBounds = 'on';
    %       
    %       % Changing the Fit Object in the Function surface also causes the
    %       % plot to update
    %       fo = fit( temp, thermex, 'smoothingspline', 'normalize', 'on', 'SmoothingParam', 0.99951 );
    %       h.FitObject = fo;
    %
    %   Example with function handle rather than fit object:
    %       clf
    %       xlim( [-pi, pi] );
    %       f = @(x) tan( sin( x ) ) - sin( tan( x ) );
    %       h = curvefit.gui.FunctionLine( gca );
    %       h.FitObject = f;
    %       % Use "plot tools" to zoom in on the noisy part of the plot.
    %       % 
    %       % With function handle, prediction bounds don't work: 
    %       h.PredictionBounds = 'on';
    %
    %   See also curvefit.gui.FunctionSurface, curvefit.gui.FunctionContour
    
    %   Copyright 2010-2013 The MathWorks, Inc.
    
    %% Properties
    properties(Constant, Access = 'private')
        % GRANULARITY   The number of points to add the user provided XData
        % to generate the XData for plotting.
        GRANULARITY = 293;
    end
    properties(SetAccess = 'private', GetAccess = 'private')
        % LineListeners  Listeners on the main line and the upper and
        % lower bounds.
        LineListeners
    end
    properties(SetAccess = 'private', GetAccess = ?cftool.BoundedFunctionLine)
        % MainLine   This is the line object that we are wrapping up. We
        % will use the function to redraw it in response changes in the
        % view, e.g., in response to changes in the axes limits.
        MainLine
        % LowerLine   A line that shows lower bounds on predictions using
        % the function.
        LowerLine
        % UpperLine   A line that shows upper bounds on predictions using
        % the function.
        UpperLine
    end
    properties(SetAccess = 'public', GetAccess = 'public', Dependent)
        % DisplayName   This is the name that will get used if the line is displayed in a
        % legend.
        DisplayName
        % LineWidth   The width of the line
        LineWidth
        % LineStyle   The style of the line
        LineStyle
        % Color   The color of the line
        Color
    end
    properties(SetAccess = 'public', GetAccess = 'public')
        % FitObject   This is the curve fit object that this FunctionLine
        % is a representation of.
        FitObject = [];
        % XData   These are "special points" added to the lines plotted.
        % They are usually the x-data from the fit.
        XData = [];
        % PredictionBounds   Option to turn 'on' or 'off' the plotting of
        % prediction bounds of the curve
        PredictionBounds = 'off';
        % PredictionBoundsOptions   Options for computing the prediction
        % bounds.
        PredictionBoundsOptions = curvefit.PredictionIntervalOptions;
    end
    
    %% Get and set methods
    methods
        function name = get.DisplayName( obj )
            % get.DisplayName   Get the DisplayName
            
            % The DisplayName is stored in the MainLine
            name = get( obj.MainLine, 'DisplayName' );
        end
        function set.DisplayName( obj, name )
            % set.DisplayName   Set the DisplayName
            
            % The DisplayName is stored in the MainLine
            set( obj.MainLine,  'DisplayName', name );
            
            % We also need to update the DisplayName of lower bound with a
            % string derived from the DisplayName.
            set( obj.LowerLine, 'DisplayName', getString(message('curvefit:curvefit:PredictionBoundsLegendEntry', name )) );
        end
        
        function linewidth = get.LineWidth( obj )
            linewidth = get( obj.MainLine, 'LineWidth' );
        end
        function set.LineWidth( obj, linewidth )
            set( obj.MainLine, 'LineWidth',  linewidth );
        end
        
        function linestyle = get.LineStyle( obj )
            linestyle = get( obj.MainLine, 'LineStyle' );
        end
        function set.LineStyle( obj, linestyle )
            set( obj.MainLine, 'LineStyle',  linestyle );
        end
        
        function color = get.Color( obj )
            % get.Color   Get the color of a FunctionLine
            
            % The Color is a dependent property of the MainLine
            color = get( obj.MainLine, 'Color' );
        end
        function set.Color( obj, color )
            % set.Color   Set the color of a FunctionLine
            
            % The Color is a dependent property of the MainLine
            set( obj.MainLine, 'Color', color );

            % When we set the color of the main line we also need to set
            % the color of the bounds.
            set( obj.LowerLine, 'Color', color );
            set( obj.UpperLine, 'Color', color );
        end
        
        function set.FitObject( obj, fo )
            % set.FitObject   Set the FitObject
            obj.FitObject = fo;
            % Setting the FitObject requires that the line be redrawn.
            redraw( obj );
        end
        
        function set.XData( obj, xdata )
            % set.XData   Set the XData
            
            % Ensure that the XData is a row.
            obj.XData = xdata(:).';
            % Setting the XData requires that the line be redrawn.
            redraw( obj );
        end
        
        function set.PredictionBounds( obj, value )
            if ischar( value ) && ismember( value, {'on', 'off'} )
                obj.PredictionBounds = value;
                redraw( obj );
            else
                error(message('curvefit:FunctionLine:InvalidPredictionBounds'));
            end
        end
        
        function set.PredictionBoundsOptions( obj, value )
            if isa( value, 'curvefit.PredictionIntervalOptions' )
                obj.PredictionBoundsOptions = value;
                redraw( obj );
            else
                error(message('curvefit:FunctionLine:PredictionBoundsOptions'));
            end
        end
    end
    
    %% Public Methods
    methods
        function obj = FunctionLine( hAxes )
            % FunctionLine   Construct a FunctionLine.
            %
            %   curvefit.gui.FunctionLine( hAxes ) constructs a FunctionLine that uses the given
            %   axes, hAxes, to plot in.
            %
            %   See also curvefit.gui.FunctionSurface
            narginchk( 1, 1 );
            
            % Create lines
            obj.MainLine  = iCreateLine( hAxes, 'curvefit.gui.FunctionLine.MainLine' );
            obj.LowerLine = iCreateLine( hAxes, 'curvefit.gui.FunctionLine.LowerLine' );
            obj.UpperLine = iCreateLine( hAxes, 'curvefit.gui.FunctionLine.UpperLine' );
            
            % The lower and upper bounds should be dashed.
            set( obj.LowerLine, 'LineStyle', '--' );
            set( obj.UpperLine, 'LineStyle', '--' );
            
            % The main line and lower bound should be represented on the legend when they
            % have data, but the upper line should NEVER be represented there.
            curvefit.gui.makeAutoLegendable( obj.MainLine );
            curvefit.gui.makeAutoLegendable( obj.LowerLine );
            curvefit.gui.setLegendable( obj.UpperLine, false );
            
            % Create Listeners
            createAxesListeners( obj );
            createLineListeners( obj );            
        end
        
        function delete( obj )
            % DELETE   Delete a FunctionLine
            %   DELETE( H ) deletes the Function Line H including the HG
            %   lines that it holds.
            
            % Delete the line listeners so that we don't get into a "deletion loop"
            cellfun( @delete, obj.LineListeners );
            
            % Delete the HG surfaces
            delete( obj.MainLine );
            delete( obj.LowerLine );
            delete( obj.UpperLine );
        end
        
        function printToFigure( obj, target )
            % printToFigure   Print a FunctionLine to a figure
            %
            %   printToFigure( aFunctionLine, target ) "prints" a copy of a FunctionLine to
            %   the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            if ~isempty( obj.FitObject )
                target.addLine( obj.MainLine );
                if strcmpi( obj.PredictionBounds, 'on' )
                    target.addLine( obj.LowerLine );
                    target.addLine( obj.UpperLine, 'Legendable', false );
                end
            end
        end
    end
    
    %% Private methods
    methods(Access = 'private')
        function redraw( obj, ~, ~ )
            % redraw   Redraw the FunctionLine based on the current
            % FitObject and axes limits.
            %
            %   REDRAW( OBJ, SRC, EVT )
            hAxes = get( obj.MainLine, 'Parent' );
            xlim = get( hAxes, 'XLim' );
            
            % The XData to use for the lines is the union of the XData
            % provided by the user and some linearly spaced points.
            xdata =  sort( [
                linspace( xlim(1), xlim(2), obj.GRANULARITY ), ...
                obj.XData
                ] );
            
            warnState = warning('off', 'all');
            cleanupObj = onCleanup(@() warning(warnState));
            if isempty( obj.FitObject )
                ydata = [];
                lowerBound = [];
                upperBound = [];
                
            elseif strcmpi( obj.PredictionBounds, 'on' )
                [ydata, lowerBound, upperBound] = iPredictionBounds( obj.FitObject, xdata, ...
                    obj.PredictionBoundsOptions );
                
            else
                ydata = feval( obj.FitObject, xdata(:) );
                ydata = ydata(:).';
                lowerBound = [];
                upperBound = [];
            end
            
            iSetXYData( obj.MainLine,  xdata, ydata );
            iSetXYData( obj.LowerLine, xdata, lowerBound );
            iSetXYData( obj.UpperLine, xdata, upperBound );
        end
        
        function createLineListeners( obj )
            obj.LineListeners = {
            obj.createListener( obj.MainLine,  'ObjectBeingDestroyed', @obj.deleteCallback )
            obj.createListener( obj.LowerLine, 'ObjectBeingDestroyed', @obj.deleteCallback )
            obj.createListener( obj.UpperLine, 'ObjectBeingDestroyed', @obj.deleteCallback )
                };
        end
        
        function createAxesListeners( obj )
            hAxes = get( obj.MainLine, 'Parent' );
            obj.createListener( hAxes, 'XLim', @obj.redraw );
        end
        
        function deleteCallback( obj, ~, ~ )
            % deleteCallback   Callback function for deletion events
            %
            %   deleteCallback( obj, src, evt )
            delete( obj );
        end
    end
end

%% Internal Functions
function [yi, lb, ub] = iPredictionBounds( fitObject, xi, options )
% iPredictionBounds   Evaluate the fit object and bounds
try
    [ci, zi] = predint( fitObject, xi, ...
        options.Level, options.Interval, options.Simultaneous );
    
    lb = reshape( ci(:,1), size( xi ) );
    ub = reshape( ci(:,2), size( xi ) );
    yi = reshape( zi,      size( xi ) );
catch ME
    % We are looking to catch errors in PREDINT caused by an inability of
    % the fit object to compute bounds
    if  strcmp( ME.identifier, 'curvefit:predint:cannotComputePredInts' ) ...
            || strcmp( ME.identifier, 'curvefit:predint:missingInfo' ) ...
            || strcmp( ME.identifier, 'curvefit:predint:cannotComputeConfInts' );
        yi = feval( fitObject, xi );
        lb = [];
        ub = [];
    else
        rethrow( ME );
    end
end
end

function iSetXYData( h, xdata, ydata )
% iSetXYData   Set the X- and Y-data on a line
%
% The Y-data may be empty, in which case the X-data will also be set to
% empty.
if isempty( ydata )
    set( h, 'XData', [], 'YData', [] );
else
    ydata = curvefit.nanFromComplexElements( ydata );
    set( h, 'XData', xdata, 'YData', ydata );
end
end

function hLine = iCreateLine( parent, tag )
% iCreateLine   Create a line with the given parent and tag.
hLine = line( 'Parent', parent, 'Tag', tag, ...
    'XData', [], 'YData', [], 'ZData', [], ...
    'XLimInclude', 'off' );

curvefit.gui.setPickableParts(hLine, 'off');
end
