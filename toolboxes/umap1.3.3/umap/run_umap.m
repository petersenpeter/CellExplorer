function [reduction, umap, clusterIdentifiers]=run_umap(varargin)
%%RUN_UMAP reduces data matrices with 3+ parameters down to fewer 
%   parameters using the algorithm UMAP (Uniform 
%   Manifold Projection and Approximation).  
%
%   [reduction,umap] = RUN_UMAP(csv_file_or_data,'NAME1',VALUE1,..., 
%   'NAMEN',VALUEN) 
%   
%
%   RETURN VALUES
%   Invoking run_umap produces 2 return values:
%   1) reduction, the actual data that UMAP reduces from the data 
%     specified by the input argument csv_file_or_data; 
%   2) umap, an instance of the UMAP class made ready for the invoker 
%     to save in a MATLAB file for further use as a template.
%
%
%   REQUIRED INPUT ARGUMENT
%   The argument csv_file_or_data is either 
%   A) a char array identifying a csv text file containing the data 
%       to be reduced. 
%   B) the actual data to be reduced; a numeric matrix.
%
%   If A) then the csv file needs the first line to be parameter names.
%
%   If run_umap is invoked with no arguments it then offers to 
%   download example csv files and run one of them.  The programming
%   examples in this documentation's use of those files.
%
%
%   OPTIONAL INPUT ARGUMENTS
%   Some of these are identical to those in the original
%   Python implementation documented by the inventors in their document
%   "Basic UMAP parameters" which can be retrieved at 
%   https://umap-learn.readthedocs.io/en/latest/parameters.html.
%   The optional argument name/value pairs are:
%
%   Name                    Value
%
%   'n_neighbors'           Controls local and global structure as 
%                           does the same parameter in the original 
%                           implementation. 
%                           Default is 30. 
%   
%   'min_dist'              Controls how tightly UMAP is allowed to 
%                           pack points together as does the same 
%                           parameter in the original implementation.
%                           Default is 0.3.
%
%   'metric'                Controls how distance is computed in the
%                           ambient space as does the same 
%                           parameter in the original implementation.
%                           Accepted values for metric include
%                           'euclidean', 'cosine', 'cityblock', 'seuclidean', 
%                           'squaredeuclidean', 'correlation', 'jaccard',
%                           'spearman', 'hamming'.
%                           These metrics are described in MATLAB's
%                           documentation for knnsearch.
%                           Default is 'euclidean'.
%
%   'randomize'             true/false.  If false run_umap invokes
%                           MATLAB's "rng default" command to ensure the
%                           same random sequence of numbers between invocations.
%                           Default is true.
%
%   'template_file'         This identifies a mat file with a saved 
%                           instance of the UMAP class that run_umap previously 
%                           produced. The instance must be be a suitable 
%                           "training set" for the current "test set" of
%                           data supplied by the argument csv_file_or_data.
%                           Template processing accelerates the 
%                           UMAP reduction and augments reproducibility.
%                           run_umap prechecks the suitability of
%                           the template's training set for the test set by
%                           checking the parameter names and the standard
%                           deviation distance of the means for each
%                           parameter.
%                           Default is empty ([]...no template).
%
%   'parameter_names'       Cell of char arrays to annotate each parameter in the
%                           data specified by csv_file_or_data.
%                           This is only needed if a template is being used or saved.
%                           
%   'verbose'               Accepted values are 'graphic', 'text' or 'none'
%                           If verbose=graphic then the data displays
%                           with probability coloring and contours as is
%                           conventional in flow cytometry analysis.
%                           If method=Java then the display refreshes
%                           as optimize_layout progresses and a progress 
%                           bar is shown along with a handy cancel
%                           button.
%                           If verbose=text the progress is displayed in
%                           the MATLAB console as textual statements.
%                           Default is 'graphic'.
%                           
%   'method'                Picks 1 of 5 implementations of UMAP's time 
%                           consuming optimize_layout phase.  Accepted values 
%                           are 'Java', 'C', 'C vectorized', 'MATLAB' or 
%                           'MATLAB Vectorized'. Only Java, currently the fastest 
%                           method, allows incremental progress reporting and
%                           cancellation.  The other methods are legacy
%                           artifacts of the programming journey we took
%                           to find the fastest treatment for
%                           optimize_layout that was rapidly developable
%                           within the MATLAB environment.  A faster
%                           implementation can be had by developing a custom C
%                           module for optimize_layout.  The current C programming
%                           method was generated by the MATLAB C coder.
%                           Default is 'Java'.
%
%  'progress_callback'      A MATLAB function handle that run_umap
%                           invokes when method=Java and verbose=graphic. 
%                           The input/output contract for this function is
%                           keepComputing=progress_report(javaObjectOrString).
%                           The javaObjectOrString argument is a char array
%                           before optimize_layout phase starts and then
%                           when optimize_layout is running it is an
%                           instance of the java class 
%                           StochasticGradientDescent.java.
%                           This instance's public methods getEpochsToDo,
%                           getEpochsDone and getEmbedding can be used
%                           to convey the state of progress as illustrated 
%                           in the source code of run_umap
%                           for the function progress_report.
%                           If the function returns keepComputing=false 
%                           then run_umap halts the processing.
%                           Default is the function progress_report
%                           in run_umap.m.
%
%   'ask_to_save_template'  true/false instructs run_umap to ask/not ask
%                           to save a template PROVIDING method='Java'
%                           verbose='graphic' and template_file is empty.
%                           Default is false.
%
%   'label_column'         number identifying column in the input data
%                           matrix which contains numeric identifiers to
%                           label the data for UMAP supervision mode.                    
%                           0 which indicates no label column.
%   `                       Default is 0.
%
%   'label_file'       the name of a properties file that contains 
%                           the label names.  The property name/value 
%                           format is identifier=false.
%
%   'n_components'          The dimension of the space to embed into.
%                           This defaults to 2 to provide easy 
%                           visualization, but can reasonably be set to 
%                           any integer value in the range 2 to 100.
%   'epsilon'              The epsilon parameter required by dbscan
%                           if output argument includes clusters and
%                           n_components > 2
%

%
%   EXAMPLES 
%   Note these examples assume your current MATLAB folder is where run_umap.m
%   is stored.
%
%   1. Download the example csv files and run sample10k.csv
%
%       run_umap
%
%   2. Reduce parameters for sample30k.csv and save as template
%
%       [~, umap]=run_umap('sample30k.csv');
%       save('myTemplate30k.umap.mat', 'umap');
%
%   3. Reduce parameters for sample130k.csv using prior template
%
%       run_umap('sample130k.csv', 'template_file', 'myTemplate30k.umap.mat');
%
%   4. Reduce parameters for sampleBalbcLabeled55k.csv supervised
%       by labels produced by Epp and save as a template.
%       Epp is a more conservative clustering technique described at
%       https://www.nature.com/articles/s42003-019-0467-6.
%       Epp stands for "Exhaustive Projection Pursuit".  By clustering
%       exhaustively in 2 dimension pairs, this technique
%       steers more carefully away from the curse of dimensionality than
%       does UMAP or t-SNE
%
%       To use Epp you can download AutoGate from cytogenie.org
%       which contains tutorials on using Epp.
%
%       [~, umap]=run_umap('sampleBalbcLabeled55k.csv', 'label_column', 11, 'label_file', 'balbcLabels.properties');
%       save('myTemplateBalbcEpp55k.umap.mat', 'umap');
%
%   5. Reduce parameters for sampleRag148k.csv using template that is
%       supervised by Epp.  This takes the clusters created by 
%       Epp on the lymphocytes of a normal mouse strain (BALB/c)
%   `   and applies them via a template to a mouse strain (RAG) 
%       that has neither T cells nor B cells
%
%       run_umap('sampleRag148k.csv', 'template_file', 'myTemplateBalbcEpp55k.umap.mat');
%
%   6. Reduce parameters for sample30k.csv and return cluster identifiers
%       using density-based merging described at 
%       http://cgworkspace.cytogenie.org/GetDown2/demo/dbm.pdf
%
%       [~,~, clusterIds]=run_umap('sample30k.csv');
%
%   7. Repeat sample 2 but for 3D output and return cluster identifiers
%       and save the result as 3D tempplate
%
%       [~, umap, clusterIds]=run_umap('sample30k.csv', 'n_components', 3);
%       save('myTemplate30k3D.umap.mat', 'umap');
%
%   8.  Repeat example 3 in 3D
%
%       run_umap('sample130k.csv', 'template_file', 'myTemplate30k3D.umap.mat', 'n_components', 3);
%
%   9.  Reduce parameters and save template for sampleRagLabeled60k.csv
%       using labels produced by an expert biologist drawing manual gate 
%       sequences on lymphocyte data taken from a RAG mouse strain which 
%       has no T cells or B cells.
%
%       [~, umap]=run_umap('sampleRagLabeled60k.csv', 'label_column', 11, 'label_file', 'ragLabels.properties');
%       save('myTemplateRag60k.umap.mat', 'umap');
%
%   10. Reduce parameters for lymphocyte data taken from a BALB/c mouse strain using 
%       template created in example 9.  This takes the clusters created 
%       on the lymphocyte data of a knockout mouse strain (RAG) with no
%       B cells or T cells and applies them to a normal mouse strain (BALB/c) 
%       which has both cell types.  This illustrates logic to prevent
%       false positives for data not seen when training/creating
%       supervised templates.  Choose to re-supervise to see effect.
%
%       run_umap('sample30k.csv', 'template_file', 'myTemplateRag60k.umap.mat');
%
%   NOTE that you can do supervised UMAP and templates with n_components
%       ...but we have not had time to update the 3D GUI to show where the 
%       supervised regions fall
%
%
%   REQUIRED PATHS
%   This distribution has 2 folders:  umap and util.  
%   You must set paths to these folders plus the java inside of umap.jar
%   Assume you have put these 2 folders under /Users/Stephen.
%   The commands that MATLAB requires would be:
%
%   addpath /Users/Stephen/umap
%   addpath /Users/Stephen/util
%   javaaddpath('/Users/Stephen/umap/umap.jar');
%
%
%   ALGORITHMS
%   UMAP is the invention of Leland McInnes, John Healy and 
%   James Melville at Canada's Tutte Institute for Mathematics and 
%   Computing.  See https://umap-learn.readthedocs.io/en/latest/
%
%   AUTHORSHIP
%   Primary Developer of this file run_umap.m: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

