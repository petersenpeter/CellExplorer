function gde = alphafunction(x,tau,tau2)
% Alpha
tmax=length(x);
dt=1;
t=0:1:tmax-1;
% tau= 2;
% tau2= 2.5;
ts=1;
tr=0:1:tmax-1; %t(round(ts/dt):length(t))-(ts-dt);

% % Alpha
% gal=zeros(size(t));
% galp=tau/exp(1);
% gal(round(ts/dt):length(t))=tr.*exp(-tr/tau)/galp;

% Dual exponential
gde=zeros(size(x));
tp=(tau*tau2)*log(tau2/tau)/(tau2-tau);
gdep=(tau*tau2)*(exp(-tp/tau2)-exp(-tp/tau))/(tau2-tau);
gde(round(ts/dt):length(t))=(tau*tau2)*(exp(-tr/tau2)-exp(-tr/tau))/((tau2-tau)*gdep);

% 
% if exist('plots')
%     if plots == 1
%     figure
%     plot(t,gde,'k-');
%     title('Alpha function','FontSize',12,'FontName','Helvetica');
%     xlabel('t (msecs)','FontSize',11,'FontName','Helvetica');
%     axis([0 tmax 0 1.02]);
%     set(gca,'Box','off');
%     end
% end