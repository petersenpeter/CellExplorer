function db_load_metadata_model

db_metadata_model = {};
db_metadata_model.views_id.opticfibers = 17619;
db_metadata_model.views_id.equipment = 17622;
db_metadata_model.views_id.suppliers = 17624;
db_metadata_model.views_id.probes = 16742;
db_metadata_model.views_id.species = 17628;
db_metadata_model.views_id.strains = 17630;
% db.virusconstructs = {};
% db.people = {};
% db.laboratories = {};

% db.environmenttypes = {};
% db.tasks = {};
% db.stimuli = {};

db_tables = fieldnames(db_metadata_model.views_id);

% DB settings for public access
options = weboptions('RequestMethod','get','Timeout',50,'CertificateFilename','');
db_settings = db_load_settings;
for i = 1:numel(db_tables)
    disp(['Processing: ' db_tables{i}])
    db_settings.address_full = [db_settings.address,'views/',num2str(db_metadata_model.views_id.(db_tables{i})),'/'];
    bz_db = webread(db_settings.address_full,options,'page_size','5000');
    db_metadata_model.(db_tables{i}) = loadjson(bz_db.renderedHtml);
end
[db_path,~,~] = fileparts(which('db_load_sessions.m'));
try
    save(fullfile(db_path,'db_metadata_model.mat'),'db_metadata_model');
    disp('Saved db metadata model')
catch
    warning('failed to save db metadata model');
end
% db_tables = fieldnames(db);
% for i = 1:numel(db_tables)
%     disp(['Downloading entries: ' db_tables{i}]);
%     db.db_tables{i}.entries = db_load_table(db_tables{i});
% end
