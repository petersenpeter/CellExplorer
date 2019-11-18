function [expl,term] = spterms(term)
%SPTERMS Explanation of spline terms in Curve Fitting Toolbox.
%
%   EXPL = SPTERMS(TERM) returns a cell array of strings containing an
%   explanation of the term specified by the string TERM.
%
%   Here are the possibilities:
%    'B-form',  'basic interval'
%    'B-spline','breaks'
%    'cubic spline interpolation', 'endconditions'
%    'not-a-knot', 'clamped', 'second', 'periodic', 'variational', 'Lagrange'
%    'cubic smoothing spline', 'quintic smoothing spline'
%    'error'
%    'knots',  'end knots', 'interior knots'
%    'least squares'
%    'NURBS', 'rational spline', 'rBform', 'rpform'
%    'roughness measure'
%    'thin-plate spline', 'centers', 'stform', 'basis function'
%    'spline'
%    'spline interpolation', 'Schoenberg-Whitney conditions'
%    'order'
%    'ppform'
%    'sites_etc'
%    'weight in roughness measure'
%
%   Only the first so many (at least 2, but usually no more than 2) letters
%   of a term need to be supplied, with the optional second output argument
%   providing the full term understood.
%
%   SPTERMS(TERM) without an output argument returns nothing, but puts the
%   explanation into a message box, with the full term understood in its title.

%   Copyright 1987-2012 The MathWorks, Inc.

if ~ischar(term)||length(term)<2
    error(message('SPLINES:SPTERMS:wrongterm'))
end

