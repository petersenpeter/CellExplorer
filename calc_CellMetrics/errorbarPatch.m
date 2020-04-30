function f2 = errorbarPatch(t_axis,plot_mean,plot_std,clr)
plot_mean(isnan(plot_mean)) = 0;
plot_std(isnan(plot_std)) = 0;
patch([t_axis,flip(t_axis)], [plot_mean+plot_std,flip(plot_mean-plot_std)],clr,'EdgeColor','none','FaceAlpha',.3); hold on
f2 = line(t_axis,plot_mean,'color',clr);
end