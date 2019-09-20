function out=Clumps(xy, mdns, labels, M, labelMap)
if nargin<5
    labelMap=[];
    if nargin<4
        M=256;
    end
end
debug=~isempty(labelMap);
if debug
    f=figure;
    ax=gca;
    hold all;
    xlim(ax, [1 M]);
    ylim(ax, [1 M]);
end
%37413 38004
R=size(xy, 1);
out=zeros(R, 1);
[~,I]=pdist2(xy, mdns, 'euclidean', 'smallest', 1);
indsWithData=Binning.MakeUnivariate(xy, min(xy), max(xy), M);
%indsWithData=MatBasics.FlipY( Binning.MakeUnivariate(xy, min(xy), max(xy), M), M);
indsOfMdns=indsWithData(I);
[xMdn, yMdn]=ind2sub([M M], indsOfMdns);
hood=false(M, M);
hood(indsWithData)=true;
ids=zeros(M,M);
ids(indsOfMdns)=labels;
N=length(labels);
for i=1:N
    label=labels(i);
    if label==38004
        disp('Developing B');
    end
    if label==37413
        disp('LPM');
    end
    x=xMdn(i);
    y=yMdn(i);
    left=x:-1:1;
    lefts=length(left);
    right=x:1:M;
    rights=length(right);
    up=y:1:M;
    ups=length(up);
    down=y:-1:1;
    downs=length(down);
    allDone=0;
    for v=1:ups
        done=expand(up(v), label);
        if done<1
            break;
        end
        allDone=allDone+done;
    end
    for v=2:downs
        done=expand(down(v), label);
        if done<1
            break;
        end
        allDone=allDone+done;
    end
    if debug
        [debugX, debugY]=ind2sub([M M], find(ids==label));
        clr=labelMap.get([num2str(label) '.color']);
        labelMap.get(num2str(label))
        clr=str2num(clr);
        plot(ax, debugX, debugY, 'marker', '.', 'markerSize', 10, ...
            'markerFaceColor', clr/256, 'lineStyle', 'none');
    end
    indsOfLabel=find(ids==label);
    trueDataWithLabel=ismember(indsWithData, indsOfLabel);
    out(trueDataWithLabel)=label;
end
    function done=expand(y_, label)
        done=0;
        for h=1:lefts
            x_=left(h);
            if hood(x_,y_)
                ids(x_,y_)=label;
                done=done+1;
            else
                break;
            end
        end
        for h=1:rights
            x_=right(h);
            if hood(x_,y_)
                ids(x_,y_)=label;
                done=done+1;
            else
                break;
            end
        end
    end
end