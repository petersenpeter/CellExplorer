function subplot_advanced(x,y,z,w,new,titleIn)
if isempty('new')
    new = 1;
end
if y == 1
    if mod(z,x) == 1 & new
        figure('Name',titleIn,'pos',UI.settings.figureSize)
    end
    subplot(x,y,mod(z-1,x)+1)
else
    if (mod(z,x) == 1 || (z==x & z==1)) & w == 1
        figure('Name',titleIn,'pos',UI.settings.figureSize)
    end
    subplot(x,y,y*mod(z-1,x)+w)
end
end