clusterIdentifiers=[];
initJava;
addpath('../util');
reduction=[];
umap=[];
p=parseArguments();
parse(p,varargin{:});
args=p.Results;   
plotting=strcmpi(args.verbose, 'graphic');
csv_file_or_data=args.csv_file_or_data;
if plotting
    xLabel=[];
    yLabel=[];
    zLabel=[];
    fig=figure('name', 'Running UMAP ...');
    curAxes=gca;
    if isempty(csv_file_or_data)
        if isequal('Yes', questdlg({...
                'Should run_umap.m download example csv files',...
                'from the Herzenberg Lab @ Stanford University', ...
                '', '.. and then run one of them?'}))
            csv_file_or_data=downloadCsv;
        end
        if isempty(csv_file_or_data)
            if plotting
                delete(fig);
            end
            return;
        end
        if ~isequal('Yes', questdlg({...
                'Test csv files have been downloaded:'...
                '    sample10k, sample30k, sampleBalbcLabeled55k,'...
                '    sample130k, sampleRag148k.csv and sampleRag55k.csv !','', ...
                'Run sample10k now?'}))
            if plotting
                delete(fig);
            end
            return;
        end
    end
end
if nargout>=3 && args.n_components>2
    % check for presence of DBSCAN
    if ~Density.HasDbScan(false)
        if plotting
            if ~askYesOrNo(Html.WrapHr(['DBSCAN for clustering in 3+D is '...
                    '<br>not downloaded ...Continue?']))
                delete(fig);
                return;
            end
        end
        dispNoDbScan;
    end
