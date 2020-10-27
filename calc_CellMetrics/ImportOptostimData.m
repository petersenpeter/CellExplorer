% Loading Sam's opto stim
% fileName = '20160210.evt.ait';
sessionNames = {'20160225','20160309','20160308','20160307','20170301','20170203','20170124','20170125','20160210','20160505'};
% sessionNames = {'mouse1_180502b','mouse1_180502a','mouse1_180501b','mouse1_180501a','mouse1_180414','mouse1_180415','mouse1_180412','mouse4_181114b','mouse3_180629','mouse3_180628','mouse3_180627','mouse5_181112B','mouse5_181116','mouse6_190330','mouse6_190331'};
sessionsRoyer = {'som1_1','som1_2','som2_1','som2_2','som3_1','som3_2','som4','som5','som6','P1','P2_1','P2_2','P3_1','P3_2','P4_1','P4_2','P4_1'};
sessionNames = sessionsRoyer;
disp('Processing opto-tagget datasets')
for i = 1:length(sessionNames)
    [session, basename, basepath] = db_set_session('sessionName',sessionNames{i});
    disp([num2str(i),': ', basename])
    extension = '.evt.ait';
    
    delimiter = '\t';
    startRow = 1;
    formatSpec = '%f%s%[^\n\r]';
    fileID = fopen([basename extension],'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
    fclose(fileID);
    
    optoStim = [];
    optoStim.timestamps_all = dataArray{1}'/1000;
    k = 1;
    kk = 1;
    kkk = 1;
    A = cellfun(@(x) strsplit(x,' '),dataArray{2},'UniformOutput',false);
    for ii = 1:length(A)
        optoStim.stimID_all(ii) = str2double( A{ii}(2));
        
        if length(A{ii})>2
            optoStim.amplitude_all(ii) = str2double(A{ii}(3));
        else
            optoStim.amplitude_all(ii) = 0;
        end
        if strcmp(A{ii}{1},'pulse_on')
            optoStim.timestamps(k,1) = dataArray{1}(ii)/1000;
            optoStim.stimID(k) = str2double( A{ii}(2));
            k = k + 1;
        end
        if strcmp(A{ii}{1},'pulse_off')
            optoStim.timestamps(kk,2) = dataArray{1}(ii)/1000;
            optoStim.stimID(kk) = str2double( A{ii}(2));
            kk = kk + 1;
        end
        if strcmp(A{ii}{1},'pulse_center')
            optoStim.peaks(kkk) = dataArray{1}(ii)/1000;
            optoStim.stimID(kkk) = str2double( A{ii}(2));
            if length(A{ii})>2
                optoStim.amplitude(kkk) = str2double(A{ii}(3));
            else
                optoStim.amplitude(kkk) = 0;
            end
            kkk = kkk + 1;
        end
    end
    fields = {'timestamps_all','stimID_all','amplitude_all'};
    optoStim = rmfield(optoStim,fields);
    
    if isfield(optoStim,'stimID')
        optoStim.stimID = optoStim.stimID';
    end
    if isfield(optoStim,'peaks')
        optoStim.peaks = optoStim.peaks';
    end
    if isfield(optoStim,'timestamps')
        optoStim.center = mean(optoStim.timestamps,2);
    end
    if isfield(optoStim,'timestamps')
        optoStim.duration = diff(optoStim.timestamps')';
    end
    if isfield(optoStim,'amplitude')
        optoStim.amplitude = optoStim.amplitude';
    end
    saveStruct(optoStim,'manipulation','session',session);
end

%%
psth_optostim = [];
for i = 2%:length(sessionNames)
    
    [session, basename, basepath] = db_set_session('sessionName',sessionNames{i});
    disp([num2str(i),': ', basename])
    load(fullfile(basepath,[basename,'.optoStim.manipulation.mat']),'optoStim');
    spikes = loadSpikes('clusteringpath',session.spikeSorting{1}.relativePath,'format',session.spikeSorting.format{1},'basepath',basepath,'basename',basename,'LSB',session.extracellular.leastSignificantBit);
    
    trigger = optoStim.timestamps(:,1);
    bins_size = 0.01;
    edges = [-0.1:0.01:0.2];
    manipulation_direction = 'activate'; % ['activate', 'silence']
%     psth_optostim.psth = zeros(length(edges),spikes.numcells);
    for j = 1:spikes.numcells
        psth = zeros(size(edges));
        for jj = 1:length(trigger)
            psth = psth + histc(spikes.times{j}'-trigger(jj),edges);
        end
        psth_optostim2 = (psth(1:end-1)/length(trigger))/bins_size;
        psth_optostim.psth{j} = psth_optostim2(:);
    end
    
    psth_optostim.x_label = 'Time (s)';
    psth_optostim.x_bins = edges(1:end-1)+(edges(2)-edges(1))/2;
    figure, plot(psth_optostim.x_bins, zscore(horzcat(psth_optostim.psth{:})))
end
