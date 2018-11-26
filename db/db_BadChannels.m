function [BadChannels,GoodChannels] = db_BadChannels(session,xml)
BadChannels = [];
if isfield(session.ChannelTags,'Bad')
    if ~isempty(session.ChannelTags.Bad.Channels)
        BadChannels = [BadChannels,session.ChannelTags.Bad.Channels,];
    end
    if ~isempty(session.ChannelTags.Bad.SpikeGroups)
        BadChannels = [BadChannels,xml.SpkGrps(session.ChannelTags.Bad.SpikeGroups).Channels+1];
    end
end
GoodChannels = setdiff(1:session.Extracellular.nChannels,BadChannels);
