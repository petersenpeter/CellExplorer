function InstantaneousTheta = calcInstantaneousTheta2(session,varargin)
% Calculates the instantaneous theta with phase and power
% By Peter Petersen
% Last edited: 18-08-2019

p = inputParser;
addParameter(p,'forceReload',false,@islogical);
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'saveAs','InstantaneousTheta',@isstr);

parse(p,varargin{:})

forceReload = p.Results.forceReload;
saveMat = p.Results.saveMat;
saveAs = p.Results.saveAs;

% Output file
saveAsFullfile = fullfile(session.general.basePath,[session.general.name,'.',saveAs,'.lfp.mat']);

ch_theta = session.channelTags.Theta.channels;
ch_theta = ch_theta(1);
if ~forceReload && exist(saveAsFullfile,'file')
    disp('Loading existing InstantaneousTheta.lfp.mat file')
    InstantaneousTheta = [];
    loaded = load(saveAsFullfile,'InstantaneousTheta');
    if isfield(loaded,'InstantaneousTheta'), InstantaneousTheta = loaded.InstantaneousTheta; end
    if isempty(InstantaneousTheta) || isnumeric(InstantaneousTheta.ThetaInstantFreq)
        disp(['InstantaneousTheta not calculated correctly. Hold on'])
        InstantaneousTheta = [];
        forceReload = true;
    elseif isempty(InstantaneousTheta) || size(InstantaneousTheta.ThetaInstantFreq,2) < ch_theta || isempty(InstantaneousTheta.ThetaInstantFreq{ch_theta})
        forceReload = true;
        disp(['Selected channel not calculated yet. Hold on'])
    end
end

% Calculating the instantaneous theta frequency
if ~exist(saveAsFullfile,'file') || forceReload
    if ~exist(fullfile(session.general.basePath,[session.general.name, '.lfp']),'file')
        disp('Creating lfp file')
        ce_LFPfromDat(session)
%         bz_LFPfromDat(session.general.basePath)
    end
    srLfp = session.extracellular.srLfp;
    disp('Calculating the instantaneous theta frequency')
    signal = session.extracellular.leastSignificantBit * double(LoadBinary(fullfile(session.general.basePath,[session.general.name '.lfp']),'nChannels',session.extracellular.nChannels,'channels',ch_theta,'precision','int16','frequency',srLfp)); % ,'start',start,'duration',duration
    
    computed = ce.processing.instantaneousTheta(signal,srLfp,ch_theta);
    for name = fieldnames(computed)'
        if iscell(computed.(name{1}))
            InstantaneousTheta.(name{1}){ch_theta} = computed.(name{1}){ch_theta};
        else
            InstantaneousTheta.(name{1}) = computed.(name{1});
        end
    end
    if saveMat
        save(saveAsFullfile,'InstantaneousTheta')
        disp('InstantaneousTheta saved to disk')
    end
    clear signal    
end
