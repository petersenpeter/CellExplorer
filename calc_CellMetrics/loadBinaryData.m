function data_out = loadBinaryData(varargin)
% loadBinaryData - Load data from a binary file.
%
% https://cellexplorer.org/datastructure/data-structure-and-format/#raw-data-file-format
%
% Example calls
% optitrack = loadOptitrack('session',session)
% optitrack = loadOptitrack('basepath',basepath,'basename',basename,'filenames',filenames)
% theta_maze = loadOptitrack('session',session,'dataName','theta_maze')
% linear_track = loadOptitrack('session',session,'dataName','linear_track')
%
%  Reading a subset of the data can be done in two different manners: either
%  by specifying start time and duration (more intuitive), or by indicating
%  the position and size of the subset in terms of number of samples per
%  channel (more accurate).
%
%  USAGE
%
%     data_out = loadBinaryData(varargin)

p = inputParser;

% General parameters
addParameter(p,'session', [], @isstruct); % The CellExplorer session struct
addParameter(p,'memmap',false,@islogical); % Boolean: make the data output a Matlab Memmap object 

% General file parameters
addParameter(p,'filename','',@isstr); % Full path and filename of the binary data
addParameter(p,'sr',[],@isnumeric); % Sampling rate
addParameter(p,'nChannels',[],@isnumeric); % Number of channels
addParameter(p,'precision',[],@isstr); % Numeric data type.

% Extra parameters related to filter and preprocessing
addParameter(p,'start',0,@isnumeric); % position to start reading (in s, default = 0)
addParameter(p,'duration',Inf,@isnumeric); % duration to read (in s, default = Inf)
addParameter(p,'offset',0,@isnumeric); % position to start reading (in samples per channel, default = 0)
addParameter(p,'samples',Inf,@isnumeric); % number of samples (per channel) to read (default = Inf)
addParameter(p,'channels',[],@isnumeric); % channels to read (default = all)
addParameter(p,'skip',0,@isnumeric); % number of bytes to skip after each value is read (default = 0)
addParameter(p,'downsample',1,@isnumeric); % factor by which to downample by (default = 1)

% Getting parameters
parse(p,varargin{:})    
parameters = p.Results;
session = parameters.session;

% Defining filename
if isempty(parameters.filename)
    if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
        parameters.filename = fullfile(session.general.basePath,session.extracellular.fileName);
    else
        parameters.filename = fullfile(session.general.basePath,[session.general.name,'.dat']);
    end    
end

% Sampling rate
if isempty(parameters.sr)
    parameters.sr = session.extracellular.sr;
end

% Number of channels
if isempty(parameters.nChannels)
    parameters.nChannels = session.extracellular.nChannels;
end

% Precision
if isempty(parameters.precision)
    parameters.precision = session.extracellular.precision;
end

% Channels to read
if isempty(parameters.channels)
    parameters.channels = 1:parameters.nChannels;
end

% Loading raw data
if parameters.memmap
    data_out = memmapfile(parameters.filename,'Format',parameters.precision,'writable',false);
%     data_out = rawData.Data;
else
    data_out = ce_LoadBinary(parameters.filename,'frequency',parameters.sr,'nChannels',parameters.nChannels,'precision',parameters.precision,...
        'start',parameters.start,'duration',parameters.duration,'offset',parameters.offset,'samples',parameters.samples,...
        'channels',parameters.channels,'skip',parameters.skip,'downsample',parameters.downsample);
end
