function [x,y] = titanium
%TITANIUM Test data.
%
%   [X,Y] = TITANIUM
%
%   returns the data points of the Titanium Heat data which give a
%   certain property of titanium as a function of temperature and
%   which have been used extensively as test data for fitting by
%   splines with variable knots.

%   Carl de Boor 1987
%   Copyright 1987-2008 The MathWorks, Inc. 

x=585+[1:49]*10;
y=[.644  .622  .638  .649  .652  .639  .646  .657  .652  .655  ...
   .644  .663  .663  .668  .676  .676  .686  .679  .678  .683  ...
   .694  .699  .710  .730  .763  .812  .907 1.044 1.336 1.881];
y=[ y ...
  2.169 2.075 1.598 1.211  .916  .746  .672  .627  .615  .607  ...
   .606  .609  .603  .601  .603  .601  .611  .601  .608];
