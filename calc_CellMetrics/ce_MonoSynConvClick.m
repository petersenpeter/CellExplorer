function mono_res = ce_MonoSynConvClick(spikes,varargin)
    
    %  INPUTS
    %
    %  spikes = CellExplorer struct with below required fields:
    %      .times = cell array with timestamps for each unit in seconds
    %      .shankID = numeric vector with a shank id for each cell. 
    %      .cluID =  numeric vector with cluster ID for each cell
    %      .spindices Nx2 matrix with spike times and a unique ID for each cell. Spike times must be sorted. 
    %       spindices can be generated with the script generateSpinDices.m
    %
    %  OPTIONAL INPUTS:
    %
    %  includeInhibitoryConnections = boolean, whether to detect inhibitory connections
    %
    %  binSize = timebin to compute CCG (in seconds)
    %
    %  duration = window to compute CCG (in seconds)
    %
    %  epoch = [start end] (in seconds)
    %
    %  cells = N x 2 matrix -  [sh celID] to include (NOTE indexing will be
    %          done on full spikeIDlist
    %
    %  conv_w = # of time bins for computing the CI for the CCG.
    %
    %  alpha = type I error for significance testing using convolution
    %     technique. Stark et al, 2009
    %
    %  calls: CCG, ce_InInterval,FindInInterval (from FMA toolbox)
    %         gui_MonoSyn, ce_cch_conv
    %
    %  OUTPUT
    %  mono_res = struct with below fields
    %      .alpha = p-value
    %      .ccgR = 3D CCG (time x ref x target;
    %      .sig_con = list of significant CCG;
    %      .Pred = predicted Poisson rate;
    %      .Bounds = conf. intervals of Poisson rate;
    %      .conv_w = convolution windows (ms)
    %      .completeIndex = cell ID index;
    %      .binSize = binSize;
    %      .duration = duration;
    %      .manualEdit = visual confirmation of connections
    %      .Pcausal = probability of getting more excess in the causal than anticausal direction;
    %      .FalsePositive = FalsePositive rate from English et al., 2017;
    %      .TruePositive = TruePositive rate from English et al., 2017;
    
    %  EXAMPLE:
    %  mono_res = ce_MonoSynConvClick (spikes)
    %  mono_res = ce_MonoSynConvClick (spikes,'binsize',.0005,'duration',.2, ...
    %  'alpha',.05,'conv_w',20,'cells',[1 2;1 3;4 5;8 8],'epoch',[10 3000; 4000 5000]);
    %
    
    % Script by Peter Petersen
    % Adapted by algorithms and previous versions developed by Sam McKenzie, Eran Stark, and others.
    % 24-06-2020
    
    
    if ~isfield(spikes,'spindices')
        disp('Generating spindices')
        spikes.spindices = generateSpinDices(spikes.times);
    end
    spikeIDs = double([spikes.shankID(spikes.spindices(:,2))' spikes.cluID(spikes.spindices(:,2))' spikes.spindices(:,2)]);
    spiketimes = spikes.spindices(:,1);
    
    %get experimentally validated probabilities
    fil = which('ce_MonoSynConvClick.m');
    if ispc
        sl = regexp(fil,'\');
    else
        sl = regexp(fil,'/');
    end
    
    fil = fil(1:sl(end));
    if exist(fullfile(fil, 'ce_ProbSynMat.mat'),'file')
        v = load(fullfile([fil, 'ce_ProbSynMat.mat']));
        foundMat = true;
    else
        foundMat = false;
        disp('ce_MonoSynConvClick: You do not have the ce_ProbSynMat.m matrix describing the likelihood of experimentally validated connectivty given excess syncrony')
    end
    
    validationDuration = @(x) assert(isnumeric(x) && length(X) == 1 && X>0, 'Duration must be numeric and positive');
    validationBinsize = @(x) assert(isnumeric(x) && length(X) == 1 && X>0, 'Binsize must be numeric and positive');
    validationEpoch = @(x) assert(isnumeric(x) && (size(x,2) == 2), 'Epoch must be numeric and of size nx2');
    validationIncludeInhibitoryConnections = @(x) assert(isnumeric(x) || islogical(x), 'Epoch must be numeric and of size nx2');
    
    p = inputParser;
    addParameter(p,'binSize',0.0004,validationBinsize); % 0.4ms
    addParameter(p,'duration',0.120,validationDuration); % 120ms
    addParameter(p,'epoch',[0 inf],validationEpoch); % [0,inf] = whole session
    addParameter(p,'cells',unique(spikeIDs(:,1:2),'rows'),@isnumeric);
    addParameter(p,'conv_w',0.010,@isnumeric); % 10ms window   
    addParameter(p,'alpha',0.001,@isnumeric); % high frequency cut off, must be .001 for causal p-value matrix
    addParameter(p,'sorted',false,@isnumeric);
    addParameter(p,'includeInhibitoryConnections',false,validationIncludeInhibitoryConnections); 
    addParameter(p,'sigWindow',0.004,@isnumeric); % monosynaptic connection will be +/- 4 ms
    
    parse(p,varargin{:})
    binSize = p.Results.binSize;
    duration = p.Results.duration;
    epoch = p.Results.epoch;
    cells = p.Results.cells;
    
    conv_w = p.Results.conv_w/binSize;
    alpha = p.Results.alpha;
    sorted = p.Results.sorted;
    includeInhibitoryConnections = p.Results.includeInhibitoryConnections;
    sigWindow = p.Results.sigWindow;
    
    nCel = size(cells,1);
    if length(varargin) ==1 && iscell(varargin{1})
        varargin = varargin{1};
    end
    
    if ~sorted
        %sort by spike times
        [spiketimes,b] = sort(spiketimes);
        spikeIDs = spikeIDs(b,:);
    end
    
    %restrict by cells and epochs
    [status] = ce_InIntervals(spiketimes,epoch);
    allID = unique(spikeIDs(:,3));
    kp = ismember(spikeIDs(:,1:2),cells,'rows') & status;
    spikeIDs = spikeIDs(kp,:);
    spiketimes = spiketimes(kp);
    
    nBins=duration/binSize+1;
    [IDindex,tet_idx,ID_idx] = unique(spikeIDs(:,3));	% list of IDs
    
    completeIndex = spikeIDs(tet_idx,:);
    
    
    % Create CCGs (including autoCG) for all cells
    disp('Generating CCGs')
    tic
    [ccgR1,tR] = CCG(spiketimes,double(spikeIDs(:,3)),'binSize',binSize,'duration',duration);
    toc
    ccgR = nan(size(ccgR1,1),nCel,nCel);
    ccgR(:,1:size(ccgR1,2),1:size(ccgR1,2)) = ccgR1;
    
    
    % get  CI for each CCG
    Pval=nan(length(tR),nCel,nCel);
    Pred=zeros(length(tR),nCel,nCel);
    Bounds=zeros(size(ccgR,1),nCel,nCel);
    sig_con = [];
    sig_con_inh = [];
    
    TruePositive = nan(nCel,nCel);
    FalsePositive = nan(nCel,nCel);
    Pcausal = nan(nCel,nCel);
    for refcellID=1:max(IDindex)
        for cell2ID= refcellID+1:max(IDindex)
            
            cch=ccgR(:,refcellID,cell2ID); % extract corresponding cross-correlation histogram vector
            
            prebins = round(length(cch)/2 - .0032/binSize):round(length(cch)/2);
            postbins = round(length(cch)/2 + .0008/binSize):round(length(cch)/2 + sigWindow/binSize);
            
            refcellshank=completeIndex(completeIndex(:,3)==refcellID);
            cell2shank=completeIndex(completeIndex(:,3)==cell2ID);
            if refcellshank==cell2shank
                % central 1.6 ms on same-shank = NaN due to limitations of
                % extracting overlapping spikes
                
                centerbins = ceil(length(cch)/2);
                sameshankcch=cch;
                sameshankcch(centerbins)=[];
                
                [pvals,pred,qvals]=ce_cch_conv(sameshankcch,conv_w);
                pred=[pred(1:(centerbins(1)-1));nan(length(centerbins),1);pred(centerbins(end)-length(centerbins)+1:end)];
                
                pvals=[pvals(1:(centerbins(1)-1));nan(length(centerbins),1);pvals(centerbins(end)-length(centerbins)+1:end)];
            else
                % calculate predictions using Eran's ce_cch_conv
                [pvals,pred,qvals]=ce_cch_conv(cch,conv_w);
            end
            
            % Store predicted values and pvalues for subsequent plotting
            Pred(:,refcellID,cell2ID)=pred;
            Pval(:,refcellID,cell2ID)=pvals(:);
            Pred(:,cell2ID,refcellID)=flipud(pred(:));
            Pval(:,cell2ID,refcellID)=flipud(pvals(:));
            
            % Calculate upper and lower limits with bonferonni correction
            
            nBonf = round(sigWindow/binSize)*2;
            
            hiBound=poissinv(1-alpha/nBonf,pred);
            loBound=poissinv(alpha/nBonf, pred);
            Bounds(:,refcellID,cell2ID,1)=hiBound;
            Bounds(:,refcellID,cell2ID,2)=loBound;
            
            Bounds(:,cell2ID,refcellID,1)=flipud(hiBound(:));
            Bounds(:,cell2ID,refcellID,2)=flipud(loBound(:));
            
            % sig = cch>hiBound | cch < loBound;
            
            % % % % % % % % % % % % % % % % % % % % % % %
            % EXCITATORY
            % Find if significant periods falls in monosynaptic window +/- 4ms
            sig = cch>hiBound;
            cchud = flipud(cch);
            sigud = flipud(sig);
            sigpost = max(cch(postbins))>poissinv(1-alpha,max(cch(prebins)));
            sigpre = max(cchud(postbins))>poissinv(1-alpha,max(cchud(prebins)));
            
            % check which is bigger
            if (any(sigud(postbins)) && sigpre)
                %test if causal is bigger than anti causal
                sig_con = [sig_con;cell2ID refcellID];
            end
            
            if any(sig(postbins)) && sigpost
                sig_con = [sig_con;refcellID cell2ID];
            end
            
            % define likelihood of being a connection
            pvals_causal = 1 - poisscdf( max(cch(postbins)) - 1, max(cch(prebins) )) - poisspdf( max(cch(postbins)), max(cch(prebins)  )) * 0.5;
            pvals_causalud = 1 - poisscdf( max(cchud(postbins)) - 1, max(cchud(prebins) )) - poisspdf( max(cchud(postbins)), max(cchud(prebins)  )) * 0.5;
            
            % can go negative for very small p-val - beyond comp. sig. dig
            
            if pvals_causalud<0
                pvals_causalud = 0;
            end
            
            if pvals_causal<0
                pvals_causal = 0;
            end
            
            Pcausal(refcellID,cell2ID) = pvals_causal;
            Pcausal(cell2ID,refcellID) = pvals_causalud;
            if foundMat
                if any(Pval(postbins,cell2ID,refcellID)<.001)
                    FP = v.ProbSyn.FalsePositive((histc(pvals_causalud,v.ProbSyn.thres))>0);
                    TP = v.ProbSyn.TruePositive((histc(pvals_causalud,v.ProbSyn.thres))>0);
                    TruePositive(cell2ID,refcellID) = TP;
                    FalsePositive(cell2ID,refcellID) = FP;
                end
                if any(Pval(postbins,refcellID,cell2ID)<.001)
                    
                    FP = v.ProbSyn.FalsePositive((histc(pvals_causal,v.ProbSyn.thres))>0);
                    TP = v.ProbSyn.TruePositive((histc(pvals_causal,v.ProbSyn.thres))>0);
                    TruePositive(refcellID,cell2ID) = TP;
                    FalsePositive(refcellID,cell2ID) = FP;
                end
            end
            
            
            % % % % % % % % % % % % % % % % % % % % % % %
            % INHIBITORY
            if includeInhibitoryConnections
                sig_inh = cch<loBound;
                cchud = flipud(cch);
                sigud_inh = flipud(sig_inh);
                sigpost_inh = min(cch(postbins))<poissinv(alpha,max(cch(prebins)));
                sigpre_inh = min(cchud(postbins))<poissinv(alpha,max(cchud(prebins)));
                
                % check which is bigger
                if (any(sigud_inh(postbins)) && sigpre_inh)
                    %test if causal is bigger than anti causal
                    sig_con_inh = [sig_con_inh;cell2ID refcellID];
                end
                
                if any(sig_inh(postbins)) && sigpost_inh
                    sig_con_inh = [sig_con_inh;refcellID cell2ID];
                end
            end
        end
    end
    
    nCel = size(completeIndex,1);
    n = histc(spikeIDs(:,3),1:length(allID));
    [nn1,nn2] = meshgrid(n);
    
    temp = ccgR - Pred;
    prob = temp./permute(repmat(nn2,1,1,size(ccgR,1)),[3 1 2]);
    
    % Creating output structure
    mono_res.ccgR = ccgR;
    %     mono_res.Pval = Pval;
    %     mono_res.prob = prob;
    %     mono_res.prob_noncor = ccgR./permute(repmat(nn2,1,1,size(ccgR,1)),[3 1 2]);
    mono_res.n = n;
    mono_res.sig_con = sig_con; % FOR BACKWARDS COMPATIBILITY
    mono_res.sig_con_excitatory = sig_con;
    mono_res.sig_con_excitatory_all = sig_con;
    if includeInhibitoryConnections
        mono_res.sig_con_inhibitory = sig_con_inh;
        mono_res.sig_con_inhibitory_all = sig_con_inh;
    end
    mono_res.Pred = Pred;
    mono_res.Bounds = Bounds;
    mono_res.completeIndex = completeIndex;
    mono_res.binSize = binSize;
    mono_res.duration = duration;
    mono_res.conv_w = conv_w;
    mono_res.Pcausal = Pcausal;
    
    if foundMat
        mono_res.FalsePositive = FalsePositive;
        mono_res.TruePositive = TruePositive;
    end
end

function out = validSize(X,Y)
    out = size(X,2) == Y;
end