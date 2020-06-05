function animal = db_create_animal(animal,animals)
% Peter Petersen
% petersen.peter@gmail.com
% Last edited: 22-05-2020


% loading and defining db settings
db_settings = db_load_settings;
db_settings.web_address = [db_settings.address, 'entries/'];

% Creating animal subject
if isfield(animal,'name') && ~isempty(animal.name)
    % Checking if animal already exist
    if ~exist('animals','var')
        animals = db_load_table('animals',[],0);
    end
    if ~isfield(animals,['animal_',animal.name])
        jsonStructure = [];
        jsonStructure.form_id = 129;
        jsonStructure.user_id = 3;
        
        % Name
        jsonStructure.fiElD_1741 = animal.name; % REQUIRED FIELD
        
        % Sex
        if ~isfield(animal,'sex') || isempty(animal.sex)
            animal.sex = 'Male';
        end
        jsonStructure.fiElD_1742 = animal.sex;
        
        % Species
        if ~isfield(animal,'species') || isempty(animal.species)
            animal.species = 'Rat';
        end
        
        jsonStructure.fiElD_1743 = animal.species;
        
        % Strains
        if ~isfield(animal,'strain') || isempty(animal.strain)
            animal.strain = 'Long Evans';
        end

        jsonStructure.fiElD_1744 = animal.strain;
        
        % Genetic line
        if ~isfield(animal,'geneticLine') || isempty(animal.geneticLine)
            animal.geneticLine = 'Wild type';
        end
        jsonStructure.fiElD_1745 = animal.geneticLine;
        
        % Birth date (optional)
        if isfield(animal,'birthDate') && ~isempty(animal.birthDate)
            jsonStructure.fiElD_1746 = animal.birthDate;
        end
        
        % Death date (optional)
        if isfield(animal,'deathDate') && ~isempty(animal.deathDate)
            jsonStructure.fiElD_1747 = animal.deathDate;
        end

        % Investigators (optional)
        if isfield(animal,'investigators_id') && ~isempty(animal.investigators_id)
            jsonStructure.fiElD_2595 = animal.investigators_id;
        elseif isfield(animal,'investigators') && ~isempty(animal.investigators)
            persons = struct2cell(db_load_table('persons'));
            temp = strcmp(cellfun(@(X) X.FullName,persons,'uni',0),animal.investigators);
            if any(temp)
                ids = [];
                idx = find(temp);
                for j = 1:sum(temp)
                    ids = [ids,str2double(persons{idx(j)}.Id)];
                end
                animal.investigators_id = ids;
                jsonStructure.fiElD_2595 = animal.investigators_id;
            end
        end
                
        % Projects (optional)
        if isfield(animal,'projects_id') && ~isempty(animal.projects_id)
            jsonStructure.fiElD_2355 = animal.projects_id;
        elseif isfield(animal,'investigators') && ~isempty(animal.investigators)
            projects = struct2cell(db_load_table('projects'));
            temp = strcmp(cellfun(@(X) X.TitleOfTheDataset,projects,'uni',0),animal.projects);
            if any(temp)
                ids = [];
                idx = find(temp);
                for j = 1:sum(temp)
                    ids = [ids,str2double(projects{idx(j)}.Id)];
                end
                animal.projects_id = ids;
                jsonStructure.fiElD_2355 = animal.projects_id;
            end
        end
        
        % Laboratory (optional)
        if isfield(animal,'laboratory_id') && ~isempty(animal.laboratory_id)
            jsonStructure.fiElD_2394 = animal.laboratory_id;
        elseif isfield(animal,'laboratory') && ~isempty(animal.laboratory)
            laboratories = struct2cell(db_load_table('laboratories'));
            temp = strcmp(cellfun(@(X) X.Laboratory,laboratories,'uni',0),animal.laboratory);
            if any(temp)
                animal.projects_id = str2double(laboratories{temp}.Id);
                jsonStructure.fiElD_2394 = animal.laboratory_id;
            end
        end
        
        cluIDs = fieldnames(jsonStructure);
        jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
        jsonStructure = jsonencode(jsonStructure);
        jsonStructure = strrep(jsonStructure,'fiElD_','');
        options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
        try
            RESPONSE = webwrite(db_settings.web_address,jsonStructure,options);
            animal.id = RESPONSE.id; % Saving ID of created animal in struct
            disp('Animal subject submitted to db')
        catch ME
            warning(ME.message)
            disp('Failed to submit animal subject to db')
        end
    else
        animal.id = animals.(['animal_',animal.name]).General.Id;
        disp('Animal subject already exist in database')
    end
else
    warning('Please specify animal name')
end
