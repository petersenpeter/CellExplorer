function addprop(obj, propname)
%ADDPROP  Add a dynamic property
%
%   addprop(obj,'PropName') adds a property named PropName to OBJ
%
%   Copyright 2011-2014 The MathWorks, Inc.

p = addprop( obj, propname );
p.SetObservable = true;

end
