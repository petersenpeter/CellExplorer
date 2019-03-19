function cell_metrics = db_submit_cells(cell_metrics,session)
f_submit_cells = waitbar(0,'DB: Submitting cells to database');
% Database options
bz_database = db_credentials;
options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password); % 'ContentType','json','MediaType','application/json'
% options.CertificateFilename=('');

% Updating Session WithToggle
if isempty(session.analysisStats.cellMetrics) || ~strcmp(session.analysisStats.cellMetrics, '1')
    waitbar(0,f_submit_cells,['DB: Adjusting session toggle: ',session.general.name]);
    options2 = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    web_address2 = [bz_database.rest_api.address, 'entries/' session.general.entryID];
    webwrite(web_address2,options2,'form_id','143','session_cellmetrics',1);
    waitbar(0,f_submit_cells,'DB: Session updated succesfully.');
end

waitbar(0,f_submit_cells,'DB: Submitting cells to database');
db_cells = db_load_table('cells',cell_metrics.general.basename);

for j = 1:size(cell_metrics.sessionID,2)
    if ~ishandle(f_submit_cells)
        break
    end

    if isfield(cell_metrics, 'entryID') && length(cell_metrics.entryID) >= j && cell_metrics.entryID(j) > 0 && isfield(db_cells,['id_',num2str(cell_metrics.entryID(j))])
        dialog_text = ['DB: Submitting cells: Cell ' num2str(j),' (Updated)'];
        web_address1 = [bz_database.rest_api.address, 'entries/', num2str(cell_metrics.entryID(j))];
    else
        dialog_text = ['DB: Submitting cells: Cell ' num2str(j),'/',num2str(size(cell_metrics.sessionID,2)),' (New)'];
        web_address1 = [bz_database.rest_api.address, 'entries'];
    end
    
    waitbar(j/size(cell_metrics.sessionID,2),f_submit_cells,dialog_text);
    
    jsonStructure = [];
    jsonStructure.form_id = 192; % Form id of sessions
%     jsonStructure.ca5yu.form = 191; % Form id of spikeGroups repeatable section
%     jsonStructure.fiElD_2463 = length(sessionInfo.spikeGroups.groups); % nSpikeGroups
%     jsonStructure.user_id = 3;
%     jsonStructure.cell_sessionid2 = cell_metrics.sessionID(j);
%     jsonStructure.cell_spikesortingid2 = cell_metrics.spikeSortingID(j);
%     jsonStructure.cell_sortingid = cell_metrics.cellID(j);
%     jsonStructure.cell_cluid = cell_metrics.cluID(j);
%     jsonStructure.cell_uid = cell_metrics.UID(j);
%     jsonStructure.cell_spikecount = cell_metrics.spikeCount(j);
%     jsonStructure.cell_firingrate = cell_metrics.firingRate(j);
%     jsonStructure.cell_maxchannel = cell_metrics.maxWaveformCh(j);
%     jsonStructure.cell_spikegroup = cell_metrics.spikeGroup(j);
%     jsonStructure.cell_brainregion = cell_metrics.brainRegion{j};
%     jsonStructure.cell_refractoryperiodviolation = cell_metrics.refractoryPeriodViolation(j);
%     jsonStructure.cell_cv2 = cell_metrics.cv2(j);
%     jsonStructure.cell_tmi = cell_metrics.thetaModulationIndex(j);
%     jsonStructure.cell_burst_royer2012 = cell_metrics.burstIndex_Royer2012(j);
%     jsonStructure.cell_burst_mizuseki2012 = cell_metrics.burstIndex_Mizuseki2012(j);
%     jsonStructure.cell_peakvoltage = cell_metrics.peakVoltage(j);
%     jsonStructure.cell_troughtopeaklatency = cell_metrics.troughToPeak(j);
%     jsonStructure.cell_isolationdistance = cell_metrics.isolationDistance(j);
%     jsonStructure.cell_lratio = cell_metrics.lRatio(j);
%     jsonStructure.cell_putativecelltype = cell_metrics.putativeCellType{j};
%     jsonStructure.cell_ccg_tau_rise = cell_metrics.acg_tau_rise(j);
%     jsonStructure.cell_ccg_tau_decay = cell_metrics.acg_tau_decay(j);
%     jsonStructure.cell_deep_superficial = cell_metrics.deepSuperficial{j};
%     jsonStructure.cell_abratio = cell_metrics.ab_ratio(j);
%     jsonStructure.cell_ripple_peak_delay = cell_metrics.ripplePeakDelay(j);
%     jsonStructure.cell_synapticinputs = cell_metrics.synapticConnectionsIn(j);
%     jsonStructure.cell_synapticoutputs = cell_metrics.synapticConnectionsOut(j);
%     jsonStructure.cell_ripple_modulation = cell_metrics.rippleModulationIndex(j);
    jsonStructure.user_id = 3;
    jsonStructure.fiElD_2714 = cell_metrics.sessionID(j);
    jsonStructure.fiElD_2721 = cell_metrics.spikeSortingID(j);
    jsonStructure.fiElD_2472 = cell_metrics.cellID(j);
    jsonStructure.fiElD_2747 = cell_metrics.cluID(j);
    jsonStructure.fiElD_1000 = cell_metrics.UID(j);
    jsonStructure.fiElD_2748 = cell_metrics.spikeCount(j);
    jsonStructure.fiElD_2447 = cell_metrics.firingRate(j);
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
    jsonStructure.fiElD_2484 = cell_metrics.isolationDistance(j);
    jsonStructure.fiElD_2485 = cell_metrics.lRatio(j);
    jsonStructure.fiElD_2671 = cell_metrics.putativeCellType{j};
    jsonStructure.fiElD_2695 = cell_metrics.acg_tau_rise(j);
    jsonStructure.fiElD_2696 = cell_metrics.acg_tau_decay(j);
    jsonStructure.fiElD_2694 = cell_metrics.deepSuperficial{j};
    jsonStructure.fiElD_2698 = cell_metrics.ab_ratio(j);
    jsonStructure.fiElD_2699 = cell_metrics.ripplePeakDelay(j);
    jsonStructure.fiElD_2719 = cell_metrics.synapticConnectionsIn(j);
    jsonStructure.fiElD_2720 = cell_metrics.synapticConnectionsOut(j);
    jsonStructure.fiElD_2692 = cell_metrics.rippleModulationIndex(j);
    temp = fieldnames(jsonStructure);
    
    jsonStructure = rmfield(jsonStructure,temp(find(struct2array(structfun(@(x) any(isnan(x) | isinf(x)), jsonStructure,'UniformOutput', false)))));
    jsonStructure = jsonencode(jsonStructure);
    jsonStructure = strrep(jsonStructure,'fiElD_','');
    options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'MediaType','application/json','Timeout',30,'CertificateFilename','');
