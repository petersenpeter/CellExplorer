function bad_channels = get_bad_channels(session)
% Getting channels marked as Bad in session struct
% session.channelTags.Bad.channels
% session.channelTags.Bad.electrodeGroups

bad_channels = [];
if ~isempty(session) && isfield(session,'channelTags') && isfield(session.channelTags,'Bad')
    if isfield(session.channelTags.Bad,'channels') && ~isempty(session.channelTags.Bad.channels)
        bad_channels = [bad_channels,session.channelTags.Bad.channels];
    end
    if isfield(session.channelTags.Bad,'electrodeGroups') && ~isempty(session.channelTags.Bad.electrodeGroups)
        bad_channels = [bad_channels,electrodeGroups{session.channelTags.Bad.electrodeGroups}];
    end
    bad_channels = unique(bad_channels);
end
