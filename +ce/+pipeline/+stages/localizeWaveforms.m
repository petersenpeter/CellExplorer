function patch = localizeWaveforms(inputs, settings, parameters)
%LOCALIZEWAVEFORMS Spatial waveform fits using resolved, fingerprinted coordinates.
% Numerical expressions and fitting settings retained from ProcessCellMetrics.
cell_metrics.general.cellCount = numel(inputs.UID);
cell_metrics.general.chanCoords = inputs.geometry.chanCoords;
cell_metrics.waveforms = inputs.waveforms;
cell_metrics.peakVoltage = inputs.peakVoltage;
cell_metrics.maxWaveformCh1 = inputs.maxWaveformCh1;
spikes = {inputs.spikes};
spkExclu = 1;
session.extracellular.electrodeGroups = inputs.electrodeGroups;
preferences.waveform = settings.preferences;
bad_channels = inputs.badChannels;
% Fit exponential
fit_eqn = fittype('a*exp(-x/b)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c'});
xdata = {};
ydata = {};

if parameters.debugMode
    fig100 = figure;
    handle_subfig1 = subplot(2,1,1); hold on
    title(handle_subfig1,'Spike amplitude (all)'), xlabel(handle_subfig1,'Distance (µm)'), ylabel(handle_subfig1,'µV')
    handle_subfig2 = subplot(2,2,3); hold on
    ylabel(handle_subfig2,'Length constant (µm)'), xlabel(handle_subfig2,'Peak voltage (µV)')
    handle_subfig3 = subplot(2,2,4); hold off
    plot(handle_subfig3,cell_metrics.general.chanCoords.x,cell_metrics.general.chanCoords.y,'.k'), hold on
    xlabel(handle_subfig3,'x position (µm)'), ylabel(handle_subfig3,'y position (µm)')
    drawnow
end

