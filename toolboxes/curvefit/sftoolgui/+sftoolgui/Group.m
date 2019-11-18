%M Wrapper for SFGroup.java
%
%   GROUP

%   Copyright 2008-2011 The MathWorks, Inc.

classdef Group < curvefit.Handle & curvefit.ListenerTarget

    properties (SetAccess = private)
        SFTool
        HFitsManager
        GroupBase
        FitdevNameListener
    end
    
    methods
        function this = Group(sftool)
            
            this.SFTool = sftool;
            % Get the singleton instance of the group
            this.GroupBase = javaMethodEDT( 'getInstance', ...
                'com.mathworks.toolbox.curvefit.surfacefitting.SFGroup');
            
            setGroupTitle(this);
            
            this.HFitsManager = sftool.HFitsManager;
            
            % Same action occurs when fits are "added" or "loaded".
            this.createListener( this.HFitsManager, 'FitAdded',...
                 @(s, e) this.fitAdded( e ) );
            this.createListener( this.HFitsManager, 'FitLoaded',...
                 @(s, e) this.fitAdded( e ) );
            this.createListener( this.HFitsManager, 'FitDeleted',...
                 @(s, e) this.fitDeleted( e ) );

            hGroupBase = this.GroupBase;
            this.createListener( hGroupBase, 'newFit', ...
                @(s, e) this.SFTool.newFitAction( ) );
            this.createListener( hGroupBase, 'closeTool', ...
                @(s, e) this.SFTool.closeSftool( ) );
            this.createListener( hGroupBase, 'groupClosed', ...
                @(s, e) this.SFTool.closeAction( ) );
            this.createListener( hGroupBase, 'groupClosing', ...
                @(s, e) this.SFTool.closingAction( ) );
            this.createListener( hGroupBase, 'selectFit', ...
                @(s, e) this.selectFitAction( e ) );
            this.createListener( hGroupBase, 'loadSession', ...
                @(s, e) this.SFTool.session( 'load' ) );
            this.createListener( hGroupBase, 'saveSession', ...
                @(s, e) this.SFTool.session( 'save' ) );
            this.createListener( hGroupBase, 'saveSessionAs', ...
                @(s, e) this.SFTool.sessionSaveAs() );
            this.createListener( hGroupBase, 'clearSession', ...
                @(s, e) this.SFTool.session( 'clear' ) );
            this.createListener( hGroupBase, 'sftoolHelp', ...
                @(s, e) this.SFTool.sftoolHelp );
            this.createListener( hGroupBase, 'cftoolHelp', ...
                @(s, e) this.SFTool.cftoolHelp );
            this.createListener( hGroupBase, 'demosHelp', ...
                @(s, e) this.SFTool.demosHelp );
            this.createListener( hGroupBase, 'aboutHelp', ...
                @(s, e) this.SFTool.aboutHelp );
            this.createListener( hGroupBase, 'generateMFile', ...
                @(s, e) this.generateMFileAction());
        end
        
        function addGroup(this, dt)
            dt.addGroup(this.GroupBase);
        end
        
        function setDefaultLocation(this)
            javaMethodEDT( 'setDefaultLocation', this.GroupBase);
        end
        
        function setGroupTitle(this)
            title = getString(message('curvefit:sftoolgui:CurveFittingTool'));
            if ~isempty(this.SFTool.SessionName)
                [~, name] = fileparts(this.SFTool.SessionName);
                title = sprintf('%s - %s', title, name);
            end
            javaMethodEDT('setGroupTitle', this.GroupBase, title);
        end
        
          function approveClose(this)
             javaMethodEDT('approveGroupClose', this.GroupBase);
        end
        
        function vetoClose(this)
             javaMethodEDT('vetoGroupClose', this.GroupBase);
        end
        
        function generateMFileAction( this)
            sftoolgui.generateMCode( this.SFTool );
        end
        
        function selectFitAction(this, evt)
            selectFit(this.HFitsManager, evt.getFitUUID );
        end
        
        function fitNameUpdated(this, evt)
            javaMethodEDT('updateFitName', this.GroupBase, ...
                                           evt.HFitdev.FitName, ...
                                           evt.HFitdev.FitID);
        end
         
        function this = fitAdded(this, evt )
            javaMethodEDT('addFit', this.GroupBase, ...
                           evt.HFitdev.FitName, ...
                           evt.HFitdev.FitID);
            updateFitdevListeners( this );
        end
        
        function this = fitDeleted( this, evt )
            javaMethodEDT('deleteFit', this.GroupBase, evt.HFitdev.FitID );
            updateFitdevListeners( this );
        end
        
        function deleteGroup(this)
            delete(this)
        end
    end
    
    methods(Access = private )
        function updateFitdevListeners( this )
            % Change the source of the Fitdev Listeners to match the list of
            % Fitdevs in the Fits Manager. If there are no listeners, then
            % create new ones. If there are no  fits, then delete the listeners.
            
            % Need to destroy the old listener since a copy is held in the
            % superclass
            if ~isempty(this.FitdevNameListener)
                delete(this.FitdevNameListener);
            end
            
            hFitdevs = this.HFitsManager.Fits;
            if isempty( hFitdevs );
                % Remove dead listener reference
                this.FitdevNameListener = [];   
            else
                % Recreate name listener on the fitdevs
                this.FitdevNameListener = this.createListener(hFitdevs, ...
                    'FitNameUpdated', @(s, e) this.fitNameUpdated(e));
            end
        end
        
    end
end
