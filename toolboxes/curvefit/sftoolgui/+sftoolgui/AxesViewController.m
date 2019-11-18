classdef AxesViewController < curvefit.Handle & curvefit.ListenerTarget
    %AxesViewController controls the axes view
    %
    %   AxesViewController(AXES, AXESVIEWMODEL, SHOW2DVIEW) controls the
    %   AXES view angle. It disables Rotate3D mode if the view is 2D and
    %   enables it otherwise.
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties( SetAccess = 'public', GetAccess = 'public', Dependent)
        % View2D is true when curve data is being viewed and false
        % otherwise.
        View2D = false;
    end
    
    properties(SetAccess = 'private', GetAccess = 'private')
        % HAxes is the handle to the axes being controlled
        HAxes ;
        % PrivateView2D is true when curve data is being viewed and false
        % otherwise. It is associated with the public View2D dependent
        % property.
        PrivateView2D = false;
        % AxesViewModel is the sftoolgui.AxesViewModel that maintains the
        % view angle for the axes under control.
        AxesViewModel;
        % AxesViewPropertyListener listens for axes View property changes
        % initiated outside this class.
        AxesViewPropertyListener;
    end
    
    methods
        function this = AxesViewController(axes, axesViewModel, show2DView)
            % AxesViewController is the constructor for the Curve Fitting
            % Tool Axes View Controller
            %
            % this = AxesViewController(AXES, AXESVIEWMODEL, SHOW2DVIEW)
            % creates an AxesViewController that controls AXES.
            % AXESVIEWMODEL is the an sftoolgui.AxesViewModel. SHOW2DVIEW
            % is true if the axes should show 2D data and false otherwise.
            
            % Make sure first input is an axes
            if ~ishghandle(axes,'axes')
                error(message('curvefit:AxesViewController:InvalidInput'));
            end
            
            % Make sure second argument is an AxesViewModelInterface
            if ~isa(axesViewModel, 'sftoolgui.AxesViewModelInterface')
                error(message('curvefit:AxesViewController:InvalidInputAxesViewModel'));
            end
            
            % Make sure third argument is a logical
            if ~islogical(show2DView)
                error(message('curvefit:AxesViewController:InvalidInputShow2DView'));
            end
            
            % Set properties
            this.AxesViewModel = axesViewModel;
            this.HAxes = axes;
            
            % Listen to the axes View property changes from actions outside
            % this class, for instance when users rotate the axes.  We are
            % using this listener on this property as an indicator of a
            % user interaction, so it must be an event-queuing listener.
            this.AxesViewPropertyListener = curvefit.gui.event.proplistener( this.HAxes, 'View', @this.axesViewChanged );
            
            % Listen to AxesViewModel 'ThreeDViewAngleChanged' event
            
            this.createListener(this.AxesViewModel, 'ThreeDViewAngleChanged', @this.axesViewModelThreeDViewAngleChanged);
            
            % set the View2D property. (This has to be done after
            % this.ViewPropertyListener has been set.)
            this.View2D = show2DView;
        end
        
        function view2D = get.View2D(this)
            % Return the value of the associated private property.
            view2D = this.PrivateView2D;
        end
        
        function set.View2D(this, show2DView)
            % In addition to setting the associated PrivateView2D property,
            % this set method handles switching between 2D and 3D views. It
            % sets the axes view angle, updates plotview information and
            % enables or disables rotation.
            
            % Update PrivateView2D to reflect state
            this.PrivateView2D = show2DView;
            
            % Set the View Angle
            % If curve data is being viewed ...
            if this.PrivateView2D
                % then set the view angle to the default for 2 D ...
                setAxesViewAngle(this, sftoolgui.util.DefaultViewAngle.TwoD)
            else
                % otherwise set the view angle to AxesViewModel.ThreeDViewAngle
                setAxesViewAngle(this, this.AxesViewModel.ThreeDViewAngle);
            end
            
            % Update the plotview information
            setOriginalView(this);
            
            % Enable/disable Rotation based on view dimension.
            behavior = hggetbehavior( this.HAxes, 'Rotate3d' );
            set( behavior, 'Enable', ~this.PrivateView2D );
        end
    end
    
    methods(Access = private)
        
        function viewAngle = getAxesViewAngle(this)
            % getAxesViewAngle returns the viewAngle, which consists of
            % two elements: AZ, the azimuth or horizontal rotation and EL,
            % the vertical elevation of this.HAxes
            [az, el] = view(this.HAxes);
            viewAngle = [az, el];
        end
        
        function setAxesViewAngle( this, viewAngle )
            % setAxesViewAngle sets the axes view angle.
            %
            %    setAxesViewAngle(THIS, VIEWANGLE) disables the listener
            %    on THIS.HAXES View property, sets the axes view angle, and
            %    then (re)enables the listener. It disables the listener
            %    to prevent recursion.
            
            curvefit.setListenerEnabled(this.AxesViewPropertyListener, false);
            view(this.HAxes, viewAngle);
            curvefit.setListenerEnabled(this.AxesViewPropertyListener, true);
        end
        
        function setOriginalView( this )
            %setOriginalView sets Rotate3D's original view angle.
            %
            %   setOriginalView(THIS) sets THIS.HAXES plotview
            %   information's View field to CFTOOL's 2D or 3D default
            %   view angle.
            %
            %   CFTOOL wants to control rotate3D mode's "Reset to Original
            %   View" functionality. Specifically, when users choose that
            %   option, we want the view angle to be restored to either
            %   CFTOOL's 2D default view angle or CFTOOL's 3D default view
            %   angle. To achieve this, we need to set rotate3D's plotview
            %   information.
            
            % Save the user's view angle.
            currentView = getAxesViewAngle(this);
            
            % Temporarily set the axes to the default view since
            % resetplotview gets its information from axes properties.
            setAxesViewAngle(this, iDefaultViewAngle(this.View2D));
            
            % Save the view.
            resetplotview(this.HAxes, 'SaveCurrentViewPropertyOnly' );
            
            % Restore the user's view angle.
            setAxesViewAngle(this, currentView);
        end
        
        function axesViewModelThreeDViewAngleChanged(this, ~, ~)
            % function axesViewModelThreeDViewAngleChanged(this, src, evt)
            %
            % axesViewModelThreeDViewAngleChanged updates the axes view
            % angle. If View2D is true, it sets the axes view angle to the
            % default 2D angle. Otherwise, it sets the axes view angle to
            % the new 3D angle.
            if this.View2D
                viewAngle = sftoolgui.util.DefaultViewAngle.TwoD;
            else
                viewAngle = this.AxesViewModel.ThreeDViewAngle;
            end
            setAxesViewAngle(this, viewAngle);
        end
        
        function axesViewChanged(this, ~, ~)
            %function axesViewChanged(this, src, event)
            %
            % axesViewChanged sets the AxesViewModel's ThreeDViewAngle
            % property.
            this.AxesViewModel.ThreeDViewAngle = getAxesViewAngle(this);
        end
    end
end

function defaultViewAngle = iDefaultViewAngle(show2DView)
% iDefaultViewAngle returns the default view angle of the requested
% dimension.
if show2DView
    defaultViewAngle = sftoolgui.util.DefaultViewAngle.TwoD;
else
    defaultViewAngle = sftoolgui.util.DefaultViewAngle.ThreeD;
end
end


