function b = trilat(X,Y,A,beta0,plots,waveforms_in)
% Trilateration estimation of unit location 
% 
% Implementation sources:
% https://stackoverflow.com/questions/31670411/find-position-based-on-signal-strength-intersection-area-between-circles
% https://gis.stackexchange.com/questions/40660/trilateration-algorithm-for-n-amount-of-points
% -------
% Input:
% X:        (n,1)-Matrix with x coordinates of n electrode sites
% Y:        (n,1)-Matrix with y coordinates of n electrode sites
% A:        Spike amplitude vector in µV with n elements
% plots:    Display spatial location relative to the electrode sites (boolean and optional)
% waveforms_in: (n,m)-Matrix with average m-length waveforms from n sites (optional)
%
% Output:
% b:        Estimated unit position (in µm)
% -------

% By Peter Petersen
% petersen.peter@gmail.com

% Making sure the dimension of the input is correct
X = X(:);
Y = Y(:);
A = A(:);

if nargin < 3
        plots = 0;
        waveforms_in = [];
end

d = 1000*A.^(-2);
tbl = table([X,Y],d);
weights = (1000*(A-min(A)+0.0001).^(-2)).^(-2);
% beta0 = [20, -100]; % initial position

modelfun = @(b,X1)(((b(1)-X1(:,1)).^2+(b(2)-X1(:,2)).^2).^(1/2));
opts = statset('TolFun',1e-3);
% mdl = fitnlm(X,y,modelfun,beta0,'Options',opts);
mdl = fitnlm(tbl,modelfun,beta0, 'Weights', weights,'Options',opts);
b = mdl.Coefficients{1:2,{'Estimate'}};

if plots
    figure
    subplot(1,2,1)
    viscircles(X, d,'color',[0,0,0,0.1]), hold on
    scatter(b(1),b(2), 70, [0 0 1], 'filled')
    scatter(X,Y, 70, [0 0 0], 'filled')
    hold off
    subplot(2,2,2)
    dist1 = (((b(1)-X).^2+(b(2)-Y).^2).^(1/2));
    plot(dist1,A,'o'),set(gca, 'XScale', 'log')
    
    % legend({'Recording sites'})
    title('Trilaterated spatial location'), xlabel('µm'), ylabel('Depth (µm)')
    if ~isempty(waveforms_in)
        for n = 1:8
            waveform2 = waveforms_in(n,:);
            plot(([1:length(waveform2)]-length(waveform2)/2)/6+X(n,1),waveform2/15+X(n,2)-2,'b')
            plot(b(1),b(2), 'ob','markersize',10), axis tight
        end
    end
end
