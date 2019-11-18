function makeAutoLegendable(aGraphic)
% makeAutoLegendable   Make a graphic auto legendable, i.e., if the X-, Y- and
% Z-data for a graphic are all empty or all NaN then the graphic should not be
% represented on the legend.

%   Copyright 2011-2014 The MathWorks, Inc.

iSetLegendable( aGraphic );
iAttachListener( aGraphic );
end

function tf = iIsEmptyData( aGraphic )
% iIsEmptyData   True for a graphic with all of its data fields empty
data = get( aGraphic, {'XData', 'YData', 'ZData'} );
tf = all( cellfun( @isempty, data ) );
end

function tf = iIsAllNotNumber( aGraphic )
% iIsAllNotNumber   True for a graphic which has only NaN for data
data = get( aGraphic, {'XData', 'YData', 'ZData'} );
tf = all( cellfun( @(d) all( isnan( d(:) ) ), data ) );
end

function iAttachListener( aGraphic )
% iAttachListener   Attach listeners to the data properties of a graphic. When
% any of the data properties change, the listener will call iSetLegendable() on
% the graphic.

if isprop( aGraphic, iListenerPropertyName() )
    % do nothing
else
    callback = iMakeCallback( aGraphic );
    
    listeners = {
        curvefit.createListener( aGraphic, 'XData', callback )
        curvefit.createListener( aGraphic, 'YData', callback )
        curvefit.createListener( aGraphic, 'ZData', callback )
        };
    
    iAddProperty( aGraphic, iListenerPropertyName() );
    set( aGraphic, iListenerPropertyName(), listeners );
end
end

function callback = iMakeCallback( aGraphic )
% iMakeCallback   Make a callback (anonymous function) to the iSetLegendable
% function for the given graphic.
callback = @(s, e) iSetLegendable( aGraphic );
end

function iSetLegendable( aGraphic )
% iSetLegendable   Allow or disallow a graphic from the legend subject to it
% having or not having data
curvefit.gui.setLegendable( aGraphic, ~iIsEmptyData( aGraphic ) && ~iIsAllNotNumber( aGraphic ) );
end

function iAddProperty( aGraphic, propertyName )
% iAddProperty   Add a property to a graphic

addprop( aGraphic, propertyName);
end

function name = iListenerPropertyName()
% iListenerPropertyName   Name of the property to use to store the listeners.
name = 'CurvefitLegendableListener';
end
