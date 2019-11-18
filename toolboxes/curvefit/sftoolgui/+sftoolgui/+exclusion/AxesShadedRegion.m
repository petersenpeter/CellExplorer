classdef AxesShadedRegion < matlab.graphics.primitive.Data
    % AxesShadedRegion   Class which manages the background shading of an
    % axes for an exclusion rule.  The shaded background is broken down
    % into two quadrilaterals whose points are of the form (x, y, z) where
    % x, y, z \in {-inf, inf, c}, where c is the constraint boundary. These
    % quadrilaterals can then be projected onto the background when it
    % comes time to actually draw them.
    %
    % Example:
    %
    %    surf(a, peaks); grid(a, 'on'); box(a, 'on'); xlabel(a, 'x');
    %    ylabel(a, 'y'); zlabel(a, 'z');
    %
    %    sftoolgui.exclusion.AxesShadedRegion('x', '>', 10, 'Parent', a);
    %    sftoolgui.exclusion.AxesShadedRegion('y', '<', 10, 'Parent', a);
    %    sftoolgui.exclusion.AxesShadedRegion('z', '<=', -5, 'Parent', a);
    
    %   Copyright 2013-2014 The MathWorks, Inc.
    
    properties(SetAccess = private, GetAccess = private)
        ShadedRegion;
    end
    
    properties(SetAccess = private, GetAccess = public)
        VertexData

        % The value which the rule is limited by, i.e. for the rule x <= 5
        % the BoundaryValue is 5
        BoundaryValue
        
        % Axis value i.e. x, y or z
        Variable
        
        % Operator which may be >, <, >=, or <=
        Operator
    end
        
    properties(SetAccess = private, GetAccess = private)
        % RuleLimits contains the boundary in which the exclusion is valid
        % e.g. [-inf 10] or [0.5 inf]
        RuleLimits
        
        % VariableIndex contains an integer which represents the axis that the rule
        % corresponds to, i.e. x = 1, y = 2, z = 3
        VariableIndex
        
        
        % OtherAxes contains the other axes i.e. the set difference of Axis
        % and [1, 2, 3]
        OtherAxes
    end
    
    methods
        function this = AxesShadedRegion(varargin)
            % Create the quadrilaterals which will be the underlying
            % representation of the excluded area
            [variable, operator, boundary, parameterValuePairs] = iParseInputs(varargin{:});
            
            this = this@matlab.graphics.primitive.Data(parameterValuePairs{:});
            
            [lowerBound, upperBound] = iFindBoundsFromOperator(operator, boundary);
            this.RuleLimits = [lowerBound, upperBound];
            
            this.Variable = variable;
            this.Operator = operator;
            this.VariableIndex = iConvertFromVariableToVariableIndex(variable);
            this.OtherAxes = setdiff([1 2 3], this.VariableIndex);
            this.BoundaryValue = boundary;
            
            % Create and initialize the Face primitive.
            shadedRegion = matlab.graphics.primitive.world.Quadrilateral;
            
            this.ShadedRegion = shadedRegion;
            shadedRegion.ColorData = uint8([255; 0; 0; 30]);
            shadedRegion.ColorType = 'truecoloralpha';
            shadedRegion.ColorBinding = 'object';
            
            % We want to update everytime the DataSpace changes.
            this.addDependencyConsumed('view');
            this.addDependencyConsumed('xyzdatalimits');

            this.addNode(shadedRegion);
        end
        
        function doUpdate(this, updateState)
            % Get the current limits
            xLim = updateState.DataSpace.XLim(:);
            yLim = updateState.DataSpace.YLim(:);
            zLim = updateState.DataSpace.ZLim(:);
            lims = [xLim, yLim, zLim];
            
            % Do Rule limits and axes limits overlap?  If not, then we
            % should not draw any quads at all
            axisLimits = lims(:, this.VariableIndex);
            
            if iRangesOverlap(this.RuleLimits, axisLimits);
                this.ShadedRegion.VertexData = iCalculateShadedRegion(updateState, lims, this.VariableIndex, this.BoundaryValue, this.RuleLimits);
            else
                this.ShadedRegion.VertexData = iEmptyShadedRegion();
            end
        end
        
        function vertices = get.VertexData(this)
            vertices = this.ShadedRegion.VertexData;
        end
    end
