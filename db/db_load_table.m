function db_out = db_load_table(table,search_term)
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 17-06-2019

switch lower(table)
    % Project info
    case 'projects';                formidable_id = 128;
        
    % Session info
    case 'sessions';                formidable_id = 143;
    case 'behavioralparadigms';     formidable_id = 180;

    % Cell info
    case 'cells';                  formidable_id = 192;
        
    % Animal info
    case 'animals';                 formidable_id = 129;
    case 'surgeries';               formidable_id = 175;
    case 'probeimplants';           formidable_id = 152;
    case 'manipulationimplants';    formidable_id = 182;
    case 'opticfiberimplants';      formidable_id = 140;
    case 'virusinjections';         formidable_id = 132;
    case 'histology';               formidable_id = 165;
    case 'impedancemeasures';       formidable_id = 160;
    case 'weightings';              formidable_id = 183;
        
    % Personal info
    case 'mazes';                   formidable_id = 130;
    case 'equipment';               formidable_id = 131;
    case 'datarepositories';        formidable_id = 124;
        
    % General attributes
    case 'manipulationtypes';       formidable_id = 182;
    case 'brainregions';            formidable_id = 11;
    case 'mazetypes';               formidable_id = 16;
    case 'persons';                 formidable_id = 110;
    case 'laboratories';            formidable_id = 117;
    case 'siliconprobes';           formidable_id = 20;
    case 'species';                 formidable_id = 115;
    case 'strains';                 formidable_id = 9;
    case 'tasks';                   formidable_id = 85;
    case 'virusbatches';            formidable_id = 105;
    case 'virusconstructs';         formidable_id = 108;
    case 'crcnsdataset';            formidable_id = 101;
    case 'equipmentlist';           formidable_id = 80;
    case 'rewards';                 formidable_id = 86;
    case 'celltypes';               formidable_id = 103;
    case 'companies';               formidable_id = 104;
    case 'opticfibers';             formidable_id = 106;
    case 'microdrives';             formidable_id = 196;
    case 'microdriveadjustments';   formidable_id = 197;
end

db_out = [];
db_settings = db_load_settings;
options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','Get','Timeout',20);
options.CertificateFilename=('');

if nargin==1
    bz_db = webread([db_settings.address, 'forms/', num2str(formidable_id), '/entries'],options,'page_size','5000');
else
    bz_db = webread([db_settings.address,'forms/', num2str(formidable_id), '/entries'],options,'page_size','5000','search',search_term);
end

bz_db_names = webread([db_settings.address,'forms/', num2str(formidable_id), '/fields'],options);

if ~isempty(bz_db)
    entrylist = fields(bz_db);
    for j = 1:size(entrylist,1)
        fieldlist = fieldnames(bz_db.(entrylist{j}).meta);
        for i = 1:length(fieldlist)
            oldField = fieldlist{i};
            if strfind(oldField,'_value')
                oldField1 = fieldlist{i}(1:end-6);
                newField = [regexprep(regexprep(bz_db_names.(oldField1).name, '(?<=(^| ))(.)', '${upper($1)}'), '[- ?()]', ''),'_ID'];
            else
                newField = regexprep(regexprep(bz_db_names.(oldField).name, '(?<=(^| ))(.)', '${upper($1)}'), '[- ?()]', '');
                if isstruct(bz_db.(entrylist{j}).meta.(oldField))
                    
                end
            end
            [bz_db.(entrylist{j}).meta.(newField)] = bz_db.(entrylist{j}).meta.(oldField);
            bz_db.(entrylist{j}).meta = rmfield(bz_db.(entrylist{j}).meta,oldField);
            
        end
        if isvarname(bz_db.(entrylist{j}).meta.Name)
            if strcmp(lower(table),'animals')
                db_out.(bz_db.(entrylist{j}).meta.Name).General = bz_db.(entrylist{j}).meta;
                db_out.(bz_db.(entrylist{j}).meta.Name).General.Id = bz_db.(entrylist{j}).id;
                db_out.(bz_db.(entrylist{j}).meta.Name).General.EntryKey = entrylist{j};
            else
                label = ['id_', bz_db.(entrylist{j}).id];
                db_out.(label) = bz_db.(entrylist{j}).meta;
                db_out.(label).Id = bz_db.(entrylist{j}).id;
                db_out.(label).EntryKey = entrylist{j};
            end
        else
            warning(['Failed to entry as name is not a valid varname: ', bz_db.(entrylist{j}).meta.Name])
        end
        
    end
    disp([num2str(size(entrylist,1)),' entries in ', table])
    
    if strcmp(lower(table),'animals')
        disp('Loading additional info for animals')
        sublist = {'Surgeries', 'ProbeImplants','VirusInjections','OpticFiberImplants','Weightings','ImpedanceMeasures','Histology'};
        animallist = fieldnames(db_out);
        for ii = 1:length(sublist)
            if nargin==1
                db_out2 = db_load_table(sublist{ii});
            else
                db_out2 = db_load_table(sublist{ii},search_term);
            end
            if ~isempty(db_out2)
                fieldlist2 = fieldnames(db_out2);
                for iiii = 1:size(animallist,1)
                    for iii = 1:size(fieldnames(db_out2),1)
                        if strcmp(db_out2.(fieldlist2{iii}).Animal,animallist{iiii})
                            db_out.(animallist{iiii}).(sublist{ii}) = db_out2.(fieldlist2{iii});
                        end
                    end
                end
            end
        end
    end
end
