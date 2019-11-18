function g = fn2fm( f, form, sconds )
%FN2FM Convert to specified form.
%
%   FN2FM(F,FORM)  converts the function in F to the specified FORM.
%   Present choices for FORM are: 'pp', 'B-', 'BB', 'rp', 'rB'.
%   See the relevant ..mak commands for specifics of such a form.
%
%   FN2FM(F,FORM,SCONDS)  uses additional information in SCONDS to help in
%   the conversion from ppform to B-form. In this conversion, the actual
%   smoothness of the function in F across each of its interior breaks has to
%   be guessed.
%   If 0 < SCONDS(1) < 1, then this is done by looking for the derivative
%   of smallest order whose jump across that break is, in absolute value,
%   greater than SCONDS(1) times the absolute value of that derivative
%   nearby.  The default value for this tolerance SCONDS(1) is 1.e-12.
%   Otherwise, if SCONDS is a vector with exactly as many entries as F has
%   interior breaks, then SCONDS(i) smoothness conditions are imposed at the
%   i-th interior break.
%   If the function in F is a tensor product, then SCONDS, if given, must
%   be a cell array.
%
%   FN2FM(F)  converts a possibly old version of a form into its present
%   version.
%
%   Examples:
%
%      sp = fn2fm(spline(x,y),'B-');
%
%   gives the interpolating cubic spline provided by MATLAB's SPLINE,
%   but in B-form (i.e., described as a linear combination of B-splines).
%
%      p0 = ppmak([0 1],[3 0 0]);
%      p1 = fn2fm(fn2fm(fnrfn(p0,[.4 .6]),'B-'),'pp');
%
%   gives  p1  identical to  p0  (up to round-off) since the spline has no
%   discontinuity in any derivative across the additional breaks introduced
%   by FNRFN, hence conversion to B-form ignores these additional breaks, and
%   conversion to ppform does not retain any knot multiplicities (like
%   the knot multiplicities introduced, by conversion to B-form, at the
%   endpoints of the spline's basic interval).
%
%      nurb = fn2fm(f,'rB');
%
%   converts the (d+1)-valued spline in  f  into B-form if need be, then
%   converts to rBform, i.e., into a d-valued rational spline or nurbs,
%   by designating its (d+1)st component as the denominator, provided d>0.
%
%   See also PP2SP, SP2PP, SP2BB.

%   Copyright 1987-2012 The MathWorks, Inc.

if ~isstruct(f) && numel(f)<2 % reject empty F or F that's just a scalar
    error(message('SPLINES:FN2FM:notafunction'))
end

if nargin==1 % set FORM to convert the form in F into its current version
    if isstruct(f)
        form = f.form;
    else
        form = iFormOfArray(f);
    end
else
    if length(form)<2
        error(message('SPLINES:FN2FM:unknownform'));
    end
end

switch form(1:2)
    case 'pp'
        if isstruct(f)
            switch f.form(1:2)
                case 'pp'
                    g = f;
                case 'rp'
                    g = f;
                    g.form = 'pp';
                    g.dim = g.dim+1;
                case 'rB'
                    f.form = 'B-';
                    f.dim = f.dim+1;
                    g = sp2pp(f);
                case {'B-','BB'},
                    g = sp2pp(f);
            end
        else
            switch f(1)
                case 10
                    [b,c,~,~,d] = ppbrk(f);
                    g = ppmak(b,c,d);
                case {11,12}
                    g = sp2pp(f);
            end
        end
    case {'sp','B-'}
        form = 'B-';
        if isstruct(f)
            switch f.form(1:2)
                case 'pp'
                    if nargin<3
                        g = pp2sp(f);
                    else
                        g = pp2sp(f,sconds);
                    end
                case 'rp'
                    f.form = 'pp';
                    f.dim = f.dim+1;
                    g = pp2sp(f);
                case 'rB'
                    g = f;
                    g.form = 'B-';
                    g.dim = g.dim+1;
                case 'B-'
                    g = f;
                case 'BB'
                    g = pp2sp(sp2pp(f));
            end
        else
            switch f(1)
                case 10
                    g = pp2sp(f);
                case 11
                    [knots,coefs] = spbrk(f);
                    g = spmak(knots,coefs);
                case 12
                    g = pp2sp(sp2pp(f));
            end
        end
    case {'bb','BB'}
        form = 'BB';
        if isstruct(f)
            switch f.form(1:2)
                case 'pp'
                    g = sp2bb(pp2sp(f));
                case 'rp'
                    f.form = 'pp';
                    f.dim = f.dim+1;
                    g = sp2bb(pp2sp(f));
                case 'rB'
                    f.form = 'B-';
                    f.dim = f.dim+1;
                    g = sp2bb(f);
                case 'B-'
                    g = sp2bb(f);
                case 'BB'
                    g = f;
            end
        else
            switch f(1)
                case 10
                    g = sp2bb(pp2sp(f));
                case 11
                    g = sp2bb(f);
                case 12
                    [knots,coefs] = spbrk(f);
                    g = spmak(knots,coefs);
                    g.form = 'BB';
            end
        end
    case 'st'
        if isstruct(f)
            switch f.form(1:2)
                case 'st'
                    g = f;
            end
        else
            switch f(1)
                case 25
                    [ce,co] = stbrk(f);
                    g = stmak(ce,co,'tp00');
            end
        end
    case 'rp'  % switch first into ppform if need be
        if isstruct(f)
            switch f.form(1:2)
                case 'pp'
                    g = f;
                case 'rp'
                    g = f;
                    g.dim = g.dim+1;
                case 'rB'
                    g = sp2pp(fn2fm(f,'B-'));
                case {'B-','BB','sp','bb'}
                    g = sp2pp(f);
            end
        else
            switch f(1)
                case 10
                    [b,c,~,~,d] = ppbrk(f);
                    g = ppmak(b,c,d);
                case {11,12}
                    g = sp2pp(f);
            end
        end
        if exist('g','var')
            g.form = 'rp';
            if length(g.dim)>1
                warning( message( 'SPLINES:FN2FM:noNDrats', num2str(g.dim), num2str(prod(g.dim)-1) ) );
                g.dim = prod(g.dim);
            end
            g.dim = g.dim-1;
            if g.dim<1
                error(message('SPLINES:FN2FM:ratneedsmoredim'))
            end
        end
    case 'rB'  % switch first into B-form if need be
        if isstruct(f)
            switch f.form(1:2)
                case 'pp'
                    if nargin<3
                        g = pp2sp(f);
                    else
                        g = pp2sp(f,sconds);
                    end
                case 'rp'
                    g = fn2fm(fn2fm(f,'pp'),'B-');
                case 'rB'
                    g = f;
                    g.dim = g.dim+1;
                case {'B-','BB','sp','bb'}
                    g = f;
            end
        else
            switch f(1)
                case 10
                    g = pp2sp(f);
                case 11
                    g = spmak(fnbrk(f,'knots'),fnbrk(f,'coefs'));
                case 12
                    g = pp2sp(sp2pp(f));
            end
        end
        if exist('g','var')
            g.form = 'rB';
            if length(g.dim)>1
                warning( message( 'SPLINES:FN2FM:noNDrats', ...
                    num2str(g.dim), num2str(prod(g.dim)-1) ) );
                g.dim = prod(g.dim);
            end
            g.dim = g.dim-1;
            if g.dim<1
                error(message('SPLINES:FN2FM:ratneedsmoredim'))
            end
        end
    case 'MA'     % convert univariate spline to old, non-structure ppform.
        if isstruct(f)&&~iscell(f.order)
            switch f.form(1:2)
                case 'pp'
                    g = [10 f.dim f.pieces f.breaks(:).' f.order f.coefs(:).'];
                case {'B-','BB'}
                    f = sp2pp(f);
                    g = [10 f.dim f.pieces f.breaks(:).' f.order f.coefs(:).'];
                otherwise
                    error(message('SPLINES:FN2FM:notintoMA'))
            end
        else
            g = f;
        end
    case 'ol'
        % Convert univariate structured form to corresponding "formerly used array form".
        g = iStructToArray( f );
    otherwise
        error(message('SPLINES:FN2FM:unknownform'));
end

if ~exist('g','var')
    error(message('SPLINES:FN2FM:notintothatform', form))
end

function form = iFormOfArray(f)
% iFormOfArray   Get the form (as a string) from a spline in array format.
switch f(1)
    case 10
        % 'ppform, univariate'
        form = 'pp';
    case 11
        % 'B-form, univariate'
        form = 'B-';
    case 12
        % 'BBform, univariate'
        form = 'BB';
    case 25
        % 'thinplate spline'
        form = 'st-tp00';
    otherwise
        error( message( 'SPLINES:FN2FM:notafunction' ) );
end

function g = iStructToArray( f )
% iStructToArray   Convert from a structure to the "formerly used array form".
if ~isstruct(f)
    error(message('SPLINES:FN2FM:olneedsstruct'))
else
    if length(f.order)>1
        error(message('SPLINES:FN2FM:nonstructneedsuni'))
    else
        switch f.form(1:2)
            case 'pp'
                g = [10 f.dim f.pieces f.breaks(:).' f.order f.coefs(:).'];
            case {'B-','BB'}
                g = [11 f.dim f.number f.coefs(:).' f.order f.knots(:).'];
                if strcmp(f.form(1:2),'BB')
                    g(1) = 12;
                end
            otherwise
                error(message('SPLINES:FN2FM:unknownfn'))
        end
    end
end
