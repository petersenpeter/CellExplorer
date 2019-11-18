classdef(Sealed) PrintToFigureTarget < curvefit.Handle
    % PrintToFigureTarget   A target location for "printing" figures to.
    %
    %   The various add* methods take a source graphic and make a copy of the graphic
    %   in the target location (either a figure or a uipanel).
    %
    %   Example
    %       someAxes = axes();
    %       someLine = plot( someAxes, rand( 10, 1 ), rand( 10, 1 ), 'DisplayName', 'Some Line' );
    %
    %       t = curvefit.gui.PrintToFigureTarget( figure() );
    %       t.addAxes( someAxes );
    %       t.addLine( someLine );
    %       t.addLegend( someLegend );
    
    %   Copyright 2012 The MathWorks, Inc.
    
    properties(Constant, GetAccess = private)
        % Constructors   Structure of constructors for MATLAB graphics that can be
        % "printed to figure".
        Constructors = iConstructors();
        
        % Properties   Structure of properties for MATLAB graphics that need values
        % copied from the source to the target.
        Properties = iProperties();
    end
    
    properties(Access = private)
        % Parent   The parent of the target graphics. Either a uipanel or a figure.
        Parent
        
        % CurrentAxes  The most recent axes. New graphics will be added to this axes.
        CurrentAxes
    end
    
    methods
        function this = PrintToFigureTarget( aTarget )
            % PrintToFigureTarget   Construct a print-to-figure target.
            %
            %   PrintToFigureTarget( target ) converts a target uipanel or figure so that
            %   other object may "print to" the target.
            this.Parent = aTarget;
        end
        
        function subTarget = createSubTarget( this, position )
            % createSubTarget   Create a sub-target within a PrintToFigureTarget
            %
            %   p.createSubTarget( position ) creates a uipanel that is a child of the parent
            %   of the print-to-figure target p. This uipanel is then wrapped in a new
            %   PrintToFigureTarget and returned. The new panel will be at the given
            %   position with the parent.
            aPanel = uipanel( 'Parent', this.Parent, 'Position', position );
            subTarget = curvefit.gui.PrintToFigureTarget( aPanel );
        end
        
        function addAxes( this, sourceAxes )
            % addAxes   Add an axes to a PrintToFigureTarget
            %
            %   p.addAxes( anAxes ) adds a copy of an axes to the PrintToFigureTarget p.
            targetAxes = axes( 'Parent', this.Parent );
            
            properties = {'Box', 'Color', 'Layer', 'Tag', 'Units', 'View', 'XLim', 'YLim', 'ZLim',  'XGrid', 'YGrid', 'ZGrid'};
            iCopyProperties( sourceAxes, targetAxes, properties );
            
            % Copy the labels
            iCopySubProperty( sourceAxes, targetAxes, 'XLabel', 'String' );
            iCopySubProperty( sourceAxes, targetAxes, 'YLabel', 'String' );
            iCopySubProperty( sourceAxes, targetAxes, 'ZLabel', 'String' );
            
            % Copy the colormap
            colormap( targetAxes, colormap( sourceAxes ) );
            
            % We want to be able to add graphics to plot without removing any previous
            % graphics. Hence we set NextPlot to 'add'.
            set( targetAxes, 'NextPlot', 'add' );
                            
            % This new axes becomes the current axes.
            this.CurrentAxes = targetAxes;
        end
        
        function addControl( this, sourceControl )
            % addControl   Add a uicontrol to a PrintToFigureTarget
            %
            %   p.addControl( aControl ) adds a copy of a uicontrol to the PrintToFigureTarget p.
            targetControl = uicontrol( 'Parent', this.Parent );
            
            properties = {'Style', 'Position', 'HorizontalAlignment', 'FontSize', 'Units', 'BackgroundColor', 'String'};
            iCopyProperties( sourceControl, targetControl, properties );
        end
        
        function addLine( this, sourceLine, varargin )
            % addLine   Add a line to a PrintToFigureTarget
            %
            %   p.addLine( aLine ) adds a copy of a line to a PrintToFigureTarget. If a
            %   legend is added to PrintToFigureTarget, then this line will appear on the
            %   legend.
            %
            %   p.addLine( aLine, 'Legendable', false ) adds a copy of a line to a
            %   PrintToFigureTarget in such a way that the new line will not appear on a
            %   legend.
            this.add( 'Line', sourceLine, varargin{:} );
        end
        
        function addSurface( this, sourceSurface, varargin )
            % addSurface   Add a surface to a PrintToFigureTarget
            %
            %   p.addSurface( aSurface ) adds a copy of a surface to the PrintToFigureTarget.
            %   If a legend is added to PrintToFigureTarget, then this surface will appear on
            %   the legend.
            %
            %   p.addSurface( aSurface, 'Legendable', false ) adds a copy of a surface to a
            %   PrintToFigureTarget in such a way that the new surface will not appear on a
            %   legend.
            this.add( 'Surface', sourceSurface, varargin{:} );
        end
        
        function addLegend( this, sourceLegend )
            % addLegend   Add a legend to a PrintToFigureTarget
            %
            %   p.addLegend( aLegend ) adds a legend to the most recent axes of a
            %   PrintToFigureTarget.
            %
            %   The legend created in the print-to-figure target will be a copy of the given
            %   legend. However the items that appear on the target legend will be based on
            %   the items in the target axes rather than the items on the source legend.
            this.privateAdd( 'Legend', sourceLegend );
        end
        
        function add( this, type, source, varargin )
            % add   Add a graphic to a PrintToFigureTarget
            %
            %   p.add( type, source ) add a source of given type to the current axes of a
            %   PrintToFigureTarget.
            %
            %   Allowed types are: Contour, 'Line', 'Patch', 'Stem', 'Surface'.
            options = iParseArguments( varargin{:} );

            target = this.privateAdd( type, source );
            curvefit.gui.setLegendable( target, options.Legendable );            
        end
    end

    methods(Access = private)
        function target = privateAdd( this, type, source )
            % add   Add a graphic the current axes
            %
            %   p.privateAdd( type, source ) add a source of given type to the current axes of  a
            %   PrintToFigureTarget.
            %
            %   Allowed types are 'Legend', 'Line', 'Surface' and 'Stem'.
            constructor = this.Constructors.(type);
            target = constructor( this.CurrentAxes );
            
            properties  = this.Properties.(type);
            iCopyProperties( source, target, properties );
        end
    end
