%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

classdef Plots < handle
    
    properties(SetAccess=private)
        is3D;
        legendHs;
        mdns;
        stds;
    end
    
    properties
        Hs;
        otherHs;
        cnts;
        names;
        N;
        distFactor;
        mx;
        mxI;
        mn;
        mnI;
    end
    
    methods
        function this=Plots()
            this.Hs=[];
        end
        
        function setHs(this, Hs)
            this.Hs=Hs;
            this.N=length(this.Hs);
            this.cnts=zeros(1, this.N);
            if isempty(this.names) 
                this.names=cell(1, this.N);
                for i=1:this.N
                    this.cnts(i)=length(get(this.Hs(i), 'XData'));
                    this.names{i}=get(this.Hs(i), 'DisplayName');
                end
            else
                for i=1:this.N
                    this.cnts(i)=length(get(this.Hs(i), 'XData'));
                end
            end
            this.setMinMax;
        end
        
        function setMinMax(this)
            [this.mx, this.mxI]=max(this.cnts);
            [this.mn, this.mnI]=min(this.cnts);
        end
        
        function setOtherHs(this, Hs)
            this.otherHs=Hs;
        end
        
        function setLegendHs(this, Hs)
            this.legendHs=Hs;
        end
        
        function initStats(this)
            if isempty(this.mdns)
                if isempty(this.Hs)
                    return;
                end
                [this.mdns, this.stds, this.is3D]=Plots.Stats(this.Hs);
                if this.is3D
                    this.distFactor=6;
                else
                    this.distFactor=3;
                end
            end
        end        
        
        function setNames(this, names)
            this.names=names;
        end
        
        function names=getNames(this)
            names=this.names;
        end
        
        function toggleVisibility(this, idx)
            if ~isempty(this.otherHs)
                R=size(this.otherHs,1);
                for r=1:R
                    plotH=this.otherHs(r, idx);
                    if strcmp('off', get(plotH, 'visible'))
                        set(plotH(r), 'visible', 'on');
                    else
                        set(plotH(r), 'visible', 'off');
                    end
                end
            end
        end
        
        function clear(this)
            try
                N_=length(this.Hs);
                for i=1:N_
                    delete(this.Hs(i));
                end
                N_=length(this.otherHs);
                for i=1:N_
                    delete(this.otherHs(i));
                end
            catch ex
                %ex.getReport
            end
        end
    end
    
    methods(Static)
        
        function [mdns, stds, is3D]=Stats(plotHs)
            N=length(plotHs);
            mdns=zeros(N,3);
            stds=zeros(N,3);
            is3D=true;
            for ii=1:N
                plotH=plotHs(ii);
                if ~ishandle(plotH)
                    return;
                end
                x_=get(plotH, 'XData');
                y_=get(plotH, 'YData') ;
                z_=get(plotH, 'ZData');
                if isempty(z_)
                    [RR,CC]=size(get(plotHs(ii), 'XData'));
                    z_=ones(RR, CC);
                    is3D=false;
                end
                d=[x_; y_; z_]';
                mdns(ii,:)=median(d);
                stds(ii,:)=std(d);
            end
        end
        
        function Flash(plotH, perc)
            ms=get(plotH, 'MarkerSize');
            if perc<.02
                set(plotH, 'MarkerSize', ms+7)
            elseif perc<.05
                set(plotH, 'MarkerSize', ms+5)
            elseif perc<.1
                set(plotH, 'MarkerSize', ms+3);
            elseif perc<.2
                set(plotH, 'MarkerSize', ms+2);
            end
            for i=1:4
                set(plotH, 'visible', 'off');
                pause(0.1);
                set(plotH, 'visible', 'on');
                pause(0.1);
            end
            set(plotH, 'MarkerSize', ms);
        end
        
        function [HL, fncMotion, btns, sortI]=Legend(plotHs, names, ...
                idxsWithName, xMargin, yMargin, doMotion, freq, priorFcn,...
                doubleClicker, javaWnd, oldJavaBtns, southComponent)
            btns=[];
            if isa(plotHs, 'Plots')
                plots=plotHs;
                N=plots.N;
            else
                plots=Plots;
                plots.setNames(names);
                if iscell(plotHs)
                    N=length(plotHs);
                    plotHs2=zeros(1,N);
                    for i=1:N
                        plotHs2(i)=plotHs{i};
                    end
                    plotHs=plotHs2;
                else
                    [R,N]=size(plotHs);
                    if R>1
                        otherPlotHs=plotHs(2:end,:);
                        plotHs=plotHs(1,:);
                        plots.setOtherHs(otherPlotHs);
                    end
                end
                plots.setHs(plotHs);
                names=plots.names;
            end
            if nargin<12
                southComponent=[];
                if nargin<11
                    oldJavaBtns=[];
                    if nargin<10
                        if nargin<9
                            doubleClicker=[];
                            if nargin<8
                                priorFcn=[];
                                if nargin<7
                                    freq=[];
                                    if nargin<6
                                        doMotion=true;
                                        if nargin<5
                                            yMargin=[];
                                            if nargin<4
                                                xMargin=[];
                                                if nargin<3
                                                    idxsWithName=[];
                                                    if nargin<2
                                                        names={};
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        javaWnd=false;
                    end
                end
            end
            if N<1
                return;
            end              
            if isempty(idxsWithName)
                idxsWithName=1:N;
            end
            assert(N>=length(idxsWithName), ...
                '# of plotHs must be >= # of idxsWithName');
            ax=get(plots.Hs(1), 'Parent');
            fig=get(ax, 'Parent');
            curOver=0;
            overH=[];
            try
                set(fig,'WindowButtonMotionFcn', @legMotion);
            catch ex
            end
            fncMotion=@legMotion;
            X=xlim(ax);
            Y=ylim(ax);
            assert( length(names) == length(idxsWithName), ...
                'Must be as many namedPlotIdxs as names');

            mx=plots.mx;
            cnts=plots.cnts;
            if isempty(freq)
                Cnt=sum(cnts);
            else
                Cnt=freq;
            end
            nNames=length(names);
            cnts2=zeros(1, nNames);
            cntPref=BasicMap.Global.getNumeric('cntPref', 2);
            if ~javaWnd
                legendHs=zeros(1, nNames);
                for i=1:nNames
                    idx=idxsWithName(i);
                    cnt=cnts(idx);
                    cnts2(i)=cnt;
                    names{i}=[names{i} '    ^{\color{blue}' ...
                        String.encodePercent(cnt, Cnt, 1) '  '...
                        '\color[rgb]{.2 .5 .2} ' ...
                        String.encodeCount(cnt, cntPref) '} '];
                    clr=get(plots.Hs(idx), 'MarkerEdgeColor');
                    legendHs(i)=plot(ax, X(1)-X(2), Y(1)-Y(2), 's', ...
                        'MarkerSize', 6 + (cnt/mx*15), 'Color',  clr, ...
                        'MarkerFaceColor', clr, 'LineStyle', 'none');
                end
                xlim(ax,X);
                ylim(ax,Y);
                [~,sortI]=sort(cnts2, 'descend');
                HL=legend(ax, legendHs(sortI), names(sortI), ...
                    'Location', 'northeast','AutoUpdate', 'off');
                if ~isempty(xMargin) && ~isempty(yMargin)
                    p=get(HL, 'position');
                    p2=Gui.GetNormalized(ax);
                    xNudge=1-(p2(1)+p2(3));
                    xNudge=xNudge-xMargin;
                    yNudge=1-(p2(2)+p2(4));
                    yNudge=yNudge-yMargin;
                    set(HL, 'position', [p(1)+xNudge, p(2)+yNudge p(3) p(4)]);
                end
                plots.setLegendHs(legendHs);
                HL.ItemHitFcn=@(h,event)Plots.LegendClick(plots, event,...
                    idxsWithName, cnts2);
            else
                for i=1:nNames
                    idx=idxsWithName(i);
                    cnt=cnts(idx);
                    cnts2(i)=cnt;
                    clr=get(plots.Hs(idx), 'MarkerEdgeColor');
                    strSymbol=['<font  ' Gui.HtmlHexColor(clr)...
                        '>&#8903;</font>'];
                    f=11+(cnt/mx*15);
                    f= ceil((f-4)/4)+1;
                    if f>6
                        f=6;
                    end
                    f=String.encodeInteger(f);
                    str=['<font size="' f '">' strSymbol '</font>'];
                    names{i}=['<html>' str names{i} '&nbsp;&nbsp;'...
                        BasicMap.Global.supStart ' <font color="blue">' ...
                        String.encodePercent(cnt,Cnt,1) '</font>'...
                        '  <font ' Html.Color([.2 .5 .2]) ' ><i>' ...
                        String.encodeCount(cnt, cntPref) '</i></font>' ...
                        BasicMap.Global.supEnd ...
                        Html.EncodeSort('name', strtrim(char(...
                        edu.stanford.facs.swing.Basics.RemoveXml(...
                        lower(names{i}))))) ...
                        Html.EncodeSort('frequency', cnt) ...
                        '</html>'];
                end
                [~, sortI]=sort(cnts2, 'descend');
                [outerPnl, ~, btns,sortGui]=...
                    Radio.Panel3(names(sortI), 1:nNames, 13, ...
                    @(h,e, i)Plots.JavaLegendClick(i,sortI,idxsWithName, ...
                    plots.Hs, cnts2, h),true,Html.Wrap(['<i>Deselecting '...
                    '<b>hides</b> items in plot & selecting <b>unhides</b></i>']));
                sortGui.setProperties(BasicMap.Global, 'javaLegend.');
                if ~isempty(oldJavaBtns)
                    it=oldJavaBtns.iterator;
                    while it.hasNext
                        btn=it.next;
                        if ~btn.isSelected
                            k=StringArray.IndexOf(names,char(btn.getText));
                            m=find(sortI==k, 1);
                            if ~isempty(m)
                                b=btns.get(m-1);
                                b.setSelected(false);
                                set(plots.Hs(k), 'visible', 'off');
                                disp('was OFF');
                            end
                        end
                    end
                    sortGui.setAllChbText;
                end
                if ~isempty(southComponent)
                    bp=Gui.BorderPanel(0,0);
                    bp.add(outerPnl, 'Center');
                    bp.add(southComponent, 'South');
                    outerPnl=bp;
                end
                pu=showMsg(outerPnl, 'Legend', 'north east+', false, ...
                    false, 0, false);
                HL=pu.dlg;
                sortGui.dlg=HL;
                if ismac
                    if 1<size(get(0, 'MonitorPositions'), 1)
                        MatBasics.RunLater(@(h,e)relocate(getjframe(fig)), .52)
                    end
                end
            end

            function relocate(ref)
                Gui.LocateJava(HL, ref, 'north east+');
                HL.setVisible(true);
            end
            function legMotion(hObj, event)
                if ~isvalid(ax)
                    return;
                end
                cp=get(ax, 'CurrentPoint');
                if isempty(cp)
                    return;
                end
                C=size(cp,2);
                x=cp(2,1);
                y=cp(2,2);
                z=cp(2,3);
                try
                    e=Gui.GetPixels(HL);
                catch ex
                    e=[];
                end
                %[normX normY normFigX normFigY e]
                if ~isempty(e)
                    cp2=get(get(HL, 'Parent'), 'currentpoint');
                    if cp2(2)<=e(2)+e(4) && cp2(2)>=e(2)
                        if cp2(1)>=e(1) && cp2(1)<= e(1)+e(3)
                            if ~isempty(doubleClicker)
                                doubleClicker.stopListening;
                            end
                            return;
                        end
                    end
                end
                if ~isempty(doubleClicker)
                    doubleClicker.startListening;
                end
                if ~doMotion
                    if ~isempty(priorFcn)
                        feval(priorFcn, hObj, event);
                    end
                    return;
                end
                plots.initStats;
                if plots.is3D
                    [D,II]=pdist2(plots.mdns, [x y z], 'euclidean', 'Smallest', 1);
                    limit=pdist2(plots.mdns(II,:), ...
                        plots.mdns(II,:)+(plots.stds(II,:)*plots.distFactor));
                else
                    [D,II]=pdist2(plots.mdns(:,1:2), [x y], 'euclidean', 'Smallest', 1);
                    limit=pdist2(plots.mdns(II,1:2), plots.mdns(II,1:2)+...
                        (plots.stds(II,1:2)*plots.distFactor));
                end
                %is3D
                [x y z ; II D limit]
                plots.names{II}
                %cp
                %[plots.mdns(II,:);plots.stds(II,:)]
                if II==plots.mxI
                    disp('hey');
                end
                if D<=limit
                    over=II;
                else
                    over=0;
                end
                if ~ishandle(overH)
                    return;
                end
                if curOver ~= over
                    curOver=over;
                    if over>0
                        %disp(['Over ' names{II}]);                        
                        nameIdx=find(idxsWithName==II,1);
                        if nameIdx>0
                            nm=names{nameIdx};
                            if javaWnd
                                nm=strrep(nm, '<sup>', '_{{');
                                nm=strrep(nm, '</sup>', '}');
                                nm=char(...
                                    edu.stanford.facs.swing.Basics.RemoveXml(nm));
                                nm=strrep(nm, '_{{', '^{');
                                nm=strrep(nm, '&#8903;','');                                
                            end
                            if isempty(overH)
                                if plots.is3D
                                    overH=text(ax, x, y, z, nm, ...
                                        'fontSize', 9, ...
                                        'color', [0 0 .5],...
                                        'EdgeColor', 'red', ...
                                        'FontName', 'Arial', ...
                                        'backgroundColor', [255/256 252/256 170/256]);
                                else
                                    overH=text(ax, x, y, nm, ...
                                        'fontSize', 9, 'color', [0 0 .5], 'EdgeColor',...
                                        'red', 'FontName', 'Arial', ...
                                        'backgroundColor', [255/256 252/256 170/256]);
                                end
                            else
                                if plots.is3D
                                    set(overH, 'visible', 'on', 'Position', ...
                                        [x y z], 'String', nm);
                                    %uistack(overH, 'top');
                                else
                                    set(overH, 'visible', 'on', 'Position', ...
                                        [x y 0], 'String', nm);
                                end
                            end
                        else
                            disp('background');
                        end
                    else
                        %disp('Over NOTHING');
                        if ~isempty(overH)
                            set(overH, 'visible', 'off');
                        end
                    end
                end
                if ~isempty(priorFcn)
                    feval(priorFcn, hObj, event);
                end
            end
        end
       
        function LegendClick(this, event, idxsWithName, nums)
            H=get(event.Peer, 'UserData');
            idx_=find(this.legendHs==event.Peer, 1);
            idx=idxsWithName(idx_);
            if ~isempty(H)
                set(event.Peer, 'UserData', []);
                delete(H);
                this.toggleVisibility(idx);
                return;
            end
            this.initStats;
            plotH=this.Hs(idx);
            perc= nums(idx_)/max(nums);
            Plots.Flash(plotH, perc);
            X=this.mdns(idx, 1);
            Y=this.mdns(idx, 2);
            ax=get(this.Hs(idx), 'Parent');
            str=get(event.Peer, 'DisplayName');
            fsz=11;
            if this.is3D
                Z=this.mdns(idx, 3);
                Plots.ShowLegendTip(ax, event.Peer, X, Y, str, fsz, 0, Z);
                [X Y Z]
            else
                Plots.ShowLegendTip(ax, event.Peer, X, Y, str, fsz, 0);
            end
            this.toggleVisibility(idx);       
        end
        
        function ok=JavaLegendClick(idx_, sortI, idxsWithName, plotHs, nums, h)
            idx=idxsWithName(sortI(idx_));
            plotH=plotHs(idx);
            if ~ishandle(plotH)
                msg('Supervisors not showing', 5, 'east+');
                ok=false;
                return;
            end
            ok=true;
            if nargin==6
                if ~h.isSelected
                    set(plotH, 'visible', 'off');
                else
                    set(plotH, 'visible', 'on');
                end
                return;
            end
            ms=get(plotH, 'MarkerSize');
            perc= nums(idx_)/max(nums);
            if perc<.02
                set(plotH, 'MarkerSize', ms+7)
            elseif perc<.05
                set(plotH, 'MarkerSize', ms+5)
            elseif perc<.1
                set(plotH, 'MarkerSize', ms+3);
            elseif perc<.2
                set(plotH, 'MarkerSize', ms+2);
            end
            for i=1:4
                set(plotH, 'visible', 'off');
                pause(0.1);
                set(plotH, 'visible', 'on');
                pause(0.1);
            end
            set(plotH, 'MarkerSize', ms);    
        end
        
        function ShowLegendTip(ax, hLegend, posX, posY, str, fsz, secs, posZ)
            if nargin<8
                [normX, normY]=Gui.DataToAxNorm(ax, posX, posY);
                tipH=text(normX+.03, normY+.03, str, ...
                    'fontSize', fsz, 'color', [0 0 .5], 'EdgeColor',...
                    'red', 'FontName', 'Arial', 'parent', ax, ...
                    'FontAngle', 'italic', 'units', 'normalized',...
                    'backgroundColor', [255/256 252/256 170/256]);
            else
                tipH=text(ax, posX, posY, posZ, str, ...
                    'fontSize', fsz, 'color', [0 0 .5], 'EdgeColor',...
                    'red', 'FontName', 'Arial', 'FontAngle', 'italic',...
                    'backgroundColor', [255/256 252/256 170/256]);
                
            end
            set(tipH, 'ButtonDownFcn', @(h,e)freeze(h, hLegend));
            if secs>0
                MatBasics.RunLater(@(h,e)closeTip, secs);
            else
                freeze(tipH, hLegend);
            end
            
            function freeze(hText, hLegend)
                if isempty(get(tipH, 'UserData'))
                    set(hText, 'UserData', true);
                    set(hText, 'FontSize', fsz-2);
                    set(hText, 'FontAngle', 'normal');
                    set(hLegend, 'UserData', hText);
                else
                    set(hLegend, 'UserData', []);
                    delete(hText);
                end
            end
            
            function closeTip
                if isempty(get(tipH, 'UserData'))
                    delete(tipH);
                end
            end
        end
        
    end
end