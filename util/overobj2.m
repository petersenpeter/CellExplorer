function h = overobj2(varargin)
% OVEROBJ2 Get handle of object that the pointer is over.
% By Yair Altman
% https://undocumentedmatlab.com/blog/undocumented-mouse-pointer-functions

% Ensure root units are pixels
oldUnits = get(0,'units');
set(0,'units','pixels');

% Get the figure beneath the mouse pointer & mouse pointer pos
try
    fig = get(0,'PointerWindow');  % HG1: R2014a or older
catch
    fig = matlab.ui.internal.getPointerWindow;  % HG2: R2014b or newer
end
p = get(0,'PointerLocation');
set(0,'units',oldUnits);

% Look for quick exit (if mouse pointer is not over any figure)
if fig==0,  h=[]; return;  end

% Compute figure offset of mouse pointer in pixels
figPos = getpixelposition(fig);
x = (p(1)-figPos(1));
y = (p(2)-figPos(2));

% Loop over all figure descendants
c = findobj(get(fig,'Children'),varargin{:});
try
    c = fig.Children(1).Children(2).Children(2).Children;
end
for h = c'
    % If descendant contains the mouse pointer position, exit
    r = getpixelposition(h);  % Note: cache this for improved performance
    if (x>r(1)) && (x<r(1)+r(3)) && (y>r(2)) && (y<r(2)+r(4))
        return
    end
end
h = [];
end