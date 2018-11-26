function classification_DeepSuperficial(SpikeGroups,clustering_path,basename,basepath,shank_to_exclude,session)
% Ripples classification of Deep-superficial channels
shank_to_exclude = [];
if isfield(session.ChannelTags,'Cortical') && ~isempty(session.ChannelTags.Cortical.SpikeGroups)
    shank_to_exclude = [shank_to_exclude,session.ChannelTags.Cortical.SpikeGroups];
end
if isfield(session.ChannelTags,'Bad') && ~isempty(session.ChannelTags.Bad.SpikeGroups)
    shank_to_exclude = [shank_to_exclude,session.ChannelTags.Bad.SpikeGroups];
end

[par,rxml] = LoadXml(fullfile(basepath,[basename,'.xml']));
ripple_channels = par.AnatGrps(SpikeGroups).Channels+1;
noPrompts = true;
if ~exist(fullfile(basepath, [basename, '.lfp']))
    disp('Creating lfp file')
    bz_LFPfromDat(pwd,'noPrompts',true)
end

if isfield(session.ChannelTags,'RippleNoise')
    disp('  Using RippleNoise reference channel')
    RippleNoiseChannel = double(LoadBinary([basename, '.lfp'],'nChannels',session.Extracellular.nChannels,'channels',session.ChannelTags.RippleNoise.Channels,'precision','int16','frequency',session.Extracellular.SrLFP)); % 0.000050354 * 
    ripples = bz_FindRipples('basepath',basepath,'channel',session.ChannelTags.Ripple.Channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.5,'noise',RippleNoiseChannel);
else
    ripples = bz_FindRipples('basepath',basepath,'channel',session.ChannelTags.Ripple.Channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.5);
end
% if ~exist(fullfile(basepath, [basename, '.SWR.events.mat']))
%     SWR = detect_swr(basename, ripple_channels);
% else
%     load(fullfile(basepath, [basename, '.SWR.events.mat']))
% end

% ripple_ave = [];
% sr_eeg = recording.sr/16;
% signal = 0.000050354 * double(LoadBinary([recording.name '.eeg'],'nChannels',session.Extracellular.nChannels,'channels',session.ChannelTags.Ripple.Channels,'precision','int16','frequency',recording.sr/16));
% Fpass = [30,300];
% Wn_theta = [Fpass(1)/(sr_eeg/2) Fpass(2)/(sr_eeg/2)]; % normalized by the nyquist frequency
% [btheta,atheta] = butter(3,Wn_theta);
% signal_filtered = filtfilt(btheta,atheta,signal)';
%
% % ripple frequency
% freqlist = 10.^(log10(20):log10(21)-log10(20):log10(320));
%
% wt = spectrogram(signal_filtered,sr_eeg/10,sr_eeg/10-1,freqlist,sr_eeg);
% clear signal_filtered signal
% for i = 1:size(ripples.peaks,1)
%     ripple_ave(:,:,i) = wt(:,round(ripples.peaks(i)*sr_eeg)-100:round(ripples.peaks(i)*sr_eeg)+100);
% end
% figure, imagesc([-100:100]/sr_eeg,Fpass,mean(abs(ripple_ave),3)),set(gca, 'Ydir', 'normal'),title('Ripples')
% set(gca,'yscale','log')

%%
siliconprobes = struct2cell(db_load_table('siliconprobes'));
if isempty(session.Extracellular.Probes)
    probeimplants = struct2cell(db_load_table('probeimplants',session.General.Animal));
    SiliconProbes = cellstr(string(probeimplants{1}.DynamicProbeLayout));
else
    SiliconProbes = session.Extracellular.SiliconProbes;
end
probeids = [];
VerticalSpacingBetweenSites = [];
VerticalSpacingBetweenSites_corrected = [];
Layout = [];

for i =1:length(SiliconProbes)
    probeids(i) = find(arrayfun(@(n) strcmp(siliconprobes{n}.DescriptiveName, SiliconProbes{1}), 1:numel(siliconprobes)));
    VerticalSpacingBetweenSites(i) = str2num(siliconprobes{probeids(i)}.VerticalSpacingBetweenSites);
    Layout{i} = siliconprobes{probeids(i)}.Layout;
    if any(strcmp(Layout{i},{'staggered','poly2','poly 2','edge'}))
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/2;
        conv_length = 3;
    elseif strcmp(Layout{i},{'linear'})
        conv_length = 2;
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i);
    elseif any(strcmp(Layout{i},{'poly3','poly 3'}))
        conv_length = 3;
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/3;
    elseif any(strcmp(Layout{i},{'poly5','poly 5'}))
        conv_length = 5;
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/5;
    else
        conv_length = 2;
        error('No probe layout defined');
    end
