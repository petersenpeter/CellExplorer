function classification_deepSuperficial(session,varargin)
% SWR ripples classification of Deep-superficial channels
% Defines the deep superficial boundary by the sharp wave reversal.
%
% The algorith assigned both distance to the reversal point and labels.
% The assigned label are (ordered by depth):
%   'Cortical'    : Assigned to channels belonging to a spikegroup with the channelTag Cortical 
%   'Deep'        : Assigned to channels above the reversal
%   'Superficial' : Assigned to channels below the reversal
%   ''            : Assigned to channels belonging to a spikegroup with the channelTag Bad
%
% Distance to the boundary in µm for spike groups where the reversal is detected.
%
% INPUT
% session struct with required fields:
%
% session.general.basePath: basePath e.g. 'Z:\peterp03\IntanData\MS22\Peter_MS22_180629_110319_concat'
% session.general.name: name of the recording, e.g. 'Peter_MS22_180629_110319_concat'
% session.channelTags.(Bad or Cortical) specifying spikeGroups (1-indexed), channels (1-indexed)
%   e.g. session.channelTags.Bad.channels = [1,25,128]; session.channelTags.Bad.spikeGroups = [1]
% session.analysisTags.probesVerticalSpacing: in µm, e.g. 20
% session.analysisTags.probesLayout: ['staggered','linear','poly2','poly3','poly5']
% session.extracellular.srLfp: in Hz, e.g. 1250
% session.extracellular.nChannels: integer, e.g. 128
% session.extracellular.nSpikeGroups: integer, e.g. 8
% session.extracellular.spikeGroups struct following the xml anatomical format but 1-indexed
% 
% Requirements
% downsampled (and lowpass filtered) basename.lfp file in basepath
%
% Dependencies:
% nanconv (included with the CellExplorer)
% LoadBinary (loading lfp)
% ce_FindRipples / bz_FindRipples (find ripples)

% Part of the CellExplorer: https://github.com/petersenpeter/CellExplorer
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-11-2019

p = inputParser;
addParameter(p,'buzcode',false,@islogical); % Defines whether bz_FindRipples or ce_FindRipples is called

% Parsing inputs
parse(p,varargin{:})
buzcode = p.Results.buzcode;

% Gets basepath and basename from session struct
basepath = session.general.basePath;
basename = session.general.name;

% Loading detected ripples
if exist(fullfile(basepath,[basename,'.ripples.events.mat']),'file')
    load(fullfile(basepath,[basename,'.ripples.events.mat']));
elseif buzcode
    if isfield(session.channelTags,'RippleNoise') && isfield(session.channelTags,'Ripple')
        disp('  Using RippleNoise reference channel')
        RippleNoiseChannel = double(LoadBinary(fullfile(basepath,[basename, '.lfp']),'nChannels',session.extracellular.nChannels,'channels',session.channelTags.RippleNoise.channels,'precision','int16','frequency',session.extracellular.srLfp)); % 0.000050354 *
        ripples = bz_FindRipples(basename,session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.9,'noise',RippleNoiseChannel);
    elseif isfield(session.channelTags,'Ripple')
        ripples = bz_FindRipples(basename,session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.5);
    else
        error('Ripple channel not defined!')
    end
else
    if isfield(session.channelTags,'RippleNoise') && isfield(session.channelTags,'Ripple')
        disp('  Using RippleNoise reference channel')
        RippleNoiseChannel = double(LoadBinary(fullfile(basepath,[basename, '.lfp']),'nChannels',session.extracellular.nChannels,'channels',session.channelTags.RippleNoise.channels,'precision','int16','frequency',session.extracellular.srLfp)); % 0.000050354 *
        ripples = ce_FindRipples(session,'channel',session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.9,'noise',RippleNoiseChannel);
    elseif isfield(session.channelTags,'Ripple')
        ripples = ce_FindRipples(session,'channel',session.channelTags.Ripple.channels-1,'basepath',basepath,'durations',[50 150],'passband',[120 180],'EMGThresh',0.5);
    else
        error('Ripple channel not defined!')
    end
end
if isfield(ripples,'detectorinfo') & isfield(ripples.detectorinfo,'detectionparms') & isfield(ripples.detectorinfo.detectionparms,'channel')
    ripple_channel_detector = ripples.detectorinfo.detectionparms.channel;
else
    ripple_channel_detector = 0;
end

% Determines which spike groups that should be excluded from the analysis
% by two channelTags: Cortical and Bad

% Use Cortical channelTag to spike groups not belonging to the hippocampus
spikeGroupsToExclude = [];
if isfield(session.channelTags,'Cortical') && ~isempty(session.channelTags.Cortical.electrodeGroups)
    spikeGroupsToExclude = [spikeGroupsToExclude,session.channelTags.Cortical.electrodeGroups];
end

% Use Bad channelTag for spike groups, that are not working properly (i.e. broken shanks)
if isfield(session.channelTags,'Bad') && isfield(session.channelTags.Bad,'spikeGroups') &&~isempty(session.channelTags.Bad.electrodeGroups)
    spikeGroupsToExclude = [spikeGroupsToExclude,session.channelTags.Bad.electrodeGroups];
