function chListBrainRegions = findBrainRegion(session)
% Pulls out brain regions from a session and assigns to channels

% By Peter Petersen
% Last edited 31-10-2019

chListBrainRegions = repmat({''},1,session.extracellular.nChannels);
brainRegions = (fieldnames(session.brainRegions));

idx = find(struct2array(structfun(@(x)all(isfield(x,'spikeGroups') && ~isempty(x.spikeGroups)), session.brainRegions,'UniformOutput',false)));
for i = idx
    temp = session.brainRegions.(brainRegions{i}).spikeGroups;
    for ii = 1:length(temp)
    	chListBrainRegions(session.extracellular.spikeGroups.channels{ii}+1) = repmat({brainRegions{i}},1,length(session.extracellular.spikeGroups.channels{ii}+1));
    end
end

idx = find(struct2array(structfun(@(x)all(isfield(x,'channels') && ~isempty(x.channels)), session.brainRegions,'UniformOutput',false)));
for i = idx
    temp = session.brainRegions.(brainRegions{i}).channels;
    chListBrainRegions(temp) = repmat({brainRegions{i}},1,length(temp));
end
