function session = db_create_animal(session,animals)
% Peter Petersen
% petersen.peter@gmail.com
% Last edited: 22-05-2020


% loading and defining db settings
db_settings = db_load_settings;
db_settings.web_address = [db_settings.address, 'entries/'];

% Creating session
if isfield(session.general,'name') && ~isempty(session.general.name)
    % Checking if animal already exist
    if ~exist('animals','var')
        animals = db_load_table('animals');
    end
    
    if ~isfield(animals,session.animal.name)
%         species = struct2cell(db_load_table('species'));
%         strains = struct2cell(db_load_table('strains'));
        
        jsonStructure = [];
        jsonStructure.form_id = 129;
        jsonStructure.user_id = 3;
        % Name
        jsonStructure.fiElD_1741 = session.animal.name; % REQUIRED FIELD
        % Sex
        if ~isfield(session.animal,'sex') || isempty(session.animal.sex)
            session.animal.sex = 'Male';
        end
        jsonStructure.fiElD_1742 = session.animal.sex;
        % Species
        if ~isfield(session.animal,'species') || isempty(session.animal.species)
            session.animal.species = 'Rat';
        end
%         temp = strcmp(cellfun(@(X) X.Species,species,'uni',0),session.animal.species);
        jsonStructure.fiElD_1743 = session.animal.species;
        
        % Strains
        if ~isfield(session.animal,'strain') || isempty(session.animal.strain)
            session.animal.strain = 'Long Evans';
        end
%         temp = strcmp(cellfun(@(X) X.Strain,strains,'uni',0),session.animal.strain);
        jsonStructure.fiElD_1744 = session.animal.strain;
        
        % Genetic line
        if ~isfield(session.animal,'geneticLine') || isempty(session.animal.geneticLine)
            session.animal.geneticLine = 'Wild type';
        end
        jsonStructure.fiElD_1745 = session.animal.geneticLine;
                
        cluIDs = fieldnames(jsonStructure);
        jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        try
            RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
            session.animal.id = RESPONSE.id; % Saving ID of created animal in struct
            disp('Animal subject submitted to db')
        catch ME
            warning(ME.message)
            disp('Failed to submit animal subject to db')
        end
    else
        session.animal.id = animals.(session.animal.name).General.Id;
        disp('animal subject already exist in database')
    end
else
    warning('Please specify animal name')
end
