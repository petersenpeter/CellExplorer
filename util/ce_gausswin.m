function w = ce_gausswin(N)
% By Peter Petersen
% petersen.peter@gmail.com

alpha = 2.5;
L = N(1)-1; 
n = (0:L)'-L/2;
w = exp(-(1/2)*(alpha*n/(L/2)).^2);
