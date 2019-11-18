function varargout = rsbrk(rs,varargin)
%RSBRK Part(s) of a rational spline in B-form
%
%   OUT1 = RSBRK(RS,PART) returns the part specified by the string PART which 
%   may be (the beginning character(s) of) one of the following strings: 
%   'knots' or 't', 'coefs', 'number', 'order', 'dim'ension, 'interval'.
%
%   VALUE = RSBRK(RP,[A B])  returns the restriction to the interval  [A .. B]  
%   of the function in RS.
%
%   [OUT1,...,OUTo] = RSBRK(PP, PART1,...,PARTi)  returns in OUTj the part 
%   specified by the string PARTj, j=1:o, provided o<=i.
%
%   RSBRK(RS) returns nothing, but prints out all the parts.
%
%   See also RSMAK, RPBRK, PPBRK, SPBRK, FNBRK.

%   Copyright 1987-2011 The MathWorks, Inc.

if ~isstruct(rs)||~isequal(rs.form([1 2]),'rB')
   error(message('SPLINES:RSBRK:notrBform'))
end

if nargin>1 % we have to hand back one or more parts
   lp = max(1,nargout);
   if lp>length(varargin)
      error(message('SPLINES:RSBRK:moreoutthanin'))
   end
   varargout = cell(1,lp);
   for jp=1:lp
      part = varargin{jp};
      if ischar(part)
         if isempty(part)
	    error(message('SPLINES:RSBRK:partemptystr'))
	 end
         switch part(1)
         case 'f',       out1 = [rs.form,'form'];
         case 'd',       out1 = rs.dim;
         case 'n',       out1 = rs.number;
         case {'k','t'}, out1 = rs.knots;
         case 'o',       out1 = rs.order;
         case 'c',       out1 = rs.coefs;
         case 'v',       out1 = length(rs.order);
         case 'i', % this must be treated differently in multivariate case
            if iscell(rs.knots)
               for i=length(rs.knots):-1:1  % loop backward to avoid redef.
                  out1{i} = rs.knots{i}([1 end]);
               end
            else
               out1 = rs.knots([1 end]);
            end
	 case 'b', % this must be treated differently in multivariate case
	    if iscell(rs.knots)
               for i=length(rs.knots):-1:1  % loop backward to avoid redef.
                  out1{i} = knt2brk(rs.knots{i});
               end
            else
               out1 = knt2brk(rs.knots);
            end
         otherwise
            error(message('SPLINES:RSBRK:wrongpart', part))
         end
      else % we are to restrict RP to some interval or piece
         out1 = fn2fm(fnbrk(fn2fm(rs,'B-'),part),'rB');
      end
      varargout{jp} = out1;
   end    
else
   if nargout==0
      if iscell(rs.knots) % we have a multivariate spline and, at present,
                          % I can't think of anything clever to do; so...
         disp(rs)
      else
        disp('knots(1:n+k)'),disp(rs.knots),
        disp('coefficients(d+1,n)'),disp(rs.coefs),
        disp(getString(message('SPLINES:resources:NumberOfCoefficients'))),disp(rs.number),
        disp(getString(message('SPLINES:resources:OrderK'))),disp(rs.order),
        disp(getString(message('SPLINES:resources:DimensionOfTarget'))),disp(rs.dim),
      end
   else
      error(message('SPLINES:RSBRK:toomanyouts'))
   end
end