end

% John's swr detector
% if ~exist(fullfile(basepath, [basename, '.SWR.events.mat']))
%     SWR = detect_swr(basename, ripple_channels);
% else
%     load(fullfile(basepath, [basename, '.SWR.events.mat']))
% end

VerticalSpacing = session.analysisTags.probesVerticalSpacing;
if ischar(session.analysisTags.probesLayout)
    Layout = session.analysisTags.probesLayout;
else
    Layout = session.analysisTags.probesLayout{1};
end
if any(strcmp(Layout,{'staggered','poly2','poly 2','edge'}))
    conv_length = 3;
elseif strcmp(Layout,{'linear'})
    conv_length = 2;
elseif any(strcmp(Layout,{'poly3','poly 3'}))
    conv_length = 3;
elseif any(strcmp(Layout,{'poly5','poly 5'}))
    conv_length = 5;
else
    % If no probe design is provided, it assumes a staggered/poly2 layout (most common)
    conv_length = 2;
    error('No probe layout defined');
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
        
% excluding channels that has the channelTags Bad as the algorithm is sensitive to artifacts
channels_to_exclude = [];
if isfield(session.channelTags,'Bad') && ~isempty(session.channelTags.Bad.channels)
    channels_to_exclude = session.channelTags.Bad.channels;
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Main algorithm  (two versions below)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

