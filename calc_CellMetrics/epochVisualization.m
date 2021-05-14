function epochVisualization(epochs,axes,y1,y2,y3)
    %Plotting epochs
    colors = 1-(1-lines(numel(epochs)))*0.7;
    if numel(epochs)==1 && (~isfield(epochs{1},'startTime') || epochs{1}.startTime==0) && (~isfield(epochs{1},'stopTime') || isempty(epochs{1}.startTime))
        return
    end
    for i = 1:numel(epochs)
        if isfield(epochs{i},'startTime') && isfield(epochs{i},'stopTime')
            p1 = patch(axes,[epochs{i}.startTime epochs{i}.stopTime  epochs{i}.stopTime epochs{i}.startTime],[y1 y1 y2 y2],colors(i,:),'EdgeColor',colors(i,:)*0.8,'HitTest','off');
            alpha(p1,0.8);
        elseif isfield(epochs{i},'startTime')
            line(axes,[epochs{i}.startTime epochs{i}.startTime],[y1 y2],'color',colors(i,:),'HitTest','off','linewidth',1.5);
        end
        if isfield(epochs{i},'startTime')
            text(axes,epochs{i}.startTime,y2,[' ',num2str(i)],'color','k','VerticalAlignment', 'top','Margin',1,'interpreter','none','HitTest','off') % ,'fontweight', 'bold'
        end
        if isfield(epochs{i},'startTime') && nargin==5
            if isfield(epochs{i},'behavioralParadigm')
                label = epochs{i}.behavioralParadigm;
            elseif isfield(epochs{i},'name')
                label = epochs{i}.name;
            else
                label = [];
            end
            if ~isempty(label)
                line(axes,[epochs{i}.startTime epochs{i}.startTime],[y2 y3],'color','k','linestyle','--','HitTest','off','linewidth',1);
                text(epochs{i}.startTime, y3, label, 'HitTest','off','HorizontalAlignment','right','VerticalAlignment','top','Rotation',90,'Interpreter', 'none','BackgroundColor',[1 1 1 0.7],'margin',0.1);
            end
        end
    end
    text(0,y1,'Epochs','VerticalAlignment', 'bottom','HorizontalAlignment','left', 'HitTest','off', 'FontSize', 12, 'Color', 'w','BackgroundColor',[0 0 0 0.7],'margin',0.1)
end
