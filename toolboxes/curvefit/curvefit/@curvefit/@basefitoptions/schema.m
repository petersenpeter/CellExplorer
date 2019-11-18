function schema
% Schema for basefitoptions object.

% Copyright 2001-2013 The MathWorks, Inc.

pk = findpackage('curvefit');
% Create a new class called basefitoptions
c = schema.class(pk, 'basefitoptions');

if isempty(findtype('FitMethod'))
  % The possible values of this EnumType are duplicated in FitOptions.java.
  % Be sure to update them there as well when changing them or their order.
  schema.EnumType('FitMethod',{'None', 'SmoothingSpline',...
                    'NearestInterpolant','LinearInterpolant', ...
                    'PchipInterpolant','CubicSplineInterpolant', ...
                    'LinearLeastSquares','NonlinearLeastSquares', ...
                    'BiharmonicInterpolant', 'ThinPlateInterpolant', ...
                    'LowessFit'}); 
end
  
% Add properties
schema.prop(c, 'Normalize', 'on/off');
schema.prop(c, 'Exclude', 'NReals');
schema.prop(c, 'Weights', 'NReals');
p = schema.prop(c, 'Method', 'FitMethod');
p.AccessFlags.PublicSet = 'off';

% The rest of the properties are not used but kept for backwards
% compatibility
p = schema.prop(c, 'PropertyListeners', 'handle.listener vector');
p.AccessFlags.Serialize = 'off';
p.AccessFlags.PublicGet = 'off';
p.AccessFlags.PublicSet = 'off';
p.AccessFlags.Reset     = 'off';

p = schema.prop(c, 'PExclude', 'NReals');
p.AccessFlags.PublicGet = 'off';
p = schema.prop(c, 'PWeights', 'NReals');
p.AccessFlags.PublicGet = 'off';
