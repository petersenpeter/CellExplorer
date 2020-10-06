function subsetPlots = sharpWaveRipple(cell_metrics,UI,ii,col)
    % A custom single cell plot for the CellExplorer
    % Displays the average sharp wave-ripple for the spike group of the
    % selected cell. The peak channel of the selected cell (ii) is highlighted
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last edited: 07-12-2019
    
    subsetPlots = [];
    if isfield(cell_metrics.general,'SWR_batch')
        if UI.BatchMode
            SWR = cell_metrics.general.SWR_batch{cell_metrics.batchIDs(ii)};
        else
            SWR = cell_metrics.general.SWR_batch;
        end
        if isfield(cell_metrics,'spikeGroup') && ~isempty(SWR) && isfield(SWR,'SWR_diff') && cell_metrics.spikeGroup(ii) <= length(SWR.ripple_power)
            spikeGroup = cell_metrics.spikeGroup(ii);
            multiplier = 0.1;
            ripple_power_temp = SWR.ripple_power{spikeGroup}/max(SWR.ripple_power{spikeGroup}); grid on
            
            plot((SWR.SWR_diff{spikeGroup}*50)+SWR.ripple_time_axis(1)-50,-[0:size(SWR.SWR_diff{spikeGroup},2)-1]*multiplier,'-k','linewidth',2, 'HitTest','off')
            
            for jj = 1:size(SWR.ripple_average{spikeGroup},2)
                text(SWR.ripple_time_axis(end)+5,SWR.ripple_average{spikeGroup}(end,jj)-(jj-1)*multiplier,[num2str(round(SWR.channelDistance(SWR.ripple_channels{spikeGroup}(jj))))])
                if strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Superficial')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*multiplier,'r','linewidth',1, 'HitTest','off')
                    plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*multiplier,'or','linewidth',2, 'HitTest','off')
                elseif strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Deep')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*multiplier,'b','linewidth',1, 'HitTest','off')
                    plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*multiplier,'ob','linewidth',2, 'HitTest','off')
                elseif strcmp(SWR.channelClass(SWR.ripple_channels{spikeGroup}(jj)),'Cortical')
                    plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*multiplier,'g','linewidth',1, 'HitTest','off')
                    plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*multiplier,'og','linewidth',2, 'HitTest','off')
                else
                    plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jj)-(jj-1)*multiplier,'k', 'HitTest','off')
                    plot((SWR.SWR_diff{spikeGroup}(jj)*50)+SWR.ripple_time_axis(1)-50,-(jj-1)*multiplier,'ok', 'HitTest','off')
                end
            end
            
            if any(SWR.ripple_channels{spikeGroup} == cell_metrics.maxWaveformCh(ii)+1)
                jjj = find(SWR.ripple_channels{spikeGroup} == cell_metrics.maxWaveformCh(ii)+1);
                plot(SWR.ripple_time_axis,SWR.ripple_average{spikeGroup}(:,jjj)-(jjj-1)*multiplier,':k','linewidth',2, 'HitTest','off')
            end
            axis tight, ax6 = axis; grid on
            plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k', 'HitTest','off');
            xlim([-220,SWR.ripple_time_axis(end)+50]), xticks([-120:40:120])
            title(['SWR spikeGroup ', num2str(spikeGroup)]),xlabel('Time (ms)'), ylabel('Ripple (mV)')
            ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
            ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
            ht3 = text(0.98,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90,'Interpreter', 'none')
        else
            title('Sharp wave-ripple')
            text(0.5,0.5,'No data','FontWeight','bold','HorizontalAlignment','center')
        end
    else
        title('Sharp wave-ripple')
        text(0.5,0.5,'Not data','FontWeight','bold','HorizontalAlignment','center')
    end
    