function [BrainRegions,BrainRegionsChannels] = db_BrainRegions(session)
session.Extracellular.nChannels
BrainRegions = (fieldnames(session.BrainRegions));
findBrainRegion = @(Channel,BrainRegions) BrainRegions{find([(struct2array(structfun(@(x) any(Channel==x.Channels)==1, session.BrainRegions,'UniformOutput',false)))])};


BrainRegionsChannels = findBrainRegion(1:session.Extracellular.nChannels,BrainRegions);

if ~isempty(session.BrainRegions)
    temp = fieldnames(session.BrainRegions);
    for i=1:length(temp)
        session.BrainRegions.(temp{i}).Channels;
    if ~isempty(session.ChannelTags.Bad.Channels)
        BadChannels = [BadChannels,session.ChannelTags.Bad.Channels,];
    end
    if ~isempty(session.ChannelTags.Bad.SpikeGroups)
        BadChannels = [BadChannels,xml.SpkGrps(session.ChannelTags.Bad.SpikeGroups).Channels+1];
    end
end
