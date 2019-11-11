function [session,basename, basepath,clusteringpath] = db_set_session(varargin)
% Loads a session from the database or defines paths for existing session struct
% INPUTS
% varargin described below
%
% OUTPUTS
% session :         session struct containing the db session info
% basename :        basename of the session
% basepath :        basepath of the session
% clusteringpath :  the path to the clustered data.

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
addParameter(p,'loadBuzcode',false,@islogical);  % Loads and saves select info from buzcode sessionInfo 

parse(p,varargin{:})

sessionId = p.Results.sessionId;
sessionName = p.Results.sessionName;
session = p.Results.session;
saveMat = p.Results.saveMat;
changeDir = p.Results.changeDir;
loadBuzcode = p.Results.loadBuzcode;

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
    if ~contains(defined_repositories,{session.general.repositories{1}})
        warning(['The repository has not been defined. Please specify the path for ' session.general.repositories{1},' in db_local_repositories.m']);
        edit db_local_repositories.m
        return
    end
    
    basename = session.general.name;
    if strcmp(session.general.repositories{1},'NYUshare_Datasets')
        Investigator_name = strsplit(session.general.investigator,' ');
        path_Investigator = [Investigator_name{2},Investigator_name{1}(1)];
        basepath = fullfile(db_settings.repositories.(session.general.repositories{1}), path_Investigator,session.animal.name, session.general.name);
    else
        basepath = fullfile(db_settings.repositories.(session.general.repositories{1}), session.animal.name, session.general.name);
    end
    
    if ~isempty(session.spikeSorting{1}.relativePath)
        clusteringpath = session.spikeSorting{1}.relativePath;
    else
        clusteringpath = '';
    end
    session.general.baseName = basename;
    session.general.basePath =  basepath;
    session.general.clusteringPath = clusteringpath;
    if ~isfield(session.extracellular,'leastSignificantBit') || session.extracellular.leastSignificantBit==0
        disp('''session.extracellular.leastSignificantBit'' set to default for intan system = 0.195 µV/bit')
    	session.extracellular.leastSignificantBit = 0.195; % Intan system = 0.195 µV/bit
    end
    
    if changeDir
        try 
            disp(['Changing Matlab directory to session basepath: ' basepath])
            cd(basepath)
        catch
            error(['db_set_path: Unable to change directory to basepath: ', basepath])
        end
    end
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    % Loading parameters from sessionInfo (Buzcode)
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    if loadBuzcode && exist('bz_getSessionInfo.m','file')
        sessionInfo = bz_getSessionInfo(session.general.basePath,'noPrompts',true);
        session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
        session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
        session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
        session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
        session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
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
        clusteringpaths{i} = clusteringpath;
        basenames{i} = basename;
    end
end
if length(sessions)>1
    session = sessions;
    basepath = basepaths;
    clusteringpath = clusteringpaths;
    basename = basenames;
end
