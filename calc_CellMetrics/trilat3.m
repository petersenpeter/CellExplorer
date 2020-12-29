function b = trilat3(X,A,beta0,plots,waveforms_in)
% Trilateration estimation of unit location 
% 
% Implementation sources:
% https://stackoverflow.com/questions/31670411/find-position-based-on-signal-strength-intersection-area-between-circles
% https://gis.stackexchange.com/questions/40660/trilateration-algorithm-for-n-amount-of-points
% -------
% Input:
% X:        (n,3)-Matrix with x,y,z coordinates of n electrode sites
% A:        Spike amplitude vector in µV with n elements
% plots:    Display spatial location relative to the electrode sites (boolean and optional)
% waveforms_in: (n,m)-Matrix with average m-length waveforms from n sites (optional)
%
% Output:
% b:        Estimated unit position (in µm)
% -------

% By Peter Petersen
% petersen.peter@gmail.com

% Turning off interation limit warning
warning('off','stats:nlinfit:IterationLimitExceeded')

if nargin < 2
        plots = 0;
        waveforms_in = [];
end
d = 1000*A.^(-2);
tbl = table(X, d');
weights = (1000*(A-min(A)+0.0001).^(-2)).^(-2);
% beta0 = [20, -100]; % initial position

modelfun = @(b,X)((abs(b(1)-X(:,1)).^2+abs(b(2)-X(:,2)).^2+abs(b(3)-X(:,3)).^2).^(1/2));
mdl = fitnlm(tbl,modelfun,beta0, 'Weights', weights.');
b = mdl.Coefficients{1:3,{'Estimate'}};

if plots
    figure
    subplot(1,2,1)
    viscircles(X(), d,'color',[0,0,0,0.1]), hold on
    scatter(b(1),b(2),b(3), 70, [0 0 1], 'filled')
    scatter(X(:,1),X(:,2),X(:,3), 70, [0 0 0], 'filled')
    hold off
    subplot(1,2,2)
    scatter(X(:,1),X(:,2),X(:,3), 70, [0 0 0], 'filled'), hold on
    
    % legend({'Recording sites'})
    title('Trilaterated spatial location'), xlabel('µm'), ylabel('Depth (µm)')
    if ~isempty(waveforms_in)
        for n = 1:8
            waveform2 = waveforms_in(n,:);
            plot(([1:length(waveform2)]-length(waveform2)/2)/6+X(n,1),waveform2/15+X(n,2)-2,'b')
            plot3(b(1),b(2),b(3), 'ob','markersize',10), axis tight
        end
    end
end
