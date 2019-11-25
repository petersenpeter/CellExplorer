function [embedding, method] = choose_optimize_layout(head_embedding,...
    tail_embedding, head, tail, n_epochs, n_vertices,epochs_per_sample,...
    a, b, gamma, initial_alpha, negative_sample_rate, verbose, method,...
    progress_callback, epoch_reports, random_state, min_dist)
%CHOOSE_OPTIMIZE_LAYOUT Given all the data necessary to perform stochastic
% gradient descent, use the "method" variable to decide whether to use
% Java, C, or MATLAB to perform SGD.
%
% See also: OPTIMIZE_LAYOUT

%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu>
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
TEST_CROSS_ENTROPY=false;
if nargin < 16
    epoch_reports = 0;
    if nargin<15
        progress_callback=[];
        if nargin < 14
            method = 'Java';
            if nargin < 13
                verbose = false;
            end
        end
    end
end
if strcmpi(method, 'C')
    if ~exist('optimize_layout_mex.mexw64', 'file')
        if initJava
            method='Java';
            yelp;
        end
    end
end
if strcmpi(method, 'C vectorized')
    if ~exist('optimize_layout2_mex.mexw64', 'file')
        if initJava
            method='Java';
            yelp;
        end
    end
end

if strcmpi(method, 'Java')
    initJava;
    try
        N=size(epochs_per_sample, 1);
        if TEST_CROSS_ENTROPY
            weights = ones(N,1)./epochs_per_sample; %We probably should have passed in weights to this instead...
        end 
        javaObject=edu.stanford.facs.swing.StochasticGradientDescent(...
            head_embedding, tail_embedding,head, tail, n_epochs, ...
            n_vertices, epochs_per_sample, a, b, gamma, ...
            initial_alpha, negative_sample_rate);
        javaObject.move_other=isequal(head_embedding, tail_embedding);
        if islogical(random_state)
            if ~random_state
                javaObject.randomize;
            end
        end
        if epoch_reports>0
            javaObject.setReports(epoch_reports);
        end
        if ~reportJavaProgress
            embedding=[];
            return;
        end
        while ~javaObject.nextEpochs
            if ~reportJavaProgress
                embedding=[];
                return;
            end
        end
        reportJavaProgress;
        embedding=javaObject.getEmbedding;
        return;
    catch ex
        ex.getReport
        warning(' JAVA jar not installed? .. using C');
        method='C';
    end
end
if strcmpi(method, 'C')
    try
        embedding = optimize_layout_mex(single(head_embedding), ...
            single(tail_embedding), int32(head), int32(tail), ...
            int32(n_epochs), int32(n_vertices), ...
            single(epochs_per_sample), single(a), single(b), ...
            single(gamma), single(initial_alpha), ...
            int32(negative_sample_rate), verbose);
    catch ex
        ex.getReport
        yelp;
    end
elseif strcmpi(method, 'MatLab')
    embedding = optimize_layout(single(head_embedding), ...
        single(tail_embedding), int32(head), int32(tail), ...
        int32(n_epochs), int32(n_vertices), ...
        single(epochs_per_sample), single(a), single(b), ...
        single(gamma), single(initial_alpha), ...
        int32(negative_sample_rate), verbose);
elseif strcmpi(method, 'C vectorized')
    embedding = optimize_layout2_mex(single(head_embedding), ...
        single(tail_embedding), int32(head), int32(tail), ...
        int32(n_epochs), int32(n_vertices), ...
        single(epochs_per_sample), single(a), single(b), ...
        single(gamma), single(initial_alpha), ...
        int32(negative_sample_rate), verbose);
elseif strcmpi(method, 'MatLab experimental')
    embedding = optimize_layout4(single(head_embedding), ...
        single(tail_embedding), int32(head), int32(tail), ...
        int32(n_epochs), int32(n_vertices), ...
        single(epochs_per_sample), single(a), single(b), ...
        single(gamma), single(initial_alpha), ...
        int32(negative_sample_rate), verbose);
elseif strcmpi(method, 'MatLab experimental 2')
    embedding = optimize_layout5(single(head_embedding), ...
        single(tail_embedding), int32(head), int32(tail), ...
        int32(n_epochs), int32(n_vertices), ...
        single(epochs_per_sample), single(a), single(b), ...
        single(gamma), single(initial_alpha), ...
        int32(negative_sample_rate), verbose);
else %method is MatLab vectorized
    embedding = optimize_layout2(single(head_embedding), ...
        single(tail_embedding), int32(head), int32(tail), ...
        int32(n_epochs), int32(n_vertices), ...
        single(epochs_per_sample), single(a), single(b), ...
        single(gamma), single(initial_alpha), ...
        int32(negative_sample_rate), verbose);
end
    function yelp
                showMsg(Html.WrapHr([...
            'Using java for stochastic gradient descent.<br>' ...
            'MathWorks File Exchange does not support mex files.<br>'...
            '<br>Download full version with mex files at <br>'...
            '(<b>http://cgworkspace.cytogenie.org/GetDown2/demo/umapDistribution.zip</b>)']), ...
            'MathWorks File Exchange restriction', 'north east+', false, false, 22);
    end

    function wantsToContinue=reportJavaProgress        
        if isequal('function_handle', class(progress_callback))
            wantsToContinue=feval(progress_callback, javaObject);
        else
            wantsToContinue=true;
            if verbose
                done=javaObject.getEpochsDone-1;
                toDo=javaObject.getEpochsToDo;
                fprintf('%d/%d epochs done\n', done, toDo);
            end
        end
        if TEST_CROSS_ENTROPY
            dists = sqrt(sum((javaObject.head_embedding(head,:) - ...
                javaObject.tail_embedding(tail,:)).^2, 2));
            CE = cross_entropy(dists, weights, min_dist);
            fprintf('Current cross entropy is %s (min_dist=%s)\n', ...
                String.encodeRounded(CE,1), String.encodeRounded(min_dist,3));
            if size(javaObject.head_embedding, 1)*size(javaObject.tail_embedding) < 1e7
                FACE = full_approx_cross_entropy(javaObject.head_embedding, javaObject.tail_embedding, head, tail, weights, a, b, javaObject.move_other);
                fprintf('The approximate cross entropy (FULL) is %s\n', ...
                    String.encodeRounded(FACE,1));
            end
            %approx_CE = approx_cross_entropy(dists, weights, a, b);
            %disp(['The current approximated cross entropy is ' num2str(approx_CE)]);
        end
    end
end

