function schema
% Schema for interp object.

% Copyright 2001-2005 The MathWorks, Inc.

pk = findpackage('curvefit');

% Create a new class called interpoptions

schema.class(pk, 'interpoptions', pk.findclass('basefitoptions'));



