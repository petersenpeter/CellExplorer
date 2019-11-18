function tf = isAssociatedFit( this, fit )
%isAssociatedFit determines whether or not FIT is the associated fit.

%   Copyright 2010 The MathWorks, Inc.
    tf = (fit == this.HFitdev);
end

