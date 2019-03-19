function classification_deepSuperficial(session)
% Ripples classification of Deep-superficial channels
basepath = session.general.basePath;
basename = session.general.baseName;

load(fullfile(basepath,[basename,'.ripples.events.mat']));
ripple_channel_detector = ripples.detectorinfo.detectionparms.channel;

spikeGroupsToExclude = [];
if isfield(session.channelTags,'Cortical') && ~isempty(session.channelTags.Cortical.spikeGroups)
    spikeGroupsToExclude = [spikeGroupsToExclude,session.channelTags.Cortical.spikeGroups];
end

if isfield(session.channelTags,'Bad') && ~isempty(session.channelTags.Bad.spikeGroups)
    spikeGroupsToExclude = [spikeGroupsToExclude,session.channelTags.Bad.spikeGroups];
end

% if ~exist(fullfile(basepath, [basename, '.SWR.events.mat']))
%     SWR = detect_swr(basename, ripple_channels);
% else
%     load(fullfile(basepath, [basename, '.SWR.events.mat']))
% end

if isfield(session.extracellular,'probesVerticalSpacing')
    VerticalSpacing = session.extracellular.probesVerticalSpacing;
    Layout = session.extracellular.probesLayout;
else
    siliconprobes = struct2cell(db_load_table('siliconprobes'));
    if isempty(session.extracellular.probes)
        probeimplants = struct2cell(db_load_table('probeimplants',session.general.animal));
        SiliconProbes = cellstr(string(probeimplants{1}.DynamicProbeLayout));
    else
        SiliconProbes = session.extracellular.siliconProbes;
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
end

ripple_average = [];
ripple_power = [];
ripple_amplitude = [];
ripple_channels = [];
srLfp = session.extracellular.srLfp;
ripple_time_axis = [-150:150]/srLfp*1000;
nChannels = session.extracellular.nChannels;
deepSuperficial_ChClass3 = repmat({''},1,nChannels);
deepSuperficial_ChClass = repmat({''},1,nChannels);
deepSuperficial_ChDistance3 = nan(1,nChannels);
deepSuperficial_ChDistance = nan(1,nChannels);

channels_to_exclude = [];
if isfield(session.channelTags,'Bad') && ~isempty(session.channelTags.Bad.channels)
    channels_to_exclude = session.channelTags.Bad.channels;
end

SWR_slope = [];
for jj = 1:session.extracellular.nSpikeGroups
    fprintf(['Analysing spike group ', num2str(jj),', ']);
    
    ripple_channels{jj} = session.extracellular.spikeGroups.channels{jj}+1;
    signal = 0.000195 * double(LoadBinary([basename '.lfp'],'nChannels',nChannels,'channels',ripple_channels{jj},'precision','int16','frequency',srLfp));
    ripple_ave2 = [];
    ripples.peaks = ripples.peaks(find(ripples.peaks*srLfp>151 & ripples.peaks*srLfp<size(signal,1)-151));
    for i = 1:size(ripples.peaks,1)
        ripple_ave2(:,:,i) = signal(round(ripples.peaks(i)*srLfp)-150:round(ripples.peaks(i)*srLfp)+150,:);
    end
    
    ripple_average{jj} = mean(ripple_ave2,3);
    ripple_power{jj} = sum(ripple_average{jj}.^2)./max(sum(ripple_average{jj}.^2));
    ripple_amplitude{jj} = mean(ripple_average{jj})/max(abs(mean(ripple_average{jj})));
    
    deepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}<=0))) = repmat({'Superficial'},sum(ripple_amplitude{jj}<=0),1);
    deepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}>0))) = repmat({'Deep'},sum(ripple_amplitude{jj}>0),1);
    if sum(ripple_amplitude{jj}>0)==0
        % Superficial
        deepSuperficial_ChDistance3(ripple_channels{jj}) = 1:size(ripple_average{jj},2);
    elseif sum(ripple_amplitude{jj}>0) == size(ripple_average{jj},2)
        % Deep
        deepSuperficial_ChDistance3(ripple_channels{jj}) = -(size(ripple_average{jj},2):-1:1);
    end
    if any(ripple_amplitude{jj}<0) && any(ripple_amplitude{jj}>0)
        threshold = interp1(ripple_amplitude{jj},[1:size(ripple_average{jj},2)],0);
        deepSuperficial_ChClass3(ripple_channels{jj}([1:threshold])) = repmat({'Deep'},length([1:threshold]),1);
        deepSuperficial_ChClass3(ripple_channels{jj}([ceil(threshold):size(ripple_average{jj},2)])) = repmat({'Superficial'},length([ceil(threshold):size(ripple_average{jj},2)]),1);
        deepSuperficial_ChDistance3(ripple_channels{jj}) = (1:size(ripple_average{jj},2))-threshold;
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
    
    if any(diff(SWR_diff2<0)==1) && ~any(jj == spikeGroupsToExclude) % && ~any(find(diff(SWR_diff{jj}<0)) > length(SWR_diff{jj}))
        indx = find(diff(SWR_diff2<0)==1);indx = indx(end);
        threshold = interp1(SWR_diff2([indx,indx+1]),[ia2(indx),ia2(indx+1)],0);
        deepSuperficial_ChClass(ripple_channels{jj}([1:threshold])) = repmat({'Deep'},length([1:threshold]),1);
        deepSuperficial_ChClass(ripple_channels{jj}([ceil(threshold):size(SWR_diff{jj},2)])) = repmat({'Superficial'},length([ceil(threshold):size(SWR_diff{jj},2)]),1);
        deepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))-threshold;
    else
        if SWR_slope > 0
            deepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Deep'},length(ripple_channels{jj}),1); % Deep
            if SWR_diff2(end)*5<max(SWR_diff2) && SWR_diff2(end) > 0
                deepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))-length(ripple_channels{jj})-1;
            end
        else
            deepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Superficial'},length(ripple_channels{jj}),1); % Superficial
            if SWR_diff2(1)*5>min(SWR_diff2)  && SWR_diff2(1) < 0
                deepSuperficial_ChDistance(ripple_channels{jj}) = (1:size(SWR_diff{jj},2))+1;
            end
        end
    end
