function fit_params_out = fit_ACG(acg_narrow,plots)
    % This function is part of CellExplorer
    % Fits a tripple exponential to the autocorrelogram with 0.5ms bins from -50ms -> 50ms
    % This function requires the Curve Fitting Toolbox
    %
    % By Peter Petersen
    % Last edited: 21-09-2021;
    
    if ~exist('plots','var')
        plots = true;
    end
    
    
    % acg_narrow = cell_metrics.acg.narrow;
    acg_narrow(100:102) = 0; % Sets the time-zero bin to zero (-0.5ms -> 0.5ms)
    offset = 101;
    x = ([1:100]/2)';
    
    % Variables
    a0 = [20, 1, 30, 2, 0.5, 5, 1.5,2];
    lb = [1, 0.1, 0, 0, -30, 0,0.1,0];
    ub = [500, 50, 500, 15, 50, 20,5,100];
    
    fit_params = nan(8,size(acg_narrow,2));
    rsquare = nan(1,size(acg_narrow,2));
    plotf0 = zeros(100,size(acg_narrow,2));
    
    
    % Turning off interation limit warning
    warning('off','stats:nlinfit:IterationLimitExceeded')
    
    % Validating that Parallel Computing Toolbox is installed
    parallel_toolbox_installed = isToolboxInstalled('Parallel Computing Toolbox');
    curve_fitting_toolbox_installed = isToolboxInstalled('Curve Fitting Toolbox');
    
    
    
    % % % % % % % % % % % % % % % % % % % % %
    % Curve Fitting Toolbox
    % % % % % % % % % % % % % % % % % % % % %
    
    g = fittype('max(c*(exp(-(x-f)/a)-d*exp(-(x-f)/b))+h*exp(-(x-f)/g)+e,0)','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c','d','e','f','g','h'});
    
    if parallel_toolbox_installed
        % Fitting ACGs in parfor
        gcp;
        parfor j = 1:size(acg_narrow,2)
            if ~any(isnan(acg_narrow(:,j)))
                [f0,gof] = fit(x,acg_narrow(x*2+offset,j),g,'StartPoint',a0,'Lower',lb,'Upper',ub);
                plotf0(:,j) = f0(x);
                fit_params(:,j) = coeffvalues(f0);
                rsquare(j) = gof.rsquare;
            end
        end
    else
        for j = 1:size(acg_narrow,2)
            if ~any(isnan(acg_narrow(:,j)))
                [f0,gof] = fit(x,acg_narrow(x*2+offset,j),g,'StartPoint',a0,'Lower',lb,'Upper',ub);
                plotf0(:,j) = f0(x);
                fit_params(:,j) = coeffvalues(f0);
                rsquare(j) = gof.rsquare;
                
                
                a = fit_params(1);
                b = fit_params(2);
                c = fit_params(3);
                d = fit_params(4);
                e = fit_params(5);
                f = fit_params(6);
                g = fit_params(7);
                h = fit_params(8);
                x_fit = ([1:0.1:100]/2)';
                fiteqn = max(c*(exp(-(x_fit-f)/a)-d*exp(-(x_fit-f)/b))+h*exp(-(x_fit-f)/g)+e,0);
                figure(3), clf
                plot(x,ydata), hold on
                plot(x_fit,fiteqn),
                text(0.5,0.5,num2str(fit_params),'Units','normalized')
            end
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
    
    
%     % % % % % % % % % % % % % % % % % % % % %
%     % Optimization Toolbox
%     % % % % % % % % % % % % % % % % % % % % %
%     predicted = @(a,x) max(a(3)*(exp(-(x-a(6))/a(1))-a(4)*exp(-(x-a(6))/a(2)))+a(8)*exp(-(x-a(6))/a(7))+a(5),0);
%     
%     for j = 1%:size(acg_narrow,2)
%         ydata = acg_narrow(x*2+offset,j);
%         ahat = lsqcurvefit(predicted,a0,x,ydata,lb,ub);
%         
%         a = ahat(1);
%         b = ahat(2);
%         c = ahat(3);
%         d = ahat(4);
%         e = ahat(5);
%         f = ahat(6);
%         g = ahat(7);
%         h = ahat(8);
%         x_fit = ([1:0.1:100]/2)';
%         fiteqn = max(c*(exp(-(x_fit-f)/a)-d*exp(-(x_fit-f)/b))+h*exp(-(x_fit-f)/g)+e,0);
%         figure(1), clf
%         plot(x,ydata), hold on
%         plot(x_fit,fiteqn),
%         text(0.5,0.5,num2str(ahat'),'Units','normalized')
%         
%         pause(1)
%     end
%     
%     % % % % % % % % % % % % % % % % % % % % %
%     % fmin search fitting
%     % % % % % % % % % % % % % % % % % % % % %
%     ydata = acg_narrow(x*2+offset,j);
%     y = @(a1,x) max(a1(3)*(exp(-(x-a1(6))/a(1))-a1(4)*exp(-(x-a1(6))/a1(2)))+a1(8)*exp(-(x-a1(6))/a1(7))+a1(5),0);  % Objective function
%     % yx = y(a0,x) + ydata;
%     OLS = @(a1) sum((y(a1,x) - ydata).^2);          % Ordinary Least Squares cost function
%     opts = optimset('MaxFunEvals',100000, 'MaxIter',100000,'TolX',1e-5);
%     [a_new,fval,exitflag,output] = fminsearch(OLS, a0, opts);       % Use ‘fminsearch’ to minimise the ‘OLS’ function
%     a = a_new(1);
%     b = a_new(2);
%     c = a_new(3);
%     d = a_new(4);
%     e = a_new(5);
%     f = a_new(6);
%     g = a_new(7);
%     h = a_new(8);
%     x_fit = ([1:0.1:100]/2)';
%     fiteqn = max(c*(exp(-(x_fit-f)/a)-d*exp(-(x_fit-f)/b))+h*exp(-(x_fit-f)/g)+e,0);
%     
%     figure(2), clf
%     plot(x,ydata), hold on
%     plot(x_fit,fiteqn),
%     text(0.5,0.5,num2str(a_new'),'Units','normalized')
    
    
    % Plots
    if plots
        jj = 1;
        for j = 1:size(acg_narrow,2)
            
            if rem(j,12)==1
                fig = figure('Name','Fitting individual ACGs','pos',[50,50,1000,700]);
                movegui(fig,'center')
                ha = ce_tight_subplot(3,4,[.06 .03],[.08 .06],[.06 .05]);
                jj = 1;
            end
            if ~any(isnan(acg_narrow(:,j)))
                y = acg_narrow(x*2+offset,j);
                set(gcf,'CurrentAxes',ha(jj)), hold(ha(jj),'on')
                patch(ha(jj),[x(1),reshape([x,x([2:end,end])]',1,[]),x(end)]  , [0,reshape([y,y]',1,[]),0],'b','EdgeColor','none','FaceAlpha',.8,'HitTest','off')
                plot(ha(jj),x,plotf0(:,j),'r-');
                title(ha(jj),[num2str(j) , ': rise=' num2str(fit_params(2,j),3),', decay=' num2str(fit_params(1,j),3),])
                xlim(ha(jj),[0,50])
            end
            jj = jj + 1;
        end
        
        fig1 = figure('Name','Fitting ACGs','pos',[50,50,1000,700],'visible','off');
        movegui(fig1,'center')
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
        set(fig1,'visible','on')
    end
end
