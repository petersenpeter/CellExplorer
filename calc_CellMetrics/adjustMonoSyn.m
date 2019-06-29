function mono_res = adjustMonoSyn(MonoSynFile)
% Make adjustment to monoSynaptic connections.
% Limitation: can only deselect connections at this point
% 
% INPUT
% MonoSynFile : full path to monosyn mat file generated with 
% 
% Example call
% mono_res = adjustMonoSyn('Z:\peterp03\IntanData\MS13\Peter_MS13_171130_121758_concat\Kilosort_2017-12-14_170737\Peter_MS13_171130_121758_concat.mono_res.cellinfo.mat')

% By Peter Petersen
% petersen.peter@gmail.com
% 22-06-2019

load(MonoSynFile);

ccgR = mono_res.ccgR;
sig_con = mono_res.sig_con;
Pred = mono_res.Pred;
Bounds = mono_res.Bounds;
completeIndex = mono_res.completeIndex;
binSize = mono_res.binSize;
duration = mono_res.duration;

sig_con = bz_PlotMonoSyn(ccgR,sig_con,Pred,Bounds,completeIndex,binSize,duration);
mono_res.sig_con = sig_con;

save(MonoSynFile,'mono_res','-v7.3','-nocompression');