end
if ischar(csv_file_or_data)
    if ~exist(csv_file_or_data, 'file')
        showMsg(Html.WrapHr(['The text file "<b>' csv_file_or_data ...
            '</b>"<br><font color="red"><i>can not be found !!</i></font>']));
        if plotting
            delete(fig);
        end
        return;
    end
    
    t=readtable(csv_file_or_data, 'ReadVariableNames', true);
    inData=table2array(t);
    parameter_names=File.CsvNames(t);
else
    inData=csv_file_or_data;
    parameter_names=args.parameter_names;
end
newSubsetIdxs=[];
template_file=args.template_file;
if ~isempty(template_file)
    if ~exist(template_file, 'file')
        showMsg(Html.WrapHr(['The template file "<b>' template_file ...
            '</b>"<br><font color="red"><i>can not be found !!</i></font>']));
        if plotting
            delete(fig);
        end
        return;
    end
    if length(parameter_names)~=size(inData, 2)
        showMsg(Html.WrapHr(sprintf(['<b>Can not create '...
            'template</b> ...<br>'...
            '%d parameter_names... but data has %d parameters?'], ...
            length(parameter_names), size(inData,2))));
        if plotting
            delete(fig)
        end
        return;
    end
    [umap, ~, canLoad, reOrgData]=Template.Get(inData, parameter_names, ...
        template_file, 3);
    if ~isempty(reOrgData)
        % column label order differed
        inData=reOrgData;
    end
    if isempty(umap)
        if ~canLoad
        if plotting 
            showMsg(Html.WrapHr(['No template data found in <br>"<b>', ...
                template_file '</b>"']));
        else
            disp(['No template data found in ' template_file]);
        end
        end
        if plotting
            delete(fig);
        end
        return;
    elseif ~isempty(umap.supervisors)
        [percNewSubsets, unknownIdxs]=...
            Template.CheckForUntrainedFalsePositives(umap, inData);
        if percNewSubsets>10
            [choice, cancelled]=Template.Ask(percNewSubsets);
            if cancelled
                if plotting
                    delete(fig);
                end
                return;
            end
            if choice==2
                umap.clearLimits;
                newSubsetIdxs=unknownIdxs;
                template_file=[];
            end
        end
    end
