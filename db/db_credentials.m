function bz_database = db_credentials
% Credentials and local settings used for connecting to the Buzsakilab metadata-database
%
% v1.2 (2018-06-07)
%
% By Peter Petersen
% petersen.peter@gmail.com

% REST API authentication info
bz_database.rest_api.username = 'user';
bz_database.rest_api.password = 'password';
bz_database.rest_api.address = 'https://buzsakilab.com/wp/wp-json/frm/v2/';

% Path to data repositories in the database
bz_database.repositories.NYUshare_Peter = 'Z:\Buzsakilabspace\PeterPetersen\IntanData';
bz_database.repositories.NYUshare_Viktor = 'Z:\Buzsakilabspace\ViktorVarga\Analysis';
bz_database.repositories.NYUshare_Datasets = 'Z:\Buzsakilabspace\Datasets';
bz_database.repositories.Peter_DataDrive1 = 'F:\IntanData';


