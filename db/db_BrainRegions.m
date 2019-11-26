function [BrainRegions,BrainRegionsChannels] = db_BrainRegions(session)
BrainRegions = (fieldnames(session.brainRegions));
findBrainRegion = @(Channel,BrainRegions) BrainRegions{find([(struct2array(structfun(@(x) any(Channel==x.Channels)==1, session.brainRegions,'UniformOutput',false)))])};

BrainRegionsChannels = findBrainRegion(1:session.extracellular.nChannels,BrainRegions);

if ~isempty(session.brainRegions)
    temp = fieldnames(session.brainRegions);
    for i=1:length(temp)
        session.brainRegions.(temp{i}).channels;
    if ~isempty(session.channelTags.Bad.channels)
        BadChannels = [BadChannels,session.channelTags.Bad.channels];
    end
    if ~isempty(session.channelTags.Bad.spikeGroups)
        BadChannels = [BadChannels,xml.SpkGrps(session.channelTags.Bad.spikeGroups).Channels+1];
    end
end
