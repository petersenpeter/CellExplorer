function cell_metrics = db_submit_cells(cell_metrics,session)
% Database options
bz_database = db_credentials;
options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password); % 'ContentType','json','MediaType','application/json'
% options.CertificateFilename=('');

% Updating Session WithToggle
if isempty(session.AnalysisStats.CellMetrics) || ~strcmp(session.AnalysisStats.CellMetrics, '1')
    disp(['DB: Adjusting session toggle: ',session.General.Name])
    options2 = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password);
    web_address2 = [bz_database.rest_api.address, 'entries/' session.General.EntryID];
    webwrite(web_address2,options2,'form_id','143','session_cellmetrics',1);
    disp('DB: Session updated succesfully.')
end

fprintf('\nDB: Submitting cells to database \n')
db_cells = db_load_table('cells',cell_metrics.General.basename);

for j = 1:size(cell_metrics.SessionID,2)
    if isfield(cell_metrics, 'EntryID') && length(cell_metrics.EntryID) >= j && cell_metrics.EntryID(j) > 0 && isfield(db_cells,['id_',num2str(cell_metrics.EntryID(j))])
        fprintf('Updated:')
        web_address1 = [bz_database.rest_api.address, 'entries/', num2str(cell_metrics.EntryID(j))];
    else
        fprintf('New:')
        web_address1 = [bz_database.rest_api.address, 'entries'];
    end
    fprintf(['Cell ' num2str(j),', '])
    if rem(j,10)==0
        printf('\n')
    end
    if isnan(cell_metrics.RippleModulationIndex(j)) || isinf(cell_metrics.RippleModulationIndex(j))
        %             sutmitString = {'form_id',192,'user_id',3,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2',cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j),'cell_synapticinputs', cell_metrics.PutativeConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.PutativeConnectionsOut(j)};
        temp = webwrite(web_address1,options,'form_id','192','form_id',192,'user_id',3,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2',cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j),'cell_synapticinputs', cell_metrics.SynapticConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.SynapticConnectionsOut(j));
    else
        %             sutmitString = {'form_id',192,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2', cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j), 'cell_synapticinputs', cell_metrics.PutativeConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.PutativeConnectionsOut(j),'cell_ripple_modulation',cell_metrics.RippleModulationIndex(j)};
        temp = webwrite(web_address1,options,'form_id',192,'cell_sessionid2',cell_metrics.SessionID(j),'cell_spikesortingid2', cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j), 'cell_synapticinputs', cell_metrics.SynapticConnectionsIn(j), 'cell_synapticoutputs', cell_metrics.SynapticConnectionsOut(j),'cell_ripple_modulation',cell_metrics.RippleModulationIndex(j));
    end
    if isfield(temp,'id')
        cell_metrics.EntryID(j) = str2num(temp.id);
    end
end
% end
fprintf('\nDB: Submission complete \n')
