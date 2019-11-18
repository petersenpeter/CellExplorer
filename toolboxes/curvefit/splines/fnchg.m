function fn = fnchg(fn,part,value)
%FNCHG Change part(s) of a form.
%
%   FNCHG(FN,PART,VALUE) changes the specified PART of FN to the given VALUE.
%   PART can be (the beginning character(s) of)
%      'dimension'     for the dimension of the function's target
%      'interval'      for the basic interval of the function
%
%   Terminating the string PART with the letter z skips any checking
%   of the specified VALUE for PART for consistency with FN.
%
%   Example: FNDIR returns a vector-valued function even when 
%   applied to an ND-valued function. This can be corrected as follows:
%
%      fdir = fnchg( fndir(f,direction), ...
%                    'dim',[fnbrk(f,'dim'),size(direction,2)] );
%
%   See also FNBRK

%   Copyright 1987-2010 The MathWorks, Inc.

if ~ischar(part)
     error(message('SPLINES:FNCHG:partnotstr')), end

switch part(1)
case 'd'
   if part(end)~='z'
      oldvalue = fnbrk(fn,'dim');
      if prod(value)~=prod(oldvalue)
          error( message( 'SPLINES:FNCHG:wrongdim', ...
              num2str(value), num2str(oldvalue) ) );
      end
   end
   fn.dim = value;
case 'i', fn = fnbrk(fn,value);
otherwise
   error(message('SPLINES:FNCHG:wrongpart', part))
end
