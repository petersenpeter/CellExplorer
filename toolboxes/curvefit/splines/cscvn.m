function cs = cscvn(points)
%CSCVN `Natural' or periodic interpolating cubic spline curve.
%
%   CS  = CSCVN(POINTS)
%
%   returns a parametric `natural' cubic spline that interpolates to
%   the given points POINTS(:,i)  at parameter values  t(i) ,
%   i=1,2,..., with  t(i)  chosen by Eugene Lee's centripetal scheme,
%   i.e., as accumulated square root of chord-length.
%
%   When first and last point coincide and there are no double points,
%   then a parametric *periodic* cubic spline is constructed instead. 
%   However, double points result in corners.
%
%   For example,
%
%      fnplt(cscvn( [1 0 -1    0 1;0 1 0   -1 0] ))
%
%   shows a (circular) curve through the four vertices of the standard diamond
%   (because of the periodic boundary conditions enforced), while
%
%      fnplt(cscvn( [1 0 -1 -1 0 1;0 1 0 0 -1 0] ))
%
%   shows a corner at the double point as well as at the curve endpoint.
%
%   See also CSAPI, CSAPE, GETCURVE, SPCRVDEM, SPLINE.

%   Carl de Boor 28 jan 90
%   cb : May 12, 1991 change from csapn to csape
%   cb : 9 may '95 csape can now handle vector-valued data
%   cb : 9 may '95 (use .' instead of ')
%   cb : 7 mar '96 (reduce to one statement)
%   cb :23 may '96 (use periodic spline for a closed curve)
%   cb :23 mar '97 (make double points corners; permit input of just one point)
%   Copyright 1987-2008 The MathWorks, Inc.

if points(:,1)==points(:,end)  endconds = 'periodic';
else                           endconds = 'variational';
end

if length(points(1,:))==1 dt = 0;
else dt = sum((diff(points.').^2).'); end
t = cumsum([0,dt.^(1/4)]);

if all(dt>0) cs = csape(t,points,endconds);
else
   dtp = find(dt>0);
   if isempty(dtp)                % there is only one distinct point
      cs = csape([0 1],points(:,[1 1]),endconds);
   elseif length(dtp)==1         % there are only two distinct points
      cs = csape([0 t(dtp+1)],points(:,dtp+[0 1]),endconds);
   else
      dtpbig = find(diff(dtp)>1);
      if isempty(dtpbig)          % there is only one piece
        temp = dtp(1):(dtp(end)+1); cs = csape(t(temp),points(:,temp),endconds);
      else                        % there are several pieces
         dtpbig = [dtpbig,length(dtp)];
         temp = dtp(1):(dtp(dtpbig(1))+1);
         coefs = ppbrk(csape(t(temp),points(:,temp),'variatonal'),'c');
         for j=2:length(dtpbig)
           temp = dtp(dtpbig(j-1)+1):(dtp(dtpbig(j))+1);
           coefs=[coefs;ppbrk(csape(t(temp),points(:,temp),'variational'),'c')];
         end
         cs = ppmak(t([dtp(1) dtp+1]),coefs,length(points(:,1)));
      end
   end
end
