function db_submit_cells(cell_metrics)
% Database options
bz_database = db_credentials;
options = weboptions('Username',bz_database.rest_api.username,'Password',bz_database.rest_api.password,'ContentType','json', 'MediaType','application/json');
options.CertificateFilename=('');

% Get list of sessions tagged as spike sorted in database
% bz_db = webread('https://buzsakilab.com/wp/wp-json/frm/v2/views/15356/',options,'page_size','5000','sorted','1');
% sessions = loadjson(bz_db.renderedHtml);
% temo = cellfun(@(x) x.Name,sessions,'UniformOutput',false);

fprintf('\nDB: Submitting cells to database \n')

web_address1 = [bz_database.rest_api.address,'entries/'];
for j = 1:size(cell_metrics.SessionID,2)
    fprintf(['Cell ' num2str(j),',  '])
    if rem(j,10)==0
        printf('\n')
    end
    test = savejson(cell_metrics);
    if isnan(cell_metrics.RippleModulationIndex(j))
        sutmitString = {'form_id',192,'cell_sessionid',cell_metrics.SessionID(j),'cell_spikesortingid',cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j)};
        webwrite(web_address1,options,sutmitString);
        
    else
        sutmitString = {'form_id',192,'cell_sessionid',cell_metrics.SessionID(j),'cell_spikesortingid',cell_metrics.SpikeSortingID(j),'cell_sortingid',cell_metrics.CellID(j),'cell_spikecount',cell_metrics.SpikeCount(j),'cell_firingrate',cell_metrics.FiringRate(j),'cell_maxchannel',cell_metrics.MaxChannel(j),'cell_spikegroup',cell_metrics.SpikeGroup(j),'cell_brainregion',cell_metrics.BrainRegion{j},'cell_refractoryperiodviolation',cell_metrics.RefractoryPeriodViolation(j),'cell_cv2',cell_metrics.CV2(j),'cell_tmi',cell_metrics.ThetaModulationIndex(j),'cell_burst_royer2012',cell_metrics.BurstIndex_Royer2012(j),'cell_burst_mizuseki2012',cell_metrics.BurstIndex_Mizuseki2012(j),'cell_peakvoltage',cell_metrics.PeakVoltage(j),'cell_troughtopeaklatency',cell_metrics.TroughToPeak(j),'cell_isolationdistance',cell_metrics.IsolationDistance(j),'cell_lratio',cell_metrics.LRatio(j),'cell_putativecelltype',cell_metrics.PutativeCellType{j},'cell_ccg_tau_rise',cell_metrics.ACG_tau_rise(j),'cell_ccg_tau_decay',cell_metrics.ACG_tau_decay(j),'cell_deep_superficial',cell_metrics.DeepSuperficial{j},'cell_abratio',cell_metrics.AB_ratio(j),'cell_ripple_peak_delay',cell_metrics.RipplePeakDelay(j),'cell_ripple_modulation',cell_metrics.RippleModulationIndex(j)};
        webwrite(web_address1,options,[sutmitString(:)]);
    end
end
fprintf('\nDB: Submission complete \n')