else
    umap = UMAP;
    umap.dimNames=parameter_names;
end
umap.metric=args.metric;
umap.n_epochs=args.n_epochs;
umap.n_neighbors=args.n_neighbors;
umap.min_dist=args.min_dist;
umap.n_components=args.n_components;
if strcmpi('Java', args.method)
    if ~initJava
        args.method='C';
        showMsg(Html.WrapHr('Could not load umap.jar for Java method'), ...
            'Problem with JAVA...', 'south west', false, false);
    end
end
        
method=umap.setMethod(args.method);
umap.verbose=~strcmpi(args.verbose, 'none');
umap.random_state=~args.randomize;
%umap.negative_sample_rate=30;
tick=tic;
[R,C]=size(inData);

labelMap=[];

if ~isempty(newSubsetIdxs)
    hasLabels=true;
    labelCols=0;
    [labels, labelMap]=resupervise(umap, inData, newSubsetIdxs);
    nLabels=length(unique(labels));
elseif args.label_column>0
    if ~isempty(template_file)
        showMsg(Html.WrapHr(['Can not do supervised mode <br>'...
            'AND use prior template at<br>the same time!']));
        return;
    end
    hasLabels=true;
   labelCols=1;
   labels=inData(:,args.label_column);
   inData(:,args.label_column)=[];
   parameter_names(args.label_column)=[];
   umap.dimNames=parameter_names;
   nLabels=length(unique(labels));
   if exist(args.label_file, 'file')
       map=java.util.Properties;
       try
           map.load(java.io.FileInputStream(args.label_file));
       catch ex
           showMsg(['Can not load ' args.label_file]);
           delete(fig);
           return;
       end
       labelMap=map;
   end