end

function [lowerBound, upperBound] = iFindBoundsFromOperator(operator, value)
% iFindBoundsFromOperator   Given an operator and a value, what are the
% upper and lower bounds for the described region
if strncmp(operator, '<', 1)
    lowerBound = -inf;
    upperBound = value;
else
    lowerBound = value;
    upperBound = inf;
end
end

function dim = iConvertFromVariableToVariableIndex(variable)
convert.x = 1;
convert.y = 2;
convert.z = 3;

dim = convert.(variable);
end

function infiniteLimits = iClipNumberLineToAxesLimits(infiniteLimits, axesLimits)
% iClipNumberLineToAxesLimits   This function converts positive and
% negative infinite values to the real maximum and minimum values of an
% axis
%
% Example:
%
%     >> iClipNumberLineToAxesLimits([-inf, 5], [0 10])
%
%        ans = [0, 5]
infiniteLimits(infiniteLimits==-Inf) = axesLimits(1);
infiniteLimits(infiniteLimits==Inf) = axesLimits(2);

if axesLimits(1) > infiniteLimits(1)
    infiniteLimits(1) = axesLimits(1);
end

if axesLimits(2) < infiniteLimits(2)
    infiniteLimits(2) = axesLimits(2);
end

end

function transformedVertices = iTransformDataToWorldCoords(dataspace,vertices)
% iTransformDataToWorldCoords   Transform an Nx3 array of data values into
% a Nx3 array of world coordinates.

if strcmp(dataspace.isLinear,'on')
    % For a linear dataspace, the data values and coordinate values are the
    % same.
    transformedVertices = vertices;
else
    % In nonlinear cases, we have to ask the dataspace to transform.
    iter = matlab.graphics.axis.dataspace.IndexPointsIterator;
    iter.Vertices=vertices;
    transformedVertices=TransformPoints(dataspace,[],iter);
    transformedVertices = transformedVertices';
end
end

function transformedVertices = iTransformWorldToScreen(dataspace, camera, vertices)
% iTransformWorldToScreen   Transform an Nx3 array of world coordinates
% into an Nx3 array of screen coordinates.

dataspaceMatrix = dataspace.getMatrix;
viewMatrix = camera.GetViewMatrix;
projectionMatrix = camera.GetProjectionMatrix;
transformationMatrix = projectionMatrix * viewMatrix * dataspaceMatrix;

n = size(vertices,1);
transformedVertices = zeros(n,3);
for ix=1:n
    p = transformationMatrix*[vertices(ix,:),1]';
    w = p(4);
    if (w <= 0)
        transformedVertices(ix,:) = [nan nan nan];
    else
        transformedVertices(ix,:) = p(1:3) / w;
    end
end
end

