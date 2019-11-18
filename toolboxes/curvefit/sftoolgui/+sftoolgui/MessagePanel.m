classdef MessagePanel <sftoolgui.Panel
    %MessagePanel A panel that display a message
    %
    %   MessagePanel(parent, message)
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties( SetAccess = 'private', GetAccess = 'private')
        % HTextControl is the text uicontrol for the message
        HTextControl
        MessageHeightExtent
    end
    
    properties (Constant, GetAccess = 'private')
        % VerticalFactor is the percentage of the panel's height which is
        % used to set the HTextControl's y position. The position should be
        % a little higher than centered.
        VerticalFactor = 0.57
    end
    
    methods
        function this = MessagePanel( parent, theMessage )
            % MessagePanel   Construct a MessagePanel.
            %
            %   sftoolgui.MessagePanel( parent, theMessage ) constructs a
            %   MessagePanel. PARENT must be a figure or uipanel.
            %   theMessage is an internal.matlab.Message whose string will
            %   be displayed in the panel.
            
            % Make sure parent is either a figure or a uipanel
            if ~(ishghandle(parent, 'figure') || ishghandle(parent, 'uipanel'))
                error(message('curvefit:sftoolgui:MessagePanel:InvalidParent'));
            end
            
            % Make sure theMessage is an internal.matlab.Message
            if ~isa(theMessage, 'message')
                error(message('curvefit:sftoolgui:MessagePanel:InvalidMessage'));
            end
            
            this = this@sftoolgui.Panel(parent);
            this.Tag = 'sftoolMessageUIPanel';
            this.HTextControl = uicontrol('Parent', this.HUIPanel, ...
                'HorizontalAlignment', 'center', ...
                'Style', 'Text', ...
                'FontSize', 11, ...
                'Units', 'pixels', ...
                'BackgroundColor', sftoolgui.util.backgroundColor(), ...
                'String', theMessage.getString);
            
            extent = get(this.HTextControl, 'Extent');
            this.MessageHeightExtent = extent(4);
            
            this.layoutPanel();
        end
        
        function printToFigure( this, target )
            % printToFigure   Print a Message Panel to a figure
            %
            %   printToFigure( aMessagePanel, target ) "prints" the contents of a Message
            %   Panel to the target (PrintToFigureTarget).
            %
            %   See also: curvefit.gui.PrintToFigureTarget
            target.addControl( this.HTextControl );
        end
    end
    
    methods(Access = protected)
        function layoutPanel(this)
            % Pass on call to the superclass
            layoutPanel@sftoolgui.Panel(this);
            
            if ~isempty(this.HTextControl)
                innerpos = this.InnerPosition;
                
                idealY = max(1, floor(innerpos(4)*this.VerticalFactor));
                
                % Adding the height extent will insure the text will be
                % shown even when the height of the control gets very small
                controlPosition = [1 1 innerpos(3) idealY + this.MessageHeightExtent];
                
                % Clip the position rectangle to be within innerpos
                controlPosition = sftoolgui.util.clipPosition(innerpos, controlPosition);
                
                % Apply correction
                controlPosition = sftoolgui.util.adjustControlPosition(this.HTextControl, controlPosition);
                
                % Set position
                set(this.HTextControl, 'Position', controlPosition);
            end
        end
    end
end
