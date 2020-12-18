function [session,success] = db_create_session(session)
% Peter Petersen
% petersen.peter@gmail.com
% Last edited: 22-05-2020

% loading and defining db settings
db_settings = db_load_settings;
db_settings.web_address = [db_settings.address, 'entries/'];
success = 0;
% Creating session
if isfield(session.general,'name') && ~isempty(session.general.name)
    % Checking if session already exist
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'timeout',30);
    db_session = webread([db_settings.address,'views/15356/'],options,'page_size','5000','timeout',30,'session',session.general.name); 
    
    if strcmp(db_session.renderedHtml, '<div class="frm_no_entries">No Entries Found</div>')
        jsonStructure = [];
        jsonStructure.form_id = 143;
        jsonStructure.user_id = 3;
        jsonStructure.fiElD_1891 = session.general.name; % REQUIRED FIELD
        if ~isfield(session.animal,'id') || isempty(session.animal.id)
            if isfield(session.animal,'name')
                session.animal = db_create_animal(session.animal);
            end
        end
        jsonStructure.fiElD_2599 = session.animal.id; % REQUIRED FIELD
        if ~isfield(session.general,'notes') || isempty(session.general.notes)
            session.general.notes = '';
        end
        jsonStructure.fiElD_1902 = session.general.notes;
        
        if isfield(session.general,'date')
            jsonStructure.fiElD_1892 = session.general.date;
        end
        cluIDs = fieldnames(jsonStructure);
        jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
        if ~isfield(session.general,'date') || isempty(session.general.date)
            session.general.date = datetime('now','TimeZone','local','Format','y-MM-d');
        end
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        try
            RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
            session.general.entryID = RESPONSE.id; % Saving ID of created session in struct
            disp('Session submitted to db')
            success = 1;
        catch ME
            warning(ME.message)
            disp('Failed to submit session to db')
            success = -1;
        end
    else
        db_session = loadjson(db_session.renderedHtml); % Saving ID of created session in struct
        session.general.entryID = db_session{1}.id;
        disp('Session already exist')
    end
else
    warning('Please specify session name')
    success = -2;
end