end
if length(unique(VerticalSpacingBetweenSites_corrected))==1
    VerticalSpacing = VerticalSpacingBetweenSites_corrected(1);
else
    VerticalSpacing = VerticalSpacingBetweenSites_corrected;
end
disp(['Vertical spacing applied: ', num2str(VerticalSpacing),' um'])

ripple_average = [];
ripple_power = [];
ripple_amplitude = [];
ripple_channels = [];
sr_eeg = par.lfpSampleRate;
ripple_time_axis = [-150:150]/sr_eeg*1000;
nChannels = session.Extracellular.nChannels;
DeepSuperficial_ChClass3 = repmat({''},1,nChannels);
DeepSuperficial_ChClass = repmat({''},1,nChannels);
DeepSuperficial_ChDistance3 = nan(1,nChannels);
DeepSuperficial_ChDistance = nan(1,nChannels);

channels_to_exclude = [];
if isfield(session.ChannelTags,'Bad') && ~isempty(session.ChannelTags.Bad.Channels)
    channels_to_exclude = session.ChannelTags.Bad.Channels;
end

SWR_slope = [];
for jj = 1:size(par.AnatGrps,2)% session.Extracellular.SpikeGroups
    fprintf(['Analysing shank ', num2str(jj),', ']);
    
    ripple_channels{jj} = par.AnatGrps(jj).Channels+1;
    signal = 0.000050354 * double(LoadBinary([basename '.lfp'],'nChannels',nChannels,'channels',ripple_channels{jj},'precision','int16','frequency',sr_eeg));
    ripple_ave2 = [];
    ripples.peaks = ripples.peaks(find(ripples.peaks*sr_eeg>151 & ripples.peaks*sr_eeg<size(signal,1)-151));
    for i = 1:size(ripples.peaks,1)
        ripple_ave2(:,:,i) = signal(round(ripples.peaks(i)*sr_eeg)-150:round(ripples.peaks(i)*sr_eeg)+150,:);
    end
    
    ripple_average{jj} = mean(ripple_ave2,3);
    ripple_power{jj} = sum(ripple_average{jj}.^2)./max(sum(ripple_average{jj}.^2));
    ripple_amplitude{jj} = mean(ripple_average{jj})/max(abs(mean(ripple_average{jj})));
    
    DeepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}<=0))) = repmat({'Superficial'},sum(ripple_amplitude{jj}<=0),1);
    DeepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}>0))) = repmat({'Deep'},sum(ripple_amplitude{jj}>0),1);
    if sum(ripple_amplitude{jj}>0)==0
        % Superficial
        DeepSuperficial_ChDistance3(ripple_channels{jj}) = 1:size(ripple_average{jj},2);
    elseif sum(ripple_amplitude{jj}>0) == size(ripple_average{jj},2)
        % Deep
        DeepSuperficial_ChDistance3(ripple_channels{jj}) = -(size(ripple_average{jj},2):-1:1);
    end
    if any(ripple_amplitude{jj}<0) && any(ripple_amplitude{jj}>0)
        threshold = interp1(ripple_amplitude{jj},[1:size(ripple_average{jj},2)],0);
        DeepSuperficial_ChClass3(ripple_channels{jj}([1:threshold])) = repmat({'Deep'},length([1:threshold]),1);
        DeepSuperficial_ChClass3(ripple_channels{jj}([ceil(threshold):size(ripple_average{jj},2)])) = repmat({'Superficial'},length([ceil(threshold):size(ripple_average{jj},2)]),1);
        DeepSuperficial_ChDistance3(ripple_channels{jj}) = (1:size(ripple_average{jj},2))-threshold;
    end
    
    % New method
    [~,ia,~] = intersect(ripple_channels{jj}, channels_to_exclude);
    [ripple_channels2,ia2] = setdiff(ripple_channels{jj}, channels_to_exclude,'legacy');
    ia2 = sort(ia2);
    SWR_average = nanconv(ripple_average{jj},ones(40,1)/40,'edge');
    SWR_average = SWR_average-SWR_average(100,:);
    SWR_diff{jj} = sum(SWR_average(100:135,:));