%     options.CertificateFilename=('');
    temp2 = webwrite(web_address1,jsonStructure,options);
    
    if isfield(temp2,'id')
        cell_metrics.entryID(j) = str2num(temp2.id);
    end
%     if isnan(cell_metrics.rippleModulationIndex(j)) || isinf(cell_metrics.rippleModulationIndex(j))
%         %             sutmitString = {'form_id',192,'user_id',3,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2',cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j),'cell_synapticinputs', cell_metrics.PutativeConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.PutativeConnectionsOut(j)};
%         temp = webwrite(web_address1,options,'form_id','192','user_id',3,'cell_sessionid2',cell_metrics.sessionID(j),'cell_spikesortingid2',cell_metrics.spikeSortingID(j),'cell_sortingid',cell_metrics.cellID(j),'cell_spikecount',cell_metrics.spikeCount(j),'cell_firingrate',cell_metrics.firingRate(j),'cell_maxchannel',cell_metrics.maxWaveformCh(j),'cell_spikegroup',cell_metrics.spikeGroup(j),'cell_brainregion',cell_metrics.brainRegion{j},'cell_refractoryperiodviolation',cell_metrics.refractoryPeriodViolation(j),'cell_cv2',cell_metrics.cv2(j),'cell_tmi',cell_metrics.thetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.burstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.burstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.peakVoltage(j),'cell_troughtopeaklatency',cell_metrics.troughToPeak(j),'cell_isolationdistance',cell_metrics.isolationDistance(j),'cell_lratio',cell_metrics.lRatio(j),'cell_putativecelltype',cell_metrics.putativeCellType{j},'cell_ccg_tau_rise',cell_metrics.acg_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.acg_tau_decay(j),'cell_deep_superficial',cell_metrics.deepSuperficial{j},'cell_abratio',cell_metrics.ab_ratio(j),'cell_ripple_peak_delay',cell_metrics.ripplePeakDelay(j),'cell_synapticinputs', cell_metrics.synapticConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.synapticConnectionsOut(j));
%     else
%         %             sutmitString = {'form_id',192,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2', cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j), 'cell_synapticinputs', cell_metrics.PutativeConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.PutativeConnectionsOut(j),'cell_ripple_modulation',cell_metrics.RippleModulationIndex(j)};
%         temp = webwrite(web_address1,options,'form_id',192,'cell_sessionid2',cell_metrics.sessionID(j),'cell_spikesortingid2', cell_metrics.spikeSortingID(j),'cell_sortingid',cell_metrics.cellID(j),'cell_spikecount',cell_metrics.spikeCount(j),'cell_firingrate',cell_metrics.firingRate(j),'cell_maxchannel',cell_metrics.maxWaveformCh(j),'cell_spikegroup',cell_metrics.spikeGroup(j),'cell_brainregion',cell_metrics.brainRegion{j},'cell_refractoryperiodviolation',cell_metrics.refractoryPeriodViolation(j),'cell_cv2',cell_metrics.cv2(j),'cell_tmi',cell_metrics.thetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.burstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.burstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.peakVoltage(j),'cell_troughtopeaklatency',cell_metrics.troughToPeak(j),'cell_isolationdistance',cell_metrics.isolationDistance(j),'cell_lratio',cell_metrics.lRatio(j),'cell_putativecelltype',cell_metrics.putativeCellType{j},'cell_ccg_tau_rise',cell_metrics.acg_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.acg_tau_decay(j),'cell_deep_superficial',cell_metrics.deepSuperficial{j},'cell_abratio',cell_metrics.ab_ratio(j),'cell_ripple_peak_delay',cell_metrics.ripplePeakDelay(j), 'cell_synapticinputs', cell_metrics.synapticConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.synapticConnectionsOut(j),'cell_ripple_modulation',cell_metrics.rippleModulationIndex(j));
%     end
end

if ishandle(f_submit_cells)
    waitbar(1,f_submit_cells,'DB: Submission complete');
    close(f_submit_cells)
end