classdef TableOfFitsClient < sftoolgui.Client & curvefit.ListenerTarget
    %TableOfFitsClient Panel for displaying a list of fits in SFTOOL
    
    %   Copyright 2008-2012 The MathWorks, Inc.
    
    properties (SetAccess = private)
        HFitsManager
        LocalJavaPanel
        FitdevListeners
    end
    
    methods
        function obj = TableOfFitsClient(fitsManager)
            
            % Get the singleton instance of the client
            obj.JavaClient = javaMethodEDT( 'getInstance', ...
                ['com.mathworks.toolbox.curvefit.' ...
                'surfacefitting.SFTableOfFitsClient']);
            obj.JavaPanel = javaMethodEDT('getPanel', obj.JavaClient);
            obj.LocalJavaPanel = javaMethodEDT('getPanel', obj.JavaClient);
            
            obj.Name = javaMethodEDT('getName', obj.JavaClient);
            
            % Same action occurs when fits are "added" or "loaded".
            obj.HFitsManager = fitsManager;
            
            obj.createListener( fitsManager, 'FitAdded', ...
                @(s, e) obj.fitAdded( e ) );
            obj.createListener( fitsManager, 'FitDeleted', ...
                @(s, e) obj.fitDeleted( e ) );
            obj.createListener( fitsManager, 'FitLoaded', ...
                @(s, e) obj.fitAdded( e ) );
            
            % Set up listeners on this panel
            obj.createListener( obj.JavaPanel, 'duplicateFit', ...
                @(s, e) obj.duplicateFitAction( e ) );
            obj.createListener( obj.JavaPanel, 'deleteFit', ...
                @(s, e) obj.deleteFitAction( e ) );
            obj.createListener( obj.JavaPanel, 'saveToWorkSpace', ...
                @(s, e) obj.saveToWorkspaceAction( e ) );
            obj.createListener( obj.JavaPanel, 'selectFit', ...
                @(s, e) obj.selectFitAction( e ) );
        end
        
        function editFitAction(obj, evt)
            name = char( evt.getFitName );
            obj.HFitsManager.editFit(name );
        end
        
        function duplicateFitAction(obj, evt)
            duplicateFit(obj.HFitsManager, evt.getFitUUID );
        end
        
        function deleteFitAction(obj, evt)
            deleteFit(obj.HFitsManager, evt.getFitUUID );
        end
        
        function saveToWorkspaceAction(obj, evt)
            obj.HFitsManager.saveToWorkspace(evt.getFitUUID);
        end
        
        function selectFitAction(obj, evt)
            selectFit(obj.HFitsManager, evt.getFitUUID );
        end
        
        function fittingDataUpdated(obj, evt)
            javaMethodEDT('clearFittingData', obj.JavaPanel, ...
                evt.HFitdev.FitName, ...
                evt.HFitdev.FittingData.Name, ...
                evt.HFitdev.FitTypeString, ...
                evt.HFitdev.FitState, ...
                evt.HFitdev.FitID);
            javaMethodEDT('clearValidationData', obj.JavaPanel, ...
                evt.HFitdev.FitID);
        end
        
        function validationDataUpdated(obj, evt)
            javaMethodEDT('updateValidationName', obj.JavaPanel, ...
                evt.HFitdev.ValidationData.Name, evt.HFitdev.FitID);
            javaMethodEDT('clearValidationData', obj.JavaPanel, ...
                evt.HFitdev.FitID);
            iUpdateTable(obj, evt.HFitdev);
        end
        
        function fitTypeFitValuesUpdated(obj, evt)
            iUpdateTable(obj, evt.HFitdev);
        end
        
        function fitNameUpdated(obj, evt)
            javaMethodEDT('updateFitName', obj.JavaPanel, ...
                evt.HFitdev.FitName, evt.HFitdev.FitID);
        end
        
        function fitUpdated( obj, evt )
            iUpdateTable(obj, evt.HFitdev);
        end
        
        function obj = fitAdded( obj, evt )
            obj = iAddFitToTable(obj, evt.HFitdev);
            iUpdateTable(obj, evt.HFitdev);
        end
        
        function obj = fitDeleted( obj, evt )
            javaMethodEDT('removeFitFromTable', obj.JavaPanel, ...
                evt.HFitdev.FitID );
            updateFitdevListeners( obj );
        end
        
        function tableConfig = saveSession(obj)
            tableConfig = sftoolgui.TableOfFitsConfiguration();
            % Get the desktop object
            dt = javaMethodEDT( 'getDesktop', ...
                'com.mathworks.mlservices.MatlabDesktopServices' );
            % Get the Table of Fits desktop client
            dtTOFClient = dt.getClient(obj.Name);
            tableConfig.Visible = dt.isClientShowing(obj.Name);

            clientLocation = dt.getClientLocation(dtTOFClient);

            path = get(clientLocation, 'Path');
            tableConfig.Location = path;
        end
        
        function loadSession(obj, tableConfig)
            % Get the desktop object
            dt = javaMethodEDT( 'getDesktop', ...
                'com.mathworks.mlservices.MatlabDesktopServices' );

            % Create a desktop location object
            if ~isempty(tableConfig.Location)
                dtLocation = javaMethodEDT( 'create', ...
                    'com.mathworks.widgets.desk.DTLocation', ...
                    tableConfig.Location);
                dt.setClientLocation(obj.Name, dtLocation);
            end
            if tableConfig.Visible
                dt.showClient(obj.Name);
            else
                dt.hideClient(obj.Name);
            end
        end
        
        function closeClient(obj)
            javaMethodEDT('close', obj.JavaClient);
        end
        
        function cleanup(obj)
            javaMethodEDT('clearTable', obj.LocalJavaPanel);
            javaMethodEDT('cleanup',  obj.LocalJavaPanel);
            closeClient(obj);
        end
    end
    
    methods(Access = private)
        function updateFitdevListeners( obj )
            % Change the source of the Fitdev Listeners to match the list of Fits in the
            % FitsManager. If there are no listeners, then create new ones. If there are no
            % fits, then delete all the listeners.
            
            hFitdevs = obj.HFitsManager.Fits;
            nFits = length( hFitdevs );
            
            % Delete existing listeners
            delete( obj.FitdevListeners );
            if nFits == 0
                % remove invalid listener handles
                obj.FitdevListeners = [];
            else
                % Need to recreate listeners
                obj.FitdevListeners = iCreateFitdevListeners( obj, hFitdevs );
            end
        end
    end