%     SWR_diff{jj} = -SWR_average(100,:)+SWR_average(140,:);
%     SWR_diff{jj}(ia) = nan;
    SWR_diff2 = SWR_diff{jj};
    SWR_diff2(ia) = [];
    SWR_diff2 = nanconv(SWR_diff2,[ones(1,conv_length)]/conv_length,'edge');
    
    SWR_average2 = nanconv(ripple_average{jj},ones(20,1)/20,'edge');
    SWR_amplitude{jj} = sum(abs(ripple_average{jj}(100:201,:)-SWR_average2(100:201,:)));
    SWR_amplitude2 = SWR_amplitude{jj};
    SWR_amplitude2(ia) = [];
    
    coefs = polyfit([1:length(SWR_amplitude2)], SWR_amplitude2, 1);
    SWR_slope = coefs(1);

    SWR_diff{jj} = SWR_diff{jj}./max(abs(SWR_diff{jj}));
    SWR_amplitude{jj} = (SWR_amplitude{jj}-min(SWR_amplitude{jj}))./max(abs(SWR_amplitude{jj}-min(SWR_amplitude{jj})));
    
    if any(diff(SWR_diff2<0)==1) && ~any(jj == shank_to_exclude) % && ~any(find(diff(SWR_diff{jj}<0)) > length(SWR_diff{jj}))
        indx = find(diff(SWR_diff2<0)==1);indx = indx(end);
        threshold = interp1(SWR_diff2([indx,indx+1]),[ia2(indx),ia2(indx+1)],0);
        DeepSuperficial_ChClass(ripple_channels{jj}([1:threshold])) = repmat({'Deep'},length([1:threshold]),1);
        DeepSuperficial_ChClass(ripple_channels{jj}([ceil(threshold):size(SWR_diff{jj},2)])) = repmat({'Superficial'},length([ceil(threshold):size(SWR_diff{jj},2)]),1);
        DeepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))-threshold;
    else
        if SWR_slope > 0
            DeepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Deep'},length(ripple_channels{jj}),1); % Deep
            if SWR_diff2(end)*5<max(SWR_diff2) && SWR_diff2(end) > 0
                DeepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))-length(ripple_channels{jj})-1;
            end
        else
            DeepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Superficial'},length(ripple_channels{jj}),1); % Superficial
            if SWR_diff2(1)*5>min(SWR_diff2)  && SWR_diff2(1) < 0
                DeepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))+1;
            end
        end
    end
end

