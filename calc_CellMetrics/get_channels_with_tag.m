function channels = get_channels_with_tag(session,tag)
% Getting channels with specific tag in session struct, e.g. Bad:
% session.channelTags.Bad.channels
% session.channelTags.Bad.electrodeGroups

channels = [];

if ~isempty(session) && isfield(session,'channelTags') && isfield(session.channelTags,tag)
    
    % Handling session.channelTags.(tag).channels
    try
        if isfield(session.channelTags.(tag),'channels') && ~isempty(session.channelTags.(tag).channels)
            channels = [channels,session.channelTags.(tag).channels];
        end
    catch
        print(['Failed to load ', tag, ' channels'])
    end

    % Handling session.channelTags.(tag).electrodeGroups
    try
        if isfield(session.channelTags.(tag),'electrodeGroups') && ~isempty(session.channelTags.(tag).electrodeGroups)
            channels = [channels,session.extracellular.electrodeGroups.channels{session.channelTags.(tag).electrodeGroups}];
        end
        channels = unique(channels);
    catch
        print(['Failed to load ', tag, ' channels from electrode groups'])
    end
end