end

function options = iParseArguments( varargin )
% iParseArguments   Parse parameter-value input arguments
parser = inputParser();
parser.addOptional( 'Legendable', true, @islogical );
parser.parse( varargin{:} );
options = parser.Results;
end

function iCopyProperties( source, target, properties )
% iCopyProperties   Copy properties from one graphic to another.
values = get( source, properties );
set( target, properties, values );
end

function iCopySubProperty( source, target, major, minor )
% iCopySubProperty   Copy a sub-property from one graphic to another
iCopyProperties( get( source, major ), get( target, major ), minor );
end

function constructors = iConstructors()
% iConstructors   Structure of constructors for MATLAB graphics that can be
% "printed to figure".
constructors = struct( ...
    'Contour', @iCreateContour, ...
    'Legend',  @( p ) legend( p, 'show' ), ...
    'Line',    @( p ) line( 'Parent', p ), ...
    'Patch',   @( p ) patch( 'Parent', p ), ...
    'Stem3',   @iCreateStem3, ...
    'Surface', @( p ) surface( 'Parent', p ) );
end

function properties = iProperties()
% iProperties   Structure of properties for MATLAB graphics that need values
% copied from the source to the target.
properties = struct( ...
    'Contour', {{'DisplayName', 'Fill', 'LineColor', 'XData', 'YData', 'ZData'}}, ...
    'Legend', {{'Position', 'Location', 'Color', 'EdgeColor', 'FontName', 'FontSize', 'FontAngle', 'FontWeight', 'Interpreter', 'LineWidth', 'Orientation', 'TextColor'}}, ...
    'Line', {{'DisplayName', 'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor', 'XData', 'YData', 'ZData'}}, ...
    'Patch', {{'FaceAlpha', 'FaceColor', 'XData', 'YData', 'ZData'}}, ...
    'Stem3', {{'DisplayName', 'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerFaceColor', 'MarkerEdgeColor', 'XData', 'YData', 'ZData'}}, ...
    'Surface', {{'AlphaData', 'AlphaDataMapping', 'CData', 'CDataMapping', 'DisplayName', 'EdgeAlpha', 'EdgeColor', 'EdgeLighting', 'FaceAlpha', 'FaceColor', 'FaceLighting', 'LineStyle', 'LineWidth', 'Marker', 'MarkerEdgeColor', 'MarkerFaceColor', 'MarkerSize', 'MeshStyle', 'VertexNormals', 'XData','YData', 'ZData'}} );
end

function c = iCreateContour( anAxes )
% iCreateContour   Create a contour plot
[~, c] = contour( anAxes, [] );
end

function s = iCreateStem3( anAxes )
% iCreateStem3   Create a stem3 plot
%
% This function will preserve the view angle of the parent axes.
[a, e] = view( anAxes );
s = stem3( [], [], [], 'Parent', anAxes );
view( anAxes, a, e );
end
