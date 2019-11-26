function [BadChannels,GoodChannels] = db_BadChannels(session,xml)
BadChannels = [];
if isfield(session.channelTags,'Bad')
    if ~isempty(session.channelTags.Bad.channels)
        BadChannels = [BadChannels,session.channelTags.Bad.channels,];
    end
    if ~isempty(session.channelTags.Bad.spikeGroups)
        BadChannels = [BadChannels,xml.SpkGrps(session.channelTags.Bad.spikeGroups).channels+1];
    end
end
GoodChannels = setdiff(1:session.extracellular.nChannels,BadChannels);
