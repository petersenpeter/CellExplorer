function fnew = fnrfn(f,varargin)
%FNRFN Insert additional sites into the partition for F.
%
%   FNEW = FNRFN(F) and FNRFN(F,'mid') both return a description of the
%   function in F in the same form, but with its partition refined by
%   the insertion of the midpoint of each of its partition intervals.
%
%   FNEW = FNRFN(F,ADDPTS) returns a description of the function in F in the
%   same form, but with its partition refined by insertion of the sites in
%   the sequence ADDPTS.
%   If ADDPTS is empty, no sites will be added.
%
%   If the function is in B-form, then ADDPTS are taken as additional
%   knots, to the extent that it does not increase knot multiplicity beyond
%   the order of the spline.
%
%   If the function is in ppform, then any entries of ADDPTS that are not
%   already in the break sequence are used as additional breaks.
%
%   If the function in F is m-variate, then ADDPTS must be a cell-array,
%   of length m, whose j-th cell specifies the additional sites, if any,
%   for the j-th variable.
%
%   Examples:
%   We construct a spline in B-form, plot it, then apply two midpoint
%   refinements, and also plot the control polygon of the resulting refined
%   spline, expecting it to be quite close to the spline itself:
%
%      k = 4; sp = spapi( k, [1,1:10,10], [cos(1),sin(1:10),cos(10)] );
%      fnplt(sp), hold on
%      sp3 = fnrfn(fnrfn(sp));
%      plot( aveknt( fnbrk(sp3,'knots'),k), fnbrk(sp3,'coefs'), 'r')
%      hold off
%
%   A third refinement would have made the two curves indistiguishable.
%
%   As another example, we use FNRFN to add two B-splines of the same order.
%
%      B1 = spmak([0:4],1); B2 = spmak([2:6],1);
%      B1r = fnrfn(B1,fnbrk(B2,'knots'));
%      B2r = fnrfn(B2,fnbrk(B1,'knots'));
%      B1pB2 = spmak(fnbrk(B1r,'knots'),fnbrk(B1r,'c')+fnbrk(B2r,'c'));
%      fnplt(B1,'r'),hold on, fnplt(B2,'b'), fnplt(B1pB2,'y',2)
%      hold off
%
%   See also PPRFN, SPRFN, FNCMB.

%   Copyright 1987-2008 The MathWorks, Inc.

if ~isstruct(f), f = fn2fm(f); end

switch f.form(1:2)
case {'B-','BB'},  fnew = sprfn(f,varargin{:});
case 'pp',         fnew = pprfn(f,varargin{:});
case 'rB',         fnew = fn2fm(sprfn(fn2fm(f,'B-'),varargin{:}),'rB');
case 'rp',         fnew = fn2fm(pprfn(fn2fm(f,'pp'),varargin{:}),'rp');
case 'st'
   error(message('SPLINES:FNPLT:notforst'))
otherwise
   error(message('SPLINES:FNPLT:unknownfn'))
end
