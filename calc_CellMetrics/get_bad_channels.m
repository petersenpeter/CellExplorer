function bad_channels = get_bad_channels(session)
% Getting channels marked as Bad in session struct
% session.channelTags.Bad.channels
% session.channelTags.Bad.electrodeGroups

bad_channels = [];

if ~isempty(session) && isfield(session,'channelTags') && isfield(session.channelTags,'Bad')
    try
        if isfield(session.channelTags.Bad,'channels') && ~isempty(session.channelTags.Bad.channels)
            bad_channels = [bad_channels,session.channelTags.Bad.channels];
        end
    catch
        print('Failed to load bad channels')
    end

    try
        if isfield(session.channelTags.Bad,'electrodeGroups') && ~isempty(session.channelTags.Bad.electrodeGroups)
            bad_channels = [bad_channels,session.extracellular.electrodeGroups.channels{session.channelTags.Bad.electrodeGroups}];
        end
        bad_channels = unique(bad_channels);
    catch
        print('Failed to load bad channels')
    end
end
