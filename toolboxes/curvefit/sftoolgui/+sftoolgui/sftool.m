classdef sftool < curvefit.Handle & curvefit.ListenerTarget
    %SFTOOL Surface Fitting Tool
    
    %   Copyright 2008-2012 The MathWorks, Inc.
    
    events
        % SftoolClosed   Fired just after SFTOOL is closed.
        SftoolClosed
    end
    
    properties
        GroupName = 'Curve Fitting Tool';
        
        HFitsManager ;
        
        TableOfFitsClient ;
        
        Group;
        
        FitFigures = {};
        
        FitFigureConfigs = {};
        
        SessionName = '';
        
        SessionPath = '';
        
        SessionChanged = false;
        
        Closeable = true;
    end
    
    properties(Access=private)
        FitFigureListeners        
    end
    
    methods
        function h = sftool
            %SFTOOL Constructor for the surface fitting tool
            %
            %   H = SFTOOL
            
            % Create message center
            h.HFitsManager = sftoolgui.FitsManager;
            
            % Get the desktop object
            dt = javaMethodEDT( 'getDesktop', 'com.mathworks.mlservices.MatlabDesktopServices' );
            
            % Create the group
            h.Group = sftoolgui.Group(h);
            
            addGroup(h.Group, dt);
            
            % Set location the first time sftool is called.
            % The setDefaultLocation method (which includes setting the
            % docked state) should be called before the addClient call.
            % Otherwise users will temporarily see sftool docked.
            if com.mathworks.services.Prefs.getBooleanPref(...
                    'CurveFittingTool.useDefaultLocation', true)
                setDefaultLocation(h.Group);
                % set tab location to the top
                dt.setDocumentBarPosition(h.GroupName, javax.swing.SwingConstants.NORTH);
                com.mathworks.services.Prefs.setBooleanPref(...
                    'CurveFittingTool.useDefaultLocation', false);
            end
            
            % Create the panels
            h.TableOfFitsClient = sftoolgui.TableOfFitsClient (h.HFitsManager );
            
            dtTOFClient = dt.getClient(h.TableOfFitsClient.Name);
            
            % And create desktop location objects
            dtS = javaMethodEDT( 'create', 'com.mathworks.widgets.desk.DTLocation', 'S' );
            addClient( h.TableOfFitsClient, dt, dtS );
            
            % Set selected
            dt.setClientSelected(dtTOFClient, true);
        end
        
        function sftoolOpened(h)
            %Add listeners
            fm = h.HFitsManager;            
            h.createListener(fm, 'FitAdded', @(s, e) h.fitAdded( e ) );
            h.createListener(fm, 'FitLoaded', @(s, e) h.fitLoaded( e ) );
            h.createListener(fm, 'FitDuplicated', @(s, e) h.fitDuplicated( e ) );
            h.createListener(fm, 'FitDeleted', @(s, e) h.fitDeleted( e ) );
            h.createListener(fm, 'FitSelected', @(s, e) h.fitSelected( e ) );
            h.createListener(fm, 'FitsManagerSessionChanged', @(s, e) h.sessionChanged() );
            h.createListener(fm, 'SessionCleared', @(s, e) h.sessionCleared() );
            h.createListener(fm, 'FitClosed', @(s, e) h.fitClosed( e ) );
        end
        
        function setWaiting(h, state)
            dt = javaMethodEDT( 'getDesktop', ...
                'com.mathworks.mlservices.MatlabDesktopServices' );
            frame = dt.getFrameContainingGroup(h.GroupName);
            if ~dt.isGroupDocked(h.GroupName) && ~isempty(frame)
                if state
                    javaMethodEDT('setWait', 'com.mathworks.mwswing.GlobalCursor', frame);
                else
                    javaMethodEDT('clear', 'com.mathworks.mwswing.GlobalCursor', frame);
                end
            end
            h.Closeable = ~state;
        end
        
        function selectTool(h)
            dt = javaMethodEDT( 'getDesktop', ...
                'com.mathworks.mlservices.MatlabDesktopServices' );
            dt.showGroup(h.GroupName, true);
        end
        
        function sftoolHelp(~)
            helpview([docroot '/toolbox/curvefit/curvefit.map'], 'sftool');
        end
        
        function cftoolHelp(~)
            doc curvefit;
        end
        
        function demosHelp(~)
            demo('toolbox','curve');
        end
        
        function aboutHelp(~)
            a = ver('curvefit');
            str = sprintf('Curve Fitting Toolbox %s\nCopyright 2001-%s The MathWorks, Inc.', ...
                a.Version, a.Date(end-3:end));
            msgbox(str,getString(message('curvefit:sftoolgui:AboutTheCurveFittingToolbox')),'modal');
        end
        
        function h = sessionChanged(h)
            h.SessionChanged = true;
        end
        
        function sessionCleared(h)
            h.SessionName = '';
        end
        
        function h = clearSessionChanged(h)
            h.SessionChanged = false;
        end
        
        function fitAdded(h, evt)
            % fitAdded   Called when new fits are created
            fitFigure = sftoolgui.FitFigure(h, evt.HFitdev, []);
            addFitFigure(h, fitFigure);
            % if there is data, note that sessionChanged;
            if iHasFittingData(evt.HFitdev.FittingData)
                sessionChanged(h);
            end
        end
        
        function fitLoaded(h, evt)
            % fitLoaded   Called when fits need to be re-created because a session was loaded
            
            % if fitFigure was not visible, just store the FitFigure
            % configuration, otherwise, recreate the FitFigure
            config = evt.HFitFigureConfig;
            if strcmp(config.Visible, 'on')
                fitFigure = sftoolgui.FitFigure(h, evt.HFitdev, evt.HFitFigureConfig);
                addFitFigure(h, fitFigure);
            else
                h.FitFigureConfigs{end + 1} = config;
            end
            sessionChanged(h);
        end
        
        function fitClosed(h, evt)
            % The fitFigure return value will be empty if the fit is
            % already closed. In that case, no further action is required.
            [fitFigure, index] = getFitFigureFromUUID(h, evt.FitUUID);
            if ~isempty(fitFigure)
                % delete old config if there is one
                deleteFitFigureConfig(h, evt.FitUUID);
                h.FitFigureConfigs{end + 1} = evt.FitFigureConfig;
                updateFitFigureListeners( h );
                h.FitFigures(index) = [];
                % We get to this code both when user closes fit and when fits
                % are being closed because sftool is closing. We want to set
                % session changed in the former but not the latter. However,
                % in the later case, this setting will be ignored, because it
                % is set after it is queried.
                sessionChanged(h);
            end
        end
        
        function fitDuplicated(h, evt)
            % If a fit is open, its corresponding FitFigure is stored in
            % sftool.FitFigures. Otherwise the configuration information
            % for the fit is stored in sftoolgui.FitFigureConfigs. When
            % duplicating a fit, if the source fit is open, get the
            % configuration information from the FitFigures property. If it
            % is closed, get the configuration information from the
            % FitFigureConfigs property.
            sFF = getFitFigureFromUUID(h, evt.SourceFitUUID);
            if isempty(sFF) % Empty indicates that the fit figure is closed.
                configuration = getFitFigureConfigFromUUID(h, evt.SourceFitUUID);
            else
                configuration = sFF.Configuration;
            end
            dFF = getFitFigureFromUUID(h, evt.HFitdev.FitID);
            if ~isempty(dFF) % Empty indicates that the new fit figure has
                % been closed. If that is the case, there is
                % no need to update it.
                updateFitFigure(dFF, configuration);
            end
            sessionChanged(h);
        end
        
        function newFitAction(h)
            newFit(h.HFitsManager, []);
        end
        
        function closingAction(h)
            if h.Closeable && iAskSaveSession(h);
                % Close all fit figures immediately; the group closes them
                % using the UI action which is queued and we do not want
                % the destruction to queue.
                FF = h.FitFigures;
                for n=1:length(FF)
                    delete(FF{n});
                end
                approveClose(h.Group);
            else
                vetoClose(h.Group)
            end
        end
        
        function closeAction(h)
            %DELETE Delete the surface fitting tool.
            dt = javaMethodEDT( 'getDesktop', 'com.mathworks.mlservices.MatlabDesktopServices' );
            dt.removeClient( h.TableOfFitsClient.Name );
            cleanup(h.TableOfFitsClient);
            dt.removeGroup( h.GroupName );
            % delete group and remove reference to group
            deleteGroup(h.Group);
            h.Group = [];
            dt.removeGroup( h.GroupName );
            % Notify listeners the SFTOOL is now closed.
            notify( h, 'SftoolClosed' );
            % Delete this instance, so that it can be reopened.
            delete(h);
        end
        
        function closeSftool(h)
            dt = javaMethodEDT( 'getDesktop', 'com.mathworks.mlservices.MatlabDesktopServices' );
            dt.closeGroup( h.GroupName );
        end
        
        function ok = session(h, action)
            % session   Save, load or clear a session
            %
            % Inputs
            %   action -- "save", "load" or "clear"

            oldSessionName = h.SessionName;
            ok = false;
            if strcmp(action, 'save')
                ok = sftoolgui.sfsession(h, 'save', h.SessionName);
            else % load or clear
                if iAskSaveSession(h)
                    if strcmp(action, 'clear')
                        setWaiting(h, true);
                    end
                    ok  = sftoolgui.sfsession(h, action, '');
                    if strcmp(action, 'clear')
                        setWaiting(h, false);
                    end
                end
            end
            if ok
                clearSessionChanged(h);
                setGroupTitle(h.Group);
            else
                % Restore old name
                h.SessionName = oldSessionName;
            end
        end
        
        function loadSessionWithFile(h, sessionFile)
            ok = false;
            if iAskSaveSession(h)
                ok  = sftoolgui.sfsession(h, 'load', sessionFile);
            end
            if ok
                clearSessionChanged(h);
                setGroupTitle(h.Group);
            end
        end
        
        function sessionSaveAs(h)
            if sftoolgui.sfsession(h, 'save', '')
                clearSessionChanged(h);
                setGroupTitle(h.Group);
            end
        end
        
        function fitDeleted(h, evt)
            fitUUID = evt.HFitdev.FitID;
            fitFigure = getFitFigureFromUUID(h, fitUUID);
            delete(fitFigure);
            deleteFitFigureConfig(h, fitUUID);
            sessionChanged(h);
        end
        
        function fitSelected(h, evt)
            fitFigure = getFitFigureFromUUID(h, evt.HFitdev.FitID);
            % Bring selected fit figure forward
            if ~isempty(fitFigure) && ishandle(fitFigure.Handle)
                figure(fitFigure.Handle);
            else % recreate figure
                fitFigure = sftoolgui.FitFigure(h, evt.HFitdev, getFitFigureConfigFromUUID(h, evt.HFitdev.FitID));
                addFitFigure(h, fitFigure);
            end
        end
        
        function savedSession = saveSession(h, sessionName)
            setWaiting(h, true);
            h.SessionName = sessionName;
            fitInfo = getAllFitdevsAndConfigs(h);
            tableConfig = saveSession(h.TableOfFitsClient);
            savedSession = sftoolgui.Session(fitInfo, ...
                tableConfig);
            setWaiting(h, false);
        end
        
        function loadSession(h, sessionInfo, sessionName)
            setWaiting(h, true);
            h.SessionName = sessionName;
            loadSession(h.TableOfFitsClient, sessionInfo.TableConfig);
            loadSession(h.HFitsManager, sessionInfo.AllFitdevsAndConfigs);
            setWaiting(h, false);
        end
        
        function allFitdevsAndConfigs = getAllFitdevsAndConfigs(h)
            fitdevs = h.HFitsManager.Fits;
            numFits = length(fitdevs);
            allFitdevsAndConfigs = cell(numFits, 1);
            % Either create a new configuration (if the figure is "open")
            % or get the saved configuration (if the figure is "closed")
            for i = 1:numFits
                allFitdevsAndConfigs{i}.Fitdev = fitdevs{i};
                fitUUID = fitdevs{i}.FitID;
                fitFigure = getFitFigureFromUUID(h, fitUUID);
                if ~isempty(fitFigure) && ishandle(fitFigure.Handle)
                    allFitdevsAndConfigs{i}.Config = fitFigure.Configuration;
                else
                    allFitdevsAndConfigs{i}.Config = getFitFigureConfigFromUUID(h, fitUUID);
                end
            end
        end
        
        function deleteFitFigureConfig(h, fitUUID)
            n = size(h.FitFigureConfigs, 2);
            for i = 1:n
                if h.FitFigureConfigs{i}.FitUUID.hashCode == fitUUID.hashCode
                    h.FitFigureConfigs(i) = [];
                    break;
                end
            end
        end
        
        function [fitFigure, i] = getFitFigureFromUUID(h, fitUUID)
            fitFigure = [];
            n = size(h.FitFigures, 2);
            for i = 1:n
                if h.FitFigures{i}.FitUUID.hashCode == fitUUID.hashCode
                    fitFigure = h.FitFigures{i};
                    break;
                end
            end
        end
        
        function config = getFitFigureConfigFromUUID(h, fitUUID)
            config = [];
            n = size(h.FitFigureConfigs, 2);
            for i = 1:n
                if h.FitFigureConfigs{i}.FitUUID.hashCode == fitUUID.hashCode
                    config = h.FitFigureConfigs{i};
                    break;
                end
            end
        end
        
        function hFunction = makeMCode( h )
            % MAKEMCODE   Generate code for an SFTOOL session
            %
            %     aFunction = MAKEMCODE( H ) is a codegen.coderoutine object
            %     that represents the code required to represent the SFTOOL
            %     session given by H.
            
            mcode = sftoolgui.codegen.MCode;
            
            % Generate code for each FitFigure
            for i = 1:length( h.FitFigures )
                generateMCode( h.FitFigures{i}, mcode );
            end
            
            % Create the coderoutine object
            hFunction = mcode.writeTo( codegen.coderoutine );
        end
    end
    
    methods(Access = private )
        function this = addFitFigure( this, fitFigure)
            this.FitFigures{end+1} = fitFigure;
            updateFitFigureListeners( this );
        end
        
        function updateFitFigureListeners( this )
            % Change the source of the FitFigure Listeners to match the list of
            % FitFigures. If there are no listeners, then create new ones. If
            % there are no  fits, then delete the listeners.
            hFitFigures = this.FitFigures;
            
            % Delete existing listeners
            delete( this.FitFigureListeners );
            if isempty( hFitFigures );
                % Remove invalid listener handles
                this.FitFigureListeners = [];
                
            else
                % Need to create listeners
                this.FitFigureListeners = this.createListener( hFitFigures, 'SessionChanged', ...
                    @(s, e) this.sessionChanged() );
            end
        end
    end
