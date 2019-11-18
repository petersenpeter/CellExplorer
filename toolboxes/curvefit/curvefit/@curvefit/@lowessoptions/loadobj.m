function obj = loadobj( loadedObject )
%LOADOBJ    Method to process CURVEFIT.LOWESSOPTIONS objects after loading.

%   Copyright 2010 The MathWorks, Inc.

% If the loaded object is-a curvefit.lowessoptions.
if isa( loadedObject, 'curvefit.lowessoptions' )
    % ... then there is no post-load processing to do
    obj = loadedObject;
    
else
    % Otherwise, we create a new curvefit.lowessoptions object.
    obj = curvefit.lowessoptions();
    postConstructorSetup( obj )
    
    % Old versions may have an out of range span. Therefore we need to map
    % the span on to the valid range.
    if isfield( loadedObject, 'Span' )
        if loadedObject.Span < 0
            loadedObject.Span = 0;
        elseif loadedObject.Span > 1
            loadedObject.Span = 1;
        end
    end
 
    % Copy values of properties from the loaded object to the new object.
    iCopyProperties( obj, loadedObject );
end

end

function iCopyProperties( obj, src )
% Copy any values properties that have non-default values.
properties = {'Method', 'Normalize', 'Exclude', 'Weights', 'Robust', 'Span'};

for i = 1:length( properties )
    % A property value is saved only if it has non-default value.
    if isfield( src, properties{i} )
        obj.(properties{i}) = src.(properties{i});
    end
end
end
