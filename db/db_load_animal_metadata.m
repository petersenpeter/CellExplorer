function db_animal_metadata = db_load_animal_metadata(animal_subject)

db_animal_metadata = {};
views_id.surgeries = 17639; % Database view IDs
views_id.opticfiberImplants = 17659;
views_id.virusInjections = 17663;
views_id.probeImplants = 17646;

db_tables = fieldnames(views_id);

% DB settings for public access
options = weboptions('RequestMethod','get','Timeout',50,'CertificateFilename','');
db_settings = db_load_settings;
for i = 1:numel(db_tables)
    disp(['Processing: ' db_tables{i}])
    db_settings.address_full = [db_settings.address,'views/',num2str(views_id.(db_tables{i})),'/'];
    if exist('animal_subject','var') && ~isempty(animal_subject)
        bz_db = webread(db_settings.address_full,options,'page_size','5000','animal',animal_subject);
    else
        bz_db = webread(db_settings.address_full,options,'page_size','5000');
    end
    if ~strcmp(bz_db.renderedHtml,'<div class="frm_no_entries">No Entries Found</div>')
        db_animal_metadata.(db_tables{i}) = loadjson(bz_db.renderedHtml);
    end
end
