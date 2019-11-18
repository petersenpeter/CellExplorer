classdef DynamicUIMenu < curvefit.Handle
    %DYNAMICUIMENU An HG uimenu with varying sub menus for use with SFTOOL
    %
    %   DYNAMICUIMENU
    
    %   There is an issue with menus that have dynamic submenus on the MAC
    %   when screen menus are enabled. The issue is due to the way HG
    %   switches a leaf menu to a parent menu at runtime based on the child
    %   list.
    %
    %   As a work around, this class will create a uimenu which always has
    %   a submenu. This "dummy" submenu Visible and HandleVisibility
    %   properties are set to off. The removeSubmenus method does not
    %   delete this menu. The enable method ignores this submenu when
    %   determining whether or not to enable the uimenu.
    
    %   Copyright 2010-2011 The MathWorks, Inc.
    
    properties(SetAccess = 'private', GetAccess = 'private')
        %Menu--  Handle to the HG uimenu that this object will use.
        Menu;
        %Submenus -- Array of current submenus, not including the dummy
        %invisible one.
        Submenus;
    end
    
    methods
        function this = DynamicUIMenu(parentMenu, varargin)
            % Construct an sftoolgui.DynamicUIMENU object using parentMenu if supplied.
            %
            % DYNAMICUIMENU()
            % Creates a default DynamicUIMenu object
            % DYNAMICUIMENU(parentMenu, varargin)
            % Creates a DynamicUIMenu object using parentMenu as the parent
            % of the uimenu this class creates. The uimenu will be created
            % with the parameter/value pairs contained in varargin
            
            if nargin < 1
                this.Menu = uimenu();
            else
                if ~iIsUIMenu(parentMenu)
                    error(message('curvefit:sftoolgui:DynamicUIMenu:invalidInput'));
                end
                this.Menu = uimenu(parentMenu, varargin{:});
            end
            
            % The initial enable state is 'off'
            set(this.Menu, 'Enable', 'off');
            
            % Create a "dummy" submenu
            uimenu(this.Menu, 'Visible', 'off', ...
                'HandleVisibility', 'off', ...
                'Tag', 'InvisibleMenuItem');
            initializeSubmenuArray(this);
        end
        
        function removeSubmenus( this )
            % removeSubmenus removes all submenus 
            
            % This will remove all submenus except the "dummy"
            delete(handle(this.Submenus));
            initializeSubmenuArray(this);
            set(this.Menu, 'Enable', 'off');
            
        end
               
        function addSubmenu(this, varargin)
            % addSubmenu will add a submenu using varargin as
            % parameter/value pairs. 
            
            % create the submenu
            this.Submenus(end + 1) = uimenu(this.Menu, varargin{:});
            set(this.Menu, 'Enable', 'on');
        end
    end
    
    methods(Access = private)
        function initializeSubmenuArray(this)
            this.Submenus = [];
        end
    end
end

function tf = iIsUIMenu(parentMenu)
% iIsValidInput returns true if parentMenu is a uimenu
tf = numel(parentMenu) == 1  && ishghandle(parentMenu, 'uimenu');
end

