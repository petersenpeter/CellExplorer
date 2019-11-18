function setIcon(hButton, File)
%setIcon sets a button's CDATA

%   HBUTTON is any uicontrol that uses CDATA property to display icons.
%   This was initially created with sftool toolbar buttons in mind, but may
%   later be modified to accept additional types. FILE is the fullpath to
%   the icon file.
%
%   It is assumed that the image file is a PNG (which contains only integer
%   datatypes).

%   Copyright 2009 The MathWorks, Inc.

% imread returns an empty alpha if 'BackgroundColor' is input, so call
% imread twice, once to get the alpha, once to get composite.
[~, ~, alpha] = imread(File);
RGB = imread(File, 'BackgroundColor', iBackgroundColor(hButton));

denom = double(intmax(class(RGB)));
RGB = double(RGB)./denom;

if ~isempty(alpha)
    alpha = double(alpha)./denom;
    
    % Then set areas which are "mostly" transparent to actually be NaN.
    % The threshold chosen for this balances the need to make the toolbar
    % images look correct when disabled with the need to have transparency
    % at all.
    % repmat alpha, which is a 16x16, to correspond to 16x16x3 RGB
    RGB(repmat(alpha<0.25,[1,1,3])) = NaN;
end

set(hButton, 'CData', RGB);
end

function bgcolor = iBackgroundColor(hButton)
% Find the background color
if isprop(hButton, 'BackgroundColor')
    % Use the HG-provided background color
    bgcolor = get(hButton, 'BackgroundColor');
else
    % Attempt to find the toolbar's color from swing.
    C = javax.swing.UIManager.getColor('ToolBar.background');
    if ~isempty(C)
        bgcolor = double(C.getRGBColorComponents([]))';
    else
        % Fall back to using a generic HG-provided value.
        bgcolor = get(hButton, 'DefaultUIControlBackgroundColor');
    end
end
end

