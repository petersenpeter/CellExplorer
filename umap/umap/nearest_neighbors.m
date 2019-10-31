function [knn_indices, knn_dists] = nearest_neighbors(X, n_neighbors, metric, varargin)
%NEAREST_NEIGHBORS Compute the "n_neighbors" nearest points for each data
% point in "X" under "metric". Currently, in most cases, this simply
% involves calling the MATLAB function knnsearch.m on the data.
%
% [knn_indices, knn_dists] = NEAREST_NEIGHBORS(X, n_neighbors, metric)
%
% Parameters
% ----------
% X: array of size (n_samples, n_features)
%     The input data of which to compute the k-neighbor graph.
% 
% n_neighbors: double
%     The number of nearest neighbors to compute for each sample in "X".
% 
% metric: string or function
%     The metric to use for the computation.
% 
% metric_kwds: cell array (optional)
%     Any arguments to pass to the metric computation function.
% 
% random_state: boolean (optional, default true)
%     If true, MATLAB's RNG will be set to default for reproducibility.
% 
% verbose: boolean (optional, default false)
%     Whether to print status data during the computation.
% 
% Returns
% -------
% knn_indices: array of size (n_samples, n_neighbors)
%     The indices on the "n_neighbors" closest points in the dataset.
% 
% knn_dists: array of size (n_samples, n_neighbors)
%     The distances to the "n_neighbors" closest points in the dataset.
%
%   AUTHORSHIP
%   Math Lead & Primary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Secondary Developer: Stephen Meehan <swmeehan@stanford.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

    p=parseArguments();
    parse(p,varargin{:});
    args=p.Results; 
    verbose = args.verbose;
    random_state = args.random_state;
    metric_kwds = args.metric_kwds;
    
    if random_state
        rng default;
    end
    
    n_samples = size(X, 1);

    if strcmpi(metric, 'precomputed')
        [knn_dists, knn_indices] = sort(X,2);
        knn_indices = knn_indices(:, 1:n_neighbors);
        knn_dists = knn_dists(:, 1:n_neighbors);

    else
        if isa(metric, 'function_handle')
            distance_func = metric;
        elseif ismember(metric, ['euclidean', 'cityblock', 'seuclidean',...
            'chebychev', 'minkowski', 'mahalanobis', 'cosine',...
            'correlation', 'hamming', 'jaccard'])
            distance_func = metric;
        else
            error('Metric is neither callable, nor a recognised string');
        end
        
        if issparse(X)
            warning('knnsearch.m runs much faster on full matrices. Converting data to full matrix!');
            X = full(X);
        end
        
        [knn_indices, knn_dists] = knnsearch(X,X,'K',n_neighbors,'Distance',distance_func);

        if any(knn_indices < 0)
            warning(['Failed to correctly find n_neighbors for some samples. '...
                'Results may be less than ideal. Try re-running with different parameters.']);
        end
    end
    
    function p=parseArguments(varargin)
        p = inputParser;
        addParameter(p,'verbose', false, @islogical);
        addParameter(p,'random_state',true);
        addParameter(p,'metric_kwds', []);
    end
end