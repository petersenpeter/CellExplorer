classdef PlotLayoutPanel < sftoolgui.Panel 
    % PlotLayoutPanel   An SFTOOL panel for displaying and laying out plot panels
    %
    %   PlotLayoutPanel(hFIG) creates an instance of a PlotLayoutPanel object.
    %   This panel class is given handles to a trio of plot panels and
    %   positions them correctly.
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    % Handles to the three plot panels that need to be positioned
    properties(Access = private)
        SurfacePanel
        ContourPanel
        ResidualsPanel
    end
    
    properties(Access = private, Transient)
        % Listener on child visibility that triggers a re-layout
        ChildVisibleListener
    end
    
    methods
        function this = PlotLayoutPanel(parent)
            %PlotLayoutPanel  Constructor for the PlotLayoutPanel class
            %
            %   PlotLayoutPanel(hParent) creates a new instance of the
            %   PlotLayoutPanel class in the specified parent.
            
            this = this@sftoolgui.Panel(parent);
            this.Tag = 'PlotLayoutPanel';
            
            set(this.HUIPanel, 'BorderType', 'none');
        end
        
        function setPanels(this, hSurface, hResiduals, hContour)
            %setPanels  Set the plot panels to position
            %
            %   setPanels(obj, hSurface, hResiduals, hContour) sets the three
            %   plot panel handles that this object should position.
            
            % Store handles to the individual plot panels
            this.SurfacePanel = hSurface;
            this.ContourPanel = hContour;
            this.ResidualsPanel = hResiduals;
            
            % Add a listener to the Visible property of all of our
            % uipanel's children.  We will redo the layout if any change.
            this.createListener( get( this.HUIPanel, 'Children' ), 'Visible', @this.updateLayout );
            
            this.layoutPanel();
        end
    end
    
    methods(Access = protected)
        function layoutPanel(this)
            %layoutPanel Update the contents of the Panel
            %
            %   layoutPanel is called when the size of the contained uipanel
            %   object changes. This method positions the three plot panels
            %   correctly.
            
            % Pass on call to the superclass
            layoutPanel@sftoolgui.Panel(this);
            
            [plotsVisible,numVisiblePlots] = getVisiblePlots(this);
            
            innerpos = this.InnerPosition;
            
            switch numVisiblePlots
                case 1 % one plot
                    iSetChildPanelPosition( innerpos, plotsVisible{1}, innerpos );
                case 2 % two plots
                    iSetTwoChildPanelsPosition( innerpos, plotsVisible{:} );
                case 3 % three plots
                    iSetThreeChildPanelPositions( innerpos, plotsVisible{:} );
                otherwise
                    % Nothing to position
            end
        end
    end
    
    methods(Access = private)
        function updateLayout(this, ~, ~)
            % updateLayout   Callback that updates the layout of this panel
            this.layoutPanel();
        end
        
        function [plotsVisible,numVisiblePlots] = getVisiblePlots(this)
            % getVisiblePlots   Cell-array of the visible plot panels
            panels = {this.SurfacePanel, this.ResidualsPanel, this.ContourPanel};
            isVisible = cellfun( @iIsPanelVisible, panels );
            
            plotsVisible = panels(isVisible);
            numVisiblePlots = nnz( isVisible );
        end
    end
end

function tf = iIsPanelVisible(hPanel)
% iIsPanelVisible Test whether a panel exists and is visible

tf = ~isempty( hPanel ) && isequal( hPanel.Visible, 'on' );
end

function iSetChildPanelPosition(innerpos, hPanel, pos)
% iSetChildPanelPosition Set a plot panel to a given position

% Clip the position rectangle to be within inner position
hPanel.Position = sftoolgui.util.clipPosition(innerpos, pos);
end

function iSetTwoChildPanelsPosition(innerpos, hTopPanel, hBottomPanel)
% iSetTwoChildPanelsPosition   Set the position of two plots if exactly two plots
% are visible.

bottomH = floor(innerpos(4)/2);

toppos = [innerpos(1), innerpos(2) + bottomH, innerpos(3), innerpos(4) - bottomH];
bottompos = [innerpos(1), innerpos(2), innerpos(3), bottomH];

iSetChildPanelPosition(innerpos, hTopPanel, toppos);
iSetChildPanelPosition(innerpos, hBottomPanel, bottompos);
end

function iSetThreeChildPanelPositions(innerpos, hTopRightPanel, hBottomRightPanel, hLeftPanel)
% iSetThreeChildPanelPositions   Set the positions of all three child panels.
leftW = floor(innerpos(3)/2);
bottomH = floor(innerpos(4)/2);

leftpos = [innerpos(1), innerpos(2), leftW, innerpos(4)];
bottomrightpos = [innerpos(1) + leftW, innerpos(2), innerpos(3) - leftW, bottomH];
toprightpos = [innerpos(1) + leftW, innerpos(2) + bottomH, innerpos(3) - leftW, innerpos(4) - bottomH];

iSetChildPanelPosition(innerpos, hLeftPanel, leftpos);
iSetChildPanelPosition(innerpos, hTopRightPanel, toprightpos);
iSetChildPanelPosition(innerpos, hBottomRightPanel, bottomrightpos);
end
