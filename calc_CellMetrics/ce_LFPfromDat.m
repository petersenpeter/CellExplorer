function ce_LFPfromDat(session,varargin)
% perform lowpass (2 X output Fs) sinc filter on wideband data
% subsample the filtered data and save as a new flat binary
% basename must have basename.dat and basename.xml
% basepath is the full path for basename.dat
%
% note that sincFilter was altered to accomodate GPU filtering
%
%INPUTS
%   session     CellExplorer session meta data struct
%
%               Assumes presence of the following files:
%                   basePath/baseName.dat
%
%   (options)
%       'lopass'        (default: 450) low pass filter frequency 
%
%
% OUTPUT
%   Creates file:   basePath/baseName.lfp
%
%   If no sessionInfo.mat file previously exists, creates one with 
%   the information from the .xml file, with the .lfp sampling frequency 
%   and the lowpass filter used.
%
%
% Dependency: iosr tool box https://github.com/IoSR-Surrey/MatlabToolbox
%
% SMckenzie, BWatson, DLevenstein 2018, 
% 12-11-2019: Peter Petersen: remamed script and made it compatible with the CellExplorer (and independent of buzcode)

%% Input handling
basepath = session.general.basePath;
basename = session.general.name;

p = inputParser;
addParameter(p,'outFs',[],@isnumeric);
addParameter(p,'lopass',450,@isnumeric);

parse(p,varargin{:})
srLfp = p.Results.outFs;
lopass = p.Results.lopass;

%Get the metadata
srLfp = session.extracellular.srLfp;
sr = session.extracellular.sr;
nChannels = session.extracellular.nChannels;

import iosr.dsp.*

useGPU = false;
% if gpuDeviceCount>0
%     useGPU = true;
% end
sizeInBytes = 2; %
timerVal = tic;

%% files check
fdat = fullfile(basepath,[basename,'.dat']);
flfp = fullfile(basepath,[basename,'.lfp']);

%Check the dat
if ~exist(fdat,'file')
    error([basename, '.dat file does not exist'])
end
fInfo = dir(fullfile(basepath, [basename '.dat']));

%If there's already a .lfp file, make sure the user wants to overwrite it
if exist(flfp,'file')
    answer = questdlg('.lfp file already exist. Do you want to overwrite it?', 'Overwrite existing file', 'Yes','Cancel','Cancel');
    switch answer
        case 'Yes'
            delete(flfp)
        otherwise
            return
    end
end

if lopass> srLfp/2
    warning('low pass cutoff beyond Nyquist')
end
 
ratio =lopass/(sr/2) ;
sampleRatio = (sr/srLfp);

%% Set Chunk and buffer size at even multiple of sampleRatio
chunksize = 1e5; % depends on the system... could be bigger I guess
if mod(chunksize,sampleRatio)~=0
    chunksize = chunksize + sampleRatio-mod(chunksize,sampleRatio);
end

%ntbuff should be even multiple of sampleRatio
ntbuff = 525;  %default filter size in iosr toolbox
if mod(ntbuff,sampleRatio)~=0
    ntbuff = ntbuff + sampleRatio-mod(ntbuff,sampleRatio);
end

nBytes = fInfo.bytes;
nbChunks = floor(nBytes/(nChannels*sizeInBytes*chunksize));

%% GET LFP FROM DAT!
fidI = fopen(fdat, 'r');
fprintf('Extraction of LFP begun \n')
fidout = fopen(flfp, 'a');
h=waitbar(0,'Please wait...','Name',[basename,'.lfp']);
for ibatch = 1:nbChunks
    if mod(ibatch,10)==0
        if ishandle(h)
            waitbar(ibatch/(nbChunks+1),h,[num2str(100*ibatch/nbChunks,2),' percent complete (duration ', num2str(toc(timerVal)/60,2),' minutes)'])
        else
            warning('LFP extraction cancelled. Deleting partly created .lfp file...')
            fclose(fidI);
            fclose(fidout);
            delete(flfp)
            return
        end
        
        if ibatch~=10
            fprintf(repmat('\b',[1 length([round(100*(ibatch-10)/nbChunks), ' percent complete'])]))
        end
        disp([round(100*(ibatch)/nbChunks), ' percent complete']);
    end
    
    if ibatch>1
        fseek(fidI,((ibatch-1)*(nChannels*sizeInBytes*chunksize))-(nChannels*sizeInBytes*ntbuff),'bof');
        dat = fread(fidI,nChannels*(chunksize+2*ntbuff),'int16');
        dat = reshape(dat,[nChannels (chunksize+2*ntbuff)]);
    else
        dat = fread(fidI,nChannels*(chunksize+ntbuff),'int16');
        dat = reshape(dat,[nChannels (chunksize+ntbuff)]);
    end
    
    
    DATA = nan(size(dat,1),chunksize/sampleRatio);
    for ii = 1:size(dat,1)
        
        d = double(dat(ii,:));
        if useGPU
            d = gpuArray(d);
        end
        
        tmp=  iosr.dsp.sincFilter(d,ratio);
        if useGPU
            if ibatch==1
                DATA(ii,:) = gather_try(int16(real( tmp(sampleRatio:sampleRatio:end-ntbuff))));
            else
                DATA(ii,:) = gather_try(int16(real( tmp(ntbuff+sampleRatio:sampleRatio:end-ntbuff))));
            end
            
        else
            if ibatch==1
                DATA(ii,:) = int16(real( tmp(sampleRatio:sampleRatio:end-ntbuff)));
            else
                DATA(ii,:) = int16(real( tmp(ntbuff+sampleRatio:sampleRatio:end-ntbuff)));
            end
            
        end
        
    end
    fwrite(fidout,DATA(:),'int16'); 
end

remainder = nBytes/(sizeInBytes*nChannels) - nbChunks*chunksize;
if ~isempty(remainder)
    fseek(fidI,((ibatch-1)*(nChannels*sizeInBytes*chunksize))-(nChannels*sizeInBytes*ntbuff),'bof');
    dat = fread(fidI,nChannels*(remainder+ntbuff),'int16');
    dat = reshape(dat,[nChannels (remainder+ntbuff)]);
 
    DATA = nan(size(dat,1),floor(remainder/sampleRatio));
    for ii = 1:size(dat,1)
        d = double(dat(ii,:));
        if useGPU
            d = gpuArray(d);
        end
        
        tmp=  iosr.dsp.sincFilter(d,ratio);
        
        if useGPU
            
            DATA(ii,:) = gather_try(int16(real( tmp(ntbuff+sampleRatio:sampleRatio:end))));
        else
            DATA(ii,:) = int16(real( tmp(ntbuff+sampleRatio:sampleRatio:end)));
        end
    end
    
    fwrite(fidout,DATA(:),'int16');
end
if ishandle(h)
    waitbar(1,h,['lfp file created. Processing time: ', num2str(toc(timerVal)/60,3),' min']);
end
close(h);

fclose(fidI);
fclose(fidout);

disp(['lfp file created: ', flfp,'. Process time: ' num2str(toc(timerVal)/60,2),' minutes'])

    function x = gather_try(x)
        try
            x = gather(x);
        catch
        end
    end
end
