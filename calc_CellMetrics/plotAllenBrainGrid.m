function plotAllenBrainGrid
% Function to plot grid from the Allen CCF. 
% Original function from allenCCF github repository
% Wire mesh data loaded from brainGridData.npy. 

mf = which('plotAllenBrainGrid.m');
brainGridData = readNPY(fullfile(fileparts(mf), 'brainGridData.npy'));
bp = 10.*double(brainGridData); 
bp(sum(bp,2)==0,:) = NaN; % when saved to uint16, NaN's become zeros. There aren't any real vertices at (0,0,0) and it shouldn't look much different if there were
% bp = bp+[0,-5700,-1000]; % -5700
% bp = bp+[0,-5700,-1000]; % -5700
ax = gca;
line(ax, bp(:,1), bp(:,2), bp(:,3), 'Color', [0 0 0 0.3], 'HitTest','off');
