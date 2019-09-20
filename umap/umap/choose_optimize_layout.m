function [embedding, method] = choose_optimize_layout(head_embedding,...
    tail_embedding, head, tail, n_epochs, n_vertices,epochs_per_sample,...
    a, b, gamma, initial_alpha, negative_sample_rate, verbose, method,...
    progress_callback, epoch_reports, random_state)
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
        if isequal('function_handle', class(progress_callback))
            javaObject=edu.stanford.facs.swing.Umap(head_embedding,...
                tail_embedding,head, tail, n_epochs,n_vertices, ...
                epochs_per_sample, a, b, gamma, initial_alpha, ...
                negative_sample_rate);
            if islogical(random_state)
                if ~random_state
                    javaObject.randomize;
                end
            end
            wantsToContinue=feval(progress_callback, javaObject);
            if epoch_reports>0
                javaObject.setReports(epoch_reports);
            end
            if ~wantsToContinue
                embedding=[];
                return;
            end
            while ~javaObject.nextEpochs()
                wantsToContinue=feval(progress_callback, javaObject);
                if ~wantsToContinue
                    embedding=[];
                    return;
                end
            end
            feval(progress_callback, javaObject);
            embedding=javaObject.getEmbedding;
        else
            if ~isempty(progress_callback)
                % is likely a progress bar
                verbose2=progress_callback;
            else
                verbose2=verbose;
            end
            embedding = edu.stanford.facs.swing.Umap.optimize_layout(...
                head_embedding, tail_embedding,head, tail, n_epochs,...
                n_vertices, epochs_per_sample, a, b, gamma, ...
                initial_alpha, negative_sample_rate, verbose2, []);
        end
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
end

