function db = db_load_sessionlist
    if exist('db_load_settings','file')
        db_settings = db_load_settings;
        db = {};
        if ~strcmp(db_settings.credentials.username,'user')
            waitbar_message = 'Downloading session list. Hold on for a few seconds...';
            % DB settings for authorized users
            options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'RequestMethod','get','Timeout',50,'CertificateFilename',''); % ,'ArrayFormat','json','ContentType','json'
            db_settings.address_full = [db_settings.address,'views/15356/'];
        else
            waitbar_message = 'Downloading public session list. Hold on for a few seconds...';
            % DB settings for public access
            options = weboptions('RequestMethod','get','Timeout',50,'CertificateFilename','');
            db_settings.address_full = [db_settings.address,'views/16777/'];
            disp(['Loading public list. Please provide your BuzLabDB credentials in ''db\_credentials.m'' ']);
        end

        % Show waitbar while loading DB
%         if isfield(UI,'panel')
            ce_waitbar = waitbar(0,waitbar_message,'name','Loading metadata from DB','WindowStyle', 'modal');
%         else
%             ce_waitbar = [];
%         end

        % Requesting db list
        bz_db = webread(db_settings.address_full,options,'page_size','5000','sorted','1','cellmetrics',1);
        if ~isempty(bz_db.renderedHtml)
            db.sessions = loadjson(bz_db.renderedHtml);
            db.refreshTime = datetime('now','Format','HH:mm:ss, d MMMM, yyyy');

            % Generating list of sessions
            [db.sessionName,db.index] = sort(cellfun(@(x) x.name,db.sessions,'UniformOutput',false));
            db.ids = cellfun(@(x) x.id,db.sessions,'UniformOutput',false);
            db.ids = db.ids(db.index);
            db.animals = cellfun(@(x) x.animal,db.sessions,'UniformOutput',false);
            db.species = cellfun(@(x) x.species,db.sessions,'UniformOutput',false);
            for i = 1:size(db.sessions,2)
                if ~isempty(db.sessions{i}.behavioralParadigm)
                    db.behavioralParadigm{i} = strjoin(db.sessions{i}.behavioralParadigm,', ');
                else
                    db.behavioralParadigm{i} = '';
                end
                if ~isempty(db.sessions{i}.brainRegion)
                    db.brainRegion{i} = strjoin(db.sessions{i}.brainRegion,', ');
                else
                    db.brainRegion{i} = '';
                end
            end
            db.investigator = cellfun(@(x) x.investigator,db.sessions,'UniformOutput',false);
            db.repository = cellfun(@(x) x.repositories{1},db.sessions,'UniformOutput',false);
            db.cells = cellfun(@(x) num2str(x.spikeSorting.cellCount),db.sessions,'UniformOutput',false);

            db.values = cellfun(@(x) x.id,db.sessions,'UniformOutput',false);
            db.values = db.values(db.index);
            db.sessionName2 = strcat(db.sessionName);
            sessionEnumerator = cellstr(num2str([1:length(db.sessionName2)]'))';
            db.sessionList = strcat(sessionEnumerator,{' '},db.sessionName2,{' '},db.cells(db.index),{' '},db.animals(db.index),{' '},db.behavioralParadigm(db.index),{' '},db.species(db.index),{' '},db.investigator(db.index),{' '},db.repository(db.index),{' '},db.brainRegion(db.index));

            % Promt user with a table with sessions
            if ishandle(ce_waitbar)
                close(ce_waitbar)
            end
            db.dataTable = {};
            db.dataTable(:,2:10) = [sessionEnumerator;db.sessionName2;db.cells(db.index);db.animals(db.index);db.species(db.index);db.behavioralParadigm(db.index);db.investigator(db.index);db.repository(db.index);db.brainRegion(db.index)]';
            db.dataTable(:,1) = {false};
            [db_path,~,~] = fileparts(which('db_load_sessions.m'));
            try
                save(fullfile(db_path,'db_cell_metrics_session_list.mat'),'db');
            catch
                warning('failed to save session list with metrics');
            end
        else
            warndlg('Failed to load sessions from database');
        end
    else
        disp('BuzLabDB tools not installed');
        msgbox({'BuzLabDB tools not installed. To install, follow the steps below: ','1. Go to the CellExplorer GitHub webpage','2. Download the BuzLabDB tools', '3. Add the db directory to your Matlab path', '4. Optionally provide your credentials in db\_credentials.m and try again.'},createStruct);
    end
end