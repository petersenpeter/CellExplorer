function signal = readLfpChannel(file, nChannels, channel)
%READLFPCHANNEL Read one native-endian int16 channel from interleaved LFP data.
validateattributes(nChannels,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(channel,{'numeric'},{'scalar','integer','positive','<=',nChannels});
fid = fopen(file,'r');
if fid < 0, error('ce:io:LfpOpenFailed','Cannot open LFP file: %s.',file); end
cleanup = onCleanup(@() fclose(fid));
if fseek(fid,0,'eof') ~= 0
    error('ce:io:LfpSeekFailed','Cannot determine LFP size.');
end
nSamples = ftell(fid)/(2*nChannels);
if mod(nSamples,1) ~= 0
    error('ce:io:LfpReadFailed','LFP has an incomplete channel frame.');
end
if fseek(fid,2*(channel-1),'bof') ~= 0
    error('ce:io:LfpSeekFailed','Cannot seek to LFP channel %d.',channel);
end
[signal,count] = fread(fid,nSamples,'int16=>double',2*(nChannels-1));
if count ~= nSamples, error('ce:io:LfpReadFailed','LFP ended before the expected sample count.'); end
end
