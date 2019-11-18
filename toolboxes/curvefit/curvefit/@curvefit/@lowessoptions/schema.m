function schema
% Schema for lowessoptions object

% Copyright 2008-2015 The MathWorks, Inc.

pk = findpackage('curvefit');
c = schema.class(pk, 'lowessoptions', pk.findclass('basefitoptions'));

% A version number for this class with a name that won't clash with a
% version number of the super class.
p = schema.prop(c, 'LowessOptionsVersion', 'int'); 
p.AccessFlags.PublicGet = 'off';
p.AccessFlags.PublicSet = 'off';

if isempty(findtype('RobustOption'))
    % This is also defined in nlsqoptions and llsqoptions
  schema.EnumType('RobustOption', {'On', 'Off', 'LAR', 'Bisquare'});
end

schema.prop(c, 'Robust', 'RobustOption');

p = schema.prop(c, 'Span', 'double'); 
p.SetFunction = @checkSpan;
