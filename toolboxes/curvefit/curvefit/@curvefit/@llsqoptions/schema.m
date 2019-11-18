function schema
% Schema for llsqoptions object.

% Copyright 2001-2004 The MathWorks, Inc.

pk = findpackage('curvefit');
% Create a new class called llsqoptions
c = schema.class(pk, 'llsqoptions', pk.findclass('basefitoptions'));

if isempty(findtype('RobustOption'))
  % The possible values of this EnumType are duplicated in FitOptions.java.
  % Be sure to update them there as well when changing them or their order.
  schema.EnumType('RobustOption', {'On', 'Off', 'LAR', 'Bisquare'});
end

% Add properties
schema.prop(c, 'Robust', 'RobustOption');
schema.prop(c, 'Lower', 'NReals');
schema.prop(c, 'Upper', 'NReals');

% The rest of the properties are not used but kept for backwards
% compatibility
p = schema.prop(c, 'SubClassPropertyListeners', 'handle.listener vector');
p.AccessFlags.Serialize = 'off';
p.AccessFlags.PublicGet = 'off';
p.AccessFlags.PublicSet = 'off';
p.AccessFlags.Reset     = 'off';

p = schema.prop(c, 'PLower', 'NReals');
p.AccessFlags.PublicGet = 'off';
p = schema.prop(c, 'PUpper', 'NReals');
p.AccessFlags.PublicGet = 'off';


