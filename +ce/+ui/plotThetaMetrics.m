function plotThetaMetrics(metrics)
%PLOTTHETAMETRICS Legacy diagnostic plots outside the numerical stage.
figure;
subplot(2,2,1);
plot(metrics.general.responseCurves.thetaPhase.x_bins,horzcat(metrics.responseCurves.thetaPhase{:}));
title('Theta entrainment during locomotion'); xlim([-1,1]*pi);
subplot(2,2,2);
plot(metrics.thetaPhaseTrough,metrics.thetaPhasePeak,'o'); xlabel('Trough'); ylabel('Peak');
subplot(2,2,3);
histogram(metrics.thetaEntrainment,30); title('Theta entrainment');
subplot(2,2,4);
histogram(metrics.thetaPhaseTrough,(-1:0.2:1)*pi); title('Theta trough and peak'); hold on;
histogram(metrics.thetaPhasePeak,(-1:0.2:1)*pi); legend({'Trough','Peak'});
end
