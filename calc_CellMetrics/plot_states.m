function plot_states(states1,t1,t2,ylim1,ax1)
    if nargin<5
        ax1 = gca;
    elseif nargin<4
        ax1 = gca;
        ylim1 = [0, 1];
    end
    % Plot states   
    stateNames = fieldnames(states1);
    clr_states = eval(['jet','(',num2str(numel(stateNames)),')']);
    for jj = 1:numel(stateNames)
        if size(states1.(stateNames{jj}),2) == 2 && size(states1.(stateNames{jj}),1) > 0
            idx = (states1.(stateNames{jj})(:,1)<t2 & states1.(stateNames{jj})(:,2)>t1);
            if any(idx)
                ydata1(1) = ylim1(1)+diff(ylim1)/numel(stateNames)*(jj-1)+diff(ylim1)/10;
                ydata1(2) = ylim1(1)+diff(ylim1)/numel(stateNames)*(jj);
                statesData2 = states1.(stateNames{jj})(idx,:);
                p1 = patch(ax1,double([statesData2,flip(statesData2,2)])',[ydata1(1);ydata1(1);ydata1(2);ydata1(2)]*ones(1,size(statesData2,1)),clr_states(jj,:),'EdgeColor',clr_states(jj,:),'HitTest','off');
                % alpha(p1,0.3);
                text(ax1,0.005,0.005+(jj-1)*0.15,stateNames{jj},'FontWeight', 'Bold','Color',clr_states(jj,:)*0.8,'margin',1,'BackgroundColor',[1 1 1 0.7], 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized'), axis tight
            else
                text(ax1,0.005,0.005+(jj-1)*0.15,stateNames{jj},stateNames{jj},'color',[0.5 0.5 0.5],'FontWeight', 'Bold','BackgroundColor',[1 1 1 0.7],'margin',1, 'HitTest','off','VerticalAlignment', 'bottom','Units','normalized')
            end
        end
    end
end