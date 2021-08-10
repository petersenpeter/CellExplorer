function [Pxx, f, C] = lpsd(x, windowfcn, fmin, fmax, Jdes, Kdes, Kmin, fs, xi)
%LPSD Power spectrum estimation with a logarithmic frequency axis
%   [Pxx, f, C] = LPSD(x, windowfcn, fmin, fmax, Jdes, Kdes, Kmin, fs, xi)
%   estimates the power spectrum or power spectral density of the time
%   series x at JDES frequencies equally spaced (on a logarithmic scale)
%   from FMIN to FMAX. 
%
%   The parameters are:
%
%     x:          time series to be transformed
%     windowfcn:  function handle to windowing function (i.e. @hanning)
%     fmin:       lowest frequency to estimate
%     fmax:       highest frequency to estimate
%     Jdes:       desired number of Fourier frequencies
%     Kdes:       desired number of averages
%     Kmin:       minimum number of averages
%     fs:         sampling rate
%     xi:         fractional overlap between segments (0 <= xi < 1)
%
%   The outputs are:
%
%     Pxx:        vector of (uncalibrated) power spectrum estimates
%     f:          vector of frequencies corresponding to Pxx
%     C:          structure containing calibration factors to calibrate Pxx
%                 into either power spectral density or power spectrum.
%
%   The implementation follows references [1] and [2] quite closely; in
%   particular, the variable names used in the program generally correspond
%   to the variables in the paper; and the corresponding equation numbers
%   are indicated in the comments.
%
%   References:
%     [1] Michael Tröbs and Gerhard Heinzel, "Improved spectrum estimation
%     from digitized time series on a logarithmic frequency axis," in
%     Measurement, vol 39 (2006), pp 120-129.
%       * http://dx.doi.org/10.1016/j.measurement.2005.10.010
%       * http://pubman.mpdl.mpg.de/pubman/item/escidoc:150688:1
%
%     [2] Michael Tröbs and Gerhard Heinzel, Corrigendum to "Improved 
%     spectrum estimation from digitized time series on a logarithmic 
%     frequency axis."
% 
%   Author(s): Tobin Fricke <tobin.fricke@ligo.org> 2012-04-17

% Sanity check the input arguments
assert(isa(windowfcn, 'function_handle'));
assert(fmax > fmin);
assert(Jdes > 0);
assert(Kdes > 0);
assert(Kmin > 0);
assert(Kdes >= Kmin);
assert(fs > 0);
assert(xi >= 0 & xi < 1);

N = length(x);                                                   % Table 1
jj = 0:Jdes-1;                                                   % Table 1

assert(fmin >= fs/N);  % Lowest frequency possible
assert(fmax <= fs/2);  % Nyquist rate

g = log(fmax) - log(fmin);                                          % (12)
f =  fmin * exp(jj * g / (Jdes - 1));                               % (13)
rp = fmin * exp(jj * g / (Jdes - 1)) * (exp(g / (Jdes - 1)) - 1);   % (15)

% r' now contains the 'desired resolutions' for each frequency bin, given
% the rule that we want the resolution to be equal to the difference in
% frequency between adjacent bins.   Below we adjust this to account for
% the minimum and desired number of averages.

ravg = (fs/N) * (1 + (1 - xi) * (Kdes - 1));                        % (16)
rmin = (fs/N) * (1 + (1 - xi) * (Kmin - 1));                        % (17)

case1 = rp >= ravg;                                                 % (18)
case2 = (rp < ravg) & (sqrt(ravg * rp) > rmin);                     % (18)
case3 = ~(case1 | case2);                                           % (18)

rpp = zeros(1, Jdes);

rpp( case1 ) = rp(case1);                                           % (18)
rpp( case2 ) = sqrt(ravg * rp(case2));                              % (18)
rpp( case3 ) = rmin;                                                % (18)

% r'' contains adjusted frequency resolutions, accounting for the finite
% length of the data, the constraint of the minimum number of averages, and
% the desired number of averages.  We now round r'' to the nearest bin of
% the DFT to get our final resolutions r.

L = round(fs ./ rpp);       % segment lengths                       % (19)
r = fs ./ L;                % actual resolution                     % (20)
m = f ./ r;                 % Fourier Tranform bin number           % (7) 

% Allocate space for some results

Pxx = NaN(1, Jdes);
S1  = NaN(1, Jdes);
S2  = NaN(1, Jdes);  

% Loop over frequencies.  For each frequency, we basically conduct Welch's
% method with the fourier transform length chosen differently for each
% frequency.

for jj=1:length(f)
  % Calculate the number of segments
  D = round( (1 - xi) * L(jj) );                                    % (2)
  K = floor( (N - L(jj)) / D + 1);                                  % (3)
       
  % reshape the time series so each column is one segment
  ii = bsxfun(@plus, (1:L(jj))', D*(0:K-1));  % selector matrix     % (5)
  data = x(ii);
  
  % Remove the mean of each segment.
  data = bsxfun(@minus, data, mean(data));                          % (4)
  
  % Compute the discrete Fourier transform
  window = windowfcn(L(jj));                                        % (5)
  sinusoid = exp(-2i*pi * (0:L(jj)-1)' * m(jj)/L(jj));              % (6)  
  data = bsxfun(@times, data, sinusoid .* window);                  % (5,6)
  
  % Average the squared magnitudes
  Pxx(jj) = mean(abs(sum(data)).^2);                                % (8)
  
  % Calculate some properties of the window function which will be used
  % during calibration  
  S1(jj) = sum(window);                                             % (23)
  S2(jj) = sum(window.^2);                                          % (24)
end

% Calculate the calibration factors

C.PS = 2 * S1.^(-2);                                                % (28)
C.PSD = 2 ./ (fs * S2);                                             % (29)

end

