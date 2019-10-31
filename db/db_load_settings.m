function db_settings = db_load_settings
% function for loading local settings used for connecting to the Buzsakilab metadata-database
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 18-08-2019

% Server path
db_settings.address = 'https://buzsakilab.com/wp/wp-json/frm/v2/';

% Authentication info
db_settings.credentials = db_credentials;

% Local repositories
db_settings.repositories = db_local_repositories;
