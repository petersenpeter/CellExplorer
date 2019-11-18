classdef Panel < curvefit.Handle & curvefit.ListenerTarget
    %PANEL A panel that can be used with SFTOOL
    %
    %   PANEL(parent) constructs a Panel instance.  This class is intended
    %   to be used as the superclass and as such should be treated as
    %   abstract even though it is not: it is not expected that you will
    %   directly instantiate this class.
    
    %   Copyright 2008-2012 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'public')
        HUIPanel;
        HParent;
    end
    
    properties(SetAccess = 'public', GetAccess = 'public', Dependent)
        % Position   Position of the uipanel in the figure
        Position
        
        % Visible   Visibility of the uipanel
        Visible
        
        % Tag   Tag of the uipanel
        Tag
    end
    
    properties(Access = private)
        % Storage for Position property
        PositionStorage = [0 0 0 0];
    end
    
    properties(GetAccess = protected, SetAccess = private, Dependent)
        %InnerPosition  Position rectangle for subclass layout
        %
        %   The InnerPosition property returns the position rectangle that
        %   subclasses should use to layout the contained components.
        InnerPosition
    end
    
    properties(Access = private, Transient)
        % Listener on the panel resize event
        ResizeListener;
        
        % Last position that we called layoutPanel() for
        LastResizePosition = [0 0 0 0];
    end
    
    methods
        function this = Panel(parent)
            this.HUIPanel = sftoolgui.util.createEtchedPanel(parent);
            
            this.HParent = parent;
            
            % Ensure that the local position property matches the panel's
            % default position.
            this.Position = get(this.HUIPanel, 'Position');
            
            this.storeListener( ...
                curvefit.listener( this.HUIPanel, 'SizeChanged', iMakeResizeCallback( this ) ) );
        end
        
        function set.Visible(this, vis)
            set(this.HUIPanel, 'Visible', vis);
            this.postSetVisible();
        end
        
        function visible = get.Visible(this)
            visible = get(this.HUIPanel, 'Visible');
        end
        
        function set.Tag(this, tag)
            set(this.HUIPanel, 'Tag', tag);
        end
        
        function tag = get.Tag(this)
            tag = get(this.HUIPanel, 'Tag');
        end
        
        function set.Position(this, pos)
            this.PositionStorage = pos;
            
            % Set panel to be this position after adjusting for any errors
            pos = sftoolgui.util.adjustControlPosition(this.HUIPanel, pos);
            set(this.HUIPanel, 'Position', pos);
        end
        
        function pos = get.Position(this)
            pos = this.PositionStorage;
        end
        
        function innerpos = get.InnerPosition(this)
            innerpos = this.Position;
            
            % Inner position coordinates start at 1
            innerpos(1:2) = 1;
            
            % Adjust for the pixels lost due to the border decoration
            W = sftoolgui.util.getPanelBorderWidth(this.HUIPanel);
            innerpos(3:4) = max(innerpos(3:4)-2*W, [0 0]);
        end
    end
    
    methods(Access = protected)
        function layoutPanel(~)
            % layoutPanel Update the contents of the Panel
            %
            %   layoutPanel is called when the size of the contained uipanel
            %   object changes.  This method should be overridden by subclasses
            %   that need to re-position contents in response to this event
        end
        
        function postSetVisible(~)
            % postSetVisible   Perform any post-set actions for the visible property
        end
    end
    
    methods(Access = private)
        function doPanelResize(this, ~, ~)
            %doResize Callback for panel resize event
            posNow = this.Position;
            posOld = this.LastResizePosition;
            
            if any(posNow(3:4)~=posOld(3:4))
                % Only call layoutPanel if the size changes
                this.layoutPanel();
                this.LastResizePosition = posNow;
            end
        end
    end
end

function CB = iMakeResizeCallback(this)
% Use a nested function handle to capture "this".  This function handle
% executes faster than either an anonymous function or a "method" function
% handle (@this.doPanelResize).

CB = @iExecute;

    function iExecute(~, ~)
        this.doPanelResize()
    end
end
