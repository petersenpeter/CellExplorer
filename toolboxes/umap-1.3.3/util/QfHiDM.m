%   Class for Hi-D matching with merging of data subsets using 
%       QF match or F-measure or both 
%
%
%   QF Algorithm is described in 
%   https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6586874/
%   and
%   https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5818510/
%
%   Bioinformatics lead: Darya Orlova <dyorlova@gmail.com>
%   Software Developer: Stephen Meehan <swmeehan@stanford.edu> 
%
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

classdef QfHiDM < handle
    %HiD QF for matching with merging from a pair of data sets
    %t prefix is data set #1 (previously referred to as teacher or training set)
    %s prefix is data set #2 (previously referred to as student or test set)
    
    properties(Constant)
        MERGE_STRATEGIES={...
            'Best matches (QF or F)', ...
            '<html>Best + top 1.5 * N matches</html>', ...
            '<html>Best + top 2 * N matches</html>',...
            '<html>Best + top 2.5 * N matches</html>', ...
            '<html>Best + top 3 * N matches</html>',...
            '<html>Best + top 3.5 * N matches</html>',...
            '<html>Best + top 4 * N matches</html>', ...
            '<html>Best + top 4.5 * N matches</html>', ...
            '<html>Best + top 5 * N matches</html>'};
        MSG_ID_TOO_BIG='QFHiDM:tooBig';
        MAX_GATE_SIZE=200000;
        MAX_QF_DISTANCE=100;
        PROP_F_MEASURE_OPTIMIZE='matchStrategy';
        PROP_MIN_SECS='minSecs';
        PROP_SECS='secs';
        PROP_BIN_SIZE='2logN';
        PROP_QFTREE_FCS='dendrogramFcs';
        PROP_BIN_METHOD='ProbBinMethodV2';
        PROP_MERGE_STRATEGY='mergeStrategy';
        PROP_MERGE_LIMIT='mergeLimit';
        PROP_MERGE_PAUSE='mergePause';
        PROP_DEVIATION_TYPE='tooFarDevTypeV4';
        PROP_DEVIATION_DATA='tooFarDevDataV2';
        DFLT_DEVIATION_TYPE_FACS=2;
        DFLT_DEVIATION_TYPE_CYTOF=2;
        DFLT_DEVIATION_DATA_FACS=2;
        DFLT_DEVIATION_DATA_CYTOF=1;
        PROP_SDU_STAIN='sduStainV4';
        PROP_SDU_SCATTER='sduScatterV4';
        PROP_MAX_DEVIANT_PARAMETERS='maxDeviantParameters';
        PROP_EMD='Emd';
        TIP_MERGE_STRATEGY=[...
            '<html>If matching 10 automatic subsets to 6 non<br>'...
            'automatic subsets then the merge candidates for'...
            '<ul><li><b>Best matches (QF or F)</b><br>' ...
            'are the 10 automatic gate''s best matches'...
            '<li><b>Best + top 1.5 * N matches</b><br>'...
            'are the 10 automatic gate''s best matches<br>'...
            'PLUS the highest 9 matches overall (1.5 * 6)'...
            '<li><b>Best + top 2 * N matches</b><br>'...
            'are the 10 automatic gate''s best matches<br>'...
            'PLUS the highest 12 matches overall (2 * 6)'...
            '<li><b>Best + top 2.5 thru 5 * N matches</b><br>'...
            'Same logic as above with more top matches overall'...
            '<hr></html>'];
        TIP_MERGE_LIMIT=[...
            '<html>Set the max merge candidates per subset'...
            '</html>'];
        TIP_MERGE_PAUSE=[...
            '<html>Pause to allow speed up of limits exceeded'...
            '</html>'];
        TIP_DEVIATION_TYPE='Robust handles skewing better (AKA median absolute deviation)...';
        TIP_DEVIATION_DATA='Log provides normal distribution...';
        F_MEASURE_OPTIMIZE=true;
        TEST_F_MEASURE_OPTIMIZE=false;
        DO_NEXT_BEST=false;
        DEV_MAX=4;%stain parameters
        DEV_MAX_LOG10=1;%scatter parameters
        ALLOW_WAYNE_MOORE_RANDOMIZE=true;
        DISTANCES={'QF', 'CityBlock', 'Chebychev',...
                        'Cosine', 'Euclidean', 'SquaredEuclidean', ...
                        'Earth mover''s (EMD)', 'QF + Euclidean', ...
                        'QF + CityBlock', 'Fast EMD'};
    end
    
    properties(SetAccess=private)
        isScatter=[];
        sduStain;
        sduScatter;
        scatterDevUnitsExceeded=0;
        stainDevUnitsExceeded=0;
        forbiddenByDevUnits=0;
        devType=1;
        mergeLimit=0;
        distanceType;
        adaptiveBins;
        %emdBins;
        nCells;
        tData;
        sData;
        tCompData;
        sCompData;
        tIsCytof=false;
        sIsCytof=false;
        tDevData;
        sDevData;
        tIdPerRow; 
        sIdPerRow;
        tIds; % > 0
        sIds; % > 0
        tSizes;
        sSizes
        bins;
        result;
        sMergedIds={};
        tMergedIds={};
        pu;
        matches;
        matches2nd;
        nextBest;
        binStrategy;
        columnNames;
        sizeLimit=0;
        ignoreTooBig=false;
        cancelled;
        tree;
        isTree=false;
        numLeaves;
        branches;
        branchLevels;
        phyTree;
        treeSz;
        leafSzs;
        nodeSzs;
        branchNames;
        branchQfs;
        nodeQfs;
        isIdentityMatrix=false;
        areEqual;
        isMerging=false;
        devMax;
        qfDistCoefficient=0;
        matrixHtml;
        measurements;
        rawMeasurements;
        fcsIdxs;
        fcsIdxsStr;
        sGt;
        tGt;
        studGid;
        teachGid;
        tMergeCnts;
        sMergeCnts;
        avoidedMerging=false;
    end
    
    properties
        tAvoidMerges;
        sAvoidMerges;
        timing;
        sNames;
        tNames;
        debugLevel=0;
        debugTxt;
        debugAb;
        maxDeviantParameters=0;
        matchStrategy=0;
        mergeStrategy=1;
        fMeasuringUnmerged=false;
        fMeasuringMerged=false;
        maxMerges=0;
    end
    
    
    methods(Static)
        function strs=MERGE_LIMITS
            app=BasicMap.Global;
            sm1=[app.smallStart '<b>'];
            sm2=['</b>' app.smallEnd];
            strs={...
            ['<html>Unlimited matches per subset'],...
            ['<html>&lt;= 7 matches ' sm1 '(per subset, 120 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 8 matches ' sm1 '(per subset, 247 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 9 matches ' sm1 '(per subset, 502 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 10 matches ' sm1 '(per subset,  1,013 mergers )' sm2 '</html>'],...
            ['<html>&lt;= 11 matches ' sm1 '(per subset, 2,036 mergers )' sm2 '</html>'],...
            ['<html>&lt;= 12 matches ' sm1 '(per subset, 4,083 mergers )' sm2 '</html>'],...
            ['<html>&lt;= 13 matches ' sm1 '(per subset, 8,178 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 14 matches ' sm1 '(per subset, 16,369 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 15 matches ' sm1 '(per subset, 32,752 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 16 matches ' sm1 '(per subset, 65,519 mergers)' sm2 '</html>'],...
            ['<html>&lt;= 17 matches ' sm1 '(per subset, 131,054 mergers)' sm2 '</html>']...
            };
        end
        
        %if strategy=0 bin the merged samples ONCE as described in paper an
        %if strategy=-1 same as 0 but scale subset weight to sample size
        %if strategy=1 then bin EACH subset pair (not supported by paper)
        function strategy=BIN_STRATEGY
            strategy=0;
        end
        
        %if bins>3 then create 2^log(N)
        %if bins<4 && >-1 then 2*log
        %if bins is -1 then half smallest cluster        
        %if bins is -2 then 2% of max+min cluster        
        function bins=BINS
            bins=-50; %50% of smallest 
        end
    end
    methods(Access=private)
        function ok=preCheckDeviations(this)
            ok=this.maxDeviantParameters>=0 && ~this.isIdentityMatrix;
        end
    end
    methods
        function this=QfHiDM(tData, tCompData, tIdPerRow, sData, ...
                sCompData, sIdPerRow, bins, binStrategy, ...
                teachStudCacheFile, studTeachCacheFile, devMax, isScatter)
            if nargin<12
                isScatter=[];
                if nargin<11
                    devMax=zeros(1, size(tCompData,2))+QfHiDM.DEV_MAX;
                    if nargin<10
                        studTeachCacheFile=[];
                        if nargin<9
                            teachStudCacheFile=[];
                        end
                    end
                end
            end
           this.isScatter=isScatter;
           this.timing=tic;
           this.devMax=devMax;
           this.tIdPerRow=tIdPerRow;
           [this.tIds, this.tSizes]=MatBasics.GetUniqueIdsAndCntIfGt0(tIdPerRow);
           this.sIdPerRow=sIdPerRow;
           [this.sIds, this.sSizes]=MatBasics.GetUniqueIdsAndCntIfGt0(sIdPerRow);
           if nargin<8
               binStrategy=QfHiDM.BIN_STRATEGY;
               if nargin<7
                   bins=QfHiDM.BINS;
               end
           end
           this.bins=bins;
           allSizes=[this.tSizes' this.sSizes'];
           mn=min(allSizes);

           tooBig=sum(allSizes>QfHiDM.MAX_GATE_SIZE);
           if tooBig>0
               if tooBig==1
                   word1=[num2str(tooBig) ' gate is'];
                   word2='';
               else
                   word1=[num2str(tooBig) ' gates are'];
                   word2='maximum=';
               end
               msgTxt=sprintf(...
                   ['<html>%s &gt; %s (%s%s cells), thus QF matching '...
                   '<br>could be very slow or run out of memory.<br>'...
                   '<br>Ignore these big gates ...or try to match them?<hr></html>'], ...
                   word1, String.encodeK(QfHiDM.MAX_GATE_SIZE),...
                   word2, String.encodeK(max(allSizes)));
               ignoreTxt='Ignore big gates';
               [answ, ~, this.cancelled]=questDlg(struct(...
                   'msg', msgTxt, 'remember', 'QfHiDM:tooBig'), ...
                   'Size issues...', ignoreTxt, 'Match (slow)', ignoreTxt);
               if this.cancelled
                   return;
               end
               this.ignoreTooBig=isempty(answ) || isequal(answ, ignoreTxt);
           end
           if bins<-9 %half smallest subset size?                              
               perc=abs(bins)/100;
               sizeLimit_=floor(mn*perc);
               if ~isequal(sData, tData)
                   nEvents=size(sData,1)+size(tData,1);
                   minEvents=min([size(sData,1)+size(tData,1);]);
               else
                   nEvents=size(sData,1);
                   minEvents=nEvents;
               end
               min2mLog=floor(2*log(minEvents));
               this.debugAb='<h2>Probability bin summary</h2>';
               %bins=0;
               if sizeLimit_<min2mLog
                   bins=0;
                   this.debugAb=sprintf([this.debugAb ...
                       '<h3>%d events per probability '...
                       'bin based on 2*log(%s)</h3>'], min2mLog, nEvents);
               else
                   if perc ~= .5 %experimenting with % of min
                       txt=sprintf(...
                           ['<html><center>Bin size is %d <br>'...
                           '(%d%% of smallest subset is %d)</center>'...
                           '<hr></html>'], ...
                           sizeLimit_, round(perc*100, 1), floor(mn));
                       if ~isempty(this.pu)
                           msg(txt);
                       else
                           disp(txt);
                       end
                   end
                   this.sizeLimit=sizeLimit_;
                   this.debugAb=sprintf([this.debugAb ...
                       '<h3>%d events per probability '...
                       'bin based on %s of smallest subset %s</h3>'], ...
                       sizeLimit_, String.encodePercent(perc, 1, 0), ...
                       String.encodeInteger(mn));
               end
           end
           this.nextBest=BasicMap;
           this.binStrategy=binStrategy;
           this.tData=tData;
           this.tCompData=tCompData;
           this.sData=sData;
           this.areEqual=isequal(this.tData, this.sData);
           this.nCells=MatBasics.CountNonZeroPerColumn(tIdPerRow)+...
               MatBasics.CountNonZeroPerColumn(sIdPerRow);
           this.sCompData=sCompData;
           if this.binStrategy==-1 || this.binStrategy==0
               if bins<-9 %half smallest subset size
                   this.adaptiveBins=AdaptiveBins(tData, sData, ...
                       this.sizeLimit, false, teachStudCacheFile, ...
                       studTeachCacheFile);               
               elseif bins<4  %use 2*log of size of merged data
                   this.adaptiveBins=AdaptiveBins(tData, sData, [],...
                       false, teachStudCacheFile, studTeachCacheFile);
               else
                   this.adaptiveBins=AdaptiveBins(tData, sData, bins, ...
                       true, teachStudCacheFile, studTeachCacheFile);
               end
               [pbR, pbC]=size(this.adaptiveBins.means);
               this.debugAb=sprintf('%s<h3>%s bins of %d dimensions<h3><hr>', ...
                   this.debugAb, String.encodeInteger(pbR), pbC);
           end
        end
    end
    methods
        function fcs=sortColumnNames(this, gt, gid)
            fcs=gt.getFirstFcs(gid);
            this.columnNames=StringArray.Sort(this.columnNames,...
                fcs.statisticParamNames);
            this.fcsIdxs=fcs.findFcsIdxs(this.columnNames);
            this.fcsIdxsStr=MatBasics.toString(this.fcsIdxs,'-');
        end
        
        function prepareMedianMarkerExpressions(this, gt, gid)
            oldOrder=this.columnNames;
            fcs= this.sortColumnNames(gt, gid);
            R=length(this.tIds);
            C=length(this.columnNames);
            mdns=zeros(R, C);
            oldRaw=MatBasics.GetMdns(this.tCompData, this.tIdPerRow, this.tIds);
            if isempty(fcs.logicle.out)
                for i=1:R
                    result_=zeros(1,C);
                    for j=1:C
                        result_(j)=oldRaw(i,j);
                    end
                    mdns(i,:)=result_;
                end
                this.measurements=mdns;
                this.rawMeasurements=oldRaw;

                return;
            end
            Ws=fcs.logicle.out.Ws;
            spn=fcs.statisticParamNames;
            newRaw=zeros(R, C);
            for i=1:R
                result_=zeros(1,C);
                for j=1:C
                    name=this.columnNames{j};
                    fcsCol=StringArray.IndexOf(spn,name);
                    oldI=StringArray.IndexOf(oldOrder, name);
                    W=Ws(fcsCol);
                    T=fcs.getUpperLimit(fcsCol);
                    v=oldRaw(i,oldI);
                    if W==0
                        result_(j)=v;
                    else
                        result_(j)=Logicle.TransformFast(v, T, W, ...
                            fcs.hdr.isCytof);
                    end
                    newRaw(i,j)=v;
                end
                mdns(i,:)=result_;
            end
            this.measurements=mdns;
            this.rawMeasurements=newRaw;
        end
        
        function webPage(this)
            if this.debugLevel>0 && (this.binStrategy==-1 || this.binStrategy==0)
                if this.bins<-9 %half smallest subset size
                    sl=this.sizeLimit;
                    fixed=false;
                elseif this.bins<4  %use 2*log of size of merged data
                    sl=[];
                    fixed=false;
                else
                    sl=this.bins;
                    fixed=true;
                end                
                [~, ~,~,~,~, html, dataHtml, idHtml, statHtml]=...
                    probabilityBins(this.tData, this.sData, sl, fixed, [], ...
                    this.tIdPerRow);
                idHtml=['<hr><h2>Probability bin results per gate</h2>' idHtml];
                Html.Browse(['<html>' idHtml this.debugTxt idHtml ...
                    '<hr><h2>Input data & bin assignment</h2>' dataHtml idHtml ...
                    '<hr><h2>Probability bin results per gate</h2>' statHtml...
                    '<hr><h2>Probability binn means/distances</h2>' ...
                    html idHtml '</html>']);
            else
                Html.Browse([this.debugTxt '</html>']);
            end
        end
        
        function setGts(this, teachGt, studGt, teachGid, studGid, fcsNames)
            this.tGt=teachGt;
            this.teachGid=teachGid;
            this.sGt=studGt;
            this.studGid=studGid;
            devData=teachGt.tp.getNumeric(QfHiDM.PROP_DEVIATION_DATA,...
                QfHiDM.DFLT_DEVIATION_DATA_CYTOF);    
            [this.tDevData, this.tIsCytof]=randomize(teachGt, teachGid,...
                this.tCompData);
            [this.sDevData, this.sIsCytof]=randomize(studGt, studGid, ...
                this.sCompData);
            this.sduScatter=teachGt.tp.getNumeric(QfHiDM.PROP_SDU_SCATTER, ...
                QfHiDM.DEV_MAX_LOG10);
            this.sduStain=teachGt.tp.getNumeric(QfHiDM.PROP_SDU_STAIN, ...
                QfHiDM.DEV_MAX);
            if this.sduStain ~= QfHiDM.DEV_MAX ...
                    || this.sduScatter ~= QfHiDM.DEV_MAX_LOG10
                N2=length(this.devMax);
                if isempty(this.isScatter)
                    for ii=1:N2
                        if this.devMax(ii)==QfHiDM.DEV_MAX
                            this.devMax(ii)=this.sduStain;
                        else
                            this.devMax(ii)=this.sduScatter;
                        end
                    end
                else
                    for ii=1:N2
                        if ~this.isScatter(ii)
                            this.devMax(ii)=this.sduStain;
                        else
                            this.devMax(ii)=this.sduScatter;
                        end
                    end
                end
            end
            
            function [out, isCytof]=randomize(gt, gid, data)
                out=[];
                isCytof=gt.isCytof(gid) ;
                if devData~=3 && isCytof && QfHiDM.ALLOW_WAYNE_MOORE_RANDOMIZE
                    [R, C]=size(data);
                    ran=-.5+rand(R,C);
                    out=data+ran;
                    if devData==2
                        fcs=gt.getFirstFcs(gid);
                        fcsIdxs_=fcs.findFcsIdxs(fcsNames);
                        N=length(fcsIdxs_);
                        for i=1:N
                            col=fcsIdxs_(i);
                            out(:,i)=Logicle.TransformFastCol(out(:,i), fcs, col);
                        end
                    elseif devData==1
                        out=MatBasics.LogReal(@log10, out);
                    elseif devData==4
                        out=MatBasics.LogReal(@log2, out);
                    elseif devData==5
                        out=MatBasics.LogReal(@log, out);
                    end
                end
            end
        end
        
        function done=compute(this, pu, convertIdsToCellStrings, totalSteps)
            if nargin<4
                totalSteps='/5';
            elseif isnumeric(totalSteps)
                totalSteps=['/' num2str(totalSteps)];
            end
                
            this.nextBest.reset;
            done=false;
            if nargin<3
                convertIdsToCellStrings=true;
                if nargin<2
                    pu=[];
                end
            end
            this.pu=pu;
            this.fMeasuringUnmerged=...
                this.matchStrategy==2 ...
                && ~this.isIdentityMatrix ...
                && isempty(this.debugTxt);
            this.fMeasuringMerged=...
                this.matchStrategy>=2 ...
                && ~this.isIdentityMatrix ...
                && isempty(this.debugTxt);
            this.setText(['Step 1' totalSteps]);
            unmergedQfs=this.computeUnmerged;
            if this.forbiddenByDevUnits>0
                str1=sprintf('%d subset matches &gt; your deviation units thresholds', ...
                    this.forbiddenByDevUnits);
                str2=sprintf('%d scatter parameter matches are too far apart', this.scatterDevUnitsExceeded);
                str3=sprintf('%d stain parameter matches are too far apart', this.stainDevUnitsExceeded);
                disp(str1);
                disp(str2);
                disp(str3);
                msg(Html.WrapHr(['<i>' str1 '</i><ul><li>' str2 ...
                    '<li>' str3 '</ul>']), 8, 'south west', 'Note...');
            end
            if this.isCancelled
                return;
            end
            this.isMerging=true;
            this.setText('Computing mergers', true);
            ticMerged=tic;
            if ~isempty(this.pu)
                progressBeforeMerge=this.pu.pb.getValue;
            end
            if ~this.checkSpeedUp(unmergedQfs)
                return;
            end
            [M, sIdsM, tIdsM]=this.computeMerged(unmergedQfs, totalSteps);
            toc(ticMerged);
            if this.isCancelled
                if this.userWantsToAvoidMerges
                    this.pu.cancelled=false;
                    this.cancelled=false;
                    if ~isempty(this.pu)
                        this.pu.pb.setValue(progressBeforeMerge);
                    end
                    this.avoidedMerging=true;
                    [M, sIdsM, tIdsM]=this.computeMerged(unmergedQfs, totalSteps);
                    if this.isCancelled
                        return;
                    end
                else
                    return;
                end
            end
            this.sMergedIds=sIdsM;
            this.tMergedIds=tIdsM;
            this.setText(['Step 4' totalSteps]);
            collectBestMatches(this, M, convertIdsToCellStrings);
            if this.cancelled
                return;
            end
            this.pu=[];
            done=true;
            [mnRows, mnCols]=MatBasics.Min(M);
            if this.fMeasuringUnmerged
                ttl='Scores are 1-F measure';
            else
                if this.fMeasuringMerged
                    ttl=['Scores are Quadratic Form distance<br>' ...
                        '(Optimized by F measure)'];
                else
                    ttl='Scores are Quadratic Form distance unoptimized';
                end
            end
            this.matrixHtml=['<html><center><h2>' ttl '</h2><hr></center>' ...
                Html.MatrixColored(...
                doHdr(this.sIds, sIdsM, this.sNames, this.sSizes, 'test'), ...
                doHdr(this.tIds, tIdsM, this.tNames, this.tSizes, 'train'), M, {},-1,@encode)...
                '</html>'];
            function num=encode(row, col, num)
                try
                    if num==QfHiDM.MAX_QF_DISTANCE
                        num='';
                        return;
                    end
                    if num>QfHiDM.MAX_QF_DISTANCE
                        num=num-QfHiDM.MAX_QF_DISTANCE;
                        num=['<small>' num2str(num) '>sdu</small>'];
                        return;
                    end
                    num=String.encodeRounded(num, 2, true);
                    
                    if mnCols(col)==row && mnRows(row)==col
                        num=['<b><font color="red">' num '</font></b>'];
                    elseif mnCols(col)==row || mnRows(row)==col
                        num=['<b>' num '</b>'];
                    end
                catch ex
                    ex.getReport
                end
            end
            function hdr=doHdr(ids, mergeIds, names, szs, setName)
                nIds=length(ids);
                if isempty(names)
                    names=cell(1,nIds);
                    for i=1:nIds
                        names{i}=[setName ' #' num2str(i)];
                    end
                end
                nMergeIds=length(mergeIds);
                hdr=cell(1, nIds+nMergeIds);
                for i=1:nIds
                    hdr{i}=[names{i} '<br>  ID=' num2str(ids(i)) '; '...
                        num2str(szs(i))];
                end
                for i=1:nMergeIds
                    if size(mergeIds{i},2)>1
                        hdr{i+nIds}=['Merged IDS=' num2str(mergeIds{i})];
                    else
                        hdr{i+nIds}=['Merged IDS=' num2str(mergeIds{i}')];
                    end
                end
            end
        end
        
        
        function  matrix=computeQfPlusDist(this, matrix, fnc)
            dt=this.distanceType;
            if ~isequal(dt, 'QF + Euclidean')...
                    && ~isequal(dt, 'QF + CityBlock') 
                return;
            end
            if isequal(dt, 'QF + Euclidean')
                this.distanceType='Euclidean';
            else
                this.distanceType='CityBlock';
            end
            distanceMatrix=feval(fnc);
            this.distanceType=dt;
            
            % every time dendrogram is constructed
            %   compute the coefficient ONCE for unmerged subsets ONLY
            if this.qfDistCoefficient==0 
                minQf=min(matrix(matrix(:)~=0));% avoid 0 identity value
                maxDistance=max(distanceMatrix(:));
                this.qfDistCoefficient=(maxDistance/minQf)^(-1);
            end
            matrix=matrix+(this.qfDistCoefficient*distanceMatrix);
        end
        
        function done=computeTree(this, pu, names)
            dt=BasicMap.Global.getNumeric(QfTree.PROP_DISTANCE, ...
                QfTree.DFLT_DISTANCE);
            this.distanceType=QfHiDM.DISTANCES{dt};
            this.isIdentityMatrix=true;
            this.isTree=true;
            this.tree=BasicMap;
            this.nextBest.reset;
            done=false;
            this.tNames=names;
            if nargin<3
                if nargin<2
                    pu=[];
                end
            end
            this.pu=pu;
            this.focusPriorFig;
            this.setText(['Computing phenogram using ' ...
                this.distanceType ' distance']);
            this.numLeaves=length(this.tIds);
            if ~isempty(this.debugTxt)
                this.debugTxt=[this.debugTxt this.debugAb];
            end
            [matrix, tSzs]=this.computeUnmerged;
            this.treeSz=sum(tSzs);
            try
                if BasicMap.Global.has(QfTree.PROP_FREQ_BASIS)
                    tz=BasicMap.Global.get(QfTree.PROP_FREQ_BASIS);
                    if isnumeric(tz) && ~isnan(tz)
                        this.treeSz=tz;
                    end
                    BasicMap.Global.remove(QfTree.PROP_FREQ_BASIS);
                end
            catch ex
            end
            this.leafSzs=tSzs;
            if this.isCancelled
                return;
            end
            matrix=this.computeQfPlusDist(matrix, ...
                @()computeUnmerged(this));
            if this.isCancelled
                return;
            end
            [pairs, unpaired]=MatBasics.FindBestPairs(matrix, max(matrix(:))+100);
            nPairs=size(pairs,1);
            nUnpaired=length(unpaired);
            prevIds=cell(1, this.numLeaves);
            for i=1:this.numLeaves
                prevIds{i}=this.tIds(i);
            end
            if nPairs+nUnpaired>1
                level=2;
                while nPairs+nUnpaired>1
                    nextIds=cell(1, nPairs+nUnpaired);
                    for i=1:nPairs
                        nextIds{i}=newBranch(pairs(i,:));
                    end
                    for j=1:nUnpaired
                        nextIds{i+j}=prevIds{unpaired(j)};
                    end
                    levelTxt=['Phenogram level #' num2str(level) ':'];
                    [matrix, tSzs]=this.computeNbyN(nextIds, nextIds, levelTxt);
                    if this.isCancelled
                        return;
                    end
                    matrix=this.computeQfPlusDist(matrix, ...
                        @()computeNbyN(this, nextIds, nextIds, levelTxt));
                    if this.isCancelled
                        return;
                    end
                    [pairs, unpaired]=MatBasics.FindBestPairs(matrix, max(matrix(:))+100);
                    nPairs=size(pairs,1);
                    nUnpaired=length(unpaired);
                    prevIds=nextIds;
                    level=level+1;
                end
            end
            if this.isCancelled
                return;
            end
            if nPairs==1
                newBranch(pairs(1,:))
            end
            [this.phyTree, this.branchNames, this.nodeQfs, branchSzs,...
                this.branchQfs]=Branch.PhyTree(this.branches, this.numLeaves);
            this.nodeSzs=[this.leafSzs branchSzs];
            this.pu=[];
            done=true;
            
            function merge=newBranch(pair)
                left_=pair(1);
                right_=pair(2);
                merge=this.addBranch(...
                    matrix(left_, right_),...
                    tSzs(left_), tSzs(right_),...
                    prevIds{left_}, prevIds{right_});
            end
        end
        
        function qfTree=viewTree(this, ttl, ...
                props,  colors, edgeColors, lineWidths, tNames)
            qfTree=QfTree(this, ttl, props, '', colors, ...
                edgeColors, lineWidths, tNames);
        end
        
        function [teachIds, studIds, t, s, firstMatch]=getUnmatched(this)
            t=true(1, length(this.tIds));
            s=true(1, length(this.sIds));
            firstMatch=zeros(1, length(this.sIds));
            n=length(this.matches);
            for i=1:n
                match=this.matches{i};
                t=processIds(match.tIds, this.tIds, t);
                [s, sIdxs]=processIds(match.sIds, this.sIds, s);
                tId=str2double(match.tIds{1});
                for k=1:length(sIdxs)
                    firstMatch(sIdxs(k))=tId;
                end
            end
            teachIds=this.tIds(t);
            studIds=this.sIds(s);
            
            function [l, idxs]=processIds(strIds, ids, l)
                idxs=[];
                n_=length(strIds);
                for j=1:n_
                    id=str2double(strIds{j});
                    idx=find(id==ids, 1);
                    if ~isempty(idx)
                        l(idx)=false;
                        idxs(end+1)=idx;
                    end
                end
            end
        end
        
        function [tQ, sQ, tF, sF]=getScores(this)
            tQ=zeros(1, length(this.tIds));
            sQ=zeros(1, length(this.sIds));
            tF=zeros(1, length(this.tIds));
            sF=zeros(1, length(this.sIds));
            n=length(this.matches);
            for i=1:n
                match=this.matches{i};
                tQ=processIds(match.tIds, this.tIds, tQ, match.qfDissimilarity);
                sQ=processIds(match.sIds, this.sIds, sQ, match.qfDissimilarity);
                tF=processIds(match.tIds, this.tIds, tF, match.fMeasure);
                sF=processIds(match.sIds, this.sIds, sF, match.fMeasure);

            end
            
            function s=processIds(strIds, ids, s, score)
                idxs=[];
                n_=length(strIds);
                for j=1:n_
                    id=str2double(strIds{j});
                    idx=find(id==ids, 1);
                    if ~isempty(idx)
                        s(idx)=score;
                    end
                end
            end
        end
    end
    
    methods(Access=private)
        function merge=addBranch(this, qfScore, leftSize, rightSize, leftIds, rightIds)
            ptr=this.numLeaves+length(this.branches)+1;
            branch=Branch(this.tree, this.tIds,qfScore, leftSize, rightSize, leftIds, rightIds, ptr);
            if branch.leftPtr<=this.numLeaves
                branch.leftName=this.tNames(branch.leftPtr);
                disp(['teachName=' branch.leftName ' ' num2str(leftSize)]);
            end
            if branch.rightPtr<=this.numLeaves
                branch.rightName=this.tNames(branch.rightPtr);
                disp(['teachName=' branch.rightName ' ' num2str(rightSize)]);
            end
            this.branches{end+1}=branch;
            merge=branch.merge;
        end
        
        function ok=userWantsToAvoidMerges(this)
            ok=false;    
            ok=AvoidMerging.Adjust(this);
        end
        
        function [M, sIdsM, tIdsM]=computeMerged(this, unmergedQfs, totalSteps)
            this.setText(['Step 2' totalSteps]);
            [M, sIdsM]=go(unmergedQfs, unmergedQfs, false);
            if ~isempty(this.pu)
                this.pu.cancelBtn.setText('Cancel');
            end
            if this.isCancelled
                tIdsM=[];
                this.getMergers(unmergedQfs, true);
                return;
            end
            this.setText(['Step 3' totalSteps]);
            [M, tIdsM]=go(unmergedQfs, M, true);
            if ~isempty(this.pu)
                this.pu.cancelBtn.setText('Cancel');
            end
            function [newMatrix, idsM]=go(...
                    unmergedMatrix, newMatrix, transpose)
                idsM={};
                [idIdxsPerMerger, mergerIdxs]=this.getMergers(...
                    unmergedMatrix, transpose);
                if this.isCancelled
                    return;
                end
                nCols=length(mergerIdxs);
                if nCols==0
                    return;
                end
                if transpose
                    word='2nd pass';
                    allStudIds=[QfHiDM.ToCell(this.sIds) sIdsM];
                else
                    word='1st pass';
                end
                cnt=0;
                for jj=1:nCols
                    idxs=idIdxsPerMerger{jj};
                    cnt=cnt+length(idxs);
                end
                this.initProgress(cnt);
                if this.fMeasuringMerged
                    word2='F measure';
                else
                    word2='QF';
                end
                this.setText(sprintf(...
                    '%s by %s %s matches for %s mergers', ...
                    String.encodeInteger(cnt), ...
                    String.encodeInteger(nCols), word2, word), true);
                for jj=1:nCols
                    idxs=idIdxsPerMerger{jj};
                    if ~transpose
                        mergerCol=mergerIdxs(jj);
                        ids=QfHiDM.ToIds(idxs, this.sIds);
                        if this.fMeasuringMerged
                            [r, bestRow]=this.fMeasureNby1(ids, this.tIds, mergerCol);
                            if QfHiDM.TEST_F_MEASURE_OPTIMIZE
                                r2=this.computeNbyN(ids, this.tIds, '', mergerCol, false);
                                testMerge(r, r2);
                            end
                        else
                            r=this.computeNbyN(ids, this.tIds, '', mergerCol, false);
                            [~, bestRow]=min(r(:,mergerCol));
                            if QfHiDM.TEST_F_MEASURE_OPTIMIZE
                                [rr, xx]=this.fMeasureNby1(ids, this.tIds, mergerCol);
                                if xx~=bestRow
                                    disp('xx~=bestRow');
                                    this.fMeasureNby1(ids, this.tIds, mergerCol);
                                end
                            end
                        end
                        if bestRow>0
                            r=r(bestRow,:);
                            ids={ids{bestRow}};
                        end
                        newMatrix=[newMatrix;r];
                    else
                        mergerRow=mergerIdxs(jj);
                        ids=QfHiDM.ToIds(idxs, this.tIds);
                        if this.fMeasuringMerged
                            [r, bestCol]=this.fMeasure1byN(allStudIds, ids, mergerRow);
                            if QfHiDM.TEST_F_MEASURE_OPTIMIZE
                                r2=this.computeNbyN(allStudIds, ids, '', mergerRow, true);
                                testMerge(r, r2);
                            end
                        else
                            r=this.computeNbyN(allStudIds, ids, '', mergerRow, true);
                            [~, bestCol]=min(r(mergerRow, :));
                            if QfHiDM.TEST_F_MEASURE_OPTIMIZE
                                [rr, xx]=this.fMeasure1byN(allStudIds, ids, mergerRow);
                                if xx~=bestCol
                                    disp('assert(xx==bestCol);');
                                    this.fMeasure1byN(allStudIds, ids, mergerRow)
                                end
                            end
                        end
                        if bestCol>0
                            r=r(:,bestCol);
                            ids={ids{bestCol}};
                        end
                        newMatrix=[newMatrix r];
                    end
                    idsM=[idsM ids];                        
                    if this.isCancelled
                        return;
                    end
                end
            end
            
            function testMerge(r, r2)
                [mn1, mnI1]=min(r(:));
                [mn2, mnI2]=min(r2(:));
                if this.matchStrategy==3
                    good=mn1==mn2;
                else
                    good=mnI1==mnI2;
                end
                if ~good
                    msgBox('F measure issues');
                end
            end
        end
        
        function D=fastEmd(this, tIdSet, sIdSet)
            tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSet);
            sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSet);
            tData_=this.tData(tChoices, :);
            sData_=this.sData(sChoices, :);
            D=AdaptiveBins.Emd(tData_, sData_, 7);
            fprintf('EMD=%s....tIds="%s" & sIds="%s"\n', ...
                String.encodeRounded(D, 4), num2str(tIdSet), ...
                num2str(sIdSet'));
        end
        
        function collectBestMatches(this, M, toCellStrings)
            this.result=MatBasics.SortMatrix(M);
            this.setText(sprintf('Finding best of %s comparisons', ...
                String.encodeInteger(this.result.N) ), true);
            N=this.result.N;
            nTeaches=length(this.tIds);
            nStuds=length(this.sIds);
            nMatches=min([nTeaches nStuds]);
            matchCnt=0;
            xUsed=false(1, nStuds);
            yUsed=false(1, nTeaches);
            this.initProgress(N);
            for i=1:N
                [qfDissimilarity, x, y]=...
                    MatBasics.PokeSortedMatrix(this.result, i);
                [sIds_, sIdxs]=QfHiDM.GetIds(x, this.sIds, this.sMergedIds);
                [tIds_, tIdxs]=QfHiDM.GetIds(y, this.tIds, this.tMergedIds);
                if ~any(xUsed(sIdxs)) && ~any(yUsed(tIdxs))
                    xUsed(sIdxs)=true;
                    yUsed(tIdxs)=true;
                    makeMatch(true);
                    if this.cancelled
                        return;
                    end
                    matchCnt=matchCnt+1;
                    if ~QfHiDM.DO_NEXT_BEST
                        if matchCnt==nMatches
                            break;
                        end
                    end
                elseif QfHiDM.DO_NEXT_BEST
                    addNextBest(sIds_, sIdxs, xUsed);
                    addNextBest(tIds_, tIdxs, yUsed);
                end
                if this.isCancelled
                    return;
                end
                this.increment;
            end
            
            function cnt=makeMatch(best)
                if toCellStrings
                    match.sIds=QfHiDM.ToCellStrings(sIds_);
                    match.tIds=QfHiDM.ToCellStrings(tIds_);
                else
                    match.sIds=sIds_;
                    match.tIds=tIds_;
                end
                [match.madUnits, match.tFreq, match.sFreq,~,~,match.tIsMaxSd]=...
                    feval(this.devFcn, this.tDevData, this.sDevData, ...
                    this.tIdPerRow, tIds_, this.sIdPerRow, sIds_);
                if this.matchStrategy==2
                    match.fMeasure=abs(qfDissimilarity-1);
                    match.qfDissimilarity=this.distance(sIds_, tIds_);
                else
                    match.qfDissimilarity=qfDissimilarity;
                    if this.areEqual
                        match.fMeasure=MatBasics.F_measure(this.tCompData,...
                            this.sCompData,this.tIdPerRow, tIds_, ...
                            this.sIdPerRow, sIds_);
                    else
                        match.fMeasure=this.fMeasureInBins(tIds_, sIds_);
                    end
                end
                if this.cancelled
                    cnt=0;
                    return;
                end
                match.x=x;
                match.y=y;
                try
                    disallow=sum(match.madUnits>=this.devMax) > this.maxDeviantParameters;
                    if disallow
                        fprintf('DISALLOWED--->> %d > %d\n',...
                            sum(match.madUnits>=this.devMax), this.maxDeviantParameters);
                    end
                catch ex
                    disallow=false;
                end
                if best && ~disallow
                    this.matches{end+1}=match;
                    cnt=length(this.matches);
                    word='best';
                else
                    this.matches2nd{end+1}=match;
                    cnt=length(this.matches2nd);
                    word='2nd best';
                end
                if length(match.sIds)>1 || length(match.tIds)>1
                    word=[word ' (MERGER)  '];
                end
                if QfHiDM.DEBUG_LEVEL>0
                    fprintf('%s match #%d: %s; X ids=%s & Y ids=%s\n', ...
                        word,  cnt, ...
                        String.encodeRounded(qfDissimilarity, 3, true),...
                        num2str(sIds_), num2str(tIds_));
                end
            end
            
            function addNextBest(ids, idxs, used)
                N2=length(ids);
                for j=1:N2
                    if used(idxs(j))
                        if ~this.nextBest.has(num2str(ids(j)))
                            lastIdx=makeMatch(false);
                            this.nextBest.set(num2str(ids(j)), lastIdx);
                        end
                    end
                end
            end
        end
        
        function [qfDistance, sIds_, tIds_]=...
                getInAscendingOrder(this, nTH, idAsCellString)
            [qfDistance, x, y]=MatBasics.PokeSortedMatrix(...
                this.result, nTH);
            [sIds_, sIdxs]=QfHiDM.GetIds(x, this.sIds, this.sMergedIds);
            [tIds_, tIdxs]=QfHiDM.GetIds(y, this.tIds, this.tMergedIds);
            if nargin>2 && idAsCellString
               sIds_=QfHiDM.ToCellStrings(sIds_);
               tIds_=QfHiDM.ToCellStrings(tIds_);
            end
        end
        
        function [result, tSzs]=computeUnmerged(this)
            if ~isempty(this.tGt)
                app=this.tGt.tp;
            else
                app=BasicMap.Global;
            end
            this.mergeLimit=0;
            if this.tIsCytof || this.sIsCytof
                dfltType=QfHiDM.DFLT_DEVIATION_TYPE_CYTOF;
                dfltData=QfHiDM.DFLT_DEVIATION_DATA_CYTOF;
            else
                dfltType=QfHiDM.DFLT_DEVIATION_TYPE_FACS;
                dfltData=QfHiDM.DFLT_DEVIATION_DATA_FACS;
            end            
            if isempty(app)
                this.devType=dfltType;
            else
                this.devType=app.getNumeric(QfHiDM.PROP_DEVIATION_TYPE,...
                    dfltType);
            end
            if isempty(this.tDevData) && isempty(this.sDevData)
                if isempty(app)
                    devData=dfltData;
                else
                    devData=app.getNumeric(QfHiDM.PROP_DEVIATION_DATA, dfltData);
                end
                if devData==1
                    this.tDevData=MatBasics.LogReal(@log10, this.tCompData);
                    this.sDevData=MatBasics.LogReal(@log10, this.sCompData);
                elseif devData==2
                    this.tDevData=this.tData;
                    this.sDevData=this.sData;
                elseif devData==3
                    this.tDevData=this.tCompData;
                    this.sDevData=this.sCompData;
                elseif devData==4
                    this.tDevData=MatBasics.LogReal(@log2, this.tCompData);
                    this.sDevData=MatBasics.LogReal(@log2, this.sCompData);
                else
                    this.tDevData=MatBasics.LogReal(@log, this.tCompData);
                    this.sDevData=MatBasics.LogReal(@log, this.sCompData);
                end
            end
            if this.fMeasuringUnmerged
                tSzs=[];%would not be needed if f measuring ... not QF tree!
                result=this.fMeasureNbyN(this.sIds, this.tIds, 'unmerged subsets');
            else
                [result, tSzs]=this.computeNbyN(this.sIds, this.tIds, 'unmerged subsets');
            end
        end
        
        function lbls=getLabels(this, idSets)
            isCell_=iscell(idSets);
            N=length(idSets);
            lbls=cell(1,N);
            for i=1:N
                if isCell_
                    lbls{i}=this.getLabel(idSets{i});
                else
                    lbls{i}=this.getLabel(idSets(i));
                end
            end
        end
        
        function lbl=getLabel(this, ids)
            id='';
            lbl='<small>';
            try
                N=length(ids);
                for i=1:N
                    id=ids(i);
                    idx=find(this.tIds==id,1);
                    n=this.tNames{idx};
                    lbl=[lbl n ', ID=' num2str(id) ', '];
                    try
                        lbl=[lbl String.encodeInteger(this.leafSzs(idx))...
                            ' events'];
                    catch ex
                        ex
                    end
                    if i<N
                        lbl=[lbl '<br>'];
                    end
                end
            catch ex
                disp(ex);
                lbl=[lbl sprintf('bug @%d', id)];
            end
            lbl=[lbl '</small>'];
        end
        
        % not transposed
        function matrix=fMeasureNbyN(this, sIdSets, tIdSets, txt)
            rows=length(sIdSets);
            cols=length(tIdSets);
            matrix=zeros(rows, cols);
            if rows==0 || cols==0
                return;
            end
            mx=QfHiDM.MAX_QF_DISTANCE;%realmax;%highest value to not select QF]
            sIsCell=iscell(sIdSets);
            tIsCell=iscell(tIdSets);
            if txt(end)==':'
                txt=sprintf('%s  %s by %s F measure matches', txt, ...
                    String.encodeInteger(rows), ...
                    String.encodeInteger(cols));
            else
                txt=sprintf('%s by %s F measure matches for %s', ...
                    String.encodeInteger(rows), ...
                    String.encodeInteger(cols), txt);
            end
            this.initProgress(rows*cols);
            this.setText(txt, true);
            matrix(:)=mx;
            chunk=floor(rows*cols/200);
            for row=1:rows
                if sIsCell
                    sIdSet=sIdSets{row};
                else
                    sIdSet=sIdSets(row);
                end
                for col=1:cols
                    if tIsCell
                        tIdSet=tIdSets{col};
                    else
                        tIdSet=tIdSets(col);
                    end
                    doF=true;
                    if this.preCheckDeviations 
                        devUnits=feval(this.devFcn, this.tDevData, ...
                            this.sDevData, this.tIdPerRow, tIdSet, ...
                            this.sIdPerRow, sIdSet);
                        deviants=sum(devUnits>this.devMax);
                        if isempty(this.isScatter)
                            stainDeviants=sum(devUnits>=this.devMax & ...
                                this.devMax>=3);
                        else
                            stainDeviants=sum(devUnits>=this.devMax & ...
                                ~this.isScatter);
                        end
                        if deviants>this.maxDeviantParameters
                            doF=false;
                        end
                        this.stainDevUnitsExceeded=...
                            this.stainDevUnitsExceeded+stainDeviants;
                        this.scatterDevUnitsExceeded=...
                            this.scatterDevUnitsExceeded+(deviants-stainDeviants);
                        if deviants>0
                            this.forbiddenByDevUnits=...
                                this.forbiddenByDevUnits+1;
                        end
                    end
                    if ~doF
                    elseif this.areEqual
                        matrix(row,col)=1-MatBasics.F_measure(...
                            this.tCompData,this.sCompData,...
                            this.tIdPerRow, tIdSet, ...
                            this.sIdPerRow, sIdSet, true);
                        if QfHiDM.DEBUG_LEVEL<0
                            realF=1-matrix(row,col);
                            [binF, binOverlap]=this.fMeasureInBins(tIdSet, sIdSet);
                            if realF>.05 || binF>.05
                                absDif=abs(realF-binF);
                                strAbsDif=String.encodeRounded(absDif, 3, true);
                                if absDif>.3
                                    fprintf('%s <<<<<<<<<<<<< .  ', strAbsDif);
                                elseif absDif>.2
                                    fprintf('%s >>>>>>>>   ', strAbsDif);
                                elseif absDif>.1
                                    fprintf('%s !!!!!!!!!   ', strAbsDif);
                                elseif absDif>.05
                                    fprintf('%s ??? ', strAbsDif);
                                end
                                fprintf('F measure==%s, ', String.encodeRounded(...
                                    realF, 3, true));
                                fprintf('BIN f measure==%s, overlap=%s', ...
                                    String.encodeRounded(binF, 3, true), ...
                                    String.encodePercent(binOverlap, 1, 0));
                                if realF>.8
                                    fprintf('!!\n');
                                else
                                    fprintf('\n');
                                end
                            end
                        end
                    else
                        matrix(row,col)=1-this.fMeasureInBins(tIdSet, sIdSet);
                    end
                    if chunk>3
                        idx=((row-1)*cols)+col;
                        if mod(idx, chunk)==0
                            this.pu.incrementProgress(chunk);
                        end
                    else
                        this.pu.incrementProgress;
                    end
                    if this.isCancelled
                        return;
                    end
                end
            end
        end

        function [topFs, range_]=getOptimizationRange(this)
            if this.matchStrategy~=2
            %if this.matchStrategy==3
                if this.areEqual
                    topN=5;
                    range_=.02;
                else
                    topN=10;
                    range_=.1;
                end
            else
                topN=1;
                range_=0;
            end
            topFs=TopItems(topN);
            %topFs=TopItems(1);
            topFs.add(-1, -1);
        end

        % not transposed
        function [matrix, bestRow]=fMeasureNby1(...
                this, sIdSets, tIdSets, mergerCol)
            bestRow=1;
            rows=length(sIdSets);
            cols=length(tIdSets);
            matrix=zeros(rows, cols);
            if rows==0 || cols==0
                return;
            end
            matrix(:)=QfHiDM.MAX_QF_DISTANCE;
            sIsCell=iscell(sIdSets);
            tIsCell=iscell(tIdSets);                
            if tIsCell
                tIdSet=tIdSets{mergerCol};
            else
                tIdSet=tIdSets(mergerCol);
            end
            bpfm=MatBasics.BestPossibleF_measures(this.tIdPerRow, ...
                tIdSet, this.sIdPerRow, sIdSets);
            [bpfm,I]=sort(bpfm, 'descend');
            tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSet);
            tSize=sum(tChoices);
            chunk=floor(rows/200);
            [topFs, range_]=this.getOptimizationRange;
            for row=1:rows
                maxF=topFs.best;
                if bpfm(row)-range_>maxF
                    row_=I(row);
                    if sIsCell
                        sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSets{row_});
                    else
                        sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSets(row_));
                    end
                    if this.areEqual
                        F=Clusters.F_measure(sum(tChoices&sChoices),...
                            tSize, sum(sChoices));
                    else
                        F=this.adaptiveBins.fMeasure(tChoices, sChoices);
                    end
                    topFs.add(F, row_);
                else
                    this.pu.incrementProgress(rows-row);
                    break;
                end
                if chunk>3 
                    if mod(row, chunk)==0
                        this.pu.incrementProgress(chunk);
                    end
                else
                    this.pu.incrementProgress;
                end
                if this.isCancelled
                    return;
                end
            end
            if this.matchStrategy==2
                [maxF, bestRow]=topFs.best;
                matrix(bestRow, mergerCol)=1-maxF;
            else
                [rows, Fs]=topFs.all;
                nRows=length(rows);
                scores=zeros(1, nRows);
                for i=1:nRows
                    if rows(i)<=0
                        scores(i)=QfHiDM.MAX_QF_DISTANCE;
                    else
                        if sIsCell
                            sIdSet=sIdSets{rows(i)};
                        else
                            sIdSet=sIdSets(rows(i));
                        end
                        scores(i)=this.distance(sIdSet, tIdSet);
                    end
                end
                [mn, mnI]=min(scores);
                bestRow=rows(mnI);
                matrix(bestRow, mergerCol)=mn;
            end            
        end


        %transposed
        function [matrix, bestCol]=fMeasure1byN(...
                this, sIdSets, tIdSets, mergerRow)
            rows=length(sIdSets);
            cols=length(tIdSets);
            matrix=zeros(rows, cols);
            if rows==0 || cols==0
                return;
            end
            matrix(:)=QfHiDM.MAX_QF_DISTANCE;
            sIsCell=iscell(sIdSets);
            tIsCell=iscell(tIdSets);          
            if sIsCell
                sIdSet=sIdSets{mergerRow};
            else
                sIdSet=sIdSets(mergerRow);
            end
            bpfm=MatBasics.BestPossibleF_measures(this.sIdPerRow, ...
                sIdSet, this.tIdPerRow, tIdSets);
            [bpfm, I]=sort(bpfm, 'descend');
            sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSet);
            sSize=sum(sChoices);
            chunk=floor(cols/200);
            [topFs, range_]=this.getOptimizationRange;
            for col=1:cols
                maxF=topFs.best;
                if bpfm(col)-range_>maxF
                    col_=I(col);
                    if tIsCell
                        tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSets{col_});
                    else
                        tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSets(col_));
                    end
                    if this.areEqual
                        newMaxF=Clusters.F_measure(sum(tChoices&sChoices),...
                            sum(tChoices), sSize);
                    else
                        newMaxF=this.adaptiveBins.fMeasure(tChoices, sChoices);
                    end
                    topFs.add(newMaxF, col_);
                else
                    this.pu.incrementProgress(cols-col);
                    break;
                end
                if chunk>3 
                    if mod(col, chunk)==0
                        this.pu.incrementProgress(chunk);
                    end
                else
                    this.pu.incrementProgress;
                end
                if this.isCancelled
                    return;
                end
            end
            if this.matchStrategy==2
                [maxF, bestCol]=topFs.best;
                matrix(mergerRow, bestCol)=1-maxF;
            else
                [cols, Fs]=topFs.all;
                nCols=length(cols);
                scores=zeros(1, nCols);
                for i=1:nCols
                    if cols(i)<=0
                        scores(i)=QfHiDM.MAX_QF_DISTANCE;
                    else
                        if tIsCell
                            tIdSet=tIdSets{cols(i)};
                        else
                            tIdSet=tIdSets(cols(i));
                        end
                        scores(i)=this.distance(sIdSet, tIdSet);
                    end
                end
                [mn, mnI]=min(scores);
                bestCol=cols(mnI);
                matrix(mergerRow, bestCol)=mn;
            end
        end
        

        function [matrix, tSzs]=computeNbyN(this, sIdSets, tIdSets, txt, ...
                only, transpose)
            rows=length(sIdSets);
            cols=length(tIdSets);
            tSzs=zeros(1, cols);
            matrix=zeros(rows, cols);
            if rows==0 || cols==0
                return;
            end
            sIsCell=iscell(sIdSets);
            tIsCell=iscell(tIdSets);
            if nargin<5
                if txt(end)==':'
                    txt=sprintf('%s  %s by %s QF matches', txt, ...
                        String.encodeInteger(rows), ...
                        String.encodeInteger(cols));
                else
                    txt=sprintf('%s by %s QF matches for %s', ...
                        String.encodeInteger(rows), ...
                        String.encodeInteger(cols), txt);
                end
                this.initProgress(rows*cols);
                this.setText(txt, true);
            else
                txt=sprintf('%s by %s QF matches, only=%d, transpose=%d',...
                    String.encodeInteger(rows), ...
                    String.encodeInteger(cols), only, transpose);
            end
            dbgMat=cell(rows, cols);
            mx=QfHiDM.MAX_QF_DISTANCE;%realmax;%highest value to not select QF]
            for row=1:rows
                if nargin>5 && transpose  && row~=only
                    matrix(row,:)=mx;%realmax;%highest value to not select QF
                    continue;
                end
                if sIsCell
                    sIdSet=sIdSets{row};
                else
                    sIdSet=sIdSets(row);
                end
                for col=1:cols
                    if this.isIdentityMatrix
                        if col==row
                            if col>1 %need tSz(col) calculated
                                this.increment;
                                continue;
                            end
                        elseif col<row
                            this.increment;
                            matrix(row, col)=matrix(col, row);
                            continue;
                        end
                    end
                    if nargin>5 && ~transpose && col~=only 
                        matrix(row,col)=mx;
                        continue;
                    end
                    if tIsCell
                        tIdSet=tIdSets{col};
                    else
                        tIdSet=tIdSets(col);
                    end
                    doQf=true;
                    if this.preCheckDeviations && nargin<6 
                        devUnits=feval(this.devFcn, this.tDevData, this.sDevData, ...
                            this.tIdPerRow, tIdSet, this.sIdPerRow, sIdSet);
                        if ~isempty(devUnits)
                            deviants=sum(devUnits>this.devMax);
                            if isempty(this.isScatter)
                                stainDeviants=sum(devUnits>=this.devMax & ...
                                    this.devMax>=3);
                            else
                                stainDeviants=sum(devUnits>=this.devMax & ...
                                    ~this.isScatter);
                            end
                            if deviants>this.maxDeviantParameters
                                doQf=false;
                                tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSet);
                                tSzs(col)=sum(tChoices);
                                matrix(row,col)=mx+deviants;
                            end
                            this.stainDevUnitsExceeded=...
                                this.stainDevUnitsExceeded+stainDeviants;
                            this.scatterDevUnitsExceeded=...
                                this.scatterDevUnitsExceeded+(deviants-stainDeviants);
                            if deviants>0
                                this.forbiddenByDevUnits=...
                                    this.forbiddenByDevUnits+1;
                            end
                        end
                    end
                    if doQf
                        [matrix(row,col), tSzs(col), dbgMat{row, col}]=...
                            this.distance(sIdSet, tIdSet);
                    end
                    this.increment;
                    if this.isCancelled
                        return;
                    end
                end
            end
            if ~isempty(this.debugTxt)
                if isempty(this.leafSzs)
                    this.leafSzs=tSzs;
                end
                tLbls=this.getLabels(tIdSets);
                sLbls=this.getLabels(sIdSets);
                if this.debugLevel<=0
                    matHtml=['<h3>' txt '</h3>' ...
                        MatBasics.ToHtml(matrix, tLbls, sLbls, [], 100, 4)];
                    this.debugTxt=[this.debugTxt matHtml];
                else
                    isIdMat=isequal(sIdSets, tIdSets);
                    dh=['<table><tr><td><h2>' txt '</h2></td><td><h2>QF ' ...
                        'calculation details for ' txt '</td><td>'...
                        '</h2></tr><tr><td><hr>' ...
                        MatBasics.ToHtml(matrix, tLbls, sLbls, [], 100, 4)...
                        '</td><td><hr><table border="1"><tr><td></td>'];
                    for col=1:cols
                        dh=[dh '<td><font color="blue">' tLbls{col} '</font></td>'];
                    end
                    dh=[dh '</tr>'];
                    for row=1:rows
                        dh=[dh '<tr><td><font color="blue">' sLbls{row} '</font></td>'];
                        for col=1:cols
                            if ~isIdMat || col>row
                                dh=[dh '<td>' dbgMat{row,col} '</td>'];
                            else
                                dh=[dh '<td></td>'];
                            end
                        end
                        dh=[dh '</tr>'];
                    end
                    dh=[dh '</table></td></tr></table>'];
                    this.debugTxt=[this.debugTxt '</table></td></tr></table>'];
                    this.debugTxt=[this.debugTxt dh];
                end
            end
        end 
        
        function [f, overlap]=fMeasureInBins(this, tIdSet, sIdSet)
            tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSet);
            sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSet);
            [f, overlap]=this.adaptiveBins.fMeasure(tChoices, sChoices);
        end
        
        function [D, tSz, html]=distance(this, sIdSet, tIdSet)
            html='';
            tt=tic;
            tChoices=MatBasics.LookForIds(this.tIdPerRow, tIdSet);
            tSz=sum(tChoices);
            sChoices=MatBasics.LookForIds(this.sIdPerRow, sIdSet);
            if ~isempty(this.distanceType) && ...
                    ~isequal('QF', this.distanceType) ...
                    && ~isequal('QF + Euclidean', this.distanceType) ...
                    && ~isequal('QF + CityBlock', this.distanceType) 
                tData_=this.tData(tChoices, :);
                sData_=this.sData(sChoices, :);
                if isequal(this.distanceType, 'Fast EMD')
                    D=AdaptiveBins.Emd(tData_, sData_, 7);
                    %fprintf('EMD=%s\n', String.encodeRounded(D));
                elseif isequal(this.distanceType, 'Earth mover''s (EMD)')
                    D=AdaptiveBins.Emd(tData_, sData_);
                else
                    D=pdist2(median(tData_), median(sData_), this.distanceType,...
                        'Smallest', 1);
                end
                return;
            end
            if this.debugLevel>0
                if length(sIdSet)>1 || length(tIdSet)>1
                    fprintf('counts t=%s (ids: %s) and  s=%s (ids: %s)', ...
                        String.encodeInteger( sum(tChoices)), num2str(tIdSet'), ...
                        String.encodeInteger(sum(sChoices)), num2str(sIdSet'));
                    fprintf('\n');
                else
                    fprintf('counts t=%s (ids: %s) and  s=%s (ids: %s)\n', ...
                        String.encodeInteger( sum(tChoices)), num2str(tIdSet), ...
                        String.encodeInteger(sum(sChoices)), num2str(sIdSet));
                end
            end
            isMeans=true;
            if this.binStrategy==1
                tData_=this.tData(tChoices, :);
                sData_=this.sData(sChoices, :);
                if nargin>2 && this.bins>3
                    [meansOrDists, ~, ~, h, f]=AdaptiveBins.Create(tData_, sData_, this.bins, true);
                else
                    if this.bins<=-9
                        [meansOrDists, ~, ~, h, f]=AdaptiveBins.Create(...
                            tData_, sData_, this.sizeLimit);
                    else %use 2*log of size of merged data
                        [meansOrDists, ~, ~, h, f]=AdaptiveBins.Create(tData_, sData_);
                    end
                end
            else
                weighBySampleSize=this.binStrategy<0;
                [meansOrDists, h, f]=this.adaptiveBins.weigh(...
                    tChoices, sChoices, weighBySampleSize);
                isMeans=isempty(this.adaptiveBins.dists);
            end
            if this.debugLevel<=0
                D=QfHiDM.Distance(h, f, meansOrDists, isMeans, this.ignoreTooBig);
            elseif ~isequal(tIdSet, sIdSet)
                [D, d_max, A_IJ]=QfHiDM.Distance(h, f, meansOrDists, isMeans, this.ignoreTooBig);
                hPtrs=this.adaptiveBins.teachPtrs(tChoices);
                fPtrs=this.adaptiveBins.studPtrs(sChoices);
                uPtrs=unique([hPtrs fPtrs]);
                colHdrs=StringArray.Num2Str(uPtrs);
                distHtml=Html.Matrix([],colHdrs, meansOrDists);
                aijHtml=Html.Matrix([], colHdrs, A_IJ);
                data_=[h;f];
                tLbls=this.getLabels(tIdSet);
                sLbls=this.getLabels(sIdSet);
                hfHtml=Html.Matrix({['H: ' StringArray.toString(tLbls)],...
                    ['F: ' StringArray.toString(sLbls) ]}, colHdrs, data_);
                html=['<table><tr><td colspan="2" align="center">'...
                    '<h3>QF dissimilarity ' String.encodeRounded(D, 3, true)...
                    '</h3><hr></td></tr><tr><td colspan="2" align="center">' ...
                    hfHtml '</td></tr><tr><td colspan="2" align="center">' ...
                    String.encodeRounded(d_max,3,true) ...
                    ' max distance</td></tr>'...
                    '<tr><td>Distances<br>' distHtml ...
                    '</td><td>A_IJ<br>' aijHtml '</td></tr></table>'];
            else
                D=0;
            end
            if QfHiDM.DEBUG_LEVEL>0
                fprintf(['   QF dist, %d & %d %dD items, total bins=%d, ' ...
                    'bins/weights=%s/%s & %s/%s\n'],...
                    sum(tChoices), sum(sChoices), size(meansOrDists,2), ...
                    size(meansOrDists,1), num2str(max(h)), num2str(sum(h>0)),...
                    num2str(max(f)), num2str(sum(f>0)));
                toc(tt);
            end
        end        
        
        function ok=isCancelled(this)
            if ~isempty(this.pu)
                drawnow;
                ok=this.pu.cancelled;
                if ok
                    this.pu.setText('Quitting....');
                end
            else
                ok=false;
            end
        end
        
        function focusPriorFig(this)
            if ~isempty(this.pu)
                if ~isempty(this.pu.priorFig)
                    figure(this.pu.priorFig);
                end
            end
        end
        
        function setText(this, txt, line2)
            if ~isempty(this.pu)
                if nargin==2 || ~line2
                    this.pu.setText(txt);
                else
                    this.pu.setText2(txt);
                end
            end
        end
        
        function initProgress(this, N)
            if ~isempty(this.pu)
                this.pu.initProgress(N, char(this.pu.label.getText));
            end            
        end
        
        function increment(this)
            if ~isempty(this.pu)
                this.pu.incrementProgress(1);
            end
        end
        
        function fcn=devFcn(this)
            %fcn=@MatBasics.GetMeanUnits;
            %fcn=@MatBasics.GetMdnUnits;
            if this.devType==3
                fcn=@MatBasics.GetMad1DevUnits;
            elseif this.devType==2
                fcn=@MatBasics.GetStdDevUnits;
            else
                fcn=@MatBasics.GetMadDevUnits;
            end
        end
        
    end
    
    methods(Static, Access=private)
        
        
        function strings=ToCellStrings(nums)
            N=length(nums);
            strings=cell(1, N);
            for i=1:N
                strings{i}=num2str(nums(i));
            end
        end
        
        function [ids, unMergedIdxs]=GetIds(i, unmerged, merged)
            if i>length(unmerged)
                i=i-length(unmerged);
                ids=merged{i};
                if nargout>1
                    N=length(ids);
                    unMergedIdxs=zeros(1,N);
                    for i=1:N
                        unMergedIdxs(i)=find(unmerged==ids(i), 1);
                    end
                end
            else
                unMergedIdxs=i;
                ids=unmerged(i);
            end
        end
        
        function out=ToCell(nums)
            N=length(nums);
            out=cell(1, N);
            for i=1:N
                out{i}=nums(i);
            end
        end
        
        function ids=ToIds(idxs, singleIds)
            N=length(idxs);
            ids=cell(1, N);
            for i=1:N
                ids{i}=singleIds(idxs{i});
            end
        end
    end
    
    
    methods(Access=private)
        function ok=checkSpeedUp(this, unmergedScores)
            ok=true;
            if ~isempty(this.tGt)
                app=this.tGt.multiProps;
            else
                app=BasicMap.Global;
            end
            this.mergeLimit=0;
            if isempty(app)
                isPausing=false;
            else
                isPausing=app.is(QfHiDM.PROP_MERGE_PAUSE, false);
                mergeLimitIdx=app.getNumeric(QfHiDM.PROP_MERGE_LIMIT, 1);
                if mergeLimitIdx>1 % unlimited
                    this.mergeLimit=5+mergeLimitIdx;
                end
            end
            if isPausing
                this.computeMergeCost(unmergedScores);
                if this.mergeLimit>0
                    if any(this.sMergeCnts>this.mergeLimit) || ...
                        any(this.tMergeCnts>this.mergeLimit)
                        [~, cancelled_]=AvoidMerging.Adjust(this);
                        if cancelled_
                            ok=false;
                        end
                    end
                end
            end
        end
        
        function computeMergeCost(this, matrix)
            if this.mergeStrategy~=1
                perc=QfHiDM.MergeStrategyPerc(this.mergeStrategy);
                [~, cntPerCol]=FindMerges(matrix, true, perc);
                this.sMergeCnts=cntPerCol;
                [~, cntPerCol]=FindMerges(matrix, false, perc);
                this.tMergeCnts=cntPerCol;
            else
                [~, cntPerCol]=...
                    QfHiDM.FindMinRowsForCol(matrix, true);
                this.sMergeCnts=cntPerCol;
                [~, cntPerCol]=...
                    QfHiDM.FindMinRowsForCol(matrix, false);
                this.tMergeCnts=cntPerCol;
            end
        end
        
        function [mergersPerCol, mergeColIdxs]=getMergers(this, matrix, ...
                transpose)
            if this.mergeStrategy~=1
                perc=QfHiDM.MergeStrategyPerc(this.mergeStrategy);
                if transpose
                    [rowsToMergePerCol, cntPerCol]=FindMerges(matrix, ...
                        transpose, perc, this.sAvoidMerges);
                    this.sMergeCnts=cntPerCol;
                else
                    [rowsToMergePerCol, cntPerCol]=FindMerges(matrix, ...
                        transpose, perc, this.tAvoidMerges);
                    this.tMergeCnts=cntPerCol;
                end
            else
                if transpose
                    [rowsToMergePerCol, cntPerCol]=...
                        QfHiDM.FindMinRowsForCol(...
                        matrix, transpose, this.sAvoidMerges);
                    this.sMergeCnts=cntPerCol;
                else
                    [rowsToMergePerCol, cntPerCol]=...
                        QfHiDM.FindMinRowsForCol(...
                        matrix, transpose, this.tAvoidMerges);
                    this.tMergeCnts=cntPerCol;
                end
            end
            mergers=rowsToMergePerCol(cntPerCol>1);
            mergeColIdxs=find(cntPerCol>1);
            mergersPerCol={};
            N=length(mergers);
            if N>0
                if ~this.avoidedMerging && max(cntPerCol)>8
                    this.pu.cancelBtn.setText(...
                        '<html>Cancel <b><i>or speed up</i></b></html>');
                    drawnow;
                end
                this.setText('Computing mergers', true);
                this.initProgress(sum(cntPerCol(cntPerCol>1)));
                mergers_={};
                mergeColIdxs_=[];
                md=mad(matrix(:));
                for i=1:N
                    merger=mergers{i};
                    col=mergeColIdxs(i);
                    N2=length(merger);
                    ols=[];
                    scores=[];
                    ol=0;
                    merger_=[];
                    for j=1:N2
                        this.increment;
                        row=merger(j);
                        if ~transpose
                            sIdSet=QfHiDM.ToIds({row}, this.sIds);
                            sIdSet=sIdSet{1};
                            tIdSet=this.tIds(col);
                            best=min(matrix(:, col));
                            qf=matrix(row, col);
                            if qf>=QfHiDM.MAX_QF_DISTANCE
                                continue;
                            end
                            if this.preCheckDeviations 
                                devUnits=feval(this.devFcn, this.tDevData,...
                                    this.sDevData, this.tIdPerRow, ...
                                    tIdSet, this.sIdPerRow, sIdSet);
                                
                            end
                            if this.areEqual && this.mergeLimit>0
                                ol=MatBasics.Overlap(this.tCompData, ...
                                    this.sCompData, this.tIdPerRow, tIdSet, ...
                                    this.sIdPerRow, sIdSet, this.areEqual);
                            end
                        else
                            tIdSet=QfHiDM.ToIds({row}, this.tIds);
                            tIdSet=tIdSet{1};
                            sIdSet=this.sIds(col);
                            best=min(matrix(col, :));
                            qf=matrix(col, row);
                            if qf>=QfHiDM.MAX_QF_DISTANCE
                                continue;
                            end
                            if this.preCheckDeviations
                                devUnits=feval(this.devFcn, ...
                                    this.sDevData, this.tDevData, ...
                                    this.sIdPerRow, sIdSet, ...
                                    this.tIdPerRow, tIdSet);                                
                            end
                            if this.areEqual && this.mergeLimit>0
                                ol=MatBasics.Overlap(this.sCompData, ...
                                    this.tCompData, this.sIdPerRow, sIdSet, ...
                                    this.tIdPerRow, tIdSet, this.areEqual);
                            end
                        end
                        dif=abs(qf-best);
                        if this.preCheckDeviations && ~isempty(devUnits)...
                                && sum(devUnits>this.devMax)>...
                                this.maxDeviantParameters
                            fprintf(...
                                '%d dimensions exceed max mad units\n', ...
                                sum(devUnits>this.devMax))
                        
                        else
                            merger_(end+1)=row;
                            if this.areEqual
                                ols(end+1)=ol;
                            else
                                ols(end+1)=QfHiDM.MAX_QF_DISTANCE-qf;
                            end
                            scores(end+1)=qf;
                            if dif>=md*QfHiDM.DEV_MAX
                                if md>0 && this.preCheckDeviations
                                    fprintf(['QF %s more than %d mad (%s) units '...
                                        ' away from %s\n'], String.encodeRounded(qf,2), ...
                                        QfHiDM.DEV_MAX, String.encodeRounded(md,3), ...
                                        String.encodeRounded(best,3));
                                end
                            end
                        end                        
                    end
                    if length(merger_)>1
                        if this.mergeLimit>0
                            if length(ols)>this.mergeLimit
                                [~,yy]=sort(ols, 'descend');
                                merger_=merger_(yy(1:this.mergeLimit));
                            end
                        end
                        mergers_{end+1}=merger_;
                        mergeColIdxs_(end+1)=mergeColIdxs(i);
                    end
                end
                mergers=mergers_;
                mergeColIdxs=mergeColIdxs_;
                N=length(mergers);
                this.setText('Gathering mergers', true);
                this.initProgress(N);
                totalMerges=0;
                for i=1:N
                    merger=mergers{i};
                    nMerger=length(merger);
                    lastComboSize=nMerger-1;
                    if this.maxMerges>0 && lastComboSize>this.maxMerges
                        lastComboSize=this.maxMerges;
                    end
                    for comboSize=2:lastComboSize
                        totalMerges=totalMerges+nchoosek(nMerger, comboSize);
                    end
                end
                strTotal=sprintf('%s total mergers', String.encodeK(totalMerges));
                this.setText(strTotal, true);
                for i=1:N
                    nextMergers={};
                    merger=mergers{i};
                    nMerger=length(merger);
                    lastComboSize=nMerger-1;
                    if this.maxMerges>0 && lastComboSize>this.maxMerges
                        lastComboSize=this.maxMerges;
                    end
                    subTotalMerges=0;
                    for comboSize=2:lastComboSize
                        subTotalMerges=subTotalMerges+nchoosek(nMerger, comboSize);
                    end
                    str_=sprintf('Subset #%d/%d, %d candidates, %s/%s',...
                        i, N, nMerger, String.encodeK(subTotalMerges), strTotal);
                    this.setText(str_, true);
                    for comboSize=2:lastComboSize
                        combos=nchoosek(merger, comboSize);
                        nCombos=length(combos);
                        if lastComboSize>18
                            this.setText(sprintf('%s-->%s combos of %d',...
                                str_, String.encodeK(nCombos), comboSize), true);
                            if this.isCancelled
                                return;
                            end
                        end
                        nextMergers=[nextMergers;num2cell(combos,2)];
                    end
                    this.increment;
                    mergersPerCol{end+1}=[merger nextMergers'];
                end
            end
        end
    end
    
    methods(Static)
        function str=MatchStrategyString(strategy)
            if ischar(strategy)
                strategy=str2double(strategy);
            end
            if strategy==2
                str='F';
            else
                if strategy==1
                    str='QF';
                else
                    str='QFxF';
                end
            end
        end
        
        function str=MergeStrategyString(mergeStrategy)
            if ischar(mergeStrategy)
                mergeStrategy=str2double(mergeStrategy);
            end
            perc=QfHiDM.MergeStrategyPerc(mergeStrategy);
            if perc == 1
                str='best';
            else
                str=['best + top ' num2str(perc) ' * N'];
            end
        end
        
        function perc=MergeStrategyPerc(mergeStrategy)
            if ischar(mergeStrategy)
               mergeStrategy=str2double(mergeStrategy);
            end
            perc=1+((mergeStrategy-1)*.5);
        end
        
        function [rowsThatAreMinForCol, cntMinForCol, isMinRowForColMinColForRow]=...
                FindMinRowsForCol(matrix, transpose, avoidMerges)
            if nargin<3
                avoidMerges=[];
            end
            if nargin>1 && transpose
                dimRow=2;
                dimCol=1;
            else
                dimRow=1;
                dimCol=2;
            end
            cols=size(matrix, dimCol);
            cntMinForCol=zeros(1, cols);
            rowsThatAreMinForCol=cell(1, cols);
            isMinRowForColMinColForRow=false(1, cols);
            [~, minColForRow]=min(matrix, [], dimCol);
            [~, minRowForCol]=min(matrix, [], dimRow);
            for col=1:cols
                if ~isempty(avoidMerges) && avoidMerges(col)
                    continue;
                end
                minRows=find(minColForRow==col);
                if transpose
                    l=matrix(col, minRows)>=QfHiDM.MAX_QF_DISTANCE;
                else
                    l=matrix(minRows, col)>=QfHiDM.MAX_QF_DISTANCE;
                end
                if sum(l)>0
                    minRows=minRows(~l);
                end
                cntMinForCol(col)=length(minRows);
                isMinRowForColMinColForRow(col)=ismember(...
                    minRowForCol(col), minRows);
                rowsThatAreMinForCol{col}=minRows;
            end
        end
        
        function [D, d_max, A_IJ]=Distance(h, f, meansOrDists, isMeans, ignoreTooBig)
            try
                if nargin<4 || isMeans
                    R=size(meansOrDists, 1);
                    if R>AdaptiveBins.MAX_SIZE
                        if nargin<5 || ~ignoreTooBig
                            D=QuadraticForm.ComputeFastHiD(h, f, meansOrDists);
                            if isnan(D)
                                D=QfHiDM.MAX_QF_DISTANCE;%close to max QF distance
                            end
                        else
                            D=QfHiDM.MAX_QF_DISTANCE;
                        end
                        return;
                    end
                    originalMeans=meansOrDists;
                    meansOrDists=MatBasics.PDist2Self(meansOrDists);
                end
                d_max=max(max(meansOrDists));
                A_IJ=1-meansOrDists/d_max;
                [H, F]=meshgrid(h-f, h-f);
                D=sqrt(sum(sum(A_IJ.*H.*F)));
            catch ex
                if nargin<4 || isMeans
                    D=QuadraticForm.ComputeFastHiD(h, f, originalMeans);
                end
            end
            if isnan(D)
                D=QfHiDM.MAX_QF_DISTANCE;%close to max QF distance
            end
        end
        
        function value=IdValue(ids)
            value='';
            N=length(ids);
            if iscell(ids)
                for i=1:N
                    if i>1
                        value=[value ', ' ids{i}];
                    else
                        value=[ids{i}];
                    end
                end
            else
                for i=1:N
                    if i>1
                        value=[value ', ' ids(i)];
                    else
                        value=[ids(i)];
                    end
                end
            end
        end
        
        function [teachData, studData]=Data(columnNames, ...
                teachData, teachColNames, teachColIdxs, studData, ...
                studColNames, studColIdxs)
            teachData=QfHiDM.GetRequiredData(teachData, columnNames, ...
                teachColNames, teachColIdxs);
            studData=QfHiDM.GetRequiredData(studData, columnNames, ...
                studColNames, studColIdxs);
            teachData=QfHiDM.Log10(teachData);
            studData=QfHiDM.Log10(studData);
        end
        
        function this=New(teachData, teachCompData, teachIds, studData, ...
                studCompData, studIds, bins, binStrategy, columnNames, ...
                teachColNames, teachColIdxs, studColNames, studColIdxs, ...
                teachStudCacheFile, studTeachCacheFile)
            if nargin<15
                studTeachCacheFile=[];
                if nargin<14
                    teachStudCacheFile=[];
                    if nargin<9
                        columnNames=[];
                        if nargin<8
                            binStrategy=QfHiDM.BIN_STRATEGY;
                            if nargin<7
                                bins=QfHiDM.BINS;
                            end
                        end
                    end
                end
            end
            if ~isempty(columnNames)
                % same data may be in different columns of this and that data
                columnNames=QfHiDM.RemoveMissingColumns(columnNames, ...
                    teachColNames, teachColIdxs);
                columnNames=QfHiDM.RemoveMissingColumns(columnNames, ...
                    studColNames, studColIdxs);
                teachData=QfHiDM.GetRequiredData(teachData, columnNames, ...
                    teachColNames, teachColIdxs);
                if ~isempty(teachCompData)
                    teachCompData=QfHiDM.GetRequiredData(teachCompData, ...
                        columnNames, teachColNames, teachColIdxs);
                end
                studData=QfHiDM.GetRequiredData(studData, columnNames, ...
                    studColNames, studColIdxs); 
                if ~isempty(studCompData)
                    studCompData=QfHiDM.GetRequiredData(studCompData, ...
                        columnNames, studColNames, studColIdxs);
                end
            end            
            teachData=QfHiDM.Log10(teachData);
            nCols=size(teachData,2);
            devMax=zeros(1, nCols)+QfHiDM.DEV_MAX;
            isScatter=false(1, nCols);
            for i=1:nCols
                if String.StartsWithI(columnNames{i}, 'FSC-') ...
                        || String.StartsWithI(columnNames{i}, 'SSC-')
                    devMax(i)=QfHiDM.DEV_MAX_LOG10;
                    isScatter(i)=true;
                end
            end
            studData=QfHiDM.Log10(studData);
            if ~isempty(teachCompData)
                assert(isequal(size(teachData), size(teachCompData)));
            end
            if ~isempty(studCompData)
                assert(isequal(size(studData), size(studCompData)));
            end
            this=QfHiDM(teachData, teachCompData, teachIds, studData, ...
                studCompData, studIds, bins, binStrategy, ...
                teachStudCacheFile, studTeachCacheFile, devMax, isScatter);
            if nargin>8
                this.columnNames=columnNames;
            end
        end
        
        function [outData, scatterColumns]=Log10(inData, whichRows, ...
                scatterColumns, divisor)
            if nargin<4
                divisor=2.5;
                if nargin<3
                    scatterColumns=[];
                    if nargin<2
                        whichRows=[];
                    end
                end
            end
            if isempty(whichRows)
                whichRows=true(1, size(inData,1));
            end
            outData=inData(whichRows, :);
            if isempty(scatterColumns)
                maxInData=max(inData);
                
                %since logicle can be < 0 and > 11
                LIKELY_LOGICLE_UPPER_LIMIT=100;
                if any(maxInData>LIKELY_LOGICLE_UPPER_LIMIT)
                    scatterColumns=find(maxInData>LIKELY_LOGICLE_UPPER_LIMIT);
                    nScatterColumns=length(scatterColumns);
                    for k=1:nScatterColumns
                        handleLog10InfOrComplex(scatterColumns(k));
                    end
                end
                if length(scatterColumns)==length(maxInData)
                    return;
                end
            end
            if ~isempty(scatterColumns)
                outData(:,scatterColumns)=log10(outData(:,scatterColumns))/divisor;
            end
            
            function handleLog10InfOrComplex(scatCol)
                %log10 converts 0s to inf and negatives to complex
                %thus 0s and negs must be re-fit BELOW the lowest unconverted 
                %number between 0 and 1 or re-fit between .01 and 1
                %BEFORE log10 conversion
                nonRealIndex=inData(:, scatCol)<=0;
                if any(nonRealIndex)
                    nonReal=outData(nonRealIndex, scatCol);
                    maxNonReal=max(nonReal);
                    sum(nonRealIndex) %display count to console
                    real=outData(~nonRealIndex, scatCol);
                    minNegLog10=min(real(real<=1));
                    if isempty(minNegLog10)
                        if maxNonReal==0
                            maxRefit=1; % log10 of 1 is 0
                        else
                            maxRefit=.99;
                        end
                        minRefit=0.01;
                    else
                        maxRefit=.99*minNegLog10;
                        minRefit=.01*minNegLog10;
                    end
                    refitRegion=maxRefit-minRefit;
                    minNonReal=min(nonReal);
                    nonRealRange=maxNonReal-minNonReal;
                    if  nonRealRange==0
                        nonRealRatio=.5;
                    else
                        nonRealRatio=(nonReal-minNonReal)/nonRealRange;
                    end
                    nonRealAdjusted=minRefit+(nonRealRatio*refitRegion);
                    outData(nonRealIndex, scatCol)=nonRealAdjusted;
                end
            end
        end

        function data=GetRequiredData(data, requiredColumnNames, ...
                dataColumnNames, dataColumnIdxs)
            requiredColumnIdxs=QfHiDM.GetRequiredColumns(...
                requiredColumnNames, dataColumnNames, dataColumnIdxs);
            data=data(:,requiredColumnIdxs);
        end
        
        function requiredColumnIdxs=GetRequiredColumns( ...
                requiredColumnNames, dataColumnNames, dataColumnIdxs)
            N=length(requiredColumnNames);
            requiredColumnIdxs=[];
            for i=1:N
                idx=StringArray.IndexOf(dataColumnNames, ...
                    requiredColumnNames{i});
                if idx>0
                    requiredColumnIdxs(end+1)=dataColumnIdxs(idx);
                end
            end
        end

        function [out, missing]=RemoveMissingColumns( ...
                requiredColumnNames, dataColumnNames, dataColumnIdxs)
            N=length(requiredColumnNames);
            missing={};
            out={};
            for i=1:N
                name=requiredColumnNames{i};
                idx=StringArray.IndexOf(dataColumnNames, name);
                if idx<1
                    missing{end+1}=name;
                else
                    out{end+1}=name;
                end
            end
        end
        
        function D=Match(teachData, studData, bins, ...
                columnNames, thisColumnNames, ...
                thisColumnIdxs, thatColumnNames, thatColumnIdxs)
            if nargin<3
                bins=[];
            end
            if nargin>3 
                % same data may be in different columns of this and that data
                teachData=QfHiDM.GetRequiredData(teachData, columnNames, ...
                    thisColumnNames, thisColumnIdxs);
                studData=QfHiDM.GetRequiredData(studData, columnNames, ...
                    thatColumnNames, thatColumnIdxs);
            end
            teachData=QfHiDM.Log10(teachData);
            studData=QfHiDM.Log10(studData);
            if bins<-9
                mn=min([size(teachData,1) size(studData,1)]);
                if mn>=30
                    perc=abs(bins)/100;
                    sizeLimit=floor(mn*perc);
                    [means, ~, ~, h, f]=AdaptiveBins.Create(teachData, ...
                        studData, sizeLimit);
                else
                    [means, ~, ~, h, f]=AdaptiveBins.Create(...
                        teachData, studData);
                end
            elseif isempty(bins) || bins<4
                [means, ~, ~, h, f]=AdaptiveBins.Create(teachData, studData);
            else
                [means, ~, ~, h, f]=AdaptiveBins.Create(teachData, ...
                    studData, bins);
            end
            D=QfHiDM.Distance(h, f, means);
            if isnan(D)
                D=QfHiDM.MAX_QF_DISTANCE;%max distance;
            end
        end
        function lvl=DEBUG_LEVEL
            lvl=0;
            %lvl=1;
        end
        
        function names=GetDescriptions(qf, gtp, doStud)
            if nargin>2 && doStud
                ids=qf.sIds;
            else
                ids=qf.tIds;
            end
            names=cell(1, length(ids));
            for i=1:length(names)
                gid=num2str(ids(i));
                names{i}=gtp.getDescription(gid);
            end
        end

        
        function names=GetNames(qf, gtp)
            names=cell(1, length(qf.tIds));
            for i=1:length(names)
                gid=num2str(qf.tIds(i));
                names{i}=gtp.getNode(gid, MatchInfo.PROP_LAST_NAME);
                if isempty(names{i})
                    names{i}=gtp.getDescription(gid);
                end
            end
        end
        
        function [colors, edgeColors, lineWidths]=GetColors(qf, gtp)
            N=length(qf.tIds);
            colors=zeros(N, 3);
            edgeColors=zeros(N, 3);
            lineWidths=zeros(1, N);
            for i=1:N
                gid=num2str(qf.tIds(i));
                clr=str2num(gtp.getNode(gid, MatchInfo.PROP_LAST_COLOR));
                if ~isempty(clr)
                    colors(i,:)=clr;
                end
                e=str2num(gtp.getNode(gid, MatchInfo.PROP_LAST_EDGE));
                if ~isempty(clr)
                    edgeColors(i,:)=e(1:3);
                    lineWidths(i)=e(4);
                end
            end
        end
        
        function QF=TreeData(qf)
            QF.tIds=qf.tIds;
            QF.numLeaves=qf.numLeaves;
            QF.branchNames=qf.branchNames;
            QF.branchQfs=qf.branchQfs;
            QF.treeSz=qf.treeSz;
            QF.phyTree=qf.phyTree;
            QF.nodeQfs=qf.nodeQfs;
            QF.nodeSzs=qf.nodeSzs;
            QF.columnNames=qf.columnNames;
            QF.distanceType=qf.distanceType;
            QF.measurements=qf.measurements;
            QF.rawMeasurements=qf.rawMeasurements;
        end
        
    end
end