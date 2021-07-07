function labels = metrics_labels(list_metrics)
% Name and units of standard cell metrics
labels = {};
labels.UID = 'UID';
labels.ab_ratio = 'AB-ratio';
labels.acg_asymptote = 'ACG asymptote';
labels.acg_c = 'ACG c (decay amplitude constant)';
labels.acg_d = 'ACG d (rise amplitude constant)';
labels.acg_fit_rsquare = 'ACG fit r^2';
labels.acg_h = 'ACG h (burst_amplitude constant)';
labels.acg_refrac = 'ACG refractory period';
labels.acg_tau_burst = 'ACG \tau_{burst}';
labels.acg_tau_decay = 'ACG \tau_{decay}';
labels.acg_tau_rise = 'ACG \tau_{rise}';
labels.animal_num = 'Animal subject';
labels.batchIDs = 'Batch IDs';
labels.brainRegion_num = 'Brain region';
labels.burstIndex_Doublets = 'Burst index (doublets)';
labels.burstIndex_Mizuseki2012 = 'Burst index (Mizuseki 2012)';
labels.burstIndex_Royer2012 = 'Burst index (Royer 2012)';
labels.cellID = 'cell ID';
labels.cluID = 'clu ID';
labels.cv2 = 'CV_2';
labels.deepSuperficialDistance = ['Deep-Superficial distance (',char(181),'m)'];
labels.deepSuperficial_num = 'Deep-Superficial';
labels.electrodeGroup = 'Electrode group';
labels.entryID = 'Entry ID';
labels.firingRate = 'Firing rate (Hz)';
labels.firingRateISI = 'Firing rate from ISI (Hz)';
labels.geneticLine_num = 'Genetic line';
labels.animal_geneticLine_num = 'Genetic line';
labels.isolationDistance = 'Isolation distance';
labels.lRatio = 'L-ratio';
labels.labels_num = 'Labels';
labels.maxWaveformCh = 'Max waveform channel (0-indexed)';
labels.maxWaveformCh1 = 'Max waveform channel (1-indexed)';
labels.maxWaveformChannelOrder = 'max waveform channel (ordered by probe layout)';
labels.peakVoltage = ['Peak voltage (',char(181),'V)'];
labels.placeFieldsCount = 'Place fields count';
labels.polarity = 'Polarity of waveform';
labels.putativeCellType_num = 'Putative cell-type';
labels.refractoryPeriodViolation = ['Refractory period violation (',char(8240),')'];
labels.sessionID = 'Session ID';
labels.sessionName_num = 'Session name';
labels.sex_num = 'Animal sex';
labels.animal_sex_num = 'Animal sex';
labels.spatialCoherence = 'Spatial coherence';
labels.spatialCoverageIndex = 'Spatial Coverage index';
labels.spatialGiniCoeff = 'Spatial Gini coefficient';
labels.spatialPeakRate = 'Spatial peak firing rate (Hz)';
labels.spatialSplitterDegree = 'spatialSplitterDegree';
labels.species_num = 'Animal species';
labels.animal_species_num = 'Animal species';
labels.spikeCount = 'Spike count';
labels.spikeGroup = 'Spike group';
labels.spikeSortingID = 'Spike sorting ID';
labels.strain_num = 'Animal strain';
labels.animal_strain_num = 'Animal strain';
labels.synapticConnectionsIn = 'Synaptic connections (inbound)';
labels.synapticConnectionsOut = 'Synaptic connections (outbound)';
labels.synapticEffect_num = 'Synaptic effect';
labels.thetaEntrainment = 'Theta entrainment';
labels.thetaModulationIndex = 'Theta modulation index';
labels.thetaPhasePeak = 'Theta phase peak';
labels.thetaPhaseTrough = 'Theta phase trough';
labels.troughToPeak = 'Trough-to-peak (ms)';
labels.troughtoPeakDerivative = 'Trough-to-peak (derivative; ms)';

% Adding missing cell metrics labels
missingLabels = setdiff(list_metrics,fieldnames(labels));
for i = 1:numel(missingLabels)
    if contains(missingLabels{i},'_num')
        labels.(missingLabels{i}) = missingLabels{i}(1:end-4);
    else
        labels.(missingLabels{i}) = missingLabels{i};
    end
end
