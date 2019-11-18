classdef (Sealed) AxesViewModel < sftoolgui.AxesViewModelInterface
    %AxesViewModel is the model for axes View and Limits properties
    
    %   Copyright 2011-2012 The MathWorks, Inc.
    
    properties
        % ThreeDViewAngle is view angle of a non-curve plot
        ThreeDViewAngle = sftoolgui.util.DefaultViewAngle.ThreeD;
    end
    
    properties (Dependent)
        % XInputLimits are the limits for the x input
        XInputLimits;
        
        % YInputLimits are the limits for the y input
        YInputLimits;
        
        % ResponseLimits are the limits for the response data
        ResponseLimits;
        
        % ResidualLimits are the limits for the residuals response data
        ResidualLimits;
    end
    
    properties (Access = private)
        
        % PrivateXInputLimits -- Private storage of XInputLimits
        PrivateXInputLimits = [-1, 1];
        
        % PrivateYInputLimits -- Private storage of YInputLimits
        PrivateYInputLimits = [-1, 1];
        
        % PrivateResponseLimits -- Private storage of ResponseLimits
        PrivateResponseLimits = [-1, 1];
        
        % PrivateResidualLimits  -- Private storage of ResidualLimits
        PrivateResidualLimits = [-1, 1];
        
    end
    
    methods
        function set.ThreeDViewAngle(this, view)
            this.ThreeDViewAngle = view;
            notify (this, 'ThreeDViewAngleChanged');
        end
        
        function setLimits(this, input, output, residuals)
            % setLimits will set all limit properties and then fire a
            % single LimitsChanged event.
            %
            % INPUT is a cell array of length 1 or 2. The first item is
            % assigned to XInputLimits. If there is a second item, it is
            % assigned to YInputLimits. If there is no second item,
            % YInputLimits is set to the default value.
            %
            % OUTPUT and RESIDUALS can be either specified or empty. If
            % specified, ResponseLimits and ResidualLimits will be set
            % respectively. If empty, that property is not changed.
            
            setInputLimitsQuietly(this, input);
            setLimitQuietly(this, 'PrivateResponseLimits', output);
            setLimitQuietly(this, 'PrivateResidualLimits', residuals);
            notify (this, 'LimitsChanged');
        end
               
        function set.XInputLimits(this, limit)
            setLimitLoudly(this, 'PrivateXInputLimits', limit)
        end
        
        function limit = get.XInputLimits(this)
            limit = this.PrivateXInputLimits;
        end
        
        function set.YInputLimits(this, limit)
            setLimitLoudly(this, 'PrivateYInputLimits', limit)
        end
        
        function limit = get.YInputLimits(this)
            limit = this.PrivateYInputLimits;
        end
        
        function set.ResponseLimits(this, limit)
            setLimitLoudly(this, 'PrivateResponseLimits', limit)
        end
        
        function limit = get.ResponseLimits(this)
            limit = this.PrivateResponseLimits;
        end
        
        function set.ResidualLimits(this, limit)
            setLimitLoudly(this, 'PrivateResidualLimits', limit)
        end
        
        function limit = get.ResidualLimits(this)
            limit = this.PrivateResidualLimits;
        end
    end
    
    methods(Access = private)
        function setLimitLoudly( this, name, limits )
            % Set the NAME property to LIMITS (if LIMITS are valid limits) and
            % fire a LimitsChanged event
            setLimitQuietly(this, name, limits);
            notify( this, 'LimitsChanged' );
        end
        
        function setLimitQuietly( this, name, limits )
            % setLimitQuietly will set the NAME property to LIMITS if LIMITS
            % are valid limits. Note: This method does not fire a
            % LimitsChanged event.
            if iIsValidLimit( limits )
                limits = iEnsureMinimumSeperation(limits);
                this.(name) = limits;
            end
        end
        
        function setInputLimitsQuietly(this, inputs)
            % setInputLimits sets PrivateXInputLimits and
            % PrivateYInputLimits.
            
            % Set PrivateXInputLimits
            setLimitQuietly(this, 'PrivateXInputLimits', inputs{1});
            
            % If there is only one input limit ...
            if length(inputs) == 1
                % ... then we assume that this is for curve data and we set
                % the PrivateYInputLimits to the default value.
                this.PrivateYInputLimits = [-1 1];
            else
                % ... otherwise we set the PrivateYInputLimits to the requested value.
                setLimitQuietly( this, 'PrivateYInputLimits', inputs{2} );
            end
        end
    end
end

function tf = iIsValidLimit( value )
% iIsValidLimit  Check limit validity.

% Valid limits are a 1x2 vector of finite values where second value is
% greater than the first.

tf = isequal( size( value ), [1, 2] ) && all( isfinite( value ) ) ...
    && value(1) < value(2);

end

function newValidLimits = iEnsureMinimumSeperation(newLimits)
% ensures that the limits have 5 digits and are at least min distance apart
roundedLimits = iRoundLimitsToNSignificantDigits(newLimits, 5);
newLimits = iRoundLimitsToNSignificantDigits(newLimits, 9);

minAllowedSeperation = iCalculateMinimumSeperation(roundedLimits);

% make sure newValidLimits are strictly outside of roundedLimits
if newLimits(1) < roundedLimits(1)
    newValidLimits(1) = roundedLimits(1)-minAllowedSeperation;
else
    newValidLimits(1) = roundedLimits(1);
end
if roundedLimits(2) < newLimits(2)
    newValidLimits(2) = roundedLimits(2)+minAllowedSeperation;
else
    newValidLimits(2) = roundedLimits(2);
end

% Make sure that rounding has not caused the limits to become identical
if newValidLimits(1) >= newValidLimits(2)
    tempVal = newValidLimits(1);
    newValidLimits(1) = tempVal - minAllowedSeperation;
    newValidLimits(2) = tempVal + minAllowedSeperation;
end
end

function roundedMinAllowedSeperation = iCalculateMinimumSeperation(limits)
% Calculates the minimun distance between the min/max values of a limit
% this is 0.01% of the largest absolute limit. The minimum value is rounded
% to have one 1 and all other values are 0.
minimumRelativeSeperation = 0.0001; % = .01% of the scale
scale = max(abs(limits));
minAbsoluteSeperation = scale*minimumRelativeSeperation;
% Round down min allowed range to have a 1 as the most significant number and
% 0's otherwise
pwr = floor(log10(minAbsoluteSeperation));
roundedMinAllowedSeperation = 10^pwr;
end

function limits = iRoundLimitsToNSignificantDigits(limits, N)
% Only take the 5 most significant digits of the limits
pow = floor(log10(max(abs(limits))));
shift = 10^(N-1-pow);
limits = round(limits*shift)/shift;
end