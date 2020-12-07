function UI = metrics_labels(UI)
% Name and units of standard cell metrics
UI.labels.UID = 'UID';
UI.labels.ab_ratio = 'AB-ratio';
UI.labels.acg_asymptote = 'ACG asymptote';
UI.labels.acg_c = 'ACG c (decay amplitude constant)';
UI.labels.acg_d = 'ACG d (rise amplitude constant)';
UI.labels.acg_fit_rsquare = 'ACG fit r^2';
UI.labels.acg_h = 'ACG h (burst_amplitude constant)';
UI.labels.acg_refrac = 'ACG refractory period';
UI.labels.acg_tau_burst = 'ACG \tau_{burst}';
UI.labels.acg_tau_decay = 'ACG \tau_{decay}';
UI.labels.acg_tau_rise = 'ACG \tau_{rise}';
UI.labels.animal_num = 'Animal subject';
UI.labels.batchIDs = 'Batch IDs';
UI.labels.brainRegion_num = 'Brain region';
UI.labels.burstIndex_Doublets = 'Burst index (doublets)';
UI.labels.burstIndex_Mizuseki2012 = 'Burst index (Mizuseki 2012)';
UI.labels.burstIndex_Royer2012 = 'Burst index (Royer 2012)';
UI.labels.cellID = 'cell ID';
UI.labels.cluID = 'clu ID';
UI.labels.cv2 = 'CV_2';
UI.labels.deepSuperficialDistance = ['Deep-Superficial distance (',char(181),'m)'];
UI.labels.deepSuperficial_num = 'Deep-Superficial';
UI.labels.electrodeGroup = 'Electrode group';
UI.labels.entryID = 'Entry ID';
UI.labels.firingRate = 'Firing rate (Hz)';
UI.labels.firingRateISI = 'Firing rate from ISI (Hz)';
UI.labels.geneticLine_num = 'Genetic line';
UI.labels.animal_geneticLine_num = 'Genetic line';
UI.labels.isolationDistance = 'Isolation distance';
UI.labels.lRatio = 'L-ratio';
UI.labels.labels_num = 'Labels';
UI.labels.maxWaveformCh = 'Max waveform channel (0-indexed)';
UI.labels.maxWaveformCh1 = 'Max waveform channel (1-indexed)';
UI.labels.maxWaveformChannelOrder = 'max waveform channel (ordered by probe layout)';
UI.labels.peakVoltage = ['Peak voltage (',char(181),'V)'];
UI.labels.placeFieldsCount = 'Place fields count';
UI.labels.polarity = 'Polarity of waveform';
UI.labels.putativeCellType_num = 'Putative cell-type';
UI.labels.refractoryPeriodViolation = ['Refractory period violation (',char(8240),')'];
UI.labels.sessionID = 'Session ID';
UI.labels.sessionName_num = 'Session name';
UI.labels.sex_num = 'Animal sex';
UI.labels.animal_sex_num = 'Animal sex';
UI.labels.spatialCoherence = 'Spatial coherence';
UI.labels.spatialCoverageIndex = 'Spatial Coverage index';
UI.labels.spatialGiniCoeff = 'Spatial Gini coefficient';
UI.labels.spatialPeakRate = 'Spatial peak firing rate (Hz)';
UI.labels.spatialSplitterDegree = 'spatialSplitterDegree';
UI.labels.species_num = 'Animal species';
UI.labels.animal_species_num = 'Animal species';
UI.labels.spikeCount = 'Spike count';
UI.labels.spikeGroup = 'Spike group';
UI.labels.spikeSortingID = 'Spike sorting ID';
UI.labels.strain_num = 'Animal strain';
UI.labels.animal_strain_num = 'Animal strain';
UI.labels.synapticConnectionsIn = 'Synaptic connections (inbound)';
UI.labels.synapticConnectionsOut = 'Synaptic connections (outbound)';
UI.labels.synapticEffect_num = 'Synaptic effect';
UI.labels.thetaEntrainment = 'Theta entrainment';
UI.labels.thetaModulationIndex = 'Theta modulation index';
UI.labels.thetaPhasePeak = 'Theta phase peak';
UI.labels.thetaPhaseTrough = 'Theta phase trough';
UI.labels.troughToPeak = 'Trough-to-peak (ms)';
UI.labels.troughtoPeakDerivative = 'Trough-to-peak (derivative; ms)';

% Adding missing cell metrics labels
missingLabels = setdiff(UI.lists.metrics,fieldnames(UI.labels));
for i = 1:numel(missingLabels)
    if contains(missingLabels{i},'_num')
        UI.labels.(missingLabels{i}) = missingLabels{i}(1:end-4);
    else
        UI.labels.(missingLabels{i}) = missingLabels{i};
    end
end