for j = 1:cell_metrics.general.cellCount
    if ~isnan(cell_metrics.peakVoltage(j)) && isfield(cell_metrics.waveforms,'filt_all')
        % Trilateration
        peakVoltage = range(cell_metrics.waveforms.filt_all{j}');
        peakVoltage(bad_channels) = NaN;
        filt_all = cell_metrics.waveforms.filt_all{j}';
        filt_all(:,bad_channels) = 0;
        [~,idx] = sort(range(filt_all),'descend');
        clear filt_all

        trilat_nChannels = min([preferences.waveform.trilat_nChannels,numel(peakVoltage)]);
        bestChannels = cell_metrics.waveforms.channels_all{j}(idx(1:trilat_nChannels));
        beta0 = [cell_metrics.general.chanCoords.x(bestChannels(1)),cell_metrics.general.chanCoords.y(bestChannels(1))]; % initial position
        trilat_pos = trilat(cell_metrics.general.chanCoords.x(bestChannels),cell_metrics.general.chanCoords.y(bestChannels),peakVoltage(idx(1:trilat_nChannels)),beta0,0); % ,1,cell_metrics.waveforms.filt_all{j}(bestChannels,:)
        cell_metrics.trilat_x(j) = trilat_pos(1);
        cell_metrics.trilat_y(j) = trilat_pos(2);

        % Length constant
        x1 = cell_metrics.general.chanCoords.x;
        y1 = cell_metrics.general.chanCoords.y;
        u = cell_metrics.trilat_x(j);
        v = cell_metrics.trilat_y(j);
        [channel_distance,idx2] = sort(hypot((x1(:)-u),(y1(:)-v)));

        nChannelFit = min([trilat_nChannels,length(session.extracellular.electrodeGroups.channels{spikes{spkExclu}.shankID(j)})]);
        x = 1:nChannelFit;
        y = peakVoltage(idx(x));
        x2 = channel_distance(1:nChannelFit)';
        xdata{j} = x2;
        ydata{j} = y;
        f0 = fit(x2',y',fit_eqn,'StartPoint',[cell_metrics.peakVoltage(j), 30, 5],'Lower',[1, 0.001, 0],'Upper',[5000, 200, 1000]);
        fitCoeffValues = coeffvalues(f0);
        cell_metrics.peakVoltage_expFit(j) = fitCoeffValues(2);
        if parameters.debugMode && ishandle(handle_subfig1)
            fig100.Name = ['Cell ',num2str(j),'/',num2str(cell_metrics.general.cellCount)];
            delete(handle_subfig1.Children)
            plot(handle_subfig1,xdata{j},ydata{j},'.-b'), hold on
            plot(handle_subfig1,x2,fitCoeffValues(1)*exp(-x2/fitCoeffValues(2))+fitCoeffValues(3),'r'),
            plot(handle_subfig2,cell_metrics.peakVoltage(j),cell_metrics.peakVoltage_expFit(j),'ok')
            plot(handle_subfig3,cell_metrics.trilat_x(j),cell_metrics.trilat_y(j),'ob'),
            drawnow
        end
    else
        cell_metrics.trilat_x(j) = nan;
        cell_metrics.trilat_y(j) = nan;
        cell_metrics.peakVoltage_expFit(j) = nan;
        xdata{j} = [];
        ydata{j} = [];
    end
end

if parameters.showFigures
    fig1 = figure('Name', 'Length constant and Trilateration','position',[100,100,900,700],'visible','off');
    movegui(fig1,'center')
    subplot(2,2,1), hold on
    for j = 1:cell_metrics.general.cellCount
        plot(xdata{j},ydata{j})
    end
    title('Spike amplitude (all)'), xlabel('Distance (µm)'), ylabel('µV')
    subplot(2,2,2), hold off,
    histogram(cell_metrics.peakVoltage_expFit,20), xlabel('Length constant (µm)')
    subplot(2,2,3), hold on
    plot(cell_metrics.peakVoltage,cell_metrics.peakVoltage_expFit,'ok')
    ylabel('Length constant (µm)'), xlabel('Peak voltage (µV)')
    subplot(2,2,4), hold on
    plot(cell_metrics.general.chanCoords.x,cell_metrics.general.chanCoords.y,'.k'), hold on
    plot(cell_metrics.trilat_x,cell_metrics.trilat_y,'ob'), xlabel('x position (µm)'), ylabel('y position (µm)')
    set(fig1,'visible','on')
end

% Common coordinate framework
if isfield(inputs.geometry,'ccf')
    ccf = inputs.geometry.ccf;
    if all(isfield(ccf,{'x','y','z'}))
        cell_metrics.general.ccf = ccf;
        cell_metrics.ccf_x = cell_metrics.general.ccf.x(cell_metrics.maxWaveformCh1)';
        cell_metrics.ccf_y = cell_metrics.general.ccf.y(cell_metrics.maxWaveformCh1)';
        cell_metrics.ccf_z = cell_metrics.general.ccf.z(cell_metrics.maxWaveformCh1)';
        for j = 1:cell_metrics.general.cellCount
            if ~isnan(cell_metrics.peakVoltage(j))
                peakVoltage = range(cell_metrics.waveforms.filt_all{j}');
                trilat_nChannels = min([preferences.waveform.trilat_nChannels,numel(peakVoltage)]);
                [~,idx] = sort(peakVoltage,'descend');
                bestChannels = cell_metrics.waveforms.channels_all{j}(idx(1:trilat_nChannels));
                beta0 = [cell_metrics.general.ccf.x(bestChannels(1)),cell_metrics.general.ccf.y(bestChannels(1)),cell_metrics.general.ccf.z(bestChannels(1))]; % initial position
                if isnan(beta0)
                    cell_metrics.ccf_x(j) = nan;
                    cell_metrics.ccf_y(j) = nan;
                    cell_metrics.ccf_z(j) = nan;
                else
                    trilat_pos = trilat3([cell_metrics.general.ccf.x(bestChannels),cell_metrics.general.ccf.y(bestChannels),cell_metrics.general.ccf.z(bestChannels)],peakVoltage(idx(1:trilat_nChannels)),beta0,0);
                    cell_metrics.ccf_x(j) = trilat_pos(1);
                    cell_metrics.ccf_y(j) = trilat_pos(2);
                    cell_metrics.ccf_z(j) = trilat_pos(3);
                end
            else
                cell_metrics.ccf_x(j) = nan;
                cell_metrics.ccf_y(j) = nan;
                cell_metrics.ccf_z(j) = nan;
            end
        end
        if parameters.showFigures
            figure
            plot3(cell_metrics.general.ccf.x,cell_metrics.general.ccf.z,cell_metrics.general.ccf.y,'.k'), hold on
            plot3(cell_metrics.ccf_x,cell_metrics.ccf_z,cell_metrics.ccf_y,'ob'),
            xlabel('x ( Anterior-Posterior; µm)'), zlabel('y (Superior-Inferior; µm)'), ylabel('z (Left-Right; µm)'), axis equal, set(gca, 'ZDir','reverse')
            if exist('plotBrainGrid.m','file')
                plotAllenBrainGrid, hold on
            end
        end

    end
end

patch.general.chanCoords = cell_metrics.general.chanCoords;
for name = {'trilat_x','trilat_y','peakVoltage_expFit','ccf_x','ccf_y','ccf_z'}
    if isfield(cell_metrics,name{1}), patch.(name{1}) = cell_metrics.(name{1}); end
end
if isfield(cell_metrics.general,'ccf'), patch.general.ccf = cell_metrics.general.ccf; end
end
