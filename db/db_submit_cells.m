function cell_metrics = db_submit_cells(cell_metrics,session)
% Submit cell metrics to the Buzsaki lab database
% 
% INPUTS
% cell_metrics: 
% session: 
%
% OUTPUT
% cell_metrics: entryID for each cell is saved to the cell_metrics struct

% By Peter Petersen
% petersen.peter@gmail.com

% TODO
% Check for existing cells for a given spike session in case the local cell metrics
% has been deleted to avoid resubmission of the same cells.

f_submit_cells = waitbar(0,'DB: Submitting cells to database','Name',session.general.name);

% Database options
db_settings = db_load_settings;
options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password); % 'ContentType','json','MediaType','application/json'

% Updating Session with toggle
if ~isfield(session.spikeSorting{1},'cellMetrics') || isempty(session.spikeSorting{1}.cellMetrics) || ~strcmp(session.spikeSorting{1}.cellMetrics, '1')
    waitbar(0,f_submit_cells,['DB: Adjusting cell metrics toggle']);
    web_address1 = [db_settings.address,'entries/', num2str(cell_metrics.spikeSortingID(1))];
    webwrite(web_address1,options,'session_cellmetrics',1);
end

% Updating spike count for the selected sorting session
web_address1 = [db_settings.address,'entries/', num2str(cell_metrics.spikeSortingID(1))];

webwrite(web_address1,options,'session_cell_count',cell_metrics.general.cellCount);

waitbar(0,f_submit_cells,'DB: Submitting cells to database');
% Requesting db list
db_cells = webread([db_settings.address,'views/16737/'],options,'page_size','5000','sorted','1','spikeSorting',session.spikeSorting{1}.entryID); % session.spikeSorting{1}.entryID
if ~strcmp(db_cells.renderedHtml,'<div class="frm_no_entries">No Entries Found</div>')
    db_cells = loadjson(db_cells.renderedHtml);
    cluIDs2  = cellfun(@(X) (X.cluID), db_cells,'UniformOutput', true);
    entryIDs2  = cellfun(@(X) (X.id), db_cells,'UniformOutput', true);
else
    db_cells = [];
    cluIDs2 = [];
end
% db_cells = db_load_table('cells',cell_metrics.general.basename);
% if ~isempty(db_cells) & length(fieldnames(db_cells))>0
%     cluIDs  = cellfun(@(X) (X.cluID), db_cells,'UniformOutput', true);
%     entryIDs  = cellfun(@(X) (X.id), db_cells,'UniformOutput', true);
%     fieldnames(db_cells);
% else
%     cluIDs = [];
% end

for j = 1:size(cell_metrics.sessionID,2)
    if ~ishandle(f_submit_cells)
        break
    end
    if isfield(cell_metrics, 'entryID') && length(cell_metrics.entryID) >= j && cell_metrics.entryID(j) > 0 %&& isfield(db_cells,['id_',num2str(cell_metrics.entryID(j))])
        dialog_text = ['DB: Submitting cells: Cell ' num2str(j),' (Updated)'];
        web_address1 = [db_settings.address, 'entries/', num2str(cell_metrics.entryID(j))];
    elseif any( cluIDs2 == cell_metrics.cluID(j))
        temp_entryID = entryIDs2{find(cluIDs2 == cell_metrics.cluID(j))};
        dialog_text = ['DB: Submitting cells: Cell ' num2str(j),' (Updated)'];
        cell_metrics.entryID(j) = str2num(temp_entryID(4:end));
        web_address1 = [db_settings.address, 'entries/', temp_entryID(4:end)];
    else
        dialog_text = ['DB: Submitting cells: Cell ' num2str(j),'/',num2str(size(cell_metrics.sessionID,2)),' (New)'];
        web_address1 = [db_settings.address, 'entries'];
    end
    
    waitbar(j/size(cell_metrics.sessionID,2),f_submit_cells,dialog_text);
    
    jsonStructure = [];
    jsonStructure.form_id = 192;
    jsonStructure.user_id = 3;
    jsonStructure.fiElD_2714 = cell_metrics.sessionID(j);
    jsonStructure.fiElD_2721 = cell_metrics.spikeSortingID(j);
    jsonStructure.fiElD_2472 = cell_metrics.cellID(j);
    jsonStructure.fiElD_2747 = cell_metrics.cluID(j);
    jsonStructure.fiElD_1000 = cell_metrics.UID(j);
    jsonStructure.fiElD_2475 = cell_metrics.spikeCount(j);
    jsonStructure.fiElD_2476 = cell_metrics.firingRate(j);
    jsonStructure.fiElD_2478 = cell_metrics.maxWaveformCh(j);
    jsonStructure.fiElD_2477 = cell_metrics.spikeGroup(j);
    jsonStructure.fiElD_2672 = cell_metrics.brainRegion{j};
    jsonStructure.fiElD_2483 = cell_metrics.refractoryPeriodViolation(j);
    jsonStructure.fiElD_2676 = cell_metrics.cv2(j);
    jsonStructure.fiElD_2689 = cell_metrics.thetaModulationIndex(j);
    jsonStructure.fiElD_2690 = cell_metrics.burstIndex_Royer2012(j);
    jsonStructure.fiElD_2691 = cell_metrics.burstIndex_Mizuseki2012(j);
    jsonStructure.fiElD_2479 = cell_metrics.peakVoltage(j);
    jsonStructure.fiElD_2480 = cell_metrics.troughToPeak(j);
    if isfield(cell_metrics,'isolationDistance')
        jsonStructure.fiElD_2484 = cell_metrics.isolationDistance(j);
        jsonStructure.fiElD_2485 = cell_metrics.lRatio(j);
    end
    jsonStructure.fiElD_2671 = cell_metrics.putativeCellType{j};
    jsonStructure.fiElD_2695 = cell_metrics.acg_tau_rise(j);
    jsonStructure.fiElD_2696 = cell_metrics.acg_tau_decay(j);
    jsonStructure.fiElD_2694 = cell_metrics.deepSuperficial{j};
    jsonStructure.fiElD_2698 = cell_metrics.ab_ratio(j);
    if isfield(cell_metrics,'ripplePeakDelay')
        jsonStructure.fiElD_2699 = cell_metrics.ripplePeakDelay(j);
        jsonStructure.fiElD_2692 = cell_metrics.rippleModulationIndex(j);
    end
    jsonStructure.fiElD_2719 = cell_metrics.synapticConnectionsIn(j);
    jsonStructure.fiElD_2720 = cell_metrics.synapticConnectionsOut(j);
    cluIDs = fieldnames(jsonStructure);
    
    jsonStructure = rmfield(jsonStructure,cluIDs(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
    jsonStructure = jsonencode(jsonStructure);
    jsonStructure = strrep(jsonStructure,'fiElD_','');
    options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
    entryIDs = webwrite(web_address1,jsonStructure,options);
    
    if isfield(entryIDs,'id')
        cell_metrics.entryID(j) = str2double(entryIDs.id);
    end
end

if ishandle(f_submit_cells)
    waitbar(1,f_submit_cells,'DB: Submission complete');
    close(f_submit_cells)
end