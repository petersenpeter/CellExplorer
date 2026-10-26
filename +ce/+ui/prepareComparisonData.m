function [cell_metrics,referenceData,fig2_axislimit_x1,fig2_axislimit_y1] = prepareComparisonData(cell_metrics,inputType,preferences,fig2_axislimit_x,fig2_axislimit_y,logIntervals,gauss2d)
%PREPARECOMPARISONDATA Legacy comparison display formulas, without viewer mutation.
ce.data.metricCellCount(cell_metrics,true);
if ~ismember(inputType,{'reference','groundTruth'})
    error('ce:ui:InvalidComparisonType','Expected reference or groundTruth.');
end
    if strcmp(inputType,'reference')
        % Cell type initialization
        referenceData.cellTypes = unique([preferences.cellTypes,cell_metrics.putativeCellType],'stable');
        clear referenceData1
        referenceData.clusClas = ones(1,length(cell_metrics.putativeCellType));
        for i = 1:length(referenceData.cellTypes)
            referenceData.clusClas(strcmp(cell_metrics.putativeCellType,referenceData.cellTypes{i}))=i;
        end
        referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas,[1:length(referenceData.cellTypes)+1])'))';
    else
        % Ground truth initialization
        clear groundTruthData1
%             referenceData.clusClas = ones(1,length(referenceData.clusClas));
        referenceData.groundTruthTypes = fieldnames(cell_metrics.groundTruthClassification)';
        for i = 1:numel(referenceData.groundTruthTypes)
            referenceData.clusClas(cell_metrics.groundTruthClassification.(referenceData.groundTruthTypes{i})) = i;
        end
%             [referenceData.clusClas, referenceData.groundTruthTypes] = findgroups([cell_metrics.groundTruthClassification{:}]);
        referenceData.counts = cellstr(num2str(histcounts(referenceData.clusClas)'))';
    end
    fig2_axislimit_x1 = [min([cell_metrics.troughToPeak * 1000,fig2_axislimit_x(1)]),max([cell_metrics.troughToPeak * 1000, fig2_axislimit_x(2)])];
    fig2_axislimit_y1 = [min([cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise>0),fig2_axislimit_y(1)]),max([cell_metrics.acg_tau_rise(cell_metrics.acg_tau_rise<Inf),fig2_axislimit_y(2)])];

    % Creating surface of reference points
    referenceData.x = linspace(fig2_axislimit_x1(1),fig2_axislimit_x1(2),preferences.binCount);
    referenceData.y = 10.^(linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),preferences.binCount));
    referenceData.y1 = linspace(log10(fig2_axislimit_y1(1)),log10(fig2_axislimit_y1(2)),preferences.binCount);

    if strcmp(inputType,'reference')
        colors = (1-(preferences.cellTypeColors)) * 250;
    else
        colors = (1-(preferences.groundTruthColors)) * 250;
    end
    temp = unique(referenceData.clusClas);

    referenceData.z = zeros(length(referenceData.x)-1,length(referenceData.y)-1,3,size(colors,1));
    for i = temp
        idx = find(referenceData.clusClas==i);
        [z_referenceData_temp,~,~] = histcounts2(cell_metrics.troughToPeak(idx) * 1000, cell_metrics.acg_tau_rise(idx),referenceData.x,referenceData.y,'norm','probability');
        referenceData.z(:,:,:,i) = bsxfun(@times,repmat(conv2(z_referenceData_temp,gauss2d,'same'),1,1,3),reshape(colors(i,:),1,1,[]));

    end
    referenceData.x = referenceData.x(1:end-1)+diff(referenceData.x([1,2]));
    referenceData.y = 10.^(linspace(log10(fig2_axislimit_y(1)),log10(fig2_axislimit_y(2)),preferences.binCount) + (log10(fig2_axislimit_y(2))-log10(fig2_axislimit_y(1)))/preferences.binCount/2);
    referenceData.y = referenceData.y(1:end-1);

    referenceData.selection = temp;

    % 'All filt waveforms'
    if ~isfield(cell_metrics.waveforms,'time_zscored')
        step_size = [cellfun(@diff,cell_metrics.waveforms.time,'UniformOutput',false)];
        cell_metrics.waveforms.time_zscored = [max(cellfun(@min, cell_metrics.waveforms.time)):min([step_size{:}]):min(cellfun(@max, cell_metrics.waveforms.time))];
    end
    if isfield(cell_metrics.waveforms,'filt')
        filtWaveform = [];
        for i = 1:length(cell_metrics.waveforms.filt)
            if isempty(cell_metrics.waveforms.filt{i})
                filtWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
            else
                filtWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.filt{i},cell_metrics.waveforms.time_zscored,'spline',nan);
            end
        end
        if ~isfield(cell_metrics.waveforms,'filt_zscored')  || size(cell_metrics.waveforms.filt,2) ~= size(cell_metrics.waveforms.filt_zscored,2)
            cell_metrics.waveforms.filt_zscored = (filtWaveform-mean(filtWaveform,'omitnan'))./std(filtWaveform,'omitnan');
        end
        clear filtWaveform
    end

    % 'All raw waveforms'
    if isfield(cell_metrics.waveforms,'raw')
        rawWaveform = [];
        for i = 1:length(cell_metrics.waveforms.raw)
            if isempty(cell_metrics.waveforms.raw{i})
                rawWaveform(:,i) = zeros(size(cell_metrics.waveforms.time_zscored));
            else
                rawWaveform(:,i) = interp1(cell_metrics.waveforms.time{i},cell_metrics.waveforms.raw{i},cell_metrics.waveforms.time_zscored,'spline',nan);
            end
        end
        if ~isfield(cell_metrics.waveforms,'raw_zscored')  || size(cell_metrics.waveforms.raw,2) ~= size(cell_metrics.waveforms.raw_zscored,2)
            cell_metrics.waveforms.raw_zscored = (rawWaveform-mean(rawWaveform,'omitnan'))./std(rawWaveform,'omitnan');
        end
        clear rawWaveform
    end

    if ~isfield(cell_metrics.acg,'wide_normalized')
        cell_metrics.acg.wide_normalized = normalize_range(cell_metrics.acg.wide);
    end
    if ~isfield(cell_metrics.acg,'narrow_normalized')
        cell_metrics.acg.narrow_normalized = normalize_range(cell_metrics.acg.narrow);
    end

    if isfield(cell_metrics.acg,'log10') && (~isfield(cell_metrics.acg,'log10_rate') || size(cell_metrics.acg.log10_rate,2) ~= size(cell_metrics.acg.log10,2))
        cell_metrics.acg.log10_rate = normalize_range(cell_metrics.acg.log10);
        cell_metrics.acg.log10_occurrence = normalize_range(cell_metrics.acg.log10.*diff(10.^logIntervals)');
    end

    if isfield(cell_metrics,'isi') && isfield(cell_metrics.isi,'log10')  && (~isfield(cell_metrics.isi,'log10_rate') || size(cell_metrics.isi.log10_rate,2) ~= size(cell_metrics.isi.log10,2))
        cell_metrics.isi.log10_rate = normalize_range(cell_metrics.isi.log10);
        cell_metrics.isi.log10_occurrence = normalize_range(cell_metrics.isi.log10.*diff(10.^logIntervals)');
    end
end


function data = normalize_range(data)
data = data./range(data);
end
