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
%       'outFs'         (default: session.extracellular.srLfp) sampling rate of the .lfp file;
%                       must divide session.extracellular.sr. Update session.extracellular.srLfp
%                       to the same value and save the session struct.
%       'overwrite'     (default: [] = ask with a dialog) what to do when basename.lfp exists:
%                       true deletes and recreates it, false stops with an error. Without a
%                       desktop (e.g. matlab -batch) and no explicit value it stops with an error.
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
addParameter(p,'overwrite',[],@(x) isempty(x) || islogical(x) || isnumeric(x));

parse(p,varargin{:})
lopass = p.Results.lopass;
overwrite = p.Results.overwrite;

%Get the metadata
% outFs, when given, sets the lfp sampling rate (previously it was ignored in favour of the session value)
if ~isempty(p.Results.outFs)
    srLfp = p.Results.outFs;
    if ~isfield(session.extracellular,'srLfp') || isempty(session.extracellular.srLfp) || session.extracellular.srLfp ~= srLfp
        warning('ce_LFPfromDat: outFs (%g Hz) differs from session.extracellular.srLfp; update the session struct to %g Hz',srLfp,srLfp)
    end
else
    srLfp = session.extracellular.srLfp;
end
sr = session.extracellular.sr;
if abs(sr/srLfp - round(sr/srLfp)) > 1e-9
    error('ce_LFPfromDat: the lfp sampling rate (%g Hz) must divide the raw sampling rate (%g Hz)',srLfp,sr)
end
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
    if isempty(overwrite) && ~usejava('desktop')
        error('ce_LFPfromDat: %s already exists. Without a desktop no dialog can be shown; pass ''overwrite'',true to recreate it or ''overwrite'',false to keep it.',flfp)
    elseif isempty(overwrite)
        answer = questdlg('.lfp file already exist. Do you want to overwrite it?', 'Overwrite existing file', 'Yes','Cancel','Cancel');
        switch answer
            case 'Yes'
                delete(flfp)
            otherwise
                return
        end
    elseif overwrite
        delete(flfp)
    else
        error('ce_LFPfromDat: %s already exists and overwrite is false.',flfp)
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
    
    % The trailing buffer can be shorter than ntbuff at the end of the file; outputs are indexed
    % from the chunk bounds, so a short read no longer fails
    if ibatch>1
        fseek(fidI,((ibatch-1)*(nChannels*sizeInBytes*chunksize))-(nChannels*sizeInBytes*ntbuff),'bof');
        dat = fread(fidI,nChannels*(chunksize+2*ntbuff),'int16');
        dat = reshape(dat,nChannels,[]);
    else
        dat = fread(fidI,nChannels*(chunksize+ntbuff),'int16');
        dat = reshape(dat,nChannels,[]);
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
                DATA(ii,:) = gather_try(int16(real( tmp(sampleRatio:sampleRatio:chunksize))));
            else
                DATA(ii,:) = gather_try(int16(real( tmp(ntbuff+sampleRatio:sampleRatio:ntbuff+chunksize))));
            end
            
        else
            if ibatch==1
                DATA(ii,:) = int16(real( tmp(sampleRatio:sampleRatio:chunksize)));
            else
                DATA(ii,:) = int16(real( tmp(ntbuff+sampleRatio:sampleRatio:ntbuff+chunksize)));
            end
            
        end
        
    end
    fwrite(fidout,DATA(:),'int16'); 
end

remainder = nBytes/(sizeInBytes*nChannels) - nbChunks*chunksize;
if remainder > 0
    % The remainder starts where the full chunks ended, preceded by ntbuff samples of filter buffer
    % (previously it was read from the start of the last full chunk, so the end of the .lfp repeated
    % that chunk). Files shorter than one chunk have no full chunks and no preceding buffer.
    if nbChunks > 0
        lead = ntbuff;
    else
        lead = 0;
    end
    fseek(fidI,(nbChunks*chunksize - lead)*nChannels*sizeInBytes,'bof');
    dat = fread(fidI,nChannels*(remainder+lead),'int16');
    dat = reshape(dat,nChannels,[]);
 
    DATA = nan(size(dat,1),floor(remainder/sampleRatio));
    for ii = 1:size(dat,1)
        d = double(dat(ii,:));
        if useGPU
            d = gpuArray(d);
        end
        
        tmp=  iosr.dsp.sincFilter(d,ratio);
        
        if useGPU
            
            DATA(ii,:) = gather_try(int16(real( tmp(lead+sampleRatio:sampleRatio:end))));
        else
            DATA(ii,:) = int16(real( tmp(lead+sampleRatio:sampleRatio:end)));
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