end

function ok = iAskSaveSession(this)
% Don't ask to save session if there is no information worth saving.
if this.SessionChanged && iHasInformationToSave(this)
    resp = questdlg(getString(message('curvefit:sftoolgui:SaveThisCurveFittingSession')), ...
        getString(message('curvefit:sftoolgui:CurveFitting')), getString(message('curvefit:sftoolgui:Yes')), getString(message('curvefit:sftoolgui:No')), getString(message('curvefit:sftoolgui:Cancel')), getString(message('curvefit:sftoolgui:Yes')));
else
    resp = getString(message('curvefit:sftoolgui:No'));
end

if isempty(resp)
    resp = getString(message('curvefit:sftoolgui:Cancel'));
end

if isequal(resp,getString(message('curvefit:sftoolgui:Yes')))
    ok = session(this, 'save');
    if ~ok
        resp = getString(message('curvefit:sftoolgui:Cancel'));
    end
end

ok = ~isequal(resp,getString(message('curvefit:sftoolgui:Cancel')));
end

function hasInformationToSave = iHasInformationToSave(this)
% iHasInformationToSave returns true if there is information worth saving.
% Even though we keep track of the fitCounter and the Table of Fits
% visibility, we won't bother saving that information if there are no fits.
hasInformationToSave = size(this.HFitsManager.Fits, 2) > 0;
end

function hasData = iHasFittingData(data)
[x, y, z, w] = getValues(data);
hasData = ~(isempty(x) && isempty(y) && isempty(z) && isempty(w));
end