function normals = iComputeQuadNormals(cameraVertices)
% iComputeQuadNormals   Compute the normal vectors of an array of
% coordinates, treating each 4 rows as a quadrilateral.
numQuads = size(cameraVertices, 1)/4;
normals = zeros(numQuads, 3);
for qix=1:numQuads
    v = cameraVertices(4*(qix-1)+(1:4)', :);
    if any(~isfinite(v(:)))
        normals(qix, :) = [0 0 0];
    else
        normals(qix, :) = cross(v(2, :)-v(1, :),v(4, :)-v(1, :));
    end
end
end

function vertices = iCalculateShadedRegion(updateState, limits, variableIndex, boundaryValue, ruleLimits)
limits(:, variableIndex) = iClipNumberLineToAxesLimits(ruleLimits, limits(:,variableIndex));

% Generate the 8 corners of the box
vertices = [
    limits(1,1), limits(1,2), limits(1,3);
    limits(2,1), limits(1,2), limits(1,3);
    limits(1,1), limits(2,2), limits(1,3);
    limits(2,1), limits(2,2), limits(1,3);
    limits(1,1), limits(1,2), limits(2,3);
    limits(2,1), limits(1,2), limits(2,3);
    limits(1,1), limits(2,2), limits(2,3);
    limits(2,1), limits(2,2), limits(2,3)
    ];
% Turn that into 6 quads, ensuring that the orientation of all of the quads
% is the same.
quads = [
    vertices(5,:); vertices(6,:); vertices(8,:); vertices(7,:);
    vertices(6,:); vertices(2,:); vertices(4,:); vertices(8,:);
    vertices(2,:); vertices(1,:); vertices(3,:); vertices(4,:);
    vertices(1,:); vertices(5,:); vertices(7,:); vertices(3,:);
    vertices(7,:); vertices(8,:); vertices(4,:); vertices(3,:);
    vertices(1,:); vertices(2,:); vertices(6,:); vertices(5,:)
    ];

quads = iRemoveConstraintPlane(variableIndex, boundaryValue, quads);

% Transform the data values of the quads into coordinate values. We'll use
% a subset of these for the VertexData of our Face primitive.
quadVertices = iTransformDataToWorldCoords(updateState.DataSpace, quads);
% Project world coordinates into screen coordinates
cameraVertices = iTransformWorldToScreen(updateState.DataSpace, updateState.Camera, quadVertices);
% Find the normal vector of each projected quad
normals = iComputeQuadNormals(cameraVertices);
% Get the Z coordinates of the normals.
quadNormalValueZ = normals(:, 3)';
% Select the quads whose normals' Z values match the sign of the
% dataspace's transform matrix.
if strcmp(updateState.DataSpace.isRightHanded, 'on')
    normalsToKeep = find(quadNormalValueZ < 0);
else
    normalsToKeep = find(quadNormalValueZ > 0);
end

% At this point, normalsToKeep contains the indices of the quads which are
% on the back side of the view. Note that this might be anywhere from 1
% quad (e.g. view(2)) to 5 quads in some perspective cases.

% Pull out the vertices of the back quads and use them as the vertex data
% on the Face primitive.
indices = repmat(4*(normalsToKeep-1), 4, 1)+repmat((1:4)', 1, numel(normalsToKeep));
vertices = single(quadVertices(indices(:), :)');
end

function overlap = iRangesOverlap(RuleLimits, axisLimits)
% iRangesOverlap   Checks to see whether two limits overlap with one
% another.  This function assumes that the limits inside each parameter are
% sorted in ascending order.
overlap = RuleLimits(1) < axisLimits(2) & RuleLimits(2) > axisLimits(1);
end

function quads = iRemoveConstraintPlane(variableIndex, boundaryValue, quads)
% iRemoveConstraintPlane   Find the quad which is constant in the boundary
% axis so that we can remove it.  This is the quad which lies parallel to
% the constraint plane.
reshapedQuads = reshape(quads, 4, 6, 3);
axisValues = reshapedQuads(:, :, variableIndex);
constraintPlane = all(axisValues == boundaryValue);

% Remove constraint plane
reshapedQuads(:, constraintPlane, :) = [];
numberOfQuadsRemoved = sum(constraintPlane);
quads = reshape(reshapedQuads, 4*(6-numberOfQuadsRemoved), 3);
end

function vertexData = iEmptyShadedRegion()
vertexData = single([]);
end

function [variable, operator, boundary, parameterValuePairs] = iParseInputs(varargin)
% This class can be constructed either with a rule defined as the first
% input or without.  We have to check whether the user has defined an odd
% number of parameters (i.e. a rule with parameter-value pairs) or an even
% number of parameters made up of parameter-value pair combinations.
if (mod(nargin, 2) == 1)
    variable = varargin{1};
    operator = varargin{2};
    boundary = varargin{3};
    parameterValuePairs = varargin(4:end);
else
    variable = 'x';
    operator = '<';
    boundary = 0;
    parameterValuePairs = varargin;
end
end