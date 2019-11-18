function outliers=excludedata(x,y,method,opt)
%EXCLUDEDATA  Mark some data to be excluded.
%   OUTLIERS = EXCLUDEDATA(XDATA,YDATA,'METHOD',VALUE) returns a logical
%   vector the same size as XDATA and YDATA with 1's marking points to ignore
%   while fitting and 0's marking the points to be included. The points marked
%   depend on the string 'METHOD' and the accompanying VALUE.
%   Choices for METHOD and VALUE are:
%
%   Indices - vector of indices marks individual points as outliers
%   Domain  - [XMIN XMAX] marks the points outside the domain as outliers
%   Range   - [YMIN YMAX] marks the points outside the range as outliers
%   Box     - [XMIN XMAX YMIN YMAX] marks points outside the box as outliers
%
%   To combine these, use the | (or) operator.  
%
%   Example:
%      outliers = excludedata(xdata, ydata, 'indices', [3 5]);
%      outliers = outliers | excludedata(xdata, ydata, 'domain', [2 6]);
%      fit1 = fit(xdata,ydata,fittype,'Exclude',outliers);
%
%   In some cases, you may want to specify a box that contains all the data to
%   keep (not exclude). To do this with EXCLUDEDATA,  use NOT (~).
%
%      outliers = ~excludedata(xdata,ydata,'box',[2 6 2 6])
%
%   See also FIT, PREPARESURFACEDATA.

%   Copyright 1999-2010 The MathWorks, Inc.
%     $Date: 1999/09/24 21:02:37 

if ~isequal(size(x),size(y))
   error(message('curvefit:excludedata:xyDifferentSizes'));
end

s=size(x);
if min(s)~=1
   error(message('curvefit:excludedata:xyNotVectors'));
end

% do automatic completion on the method
method=lower(method);
allfields={'indices';'domain';'range';'box'};
matches=strmatch(method,allfields);
switch size(matches,1)
case 0
   error(message('curvefit:excludedata:invalidMethod', method));
case 1 % A unique match
   method=allfields{matches};
   
   % HERE'S THE BEEF  
   switch method
   case 'indices'
      outliers=false(size(x));
      outliers(opt)=1;
   case 'domain'
      outliers=x<opt(1) | x>opt(2);
   case 'range'
      outliers=y<opt(1) | y>opt(2);
   case 'box'
      outliers=x<opt(1) | x>opt(2) | y<opt(3) | y>opt(4);
   end   
end

