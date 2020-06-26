function fit_params_out = fit_ACG(acg_narrow,plots)
% This function is part of CellExplorer
% Fits a tripple exponential to the ACGs
% By Peter Petersen
% Last edited: 16-06-22020;
if ~exist('plots','var')
    plots = true;
end
fit_params = nan(8,size(acg_narrow,2));
rsquare = nan(1,size(acg_narrow,2));
plotf0 = zeros(100,size(acg_narrow,2));
offset = 101;
x = ([1:100]/2)';
g = fittype('max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0)','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c','d','e','f','g','h'});

% Calculations
gcp;

% Turning off interation limit warning
warning('off','stats:nlinfit:IterationLimitExceeded')
% Fitting ACGs in parfor
parfor j = 1:size(acg_narrow,2)
    if ~any(isnan(acg_narrow(:,j)))
        [f0,gof] = fit(x,acg_narrow(x*2+offset,j),g,'StartPoint',[20, 1, 30, 2, 0, 5, 1.5,2],'Lower',[1, 0.1, 0, 0, -30, 0,0.1,0],'Upper',[500, 50, 500, 15, 50, 20,5,100]);
        plotf0(:,j) = f0(x);
        fit_params(:,j) = coeffvalues(f0);
        rsquare(j) = gof.rsquare;
    end
end

fit_params_out.acg_tau_decay = fit_params(1,:);
fit_params_out.acg_tau_rise = fit_params(2,:);
fit_params_out.acg_c = fit_params(3,:);
fit_params_out.acg_d = fit_params(4,:);
fit_params_out.acg_asymptote = fit_params(5,:);
fit_params_out.acg_refrac = fit_params(6,:);
fit_params_out.acg_tau_burst = fit_params(7,:); 
fit_params_out.acg_h = fit_params(8,:);
fit_params_out.acg_fit_rsquare = rsquare;

% Plots
if plots
    jj = 1;
    for j = 1:size(acg_narrow,2)
        
        if rem(j,12)==1
            fig = figure('Name','Fitting ACGs','pos',[50,50,1000,800]);
            ha = tight_subplot(3,4,[.06 .03],[.08 .06],[.06 .05]);
            jj = 1;
        end
        if ~any(isnan(acg_narrow(:,j)))
            y = acg_narrow(x*2+offset,j);
            set(fig,'CurrentAxes',ha(jj)), hold(ha(jj),'on')
            patch(ha(jj),[x(1),reshape([x,x([2:end,end])]',1,[]),x(end)]  , [0,reshape([y,y]',1,[]),0],'b','EdgeColor','none','FaceAlpha',.8,'HitTest','off')
            plot(ha(jj),x,plotf0(:,j),'r-');
            title(ha(jj),[num2str(j) , ': rise=' num2str(fit_params(2,j),3),', decay=' num2str(fit_params(1,j),3),])
            xlim(ha(jj),[0,50])
        end
        jj = jj + 1;
    end
    
    figure,
    subplot(3,3,1), x1 = fit_params(1,:);
    [~,edges] = histcounts(log10(x1),40);
    histogram(x1,10.^edges), xlabel('\tau_{decay} [ms]'), axis tight, ylabel('A')
    set(gca, 'xscale','log')
    
    subplot(3,3,2), x1 = fit_params(2,:);
    [~,edges] = histcounts(log10(x1),40);
    histogram(x1,10.^edges), xlabel('\tau_{rise} [ms]'), axis tight, title('double-exponential fit to the ACG'), ylabel('B')
    set(gca, 'xscale','log')
    
    subplot(3,3,3), x1 = fit_params(3,:);
    [~,edges] = histcounts(log10(x1),40);
    histogram(x1,10.^edges), xlabel('constant c'), axis tight, ylabel('C')
    set(gca, 'xscale','log')
    
    subplot(3,3,4), x1 = fit_params(4,:);
    [~,edges] = histcounts(log10(x1),40);
    histogram(x1,10.^edges), xlabel('constant d'), axis tight, ylabel('D')
    set(gca, 'xscale','log')
    
    subplot(3,3,5), x1 = fit_params(5,:);
    histogram(x1,40), xlabel('constant e'), axis tight, ylabel('E')
    
    subplot(3,3,6), x1 = fit_params(6,:);
    histogram(x1,40), xlabel('t_0 Refractory time (ms)'), axis tight, ylabel('F')
    
    subplot(3,3,7), x1 = fit_params(7,:);
    histogram(x1,40), xlabel('\tau_{burst}'), axis tight, ylabel('G')
    
    subplot(3,3,8), x1 = fit_params(8,:);
    histogram(x1,40), xlabel('Burst constant'), axis tight, title('fit = max(c*(exp(-(x-t_0)/\tau_{decay})-d*exp(-(x-t_0)/\tau_{rise}))+h*exp(-(x-t_0)/\tau_{burst})+e,0)'), ylabel('H')
    
    subplot(3,3,9), x1 = rsquare;
    histogram(x1,40), xlabel('r^2'), axis tight, ylabel('r^2')
    drawnow
end
end
