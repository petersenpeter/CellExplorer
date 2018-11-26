function fit_params_out = fit_ACG(ACG2)
fit_params = [];
rsquare = [];
offset = 101;
% g = fittype('max(c*exp(-(x-f)/a)-d*exp(-(x-f)/b)+e,0)','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c','d','e','f'});
g = fittype('max(c*exp(-(x-f)/a)-d*exp(-(x-f)/b)+e+h*exp(-(x-f)/g),0)','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c','d','e','f','g','h'});

ACG_mat =[]; paut=[];
jj = 1;
for j = 1:size(ACG2,2)
    x = [1:100]';
    y = ACG2(x+offset,j)/max(ACG2(x+offset,j));
    
    [f0,gof] = fit(x/2,y,g,'StartPoint',[25, 1, 1, 2, 0, 3, 1,1],'Lower',[1, 0.1, 0, 0, -30, 0,0.1,0],'Upper',[500, 50, 20, 15, 50, 20,10,20]);
%     f0 = fit(x/2,y,'exp2','StartPoint',[1, -0.015, -1, -1]);
    fit_params(:,j) = coeffvalues(f0);
%     xx = linspace(0,48,100);
    rsquare(j) = gof.rsquare;

    if rem(j,12)==1
        figure,
        jj = 1;
    end
    subplot(3,4,jj)
    plot(x/2,y,'.-',x/2,f0(x/2),'r-'); axis tight, title([num2str(j) , ': rise=' num2str(fit_params(2,j),3),', decay=' num2str(fit_params(1,j),3),])
    ylim([0,1])
%     subplot(2,1,2)
%     [fmodel,ydata,xdata,paut(j,:)] = fitpyrint(ACG2(:,j)',0:0.5:50,1,20);

    jj = jj + 1;
end

figure,
subplot(2,4,1), x = fit_params(1,:);
[~,edges] = histcounts(log10(x),40);
histogram(x,10.^edges), xlabel('\tau_{decay} [ms]'), axis tight
set(gca, 'xscale','log')

subplot(2,4,2), x = fit_params(2,:);
[~,edges] = histcounts(log10(x),40);
histogram(x,10.^edges), xlabel('\tau_{rise} [ms]'), axis tight, title('double-exponential fit to the ACG')
set(gca, 'xscale','log')

subplot(2,4,3), x = fit_params(3,:);
[~,edges] = histcounts(log10(x),40);
histogram(x,10.^edges), xlabel('constant c'), axis tight
set(gca, 'xscale','log')

subplot(2,4,4), x = fit_params(4,:);
[~,edges] = histcounts(log10(x),40);
histogram(x,10.^edges), xlabel('constant d'), axis tight
set(gca, 'xscale','log')

subplot(2,4,5), x = fit_params(5,:);  
histogram(x,40), xlabel('constant e'), axis tight

subplot(2,4,6), x = fit_params(6,:);
histogram(x,40), xlabel('t_0 Refractory time (ms)'), axis tight, title('fit = c*exp(-(t-t_0)/\tau_{decay})-d*exp(-(t-t_0)/\tau_{rise}) + e')

subplot(2,4,7), x = rsquare;
histogram(x,40), xlabel('r^2'), axis tight

fit_params_out.ACG_tau_decay = fit_params(1,:);
fit_params_out.ACG_tau_rise = fit_params(2,:);
fit_params_out.ACG_c = fit_params(3,:);
fit_params_out.ACG_d = fit_params(4,:);
fit_params_out.ACG_asymptote = fit_params(5,:);
fit_params_out.ACG_refrac = fit_params(6,:);
fit_params_out.ACG_tau_burst = fit_params(7,:); 
fit_params_out.ACG_h = fit_params(8,:);
fit_params_out.ACG_fit_rsquare = rsquare;
