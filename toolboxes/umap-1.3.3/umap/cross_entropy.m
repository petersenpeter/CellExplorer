function result = cross_entropy(dists, weights, min_dist, max)
%CROSS_ENTROPY Given a distance for each 1-simplex in low-dimensional space
% and the original weights of the 1-simplices in high-dimensional space,
% compute the total cross-entropy between the two simplicial complexes
% using the original non-smooth formula.
%
% result = CROSS_ENTROPY(dists, weights, min_dist, max)
%
% Parameters
% ----------
% dists: array of size (n_1_simplices, 1)
%     The current distance between the two endpoints of the 1-simplex in
%     low-dimensional Euclidean space.
%
% weights: array of size (n_1_simplices, 1)
%     The original weights assigned to the 1-simplices in high-dimensional
%     space.
%
% min_dist: double
%     The desired minimum distance parameter in low-dimensional space
%
% max: double (optional, default 10)
%     In practice, many points are within min_dist from each other, which
%     means that -log(1-Psi) is infinity. When adding such summands to the
%     total cross entropy, we add max instead of infinity.
% 
% Returns
% -------
% result: double
%     The total cross entropy between the two simplicial complexes.
%
% See also: APPROX_CROSS_ENTROPY
%
%   AUTHORSHIP
%   Math Lead & Primary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Secondary Developer: Stephen Meehan <swmeehan@stanford.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%
if nargin < 4
    max = 10;
end

Psi = (dists < min_dist) + ~(dists < min_dist).*exp(-(dists - min_dist));
w1 = weights == 1;
w0 = weights == 0;
other = ~w0 & ~w1;
Psi_summands = zeros(size(weights));
Psi_summands(w1) = log(Psi(w1));
Psi_summands(w0) = log(1-Psi(w0));
Psi_summands(other) = weights(other).*log(Psi(other)) + (1-weights(other)).*log(1-Psi(other));

Psi_summands(isinf(Psi_summands)) = -max;
result = -sum(Psi_summands);
end