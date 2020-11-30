function handle_ce_gscatter = ce_gscatter(plotX,plotY1,plotClas,clr_groups,markerSize,markerType)
uniqueGroups = unique(plotClas);
for i_groups = 1:size(clr_groups,1)
    idx = plotClas == uniqueGroups(i_groups);
    handle_ce_gscatter(i_groups) = line(plotX(idx), plotY1(idx),'Marker',markerType,'LineStyle','none','color',clr_groups(i_groups,:), 'MarkerSize',markerSize,'HitTest','off');
end
end