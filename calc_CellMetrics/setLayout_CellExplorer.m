function preferences = setLayout_CellExplorer(preferences,loadOrSave)
    preferences_to_save = {'customPlot','acgType','metricsTable','plotWaveformMetrics','plotInsetChannelMap','plotInsetACG', 'plotXdata','showIntroduction',...
        'plotYdata','plotZdata','plotMarkerSizedata','customPlotHistograms','layout','sortingMetric','markerSize','stickySelection','hoverEffect',...
        'trilatGroupData','zscoreWaveforms', 'colormap','colormapStates', 'rainCloudNormalization', 'isiNormalization', 'monoSynDisp', 'displayInhibitory',...
        'displayExcitatory','displayExcitatoryPostsynapticCells','displayInhibitoryPostsynapticCells','plotExcitatoryConnections','plotInhibitoryConnections'};
    
    if isdeployed
        CellExplorer_path = pwd;
    else
        [CellExplorer_path,~,~] = fileparts(which('CellExplorer.m'));
        CellExplorer_path = fullfile(CellExplorer_path,'calc_CellMetrics');
    end
    
    if loadOrSave == 1
        if exist(fullfile(CellExplorer_path,'last_preferences_CellExplorer.mat'))
            load(fullfile(CellExplorer_path,'last_preferences_CellExplorer.mat'),'last_preferences');
            for i = 1:numel(preferences_to_save)
                if isfield(last_preferences,preferences_to_save{i})
                    preferences.(preferences_to_save{i}) = last_preferences.(preferences_to_save{i});
                end
            end
            preferences.showIntroduction = false; 
        else
            preferences.showIntroduction = true; 
        end
    else
        last_preferences = {};
        for i = 1:numel(preferences_to_save)
            last_preferences.(preferences_to_save{i}) = preferences.(preferences_to_save{i});
        end
        save(fullfile(CellExplorer_path,'last_preferences_CellExplorer.mat'),'last_preferences');
    end
end
