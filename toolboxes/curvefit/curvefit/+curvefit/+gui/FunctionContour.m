classdef FunctionContour < curvefit.Handle & curvefit.ListenerTarget
    %FunctionContour   An HG contour representation of a surface fit object
    %
    %   A FunctionContour is wrapper around an HG contour. This HG contour
    %   is a contour plot of a surface fit object and will respond to
    %   changes in that fit object or to changes in the axes limits.
    %
    %   Example:
    %       % Fit a contour to data
    %       load franke
    %       fo = fit( [x, y], z, 'poly23' );
    %
    %       % Create a function contour attached to the current axes (GCA)
    %       h = curvefit.gui.FunctionContour( gca );
    %
    %       % Setting the FitObject property produces a plot
    %       h.FitObject = fo;
    %
    %       % Changing the axes limits causes the contour plot to update
    %       set( gca, 'XLim', [683, 3045], 'Ylim', [0, 1.1] );
    %
    %       % Changing the Fit Object in the Function surface also causes
    %       % the plot to update
    %       fo = fit( [x, y], z, 'linearinterp' );
    %       h.FitObject = fo;
    %
    %   See also curvefit.gui.FunctionLine curvefit.gui.FunctionSurface
    
    %   Copyright 2011-2013 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'private', Dependent = true)
        % Parent -- This is the axes in which the contour lives. It is a
        % dependent property and is inferred from the HgContour property
        Parent
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % AxesLimitListeners -- Listeners on axes limits which call the
        % redraw method (obj.Parent).
        AxesLimitListeners
        
        % ContourListeners -- Listeners on the contour (obj.HgContour).
        ContourListeners
        
        % HgContour   This is the HG contour object that we are wrapping up
        HgContour
    end
    properties(SetAccess = 'public', GetAccess = 'public', Dependent = true)
        % DisplayName -- This is the name that will get used if the contour is
        % displayed in a legend.
        DisplayName
    end
    properties(SetAccess = 'public', GetAccess = 'public')
        % FitObject -- This is the surface fit object that this
        % FunctionContour is a representation of.
        FitObject
    end
    
    methods
        function obj = FunctionContour( hAxes )
            % FunctionContour   Create a function contour
            %
            %   curvefit.gui.FunctionContour( anAxes ) is a function contour object attached
            %   to the given axes, anAxes.
            %
            %   See also curvefit.gui.FunctionLine, curvefit.gui.FunctionSurface.
            narginchk( 1, 1 );

            obj.HgContour = iCreateContour( hAxes );
            
            % Don't display the FunctionContour on the legend
            curvefit.gui.setLegendable( obj.HgContour, false )
            
            % Set the contour group to the bottom of the stack, to ensure
            % that the points are never hidden
            uistack( double( obj.HgContour ), 'bottom');
            
            % Create Listeners
            createAxesListeners( obj );
            createAxesLimitListeners( obj );
            createContourListeners( obj )
        end
        
        function set.FitObject( obj, fo )
            obj.FitObject = fo;
            redraw( obj );
        end
        
        function hAxes = get.Parent( obj )
            hAxes = get( obj.HgContour, 'Parent' );
        end
        
        function n = get.DisplayName( obj )
            n = get( obj.HgContour, 'DisplayName' );
        end
        
        function set.DisplayName( obj, n )
            set( obj.HgContour, 'DisplayName', n );
        end
        
        function delete( obj )
            % delete
            %   DELETE( H ) deletes the Function Contour H including the HG
            %   contours that it holds. Use deleteButKeepContour if you want to
            %   keep the HG contours but delete the function contour
            %
            %   See also deleteButKeepContour.
            
            % Delete the contour listeners so that we don't get into a "deletion
            % loop"
            obj.ContourListeners = {};
            
            % Delete the HG contour
            delete( obj.HgContour );
        end
        
        function hContour = deleteButKeepContour( obj )
            % deleteButKeepContour   Delete the FunctionContour without deleting the HG contours
            %
            %   S = deleteButKeepContour( H ) deletes the Function Contour H
            %   without deleting the HG contour that it holds. Instead the HG
            %   contours are returned as the output argument S. This allows the
            %   FunctionContour to be used as a utility for plotting contours,
            %   e.g.,
            %
            %       fo = fit( [Ne, OT], Gn, 'polynomial' );
            %       % Now plot and get a regular HG surface
            %       hFS = FunctionContour( hAxes );
            %       hFS.FitObject = fo;
            %       hSurf = deleteButKeepContour( hFS );
            %
            %   S will be a handle to HG contour.
            
            % Get the HG Contour
            hContour = obj.HgContour;
            % Ensure the HG contour aren't deleted
            obj.HgContour = [];
            % Set the axis limits to respond to the contour limits
            set( hContour, 'XLimInclude', 'on', 'YLimInclude', 'on' );
            
            % Delete the FunctionContour
            delete( obj );
        end
        
        function printToFigure( obj, target )
            % printToFigure   Print a FunctionContour to a figure
            %
            %   printToFigure( FunctionContour, target ) "prints" a copy of a
            %   FunctionContour to the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            target.add( 'Contour', obj.HgContour, 'Legendable', false );
        end
        
        function setAxesLimitListenersEnabled( obj, state )
            % setAxesLimitListenersEnabled   Activate/deactivate the axes listeners that
            % redraw the FunctionContour.
            for k=1:length(obj.AxesLimitListeners)
                curvefit.setListenerEnabled( obj.AxesLimitListeners{k}, state );
            end
        end
    end
    
    methods(Access = 'private')
        function redraw( obj, ~, ~ )
            % redraw   Redraw a function contour
            %
            % Note: This method can be used as callback, i.e., the second and third arguments
            % are SRC and EVT.
            if isempty( obj.FitObject )
                % If the there is no Fit Object, then there can be no contour.
                iSetEmptyData( obj.HgContour );
            else
                % Form a grid for the contour.
                xlim = get( obj.Parent, 'XLim' );
                ylim = get( obj.Parent, 'YLim' );
                [xi, yi] = meshgrid( ...
                    linspace( xlim(1), xlim(2), 49 ), ...
                    linspace( ylim(1), ylim(2), 51 ) );
                
                % Evaluate the fit object over the grid
                zi = feval( obj.FitObject, xi, yi );
                
                % Update the contour object with the new values
                iSetXYZData( obj.HgContour, xi, yi, zi );
            end
        end
        
        function createAxesListeners( obj )
            obj.createListener( obj.Parent, 'ObjectBeingDestroyed', @obj.deleteCallback );
        end
        
        function createAxesLimitListeners( obj )
            obj.AxesLimitListeners = {
                obj.createListener( obj.Parent, 'XLim', @obj.redraw );
                obj.createListener( obj.Parent, 'YLim', @obj.redraw );
                };
        end
        
        function createContourListeners( obj )
            obj.ContourListeners = {
                obj.createListener( obj.HgContour, 'ObjectBeingDestroyed', @obj.deleteCallback )
                };
        end
        
        function deleteCallback( obj, ~, ~ )
            delete( obj );
        end
    end
end

function iSetEmptyData( h )
% iSetEmptyData   Set all the data fields to empty.
iSetXYZData( h, [], [], [] );
end

function iSetXYZData( h, xdata, ydata, zdata )
% iSetXYZData   Set the X-, Y-, and Z-data on a contour
set( h, 'XData', xdata, 'YData', ydata, 'ZData', zdata );
end

function aContour = iCreateContour( anAxes )
% iCreateContour   Create a contour plot without messing with the axes.

% Preserve "next plot".
nextPlot = get( anAxes, 'NextPlot' );
nextPlotCleaner = onCleanup( @() set( anAxes, 'NextPlot', nextPlot ) );

% We want to "add" the contour the axes without messing with the axes
set( anAxes, 'NextPlot', 'add' );

% Create the contour
[~, aContour] = contour( anAxes, [] );
set( aContour, ...
    'HitTest', 'off', ... 
    'Fill', 'on', ...
    'LineColor', 'k', ...
    'XLimInclude', 'off', 'YLimInclude', 'off', ...
    'Tag', 'curvefit.gui.FunctionContour');
curvefit.gui.setPickableParts(aContour, 'off');
end
