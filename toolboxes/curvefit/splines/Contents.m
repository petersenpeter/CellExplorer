% Curve Fitting Toolbox -- Spline Functions
%
% GUIs.
%   splinetool - Experiment with some spline approximation methods.
%   bspligui   - Experiment with B-spline as function of its knots.
%
% Constructions of splines.
%
%   csape    - Cubic spline interpolation with end-conditions.
%   csapi    - Cubic spline interpolation.
%   csaps    - Cubic smoothing spline.
%   cscvn    - `Natural' or periodic cubic spline curve.
%   getcurve - Interactive creation of cubic spline curve.
%   ppmak    - Put together spline in ppform.
%
%   spap2    - Least squares spline approximation.
%   spapi    - Spline interpolation.
%   spaps    - Smoothing spline.
%   spcrv    - Spline curve by uniform subdivision.
%   spmak    - Put together spline in B-form.
%
%   rpmak    - Put together rational spline in rpform.
%   rscvn    - Interpolating piecewise circular-arc curve in rBform.
%   rsmak    - Put together rational spline in rBform.
%
%   stmak    - Put together function in stform.
%   tpaps    - Thin-plate smoothing spline.
%
% Operations on splines (in whatever form, B-form, ppform, rBform, stform, ...
%                          univariate or multivariate)
%   fnbrk    - Name and part(s) of form.
%   fnchg    - Change part of form.
%   fncmb    - Arithmetic with function(s).
%   fnder    - Differentiate function.
%   fndir    - Directional derivative of function.
%   fnint    - Integrate function.
%   fnjmp    - Jumps, i.e., f(x+) - f(x-) .
%   fnmin    - Minimum of function in given interval.
%   fnplt    - Plot function.
%   fnrfn    - Insert additional points into partition of form.
%   fntlr    - Taylor coefficients or polynomial.
%   fnval    - Evaluate function.
%   fnxtr    - Extrapolate function.
%   fnzeros  - Zeros of function in given interval.
%   fn2fm    - Convert to specified form.
%
% Work on knots, breaks, and sites.
%   aptknt   - Acceptable knot sequence.
%   augknt   - Augment knot sequence.
%   aveknt   - Knot averages.
%   brk2knt  - Convert breaks with multiplicities into knots.
%   chbpnt   - Good data sites, the Chebyshev-Demko points.
%   knt2brk  - Convert knots to breaks and their multiplicities.
%   knt2mlt  - Knot multiplicities.
%   newknt   - New break distribution.
%   optknt   - Knot distribution "optimal" for interpolation.
%   sorted   - Locate sites with respect to meshsites.
%
% Spline construction tools.
%   spcol    - B-spline collocation matrix.
%   stcol    - Scattered translates collocation matrix.
%   slvblk   - Solve almost block-diagonal linear system.
%   bkbrk    - Part(s) of almost block-diagonal matrix.
%
% Spline conversion tools.
%   splpp    - Left Taylor coefficients from local B-coefficients.
%   sprpp    - Right Taylor coefficients from local B-coefficients.
%
% Functions and data.
%   franke   - Franke's bivariate test function.
%   subplus  - Positive part.
%   titanium - Test data.
%
% Information about splines and the toolbox.
%   bspline  - Plots a B-spline and its polynomial pieces.
%   spterms  - Explanation of spline terms.

%   Copyright 1987-2017 The MathWorks, Inc.

% Undocumented files.

% Helper files.
%   chckxywp - Check and adjust input for *AP* commands.

% Form-specific functions called by FN commands.
%   pp2sp    - Convert from ppform to B-form.
%   ppbrk    - Part(s) of a ppform.
%   pprfn    - Insert additional breaks into a ppform.
%   ppual    - Evaluate function in ppform.
%   rpbrk    - Part(s) of a rpform.
%   rsbrk    - Part(s) of a rational spline in B-form
%   rsval    - Evaluate rational spline.
%   sp2bb    - Convert from B-form to BBform.
%   sp2pp    - Convert from B-form to ppform.
%   spbrk    - Part(s) of a B-form or a BBform.
%   sprfn    - Insert additional knots into B-form of a spline.
%   spval    - Evaluate function in B-form.
%   stbrk    - Part(s) of an stform.
%   stval    - Evaluate function in stform.