clear signal
if isfield(session.ChannelTags,'Cortical') && ~isempty(session.ChannelTags.Cortical.SpikeGroups)
    for jj = session.ChannelTags.Cortical.SpikeGroups
    DeepSuperficial_ChClass3(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
    DeepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
    end
end
if isfield(session.ChannelTags,'Bad') && ~isempty(session.ChannelTags.Bad.SpikeGroups)
    for jj = session.ChannelTags.Bad.SpikeGroups
    DeepSuperficial_ChClass3(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
    DeepSuperficial_ChClass(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
    end
end
% for jj = shank_to_exclude
%     DeepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
%     DeepSuperficial_ChDistance(ripple_channels{jj}) = nan;
% end
DeepSuperficial_ChDistance3 = DeepSuperficial_ChDistance3 *VerticalSpacing;
DeepSuperficial_ChDistance = DeepSuperficial_ChDistance *VerticalSpacing;

save(fullfile(basepath, 'DeepSuperficial_ChClass.mat'),'DeepSuperficial_ChClass','ripple_power','ripple_amplitude','ripple_average','ripple_time_axis','ripple_channels','DeepSuperficial_ChDistance','SWR_diff','SWR_amplitude')

figure,
for jj = 1:session.Extracellular.SpikeGroups
    subplot(2,ceil(session.Extracellular.SpikeGroups/2),jj)
    
    plot((SWR_diff{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_diff{jj},2)-1]*0.04,'-k','linewidth',2), hold on, grid on
    plot((SWR_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_amplitude{jj},2)-1]*0.04,'k','linewidth',1)
    plot((ripple_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{jj},2)-1]*0.04,'m','linewidth',1)
    
    for jjj = 1:size(ripple_average{jj},2)
        text(ripple_time_axis(end)+5,ripple_average{jj}(1,jjj)-(jjj-1)*0.04,[num2str(round(DeepSuperficial_ChDistance(ripple_channels{jj}(jjj))))])
        text((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50-10,-(jjj-1)*0.04,num2str(ripple_channels{jj}(jjj)),'HorizontalAlignment','Right')
        plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04)
        if strcmp(DeepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Superficial')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'or','linewidth',2)
        elseif strcmp(DeepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Deep')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ob','linewidth',2)
        elseif strcmp(DeepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Cortical')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'og','linewidth',2)
        else
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ok')
        end
        if session.ChannelTags.Ripple.Channels==ripple_channels{jj}(jjj)
            plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04,'k','linewidth',2)
        end
    end
    title(['Shank ' num2str(jj)]),xlabel('Time (ms)'),if jj ==1; ylabel(session.General.Name, 'Interpreter', 'none'); end
    axis tight, ax6 = axis; grid on
    plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
    xlim([-220,ripple_time_axis(end)+45]), xticks([-120:40:120])
    ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
    ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
    if ceil(session.Extracellular.SpikeGroups/2) == jj || session.Extracellular.SpikeGroups == jj
        ht3 = text(1.05,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
    end
end
% 
% figure,
% for jj = 1:session.Extracellular.SpikeGroups
%     subplot(2,ceil(session.Extracellular.SpikeGroups/2),jj)
%     
%     plot((ripple_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{jj},2)-1]*0.04,'-k','linewidth',2), hold on, grid on
%     
%     for jjj = 1:size(ripple_average{jj},2)
%         text(ripple_time_axis(end)+5,ripple_average{jj}(1,jjj)-(jjj-1)*0.04,[num2str(round(DeepSuperficial_ChDistance(ripple_channels{jj}(jjj))))])
%         text((ripple_amplitude{jj}(jjj)*50)+ripple_time_axis(1)-50-10,-(jjj-1)*0.04,num2str(ripple_channels{jj}(jjj)),'HorizontalAlignment','Right')
%         
%         SWR_average = nanconv(ripple_average{jj}(:,jjj),ones(20,1)/20,'edge');
% %         plot(ripple_time_axis,SWR_average);
%         plot(ripple_time_axis,(ripple_average{jj}(:,jjj)-SWR_average)-(jjj-1)*0.04)
%         if strcmp(DeepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Superficial')
%             plot((ripple_amplitude{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'or','linewidth',2)
%         elseif strcmp(DeepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Deep')
%             plot((ripple_amplitude{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ob','linewidth',2)
%         else
%             plot((ripple_amplitude{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ok')
%         end
%         if session.ChannelTags.Ripple.Channels==ripple_channels{jj}(jjj)
%             plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04,'k','linewidth',2)
%         end
%     end
%     title(['Shank ' num2str(jj)]),xlabel('Time (ms)'),if jj ==1; ylabel(session.General.Name, 'Interpreter', 'none'); end
%     axis tight, ax6 = axis; grid on
%     plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
%     xlim([-220,ripple_time_axis(end)+50]), xticks([-120:40:120])
%     ht1 = text(0.034,0.01,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
%     ht2 = text(0.20,0.01,'Deep','Units','normalized','FontWeight','Bold','Color','b'); set(ht1,'Rotation',90), set(ht2,'Rotation',90)
%     ht3 = text(0.95,0.01,'Depth (µm)','Units','normalized','Color','k'); set(ht1,'Rotation',90), set(ht3,'Rotation',90)
% end
% 
% for jj = 1:session.Extracellular.SpikeGroups
%     figure(100)
%     SWR_average = nanconv(ripple_average{jj},ones(60,1)/60,'edge');
%     SWR_diff = -SWR_average(100,:)+SWR_average(151,:);
%     SWR_average = nanconv(ripple_average{jj},ones(20,1)/20,'edge');
%     SWR_amplitude = sum(abs(ripple_average{jj}(100:201,:)-SWR_average(100:201,:)));
%     plot([1:length(SWR_diff)]*VerticalSpacing,SWR_diff,'.-'), hold on
%     text(length(SWR_diff)*VerticalSpacing+1,SWR_diff(end),num2str(jj))
%     title(['Reversal']),grid on
%     figure(101)
%     plot([1:length(SWR_amplitude)]*VerticalSpacing,SWR_amplitude,'.-'), hold on
%     text(length(SWR_amplitude)*VerticalSpacing+1,SWR_amplitude(end),num2str(jj))
%     title(['Ripple power'])
% end
% grid on