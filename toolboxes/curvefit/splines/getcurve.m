function [xy, spcv] = getcurve 
%GETCURVE  Interactive creation of a cubic spline curve.
%
%   [xy, spcv] = getcurve;  asks for a point sequence to be specified
%   by mouse clicks on a grid provided.
%   The points picked are available in the array XY.
%   The spline curve is available in SPCV.
%   A closed curve will be drawn if the first and last point are
%   sufficiently close to each other.
%   Repeated points create a corner in the curve.

%   Copyright 1987-2011 The MathWorks, Inc.

w = [-1 1 -1 1];  % start with the unit square
clf, axis(w), hold on, grid on

title(getString(message('SPLINES:resources:plotTitle_UseMouseToPickPoints')))
pts = line('Xdata',NaN,'Ydata',NaN,'marker','o','erase','none');

maxpnts = 100; xy = zeros(2,maxpnts);
while 1
   for j=1:maxpnts
      [x,y] = ginput(1);
      if isempty(x)||x<w(1)||x>w(2)||y<w(3)||y>w(4), break, end
      xy(:,j) = [x;y];
      if j>1
         set(pts,'Xdata',xy(1,1:j),'Ydata',xy(2,1:j))
      else
         set(pts,'Xdata',x,'Ydata',y)
         xlabel(getString(message('SPLINES:resources:axesLabel_WhenYouAreDone')))
      end
   end
   if j>1, break, end
   xlabel(getString(message('SPLINES:resources:axesLabel_ClickInsideOnce')))
end 

title(' ')
xlabel(getString(message('SPLINES:resources:axesLabel_Done')))
xy(:,j:maxpnts)=[];
if norm(xy(:,1)-xy(:,j-1))<.05, xy(:,j-1)=xy(:,1); end
set(pts,'Xdata',xy(1,:),'Ydata',xy(2,:),'erase','xor','linestyle','none')
spcv = cscvn(xy); fnplt(spcv), hold off
