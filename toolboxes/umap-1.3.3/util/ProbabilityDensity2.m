%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%
classdef ProbabilityDensity2 < handle
    properties(Constant) 
        DEFAULT_BAND_WIDTH=.014;
        DEFAULT_GRID_SIZE=256;
        N_MIN=5000;
    end
    
    properties(SetAccess=private)
        deltas;
        onScale;
        xyData;
        xgrid;
        ygrid;
        wmat;
        fmat;
        fmatVector;
        ye;
        xm;
        ym;
        h;
        M;
        N;
        D;
        mins;
        maxs;
        dataBinIdxs;
    end
    
    methods
        function this=ProbabilityDensity2(xyData, mins, maxs, gridSize, bandWidth)
            assert(nargin>0);
            [this.N, this.D]=size(xyData);
            assert(this.D==2); %2D only
            if nargin<5
                bandWidth=this.DEFAULT_BAND_WIDTH;
                if nargin<4
                    gridSize=this.DEFAULT_GRID_SIZE;
                    if nargin<3
                        maxs=[];
                        if nargin<2
                            mins=[];
                        end
                    end
                end
            end
            needsScaling=~isempty(maxs) || ~isempty(mins);
            if isempty(maxs)
                maxs=max(xyData);
            end
            if isempty(mins)
                mins=min(xyData);
            end
            if needsScaling
                this.onScale=MatBasics.FindOnScale(xyData, mins, maxs);
                cntEdge=size(xyData, 1)-sum(this.onScale);
                if cntEdge>0
                    xyData=xyData(this.onScale, :);
                    this.N=this.N-cntEdge;
                end
                
            end
            this.mins=mins;
            this.maxs=maxs;
            this.M =gridSize;
            this.deltas=1/(this.M-1)*(maxs-mins);              
            this.xyData=xyData;
            this.h=zeros(1, this.D);
            for i =1:this.D
                if this.N<ProbabilityDensity2.N_MIN
                    this.h(i)=(this.N/ProbabilityDensity2.N_MIN)^(-1/6)*1.7...
                        *bandWidth*(maxs(i)-mins(i));
                else
                    this.h(i)=bandWidth*(maxs(i)-mins(i));
                end
            end
            this.computeWeight;
            this.computeDensity;
        end
        
        function drawJetColors(this, ax, numberOfJetColors)
            if nargin<3
                numberOfJetColors=128;
            end
            this.drawColors(ax, numberOfJetColors);
        end
        
        function H=drawContours(this, ax, percent, color, lineWidth)
            if nargin<5
                lineWidth=1;
                if nargin<4
                    color=[.5 .5 .6];
                    if nargin<3
                        percent=10;
                    end
                end
            end
            numLevels=floor(100/percent);
            levels=this.computeLevels(numLevels);
            [~,H]=contour(ax, this.xm, this.ym, this.fmat, levels, ...
                'k', 'color', color, 'LineStyle', '-', 'LineWidth', lineWidth);
        end
        
        function drawColors(this, ax, numberOfJetColors, subsetOfData, ...
            colorRangeStart, colorRangeEnd)
            wasHeld=ishold(ax);
            if ~wasHeld
                hold(ax);
            end
            if nargin<5
                isJetColor=true;
                if nargin<4
                    subsetOfData=[];
                    if  nargin<3
                        numberOfJetColors=64;                        
                    end
                end
            else
                isJetColor=false;
            end
            if isempty(subsetOfData)
                data=this.xyData;
            else
                if size(subsetOfData, 1)==length(this.onScale)
                    data=subsetOfData(this.onScale, :);
                else
                    onScale_=MatBasics.FindOnScale(subsetOfData, ...
                        this.mins, this.maxs);
                    data=subsetOfData(onScale_, :);
                end
            end
            z=reshape(1:this.M^2,this.M,this.M);
            eb=interp2(this.xgrid, this.ygrid, z',...
                data(:,1),data(:,2),'nearest');  %this associates each data point with its nearest grid point
            [x1,~,x3]=unique(eb);
            if isJetColor
                colors=jet(numberOfJetColors);
            else
                if nargin<6
                    colors=colorRangeStart;
                else
                    a1=mean(colorRangeEnd);
                    a2=mean(colorRangeStart);
                    if a1<a2
                        m1=max(colorRangeEnd);
                        if m1>.75
                            f=.75/m1;
                            colorRangeEnd=colorRangeEnd*f;
                        end
                    end
                    nColors=32;
                    colors=zeros(nColors,3);
                    colors(1,:)=colorRangeStart;
                    colors(nColors,:)=colorRangeEnd;
                    gap=zeros(1,3);
                    for i=1:3
                        gap(i)=colorRangeEnd(i)-colorRangeStart(i);
                    end
                    for i=2:nColors-1
                        for j=1:3
                            colors(i,j)=colors(1,j)+(i/nColors*gap(1,j));
                        end
                    end
                end
            end
            nColors=length(colors);
            try
                levels=this.computeLevels(nColors);
            catch ex
            end
            if size(data,1)<10
                color=colors(1, :);
                plot(ax, data(:,1), data(:,2), 'd',...
                    'markersize', 2, 'MarkerEdgeColor',...
                    color, 'LineStyle', 'none');
                if ~wasHeld
                    hold(ax);
                end
                return;
            end
            try
                colormap(colors);
            catch ex
                disp('huh');
            end
            densities=this.fmatVector(x1);
            lookup=bsearch(levels,densities);
            eventColors=lookup(x3);
            usedColors=unique(eventColors);
            N2=length(usedColors);
            sz=size(data,1);
            if sz<10000
                marker='d';
                ms=2;
            else
                marker='.';
                ms=2;
            end
            for i=1:N2
                colorIdx=usedColors(i);
                li=eventColors==colorIdx;
                plot(ax, data(li,1), data(li,2), marker,...
                    'markersize', ms, 'MarkerEdgeColor',...
                    colors(colorIdx, :), 'LineStyle', 'none');
            end
            if ~wasHeld
                hold(ax);
            end
        end
    end
    
    methods(Access=private)        
    
        function computeWeight(this)
            this.ye=zeros(2, this.M);
            pointLL=zeros(this.N,2);  %this will be the "lower left" gridpoint to each data point
            for ii = 1:2
                this.ye(ii,:) = linspace(this.mins(ii), this.maxs(ii), this.M);
                pointLL(:,ii)=floor((this.xyData(:,ii)-this.mins(ii))./this.deltas(ii)) + 1;
            end
            pointLL(pointLL==this.M)=this.M-1;  %this avoids going over grid boundary
            %% assign each data point to its closest grid point
            [this.xgrid, this.ygrid]=meshgrid(this.ye(1,:),this.ye(2,:));
            z=reshape(1:this.M^2, this.M, this.M);
            this.dataBinIdxs=interp2(this.xgrid, this.ygrid,z',...
                this.xyData(:,1),this.xyData(:,2),'nearest');  %this associates each data point with its nearest grid point
            
            %% compute w
            Deltmat=repmat(this.deltas, this.N,1);
            shape=this.M*ones(1,2);
            wmat_=zeros(this.M, this.M);
            for ii=0:1  %number of neighboring gridpoints in 2 dimensions
                for j=0:1
                    pointm=pointLL+repmat([j ii],this.N,1);  %indices of ith neighboring gridpoints
                    pointy=zeros(this.N,2);
                    for k=1:2
                        pointy(:,k)=this.ye(k,pointm(:,k));  %y-values of ith neighboring gridpoints
                    end
                    W=prod(1-(abs(this.xyData-pointy)./Deltmat),2);  %contribution to w from ith neighboring gridpoint from each datapoint
                    wmat_=wmat_+accumarray(pointm,W,shape);  %sums contributions for ith gridpoint over data points and adds to wmat
                end
            end
            this.wmat=wmat_;
            
        end
        
        function computeDensity(this)
            Z_=zeros(1, this.D);
            Zin=cell(1, this.D);
            for i =1:this.D
                Z_(i)=min(floor(4*this.h(i)/this.deltas(i)), this.M-1);
                Zin{i}=-Z_(i):Z_(i);
            end
            phi = @(x) 1/sqrt(2*pi)*exp(-x.^2./2);
            [L_{1},L_{2}]=meshgrid(Zin{1},Zin{2});
            Phix=phi(L_{1}*this.deltas(1)./this.h(1))./this.h(1);
            Phiy=phi(L_{2}*this.deltas(2)./this.h(2))./this.h(2);
            Phimat = (Phix.*Phiy)';   
            fMat = 1/this.N*conv2(this.wmat,Phimat,'same');
            this.fmatVector=reshape(fMat,[1, this.M^2]);
            this.fmat=fMat';
            [this.xm, this.ym]=meshgrid(this.ye(1,:),this.ye(2,:));
        end
        
        function levels=computeLevels(this, numberOfLevels)
            T=sort(reshape(this.fmat, 1, this.M^this.D));
            CT=cumsum(T);
            NT=CT/CT(end);
            levels=zeros(1, numberOfLevels);
            for level=1:numberOfLevels
                idx=bsearch(NT, level/numberOfLevels);
                levels(level)=T(idx);
            end
        end
        
    end
    
    methods(Static)
        function Draw(ax, data, doContours, doJetColors, reset)
            if nargin<5
                reset=true;
                if nargin<4
                    doJetColors=true;
                    if nargin<3
                        doContours=true;
                    end
                end
            end
            pb=ProbabilityDensity2(data);
            if reset
                cla(ax, 'reset');
            end
            try
                wasHeld=ishold(ax);
                if ~wasHeld
                    hold(ax, 'on');
                end
                if doJetColors
                    pb.drawJetColors(ax);
                end
                if doContours
                    pb.drawContours(ax);
                end
                if ~wasHeld
                    hold(ax, 'off');
                end
            catch ex
                ex.getReport
            end
        end
        
        function [fncMotion, javaLegend, btns, btnLbls]=DrawLabeled(ax, data, ...
                lbls, lblMap, doCntrs, reset, priorFcn, doubleClicker, ...
                xMargin, yMargin, javaWnd, oldJavaBtns, southComponent)
            fncMotion=[];
            javaLegend=[];
            btns=[];
            btnLbls=[];
            if nargin<13
                southComponent=[];
                if nargin<12
                    oldJavaBtns=[];
                    if nargin<11
                        javaWnd=false;
                        if nargin<10
                            yMargin=-0.007;
                            if nargin<9
                                xMargin=-0.007;
                                if nargin<8
                                    doubleClicker=[];
                                    if nargin<7
                                        priorFcn=[];
                                        if nargin<6
                                            reset=true;
                                            if nargin<5
                                                doCntrs=true;
                                                if nargin<4
                                                    lblMap=[];
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            [R, C]=size(data);
            assert(C==2, 'data''s 2nd dimension must be size 2!');
            [RL, CL]=size(lbls);
            assert(CL==1, 'Labels'' 2nd dimension must be size 1!');
            assert(R==RL, 'Labels'' 1st dimension size !- data''s 1st!');
            pb=ProbabilityDensity2(data);
            if reset
                cla(ax, 'reset');
            end
            try
                wasHeld=ishold(ax);
                if ~wasHeld
                    hold(ax, 'on');
                end
                u=unique(lbls);
                N=length(u);
                labelHs=zeros(1,N);
                if isempty(lblMap)
                    if exist('labelMap.properties', 'file')
                        lblMap=java.util.Properties;
                        lblMap.load(java.io.FileInputStream('labelMap.properties'));
                    end
                end
                if isempty(lblMap)
                    for i=1:N
                        l=lbls==u(i);
                        clr=Gui.HslColor(i, N);
                        labelHs(i)=plot(ax, ...
                            data(l,1), data(l,2), '.', 'MarkerSize', 2,...
                            'MarkerEdgeColor', clr, 'LineStyle', 'none');
                    end
                else
                    names={};
                    labelIdxs=[];
                    for i=1:N
                        key=num2str(u(i));
                        l=lbls==u(i);
                        keyColor=[key '.color'];
                        colorString=char(lblMap.get(keyColor));
                        if ~isempty(colorString)
                            clr=str2num(colorString);
                            if any(clr>1)
                                clr=clr/256;
                            end
                        else
                            if u(i)==0
                                clr=[.61 .61 .61];
                            else
                                clr=Gui.HslColor(i, N);
                            end
                            colorString=num2str(floor(clr*256));
                            lblMap.put(keyColor, colorString);
                        end
                        labelHs(i)=plot(ax, ...
                            data(l,1), data(l,2), '.', 'MarkerSize', 2,...
                            'MarkerEdgeColor', clr, 'LineStyle', 'none');
                        name=char(lblMap.get(java.lang.String(key)));
                        if ~isempty(name)
                            names{end+1}=name;
                            labelIdxs(end+1)=i;
                        else
                            names{end+1}='unsupervised';
                            labelIdxs(end+1)=i;
                            %disp([id ' NOT found' ]);
                        end
                    end
                    if ~isempty(names)
                        [javaLegend, fncMotion, btns, sortI]=...
                            Plots.Legend(labelHs,...
                             names, labelIdxs, xMargin, yMargin, true,...
                            [], priorFcn, doubleClicker, javaWnd, ...
                            oldJavaBtns, southComponent);
                        btnLbls=u(sortI);
                        if ~isempty(doubleClicker)
                            %draggable(H);
                        end
                    end
                end
                if doCntrs
                    pb.drawContours(ax, 10, [0 0 0]);
                end
                if ~wasHeld
                    hold(ax, 'off');
                end
            catch ex
                ex.getReport
            end
        end
    end
end