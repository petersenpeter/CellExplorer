function chanCoordsVisualization(chanCoords,axes)
    %Plotting channel coordinates
    line(axes,chanCoords.x,chanCoords.y,'color','k','Marker','.','linestyle','none','HitTest','off','markersize',5)
    x_lim_data = [min(chanCoords.x),max(chanCoords.x)];
    y_lim_data = [min(chanCoords.y),max(chanCoords.y)];
    x_padding = 0.05*diff(x_lim_data);
    y_padding = 0.05*diff(y_lim_data);
    if x_padding>0
        xlim(axes,[x_lim_data(1)-x_padding,x_lim_data(2)+x_padding])
    end
    if y_padding>0
        ylim(axes,[y_lim_data(1)-y_padding,y_lim_data(2)+y_padding])
    end
end
