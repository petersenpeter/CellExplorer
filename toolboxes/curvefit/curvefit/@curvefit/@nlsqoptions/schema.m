function schema
%Schema function for nlsqoptions object.

% Copyright 2001-2015 The MathWorks, Inc.

pk = findpackage('curvefit');
% Create a new class called nlsqoptions
c = schema.class(pk, 'nlsqoptions', pk.findclass('basefitoptions'));

if isempty(findtype('FitAlgorithm'))
  % The possible values of this EnumType are duplicated in FitOptions.java.
  % Be sure to update them there as well when changing them or their order.
  schema.EnumType('FitAlgorithm', {'Trust-Region', 'Levenberg-Marquardt','Gauss-Newton'});
end
if isempty(findtype('DispChoice'))
  schema.EnumType('DispChoice', {'Notify', 'Final','Iter', 'Off'});
end
if isempty(findtype('RobustOption'))
  % The possible values of this EnumType are duplicated in FitOptions.java.
  % Be sure to update them there as well when changing them or their order.
  schema.EnumType('RobustOption', {'On', 'Off','LAR', 'Bisquare'});
end

% Add properties
schema.prop(c, 'Robust', 'RobustOption');
schema.prop(c, 'StartPoint', 'NReals');
schema.prop(c, 'Lower', 'NReals');
schema.prop(c, 'Upper', 'NReals');

p = schema.prop(c, 'Algorithm', 'FitAlgorithm');
p.SetFunction = @setAlgorithm;

schema.prop(c, 'DiffMinChange', 'double'); 
schema.prop(c, 'DiffMaxChange', 'double'); 
schema.prop(c, 'Display', 'DispChoice');

% Jacobian field only used internally so turn PublicGet to off.
p = schema.prop(c, 'Jacobian', 'on/off');
p.AccessFlags.PublicGet = 'off';

schema.prop(c, 'MaxFunEvals', 'int32');
schema.prop(c, 'MaxIter', 'int32');
schema.prop(c, 'TolFun', 'double');
schema.prop(c, 'TolX', 'double');

% The rest of the properties are not used but kept for backwards
% compatibility
p = schema.prop(c, 'SubClassPropertyListeners', 'handle.listener vector');
p.AccessFlags.Serialize = 'off';
p.AccessFlags.PublicGet = 'off';
p.AccessFlags.PublicSet = 'off';
p.AccessFlags.Reset     = 'off';

p = schema.prop(c, 'PStartPoint', 'NReals');
p.AccessFlags.PublicGet = 'off';
p = schema.prop(c, 'PLower', 'NReals');
p.AccessFlags.PublicGet = 'off';
p = schema.prop(c, 'PUpper', 'NReals');
p.AccessFlags.PublicGet = 'off';
