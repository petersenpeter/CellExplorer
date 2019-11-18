function [xds,yds] = datastats(xdata, ydata)
%DATASTATS Data statistics.
%   DS = DATASTATS(XDATA) returns data statistics for XDATA in the
%   structure DS. XDATA should be a real column vector and the
%   imaginary part of complex XDATA is ignored.
%
%   The returned structure DS contains the following fields:
%
%      ds.num       --- number of points in the data
%      ds.max       --- maximum of the data
%      ds.min       --- minimum of the data
%      ds.mean      --- mean of the data
%      ds.median    --- median of the data
%      ds.range     --- difference between max and min
%      ds.std       --- standard deviation of the data
%    
%   [XDS,YDS] = DATASTATS(XDATA,YDATA) returns data statistics for
%   XDATA and YDATA in the structures XDS and YDS.  XDATA and YDATA
%   should be real column vectors and the imaginary parts of complex
%   inputs are ignored.  XDS and YDS are structures as in the above
%   case.

%   Copyright 1999-2004 The MathWorks, Inc.

if nargin < 1
  error(message('curvefit:datastats:noInput'));
end

if size(xdata,2) ~= 1
  error(message('curvefit:datastats:xDataMustBeColVector'));
end

cplxflag = 0;
if ~isreal(xdata)
    cplxflag = 1;
    xdata = real(xdata);
end

if nargin >= 2 
  if size(ydata,2) ~= 1 
  error(message('curvefit:datastats:yDataMustBeColVector'));
  end
  if ~isreal(ydata)
      cplxflag = 1;
      ydata = real(ydata);
  end
end

if cplxflag
    warning(message('curvefit:datastats:usingRealComp'));
end

xds.num = length(xdata);
xds.max = max(xdata);
xds.min = min(xdata);
xds.mean = mean(xdata);
xds.median = median(xdata);
xds.range = xds.max-xds.min;
xds.std = std(xdata);

if nargout == 2 && nargin == 2
  yds.num = length(ydata);
  yds.max = max(ydata);
  yds.min = min(ydata);
  yds.mean = mean(ydata);
  yds.median = median(ydata);
  yds.range = yds.max-yds.min;
  yds.std = std(ydata);
end
