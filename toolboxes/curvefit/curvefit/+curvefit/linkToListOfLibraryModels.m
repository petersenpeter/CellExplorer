function link = linkToListOfLibraryModels( useHotlinks  )
% linkToListOfLibraryModels   Link to "List of Library Models for Curve and
% Surface Fitting" page in the documentation.
%
%   linkToListOfLibraryModels( useHotlinks ) is a link to "List of Library Models
%   for Curve and Surface Fitting" page in the documentation. If useHotlinks is
%   true then the link contains a hotlink. If useHotlinks is false then the link
%   just contains text and does contain a hotlink.
%
%   linkToListOfLibraryModels() checks to see if hotlinks are supported and
%   includes or doesn't include a hotlink based on that.

%   Copyright 2011 The MathWorks, Inc.

% If no arguments are given, then we use hotlinks only when they are supported
if ~nargin
    useHotlinks = feature( 'hotlinks' ) && ~isdeployed();
end

% The text is the message the user will see on screen.
text = getString( message( 'curvefit:curvefit:ListOfLibraryModelsForCurveAndSurfaceFitting' ) );

% The command is what get executed when the user clicks on the link
command = 'helpview( fullfile( docroot, ''toolbox'', ''curvefit'', ''curvefit.map'' ), ''cflibhelp'' );';

% If we need to use hotlinks, ...
if useHotlinks
    % ... then the text needs to be wrapped in an HREF to make the link
    link = sprintf( '<a href="matlab:%s">%s</a>', command, text );
else
    % ... otherwise the link is not a link and is just the text to be displayed on
    % screen.
    link = text;
end
end
