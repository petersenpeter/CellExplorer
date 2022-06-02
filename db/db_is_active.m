function enableDatabase = db_is_active
    enableDatabase = false;
    if exist('db_load_settings','file')
        credentials = db_credentials;
        if ~strcmp(credentials.username,'user')
            enableDatabase = true;
        end
    end
end
