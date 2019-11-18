function fulliconfile = iconPath(iconfile, location)
%iconPath returns a fullpath to an sftool icon file

%   ICONFILE is the name of an icon in the sftoolgui package icons
%   directory
%   LOCATION is 'sftool' (default not required), or 'matlab'

%   Copyright 2009 The MathWorks, Inc.

if nargin == 1
    location = 'sftool';
end

switch lower(location)
    case 'sftool'
        pathstr = fileparts(mfilename('fullpath'));
        fulliconfile = fullfile(pathstr, 'icons', iconfile);
    case 'matlab'
        fulliconfile = fullfile(matlabroot, 'toolbox', 'matlab', ...
            'icons', iconfile);
    otherwise
        error(message('curvefit:iconPath:InvalidLocation'));
end
end