end

function obj = iAddFitToTable(obj, hFitdev)
javaMethodEDT('addFit', obj.JavaPanel, ...
    hFitdev.FitName, ...
    hFitdev.FitID, ...
    hFitdev.FitState, ...
    hFitdev.FitTypeString);
updateFitdevListeners( obj );
end

function iUpdateTable(obj, HFitdev)

if HFitdev.FitState == com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.GOOD || ...
        HFitdev.FitState == com.mathworks.toolbox.curvefit.surfacefitting.SFFitState.WARNING  % good or warning fit
    javaMethodEDT('updateFit', obj.JavaPanel, ...
        HFitdev.FitName, ...
        HFitdev.FittingData.Name, ...
        HFitdev.FitTypeString, ...
        HFitdev.Goodness.sse, ...
        HFitdev.Goodness.rsquare, ...
        HFitdev.Goodness.dfe, ...
        HFitdev.Goodness.adjrsquare, ...
        HFitdev.Goodness.rmse, ...
        HFitdev.Output.numparam, ...
        HFitdev.FitID, ...
        HFitdev.FitState);
    javaMethodEDT('updateValidationName', obj.JavaPanel, ...
        HFitdev.ValidationData.Name, HFitdev.FitID);
    if ~isempty(HFitdev.ValidationGoodness.sse) && ...
            ~isempty(HFitdev.ValidationGoodness.rmse)
        javaMethodEDT('updateValidationData', obj.JavaPanel, ...
            HFitdev.ValidationGoodness.sse, ...
            HFitdev.ValidationGoodness.rmse, ...
            HFitdev.FitID);
    else
        javaMethodEDT('clearValidationData', obj.JavaPanel, ...
            HFitdev.FitID);
    end
else % bad or incomplete
    javaMethodEDT('clearFittingData', obj.JavaPanel, ...
        HFitdev.FitName, ...
        HFitdev.FittingData.Name, ...
        HFitdev.FitTypeString, ...
        HFitdev.FitState, ...
        HFitdev.FitID);
    javaMethodEDT('updateValidationName', obj.JavaPanel, ...
        HFitdev.ValidationData.Name, HFitdev.FitID);
    javaMethodEDT('clearValidationData', obj.JavaPanel, HFitdev.FitID);
end
end

function listeners = iCreateFitdevListeners( obj, hFitdevs )
listeners = [
    obj.createListener( hFitdevs, 'FitNameUpdated',          @(s, e) obj.fitNameUpdated( e ));
    obj.createListener( hFitdevs, 'FitUpdated',              @(s, e) obj.fitUpdated( e ));
    obj.createListener( hFitdevs, 'FittingDataUpdated',      @(s, e) obj.fittingDataUpdated( e ));
    obj.createListener( hFitdevs, 'ValidationDataUpdated',   @(s, e) obj.validationDataUpdated( e ));
    obj.createListener( hFitdevs, 'FitTypeFitValuesUpdated', @(s, e) obj.fitTypeFitValuesUpdated( e ));
    ];
end