switch term(1:2)
    case 'B-'
        if length(term)<3
            error(message('SPLINES:SPTERMS:unclearBterm'))
        end
        if term(3)=='f'
            term = 'B-form';
            mess =...
                {getString(message('SPLINES:resources:term_Bform'))};
        else
            term = 'B-spline';
            mess = {...
                getString(message('SPLINES:resources:term_BSplinesLine1')),...
                '', ...
                getString(message('SPLINES:resources:term_BSplinesLine2')),...
                '', ...
                getString(message('SPLINES:resources:term_BSplinesLine3')),...
                '', ...
                getString(message('SPLINES:resources:term_BSplinesLine4', 'sum_{i=j-k+1:j} B( . | t(i:i+k) ) = 1')),...
                '', ...
                getString(message('SPLINES:resources:term_BSplinesLine5'))
                };
        end
        
    case 'ba'
        switch term(5)
            case 'c'
                term = 'basic interval';
                mess =...
                    {sprintf('%s\n%s\n%s\n\n%s',...
                    getString(message('SPLINES:resources:term_BasicIntervalLine1')),...
                    getString(message('SPLINES:resources:term_BasicIntervalLine2')),...
                    getString(message('SPLINES:resources:term_BasicIntervalLine3')),...
                    getString(message('SPLINES:resources:term_BasicIntervalLine4')))};
            case 's'
                term = 'basis function';
                mess = getString(message('SPLINES:resources:term_BasisFunction'));
        end
        
    case 'br'
        term = 'breaks';
        mess = ...
            {sprintf('%s\n\n%s',...
            getString(message('SPLINES:resources:term_BreaksLine1')),...
            getString(message('SPLINES:resources:term_BreaksLine2')))};
        
    case 'cu'
        if length(term)<8
            error(message('SPLINES:SPTERMS:unclearCubicterm'))
        end
        if term(8)=='p'
            term = 'cubic spline interpolation';
            mess = ...
                {sprintf('\n%s\n\n%s\n',...
                getString(message('SPLINES:resources:term_CubicSplineLine1')),...
                getString(message('SPLINES:resources:term_CubicSplineLine2')))};
        else
            term = 'cubic smoothing spline';
            mess = {
                getString(message('SPLINES:resources:term_CubicSmoothingSplineLine1')),...
                '', ...
                getString(message('SPLINES:resources:term_CubicSmoothingSplineLine3')),...
                '', ...
                getString(message('SPLINES:resources:term_CubicSmoothingSplineLine4'))
                };
        end
        
        % end conditions
    case 'no'
        term = 'not-a-knot end condition';
        mess = getString(message('SPLINES:resources:term_NotAKnot'));
    case 'cl'
        term = 'clamped end condition';   % complete or clamped or first derivative
        mess = getString(message('SPLINES:resources:term_ClampedOrComplete'));
    case 'se'
        term = 'second end condition';   % second derivative
        mess = getString(message('SPLINES:resources:term_SecondEndCondition'));
    case 'pe'
        term = 'periodic end condition';
        mess = getString(message('SPLINES:resources:term_PeriodicEndCondition'));

    case 'va'
        term = 'variational end condition';  % variational
        mess = ...
            {sprintf('%s\n\n%s',...
            getString(message('SPLINES:resources:term_VariationalLine1')),...
            getString(message('SPLINES:resources:term_VariationalLine2')))};
    case 'La'
        term = 'Lagrange end condition';
        mess = getString(message('SPLINES:resources:term_Lagrange'));
    case 'ro'
        term = 'roughness measure';
        mess = getString(message('SPLINES:resources:term_RoughnessMeasureLine1'));
    case 'we'
        term = 'weight in roughness measure';
        mess = {
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine1')),...
            '', ...
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine4','x_{i-1} .. x_i)'))
            };
            
    case 'kn'
        term = 'knots';
        mess = ...
            {sprintf('\n%s\n\n%s\n\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_KnotsLine1')),...
            getString(message('SPLINES:resources:term_KnotsLine2')),...
            getString(message('SPLINES:resources:term_KnotsLine3','S_{k,t}')),...
            getString(message('SPLINES:resources:term_KnotsLine4')))};
        
    case 'en'
        term = 'end knots';
        mess = ...
            {sprintf('\n%s\n\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_EndKnotsLine1')),...
            getString(message('SPLINES:resources:term_EndKnotsLine2')),...
            getString(message('SPLINES:resources:term_EndKnotsLine3')))};
    case 'er'
        term = 'error';
        mess = ...
            {sprintf('%s\n\n%s',...
            getString(message('SPLINES:resources:term_ErrorLine1')),...
            getString(message('SPLINES:resources:term_ErrorLine2')))};
    case 'in'
        term = 'interior knots';
        mess = ...
            {sprintf('%s\n\n%s',...
            getString(message('SPLINES:resources:term_InteriorKnotsLine1')),...
            getString(message('SPLINES:resources:term_InteriorKnotsLine2')))};
        
    case 'le'
        term = 'least squares';
        mess = ...
            {sprintf('%s\n\n%s\n%s',...
            getString(message('SPLINES:resources:term_LeastSquaresLine1')),...
            getString(message('SPLINES:resources:term_LeastSquaresLine2')),...
            getString(message('SPLINES:resources:term_LeastSquaresLine3')))};
        
    case {'NU','nu'}
        term = 'NURBS';
        mess = getString(message('SPLINES:resources:term_NURBS'));
    case 'ra'
        term = 'rational spline';
        mess = ...
            {getString(message('SPLINES:resources:term_RationalSplineLine1'));...
            '';...
            getString(message('SPLINES:resources:term_RationalSplineLine3'))};
    case 'rB'
        term = 'rBform';
        mess = getString(message('SPLINES:resources:term_RBform'));
    case 'rp'
        term = 'rpform';
        mess = getString(message('SPLINES:resources:term_Rpform'));
    case 'st'
        term = 'stform';
        mess = ...
            {getString(message('SPLINES:resources:term_StformLine1'));'';
            getString(message('SPLINES:resources:term_StformLine2'))};
    case 'th'
        term = 'thin-plate spline';
        mess = getString(message('SPLINES:resources:term_ThinplateSpline'));
    case 'ce'
        term = 'centers';
        mess = getString(message('SPLINES:resources:term_Centers'));
    case 'qu'
        term = 'quintic smoothing spline';
        mess = {...
            getString(message('SPLINES:resources:term_QuinticSmoothingSplineLine1'));'';
            getString(message('SPLINES:resources:term_QuinticSmoothingSplineLine2'))};
    case {'sp','Sc'} % this one, we have to split further
        if ~any( term == ' ' ) && term(2)~='c'
            term = 'spline';
            mess = getString(message('SPLINES:resources:term_Spline'));
        else
            switch term(2)
                case 'p'
                    term = 'spline interpolation';
                case 'c'
                    term = 'Schoenberg-Whitney conditions';
            end
            
            mess = {
                getString(message('SPLINES:resources:term_SplineInterpolantLine1'));'';
                getString(message('SPLINES:resources:term_SplineInterpolantLine2'));'';
                getString(message('SPLINES:resources:term_SplineInterpolantLine4'));'';
                getString(message('SPLINES:resources:term_SplineInterpolantLine5'));...
                getString(message('SPLINES:resources:term_SplineInterpolantLine6'))
                };
        end
        
    case 'or'
        term = 'order';
        mess = ...
            {getString(message('SPLINES:resources:term_OrderLine1'));'';
            getString(message('SPLINES:resources:term_OrderLine2'))};
        
    case 'pp'
        term = 'ppform';
        mess = getString(message('SPLINES:resources:term_Pform'));
        
    case 'si'
        term = 'sites_etc';
        mess = {
            getString(message('SPLINES:resources:term_SitesLine1'));'';
            getString(message('SPLINES:resources:term_SitesLine2'))
            };
        
    otherwise
        mess = getString(message('SPLINES:resources:term_NothingYet'));
end

if nargout>0
    if ~iscell( mess )
        mess = {mess};
    end
    expl = mess;
else
    msgbox(mess, getString(message('SPLINES:resources:dlgTitle_Explanation', term )))
end
