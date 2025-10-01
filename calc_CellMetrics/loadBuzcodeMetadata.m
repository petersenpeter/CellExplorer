%improvisations made by Diksha Zutshi
function session = loadBuzcodeMetadata(session)
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    % Loading channel group parameters from sessionInfo
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
        
    if exist(fullfile(session.general.basePath,[session.general.name,'.sessionInfo.mat']),'file')
        load(fullfile(session.general.basePath,[session.general.name,'.sessionInfo.mat']),'sessionInfo')
        if isfield(sessionInfo,'AnatGrps')
            session.extracellular.nElectrodeGroups = size(sessionInfo.AnatGrps,2); % Number of electrode groups
            session.extracellular.electrodeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Electrode groups
            session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0); % Changing index from 0 to 1
        else
            session.extracellular.nElectrodeGroups = session.extracellular.nSpikeGroups; % Number of electrode groups
            session.extracellular.electrodeGroups.channels = session.extracellular.spikeGroups.channels; % Electrode groups
            session.extracellular.electrodeGroups.channels=cellfun(@(x) x+1,session.extracellular.electrodeGroups.channels,'un',0); % Changing index from 0 to 1
        end
        
        if isfield(sessionInfo,'spikeGroups') && sessionInfo.spikeGroups.nGroups>0
            session.extracellular.nSpikeGroups = sessionInfo.spikeGroups.nGroups; % Number of spike groups
            session.extracellular.spikeGroups.channels = sessionInfo.spikeGroups.groups; % Spike groups
            session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0); % Changing index from 0 to 1
        elseif isfield(sessionInfo,'AnatGrps')
            warning('No spike groups exist in the xml. Anatomical groups used instead')
            session.extracellular.nSpikeGroups = size(sessionInfo.AnatGrps,2); % Number of spike groups
            session.extracellular.spikeGroups.channels = {sessionInfo.AnatGrps.Channels}; % Spike groups
            session.extracellular.spikeGroups.channels=cellfun(@(x) x+1,session.extracellular.spikeGroups.channels,'un',0); % Changing index from 0 to 1
        end
        
        
        if isfield(sessionInfo,'region')
            regions=sessionInfo.region(:);
            if isfield(sessionInfo,'ElecGp')
                electrodeGroups=sessionInfo.ElecGp;
                %index of changing regions to get unique regions
                sameasnext=strcmp(regions(1:end-1),regions(2:end));
                changeIdx=[1;find(~sameasnext)+1;numel(regions)+1];
                regionnames=regions(changeIdx(1:end-1));
                
                for i=1:numel(regionnames)
                    name=regionnames{i};
                    group=electrodeGroups{i};
                    channels=group.channel;
                    channels=cellfun(@str2double,channels);
                    session.brainRegions.(name).brainRegion=name;
                    session.brainRegions.(name).channels=channels;
                    session.brainRegions.(name).electrodeGroups=i;
                end    
                
            else
                disp('E')
            end    
        else
            disp('Brain region information isnt present in sessionInfo');
        end    
        
        session.extracellular.sr = sessionInfo.rates.wideband; % Sampling rate of dat file
        session.extracellular.srLfp = sessionInfo.rates.lfp; % Sampling rate of lfp file
        session.extracellular.nChannels = sessionInfo.nChannels; % Number of channels
        disp(['Channel groups updated from ', session.general.name,'.sessionInfo.mat'])
    else
        disp('No sessionInfo.mat file found in basepath')
    end
end