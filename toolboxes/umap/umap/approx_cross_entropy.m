function result = approx_cross_entropy(dists, weights, a, b)
%APPROX_CROSS_ENTROPY Given a distance for each 1-simplex in low-dimensional space
% and the original weights of the 1-simplices in high-dimensional space,
% compute the approximation to the cross-entropy between the two simplicial
% complexes. This calculation uses the modified smooth formula Phi for
% low-dimensional weight that is used in the stochastic gradient descent.
%
% result = APPROX_CROSS_ENTROPY(dists, weights, a, b)
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
% a: double
%     Parameter of differentiable approximation of right adjoint functor.
% 
% b: double
%     Parameter of differentiable approximation of right adjoint functor.
% 
% Returns
% -------
% result: double
%     The total approximated cross entropy between the two simplicial complexes.
%
% See also: CROSS_ENTROPY
%
%   AUTHORSHIP
%   Math Lead & Primary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Secondary Developer: Stephen Meehan <swmeehan@stanford.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%
max = 10;

Phi = ones(size(dists,1),1)./(1 + a*(dists.^(2*b)));
w1 = weights == 1;
w0 = weights == 0;
other = ~w0 & ~w1;
Phi_summands = zeros(size(weights));
Phi_summands(w1) = log(Phi(w1));
Phi_summands(w0) = log(1-Phi(w0));
Phi_summands(other) = weights(other).*log(Phi(other)) + (1-weights(other)).*log(1-Phi(other));

Phi_summands(isinf(Phi_summands)) = -max;
result = -sum(Phi_summands);
end