function [RippleModulationIndex,RipplePeakDelay,RippleCorrelogram] = calc_RippleModulationIndex(PSTH,time)
%% Ripple modulation index

% By Peter Petersen
% petersen.peter@gmail.com
% 08-07-2019

RippleModulationIndex = [];
RippleCorrelogram = [];

conv_length1 = 5;
conv_length2 = 40;

RippleBaseline = 1:100;
RippleRipple = 161:241;
RipplePost = 161:241;
RipplePeak = 195:210;

RippleCorrelogram = nanconv(PSTH,ones(1,conv_length1)/conv_length1,'edge');
RippleCorrelogram2 = nanconv(PSTH,ones(1,conv_length2)/conv_length2,'edge');

[~,RipplePeakDelay] = max(RippleCorrelogram2);
RipplePeakDelay = RipplePeakDelay-201;

RippleModulationIndex = mean(RippleCorrelogram(RipplePeak,:))./mean(RippleCorrelogram(RippleBaseline,:));
[~,index2] = sort(RippleModulationIndex,'descend');
[~,index3] = sort(RipplePeakDelay);

figure,
subplot(2,2,1), histogram(RippleModulationIndex,40), title('RippleModulationIndex'), xlabel('Ratio')
subplot(2,2,2), histogram(RipplePeakDelay,40), title('RipplePeakDelay'), xlabel('Time (ms)')
subplot(2,2,3), imagesc((RippleCorrelogram(100:300,index2))'), title('Ripple Correlograms'), ylabel('Sorted by RippleModulationIndex')
subplot(2,2,4), imagesc((RippleCorrelogram(100:300,index3))'), title('Ripple Correlograms'), ylabel('Sorted by RipplePeakDelay')