end

clear signal
if isfield(session.channelTags,'Cortical') && ~isempty(session.channelTags.Cortical.spikeGroups)
    for jj = session.channelTags.Cortical.spikeGroups
        deepSuperficial_ChClass3(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
        deepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
    end
end

if isfield(session.channelTags,'Bad') && ~isempty(session.channelTags.Bad.spikeGroups)
    for jj = session.channelTags.Bad.spikeGroups
        deepSuperficial_ChClass3(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
        deepSuperficial_ChClass(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
    end
end

deepSuperficial_ChDistance3 = deepSuperficial_ChDistance3 * VerticalSpacing;
deepSuperficial_ChDistance = deepSuperficial_ChDistance * VerticalSpacing;

deepSuperficialfromRipple.channels = 0:length(deepSuperficial_ChDistance)-1; % index 0
deepSuperficialfromRipple.channelClass = deepSuperficial_ChClass;
deepSuperficialfromRipple.channelDistance = deepSuperficial_ChDistance;
deepSuperficialfromRipple.ripple_power = ripple_power;
deepSuperficialfromRipple.ripple_amplitude = ripple_amplitude;
deepSuperficialfromRipple.ripple_average = ripple_average;
deepSuperficialfromRipple.ripple_time_axis = ripple_time_axis;
deepSuperficialfromRipple.ripple_channels = ripple_channels; %  index 1 for channels
deepSuperficialfromRipple.SWR_diff = SWR_diff;
deepSuperficialfromRipple.SWR_amplitude = SWR_amplitude;
deepSuperficialfromRipple.detectorinfo = ripples.detectorinfo;
deepSuperficialfromRipple.processinginfo.function = 'classification_deepSuperficial';
deepSuperficialfromRipple.processinginfo.date = now;
deepSuperficialfromRipple.processinginfo.params.verticalSpacing = VerticalSpacing;
deepSuperficialfromRipple.processinginfo.params.spikeGroupsToExclude = spikeGroupsToExclude;

save(fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']),'deepSuperficialfromRipple')

figure,
for jj = 1:session.extracellular.nSpikeGroups
    subplot(2,ceil(session.extracellular.nSpikeGroups/2),jj)
    
    plot((SWR_diff{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_diff{jj},2)-1]*0.04,'-k','linewidth',2), hold on, grid on
    plot((SWR_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_amplitude{jj},2)-1]*0.04,'k','linewidth',1)
    plot((ripple_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{jj},2)-1]*0.04,'m','linewidth',1)
    
    for jjj = 1:size(ripple_average{jj},2)
        text(ripple_time_axis(end)+5,ripple_average{jj}(1,jjj)-(jjj-1)*0.04,[num2str(round(deepSuperficial_ChDistance(ripple_channels{jj}(jjj))))])
        text((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50-10,-(jjj-1)*0.04,num2str(ripple_channels{jj}(jjj)-1),'HorizontalAlignment','Right')
        plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04)
        if strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Superficial')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'or','linewidth',2)
        elseif strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Deep')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ob','linewidth',2)
        elseif strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Cortical')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'og','linewidth',2)
        else
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ok')
        end
        if ripple_channel_detector==ripple_channels{jj}(jjj)
            plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04,'k','linewidth',2)
        end
    end
    title(['Spike group ' num2str(jj)]),xlabel('Time (ms)'),if jj ==1; ylabel(session.general.name, 'Interpreter', 'none'); end
    axis tight, ax6 = axis; grid on
    plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
    xlim([-220,ripple_time_axis(end)+45]), xticks([-120:40:120])
    ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
    ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
    if ceil(session.extracellular.nSpikeGroups/2) == jj || session.extracellular.nSpikeGroups == jj
        ht3 = text(1.05,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
    end
end
