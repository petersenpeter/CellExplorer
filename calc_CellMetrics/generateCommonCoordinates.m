function generateCommonCoordinates(session)
        % Loading channelmap
        if ~exist(fullfile(session.general.basePath,[session.general.name,'.chanCoords.channelInfo.mat']))
            generateChannelMap
        end
        chanCoords = loadStruct('chanCoords','channelInfo','session',session);

        ccf = {};
        ccf.x = [];
        ccf.y = [];
        ccf.z = [];
        requiredFields = {'ap','ml','depth','ap_angle','ml_angle','rotation'};
        nChannelsProcessed = 0;
        
        figure
        for i = 1:numel(session.animal.probeImplants)
            % Loading implant coordinates
            implantCoordinate = session.animal.probeImplants{i};
            % Verifying required fields
            for j = 1:numel(requiredFields)
                if ~isfield(implantCoordinate,requiredFields{j}) || isempty(implantCoordinate.(requiredFields{j}))
                    implantCoordinate.(requiredFields{j}) = 0;
                end
            end
            % Realigning chanCoords origin to the centered lower part of the probes (the tip)
            nChannels = session.animal.probeImplants{i}.nChannels;
            chanCoords1.x = chanCoords.x([1:nChannels]+nChannelsProcessed) - mean(chanCoords.x([1:nChannels]+nChannelsProcessed));
            chanCoords1.y = chanCoords.y([1:nChannels]+nChannelsProcessed) - min(chanCoords.y([1:nChannels]+nChannelsProcessed));
            chanCoords1.z = zeros(size(chanCoords1.y));
            chanCoords1.x = chanCoords1.x(:);
            chanCoords1.y = chanCoords1.y(:);
            chanCoords1.z = chanCoords1.z(:);
            
            % Calculating the common coordinates
            ccf1(i) = bregma_to_CCF(chanCoords1,implantCoordinate);
            
            % Adding 
            text(ccf1(i).implantVector(1,1),ccf1(i).implantVector(1,3),ccf1(i).implantVector(1,2),num2str(i),'HorizontalAlignment','center','VerticalAlignment','bottom');
            
            % Combining CCFs from multiple probes
            ccf.x = [ccf.x;ccf1(i).x];
            ccf.y = [ccf.y;ccf1(i).y];
            ccf.z = [ccf.z;ccf1(i).z];
            ccf.implantVector{i} = ccf1(i).implantVector;
            nChannelsProcessed = nChannelsProcessed + nChannels;
        end
        
        % Saving the ccf to a basename.ccf.channelInfo.mat file
        saveStruct(ccf,'channelInfo','session',session);
    end