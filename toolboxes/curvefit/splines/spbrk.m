function varargout = spbrk(sp,varargin)
%SPBRK Part(s) of a B-form or a BBform.
%
%   [KNOTS,COEFS,N,K,D] = SPBRK(SP) breaks the B-form in SP into its parts and
%   returns as many of them as are specified by the output arguments.
%
%   OUT1 = SPBRK(SP,PART) returns the part specified by the string PART which
%   may be (the beginning character(s) of) one of the following strings:
%   'knots' or 't', 'coefs', 'number', 'order', 'dimension', 'interval',
%   'breaks'.
%
%   If PART is the 1-by-2 matrix [A,B], the restriction/extension of the spline
%   in SP to the interval with endpoints A and B is returned, in the same form.
%
%   [OUT1,...,OUTo] = SPBRK(SP, PART1,...,PARTi)  returns in OUTj the part
%   specified by the string PARTj, j=1:o, provided o<=i.
%
%   SPBRK(SP) returns nothing, but prints out all the parts.
%
%   See also PPBRK, FNBRK, RSBRK, RPBRK.

%   Copyright 1987-2011 The MathWorks, Inc.

if ~isstruct(sp)
  if sp(1)~=11&&sp(1)~=12
     error(message('SPLINES:SPBRK:fnotBform'))
  else
     di=sp(2);ni=sp(3);
     ci=reshape(sp(3+(1:di*ni)),di,ni);
     kk=sp(4+di*ni);ki=sp(4+di*ni+(1:kk+ni));
     sp = spmak(ki,ci);
  end
end

if length(sp.form)~=2||sp.form(1)~='B'
   error(message('SPLINES:SPBRK:snotBform'))
end
if nargin>1 % we have to hand back one or more parts
   lp = max(1,nargout); % SPBRK(SP,PART) may be part of an expression
   if lp>length(varargin)
      error(message('SPLINES:SPBRK:moreoutthanin'))
   end
   varargout = cell(1,lp);
   for jp=1:lp
       part = varargin{jp};
       if ischar(part)
           if isempty(part)
               error(message('SPLINES:SPBRK:partemptystr'))
           end
           switch part(1)
               case 'f',       out1 = [sp.form,'form'];
               case 'd',       out1 = sp.dim;
               case 'n',       out1 = sp.number;
               case {'k','t'}, out1 = sp.knots;
               case 'o',       out1 = sp.order;
               case 'c',       out1 = sp.coefs;
               case 'v',       out1 = length(sp.order);
               case 'i', % this must be treated differently in multivariate case
                   if iscell(sp.knots)
                       for i=length(sp.knots):-1:1  % loop backward to avoid redef.
                           out1{i} = sp.knots{i}([1 end]);
                       end
                   else
                       out1 = sp.knots([1 end]);
                   end
               case 'b', % this must be treated differently in multivariate case
                   if iscell(sp.knots)
                       for i=length(sp.knots):-1:1  % loop backward to avoid redef.
                           out1{i} = knt2brk(sp.knots{i});
                       end
                   else
                       out1 = knt2brk(sp.knots);
                   end
               otherwise
                   error(message('SPLINES:SPBRK:wrongpart', part))
           end
      elseif isempty(part)
	 out1 = sp;
      else
         if iscell(part)  % we must be dealing with a tensor-product spline
            c = sp.coefs; knots = sp.knots; m = length(knots);
            sizec = size(c);
            if length(sizec)~=m+1 % trouble because of trailing singleton dims
               sizec = [sp.dim,sp.number]; c = reshape(c,sizec);
            end
            for i=m:-1:1
               dd = prod(sizec(1:m));
               spi = spcut(spmak(knots{i},reshape(c,dd,sp.number(i))), part{i});
               knots{i} = spi.knots; sizec(m+1) = spi.number;
               c = reshape(spi.coefs,sizec);
               if m>1
                  c = permute(c,[1,m+1,2:m]);
                  sizec(2:m+1) = sizec([m+1,2:m]);
               end
            end
            out1 = spmak(knots,c,sizec);

         else             % we must be dealing with a univariate spline
            out1 = spcut(sp,part);
         end
      end
      varargout{jp} = out1;
   end
else
   if nargout==0
     if iscell(sp.knots) % we have a multivariate spline and, at present,
                         % I can't think of anything clever to do; so...
       disp(sp)
     else
       disp('knots(1:n+k)'),disp(sp.knots),
       disp('coefficients(d,n)'),disp(sp.coefs),
       disp(getString(message('SPLINES:resources:NumberOfCoefficients'))),disp(sp.number),
       disp(getString(message('SPLINES:resources:OrderK'))),disp(sp.order),
       disp(getString(message('SPLINES:resources:DimensionOfTarget'))),disp(sp.dim),
     end
   else
    varargout = {sp.knots,sp.coefs, sp.number, sp.order, sp.dim};
   end
end
function out1 = spcut(sp,interv)
%SPCUT change the basic interval

if isempty(interv)||ischar(interv), out1 = sp; return, end

sizei = size(interv);
if sizei(2)>1 % we are to change the basic interval
   tl = interv(1,1); tr = interv(1,2);
   if tl==tr
      warning(message('SPLINES:SPBRK:SPCUT:trivialinterval'))
      out1 = sp; return
   end
   if tl>tr, tl = tr; tr = interv(1); end

   index = sorted(sp.knots,[tl,tr]); mults = knt2mlt(sp.knots);
   if tl<sp.knots(1),      m1 = 1;
   elseif tl==sp.knots(1), m1 = 0;
   else                    m1 = sp.order;
      if tl==sp.knots(index(1)), m1 = m1-mults(index(1))-1; end
   end
   if tr>sp.knots(end),      m2 = 1;
   elseif tr==sp.knots(end), m2 = 0;
   else                      m2 = sp.order;
      if tr==sp.knots(index(2)), m2 = m2-mults(index(2))-1; end
   end
   sp = fnrfn(sp, [repmat(tl,1,m1),repmat(tr,1,m2)]);
   index = sorted(sp.knots,[tl tr]);
   if sp.knots(end)>tr
      sp = spmak(sp.knots(1:index(2)),sp.coefs(:,1:(index(2)-sp.order)));
   end
   if sp.knots(1)<tl
      sp = spmak(sp.knots(index(1)-sp.order+1:end), ...
                 sp.coefs(:,index(1)-sp.order+1:end));
   end
   out1 = sp;
else
   error(message('SPLINES:SPBRK:partnotinterv', sprintf( '%g', interv )))
end
