classdef (HandleCompatible) FittypeSpecificationVisitor
    % FittypeSpecificationVisitor is an interface which may be used by a class
    % to perform an action dependent on which fit is currently selected in
    % CFTool.  For example, we may want to update the GUI in a way which is
    % specific to a fit; we may want to build a fit but not know which fit is
    % currently selected.  The visitor allows us to keep this logic away from
    % FitDev
    
    %   Copyright 2013 The MathWorks, Inc.
    
    methods(Abstract)
        % Curves
        visitCustomNonLinearCurveSpecification(this, customLinearCurveSpecification);
        visitLibrarySpecification(this, libraryCurveSpecification);
        visitSmoothingSplineCurveSpecification(this, smoothingSplineCurveSpecification);
        visitCustomLinearCurveSpecification(this, customLinearCurveSpecification);
        visitInterpolantCurveSpecification(this, interpolantCurveSpecification);
        
        % Surfaces
        visitPolynomialSurfaceSpecification(this, polynomialSurfaceSpecification);
        visitLowessSurfaceSpecification(this, lowessSurfaceSpecification);
        visitCustomNonLinearSurfaceSpecification(this, customNonLinearSurfaceSpecification);
        visitInterpolantSurfaceSpecification(this, interpolantSurfaceSpecification);
    end
    
end

