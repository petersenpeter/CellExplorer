function geometry = resolveGeometry(session)
%RESOLVEGEOMETRY Resolve effective channel coordinates without mutating metadata.
% Explicit session x/y take precedence, then channelInfo, chanMap, tagged map,
% and generated coordinates. File-derived coordinates are not copied to session.
basepath = session.general.basePath;
basename = session.general.name;
file = fullfile(basepath,[basename,'.chanCoords.channelInfo.mat']);
if isfield(session.extracellular,'chanCoords') && ...
        all(isfield(session.extracellular.chanCoords,{'x','y'})) && ...
        ~isempty(session.extracellular.chanCoords.x) && ~isempty(session.extracellular.chanCoords.y)
    coordinates = session.extracellular.chanCoords;
    source = 'session';
elseif isfile(file)
    data = load(file,'chanCoords'); coordinates = data.chanCoords;
    source = 'channelInfo';
elseif isfile(fullfile(basepath,'chanMap.mat'))
    data = load(fullfile(basepath,'chanMap.mat'),'xcoords','ycoords');
    coordinates = struct('x',data.xcoords,'y',data.ycoords);
    source = 'chanMap.mat';
elseif isfield(session,'analysisTags') && isfield(session.analysisTags,'chanMapFile') && ~isempty(session.analysisTags.chanMapFile)
    data = load(fullfile(basepath,session.analysisTags.chanMapFile),'xcoords','ycoords');
    coordinates = struct('x',data.xcoords,'y',data.ycoords);
    source = session.analysisTags.chanMapFile;
else
    coordinates = generateChanCoords(session);
    source = 'generated';
end
geometry.chanCoords = validateCoordinates(coordinates,{'x','y'},session.extracellular.nChannels,false);
geometry.source = source;
file = fullfile(basepath,[basename,'.ccf.channelInfo.mat']);
if isfile(file)
    data = load(file,'ccf');
    geometry.ccf = validateCoordinates(data.ccf,{'x','y','z'},session.extracellular.nChannels,true);
end
end

function coordinates = validateCoordinates(coordinates,axes,count,allowNaN)
for index = 1:numel(axes)
    name = axes{index};
    if ~isstruct(coordinates) || ~isscalar(coordinates) || ~isfield(coordinates,name)
        error('ce:pipeline:InvalidCoordinates','Channel coordinates require %s.',name);
    end
    value = coordinates.(name);
    if ~isnumeric(value) || ~isreal(value) || ~isvector(value) || numel(value) ~= count || ...
            any(isinf(value)) || (~allowNaN && any(isnan(value)))
        error('ce:pipeline:InvalidCoordinates','Channel coordinate %s must have one valid value per channel.',name);
    end
    coordinates.(name) = value(:);
end
end
