function chListBrainRegions = findBrainRegion(session)
% Pulls out brain regions from a session and assigns to channels

chListBrainRegions = repmat({''},1,session.extracellular.nChannels);
brainRegions = (fieldnames(session.brainRegions));

idx = find(struct2array(structfun(@(x)all(~isempty(x.spikeGroups)), session.brainRegions,'UniformOutput',false)));
for i = idx
    temp = session.brainRegions.(brainRegions{i}).spikeGroups;
    for ii = 1:length(temp)
    	chListBrainRegions(session.extracellular.spikeGroups.channels{ii}+1) = repmat({brainRegions{i}},1,length(session.extracellular.spikeGroups.channels{ii}+1));
    end
end
% 
% for i = 1:session.extracellular.nSpikeGroups
%     temp = find([(struct2array(structfun(@(x) any(i==x.spikeGroups)==1, session.brainRegions,'UniformOutput',false)))]);
%     if ~isempty(temp)
%         for ii = 1:length(temp)
%             chListBrainRegions(session.extracellular.spikeGroups.channels{i}+1) = repmat({brainRegions{temp(ii)}},1,length(session.extracellular.spikeGroups.channels{i}+1));
%         end
%     end
% end

idx = find(struct2array(structfun(@(x)all(~isempty(x.channels)), session.brainRegions,'UniformOutput',false)));
for i = idx
    temp = session.brainRegions.(brainRegions{i}).channels;
    chListBrainRegions(temp) = repmat({brainRegions{i}},1,length(temp));
end
