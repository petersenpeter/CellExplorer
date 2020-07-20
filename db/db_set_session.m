function [session,basename, basepath] = db_set_session(varargin)
% Loads a session from the database or defines paths for existing session struct
% INPUTS
% varargin described below
%
% OUTPUTS
% session :         session struct containing the db session info
% basename :        basename of the session
% basepath :        basepath of the session

% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 07-11-2019

p = inputParser;
% Inputs
addParameter(p,'sessionId',[],@isnumeric);  % DB numeric ID
addParameter(p,'sessionName',[],@isstr); % DB session name
addParameter(p,'session',[],@isstruct); % session struct (can be used to generate the paths)

% Parameters
addParameter(p,'saveMat',true,@islogical);      % Saves the session struct to a mat file
addParameter(p,'changeDir',true,@islogical);    % change directory to basepath?

parse(p,varargin{:})

sessionId = p.Results.sessionId;
sessionName = p.Results.sessionName;
session = p.Results.session;
saveMat = p.Results.saveMat;
changeDir = p.Results.changeDir;

if ~isempty(sessionId)
    sessions = db_load_sessions('sessionId',sessionId);
    if isempty(sessions)
        return
    end
elseif ~isempty(sessionName)
    sessions = db_load_sessions('sessionName',sessionName);
    if isempty(sessions)
        return
    end
else
    sessions{1} = session;
end
db_settings = db_load_settings;
defined_repositories = fieldnames(db_settings.repositories);

for i = 1:length(sessions)
    session = sessions{i};
    if ~isfield(session.general,'repositories') 
        warning('The repository has not been defined for the session.');
        return
    elseif ~contains(defined_repositories,{session.general.repositories{1}})
        warning(['The repository has not been defined. Please specify the path for ' session.general.repositories{1},' in db_local_repositories.m']);
        edit db_local_repositories.m
        return
    end
    
    basename = session.general.name;
    if strcmp(session.general.repositories{1},'NYUshare_Datasets')
        Investigator_name = strsplit(session.general.investigator,' ');
        path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
        basepath = fullfile(db_settings.repositories.(session.general.repositories{1}), path_Investigator,session.animal.name, session.general.name);
    elseif strcmp(session.general.repositories{1},'NYUshare_AllenInstitute')
        basepath = fullfile(db_settings.repositories.(session.general.repositories{1}), session.general.name);
    else
        basepath = fullfile(db_settings.repositories.(session.general.repositories{1}), session.animal.name, session.general.name);
    end
    
    session.general.baseName = basename;
    session.general.basePath =  basepath;
    if ~isfield(session.extracellular,'leastSignificantBit') || session.extracellular.leastSignificantBit==0
        disp('''session.extracellular.leastSignificantBit'' set to default for intan system = 0.195 µV/bit')
    	session.extracellular.leastSignificantBit = 0.195; % Intan system = 0.195 µV/bit
    end
    
    % Checking format of spike groups and electrode groups (must be of type cell)
    if isfield(session.extracellular,'spikeGroups') && isfield(session.extracellular.spikeGroups,'channels') && isnumeric(session.extracellular.spikeGroups.channels)
        session.extracellular.spikeGroups.channels = num2cell(session.extracellular.spikeGroups.channels,2);
    end
    if isfield(session.extracellular,'electrodeGroups') && isfield(session.extracellular.electrodeGroups,'channels') && isnumeric(session.extracellular.electrodeGroups.channels)
        session.extracellular.electrodeGroups.channels = num2cell(session.extracellular.electrodeGroups.channels,2)';
    end
    
    if changeDir
        try 
            disp(['Changing Matlab directory to session basepath: ' basepath])
            cd(basepath)
        catch
            error(['db_set_path: Unable to change directory to basepath: ', basepath])
        end
    end

    if saveMat
        [stat,mess]=fileattrib(fullfile(basepath, 'session.mat'));
        if stat==0
            try
                disp(['Saving ',basename,'.session.mat file to basepath'])
                save(fullfile(basepath, [basename,'.session.mat']),'session','-v7.3','-nocompression');
            catch
                warning(['Failed to save ',basename,'.session.mat. Location not available']);
            end
        elseif mess.UserWrite
            save(fullfile(basepath, [basename,'.session.mat']),'session','-v7.3','-nocompression');
        else
            warning(['Unable to write to ',basename,'.session.mat. No writing permissions.']);
        end
    end
    if length(sessions)>1
        sessions{i} = session;
        basepaths{i} = basepath;
        basenames{i} = basename;
    end
end
if length(sessions)>1
    session = sessions;
    basepath = basepaths;
    basename = basenames;
end
