% Setting time axis
x = 0.1:0.1:100;

% Setting fitting parameters
a = 25;  % tau decay
b = 2;   % tau rise
c = 20;  % amplitude decay  
d = 5;   % amplitude rise
e = 3;   % symtotic rate value
f = 5;   % refractory period
g = 2;   % tau decay burst/doublets
h = 5;   % contant burst/doublet amplitude

fit = max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+e+h*exp(-(x-f)/g),0);

figure, plot(x,fit,'b')