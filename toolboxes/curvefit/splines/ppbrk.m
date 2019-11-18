function varargout = ppbrk(pp,varargin)
%PPBRK Part(s) of a ppform.
%
%   [BREAKS,COEFS,L,K,D] = PPBRK(PP)  breaks the ppform in PP into its parts 
%   and returns as many of them as are specified by the output arguments. 
%
%   PPBRK(PP)  returns nothing, but prints all parts.
%
%   OUT1 = PPBRK(PP,PART)  returns the particular part specified by the string 
%   PART, which may be (the beginning character(s) of) one of the following
%   strings:  
%      'breaks', 'coefs', 'pieces' or 'l', 'order', 'dim', 'interval'.
%   For a while, there is also the choice
%      'guide'
%   that returns the coefficient array in the form required in the ppform used
%   in `A Practical Guide to Splines', especially for PPVALU there. This is not
%   available for vector-valued and/or tensor product splines.
%
%   PJ = PPBRK(PP,J)  returns the ppform of the J-th polynomial piece of the 
%   function in PP.
%
%   PC = PPBRK(PP,[A B])  returns the restriction/extension of the function
%   in PP to the interval  [A .. B], with [] causing PP to be returned as is.
%
%   If PP contains an m-variate spline and PART is not a string, then it
%   must be a cell-array, of length m .
%
%   [OUT1,...,OUTo] = PPBRK(PP, PART1,...,PARTi)  returns in OUTj the part 
%   specified by the string PARTj, j=1:o, provided o<=i.
%
%   Example: If PP contains a bivariate spline with at least 4 pieces
%   in the first variable, then
%
%      ppp = ppbrk(pp,{4,[-1 1]});
%
%   gives the bivariate spline that agrees with the given one on the
%   rectangle  [pp.breaks{1}(4) .. [pp.breaks{1}(5)] x [-1 1] .
%
%   See also SPBRK, FNBRK.

%   Copyright 1987-2011 The MathWorks, Inc.

if ~isstruct(pp)
   if pp(1)~=10
      error(message('SPLINES:PPBRK:unknownfn'))
   else
      ppi = pp;
      di=ppi(2); li=ppi(3); ki=ppi(5+li);

      pp = struct('breaks',reshape(ppi(3+(1:li+1)),1,li+1), ...
                  'coefs',reshape(ppi(5+li+(1:di*li*ki)),di*li,ki), ...
                  'form','pp', 'dim',di, 'pieces',li, 'order',ki);
   end
end 

if ~strcmp(pp.form,'pp')
   error(message('SPLINES:PPBRK:notpp'))
end
if nargin>1 % we have to hand back one or more parts
   np = max(1,nargout);
   if np>length(varargin)
      error(message('SPLINES:PPBRK:moreoutthanin'))
   end
   varargout = cell(1,np);
   for jp=1:np
      part = varargin{jp};

      if ischar(part)
         if isempty(part)
	    error(message('SPLINES:PPBRK:partemptystr'))
	 end
         switch part(1)
         case 'f',       out1 = [pp.form,'form'];
         case 'd',       out1 = pp.dim;
         case {'l','p'}, out1 = pp.pieces;
         case 'b',       out1 = pp.breaks;
         case 'o',       out1 = pp.order;
         case 'c',       out1 = pp.coefs;
	 case 'v',       out1 = length(pp.order);
         case 'g',       % if the spline is univariate, scalar-valued,
                         % return the coefs in the form needed in the ppform
                         % used in PGS.
            if length(pp.dim)>1||pp.dim>1||iscell(pp.order)
               error(message('SPLINES:PPBRK:onlyuniscalar', part))
            else
               k = pp.order;
               out1 = (pp.coefs(:,k:-1:1).').* ...
	                repmat(cumprod([1 1:k-1].'),1,pp.pieces);
            end
         case 'i'
            if iscell(pp.breaks)
               for i=length(pp.order):-1:1
                  out1{i} = pp.breaks{i}([1 end]); end
            else
               out1 = pp.breaks([1 end]);
            end
         otherwise
            error(message('SPLINES:PPBRK:unknownpart', part))
         end
      elseif isempty(part)
	 out1 = pp;
      else % we are to restrict PP to some interval or piece
	 sizeval = pp.dim; if length(sizeval)>1, pp.dim = prod(sizeval); end
         if iscell(part)  % we are dealing with a tensor-product spline
   
            [breaks,c,l,k,d] = ppbrk(pp); m = length(breaks);
            sizec = [d,l.*k]; %size(c);
            if length(sizec)~=m+1
	       error(message('SPLINES:PPBRK:inconsistentfn')),
            end
            for i=m:-1:1
               dd = prod(sizec(1:m));
               ppi = ppbrk1(ppmak(breaks{i},reshape(c,dd*l(i),k(i)),dd),...
                           part{i}) ;
               breaks{i} = ppi.breaks; sizec(m+1) = ppi.pieces*k(i);
               c = reshape(ppi.coefs,sizec);
               if m>1
                  c = permute(c,[1,m+1,2:m]);
                  sizec(2:m+1) = sizec([m+1,2:m]);
               end
            end
            out1 = ppmak(breaks,c, sizec);
   
         else  % we are dealing with a univariate spline
   
            out1 = ppbrk1(pp,part);
         end
         if length(sizeval)>1, out1 = fnchg(out1,'dz',sizeval); end
      end
      varargout{jp} = out1;
   end
else
   if nargout==0
     if iscell(pp.breaks) % we have a multivariate spline and, at present,
                          % I can't think of anything clever to do; so...
       disp(pp)
     else
       disp('breaks(1:l+1)'),        disp(pp.breaks)
       disp('coefficients(d*l,k)'),  disp(pp.coefs)
       disp(getString(message('SPLINES:resources:PiecesNumber'))),      disp(pp.pieces)
       disp(getString(message('SPLINES:resources:OrderK'))),              disp(pp.order)
       disp(getString(message('SPLINES:resources:DimensionOfTarget'))),disp(pp.dim)
       % disp('dimension v of domain'),disp(length(pp.order))
     end
   else
      varargout = {pp.breaks, pp.coefs, pp.pieces, pp.order, pp.dim};
   end
end

function pppart = ppbrk1(pp,part)
%PPBRK1 restriction of pp to some piece or interval

if isempty(part)||ischar(part), pppart = pp; return, end

if size(part,2) > 1 , % extract the part relevant to the interval 
                      % specified by  part =: [a b]  
   pppart = ppcut(pp,part(1,1:2));
else                  % extract the part(1)-th polynomial piece of pp (if any)
   pppart = pppce(pp,part(1));
end

function ppcut = ppcut(pp,interv)
%PPCUT returns the part of pp  specified by the interval interv =: [a b]  

xl = interv(1); xr = interv(2); if xl>xr, xl = xr; xr = interv(1);  end
if xl==xr
   warning(message('SPLINES:PPBRK:PPCUT:trivialinterval'))
   ppcut = pp; return
end
 
%  the first pol. piece is  jl ,
% the one responsible for argument  xl
jl=pp.pieces; index=find(pp.breaks(2:jl)>xl); 
                                   % note that the resulting  index  ...
if (~isempty(index)), jl=index(1); % ... is shifted down by one  ...
end                                % ... because of  breaks(2: ...
%  if xl ~= breaks(jl), recenter the pol.coeffs.
x=xl-pp.breaks(jl);
di = pp.dim;
if x ~= 0
   a=pp.coefs(di*jl+(1-di:0),:);
   for ii=pp.order:-1:2
      for i=2:ii
         a(:,i)=x*a(:,i-1)+a(:,i);
      end
   end
   pp.coefs(di*jl+(1-di:0),:)=a;
end
 
%  the last pol. piece is  jr ,
% the one responsible for argument  xr .
jr=pp.pieces;index=find(pp.breaks(2:jr+1)>=xr); 
                                   % note that the resulting ...
if (~isempty(index)), jr=index(1); % index  is shifted down by
end                                % ... one because of  breaks(2: ...
 
%  put together the cut-down  pp
di = pp.dim;
ppcut = ppmak([xl pp.breaks(jl+1:jr) xr], ...
                        pp.coefs(di*(jl-1)+(1:di*(jr-jl+1)),:),di);

function pppce = pppce(pp,j)
%PPPCE returns the j-th polynomial piece of pp  (if any).

%  if  pp  has a  j-th  piece, ...
if (0<j)&&(j<=pp.pieces)  %             ...  extract it
   di = pp.dim;
   pppce = ppmak([pp.breaks(j) pp.breaks(j+1)], ...
              pp.coefs(di*j+(1-di:0),:),di);
else
   error(message('SPLINES:PPBRK:wrongpieceno', sprintf( '%g', j )));
end
