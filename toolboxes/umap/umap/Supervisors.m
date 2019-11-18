%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%
classdef Supervisors < handle
    properties(Constant)
        DEV_UNIT_LIMIT=4;
        BORDER_DEV_UNIT_LIMIT=.2;
        VERBOSE=false;
        COLOR_NEW_SUBSET=[153 153 179];
    end
    
    properties
        density;
        embedding;
    end
    
    properties(SetAccess=private)
        ids;
        labelMap;
        mdns;
        mads;
        means;
        stds;
        cnts;
        N;
        xLimit;
        yLimit;
        labels;
        qfLabels;
        qfClusterNames;
        qfClusterColors;
        qfClusterMdns;
        qfClusterLabels;
    end
    
    methods
        function this=Supervisors(labels, labelMap, embedding, ax)
            this.labelMap=labelMap;
            this.ids=unique(labels);
            this.labels=labels;
            N=length(this.ids);
            this.cnts=zeros(N,1);
            this.mdns=zeros(N,2);
            this.means=zeros(N,2);
            this.mads=zeros(N,2);
            this.stds=zeros(N,2);
            for i=1:N
                id=this.ids(i);
                l=labels==id;
                this.cnts(i)=sum(l);
                this.mdns(i,:)=median(embedding(l,:));
                this.mads(i,:)=mad(embedding(l,:),1);
                this.means(i,:)=mean(embedding(l,:));
                this.stds(i,:)=std(embedding(l,:),1);
            end
            this.N=N;
            if nargin<4 || isempty(ax) || ~ishandle(ax)
                mx=max(embedding);
                mn=min(embedding);
                this.xLimit=[mn(1) mx(1)];
                this.yLimit=[mn(2) mx(2)];
            else
                this.xLimit=xlim(ax);
                this.yLimit=ylim(ax);
            end
            this.embedding=embedding;
        end
        
        function qf=clearQf(this)
            qf.qfLabels=this.qfLabels;
            qf.qfClusterNames=this.qfClusterNames;
            qf.qfClusterColors=this.qfClusterColors;
            qf.qfClusterMdns=this.qfClusterMdns;
            qf.qfClusterLabels=this.qfClusterLabels;
            this.qfLabels=[];
            this.qfClusterNames={};
            this.qfClusterColors={};
            this.qfClusterMdns=[];
            this.qfClusterLabels={};
        end
        
        function qf=restoreQf(this, qf)
            this.qfLabels=qf.qfLabels;
            this.qfClusterNames=qf.qfClusterNames;
            this.qfClusterColors=qf.qfClusterColors;
            this.qfClusterMdns=qf.qfClusterMdns;
            this.qfClusterLabels=qf.qfClusterLabels;
        end

        function [name, color, label]=getNameByMedian(this, mdn)
            [~, iMeHearty]=pdist2(this.density.clusterMdns, mdn, ...
                'euclidean', 'smallest', 1);
            name=this.density.clusterNames{iMeHearty};
            color=this.density.clusterColors{iMeHearty};
            label=this.density.clusterLabels{iMeHearty};
        end        
    end
    
    methods(Static)
        function [mins, maxs]=GetMinsMaxs(data)
            [mins, maxs]=MatBasics.GetMinsMaxs(data, .15);
        end
        
        function [density, numClusts, clustIds]=Cluster(data)
            [mins, maxs]=Supervisors.GetMinsMaxs(data);
            [numClusts, clustIds, density]=Density.ClusterVeryHigh(...
                data, mins, maxs);
        end
    end
    
    methods
        function [names, lbls]=getQfTraining(this)
            names={};
            lbls=this.labels;
            N_=length(this.ids);
            for i=1:N_
                id=this.ids(i);
                if id>0
                    if this.cnts(i)>=20
                        key=num2str(id);
                        names{end+1}=this.labelMap.get(key);
                    else
                        lbls(this.labels==id)=0;
                    end
                end
            end
        end
            
        function qfMatchWithClusters(this, data, density, ...
                numClusters, clusterIds)
            if nargin<3
                [density, numClusters, clusterIds]=Supervisors.Cluster(data);
            end
            this.density=density;
            [R,C]=size(clusterIds);
            if C>1 && R==1
                clusterIds=clusterIds';
            end
            [tNames, lbls]=this.getQfTraining;
            if isequal(data, this.embedding)
                matchStrategy=2;
            else
                matchStrategy=1;
            end
            result=run_HiD_match(this.embedding, ...
                lbls, data,...
                clusterIds, 'trainingNames', tNames, ...
                'matchStrategy', matchStrategy, ...
                'log10', false);
            [~,~,us, unmatchedClusters, clusterMatch]=result.getUnmatched;
            cluMdns=zeros(numClusters, 2);
            [tQ, sQ, tF, sF]=result.getScores;
            clusterLabels=cell(1,numClusters);
            clusterNames=cell(1,numClusters);
            clusterColors=cell(1,numClusters);
            newSubsets=0;
            labels_=zeros(size(data, 1), 1);
            for i=1:numClusters
                l=clusterIds==i;
                isNew=unmatchedClusters(i);
                if isNew
                    newSubsets=newSubsets+1;
                    clusterLabel=0-i;
                    clusterNames{i}=['New subset #' num2str(newSubsets) ];
                    clr=num2str(Supervisors.COLOR_NEW_SUBSET+newSubsets);
                else
                    clusterLabel=clusterMatch(i);
                    clusterNames{i}=this.labelMap.get(num2str(clusterLabel));
                    clr=this.labelMap.get([num2str(clusterLabel) '.color']);
                end
                clusterColors{i}=clr;
                clusterLabels{i}=clusterLabel;
                labels_(l)=clusterLabel;
                if Supervisors.VERBOSE
                    sum(l)
                end
                cluMdns(i,:)=median(data(l,:));
            end
            this.density.setLabels(labels_, clusterNames, ...
                clusterColors, cluMdns, clusterLabels);
            function d=normalize(d)
                mn=min(d);
                N_=length(mn);
                for j=1:N_
                    if mn(j)<=0
                        add_=1-mn(j);
                        d(:,j)=d(:,j)+add_;
                    end
                end
                for j=1:N_
                    mx_=max(d(:,j));
                    mn_=min(d(:,j));
                    r=mx_-mn_;
                    d(:,j)=(d(:,j)-mn_)/r;
                end
            end
        end
        
        function matchWithClusters(this, data, density, ...
                numClusters, clusterIds)
            this.density=density;
            clusterLabels=cell(1,numClusters);
            clusterNames=cell(1,numClusters);
            clusterColors=cell(1,numClusters);
            %[~,I]=pdist2(this.mdns, embedding, 'euclidean', 'smallest', 1);
            %labels2=this.ids(I);
            avgs=this.mdns;
            if isprop(this, 'mads')
                devs=this.mads;
            else
                devs=[];
            end
            if any(this.cnts<20)
                avgs(this.cnts<20, 1)=this.xLimit(2)*5;
                avgs(this.cnts<20, 2)=this.yLimit(2)*5;
            end
            cluMdns=zeros(numClusters, 2);
            cluDevs=zeros(numClusters, 2);
            for i=1:numClusters
                l=clusterIds==i;
                if Supervisors.VERBOSE
                    sum(l)
                end
                cluMdns(i,:)=median(data(l,:));
                cluDevs(i,:)=mad(data(l,:), 1);
            end
            hasDevs=~isempty(devs);
            [D, I]=pdist2(avgs, cluMdns, 'euclidean', 'smallest', 1);
            labels_=zeros(size(data, 1), 1);
            reChecks={};
            for i=1:numClusters
                labelIdx=I(i);
                label=this.ids(labelIdx);
                if label==0
                    label=0-i;
                else
                    key=num2str(label);
                    clusterLabels{i}=label;
                    clusterNames{i}=this.labelMap.get(key);
                    clusterColors{i}=this.labelMap.get([key '.color']);
                end
                l=clusterIds==i;
                if Supervisors.VERBOSE
                    sum(l)
                    this.labelMap.get(num2str(label))
                end
                if hasDevs
                    devDist=MatBasics.DevDist(cluMdns(i,:), cluDevs(i,:));
                    if any(D(i)>=devDist*Supervisors.DEV_UNIT_LIMIT)
                        reChecks{end+1}=struct('clustId', i, 'count',...
                            sum(l), 'label', label, 'labelIdx', labelIdx);
                        label=0-i;
                    end
                end
                labels_(l)=label;
            end
            if hasDevs
                N_=length(reChecks);
                while N_>0 
                    changes=[];
                    for i=1:N_
                        clustId=reChecks{i}.clustId;
                        label=reChecks{i}.label;
                        labelIdx=reChecks{i}.labelIdx;
                        closestLabelIdxs=labels_==label;
                        if Supervisors.VERBOSE
                            sum(closestLabelIdxs)
                            this.labelMap.get(num2str(label))
                            reChecks{i}
                        end
                        if any(closestLabelIdxs)
                            %Does this cluster with no label match
                            %   sit on the border of one with the 
                            %   closest label from the supervisor?
                            unlabeledClusterIdxs=clusterIds==clustId;
                            borderDistance=min(pdist2(...
                                data(unlabeledClusterIdxs, :), ...
                                data(closestLabelIdxs,:), 'euclidean', ...
                                'smallest', 1));
                            supervisorDevDistance=MatBasics.DevDist(...
                                avgs(labelIdx,:), devs(labelIdx,:));
                            limit=supervisorDevDistance*...
                                Supervisors.BORDER_DEV_UNIT_LIMIT;
                            if borderDistance<=limit
                                changes(end+1)=i;
                                labels_(unlabeledClusterIdxs)=label;
                            end
                        end
                    end
                    if isempty(changes)
                        break;
                    else
                        reChecks(changes)=[];
                    end
                    N_=length(reChecks);                    
                end
                newSubsetIds=unique(labels_(labels_<0));
                newSubsets=length(newSubsetIds);
                for i=1:newSubsets
                    clustId=0-newSubsetIds(i);
                    clusterLabels{clustId}=newSubsetIds(i);
                    clusterNames{clustId}=['New subset #' num2str(i)];
                    color_=Supervisors.COLOR_NEW_SUBSET+clustId;
                    if any(color_<0)
                        color_(color_<0)=0;
                    end
                    clusterColors{clustId}=num2str(color_);
                end
                N_=length(this.ids);
                remainder=data(labels_==0,:); 
                labels2=zeros(size(remainder,1),1);
                for i=1:N_
                    if ~any(find(labels_==this.ids(i),1))
                        label=this.ids(i);
                        if Supervisors.VERBOSE
                            this.labelMap.get(num2str(label))
                        end
                        [D2, I2]=pdist2(avgs(i,:), remainder, ...
                            'euclidean', 'smallest', 1);
                        pt=avgs(i,:)+devs(i,:);
                        devDist=pdist2(avgs(i,:), pt);
                        if any(D2<devDist*Supervisors.DEV_UNIT_LIMIT)
                            labels2(D2<devDist)=label;
                        end
                    end
                end
                if any(labels2)
                    labels_(labels_==0)=labels2;
                end
            else
                newSubsets=0;
            end
            this.density.setLabels(labels_, clusterNames, ...
                clusterColors, cluMdns, clusterLabels);
        end
        
        function updateDensity(this, data, density, ...
                numClusters, clusterIds, useQfMatch)
            if ~useQfMatch || isempty(this.qfLabels)
                this.matchWithClusters(data, density, numClusters, clusterIds);
            else
                this.density=density;
                density.setLabels(this.qfLabels, this.qfClusterNames,...
                    this.qfClusterColors, this.qfClusterMdns, this.qfClusterLabels);
            end
        end
        
        function [labels, labelMap]=supervise(this, data, ...
                computeClusters, doHtml, useQfMatch)
            if nargin<4
                doHtml=false;
            end
            labelMap=java.util.Properties;
            computeQfMatch=false;
            if nargin >4 && useQfMatch
                if ~isempty(this.embedding)
                    computeQfMatch=isempty(this.qfLabels);
                    if ~computeQfMatch     
                        labels=this.qfLabels;
                        doMap(this.qfClusterColors, this.qfClusterNames);
                        return;
                    end
                end
            end
            if computeClusters
                [dns, numClusters, clusterIds]=Supervisors.Cluster(data);
                if computeQfMatch
                    this.qfMatchWithClusters(data, dns, numClusters, clusterIds);
                else
                    this.matchWithClusters(data, dns, numClusters, ...
                        clusterIds);
                end
            end              
            labels=this.density.labels;
            doMap(this.density.clusterColors, this.density.clusterNames);
            if computeQfMatch
                this.qfLabels=labels;
                this.qfClusterNames=this.density.clusterNames;
                this.qfClusterColors=this.density.clusterColors;
                this.qfClusterMdns=this.density.clusterMdns;
                this.qfClusterLabels=this.density.clusterLabels;
            end
            
            function doMap(clusterColors, clusterNames)                
                ids_=unique(labels);
                N_=length(ids_);
                for i=1:N_
                    putInMap(ids_(i), clusterColors, clusterNames);
                end
            end
            
            function putInMap(id, clusterColors, clusterNames) 
                key=num2str(id);
                keyColor=[key '.color'];
                if id==0
                    if doHtml
                        name='<font color="62A162">unsupervised</font>';
                    else
                        name='\color[rgb]{0.4 0.65 0.4}\bf\itunsupervised';
                    end
                    color='92 92 128';
                elseif id<0
                    clustId=0-id;
                    nm=clusterNames{clustId};
                    if doHtml
                        name=['<font color="#4242BA"><i>' nm ' ?</i></font>'];
                    else
                        name=['\color[rgb]{0. 0.4 0.65}\bf\it' nm  ' ?'];
                    end
                    color=clusterColors(clustId);
                else
                    name=this.labelMap.get(key);
                    if doHtml
                        if String.Contains(name, '^{')
                            name=strrep(name, '^{', '<sup>');
                            name=strrep(name, '}', '</sup>');
                        end
                    end
                    color=this.labelMap.get(keyColor);
                end
                labelMap.put(java.lang.String(key), name);
                labelMap.put(keyColor, color);
            end
            
        end
        
        function drawClusterBorders(this, ax)
            wasHeld=ishold(ax);
            if ~wasHeld
                hold(ax, 'on');
            end
            N_=length(this.density.clusterColors);
            for i=1:N_
                clr=(str2num(this.density.clusterColors{i})/256)*.85;
                gridEdge(this.density, true, i, clr, ax, .8, '.', '-', .5);
                if Supervisors.VERBOSE
                    str2num(this.density.clusterColors{i})
                    clr
                    disp('ok');
                end
            end
            if ~wasHeld
                hold(ax, 'off');
            end
        end

    end
end