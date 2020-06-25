function ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
% tight_subplot creates "subplot" axes with adjustable gaps and margins
% Pekka Kumpulainen 21.5.2012
% https://www.mathworks.com/matlabcentral/fileexchange/27991-tight_subplot-nh-nw-gap-marg_h-marg_w
if nargin<3; gap = .02; end
if nargin<4 || isempty(marg_h); marg_h = .05; end
if nargin<5; marg_w = .05; end
if numel(gap)==1
    gap = [gap gap];
end
if numel(marg_w)==1
    marg_w = [marg_w marg_w];
end
if numel(marg_h)==1
    marg_h = [marg_h marg_h];
end
axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh;
if axh<0 
    axh = 0.001;
end
axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;
py = 1-marg_h(2)-axh;

ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    for ix = 1:Nw
        ii = ii+1;
        ha(ii) = axes('Units','normalized','Position',[px py axw axh]); 
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end
ha = ha(:);

end