else
    hasLabels=false;
    labelCols=0;
    nLabels=0;
end
if any(isnan(inData(:)))
    if plotting
        if isequal('Yes', questdlg({...
                'Data matrix has NAN values which',...
                'which cause odd effects on UMAP!','', ...
                'Try to remove nan values?'}))
            allNanColumns=all(isnan(inData));
            if any(allNanColumns)
                inData=inData(:, ~allNanColumns);
            end
            allNanRows=all(isnan(inData'));
            if any(allNanRows)
                inData=inData(~allNanRows,:);
            end
            [R,C]=size(inData);
        end
        if any(isnan(inData(:)))
            showMsg(Html.WrapHr(['Sorry...<br>can not proceed<br>'...
                '<br>NAN values exist... SIGH!']));
            return;
        end
    else
        error('Can not proceed with NAN values');
    end
end

info=[String.encodeInteger(R) 'x' String.encodeInteger(C-labelCols)];
if ischar(csv_file_or_data)
    [~, fileName]=fileparts(csv_file_or_data);
    info=['UMAP for ' fileName ', ' info];
else
    info=['[UMAP for ' info];
end

info2=['optimize\_layout method=' method ];
if strcmpi(method, 'Java')
    if plotting
        umap.progress_callback=args.progress_callback;
        set(fig, 'NumberTitle', 'off', 'name', info);
        try
            nTh=edu.stanford.facs.swing.StochasticGradientDescent.EPOCH_REPORTS+3;
            pu=PopUp(Html.WrapHr(sprintf(['Using UMAP to reduce '...
                ' <b>%d</b> parameters down to ' ...
                num2str(args.n_components) '...'], C-labelCols)), ...
                'south++', 'Reducing parameters...', false, true);
            pu.initProgress(nTh);
            pu.pb.setStringPainted(true);
            pu.setTimeSpentTic;
            drawnow;
        catch ex
            args.method='C';
            method=umap.setMethod(args.method);
            showMsg(Html.WrapHr(['Could not load umap.jar for Java method'...
                '<br><br>Switching optimize_layout method to "C" ']), ...
                'Problem with JAVA...', 'south west', false, false);
        end
    end
end
tc=tic;
if plotting
    if ispc
        left=.23;
        width=.6;
        height=.2;
    else
        left=.3;
        width=.45;
        height=.1;
    end
    lbl=annotation(fig, 'textbox','String', {['\color{blue}Generating '...
        info '\color{black}'], info2}, 'units', 'normalized', ...
        'position', [left .4 width height], 'fontSize', 14);
    updatePlot;
end
paramAnnotation=[];
if umap.verbose
    txt=sprintf(['n\\_neighbors=\\color{blue}%d\\color{black}, '...
        'min\\_dist=\\color{blue}%s\\color{black}, '...
        'metric=\\color{blue}%s\\color{black},'...
        'randomize=\\color{blue}%d\\color{black}, '...
        'labels=\\color{blue}%d'], ...
        umap.n_neighbors, num2str(umap.min_dist), umap.metric,...
        ~umap.random_state, nLabels); 
    disp(txt);
    if plotting
        paramAnnotation=annotation(fig, 'textbox','String', txt,...
            'units', 'normalized', 'position', [.03 .94 .92 .05],...
            'fontSize', 9, 'HorizontalAlignment', 'center');
        drawnow;
    end
end
if ~isempty(template_file)
    reduction=umap.transform(inData);
else
    if ~hasLabels 
        reduction = umap.fit_transform(inData);
    else
        reduction = umap.fit_transform(inData, labels);
        if ~isempty(reduction)
            if ~isempty(labelMap)
                umap.setSupervisors(labels, labelMap, curAxes);
            end
        end
    end
end
if ~isempty(paramAnnotation)
    set(paramAnnotation, 'visible', 'on');
end
if ~isempty(reduction)
    if plotting
        figure(fig);
        delete(lbl);
        if strcmpi(method, 'Java') 
            pu.pb.setString('All done');
        end
        updatePlot(reduction, true)
        annotation(fig, 'textbox', 'String', ['Compute time=\color{blue}' ...
            String.MinutesSeconds(toc(tick))],'units', 'normalized', ...
            'position', [.65 .01 .33 .05], 'fontSize', 9)
        if isempty(template_file) && args.ask_to_save_template
            if isequal('Yes', questdlg({'Save this UMAP reduction', ...
                    'as template to accelerate reduction', ...
                    'for compatible other data sets?'}))
                if length(parameter_names)~=size(inData, 2)
                    showMsg(Html.WrapHr(sprintf(['<b>Can not create '...
                        'template</b> ...<br>'...
                        '%d parameter_names ...but data has %d parameters?'], ...
                        length(parameter_names), size(inData,2))));
                else
                    umap.prepareForTemplate(curAxes);
                    if ischar(csv_file_or_data)
                        Template.Save(umap, csv_file_or_data);
                    else
                        Template.Save(umap, fullfile(pwd, 'template.csv'));
                    end
                end
            end
        end
    end
else
    msg('Parameter reduction was cancelled or not done');
end
if strcmpi(method, 'Java') && plotting
    pu.stop;
    pu.dlg.dispose;
end
if nargout>1
    if plotting
        umap.prepareForTemplate(curAxes);
    else
        umap.prepareForTemplate;
    end
    if nargout>2
        clusterIdentifiers=doClusters(reduction, plotting);
        if isempty(clusterIdentifiers)
            dispNoDbScan;
        end
    end
end     

    function clusterIds=doClusters(data, show)
        if isempty(data)
            clusterIds=[];
        else
            [numClusters, clusterIds]=findClusters(data);
            if show
                if ~isempty(clusterIds)
                    ClusterPlots.Go([], data, clusterIds, xLabel, ...
                        yLabel, zLabel);
                end
            end
        end
    end

    function updatePlot(data, lastCall)
        if nargin>0
            if isempty(xLabel)
                dimInfo=sprintf('  %dD\\rightarrow%dD', C-labelCols, ...
                    args.n_components);
                xLabel=['UMAP-X' dimInfo];
                yLabel=['UMAP-Y' dimInfo];
                if args.n_components>2
                    zLabel=['UMAP-Z' dimInfo];
                end
            end
            if args.n_components>2
                nD=size(data, 2);
                assert(nD==args.n_components);
                if args.frequencyDensity3D
                    Gui.PlotDensity3D(curAxes, data, 64, 'iso',...
                        xLabel, yLabel, zLabel);
                else
                    Gui.PlotNeighDist3D(curAxes, data, ...
                        args.n_neighbors);
                end
                if args.n_components>3
                    title(curAxes, ['NOTE:  Only 3 of \color{red}' ...
                        num2str(args.n_components) ...
                        ' dimensions being shown...']);
                end
            else
                if hasLabels
                    if nargin>1 && lastCall
                        %at the end force QF match (slower but more accurate)
                        [lbls, lblMap]=umap.supervisors.supervise(...
                            data, true, true, true);
                        ProbabilityDensity2.DrawLabeled(curAxes, data,...
                            lbls, lblMap, true, true, [], [], -0.01,...
                            0.061, true,[]);
                        % if saving template avoid Qf variables pointing to
                        % original embedding
                        umap.supervisors.clearQf; 
                    else
                        ProbabilityDensity2.DrawLabeled(curAxes, data, ...
                            labels, labelMap);
                    end
                    if ~isempty(paramAnnotation)
                        set(paramAnnotation, 'visible', 'off');
                    end
                else
                    if isprop(umap, 'supervisors') ...
                            && ~isempty(umap.supervisors)
                        if nargin>1 && lastCall
                            if isempty(umap.supervisors.embedding)
                                umap.supervisors.embedding=umap.embedding;
                            end
                            [lbls, lblMap]=...
                                umap.supervisors.supervise(data, true, ...
                                true, true);
                            ProbabilityDensity2.DrawLabeled(curAxes, data,...
                                lbls, lblMap, true, true, [], [], -0.01,...
                                0.061, true,[]);
                        else
                            [lbls, lblMap]=...
                                umap.supervisors.supervise(data, true);
                            ProbabilityDensity2.DrawLabeled(curAxes, data, ...
                                lbls, lblMap);
                        end
                        if ~isempty(paramAnnotation)
                            set(paramAnnotation, 'visible', 'off');
                        end
                    else
                        ProbabilityDensity2.Draw(curAxes, data);
                    end
                end
            end
        end
        if isprop(umap, 'xLimit')
            if ~isempty(umap.xLimit)
                xlim(curAxes, umap.xLimit);
                ylim(curAxes, umap.yLimit);
                if nargin>0
                    Gui.StretchLims(curAxes, data, .04)
                end
            end
        end
        xlabel(curAxes, xLabel);
        ylabel(curAxes, yLabel)
        if args.n_components>2
            zlabel(curAxes, zLabel);
        end
        grid(curAxes, 'on')
        set(curAxes, 'plotboxaspectratio', [1 1 1])
        if nargin>1 && lastCall
            if args.n_components==2
                if isprop(umap, 'supervisors') ...
                        && ~isempty(umap.supervisors)
                    if ~hasLabels
                        umap.supervisors.drawClusterBorders(curAxes);
                    end
                end
            end
        end
        drawnow;
    end

    function keepComputing=progress_report(javaObjectOrString)
        keepComputing=~pu.cancelled;
        if ischar(javaObjectOrString)
            pu.pb.setValue(pu.pb.getValue+1);
            pu.pb.setString(javaObjectOrString);
            pu.pack;
            pu.showTimeSpent;
            return;
        end 
        done=javaObjectOrString.getEpochsDone-1;
        toDo=javaObjectOrString.getEpochsToDo;
        pu.pb.setValue(done+3);
        pu.pb.setMaximum(toDo);
        pu.pb.setString(sprintf('%d/%d epochs done', done, toDo));
        if isvalid(lbl)
            delete(lbl);
        end
        updatePlot(javaObjectOrString.getEmbedding);
        pu.showTimeSpent;
    end

    
    function file=downloadCsv
        if ispc
            prompt='Specify name & folder for saving zip file download';
        else
            prompt=Html.WrapHr(...
                ['Please specify the name and folder for the'...
                '<br>zip file being downloaded'...
                '<br>(which will be unzipped after)']);
        end
        [fldr, file]=FileBasics.UiPut(pwd, 'samplesFromHerzenbergLab.zip', ...
            prompt);
        if isnumeric(fldr)
            file=[];
            return;
        end
        pu=PopUp('Downloading & unzipping samples');        
        zipFile=fullfile(fldr, file);
        websave(zipFile, ...
            'http://cgworkspace.cytogenie.org/GetDown2/demo/samples.zip');
        unzip(zipFile);
        pu.close;
        file=fullfile(fldr, 'sample10k.csv');
    end

    function ok=validateCallback(x)
        ok=isequal('function_handle', class(x));
    end

    function ok=validateParameterNames(x)
        ok=false;
        if iscell(x)
            N=length(x);
            if N>0
                for i=1:N
                    if ~ischar(x{i})
                        ok=false;
                        return;
                    end
                end
                ok=true;
            end
        end
    end

    function [numClusters, clusters]=findClusters(data)
        clusters=[];
        epsilon=args.epsilon;
        if epsilon<1
            epsilon=1;
        end
        neighbors=args.n_neighbors;
        if args.n_components>2
            pu2=PopUp('Finding clusters with dbscan', 'north', ...
                'Clustering...', false);
            try
                clusters=dbscan(data, epsilon, neighbors);
            catch ex
                try
                    % see if DBSCAN is available
                    DBSCAN(randi(100, 50, 3), .5, 15);
                    %YES
                    pu2.setText(Html.WrapHr(['MATLAB''s dbscan not '...
                        'available ... <br>using DBSCAN from'...
                        'MathWorks File Exchange.<br><br><i>Note that'...
                        ' DBSCAN is quite slow!</i>']));
                    clusters=DBSCAN(data, epsilon, neighbors);
                catch ex
                    disp('No dbscan ... before r2019a');
                    if plotting
                        Density.DownloadDbScan;
                    end
                end
            end
            pu2.close;
            numClusters=sum(unique(clusters)>0);
        else
            [numClusters,clusters]=Density.ClusterVeryHigh(data);
        end
    end


    function p=parseArguments(varargin)
        p = inputParser;
        defaultMetric = 'euclidean';
        expectedMetric = {'euclidean', 'cosine', 'cityblock', 'seuclidean',...
            'squaredeuclidean', 'correlation', 'jaccard', 'spearman', 'hamming'};
        defaultVerbose= 'graphic';
        expectedVerbose = {'graphic','text','none'};
        defaultMethod='Java';
        expectedMethod={'Java', 'C', 'C vectorized', 'MATLAB', 'MATLAB vectorized',...
            'MATLAB experimental', 'MATLAB experimental 2'};
        addOptional(p,'csv_file_or_data',[],@(x) ischar(x) || isnumeric(x));
        addParameter(p,'ask_to_save_template', false, @islogical);
        addParameter(p,'randomize', false, @islogical);
        addParameter(p,'template_file',[], @ischar);
        addParameter(p,'n_neighbors', 30, @(x) isnumeric(x) && x>2 && x<200);
        addParameter(p,'min_dist', .3, @(x) isnumeric(x) && x>.05 && x<.8);
        addParameter(p,'metric', defaultMetric, ...
            @(x) any(validatestring(x,expectedMetric)));
        addParameter(p,'n_epochs',[], @(x) isnumeric(x) && x>4);
        addParameter(p,'verbose',defaultVerbose,...
            @(x) any(validatestring(x,expectedVerbose)));
        addParameter(p,'method',defaultMethod,...
            @(x) any(validatestring(x,expectedMethod)));
        addParameter(p, 'parameter_names', {}, @validateParameterNames);
        addParameter(p, 'progress_callback', ...
            @(javaObject)progress_report(javaObject), @validateCallback);
        addParameter(p,'label_column',0,@(x) isnumeric(x) && x>0);
        addParameter(p,'label_file',[], @ischar);
        addParameter(p,'n_components', 2, @(x) isnumeric(x) && x>=2 && x<101);
        addParameter(p,'epsilon', .6, @(x) isnumeric(x) && x>1 && x<100);
        addParameter(p,'frequencyDensity3D', true, @islogical);
    end
end

function dispNoDbScan
        warning(['dbscan for clustering in 3+D is not available ... '...
            '\nDownload from MathWorks File Exchange: '...
            'https://www.mathworks.com/matlabcentral/fileexchange/52905-dbscan-clustering-algorithm']);
end