SWR_slope = [];
for jj = 1:session.extracellular.nSpikeGroups
    % Analysing the spike groups separately
    fprintf(['Analysing spike group ', num2str(jj),', ']);
    
    % Get list of channels belong to spike group (1-indexed)
    ripple_channels{jj} = session.extracellular.spikeGroups.channels{jj};
    
    % Loading .lfp file
    signal = 0.000195 * double(LoadBinary([basename '.lfp'],'nChannels',nChannels,'channels',ripple_channels{jj},'precision','int16','frequency',srLfp));
    ripple_ave2 = [];
    
    % Only include ripples outside 151 samples from the start/end of the lfp file
    ripples.peaks = ripples.peaks(find(ripples.peaks*srLfp>151 & ripples.peaks*srLfp<size(signal,1)-151));
    for i = 1:size(ripples.peaks,1)
        ripple_ave2(:,:,i) = signal(round(ripples.peaks(i)*srLfp)-150:round(ripples.peaks(i)*srLfp)+150,:);
    end
    
    ripple_average{jj} = mean(ripple_ave2,3);
    ripple_power{jj} = sum(ripple_average{jj}.^2)./max(sum(ripple_average{jj}.^2));
    ripple_amplitude{jj} = mean(ripple_average{jj})/max(abs(mean(ripple_average{jj})));
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    % First algorithm (check new algorithm below)
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    
    % Assigns Superficial label to all channels if all channels have negative ripple amplitude
    deepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}<=0))) = repmat({'Superficial'},sum(ripple_amplitude{jj}<=0),1);
    % Assigns Deep label to all channels if all channels have positive ripple amplitude
    deepSuperficial_ChClass3(ripple_channels{jj}(find(ripple_amplitude{jj}>0))) = repmat({'Deep'},sum(ripple_amplitude{jj}>0),1);
    
    % assigning distance to reversal
    if sum(ripple_amplitude{jj}>0)==0
        % Superficial 
        % Positive distance to reversal assigned to channels in spike group
        % if all channels are below reversal
        deepSuperficial_ChDistance3(ripple_channels{jj}) = 1:size(ripple_average{jj},2);
    elseif sum(ripple_amplitude{jj}>0) == size(ripple_average{jj},2)
        % Deep
        % Negative distance to reversal assigned to channels in spike group
        % if all channels are above reversal
        deepSuperficial_ChDistance3(ripple_channels{jj}) = -(size(ripple_average{jj},2):-1:1);
    end
    % Deals with the spike groups where a reversal is detected
    if any(ripple_amplitude{jj}<0) && any(ripple_amplitude{jj}>0)
        % Performs a linear interpolation to determine the reversal point.
        % This limits the variance that can exist because of variance in
        % the ripple amplitude and due to sub-optimal probe layouts 
        threshold = interp1(ripple_amplitude{jj},[1:size(ripple_average{jj},2)],0);
        deepSuperficial_ChClass3(ripple_channels{jj}([1:threshold])) = repmat({'Deep'},length([1:threshold]),1);
        deepSuperficial_ChClass3(ripple_channels{jj}([ceil(threshold):size(ripple_average{jj},2)])) = repmat({'Superficial'},length([ceil(threshold):size(ripple_average{jj},2)]),1);
        deepSuperficial_ChDistance3(ripple_channels{jj}) = (1:size(ripple_average{jj},2))-threshold;
    end
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    % Second algorithm (newest)
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    % Seems to do much better across mouse and rat recordings where the
    % sharp wave can have very different shape and amplitude.
    
    [~,ia,~] = intersect(ripple_channels{jj}, channels_to_exclude);
    [ripple_channels2,ia2] = setdiff(ripple_channels{jj}, channels_to_exclude,'legacy');
    ia2 = sort(ia2);
    SWR_average = nanconv(ripple_average{jj},ones(40,1)/40,'edge');
    SWR_average = SWR_average-SWR_average(100,:);
    SWR_diff{jj} = sum(SWR_average(100:135,:));
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
    
    if any(diff(SWR_diff2<0)==1) && ~any(jj == spikeGroupsToExclude)
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
% Labels channels Cortical if spike group has channelTags
if isfield(session.channelTags,'Cortical') && ~isempty(session.channelTags.Cortical.electrodeGroups)
    for jj = session.channelTags.Cortical.electrodeGroups
        deepSuperficial_ChClass3(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
        deepSuperficial_ChClass(ripple_channels{jj}) = repmat({'Cortical'},length(ripple_channels{jj}),1);
    end
end

% Removes channel-labels if spike group has channelTags Bad
if isfield(session.channelTags,'Bad') && isfield(session.channelTags.Bad,'electrodeGroups') && ~isempty(session.channelTags.Bad.electrodeGroups)
    for jj = session.channelTags.Bad.electrodeGroups
        deepSuperficial_ChClass3(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
        deepSuperficial_ChClass(ripple_channels{jj}) = repmat({''},length(ripple_channels{jj}),1);
    end
end

deepSuperficial_ChDistance3 = deepSuperficial_ChDistance3 * VerticalSpacing;
deepSuperficial_ChDistance = deepSuperficial_ChDistance * VerticalSpacing;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Saving the result to basename.deepSuperficialfromRipple.channelinfo.mat  
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

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
if isfield(ripples,'detectorinfo')
    deepSuperficialfromRipple.detectorinfo = ripples.detectorinfo;
end
deepSuperficialfromRipple.processinginfo.function = 'classification_deepSuperficial';
deepSuperficialfromRipple.processinginfo.date = now;
deepSuperficialfromRipple.processinginfo.params.verticalSpacing = VerticalSpacing;
deepSuperficialfromRipple.processinginfo.params.spikeGroupsToExclude = spikeGroupsToExclude;
save(fullfile(basepath, [basename,'.deepSuperficialfromRipple.channelinfo.mat']),'deepSuperficialfromRipple');

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Plotting the average ripple with sharp wave across all spike groups
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

figure
for jj = 1:session.extracellular.nSpikeGroups
    subplot(2,ceil(session.extracellular.nSpikeGroups/2),jj)
    plot((SWR_diff{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_diff{jj},2)-1]*0.04,'-k','linewidth',2), hold on, grid on
    plot((SWR_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(SWR_amplitude{jj},2)-1]*0.04,'k','linewidth',1)
    % Plotting ripple amplitude along vertical axis
    plot((ripple_amplitude{jj}*50)+ripple_time_axis(1)-50,-[0:size(ripple_amplitude{jj},2)-1]*0.04,'m','linewidth',1)
    
    for jjj = 1:size(ripple_average{jj},2)
        % Plotting depth (µm)
        text(ripple_time_axis(end)+5,ripple_average{jj}(1,jjj)-(jjj-1)*0.04,[num2str(round(deepSuperficial_ChDistance(ripple_channels{jj}(jjj))))])
        % Plotting channel number (0 indexes)
        text((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50-10,-(jjj-1)*0.04,num2str(ripple_channels{jj}(jjj)-1),'HorizontalAlignment','Right')
        plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04)
        % Plotting assigned channel labels
        if strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Superficial')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'or','linewidth',2)
        elseif strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Deep')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ob','linewidth',2)
        elseif strcmp(deepSuperficial_ChClass(ripple_channels{jj}(jjj)),'Cortical')
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'og','linewidth',2)
        else
            plot((SWR_diff{jj}(jjj)*50)+ripple_time_axis(1)-50,-(jjj-1)*0.04,'ok')
        end
        % Plotting the channel used for the ripple detection if it is part of current spike group
        if ripple_channel_detector==ripple_channels{jj}(jjj)
            plot(ripple_time_axis,ripple_average{jj}(:,jjj)-(jjj-1)*0.04,'k','linewidth',2)
        end
    end
    
    title(['Spike group ' num2str(jj)]),xlabel('Time (ms)'),if jj ==1; ylabel(basename, 'Interpreter', 'none'); end
    axis tight, ax6 = axis; grid on
    plot([-120, -120;-170,-170;120,120], [ax6(3) ax6(4)],'color','k');
    xlim([-220,ripple_time_axis(end)+45]), xticks([-120:40:120])
    ht1 = text(0.02,0.03,'Superficial','Units','normalized','FontWeight','Bold','Color','r');
    ht2 = text(0.02,0.97,'Deep','Units','normalized','FontWeight','Bold','Color','b');
    if ceil(session.extracellular.nSpikeGroups/2) == jj || session.extracellular.nSpikeGroups == jj
        ht3 = text(1.05,0.4,'Depth (µm)','Units','normalized','Color','k'); set(ht3,'Rotation',90)
    end
end
saveas(gcf,'deepSuperficial_classification_fromRipples.png');
