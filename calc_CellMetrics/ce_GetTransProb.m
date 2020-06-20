function [trans,prob,prob_uncor,pred] = ce_GetTransProb(rawCCG,n,binSize,conv_win,varargin)
% Extract the baseline corrected CCG + spike trans probe from raw CCG

%rawCCG = spike count between reference and target spike train
% n = number of reference spikes
% bin size = the binning of the CCG (in seconds)
% conv_win = slow, network comodulation time scale (in seconds)
% (optional input) = intwin = time bins in which synapse should inject
% excess synchrony


% define integration window
if ~isempty(varargin)
    intwin = varargin{1};
else
    intwin = round(length(rawCCG)/2) + round([.0008:binSize:.0048]/binSize);
end

%get CCG normalized by number of reference spikes
prob_uncor = rawCCG./n;

%calculate low freq. network comodulation
[ ~, pred ] = ce_cch_conv( rawCCG, round(conv_win/binSize));

%baseline subtract
prob = (rawCCG(:) - pred)/n;

prob1 = prob;
prob1(prob1<0) = 0;

%integrate
trans = sum(prob1(intwin));
end